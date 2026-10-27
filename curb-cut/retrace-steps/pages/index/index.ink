<script def>
{
  "title": "Retrace Steps"
}
</script>

<script setup>
import wx from 'wx';

// CC12 index: breadcrumb-tape overview. The horizontal tape shows the
// anchors dropped so far in walking order; the two subpages below it are
// the selection list (ArrowUp/ArrowDown cycles, Enter opens the selected
// subpage, marked with ▶). No map and no location API are used anywhere.
const KEY = 'retraceStepsV1';
const SUBS = [
  { name: '锚点记录', url: '/pages/anchors/index' },
  { name: '逆序引导', url: '/pages/guide/index' }
];

export default {
  data: { tape: '', status: '', s0: '', s1: '', detail: '', evt: '记录: 准备完成' },

  onLoad() {
    this._idx = 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  onShow() {
    this._idx = 0;
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { anchors: [], guides: [] }; },
  _recompute() {
    const st = this._load();
    const anchors = st.anchors || [];
    let tape = '起点';
    anchors.forEach(function (a) { tape += ' ●→'; });
    tape += anchors.length ? ' 现在' : '（还没有锚点）';
    const rows = SUBS.map(function (s, i) { return (i === this._idx ? '▶ ' : '　') + s.name; }.bind(this));
    const guides = st.guides || [];
    this.setData({
      tape: tape,
      status: '当前锚点 ' + anchors.length + ' 个 · 已完成逆序引导 ' + guides.length + ' 次',
      s0: rows[0], s1: rows[1],
      detail: anchors.length ? ('最近锚点: 锚点' + anchors.length + (anchors[anchors.length - 1].yawDeg !== null && anchors[anchors.length - 1].yawDeg !== undefined ? ' · 朝向约' + anchors[anchors.length - 1].yawDeg + '°' : ' · 朝向未记录') + ' ' + anchors[anchors.length - 1].at) : '先去“锚点记录”页：每个转弯/地标处点头落一个点。',
      evt: '记录: 锚点' + anchors.length + '个'
    });
  },
  openTap() { try { wx.navigateTo({ url: SUBS[this._idx].url }); } catch (e) {} },
  anchorsTap() { try { wx.navigateTo({ url: '/pages/anchors/index' }); } catch (e) {} },
  guideTap() { try { wx.navigateTo({ url: '/pages/guide/index' }); } catch (e) {} },
  nextTap() { this._idx = (this._idx + 1) % SUBS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + SUBS.length - 1) % SUBS.length; this._recompute(); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.openTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.openTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">找回来的路</div>
    <div class="tape">{{ tape }}</div>
    <div class="status">{{ status }}</div>
    <div class="tiles">
      <div class="tile">{{ s0 }}</div>
      <div class="tile">{{ s1 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="tbtn main" bindtap="anchorsTap">去落点</button>
      <button class="tbtn" bindtap="guideTap">开始返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 14px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #7dff9e; font-size: 22px; font-weight: bold; letter-spacing: 4px; }
.tape { margin-top: 12px; background-color: #0d3d17; border-top: 3px solid #40ff5e; border-bottom: 3px solid #40ff5e; color: #7dff9e; font-size: 16px; padding: 10px 12px; white-space: nowrap; overflow: hidden; }
.status { color: #40ff5e; font-size: 12px; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.tiles { display: flex; flex-direction: row; margin-top: 12px; }
.tile { flex: 1; margin-right: 12px; background-color: #0d2812; color: #7dff9e; border: 2px solid rgba(64,255,94,0.7); font-size: 16px; padding: 12px 0; text-align: center; }
.tiles .tile:last-child { margin-right: 0; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.tbtn { flex: 1; margin-right: 10px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; }
.btnrow .tbtn:last-child { margin-right: 0; }
.tbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 330px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
