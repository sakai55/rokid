<script def>
{
  "title": "Freeze Cue"
}
</script>

<script setup>
import wx from 'wx';

// CC10 v2 cue page: the rhythm line runs at the set BPM; each beat moves the
// block on the line and the TTS counts aloud in fours. A step is counted
// from a head pitch dip (AbsoluteOrientationSensor vs the centre calibrated
// at start) or, honestly labelled, from a temple tap when no sensor exists.
// Reaching the target settles as 'walked'; running past the time limit
// settles as 'rest' and tells the user to hold on and rest.
const KEY = 'freezeStepCueV2';
const RHYTHMS = [
  { name: '慢稳', bpm: 50, target: 16, note: '刚起步、家里门口' },
  { name: '日常', bpm: 60, target: 20, note: '平时过门厅、进电梯' },
  { name: '门口短程', bpm: 72, target: 12, note: '只差几步到门口' },
  { name: '长廊', bpm: 56, target: 24, note: '走廊一段、步数多' }
];

export default {
  data: { status: '', big: '', line: '', info: '', evt: 'EVT: ready' },

  onLoad() {
    const st = this._load();
    this._r = RHYTHMS[(st && typeof st.rhythm === 'number') ? st.rhythm : 1];
    this._running = false; this._done = false; this._steps = 0; this._beats = 0; this._t0 = 0;
    this._pitch = null; this._pitch0 = null; this._dipped = false; this._sensorOk = false; this._sensor = null; this._timer = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._startSensor();
    this._recompute();
  },
  onHide() { this._stopTimer(); },
  onUnload() { this._stopTimer(); if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _stopTimer() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } this._running = false; },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { sessions: [], totalSteps: 0, rhythm: 1 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _limitSec() { return Math.ceil(this._r.target * 120 / this._r.bpm); },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 30 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        const sp = 2 * (w * x - y * z);
        self._pitch = sp >= 1 ? Math.PI / 2 : (sp <= -1 ? -Math.PI / 2 : Math.asin(sp));
        self._stepTick();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _stepTick() {
    if (!this._running || this._pitch === null || this._pitch0 === null) return;
    const dp = this._pitch - this._pitch0;
    if (!this._dipped && dp <= -0.20) { this._dipped = true; this._countStep(); }
    if (this._dipped && dp >= -0.08) this._dipped = false;
  },
  _countStep() {
    if (!this._running || this._done) return;
    this._steps++;
    if (this._steps % 8 === 0) this._speak('已走' + this._steps + '步');
    if (this._steps >= this._r.target) { this._finish('走起来了'); return; }
    this._recompute();
  },

  startTap() {
    if (this._running || this._done) return;
    this._steps = 0; this._beats = 0; this._t0 = Date.now();
    this._pitch0 = this._pitch; this._dipped = false;
    this._running = true;
    this._speak('开始。跟着节拍，一步，一步。');
    const self = this;
    const stepMs = Math.round(60000 / this._r.bpm);
    this._timer = setInterval(function () {
      self._beats++;
      if (self._beats % 4 === 0) self._speak(String(self._beats));
      if (Date.now() - self._t0 > self._limitSec() * 1000) { self._finish('超时休息'); return; }
      self._recompute();
    }, stepMs);
    this._recompute();
  },
  _finish(result) {
    this._stopTimer();
    this._done = true;
    const st = this._load();
    st.sessions = st.sessions || [];
    st.sessions.push({ date: new Date().toISOString().slice(0, 10), rhythm: this._r.name, steps: this._steps, result: result });
    st.totalSteps = (st.totalSteps || 0) + this._steps;
    this._save(st);
    if (result === '走起来了') this._speak('走起来了。很好，继续稳稳地走。');
    else this._speak('先停下来，扶稳，休息一下。不着急。');
    this.setData({ evt: 'EVT: finished - ' + result });
    this._recompute();
  },
  stopTap() { if (this._running) this._finish('手动停下'); },
  backTap() { this._stopTimer(); try { wx.navigateBack({}); } catch (e) {} },

  _recompute() {
    const pos = this._beats % 20;
    let line = '';
    for (let i = 0; i < 20; i++) line += (i === pos ? '█' : '─');
    let head = '准备：扶稳站好，选好前方落脚处';
    if (this._done) head = (this._steps >= this._r.target) ? '结算：走起来了' : '结算：先扶稳休息';
    else if (this._running) head = '节拍进行中：一步一拍，不要抢拍';
    this.setData({
      status: '节律提示：' + this._r.name + ' · ' + this._r.bpm + ' 拍/分 · ' + (this._sensorOk ? '头部传感器记步' : '无传感器：单击记步'),
      big: this._steps + ' / ' + this._r.target + ' 步',
      line: line,
      info: head + ' · 已用 ' + (this._running || this._done ? Math.round((Date.now() - this._t0) / 1000) : 0) + ' 秒 / 上限 ' + this._limitSec() + ' 秒'
    });
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); if (this._running) this._countStep(); else this.startTap(); return; }
  },
  onKeyUp(event) { if (event.key === 'Enter') event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Step Cue</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="line">{{ line }}</div>
    <div class="info">{{ info }}</div>
    <div class="warn">生活辅助，不是医疗判断。头晕或站不稳，立刻停下扶稳。</div>
    <div class="btnrow">
      <button class="cuebtn main" bindtap="startTap">START</button>
      <button class="cuebtn" bindtap="stopTap">STOP</button>
      <button class="cuebtn" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 14px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.big { color: #7dff9e; font-size: 54px; font-weight: bold; text-align: center; margin-top: 26px; font-family: monospace; }
.line { color: #40ff5e; font-size: 20px; text-align: center; margin-top: 18px; letter-spacing: 2px; font-family: monospace; white-space: nowrap; overflow: hidden; }
.info { color: #40ff5e; font-size: 13px; text-align: center; margin-top: 14px; white-space: nowrap; overflow: hidden; }
.warn { color: rgba(125,255,158,0.8); font-size: 11px; text-align: center; margin-top: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 16px; }
.cuebtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); font-size: 15px; padding: 8px 0; text-align: center; border-radius: 6px; }
.btnrow .cuebtn:last-child { margin-right: 0; }
.cuebtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
