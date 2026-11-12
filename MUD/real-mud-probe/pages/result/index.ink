<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults } from '../../judge.js';
import { log, flushLog } from '../../logq.js';

// 结果单：共 5 屏——第 1 屏四站大字汇总，第 2~5 屏四站逐项明细
// （存储逐项 / 手势逐次 / 朝向逐向 / 判定逐次），每屏顶部标屏序
// 与段名。逐屏截屏（或拍照）即可把全部原始数带回，不依赖网络
// 与日志钥匙；配了钥匙时，进页同时经 logq 上报一条汇总。
// 明细一律取已落盘 results 的原始字段，不在结果页现算假数
// （汇总里的平均/中位是展示口径，与汇总屏同源）。
const ACTS = ['刷新', '明细下一屏', 'BACK 返回'];
const SCREEN_NAMES = ['汇总', '存储逐项', '手势逐次', '朝向逐向', '判定逐次'];
const GNAME = { open_palm: '开掌', other: '其他手势', none: '没看到手' };

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
    status: '结果单：共 5 屏，逐屏截屏即可带回全部原始数',
    screenLine: '第 1/5 屏 · 汇总',
    storageBig: '存储：未测',
    gestureBig: '手势：未测',
    headingBig: '朝向：未测',
    timingBig: '判定：未测',
    detailLine: '',
    detTitle: '',
    detBody: '',
    sumCls: 'card big',
    sumDetCls: 'line',
    detCls: 'card big hide',
    focusLine: '',
    cls0: 'banner', cls1: 'banner ghost', cls2: 'banner ghost',
    evt: 'EVT: ready',
    ver: 'v1.0.3'
  },
  onLoad() { this._focus = 0; this._screen = 0; this._render(); this._report(); },
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
  _detail(r, screen) {
    // 每段明细取落盘原始字段逐项列全，不截断、不现算假数。
    if (screen === 1) {
      const s = r.storage;
      if (!s) return '存储：未测（无落盘数据）';
      const be = function (name, b) {
        if (!b || b.na) return [name + '：接口不存在'];
        return [
          name + ' 单值：' + b.sizes.map(function (x) { return x.kb + 'K' + (x.ok ? '✓' : '✗'); }).join(' '),
          name + ' 累计：' + b.cumKB + ' KB' + (b.cumCapped ? '（达 500K 上限未失败）' : '（写失败停）')
        ];
      };
      const lines = be('localStorage', s.local).concat(be('wx 存储', s.wx));
      lines.push('样本房块：' + s.roomBytes + ' B · 往返' + (s.roomOk ? '无损 PASS' : 'FAIL'));
      lines.push('上次标记：' + (s.prevMark && s.prevMark.found ? ('在（' + s.prevMark.at + '）') : '不在'));
      lines.push('测试时间：' + String(s.at || '').slice(0, 19).replace('T', ' '));
      return lines.join('\n');
    }
    if (screen === 2) {
      const gt = (r.gesture && r.gesture.trials) || [];
      if (!gt.length) return '手势：未测（无落盘数据）';
      const marked = gt.filter(function (t) { return t && t.truth; });
      const right = marked.filter(function (t) { return t.truth === 'right'; }).length;
      const lines = ['认对 ' + right + '/' + marked.length + ' · 平均把握 ' + (marked.length ? avg(marked.map(function (t) { return t.confidence; }), 2) : '—') + '（已标 ' + marked.length + '/10）'];
      gt.forEach(function (t, i) {
        lines.push('#' + (i + 1) + ' 判定 ' + (GNAME[t.guess] || t.guess) + '（' + t.guess + '）· 把握 ' + t.confidence + ' · 真值 ' + (t.truth === 'right' ? '对' : (t.truth === 'wrong' ? '错' : '未标')));
      });
      return lines.join('\n');
    }
    if (screen === 3) {
      const h = r.heading || {};
      const ht = h.trials || [];
      if (!ht.length && !h.nods && !h.calibrated) return '朝向：未测（无落盘数据）';
      const lines = [];
      ht.forEach(function (t) {
        lines.push(t.target + '（' + t.targetDeg + '°）：误差 ' + t.errDeg + '° · 头稳 ' + t.steadyMs + ' ms');
      });
      if (ht.length) lines.push('平均误差 ' + avg(ht.map(function (t) { return t.errDeg; }), 1) + '° · 头稳平均 ' + avg(ht.map(function (t) { return t.steadyMs; })) + ' ms（已记 ' + ht.length + '/4 向）');
      lines.push('点头计数：' + (h.nods || 0) + ' 次');
      lines.push('已校准：' + (h.calibrated ? '是（曾定中心）' : '否'));
      return lines.join('\n');
    }
    if (screen === 4) {
      const tr = (r.timing && r.timing.runs) || [];
      if (!tr.length) return '判定：未测（无落盘数据）';
      const lines = ['总耗时中位 ' + median(tr.map(function (x) { return x.totalMs; })) + ' ms · 平均把握 ' + avg(tr.map(function (x) { return x.confidence; }), 2) + '（' + tr.length + '/3 次）'];
      tr.forEach(function (x, i) {
        const geo = (x.geoAcc !== null && x.geoAcc !== undefined) ? ('定位 ±' + x.geoAcc + ' m') : ('定位 ' + (x.geoCode ? ('失败 ' + x.geoCode) : '未回'));
        lines.push('#' + (i + 1) + ' 总 ' + x.totalMs + ' ms：拍 ' + x.photoMs + ' / 编 ' + x.encodeMs + ' / LLM ' + x.llmMs);
        lines.push('　 把握 ' + x.confidence + ' · 认出 ' + x.recognizedCount + ' 物 · ' + geo);
      });
      return lines.join('\n');
    }
    return '';
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
    const sc = this._screen || 0;
    const upd = {
      storageBig: s.storage ? ('存储：' + s.storage) : '存储：未测',
      gestureBig: s.gesture ? ('手势：' + s.gesture) : '手势：未测',
      headingBig: s.heading ? ('朝向：' + s.heading) : '朝向：未测',
      timingBig: s.timing ? ('判定：' + s.timing) : '判定：未测',
      detailLine: details.join('\n'),
      screenLine: '第 ' + (sc + 1) + '/5 屏 · ' + SCREEN_NAMES[sc],
      detTitle: sc === 0 ? '' : ('明细 ' + (sc + 1) + '/5 · ' + SCREEN_NAMES[sc]),
      detBody: sc === 0 ? '' : this._detail(r, sc),
      sumCls: sc === 0 ? 'card big' : 'card big hide',
      sumDetCls: sc === 0 ? 'line' : 'line hide',
      detCls: sc === 0 ? 'card big hide' : 'card big',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击或点头执行）'
    };
    for (var i = 0; i < ACTS.length; i++) upd['cls' + i] = (i === this._focus) ? 'banner' : 'banner ghost';
    this.setData(upd);
  },
  _report() {
    const r = loadResults();
    const s = this._summary(r);
    log('result', '', [s.storage || 'storage:-', s.gesture || 'gesture:-', s.heading || 'heading:-', s.timing || 'timing:-'].join(' | '));
    flushLog();
  },
  nextScreen() { this._screen = ((this._screen || 0) + 1) % 5; this.setData({ evt: 'EVT: screen ' + (this._screen + 1) + '/5 ' + SCREEN_NAMES[this._screen] }); this._render(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) { this._render(); this._report(); this.setData({ evt: 'EVT: refreshed' }); }
    else if (this._focus === 1) this.nextScreen();
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    // 按键一律以 event.code 为准：真机 event.key 不可靠且会遮蔽 code（v1.0.1 修复）。
    var code = (event && event.code) || '';
    if (!code && event && event.key) code = event.key;
    if (code === 'Enter' || code === 'GlobalHook') this.doAct();
    else if (code === 'ArrowUp') this.moveTap(-1);
    else if (code === 'ArrowDown') this.moveTap(1);
    else if (code === 'Backspace') this.backTap();
  },
  onKeyUp(event) {
    var code = (event && event.code) || '';
    if (!code && event && event.key) code = event.key;
    if ((code === 'Enter' || code === 'GlobalHook' || code === 'ArrowUp' || code === 'ArrowDown') && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="title">结果单</text>
    <text class="status">{{status}}</text>
    <text class="line dim">{{screenLine}}</text>
    <view class="{{sumCls}}">
      <text class="bline">{{storageBig}}</text>
      <text class="bline">{{gestureBig}}</text>
      <text class="bline">{{headingBig}}</text>
      <text class="bline">{{timingBig}}</text>
    </view>
    <text class="{{sumDetCls}}">{{detailLine}}</text>
    <view class="{{detCls}}">
      <text class="bline">{{detTitle}}</text>
      <text class="detbody">{{detBody}}</text>
    </view>
    <button class="{{cls0}}" bindtap="actTap" data-idx="0">刷新</button>
    <button class="{{cls1}}" bindtap="actTap" data-idx="1">明细下一屏</button>
    <button class="{{cls2}}" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <view class="foot-row">
      <text class="foot">{{evt}} · 结果存本机，关掉重开不丢</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 6px 8px; margin-top: 4px; }
.card.hide { display: none; }
.bline { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 19px; margin-top: 2px; }
.detbody { color: rgba(125,255,158,0.92); font-size: 12px; line-height: 17px; margin-top: 3px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.line.hide { display: none; }
.dim { color: rgba(64,255,94,0.55); }
.banner { color: #04140a; background-color: #40ff5e; padding: 4px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 4px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.foot-row { display: flex; flex-direction: row; align-items: center; justify-content: flex-end; margin-top: auto; padding-top: 3px; }
.foot { flex-grow: 1; color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; }
.ver { color: rgba(125,255,158,0.75); font-family: monospace; font-size: 10px; line-height: 12px; text-align: right; }
</style>
