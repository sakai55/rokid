<script def>{"title":"Barcode Rally - Settle"}</script>

<script setup>
import wx from 'wx';

// AV07 settle: counts by format + verification progress x/10.
// Enter writes this round into 'av07_tally' (cumulative verified + total
// scans across sessions, guarded so re-entering does not double-count).
// Clear resets the tally and the round's scan/manual temp lists.
const KEY = 'av07_tally';
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

export default {
  data: { status: '结算：按码制计数 + 核销进度，Enter 入账（av07_tally）', rows: [], progressText: '核销 0/10', totalText: '累计：—', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._steady = false; this._saved = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._show();
  },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { verified: 0, scans: 0, rounds: 0 }; },
  _save(v) { try { wx.setStorageSync(KEY, v); } catch (e) {} },
  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },

  _round() {
    const scansRaw = this._loadTmp('av07_scans_tmp'); const scans = Array.isArray(scansRaw) ? scansRaw : [];
    const manRaw = this._loadTmp('av07_manual_tmp'); const manual = Array.isArray(manRaw) ? manRaw : [];
    const byFmt = {};
    scans.forEach(function (s) { byFmt[s.format] = (byFmt[s.format] || 0) + 1; });
    let done = 0;
    TARGETS.forEach(function (t, i) {
      if (manual.indexOf(i) >= 0) { done++; return; }
      if (scans.filter(function (s) { return s.format === t.format && s.value === t.value; }).length) done++;
    });
    return { scans: scans, byFmt: byFmt, done: done };
  },

  _show() {
    const r = this._round();
    const rows = Object.keys(r.byFmt).map(function (f) { return { label: f + ' · ' + r.byFmt[f] + ' 条' }; });
    if (!rows.length) rows.push({ label: '暂无扫描 — 先去连续扫' });
    const cum = this._load();
    this.setData({
      rows: rows,
      progressText: '核销 ' + r.done + '/10 · 本轮扫 ' + r.scans.length + ' 条',
      totalText: '累计（av07_tally）：已核销 ' + (cum.verified || 0) + ' · 总扫 ' + (cum.scans || 0) + ' · 轮次 ' + (cum.rounds || 0) + (this._saved ? ' · 本轮已入账' : ' · 本轮未入账'),
      status: r.scans.length ? '结算：本轮如下，Enter 入累计账' : '结算：暂无本轮数据'
    });
  },

  saveTap() {
    if (this._saved) { this.setData({ evt: 'EVT: already settled - no double count' }); return; }
    const r = this._round();
    const cum = this._load();
    cum.verified = (cum.verified || 0) + r.done;
    cum.scans = (cum.scans || 0) + r.scans.length;
    cum.rounds = (cum.rounds || 0) + 1;
    this._save(cum);
    this._saved = true;
    this.setData({ evt: 'EVT: settled into av07_tally' });
    this._speak('结算完成，核销' + r.done + '件');
    this._show();
  },
  clearTap() {
    try { wx.removeStorageSync(KEY); wx.removeStorageSync('av07_scans_tmp'); wx.removeStorageSync('av07_manual_tmp'); } catch (e) {}
    this._saved = false;
    this.setData({ evt: 'EVT: tally cleared - new round' });
    this._show();
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
    if (key === 'Enter') {  this.saveTap(); return; }
    if (key === 'ArrowDown' || key === 'ArrowUp') {  this._show(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">结算 · 按码制计数</text></view>
    <text class="status">{{status}}</text>
    <view class="bigcount"><text class="bignum">{{progressText}}</text></view>
    <view class="fmtlist">
      <view ink:for="{{rows}}" class="fmtrow"><text class="fmttext">{{item.label}}</text></view>
    </view>
    <text class="line bright">{{totalText}}</text>
    <text class="line dim">{{steady}}</text>
    <view class="btnrow">
      <button class="tallybtn main" bindtap="saveTap">入账</button>
      <button class="tallybtn" bindtap="clearTap">清空重盘</button>
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
.bigcount { margin-top: 8px; border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 9px; text-align: center; }
.bignum { color: #7dff9e; font-size: 21px; font-weight: bold; }
.fmtlist { margin-top: 7px; border: 1px solid rgba(125,255,158,0.55); background-color: #04140a; padding: 6px 8px; height: 118px; overflow: hidden; }
.fmtrow { border-bottom: 1px solid rgba(64,255,94,0.3); padding: 3px 2px; }
.fmttext { color: #7dff9e; font-size: 12px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 6px; }
.bright { color: #7dff9e; }
.dim { color: rgba(64,255,94,0.7); }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.tallybtn { flex: 1; margin-right: 8px; background-color: #0a1f0e; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); font-size: 12px; padding: 7px 10px; text-align: left; }
.main { color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
