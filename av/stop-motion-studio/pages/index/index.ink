<script def>
{
  "title": "Stop Motion Studio"
}
</script>

<script setup>
import wx from 'wx';

var CFGKEY = 'av11_cfg';
var SPEEDS = [
  { key: 'slow', label: '慢速', fps: 5 },
  { key: 'mid', label: '中速', fps: 8 },
  { key: 'fast', label: '快速', fps: 12 }
];
var LENS = [
  { key: 'short', label: '短', sec: 5 },
  { key: 'mid', label: '中', sec: 10 },
  { key: 'long', label: '长', sec: 15 }
];
var CAP_FRAMES = 120;
var SAFETY_SEC = 180;
var AUTO_IV = 2;

function sget(k) {
  try { if (typeof localStorage !== 'undefined') { var v = localStorage.getItem(k); if (v) return JSON.parse(v); } } catch (e) {}
  try { var w = wx.getStorageSync(k); if (w) return (typeof w === 'string') ? JSON.parse(w) : w; } catch (e) {}
  return null;
}
function sset(k, v) {
  try { if (typeof localStorage !== 'undefined') { localStorage.setItem(k, JSON.stringify(v)); return true; } } catch (e) {}
  try { wx.setStorageSync(k, v); return true; } catch (e) {}
  return false;
}
function defCfg() { return { name: '未命名定格', speedKey: 'mid', lenKey: 'mid', mode: 'manual' }; }
function speedOf(c) { for (var i = 0; i < SPEEDS.length; i++) if (SPEEDS[i].key === c.speedKey) return SPEEDS[i]; return SPEEDS[1]; }
function lenOf(c) { for (var i = 0; i < LENS.length; i++) if (LENS[i].key === c.lenKey) return LENS[i]; return LENS[1]; }
function targetOf(c) { return Math.min(speedOf(c).fps * lenOf(c).sec, CAP_FRAMES); }
function fmtDur(s) {
  if (s < 60) return s + ' 秒';
  var m = Math.floor(s / 60), r = s % 60;
  return r ? (m + ' 分 ' + r + ' 秒') : (m + ' 分钟');
}

