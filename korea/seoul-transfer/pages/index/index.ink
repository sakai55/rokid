<script def>
{
  "title": "Seoul Transfer"
}
</script>

<script setup>
import wx from 'wx';

// KR16 index: line-band overview of 8 transfer stations + last-train status.
// Home-page key contract: ArrowUp/ArrowDown cycles the two sub-pages,
// Enter opens the selected sub-page. Status counts come from real storage.
const KEY = 'seoulTransferV1';
const STATIONS = [
  { name: '서울역', lines: '1호선 · 4호선 · 공항철도' },
  { name: '시청', lines: '1호선 · 2호선' },
  { name: '종로3가', lines: '1호선 · 3호선 · 5호선' },
  { name: '동대문역사문화공원', lines: '2호선 · 4호선 · 5호선' },
  { name: '강남', lines: '2호선 · 신분당선' },
  { name: '잠실', lines: '2호선 · 8호선' },
  { name: '홍대입구', lines: '2호선 · 공항철도 · 경의중앙선' },
  { name: '고속터미널', lines: '3호선 · 7호선 · 9호선' }
];

export default {
  data: { band: '', stations: '', status: '', m0: '', m1: '', hint: '', evt: 'EVT: ready' },

  onLoad() {
    this._sel = 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { transfers: [], lastTrainDone: 0 }; },
  _recompute() {
    const st = this._load();
    const band = STATIONS.map(function (s) { return '● ' + s.name; }).join('  ');
    const list = STATIONS.map(function (s, i) { return (i + 1) + '. ' + s.name + ' — ' + s.lines; }).join('  |  ');
    this.setData({
      band: band,
      stations: list,
      status: '환승역 8곳 · 확인한 환승 ' + st.transfers.length + '건 · 막차 지킨 횟수 ' + st.lastTrainDone + '번',
      m0: (this._sel === 0 ? '▶ ' : '· ') + '환승 확인하기',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '막차 지키기',
      hint: '위·아래 키로 고르고 확인 키로 들어갑니다'
    });
  },
  _open() {
    try { wx.navigateTo({ url: this._sel === 0 ? '/pages/transfer/index' : '/pages/lasttrain/index' }); } catch (e) { this.setData({ evt: 'EVT: navigate failed' }); }
  },
  openTap() { this._open(); },
  upTap() { this._sel = (this._sel + 1) % 2; this._recompute(); },
  downTap() { this._sel = (this._sel + 1) % 2; this._recompute(); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this._open();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this._open(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.upTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.downTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Seoul Transfer</div>
    <div class="band">{{ band }}</div>
    <div class="rail"><div class="railfill"></div></div>
    <div class="stations">{{ stations }}</div>
    <div class="status">{{ status }}</div>
    <div class="modes">
      <div class="mode">{{ m0 }}</div>
      <div class="mode">{{ m1 }}</div>
    </div>
    <div class="hint">{{ hint }}</div>
    <div class="btnrow">
      <button class="linebtn main" bindtap="openTap">들어가기</button>
      <button class="linebtn" bindtap="upTap">다음</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.band { color: #7dff9e; font-size: 12px; margin-top: 8px; line-height: 20px; }
.rail { height: 6px; background-color: #0d2812; margin-top: 4px; border-radius: 3px; }
.railfill { height: 6px; width: 100%; background-color: #40ff5e; border-radius: 3px; }
.stations { color: #40ff5e; font-size: 11px; margin-top: 8px; line-height: 18px; }
.status { color: #7dff9e; font-size: 12px; margin-top: 8px; }
.modes { margin-top: 10px; border-left: 4px solid #40ff5e; padding-left: 10px; }
.mode { color: #7dff9e; font-size: 15px; line-height: 26px; }
.hint { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.linebtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 6px 0; text-align: center; }
.btnrow .linebtn:last-child { margin-right: 0; }
.linebtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
