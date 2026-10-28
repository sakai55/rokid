<script def>
{"title": "AV Sync Check"}
</script>

<script setup>
import wx from 'wx';

// AV09 history: persistent reports av09_reports, list + clear.
const KEY = 'av09_reports';
const ACTS = ['朗读最近一条', '清空历史', '返回 BACK'];

export default {
  data: {
    status: '历史：历次声画同检报告',
    rows: [],
    countLine: '报告 0 条',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._steady = false; this._render(); },
  onShow() { this._render(); },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) { const p = (typeof v === 'string') ? JSON.parse(v) : v; if (Array.isArray(p)) return p; } } catch (e) {} return []; },
  _save(a) { try { wx.setStorageSync(KEY, a); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _render() {
    const recs = this._load();
    const rows = recs.slice(-6).reverse().map((r) => ({ text: (r.time || '').slice(5, 16) + ' · ' + (r.verdict || '') + ' · ' + (r.fps || '?') + 'fps · 最大间隔 ' + (r.maxGap || '?') + 'ms · RMS ' + (r.rmsMean === undefined ? '?' : r.rmsMean) + ' · delta中位 ' + (r.deltaMedian === null || r.deltaMedian === undefined ? '无' : (r.deltaMedian + 'ms')) }));
    this.setData({ rows: rows, countLine: '报告 ' + recs.length + ' 条（持久化 ' + KEY + '）', focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）' });
  },
  speakTap() {
    const recs = this._load();
    if (!recs.length) { this.setData({ evt: 'EVT: speak refused - empty' }); return; }
    const r = recs[recs.length - 1];
    this._speak('最近一次判定' + (r.verdict || '') + '，帧率' + (r.fps || '?') + '，差值中位' + (r.deltaMedian === null || r.deltaMedian === undefined ? '无' : (r.deltaMedian + '毫秒')));
  },
  clearTap() { this._save([]); this.setData({ status: '历史已清空（本人操作）', evt: 'EVT: history cleared' }); this._render(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.speakTap(); else if (this._focus === 1) this.clearTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (k === 'Enter') {  this.doAct(); }
    else if (k === 'ArrowUp') {  this.moveTap(-1); }
    else if (k === 'ArrowDown') {  this.moveTap(1); }
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">AV Sync Check · 历史</text>
    <text class="status">{{status}}</text>
    <view class="list">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <text class="line dim">{{countLine}}</text>
    <button class="dash" bindtap="actTap" data-idx="0">朗读最近一条</button>
    <button class="dash" bindtap="actTap" data-idx="1">清空历史</button>
    <button class="dash" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.list { display: flex; flex-direction: column; margin-top: 5px; min-height: 70px; }
.row { padding: 3px 4px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.rtxt { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; }
.dash { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.65); border-radius: 8px; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
