#!/usr/bin/env node
/**
 * TR01 学字页笔顺标注 · 全量几何 QC 门（GO 2026-11-01 立）
 *
 * 背景：v1.1–v1.3.5 的每一轮改版都在「大」字上验收通过、却在别的
 * 笔画上带出新毛病（缎带弧 / 箭头向偏 / 序号脱尾 / 两号同侧 /
 * 弧尾倒钩）。本门把历轮缺陷写成不变量，对全部 20 字 × 77 笔的
 * _geom() 输出逐项机检；任一项 FAIL 即 exit 1，不许打包/交付。
 *
 * 用法：node qc/check-geometry.js [--verbose]
 * 规则：改学字页几何（learn/index.ink 的 _geom/_parallelArc/
 * _arcFor/_shortenArc/_badgePos/_detangle）必须重跑本门并全过，
 * 同时重拍抽查字（永・人・水・心）学字页人工回读后才算完成。
 *
 * 检查项（阈值即历轮定版口径，不得放宽来迁就失败）：
 *  C1 覆盖   每笔必有弧（无弧 = FAIL）
 *  C2 侵入   弧采样点距全字轮廓 minDist ≥ 6.5；序号圈心 ≥ 17.5
 *  C3 回环   弧点列沿自身首末轴的进度不得倒退 > 2px（倒钩/回环）
 *  C4 方向   箭头 endDir 与该笔对应段的行笔方向夹角 ≤ 40°
 *            （平行弧比起笔段方向、兜底弧比收笔段方向）
 *  C5 弧长   弧长 ∈ [20, 90]px，且为该笔中线长的 [0.15, 0.65]
 *  C6 平行带 平行弧每点距本笔中线 ∈ [16, 58]px（贴笔伴行带）
 *  C7 贴尾   序号距弧尾 ≤ 42px（放宽落位须 ≤ 60 且计入清单）
 *  C8 外侧   序号离字心 ≥ 弧尾离字心 − 6（不许落进字内）
 *  C9 间隔   同字序号两两 ≥ 28px
 *  C10 兜底  非平行弧占比 ≤ 25%，且逐笔列明
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const VERBOSE = process.argv.includes('--verbose');

function loadChars() {
  let s = fs.readFileSync(path.join(ROOT, 'chars.js'), 'utf8');
  s = s.replace(/export\s+(var|const|let)\s+CHARS/, 'var CHARS').replace(/export\s*\{[^}]*\}/, '');
  const mod = { exports: {} };
  new Function('module', s + '\nmodule.exports = CHARS;')(mod);
  return mod.exports;
}

function loadPageDef() {
  const ink = fs.readFileSync(path.join(ROOT, 'pages/learn/index.ink'), 'utf8');
  let setup = ink.match(/<script setup>([\s\S]*?)<\/script>/)[1];
  setup = setup.split('\n').filter(l => !l.startsWith('import ')).join('\n');
  setup = setup.replace('export default {', 'module.exports = {');
  setup = 'const loadKey=()=>null, saveKey=()=>{}, speak=()=>{};\n' + setup;
  const mod = { exports: {} };
  new Function('CHARS', 'module', setup)(loadChars(), mod);
  return mod.exports;
}

const dist = (a, b) => Math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2);
function polylineLen(pts) { let L = 0; for (let i = 1; i < pts.length; i++) L += dist(pts[i - 1], pts[i]); return L; }
function pointAt(pts, target) {
  let L = 0;
  for (let i = 1; i < pts.length; i++) {
    const d = dist(pts[i - 1], pts[i]);
    if (L + d >= target) { const f = d > 1e-9 ? (target - L) / d : 0; return [pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * f, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * f]; }
    L += d;
  }
  return pts[pts.length - 1];
}
function ptSegDist(p, a, b) {
  const vx = b[0] - a[0], vy = b[1] - a[1];
  const wx = p[0] - a[0], wy = p[1] - a[1];
  const c1 = vx * wx + vy * wy;
  const c2 = vx * vx + vy * vy;
  const t = c2 > 1e-9 ? Math.max(0, Math.min(1, c1 / c2)) : 0;
  return dist(p, [a[0] + vx * t, a[1] + vy * t]);
}
function ptLineDist(p, line) { let m = 1e9; for (let i = 1; i < line.length; i++) m = Math.min(m, ptSegDist(p, line[i - 1], line[i])); return m; }
function angleDeg(u, v) {
  const lu = Math.sqrt(u[0] ** 2 + u[1] ** 2), lv = Math.sqrt(v[0] ** 2 + v[1] ** 2);
  if (lu < 1e-9 || lv < 1e-9) return 180;
  const c = Math.max(-1, Math.min(1, (u[0] * v[0] + u[1] * v[1]) / (lu * lv)));
  return Math.acos(c) * 180 / Math.PI;
}

function main() {
  const CHARS = loadChars();
  const pageDef = loadPageDef();
  const fails = [];
  const warns = [];
  const stats = { arcs: 0, parallel: 0, fallback: [], maxSetback: 0, maxDirDev: 0, minClear: 1e9, maxBadgeTail: 0, minBadgePair: 1e9 };
  const fail = (id, msg) => fails.push(id + ' ' + msg);

  for (const c of CHARS) {
    const page = Object.create(pageDef);
    page._char = c; page._geomCache = null;
    const g = page._geom();
    let mnx = 1e9, mny = 1e9, mxx = -1e9, mxy = -1e9;
    for (const ln of g.lines) for (const p of ln) { mnx = Math.min(mnx, p[0]); mxx = Math.max(mxx, p[0]); mny = Math.min(mny, p[1]); mxy = Math.max(mxy, p[1]); }
    const cc = [(mnx + mxx) / 2, (mny + mxy) / 2];

    g.arcs.forEach((arc, i) => {
      const tag = c.char + '·第' + (i + 1) + '笔';
      stats.arcs++;
      // C1 覆盖
      if (!arc) { fail('C1', tag + ' 无弧'); return; }
      const isParallel = arc.mode === 'parallel';
      if (isParallel) stats.parallel++; else stats.fallback.push(tag + '(' + arc.mode + ')');
      const line = g.lines[i];
      const medLen = polylineLen(line);
      const arcLen = polylineLen(arc.pts);
      // C2 侵入（弧）
      if (arc.minDist < stats.minClear) stats.minClear = arc.minDist;
      if (!(arc.minDist >= 6.5)) fail('C2', tag + ' 弧侵入 minDist=' + arc.minDist.toFixed(2) + ' < 6.5');
      // C3 回环/倒钩
      const P = arc.pts;
      const axis = [P[P.length - 1][0] - P[0][0], P[P.length - 1][1] - P[0][1]];
      const al = Math.sqrt(axis[0] ** 2 + axis[1] ** 2);
      if (al > 1e-9) {
        const ax = [axis[0] / al, axis[1] / al];
        let maxProg = -1e9, setback = 0;
        for (const p of P) {
          const pr = (p[0] - P[0][0]) * ax[0] + (p[1] - P[0][1]) * ax[1];
          if (pr > maxProg) maxProg = pr;
          if (maxProg - pr > setback) setback = maxProg - pr;
        }
        if (setback > stats.maxSetback) stats.maxSetback = setback;
        if (setback > 2.0) fail('C3', tag + ' 弧回退 ' + setback.toFixed(1) + 'px > 2（倒钩/回环）');
      }
      // C4 方向
      if (!arc.endDir) { fail('C4', tag + ' 缺 endDir'); }
      else {
        const segDir = isParallel
          ? (() => { const a = pointAt(line, medLen * 0.05), b = pointAt(line, medLen * 0.40); return [b[0] - a[0], b[1] - a[1]]; })()
          : (() => { const a = pointAt(line, medLen * 0.60), b = pointAt(line, medLen * 0.98); return [b[0] - a[0], b[1] - a[1]]; })();
        const dev = angleDeg(arc.endDir, segDir);
        if (dev > stats.maxDirDev) stats.maxDirDev = dev;
        if (dev > 40) fail('C4', tag + ' 箭头方向偏差 ' + dev.toFixed(1) + '° > 40°');
      }
      // C5 弧长
      const ratio = medLen > 1e-9 ? arcLen / medLen : 0;
      if (arcLen < 20 || arcLen > 90) fail('C5', tag + ' 弧长 ' + arcLen.toFixed(1) + 'px 不在 [20,90]');
      if (ratio < 0.15 || ratio > 0.65) fail('C5', tag + ' 弧长比 ' + ratio.toFixed(2) + ' 不在 [0.15,0.65]');
      // C6 平行带
      if (isParallel) {
        for (const p of P) {
          const d = ptLineDist(p, line);
          if (d < 16 || d > 58) { fail('C6', tag + ' 平行带越界 ' + d.toFixed(1) + 'px（点 ' + p.map(v => v.toFixed(0)).join(',') + '）'); break; }
        }
      }
      // C7/C8 序号
      const badge = g.badges[i];
      if (!badge) { fail('C7', tag + ' 无序号落位'); return; }
      const dTail = dist(badge, P[0]);
      if (dTail > stats.maxBadgeTail) stats.maxBadgeTail = dTail;
      if (dTail > 60) fail('C7', tag + ' 序号距弧尾 ' + dTail.toFixed(1) + 'px > 60');
      else if (dTail > 42) warns.push('C7 ' + tag + ' 序号距弧尾 ' + dTail.toFixed(1) + 'px（放宽落位）');
      const dBadgeC = dist(badge, cc), dTailC = dist(P[0], cc);
      if (dBadgeC < dTailC - 6) fail('C8', tag + ' 序号比弧尾更靠字心（' + dBadgeC.toFixed(0) + ' < ' + dTailC.toFixed(0) + '-6）');
      const dPoly = page._distPolys(badge[0], badge[1], g.polys);
      if (dPoly < 17.5) fail('C2', tag + ' 序号侵入 distPolys=' + dPoly.toFixed(1) + ' < 17.5');
      if (VERBOSE) console.log(tag, arc.mode, 'len', arcLen.toFixed(0), 'minDist', arc.minDist.toFixed(1), 'badge', badge.map(v => v.toFixed(0)).join(','));
    });
    // C9 序号间隔
    for (let i = 0; i < g.badges.length; i++) for (let j = i + 1; j < g.badges.length; j++) {
      if (!g.badges[i] || !g.badges[j]) continue;
      const d = dist(g.badges[i], g.badges[j]);
      if (d < stats.minBadgePair) stats.minBadgePair = d;
      if (d < 28) fail('C9', c.char + ' 序号 ' + (i + 1) + '/' + (j + 1) + ' 间隔 ' + d.toFixed(1) + 'px < 28');
    }
  }
  // C10 兜底占比
  const fbShare = stats.arcs ? (stats.arcs - stats.parallel) / stats.arcs : 0;
  if (fbShare > 0.25) fail('C10', '兜底弧占比 ' + (fbShare * 100).toFixed(0) + '% > 25%');

  console.log('=== TR01 笔顺标注 QC 门 ===');
  console.log('弧总数 ' + stats.arcs + '（平行 ' + stats.parallel + ' / 兜底 ' + (stats.arcs - stats.parallel) + '）');
  console.log('最小弧-轮廓距离 ' + stats.minClear.toFixed(2) + 'px（门限 6.5）');
  console.log('最大弧回退 ' + stats.maxSetback.toFixed(2) + 'px（门限 2）');
  console.log('最大箭头方向偏差 ' + stats.maxDirDev.toFixed(1) + '°（门限 40）');
  console.log('最大序号-弧尾距离 ' + stats.maxBadgeTail.toFixed(1) + 'px（门限 42/放宽 60）');
  console.log('最小序号间隔 ' + stats.minBadgePair.toFixed(1) + 'px（门限 28）');
  console.log('兜底弧清单：' + (stats.fallback.join('、') || '无'));
  if (warns.length) { console.log('--- WARN ' + warns.length + ' ---'); warns.forEach(w => console.log('  ' + w)); }
  if (fails.length) {
    console.log('--- FAIL ' + fails.length + ' ---');
    fails.forEach(f => console.log('  ' + f));
    process.exit(1);
  }
  console.log('QC PASS');
}

main();
