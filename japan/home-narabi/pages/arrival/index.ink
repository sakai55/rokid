<script def>
{
  "title": "到着守候"
}
</script>

<script setup>
import wx from 'wx';

// JP24 home-narabi - arrival watch.
// Presets 1/3/5 minutes (ArrowUp/ArrowDown cycles), Enter or nod starts a
// manual countdown (setInterval, 1 s tick). At zero, TTS announces arrival
// with the locked queue side and door car, and a boarding record
// (station, side, door, time) is appended to wx storage 'homeNarabiV1'.
// Stopping early saves nothing. Past records are counted on the board.
const KEY = 'homeNarabiV1';
const PRESETS = [60, 180, 300];
const STATIONS = [
  { name: '新宿', side: '左側', door: '3号車・前寄り' },
  { name: '渋谷', side: '右側', door: '5号車・中央' },
  { name: '池袋', side: '左側', door: '2号車・後寄り' },
  { name: '東京', side: '右側', door: '7号車・中央' },
  { name: '品川', side: '左側', door: '4号車・前寄り' },
  { name: '上野', side: '右側', door: '6号車・後寄り' }
];

export default {
  data: { status: '', clock: '', queue: '', record: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._preset = 1; this._running = false; this._left = 0; this._timer = null; this._recompute(); },
  onHide() { this._stopTimer(); },
  onUnload() { this._stopTimer(); },
  _stopTimer() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { station: 0, queue: null, boards: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _mmss(s) { const m = Math.floor(s / 60); const r = s % 60; return m + ':' + (r < 10 ? '0' : '') + r; },

  _recompute() {
    const st = this._load();
    const q = st.queue;
    const queueTxt = q ? ('並ぶ列： ' + q.station + ' ' + q.side + ' ／ ドア ' + q.door) : '並ぶ列： 未確定（先に並び確認で確定してください）';
    const boards = st.boards || [];
    const last = boards.length ? boards[boards.length - 1] : null;
    this.setData({
      status: '到着守候： 開始したら到着まで見守ります',
      clock: this._running ? this._mmss(this._left) : (PRESETS[this._preset] / 60) + '分',
      queue: queueTxt,
      record: last ? ('乗車記録 ' + boards.length + ' 件 ／ 前回 ' + last.station + ' ' + last.at) : ('乗車記録 ' + boards.length + ' 件')
    });
  },
  startTap() {
    if (this._running) return;
    this._running = true;
    this._left = PRESETS[this._preset];
    this._speak('到着まで見守ります。あと' + (PRESETS[this._preset] / 60) + '分です。');
    const self = this;
    this._timer = setInterval(function () {
      self._left--;
      if (self._left <= 0) { self._finish(); return; }
      self._recompute();
    }, 1000);
    this.setData({ evt: 'EVT: countdown started ' + PRESETS[this._preset] + 's' });
    this._recompute();
  },
  _finish() {
    this._stopTimer();
    this._running = false;
    const st = this._load();
    const q = st.queue;
    const stn = (typeof st.station === 'number' && STATIONS[st.station]) ? STATIONS[st.station] : STATIONS[0];
    const rec = {
      station: q ? q.station : stn.name,
      side: q ? q.side : stn.side,
      door: q ? q.door : stn.door,
      at: new Date().toISOString().slice(0, 16).replace('T', ' ')
    };
    const boards = st.boards || [];
    boards.push(rec);
    st.boards = boards;
    this._save(st);
    this._speak('電車が到着します。' + rec.side + '、ドアは' + rec.door + 'です。お気をつけて。');
    this.setData({ evt: 'EVT: arrived - ' + rec.station + ' ' + rec.side });
    this._recompute();
  },
  stopTap() {
    if (!this._running) return;
    this._stopTimer();
    this._running = false;
    this.setData({ evt: 'EVT: countdown stopped' });
    this._recompute();
  },
  nextTap() { if (this._running) return; this._preset = (this._preset + 1) % PRESETS.length; this._recompute(); },
  prevTap() { if (this._running) return; this._preset = (this._preset + PRESETS.length - 1) % PRESETS.length; this._recompute(); },
  backTap() { this._stopTimer(); try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.startTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.startTap(); return; }
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">到着守候</div>
    <div class="status">{{ status }}</div>
    <div class="clockbox">
      <div class="clock">{{ clock }}</div>
      <div class="cap">到着まで</div>
    </div>
    <div class="queue">{{ queue }}</div>
    <div class="record">{{ record }}</div>
    <div class="btnrow">
      <button class="arrbtn main" bindtap="startTap">開始</button>
      <button class="arrbtn" bindtap="stopTap">停止</button>
      <button class="arrbtn" bindtap="nextTap">時間切替</button>
      <button class="arrbtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #7dff9e; font-size: 19px; font-weight: bold; }
.status { color: #40ff5e; font-size: 12px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.clockbox { margin-top: 14px; border-top: 3px solid rgba(64,255,94,0.8); border-bottom: 3px solid rgba(64,255,94,0.8); padding: 12px 0; text-align: center; }
.clock { color: #7dff9e; font-size: 56px; font-weight: bold; font-family: monospace; }
.cap { color: #40ff5e; font-size: 12px; margin-top: 2px; }
.queue { color: #7dff9e; font-size: 13px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.record { color: #40ff5e; font-size: 12px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.arrbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 12px; }
.btnrow .arrbtn:last-child { margin-right: 0; }
.arrbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
