<script def>
{
  "navigationBarTitleText": "Queue Roam"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '取号副线 — 主线是逛，副线替你盯着叫号：登记自己的号，far-field 守听叫号广播，路过看屏手动报进度，快到时叫你回去',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — 取号登记：点 NUM 切换到你的号，START 开始守听；路过看屏时点 PROG 报进度',
    bigLabel: '取号副线 · 待机',
    bigText: '未登记你的号',
    bigNote: 'NUM 切换你的号 · START 开始守听 · DEMO 走演示',
    permLine: 'PERM: RECORD_AUDIO — far-field 守听叫号广播 + ASR；模式只影响 getUserMedia 流，不改变宿主 ASR 的拾音',
    rows: [],
    countLine: '已听 0 段 · 快到提醒 0 次 · 叫到提醒 0 次 · 回去确认 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - register your ticket number, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | summary
    this._numList = ['A047', 'A052', 'B008', 'C120'];
    this._numIdx = -1; // -1 = unset
    this._progList = ['A040', 'A042', 'A044', 'A046'];
    this._progIdx = -1; // -1 = unset
    this._nearThreshold = 5;
    this._nearFiredFor = null; // progress value a near reminder already fired for
    this._banner = null; // null | 'near' | 'called'
    this._segments = 0;
    this._nearCount = 0;
    this._calledCount = 0;
    this._confirmedCount = 0;
    this._events = []; // { label, text } — near/called records only, session memory
    this._startAt = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 listening, 2 non-hit, 3 near, 4 called, 5 summary
    this._focus = 0;
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: number, progress, events
    // and counts die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up -
    // that IS the design. Close the agent and the queue is gone.
    this._mode = 'idle';
    this._numIdx = -1;
    this._progIdx = -1;
    this._nearFiredFor = null;
    this._banner = null;
    this._segments = 0;
    this._nearCount = 0;
    this._calledCount = 0;
    this._confirmedCount = 0;
    this._events = [];
    this._startAt = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this._focus = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _elapsedText() {
    if (!this._startAt) return '第0分钟';
    var m = Math.floor((this._now() - this._startAt) / 60000);
    return '第' + (m + 1) + '分钟';
  },

  _myNum() {
    return this._numIdx >= 0 ? this._numList[this._numIdx] : null;
  },

  _myNumDisplay() {
    var n = this._myNum();
    if (!n) return null;
    return this._demo ? n + '（DEMO 示例）' : n;
  },

  _progress() {
    return this._progIdx >= 0 ? this._progList[this._progIdx] : null;
  },

  // Gap = your number minus the reported progress, only when
  // both share the same letter prefix. This is arithmetic on
  // two strings you supplied, not a queue system: the official
  // call is still whatever the screen and the broadcast say.
  _gap() {
    var mine = this._myNum();
    var prog = this._progress();
    if (!mine || !prog) return null;
    if (mine.charAt(0) !== prog.charAt(0)) return null;
    var a = parseInt(mine.slice(1), 10);
    var b = parseInt(prog.slice(1), 10);
    if (isNaN(a) || isNaN(b)) return null;
    return a - b;
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (only nod is documented)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod switches the
    // ticket number (idle — cycling to your number), confirms
    // going back when a near/called banner is on screen
    // (listening), or confirms the summary. A nod never starts
    // listening on its own and never reports screen progress:
    // progress is a manual report, not a head gesture.
    if (this._mode === 'idle') { this.numTap(); return; }
    if (this._mode === 'listening' && this._banner) { this.checkTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored here - NUM switches your number, CHECK confirms going back when reminded' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.numTap();
      else if (this._mode === 'listening' && this._banner) this.checkTap();
      else if (this._mode === 'summary') this._confirmSummary();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.backTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- registration & listening ----------

  numTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: NUM refused - your number is registered before START, not mid-roam' });
      return;
    }
    this._numIdx = (this._numIdx + 1) % this._numList.length;
    this.setData({
      status: '你的号已设为 ' + this._myNum() + ' — START 开始守听',
      lastEvent: 'EVT: ticket number set - ' + this._myNum()
    });
    this._renderAll();
  },

  progTap() {
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: PROG refused - progress is reported while listening, not in idle or summary' });
      return;
    }
    this._progIdx = (this._progIdx + 1) % this._progList.length;
    this.setData({
      status: '当前叫到已报为 ' + this._progress() + ' — 路过看屏时再点 PROG 更新',
      lastEvent: 'EVT: progress reported - ' + this._progress()
    });
    this._checkNear();
    this._renderAll();
  },

  _checkNear() {
    // Near / reached checks run only on a manual progress
    // report, never on a broadcast segment: a misheard number
    // in ASR must not move the progress or fire a reminder.
    if (this._mode !== 'listening') return;
    if (this._banner === 'called') return;
    var gap = this._gap();
    if (gap === null) return;
    var prog = this._progress();
    if (gap === 0) {
      this._calledCount++;
      this._banner = 'called';
      this._events.push({ label: this._elapsedText(), text: '进度报到你的号 ' + this._myNum() + ' — 到你了' });
      this._focus = this._events.length - 1;
      this._speakText('到你了，马上回去');
      this.setData({
        status: '到你了！进度已报到你的号 — 马上回去，CHECK 确认回去',
        lastEvent: 'EVT: progress reached your number - called (called ' + this._calledCount + ')'
      });
      return;
    }
    if (gap > 0 && gap <= this._nearThreshold && this._nearFiredFor !== prog) {
      this._nearFiredFor = prog;
      this._nearCount++;
      this._banner = 'near';
      this._events.push({ label: this._elapsedText(), text: '快到提醒 · 当前叫到 ' + prog + ' · 距你还有 ' + gap + ' 号' });
      this._focus = this._events.length - 1;
      this._speakText('快到你了，回去等着');
      this.setData({
        status: '快到你了 — 当前叫到 ' + prog + '，距你还有 ' + gap + ' 号，CHECK 确认回去',
        lastEvent: 'EVT: near reminder (near ' + this._nearCount + ') - gap ' + gap
      });
    }
  },

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - listening is already under way or finished' });
      return;
    }
    if (!this._myNum()) {
      this.setData({ lastEvent: 'EVT: START refused - missing: 你的号（NUM 切换）' });
      return;
    }
    this._mode = 'listening';
    this._startAt = this._now();
    this._focus = 0;
    this.setData({
      status: '守听逛街中 — far-field 守听叫号广播，只认你的号；路过看屏时点 PROG 报进度',
      lastEvent: 'EVT: listening started (ticket ' + this._myNum() + ')'
    });
    this._renderAll();
  },

  // ---------- call-number gate ----------

  _onSegment(text) {
    // The gate: one ASR transcript segment in, one decision out.
    // A hit is ONLY the segment calling your own number: it
    // banners hard, speaks once ("到你了，马上回去"), and is
    // recorded as an event. Any other segment — including a
    // broadcast calling somebody else's number — moves only
    // the counter: the sentence is discarded here and stored
    // nowhere, and it never moves the progress. Progress moves
    // only when you report it by hand at the screen.
    if (this._mode !== 'listening') return;
    var seg = String(text || '');
    this._segments++;
    var m = seg.match(/[A-Z]\d{3}/);
    var called = m ? m[0] : null;
    if (called !== this._myNum()) {
      this.setData({ lastEvent: 'EVT: segment ' + this._segments + ' - not your number, counted only, discarded' });
      this._renderAll();
      return;
    }
    this._calledCount++;
    this._banner = 'called';
    this._events.push({ label: this._elapsedText(), text: seg + ' — 叫到你的号' });
    this._focus = this._events.length - 1;
    this._speakText('到你了，马上回去');
    this.setData({
      status: '到你了！广播叫到你的号 ' + this._myNum() + ' — 马上回去，CHECK 确认回去',
      lastEvent: 'EVT: segment ' + this._segments + ' HIT your number ' + called + ' - called (called ' + this._calledCount + ')'
    });
    this._renderAll();
  },

  checkTap() {
    if (this._mode === 'listening' && this._banner) {
      this._confirmedCount++;
      this._banner = null;
      this._speakText('回去已确认');
      this.setData({
        status: '回去已确认 — 继续逛，守听仍在进行',
        lastEvent: 'EVT: going back confirmed (confirmed ' + this._confirmedCount + ')'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'summary') {
      this._confirmSummary();
      return;
    }
    this.setData({ lastEvent: 'EVT: CHECK refused here - no near/called banner to confirm; NUM switches your number, PROG reports progress' });
  },

  endTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: END refused - a summary is already open' });
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - no roam is under way' });
      return;
    }
    this._mode = 'summary';
    this._summary = {
      segments: this._segments,
      near: this._nearCount,
      called: this._calledCount,
      confirmed: this._confirmedCount,
      myNum: this._myNum(),
      progress: this._progress(),
      events: this._events.length
    };
    this.setData({
      status: '本次取号小结 — 确认后清空本次记录',
      lastEvent: 'EVT: roam ended - summary ready (segments ' + this._segments + ', near ' + this._nearCount + ', called ' + this._calledCount + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._numIdx = -1;
    this._progIdx = -1;
    this._nearFiredFor = null;
    this._banner = null;
    this._segments = 0;
    this._nearCount = 0;
    this._calledCount = 0;
    this._confirmedCount = 0;
    this._events = [];
    this._startAt = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this._focus = 0;
    this.setData({
      status: '取号副线 — 主线是逛，副线替你盯着叫号：登记自己的号，far-field 守听叫号广播，路过看屏手动报进度，快到时叫你回去',
      lastEvent: 'EVT: summary confirmed - roam cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to listening without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'listening';
      this._summary = null;
      this.setData({
        status: '守听逛街中 — far-field 守听叫号广播，只认你的号；路过看屏时点 PROG 报进度',
        lastEvent: 'EVT: back to listening - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins listening, END opens the summary' });
  },

  _focusLen() {
    if (this._mode === 'idle') return 2;
    return this._events.length;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._focusLen()) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = this._myNum()
        ? '已登记：你的号 ' + this._myNum() + '，点开始守听'
        : '还没登记：你的号，NUM 切换你的号';
    } else if (this._mode === 'listening') {
      if (this._banner === 'called') {
        line = '到你了，马上回去';
      } else if (this._banner === 'near') {
        line = '快到你了，回去等着';
      } else {
        line = '守听进行中，已听 ' + this._segments + ' 段，当前叫到 ' + (this._progress() || '未更新');
      }
    } else if (this._summary) {
      line = '本次取号小结：你的号 ' + this._summary.myNum + '，快到提醒 ' + this._summary.near + ' 次，叫到提醒 ' + this._summary.called + ' 次';
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user roam is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._numIdx >= 0 || this._progIdx >= 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user registration is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._numIdx = 0; // A047 (DEMO sample)
      this.startTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - ticket A047 registered (DEMO sample), listening started' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onSegment('请 A030 号到 2 号窗口');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - non-hit segment counted only (segments 1, called 0)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      // Two manual progress reports: A040 (gap 7, silent) then
      // A042 (gap 5, near reminder fires once). Progress is
      // reported by hand at the screen in the demo, exactly as
      // a user would report it — no broadcast segment moves it.
      this._demoStage = 3;
      this.progTap();
      this.progTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - near reminder on screen (progress A042, gap 5, near 1)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._onSegment('请 A047 号到 1 号窗口');
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - HIT your number A047, called banner on (segments 2, called 1)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      if (this._banner) this.checkTap();
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary (segments 2, near 1, called 1, confirmed 1, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, n;
    if (this._mode === 'idle') {
      rows.push({
        idx: 0,
        name: '登记1 · 你的号',
        detail: this._myNumDisplay() ? this._myNumDisplay() : '未登记（点 NUM 切换到你的号）',
        flag: this._myNum() ? '✓' : '○',
        cls: 'row'
      });
      rows.push({
        idx: 1,
        name: '登记2 · 当前叫到',
        detail: this._progress() ? this._progress() : '未更新（路过看屏时点 PROG 报数）',
        flag: this._progress() ? '✓' : '○',
        cls: 'row'
      });
    } else if (this._events.length === 0) {
      rows.push({
        idx: 0,
        name: '守听中',
        detail: '暂无叫号记录 — 非本人号只计数不存，进度只靠你手动报',
        flag: '◎',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._events.length; i++) {
        n = this._events[i];
        rows.push({
          idx: i,
          name: '记录' + (i + 1) + ' · ' + n.label,
          detail: n.text,
          flag: '✓',
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    patch.countLine = '已听 ' + this._segments + ' 段 · 快到提醒 ' + this._nearCount + ' 次' +
      ' · 叫到提醒 ' + this._calledCount + ' 次 · 回去确认 ' + this._confirmedCount + ' 次' +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — 取号登记：点 NUM 切换到你的号，START 开始守听；路过看屏时点 PROG 报进度';
      patch.bigLabel = '取号副线 · 待机';
      patch.bigText = this._myNumDisplay() ? '已登记：' + this._myNum() : '未登记你的号';
      patch.bigNote = this._myNum()
        ? '你的号 ' + this._myNum() + ' · START 开始守听 · DEMO 走演示'
        : 'NUM 切换你的号 · START 开始守听 · DEMO 走演示';
    } else if (this._mode === 'listening') {
      if (this._banner === 'called') {
        patch.boxLabel = '◎ 到你了！广播叫到你的号 — 马上回去，CHECK 确认回去';
        patch.bigLabel = '到你了';
        patch.bigText = '到你了！';
        patch.bigNote = '你的号 ' + this._myNum() + ' · 当前叫到 ' + (this._progress() || '未更新') + ' · CHECK 确认回去';
      } else if (this._banner === 'near') {
        var gap = this._gap();
        patch.boxLabel = '◎ 快到你了 — 当前叫到 ' + (this._progress() || '未更新') + '，距你还有 ' + gap + ' 号，CHECK 确认回去';
        patch.bigLabel = '快到你了';
        patch.bigText = '距你还有 ' + gap + ' 号';
        patch.bigNote = '你的号 ' + this._myNum() + ' · 当前叫到 ' + this._progress() + ' · CHECK 确认回去';
      } else {
        patch.boxLabel = '◎ 守听逛街中 — far-field 守听叫号广播，只认你的号';
        patch.bigLabel = '守听逛街中';
        patch.bigText = '已听 ' + this._segments + ' 段';
        patch.bigNote = '你的号 ' + this._myNum() + ' · 当前叫到 ' + (this._progress() || '未更新') + ' · 非本人号只计数不存';
      }
    } else {
      patch.boxLabel = '◎ 本次取号小结';
      patch.bigLabel = '本次取号小结';
      var s = this._summary || { segments: 0, near: 0, called: 0, confirmed: 0, myNum: '', progress: null, events: 0 };
      patch.bigText = '叫到提醒 ' + s.called + ' 次';
      patch.bigNote = '你的号 ' + s.myNum + ' · 最终进度 ' + (s.progress || '未更新') + ' · 已听 ' + s.segments + ' 段 · 快到提醒 ' + s.near + ' 次 · 回去确认 ' + s.confirmed + ' 次 · 确认后清空本次记录';
    }
    patch.bigCls = this._bigClsFor(patch.bigText);
    this.setData(patch);
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">QUEUE ROAM v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{permLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="demoTap">DEMO</button>
      <button class="btn btn-main" bindtap="numTap">NUM</button>
      <button class="btn btn-main" bindtap="progTap">PROG</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn btn-main" bindtap="checkTap">CHECK</button>
      <button class="btn" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="prevTap">PREV</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">没有读屏：叫号屏进度只能由你路过时点 PROG 手动报数，Agent 不读屏幕、没有 OCR；没有说话人识别：叫号判定只对 ASR 转写文本做号段匹配，ASR 听错号就可能漏报/误报；号的差距只是登记号与手动进度相减的算术，不是官方排队系统——官方叫号仍以现场屏/广播为准；收音模式只影响 getUserMedia 流的拾音、不改变宿主 ASR 的拾音；本次取号数据只存会话内存，关掉即清；far-field 守听中，非本人号只计数、判定即丢弃</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 2px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 1px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.biglabel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.bignum {
  color: #40ff5e;
  font-size: 34px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-sm {
  color: #40ff5e;
  font-size: 24px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-xs {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 1px;
}
.bignote {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 2px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 1px;
  font-size: 11px;
  font-weight: 500;
  line-height: 16px;
  text-align: center;
}
.btn-main {
  color: #40ff5e;
  border-color: rgba(64,255,94,0.72);
  background-color: rgba(64,255,94,0.12);
}
.list {
  flex-shrink: 0;
  height: 80px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-right: 8px;
}
.rdetail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 15px;
  flex-grow: 1;
}
.rflag {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 12px;
}
</style>
