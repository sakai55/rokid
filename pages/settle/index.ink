<script def>
{
  "title": "Chunk Settle"
}
</script>

<script setup>
import wx from 'wx';

var LKEY = 'av03_last';
var SKEY = 'av03_sessions';

export default {
  data: {
    evt: 'EVT: settle ready',
    ver: 'v1.0.0',
    status: '最近一次录制的分片结算',
    lines: [],
    estLine: '上限估算：待数据',
    saved: false
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._last = null;
    try {
      var v = wx.getStorageSync(LKEY);
      this._last = (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    this._render();
  },
  _load() {
    try {
      var v = wx.getStorageSync(SKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return [];
  },
  _save(list) { try { wx.setStorageSync(SKEY, list); } catch (e) {} },
  _render() {
    var l = this._last;
    if (!l) {
      this.setData({ status: '尚无录制结果：先去录制页录一段（不编造结算）', lines: [] });
      return;
    }
    var mb = l.bytes / 1048576;
    var perMin = l.durSec > 0 ? mb / (l.durSec / 60) : 0;
    // Estimate basis (stated, not measured): assume 8 GB of free space on
    // the 32 GB device; real free space is a host value this page cannot
    // read, so the cap below is an estimate on that stated assumption.
    var capMin = perMin > 0 ? Math.floor(8192 / perMin) : 0;
    var lines = [
      { k: '分片数', v: '' + l.chunks + '（start(1000) 每秒一片）' },
      { k: '总字节', v: l.bytes + 'B · ' + mb.toFixed(2) + ' MB' },
      { k: '时长', v: l.durSec + 's · 格式 ' + l.mime },
      { k: '速率', v: perMin.toFixed(2) + ' MB/分钟' }
    ];
    this.setData({
      lines: lines,
      estLine: '上限估算：按 ' + perMin.toFixed(2) + ' MB/分钟 × 假设可用空间 8GB（假设值，非实测）≈ 可录 ' + capMin + ' 分钟'
    });
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onSaveTap() { this._confirmSave(); },
  _confirmSave() {
    if (!this._last || this.data.saved) { try { wx.navigateTo({ url: '/pages/history/index' }); } catch (e) {} return; }
    var list = this._load();
    var l = this._last;
    list.unshift({ at: new Date(l.at || Date.now()).toISOString().slice(0, 16).replace('T', ' '), chunks: l.chunks, bytes: l.bytes, durSec: l.durSec, mime: l.mime });
    this._save(list.slice(0, 30));
    this.setData({ saved: true, status: '已写入历史，去看总计', evt: 'EVT: session saved' });
    this._speak('结算已保存');
    try { wx.navigateTo({ url: '/pages/history/index' }); } catch (e) {}
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
    if (k === 'Enter' || k === 'GlobalHook') this._confirmSave();
    else if (k === 'ArrowDown' || k === 'ArrowUp') this._speak(this.data.estLine);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._confirmSave(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="dialbtn dialbtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">SETTLE · 结算</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="slist">
      <view ink:for="{{lines}}" class="srow">
        <text class="sk">{{item.k}}</text>
        <text class="sv">{{item.v}}</text>
      </view>
    </view>
    <text class="est">{{estLine}}</text>
    <button class="dialbtn dialbtn-main" bindtap="onSaveTap">SAVE 写入历史</button>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.dialbtn { border-radius: 24px; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.14); color: #7dff9e; font-size: 11px; padding: 6px 0; text-align: center; }
.dialbtn-back { padding: 3px 10px; font-size: 10px; }
.dialbtn-main { margin-top: 10px; padding: 9px 0; font-size: 13px; background-color: rgba(125,255,158,0.22); }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.slist { display: flex; flex-direction: column; margin-top: 8px; }
.srow { display: flex; flex-direction: row; border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 7px 10px; margin-bottom: 5px; border-radius: 12px; }
.sk { color: #40ff5e; font-size: 12px; font-weight: 500; width: 64px; }
.sv { color: #7dff9e; font-family: monospace; font-size: 11px; }
.est { color: rgba(125,255,158,0.9); font-size: 10px; margin-top: 6px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
