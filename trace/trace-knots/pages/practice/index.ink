<script def>
{"title": "Trace Knots"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { KNOTS } from '../../knots.js';

// TR05 练习主页（描红主页）：中央范本区是本步绳结线条示意图的文字
// 描述（绳走向与交叉点）；右侧步骤栏给步名、本步要点、粗查清单与
// 前后步。步进由进度键的 step 决定：只有验形页放行才 +1，本页的
// 「回看上一步」只是看，不改进度。TTS 同步念本步要点。
const PROG = 'trace.trace-knots.v1';
const TMP = 'trace.knots.tmp';
const ACTS = ['打好了，去验形', '念要点', '回看上一步', '换一个结', 'BACK'];

export default {
  data: {
    status: '照着范本打这一步，打完举到眼前验形',
    headLine: '',
    stepLine: '',
    tipLine: '',
    diagramLine: '',
    checksLine: '',
    railLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._peek = -1;
    const t = loadKey(TMP, { knot: KNOTS[0].id });
    this._knot = KNOTS.filter(function (w) { return w.id === t.knot; })[0] || KNOTS[0];
    this._render(true);
  },
  onShow() { this._peek = -1; this._render(false); },
  _step() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const rec = (p.done || {})[this._knot.id] || { step: 0 };
    return Math.min(rec.step || 0, this._knot.steps.length);
  },
  _viewStep() { return this._peek >= 0 ? this._peek : this._step(); },
  _render(speakTip) {
    const w = this._knot;
    const cur = this._step();
    const vs = this._viewStep();
    if (cur >= w.steps.length) {
      this.setData({
        headLine: w.name + ' · 全部 ' + w.steps.length + ' 步已验完',
        stepLine: '去结算页收尾',
        tipLine: '每一步都过了验形，去结算这个结',
        diagramLine: '',
        checksLine: '',
        railLine: '', focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
      });
      return;
    }
    const s = w.steps[vs];
    const prev = vs > 0 ? w.steps[vs - 1].t : '（起步）';
    const next = vs < w.steps.length - 1 ? w.steps[vs + 1].t : '（最后一步）';
    this.setData({
      headLine: w.name + '（' + w.use + ' · ' + w.rope + '）',
      stepLine: '第 ' + (vs + 1) + ' 步 / 共 ' + w.steps.length + ' 步 · ' + s.t + (this._peek >= 0 ? '（回看中，不是当前步）' : ''),
      tipLine: s.tip,
      diagramLine: '范本：' + s.diagram,
      checksLine: '本步粗查：' + s.checks.join('；'),
      railLine: '上一步：' + prev + ' → 下一步：' + next,
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行，点头=去验形）'
    });
    if (speakTip && this._peek < 0) speak(s.t + '。' + s.tip);
  },
  checkTap() {
    if (this._peek >= 0) { this._peek = -1; this._render(false); return; }
    if (this._step() >= this._knot.steps.length) { try { wx.navigateTo({ url: '/pages/finish/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } return; }
    try { wx.navigateTo({ url: '/pages/check/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  speakTap() { const vs = this._viewStep(); const s = this._knot.steps[Math.min(vs, this._knot.steps.length - 1)]; if (s) speak(s.t + '。' + s.tip); this.setData({ evt: 'EVT: speak tip' }); },
  peekTap() {
    if (this._peek >= 0) { this._peek = -1; this.setData({ evt: 'EVT: peek off' }); }
    else {
      const cur = this._step();
      if (cur <= 0) { this.setData({ status: '还没有上一步可回看', evt: 'EVT: peek none' }); return; }
      this._peek = cur - 1; this.setData({ evt: 'EVT: peek step ' + cur });
    }
    this._render(false);
  },
  galleryTap() { try { wx.navigateTo({ url: '/pages/gallery/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.checkTap();
    else if (this._focus === 1) this.speakTap();
    else if (this._focus === 2) this.peekTap();
    else if (this._focus === 3) this.galleryTap();
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(false); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.checkTap(); },
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
    <text class="title">绳结描红 · 练习</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <view class="model">
        <text class="diagram">{{diagramLine}}</text>
        <text class="rnote">范本为本系列自绘线条示意图的文字描述：绳走向与交叉点为准，不是照片。打完把绳举到眼前，去验形。</text>
      </view>
      <view class="rail">
        <text class="step">{{stepLine}}</text>
        <text class="tip">{{tipLine}}</text>
        <text class="checks">{{checksLine}}</text>
      </view>
    </view>
    <text class="rail2">{{railLine}}</text>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">去验形</button>
      <button class="tag" bindtap="actTap" data-idx="1">念要点</button>
      <button class="tag" bindtap="actTap" data-idx="2">回看上一步</button>
      <button class="tag" bindtap="actTap" data-idx="3">换一个结</button>
      <button class="tag" bindtap="actTap" data-idx="4">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR05 · 范本为本系列自绘线条示意图</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.head { color: #7dff9e; font-size: 13px; line-height: 17px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; margin-top: 4px; }
.model { width: 208px; background-color: #03130a; border: 2px solid rgba(64,255,94,0.45); border-radius: 12px; padding: 6px; }
.diagram { color: #7dff9e; font-size: 12px; line-height: 17px; }
.rnote { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 14px; margin-top: 4px; }
.rail { display: flex; flex-direction: column; margin-left: 8px; width: 218px; }
.step { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; }
.tip { color: rgba(125,255,158,0.92); font-size: 12px; line-height: 17px; margin-top: 3px; }
.checks { color: rgba(64,255,94,0.7); font-size: 11px; line-height: 15px; margin-top: 3px; }
.rail2 { color: rgba(64,255,94,0.6); font-size: 10px; line-height: 13px; margin-top: 3px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 12px; padding: 4px 8px; font-size: 11px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
