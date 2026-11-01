/**
 * trace-kana 学ぶページ筆順注釈 · 全量幾何 QC ゲート v1.1
 * （TR01 の QC ゲート v2 を継承し、仮名の筆形ポリゴン用に移植。
 * v1.1：C4 に「弧が覆う区間自体の総転向 > 50° なら急転区扱い」
 * を追加——ループ画の書き始め区間は大きく回るため、末端窓だけ
 * では急転区を捉えきれない。根拠は初回の抽拍 4 字。）
 *
 * 継承する不変量と帯域は TR01 v2 の定性結論のまま：
 * - C3 は二帯域：純回退 > 10px = FAIL、3〜10px = WARN 観察帯
 *   （基線が変われば抽拍＝学ぶページの撮影→拡大回読が必須）。
 * - C4：弧の末尾が中心線の急転区（±16px 窓で転向 > 50°）に落ち
 *   る場合は WARN（抽拍裁決）。平直な末尾で偏り > 40° は FAIL。
 * - C2b/C8（内蔵する番号）は WARN のみ——幾何的には解が無く、
 *   視覚的に解く妥協（暗い円盤で可読性を担保）。
 * - 平行帯の下限 13px（転回内側の圧縮を許容）。
 * 仮名固有の注意：polys は漢字の輪郭ではなく筆形リボン（中心線
 * ＋実測した太さ）。弧の押し出し量（中心線から 30/36/42px）に
 * 対しリボンの半幅は画面で約 8〜11px なので、C2 の余白は漢字版
 * より広く出るのが正常。逆に C6 の平行帯は中心線基準で不変。
 *
 * 使い方：node qc/check-geometry.js [--verbose]
 * 規則：学ぶページの幾何を変えたら必ず再実行する。FAIL = パッ
 * ク／提出禁止。WARN リストが基線（v1.0.0 初回出力）と変わった
 * ら、変わった字の学ぶページを撮影して拡大回読するまで未完。
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const VERBOSE = process.argv.includes('--verbose');

function loadChars() {
  let s = fs.readFileSync(path.join(ROOT, 'kana.js'), 'utf8');
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
function segDir(line, fromFrac, toFrac) {
  const L = polylineLen(line);
  const a = pointAt(line, L * fromFrac), b = pointAt(line, L * toFrac);
  return [b[0] - a[0], b[1] - a[1]];
}
function segDirAbs(line, fromPx, toPx) {
  const a = pointAt(line, fromPx), b = pointAt(line, toPx);
  return [b[0] - a[0], b[1] - a[1]];
}
function nearestTonLine(line, p, loPx, hiPx) {
  // 点 p 在中线上最近点的弧长位置（限定在 [loPx, hiPx] 内找）。
  let best = 1e18, bt = loPx, acc = 0;
  for (let i = 1; i < line.length; i++) {
    const a = line[i - 1], b = line[i];
    const vx = b[0] - a[0], vy = b[1] - a[1];
    const segL = Math.sqrt(vx * vx + vy * vy);
    let t = segL > 1e-9 ? ((p[0] - a[0]) * vx + (p[1] - a[1]) * vy) / (segL * segL) : 0;
    t = Math.max(0, Math.min(1, t));
    const cand = acc + segL * t;
    if (cand >= loPx && cand <= hiPx) {
      const d = dist(p, [a[0] + vx * t, a[1] + vy * t]);
      if (d < best) { best = d; bt = cand; }
    }
    acc += segL;
  }
  return bt;
}
function medianPortionSetback(line, arcPts, isParallel) {
  // 弧所覆中线段自身的回退量：取弧首末点在中线上的落点区间，
  // 以 2px 步长重采样该段中线后算 arcSetback。
  const L = polylineLen(line);
  const tFirst = nearestTonLine(line, arcPts[0], isParallel ? 0 : L * 0.4, isParallel ? L * 0.55 : L);
  const span = polylineLen(arcPts) * 1.7 + 12;
  const tLast = nearestTonLine(line, arcPts[arcPts.length - 1], Math.max(0, tFirst - 12), Math.min(L, tFirst + span));
  const from = Math.max(0, Math.min(tFirst, tLast) - 4);
  const to = Math.min(L, Math.max(tFirst, tLast) + 4);
  const pts = [];
  for (let t = from; t <= to; t += 2) pts.push(pointAt(line, t));
  if (pts.length < 2) return 0;
  pts.push(pointAt(line, to));
  return arcSetback(pts);
}
function endZoneTurn(line, arcPts) {
  // 弧末落点 ±16px 窗口内中线转向（> 50° = 急转区）。
  const L = polylineLen(line);
  const bt = nearestTonLine(line, arcPts[arcPts.length - 1], 0, L);
  const pre = segDirAbs(line, Math.max(0, bt - 16), Math.max(0, bt - 3));
  const post = segDirAbs(line, Math.min(L, bt + 3), Math.min(L, bt + 16));
  return angleDeg(pre, post);
}
function coverTurn(line, arcPts) {
  // 仮名版追加（v1.1）：弧が覆う中心線区間そのものの総転向。
  // ループ画の書き始めは「横へ進んでから急に下る」——区間自体が
  // 50° 以上回る場合、矢印の向きは単一の標量では定義できない
  // （末端 ±16px 窓では捉えきれない。ぬ・2／め・2／な・4 の
  // 実測が根拠：いずれも抽拍では「角の先の下向き」で視覚成立）。
  const L = polylineLen(line);
  const t0 = nearestTonLine(line, arcPts[0], 0, L);
  const t1 = nearestTonLine(line, arcPts[arcPts.length - 1], 0, L);
  const a = Math.min(t0, t1), b = Math.max(t0, t1);
  if (b - a < 8) return 0;
  const d0 = segDirAbs(line, a, Math.min(b, a + 10));
  const d1 = segDirAbs(line, Math.max(a, b - 10), b);
  return angleDeg(d0, d1);
}
function endTangentInfo(line, arcPts) {
  // 弧末点落点 bt；若 bt 处中线急转（转前/转后切线差 > 50°），
  // 返回转后前进方向，否则返回跨 bt 的普通切线。
  const L = polylineLen(line);
  const bt = nearestTonLine(line, arcPts[arcPts.length - 1], 0, L);
  const pre = segDirAbs(line, Math.max(0, bt - 12), Math.max(0, bt - 2));
  const post = segDirAbs(line, Math.min(L, bt + 2), Math.min(L, bt + 14));
  if (angleDeg(pre, post) > 50) return post;
  return segDirAbs(line, Math.max(0, bt - 10), Math.min(L, bt + 2));
}
function arcSetback(P) {
  const axis = [P[P.length - 1][0] - P[0][0], P[P.length - 1][1] - P[0][1]];
  const al = Math.sqrt(axis[0] ** 2 + axis[1] ** 2);
  if (al <= 1e-9) return 0;
  const ax = [axis[0] / al, axis[1] / al];
  let maxProg = -1e9, setback = 0;
  for (const p of P) {
    const pr = (p[0] - P[0][0]) * ax[0] + (p[1] - P[0][1]) * ax[1];
    if (pr > maxProg) maxProg = pr;
    if (maxProg - pr > setback) setback = maxProg - pr;
  }
  return setback;
}

function main() {
  const CHARS = loadChars();
  const pageDef = loadPageDef();
  const fails = [];
  const warns = [];
  const stats = { arcs: 0, parallel: 0, fallback: [], maxDirDev: 0, minClear: 1e9, minBadgePair: 1e9 };
  const fail = (id, msg) => fails.push(id + ' ' + msg);
  const warn = (id, msg) => warns.push(id + ' ' + msg);

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
      if (!arc) { fail('C1', tag + ' 无弧'); return; }
      const isParallel = arc.mode === 'parallel';
      if (isParallel) stats.parallel++; else stats.fallback.push(tag + '(' + arc.mode + ')');
      const line = g.lines[i];
      const medLen = polylineLen(line);
      const arcLen = polylineLen(arc.pts);
      // C2 弧侵入
      if (arc.minDist < stats.minClear) stats.minClear = arc.minDist;
      if (!(arc.minDist >= 6.5)) fail('C2', tag + ' 弧侵入 minDist=' + arc.minDist.toFixed(2) + ' < 6.5');
      // C3 回退分带：净回退 > 10 = FAIL；> 3 = WARN 观察带
      const sb = arcSetback(arc.pts);
      const msb = medianPortionSetback(line, arc.pts, isParallel);
      if (sb - msb > 10) fail('C3', tag + ' 弧回退 ' + sb.toFixed(1) + 'px 超出中线自身回退 ' + msb.toFixed(1) + 'px（大回退倒钩）');
      else if (sb > 3) warn('C3', tag + ' 回退观察带 ' + sb.toFixed(1) + 'px（中线自身 ' + msb.toFixed(1) + 'px；基线变化须抽拍）');
      // C4 箭头方向：平直末端偏 > 40° = FAIL；急转区末端降 WARN
      if (!arc.endDir) fail('C4', tag + ' 缺 endDir');
      else {
        const tan = endTangentInfo(line, arc.pts);
        const dev = angleDeg(arc.endDir, tan);
        if (dev > stats.maxDirDev) stats.maxDirDev = dev;
        if (dev > 40) {
          if (endZoneTurn(line, arc.pts) > 50 || coverTurn(line, arc.pts) > 50) warn('C4', tag + ' 急转区箭头偏 ' + dev.toFixed(1) + '°（抽拍裁决）');
          else fail('C4', tag + ' 箭头方向偏末端方向 ' + dev.toFixed(1) + '° > 40°');
        }
      }
      // C5 弧长（绝对值硬限；短比仅警告）
      if (arcLen < 12 || arcLen > 100) fail('C5', tag + ' 弧长 ' + arcLen.toFixed(1) + 'px 不在 [12,100]');
      else if (arcLen < 20) warn('C5', tag + ' 短弧 ' + arcLen.toFixed(1) + 'px（兜底/短笔）');
      const ratio = medLen > 1e-9 ? arcLen / medLen : 0;
      if (isParallel && ratio < 0.10) warn('C5', tag + ' 弧长比 ' + ratio.toFixed(2) + '（长笔短弧）');
      // C6 平行带
      if (isParallel) {
        for (const p of arc.pts) {
          const d = ptLineDist(p, line);
          if (d < 13 || d > 58) { fail('C6', tag + ' 平行带越界 ' + d.toFixed(1) + 'px'); break; }
        }
      }
      // C7/C8/C2b 序号
      const badge = g.badges[i];
      if (!badge) { fail('C7', tag + ' 无序号落位'); return; }
      const dTail = dist(badge, arc.pts[0]);
      if (dTail > 90) fail('C7', tag + ' 序号距弧尾 ' + dTail.toFixed(1) + 'px > 90（脱钩）');
      else if (dTail > 42) warn('C7', tag + ' 序号距弧尾 ' + dTail.toFixed(1) + 'px（放宽落位）');
      const dPoly = page._distPolys(badge[0], badge[1], g.polys);
      if (dPoly < 17.5) warn('C2b', tag + ' 内嵌序号 distPolys=' + dPoly.toFixed(1) + '（靠圆盘底色保可读，抽拍裁决）');
      if (dist(badge, cc) < dist(arc.pts[0], cc) - 6) warn('C8', tag + ' 序号比弧尾更靠字心（内嵌）');
      if (VERBOSE) console.log(tag, arc.mode, 'len', arcLen.toFixed(0), 'minDist', arc.minDist.toFixed(1), 'sb', sb.toFixed(1), 'msb', msb.toFixed(1));
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

  console.log('=== trace-kana 筆順注釈 QC ゲート v1.1 ===');
  console.log('弧总数 ' + stats.arcs + '（平行 ' + stats.parallel + ' / 兜底 ' + (stats.arcs - stats.parallel) + '）');
  console.log('最小弧-轮廓距离 ' + stats.minClear.toFixed(2) + 'px（门限 6.5）');
  console.log('最大箭头方向偏差（局部切线）' + stats.maxDirDev.toFixed(1) + '°（门限 40）');
  console.log('最小序号间隔 ' + stats.minBadgePair.toFixed(1) + 'px（门限 28）');
  console.log('兜底弧清单：' + (stats.fallback.join('、') || '无'));
  if (warns.length) { console.log('--- WARN ' + warns.length + '（已知妥协，抽拍回读覆盖）---'); warns.forEach(w => console.log('  ' + w)); }
  if (fails.length) {
    console.log('--- FAIL ' + fails.length + ' ---');
    fails.forEach(f => console.log('  ' + f));
    process.exit(1);
  }
  console.log('QC PASS');
}

main();
