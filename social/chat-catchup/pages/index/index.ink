<script def>
{
  "navigationBarTitleText": "Chat Catchup"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '谈话接续 — 和人谈话走神十几秒，回来完全接不上，又不好意思让对方重复：守听字幕默记对方的话，摇头/按键求助时眼前给最近 15 秒的要点摘要',
    steadyText: 'HEAD: moving - listening starts on START, not on gaze',
    boxLabel: '◎ 最近 15 秒 — START 开始守听，HELP 求助要点摘要',
    bigLabel: '谈话接续 · 待机',
    bigText: '还没开始',
    bigNote: 'START 开始守听 · HELP 求助最近 15 秒要点（无声）',
    permLine: 'PERM: RECORD_AUDIO — 只做谈话守听 + ASR 字幕缓冲；不拍照、不定位；摘要是原句摘录，不是语义提炼；HELP 本身不出声',
    rows: [],
    countLine: '已听 0 段 · 缓冲 0 段 · 求助 0 次 · 只存本次谈话会话 · 缓冲过期即弃 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START starts listening, HELP shows the last ~15 s in silence',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | help | summary
    // Rolling ~15 s transcript window: { text, at }. Anything
    // older than 15 s is dropped before it is ever shown, so
    // the help view is genuinely the last 15 seconds.
    this._buffer = [];
    this._heard = 0;
    this._helps = 0;
    this._helpPoints = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 listening, 2-4 captions, 5 help, 6 back, 7 summary
    this._nodLock = false;
    this._stream = null;
    this._recog = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the rolling buffer, the
    // help points, the counts and the summary die with the
    // page. Nothing was ever written anywhere persistent,
    // so there is nothing to clean up — that IS the design.
    this._stopListening();
    this._mode = 'idle';
    this._buffer = [];
    this._heard = 0;
    this._helps = 0;
    this._helpPoints = [];
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

  _mic() { return 'far-field'; },

  _prune(now) {
    // Keep only segments from the last ~15 s.
    this._buffer = this._buffer.filter(function (s) { return now - s.at <= 15000; });
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. HELP itself never calls this: the
    // summary is silent by design, and only an explicit SPEAK
    // tap in the help view reads the points aloud.
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - listening starts on START, not on gaze'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g === 'shake') {
      // Shake = ask for help, but only while listening. A
      // shake in any other mode is ignored and noted: help
      // only makes sense mid-conversation. If the host never
      // sends a shake event, the HELP button is the fallback
      // — the README says so in plain words.
      if (this._mode === 'listening') { this.helpTap(); return; }
      this.setData({ lastEvent: 'EVT: shake ignored - help only makes sense while listening' });
      return;
    }
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (nod and shake only)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod starts
    // listening in idle, returns from the help view to
    // listening, or confirms the summary. A nod in listening
    // is ignored and noted: captions can only arrive from
    // the conversation stream, a nod must not invent one.
    // A nod never picks a help point and never asks for help:
    // asking for help is shake / HELP, not nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'listening') {
      this.setData({ lastEvent: 'EVT: nod ignored while listening - captions come from the conversation, not from a nod' });
      return;
    }
    if (this._mode === 'help') { this.backTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'listening') this.helpTap();
      else if (this._mode === 'help') this.backTap();
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

  // ---------- listening (ASR path, same shape as meeting-filter) ----------

  _startListening() {
    var self = this;
    try {
      if (typeof navigator !== 'undefined' && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: { microphoneMode: this._mic() } }).then(function (stream) {
          self._stream = stream;
        }).catch(function (e) {
          self.setData({ lastEvent: 'EVT: mic stream unavailable here - ' + self._err(e) });
        });
      }
    } catch (e) {}
    try {
      var SR = (typeof window !== 'undefined' && (window.SpeechRecognition || window.webkitSpeechRecognition)) || null;
      if (SR) {
        var recog = new SR();
        recog.continuous = true;
        recog.interimResults = false;
        recog.onresult = function (event) {
          try {
            var res = event.results[event.results.length - 1];
            if (res && res.isFinal) self._onTranscript(res[0].transcript || '');
          } catch (e) {}
        };
        recog.onerror = function () {};
        recog.start();
        this._recog = recog;
      }
    } catch (e) {}
  },

  _stopListening() {
    try { if (this._stream) this._stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {}
    try { if (this._recog) this._recog.stop(); } catch (e) {}
    this._stream = null;
    this._recog = null;
  },

  // The single decision point for every transcript segment,
  // real or DEMO: append to the rolling ~15 s buffer and
  // prune anything older. Nothing is classified, nothing is
  // summarised here — the help view later just lists what
  // is still inside the window.
  _onTranscript(text, atMs) {
    if (this._mode !== 'listening') return;
    var t = String(text || '').trim();
    if (!t) {
      this.setData({ lastEvent: 'EVT: empty transcript ignored - not counted' });
      return;
    }
    var now = (typeof atMs === 'number') ? atMs : this._now();
    this._buffer.push({ text: t, at: now });
    this._prune(now);
    this._heard++;
    this.setData({
      status: '守听进行中 — 字幕默记进最近 15 秒缓冲，走神时 HELP 求助（无声）',
      lastEvent: 'EVT: heard - buffered, pruned to ~15 s (' + this._buffer.length + ' kept)'
    });
    this._renderAll();
  },

  // ---------- start / help / end ----------

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already listening, helping, or summarising' });
      return;
    }
    this._mode = 'listening';
    this._buffer = [];
    this._heard = 0;
    this._helps = 0;
    this._helpPoints = [];
    this._focus = 0;
    this._summary = null;
    this._startListening();
    this.setData({
      status: '守听进行中 — 字幕默记进最近 15 秒缓冲，走神时 HELP 求助（无声）',
      lastEvent: 'EVT: listening started - far-field mic, rolling ~15 s buffer'
    });
    this._renderAll();
  },

  helpTap() {
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: HELP refused - help only makes sense while listening' });
      return;
    }
    // Re-prune at help time: a segment that aged past 15 s
    // while you were deciding to ask must not be shown.
    this._prune(this._now());
    this._helpPoints = this._buffer.slice();
    this._helps++;
    this._mode = 'help';
    this._focus = 0;
    // Deliberately no TTS here: reading the summary aloud
    // would interrupt the very conversation you zoned out
    // of. The points are in view only. SPEAK in the help
    // view is the only way they are read aloud, and only
    // because you tapped it.
    this.setData({
      status: '最近 15 秒要点（无声）— 只列缓冲内字幕原句，不是语义提炼；BACK 回守听',
      lastEvent: 'EVT: HELP - ' + this._helpPoints.length + ' points from the last ~15 s, shown in silence (help ' + this._helps + ')'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to listening without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始守听' });
      return;
    }
    this._stopListening();
    this._mode = 'summary';
    this._summary = {
      heard: this._heard,
      buffered: this._buffer.length,
      helps: this._helps
    };
    this.setData({
      status: '结束 — 求助 ' + this._helps + ' 次，已听 ' + this._heard + ' 段，点 END 确认清空，BACK 回守听',
      lastEvent: 'EVT: closed - helps ' + this._helps + ', heard ' + this._heard + ', buffered ' + this._buffer.length
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._stopListening();
    this._mode = 'idle';
    this._buffer = [];
    this._heard = 0;
    this._helps = 0;
    this._helpPoints = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '谈话接续 — START 再次开始守听',
      lastEvent: 'EVT: summary confirmed - buffer and counts cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to listening without
      // deleting anything; the summary is rebuilt on END.
      // Listening restarts so the buffer keeps rolling.
      this._mode = 'listening';
      this._summary = null;
      this._startListening();
      this.setData({
        status: '守听进行中 — 字幕默记进最近 15 秒缓冲，走神时 HELP 求助（无声）',
        lastEvent: 'EVT: back to listening - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'help') {
      // Back from the help view returns to listening. The
      // frozen help points are kept until the next HELP, but
      // the live buffer keeps rolling underneath.
      this._mode = 'listening';
      this.setData({
        status: '守听进行中 — 字幕默记进最近 15 秒缓冲，走神时 HELP 求助（无声）',
        lastEvent: 'EVT: back to listening from help - buffer keeps rolling'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins listening, HELP asks while listening' });
  },

  _focusLen() {
    if (this._mode === 'help') return this._helpPoints.length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus (focus walks help points only)' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus (focus walks help points only)' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
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
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没开始：START 开始守听';
    } else if (this._mode === 'listening') {
      line = '守听中，已听 ' + this._heard + ' 段，缓冲 ' + this._buffer.length + ' 段';
    } else if (this._mode === 'help') {
      // The only place buffer sentences are ever spoken, and
      // only because you tapped SPEAK in the help view. HELP
      // itself stays silent.
      line = this._helpPoints.length === 0
        ? '最近 15 秒没有字幕'
        : '最近 15 秒要点：' + this._helpPoints.map(function (s) { return s.text; }).join('；');
    } else if (this._summary) {
      line = '本次谈话小结：求助 ' + this._summary.helps + ' 次，已听 ' + this._summary.heard + ' 段，缓冲 ' + this._summary.buffered + ' 段';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user listening session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._heard > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user captions are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._mode = 'listening';
      this._buffer = [];
      this._heard = 0;
      this._helps = 0;
      this._helpPoints = [];
      this._focus = 0;
      this._summary = null;
      this.setData({
        status: 'DEMO - 守听进行中（示例字幕，非真实转写）',
        lastEvent: 'EVT: DEMO stage 1 - listening started (DEMO sample, far-field)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onTranscript('明天三点前把货送到仓库', this._now());
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - caption 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onTranscript('预算先定五千，超了再商量', this._now());
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - caption 2 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._onTranscript('周五前把合同发过来', this._now());
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - caption 3 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.helpTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - HELP, 3 points from the last ~15 s, shown in silence (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.backTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - back to listening, buffer keeps rolling (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - summary: helps 1, heard 3 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i;

    if (this._mode === 'idle') {
      rows.push({
        idx: 0,
        name: '暂未开始',
        detail: 'START 开始守听（示例字幕，DEMO 演示）',
        flag: '○',
        cls: 'row'
      });
    } else if (this._mode === 'listening') {
      if (this._buffer.length === 0) {
        rows.push({
          idx: 0,
          name: '缓冲是空的',
          detail: '还没听到字幕 — HELP 现在求助也只会给空摘要',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._buffer.length; i++) {
          rows.push({
            idx: i,
            name: '第 ' + (i + 1) + ' 段',
            detail: this._buffer[i].text + (i === this._buffer.length - 1 ? ' · 最新' : ''),
            flag: (i === this._buffer.length - 1 ? '▶' : '○'),
            cls: 'row'
          });
        }
      }
    } else if (this._mode === 'help') {
      if (this._helpPoints.length === 0) {
        rows.push({
          idx: 0,
          name: '最近 15 秒没有字幕',
          detail: '缓冲是空的 — BACK 回守听继续记',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._helpPoints.length; i++) {
          rows.push({
            idx: i,
            name: '要点 ' + (i + 1),
            detail: this._helpPoints[i].text + (this._focus === i ? ' · 当前' : ''),
            flag: (this._focus === i ? '▶' : '○'),
            cls: 'row'
          });
        }
      }
    } else {
      var s = this._summary || { heard: 0, buffered: 0, helps: 0 };
      rows.push({ idx: 0, name: '求助', detail: s.helps + ' 次', flag: '○', cls: 'row' });
      rows.push({ idx: 1, name: '已听', detail: s.heard + ' 段', flag: '○', cls: 'row' });
      rows.push({ idx: 2, name: '缓冲', detail: s.buffered + ' 段', flag: '○', cls: 'row' });
    }

    var patch = { rows: rows };
    patch.countLine = '已听 ' + this._heard + ' 段 · 缓冲 ' + this._buffer.length + ' 段 · 求助 ' + this._helps + ' 次 · 只存本次谈话会话 · 缓冲过期即弃 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 最近 15 秒 — START 开始守听，HELP 求助要点摘要';
      patch.bigLabel = '谈话接续 · 待机';
      patch.bigText = '还没开始';
      patch.bigNote = 'START 开始守听 · HELP 求助最近 15 秒要点（无声）';
    } else if (this._mode === 'listening') {
      patch.boxLabel = '◎ 守听进行中 — HELP 求助最近 15 秒要点，END 结束';
      patch.bigLabel = '谈话接续 · 守听中';
      patch.bigText = '守听中 · ' + this._buffer.length + ' 段';
      patch.bigNote = this._buffer.length === 0
        ? '还没听到字幕 · HELP 求助 · END 结束出小结'
        : '最新：' + this._buffer[this._buffer.length - 1].text + ' · HELP 求助 · END 结束出小结';
    } else if (this._mode === 'help') {
      patch.boxLabel = '◎ 最近 15 秒要点（无声）— 只列缓冲内字幕原句';
      patch.bigLabel = '谈话接续 · 最近 15 秒';
      patch.bigText = this._helpPoints.length === 0 ? '没有字幕' : '要点 ' + this._helpPoints.length + ' 条';
      patch.bigNote = this._helpPoints.length === 0
        ? '缓冲是空的 · BACK 回守听继续记'
        : '原句摘录，不是语义提炼 · BACK 回守听 · SPEAK 主动点才出声';
    } else {
      patch.boxLabel = '◎ 本次谈话小结 — 求助、已听、缓冲钉在下面';
      patch.bigLabel = '本次谈话小结';
      var sm = this._summary || { heard: 0, buffered: 0, helps: 0 };
      patch.bigText = '求助 ' + sm.helps + ' 次';
      patch.bigNote = '已听 ' + sm.heard + ' 段 · 缓冲 ' + sm.buffered + ' 段 · 点 END 确认清空 · BACK 回守听';
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
      <text class="title">CHAT CATCHUP v1.0.0</text>
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
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn btn-main" bindtap="helpTap">HELP</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
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
    <text class="foot2">要点摘要是缓冲内字幕原句的摘录罗列，不是语义提炼——Agent 不理解谈话内容；HELP 本身不出声，只有摘要页主动点 SPEAK 才会把要点读出来；没有说话人识别，缓冲不分说话方；摇头求助以宿主发送 shake 手势为准，若宿主不发送则以 HELP 按键为准；只存本次谈话会话，缓冲过期即弃，关掉即清；收音模式只影响 getUserMedia 流的拾音、不改变宿主 ASR 的拾音；没有室内定位；零落盘</text>
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
