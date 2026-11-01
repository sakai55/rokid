<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../store.js';

// 我的句子：语音现说过的台词都在这里，跨会话保存。
// 点一条 = 换到当前场景当台词 A；也可清空。
const STORE = 'trace.trace-reality.v1';
const SESS = 'trace.reality.session';
const WIN = 7;

export default {
  data: {
    status: '我的句子：说过的台词存这里',
    rows: [],
    emptyLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _list() { const st = loadKey(STORE, { custom: [] }); return st.custom || []; },
  _render() {
    const list = this._list();
    let start = Math.max(0, Math.min(this._focus - 3, list.length - WIN));
    if (start < 0) start = 0;
    const rows = [];
    for (let i = start; i < Math.min(list.length, start + WIN); i++) {
      rows.push({ idx: i, cls: i === this._focus ? 'row sel' : 'row', label: (i === this._focus ? '▶ ' : '· ') + list[i] });
    }
    this.setData({ rows: rows, emptyLine: list.length ? '' : '还没有存下句子。去任意场景的选词页，按「说一句」现说一句就会存进来。' });
  },
  _useFocus() {
    const list = this._list();
    if (!list.length) return;
    const sess = loadKey(SESS, { sceneId: 'bubble', textA: '', textB: '', size: 1 });
    sess.textA = list[this._focus];
    saveKey(SESS, sess);
    speak('换上了：' + sess.textA);
    try { wx.navigateTo({ url: '/pages/edit/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  clearTap() {
    const st = loadKey(STORE, { custom: [], shots: 0, size: 1, uses: {} });
    st.custom = [];
    saveKey(STORE, st);
    this._focus = 0;
    this.setData({ evt: 'EVT: cleared' });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  rowTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) { this._focus = idx; this._useFocus(); } },
  moveTap(d) { const n = Math.max(1, this._list().length); this._focus = (this._focus + d + n) % n; this.setData({ evt: 'EVT: focus line' }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this._useFocus(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this._useFocus();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">现实合影 · 我的句子</text>
    <text class="status">{{status}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{emptyLine}}</text>
    <view class="acts">
      <button class="act" bindtap="clearTap">清空</button>
      <button class="act" bindtap="backTap">BACK</button>
    </view>
    <text class="foot">{{evt}} · {{ver}} · 现实合影</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; border-top: 1px solid rgba(64,255,94,0.35); }
.row { padding: 4px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.row.sel { background-color: #0a1f0e; border-left: 4px solid #40ff5e; }
.rtxt { color: #7dff9e; font-size: 14px; line-height: 19px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 4px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
