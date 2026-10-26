<script def>
{
  "title": "Machi Kotowaza"
}
</script>

<script setup>
import wx from 'wx';

// JP21 kotowaza mode: 12-question proverb quiz, 3 stages (4 questions each).
// Answer A by turning the head left, B by turning right (yaw vs centre),
// or with the A/B keys and buttons. Score + best stage persist.
const KEY = 'machiGameSetV1';
const QS = [
  { q: '犬も歩けば', a: '棒に当たる', b: '猫に会う', ans: 0 },
  { q: '猿も木から', a: '眺める', b: '落ちる', ans: 1 },
  { q: '石の上にも', a: '三年', b: '一週間', ans: 0 },
  { q: '急がば', a: '走れ', b: '回れ', ans: 1 },
  { q: '花より', a: '団子', b: '葉っぱ', ans: 0 },
  { q: '猫に', a: '小判', b: '鈴', ans: 0 },
  { q: '馬の耳に', a: '風', b: '念仏', ans: 1 },
  { q: '七転び', a: '八起き', b: '七起き', ans: 0 },
  { q: 'ちりも積もれば', a: '川となる', b: '山となる', ans: 1 },
  { q: '雨降って', a: '地固まる', b: '川あふれる', ans: 0 },
  { q: '弘法にも筆の', a: '誤り', b: '自慢', ans: 0 },
  { q: '井の中の蛙', a: '池を知らず', b: '大海を知らず', ans: 1 }
];

export default {
  data: { status: '', prog: '', question: '', cardA: '', cardB: '', score: '', evt: 'EVT: ready' },

  onLoad() {
    this._idx = 0; this._score = 0; this._done = false; this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null; this._lock = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._startSensor();
    this._recompute();
  },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { taikoBest: 0, quizBest: 0, quizStage: 0, plays: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _stage() { return Math.min(3, Math.floor(this._idx / 4) + 1); },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 20 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        if (self._yaw0 === null) self._yaw0 = self._yaw;
        self._zoneTick();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _angDiff(a, b) { let d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() {
    if (this._done || this._lock || this._yaw === null || this._yaw0 === null) return;
    const dy = this._angDiff(this._yaw, this._yaw0);
    let z = 'C';
    if (dy <= -0.40) z = 'A'; else if (dy >= 0.40) z = 'B';
    if (z !== 'C' && this._zone === 'C') this._answer(z === 'A' ? 0 : 1);
    this._zone = z;
  },

  _answer(choice) {
    if (this._done || this._lock) return;
    this._lock = true;
    const q = QS[this._idx];
    const ok = choice === q.ans;
    if (ok) this._score += 100;
    this.setData({ evt: 'EVT: ' + (ok ? 'correct' : 'wrong') + ' Q' + (this._idx + 1) });
    this._speak(ok ? '正解です。' : '残念、答えは' + (q.ans === 0 ? q.a : q.b) + 'です。');
    this._idx++;
    const self = this;
    setTimeout(function () {
      self._lock = false;
      if (self._idx >= QS.length) self._finish(); else self._recompute();
    }, 350);
    this._recompute();
  },
  _finish() {
    this._done = true;
    const st = this._load();
    st.plays = (st.plays || 0) + 1;
    if (this._score > (st.quizBest || 0)) st.quizBest = this._score;
    if (this._stage() > (st.quizStage || 0)) st.quizStage = 3;
    this._save(st);
    this._speak('全問終わりました。スコアは' + this._score + '点です。');
    this._recompute();
  },
  againTap() { this._idx = 0; this._score = 0; this._done = false; this._yaw0 = this._yaw; this._recompute(); },
  aTap() { this._answer(0); },
  bTap() { this._answer(1); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },

  _recompute() {
    if (this._done) {
      this.setData({
        status: 'ことわざクイズ：終了',
        prog: '全 12 問 ・ 第3級まで到達',
        question: 'スコア ' + this._score + ' 点',
        cardA: 'もう一度', cardB: 'メニューへ',
        score: 'BEST は記録に保存されました'
      });
      return;
    }
    const q = QS[this._idx];
    this.setData({
      status: 'ことわざクイズ：' + (this._sensorOk ? '頭の左右で回答' : 'キー・ボタンでも回答できます'),
      prog: '第' + this._stage() + '級 ・ ' + (this._idx + 1) + ' / 12 問',
      question: q.q + ' ＿＿',
      cardA: 'A: ' + q.a,
      cardB: 'B: ' + q.b,
      score: 'SCORE ' + this._score
    });
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
    if (key === 'ArrowLeft') { event.preventDefault(); if (this._done) this.againTap(); else this._answer(0); return; }
    if (key === 'ArrowRight') { event.preventDefault(); if (this._done) this.backTap(); else this._answer(1); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); if (this._done) this.againTap(); return; }
  },
  onKeyUp(event) { if (['ArrowLeft', 'ArrowRight', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Kotowaza Quiz</div>
    <div class="status">{{ status }}</div>
    <div class="prog">{{ prog }}</div>
    <div class="question">{{ question }}</div>
    <div class="cards">
      <div class="card card-l" bindtap="aTap">{{ cardA }}</div>
      <div class="card card-r" bindtap="bTap">{{ cardB }}</div>
    </div>
    <div class="score">{{ score }}</div>
    <div class="btnrow">
      <button class="pill" bindtap="aTap">A</button>
      <button class="pill" bindtap="bTap">B</button>
      <button class="pill" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; text-align: center; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; text-align: center; white-space: nowrap; overflow: hidden; }
.prog { color: #7dff9e; font-size: 13px; margin-top: 10px; font-family: monospace; }
.question { color: #7dff9e; font-size: 25px; font-weight: bold; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.cards { display: flex; flex-direction: row; margin-top: 14px; }
.card { flex: 1; margin-right: 10px; border: 2px solid rgba(64,255,94,0.8); color: #40ff5e; font-size: 17px; font-weight: bold; padding: 16px 8px; text-align: center; background-color: #061a0b; white-space: nowrap; overflow: hidden; }
.cards .card:last-child { margin-right: 0; }
.card-l { border-radius: 4px 26px 4px 26px; }
.card-r { border-radius: 26px 4px 26px 4px; }
.score { color: #40ff5e; font-size: 13px; margin-top: 10px; font-family: monospace; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.pill { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 14px; padding: 6px 0; text-align: center; border-radius: 16px; }
.btnrow .pill:last-child { margin-right: 0; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
