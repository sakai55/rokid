<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 学字页 v3（描红主页）：范字全屏——画布占满整页（464×252），只留
// 底部窄栏放「第 X 笔 / 共 N 笔（笔型）+ 本笔要点」与最少控件。
// v1.3.0：范字主体按桌面描红距离口径缩放——眼到桌面约 40cm、字帖
// 格字约 9cm 见方（张角约 12.8°，合纵向视场约 58%），20 字轮廓并
// 集高度约 205px、居中（S=236），与低头看纸上字接近 1:1。笔顺弧
// 废弃逐点平行偏移，每笔构造一支与字身分离的简化弧——候选 = 二次
// 贝塞尔（P0 / Pm / P1 沿逐点外向法线推出 22–38px）与三次贝塞尔
// （双控点），内外两侧都试；候选逐采样点（含箭头翼尖）用全字轮
// 廓多边形硬校验：不许进入任一笔画轮廓内部及其 6px 邻域（侵入必
// 为 0），与轮廓最小距离 ≥14px 为达标档、≥6.5px 为可用档；完整
// 弧不存在时缩短到不侵入的区段（宁短勿侵入），再不行在笔末外侧
// 沿行笔方向补一支终段小弧。序号圈在弧尾外侧以 16 方位搜索落位
// （校验对轮廓 / 全部弧线 / 已放圈的距离）。
// v1.3.1（GO 看图定版）：弧只保留原弧末段约 1/4（原弧过短时保
// 16px 最低可读长度），箭头头随弧长收小。
// v1.3.2（GO 看图再定）：笔画本体统一低亮度（半透明淡绿，所有
// 笔画所有状态一致，不再分档），高亮只给笔顺标注——弧恢复最亮
// 绿 + 实心箭头头、序号圈亮绿；箭头方向改按本笔行笔方向
// （arc.endDir），不取短弧弦向（「大」第 1 笔曾被弦向带偏）。
// v1.3.3（GO 看图定版）：v1.3.2 除弧外全部冻结；弧形箭头改回
// v1.2 式沿笔画平行伴行弧、只取末段缩短版（见 _parallelArc），
// 硬校验保与字身拉开距离，不重蹈 v1.2 缎带覆辙。
// v1.3.4（GO 三点修正）：序号锚定弧尾并一律外侧（见 _badgePos），
// 平行弧法线平滑、弧形贴合笔画自身走向；其余仍冻结。
// v1.3.5（GO 定）：弧线箭头改放在起笔位置——平行弧取中线起始
// 段，弧尾即起笔处、序号随之锚定起笔，箭头沿行笔方向指去向。
// 笔画拆分仍按 GF0023-2020（如永 = 5
// 笔）。笔位逐步落盘（trace.brush.learn）：平台无常亮 / wake
// lock API（官方文档全量查无，见 README 平台边界），描红中熄屏
// 无法从 Agent 侧阻止，靠重进同字恢复当前笔缓解。
const TMP = 'trace.brush.tmp';
const LEARN = 'trace.brush.learn'; // 笔位落盘（熄屏 / 重进恢复用，非进度）
const ACTS = ['上一笔', '下一笔', '念要点', '写完去验收', '返回 BACK'];
const W = 464, H = 252, S = 236, OX = 110, OY = 11;

