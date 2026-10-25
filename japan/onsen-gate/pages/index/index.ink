<script def>
{
  "title": "Onsen Gate"
}
</script>

<script setup>
import wx from 'wx';

// JP05 Onsen Gate - 门禁阈限 Threshold Gates
// Local anchor: 日本の温泉・銭湯有一套不写在墙上也人人懂的规矩：湯船の前に体を洗う、タオルは湯船に入れない、髪は束ねる。对初次去的人（和...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const GATES = ['掛け湯・体を洗う', '髪を束ねる 毛巾は湯船外', '静かに浸かる'];
const RULES = ['湯船の前に、掛け湯と洗体を。石鹸の泡は流してから。', '長い髪は束ねる。タオルは湯船に入れず、縁に置く。', '静かに入り、泳がない。目安は10分、無理はしない。'];
const DEMO_S = [{"gate": 1, "done": [true, false, false], "soak": -1, "running": false}, {"gate": 3, "done": [true, true, true], "soak": 600, "running": true}, {"gate": 3, "done": [true, true, true], "soak": 187, "running": true}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"gate": 0, "done": [false, false, false], "soak": -1, "running": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _fmt(sec) { const m = Math.floor(sec / 60); const s = sec % 60; return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s; },
  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - gates open in order only' }); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.gate < 3) {
      s.done[s.gate] = true; s.gate++;
      this._speak(s.gate < 3 ? ('次の門です。' + GATES[s.gate]) : '三つの門を通りました。どうぞお湯へ。');
      if (s.gate >= 3) { s.soak = 600; s.running = true; this._startSoak(); }
      this.setData({ evt: 'EVT: gate passed ' + s.gate + '/3' }); this._recompute(); return;
    }
    s.running = !s.running;
    if (s.running) this._startSoak(); else this._stopTimers();
    this.setData({ evt: 'EVT: soak timer ' + (s.running ? 'resumed' : 'paused') }); this._recompute();
  },
  _startSoak() {
    this._stopTimers();
    const self = this;
    this._timer = setInterval(() => {
      if (self._s.soak > 0) { self._s.soak--; self._recompute(); }
      if (self._s.soak <= 0) { self._stopTimers(); self._s.running = false; self._speak('10分たちました。上がりましょう。'); self._recompute(); }
    }, 1000);
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    const t = s.gate < 3 ? RULES[s.gate] : 'あとは静かに。水分は上がってから摂りましょう。';
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: RULE ' + (ok ? 'spoken' : 'FAIL') }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.gate > 0 && s.gate < 3) { s.gate--; s.done[s.gate] = false; }
    if (s.gate >= 3) { this._stopTimers(); s.gate = 2; s.done[2] = false; s.soak = -1; s.running = false; }
    this.setData({ evt: 'EVT: back one gate' }); this._recompute();
  },
  speakTap() { this.act2Tap(); },
  _recompute() {
    const s = this._s;
    const rows = GATES.map((g, i) => g + '｜' + (s.done[i] ? '通過 ✓' : (i === s.gate ? '現在 — 本人確認で通過' : '未')));
    this.setData({
      status: s.gate < 3 ? ('GATE ' + (s.gate + 1) + '/3 · カメラは一切使いません') : ('SOAK: 入池中 ' + this._fmt(Math.max(0, s.soak)) + (s.running ? '' : '（一時停止）')),
      hero: s.gate < 3 ? ('門 ' + (s.gate + 1) + '：' + GATES[s.gate]) : ('湯船 ' + this._fmt(Math.max(0, s.soak))),
      heroSub: s.gate < 3 ? '前の門を通らないと次は開きません' : '10分の目安です。無理はしないでください',
      r1: rows[0], r2: rows[1], r3: rows[2], r4: '', marks: '',
      guide: 'PASS 通过此门 · RULE 听规矩 · BACK 回上一门 · 点头=PASS'
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
    <div class="ttl">ONSEN GATE</div>
    <div class="status">{{ status }}</div>
    <div class="gaterow">
      <div class="gate"><div class="gname">{{ r1 }}</div></div>
      <div class="gate"><div class="gname">{{ r2 }}</div></div>
      <div class="gate"><div class="gname">{{ r3 }}</div></div>
    </div>
    <div class="heroline center">{{ hero }}</div>
    <div class="rline center dim">{{ heroSub }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">PASS</button>
      <button class="btn" bindtap="act2Tap">RULE</button>
      <button class="btn" bindtap="act3Tap">BACK</button>
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

.gaterow { display: flex; flex-direction: row; margin-top: 10px; }
.gate { flex: 1; margin-right: 8px; border: 2px solid rgba(64,255,94,0.6); border-bottom: none; height: 86px; padding: 8px 6px; box-sizing: border-box; }
.gaterow .gate:last-child { margin-right: 0; }
.gname { color: #7dff9e; font-size: 12px; line-height: 17px; text-align: center; }
.btn { border: 2px solid rgba(64,255,94,0.7); border-bottom: none; background-color: transparent; padding: 10px 0 6px; }
.btn-main { border-color: #7dff9e; background-color: #0d2812; }
.demobtn { border: 2px solid rgba(64,255,94,0.7); border-bottom: none; background-color: transparent; }
</style>
