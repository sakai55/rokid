<script def>
{
  "title": "Mic Memory"
}
</script>

<script setup>
import wx from 'wx';

var BKEY = 'av04_best';
var ENVS = ['街头', '会议室', '近耳语'];

export default {
  data: {
    evt: 'EVT: memory ready',
    ver: 'v1.0.0',
    status: '三环境各自的最佳模式（跨会话保存）',
    selIdx: 0,
    rows: []
  },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._refresh(); },
  onShow() { this._refresh(); },
  _load() {
    try {
      var v = wx.getStorageSync(BKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return {};
  },
  _save(o) { try { wx.setStorageSync(BKEY, o); } catch (e) {} },
  _refresh() {
    var best = this._load();
    var sel = this.data.selIdx;
    var rows = ENVS.map(function (e, i) {
      return { env: e, mode: best[e] || '未测', cls: i === sel ? 'mrow2 mrow2-sel' : 'mrow2', mark: i === sel ? '▸' : '·' };
    });
    this.setData({ rows: rows });
  },
  _move(dir) {
    var s = (this.data.selIdx + dir + ENVS.length) % ENVS.length;
    this.setData({ selIdx: s, evt: 'EVT: mem sel ' + ENVS[s] });
    this._refresh();
  },
  _speakSel() {
    var best = this._load();
    var e = ENVS[this.data.selIdx];
    this._speak(e + '最佳模式' + (best[e] || '未测'));
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onClearTap() {
    this._save({});
    this.setData({ evt: 'EVT: memory cleared' });
    this._refresh();
    this._speak('环境记忆已清空');
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
      <button class="lanebtn lanebtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">MEMORY · 环境记忆</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="mlist2">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="menv">{{item.mark}} {{item.env}}</text>
        <text class="mmode">{{item.mode}}</text>
      </view>
    </view>
    <view class="btnrow">
      <button class="lanebtn" bindtap="onSpeakTap">SPEAK 播报</button>
      <button class="lanebtn" bindtap="onClearTap">CLEAR 清空</button>
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
.lanebtn { border-left: 6px solid #40ff5e; border-top: 1px solid rgba(64,255,94,0.7); border-bottom: 1px solid rgba(64,255,94,0.7); border-right: 1px solid rgba(64,255,94,0.7); background-color: #0a1f0e; color: #7dff9e; font-size: 11px; padding: 7px 0; text-align: center; flex-grow: 1; margin-right: 6px; }
.lanebtn-back { flex-grow: 0; padding: 3px 8px; font-size: 10px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.mlist2 { display: flex; flex-direction: column; margin-top: 8px; }
.mrow2 { display: flex; flex-direction: row; align-items: center; border-left: 8px solid rgba(64,255,94,0.45); background-color: #04140a; padding: 9px 10px; margin-bottom: 6px; }
.mrow2-sel { border-left: 8px solid #7dff9e; background-color: #0a1f0e; }
.menv { color: #40ff5e; font-size: 14px; font-weight: 500; width: 90px; }
.mmode { color: #7dff9e; font-family: monospace; font-size: 12px; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
