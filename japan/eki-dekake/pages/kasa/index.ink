<script def>
{
  "title": "Eki Dekake Kasa"
}
</script>

<script setup>
import wx from 'wx';

// JP20 eki-dekake - 傘フロー: borrow register -> deadline watch -> return confirm.
// State persists in wx storage 'ekiDekakeV1' (shared with the station board).
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
  data: { status: '', phase: '', line1: '', line2: '', line3: '', evt: 'EVT: ready' },

  onLoad() {
    this._steady = false; this._timer = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
    const self = this;
    this._timer = setInterval(function () { self._recompute(); }, 30000);
  },
  onHide() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },
  onUnload() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { lastStation: 0, kasa: null, trips: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _station() { const st = this._load(); const i = (st && typeof st.lastStation === 'number') ? st.lastStation : 0; return STATIONS[i]; },
  _fmt(t) { const d = new Date(t); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },

  _recompute() {
    const st = this._load(); const s = this._station();
    if (st.kasa && st.kasa.active) {
      const remain = Math.max(0, Math.round((st.kasa.deadline - Date.now()) / 60000));
      const over = Date.now() > st.kasa.deadline;
      this.setData({
        status: '傘フロー：貸出中（' + st.kasa.station + '）',
        phase: over ? '期限を過ぎています' : '期限まで あと ' + remain + ' 分',
        line1: '借りた駅: ' + st.kasa.station + ' ' + this._fmt(st.kasa.borrowedAt) + ' に登録',
        line2: '返す場所: ' + st.kasa.point,
        line3: '返却したら RETURNED を押してください。本人の確認だけが記録されます。'
      });
    } else {
      this.setData({
        status: '傘フロー：まだ借りていません（駅は ' + s.name + '）',
        phase: '手順 1/3 借りる登録',
        line1: '傘スタンド: ' + s.kasa,
        line2: '返却期限: ' + s.hours + ' 時間（登録した時刻から）',
        line3: 'スタンドで傘を受け取ったら BORROW を押してください。'
      });
    }
  },

  borrowTap() {
    const st = this._load(); const s = this._station();
    if (st.kasa && st.kasa.active) { this.setData({ evt: 'EVT: already borrowed' }); return; }
    st.kasa = { active: true, station: s.name, point: s.kasa, borrowedAt: Date.now(), deadline: Date.now() + s.hours * 3600000 };
    this._save(st);
    this._speak('シェア傘を借りました。返却期限は' + s.hours + '時間です。');
    this.setData({ evt: 'EVT: borrowed - ' + s.name });
    this._recompute();
  },
  returnedTap() {
    const st = this._load();
    if (!st.kasa || !st.kasa.active) { this.setData({ evt: 'EVT: nothing to return' }); return; }
    const trip = { date: new Date().toISOString().slice(0, 10), station: st.kasa.station, phase: '傘を返却', at: this._fmt(Date.now()) };
    st.trips = st.trips || []; st.trips.push(trip);
    st.kasa = { active: false };
    this._save(st);
    this._speak('返却を記録しました。お疲れさまでした。');
    this.setData({ evt: 'EVT: returned recorded' });
    this._recompute();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  speakTap() {
    const st = this._load();
    if (st.kasa && st.kasa.active) { const r = Math.max(0, Math.round((st.kasa.deadline - Date.now()) / 60000)); this._speak('傘の返却期限まで、あと' + r + '分です。返す場所は' + st.kasa.point + 'です。'); }
    else this._speak('傘はまだ借りていません。駅は' + this._station().name + 'です。');
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
    if (g !== 'nod' || !this._steady) return;
    const st = this._load();
    if (st.kasa && st.kasa.active) this.returnedTap(); else this.borrowTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); const st = this._load(); if (st.kasa && st.kasa.active) this.returnedTap(); else this.borrowTap(); return; }
  },
  onKeyUp(event) { if (event.key === 'Enter') event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Kasa Flow</div>
    <div class="status">{{ status }}</div>
    <div class="clock">{{ phase }}</div>
    <div class="line">{{ line1 }}</div>
    <div class="line">{{ line2 }}</div>
    <div class="line dim">{{ line3 }}</div>
    <div class="steps">
      <div class="step">1 登録</div>
      <div class="step">2 期限守候</div>
      <div class="step">3 返却確認</div>
    </div>
    <div class="btnrow">
      <button class="tag tag-main" bindtap="borrowTap">BORROW</button>
      <button class="tag" bindtap="returnedTap">RETURNED</button>
    </div>
    <div class="btnrow">
      <button class="tag" bindtap="speakTap">SPEAK</button>
      <button class="tag" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.clock { color: #7dff9e; font-size: 27px; font-weight: bold; margin-top: 16px; letter-spacing: 1px; white-space: nowrap; overflow: hidden; }
.line { color: #40ff5e; font-size: 13px; line-height: 19px; margin-top: 7px; white-space: nowrap; overflow: hidden; }
.dim { color: rgba(125,255,158,0.75); font-size: 12px; }
.steps { display: flex; flex-direction: row; margin-top: 14px; }
.step { flex: 1; margin-right: 6px; border-top: 3px solid rgba(64,255,94,0.7); color: #7dff9e; font-size: 11px; padding-top: 4px; text-align: center; }
.steps .step:last-child { margin-right: 0; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.tag { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px dashed rgba(64,255,94,0.85); font-size: 14px; padding: 7px 0; text-align: center; border-radius: 2px; }
.btnrow .tag:last-child { margin-right: 0; }
.tag-main { background-color: #14541f; color: #7dff9e; font-weight: bold; border-style: solid; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
