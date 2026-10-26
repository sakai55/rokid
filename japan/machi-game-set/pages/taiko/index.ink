<script def>
{
  "title": "Machi Taiko"
}
</script>

<script setup>
import wx from 'wx';

// JP21 taiko mode: head-action rhythm game.
// Songs: 3 (patterns of N=nod / L=turn left / R=turn right, segmented motion,
// always return to centre between actions - never circling).
// Head actions come from AbsoluteOrientationSensor yaw/pitch vs the centre
// calibrated at song start; nod also arrives via onHeadGesture.
// Sensor absent -> keys stand in (ArrowLeft/ArrowRight/Enter), said honestly.
const KEY = 'machiGameSetV1';
const SONGS = [
  { name: '祭り囃子', bpm: 72, beats: ['N', 'N', 'L', 'N', 'R', 'N', 'L', 'R'] },
  { name: '盆踊り', bpm: 60, beats: ['N', 'L', 'N', 'R', 'N', 'L', 'L', 'N', 'R', 'N'] },
  { name: '山車リズム', bpm: 84, beats: ['N', 'R', 'N', 'L', 'R', 'N', 'L', 'N', 'R', 'L', 'N', 'N'] }
];
const LABEL = { N: 'うなずく ドン', L: '左を向く カッ', R: '右を向く カッ' };

export default {
  data: { status: '', song: '', big: '', score: '', dots: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._song = 0; this._playing = false; this._beat = -1; this._score = 0; this._combo = 0; this._judged = -1;
    this._yaw = null; this._pitch = null; this._yaw0 = null; this._pitch0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null; this._timer = null; this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._startSensor();
    this._recompute();
  },
  onHide() { this._stop(); },
  onUnload() { this._stop(); if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _stop() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } this._playing = false; },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { taikoBest: 0, quizBest: 0, quizStage: 0, plays: 0 }; },
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
        const sp = 2 * (w * x - y * z);
        self._pitch = sp >= 1 ? Math.PI / 2 : (sp <= -1 ? -Math.PI / 2 : Math.asin(sp));
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
    const dp = this._pitch - this._pitch0;
    let z = 'C';
    if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R'; else if (dp <= -0.26) z = 'N';
    if (z !== 'C' && this._zone === 'C') this._action(z);
    this._zone = z;
  },
  _action(act) {
    if (!this._playing) return;
    const song = SONGS[this._song];
    if (this._beat < 0 || this._beat >= song.beats.length) return;
    if (this._judged === this._beat) return;
    this._judged = this._beat;
    if (act === song.beats[this._beat]) { this._score += 100; this._combo++; this.setData({ evt: 'EVT: HIT ' + act + ' combo ' + this._combo }); }
    else { this._combo = 0; this.setData({ evt: 'EVT: MISS ' + act + ' vs ' + song.beats[this._beat] }); }
    this._recompute();
  },

  startTap() {
    if (this._playing) return;
    const song = SONGS[this._song];
    this._score = 0; this._combo = 0; this._beat = -1; this._judged = -1;
    this._yaw0 = this._yaw; this._pitch0 = this._pitch; this._zone = 'C';
    this._playing = true;
    this._speak(song.name + '、はじめます。正面を向いて、拍に合わせてどうぞ。');
    const self = this;
    const stepMs = Math.round(60000 / song.bpm);
    this._timer = setInterval(function () {
      self._beat++;
      if (self._beat >= song.beats.length) { self._finish(); return; }
      self._recompute();
    }, stepMs);
    this._recompute();
  },
  _finish() {
    this._stop();
    const st = this._load();
    st.plays = (st.plays || 0) + 1;
    if (this._score > (st.taikoBest || 0)) st.taikoBest = this._score;
    this._save(st);
    this._speak('終わりです。スコアは' + this._score + '点でした。');
    this.setData({ evt: 'EVT: finished score ' + this._score });
    this._recompute(true);
  },
  songTap() { if (this._playing) return; this._song = (this._song + 1) % SONGS.length; this._recompute(); },
  backTap() { this._stop(); try { wx.navigateBack({}); } catch (e) {} },

  _recompute(finished) {
    const song = SONGS[this._song];
    let dots = '';
    for (let i = 0; i < song.beats.length; i++) dots += (i < this._beat ? '●' : (i === this._beat ? '◉' : '○'));
    const cur = (this._playing && this._beat >= 0 && this._beat < song.beats.length) ? LABEL[song.beats[this._beat]] : (finished ? 'おつかれさま' : 'START で開始');
    this.setData({
      status: '祭り太鼓：' + (this._sensorOk ? '頭センサー使用中' : 'センサーなし（キーでも遊べます）'),
      song: song.name + ' ・ ' + song.bpm + ' BPM ・ ' + song.beats.length + ' 拍',
      big: cur,
      score: 'SCORE ' + this._score + ' ・ COMBO ' + this._combo,
      dots: dots,
      guide: 'ドン=うなずく ／ カッ=左・右を向いて正面に戻る（回しません）'
    });
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || {}; this._steady = d.isStable === true || d.stable === true; },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this._action('N');
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowLeft') { event.preventDefault(); this._action('L'); return; }
    if (key === 'ArrowRight') { event.preventDefault(); this._action('R'); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); if (this._playing) this._action('N'); else this.startTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.songTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.backTap(); return; }
  },
  onKeyUp(event) { if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Matsuri Taiko</div>
    <div class="status">{{ status }}</div>
    <div class="song">{{ song }}</div>
    <div class="drum">{{ big }}</div>
    <div class="dots">{{ dots }}</div>
    <div class="score">{{ score }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="beatbtn main" bindtap="startTap">START</button>
      <button class="beatbtn" bindtap="songTap">SONG</button>
      <button class="beatbtn" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.song { color: #7dff9e; font-size: 13px; margin-top: 8px; font-family: monospace; }
.drum { color: #7dff9e; font-size: 30px; font-weight: bold; margin-top: 18px; border: 3px solid rgba(64,255,94,0.8); border-radius: 50%; width: 300px; margin-left: 74px; padding: 26px 0; background-color: #071c0c; white-space: nowrap; overflow: hidden; }
.dots { color: #40ff5e; font-size: 17px; letter-spacing: 3px; margin-top: 12px; font-family: monospace; }
.score { color: #40ff5e; font-size: 14px; margin-top: 6px; font-family: monospace; }
.guide { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.beatbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 14px; padding: 6px 0; text-align: center; border-radius: 24px; }
.btnrow .beatbtn:last-child { margin-right: 0; }
.beatbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
