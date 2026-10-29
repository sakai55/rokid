// judge.js —— 描红壳 PhotoJudge（v1）：拍照 → data URL → LLM 图片判定。
// 平台铁律：Blob 转 data URL 只走 arrayBuffer + 分块 btoa，不走浏览器
// 式读 Blob 文本的接口（教训见全局错误码表现场案例）；判定看不清
// 就如实返回 unclear，不编造。所有失败映射裸码，经 err.js 落盘。
// 本台无缩图步骤：原图直接编码。
import wx from 'wx';
import { ERR, codedError, fail } from './err.js';

var SLUG = 'trace-plating';
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
    var url = await blobToDataUrl(blob);
    return { url: url, bytes: blob.size, note: '原图直编' };
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
