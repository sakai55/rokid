<script def>
{"title": "Trace Plating"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { PLATINGS } from '../../platings.js';

// TR07 结算页：一套构图的收尾——已对步数、本轮本人改判与跳过
// 次数、完成记录。全部步对完可直接结算；没对完也可由本人改判结
// 算（记 partial 与一次 overrides），结算后本套步数清零、下次可重摆。
const PROG = 'trace.trace-plating.v1';
const TMP = 'trace.plating.tmp';
const ACTS = ['结算这套构图', '本人算完成（改判结算）', '换一套（构图集）', '看进度'];

export default {
  data: {
    status: '结算：摆完一套，记上一笔',
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
    const t = loadKey(TMP, { plating: PLATINGS[0].id });
    this._plating = PLATINGS.filter(function (w) { return w.id === t.plating; })[0] || PLATINGS[0];
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const w = this._plating;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const rec = (p.done || {})[w.id] || { count: 0, step: 0, overrides: 0 };
    this.setData({
      workLine: w.name + '（' + w.level + ' · ' + w.steps.length + ' 步）已完成 ' + (rec.count || 0) + ' 次',
      stepsLine: '本轮已对 ' + Math.min(rec.step || 0, w.steps.length) + ' / ' + w.steps.length + ' 步' + ((rec.step || 0) >= w.steps.length ? '——全部对完，可直接结算' : '——还没对完，结算是本人改判'),
      overLine: '本轮本人改判 ' + (rec.runOverrides || 0) + ' 次 · 累计改判 ' + (rec.overrides || 0) + ' 次 · 累计跳过 ' + (rec.skips || 0) + ' 次',
      lastLine: rec.lastAt ? ('上次完成：' + String(rec.lastAt).slice(0, 10)) : '这套还没完成过',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _settle(partial) {
    const w = this._plating;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    p.done = p.done || {};
    const rec = p.done[w.id] || { count: 0, step: 0, overrides: 0 };
    if (!partial && (rec.step || 0) < w.steps.length) {
      this.setData({ status: '还没对完：要么回去摆完，要么用「本人算完成」改判结算', evt: 'EVT: settle refused - steps remain' });
      return;
    }
    if ((rec.step || 0) === 0 && !rec.lastAt) {
      this.setData({ status: '这套还没开摆，先去摆几步再来结算', evt: 'EVT: settle refused - not started' });
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
    <text class="title">摆盘描红 · 结算</text>
    <text class="status">{{status}}</text>
    <view class="plate-box">
      <text class="work">{{workLine}}</text>
      <text class="line">{{stepsLine}}</text>
      <text class="line">{{overLine}}</text>
      <text class="line dim">{{lastLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">结算这套</button>
      <button class="tag" bindtap="actTap" data-idx="1">本人算完成</button>
      <button class="tag" bindtap="actTap" data-idx="2">换一套</button>
      <button class="tag" bindtap="actTap" data-idx="3">看进度</button>
    </view>
    <text class="note">结算口径：每一步都经拍照对位后由本人算过才算「对完结算」；本人改判结算会如实记 partial，不冒充全对。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR07 · 自评描红</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.plate-box { border: 2px solid rgba(125,255,158,0.65); border-radius: 20px; background-color: #03130a; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 7px 9px; margin-top: 6px; }
.work { color: #7dff9e; font-size: 14px; font-weight: 500; line-height: 19px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 20px; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 5px 10px; font-size: 12px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
