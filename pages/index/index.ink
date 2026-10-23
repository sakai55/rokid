<script def>
{
  "navigationBarTitleText": "Meet Point"
}
</script>

<script setup>
export default {
  data: {
    status: 'TAP SHARE FOR YOUR FIX, OR DEMO TO SIMULATE',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    myLine: 'MY COORDS: no fix yet (SHARE / DEMO)',
    partnerLine: 'PARTNER: 广场北口 (demo partner position) · ---',
    arrow: '·',
    relLine: 'PARTNER: ---',
    courseCls: 'rel',
    lastEvent: 'EVT: nod = re-fix / PARTNER cycles partner / DEMO rotates',
    busy: false
  },

  onLoad() {
    this._partnerIdx = 0;
    this._origin = null;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
    this._demoOrigin = { lat: 35.6812, lon: 139.7671 };
    this._sensor = null;
    this._timer = null;
    this._watchId = null;
    this._lastSpeak = null;
    this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
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
    if (this._watchId !== null && navigator.geolocation) {
      try { navigator.geolocation.clearWatch(this._watchId); } catch (e) {}
      this._watchId = null;
    }
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
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g === 'nod' && this._steady) this.startTap();
    else if (g === 'nod') this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.partnerTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm = re-fix' });
      this.startTap();
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

  // ---------- partner presets ----------

  _partners() {
    // Partner positions as small lat/lon offsets around MY fix (or the
    // labeled DEMO origin). In real use these presets are replaced by the
    // coordinates the partner reads aloud / messages to you — there is no
    // live sync service in this runtime, and the UI labels these DEMO.
    return [
      { name: '广场北口', en: 'Plaza N gate', dLat: 0.0016, dLon: 0.0004 },
      { name: '车站西门', en: 'Station W gate', dLat: -0.0005, dLon: 0.0022 },
      { name: '咖啡店门口', en: 'Coffee shop', dLat: 0.0002, dLon: -0.0011 },
      { name: '近处样例', en: 'NEAR demo', dLat: 0.00014, dLon: 0.00010 }
    ];
  },

  _partner() { return this._partners()[this._partnerIdx || 0]; },

  partnerTap() {
    this._partnerIdx = ((this._partnerIdx || 0) + 1) % this._partners().length;
    var p = this._partner();
    this.setData({ lastEvent: 'EVT: partner -> ' + p.name + ' ' + p.en + ' (demo preset)' });
    this._recompute();
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

  _yawDeg(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    var deg = yaw * 180 / Math.PI;
    return (deg + 360) % 360;
  },

  _onHeading(sensor) {
    if (this._demo) return;
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

  // ---------- position ----------

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

  _fix() {
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
        myLine: 'MY COORDS: FAIL ' + self._err(e) + ' (no fix taken)',
        lastEvent: 'EVT: geo FAIL ' + self._err(e)
      });
      return null;
    });
  },

  // SHARE: fix my position and show the coordinates BIG — I read them to
  // my partner by voice/message; they do the same on their side. That
  // read-aloud exchange is the real channel; nothing syncs by itself.
  async startTap() {
    if (this.data.busy) return;
    this.setData({ busy: true, status: 'LOCATING...' });
    var pos = await this._fix();
    if (pos && pos.coords) {
      this._demo = false;
      this._origin = { lat: pos.coords.latitude, lon: pos.coords.longitude };
      if (this._headingSrc === 'DEMO') this._headingSrc = this._sensor ? 'SENSOR' : 'NONE';
      this.setData({
        myLine: 'MY COORDS: ' + pos.coords.latitude.toFixed(5) + ', ' +
          pos.coords.longitude.toFixed(5) + ' ±' + Math.round(pos.coords.accuracy || 0) + 'm · GPS',
        status: 'FIX OK - read these coords to your partner',
        lastEvent: 'EVT: GPS fix ok - share coords, then follow the arrow'
      });
      this._recompute();
    }
    this.setData({ busy: false });
  },

  shareTap() { this.startTap(); },
  updateTap() { this.startTap(); },

  // ---------- demo simulation ----------

  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._origin = { lat: this._demoOrigin.lat, lon: this._demoOrigin.lon };
      this.setData({
        myLine: 'MY COORDS: ' + this._demoOrigin.lat.toFixed(5) + ', ' +
          this._demoOrigin.lon.toFixed(5) + ' (DEMO origin, simulated)',
        status: 'DEMO MODE - tap DEMO again: heading +45 deg',
        lastEvent: 'EVT: DEMO on - simulated origin + heading 0 deg'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      this.setData({
        status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
      });
    }
    this._recompute();
  },

  // ---------- guidance math ----------

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

  _recompute() {
    var p = this._partner();
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : '')
    };
    if (!this._origin) {
      patch.partnerLine = 'PARTNER: ' + p.name + ' ' + p.en + ' (demo partner position) · no fix yet';
      patch.arrow = '·';
      patch.relLine = 'PARTNER: ---';
      patch.courseCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    var pLat = this._origin.lat + p.dLat;
    var pLon = this._origin.lon + p.dLon;
    var bd = this._bearingDist(this._origin.lat, this._origin.lon, pLat, pLon);
    patch.partnerLine = 'PARTNER: ' + p.name + ' ' + p.en + ' (demo partner position) · ' +
      this._distText(bd.dist) + ' · brg ' + Math.round(bd.bearing) + ' deg';
    // Within ~25 m GPS noise dominates direction: declare arrival.
    if (bd.dist < 25) {
      patch.arrow = '◎';
      patch.relLine = 'ARRIVED — look up and find them';
      patch.courseCls = 'rel rel-on';
      this._lastSpeak = { arrived: true, distText: this._distText(bd.dist) };
      this.setData(patch);
      return;
    }
    if (this._heading === null) {
      patch.arrow = '·';
      patch.relLine = 'PARTNER: heading n/a - SRC NONE, tap DEMO';
      patch.courseCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    var rel = ((bd.bearing - this._heading + 540) % 360) - 180;
    var rel360 = (bd.bearing - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    var arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    var onCourse = Math.abs(rel) <= 15;
    patch.arrow = arrow;
    if (onCourse) {
      patch.relLine = 'ON COURSE — head that way · ' + this._distText(bd.dist);
      patch.courseCls = 'rel rel-on';
    } else {
      patch.relLine = 'PARTNER: ' + dir.en + ' ' + deg + '° · ' + this._distText(bd.dist);
      patch.courseCls = 'rel';
    }
    this._lastSpeak = {
      arrived: false, zh: dir.zh, deg: deg,
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
        text = '还没有定位结果。先点共享位置，或者点演示模拟。';
      } else if (s.arrived) {
        text = '你到了，对方就在附近，约 ' + s.distText + '，抬头找人。';
      } else if (s.onCourse) {
        text = '对方就在你正前方，约 ' + s.distText + '，一直往前走。';
      } else {
        text = '对方在你' + s.zh + ' ' + s.deg + ' 度，约 ' + s.distText + '。';
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
      <text class="title">MEET POINT</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="share-box">
      <text class="coords">{{myLine}}</text>
      <text class="hint">SHARE: read your coords aloud / by message - partner does the same</text>
    </view>
    <view class="arrow-box">
      <text class="partner">{{partnerLine}}</text>
      <text class="arrow">{{arrow}}</text>
      <text class="{{courseCls}}">{{relLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="shareTap">SHARE</button>
      <button class="btn" bindtap="partnerTap">PARTNER</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
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
.share-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 6px 10px;
  margin-bottom: 6px;
}
.coords {
  color: #40ff5e;
  font-size: 13px;
  line-height: 17px;
}
.hint {
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
  padding: 4px 10px 6px;
  margin-bottom: 6px;
}
.partner {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  text-align: center;
}
.arrow {
  color: #40ff5e;
  font-size: 38px;
  line-height: 42px;
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
