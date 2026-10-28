<script def>
{
  "title": "Stop Motion Shoot"
}
</script>

<script setup>
import wx from 'wx';
import { store, resetSession } from '../../store.js';

var CFGKEY = 'av11_cfg';
var WORKSKEY = 'av11_works';
var SPEEDS = [
  { key: 'slow', label: '慢速', fps: 5 },
  { key: 'mid', label: '中速', fps: 8 },
  { key: 'fast', label: '快速', fps: 12 }
];
var LENS = [
  { key: 'short', label: '短', sec: 5 },
  { key: 'mid', label: '中', sec: 10 },
  { key: 'long', label: '长', sec: 15 }
];
var CAP_FRAMES = 120;
var SAFETY_SEC = 180;
var AUTO_IV = 2;

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
function defCfg() { return { name: '未命名定格', speedKey: 'mid', lenKey: 'mid', mode: 'manual' }; }
function speedOf(c) { for (var i = 0; i < SPEEDS.length; i++) if (SPEEDS[i].key === c.speedKey) return SPEEDS[i]; return SPEEDS[1]; }
function lenOf(c) { for (var i = 0; i < LENS.length; i++) if (LENS[i].key === c.lenKey) return LENS[i]; return LENS[1]; }
function targetOf(c) { return Math.min(speedOf(c).fps * lenOf(c).sec, CAP_FRAMES); }
function reasonLabel(r) { return r === 'target' ? '拍够了' : (r === 'time' ? '满 3 分钟了' : (r === 'user' ? '手动结束' : '')); }
var MENU = [
  { name: '拍一帧', act: 'cap' },
  { name: '自动开关', act: 'timer' },
  { name: '洋葱皮开关', act: 'onion' },
  { name: '清空重拍', act: 'clear' },
  { name: '完成去合成', act: 'done' }
];

