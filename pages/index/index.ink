<script def>
{
  "title": "Samgyeop Flip"
}
</script>

<script setup>
import wx from 'wx';

// KR01 Samgyeop Flip - 烤盘节拍 Grill Metronome
// Local anchor: 韩式烤肉（삼겹살）是一桌人的共同工程：谁负责烤、什么时候翻面、什么时候剪段，全桌都在等一个节奏。翻早了没焦香，翻晚了就苦...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const SIDE_SECS = [45, 40];
const DEMO_S = [{"side": 0, "left": 23, "running": true, "flips": 0, "cuts": 0, "pieces": 6, "batch": 1}, {"side": 1, "left": 40, "running": true, "flips": 1, "cuts": 0, "pieces": 6, "batch": 1}, {"side": 1, "left": 7, "running": true, "flips": 3, "cuts": 6, "pieces": 6, "batch": 2}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"side": 0, "left": 45, "running": false, "flips": 0, "cuts": 0, "pieces": 6, "batch": 1};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _tickStart() {
    this._stopTimers();
    const self = this;
    this._timer = setInterval(() => {
      const s = self._s;
      if (s.left > 0) { s.left--; self._recompute(); }
      if (s.left <= 0) { self._flip(true); }
    }, 1000);
  },
  _flip(auto) {
    const s = this._s;
    s.flips++; s.side = (s.side + 1) % 2; s.left = SIDE_SECS[s.side];
    this._speak(s.side === 0 ? '새 배치처럼, 첫 면입니다。' : '뒤집으세요。');
    this.setData({ evt: 'EVT: FLIP ' + (auto ? 'auto at 0s' : 'manual') + ' -> side ' + (s.side + 1) });
    this._recompute();
  },
  _nodAction() { if (this._s.running) this._flip(false); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - rhythm is time, not pages' }); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.running = !s.running;
    if (s.running) { this._tickStart(); this._speak('굽기 시작합니다。'); } else this._stopTimers();
    this.setData({ evt: 'EVT: timer ' + (s.running ? 'started' : 'paused') }); this._recompute();
  },
  act2Tap() { if (this._demoIdx >= 0) return; if (this._s.running) this._flip(false); },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.cuts++;
    if (s.cuts >= s.pieces) { s.cuts = 0; s.batch++; s.flips = 0; this._speak('이 배치는 먹어도 돼요。다음 배치를 올려요。'); }
    this.setData({ evt: 'EVT: CUT ' + s.cuts + '/' + s.pieces + ' batch ' + s.batch }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak((s.side + 1) + '면, ' + s.left + '초 남았어요。가위 ' + s.cuts + '번。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'status' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    this.setData({
      status: s.running ? ('GRILL: 배치 ' + s.batch + ' · ' + (s.side + 1) + '면 굽는 중') : 'SETUP: START로 타이머 시작 · 익은 정도는 색과 탄력으로 직접 확인',
      hero: String(s.left), heroSub: (s.side + 1) + '면 · ' + SIDE_SECS[s.side] + '초',
      r1: '고기 ' + s.pieces + '점 · 뒤집기 ' + s.flips + '회',
      r2: '가위 ' + s.cuts + '/' + s.pieces + ' — 차면 배치 완료',
      r3: '', r4: '', marks: '박자만 지킵니다 · 익은 정도는 단정하지 않아요',
      guide: 'START 시작/일시정지 · FLIP 바로 뒤집기 · CUT 한 조각 자르기 · 끄덕임=FLIP'
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
    <div class="ttl">SAMGYEOP FLIP</div>
    <div class="status">{{ status }}</div>
    <div class="grillwrap">
      <div class="grill"><div class="grillsec">{{ hero }}</div><div class="grillsub">{{ heroSub }}</div></div>
      <div class="grillside"><div class="rline">{{ r1 }}</div><div class="rline">{{ r2 }}</div><div class="rline dim">{{ marks }}</div></div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">START</button>
      <button class="btn" bindtap="act2Tap">FLIP</button>
      <button class="btn" bindtap="act3Tap">CUT</button>
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

.grillwrap { display: flex; flex-direction: row; margin-top: 8px; }
.grill { width: 148px; height: 148px; border: 2px solid rgba(64,255,94,0.72); border-radius: 74px; text-align: center; box-sizing: border-box; padding-top: 44px; }
.grillsec { color: #40ff5e; font-family: monospace; font-size: 30px; font-weight: bold; }
.grillsub { color: #7dff9e; font-size: 11px; margin-top: 2px; }
.grillside { flex: 1; margin-left: 14px; padding-top: 26px; }
.btn { border-radius: 26px; background-color: #14541f; border: 2px solid #40ff5e; padding: 8px 0; font-weight: bold; }
.btn-main { background-color: #40ff5e; color: #06280f; border-color: #7dff9e; }
.demobtn { border-radius: 26px; background-color: #14541f; border: 2px solid #40ff5e; }
</style>
