<script def>
{
  "title": "Shiyakusho Number"
}
</script>

<script setup>
import wx from 'wx';

// JP27 number: a manual number-waiting board. The user starts the wait
// themselves; nothing is read from the office display, so the timer only
// measures time since the user pressed start. "Called" stops the wait and
// stores a record; "completed" stores a separate completion record.
// Both records persist across sessions under shiyakushoV1.
const KEY = 'shiyakushoV1';
const NAMES = ['転入届', '転出届', 'マイナンバーカード', '国民健康保険', '印鑑登録', '児童手当'];
const ACTIONS = ['待ちをはじめる / とめる', '呼ばれた', '手続き完了を記録する'];

export default {
  data: { proc: '', big: '00:00', status: '', a0: '', a1: '', a2: '', detail: '', evt: '記録: 準備完了' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    const st = this._load();
    this._sel = (typeof st.selected === 'number') ? st.selected : 0;
    this._act = 0; this._waiting = false; this._startMs = 0; this._elapsed = 0; this._timer = null;
    this._recompute();
  },
  onHide() { this._stopTimer(); },
  onUnload() { this._stopTimer(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { selected: 0, checked: {}, records: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },
  _fmt(sec) { const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(Math.floor(sec / 60)) + ':' + p(sec % 60); },
  _stopTimer() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },
  _recompute() {
    const st = this._load();
    const n = st.records ? st.records.length : 0;
    const last = (st.records && st.records.length) ? st.records[st.records.length - 1] : null;
    const rows = ACTIONS.map(function (a, i) { return (i === this._act ? '▶ ' : '　') + a; }.bind(this));
    this.setData({
      proc: NAMES[this._sel],
      big: this._fmt(this._elapsed),
      status: this._waiting ? '番号を待っています…' : 'まだ待っていません。はじめるを押してください。',
      a0: rows[0], a1: rows[1], a2: rows[2],
      detail: last ? ('さいごの記録: ' + last.kind + ' ' + last.proc + ' ' + last.at + ' ・ 記録は合計' + n + '件') : '記録はまだありません。',
      evt: '記録: ' + NAMES[this._sel] + ' 記録' + n + '件'
    });
  },
  _pushRecord(kind) {
    const st = this._load();
    if (!st.records) st.records = [];
    st.records.push({ kind: kind, proc: NAMES[this._sel], waitedSec: this._elapsed, at: this._time(), date: new Date().toISOString().slice(0, 10) });
    this._save(st);
  },
  _actTap() {
    if (this._act === 0) {
      if (!this._waiting) {
        this._waiting = true; this._startMs = Date.now(); this._elapsed = 0;
        const self = this;
        this._stopTimer();
        this._timer = setInterval(function () { self._elapsed = Math.floor((Date.now() - self._startMs) / 1000); self._recompute(); }, 1000);
        this._speak('番号待ちをはじめました。');
        this.setData({ evt: '記録: 待ち開始 ' + NAMES[this._sel] });
      } else {
        this._waiting = false; this._stopTimer();
        this.setData({ evt: '記録: 待ち停止 ' + this._fmt(this._elapsed) });
      }
    } else if (this._act === 1) {
      this._waiting = false; this._stopTimer();
      this._pushRecord('呼ばれた');
      this._speak(NAMES[this._sel] + 'で呼ばれました。窓口へどうぞ。');
      this.setData({ evt: '記録: 呼ばれた ' + NAMES[this._sel] });
    } else {
      this._pushRecord('手続き完了');
      this._speak(NAMES[this._sel] + 'の手続き完了を記録しました。');
      this.setData({ evt: '記録: 手続き完了 ' + NAMES[this._sel] });
    }
    this._recompute();
  },
  nextTap() { this._act = (this._act + 1) % ACTIONS.length; this._recompute(); },
  prevTap() { this._act = (this._act + ACTIONS.length - 1) % ACTIONS.length; this._recompute(); },
  backTap() { this._stopTimer(); try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this._actTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this._actTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="topline">
      <div class="proc">{{ proc }}</div>
      <div class="label">番号待ち</div>
    </div>
    <div class="board">
      <div class="big">{{ big }}</div>
      <div class="status">{{ status }}</div>
    </div>
    <div class="actions">
      <div class="arow">{{ a0 }}</div>
      <div class="arow">{{ a1 }}</div>
      <div class="arow">{{ a2 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="nbtn main" bindtap="_actTap">決定</button>
      <button class="nbtn" bindtap="backTap">もどる</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.topline { display: flex; flex-direction: row; }
.proc { color: #7dff9e; font-size: 20px; font-weight: bold; flex: 1; white-space: nowrap; overflow: hidden; }
.label { color: #40ff5e; font-size: 12px; padding-top: 6px; }
.board { margin-top: 8px; background-color: #0d3d17; border: 2px solid #40ff5e; padding: 10px 0; text-align: center; }
.big { color: #7dff9e; font-size: 44px; font-weight: bold; letter-spacing: 6px; }
.status { color: #40ff5e; font-size: 12px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.actions { margin-top: 10px; }
.arow { color: #7dff9e; font-size: 14px; line-height: 24px; white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 11px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.nbtn { flex: 1; margin-right: 10px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; }
.btnrow .nbtn:last-child { margin-right: 0; }
.nbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 330px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
