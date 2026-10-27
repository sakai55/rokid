<script def>
{
  "title": "並び確認"
}
</script>

<script setup>
import wx from 'wx';

// JP24 home-narabi - queue check (two phases).
// Phase A: pick one of six Yamanote stations (ArrowUp/ArrowDown cycles,
// Enter confirms). Phase B: confirm the queue side - head yaw from
// AbsoluteOrientationSensor (left/right beyond ~20 deg) moves the choice,
// ArrowUp/ArrowDown also cycles it, Enter or nod locks it: TTS announces
// e.g. "左側の列です。ドアは3号車・前寄りです" and the choice is saved to
// wx storage 'homeNarabiV1' for the arrival page. Sensor absent -> keys
// only, said honestly. Segmented motion only: turn, then return to centre.
const KEY = 'homeNarabiV1';
const STATIONS = [
  { name: '新宿', side: '左側', door: '3号車・前寄り' },
  { name: '渋谷', side: '右側', door: '5号車・中央' },
  { name: '池袋', side: '左側', door: '2号車・後寄り' },
  { name: '東京', side: '右側', door: '7号車・中央' },
  { name: '品川', side: '左側', door: '4号車・前寄り' },
  { name: '上野', side: '右側', door: '6号車・後寄り' }
];
const SIDES = ['左側の列', '右側の列'];

export default {
  data: { status: '', big: '', info: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._phase = 'A'; this._stIdx = 0; this._side = 0; this._locked = false;
    this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null;
    const st = this._load();
    if (typeof st.station === 'number' && STATIONS[st.station]) this._stIdx = st.station;
    this._startSensor();
    this._recompute();
  },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { station: 0, queue: null, boards: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 30 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        self._zoneTick();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _angDiff(a, b) { let d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() {
    if (this._phase !== 'B' || this._locked || this._yaw === null || this._yaw0 === null) return;
    const dy = this._angDiff(this._yaw, this._yaw0);
    let z = 'C';
    if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R';
    if (z !== 'C' && this._zone === 'C') { this._side = (z === 'L') ? 0 : 1; this._recompute(); }
    this._zone = z;
  },

  _recompute() {
    const stn = STATIONS[this._stIdx];
    if (this._phase === 'A') {
      this.setData({
        status: '駅を選んでください（上下で移動・Enter で決定）',
        big: stn.name,
        info: 'ホーム側 ' + stn.side + ' ／ ドア ' + stn.door,
        guide: 'センサー： ' + (this._sensorOk ? '頭センサー使用可' : 'センサーなし（キーで確認できます）')
      });
    } else if (!this._locked) {
      this.setData({
        status: stn.name + '： 並ぶ列を確認します',
        big: SIDES[this._side],
        info: 'ドア ' + stn.door + ' ／ 頭を左右に向けて列を選び、点头で確定',
        guide: 'センサー： ' + (this._sensorOk ? '頭センサー使用中' : 'センサーなし（上下キーで選べます）')
      });
    } else {
      this.setData({
        status: stn.name + '： 列を確定しました',
        big: SIDES[this._side] + ' 確定',
        info: 'ドア ' + stn.door + ' ／ 到着守候へ進めます',
        guide: '確定内容は端末に保存済みです'
      });
    }
  },
  mainTap() {
    const stn = STATIONS[this._stIdx];
    if (this._phase === 'A') {
      this._phase = 'B';
      this._side = (stn.side === '左側') ? 0 : 1;
      this._yaw0 = this._yaw; this._zone = 'C';
      this._speak(stn.name + 'です。ホーム側は' + stn.side + '、ドアは' + stn.door + 'です。頭を左右に向けて、並ぶ列を確認してください。');
      this.setData({ evt: 'EVT: station picked - ' + stn.name });
      this._recompute();
      return;
    }
    if (this._locked) { this.setData({ evt: 'EVT: already locked' }); return; }
    this._locked = true;
    const st = this._load();
    st.station = this._stIdx;
    st.queue = { station: stn.name, side: SIDES[this._side], door: stn.door, at: new Date().toISOString() };
    this._save(st);
    this._speak(SIDES[this._side] + 'です。ドアは' + stn.door + 'です。');
    this.setData({ evt: 'EVT: locked - ' + stn.name + ' ' + SIDES[this._side] });
    this._recompute();
  },
  nextTap() {
    if (this._phase === 'A') { this._stIdx = (this._stIdx + 1) % STATIONS.length; }
    else if (!this._locked) { this._side = (this._side + 1) % SIDES.length; }
    this._recompute();
  },
  prevTap() {
    if (this._phase === 'A') { this._stIdx = (this._stIdx + STATIONS.length - 1) % STATIONS.length; }
    else if (!this._locked) { this._side = (this._side + SIDES.length - 1) % SIDES.length; }
    this._recompute();
  },
  arrivalTap() { try { wx.navigateTo({ url: '/pages/arrival/index' }); } catch (e) {} },
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
    if (g === 'nod') this.mainTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.mainTap(); return; }
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">並び確認</div>
    <div class="status">{{ status }}</div>
    <div class="gauge">
      <div class="big">{{ big }}</div>
      <div class="bar"><div class="mark">▼</div></div>
    </div>
    <div class="info">{{ info }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="qbtn main" bindtap="mainTap">決定・確定</button>
      <button class="qbtn" bindtap="nextTap">次へ</button>
      <button class="qbtn" bindtap="arrivalTap">到着守候</button>
      <button class="qbtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; }
.status { color: #7dff9e; font-size: 12px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.gauge { margin-top: 14px; border: 2px solid rgba(64,255,94,0.8); background-color: #071c0c; padding: 16px 0 10px 0; }
.big { color: #7dff9e; font-size: 30px; font-weight: bold; }
.bar { height: 4px; background-color: rgba(64,255,94,0.5); margin: 12px 40px 0 40px; position: relative; }
.mark { color: #40ff5e; font-size: 12px; position: absolute; left: 50%; top: -14px; }
.info { color: #40ff5e; font-size: 13px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.guide { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.qbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 20px; }
.btnrow .qbtn:last-child { margin-right: 0; }
.qbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
