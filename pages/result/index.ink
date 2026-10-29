<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults } from '../../judge.js';
import { log, flushLog } from '../../logq.js';

// 结果单：四站关键数的大字汇总，持久保存、可翻回看。
// 这一页就是给 GO 的主反馈面——截图这一页即可回报四站结果；
// 配了日志钥匙时，进页同时把汇总经 logq 上报一次。
const ACTS = ['刷新', 'BACK 返回'];

function median(arr) {
  if (!arr.length) return null;
  const s = arr.slice().sort(function (a, b) { return a - b; });
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : Math.round((s[m - 1] + s[m]) / 2);
}
function avg(arr, dec) {
  if (!arr.length) return null;
  const v = arr.reduce(function (a, b) { return a + b; }, 0) / arr.length;
  const p = Math.pow(10, dec || 0);
  return Math.round(v * p) / p;
}

export default {
  data: {
    status: '结果单：四站汇总（这一页截图即可回报）',
    storageBig: '存储：未测',
    gestureBig: '手势：未测',
    headingBig: '朝向：未测',
    timingBig: '判定：未测',
    detailLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); this._report(); },
  onShow() { this._render(); },
  _summary(r) {
    const out = {};
    if (r.storage) {
      const s = r.storage;
      const fmt = function (b) { return b.sizes.map(function (x) { return x.kb + 'K' + (x.ok ? '✓' : '✗'); }).join(' ') + ' 累计' + b.cumKB + 'K'; };
      out.storage = '存储 LS[' + fmt(s.local) + '] WX[' + fmt(s.wx) + '] 房块' + (s.roomOk ? '✓' : '✗') + ' 上次标记' + (s.prevMark && s.prevMark.found ? '在' : '不在');
    }
    const gt = (r.gesture && r.gesture.trials) || [];
    const marked = gt.filter(function (t) { return t && t.truth; });
    if (marked.length) {
      const right = marked.filter(function (t) { return t.truth === 'right'; }).length;
      out.gesture = '手势 认对 ' + right + '/' + marked.length + ' · 平均把握 ' + avg(marked.map(function (t) { return t.confidence; }), 2);
      out.gestureRight = right; out.gestureN = marked.length;
    }
    const ht = (r.heading && r.heading.trials) || [];
    if (ht.length || (r.heading && r.heading.nods)) {
      out.heading = '朝向 ' + ht.length + '/4 向' + (ht.length ? ' · 平均误差 ' + avg(ht.map(function (t) { return t.errDeg; }), 1) + '° · 头稳平均 ' + avg(ht.map(function (t) { return t.steadyMs; })) + 'ms' : '') + ' · 点头 ' + ((r.heading && r.heading.nods) || 0) + ' 次';
    }
    const tr = (r.timing && r.timing.runs) || [];
    if (tr.length) {
      out.timing = '判定 ' + tr.length + '/3 次 · 总耗时中位 ' + median(tr.map(function (x) { return x.totalMs; })) + 'ms · 平均把握 ' + avg(tr.map(function (x) { return x.confidence; }), 2);
    }
    return out;
  },
  _render() {
    const r = loadResults();
    const s = this._summary(r);
    const details = [];
    if (r.storage) details.push('存储明细：样本房块 ' + r.storage.roomBytes + ' B 往返' + (r.storage.roomOk ? '无损' : '失败') + ' · 测于 ' + String(r.storage.at || '').slice(0, 16));
    const gt = (r.gesture && r.gesture.trials) || [];
    if (gt.length) details.push('手势逐次：' + gt.map(function (t, i) { return (i + 1) + '.' + t.guess + '/' + t.confidence + '/' + (t.truth === 'right' ? '对' : (t.truth === 'wrong' ? '错' : '未标')); }).join(' '));
    const tr = (r.timing && r.timing.runs) || [];
    if (tr.length) details.push('判定逐次：' + tr.map(function (x, i) { return (i + 1) + '.总' + x.totalMs + 'ms' + (x.geoAcc !== null && x.geoAcc !== undefined ? ' 定位±' + x.geoAcc + 'm' : (x.geoCode ? ' 定位' + x.geoCode : '')); }).join(' '));
    this.setData({
      storageBig: s.storage ? ('存储：' + s.storage) : '存储：未测',
      gestureBig: s.gesture ? ('手势：' + s.gesture) : '手势：未测',
      headingBig: s.heading ? ('朝向：' + s.heading) : '朝向：未测',
      timingBig: s.timing ? ('判定：' + s.timing) : '判定：未测',
      detailLine: details.join('\n'),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击或点头执行）'
    });
  },
  _report() {
    const r = loadResults();
    const s = this._summary(r);
    log('result', '', [s.storage || 'storage:-', s.gesture || 'gesture:-', s.heading || 'heading:-', s.timing || 'timing:-'].join(' | '));
    flushLog();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) { this._render(); this._report(); this.setData({ evt: 'EVT: refreshed' }); } else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">结果单</text>
    <text class="status">{{status}}</text>
    <view class="card big">
      <text class="bline">{{storageBig}}</text>
      <text class="bline">{{gestureBig}}</text>
      <text class="bline">{{headingBig}}</text>
      <text class="bline">{{timingBig}}</text>
    </view>
    <text class="line">{{detailLine}}</text>
    <button class="banner" bindtap="actTap" data-idx="0">刷新</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · 结果存本机，关掉重开不丢</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 6px 8px; margin-top: 4px; }
.bline { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 19px; margin-top: 2px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.banner { color: #04140a; background-color: #40ff5e; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
