<script def>
{
  "navigationBarTitleText": "Clean Check"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'SWEEP: turn slowly, dwell 2s on each zone',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: SWEEP · ZONE: 窗边',
    progLine: 'COVERED: 0/6 · reg zones: 0/6',
    rows: [
      { text: '○ 窗边 · no heading' }
    ],
    focusName: 'NEXT MISSED: —',
    focusLine: 'no zones registered — SETUP to bind, or DEMO',
    arrow: '·',
    guideLine: 'NO HEADING — SETUP first or tap DEMO',
    guideCls: 'rel',
    lastEvent: 'EVT: covered = gaze dwelled 2s there - NOT proof it is clean',
    busy: false
  },

  onLoad() {
    this._mode = 'SWEEP';
    this._defs = this._zoneDefs();
    this._zones = this._loadZones();
    this._cov = this._freshCov();
    this._sel = 0;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 90;
    this._sensor = null;
    this._timer = null;
    this._steady = false;
    this._dwellZone = -1;
    this._dwellStart = 0;
    this._dwellMs = 0;
    this._dwellFrozen = false;
    this._doneSpoken = false;
    this._lastSpeak = null;
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
    this._saveZones();
  },

  onOrientationStabilityChange(event) {
    if (this._demo) return; // demo simulates a held-still head
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
    if (!this._steady) this._resetDwell();
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    if (this._mode === 'SETUP') { this.regTap(); return; }
    // SWEEP: a nod marks the selected zone BY TAP - honestly recorded
    // as 'tap', never as gaze coverage. The 2s dwell stays the only
    // way to earn a 'gaze' tick.
    this.markTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.zoneTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'SETUP') this.regTap(); else this.markTap();
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

  // ---------- the six zones people forget ----------

  _zoneDefs() {
    return [
      { name: '窗边', cue: '窗台、窗框、玻璃下沿最容易积灰' },
      { name: '门口', cue: '门后、门把、踢脚线都看一遍' },
      { name: '床边', cue: '探头看床底边缘，别漏床下灰' },
      { name: '柜顶', cue: '柜顶积灰最厚，踮脚看清楚' },
      { name: '墙角', cue: '墙角和踢脚线交界，蜘蛛网在这' },
      { name: '桌下', cue: '桌下线缆缠着灰，蹲下看一眼' }
    ];
  },

  _freshCov() {
    var out = [];
    for (var i = 0; i !== 6; i++) out.push({ covered: false, how: '', time: '' });
    return out;
  },

  _coveredCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._cov[i].covered) n++;
    return n;
  },

  // ---------- persistence (wx sync storage, key 'cleanCheckZones') ----------

  _loadZones() {
    var out = [];
    var i;
    for (i = 0; i !== 6; i++) out.push({ name: this._defs[i].name, headingDeg: null, demo: false });
    try {
      var raw = wx.getStorageSync('cleanCheckZones');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return out;
      for (i = 0; i !== raw.length; i++) {
        var r = raw[i];
        if (!r || typeof r.name !== 'string') continue;
        for (var j = 0; j !== 6; j++) {
          if (this._defs[j].name === r.name) {
            if (isFinite(r.headingDeg)) {
              out[j].headingDeg = ((Math.round(r.headingDeg) % 360) + 360) % 360;
              out[j].demo = !!r.demo;
            }
            break;
          }
        }
      }
      return out;
    } catch (e) {
      return out;
    }
  },

  _saveZones() {
    // DEMO headings are a simulation: never overwrite real registrations.
    if (this._demo) return;
    try {
      var out = [];
      for (var i = 0; i !== 6; i++) {
        out.push({
          name: this._zones[i].name,
          headingDeg: this._zones[i].headingDeg,
          demo: !!this._zones[i].demo
        });
      }
      wx.setStorageSync('cleanCheckZones', out);
    } catch (e) { /* storage unavailable on this host: zones stay in memory */ }
  },

  _regCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._zones[i].headingDeg !== null) n++;
    return n;
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

  // 250ms tick: poll the sensor (preview hosts may not fire 'reading'),
  // advance the dwell state machine, refresh the dwell display.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._dwellTick(Date.now());
      self._recompute();
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- relative-angle math (same convention as siblings) ----------

  _rel(headingDeg, current) {
    return ((headingDeg - current + 540) % 360) - 180; // -180..180, + = right
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  // The zone your gaze is on right now: uncovered, has a heading, and
  // within the +-25 deg cone of the current heading. Nearest wins.
  // -1 when there is no such zone (or no live heading at all).
  _coneZone() {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 26;
    for (var i = 0; i !== 6; i++) {
      if (this._cov[i].covered) continue;
      var h = this._zones[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a <= 25 && a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  // Angularly nearest uncovered zone that has a heading (guidance
  // target). exclude >= 0 skips one zone (the one being dwelled on).
  _nearestMissed(exclude) {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 999;
    for (var i = 0; i !== 6; i++) {
      if (i === exclude || this._cov[i].covered) continue;
      var h = this._zones[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  _firstMissed() {
    for (var i = 0; i !== 6; i++) if (!this._cov[i].covered) return i;
    return -1;
  },

  // ---------- dwell state machine ----------

  _resetDwell() {
    this._dwellZone = -1;
    this._dwellStart = 0;
    this._dwellMs = 0;
  },

  // One dwell step at time nowMs. Coverage rule: gaze inside a zone's
  // +-25 deg cone AND head steady, continuously for 2000ms. Leaving
  // the cone, switching zones, or moving the head resets the timer -
  // a fast sweep across the room can never fake coverage.
  _dwellTick(nowMs) {
    if (this._dwellFrozen) return; // DEMO holds a primed dwell for display
    if (this._mode !== 'SWEEP' || this._coveredCount() >= 6) {
      if (this._dwellZone >= 0) this._resetDwell();
      return;
    }
    var cand = this._steady ? this._coneZone() : -1;
    if (cand < 0) {
      if (this._dwellZone >= 0) this._resetDwell();
      return;
    }
    if (cand !== this._dwellZone) {
      this._dwellZone = cand;
      this._dwellStart = nowMs;
      this._dwellMs = 0;
      return;
    }
    this._dwellMs = nowMs - this._dwellStart;
    if (this._dwellMs >= 2000) {
      var i = cand;
      this._cov[i] = { covered: true, how: 'gaze', time: this._hhmm(new Date(nowMs)) };
      this._resetDwell();
      this._sel = this._nearestMissed(-1);
      if (this._sel < 0) this._sel = this._firstMissed();
      var n = this._coveredCount();
      if (n >= 6) {
        this.setData({
          status: 'SWEEP DONE — 每个角落都看过了',
          lastEvent: 'EVT: all 6 zones covered - spoken wrap-up sent'
        });
        this._finishSpeak();
      } else {
        this.setData({
          status: 'COVERED ' + n + '/6: ' + this._defs[i].name + ' ✓ (gaze)',
          lastEvent: 'EVT: ' + this._defs[i].name + ' covered by 2s gaze dwell'
        });
      }
      this._recompute();
    }
  },

  _finishSpeak() {
    if (this._doneSpoken) return;
    this._doneSpoken = true;
    this._speakText('打扫复查完成。六个角落都逐个看过了。注意，我记录的是你看过，不保证已经擦干净。');
  },

  // ---------- modes / selection ----------

  modeTap() {
    this._mode = this._mode === 'SWEEP' ? 'SETUP' : 'SWEEP';
    if (this._mode === 'SETUP') {
      if (this._sel < 0) this._sel = 0;
      this._resetDwell();
    } else {
      var nm = this._nearestMissed(-1);
      this._sel = nm >= 0 ? nm : this._firstMissed();
    }
    this.setData({
      status: this._mode === 'SWEEP'
        ? 'SWEEP: turn slowly, dwell 2s on each zone'
        : 'SETUP: look at the zone, tap REG to bind its heading',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  zoneTap() {
    if (this._mode === 'SETUP') {
      this._sel = ((this._sel < 0 ? 0 : this._sel) + 1) % 6;
    } else {
      // SWEEP: cycle among the zones still missed.
      var missed = [];
      for (var i = 0; i !== 6; i++) if (!this._cov[i].covered) missed.push(i);
      if (!missed.length) {
        this.setData({ lastEvent: 'EVT: nothing missed - sweep done' });
        return;
      }
      var pos = missed.indexOf(this._sel);
      this._sel = missed[(pos + 1) % missed.length];
    }
    this.setData({ lastEvent: 'EVT: zone -> ' + this._defs[this._sel < 0 ? 0 : this._sel].name });
    this._recompute();
  },

  // ---------- SETUP: register a heading ----------

  regTap() {
    if (this._mode !== 'SETUP') {
      this.setData({ lastEvent: 'EVT: REG is SETUP only - tap MODE first' });
      return;
    }
    if (this._sel < 0) this._sel = 0;
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'REG FAIL: no heading - DEMO or wait for sensor',
        lastEvent: 'EVT: REG refused - never invent a heading'
      });
      return;
    }
    var h = Math.round(this._heading);
    // Re-registering a zone replaces its old heading.
    this._zones[this._sel].headingDeg = h;
    this._zones[this._sel].demo = !!this._demo;
    this._saveZones();
    this.setData({
      status: 'REGISTERED: ' + this._defs[this._sel].name + ' · ' + h + '°',
      lastEvent: 'EVT: heading bound ' + this._defs[this._sel].name + ' at ' + h +
        ' deg' + (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._recompute();
  },

  // ---------- SWEEP: mark by tap (honestly recorded as 'tap') ----------

  markTap() {
    if (this._mode !== 'SWEEP') {
      this.setData({ lastEvent: 'EVT: MARK is SWEEP only - tap MODE first' });
      return;
    }
    if (this._coveredCount() >= 6) {
      this.setData({ lastEvent: 'EVT: sweep already complete - RESET for a new one' });
      return;
    }
    // Prefer the zone you are facing right now; else the selected one.
    var i = this._coneZone();
    if (i < 0) i = this._sel;
    if (i < 0 || this._cov[i].covered) i = this._firstMissed();
    if (i < 0) return;
    this._cov[i] = { covered: true, how: 'tap', time: this._hhmm(new Date()) };
    if (this._dwellZone === i) this._resetDwell();
    var n = this._coveredCount();
    var name = this._defs[i].name;
    this._sel = this._nearestMissed(-1);
    if (this._sel < 0) this._sel = this._firstMissed();
    if (n >= 6) {
      this.setData({
        status: 'SWEEP DONE — 每个角落都看过了',
        lastEvent: 'EVT: all 6 zones covered - spoken wrap-up sent'
      });
      this._recompute();
      this._finishSpeak();
      return;
    }
    this.setData({
      status: 'COVERED ' + n + '/6: ' + name + ' ✓ (tap)',
      lastEvent: 'EVT: ' + name + ' marked by tap - recorded as tap, not gaze'
    });
    this._recompute();
  },

  resetTap() {
    this._cov = this._freshCov();
    this._resetDwell();
    this._doneSpoken = false;
    this._sel = this._nearestMissed(-1);
    if (this._sel < 0) this._sel = this._firstMissed();
    if (this._sel < 0) this._sel = 0;
    this.setData({
      status: this._mode === 'SWEEP'
        ? 'SWEEP: turn slowly, dwell 2s on each zone'
        : 'SETUP: look at the zone, tap REG to bind its heading',
      lastEvent: 'EVT: new sweep - coverage cleared, zones kept'
    });
    this._recompute();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO: drop the simulated zones, restore real ones.
      this._demo = false;
      this._dwellFrozen = false;
      this._zones = this._loadZones();
      this._cov = this._freshCov();
      this._resetDwell();
      this._doneSpoken = false;
      this._sel = 0;
      this._heading = null;
      this._headingSrc = 'NONE';
      this._steady = false;
      this.setData({ steadyText: 'HEAD: moving - hold still' });
      this._startHeading();
      this.setData({
        status: 'SWEEP: turn slowly, dwell 2s on each zone',
        lastEvent: 'EVT: DEMO off - your saved zones restored'
      });
      this._recompute();
      return;
    }
    for (var i = 0; i !== 6; i++) {
      this._zones[i].headingDeg = null;
      this._zones[i].demo = false;
    }
    this._saveZones();
    this._cov = this._freshCov();
    this._resetDwell();
    this._doneSpoken = false;
    this._sel = 0;
    this.setData({
      status: 'SWEEP: turn slowly, dwell 2s on each zone',
      lastEvent: 'EVT: all registered zone headings cleared'
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO binds simulated headings 30/90/150/210/270/330 (memory only,
  // real registrations are never overwritten). The sweep notionally
  // started facing the window side (30 deg): it is already covered by
  // a full 2s gaze dwell, timed from ONE Date snapshot. The demo head
  // is now at 90 deg, held steady, dwelling on the doorway (90 deg)
  // with the dwell primed at 1.2s and held there for display - on the
  // real device the dwell runs in real time. Further taps step the
  // heading +45 and re-prime the dwell on the zone in the cone.
  demoTap() {
    if (!this._demo) {
      var snap = new Date(); // ONE snapshot: all demo times derive from it
      this._demo = true;
      this._demoHeading = 90;
      this._heading = 90;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY' });
      var hs = [30, 90, 150, 210, 270, 330];
      for (var i = 0; i !== 6; i++) {
        this._zones[i] = { name: this._defs[i].name, headingDeg: hs[i], demo: true };
      }
      this._cov = this._freshCov();
      this._cov[0] = { covered: true, how: 'gaze', time: this._hhmm(snap) };
      this._mode = 'SWEEP';
      this._doneSpoken = false;
      this._dwellZone = 1;
      this._dwellMs = 1200;
      this._dwellStart = snap.getTime() - 1200;
      this._dwellFrozen = true;
      this._sel = 1;
      this.setData({
        status: 'DEMO SWEEP 1/6 - dwelling 门口 1.2s (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO on - zones in memory only, 窗边 covered by gaze'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      // Re-prime the held dwell on whatever zone is in the cone now.
      var cz = this._coneZone();
      if (cz >= 0) {
        this._dwellZone = cz;
        this._dwellMs = 1200;
        this._dwellStart = Date.now() - 1200;
      } else {
        this._resetDwell();
      }
      this.setData({
        status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
      });
    }
    this._recompute();
  },

  // ---------- recompute view ----------

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var done = this._coveredCount();
    var selName = this._sel >= 0 ? this._defs[this._sel].name : '(none)';
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · ZONE: ' + selName,
      progLine: 'COVERED: ' + done + '/6 · reg zones: ' + this._regCount() + '/6'
    };
    var self = this;
    patch.rows = this._defs.map(function (d, i) {
      var c = self._cov[i];
      var z = self._zones[i];
      var regTxt = z.headingDeg === null ? 'no heading' : 'reg ' + z.headingDeg + '°';
      var mark;
      if (c.covered) mark = '✓ ' + c.how + ' ' + c.time;
      else if (self._dwellZone === i) mark = '◎ dwell ' + (self._dwellMs / 1000).toFixed(1) + 's';
      else mark = '○';
      var cur = (!c.covered && i === self._sel && self._mode === 'SETUP') ? '▸ ' : '';
      return { text: cur + d.name + ' · ' + mark + ' · ' + regTxt };
    });

    if (this._mode === 'SETUP') {
      var si = this._sel < 0 ? 0 : this._sel;
      var sz = this._zones[si];
      patch.focusName = 'SETUP: ' + this._defs[si].name;
      patch.focusLine = this._defs[si].cue;
      patch.arrow = '◎';
      patch.guideLine = sz.headingDeg === null
        ? 'UNREGISTERED — look at it, tap REG'
        : 'REGISTERED ' + sz.headingDeg + '° — REG again to re-bind';
      patch.guideCls = 'rel';
      this._lastSpeak = {
        text: '设置模式。当前区域是' + this._defs[si].name + '。' +
          (sz.headingDeg === null ? '还没有登记朝向。' : '已登记在' + sz.headingDeg + '度。')
      };
      this.setData(patch);
      return;
    }

    // SWEEP
    if (done >= 6) {
      patch.focusName = 'SWEEP DONE — 都看过了';
      patch.focusLine = '6/6 已覆盖 — 看过≠擦净，靠你的手';
      patch.arrow = '✓';
      patch.guideLine = 'SWEEP DONE — 每个角落都看过了';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: '打扫复查完成。六个角落都逐个看过了。' };
      this.setData(patch);
      return;
    }
    var missedNames = [];
    for (var k = 0; k !== 6; k++) if (!this._cov[k].covered) missedNames.push(this._defs[k].name);
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    var dwell = this._dwellZone;
    if (dwell >= 0) {
      patch.focusName = 'DWELL: ' + this._defs[dwell].name;
      patch.focusLine = 'dwell ' + (this._dwellMs / 1000).toFixed(1) + 's / 2s — hold still, wipe as you look';
      // Guidance points past the dwell zone, at the next missed one.
      var nx = this._nearestMissed(dwell);
      if (nx >= 0 && this._heading !== null) {
        var relN = this._rel(this._zones[nx].headingDeg, this._heading);
        var relN360 = (this._zones[nx].headingDeg - this._heading + 360) % 360;
        patch.arrow = arrows[Math.round(relN360 / 45) % 8];
        patch.guideLine = 'NEXT: ' + this._defs[nx].name + ' — TURN: ' + this._dirName(relN).en +
          ' ' + Math.round(Math.abs(relN)) + '°';
        patch.guideCls = 'rel';
      } else {
        patch.arrow = '◎';
        patch.guideLine = 'MISSED ' + missedNames.length + ' — this is the last one';
        patch.guideCls = 'rel rel-on';
      }
      this._lastSpeak = {
        text: '还差' + missedNames.length + '个角落：' + missedNames.join('、') + '。'
      };
      this.setData(patch);
      return;
    }
    // Not dwelling: guide to the nearest missed zone.
    var tgt = this._nearestMissed(-1);
    if (tgt < 0) tgt = this._sel >= 0 && !this._cov[this._sel].covered ? this._sel : this._firstMissed();
    if (tgt < 0) tgt = 0;
    patch.focusName = 'NEXT MISSED: ' + this._defs[tgt].name;
    patch.focusLine = this._defs[tgt].cue;
    var tz = this._zones[tgt].headingDeg;
    if (tz === null) {
      patch.arrow = '·';
      patch.guideLine = 'NO HEADING — find it by eye, MARK when done';
      patch.guideCls = 'rel';
    } else if (this._heading === null) {
      patch.arrow = '·';
      patch.guideLine = 'HEADING N/A (SRC NONE) — find it by eye';
      patch.guideCls = 'rel';
    } else {
      var rel = this._rel(tz, this._heading);
      var rel360 = (tz - this._heading + 360) % 360;
      patch.arrow = arrows[Math.round(rel360 / 45) % 8];
      patch.guideLine = 'TURN: ' + this._dirName(rel).en + ' ' + Math.round(Math.abs(rel)) +
        '° — reg ' + tz + '°';
      patch.guideCls = 'rel';
    }
    this._lastSpeak = {
      text: '还差' + missedNames.length + '个角落：' + missedNames.join('、') + '。' +
        (tz !== null && this._heading !== null
          ? '最近的是' + this._defs[tgt].name + '，在你' + this._dirName(this._rel(tz, this._heading)).zh + '。'
          : '')
    };
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
    var text = s ? s.text : '还没有复查进度。';
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">CLEAN CHECK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="mark-box">
      <text class="mark-mode">{{modeLine}}</text>
      <text class="count">{{progLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="guide-box">
      <text class="curname">{{focusName}}</text>
      <text class="cue">{{focusLine}}</text>
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{guideCls}}">{{guideLine}}</text>
      </view>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="zoneTap">ZONE</button>
      <button class="btn" bindtap="regTap">REG</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="resetTap">RESET</button>
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
.count {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.list {
  height: 45px;
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
