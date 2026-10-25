<script def>
{
  "navigationBarTitleText": "Posture Guard"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'NOT CALIBRATED - look straight, tap CAL',
    pitchLine: 'PITCH: --- · SRC: NONE',
    calLine: 'NEUTRAL — · LIMIT 20 MIN',
    droopLine: 'DROOP — · NO CAL',
    rows: [
      { text: 'STRETCH 00:00 / 20:00' },
      { text: 'DOWN TOTAL (session) 00:00' },
      { text: 'LONGEST 00:00' },
      { text: 'REMINDERS 0 · STATE NO CAL' }
    ],
    focusName: 'CALIBRATE FIRST',
    focusLine: 'look straight ahead comfortably, tap CAL',
    arrow: '◎',
    guideLine: 'DROOP is measured from YOUR neutral',
    guideCls: 'rel',
    lastEvent: 'EVT: I measure head pitch only - not your spine',
    busy: false
  },

  onLoad() {
    this._neutral = null;        // calibrated neutral pitch reading (deg)
    this._limitMin = 20;         // reminder limit: 5 / 10 / 20 minutes
    this._loadSettings();
    this._pitch = null;          // latest raw pitch reading (deg)
    this._pitchSrc = 'NONE';
    this._sensor = null;
    this._timer = null;
    this._lastTickMs = 0;
    // stretch state machine (all ms, session scope)
    this._stretchMs = 0;         // accumulated DOWN time in this stretch
    this._liftMs = 0;            // current continuous lift duration
    this._downTotalMs = 0;       // session DOWN total
    this._longestMs = 0;         // longest stretch this session
    this._reminders = 0;         // reminders spoken this session
    this._reminded = false;      // reminder already fired for this stretch
    this._demo = false;
    this._demoDroop = 34;        // simulated droop while in DEMO
    this._demoSaved = null;      // real settings snapshot while in DEMO
    this._lastSpeak = null;
    this._startPitch();
    this._startTimer();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startPitch();
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopPitch();
  },

  onUnload() {
    this._stopTimer();
    this._stopPitch();
    this._saveSettings();
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g === 'nod') this.speakTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.limitTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._neutral === null) this.calTap(); else this.speakTap();
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

  // ---------- pitch from the orientation quaternion ----------
  //
  // Nodding is rotation about the glasses' lateral axis (temple to
  // temple = the device X axis). In the ZYX Euler decomposition of
  // the orientation quaternion q = [x, y, z, w] that rotation is
  //   pitchDeg = atan2(2(wx + yz), 1 - 2(x^2 + y^2))
  // (the same component family the siblings use for yaw). Verified
  // with synthetic quaternions in Node: a level worn pose reads
  // about +90 deg, nodding down 30 deg reads about +60, looking up
  // 20 deg reads about +110, and the value does not change with
  // yaw. The absolute number means nothing on its own - DROOP is
  // always (calibrated neutral) - (current reading), positive when
  // the head is below YOUR neutral.
  _pitchDeg(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var n = Math.sqrt(x * x + y * y + z * z + w * w);
    if (!isFinite(n) || n < 1e-6) return null;
    x /= n; y /= n; z /= n; w /= n;
    var deg = Math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y)) * 180 / Math.PI;
    return deg;
  },

  _startPitch() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._pitchSrc = 'NONE';
      this._recompute();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onPitch(s); });
      s.addEventListener('error', function (ev) {
        self._pitchSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - pitch NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._pitchSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopPitch() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  _onPitch(sensor) {
    if (this._demo) return; // demo pitch wins while simulating
    var deg = this._pitchDeg(sensor.quaternion);
    if (deg === null) return;
    this._pitch = deg;
    this._pitchSrc = 'SENSOR';
  },

  // 250ms tick: poll the sensor (preview hosts may not fire
  // 'reading'), advance the stretch state machine, refresh.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onPitch(self._sensor);
      }
      self._tick(Date.now());
      self._recompute();
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- persistence (wx sync storage, key 'postureGuard') ----------

  _loadSettings() {
    try {
      var raw = wx.getStorageSync('postureGuard');
      if (!raw || typeof raw !== 'object') return;
      if (isFinite(raw.neutralPitch)) {
        this._neutral = Math.max(-180, Math.min(180, Number(raw.neutralPitch)));
      }
      if (raw.limitMin === 5 || raw.limitMin === 10 || raw.limitMin === 20) {
        this._limitMin = raw.limitMin;
      }
    } catch (e) { /* storage unavailable on this host: defaults stay */ }
  },

  _saveSettings() {
    // DEMO settings are a simulation: never overwrite real ones.
    if (this._demo) return;
    try {
      wx.setStorageSync('postureGuard', {
        neutralPitch: this._neutral,
        limitMin: this._limitMin
      });
    } catch (e) { /* storage unavailable on this host: settings stay in memory */ }
  },

  // ---------- the stretch state machine ----------
  //
  // DOWN: droop > 25 deg. While DOWN, the stretch clock runs.
  // A lift (droop <= 25) shorter than 10 s only PAUSES the clock -
  // glancing up at the door does not earn you a fresh neck. A lift
  // of 10 s or more RESETS the stretch to zero and re-arms the
  // reminder. The reminder fires exactly ONCE per stretch, when
  // the accumulated DOWN time reaches the limit. A missing pitch
  // reading (sensor gone) pauses everything: no growth, no reset.

  _droopNow() {
    if (this._demo) return this._demoDroop;
    if (this._neutral === null || this._pitch === null) return null;
    return this._neutral - this._pitch;
  },

  _tick(nowMs) {
    var dt = this._lastTickMs > 0 ? nowMs - this._lastTickMs : 0;
    this._lastTickMs = nowMs;
    if (dt < 0) dt = 0;
    if (dt > 5000) dt = 5000; // a stalled page must not bank hours
    if (this._demo) dt = dt * 60; // DEMO clock runs 60x fast (stated)
    var droop = this._droopNow();
    if (droop === null) return; // no reading: pause, never reset
    if (droop > 25) {
      this._liftMs = 0;
      this._stretchMs += dt;
      this._downTotalMs += dt;
      if (this._stretchMs > this._longestMs) this._longestMs = this._stretchMs;
      if (!this._reminded && this._stretchMs >= this._limitMin * 60000) {
        this._reminded = true;
        this._reminders++;
        this.setData({
          status: 'REMINDER SENT — 抬头休息一下',
          lastEvent: 'EVT: stretch hit ' + this._limitMin + ' min - reminder spoken once'
        });
        this._speakText(this._reminderText());
      }
    } else {
      this._liftMs += dt;
      if (this._liftMs >= 10000) {
        this._stretchMs = 0;
        this._reminded = false;
        this._liftMs = 0;
      }
    }
  },

  _reminderText() {
    var zh = { 5: '五分钟', 10: '十分钟', 20: '二十分钟' };
    return '你已经低头' + (zh[this._limitMin] || '二十分钟') +
      '了，抬头看看远处，活动一下脖子。';
  },

  _stateWord() {
    if (this._neutral === null && !this._demo) return 'NO CAL';
    var droop = this._droopNow();
    if (droop === null) return 'NO PITCH';
    if (droop > 25) return this._reminded ? 'REMINDED' : 'DOWN';
    return this._stretchMs > 0 ? 'PAUSED' : 'UP';
  },

  // ---------- actions ----------

  calTap() {
    if (!this._demo && this._pitch === null) {
      // Same honesty rule as the siblings: never invent a reading.
      this.setData({
        status: 'CAL FAIL: no pitch reading - sensor n/a',
        lastEvent: 'EVT: CAL refused - never invent a neutral'
      });
      return;
    }
    var reading = this._demo ? (90 - this._demoDroop) : this._pitch;
    this._neutral = reading;
    // A fresh neutral invalidates the running stretch.
    this._stretchMs = 0;
    this._liftMs = 0;
    this._reminded = false;
    this._saveSettings();
    this.setData({
      status: 'CALIBRATED - neutral ' + Math.round(reading) + ' deg',
      lastEvent: 'EVT: neutral set to ' + Math.round(reading) + ' deg' +
        (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._recompute();
  },

  limitTap() {
    this._limitMin = this._limitMin === 20 ? 5 : (this._limitMin === 5 ? 10 : 20);
    this._saveSettings();
    this.setData({
      status: 'LIMIT: ' + this._limitMin + ' min continuous droop',
      lastEvent: 'EVT: reminder limit -> ' + this._limitMin + ' min' +
        (this._demo ? ' (DEMO session)' : '')
    });
    this._recompute();
  },

  resetTap() {
    this._stretchMs = 0;
    this._liftMs = 0;
    this._downTotalMs = 0;
    this._longestMs = 0;
    this._reminders = 0;
    this._reminded = false;
    this.setData({
      status: this._neutral === null && !this._demo
        ? 'NOT CALIBRATED - look straight, tap CAL'
        : 'MONITORING - droop >25 deg counts as DOWN',
      lastEvent: 'EVT: new session - stats cleared, calibration kept'
    });
    this._recompute();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO: restore the real settings snapshot.
      this._demo = false;
      if (this._demoSaved) {
        this._neutral = this._demoSaved.neutralPitch;
        this._limitMin = this._demoSaved.limitMin;
      }
      this._demoSaved = null;
      this._pitch = null;
      this._pitchSrc = 'NONE';
      this._stretchMs = 0;
      this._liftMs = 0;
      this._downTotalMs = 0;
      this._longestMs = 0;
      this._reminders = 0;
      this._reminded = false;
      this._startPitch();
      this.setData({
        status: this._neutral === null
          ? 'NOT CALIBRATED - look straight, tap CAL'
          : 'MONITORING - droop >25 deg counts as DOWN',
        lastEvent: 'EVT: DEMO off - your saved calibration restored'
      });
      this._recompute();
      return;
    }
    this._neutral = null;
    this._limitMin = 20;
    this._stretchMs = 0;
    this._liftMs = 0;
    this._downTotalMs = 0;
    this._longestMs = 0;
    this._reminders = 0;
    this._reminded = false;
    this._saveSettings();
    this.setData({
      status: 'NOT CALIBRATED - look straight, tap CAL',
      lastEvent: 'EVT: calibration cleared - CAL again to restart'
    });
    this._recompute();
  },

  // ---------- DEMO ----------
  //
  // DEMO simulates a wearer mid-session, memory only: neutral 90 deg
  // (the level worn pose), head currently drooped 34 deg, and the
  // running stretch pre-accumulated to 18:24 of the 20:00 limit.
  // Seeded session stats as pure constants (no Date anywhere):
  // longest 24:12 + current stretch 18:24 = total 42:36, and one
  // reminder already fired in that earlier stretch. The demo clock
  // runs 60x fast, so the stretch reaches the limit - and the
  // reminder fires - seconds after entry. Tapping DEMO again
  // toggles the simulated head DOWN (34 deg) / UP (-6 deg).

  demoTap() {
    if (!this._demo) {
      this._demoSaved = { neutralPitch: this._neutral, limitMin: this._limitMin };
      this._demo = true;
      this._neutral = 90;
      this._limitMin = 20;
      this._demoDroop = 34;
      this._pitch = 90 - 34;
      this._pitchSrc = 'DEMO';
      this._stretchMs = (18 * 60 + 24) * 1000;
      this._longestMs = (24 * 60 + 12) * 1000;
      this._downTotalMs = (42 * 60 + 36) * 1000;
      this._reminders = 1;
      this._reminded = false;
      this._liftMs = 0;
      this._lastTickMs = 0;
      this.setData({
        status: 'DEMO - simulated pitch, clock runs 60x fast',
        lastEvent: 'EVT: DEMO on - memory only, stretch seeded 18:24/20:00'
      });
    } else {
      this._demoDroop = this._demoDroop > 25 ? -6 : 34;
      this._pitch = 90 - this._demoDroop;
      this.setData({
        status: 'DEMO - simulated head ' + (this._demoDroop > 25 ? 'DOWN 34 deg' : 'UP -6 deg'),
        lastEvent: 'EVT: DEMO droop -> ' + this._demoDroop + ' deg (clock 60x)'
      });
    }
    this._recompute();
  },

  // ---------- formatting ----------

  _fmtDur(ms) {
    function p(n) { return (n < 10 ? '0' : '') + n; }
    var s = Math.floor(ms / 1000);
    var h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    var ss = s % 60;
    if (h > 0) return h + ':' + p(m) + ':' + p(ss);
    return p(m) + ':' + p(ss);
  },

  _durZh(ms) {
    var s = Math.round(ms / 1000);
    if (s < 60) return s + '秒';
    var m = Math.floor(s / 60);
    var rest = s % 60;
    return m + '分钟' + (rest > 0 ? rest + '秒' : '');
  },

  // ---------- recompute view ----------

  _recompute() {
    var droop = this._droopNow();
    var word = this._stateWord();
    var pitchTxt = this._demo
      ? String(Math.round(90 - this._demoDroop))
      : (this._pitch === null ? '---' : String(Math.round(this._pitch)));
    var limitMs = this._limitMin * 60000;
    var patch = {
      pitchLine: 'PITCH: ' + pitchTxt + ' · SRC: ' + this._pitchSrc +
        (this._demo ? ' (DEMO 60x)' : ''),
      calLine: 'NEUTRAL ' + (this._neutral === null ? '—' : Math.round(this._neutral) + '°') +
        ' · LIMIT ' + this._limitMin + ' MIN',
      droopLine: 'DROOP ' + (droop === null ? '—' : Math.round(droop) + '°') + ' — ' + word,
      rows: [
        { text: 'STRETCH ' + this._fmtDur(this._stretchMs) + ' / ' + this._fmtDur(limitMs) },
        { text: 'DOWN TOTAL (session) ' + this._fmtDur(this._downTotalMs) },
        { text: 'LONGEST ' + this._fmtDur(this._longestMs) },
        { text: 'REMINDERS ' + this._reminders + ' · STATE ' + word }
      ]
    };
    if (word === 'NO CAL') {
      patch.focusName = 'CALIBRATE FIRST';
      patch.focusLine = 'look straight ahead comfortably, tap CAL';
      patch.arrow = '◎';
      patch.guideLine = 'DROOP is measured from YOUR neutral';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: '还没有校准。看正前方，点 CAL，我再开始计时。' };
    } else if (word === 'NO PITCH') {
      patch.focusName = 'NO PITCH READING';
      patch.focusLine = 'sensor paused - stretch clock is held, not reset';
      patch.arrow = '◎';
      patch.guideLine = 'WAITING FOR SENSOR — nothing counts, nothing resets';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: '现在没有姿势读数，计时暂停中。' };
    } else if (word === 'DOWN') {
      patch.focusName = 'HEAD DOWN — TIMER RUNNING';
      patch.focusLine = 'droop ' + Math.round(droop) + '° > 25° — a book on the desk counts too';
      patch.arrow = '↓';
      patch.guideLine = 'STRETCH ' + this._fmtDur(this._stretchMs) + ' OF ' +
        this._fmtDur(limitMs) + ' — reminder at the limit';
      patch.guideCls = 'rel';
      this._lastSpeak = {
        text: '你正低着头，这一段已经持续' + this._durZh(this._stretchMs) + '。'
      };
    } else if (word === 'REMINDED') {
      patch.focusName = '抬头休息一下 — TAKE A BREAK';
      patch.focusLine = 'look far away, roll your neck slowly';
      patch.arrow = '!';
      patch.guideLine = 'REMINDED — 1 per stretch; lift 10s+ to re-arm';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._reminderText() };
    } else if (word === 'PAUSED') {
      patch.focusName = 'PAUSED — LIFT ' + (this._liftMs / 1000).toFixed(1) + 's / 10s';
      patch.focusLine = 'brief lift only pauses - look down to resume';
      patch.arrow = '◎';
      patch.guideLine = 'STRETCH HELD AT ' + this._fmtDur(this._stretchMs) + ' — 10s up resets it';
      patch.guideCls = 'rel';
      this._lastSpeak = {
        text: '计时暂停。这一段低头已经累计' + this._durZh(this._stretchMs) +
          '，抬头满十秒才会清零。'
      };
    } else { // UP
      patch.focusName = 'HEAD UP — GOOD';
      patch.focusLine = 'droop within 25° of neutral — nothing counting';
      patch.arrow = '↑';
      patch.guideLine = 'STRETCH 00:00 — the clock starts at droop >25°';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = {
        text: '现在头是抬着的。本次累计低头' + this._durZh(this._downTotalMs) + '。'
      };
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
    var text;
    if (this._neutral === null && !this._demo) {
      text = '还没有校准。看正前方，点 CAL，我再开始计时。';
    } else {
      text = '本次监测：累计低头' + this._durZh(this._downTotalMs) +
        '，最长连续低头' + this._durZh(this._longestMs) +
        '，已经提醒' + this._reminders + '次。' +
        (this._stretchMs > 0
          ? '当前这一段已经持续' + this._durZh(this._stretchMs) + '。'
          : '现在没有进行中的低头段。');
    }
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">POSTURE GUARD</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{pitchLine}}</text>
    </view>
    <view class="mark-box">
      <text class="mark-mode">{{calLine}}</text>
      <text class="count">{{droopLine}}</text>
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
      <button class="btn btn-main" bindtap="calTap">CAL</button>
      <button class="btn" bindtap="limitTap">LIMIT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="resetTap">RESET</button>
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
.count {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.stats {
  display: flex;
  flex-direction: column;
  margin-bottom: 3px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
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
  padding: 2px 10px 4px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
