<script def>{"title":"Barcode Rally"}</script>

<script setup>
import wx from 'wx';

// AV07 barcode-rally - index: format gate (B7).
// Enter on the CHECK row calls BarcodeDetector.getSupportedFormats() and
// lists the real host formats with a count. The 10-item target list
// (name + expected canonical format + example value) is always visible.
// Example values are samples only; real items rule on device (see README).
const TARGETS = [
  { name: '矿泉水', format: 'ean_13', value: '6901234500017' },
  { name: '快递单', format: 'code_128', value: 'SF1234567890' },
  { name: '会员卡', format: 'qr_code', value: 'MEMBER-2026-001' },
  { name: '牛奶盒', format: 'ean_13', value: '6912345600024' },
  { name: '罐头食品', format: 'ean_8', value: '12345670' },
  { name: '洗手液', format: 'upc_a', value: '012345678905' },
  { name: '电池', format: 'code_39', value: 'BAT-AA-04' },
  { name: '打印纸', format: 'pdf417', value: 'DOC-A4-500' },
  { name: '标签贴', format: 'data_matrix', value: 'DM-LABEL-09' },
  { name: '挂面', format: 'codabar', value: '1234567890' }
];
const MENU = [
  { label: '检测码制（Enter 查宿主）', url: '' },
  { label: '连续扫 → scan', url: '/pages/scan/index' },
  { label: '清单核销 → tally', url: '/pages/tally/index' },
  { label: '结算 → settle', url: '/pages/settle/index' }
];

export default {
  data: { status: '多码清点：先过码制门，再按目标清单扫码核销', menu: [], fmtText: '码制：尚未检测 — 选中第一行按 Enter 检测', fmtRows: [], targetRows: [], evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._sel = 0; this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._render();
    const old = this._loadTmp('av07_formats_tmp');
    if (old && old.length) this._renderFormats(old);
  },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },

  _render() {
    const self = this;
    this.setData({
      menu: MENU.map(function (m, i) { return { label: (i === self._sel ? '▶ ' : '· ') + m.label, idx: i }; }),
      targetRows: TARGETS.map(function (t, i) { return { label: (i + 1) + '. ' + t.name + ' · ' + t.format + ' · 例值 ' + t.value }; })
    });
  },
  _renderFormats(list) {
    this.setData({
      fmtText: '码制：宿主支持 ' + list.length + ' 种 — ' + list.join(' / '),
      fmtRows: list.map(function (f) { return { label: '✓ ' + f }; }),
      status: '码制门已过：宿主实列 ' + list.length + ' 种码制，可开始连续扫'
    });
  },

  async checkTap() {
    this.setData({ evt: 'EVT: checking formats', status: '正在向宿主查询 BarcodeDetector 支持码制…' });
    try {
      if (typeof BarcodeDetector === 'undefined' || typeof BarcodeDetector.getSupportedFormats !== 'function') {
        this.setData({ status: '宿主无 BarcodeDetector.getSupportedFormats — 如实显示，扫码不可用', fmtText: '码制：不可用（Web 预览/当前宿主无此 API）', fmtRows: [{ label: 'getSupportedFormats 不可用' }] });
        this._speak('当前宿主不支持条码检测');
        return;
      }
      const list = await BarcodeDetector.getSupportedFormats();
      const arr = Array.isArray(list) ? list.slice() : [];
      this._saveTmp('av07_formats_tmp', arr);
      this._renderFormats(arr);
      this.setData({ evt: 'EVT: formats ok - ' + arr.length });
      this._speak('宿主支持' + arr.length + '种码制');
    } catch (e) {
      this.setData({ status: '码制查询失败：' + String((e && e.message) || e).slice(0, 50) + ' — 如实显示', evt: 'EVT: formats failed' });
    }
  },

  goTap() {
    const m = MENU[this._sel];
    if (!m.url) { this.checkTap(); return; }
    try { wx.navigateTo({ url: m.url }); } catch (e) {}
  },
  rowTap(e) {
    const i = (e && e.currentTarget && e.currentTarget.dataset) ? Number(e.currentTarget.dataset.idx) : -1;
    if (isNaN(i)) return;
    if (i < 0 || i >= MENU.length) return;
    this._sel = i; this._render(); this.goTap();
  },

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
    if (key === 'ArrowDown') {  this._sel = (this._sel + 1) % MENU.length; this._render(); return; }
    if (key === 'ArrowUp') {  this._sel = (this._sel + MENU.length - 1) % MENU.length; this._render(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="ttl">Barcode Rally · 码制门</text>
    <text class="status">{{status}}</text>
    <view class="menulist">
      <view ink:for="{{menu}}" class="menurow" data-idx="{{item.idx}}" bindtap="rowTap"><text class="menutext">{{item.label}}</text></view>
    </view>
    <text class="line bright">{{fmtText}}</text>
    <view class="fmtlist">
      <view ink:for="{{fmtRows}}" class="fmtrow"><text class="fmttext">{{item.label}}</text></view>
    </view>
    <text class="line">目标清单 10 件（例值仅示例，真机以实物为准）：</text>
    <view class="targetlist">
      <view ink:for="{{targetRows}}" class="targetrow"><text class="targettext">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{steady}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.ttl { color: #7dff9e; font-size: 18px; font-weight: bold; letter-spacing: 2px; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.menulist { margin-top: 6px; }
.menurow { background-color: #0a1f0e; border: 1px solid rgba(64,255,94,0.8); padding: 4px 10px; margin-bottom: 4px; }
.menutext { color: #7dff9e; font-size: 12px; }
.line { color: rgba(125,255,158,0.9); font-size: 10px; display: block; margin-top: 4px; }
.bright { color: #7dff9e; font-size: 11px; }
.dim { color: rgba(64,255,94,0.7); }
.fmtlist { height: 18px; overflow: hidden; padding: 1px 4px; }
.fmtrow { display: inline-block; margin-right: 8px; }
.fmttext { color: #40ff5e; font-size: 10px; }
.targetlist { margin-top: 3px; border: 1px solid rgba(125,255,158,0.55); background-color: #04140a; padding: 3px 8px; height: 140px; overflow: hidden; }
.targetrow { border-bottom: 1px solid rgba(64,255,94,0.3); padding: 0 2px; }
.targettext { color: #7dff9e; font-size: 10px; line-height: 13px; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
