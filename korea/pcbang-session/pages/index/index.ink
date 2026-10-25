<script def>
{
  "title": "PCbang Session"
}
</script>

<script setup>
import wx from 'wx';

// KR09 PCbang Session - 座席账本 Seat Ledger
// Local anchor: PC방 是韩国的生活基础设施：按小时计费、座位上就能点餐送到手边，泡面和饮料的钱和机时费一起结算。人在局内最分不了心——...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const MENUS = [['라면', 4500], ['음료', 2000], ['볶음밥', 6000]];
const RATE = 1000;
const DEMO_S = [{"blocks": 0, "ord": [0, 0, 0], "menuIdx": 0, "settled": false}, {"blocks": 2, "ord": [1, 1, 0], "menuIdx": 1, "settled": false}, {"blocks": 4, "ord": [1, 2, 1], "menuIdx": 2, "settled": true}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"blocks": 0, "ord": [0, 0, 0], "menuIdx": 0, "settled": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) { const s = this._s; s.menuIdx = Math.max(0, Math.min(2, s.menuIdx + dir)); this.setData({ evt: 'EVT: swipe -> menu ' + MENUS[s.menuIdx][0] }); this._recompute(); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.settled) { this.setData({ evt: 'EVT: settled - END again for new session' }); this._recompute(); return; }
    s.blocks++;
    this._speak(s.blocks + '시간 블록을 기록했습니다.');
    this.setData({ evt: 'EVT: +1H -> ' + s.blocks + ' blocks' }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.settled) { this.setData({ evt: 'EVT: settled' }); this._recompute(); return; }
    s.ord[s.menuIdx]++;
    this._speak(MENUS[s.menuIdx][0] + ' 주문을 기록했습니다.');
    this.setData({ evt: 'EVT: ORDER ' + MENUS[s.menuIdx][0] }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.settled) { this._s = { blocks: 0, ord: [0, 0, 0], menuIdx: 0, settled: false }; this.setData({ evt: 'EVT: new session' }); this._recompute(); return; }
    s.settled = true;
    const food = s.ord.reduce((a, v, i) => a + v * MENUS[i][1], 0);
    this._speak('예상 결제는 ' + (s.blocks * RATE + food) + '원입니다. 카운터 금액이 정본입니다.');
    this.setData({ evt: 'EVT: END settled' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const food = s.ord.reduce((a, v, i) => a + v * MENUS[i][1], 0);
    const ok = this._speak('현재 ' + s.blocks + '시간 블록, 예상 ' + (s.blocks * RATE + food) + '원입니다.');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'summary' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const food = s.ord.reduce((a, v, i) => a + v * MENUS[i][1], 0);
    const total = s.blocks * RATE + food;
    const nOrd = s.ord.reduce((a, v) => a + v, 0);
    const parts = []; MENUS.forEach((m, i) => { if (s.ord[i] > 0) parts.push(m[0] + '×' + s.ord[i]); });
    const ordTxt = parts.join(' · ');
    this.setData({
      status: s.settled ? 'END: 결산 표시 중 · 카운터가 정본' : 'SEAT 12 · ' + s.blocks + ' blocks · 주문 ' + nOrd + '건',
      hero: '₩' + total, heroSub: s.settled ? '예상 총액 (정본은 카운터)' : '예상 누적',
      r1: '시간: ' + s.blocks + 'h × ₩' + RATE + ' = ₩' + (s.blocks * RATE),
      r2: '주문: ' + (ordTxt || '없음') + ' = ₩' + food,
      r3: '다음 후보: ' + MENUS[s.menuIdx][0] + ' ₩' + MENUS[s.menuIdx][1] + ' (스와이프로 변경)',
      r4: '', marks: '',
      guide: '+1H 시간 블록 · ORDER 후보 주문 기록 · END 결산 ·点头=+1H'
    });
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) { return false; }
  },

  onOrientationStabilityChange(event) {
    const d = (event && event.detail) || {};
    this._steady = d.isStable === true || d.stable === true;
  },

  onHeadGesture(event) {
    const d = (event && event.detail) || {};
    const g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') return;
    if (!this._steady) return;
    if (this._demoIdx >= 0) return;
    this._nodAction();
  },

  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._swipe(1); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._swipe(-1); return; }
  },

  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  demoTap() {
    if (this._busy) return;
    if (this._demoIdx < 0) {
      this._savedS = JSON.parse(JSON.stringify(this._s));
      this._demoIdx = 0;
      this._stopTimers();
    } else {
      this._demoIdx++;
    }
    if (this._demoIdx >= DEMO_S.length) {
      this._s = this._savedS; this._savedS = null; this._demoIdx = -1;
      this._recompute();
      this.setData({ evt: 'EVT: DEMO off - real state restored' });
      return;
    }
    this._s = JSON.parse(JSON.stringify(DEMO_S[this._demoIdx]));
    this._recompute();
    this.setData({ evt: 'EVT: DEMO ' + (this._demoIdx + 1) + '/' + DEMO_S.length + ' (seeded, in-memory)' });
  },

  _stopTimers() {
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
    if (this._micTimer) { try { clearInterval(this._micTimer); } catch (e) {} this._micTimer = null; }
    if (this._stream) { try { this._stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} }); } catch (e) {} this._stream = null; }
    if (this._ac) { try { this._ac.close(); } catch (e) {} this._ac = null; }
  }
};
</script>

