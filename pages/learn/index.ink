<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 学字页 v3（描红主页）：范字全屏——画布占满整页（464×252），只留
// 底部窄栏放「第 X 笔 / 共 N 笔（笔型）+ 本笔要点」与最少控件。
// v1.2.0：范字改空心描边（描红字帖式）——strokes 路径只 stroke 不
// fill，当前笔描边最亮绿 #7dff9e 且略粗、已学 #40ff5e 中绿、未学压
// 暗细线；路径异常退 medians 折线细描。笔顺箭头按 GO 参考图式改
// 弧形：每笔把 medians 点列沿切线法线平移到笔画外侧（先 18px、侵
// 入字身加大到 24px），成一条贴着笔画走向弯曲的平行弧，弧末端加
// 箭头头（钩 / 折笔的弧沿折向弯、箭头指钩尖）；笔顺数字圈移到弧
// 起点外侧。弧线 / 数字与所属笔同档明暗，与笔画共用同一坐标变换
// （1024 系 → 画布）。笔画拆分仍按 GF0023-2020（如永 = 5 笔，不
// 跟参考图的永字八法 8 标注）。笔位逐步落盘（trace.brush.learn）：
// 平台无常亮 / wake lock API（官方文档全量查无，见 README 平台边
// 界），描红中熄屏无法从 Agent 侧阻止，靠重进同字恢复当前笔缓解。
const TMP = 'trace.brush.tmp';
const LEARN = 'trace.brush.learn'; // 笔位落盘（熄屏 / 重进恢复用，非进度）
const ACTS = ['上一笔', '下一笔', '念要点', '写完去验收', '返回 BACK'];
const W = 464, H = 252, S = 248, OX = 108, OY = 10;

