<script def>
{
  "navigationBarTitleText": "Parking Return"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PARK: pick a ZONE, tap PARK when you leave the car',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: PARK · ZONE: B1',
    spotLine: 'SPOT: none saved - PARK first',
    posLine: 'POS: no fix yet (RETURN: UPDATE / DEMO)',
    arrow: '·',
    relLine: 'CAR: ---',
    relCls: 'rel',
    cueLine: 'CUES: park first, then RETURN shows zone + car-nose heading',
    plateLine: 'PLATE: photo record only - no photo yet',
    lastEvent: 'EVT: MODE toggles / ZONE cycles / nod when steady = PARK or UPDATE',
    busy: false
  },

  onLoad() {
    this._mode = 'PARK';
    this._zoneIdx = 0;
    this._spot = this._loadSpot();
    if (this._spot) this._mode = 'RETURN';
    this._origin = null;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
    this._demoSteps = 0;
    this._demoNear = false;
    this._demoOrigin = { lat: 35.6812, lon: 139.7671 };
    this._sensor = null;
    this._timer = null;
    this._steady = false;
    this._lastSpeak = null;
    this._stream = null;
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
    this._stopStream();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopStream();
    this._saveSpot();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    if (this._mode === 'PARK') this.parkTap();
    else this.updateTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      if (this._mode === 'PARK') this.zoneTap(); else this.updateTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm = re-fix / park' });
      if (this._mode === 'PARK') this.parkTap(); else this.updateTap();
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
    if (e.code === 1) return 'PERMISSION_DENIED';
    if (e.code === 2) return 'POSITION_UNAVAILABLE';
    if (e.code === 3) return 'TIMEOUT';
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

  _nowTime() {
    var d = new Date();
    var hh = d.getHours(); if (hh < 10) hh = '0' + hh;
    var mm = d.getMinutes(); if (mm < 10) mm = '0' + mm;
    return hh + ':' + mm;
  },

  // ---------- zones ----------

  _zones() { return ['B1', 'B2', 'B3', '地面', '路边']; },
  _zone() { return this._zones()[this._zoneIdx || 0]; },

  zoneTap() {
    this._zoneIdx = ((this._zoneIdx || 0) + 1) % this._zones().length;
    this.setData({ lastEvent: 'EVT: zone -> ' + this._zone() });
    this._recompute();
  },

  modeTap() {
    this._mode = this._mode === 'PARK' ? 'RETURN' : 'PARK';
    this.setData({
      status: this._mode === 'PARK'
        ? 'PARK: pick a ZONE, tap PARK when you leave the car'
        : 'RETURN: tap UPDATE for a fix, follow the arrow to your car',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  // ---------- persistence (wx sync storage, key 'parkingSpot') ----------

  _loadSpot() {
    try {
      var r = wx.getStorageSync('parkingSpot');
      if (!r || typeof r !== 'object') return null;
      if (typeof r.zone !== 'string' || typeof r.time !== 'string') return null;
      var spot = {
        lat: isFinite(r.lat) ? Number(r.lat) : null,
        lon: isFinite(r.lon) ? Number(r.lon) : null,
        hasFix: !!r.hasFix && isFinite(r.lat) && isFinite(r.lon),
        accuracy: isFinite(r.accuracy) ? Number(r.accuracy) : 0,
        headingDeg: isFinite(r.headingDeg) ? ((Math.round(r.headingDeg) % 360) + 360) % 360 : null,
        zone: String(r.zone).slice(0, 6),
        time: String(r.time).slice(0, 5),
        demo: !!r.demo
      };
      if (!spot.hasFix) { spot.lat = null; spot.lon = null; }
      return spot;
    } catch (e) {
      return null;
    }
  },

  _saveSpot() {
    try {
      // DEMO spots are simulation only: never overwrite a real record.
      if (this._spot && !this._spot.demo) {
        wx.setStorageSync('parkingSpot', this._spot);
      } else if (!this._spot) {
        wx.setStorageSync('parkingSpot', '');
      }
    } catch (e) { /* storage unavailable on this host: record stays in memory */ }
  },

  _clearStoredSpot() {
    try { wx.setStorageSync('parkingSpot', ''); } catch (e) { /* see above */ }
  },

  // ---------- heading (AbsoluteOrientationSensor, same as head-nav) ----------

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

  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      } else {
        self._recompute();
      }
    }, 5000);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- position (single fixes only, never a watch) ----------

  _fixRaw() {
    var p = new Promise(function (resolve, reject) {
      if (!navigator.geolocation || !navigator.geolocation.getCurrentPosition) {
        reject(new Error('geolocation n/a on this host'));
        return;
      }
      navigator.geolocation.getCurrentPosition(resolve, reject,
        { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 });
    });
    return this._withTimeout(p, 12000, 'geo');
  },

  // ---------- PARK ----------

  async parkTap() {
    if (this.data.busy) return;
    if (this._mode !== 'PARK') {
      this.setData({ lastEvent: 'EVT: PARK only applies in PARK mode (MODE toggles)' });
      return;
    }
    this.setData({ busy: true, status: 'PARKING: taking a fix...' });
    var pos = null, fixErr = null;
    try {
      pos = await this._fixRaw();
    } catch (e) {
      fixErr = e;
    }
    // The record saves either way: with a fix it guides you back; without
    // one (underground garage) it still keeps zone + car-nose heading +
    // time, and RETURN falls back to those cues. Nothing is invented.
    var spot = {
      lat: pos && pos.coords ? pos.coords.latitude : null,
      lon: pos && pos.coords ? pos.coords.longitude : null,
      hasFix: !!(pos && pos.coords),
      accuracy: pos && pos.coords ? Math.round(pos.coords.accuracy || 0) : 0,
      headingDeg: this._heading === null ? null : Math.round(this._heading),
      zone: this._zone(),
      time: this._nowTime(),
      demo: !!this._demo
    };
    this._spot = spot;
    this._saveSpot();
    if (spot.hasFix) {
      this.setData({
        status: 'PARKED: ' + spot.zone + ' · fix ±' + spot.accuracy + 'm · car nose ' +
          (spot.headingDeg === null ? 'n/a' : spot.headingDeg + '°') + ' · ' + spot.time,
        lastEvent: 'EVT: parked with GPS fix - switch MODE to RETURN when you come back'
      });
    } else {
      this.setData({
        status: 'PARKED (no fix): ' + spot.zone + ' · ' + this._err(fixErr),
        lastEvent: 'EVT: parked WITHOUT a fix (' + this._err(fixErr) +
          ') - record kept, honestly marked no fix'
      });
    }
    this._recompute();
    this.setData({ busy: false });
  },

  // ---------- RETURN ----------

  async updateTap() {
    if (this.data.busy) return;
    if (this._mode !== 'RETURN') {
      this.setData({ lastEvent: 'EVT: UPDATE only applies in RETURN mode (MODE toggles)' });
      return;
    }
    if (this._demo) {
      // In DEMO the simulated position is the demo origin; UPDATE just
      // recomputes guidance from it (DEMO steps the heading instead).
      this._origin = { lat: this._demoOrigin.lat, lon: this._demoOrigin.lon };
      this.setData({
        posLine: 'POS: DEMO origin ' + this._demoOrigin.lat.toFixed(4) + ',' +
          this._demoOrigin.lon.toFixed(4) + ' (simulated)',
        lastEvent: 'EVT: DEMO re-fix at simulated origin'
      });
      this._recompute();
      return;
    }
    this.setData({ busy: true, status: 'LOCATING...' });
    try {
      var pos = await this._fixRaw();
      if (pos && pos.coords) {
        this._origin = { lat: pos.coords.latitude, lon: pos.coords.longitude };
        this.setData({
          posLine: 'POS: ' + pos.coords.latitude.toFixed(4) + ',' +
            pos.coords.longitude.toFixed(4) + ' ±' + Math.round(pos.coords.accuracy || 0) + 'm · GPS',
          status: 'FIX OK - turn until the arrow points up',
          lastEvent: 'EVT: GPS fix ok, guidance updated'
        });
        this._recompute();
      }
    } catch (e) {
      this.setData({
        status: 'GPS FAIL: ' + this._err(e) + ' - cues still shown below',
        posLine: 'POS: FAIL ' + this._err(e) + ' (no fix taken)',
        lastEvent: 'EVT: geo FAIL ' + this._err(e)
      });
    }
    this.setData({ busy: false });
  },

  // ---------- FOUND ----------

  foundTap() {
    if (!this._spot) {
      this.setData({ lastEvent: 'EVT: no record to clear' });
      return;
    }
    var wasDemo = !!this._spot.demo;
    this._spot = null;
    this._origin = null;
    if (wasDemo) {
      // Demo spot was memory-only; reload any real stored record.
      this._spot = this._loadSpot();
    } else {
      this._clearStoredSpot();
    }
    this._mode = this._spot ? 'RETURN' : 'PARK';
    this.setData({
      status: wasDemo
        ? '车已取回 (DEMO record cleared)'
        : '车已取回 — record cleared, ready for next park',
      plateLine: 'PLATE: photo record only - no photo yet',
      posLine: 'POS: no fix yet (RETURN: UPDATE / DEMO)',
      lastEvent: 'EVT: FOUND - parking record cleared' + (wasDemo ? ' (demo)' : '')
    });
    this._recompute();
  },

  // ---------- PLATE photo record (telephoto, no OCR) ----------

  _stopStream() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  async plateTap() {
    if (this.data.busy) return;
    if (this._mode !== 'RETURN') {
      this.setData({ lastEvent: 'EVT: PLATE is for RETURN - get near your car first' });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        plateLine: 'PLATE: FAIL - mediaDevices n/a on this host, no photo taken',
        lastEvent: 'EVT: plate FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, plateLine: 'PLATE: capturing (telephoto)...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
      var bytes = blob && blob.size ? blob.size : 0;
      this.setData({
        plateLine: 'PLATE: photo ' + bytes + 'B · telephoto - record only, compare with your eyes (NO OCR)',
        lastEvent: 'EVT: plate-area photo recorded ' + bytes + 'B (visual record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) { this._stopStream(); stream = null; }
      // Fallback: wx camera context, like gaze-translate / glasses-benchmark.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          plateLine: 'PLATE: wx photo ' + size + 'B - record only, compare with your eyes (NO OCR)',
          lastEvent: 'EVT: plate-area wx photo recorded ' + size + 'B (visual record only)'
        });
      } catch (e2) {
        this.setData({
          plateLine: 'PLATE: FAIL - ' + this._err(firstErr) + ', no photo taken',
          lastEvent: 'EVT: plate FAIL - ' + this._err(firstErr)
        });
      }
    } finally {
      if (stream) this._stopStream();
      this.setData({ busy: false });
    }
  },

  // ---------- DEMO ----------

  // DEMO stores a labeled demo spot ~120 m from the simulated origin and
  // enters RETURN; further taps step the simulated heading +45°. After a
  // full turn (8 steps) the demo spot switches to a NEAR variant (~15 m),
  // then back again. The demo spot lives in memory only - it never
  // overwrites the stored real record.
  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._demoSteps = 0;
      this._demoNear = false;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._origin = { lat: this._demoOrigin.lat, lon: this._demoOrigin.lon };
      this._spot = this._demoSpot(false);
      this._mode = 'RETURN';
      this.setData({
        posLine: 'POS: DEMO origin ' + this._demoOrigin.lat.toFixed(4) + ',' +
          this._demoOrigin.lon.toFixed(4) + ' (simulated)',
        status: 'DEMO RETURN: car ~120 m away (DEMO: heading +45)',
        lastEvent: 'EVT: DEMO on - demo spot (memory only); 8 DEMO steps = NEAR demo'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      this._demoSteps++;
      if (this._demoSteps % 8 === 0) {
        this._demoNear = !this._demoNear;
        this._spot = this._demoSpot(this._demoNear);
        this.setData({
          status: this._demoNear
            ? 'DEMO NEAR: car ~15 m away - look with the cues'
            : 'DEMO RETURN: car ~120 m away (DEMO: heading +45)',
          lastEvent: 'EVT: DEMO spot -> ' + (this._demoNear ? 'NEAR variant (~15 m)' : 'far variant (~120 m)')
        });
      } else {
        this.setData({
          status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
          lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
        });
      }
    }
    this._recompute();
  },

  _demoSpot(near) {
    var d = near ? { dLat: 0.00012, dLon: 0.00006 } : { dLat: 0.0010, dLon: 0.0005 };
    return {
      lat: this._demoOrigin.lat + d.dLat,
      lon: this._demoOrigin.lon + d.dLon,
      hasFix: true,
      accuracy: 5,
      headingDeg: 140,
      zone: 'B2',
      time: this._nowTime(),
      demo: true
    };
  },

  // ---------- guidance math (same as head-nav / meet-point) ----------

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

  _spotText(spot) {
    if (!spot) return 'SPOT: none saved - PARK first';
    var nose = spot.headingDeg === null ? '车头朝向未记录' : '车头 ' + spot.headingDeg + '°';
    var fix = spot.hasFix ? 'fix ±' + spot.accuracy + 'm' : 'NO FIX (zone+heading only)';
    return 'SPOT: ' + spot.zone + ' · ' + nose + ' · ' + spot.time + ' · ' + fix +
      (spot.demo ? ' · DEMO' : '');
  },

  _cueText(spot) {
    if (!spot) return 'CUES: park first, then RETURN shows zone + car-nose heading';
    var nose = spot.headingDeg === null ? '车头朝向当时未记录' : '车头当时朝 ' + spot.headingDeg + '°';
    return 'CUES: 区域 ' + spot.zone + ' · ' + nose + ' · ' + spot.time + ' 停好' +
      (spot.demo ? ' (DEMO)' : '');
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var spot = this._spot;
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · ZONE: ' + this._zone(),
      spotLine: this._spotText(spot),
      cueLine: this._cueText(spot)
    };
    if (this._mode === 'PARK') {
      patch.arrow = '·';
      patch.relLine = spot ? 'CAR: parked - MODE -> RETURN to go back' : 'CAR: ---';
      patch.relCls = 'rel';
      this._lastSpeak = spot ? { kind: 'parked', spot: spot } : null;
      this.setData(patch);
      return;
    }
    // RETURN mode
    if (!spot) {
      patch.arrow = '·';
      patch.relLine = 'CAR: no record - MODE -> PARK first';
      patch.relCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    if (!spot.hasFix) {
      // No-fix record (e.g. underground garage): no arrow games - the
      // zone + car-nose heading cues are the honest guidance.
      patch.arrow = '◎';
      patch.relLine = 'NEAR — no GPS record, use the cues below';
      patch.relCls = 'rel rel-on';
      this._lastSpeak = { kind: 'near', spot: spot };
      this.setData(patch);
      return;
    }
    if (!this._origin) {
      patch.arrow = '·';
      patch.relLine = 'CAR: tap UPDATE for your fix';
      patch.relCls = 'rel';
      this._lastSpeak = { kind: 'parked', spot: spot };
      this.setData(patch);
      return;
    }
    var bd = this._bearingDist(this._origin.lat, this._origin.lon, spot.lat, spot.lon);
    if (bd.dist < 25) {
      // Within ~25 m GPS noise dominates direction: switch to eyes.
      patch.arrow = '◎';
      patch.relLine = 'NEAR — look for your car · ' + this._distText(bd.dist);
      patch.relCls = 'rel rel-on';
      this._lastSpeak = { kind: 'near', spot: spot, distText: this._distText(bd.dist) };
      this.setData(patch);
      return;
    }
    if (this._heading === null) {
      patch.arrow = '·';
      patch.relLine = 'CAR: heading n/a - SRC NONE, tap DEMO';
      patch.relCls = 'rel';
      this._lastSpeak = { kind: 'parked', spot: spot };
      this.setData(patch);
      return;
    }
    var rel = ((bd.bearing - this._heading + 540) % 360) - 180; // -180..180, + = right
    var rel360 = (bd.bearing - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    var arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    var onCourse = Math.abs(rel) <= 15;
    patch.arrow = arrow;
    if (onCourse) {
      patch.relLine = 'ON COURSE — walk straight · ' + this._distText(bd.dist);
      patch.relCls = 'rel rel-on';
    } else {
      patch.relLine = 'CAR: ' + dir.en + ' ' + deg + '° · ' + this._distText(bd.dist);
      patch.relCls = 'rel';
    }
    this._lastSpeak = {
      kind: 'guide', zh: dir.zh, deg: deg,
      distText: this._distText(bd.dist), onCourse: onCourse
    };
    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var s = this._lastSpeak;
      var text;
      if (!s) {
        text = '还没有停车记录。停车时先选区域，点停车保存。';
      } else if (s.kind === 'near') {
        var sp = s.spot;
        var parts = sp.time.split(':');
        text = '你的车就在这一带找。区域' + sp.zone + '，' +
          (sp.headingDeg === null ? '车头朝向当时没有记录' : '车头当时朝' + sp.headingDeg + '度') +
          '，' + parts[0] + '点' + parts[1] + '分停好的。抬头找车。';
      } else if (s.kind === 'parked') {
        var sp2 = s.spot;
        text = '车停在' + sp2.zone + '，' +
          (sp2.headingDeg === null ? '车头朝向没有记录' : '车头朝' + sp2.headingDeg + '度') +
          '。回停车场时切到返回模式，点更新定位，跟着箭头走。';
      } else if (s.onCourse) {
        text = '车就在你正前方，约 ' + s.distText + '，一直往前走。';
      } else {
        text = '车在你' + s.zh + ' ' + s.deg + ' 度，约 ' + s.distText + '。';
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">PARKING RETURN</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="spot-box">
      <text class="spot-mode">{{modeLine}}</text>
      <text class="spot">{{spotLine}}</text>
      <text class="pos">{{posLine}}</text>
    </view>
    <view class="guide-box">
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{relCls}}">{{relLine}}</text>
      </view>
      <text class="cue">{{cueLine}}</text>
      <text class="plate">{{plateLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="zoneTap">ZONE</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="parkTap">PARK</button>
      <button class="btn" bindtap="updateTap">UPDATE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="plateTap">PLATE</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="foundTap">FOUND</button>
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
  margin-bottom: 5px;
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
.spot-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 10px;
  margin-bottom: 5px;
}
.spot-mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.spot {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.pos {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.guide-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 3px 10px 5px;
  margin-bottom: 5px;
}
.guide-top {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.arrow {
  color: #40ff5e;
  font-size: 28px;
  line-height: 31px;
  margin-right: 10px;
  text-align: center;
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
.cue {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.plate {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 4px;
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
  margin-top: 1px;
}
</style>
