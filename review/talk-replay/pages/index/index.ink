<script def>
{
  "navigationBarTitleText": "Talk Replay"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '谈话回放 — 谈话时字幕按说话方标注，谈完回放只列承诺 + 数字 + 期限三类句',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 守听 — SIDE 标说话方、DIR 标朝向，SEG 收一段示例转写，REPLAY 回放',
    bigLabel: '谈话守听 · 待机',
    bigText: '还没收',
    bigNote: '说话方 对方 · 朝向 前方 · SEG 收一段示例转写 · REPLAY 回放',
    permLine: 'PERM: RECORD_AUDIO — 谈话守听 + ASR 转写；不拍照、不定位；收音模式只影响 getUserMedia 流、不改变宿主 ASR',
    rows: [],
    countLine: '已收 0 段 · 对方 0 · 自己 0 · 承诺 0 · 数字 0 · 期限 0 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - subtitles arrive tagged by SIDE and DIR, then REPLAY',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'listen'; // listen | replay | summary
    this._sideList = ['对方', '自己'];
    this._sideIdx = 0;
    this._dirList = ['前方', '左前方', '右前方', '左方', '右方', '后方'];
    this._dirIdx = 0;
    // Sample transcript lines for SEG / DEMO. In the real device
    // these arrive from host ASR via onASRResult; the preview
    // host has no ASR, so SEG and DEMO feed the same
    // _addSegment path with labelled samples. Samples are
    // labelled 示例转写 wherever they appear.
    this._sampleList = [
      '房东说：这周五前会把押金退给你',
      '我说：押金是 3200 元',
      '师傅说：下周二保证修好',
      '房东说：水电费每月 150 元',
      '我说：月底前把合同签好'
    ];
    this._sampleIdx = 0;
    this._filterList = ['全部', '承诺', '数字', '期限'];
    this._filterIdx = 0;
    this._segments = []; // { text, side, dir, time, classes, demo } — session memory only
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1-3 segments, 4 replay+filter, 5 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the subtitles die with the
    // page. Nothing was ever written anywhere persistent, so
    // there is nothing to clean up — that IS the design. Close
    // the agent and the talk is gone.
    this._mode = 'listen';
    this._sideIdx = 0;
    this._dirIdx = 0;
    this._sampleIdx = 0;
    this._filterIdx = 0;
    this._segments = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _timeLabel() {
    var d = new Date(this._now());
    var h = String(d.getHours());
    if (h.length < 2) h = '0' + h;
    var m = String(d.getMinutes());
    if (m.length < 2) m = '0' + m;
    return h + ':' + m;
  },

  _side() { return this._sideList[this._sideIdx]; },
  _dir() { return this._dirList[this._dirIdx]; },
  _filter() { return this._filterList[this._filterIdx]; },

  // Three kinds of sentences, by keyword match only — NOT
  // semantic understanding. A sentence with 会 in it is not
  // necessarily a promise; a sentence the ASR misheard can be
  // mis-sorted or missed. Replay lists candidates; the talk's
  // real meaning is the user's call.
  _classes(text) {
    var out = [];
    if (/会|保证|答应|负责|包|一定/.test(text)) out.push('承诺');
    if (/[0-9]|元|块|万|千|百/.test(text)) out.push('数字');
    if (/周|号|天内|之前|月底|下周|明天|后天|截止/.test(text)) out.push('期限');
    return out;
  },

  _addSegment(text, demo) {
    this._segments.push({
      text: text,
      side: this._side(),
      dir: this._dir(),
      time: this._timeLabel(),
      classes: this._classes(text),
      demo: !!demo
    });
    this._focus = this._segments.length - 1;
  },

  // Real-device path: host ASR delivers transcript text here
  // and it flows into the same register as the samples. The
  // preview host has no ASR, so SEG / DEMO simulate this feed.
  onASRResult(event) {
    if (this._mode !== 'listen') return;
    var d = (event && event.detail) || event || {};
    var text = d.text || d.transcript || d.result || '';
    if (!text) return;
    this._addSegment(String(text), false);
    this.setData({
      status: '已收一段：' + text + '（' + this._side() + ' · ' + this._dir() + '）',
      lastEvent: 'EVT: subtitle received - ' + text
    });
    this._renderAll();
  },

  _visible() {
    var f = this._filter();
    if (f === '全部') return this._segments.slice();
    var out = [];
    var i;
    for (i = 0; i < this._segments.length; i++) {
      if (this._segments[i].classes.indexOf(f) !== -1) out.push(this._segments[i]);
    }
    return out;
  },

  _counts() {
    var c = { '对方': 0, '自己': 0, '承诺': 0, '数字': 0, '期限': 0 };
    var i, j;
    for (i = 0; i < this._segments.length; i++) {
      if (c[this._segments[i].side] !== undefined) c[this._segments[i].side]++;
      for (j = 0; j < this._segments[i].classes.length; j++) {
        if (c[this._segments[i].classes[j]] !== undefined) c[this._segments[i].classes[j]]++;
      }
    }
    return c;
  },

  _otherPromises() {
    var out = [];
    var i;
    for (i = 0; i < this._segments.length; i++) {
      if (this._segments[i].side === '对方' && this._segments[i].classes.indexOf('承诺') !== -1) {
        out.push(this._segments[i]);
      }
    }
    return out;
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
    // Nod discipline in THIS agent: a steady nod advances the
    // replay by one, or confirms the summary. It never adds a
    // subtitle in listen mode — subtitles arrive from the talk
    // itself, and a nod must not invent one. It never changes
    // SIDE or DIR: those are selections, and a nod must not
    // silently pick one.
    if (this._mode === 'replay') { this.nextTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored in listen - subtitles arrive from the talk, a nod does not add one' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'replay') this.nextTap();
      else if (this._mode === 'summary') this._confirmSummary();
      else this.setData({ lastEvent: 'EVT: Enter ignored in listen - subtitles arrive from the talk, Enter does not add one' });
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

  // ---------- selection ----------

  sideTap() {
    if (this._mode !== 'listen') {
      this.setData({ lastEvent: 'EVT: SIDE refused - the speaking side is marked while listening, not in replay or summary' });
      return;
    }
    this._sideIdx = (this._sideIdx + 1) % this._sideList.length;
    this.setData({
      status: '说话方已标为 ' + this._side() + ' — 接下来的字幕都归这一方，直到你再切',
      lastEvent: 'EVT: side set - ' + this._side()
    });
    this._renderAll();
  },

  dirTap() {
    if (this._mode !== 'listen') {
      this.setData({ lastEvent: 'EVT: DIR refused - direction is marked while listening, not in replay or summary' });
      return;
    }
    this._dirIdx = (this._dirIdx + 1) % this._dirList.length;
    this.setData({
      status: '朝向已标为 ' + this._dir() + ' — 接下来的字幕都带这个朝向',
      lastEvent: 'EVT: direction set - ' + this._dir()
    });
    this._renderAll();
  },

  // ---------- listen / replay / summary ----------

  segTap() {
    if (this._mode !== 'listen') {
      this.setData({ lastEvent: 'EVT: SEG refused - subtitles are received while listening, not in replay or summary' });
      return;
    }
    var text = this._sampleList[this._sampleIdx % this._sampleList.length];
    this._sampleIdx++;
    this._addSegment(text, true);
    this.setData({
      status: '已收一段示例转写：' + text + '（' + this._side() + ' · ' + this._dir() + '）— 继续收，或 REPLAY 回放',
      lastEvent: 'EVT: subtitle received (示例转写) - ' + text + ' (' + this._side() + ', ' + this._dir() + ')'
    });
    this._renderAll();
  },

  replayTap() {
    if (this._mode === 'replay') {
      this.setData({ lastEvent: 'EVT: REPLAY refused - talk replay is already open' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: REPLAY refused - confirm or go back from the summary first' });
      return;
    }
    if (this._segments.length === 0) {
      this.setData({ lastEvent: 'EVT: REPLAY refused - missing: 至少收一段字幕（SEG）' });
      return;
    }
    this._mode = 'replay';
    this._filterIdx = 0;
    this._focus = 0;
    this.setData({
      status: '谈话回放 — 只列承诺 + 数字 + 期限三类句，FILTER 换类型，NEXT/PREV 换段',
      lastEvent: 'EVT: replay started (' + this._segments.length + ' segments)'
    });
    this._renderAll();
  },

  filterTap() {
    if (this._mode !== 'replay') {
      this.setData({ lastEvent: 'EVT: FILTER refused - filtering applies to the talk replay, not while listening or in summary' });
      return;
    }
    this._filterIdx = (this._filterIdx + 1) % this._filterList.length;
    this._focus = 0;
    this.setData({
      status: '过滤已切为 ' + this._filter() + ' — 回放只列该类句',
      lastEvent: 'EVT: filter set - ' + this._filter()
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the talk.
      // BACK is the way back to replay without deleting.
      this._confirmSummary();
      return;
    }
    if (this._segments.length === 0) {
      this.setData({ lastEvent: 'EVT: END refused - missing: 至少收一段字幕（SEG）' });
      return;
    }
    this._mode = 'summary';
    var c = this._counts();
    this._summary = {
      total: this._segments.length,
      other: c['对方'],
      self: c['自己'],
      promise: c['承诺'],
      number: c['数字'],
      deadline: c['期限'],
      otherPromises: this._otherPromises().length
    };
    this.setData({
      status: '本次谈话小结 — 对方承诺句逐条列在下面，点 END 确认清空，BACK 返回回放',
      lastEvent: 'EVT: talk ended - summary ready (total ' + this._segments.length + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'listen';
    this._sideIdx = 0;
    this._dirIdx = 0;
    this._sampleIdx = 0;
    this._filterIdx = 0;
    this._segments = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '谈话回放 — 谈话时字幕按说话方标注，谈完回放只列承诺 + 数字 + 期限三类句',
      lastEvent: 'EVT: summary confirmed - talk cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to replay without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'replay';
      this._summary = null;
      this.setData({
        status: '谈话回放 — 只列承诺 + 数字 + 期限三类句，FILTER 换类型，NEXT/PREV 换段',
        lastEvent: 'EVT: back to replay - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'replay') {
      this._mode = 'listen';
      this.setData({
        status: '谈话守听 — 继续收，或 REPLAY 回放',
        lastEvent: 'EVT: back to listening - segments kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - SEG receives a subtitle, REPLAY opens the replay' });
  },

  _focusLen() {
    if (this._mode === 'listen') return this._segments.length;
    if (this._mode === 'replay') return this._visible().length;
    return 0;
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
    if (this._mode === 'listen') {
      line = this._segments.length === 0
        ? '还没收：谈话声流进来就收一段，SEG 收一段示例转写'
        : '已收 ' + this._segments.length + ' 段，继续收或回放';
    } else if (this._mode === 'replay') {
      var vis = this._visible();
      if (vis.length === 0) {
        line = '过滤 ' + this._filter() + ' 下暂无此类句';
      } else {
        var cur = vis[this._focus] || vis[0];
        line = cur.time + '，' + cur.side + '，' + cur.dir + '：' + cur.text;
      }
    } else if (this._summary) {
      line = '本次谈话小结：共 ' + this._summary.total + ' 段，对方承诺 ' + this._summary.otherPromises + ' 句，承诺 ' + this._summary.promise + ' 句，数字 ' + this._summary.number + ' 句，期限 ' + this._summary.deadline + ' 句';
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
    if (this._mode !== 'listen' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user replay is under way' });
      return;
    }
    if (this._mode === 'listen' && !this._demo && this._segments.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user segments are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._sideIdx = 0; // 对方
      this._dirIdx = 0; // 前方
      this._sampleIdx = 0;
      this.segTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - other-party promise received (DEMO sample, 1 segment)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._sideIdx = 1; // 自己
      this._dirIdx = 2; // 右前方
      this.segTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - own number received (DEMO sample, 2 segments)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._sideIdx = 0; // 对方
      this._dirIdx = 5; // 后方
      this.segTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - other-party promise + deadline received (DEMO sample, 3 segments)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.replayTap();
      // Filter cycles 全部 -> 承诺: one tap lands on 承诺,
      // so the replay shows only the promise sentences.
      this.filterTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - replay filtered to 承诺 (2 of 3 segments visible)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary (3 segments: 承诺 2, 数字 1, 期限 2, 对方承诺 2 句, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, e;
    var list;
    if (this._mode === 'summary') {
      list = this._otherPromises();
    } else if (this._mode === 'replay') {
      list = this._visible();
    } else {
      list = this._segments;
    }
    if (list.length === 0) {
      rows.push({
        idx: 0,
        name: this._mode === 'replay' ? '过滤下暂无此类句' : (this._mode === 'summary' ? '对方暂无承诺句' : '暂无字幕'),
        detail: this._mode === 'replay'
          ? '过滤 ' + this._filter() + ' 下没有此类句 — FILTER 换个类型，或 BACK 回去继续收'
          : (this._mode === 'summary'
            ? '对方没有承诺类句 — BACK 返回回放看全部'
            : '谈话声流进来就收一段，SEG 收一段示例转写，SIDE 标说话方、DIR 标朝向'),
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < list.length; i++) {
        e = list[i];
        rows.push({
          idx: i,
          name: (this._mode === 'summary' ? '承诺' + (i + 1) : '段' + (i + 1)) + ' · ' + e.time + ' · ' + e.side + ' · ' + e.dir,
          detail: e.text + ' [' + (e.classes.length ? e.classes.join('/') : '未分类') + ']' + (e.demo ? '（DEMO 示例）' : ''),
          flag: this._focus === i ? '▶' : '✓',
          cls: 'row'
        });
      }
    }

    var c = this._counts();
    var patch = { rows: rows };
    patch.countLine = '已收 ' + this._segments.length + ' 段 · 对方 ' + c['对方'] +
      ' · 自己 ' + c['自己'] + ' · 承诺 ' + c['承诺'] +
      ' · 数字 ' + c['数字'] + ' · 期限 ' + c['期限'] +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'listen') {
      patch.boxLabel = '◎ 守听 — SIDE 标说话方、DIR 标朝向，SEG 收一段示例转写，REPLAY 回放';
      patch.bigLabel = '谈话守听 · 待机';
      patch.bigText = this._segments.length === 0 ? '还没收' : '已收 ' + this._segments.length + ' 段';
      patch.bigNote = '说话方 ' + this._side() + ' · 朝向 ' + this._dir() + ' · SEG 收一段示例转写 · REPLAY 回放';
    } else if (this._mode === 'replay') {
      patch.boxLabel = '◎ 谈话回放 · 过滤：' + this._filter() + ' — NEXT/PREV 换段，FILTER 换类型';
      patch.bigLabel = '谈话回放 · ' + this._filter();
      var vis = this._visible();
      if (vis.length === 0) {
        patch.bigText = '暂无此类';
        patch.bigNote = '过滤 ' + this._filter() + ' 下没有此类句 · FILTER 换个类型';
      } else {
        var cur = vis[this._focus] || vis[0];
        patch.bigText = cur.text;
        patch.bigNote = cur.time + ' · ' + cur.side + ' · ' + cur.dir + ' · ' + cur.classes.join('/') + ' · 第 ' + (this._focus + 1) + '/' + vis.length + ' 段' + (cur.demo ? '（DEMO 示例）' : '');
      }
    } else {
      patch.boxLabel = '◎ 本次谈话小结 — 对方承诺句逐条列在下面';
      patch.bigLabel = '本次谈话小结';
      var s = this._summary || { total: 0, other: 0, self: 0, promise: 0, number: 0, deadline: 0, otherPromises: 0 };
      patch.bigText = '共 ' + s.total + ' 段';
      patch.bigNote = '对方 ' + s.other + ' · 自己 ' + s.self + ' · 承诺 ' + s.promise + ' · 数字 ' + s.number + ' · 期限 ' + s.deadline + ' · 对方承诺 ' + s.otherPromises + ' 句 · 点 END 确认清空 · BACK 返回回放';
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
      <text class="title">TALK REPLAY v1.0.0</text>
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
      <button class="btn btn-main" bindtap="sideTap">SIDE</button>
      <button class="btn btn-main" bindtap="dirTap">DIR</button>
      <button class="btn btn-main" bindtap="segTap">SEG</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="replayTap">REPLAY</button>
      <button class="btn btn-main" bindtap="filterTap">FILTER</button>
      <button class="btn" bindtap="endTap">END</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
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
    <text class="foot2">三类句是关键词匹配分出来的，不是语义理解——「会」字句未必真是承诺，ASR 听错也可能漏分/错分，回放只列候选、最终以谈话原意为准；说话方是你切换 SIDE 标记的，不是声纹识别——没标的段不归属任何一方；只存本次谈话会话，关掉即清；收音模式只影响 getUserMedia 流的拾音、不改变宿主 ASR 的拾音；没有室内定位；零落盘</text>
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
