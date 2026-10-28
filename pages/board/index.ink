<script def>
{
  "title": "Mic Board"
}
</script>

<script setup>
import wx from 'wx';

var RKEY = 'av04_rounds';
var BKEY = 'av04_best';

export default {
  data: {
    evt: 'EVT: board ready',
    ver: 'v1.0.0',
    status: '四轮按 RMS/峰值综合排序',
    envName: '-',
    conclusion: '结论：待四轮数据',
    saved: false,
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._best = null;
    this._render();
  },
  onShow() { this._render(); },
  _loadBest() {
    try {
      var v = wx.getStorageSync(BKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return {};
  },
  _render() {
    var wrap = null;
    try {
      var v = wx.getStorageSync(RKEY);
      wrap = (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    var results = (wrap && wrap.results) || [];
    var env = (wrap && wrap.env) || '-';
    this.setData({ envName: env });
    var scored = results.filter(function (r) { return r && r.mode; }).map(function (r) {
      return { mode: r.mode, actual: r.actual, fellBack: r.fellBack, rms: r.rms || 0, peak: r.peak || 0, score: (r.rms || 0) + (r.peak || 0) * 0.25 };
    });
    scored.sort(function (a, b) { return b.score - a.score; });
    var rows = scored.map(function (r, i) {
      return {
        rank: '' + (i + 1),
        mode: r.mode,
        line: 'RMS ' + r.rms.toFixed(3) + ' · 峰值 ' + r.peak.toFixed(2) + ' · 综合 ' + r.score.toFixed(3) + (r.fellBack ? ' · exact→ideal' : ''),
        cls: i === 0 ? 'brow brow-top' : 'brow'
      };
    });
    this._best = scored.length ? scored[0] : null;
    this.setData({
      rows: rows,
      conclusion: this._best ? ('结论：' + env + ' 环境最佳模式 = ' + this._best.mode) : '结论：尚无四轮数据（先去四轮页实测，不编造排名）',
      status: scored.length ? '四轮按 RMS/峰值综合排序（综合 = RMS + 峰值×0.25）' : '暂无数据'
    });
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onSaveTap() { this._confirmSave(); },
  _confirmSave() {
    if (!this._best) { this.setData({ evt: 'EVT: no data to save' }); return; }
    var best = this._loadBest();
    best[this.data.envName] = this._best.mode;
    try { wx.setStorageSync(BKEY, best); } catch (e) {}
    this.setData({ saved: true, status: '已写入环境记忆：' + this.data.envName + ' → ' + this._best.mode, evt: 'EVT: best saved' });
    this._speak(this.data.conclusion);
    try { wx.navigateTo({ url: '/pages/memory/index' }); } catch (e) {}
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
    else if (k === 'ArrowDown' || k === 'ArrowUp') this._speak(this.data.conclusion);
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
      <button class="lanebtn lanebtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">BOARD · 评分榜</text>
      <text class="env">{{envName}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="blist">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="brank">{{item.rank}}</text>
        <text class="bmode">{{item.mode}}</text>
        <text class="bline">{{item.line}}</text>
      </view>
    </view>
    <text class="concl">{{conclusion}}</text>
    <button class="lanebtn lanebtn-main" bindtap="onSaveTap">SAVE 存入环境记忆</button>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.lanebtn { border-left: 6px solid #40ff5e; border-top: 1px solid rgba(64,255,94,0.7); border-bottom: 1px solid rgba(64,255,94,0.7); border-right: 1px solid rgba(64,255,94,0.7); background-color: #0a1f0e; color: #7dff9e; font-size: 11px; padding: 7px 0; text-align: center; }
.lanebtn-back { padding: 3px 8px; font-size: 10px; }
.lanebtn-main { margin-top: 10px; padding: 9px 0; font-size: 13px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.env { color: #40ff5e; font-size: 12px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.blist { display: flex; flex-direction: column; margin-top: 7px; }
.brow { display: flex; flex-direction: row; align-items: center; border-left: 8px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 6px 8px; margin-bottom: 5px; }
.brow-top { border-left: 8px solid #7dff9e; background-color: rgba(125,255,158,0.2); }
.brank { color: #7dff9e; font-size: 16px; font-weight: 500; width: 22px; }
.bmode { color: #40ff5e; font-family: monospace; font-size: 11px; width: 108px; }
.bline { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 9px; }
.concl { color: #7dff9e; font-size: 13px; font-weight: 500; margin-top: 5px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
