<script def>
{
  "title": "Stop Motion Shoot"
}
</script>

<script setup>
import wx from 'wx';
import { store, resetSession } from '../../store.js';
import { errLine, fullCode, codedError } from '../../err.js';

var WORKSKEY = 'av11_works';
var FPS = 12;
var TARGET = 120;
var MEM_TARGET = 40;
var IV_MS = 1000;
var SAFETY_SEC = 180;
var ENC_TIMEOUT_MS = 600;
var BUSY_WATCHDOG_MS = 2500;
var MAX_CONSEC_FAILS = 10;

function sget(k, page) {
  try { if (typeof localStorage !== 'undefined') { var v = localStorage.getItem(k); if (v) return JSON.parse(v); } } catch (e) { if (page) page._recordErr('E5002', e, true); }
  try { var w = wx.getStorageSync(k); if (w) return (typeof w === 'string') ? JSON.parse(w) : w; } catch (e) { if (page) page._recordErr('E5002', e, true); }
  return null;
}
// Returns null on success, or the failure Error (for E5001/E5003 mapping).
function sset(k, v) {
  var lastErr = null;
  try { if (typeof localStorage !== 'undefined') { localStorage.setItem(k, JSON.stringify(v)); return null; } } catch (e) { lastErr = e; }
  try { wx.setStorageSync(k, v); return null; } catch (e) { lastErr = e; }
  return lastErr || new Error('storage write failed');
}
function reasonLabel(r) {
  return r === 'voice' ? '说「退出」结束' : (r === 'target' ? '拍够了' : (r === 'time' ? '满 3 分钟了' : (r === 'back' ? '双击结束' : (r === 'errors' ? '连续失败停拍' : ''))));
}
function errText(e) { return String((e && e.message) || e); }
function isQuota(e) { var s = errText(e) + ' ' + ((e && e.name) || ''); return /quota/i.test(s); }

