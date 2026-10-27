<script def>
{
  "title": "Task Anchor Log"
}
</script>

<script setup>
import wx from 'wx';

// CC13 task-anchor - log page.
// Completed-task logs and cumulative focus minutes, read from wx storage
// 'taskAnchorV1'. Latest five logs are listed; ArrowUp/ArrowDown move the
// selection, Enter (main action) speaks the selected log aloud.
const KEY = 'taskAnchorV1';

export default {
  data: { totalLine: '', l0: '', l1: '', l2: '', l3: '', l4: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { current: null, logs: [], totalMinutes: 0, drifts: 0 }; },

  _recompute() {
    const st = this._load();
    const logs = (st.logs || []).slice(-5);
    const rows = [];
    for (let i = 0; i < 5; i++) {
      if (i < logs.length) rows.push((i === this._sel ? '▶ ' : '· ') + logs[i].task + ' · ' + logs[i].minutes + ' 分钟 · ' + logs[i].at);
      else rows.push('');
    }
    this.setData({
      totalLine: '累计专注 ' + (st.totalMinutes || 0) + ' 分钟 · 完成 ' + (st.logs || []).length + ' 个任务' + (logs.length === 0 ? ' · 还没有完成记录' : ''),
      l0: rows[0], l1: rows[1], l2: rows[2], l3: rows[3], l4: rows[4]
    });
  },
  speakTap() {
    const st = this._load();
    const logs = (st.logs || []).slice(-5);
    if (logs.length === 0) { this._speak('还没有完成记录。'); this.setData({ evt: 'EVT: no logs yet' }); return; }
    const item = logs[Math.min(this._sel, logs.length - 1)];
    this._speak(item.task + '，' + item.minutes + '分钟。');
    this.setData({ evt: 'EVT: spoke log - ' + item.task });
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.speakTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = Math.max(0, this._sel - 1); this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = Math.min(4, this._sel + 1); this._recompute(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">完成记录</div>
    <div class="total">{{ totalLine }}</div>
    <div class="list">
      <div class="lrow">{{ l0 }}</div>
      <div class="lrow">{{ l1 }}</div>
      <div class="lrow">{{ l2 }}</div>
      <div class="lrow">{{ l3 }}</div>
      <div class="lrow">{{ l4 }}</div>
    </div>
    <div class="note">记录只记任务名、分钟数与时间，不记评价；走神自报不扣分、不留斥责记录。</div>
    <div class="btnrow">
      <button class="logbtn main" bindtap="speakTap">播报</button>
      <button class="logbtn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.total { color: #7dff9e; font-size: 13px; margin-top: 4px; }
.list { margin-top: 14px; border-top: 2px solid rgba(64,255,94,0.7); border-bottom: 2px solid rgba(64,255,94,0.7); padding: 10px 0; }
.lrow { color: #7dff9e; font-size: 14px; line-height: 26px; white-space: nowrap; overflow: hidden; min-height: 26px; }
.note { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 12px; line-height: 16px; }
.btnrow { display: flex; flex-direction: row; margin-top: 16px; }
.logbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; border-radius: 6px; }
.btnrow .logbtn:last-child { margin-right: 0; }
.logbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
