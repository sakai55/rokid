<script def>
{
  "title": "Eki Dekake"
}
</script>

<script setup>
import wx from 'wx';

// JP20 eki-dekake - 駅ボード (station board).
// Merged rebuild of JP14 kasa-share + JP16 eki-barrier.
// Station facility set: 6 stations, each with elevator side, umbrella point,
// return deadline. Last station + trips persist in wx storage 'ekiDekakeV1'.
const STATIONS = [
  { name: '東京駅', side: '中央', elv: '丸の内中央口・改札内', kasa: '丸の内南口 傘スタンド', hours: 6 },
  { name: '新宿駅', side: '左', elv: '西口・改札外 左手', kasa: '西口交番前 傘スタンド', hours: 4 },
  { name: '渋谷駅', side: '右', elv: 'ハチ公改札・右手 通路奥', kasa: 'ハチ公口 傘スタンド', hours: 4 },
  { name: '池袋駅', side: '左', elv: '中央改札・左手 地下通路', kasa: '中央口 傘スタンド', hours: 5 },
  { name: '品川駅', side: '右', elv: '中央改札・右手 港南口方面', kasa: '中央口 傘スタンド', hours: 6 },
  { name: '上野駅', side: '中央', elv: '中央改札・正面 地下', kasa: '正面玄関 傘スタンド', hours: 5 }
];
const KEY = 'ekiDekakeV1';

export default {
  data: { status: '', row0: '', row1: '', row2: '', row3: '', row4: '', row5: '', detail: '', detail2: '', head: '', evt: 'EVT: ready' },

  onLoad() {
    this._idx = 0; this._steady = false; this._yaw = null; this._yaw0 = null; this._sensorOk = false; this._sensor = null; this._headShown = '';
    const st = this._load();
    if (st && typeof st.lastStation === 'number') this._idx = st.lastStation;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._startSensor();
    this._recompute();
  },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { lastStation: 0, kasa: null, trips: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _startSensor() {
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; }
      const s = new AbsoluteOrientationSensor({ frequency: 15 });
      const self = this;
      s.addEventListener('reading', function () {
        const q = s.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
        if (self._yaw0 === null) self._yaw0 = self._yaw;
        self._headTick();
      });
      s.addEventListener('error', function () {});
      s.start(); this._sensor = s; this._sensorOk = true;
    } catch (e) { this._sensorOk = false; }
  },
  _angDiff(a, b) { let d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _headTick() {
    if (this._yaw === null || this._yaw0 === null) return;
    const d = this._angDiff(this._yaw, this._yaw0);
    let t = '正面';
    if (d >= 0.30) t = '左向き'; else if (d <= -0.30) t = '右向き';
    const st = STATIONS[this._idx];
    const msg = '頭: ' + t + ' ／ この駅の昇降機は ' + st.side;
    if (msg !== this._headShown) { this._headShown = msg; this.setData({ head: msg }); }
  },

  _recompute() {
    const st = STATIONS[this._idx];
    const rows = STATIONS.map((s2, i) => (i === this._idx ? '▶ ' : '· ') + s2.name + ' …… 昇降機 ' + s2.side);
    const saved = this._load();
    const kasaTxt = (saved && saved.kasa && saved.kasa.active) ? '傘：借りています（' + saved.kasa.station + '）' : '傘：借りていません';
    this.setData({
      status: '駅ボード：' + st.name + ' を表示中 ・ ' + kasaTxt,
      row0: rows[0], row1: rows[1], row2: rows[2], row3: rows[3], row4: rows[4], row5: rows[5],
      detail: '昇降機: ' + st.elv,
      detail2: '傘: ' + st.kasa + ' ／ 返却期限 ' + st.hours + ' 時間',
      head: this._sensorOk ? (this._headShown || '頭: 読取中…') : '頭: センサーなし（手動で確認してください）'
    });
  },

  prevTap() { this._idx = (this._idx + STATIONS.length - 1) % STATIONS.length; this._headShown = ''; this.setData({ evt: 'EVT: prev station' }); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % STATIONS.length; this._headShown = ''; this.setData({ evt: 'EVT: next station' }); this._recompute(); },
  goTap() {
    const st = this._load(); st.lastStation = this._idx; this._save(st);
    this._speak(STATIONS[this._idx].name + '。昇降機は' + STATIONS[this._idx].side + 'です。');
    this.setData({ evt: 'EVT: station fixed - ' + STATIONS[this._idx].name });
    this._recompute();
  },
  kasaTap() { try { wx.navigateTo({ url: '/pages/kasa/index' }); } catch (e) {} },
  recordTap() { try { wx.navigateTo({ url: '/pages/record/index' }); } catch (e) {} },
  speakTap() { const st = STATIONS[this._idx]; this._speak(st.name + '。昇降機は' + st.elv + '。傘は' + st.kasa + '、返却期限は' + st.hours + '時間です。'); },

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
    if (g !== 'nod' || !this._steady) return;
    this.goTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === 'Enter') event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Eki Dekake</div>
    <div class="status">{{ status }}</div>
    <div class="board">
      <div class="brow">{{ row0 }}</div>
      <div class="brow">{{ row1 }}</div>
      <div class="brow">{{ row2 }}</div>
      <div class="brow">{{ row3 }}</div>
      <div class="brow">{{ row4 }}</div>
      <div class="brow">{{ row5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="detail dim">{{ detail2 }}</div>
    <div class="head">{{ head }}</div>
    <div class="btnrow">
      <button class="chip" bindtap="prevTap">PREV</button>
      <button class="chip chip-main" bindtap="goTap">FIX</button>
      <button class="chip" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="chip wide" bindtap="kasaTap">KASA</button>
      <button class="chip wide" bindtap="recordTap">RECORD</button>
      <button class="chip wide" bindtap="speakTap">SPEAK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 3px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.board { margin-top: 8px; border: 2px solid rgba(64,255,94,0.65); padding: 6px 10px; background-color: #04140a; }
.brow { color: #7dff9e; font-size: 13px; line-height: 19px; white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 12px; line-height: 17px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.dim { color: rgba(125,255,158,0.78); }
.head { color: #7dff9e; font-size: 12px; margin-top: 4px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 7px; }
.chip { flex: 1; margin-right: 6px; background-color: #0a1f0e; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 5px 0; text-align: center; border-radius: 3px; }
.btnrow .chip:last-child { margin-right: 0; }
.chip-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.wide { letter-spacing: 1px; }
.foot { position: absolute; left: 14px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
