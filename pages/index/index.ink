<script def>
{"title": "AV Sync Check"}
</script>

<script setup>
import wx from 'wx';

// AV09 av-sync-check - index: dual-track gate (B9).
// One getUserMedia({video:true,audio:true}) call opens both tracks;
// device list, supported constraints and per-track getSettings() are
// read back onto the screen. Live proof: Analyser RMS every 300ms and
// grabFrame liveness (count + interval). Each page opens its own
// stream; streams are not shared across pages (see README).
const MENU = ['开/停双轨采样', '去同步事件 sync', '去判定 judge', '去历史 history'];

export default {
  data: {
    status: '双轨门：Enter 开一条流同时取视频＋音频',
    devLine: '设备：未枚举',
    consLine: '约束支持：未读',
    vLine: '视频轨：未开',
    aLine: '音频轨：未开',
    rmsBar: '░░░░░░░░░░',
    rmsLine: '音频 RMS：—',
    frameLine: '帧活体：0 帧 · 间隔 — ms',
    selLine: '',
    menu: [],
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._sel = 0; this._steady = false; this._stream = null; this._cap = null; this._ctx = null; this._analyser = null; this._timer = null; this._frames = 0; this._lastFrameAt = 0; this._render(); },
  onUnload() { this._stopStream(); },

  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const rows = MENU.map((label, i) => ({ idx: i, label: (i === this._sel ? '▶ ' : '· ') + label, cls: i === this._sel ? 'mrow sel' : 'mrow' }));
    this.setData({ menu: rows, selLine: '选中 ' + (this._sel + 1) + '/4：' + MENU[this._sel] });
  },
  _bar(rms) { const n = Math.max(0, Math.min(10, Math.round(rms * 30))); let s = ''; for (let i = 0; i < 10; i++) s += (i < n ? '█' : '░'); return s; },

  async openTap() {
    if (this._stream) { this._stopStream(); this.setData({ status: '双轨已停（tracks 已 stop，定时器已清）', evt: 'EVT: stream stopped' }); return; }
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw new Error('getUserMedia 不可用');
      const stream = await nav.mediaDevices.getUserMedia({ video: true, audio: true });
      this._stream = stream;
      let devTxt = '设备：枚举不可用';
      try {
        if (nav.mediaDevices.enumerateDevices) {
          const devs = await nav.mediaDevices.enumerateDevices();
          let nv = 0; let na = 0;
          devs.forEach((d) => { if (d.kind === 'videoinput') nv++; if (d.kind === 'audioinput') na++; });
          devTxt = '设备：共 ' + devs.length + ' 个（视频入 ' + nv + ' · 音频入 ' + na + '）';
        }
      } catch (e) { devTxt = '设备：枚举失败 ' + this._err(e); }
      let consTxt = '约束支持：不可读';
      try {
        if (nav.mediaDevices.getSupportedConstraints) {
          const c = nav.mediaDevices.getSupportedConstraints();
          consTxt = '约束支持：' + Object.keys(c).filter((k) => c[k]).slice(0, 8).join(' / ');
        }
      } catch (e) {}
      const vt = stream.getVideoTracks()[0];
      const at = stream.getAudioTracks()[0];
      let vTxt = '视频轨：无'; let aTxt = '音频轨：无';
      try { if (vt && vt.getSettings) { const s = vt.getSettings(); vTxt = '视频轨：' + (s.width || '?') + '×' + (s.height || '?') + ' · ' + (s.frameRate || '?') + 'fps'; } } catch (e) {}
      try { if (at && at.getSettings) { const s = at.getSettings(); aTxt = '音频轨：' + (s.sampleRate || '?') + 'Hz · ' + (s.channelCount || '?') + ' 声道'; } } catch (e) {}
      try { if (vt && typeof ImageCapture !== 'undefined') this._cap = new ImageCapture(vt); } catch (e) { this._cap = null; }
      try {
        const AC = (typeof AudioContext !== 'undefined') ? AudioContext : null;
        if (AC) {
          this._ctx = new AC();
          this._analyser = this._ctx.createAnalyser();
          this._analyser.fftSize = 512;
          const src = this._ctx.createMediaStreamSource(stream);
          src.connect(this._analyser);
        }
      } catch (e) { this._analyser = null; }
      this._frames = 0; this._lastFrameAt = 0;
      const self = this;
      this._timer = setInterval(() => { self._tick(); }, 300);
      this.setData({ status: '双轨采样中：设置已回读，活体指示运行中', devLine: devTxt, consLine: consTxt, vLine: vTxt, aLine: aTxt, evt: 'EVT: stream open, settings read back' });
      this._speak('双轨已开');
    } catch (e) {
      this.setData({ status: '开流失败：' + this._err(e) + '（如实，不假装采样）', evt: 'EVT: stream FAIL ' + this._err(e) });
    }
  },
  async _tick() {
    try {
      if (this._analyser) {
        const buf = new Float32Array(this._analyser.fftSize);
        this._analyser.getFloatTimeDomainData(buf);
        let sum = 0; for (let i = 0; i < buf.length; i++) sum += buf[i] * buf[i];
        const rms = Math.sqrt(sum / buf.length);
        this.setData({ rmsBar: this._bar(rms), rmsLine: '音频 RMS：' + rms.toFixed(3) });
      }
      if (this._cap && this._cap.grabFrame) {
        const now = Date.now();
        await this._cap.grabFrame();
        const gap = this._lastFrameAt ? (now - this._lastFrameAt) : 0;
        this._lastFrameAt = now; this._frames++;
        this.setData({ frameLine: '帧活体：' + this._frames + ' 帧 · 间隔 ' + (gap || '—') + ' ms' });
      }
    } catch (e) {}
  },
  _stopStream() {
    try { if (this._timer) { clearInterval(this._timer); this._timer = null; } } catch (e) {}
    try { if (this._stream) { this._stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} }); this._stream = null; } } catch (e) {}
    try { if (this._ctx) { this._ctx.close(); this._ctx = null; } } catch (e) {}
    this._cap = null; this._analyser = null;
  },
  syncTap() { try { wx.navigateTo({ url: '/pages/sync/index' }); } catch (e) {} },
  judgeTap() { try { wx.navigateTo({ url: '/pages/judge/index' }); } catch (e) {} },
  historyTap() { try { wx.navigateTo({ url: '/pages/history/index' }); } catch (e) {} },
  rowTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (isNaN(idx)) return; this._sel = idx; this._render(); this.doSel(); },
  doSel() { if (this._sel === 0) this.openTap(); else if (this._sel === 1) this.syncTap(); else if (this._sel === 2) this.judgeTap(); else this.historyTap(); },
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
    <text class="title">AV Sync Check · 双轨门</text>
    <text class="status">{{status}}</text>
    <view class="gauge">
      <text class="glabel">音频电平 RMS</text>
      <text class="bar">{{rmsBar}}</text>
      <text class="gval">{{rmsLine}}</text>
    </view>
    <view class="gauge">
      <text class="glabel">视频帧活体 grabFrame</text>
      <text class="gval">{{frameLine}}</text>
    </view>
    <text class="line">{{devLine}}</text>
    <text class="line dim">{{consLine}}</text>
    <text class="line">{{vLine}}</text>
    <text class="line">{{aLine}}</text>
    <view class="menu">
      <view ink:for="{{menu}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="mtxt">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{selLine}}</text>
    <text class="note">每页独立开流：本页的流不跨页复用，sync 页会自开一条流。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.gauge { border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 4px 8px; margin-top: 5px; }
.glabel { color: rgba(64,255,94,0.6); font-size: 10px; line-height: 13px; }
.bar { color: #40ff5e; font-size: 16px; line-height: 20px; letter-spacing: 2px; }
.gval { color: #7dff9e; font-size: 12px; line-height: 16px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.menu { display: flex; flex-direction: column; margin-top: 5px; border-top: 1px solid rgba(64,255,94,0.35); }
.mrow { padding: 4px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.mrow.sel { background-color: #0a1f0e; border-left: 4px solid #40ff5e; }
.mtxt { color: #7dff9e; font-size: 12px; line-height: 16px; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
