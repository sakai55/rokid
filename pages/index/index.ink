<script def>
{
  "title": "Yutnori Game"
}
</script>

<script setup>
import wx from 'wx';

// KR17 index: board overview - 20 cells, both pieces, live score.
// Home-page key contract: ArrowUp/ArrowDown cycles the two sub-pages,
// Enter opens the selected sub-page. Positions and score are read from
// the same storage key the throw page writes.
const KEY = 'yutnoriV1';
const CELLS = 20;

export default {
  data: { row1: '', row2: '', pieces: '', score: '', m0: '', m1: '', hint: '', evt: 'EVT: ready' },

  onLoad() {
    this._sel = 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { pos: [0, 0], turn: 0, gameThrows: 0, wins: [0, 0], totalThrows: 0, best: 0 }; },
  _cellMark(st, i) {
    let m = '';
    if (st.pos[0] === i) m += '나';
    if (st.pos[1] === i) m += '가';
    return m;
  },
  _recompute() {
    const st = this._load();
    const self = this;
    const row = function (from, to) {
      const parts = [];
      for (let i = from; i <= to; i++) parts.push(i + self._cellMark(st, i));
      return parts.join(' ');
    };
    this.setData({
      row1: row(1, 10),
      row2: row(11, 20),
      pieces: '나 말: ' + st.pos[0] + '칸 · 가족 말: ' + st.pos[1] + '칸 · 차례: ' + (st.turn === 0 ? '나' : '가족'),
      score: '승리 — 나 ' + st.wins[0] + '승 · 가족 ' + st.wins[1] + '승 · 이번 판 던진 횟수 ' + st.gameThrows + '번',
      m0: (this._sel === 0 ? '▶ ' : '· ') + '윷 던지기',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '기록 보기',
      hint: '위·아래 키로 고르고 확인 키로 들어갑니다'
    });
  },
  _open() {
    try { wx.navigateTo({ url: this._sel === 0 ? '/pages/throw/index' : '/pages/record/index' }); } catch (e) { this.setData({ evt: 'EVT: navigate failed' }); }
  },
  openTap() { this._open(); },
  upTap() { this._sel = (this._sel + 1) % 2; this._recompute(); },
  downTap() { this._sel = (this._sel + 1) % 2; this._recompute(); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this._open();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this._open(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.upTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.downTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Yutnori Game</div>
    <div class="boardlabel">윷판 20칸 · 나=나 말 · 가=가족 말</div>
    <div class="board">
      <div class="brow">{{ row1 }}</div>
      <div class="brow">{{ row2 }}</div>
    </div>
    <div class="pieces">{{ pieces }}</div>
    <div class="score">{{ score }}</div>
    <div class="modes">
      <div class="mode">{{ m0 }}</div>
      <div class="mode">{{ m1 }}</div>
    </div>
    <div class="hint">{{ hint }}</div>
    <div class="btnrow">
      <button class="yutbtn main" bindtap="openTap">들어가기</button>
      <button class="yutbtn" bindtap="upTap">다음</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.boardlabel { color: #7dff9e; font-size: 11px; margin-top: 8px; }
.board { border: 3px solid rgba(64,255,94,0.8); background-color: #071c0c; margin-top: 6px; padding: 10px 12px; }
.brow { color: #7dff9e; font-size: 13px; line-height: 24px; font-family: monospace; white-space: nowrap; overflow: hidden; }
.pieces { color: #7dff9e; font-size: 13px; margin-top: 10px; }
.score { color: #40ff5e; font-size: 12px; margin-top: 4px; }
.modes { margin-top: 10px; border-left: 4px solid #40ff5e; padding-left: 10px; }
.mode { color: #7dff9e; font-size: 15px; line-height: 26px; }
.hint { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.yutbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 6px 0; text-align: center; }
.btnrow .yutbtn:last-child { margin-right: 0; }
.yutbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
