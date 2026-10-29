<script def>
{"title": "Trace Sketch"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { PICS } from '../../pics.js';

// TR06 描红主页：中央范本按 pics.js 的分笔点列逐笔绘制——当前笔
// 最亮绿粗线、已画笔中绿、未画笔暗绿细线；右侧给本笔名与要点，
// TTS 同步念。整幅在真纸上画完后去验收页拍照对形（整幅验，不逐笔拍）。
const TMP = 'trace.sketch.tmp';
const ACTS = ['上一笔', '下一笔', '念要点', '画完去验收', 'BACK'];

export default {
  data: {
    status: '一笔一笔看清，在纸上跟画这一笔',
    headLine: '',
    stepLine: '',
    tipLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 1; this._step = 0;
    const t = loadKey(TMP, { pic: PICS[0].id, review: false });
    this._pic = PICS.filter(function (x) { return x.id === t.pic; })[0] || PICS[0];
    this._render(true);
  },
  onShow() { this._render(false); },
  _render(speakTip) {
    const pic = this._pic;
    const s = pic.strokes[this._step];
    this.setData({
      headLine: pic.name + '（共 ' + pic.strokes.length + ' 笔）',
      stepLine: '第 ' + (this._step + 1) + ' 笔 · ' + s.n + (s.closed ? '（闭合图形，收尾要合上口）' : ''),
      tipLine: s.tip,
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
    if (speakTip) speak(s.n + '。' + s.tip);
    const self = this;
    setTimeout(function () { self._draw(); }, 60);
    setTimeout(function () { self._draw(); }, 420);
  },
  _draw() {
    try {
      const ctx = wx.createCanvasContext('picCanvas');
      if (!ctx) return;
      ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, 208, 208);
      ctx.strokeStyle = 'rgba(64,255,94,0.30)'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(4, 104); ctx.lineTo(204, 104); ctx.stroke();
      ctx.beginPath(); ctx.strokeRect(3, 3, 202, 202);
      const pic = this._pic;
      for (let i = 0; i < pic.strokes.length; i++) {
        const st = pic.strokes[i];
        if (i < this._step) { ctx.strokeStyle = '#40ff5e'; ctx.lineWidth = 3; }
        else if (i === this._step) { ctx.strokeStyle = '#7dff9e'; ctx.lineWidth = 5; }
        else { ctx.strokeStyle = 'rgba(64,255,94,0.28)'; ctx.lineWidth = 1; }
        ctx.beginPath();
        for (let j = 0; j < st.pts.length; j++) {
          const x = 4 + st.pts[j][0], y = 4 + st.pts[j][1];
          if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        if (st.closed) ctx.closePath();
        ctx.stroke();
      }
      ctx.flush();
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  prevTap() { if (this._step > 0) { this._step--; this._render(true); } else this.setData({ status: '已是第一笔', evt: 'EVT: step at first' }); },
  nextTap() {
    if (this._step < this._pic.strokes.length - 1) { this._step++; this._render(true); }
    else { this.setData({ status: '已是最后一笔：在纸上画完整幅，去验收', evt: 'EVT: step at last' }); speak('最后一笔，画完去验收'); }
  },
  speakTap() { const s = this._pic.strokes[this._step]; speak(s.n + '。' + s.tip); this.setData({ evt: 'EVT: speak tip' }); },
  checkTap() { try { wx.navigateTo({ url: '/pages/check/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.prevTap();
    else if (this._focus === 1) this.nextTap();
    else if (this._focus === 2) this.speakTap();
    else if (this._focus === 3) this.checkTap();
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(false); },
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
    <text class="title">简笔画描红 · 描红</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <canvas id="picCanvas" width="208" height="208" class="pic-canvas"></canvas>
      <view class="rail">
        <text class="step">{{stepLine}}</text>
        <text class="tip">{{tipLine}}</text>
        <text class="rnote">当前笔最亮粗线，已画笔中绿，未画笔压暗。在手账纸上跟画这一笔，再看下一笔；整幅画完去验收。</text>
      </view>
    </view>
    <view class="acts">
      <button class="pen" bindtap="actTap" data-idx="0">上一笔</button>
      <button class="pen hot" bindtap="actTap" data-idx="1">下一笔</button>
      <button class="pen" bindtap="actTap" data-idx="2">念要点</button>
      <button class="pen" bindtap="actTap" data-idx="3">画完去验收</button>
      <button class="pen" bindtap="actTap" data-idx="4">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR06 · 线条为本系列自绘坐标数据</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.head { color: #7dff9e; font-size: 13px; line-height: 17px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; margin-top: 4px; }
.pic-canvas { width: 208px; height: 208px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.4); }
.rail { display: flex; flex-direction: column; margin-left: 8px; width: 218px; }
.step { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; }
.tip { color: rgba(125,255,158,0.92); font-size: 12px; line-height: 17px; margin-top: 3px; }
.rnote { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 14px; margin-top: 4px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 12px; margin-top: 6px; }
.pen { color: #7dff9e; background-color: #04140a; border: none; border-bottom: 2px solid rgba(125,255,158,0.6); padding: 4px 6px; font-size: 12px; text-align: left; }
.pen.hot { background-color: #0a2413; border-bottom: 3px solid #7dff9e; font-weight: 500; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
