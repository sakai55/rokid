<script def>{"title":"Hotword Forge"}</script>

<script setup>
import wx from 'wx';

// AV05 hotword-forge - index: capability gate (B5).
// Enter on the CHECK row calls SpeechRecognitionSession.getCapabilities()
// and reads back every field. Unsupported items disable the matching
// forge controls. Caps travel to other pages via wx storage temp key
// 'av05_caps_tmp' (page-to-page handoff only, not a persistence claim).
const MENU = [
  { label: '检测能力（Enter 查宿主）', url: '' },
  { label: '锻造热词 → forge', url: '/pages/forge/index' },
  { label: '实测识别 → test', url: '/pages/test/index' },
  { label: '命中结算 → settle', url: '/pages/settle/index' }
];

export default {
  data: { status: '热词锻造：先过能力门，宿主不支持的开关当场关闭', menu: [], caps: [], capsNote: '能力：尚未检测 — 选中第一行按 Enter 检测', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._sel = 0; this._caps = null; this._canForge = false; this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._renderMenu();
    const old = this._loadTmp('av05_caps_tmp');
    if (old) { this._caps = old; this._canForge = true; this._renderCaps(old); }
  },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },

  _renderMenu() {
    const self = this;
    this.setData({ menu: MENU.map(function (m, i) { return { label: (i === self._sel ? '▶ ' : '· ') + m.label, idx: i }; }) });
  },

  _renderCaps(c) {
    const rows = [];
    const fmts = (c.audioFormats || []).map(function (f) { return (typeof f === 'string') ? f : ((f.mimeType || f.mime || '?') + '@' + (f.sampleRate || f.rate || '?')); }).join(' / ') || '无';
    rows.push({ label: 'audioFormats：' + fmts });
    rows.push({ label: 'maxChunkBytes：' + (c.maxChunkBytes != null ? String(c.maxChunkBytes) : '宿主未给') });
    rows.push({ label: 'interimResults：' + (c.interimResults ? '支持' : '不支持 → 实测页只显示 final') });
    rows.push({ label: 'phrases 热词：' + (c.phrases ? '支持' : '宿主不支持 → 锻造页热词勾选关闭') });
    rows.push({ label: 'contextUpdates：' + (c.contextUpdates ? '支持' : '宿主不支持 → 锻造页上下文注入关闭') });
    rows.push({ label: 'segmentationModes：' + ((c.segmentationModes && c.segmentationModes.length) ? c.segmentationModes.join(' / ') : '宿主未给 → 分段固定 auto') });
    const vad = c.vadSilenceDuration || {};
    rows.push({ label: 'vadSilenceDuration：' + ((vad.minMs != null) ? (vad.minMs + '–' + vad.maxMs + ' ms') : '宿主未给 → VAD 步进关闭') });
    this.setData({ caps: rows, capsNote: '能力：已检测（见上）· 可进锻造', status: '能力门已过：按宿主真实能力锻造，不支持项已标注关闭' });
  },

  async checkTap() {
    this.setData({ evt: 'EVT: checking capabilities', status: '正在向宿主查询 SpeechRecognitionSession 能力…' });
    try {
      if (typeof SpeechRecognitionSession === 'undefined' || typeof SpeechRecognitionSession.getCapabilities !== 'function') {
        this._canForge = false;
        this.setData({ status: '宿主无 SpeechRecognitionSession.getCapabilities — 如实报错，锻造已禁止', capsNote: '能力：不可用（Web 预览/当前宿主无此 API）', caps: [{ label: 'getCapabilities 不可用 — 锻造按钮置灰' }] });
        this._speak('当前宿主不支持外部流识别，无法锻造');
        return;
      }
      const c = await SpeechRecognitionSession.getCapabilities();
      if (!c) throw new Error('empty capabilities');
      this._caps = c; this._canForge = true;
      this._saveTmp('av05_caps_tmp', c);
      this._renderCaps(c);
      this.setData({ evt: 'EVT: capabilities ok' });
      this._speak('能力检测完成，可以锻造');
    } catch (e) {
      this._canForge = false;
      this.setData({ status: '能力查询失败：' + String((e && e.message) || e).slice(0, 60) + ' — 锻造已禁止', evt: 'EVT: capabilities failed' });
    }
  },

  goTap() {
    const m = MENU[this._sel];
    if (!m.url) { this.checkTap(); return; }
    if (m.url.indexOf('forge') >= 0 && !this._canForge) {
      this.setData({ status: '尚未通过能力门（或宿主不支持）— 先检测能力，锻造按钮置灰', evt: 'EVT: forge blocked - no caps' });
      return;
    }
    try { wx.navigateTo({ url: m.url }); } catch (e) {}
  },
  rowTap(e) {
    const i = (e && e.currentTarget && e.currentTarget.dataset) ? Number(e.currentTarget.dataset.idx) : -1;
    if (isNaN(i)) return;
    if (i < 0 || i >= MENU.length) return;
    this._sel = i; this._renderMenu(); this.goTap();
  },
  moveTap() { this._sel = (this._sel + 1) % MENU.length; this._renderMenu(); },
  backTap() { this._sel = (this._sel + MENU.length - 1) % MENU.length; this._renderMenu(); },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.goTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.goTap(); return; }
    if (key === 'ArrowDown') {  this.moveTap(); return; }
    if (key === 'ArrowUp') {  this.backTap(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="ttl">Hotword Forge · 能力门</text>
    <text class="status">{{status}}</text>
    <view class="furnace">
      <view ink:for="{{menu}}" class="menurow" data-idx="{{item.idx}}" bindtap="rowTap"><text class="menutext">{{item.label}}</text></view>
    </view>
    <text class="capnote">{{capsNote}}</text>
    <view class="capbox">
      <view ink:for="{{caps}}" class="caprow"><text class="captext">{{item.label}}</text></view>
    </view>
    <text class="steady">{{steady}}</text>
    <view class="btnrow">
      <button class="forgebtn" bindtap="checkTap">检测能力</button>
      <button class="forgebtn" bindtap="goTap">进入选中</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.ttl { color: #7dff9e; font-size: 18px; font-weight: bold; letter-spacing: 2px; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.furnace { margin-top: 8px; border: 3px solid #40ff5e; background-color: #04140a; padding: 6px 8px; }
.menurow { border: 2px solid rgba(64,255,94,0.8); background-color: #0a1f0e; padding: 5px 8px; margin-bottom: 5px; }
.menutext { color: #7dff9e; font-size: 13px; }
.capnote { color: #7dff9e; font-size: 11px; display: block; margin-top: 7px; }
.capbox { margin-top: 4px; border: 1px solid rgba(125,255,158,0.55); padding: 4px 8px; height: 104px; overflow: hidden; }
.caprow { margin-bottom: 1px; }
.captext { color: rgba(125,255,158,0.9); font-size: 10px; }
.steady { color: rgba(64,255,94,0.75); font-size: 10px; display: block; margin-top: 4px; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.forgebtn { flex: 1; margin-right: 8px; background-color: #0a1f0e; color: #7dff9e; border: 3px solid #40ff5e; font-size: 13px; font-weight: bold; padding: 6px 0; text-align: center; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
