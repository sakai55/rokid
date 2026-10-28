<script def>
{
  "title": "Tri Shot Lab"
}
</script>

<script setup>
import wx from 'wx';

var TKEY = 'av01_target';
var TARGETS = [
  { name: '远牌', hint: '远处招牌/站牌 · 长焦主场' },
  { name: '小字', hint: '说明书小字 · 近距细读' },
  { name: '条码', hint: '商品条码 · 广角扫描面' },
  { name: '价签', hint: '货架价签 · 中距小字' },
  { name: '仪表', hint: '电表/水表读数 · 数字判读' },
  { name: '包装字', hint: '包装背面成分字 · 密排版' }
];

export default {
  data: {
    evt: 'EVT: ready · 滑动选对象，单击进连拍',
    ver: 'v1.0.1',
    status: '选一个拍摄对象：三镜（wide/telephoto/default）将同场连拍',
    heard: '',
    steady: false,
    selIdx: 0,
    selName: '远牌',
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._syncRows();
  },
  onShow() { this._syncRows(); },
  _syncRows() {
    var sel = this.data.selIdx;
    var rows = TARGETS.map(function (t, i) {
      return { name: t.name, hint: t.hint, cls: i === sel ? 'cell cell-sel' : 'cell', mark: i === sel ? '▸' : '·' };
    });
    this.setData({ rows: rows, selName: TARGETS[sel].name });
  },
  _move(dir) {
    var n = (this.data.selIdx + dir + TARGETS.length) % TARGETS.length;
    this.setData({ selIdx: n, evt: 'EVT: sel ' + TARGETS[n].name });
    this._syncRows();
  },
  _choose(i) {
    var t = TARGETS[i];
    if (!t) return;
    try { wx.setStorageSync(TKEY, { name: t.name, at: Date.now() }); } catch (e) {}
    this.setData({ evt: 'EVT: target=' + t.name + ' -> shoot' });
    this._speak('已选' + t.name + '，开始连拍准备');
    try { wx.navigateTo({ url: '/pages/shoot/index' }); } catch (e) {}
  },
  onRowTap(e) {
    var i = 0;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this.data.selIdx;
    this.setData({ selIdx: i });
    this._syncRows();
    this._choose(i);
  },
  onHistoryTap() { try { wx.navigateTo({ url: '/pages/history/index' }); } catch (e) {} },
  onListenTap() { this._listen(); },
  _listen() {
    var self = this;
    try {
      if (typeof SpeechRecognition === 'undefined') {
        this.setData({ status: '宿主无 SpeechRecognition，待真机使用语音选对象', evt: 'EVT: asr n/a' });
        return;
      }
      var r = new SpeechRecognition();
      r.interimResults = true;
      r.onresult = function (e) {
        try {
          var t = e.results[e.resultIndex][0].transcript;
          self.setData({ heard: t });
          for (var i = 0; i < TARGETS.length; i++) {
            if (t.indexOf(TARGETS[i].name) >= 0) {
              self.setData({ selIdx: i, status: '语音命中：' + TARGETS[i].name, evt: 'EVT: asr hit ' + TARGETS[i].name });
              self._syncRows();
              return;
            }
          }
        } catch (err) {}
      };
      r.onerror = function (e) {
        self.setData({ status: '语音识别失败（如实记录）：' + (e && e.error ? e.error : 'unknown') + ' · 可重说或滑动手选', evt: 'EVT: asr error' });
      };
      r.onend = function () {
        if (!self.data.heard) self.setData({ status: '没听清：请重说对象名（远牌/小字/条码/价签/仪表/包装字），或滑动手选' });
      };
      r.start();
      this.setData({ status: '聆听中：说出对象名…', evt: 'EVT: asr start' });
    } catch (e) {
      this.setData({ status: '语音启动失败，待真机', evt: 'EVT: asr throw' });
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
    if (k === 'Enter' || k === 'GlobalHook') this._choose(this.data.selIdx);
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._choose(this.data.selIdx); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ steady: s, evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="strip">
      <view class="hole"></view><view class="hole"></view><view class="hole"></view>
      <text class="ttl">TRI SHOT LAB · 三镜同场</text>
      <view class="hole"></view><view class="hole"></view><view class="hole"></view>
    </view>
    <text class="status">{{status}}</text>
    <view class="grid">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="onRowTap" data-idx="{{index}}">
        <text class="cname">{{item.mark}} {{item.name}}</text>
        <text class="chint">{{item.hint}}</text>
      </view>
    </view>
    <view class="btnrow">
      <button class="sqbtn" bindtap="onListenTap">VOICE 语音选</button>
      <button class="sqbtn" bindtap="onHistoryTap">HISTORY 历史</button>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.strip { display: flex; flex-direction: row; align-items: center; border-top: 2px solid rgba(64,255,94,0.9); border-bottom: 2px solid rgba(64,255,94,0.9); padding: 2px 2px; }
.hole { width: 8px; height: 8px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.7); margin-right: 5px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 16px; font-weight: 500; text-align: center; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 2px; }
.grid { display: flex; flex-direction: column; margin-top: 3px; }
.cell { border: 1px solid rgba(64,255,94,0.55); background-color: #04140a; padding: 3px 10px; margin-bottom: 4px; border-radius: 0; }
.cell-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.cname { color: #40ff5e; font-size: 14px; font-weight: 500; }
.chint { color: rgba(64,255,94,0.62); font-size: 10px; margin-left: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 2px; }
.sqbtn { flex-grow: 1; border-radius: 0; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.16); color: #7dff9e; font-size: 12px; padding: 7px 0; text-align: center; margin-right: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
