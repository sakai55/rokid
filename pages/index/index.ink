<script def>
{
  "title": "Tsugaku Mimamori"
}
</script>

<script setup>
import wx from 'wx';

// JP26 tsugaku-mimamori - ルート总览 (menu page).
// 8 school-route checkpoints, shown as a dotted route (two rows of four
// dots). Dots show TODAY's going-to-school arrivals (● arrived, ○ not
// yet) from wx storage 'tsugakuMimamoriV1'. ArrowUp/ArrowDown cycles the
// ▶ menu (チェック / 記録); Enter opens the selected page. No location
// is used: arrivals are only the child's own nod/Enter check-ins.
const KEY = 'tsugakuMimamoriV1';
const POINTS = [
  { name: '集合場所', short: '集合' },
  { name: '横断歩道', short: '横断' },
  { name: '公園前', short: '公園' },
  { name: '踏切', short: '踏切' },
  { name: 'コンビニ前', short: 'コンビニ' },
  { name: '神社前', short: '神社' },
  { name: '学校門', short: '学校門' },
  { name: '下校集合場所', short: '下校' }
];

export default {
  data: { status: '', toLine: '', fromLine: '', m0: '', m1: '', evt: 'EVT: ready',
    d0: '', d1: '', d2: '', d3: '', d4: '', d5: '', d6: '', d7: '' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { days: {} }; },
  _today() {
    const st = this._load();
    const date = new Date().toISOString().slice(0, 10);
    if (!st.days[date]) st.days[date] = { to: [null, null, null, null, null, null, null, null], from: [null, null, null, null, null, null, null, null] };
    return { st: st, date: date, day: st.days[date] };
  },

  _recompute() {
    const t = this._today();
    const toDone = t.day.to.filter(Boolean).length;
    const fromDone = t.day.from.filter(Boolean).length;
    const patch = {
      status: '通学路みまもり：今日 ' + t.date,
      toLine: '登校 ' + toDone + ' / 8 地点',
      fromLine: '下校 ' + fromDone + ' / 8 地点',
      m0: (this._sel === 0 ? '▶ ' : '· ') + 'チェックする（うなずいて到着記録）',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '記録を見る（今日の到着・未到達）'
    };
    for (let i = 0; i < 8; i++) patch['d' + i] = (t.day.to[i] ? '● ' : '○ ') + (i + 1) + ' ' + POINTS[i].short;
    this.setData(patch);
  },
  checkTap() { try { wx.navigateTo({ url: '/pages/check/index' }); } catch (e) {} },
  recordTap() { try { wx.navigateTo({ url: '/pages/record/index' }); } catch (e) {} },
  openSel() { if (this._sel === 0) this.checkTap(); else this.recordTap(); },
  speakTap() {
    const t = this._today();
    const toDone = t.day.to.filter(Boolean).length;
    this._speak('通学路みまもりです。今日の登校は' + toDone + '地点まで進んでいます。');
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
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = (this._sel + 2 - 1) % 2; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.openSel(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">通学路みまもり</div>
    <div class="status">{{ status }}</div>
    <div class="route">
      <div class="rrow"><div class="dot">{{ d0 }}</div><div class="dot">{{ d1 }}</div><div class="dot">{{ d2 }}</div><div class="dot">{{ d3 }}</div></div>
      <div class="connector">············</div>
      <div class="rrow"><div class="dot">{{ d4 }}</div><div class="dot">{{ d5 }}</div><div class="dot">{{ d6 }}</div><div class="dot">{{ d7 }}</div></div>
    </div>
    <div class="prog">{{ toLine }} ・ {{ fromLine }}</div>
    <div class="legend">●＝到着チェック済み ○＝まだ（登校の進み具合）</div>
    <div class="menu">
      <div class="mrow">{{ m0 }}</div>
      <div class="mrow">{{ m1 }}</div>
    </div>
    <div class="btnrow">
      <button class="routebtn main" bindtap="checkTap">チェック</button>
      <button class="routebtn" bindtap="speakTap">読み上げる</button>
      <button class="routebtn" bindtap="recordTap">記録</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; text-align: center; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; text-align: center; white-space: nowrap; overflow: hidden; }
.route { margin-top: 12px; border: 2px solid rgba(64,255,94,0.7); padding: 10px 8px; background-color: #04140a; }
.rrow { display: flex; flex-direction: row; }
.dot { flex: 1; color: #7dff9e; font-size: 13px; text-align: center; padding: 8px 0; border: 2px solid rgba(64,255,94,0.6); border-radius: 50%; margin: 2px; }
.connector { color: rgba(64,255,94,0.6); font-size: 12px; text-align: center; letter-spacing: 4px; }
.prog { color: #40ff5e; font-size: 14px; margin-top: 10px; text-align: center; font-family: monospace; }
.legend { color: rgba(125,255,158,0.75); font-size: 10px; margin-top: 4px; text-align: center; white-space: nowrap; overflow: hidden; }
.menu { margin-top: 8px; }
.mrow { color: #7dff9e; font-size: 14px; line-height: 22px; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.routebtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 20px; }
.btnrow .routebtn:last-child { margin-right: 0; }
.routebtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
