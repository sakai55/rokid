<script def>
{
  "title": "Retrace Guide"
}
</script>

<script setup>
import wx from 'wx';

// CC12 guide: walk the anchors back in reverse, one segment at a time.
// Only the current segment is shown in large type. Nod or Enter confirms
// arrival at that anchor and moves to the next segment; when the last
// segment is confirmed, the completed guide is announced and persisted.
// Direction reference is the recorded yaw of the target anchor, or pure
// order when the anchor was stored without a yaw. No map is involved.
const KEY = 'retraceStepsV1';

export default {
  data: { big: '', progress: '', detail: '', evt: '记录: 准备完成' },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._step = 0;
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { anchors: [], guides: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _time() { const d = new Date(); const p = function (n) { return (n < 10 ? '0' : '') + n; }; return p(d.getHours()) + ':' + p(d.getMinutes()); },
  _reversed() { const st = this._load(); return (st.anchors || []).slice().reverse(); },
  _recompute() {
    const rev = this._reversed();
    if (!rev.length) {
      this.setData({
        big: '还没有锚点',
        progress: '0 / 0 段',
        detail: '先去“锚点记录”页：每个转弯/地标处点头落一个点，再回来。',
        evt: '记录: 无锚点'
      });
      return;
    }
    if (this._step >= rev.length) this._step = rev.length - 1;
    const a = rev[this._step];
    const yawTxt = (a.yawDeg !== null && a.yawDeg !== undefined) ? ('，落点时朝向约' + a.yawDeg + '°') : '（该点无朝向记录，按顺序走）';
    let dots = '';
    for (let i = 0; i < rev.length; i++) dots += (i < this._step ? '● ' : (i === this._step ? '◉ ' : '○ '));
    this.setData({
      big: '第' + (this._step + 1) + '段：回到锚点' + a.n + yawTxt,
      progress: '逆序第 ' + (this._step + 1) + ' / ' + rev.length + ' 段 · ' + dots,
      detail: '走到这个锚点，到了就点头或按确定键，再给下一段。',
      evt: '记录: 引导第' + (this._step + 1) + '/' + rev.length + '段'
    });
  },
  confirmTap() {
    const rev = this._reversed();
    if (!rev.length) { this.setData({ evt: 'EVT: 还没有锚点，先去落点' }); return; }
    if (this._step >= rev.length - 1) {
      const st = this._load();
      if (!st.guides) st.guides = [];
      st.guides.push({ anchors: rev.length, at: this._time(), date: new Date().toISOString().slice(0, 10) });
      this._save(st);
      this._speak('已经回到起点，引导完成。');
      this.setData({ evt: '记录: 引导完成 ' + rev.length + '段' });
      this._step = 0;
    } else {
      this._step++;
      this._speak('下一段。');
    }
    this._recompute();
  },
  nextTap() { const rev = this._reversed(); if (!rev.length) return; this._step = Math.min(rev.length - 1, this._step + 1); this._recompute(); },
  prevTap() { if (this._step > 0) this._step--; this._recompute(); },
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
    if (g === 'nod') this.confirmTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.confirmTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="stage">
      <div class="big">{{ big }}</div>
    </div>
    <div class="progress">{{ progress }}</div>
    <div class="detail">{{ detail }}</div>
    <div class="btnrow">
      <button class="gbtn main" bindtap="confirmTap">到了，下一段</button>
      <button class="gbtn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 14px 16px; box-sizing: border-box; position: relative; }
.stage { margin-top: 30px; background-color: #0d3d17; border: 3px solid #40ff5e; padding: 34px 18px; text-align: center; }
.big { color: #7dff9e; font-size: 24px; font-weight: bold; line-height: 34px; }
.progress { color: #40ff5e; font-size: 13px; margin-top: 16px; text-align: center; white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 10px; text-align: center; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 16px; }
.gbtn { flex: 1; margin-right: 10px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 15px; padding: 9px 0; text-align: center; }
.btnrow .gbtn:last-child { margin-right: 0; }
.gbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 330px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
