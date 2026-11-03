<script def>
{"title": "Trace Kanji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, ensureQueue, finishChar } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 学ぶページ（描紅の主画面）：範字は全面——キャンバスがページを占
// め（464×252）、下の細い欄に「何画目／全何画（画の種類）＋その画
// の要点」と最小限の操作だけを置く。
// 漢字版の範字は TR01 と同じ空心描き：hanzi-writer-data の分筆輪
// 郭パスを stroke で描く（塗らない）。筆順は KanjiVG と全字照合し、
// 「右」（1・2画）・「田」（3・4画）・「生」（3・4画）は日本式の順に入れ替えてある。
// 大きさは机上描紅の距離の目安に合わせる——目から机まで約 40cm、
// 練習帳の一字約 9cm（視角約 12.8°）。弧と番号の注釈系と描画は
// TR01 v1.3.6 の凍結仕様をそのまま継承する：弧は書き始めの位置に
// 置き（中心線の開始区間に平行）、番号は弧の尾（＝書き始め）の外
// 側に固定し、矢印は運筆方向を指す。本体は全画統一の低輝度、高輝
// 度は注釈だけ。
// 画の位置はそのつど保存する（trace.kanji.learn）：プラットフォーム
// に常時点灯／wake lock の API はない（公式文書の全量確認で無し。
// README の「プラットフォームの境界」参照）。描紅中の画面消灯は
// Agent 側では防げないので、同じ字に再入したときに現在画へ戻るこ
// とで緩和する。
const TMP = 'trace.kanji.tmp';
const PROG = 'trace.trace-kanji.v1';
const LEARN = 'trace.kanji.learn'; // 画の位置の保存（画面消灯／再入時の復元用。進捗ではない）
const ACTS = ['前の画', '次の画', '要点を聞く', '書き終えたらチェック', '戻る BACK'];
const W = 464, H = 252, S = 236, OX = 110, OY = 11;

export default {
  data: {
    status: '学ぶ：一画ずつよく見て、紙にまねて書く（うなずき＝この字を終える）',
    barLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.1.0'
  },
  onLoad() {
    this._focus = 1; this._step = 0; this._useMedians = false;
    const t = loadKey(TMP, { char: CHARS[0].char });
    this._counted = (t && t.counted) || '';
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    // 画の位置の復元：常時点灯の API はない（README の境界参照）。
    // 画面消灯／終了のあとで同じ字に再入したら、保存した画の位置へ
    // 戻る。字が変わっていたら（一回目の画から）始める。
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
      barLine: c.char + '（' + c.reading + '）' + (this._step + 1) + '画目 / 全 ' + c.strokes.length + '画（' + c.types[this._step] + '）：' + c.tips[this._step],
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enter で実行、うなずき＝この字を終える）'
    });
    if (speakTip) speak(c.tips[this._step]);
    const self = this;
    setTimeout(function () { self._draw(); }, 60);
    setTimeout(function () { self._draw(); }, 420);
  },
  _X(x) { return OX + x * S / 1024; },
  _Y(y) { return OY + (900 - y) * S / 1024; },
  _path(ctx, d) {
    // パスは M / L / C / Q / Z のみ（絶対座標）。仮名データは M / L / Z のみ
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
    // 点と線分の距離（弧と番号の配置チェック用）
    const abx = bx - ax, aby = by - ay;
    const t0 = abx * abx + aby * aby;
    let t = t0 > 0 ? ((px - ax) * abx + (py - ay) * aby) / t0 : 0;
    t = Math.max(0, Math.min(1, t));
    const qx = ax + abx * t - px, qy = ay + aby * t - py;
    return Math.sqrt(qx * qx + qy * qy);
  },
  _pathPoly(d) {
    // 画の SVG パス → 輪郭ポリゴンの点列（キャンバス座標、曲線は 8 分割で標本化）。
    // 弧の侵入判定（点が画の内側に入っていないか）に使う
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
    // レイ法による、点が多角形の内側かどうかの判定
    let inside = false;
    for (let a = 0, b = poly.length - 1; a < poly.length; b = a++) {
      const xa = poly[a][0], ya = poly[a][1], xb = poly[b][0], yb = poly[b][1];
      if (((ya > py) !== (yb > py)) && (px < (xb - xa) * (py - ya) / (yb - ya) + xa)) inside = !inside;
    }
    return inside;
  },
  _distPolys(px, py, polys) {
    // 点から字全体の輪郭までの最小距離。どれかの輪郭の内側なら -1 を返す（硬い制約の判定）
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
    // 筆順の弧 v1.3.0（字から離した簡略弧、硬い制約で検証）：候補 =
    // 二次ベジェ（中心線の始／中／終の 3 点を各自の外向き法線へ押し
    // 出す）と三次ベジェ（1/3・2/3 の二つの制御点）。外側（点ごとに
    // 字の中心から離れる向き）と内側を試し、押し出し量は 22〜38px。
    // 候補は標本点ごと＋矢印の翼端を _distPolys で検証：輪郭に入る、
    // または輪郭まで 6.5px 未満なら却下。14px 以上が合格。選択順 =
    // 向きの合う合格弧（弧の末尾の向きと画の終わりの運筆方向のずれ
    // 50° 以内）→ 向きの合う使用可能弧（6.5 以上）→ 短縮片段 → 終
    // 端の小弧。戻り値は { pts 弧の点列, n0 弧の始点の外向き単位ベクトル }。
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
    // 画の終わりの運筆方向：終点から 10px 以上さかのぼって向きを取る（末尾が短いと単区間の向きは不安定）
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
    // 短縮段位：複数の押し出し量の曲線の上で、侵入しない最長区間を探す（始点／終点を含むものを優遇）
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
    // 向きの合う短縮片段を、向きの違う完全な弧より優先する。それも無理なら終端の小弧で受ける
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
    // 筆順の弧 v1.3.3（GO 指定）：v1.2 の形に戻す——弧はその画の
    // 中心線に平行に沿う（中心線を Catmull-Rom で再標本化し、点ご
    // とに法線方向へ押し出す）。区間の長さ = 中心線の全長 × 0.35
    // （26〜56px に制限）。v1.3.5（GO 決定）：弧は書き始めの位置に
    // 置く——中心線の開始区間を取り、弧の尾が書き始め（番号はここ
    // に固定）、矢印は運筆方向を指す（endDir は区間末尾の平滑化し
    // た接線）。v1.2 の失敗は弧が輪郭に貼り付いた（リボン状）こと。
    // 本版は v1.3 の硬い検証を維持：区間全体の標本点＋矢印の翼端を
    // 点ごとに _distPolys ≥ 6.5 かつキャンバス内と検証し、押し出
    // し量 30/36/42 を両側で試す。全滅なら null を返し、_geom が
    // v1.3 の短い弧で受ける。
    const line = lines[idx];
    if (!line || line.length < 2) return null;
    const self = this;
    const hyp = function (a, b) { return Math.sqrt(a * a + b * b); };
    // 中心線はまず弧長で均一に再標本化する（約 9px に 1 点）：元の
    // 中心線は点の間隔がばらばら（一画の中で 58→246 設計 px）で、
    // Catmull-Rom は間隔の急変箇所で行き過ぎて輪を作る——ずらした
    // 弧の始点がそのために折り返して返し（かぎ）になった（「大」
    // 第 1 画、v1.3.6 で実地に特定）。均一化すれば曲線は輪を作らない。
    const uline = [line[0]];
    let acc = 0;
    for (let k = 1; k < line.length; k++) {
      let ax = line[k - 1][0], ay = line[k - 1][1];
      const bx = line[k][0], by = line[k][1];
      let d = hyp(bx - ax, by - ay);
      while (d > 1e-6 && acc + d >= 9) {
        const f = (9 - acc) / d;
        ax = ax + (bx - ax) * f; ay = ay + (by - ay) * f;
        uline.push([ax, ay]);
        d = hyp(bx - ax, by - ay);
        acc = 0;
      }
      acc += d;
    }
    if (uline[uline.length - 1] !== line[line.length - 1]) uline.push(line[line.length - 1]);
    // Catmull-Rom 再標本化（端点は複製で補う）。72 点＋点ごとの接線
    const P = [uline[0]].concat(uline, [uline[uline.length - 1]]);
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
    // 書き始めの区間：中心線の始点から segLen の長さの一段（v1.3.5）
    const segIdx = [];
    for (let k = 0; k < dense.length; k++) { segIdx.push(k); if (cum[k] >= segLen) break; }
    const rawN = [];
    for (let k = 0; k < dense.length; k++) {
      const a = dense[Math.max(0, k - 1)], b = dense[Math.min(dense.length - 1, k + 1)];
      const tx = b[0] - a[0], ty = b[1] - a[1];
      const tl = hyp(tx, ty);
      rawN.push(tl < 1e-6 ? null : [-ty / tl, tx / tl]);
    }
    // 法線の平滑化（前後 3 標本点の平均、v1.3.4）：弧の形を画自
    // 身の流れに沿わせ、標本点の間隔のばらつきで偽の曲がりを作らない。
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
          // 矢印の翼端の検証（向き = 区間末尾の接線、endDir とほぼ同方向）
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
          // 区間末尾の平滑化した接線 = 矢印の向き（書き始め区間の運筆の行き先、v1.3.5）
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
      // 書き始めが窮屈なら区間を短くして再挑戦（位置は書き始めのまま、v1.3.5）
      const shortIdx = [];
      const cap = Math.max(18, segLen * 0.65);
      for (let k = 0; k < dense.length; k++) { shortIdx.push(k); if (cum[k] >= cap) break; }
      if (shortIdx.length >= 3 && shortIdx.length < segIdx.length) arc = attempt(shortIdx);
    }
    return arc;
  },
  _detangle(arc) {
    // 弧の尾の返し取り（v1.3.6、GO 指摘「大」第 1 画の弧の尾に余
    // 分な返し）：書き始めの中心線には止めの小さな曲がりがあり、
    // ずらした弧の最初の数歩が法線の急転に引かれて返しになる。弧
    // の最初の一歩と「弧の頭→第 4 点」の向きのなす角が 60° を超
    // えたら、弧の頭の点を一つずつ削る（最大 4 点）。向きが素直に
    // なったら止める。通常の弧は滑らかに始まるので発動しない。
    if (!arc || !arc.pts) return arc;
    const pts = arc.pts;
    let guard = 0;
    while (pts.length > 4 && guard < 4) {
      guard++;
      const ax = pts[1][0] - pts[0][0], ay = pts[1][1] - pts[0][1];
      const bx = pts[3][0] - pts[0][0], by = pts[3][1] - pts[0][1];
      const la = Math.sqrt(ax * ax + ay * ay), lb = Math.sqrt(bx * bx + by * by);
      if (la < 1e-6 || lb < 1e-6) break;
      if ((ax * bx + ay * by) / (la * lb) < 0.5) pts.shift(); else break;
    }
    return arc;
  },
  _shortenArc(arc, cx, cy) {
    // v1.3.1：元の弧の末尾約 1/4 だけを残す——弧の終わりから目標
    // の長さを測り、始点は元の標本点の間で補間する。新しい点列は
    // 元の弧の部分集合なので、新しい侵入は生じない。元の弧自体が
    // 短いときは読み取れる最低の長さ 16px を保ち、短い画が矢印の
    // 頭だけにならないようにする。新しい始点の外向きベクトルは新
    // しい始点の接線から計算し直し、番号の円の配置に使う。
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
    // 筆順の番号の円（v1.3.4、GO 決定）：番号はその弧の尾に固定
    // する——候補点はすべて弧の尾 A（pts[0]）の周りに作る：弧の延
    // 長線の後方、弧の外側の法線 n0、その斜めの組み合わせ、さらに
    // 16 方位の環状探索。硬い検証は従来通り（円の中心から字全体
    // の輪郭まで半径＋6.5 以上、どの弧も押さえない、配置済みの円
    // と 2r+8 以上、弧の尾より字の中心に近くない）。有効な候補は
    // 「先着順」にはしない：まず弧の尾から 42px 以内に限り、「字
    // の中心から遠い（常に外側）− 弧の尾からの距離（尾に密着）」
    // で点数を付けて最良を選ぶ。場所が無ければ範囲を広げる。二つ
    // の番号が同じ側に寄ることはなくなる。配置の半径は 11 で計算。
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
    // まず弧の尾から 42px 以内で選ぶ（尾への密着を優先）。本当に場所がなければ全候補に広げる。
    return evaluate(42) || evaluate(1e9);
  },
  _geom() {
    // その字の幾何（中心線／輪郭／弧／番号の位置）は一度だけ計算
    // してキャッシュする：幾何は字だけで決まり、現在の画には依ら
    // ない。再描画のたびに候補探索を繰り返さないため。
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
        // v1.3.3：まず平行に沿う弧（_parallelArc）。置けなければ
        // v1.3 の離れた短い弧（_arcFor + _shortenArc）に退く。
        let arc = null;
        try { arc = this._parallelArc(lines, polys, i, ccx, ccy); } catch (e2) { arc = null; }
        if (!arc) {
          const baseArc = this._arcFor(lines, polys, i, ccx, ccy);
          arc = baseArc ? this._shortenArc(baseArc, ccx, ccy) : null;
        }
        if (arc) arc = this._detangle(arc);
        if (arc) {
          // 矢印の頭の向き = その画の中心線の末尾区間の向き（終点
          // から 10px 以上さかのぼって取る）：v1.3.2 の修正——短い
          // 弧自身の弦の向きはぶれる（例「大」第 1 画の横：短い弧の
          // 弦が斜め下を向き、向きが間違って見えた）。矢印は運筆方
          // 向だけを信じる。書き始め区間の平行弧（v1.3.5）は区間末
          // 尾の接線 endDir を持つので、ここでは上書きしない。
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
    // 筆順の弧 = 高輝度の注釈（GO v1.3.2 決定）：最も明るい緑、
    // 塗りの矢印の頭、三つの状態で同一。矢印の頭の後方長／半幅は
    // 弧の長さで縮む（上限 13／7.5、番号配置の検証の保守的な幾何
    // と両立）。矢印の向きは arc.endDir（その画の運筆方向、_geom
    // が注入）を優先し、短い弧の弦の向きは使わない。無ければ弧の
    // 末尾から 5px 以上さかのぼった局所接線に退く。
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
    // 弧がないとき（中心線データ不足など）の番号の円の位置：書き始めの点のそば、字の中心と反対向き
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
    // 筆順の番号：筆順の弧と同じ高輝度の注釈（GO v1.3.2 決定）——暗い半透明
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
  prevTap() { if (this._step > 0) { this._step--; this._render(true); } else { this.setData({ status: '最初の画です', evt: 'EVT: step at first' }); speak('最初の画です'); } },
  nextTap() {
    const c = this._char;
    if (this._step < c.strokes.length - 1) { this._step++; this._render(true); }
    else { this.setData({ status: '最後の画です：紙に字全体を書き終えてから、チェックへ', evt: 'EVT: step at last' }); speak('最後の画です。紙に字全体を書き終えてから、チェックに行ってください'); }
  },
  speakTap() { speak(this._char.tips[this._step]); this.setData({ evt: 'EVT: speak tip' }); },
  verifyTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  finishTap() {
    // うなずき＝この字を終える：練習 1 回分を記録し、字を列の後ろへ
    // （回数が多い字ほど遠く。judge.js の finishChar）。記録済み
    // （チェック側で数えた）なら数え直さず、戻るだけ。
    if (this._counted !== this._char.char) {
      const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
      ensureQueue(p, CHARS.map(function (c) { return c.char; }));
      finishChar(p, this._char.char);
      if (saveKey(PROG, p)) {
        this._counted = this._char.char;
        const t = loadKey(TMP, {}); t.counted = this._char.char; saveKey(TMP, t);
        speak(this._char.char + '、練習しました');
      }
    }
    try { wx.navigateBack({}); } catch (e) {}
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.prevTap();
    else if (this._focus === 1) this.nextTap();
    else if (this._focus === 2) this.speakTap();
    else if (this._focus === 3) this.verifyTap();
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(false); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.finishTap(); },
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
      <button class="act" bindtap="actTap" data-idx="0">前の画</button>
      <button class="act hot" bindtap="actTap" data-idx="1">次の画</button>
      <button class="act" bindtap="actTap" data-idx="2">要点を聞く</button>
      <button class="act" bindtap="actTap" data-idx="3">チェックへ</button>
      <button class="act" bindtap="actTap" data-idx="4">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kanji · 範字データ hanzi-writer-data（筆順は KanjiVG 照合） · 数字＝筆順、弧の矢印＝書き始めの向き</text>
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
