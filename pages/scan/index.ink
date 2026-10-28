<script def>{"title":"Barcode Rally - Scan"}</script>

<script setup>
import wx from 'wx';

// AV07 scan: getUserMedia -> ImageCapture -> grabFrame() ImageBitmap fed
// directly to BarcodeDetector.detect(). Fallback: takePhoto({mode:'wide'})
// Blob fed to detect(), labelled as fallback. detect() never receives a
// VideoFrame. Dedup window: same rawValue within 3s prompts only.
// Every accepted code is spoken (rawValue first 20 chars) and appended to
// the shared scan list 'av07_scans_tmp'.
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
  data: { status: '连续扫：对准条码按 Enter 单次扫（grabFrame 主路径）', lastText: '最近：尚未扫到', boxText: 'boundingBox：—', rows: [], countText: '已扫 0 条', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._steady = false; this._busy = false; this._seen = {};
    try { this.enableWorldAwareness(); } catch (e) {}
    this._showList();
  },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },
  _scans() { const v = this._loadTmp('av07_scans_tmp'); return Array.isArray(v) ? v : []; },

  _showList() {
    const scans = this._scans();
    this.setData({
      rows: scans.slice(-6).map(function (s, i) { return { label: (scans.length - Math.min(6, scans.length) + i + 1) + '. ' + s.format + ' · ' + s.value }; }),
      countText: '已扫 ' + scans.length + ' 条（去重窗 3 秒）'
    });
  },

  async scanTap() { if (this._busy) return; this._busy = true; try { await this._scanOnce(); } finally { this._busy = false; } },

  async _scanOnce() {
    let stream = null;
    try {
      if (typeof BarcodeDetector === 'undefined') { this.setData({ status: '宿主无 BarcodeDetector — 扫码不可用，如实显示', evt: 'EVT: no detector' }); return; }
      const gum = (typeof navigator !== 'undefined' && navigator.mediaDevices && typeof navigator.mediaDevices.getUserMedia === 'function') ? navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices) : null;
      if (!gum) { this.setData({ status: '宿主无 getUserMedia — 扫码不可用，如实显示', evt: 'EVT: no getUserMedia' }); return; }
      if (typeof ImageCapture === 'undefined') { this.setData({ status: '宿主无 ImageCapture — 扫码不可用，如实显示', evt: 'EVT: no ImageCapture' }); return; }
      stream = await gum({ video: true });
      const track = stream.getVideoTracks()[0];
      const cap = new ImageCapture(track);
      const detector = new BarcodeDetector();
      let results = null; let via = 'grabFrame';
      try {
        const bitmap = await cap.grabFrame();
        results = await detector.detect(bitmap);
        try { if (bitmap && typeof bitmap.close === 'function') bitmap.close(); } catch (e) {}
      } catch (grabErr) {
        via = 'takePhoto 回退';
        const blob = await cap.takePhoto({ mode: 'wide' });
        results = await detector.detect(blob);
      }
      if (!results || !results.length) { this.setData({ status: '本次未检出条码（' + via + '）— 对准后重试', evt: 'EVT: no code found' }); return; }
      const r = results[0];
      const fmt = r.format || '?'; const val = r.rawValue || '';
      const bb = r.boundingBox || {};
      this.setData({
        lastText: '最近：' + fmt + ' · ' + val + '（' + via + '）',
        boxText: 'boundingBox：x ' + Math.round(bb.x || 0) + ' · y ' + Math.round(bb.y || 0) + ' · w ' + Math.round(bb.width || bb.w || 0) + ' · h ' + Math.round(bb.height || bb.h || 0)
      });
      const now = Date.now();
      if (this._seen[val] && (now - this._seen[val] < 3000)) {
        this.setData({ status: '重复码（3 秒去重窗内）— 只提示不重复计', evt: 'EVT: dedup hit' });
        this._speak('重复码');
        return;
      }
      this._seen[val] = now;
      const scans = this._scans();
      scans.push({ format: fmt, value: val, box: { x: bb.x || 0, y: bb.y || 0, w: bb.width || bb.w || 0, h: bb.height || bb.h || 0 }, time: now });
      this._saveTmp('av07_scans_tmp', scans);
      const hit = TARGETS.filter(function (t) { return t.format === fmt && t.value === val; })[0];
      const sameFmt = TARGETS.filter(function (t) { return t.format === fmt && t.value !== val; })[0];
      let note = '已记录';
      if (hit) note = '命中目标：' + hit.name + '（码制+值全合，去核销页确认）';
      else if (sameFmt) note = '同码制异值：与「' + sameFmt.name + '」同为 ' + fmt + ' 但值不同，不自动核销';
      this.setData({ status: note, evt: 'EVT: scanned ' + fmt });
      this._showList();
      this._speak(String(val).slice(0, 20));
    } catch (e) {
      this.setData({ status: '扫码失败：' + String((e && e.message) || e).slice(0, 55) + ' — 如实显示', evt: 'EVT: scan failed' });
    } finally {
      if (stream) { try { stream.getTracks().forEach(function (t) { try { t.stop(); } catch (e) {} }); } catch (e) {} }
    }
  },

  tallyTap() { try { wx.navigateTo({ url: '/pages/tally/index' }); } catch (e) {} },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.scanTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.scanTap(); return; }
    if (key === 'ArrowDown' || key === 'ArrowUp') {  this.tallyTap(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">连续扫 · 对准即扫</text></view>
    <text class="status">{{status}}</text>
    <view class="bigcount"><text class="bignum">{{countText}}</text></view>
    <text class="line bright">{{lastText}}</text>
    <text class="line">{{boxText}}</text>
    <view class="scanlist">
      <view ink:for="{{rows}}" class="scanrow"><text class="scantext">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{steady}}</text>
    <view class="btnrow">
      <button class="tallybtn main" bindtap="scanTap">扫一次</button>
      <button class="tallybtn" bindtap="tallyTap">去核销</button>
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
.bigcount { margin-top: 7px; border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 7px; text-align: center; }
.bignum { color: #7dff9e; font-size: 20px; font-weight: bold; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 4px; }
.bright { color: #7dff9e; }
.dim { color: rgba(64,255,94,0.7); }
.scanlist { margin-top: 5px; height: 96px; overflow: hidden; padding: 2px 6px; }
.scanrow { border-bottom: 1px solid rgba(64,255,94,0.3); padding: 2px 2px; }
.scantext { color: #7dff9e; font-size: 11px; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.tallybtn { flex: 1; margin-right: 8px; background-color: #0a1f0e; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); font-size: 12px; padding: 7px 10px; text-align: left; }
.main { color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
