<script def>
{
  "navigationBarTitleText": "Stove Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT A POT, TAP SET - I KEEP THE TIMERS',
    headLine: 'HEAD: --- deg · SRC: NONE · HEAD: moving - hold still',
    watchLine: 'WATCH: 0/3 pots · timers run only while this page is open',
    alertLine: 'NO ALERT - nothing has run out yet',
    alertCls: 'alert',
    rows: [
      { text: '▸ 槽 1 · 空 — 看着一口锅点 SET 登记' },
      { text: '  槽 2 · 空' },
      { text: '  槽 3 · 空' }
    ],
    listenLine: 'LISTEN: off · LVL: ---------- 0',
    nudgeLine: 'LOUD WATCH: level only - NOT boiling detection',
    focusName: '▸ 槽 1（空）',
    focusCue: '看着一口锅点 SET：绑朝向、选名字和时长',
    guideLine: 'NO POTS YET - register the first pot you light',
    guideCls: 'rel',
    lastEvent: 'EVT: I watch the clocks - you cook',
    busy: false
  },

  onLoad() {
    // 250ms tick engine, same discipline as the siblings:
    // countdowns, dwell and loud-episodes all accumulate TICK
    // COUNTS, never re-sampled wall-clock deltas.
    this._TICK_MS = 250;
    this._NAMES = ['汤锅', '炒锅', '蒸锅', '饭锅'];
    this._MINUTES = [5, 10, 15, 20, 30];
    this._LOUD_THR = 0.55;   // level threshold for the loud-episode watch
    this._LOUD_TICKS = 40;   // 40 ticks x 250ms = 10s sustained = one nudge
    this._ACK_CONE = 15;     // face-the-pot cone for look-back ack (deg)
    this._ACK_TICKS = 4;     // 4 ticks x 250ms = 1s facing = acknowledged
    this._slots = [null, null, null];
    this._sel = 0;
    this._setup = null;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._sensor = null;
    this._timer = null;
    this._tickCount = 0;
    this._ackIdx = -1;
    this._ackTicks = 0;
    this._listening = false;
    this._stream = null;
    this._actx = null;
    this._analyser = null;
    this._srcNode = null;
    this._buf = null;
    this._micLabel = 'off';
    this._curLevel = 0;
    this._loudTicks = 0;
    this._loudArmed = true;
    this._lastNudge = '';
    this._demo = false;
    this._demoSteps = 0;
    this._demoHeading = 0;
    this._realSlots = null;
    this._realSel = 0;
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
    if (!this._steady) this._resetAckDwell();
    this._recompute();
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // Nod discipline: a steady nod only ever SPEAKS the watch
    // status. A nod never registers a pot, never acknowledges an
    // alert, never starts or stops the listen watch - looking back
    // at the pot (or a deliberate tap) is what closes the loop.
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: nod ignored - finish or cancel SET first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod = speak the watch status (never ack)' });
    this.speakTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier section 3.2.1): single tap = Enter,
  // double-tap = Backspace, swipe = ArrowUp/ArrowDown. The whole
  // main flow (register, watch, look-back ack, hear status) runs
  // on these keys + head-steady + nod.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (Enter) = primary action' });
      this._primaryTap();
    } else if (code === 'ArrowDown') {
      if (this._setup) this._setupCycle('name', 1);
      else this._moveSel(1);
    } else if (code === 'ArrowUp') {
      if (this._setup) this._setupCycle('minutes', 1);
      else this._moveSel(-1);
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
  // setting up -> start that pot; selected pot is alerting ->
  // acknowledge it; selected slot empty -> start registering it;
  // otherwise -> speak the watch status.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._setup) { this._confirmSetup(); return; }
    var pot = this._slots[this._sel];
    if (pot && pot.state === 'alert') { this._ack(this._sel, 'tap'); return; }
    if (!pot) { this._enterSetup(); return; }
    if (pot.state === 'done') { this._enterSetup(); return; }
    this.speakTap();
  },

  _moveSel(dir) {
    this._sel = (((this._sel + dir) % 3) + 3) % 3;
    this.setData({ lastEvent: 'EVT: swipe -> select slot ' + (this._sel + 1) });
    this._recompute();
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

  _activeCount() {
    var n = 0;
    for (var i = 0; i !== 3; i++) {
      var p = this._slots[i];
      if (p && p.state !== 'done') n++;
    }
    return n;
  },

  _firstAlert() {
    for (var i = 0; i !== 3; i++) {
      var p = this._slots[i];
      if (p && p.state === 'alert') return i;
    }
    return -1;
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

  // 250ms tick: poll the sensor (preview hosts may not fire
  // 'reading'), count every cooking pot down in parallel, run the
  // face-to-ack dwell and the loud-episode watch off tick counts.
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
    var fired = false;
    for (var i = 0; i !== 3; i++) {
      var p = this._slots[i];
      if (!p || p.state !== 'cooking') continue;
      p.remainTicks -= 1;
      if (p.remainTicks <= 0) {
        p.remainTicks = 0;
        p.state = 'alert';
        this._fireAlert(i);
        fired = true;
      }
    }
    this._ackDwellTick();
    if (this._listening) this._sampleLevel();
    if (!fired && this._tickCount % 4 === 0) this._recompute();
    else if (fired) this._recompute();
  },

  // A pot ran out: speak ONCE, naming it by where it is relative
  // to you right now ("左边的汤锅到时间了"). The banner then
  // stays until you look back at the pot or tap ACK - it is never
  // re-shouted on a timer.
  _fireAlert(i) {
    var p = this._slots[i];
    var text;
    if (this._heading === null) {
      text = p.name + '到时间了';
    } else {
      text = this._dirName(this._rel(p.headingDeg, this._heading)).zh + '的' + p.name + '到时间了';
    }
    this._speakText(text);
    this.setData({
      status: '⏰ ' + text + ' — 看回它停 1 秒，或点 ACK',
      lastEvent: 'EVT: ' + p.name + ' ran out - spoken once, banner stays till you look back'
    });
  },

  // ---------- look-back acknowledgement (face the pot) ----------

  _resetAckDwell() {
    this._ackIdx = -1;
    this._ackTicks = 0;
  },

  // The attention loop closes when you actually look back: head
  // steady AND an alerting pot inside the +-15 deg cone for 1
  // continuous second (4 ticks). Sweeping past a pot earns
  // nothing; another pot entering the cone restarts the count.
  _ackDwellTick() {
    if (this._firstAlert() < 0) {
      if (this._ackIdx >= 0) this._resetAckDwell();
      return;
    }
    if (!this._steady || this._heading === null) {
      if (this._ackIdx >= 0) this._resetAckDwell();
      return;
    }
    var best = -1, bestAbs = this._ACK_CONE + 1;
    for (var i = 0; i !== 3; i++) {
      var p = this._slots[i];
      if (!p || p.state !== 'alert') continue;
      var a = Math.abs(this._rel(p.headingDeg, this._heading));
      if (a <= this._ACK_CONE && a < bestAbs) { best = i; bestAbs = a; }
    }
    if (best < 0) {
      if (this._ackIdx >= 0) this._resetAckDwell();
      return;
    }
    if (best !== this._ackIdx) {
      this._ackIdx = best;
      this._ackTicks = 0;
      this._recompute();
      return;
    }
    this._ackTicks += 1;
    if (this._ackTicks >= this._ACK_TICKS) {
      this._ack(best, 'face');
    } else {
      this._recompute();
    }
  },

  _ack(i, how) {
    var p = this._slots[i];
    if (!p || p.state !== 'alert') return;
    p.state = 'done';
    p.ackHow = how;
    this._resetAckDwell();
    var left = this._firstAlert();
    this.setData({
      status: '✓ ' + p.name + ' 已回看确认 (' + how + ')' +
        (left >= 0 ? ' — 还有 ' + this._slots[left].name + ' 等你回看' : ''),
      lastEvent: 'EVT: ' + p.name + ' acknowledged by ' + how + ' - loop closed'
    });
    this._recompute();
  },

  ackTap() {
    if (this.data.busy) return;
    var i = (this._slots[this._sel] && this._slots[this._sel].state === 'alert')
      ? this._sel : this._firstAlert();
    if (i < 0) {
      this.setData({ lastEvent: 'EVT: ACK ignored - no pot is waiting for a look-back' });
      return;
    }
    this._ack(i, 'tap');
  },

  // ---------- register a pot (SET) ----------

  // Registering means: you are looking at the pot NOW. The current
  // heading is captured when setup opens; swipes then pick the
  // name (down) and the minutes (up), and one tap starts it.
  _enterSetup() {
    var slot = this._sel;
    var cur = this._slots[slot];
    if (cur && cur.state === 'cooking') {
      this.setData({ lastEvent: 'EVT: SET ignored - slot ' + (slot + 1) + ' is cooking' });
      return;
    }
    if (cur && cur.state === 'alert') {
      this.setData({ lastEvent: 'EVT: SET ignored - look back at that pot first (ACK)' });
      return;
    }
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'SET FAIL: no heading - look at the pot, or use DEMO',
        lastEvent: 'EVT: SET refused - a pot must be bound to a real heading'
      });
      return;
    }
    this._setup = {
      slot: slot,
      nameIdx: 0,
      minIdx: 1, // 10 minutes default
      headingDeg: Math.round(this._heading)
    };
    this.setData({
      status: 'REGISTER: ' + this._NAMES[0] + ' · ' + this._MINUTES[1] +
        ' min · @ ' + this._setup.headingDeg + ' deg - swipe to adjust, tap to start',
      lastEvent: 'EVT: setup opened on slot ' + (slot + 1) +
        ' at heading ' + this._setup.headingDeg + ' deg'
    });
    this._recompute();
  },

  _setupCycle(which, dir) {
    if (!this._setup) return;
    if (which === 'name') {
      var n = this._NAMES.length;
      this._setup.nameIdx = (((this._setup.nameIdx + dir) % n) + n) % n;
    } else {
      var m = this._MINUTES.length;
      this._setup.minIdx = (((this._setup.minIdx + dir) % m) + m) % m;
    }
    this.setData({
      lastEvent: 'EVT: setup -> ' + this._NAMES[this._setup.nameIdx] + ' · ' +
        this._MINUTES[this._setup.minIdx] + ' min'
    });
    this._recompute();
  },

  _confirmSetup() {
    var s = this._setup;
    if (!s) return;
    var mins = this._MINUTES[s.minIdx];
    this._slots[s.slot] = {
      name: this._NAMES[s.nameIdx],
      headingDeg: s.headingDeg,
      totalTicks: mins * 60 * 4,
      remainTicks: mins * 60 * 4,
      state: 'cooking',
      ackHow: ''
    };
    this._setup = null;
    this.setData({
      status: '⏱ ' + this._slots[s.slot].name + ' 计时开始：' + mins + ' 分钟',
      lastEvent: 'EVT: slot ' + (s.slot + 1) + ' registered ' + this._slots[s.slot].name +
        ' @ ' + s.headingDeg + ' deg · ' + mins + ' min'
    });
    this._recompute();
  },

  setTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this._setup = null;
      this.setData({
        status: 'REGISTER CANCELLED - nothing started',
        lastEvent: 'EVT: setup cancelled'
      });
      this._recompute();
      return;
    }
    this._enterSetup();
  },

  // ---------- TIME: setup cycles presets, cooking adds +5 min ----------

  timeTap() {
    if (this.data.busy) return;
    if (this._setup) { this._setupCycle('minutes', 1); return; }
    var p = this._slots[this._sel];
    if (p && p.state === 'cooking') {
      p.totalTicks += 5 * 60 * 4;
      p.remainTicks += 5 * 60 * 4;
      this.setData({
        status: '⏱ ' + p.name + ' +5 分钟 → 还剩 ' + this._fmtTicks(p.remainTicks),
        lastEvent: 'EVT: ' + p.name + ' extended by 5 min'
      });
      this._recompute();
      return;
    }
    this.setData({ lastEvent: 'EVT: TIME works while registering, or adds 5 min to a cooking pot' });
  },

  // ---------- LISTEN: the loud-episode watch (LEVEL ONLY) ----------

  // An omnidirectional getUserMedia stream feeds an AnalyserNode;
  // only the RMS loudness number is ever used. There is NO sound
  // classification on this platform: this watch cannot tell
  // boiling from a dropped lid or a loud TV, and it never claims
  // to. If the kitchen stays loud for 10 continuous seconds it
  // nudges you ONCE per loud episode to glance at the pot in
  // front of you; it re-arms only after the level drops again.
  async listenTap() {
    if (this.data.busy) return;
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
      this._loudTicks = 0;
      this._loudArmed = true;
      this.setData({
        busy: false,
        status: 'LISTENING: loud 10s = one nudge (level only)',
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
    if (!this._analyser || !this._buf) return;
    this._analyser.getFloatTimeDomainData(this._buf);
    var sum = 0;
    for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
    var lvl = Math.min(1, Math.sqrt(sum / this._buf.length) * 3);
    this._curLevel = lvl;
    if (lvl > this._LOUD_THR) {
      this._loudTicks += 1;
      if (this._loudTicks >= this._LOUD_TICKS && this._loudArmed) {
        this._loudArmed = false;
        this._fireNudge();
      }
    } else {
      this._loudTicks = 0;
      this._loudArmed = true; // a quiet stretch re-arms the next episode
    }
    this._recompute();
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  // One nudge per loud episode. The wording stays level-based:
  // the kitchen has been LOUD - go glance at the pot nearest to
  // where you are facing. It never says a pot is boiling over.
  _fireNudge() {
    var target = null;
    if (this._heading !== null) {
      var bestAbs = 46;
      for (var i = 0; i !== 3; i++) {
        var p = this._slots[i];
        if (!p || p.state === 'done') continue;
        var a = Math.abs(this._rel(p.headingDeg, this._heading));
        if (a <= 45 && a < bestAbs) { target = p; bestAbs = a; }
      }
    }
    var text = target
      ? '厨房声音持续很大，看一眼你' +
        this._dirName(this._rel(target.headingDeg, this._heading)).zh + '的' + target.name
      : '厨房声音持续很大，看一眼你正前方的锅';
    this._lastNudge = text;
    this._speakText(text);
    this.setData({
      status: '🔊 厨房持续很响 — 回看一眼（只是响度，不是沸腾识别）',
      lastEvent: 'EVT: loud episode >=10s - nudged once: ' + text
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
    this._loudTicks = 0;
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
    var parts = [];
    for (var i = 0; i !== 3; i++) {
      var p = this._slots[i];
      if (!p) continue;
      if (p.state === 'cooking') {
        var sec = Math.ceil(p.remainTicks / 4);
        parts.push(p.name + '还剩' + Math.floor(sec / 60) + '分' + (sec % 60) + '秒');
      } else if (p.state === 'alert') {
        parts.push(p.name + '到时间了，还没回看确认');
      } else {
        parts.push(p.name + '已确认');
      }
    }
    if (!parts.length) return '现在没有在煮的锅。';
    return '灶台守望：' + parts.join('；') + '。';
  },

  speakTap() {
    if (this.data.busy) return;
    var text = this._statusText();
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  },

  // ---------- DEMO (seeded mid-cook, memory only - toggles off) ----------

  // DEMO seeds two pots mid-cook with the demo head facing AWAY
  // (180 deg): the soup pot in front-left is 6 seconds from done,
  // so it runs out and SHOUTS once while the banner waits; step
  // the heading +45 deg per DEMO tap until you face it (0 deg,
  // inside its +-15 deg cone) and hold 1s - the look-back ack
  // fires and the loop closes. The tap after a full circle exits
  // DEMO and restores your real slots untouched. DEMO pauses the
  // real pots (their ticks are held in memory) and writes nothing
  // anywhere - this agent writes nothing anywhere, ever.
  demoTap() {
    if (this.data.busy) return;
    if (this._setup) {
      this.setData({ lastEvent: 'EVT: DEMO ignored - finish or cancel SET first' });
      return;
    }
    if (!this._demo) {
      if (this._listening) this._stopListen(true);
      this._realSlots = this._slots;
      this._realSel = this._sel;
      this._demo = true;
      this._demoSteps = 0;
      this._demoHeading = 180;
      this._heading = 180;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this._slots = [
        { name: '汤锅', headingDeg: 350, totalTicks: 7200, remainTicks: 24, state: 'cooking', ackHow: '' },
        { name: '蒸锅', headingDeg: 90, totalTicks: 2400, remainTicks: 1200, state: 'cooking', ackHow: '' },
        null
      ];
      this._sel = 0;
      this._resetAckDwell();
      this.setData({
        status: 'DEMO COOK - soup runs out in ~6s; tap DEMO to turn +45',
        lastEvent: 'EVT: DEMO on - seeded pots in memory only, real pots paused'
      });
      this._recompute();
      return;
    }
    if (this._demoSteps >= 8) {
      this._exitDemo();
      return;
    }
    this._demoSteps += 1;
    this._demoHeading = (this._demoHeading + 45) % 360;
    this._heading = this._demoHeading;
    this._headingSrc = 'DEMO';
    this.setData({
      status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
    });
    this._recompute();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._slots = this._realSlots || [null, null, null];
    this._sel = this._realSel || 0;
    this._realSlots = null;
    this._resetAckDwell();
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real pots are back',
      lastEvent: 'EVT: DEMO off - real slots restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _rowText(i) {
    var cur = i === this._sel ? '▸ ' : '  ';
    var p = this._slots[i];
    if (this._setup && this._setup.slot === i) {
      return cur + '槽 ' + (i + 1) + ' · 登记中：' + this._NAMES[this._setup.nameIdx] +
        ' · ' + this._MINUTES[this._setup.minIdx] + ' 分钟 · @ ' + this._setup.headingDeg + '°';
    }
    if (!p) return cur + '槽 ' + (i + 1) + ' · 空';
    if (p.state === 'done') {
      return cur + p.name + ' · ✓ 已回看确认 (' + p.ackHow + ') · 设定 ' +
        Math.round(p.totalTicks / 240) + ' 分钟 · reg ' + p.headingDeg + '°';
    }
    var dirTxt;
    if (this._heading === null) {
      dirTxt = '朝向未知';
    } else {
      var rel = this._rel(p.headingDeg, this._heading);
      dirTxt = this._dirName(rel).zh + ' ' + Math.round(Math.abs(rel)) + '°';
    }
    if (p.state === 'alert') {
      return cur + p.name + ' · ! 到时间了 · ' + dirTxt + ' · 等你回看 · reg ' + p.headingDeg + '°';
    }
    return cur + p.name + ' · 还剩 ' + this._fmtTicks(p.remainTicks) + ' · ' +
      dirTxt + ' · reg ' + p.headingDeg + '°';
  },

  _recompute() {
    var patch = {
      headLine: 'HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : '') +
        (this._steady ? ' · HEAD STEADY' : ' · HEAD: moving - hold still')
    };
    var cooking = 0, alerting = 0;
    for (var i = 0; i !== 3; i++) {
      var p = this._slots[i];
      if (!p) continue;
      if (p.state === 'cooking') cooking++;
      if (p.state === 'alert') alerting++;
    }
    patch.watchLine = 'WATCH: ' + this._activeCount() + '/3 pots on timers · ' +
      cooking + ' cooking · ' + alerting + ' waiting for a look-back' +
      ' · timers run only while open';

    var fa = this._firstAlert();
    if (fa >= 0) {
      var ap = this._slots[fa];
      var dwellTxt = (this._ackIdx === fa && this._ackTicks > 0)
        ? ' · 看着它 ' + (this._ackTicks * 250 / 1000).toFixed(1) + 's / 1s' : '';
      patch.alertLine = '⏰ ' + ap.name + ' 到时间了 — 转头看它停 1 秒确认，或点 ACK' + dwellTxt;
      patch.alertCls = 'alert alert-on';
    } else {
      patch.alertLine = 'NO ALERT - nothing is waiting for a look-back';
      patch.alertCls = 'alert';
    }

    var self = this;
    patch.rows = [0, 1, 2].map(function (i) { return { text: self._rowText(i) }; });

    if (this._listening) {
      patch.listenLine = 'LISTEN: ' + this._micLabel + ' · LVL: ' +
        this._levelBar(this._curLevel) + ' ' + Math.round(this._curLevel * 100) +
        ' · loud ' + (this._loudTicks * 250 / 1000).toFixed(0) + 's / 10s';
    } else {
      patch.listenLine = 'LISTEN: off · LVL: ---------- 0';
    }
    patch.nudgeLine = this._lastNudge
      ? 'NUDGE: ' + this._lastNudge
      : 'LOUD WATCH: level only - NOT boiling detection';

    // Guide box: about the SELECTED slot / setup state.
    var sel = this._slots[this._sel];
    if (this._setup) {
      patch.focusName = '▸ 登记槽 ' + (this._setup.slot + 1);
      patch.focusCue = '下滑换名字 · 上滑换时长 · 单击（Enter）开始计时';
      patch.guideLine = this._NAMES[this._setup.nameIdx] + ' · ' +
        this._MINUTES[this._setup.minIdx] + ' 分钟 · 朝向 ' + this._setup.headingDeg +
        '°（点 SET 那一刻的正前方）';
      patch.guideCls = 'rel rel-on';
    } else if (!sel) {
      patch.focusName = '▸ 槽 ' + (this._sel + 1) + '（空）';
      patch.focusCue = '看着一口锅点 SET：绑朝向、选名字和时长';
      patch.guideLine = this._heading === null
        ? 'NO HEADING — find a pot by eye is not enough: SET needs the sensor (or DEMO)'
        : 'LOOKING AT ' + Math.round(this._heading) + '° — SET binds this direction to the pot';
      patch.guideCls = 'rel';
    } else if (sel.state === 'done') {
      patch.focusName = '▸ ' + sel.name + '（已确认）';
      patch.focusCue = '这一槽空出来了：看着下一口锅点 SET 重新登记';
      patch.guideLine = '✓ DONE by ' + sel.ackHow + ' — SET re-registers this slot';
      patch.guideCls = 'rel';
    } else if (sel.state === 'alert') {
      patch.focusName = '▸ ' + sel.name + '（到时间了）';
      patch.focusCue = '转头看向它、头稳住停 1 秒 = 回看确认；或点 ACK';
      patch.guideLine = this._heading === null
        ? '! TIME UP — heading n/a, tap ACK after you have looked'
        : '! TIME UP — it is ' +
          this._dirName(this._rel(sel.headingDeg, this._heading)).en + ' of you · reg ' +
          sel.headingDeg + '°';
      patch.guideCls = 'rel rel-on';
    } else {
      patch.focusName = '▸ ' + sel.name + ' · 还剩 ' + this._fmtTicks(sel.remainTicks);
      patch.focusCue = '安心备菜 — 到点它按方向叫你回看';
      if (this._heading === null) {
        patch.guideLine = 'HEADING N/A (SRC NONE) — timer still runs, direction unknown';
        patch.guideCls = 'rel';
      } else {
        var rel2 = this._rel(sel.headingDeg, this._heading);
        var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
        var rel360 = (sel.headingDeg - this._heading + 360) % 360;
        patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' TURN: ' +
          this._dirName(rel2).en + ' ' + Math.round(Math.abs(rel2)) + '° — ' +
          sel.name + ' reg ' + sel.headingDeg + '°';
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
      <text class="title">STOVE WATCH</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}}</text>
    </view>
    <view class="alert-box">
      <text class="{{alertCls}}">{{alertLine}}</text>
    </view>
    <view class="box">
      <text class="watch">{{watchLine}}</text>
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
    <text class="foot2">只在本页打开时守望 · 电平 ≠ 沸腾识别 · 不存任何记录</text>
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
