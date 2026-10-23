<script def>
{
  "navigationBarTitleText": "Sound Compass"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'Tap SCAN, then turn slowly in a circle',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    scanLine: 'SCAN: idle - no scan yet',
    levelLine: 'LVL: ---------- 0 · covered 0/72',
    noteLine: 'COARSE: loudest while you turned - not a bearing',
    arrow: '·',
    relLine: 'RESULT: scan first - SCAN or DEMO',
    relCls: 'rel',
    topLine: 'TOP: ---',
    lastEvent: 'EVT: reflections + steady noise distort a scan',
    busy: false
  },

  onLoad() {
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._sensor = null;
    this._steady = false;
    this._buckets = null;      // 72 x 5 deg buckets, max level 0..1, -1 = empty
    this._curLevel = 0;
    this._peak = null;         // { deg, level } after a finished scan
    this._lastSpeak = null;
    this._scanning = false;
    this._scanLeft = 0;
    this._scanTimer = null;
    this._stream = null;
    this._actx = null;
    this._analyser = null;
    this._srcNode = null;
    this._buf = null;
    this._demoTimer = null;
    this._demoStep = 0;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
  },

  onHide() {
    this._stopScan(true);
    this._stopDemo();
    this._stopHeading();
  },

  onUnload() {
    this._stopScan(true);
    this._stopDemo();
    this._stopHeading();
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
    if (this._peak) {
      if (this._steady) this.speakTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to SPEAK' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._scanning || this._demoTimer) this.stopTap(); else this.scanTap();
    } else if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.setData({ lastEvent: 'EVT: turn your head - the scan follows it' });
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

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  // ---------- heading (AbsoluteOrientationSensor, same as exit-radar) ----------

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
    if (changed && !this._scanning) this._recompute();
  },

  // ---------- direction math (same as exit-radar) ----------

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _turnHint(rel) {
    var a = Math.abs(rel);
    if (a <= 15) return 'you face it now';
    if (a <= 67.5) return rel > 0 ? 'turn right a bit' : 'turn left a bit';
    if (a <= 112.5) return rel > 0 ? 'turn right' : 'turn left';
    if (a <= 157.5) return rel > 0 ? 'turn around right' : 'turn around left';
    return 'turn around';
  },

  // Relative angle of a stored direction vs the current heading, -180..180 (+ = right).
  _relOf(deg) {
    return ((deg - this._heading + 540) % 360) - 180;
  },

  // ---------- buckets ----------

  _resetBuckets() {
    var b = [];
    for (var i = 0; i !== 72; i++) b.push(-1);
    this._buckets = b;
  },

  _covered() {
    if (!this._buckets) return 0;
    var n = 0;
    for (var i = 0; i !== 72; i++) if (this._buckets[i] >= 0) n++;
    return n;
  },

  _bucketSample(headingDeg, level) {
    if (!this._buckets) this._resetBuckets();
    var idx = Math.floor(((headingDeg % 360) + 360) % 360 / 5) % 72;
    if (level > this._buckets[idx]) this._buckets[idx] = level;
  },

  // Highest-level bucket wins; ties go to the first found.
  _peakPick() {
    if (!this._buckets) return null;
    var best = -1, bestLvl = -1;
    for (var i = 0; i !== 72; i++) {
      if (this._buckets[i] > bestLvl) { bestLvl = this._buckets[i]; best = i; }
    }
    if (best < 0) return null;
    return { deg: best * 5 + 2, level: bestLvl };
  },

  _top3() {
    if (!this._buckets) return [];
    var items = [];
    for (var i = 0; i !== 72; i++) {
      if (this._buckets[i] >= 0) items.push({ deg: i * 5 + 2, level: this._buckets[i] });
    }
    items.sort(function (a, b) { return b.level - a.level; });
    return items.slice(0, 3);
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  // ---------- SCAN (real mic turn-scan) ----------

  async scanTap() {
    if (this._scanning || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: scan already running - tap STOP' });
      return;
    }
    if (this.data.busy) return;
    // Honest refusal: a turn-scan is meaningless without a heading.
    if (!this._demo && (this._heading === null || this._headingSrc === 'NONE')) {
      this.setData({
        status: 'SCAN FAIL: need heading - sensor n/a here',
        lastEvent: 'EVT: SCAN refused - turn-scan requires the orientation sensor'
      });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'SCAN FAIL: mic n/a on this host',
        lastEvent: 'EVT: SCAN FAIL - mediaDevices n/a'
      });
      return;
    }
    if (typeof AudioContext === 'undefined') {
      this.setData({
        status: 'SCAN FAIL: Web Audio n/a on this host',
        lastEvent: 'EVT: SCAN FAIL - AudioContext n/a'
      });
      return;
    }
    this.setData({ busy: true, status: 'SCAN: opening mic (omnidirectional)...' });
    var stream = null;
    var actx = null;
    try {
      try {
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'omnidirectional' }
        }), 9000, 'mic');
      } catch (eMode) {
        // media.md: not every device supports every mode - fall back to
        // the default microphone and say so, do not fake the mode.
        if (!eMode || eMode.name !== 'OverconstrainedError') throw eMode;
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 9000, 'mic');
        this.setData({ lastEvent: 'EVT: omnidirectional n/a - default mic used' });
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
      this._resetBuckets();
      this._peak = null;
      this._lastSpeak = null;
      this._scanning = true;
      this._scanLeft = 20;
      var self = this;
      this._scanTimer = setInterval(function () { self._sampleTick(); }, 100);
      this.setData({
        busy: false,
        status: 'SCANNING: turn slowly - 20s, full circle',
        lastEvent: 'EVT: scan started - keep turning slowly'
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
        status: 'SCAN FAIL: ' + this._err(e),
        lastEvent: 'EVT: SCAN FAIL - ' + this._err(e)
      });
    }
  },

  _sampleTick() {
    if (!this._scanning) return;
    this._scanLeft -= 0.1;
    var lvl = 0;
    if (this._analyser && this._buf) {
      this._analyser.getFloatTimeDomainData(this._buf);
      var sum = 0;
      for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
      var rms = Math.sqrt(sum / this._buf.length);
      lvl = Math.min(1, rms * 3);
    }
    this._curLevel = lvl;
    if (this._heading !== null) this._bucketSample(this._heading, lvl);
    if (this._scanLeft <= 0) {
      this._finishScan('20s up');
      return;
    }
    this._recompute();
  },

  stopTap() {
    if (this._demoTimer) {
      this._stopDemo();
      this.setData({
        status: 'DEMO stopped - tap DEMO to run it fully',
        lastEvent: 'EVT: demo sweep stopped early'
      });
      this._recompute();
      return;
    }
    if (!this._scanning) {
      this.setData({ lastEvent: 'EVT: nothing scanning - SCAN or DEMO first' });
      return;
    }
    this._finishScan('stopped by you');
  },

  // Stops mic/context/timers; silent=true on hide/unload (no result UI).
  _stopScan(silent) {
    if (this._scanTimer) { clearInterval(this._scanTimer); this._scanTimer = null; }
    this._scanning = false;
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
    if (!silent) this._curLevel = 0;
  },

  _finishScan(why) {
    this._stopScan(false);
    var covered = this._covered();
    this._peak = this._peakPick();
    if (!this._peak) {
      this.setData({
        status: 'SCAN DONE: no samples - turn while scanning',
        lastEvent: 'EVT: scan finished (' + why + ') - nothing captured'
      });
      this._recompute();
      return;
    }
    this.setData({
      status: 'SCAN DONE (' + why + ') - peak from ' + covered + ' buckets',
      lastEvent: 'EVT: loudest bucket ' + this._peak.deg + ' deg - turn back to it'
    });
    this._recompute();
  },

  // ---------- DEMO (synthetic sweep, peak at 140 deg) ----------

  // DEMO synthesizes a full turn: heading sweeps 0..355 while a fake
  // level profile (gaussian peak at 140 deg + noise floor) fills the
  // buckets, then the normal RESULT path runs - no mic, no sensor.
  demoTap() {
    if (this._scanning || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: busy - tap STOP first' });
      return;
    }
    this._demo = true;
    this._headingSrc = 'DEMO';
    this._resetBuckets();
    this._peak = null;
    this._lastSpeak = null;
    this._demoStep = 0;
    this._heading = 0;
    this.setData({
      status: 'DEMO SCAN: synthetic sweep - peak built at 140',
      lastEvent: 'EVT: DEMO on - fake levels, no mic used'
    });
    var self = this;
    this._demoTimer = setInterval(function () { self._demoTick(); }, 90);
    this._recompute();
  },

  _demoLevel(deg) {
    var d = Math.abs(((deg - 140 + 540) % 360) - 180); // angular distance to 140
    var g = Math.exp(-(d * d) / (2 * 22 * 22));
    var noise = 0.02 + 0.015 * (0.5 + 0.5 * Math.sin(deg * 1.7));
    return Math.min(1, 0.08 + 0.85 * g + noise);
  },

  _demoTick() {
    var deg = this._demoStep * 5;
    if (deg > 355) {
      this._stopDemo();
      this._heading = 0; // end facing 0 so the peak sits RIGHT-BACK 140
      this._finishScan('demo sweep done');
      return;
    }
    this._heading = deg;
    this._curLevel = this._demoLevel(deg);
    this._bucketSample(deg, this._curLevel);
    this._demoStep++;
    this._recompute();
  },

  _stopDemo() {
    if (this._demoTimer) { clearInterval(this._demoTimer); this._demoTimer = null; }
  },

  clearTap() {
    if (this._scanning || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: stop the scan before CLEAR' });
      return;
    }
    this._buckets = null;
    this._peak = null;
    this._lastSpeak = null;
    this._curLevel = 0;
    this.setData({
      status: 'Cleared - SCAN or DEMO to scan again',
      lastEvent: 'EVT: buckets + result cleared'
    });
    this._recompute();
  },

  // ---------- render ----------

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : '')
    };
    var covered = this._covered();
    patch.levelLine = 'LVL: ' + this._levelBar(this._curLevel) + ' ' +
      Math.round(this._curLevel * 100) + ' · covered ' + covered + '/72';
    if (this._scanning) {
      patch.scanLine = 'SCAN: ' + Math.max(0, Math.ceil(this._scanLeft)) +
        's left - keep turning slowly';
    } else if (this._demoTimer) {
      patch.scanLine = 'SCAN: DEMO sweep ' + covered + '/72 buckets...';
    } else if (this._peak) {
      patch.scanLine = 'SCAN: done · peak from ' + covered + ' buckets';
    } else {
      patch.scanLine = 'SCAN: idle - no scan yet';
    }

    if (!this._peak) {
      patch.arrow = '·';
      patch.relLine = (this._scanning || this._demoTimer)
        ? 'RESULT: scanning - loudest direction comes at the end'
        : 'RESULT: scan first - SCAN or DEMO';
      patch.relCls = 'rel';
      patch.topLine = 'TOP: ---';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    var top = this._top3();
    patch.topLine = 'TOP: ' + top.map(function (t) {
      return t.deg + '° ' + Math.round(t.level * 100);
    }).join(' · ');
    if (this._heading === null) {
      patch.arrow = '·';
      patch.relLine = 'LOUDEST was ' + this._peak.deg + '° - heading n/a now';
      patch.relCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    var rel = this._relOf(this._peak.deg);
    var rel360 = (this._peak.deg - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    if (Math.abs(rel) <= 15) {
      patch.relLine = 'LOUDEST: AHEAD ' + deg + '° - you face it';
      patch.relCls = 'rel rel-on';
    } else {
      patch.relLine = 'LOUDEST: ' + dir.en + ' ' + deg + '° — ' + this._turnHint(rel);
      patch.relCls = 'rel';
    }
    this._lastSpeak = { zh: dir.zh, deg: deg, ahead: Math.abs(rel) <= 15 };
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
        text = '还没有扫描结果。先点扫描，慢慢转一圈。';
      } else if (s.ahead) {
        text = '刚才最响的声音就在你正前方。';
      } else {
        text = '刚才最响的方向在你' + s.zh + '，大约' + s.deg + '度。';
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
      <text class="title">SOUND COMPASS</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="scan-box">
      <text class="scan">{{scanLine}}</text>
      <text class="level">{{levelLine}}</text>
      <text class="note">{{noteLine}}</text>
    </view>
    <view class="result-box">
      <view class="result-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{relCls}}">{{relLine}}</text>
      </view>
      <text class="top">{{topLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="scanTap">SCAN</button>
      <button class="btn" bindtap="stopTap">STOP</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
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
.scan-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.scan {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.level {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.note {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.result-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 4px;
  margin-bottom: 4px;
}
.result-top {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.arrow {
  color: #40ff5e;
  font-size: 28px;
  line-height: 31px;
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
.top {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
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
