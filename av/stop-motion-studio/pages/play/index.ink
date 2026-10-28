<script def>
{
  "title": "Stop Motion Play"
}
</script>

<script setup>
import wx from 'wx';
import { store } from '../../store.js';

var CFGKEY = 'av11_cfg';
var WORKSKEY = 'av11_works';
var SPEEDS = [
  { key: 'slow', label: '慢速', fps: 5 },
  { key: 'mid', label: '中速', fps: 8 },
  { key: 'fast', label: '快速', fps: 12 }
];

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
function reasonLabel(r) { return r === 'target' ? '拍够了' : (r === 'time' ? '满 3 分钟了' : (r === 'user' ? '手动结束' : '—')); }
var MENU = [
  { name: '播放/暂停', act: 'toggle' },
  { name: '重播', act: 'replay' },
  { name: '循环开关', act: 'loop' },
  { name: '删最后一帧', act: 'del' },
  { name: '回拍摄补拍', act: 'shoot' }
];

export default {
  data: {
    evt: 'EVT: play ready',
    ver: 'v1.0.0',
    status: '合成 = 按设定帧率逐帧播放帧序列（不是生成视频文件）',
    progLine: '帧 0/0',
    readLines: [],
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._sel = 0; this._ctx = null; this._timer = null; this._playing = false;
    this._idx = 0; this._loop = false; this._drawTimes = []; this._decBusy = false;
    this._cfg = sget(CFGKEY) || defCfg();
    this._fps = speedOf(this._cfg).fps;
    if (!store.frames.length) this.setData({ status: '会话内暂无帧：先去拍摄页拍帧，再回来合成播放' });
    this._render();
  },
  onReady() { try { if (wx.createCanvasContext) this._ctx = wx.createCanvasContext('playCanvas'); } catch (e) { this._ctx = null; } this._drawCurrent(); },
  onHide() { this._pause(); this._persistMeasured(); },
  onUnload() { this._pause(); this._persistMeasured(); },
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
    var sel = this._sel || 0;
    var rows = MENU.map(function (m, i) {
      return { name: m.name, cls: i === sel ? 'mrow mrow-sel' : 'mrow', mark: i === sel ? '▸' : '·' };
    });
    var n = store.frames.length;
    var total = this._totals();
    var meas = this._measured();
    if (meas) store.measuredFps = meas;
    var reads = [
      { l1: '设定帧率', v1: this._fps + ' fps', l2: '实测帧率', v2: meas ? (meas + ' fps') : '未测（播放后出）' },
      { l1: '已拍张数', v1: n + ' / 目标 ' + (store.target || 0), l2: '单帧平均', v2: n ? (Math.round((total / n / 102.4)) / 10 + ' KB') : '-' },
      { l1: '帧总大小', v1: n ? (Math.round((total / 102.4)) / 10 + ' KB') : '-', l2: '拍摄耗时', v2: (store.shootSec || 0) + ' s' },
      { l1: '停因', v1: reasonLabel(store.stopReason), l2: '推算成片', v2: n ? (Math.round((n / this._fps) * 10) / 10 + ' s') : '-' }
    ];
    this.setData({
      rows: rows,
      readLines: reads,
      progLine: '帧 ' + (n ? Math.min(this._idx + 1, n) : 0) + '/' + n + ' · 循环' + (this._loop ? '开' : '关') + (this._playing ? ' · 播放中' : ' · 已停')
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
  async _drawCurrent() {
    if (!store.frames.length || !this._ctx) return;
    if (this._decBusy) return;
    if (typeof createImageBitmap === 'undefined' || typeof atob === 'undefined') {
      this.setData({ status: '本机无 createImageBitmap/atob，帧图解码不可用，合成播放待真机（如实）', evt: 'EVT: decode n/a' });
      return;
    }
    this._decBusy = true;
    var bmp = null;
    try {
      var blob = this._dataUrlToBlob(store.frames[this._idx]);
      bmp = await createImageBitmap(blob);
      this._ctx.drawImage(bmp, 0, 0, 448, 160);
      if (this._ctx.flush) this._ctx.flush();
      this._drawTimes.push(Date.now());
      if (this._drawTimes.length > 240) this._drawTimes.shift();
    } catch (e) {
      this.setData({ status: '帧解码/绘制失败（如实）：' + String((e && e.message) || e).slice(0, 40), evt: 'EVT: draw fail' });
    } finally {
      if (bmp) { try { bmp.close(); } catch (e) {} }
      this._decBusy = false;
      this._render();
    }
  },
  _play() {
    if (!store.frames.length) { this.setData({ status: '无帧可播：先去拍摄', evt: 'EVT: play empty' }); return; }
    if (this._idx >= store.frames.length - 1) this._idx = 0;
    this._playing = true;
    this._drawTimes = [];
    var self = this;
    var stepMs = Math.max(40, Math.round(1000 / this._fps));
    this._drawCurrent();
    this._timer = setInterval(function () {
      if (!self._playing) return;
      if (self._idx >= store.frames.length - 1) {
        if (self._loop) { self._idx = 0; self._drawCurrent(); return; }
        self._pause();
        self._persistMeasured();
        self._speak('播放结束');
        self.setData({ status: '播放结束：实测帧率与读数见验证面板' });
        return;
      }
      self._idx++;
      self._drawCurrent();
    }, stepMs);
    this._render();
    this.setData({ evt: 'EVT: playing @' + this._fps + 'fps' });
  },
  _pause() {
    this._playing = false;
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
    this._render();
  },
  _activate(i) {
    var d = MENU[i]; if (!d) return;
    this._sel = i;
    if (d.act === 'toggle') { if (this._playing) { this._pause(); this._persistMeasured(); this.setData({ evt: 'EVT: pause' }); } else this._play(); }
    else if (d.act === 'replay') { this._pause(); this._idx = 0; this._drawTimes = []; this._play(); }
    else if (d.act === 'loop') { this._loop = !this._loop; this._render(); this.setData({ evt: 'EVT: loop ' + this._loop }); }
    else if (d.act === 'del') {
      this._pause();
      if (store.frames.length) {
        store.frames.pop();
        store.sizes.pop();
        if (this._idx >= store.frames.length) this._idx = Math.max(0, store.frames.length - 1);
        this._persistMeasured();
        this.setData({ status: '已删最后一帧，现 ' + store.frames.length + ' 帧；可回拍摄页补拍', evt: 'EVT: del last' });
        this._drawCurrent();
      } else this.setData({ status: '已无帧可删', evt: 'EVT: del empty' });
      this._render();
    }
    else if (d.act === 'shoot') {
      this._pause();
      store.stopReason = ''; // retake continuation: shoot page must not reset
      try { wx.navigateTo({ url: '/pages/shoot/index' }); } catch (e) {}
    }
    this._render();
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
  onHeadGesture(event) { if (event && event.gesture === 'nod') { if (this._playing) { this._pause(); this._persistMeasured(); } else this._play(); } }
};
</script>

<page>
  <view class="page">
    <text class="ttl">PLAY · 合成播放</text>
    <canvas id="playCanvas" width="448" height="160" class="viewcv"></canvas>
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
.viewcv { width: 448px; height: 160px; margin-top: 4px; border: 1px solid rgba(64,255,94,0.7); background-color: #021007; }
.prog { color: #40ff5e; font-family: monospace; font-size: 11px; margin-top: 4px; }
.rlist { display: flex; flex-direction: column; margin-top: 4px; border: 1px solid rgba(64,255,94,0.6); background-color: #04140a; padding: 4px 8px; }
.rrow { display: flex; flex-direction: row; margin-bottom: 2px; }
.rlabel { width: 56px; color: #40ff5e; font-size: 10px; font-family: monospace; }
.rlabel2 { margin-left: 14px; }
.rval { flex-grow: 1; color: #7dff9e; font-size: 10px; font-family: monospace; font-weight: 500; }
.status { color: rgba(125,255,158,0.9); font-size: 9px; margin-top: 3px; }
.mlist { display: flex; flex-direction: row; flex-wrap: wrap; margin-top: 4px; }
.mrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 3px 6px; margin-right: 4px; margin-bottom: 3px; }
.mrow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.mname { color: #40ff5e; font-size: 10px; }
.footrow { display: flex; flex-direction: row; margin-top: 1px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
