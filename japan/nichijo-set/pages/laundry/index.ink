<script def>
{
  "title": "Nichijo Laundry"
}
</script>

<script setup>
import wx from 'wx';

// JP22 laundry mode: countdown watch for 3 machines.
// End times are stored as timestamps in wx storage 'nichijoSetV1', so the
// watch survives leaving the page or the app; a 5-second tick refreshes the
// remaining time and announces the end once (TTS + on-screen state).
const KEY = 'nichijoSetV1';
const MACHINES = ['洗濯機 A', '洗濯機 B', '乾燥機'];
const PRESETS = [30, 45, 60];

export default {
  data: { status: '', m0: '', m1: '', m2: '', detail: '', evt: 'EVT: ready' },

  onLoad() {
    this._sel = 0; this._preset = 0; this._timer = null;
    const st = this._load();
    if (!st.laundry || st.laundry.length !== 3) { st.laundry = MACHINES.map(function (n) { return { name: n, endAt: 0, notified: false }; }); this._save(st); }
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
    const self = this;
    this._timer = setInterval(function () { self._tick(); }, 5000);
  },
  onHide() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },
  onUnload() { if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; } },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { proof: null, laundry: [], origami: { done: [], work: 0, step: 0 } }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _tick() {
    const st = this._load();
    let changed = false;
    (st.laundry || []).forEach(function (m) {
      if (m.endAt && m.endAt <= Date.now() && !m.notified) { m.notified = true; changed = true; this._speak(m.name + 'が終わりました。取り出してください。'); }
    }.bind(this));
    if (changed) this._save(st);
    this._recompute();
  },
  _fmtRemain(m) {
    if (!m.endAt) return '未開始';
    const r = Math.round((m.endAt - Date.now()) / 60000);
    if (r <= 0) return '終了';
    return 'あと ' + r + ' 分';
  },
  _recompute() {
    const st = this._load();
    const ms = st.laundry || [];
    const row = function (m, i) { return (i === this._sel ? '▶ ' : '· ') + m.name + ' …… ' + this._fmtRemain(m); }.bind(this);
    this.setData({
      status: 'ランドリー守候: 終了時刻は端末に保存され、離れても数え続けます',
      m0: ms[0] ? row(ms[0], 0) : '', m1: ms[1] ? row(ms[1], 1) : '', m2: ms[2] ? row(ms[2], 2) : '',
      detail: '選択中: ' + MACHINES[this._sel] + ' ・ 時間設定 ' + PRESETS[this._preset] + ' 分（TIME で切替、START で開始）'
    });
  },
  nextTap() { this._sel = (this._sel + 1) % MACHINES.length; this._recompute(); },
  timeTap() { this._preset = (this._preset + 1) % PRESETS.length; this._recompute(); },
  startTap() {
    const st = this._load();
    st.laundry[this._sel] = { name: MACHINES[this._sel], endAt: Date.now() + PRESETS[this._preset] * 60000, notified: false };
    this._save(st);
    this._speak(MACHINES[this._sel] + 'を始めました。' + PRESETS[this._preset] + '分後に知らせします。');
    this.setData({ evt: 'EVT: started - ' + MACHINES[this._sel] });
    this._recompute();
  },
  stopTap() {
    const st = this._load();
    st.laundry[this._sel] = { name: MACHINES[this._sel], endAt: 0, notified: false };
    this._save(st);
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
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.startTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.timeTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Laundry Watch</div>
    <div class="status">{{ status }}</div>
    <div class="machines">
      <div class="mrow">{{ m0 }}</div>
      <div class="mrow">{{ m1 }}</div>
      <div class="mrow">{{ m2 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="dial main" bindtap="startTap">START</button>
      <button class="dial" bindtap="timeTap">TIME</button>
      <button class="dial" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="dial" bindtap="stopTap">STOP</button>
      <button class="dial" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.machines { margin-top: 12px; }
.mrow { color: #7dff9e; font-size: 20px; font-weight: bold; line-height: 34px; border-bottom: 1px solid rgba(64,255,94,0.45); white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.dial { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.75); font-size: 14px; padding: 7px 0; text-align: center; border-radius: 50%; }
.btnrow .dial:last-child { margin-right: 0; }
.dial.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
