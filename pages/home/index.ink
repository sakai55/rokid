<script def>
{
  "title": "QR Probe"
}
</script>

<script setup>
import wx from 'wx';
import { VER, EC_LEVELS, probeDetector, readState, patchState, fail } from '../../qrprobe.js';

var MENU = [
  { label: '编码站', url: '/pages/encode/index' },
  { label: '文件读回站', url: '/pages/decode/index' },
  { label: '相机读码站', url: '/pages/camera/index' },
  { label: '展示页', url: '/pages/display/index' },
  { label: '结果单', url: '/pages/results/index' }
];

export default {
  data: {
    evt: 'EVT: home',
    ver: 'v' + VER,
    detLine: 'BarcodeDetector 检测中…',
    fmtLine: '',
    lastLine: '',
    menu: []
  },
  onLoad() {
    this._sel = 0;
    this._lastAct = 0;
    this._render();
    this._summary();
    this._probe();
  },
  onShow() { this._summary(); },
  async _probe() {
    var det = await probeDetector();
    patchState(function (st) {
      st.detector = { available: det.available, formats: det.formats, qr: det.qr, errCode: det.errCode, raw: det.raw, ts: Date.now() };
    });
    if (!det.available) {
      fail('E7009', det.raw);
      this.setData({ detLine: 'BarcodeDetector 不可用 · E7009', fmtLine: '读回与相机两站将停在守卫态' });
    } else if (!det.qr) {
      fail(det.errCode || 'E7005', det.raw);
      this.setData({ detLine: 'BarcodeDetector 可用 · qr_code 不在支持列表 · E7005', fmtLine: '支持码制 ' + (det.formats ? det.formats.length : 0) + ' 种（见结果单）' });
    } else {
      this.setData({
        detLine: 'BarcodeDetector 可用 · 支持 qr_code',
        fmtLine: '支持码制：' + (det.formats ? det.formats.join(' ') : '')
      });
    }
  },
  _summary() {
    var st = readState();
    var parts = [];
    for (var i = 0; i < EC_LEVELS.length; i++) {
      var ec = EC_LEVELS[i];
      var e = st.encode[ec];
      if (e && e.ceiling) parts.push(ec + ' 编码 ' + e.ceiling.bytes);
      var f = st.file[ec];
      if (f && f.ceiling) parts.push(ec + ' 读回 ' + f.ceiling);
    }
    if (parts.length) this.setData({ lastLine: '已有记录：' + parts.join(' · ') + '（字节）' });
  },
  _render() {
    var rows = [];
    for (var i = 0; i < MENU.length; i++) {
      rows.push({ idx: i, label: (i === this._sel ? '▶ ' : '　') + MENU[i].label, cls: i === this._sel ? 'row sel' : 'row' });
    }
    this.setData({ menu: rows });
  },
  _dup() {
    var now = Date.now();
    if (now - this._lastAct < 400) return true;
    this._lastAct = now;
    return false;
  },
  _open() {
    var m = MENU[this._sel];
    if (!m) return;
    this.setData({ evt: 'EVT: open ' + m.label });
    try { wx.navigateTo({ url: m.url }); } catch (e) {}
  },
  moveTap(d) {
    this._sel = (this._sel + d + MENU.length) % MENU.length;
    this.setData({ evt: 'EVT: select ' + MENU[this._sel].label });
    this._render();
  },
  rowTap(e) {
    var idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN;
    if (isNaN(idx)) return;
    this._sel = idx;
    this._render();
    if (!this._dup()) this._open();
  },
  onKeyDown(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (!this._dup()) this._open(); }
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
  },
  onKeyUp(event) {
    var k = event && (event.code || event.key);
    if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">QR PROBE · 二维码容量探针</text>
    <text class="purpose">量二维码作本地数据交换的容量边界：编码 → 存图 → 读回 → 相机</text>
    <view class="cards">
      <text class="card">{{detLine}}</text>
      <text class="card2">{{fmtLine}}</text>
    </view>
    <view class="menu">
      <view ink:for="{{menu}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="mtxt">{{item.label}}</text></view>
    </view>
    <text class="last">{{lastLine}}</text>
    <text class="note">预览数值是预览宿主的，只认真机</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.purpose { color: #40ff5e; font-size: 12px; margin-top: 4px; }
.cards { display: flex; flex-direction: column; margin-top: 6px; border: 1px solid rgba(64,255,94,0.55); padding: 5px 8px; }
.card { color: #7dff9e; font-size: 13px; line-height: 19px; }
.card2 { color: rgba(125,255,158,0.85); font-size: 10px; line-height: 14px; }
.menu { display: flex; flex-direction: column; margin-top: 8px; }
.row { padding: 4px 8px; margin-top: 3px; border: 1px solid rgba(64,255,94,0.35); }
.row.sel { background-color: #40ff5e; }
.mtxt { color: #7dff9e; font-size: 15px; }
.row.sel .mtxt { color: #000000; font-weight: 500; }
.last { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.note { color: rgba(64,255,94,0.6); font-size: 10px; margin-top: 2px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
