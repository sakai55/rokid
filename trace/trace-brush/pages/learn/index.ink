<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 学字页（描红主页）：中央范字按 strokes 路径逐笔渲染——
// 当前笔 #7dff9e 最亮、已学笔 #40ff5e、未学笔暗绿；右侧步骤栏给
// 本笔要点，TTS 同步念。路径填充走不通时退 medians 折线（粗描边）。
const TMP = 'trace.brush.tmp';
const ACTS = ['上一笔', '下一笔', '念要点', '写完去验收', '字义笔法', '返回 BACK'];
const S = 200, OX = 4, OY = 4;

export default {
  data: {
    status: '学字：一笔一笔看清，再在纸上跟写',
    headLine: '',
    stepLine: '',
    tipLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 1; this._step = 0; this._useMedians = false;
    const t = loadKey(TMP, { char: CHARS[0].char });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    this._render(true);
  },
  onShow() { this._render(false); },
  _render(speakTip) {
    const c = this._char;
    this.setData({
      headLine: c.char + ' · ' + c.pinyin + ' · ' + c.meaning,
      stepLine: '第 ' + (this._step + 1) + ' 笔 / 共 ' + c.strokes.length + ' 笔（' + c.types[this._step] + '）',
      tipLine: c.tips[this._step],
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
    if (speakTip) speak(c.tips[this._step]);
    const self = this;
    setTimeout(function () { self._draw(); }, 60);
    setTimeout(function () { self._draw(); }, 420);
  },
  _X(x) { return OX + x * S / 1024; },
  _Y(y) { return OY + (900 - y) * S / 1024; },
  _path(ctx, d) {
    // hanzi-writer-data 路径只含 M / L / C / Q / Z（绝对坐标）
    const toks = String(d).match(/[MLCQZ]|-?\d+\.?\d*/g) || [];
    let i = 0, cmd = '';
    ctx.beginPath();
    while (i < toks.length) {
      if (/[MLCQZ]/.test(toks[i])) { cmd = toks[i]; i++; if (cmd === 'Z') { ctx.closePath(); cmd = ''; } continue; }
      if (cmd === 'M') { ctx.moveTo(this._X(+toks[i]), this._Y(+toks[i + 1])); i += 2; cmd = 'L'; }
      else if (cmd === 'L') { ctx.lineTo(this._X(+toks[i]), this._Y(+toks[i + 1])); i += 2; }
      else if (cmd === 'C') { ctx.bezierCurveTo(this._X(+toks[i]), this._Y(+toks[i + 1]), this._X(+toks[i + 2]), this._Y(+toks[i + 3]), this._X(+toks[i + 4]), this._Y(+toks[i + 5])); i += 6; }
      else if (cmd === 'Q') { ctx.quadraticCurveTo(this._X(+toks[i]), this._Y(+toks[i + 1]), this._X(+toks[i + 2]), this._Y(+toks[i + 3])); i += 4; }
      else i++;
    }
  },
  _draw() {
    try {
      const ctx = wx.createCanvasContext('charCanvas');
      if (!ctx) return;
      const c = this._char;
      ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, 208, 208);
      // 米字格
      ctx.strokeStyle = 'rgba(64,255,94,0.30)'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(104, 2); ctx.lineTo(104, 206); ctx.moveTo(2, 104); ctx.lineTo(206, 104);
      ctx.moveTo(2, 2); ctx.lineTo(206, 206); ctx.moveTo(206, 2); ctx.lineTo(2, 206); ctx.stroke();
      ctx.strokeStyle = 'rgba(64,255,94,0.45)'; ctx.beginPath(); ctx.strokeRect(2, 2, 204, 204);
      for (let i = 0; i < c.strokes.length; i++) {
        const col = i < this._step ? '#40ff5e' : (i === this._step ? '#7dff9e' : 'rgba(64,255,94,0.20)');
        if (!this._useMedians) {
          try {
            this._path(ctx, c.strokes[i]);
            ctx.fillStyle = col; ctx.fill();
          } catch (e) { this._useMedians = true; }
        }
        if (this._useMedians) {
          const med = c.medians[i];
          ctx.strokeStyle = col; ctx.lineWidth = 9;
          ctx.beginPath();
          for (let j = 0; j < med.length; j++) {
            const px = this._X(med[j][0]), py = this._Y(med[j][1]);
            if (j === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
          }
          ctx.stroke();
        }
      }
      ctx.flush();
      if (this._useMedians) this.setData({ evt: 'EVT: draw via medians fallback' });
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  prevTap() { if (this._step > 0) { this._step--; this._render(true); } else this.setData({ status: '已是第一笔', evt: 'EVT: step at first' }); },
  nextTap() {
    const c = this._char;
    if (this._step < c.strokes.length - 1) { this._step++; this._render(true); }
    else { this.setData({ status: '已是最后一笔：在纸上写完整个字，再去验收', evt: 'EVT: step at last' }); speak('最后一笔，看完在纸上写完整个字，再去验收'); }
  },
  speakTap() { speak(this._char.tips[this._step]); this.setData({ evt: 'EVT: speak tip' }); },
  verifyTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  detailTap() { try { wx.navigateTo({ url: '/pages/detail/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.prevTap();
    else if (this._focus === 1) this.nextTap();
    else if (this._focus === 2) this.speakTap();
    else if (this._focus === 3) this.verifyTap();
    else if (this._focus === 4) this.detailTap();
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
    <text class="title">毛笔字描红 · 学字</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <canvas id="charCanvas" width="208" height="208" class="char-canvas"></canvas>
      <view class="rail">
        <text class="step">{{stepLine}}</text>
        <text class="tip">{{tipLine}}</text>
        <text class="rnote">当前笔最亮绿，已学笔中绿，未学笔压暗。在真纸上用真毛笔跟写这一笔，再看下一笔；整字写完去验收。</text>
      </view>
    </view>
    <view class="acts">
      <button class="act" bindtap="actTap" data-idx="0">上一笔</button>
      <button class="act hot" bindtap="actTap" data-idx="1">下一笔</button>
      <button class="act" bindtap="actTap" data-idx="2">念要点</button>
      <button class="act" bindtap="actTap" data-idx="3">写完去验收</button>
      <button class="act" bindtap="actTap" data-idx="4">字义笔法</button>
      <button class="act" bindtap="actTap" data-idx="5">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01 · 范字数据 hanzi-writer-data</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.head { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 17px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; gap: 8px; margin-top: 3px; }
.char-canvas { width: 208px; height: 208px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.4); }
.rail { display: flex; flex-direction: column; flex-grow: 1; }
.step { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 17px; }
.tip { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 17px; margin-top: 3px; }
.rnote { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 14px; margin-top: 5px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 6px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 4px 8px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
