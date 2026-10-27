<script def>
{
  "title": "ホームの並び"
}
</script>

<script setup>
import wx from 'wx';

// JP24 home-narabi - station board (home page).
// Horizontal platform strip: six Yamanote stations, each with a platform
// side and a door car (6 x 2 content set). The board shows the station
// carried over from the last queue check (default 新宿); changing the
// station happens at the head of the queue page. ArrowUp/ArrowDown cycles
// the two subpages (▶ marker), Enter opens the selected one. State in wx
// storage 'homeNarabiV1'.
const KEY = 'homeNarabiV1';
const STATIONS = [
  { name: '新宿', side: '左側', door: '3号車・前寄り' },
  { name: '渋谷', side: '右側', door: '5号車・中央' },
  { name: '池袋', side: '左側', door: '2号車・後寄り' },
  { name: '東京', side: '右側', door: '7号車・中央' },
  { name: '品川', side: '左側', door: '4号車・前寄り' },
  { name: '上野', side: '右側', door: '6号車・後寄り' }
];

export default {
  data: { status: '', strip: '', detail: '', m0: '', m1: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { station: 0, queue: null, boards: [] }; },
  _station(st) { const i = (st.station || 0); return STATIONS[i] || STATIONS[0]; },

  _recompute() {
    const st = this._load();
    const cur = this._station(st);
    let strip = '';
    STATIONS.forEach(function (s, i) { strip += (s.name === cur.name ? '●' : '○') + s.name + (i < STATIONS.length - 1 ? '─' : ''); });
    const boards = st.boards || [];
    this.setData({
      status: 'ホームの並び： 並ぶ列とドア位置を頭で確認',
      strip: strip,
      detail: 'いまの駅： ' + cur.name + ' ／ ホーム側 ' + cur.side + ' ／ ドア ' + cur.door + ' ／ 乗車記録 ' + boards.length + ' 件',
      m0: (this._sel === 0 ? '▶ ' : '· ') + '並び確認（駅は入ってから選べます）',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '到着守候'
    });
  },
  // Selection contract: sel 0 -> pages[1] (first subpage), sel 1 -> pages[2]
  // (second subpage); onShow resets sel to 0, so returning from a subpage
  // via Backspace always lands on the first subpage.
  _open() { try { wx.navigateTo({ url: this._sel === 0 ? '/pages/queue/index' : '/pages/arrival/index' }); } catch (e) {} },
  queueTap() { this._sel = 0; this._open(); },
  arrivalTap() { this._sel = 1; this._open(); },
  speakTap() {
    const cur = this._station(this._load());
    this._speak('ホームの並びです。いまの駅は' + cur.name + '、ホーム側は' + cur.side + '、ドアは' + cur.door + 'です。');
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this._open(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">ホームの並び</div>
    <div class="status">{{ status }}</div>
    <div class="stripbox">
      <div class="strip">{{ strip }}</div>
      <div class="rail"></div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="menu">
      <div class="mrow">{{ m0 }}</div>
      <div class="mrow">{{ m1 }}</div>
    </div>
    <div class="btnrow">
      <button class="stripbtn main" bindtap="queueTap">並び確認</button>
      <button class="stripbtn" bindtap="arrivalTap">到着守候</button>
      <button class="stripbtn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #7dff9e; font-size: 22px; font-weight: bold; letter-spacing: 2px; }
.status { color: #40ff5e; font-size: 11px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.stripbox { margin-top: 18px; border: 1px solid rgba(64,255,94,0.6); padding: 12px 10px 10px 10px; background-color: #04140a; }
.strip { color: #7dff9e; font-size: 14px; white-space: nowrap; overflow: hidden; }
.rail { height: 4px; background-color: rgba(64,255,94,0.5); margin-top: 8px; }
.detail { color: #40ff5e; font-size: 13px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.menu { margin-top: 14px; border-top: 1px solid rgba(64,255,94,0.5); padding-top: 10px; }
.mrow { color: #7dff9e; font-size: 15px; line-height: 27px; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.stripbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 7px 0; text-align: center; }
.btnrow .stripbtn:last-child { margin-right: 0; }
.stripbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
