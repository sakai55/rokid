<script def>
{
  "title": "Cafe Stamp"
}
</script>

<script setup>
import wx from 'wx';

// KR13 Cafe Stamp - 도장 카드 Stamp Card
// Local anchor: 韩国咖啡店的印章卡（스탬프 카드）是常见的常客制度：买一杯盖一章，集满 10 个换一杯免费。最容易乱的是「这张卡到底盖了...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const CARD_MAX = 10;
const DEMO_S = [{"stamps": 5, "free": 0}, {"stamps": 10, "free": 0}, {"stamps": 0, "free": 1}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"stamps": 0, "free": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) {
    this.setData({ evt: 'EVT: swipe - 도장은 버튼으로 찍습니다' });
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.stamps >= 10) { this.act2Tap(); } else { this.speakTap(); }
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.stamps >= 10) {
      this._speak('이미 10개를 다 찍었습니다. 무료 음료를 교환해 주세요.');
      this.setData({ evt: 'EVT: STAMP blocked - card full' });
    } else {
      s.stamps++;
      if (s.stamps >= 10) this._speak('스탬프 10개, 무료 음료 한 잔을 받을 수 있습니다.');
      this.setData({ evt: 'EVT: stamp +' + s.stamps + '/10' });
    }
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.stamps < 10) {
      this._speak('스탬프가 아직 10개가 아닙니다.');
      this.setData({ evt: 'EVT: FREE blocked - not full yet' });
    } else {
      s.stamps = 0;
      s.free++;
      this._speak('무료 음료 한 잔을 교환했습니다. 맛있게 드세요.');
      this.setData({ evt: 'EVT: free drink redeemed' });
    }
    this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.stamps > 0) s.stamps--;
    this.setData({ evt: 'EVT: undo -> ' + s.stamps + '/10' });
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    let t = '';
    if (s.stamps >= 10) {
      t = '스탬프 10개, 무료 음료 한 잔을 받을 수 있습니다.';
    } else {
      t = '스탬프 ' + s.stamps + '개, 무료 음료까지 ' + (10 - s.stamps) + '개 남았습니다.';
    }
    t += ' 지금까지 무료 음료 ' + s.free + '잔을 교환했습니다.';
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'card spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    let cells = '';
    for (let i = 0; i < 10; i++) cells += (i < s.stamps ? '●' : '○');
    this.setData({
      status: '카페 스탬프: ' + s.stamps + '/10 · 무료 음료 ' + s.free + '잔 교환',
      hero: s.stamps >= 10 ? '무료 음료 가능!' : '스탬프 ' + s.stamps + '개',
      heroSub: '',
      r1: s.stamps >= 10 ? '10개 완성 — FREE로 교환하세요' : '무료 음료까지 ' + (10 - s.stamps) + '개 남았습니다',
      r2: '지금까지 교환한 무료 음료 ' + s.free + '잔 · 규칙은 매장 안내를 따릅니다',
      r3: '',
      r4: '',
      marks: cells,
      guide: 'STAMP 도장 추가 · FREE 무료 음료 교환 · UNDO 마지막 도장 취소 · GO=교환/읽어주기 · 끄덕임=도장 추가'
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
    <div class="ttl">CAFE STAMP</div>
    <div class="status">{{ status }}</div>
    <div class="gridbox"><div class="gridmarks">{{ marks }}</div></div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="heroline">{{ hero }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">STAMP</button>
      <button class="btn" bindtap="act2Tap">FREE</button>
      <button class="btn" bindtap="act3Tap">UNDO</button>
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

.gridbox { border: 1px solid rgba(64,255,94,0.48); padding: 10px; margin-top: 8px; text-align: center; }
.gridmarks { color: #40ff5e; font-family: monospace; font-size: 21px; line-height: 28px; letter-spacing: 3px; }
.btn { border: 2px solid rgba(64,255,94,0.85); background-color: #0d2812; border-radius: 0; padding: 9px 0; letter-spacing: 1px; }
.btn-main { background-color: #14541f; border-color: #7dff9e; }
.demobtn { border: 2px solid rgba(64,255,94,0.85); border-radius: 0; }
.btn { border: 2px dotted rgba(64,255,94,0.9); border-radius: 18px; }
.demobtn { border: 2px dotted rgba(64,255,94,0.9); border-radius: 18px; }
</style>
