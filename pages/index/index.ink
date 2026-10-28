<script def>
{"title": "System Audio Capture"}
</script>

<script setup>
import wx from 'wx';

// AV10 system-audio-capture - index: source gate (B10 + B4 discipline).
// DISCIPLINE: the only audio constraint ever requested here is
// { audio: { captureSource: 'system-audio' } }. This file never sets
// a microphone mode and never requests echo cancellation, and on
// failure it never falls back to a microphone stream.
const MENU = ['探测内录来源', '去内录 capture', '去转写 transcribe', '去归档 archive'];

export default {
  data: {
    status: '来源门：只认 system-audio，永不回退麦克风',
    srcLine: 'captureSource 实际值：未探测',
    rmsLine: '播放声检测：未测（探测后读 1 秒 RMS）',
    ruleLine: '纪律：只请求 captureSource system-audio；不带麦克风模式；不带回声消除；失败不回退',
    selLine: '',
    menu: [],
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() { this._sel = 0; this._steady = false; this._stream = null; this._ctx = null; this._render(); },
  onUnload() { this._cleanup(); },

  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const rows = MENU.map((label, i) => ({ idx: i, label: (i === this._sel ? '▶ ' : '· ') + label, cls: i === this._sel ? 'mrow sel' : 'mrow' }));
    this.setData({ menu: rows, selLine: '选中 ' + (this._sel + 1) + '/4：' + MENU[this._sel] });
  },
  _cleanup() {
    try { if (this._stream) { this._stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} }); this._stream = null; } } catch (e) {}
    try { if (this._ctx) { this._ctx.close(); this._ctx = null; } } catch (e) {}
  },

  async probeTap() {
    this._cleanup();
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw new Error('getUserMedia 不可用');
      // Only this exact shape is ever requested (see discipline note).
      const stream = await nav.mediaDevices.getUserMedia({ audio: { captureSource: 'system-audio' } });
      this._stream = stream;
      const track = stream.getAudioTracks()[0];
      let actual = '未知（getSettings 不可用）';
      try { if (track && track.getSettings) { const s = track.getSettings(); actual = String(s.captureSource || '未回报字段'); } } catch (e) {}
      this.setData({ srcLine: 'captureSource 实际值：' + actual, evt: 'EVT: source probed = ' + actual });
      let rmsTxt = '播放声检测：Analyser 不可用，未测';
      try {
        const AC = (typeof AudioContext !== 'undefined') ? AudioContext : null;
        if (AC) {
          this._ctx = new AC();
          const an = this._ctx.createAnalyser(); an.fftSize = 512;
          this._ctx.createMediaStreamSource(stream).connect(an);
          const buf = new Float32Array(an.fftSize);
          let peak = 0;
          for (let n = 0; n < 4; n++) {
            await new Promise((r) => setTimeout(r, 250));
            an.getFloatTimeDomainData(buf);
            let sum = 0; for (let i = 0; i < buf.length; i++) sum += buf[i] * buf[i];
            peak = Math.max(peak, Math.sqrt(sum / buf.length));
          }
          rmsTxt = peak < 0.005 ? '播放声检测：1 秒内 RMS≈0，当前无播放声（静音）' : ('播放声检测：有播放声（峰值 RMS ' + peak.toFixed(3) + '）');
        }
      } catch (e) { rmsTxt = '播放声检测：读取失败 ' + this._err(e); }
      this.setData({ status: '来源门通过：内录来源已开（探测后自动关闭）', rmsLine: rmsTxt, evt: 'EVT: probe done' });
      this._speak('内录来源已确认');
      this._cleanup();
    } catch (e) {
      this.setData({
        status: '来源请求失败：' + this._err(e) + '。永不回退麦克风——请确认设备有正在播放的声音来源',
        srcLine: 'captureSource 实际值：请求失败（' + this._err(e) + '）',
        evt: 'EVT: probe FAIL no-fallback ' + this._err(e)
      });
    }
  },
  captureTap() { try { wx.navigateTo({ url: '/pages/capture/index' }); } catch (e) {} },
  transcribeTap() { try { wx.navigateTo({ url: '/pages/transcribe/index' }); } catch (e) {} },
  archiveTap() { try { wx.navigateTo({ url: '/pages/archive/index' }); } catch (e) {} },
  rowTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (isNaN(idx)) return; this._sel = idx; this._render(); this.doSel(); },
  doSel() { if (this._sel === 0) this.probeTap(); else if (this._sel === 1) this.captureTap(); else if (this._sel === 2) this.transcribeTap(); else this.archiveTap(); },
  moveTap(d) { this._sel = (this._sel + d + MENU.length) % MENU.length; this.setData({ evt: 'EVT: select ' + MENU[this._sel] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doSel(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (k === 'Enter') {  this.doSel(); }
    else if (k === 'ArrowUp') {  this.moveTap(-1); }
    else if (k === 'ArrowDown') {  this.moveTap(1); }
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">System Audio Capture · 来源门</text>
    <text class="status">{{status}}</text>
    <view class="deck">
      <text class="dline">{{srcLine}}</text>
      <text class="dline">{{rmsLine}}</text>
      <text class="dline warn">{{ruleLine}}</text>
    </view>
    <view class="menu">
      <view ink:for="{{menu}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="mtxt">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{selLine}}</text>
    <text class="note">录的是设备自身播放声，不是环境会议声——与会议转写的区别就在来源门。每页独立开流。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.deck { border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 5px 8px; margin-top: 5px; }
.dline { color: rgba(125,255,158,0.9); font-size: 11px; line-height: 16px; }
.dline.warn { color: #40ff5e; }
.menu { display: flex; flex-direction: column; margin-top: 6px; border-top: 1px solid rgba(64,255,94,0.35); }
.mrow { padding: 5px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.mrow.sel { background-color: #0a1f0e; border-left: 4px solid #40ff5e; }
.mtxt { color: #7dff9e; font-size: 12px; line-height: 16px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
