<script def>
{
  "title": "Stop Motion Shoot"
}
</script>

<script setup>
import wx from 'wx';
import { store, resetSession } from '../../store.js';

var WORKSKEY = 'av11_works';
var FPS = 12;
var TARGET = 120;
var MEM_TARGET = 40;
var IV_MS = 1000;
var SAFETY_SEC = 180;
var ENC_TIMEOUT_MS = 600;
var BUSY_WATCHDOG_MS = 2500;

function sget(k) {
  try { if (typeof localStorage !== 'undefined') { var v = localStorage.getItem(k); if (v) return JSON.parse(v); } } catch (e) {}
  try { var w = wx.getStorageSync(k); if (w) return (typeof w === 'string') ? JSON.parse(w) : w; } catch (e) {}
  return null;
}
function sset(k, v) {
  try { if (typeof localStorage !== 'undefined') { localStorage.setItem(k, JSON.stringify(v)); return true; } } catch (e) {}
  try { wx.setStorageSync(k, v); return true; } catch (e) {}
  return false;
}
function reasonLabel(r) {
  return r === 'voice' ? '说「退出」结束' : (r === 'target' ? '拍够了' : (r === 'time' ? '满 3 分钟了' : (r === 'back' ? '双击结束' : '')));
}
function errText(e) { return String((e && e.message) || e); }

