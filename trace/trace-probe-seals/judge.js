// judge.js —— 描红壳 PhotoJudge（v1）：拍照 → data URL → LLM 图片判定。
// 平台铁律：Blob 转 data URL 只走 arrayBuffer + 分块 btoa（运行时没有
// 浏览器式读 Blob 文本的接口，教训见全局错误码表现场案例）；判定看
// 不清就如实返回 unclear，不编造。所有失败映射裸码，经 err.js 落盘。
import wx from 'wx';
import { ERR, codedError, fail } from './err.js';

var SLUG = 'trace-probe-seals';
var VERSION = '1.0.0';

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
    speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
  } catch (e) { /* 播报失败静默：错误处理不制造新错误 */ }
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
  // 缩到宽 480 再编码，减小 LLM 图片体积；失败回退原图并如实标注。
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

// 单轮图片判定：system + 文本 + 一张图，返回模型原文（解析在页面做）。
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
