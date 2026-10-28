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
var IV_MS = 1000;
var SAFETY_SEC = 180;

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

export default {
  data: {
    evt: 'EVT: shoot ready',
    ver: 'v1.1.0',
    status: '取景启动中…',
    bigLine: '已拍 0 / 120 张',
    filmLine: '预估成片 0 秒',
    hintLine: '点头开始拍摄',
    infoLine: '12 帧/秒 · 满 120 张约 10 秒 · 点头开始 · 说退出合成'
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    resetSession(); // entering the shoot page always starts a fresh sequence
    store.target = TARGET;
    this._phase = 'wait'; // 'wait' | 'shooting' | 'done'
    this._stream = null; this._cap = null; this._ctx = null;
    this._prevBmp = null; this._busy = false;
    this._pvTimer = null; this._capTimer = null; this._elTimer = null;
    this._startTs = 0; this._elapsed = 0; this._pvFail = 0;
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
  _render() {
    var n = store.frames.length;
    this.setData({
      bigLine: '已拍 ' + n + ' / 120 张',
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
      if (this._phase === 'wait') this.setData({ status: '取景中：摆好物件，点头开始自动拍摄', evt: 'EVT: camera on' });
      var self = this;
      if (!this._pvTimer) this._pvTimer = setInterval(function () { self._previewTick(); }, 350);
      if (this._phase === 'shooting') this._startShootTimers();
    } catch (e) {
      this.setData({ status: '相机启动失败（如实）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: camera fail' });
    }
  },
  _startShootTimers() {
    var self = this;
    if (!this._capTimer) this._capTimer = setInterval(function () { self._capture(); }, IV_MS);
    if (!this._elTimer) this._elTimer = setInterval(function () {
      if (self._startTs) self._elapsed = (Date.now() - self._startTs) / 1000;
      store.shootSec = Math.floor(self._elapsed);
      if (self._elapsed >= SAFETY_SEC) self._finish('time');
    }, 500);
  },
  async _previewTick() {
    if (!this._cap || this._busy) return;
    var bmp = null;
    try {
      bmp = await this._cap.grabFrame();
      if (this._ctx) {
        this._ctx.drawImage(bmp, 0, 0, 448, 198);
        if (this._prevBmp) {
          this._ctx.globalAlpha = 0.45;
          this._ctx.drawImage(this._prevBmp, 0, 0, 448, 198);
          this._ctx.globalAlpha = 1;
        }
        if (this._ctx.flush) this._ctx.flush();
      }
      this._pvFail = 0;
    } catch (e) {
      this._pvFail++;
      if (this._pvFail === 3) this.setData({ status: '取景绘制失败（grabFrame/画布不可用，如实）', evt: 'EVT: preview draw fail' });
    } finally { if (bmp && bmp !== this._prevBmp) { try { bmp.close(); } catch (e) {} } }
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
  async _encodeFrame(bmp) {
    var cv = null;
    try { if (typeof document !== 'undefined') cv = document.createElement('canvas'); } catch (e) {}
    if (!cv && typeof Canvas !== 'undefined') { try { cv = new Canvas(480, 352); } catch (e) {} }
    if (cv) {
      try {
        try { cv.width = 480; cv.height = 352; } catch (e) {}
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
      } catch (e) { /* canvas encode failed on this host: try createImageBlob below */ }
    }
    if (typeof createImageBlob === 'function') {
      var raw = await createImageBlob(bmp, { type: 'image/jpeg', quality: 0.6 });
      return { url: await this._blobToDataUrl(raw), bytes: raw.size || 0 };
    }
    throw new Error('no jpeg output path (canvas/createImageBlob)');
  },
  async _capture() {
    if (this._busy || this._phase !== 'shooting') return;
    if (!this._cap) return;
    if (store.frames.length >= TARGET) { this._finish('target'); return; }
    this._busy = true;
    var bmp = null;
    try {
      if (!store.startedAt) store.startedAt = Date.now();
      bmp = await this._cap.grabFrame();
      var enc = await this._encodeFrame(bmp);
      store.frames.push(enc.url);
      store.sizes.push(enc.bytes);
      if (this._prevBmp) { try { this._prevBmp.close(); } catch (e) {} }
      this._prevBmp = bmp; bmp = null;
      var n = store.frames.length;
      this.setData({ evt: 'EVT: frame ' + n });
      this._render();
      if (n === 60) this._speak('已拍一半');
      if (n >= TARGET) this._finish('target');
    } catch (e) {
      this.setData({ status: '拍帧失败（如实）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: cap fail' });
    } finally {
      if (bmp) { try { bmp.close(); } catch (e) {} }
      this._busy = false;
    }
  },
  _begin() {
    if (this._phase !== 'wait') return;
    this._phase = 'shooting';
    this._startTs = Date.now();
    this._elapsed = 0;
    if (!store.startedAt) store.startedAt = Date.now();
    this._startAsr();
    this._startShootTimers();
    this._speak('开始拍摄，说退出结束合成');
    this.setData({ status: '自动拍摄中：每秒一张', hintLine: '说「退出」结束合成', evt: 'EVT: shooting' });
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
      target: TARGET,
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
      if (this._phase === 'wait') this._begin();
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
.hint { color: #7dff9e; font-size: 13px; margin-top: 5px; }
.status { color: rgba(125,255,158,0.9); font-size: 10px; margin-top: 3px; }
.info { color: rgba(64,255,94,0.75); font-size: 10px; margin-top: 4px; }
.footrow { display: flex; flex-direction: row; margin-top: 4px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