export default {
  data: {
    evt: 'EVT: shoot ready',
    ver: 'v1.0.0',
    status: '取景启动中…',
    countLine: '帧 0/80 · 已拍 0s/180s 安全上限 · 手动',
    onionLine: '洋葱皮：开（上一帧半透明叠加）',
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._sel = 0; this._stream = null; this._cap = null; this._ctx = null;
    this._prevBmp = null; this._busy = false;
    this._pvTimer = null; this._capTimer = null; this._elTimer = null;
    this._baseSec = 0; this._startTs = 0; this._elapsed = 0; this._onion = true; this._pvFail = 0;
    this._cfg = sget(CFGKEY) || defCfg();
    this._fps = speedOf(this._cfg).fps;
    this._target = targetOf(this._cfg);
    if (store.stopReason) resetSession(); // a finished sequence starts fresh
    if (store.frames.length) {
      this._baseSec = store.shootSec || 0;
      this._elapsed = this._baseSec;
      this.setData({ status: '补拍模式：会话内已有 ' + store.frames.length + ' 帧，接着拍' });
    }
    store.target = this._target;
    this._render();
  },
  onReady() { this._initCanvas(); this._startCamera(); },
  onShow() {
    this._render();
    // Returning via navigateBack: page instance survived but onHide stopped
    // the camera. Restart it; a finished sequence re-entered this way is a
    // retake continuation, not a reset.
    if (this._wasLive && !this._cap) {
      if (store.stopReason) { store.stopReason = ''; this._baseSec = store.shootSec || 0; this._elapsed = this._baseSec; }
      this._startCamera();
    }
  },
  onHide() { this._stopAll(); },
  onUnload() { this._stopAll(); },
  _initCanvas() {
    try { if (typeof wx !== 'undefined' && wx.createCanvasContext) this._ctx = wx.createCanvasContext('viewCanvas'); } catch (e) { this._ctx = null; }
  },
  _render() {
    var sel = this._sel || 0;
    var rows = MENU.map(function (m, i) {
      return { name: m.name, cls: i === sel ? 'mrow mrow-sel' : 'mrow', mark: i === sel ? '▸' : '·' };
    });
    this.setData({
      rows: rows,
      countLine: '帧 ' + store.frames.length + '/' + this._target + ' · 已拍 ' + Math.floor(this._elapsed) + 's/' + SAFETY_SEC + 's 安全上限 · ' + (this._cfg.mode === 'auto' ? '自动 2s/张' : '手动'),
      onionLine: '洋葱皮：' + (this._onion ? '开（上一帧半透明叠加在取景上）' : '关')
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
      this._startTs = Date.now() - this._baseSec * 1000;
      if (!store.frames.length) this.setData({ status: '取景中：摆好物件，单击或点头拍一帧', evt: 'EVT: camera on' });
      var self = this;
      this._pvTimer = setInterval(function () { self._previewTick(); }, 350);
      this._elTimer = setInterval(function () {
        if (self._startTs) self._elapsed = (Date.now() - self._startTs) / 1000;
        store.shootSec = Math.floor(self._elapsed);
        self._render();
        if (self._elapsed >= SAFETY_SEC) self._finish('time');
      }, 500);
    } catch (e) {
      this.setData({ status: '相机启动失败（如实）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: camera fail' });
    }
  },
  async _previewTick() {
    if (!this._cap || this._busy) return;
    var bmp = null;
    try {
      bmp = await this._cap.grabFrame();
      if (this._ctx) {
        this._ctx.drawImage(bmp, 0, 0, 448, 196);
        if (this._onion && this._prevBmp) {
          this._ctx.globalAlpha = 0.45;
          this._ctx.drawImage(this._prevBmp, 0, 0, 448, 196);
          this._ctx.globalAlpha = 1;
        }
        if (this._ctx.flush) this._ctx.flush();
      }
      this._pvFail = 0;
    } catch (e) {
      this._pvFail++;
      if (this._pvFail === 3) this.setData({ status: '取景绘制失败（grabFrame/画布不可用，如实）：仍可尝试拍帧', evt: 'EVT: preview draw fail' });
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
    if (this._busy) return;
    if (!this._cap) { this.setData({ status: '相机未就绪，待真机拍摄（不生成假帧）', evt: 'EVT: cap n/a' }); return; }
    if (store.frames.length >= this._target) { this._finish('target'); return; }
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
      this.setData({ evt: 'EVT: frame ' + n, status: '已拍第 ' + n + ' 帧 · JPEG 入会话内存（单帧 ' + Math.round(enc.bytes / 102.4) / 10 + ' KB）' });
      if (n % 10 === 0) this._speak('已拍 ' + n + ' 帧，还剩 ' + (this._target - n) + ' 帧');
      else this._speak(n + '帧');
      this._render();
      if (n >= this._target) this._finish('target');
    } catch (e) {
      this.setData({ status: '拍帧失败（如实）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: cap fail' });
    } finally {
      if (bmp) { try { bmp.close(); } catch (e) {} }
      this._busy = false;
    }
  },
  _toggleTimer() {
    var self = this;
    if (this._capTimer) { clearInterval(this._capTimer); this._capTimer = null; this.setData({ status: '自动拍摄已停', evt: 'EVT: auto off' }); return; }
    if (this._cfg.mode !== 'auto') { this.setData({ status: '当前是手动拍法：到设置页切「自动」后可用', evt: 'EVT: auto manual-mode' }); return; }
    this._capTimer = setInterval(function () { self._capture(); }, AUTO_IV * 1000);
    this.setData({ status: '自动拍摄中：每 2 秒一张', evt: 'EVT: auto on' });
    this._speak('自动拍摄开始');
  },
  _writeWork() {
    if (!store.frames.length) return;
    var total = 0;
    store.sizes.forEach(function (s) { total += s || 0; });
    var entry = {
      id: store.startedAt || Date.now(),
      name: this._cfg.name || '未命名定格',
      fps: this._fps,
      frames: store.frames.length,
      target: this._target,
      stopReason: store.stopReason,
      shootSec: Math.floor(this._elapsed),
      avgKB: Math.round((total / store.frames.length / 102.4)) / 10,
      totalKB: Math.round((total / 102.4)) / 10,
      filmSec: Math.round((store.frames.length / this._fps) * 10) / 10,
      measuredFps: null,
      at: Date.now()
    };
    var works = sget(WORKSKEY) || [];
    works = [entry].concat(works.filter(function (w) { return w.id !== entry.id; })).slice(0, 12);
    sset(WORKSKEY, works);
  },
  _finish(reason) {
    if (store.stopReason) return;
    store.stopReason = reason;
    store.shootSec = Math.floor(this._elapsed);
    this._stopAll();
    this._writeWork();
    var n = store.frames.length;
    if (reason === 'target') this._speak('拍够了，共 ' + n + ' 张，去合成');
    else if (reason === 'time') this._speak('满 3 分钟了，共 ' + n + ' 张，去合成');
    else this._speak('拍摄结束，共 ' + n + ' 张，去合成');
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
  _activate(i) {
    var d = MENU[i]; if (!d) return;
    this._sel = i; this._render();
    if (d.act === 'cap') this._capture();
    else if (d.act === 'timer') this._toggleTimer();
    else if (d.act === 'onion') { this._onion = !this._onion; this._render(); this.setData({ evt: 'EVT: onion ' + this._onion }); }
    else if (d.act === 'clear') {
      resetSession();
      store.target = this._target;
      if (this._prevBmp) { try { this._prevBmp.close(); } catch (e) {} this._prevBmp = null; }
      this._baseSec = 0; this._elapsed = 0; this._startTs = Date.now();
      this.setData({ status: '已清空，从第 1 帧重拍', evt: 'EVT: clear' }); this._render();
    }
    else if (d.act === 'done') this._finish('user');
  },
  onRowTap(e) {
    var i = this._sel || 0;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this._sel || 0;
    this._activate(i);
  },
  _move(dir) { this._sel = ((this._sel || 0) + dir + MENU.length) % MENU.length; this._render(); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter' || k === 'GlobalHook') this._activate(this._sel || 0);
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._capture(); }
};
</script>

<page>
  <view class="page">
    <text class="ttl">SHOOT · 拍摄</text>
    <canvas id="viewCanvas" width="448" height="196" class="viewcv"></canvas>
    <text class="count">{{countLine}}</text>
    <text class="onion">{{onionLine}}</text>
    <text class="status">{{status}}</text>
    <view class="mlist">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="onRowTap" data-idx="{{index}}">
        <text class="mname">{{item.mark}} {{item.name}}</text>
      </view>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 15px; font-weight: 500; }
.viewcv { width: 448px; height: 196px; margin-top: 4px; border: 1px solid rgba(64,255,94,0.7); background-color: #021007; }
.count { color: #40ff5e; font-family: monospace; font-size: 11px; margin-top: 4px; }
.onion { color: rgba(125,255,158,0.85); font-size: 10px; margin-top: 2px; }
.status { color: rgba(125,255,158,0.9); font-size: 10px; margin-top: 2px; }
.mlist { display: flex; flex-direction: row; flex-wrap: wrap; margin-top: 5px; }
.mrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 4px 7px; margin-right: 5px; margin-bottom: 4px; }
.mrow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.mname { color: #40ff5e; font-size: 11px; }
.footrow { display: flex; flex-direction: row; margin-top: 2px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
