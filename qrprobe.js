// qr-capacity-probe shared helpers: the failure funnel, the QR encoder
// wrapper (vendored qrcode-generator 1.4.4 in lib/qrcode.js, UTF-8 byte
// mode), the deterministic ladder payloads, OPFS storage of the
// rendered codes, the BarcodeDetector wrapper and the persisted
// results record.
//
// The exchange model under test: agent A encodes text into a QR image,
// the image is stored as a file, BarcodeDetector reads it back. The
// rendered images live in this agent's own OPFS directory "qrprobe/"
// as qr-<EC>-<bytes>.png. Nothing here touches the network, and the
// system media library is deliberately NOT used (its operation API is
// undocumented — registry open point, CAPABILITIES section 5 item 12).
//
// Persisted keys (localStorage, prefix "qrprobe."):
//   qrprobe.last   {v, ts, detector, encode{L,M,Q,H}, file{L,M,Q,H}, camera}
//   qrprobe.error  {v, slug, ver, code, raw, ts}   last coded failure

import qrcode from './lib/qrcode.js';
import { errLabel } from './err.js';

export var VER = '1.0.0';
export var SLUG = 'qr-capacity-probe';
export var EC_LEVELS = ['L', 'M', 'Q', 'H'];
export var LADDER = [128, 256, 512, 768, 1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 2953];
export var CJK_TEXT = '二维码是眼镜本地数据交换的信箱，存进去，读回来。';
export var OPFS_DIR = 'qrprobe';

var PATTERN = 'QRPROBE-0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ-';

// ------------------------------------------------------------ payloads

// Deterministic ladder payload: the same size always regenerates the
// exact same string, so the decode stations can verify rawValue
// byte-for-byte without persisting the payloads themselves.
export function payloadFor(n) {
  var s = '';
  while (s.length < n) s += PATTERN;
  return s.slice(0, n);
}

export function utf8Len(s) {
  var n = 0;
  for (var i = 0; i < s.length; i++) {
    var c = s.charCodeAt(i);
    if (c < 0x80) n += 1;
    else if (c < 0x800) n += 2;
    else if (c >= 0xD800 && c <= 0xDBFF) { n += 4; i++; }
    else n += 3;
  }
  return n;
}

// If text is one of this probe's own payloads, return its byte size
// (ladder size, or the CJK sample's UTF-8 byte count); otherwise 0.
export function matchPayload(text) {
  for (var i = 0; i < LADDER.length; i++) {
    if (text === payloadFor(LADDER[i])) return LADDER[i];
  }
  if (text === CJK_TEXT) return utf8Len(CJK_TEXT);
  return 0;
}

// -------------------------------------------------------------- errors

var lastError = null;

export function getLastError() { return lastError; }

export function errText(e) { return String((e && e.message) || e); }

export function errName(e) { return (e && e.name) || ''; }

// The single failure funnel: every coded failure in the agent goes
// through here, is kept in memory and persisted to qrprobe.error with
// slug + version. Never throws.
export function fail(code, raw) {
  var rec = {
    v: 1, slug: SLUG, ver: VER, code: code, label: errLabel(code),
    raw: String(raw == null ? '' : raw).slice(0, 200), ts: Date.now()
  };
  lastError = rec;
  try {
    if (typeof localStorage !== 'undefined') localStorage.setItem('qrprobe.error', JSON.stringify(rec));
  } catch (e) { /* the funnel must never become a second failure */ }
  return rec;
}

export function readLastError() {
  if (lastError) return lastError;
  try {
    if (typeof localStorage !== 'undefined') {
      var s = localStorage.getItem('qrprobe.error');
      if (s) { lastError = JSON.parse(s); return lastError; }
    }
  } catch (e) {}
  return null;
}

// ------------------------------------------------------- results state

export function emptyState() {
  return {
    v: 1, ts: 0, detector: null,
    encode: { L: null, M: null, Q: null, H: null },
    file: { L: null, M: null, Q: null, H: null },
    camera: { best: null, last: null }
  };
}

export function readState() {
  try {
    if (typeof localStorage !== 'undefined') {
      var s = localStorage.getItem('qrprobe.last');
      if (s) {
        var st = JSON.parse(s);
        if (st && st.v === 1 && st.encode && st.file && st.camera) return st;
      }
    }
  } catch (e) {}
  return emptyState();
}

export function patchState(fn) {
  var st = readState();
  try { fn(st); } catch (e) {}
  st.ts = Date.now();
  try {
    if (typeof localStorage !== 'undefined') localStorage.setItem('qrprobe.last', JSON.stringify(st));
  } catch (e) { fail('E5001', errText(e)); }
  return st;
}

// -------------------------------------------------------------- encoder

// Encode text at one EC level in byte mode (UTF-8 via the vendored
// override). Auto version up to 40; make() throws on length overflow —
// that throw IS the encode-ceiling signal. Version is derived from the
// module count: version = (modules - 17) / 4.
export function encodeQR(text, ec) {
  var qr = qrcode(0, ec);
  qr.addData(text, 'Byte');
  qr.make();
  var modules = qr.getModuleCount();
  return { qr: qr, modules: modules, version: (modules - 17) / 4 };
}

// Largest integer module scale that fits (modules + 8 quiet-zone
// modules) into a w x h box; never below 1.
export function fitScale(modules, w, h) {
  var total = modules + 8;
  var s = Math.floor(Math.min(w, h) / total);
  return s < 1 ? 1 : s;
}

