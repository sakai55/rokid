<script def>
{
  "title": "お薬手帳"
}
</script>

<script setup>
import wx from 'wx';

// JP23 okusuri-techou - medicine notebook (cover page).
// Home page: today's dose progress, low-stock warnings, next visit date,
// and a two-item menu (medicine check / stock & visit record) cycled with
// ArrowUp/ArrowDown, opened with Enter. State in wx storage 'okusuriTechouV1'.
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
  data: { status: '', prog: '', warn: '', visit: '', m0: '', m1: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { date: '', checks: [false, false, false, false, false, false], stock: MEDS.map(function (m) { return m.stock; }), visit: '' }; },
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
    const today = this._today();
    const checks = (st.date === today && st.checks) ? st.checks : [false, false, false, false, false, false];
    const done = checks.filter(Boolean).length;
    const stock = st.stock || MEDS.map(function (m) { return m.stock; });
    const low = [];
    MEDS.forEach(function (m, i) { if (stock[i] <= 7) low.push(m.name + ' 残り' + stock[i]); });
    this.setData({
      status: 'お薬手帳：今日の服薬を逃さず、残量と受診を一括管理',
      prog: '今日の服薬： ' + done + ' / 6 済み',
      warn: low.length ? '残量注意： ' + low.join(' ・ ') : '残量： すべて十分です',
      visit: '次回受診予定： ' + this._nextVisit(st.visit) + (st.visit ? '（前回 ' + st.visit + '）' : ''),
      m0: (this._sel === 0 ? '▶ ' : '· ') + '今日の服薬チェック',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '残量・受診記録'
    });
  },
  // Selection contract: sel 0 -> pages[1] (first subpage), sel 1 -> pages[2]
  // (second subpage); onShow resets sel to 0, so returning from a subpage
  // via Backspace always lands on the first subpage.
  _open() { try { wx.navigateTo({ url: this._sel === 0 ? '/pages/medicine/index' : '/pages/record/index' }); } catch (e) {} },
  medicineTap() { this._sel = 0; this._open(); },
  recordTap() { this._sel = 1; this._open(); },
  speakTap() {
    const st = this._load();
    const today = this._today();
    const checks = (st.date === today && st.checks) ? st.checks : [false, false, false, false, false, false];
    const done = checks.filter(Boolean).length;
    this._speak('お薬手帳です。今日の服薬は' + done + '種類のうち' + done + '種類が済んでいます。');
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
    <div class="spine"></div>
    <div class="cover">
      <div class="ttl">お薬手帳</div>
      <div class="status">{{ status }}</div>
      <div class="prog">{{ prog }}</div>
      <div class="warn">{{ warn }}</div>
      <div class="visit">{{ visit }}</div>
      <div class="menu">
        <div class="mrow">{{ m0 }}</div>
        <div class="mrow">{{ m1 }}</div>
      </div>
      <div class="btnrow">
        <button class="coverbtn main" bindtap="medicineTap">服薬チェック</button>
        <button class="coverbtn" bindtap="recordTap">残量・受診</button>
        <button class="coverbtn" bindtap="speakTap">音声案内</button>
      </div>
      <div class="foot">{{ evt }}</div>
    </div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 0; box-sizing: border-box; position: relative; display: flex; flex-direction: row; }
.spine { width: 22px; background-color: #14541f; border-right: 3px solid rgba(64,255,94,0.8); }
.cover { flex: 1; padding: 14px 18px; box-sizing: border-box; position: relative; }
.ttl { color: #7dff9e; font-size: 26px; font-weight: bold; letter-spacing: 4px; }
.status { color: #40ff5e; font-size: 11px; margin-top: 4px; white-space: nowrap; overflow: hidden; }
.prog { color: #7dff9e; font-size: 17px; font-weight: bold; margin-top: 16px; }
.warn { color: #40ff5e; font-size: 13px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.visit { color: #40ff5e; font-size: 13px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.menu { margin-top: 16px; border-top: 1px solid rgba(64,255,94,0.5); padding-top: 10px; }
.mrow { color: #7dff9e; font-size: 16px; line-height: 28px; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.coverbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 7px 0; text-align: center; border-radius: 6px; }
.btnrow .coverbtn:last-child { margin-right: 0; }
.coverbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 18px; top: 322px; width: 420px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
