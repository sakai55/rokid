<script def>
{
  "title": "Tri Shot History"
}
</script>

<script setup>
import wx from 'wx';

var HKEY = 'av01_history';

export default {
  data: {
    evt: 'EVT: history ready',
    ver: 'v1.0.0',
    status: '历史判读（最近 8 条）',
    countLine: '共 0 条',
    selIdx: 0,
    rows: []
  },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._refresh(); },
  onShow() { this._refresh(); },
  _load() {
    try {
      var v = wx.getStorageSync(HKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return [];
  },
  _save(list) { try { wx.setStorageSync(HKEY, list); } catch (e) {} },
  _refresh() {
    var list = this._load();
    var sel = this.data.selIdx;
    var rows = list.slice(0, 8).map(function (h, i) {
      return {
        line: h.at + ' · ' + h.target,
        concl: h.conclusion,
        llm: h.llm ? 'LLM 判读' : '仅像素对照',
        cls: i === sel ? 'hrow hrow-sel' : 'hrow'
      };
    });
    this.setData({ rows: rows, countLine: '共 ' + list.length + ' 条（显示最近 8 条）', status: list.length ? '历史判读（最近 8 条）' : '暂无历史：先完成一次连拍判读' });
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
    if (h) this._speak(h.target + '，' + h.conclusion);
    else this._speak('暂无历史');
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
      <button class="backbtn" bindtap="onBackTap">BACK</button>
      <text class="ttl">HISTORY · 历史</text>
      <text class="cnt">{{countLine}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="hlist">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="hline">{{item.line}}</text>
        <text class="hconcl">{{item.concl}}</text>
        <text class="hllm">{{item.llm}}</text>
      </view>
    </view>
    <view class="btnrow">
      <button class="sqbtn" bindtap="onSpeakTap">SPEAK 播报选中</button>
      <button class="sqbtn" bindtap="onClearTap">CLEAR 清空</button>
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
.backbtn { border-radius: 0; border: 1px solid rgba(64,255,94,0.8); background-color: #04140a; color: rgba(125,255,158,0.9); font-size: 10px; padding: 3px 8px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.cnt { color: rgba(64,255,94,0.7); font-size: 10px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.hlist { display: flex; flex-direction: column; margin-top: 6px; }
.hrow { border-left: 4px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 4px 10px; margin-bottom: 4px; border-radius: 0; }
.hrow-sel { border-left: 4px solid #7dff9e; background-color: #0a1f0e; }
.hline { color: #40ff5e; font-size: 11px; font-weight: 500; }
.hconcl { color: rgba(125,255,158,0.9); font-size: 10px; margin-left: 8px; }
.hllm { color: rgba(64,255,94,0.6); font-size: 9px; margin-left: 8px; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.sqbtn { flex-grow: 1; border-radius: 0; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.16); color: #7dff9e; font-size: 12px; padding: 7px 0; text-align: center; margin-right: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