export default {
  data: {
    evt: 'EVT: shoot ready',
    ver: 'v1.1.2',
    status: '取景启动中…',
    bigLine: '已拍 0 / 120 张',
    filmLine: '预估成片 0 秒',
    hintLine: '点头或单击开始拍摄',
    modeLine: '',
    failLine: '',
    infoLine: '12 帧/秒 · 满 120 张约 10 秒 · 点头或单击开始 · 说退出合成'
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { this._recordErr('E7006', e, true); }
    resetSession(); // entering the shoot page always starts a fresh sequence
    store.target = TARGET;
    this._phase = 'wait'; // 'wait' | 'shooting' | 'done'
    this._stream = null; this._cap = null; this._ctx = null;
    this._prevBmp = null; this._prevStored = false; this._busy = false;
    this._capBusyTs = 0; this._stage = '';
    this._pvTimer = null; this._capTimer = null; this._elTimer = null;
    this._startTs = 0; this._elapsed = 0; this._pvFail = 0;
    this._failTotal = 0; this._consecFails = 0;
    this._errCode = ''; this._errCount = 0; this._lastErrRaw = '';
    this._diagShown = false; this._storeErrRec = false;
    this._rec = null; this._asrDead = false; this._asrRestartFails = 0; this._backUsed = false;
    this._render();
  },
  onReady() { this._initCanvas(); this._startCamera(); },
  onShow() {
    // Same instance returning to the foreground: camera was stopped on hide.
    if (this._wasLive && !this._cap && this._phase !== 'done') this._startCamera();
  },
  onHide() { this._stopAll(); },
  onUnload() {
    // Abnormal unload mid-take: tag the record E8002 before tearing down.
    if (this._phase === 'shooting') {
      this._recordErr('E8002', new Error('page unloaded mid-take'), true);
      store.stopReason = store.stopReason || 'errors';
      this._writeWork();
    }
    this._stopAll();
  },
  _initCanvas() {
    try { if (typeof wx !== 'undefined' && wx.createCanvasContext) this._ctx = wx.createCanvasContext('viewCanvas'); } catch (e) { this._ctx = null; }
  },
  _targetNow() { return store.mode === 'memory' ? MEM_TARGET : TARGET; },
  _render() {
    var n = store.frames.length;
    this.setData({
      bigLine: '已拍 ' + n + ' / ' + this._targetNow() + ' 张',
      filmLine: '预估成片 ' + (Math.round((n / FPS) * 10) / 10) + ' 秒'
    });
  },
  // Error-code plumbing (err.js is the only definition site). Records
  // store.lastError with the FULL prefixed code; unless silent, shows
  // "AVE#### 说明" in the big fail area; consecutive same-code hits
  // only bump the ×N counter instead of spamming.
  _recordErr(code, e, silent, keepLast) {
    var raw = e ? errText(e).slice(0, 40) : '';
    this._lastErrRaw = raw;
    if (!keepLast) store.lastError = { code: fullCode(code), text: raw, at: Date.now() };
    if (this._errCode === code) this._errCount++;
    else { this._errCode = code; this._errCount = 1; }
    if (!silent) {
      this.setData({
        failLine: errLine(code) + (this._errCount > 1 ? ' ×' + this._errCount : ''),
        evt: 'EVT: ' + fullCode(code)
      });
    }
  },
  async _startCamera() {
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') {
        this._recordErr('E1003', new Error('no ImageCapture'));
        this.setData({ status: '宿主无相机/ImageCapture，待真机拍摄（不生成假帧）', evt: 'EVT: camera n/a' });
        return;
      }
      try {
        this._stream = await navigator.mediaDevices.getUserMedia({ video: true });
      } catch (e) {
        this._recordErr((e && e.name === 'NotAllowedError') ? 'E1002' : 'E1001', e);
        this.setData({ status: '相机启动失败（如实）：' + errText(e).slice(0, 44), evt: 'EVT: camera fail' });
        return;
      }
      var track = this._stream.getVideoTracks()[0];
      if (!track) { this._recordErr('E1001', new Error('no video track')); return; }
      var self = this;
      try { track.onended = function () { self._recordErr('E1006', new Error('video track ended')); }; } catch (e) {}
      try { this._cap = new ImageCapture(track); }
      catch (e) {
        this._recordErr('E1003', e);
        this.setData({ status: '拍照器不可用（如实）：' + errText(e).slice(0, 44), evt: 'EVT: capture n/a' });
        return;
      }
      this._wasLive = true;
      if (this._phase === 'wait') {
        this.setData({ status: '取景中：摆好物件，点头或单击开始自动拍摄', evt: 'EVT: camera on' });
        // Preview refresh runs ONLY while waiting: once shooting starts it
        // is stopped so preview and capture never fight over grabFrame.
        if (!this._pvTimer) this._pvTimer = setInterval(function () { self._previewTick(); }, 350);
      }
      if (this._phase === 'shooting') this._startShootTimers();
    } catch (e) {
      this._recordErr('E9001', e);
      this.setData({ status: '相机启动失败（如实）：' + errText(e).slice(0, 44), evt: 'EVT: camera fail' });
    }
  },
  _startShootTimers() {
    var self = this;
    if (!this._capTimer) this._capTimer = setInterval(function () { self._capture(); }, IV_MS);
    if (!this._elTimer) this._elTimer = setInterval(function () {
      if (self._startTs) self._elapsed = (Date.now() - self._startTs) / 1000;
      store.shootSec = Math.floor(self._elapsed);
      // Busy watchdog: a single frame stuck > 2.5 s (a hung promise in any
      // link of the chain) must never block the whole take forever.
      if (self._busy && self._capBusyTs && (Date.now() - self._capBusyTs) > BUSY_WATCHDOG_MS) {
        self._busy = false; self._capBusyTs = 0;
        self._frameFail(codedError('E2009', 'frame stuck >2.5s (watchdog reset)'));
      }
      // 5-second zero-frame diagnosis, big and specific.
      if (self._phase === 'shooting' && !self._diagShown && self._elapsed >= 5 && store.frames.length === 0) {
        self._diagShown = true;
        var d = self._diagText();
        self.setData({ hintLine: '诊断：' + d, status: '开始 5 秒仍 0 张 — ' + d, evt: 'EVT: diag 0 frames' });
      }
      if (self._elapsed >= SAFETY_SEC) self._finish('time');
    }, 500);
  },
  _diagText() {
    if (!this._cap) return '相机未就绪（取景未启动）';
    if (store.mode === 'memory') return '编码超时/失败，已切内存帧模式' + (store.encodeError ? '（' + store.encodeError.slice(0, 24) + '）' : '');
    if (this._errCode === 'E2001') return 'grabFrame 失败：' + this._lastErrRaw;
    if (this._errCode === 'E2009') return '单帧处理 hang，已被看门狗复位：' + this._lastErrRaw;
    if (store.encodeError) return '编码失败：' + store.encodeError.slice(0, 28);
    if (this._errCode) return errLine(this._errCode) + '：' + this._lastErrRaw;
    return '暂无报错，出帧未回（疑编码 hang，600ms 熔断监控中）';
  },
  _drawLive(bmp) {
    if (!this._ctx || !bmp) return;
    try {
      this._ctx.drawImage(bmp, 0, 0, 448, 198);
      if (this._prevBmp && this._prevBmp !== bmp) {
        this._ctx.globalAlpha = 0.45;
        this._ctx.drawImage(this._prevBmp, 0, 0, 448, 198);
        this._ctx.globalAlpha = 1;
      }
      if (this._ctx.flush) this._ctx.flush();
    } catch (e) {}
  },
  async _previewTick() {
    if (!this._cap || this._busy || this._phase !== 'wait') return;
    var bmp = null;
    try {
      bmp = await this._cap.grabFrame();
      this._drawLive(bmp);
      this._pvFail = 0;
    } catch (e) {
      this._pvFail++;
      this._recordErr('E1004', e, true);
      if (this._pvFail === 3) {
        this._recordErr('E1005', e);
        this.setData({ status: '取景连续失败（grabFrame/画布不可用，如实）', evt: 'EVT: preview draw fail' });
      }
    } finally { if (bmp && bmp !== this._prevBmp) { try { bmp.close(); } catch (e) {} } }
  },
  _makeCanvas(w, h) {
    var cv = null;
    try { if (typeof document !== 'undefined') cv = document.createElement('canvas'); } catch (e) {}
    if (!cv && typeof Canvas !== 'undefined') { try { cv = new Canvas(w, h); } catch (e) {} }
    if (cv) { try { cv.width = w; cv.height = h; } catch (e) {} }
    return cv;
  },
  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (the v1.1.0/v1.1.1 field
    // failure, code AVE2005). Documented path instead:
    // blob.arrayBuffer() -> chunked base64 via btoa (window reference).
    // Covered by the same 600 ms breaker as the rest of the encode chain
    // (the caller races it). Any failure here throws E2005.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw codedError('E2005', 'blob.arrayBuffer unavailable');
      var buf = await blob.arrayBuffer();
      var bytes = new Uint8Array(buf);
      var bin = '';
      var CH = 0x8000;
      for (var i = 0; i < bytes.length; i += CH) {
        bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      }
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && e.code) throw e;
      throw codedError('E2005', errText(e));
    }
  },
  _raceTimeout(p, ms, code, label) {
    return Promise.race([
      p,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(codedError(code, label)); }, ms);
      })
    ]);
  },
  async _encodeWork(bmp) {
    var cv = this._makeCanvas(480, 352);
    if (cv) {
      try {
        var ctx = cv.getContext('2d');
        ctx.drawImage(bmp, 0, 0, 480, 352);
        if (typeof cv.convertToBlob === 'function') {
          var blob = await cv.convertToBlob({ type: 'image/jpeg', quality: 0.6 });
          if (!blob || !blob.size) throw codedError('E2003', 'convertToBlob empty');
          return { url: await this._blobToDataUrl(blob), bytes: blob.size || 0 };
        }
        if (typeof cv.toDataURL === 'function') {
          var u = cv.toDataURL('image/jpeg', 0.6);
          if (!u) throw codedError('E2003', 'toDataURL empty');
          return { url: u, bytes: Math.floor(String(u).length * 3 / 4) };
        }
      } catch (e) {
        if (e && e.code) throw e;
        throw codedError('E2003', errText(e));
      }
    }
    if (typeof createImageBlob === 'function') {
      try {
        var raw = await createImageBlob(bmp, { type: 'image/jpeg', quality: 0.6 });
        if (!raw || !raw.size) throw codedError('E2004', 'createImageBlob empty');
        return { url: await this._blobToDataUrl(raw), bytes: raw.size || 0 };
      } catch (e2) {
        if (e2 && e2.code) throw e2;
        throw codedError('E2004', errText(e2));
      }
    }
    throw codedError(cv ? 'E2003' : 'E2002', cv ? 'canvas has no jpeg output' : 'no canvas, no direct encoder');
  },
  async _encodeFrame(bmp) {
    // CIRCUIT BREAKER: the whole encode chain (convertToBlob /
    // createImageBlob / arrayBuffer-to-text) races a 600 ms timer and
    // trips as E2006. A host whose encoder promise never settles (or
    // whose text step is missing entirely) latches into bitmap mode
    // instead of dying silently frame after frame.
    return this._raceTimeout(this._encodeWork(bmp), ENC_TIMEOUT_MS, 'E2006', 'encode timeout 600ms');
  },
  _setPrev(bmp, stored) {
    if (this._prevBmp && this._prevBmp !== bmp && !this._prevStored) { try { this._prevBmp.close(); } catch (e) {} }
    this._prevBmp = bmp;
    this._prevStored = !!stored;
  },
  _storeBitmap(bmp) {
    // Bitmap-direct fallback: no encoding anywhere. Prefer raw pixels via
    // getImageData (documented on the canvas ctx); else keep the bitmap.
    // Returns 'px' | 'bmp' | null (null = no output path at all).
    var pxTried = false;
    var cv = this._makeCanvas(480, 352);
    if (cv) {
      try {
        var ctx = cv.getContext('2d');
        ctx.drawImage(bmp, 0, 0, 480, 352);
        if (typeof ctx.getImageData === 'function') {
          pxTried = true;
          var img = ctx.getImageData(0, 0, 480, 352);
          store.frames.push({ kind: 'px', w: 480, h: 352, img: img });
          store.sizes.push(480 * 352 * 4);
          this._setPrev(bmp, false);
          return 'px';
        }
      } catch (e) {}
    }
    try {
      store.frames.push({ kind: 'bmp', bmp: bmp });
      store.sizes.push((bmp.width || 480) * (bmp.height || 352) * 4);
      this._setPrev(bmp, true);
      return 'bmp';
    } catch (e) {
      if (pxTried) throw codedError('E2008', errText(e));
      throw codedError('E2007', errText(e));
    }
  },
  _onModeSwitch(code) {
    store.target = MEM_TARGET;
    this.setData({
      modeLine: errLine(code) + '，已切内存帧模式 · 目标降为 40 张',
      status: '编码链失败/超时（如实）：' + (store.encodeError || '').slice(0, 44),
      evt: 'EVT: memory mode ' + fullCode(code)
    });
    this._speak('编码不可用，已切内存帧模式');
    this._render();
  },
  _frameFail(e) {
    var code = (e && e.code) || 'E9001';
    this._failTotal++;
    this._consecFails++;
    this._recordErr(code, e);
    this.setData({ status: '拍帧失败（如实）：' + this._lastErrRaw + ' · 累计失败 ' + this._failTotal + ' 次' });
    if (this._failTotal === 1) this._speak('拍帧失败');
    if (this._consecFails >= MAX_CONSEC_FAILS && this._phase === 'shooting') this._autoStop();
  },
  async _capture() {
    if (this._busy || this._phase !== 'shooting') return;
    if (!this._cap) return;
    if (store.frames.length >= this._targetNow()) { this._finish('target'); return; }
    this._busy = true;
    this._capBusyTs = Date.now();
    var bmp = null;
    var owned = false; // bmp ownership handed to store / onion
    try {
      if (!store.startedAt) store.startedAt = Date.now();
      try { bmp = await this._cap.grabFrame(); }
      catch (ge) { throw codedError('E2001', errText(ge)); }
      this._drawLive(bmp);
      if (store.mode !== 'memory') {
        try {
          var enc = await this._encodeFrame(bmp);
          store.frames.push({ kind: 'url', url: enc.url });
          store.sizes.push(enc.bytes);
          if (!store.mode) store.mode = 'url';
          this._setPrev(bmp, false); owned = true;
        } catch (ee) {
          // Encode rejected OR timed out: record the first error verbatim
          // (the diagnostic the device must bring back), latch memory mode,
          // and still save THIS frame as a bitmap — not a dead frame.
          var emsg = errText(ee);
          var ecode = (ee && ee.code) || 'E9001';
          if (!store.encodeError) store.encodeError = emsg.slice(0, 120);
          this._recordErr(ecode, ee, true);
          store.mode = 'memory';
          this._onModeSwitch(ecode);
          this._storeBitmap(bmp); owned = true;
        }
      } else {
        this._storeBitmap(bmp); owned = true;
      }
      this._consecFails = 0;
      var n = store.frames.length;
      this.setData({ evt: 'EVT: frame ' + n });
      this._render();
      if (n === Math.floor(this._targetNow() / 2)) this._speak('已拍一半');
      if (n >= this._targetNow()) this._finish('target');
    } catch (e) {
      this._frameFail(e);
    } finally {
      if (bmp && !owned) { try { bmp.close(); } catch (e) {} }
      this._busy = false;
      this._capBusyTs = 0;
    }
  },
  _begin(via) {
    if (this._phase !== 'wait') return;
    this._phase = 'shooting';
    store.startVia = via || 'nod';
    this._startTs = Date.now();
    this._elapsed = 0;
    this._failTotal = 0; this._consecFails = 0;
    this._errCode = ''; this._errCount = 0; this._diagShown = false;
    if (!store.startedAt) store.startedAt = Date.now();
    // Stop the preview timer: preview and capture must not both grabFrame.
    if (this._pvTimer) { clearInterval(this._pvTimer); this._pvTimer = null; }
    this._startAsr();
    this._startShootTimers();
    this._speak('开始拍摄，说退出结束合成');
    this.setData({ status: '自动拍摄中：每秒一张', hintLine: '说「退出」结束合成', failLine: '', modeLine: store.mode === 'memory' ? '内存帧模式 · 目标 40 张' : '', evt: 'EVT: shooting via ' + store.startVia });
    this._capture();
  },
  _startAsr() {
    var self = this;
    if (typeof SpeechRecognition === 'undefined') { this._asrFail('E3001', new Error('SpeechRecognition undefined')); return; }
    var rec = null;
    try { rec = new SpeechRecognition(); }
    catch (e) { this._asrFail('E3002', e); return; }
    rec.continuous = true;
    rec.interimResults = true;
    try { rec.lang = 'zh-CN'; } catch (e) {}
    rec.onresult = function (ev) { self._asrRestartFails = 0; self._onAsrResult(ev); };
    rec.onerror = function (ev) { self._asrFail('E3003', new Error((ev && ev.error) || 'asr error')); };
    rec.onend = function () {
      // Host ended the session mid-shoot: restart unless we are done.
      if (self._phase === 'shooting' && !self._asrDead) {
        try { rec.start(); self._asrRestartFails = 0; }
        catch (e) {
          self._asrRestartFails++;
          if (self._asrRestartFails >= 3) self._asrFail('E3004', e);
        }
      }
    };
    this._rec = rec;
    try { rec.start(); }
    catch (e) { this._asrFail('E3002', e); }
  },
  _onAsrResult(ev) {
    if (this._phase !== 'shooting') return;
    try {
      var rs = ev.results;
      var from = ev.resultIndex || 0;
      for (var i = from; i < rs.length; i++) {
        var t = rs[i] && rs[i][0] && rs[i][0].transcript;
        if (t && String(t).indexOf('退出') >= 0) { this._finish('voice'); return; }
      }
    } catch (e) {}
  },
  _asrFail(code, e) {
    if (this._asrDead) return;
    this._asrDead = true;
    this._recordErr(code, e, true);
    if (this._phase === 'shooting') {
      this.setData({ hintLine: errLine(code) + ' · 语音退出不可用，请用双击结束', evt: 'EVT: asr fail ' + fullCode(code) });
    }
  },
  _stopAsr() {
    this._asrDead = true; // blocks the onend restart
    if (this._rec) {
      try { this._rec.abort(); } catch (e) { try { this._rec.stop(); } catch (e2) {} }
      this._rec = null;
    }
  },
  _writeWork() {
    var total = 0;
    store.sizes.forEach(function (s) { total += s || 0; });
    var n = store.frames.length;
    var entry = {
      id: store.startedAt || Date.now(),
      fps: FPS,
      frames: n,
      target: this._targetNow(),
      mode: store.mode || 'none',
      encodeError: store.encodeError || '',
      lastError: store.lastError || null,
      startVia: store.startVia || '',
      stopReason: store.stopReason,
      shootSec: Math.floor(this._elapsed),
      avgKB: n ? Math.round((total / n / 102.4)) / 10 : 0,
      totalKB: Math.round((total / 102.4)) / 10,
      filmSec: Math.round((n / FPS) * 10) / 10,
      measuredFps: null,
      at: Date.now()
    };
    var works = sget(WORKSKEY, this) || [];
    works = [entry].concat(works.filter(function (w) { return w.id !== entry.id; })).slice(0, 12);
    var se = sset(WORKSKEY, works);
    if (se) this._recordErr(isQuota(se) ? 'E5003' : 'E5001', se, true);
  },
  _autoStop() {
    // Fast fail: 10 consecutive frame failures — stop NOW, stay on the
    // shoot page, show E2010 big with the primary code, speak the code.
    // store.lastError deliberately keeps the PRIMARY error (the table
    // says for E2010: 主码见 lastError), so E2010 is display-only here.
    var primary = (store.lastError && store.lastError.code) || fullCode('E9001');
    this._phase = 'done';
    store.stopReason = 'errors';
    store.shootSec = Math.floor(this._elapsed);
    this._stopAsr();
    this._stopAll();
    this._writeWork();
    this._recordErr('E2010', new Error('10 consecutive frame failures'), false, true);
    this._speak('错误 ' + fullCode('E2010'));
    this.setData({
      bigLine: errLine('E2010'),
      hintLine: '主错误 ' + primary + ' · 点头或单击重新开始',
      status: '连续失败 10 次自动停拍 · 最近原文：' + this._lastErrRaw,
      evt: 'EVT: auto stop ' + fullCode('E2010')
    });
    this._phase = 'wait';
    this._startCamera();
  },
  _finish(reason) {
    if (this._phase === 'done') return;
    this._phase = 'done';
    store.stopReason = reason;
    store.shootSec = Math.floor(this._elapsed);
    this._stopAsr();
    this._stopAll();
    this._writeWork();
    var n = store.frames.length;
    if (!n) {
      // E4001: zero frames — STAY on the shoot page with the code big,
      // never navigate (v1.1.x navigated to an empty play page and the
      // agent felt like it had quit). Retry is one nod/tap away.
      var primary = (store.lastError && store.lastError.code) || '';
      this._recordErr('E4001', new Error('finished with 0 frames'), false, true);
      this._speak('一张都没有拍到');
      this.setData({
        bigLine: errLine('E4001'),
        hintLine: primary ? ('主错误 ' + primary + ' · 点头或单击重新开始') : '一张都没拍成 · 点头或单击重新开始',
        status: '已停：' + reasonLabel(reason) + ' · 0 帧留在拍摄页，不跳合成',
        evt: 'EVT: finish 0 frames ' + fullCode('E4001')
      });
      this._phase = 'wait';
      this._startCamera();
      return;
    }
    if (reason === 'target') this._speak('拍够了，共 ' + n + ' 张，开始合成');
    else if (reason === 'time') this._speak('满 3 分钟了，共 ' + n + ' 张，开始合成');
    else if (reason === 'voice') this._speak('好的，共 ' + n + ' 张，开始合成');
    else this._speak('拍摄结束，共 ' + n + ' 张，开始合成');
    this.setData({ status: '已停：' + reasonLabel(reason) + ' · 共 ' + n + ' 张', evt: 'EVT: finish ' + reason });
    try { wx.navigateTo({ url: '/pages/play/index' }); }
    catch (e) {
      this._recordErr('E8001', e);
      this.setData({ status: errLine('E8001') + '：帧还在本页内存，退出重进将丢失', evt: 'EVT: nav fail' });
    }
  },
  _stopAll() {
    if (this._pvTimer) { clearInterval(this._pvTimer); this._pvTimer = null; }
    if (this._capTimer) { clearInterval(this._capTimer); this._capTimer = null; }
    if (this._elTimer) { clearInterval(this._elTimer); this._elTimer = null; }
    if (this._stream) { try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} this._stream = null; }
    this._cap = null;
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      if (!store.lastError || store.lastError.code !== fullCode('E3005')) this._recordErr('E3005', e, true);
      return false;
    }
  },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter' && this._phase === 'wait') {
      // Diagnostic second start channel: tap works but nod does not =
      // gesture channel problem; tap starts but frames stay 0 = frame
      // chain problem. The two fault domains stay distinguishable.
      this._begin('tap');
    }
    if (k === 'Backspace' && this._phase === 'shooting') {
      this._backUsed = true; // consumed: onKeyUp swallows the default back
      this._finish('back');
    }
  },
  onKeyUp(event) {
    var k = event.key || event.code;
    if (k === 'Backspace' && this._backUsed) { this._backUsed = false; event.preventDefault(); }
  },
  onHeadGesture(event) {
    if (event && event.gesture === 'nod') {
      if (this._phase === 'wait') this._begin('nod');
      // While shooting a nod does NOTHING on purpose (speech moves the
      // head; a nod must never stop or alter the take).
    }
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">SHOOT · 定格拍摄</text>
    <canvas id="viewCanvas" width="448" height="198" class="viewcv"></canvas>
    <text class="big">{{bigLine}}</text>
    <text class="film">{{filmLine}}</text>
    <text class="mode" ink:if="{{modeLine}}">{{modeLine}}</text>
    <text class="fail" ink:if="{{failLine}}">{{failLine}}</text>
    <text class="hint">{{hintLine}}</text>
    <text class="status">{{status}}</text>
    <text class="info">{{infoLine}}</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 15px; font-weight: 500; }
.viewcv { width: 448px; height: 198px; margin-top: 4px; border: 1px solid rgba(64,255,94,0.7); background-color: #021007; }
.big { color: #7dff9e; font-family: monospace; font-size: 19px; font-weight: 500; margin-top: 6px; }
.film { color: #40ff5e; font-family: monospace; font-size: 12px; margin-top: 2px; }
.mode { color: #000000; background-color: #40ff5e; font-size: 13px; font-weight: 500; margin-top: 4px; padding: 2px 6px; }
.fail { color: #7dff9e; font-size: 13px; font-weight: 500; margin-top: 4px; }
.hint { color: #7dff9e; font-size: 13px; margin-top: 5px; }
.status { color: rgba(125,255,158,0.9); font-size: 10px; margin-top: 3px; }
.info { color: rgba(64,255,94,0.75); font-size: 10px; margin-top: 4px; }
.footrow { display: flex; flex-direction: row; margin-top: 4px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
