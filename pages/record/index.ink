<script def>
{
  "title": "Chunk Record"
}
</script>

<script setup>
import wx from 'wx';

var PKEY = 'av03_pick';
var LKEY = 'av03_last';
var DURS = [30, 60, 120];

export default {
  data: {
    evt: 'EVT: record ready',
    ver: 'v1.0.0',
    status: '选时长后单击开始 · 分片 1 秒一片',
    placeholder: '录后回放待真机验证（placeholder）：本页不假装能回放',
    mimeText: '格式 -',
    durIdx: 1,
    durText: '60s',
    clock: '00:00',
    chunkText: '分片 0 · 0B',
    dots: [],
    recState: 'idle',
    recLabel: 'REC 开始录制'
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._stream = null; this._rec = null; this._iv = null;
    this._chunks = 0; this._bytes = 0; this._t0 = 0; this._lastTts = 0;
    var mime = '';
    try {
      var v = wx.getStorageSync(PKEY);
      var o = (typeof v === 'string') ? JSON.parse(v) : v;
      if (o && o.mime) mime = o.mime;
    } catch (e) {}
    this._mime = mime;
    this.setData({ mimeText: '格式 ' + (mime || '宿主默认（探针无可用视频格式）') });
    this._syncDots();
  },
  onHide() { this._cleanup(); },
  onUnload() { this._cleanup(); },
  _cleanup() {
    if (this._iv) { clearInterval(this._iv); this._iv = null; }
    if (this._rec && this._rec.state !== 'inactive') { try { this._rec.stop(); } catch (e) {} }
    this._rec = null;
    if (this._stream) { try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} this._stream = null; }
  },
  _syncDots() {
    var dots = [];
    for (var i = 0; i < 12; i++) dots.push({ cls: i < this._chunks % 13 ? 'dot dot-on' : 'dot' });
    this.setData({ dots: dots });
  },
  _fmtClock(sec) {
    var m = Math.floor(sec / 60), s = sec % 60;
    return (m < 10 ? '0' + m : '' + m) + ':' + (s < 10 ? '0' + s : '' + s);
  },
  onBackTap() { this._cleanup(); try { wx.navigateBack({}); } catch (e) {} },
  onDurTap() {
    if (this.data.recState === 'recording') return;
    var n = (this.data.durIdx + 1) % DURS.length;
    this.setData({ durIdx: n, durText: DURS[n] + 's', evt: 'EVT: dur ' + DURS[n] });
    this._dur = DURS[n];
  },
  onVoiceDurTap() { this._listenDur(); },
  _listenDur() {
    var self = this;
    try {
      if (typeof SpeechRecognition === 'undefined') {
        this.setData({ status: '宿主无 SpeechRecognition，待真机语音定时长', evt: 'EVT: asr n/a' });
        return;
      }
      var r = new SpeechRecognition();
      r.interimResults = true;
      r.onresult = function (e) {
        try {
          var t = e.results[e.resultIndex][0].transcript;
          var m = t.match(/(\d{1,3})/);
          if (m) {
            var sec = Math.max(5, Math.min(600, parseInt(m[1], 10)));
            self._dur = sec;
            self.setData({ durText: sec + 's（语音）', status: '语音时长已设 ' + sec + ' 秒 · 听错可重说', evt: 'EVT: asr dur ' + sec });
          }
        } catch (err) {}
      };
      r.onerror = function (e) {
        self.setData({ status: '语音失败（如实记录）：' + (e && e.error ? e.error : 'unknown') + ' · 可重说或点按切换档位', evt: 'EVT: asr error' });
      };
      r.start();
      this.setData({ status: '聆听中：说「录 90 秒」这样的秒数…', evt: 'EVT: asr start' });
    } catch (e) { this.setData({ status: '语音启动失败，待真机', evt: 'EVT: asr throw' }); }
  },
  onRecTap() {
    if (this.data.recState === 'recording' || this.data.recState === 'paused') this._stopRec();
    else this._startRec();
  },
  onPauseTap() {
    if (!this._rec) return;
    try {
      if (this._rec.state === 'recording') { this._rec.pause(); this.setData({ recState: 'paused', recLabel: 'STOP 停止', status: '已暂停（pause）· 再点录制钮停止' }); }
      else if (this._rec.state === 'paused') { this._rec.resume(); this.setData({ recState: 'recording', status: '已继续（resume）' }); }
    } catch (e) { this.setData({ status: 'pause/resume 失败（如实记录）：' + String((e && e.message) || e).slice(0, 36) }); }
  },
  async _startRec() {
    var self = this;
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof MediaRecorder === 'undefined') {
        this.setData({ status: '宿主无 MediaRecorder/相机，待真机录制', evt: 'EVT: rec n/a' });
        return;
      }
      this._stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      var opts = this._mime ? { mimeType: this._mime } : undefined;
      this._rec = new MediaRecorder(this._stream, opts);
      this._chunks = 0; this._bytes = 0; this._t0 = Date.now(); this._lastTts = 0;
      this._rec.ondataavailable = function (e) {
        if (e.data && e.data.size) { self._chunks++; self._bytes += e.data.size; self._syncDots(); }
      };
      this._rec.onstop = function () { self._finish(); };
      this._rec.start(1000);
      var target = this._dur || DURS[this.data.durIdx];
      this.setData({ recState: 'recording', recLabel: 'STOP 停止', status: '录制中 · 目标 ' + target + 's · 每 10s 语音报时', evt: 'EVT: rec start ' + target + 's' });
      this._speak('开始录制');
      this._iv = setInterval(function () { self._tick(target); }, 1000);
    } catch (e) {
      this.setData({ status: '录制启动失败（如实记录）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: rec fail' });
      this._cleanup();
    }
  },
  _tick(target) {
    var sec = Math.floor((Date.now() - this._t0) / 1000);
    var mbPerMin = sec > 0 ? (this._bytes / 1048576) / (sec / 60) : 0;
    this.setData({
      clock: this._fmtClock(sec),
      chunkText: '分片 ' + this._chunks + ' · ' + this._bytes + 'B · 约 ' + mbPerMin.toFixed(2) + ' MB/分钟'
    });
    if (sec > 0 && sec % 10 === 0 && sec !== this._lastTts) {
      this._lastTts = sec;
      this._speak('已录' + sec + '秒，约' + mbPerMin.toFixed(1) + '兆每分钟');
    }
    if (sec >= target) this._stopRec();
  },
  _stopRec() {
    if (this._iv) { clearInterval(this._iv); this._iv = null; }
    if (this._rec && this._rec.state !== 'inactive') { try { this._rec.stop(); } catch (e) { this._finish(); } }
    else this._finish();
  },
  _finish() {
    var sec = this._t0 ? Math.round((Date.now() - this._t0) / 1000) : 0;
    var last = { chunks: this._chunks, bytes: this._bytes, durSec: sec, mime: this._mime || 'default', at: Date.now() };
    try { wx.setStorageSync(LKEY, last); } catch (e) {}
    if (this._stream) { try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} this._stream = null; }
    this._rec = null;
    this.setData({ recState: 'idle', recLabel: 'REC 开始录制', status: '录制结束，去结算', evt: 'EVT: rec done ' + sec + 's' });
    this._speak('录制结束');
    try { wx.navigateTo({ url: '/pages/settle/index' }); } catch (e) {}
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
    if (k === 'Enter' || k === 'GlobalHook') this.onRecTap();
    else if (k === 'ArrowDown') this.onDurTap();
    else if (k === 'ArrowUp') this.onPauseTap();
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod' && this.data.recState === 'idle') this._startRec(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="dialbtn dialbtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">RECORD · 录制</text>
      <text class="mime">{{mimeText}}</text>
    </view>
    <text class="clock">{{clock}}</text>
    <view class="dotrow">
      <view ink:for="{{dots}}" class="{{item.cls}}"></view>
    </view>
    <text class="chunks">{{chunkText}}</text>
    <text class="status">{{status}}</text>
    <text class="ph">{{placeholder}}</text>
    <view class="btnrow">
      <button class="dialbtn" bindtap="onDurTap">时长 {{durText}}</button>
      <button class="dialbtn" bindtap="onVoiceDurTap">VOICE 语音定</button>
      <button class="dialbtn" bindtap="onPauseTap">PAUSE 暂停/继续</button>
    </view>
    <button class="recbtn" bindtap="onRecTap">{{recLabel}}</button>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.dialbtn { border-radius: 24px; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.14); color: #7dff9e; font-size: 11px; padding: 6px 0; text-align: center; flex-grow: 1; margin-right: 6px; }
.dialbtn-back { flex-grow: 0; padding: 3px 10px; font-size: 10px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.mime { color: rgba(64,255,94,0.7); font-family: monospace; font-size: 9px; }
.clock { color: #7dff9e; font-family: monospace; font-size: 46px; font-weight: 500; text-align: center; margin-top: 10px; }
.dotrow { display: flex; flex-direction: row; justify-content: center; margin-top: 6px; }
.dot { width: 10px; height: 10px; border-radius: 5px; border: 1px solid rgba(64,255,94,0.6); background-color: #04140a; margin-right: 5px; }
.dot-on { background-color: #40ff5e; }
.chunks { color: #40ff5e; font-family: monospace; font-size: 11px; text-align: center; margin-top: 6px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; text-align: center; margin-top: 5px; }
.ph { color: rgba(64,255,94,0.6); font-size: 9px; text-align: center; margin-top: 3px; }
.btnrow { display: flex; flex-direction: row; margin-top: 9px; }
.recbtn { width: 120px; height: 52px; border-radius: 26px; border: 3px solid #7dff9e; background-color: rgba(125,255,158,0.25); color: #7dff9e; font-size: 13px; font-weight: 500; text-align: center; margin-top: 10px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
