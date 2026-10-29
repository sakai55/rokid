<script def>
{"title": "Trace Sketch"}
</script>

<script setup>
import wx from 'wx';
import { loadKey } from '../../judge.js';
import { PICS } from '../../pics.js';

// TR06 进度页：12 幅逐幅列画过次数、算过没有、复习过关与协助次数；
// 汇总已画幅数、累计次数、动手天数。手账横线账本样式。
const PROG = 'trace.trace-sketch.v1';
const ACTS = ['去图库选图', '复习抽查', '翻下一页', '返回今日页'];
const PER = 6;

export default {
  data: {
    status: '我的进度：画过哪些、复习过关没有',
    rows: ['', '', '', '', '', ''],
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._page = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    const base = this._page * PER;
    const rows = ['', '', '', '', '', ''];
    for (let i = 0; i < PER; i++) {
      const pic = PICS[base + i];
      if (!pic) break;
      const rec = (p.pics || {})[pic.id] || { count: 0 };
      rows[i] = pic.name + '：画 ' + (rec.count || 0) + ' 次' + (rec.passed ? ' · 已算过' : '') + (rec.reviewPassed ? ' · 复习过关 ' + rec.reviewPassed + ' 次' : '') + (rec.assisted ? '（含协助 ' + rec.assisted + ' 次）' : '') + (rec.overrides ? ' · 改判 ' + rec.overrides + ' 次' : '');
    }
    let drawn = 0, total = 0, rev = 0;
    Object.keys(p.pics || {}).forEach(function (k) { const r = p.pics[k]; if (r && r.count > 0) drawn++; total += (r.count || 0); rev += (r.reviewPassed || 0); });
    const days = Object.keys(p.days || {}).length;
    this.setData({
      rows: rows,
      sumLine: '汇总：已画 ' + drawn + ' / ' + PICS.length + ' 幅 · 累计 ' + total + ' 次 · 复习过关共 ' + rev + ' 次 · 动手 ' + days + ' 天（共 2 页）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  galleryTap() { try { wx.navigateTo({ url: '/pages/gallery/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  reviewTap() { try { wx.navigateTo({ url: '/pages/review/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  flipTap() { this._page = (this._page + 1) % Math.ceil(PICS.length / PER); this.setData({ evt: 'EVT: progress page ' + (this._page + 1) }); this._render(); },
  homeTap() { try { wx.navigateBack({ delta: 10 }); } catch (e) { try { wx.navigateTo({ url: '/pages/index/index' }); } catch (e2) {} } },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.galleryTap();
    else if (this._focus === 1) this.reviewTap();
    else if (this._focus === 2) this.flipTap();
    else this.homeTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">简笔画描红 · 进度</text>
    <text class="status">{{status}}</text>
    <view class="ruled">
      <text class="rline">{{rows[0]}}</text>
      <text class="rline">{{rows[1]}}</text>
      <text class="rline">{{rows[2]}}</text>
      <text class="rline">{{rows[3]}}</text>
      <text class="rline">{{rows[4]}}</text>
      <text class="rline">{{rows[5]}}</text>
    </view>
    <text class="line">{{sumLine}}</text>
    <view class="acts">
      <button class="pen hot" bindtap="actTap" data-idx="0">去图库选图</button>
      <button class="pen" bindtap="actTap" data-idx="1">复习抽查</button>
      <button class="pen" bindtap="actTap" data-idx="2">翻下一页</button>
      <button class="pen" bindtap="actTap" data-idx="3">返回今日页</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR06 · 进度键 trace.trace-sketch.v1</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.ruled { margin-top: 5px; border-top: 1px solid rgba(64,255,94,0.4); }
.rline { color: rgba(125,255,158,0.9); font-size: 11px; line-height: 16px; padding: 3px 2px; border-bottom: 1px solid rgba(64,255,94,0.35); }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 4px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 12px; margin-top: 7px; }
.pen { color: #7dff9e; background-color: #04140a; border: none; border-bottom: 2px solid rgba(125,255,158,0.6); padding: 4px 6px; font-size: 12px; text-align: left; }
.pen.hot { background-color: #0a2413; border-bottom: 3px solid #7dff9e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