export default {
  data: {
    status: '学字：一笔一笔看清，再在纸上跟写',
    barLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.2.0'
  },
  onLoad() {
    this._focus = 1; this._step = 0; this._useMedians = false;
    const t = loadKey(TMP, { char: CHARS[0].char });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    // 笔位恢复：平台无常亮 API（见 README 平台边界），熄屏 / 退出后
    // 重进同一字时，按落盘笔位回到当前笔、明暗进度原样恢复；换字
    // （落盘字 ≠ 本次字）则从第一笔开始。
    const ls = loadKey(LEARN, null);
    if (ls && ls.char === this._char.char && typeof ls.step === 'number') {
      this._step = Math.max(0, Math.min(this._char.strokes.length - 1, ls.step));
    }
    this._render(true);
  },
  onShow() { this._render(false); },
  _render(speakTip) {
    const c = this._char;
    saveKey(LEARN, { char: c.char, step: this._step });
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
  _segDist(px, py, ax, ay, bx, by) {
    // 点到线段距离（箭头落位校验用）
    const abx = bx - ax, aby = by - ay;
    const t0 = abx * abx + aby * aby;
    let t = t0 > 0 ? ((px - ax) * abx + (py - ay) * aby) / t0 : 0;
    t = Math.max(0, Math.min(1, t));
    const qx = ax + abx * t - px, qy = ay + aby * t - py;
    return Math.sqrt(qx * qx + qy * qy);
  },
  _pathPoly(d) {
    // 笔画 SVG 路径 → 轮廓多边形点列（画布坐标，曲线采样 8 步），供
    // 弧线侵入判定（点是否落在笔画身内）
    const toks = String(d).match(/[MLCQZ]|-?\d+\.?\d*/g) || [];
    let i = 0, cmd = '';
    const pts = [];
    let cur = null;
    const self = this;
    function P(x, y) { return [self._X(x), self._Y(y)]; }
    while (i < toks.length) {
      if (/[MLCQZ]/.test(toks[i])) { cmd = toks[i]; i++; if (cmd === 'Z') cmd = ''; continue; }
      if (cmd === 'M') { cur = P(+toks[i], +toks[i + 1]); pts.push(cur); i += 2; cmd = 'L'; }
      else if (cmd === 'L') { cur = P(+toks[i], +toks[i + 1]); pts.push(cur); i += 2; }
      else if (cmd === 'C') {
        const p0 = cur, p1 = P(+toks[i], +toks[i + 1]), p2 = P(+toks[i + 2], +toks[i + 3]), p3 = P(+toks[i + 4], +toks[i + 5]);
        for (let k = 1; k <= 8; k++) { const t = k / 8, u = 1 - t; pts.push([u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0], u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]]); }
        cur = p3; i += 6;
      } else if (cmd === 'Q') {
        const p0 = cur, p1 = P(+toks[i], +toks[i + 1]), p2 = P(+toks[i + 2], +toks[i + 3]);
        for (let k = 1; k <= 8; k++) { const t = k / 8, u = 1 - t; pts.push([u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]]); }
        cur = p2; i += 4;
      } else i++;
    }
    return pts;
  },
  _inPoly(px, py, poly) {
    // 射线法点在多边形内判定
    let inside = false;
    for (let a = 0, b = poly.length - 1; a < poly.length; b = a++) {
      const xa = poly[a][0], ya = poly[a][1], xb = poly[b][0], yb = poly[b][1];
      if (((ya > py) !== (yb > py)) && (px < (xb - xa) * (py - ya) / (yb - ya) + xa)) inside = !inside;
    }
    return inside;
  },
  _arcFor(lines, polys, idx, cx, cy) {
    // 弧形笔顺箭头（按 GO 参考图式）：把该笔 medians 点列逐点沿切线
    // 法线平移到笔画外侧，成一条贴着笔画走向弯曲的平行弧。选边 =
    // 中点处远离字心的一侧（整笔同一侧，法线随切线连续旋转，钩 /
    // 折笔的弧自然沿折向弯过去）；偏移 18px 起、侵入字身加大到
    // 24px，候选弧经逐点排斥松弛绕开邻笔后按「落进笔画轮廓内的采
    // 样比例」评分，外侧优先（见下方 intrOf 处注释）。返回
    // { pts 弧点列（画布坐标）, n0 弧起点处的单位外移方向 }，数字
    // 圈据 n0 落在弧起点外侧。
    const line = lines[idx];
    if (!line || line.length < 2) return null;
    const n = line.length;
    const tans = [], nors = [];
    for (let j = 0; j < n; j++) {
      const a = line[Math.max(0, j - 1)], b = line[Math.min(n - 1, j + 1)];
      let tx = b[0] - a[0], ty = b[1] - a[1];
      const tl = Math.sqrt(tx * tx + ty * ty);
      if (tl < 0.01) { tx = 1; ty = 0; } else { tx /= tl; ty /= tl; }
      tans.push([tx, ty]);
      nors.push([-ty, tx]); // 法线族 A（随切线连续）；族 B 为其反向
    }
    const jm = Math.floor(n / 2);
    const awayA = (nors[jm][0] * (line[jm][0] - cx) + nors[jm][1] * (line[jm][1] - cy)) >= 0;
    const build = function (useA, d) {
      const pts = [];
      for (let j = 0; j < n; j++) {
        const s = useA ? 1 : -1;
        pts.push([line[j][0] + nors[j][0] * s * d, line[j][1] + nors[j][1] * s * d]);
      }
      return pts;
    };
    const nearInfo = function (px, py, selfSegSkip) {
      // 最近中线段信息：{ d 距离, qx/qy 最近点 }。跳过本笔沿轨附近的
      // 段（弧本就贴着它们走）；其他笔的段全算。
      let bd = 1e9, bq = null;
      for (let s2 = 0; s2 < lines.length; s2++) {
        const ln = lines[s2];
        for (let j = 0; j + 1 < ln.length; j++) {
          if (s2 === idx && selfSegSkip && j >= selfSegSkip[0] && j <= selfSegSkip[1]) continue;
          const ax = ln[j][0], ay = ln[j][1], abx = ln[j + 1][0] - ax, aby = ln[j + 1][1] - ay;
          const t0 = abx * abx + aby * aby;
          let t = t0 > 0 ? ((px - ax) * abx + (py - ay) * aby) / t0 : 0;
          t = Math.max(0, Math.min(1, t));
          const qx = ax + abx * t, qy = ay + aby * t;
          const dd = Math.sqrt((px - qx) * (px - qx) + (py - qy) * (py - qy));
          if (dd < bd) { bd = dd; bq = [qx, qy]; }
        }
      }
      return { d: bd, q: bq };
    }.bind(this);
    const relax = function (pts) {
      // 逐点排斥松弛：弧点离任何中线（本笔沿轨附近段除外）< 16 就沿
      // 远离该中线的方向推出去，4 轮 + 邻点平滑，弧保持贴笔平滑、
      // 只在交叉 / 贴近处局部绕开。每点总位移钳制在原位 34px 内。
      const orig = pts.map(function (p) { return [p[0], p[1]]; });
      for (let round = 0; round < 4; round++) {
        for (let j = 0; j < pts.length; j++) {
          const info = nearInfo(pts[j][0], pts[j][1], [j - 2, j + 1]);
          if (info.q && info.d < 16) {
            let vx = pts[j][0] - info.q[0], vy = pts[j][1] - info.q[1];
            const vl = Math.sqrt(vx * vx + vy * vy);
            if (vl < 0.01) { vx = nors[j][0]; vy = nors[j][1]; } else { vx /= vl; vy /= vl; }
            const push = (16 - info.d) * 0.9;
            pts[j][0] += vx * push; pts[j][1] += vy * push;
          }
        }
        for (let j = 1; j + 1 < pts.length; j++) {
          pts[j][0] = pts[j - 1][0] * 0.22 + pts[j][0] * 0.56 + pts[j + 1][0] * 0.22;
          pts[j][1] = pts[j - 1][1] * 0.22 + pts[j][1] * 0.56 + pts[j + 1][1] * 0.22;
        }
        for (let j = 0; j < pts.length; j++) {
          let mx = pts[j][0] - orig[j][0], my = pts[j][1] - orig[j][1];
          const ml = Math.sqrt(mx * mx + my * my);
          if (ml > 34) { pts[j][0] = orig[j][0] + mx / ml * 34; pts[j][1] = orig[j][1] + my / ml * 34; }
          pts[j][0] = Math.max(4, Math.min(W - 4, pts[j][0]));
          pts[j][1] = Math.max(4, Math.min(H - 4, pts[j][1]));
        }
      }
      return pts;
    }.bind(this);
    const intrOf = function (pts) {
      // 侵入率：弧采样点落进任一笔画轮廓多边形内的比例（0 = 全程在
      // 笔画身外）。交叉笔画的交点附近少量侵入几何上不可避免，取舍
      // 以侵入率最小为准。
      const samples = [];
      for (let j = 0; j < pts.length; j++) {
        samples.push(pts[j]);
        if (j + 1 < pts.length) {
          samples.push([pts[j][0] * 0.66 + pts[j + 1][0] * 0.34, pts[j][1] * 0.66 + pts[j + 1][1] * 0.34]);
          samples.push([pts[j][0] * 0.34 + pts[j + 1][0] * 0.66, pts[j][1] * 0.34 + pts[j + 1][1] * 0.66]);
        }
      }
      let inside = 0;
      for (let k = 0; k < samples.length; k++) {
        for (let s2 = 0; s2 < polys.length; s2++) {
          if (this._inPoly(samples[k][0], samples[k][1], polys[s2])) { inside++; break; }
        }
      }
      return samples.length ? inside / samples.length : 1;
    }.bind(this);
    // 候选 = （外侧 / 内侧）×（18 / 24px），各自先松弛再按侵入率评：
    // 优先外侧——外侧侵入率不比内侧最优差过 0.12 就用外侧（弧应贴
    // 字身外缘，如捺弧走右下侧）；否则用全局侵入最小者。
    const candDefs = [[awayA, 18], [awayA, 24], [!awayA, 18], [!awayA, 24]];
    const scored = [];
    for (let k = 0; k < candDefs.length; k++) {
      const pts = relax(build(candDefs[k][0], candDefs[k][1]));
      scored.push({ pts: pts, away: candDefs[k][0] === awayA, intr: intrOf(pts) });
    }
    let bestAway = null, bestOther = null;
    for (let k = 0; k < scored.length; k++) {
      const s = scored[k];
      if (s.away) { if (!bestAway || s.intr < bestAway.intr) bestAway = s; }
      else if (!bestOther || s.intr < bestOther.intr) bestOther = s;
    }
    let best = null;
    if (bestAway && (!bestOther || bestAway.intr <= bestOther.intr + 0.12)) best = bestAway.pts;
    else if (bestOther) best = bestOther.pts;
    else if (bestAway) best = bestAway.pts;
    if (!best) return null;
    for (let j = 0; j < best.length; j++) {
      best[j][0] = Math.max(3, Math.min(W - 3, best[j][0]));
      best[j][1] = Math.max(3, Math.min(H - 3, best[j][1]));
    }
    let nx = best[0][0] - line[0][0], ny = best[0][1] - line[0][1];
    const nl = Math.sqrt(nx * nx + ny * ny);
    if (nl > 0.01) { nx /= nl; ny /= nl; } else { nx = 0; ny = -1; }
    return { pts: best, n0: [nx, ny] };
  },
  _arrow(ctx, arc, state, col) {
    // 沿弧点列画平滑弧线（polyline），末端按弧末段方向加箭头头；
    // 与所属笔同档明暗。
    if (!arc || !arc.pts || arc.pts.length < 2) return;
    const pts = arc.pts, n = pts.length;
    ctx.strokeStyle = col; ctx.lineWidth = state === 1 ? 2.6 : (state === 0 ? 2 : 1.6);
    ctx.beginPath();
    for (let j = 0; j < n; j++) {
      if (j === 0) ctx.moveTo(pts[j][0], pts[j][1]); else ctx.lineTo(pts[j][0], pts[j][1]);
    }
    ctx.stroke();
    let dx = pts[n - 1][0] - pts[n - 2][0], dy = pts[n - 1][1] - pts[n - 2][1];
    let dl = Math.sqrt(dx * dx + dy * dy);
    if (dl < 0.5 && n > 2) { dx = pts[n - 1][0] - pts[n - 3][0]; dy = pts[n - 1][1] - pts[n - 3][1]; dl = Math.sqrt(dx * dx + dy * dy); }
    if (dl < 0.5) return;
    dx /= dl; dy /= dl;
    const tx = pts[n - 1][0], ty = pts[n - 1][1];
    const px = -dy, py = dx, hw = 8;
    ctx.beginPath();
    ctx.moveTo(tx, ty); ctx.lineTo(tx - dx * hw + px * hw * 0.62, ty - dy * hw + py * hw * 0.62);
    ctx.moveTo(tx, ty); ctx.lineTo(tx - dx * hw - px * hw * 0.62, ty - dy * hw - py * hw * 0.62);
    ctx.stroke();
  },
  _badgePos(arc, state) {
    // 笔顺数字圈：落在弧起点外侧（沿弧起点外移方向再推一个半径多）
    if (!arc || !arc.pts || !arc.pts.length) return null;
    const r = state === 1 ? 11 : 9.5;
    let bx = arc.pts[0][0] + arc.n0[0] * (r + 3);
    let by = arc.pts[0][1] + arc.n0[1] * (r + 3);
    bx = Math.max(r + 1, Math.min(W - r - 1, bx));
    by = Math.max(r + 1, Math.min(H - r - 1, by));
    return [bx, by];
  },
  _badgePosFallback(med) {
    // 无弧时（如 medians 不足）的数字圈位置：起笔点旁、向字心反方向
    if (!med || !med.length) return null;
    let bx = this._X(med[0][0]), by = this._Y(med[0][1]);
    let vx = bx - W / 2, vy = by - H / 2;
    const vl = Math.sqrt(vx * vx + vy * vy);
    if (vl > 1) { bx += vx / vl * 15; by += vy / vl * 15; }
    else { bx -= 15; by -= 15; }
    bx = Math.max(12, Math.min(W - 12, bx)); by = Math.max(12, Math.min(H - 12, by));
    return [bx, by];
  },
  _badge(ctx, pos, num, state) {
    // 笔顺数字：小圆圈底 + 序号（位置由 _badgePos 定）
    if (!pos) return;
    const bx = pos[0], by = pos[1];
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
      // 预计算（画布坐标）：全部笔画中线、字心（包围盒中心）、数字圈位
      const lines = [];
      let mnx = 1e9, mny = 1e9, mxx = -1e9, mxy = -1e9;
      for (let i = 0; i < c.medians.length; i++) {
        const ln = [];
        for (let j = 0; j < c.medians[i].length; j++) {
          const vx = this._X(c.medians[i][j][0]), vy = this._Y(c.medians[i][j][1]);
          ln.push([vx, vy]);
          if (vx < mnx) mnx = vx; if (vx > mxx) mxx = vx;
          if (vy < mny) mny = vy; if (vy > mxy) mxy = vy;
        }
        lines.push(ln);
      }
      const ccx = (mnx + mxx) / 2, ccy = (mny + mxy) / 2;
      // 逐笔弧形箭头（贴笔画外侧的平行弧），数字圈随弧起点定
      const polys = [];
      for (let i = 0; i < c.strokes.length; i++) { try { polys.push(this._pathPoly(c.strokes[i])); } catch (e) { polys.push([]); } }
      const arcs = [];
      for (let i = 0; i < c.medians.length; i++) arcs.push(this._arcFor(lines, polys, i, ccx, ccy));
      // 空心描边：路径只 stroke 不 fill（字帖式空心字，内部透黑）
      const cols = ['#40ff5e', '#7dff9e', 'rgba(64,255,94,0.20)'];
      const widths = [1.8, 2.4, 1.1];
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        const col = cols[state];
        if (!this._useMedians) {
          try {
            this._path(ctx, c.strokes[i]);
            ctx.strokeStyle = col; ctx.lineWidth = widths[state]; ctx.stroke();
          } catch (e) { this._useMedians = true; }
        }
        if (this._useMedians) {
          const med = c.medians[i];
          ctx.strokeStyle = col; ctx.lineWidth = widths[state];
          ctx.beginPath();
          for (let j = 0; j < med.length; j++) {
            const px = this._X(med[j][0]), py = this._Y(med[j][1]);
            if (j === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
          }
          ctx.stroke();
        }
      }
      // 弧线层（笔画外侧平行弧 + 弧末箭头头）+ 数字层（弧起点旁，最后画）
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        const acol = state === 1 ? '#7dff9e' : (state === 0 ? 'rgba(64,255,94,0.85)' : 'rgba(64,255,94,0.35)');
        this._arrow(ctx, arcs[i], state, acol);
      }
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        const pos = arcs[i] ? this._badgePos(arcs[i], state) : this._badgePosFallback(c.medians[i]);
        this._badge(ctx, pos, i + 1, state);
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
    <text class="foot">{{evt}} · {{ver}} · TR01 · 范字数据 hanzi-writer-data · 空心范字 · 数字=笔顺，弧箭=走向</text>
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
