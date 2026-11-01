// store.js —— 现实合影的存储 / 播报 / 语音输入（描红壳的轻量版）。
// 本台不拍照、不调大模型：合成靠系统截图（Hi Rokid App 的截图把
// 眼镜画面与现实景象合成一张图），本台只负责把叠加画对位置、
// 把纯净画面交出来。语音输入走宿主 SpeechRecognition（存在性
// 守卫 + 裸码兜底），识别不可用时预置句库照常可用。
import wx from 'wx';
import { fail } from './err.js';

var SLUG = 'trace-reality';
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

export function reportFail(code, raw) { return fail(code, raw, SLUG, VERSION); }

// 听一句话 → onOk(text)。不可用 / 失败走 onErr(裸码)，页面据此提示。
export function listenOnce(onOk, onErr) {
  var SR = (typeof SpeechRecognition !== 'undefined') ? SpeechRecognition : null;
  if (!SR) { reportFail('E3001', 'SpeechRecognition undefined'); if (onErr) onErr('E3001'); return false; }
  var rec = null;
  try {
    rec = new SR();
    rec.continuous = false;
    rec.interimResults = false;
    try { rec.lang = 'zh-CN'; } catch (e) { /* 宿主不认 lang 时忽略 */ }
  } catch (e) { reportFail('E3002', e); if (onErr) onErr('E3002'); return false; }
  var done = false;
  rec.onresult = function (ev) {
    if (done) return;
    var t = '';
    try {
      var r = ev.results[ev.results.length - 1];
      t = (r && r[0] && r[0].transcript) || '';
    } catch (e) { t = ''; }
    if (t) { done = true; try { rec.stop(); } catch (e) {} if (onOk) onOk(String(t).slice(0, 24)); }
  };
  rec.onerror = function (ev) {
    if (done) return; done = true;
    reportFail('E3003', (ev && ev.error) || 'asr error');
    if (onErr) onErr('E3003');
  };
  rec.onend = function () { if (!done) { done = true; if (onErr) onErr('E3003'); } };
  try { rec.start(); return true; }
  catch (e) { reportFail('E3002', e); if (onErr) onErr('E3002'); return false; }
}
