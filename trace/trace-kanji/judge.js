// judge.js —— 描紅シェル PhotoJudge（v1）：撮影 → data URL → LLM 画像判定。
// 平台の鉄則：Blob から data URL への変換は arrayBuffer＋分割 btoa のみ（ランタイムに
// ブラウザ式の Blob テキスト読み取りはない。全艦隊エラーコード表の現場事例参照）。判定は
// 見えなければ正直に unclear を返し、作り話をしない。失敗はすべて裸コードに写像し err.js 経由で保存。
import wx from 'wx';
import { ERR, codedError, fail } from './err.js';

var SLUG = 'trace-kanji';
var VERSION = '1.1.0';

export function loadKey(key, fallback) {
  try {
    var v = wx.getStorageSync(key);
    if (v === '' || v === null || typeof v === 'undefined') return fallback;
    return (typeof v === 'string') ? JSON.parse(v) : v;
  } catch (e) { fail('E5002', e, SLUG, VERSION); return fallback; }
}

export function saveKey(key, val) {
  try { wx.setStorageSync(key, val); return true; }
  catch (e) { fail('E5001', e, SLUG, VERSION); return false; }
}

export function speak(text) {
  try {
    if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
    var u = new SpeechSynthesisUtterance(text);
    // 言語は必ず ja-JP を付ける：付けないとホストのロケール（中国語等）で
    // 日本語文が読まれ、中日混ざった発音になる（GO 2026-11-03 指摘）。
    try { u.lang = 'ja-JP'; } catch (e) {}
    speechSynthesis.speak(u, 'immediate');
  } catch (e) { /* 読み上げ失敗は沈黙：エラー処理が新しいエラーを作らない */ }
}

// ---- 練習の列（キュー）と記憶曲線 ----
// 列は PROG.queue（字の配列）。練習を終えた字は列から外れて後ろに
// 入り直す。入り直す距離は練習回数で伸びる（忘却曲線への対処）：
// 回数 1→3 字後ろ、2→5、3→9、4→16、5→24、6 回以上は最後尾。
export var QUEUE_LADDER = [3, 5, 9, 16, 24, 9999];
export function ensureQueue(p, allChars) {
  if (!Array.isArray(p.queue) || !p.queue.length) p.queue = allChars.slice();
  return p;
}
export function requeue(p, ch) {
  var q = (p.queue || []).filter(function (x) { return x !== ch; });
  var n = ((p.chars || {})[ch] || {}).count || 1;
  var d = QUEUE_LADDER[Math.min(n - 1, QUEUE_LADDER.length - 1)];
  var at = Math.min(d, q.length);
  q.splice(at, 0, ch);
  p.queue = q;
  return at;
}
export function finishChar(p, ch) {
  // 練習 1 回分を記録し（回数・日・最終字）、列の後ろに入れ直す。
  p.chars = p.chars || {}; p.days = p.days || {};
  var rec = p.chars[ch] || { count: 0 };
  rec.count = (rec.count || 0) + 1;
  rec.lastAt = new Date().toISOString();
  p.chars[ch] = rec;
  p.days[new Date().toISOString().slice(0, 10)] = true;
  p.lastChar = ch;
  requeue(p, ch);
  return rec.count;
}

// ---- 範字の描画（読み方ページの大字用） ----
// <text> の大字はホストのフォントで描かれ、中国語フォントの字形に
// なることがあるため、学ぶページと同じ分筆輪郭を Canvas に塗る。
function tracePath(ctx, d, S, OX, OY) {
  var toks = d.match(/[A-Za-z]|-?\d+\.?\d*/g); if (!toks) return;
  var i = 0, cmd = null, sx = 0, sy = 0;
  function num() { return parseFloat(toks[i++]); }
  function X(x) { return OX + x * S / 1024; }
  function Y(y) { return OY + (900 - y) * S / 1024; }
  ctx.beginPath();
  while (i < toks.length) {
    if (/[A-Za-z]/.test(toks[i])) cmd = toks[i++];
    if (cmd === 'M') { var mx = num(), my = num(); sx = mx; sy = my; ctx.moveTo(X(mx), Y(my)); cmd = 'L'; }
    else if (cmd === 'L') { ctx.lineTo(X(num()), Y(num())); }
    else if (cmd === 'C') { var a = num(), b = num(), c2 = num(), d2 = num(), ex = num(), ey = num(); ctx.bezierCurveTo(X(a), Y(b), X(c2), Y(d2), X(ex), Y(ey)); }
    else if (cmd === 'Q') { var qa = num(), qb = num(), qx = num(), qy = num(); ctx.quadraticCurveTo(X(qa), Y(qb), X(qx), Y(qy)); }
    else if (cmd === 'Z') { ctx.closePath(); }
    else break;
  }
}
export function drawGlyph(ctx, charData, S, OX, OY) {
  if (!ctx || !charData) return;
  charData.strokes.forEach(function (d) {
    tracePath(ctx, d, S, OX, OY);
    ctx.fillStyle = 'rgba(64,255,94,0.34)';
    ctx.fill();
    ctx.strokeStyle = 'rgba(125,255,158,0.85)';
    ctx.lineWidth = 1;
    ctx.stroke();
  });
  if (ctx.flush) ctx.flush();
}

