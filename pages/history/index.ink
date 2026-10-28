<script def>
{
  "title": "Chunk History"
}
</script>

<script setup>
import wx from 'wx';

var SKEY = 'av03_sessions';

export default {
  data: {
    evt: 'EVT: history ready',
    ver: 'v1.0.0',
    status: '录制历史与总计',
    totalLine: '共 0 场 · 0B · 0s',
    selIdx: 0,
    rows: []
  },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._refresh(); },
  onShow() { this._refresh(); },
  _load() {
    try {
      var v = wx.getStorageSync(SKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return [];
  },
  _save(list) { try { wx.setStorageSync(SKEY, list); } catch (e) {} },
  _refresh() {
    var list = this._load();
    var tb = 0, td = 0, tc = 0;
    list.forEach(function (h) { tb += h.bytes || 0; td += h.durSec || 0; tc += h.chunks || 0; });
    var sel = this.data.selIdx;
    var rows = list.slice(0, 8).map(function (h, i) {
      return {
        line: h.at + ' · ' + h.durSec + 's',
        detail: h.chunks + ' 片 · ' + h.bytes + 'B · ' + h.mime,
        cls: i === sel ? 'hrow hrow-sel' : 'hrow'
      };
    });
    this.setData({
      rows: rows,
      totalLine: '共 ' + list.length + ' 场 · ' + tc + ' 片 · ' + tb + 'B · ' + td + 's',
      status: list.length ? '录制历史与总计' : '暂无历史：先完成一次录制结算'
    });
  },
  _move(dir) {
    var n = this._load().slice(0, 8).length;
    if (!n) return;
    var s = (this.data.selIdx + dir + n) % n;
    this.setData({ selIdx: s, evt: 'EVT: hist sel ' + s });
    this._refresh();
  },
  _speakSel() {
    var list = this._load();
    var h = list[this.data.selIdx];
    if (h) this._speak(h.durSec + '秒，' + h.chunks + '个分片');
    else this._speak(this.data.totalLine);
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onClearTap() {
    this._save([]);
    this.setData({ selIdx: 0, evt: 'EVT: history cleared' });
    this._refresh();
    this._speak('历史已清空');
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
      <button class="dialbtn dialbtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">HISTORY · 历史</text>
      <text class="tot">{{totalLine}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="hlist">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="hline">{{item.line}}</text>
        <text class="hdetail">{{item.detail}}</text>
      </view>
    </view>
    <view class="btnrow">
      <button class="dialbtn" bindtap="onSpeakTap">SPEAK 播报</button>
      <button class="dialbtn" bindtap="onClearTap">CLEAR 清空</button>
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
.dialbtn { border-radius: 24px; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.14); color: #7dff9e; font-size: 11px; padding: 6px 0; text-align: center; flex-grow: 1; margin-right: 6px; }
.dialbtn-back { flex-grow: 0; padding: 3px 10px; font-size: 10px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.tot { color: rgba(64,255,94,0.7); font-family: monospace; font-size: 9px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.hlist { display: flex; flex-direction: column; margin-top: 6px; }
.hrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 5px 10px; margin-bottom: 4px; border-radius: 12px; }
.hrow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.hline { color: #40ff5e; font-size: 11px; font-weight: 500; }
.hdetail { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 10px; margin-left: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
