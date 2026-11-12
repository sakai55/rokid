<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults, saveResults } from '../../judge.js';
import { fail } from '../../err.js';
import { log, flushLog } from '../../logq.js';

// 首页：四站入口 + 结果单 + 设置自检，并显示上次结果摘要。
// 本探针为真境漫游阶段 1 采集真机事实，不占正式游戏本体、不提审。
const MENU = ['存储探针', '手势探针', '朝向探针', '判定耗时', '结果单', '设置 / 自检'];
const URLS = ['/pages/storage/index', '/pages/gesture/index', '/pages/heading/index', '/pages/timing/index', '/pages/result/index', '/pages/settings/index'];

// —— v1.0.3 信号自动探测序列（GO 指令：不用用户操作，点头直接逐个探测）——
// 选择通道本身正是坏掉待测的部分，所以诊断不能依赖任何菜单选择：
// 待机点一次头（或进页 5 秒无 nod 自动开始）→ 五项逐项开窗探测 →
// 自动汇总屏 → 自动结果图逐帧循环。全程自动：每项 6 秒硬超时、
// 全局看门狗兜底、内部出错记裸码跳下一项，序列永远走到汇总与结果图。
const STEPS = [
  { name: '点头', prompt: '请点一次头', expect: 'ges' },
  { name: '下滑', prompt: '请下滑一次（镜腿向前滑）', expect: 'key' },
  { name: '上滑', prompt: '请上滑一次（镜腿向后滑）', expect: 'key' },
  { name: '单击', prompt: '请单击一次镜腿', expect: 'key' },
  { name: '双击', prompt: '请双击一次镜腿', expect: 'key' }
];
const WIN_MS = 6000;          // 每项窗口
const AUTO_MS = 5000;         // 进页无 nod 自动开始
const SUM_MS = 10000;         // 汇总屏停留后自动进结果图
const FRM_MS = 10000;         // 结果图每帧停留
const FRM_LINES = 16;         // 结果图每帧最多列多少条事件
const EVT_CAP = 60;           // 每项最多记多少条事件（防落盘膨胀，超限标记 trunc）
const VER = 'v1.0.3';

