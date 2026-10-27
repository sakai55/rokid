<script def>
{
  "title": "今日の服薬チェック"
}
</script>

<script setup>
import wx from 'wx';

// JP23 okusuri-techou - today's dose checklist (ruled notebook page).
// Six medicines, each with time and usage. ArrowUp/ArrowDown moves,
// Enter or nod checks the current one: the check is persisted for today
// and the remaining count drops by one (floor 0). All six checked -> TTS
// completion announcement. State in wx storage 'okusuriTechouV1'.
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
  data: { status: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { date: '', checks: [false, false, false, false, false, false], stock: MEDS.map(function (m) { return m.stock; }), visit: '' }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _today() { return new Date().toISOString().slice(0, 10); },

  _checks(st) {
    const today = this._today();
    if (st.date !== today) return [false, false, false, false, false, false];
    return st.checks || [false, false, false, false, false, false];
  },
  _recompute() {
    const st = this._load();
    const checks = this._checks(st);
    const done = checks.filter(Boolean).length;
    const rows = MEDS.map(function (m, i) {
      return (i === this._idx ? '▶ ' : '· ') + m.name + ' ' + m.time + ' ' + m.use + (checks[i] ? ' …… 済' : ' …… 未');
    }.bind(this));
    this.setData({
      status: '今日の服薬： ' + done + ' / 6 済み',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4], r5: rows[5],
      detail: done >= 6 ? '今日のお薬は全部終わりました。' : ('今の薬： ' + MEDS[this._idx].name + '（' + MEDS[this._idx].time + '・' + MEDS[this._idx].use + '）')
    });
  },
  checkTap() {
    const st = this._load();
    const checks = this._checks(st);
    if (checks[this._idx]) { this.setData({ evt: 'EVT: already checked - ' + MEDS[this._idx].name }); return; }
    checks[this._idx] = true;
    st.date = this._today();
    st.checks = checks;
    const stock = st.stock || MEDS.map(function (m) { return m.stock; });
    stock[this._idx] = Math.max(0, stock[this._idx] - 1);
    st.stock = stock;
    this._save(st);
    this._speak(MEDS[this._idx].name + 'を飲みました。残りは' + stock[this._idx] + 'です。');
    if (checks.filter(Boolean).length >= 6) this._speak('今日のお薬は全部終わりました。');
    this.setData({ evt: 'EVT: checked - ' + MEDS[this._idx].name + ' stock ' + stock[this._idx] });
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
    if (g === 'nod') this.checkTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.checkTap(); return; }
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">今日の服薬チェック</div>
    <div class="status">{{ status }}</div>
    <div class="ruled">
      <div class="lrow">{{ r0 }}</div>
      <div class="lrow">{{ r1 }}</div>
      <div class="lrow">{{ r2 }}</div>
      <div class="lrow">{{ r3 }}</div>
      <div class="lrow">{{ r4 }}</div>
      <div class="lrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="rulebtn main" bindtap="checkTap">飲んだ</button>
      <button class="rulebtn" bindtap="nextTap">次へ</button>
      <button class="rulebtn" bindtap="prevTap">前へ</button>
      <button class="rulebtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #04140a; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #7dff9e; font-size: 19px; font-weight: bold; }
.status { color: #40ff5e; font-size: 12px; margin-top: 2px; }
.ruled { margin-top: 10px; border-top: 2px solid rgba(64,255,94,0.8); border-bottom: 2px solid rgba(64,255,94,0.8); padding: 4px 0; }
.lrow { color: #7dff9e; font-size: 14px; line-height: 26px; border-bottom: 1px solid rgba(64,255,94,0.35); white-space: nowrap; overflow: hidden; }
.lrow:last-child { border-bottom: none; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.rulebtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 4px; }
.btnrow .rulebtn:last-child { margin-right: 0; }
.rulebtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
