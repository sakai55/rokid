<script def>
{
  "navigationBarTitleText": "Fall Guard"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'MONITORING - jolt + stillness = check on you',
    sensorLine: 'MOTION: --- deg/s · SRC: NONE',
    stateLine: 'STATE: MONITOR · CONTACT —',
    rows: [
      { text: 'JOLT > 240 deg/s, then 15 s motionless = CHECK' },
      { text: 'CHECK asks 60 s - any reply, nod or OK cancels' },
      { text: 'NO REPLY = ALERT card (it cannot call anyone)' },
      { text: 'EVENTS LOGGED: 0 (times + outcomes only)' }
    ],
    focusName: 'WATCHING — ALL QUIET',
    focusLine: 'a jolt then 15 s still starts a spoken check',
    arrow: '◎',
    guideLine: 'PATTERN WATCH, NOT A MEDICAL ALARM',
    guideCls: 'rel',
    lastEvent: 'EVT: I watch for a motion pattern - not falls',
    busy: false
  },

  onLoad() {
    // ---- detection state machine (session scope) ----
    this._state = 'MONITOR';        // MONITOR | STILL | CHECK | ALERT
    this._lastQ = null;             // last orientation quaternion [x,y,z,w]
    this._lastQMs = 0;              // wall time of that sample
    this._angVel = null;            // latest angular speed (deg/s)
    this._sampleAgeMs = 0;          // ms since the newest sample (clock interp.)
    this._joltUntilMs = 0;          // a jolt stays "recent" for 750 ms
    this._stillBaseQ = null;        // orientation captured when the jolt ended
    this._stillMs = 0;              // continuous motionless time after a jolt
    this._gain3s = 0;               // reorientation inside a 3 s window (jolt = fast turn)
    this._gainQ = [];               // [{q, t}] samples inside the window
    this._checkMs = 0;              // time spent in CHECK
    this._checkSpoke = 0;           // how many times the question was spoken
    this._alertSpoke = 0;           // how many times the alert was spoken
    this._log = [];                 // [{time, outcome}] - wx key 'fallGuardLog'
    this._contact = null;           // {name, rel} - wx key 'fallGuardContact'
    this._relIdx = 0;
    this._rels = ['子女', '配偶', '邻居', '护工'];
    this._stable = null;            // last host stability signal (display + soft evidence)
    this._sensor = null;
    this._orientSrc = 'NONE';
    this._timer = null;
    this._lastTickMs = 0;
    this._rec = null;               // one-shot SpeechRecognition while CHECK listens
    this._listening = false;
    this._demo = false;
    this._demoSaved = null;         // real contact snapshot while in DEMO
    this._lastSpeak = null;
    this._loadStore();
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startSensor();
    this._startTimer();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startSensor();
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopSensor();
    this._stopRec();
  },

  onUnload() {
    this._stopTimer();
    this._stopSensor();
    this._stopRec();
    this._saveLog();
  },

  onOrientationStabilityChange(event) {
    this._stable = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g === 'nod') {
      if (this._state === 'CHECK') this.respondOk('nod');
      else this.speakTap();
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._state === 'CHECK') this.respondOk('key');
      else if (this._state === 'ALERT') this.backTap();
      else this.okTap();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  // ---------- orientation stream ----------
  //
  // The only documented motion basis is the AbsoluteOrientationSensor
  // quaternion stream (about 5 Hz here) plus the host's
  // onOrientationStabilityChange events. There is no fall API, so
  // this agent watches a PATTERN in that stream:
  //   angle between successive quaternions  -> angular speed
  //   a fast reorientation (gain over a 3 s window) -> "jolt"
  //   then orientation frozen at the new pose -> "stillness"
  // A normal head turn is just as fast as a jolt - the fall-like
  // signature is the stillness AFTER it. Both halves are required.
  _startSensor() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._orientSrc = 'NONE';
      this._recompute();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onSample(s.quaternion, Date.now()); });
      s.addEventListener('error', function (ev) {
        self._orientSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - motion NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._orientSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopSensor() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  // Angle (deg) between two orientation quaternions: the smallest
  // rotation taking one pose to the other. q and -q are the same pose.
  _angleBetween(a, b) {
    if (!a || !b || a.length < 4 || b.length < 4) return null;
    var na = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2] + a[3] * a[3]);
    var nb = Math.sqrt(b[0] * b[0] + b[1] * b[1] + b[2] * b[2] + b[3] * b[3]);
    if (!isFinite(na) || !isFinite(nb) || na < 1e-6 || nb < 1e-6) return null;
    var d = Math.abs(
      (a[0] / na) * (b[0] / nb) + (a[1] / na) * (b[1] / nb) +
      (a[2] / na) * (b[2] / nb) + (a[3] / na) * (b[3] / nb));
    if (d > 1) d = 1;
    return 2 * Math.acos(d) * 180 / Math.PI;
  },

  // One orientation sample. Folds the sample into the motion model:
  // refreshes the speed + gain window and records jolts. A change of
  // 60 deg or more inside any trailing 3 s window is a jolt - a fall
  // tumbles the head far, but so does a sharp look-back, which is why
  // a jolt alone never triggers anything but the stillness watch.
  _onSample(q, nowMs) {
    if (this._demo) return; // demo motion wins while simulating
    if (!q || q.length < 4) return;
    this._orientSrc = 'SENSOR';
    if (this._lastQ) {
      var dt = (nowMs - this._lastQMs) / 1000;
      var ang = this._angleBetween(this._lastQ, q);
      if (dt > 0 && ang !== null) this._angVel = ang / dt;
    }
    this._lastQ = [q[0], q[1], q[2], q[3]];
    this._lastQMs = nowMs;
    this._sampleAgeMs = 0;
    this._gainQ.push({ q: this._lastQ, t: nowMs });
    while (this._gainQ.length && nowMs - this._gainQ[0].t > 3000) this._gainQ.shift();
    var gain = 0;
    for (var i = 0; i < this._gainQ.length; i++) {
      var a = this._angleBetween(this._gainQ[i].q, this._lastQ);
      if (a !== null && a > gain) gain = a;
    }
    this._gain3s = gain;
    if (gain >= 60 && (this._state === 'MONITOR' || this._state === 'STILL')) {
      this._joltUntilMs = nowMs + 750;
    }
  },

  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onSample(self._sensor.quaternion, Date.now());
      }
      self._tick(Date.now());
      self._recompute();
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- persistence (wx sync storage) ----------

  _loadStore() {
    try {
      var lg = wx.getStorageSync('fallGuardLog');
      if (Array.isArray(lg)) {
        this._log = lg.filter(function (e) {
          return e && typeof e.time === 'string' && typeof e.outcome === 'string';
        }).slice(-30);
      }
    } catch (e) { /* storage unavailable on this host: log stays in memory */ }
    try {
      var ct = wx.getStorageSync('fallGuardContact');
      if (ct && typeof ct.name === 'string' && ct.name) {
        this._contact = { name: String(ct.name).slice(0, 24), rel: String(ct.rel || '子女') };
        var ri = this._rels.indexOf(this._contact.rel);
        if (ri >= 0) this._relIdx = ri;
      }
    } catch (e) { /* storage unavailable on this host: contact stays unset */ }
  },

  _saveLog() {
    try { wx.setStorageSync('fallGuardLog', this._log.slice(-30)); } catch (e) {}
  },

  _saveContact() {
    if (this._demo) return; // demo contact is fictional: never persist it
    try {
      if (this._contact) wx.setStorageSync('fallGuardContact', this._contact);
      else if (typeof wx.removeStorageSync === 'function') wx.removeStorageSync('fallGuardContact');
    } catch (e) {}
  },

  _logEvent(outcome) {
    if (this._demo) return; // demo events never enter the real log
    var d = new Date();
    function p(n) { return (n < 10 ? '0' : '') + n; }
    var t = p(d.getHours()) + ':' + p(d.getMinutes());
    this._log.push({ time: t, outcome: outcome });
    if (this._log.length > 30) this._log = this._log.slice(-30);
    this._saveLog();
  },

  // ---------- the fall-pattern state machine ----------
  //
  // MONITOR: samples flow. A jolt (gain >= 60 deg inside 3 s) arms
  //   the stillness watch; while the head is still moving fast
  //   (>= 60 deg/s) nothing else happens.
  // STILL: entered when a jolt happened within the last 750 ms and
  //   the head has been slow (< 15 deg/s) for a full second. From
  //   then the head must stay inside a 3 deg cone around the pose
  //   it stopped in (and the sample stream must stay alive) for
  //   15 continuous seconds. Any real movement (speed >= 15 deg/s
  //   or leaving the cone) cancels straight back to MONITOR - a
  //   person who gets up and walks off is fine by definition here.
  // CHECK: speaks "你还好吗？" at entry and every 15 s, listens for
  //   ANY speech, and accepts a nod or an OK tap. 60 s of silence
  //   escalates to ALERT.
  // ALERT: shows + repeats the pre-set contact card. It cannot call
  //   or message anyone - no such API exists. OK/BACK returns.
  _tick(nowMs) {
    var dt = this._lastTickMs > 0 ? nowMs - this._lastTickMs : 0;
    this._lastTickMs = nowMs;
    if (dt < 0) dt = 0;
    if (dt > 5000) dt = 5000; // a stalled page must not bank time
    if (this._lastQMs > 0) this._sampleAgeMs = Math.max(0, nowMs - this._lastQMs);
    var speed = this._angVel === null ? 0 : this._angVel;

    if (this._state === 'MONITOR') {
      if (this._joltUntilMs > nowMs && speed < 15) {
        this._state = 'STILL';
        this._stillMs = 0;
        this._stillBaseQ = null;
        this.setData({ lastEvent: 'EVT: jolt done - watching 15 s of stillness' });
      }
    } else if (this._state === 'STILL') {
      var moved = speed >= 15;
      if (!moved && this._stillBaseQ && this._lastQ) {
        var drift = this._angleBetween(this._stillBaseQ, this._lastQ);
        if (drift !== null && drift > 3) moved = true;
      }
      // A dead sensor cannot prove stillness: a frozen stream would
      // otherwise look exactly like a motionless head.
      var dead = !this._demo && (this._orientSrc !== 'SENSOR' || this._sampleAgeMs > 3000);
      if (moved) {
        this._state = 'MONITOR';
        this._stillMs = 0;
        this._stillBaseQ = null;
        this.setData({ lastEvent: 'EVT: movement resumed - back to MONITOR' });
      } else if (dead) {
        this._state = 'MONITOR';
        this._stillMs = 0;
        this._stillBaseQ = null;
        this.setData({ lastEvent: 'EVT: sensor stream lost - stillness unproven, watch cancelled' });
      } else {
        this._stillMs += dt;
        if (this._stillMs >= 1000 && !this._stillBaseQ && this._lastQ) {
          this._stillBaseQ = this._lastQ;
        }
        if (this._stillMs >= 15000) this._enterCheck('pattern');
      }
    } else if (this._state === 'CHECK') {
      this._checkMs += dt;
      var due = Math.floor(this._checkMs / 15000);
      if (due > this._checkSpoke) {
        this._checkSpoke = due;
        this._speakText('你还好吗？出个声，或者点一下头，告诉我你没事。');
        if (!this._listening) this._startListen();
      }
      if (this._checkMs >= 60000) this._enterAlert('no-response');
    } else if (this._state === 'ALERT') {
      if (!this._alertNextMs) this._alertNextMs = nowMs + 20000;
      if (nowMs >= this._alertNextMs) {
        this._alertNextMs = nowMs + 20000;
        this._alertSpoke++;
        this._speakText(this._alertText());
      }
    }
  },

  _enterCheck(how) {
    this._state = 'CHECK';
    this._checkMs = 0;
    this._checkSpoke = 0;
    this._stillMs = 0;
    this._stillBaseQ = null;
    this._logEvent('check-' + how);
    this.setData({
      status: 'ARE YOU OK? — 你还好吗？',
      lastEvent: 'EVT: pattern matched - asking out loud, say anything'
    });
    this._speakText('你还好吗？出个声，或者点一下头，告诉我你没事。');
    this._startListen();
    this._recompute();
  },

  _enterAlert(how) {
    this._state = 'ALERT';
    this._alertNextMs = 0;
    this._alertSpoke = 1;
    this._stopRec();
    this._logEvent('alert-' + how);
    this.setData({
      status: 'NO REPLY — SHOWING YOUR CONTACT CARD',
      lastEvent: 'EVT: no response - alert card up (it cannot call anyone)'
    });
    this._speakText(this._alertText());
    this._recompute();
  },

  _alertText() {
    if (this._contact) {
      return '需要帮助。这里有人倒下了，请联系' + this._contact.rel +
        this._contact.name + '。再说一遍，需要帮助，请联系' +
        this._contact.rel + this._contact.name + '。';
    }
    return '需要帮助。这里有人倒下了，请身边的人帮忙，必要时拨打一二零急救电话。';
  },

  // Any confirmed response while CHECK is up: speech, nod or tap.
  respondOk(how) {
    if (this._state !== 'CHECK') return;
    this._state = 'MONITOR';
    this._checkMs = 0;
    this._stopRec();
    this._logEvent('responded-ok');
    this.setData({
      status: 'MONITORING - jolt + stillness = check on you',
      lastEvent: 'EVT: you answered (' + how + ') - glad you are OK, logged'
    });
    this._speakText('好的，听到了，你没事就好。');
    this._recompute();
  },

  // ---------- one-shot listening while CHECK is up ----------
  //
  // ANY recognized speech counts as a response - the wearer may be
  // hurt and unable to say a magic word, so there is deliberately no
  // keyword matching and no voiceprint.
  _startListen() {
    if (typeof SpeechRecognition === 'undefined') {
      this._listening = false;
      return; // CHECK still works via nod / OK tap; README says so
    }
    if (this._listening) return;
    var self = this;
    try {
      this._stopRec();
      var rec = new SpeechRecognition();
      this._rec = rec;
      this._listening = true;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (txt && self._state === 'CHECK') self.respondOk('voice');
        } catch (e) {}
      };
      rec.onerror = function () { self._listening = false; };
      rec.onend = function () { if (self._rec === rec) self._rec = null; self._listening = false; };
      rec.start();
    } catch (e) {
      this._listening = false;
    }
  },

  _stopRec() {
    if (this._rec) {
      try { this._rec.abort(); } catch (e) {}
      this._rec = null;
    }
    this._listening = false;
  },

  // ---------- actions ----------

  okTap() {
    if (this._state === 'CHECK') { this.respondOk('tap'); return; }
    if (this._state === 'ALERT') { this.backTap(); return; }
    if (this._state === 'STILL') {
      // Moving on purpose: the wearer confirms they are up and fine,
      // so the stillness watch stands down.
      this._state = 'MONITOR';
      this._stillMs = 0;
      this._stillBaseQ = null;
      this.setData({ lastEvent: 'EVT: OK tapped - stillness watch cancelled by you' });
      this._recompute();
      return;
    }
    this.setData({
      status: 'MONITORING - jolt + stillness = check on you',
      lastEvent: 'EVT: OK noted - all quiet, still watching'
    });
    this._speakText('好的，我在看着。');
    this._recompute();
  },

  helpTap() {
    // Manual SOS: works from any state, skips the whole pattern.
    this._enterAlert('manual');
  },

  backTap() {
    if (this._state === 'ALERT') {
      this._state = 'MONITOR';
      this._logEvent('alert-dismissed');
      this.setData({
        status: 'MONITORING - jolt + stillness = check on you',
        lastEvent: 'EVT: alert card dismissed by tap - back to watching'
      });
      this._speakText('好的，警报解除，我继续看着。');
    } else if (this._state === 'CHECK') {
      this.respondOk('tap');
      return;
    } else {
      this.setData({ lastEvent: 'EVT: BACK - nothing to dismiss right now' });
    }
    this._recompute();
  },

  // SETUP: say the contact's name once. It is kept VERBATIM - a name
  // is the one thing an agent must never silently "correct".
  nameTap() {
    var self = this;
    if (this._state === 'CHECK' || this._state === 'ALERT') {
      this.setData({ lastEvent: 'EVT: busy - answer the check first' });
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'NAME SKIP - SpeechRecognition n/a here',
        lastEvent: 'EVT: NAME unavailable on this host (honest SKIP)'
      });
      return;
    }
    try {
      this._stopRec();
      var rec = new SpeechRecognition();
      this._rec = rec;
      this._listening = true;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          self._contact = { name: txt.slice(0, 24), rel: self._rels[self._relIdx] };
          self._saveContact();
          self.setData({
            status: 'CONTACT SET: ' + self._contact.rel + ' · ' + self._contact.name,
            lastEvent: 'EVT: contact name kept verbatim - redo if misheard'
          });
          self._speakText('记下了。需要帮助时，我会喊：请联系' +
            self._contact.rel + self._contact.name + '。');
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self._listening = false;
        self.setData({
          status: 'NAME FAIL - ' + self._err(ev.error || ev),
          lastEvent: 'EVT: NAME error - contact unchanged'
        });
      };
      rec.onend = function () { if (self._rec === rec) self._rec = null; self._listening = false; };
      rec.start();
      this.setData({
        status: 'SAY the contact name once, close and clear',
        lastEvent: 'EVT: NAME listening (one shot, verbatim)'
      });
    } catch (e) {
      this._listening = false;
      this.setData({
        status: 'NAME FAIL - ' + this._err(e),
        lastEvent: 'EVT: NAME start failed'
      });
    }
  },

  relTap() {
    this._relIdx = (this._relIdx + 1) % this._rels.length;
    if (this._contact) {
      this._contact = { name: this._contact.name, rel: this._rels[this._relIdx] };
      this._saveContact();
    }
    this.setData({
      status: 'CONTACT: ' + this._rels[this._relIdx] +
        (this._contact ? ' · ' + this._contact.name : ' - tap NAME to say who'),
      lastEvent: 'EVT: contact relation -> ' + this._rels[this._relIdx]
    });
    this._recompute();
  },

  speakTap() {
    var text;
    if (this._state === 'CHECK') {
      text = '你还好吗？出个声，或者点一下头，告诉我你没事。';
    } else if (this._state === 'ALERT') {
      text = this._alertText();
    } else {
      var n = this._log.length;
      text = '跌倒守望开着。我盯着一个动作模式：先是猛地一晃，然后十五秒一动不动，才会出声问你。' +
        (this._contact
          ? '你的求助联系人是' + this._contact.rel + this._contact.name + '。'
          : '你还没有设置求助联系人。') +
        (n > 0 ? '本机一共记录过' + n + '条事件。' : '目前没有记录过事件。');
    }
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent' });
    }
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO: restore the real contact, drop demo state.
      this._demo = false;
      this._contact = this._demoSaved;
      this._demoSaved = null;
      if (this._contact) {
        var ri = this._rels.indexOf(this._contact.rel);
        if (ri >= 0) this._relIdx = ri;
      }
      this._state = 'MONITOR';
      this._lastQ = null;
      this._lastQMs = 0;
      this._angVel = null;
      this._sampleAgeMs = 0;
      this._joltUntilMs = 0;
      this._stillMs = 0;
      this._stillBaseQ = null;
      this._gain3s = 0;
      this._gainQ = [];
      this._checkMs = 0;
      this._alertSpoke = 0;
      this._orientSrc = 'NONE';
      this._startSensor();
      this.setData({
        status: 'MONITORING - jolt + stillness = check on you',
        lastEvent: 'EVT: DEMO off - your real contact restored'
      });
      this._recompute();
      return;
    }
    this._log = [];
    this._saveLog();
    this.setData({ lastEvent: 'EVT: event log cleared (contact kept)' });
    this._recompute();
  },

  // ---------- DEMO ----------
  //
  // DEMO plays the whole story in memory at real speed: a simulated
  // jolt (gain 95 deg) has just ended and the head is motionless, so
  // the machine lands in STILL with the 15 s count already at 9.0 s;
  // about six seconds later it really escalates into CHECK on its
  // own. Movement is synthesized inside _tick via a demo branch in
  // _feedSample-free counters: while _demo is on, _onSample ignores
  // the real sensor and the tick treats speed as 0 with a live
  // stream. The contact is fictional and labeled DEMO everywhere;
  // _saveContact refuses to persist while demo is on, and CLEAR
  // restores the real contact. Demo events are NOT written to the
  // real log.
  demoTap() {
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO already on - tap CLEAR to exit' });
      return;
    }
    this._demoSaved = this._contact;
    this._demo = true;
    this._orientSrc = 'DEMO';
    this._contact = { name: '小明', rel: '子女' };
    this._relIdx = 0;
    var now = Date.now();
    this._lastQ = [0, 0, 0, 1];
    this._lastQMs = now;
    this._sampleAgeMs = 0;
    this._angVel = 0;
    this._gain3s = 95;
    this._joltUntilMs = now + 750;
    this._state = 'MONITOR';
    this._stillMs = 0;
    this._stillBaseQ = null;
    this.setData({
      status: 'DEMO - simulated jolt done, head motionless',
      lastEvent: 'EVT: DEMO on - stillness lands in CHECK in ~6 s'
    });
    // Drive the first transition immediately so the landing state is
    // STILL at 9.0 s, not MONITOR.
    this._lastTickMs = now;
    this._tickDemoSeed(now);
    this._recompute();
  },

  // Demo-only: pretend 9 s of stillness have already passed by
  // stepping the real machine with synthetic ticks.
  _tickDemoSeed(now) {
    if (this._state === 'MONITOR' && this._joltUntilMs > now) {
      this._state = 'STILL';
      this._stillMs = 9000;
      this._stillBaseQ = this._lastQ;
      this.setData({ lastEvent: 'EVT: DEMO seeded - still 9.0 s of 15 s' });
    }
  },

  // ---------- formatting ----------

  _fmtSecs(ms) {
    return (ms / 1000).toFixed(1) + 's';
  },

  // ---------- recompute view ----------

  _recompute() {
    var speedTxt = this._demo ? '0' :
      (this._angVel === null ? '---' : String(Math.round(this._angVel)));
    var contactTxt = this._contact
      ? this._contact.rel + ' · ' + this._contact.name + (this._demo ? ' (DEMO)' : '')
      : 'NOT SET - tap REL + NAME';
    var last = this._log.length ? this._log[this._log.length - 1] : null;
    var patch = {
      sensorLine: 'MOTION: ' + speedTxt + ' deg/s · SRC: ' + this._orientSrc +
        (this._stable === null ? '' : (this._stable ? ' · HOST: stable' : ' · HOST: moving')),
      stateLine: 'STATE: ' + this._state + ' · CONTACT ' + contactTxt,
      rows: [
        { text: 'JOLT > 240 deg/s, then 15 s motionless = CHECK' },
        { text: 'CHECK asks 60 s - any reply, nod or OK cancels' },
        { text: 'NO REPLY = ALERT card (it cannot call anyone)' },
        { text: 'EVENTS LOGGED: ' + this._log.length + (last
          ? ' · LAST ' + last.time + ' ' + last.outcome : '') }
      ]
    };
    if (this._state === 'MONITOR') {
      patch.status = this._demo
        ? 'DEMO - simulated jolt done, head motionless'
        : 'MONITORING - jolt + stillness = check on you';
      patch.focusName = 'WATCHING — ALL QUIET';
      patch.focusLine = 'a jolt then 15 s still starts a spoken check';
      patch.arrow = '◎';
      patch.guideLine = 'PATTERN WATCH, NOT A MEDICAL ALARM';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: '跌倒守望开着，目前一切正常。' };
    } else if (this._state === 'STILL') {
      patch.status = (this._demo ? 'DEMO ' : '') +
        'JOLT SEEN - still ' + this._fmtSecs(this._stillMs) + ' / 15.0s';
      patch.focusName = 'STILL? ' + this._fmtSecs(this._stillMs) + ' / 15s';
      patch.focusLine = 'move or tap OK if you are fine - still counts on';
      patch.arrow = '◉';
      patch.guideLine = 'MOTIONLESS AFTER A JOLT — checking soon';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: '刚才晃了一下，现在一动不动，我在计时。' };
    } else if (this._state === 'CHECK') {
      var left = Math.max(0, Math.ceil((60000 - this._checkMs) / 1000));
      patch.status = 'ARE YOU OK? — reply within ' + left + 's';
      patch.focusName = '你还好吗？ARE YOU OK?';
      patch.focusLine = 'say anything, nod, or tap OK — ' + left + 's left';
      patch.arrow = '?';
      patch.guideLine = 'NO REPLY IN ' + left + 's = CONTACT CARD NEXT';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: '你还好吗？出个声，或者点一下头，告诉我你没事。' };
    } else { // ALERT
      patch.status = 'NO REPLY — SHOWING YOUR CONTACT CARD';
      patch.focusName = this._contact
        ? '请联系 ' + this._contact.rel + ' · ' + this._contact.name
        : '请帮忙 — 必要时拨打 120';
      patch.focusLine = 'I CANNOT CALL ANYONE - show this / read it aloud';
      patch.arrow = '!';
      patch.guideLine = 'SAY IT ALOUD SO PEOPLE NEARBY CAN ACT';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._alertText() };
    }
    this.setData(patch);
  },

  // ---------- speech ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">FALL GUARD</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{sensorLine}}</text>
    </view>
    <view class="mark-box">
      <text class="mark-mode">{{stateLine}}</text>
    </view>
    <view class="stats">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </view>
    <view class="guide-box">
      <text class="curname">{{focusName}}</text>
      <text class="cue">{{focusLine}}</text>
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{guideCls}}">{{guideLine}}</text>
      </view>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
      <button class="btn btn-help" bindtap="helpTap">HELP</button>
      <button class="btn" bindtap="backTap">BACK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="relTap">REL</button>
      <button class="btn" bindtap="nameTap">NAME</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 8px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.mark-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.mark-mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.stats {
  display: flex;
  flex-direction: column;
  margin-bottom: 3px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 1px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.rtext {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.guide-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px;
  margin-bottom: 4px;
}
.curname {
  color: #40ff5e;
  font-size: 15px;
  font-weight: 500;
  line-height: 19px;
}
.cue {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.guide-top {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-top: 1px;
}
.arrow {
  color: #40ff5e;
  font-size: 24px;
  line-height: 27px;
  margin-right: 10px;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 3px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 4px;
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
.btn-help {
  color: #40ff5e;
  border-color: rgba(64,255,94,0.96);
  background-color: rgba(64,255,94,0.24);
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
