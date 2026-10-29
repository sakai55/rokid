// logq.js —— 真境探针的诊断日志回传客户端。
// 形态照 AV11 v1.2.0 的 logq.js：事件先落本地队列（localStorage
// 'mudprobe_logq'，上限 100 条、最旧先丢），再批量 POST 到前门 /log。
// 打包版眼镜没有任何日志回程通道，结果单页之外这条事件流就是探针
// 的第二反馈面（反馈协议见 README）。
//
// 配置纪律（config.js，大表哥 channel.js 成例）：domain + key 两件
// 都在 config.js 里。启用条件 = CHANNEL_KEY 不是占位符 且 BASE_URL
// 非空；缺任一件时整个客户端完全 no-op：log() 丢弃一切、flushLog()
// 不发、不碰存储——探针功能完全不受影响，也不出任何提示。
//
// 安全契约：所有导出全程 try/catch，永不抛错、永不阻塞主流程；发送
// 是 fire-and-forget，失败就把队列留给下一个 flush 时机（各站完成 /
// 进结果单页 / 下次启动）。
// 隐私：事件只带短步名、裸错误码与短数值摘要；照片与 data URL 永不
// 入日志（raw 以 'data:' 开头直接丢弃，raw 一律截断 200 字）。服务
// 端上限：单次 ≤50 条。
import { BASE_URL, CHANNEL_KEY } from './config.js';

export var APP_VERSION = '1.0.0';

var SLUG = 'real-mud-probe';
var QUEUE_KEY = 'mudprobe_logq';
var QUEUE_MAX = 100;
var BATCH_MAX = 50;
var RAW_MAX = 200;

var _queue = null;
var _session = '';
var _sending = false;

function _enabled() {
  return !!CHANNEL_KEY && CHANNEL_KEY !== 'PASTE_CHANNEL_KEY_HERE' && !!BASE_URL;
}

function _logUrl() { return BASE_URL + '/log'; }

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
  } catch (e) { /* 队列落盘只是尽力而为 */ }
}

function _newSession() {
  var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  var r = '';
  for (var i = 0; i < 4; i++) r += chars.charAt(Math.floor(Math.random() * chars.length));
  return Date.now().toString(36) + '-' + r;
}

// 启动入口（app.js onLaunch）：先 flush 上一轮残留队列（保留其原
// session），再开本轮 session 并记 start 事件。
export function initLog() {
  try {
    if (!_enabled()) return;
    _load();
    flushLog();
    _session = _newSession();
    log('start', '', APP_VERSION);
  } catch (e) { /* 日志永不能拖垮启动 */ }
}

// 记一条事件。step：短 ASCII 步名；code：裸错误码或 ''；raw：短摘要。
export function log(step, code, raw) {
  try {
    if (!_enabled()) return;
    _load();
    var r = raw == null ? '' : String(raw);
    if (r.indexOf('data:') === 0) return;
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
  } catch (e) { /* 日志永不抛错进主流程 */ }
}

// fire-and-forget 批量发送：按 session 分组、单批 ≤50、最旧先发。
// 成功才删已发记录；任何失败保留队列等下一个 flush 时机。
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
    fetch(_logUrl(), {
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
      if (ok && _queue.length) flushLog();
    }).catch(function () {
      _sending = false;
    });
  } catch (e) { _sending = false; }
}
