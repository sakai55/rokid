<script def>
{
  "navigationBarTitleText": "Speaker Focus"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'FACE A SEAT, TAP SEAT + SAY THE NAME',
    steadyText: 'HEAD: moving - hold still',
    headLine: 'HEAD: --- deg · SRC: NONE',
    facingLine: 'FACING: - (no seats registered yet)',
    seatsLine: 'SEATS (0/6): none',
    micLine: 'MIC CHECK: not run',
    levelLine: 'LVL: ---------- (far-field feed: check only)',
    lastLine: 'LAST: - (LISTEN, then face who is talking)',
    minHead: 'MINUTES: 0/30 segs · TEXT only - no audio kept',
    min1: '·',
    min2: '·',
    min3: '·',
    min4: '·',
    honestLine: 'tags = where you FACED, not who spoke',
    honestLine2: 'far-field = level check only · words via host ASR',
    lastEvent: 'EVT: tap(Enter)=LISTEN · swipe=scroll · nod(steady)=LISTEN',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._seats = [];          // {name, headingDeg, src} - TEXT only, persisted
    this._segments = [];       // {date, time, seat, text} - TEXT only, persisted
    this._heading = null;
    this._headingSrc = 'NONE';
    this._sensor = null;
    this._steady = false;
    this._timer = null;
    this._listening = false;
    this._recog = null;
    this._nameRec = null;
    this._pendingSeat = null;  // {headingDeg, chipMode} while naming a seat
    this._chipIdx = 0;
    this._chips = ['座位1', '座位2', '座位3', '座位4', '座位5', '座位6', '主持人', '客户'];
    this._clearArmed = false;
    this._viewEnd = 0;         // minutes window: last shown segment index + 1
    this._demo = false;
    this._demoSaved = null;
    this._demoHeading = 0;
    this._demoSegIdx = 0;
    this._checkStream = null;
    this._loadAll();
    this._startHeading();
    this._startTimer();
    this._renderAll();
  },

  onShow() {
    this._startTimer();
    if (!this._sensor) this._startHeading();
  },

  onHide() {
    this._stopTimer();
    this._stopRecog();
    this._stopNameRec();
    this._listening = false;
  },

  onUnload() {
    this._stopTimer();
    this._stopRecog();
    this._stopNameRec();
    this._stopHeading();
    this._stopCheckStream();
    // Seats + minutes are TEXT in wx storage; no audio exists anywhere.
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // A steady nod starts a LISTEN round when idle - and only that.
    // It never registers a seat and never clears minutes: naming and
    // wiping always need a deliberate tap (brief discipline).
    if (this.data.busy) {
      this.setData({ lastEvent: 'EVT: nod ignored - busy' });
      return;
    }
    if (this._pendingSeat) {
      this.setData({ lastEvent: 'EVT: nod ignored - naming a seat (nod never names)' });
      return;
    }
    if (this._listening) {
      this.setData({ lastEvent: 'EVT: nod ignored - already listening' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady (nod = LISTEN)' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod (steady) = LISTEN round' });
    this._startListen();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier section 3.2.1): single tap arrives
  // as Enter, double-tap as Backspace, swipe as ArrowUp/ArrowDown.
  // The main flow - register seats, run listen rounds, read the
  // minutes back - runs on these keys + head-steady + nod; the
  // on-screen buttons mirror the same actions for tapping.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._pendingSeat) {
        this._enterNaming();
      } else {
        this.setData({ lastEvent: 'EVT: tap (Enter) = LISTEN ' + (this._listening ? 'stop' : 'round') });
        this.listenTap();
      }
    } else if (code === 'ArrowUp') {
      if (this._pendingSeat && this._pendingSeat.chipMode) this._cycleChip(1, 'swipe');
      else this._scrollMinutes(-1, 'swipe');
    } else if (code === 'ArrowDown') {
      if (this._pendingSeat && this._pendingSeat.chipMode) this._cycleChip(-1, 'swipe');
      else this._scrollMinutes(1, 'swipe');
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: double-tap (Backspace) back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- small helpers (sibling discipline) ----------

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // Wall-clock strings from ONE Date snapshot per call - demo seeds
  // and segment stamps never mix samples from a drifting clock.
  _stamp() {
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      time: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _rel(targetDeg, current) {
    return ((targetDeg - current + 540) % 360) - 180; // -180..180, + = right
  },

  _signed(deg) {
    var s = ((deg + 180) % 360 + 360) % 360 - 180;
    return (s > 0 ? '+' : '') + s;
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  // ---------- persistence (TEXT only - seats + minutes) ----------

  _loadAll() {
    try {
      var s = wx.getStorageSync('speakerSeats');
      if (s && s.seats && s.seats.length) {
        for (var i = 0; i !== s.seats.length && this._seats.length < 6; i++) {
          var it = s.seats[i];
          if (it && typeof it.name === 'string' && typeof it.headingDeg === 'number') {
            this._seats.push({ name: it.name, headingDeg: it.headingDeg, src: it.src || 'ASR' });
          }
        }
      }
    } catch (e) { /* storage unavailable: seats stay in memory */ }
    try {
      var m = wx.getStorageSync('speakerMinutes');
      if (m && m.segments && m.segments.length) {
        for (var j = 0; j !== m.segments.length && this._segments.length < 30; j++) {
          var sg = m.segments[j];
          if (sg && typeof sg.text === 'string') {
            this._segments.push({
              date: sg.date || '', time: sg.time || '',
              seat: sg.seat || '朝向未登记', text: sg.text
            });
          }
        }
      }
    } catch (e) { /* storage unavailable: minutes stay in memory */ }
    this._viewEnd = this._segments.length;
  },

  _saveSeats() {
    // DEMO state is a simulation: never overwrite the real record.
    if (this._demo) return;
    try {
      var seats = [];
      for (var i = 0; i !== this._seats.length; i++) {
        var s = this._seats[i];
        seats.push({ name: s.name, headingDeg: s.headingDeg, src: s.src });
      }
      wx.setStorageSync('speakerSeats', { seats: seats });
    } catch (e) { /* storage unavailable on this host: memory only */ }
  },

  _saveMinutes() {
    if (this._demo) return;
    try {
      var segs = [];
      for (var i = 0; i !== this._segments.length; i++) {
        var g = this._segments[i];
        // Notes only: time, facing tag, verbatim words. No audio
        // exists at any point in this agent - nothing to leak here.
        segs.push({ date: g.date, time: g.time, seat: g.seat, text: g.text });
      }
      var st = this._stamp();
      wx.setStorageSync('speakerMinutes', { date: st.date, segments: segs });
    } catch (e) { /* storage unavailable on this host: memory only */ }
  },

  // ---------- heading (AbsoluteOrientationSensor, same as siblings) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._renderAll();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onHeading(s); });
      s.addEventListener('error', function (ev) {
        self._headingSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - heading NONE' });
        self._renderAll();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._headingSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopHeading() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  _yawDeg(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    var deg = yaw * 180 / Math.PI;
    return (deg + 360) % 360;
  },

  _onHeading(sensor) {
    if (this._demo) return; // demo heading wins while simulating
    var deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    var changed = this._heading === null || Math.abs(deg - this._heading) >= 1;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (changed) this._renderAll();
  },

  // 250ms tick: poll the sensor (preview hosts may not fire
  // 'reading') so FACING follows the head everywhere.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- seat math: tags are FACING, never identity ----------

  // The seat you are facing: the registered seat with the smallest
  // |relative angle|, and only inside a +-30 deg cone. A tie on
  // |rel| goes to the seat registered earlier. null when you face
  // no registered seat (or have no heading / no seats).
  _nearestSeat(heading) {
    if (heading === null || heading === undefined) return null;
    var best = null, bestAbs = 31; // must beat 31, i.e. |rel| <= 30
    for (var i = 0; i !== this._seats.length; i++) {
      var a = Math.abs(this._rel(this._seats[i].headingDeg, heading));
      if (a <= 30 && a < bestAbs) { best = this._seats[i]; bestAbs = a; }
    }
    return best;
  },

  _facingSeat() { return this._nearestSeat(this._heading); },

  // ---------- SEAT registration (face it, name it) ----------

  seatTap() {
    if (this.data.busy) return;
    this._clearArmed = false;
    if (this._pendingSeat) {
      if (this._pendingSeat.chipMode) {
        this._cycleChip(1, 'button');
      } else {
        this.setData({ lastEvent: 'EVT: naming in progress - say the name, or tap (Enter) for a preset name' });
      }
      return;
    }
    if (this._listening) {
      this.setData({ lastEvent: 'EVT: SEAT ignored - stop LISTEN first' });
      return;
    }
    if (this._seats.length >= 6) {
      this.setData({
        status: 'SEATS FULL (6/6) - no more seats this table',
        lastEvent: 'EVT: SEAT refused - cap 6 reached'
      });
      return;
    }
    if (this._heading === null) {
      // No heading, no seat: a direction tag without a direction is
      // worthless, so refuse honestly instead of inventing one.
      this.setData({
        status: 'SEAT FAIL - no heading on this host; cannot bind a seat',
        lastEvent: 'EVT: SEAT refused - heading NONE (never invented)'
      });
      return;
    }
    this._pendingSeat = { headingDeg: Math.round(this._heading) % 360, chipMode: false };
    if (this._demo) {
      this._registerSeat('演示座位' + (this._seats.length + 1), 'DEMO');
      return;
    }
    if (typeof SpeechRecognition !== 'undefined') {
      this._nameListen();
    } else {
      this._enterChipMode('no recogniser on this host');
    }
  },

  _enterChipMode(why) {
    if (!this._pendingSeat) return;
    this._pendingSeat.chipMode = true;
    this._chipIdx = 0;
    this.setData({
      status: 'NAME? ' + this._chips[0] + ' - SEAT/swipe = next, tap(Enter) = use it',
      lastEvent: 'EVT: preset name chips (' + why + ') - labelled, not listened'
    });
    this._renderAll();
  },

  _cycleChip(dir, src) {
    if (!this._pendingSeat || !this._pendingSeat.chipMode) return;
    var n = this._chips.length;
    this._chipIdx = (((this._chipIdx + dir) % n) + n) % n;
    this.setData({
      status: 'NAME? ' + this._chips[this._chipIdx] + ' - SEAT/swipe = next, tap(Enter) = use it',
      lastEvent: 'EVT: ' + src + ' -> name chip ' + this._chips[this._chipIdx]
    });
  },

  // Enter while naming: confirm the chip in chip mode; in ASR mode
  // it bails out of listening into the labelled chip fallback.
  _enterNaming() {
    if (!this._pendingSeat) return;
    if (this._pendingSeat.chipMode) {
      var name = this._chips[this._chipIdx];
      this.setData({ lastEvent: 'EVT: tap (Enter) = use preset name ' + name });
      this._registerSeat(name, 'chip');
    } else {
      this._stopNameRec();
      this.setData({ busy: false });
      this._enterChipMode('you chose a preset name');
    }
  },

  _registerSeat(name, src) {
    if (!this._pendingSeat) return;
    var seat = { name: name, headingDeg: this._pendingSeat.headingDeg, src: src };
    this._seats.push(seat);
    this._pendingSeat = null;
    this._saveSeats();
    this.setData({
      status: 'SEAT SAVED: ' + name + ' @' + this._signed(seat.headingDeg) + ' deg (' + this._seats.length + '/6)',
      lastEvent: 'EVT: seat registered - ' + name + ' bound to the direction you face, not a voice'
    });
    this._renderAll();
  },

  _stopNameRec() {
    if (this._nameRec) {
      try { this._nameRec.abort(); } catch (e) {}
      this._nameRec = null;
    }
  },

  // Naming dictation: wearer-mode mic AVAILABILITY check first
  // (queue-sense pattern), then the host recogniser hears the name
  // on its own mic. The name is stored VERBATIM.
  async _nameListen() {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    var micNote = 'MIC CHECK: not run';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic check');
        var settings = {};
        try {
          var tr = ms.getAudioTracks()[0];
          if (tr && tr.getSettings) settings = tr.getSettings();
        } catch (e) {}
        micNote = 'MIC CHECK: wearer OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        // The check stream is stopped BEFORE recognition starts -
        // it is an availability check, never the ASR input.
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        micNote = 'MIC CHECK: FAIL - ' + this._err(e);
      }
    }
    this.setData({ micLine: micNote });
    if (!this._pendingSeat) { this.setData({ busy: false }); return; }
    try {
      this._stopNameRec();
      var rec = new SpeechRecognition();
      this._nameRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) { self._enterChipMode('empty name heard'); return; }
          // VERBATIM: the name is whatever was said, stored as-is.
          self._registerSeat(txt, 'ASR');
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        if (self._nameRec === rec) self._nameRec = null;
        self.setData({ busy: false });
        self._enterChipMode('ASR error - ' + self._err(ev && ev.error ? ev.error : ev));
      };
      rec.onend = function () {
        if (self._nameRec === rec) self._nameRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'NAME? listening (host ASR) - say the name for @' +
          this._signed(this._pendingSeat.headingDeg) + ' deg',
        lastEvent: 'EVT: naming via host ASR (' + micNote + ')'
      });
    } catch (e) {
      this.setData({ busy: false });
      this._enterChipMode('recogniser would not start');
    }
  },

  // ---------- far-field CHECK (availability + level feed ONLY) ----------

  _stopCheckStream() {
    if (this._checkStream) {
      try { this._checkStream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._checkStream = null;
    }
  },

  // The far-field microphoneMode applies ONLY to this getUserMedia
  // stream (dossier sections 2.4 / 2.8): we open it, read back the
  // selected mode, show the room level it hears for a moment, then
  // STOP every track. It can NOT and does NOT feed the host
  // SpeechRecognition below - recognition always runs on the host's
  // own microphone. Ordering is part of the contract: check tracks
  // are fully stopped before rec.start() is ever called.
  async _farFieldCheck() {
    var self = this;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        micLine: 'MIC CHECK: n/a (no getUserMedia) - ASR uses host mic',
        levelLine: 'LVL: n/a (no mic stream on this host)'
      });
      return;
    }
    var stream = null;
    var fellBack = false;
    try {
      try {
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'far-field', echoCancellation: true }
        }), 6000, 'far-field check');
      } catch (eMode) {
        // media.md: not every device supports every mode - fall back
        // to the default microphone and say so, do not fake the mode.
        if (!eMode || eMode.name !== 'OverconstrainedError') throw eMode;
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 6000, 'mic');
        fellBack = true;
      }
      this._checkStream = stream;
      var mode = '';
      try {
        var tr = stream.getAudioTracks()[0];
        if (tr && tr.getSettings) mode = tr.getSettings().microphoneMode || '';
      } catch (e) {}
      var checkNote = fellBack
        ? 'MIC CHECK: default mic (far-field n/a here) - level only'
        : 'MIC CHECK: far-field OK' + (mode ? ' (' + mode + ')' : '') + ' - level only';
      this.setData({ micLine: checkNote });
      // Short live level readout from the check feed (~0.6 s), then
      // the stream is stopped for good before ASR starts.
      if (typeof AudioContext !== 'undefined') {
        var actx = null;
        try {
          actx = new AudioContext();
          await actx.resume();
          var srcNode = actx.createMediaStreamSource(stream);
          var an = actx.createAnalyser();
          an.fftSize = 2048;
          srcNode.connect(an); // analyser only - never to destination
          var buf = new Float32Array(an.fftSize);
          for (var tick = 0; tick !== 6; tick++) {
            an.getFloatTimeDomainData(buf);
            var sum = 0;
            for (var i = 0; i !== buf.length; i++) sum += buf[i] * buf[i];
            var lvl = Math.min(1, Math.sqrt(sum / buf.length) * 3);
            self.setData({
              levelLine: 'LVL: ' + self._levelBar(lvl) + ' room level (far-field feed)'
            });
            await new Promise(function (res) { setTimeout(res, 100); });
          }
          try { srcNode.disconnect(); } catch (e) {}
        } catch (e) {
          this.setData({ levelLine: 'LVL: n/a (Web Audio failed on this host)' });
        } finally {
          if (actx) { try { await actx.close(); } catch (e) {} }
        }
      } else {
        this.setData({ levelLine: 'LVL: n/a (Web Audio n/a on this host)' });
      }
    } catch (e) {
      this.setData({
        micLine: 'MIC CHECK: FAIL - ' + this._err(e) + ' - ASR still uses host mic',
        levelLine: 'LVL: n/a (mic check failed)'
      });
    } finally {
      // STOPPED - before any recognition starts. This stream never
      // reaches the recogniser; it was a check + a level meter.
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        if (this._checkStream === stream) this._checkStream = null;
      }
    }
  },

  // ---------- LISTEN round (host ASR, tagged by facing) ----------

  listenTap() {
    if (this.data.busy) return;
    this._clearArmed = false;
    if (this._pendingSeat) {
      this.setData({ lastEvent: 'EVT: LISTEN ignored - finish naming the seat first' });
      return;
    }
    if (this._listening) {
      this._stopRecog();
      this._listening = false;
      this.setData({
        status: 'LISTEN round stopped - ' + this._segments.length + ' segs in minutes',
        lastEvent: 'EVT: listen round stopped by tap'
      });
      this._renderAll();
      return;
    }
    this._startListen();
  },

  async _startListen() {
    if (this._demo) { this._demoListen(); return; }
    this.setData({ busy: true, status: 'LISTEN: far-field check first...' });
    await this._farFieldCheck();
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host - nothing is
      // captioned, and we say so instead of faking a round.
      this.setData({
        busy: false,
        status: 'LISTEN SKIP - no recogniser on this host; nothing captioned',
        lastEvent: 'EVT: LISTEN skipped honestly (ASR n/a)'
      });
      return;
    }
    var self = this;
    try {
      this._stopRecog();
      var rec = new SpeechRecognition();
      this._recog = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      try { rec.continuous = true; } catch (e) {}
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // Tag with the heading AT THIS MOMENT: the seat you are
          // facing as the words land - facing, never identity.
          self._addSegment(txt);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        if (self._recog === rec) self._recog = null;
        self._listening = false;
        self.setData({
          busy: false,
          status: 'LISTEN FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + '; tap LISTEN again',
          lastEvent: 'EVT: LISTEN ASR error - round ended'
        });
        self._renderAll();
      };
      rec.onend = function () {
        if (self._recog === rec) self._recog = null;
        if (self._listening) {
          self._listening = false;
          self.setData({
            busy: false,
            status: 'LISTEN round ended - ' + self._segments.length + ' segs in minutes'
          });
          self._renderAll();
        }
      };
      rec.start();
      this._listening = true;
      this.setData({
        busy: false,
        status: 'LISTENING (host ASR) - face who is talking',
        lastEvent: 'EVT: ASR round started (host mic) after far-field check stopped'
      });
      this._renderAll();
    } catch (e) {
      this.setData({
        busy: false,
        status: 'LISTEN FAIL - recogniser would not start',
        lastEvent: 'EVT: LISTEN start failed - ' + this._err(e)
      });
    }
  },

  _stopRecog() {
    if (this._recog) {
      try { this._recog.abort(); } catch (e) {}
      this._recog = null;
    }
  },

  _addSegment(text) {
    var seat = this._facingSeat();
    var tag = seat ? seat.name : '朝向未登记';
    var st = this._stamp();
    this._segments.push({ date: st.date, time: st.time, seat: tag, text: text });
    var dropped = false;
    if (this._segments.length > 30) { this._segments.shift(); dropped = true; }
    this._viewEnd = this._segments.length;
    this._saveMinutes();
    this.setData({
      lastLine: 'LAST: [' + tag + '] ' + text.slice(0, 34),
      lastEvent: 'EVT: seg ' + this._segments.length + '/30 tagged [' + tag + '] by facing' +
        (dropped ? ' - oldest dropped (cap 30)' : '')
    });
    this._renderAll();
  },

  // ---------- LIST (minutes window) ----------

  listTap() {
    this._clearArmed = false;
    this._viewEnd = this._segments.length;
    this.setData({
      status: this._segments.length
        ? 'MINUTES: newest shown - swipe scrolls, SPEAK reads all'
        : 'MINUTES: empty - LISTEN a round first',
      lastEvent: 'EVT: LIST - window at newest (' + this._segments.length + ' segs)'
    });
    this._renderAll();
  },

  _scrollMinutes(dir, src) {
    var len = this._segments.length;
    if (!len) {
      this.setData({ lastEvent: 'EVT: ' + src + ' - no minutes to scroll' });
      return;
    }
    var minEnd = Math.min(4, len);
    this._viewEnd = Math.max(minEnd, Math.min(len, this._viewEnd + dir));
    this.setData({ lastEvent: 'EVT: ' + src + ' -> minutes window ends at ' + this._viewEnd + '/' + len });
    this._renderAll();
  },

  // ---------- SPEAK (minutes readback, grouped by facing) ----------

  // Groups segments by their facing tag in first-appearance order.
  // The wording is pinned: every group is "the direction you were
  // facing" - the tag is NEVER spoken as who the speaker was.
  _speakText() {
    if (!this._segments.length) {
      return '还没有纪要。先把脸朝向一个座位登记名字，再点聆听，朝向正在说话的人。';
    }
    var order = [];
    var byTag = {};
    for (var i = 0; i !== this._segments.length; i++) {
      var g = this._segments[i];
      if (!byTag[g.seat]) { byTag[g.seat] = []; order.push(g.seat); }
      byTag[g.seat].push(g.text);
    }
    var parts = ['纪要共 ' + this._segments.length + ' 段。先说明：标注的只是你当时面对的方向，不是声音识别。'];
    for (var j = 0; j !== order.length; j++) {
      var tag = order[j];
      if (tag === '朝向未登记') {
        parts.push('有一段话记下时，你没有对着任何登记过的座位：' + byTag[tag].join('；'));
      } else {
        parts.push('你当时看着' + tag + '的方向时，记下：' + byTag[tag].join('；'));
      }
    }
    return parts.join('。');
  },

  speakTap() {
    if (this.data.busy) return;
    this._clearArmed = false;
    var text = this._speakText();
    var ok = this._speak(text);
    this.setData({
      status: ok ? 'MINUTES spoken - grouped by the way you FACED' : 'MINUTES below (TTS n/a on this host)',
      lastEvent: ok ? 'EVT: TTS minutes sent: ' + text.slice(0, 44) : 'EVT: SPEAK FAIL - speechSynthesis n/a here'
    });
  },

  // ---------- CLEAR (two-step, minutes only - seats kept) ----------

  clearTap() {
    if (this.data.busy) return;
    if (!this._clearArmed) {
      this._clearArmed = true;
      this.setData({
        status: 'CLEAR armed - tap CLEAR again to wipe minutes (seats kept)',
        lastEvent: 'EVT: CLEAR armed - nothing wiped yet'
      });
      return;
    }
    this._clearArmed = false;
    this._segments = [];
    this._viewEnd = 0;
    this._saveMinutes();
    this.setData({
      status: 'MINUTES wiped - ' + this._seats.length + ' seats kept',
      lastLine: 'LAST: - (minutes cleared)',
      lastEvent: 'EVT: minutes wiped (two-step) - seats kept, text record updated'
    });
    this._renderAll();
  },

  // ---------- DEMO (seeded table, memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    this._clearArmed = false;
    if (!this._demo) {
      this._demoSaved = {
        seats: this._seats, segments: this._segments,
        heading: this._heading, headingSrc: this._headingSrc,
        viewEnd: this._viewEnd
      };
      this._demo = true;
      this._demoHeading = 0;
      this._demoSegIdx = 0;
      this._seats = [
        { name: '王工', headingDeg: 320, src: 'DEMO' },
        { name: '李经理', headingDeg: 0, src: 'DEMO' },
        { name: '客户赵总', headingDeg: 45, src: 'DEMO' }
      ];
      var st = this._stamp();
      this._segments = [
        { date: st.date, time: st.time, seat: '李经理', text: '下周一把排期表发出来' },
        { date: st.date, time: st.time, seat: '王工', text: '接口文档我今晚更新' },
        { date: st.date, time: st.time, seat: '朝向未登记', text: '（有人插了一句，没对着登记的座位）' }
      ];
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._viewEnd = this._segments.length;
      this.setData({
        status: 'DEMO table - 3 seats; tap DEMO to turn your head +45 deg',
        lastLine: 'LAST: [朝向未登记] （有人插了一句…）',
        lastEvent: 'EVT: DEMO on - seeded seats + minutes in memory only, nothing written'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      if (this._demoHeading === 0) {
        var saved = this._demoSaved;
        this._demo = false;
        this._demoSaved = null;
        if (saved) {
          this._seats = saved.seats;
          this._segments = saved.segments;
          this._heading = saved.heading;
          this._headingSrc = saved.headingSrc;
          this._viewEnd = saved.viewEnd;
        }
        this.setData({
          status: 'DEMO OFF - your real seats + minutes are back',
          lastEvent: 'EVT: DEMO cleared - real record restored, nothing was written'
        });
      } else {
        this._heading = this._demoHeading;
        this._headingSrc = 'DEMO';
        this.setData({
          status: 'DEMO - head now at ' + this._demoHeading + ' deg; watch FACING',
          lastEvent: 'EVT: DEMO head stepped to ' + this._demoHeading + ' deg'
        });
      }
    }
    this._renderAll();
  },

  // A demo listen round: one canned line, tagged by the seat the
  // demo head is facing - the tagging mechanic, previewable.
  _demoListen() {
    var lines = [
      '这个季度的交付节点我们再对一次',
      '预算这边我没有异议',
      '上线时间能不能提前到周四'
    ];
    var text = lines[this._demoSegIdx % lines.length];
    this._demoSegIdx++;
    var seat = this._facingSeat();
    var tag = seat ? seat.name : '朝向未登记';
    var st = this._stamp();
    this._segments.push({ date: st.date, time: st.time, seat: tag, text: text });
    if (this._segments.length > 30) this._segments.shift();
    this._viewEnd = this._segments.length;
    this.setData({
      busy: false,
      status: 'DEMO seg tagged [' + tag + '] by facing (seeded line)',
      lastLine: 'LAST: [' + tag + '] ' + text.slice(0, 34) + ' (DEMO)',
      lastEvent: 'EVT: DEMO listen - canned line, tagged by facing, not saved'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _windowLines() {
    var len = this._segments.length;
    var end = Math.max(0, Math.min(len, this._viewEnd));
    var start = Math.max(0, end - 4);
    var lines = ['·', '·', '·', '·'];
    for (var i = start; i !== end; i++) {
      var g = this._segments[i];
      var mark = i === end - 1 ? '> ' : '  ';
      lines[i - start] = mark + g.time + ' [' + g.seat + '] ' + g.text.slice(0, 26);
    }
    return lines;
  },

  _renderAll() {
    var patch = {};
    patch.headLine = 'HEAD: ' + (this._heading === null ? '---' : Math.round(this._heading)) +
      ' deg · SRC: ' + this._headingSrc + (this._demo ? ' (DEMO)' : '');
    var f = this._facingSeat();
    if (f) {
      patch.facingLine = 'FACING: ' + f.name + ' @' + this._signed(f.headingDeg) + ' deg';
    } else if (!this._seats.length) {
      patch.facingLine = 'FACING: - (no seats registered yet)';
    } else if (this._heading === null) {
      patch.facingLine = 'FACING: - (no heading on this host)';
    } else {
      patch.facingLine = 'FACING: - (no seat within ±30 deg)';
    }
    if (this._pendingSeat) {
      patch.seatsLine = 'NAMING seat @' + this._signed(this._pendingSeat.headingDeg) +
        ' deg...' + (this._pendingSeat.chipMode ? ' (preset chips)' : ' (say the name)');
    } else if (this._seats.length) {
      var parts = [];
      for (var i = 0; i !== this._seats.length; i++) {
        parts.push(this._seats[i].name + '@' + this._signed(this._seats[i].headingDeg));
      }
      var line = 'SEATS (' + this._seats.length + '/6): ' + parts.join(' · ');
      patch.seatsLine = line.length > 62 ? line.slice(0, 62) : line;
    } else {
      patch.seatsLine = 'SEATS (0/6): none - face a seat, tap SEAT';
    }
    patch.minHead = 'MINUTES: ' + this._segments.length + '/30 segs · TEXT only - no audio kept';
    var w = this._windowLines();
    patch.min1 = w[0]; patch.min2 = w[1]; patch.min3 = w[2]; patch.min4 = w[3];
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">SPEAKER FOCUS</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{headLine}}</text>
    </view>
    <view class="info-box">
      <text class="facing">{{facingLine}}</text>
      <text class="photo">{{seatsLine}}</text>
      <text class="photo">{{micLine}}</text>
      <text class="photo">{{levelLine}}</text>
      <text class="photo">{{lastLine}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">◎ MINUTES - tagged by the seat you FACED</text>
      <text class="photo">{{minHead}}</text>
      <text class="min">{{min1}}</text>
      <text class="min">{{min2}}</text>
      <text class="min">{{min3}}</text>
      <text class="min">{{min4}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="seatTap">SEAT</button>
      <button class="btn btn-main" bindtap="listenTap">LISTEN</button>
      <button class="btn" bindtap="listTap">LIST</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="sub">{{honestLine}}</text>
    <text class="sub">{{honestLine2}}</text>
    <text class="foot">{{lastEvent}}</text>
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
.facing {
  color: #40ff5e;
  font-size: 16px;
  font-weight: 500;
  line-height: 20px;
  margin-top: 2px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.min {
  color: rgba(64,255,94,0.72);
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
</style>