export default {
  data: {
    evt: 'EVT: ready · 滑动选行，单击切换/进入',
    ver: 'v1.0.0',
    status: '只选两样：速度和长度，张数自动算好',
    bigLine: '',
    autoLine: '',
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._sel = 0; this._rec = null;
    this._cfg = sget(CFGKEY) || defCfg();
    this._render();
  },
  onShow() { this._cfg = sget(CFGKEY) || this._cfg || defCfg(); this._render(); },
  onUnload() { this._stopAsr(); },
  _defs() {
    var c = this._cfg;
    var sp = speedOf(c), ln = lenOf(c);
    return [
      { name: '作品名（语音起名）', val: c.name, act: 'name' },
      { name: '速度', val: sp.label + '（' + sp.fps + ' 帧/秒）', act: 'speed' },
      { name: '长度', val: ln.label + '（约 ' + ln.sec + ' 秒）', act: 'len' },
      { name: '拍法', val: c.mode === 'auto' ? '自动（每 2 秒一张）' : '手动（点一下拍一张）', act: 'mode' },
      { name: '去拍摄', val: '洋葱皮取景', act: 'shoot' },
      { name: '去合成', val: '播放 + 验证读数', act: 'play' }
    ];
  },
  _render() {
    var defs = this._defs();
    var sel = this._sel || 0;
    var rows = defs.map(function (d, i) {
      return { name: d.name, val: d.val, cls: i === sel ? 'srow srow-sel' : 'srow', mark: i === sel ? '▸' : '·' };
    });
    var c = this._cfg;
    var sp = speedOf(c), ln = lenOf(c);
    var target = targetOf(c);
    var film = Math.round((target / sp.fps) * 10) / 10;
    var big = sp.label + ' · ' + ln.label + ' — 拍 ' + target + ' 张，成片约 ' + (film % 1 ? film : Math.round(film)) + ' 秒';
    var auto = '';
    if (c.mode === 'auto') {
      var need = target * AUTO_IV;
      if (need > SAFETY_SEC) {
        auto = '自动拍约需 ' + fmtDur(need) + '，超过 3 分钟上限：约拍 ' + Math.floor(SAFETY_SEC / AUTO_IV) + ' 张就会自动停（满 3 分钟了）';
      } else {
        auto = '自动拍约需 ' + fmtDur(need) + '（每 2 秒一张，拍够 ' + target + ' 张自动停）';
      }
    } else {
      auto = '手动：点一下拍一张；拍够张数自动停，拍摄满 3 分钟也会自动停';
    }
    this.setData({ rows: rows, bigLine: big, autoLine: auto });
  },
  _save() { sset(CFGKEY, this._cfg); },
  _cycle(act) {
    var c = this._cfg;
    function nxtKey(arr, key) {
      for (var i = 0; i < arr.length; i++) if (arr[i].key === key) return arr[(i + 1) % arr.length].key;
      return arr[0].key;
    }
    if (act === 'speed') c.speedKey = nxtKey(SPEEDS, c.speedKey);
    else if (act === 'len') c.lenKey = nxtKey(LENS, c.lenKey);
    else if (act === 'mode') c.mode = (c.mode === 'auto') ? 'manual' : 'auto';
    this._save(); this._render();
    this.setData({ evt: 'EVT: set ' + act });
    if (act === 'speed') this._speak('速度 ' + speedOf(c).label);
    if (act === 'len') this._speak('长度 ' + lenOf(c).label);
    if (act === 'mode') this._speak(c.mode === 'auto' ? '自动拍，每 2 秒一张' : '手动拍，点一下拍一张');
  },
  _move(dir) {
    var n = this._defs().length;
    this._sel = ((this._sel || 0) + dir + n) % n;
    this._render();
    this.setData({ evt: 'EVT: sel ' + this._defs()[this._sel].name });
  },
  _activate(i) {
    var d = this._defs()[i];
    if (!d) return;
    this._sel = i;
    if (d.act === 'name') { this._nameByVoice(); return; }
    if (d.act === 'shoot') { this._save(); try { wx.navigateTo({ url: '/pages/shoot/index' }); } catch (e) {} return; }
    if (d.act === 'play') { try { wx.navigateTo({ url: '/pages/play/index' }); } catch (e) {} return; }
    this._cycle(d.act);
  },
  onRowTap(e) {
    var i = this._sel || 0;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this._sel || 0;
    this._activate(i);
  },
  _stopAsr() { try { if (this._rec) { this._rec.abort(); this._rec = null; } } catch (e) {} },
  _nameByVoice() {
    try {
      if (typeof SpeechRecognition === 'undefined') { this.setData({ status: '本机无 SpeechRecognition，语音起名不可用（如实），先用默认名', evt: 'EVT: ASR n/a' }); return; }
      this._stopAsr();
      var rec = new SpeechRecognition();
      rec.interimResults = true;
      var self = this;
      rec.onresult = function (e) {
        try {
          var tr = e.results[e.resultIndex][0].transcript;
          var fin = e.results[e.resultIndex].isFinal;
          self.setData({ status: '语音听写：' + tr + (fin ? '（定稿）' : '（中间）') });
          if (fin && tr) {
            if (String(tr).indexOf('开始') >= 0) {
              self._save(); self._speak('开始拍摄');
              try { wx.navigateTo({ url: '/pages/shoot/index' }); } catch (err) {}
              return;
            }
            self._cfg.name = String(tr).slice(0, 20);
            self._save(); self._render();
            self.setData({ evt: 'EVT: name=' + self._cfg.name });
            self._speak('作品名 ' + self._cfg.name);
          }
        } catch (err) {}
      };
      rec.onerror = function (ev) { self.setData({ status: '语音失败：' + String((ev && ev.error) || 'error') + '，可重说纠错', evt: 'EVT: ASR error' }); };
      rec.onend = function () { self._rec = null; };
      this._rec = rec;
      rec.start();
      this.setData({ status: '聆听中：说出作品名（说错重说即可）；说「开始」直接去拍摄', evt: 'EVT: ASR listening' });
    } catch (e) { this.setData({ status: '语音启动失败（如实）：' + String((e && e.message) || e).slice(0, 40), evt: 'EVT: ASR fail' }); }
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
    if (k === 'Enter' || k === 'GlobalHook') this._activate(this._sel || 0);
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._activate(this._sel || 0); }
};
</script>

<page>
  <view class="page">
    <text class="ttl">STOP MOTION · 定格工场</text>
    <text class="status">{{status}}</text>
    <view class="slist">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="onRowTap" data-idx="{{index}}">
        <text class="sname">{{item.mark}} {{item.name}}</text>
        <text class="sval">{{item.val}}</text>
      </view>
    </view>
    <text class="big">{{bigLine}}</text>
    <text class="auto">{{autoLine}}</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 3px; }
.slist { display: flex; flex-direction: column; margin-top: 6px; }
.srow { display: flex; flex-direction: row; border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 7px 10px; margin-bottom: 4px; }
.srow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.sname { flex-grow: 1; color: #40ff5e; font-size: 13px; }
.sval { color: #7dff9e; font-size: 12px; font-family: monospace; }
.big { color: #7dff9e; font-size: 17px; font-weight: 500; margin-top: 8px; border: 1px dashed rgba(125,255,158,0.6); padding: 6px 8px; }
.auto { color: rgba(64,255,94,0.8); font-size: 10px; margin-top: 5px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
