<script def>
{"title": "Trace Knots"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { KNOTS } from '../../knots.js';

// TR05 进度页：8 个结逐个列完成次数、当前打到第几步、改判次数；
// 汇总完成结数、累计次数。续练入口回到上次结的断点。
const PROG = 'trace.trace-knots.v1';
const TMP = 'trace.knots.tmp';
const ACTS = ['继续上次结', '结集', '翻下一页', '返回今日页'];
const PER = 4;

export default {
  data: {
    status: '我的进度：练过哪些、打到哪了',
    rows: ['', '', '', ''],
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._page = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const base = this._page * PER;
    const rows = ['', '', '', ''];
    for (let i = 0; i < PER; i++) {
      const w = KNOTS[base + i];
      if (!w) break;
      const rec = (p.done || {})[w.id] || { count: 0, step: 0, overrides: 0 };
      let state = '未开练';
      if ((rec.step || 0) > 0 && (rec.step || 0) < w.steps.length) state = '打到第 ' + (rec.step + 1) + ' 步';
      else if ((rec.step || 0) >= w.steps.length) state = '待结算';
      else if ((rec.count || 0) > 0) state = '可重打';
      rows[i] = w.name + '：完成 ' + (rec.count || 0) + ' 次 · ' + state + ' · 改判 ' + (rec.overrides || 0) + ' 次';
    }
    let kinds = 0, total = 0, overs = 0;
    Object.keys(p.done || {}).forEach(function (k) { const r = p.done[k]; if (r && r.count > 0) kinds++; total += (r.count || 0); overs += (r.overrides || 0); });
    this.setData({
      rows: rows,
      sumLine: '汇总：完成过 ' + kinds + ' / ' + KNOTS.length + ' 个 · 累计 ' + total + ' 次 · 累计改判 ' + overs + ' 次（共 2 页，焦点选「翻下一页」看全 8 个）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  contTap() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    if (p.lastItem) saveKey(TMP, { knot: p.lastItem });
    try { wx.navigateTo({ url: '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  galleryTap() { try { wx.navigateTo({ url: '/pages/gallery/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  homeTap() { try { wx.navigateBack({ delta: 10 }); } catch (e) { try { wx.navigateTo({ url: '/pages/index/index' }); } catch (e2) {} } },
  pageFlip(d) {
    const pages = Math.ceil(KNOTS.length / PER);
    this._page = (this._page + d + pages) % pages;
    this.setData({ evt: 'EVT: progress page ' + (this._page + 1) });
    this._render();
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.contTap();
    else if (this._focus === 1) this.galleryTap();
    else if (this._focus === 2) this.pageFlip(1);
    else this.homeTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'ArrowLeft') this.pageFlip(-1);
    else if (k === 'ArrowRight') this.pageFlip(1);
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown' || k === 'ArrowLeft' || k === 'ArrowRight') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">绳结描红 · 进度</text>
    <text class="status">{{status}}</text>
    <view class="ledger">
      <text class="rowline">{{rows[0]}}</text>
      <text class="rowline">{{rows[1]}}</text>
      <text class="rowline">{{rows[2]}}</text>
      <text class="rowline">{{rows[3]}}</text>
    </view>
    <text class="line">{{sumLine}}</text>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">继续上次</button>
      <button class="tag" bindtap="actTap" data-idx="1">结集</button>
      <button class="tag" bindtap="actTap" data-idx="2">翻下一页</button>
      <button class="tag" bindtap="actTap" data-idx="3">返回今日页</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR05 · 进度键 trace.trace-knots.v1</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.ledger { border: 2px solid rgba(64,255,94,0.4); border-radius: 12px; background-color: #03130a; padding: 6px 8px; margin-top: 6px; }
.rowline { color: rgba(125,255,158,0.9); font-size: 11px; line-height: 17px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 4px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; gap: 6px; margin-top: 7px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
