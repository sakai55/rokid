<script def>
{
  "title": "Seoul Transfer"
}
</script>

<script setup>
import wx from 'wx';

// KR16 lasttrain: a manually started last-train countdown.
// ArrowUp/ArrowDown changes the minutes (5/10/15/20/30) while idle,
// Enter starts the setInterval countdown, reaching zero speaks once and
// records one guarded last train in storage.
const KEY = 'seoulTransferV1';
const MINUTES = [5, 10, 15, 20, 30];

export default {
  data: { pick: '', clock: '', status: '', records: '', evt: 'EVT: ready' },

  onLoad() {
    this._mi = 2; this._left = 0; this._timer = null; this._running = false; this._announced = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  onHide() { this._stopTimer(); },
  onUnload() { this._stopTimer(); },
  _stopTimer() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { transfers: [], lastTrainDone: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _fmt(sec) { const m = Math.floor(sec / 60); const s = sec % 60; return m + ':' + (s < 10 ? '0' : '') + s; },
  _recompute() {
    const st = this._load();
    const last = st.transfers.length ? st.transfers[st.transfers.length - 1] : null;
    this.setData({
      pick: '막차까지: ' + MINUTES[this._mi] + '분' + (this._running ? ' · 지키는 중' : ' · 위·아래 키로 분 선택'),
      clock: this._running ? this._fmt(this._left) : this._fmt(MINUTES[this._mi] * 60),
      status: this._running ? '막차를 기다리는 중입니다. 시간이 되면 알려드립니다.' : '확인 키를 누르면 카운트다운이 시작됩니다.',
      records: '확인한 환승 ' + st.transfers.length + '건' + (last ? (' · 최근: ' + last.station + ' ' + last.side + ' ' + last.at) : '') + ' · 막차 지킨 횟수 ' + st.lastTrainDone + '번'
    });
  },
  startTap() {
    if (this._running) return;
    this._running = true; this._announced = false; this._left = MINUTES[this._mi] * 60;
    const self = this;
    this._timer = setInterval(function () {
      self._left--;
      if (self._left <= 0) { self._finish(); return; }
      self._recompute();
    }, 1000);
    this._speak('막차 카운트다운을 시작합니다. ' + MINUTES[this._mi] + '분 남았습니다.');
    this.setData({ evt: 'EVT: countdown started ' + MINUTES[this._mi] + ' min' });
    this._recompute();
  },
  _finish() {
    this._stopTimer(); this._running = false;
    if (!this._announced) {
      this._announced = true;
      const st = this._load();
      st.lastTrainDone = (st.lastTrainDone || 0) + 1;
      this._save(st);
      this._speak('막차 시간입니다. 지금 타는 곳으로 가세요.');
      this.setData({ evt: 'EVT: last train time reached' });
    }
    this._recompute();
  },
  upTap() { if (this._running) return; this._mi = (this._mi + 1) % MINUTES.length; this._recompute(); },
  downTap() { if (this._running) return; this._mi = (this._mi + MINUTES.length - 1) % MINUTES.length; this._recompute(); },
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
    if (key === 'ArrowUp') { event.preventDefault(); this.upTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.downTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Seoul Transfer</div>
    <div class="pick">{{ pick }}</div>
    <div class="clockbox">
      <div class="clock">{{ clock }}</div>
      <div class="clocklabel">막차까지 남은 시간</div>
    </div>
    <div class="status">{{ status }}</div>
    <div class="records">{{ records }}</div>
    <div class="btnrow">
      <button class="clockbtn main" bindtap="startTap">카운트다운 시작</button>
      <button class="clockbtn" bindtap="upTap">분 올리기</button>
      <button class="clockbtn" bindtap="backTap">뒤로</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; text-align: left; }
.pick { color: #7dff9e; font-size: 13px; margin-top: 10px; }
.clockbox { border: 3px solid rgba(64,255,94,0.8); background-color: #04140a; margin: 14px 90px 0 90px; padding: 18px 0 12px 0; border-radius: 50%; }
.clock { color: #7dff9e; font-size: 34px; font-weight: bold; font-family: monospace; }
.clocklabel { color: #40ff5e; font-size: 11px; margin-top: 6px; }
.status { color: #40ff5e; font-size: 13px; margin-top: 14px; }
.records { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.clockbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 6px 0; text-align: center; }
.btnrow .clockbtn:last-child { margin-right: 0; }
.clockbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
