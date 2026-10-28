<script def>
{
  "title": "Stop Motion Play"
}
</script>

<script setup>
import wx from 'wx';
import { store } from '../../store.js';

var WORKSKEY = 'av11_works';
var FPS = 12;
var TARGET = 120;

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
  return r === 'voice' ? '说「退出」结束' : (r === 'target' ? '拍够了' : (r === 'time' ? '满 3 分钟了' : (r === 'back' ? '双击结束' : '—')));
}
function frameUrl(fr) {
  if (!fr) return '';
  if (typeof fr === 'string') return fr;
  return fr.url || '';
}

export default {
  data: {
    evt: 'EVT: play ready',
    ver: 'v1.1.1',
    status: '合成 = 按 12 帧/秒逐帧播放帧序列（不是生成视频文件）',
    progLine: '帧 0/0',
    readLines: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._ctx = null; this._timer = null; this._playing = false;
    this._idx = 0; this._drawTimes = []; this._decBusy = false;
    this._pxCv = null;
    if (!store.frames.length) this.setData({ status: '会话内暂无帧：先回拍摄页，点头或单击开始拍摄' });
    this._render();
  },
  onReady() {
    try { if (wx.createCanvasContext) this._ctx = wx.createCanvasContext('playCanvas'); } catch (e) { this._ctx = null; }
    if (store.frames.length) this._play();
    else this._drawCurrent();
  },
  onHide() { this._stop(); this._persistMeasured(); },
  onUnload() { this._stop(); this._persistMeasured(); },
  _totals() {
    var total = 0;
    store.sizes.forEach(function (s) { total += s || 0; });
    return total;
  },
  _measured() {
    if (this._drawTimes.length < 2) return null;
    var dt = (this._drawTimes[this._drawTimes.length - 1] - this._drawTimes[0]) / 1000;
    if (dt <= 0) return null;
    return Math.round(((this._drawTimes.length - 1) / dt) * 10) / 10;
  },
  _render() {
    var n = store.frames.length;
    var total = this._totals();
    var meas = this._measured();
    if (meas) store.measuredFps = meas;
    var T = store.target || TARGET;
    var mem = store.mode === 'memory';
    var avgTxt = n ? ((mem ? '约 ' : '') + Math.round((total / n / 102.4)) / 10 + ' KB' + (mem ? '（估算）' : '')) : '-';
    var totTxt = n ? ((mem ? '约 ' : '') + Math.round((total / 102.4)) / 10 + ' KB' + (mem ? '（估算）' : '')) : '-';
    var modeTxt = store.mode === 'memory' ? '内存帧' : (store.mode === 'url' ? 'dataURL' : '—');
    var reads = [
      { l1: '设定帧率', v1: FPS + ' fps', l2: '实测帧率', v2: meas ? (meas + ' fps') : '未测（播放后出）' },
      { l1: '已拍张数', v1: n + ' / ' + T, l2: '实际成片', v2: n ? (Math.round((n / FPS) * 10) / 10 + ' s') : '-' },
      { l1: '单帧平均', v1: avgTxt, l2: '帧总大小', v2: totTxt },
      { l1: '拍摄耗时', v1: (store.shootSec || 0) + ' s', l2: '停因', v2: reasonLabel(store.stopReason) },
      { l1: '出帧模式', v1: modeTxt, l2: '编码错误', v2: store.encodeError ? store.encodeError.slice(0, 26) : '-' }
    ];
    this.setData({
      readLines: reads,
      progLine: '帧 ' + (n ? Math.min(this._idx + 1, n) : 0) + '/' + n + (this._playing ? ' · 循环播放中 · 点头或单击从头重播' : '')
    });
  },
  _persistMeasured() {
    var meas = this._measured();
    if (!meas || !store.startedAt) return;
    var works = sget(WORKSKEY) || [];
    var changed = false;
    for (var i = 0; i < works.length; i++) {
      if (works[i].id === store.startedAt) {
        works[i].measuredFps = meas;
        works[i].frames = store.frames.length;
        var total = this._totals();
        works[i].totalKB = Math.round((total / 102.4)) / 10;
        works[i].avgKB = store.frames.length ? Math.round((total / store.frames.length / 102.4)) / 10 : 0;
        changed = true;
        break;
      }
    }
    if (changed) sset(WORKSKEY, works);
  },
  _dataUrlToBlob(u) {
    var p = String(u).split(',');
    var mime = 'image/jpeg';
    var m = p[0].match(/:(.*?);/);
    if (m) mime = m[1];
    var bin = atob(p[1] || '');
    var arr = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
    return new Blob([arr], { type: mime });
  },
  _makeCanvas(w, h) {
    var cv = null;
    try { if (typeof document !== 'undefined') cv = document.createElement('canvas'); } catch (e) {}
    if (!cv && typeof Canvas !== 'undefined') { try { cv = new Canvas(w, h); } catch (e) {} }
    if (cv) { try { cv.width = w; cv.height = h; } catch (e) {} }
    return cv;
  },
  async _drawCurrent() {
    if (!store.frames.length || !this._ctx) return;
    if (this._decBusy) return;
    var fr = store.frames[this._idx];
    this._decBusy = true;
    var bmp = null;
    try {
      if (fr && fr.kind === 'px') {
        // Raw pixels: put back onto an offscreen canvas, then drawImage
        // (Canvas is a documented drawImage source) scaled to the stage.
        if (!this._pxCv) this._pxCv = this._makeCanvas(fr.w || 480, fr.h || 352);
        if (!this._pxCv) throw new Error('no offscreen canvas for px frame');
        var pctx = this._pxCv.getContext('2d');
        pctx.putImageData(fr.img, 0, 0);
        this._ctx.drawImage(this._pxCv, 0, 0, 448, 170);
      } else if (fr && fr.kind === 'bmp') {
        this._ctx.drawImage(fr.bmp, 0, 0, 448, 170);
      } else {
        if (typeof createImageBitmap === 'undefined' || typeof atob === 'undefined') {
          this.setData({ status: '本机无 createImageBitmap/atob，帧图解码不可用，合成播放待真机（如实）', evt: 'EVT: decode n/a' });
          return;
        }
        var blob = this._dataUrlToBlob(frameUrl(fr));
        bmp = await createImageBitmap(blob);
        this._ctx.drawImage(bmp, 0, 0, 448, 170);
      }
      if (this._ctx.flush) this._ctx.flush();
      this._drawTimes.push(Date.now());
      if (this._drawTimes.length > 240) this._drawTimes.shift();
    } catch (e) {
      this.setData({ status: '帧绘制失败（如实）：' + String((e && e.message) || e).slice(0, 40), evt: 'EVT: draw fail' });
    } finally {
      if (bmp) { try { bmp.close(); } catch (e) {} }
      this._decBusy = false;
      this._render();
    }
  },
  _play() {
    if (!store.frames.length || this._playing) return;
    this._playing = true;
    this._drawCurrent();
    var self = this;
    var stepMs = Math.max(40, Math.round(1000 / FPS));
    this._timer = setInterval(function () {
      if (!self._playing) return;
      self._idx = (self._idx + 1) % store.frames.length;
      self._drawCurrent();
    }, stepMs);
    this._render();
    this.setData({ evt: 'EVT: looping @12fps' });
  },
  _stop() {
    this._playing = false;
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },
  _restart() {
    this._idx = 0;
    this._drawTimes = [];
    if (!this._playing) this._play();
    else this._drawCurrent();
    this._render();
    this.setData({ evt: 'EVT: replay from 0' });
  },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this._restart(); // diagnostic twin of the nod replay
  },
  onHeadGesture(event) {
    if (event && event.gesture === 'nod') this._restart();
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">PLAY · 合成播放</text>
    <canvas id="playCanvas" width="448" height="170" class="viewcv"></canvas>
    <text class="prog">{{progLine}}</text>
    <view class="rlist">
      <view ink:for="{{readLines}}" class="rrow">
        <text class="rlabel">{{item.l1}}</text>
        <text class="rval">{{item.v1}}</text>
        <text class="rlabel rlabel2">{{item.l2}}</text>
        <text class="rval">{{item.v2}}</text>
      </view>
    </view>
    <text class="status">{{status}}</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 15px; font-weight: 500; }
.viewcv { width: 448px; height: 170px; margin-top: 4px; border: 1px solid rgba(64,255,94,0.7); background-color: #021007; }
.prog { color: #40ff5e; font-family: monospace; font-size: 12px; margin-top: 4px; }
.rlist { display: flex; flex-direction: column; margin-top: 4px; border: 1px solid rgba(64,255,94,0.6); background-color: #04140a; padding: 4px 8px; }
.rrow { display: flex; flex-direction: row; margin-bottom: 2px; }
.rlabel { width: 56px; color: #40ff5e; font-size: 10px; font-family: monospace; }
.rlabel2 { margin-left: 14px; }
.rval { flex-grow: 1; color: #7dff9e; font-size: 10px; font-family: monospace; font-weight: 500; }
.status { color: rgba(125,255,158,0.9); font-size: 9px; margin-top: 3px; }
.footrow { display: flex; flex-direction: row; margin-top: 2px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
