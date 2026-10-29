<script def>
{"title": "Trace Sketch"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { PICS } from '../../pics.js';

// TR06 图库：12 幅分页陈列（每幅标笔数、画过次数、有没有算过），
// 选中写入 TMP 进描红页。手账横线行样式，与折纸台的纸签行不同。
const PROG = 'trace.trace-sketch.v1';
const TMP = 'trace.sketch.tmp';
const PER = 6;

export default {
  data: {
    status: '图库：选一幅开画',
    rows: ['', '', '', '', '', ''],
    pageLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._page = 0; this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _items() { const base = this._page * PER; return PICS.slice(base, base + PER); },
  _ctrls() { return this._items().map(function (p) { return '画 ' + p.name; }).concat(['上一页', '下一页', 'BACK']); },
  _render() {
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    const items = this._items();
    const rows = ['', '', '', '', '', ''];
    for (let i = 0; i < items.length; i++) {
      const pic = items[i];
      const rec = (p.pics || {})[pic.id] || { count: 0, passed: false };
      rows[i] = pic.name + ' · ' + pic.strokes.length + ' 笔 · 画过 ' + (rec.count || 0) + ' 次' + (rec.passed ? ' · 已算过' : '');
    }
    const ctrls = this._ctrls();
    if (this._focus >= ctrls.length) this._focus = 0;
    this.setData({
      rows: rows,
      pageLine: '第 ' + (this._page + 1) + ' 页 / 共 ' + Math.ceil(PICS.length / PER) + ' 页（' + PICS.length + ' 幅）',
      focusLine: '焦点：' + ctrls[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _pick(i) {
    const items = this._items();
    if (i < 0 || i >= items.length) return;
    saveKey(TMP, { pic: items[i].id, review: false, peeked: false });
    try { wx.navigateTo({ url: '/pages/draw/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  doAct() {
    const n = this._items().length;
    if (this._focus < n) this._pick(this._focus);
    else if (this._focus === n) { if (this._page > 0) { this._page--; this._focus = 0; this._render(); } }
    else if (this._focus === n + 1) { if (this._page < Math.ceil(PICS.length / PER) - 1) { this._page++; this._focus = 0; this._render(); } }
    else { try { wx.navigateBack({}); } catch (e) {} }
  },
  rowTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._pick(idx); },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  moveTap(d) { const ctrls = this._ctrls(); this._focus = (this._focus + d + ctrls.length) % ctrls.length; this.setData({ evt: 'EVT: focus ' + ctrls[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'Backspace') { try { wx.navigateBack({}); } catch (e) {} }
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">简笔画描红 · 图库</text>
    <text class="status">{{status}}</text>
    <view class="ruled">
      <button class="prow" bindtap="rowTap" data-idx="0">{{rows[0]}}</button>
      <button class="prow" bindtap="rowTap" data-idx="1">{{rows[1]}}</button>
      <button class="prow" bindtap="rowTap" data-idx="2">{{rows[2]}}</button>
      <button class="prow" bindtap="rowTap" data-idx="3">{{rows[3]}}</button>
      <button class="prow" bindtap="rowTap" data-idx="4">{{rows[4]}}</button>
      <button class="prow" bindtap="rowTap" data-idx="5">{{rows[5]}}</button>
    </view>
    <view class="acts">
      <button class="pen" bindtap="actTap" data-idx="6">上一页</button>
      <button class="pen" bindtap="actTap" data-idx="7">下一页</button>
      <button class="pen" bindtap="actTap" data-idx="8">BACK</button>
    </view>
    <text class="line dim">{{pageLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR06</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.ruled { display: flex; flex-direction: column; margin-top: 5px; border-top: 1px solid rgba(64,255,94,0.4); }
.prow { color: rgba(125,255,158,0.92); background-color: #000000; border: none; border-bottom: 1px solid rgba(64,255,94,0.35); padding: 5px 4px; font-size: 12px; text-align: left; }
.acts { display: flex; flex-direction: row; gap: 14px; margin-top: 6px; }
.pen { color: #7dff9e; background-color: #04140a; border: none; border-bottom: 2px solid rgba(125,255,158,0.6); padding: 4px 6px; font-size: 12px; text-align: left; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
