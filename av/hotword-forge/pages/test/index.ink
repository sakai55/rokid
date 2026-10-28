<script def>{"title":"Hotword Forge - Test"}</script>

<script setup>
import wx from 'wx';

// AV05 test: stream mic chunks into a SpeechRecognitionSession.
// mime = intersection of host audioFormats and MediaRecorder.isTypeSupported.
// MediaRecorder.start(250) chunks go through a serial Promise chain into
// session.audio.getWriter(); interim results render live, finals accumulate.

export default {
  data: { status: '实测：Enter 开始 — 念出盘点词句，看热词命中', cfgText: '配置：未读到（先去锻造页存配置）', interimText: 'interim：—', finalText: 'final：—', hitText: '命中：尚未统计', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._steady = false; this._recording = false; this._final = ''; this._session = null; this._recorder = null; this._stream = null; this._writer = null; this._chain = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    const cfg = this._loadTmp('av05_cfg_tmp');
    const caps = this._loadTmp('av05_caps_tmp');
    this._cfg = cfg || { picked: [], vadMs: null, segMode: 'auto', useCtx: false, dialog: [] };
    this._caps = caps || {};
    if (cfg) this.setData({ cfgText: '配置：热词 ' + (cfg.picked || []).length + ' 个 · VAD ' + (cfg.vadMs != null ? cfg.vadMs + 'ms' : '关') + ' · 分段 ' + (cfg.segMode || 'auto') + ' · 上下文 ' + (cfg.useCtx ? '开' : '关') });
  },
  onUnload() { this._cleanup(); },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },

  _pickMime() {
    try {
      if (typeof MediaRecorder === 'undefined' || typeof MediaRecorder.isTypeSupported !== 'function') return null;
      const fmts = (this._caps.audioFormats || []).map(function (f) { return (typeof f === 'string') ? f : (f.mimeType || f.mime || ''); }).filter(function (s) { return !!s; });
      for (let i = 0; i < fmts.length; i++) { if (MediaRecorder.isTypeSupported(fmts[i])) return fmts[i]; }
      const fall = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4', 'audio/ogg;codecs=opus'];
      for (let j = 0; j < fall.length; j++) { if (MediaRecorder.isTypeSupported(fall[j])) return fall[j]; }
    } catch (e) {}
    return null;
  },

  async mainTap() { if (this._recording) { await this._stop(); } else { await this._start(); } },

  async _start() {
    try {
      if (typeof SpeechRecognitionSession === 'undefined') { this.setData({ status: '宿主无 SpeechRecognitionSession — 实测不可用，如实显示', evt: 'EVT: no session api' }); return; }
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof navigator.mediaDevices.getUserMedia !== 'function') { this.setData({ status: '宿主无 getUserMedia — 实测不可用，如实显示', evt: 'EVT: no getUserMedia' }); return; }
      if (typeof MediaRecorder === 'undefined') { this.setData({ status: '宿主无 MediaRecorder — 实测不可用，如实显示', evt: 'EVT: no MediaRecorder' }); return; }
      const mime = this._pickMime();
      if (!mime) { this.setData({ status: '宿主格式与 MediaRecorder 无交集 — 无法开录', evt: 'EVT: no common mime' }); return; }
      const cfg = this._cfg;
      const opts = { lang: 'zh-CN', interimResults: true, segmentation: cfg.segMode || 'auto' };
      if (cfg.picked && cfg.picked.length && this._caps.phrases !== false) opts.phrases = cfg.picked.slice();
      if (cfg.vadMs != null) opts.vadSilenceDuration = cfg.vadMs;
      const session = new SpeechRecognitionSession(opts);
      this._session = session;
      if (cfg.useCtx && this._caps.contextUpdates !== false && typeof session.updateContext === 'function') {
        try { await session.updateContext(cfg.dialog || []); } catch (e) { this.setData({ evt: 'EVT: updateContext failed - noted' }); }
      }
      const self = this;
      session.onresult = function (ev) { self._onResult(ev); };
      session.onerror = function (ev) { self.setData({ status: '识别会话报错：' + String((ev && (ev.message || ev.error)) || 'unknown').slice(0, 50), evt: 'EVT: session error' }); };
      this._writer = session.audio.getWriter();
      this._chain = Promise.resolve();
      this._stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const rec = new MediaRecorder(this._stream, { mimeType: mime });
      this._recorder = rec;
      const writer = this._writer;
      rec.ondataavailable = function (e) {
        if (e && e.data && e.data.size) {
          const chunk = e.data;
          self._chain = self._chain.then(function () { return writer.write(chunk); }).catch(function () {});
        }
      };
      this._final = '';
      rec.start(250);
      this._recording = true;
      this.setData({ status: '录音中（' + mime + ' · 250ms 分片串行写入）— 再按 Enter 结束', interimText: 'interim：—', finalText: 'final：—', evt: 'EVT: recording started' });
      this._speak('开始实测，请念盘点词句');
    } catch (e) {
      this._cleanup();
      this.setData({ status: '实测启动失败：' + String((e && e.message) || e).slice(0, 60), evt: 'EVT: start failed' });
    }
  },

  _onResult(ev) {
    let transcript = ''; let isFinal = false;
    try {
      if (ev && typeof ev.transcript === 'string') { transcript = ev.transcript; isFinal = !!ev.isFinal; }
      else if (ev && ev.results && ev.results.length) {
        const r = ev.results[ev.resultIndex != null ? ev.resultIndex : ev.results.length - 1];
        if (r && r[0]) transcript = r[0].transcript || '';
        isFinal = !!(r && r.isFinal);
      }
    } catch (e) {}
    if (!transcript) return;
    if (isFinal) {
      this._final = (this._final + ' ' + transcript).trim();
      this.setData({ finalText: 'final：' + this._final.slice(-90), interimText: 'interim：—' });
      this._countHits();
    } else {
      this.setData({ interimText: 'interim：' + transcript.slice(-60) });
    }
  },

  _countHits() {
    const picked = (this._cfg && this._cfg.picked) || [];
    const hits = {};
    picked.forEach(function (w) { let n = 0; let idx = 0; const text = this._final; while (true) { const p = text.indexOf(w, idx); if (p < 0) break; n++; idx = p + w.length; } hits[w] = n; }.bind(this));
    this._hits = hits;
    const parts = picked.map(function (w) { return w + '×' + (hits[w] || 0); });
    this.setData({ hitText: '命中：' + (parts.length ? parts.join(' · ') : '无热词（先去锻造页勾选）') });
    return hits;
  },

  async _stop() {
    try {
      if (this._recorder && this._recorder.state !== 'inactive') { try { this._recorder.stop(); } catch (e) {} }
      if (this._chain) { try { await this._chain; } catch (e) {} }
      if (this._writer) { try { await this._writer.close(); } catch (e) {} this._writer = null; }
    } catch (e) {}
    this._cleanupTracks();
    this._recording = false;
    const hits = this._countHits();
    this._saveTmp('av05_last_tmp', { hits: hits, finalText: this._final, cfg: this._cfg });
    this.setData({ status: '实测结束 — 命中已暂存，去结算页入账', evt: 'EVT: recording stopped - hits saved' });
    this._speak('实测结束，去结算页看命中');
    this._session = null; this._recorder = null;
  },

  _cleanupTracks() { if (this._stream) { try { this._stream.getTracks().forEach(function (t) { try { t.stop(); } catch (e) {} }); } catch (e) {} this._stream = null; } },
  _cleanup() { if (this._recorder && this._recorder.state !== 'inactive') { try { this._recorder.stop(); } catch (e) {} } this._cleanupTracks(); this._recording = false; },
  backTap() { this._cleanup(); try { wx.navigateBack({}); } catch (e) {} },
  settleTap() { try { wx.navigateTo({ url: '/pages/settle/index' }); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.mainTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.mainTap(); return; }
    if (key === 'ArrowDown' || key === 'ArrowUp') {  this.settleTap(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">实测台 · 边说边认</text></view>
    <text class="status">{{status}}</text>
    <text class="line">{{cfgText}}</text>
    <view class="livebox">
      <text class="live interim">{{interimText}}</text>
      <text class="live final">{{finalText}}</text>
    </view>
    <text class="line bright">{{hitText}}</text>
    <text class="line">{{steady}}</text>
    <view class="btnrow">
      <button class="forgebtn main" bindtap="mainTap">开始 / 结束实测</button>
      <button class="forgebtn" bindtap="settleTap">去结算</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { background-color: #04140a; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 10px; padding: 3px 8px; margin-right: 10px; }
.ttl { color: #7dff9e; font-size: 17px; font-weight: bold; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 5px; }
.bright { color: #7dff9e; }
.livebox { margin-top: 8px; border: 3px solid #40ff5e; background-color: #04140a; padding: 10px; height: 120px; overflow: hidden; }
.live { display: block; font-size: 13px; line-height: 19px; }
.interim { color: rgba(125,255,158,0.75); }
.final { color: #7dff9e; margin-top: 6px; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.forgebtn { flex: 1; margin-right: 8px; background-color: #0a1f0e; color: #40ff5e; border: 3px solid rgba(64,255,94,0.85); font-size: 12px; padding: 7px 0; text-align: center; }
.main { color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
