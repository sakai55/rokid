<script def>
{
  "title": "Nichijo Origami"
}
</script>

<script setup>
import wx from 'wx';

// JP22 origami mode: hands-busy step guide.
// Three works with real step lists (8/6/7 steps). A nod (or NEXT) advances
// one step; progress is persisted after every step, finishing a work records
// it and moves to the next work.
const KEY = 'nichijoSetV1';
const WORKS = [
  { name: 'つる', steps: ['紙を三角に折る', 'もう一度三角に折る', '開いて四角の跡をつける', '角を中心に合わせる', '裏返して同じように折る', '首と尾を引き出す', 'くちばしを折る', '羽を広げて完成'] },
  { name: 'かぶと', steps: ['三角に折る', '両角を下に折る', '下の辺を上に折る', '裏返して同じように折る', '角を内側にしまう', '広げて完成'] },
  { name: 'ふうせん', steps: ['四角に折って跡をつける', '四隅を中心に合わせる', '裏返して同じように折る', '吹き口を残して折る', 'そっと息を入れる', '角を整える', '膨らませて完成'] }
];

export default {
  data: { status: '', work: '', stepBig: '', stepText: '', bar: '', evt: 'EVT: ready' },

  onLoad() {
    const st = this._load();
    const og = st.origami || { done: [], work: 0, step: 0 };
    this._work = og.work || 0; this._step = og.step || 0;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { proof: null, laundry: [], origami: { done: [], work: 0, step: 0 } }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _persist() {
    const st = this._load();
    st.origami = st.origami || { done: [], work: 0, step: 0 };
    st.origami.work = this._work; st.origami.step = this._step;
    this._save(st);
  },

  _recompute() {
    const w = WORKS[this._work];
    let bar = '';
    for (let i = 0; i < w.steps.length; i++) bar += (i < this._step ? '●' : (i === this._step ? '◉' : '○'));
    this.setData({
      status: 'おりがみ: 両手がふさがっていても、うなずきで進めます',
      work: '作品 ' + (this._work + 1) + ' / 3 ・ ' + w.name,
      stepBig: '手順 ' + (this._step + 1) + ' / ' + w.steps.length,
      stepText: w.steps[this._step],
      bar: bar
    });
  },
  nextTap() {
    const w = WORKS[this._work];
    if (this._step + 1 >= w.steps.length) {
      const st = this._load();
      st.origami = st.origami || { done: [], work: 0, step: 0 };
      st.origami.done = st.origami.done || [];
      if (st.origami.done.indexOf(w.name) < 0) st.origami.done.push(w.name);
      this._work = (this._work + 1) % WORKS.length; this._step = 0;
      st.origami.work = this._work; st.origami.step = 0;
      this._save(st);
      this._speak(w.name + 'が完成しました。記録しました。');
      this.setData({ evt: 'EVT: work finished - ' + w.name });
      this._recompute();
      return;
    }
    this._step++;
    this._persist();
    this._speak(WORKS[this._work].steps[this._step]);
    this._recompute();
  },
  prevTap() { if (this._step > 0) { this._step--; this._persist(); } this._recompute(); },
  workTap() { this._work = (this._work + 1) % WORKS.length; this._step = 0; this._persist(); this._recompute(); },
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
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Origami Steps</div>
    <div class="status">{{ status }}</div>
    <div class="work">{{ work }}</div>
    <div class="stepcard">
      <div class="stepbig">{{ stepBig }}</div>
      <div class="steptext">{{ stepText }}</div>
    </div>
    <div class="bar">{{ bar }}</div>
    <div class="btnrow">
      <button class="fold main" bindtap="nextTap">NEXT</button>
      <button class="fold" bindtap="prevTap">PREV</button>
      <button class="fold" bindtap="workTap">WORK</button>
      <button class="fold" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.work { color: #7dff9e; font-size: 14px; margin-top: 10px; font-family: monospace; }
.stepcard { margin-top: 10px; border: 1px solid rgba(64,255,94,0.7); background-color: #061a0b; padding: 16px 14px; transform: rotate(0deg); }
.stepbig { color: #7dff9e; font-size: 15px; font-family: monospace; }
.steptext { color: #7dff9e; font-size: 24px; font-weight: bold; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.bar { color: #40ff5e; font-size: 16px; letter-spacing: 3px; margin-top: 12px; font-family: monospace; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.fold { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 13px; padding: 7px 0; text-align: center; border-radius: 2px 12px 2px 12px; }
.btnrow .fold:last-child { margin-right: 0; }
.fold.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
