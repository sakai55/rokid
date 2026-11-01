<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, listenOnce } from '../../store.js';
import { sceneById } from '../../scenes.js';

// 选词页：焦点贯穿「预置句 + 动作」一列，Enter 执行焦点项——
// 预置句换台词、说一句现说、换大小、去取景，全程不用点按钮。
// 双人对话按对选词，也可分别给 A / B 现说。
const STORE = 'trace.trace-reality.v1';
const SESS = 'trace.reality.session';
const WIN = 5;
const SIZES = ['小', '中', '大'];
const ACTIONS = ['说一句', '说 B 句', '换大小', '去取景'];

export default {
  data: {
    status: '',
    curLine: '',
    rows: [],
    actLine: '',
    sizeLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _sess() { return loadKey(SESS, { sceneId: 'bubble', textA: '', textB: '', size: 1 }); },
  _scene() { return sceneById(this._sess().sceneId); },
  _options() {
    const sc = this._scene();
    if (sc.pairs) return sc.pairs.map(function (p) { return p[0] + ' ｜ ' + p[1]; });
    return sc.lines.slice();
  },
  _total() { return this._options().length + ACTIONS.length; },
  _render() {
    const sess = this._sess();
    const sc = this._scene();
    const opts = this._options();
    const onAction = this._focus >= opts.length;
    let start = Math.max(0, Math.min(Math.min(this._focus, opts.length - 1) - 2, opts.length - WIN));
    if (start < 0) start = 0;
    const rows = [];
    for (let i = start; i < Math.min(opts.length, start + WIN); i++) {
      rows.push({ idx: i, cls: i === this._focus ? 'row sel' : 'row', label: (i === this._focus ? '▶ ' : '· ') + opts[i] });
    }
    this.setData({
      status: sc.name + '：' + sc.desc,
      curLine: sc.pairs ? ('A：' + sess.textA + '　B：' + sess.textB) : ('当前台词：' + sess.textA),
      rows: rows,
      actLine: '动作：' + ACTIONS.map(function (a, i) { return (onAction && (i === this._focus - opts.length)) ? '▶' + a : a; }).join(' · '),
      sizeLine: '大小：' + SIZES[sess.size] + '（上下移动焦点，Enter 执行，点头=执行）'
    });
  },
  _applyFocus() {
    const sess = this._sess();
    const sc = this._scene();
    if (sc.pairs) { sess.textA = sc.pairs[this._focus][0]; sess.textB = sc.pairs[this._focus][1]; }
    else sess.textA = sc.lines[this._focus];
    saveKey(SESS, sess);
    this.setData({ evt: 'EVT: line set' });
    speak('换好了');
    this._render();
  },
  _heard(which, text) {
    const sess = this._sess();
    if (which === 'B') sess.textB = text; else sess.textA = text;
    saveKey(SESS, sess);
    const st = loadKey(STORE, { custom: [], shots: 0, size: 1, uses: {} });
    st.custom = (st.custom || []).filter(function (x) { return x !== text; });
    st.custom.unshift(text);
    st.custom = st.custom.slice(0, 20);
    saveKey(STORE, st);
    this.setData({ evt: 'EVT: heard ok' });
    speak('记下了：' + text);
    this._render();
  },
  _say(which) {
    const self = this;
    this.setData({ evt: 'EVT: listening ' + which });
    speak('说吧');
    listenOnce(
      function (t) { self._heard(which, t); },
      function (code) { self.setData({ evt: 'EVT: asr FAIL ' + code }); speak('没听清，用预置句也行'); }
    );
  },
  sayTap(e) {
    const which = (e && e.currentTarget && e.currentTarget.dataset && e.currentTarget.dataset.which) || 'A';
    this._say(which);
  },
  sizeTap() {
    const sess = this._sess();
    sess.size = ((sess.size || 1) + 1) % 3;
    saveKey(SESS, sess);
    const st = loadKey(STORE, { custom: [], shots: 0, size: 1, uses: {} });
    st.size = sess.size;
    saveKey(STORE, st);
    this.setData({ evt: 'EVT: size ' + SIZES[sess.size] });
    this._render();
  },
  frameTap() { try { wx.navigateTo({ url: '/pages/frame/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  doAct() {
    const n = this._options().length;
    if (this._focus < n) { this._applyFocus(); return; }
    const a = this._focus - n;
    if (a === 0) this._say('A');
    else if (a === 1) this._say('B');
    else if (a === 2) this.sizeTap();
    else this.frameTap();
  },
  actBtnTap(e) { const a = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.a) : NaN; if (!isNaN(a)) { this._focus = this._options().length + a; this.doAct(); } },
  rowTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) { this._focus = idx; this._applyFocus(); } },
  moveTap(d) { const n = this._total(); this._focus = (this._focus + d + n) % n; this.setData({ evt: 'EVT: focus ' + this._focus }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">现实合影 · 选台词</text>
    <text class="status">{{status}}</text>
    <text class="cur">{{curLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <text class="actline">{{actLine}}</text>
    <view class="acts">
      <button class="act hot" bindtap="actBtnTap" data-a="0">说一句</button>
      <button class="act" bindtap="actBtnTap" data-a="1">说 B 句</button>
      <button class="act" bindtap="actBtnTap" data-a="2">换大小</button>
      <button class="act hot" bindtap="actBtnTap" data-a="3">去取景</button>
      <button class="act" bindtap="backTap">BACK</button>
    </view>
    <text class="line dim">{{sizeLine}} · 说 B 句只对双人对话有用</text>
    <text class="foot">{{evt}} · {{ver}} · 现实合影</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.cur { color: #7dff9e; font-size: 13px; line-height: 18px; margin-top: 3px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; border-top: 1px solid rgba(64,255,94,0.35); }
.row { padding: 4px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.row.sel { background-color: #0a1f0e; border-left: 4px solid #40ff5e; }
.rtxt { color: #7dff9e; font-size: 14px; line-height: 19px; }
.actline { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 5px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 4px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