<template>
  <div class="page">
    <div class="ttl">PCBANG SESSION</div>
    <div class="status">{{ status }}</div>
    <div class="bezel">
      <div class="brow">{{ r1 }}</div>
      <div class="brow">{{ r2 }}</div>
      <div class="brow dim2">{{ r3 }}</div>
    </div>
    <div class="heroline center">{{ hero }}</div>
    <div class="rline center dim">{{ heroSub }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">+1H</button>
      <button class="btn" bindtap="act2Tap">ORDER</button>
      <button class="btn" bindtap="act3Tap">END</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </div>
    <div class="guide">{{ guide }}</div>
    <div class="foot">{{ evt }}</div>
    <button class="demobtn" bindtap="demoTap">DEMO</button>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; line-height: 15px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.btn { flex: 1; margin-right: 6px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 13px; padding: 5px 0; text-align: center; }
.btnrow .btn:last-child { margin-right: 0; }
.btn-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.guide { color: rgba(64,255,94,0.62); font-size: 10px; line-height: 13px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.rline { color: #7dff9e; font-size: 12px; line-height: 16px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.dim { color: rgba(125,255,158,0.75); }
.center { text-align: center; }
.mono { font-family: monospace; }
.heroline { color: #40ff5e; font-size: 16px; font-weight: bold; line-height: 21px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.foot { position: absolute; left: 14px; top: 322px; width: 350px; color: rgba(64,255,94,0.66); font-family: monospace; font-size: 9px; line-height: 12px; white-space: nowrap; overflow: hidden; }
.demobtn { position: absolute; left: 388px; top: 312px; width: 78px; height: 28px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 12px; text-align: center; }

.bezel { border: 4px solid rgba(64,255,94,0.5); border-radius: 10px; padding: 10px 12px; margin-top: 8px; }
.brow { color: #7dff9e; font-size: 13px; line-height: 20px; white-space: nowrap; overflow: hidden; }
.dim2 { color: rgba(64,255,94,0.62); }
.btn { font-family: monospace; background-color: #0d2812; border: 1px solid rgba(64,255,94,0.8); border-bottom: 4px solid rgba(64,255,94,0.8); border-radius: 6px; padding: 6px 0; }
.btn-main { background-color: #40ff5e; color: #06280f; border-color: #7dff9e; }
.demobtn { font-family: monospace; border-bottom: 4px solid rgba(64,255,94,0.8); border-radius: 6px; }
</style>
