<script def>
{
  "title": "Karuta Tori"
}
</script>

<script setup>
import wx from 'wx';

// JP25 karuta-tori - 札一覧 (menu page).
// Cards: 20 ORIGINAL kami phrases (seasonal / daily life), NOT Hyakunin
// Isshu quotations. Grid shows all 20 cards with taken marks from the last
// finished game (wx storage 'karutaToriV1', lastTaken). Spotlight cycles
// through the phrases one at a time. ArrowUp/ArrowDown cycles the ▶ menu
// (対戦 / 記録); Enter opens the selected page.
const KEY = 'karutaToriV1';
const CARDS = [
  '春の朝 まどをあけると さくら舞う',
  '夏の夜 せみの声きく 庭の隅',
  '秋の風 きんもくせいが 香る道',
  '冬の朝 ゆげのたつお茶 手を温める',
  '雨あがり 水たまりには 空うつる',
  '夕焼けに 帰り道ゆく 自転車',
  '朝ごはん 湯気のごはんに 卵焼き',
  '昼下がり 猫はひなたで 丸くなる',
  '夕方の 台所からは カレーの香り',
  '星空に 流れ星ひとつ 願い込む',
  '春の川 桜の花びら 流れてく',
  '夏祭り 提灯ゆれる 夜店の灯',
  '秋の山 栗ひろいする 子どもたち',
  '雪の朝 足あとつづく 白い道',
  '風の強い日 洗濯物が 踊ってる',
  '本を読む 窓辺の椅子で 午後の光',
  '散歩道 犬としっぽを ふりながら',
  'お月さま 雲の合間から 顔を出す',
  '朝の駅 電車のドアが 閉まる音',
  '夜の海 波の音だけ 聞こえてる'
];

export default {
  data: { status: '', spot: '', m0: '', m1: '', evt: 'EVT: ready',
    c0: '', c1: '', c2: '', c3: '', c4: '', c5: '', c6: '', c7: '', c8: '', c9: '',
    c10: '', c11: '', c12: '', c13: '', c14: '', c15: '', c16: '', c17: '', c18: '', c19: '' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._spot = 0; this._recompute(); },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { best: 0, takenTotal: 0, plays: 0, lastScore: 0, lastCorrect: 0, lastTaken: [] }; },

  _recompute() {
    const st = this._load();
    const taken = {};
    (st.lastTaken || []).forEach(function (i) { taken[i] = true; });
    const patch = {
      status: 'かるた取り：20首（自作オリジナル）・前回 ' + (st.lastCorrect || 0) + '枚 / ベスト ' + (st.best || 0) + '点',
      spot: '今の札 ' + (this._spot + 1) + '：' + CARDS[this._spot],
      m0: (this._sel === 0 ? '▶ ' : '· ') + '対戦する（頭で札を取る）',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '記録を見る（ベスト・取札数）'
    };
    for (let i = 0; i < 20; i++) patch['c' + i] = (i + 1) + (taken[i] ? ' ●' : ' ○');
    this.setData(patch);
  },
  spotTap() { this._spot = (this._spot + 1) % CARDS.length; this._recompute(); },
  playTap() { try { wx.navigateTo({ url: '/pages/play/index' }); } catch (e) {} },
  recordTap() { try { wx.navigateTo({ url: '/pages/record/index' }); } catch (e) {} },
  openSel() { if (this._sel === 0) this.playTap(); else this.recordTap(); },
  speakTap() { this._speak('かるた取りです。' + CARDS[this._spot]); },
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
    <div class="ttl">かるた取り</div>
    <div class="status">{{ status }}</div>
    <div class="grid">
      <div class="grow"><div class="cell">{{ c0 }}</div><div class="cell">{{ c1 }}</div><div class="cell">{{ c2 }}</div><div class="cell">{{ c3 }}</div><div class="cell">{{ c4 }}</div></div>
      <div class="grow"><div class="cell">{{ c5 }}</div><div class="cell">{{ c6 }}</div><div class="cell">{{ c7 }}</div><div class="cell">{{ c8 }}</div><div class="cell">{{ c9 }}</div></div>
      <div class="grow"><div class="cell">{{ c10 }}</div><div class="cell">{{ c11 }}</div><div class="cell">{{ c12 }}</div><div class="cell">{{ c13 }}</div><div class="cell">{{ c14 }}</div></div>
      <div class="grow"><div class="cell">{{ c15 }}</div><div class="cell">{{ c16 }}</div><div class="cell">{{ c17 }}</div><div class="cell">{{ c18 }}</div><div class="cell">{{ c19 }}</div></div>
    </div>
    <div class="legend">●＝前回取った札 ○＝まだの札（札面は番号＋取／未で一覧）</div>
    <div class="spot">{{ spot }}</div>
    <div class="menu">
      <div class="mrow">{{ m0 }}</div>
      <div class="mrow">{{ m1 }}</div>
    </div>
    <div class="btnrow">
      <button class="cardbtn main" bindtap="playTap">対戦</button>
      <button class="cardbtn" bindtap="spotTap">次の札</button>
      <button class="cardbtn" bindtap="recordTap">記録</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; text-align: center; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; text-align: center; white-space: nowrap; overflow: hidden; }
.grid { margin-top: 10px; border: 2px solid rgba(64,255,94,0.7); padding: 6px 8px; background-color: #04140a; }
.grow { display: flex; flex-direction: row; }
.cell { flex: 1; color: #7dff9e; font-size: 13px; text-align: center; padding: 4px 0; border: 1px solid rgba(64,255,94,0.35); margin: 1px; font-family: monospace; }
.legend { color: rgba(125,255,158,0.75); font-size: 10px; margin-top: 4px; text-align: center; white-space: nowrap; overflow: hidden; }
.spot { color: #40ff5e; font-size: 14px; margin-top: 8px; text-align: center; white-space: nowrap; overflow: hidden; }
.menu { margin-top: 6px; }
.mrow { color: #7dff9e; font-size: 14px; line-height: 22px; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.cardbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 6px 6px 18px 18px; }
.btnrow .cardbtn:last-child { margin-right: 0; }
.cardbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
