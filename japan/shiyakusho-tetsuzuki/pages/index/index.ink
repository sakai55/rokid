<script def>
{
  "title": "Shiyakusho Tetsuzuki"
}
</script>

<script setup>
import wx from 'wx';

// JP27 index: ticket-strip list of six city-office procedures.
// Each procedure carries its own countable document list (3-5 items).
// The selection list below the strip is the two subpages, in app.json
// pages order: sel 0 opens docs (pages[1]), sel 1 opens number (pages[2]).
// onShow always resets sel to 0, so coming back from a subpage always
// lands on the first subpage. The target procedure is shown in the detail
// line and changed with the procedure button; it is stored so the docs
// and number pages open on it.
const KEY = 'shiyakushoV1';
const PROCEDURES = [
  { name: '転入届', docs: ['本人確認書類', '転出証明書', 'マイナンバーカード', '印鑑'] },
  { name: '転出届', docs: ['本人確認書類', 'マイナンバーカード', '国民健康保険証', '印鑑'] },
  { name: 'マイナンバーカード', docs: ['通知カード', '本人確認書類', '顔写真', '暗証番号メモ', '印鑑'] },
  { name: '国民健康保険', docs: ['本人確認書類', 'マイナンバーカード', '印鑑'] },
  { name: '印鑑登録', docs: ['登録する印鑑', '本人確認書類', '手数料'] },
  { name: '児童手当', docs: ['請求書', '通帳', '本人確認書類', 'マイナンバーカード', '健康保険証'] }
];
const DESTS = [
  { name: '書類チェック', url: '/pages/docs/index' },
  { name: '番号待ち', url: '/pages/number/index' }
];

export default {
  data: { status: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', d0: '', d1: '', detail: '', evt: '記録: 準備完了' },

  onLoad() {
    this._idx = 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    const st = this._load();
    this._proc = (typeof st.selected === 'number' && st.selected >= 0 && st.selected < PROCEDURES.length) ? st.selected : 0;
    this._recompute();
  },
  onShow() {
    this._idx = 0;
    if (typeof this._proc === 'undefined') { const st = this._load(); this._proc = (typeof st.selected === 'number') ? st.selected : 0; }
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { selected: 0, checked: {}, records: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _checkedCount(i) {
    const st = this._load();
    const arr = (st.checked && st.checked[String(i)]) || [];
    return arr.filter(Boolean).length;
  },
  _recompute() {
    const self = this;
    const rows = PROCEDURES.map(function (p, i) {
      const done = self._checkedCount(i);
      const mark = done >= p.docs.length ? ' 済' : '';
      return '0' + (i + 1) + ' ┆ ' + p.name + ' …… 書類' + p.docs.length + '点' + (done ? ' (' + done + '点確認済)' : '') + mark;
    });
    const dests = DESTS.map(function (d, i) { return (i === self._idx ? '▶ ' : '　') + d.name; });
    const st = this._load();
    const proc = PROCEDURES[this._proc];
    this.setData({
      status: '市役所の手続き 6件 ・ 書類は合計24点',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4], r5: rows[5],
      d0: dests[0], d1: dests[1],
      detail: '対象の手続き: ' + proc.name + ' ・ 書類' + proc.docs.length + '点 ・ 完了した記録は' + (st.records ? st.records.length : 0) + '件あります。',
      evt: '記録: 選択 ' + DESTS[this._idx].name + ' / 手続き ' + proc.name
    });
  },
  _saveSelected() { const st = this._load(); st.selected = this._proc; this._save(st); },
  openTap() { this._saveSelected(); try { wx.navigateTo({ url: DESTS[this._idx].url }); } catch (e) {} },
  dest0Tap() { this._idx = 0; this.openTap(); },
  dest1Tap() { this._idx = 1; this.openTap(); },
  procTap() { this._proc = (this._proc + 1) % PROCEDURES.length; this._saveSelected(); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % DESTS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + DESTS.length - 1) % DESTS.length; this._recompute(); },
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
    <div class="band">市役所の手続き</div>
    <div class="status">{{ status }}</div>
    <div class="strip">
      <div class="trow">{{ r0 }}</div>
      <div class="trow">{{ r1 }}</div>
      <div class="trow">{{ r2 }}</div>
      <div class="trow">{{ r3 }}</div>
      <div class="trow">{{ r4 }}</div>
      <div class="trow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="dest">
      <div class="drow" bindtap="dest0Tap">{{ d0 }}</div>
      <div class="drow" bindtap="dest1Tap">{{ d1 }}</div>
    </div>
    <div class="btnrow">
      <button class="tbtn main" bindtap="openTap">選んだページをひらく</button>
      <button class="tbtn" bindtap="procTap">つぎの手続きへ</button>
    </div>
    <div class="stubbar">✂ 切り取り線の内側があなたの手続きです</div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 16px; box-sizing: border-box; position: relative; }
.band { background-color: #0d3d17; color: #7dff9e; font-size: 20px; font-weight: bold; padding: 6px 12px; letter-spacing: 3px; border-left: 8px solid #40ff5e; }
.status { color: #7dff9e; font-size: 11px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.strip { margin-top: 8px; border-top: 1px dashed rgba(64,255,94,0.7); border-bottom: 1px dashed rgba(64,255,94,0.7); }
.trow { color: #7dff9e; font-size: 14px; line-height: 22px; border-bottom: 1px dashed rgba(64,255,94,0.35); white-space: nowrap; overflow: hidden; }
.trow:last-child { border-bottom: none; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.dest { margin-top: 4px; }
.drow { color: #7dff9e; font-size: 13px; line-height: 20px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.tbtn { flex: 1; margin-right: 10px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; }
.btnrow .tbtn:last-child { margin-right: 0; }
.tbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.stubbar { color: rgba(64,255,94,0.6); font-size: 10px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.foot { position: absolute; left: 16px; top: 330px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
