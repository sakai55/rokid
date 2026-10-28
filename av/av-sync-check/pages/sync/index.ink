<script def>
{"title": "AV Sync Check"}
</script>

<script setup>
import wx from 'wx';

// AV09 sync: three clap events. The page opens its own stream and
// samples every ~100ms into a ring buffer of the last 30 samples
// (time / brightness / RMS). Enter marks "I clapped" at JS time t0;
// the audio peak ta is the first buffered frame over the RMS
// threshold, the video peak tv is the frame with the largest
// brightness step. delta = ta - tv is a JS-clock estimate, not
// hardware sync - the UI says so.
const TMP = 'av09_tmp';
const ACTS = ['开/停采样', '我拍手了（标记）', '返回 BACK'];
const RMS_TH = 0.2;

export default {
  data: {
    status: '同步事件：先开采样，再拍手 3 次（每次点「我拍手了」）',
    sampleLine: '采样：未开 · 缓冲 0/30',
    evLine: '事件：0/3',
    deltaLine: '— ms',
    rows: [],
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 1; this._steady = false;
    this._stream = null; this._cap = null; this._ctx = null; this._analyser = null; this._timer = null;
    this._buf = []; this._events = []; this._gaps = []; this._lastSampleAt = 0; this._rmsSum = 0; this._rmsN = 0;
    try { const v = wx.getStorageSync(TMP); const p = v ? ((typeof v === 'string') ? JSON.parse(v) : v) : null; if (p && Array.isArray(p.events)) { this._events = p.events; this._gaps = p.gaps || []; this._rmsSum = p.rmsSum || 0; this._rmsN = p.rmsN || 0; } } catch (e) {}
    this._render();
  },
  onUnload() { this._stopStream(); this._persist(); },

  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _persist() {
    try {
      wx.setStorageSync(TMP, { events: this._events, gaps: this._gaps.slice(-60), rmsSum: this._rmsSum, rmsN: this._rmsN, deltaMedian: this._deltaMedian() });
    } catch (e) {}
  },
  _deltaMedian() {
    const ds = this._events.filter((x) => x.delta !== null && x.delta !== undefined).map((x) => x.delta).sort((a, b) => a - b);
    if (!ds.length) return null;
    return ds[Math.floor(ds.length / 2)];
  },
  _render() {
    const rows = this._events.map((x, i) => ({ text: '拍手' + (i + 1) + '：' + (x.delta === null || x.delta === undefined ? '未检出尖峰' : ('delta ' + x.delta + ' ms（ta ' + x.ta + ' / tv ' + x.tv + '）')) }));
    const last = this._events.length ? this._events[this._events.length - 1] : null;
    this.setData({
      rows: rows,
      evLine: '事件：' + this._events.length + '/3' + (this._events.length >= 3 ? '（做满，去判定页）' : ''),
      deltaLine: last ? (last.delta === null || last.delta === undefined ? '未检出' : (last.delta + ' ms')) : '— ms',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },

  async toggleTap() {
    if (this._stream) { this._stopStream(); this.setData({ status: '采样已停', sampleLine: '采样：已停 · 缓冲 ' + this._buf.length + '/30', evt: 'EVT: sampling stopped' }); return; }
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw new Error('getUserMedia 不可用');
      const stream = await nav.mediaDevices.getUserMedia({ video: true, audio: true });
      this._stream = stream;
      try { const vt = stream.getVideoTracks()[0]; if (vt && typeof ImageCapture !== 'undefined') this._cap = new ImageCapture(vt); } catch (e) { this._cap = null; }
      try {
        const AC = (typeof AudioContext !== 'undefined') ? AudioContext : null;
        if (AC) { this._ctx = new AC(); this._analyser = this._ctx.createAnalyser(); this._analyser.fftSize = 512; this._ctx.createMediaStreamSource(stream).connect(this._analyser); }
      } catch (e) { this._analyser = null; }
      this._lastSampleAt = 0;
      const self = this;
      this._timer = setInterval(() => { self._sample(); }, 100);
      this.setData({ status: '采样中：拍手后立刻点「我拍手了」', evt: 'EVT: sampling started (own stream)' });
      this._speak('采样开始，请拍手');
    } catch (e) {
      this.setData({ status: '开流失败：' + this._err(e), evt: 'EVT: stream FAIL ' + this._err(e) });
    }
  },
  async _sample() {
    try {
      const now = Date.now();
      if (this._lastSampleAt) this._gaps.push(now - this._lastSampleAt);
      this._lastSampleAt = now;
      let rms = 0;
      if (this._analyser) {
        const buf = new Float32Array(this._analyser.fftSize);
        this._analyser.getFloatTimeDomainData(buf);
        let sum = 0; for (let i = 0; i < buf.length; i++) sum += buf[i] * buf[i];
        rms = Math.sqrt(sum / buf.length);
      }
      this._rmsSum += rms; this._rmsN++;
      let bright = -1;
      if (this._cap && this._cap.grabFrame && typeof document !== 'undefined') {
        try {
          const bmp = await this._cap.grabFrame();
          const cv = document.createElement('canvas'); cv.width = 16; cv.height = 12;
          const cx = cv.getContext('2d');
          if (cx) {
            cx.drawImage(bmp, 0, 0, 16, 12);
            const img = cx.getImageData(0, 0, 16, 12);
            let s = 0; for (let i = 0; i < img.data.length; i += 4) s += img.data[i];
            bright = s / (16 * 12);
          }
        } catch (e) { bright = -1; }
      }
      this._buf.push({ t: now, bright: bright, rms: rms });
      while (this._buf.length > 30) this._buf.shift();
      this.setData({ sampleLine: '采样：运行中 · 缓冲 ' + this._buf.length + '/30 · RMS ' + rms.toFixed(3) + ' · 亮度 ' + (bright < 0 ? '—' : bright.toFixed(0)) });
    } catch (e) {}
  },
  _stopStream() {
    try { if (this._timer) { clearInterval(this._timer); this._timer = null; } } catch (e) {}
    try { if (this._stream) { this._stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} }); this._stream = null; } } catch (e) {}
    try { if (this._ctx) { this._ctx.close(); this._ctx = null; } } catch (e) {}
    this._cap = null; this._analyser = null;
  },

  markTap() {
    if (!this._stream) { this.setData({ status: '先开采样再拍手：未开流不记事件', evt: 'EVT: mark refused - sampling off' }); this._speak('先开采样'); return; }
    if (this._events.length >= 3) { this.setData({ status: '已做满 3 次，去判定页', evt: 'EVT: mark refused - 3 done' }); return; }
    const t0 = Date.now();
    let ta = null; let tv = null; let bestStep = -1;
    for (let i = 0; i < this._buf.length; i++) {
      if (ta === null && this._buf[i].rms > RMS_TH) ta = this._buf[i].t;
      if (i > 0 && this._buf[i].bright >= 0 && this._buf[i - 1].bright >= 0) {
        const step = Math.abs(this._buf[i].bright - this._buf[i - 1].bright);
        if (step > bestStep) { bestStep = step; tv = this._buf[i].t; }
      }
    }
    let ev = null;
    if (ta === null || tv === null || bestStep <= 0) {
      ev = { t0: t0, ta: ta, tv: tv, delta: null };
      this.setData({ status: '第 ' + (this._events.length + 1) + ' 次：未检出尖峰（如实记录，可继续下一次）', evt: 'EVT: clap ' + (this._events.length + 1) + ' no peak' });
      this._speak('未检出尖峰');
    } else {
      ev = { t0: t0, ta: ta, tv: tv, delta: ta - tv };
      this.setData({ status: '第 ' + (this._events.length + 1) + ' 次：delta ' + ev.delta + ' ms（JS 时钟估算）', evt: 'EVT: clap delta ' + ev.delta + 'ms' });
      this._speak('差值 ' + ev.delta + ' 毫秒');
    }
    this._events.push(ev);
    this._persist();
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.toggleTap(); else if (this._focus === 1) this.markTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.markTap(); },
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
    <text class="title">AV Sync Check · 同步事件</text>
    <text class="status">{{status}}</text>
    <text class="sample">{{sampleLine}}</text>
    <view class="bigbox">
      <text class="biglabel">最近一次 delta（ta − tv）</text>
      <text class="bigdelta">{{deltaLine}}</text>
      <text class="bigsub">{{evLine}} · delta 为 JS 时钟估算，非硬件同步</text>
    </view>
    <view class="list">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <button class="dash" bindtap="actTap" data-idx="0">开 / 停采样</button>
    <button class="dash main" bindtap="actTap" data-idx="1">我拍手了</button>
    <button class="dash" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">尖峰定义：音频＝缓冲内 RMS 首次超 0.2 的帧；视频＝相邻帧平均亮度差最大帧。找不到尖峰如实记「未检出尖峰」。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.sample { color: rgba(125,255,158,0.85); font-family: monospace; font-size: 11px; line-height: 15px; margin-top: 2px; }
.bigbox { border: 2px solid #40ff5e; background-color: #0a1f0e; padding: 5px 9px; margin-top: 5px; }
.biglabel { color: rgba(64,255,94,0.65); font-size: 10px; line-height: 13px; }
.bigdelta { color: #7dff9e; font-size: 30px; font-weight: 500; line-height: 34px; }
.bigsub { color: rgba(125,255,158,0.8); font-size: 11px; line-height: 15px; }
.list { display: flex; flex-direction: column; margin-top: 4px; min-height: 48px; }
.row { padding: 3px 4px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.rtxt { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; }
.dash { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.65); border-radius: 8px; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.dash.main { color: #04140a; background-color: #40ff5e; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
