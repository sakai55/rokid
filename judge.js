// judge.js —— 真境探针的共用判定管线（架构 §5 的探针形态）：
// 拍照 → Blob→data URL（arrayBuffer + 分块 btoa；浏览器式读 Blob
// 文本的接口不在运行时 API 清单里）→ LanguageModel 图片输入 →
// 结构化 JSON 解析校验。
// 判定耗时页要分段计时，所以拍照段与编码段在本模块内分别打点。
// 全部失败映射裸码：拍照段在本模块抛 codedError，LLM 段同理；
// 页面拿到 code 后经 err.js 的 fail() 落 lastError。
import wx from 'wx';
import { ERR, codedError, fail } from './err.js';

export var RESULTS_KEY = 'mud.probe.results.v1';

// ---------- 存储小工具（结果与记录都走 wx 存储） ----------

export function loadKey(key, fallback) {
  try {
    var v = wx.getStorageSync(key);
    if (v === '' || v === null || typeof v === 'undefined') return fallback;
    return (typeof v === 'string') ? JSON.parse(v) : v;
  } catch (e) { fail(ERR.LOAD, e); return fallback; }
}

export function saveKey(key, val) {
  try { wx.setStorageSync(key, val); return true; }
  catch (e) { return false; }
}

export function loadResults() {
  var r = loadKey(RESULTS_KEY, null);
  if (!r || typeof r !== 'object') r = {};
  if (!r.gesture) r.gesture = { trials: [] };
  if (!r.heading) r.heading = { trials: [], nods: 0, calibrated: false };
  if (!r.timing) r.timing = { runs: [] };
  return r;
}

export function saveResults(r) { return saveKey(RESULTS_KEY, r); }

export function speak(text) {
  try {
    if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
    speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
  } catch (e) { /* 播报失败静默：错误处理不制造新错误 */ }
}

// ---------- 拍照与编码 ----------

export async function blobToDataUrl(blob) {
  try {
    if (!blob || typeof blob.arrayBuffer !== 'function') throw codedError(ERR.ENCODE_TEXT, 'blob.arrayBuffer unavailable');
    var bytes = new Uint8Array(await blob.arrayBuffer());
    var bin = '';
    var CH = 0x8000;
    for (var i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
    return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
  } catch (e) {
    if (e && e.code) throw e;
    throw codedError(ERR.ENCODE_TEXT, String((e && e.message) || e));
  }
}

async function shrinkBlob(blob) {
  // 缩到宽 480 再编码，减小 LLM 图片体积；失败回退原图并标注。
  try {
    if (typeof createImageBitmap === 'undefined' || typeof document === 'undefined') throw new Error('no bitmap/canvas');
    var bmp = await createImageBitmap(blob);
    var scale = bmp.width > 480 ? (480 / bmp.width) : 1;
    if (scale === 1) return { blob: blob, note: '原图' };
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
    return { blob: out, note: '已缩图宽480' };
  } catch (e) {
    return { blob: blob, note: '缩图失败回退原图' };
  }
}

// 拍照 + 编码，返回 data URL 与分段耗时：
// photoMs = 打开相机流 + takePhoto；encodeMs = 缩图 + 转 data URL。
export async function takePhotoTimed(mode) {
  var nav = (typeof navigator !== 'undefined') ? navigator : null;
  if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw codedError(ERR.CAM_OPEN, 'getUserMedia unavailable');
  if (typeof ImageCapture === 'undefined') throw codedError(ERR.CAPTURE_NA, 'ImageCapture unavailable');
  var stream = null;
  var t0 = Date.now();
  try {
    try {
      stream = await nav.mediaDevices.getUserMedia({ video: true });
    } catch (e) {
      var n = (e && e.name) || '';
      if (n === 'NotAllowedError') throw codedError(ERR.CAM_DENIED, String(e.message || e));
      if (n === 'NotFoundError') throw codedError(ERR.CAM_MISSING, String(e.message || e));
      throw codedError(ERR.CAM_OPEN, String((e && e.message) || e));
    }
    var track = stream.getVideoTracks()[0];
    var cap = new ImageCapture(track);
    var blob = null;
    try { blob = await cap.takePhoto({ mode: mode || 'default' }); }
    catch (e) { throw codedError(ERR.PHOTO, String((e && e.message) || e)); }
    if (!blob) throw codedError(ERR.PHOTO, 'empty blob');
    var photoMs = Date.now() - t0;
    var t1 = Date.now();
    var shr = await shrinkBlob(blob);
    var url = await blobToDataUrl(shr.blob);
    return { url: url, bytes: blob.size, note: shr.note, photoMs: photoMs, encodeMs: Date.now() - t1 };
  } finally {
    try { if (stream) stream.getTracks().forEach(function (tr) { try { tr.stop(); } catch (e) {} }); } catch (e) {}
  }
}

// ---------- LLM 图片判定 ----------

var LLM_TIMEOUT_MS = 45000;

function withTimeout(p, ms) {
  return new Promise(function (resolve, reject) {
    var done = false;
    var tm = setTimeout(function () {
      if (!done) { done = true; reject(codedError(ERR.LLM_TIMEOUT, 'LLM no answer in ' + ms + 'ms')); }
    }, ms);
    p.then(function (v) { if (!done) { done = true; clearTimeout(tm); resolve(v); } },
           function (e) { if (!done) { done = true; clearTimeout(tm); reject(e); } });
  });
}

// 单轮图片判定：返回模型原文（解析在 parseJudgeJson）。超时 E6003。
export async function judgeImage(dataUrl, systemText, userText) {
  // 图片输入形状自检：data URL 不成形就是图片输入失败（E6005），
  // 不把这种问题混进 LLM 请求失败里。
  if (typeof dataUrl !== 'string' || dataUrl.indexOf('data:image/') !== 0 || dataUrl.length < 100) throw codedError(ERR.IMG_INPUT, 'malformed image data URL');
  if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) throw codedError(ERR.LLM_NA, 'LanguageModel unavailable');
  var avail = await LanguageModel.availability();
  if (avail !== 'available') throw codedError(ERR.LLM_NA, 'availability=' + avail);
  var session = null;
  try {
    session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: systemText }] });
    var out = await withTimeout(session.prompt([{ type: 'text', text: userText }, { type: 'image_url', image_url: { url: dataUrl } }]), LLM_TIMEOUT_MS);
    var text = String(out || '');
    if (!text.trim()) throw codedError(ERR.LLM_OUTPUT, 'empty LLM output');
    return text;
  } catch (e) {
    if (e && e.code) throw e;
    // 图片输入本身被拒与一般请求失败分不开时归请求失败；data URL
    // 构造问题在编码段已经拦下，这里不冒认 E6005。
    throw codedError(ERR.LLM_REQ, String((e && e.message) || e));
  } finally {
    try { if (session && session.destroy) session.destroy(); } catch (e) {}
  }
}

// 从模型原文里抽出 JSON 对象并解析：找不到/语法坏 E6009，
// 字段结构由各页再验（不合结构 E6011）。
export function parseJudgeJson(text) {
  var s = String(text || '');
  var a = s.indexOf('{');
  var b = s.lastIndexOf('}');
  if (a < 0 || b <= a) throw codedError(ERR.RESP_PARSE, 'no JSON object in LLM output');
  try { return JSON.parse(s.slice(a, b + 1)); }
  catch (e) { throw codedError(ERR.RESP_PARSE, String((e && e.message) || e)); }
}

export function clamp01(v) {
  var n = Number(v);
  if (isNaN(n)) return null;
  if (n < 0) return 0;
  if (n > 1) return 1;
  return n;
}
