<script def>
{
  "title": "Jjimjil Rest"
}
</script>

<script setup>
import wx from 'wx';

// KR09 Jjimjil Rest - 冷热循环 Thermal Cycle
// Local anchor: 찜질방（汗蒸房）的玩法是循环：高温房里出一身汗，出来在休息厅吃식이（米露）与烤鸡蛋，缓过来再进去。节奏对了是享受，节奏乱...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const DUR = [720, 480];
const NAMES = ['찜질', '휴식'];
const DEMO_S = [{"phase": 0, "left": 402, "running": true, "cycles": 0, "added": 0}, {"phase": 1, "left": 480, "running": true, "cycles": 0, "added": 0}, {"phase": 0, "left": 720, "running": true, "cycles": 2, "added": 120}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"phase": 0, "left": 720, "running": false, "cycles": 0, "added": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _fmt(sec) { const m = Math.floor(sec / 60); const s = sec % 60; return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s; },
  _tickStart() {
    this._stopTimers();
    const self = this;
    this._timer = setInterval(() => {
      const s = self._s;
      if (s.left > 0) { s.left--; self._recompute(); }
      if (s.left <= 0) self._switch(true);
    }, 1000);
  },
  _switch(auto) {
    const s = this._s;
    if (s.phase === 1) s.cycles++;
    s.phase = (s.phase + 1) % 2; s.left = DUR[s.phase]; s.added = 0;
    this._speak(s.phase === 0 ? '찜질 시간예요。' : '쉬는 시간예요。');
    this.setData({ evt: 'EVT: SWITCH ' + (auto ? 'auto' : 'manual') + ' -> ' + NAMES[s.phase] + ' cycle ' + (s.cycles + 1) });
    this._recompute();
  },
  _nodAction() { this.act2Tap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - cycles are time, not pages' }); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.running = !s.running;
    if (s.running) this._tickStart(); else this._stopTimers();
    this.setData({ evt: 'EVT: cycle ' + (s.running ? 'running' : 'paused') }); this._recompute();
  },
  act2Tap() { if (this._demoIdx >= 0) return; if (this._s.running) this._switch(false); },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s.left += 120; this._s.added += 120;
    this.setData({ evt: 'EVT: +2min (labelled as added time)' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak(NAMES[s.phase] + ' ' + Math.floor(s.left / 60) + '분 남았어요。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'phase' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    this.setData({
      status: 'CYCLE ' + (s.cycles + 1) + ' · 現在 ' + NAMES[s.phase] + (s.added ? '（+' + Math.floor(s.added / 60) + '分 追加あり）' : '') + ' · 効能の話はしません',
      hero: NAMES[s.phase] + ' ' + this._fmt(Math.max(0, s.left)),
      heroSub: '熱 12分 / 休 8分 のリズムだけを守ります',
      r1: '열 ' + this._fmt(s.phase === 0 ? s.left : DUR[0]),
      r2: '휴 ' + this._fmt(s.phase === 1 ? s.left : DUR[1]),
      r3: '', r4: '', marks: '',
      guide: 'START 开始/暂停 · SWITCH 跳段 · +2MIN 加时（如实标注） · 点头=跳段'
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
    <div class="ttl">JJIMJIL REST</div>
    <div class="status">{{ status }}</div>
    <div class="ringrow">
      <div class="ring"><div class="ringv">{{ r1 }}</div></div>
      <div class="ring"><div class="ringv">{{ r2 }}</div></div>
    </div>
    <div class="heroline center">{{ hero }}</div>
    <div class="rline center dim">{{ heroSub }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">START</button>
      <button class="btn" bindtap="act2Tap">SWITCH</button>
      <button class="btn" bindtap="act3Tap">+2MIN</button>
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

.ringrow { display: flex; flex-direction: row; margin-top: 10px; justify-content: center; }
.ring { width: 118px; height: 118px; border: 2px solid rgba(64,255,94,0.65); border-radius: 59px; margin-right: 18px; text-align: center; box-sizing: border-box; padding-top: 42px; }
.ringrow .ring:last-child { margin-right: 0; }
.ringv { color: #7dff9e; font-family: monospace; font-size: 16px; font-weight: bold; }
.btn { border: 4px double #40ff5e; border-radius: 24px; background-color: transparent; padding: 5px 0; }
.btn-main { border-color: #7dff9e; background-color: #0d2812; }
.demobtn { border: 4px double #40ff5e; border-radius: 24px; background-color: transparent; }
</style>
