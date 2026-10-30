// storage-probe shared helpers: the failure funnel, the cross-session
// marker, the results record, availability ping and formatting.
//
// Persisted keys — every key this agent ever writes starts with
// "sprobe." and tests only ever remove their own keys:
//   sprobe.marker  {v, firstTs, lastTs, launches}  cross-session marker
//   sprobe.last    {v, ts, systems:{ls,wx,opfs}}   latest run results
//   sprobe.error   {v, slug, ver, code, raw, ts}   last coded failure
//   sprobe.ping    scratch availability probe key (removed immediately)
//   sprobe.ls.* / sprobe.wx.*  ramp payload keys (removed after each run)
// The clear-all entry points of either KV store are NEVER called
// anywhere in this project — a probe must not destroy the data it
// measures, and the marker/results keys must survive the ramps.

import { errLabel } from './err.js';

export var VER = '1.0.0';
export var SLUG = 'storage-probe';
export var CHUNK = 32768;           // 32 KiB ramp step (payload chars)
export var CAP = 16 * 1024 * 1024;  // 16 MiB ramp ceiling
export var MAXCH = CAP / CHUNK;     // 512 chunks

// ---------------------------------------------------------------- errors

var lastError = null;

export function getLastError() { return lastError; }

export function errText(e) { return String((e && e.message) || e); }

export function errName(e) { return (e && e.name) || ''; }

export function isQuota(e) {
  var s = errText(e) + ' ' + errName(e);
  return /quota/i.test(s);
}

// The single failure funnel: every coded failure in the agent goes
// through here, is kept in memory and persisted to sprobe.error with
// slug + version. Never throws — the storage layer itself may be the
// thing that is broken.
export function fail(code, raw) {
  var rec = {
    v: 1, slug: SLUG, ver: VER, code: code, label: errLabel(code),
    raw: String(raw == null ? '' : raw).slice(0, 200), ts: Date.now()
  };
  lastError = rec;
  try {
    if (typeof localStorage !== 'undefined') localStorage.setItem('sprobe.error', JSON.stringify(rec));
  } catch (e) { /* the funnel must never become a second failure */ }
  return rec;
}

export function readLastError() {
  if (lastError) return lastError;
  try {
    if (typeof localStorage !== 'undefined') {
      var s = localStorage.getItem('sprobe.error');
      if (s) { lastError = JSON.parse(s); return lastError; }
    }
  } catch (e) {}
  return null;
}

// ------------------------------------------------- cross-session marker

var markerCache = null;

// Read the old marker first (the home page shows it), then write the
// updated one. Runs once per process; app.js onLaunch calls it, the
// home page falls back to it if the app hook did not fire.
export function initMarker() {
  if (markerCache) return markerCache;
  var prev = null;
  try {
    if (typeof localStorage !== 'undefined') {
      var s = localStorage.getItem('sprobe.marker');
      if (s) prev = JSON.parse(s);
    }
  } catch (e) { fail('E5002', errText(e)); }
  var now = Date.now();
  var cur = {
    v: 1,
    firstTs: (prev && prev.firstTs) || now,
    lastTs: now,
    launches: ((prev && prev.launches) || 0) + 1
  };
  try {
    if (typeof localStorage !== 'undefined') localStorage.setItem('sprobe.marker', JSON.stringify(cur));
  } catch (e) { fail(isQuota(e) ? 'E5003' : 'E5001', errText(e)); }
  markerCache = { prev: prev, cur: cur };
  return markerCache;
}

export function markerInfo() { return markerCache || initMarker(); }

// ------------------------------------------------------- results record

export function readLast() {
  try {
    if (typeof localStorage !== 'undefined') {
      var s = localStorage.getItem('sprobe.last');
      if (s) return JSON.parse(s);
    }
  } catch (e) {}
  return null;
}

export function saveSysResult(sys, result) {
  var all = readLast() || { v: 1, ts: 0, systems: {} };
  if (!all.systems) all.systems = {};
  all.systems[sys] = result;
  all.ts = Date.now();
  try {
    if (typeof localStorage !== 'undefined') localStorage.setItem('sprobe.last', JSON.stringify(all));
  } catch (e) { fail(isQuota(e) ? 'E5003' : 'E5001', errText(e)); }
  return all;
}

// Short display lines for one system's stored result. Shared by the
// station pages (their own system) and the results page (all three),
// so the photographed results sheet uses the exact same wording.
export function describeResult(sys, r) {
  if (!r) return ['未测'];
  var lines = [];
  if (r.available === false) {
    lines.push('不可用' + (r.errorCode ? ' · ' + r.errorCode : ''));
    if (r.errMsg) lines.push('原文：' + r.errMsg);
    return lines;
  }
  if (sys === 'opfs') {
    lines.push('配额 ' + fmtBytes(r.quota) + ' · 已用 ' + fmtBytes(r.usage));
    lines.push('持久化 ' + (r.persisted === true ? '已持久' : (r.persisted === false ? '未持久' : '未知')) +
      ' · 申请 ' + (r.persistResult === true ? '通过' : (r.persistResult === false ? '未通过' : '未知')));
    if (r.writtenBytes > 0 || r.verified) {
      lines.push('写入 ' + fmtBytes(r.writtenBytes) + (r.verified ? ' · 读回校验通过' : ' · 未完成校验'));
    }
    if (r.capped) lines.push('写入达 16 MiB 上限，未触顶');
  } else {
    lines.push('往返 ' + (r.roundtrip ? '通过' : '失败' + (r.errorCode ? ' · ' + r.errorCode : '')));
    if (r.capped) lines.push('容量 ≥16 MiB 未触顶');
    else if (typeof r.capacityBytes === 'number') lines.push('容量 ' + fmtBytes(r.capacityBytes) + (r.aborted ? '（已中止）' : ''));
  }
  if (r.errorCode && r.roundtrip !== false) lines.push('错误 ' + r.errorCode + (r.errMsg ? ' · ' + r.errMsg : ''));
  if (r.ts) lines.push(fmtDT(r.ts));
  return lines;
}

// ------------------------------------------------------ availability

// Non-destructive existence probe for localStorage: writes only its
// own scratch key and removes it immediately.
export function lsAvailable() {
  if (typeof localStorage === 'undefined') return { ok: false, code: 'E5005', raw: 'localStorage undefined' };
  try {
    localStorage.setItem('sprobe.ping', '1');
    var v = localStorage.getItem('sprobe.ping');
    localStorage.removeItem('sprobe.ping');
    return v === '1' ? { ok: true } : { ok: false, code: 'E5002', raw: 'ping readback mismatch' };
  } catch (e) {
    try { localStorage.removeItem('sprobe.ping'); } catch (e2) {}
    return { ok: false, code: 'E5005', raw: errText(e) };
  }
}

// OPFS existence is a pure typeof guard — no call is made.
export function opfsGuard() {
  return typeof navigator !== 'undefined' && !!navigator.storage &&
    typeof navigator.storage.getDirectory === 'function';
}

// ------------------------------------------------------------ formatting

export function tick() {
  return new Promise(function (res) { setTimeout(res, 0); });
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
