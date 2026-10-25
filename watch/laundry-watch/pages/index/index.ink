<script def>
{
  "navigationBarTitleText": "Laundry Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'FACE THE PANEL, TAP SET - I KEEP THE WASH TIMER',
    headLine: 'HEAD: --- deg · SRC: NONE · HEAD: moving - hold still',
    alertLine: 'NO ALERT - nothing is waiting for a look-back',
    alertCls: 'alert',
    cycleLine: 'WASH: none yet · timers run only while this page is open',
    rows: [
      { text: '▸ 洗衣机 · 空 — 站在面板前看着它点 SET 登记' }
    ],
    listenLine: 'LISTEN: off · LVL: ---------- 0',
    nudgeLine: 'LEVEL WATCH: level only - NOT beep recognition',
    focusName: '▸ 洗衣机（未登记）',
    focusCue: '站在面板前看着它点 SET：绑朝向、填面板上的分钟数',
    guideLine: 'NO MACHINE YET - register the wash you just started',
    guideCls: 'rel',
    lastEvent: 'EVT: I watch the wash clock - you leave the balcony',
    busy: false
  },

  onLoad() {
    // 250ms tick engine, same discipline as W01/W02: the
    // countdown, the face-ack dwell and the spike watch all
    // accumulate TICK COUNTS, never re-sampled wall-clock deltas.
    this._TICK_MS = 250;
    this._MINUTES = [15, 30, 45, 60, 90];
    this._LOADS = ['小件', '日常', '大件'];
    this._PRENUDGE_TICKS = 720;   // soft call when 3 min remain
    this._PRENUDGE_MIN_TOTAL = 1200; // only for estimates over 5 min
    this._ACK_CONE = 15;          // face-the-machine cone (deg)
    this._ACK_TICKS = 4;          // 4 ticks x 250ms = 1s facing = ack
    this._SPIKE_HI = 0.6;         // level above this = a loud sound
    this._SPIKE_LO = 0.25;        // level below this = quiet again
    this._SPIKE_MAX_TICKS = 8;    // high for <= 2s = a SHORT sound
    this._QUIET_TICKS = 16;       // 4s of quiet re-arms the episode
    this._SPIKE_FRAC = 0.8;       // spike window opens at 80% elapsed
    this._cycle = null;
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
    this._spikeState = 'idle';    // idle | inspike | cooldown
    this._spikeTicks = 0;
    this._spikeFromCooldown = false;
    this._quietTicks = 0;
    this._lastNudge = '';
    this._demo = false;
    this._demoSteps = 0;
    this._demoHeading = 0;
    this._demoStartTick = 0;
    this._realCycle = null;
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
    // Nod discipline (same as W01/W02): a steady nod only ever
    // SPEAKS the status. A nod never registers the machine,
    // never acknowledges an alert - walking back and looking
    // at the machine (or a deliberate tap) closes the loop.
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: nod ignored - finish or cancel SET first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod = speak the wash status (never ack)' });
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
      if (this._setup) this._setupCycle('load', 1);
      else this.setData({ lastEvent: 'EVT: swipe down - nothing to select (one machine)' });
    } else if (code === 'ArrowUp') {
      if (this._setup) this._setupCycle('minutes', 1);
      else this.setData({ lastEvent: 'EVT: swipe up - nothing to select (one machine)' });
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
  // setting up -> start the wash; machine is alerting ->
  // acknowledge it; replace armed -> open setup; otherwise ->
  // register (or arm the replace) / speak the status.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._setup) { this._confirmSetup(); return; }
    var c = this._cycle;
    if (c && c.state === 'alert') { this._ack('tap'); return; }
    if (this._replaceArm) { this._enterSetup(); return; }
    if (!c || c.state === 'done') { this._enterSetup(); return; }
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
    var c = this._cycle;
    if (!c || !c.totalTicks) return null;
    return 1 - c.remainTicks / c.totalTicks;
  },

  // The spike watch only listens during the last stretch of
  // the cycle - or while the finished alert is still waiting
  // for a look-back. Outside that window a loud short sound
  // is just the TV or a door, and earns nothing.
  _spikeWindowOpen() {
    var c = this._cycle;
    if (!c) return false;
    if (c.state === 'alert') return true;
    if (c.state !== 'washing') return false;
    return this._elapsedFrac() >= this._SPIKE_FRAC;
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
    var c = this._cycle;
    if (c && c.state === 'washing') {
      c.remainTicks -= 1;
      if (c.remainTicks < 0) c.remainTicks = 0;
      this._checkCycle();
    }
    this._ackDwellTick();
    if (this._listening) this._sampleLevel();
    if (this._tickCount % 4 === 0) this._recompute();
  },

  // Threshold crossings for the ONE cycle, keyed on tick
  // counts: 3 minutes left = one soft call (only for estimates
  // over 5 minutes - a short wash does not need a warm-up);
  // zero = the alert (spoken once, banner stays).
  _checkCycle() {
    var c = this._cycle;
    if (!c || c.state !== 'washing') return;
    if (!c.preFired && c.totalTicks > this._PRENUDGE_MIN_TOTAL &&
        c.remainTicks <= this._PRENUDGE_TICKS && c.remainTicks > 0) {
      c.preFired = true;
      this._speakText('洗衣快结束了，还剩大约三分钟，准备晾衣服');
      this.setData({
        status: '⏰ 洗衣快结束了（约剩 3 分钟）— 准备晾衣服',
        lastEvent: 'EVT: soft call at 3 min left - spoken once'
      });
    }
    if (c.remainTicks <= 0) {
      c.state = 'alert';
      var text;
      if (this._heading === null) {
        text = '洗衣机到时间了，去晾衣服';
      } else {
        text = this._dirName(this._rel(c.headingDeg, this._heading)).zh + '的洗衣机到时间了，去晾衣服';
      }
      this._speakText(text);
      this.setData({
        status: '⏰ ' + text + ' — 回去看它停 1 秒，或点 ACK',
        lastEvent: 'EVT: zero alert - spoken once, banner stays till you look back'
      });
      this._recompute();
    }
  },

  // ---------- look-back acknowledgement (face the machine) ----------

  // The attention loop closes when you actually go back and
  // look: head steady AND the machine inside the +-15 deg
  // cone. Entering the cone only STARTS the span (same
  // semantics as W01/W02); a further 4 ticks (1s) of
  // continuous facing confirms. Sweeping past earns nothing.
  _ackDwellTick() {
    var c = this._cycle;
    var inCone = c && c.state === 'alert' && this._steady &&
      this._heading !== null &&
      Math.abs(this._rel(c.headingDeg, this._heading)) <= this._ACK_CONE;
    if (!inCone) {
      if (this._ackInCone || this._ackTicks) {
        this._ackInCone = false;
        this._ackTicks = 0;
        if (c && c.state === 'alert') this._recompute();
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
    var c = this._cycle;
    if (!c || c.state !== 'alert') return;
    c.state = 'done';
    c.ackHow = how;
    this._ackTicks = 0;
    this._ackInCone = false;
    this.setData({
      status: '✓ 已回看洗衣机 (' + how + ') — 闭环完成，去晾衣服',
      lastEvent: 'EVT: machine acknowledged by ' + how + ' - loop closed'
    });
    this._recompute();
  },

  ackTap() {
    if (this.data.busy) return;
    if (!this._cycle || this._cycle.state !== 'alert') {
      this.setData({ lastEvent: 'EVT: ACK ignored - the machine is not waiting for a look-back' });
      return;
    }
    this._ack('tap');
  },

  // ---------- register the machine (SET) ----------

  // Registering means: you are standing at the panel NOW.
  // The current heading is captured when setup opens; swipes
  // pick the load (down) and the minutes THE PANEL SHOWS
  // (up) - the number comes from the machine's own display,
  // read by your eyes. A cycle already running is only
  // replaced after an explicit arm + confirm - never silently.
  _enterSetup() {
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'SET FAIL: no heading - stand at the panel, or use DEMO',
        lastEvent: 'EVT: SET refused - the machine must be bound to a real heading'
      });
      return;
    }
    this._replaceArm = false;
    this._setup = {
      loadIdx: 1, // 日常 default
      minIdx: 1,  // 30 minutes default
      headingDeg: Math.round(this._heading),
      replacing: !!(this._cycle && this._cycle.state !== 'done')
    };
    this.setData({
      status: 'REGISTER: ' + this._LOADS[1] + ' · 面板 ' + this._MINUTES[1] +
        ' 分钟 · @ ' + this._setup.headingDeg + ' deg - swipe to adjust, tap to start',
      lastEvent: 'EVT: setup opened at heading ' + this._setup.headingDeg + ' deg' +
        (this._setup.replacing ? ' (replaces the current cycle)' : '')
    });
    this._recompute();
  },

  _setupCycle(which, dir) {
    if (!this._setup) return;
    if (which === 'load') {
      var n = this._LOADS.length;
      this._setup.loadIdx = (((this._setup.loadIdx + dir) % n) + n) % n;
    } else {
      var m = this._MINUTES.length;
      this._setup.minIdx = (((this._setup.minIdx + dir) % m) + m) % m;
    }
    this.setData({
      lastEvent: 'EVT: setup -> ' + this._LOADS[this._setup.loadIdx] + ' · 面板 ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟'
    });
    this._recompute();
  },

  _confirmSetup() {
    var s = this._setup;
    if (!s) return;
    var mins = this._MINUTES[s.minIdx];
    // The load size is only a LABEL - it never feeds the math;
    // the countdown is the minutes the panel showed.
    this._cycle = {
      load: this._LOADS[s.loadIdx],
      headingDeg: s.headingDeg,
      totalTicks: mins * 60 * 4,
      remainTicks: mins * 60 * 4,
      state: 'washing',
      preFired: false,
      ackHow: ''
    };
    this._setup = null;
    this._replaceArm = false;
    this._resetSpike();
    this.setData({
      status: '⏱ 开始守望：面板 ' + mins + ' 分钟（' + this._cycle.load + '）',
      lastEvent: 'EVT: machine registered @ ' + s.headingDeg + ' deg · ' +
        this._cycle.load + ' · panel ' + mins + ' min'
    });
    this._recompute();
  },

  setTap() {
    if (this.data.busy) return;
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: SET ignored in DEMO - the demo cycle is running' });
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
    var c = this._cycle;
    if (c && c.state === 'washing') {
      if (!this._replaceArm) {
        this._replaceArm = true;
        this.setData({
          status: 'REPLACE? 正在洗涤中 — 再点一次 SET 丢弃它、重新登记',
          lastEvent: 'EVT: replace armed - a second SET opens setup'
        });
        this._recompute();
        return;
      }
      this._enterSetup();
      return;
    }
    if (c && c.state === 'alert') {
      this.setData({ lastEvent: 'EVT: SET ignored - look back at the machine first (ACK)' });
      return;
    }
    this._replaceArm = false;
    this._enterSetup();
  },

  // ---------- TIME: setup cycles panel minutes, washing adds +5 min ----------

  timeTap() {
    if (this.data.busy) return;
    if (this._setup) { this._setupCycle('minutes', 1); return; }
    var c = this._cycle;
    if (c && c.state === 'washing') {
      c.totalTicks += 5 * 60 * 4;
      c.remainTicks += 5 * 60 * 4;
      this.setData({
        status: '⏱ 估时 +5 分钟 → 还剩 ' + this._fmtTicks(c.remainTicks),
        lastEvent: 'EVT: estimate extended by 5 min (spin runs long)'
      });
      this._recompute();
      return;
    }
    this.setData({ lastEvent: 'EVT: TIME works while registering, or adds 5 min to a running wash' });
  },

  // ---------- LISTEN: the level watch (LEVEL ONLY) ----------

  // An omnidirectional getUserMedia stream feeds an
  // AnalyserNode; only the RMS loudness number is ever used.
  // There is NO sound classification on this platform, so this
  // watch cannot tell a finished-chime from a door slam or
  // the TV. What it can honestly do: during the LAST 20% of
  // the countdown (or while the finished alert still waits
  // for a look-back), if the level jumps loud and falls quiet
  // again within 2 seconds - the SHAPE of a short sound -
  // nudge you ONCE per episode to go and look. A sustained
  // loud noise (the spin cycle itself) is deliberately NOT a
  // signal: it is far too ambiguous to mean anything.
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
      this._resetSpike();
      this.setData({
        busy: false,
        status: 'LISTENING: a short loud sound in the last stretch = one nudge (level only)',
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

  _resetSpike() {
    this._spikeState = 'idle';
    this._spikeTicks = 0;
    this._spikeFromCooldown = false;
    this._quietTicks = 0;
  },

  _sampleLevel() {
    var lvl;
    if (this._demo) {
      // Scripted demo level: quiet, one short loud burst a
      // couple of seconds in (5 ticks high), then quiet again.
      var dt = this._tickCount - this._demoStartTick;
      lvl = (dt >= 8 && dt <= 12) ? 0.85 : 0.05;
    } else {
      if (!this._analyser || !this._buf) return;
      this._analyser.getFloatTimeDomainData(this._buf);
      var sum = 0;
      for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
      lvl = Math.min(1, Math.sqrt(sum / this._buf.length) * 3);
    }
    this._curLevel = lvl;
    if (lvl >= this._SPIKE_HI) {
      // Loud. If this starts a new high stretch, remember
      // whether we were still cooling down from the last one -
      // a spike inside a cooldown belongs to the SAME episode.
      if (this._spikeState !== 'inspike') {
        this._spikeFromCooldown = (this._spikeState === 'cooldown');
        this._spikeState = 'inspike';
        this._spikeTicks = 0;
      }
      this._spikeTicks += 1;
      this._quietTicks = 0;
    } else if (lvl < this._SPIKE_LO) {
      // Quiet again. If a high stretch just ended, judge it:
      // short (<= 2s) and not a cooldown repeat and inside
      // the window = one nudge. Too long = sustained noise,
      // which earns nothing by design.
      if (this._spikeState === 'inspike') {
        var dur = this._spikeTicks;
        var fromCd = this._spikeFromCooldown;
        this._spikeState = 'cooldown';
        this._spikeTicks = 0;
        if (dur <= this._SPIKE_MAX_TICKS && !fromCd) {
          if (this._spikeWindowOpen()) {
            this._fireSpikeNudge();
          } else {
            this.setData({ lastEvent: 'EVT: short loud sound outside the last stretch - ignored (TV? a door?)' });
          }
        } else if (dur > this._SPIKE_MAX_TICKS) {
          this.setData({ lastEvent: 'EVT: sustained loud level - not a signal (too ambiguous), ignored' });
        }
      }
      this._quietTicks += 1;
      if (this._spikeState === 'cooldown' && this._quietTicks >= this._QUIET_TICKS) {
        this._spikeState = 'idle'; // episode over - re-armed
      }
    } else {
      // In-between level: a spike in progress keeps ageing
      // (a slow fall still counts toward its length); quiet
      // does not accumulate here.
      this._quietTicks = 0;
      if (this._spikeState === 'inspike') this._spikeTicks += 1;
    }
    this._recompute();
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  // One nudge per episode. The wording stays level-based: a
  // loud SHORT SOUND just happened - go look. It never says
  // a chime was recognised, and never says the wash is done.
  _fireSpikeNudge() {
    var text = '刚才有一声响亮的短音，去看一眼洗衣机';
    this._lastNudge = text;
    this._speakText(text);
    this.setData({
      status: '🔊 刚才有一声响亮的短音 — 去看一眼（只是电平，不是蜂鸣识别）',
      lastEvent: 'EVT: short loud spike in the last stretch - nudged once: ' + text
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
    this._resetSpike();
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
    var c = this._cycle;
    if (!c) return '洗衣守望：还没登记洗衣机。';
    if (c.state === 'washing') {
      var sec = Math.ceil(c.remainTicks / 4);
      return '洗衣守望：洗涤中，还剩约' + Math.floor(sec / 60) + '分' + (sec % 60) + '秒到估时。';
    }
    if (c.state === 'alert') return '洗衣守望：估时已到，洗衣机在等你回看确认。';
    return '洗衣守望：这一筒已回看确认，去晾衣服吧。';
  },

  speakTap() {
    if (this.data.busy) return;
    var text = this._statusText();
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  },

  // ---------- DEMO (seeded near the end, memory only - toggles off) ----------

  // DEMO seeds a 45-minute panel cycle already 85% through,
  // the machine dead ahead (0 deg) with the demo head facing
  // AWAY (180 deg), and LISTEN simulated on: a couple of
  // seconds in, the scripted level throws one short loud
  // burst (the spike window is open at 85%) and the nudge
  // fires. Each DEMO tap also fast-forwards the wash by 6% of
  // the estimate and turns the head +45 deg: the 3-minute
  // soft call sounds mid-circle, the zero alert lands, and
  // when the turning head comes back around to the machine
  // (0 deg) and holds 1s, the look-back ack closes the loop.
  // The tap after a full circle exits DEMO and restores your
  // real cycle untouched. DEMO pauses the real cycle (its
  // ticks are held in memory) and writes nothing anywhere -
  // this agent writes nothing anywhere, ever.
  demoTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: DEMO ignored - finish or cancel SET first' });
      return;
    }
    if (!this._demo) {
      if (this._listening) this._stopListen(true);
      this._realCycle = this._cycle;
      this._demo = true;
      this._demoSteps = 0;
      this._demoHeading = 180;
      this._demoStartTick = this._tickCount;
      this._heading = 180;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this._cycle = {
        load: '日常',
        headingDeg: 0,
        totalTicks: 10800,
        remainTicks: 1620,
        state: 'washing',
        preFired: false,
        ackHow: ''
      };
      this._listening = true;
      this._micLabel = 'DEMO (simulated)';
      this._curLevel = 0.05;
      this._resetSpike();
      this._ackTicks = 0;
      this.setData({
        status: 'DEMO WASH - 85% in, spike watch live; tap DEMO: +45 deg, time +6%',
        lastEvent: 'EVT: DEMO on - seeded cycle in memory only, real cycle paused'
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
    var c = this._cycle;
    if (c && c.state === 'washing') {
      c.remainTicks -= Math.round(c.totalTicks * 0.06);
      if (c.remainTicks < 0) c.remainTicks = 0;
      this._checkCycle();
    }
    this.setData({
      status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg · wash fast-forwarded +6%'
    });
    this._recompute();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._cycle = this._realCycle || null;
    this._realCycle = null;
    this._listening = false;
    this._micLabel = 'off';
    this._curLevel = 0;
    this._ackTicks = 0;
    this._ackInCone = false;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real wash is back',
      lastEvent: 'EVT: DEMO off - real cycle restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _machineDirText() {
    var c = this._cycle;
    if (!c || this._heading === null) return null;
    var rel = this._rel(c.headingDeg, this._heading);
    return { rel: rel, text: this._dirName(rel).zh + ' ' + Math.round(Math.abs(rel)) + '°' };
  },

  _rowText() {
    if (this._setup) {
      return '▸ 洗衣机 · 登记中：' + this._LOADS[this._setup.loadIdx] + ' · 面板 ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟 · @ ' + this._setup.headingDeg + '°';
    }
    var c = this._cycle;
    if (!c) return '▸ 洗衣机 · 空 — 站在面板前看着它点 SET 登记';
    var d = this._machineDirText();
    var dirTxt = d ? d.text : '朝向未知';
    if (c.state === 'done') {
      return '▸ 洗衣机 · ✓ 已回看确认 (' + c.ackHow + ') · 面板 ' +
        Math.round(c.totalTicks / 240) + ' 分钟 · ' + c.load + ' · reg ' + c.headingDeg + '°';
    }
    if (c.state === 'alert') {
      return '▸ 洗衣机 · ! 估时已到 · ' + dirTxt + ' · 等你回看 · reg ' + c.headingDeg + '°';
    }
    return '▸ 洗衣机 · 还剩 ' + this._fmtTicks(c.remainTicks) + ' / 面板 ' +
      Math.round(c.totalTicks / 240) + ' 分钟 · ' + c.load + ' · ' + dirTxt +
      ' · reg ' + c.headingDeg + '°';
  },

  _recompute() {
    var patch = {
      headLine: 'HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : '') +
        (this._steady ? ' · HEAD STEADY' : ' · HEAD: moving - hold still')
    };
    var c = this._cycle;
    if (!c) {
      patch.cycleLine = 'WASH: none yet · timers run only while this page is open';
    } else if (c.state === 'washing') {
      patch.cycleLine = 'WASH: ' + c.load + ' · 还剩 ' + this._fmtTicks(c.remainTicks) +
        ' / 面板 ' + Math.round(c.totalTicks / 240) + ' 分钟（' +
        Math.round(this._elapsedFrac() * 100) + '%）· timers run only while open';
    } else if (c.state === 'alert') {
      patch.cycleLine = 'WASH: 估时已到 · ' + c.load + ' · waiting for your look-back';
    } else {
      patch.cycleLine = 'WASH: done · 已回看确认 (' + c.ackHow + ') · ' + c.load;
    }

    if (c && c.state === 'alert') {
      var dwellTxt = this._ackTicks > 0
        ? ' · 看着它 ' + (this._ackTicks * 250 / 1000).toFixed(1) + 's / 1s' : '';
      patch.alertLine = '⏰ 洗衣估时到了 — 回去看它停 1 秒确认，或点 ACK' + dwellTxt;
      patch.alertCls = 'alert alert-on';
    } else {
      patch.alertLine = 'NO ALERT - nothing is waiting for a look-back';
      patch.alertCls = 'alert';
    }

    patch.rows = [{ text: this._rowText() }];

    if (this._listening) {
      patch.listenLine = 'LISTEN: ' + this._micLabel + ' · LVL: ' +
        this._levelBar(this._curLevel) + ' ' + Math.round(this._curLevel * 100) +
        (this._spikeWindowOpen() ? ' · spike watch ON (last stretch)' : ' · spike watch waits for last 20%');
    } else {
      patch.listenLine = 'LISTEN: off · LVL: ---------- 0';
    }
    patch.nudgeLine = this._lastNudge
      ? 'NUDGE: ' + this._lastNudge
      : 'LEVEL WATCH: level only - NOT beep recognition';

    // Guide box: about the machine / setup state.
    if (this._setup) {
      patch.focusName = '▸ 登记洗衣机';
      patch.focusCue = '下滑换衣量 · 上滑换面板分钟数 · 单击（Enter）开始守望';
      patch.guideLine = this._LOADS[this._setup.loadIdx] + ' · 面板 ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟 · 朝向 ' + this._setup.headingDeg +
        '°（衣量只是标签，时间以面板显示为准）';
      patch.guideCls = 'rel rel-on';
    } else if (!c) {
      patch.focusName = '▸ 洗衣机（未登记）';
      patch.focusCue = '站在面板前看着它点 SET：绑朝向、填面板上的分钟数';
      patch.guideLine = this._heading === null
        ? 'NO HEADING — SET needs the sensor (or DEMO): a direction is the whole point'
        : 'LOOKING AT ' + Math.round(this._heading) + '° — SET binds this direction to the machine';
      patch.guideCls = 'rel';
    } else if (c.state === 'done') {
      patch.focusName = '▸ 洗衣机（已回看确认）';
      patch.focusCue = '这一筒闭环了：站在面板前点 SET 可登记下一筒';
      patch.guideLine = '✓ DONE by ' + c.ackHow + ' — SET registers a fresh wash';
      patch.guideCls = 'rel';
    } else if (c.state === 'alert') {
      patch.focusName = '▸ 洗衣机（估时已到）';
      patch.focusCue = '回阳台看向它、头稳住停 1 秒 = 回看确认；或点 ACK';
      patch.guideLine = this._heading === null
        ? '! TIME UP — heading n/a, tap ACK after you have looked'
        : '! TIME UP — the machine is ' +
          this._dirName(this._rel(c.headingDeg, this._heading)).en + ' of you · reg ' +
          c.headingDeg + '°';
      patch.guideCls = 'rel rel-on';
    } else {
      patch.focusName = '▸ 洗衣机 · 还剩 ' + this._fmtTicks(c.remainTicks);
      patch.focusCue = '安心离开阳台 — 剩 3 分钟先轻喊，最后 20% 守听短音';
      if (this._heading === null) {
        patch.guideLine = 'HEADING N/A (SRC NONE) — timer still runs, direction unknown';
        patch.guideCls = 'rel';
      } else {
        var rel2 = this._rel(c.headingDeg, this._heading);
        var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
        var rel360 = (c.headingDeg - this._heading + 360) % 360;
        patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' MACHINE: ' +
          this._dirName(rel2).en + ' ' + Math.round(Math.abs(rel2)) + '° — reg ' +
          c.headingDeg + '°';
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
      <text class="title">LAUNDRY WATCH</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}}</text>
    </view>
    <view class="alert-box">
      <text class="{{alertCls}}">{{alertLine}}</text>
    </view>
    <view class="box">
      <text class="watch">{{cycleLine}}</text>
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
    <text class="foot2">只在本页打开时守望 · 电平 ≠ 蜂鸣识别 · 不存任何记录</text>
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