export default {
  data: {
    status: '真境探针：四站测完，结果汇成一张结果单',
    sumLine: '上次结果：还没有任何记录',
    cls0: 'banner', cls1: 'banner ghost', cls2: 'banner ghost', cls3: 'banner ghost', cls4: 'banner ghost', cls5: 'banner ghost',
    keyLine: 'KEY: (还没收到按键)',
    gesLine: 'GES: (无)',
    evt: 'EVT: ready',
    ver: VER,
    idleCls: 'sec', runCls: 'sec hide', sumCls: 'sec hide', frmCls: 'sec hide',
    lastDiag: '',
    seqPrompt: '', seqState: '', seqCount: '', doneHead: '', doneList: '',
    sumBody: '',
    frmLabel: '', frmHead: '', frmBody: '', frmState: ''
  },
  onLoad() {
    this._focus = 0;
    this._stage = 'idle';       // idle | run | sum | frames
    this._step = 0;
    this._bucket = [];
    this._diagItems = [];
    this._frames = [];
    this._frmIdx = 0;
    this._frmPaused = false;
  },
  onShow() { this._render(); this._armAuto(); },
  onHide() { this._abortSeq(); this._clearTimer('_autoTimer'); this._clearTimer('_sumTimer'); this._clearTimer('_frmTimer'); },
  onUnload() { this._clearTimer('_autoTimer'); this._clearTimer('_tickTimer'); this._clearTimer('_transTimer'); this._clearTimer('_watchTimer'); this._clearTimer('_sumTimer'); this._clearTimer('_frmTimer'); },
  _render() {
    const r = loadResults();
    const parts = [];
    parts.push(r.storage ? '存储 已测' : '存储 未测');
    const gt = (r.gesture && r.gesture.trials) || [];
    parts.push('手势 ' + gt.filter(function (t) { return t && t.truth; }).length + '/10 已标真值');
    const ht = (r.heading && r.heading.trials) || [];
    parts.push('朝向 ' + ht.length + '/4 向');
    const tr = (r.timing && r.timing.runs) || [];
    parts.push('判定 ' + tr.length + '/3 次');
    const upd = { sumLine: '进度：' + parts.join(' · ') };
    for (var i = 0; i < MENU.length; i++) upd['cls' + i] = (i === this._focus) ? 'banner' : 'banner ghost';
    const dg = r.diag;
    if (dg && dg.items && dg.items.length) {
      upd.lastDiag = '上次信号探测：' + dg.items.map(function (it) { return it.name + (it.ok ? '✓' : '✗'); }).join(' ');
    } else upd.lastDiag = '';
    this.setData(upd);
  },
  _show(stage) {
    this._stage = stage;
    this.setData({
      idleCls: stage === 'idle' ? 'sec' : 'sec hide',
      runCls: stage === 'run' ? 'sec' : 'sec hide',
      sumCls: stage === 'sum' ? 'sec' : 'sec hide',
      frmCls: stage === 'frames' ? 'sec' : 'sec hide'
    });
  },
  goTap(i) {
    if (i >= URLS.length) { try { wx.navigateBack({}); } catch (e) {} return; }
    try { wx.navigateTo({ url: URLS[i] }); }
    catch (e) { fail('E8001', e); this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { this.goTap(this._focus); },
  moveTap(d) { this._focus = (this._focus + d + MENU.length) % MENU.length; this.setData({ evt: 'EVT: focus ' + MENU[this._focus] }); this._render(); },

  // —— v1.0.2 原始事件探头（只记录、不判断、不拦截，全态保留）——
  // 返回 dump 字符串，序列记录与日志上报共用同一份原文。
  _probeKey(dir, event) {
    var e = event || {};
    var f = function (v) { return (v === undefined || v === null || v === '') ? '-' : String(v); };
    var kc = (e.keyCode !== undefined && e.keyCode !== null) ? e.keyCode : e.which;
    var s = 'KEY ' + dir + ' code=' + f(e.code) + ' key=' + f(e.key) + ' kc=' + f(kc);
    this.setData({ keyLine: s });
    log('key', '', s);
    return s;
  },
  _probeGes(event) {
    var d = (event && event.detail) || event || {};
    var f = function (v) { return (v === undefined || v === null || v === '') ? '-' : String(v); };
    var s = 'GES gesture=' + f(d.gesture) + ' type=' + f(d.type);
    this.setData({ gesLine: s });
    log('ges', '', s);
    return s;
  },

  // —— 自动探测序列状态机 ——
  _clearTimer(name) { if (this[name]) { clearTimeout(this[name]); clearInterval(this[name]); this[name] = null; } },
  _armAuto() {
    this._clearTimer('_autoTimer');
    if (this._stage !== 'idle') return;
    var self = this;
    this._autoTimer = setTimeout(function () {
      self._autoTimer = null;
      if (self._stage === 'idle') self._startSeq(null);
    }, AUTO_MS);
  },
  _startSeq(firstGesDump) {
    this._clearTimer('_autoTimer');
    this._clearTimer('_sumTimer');
    this._clearTimer('_frmTimer');
    this._clearTimer('_transTimer');
    this._diagItems = [];
    this._step = 0;
    this._accepting = false;
    this.setData({ doneHead: '', doneList: '' });
    this._show('run');
    log('diag-start', '', firstGesDump ? 'by-nod' : 'auto');
    var self = this;
    // 全局看门狗：五项窗口总时长 + 余量内没走到汇总，就强制收尾，
    // 缺的项记 ✗ 未完成——序列不许死在半路。
    this._watchTimer = setTimeout(function () {
      self._watchTimer = null;
      if (self._stage === 'run') { try { self._forceFinish(); } catch (e) { fail('E9001', e); } }
    }, WIN_MS * STEPS.length + 20000);
    try { this._beginStep(firstGesDump || null); }
    catch (e) { fail('E9001', e); this._forceFinish(); }
  },
  _beginStep(preDump) {
    // 隔离纪律：开新项前先清空本项缓冲与状态，上一项的计时已在
    // _closeStep 停干净；捕获闸门 _accepting 只在本项窗口内打开，
    // 过渡屏期间的事件不记进任何一项，项与项互不污染。
    this._bucket = [];
    this._bucketTrunc = false;
    this._stepErr = '';
    this._winStart = Date.now();
    this._left = Math.round(WIN_MS / 1000);
    this._accepting = true;
    var st = STEPS[this._step];
    this.setData({
      seqPrompt: '第 ' + (this._step + 1) + '/5 项 · ' + st.prompt,
      seqState: '状态：记录中 · 剩余 ' + this._left + ' 秒',
      seqCount: '已收到 0 个信号'
    });
    if (preDump) this._recEvent('ges', preDump, 0);
    var self = this;
    this._clearTimer('_tickTimer');
    this._tickTimer = setInterval(function () {
      try {
        self._left -= 1;
        if (self._left <= 0) { self._closeStep(); return; }
        self.setData({ seqState: '状态：记录中 · 剩余 ' + self._left + ' 秒' });
      } catch (e) { self._stepErr = 'E9001'; fail('E9001', e); try { self._closeStep(); } catch (e2) {} }
    }, 1000);
  },
  _recEvent(kind, dump, relForce) {
    if (this._stage !== 'run' || !this._accepting) return;
    var rel = (typeof relForce === 'number') ? relForce : (Date.now() - this._winStart);
    if (this._bucket.length < EVT_CAP) this._bucket.push({ t: rel, kind: kind, dump: dump });
    else this._bucketTrunc = true;
    // 全量回传：窗口内每一个事件逐条上报（含相对时刻），不只报第一条。
    log('diag-ev', '', 'item=' + (this._step + 1) + ' t=+' + rel + 'ms ' + dump);
    this.setData({ seqCount: '已收到 ' + this._bucket.length + ' 个信号' });
  },
  _closeStep() {
    // 先关捕获闸门、停本项计时，再结算落盘上报——本项到此封口，
    // 之后（含过渡屏期间）的事件与本项无关。回传 flush 只在本项
    // 窗口结束后的这一刻发，不与捕获抢跑道（log() 本身只入本地
    // 队列、不发送，见 logq.js）。
    this._accepting = false;
    this._clearTimer('_tickTimer');
    var st = STEPS[this._step];
    var exp = st.expect;
    var firstExp = '', firstAny = '';
    for (var i = 0; i < this._bucket.length; i++) {
      if (!firstAny) firstAny = this._bucket[i].dump;
      if (this._bucket[i].kind === exp && !firstExp) firstExp = this._bucket[i].dump;
    }
    var item = {
      name: st.name,
      ok: !!firstExp,
      n: this._bucket.length,
      first: firstExp || firstAny || '',
      events: this._bucket,
      trunc: !!this._bucketTrunc,
      err: this._stepErr || ''
    };
    this._diagItems.push(item);
    log('diag-' + (this._step + 1), '', st.name + ' ' + (item.err ? ('ERR ' + item.err) : (item.ok ? 'OK' : 'NONE')) + ' n=' + item.n + ' first=' + (item.first || '-'));
    flushLog();
    this._saveDiag();
    this._renderDone();
    this._step += 1;
    if (this._step < STEPS.length) this._scheduleNext();
    else this._finishSeq();
  },
  _renderDone() {
    // 状态区里的已完成列表：随跑随长，每项一行（出错带裸码）。
    var lines = [];
    for (var i = 0; i < this._diagItems.length; i++) {
      var it = this._diagItems[i];
      lines.push('第' + (i + 1) + '项 ' + it.name + ' ' + (it.err ? ('出错 ' + it.err + ' 已跳过') : (it.ok ? '✓ 已完成 · 收到 ' + it.n + ' 个' : '✗ 无信号')));
    }
    this.setData({ doneHead: lines.length ? '已完成：' : '', doneList: lines.join('\n') });
  },
  _scheduleNext() {
    // 过渡屏（约 1 秒）：上一项已封口，下一项还没开窗，节奏可辨。
    var st = STEPS[this._step];
    this.setData({
      seqPrompt: '下一项：第 ' + (this._step + 1) + '/5 项 · ' + st.prompt,
      seqState: '状态：等待中',
      seqCount: ''
    });
    var self = this;
    this._clearTimer('_transTimer');
    this._transTimer = setTimeout(function () {
      self._transTimer = null;
      if (self._stage !== 'run') return;
      try { self._beginStep(null); }
      catch (e) {
        fail('E9001', e);
        self._diagItems.push({ name: STEPS[self._step].name, ok: false, n: 0, first: '', events: [], err: 'E9001' });
        self._saveDiag();
        self._renderDone();
        self._step += 1;
        if (self._step < STEPS.length) self._scheduleNext();
        else self._finishSeq();
      }
    }, 1000);
  },
  _forceFinish() {
    // 看门狗收尾：当前项（仅当捕获闸门还开着）按已捕获的收掉，
    // 其余项记未完成，直接进汇总。
    this._clearTimer('_tickTimer');
    this._clearTimer('_transTimer');
    if (this._stage !== 'run') return;
    if (this._accepting && this._diagItems.length === this._step) {
      this._accepting = false;
      var st = STEPS[this._step];
      var firstExp = '', firstAny = '';
      for (var i = 0; i < this._bucket.length; i++) {
        if (!firstAny) firstAny = this._bucket[i].dump;
        if (this._bucket[i].kind === st.expect && !firstExp) firstExp = this._bucket[i].dump;
      }
      this._diagItems.push({ name: st.name, ok: !!firstExp, n: this._bucket.length, first: firstExp || firstAny || '', events: this._bucket, trunc: !!this._bucketTrunc });
      this._step += 1;
    }
    while (this._step < STEPS.length) {
      this._diagItems.push({ name: STEPS[this._step].name, ok: false, n: 0, first: '', events: [], skipped: true });
      this._step += 1;
    }
    this._finishSeq();
  },
  _saveDiag() {
    var r = loadResults();
    r.diag = { at: new Date().toISOString(), items: this._diagItems };
    saveResults(r);
  },
  _finishSeq() {
    this._clearTimer('_tickTimer');
    this._clearTimer('_transTimer');
    this._clearTimer('_watchTimer');
    this._accepting = false;
    this._saveDiag();
    var marks = this._diagItems.map(function (it) { return it.name + (it.ok ? '✓' : '✗'); }).join(' ');
    log('diag-summary', '', marks);
    flushLog();
    var lines = [];
    for (var i = 0; i < this._diagItems.length; i++) {
      var it = this._diagItems[i];
      lines.push('第' + (i + 1) + '项 ' + it.name + (it.err ? ' ✗ 出错 ' + it.err + '（已跳过）' : (it.ok ? ' ✓ 收到 ' + it.n + ' 个信号' : (it.skipped ? ' ✗ 未完成（看门狗跳过）' : ' ✗ 无信号'))));
      lines.push('  ' + (it.first || '（窗口内零事件）'));
    }
    this.setData({ sumBody: lines.join('\n') });
    this._buildFrames();
    this._show('sum');
    this._render();
    var self = this;
    this._clearTimer('_sumTimer');
    this._sumTimer = setTimeout(function () {
      self._sumTimer = null;
      if (self._stage === 'sum') self._enterFrames();
    }, SUM_MS);
  },
  _abortSeq() {
    // 页面被切走时停掉序列计时，回到待机，免得后台自走。
    if (this._stage !== 'run') return;
    this._accepting = false;
    this._clearTimer('_tickTimer');
    this._clearTimer('_transTimer');
    this._clearTimer('_watchTimer');
    this._show('idle');
  },

  // —— 结果图：逐帧摆满屏供截屏入相册 ——
  // 媒体库写入只有权限名、没有官方文档化的保存 API（能力注册表
  // §5 第 12 条未明），Agent 不能自己把图写进相册；结果图就是把
  // 每一项的全部事件逐条摆满屏，用户截屏后经手机 App 落相册。
  _buildFrames() {
    var frames = [];
    for (var i = 0; i < this._diagItems.length; i++) {
      var it = this._diagItems[i];
      var head = '第' + (i + 1) + '项 ' + it.name + '：' + (it.err ? '✗ 出错 ' + it.err + '（已跳过）· 已捕获 ' + it.n + ' 个信号' : (it.ok ? '✓ 收到 ' + it.n + ' 个信号' : (it.skipped ? '✗ 未完成（看门狗跳过）' : '✗ 无信号（窗口内零事件）')));
      var lines = [];
      for (var j = 0; j < it.events.length; j++) lines.push('+' + it.events[j].t + 'ms ' + it.events[j].dump);
      if (!lines.length) lines.push('（窗口内零事件）');
      if (it.trunc) lines.push('（事件超 ' + EVT_CAP + ' 条上限，后段已截断）');
      for (var k = 0; k < lines.length; k += FRM_LINES) {
        frames.push({ item: i, head: head + (k > 0 ? '（续）' : ''), lines: lines.slice(k, k + FRM_LINES) });
      }
    }
    this._frames = frames;
  },
  _enterFrames() {
    if (!this._frames.length) this._buildFrames();
    this._frmIdx = 0;
    this._frmPaused = false;
    this._frmLeft = Math.round(FRM_MS / 1000);
    this._show('frames');
    this._renderFrame();
    var self = this;
    this._clearTimer('_frmTimer');
    this._frmTimer = setInterval(function () {
      try {
        if (self._frmPaused) return;
        self._frmLeft -= 1;
        if (self._frmLeft <= 0) {
          self._frmIdx = (self._frmIdx + 1) % self._frames.length;
          self._frmLeft = Math.round(FRM_MS / 1000);
          self._renderFrame();
        } else self._renderFrameState();
      } catch (e) { fail('E9001', e); }
    }, 1000);
  },
  _renderFrame() {
    var f = this._frames[this._frmIdx];
    if (!f) return;
    this.setData({
      frmLabel: '结果图 ' + (this._frmIdx + 1) + '/' + this._frames.length + ' · 第' + (f.item + 1) + '项 ' + STEPS[f.item].name + ' · ' + VER,
      frmHead: f.head,
      frmBody: f.lines.join('\n')
    });
    this._renderFrameState();
  },
  _renderFrameState() {
    this.setData({ frmState: this._frmPaused ? '已暂停 · 点头继续 · 双击退出' : ('还剩 ' + this._frmLeft + ' 秒下一帧 · 点头暂停 · 双击退出') });
  },

  // —— 输入分工（按态分流）——
  onHeadGesture(event) {
    var dump = this._probeGes(event);
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || '';
    if (this._stage === 'run') { this._recEvent('ges', dump); return; }
    if (g !== 'nod') return;
    if (this._stage === 'idle') this._startSeq(dump);
    else if (this._stage === 'sum') { this._clearTimer('_sumTimer'); this._startSeq(dump); }
    else if (this._stage === 'frames') {
      this._frmPaused = !this._frmPaused;
      if (!this._frmPaused) this._frmLeft = Math.round(FRM_MS / 1000);
      this._renderFrameState();
    }
  },
  onKeyDown(event) {
    var dump = this._probeKey('down', event);
    if (this._stage === 'run') { this._recEvent('key', dump); return; }
    if (this._stage !== 'idle') return;   // sum / frames 态不拦截：双击 Backspace 走宿主默认退出
    // 按键一律以 event.code 为准：真机 event.key 不可靠且会遮蔽 code
    // （v1.0.0 因此滑动/单击全灭，见 README Change Log 1.0.1）。
    var code = (event && event.code) || '';
    if (!code && event && event.key) code = event.key;
    if (code === 'Enter' || code === 'GlobalHook') this.doAct();
    else if (code === 'ArrowUp') this.moveTap(-1);
    else if (code === 'ArrowDown') this.moveTap(1);
    else if (code === 'Backspace') { try { wx.navigateBack({}); } catch (e) {} }
  },
  onKeyUp(event) {
    var dump = this._probeKey('up', event);
    var code = (event && event.code) || '';
    if (!code && event && event.key) code = event.key;
    if (this._stage === 'run') {
      this._recEvent('key', dump);
      // 序列中挡下宿主默认动作（含 Backspace 返回），免得第 5 项双击把整轮带走。
      if ((code === 'Enter' || code === 'GlobalHook' || code === 'ArrowUp' || code === 'ArrowDown' || code === 'Backspace') && event.preventDefault) event.preventDefault();
      return;
    }
    if (this._stage !== 'idle') return;   // sum / frames 态不挡 Backspace，宿主默认退出要生效
    if ((code === 'Enter' || code === 'GlobalHook' || code === 'ArrowUp' || code === 'ArrowDown') && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="title">真境探针 · RealMUD</text>
    <text class="status">{{status}}</text>
    <view class="{{idleCls}}">
      <view class="card">
        <text class="line">用途：给真境漫游（第一人称现实 MUD）阶段 1 测四组数——存储能存多少、手势判定认得准不准、转头朝向误差多大、拍照判定一趟要多久。</text>
      </view>
      <button class="{{cls0}}" bindtap="actTap" data-idx="0">存储探针</button>
      <button class="{{cls1}}" bindtap="actTap" data-idx="1">手势探针（10 次）</button>
      <button class="{{cls2}}" bindtap="actTap" data-idx="2">朝向探针（4 向）</button>
      <button class="{{cls3}}" bindtap="actTap" data-idx="3">判定耗时（3 次）</button>
      <button class="{{cls4}}" bindtap="actTap" data-idx="4">结果单</button>
      <button class="{{cls5}}" bindtap="actTap" data-idx="5">设置 / 自检</button>
      <text class="bighint">点头开始逐个探测信号</text>
      <text class="line dim">{{sumLine}}</text>
      <text class="line dim">{{lastDiag}}</text>
    </view>
    <view class="{{runCls}}">
      <text class="seqprompt">{{seqPrompt}}</text>
      <text class="seqmeta">{{seqState}}</text>
      <text class="seqmeta">{{seqCount}}</text>
      <text class="seqmeta">{{doneHead}}</text>
      <text class="donelist">{{doneList}}</text>
      <text class="line dim">自动探测中：按提示做动作即可，不用做任何选择；逐项单独跑、按顺序跑。</text>
    </view>
    <view class="{{sumCls}}">
      <text class="seqprompt">信号探测汇总</text>
      <text class="sumbody">{{sumBody}}</text>
      <text class="line dim">点头再跑一轮 · 约 10 秒后自动显示结果图 · 双击退出</text>
    </view>
    <view class="{{frmCls}}">
      <text class="frmlabel">{{frmLabel}}</text>
      <text class="frmhead">{{frmHead}}</text>
      <text class="frmbody">{{frmBody}}</text>
      <text class="line dim">{{frmState}}</text>
    </view>
    <text class="line diag">{{keyLine}}</text>
    <text class="line diag">{{gesLine}}</text>
    <view class="foot-row">
      <text class="foot">{{evt}} · 探针（不提审）</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 5px 7px; margin-top: 4px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.diag { color: rgba(125,255,158,0.8); font-family: monospace; font-size: 10px; line-height: 12px; }
.banner { color: #04140a; background-color: #40ff5e; padding: 3px 4px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 3px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.bighint { color: #7dff9e; font-size: 16px; font-weight: 500; line-height: 20px; margin-top: 5px; }
.sec { display: flex; flex-direction: column; }
.sec.hide { display: none; }
.seqprompt { color: #7dff9e; font-size: 19px; font-weight: 500; line-height: 24px; margin-top: 10px; }
.seqmeta { color: rgba(125,255,158,0.88); font-size: 13px; line-height: 18px; margin-top: 4px; }
.donelist { color: rgba(125,255,158,0.75); font-family: monospace; font-size: 10px; line-height: 14px; margin-top: 2px; }
.sumbody { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 10px; line-height: 14px; margin-top: 6px; }
.frmlabel { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; margin-top: 4px; }
.frmhead { color: #40ff5e; font-size: 11px; line-height: 15px; margin-top: 3px; }
.frmbody { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 10px; line-height: 13px; margin-top: 3px; }
.foot-row { display: flex; flex-direction: row; align-items: center; justify-content: flex-end; margin-top: auto; padding-top: 3px; }
.foot { flex-grow: 1; color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; }
.ver { color: rgba(125,255,158,0.75); font-family: monospace; font-size: 10px; line-height: 12px; text-align: right; }
</style>
