<script def>
{
  "title": "Motion Frame Watch"
}
</script>

<script setup>
import wx from 'wx';

var BKEY = 'av02_baseline';
var THRS = [
  { label: '灵敏 2%', v: 2 },
  { label: '标准 5%', v: 5 },
  { label: '宽松 10%', v: 10 }
];
var MENU = [
  { name: '阈值档位', hint: '单击在 灵敏2%/标准5%/宽松10% 间切换', act: 'thr' },
  { name: '基线标定', hint: '单击拍基线帧（grabFrame）', act: 'cal' },
  { name: '开始监看', hint: '去监看页（需先标定）', act: 'watch' },
  { name: '变化日志', hint: '看已入账的变化记录', act: 'log' }
];

export default {
  data: {
    evt: 'EVT: ready · 滑动选菜单/阈值',
    ver: 'v1.0.0',
    status: '先对准静止画面拍一张基线，再选触发阈值',
    baseLine: '基线：未标定',
    thrIdx: 1,
    thrLabel: '标准 5%',
    selIdx: 0,
    rows: [],
    segRows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._syncAll();
  },
  onShow() { this._syncAll(); },
  _loadBase() {
    try {
      var v = wx.getStorageSync(BKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return null;
  },
  _syncAll() {
    var b = this._loadBase();
    var sel = this.data.selIdx;
    var ti = this.data.thrIdx;
    var rows = MENU.map(function (m, i) {
      var nm = m.act === 'thr' ? ('阈值：' + THRS[ti].label) : m.name;
      return { name: nm, hint: m.hint, cls: i === sel ? 'mrow mrow-sel' : 'mrow', mark: i === sel ? '▸' : '·' };
    });
    var segs = THRS.map(function (t, i) {
      return { label: t.label, cls: i === ti ? 'seg seg-on' : 'seg' };
    });
    this.setData({
      rows: rows,
      segRows: segs,
      thrLabel: THRS[ti].label,
      baseLine: b && b.data ? ('基线：已标定 · 64x48 · 阈值 ' + (b.thr || 5) + '%') : '基线：未标定'
    });
  },
  _move(dir) {
    var n = (this.data.selIdx + dir + MENU.length) % MENU.length;
    this.setData({ selIdx: n, evt: 'EVT: menu ' + MENU[n].name });
    this._syncAll();
  },
  _cycleThr() {
    var n = (this.data.thrIdx + 1) % THRS.length;
    this.setData({ thrIdx: n, evt: 'EVT: thr ' + THRS[n].label });
    this._syncAll();
    this._speak('阈值' + THRS[n].label);
  },
  onThrTap() { this._cycleThr(); },
  onRowTap(e) {
    var i = this.data.selIdx;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this.data.selIdx;
    this.setData({ selIdx: i });
    this._activate(i);
  },
  _activate(i) {
    var act = MENU[i] && MENU[i].act;
    if (act === 'thr') this._cycleThr();
    else if (act === 'cal') this._calibrate();
    else if (act === 'watch') { try { wx.navigateTo({ url: '/pages/watch/index' }); } catch (e) {} }
    else if (act === 'log') { try { wx.navigateTo({ url: '/pages/log/index' }); } catch (e) {} }
  },
  async _calibrate() {
    var self = this;
    this.setData({ status: '标定中：抓取基线帧…', evt: 'EVT: cal start' });
    var stream = null;
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined' || typeof document === 'undefined') {
        this.setData({ status: '宿主无相机/canvas，待真机标定（不生成假基线）', evt: 'EVT: camera n/a' });
        return;
      }
      stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = stream.getVideoTracks()[0];
      var cap = new ImageCapture(track);
      var bmp = await cap.grabFrame();
      var cv = document.createElement('canvas');
      cv.width = 64; cv.height = 48;
      var ctx = cv.getContext('2d');
      ctx.drawImage(bmp, 0, 0, 64, 48);
      try { bmp.close(); } catch (e) {}
      var img = ctx.getImageData(0, 0, 64, 48).data;
      var lum = [];
      for (var i = 0; i < img.length; i += 4) lum.push(Math.round((img[i] + img[i + 1] + img[i + 2]) / 3));
      var thr = THRS[this.data.thrIdx].v;
      try { wx.setStorageSync(BKEY, { data: lum, thr: thr, at: Date.now() }); } catch (e) {}
      this.setData({ status: '基线已标定（64x48 亮度阵列 · 阈值 ' + thr + '%）', evt: 'EVT: cal ok n=' + lum.length });
      this._speak('基线已标定');
      this._syncAll();
    } catch (e) {
      this.setData({ status: '标定失败（如实记录）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: cal fail' });
    } finally {
      if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} }
    }
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter' || k === 'GlobalHook') this._activate(this.data.selIdx);
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._activate(this.data.selIdx); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">MOTION FRAME WATCH · 动帧守望</text>
    <text class="status">{{status}}</text>
    <text class="baseline">{{baseLine}}</text>
    <view class="segbar" bindtap="onThrTap">
      <view ink:for="{{segRows}}" class="{{item.cls}}"><text class="segtext">{{item.label}}</text></view>
    </view>
    <text class="thrnote">阈值 {{thrLabel}}（点分段条切换 · 监看时以标定时阈值为准）</text>
    <view class="mlist">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="onRowTap" data-idx="{{index}}">
        <text class="mname">{{item.mark}} {{item.name}}</text>
        <text class="mhint">{{item.hint}}</text>
      </view>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 5px; }
.baseline { color: #40ff5e; font-family: monospace; font-size: 11px; margin-top: 4px; }
.segbar { display: flex; flex-direction: row; margin-top: 8px; border: 1px solid rgba(64,255,94,0.8); }
.seg { flex-grow: 1; padding: 6px 0; text-align: center; background-color: #04140a; border-right: 1px solid rgba(64,255,94,0.5); }
.seg-on { background-color: rgba(125,255,158,0.3); }
.segtext { color: #7dff9e; font-size: 12px; }
.thrnote { color: rgba(64,255,94,0.6); font-size: 9px; margin-top: 3px; }
.mlist { display: flex; flex-direction: column; margin-top: 8px; }
.mrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 7px 10px; margin-bottom: 6px; }
.mrow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.mname { color: #40ff5e; font-size: 14px; font-weight: 500; }
.mhint { color: rgba(64,255,94,0.62); font-size: 10px; margin-left: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 6px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
