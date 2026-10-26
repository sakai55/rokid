<script def>
{
  "title": "Machi Game Set"
}
</script>

<script setup>
import wx from 'wx';

// JP21 machi-game-set - 等ち時間ゲーム集 (menu page).
// Merged rebuild of JP15 matsuri-taiko + JP17 kotowaza-quiz.
// Scores/progress persist in wx storage 'machiGameSetV1'.
const KEY = 'machiGameSetV1';

export default {
  data: { status: '', taikoBest: '', quizBest: '', plays: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { taikoBest: 0, quizBest: 0, quizStage: 0, plays: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const st = this._load();
    this.setData({
      status: '待ち時間ゲーム集：遊びたい方を選んでください',
      taikoBest: 'BEST ' + st.taikoBest,
      quizBest: 'BEST ' + st.quizBest + ' ・ 到達 ' + (st.quizStage ? ('第' + st.quizStage + '級') : '—'),
      plays: 'プレイ回数 ' + st.plays + ' 回（記録は端末に保存されます）'
    });
  },
  taikoTap() { try { wx.navigateTo({ url: '/pages/taiko/index' }); } catch (e) {} },
  quizTap() { try { wx.navigateTo({ url: '/pages/quiz/index' }); } catch (e) {} },
  resetTap() { this._save({ taikoBest: 0, quizBest: 0, quizStage: 0, plays: 0 }); this.setData({ evt: 'EVT: scores cleared' }); this._recompute(); },
  speakTap() { const st = this._load(); this._speak('待ち時間ゲーム集です。太鼓のベストは' + st.taikoBest + '点、ことわざのベストは' + st.quizBest + '点です。'); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp') { event.preventDefault(); this.taikoTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.quizTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
  },
  onKeyUp(event) { if (event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === 'Enter') event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Machi Game Set</div>
    <div class="status">{{ status }}</div>
    <div class="tiles">
      <div class="tile tile-a" bindtap="taikoTap">
        <div class="ticon">太</div>
        <div class="tname">祭り太鼓</div>
        <div class="tsub">頭で叩く・3曲</div>
        <div class="tbest">{{ taikoBest }}</div>
      </div>
      <div class="tile tile-b" bindtap="quizTap">
        <div class="ticon">言</div>
        <div class="tname">ことわざ</div>
        <div class="tsub">頭で選ぶ・12問</div>
        <div class="tbest">{{ quizBest }}</div>
      </div>
    </div>
    <div class="plays">{{ plays }}</div>
    <div class="btnrow">
      <button class="cart cart-a" bindtap="taikoTap">TAIKO</button>
      <button class="cart cart-b" bindtap="quizTap">QUIZ</button>
      <button class="cart" bindtap="resetTap">RESET</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; text-align: center; }
.status { color: #7dff9e; font-size: 11px; margin-top: 3px; text-align: center; white-space: nowrap; overflow: hidden; }
.tiles { display: flex; flex-direction: row; margin-top: 14px; }
.tile { flex: 1; margin-right: 10px; border: 2px solid rgba(64,255,94,0.8); padding: 12px 10px; text-align: center; background-color: #061a0b; }
.tiles .tile:last-child { margin-right: 0; }
.tile-a { border-radius: 60px 60px 12px 12px; }
.tile-b { border-radius: 12px 12px 60px 60px; }
.ticon { color: #7dff9e; font-size: 34px; font-weight: bold; line-height: 40px; }
.tname { color: #40ff5e; font-size: 17px; font-weight: bold; margin-top: 2px; }
.tsub { color: rgba(125,255,158,0.8); font-size: 11px; margin-top: 2px; }
.tbest { color: #7dff9e; font-size: 12px; margin-top: 6px; font-family: monospace; white-space: nowrap; overflow: hidden; }
.plays { color: rgba(125,255,158,0.8); font-size: 11px; text-align: center; margin-top: 10px; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.cart { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); border-bottom-width: 5px; font-size: 14px; padding: 6px 0; text-align: center; border-radius: 8px; }
.btnrow .cart:last-child { margin-right: 0; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
