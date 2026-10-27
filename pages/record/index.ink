<script def>
{
  "title": "残量・受診記録"
}
</script>

<script setup>
import wx from 'wx';

// JP23 okusuri-techou - stock & visit ledger.
// Six medicines with persisted remaining counts (default = one pack).
// ArrowUp/ArrowDown selects a medicine, Enter or nod refills it to the
// default count (補充). The visit button records today as the last visit
// date; the next visit is shown as last visit + 30 days. All in wx storage
// 'okusuriTechouV1'.
const KEY = 'okusuriTechouV1';
const MEDS = [
  { name: '朝の血圧薬', time: '7:00', use: '朝食前・1錠', stock: 28 },
  { name: '昼の胃薬', time: '12:30', use: '昼食後・1錠', stock: 28 },
  { name: '夜の睡眠薬', time: '21:30', use: '就寝前・1錠', stock: 28 },
  { name: '食後のビタミン', time: '8:30', use: '朝食後・1錠', stock: 30 },
  { name: '週1回の骨薬', time: '日曜 9:00', use: '週1回・1錠', stock: 4 },
  { name: '頓服の痛み止め', time: '必要時', use: '痛いとき・1錠', stock: 10 }
];

export default {
  data: { status: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', visit: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { date: '', checks: [false, false, false, false, false, false], stock: MEDS.map(function (m) { return m.stock; }), visit: '' }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _today() { return new Date().toISOString().slice(0, 10); },
  _nextVisit(visit) {
    if (!visit) return '未記録';
    try {
      const d = new Date(visit); d.setDate(d.getDate() + 30);
      return d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate();
    } catch (e) { return '未記録'; }
  },

  _recompute() {
    const st = this._load();
    const stock = st.stock || MEDS.map(function (m) { return m.stock; });
    const rows = MEDS.map(function (m, i) {
      const warn = stock[i] <= 7 ? ' ⚠' : '';
      return (i === this._idx ? '▶ ' : '· ') + m.name + ' …… 残り ' + stock[i] + warn;
    }.bind(this));
    this.setData({
      status: '残量・受診記録： 補充で既定数に戻します',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4], r5: rows[5],
      visit: '前回受診： ' + (st.visit || '未記録') + ' ／ 次回予定： ' + this._nextVisit(st.visit)
    });
  },
  refillTap() {
    const st = this._load();
    const stock = st.stock || MEDS.map(function (m) { return m.stock; });
    stock[this._idx] = MEDS[this._idx].stock;
    st.stock = stock;
    this._save(st);
    this._speak(MEDS[this._idx].name + 'を補充しました。残りは' + stock[this._idx] + 'です。');
    this.setData({ evt: 'EVT: refilled - ' + MEDS[this._idx].name + ' stock ' + stock[this._idx] });
    this._recompute();
  },
  visitTap() {
    const st = this._load();
    st.visit = this._today();
    this._save(st);
    this._speak('今日を受診日として記録しました。次回は30日後です。');
    this.setData({ evt: 'EVT: visit recorded - ' + st.visit });
    this._recompute();
  },
  nextTap() { this._idx = (this._idx + 1) % MEDS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + MEDS.length - 1) % MEDS.length; this._recompute(); },
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
    if (g === 'nod') this.refillTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.refillTap(); return; }
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">残量・受診記録</div>
    <div class="status">{{ status }}</div>
    <div class="ledger">
      <div class="lrow">{{ r0 }}</div>
      <div class="lrow">{{ r1 }}</div>
      <div class="lrow">{{ r2 }}</div>
      <div class="lrow">{{ r3 }}</div>
      <div class="lrow">{{ r4 }}</div>
      <div class="lrow">{{ r5 }}</div>
    </div>
    <div class="visit">{{ visit }}</div>
    <div class="btnrow">
      <button class="ledbtn main" bindtap="refillTap">補充する</button>
      <button class="ledbtn" bindtap="visitTap">受診日を記録</button>
      <button class="ledbtn" bindtap="nextTap">次へ</button>
      <button class="ledbtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; }
.status { color: #7dff9e; font-size: 12px; margin-top: 2px; }
.ledger { margin-top: 10px; display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.6); }
.lrow { color: #7dff9e; font-size: 14px; line-height: 25px; padding: 0 10px; border-bottom: 1px dashed rgba(64,255,94,0.35); white-space: nowrap; overflow: hidden; }
.lrow:last-child { border-bottom: none; }
.visit { color: #40ff5e; font-size: 12px; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.ledbtn { flex: 1; margin-right: 8px; background-color: #071c0c; color: #40ff5e; border: 1px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; }
.btnrow .ledbtn:last-child { margin-right: 0; }
.ledbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
