<script def>
{
  "title": "Karuta Play"
}
</script>

<script setup>
import wx from 'wx';

// JP25 karuta-tori - 対戦.
// 20 rounds, one target card per round. TTS reads the target kami phrase;
// the player moves the cursor among 4 candidate cards with head yaw
// (AbsoluteOrientationSensor vs centre calibrated at start, segmented
// motion: turn, return to centre, next - never circling) or Arrow keys,
// and confirms with onHeadGesture('nod') or Enter. Correct +100, wrong
// -50. After 20 rounds the game settles: 14+ correct = win. Scores persist
// in wx storage 'karutaToriV1'. Sensor absent -> keys stand in, said honestly.
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
  data: { status: '', round: '', target: '', cand0: '', cand1: '', cand2: '', cand3: '', score: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._playing = false; this._round = 0; this._order = []; this._cands = []; this._cursor = 0;
    this._score = 0; this._correct = 0; this._taken = [];
    this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._startSensor();
    this._recompute();
  },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { best: 0, takenTotal: 0, plays: 0, lastScore: 0, lastCorrect: 0, lastTaken: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 30 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        self._zoneTick();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _angDiff(a, b) { let d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() {
    if (!this._playing || this._yaw === null || this._yaw0 === null) return;
    const dy = this._angDiff(this._yaw, this._yaw0);
    let z = 'C';
    if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R';
    if (z !== 'C' && this._zone === 'C') this._move(z === 'L' ? -1 : 1);
    this._zone = z;
  },
  _shuffle(arr) {
    for (let i = arr.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); const t = arr[i]; arr[i] = arr[j]; arr[j] = t; }
    return arr;
  },
  _move(d) {
    if (!this._playing) return;
    this._cursor = (this._cursor + d + this._cands.length) % this._cands.length;
    this._recompute();
  },
  _beginRound() {
    const target = this._order[this._round];
    const pool = [];
    for (let i = 0; i < CARDS.length; i++) if (i !== target) pool.push(i);
    this._shuffle(pool);
    this._cands = this._shuffle([target, pool[0], pool[1], pool[2]]);
    this._cursor = 0;
    this._recompute();
    this._speak('聞いてください。' + CARDS[target]);
  },
  startTap() {
    if (this._playing) return;
    this._order = this._shuffle([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
    this._round = 0; this._score = 0; this._correct = 0; this._taken = [];
    this._yaw0 = this._yaw; this._zone = 'C'; this._playing = true;
    this._speak('かるた取り、はじめます。正面を向いてください。');
    this._beginRound();
  },
  confirmTap() {
    if (!this._playing) { this.startTap(); return; }
    const picked = this._cands[this._cursor];
    const target = this._order[this._round];
    if (picked === target) {
      this._score += 100; this._correct++; this._taken.push(target);
      this.setData({ evt: 'EVT: HIT card ' + (target + 1) + ' score ' + this._score });
      this._speak('その通りです。');
    } else {
      this._score -= 50;
      this.setData({ evt: 'EVT: MISS picked ' + (picked + 1) + ' vs ' + (target + 1) + ' score ' + this._score });
      this._speak('残念、ちがう札でした。');
    }
    this._round++;
    if (this._round >= 20) this._finish(); else this._beginRound();
  },
  _finish() {
    this._playing = false;
    const win = this._correct >= 14;
    const st = this._load();
    st.plays = (st.plays || 0) + 1;
    st.takenTotal = (st.takenTotal || 0) + this._correct;
    if (this._score > (st.best || 0)) st.best = this._score;
    st.lastScore = this._score; st.lastCorrect = this._correct; st.lastTaken = this._taken.slice();
    this._save(st);
    this._speak(win ? ('勝ちです。' + this._score + '点、' + this._correct + '枚取りました。') : ('終わりです。' + this._score + '点、' + this._correct + '枚でした。'));
    this.setData({ evt: 'EVT: finished ' + (win ? 'WIN' : 'LOSE') + ' score ' + this._score + ' correct ' + this._correct });
    this._recompute(win);
  },
  replayTap() {
    if (!this._playing) return;
    this._speak(CARDS[this._order[this._round]]);
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  _recompute(win) {
    const patch = {
      status: 'かるた対戦：' + (this._sensorOk ? '頭センサー使用中' : 'センサーなし（キーでも遊べます）'),
      round: this._playing ? ('第' + (this._round + 1) + '首 / 20首') : '20首の対戦',
      target: this._playing ? '聞いた句に合う札を選んでください' : (win === true ? '勝ちです。もう一度遊べます。' : (win === false ? '負けです。もう一度遊べます。' : '取る で開始（正面を向いてください）')),
      score: 'SCORE ' + this._score + ' ・ 取った札 ' + this._correct + '枚',
      guide: '左・右を向いて選び、正面に戻る（回しません）。うなずき／Enter で取る。'
    };
    for (let i = 0; i < 4; i++) {
      patch['cand' + i] = this._playing ? ((i === this._cursor ? '▶ ' : '· ') + (this._cands[i] + 1) + ' ' + CARDS[this._cands[i]]) : '候補は対戦中に表示されます';
    }
    this.setData(patch);
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.confirmTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowLeft') { event.preventDefault(); this._move(-1); return; }
    if (key === 'ArrowRight') { event.preventDefault(); this._move(1); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._move(-1); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._move(1); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.confirmTap(); return; }
  },
  onKeyUp(event) { if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">かるた対戦</div>
    <div class="status">{{ status }}</div>
    <div class="round">{{ round }}</div>
    <div class="target">{{ target }}</div>
    <div class="candlist">
      <div class="crow">{{ cand0 }}</div>
      <div class="crow">{{ cand1 }}</div>
      <div class="crow">{{ cand2 }}</div>
      <div class="crow">{{ cand3 }}</div>
    </div>
    <div class="score">{{ score }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="takebtn main" bindtap="confirmTap">取る</button>
      <button class="takebtn" bindtap="replayTap">もう一度聞く</button>
      <button class="takebtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.round { color: #7dff9e; font-size: 15px; margin-top: 14px; font-family: monospace; }
.target { color: #40ff5e; font-size: 15px; margin-top: 10px; border: 3px solid rgba(64,255,94,0.8); background-color: #071c0c; padding: 22px 10px; }
.candlist { margin-top: 12px; border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 6px 10px; text-align: left; }
.crow { color: #7dff9e; font-size: 14px; line-height: 24px; white-space: nowrap; overflow: hidden; }
.score { color: #40ff5e; font-size: 14px; margin-top: 12px; font-family: monospace; }
.guide { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.takebtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 18px 18px 6px 6px; }
.btnrow .takebtn:last-child { margin-right: 0; }
.takebtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
