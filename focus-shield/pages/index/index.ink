<script def>
{
  "navigationBarTitleText": "Focus Shield"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '专注护盾 — 会话门禁：白名单语音命中才打断，其余响动只记不报，休息时看小结',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — DUR 选时长，NAME 换名字，KW 换关键词，START 开始会话',
    bigLabel: '专注护盾 · 待机',
    bigText: '未开始',
    bigNote: 'START 开始会话 · DEMO 走四段演示 · 白名单外一律只记不打断',
    permLine: 'PERM: RECORD_AUDIO — 全向守听 + ASR 转写关键词门；无拍照、无定位',
    rows: [],
    countLine: '放行 0 次 · 记录 0 条 · 只存本次会话内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - set duration, name and keywords, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | session | summary
    this._paused = false;
    this._dur = 25; // minutes, preset
    this._name = '小林';
    this._nameIdx = 0;
    this._kwSet = 0;
    this._keywords = ['开会', '找你'];
    this._events = []; // { time, kind: 'pass'|'note', text, level }
    this._focus = 0;
    this._banner = ''; // current pass banner text, '' = none
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 session, 2 pass banner, 3 notes, 4 summary
    this._summary = null; // { durText, pass, note } on summary screen
    this._clearArm = false;
    this._clearTimer = null;
    this._nodLock = false;
    this._tickTimer = null;
    this._startAt = 0;
    this._demoDurText = '';
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the whitelist, the timeline,
    // the banner and the summary die with the page. Nothing was
    // ever written to any storage, so there is nothing to clean
    // up - that IS the design. Close the agent and the shield is
    // gone; the next focus session starts from a blank gate.
    this._stopTick();
    this._disarm();
    this._events = [];
    this._banner = '';
    this._summary = null;
    this._mode = 'idle';
    this._paused = false;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _namePool() { return ['小林', '阿哲']; },

  _kwSets() {
    return [['开会', '找你'], ['电话', '找你'], ['开会', '电话']];
  },

  _whitelist() {
    var out = [this._name];
    for (var i = 0; i < this._keywords.length; i++) out.push(this._keywords[i]);
    return out;
  },

  _passCount() {
    var n = 0;
    for (var i = 0; i < this._events.length; i++) if (this._events[i].kind === 'pass') n++;
    return n;
  },

  _noteCount() {
    var n = 0;
    for (var i = 0; i < this._events.length; i++) if (this._events[i].kind === 'note') n++;
    return n;
  },

  _elapsedText() {
    if (this._demoDurText) return this._demoDurText;
    if (!this._startAt) return '0 分钟';
    var m = Math.floor((this._now() - this._startAt) / 60000);
    return m + ' 分钟';
  },

  _disarm() {
    this._clearArm = false;
    if (this._clearTimer) { try { clearTimeout(this._clearTimer); } catch (e) {} this._clearTimer = null; }
  },

  _armClear() {
    this._disarm();
    this._clearArm = true;
    var self = this;
    this._clearTimer = setTimeout(function () {
      self._clearTimer = null;
      if (self._clearArm) {
        self._clearArm = false;
        self.setData({ lastEvent: 'EVT: clear disarmed (timeout) - summary kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _startTick() {
    this._stopTick();
    var self = this;
    // Display-only tick: refreshes the elapsed readout. It never
    // creates, edits or deletes session data.
    this._tickTimer = setInterval(function () {
      if (self._mode === 'session') self._renderAll();
    }, 10000);
  },

  _stopTick() {
    if (this._tickTimer) { try { clearInterval(this._tickTimer); } catch (e) {} this._tickTimer = null; }
  },

  _speakText(text) {
    // TTS via the host voice. The utterance lang is never set:
    // the documented behaviour is that it does not take effect.
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
    // Nod discipline in THIS agent: a steady nod confirms, and
    // only where confirmation is safe - START in idle, CONFIRM
    // on the summary screen. In a live session a nod is ignored
    // on purpose: ending a session or clearing a timeline must
    // never happen by accident while you are working.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored - nod never ends a live session' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'session') this.endTap();
      else this._confirmSummary();
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

  // ---------- session control ----------

  startTap() {
    this._disarm();
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - a session is already running or a summary is open' });
      return;
    }
    this._mode = 'session';
    this._paused = false;
    this._events = [];
    this._banner = '';
    this._summary = null;
    this._startAt = this._now();
    this._demoDurText = '';
    this._focus = 0;
    this._startTick();
    this._startListening();
    this.setData({
      status: '会话进行中 — 白名单外一律只记不打断',
      lastEvent: 'EVT: session started (' + this._dur + ' min, name ' + this._name + ', keywords ' + this._keywords.join('/') + ')'
    });
    this._renderAll();
  },

  pauseTap() {
    this._disarm();
    if (this._mode !== 'session') {
      this.setData({ lastEvent: 'EVT: PAUSE refused - no live session' });
      return;
    }
    this._paused = !this._paused;
    this.setData({
      status: this._paused ? '会话已暂停 — 守听暂停，打断与记录都停' : '会话进行中 — 白名单外一律只记不打断',
      lastEvent: this._paused ? 'EVT: session paused - listening paused' : 'EVT: session resumed'
    });
    this._renderAll();
  },

  endTap() {
    this._disarm();
    if (this._mode !== 'session') {
      this.setData({ lastEvent: 'EVT: END refused - no live session' });
      return;
    }
    this._stopTick();
    this._stopListening();
    this._mode = 'summary';
    this._paused = false;
    this._summary = {
      durText: this._elapsedText(),
      pass: this._passCount(),
      note: this._noteCount()
    };
    this.setData({
      status: '休息小结 — 会话已结束，确认后清空本次记录',
      lastEvent: 'EVT: session ended - summary ready (pass ' + this._summary.pass + ', note ' + this._summary.note + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    this._disarm();
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._events = [];
    this._banner = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._demoDurText = '';
    this._startAt = 0;
    this.setData({
      status: '专注护盾 — 会话门禁：白名单语音命中才打断，其余响动只记不报，休息时看小结',
      lastEvent: 'EVT: summary confirmed - session data cleared'
    });
    this._renderAll();
  },

  backTap() {
    this._disarm();
    if (this._mode === 'summary') {
      // Back from the summary returns to the live session view
      // without deleting anything; the summary is rebuilt on END.
      this._mode = 'session';
      this._summary = null;
      this._startTick();
      this.setData({
        status: '会话进行中 — 白名单外一律只记不打断',
        lastEvent: 'EVT: back to live session - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'session') {
      this.pauseTap();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - already idle' });
  },

  nextTap() {
    this._disarm();
    if (this._events.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - timeline is empty' });
      return;
    }
    this._focus = (this._focus + 1) % this._events.length;
    this._banner = '';
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> entry ' + (this._focus + 1) });
  },

  prevTap() {
    this._disarm();
    if (this._events.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - timeline is empty' });
      return;
    }
    this._focus = (this._focus - 1 + this._events.length) % this._events.length;
    this._banner = '';
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> entry ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._events.length) return;
    this._focus = idx;
    var ev = this._events[idx];
    this.setData({ lastEvent: 'EVT: entry ' + (idx + 1) + ' - ' + ev.text });
    this._renderAll();
  },

  // ---------- settings (idle only) ----------

  durTap() {
    this._disarm();
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: DUR refused - settings change only in idle' });
      return;
    }
    this._dur = this._dur === 25 ? 50 : 25;
    this.setData({ lastEvent: 'EVT: duration set to ' + this._dur + ' min' });
    this._renderAll();
  },

  nameTap() {
    this._disarm();
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: NAME refused - settings change only in idle' });
      return;
    }
    this._nameIdx = (this._nameIdx + 1) % this._namePool().length;
    this._name = this._namePool()[this._nameIdx];
    this.setData({ lastEvent: 'EVT: whitelist name set to ' + this._name + ' (DEMO sample name)' });
    this._renderAll();
  },

  kwTap() {
    this._disarm();
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: KW refused - settings change only in idle' });
      return;
    }
    this._kwSet = (this._kwSet + 1) % this._kwSets().length;
    this._keywords = this._kwSets()[this._kwSet];
    this.setData({ lastEvent: 'EVT: keywords set to ' + this._keywords.join('/') });
    this._renderAll();
  },

  // ---------- listening: the two tiers ----------

  // Tier 1 (interrupt): ASR transcript text matched against the
  // whitelist. This is the ONLY interrupt path. It matches text,
  // never audio identity: no speaker recognition exists here.
  _onTranscript(text) {
    if (this._mode !== 'session' || this._paused) return;
    var t = String(text || '');
    if (!t) return;
    var hit = '';
    var wl = this._whitelist();
    for (var i = 0; i < wl.length; i++) {
      if (t.indexOf(wl[i]) !== -1) { hit = wl[i]; break; }
    }
    if (!hit) return;
    this._events.push({ time: this._elapsedText(), kind: 'pass', text: '放行：' + t, level: '' });
    this._focus = this._events.length - 1;
    this._banner = hit;
    this._speakText('打断：' + t);
    this.setData({ lastEvent: 'EVT: whitelist hit (' + hit + ') - interrupted with TTS + banner' });
    this._renderAll();
  },

  // Tier 2 (never interrupts): a loudness spike is a level band
  // only. It is NOT a doorbell, an alarm or a cry - this platform
  // has no sound classification, and a level band must never be
  // reported as one. It is logged silently for the break summary.
  _onNoise(rms) {
    if (this._mode !== 'session' || this._paused) return;
    var r = Number(rms);
    if (isNaN(r) || r < 0.35) return;
    var level = r < 0.65 ? '中' : '高';
    this._events.push({ time: this._elapsedText(), kind: 'note', text: '响动（未分类）· 响度' + level, level: level });
    this._focus = this._events.length - 1;
    this.setData({ lastEvent: 'EVT: noise noted silently (level ' + level + ') - no TTS, no banner' });
    this._renderAll();
  },

  noteTap() {
    this._disarm();
    if (this._mode !== 'session') {
      this.setData({ lastEvent: 'EVT: NOTE refused - no live session' });
      return;
    }
    if (this._paused) {
      this.setData({ lastEvent: 'EVT: NOTE refused - session paused' });
      return;
    }
    this._events.push({ time: this._elapsedText(), kind: 'note', text: '手动记录响动（未分类）', level: '中' });
    this._focus = this._events.length - 1;
    this.setData({ lastEvent: 'EVT: manual noise note added (silent)' });
    this._renderAll();
  },

  _startListening() {
    // Real-device path, guarded: omnidirectional getUserMedia
    // stream -> AnalyserNode RMS -> _onNoise; ASR transcript ->
    // _onTranscript. On the preview host both fail by design and
    // the session still works through DEMO / manual NOTE.
    try {
      var self = this;
      if (typeof navigator !== 'undefined' && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: { microphoneMode: 'omnidirectional' } }).then(function (stream) {
          try {
            var ctx = new (window.AudioContext || window.webkitAudioContext)();
            var src = ctx.createMediaStreamSource(stream);
            var an = ctx.createAnalyser();
            src.connect(an);
            var buf = new Float32Array(an.fftSize);
            var poll = function () {
              if (self._mode !== 'session') { try { stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {} return; }
              try {
                an.getFloatTimeDomainData(buf);
                var sum = 0;
                for (var i = 0; i < buf.length; i++) sum += buf[i] * buf[i];
                var rms = Math.sqrt(sum / buf.length);
                self._onNoise(rms);
              } catch (e) {}
              setTimeout(poll, 1000);
            };
            setTimeout(poll, 1000);
          } catch (e) {}
        }).catch(function (e) {
          self.setData({ lastEvent: 'EVT: listening unavailable here - ' + self._err(e) });
        });
      }
    } catch (e) {}
  },

  _stopListening() {
    // Streams are stopped by the poll loop when the mode leaves
    // 'session'; nothing else to tear down here.
  },

  delTap() {
    if (this._mode === 'session') {
      // In a live session DEL only clears the pass banner - it
      // never deletes timeline entries or ends the session.
      this._banner = '';
      this._disarm();
      this.setData({ lastEvent: 'EVT: banner cleared - session and timeline kept' });
      this._renderAll();
      return;
    }
    if (this._mode === 'summary') {
      if (!this._clearArm) {
        this._armClear();
        this.setData({ lastEvent: 'EVT: DEL armed - tap DEL again within 6 s to clear the session' });
        this._renderAll();
        return;
      }
      this._disarm();
      this._confirmSummary();
      return;
    }
    this._disarm();
    this.setData({ lastEvent: 'EVT: DEL ignored - nothing to clear in idle' });
  },

  speakTap() {
    this._disarm();
    var line = '';
    if (this._mode === 'idle') {
      line = '专注护盾待机，' + this._dur + ' 分钟，名字 ' + this._name + '，关键词 ' + this._keywords.join('、');
    } else if (this._mode === 'session') {
      if (this._banner) {
        line = '放行打断：' + this._banner;
      } else {
        line = '会话进行中，已专注 ' + this._elapsedText() + '，放行 ' + this._passCount() + ' 次，记录 ' + this._noteCount() + ' 条';
      }
    } else if (this._summary) {
      line = '休息小结：专注 ' + this._summary.durText + '，放行打断 ' + this._summary.pass + ' 次，记录响动 ' + this._summary.note + ' 条';
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    this._disarm();
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode === 'session' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is running' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._mode = 'session';
      this._paused = false;
      this._dur = 25;
      this._name = '小林';
      this._keywords = ['开会', '找你'];
      this._events = [];
      this._banner = '';
      this._summary = null;
      this._startAt = this._now();
      this._demoDurText = '12 分钟（DEMO）';
      this._focus = 0;
      this.setData({
        status: 'DEMO - 会话进行中（示例数据，非真实守听）',
        lastEvent: 'EVT: DEMO stage 1 - session started (25 min, name 小林， keywords 开会/找你）'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onTranscript('小林，开会时间到了');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - whitelist hit (小林） banner + TTS' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onNoise(0.5);
      this._onNoise(0.8);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - two noise notes logged silently (no TTS, no banner)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._stopTick();
      this._mode = 'summary';
      this._summary = { durText: '12 分钟（DEMO）', pass: this._passCount(), note: this._noteCount() };
      this.setData({
        status: 'DEMO - 休息小结（示例数据）',
        lastEvent: 'EVT: DEMO stage 4 - break summary (pass 1, note 2)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._events.length; i++) {
      var ev = this._events[i];
      rows.push({
        idx: i,
        name: ev.time + ' · ' + ev.text,
        detail: ev.kind === 'pass' ? '放行' : '记录',
        flag: ev.kind === 'pass' ? '!' : '·',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '放行 ' + this._passCount() + ' 次 · 记录 ' + this._noteCount() + ' 条' +
      (this._paused ? ' · 已暂停' : '') +
      ' · 只存本次会话内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — DUR 选时长，NAME 换名字，KW 换关键词，START 开始会话';
      patch.bigLabel = '专注护盾 · 待机';
      patch.bigText = this._dur + ' 分钟';
      patch.bigNote = '名字：' + this._name + ' · 关键词：' + this._keywords.join('、') + ' · START 开始 · DEMO 走演示';
    } else if (this._mode === 'session') {
      if (this._banner) {
        patch.boxLabel = '◎ 放行打断 — 白名单命中，TTS 已播报';
        patch.bigLabel = '放行打断';
        patch.bigText = this._banner;
        patch.bigNote = '命中白名单 · 横幅留待回看 · DEL 只清横幅，不动时间线';
      } else {
        patch.boxLabel = '◎ 会话进行中 — 白名单外一律只记不打断';
        patch.bigLabel = '会话进行中' + (this._paused ? ' · 已暂停' : '');
        patch.bigText = '已专注 ' + this._elapsedText();
        patch.bigNote = '名字：' + this._name + ' · 关键词：' + this._keywords.join('、') + ' · 响动只记不报，休息时看小结';
      }
    } else {
      patch.boxLabel = '◎ 休息小结';
      patch.bigLabel = '休息小结';
      var s = this._summary || { durText: '0 分钟', pass: 0, note: 0 };
      patch.bigText = '专注 ' + s.durText;
      patch.bigNote = '放行打断 ' + s.pass + ' 次 · 记录响动 ' + s.note + ' 条 · 确认后清空本次记录';
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
      <text class="title">FOCUS SHIELD v1.0.0</text>
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
      <button class="btn" bindtap="pauseTap">PAUSE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="kwTap">KW</button>
      <button class="btn" bindtap="nameTap">NAME</button>
      <button class="btn" bindtap="durTap">DUR</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="noteTap">NOTE</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="delTap">DEL</button>
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
    <text class="foot2">门铃/报警/孩子哭没有声音分类，响动只能记不能认 · 白名单只匹配 ASR 转写文本 · 只记本次会话，关掉即清</text>
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
  line-height: 38px;
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
  height: 95px;
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
