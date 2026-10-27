<script def>
{
  "title": "Karuta Record"
}
</script>

<script setup>
import wx from 'wx';

// JP25 karuta-tori - 記録.
// Reads wx storage 'karutaToriV1': best score, total cards taken, play
// count and the last game's score / cards. ArrowUp/ArrowDown cycles the ▶
// selection among the three stat rows; Enter speaks the summary (the main
// action). RESET clears the record; the record is never invented - an
// empty record reads 0.
const KEY = 'karutaToriV1';

export default {
  data: { status: '', r0: '', r1: '', r2: '', last: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { best: 0, takenTotal: 0, plays: 0, lastScore: 0, lastCorrect: 0, lastTaken: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const st = this._load();
    this.setData({
      status: 'かるた記録：対戦の結果は端末に保存されます',
      r0: (this._sel === 0 ? '▶ ' : '· ') + 'ベストスコア：' + (st.best || 0) + '点',
      r1: (this._sel === 1 ? '▶ ' : '· ') + '取札総数：' + (st.takenTotal || 0) + '枚',
      r2: (this._sel === 2 ? '▶ ' : '· ') + 'プレイ回数：' + (st.plays || 0) + '回',
      last: '前回の成績：' + (st.lastScore || 0) + '点・' + (st.lastCorrect || 0) + '枚（20首中）'
    });
  },
  speakTap() {
    const st = this._load();
    this._speak('かるた取りの記録です。ベストは' + (st.best || 0) + '点、取った札は合計' + (st.takenTotal || 0) + '枚、' + (st.plays || 0) + '回遊びました。');
  },
  resetTap() {
    this._save({ best: 0, takenTotal: 0, plays: 0, lastScore: 0, lastCorrect: 0, lastTaken: [] });
    this.setData({ evt: 'EVT: record cleared' });
    this._recompute();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = (this._sel + 2) % 3; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % 3; this._recompute(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">かるた記録</div>
    <div class="status">{{ status }}</div>
    <div class="ledger">
      <div class="lrow big">{{ r0 }}</div>
      <div class="lrow big">{{ r1 }}</div>
      <div class="lrow big">{{ r2 }}</div>
    </div>
    <div class="last">{{ last }}</div>
    <div class="note">句集 20首はすべて自作オリジナルです。百人一首の引用ではありません。</div>
    <div class="btnrow">
      <button class="recbtn main" bindtap="speakTap">読み上げる</button>
      <button class="recbtn" bindtap="resetTap">リセット</button>
      <button class="recbtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.ledger { margin-top: 16px; border-left: 6px solid rgba(64,255,94,0.8); padding: 4px 0 4px 14px; background-color: #04140a; }
.lrow.big { color: #7dff9e; font-size: 18px; line-height: 38px; white-space: nowrap; overflow: hidden; }
.last { color: #40ff5e; font-size: 13px; margin-top: 14px; white-space: nowrap; overflow: hidden; }
.note { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 16px; }
.recbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 6px; }
.btnrow .recbtn:last-child { margin-right: 0; }
.recbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
