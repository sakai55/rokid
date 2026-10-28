// Stop Motion Studio — diagnostic log return client （诊断日志回传试点）.
//
// Runtime events are queued locally (localStorage 'av11_logq', capped
// at 100 entries, oldest dropped first) and POSTed in batches to the
// front door's /log endpoint. This pilot exists because a packaged
// agent has NO log channel back from a real device: the on-screen
// error codes plus this event stream are the whole debug surface.
//
// CONFIG — the only deployment values in this project live here, at
// the top of this file (the fleet's channel-config discipline):
// LOG_URL is the front-door /log endpoint; CHANNEL_KEY is the
// glasses-side key of that front door. The repo stores ONLY the
// placeholder. Before packaging, the deployer replaces the placeholder
// with the real key inside Studio; a filled file is never pushed back
// to the repo, and the key is refilled after every fresh import.
// While CHANNEL_KEY is still the placeholder the whole client is a
// NO-OP: log() drops every event, flushLog() sends nothing and no
// storage is touched — which is also the review build's off state.
//
// Safety contract: every export is fully try/catch wrapped. Logging
// must never throw, never block and never alter the main flow; sends
// are fire-and-forget, and a failed send simply keeps the queue for
// the next flush point (take finish / play-page entry / next launch).
//
// Privacy: events carry only short step ids, bare error codes and
// short raw notes (error text, counts, mode strings). Photo data and
// recognised speech text are never logged; a raw string starting with
// 'data:' is dropped outright, and raw is truncated to 200 chars
// regardless. Server-side caps: ts 40 / code 8 / step 80 / raw 300,
// at most 50 events per POST.

export var LOG_URL = 'https://rokidp.datumoj.com/log';
export var CHANNEL_KEY = 'PASTE_CHANNEL_KEY_HERE';
export var APP_VERSION = '1.2.0';

var SLUG = 'stop-motion-studio';
var QUEUE_KEY = 'av11_logq';
var QUEUE_MAX = 100;
var BATCH_MAX = 50;
var RAW_MAX = 200;

var _queue = null;   // null = not loaded yet; records {ts, code, step, raw, s}
var _session = '';   // this launch's session id ('' until initLog)
var _sending = false;

function _enabled() {
  return !!CHANNEL_KEY && CHANNEL_KEY !== 'PASTE_CHANNEL_KEY_HERE';
}

function _load() {
  if (_queue) return;
  _queue = [];
  try {
    if (typeof localStorage !== 'undefined') {
      var v = localStorage.getItem(QUEUE_KEY);
      if (v) {
        var arr = JSON.parse(v);
        if (arr && arr.length) _queue = arr;
      }
    }
  } catch (e) { _queue = []; }
}

function _save() {
  try {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(QUEUE_KEY, JSON.stringify(_queue || []));
    }
  } catch (e) { /* queue persistence is best-effort only */ }
}

function _newSession() {
  var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  var r = '';
  for (var i = 0; i < 4; i++) r += chars.charAt(Math.floor(Math.random() * chars.length));
  return Date.now().toString(36) + '-' + r;
}

// Launch entry (app.js onLaunch): FIRST flush whatever a previous run
// left in the queue (those records keep their own session id), then
// open this run's session and record the start event.
export function initLog() {
  try {
    if (!_enabled()) return;
    _load();
    flushLog();
    _session = _newSession();
    log('start', '', APP_VERSION);
  } catch (e) { /* logging must never break launch */ }
}

// Append one event. step: short ASCII id ('start' / 'begin' / 'frame0'
// / 'mode' / 'fail' / 'finish' / 'play'). code: a bare error code or
// ''. raw: short diagnostic note only (see the privacy note above).
export function log(step, code, raw) {
  try {
    if (!_enabled()) return;
    _load();
    var r = raw == null ? '' : String(raw);
    if (r.indexOf('data:') === 0) return; // never log payload-shaped data
    if (r.length > RAW_MAX) r = r.slice(0, RAW_MAX);
    var c = (code && /^E\d{4}$/.test(code)) ? code : '';
    _queue.push({
      ts: new Date().toISOString(),
      code: c,
      step: String(step || '').slice(0, 80),
      raw: r,
      s: _session
    });
    while (_queue.length > QUEUE_MAX) _queue.shift();
    _save();
  } catch (e) { /* logging must never throw into the main flow */ }
}

// Fire-and-forget drain: POSTs the queue batch by batch (at most 50
// events, grouped by the session that recorded them, oldest first).
// Success removes exactly the sent records; any failure (network,
// non-200, no fetch) keeps them for the next flush point.
export function flushLog() {
  try {
    if (!_enabled() || _sending) return;
    if (typeof fetch !== 'function') return;
    _load();
    if (!_queue.length) return;
    _sending = true;
    var s0 = _queue[0].s || '';
    var batch = [];
    for (var i = 0; i < _queue.length && batch.length < BATCH_MAX; i++) {
      if ((_queue[i].s || '') !== s0) break;
      batch.push(_queue[i]);
    }
    var events = batch.map(function (rec) {
      return { ts: rec.ts, code: rec.code, step: rec.step, raw: rec.raw };
    });
    fetch(LOG_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-channel-key': CHANNEL_KEY },
      body: JSON.stringify({ slug: SLUG, session: s0, events: events })
    }).then(function (resp) {
      var ok = !!resp && (resp.ok === true || resp.status === 200);
      if (ok) {
        for (var j = 0; j < batch.length; j++) {
          var ix = _queue.indexOf(batch[j]);
          if (ix >= 0) _queue.splice(ix, 1);
        }
        _save();
      }
      _sending = false;
      if (ok && _queue.length) flushLog(); // drain the next batch / session
    }).catch(function () {
      _sending = false; // keep the queue; the next flush point retries
    });
  } catch (e) { _sending = false; }
}