export async function blobToDataUrl(blob) {
  try {
    if (!blob || typeof blob.arrayBuffer !== 'function') throw codedError('E2013', 'blob.arrayBuffer unavailable');
    var bytes = new Uint8Array(await blob.arrayBuffer());
    var bin = '';
    var CH = 0x8000;
    for (var i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
    return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
  } catch (e) {
    if (e && e.code) throw e;
    throw codedError('E2013', String((e && e.message) || e));
  }
}

async function shrinkBlob(blob) {
  // 幅 480 に縮小してから符号化し、LLM 画像の量を減らす。失敗したら原寸に戻して正直に注記。
  try {
    if (typeof createImageBitmap === 'undefined' || typeof document === 'undefined') throw new Error('no bitmap/canvas');
    var bmp = await createImageBitmap(blob);
    var scale = bmp.width > 480 ? (480 / bmp.width) : 1;
    if (scale === 1) return { blob: blob, note: '原寸' };
    var cv = document.createElement('canvas');
    cv.width = Math.max(1, Math.round(bmp.width * scale));
    cv.height = Math.max(1, Math.round(bmp.height * scale));
    var ctx = cv.getContext('2d');
    if (!ctx) throw new Error('no 2d ctx');
    ctx.drawImage(bmp, 0, 0, cv.width, cv.height);
    if (ctx.flush) ctx.flush();
    var out = await new Promise(function (res, rej) {
      try { cv.convertToBlob(function (b) { if (b) res(b); else rej(new Error('convert fail')); }, 'image/jpeg', 0.7); }
      catch (e) { rej(e); }
    });
    return { blob: out, note: '幅480に縮小' };
  } catch (e) {
    return { blob: blob, note: '縮小できず原寸のまま' };
  }
}

export async function takePhotoDataUrl(mode) {
  var nav = (typeof navigator !== 'undefined') ? navigator : null;
  if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw codedError('E1001', 'getUserMedia unavailable');
  if (typeof ImageCapture === 'undefined') throw codedError('E1003', 'ImageCapture unavailable');
  var stream = null;
  try {
    stream = await nav.mediaDevices.getUserMedia({ video: true });
  } catch (e) {
    var n = (e && e.name) || '';
    if (n === 'NotAllowedError') throw codedError('E1002', String(e.message || e));
    if (n === 'NotFoundError') throw codedError('E1007', String(e.message || e));
    throw codedError('E1001', String((e && e.message) || e));
  }
  try {
    var track = stream.getVideoTracks()[0];
    var cap = new ImageCapture(track);
    var blob = null;
    try { blob = await cap.takePhoto({ mode: mode || 'default' }); }
    catch (e) { throw codedError('E1009', String((e && e.message) || e)); }
    if (!blob) throw codedError('E1009', 'empty blob');
    var shr = await shrinkBlob(blob);
    var url = await blobToDataUrl(shr.blob);
    return { url: url, bytes: blob.size, note: shr.note };
  } finally {
    try { stream.getTracks().forEach(function (tr) { try { tr.stop(); } catch (e) {} }); } catch (e) {}
  }
}

// 一往復の画像判定：system＋テキスト＋画像 1 枚。モデルの原文を返す（解析はページ側）。
export async function judgePhoto(dataUrl, systemText, userText) {
  if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) throw codedError('E6001', 'LanguageModel unavailable');
  var avail = await LanguageModel.availability();
  if (avail !== 'available') throw codedError('E6001', 'availability=' + avail);
  var session = null;
  try {
    session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: systemText }] });
    var out = await session.prompt([{ type: 'text', text: userText }, { type: 'image_url', image_url: { url: dataUrl } }]);
    var text = String(out || '');
    if (!text.trim()) throw codedError('E6011', 'empty LLM output');
    return text;
  } catch (e) {
    if (e && e.code) throw e;
    throw codedError('E6002', String((e && e.message) || e));
  } finally {
    try { if (session && session.destroy) session.destroy(); } catch (e) {}
  }
}

export function reportFail(code, raw) { return fail(code, raw, SLUG, VERSION); }
export { ERR };
