<script def>
{
  "title": "Motion Log"
}
</script>

<script setup>
import wx from 'wx';

var LKEY = 'av02_log';

export default {
  data: {
    evt: 'EVT: log ready',
    ver: 'v1.0.0',
    status: '变化日志与计数结算',
    countLine: '共 0 次 · 最大差值 -%',
    selIdx: 0,
    rows: []
  },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._refresh(); },
  onShow() { this._refresh(); },
  _load() {
    try {
      var v = wx.getStorageSync(LKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return [];
  },
  _save(list) { try { wx.setStorageSync(LKEY, list); } catch (e) {} },
  _refresh() {
    var list = this._load();
    var max = 0;
    list.forEach(function (h) { if (h.diff > max) max = h.diff; });
    var sel = this.data.selIdx;
    var rows = list.slice(0, 8).map(function (h, i) {
      return { line: h.at + ' · 差值 ' + h.diff + '%', desc: h.desc, cls: i === sel ? 'lrow lrow-sel' : 'lrow' };
    });
    this.setData({
      rows: rows,
      countLine: '共 ' + list.length + ' 次 · 最大差值 ' + (list.length ? max + '%' : '-%'),
      status: list.length ? '变化日志与计数结算' : '暂无记录：先完成一次监看触发'
    });
  },
  _move(dir) {
    var n = this._load().slice(0, 8).length;
    if (!n) return;
    var s = (this.data.selIdx + dir + n) % n;
    this.setData({ selIdx: s, evt: 'EVT: log sel ' + s });
    this._refresh();
  },
  _speakSel() {
    var list = this._load();
    var h = list[this.data.selIdx];
    if (h) this._speak('差值' + h.diff + '%，' + h.desc);
    else this._speak(this.data.countLine);
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onClearTap() {
    this._save([]);
    this.setData({ selIdx: 0, evt: 'EVT: log cleared' });
    this._refresh();
    this._speak('日志已清空');
  },
  onSpeakTap() { this._speakSel(); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter' || k === 'GlobalHook') this._speakSel();
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._speakSel(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="alertbtn alertbtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">LOG · 日志</text>
      <text class="cnt">{{countLine}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="llist">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="lline">{{item.line}}</text>
        <text class="ldesc">{{item.desc}}</text>
      </view>
    </view>
    <view class="btnrow">
      <button class="alertbtn alertbtn-half" bindtap="onSpeakTap">SPEAK 播报</button>
      <button class="alertbtn alertbtn-half" bindtap="onClearTap">CLEAR 清空</button>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.alertbtn { border-top: 3px solid #40ff5e; border-bottom: 3px solid #40ff5e; border-left: 1px solid rgba(64,255,94,0.7); border-right: 1px solid rgba(64,255,94,0.7); background-color: #04140a; color: #7dff9e; text-align: center; }
.alertbtn-back { font-size: 10px; padding: 3px 8px; }
.alertbtn-half { flex-grow: 1; font-size: 12px; padding: 9px 0; margin-right: 8px; background-color: rgba(64,255,94,0.18); }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.cnt { color: rgba(64,255,94,0.7); font-family: monospace; font-size: 9px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.llist { display: flex; flex-direction: column; margin-top: 6px; }
.lrow { border-left: 5px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 4px 10px; margin-bottom: 4px; }
.lrow-sel { border-left: 5px solid #7dff9e; background-color: #0a1f0e; }
.lline { color: #40ff5e; font-size: 11px; font-weight: 500; }
.ldesc { color: rgba(125,255,158,0.9); font-size: 10px; margin-left: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
