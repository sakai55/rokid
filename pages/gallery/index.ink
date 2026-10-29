<script def>
{"title": "Trace Plating"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { PLATINGS } from '../../platings.js';

// TR07 构图集：8 套构图分页陈列（每套标步数、难度、完成次数、摆到第几步），
// 选中写入 TMP 并进练习页；摆到一半的构图从断点续练，不重头。
const PROG = 'trace.trace-plating.v1';
const TMP = 'trace.plating.tmp';
const PER = 4;

export default {
  data: {
    status: '构图集：选一套开摆，半成品会续上',
    rows: ['', '', '', ''],
    pageLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._page = 0; this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _items() { const base = this._page * PER; return PLATINGS.slice(base, base + PER); },
  _ctrls() { return this._items().map(function (w) { return '摆 ' + w.name; }).concat(['上一页', '下一页', 'BACK']); },
  _render() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const items = this._items();
    const rows = ['', '', '', ''];
    for (let i = 0; i < items.length; i++) {
      const w = items[i];
      const rec = (p.done || {})[w.id] || { step: 0, count: 0 };
      let state = '没摆过';
      if ((rec.step || 0) > 0 && (rec.step || 0) < w.steps.length) state = '摆到第 ' + (rec.step + 1) + ' 步';
      else if ((rec.step || 0) >= w.steps.length) state = '待结算';
      rows[i] = w.name + ' · ' + w.level + ' · ' + w.steps.length + ' 步 · 完成 ' + (rec.count || 0) + ' 次 · ' + state;
    }
    const ctrls = this._ctrls();
    if (this._focus >= ctrls.length) this._focus = 0;
    this.setData({
      rows: rows,
      pageLine: '第 ' + (this._page + 1) + ' 页 / 共 ' + Math.ceil(PLATINGS.length / PER) + ' 页（' + PLATINGS.length + ' 套构图）',
      focusLine: '焦点：' + ctrls[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _pick(i) {
    const items = this._items();
    if (i < 0 || i >= items.length) return;
    saveKey(TMP, { plating: items[i].id });
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    p.lastItem = items[i].id;
    saveKey(PROG, p);
    try { wx.navigateTo({ url: '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  doAct() {
    const n = this._items().length;
    if (this._focus < n) this._pick(this._focus);
    else if (this._focus === n) { if (this._page > 0) { this._page--; this._focus = 0; this._render(); } }
    else if (this._focus === n + 1) { if (this._page < Math.ceil(PLATINGS.length / PER) - 1) { this._page++; this._focus = 0; this._render(); } }
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
    <text class="title">摆盘描红 · 构图集</text>
    <text class="status">{{status}}</text>
    <view class="shelf">
      <button class="row" bindtap="rowTap" data-idx="0">{{rows[0]}}</button>
      <button class="row" bindtap="rowTap" data-idx="1">{{rows[1]}}</button>
      <button class="row" bindtap="rowTap" data-idx="2">{{rows[2]}}</button>
      <button class="row" bindtap="rowTap" data-idx="3">{{rows[3]}}</button>
    </view>
    <view class="acts">
      <button class="tag" bindtap="actTap" data-idx="4">上一页</button>
      <button class="tag" bindtap="actTap" data-idx="5">下一页</button>
      <button class="tag" bindtap="actTap" data-idx="6">BACK</button>
    </view>
    <text class="line dim">{{pageLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR07</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.shelf { display: flex; flex-direction: column; gap: 5px; margin-top: 6px; }
.row { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.5); border-radius: 20px; padding: 6px 8px; font-size: 12px; text-align: left; }
.acts { display: flex; flex-direction: row; gap: 6px; margin-top: 7px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 20px; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 5px 10px; font-size: 12px; text-align: center; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
