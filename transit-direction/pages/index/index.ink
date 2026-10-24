<script def>
{
  "navigationBarTitleText": "Transit Direction"
}
</script>

<script setup>
export default {
  data: {
    status: 'TAP START FOR GPS, OR DEMO TO SIMULATE',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    fixLine: 'FIX: no fix yet (START / DEMO)',
    modeLine: 'MODE: ALIGN · WATCH: off',
    targetLine: 'COURSE: not locked - face your way, tap ALIGN',
    arrow: '·',
    relLine: 'GUIDE: ---',
    courseCls: 'rel',
    lastEvent: 'EVT: tap = fix / lock · swipe = presets · nod = speak',
    busy: false
  },

  onLoad() {
    this._fix = null;            // current position {lat, lon, acc} (watch-updated)
    this._origin = null;         // the exit fix: PRESET offsets anchor HERE
    this._fixTime = '';
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._mode = 'ALIGN';        // 'ALIGN' | 'PRESET'
    this._locked = null;         // {bearing, time} - ALIGN course
    this._destIdx = 0;
    this._demo = false;
    this._demoHeading = 0;
    this._demoOrigin = { lat: 35.6812, lon: 139.7671 };
    this._sensor = null;
    this._timer = null;
    this._watchId = null;
    this._watchState = 'off';    // 'live' | 'fail' | 'n/a' | 'off'
    this._driftTicks = 0;        // consecutive 500 ms ticks beyond 30 deg
    this._driftSpoken = false;   // correction spoken for this drift episode
    this._arrived = false;
    this._arrivedSpoken = false;
    this._lastSpeak = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
    this._startTimer();
    if (this._fix && !this._demo) this._startWatch();
  },

  onHide() {
    this._stopTimer();
    this._stopHeading();
    this._stopWatch();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopWatch();
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({ steadyText: 'HEAD STEADY' });
    } else {
      this.setData({ steadyText: 'HEAD: moving - hold still' });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // Nod only ever speaks the current guidance, and only while guiding
    // with a steady head. It never locks a course and never starts a fix.
    if (this._guiding() && this._steady) {
      this.setData({ lastEvent: 'EVT: nod = speak guidance' });
      this.speakTap();
    } else if (this._guiding()) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - not guiding yet' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier §3.2.1): single tap arrives as Enter,
  // double-tap as Backspace, swipe as ArrowUp/ArrowDown. Every main
  // flow is completable with these keys + head-steady + nod alone;
  // the four on-screen buttons mirror the same actions for tapping.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (Enter) = primary action' });
      this._primaryTap();
    } else if (code === 'ArrowUp') {
      this._swipe(1);
    } else if (code === 'ArrowDown') {
      this._swipe(-1);
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: double-tap (Backspace) back (host handles close)' });
    }
  },

  // The context primary action behind a single tap (Enter):
  // no fix yet -> START; ALIGN mode -> lock the facing as the course;
  // PRESET with a dead/absent watch -> manual UPDATE re-fix; otherwise
  // speak the current guidance (same as nod).
  async _primaryTap() {
    if (this._demo) { this.speakTap(); return; }
    if (!this._fix) { await this.startTap(); return; }
    if (this._mode === 'ALIGN') { this.alignTap(); return; }
    if (this._watchState !== 'live') { await this.updateTap(); return; }
    this.speakTap();
  },

  // Swipe (ArrowUp/Down): in ALIGN mode a swipe enters PRESET mode;
  // in PRESET mode it cycles the demo preset destinations.
  _swipe(dir) {
    if (this._mode !== 'PRESET') {
      this._mode = 'PRESET';
      var d0 = this._dest();
      this.setData({ lastEvent: 'EVT: swipe -> PRESET mode · dest ' + d0.name + ' ' + d0.en + ' (demo preset)' });
      this._resetEpisodes();
      this._recompute();
      return;
    }
    var n = this._dests().length;
    this._destIdx = (((this._destIdx || 0) + dir) % n + n) % n;
    var d = this._dest();
    this.setData({ lastEvent: 'EVT: swipe -> dest ' + d.name + ' ' + d.en + ' (demo preset)' });
    this._resetEpisodes();
    this._recompute();
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- helpers ----------

  _timeStr(d) {
    var hh = d.getHours(); if (hh < 10) hh = '0' + hh;
    var mm = d.getMinutes(); if (mm < 10) mm = '0' + mm;
    return hh + ':' + mm;
  },

  _err(e) {
    if (!e) return 'unknown error';
    if (e.code === 1) return 'PERMISSION_DENIED';
    if (e.code === 2) return 'POSITION_UNAVAILABLE';
    if (e.code === 3) return 'TIMEOUT';
    return String(e.message || e.name || e).slice(0, 60);
  },

  _guiding() {
    if (this._mode === 'ALIGN') return !!this._locked;
    return !!(this._fix && this._origin);
  },

  // ---------- destinations (PRESET mode, demo data) ----------

  _dests() {
    // Built-in DEMO preset destinations: small lat/lon offsets around the
    // current fix (or the labeled demo origin). This build has no way to
    // enter real destination coordinates - the presets stand in for one,
    // exactly as disclosed in the UI and README (same posture as #08).
    return [
      { name: '公交站', en: 'Bus stop', dLat: 0.0018, dLon: 0.0026 },
      { name: '便利店', en: 'Conv. store', dLat: -0.0011, dLon: 0.0022 },
      { name: '公园入口', en: 'Park gate', dLat: 0.0028, dLon: -0.0019 }
    ];
  },

  _dest() { return this._dests()[this._destIdx || 0]; },

  // Destination coordinates are anchored to the ORIGIN (the exit fix
  // taken at START), never to the moving current fix - otherwise the
  // target would walk along with the wearer and distance never shrink.
  _destCoords() {
    if (!this._origin) return null;
    var d = this._dest();
    return { lat: this._origin.lat + d.dLat, lon: this._origin.lon + d.dLon };
  },

  // ---------- heading (AbsoluteOrientationSensor) ----------

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

  // Yaw from the orientation quaternion [x, y, z, w]. The zero reference
  // is host-defined and the dossier does not fix its frame: ALIGN mode
  // only ever compares headings with each other (reference-free), while
  // PRESET bearings inherit that caveat (see README 未验证).
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

  // The guide engine ticks on accumulated tick counts (500 ms per tick),
  // NOT on repeated Date samples, so the 3 s drift rule cannot be
  // distorted by the preview host's drifting clock (same discipline
  // as #38 memory-anchor).
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._guideTick();
    }, 500);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- position: one fix + live watch ----------

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _fixOnce() {
    var self = this;
    var p = new Promise(function (resolve, reject) {
      if (!navigator.geolocation || !navigator.geolocation.getCurrentPosition) {
        reject(new Error('geolocation n/a on this host'));
        return;
      }
      navigator.geolocation.getCurrentPosition(resolve, reject,
        { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 });
    });
    return this._withTimeout(p, 12000, 'geo').then(function (pos) {
      return pos;
    }).catch(function (e) {
      self.setData({
        status: 'GPS FAIL: ' + self._err(e) + ' - tap DEMO to simulate',
        fixLine: 'FIX: FAIL ' + self._err(e) + ' (no fix taken)',
        lastEvent: 'EVT: geo FAIL ' + self._err(e)
      });
      return null;
    });
  },

  _applyFix(pos, label) {
    this._fix = { lat: pos.coords.latitude, lon: pos.coords.longitude, acc: pos.coords.accuracy || 0 };
    if (!this._origin) this._origin = { lat: this._fix.lat, lon: this._fix.lon };
    this._fixTime = this._timeStr(new Date());
    this.setData({
      fixLine: 'FIX: ' + this._fix.lat.toFixed(4) + ',' + this._fix.lon.toFixed(4) +
        ' ±' + Math.round(this._fix.acc) + 'm · ' + label + ' ' + this._fixTime,
      lastEvent: 'EVT: fix ok (' + label + ') - guidance updated'
    });
  },

  async startTap() {
    if (this.data.busy) return;
    this.setData({ busy: true, status: 'LOCATING...' });
    var pos = await this._fixOnce();
    if (pos && pos.coords) {
      if (this._demo) { this._demo = false; if (this._headingSrc === 'DEMO') this._headingSrc = this._sensor ? 'SENSOR' : 'NONE'; }
      this._applyFix(pos, 'GPS');
      // START means "I am at the exit now": re-anchor the presets here.
      this._origin = { lat: this._fix.lat, lon: this._fix.lon };
      this.setData({ status: 'FIX OK - face your way + ALIGN, or swipe for a preset' });
      this._startWatch();
      this._recompute();
    }
    this.setData({ busy: false });
  },

  // Manual re-fix: the fallback when watchPosition is unavailable or has
  // failed, and a manual refresh otherwise. Labeled as such on the fix line.
  async updateTap() {
    if (this.data.busy) return;
    this.setData({ busy: true, status: 'RE-FIXING...' });
    var pos = await this._fixOnce();
    if (pos && pos.coords) {
      if (this._demo) { this._demo = false; if (this._headingSrc === 'DEMO') this._headingSrc = this._sensor ? 'SENSOR' : 'NONE'; }
      this._applyFix(pos, 'GPS re-fix');
      this.setData({
        status: this._watchState === 'live' ? 'FIX UPDATED (watch still live)' :
          'FIX UPDATED manually - watch ' + this._watchState + ', UPDATE re-fixes'
      });
      if (this._watchState !== 'live') this._startWatch();
      this._recompute();
    }
    this.setData({ busy: false });
  },

  _startWatch() {
    if (this._watchId !== null || this._demo) return;
    if (!navigator.geolocation || typeof navigator.geolocation.watchPosition !== 'function') {
      this._watchState = 'n/a';
      this.setData({ lastEvent: 'EVT: watchPosition n/a on this host - UPDATE re-fixes manually' });
      this._recompute();
      return;
    }
    var self = this;
    try {
      this._watchId = navigator.geolocation.watchPosition(
        function (pos) {
          if (pos && pos.coords) {
            self._watchState = 'live';
            self._applyFix(pos, 'GPS');
            self._recompute();
          }
        },
        function (e) {
          self._watchState = 'fail';
          self._stopWatch();
          self.setData({
            status: 'WATCH FAIL: ' + self._err(e) + ' - tap UPDATE to re-fix',
            lastEvent: 'EVT: watch FAIL ' + self._err(e) + ' - manual UPDATE fallback'
          });
          self._recompute();
        },
        { enableHighAccuracy: false, timeout: 15000, maximumAge: 5000 });
      this._watchState = 'live';
    } catch (e) {
      this._watchId = null;
      this._watchState = 'n/a';
      this.setData({ lastEvent: 'EVT: watch start failed - UPDATE re-fixes manually' });
    }
    this._recompute();
  },

  _stopWatch() {
    if (this._watchId !== null && typeof navigator !== 'undefined' && navigator.geolocation) {
      try { navigator.geolocation.clearWatch(this._watchId); } catch (e) {}
    }
    this._watchId = null;
    if (this._watchState === 'live') this._watchState = 'off';
  },

  // ---------- ALIGN: lock the wearer's own facing as the course ----------

  alignTap() {
    if (this._heading === null) {
      this.setData({
        status: 'ALIGN FAIL - no heading (SRC NONE)',
        lastEvent: 'EVT: ALIGN refused - no heading; face a known way or tap DEMO'
      });
      return;
    }
    this._mode = 'ALIGN';
    this._locked = { bearing: Math.round(this._heading * 10) / 10, time: this._timeStr(new Date()) };
    this._resetEpisodes();
    this.setData({
      status: 'COURSE LOCKED - walk, keep the arrow up',
      lastEvent: 'EVT: ALIGN locked course ' + Math.round(this._locked.bearing) + ' deg at ' + this._locked.time
    });
    this._recompute();
  },

  _resetEpisodes() {
    this._driftTicks = 0;
    this._driftSpoken = false;
    this._arrivedSpoken = false;
  },

  // ---------- demo simulation ----------

  demoTap() {
    if (!this._demo) {
      var now = new Date(); // ONE snapshot: every demo time derives from it
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._mode = 'PRESET';
      this._destIdx = 0;
      this._watchState = 'off';
      this._origin = { lat: this._demoOrigin.lat, lon: this._demoOrigin.lon };
      this._fix = { lat: this._demoOrigin.lat, lon: this._demoOrigin.lon, acc: 0 };
      this._fixTime = this._timeStr(now);
      this._resetEpisodes();
      this.setData({
        fixLine: 'FIX: DEMO origin ' + this._demoOrigin.lat.toFixed(4) + ',' +
          this._demoOrigin.lon.toFixed(4) + ' ' + this._fixTime + ' (simulated)',
        status: 'DEMO MODE - tap DEMO: heading +45, walk closer',
        lastEvent: 'EVT: DEMO on - simulated fix + heading 0 deg'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      // Walk-in: each extra tap closes 55% of the remaining distance to
      // the demo destination, so the ARRIVED state is reachable in preview.
      var dc = this._destCoords();
      if (dc && this._fix) {
        this._fix = {
          lat: this._fix.lat + (dc.lat - this._fix.lat) * 0.55,
          lon: this._fix.lon + (dc.lon - this._fix.lon) * 0.55,
          acc: 0
        };
      }
      this.setData({
        status: 'DEMO MODE - heading ' + this._demoHeading + ' deg, walked closer (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg + walk-in'
      });
    }
    this._recompute();
  },

  // ---------- guidance math (same geometry as #06 / #08) ----------

  _bearingDist(lat1, lon1, lat2, lon2) {
    var R = 6371000;
    var p1 = lat1 * Math.PI / 180, p2 = lat2 * Math.PI / 180;
    var dp = (lat2 - lat1) * Math.PI / 180;
    var dl = (lon2 - lon1) * Math.PI / 180;
    var a = Math.sin(dp / 2) * Math.sin(dp / 2) +
      Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
    var dist = 2 * R * Math.asin(Math.sqrt(a));
    var y = Math.sin(dl) * Math.cos(p2);
    var x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl);
    var brg = Math.atan2(y, x) * 180 / Math.PI;
    return { bearing: (brg + 360) % 360, dist: dist };
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _distText(m) {
    if (m < 1000) return Math.round(m) + ' m';
    return (m / 1000).toFixed(1) + ' km';
  },

  // The guidance target: ALIGN -> the locked facing (a relative course,
  // reference-frame free); PRESET -> true bearing to the demo destination.
  _targetBearing() {
    if (this._mode === 'ALIGN') {
      return this._locked ? this._locked.bearing : null;
    }
    var dc = this._destCoords();
    if (!dc || !this._fix) return null;
    return this._bearingDist(this._fix.lat, this._fix.lon, dc.lat, dc.lon).bearing;
  },

  // rel = target - current heading, normalized -180..180; + = target is
  // to your RIGHT (you have drifted left of the course).
  _relTo(bearing) {
    if (bearing === null || this._heading === null) return null;
    return ((bearing - this._heading + 540) % 360) - 180;
  },

  _presetDist() {
    var dc = this._destCoords();
    if (!dc || !this._fix) return null;
    return this._bearingDist(this._fix.lat, this._fix.lon, dc.lat, dc.lon).dist;
  },

  // ---------- guide engine (drift episodes + arrival) ----------

  // Runs every 500 ms tick. Drift rule: |rel| beyond 30 deg for 3
  // continuous seconds (6 ticks) speaks ONE correction per episode;
  // coming back within 15 deg re-arms. Arrival (< 40 m, PRESET only)
  // speaks once per approach.
  _guideTick() {
    var wasArrived = this._arrived;
    this._arrived = false;
    if (this._mode === 'PRESET') {
      var dist = this._presetDist();
      if (dist !== null && dist < 40) {
        this._arrived = true;
        if (!this._arrivedSpoken) {
          this._arrivedSpoken = true;
          var d = this._dest();
          var ok = this._speak('你到了，' + d.name + '就在附近，抬头找一找。');
          this.setData({ lastEvent: 'EVT: ARRIVED < 40 m' + (ok ? ' (spoken once)' : ' (TTS n/a here)') });
        }
      } else {
        this._arrivedSpoken = false;
      }
    }
    if (this._arrived !== wasArrived) this._recompute();
    if (this._arrived) { this._driftTicks = 0; return; }

    var rel = this._relTo(this._targetBearing());
    if (rel === null || !this._guiding()) { this._driftTicks = 0; return; }
    var a = Math.abs(rel);
    if (a <= 15) {
      this._driftTicks = 0;
      this._driftSpoken = false; // back on course: episode closed, re-armed
      return;
    }
    if (a <= 30) { this._driftTicks = 0; return; } // off course, below drift rule
    this._driftTicks += 1;
    if (this._driftTicks * 500 >= 3000 && !this._driftSpoken) {
      this._driftSpoken = true;
      var deg = Math.round(a);
      // rel > 0: target sits to your right -> you drifted LEFT, correct right.
      var text = rel > 0
        ? '你偏向左边了，往右修正 ' + deg + ' 度。'
        : '你偏向右边了，往左修正 ' + deg + ' 度。';
      var ok2 = this._speak(text);
      this.setData({ lastEvent: 'EVT: drift ' + deg + ' deg over 3 s - correction' + (ok2 ? ' spoken once' : ' (TTS n/a here)') });
    }
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · WATCH: ' +
        (this._demo ? 'DEMO' : this._watchState)
    };
    var bearing = this._targetBearing();
    var rel = this._relTo(bearing);

    if (this._mode === 'ALIGN') {
      if (!this._locked) {
        patch.targetLine = 'COURSE: not locked - face your way, tap ALIGN';
        patch.arrow = '·';
        patch.relLine = 'GUIDE: ---';
        patch.courseCls = 'rel';
        this._lastSpeak = null;
        this.setData(patch);
        return;
      }
      patch.targetLine = 'COURSE: locked ' + Math.round(this._locked.bearing) + ' deg · ' +
        this._locked.time + ' · re-ALIGN at corners';
      if (rel === null) {
        patch.arrow = '·';
        patch.relLine = 'GUIDE: heading n/a - SRC NONE, tap DEMO';
        patch.courseCls = 'rel';
        this._lastSpeak = null;
        this.setData(patch);
        return;
      }
      this._paintGuidance(patch, rel, 'COURSE');
      this._lastSpeak = {
        kind: 'align', onCourse: Math.abs(rel) <= 15,
        zh: this._dirName(rel).zh, deg: Math.round(Math.abs(rel))
      };
      this.setData(patch);
      return;
    }

    // PRESET mode
    var d = this._dest();
    if (!this._fix || !this._origin) {
      patch.targetLine = 'DEST: ' + d.name + ' ' + d.en + ' (demo preset) · no fix yet';
      patch.arrow = '·';
      patch.relLine = 'GUIDE: ---';
      patch.courseCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    var dist = this._presetDist();
    patch.targetLine = 'DEST: ' + d.name + ' ' + d.en + ' (demo preset) · ' +
      this._distText(dist) + ' · brg ' + Math.round(bearing) + ' deg';
    if (dist < 40) {
      patch.arrow = '◎';
      patch.relLine = 'ARRIVED — look up, it is near';
      patch.courseCls = 'rel rel-on';
      this._lastSpeak = { kind: 'arrived', name: d.name };
      this.setData(patch);
      return;
    }
    if (rel === null) {
      patch.arrow = '·';
      patch.relLine = 'GUIDE: heading n/a - SRC NONE, tap DEMO';
      patch.courseCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    this._paintGuidance(patch, rel, 'DEST');
    this._lastSpeak = {
      kind: 'preset', name: d.name, onCourse: Math.abs(rel) <= 15,
      zh: this._dirName(rel).zh, deg: Math.round(Math.abs(rel)),
      distText: this._distText(dist)
    };
    this.setData(patch);
  },

  _paintGuidance(patch, rel, prefix) {
    var rel360 = (rel + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var deg = Math.round(Math.abs(rel));
    if (Math.abs(rel) <= 15) {
      patch.relLine = 'ON COURSE — WALK STRAIGHT';
      patch.courseCls = 'rel rel-on';
    } else {
      patch.relLine = prefix + ': ' + this._dirName(rel).en + ' ' + deg + '°';
      patch.courseCls = 'rel';
    }
  },

  // ---------- speech (TTS out only; lang is never set) ----------

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  speakTap() {
    var s = this._lastSpeak;
    var text;
    if (!s) {
      text = '还没有开始指引。先点开始定位，对准方向后点锁定方向。';
    } else if (s.kind === 'arrived') {
      text = '你到了，' + s.name + '就在附近，抬头找一找。';
    } else if (s.kind === 'align') {
      text = s.onCourse
        ? '方向正确，沿着你锁定的方向一直往前走。'
        : '锁定的方向在你' + s.zh + ' ' + s.deg + ' 度，修正后继续走。';
    } else if (s.onCourse) {
      text = s.name + '就在你正前方，约 ' + s.distText + '，一直往前走。';
    } else {
      text = s.name + '在你' + s.zh + ' ' + s.deg + ' 度，约 ' + s.distText + '。';
    }
    var ok = this._speak(text);
    this.setData({
      lastEvent: ok ? 'EVT: TTS speak sent: ' + text : 'EVT: SPEAK FAIL - speechSynthesis n/a on this host'
    });
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">TRANSIT DIR</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="fix">{{fixLine}}</text>
      <text class="info">{{modeLine}}</text>
      <text class="info">{{targetLine}}</text>
    </view>
    <view class="arrow-box">
      <text class="arrow">{{arrow}}</text>
      <text class="{{courseCls}}">{{relLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn btn-main" bindtap="alignTap">ALIGN</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 12px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 6px;
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
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 6px 10px;
  margin-bottom: 6px;
}
.fix {
  color: #40ff5e;
  font-size: 13px;
  line-height: 17px;
}
.info {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.arrow-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 4px;
  margin-bottom: 6px;
}
.arrow {
  color: #40ff5e;
  font-size: 34px;
  line-height: 38px;
  text-align: center;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
  text-align: center;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 6px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 5px;
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
  margin-top: 2px;
}
</style>
