<script def>
{
  "navigationBarTitleText": "Bath Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT THE TUB, TAP SET - I KEEP THE FILL TIMER',
    headLine: 'HEAD: --- deg · SRC: NONE · HEAD: moving - hold still',
    alertLine: 'NO ALERT - nothing is waiting for a look-back',
    alertCls: 'alert',
    fillLine: 'FILL: none yet · timers run only while this page is open',
    rows: [
      { text: '▸ 浴缸 · 空 — 站在浴缸边看着它点 SET 登记' }
    ],
    listenLine: 'LISTEN: off · LVL: ---------- 0',
    nudgeLine: 'LEVEL WATCH: level only - NOT water-state detection',
    focusName: '▸ 浴缸（未登记）',
    focusCue: '站在浴缸边看着它点 SET：绑朝向、选缸大小和估满时间',
    guideLine: 'NO TUB YET - register the tub you are filling',
    guideCls: 'rel',
    lastEvent: 'EVT: I watch the fill clock - you go pack',
    busy: false
  },

  onLoad() {
    // 250ms tick engine, same discipline as WA01: the countdown,
    // the face-ack dwell and the level-drop watch all accumulate
    // TICK COUNTS, never re-sampled wall-clock deltas.
    this._TICK_MS = 250;
    this._MINUTES = [5, 10, 15, 20];
    this._SIZES = ['小', '标准', '大'];
    this._PRE_FRAC = 0.8;    // pre-alert at 80% of YOUR estimate
    this._ACK_CONE = 15;     // face-the-tub cone for look-back ack (deg)
    this._ACK_TICKS = 4;     // 4 ticks x 250ms = 1s facing = acknowledged
    this._RUN_LVL = 0.2;     // level above this = "water sound present"
    this._RUN_TICKS = 8;     // 2s of it = running water has been heard
    this._DROP_LVL = 0.08;   // level below this = near silence
    this._DROP_TICKS = 32;   // 32 ticks x 250ms = 8s of silence = a drop
    this._fill = null;
    this._setup = null;
    this._replaceArm = false;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._sensor = null;
    this._timer = null;
    this._tickCount = 0;
    this._ackTicks = 0;
    this._ackInCone = false;
    this._listening = false;
    this._stream = null;
    this._actx = null;
    this._analyser = null;
    this._srcNode = null;
    this._buf = null;
    this._micLabel = 'off';
    this._curLevel = 0;
    this._runTicks = 0;
    this._heardRunning = false;
    this._dropTicks = 0;
    this._dropStartFrac = null;
    this._lastNudge = '';
    this._demo = false;
    this._demoSteps = 0;
    this._demoHeading = 0;
    this._demoLevel = 0;
    this._realFill = null;
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
    // Nod discipline (same as WA01): a steady nod only ever SPEAKS
    // the status. A nod never registers the tub, never
    // acknowledges an alert - walking back and looking at the
    // tub (or a deliberate tap) is what closes the loop.
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: nod ignored - finish or cancel SET first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod = speak the fill status (never ack)' });
    this.speakTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier section 3.2.1): single tap =
  // Enter, double-tap = Backspace, swipe = ArrowUp/ArrowDown.
  // The whole main flow (register, watch, look-back ack, hear
  // status) runs on these keys + head-steady + nod.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (Enter) = primary action' });
      this._primaryTap();
    } else if (code === 'ArrowDown') {
      if (this._setup) this._setupCycle('size', 1);
      else this.setData({ lastEvent: 'EVT: swipe down - nothing to select (one tub)' });
    } else if (code === 'ArrowUp') {
      if (this._setup) this._setupCycle('minutes', 1);
      else this.setData({ lastEvent: 'EVT: swipe up - nothing to select (one tub)' });
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

  // Context primary action behind a single tap (Enter):
  // setting up -> start the fill; tub is alerting -> acknowledge
  // it; replace armed -> open setup; otherwise -> register (or
  // arm the replace) / speak the status while filling.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._setup) { this._confirmSetup(); return; }
    var f = this._fill;
    if (f && f.state === 'alert') { this._ack('tap'); return; }
    if (this._replaceArm) { this._enterSetup(); return; }
    if (!f || f.state === 'done') { this._enterSetup(); return; }
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

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  _headText(h) {
    return (h === null || h === undefined || !isFinite(h)) ? '---' : String(Math.round(h));
  },

  _fmtTicks(ticks) {
    var sec = Math.max(0, Math.ceil(ticks / 4));
    return this._pad2(Math.floor(sec / 60)) + ':' + this._pad2(sec % 60);
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

  _elapsedFrac() {
    var f = this._fill;
    if (!f || !f.totalTicks) return null;
    return 1 - f.remainTicks / f.totalTicks;
  },

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
    var f = this._fill;
    if (f && f.state === 'filling') {
      f.remainTicks -= 1;
      if (f.remainTicks < 0) f.remainTicks = 0;
      this._checkThresholds();
    }
    this._ackDwellTick();
    if (this._listening) this._sampleLevel();
    if (this._tickCount % 4 === 0) this._recompute();
  },

  // Threshold crossings for the ONE fill: 80% of the wearer's
  // own estimate = pre-alert (spoken once); 100% = full alert
  // (spoken once, banner stays). Both keyed on tick counts.
  _checkThresholds() {
    var f = this._fill;
    if (!f || f.state !== 'filling') return;
    var frac = this._elapsedFrac();
    if (!f.preFired && frac >= this._PRE_FRAC) {
      f.preFired = true;
      this._speakText('浴缸快满了，准备回去关水');
      this.setData({
        status: '⏰ 浴缸快满了（估时 80%）— 准备回去关水',
        lastEvent: 'EVT: pre-alert at 80% of your estimate - spoken once'
      });
    }
    if (f.remainTicks <= 0) {
      f.state = 'alert';
      var text;
      if (this._heading === null) {
        text = '浴缸满了，回去关水';
      } else {
        text = this._dirName(this._rel(f.headingDeg, this._heading)).zh + '的浴缸满了，回去关水';
      }
      this._speakText(text);
      this.setData({
        status: '⏰ ' + text + ' — 回去看它停 1 秒，或点 ACK',
        lastEvent: 'EVT: full alert at 100% - spoken once, banner stays till you look back'
      });
      this._recompute();
    }
  },

  // ---------- look-back acknowledgement (face the tub) ----------

  // The attention loop closes when you actually go back and
  // look: head steady AND the tub inside the +-15 deg cone.
  // Entering the cone only STARTS the span (same semantics as
  // WA01); a further 4 ticks (1s) of continuous facing confirms.
  // Sweeping past earns nothing.
  _ackDwellTick() {
    var f = this._fill;
    var inCone = f && f.state === 'alert' && this._steady &&
      this._heading !== null &&
      Math.abs(this._rel(f.headingDeg, this._heading)) <= this._ACK_CONE;
    if (!inCone) {
      if (this._ackInCone || this._ackTicks) {
        this._ackInCone = false;
        this._ackTicks = 0;
        if (f && f.state === 'alert') this._recompute();
      }
      return;
    }
    if (!this._ackInCone) {
      this._ackInCone = true;
      this._ackTicks = 0;
      this._recompute();
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
    var f = this._fill;
    if (!f || f.state !== 'alert') return;
    f.state = 'done';
    f.ackHow = how;
    this._ackTicks = 0;
    this._ackInCone = false;
    this.setData({
      status: '✓ 已回看浴缸 (' + how + ') — 闭环完成，记得关水',
      lastEvent: 'EVT: tub acknowledged by ' + how + ' - loop closed'
    });
    this._recompute();
  },

  ackTap() {
    if (this.data.busy) return;
    if (!this._fill || this._fill.state !== 'alert') {
      this.setData({ lastEvent: 'EVT: ACK ignored - the tub is not waiting for a look-back' });
      return;
    }
    this._ack('tap');
  },

  // ---------- register the tub (SET) ----------

  // Registering means: you are standing at the tub NOW. The
  // current heading is captured when setup opens; swipes pick
  // the size (down) and the estimated minutes (up), one tap
  // starts. A fill already in progress is only replaced after
  // an explicit arm + confirm - never silently.
  _enterSetup() {
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'SET FAIL: no heading - stand at the tub, or use DEMO',
        lastEvent: 'EVT: SET refused - the tub must be bound to a real heading'
      });
      return;
    }
    this._replaceArm = false;
    this._setup = {
      sizeIdx: 1, // 标准 default
      minIdx: 1,  // 10 minutes default
      headingDeg: Math.round(this._heading),
      replacing: !!(this._fill && this._fill.state !== 'done')
    };
    this.setData({
      status: 'REGISTER: ' + this._SIZES[1] + '缸 · 估 ' + this._MINUTES[1] +
        ' 分钟满 · @ ' + this._setup.headingDeg + ' deg - swipe to adjust, tap to start',
      lastEvent: 'EVT: setup opened at heading ' + this._setup.headingDeg + ' deg' +
        (this._setup.replacing ? ' (replaces the current fill)' : '')
    });
    this._recompute();
  },

  _setupCycle(which, dir) {
    if (!this._setup) return;
    if (which === 'size') {
      var n = this._SIZES.length;
      this._setup.sizeIdx = (((this._setup.sizeIdx + dir) % n) + n) % n;
    } else {
      var m = this._MINUTES.length;
      this._setup.minIdx = (((this._setup.minIdx + dir) % m) + m) % m;
    }
    this.setData({
      lastEvent: 'EVT: setup -> ' + this._SIZES[this._setup.sizeIdx] + '缸 · 估 ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟'
    });
    this._recompute();
  },

  _confirmSetup() {
    var s = this._setup;
    if (!s) return;
    var mins = this._MINUTES[s.minIdx];
    // The tub size is only a LABEL on your estimate - it never
    // feeds the math; the countdown is the minutes you picked.
    this._fill = {
      size: this._SIZES[s.sizeIdx],
      headingDeg: s.headingDeg,
      totalTicks: mins * 60 * 4,
      remainTicks: mins * 60 * 4,
      state: 'filling',
      preFired: false,
      dropNudged: false,
      ackHow: ''
    };
    this._setup = null;
    this._replaceArm = false;
    this._heardRunning = false;
    this._runTicks = 0;
    this._dropTicks = 0;
    this._dropStartFrac = null;
    this.setData({
      status: '⏱ 开始放水计时：估 ' + mins + ' 分钟满（' + this._fill.size + '缸）',
      lastEvent: 'EVT: tub registered @ ' + s.headingDeg + ' deg · ' +
        this._fill.size + '缸 · est ' + mins + ' min'
    });
    this._recompute();
  },

  setTap() {
    if (this.data.busy) return;
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: SET ignored in DEMO - the demo fill is running' });
      return;
    }
    if (this._setup) {
      this._setup = null;
      this.setData({
        status: 'REGISTER CANCELLED - nothing started',
        lastEvent: 'EVT: setup cancelled'
      });
      this._recompute();
      return;
    }
    var f = this._fill;
    if (f && f.state === 'filling') {
      if (!this._replaceArm) {
        this._replaceArm = true;
        this.setData({
          status: 'REPLACE? 正在放水中 — 再点一次 SET 丢弃它、重新登记',
          lastEvent: 'EVT: replace armed - a second SET opens setup'
        });
        this._recompute();
        return;
      }
      this._enterSetup();
      return;
    }
    if (f && f.state === 'alert') {
      this.setData({ lastEvent: 'EVT: SET ignored - look back at the tub first (ACK)' });
      return;
    }
    this._replaceArm = false;
    this._enterSetup();
  },

  // ---------- TIME: setup cycles presets, filling adds +2 min ----------

  timeTap() {
    if (this.data.busy) return;
    if (this._setup) { this._setupCycle('minutes', 1); return; }
    var f = this._fill;
    if (f && f.state === 'filling') {
      f.totalTicks += 2 * 60 * 4;
      f.remainTicks += 2 * 60 * 4;
      this.setData({
        status: '⏱ 估时 +2 分钟 → 还剩 ' + this._fmtTicks(f.remainTicks),
        lastEvent: 'EVT: estimate extended by 2 min'
      });
      this._recompute();
      return;
    }
    this.setData({ lastEvent: 'EVT: TIME works while registering, or adds 2 min to a running fill' });
  },

  // ---------- LISTEN: the level watch (LEVEL ONLY) ----------

  // An omnidirectional getUserMedia stream feeds an
  // AnalyserNode; only the RMS loudness number is ever used.
  // There is NO sound classification on this platform, so this
  // watch cannot tell running water from a hairdryer, and a
  // level DROP is just a level drop - it never becomes "the
  // water stopped". What it can honestly do: if running-water
  // level was heard, then the level falls to near-silence and
  // STAYS there 8 continuous seconds while the fill is still
  // in its first half, nudge you ONCE per fill to go look.
  async listenTap() {
    if (this.data.busy) return;
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: LISTEN is simulated inside DEMO' });
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
      this._runTicks = 0;
      this._heardRunning = false;
      this._dropTicks = 0;
      this._dropStartFrac = null;
      this.setData({
        busy: false,
        status: 'LISTENING: an early level drop = one nudge (level only)',
        lastEvent: fellBack
          ? 'EVT: omni n/a - default mic used, said so'
          : 'EVT: listen live - RMS level only, no recording'
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

  _sampleLevel() {
    var lvl;
    if (this._demo) {
      lvl = this._demoLevel;
    } else {
      if (!this._analyser || !this._buf) return;
      this._analyser.getFloatTimeDomainData(this._buf);
      var sum = 0;
      for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
      lvl = Math.min(1, Math.sqrt(sum / this._buf.length) * 3);
    }
    this._curLevel = lvl;
    var f = this._fill;
    if (lvl > this._RUN_LVL) {
      // Water-sound level present. A couple of seconds of it
      // arms the drop watch; any return of level cancels a
      // drop in progress.
      this._runTicks += 1;
      if (this._runTicks >= this._RUN_TICKS) this._heardRunning = true;
      this._dropTicks = 0;
      this._dropStartFrac = null;
    } else if (lvl < this._DROP_LVL) {
      if (this._heardRunning && f && f.state === 'filling' && !f.dropNudged) {
        if (this._dropTicks === 0) this._dropStartFrac = this._elapsedFrac();
        this._dropTicks += 1;
        if (this._dropTicks >= this._DROP_TICKS) {
          // The episode is consumed either way (once per fill);
          // it only nudges when the drop STARTED in the first
          // half - a late drop is what the timers are for.
          f.dropNudged = true;
          this._dropTicks = 0;
          if (this._dropStartFrac !== null && this._dropStartFrac < 0.5) {
            this._fireDropNudge();
          } else {
            this.setData({ lastEvent: 'EVT: level drop after halfway - left to the timers, no nudge' });
          }
          this._dropStartFrac = null;
        }
      }
    } else {
      // In-between level: neither running nor silence - a drop
      // in progress is broken, the count restarts.
      this._dropTicks = 0;
      this._dropStartFrac = null;
    }
    this._recompute();
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  // One nudge per fill. The wording stays level-based: the
  // sound LEVEL dropped early - go look. It never says the
  // water stopped, and never says why it dropped.
  _fireDropNudge() {
    var text = '水声电平掉下去了，去看一眼浴缸';
    this._lastNudge = text;
    this._speakText(text);
    this.setData({
      status: '🔊 水声电平早早掉下去了 — 去看一眼（只是电平，不是水位识别）',
      lastEvent: 'EVT: level drop >=8s in first half - nudged once: ' + text
    });
    this._recompute();
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
    this._runTicks = 0;
    this._dropTicks = 0;
    if (!silent) this._curLevel = 0;
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
    var f = this._fill;
    if (!f) return '浴缸守望：还没登记浴缸。';
    if (f.state === 'filling') {
      var sec = Math.ceil(f.remainTicks / 4);
      return '浴缸守望：放水中，还剩约' + Math.floor(sec / 60) + '分' + (sec % 60) + '秒到估时。';
    }
    if (f.state === 'alert') return '浴缸守望：估时已到，浴缸在等你回看确认。';
    return '浴缸守望：这一缸已回看确认。';
  },

  speakTap() {
    if (this.data.busy) return;
    var text = this._statusText();
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  },

  // ---------- DEMO (seeded mid-fill, memory only - toggles off) ----------

  // DEMO seeds a fill already 35% through YOUR 5-minute
  // estimate, tub dead ahead (0 deg) with the demo head facing
  // AWAY (180 deg), and LISTEN simulated on: the level runs,
  // then from the first DEMO tap it drops - hold ~8s and the
  // early-drop nudge fires. Each DEMO tap also fast-forwards
  // the fill by 8% of the estimate and turns the head +45 deg:
  // the 80% pre-alert calls out mid-circle, the full alert
  // lands at 100%, and when the turning head comes back around
  // to the tub (0 deg) and holds 1s, the look-back ack closes
  // the loop. The tap after that exits DEMO and restores your
  // real fill untouched. DEMO pauses the real fill (its ticks
  // are held in memory) and writes nothing anywhere - this
  // agent writes nothing anywhere, ever.
  demoTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: DEMO ignored - finish or cancel SET first' });
      return;
    }
    if (!this._demo) {
      if (this._listening) this._stopListen(true);
      this._realFill = this._fill;
      this._demo = true;
      this._demoSteps = 0;
      this._demoHeading = 180;
      this._heading = 180;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this._demoLevel = 0.5;
      this._fill = {
        size: '标准',
        headingDeg: 0,
        totalTicks: 1200,
        remainTicks: 780,
        state: 'filling',
        preFired: false,
        dropNudged: false,
        ackHow: ''
      };
      this._listening = true;
      this._micLabel = 'DEMO (simulated)';
      this._curLevel = 0.5;
      this._runTicks = 0;
      this._heardRunning = false;
      this._dropTicks = 0;
      this._dropStartFrac = null;
      this._ackTicks = 0;
      this.setData({
        status: 'DEMO FILL - 35% in, level running; tap DEMO: +45 deg, time +8%',
        lastEvent: 'EVT: DEMO on - seeded fill in memory only, real fill paused'
      });
      this._recompute();
      return;
    }
    if (this._demoSteps >= 12) {
      this._exitDemo();
      return;
    }
    this._demoSteps += 1;
    this._demoHeading = (this._demoHeading + 45) % 360;
    this._heading = this._demoHeading;
    this._headingSrc = 'DEMO';
    this._demoLevel = 0.02; // from the first step on, the sound level is gone
    var f = this._fill;
    if (f && f.state === 'filling') {
      f.remainTicks -= Math.round(f.totalTicks * 0.08);
      if (f.remainTicks < 0) f.remainTicks = 0;
      this._checkThresholds();
    }
    this.setData({
      status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg · fill fast-forwarded +8%'
    });
    this._recompute();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._fill = this._realFill || null;
    this._realFill = null;
    this._listening = false;
    this._micLabel = 'off';
    this._curLevel = 0;
    this._demoLevel = 0;
    this._ackTicks = 0;
    this._ackInCone = false;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real fill is back',
      lastEvent: 'EVT: DEMO off - real fill restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _tubDirText() {
    var f = this._fill;
    if (!f || this._heading === null) return null;
    var rel = this._rel(f.headingDeg, this._heading);
    return { rel: rel, text: this._dirName(rel).zh + ' ' + Math.round(Math.abs(rel)) + '°' };
  },

  _rowText() {
    if (this._setup) {
      return '▸ 浴缸 · 登记中：' + this._SIZES[this._setup.sizeIdx] + '缸 · 估 ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟 · @ ' + this._setup.headingDeg + '°';
    }
    var f = this._fill;
    if (!f) return '▸ 浴缸 · 空 — 站在浴缸边看着它点 SET 登记';
    var d = this._tubDirText();
    var dirTxt = d ? d.text : '朝向未知';
    if (f.state === 'done') {
      return '▸ 浴缸 · ✓ 已回看确认 (' + f.ackHow + ') · 估 ' +
        Math.round(f.totalTicks / 240) + ' 分钟 · ' + f.size + '缸 · reg ' + f.headingDeg + '°';
    }
    if (f.state === 'alert') {
      return '▸ 浴缸 · ! 估时已到 · ' + dirTxt + ' · 等你回看 · reg ' + f.headingDeg + '°';
    }
    return '▸ 浴缸 · 还剩 ' + this._fmtTicks(f.remainTicks) + ' / 估 ' +
      Math.round(f.totalTicks / 240) + ' 分钟 · ' + f.size + '缸 · ' + dirTxt +
      ' · reg ' + f.headingDeg + '°';
  },

  _recompute() {
    var patch = {
      headLine: 'HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : '') +
        (this._steady ? ' · HEAD STEADY' : ' · HEAD: moving - hold still')
    };
    var f = this._fill;
    if (!f) {
      patch.fillLine = 'FILL: none yet · timers run only while this page is open';
    } else if (f.state === 'filling') {
      patch.fillLine = 'FILL: ' + f.size + '缸 · 还剩 ' + this._fmtTicks(f.remainTicks) +
        ' / 估 ' + Math.round(f.totalTicks / 240) + ' 分钟（' +
        Math.round(this._elapsedFrac() * 100) + '%）· timers run only while open';
    } else if (f.state === 'alert') {
      patch.fillLine = 'FILL: 估时已到 · ' + f.size + '缸 · waiting for your look-back';
    } else {
      patch.fillLine = 'FILL: done · 已回看确认 (' + f.ackHow + ') · ' + f.size + '缸';
    }

    if (f && f.state === 'alert') {
      var dwellTxt = this._ackTicks > 0
        ? ' · 看着它 ' + (this._ackTicks * 250 / 1000).toFixed(1) + 's / 1s' : '';
      patch.alertLine = '⏰ 浴缸估时到了 — 回去看它停 1 秒确认，或点 ACK' + dwellTxt;
      patch.alertCls = 'alert alert-on';
    } else {
      patch.alertLine = 'NO ALERT - nothing is waiting for a look-back';
      patch.alertCls = 'alert';
    }

    patch.rows = [{ text: this._rowText() }];

    if (this._listening) {
      patch.listenLine = 'LISTEN: ' + this._micLabel + ' · LVL: ' +
        this._levelBar(this._curLevel) + ' ' + Math.round(this._curLevel * 100) +
        (this._heardRunning ? ' · running heard' : ' · no running level yet') +
        ' · drop ' + (this._dropTicks * 250 / 1000).toFixed(0) + 's / 8s';
    } else {
      patch.listenLine = 'LISTEN: off · LVL: ---------- 0';
    }
    patch.nudgeLine = this._lastNudge
      ? 'NUDGE: ' + this._lastNudge
      : 'LEVEL WATCH: level only - NOT water-state detection';

    // Guide box: about the tub / setup state.
    if (this._setup) {
      patch.focusName = '▸ 登记浴缸';
      patch.focusCue = '下滑换缸大小 · 上滑换估时 · 单击（Enter）开始放水计时';
      patch.guideLine = this._SIZES[this._setup.sizeIdx] + '缸 · 估 ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟 · 朝向 ' + this._setup.headingDeg +
        '°（缸大小只是标签，时间以你估的为准）';
      patch.guideCls = 'rel rel-on';
    } else if (!f) {
      patch.focusName = '▸ 浴缸（未登记）';
      patch.focusCue = '站在浴缸边看着它点 SET：绑朝向、选缸大小和估满时间';
      patch.guideLine = this._heading === null
        ? 'NO HEADING — SET needs the sensor (or DEMO): a direction is the whole point'
        : 'LOOKING AT ' + Math.round(this._heading) + '° — SET binds this direction to the tub';
      patch.guideCls = 'rel';
    } else if (f.state === 'done') {
      patch.focusName = '▸ 浴缸（已回看确认）';
      patch.focusCue = '这一缸闭环了：站在浴缸边点 SET 可登记下一缸';
      patch.guideLine = '✓ DONE by ' + f.ackHow + ' — SET registers a fresh fill';
      patch.guideCls = 'rel';
    } else if (f.state === 'alert') {
      patch.focusName = '▸ 浴缸（估时已到）';
      patch.focusCue = '回浴室看向它、头稳住停 1 秒 = 回看确认；或点 ACK';
      patch.guideLine = this._heading === null
        ? '! TIME UP — heading n/a, tap ACK after you have looked'
        : '! TIME UP — the tub is ' +
          this._dirName(this._rel(f.headingDeg, this._heading)).en + ' of you · reg ' +
          f.headingDeg + '°';
      patch.guideCls = 'rel rel-on';
    } else {
      patch.focusName = '▸ 浴缸 · 还剩 ' + this._fmtTicks(f.remainTicks);
      patch.focusCue = '安心去收拾 — 80% 时先叫你，估时到了再叫你回去看';
      if (this._heading === null) {
        patch.guideLine = 'HEADING N/A (SRC NONE) — timer still runs, direction unknown';
        patch.guideCls = 'rel';
      } else {
        var rel2 = this._rel(f.headingDeg, this._heading);
        var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
        var rel360 = (f.headingDeg - this._heading + 360) % 360;
        patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' TUB: ' +
          this._dirName(rel2).en + ' ' + Math.round(Math.abs(rel2)) + '° — reg ' +
          f.headingDeg + '°';
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
      <text class="title">BATH WATCH</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}}</text>
    </view>
    <view class="alert-box">
      <text class="{{alertCls}}">{{alertLine}}</text>
    </view>
    <view class="box">
      <text class="watch">{{fillLine}}</text>
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
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
      <button class="btn" bindtap="timeTap">TIME</button>
      <button class="btn" bindtap="ackTap">ACK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="listenTap">LISTEN</button>
      <button class="btn btn-main" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">只在本页打开时守望 · 电平 ≠ 水位识别 · 不存任何记录</text>
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
.watch {
  color: #40ff5e;
  font-size: 11px;
  line-height: 14px;
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
