<script def>
{
  "navigationBarTitleText": "Tour Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '跟团副线 — 主线是专心看景，副线替你听着导游的集合信息：集合点朝向登记 + 集合时间，far-field 守听只提集合句，快到点提醒归队',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — 集合点登记：看向集合点停稳点 REG，TIME 选集合时间，START 开始守听',
    bigLabel: '跟团副线 · 待机',
    bigText: '未登记集合点',
    bigNote: 'REG 登记朝向 · TIME 选集合时间 · START 开始守听 · DEMO 走演示',
    permLine: 'PERM: RECORD_AUDIO — far-field 守听 + ASR；模式只影响 getUserMedia 流，不改变宿主 ASR 的拾音',
    rows: [],
    countLine: '已听 0 段 · 集合命中 0 条 · 归队提醒 0 次 · 归队确认 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - register the meeting direction and time, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | summary
    this._dir = null; // registered meeting direction label
    this._times = ['15:00', '15:30', '16:00', '16:30'];
    this._timeIdx = -1; // -1 = unset
    this._keywords = ['集合', '出发', '上车', '点名', '集合点'];
    this._segments = 0;
    this._hits = 0;
    this._notes = []; // { label, text, kw } — meeting sentences only, session memory
    this._dueCount = 0;
    this._dueConfirmed = 0;
    this._dueFlash = false; // a due reminder is on screen, awaiting CHECK
    this._hitFlash = false; // last hit banner
    this._hitKw = '';
    this._dueStage = 0; // 0 none, 1 warned (10 min), 2 overdue
    this._deadline = 0;
    this._startAt = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 listening, 2 non-hit, 3 hit, 4 due, 5 summary
    this._focus = 0;
    this._nodLock = false;
    var self = this;
    try {
      this._ticker = setInterval(function () { self._tick(); }, 30000);
    } catch (e) { this._ticker = 0; }
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: direction, time, notes and
    // counts die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up -
    // that IS the design. Close the agent and the tour is gone.
    try { if (this._ticker) clearInterval(this._ticker); } catch (e) {}
    this._mode = 'idle';
    this._dir = null;
    this._timeIdx = -1;
    this._segments = 0;
    this._hits = 0;
    this._notes = [];
    this._dueCount = 0;
    this._dueConfirmed = 0;
    this._dueFlash = false;
    this._hitFlash = false;
    this._hitKw = '';
    this._dueStage = 0;
    this._deadline = 0;
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

  _timeStr() {
    return this._timeIdx >= 0 ? this._times[this._timeIdx] : '未设置';
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

  _deadlineFor(timeStr) {
    // Next occurrence of the HH:MM clock time (today, or
    // tomorrow if it already passed). The meeting time is a
    // clock time the wearer registers; the countdown is real
    // time to that clock time, not a made-up interval.
    var parts = String(timeStr).split(':');
    var h = parseInt(parts[0], 10);
    var m = parseInt(parts[1], 10);
    var d = new Date();
    d.setHours(h, m, 0, 0);
    if (d.getTime() <= this._now()) d = new Date(d.getTime() + 24 * 3600 * 1000);
    return d.getTime();
  },

  _tick() {
    // Due reminders are threshold crossings, not a loop: the
    // 10-minute warning fires once, the overdue warning fires
    // once. A reminder already on screen is never re-spoken.
    if (this._mode !== 'listening' || !this._deadline) return;
    var left = this._deadline - this._now();
    if (left <= 0 && this._dueStage < 2) {
      this._dueStage = 2;
      this._dueCount++;
      this._dueFlash = true;
      this._speakText('已经过了集合时间，请往登记朝向归队');
      this.setData({
        status: '过了集合时间 — 请往登记朝向归队，CHECK 确认归队',
        lastEvent: 'EVT: overdue reminder (due ' + this._dueCount + ') - past meeting time'
      });
      this._renderAll();
      return;
    }
    if (left <= 10 * 60 * 1000 && this._dueStage === 0) {
      this._dueStage = 1;
      this._dueCount++;
      this._dueFlash = true;
      this._speakText('快到集合时间了，请往登记朝向归队');
      this.setData({
        status: '快到集合时间了 — 往登记朝向归队，CHECK 确认归队',
        lastEvent: 'EVT: due reminder (due ' + this._dueCount + ') - 10 minutes to meeting'
      });
      this._renderAll();
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
    // Nod discipline in THIS agent: a steady nod registers the
    // meeting direction (idle — you are facing it, that is the
    // gaze confirm), confirms归队 when a due reminder is on
    // screen (listening), or confirms the summary. A nod never
    // starts listening on its own and never saves a note: the
    // gate is the transcript, not the head.
    if (this._mode === 'idle') { this.regTap(); return; }
    if (this._mode === 'listening' && this._dueFlash) { this.checkTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored here - REG registers direction, CHECK confirms归队 when reminded' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.regTap();
      else if (this._mode === 'listening' && this._dueFlash) this.checkTap();
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

  regTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: REG refused - direction is registered before START, not mid-tour' });
      return;
    }
    if (this._dir) {
      this.setData({ lastEvent: 'EVT: REG - direction already registered: ' + this._dir });
      return;
    }
    this._dir = '当前朝向（已登记）';
    this.setData({
      status: '集合点朝向已登记 — TIME 选集合时间，START 开始守听',
      lastEvent: 'EVT: meeting direction registered (current facing)'
    });
    this._renderAll();
  },

  timeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TIME refused - meeting time is set before START, not mid-tour' });
      return;
    }
    this._timeIdx = (this._timeIdx + 1) % this._times.length;
    this.setData({
      status: '集合时间已设为 ' + this._timeStr() + ' — START 开始守听',
      lastEvent: 'EVT: meeting time set - ' + this._timeStr()
    });
    this._renderAll();
  },

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - listening is already under way or finished' });
      return;
    }
    var missing = [];
    if (!this._dir) missing.push('集合点朝向（REG 登记）');
    if (this._timeIdx < 0) missing.push('集合时间（TIME 选择）');
    if (missing.length > 0) {
      this.setData({ lastEvent: 'EVT: START refused - missing: ' + missing.join('、') });
      return;
    }
    this._mode = 'listening';
    this._startAt = this._now();
    this._deadline = this._deadlineFor(this._timeStr());
    this._focus = 0;
    this.setData({
      status: '守听进行中 — far-field 守听导游喊话，只提集合信息；非集合句只计数不存',
      lastEvent: 'EVT: listening started (direction + time ' + this._timeStr() + ')'
    });
    this._renderAll();
  },

  // ---------- transcript gate ----------

  _onSegment(text) {
    // The gate: one ASR transcript segment in, one decision out.
    // A hit saves the sentence itself (plus minute mark and the
    // keyword) and banners + speaks the keyword once — the
    // sentence is shown in view, never read aloud whole, so a
    // hit costs one short utterance, not a paragraph. A
    // non-hit moves only the counter: the sentence is discarded
    // here and stored nowhere.
    if (this._mode !== 'listening') return;
    var seg = String(text || '');
    this._segments++;
    var hitKw = '';
    for (var i = 0; i < this._keywords.length; i++) {
      if (seg.indexOf(this._keywords[i]) >= 0) { hitKw = this._keywords[i]; break; }
    }
    if (!hitKw) {
      this.setData({ lastEvent: 'EVT: segment ' + this._segments + ' - no meeting keyword, counted only, discarded' });
      this._renderAll();
      return;
    }
    this._hits++;
    this._hitFlash = true;
    this._hitKw = hitKw;
    this._notes.push({ label: this._elapsedText(), text: seg, kw: hitKw });
    this._focus = this._notes.length - 1;
    this._speakText('集合信息：' + hitKw);
    this.setData({
      status: '集合信息！关键词「' + hitKw + '」— 已记入本团笔记',
      lastEvent: 'EVT: segment ' + this._segments + ' HIT keyword ' + hitKw + ' - note saved (hits ' + this._hits + ')'
    });
    this._renderAll();
  },

  checkTap() {
    if (this._mode === 'listening' && this._dueFlash) {
      this._dueConfirmed++;
      this._dueFlash = false;
      this._speakText('归队已确认');
      this.setData({
        status: '归队已确认 — 继续看景，守听仍在进行',
        lastEvent: 'EVT:归队 confirmed (confirmed ' + this._dueConfirmed + ')'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'summary') {
      this._confirmSummary();
      return;
    }
    this.setData({ lastEvent: 'EVT: CHECK refused here - no due reminder to confirm; REG registers direction, TIME sets meeting time' });
  },

  endTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: END refused - a summary is already open' });
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - no tour is under way' });
      return;
    }
    this._mode = 'summary';
    this._summary = {
      segments: this._segments,
      hits: this._hits,
      due: this._dueCount,
      dueConfirmed: this._dueConfirmed,
      notes: this._notes.length
    };
    this.setData({
      status: '本团小结 — 确认后清空本次记录',
      lastEvent: 'EVT: tour ended - summary ready (segments ' + this._segments + ', hits ' + this._hits + ', due ' + this._dueCount + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._dir = null;
    this._timeIdx = -1;
    this._segments = 0;
    this._hits = 0;
    this._notes = [];
    this._dueCount = 0;
    this._dueConfirmed = 0;
    this._dueFlash = false;
    this._hitFlash = false;
    this._hitKw = '';
    this._dueStage = 0;
    this._deadline = 0;
    this._startAt = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this._focus = 0;
    this.setData({
      status: '跟团副线 — 主线是专心看景，副线替你听着导游的集合信息：集合点朝向登记 + 集合时间，far-field 守听只提集合句，快到点提醒归队',
      lastEvent: 'EVT: summary confirmed - tour cleared'
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
        status: '守听进行中 — far-field 守听导游喊话，只提集合信息；非集合句只计数不存',
        lastEvent: 'EVT: back to listening - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins listening, END opens the summary' });
  },

  _focusLen() {
    if (this._mode === 'idle') return 2;
    if (this._mode === 'listening') return this._notes.length;
    return this._notes.length;
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
      var missing = [];
      if (!this._dir) missing.push('集合点朝向');
      if (this._timeIdx < 0) missing.push('集合时间');
      line = missing.length > 0
        ? '还没登记：' + missing.join('、') + '，REG 登记朝向，TIME 选时间'
        : '已登记：集合点朝向 + ' + this._timeStr() + '，点开始守听';
    } else if (this._mode === 'listening') {
      if (this._dueFlash) {
        line = '快到集合时间了，请往登记朝向归队';
      } else if (this._hitFlash) {
        line = '集合信息：' + this._hitKw + '，已记入本团笔记';
      } else {
        line = '守听进行中，已听 ' + this._segments + ' 段，集合命中 ' + this._hits + ' 条';
      }
    } else if (this._summary) {
      line = '本团小结：已听 ' + this._summary.segments + ' 段，集合命中 ' + this._summary.hits + ' 条，归队提醒 ' + this._summary.due + ' 次';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user tour is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._dir || this._timeIdx >= 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user registration is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._dir = '停车场入口（DEMO 示例）';
      this._timeIdx = 1; // 15:30
      this.startTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - direction + time registered (DEMO sample), listening started' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onSegment('这边的风景真不错');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - non-hit segment counted only (segments 1, hits 0)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onSegment('大家注意，三点半在停车场入口集合');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - HIT keyword 集合, note saved (segments 2, hits 1)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      // Force the due threshold: the deadline jumps to 10
      // minutes out so the reminder fires now, labelled DEMO.
      // In a real tour the same threshold is crossed by the
      // clock, not by a tap.
      this._demoStage = 4;
      this._deadline = this._now() + 10 * 60 * 1000 - 1000;
      this._tick();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - due reminder on screen (due 1, DEMO-forced threshold)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      if (this._dueFlash) this.checkTap();
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary (segments 2, hits 1, due 1,归队 confirmed, DEMO sample)' });
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
        name: '登记1 · 集合点朝向',
        detail: this._dir ? this._dir : '未登记（看向集合点停稳，点 REG）',
        flag: this._dir ? '✓' : '○',
        cls: 'row'
      });
      rows.push({
        idx: 1,
        name: '登记2 · 集合时间',
        detail: this._timeIdx >= 0 ? this._timeStr() + '（TIME 换时间）' : '未设置（点 TIME 选择）',
        flag: this._timeIdx >= 0 ? '✓' : '○',
        cls: 'row'
      });
    } else if (this._notes.length === 0) {
      rows.push({
        idx: 0,
        name: '守听中',
        detail: '暂无集合笔记 — 非集合句只计数不存',
        flag: '◎',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._notes.length; i++) {
        n = this._notes[i];
        rows.push({
          idx: i,
          name: '笔记' + (i + 1) + ' · ' + n.label + ' · ' + n.kw,
          detail: n.text,
          flag: '✓',
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    patch.countLine = '已听 ' + this._segments + ' 段 · 集合命中 ' + this._hits + ' 条' +
      ' · 归队提醒 ' + this._dueCount + ' 次 · 归队确认 ' + this._dueConfirmed + ' 次' +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — 集合点登记：看向集合点停稳点 REG，TIME 选集合时间，START 开始守听';
      patch.bigLabel = '跟团副线 · 待机';
      patch.bigText = this._dir ? '已登记：' + (this._dir.indexOf('（') >= 0 ? this._dir.split('（')[0] : this._dir) : '未登记集合点';
      patch.bigNote = this._timeIdx >= 0
        ? '集合时间 ' + this._timeStr() + ' · ' + (this._dir ? 'START 开始守听' : 'REG 登记朝向后 START') + ' · DEMO 走演示'
        : 'REG 登记朝向 · TIME 选集合时间 · START 开始守听';
    } else if (this._mode === 'listening') {
      if (this._dueFlash) {
        patch.boxLabel = '◎ 快到集合时间了 — 往登记朝向归队，CHECK 确认归队';
        patch.bigLabel = '快到集合时间';
        patch.bigText = '该归队了';
        patch.bigNote = '集合时间 ' + this._timeStr() + ' · 集合点：' + (this._dir || '未登记') + ' · CHECK 确认归队';
      } else if (this._hitFlash) {
        patch.boxLabel = '◎ 集合信息！关键词「' + this._hitKw + '」— 已记入本团笔记';
        patch.bigLabel = '集合信息';
        patch.bigText = '「' + this._hitKw + '」命中';
        patch.bigNote = '已听 ' + this._segments + ' 段 · 集合命中 ' + this._hits + ' 条 · 笔记在下方';
      } else {
        patch.boxLabel = '◎ 守听进行中 — far-field 守听导游喊话，只提集合信息';
        patch.bigLabel = '守听进行中';
        patch.bigText = '已听 ' + this._segments + ' 段';
        patch.bigNote = '集合命中 ' + this._hits + ' 条 · 归队提醒 ' + this._dueCount + ' 次 · 非集合句只计数不存';
      }
    } else {
      patch.boxLabel = '◎ 本团小结';
      patch.bigLabel = '本团小结';
      var s = this._summary || { segments: 0, hits: 0, due: 0, dueConfirmed: 0, notes: 0 };
      patch.bigText = '集合命中 ' + s.hits + ' 条';
      patch.bigNote = '已听 ' + s.segments + ' 段 · 归队提醒 ' + s.due + ' 次 · 归队确认 ' + s.dueConfirmed + ' 次 · 笔记 ' + s.notes + ' 条 · 确认后清空本次记录';
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
      <text class="title">TOUR WATCH v1.0.0</text>
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
      <button class="btn btn-main" bindtap="regTap">REG</button>
      <button class="btn btn-main" bindtap="timeTap">TIME</button>
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
    <text class="foot2">没有说话人识别：命中只对 ASR 转写文本做集合关键词匹配，ASR 听错就可能漏报/误报；集合朝向只是你登记的方向，不是定位导航——归队仍靠你自己看路走过去；笔记只存命中句本身，不存全部转写；收音模式只影响 getUserMedia 流的拾音、不改变宿主 ASR 的拾音；本次跟团数据只存会话内存，关掉即清；far-field 守听中，非集合句只计数、判定即丢弃</text>
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
