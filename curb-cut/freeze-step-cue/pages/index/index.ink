<script def>
{
  "title": "Freeze Step Cue"
}
</script>

<script setup>
import wx from 'wx';

// CC10 freeze-step-cue v2 - rhythm home page.
// Four rhythm sets (content set); pick one and go to the cue page.
// Session history persists in wx storage 'freezeStepCueV2'.
// Life aid only - no medical judgement (see AGENTS.md).
const KEY = 'freezeStepCueV2';
const RHYTHMS = [
  { name: '慢稳', bpm: 50, target: 16, note: '刚起步、家里门口' },
  { name: '日常', bpm: 60, target: 20, note: '平时过门厅、进电梯' },
  { name: '门口短程', bpm: 72, target: 12, note: '只差几步到门口' },
  { name: '长廊', bpm: 56, target: 24, note: '走廊一段、步数多' }
];

export default {
  data: { status: '', r0: '', r1: '', r2: '', r3: '', summary: '', evt: 'EVT: ready' },

  onLoad() { this._sel = 0; try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { sessions: [], totalSteps: 0, rhythm: 1 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const rows = RHYTHMS.map(function (r, i) {
      return (i === this._sel ? '▶ ' : '· ') + r.name + ' · ' + r.bpm + ' 拍/分 · 目标 ' + r.target + ' 步 · ' + r.note;
    }.bind(this));
    const st = this._load();
    const walked = (st.sessions || []).filter(function (s) { return s.result === '走起来了'; }).length;
    this.setData({
      status: '步态冻结节律提示 v2：先选一组节律，再开始一步一拍',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3],
      summary: '已记录 ' + (st.sessions || []).length + ' 次 · 走起来 ' + walked + ' 次 · 累计 ' + (st.totalSteps || 0) + ' 步'
    });
  },
  nextTap() { this._sel = (this._sel + 1) % RHYTHMS.length; this._recompute(); },
  prevTap() { this._sel = (this._sel + RHYTHMS.length - 1) % RHYTHMS.length; this._recompute(); },
  goTap() {
    const st = this._load(); st.rhythm = this._sel; this._save(st);
    try { wx.navigateTo({ url: '/pages/cue/index' }); } catch (e) {}
  },
  recordTap() { try { wx.navigateTo({ url: '/pages/record/index' }); } catch (e) {} },
  speakTap() { const r = RHYTHMS[this._sel]; this._speak('当前节律是' + r.name + '，每分钟' + r.bpm + '拍，目标' + r.target + '步。'); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.goTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Freeze Step Cue</div>
    <div class="status">{{ status }}</div>
    <div class="cards">
      <div class="rcard">{{ r0 }}</div>
      <div class="rcard">{{ r1 }}</div>
      <div class="rcard">{{ r2 }}</div>
      <div class="rcard">{{ r3 }}</div>
    </div>
    <div class="summary">{{ summary }}</div>
    <div class="btnrow">
      <button class="rbtn" bindtap="prevTap">PREV</button>
      <button class="rbtn rbtn-main" bindtap="goTap">START</button>
      <button class="rbtn" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="rbtn" bindtap="recordTap">RECORD</button>
      <button class="rbtn" bindtap="speakTap">SPEAK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.cards { margin-top: 10px; }
.rcard { color: #7dff9e; font-size: 13px; line-height: 20px; border-left: 4px solid rgba(64,255,94,0.7); padding: 4px 8px; margin-top: 6px; background-color: #061a0b; white-space: nowrap; overflow: hidden; }
.summary { color: #40ff5e; font-size: 12px; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 9px; }
.rbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 4px; }
.btnrow .rbtn:last-child { margin-right: 0; }
.rbtn-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