// Draw a code onto any 2d context: dark modules in black, light
// modules and the 4-module quiet zone in the brightest green (the
// fleet's "white" role — decoders read luminance, and agent UI is
// green-only). Returns the drawn size in px.
export function drawQR(ctx, qr, scale, ox, oy) {
  var modules = qr.getModuleCount();
  var total = modules + 8;
  var size = total * scale;
  var x0 = ox || 0, y0 = oy || 0;
  ctx.fillStyle = '#7dff9e';
  ctx.fillRect(x0, y0, size, size);
  ctx.fillStyle = '#000000';
  for (var r = 0; r < modules; r++) {
    for (var c = 0; c < modules; c++) {
      if (qr.isDark(r, c)) ctx.fillRect(x0 + (c + 4) * scale, y0 + (r + 4) * scale, scale, scale);
    }
  }
  try { if (ctx.flush) ctx.flush(); } catch (e) {}
  return size;
}

// Render a code to a PNG Blob through an offscreen Canvas (the
// stream-probe-proven path). Returns null when the host lacks the
// Canvas constructor or convertToBlob (Ink 0.19+) — callers record
// that honestly instead of failing the encode result.
export async function qrToBlob(qr, scale) {
  if (typeof Canvas === 'undefined') return null;
  var modules = qr.getModuleCount();
  var size = (modules + 8) * scale;
  var cv = new Canvas(size, size);
  var ctx = cv.getContext('2d');
  drawQR(ctx, qr, scale, 0, 0);
  if (typeof cv.convertToBlob !== 'function') return null;
  return await cv.convertToBlob({ type: 'image/png' });
}

// ------------------------------------------------------------- detector

export function detectorGuard() {
  return typeof BarcodeDetector !== 'undefined';
}

// Availability + supported formats + whether qr_code is among them.
// Never throws; the failure shape carries the mapped code.
export async function probeDetector() {
  if (!detectorGuard()) {
    return { available: false, formats: null, qr: false, errCode: 'E7009', raw: 'BarcodeDetector undefined' };
  }
  var formats = null;
  try {
    formats = await BarcodeDetector.getSupportedFormats();
  } catch (e) {
    return { available: true, formats: null, qr: false, errCode: 'E7004', raw: errText(e) };
  }
  var qr = !!(formats && formats.indexOf('qr_code') >= 0);
  return {
    available: true, formats: formats, qr: qr,
    errCode: qr ? '' : 'E7005',
    raw: qr ? '' : 'qr_code not in getSupportedFormats()'
  };
}

export function makeDetector() {
  return new BarcodeDetector({ formats: ['qr_code'] });
}

// ---------------------------------------------------------------- OPFS

export function opfsGuard() {
  return typeof navigator !== 'undefined' && !!navigator.storage &&
    typeof navigator.storage.getDirectory === 'function';
}

export function fileName(ec, n) { return 'qr-' + ec + '-' + n + '.png'; }

export async function opfsSave(ec, n, blob) {
  var root = await navigator.storage.getDirectory();
  var dir = await root.getDirectoryHandle(OPFS_DIR, { create: true });
  var fh = await dir.getFileHandle(fileName(ec, n), { create: true });
  var w = await fh.createWritable();
  await w.write(blob);
  await w.close();
  return blob.size;
}

export async function opfsRead(ec, n) {
  var root = await navigator.storage.getDirectory();
  // NOTE: the options argument is always passed, even when empty —
  // the Ink bridge rejects one-argument handle calls ("Error calling
  // function with 1 argument(s) while 2 where expected", first seen
  // in the web preview; the fleet's storage-probe always passed it).
  var dir = await root.getDirectoryHandle(OPFS_DIR, {});
  var fh = await dir.getFileHandle(fileName(ec, n), {});
  return await fh.getFile();
}

export function isNotFound(e) {
  if (errName(e) === 'NotFoundError') return true;
  return /not\s*found|no such file/i.test(errText(e));
}

export function storageCodeFor(e, writing) {
  var nm = errName(e);
  if (nm === 'NotSupportedError') return 'E5005';
  if (nm === 'QuotaExceededError' || /quota/i.test(errText(e))) return 'E5003';
  return writing ? 'E5001' : 'E5002';
}

// -------------------------------------------------------------- helpers

export function tick() {
  return new Promise(function (res) { setTimeout(res, 0); });
}

export function withTimeout(p, ms, tag) {
  return Promise.race([p, new Promise(function (_, rej) {
    setTimeout(function () { rej(new Error('timeout ' + tag)); }, ms);
  })]);
}

export function fmtBytes(n) {
  if (typeof n !== 'number' || n === null || isNaN(n)) return '未知';
  if (n >= 1048576) return (n / 1048576).toFixed(2) + ' MiB';
  if (n >= 1024) return (n / 1024).toFixed(1) + ' KiB';
  return n + ' B';
}

function pad2(x) { return (x < 10 ? '0' : '') + x; }

export function fmtDT(ts) {
  if (!ts) return '—';
  var d = new Date(ts);
  return (d.getMonth() + 1) + '-' + pad2(d.getDate()) + ' ' +
    pad2(d.getHours()) + ':' + pad2(d.getMinutes()) + ':' + pad2(d.getSeconds());
}
