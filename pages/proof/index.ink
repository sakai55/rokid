<script def>
{
  "title": "Nichijo Proof"
}
</script>

<script setup>
import wx from 'wx';

// JP22 proof mode: leave-home evidence checklist.
// Five points (gas, front-door lock, window lock, water, air conditioner).
// Each point is proven either by a real camera photo (ImageCapture.takePhoto,
// CAMERA permission declared) or by an explicit manual check - the mode is
// recorded honestly ('写真' vs '手動', with the time). When all five are
// proven, the record is stored and can be replayed after leaving home.
const KEY = 'nichijoSetV1';
const POINTS = ['ガスコンロ', '玄関の鍵', '窓の鍵', '水道', 'エアコン'];

export default {
  data: { status: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', evt: 'EVT: ready' },

  onLoad() {
    this._idx = 0; this._marks = POINTS.map(function () { return null; });
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { proof: null, laundry: [], origami: { done: [], work: 0, step: 0 } }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },

  _recompute() {
    const rows = POINTS.map(function (name, i) {
      const m = this._marks[i];
      return (i === this._idx ? '▶ ' : '· ') + name + (m ? (' …… ' + m.mode + ' ' + m.at) : ' …… 未');
    }.bind(this));
    const done = this._marks.filter(Boolean).length;
    this.setData({
      status: '出発前チェック: ' + done + ' / 5 済み',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4],
      detail: done >= 5 ? '全部そろいました。出発できます（記録は今日の分として保存済み）。' : ('今の項目: ' + POINTS[this._idx] + ' ・ 写真で残すか、手動で確認してください。')
    });
  },
  _mark(mode) {
    this._marks[this._idx] = { mode: mode, at: this._time() };
    if (this._marks.filter(Boolean).length >= 5) {
      const st = this._load();
      st.proof = { date: new Date().toISOString().slice(0, 10), at: this._time(), points: this._marks.map(function (m, i) { return { name: POINTS[i], mode: m.mode, at: m.at }; }) };
      this._save(st);
      this._speak('全部のチェックが終わりました。記録を保存しました。');
    }
    this._recompute();
  },
  async photoTap() {
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) throw new Error('camera n/a');
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      const track = stream.getVideoTracks()[0];
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      const cap = new ImageCapture(track);
      await cap.takePhoto({ mode: 'default' });
      try { track.stop(); } catch (e) {}
      this.setData({ evt: 'EVT: photo taken - ' + POINTS[this._idx] });
      this._mark('写真');
    } catch (e) {
      this.setData({ evt: 'EVT: photo failed (' + String(e).slice(0, 60) + ') - 手動確認できます' });
    }
  },
  manualTap() { this._mark('手動'); this.setData({ evt: 'EVT: manual check - ' + POINTS[this._idx] }); },
  nextTap() { this._idx = (this._idx + 1) % POINTS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + POINTS.length - 1) % POINTS.length; this._recompute(); },
  replayTap() {
    const st = this._load();
    if (st.proof && st.proof.points) {
      const first = st.proof.points[0];
      this._speak('今日の記録です。' + first.name + 'は' + first.at + 'に' + first.mode + 'で確認しました。全五か所そろっています。');
      this.setData({ evt: 'EVT: replay - ' + st.proof.date + ' ' + st.proof.at });
    } else {
      this._speak('今日の記録はまだありません。');
      this.setData({ evt: 'EVT: no record yet' });
    }
  },
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
    if (g === 'nod') this.nextTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.manualTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Leave-Home Proof</div>
    <div class="status">{{ status }}</div>
    <div class="list">
      <div class="lrow">{{ r0 }}</div>
      <div class="lrow">{{ r1 }}</div>
      <div class="lrow">{{ r2 }}</div>
      <div class="lrow">{{ r3 }}</div>
      <div class="lrow">{{ r4 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="stampbtn main" bindtap="photoTap">PHOTO</button>
      <button class="stampbtn" bindtap="manualTap">MANUAL</button>
      <button class="stampbtn" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="stampbtn" bindtap="replayTap">REPLAY</button>
      <button class="stampbtn" bindtap="prevTap">PREV</button>
      <button class="stampbtn" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.list { margin-top: 10px; border: 1px solid rgba(64,255,94,0.6); padding: 8px 12px; background-color: #04140a; }
.lrow { color: #7dff9e; font-size: 14px; line-height: 23px; white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 9px; }
.stampbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 50%; }
.btnrow .stampbtn:last-child { margin-right: 0; }
.stampbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
