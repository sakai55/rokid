<script def>{"title":"Hotword Forge - Forge"}</script>

<script setup>
import wx from 'wx';

// AV05 forge: pick hotwords from the 12-word warehouse set (boost +5 fixed),
// step VAD silence inside the host range, pick a segmentation mode the host
// listed, and optionally inject a stocktaking dialogue via updateContext
// (the session itself applies it on the test page; here we store the choice).
const WORDS = ['纸箱', '托盘', '货架', '叉车', '标签', '封口', '称重', '扫码枪', '周转箱', '防潮垫', '捆扎带', '出库单'];
const DIALOG = [
  { role: 'user', text: '三号货架还有多少纸箱？' },
  { role: 'assistant', text: '纸箱还剩十二个，托盘在叉车旁边。' },
  { role: 'user', text: '把出库单和捆扎带一起核对。' },
  { role: 'assistant', text: '好的，先称重再封口。' }
];

export default {
  data: { status: '锻造：上下移选词，Enter 勾选热词（boost +5）', rows: [], vadText: 'VAD 静音阈值：—', segText: '分段模式：auto', ctxText: '上下文注入：盘点对话 4 句（待定）', pickedText: '已选 0 词', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._sel = 0; this._steady = false;
    this._picked = {}; this._vadIdx = 0; this._vadOpts = []; this._segIdx = 0; this._segOpts = ['auto']; this._useCtx = true; this._phrasesOk = true; this._ctxOk = true;
    try { this.enableWorldAwareness(); } catch (e) {}
    const caps = this._loadTmp('av05_caps_tmp') || {};
    if (caps.phrases === false) { this._phrasesOk = false; }
    if (caps.contextUpdates === false) { this._ctxOk = false; this._useCtx = false; }
    if (caps.segmentationModes && caps.segmentationModes.length) this._segOpts = caps.segmentationModes.slice();
    const vad = caps.vadSilenceDuration || {};
    if (vad.minMs != null && vad.maxMs != null && vad.maxMs > vad.minMs) {
      const mid = Math.round((vad.minMs + vad.maxMs) / 2);
      this._vadOpts = [vad.minMs, mid, vad.maxMs];
    }
    const old = this._loadTmp('av05_cfg_tmp');
    if (old) {
      (old.picked || []).forEach(function (w) { this._picked[w] = true; }.bind(this));
      if (old.vadMs != null) { const vi = this._vadOpts.indexOf(old.vadMs); if (vi >= 0) this._vadIdx = vi; }
      if (old.segMode) { const si = this._segOpts.indexOf(old.segMode); if (si >= 0) this._segIdx = si; }
      if (typeof old.useCtx === 'boolean') this._useCtx = old.useCtx && this._ctxOk;
    }
    this._recompute();
  },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },
  _pickedList() { const self = this; return WORDS.filter(function (w) { return self._picked[w]; }); },

  _recompute() {
    const self = this;
    const rows = WORDS.map(function (w, i) {
      const on = !!self._picked[w];
      return { label: (i === self._sel ? '▶ ' : '· ') + w + (on ? ' [热词 +5]' : ' [未选]'), idx: i };
    });
    this.setData({
      rows: rows,
      vadText: this._vadOpts.length ? ('VAD 静音阈值：' + this._vadOpts[this._vadIdx] + ' ms（宿主区间内步进）') : 'VAD 静音阈值：关闭（宿主未给区间）',
      segText: '分段模式：' + this._segOpts[this._segIdx] + '（宿主所列内选）',
      ctxText: this._ctxOk ? ('上下文注入：' + (this._useCtx ? '开 — 盘点对话 4 句将经 updateContext 注入' : '关')) : '上下文注入：关闭（宿主不支持 contextUpdates）',
      pickedText: '已选 ' + this._pickedList().length + ' 词' + (this._phrasesOk ? '' : ' · 注意：宿主不支持 phrases，勾选仅记录、实测不注入'),
      status: this._phrasesOk ? '锻造：上下移选词，Enter 勾选热词（boost +5）' : '锻造：宿主不支持 phrases — 热词开关已关闭，仅可调 VAD/分段'
    });
  },

  toggleTap() {
    if (!this._phrasesOk) { this.setData({ evt: 'EVT: phrases unsupported - toggle ignored' }); return; }
    const w = WORDS[this._sel];
    this._picked[w] = !this._picked[w];
    this.setData({ evt: 'EVT: toggle ' + w });
    this._recompute();
  },
  rowTap(e) {
    const i = (e && e.currentTarget && e.currentTarget.dataset) ? Number(e.currentTarget.dataset.idx) : -1;
    if (isNaN(i)) return;
    if (i < 0 || i >= WORDS.length) return;
    this._sel = i; this.toggleTap();
  },
  vadTap() { if (!this._vadOpts.length) return; this._vadIdx = (this._vadIdx + 1) % this._vadOpts.length; this.setData({ evt: 'EVT: vad step' }); this._recompute(); },
  segTap() { this._segIdx = (this._segIdx + 1) % this._segOpts.length; this.setData({ evt: 'EVT: segmentation step' }); this._recompute(); },
  ctxTap() { if (!this._ctxOk) return; this._useCtx = !this._useCtx; this.setData({ evt: 'EVT: context toggle' }); this._recompute(); },
  saveTap() {
    const cfg = { picked: this._pickedList(), vadMs: this._vadOpts.length ? this._vadOpts[this._vadIdx] : null, segMode: this._segOpts[this._segIdx], useCtx: this._useCtx, dialog: DIALOG };
    this._saveTmp('av05_cfg_tmp', cfg);
    this.setData({ evt: 'EVT: config saved - ' + cfg.picked.length + ' words', status: '配置已存（页间临时键 av05_cfg_tmp）— 去实测页验证' });
    this._speak('锻造完成，已选' + cfg.picked.length + '个热词');
    try { wx.navigateTo({ url: '/pages/test/index' }); } catch (e) {}
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.saveTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.toggleTap(); return; }
    if (key === 'ArrowDown') {  this._sel = (this._sel + 1) % WORDS.length; this._recompute(); return; }
    if (key === 'ArrowUp') {  this._sel = (this._sel + WORDS.length - 1) % WORDS.length; this._recompute(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">锻造炉 · 选热词</text></view>
    <text class="status">{{status}}</text>
    <view class="grid">
      <view ink:for="{{rows}}" class="wordblock" data-idx="{{item.idx}}" bindtap="rowTap"><text class="wordtext">{{item.label}}</text></view>
    </view>
    <text class="line">{{vadText}}</text>
    <text class="line">{{segText}}</text>
    <text class="line">{{ctxText}}</text>
    <text class="line bright">{{pickedText}} · {{steady}}</text>
    <view class="btnrow">
      <button class="forgebtn" bindtap="vadTap">VAD 步进</button>
      <button class="forgebtn" bindtap="segTap">分段切换</button>
      <button class="forgebtn" bindtap="ctxTap">上下文开/关</button>
      <button class="forgebtn main" bindtap="saveTap">存配置去实测</button>
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
.grid { margin-top: 7px; border: 3px solid #40ff5e; background-color: #04140a; padding: 6px; height: 148px; overflow: hidden; }
.wordblock { border: 2px solid rgba(64,255,94,0.75); background-color: #0a1f0e; padding: 3px 8px; margin-bottom: 3px; }
.wordtext { color: #7dff9e; font-size: 12px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 3px; }
.bright { color: #7dff9e; }
.btnrow { display: flex; flex-direction: row; margin-top: 7px; }
.forgebtn { flex: 1; margin-right: 6px; background-color: #0a1f0e; color: #40ff5e; border: 3px solid rgba(64,255,94,0.85); font-size: 11px; padding: 6px 0; text-align: center; }
.main { color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
