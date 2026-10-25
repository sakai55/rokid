<script def>
{
  "navigationBarTitleText": "Cross Street"
}
</script>

<script setup>
import wx from 'wx';

// The verdict line, verbatim. It records that the LOOK happened - it
// is a reference for the ritual, never a judgement about the road.
var VERDICT_LINE = '双向确认完成（仅供参考）— 眼镜看不见车辆，过街全程请继续观察';
var TURN_MIN = 60;        // deg of head turn each side must reach
var HOLD_MS = 1000;       // steady hold that confirms a side
var STEADY_AGE_MS = 250;  // head unchanged this long = settled
var FRESH_MS = 750;       // sample older than this proves nothing: at
                          // 5 Hz a live stream samples every ~200 ms,
                          // so 750 ms of silence is already a dead
                          // stream - and 250 ms settle + 1000 ms hold
                          // can then never fit inside the dead window

export default {
  data: {
    status: 'AT THE CURB — face the road, tap START',
    headLine: 'HEAD: --- deg · REL: --- · SRC: NONE',
    stateLine: 'NO REFERENCE — tap START facing the road',
    rows: [
      { text: '◀ LEFT: turn 60°+ left, hold steady 1 s' },
      { text: '▶ RIGHT: turn 60°+ right, hold steady 1 s' },
      { text: 'LOG: 0 crossings done · LAST —' },
      { text: 'IT SEES HEAD TURNS ONLY — NOT CARS, NOT LIGHTS' }
    ],
    barLine: '◀··+······|······+··▶',
    focusName: 'FACE THE ROAD YOU WILL CROSS',
    focusLine: 'START saves the heading you face as reference',
    arrow: '◎',
    guideLine: 'TURN ≥60° EACH WAY + HOLD 1 s — EITHER ORDER',
    guideCls: 'rel',
    lastEvent: 'EVT: I verify the look, never the traffic',
    busy: false
  },

  onLoad() {
    // ---- ritual state machine (session scope) ----
    this._state = 'IDLE';          // IDLE | RUN | DONE
    this._ref = null;               // reference heading captured by START
    this._heading = null;           // latest head heading (deg, 0..360)
    this._headingSrc = 'NONE';      // SENSOR | DEMO | NONE
    this._prevHeading = null;       // previous sample, for move detection
    this._lastSampleMs = 0;         // wall time of the newest sample
    this._lastMoveMs = 0;           // last time the heading moved >= 2 deg
    this._speed = null;             // latest head speed (deg/s, display)
    this._hostStable = null;        // host stability signal, when it fires
    this._leftDone = false;
    this._rightDone = false;
    this._leftTime = '';
    this._rightTime = '';
    this._holdSide = null;          // 'LEFT' | 'RIGHT' | null
    this._holdMs = 0;
    this._log = [];                 // [{time}] - wx key 'crossStreetLog'
    this._sensor = null;
    this._timer = null;
    this._lastTickMs = 0;
    this._demo = false;
    this._demoHeading = 140;
    this._lastSpeak = null;
    this._loadLog();
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
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._saveLog();
  },

  onOrientationStabilityChange(event) {
    if (this._demo) return; // the demo head's steadiness is simulated
    this._hostStable = !!(event && event.stable);
    if (this._hostStable === false) {
      // The host says the head is moving: any hold in progress dies.
      this._holdSide = null;
      this._holdMs = 0;
    }
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    // A nod is a pitch motion, not a turn: it can never confirm a
    // side. It just reads the current progress aloud, hands-free.
    if (g === 'nod') this.speakTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._state === 'RUN') this.speakTap(); else this.startTap();
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

  _hhmm(d) {
    function p(n) { return (n < 10 ? '0' : '') + n; }
    return p(d.getHours()) + ':' + p(d.getMinutes());
  },

  // ---------- relative-angle math (house convention, as siblings) ----------

  // Signed shortest angle from current to target: -180..180, + = right.
  _rel(target, current) {
    return ((target - current + 540) % 360) - 180;
  },

  // How far the head itself has turned from the reference heading.
  // + = turned right, - = turned left (same sign convention).
  _turnRel() {
    if (this._heading === null || this._ref === null) return null;
    return this._rel(this._heading, this._ref);
  },

  _signed(n) {
    return (n > 0 ? '+' : '') + n;
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
    this._headingSrc = 'SENSOR';
    this._feedHeading(deg, Date.now());
  },

  // One heading sample at wall time nowMs. Tracks the newest sample
  // time (a frozen stream must prove nothing, same rule as #33) and
  // the last time the head actually moved by 2 deg or more - that
  // stillness age, not the raw samples, is what "steady" means here.
  _feedHeading(deg, nowMs) {
    if (this._prevHeading !== null) {
      var d = Math.abs(this._rel(deg, this._prevHeading));
      var dt = (nowMs - this._lastSampleMs) / 1000;
      if (d >= 2) {
        this._lastMoveMs = nowMs;
        if (dt > 0) this._speed = d / dt;
      }
    } else {
      this._lastMoveMs = nowMs;
    }
    this._prevHeading = deg;
    this._heading = deg;
    this._lastSampleMs = nowMs;
  },

  // Steady = the sample stream is alive AND the head has not moved
  // for STEADY_AGE_MS AND the host has not just said "moving".
  _isSteady(nowMs) {
    if (this._heading === null) return false;
    if (nowMs - this._lastSampleMs > FRESH_MS) return false;
    if (this._hostStable === false) return false;
    return (nowMs - this._lastMoveMs) >= STEADY_AGE_MS;
  },

  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._tick(Date.now());
      self._recompute();
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- persistence (wx sync storage, key 'crossStreetLog') ----------

  _loadLog() {
    try {
      var lg = wx.getStorageSync('crossStreetLog');
      if (Array.isArray(lg)) {
        this._log = lg.filter(function (e) {
          return e && typeof e.time === 'string';
        }).slice(-30);
      }
    } catch (e) { /* storage unavailable on this host: log stays in memory */ }
  },

  _saveLog() {
    try { wx.setStorageSync('crossStreetLog', this._log.slice(-30)); } catch (e) {}
  },

  _logCrossing(nowMs) {
    this._log.push({ time: this._hhmm(new Date(nowMs)) });
    if (this._log.length > 30) this._log = this._log.slice(-30);
    this._saveLog();
  },

  // ---------- the look-both-ways state machine ----------
  //
  // IDLE: no reference. START at the curb captures the heading you
  //   face - the agent does not know where the road is, so the
  //   reference is simply wherever you were looking.
  // RUN: each side confirms independently (either order): the head
  //   turned >= 60 deg that way from the reference AND held steady
  //   there for a continuous 1000 ms. Turning without settling, or
  //   settling without turning far enough, confirms nothing; moving
  //   mid-hold, or the sample stream dying, resets the hold.
  // DONE: both sides confirmed -> verdict line + verdict TTS + one
  //   log entry (real rituals only, never DEMO).
  _tick(nowMs) {
    var dt = this._lastTickMs > 0 ? nowMs - this._lastTickMs : 0;
    this._lastTickMs = nowMs;
    if (dt < 0) dt = 0;
    if (dt > 5000) dt = 5000; // a stalled page must not bank time
    if (this._demo) this._lastSampleMs = nowMs; // simulated stream is alive
    if (this._state !== 'RUN') return;
    var rel = this._turnRel();
    if (rel === null) { this._holdSide = null; this._holdMs = 0; return; }
    var side = null;
    if (!this._leftDone && rel <= -TURN_MIN) side = 'LEFT';
    else if (!this._rightDone && rel >= TURN_MIN) side = 'RIGHT';
    if (side && this._isSteady(nowMs)) {
      if (this._holdSide === side) this._holdMs += dt;
      else { this._holdSide = side; this._holdMs = 0; }
      if (this._holdMs >= HOLD_MS) this._confirmSide(side, nowMs);
    } else {
      this._holdSide = null;
      this._holdMs = 0;
    }
  },

  _confirmSide(side, nowMs) {
    var t = this._demo ? 'DEMO' : this._hhmm(new Date(nowMs));
    if (side === 'LEFT') { this._leftDone = true; this._leftTime = t; }
    else { this._rightDone = true; this._rightTime = t; }
    this._holdSide = null;
    this._holdMs = 0;
    if (this._leftDone && this._rightDone) {
      this._state = 'DONE';
      if (!this._demo) this._logCrossing(nowMs);
      this.setData({
        lastEvent: 'EVT: both sides confirmed - verdict spoken' +
          (this._demo ? ' (DEMO, not logged)' : ', ritual logged')
      });
      // One utterance only: the verdict replaces the per-side line,
      // so the two never talk over each other.
      this._speakText('左右都看过了。过街时请继续左右观察，注意车辆。');
    } else {
      this.setData({
        lastEvent: 'EVT: ' + side + ' confirmed by a 1 s steady hold - one side to go'
      });
      this._speakText(side === 'LEFT' ? '左边看过了。' : '右边看过了。');
    }
    this._recompute();
  },

  // ---------- actions ----------

  startTap() {
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO is running - tap CLEAR to exit it first' });
      return;
    }
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a reference.
      this.setData({
        status: 'START FAIL: no heading (SRC NONE)',
        lastEvent: 'EVT: START refused - no heading to capture as reference'
      });
      return;
    }
    this._ref = Math.round(this._heading) % 360;
    this._state = 'RUN';
    this._leftDone = false;
    this._rightDone = false;
    this._leftTime = '';
    this._rightTime = '';
    this._holdSide = null;
    this._holdMs = 0;
    this.setData({
      lastEvent: 'EVT: START - reference ' + this._ref + ' deg (the way you face)'
    });
    this._speakText('开始。向左转头六十度以上，停稳一秒；再向右转头六十度以上，停稳一秒。先看哪边都可以。');
    this._recompute();
  },

  resetTap() {
    this._state = 'IDLE';
    this._ref = null;
    this._leftDone = false;
    this._rightDone = false;
    this._leftTime = '';
    this._rightTime = '';
    this._holdSide = null;
    this._holdMs = 0;
    this.setData({
      lastEvent: 'EVT: RESET - back to the curb, ritual cleared, log kept'
    });
    this._recompute();
  },

  logTap() {
    var n = this._log.length;
    var last = n ? this._log[n - 1] : null;
    var text = n > 0
      ? '本机一共记录了' + n + '次完成的过街确认。最近一次在' + last.time + '。'
      : '本机还没有记录过完成的过街确认。';
    this.setData({
      status: 'LOG: ' + n + ' crossings done' + (last ? ' · LAST ' + last.time : ''),
      lastEvent: 'EVT: log read aloud - times only, nothing else stored'
    });
    this._speakText(text);
    this._recompute();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO: drop the simulated ritual, back to real IDLE.
      this._demo = false;
      this._state = 'IDLE';
      this._ref = null;
      this._leftDone = false;
      this._rightDone = false;
      this._leftTime = '';
      this._rightTime = '';
      this._holdSide = null;
      this._holdMs = 0;
      this._heading = null;
      this._prevHeading = null;
      this._headingSrc = 'NONE';
      this._speed = null;
      this._startHeading();
      this.setData({
        lastEvent: 'EVT: DEMO off - back to the real curb'
      });
      this._recompute();
      return;
    }
    this._log = [];
    this._saveLog();
    this.setData({ lastEvent: 'EVT: crossing log cleared' });
    this._recompute();
  },

  // ---------- DEMO ----------
  //
  // DEMO plays the ritual in memory (nothing is logged, nothing is
  // persisted): the reference is 100 deg, the LEFT side is already
  // confirmed (the simulated head held steady at -65 deg), and the
  // head is now mid-turn to the right at +40 deg with guidance to
  // keep going. One more DEMO tap swings the simulated head to
  // +70 deg and holds it there, so the real state machine confirms
  // RIGHT about a second later and lands on the verdict.
  demoTap() {
    var now = Date.now();
    if (!this._demo) {
      this._demo = true;
      this._headingSrc = 'DEMO';
      this._ref = 100;
      this._state = 'RUN';
      this._leftDone = true;
      this._leftTime = 'DEMO';
      this._rightDone = false;
      this._rightTime = '';
      this._holdSide = null;
      this._holdMs = 0;
      this._demoHeading = 140;
      this._heading = 140;
      this._prevHeading = 140;
      this._lastSampleMs = now;
      this._lastMoveMs = now; // mid-turn: not settled yet
      this._speed = 80;
      this.setData({
        lastEvent: 'EVT: DEMO on - ref 100 deg, LEFT done at -65, head at +40 (memory only)'
      });
    } else if (this._state === 'RUN' && !this._rightDone) {
      this._demoHeading = 170;
      this._heading = 170;
      this._prevHeading = 170;
      this._lastSampleMs = now;
      this._lastMoveMs = now - 300; // it has just settled at +70
      this._speed = 0;
      this.setData({
        lastEvent: 'EVT: DEMO head -> 170 deg (rel +70) - the 1 s hold now runs'
      });
    } else {
      this.setData({ lastEvent: 'EVT: DEMO complete - tap CLEAR to exit' });
    }
    this._recompute();
  },

  // ---------- formatting ----------

  // 21-char progress bar: marker = where your head is between the
  // two hold zones. '+' marks the +-60 deg thresholds, '|' is the
  // reference direction, the ends are the far left / far right.
  _bar(rel) {
    var chars = [];
    var i;
    for (i = 0; i !== 21; i++) chars.push('·');
    chars[10] = '|';
    chars[3] = '+';
    chars[17] = '+';
    chars[0] = '◀';
    chars[20] = '▶';
    if (rel !== null) {
      var idx = Math.round((rel + 90) / 180 * 20);
      if (idx < 0) idx = 0;
      if (idx > 20) idx = 20;
      chars[idx] = '◆';
    }
    return chars.join('');
  },

  // ---------- recompute view ----------

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var rel = this._turnRel();
    var relTxt = rel === null ? '---' : this._signed(Math.round(rel));
    var steadyNow = this._isSteady(Date.now());
    var patch = {
      headLine: 'HEAD: ' + headTxt + ' deg · REL: ' + relTxt + ' · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : '') +
        (this._heading === null ? '' : (steadyNow ? ' · STEADY' : ' · MOVING')),
      barLine: this._bar(rel),
      rows: [
        { text: this._leftDone
          ? '◀ LEFT ✓ DONE ' + this._leftTime
          : '◀ LEFT: turn 60°+ left, hold steady 1 s' },
        { text: this._rightDone
          ? '▶ RIGHT ✓ DONE ' + this._rightTime
          : '▶ RIGHT: turn 60°+ right, hold steady 1 s' },
        { text: 'LOG: ' + this._log.length + ' crossings done · LAST ' +
          (this._log.length ? this._log[this._log.length - 1].time : '—') },
        { text: 'IT SEES HEAD TURNS ONLY — NOT CARS, NOT LIGHTS' }
      ]
    };
    var doneN = (this._leftDone ? 1 : 0) + (this._rightDone ? 1 : 0);
    var demoPre = this._demo ? 'DEMO ' : '';

    if (this._state === 'IDLE') {
      patch.status = 'AT THE CURB — face the road, tap START';
      patch.stateLine = 'NO REFERENCE — tap START facing the road';
      patch.focusName = 'FACE THE ROAD YOU WILL CROSS';
      patch.focusLine = 'START saves the heading you face as reference';
      patch.arrow = '◎';
      patch.guideLine = 'TURN ≥60° EACH WAY + HOLD 1 s — EITHER ORDER';
      patch.guideCls = 'rel';
      this._lastSpeak = {
        text: '过街确认。站在路边，面朝你要过的马路，点开始。然后向左转头六十度以上，停稳一秒；' +
          '再向右转头六十度以上，停稳一秒。眼镜只能确认你转头看过，看不见车辆。'
      };
    } else if (this._state === 'DONE') {
      patch.status = demoPre + 'LOOKED BOTH WAYS — 左右都看过了';
      patch.stateLine = 'REF: ' + this._ref + '° · LEFT ✓ · RIGHT ✓ — BOTH DONE';
      patch.focusName = '左右都看过了 — LOOKED BOTH WAYS';
      patch.focusLine = VERDICT_LINE;
      patch.arrow = '✓';
      patch.guideLine = 'REFERENCE ONLY — KEEP LOOKING WHILE YOU CROSS';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: '左右都看过了。过街时请继续左右观察，注意车辆。' };
    } else { // RUN
      patch.status = demoPre + 'RITUAL ' + doneN + '/2 — ' +
        (doneN === 0 ? 'LOOK LEFT ◀ OR RIGHT ▶' : 'ONE SIDE DONE — NOW THE OTHER');
      patch.stateLine = 'REF: ' + this._ref + '° · LEFT ' +
        (this._leftDone ? '✓' : '…') + ' · RIGHT ' + (this._rightDone ? '✓' : '…');
      this._lastSpeak = {
        text: '过街确认进行中。' +
          (this._leftDone ? '左边已经看过。' : '左边还没看。') +
          (this._rightDone ? '右边已经看过。' : '右边还没看。')
      };
      if (rel === null) {
        patch.focusName = 'HEADING N/A — RITUAL PAUSED';
        patch.focusLine = 'no heading — a sensor is needed to measure the turn';
        patch.arrow = '·';
        patch.guideLine = 'HEADING N/A (SRC NONE) — ritual paused';
        patch.guideCls = 'rel';
      } else {
        var side = null;
        if (!this._leftDone && rel <= -TURN_MIN) side = 'LEFT';
        else if (!this._rightDone && rel >= TURN_MIN) side = 'RIGHT';
        if (side && this._holdSide === side) {
          patch.focusName = 'HOLD STILL — ' + side;
          patch.focusLine = 'holding ' + (this._holdMs / 1000).toFixed(1) +
            's / 1.0s — do not turn back yet';
          patch.arrow = side === 'LEFT' ? '◀' : '▶';
          patch.guideLine = 'HOLDING… ' + (this._holdMs / 1000).toFixed(1) + 's / 1.0s';
          patch.guideCls = 'rel rel-on';
        } else if (side) {
          patch.focusName = 'YOU ARE THERE — SETTLE YOUR HEAD';
          patch.focusLine = 'past 60° — hold still to run the 1 s timer';
          patch.arrow = side === 'LEFT' ? '◀' : '▶';
          patch.guideLine = 'HOLD STILL — TIMER RUNS WHEN SETTLED';
          patch.guideCls = 'rel';
        } else if (doneN === 0) {
          patch.focusName = 'LOOK LEFT ◀ OR RIGHT ▶';
          patch.focusLine = 'turn 60°+ to one side, hold steady 1 s';
          patch.arrow = rel > 0 ? '▶' : (rel < 0 ? '◀' : '◎');
          if (rel > 0) patch.guideLine = 'KEEP TURNING RIGHT — ' + (TURN_MIN - Math.round(rel)) + '° TO THE HOLD ZONE';
          else if (rel < 0) patch.guideLine = 'KEEP TURNING LEFT — ' + (TURN_MIN + Math.round(rel)) + '° TO THE HOLD ZONE';
          else patch.guideLine = 'TURN EITHER WAY — 60° TO A HOLD ZONE';
          patch.guideCls = 'rel';
        } else {
          var other = this._leftDone ? 'RIGHT' : 'LEFT';
          patch.focusName = 'NOW LOOK ' + other + (other === 'LEFT' ? ' ◀' : ' ▶');
          patch.focusLine = 'one side done — the ritual needs both sides';
          patch.arrow = other === 'LEFT' ? '◀' : '▶';
          var need = other === 'RIGHT' ? TURN_MIN - Math.round(rel) : TURN_MIN + Math.round(rel);
          if (need < 0) need = 0;
          patch.guideLine = 'TURN ' + other + ' — ' + need + '° TO THE HOLD ZONE';
          patch.guideCls = 'rel';
        }
      }
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
  },

  speakTap() {
    var s = this._lastSpeak;
    var text = s ? s.text : '还没有过街确认进度。';
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">CROSS STREET</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}}</text>
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
      <text class="bar">{{barLine}}</text>
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{guideCls}}">{{guideLine}}</text>
      </view>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn" bindtap="resetTap">RESET</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="logTap">LOG</button>
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
.bar {
  color: #40ff5e;
  font-family: monospace;
  font-size: 12px;
  line-height: 16px;
  margin-top: 2px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
