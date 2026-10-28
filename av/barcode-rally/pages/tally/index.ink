<script def>{"title":"Barcode Rally - Tally"}</script>

<script setup>
import wx from 'wx';

// AV07 tally: a target is verified only when a scan matches BOTH expected
// format and expected value, or when the user manually verifies it here
// (Enter on a selected target applies the latest scan by hand -- the honest
// correction path, README states this rule). Voice correction: host
// SpeechRecognition -- say a scan number ("删掉第X条") to delete that scan,
// or say a barcode tail (>=4 digits) to delete the matching scan.
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
const CN = { '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10 };

export default {
  data: { status: '核销：上下选目标，Enter 用最近扫描手动核销；可语音删误扫', targetRows: [], scanRows: [], progressText: '核销 0/10', heardText: '语音纠错：未听', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._sel = 0; this._steady = false; this._rec = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._show();
  },
  onShow() { this._show(); },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },
  _scans() { const v = this._loadTmp('av07_scans_tmp'); return Array.isArray(v) ? v : []; },
  _manual() { const v = this._loadTmp('av07_manual_tmp'); return Array.isArray(v) ? v : []; },
  _doneSet() {
    const scans = this._scans(); const manual = this._manual(); const done = {};
    TARGETS.forEach(function (t, i) {
      if (manual.indexOf(i) >= 0) { done[i] = '手动'; return; }
      const hit = scans.filter(function (s) { return s.format === t.format && s.value === t.value; })[0];
      if (hit) done[i] = '自动';
    });
    return done;
  },

  _show() {
    const done = this._doneSet();
    const self = this;
    const n = Object.keys(done).length;
    const scans = this._scans();
    this.setData({
      targetRows: TARGETS.map(function (t, i) { return { label: (i === self._sel ? '▶ ' : '· ') + (done[i] ? '✓ ' : '○ ') + t.name + ' · ' + t.format + (done[i] ? '（' + done[i] + '核销）' : '（未）'), idx: i }; }),
      scanRows: scans.slice(-5).map(function (s, i) { return { label: (scans.length - Math.min(5, scans.length) + i + 1) + '. ' + s.format + ' · ' + s.value }; }),
      progressText: '核销 ' + n + '/10'
    });
  },

  manualTap() {
    const scans = this._scans();
    if (!scans.length) { this.setData({ status: '还没有扫描记录 — 先去连续扫', evt: 'EVT: manual blocked - no scan' }); return; }
    const manual = this._manual();
    if (manual.indexOf(this._sel) < 0) manual.push(this._sel);
    this._saveTmp('av07_manual_tmp', manual);
    const latest = scans[scans.length - 1];
    this.setData({ status: '已手动核销「' + TARGETS[this._sel].name + '」（最近扫描 ' + latest.format + ' · ' + latest.value + '）— 人工纠错路径', evt: 'EVT: manual verify ' + this._sel });
    this._speak('已核销' + TARGETS[this._sel].name);
    this._show();
  },
  rowTap(e) {
    const i = (e && e.currentTarget && e.currentTarget.dataset) ? Number(e.currentTarget.dataset.idx) : -1;
    if (isNaN(i)) return;
    if (i < 0 || i >= TARGETS.length) return;
    this._sel = i; this._show(); this.manualTap();
  },

  _listen() {
    try {
      const Ctor = (typeof SpeechRecognition !== 'undefined') ? SpeechRecognition : ((typeof webkitSpeechRecognition !== 'undefined') ? webkitSpeechRecognition : null);
      if (!Ctor) { this.setData({ heardText: '语音纠错：宿主无 SpeechRecognition — 如实显示，可用手动核销', evt: 'EVT: no asr host' }); return; }
      const r = new Ctor();
      this._rec = r;
      r.interimResults = true;
      const self = this;
      r.onresult = function (e) {
        try {
          const res = e.results[e.resultIndex];
          const t = (res && res[0]) ? (res[0].transcript || '') : '';
          if (!t) return;
          self.setData({ heardText: '语音纠错：听到「' + t + '」' });
          if (res.isFinal) self._applyVoiceDelete(t);
        } catch (err) {}
      };
      r.onerror = function (e) { self.setData({ heardText: '语音纠错失败：' + String((e && (e.error || e.message)) || 'unknown').slice(0, 35) + ' — 可重说', evt: 'EVT: asr error' }); };
      r.start();
      this.setData({ heardText: '语音纠错：聆听中…说「删掉第X条」或条码尾号', evt: 'EVT: listening' });
    } catch (e) {
      this.setData({ heardText: '语音纠错启动失败：' + String((e && e.message) || e).slice(0, 35), evt: 'EVT: asr start failed' });
    }
  },

  _applyVoiceDelete(t) {
    const scans = this._scans();
    if (!scans.length) { this.setData({ evt: 'EVT: voice delete - no scans' }); return; }
    const digits = (t.match(/\d+/g) || []).join('');
    if (digits.length >= 4) {
      const idx = scans.findIndex(function (s) { return String(s.value).indexOf(digits) >= 0 || digits.indexOf(String(s.value).slice(-4)) >= 0; });
      if (idx >= 0) { const gone = scans.splice(idx, 1)[0]; this._saveTmp('av07_scans_tmp', scans); this.setData({ status: '已按尾号删误扫：' + gone.format + ' · ' + gone.value, evt: 'EVT: scan deleted by tail' }); this._speak('已删除误扫'); this._show(); return; }
    }
    let num = null;
    const m = t.match(/第\s*(\d+)\s*条/);
    if (m) num = Number(m[1]);
    else { const keys = Object.keys(CN); for (let i = 0; i < keys.length; i++) { if (t.indexOf('第' + keys[i]) >= 0) { num = CN[keys[i]]; break; } } }
    if (num != null && num >= 1 && num <= scans.length) {
      const gone = scans.splice(num - 1, 1)[0];
      this._saveTmp('av07_scans_tmp', scans);
      this.setData({ status: '已删第 ' + num + ' 条误扫：' + gone.format + ' · ' + gone.value, evt: 'EVT: scan deleted by index' });
      this._speak('已删除第' + num + '条');
      this._show();
      return;
    }
    this.setData({ status: '没听懂删除指令 — 可重说「删掉第X条」或条码尾号', evt: 'EVT: voice delete not understood' });
  },

  listenTap() { this._listen(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  settleTap() { try { wx.navigateTo({ url: '/pages/settle/index' }); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.manualTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.manualTap(); return; }
    if (key === 'ArrowDown') {  this._sel = (this._sel + 1) % TARGETS.length; this._show(); return; }
    if (key === 'ArrowUp') {  this._sel = (this._sel + TARGETS.length - 1) % TARGETS.length; this._show(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">清单核销</text><text class="bigprog">{{progressText}}</text></view>
    <text class="status">{{status}}</text>
    <view class="targetlist">
      <view ink:for="{{targetRows}}" class="targetrow" data-idx="{{item.idx}}" bindtap="rowTap"><text class="targettext">{{item.label}}</text></view>
    </view>
    <text class="line">最近扫描：</text>
    <view class="scanlist">
      <view ink:for="{{scanRows}}" class="scanrow"><text class="scantext">{{item.label}}</text></view>
    </view>
    <text class="line">{{heardText}} · {{steady}}</text>
    <view class="btnrow">
      <button class="tallybtn main" bindtap="manualTap">手动核销选中</button>
      <button class="tallybtn" bindtap="listenTap">语音删误扫</button>
      <button class="tallybtn" bindtap="settleTap">去结算</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { background-color: #04140a; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 10px; padding: 3px 8px; margin-right: 10px; }
.ttl { color: #7dff9e; font-size: 17px; font-weight: bold; flex: 1; }
.bigprog { color: #7dff9e; font-size: 18px; font-weight: bold; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.targetlist { margin-top: 6px; border: 1px solid rgba(125,255,158,0.55); background-color: #04140a; padding: 4px 8px; height: 128px; overflow: hidden; }
.targetrow { border-bottom: 1px solid rgba(64,255,94,0.3); padding: 1px 2px; }
.targettext { color: #7dff9e; font-size: 11px; }
.line { color: rgba(125,255,158,0.9); font-size: 10px; display: block; margin-top: 4px; }
.scanlist { height: 52px; overflow: hidden; padding: 1px 4px; }
.scanrow { padding: 1px 2px; }
.scantext { color: #40ff5e; font-size: 10px; }
.btnrow { display: flex; flex-direction: row; margin-top: 5px; }
.tallybtn { flex: 1; margin-right: 8px; background-color: #0a1f0e; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); font-size: 11px; padding: 6px 10px; text-align: left; }
.main { color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
