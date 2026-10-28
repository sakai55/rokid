<script def>
{
  "title": "Mic Rounds"
}
</script>

<script setup>
import wx from 'wx';

var EKEY = 'av04_env';
var RKEY = 'av04_rounds';
var MODES = ['wearer', 'far-field', 'near-field', 'omnidirectional'];
var SENTENCES = [
  '今天天气晴朗，我们走路去车站。',
  '请把会议纪要发到我的邮箱里。',
  '小声一点，孩子刚刚睡着了。',
  '这条街的尽头有一家面包店。'
];

export default {
  data: {
    evt: 'EVT: rounds ready',
    ver: 'v1.0.0',
    status: '每轮：听领读 → 单击开录 → 跟读测试句（约 3 秒）',
    envName: '-',
    roundText: '第 1/4 轮 · wearer',
    sentence: SENTENCES[0],
    heardLine: '参考转写：未测（仅参考分）',
    busy: false,
    lanes: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._idx = 0;
    this._results = [];
    var env = '-';
    try {
      var v = wx.getStorageSync(EKEY);
      var o = (typeof v === 'string') ? JSON.parse(v) : v;
      if (o && o.env) env = o.env;
    } catch (e) {}
    this.setData({ envName: env });
    this._syncRound();
  },
  _syncRound() {
    var idx = this._idx;
    var res = this._results;
    var lanes = MODES.map(function (m, i) {
      var r = res[i];
      var w = r ? Math.min(100, Math.round(r.rms * 300)) : 0;
      return {
        mode: m,
        line: r ? ('RMS ' + r.rms.toFixed(3) + ' · 峰值 ' + r.peak.toFixed(2) + (r.fellBack ? ' · exact→ideal' : '')) : (i === idx ? '当前轮' : '待测'),
        barCls: 'bar',
        cls: i === idx ? 'lane lane-cur' : (r ? 'lane lane-done' : 'lane')
      };
    });
    this.setData({
      lanes: lanes,
      roundText: idx < 4 ? ('第 ' + (idx + 1) + '/4 轮 · ' + MODES[idx]) : '四轮完成 · 去评分榜',
      sentence: SENTENCES[Math.min(idx, 3)]
    });
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onLeadTap() { this._speak('请跟读：' + this.data.sentence); },
  onRoundTap() { this._runRound(); },
  _listenRef() {
    var self = this;
    try {
      if (typeof SpeechRecognition === 'undefined') { this.setData({ heardLine: '参考转写：宿主无 ASR（仅参考分，缺失不影响排名）' }); return; }
      var r = new SpeechRecognition();
      r.interimResults = false;
      r.onresult = function (e) {
        try {
          var t = e.results[e.resultIndex][0].transcript;
          self.setData({ heardLine: '参考转写（仅参考）：「' + t + '」' + t.length + ' 字' });
          if (self._results[self._idx]) self._results[self._idx].refChars = t.length;
        } catch (err) {}
      };
      r.onerror = function () { self.setData({ heardLine: '参考转写：识别失败（如实记录，仅参考分）' }); };
      r.start();
    } catch (e) {}
  },
  async _runRound() {
    if (this.data.busy || this._idx >= 4) {
      if (this._idx >= 4) { try { wx.navigateTo({ url: '/pages/board/index' }); } catch (e) {} }
      return;
    }
    var mode = MODES[this._idx];
    var self = this;
    this.setData({ busy: true, status: '第 ' + (this._idx + 1) + ' 轮 ' + mode + '：取流中…', evt: 'EVT: round ' + mode });
    this._speak('请跟读：' + SENTENCES[this._idx]);
    var stream = null;
    var fellBack = false;
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices) throw new Error('mediaDevices n/a');
      try {
        stream = await navigator.mediaDevices.getUserMedia({ audio: { microphoneMode: { exact: mode } } });
      } catch (e1) {
        if (e1 && e1.name === 'OverconstrainedError') {
          stream = await navigator.mediaDevices.getUserMedia({ audio: { microphoneMode: { ideal: mode } } });
          fellBack = true;
        } else { throw e1; }
      }
      var track = stream.getAudioTracks()[0];
      var actual = '-';
      try { var st = track.getSettings(); if (st && st.microphoneMode) actual = st.microphoneMode; } catch (e) {}
      this._listenRef();
      var mime = '';
      try { if (typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')) mime = 'audio/ogg;codecs=opus'; } catch (e) {}
      var chunks = [];
      var rec = new MediaRecorder(stream, mime ? { mimeType: mime } : undefined);
      rec.ondataavailable = function (e) { if (e.data && e.data.size) chunks.push(e.data); };
      var stopped = new Promise(function (res) { rec.onstop = res; });
      rec.start(250);
      this.setData({ status: '录制中：请跟读测试句（3 秒）…' });
      await new Promise(function (res) { setTimeout(res, 3000); });
      rec.stop();
      await stopped;
      var blob = new Blob(chunks, { type: mime || 'audio/ogg' });
      // Level measurement: decode the recorded blob with decodeAudioData
      // and compute RMS / peak directly over the decoded channel data.
      var rms = 0, peak = 0, method = 'decodeAudioData channel data';
      try {
        var AC = typeof AudioContext !== 'undefined' ? AudioContext : null;
        if (!AC) throw new Error('AudioContext n/a');
        var actx = new AC();
        var abuf = await blob.arrayBuffer();
        var audio = await actx.decodeAudioData(abuf);
        var ch = audio.getChannelData(0);
        var sum = 0;
        for (var i = 0; i < ch.length; i++) { var v = Math.abs(ch[i]); sum += ch[i] * ch[i]; if (v > peak) peak = v; }
        rms = ch.length ? Math.sqrt(sum / ch.length) : 0;
        try { await actx.close(); } catch (e) {}
      } catch (e) { method = '解码失败（如实记录）：' + String((e && e.message) || e).slice(0, 28); }
      this._results[this._idx] = { mode: mode, actual: actual, fellBack: fellBack, rms: rms, peak: peak, refChars: 0, method: method };
      try { wx.setStorageSync(RKEY, { env: this.data.envName, results: this._results }); } catch (e) {}
      this.setData({ status: mode + ' 轮完成：回读 ' + actual + (fellBack ? ' · exact 不支持，已回退 ideal' : '') + ' · RMS ' + rms.toFixed(3), evt: 'EVT: round done ' + mode });
      this._speak(mode + '轮完成');
      this._idx++;
      this._syncRound();
      if (this._idx >= 4) {
        this.setData({ status: '四轮完成，去评分榜看结论' });
        setTimeout(function () { try { wx.navigateTo({ url: '/pages/board/index' }); } catch (e) {} }, 800);
      }
    } catch (e) {
      this.setData({ status: '本轮失败（如实记录）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: round fail' });
      this._results[this._idx] = { mode: mode, actual: '-', fellBack: fellBack, rms: 0, peak: 0, refChars: 0, method: '取流失败' };
      this._idx++;
      this._syncRound();
    } finally {
      if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} }
      this.setData({ busy: false });
    }
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
    if (k === 'Enter' || k === 'GlobalHook') this._runRound();
    else if (k === 'ArrowDown' || k === 'ArrowUp') this.onLeadTap();
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod' && !this.data.busy) this._runRound(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="lanebtn lanebtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">ROUNDS · 四轮录制</text>
      <text class="env">{{envName}}</text>
    </view>
    <text class="round">{{roundText}}</text>
    <text class="sentence">测试句：{{sentence}}</text>
    <view class="lanes">
      <view ink:for="{{lanes}}" class="{{item.cls}}">
        <text class="lmode">{{item.mode}}</text>
        <view class="track"><view class="bar"></view></view>
        <text class="lline">{{item.line}}</text>
      </view>
    </view>
    <text class="heard">{{heardLine}}</text>
    <text class="status">{{status}}</text>
    <view class="btnrow">
      <button class="lanebtn" bindtap="onLeadTap">LEAD 领读</button>
      <button class="lanebtn" bindtap="onRoundTap">REC 本轮录制</button>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.lanebtn { border-left: 6px solid #40ff5e; border-top: 1px solid rgba(64,255,94,0.7); border-bottom: 1px solid rgba(64,255,94,0.7); border-right: 1px solid rgba(64,255,94,0.7); background-color: #0a1f0e; color: #7dff9e; font-size: 11px; padding: 7px 0; text-align: center; flex-grow: 1; margin-right: 6px; }
.lanebtn-back { flex-grow: 0; padding: 3px 8px; font-size: 10px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.env { color: #40ff5e; font-size: 12px; }
.round { color: #7dff9e; font-size: 14px; font-weight: 500; margin-top: 7px; }
.sentence { color: rgba(125,255,158,0.95); font-size: 12px; margin-top: 3px; }
.lanes { display: flex; flex-direction: column; margin-top: 7px; }
.lane { display: flex; flex-direction: row; align-items: center; border-left: 8px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 5px 8px; margin-bottom: 4px; }
.lane-cur { border-left: 8px solid #7dff9e; background-color: #0a1f0e; }
.lane-done { border-left: 8px solid #40ff5e; }
.lmode { color: #40ff5e; font-family: monospace; font-size: 10px; width: 108px; }
.track { flex-grow: 1; height: 8px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.5); margin-right: 8px; }
.bar { height: 8px; background-color: rgba(64,255,94,0.55); width: 40px; }
.lline { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 9px; }
.heard { color: rgba(64,255,94,0.7); font-size: 10px; margin-top: 4px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 3px; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