export default {
  data: {
    evt: 'EVT: shoot ready',
    ver: 'v1.1.1',
    status: '取景启动中…',
    bigLine: '已拍 0 / 120 张',
    filmLine: '预估成片 0 秒',
    hintLine: '点头或单击开始拍摄',
    modeLine: '',
    failLine: '',
    infoLine: '12 帧/秒 · 满 120 张约 10 秒 · 点头或单击开始 · 说退出合成'
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    resetSession(); // entering the shoot page always starts a fresh sequence
    store.target = TARGET;
    this._phase = 'wait'; // 'wait' | 'shooting' | 'done'
    this._stream = null; this._cap = null; this._ctx = null;
    this._prevBmp = null; this._prevStored = false; this._busy = false;
    this._capBusyTs = 0; this._stage = '';
    this._pvTimer = null; this._capTimer = null; this._elTimer = null;
    this._startTs = 0; this._elapsed = 0; this._pvFail = 0;
    this._failCount = 0; this._lastErr = ''; this._errKind = '';
    this._diagShown = false;
    this._rec = null; this._asrDead = false; this._backUsed = false;
    this._render();
  },
  onReady() { this._initCanvas(); this._startCamera(); },
  onShow() {
    // Same instance returning to the foreground: camera was stopped on hide.
    if (this._wasLive && !this._cap && this._phase !== 'done') this._startCamera();
  },
  onHide() { this._stopAll(); },
  onUnload() { this._stopAll(); },
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
  async _startCamera() {
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') {
        this.setData({ status: '宿主无相机/ImageCapture，待真机拍摄（不生成假帧）', evt: 'EVT: camera n/a' });
        return;
      }
      this._stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = this._stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      this._cap = new ImageCapture(track);
      this._wasLive = true;
      if (this._phase === 'wait') {
        this.setData({ status: '取景中：摆好物件，点头或单击开始自动拍摄', evt: 'EVT: camera on' });
        // Preview refresh runs ONLY while waiting: once shooting starts it
        // is stopped so preview and capture never fight over grabFrame.
        var self = this;
        if (!this._pvTimer) this._pvTimer = setInterval(function () { self._previewTick(); }, 350);
      }
      if (this._phase === 'shooting') this._startShootTimers();
    } catch (e) {
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
        self._noteFail(new Error('单帧处理超时 2.5 秒（看门狗复位）'), 'stuck');
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
    if (this._errKind === 'grab') return 'grabFrame 失败：' + this._lastErr;
    if (this._errKind === 'stuck') return '单帧处理 hang，已被看门狗复位：' + this._lastErr;
    if (store.encodeError) return '编码失败：' + store.encodeError.slice(0, 28);
    if (this._failCount > 0) return '拍帧失败：' + this._lastErr;
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
      if (this._pvFail === 3) this.setData({ status: '取景绘制失败（grabFrame/画布不可用，如实）', evt: 'EVT: preview draw fail' });
    } finally { if (bmp && bmp !== this._prevBmp) { try { bmp.close(); } catch (e) {} } }
  },
  _makeCanvas(w, h) {
    var cv = null;
    try { if (typeof document !== 'undefined') cv = document.createElement('canvas'); } catch (e) {}
    if (!cv && typeof Canvas !== 'undefined') { try { cv = new Canvas(w, h); } catch (e) {} }
    if (cv) { try { cv.width = w; cv.height = h; } catch (e) {} }
    return cv;
  },
  _blobToDataUrl(blob) {
    return new Promise(function (resolve, reject) {
      try {
        var fr = new FileReader();
        fr.onload = function () { resolve(fr.result); };
        fr.onerror = function () { reject(new Error('FileReader fail')); };
        fr.readAsDataURL(blob);
      } catch (e) { reject(e); }
    });
  },
  _raceTimeout(p, ms, label) {
    return Promise.race([
      p,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label)); }, ms);
      })
    ]);
  },
  async _encodeWork(bmp) {
    var cv = this._makeCanvas(480, 352);
    if (cv) {
      var ctx = cv.getContext('2d');
      ctx.drawImage(bmp, 0, 0, 480, 352);
      if (typeof cv.convertToBlob === 'function') {
        var blob = await cv.convertToBlob({ type: 'image/jpeg', quality: 0.6 });
        return { url: await this._blobToDataUrl(blob), bytes: blob.size || 0 };
      }
      if (typeof cv.toDataURL === 'function') {
        var u = cv.toDataURL('image/jpeg', 0.6);
        return { url: u, bytes: Math.floor(String(u).length * 3 / 4) };
      }
    }
    if (typeof createImageBlob === 'function') {
      var raw = await createImageBlob(bmp, { type: 'image/jpeg', quality: 0.6 });
      return { url: await this._blobToDataUrl(raw), bytes: raw.size || 0 };
    }
    throw new Error('no jpeg output path (canvas/createImageBlob)');
  },
  async _encodeFrame(bmp) {
    // CIRCUIT BREAKER (in _capture's encode call): the whole encode chain
    // (convertToBlob / createImageBlob / FileReader) races a 600 ms timer.
    // A host whose encoder promise never settles (the v1.1 real-device
    // symptom: begin + TTS fine, zero frames, zero errors) trips this and
    // the take latches into bitmap mode instead of dying silently.
    return this._raceTimeout(this._encodeWork(bmp), ENC_TIMEOUT_MS, 'encode timeout 600ms');
  },
  _storeBitmap(bmp) {
    // Bitmap-direct fallback: no encoding anywhere. Prefer raw pixels via
    // getImageData (documented on the canvas ctx); else keep the bitmap.
    var done = false;
    var cv = this._makeCanvas(480, 352);
    if (cv) {
      try {
        var ctx = cv.getContext('2d');
        ctx.drawImage(bmp, 0, 0, 480, 352);
        if (typeof ctx.getImageData === 'function') {
          var img = ctx.getImageData(0, 0, 480, 352);
          store.frames.push({ kind: 'px', w: 480, h: 352, img: img });
          store.sizes.push(480 * 352 * 4);
          done = true;
        }
      } catch (e) {}
    }
    if (!done) {
      store.frames.push({ kind: 'bmp', bmp: bmp });
      store.sizes.push((bmp.width || 480) * (bmp.height || 352) * 4);
    }
    // Onion bookkeeping: bmp becomes the previous frame. A bitmap stored
    // as a frame must never be closed; a px-mode bitmap may be closed
    // when the next frame replaces it (its pixels are already copied).
    if (this._prevBmp && this._prevBmp !== bmp && !this._prevStored) { try { this._prevBmp.close(); } catch (e) {} }
    this._prevBmp = bmp;
    this._prevStored = !done;
  },
  _onModeSwitch() {
    store.target = MEM_TARGET;
    this.setData({
      modeLine: '编码不可用，已切内存帧模式 · 目标降为 40 张',
      status: '编码链失败/超时（如实）：' + (store.encodeError || '').slice(0, 44),
      evt: 'EVT: memory mode'
    });
    this._speak('编码不可用，已切内存帧模式');
    this._render();
  },
  _noteFail(e, kind) {
    this._failCount++;
    var msg = errText(e).slice(0, 40);
    this._lastErr = msg;
    if (kind) this._errKind = kind;
    if (this._failCount === 1) this._speak('拍帧失败');
    this.setData({
      status: '拍帧失败（如实）：' + msg,
      failLine: '失败 ' + this._failCount + ' 次 · 最近：' + msg,
      evt: 'EVT: cap fail'
    });
  },
  async _capture() {
    if (this._busy || this._phase !== 'shooting') return;
    if (!this._cap) return;
    if (store.frames.length >= this._targetNow()) { this._finish('target'); return; }
    this._busy = true;
    this._capBusyTs = Date.now();
    this._stage = 'grab';
    var bmp = null;
    var owned = false; // bmp ownership handed to store / onion
    try {
      if (!store.startedAt) store.startedAt = Date.now();
      bmp = await this._cap.grabFrame();
      this._drawLive(bmp);
      if (store.mode !== 'memory') {
        this._stage = 'encode';
        try {
          var enc = await this._encodeFrame(bmp);
          store.frames.push({ kind: 'url', url: enc.url });
          store.sizes.push(enc.bytes);
          if (!store.mode) store.mode = 'url';
          if (this._prevBmp && this._prevBmp !== bmp && !this._prevStored) { try { this._prevBmp.close(); } catch (e) {} }
          this._prevBmp = bmp; this._prevStored = false; owned = true;
        } catch (ee) {
          // Encode rejected OR timed out: record the first error verbatim
          // (the diagnostic the device must bring back), latch memory mode,
          // and still save THIS frame as a bitmap — not a dead frame.
          var emsg = errText(ee);
          if (!store.encodeError) store.encodeError = emsg.slice(0, 120);
          this._errKind = emsg.indexOf('timeout') >= 0 ? 'timeout' : 'encode';
          this._lastErr = emsg.slice(0, 40);
          store.mode = 'memory';
          this._onModeSwitch();
          this._stage = 'store';
          this._storeBitmap(bmp); owned = true;
        }
      } else {
        this._stage = 'store';
        this._storeBitmap(bmp); owned = true;
      }
      var n = store.frames.length;
      this.setData({ evt: 'EVT: frame ' + n });
      this._render();
      if (n === Math.floor(this._targetNow() / 2)) this._speak('已拍一半');
      if (n >= this._targetNow()) this._finish('target');
    } catch (e) {
      this._noteFail(e, this._stage === 'grab' ? 'grab' : 'store');
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
    if (!store.startedAt) store.startedAt = Date.now();
    // Stop the preview timer: preview and capture must not both grabFrame.
    if (this._pvTimer) { clearInterval(this._pvTimer); this._pvTimer = null; }
    this._startAsr();
    this._startShootTimers();
    this._speak('开始拍摄，说退出结束合成');
    this.setData({ status: '自动拍摄中：每秒一张', hintLine: '说「退出」结束合成', evt: 'EVT: shooting via ' + store.startVia });
    this._capture();
  },
  _startAsr() {
    var self = this;
    try {
      if (typeof SpeechRecognition === 'undefined') { this._asrFail(); return; }
      var rec = new SpeechRecognition();
      rec.continuous = true;
      rec.interimResults = true;
      try { rec.lang = 'zh-CN'; } catch (e) {}
      rec.onresult = function (ev) { self._onAsrResult(ev); };
      rec.onerror = function () { self._asrFail(); };
      rec.onend = function () {
        // Host ended the session mid-shoot: restart unless we are done.
        if (self._phase === 'shooting' && !self._asrDead) { try { rec.start(); } catch (e) {} }
      };
      this._rec = rec;
      rec.start();
    } catch (e) { this._asrFail(); }
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
  _asrFail() {
    if (this._asrDead) return;
    this._asrDead = true;
    if (this._phase === 'shooting') {
      this.setData({ hintLine: '语音退出不可用，请用双击结束', evt: 'EVT: asr fail' });
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
    if (!store.frames.length) return;
    var total = 0;
    store.sizes.forEach(function (s) { total += s || 0; });
    var entry = {
      id: store.startedAt || Date.now(),
      fps: FPS,
      frames: store.frames.length,
      target: this._targetNow(),
      mode: store.mode || 'none',
      encodeError: store.encodeError || '',
      startVia: store.startVia || '',
      stopReason: store.stopReason,
      shootSec: Math.floor(this._elapsed),
      avgKB: Math.round((total / store.frames.length / 102.4)) / 10,
      totalKB: Math.round((total / 102.4)) / 10,
      filmSec: Math.round((store.frames.length / FPS) * 10) / 10,
      measuredFps: null,
      at: Date.now()
    };
    var works = sget(WORKSKEY) || [];
    works = [entry].concat(works.filter(function (w) { return w.id !== entry.id; })).slice(0, 12);
    sset(WORKSKEY, works);
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
    if (reason === 'target') this._speak('拍够了，共 ' + n + ' 张，开始合成');
    else if (reason === 'time') this._speak('满 3 分钟了，共 ' + n + ' 张，开始合成');
    else if (reason === 'voice') this._speak('好的，共 ' + n + ' 张，开始合成');
    else this._speak('拍摄结束，共 ' + n + ' 张，开始合成');
    this.setData({ status: '已停：' + reasonLabel(reason) + ' · 共 ' + n + ' 张', evt: 'EVT: finish ' + reason });
    try { wx.navigateTo({ url: '/pages/play/index' }); } catch (e) {}
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
    } catch (e) { return false; }
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
