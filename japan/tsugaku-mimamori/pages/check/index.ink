<script def>
{
  "title": "Tsugaku Check"
}
</script>

<script setup>
import wx from 'wx';

// JP26 tsugaku-mimamori - チェック.
// 8 checkpoints, each with one short feature sentence. The current point
// is shown large; ArrowUp/ArrowDown moves to the previous/next point;
// onHeadGesture('nod') or Enter (the main action) checks in the current
// point with the arrival time. 登校 / 下校 switches with a button.
// When all 8 points of the current direction are checked, TTS announces
// 登校完了 / 下校完了. Records persist per day in wx storage
// 'tsugakuMimamoriV1'. Arrivals are the child's own check-ins only -
// no location is measured, so nothing here proves where the child was.
const KEY = 'tsugakuMimamoriV1';
const POINTS = [
  { name: '集合場所', feat: 'みんなが集まる広場のベンチ前' },
  { name: '横断歩道', feat: '信号を見て手を挙げて渡る場所' },
  { name: '公園前', feat: 'すべり台が見える公園の入口' },
  { name: '踏切', feat: '音が鳴ったら止まって待つ場所' },
  { name: 'コンビニ前', feat: '明るい店の前を通る場所' },
  { name: '神社前', feat: '石の鳥居がある静かな坂道' },
  { name: '学校門', feat: '先生が立っている正門' },
  { name: '下校集合場所', feat: '帰りに集まって点呼する場所' }
];

export default {
  data: { status: '', mode: '', big: '', feat: '', state: '', dots: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._mode = 'to'; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { days: {} }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _today() {
    const st = this._load();
    const date = new Date().toISOString().slice(0, 10);
    if (!st.days[date]) st.days[date] = { to: [null, null, null, null, null, null, null, null], from: [null, null, null, null, null, null, null, null] };
    return { st: st, date: date, day: st.days[date] };
  },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },
  _list() { return this._mode === 'to' ? this._today().day.to : this._today().day.from; },

  _recompute() {
    const t = this._today();
    const list = this._mode === 'to' ? t.day.to : t.day.from;
    const done = list.filter(Boolean).length;
    let dots = '';
    for (let i = 0; i < 8; i++) dots += (i === this._idx ? '◉' : (list[i] ? '●' : '○')) + ' ';
    const at = list[this._idx];
    this.setData({
      status: '通学チェック：今日 ' + t.date,
      mode: (this._mode === 'to' ? '登校' : '下校') + ' ' + done + ' / 8 地点',
      big: (this._idx + 1) + ' ' + POINTS[this._idx].name,
      feat: POINTS[this._idx].feat,
      state: at ? ('到着チェック済み ' + at) : 'まだチェックしていません',
      dots: dots
    });
  },
  markTap() {
    const t = this._today();
    const list = this._mode === 'to' ? t.day.to : t.day.from;
    if (list[this._idx]) {
      this.setData({ evt: 'EVT: already checked ' + POINTS[this._idx].name + ' ' + list[this._idx] });
      this._speak(POINTS[this._idx].name + 'はもうチェック済みです。');
      return;
    }
    list[this._idx] = this._time();
    this._save(t.st);
    this.setData({ evt: 'EVT: checked ' + POINTS[this._idx].name + ' ' + list[this._idx] });
    if (list.filter(Boolean).length >= 8) {
      this._speak(this._mode === 'to' ? '登校完了です。8地点すべてチェックできました。' : '下校完了です。8地点すべてチェックできました。');
    } else {
      this._speak(POINTS[this._idx].name + '、到着しました。');
    }
    this._recompute();
  },
  modeTap() { this._mode = this._mode === 'to' ? 'from' : 'to'; this._recompute(); },
  prevTap() { this._idx = (this._idx + 7) % 8; this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % 8; this._recompute(); },
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
    if (g === 'nod') this.markTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.markTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">通学チェック</div>
    <div class="status">{{ status }}</div>
    <div class="mode">{{ mode }}</div>
    <div class="bigdot">●</div>
    <div class="big">{{ big }}</div>
    <div class="feat">{{ feat }}</div>
    <div class="state">{{ state }}</div>
    <div class="dots">{{ dots }}</div>
    <div class="btnrow">
      <button class="checkbtn main" bindtap="markTap">到着チェック</button>
      <button class="checkbtn" bindtap="modeTap">登校／下校</button>
    </div>
    <div class="btnrow">
      <button class="checkbtn" bindtap="prevTap">前の地点</button>
      <button class="checkbtn" bindtap="nextTap">次の地点</button>
      <button class="checkbtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.mode { color: #7dff9e; font-size: 14px; margin-top: 8px; font-family: monospace; }
.bigdot { color: #40ff5e; font-size: 44px; line-height: 50px; margin-top: 6px; }
.big { color: #7dff9e; font-size: 30px; font-weight: bold; margin-top: 2px; }
.feat { color: #40ff5e; font-size: 13px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.state { color: #7dff9e; font-size: 13px; margin-top: 6px; font-family: monospace; }
.dots { color: #40ff5e; font-size: 18px; letter-spacing: 4px; margin-top: 10px; font-family: monospace; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.checkbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 6px; }
.btnrow .checkbtn:last-child { margin-right: 0; }
.checkbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
