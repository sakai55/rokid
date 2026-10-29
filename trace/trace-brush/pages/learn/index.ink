<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 学字页 v2（描红主页）：范字全屏——画布占满整页（464×252），只留
// 底部窄栏放「第 X 笔 / 共 N 笔（笔型）+ 本笔要点」与最少控件。
// 逐笔渲染沿用 strokes 路径填充（当前笔 #7dff9e、已学 #40ff5e、
// 未学压暗），填充异常退 medians 折线。每笔另按 medians 数据叠加：
// 起笔点旁的笔顺数字（小圆圈底 + 序号，同明暗规则）与末段方向箭头
// （最后两点定方向，当前笔更大更亮）。数字 / 箭头与笔画共用同一
// 坐标变换（1024 系 → 画布），严丝合缝对齐。
const TMP = 'trace.brush.tmp';
const ACTS = ['上一笔', '下一笔', '念要点', '写完去验收', '返回 BACK'];
const W = 464, H = 252, S = 248, OX = 108, OY = 10;

export default {
  data: {
    status: '学字：一笔一笔看清，再在纸上跟写',
    barLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.1.0'
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
      barLine: c.char + '（' + c.pinyin + '）第 ' + (this._step + 1) + ' 笔 / 共 ' + c.strokes.length + ' 笔（' + c.types[this._step] + '）：' + c.tips[this._step],
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行，点头=执行）'
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
  _arrow(ctx, med, cur, col) {
    // 末段箭头：最后两点定方向，箭头头部落在笔末端、沿方向略出头
    if (!med || med.length < 2) return;
    const e = med[med.length - 1], p = med[med.length - 2];
    let dx = this._X(e[0]) - this._X(p[0]), dy = this._Y(e[1]) - this._Y(p[1]);
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len < 0.5) return;
    dx /= len; dy /= len;
    const L = cur ? 15 : 11;
    const tx = this._X(e[0]) + dx * 3, ty = this._Y(e[1]) + dy * 3;
    const bx = tx - dx * L, by = ty - dy * L;
    const px = -dy, py = dx, hw = L * 0.48;
    ctx.strokeStyle = col; ctx.lineWidth = cur ? 2.6 : 2;
    ctx.beginPath();
    ctx.moveTo(bx - dx * 2, by - dy * 2); ctx.lineTo(tx, ty);
    ctx.moveTo(tx, ty); ctx.lineTo(bx + px * hw, by + py * hw);
    ctx.moveTo(tx, ty); ctx.lineTo(bx - px * hw, by - py * hw);
    ctx.stroke();
  },
  _badge(ctx, med, num, state) {
    // 笔顺数字：起笔点（medians[0]）旁的小圆圈 + 序号，向字心反方向偏移避免压住起笔
    if (!med || !med.length) return;
    let bx = this._X(med[0][0]), by = this._Y(med[0][1]);
    let vx = bx - W / 2, vy = by - H / 2;
    const vl = Math.sqrt(vx * vx + vy * vy);
    if (vl > 1) { bx += vx / vl * 15; by += vy / vl * 15; }
    else { bx -= 15; by -= 15; }
    bx = Math.max(12, Math.min(W - 12, bx)); by = Math.max(12, Math.min(H - 12, by));
    const r = state === 1 ? 11 : 9.5;
    ctx.beginPath(); ctx.arc(bx, by, r, 0, Math.PI * 2);
    if (state === 1) { ctx.fillStyle = '#7dff9e'; ctx.fill(); ctx.fillStyle = '#04240d'; }
    else if (state < 1) { ctx.fillStyle = 'rgba(64,255,94,0.75)'; ctx.fill(); ctx.fillStyle = '#04240d'; }
    else { ctx.fillStyle = 'rgba(4,20,10,0.92)'; ctx.fill(); ctx.strokeStyle = 'rgba(64,255,94,0.45)'; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(bx, by, r, 0, Math.PI * 2); ctx.stroke(); ctx.fillStyle = 'rgba(64,255,94,0.60)'; }
    ctx.font = (state === 1 ? 'bold ' : '') + '11px sans-serif';
    ctx.fillText(String(num), bx - 3.2, by + 3.8);
  },
  _draw() {
    try {
      const ctx = wx.createCanvasContext('charCanvas');
      if (!ctx) return;
      const c = this._char;
      ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, W, H);
      // 米字格（全幅）
      ctx.strokeStyle = 'rgba(64,255,94,0.22)'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(W / 2, 3); ctx.lineTo(W / 2, H - 3); ctx.moveTo(3, H / 2); ctx.lineTo(W - 3, H / 2);
      ctx.moveTo(3, 3); ctx.lineTo(W - 3, H - 3); ctx.moveTo(W - 3, 3); ctx.lineTo(3, H - 3); ctx.stroke();
      ctx.strokeStyle = 'rgba(64,255,94,0.40)'; ctx.beginPath(); ctx.strokeRect(2, 2, W - 4, H - 4);
      const cols = ['#40ff5e', '#7dff9e', 'rgba(64,255,94,0.20)'];
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        const col = cols[state];
        if (!this._useMedians) {
          try {
            this._path(ctx, c.strokes[i]);
            ctx.fillStyle = col; ctx.fill();
          } catch (e) { this._useMedians = true; }
        }
        if (this._useMedians) {
          const med = c.medians[i];
          ctx.strokeStyle = col; ctx.lineWidth = 11;
          ctx.beginPath();
          for (let j = 0; j < med.length; j++) {
            const px = this._X(med[j][0]), py = this._Y(med[j][1]);
            if (j === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
          }
          ctx.stroke();
        }
      }
      // 箭头层 + 数字层（与笔画同一变换；数字最后画，保证可读）
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        const acol = state === 1 ? '#7dff9e' : (state === 0 ? 'rgba(64,255,94,0.85)' : 'rgba(64,255,94,0.35)');
        this._arrow(ctx, c.medians[i], state === 1, acol);
      }
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        this._badge(ctx, c.medians[i], i + 1, state);
      }
      ctx.flush();
      if (this._useMedians) this.setData({ evt: 'EVT: draw via medians fallback' });
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  prevTap() { if (this._step > 0) { this._step--; this._render(true); } else { this.setData({ status: '已是第一笔', evt: 'EVT: step at first' }); speak('已是第一笔'); } },
  nextTap() {
    const c = this._char;
    if (this._step < c.strokes.length - 1) { this._step++; this._render(true); }
    else { this.setData({ status: '已是最后一笔：在纸上写完整个字，再去验收', evt: 'EVT: step at last' }); speak('最后一笔，看完在纸上写完整个字，再去验收'); }
  },
  speakTap() { speak(this._char.tips[this._step]); this.setData({ evt: 'EVT: speak tip' }); },
  verifyTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.prevTap();
    else if (this._focus === 1) this.nextTap();
    else if (this._focus === 2) this.speakTap();
    else if (this._focus === 3) this.verifyTap();
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
    <canvas id="charCanvas" width="464" height="252" class="char-canvas"></canvas>
    <text class="bar">{{barLine}}</text>
    <view class="acts">
      <button class="act" bindtap="actTap" data-idx="0">上一笔</button>
      <button class="act hot" bindtap="actTap" data-idx="1">下一笔</button>
      <button class="act" bindtap="actTap" data-idx="2">念要点</button>
      <button class="act" bindtap="actTap" data-idx="3">写完去验收</button>
      <button class="act" bindtap="actTap" data-idx="4">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01 · 范字数据 hanzi-writer-data · 圈内数字=笔顺，箭头=行笔方向</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 3px 8px; background-color: #000000; }
.char-canvas { width: 464px; height: 252px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.4); }
.bar { color: rgba(125,255,158,0.92); font-size: 11.5px; line-height: 15px; margin-top: 3px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 4px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 3px 8px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.line { color: rgba(125,255,158,0.85); font-size: 10.5px; line-height: 13px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 9.5px; line-height: 12px; margin-top: 1px; }
</style>
