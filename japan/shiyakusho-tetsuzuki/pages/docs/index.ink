<script def>
{
  "title": "Shiyakusho Docs"
}
</script>

<script setup>
import wx from 'wx';

// JP27 docs: one procedure's document checklist, checked one by one.
// Checking is honest: only the user's own tap, Enter or nod marks an item.
// When every item of the selected procedure is checked, the completion is
// announced by TTS and written to the persisted record list.
const KEY = 'shiyakushoV1';
const PROCEDURES = [
  { name: '転入届', docs: ['本人確認書類', '転出証明書', 'マイナンバーカード', '印鑑'] },
  { name: '転出届', docs: ['本人確認書類', 'マイナンバーカード', '国民健康保険証', '印鑑'] },
  { name: 'マイナンバーカード', docs: ['通知カード', '本人確認書類', '顔写真', '暗証番号メモ', '印鑑'] },
  { name: '国民健康保険', docs: ['本人確認書類', 'マイナンバーカード', '印鑑'] },
  { name: '印鑑登録', docs: ['登録する印鑑', '本人確認書類', '手数料'] },
  { name: '児童手当', docs: ['請求書', '通帳', '本人確認書類', 'マイナンバーカード', '健康保険証'] }
];

export default {
  data: { proc: '', status: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', evt: '記録: 準備完了' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    const st = this._load();
    this._sel = (typeof st.selected === 'number') ? st.selected : 0;
    const arr = (st.checked && st.checked[String(this._sel)]) || [];
    this._marks = PROCEDURES[this._sel].docs.map(function (_, i) { return !!arr[i]; });
    this._idx = 0;
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { selected: 0, checked: {}, records: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },
  _persist() {
    const st = this._load();
    if (!st.checked) st.checked = {};
    st.checked[String(this._sel)] = this._marks.slice();
    this._save(st);
  },
  _recompute() {
    const docs = PROCEDURES[this._sel].docs;
    const rows = docs.map(function (name, i) {
      return (i === this._idx ? '▶ ' : '　') + (this._marks[i] ? '☑ ' : '☐ ') + name;
    }.bind(this));
    while (rows.length < 5) rows.push('');
    const done = this._marks.filter(Boolean).length;
    this.setData({
      proc: PROCEDURES[this._sel].name,
      status: '書類チェック: ' + done + ' / ' + docs.length + ' 点確認済',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4],
      detail: done >= docs.length ? '全部そろいました。窓口へどうぞ。' : ('いまの書類: ' + docs[this._idx] + ' ・ うなずくか決定キーで確認します。'),
      evt: '記録: ' + PROCEDURES[this._sel].name + ' ' + done + '/' + docs.length
    });
  },
  checkTap() {
    const docs = PROCEDURES[this._sel].docs;
    this._marks[this._idx] = !this._marks[this._idx];
    this._persist();
    const done = this._marks.filter(Boolean).length;
    if (done >= docs.length) {
      const st = this._load();
      if (!st.records) st.records = [];
      st.records.push({ kind: 'docs-complete', proc: PROCEDURES[this._sel].name, at: this._time(), date: new Date().toISOString().slice(0, 10) });
      this._save(st);
      this._speak(PROCEDURES[this._sel].name + 'の書類が全部そろいました。');
      this.setData({ evt: '記録: 書類そろい済 ' + PROCEDURES[this._sel].name });
    } else {
      let next = this._idx;
      for (let k = 1; k <= docs.length; k++) { const j = (this._idx + k) % docs.length; if (!this._marks[j]) { next = j; break; } }
      this._idx = next;
    }
    this._recompute();
  },
  nextTap() { this._idx = (this._idx + 1) % PROCEDURES[this._sel].docs.length; this._recompute(); },
  prevTap() { const n = PROCEDURES[this._sel].docs.length; this._idx = (this._idx + n - 1) % n; this._recompute(); },
  numberTap() { try { wx.navigateTo({ url: '/pages/number/index' }); } catch (e) {} },
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
    if (g === 'nod') this.checkTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.checkTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="headrow">
      <div class="proc">{{ proc }}</div>
      <div class="count">{{ status }}</div>
    </div>
    <div class="cards">
      <div class="card">{{ r0 }}</div>
      <div class="card">{{ r1 }}</div>
      <div class="card">{{ r2 }}</div>
      <div class="card">{{ r3 }}</div>
      <div class="card">{{ r4 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="btncol">
      <button class="cbtn main" bindtap="checkTap">この書類を確認する</button>
      <button class="cbtn" bindtap="nextTap">つぎの書類へ</button>
      <button class="cbtn" bindtap="numberTap">番号をまつページへ</button>
      <button class="cbtn" bindtap="backTap">もどる</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #04140a; padding: 12px 16px; box-sizing: border-box; position: relative; }
.headrow { display: flex; flex-direction: row; border-bottom: 3px solid #40ff5e; padding-bottom: 6px; }
.proc { color: #7dff9e; font-size: 20px; font-weight: bold; flex: 1; white-space: nowrap; overflow: hidden; }
.count { color: #40ff5e; font-size: 12px; padding-top: 6px; white-space: nowrap; }
.cards { margin-top: 10px; }
.card { color: #7dff9e; font-size: 15px; line-height: 26px; background-color: #0a2410; margin-bottom: 4px; padding: 2px 10px; border-left: 5px solid #40ff5e; white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btncol { margin-top: 8px; }
.cbtn { width: 100%; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 5px 0; text-align: center; margin-bottom: 5px; }
.cbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 330px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
