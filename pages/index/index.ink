<script def>
{
  "title": "High Shelf Ask"
}
</script>

<script setup>
import wx from 'wx';

// CC09 high-shelf-ask - 高层货架求助话 Shelf Ask
const ITEMS = [{"label": "洗发水", "sub": "第3层左数第2件"}, {"label": "酱油", "sub": "第4层左数第1件"}, {"label": "洗衣液", "sub": "第3层左数第4件"}, {"label": "麦片", "sub": "第5层左数第3件"}, {"label": "牙膏", "sub": "第2层左数第2件"}];
const DEMO_S = [{"idx": 0, "done": [true, false, false, false, false], "cycles": 0}, {"idx": 1, "done": [true, true, false, false, false], "cycles": 0}, {"idx": 4, "done": [true, true, true, true, true], "cycles": 1}];
const N_KIND = "done";
const DONE_T = "已取到";
const TODO_T = "待取";

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"idx": 0, "done": ITEMS.map(() => false), "cycles": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers(); },

  _nodAction() { this._checkOrSpeak(); },
  _swipe(dir) {
    this.setData({ evt: 'EVT: swipe' });
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    this._checkOrSpeak();
  },
  _checkOrSpeak() {
    const s = this._s;
    if (!s.done[s.idx]) {
      s.done[s.idx] = true;
      this._speak('请帮我拿' + ITEMS[s.idx].sub + '的' + ITEMS[s.idx].label + '，谢谢。');
      this.setData({ evt: 'EVT: checked - ' + ITEMS[s.idx].label });
      if (s.done.every(Boolean)) { s.cycles++; }
    } else {
      this.speakTap();
    }
    this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.idx = (s.idx + 1) % ITEMS.length;
    this.setData({ evt: 'EVT: next -> ' + ITEMS[s.idx].label });
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._checkOrSpeak();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.idx = (s.idx + ITEMS.length - 1) % ITEMS.length;
    this.setData({ evt: 'EVT: prev -> ' + ITEMS[s.idx].label });
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const t = s.done[s.idx] ? ITEMS[s.idx].label + '（' + ITEMS[s.idx].sub + '）已经取到了。' : ITEMS[s.idx].label + '（' + ITEMS[s.idx].sub + '），还没取到。';
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    let marks = '';
    for (let i = 0; i < ITEMS.length; i++) marks += (s.done[i] ? '●' : '○') + (i < ITEMS.length - 1 ? ' ' : '');
    const doneCount = s.done.filter(Boolean).length;
    this.setData({
      status: '高层货架：当前' + ITEMS[s.idx].label + '（' + ITEMS[s.idx].sub + '）·' + (s.done[s.idx] ? DONE_T : TODO_T),
      hero: ITEMS[s.idx].label,
      heroSub: ITEMS[s.idx].sub,
      r1: ITEMS.map((it, i) => (i === s.idx ? '▶' : '·') + it.label).join(' '),
      r2: 'PROGRESS ' + doneCount + '/' + ITEMS.length + ' · CYCLES ' + s.cycles,
      marks: marks,
      guide: "NEXT 下一件 · GOT 已取到 · PREV 上一件 · GO=取到/代说 · 点头=取到"
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
    <div class="ttl">High Shelf Ask</div>
    <div class="status">{{ status }}</div>
    <div class="linebox">
      <div class="dots">{{ marks }}</div>
      <div class="stations">{{ r1 }}</div>
    </div>
    <div class="heroline">{{ hero }}</div>
    <div class="rline dim">{{ heroSub }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">NEXT</button>
      <button class="btn" bindtap="act2Tap">GOT</button>
      <button class="btn" bindtap="act3Tap">PREV</button>
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
.btn { flex: 1; margin-right: 6px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 13px; padding: 5px 0; text-align: center; border-radius: 0px; }
.btnrow .btn:last-child { margin-right: 0; }
.btn-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.guide { color: rgba(64,255,94,0.62); font-size: 10px; line-height: 13px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.rline { color: #7dff9e; font-size: 12px; line-height: 16px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.dim { color: rgba(125,255,158,0.75); }
.center { text-align: center; }
.mono { font-family: monospace; }
.heroline { color: #40ff5e; font-size: 16px; font-weight: bold; line-height: 21px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.foot { position: absolute; left: 14px; top: 322px; width: 350px; color: rgba(64,255,94,0.66); font-family: monospace; font-size: 9px; line-height: 12px; white-space: nowrap; overflow: hidden; }
.demobtn { position: absolute; left: 388px; top: 312px; width: 78px; height: 28px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 12px; text-align: center; border-radius: 0px; }
.linebox { margin-top: 12px; border-top: 2px solid rgba(64,255,94,0.6); padding-top: 8px; }
.dots { color: #40ff5e; font-family: monospace; font-size: 19px; letter-spacing: 2px; text-align: center; }
.stations { color: #7dff9e; font-size: 11px; text-align: center; margin-top: 4px; white-space: nowrap; overflow: hidden; }
</style>
