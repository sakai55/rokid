<script def>
{
  "title": "Yutnori Game"
}
</script>

<script setup>
import wx from 'wx';

// KR17 record: wins, throw counts and best record, all read from the
// same storage key the throw page writes. Enter (or nod) speaks the
// summary aloud; ArrowUp/ArrowDown moves between the record rows.
const KEY = 'yutnoriV1';

export default {
  data: { r0: '', r1: '', r2: '', r3: '', summary: '', evt: 'EVT: ready' },

  onLoad() {
    this._idx = 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { pos: [0, 0], turn: 0, gameThrows: 0, wins: [0, 0], totalThrows: 0, best: 0 }; },
  _recompute() {
    const st = this._load();
    const rows = [
      '나 승리: ' + st.wins[0] + '승',
      '가족 승리: ' + st.wins[1] + '승',
      '전체 던진 횟수: ' + st.totalThrows + '번',
      '최소 던짐 승리 기록: ' + (st.best ? st.best + '번' : '아직 없음')
    ];
    const marked = rows.map(function (r, i) { return (i === this._idx ? '▶ ' : '· ') + r; }.bind(this));
    this.setData({
      r0: marked[0], r1: marked[1], r2: marked[2], r3: marked[3],
      summary: st.wins[0] + st.wins[1] > 0 ? '지금까지 ' + (st.wins[0] + st.wins[1]) + '판이 끝났습니다.' : '아직 끝난 판이 없습니다. 윷 던지기 페이지에서 시작하세요.'
    });
  },
  speakTap() {
    const st = this._load();
    this._speak('기록입니다. 나 ' + st.wins[0] + '승, 가족 ' + st.wins[1] + '승, 전체 ' + st.totalThrows + '번 던졌습니다.');
    this.setData({ evt: 'EVT: record spoken' });
  },
  nextTap() { this._idx = (this._idx + 1) % 4; this._recompute(); },
  prevTap() { this._idx = (this._idx + 3) % 4; this._recompute(); },
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
    if (g === 'nod') this.speakTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Yutnori Game</div>
    <div class="subtitle">기록 · 지금까지의 윷놀이 성적</div>
    <div class="ledger">
      <div class="lrow">{{ r0 }}</div>
      <div class="lrow">{{ r1 }}</div>
      <div class="lrow">{{ r2 }}</div>
      <div class="lrow">{{ r3 }}</div>
    </div>
    <div class="summary">{{ summary }}</div>
    <div class="btnrow">
      <button class="recbtn main" bindtap="speakTap">기록 읽어주기</button>
      <button class="recbtn" bindtap="nextTap">다음 줄</button>
      <button class="recbtn" bindtap="backTap">뒤로</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.subtitle { color: #7dff9e; font-size: 12px; margin-top: 4px; }
.ledger { margin-top: 16px; border-top: 2px solid rgba(64,255,94,0.8); }
.lrow { color: #7dff9e; font-size: 16px; line-height: 34px; border-bottom: 1px solid rgba(64,255,94,0.4); white-space: nowrap; overflow: hidden; }
.summary { color: #40ff5e; font-size: 13px; margin-top: 14px; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.recbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 6px 0; text-align: center; }
.btnrow .recbtn:last-child { margin-right: 0; }
.recbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
