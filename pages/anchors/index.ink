<script def>
{
  "title": "Retrace Anchors"
}
</script>

<script setup>
import wx from 'wx';

// CC12 anchors: drop a breadcrumb anchor with a nod at each turn or
// landmark. The anchor stores its sequence number, the current relative
// yaw from AbsoluteOrientationSensor when available, and the time.
// Sensor absent -> the anchor is still stored with yawDeg null and the
// page says so honestly; the guide then falls back to pure order.
// No map, no geolocation API is used.
const KEY = 'retraceStepsV1';

export default {
  data: { sensor: '', status: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', evt: '记录: 准备完成' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._yaw = null; this._sensorOk = false; this._sensor = null; this._idx = 0;
    this._startSensor();
    this._recompute();
  },
  onHide() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { anchors: [], guides: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },
  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 20 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        const yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        self._yaw = Math.round(yaw * 180 / Math.PI);
        self._recompute();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _recompute() {
    const st = this._load();
    const anchors = st.anchors || [];
    const shown = anchors.slice(-6);
    const rows = shown.map(function (a, k) {
      const gi = anchors.length - shown.length + k;
      const yawTxt = (a.yawDeg !== null && a.yawDeg !== undefined) ? ('朝向约' + a.yawDeg + '°') : '朝向未记录';
      return (gi === this._idx ? '▶ ' : '　') + '● 锚点' + (gi + 1) + ' · ' + yawTxt + ' · ' + a.at;
    }.bind(this));
    while (rows.length < 6) rows.push('');
    if (anchors.length && this._idx >= anchors.length) this._idx = anchors.length - 1;
    this.setData({
      sensor: this._sensorOk ? '方向参考可用（当前朝向约' + (this._yaw === null ? '—' : this._yaw) + '°）' : '方向参考不可用，仍可用手动顺序引导',
      status: '已落锚点 ' + anchors.length + ' 个（只显示最近 6 个）',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4], r5: rows[5],
      detail: anchors.length ? '当前查看: 锚点' + (this._idx + 1) + ' · 点头或确定键在当前位置再落一个点。' : '还没有锚点：走到转弯/地标处，点头落第一个点。',
      evt: '记录: 锚点' + anchors.length + '个'
    });
  },
  dropTap() {
    const st = this._load();
    if (!st.anchors) st.anchors = [];
    const yawDeg = this._sensorOk ? this._yaw : null;
    st.anchors.push({ n: st.anchors.length + 1, yawDeg: yawDeg, at: this._time(), date: new Date().toISOString().slice(0, 10) });
    this._save(st);
    this._idx = st.anchors.length - 1;
    this._speak('锚点' + st.anchors.length + '已落下。');
    this.setData({ evt: '记录: 落点 锚点' + st.anchors.length });
    this._recompute();
  },
  delTap() {
    const st = this._load();
    if (!st.anchors || !st.anchors.length) { this.setData({ evt: '记录: 没有可删的锚点' }); return; }
    st.anchors.pop();
    this._save(st);
    if (this._idx >= st.anchors.length) this._idx = Math.max(0, st.anchors.length - 1);
    this.setData({ evt: '记录: 删除上一点，剩余' + st.anchors.length + '个' });
    this._recompute();
  },
  nextTap() { const st = this._load(); const n = (st.anchors || []).length; if (!n) return; this._idx = (this._idx + 1) % n; this._recompute(); },
  prevTap() { const st = this._load(); const n = (st.anchors || []).length; if (!n) return; this._idx = (this._idx + n - 1) % n; this._recompute(); },
  guideTap() { try { wx.navigateTo({ url: '/pages/guide/index' }); } catch (e) {} },
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
    if (g === 'nod') this.dropTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.dropTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="sensor">{{ sensor }}</div>
    <div class="rail">
      <div class="arow">{{ r0 }}</div>
      <div class="arow">{{ r1 }}</div>
      <div class="arow">{{ r2 }}</div>
      <div class="arow">{{ r3 }}</div>
      <div class="arow">{{ r4 }}</div>
      <div class="arow">{{ r5 }}</div>
    </div>
    <div class="status">{{ status }}</div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="abtn main" bindtap="dropTap">点头落点</button>
      <button class="abtn" bindtap="delTap">删除上一点</button>
      <button class="abtn" bindtap="guideTap">开始返回</button>
      <button class="abtn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #04140a; padding: 12px 16px; box-sizing: border-box; position: relative; }
.sensor { color: #7dff9e; font-size: 12px; background-color: #0d3d17; padding: 6px 10px; white-space: nowrap; overflow: hidden; }
.rail { margin-top: 10px; border-left: 4px solid #40ff5e; padding-left: 12px; }
.arow { color: #7dff9e; font-size: 14px; line-height: 25px; white-space: nowrap; overflow: hidden; }
.status { color: #40ff5e; font-size: 12px; margin-top: 8px; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 4px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.abtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; }
.btnrow .abtn:last-child { margin-right: 0; }
.abtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 330px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
