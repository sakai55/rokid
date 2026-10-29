<script def>
{"title": "Trace Origami"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { WORKS } from '../../works.js';

// TR04 折叠主页（描红主页）：中央 Canvas 自绘本步折形——纸面轮廓暗绿
// 填充、被折纸片中绿、本步折线最亮绿粗线；右侧步骤栏给折法名、本步
// 要点与前后步。步进由进度键的 step 决定：只有验形页放行才 +1，本页
// 的「回看上一步」只是看，不改进度。TTS 同步念本步要点。
const PROG = 'trace.trace-origami.v1';
const TMP = 'trace.origami.tmp';
const ACTS = ['折好了，去验形', '念要点', '回看上一步', '换作品', 'BACK'];

export default {
  data: {
    status: '照着范本折这一步，折完举到眼前验形',
    headLine: '',
    stepLine: '',
    tipLine: '',
    railLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._peek = -1;
    const t = loadKey(TMP, { work: WORKS[0].id });
    this._work = WORKS.filter(function (w) { return w.id === t.work; })[0] || WORKS[0];
    this._render(true);
  },
  onShow() { this._peek = -1; this._render(false); },
  _step() {
    const p = loadKey(PROG, { works: {}, days: {}, lastWork: '' });
    const rec = (p.works || {})[this._work.id] || { step: 0 };
    return Math.min(rec.step || 0, this._work.steps.length);
  },
  _viewStep() { return this._peek >= 0 ? this._peek : this._step(); },
  _render(speakTip) {
    const w = this._work;
    const cur = this._step();
    const vs = this._viewStep();
    if (cur >= w.steps.length) {
      this.setData({
        headLine: w.name + ' · 全部 ' + w.steps.length + ' 步已验完',
        stepLine: '去成品结算页收尾',
        tipLine: '每一步都过了验形，去结算这件作品',
        railLine: '', focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
      });
      const self0 = this; setTimeout(function () { self0._draw(-1); }, 60);
      return;
    }
    const s = w.steps[vs];
    const prev = vs > 0 ? w.steps[vs - 1].t : '（起步）';
    const next = vs < w.steps.length - 1 ? w.steps[vs + 1].t : '（最后一步）';
    this.setData({
      headLine: w.name + '（' + w.paper + '）',
      stepLine: '第 ' + (vs + 1) + ' 步 / 共 ' + w.steps.length + ' 步 · ' + s.t + (this._peek >= 0 ? '（回看中，不是当前步）' : ''),
      tipLine: s.tip,
      railLine: '上一步：' + prev + ' → 下一步：' + next,
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行，点头=去验形）'
    });
    if (speakTip && this._peek < 0) speak(s.t + '。' + s.tip);
    const self = this;
    setTimeout(function () { self._draw(vs); }, 60);
    setTimeout(function () { self._draw(vs); }, 420);
  },
  _draw(vs) {
    try {
      const ctx = wx.createCanvasContext('foldCanvas');
      if (!ctx) return;
      ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, 208, 208);
      ctx.strokeStyle = 'rgba(64,255,94,0.35)'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.strokeRect(3, 3, 202, 202);
      if (vs < 0 || vs >= this._work.steps.length) {
        ctx.fillStyle = '#40ff5e'; ctx.fillRect(84, 84, 40, 40);
        ctx.flush(); return;
      }
      const s = this._work.steps[vs];
      const P = function (pts) {
        ctx.beginPath();
        for (let i = 0; i < pts.length; i++) {
          const x = 4 + pts[i][0], y = 4 + pts[i][1];
          if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.closePath();
      };
      P(s.poly); ctx.fillStyle = 'rgba(64,255,94,0.22)'; ctx.fill();
      ctx.strokeStyle = 'rgba(125,255,158,0.8)'; ctx.lineWidth = 1; ctx.stroke();
      if (s.flap) {
        P(s.flap); ctx.fillStyle = 'rgba(64,255,94,0.5)'; ctx.fill();
        ctx.strokeStyle = 'rgba(125,255,158,0.9)'; ctx.stroke();
      }
      if (s.crease) {
        ctx.strokeStyle = '#7dff9e'; ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(4 + s.crease[0][0], 4 + s.crease[0][1]);
        ctx.lineTo(4 + s.crease[1][0], 4 + s.crease[1][1]);
        ctx.stroke();
        ctx.fillStyle = '#7dff9e';
        ctx.beginPath(); ctx.arc(4 + (s.crease[0][0] + s.crease[1][0]) / 2, 4 + (s.crease[0][1] + s.crease[1][1]) / 2, 4, 0, 2 * Math.PI); ctx.fill();
      }
      ctx.flush();
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  checkTap() {
    if (this._peek >= 0) { this._peek = -1; this._render(false); return; }
    if (this._step() >= this._work.steps.length) { try { wx.navigateTo({ url: '/pages/finish/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } return; }
    try { wx.navigateTo({ url: '/pages/check/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  speakTap() { const vs = this._viewStep(); const s = this._work.steps[Math.min(vs, this._work.steps.length - 1)]; if (s) speak(s.t + '。' + s.tip); this.setData({ evt: 'EVT: speak tip' }); },
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
    <text class="title">折纸描红 · 折叠</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <canvas id="foldCanvas" width="208" height="208" class="fold-canvas"></canvas>
      <view class="rail">
        <text class="step">{{stepLine}}</text>
        <text class="tip">{{tipLine}}</text>
        <text class="rnote">图里暗绿是纸面、中绿是这步要折动的纸片、最亮粗线是本步折线。折完把纸举到眼前，去验形。</text>
      </view>
    </view>
    <text class="rail2">{{railLine}}</text>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">去验形</button>
      <button class="tag" bindtap="actTap" data-idx="1">念要点</button>
      <button class="tag" bindtap="actTap" data-idx="2">回看上一步</button>
      <button class="tag" bindtap="actTap" data-idx="3">换作品</button>
      <button class="tag" bindtap="actTap" data-idx="4">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR04 · 范本为本系列自绘折形示意图</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.head { color: #7dff9e; font-size: 13px; line-height: 17px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; margin-top: 4px; }
.fold-canvas { width: 208px; height: 208px; background-color: #03130a; border: 1px dashed rgba(64,255,94,0.45); }
.rail { display: flex; flex-direction: column; margin-left: 8px; width: 218px; }
.step { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; }
.tip { color: rgba(125,255,158,0.92); font-size: 12px; line-height: 17px; margin-top: 3px; }
.rnote { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 14px; margin-top: 4px; }
.rail2 { color: rgba(64,255,94,0.6); font-size: 10px; line-height: 13px; margin-top: 3px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.tag { color: #7dff9e; background-color: #03130a; border: 1px solid rgba(125,255,158,0.55); border-left: 7px solid #40ff5e; border-radius: 2px; padding: 4px 8px 4px 6px; font-size: 11px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border-left: 7px solid #7dff9e; font-weight: 500; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
