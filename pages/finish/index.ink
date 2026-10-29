<script def>
{"title": "Trace Knots"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { KNOTS } from '../../knots.js';

// TR05 结算页：一个结的收尾——已验步数、本轮本人改判次数、完成
// 记录。全部步验完可直接结算；没验完也可由本人改判结算（记
// partial 与一次 overrides），结算后本结步数清零、下次可重打。
const PROG = 'trace.trace-knots.v1';
const TMP = 'trace.knots.tmp';
const ACTS = ['结算这个结', '本人算完成（改判结算）', '换一个（结集）', '看进度'];

export default {
  data: {
    status: '结算：打完一个结，记上一笔',
    workLine: '',
    stepsLine: '',
    overLine: '',
    lastLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0;
    const t = loadKey(TMP, { knot: KNOTS[0].id });
    this._knot = KNOTS.filter(function (w) { return w.id === t.knot; })[0] || KNOTS[0];
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const w = this._knot;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const rec = (p.done || {})[w.id] || { count: 0, step: 0, overrides: 0 };
    this.setData({
      workLine: w.name + '（' + w.level + ' · ' + w.steps.length + ' 步）已完成 ' + (rec.count || 0) + ' 次',
      stepsLine: '本轮已验 ' + Math.min(rec.step || 0, w.steps.length) + ' / ' + w.steps.length + ' 步' + ((rec.step || 0) >= w.steps.length ? '——全部验完，可直接结算' : '——还没验完，结算是本人改判'),
      overLine: '本轮本人改判 ' + (rec.runOverrides || 0) + ' 次 · 累计改判 ' + (rec.overrides || 0) + ' 次',
      lastLine: rec.lastAt ? ('上次完成：' + String(rec.lastAt).slice(0, 10)) : '这个结还没完成过',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _settle(partial) {
    const w = this._knot;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    p.done = p.done || {};
    const rec = p.done[w.id] || { count: 0, step: 0, overrides: 0 };
    if (!partial && (rec.step || 0) < w.steps.length) {
      this.setData({ status: '还没验完：要么回去打完，要么用「本人算完成」改判结算', evt: 'EVT: settle refused - steps remain' });
      return;
    }
    if ((rec.step || 0) === 0 && !rec.lastAt) {
      this.setData({ status: '这个结还没开打，先去打几步再来结算', evt: 'EVT: settle refused - not started' });
      return;
    }
    rec.count = (rec.count || 0) + 1;
    if (partial) { rec.overrides = (rec.overrides || 0) + 1; rec.partial = (rec.partial || 0) + 1; }
    rec.step = 0;
    rec.runOverrides = 0;
    rec.lastAt = new Date().toISOString();
    p.done[w.id] = rec;
    p.lastItem = w.id;
    p.today = new Date().toISOString().slice(0, 10);
    if (!saveKey(PROG, p)) { this.setData({ status: '保存失败：E5001（结算没落盘）', evt: 'EVT: settle save FAIL E5001' }); return; }
    this.setData({ status: '已记：' + w.name + '完成第 ' + rec.count + ' 次' + (partial ? '（本人改判结算）' : ''), evt: 'EVT: settled ' + w.id + ' count=' + rec.count });
    speak(w.name + '，已记完成');
    this._render();
  },
  settleTap() { this._settle(false); },
  overrideTap() { this._settle(true); },
  galleryTap() { try { wx.navigateTo({ url: '/pages/gallery/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  progressTap() { try { wx.navigateTo({ url: '/pages/progress/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.settleTap();
    else if (this._focus === 1) this.overrideTap();
    else if (this._focus === 2) this.galleryTap();
    else this.progressTap();
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
    <text class="title">绳结描红 · 结算</text>
    <text class="status">{{status}}</text>
    <view class="knot-box">
      <text class="work">{{workLine}}</text>
      <text class="line">{{stepsLine}}</text>
      <text class="line">{{overLine}}</text>
      <text class="line dim">{{lastLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">结算这个结</button>
      <button class="tag" bindtap="actTap" data-idx="1">本人算完成</button>
      <button class="tag" bindtap="actTap" data-idx="2">换一个结</button>
      <button class="tag" bindtap="actTap" data-idx="3">看进度</button>
    </view>
    <text class="note">结算口径：每一步都经拍照验形放行才算「验完结算」；本人改判结算会如实记 partial，不冒充全验。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR05</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.knot-box { border: 2px solid rgba(125,255,158,0.65); border-radius: 12px; background-color: #03130a; padding: 7px 9px; margin-top: 6px; }
.work { color: #7dff9e; font-size: 14px; font-weight: 500; line-height: 19px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
