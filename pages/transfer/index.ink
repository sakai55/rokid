<script def>
{
  "title": "Seoul Transfer"
}
</script>

<script setup>
import wx from 'wx';

// KR16 transfer: confirm the platform direction at one of 8 stations.
// ArrowUp/ArrowDown moves between stations, Enter (or nod) locks the
// direction verdict and saves it. Head yaw comes from
// AbsoluteOrientationSensor vs the centre calibrated at page load;
// sensor absent -> the note sentence is still shown and Enter still locks,
// and the evt line says so honestly.
const KEY = 'seoulTransferV1';
const STATIONS = [
  { name: '서울역', lines: '1호선 · 4호선 · 공항철도', dir: '공항철도 타는 곳은 지하 2층 왼쪽 승강장입니다' },
  { name: '시청', lines: '1호선 · 2호선', dir: '2호선 외선순환 방향 승강장으로 가세요' },
  { name: '종로3가', lines: '1호선 · 3호선 · 5호선', dir: '5호선 타는 곳은 지하 3층입니다' },
  { name: '동대문역사문화공원', lines: '2호선 · 4호선 · 5호선', dir: '4호선 타는 곳은 가장 깊은 층입니다' },
  { name: '강남', lines: '2호선 · 신분당선', dir: '신분당선 타는 곳은 지하 4층입니다' },
  { name: '잠실', lines: '2호선 · 8호선', dir: '8호선 타는 곳은 2호선 승강장 끝쪽입니다' },
  { name: '홍대입구', lines: '2호선 · 공항철도 · 경의중앙선', dir: '공항철도 타는 곳은 지하 3층입니다' },
  { name: '고속터미널', lines: '3호선 · 7호선 · 9호선', dir: '9호선 급행 타는 곳은 가운데 승강장입니다' }
];

export default {
  data: { station: '', lines: '', dir: '', verdict: '', sensor: '', evt: 'EVT: ready' },

  onLoad() {
    this._idx = 0; this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null; this._locked = '';
    try { this.enableWorldAwareness(); } catch (e) {}
    this._startSensor();
    this._recompute();
  },
  onHide() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { transfers: [], lastTrainDone: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 30 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        if (self._yaw0 === null) self._yaw0 = self._yaw;
        self._zoneTick();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _angDiff(a, b) { let d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() {
    if (this._yaw === null || this._yaw0 === null) return;
    const dy = this._angDiff(this._yaw, this._yaw0);
    let z = 'C';
    if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R';
    if (z !== this._zone) { this._zone = z; this._recompute(); }
  },
  _recompute() {
    const s = STATIONS[this._idx];
    const zoneText = this._zone === 'L' ? '◀ 왼쪽을 보고 있습니다' : (this._zone === 'R' ? '오른쪽을 보고 있습니다 ▶' : '정면을 보고 있습니다');
    this.setData({
      station: (this._idx + 1) + ' / 8 · ' + s.name,
      lines: s.lines,
      dir: s.dir,
      verdict: this._locked || zoneText,
      sensor: this._sensorOk ? '머리 방향 감지기 사용 중' : '감지기 없음 · 확인 키로 방향을 잠글 수 있습니다'
    });
  },
  _lock() {
    const s = STATIONS[this._idx];
    const side = this._zone === 'L' ? '왼쪽' : (this._zone === 'R' ? '오른쪽' : '정면');
    const st = this._load();
    st.transfers.push({ station: s.name, side: side, at: this._time() });
    this._save(st);
    this._locked = '잠금 완료: ' + s.name + ' · ' + side + ' 방향 · ' + this._time();
    this._speak(s.name + '역, ' + side + ' 방향으로 확인했습니다. ' + s.dir);
    this.setData({ evt: 'EVT: locked - ' + s.name + ' ' + side });
    this._recompute();
  },
  lockTap() { this._lock(); },
  nextTap() { this._idx = (this._idx + 1) % STATIONS.length; this._locked = ''; this._recompute(); },
  prevTap() { this._idx = (this._idx + STATIONS.length - 1) % STATIONS.length; this._locked = ''; this._recompute(); },
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
    if (g === 'nod') this._lock();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this._lock(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Seoul Transfer</div>
    <div class="station">{{ station }}</div>
    <div class="lines">{{ lines }}</div>
    <div class="arrowbox">
      <div class="arrow">◀ ▶</div>
      <div class="verdict">{{ verdict }}</div>
    </div>
    <div class="dir">{{ dir }}</div>
    <div class="sensor">{{ sensor }}</div>
    <div class="btnrow">
      <button class="dirbtn main" bindtap="lockTap">방향 잠금</button>
      <button class="dirbtn" bindtap="nextTap">다음 역</button>
      <button class="dirbtn" bindtap="backTap">뒤로</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; text-align: left; }
.station { color: #7dff9e; font-size: 20px; font-weight: bold; margin-top: 10px; }
.lines { color: #40ff5e; font-size: 12px; margin-top: 4px; }
.arrowbox { border: 3px solid rgba(64,255,94,0.8); background-color: #071c0c; margin: 14px 40px 0 40px; padding: 14px 0 10px 0; }
.arrow { color: #7dff9e; font-size: 30px; font-weight: bold; letter-spacing: 12px; }
.verdict { color: #7dff9e; font-size: 14px; margin-top: 8px; }
.dir { color: #40ff5e; font-size: 13px; margin-top: 12px; }
.sensor { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 6px; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.dirbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 8px; }
.btnrow .dirbtn:last-child { margin-right: 0; }
.dirbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
