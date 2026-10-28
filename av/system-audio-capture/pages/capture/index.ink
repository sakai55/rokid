<script def>
{"title": "System Audio Capture"}
</script>

<script setup>
import wx from 'wx';

// AV10 capture: chunked recording of the system-audio source.
// Same source discipline as the gate page: only the system-audio
// capture source is ever requested, no mic mode, no echo-cancel
// constraint, and failure never falls back to a microphone stream.
// MediaRecorder runs with start(250) timeslices; the live Analyser
// level proves the sound is playback, not room sound. The finished
// Blob cannot enter wx storage directly, so it is handed to the
// next pages as a dataURL in the temp key av10_tmp.
const TMP = 'av10_tmp';
const ACTS = ['开始内录', '停止内录', '返回 BACK'];
const SIZE_LIMIT = 500 * 1024;

export default {
  data: {
    status: '内录：让设备先播放声音，再开始内录',
    mimeLine: '格式：未定（开录时查 isTypeSupported）',
    chunkLine: '分片：0 片 · 累计 0 B',
    levelBlocks: '░░░░░░░░░░░░',
    levelLine: '电平：—（录中实时，证明来源是播放声）',
    sizeLine: '大小提示：—',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() {
    this._focus = 0; this._steady = false;
    this._stream = null; this._rec = null; this._ctx = null; this._analyser = null; this._timer = null;
    this._chunks = []; this._bytes = 0; this._mime = '';
    this._render();
  },
  onUnload() { this._cleanup(false); },

  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() { this.setData({ focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）' }); },
  _blocks(rms) { const n = Math.max(0, Math.min(12, Math.round(rms * 36))); let s = ''; for (let i = 0; i < 12; i++) s += (i < n ? '█' : '░'); return s; },
  _cleanup(stopRec) {
    try { if (this._timer) { clearInterval(this._timer); this._timer = null; } } catch (e) {}
    try { if (stopRec && this._rec && this._rec.state === 'recording') this._rec.stop(); } catch (e) {}
    try { if (this._stream) { this._stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} }); this._stream = null; } } catch (e) {}
    try { if (this._ctx) { this._ctx.close(); this._ctx = null; } } catch (e) {}
    this._analyser = null;
  },

  async startTap() {
    if (this._rec) { this.setData({ evt: 'EVT: start refused - already recording' }); return; }
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw new Error('getUserMedia 不可用');
      if (typeof MediaRecorder === 'undefined') throw new Error('MediaRecorder 不可用');
      const stream = await nav.mediaDevices.getUserMedia({ audio: { captureSource: 'system-audio' } });
      this._stream = stream;
      let mime = '';
      let mimeTxt = '格式：默认（isTypeSupported 不可用，浏览器决定）';
      try {
        if (typeof MediaRecorder.isTypeSupported === 'function') {
          if (MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')) { mime = 'audio/ogg;codecs=opus'; mimeTxt = '格式：audio/ogg;codecs=opus（首选，已确认支持）'; }
          else mimeTxt = '格式：回退默认（opus ogg 不支持，浏览器决定，已标注）';
        }
      } catch (e) {}
      this._mime = mime;
      const rec = mime ? new MediaRecorder(stream, { mimeType: mime }) : new MediaRecorder(stream);
      this._chunks = []; this._bytes = 0;
      const self = this;
      rec.ondataavailable = function (e) {
        try {
          if (e.data && e.data.size) { self._chunks.push(e.data); self._bytes += e.data.size; self.setData({ chunkLine: '分片：' + self._chunks.length + ' 片 · 累计 ' + self._bytes + ' B（每 250ms 一片）' }); }
        } catch (err) {}
      };
      rec.onstop = function () { self._finish(); };
      this._rec = rec;
      rec.start(250);
      try {
        const AC = (typeof AudioContext !== 'undefined') ? AudioContext : null;
        if (AC) { this._ctx = new AC(); this._analyser = this._ctx.createAnalyser(); this._analyser.fftSize = 512; this._ctx.createMediaStreamSource(stream).connect(this._analyser); }
      } catch (e) { this._analyser = null; }
      this._timer = setInterval(() => {
        try {
          if (!self._analyser) return;
          const buf = new Float32Array(self._analyser.fftSize);
          self._analyser.getFloatTimeDomainData(buf);
          let sum = 0; for (let i = 0; i < buf.length; i++) sum += buf[i] * buf[i];
          const rms = Math.sqrt(sum / buf.length);
          self.setData({ levelBlocks: self._blocks(rms), levelLine: '电平：RMS ' + rms.toFixed(3) + '（录中实时，证明来源是播放声）' });
        } catch (e) {}
      }, 200);
      this.setData({ status: '内录中：播放声正在被录下，Enter 停录', mimeLine: mimeTxt, evt: 'EVT: recording started' });
      this._speak('内录开始');
    } catch (e) {
      this.setData({ status: '开录失败：' + this._err(e) + '。永不回退麦克风', evt: 'EVT: record FAIL no-fallback ' + this._err(e) });
      this._cleanup(false); this._rec = null;
    }
  },
  stopTap() {
    if (!this._rec) { this.setData({ evt: 'EVT: stop refused - not recording' }); return; }
    this.setData({ status: '正在停录并汇总分片…', evt: 'EVT: stopping' });
    try { if (this._timer) { clearInterval(this._timer); this._timer = null; } } catch (e) {}
    try { this._rec.stop(); } catch (e) { this._finish(); }
  },
  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      const buf = await blob.arrayBuffer();
      const bytes = new Uint8Array(buf);
      let bin = '';
      const CH = 0x8000;
      for (let i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'audio/ogg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: ' + this._err(e));
    }
  },
  async _finish() {
    const rec = this._rec; this._rec = null;
    try {
      const type = this._mime || (rec && rec.mimeType) || 'audio/ogg';
      const blob = new Blob(this._chunks, { type: type });
      const url = await this._blobToDataUrl(blob);
      const over = blob.size > SIZE_LIMIT;
      try { wx.setStorageSync(TMP, { dataUrl: url, size: blob.size, mime: type, chunks: this._chunks.length, time: new Date().toISOString(), transcript: '' }); } catch (e) {
        this.setData({ status: '停录完成但临时键写入失败：' + this._err(e) + '（录音过大时可能存不下，如实）', evt: 'EVT: tmp save FAIL' });
        this._cleanup(false); return;
      }
      this.setData({
        status: '停录完成：' + blob.size + ' B 已存临时键 av10_tmp，去转写页',
        sizeLine: over ? '大小提示：超过 500KB，过长录音 dataURL 可能存不下；本条已尝试存入，转写若失败如实标注，仅保留前段转写路径为 placeholder' : '大小提示：500KB 以内，临时键可容纳',
        evt: 'EVT: recorded ' + blob.size + 'B in ' + this._chunks.length + ' chunks'
      });
      this._speak('内录完成');
    } catch (e) {
      this.setData({ status: '汇总失败：' + this._err(e), evt: 'EVT: finish FAIL ' + this._err(e) });
    } finally { this._cleanup(false); }
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.startTap(); else if (this._focus === 1) this.stopTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (k === 'Enter') {  this.doAct(); }
    else if (k === 'ArrowUp') {  this.moveTap(-1); }
    else if (k === 'ArrowDown') {  this.moveTap(1); }
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">System Audio Capture · 内录</text>
    <text class="status">{{status}}</text>
    <view class="wavebox">
      <text class="blocks">{{levelBlocks}}</text>
      <text class="wline">{{levelLine}}</text>
      <text class="wline">{{chunkLine}}</text>
      <text class="wline dim">{{mimeLine}}</text>
    </view>
    <text class="line dim">{{sizeLine}}</text>
    <button class="wide" bindtap="actTap" data-idx="0">开始内录</button>
    <button class="wide alt" bindtap="actTap" data-idx="1">停止内录（Enter 停录）</button>
    <button class="wide alt" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">本页按来源门纪律独立开流；录音 Blob 不能直接进 wx 存储，转 dataURL 存临时键 av10_tmp 交下一页。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.wavebox { border: 1px solid rgba(125,255,158,0.6); background-color: #0a1f0e; padding: 6px 8px; margin-top: 5px; }
.blocks { color: #40ff5e; font-size: 20px; line-height: 24px; letter-spacing: 3px; }
.wline { color: rgba(125,255,158,0.9); font-size: 11px; line-height: 15px; margin-top: 2px; }
.wline.dim { color: rgba(64,255,94,0.55); }
.wide { color: #04140a; background-color: #40ff5e; padding: 7px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 7px; }
.wide.alt { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
