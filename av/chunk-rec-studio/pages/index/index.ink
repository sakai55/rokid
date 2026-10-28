<script def>
{
  "title": "Chunk Rec Studio"
}
</script>

<script setup>
import wx from 'wx';

var PKEY = 'av03_pick';
var CANDIDATES = ['video/mp4', 'video/webm;codecs=vp8,opus', 'audio/ogg;codecs=opus', 'audio/wav'];
var MENU = [
  { name: '切换录制格式', hint: '在探针支持的视频格式间切换', act: 'fmt' },
  { name: '用选中格式录制', hint: '去录制页', act: 'record' },
  { name: '上次结算', hint: '看最近一次分片结算', act: 'settle' },
  { name: '录制历史', hint: '全部场次与总计', act: 'history' }
];

export default {
  data: {
    evt: 'EVT: probe ready',
    ver: 'v1.0.0',
    status: '探针：逐项查 MediaRecorder.isTypeSupported',
    probeRows: [],
    settingsLine: '轨道设置：未回读',
    constraintLine: '约束字段：未列出',
    selFmt: '（无可用视频格式）',
    fmtIdx: 0,
    selIdx: 0,
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._videoFmts = [];
    this._probe();
    this._syncMenu();
  },
  onShow() { this._syncMenu(); },
  _probe() {
    var self = this;
    var rows = CANDIDATES.map(function (m) {
      var ok = false;
      try { ok = (typeof MediaRecorder !== 'undefined') && !!MediaRecorder.isTypeSupported(m); } catch (e) {}
      if (ok && m.indexOf('video/') === 0) self._videoFmts.push(m);
      return { mime: m, res: ok ? '支持' : '不支持', cls: ok ? 'prow prow-ok' : 'prow' };
    });
    this.setData({ probeRows: rows, evt: 'EVT: probe done video=' + this._videoFmts.length });
    if (this._videoFmts.length) {
      this.setData({ fmtIdx: 0, selFmt: this._videoFmts[0] });
      try { wx.setStorageSync(PKEY, { mime: this._videoFmts[0], dur: 60 }); } catch (e) {}
    } else {
      this.setData({ status: '探针完成：宿主无可用视频格式时录制页将如实报错，待真机' });
    }
    this._readTracks();
  },
  async _readTracks() {
    var stream = null;
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices) {
        this.setData({ settingsLine: '轨道设置：宿主无 mediaDevices，待真机回读' });
        return;
      }
      stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      var vt = stream.getVideoTracks()[0];
      var at = stream.getAudioTracks()[0];
      var vs = vt && vt.getSettings ? vt.getSettings() : {};
      var as = at && at.getSettings ? at.getSettings() : {};
      this.setData({
        settingsLine: '视频 ' + (vs.width || '?') + 'x' + (vs.height || '?') + ' @' + (vs.frameRate || '?') + 'fps · 音频 ' + (as.sampleRate || '?') + 'Hz/' + (as.channelCount || '?') + 'ch',
        evt: 'EVT: tracks read'
      });
      var cons = {};
      try { cons = navigator.mediaDevices.getSupportedConstraints ? navigator.mediaDevices.getSupportedConstraints() : {}; } catch (e) {}
      var fields = Object.keys(cons).filter(function (k) { return cons[k]; });
      this.setData({ constraintLine: '约束字段(' + fields.length + ')：' + (fields.slice(0, 8).join(', ') || '无') });
    } catch (e) {
      this.setData({ settingsLine: '轨道回读失败（如实记录）：' + String((e && e.message) || e).slice(0, 40) });
    } finally {
      if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} }
    }
  },
  _syncMenu() {
    var sel = this.data.selIdx;
    var rows = MENU.map(function (m, i) {
      return { name: m.name, hint: m.hint, cls: i === sel ? 'mrow mrow-sel' : 'mrow', mark: i === sel ? '▸' : '·' };
    });
    this.setData({ rows: rows });
  },
  _move(dir) {
    var n = (this.data.selIdx + dir + MENU.length) % MENU.length;
    this.setData({ selIdx: n, evt: 'EVT: menu ' + MENU[n].name });
    this._syncMenu();
  },
  onFmtTap() { this._cycleFmt(); },
  _cycleFmt() {
    if (!this._videoFmts.length) return;
    var n = (this.data.fmtIdx + 1) % this._videoFmts.length;
    this.setData({ fmtIdx: n, selFmt: this._videoFmts[n], evt: 'EVT: fmt ' + this._videoFmts[n] });
    try {
      var v = wx.getStorageSync(PKEY);
      var o = (typeof v === 'string') ? JSON.parse(v) : (v || {});
      o.mime = this._videoFmts[n];
      wx.setStorageSync(PKEY, o);
    } catch (e) {}
    this._speak('格式' + this._videoFmts[n]);
  },
  onRowTap(e) {
    var i = this.data.selIdx;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this.data.selIdx;
    this.setData({ selIdx: i });
    this._activate(i);
  },
  _activate(i) {
    var act = MENU[i] && MENU[i].act;
    if (act === 'fmt') this._cycleFmt();
    else if (act === 'record') { try { wx.navigateTo({ url: '/pages/record/index' }); } catch (e) {} }
    else if (act === 'settle') { try { wx.navigateTo({ url: '/pages/settle/index' }); } catch (e) {} }
    else if (act === 'history') { try { wx.navigateTo({ url: '/pages/history/index' }); } catch (e) {} }
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
    if (k === 'Enter' || k === 'GlobalHook') this._activate(this.data.selIdx);
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._activate(this.data.selIdx); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">CHUNK REC STUDIO · 分片录制工坊</text>
    <text class="status">{{status}}</text>
    <view class="plist">
      <view ink:for="{{probeRows}}" class="{{item.cls}}">
        <text class="pmime">{{item.mime}}</text>
        <text class="pres">{{item.res}}</text>
      </view>
    </view>
    <text class="sline">{{settingsLine}}</text>
    <text class="sline">{{constraintLine}}</text>
    <button class="dialbtn" bindtap="onFmtTap">格式 {{selFmt}}（点此切换）</button>
    <view class="mlist">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="onRowTap" data-idx="{{index}}">
        <text class="mname">{{item.mark}} {{item.name}}</text>
        <text class="mhint">{{item.hint}}</text>
      </view>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 15px; font-weight: 500; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 5px; }
.plist { display: flex; flex-direction: column; margin-top: 6px; }
.prow { display: flex; flex-direction: row; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 3px 10px; margin-bottom: 3px; }
.prow-ok { border-color: #40ff5e; background-color: #0a1f0e; }
.pmime { flex-grow: 1; color: rgba(125,255,158,0.9); font-family: monospace; font-size: 10px; }
.pres { color: #40ff5e; font-size: 11px; }
.sline { color: rgba(64,255,94,0.7); font-family: monospace; font-size: 9px; margin-top: 3px; }
.dialbtn { border-radius: 24px; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.14); color: #7dff9e; font-size: 11px; padding: 6px 0; text-align: center; margin-top: 7px; }
.mlist { display: flex; flex-direction: column; margin-top: 7px; }
.mrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 5px 10px; margin-bottom: 4px; border-radius: 12px; }
.mrow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.mname { color: #40ff5e; font-size: 13px; font-weight: 500; }
.mhint { color: rgba(64,255,94,0.62); font-size: 10px; margin-left: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
