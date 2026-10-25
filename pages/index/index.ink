<script def>
{
  "navigationBarTitleText": "Photo Level"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'FRAME YOUR SHOT - the grid floats over your REAL view',
    steadyText: 'HEAD: moving - hold still',
    rawLine: 'RAW R --- P --- · SRC NONE · CAL —',
    rollText: 'ROLL ---',
    levelLine: 'LEVEL: n/a - no sensor reading yet',
    levelCls: 'level',
    g0: 'cell cr cb', g1: 'cell cr cb', g2: 'cell cb',
    g3: 'cell cr cb', g4: 'cell cr cb', g5: 'cell cb',
    g6: 'cell cr', g7: 'cell cr', g8: 'cell',
    crossCls: 'cross',
    gridLine: 'GRID: FULL thirds (swipe cycles FULL / HORIZON / OFF)',
    tipLine: 'TIP: put the subject on a + cross point, not dead centre',
    shotHead: 'SHOTS (session only, NEVER saved): 0/6',
    shotRows: [],
    lastEvent: 'EVT: no camera feed here - the photo is taken only at SNAP',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._roll = null;         // latest RAW roll from the quaternion (deg)
    this._pitch = null;        // latest RAW pitch from the quaternion (deg)
    this._rollSrc = 'NONE';    // 'SENSOR' | 'DEMO' | 'NONE'
    this._sensor = null;
    this._timer = null;
    this._cal = null;          // {roll, pitch} session zero offsets (CALIB)
    this._gridIdx = 0;         // 0 FULL thirds | 1 HORIZON | 2 OFF
    this._tipIdx = 0;
    this._shots = [];          // session shot records, newest first, cap 6
    this._demo = false;
    this._demoStep = 0;
    this._demoSavedCal = null;
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
  },

  onUnload() {
    this._stopTimer();
    this._stopSensor();
    // Nothing is saved on unload either: this agent stores NOTHING.
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - nod = SNAP' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // Nod discipline: a nod is a shutter ONLY with a steady head AND
    // a live orientation reading (sensor or DEMO) - the shot's whole
    // point is its level verdict, so a nod with no reading is refused
    // honestly instead of firing blind. SNAP / Enter still work
    // without a sensor; their verdict is then "ROLL n/a".
    if (this.data.busy) {
      this.setData({ lastEvent: 'EVT: nod ignored - busy' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    if (this._roll === null) {
      this.setData({ lastEvent: 'EVT: nod refused - no orientation reading; use SNAP (verdict will be n/a)' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod (steady) = SNAP' });
    this.snapTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier section 3.2.1): single tap arrives as
  // Enter, double-tap as Backspace, swipe as ArrowUp/ArrowDown.
  // Enter is kept to ONE meaning - SNAP - so the shutter is never a
  // surprise. Swipes cycle the grid style. The five on-screen
  // buttons mirror these actions for tapping.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (' + code + ') = SNAP' });
      this.snapTap();
    } else if (code === 'ArrowUp') {
      this._cycleGrid(1);
    } else if (code === 'ArrowDown') {
      this._cycleGrid(-1);
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

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // ONE clock snapshot -> "HH:MM" (the preview host's Date is
  // virtualised and drifts between calls - same lesson as DI25/DI38).
  _timeStr() {
    var d = new Date();
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
  },

  _fmtDeg(v) {
    if (v === null || v === undefined || !isFinite(v)) return '---';
    var r = Math.round(v * 10) / 10;
    if (r === 0) r = 0; // normalise -0
    return (r > 0 ? '+' : '') + r.toFixed(1) + '°';
  },

  // ---------- orientation: roll / pitch from the quaternion ----------
  //
  // Standard ZYX Euler decomposition of the orientation quaternion
  // q = [x, y, z, w] (the composition Rz(yaw) * Ry(pitch) * Rx(roll)):
  //   roll  = atan2(2(wx + yz), 1 - 2(x^2 + y^2))   (about X)
  //   pitch = asin(clamp(2(wy - zx), -1, 1))        (about Y)
  // Verified in Node against quaternions composed independently
  // from axis-angle rotations. WHICH physical tilt each component
  // is on the real glasses depends on the host's sensor frame,
  // which the dossier does not fix - that is exactly why CALIB
  // zeroes both components against YOUR level pose, and why the
  // RAW values are always shown next to the corrected ones.
  _eulerZYX(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var n = Math.sqrt(x * x + y * y + z * z + w * w);
    if (!isFinite(n) || n < 1e-6) return null;
    x /= n; y /= n; z /= n; w /= n;
    var roll = Math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y)) * 180 / Math.PI;
    var s = 2 * (w * y - z * x);
    if (s > 1) s = 1;
    if (s < -1) s = -1;
    var pitch = Math.asin(s) * 180 / Math.PI;
    return { roll: roll, pitch: pitch };
  },

  _startSensor() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._rollSrc = 'NONE';
      this._recompute();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onSensor(s); });
      s.addEventListener('error', function (ev) {
        self._rollSrc = 'NONE';
        self._roll = null;
        self._pitch = null;
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - roll NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._rollSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopSensor() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  _onSensor(sensor) {
    if (this._demo) return; // demo readings win while simulating
    var e = this._eulerZYX(sensor.quaternion);
    if (!e) return;
    var changed = this._roll === null ||
      Math.abs(e.roll - this._roll) >= 0.1 || Math.abs(e.pitch - this._pitch) >= 0.1;
    this._roll = e.roll;
    this._pitch = e.pitch;
    this._rollSrc = 'SENSOR';
    if (changed) this._recompute();
  },

  // 250 ms tick: poll the sensor (preview hosts may not fire
  // 'reading' events) and refresh the level readout.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onSensor(self._sensor);
      } else if (self._roll !== null) {
        self._recompute();
      }
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // Corrected readings: raw minus YOUR calibrated zero (session
  // only). With no CALIB the offsets are 0 and corrected == raw,
  // labelled as the raw frame.
  _corrRoll() {
    if (this._roll === null) return null;
    return this._roll - (this._cal ? this._cal.roll : 0);
  },

  _corrPitch() {
    if (this._pitch === null) return null;
    return this._pitch - (this._cal ? this._cal.pitch : 0);
  },

  _isLevel(corrRoll) {
    return corrRoll !== null && Math.abs(corrRoll) <= 2;
  },

  _verdict(corrRoll) {
    if (corrRoll === null) return 'ROLL n/a (no sensor)';
    if (this._isLevel(corrRoll)) return 'LEVEL ✓';
    return 'TILTED ' + this._fmtDeg(corrRoll);
  },

  // ---------- composition tips (STATIC guidance text) ----------
  //
  // These tips are fixed text, rotated on SNAP and on grid changes.
  // The agent does NOT detect subjects, horizons or anything else
  // in the scene - the wearer does the seeing; the tips only remind.
  _tips() {
    return [
      'put the subject on a + cross point, not dead centre',
      'rest the horizon on a third line, upper or lower - not the middle',
      'leave space in front of a face or a moving subject',
      'stand a tall subject (tree, tower) along a vertical third line',
      'foreground on one edge, subject on a cross, sky on the top third'
    ];
  },

  _nextTip() {
    this._tipIdx = ((this._tipIdx || 0) + 1) % this._tips().length;
  },

  // ---------- grid styles ----------

  _gridNames() { return ['FULL', 'HORIZON', 'OFF']; },

  _cycleGrid(dir) {
    this._gridIdx = (((this._gridIdx || 0) + dir) % 3 + 3) % 3;
    this._nextTip();
    this.setData({
      lastEvent: 'EVT: swipe -> grid ' + this._gridNames()[this._gridIdx]
    });
    this._recompute();
  },

  gridTap() { this._cycleGrid(1); },

  _gridPatch() {
    var full = [
      'cell cr cb', 'cell cr cb', 'cell cb',
      'cell cr cb', 'cell cr cb', 'cell cb',
      'cell cr', 'cell cr', 'cell'
    ];
    var horizon = [
      'cell cb', 'cell cb', 'cell cb',
      'cell cb', 'cell cb', 'cell cb',
      'cell', 'cell', 'cell'
    ];
    var off = ['cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell'];
    var cells = this._gridIdx === 0 ? full : (this._gridIdx === 1 ? horizon : off);
    var patch = { crossCls: this._gridIdx === 0 ? 'cross' : 'cross cross-off' };
    for (var i = 0; i < 9; i++) patch['g' + i] = cells[i];
    patch.gridLine = this._gridIdx === 0
      ? 'GRID: FULL thirds (swipe cycles FULL / HORIZON / OFF)'
      : this._gridIdx === 1
        ? 'GRID: HORIZON lines only (swipe cycles FULL / HORIZON / OFF)'
        : 'GRID: OFF - level only (swipe cycles FULL / HORIZON / OFF)';
    return patch;
  },

  // ---------- CALIB (relative zero - YOUR level pose, session only) ----------

  calibTap() {
    if (this._roll === null || this._pitch === null) {
      // Never invent a zero: no reading, no calibration.
      this.setData({
        status: 'CALIB FAIL: no orientation reading - sensor n/a',
        lastEvent: 'EVT: CALIB refused - never invent a zero; tap DEMO to simulate'
      });
      return;
    }
    this._cal = { roll: this._roll, pitch: this._pitch };
    this.setData({
      status: 'CALIBRATED - this pose is YOUR level (session only)',
      lastEvent: 'EVT: CALIB zero <- RAW R ' + this._fmtDeg(this._roll) +
        ' P ' + this._fmtDeg(this._pitch) + (this._demo ? ' (DEMO)' : '')
    });
    this._recompute();
  },

  // ---------- SNAP (the only moment a photo exists) ----------

  snapTap() { this._snap(); },

  async _snap() {
    if (this.data.busy) return;
    // The verdict belongs to the CAPTURE INSTANT: freeze the
    // corrected roll/pitch now, before any async camera work.
    var capRoll = this._corrRoll();
    var capPitch = this._corrPitch();
    var capTime = this._timeStr();

    if (this._demo) {
      this._recordShot({
        time: capTime, roll: capRoll, pitch: capPitch,
        bytes: 0, demo: true, wxPhoto: false
      });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'SNAP FAIL - no camera on this host; no shot taken',
        lastEvent: 'EVT: SNAP FAIL (host has no camera) - nothing recorded'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (default mode)...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'photo');
      var bytes = blob && blob.size ? blob.size : 0;
      // The Blob itself is deliberately NOT kept: the shot record
      // holds only time + roll/pitch + verdict. Photo bytes stay in
      // this session and are never written anywhere.
      this._recordShot({
        time: capTime, roll: capRoll, pitch: capPitch,
        bytes: bytes, demo: false, wxPhoto: false
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null;
      }
      // Fallback: wx camera context (like the sibling agents).
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this._recordShot({
          time: capTime, roll: capRoll, pitch: capPitch,
          bytes: size, demo: false, wxPhoto: true
        });
      } catch (e3) {
        this.setData({
          status: 'SNAP FAIL - ' + this._err(firstErr) + '; no shot taken',
          lastEvent: 'EVT: SNAP FAIL - ' + this._err(firstErr)
        });
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
      this.setData({ busy: false });
    }
  },

  _recordShot(shot) {
    shot.verdict = this._verdict(shot.roll);
    this._shots.unshift(shot);
    var dropped = false;
    while (this._shots.length > 6) { this._shots.pop(); dropped = true; }
    this._nextTip();
    this.setData({
      status: 'SHOT #' + this._shots.length + ' · ' + shot.verdict +
        ' · roll ' + this._fmtDeg(shot.roll) + (shot.demo ? ' (DEMO)' : ''),
      lastEvent: 'EVT: shot ' + shot.time + ' · ' + shot.verdict + ' · ' + shot.bytes + 'B' +
        (shot.wxPhoto ? ' (wx fallback)' : '') + (shot.demo ? ' (DEMO, 0 bytes)' : '') +
        ' - photo NOT saved' + (dropped ? '; oldest shot dropped (session cap 6)' : '')
    });
    this._recompute();
  },

  // ---------- DEMO (simulated roll sweep, memory only) ----------
  //
  // DEMO roll steps sweep -8 deg up through +1 deg (the LEVEL band)
  // and beyond, so both verdicts preview. DEMO pitch is a fixed
  // simulated +2.0 deg. Tapping DEMO past the last step exits and
  // restores the real calibration and sensor state. DEMO shots are
  // labelled DEMO with 0 bytes. Nothing is written anywhere, ever.

  _demoRolls() { return [-8, -5.5, -3, -1, 1, 4, 7]; },

  demoTap() {
    var rolls = this._demoRolls();
    if (!this._demo) {
      this._demo = true;
      this._demoSavedCal = this._cal;
      this._demoStep = 0;
      this._roll = rolls[0];
      this._pitch = 2.0;
      this._rollSrc = 'DEMO';
      this.setData({
        status: 'DEMO - simulated roll sweeping (tap DEMO to step)',
        lastEvent: 'EVT: DEMO on - roll ' + this._fmtDeg(this._roll) + ' (pitch simulated +2.0°)'
      });
      this._recompute();
      return;
    }
    this._demoStep += 1;
    if (this._demoStep >= rolls.length) {
      // Past the last step: exit DEMO, restore the real session.
      this._demo = false;
      this._cal = this._demoSavedCal;
      this._demoSavedCal = null;
      this._roll = null;
      this._pitch = null;
      this._rollSrc = this._sensor ? 'SENSOR' : 'NONE';
      if (!this._sensor) this._startSensor();
      this.setData({
        status: 'DEMO OFF - real sensor state restored',
        lastEvent: 'EVT: DEMO off - your calibration (if any) restored'
      });
      this._recompute();
      return;
    }
    this._roll = rolls[this._demoStep];
    this._pitch = 2.0;
    this._rollSrc = 'DEMO';
    this.setData({
      status: 'DEMO - simulated roll ' + this._fmtDeg(this._roll),
      lastEvent: 'EVT: DEMO roll -> ' + this._fmtDeg(this._roll) + ' (step ' +
        (this._demoStep + 1) + '/' + rolls.length + ')'
    });
    this._recompute();
  },

  // ---------- speech (TTS out only; lang is never set) ----------

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6).
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  _degZh(v) { return String(Math.round(Math.abs(v))); },

  speakTap() {
    var text;
    var last = this._shots[0];
    if (!last) {
      var c = this._corrRoll();
      text = c === null
        ? '还没拍照，也没有传感器读数。先对准画面，点头或点 SNAP 拍一张。'
        : '还没拍照。现在横滚' + this._fmtDeg(c) + '，' +
          (this._isLevel(c) ? '是平的，可以拍。' : '先把头摆平再拍。');
    } else if (last.roll === null) {
      text = '上一张没有水平读数，拍的时候没有传感器。';
    } else if (this._isLevel(last.roll)) {
      text = '这一张水平很好，拍摄时横滚' + this._fmtDeg(last.roll) + '。';
    } else {
      text = '这一张向' + (last.roll > 0 ? '右' : '左') + '歪了' +
        this._degZh(last.roll) + '度。';
    }
    var ok = this._speak(text);
    this.setData({
      lastEvent: ok ? 'EVT: TTS speak sent: ' + text
        : 'EVT: SPEAK FAIL - speechSynthesis n/a on this host'
    });
  },

  // ---------- rendering ----------

  _bubble(corrRoll) {
    // A 15-char bubble level: the bubble sits at the centre tick
    // when the corrected roll is 0; 1 char ~ 1.2 deg of tilt.
    if (corrRoll === null) return '|···············|';
    var idx = Math.round(corrRoll / 1.2);
    if (idx > 7) idx = 7;
    if (idx < -7) idx = -7;
    var pos = 7 + idx;
    var s = '';
    for (var i = 0; i < 15; i++) {
      s += i === pos ? '●' : (i === 7 ? '|' : '·');
    }
    return '|' + s + '|';
  },

  _horizon(corrRoll) {
    if (corrRoll === null) return '─ ─ ─ ─ ─';
    if (this._isLevel(corrRoll)) return '━━━━ LEVEL ✓ ━━━━';
    return corrRoll > 0 ? '╲ ╲ ╲ TILTED' : '╱ ╱ ╱ TILTED';
  },

  _recompute() {
    var corrRoll = this._corrRoll();
    var corrPitch = this._corrPitch();
    var patch = {
      rawLine: 'RAW R ' + this._fmtDeg(this._roll) + ' P ' + this._fmtDeg(this._pitch) +
        ' · SRC ' + this._rollSrc +
        ' · CAL ' + (this._cal ? 'R ' + this._fmtDeg(this._cal.roll) + ' P ' + this._fmtDeg(this._cal.pitch) : '—'),
      rollText: 'ROLL ' + this._fmtDeg(corrRoll) +
        (this._cal ? '' : ' (raw)'),
      tipLine: 'TIP: ' + this._tips()[this._tipIdx || 0]
    };
    if (corrRoll === null) {
      patch.levelLine = 'LEVEL: n/a - no sensor reading · PITCH ---';
      patch.levelCls = 'level';
    } else if (this._isLevel(corrRoll)) {
      patch.levelLine = this._bubble(corrRoll) + ' ' + this._horizon(corrRoll) +
        ' · PITCH ' + this._fmtDeg(corrPitch);
      patch.levelCls = 'level level-on';
    } else {
      patch.levelLine = this._bubble(corrRoll) + ' ' + this._horizon(corrRoll) +
        ' ' + this._fmtDeg(corrRoll) + ' · PITCH ' + this._fmtDeg(corrPitch);
      patch.levelCls = 'level';
    }
    var gp = this._gridPatch();
    for (var k in gp) patch[k] = gp[k];
    patch.shotHead = 'SHOTS (session only, NEVER saved): ' + this._shots.length + '/6' +
      (this._shots.length > 4 ? ' · latest 4 shown' : '');
    patch.shotRows = this._shots.slice(0, 4).map(function (s, i) {
      return {
        text: '#' + (i + 1) + ' ' + s.time + ' · roll ' + this._fmtDeg(s.roll) +
          ' · ' + s.verdict + ' · ' + s.bytes + 'B' + (s.demo ? ' DEMO' : '')
      };
    }, this);
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">PHOTO LEVEL</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{rawLine}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="finder">
      <view class="grow">
        <view class="{{g0}}"></view>
        <view class="{{g1}}"></view>
        <view class="{{g2}}"></view>
      </view>
      <view class="grow">
        <view class="{{g3}}"></view>
        <view class="{{g4}}">
          <view class="cross-wrap">
            <view class="cross-row">
              <text class="{{crossCls}}">+</text>
              <text class="{{crossCls}}">+</text>
            </view>
            <view class="cross-row">
              <text class="{{crossCls}}">+</text>
              <text class="{{crossCls}}">+</text>
            </view>
          </view>
        </view>
        <view class="{{g5}}"></view>
      </view>
      <view class="grow">
        <view class="{{g6}}"></view>
        <view class="{{g7}}"></view>
        <view class="{{g8}}"></view>
      </view>
      <view class="level-strip">
        <text class="roll">{{rollText}}</text>
        <text class="{{levelCls}}">{{levelLine}}</text>
      </view>
    </view>
    <text class="tip">{{tipLine}}</text>
    <text class="gridline">{{gridLine}}</text>
    <text class="shothead">{{shotHead}}</text>
    <view class="shots">
      <view ink:for="{{shotRows}}" class="srow">
        <text class="stext">{{item.text}}</text>
      </view>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn" bindtap="calibTap">CALIB</button>
      <button class="btn" bindtap="gridTap">GRID</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot-note">GRID FLOATS OVER YOUR REAL VIEW - NO CAMERA FEED · PHOTOS NEVER SAVED</text>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 4px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 3px;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: 500;
  line-height: 23px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
}
.finder {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 6px 4px;
  margin-bottom: 3px;
}
.grow {
  display: flex;
  flex-direction: row;
  height: 27px;
}
.cell {
  flex-grow: 1;
}
.cr {
  border-right: 1px solid rgba(64,255,94,0.48);
}
.cb {
  border-bottom: 1px solid rgba(64,255,94,0.48);
}
.cross-wrap {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
  padding: 0 2px;
}
.cross-row {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
}
.cross {
  color: #40ff5e;
  font-size: 10px;
  line-height: 10px;
}
.cross-off {
  color: rgba(64,255,94,0);
}
.level-strip {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 3px;
}
.roll {
  color: #40ff5e;
  font-size: 20px;
  font-weight: 500;
  line-height: 23px;
  text-align: center;
}
.level {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  font-weight: 500;
  line-height: 15px;
  text-align: center;
}
.level-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.tip {
  color: rgba(64,255,94,0.72);
  font-size: 10px;
  line-height: 13px;
}
.gridline {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
}
.shothead {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
.shots {
  display: flex;
  flex-direction: column;
}
.srow {
  display: flex;
  flex-direction: row;
  padding: 1px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.stext {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 3px;
  margin-top: 3px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 3px;
  font-size: 11px;
  font-weight: 500;
  line-height: 15px;
  text-align: center;
}
.btn-main {
  color: #40ff5e;
  border-color: rgba(64,255,94,0.72);
  background-color: rgba(64,255,94,0.12);
}
.foot-note {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 9px;
  line-height: 12px;
  margin-top: 1px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
