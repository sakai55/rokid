<script def>
{
  "title": "Task Anchor Focus"
}
</script>

<script setup>
import wx from 'wx';

// CC13 task-anchor - focus page (hourglass timer dial).
// One task name stays resident at the top. A 25-minute focus segment runs
// on setInterval (1 s tick); every 5 minutes a gentle TTS check-in says
// only "还在 XX 上吗" plus the elapsed time - it only shows, never scolds.
// Enter / nod while running = drift self-report: it speaks the elapsed
// time and the next smallest action, then keeps the timer running.
// Enter / nod while idle = start. DONE finishes the segment and persists
// the log and the cumulative minutes in wx storage 'taskAnchorV1'.
const KEY = 'taskAnchorV1';
const SEG_SEC = 1500;
const TEMPLATES = ['写作业', '写报告', '做家务', '做饭', '复习', '整理房间', '回邮件', '运动'];
const NEXT = ['先写第一题', '先写第一段', '先收拾桌面一件', '先洗一样菜', '先看第一页', '先收一个抽屉', '先回最短的一封', '先热身一分钟'];

export default {
  data: { task: '', big: '', seg: '', hint: '', driftLine: '', evt: 'EVT: ready' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._sel = 0; this._running = false; this._elapsed = 0; this._timer = null; this._lastMark = 0;
    const st = this._load();
    if (st.current && st.current.task) { this._sel = TEMPLATES.indexOf(st.current.task); if (this._sel < 0) this._sel = 0; this._elapsed = st.current.elapsed || 0; }
    this._recompute();
  },
  onHide() { this._stopTimer(); this._persist(); },
  onUnload() { this._stopTimer(); this._persist(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { current: null, logs: [], totalMinutes: 0, drifts: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _persist() {
    const st = this._load();
    st.current = { task: TEMPLATES[this._sel], elapsed: this._elapsed, done: false };
    this._save(st);
  },
  _fmt(s) { const m = Math.floor(s / 60); const r = s % 60; return (m < 10 ? '0' : '') + m + ':' + (r < 10 ? '0' : '') + r; },
  _stopTimer() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },

  _recompute() {
    const task = TEMPLATES[this._sel];
    this.setData({
      task: '正在做：' + task,
      big: this._fmt(this._elapsed),
      seg: '25 分钟专注段 · 剩余 ' + this._fmt(Math.max(0, SEG_SEC - this._elapsed)) + (this._running ? ' · 进行中' : ' · 已暂停'),
      hint: '下一步最小动作：' + NEXT[this._sel],
      driftLine: this._running ? '走神了？按 Enter 自报，只报时间和下一步，不斥责' : '按 Enter 开始；上下键换任务模板'
    });
  },
  _tick() {
    this._elapsed++;
    if (this._elapsed >= SEG_SEC) { this.doneTap(); return; }
    if (this._elapsed % 300 === 0 && this._elapsed !== this._lastMark) {
      this._lastMark = this._elapsed;
      this._speak('还在' + TEMPLATES[this._sel] + '上吗？已经' + Math.floor(this._elapsed / 60) + '分钟了。');
    }
    this._recompute();
  },
  startTap() {
    if (this._running) { this._running = false; this._stopTimer(); this._persist(); this.setData({ evt: 'EVT: paused at ' + this._fmt(this._elapsed) }); this._recompute(); return; }
    this._running = true;
    const self = this;
    this._timer = setInterval(function () { self._tick(); }, 1000);
    this._speak('开始做' + TEMPLATES[this._sel] + '，一次只做这一件。');
    this.setData({ evt: 'EVT: started ' + TEMPLATES[this._sel] });
    this._recompute();
  },
  driftTap() {
    if (!this._running) { this.startTap(); return; }
    const st = this._load();
    st.drifts = (st.drifts || 0) + 1;
    st.current = { task: TEMPLATES[this._sel], elapsed: this._elapsed, done: false };
    this._save(st);
    const msg = '已经' + Math.floor(this._elapsed / 60) + '分钟了，下一步是' + NEXT[this._sel] + '。';
    this._speak(msg);
    this.setData({ evt: 'EVT: drift report - ' + this._fmt(this._elapsed) + ' -> ' + NEXT[this._sel] });
    this._recompute();
  },
  doneTap() {
    this._running = false; this._stopTimer();
    const mins = Math.max(1, Math.round(this._elapsed / 60));
    const st = this._load();
    st.logs = st.logs || [];
    st.logs.push({ task: TEMPLATES[this._sel], minutes: mins, at: new Date().toISOString().slice(0, 16) });
    st.totalMinutes = (st.totalMinutes || 0) + mins;
    st.current = { task: TEMPLATES[this._sel], elapsed: 0, done: true };
    this._save(st);
    this._speak(TEMPLATES[this._sel] + '完成了，一共' + mins + '分钟。');
    this.setData({ evt: 'EVT: done ' + TEMPLATES[this._sel] + ' ' + mins + ' min' });
    this._elapsed = 0;
    this._recompute();
  },
  backTap() { this._stopTimer(); this._persist(); try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.driftTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.driftTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = (this._sel + TEMPLATES.length - 1) % TEMPLATES.length; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % TEMPLATES.length; this._recompute(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="task">{{ task }}</div>
    <div class="dialwrap">
      <div class="dial">
        <div class="big">{{ big }}</div>
        <div class="seg">{{ seg }}</div>
      </div>
    </div>
    <div class="hint">{{ hint }}</div>
    <div class="drift">{{ driftLine }}</div>
    <div class="btnrow">
      <button class="dialbtn main" bindtap="driftTap">自报 / 开始</button>
      <button class="dialbtn" bindtap="doneTap">完成</button>
      <button class="dialbtn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.task { color: #7dff9e; font-size: 20px; font-weight: bold; white-space: nowrap; overflow: hidden; }
.dialwrap { margin-top: 14px; }
.dial { width: 220px; height: 150px; margin-left: 114px; border: 3px solid rgba(64,255,94,0.85); border-radius: 50%; background-color: #071c0c; padding-top: 36px; box-sizing: border-box; }
.big { color: #7dff9e; font-size: 34px; font-weight: bold; font-family: monospace; }
.seg { color: #40ff5e; font-size: 11px; margin-top: 6px; }
.hint { color: #40ff5e; font-size: 14px; margin-top: 14px; white-space: nowrap; overflow: hidden; }
.drift { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 6px; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.dialbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; border-radius: 50%; }
.btnrow .dialbtn:last-child { margin-right: 0; }
.dialbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