export default {
  data: {
    status: '学字：一笔一笔看清，再在纸上跟写',
    barLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.3.5'
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
    // 点到线段距离（弧线 / 序号落位校验用）
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
  _distPolys(px, py, polys) {
    // 点到全字轮廓的最小距离；落进任一轮廓内返回 -1（硬约束判定）
    let bd = 1e9;
    for (let s2 = 0; s2 < polys.length; s2++) {
      const poly = polys[s2];
      if (!poly || poly.length < 3) continue;
      if (this._inPoly(px, py, poly)) return -1;
      for (let a = 0, b = poly.length - 1; a < poly.length; b = a++) {
        const d = this._segDist(px, py, poly[b][0], poly[b][1], poly[a][0], poly[a][1]);
        if (d < bd) bd = d;
      }
    }
    return bd;
  },
  _arcFor(lines, polys, idx, cx, cy) {
    // 笔顺弧 v1.3.0（与字身分离的简化弧，硬约束校验）：候选构造 =
    // 二次贝塞尔（medians 首 / 中 / 末三点沿各自外向法线推出）与三
    // 次贝塞尔（1/3、2/3 点双控），外侧（逐点远离字心）与内侧各试
    // 推距 22–38px。每个候选逐采样点 + 箭头翼尖用 _distPolys 校验：
    // 进轮廓或距轮廓 <6.5px 即废；≥14px 为达标。选取顺序 = 方向对
    // （弧末方向与笔末行笔方向偏差 ≤50°）的达标弧 → 方向对的可用
    // 弧（≥6.5） → 缩短片段（在多推距曲线上取最长不侵入区段）→
    // 终段小弧（笔末外侧沿行笔方向的 36px 短弧）。返回
    // { pts 弧点列, n0 弧起点外向单位向量 }。
    const line = lines[idx];
    if (!line || line.length < 2) return null;
    const self = this;
    const n = line.length;
    const P0 = line[0], P1 = line[n - 1];
    const jm = Math.floor(n / 2), Pm = line[jm];
    const j1 = Math.floor(n / 3), j2 = Math.floor(2 * n / 3);
    const Pa = line[j1], Pb = line[j2];
    const hyp = function (a, b) { return Math.sqrt(a * a + b * b); };
    const sub = function (a, b) { return [a[0] - b[0], a[1] - b[1]]; };
    const vnorm = function (v) { const l = hyp(v[0], v[1]); return l < 1e-6 ? null : [v[0] / l, v[1] / l]; };
    const angDeg = function (u, v) { const d = Math.max(-1, Math.min(1, u[0] * v[0] + u[1] * v[1])); return Math.acos(d) * 180 / Math.PI; };
    const bez2 = function (p0, p1, p2, t) { const u = 1 - t; return [u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]]; };
    const bez3 = function (p0, p1, p2, p3, t) { const u = 1 - t; return [u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0], u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]]; };
    // 笔末行笔方向：自末点回溯 ≥10px 取向（末段过短时单段方向不稳）
    let eiEnd = n - 2;
    while (eiEnd > 0 && hyp(line[n - 1][0] - line[eiEnd][0], line[n - 1][1] - line[eiEnd][1]) < 10) eiEnd--;
    const endDir = vnorm(sub(line[n - 1], line[eiEnd])) || [1, 0];
    const outNormal = function (j) {
      const a = line[Math.max(0, j - 1)], b = line[Math.min(n - 1, j + 1)];
      const t = vnorm(sub(b, a)) || vnorm(sub(P1, P0)) || [1, 0];
      let nv = [-t[1], t[0]];
      if (nv[0] * (line[j][0] - cx) + nv[1] * (line[j][1] - cy) < 0) nv = [-nv[0], -nv[1]];
      return nv;
    };
    const o0 = outNormal(0), o1 = outNormal(jm), o2 = outNormal(n - 1), oa = outNormal(j1), ob = outNormal(j2);
    const build = function (kind, side, dEnd) {
      const dCtrl = Math.min(dEnd + 8, 46);
      const A = [P0[0] + o0[0] * side * dEnd, P0[1] + o0[1] * side * dEnd];
      const B = [P1[0] + o2[0] * side * dEnd, P1[1] + o2[1] * side * dEnd];
      const pts = [];
      if (kind === 'quad') {
        const Q = [Pm[0] + o1[0] * side * dCtrl, Pm[1] + o1[1] * side * dCtrl];
        for (let k = 0; k <= 24; k++) pts.push(bez2(A, Q, B, k / 24));
        return { A: A, B: B, Q: Q, pts: pts, n0: [o0[0] * side, o0[1] * side] };
      }
      const C1 = [Pa[0] + oa[0] * side * dCtrl, Pa[1] + oa[1] * side * dCtrl];
      const C2 = [Pb[0] + ob[0] * side * dCtrl, Pb[1] + ob[1] * side * dCtrl];
      for (let k = 0; k <= 24; k++) pts.push(bez3(A, C1, C2, B, k / 24));
      return { A: A, B: B, Q: C2, pts: pts, n0: [o0[0] * side, o0[1] * side] };
    };
    const wingTipsOf = function (pts) {
      const B = pts[pts.length - 1], Qp = pts[Math.max(0, pts.length - 4)];
      const dir = vnorm(sub(B, Qp));
      if (!dir) return [];
      const px = -dir[1], py = dir[0];
      return [[B[0] - dir[0] * 13 + px * 7.5, B[1] - dir[1] * 13 + py * 7.5], [B[0] - dir[0] * 13 - px * 7.5, B[1] - dir[1] * 13 - py * 7.5]];
    };
    const evalPts = function (pts) {
      let md = 1e9;
      for (let k = 0; k < pts.length; k++) {
        const p = pts[k];
        if (p[0] < 3 || p[0] > W - 3 || p[1] < 3 || p[1] > H - 3) return -2;
        const d = self._distPolys(p[0], p[1], polys);
        if (d < md) md = d;
      }
      return md;
    };
    const evalCfg = function (kind, side, dEnd) {
      const c = build(kind, side, dEnd);
      const md = evalPts(c.pts.concat(wingTipsOf(c.pts)));
      return { kind: kind, side: side, dEnd: dEnd, pts: c.pts, n0: c.n0, minDist: md };
    };
    const fragEndDir = function (pts) {
      let ei = pts.length - 2;
      while (ei > 0 && hyp(pts[pts.length - 1][0] - pts[ei][0], pts[pts.length - 1][1] - pts[ei][1]) < 8) ei--;
      return vnorm(sub(pts[pts.length - 1], pts[ei])) || endDir;
    };
    const fragN0 = function (pts) {
      const t = vnorm(sub(pts[Math.min(pts.length - 1, 2)], pts[0])) || [1, 0];
      let nv = [-t[1], t[0]];
      if (nv[0] * (pts[0][0] - cx) + nv[1] * (pts[0][1] - cy) < 0) nv = [-nv[0], -nv[1]];
      return nv;
    };
    const terminalTick = function () {
      const poly = polys[idx];
      let bot = -1e9;
      for (let k = 0; k < poly.length; k++) bot = Math.max(bot, poly[k][1]);
      const cands = [];
      const sg = [1, -1], noffs = [16, 22, 28, 34], aoffs = [0, 8, 16];
      for (let a2 = 0; a2 < sg.length; a2++) for (let b2 = 0; b2 < noffs.length; b2++) for (let c2 = 0; c2 < aoffs.length; c2++) {
        cands.push([P1[0] + endDir[0] * aoffs[c2] + o2[0] * sg[a2] * noffs[b2], P1[1] + endDir[1] * aoffs[c2] + o2[1] * sg[a2] * noffs[b2]]);
      }
      cands.push([P1[0] + endDir[0] * 10, bot + 13]);
      cands.push([P1[0] + endDir[0] * 10, bot + 19]);
      for (let k = 0; k < cands.length; k++) {
        const A = cands[k];
        const B = [A[0] + endDir[0] * 36, A[1] + endDir[1] * 36];
        const Q = [A[0] + endDir[0] * 18 + (-endDir[1]) * 5, A[1] + endDir[1] * 18 + endDir[0] * 5];
        const pts = [];
        for (let j = 0; j <= 16; j++) pts.push(bez2(A, Q, B, j / 16));
        const md = evalPts(pts.concat(wingTipsOf(pts)));
        if (md >= 6.5) return { pts: pts, n0: fragN0(pts), minDist: md, endMismatch: angDeg(fragEndDir(pts), endDir), mode: 'terminal' };
      }
      return null;
    };
    const PUSHES = [22, 26, 30, 34, 38];
    const order = [['quad', 1], ['cubic', 1], ['quad', -1], ['cubic', -1]];
    let goodOk = null, goodAny = null, softOk = null, softAny = null;
    for (let oi = 0; oi < order.length; oi++) {
      const kind = order[oi][0], side = order[oi][1];
      for (let pi = 0; pi < PUSHES.length; pi++) {
        const c = evalCfg(kind, side, PUSHES[pi]);
        const mm = angDeg(fragEndDir(c.pts), endDir);
        c.endMismatch = mm;
        if (c.minDist >= 14) {
          if (!goodAny) goodAny = c;
          if (mm <= 50 && !goodOk) goodOk = c;
        } else if (c.minDist >= 6.5) {
          if (!softAny || c.minDist > softAny.minDist) softAny = c;
          if (mm <= 50 && (!softOk || c.minDist > softOk.minDist)) softOk = c;
        }
      }
    }
    if (goodOk) return goodOk;
    if (softOk) return softOk;
    // 缩短档：多推距曲线上找最长不侵入区段（含起点 / 末点者加权）
    let bestRun = null;
    const shortPushes = [16, 22, 30, 38];
    for (let oi = 0; oi < order.length; oi++) {
      const kind = order[oi][0], side = order[oi][1];
      for (let pi = 0; pi < shortPushes.length; pi++) {
        const dEnd = shortPushes[pi];
        const c = build(kind, side, dEnd);
        const dense = [];
        if (kind === 'quad') {
          for (let k = 0; k <= 48; k++) dense.push(bez2(c.A, c.Q, c.B, k / 48));
        } else {
          const dCtrl = Math.min(dEnd + 8, 46);
          const C1 = [Pa[0] + oa[0] * side * dCtrl, Pa[1] + oa[1] * side * dCtrl];
          const C2 = [Pb[0] + ob[0] * side * dCtrl, Pb[1] + ob[1] * side * dCtrl];
          for (let k = 0; k <= 48; k++) dense.push(bez3(c.A, C1, C2, c.B, k / 48));
        }
        const runs = [];
        let runStart = -1;
        for (let k = 0; k <= dense.length; k++) {
          const p = dense[k];
          const ok = k < dense.length && p[0] >= 3 && p[0] <= W - 3 && p[1] >= 3 && p[1] <= H - 3 && self._distPolys(p[0], p[1], polys) >= 6.5;
          if (ok && runStart < 0) runStart = k;
          if (!ok && runStart >= 0) { runs.push([runStart, k - 1]); runStart = -1; }
        }
        for (let ri = 0; ri < runs.length; ri++) {
          const r = runs[ri];
          if (r[1] - r[0] < 4) continue;
          const pts = dense.slice(r[0], r[1] + 1);
          const wt = wingTipsOf(pts);
          let wok = true;
          for (let wi = 0; wi < wt.length; wi++) { if (self._distPolys(wt[wi][0], wt[wi][1], polys) < 6) { wok = false; break; } }
          if (!wok) continue;
          let len = 0;
          for (let k = 1; k < pts.length; k++) len += hyp(pts[k][0] - pts[k - 1][0], pts[k][1] - pts[k - 1][1]);
          if (len < 12) continue;
          const score = len * (1 + (r[0] === 0 ? 0.3 : 0) + (r[1] === 48 ? 0.3 : 0));
          if (!bestRun || score > bestRun.score) {
            let md = 1e9;
            for (let k = 0; k < pts.length; k++) md = Math.min(md, self._distPolys(pts[k][0], pts[k][1], polys));
            bestRun = { pts: pts, n0: fragN0(pts), minDist: md, score: score, endMismatch: angDeg(fragEndDir(pts), endDir), mode: 'shortened' };
          }
        }
      }
    }
    // 方向对的缩短片段优先于方向错的完整弧；再不行用终段小弧兜底
    if (bestRun && bestRun.endMismatch <= 60) return bestRun;
    if (!bestRun || bestRun.endMismatch > 60 || goodAny || softAny) {
      const tick = terminalTick();
      if (tick) return tick;
    }
    if (bestRun) return bestRun;
    if (goodAny) return goodAny;
    if (softAny) return softAny;
    return null;
  },
  _parallelArc(lines, polys, idx, cx, cy) {
    // 笔顺弧 v1.3.3（GO 指定）：回到 v1.2 的形态——弧沿本笔中线
    // 平行伴行（中线 Catmull-Rom 重采样后逐点沿法线外推），段长
    // = 中线总长 × 0.35（26–56px 钳制）。v1.3.5（GO 定）：弧放在
    // 起笔位置——取中线的起始段，弧尾即起笔处（序号锚定于此），
    // 箭头沿行笔方向指出这一笔的去向（endDir 取段末平滑切向）。
    // v1.2 当年失败在弧贴着轮廓描边（缎带），本版保留 v1.3 的
    // 硬校验：整段采样点 + 箭头翼尖逐点验 _distPolys ≥6.5 且不
    // 出画布，推距 30/36/42 逐档试、两侧都试；全不过则返回
    // null，由 _geom 退回 v1.3 短弧兜底。
    const line = lines[idx];
    if (!line || line.length < 2) return null;
    const self = this;
    const hyp = function (a, b) { return Math.sqrt(a * a + b * b); };
    // Catmull-Rom 重采样（端点复制补齐），72 样点 + 逐点切向
    const P = [line[0]].concat(line, [line[line.length - 1]]);
    const dense = [];
    const SEG = 72;
    for (let s = 0; s < P.length - 3; s++) {
      const p0 = P[s], p1 = P[s + 1], p2 = P[s + 2], p3 = P[s + 3];
      const steps = Math.max(2, Math.round(SEG / (P.length - 3)));
      for (let k = (s === 0 ? 0 : 1); k <= steps; k++) {
        const t = k / steps, t2 = t * t, t3 = t2 * t;
        dense.push([
          0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3),
          0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
        ]);
      }
    }
    if (dense.length < 4) return null;
    const cum = [0];
    for (let k = 1; k < dense.length; k++) cum.push(cum[k - 1] + hyp(dense[k][0] - dense[k - 1][0], dense[k][1] - dense[k - 1][1]));
    const total = cum[cum.length - 1];
    if (!(total > 8)) return null;
    const segLen = Math.min(total, Math.max(26, Math.min(56, total * 0.35)));
    // 起笔段：自中线起点起、长 segLen 的一段（v1.3.5）。
    const segIdx = [];
    for (let k = 0; k < dense.length; k++) { segIdx.push(k); if (cum[k] >= segLen) break; }
    const rawN = [];
    for (let k = 0; k < dense.length; k++) {
      const a = dense[Math.max(0, k - 1)], b = dense[Math.min(dense.length - 1, k + 1)];
      const tx = b[0] - a[0], ty = b[1] - a[1];
      const tl = hyp(tx, ty);
      rawN.push(tl < 1e-6 ? null : [-ty / tl, tx / tl]);
    }
    // 法线平滑（±3 样点均值，v1.3.4）：弧形贴合笔画自身走向，
    // 不因样点间距不均鼓出假弯。
    const smN = [];
    for (let k = 0; k < dense.length; k++) {
      let sx = 0, sy = 0, cnt = 0;
      for (let j = Math.max(0, k - 3); j <= Math.min(dense.length - 1, k + 3); j++) {
        if (rawN[j]) { sx += rawN[j][0]; sy += rawN[j][1]; cnt++; }
      }
      if (!cnt) { smN.push(null); continue; }
      const sl = hyp(sx, sy);
      smN.push(sl < 1e-6 ? rawN[k] : [sx / sl, sy / sl]);
    }
    const normalAt = function (k) { return smN[k]; };
    const attempt = function (idxs) {
      const midK = idxs[Math.floor(idxs.length / 2)];
      const midN = normalAt(midK);
      if (!midN) return null;
      const away = (midN[0] * (dense[midK][0] - cx) + midN[1] * (dense[midK][1] - cy)) >= 0 ? 1 : -1;
      const sides = [away, -away];
      const pushes = [30, 36, 42, 24];
      const segL = cum[idxs[idxs.length - 1]] - cum[idxs[0]];
      const wingTips = function (pts, dir) {
        const back = Math.min(13, Math.max(7, segL * 0.55));
        const half = Math.min(7.5, Math.max(3.5, segL * 0.28));
        const tx = pts[pts.length - 1][0], ty = pts[pts.length - 1][1];
        const px = -dir[1], py = dir[0];
        return [[tx - dir[0] * back + px * half, ty - dir[1] * back + py * half], [tx - dir[0] * back - px * half, ty - dir[1] * back - py * half]];
      };
      for (let s2 = 0; s2 < sides.length; s2++) {
        const side = sides[s2];
        for (let p2 = 0; p2 < pushes.length; p2++) {
          const push = pushes[p2];
          const pts = [];
          let bad = false;
          for (let q = 0; q < idxs.length; q++) {
            const k = idxs[q];
            const nv = normalAt(k);
            if (!nv) { bad = true; break; }
            const pt = [dense[k][0] + nv[0] * side * push, dense[k][1] + nv[1] * side * push];
            if (pt[0] < 3 || pt[0] > W - 3 || pt[1] < 3 || pt[1] > H - 3) { bad = true; break; }
            if (self._distPolys(pt[0], pt[1], polys) < 6.5) { bad = true; break; }
            pts.push(pt);
          }
          if (bad || pts.length < 3) continue;
          // 箭头翼尖校验（方向 = 段末切向，与 endDir 同向近似）
          const e0 = pts[pts.length - 1], e1 = pts[Math.max(0, pts.length - 3)];
          let dx = e0[0] - e1[0], dy = e0[1] - e1[1];
          const dl = hyp(dx, dy);
          if (dl < 1e-6) continue;
          dx /= dl; dy /= dl;
          const wt = wingTips(pts, [dx, dy]);
          let wok = true, md = 1e9;
          for (let w = 0; w < wt.length; w++) { const d = self._distPolys(wt[w][0], wt[w][1], polys); if (d < 6) { wok = false; break; } }
          if (!wok) continue;
          for (let k = 0; k < pts.length; k++) md = Math.min(md, self._distPolys(pts[k][0], pts[k][1], polys));
          const n0v = normalAt(idxs[0]);
          // 段末平滑切向 = 箭头方向（起笔段的行笔去向，v1.3.5）
          const ek = idxs[idxs.length - 1];
          const ea = dense[Math.max(0, ek - 3)], eb = dense[Math.min(dense.length - 1, ek + 1)];
          let etx = eb[0] - ea[0], ety = eb[1] - ea[1];
          const etl = hyp(etx, ety);
          const endDir = etl > 1e-6 ? [etx / etl, ety / etl] : null;
          return { pts: pts, n0: n0v ? [n0v[0] * side, n0v[1] * side] : [0, -1], minDist: md, mode: 'parallel', endDir: endDir };
        }
      }
      return null;
    };
    let arc = attempt(segIdx);
    if (!arc && segLen > 24) {
      // 起笔处太挤时缩短一段再试（仍在起笔位置，v1.3.5）
      const shortIdx = [];
      const cap = Math.max(18, segLen * 0.65);
      for (let k = 0; k < dense.length; k++) { shortIdx.push(k); if (cum[k] >= cap) break; }
      if (shortIdx.length >= 3 && shortIdx.length < segIdx.length) arc = attempt(shortIdx);
    }
    return arc;
  },
  _shortenArc(arc, cx, cy) {
    // v1.3.1：只保留原弧的末段约 1/4——从弧末向前量目标长度，起
    // 点在原采样点之间插值；新点列是原弧子集，不会新增侵入。原弧
    // 本身很短时保留 16px 最低可读长度，避免短笔只剩箭头头。新弧
    // 起点的外向向量按新起点切线重算，供序号圈落位。
    if (!arc || !arc.pts || arc.pts.length < 2) return arc;
    const pts = arc.pts;
    const lens = [0];
    let total = 0;
    for (let k = 1; k < pts.length; k++) {
      total += Math.sqrt((pts[k][0] - pts[k - 1][0]) * (pts[k][0] - pts[k - 1][0]) + (pts[k][1] - pts[k - 1][1]) * (pts[k][1] - pts[k - 1][1]));
      lens.push(total);
    }
    const target = Math.max(16, total * 0.25);
    if (!(total > target)) return arc;
    const cut = total - target;
    let si = 1;
    while (si < lens.length && lens[si] < cut) si++;
    const out = [];
    if (si < pts.length) {
      const segLen = lens[si] - lens[si - 1];
      const f = segLen > 1e-6 ? (cut - lens[si - 1]) / segLen : 0;
      out.push([pts[si - 1][0] + (pts[si][0] - pts[si - 1][0]) * f, pts[si - 1][1] + (pts[si][1] - pts[si - 1][1]) * f]);
      for (let k = si; k < pts.length; k++) out.push(pts[k]);
    }
    if (out.length < 2) return arc;
    const q = out[Math.min(out.length - 1, 2)];
    let tx = q[0] - out[0][0], ty = q[1] - out[0][1];
    const tl = Math.sqrt(tx * tx + ty * ty);
    let n0 = arc.n0;
    if (tl > 1e-6) {
      tx /= tl; ty /= tl;
      n0 = [-ty, tx];
      if (n0[0] * (out[0][0] - cx) + n0[1] * (out[0][1] - cy) < 0) n0 = [-n0[0], -n0[1]];
    }
    return { pts: out, n0: n0, minDist: arc.minDist, endMismatch: arc.endMismatch, mode: (arc.mode || 'full') + '+quarter' };
  },
  _badgePos(arc, polys, allPts, placed, cx, cy) {
    // 笔顺数字圈（v1.3.4，GO 定）：序号锚定在本弧的尾部——候选点
    // 全部绕弧尾 A（pts[0]）生成：弧线延长线后方、弧外侧法线
    // n0、两者斜组合，再加 16 方位环搜；硬校验同前（圈心距全字
    // 轮廓 ≥ 半径+6.5、不压任何弧线、与已放圈 ≥ 2r+8、且不比弧
    // 尾更靠近字心）；有效候选不再取「先到先得」：先限弧尾
    // 42px 内、按「离字心远（一律外侧） − 离弧尾距离（贴尾）」
    // 打分取最优，无位才放宽；两个序号因此不会再挤到同一侧。
    // 落位半径按 11 算。
    if (!arc || !arc.pts || !arc.pts.length) return null;
    const r = 11;
    const A = arc.pts[0], n0 = arc.n0 || [0, -1];
    const q = arc.pts[Math.min(3, arc.pts.length - 1)];
    let tx = A[0] - q[0], ty = A[1] - q[1];
    const tll = Math.sqrt(tx * tx + ty * ty);
    if (tll < 1e-6) { tx = 0; ty = -1; } else { tx /= tll; ty /= tll; }
    const cands = [];
    const push = function (x, y) { cands.push([x, y]); };
    const d0 = r + 10;
    push(A[0] + tx * d0, A[1] + ty * d0);
    push(A[0] + n0[0] * d0, A[1] + n0[1] * d0);
    push(A[0] + tx * d0 + n0[0] * r * 0.8, A[1] + ty * d0 + n0[1] * r * 0.8);
    push(A[0] + n0[0] * d0 + tx * r * 0.8, A[1] + n0[1] * d0 + ty * r * 0.8);
    for (let k = 0; k < 16; k++) {
      const a = k * Math.PI / 8;
      const dir = [Math.cos(a), Math.sin(a)];
      for (let extra = 0; extra <= 44; extra += 6) {
        push(A[0] + dir[0] * (d0 + extra), A[1] + dir[1] * (d0 + extra));
      }
    }
    const aDist = Math.sqrt((A[0] - cx) * (A[0] - cx) + (A[1] - cy) * (A[1] - cy));
    const self = this;
    const evaluate = function (cap) {
      let best = null, bestScore = -1e18;
      for (let ci = 0; ci < cands.length; ci++) {
        const bx = cands[ci][0], by = cands[ci][1];
        const dA = Math.sqrt((bx - A[0]) * (bx - A[0]) + (by - A[1]) * (by - A[1]));
        if (dA > cap) continue;
        if (bx < r + 2 || bx > W - r - 2 || by < r + 2 || by > H - r - 2) continue;
        const cDist = Math.sqrt((bx - cx) * (bx - cx) + (by - cy) * (by - cy));
        if (cDist < aDist - 6) continue;
        if (self._distPolys(bx, by, polys) < r + 6.5) continue;
        let ok = true;
        for (let k = 0; k < allPts.length; k++) {
          const dd = Math.sqrt((bx - allPts[k][0]) * (bx - allPts[k][0]) + (by - allPts[k][1]) * (by - allPts[k][1]));
          if (dd < r + 1.5) { ok = false; break; }
        }
        if (!ok) continue;
        for (let k = 0; k < placed.length; k++) {
          const dd = Math.sqrt((bx - placed[k][0]) * (bx - placed[k][0]) + (by - placed[k][1]) * (by - placed[k][1]));
          if (dd < 2 * r + 8) { ok = false; break; }
        }
        if (!ok) continue;
        const score = cDist - dA;
        if (score > bestScore) { bestScore = score; best = [bx, by]; }
      }
      return best;
    };
    // 先在弧尾 42px 内选（贴尾优先），实在无位才放宽到全部候选。
    return evaluate(42) || evaluate(1e9);
  },
  _geom() {
    // 本字几何（中线 / 轮廓 / 弧 / 序号位）只算一次并缓存：几何只与
    // 字有关、与当前笔无关，避免每次重绘重复候选搜索。
    const c = this._char;
    if (this._geomCache && this._geomCache.char === c.char) return this._geomCache;
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
    const polys = [];
    for (let i = 0; i < c.strokes.length; i++) { try { polys.push(this._pathPoly(c.strokes[i])); } catch (e) { polys.push([]); } }
    const arcs = [];
    for (let i = 0; i < c.medians.length; i++) {
      try {
        // v1.3.3：首选平行伴行弧（_parallelArc）；放不下才退回
        // v1.3 的分离短弧（_arcFor + _shortenArc）。
        let arc = null;
        try { arc = this._parallelArc(lines, polys, i, ccx, ccy); } catch (e2) { arc = null; }
        if (!arc) {
          const baseArc = this._arcFor(lines, polys, i, ccx, ccy);
          arc = baseArc ? this._shortenArc(baseArc, ccx, ccy) : null;
        }
        if (arc) {
          // 箭头头方向 = 本笔中线末段方向（自末点回溯 ≥10px 取向）：
          // v1.3.2 修正——短弧自身的弦向会偏（如「大」第 1 笔横，短
          // 弧弦向斜下、看着像方向错了），箭头只认行笔方向。起笔段
          // 平行弧（v1.3.5）自带段末切向 endDir，不在此覆盖。
          const line = lines[i], n = line.length;
          let ei = n - 2;
          while (ei > 0 && Math.sqrt((line[n - 1][0] - line[ei][0]) * (line[n - 1][0] - line[ei][0]) + (line[n - 1][1] - line[ei][1]) * (line[n - 1][1] - line[ei][1])) < 10) ei--;
          let vx = line[n - 1][0] - line[ei][0], vy = line[n - 1][1] - line[ei][1];
          const vl = Math.sqrt(vx * vx + vy * vy);
          if (vl > 1e-6 && !arc.endDir) arc.endDir = [vx / vl, vy / vl];
        }
        arcs.push(arc);
      } catch (e) { arcs.push(null); }
    }
    const allPts = [];
    for (let i = 0; i < arcs.length; i++) { if (arcs[i]) for (let j = 0; j < arcs[i].pts.length; j++) allPts.push(arcs[i].pts[j]); }
    const placed = [], badges = [];
    for (let i = 0; i < c.medians.length; i++) {
      let bp = null;
      try { bp = arcs[i] ? this._badgePos(arcs[i], polys, allPts, placed, ccx, ccy) : null; } catch (e) { bp = null; }
      if (bp) placed.push(bp);
      badges.push(bp || this._badgePosFallback(c.medians[i]));
    }
    this._geomCache = { char: c.char, lines: lines, polys: polys, arcs: arcs, badges: badges };
    return this._geomCache;
  },
  _arrow(ctx, arc, state, col) {
    // 笔顺弧 = 高亮标注（GO v1.3.2 定）：最亮绿、实心箭头头，三档
    // 一致；箭头头随后掠 / 半宽随弧长收小（上限 13 / 7.5，与序号
    // 落位校验的保守几何兼容）。箭头方向优先用 arc.endDir（本笔
    // 行笔方向，_geom 注入），短弧弦向不作数；缺失时退回弧末回
    // 溯 ≥5px 的局部切向。
    if (!arc || !arc.pts || arc.pts.length < 2) return;
    const pts = arc.pts, n = pts.length;
    let arcLen = 0;
    for (let j = 1; j < n; j++) arcLen += Math.sqrt((pts[j][0] - pts[j - 1][0]) * (pts[j][0] - pts[j - 1][0]) + (pts[j][1] - pts[j - 1][1]) * (pts[j][1] - pts[j - 1][1]));
    ctx.strokeStyle = col; ctx.lineWidth = 2.4;
    ctx.beginPath();
    for (let j = 0; j < n; j++) {
      if (j === 0) ctx.moveTo(pts[j][0], pts[j][1]); else ctx.lineTo(pts[j][0], pts[j][1]);
    }
    ctx.stroke();
    let dx = 0, dy = 0;
    if (arc.endDir) { dx = arc.endDir[0]; dy = arc.endDir[1]; }
    else {
      let ei = n - 2;
      while (ei > 0 && Math.sqrt((pts[n - 1][0] - pts[ei][0]) * (pts[n - 1][0] - pts[ei][0]) + (pts[n - 1][1] - pts[ei][1]) * (pts[n - 1][1] - pts[ei][1])) < 5) ei--;
      dx = pts[n - 1][0] - pts[ei][0]; dy = pts[n - 1][1] - pts[ei][1];
      const dl0 = Math.sqrt(dx * dx + dy * dy);
      if (dl0 < 0.5) return;
      dx /= dl0; dy /= dl0;
    }
    const tx = pts[n - 1][0], ty = pts[n - 1][1];
    const px = -dy, py = dx;
    const back = Math.min(13, Math.max(7, arcLen * 0.55));
    const half = Math.min(7.5, Math.max(3.5, arcLen * 0.28));
    const w1 = [tx - dx * back + px * half, ty - dy * back + py * half];
    const w2 = [tx - dx * back - px * half, ty - dy * back - py * half];
    ctx.beginPath();
    ctx.moveTo(tx, ty); ctx.lineTo(w1[0], w1[1]); ctx.lineTo(w2[0], w2[1]); ctx.closePath();
    ctx.fillStyle = col; ctx.fill();
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
    // 笔顺数字：与笔顺弧同属高亮标注（GO v1.3.2 定）——深色半透
    // 明底 + 最亮绿圈与数字，三档一致（位置由 _badgePos 定，落
    // 位半径仍按 11）。
    if (!pos) return;
    const bx = pos[0], by = pos[1];
    const r = 10;
    ctx.beginPath(); ctx.arc(bx, by, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(4,20,10,0.88)'; ctx.fill();
    ctx.strokeStyle = 'rgba(125,255,158,0.95)'; ctx.lineWidth = 1.4;
    ctx.beginPath(); ctx.arc(bx, by, r, 0, Math.PI * 2); ctx.stroke();
    ctx.fillStyle = 'rgba(125,255,158,0.95)';
    ctx.font = '11px sans-serif';
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
      // 几何（中线 / 轮廓 / 弧 / 序号位）按字缓存，见 _geom()
      const g = this._geom();
      const arcs = g.arcs;
      // 空心描边：路径只 stroke 不 fill（字帖式空心字，内部透黑）；
      // 笔画本体统一低亮度（GO v1.3.2 定：撇捺那种半透明淡绿效果，
      // 所有笔画、所有状态一致），高亮只给笔顺弧与序号。
      const cols = ['rgba(64,255,94,0.42)', 'rgba(64,255,94,0.42)', 'rgba(64,255,94,0.42)'];
      const widths = [1.5, 1.5, 1.5];
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
      // 弧线层（与字身分离的笔顺弧 + 弧末箭头头）+ 数字层（弧尾外侧，最后画）
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        const acol = '#7dff9e';
        this._arrow(ctx, arcs[i], state, acol);
      }
      for (let i = 0; i < c.strokes.length; i++) {
        const state = i < this._step ? 0 : (i === this._step ? 1 : 2);
        this._badge(ctx, g.badges[i], i + 1, state);
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
