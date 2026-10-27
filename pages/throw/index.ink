<script def>
{
  "title": "Yutnori Game"
}
</script>

<script setup>
import wx from 'wx';

// KR17 throw: nod or Enter throws the sticks. The result is a stated
// demo random pick among 5 results (not physical stick recognition):
// 도 1칸, 개 2칸, 걸 3칸, 윷 4칸 + 한 번 더, 모 5칸 + 한 번 더.
// The current player's piece moves; reaching cell 20 wins, the win and
// the throw count persist, and the board resets for the next game.
const KEY = 'yutnoriV1';
const RESULTS = [
  { name: '도', steps: 1, note: '한 칸 앞으로', sticks: '●○○○', extra: false },
  { name: '개', steps: 2, note: '두 칸 앞으로', sticks: '●●○○', extra: false },
  { name: '걸', steps: 3, note: '세 칸 앞으로', sticks: '●●●○', extra: false },
  { name: '윷', steps: 4, note: '네 칸 앞으로 · 한 번 더 던집니다', sticks: '●●●●', extra: true },
  { name: '모', steps: 5, note: '다섯 칸 앞으로 · 한 번 더 던집니다', sticks: '○○○○', extra: true }
];

export default {
  data: { turn: '', sticks: '', result: '', pieces: '', note: '', ref: '', evt: 'EVT: ready' },

  onLoad() {
    this._ref = 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { pos: [0, 0], turn: 0, gameThrows: 0, wins: [0, 0], totalThrows: 0, best: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _recompute() {
    const st = this._load();
    this.setData({
      turn: '차례: ' + (st.turn === 0 ? '나' : '가족') + ' · 나 말 ' + st.pos[0] + '칸 · 가족 말 ' + st.pos[1] + '칸',
      pieces: '목표 20칸 · 이번 판 던진 횟수 ' + st.gameThrows + '번',
      note: '고개를 끄덕이거나 확인 키를 누르면 윷을 던집니다. 결과는 화면에 보이는 시범 무작위 수입니다.'
    });
  },
  throwTap() {
    const st = this._load();
    const r = RESULTS[Math.floor(Math.random() * RESULTS.length)];
    const me = st.turn;
    st.gameThrows = (st.gameThrows || 0) + 1;
    st.totalThrows = (st.totalThrows || 0) + 1;
    st.pos[me] = st.pos[me] + r.steps;
    let won = false;
    if (st.pos[me] >= 20) {
      st.pos[me] = 20; won = true;
      st.wins[me] = (st.wins[me] || 0) + 1;
      if (!st.best || st.gameThrows < st.best) st.best = st.gameThrows;
    }
    if (!won && !r.extra) st.turn = 1 - me;
    if (won) {
      const winner = me === 0 ? '나' : '가족';
      this._speak(winner + '가 이겼습니다. ' + r.name + '가 나와서 20칸에 도착했습니다.');
      this.setData({ evt: 'EVT: win - ' + winner + ' ' + r.name + ' throws ' + st.gameThrows });
      st.pos = [0, 0]; st.turn = 0; st.gameThrows = 0;
    } else {
      this._speak((me === 0 ? '나' : '가족') + '의 차례, ' + r.name + '가 나왔습니다. ' + r.steps + '칸 앞으로 갑니다.');
      this.setData({ evt: 'EVT: throw - ' + r.name + ' ' + r.steps + ' steps' });
    }
    this._save(st);
    this.setData({ sticks: '윷짝: ' + r.sticks, result: r.name + ' · ' + r.steps + '칸 · ' + r.note });
    this._recompute();
  },
  refUpTap() { this._ref = (this._ref + 1) % RESULTS.length; const r = RESULTS[this._ref]; this.setData({ ref: '결과 보기: ' + r.name + ' · ' + r.steps + '칸 · ' + r.note }); },
  refDownTap() { this._ref = (this._ref + RESULTS.length - 1) % RESULTS.length; const r = RESULTS[this._ref]; this.setData({ ref: '결과 보기: ' + r.name + ' · ' + r.steps + '칸 · ' + r.note }); },
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
    if (g === 'nod') this.throwTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.throwTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.refUpTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.refDownTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Yutnori Game</div>
    <div class="turn">{{ turn }}</div>
    <div class="stickbox">
      <div class="sticks">{{ sticks }}</div>
      <div class="result">{{ result }}</div>
    </div>
    <div class="pieces">{{ pieces }}</div>
    <div class="note">{{ note }}</div>
    <div class="ref">{{ ref }}</div>
    <div class="btnrow">
      <button class="throwbtn main" bindtap="throwTap">윷 던지기</button>
      <button class="throwbtn" bindtap="backTap">뒤로</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; text-align: left; }
.turn { color: #7dff9e; font-size: 14px; margin-top: 10px; }
.stickbox { border: 3px solid rgba(64,255,94,0.8); background-color: #071c0c; margin: 16px 60px 0 60px; padding: 16px 0 12px 0; border-radius: 24px; }
.sticks { color: #7dff9e; font-size: 30px; letter-spacing: 10px; font-family: monospace; }
.result { color: #7dff9e; font-size: 15px; margin-top: 10px; }
.pieces { color: #40ff5e; font-size: 12px; margin-top: 14px; }
.note { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; line-height: 18px; }
.ref { color: #40ff5e; font-size: 12px; margin-top: 4px; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.throwbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; border-radius: 24px; }
.btnrow .throwbtn:last-child { margin-right: 0; }
.throwbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
