<script def>
{
  "title": "Motion Watch"
}
</script>

<script setup>
import wx from 'wx';

var BKEY = 'av02_baseline';
var AKEY = 'av02_alert';

export default {
  data: {
    evt: 'EVT: watch ready（仅前台运行）',
    ver: 'v1.0.0',
    status: '单击开始监看 · 离开本页即停',
    watching: false,
    watchLabel: 'START 开始监看',
    diffText: '--.-%',
    diffCls: 'bigdiff',
    samples: 0,
    intervalText: '实测间隔 - ms',
    thrText: '阈值 -%',
    alertLine: ''
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._iv = null; this._stream = null; this._cap = null; this._lastAt = 0;
    var b = this._loadBase();
    if (b && b.data) this.setData({ thrText: '阈值 ' + (b.thr || 5) + '%' });
    else this.setData({ status: '未标定基线：先回中枢页拍基线' });
  },
  onHide() { this._stopWatch('页面隐藏，监看已停（仅前台运行）'); },
  onUnload() { this._stopWatch(''); },
  _loadBase() {
    try {
      var v = wx.getStorageSync(BKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return null;
  },
  onBackTap() { this._stopWatch(''); try { wx.navigateBack({}); } catch (e) {} },
  onWatchTap() { if (this.data.watching) this._stopWatch('监看已手动停止'); else this._startWatch(); },
  async _startWatch() {
    var self = this;
    var base = this._loadBase();
    if (!base || !base.data) { this.setData({ status: '未标定基线，无法监看' }); return; }
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined' || typeof document === 'undefined') {
        this.setData({ status: '宿主无相机/canvas，待真机监看', evt: 'EVT: camera n/a' });
        return;
      }
      this._stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = this._stream.getVideoTracks()[0];
      this._cap = new ImageCapture(track);
    } catch (e) {
      this.setData({ status: '取流失败（如实记录）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: stream fail' });
      return;
    }
    this.setData({ watching: true, watchLabel: 'STOP 停止监看', status: '监看中：约每 1200ms 抓一帧比对基线', samples: 0, evt: 'EVT: watch start' });
    this._speak('开始监看');
    this._lastAt = Date.now();
    this._iv = setInterval(function () { self._sample(base); }, 1200);
  },
  async _sample(base) {
    if (!this._cap) return;
    var now = Date.now();
    var gap = this._lastAt ? (now - this._lastAt) : 0;
    this._lastAt = now;
    try {
      var bmp = await this._cap.grabFrame();
      var cv = document.createElement('canvas');
      cv.width = 64; cv.height = 48;
      var ctx = cv.getContext('2d');
      ctx.drawImage(bmp, 0, 0, 64, 48);
      try { bmp.close(); } catch (e) {}
      var img = ctx.getImageData(0, 0, 64, 48).data;
      var changed = 0, total = base.data.length;
      for (var i = 0; i < total; i++) {
        var lum = Math.round((img[i * 4] + img[i * 4 + 1] + img[i * 4 + 2]) / 3);
        if (Math.abs(lum - base.data[i]) > 24) changed++;
      }
      var pct = Math.round(changed / total * 1000) / 10;
      var n = this.data.samples + 1;
      this.setData({
        samples: n,
        diffText: pct.toFixed(1) + '%',
        diffCls: pct >= (base.thr || 5) ? 'bigdiff bigdiff-alert' : 'bigdiff',
        intervalText: '实测间隔 ' + gap + ' ms · 官方未公布帧率上限，此为本机实测',
        evt: 'EVT: sample ' + n + ' diff ' + pct + '%'
      });
      if (pct >= (base.thr || 5)) {
        try { wx.setStorageSync(AKEY, { diff: pct, at: Date.now(), thr: base.thr || 5 }); } catch (e) {}
        this._stopWatch('超阈值 ' + pct + '% ≥ ' + (base.thr || 5) + '%，去存证判定');
        this._speak('点位有变化');
        try { wx.navigateTo({ url: '/pages/proof/index' }); } catch (e) {}
      }
    } catch (e) {
      this.setData({ evt: 'EVT: sample fail ' + String((e && e.message) || e).slice(0, 30) });
    }
  },
  _stopWatch(msg) {
    if (this._iv) { clearInterval(this._iv); this._iv = null; }
    if (this._stream) { try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} this._stream = null; }
    this._cap = null;
    if (this.data.watching) this.setData({ watching: false, watchLabel: 'START 开始监看' });
    if (msg) this.setData({ status: msg });
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
    if (k === 'Enter' || k === 'GlobalHook') this.onWatchTap();
    else if (k === 'ArrowDown' || k === 'ArrowUp') this.setData({ evt: 'EVT: diff ' + this.data.diffText + ' samples ' + this.data.samples });
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod' && !this.data.watching) this._startWatch(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="alertbtn alertbtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">WATCH · 监看</text>
      <text class="thr">{{thrText}}</text>
    </view>
    <text class="{{diffCls}}">{{diffText}}</text>
    <text class="cap">最近一帧变化像素占比</text>
    <view class="statrow">
      <text class="stat">采样 {{samples}} 次</text>
      <text class="stat">{{intervalText}}</text>
    </view>
    <text class="status">{{status}}</text>
    <button class="alertbtn alertbtn-main" bindtap="onWatchTap">{{watchLabel}}</button>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.alertbtn { border-top: 3px solid #40ff5e; border-bottom: 3px solid #40ff5e; border-left: 1px solid rgba(64,255,94,0.7); border-right: 1px solid rgba(64,255,94,0.7); background-color: #04140a; color: #7dff9e; text-align: center; }
.alertbtn-back { font-size: 10px; padding: 3px 8px; }
.alertbtn-main { font-size: 14px; font-weight: 500; padding: 10px 0; margin-top: 10px; background-color: rgba(64,255,94,0.18); }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.thr { color: #40ff5e; font-size: 11px; }
.bigdiff { color: #40ff5e; font-size: 52px; font-weight: 500; text-align: center; margin-top: 14px; }
.bigdiff-alert { color: #7dff9e; background-color: rgba(125,255,158,0.28); }
.cap { color: rgba(64,255,94,0.65); font-size: 10px; text-align: center; }
.statrow { display: flex; flex-direction: column; margin-top: 8px; }
.stat { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 10px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
