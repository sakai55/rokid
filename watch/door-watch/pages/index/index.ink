<script def>
{
  "navigationBarTitleText": "Door Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'FACE THE DOOR FROM YOUR SEAT, TAP SET - I KEEP AN EAR OUT',
    headLine: 'HEAD: --- deg · SRC: NONE · HEAD: moving - hold still',
    doorLine: 'DOOR: not registered - face the door and tap SET',
    alertLine: 'NO ALERT - no loud pattern is waiting',
    alertCls: 'alert',
    listenLine: 'LISTEN: off · LVL: ---------- 0',
    nudgeLine: 'PATTERN: level shapes only - NOT doorbell / knock recognition',
    focusName: '▸ 门口守望',
    focusCue: '坐在你平常的位置看着门点 SET：把方向登记下来',
    guideLine: 'NO DOOR YET - the direction I report comes from your registration',
    guideCls: 'rel',
    lastEvent: 'EVT: I watch the door noises - you work',
    busy: false
  },

  onLoad() {
    // 250ms tick engine, same discipline as the siblings: dwell,
    // pattern segments and re-arm quiet all accumulate TICK
    // COUNTS, never re-sampled wall-clock deltas.
    this._TICK_MS = 250;
    this._LABELS = ['正门', '后门', '院门'];
    // Sensitivity scales LEVEL thresholds only. Base: spike peak
    // 0.60, bell floor 0.50 (RMS 0..1 after the x3 meter gain).
    this._SENS = [
      { name: '灵敏', f: 0.75 },
      { name: '标准', f: 1.0 },
      { name: '安静屋', f: 1.25 }
    ];
    this._SPIKE_BASE = 0.60;
    this._BELL_BASE = 0.50;
    this._ACK_CONE = 15;     // face-the-door cone for look ack (deg)
    this._ACK_TICKS = 4;     // 4 ticks x 250ms = 1s facing = acknowledged
    this._REARM_TICKS = 40;  // 40 ticks of quiet = 10s = re-arm
    this._BURST_WIN = 20;    // 2 spikes within 20 ticks (5s) = a burst
    this._door = null;       // { labelIdx, headingDeg }
    this._setup = null;      // { labelIdx, headingDeg }
    this._sensIdx = 1;       // 标准
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._sensor = null;
    this._timer = null;
    this._tickCount = 0;
    this._alertPending = false;
    this._ackTicks = 0;
    this._nudgeCount = 0;
    this._lastNudge = '';
    // microphone level stream (LISTEN)
    this._listening = false;
    this._stream = null;
    this._actx = null;
    this._analyser = null;
    this._srcNode = null;
    this._buf = null;
    this._micLabel = 'off';
    this._curLevel = 0;
    // pattern engine state (segments on the tick clock)
    this._seg = null;        // { start, peak } while level >= bell floor
    this._spikes = [];       // tick stamps of completed spike candidates
    this._armed = true;
    this._quietTicks = 0;
    // demo state
    this._demo = false;
    this._demoSteps = 0;
    this._demoTicks = 0;
    this._demoAcked = false;
    this._realDoor = null;
    this._realSens = 1;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopHeading();
    this._stopListen(true);
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopListen(true);
  },

  onOrientationStabilityChange(event) {
    if (this._demo) return; // demo simulates a held-still head
    this._steady = !!(event && event.stable);
    if (!this._steady) this._ackTicks = 0;
    this._recompute();
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // Nod discipline: a steady nod only ever SPEAKS the status.
    // A nod never registers the door, never acknowledges a nudge,
    // never starts or stops the listen watch - facing the door
    // (or a deliberate tap) is what closes the loop.
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: nod ignored - finish or cancel SET first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod = speak the status (never ack)' });
    this.speakTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier section 3.2.1): single tap = Enter,
  // double-tap = Backspace, swipe = ArrowUp/ArrowDown. The whole
  // main flow (register, watch, face ack, hear status) runs on
  // these keys + head-steady + nod.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (Enter) = primary action' });
      this._primaryTap();
    } else if (code === 'ArrowDown') {
      if (this._setup) this._setupCycle(1);
      else this._sensCycle(1);
    } else if (code === 'ArrowUp') {
      if (this._setup) this._setupCycle(-1);
      else this._sensCycle(-1);
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

  // Context primary action behind a single tap (Enter): setting
  // up -> confirm the registration; a nudge is waiting -> ack it;
  // no door yet -> start registering; otherwise -> speak status.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._setup) { this._confirmSetup(); return; }
    if (this._alertPending) { this._ack('tap'); return; }
    if (!this._door) { this._enterSetup(); return; }
    this.speakTap();
  },

  // ---------- helpers ----------

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _headText(h) {
    return (h === null || h === undefined || !isFinite(h)) ? '---' : String(Math.round(h));
  },

  // Relative-angle math, same convention as the siblings:
  // rel = target - current, normalised to -180..180, + = right.
  _rel(targetDeg, current) {
    return ((targetDeg - current + 540) % 360) - 180;
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _spikeThr() { return this._SPIKE_BASE * this._SENS[this._sensIdx].f; },
  _bellThr() { return this._BELL_BASE * this._SENS[this._sensIdx].f; },

  // ---------- heading (AbsoluteOrientationSensor, same as siblings) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._recompute();
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
        self._recompute();
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
    if (changed) this._recompute();
  },

  // ---------- the tick engine ----------

  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._tick();
    }, this._TICK_MS);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _tick() {
    this._tickCount = (this._tickCount || 0) + 1;
    if (this._demo) this._demoTicks += 1;
    if (this._listening) this._sampleLevel();
    this._ackDwellTick();
    if (this._tickCount % 4 === 0) this._recompute();
  },

  // ---------- the pattern engine (LEVEL SHAPES ONLY) ----------

  // This platform has NO sound classification and NO sound
  // localisation. The engine below never hears "a doorbell" or
  // "a knock" - it only watches the SHAPE of the loudness level:
  //   spike candidate: a loud segment (peak >= spike threshold)
  //     lasting at most 2s before it falls;
  //   burst: 2 spike candidates completing within 5s of each
  //     other (knock-shaped);
  //   bell shape: one segment at moderate loudness (bell floor
  //     up to spike threshold) sustained 1-3s, then falling.
  // A lone spike earns nothing. Sustained loud (a segment over
  // 3s: TV, a running tap, a call on speaker) earns nothing.

  _resetPattern() {
    this._seg = null;
    this._spikes = [];
    this._armed = true;
    this._quietTicks = 0;
  },

  _sampleLevel() {
    var lvl;
    if (this._demo) {
      lvl = this._demoLevel();
    } else {
      if (!this._analyser || !this._buf) return;
      this._analyser.getFloatTimeDomainData(this._buf);
      var sum = 0;
      for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
      lvl = Math.min(1, Math.sqrt(sum / this._buf.length) * 3);
    }
    this._curLevel = lvl;
    var bell = this._bellThr();
    if (lvl >= bell) {
      this._quietTicks = 0;
      if (!this._seg) this._seg = { start: this._tickCount, peak: lvl };
      else if (lvl > this._seg.peak) this._seg.peak = lvl;
    } else {
      if (this._seg) {
        var seg = this._seg;
        this._seg = null;
        this._endSegment(seg);
      }
      if (!this._armed) {
        this._quietTicks += 1;
        if (this._quietTicks >= this._REARM_TICKS) {
          this._armed = true;
          this.setData({ lastEvent: 'EVT: listen re-armed after 10s of quiet' });
          this._recompute();
        }
      }
    }
    this._recompute();
  },

  _endSegment(seg) {
    var dur = this._tickCount - seg.start; // ticks at/above the bell floor
    var spike = this._spikeThr();
    if (dur > 12) {
      // Over 3s of loud: sustained noise is deliberately NOT a
      // signal - it is too ambiguous to mean "someone at the door".
      this.setData({
        lastEvent: 'EVT: sustained loud segment (' + (dur / 4).toFixed(1) +
          's) ended - earns nothing (level shape only)'
      });
      return;
    }
    if (seg.peak >= spike && dur <= 8) {
      // A spike candidate. One alone is just a dropped pan or a
      // slammed drawer somewhere - it earns nothing by itself.
      var now = this._tickCount;
      this._spikes = this._spikes.filter(function (t) { return now - t <= 20; }, this);
      this._spikes.push(now);
      if (this._spikes.length >= 2) {
        this._spikes = [];
        this._patternFires('burst');
      } else {
        this.setData({
          lastEvent: 'EVT: single loud spike counted (1 of 2) - a lone spike earns no nudge'
        });
      }
      return;
    }
    if (seg.peak >= this._bellThr() && seg.peak < spike && dur >= 4 && dur <= 12) {
      this._patternFires('bell');
      return;
    }
    if (dur >= 4) {
      this.setData({
        lastEvent: 'EVT: loud segment matched no pattern - ignored (level shapes only)'
      });
    }
  },

  // A pattern completed. If the watch is still in cooldown from
  // the previous episode this is the SAME episode - no repeat
  // nudge. Otherwise: speak ONCE, with the door's direction as
  // registered (never derived from the sound), and leave the
  // banner up until the wearer faces the door or taps ACK.
  _patternFires(kind) {
    if (!this._armed) {
      this.setData({
        lastEvent: 'EVT: pattern during cooldown - same episode, no repeat nudge'
      });
      return;
    }
    this._armed = false;
    this._quietTicks = 0;
    this._nudgeCount += 1;
    this._alertPending = true;
    this._ackTicks = 0;
    var text;
    if (this._door && this._heading !== null) {
      text = '刚才有一阵响动 — ' + this._LABELS[this._door.labelIdx] + '在你' +
        this._dirName(this._rel(this._door.headingDeg, this._heading)).zh + '，去看一眼';
    } else if (this._door) {
      text = '刚才有一阵响动 — 去' + this._LABELS[this._door.labelIdx] + '看一眼';
    } else {
      text = '刚才有一阵响动 — 去门口看一眼';
    }
    this._lastNudge = text;
    this._speakText(text);
    this.setData({
      status: '🔔 ' + text + '（响动只是电平形状，没识别出是什么声）',
      lastEvent: 'EVT: ' + (kind === 'burst' ? 'knock-shaped burst' : 'bell-length tone') +
        ' pattern - nudged once; the sound itself was NOT identified'
    });
    this._recompute();
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  // ---------- LISTEN: omnidirectional level stream ----------

  // The omnidirectional mode only shapes this getUserMedia
  // stream, which feeds an AnalyserNode RMS meter - nothing
  // else. This agent has NO speech recognition at all, so there
  // is nothing for a mic mode to "improve". The audio is never
  // recorded, never sent anywhere; only the level number lives.
  async listenTap() {
    if (this.data.busy) return;
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: LISTEN ignored in DEMO - the feed is simulated' });
      return;
    }
    if (this._listening) {
      this._stopListen(false);
      this.setData({
        status: 'LISTEN off - mic released',
        lastEvent: 'EVT: listen stopped - tracks released, nothing recorded'
      });
      this._recompute();
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'LISTEN FAIL: mic n/a on this host',
        lastEvent: 'EVT: LISTEN FAIL - mediaDevices n/a'
      });
      return;
    }
    if (typeof AudioContext === 'undefined') {
      this.setData({
        status: 'LISTEN FAIL: Web Audio n/a on this host',
        lastEvent: 'EVT: LISTEN FAIL - AudioContext n/a'
      });
      return;
    }
    this.setData({ busy: true, status: 'LISTEN: opening mic (omnidirectional)...' });
    var stream = null;
    var actx = null;
    var fellBack = false;
    try {
      try {
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'omnidirectional' }
        }), 9000, 'mic');
      } catch (eMode) {
        // media.md: not every device supports every mode - fall
        // back to the default microphone and say so.
        if (!eMode || eMode.name !== 'OverconstrainedError') throw eMode;
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 9000, 'mic');
        fellBack = true;
      }
      this._stream = stream;
      actx = new AudioContext();
      this._actx = actx;
      await actx.resume();
      var src = actx.createMediaStreamSource(stream);
      var an = actx.createAnalyser();
      an.fftSize = 2048;
      src.connect(an); // analyser only - never to destination (feedback)
      this._srcNode = src;
      this._analyser = an;
      this._buf = new Float32Array(an.fftSize);
      var mode = '';
      try {
        var tr = stream.getAudioTracks()[0];
        if (tr && tr.getSettings) mode = tr.getSettings().microphoneMode || '';
      } catch (e) {}
      this._micLabel = fellBack ? 'default - omni n/a' : (mode || 'omnidirectional');
      this._listening = true;
      this._curLevel = 0;
      this._resetPattern();
      this.setData({
        busy: false,
        status: 'LISTENING: knock-burst / bell-length patterns = one nudge (level only)',
        lastEvent: fellBack
          ? 'EVT: omni n/a - default mic used, said so'
          : 'EVT: listen live - RMS level only, no recording, no recognition'
      });
      this._recompute();
    } catch (e) {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        this._stream = null;
      }
      if (actx) { try { await actx.close(); } catch (e3) {} this._actx = null; }
      this.setData({
        busy: false,
        status: 'LISTEN FAIL: ' + this._err(e),
        lastEvent: 'EVT: LISTEN FAIL - ' + this._err(e)
      });
    }
  },

  _stopListen(silent) {
    if (this._srcNode) { try { this._srcNode.disconnect(); } catch (e) {} this._srcNode = null; }
    this._analyser = null;
    this._buf = null;
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    if (this._actx) {
      var c = this._actx;
      this._actx = null;
      try { c.close(); } catch (e) {}
    }
    this._listening = false;
    this._micLabel = 'off';
    this._seg = null;
    if (!silent) this._curLevel = 0;
  },

  // ---------- look acknowledgement (face the door) ----------

  // The loop closes when you actually turn to the door: head
  // steady AND the registered door inside the +-15 deg cone for
  // 1 continuous second (4 ticks). Sweeping past earns nothing;
  // leaving the cone restarts the count.
  _ackDwellTick() {
    if (!this._alertPending || !this._door) {
      if (this._ackTicks) this._ackTicks = 0;
      return;
    }
    if (!this._steady || this._heading === null) {
      if (this._ackTicks) { this._ackTicks = 0; this._recompute(); }
      return;
    }
    var a = Math.abs(this._rel(this._door.headingDeg, this._heading));
    if (a > this._ACK_CONE) {
      if (this._ackTicks) { this._ackTicks = 0; this._recompute(); }
      return;
    }
    this._ackTicks += 1;
    if (this._ackTicks >= this._ACK_TICKS) {
      this._ack('face');
    } else {
      this._recompute();
    }
  },

  _ack(how) {
    if (!this._alertPending) return;
    this._alertPending = false;
    this._ackTicks = 0;
    if (this._demo && how === 'face') this._demoAcked = true;
    var label = this._door ? this._LABELS[this._door.labelIdx] : '门口';
    this.setData({
      status: '✓ 已回看' + label + ' (' + how + ') — 闭环完成',
      lastEvent: 'EVT: nudge acknowledged by ' + how + ' - loop closed'
    });
    this._recompute();
  },

  ackTap() {
    if (this.data.busy) return;
    if (!this._alertPending) {
      this.setData({ lastEvent: 'EVT: ACK ignored - no nudge is waiting' });
      return;
    }
    this._ack('tap');
  },

  // ---------- register the door (SET) ----------

  // Registering means: you are sitting in your usual seat looking
  // at the door NOW. The current heading is captured when setup
  // opens; swipes pick the door label, one tap binds it. Every
  // direction this agent ever reports comes from this binding -
  // never from any sound.
  _enterSetup() {
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'SET FAIL: no heading - look at the door, or use DEMO',
        lastEvent: 'EVT: SET refused - a door must be bound to a real heading'
      });
      return;
    }
    this._setup = {
      labelIdx: this._door ? this._door.labelIdx : 0,
      headingDeg: Math.round(this._heading)
    };
    this.setData({
      status: 'REGISTER: ' + this._LABELS[this._setup.labelIdx] + ' · @ ' +
        this._setup.headingDeg + ' deg - swipe to change label, tap to bind',
      lastEvent: 'EVT: setup opened at heading ' + this._setup.headingDeg + ' deg'
    });
    this._recompute();
  },

  _setupCycle(dir) {
    if (!this._setup) return;
    var n = this._LABELS.length;
    this._setup.labelIdx = (((this._setup.labelIdx + dir) % n) + n) % n;
    this.setData({
      lastEvent: 'EVT: setup label -> ' + this._LABELS[this._setup.labelIdx]
    });
    this._recompute();
  },

  _confirmSetup() {
    var s = this._setup;
    if (!s) return;
    this._door = { labelIdx: s.labelIdx, headingDeg: s.headingDeg };
    this._setup = null;
    this.setData({
      status: '✓ ' + this._LABELS[this._door.labelIdx] + '已登记 @ ' + s.headingDeg +
        '° — 点 LISTEN 开始守听',
      lastEvent: 'EVT: door registered ' + this._LABELS[this._door.labelIdx] +
        ' @ ' + s.headingDeg + ' deg (from your seat)'
    });
    this._recompute();
  },

  setTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this._setup = null;
      this.setData({
        status: 'REGISTER CANCELLED - nothing bound',
        lastEvent: 'EVT: setup cancelled'
      });
      this._recompute();
      return;
    }
    if (this._alertPending) {
      this.setData({ lastEvent: 'EVT: SET ignored - look at the door first (ACK)' });
      return;
    }
    this._enterSetup();
  },

  // ---------- sensitivity (LEVEL thresholds only) ----------

  _sensCycle(dir) {
    var n = this._SENS.length;
    this._sensIdx = (((this._sensIdx + dir) % n) + n) % n;
    this.setData({
      lastEvent: 'EVT: sensitivity -> ' + this._SENS[this._sensIdx].name +
        ' (level thresholds x' + this._SENS[this._sensIdx].f + ')'
    });
    this._recompute();
  },

  sensTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: SENS ignored while registering' });
      return;
    }
    this._sensCycle(1);
  },

  // ---------- speech (TTS out; lang is never set) ----------

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
  },

  _statusText() {
    if (!this._door) return '门口守望：还没登记门。坐在你平常的位置，看着门点 SET 登记。';
    var label = this._LABELS[this._door.labelIdx];
    var dirTxt = this._heading === null
      ? '现在朝向未知'
      : label + '现在在你' + this._dirName(this._rel(this._door.headingDeg, this._heading)).zh;
    return '门口守望：' + dirTxt + '；守听' + (this._listening ? '开着' : '关着') +
      '，灵敏度' + this._SENS[this._sensIdx].name + '；到现在提醒过' +
      this._nudgeCount + '次。';
  },

  speakTap() {
    if (this.data.busy) return;
    var text = this._statusText();
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  },

  // ---------- DEMO (seeded door + simulated feed, memory only) ----------

  // DEMO registers a front door at 120 deg with the demo head at
  // 0 deg (door behind-right) and plays a simulated level feed:
  // first ONE lone spike (counted, explained, earns nothing),
  // then a knock-shaped burst - two spikes inside 5s - which
  // fires the nudge with the registered direction. Each DEMO tap
  // turns the demo head +45 deg; at 135 deg the door sits inside
  // the +-15 deg cone, the 1s dwell runs and the face ack closes
  // the loop. One more tap exits and restores your real state.
  // DEMO writes nothing anywhere - this agent never does.
  _demoLevel() {
    var t = this._demoTicks;
    if ((t >= 5 && t <= 6) || (t >= 33 && t <= 34) || (t >= 41 && t <= 42)) return 0.82;
    return 0.04;
  },

  demoTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: DEMO ignored - finish or cancel SET first' });
      return;
    }
    if (!this._demo) {
      if (this._listening) this._stopListen(true);
      this._realDoor = this._door;
      this._realSens = this._sensIdx;
      this._demo = true;
      this._demoSteps = 0;
      this._demoTicks = 0;
      this._demoAcked = false;
      this._door = { labelIdx: 0, headingDeg: 120 };
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this._listening = true; // simulated feed, see _demoLevel
      this._micLabel = 'DEMO (simulated)';
      this._curLevel = 0;
      this._alertPending = false;
      this._resetPattern();
      this.setData({
        status: 'DEMO - a lone spike first (ignored), then a knock-burst',
        lastEvent: 'EVT: DEMO on - door @ 120 deg, simulated level feed, real state saved'
      });
      this._recompute();
      return;
    }
    if (this._demoAcked || this._demoSteps >= 8) {
      this._exitDemo();
      return;
    }
    this._demoSteps += 1;
    this._heading = (this._heading + 45) % 360;
    this._headingSrc = 'DEMO';
    this.setData({
      status: 'DEMO MODE - heading ' + this._heading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._heading + ' deg'
    });
    this._recompute();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._demoTicks = 0;
    this._door = this._realDoor;
    this._sensIdx = this._realSens;
    this._realDoor = null;
    this._listening = false;
    this._micLabel = 'off';
    this._curLevel = 0;
    this._alertPending = false;
    this._ackTicks = 0;
    this._resetPattern();
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real door registration is back',
      lastEvent: 'EVT: DEMO off - real state restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _doorText() {
    if (this._setup) {
      return 'DOOR: 登记中 — ' + this._LABELS[this._setup.labelIdx] +
        ' · @ ' + this._setup.headingDeg + '°（点 SET 那一刻的正前方）';
    }
    if (!this._door) return 'DOOR: not registered - face the door and tap SET';
    var base = 'DOOR: ' + this._LABELS[this._door.labelIdx] + ' · reg ' +
      this._door.headingDeg + '°';
    if (this._heading === null) return base + ' · 朝向未知';
    var rel = this._rel(this._door.headingDeg, this._heading);
    return base + ' · 现在在你' + this._dirName(rel).zh + ' ' +
      Math.round(Math.abs(rel)) + '°';
  },

  _recompute() {
    var patch = {
      headLine: 'HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : '') +
        (this._steady ? ' · HEAD STEADY' : ' · HEAD: moving - hold still'),
      doorLine: this._doorText()
    };

    if (this._alertPending) {
      var dwellTxt = (this._ackTicks > 0)
        ? ' · 看着它 ' + (this._ackTicks * 250 / 1000).toFixed(1) + 's / 1s' : '';
      var lbl = this._door ? this._LABELS[this._door.labelIdx] : '门口';
      patch.alertLine = '🔔 刚才有一阵响动 — 转头看向' + lbl + '停 1 秒确认，或点 ACK' + dwellTxt;
      patch.alertCls = 'alert alert-on';
    } else {
      patch.alertLine = 'NO ALERT - no loud pattern is waiting';
      patch.alertCls = 'alert';
    }

    if (this._listening) {
      patch.listenLine = 'LISTEN: ' + this._micLabel + ' · LVL: ' +
        this._levelBar(this._curLevel) + ' ' + Math.round(this._curLevel * 100) +
        ' · 灵敏度 ' + this._SENS[this._sensIdx].name + '（只是电平阈值）';
    } else {
      patch.listenLine = 'LISTEN: off · LVL: ---------- 0 · 灵敏度 ' +
        this._SENS[this._sensIdx].name;
    }
    patch.nudgeLine = this._lastNudge
      ? 'NUDGE: ' + this._lastNudge
      : 'PATTERN: level shapes only - NOT doorbell / knock recognition';

    // Guide box: where the door is relative to you, right now.
    if (this._setup) {
      patch.focusName = '▸ 登记' + this._LABELS[this._setup.labelIdx];
      patch.focusCue = '滑动换门标签 · 单击（Enter）绑定这个方向';
      patch.guideLine = this._LABELS[this._setup.labelIdx] + ' · 朝向 ' +
        this._setup.headingDeg + '°（以你现在坐的位置为准）';
      patch.guideCls = 'rel rel-on';
    } else if (!this._door) {
      patch.focusName = '▸ 门口守望';
      patch.focusCue = '坐在你平常的位置看着门点 SET：把方向登记下来';
      patch.guideLine = this._heading === null
        ? 'NO HEADING — SET needs the sensor (or use DEMO)'
        : 'LOOKING AT ' + Math.round(this._heading) +
          '° — SET binds this direction to the door';
      patch.guideCls = 'rel';
    } else {
      var label = this._LABELS[this._door.labelIdx];
      patch.focusName = '▸ ' + label + ' · 已登记';
      patch.focusCue = this._listening
        ? '守听中 — 有敲门状/门铃状的响动模式，我按登记方向叫你'
        : '点 LISTEN 开始守听；方向随时按你当前朝向换算';
      if (this._heading === null) {
        patch.guideLine = 'HEADING N/A (SRC NONE) — door direction unknown right now';
        patch.guideCls = 'rel';
      } else {
        var rel2 = this._rel(this._door.headingDeg, this._heading);
        var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
        var rel360 = (this._door.headingDeg - this._heading + 360) % 360;
        patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' TURN: ' +
          this._dirName(rel2).en + ' ' + Math.round(Math.abs(rel2)) + '° — ' +
          label + ' reg ' + this._door.headingDeg + '°';
        patch.guideCls = Math.abs(rel2) <= 15 ? 'rel rel-on' : 'rel';
      }
    }
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">DOOR WATCH</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}}</text>
    </view>
    <view class="alert-box">
      <text class="{{alertCls}}">{{alertLine}}</text>
    </view>
    <view class="box">
      <text class="door">{{doorLine}}</text>
    </view>
    <view class="box">
      <text class="listen">{{listenLine}}</text>
      <text class="note">{{nudgeLine}}</text>
    </view>
    <view class="guide-box">
      <text class="curname">{{focusName}}</text>
      <text class="cue">{{focusCue}}</text>
      <text class="{{guideCls}}">{{guideLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="setTap">SET</button>
      <button class="btn" bindtap="sensTap">SENS</button>
      <button class="btn" bindtap="ackTap">ACK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="listenTap">LISTEN</button>
      <button class="btn btn-main" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">只在本页打开时守听 · 方向来自登记，不是声音定位 · 不存任何记录</text>
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
  margin-bottom: 2px;
}
.title {
  color: #40ff5e;
  font-size: 18px;
  font-weight: 500;
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 13px;
  margin-top: 1px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
}
.alert-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 2px 10px;
  margin-bottom: 2px;
}
.alert {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  font-weight: 500;
  line-height: 15px;
}
.alert-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px;
  margin-bottom: 2px;
}
.door {
  color: #40ff5e;
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.listen {
  color: #40ff5e;
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.note {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
.guide-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 3px;
  margin-bottom: 2px;
}
.curname {
  color: #40ff5e;
  font-size: 15px;
  font-weight: 500;
  line-height: 17px;
}
.cue {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 13px;
  margin-top: 1px;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 15px;
  margin-top: 1px;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
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
  padding: 2px;
  font-size: 11px;
  font-weight: 500;
  line-height: 14px;
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
  line-height: 13px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
