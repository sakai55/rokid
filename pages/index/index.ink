<script def>
{
  "title": "Jinja Bow"
}
</script>

<script setup>
import wx from 'wx';

// JP02 Jinja Bow - 身体即输入 Ritual Sequence
// Local anchor: 日本神社参拜有一套身体记住的顺序：一の鳥居前一揖、手水舎净手漱口、拝殿前摇铃、二拝二拍手一拝。顺序错了不失礼，但心里没底...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const STEPS = ['一の鳥居前で 一揖','手水舎：左手→右手→口→柄','拝殿前で 鈴を鳴らす','二拝：深いお辞儀を二度','二拍手：拍手二度（自己確認）','一拝：最後にもう一度深く'];
const NEED = [1, 1, 1, 2, 1, 1];
const DEMO_S = [{"idx": 2, "done": [true, true, false, false, false, false], "bows": 0, "finished": false, "sensor": "ok", "base": 4, "dipped": false}, {"idx": 3, "done": [true, true, true, false, false, false], "bows": 1, "finished": false, "sensor": "ok", "base": 4, "dipped": true}, {"idx": 6, "done": [true, true, true, true, true, true], "bows": 0, "finished": true, "sensor": "ok", "base": 4, "dipped": false}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"idx": 0, "done": [false, false, false, false, false, false], "bows": 0, "finished": false, "sensor": "unknown", "base": null, "dipped": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._sensorStart();
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _sensorStart() {
    const self = this;
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._s.sensor = 'absent'; return; }
      const sen = new AbsoluteOrientationSensor({ frequency: 30 });
      sen.addEventListener('reading', () => {
        const q = sen.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        const pitch = Math.asin(Math.max(-1, Math.min(1, 2 * (w * x - y * z)))) * 180 / Math.PI;
        self._onPitch(pitch);
      });
      sen.addEventListener('error', () => { self._s.sensor = 'absent'; self._recompute(); });
      sen.start();
      this._sensor = sen; this._s.sensor = 'ok';
    } catch (e) { this._s.sensor = 'absent'; }
  },
  _onPitch(pitch) {
    const s = this._s;
    if (s.base === null || s.base === undefined) { s.base = pitch; return; }
    const d = pitch - s.base;
    if (!s.dipped && d > 16) { s.dipped = true; return; }
    if (s.dipped && d < 8) { s.dipped = false; this._confirm('bow'); }
  },
  _confirm(src) {
    const s = this._s;
    if (s.finished || this._demoIdx >= 0) return;
    s.bows++;
    if (s.bows >= NEED[s.idx]) {
      s.done[s.idx] = true; s.bows = 0; s.idx++;
      if (s.idx >= STEPS.length) { s.finished = true; this._speak('参拝が終わりました。お疲れさまでした。'); }
      else this._speak(STEPS[s.idx]);
    } else {
      this._speak('もう一度、深くお辞儀を。');
    }
    this.setData({ evt: 'EVT: confirm by ' + src + ' - step ' + Math.min(s.idx + 1, 6) + '/6' });
    this._recompute();
  },
  _nodAction() { this._confirm('nod'); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - sequence is fixed, peek only' }); this._recompute(); },
  goTap() { if (this._demoIdx >= 0) return; this._confirm('tap'); },
  act1Tap() { if (this._demoIdx >= 0) return; this._confirm('tap'); },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.idx > 0) { s.idx--; s.done[s.idx] = false; s.bows = 0; s.finished = false; }
    this.setData({ evt: 'EVT: back one step' }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s = { idx: 0, done: [false, false, false, false, false, false], bows: 0, finished: false, sensor: this._s.sensor, base: this._s.base, dipped: false };
    this.setData({ evt: 'EVT: sequence restarted' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const t = s.finished ? '参拝は完了しています。' : ('今は ' + (s.idx + 1) + ' 番目。' + STEPS[s.idx]);
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'current step spoken' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const rows = ['', '', '', ''];
    for (let k = 0; k < 4; k++) {
      const i = Math.min(s.idx, 2) + k - (s.idx >= 4 ? (s.idx - 3) : 0);
    }
    let start = Math.max(0, Math.min(s.idx, STEPS.length - 4));
    for (let k = 0; k < 4; k++) {
      const i = start + k;
      const mark = s.done[i] ? '✓ ' : (i === s.idx ? '► ' : '· ');
      rows[k] = mark + (i + 1) + '. ' + STEPS[i];
    }
    this.setData({
      status: s.finished ? 'DONE: 参拝完了 — お疲れさまでした' : ('STEP ' + (s.idx + 1) + '/6 · センサー ' + (s.sensor === 'ok' ? '有効（お辞儀で確認）' : 'なし（点頭/タップで確認）')),
      hero: s.finished ? '参拝完了' : ('今：' + STEPS[s.idx] + (NEED[s.idx] > 1 ? '（' + s.bows + '/' + NEED[s.idx] + '）' : '')),
      heroSub: '', r1: rows[0], r2: rows[1], r3: rows[2], r4: rows[3], marks: '',
      guide: 'CONFIRM お辞儀/点頭 · BACK 一步戻る · 手は空けて、目は神前へ'
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
    <div class="ttl">JINJA BOW</div>
    <div class="status">{{ status }}</div>
    <div class="scrollbox">
      <div class="srow">{{ r1 }}</div>
      <div class="srow">{{ r2 }}</div>
      <div class="srow">{{ r3 }}</div>
      <div class="srow">{{ r4 }}</div>
    </div>
    <div class="curline">{{ hero }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">CONFIRM</button>
      <button class="btn" bindtap="act2Tap">BACK</button>
      <button class="btn" bindtap="act3Tap">RESTART</button>
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

.scrollbox { border-left: 2px solid rgba(64,255,94,0.72); padding-left: 12px; margin-top: 8px; }
.srow { color: #7dff9e; font-size: 14px; line-height: 24px; white-space: nowrap; overflow: hidden; }
.curline { color: #40ff5e; font-size: 15px; font-weight: bold; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btn { background-color: #0d2812; border: none; border-bottom: 2px solid rgba(64,255,94,0.72); letter-spacing: 4px; padding: 6px 0; }
.btn-main { background-color: #14541f; border-bottom: 4px double #7dff9e; }
.demobtn { background-color: #0d2812; border: none; border-bottom: 2px solid rgba(64,255,94,0.72); letter-spacing: 2px; }
</style>
