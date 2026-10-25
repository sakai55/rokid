<script def>
{
  "title": "Hanbok Rental"
}
</script>

<script setup>
import wx from 'wx';

// KR11 Hanbok Rental - 衣物核对 Garment Check
// Local anchor: 한국의 궁궐 일대에는 한복 대여점이 늘어서 있다. 한복을 입고 궁궐에 들어가고, 정해진 시간 안에 저고리, ...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const ITEMS = ['저고리','치마','장신구','가방'];
const DEMO_S = [{"focus": 1, "done": [true, false, false, false], "mins": 210, "returned": false}, {"focus": 2, "done": [true, true, false, false], "mins": 150, "returned": false}, {"focus": 3, "done": [true, true, true, true], "mins": 60, "returned": true}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"focus": 0, "done": [false, false, false, false], "mins": 240, "returned": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _countDone() {
    let n = 0;
    for (let i = 0; i < 4; i++) if (this._s.done[i]) n++;
    return n;
  },
  _nodAction() { this.act2Tap(); },
  _swipe(dir) {
    const s = this._s;
    s.focus = (s.focus + dir + 4) % 4;
    this.setData({ evt: 'EVT: focus -> ' + ITEMS[s.focus] });
    this._recompute();
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (this._countDone() === 4 && !s.returned) {
      s.returned = true;
      this._speak('반납 준비가 끝났어요. 대여점으로 돌아가세요.');
      this.setData({ evt: 'EVT: ready to return' });
    } else {
      this.speakTap();
    }
    this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    this._s.focus = (this._s.focus + 1) % 4;
    this.setData({ evt: 'EVT: focus -> ' + ITEMS[this._s.focus] });
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.done[s.focus] = !s.done[s.focus];
    this.setData({ evt: 'EVT: ' + ITEMS[s.focus] + ' -> ' + (s.done[s.focus] ? 'checked' : 'unchecked') });
    this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s.mins += 30;
    this.setData({ evt: 'EVT: extended +30 min' });
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const n = this._countDone();
    const t = s.returned
      ? '반납 준비가 끝났어요. 대여점으로 돌아가세요.'
      : ('반납까지 ' + s.mins + '분 남았어요. 확인된 물품은 ' + n + '개입니다.');
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'rental spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    const n = this._countDone();
    const lines = [];
    for (let i = 0; i < 4; i++) {
      lines.push((i === s.focus ? '▶ ' : '  ') + ITEMS[i] + ' · ' + (s.done[i] ? '확인됨' : '미확인'));
    }
    this.setData({
      status: s.returned ? 'RETURN: 반납 준비 완료 — 대여점으로' : ('RENTAL: 반납까지 ' + s.mins + '분 · ' + n + '/4 확인'),
      hero: s.returned ? '반납 준비 완료' : ('반납까지 ' + s.mins + '분'),
      heroSub: '대여 물품 ' + n + '/4 확인 · 연장 30분 단위',
      r1: lines[0],
      r2: lines[1],
      r3: lines[2],
      r4: lines[3],
      marks: '대여증 · 물품은 반납 전에 모두 확인하세요',
      guide: 'NEXT 다음 물품 · CHECK 확인/해제 · EXTEND 30분 연장 · GO=반납/읽어주기 · 끄덕임=CHECK'
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
    <div class="ttl">HANBOK RENTAL</div>
    <div class="status">{{ status }}</div>
    <div class="garment">
      <div class="grow">{{ r1 }}</div>
      <div class="grow">{{ r2 }}</div>
      <div class="grow">{{ r3 }}</div>
      <div class="grow">{{ r4 }}</div>
    </div>
    <div class="heroline">{{ hero }}</div>
    <div class="rline dim">{{ heroSub }}</div>
    <div class="rline dim">{{ marks }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">NEXT</button>
      <button class="btn" bindtap="act2Tap">CHECK</button>
      <button class="btn" bindtap="act3Tap">EXTEND</button>
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

.garment { margin-top: 8px; border: 1px solid rgba(64,255,94,0.5); padding: 8px 12px; }
.grow { color: #7dff9e; font-size: 13px; line-height: 20px; white-space: nowrap; overflow: hidden; }
.btn { border-radius: 0 14px 14px 0; border: 1px solid rgba(64,255,94,0.72); border-left: 5px solid #40ff5e; background-color: #0d2812; text-align: left; padding: 6px 0 6px 10px; }
.btn-main { background-color: #14541f; border-left-color: #7dff9e; }
.demobtn { border-radius: 0 14px 14px 0; border-left: 5px solid #40ff5e; }
</style>
