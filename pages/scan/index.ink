<script def>
{
  "title": "Quiet Corner Scan"
}
</script>

<script setup>
import wx from 'wx';

// CC14 quiet-corner - scan page (compass sound-pressure ring).
// HONEST BOUNDARY: no microphone measures sound pressure. The wearer
// turns slowly in a circle; AbsoluteOrientationSensor yaw (guarded,
// try/catch) gives the relative direction, and the wearer nods when a
// direction FEELS quietest. The agent then shows only that direction plus
// one action sentence, and switches everything else off.
// Sensor missing: the evt line says so honestly and manual direction
// marking still works ("方向参考不可用，仍可用手动方向标记").
// Marked direction persists in wx storage 'quietCornerV1'.
const KEY = 'quietCornerV1';
const DIRS = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];

export default {
  data: { center: '', ring1: '', ring2: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._dir = 0; this._yaw = null; this._yaw0 = null; this._sensorOk = false; this._sensor = null; this._scanning = false;
    this._startSensor();
    if (!this._sensorOk) this.setData({ evt: 'EVT: sensor unavailable - 方向参考不可用，仍可用手动方向标记' });
    this._recompute();
  },
  onHide() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { quiet: null, spots: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _angDiff(a, b) { let d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 30 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        if (self._scanning && self._yaw0 !== null) {
          const deg = self._angDiff(self._yaw, self._yaw0) * 180 / Math.PI;
          self._dir = ((Math.round((deg + 360) / 45) % 8) + 8) % 8;
          self._recompute();
        }
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _recompute() {
    const ring = function (list, cur) { return list.map(function (d, i) { return (i === cur ? '▶' + d : d); }).join('  '); };
    this.setData({
      center: DIRS[this._dir],
      ring1: ring(DIRS.slice(0, 4), this._dir < 4 ? this._dir : -1),
      ring2: ring(DIRS.slice(4, 8), this._dir >= 4 ? this._dir - 4 : -1),
      guide: this._scanning ? '慢慢转，感觉到最安静时点头标记' : (this._sensorOk ? '按 Enter 开始扫描（以当前朝向为中心）' : '方向参考不可用，仍可用手动方向标记')
    });
  },
  startTap() {
    this._scanning = true;
    this._yaw0 = this._yaw;
    this._speak('开始扫描。慢慢转一圈，感觉到最安静的方向就点头。');
    this.setData({ evt: 'EVT: scanning started' });
    this._recompute();
  },
  markTap() {
    const dir = DIRS[this._dir];
    const st = this._load();
    st.quiet = { dir: dir, at: new Date().toISOString().slice(0, 16) };
    this._save(st);
    this._scanning = false;
    this._speak('往' + dir + '走，那边最安静。');
    this.setData({ evt: 'EVT: quiet marked - ' + dir });
    this._recompute();
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
    if (g === 'nod') this.markTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); if (!this._scanning) this.startTap(); else this.markTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._dir = (this._dir + DIRS.length - 1) % DIRS.length; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._dir = (this._dir + 1) % DIRS.length; this._recompute(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">找安静方向</div>
    <div class="ringwrap">
      <div class="ringtop">{{ ring1 }}</div>
      <div class="compass">
        <div class="center">{{ center }}</div>
      </div>
      <div class="ringbot">{{ ring2 }}</div>
    </div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="ringbtn main" bindtap="markTap">标记最安静</button>
      <button class="ringbtn" bindtap="startTap">开始扫描</button>
      <button class="ringbtn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.ringwrap { margin-top: 10px; }
.ringtop { color: #40ff5e; font-size: 13px; letter-spacing: 2px; }
.compass { width: 140px; height: 140px; margin-left: 154px; margin-top: 8px; margin-bottom: 8px; border: 4px solid rgba(64,255,94,0.9); border-radius: 50%; background-color: #061a0b; padding-top: 46px; box-sizing: border-box; }
.center { color: #7dff9e; font-size: 32px; font-weight: bold; }
.ringbot { color: #40ff5e; font-size: 13px; letter-spacing: 2px; }
.guide { color: rgba(125,255,158,0.9); font-size: 12px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.ringbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 7px 0; text-align: center; border-radius: 50%; }
.btnrow .ringbtn:last-child { margin-right: 0; }
.ringbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
