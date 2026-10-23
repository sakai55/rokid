<script def>
{
  "navigationBarTitleText": "Exit Radar"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'MARK: look at an exit sign, tap MARK',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: MARK · LABEL: 安全出口',
    countLine: 'EXITS: 0/6 · stored on this device only',
    photoLine: 'PHOTO: record only - no photo yet',
    rows: [
      { text: '(no exits) - MARK one here, or DEMO' }
    ],
    arrow: '·',
    relLine: 'GUIDE: tap GUIDE for the nearest exit',
    relCls: 'rel',
    nearLine: 'NEAREST: ---',
    lastEvent: 'EVT: real emergency: follow building signs + alarms first',
    busy: false
  },

  onLoad() {
    this._mode = 'MARK';
    this._labelIdx = 0;
    this._records = this._loadRecords();
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
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
    this._saveRecords();
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
    if (this._mode === 'MARK') {
      if (this._steady) this.markTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to MARK' });
    } else {
      this.speakTap();
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      if (this._mode === 'MARK') this.labelTap();
      else this.setData({ lastEvent: 'EVT: GUIDE follows your heading - turn your head' });
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'MARK') this.markTap(); else this.speakTap();
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

  _nowTime() {
    var d = new Date();
    var hh = d.getHours(); if (hh < 10) hh = '0' + hh;
    var mm = d.getMinutes(); if (mm < 10) mm = '0' + mm;
    return hh + ':' + mm;
  },

  // ---------- labels ----------

  _labels() { return ['安全出口', '楼梯间', '消防通道', '大堂方向']; },
  _label() { return this._labels()[this._labelIdx || 0]; },

  labelTap() {
    if (this._mode !== 'MARK') {
      this.setData({ lastEvent: 'EVT: LABEL only applies in MARK mode' });
      return;
    }
    this._labelIdx = ((this._labelIdx || 0) + 1) % this._labels().length;
    this.setData({ lastEvent: 'EVT: label -> ' + this._label() });
    this._recompute();
  },

  // ---------- persistence (wx sync storage, key 'exitRadar', max 6) ----------

  _loadRecords() {
    try {
      var raw = wx.getStorageSync('exitRadar');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 6; i++) {
        var r = raw[i];
        if (r && typeof r.label === 'string' && isFinite(r.heading) && typeof r.time === 'string') {
          out.push({
            label: String(r.label).slice(0, 8),
            heading: ((Math.round(r.heading) % 360) + 360) % 360,
            time: String(r.time).slice(0, 5),
            demo: !!r.demo
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveRecords() {
    try {
      wx.setStorageSync('exitRadar', this._records || []);
    } catch (e) { /* storage unavailable on this host: records stay in memory */ }
  },

  // Beyond 6 records the oldest is dropped.
  _addRecord(rec) {
    var arr = this._records || [];
    arr.push(rec);
    while (arr.length > 6) arr.shift();
    this._records = arr;
    this._saveRecords();
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

  // ---------- modes ----------

  modeTap() {
    this._mode = this._mode === 'MARK' ? 'GUIDE' : 'MARK';
    this.setData({
      status: this._mode === 'MARK'
        ? 'MARK: look at an exit sign, tap MARK'
        : 'GUIDE: nearest exit vs your heading',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  guideTap() {
    if (this._mode !== 'GUIDE') {
      this._mode = 'GUIDE';
      this.setData({
        status: 'GUIDE: nearest exit vs your heading',
        lastEvent: 'EVT: mode -> GUIDE'
      });
    } else {
      this.setData({ lastEvent: 'EVT: GUIDE refreshed - turn your head' });
    }
    this._recompute();
  },

  // ---------- MARK ----------

  markTap() {
    if (this._mode !== 'MARK') {
      this.setData({ lastEvent: 'EVT: MARK only applies in MARK mode (MODE toggles)' });
      return;
    }
    if (this._heading === null) {
      // Same honesty rule as find-my-thing: never invent a heading.
      this.setData({
        status: 'MARK FAIL: no heading - DEMO or wait for sensor',
        lastEvent: 'EVT: MARK refused - never invent a heading'
      });
      return;
    }
    var rec = {
      label: this._label(),
      heading: Math.round(this._heading),
      time: this._nowTime(),
      demo: !!this._demo
    };
    this._addRecord(rec);
    this.setData({
      status: 'MARKED: ' + rec.label + ' · ' + rec.heading + '° · ' + rec.time,
      lastEvent: 'EVT: exit registered ' + rec.label + ' at heading ' + rec.heading +
        ' deg' + (rec.demo ? ' (DEMO heading)' : '')
    });
    this._recompute();
  },

  clearTap() {
    this._records = [];
    this._saveRecords();
    this.setData({
      status: this._mode === 'MARK'
        ? 'MARK: look at an exit sign, tap MARK'
        : 'GUIDE: no exits - MARK some first',
      photoLine: 'PHOTO: record only - no photo yet',
      lastEvent: 'EVT: all exits cleared'
    });
    this._recompute();
  },

  // ---------- PHOTO (telephoto record of the sign, no recognition) ----------

  _stopStream() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  async photoTap() {
    if (this.data.busy) return;
    if (this._mode !== 'MARK') {
      this.setData({ lastEvent: 'EVT: PHOTO is for MARK - look at the sign, record it' });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a here, no photo taken',
        lastEvent: 'EVT: photo FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, photoLine: 'PHOTO: capturing sign (telephoto)...' });
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
        photoLine: 'PHOTO: ' + bytes + 'B · telephoto · record only',
        lastEvent: 'EVT: sign photo recorded ' + bytes + 'B (visual record only, no reading)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) { this._stopStream(); stream = null; }
      // Fallback: wx camera context, like gaze-translate / parking-return.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B · record only',
          lastEvent: 'EVT: sign wx photo recorded ' + size + 'B (visual record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ', no photo taken',
          lastEvent: 'EVT: photo FAIL - ' + this._err(firstErr)
        });
      }
    } finally {
      if (stream) this._stopStream();
      this.setData({ busy: false });
    }
  },

  // ---------- DEMO ----------

  // DEMO registers 3 labeled exits at 40 / 170 / 300 deg and switches to
  // GUIDE; further taps step the simulated heading +45 deg, so the
  // nearest exit changes - at heading 45 the 40 deg exit is 5 deg off
  // and the EXIT AHEAD state lights up.
  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      // Re-entering DEMO replaces older demo records instead of piling up.
      this._records = (this._records || []).filter(function (r) { return !r.demo; });
      var t = this._nowTime();
      this._addRecord({ label: '安全出口', heading: 40, time: t, demo: true });
      this._addRecord({ label: '楼梯间', heading: 170, time: t, demo: true });
      this._addRecord({ label: '消防通道', heading: 300, time: t, demo: true });
      this._mode = 'GUIDE';
      this.setData({
        status: 'DEMO GUIDE: 3 exits in (DEMO steps +45)',
        lastEvent: 'EVT: DEMO on - exits at 40/170/300 deg, mode GUIDE'
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

  // ---------- guidance math (same as head-nav / find-my-thing) ----------

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  // Angularly nearest registered exit vs the current heading.
  _nearest() {
    var recs = this._records || [];
    if (!recs.length || this._heading === null) return null;
    var best = null;
    for (var i = 0; i !== recs.length; i++) {
      var rel = ((recs[i].heading - this._heading + 540) % 360) - 180; // -180..180, + = right
      if (!best || Math.abs(rel) < Math.abs(best.rel)) best = { rec: recs[i], rel: rel };
    }
    return best;
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · LABEL: ' + this._label()
    };
    var recs = this._records || [];
    if (!recs.length) {
      patch.rows = [{ text: '(no exits) - MARK one here, or DEMO' }];
    } else {
      patch.rows = recs.map(function (r) {
        return { text: r.label + ' · ' + r.heading + '° · ' + r.time + (r.demo ? ' DEMO' : '') };
      });
    }
    patch.countLine = 'EXITS: ' + recs.length + '/6 · stored on this device only';

    if (this._mode === 'MARK') {
      patch.arrow = '·';
      patch.relLine = recs.length
        ? 'GUIDE: tap GUIDE for the nearest exit'
        : 'GUIDE: no exits yet - MARK first';
      patch.relCls = 'rel';
      patch.nearLine = 'NEAREST: ---';
      // In MARK the SPEAK button reads the nearest exit too, so
      // compute the speak payload here as well.
      var nb = this._nearest();
      this._lastSpeak = nb ? {
        kind: 'guide', label: nb.rec.label, zh: this._dirName(nb.rel).zh,
        deg: Math.round(Math.abs(nb.rel)), ahead: Math.abs(nb.rel) <= 15
      } : null;
      this.setData(patch);
      return;
    }
    // GUIDE mode
    if (!recs.length) {
      patch.arrow = '·';
      patch.relLine = 'GUIDE: no exits - MARK some first';
      patch.relCls = 'rel';
      patch.nearLine = 'NEAREST: ---';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    if (this._heading === null) {
      patch.arrow = '·';
      patch.relLine = 'GUIDE: heading n/a - SRC NONE, tap DEMO';
      patch.relCls = 'rel';
      patch.nearLine = 'NEAREST: ---';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    var b = this._nearest();
    var rel = b.rel;
    var rel360 = (b.rec.heading - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    var ahead = Math.abs(rel) <= 15;
    if (ahead) {
      patch.relLine = 'EXIT AHEAD — look for the green sign';
      patch.relCls = 'rel rel-on';
    } else {
      patch.relLine = 'NEAREST EXIT: ' + dir.en + ' ' + deg + '° — ' + b.rec.label;
      patch.relCls = 'rel';
    }
    patch.nearLine = 'NEAREST: ' + b.rec.label + ' · reg ' + b.rec.heading + '° · ' +
      b.rec.time + (b.rec.demo ? ' · DEMO' : '');
    this._lastSpeak = { kind: 'guide', label: b.rec.label, zh: dir.zh, deg: deg, ahead: ahead };
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
        text = '还没有登记出口。先慢慢环视一周，看着出口标志点登记。';
      } else if (s.ahead) {
        text = '最近的出口就在你正前方，是' + s.label + '。往前走，找绿色标志。';
      } else {
        text = '最近的出口在你' + s.zh + ' ' + s.deg + '度，是' + s.label + '。转身找绿色标志。';
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
      <text class="title">EXIT RADAR</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="mark-box">
      <text class="mark-mode">{{modeLine}}</text>
      <text class="count">{{countLine}}</text>
      <text class="photo">{{photoLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="guide-box">
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{relCls}}">{{relLine}}</text>
      </view>
      <text class="near">{{nearLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="labelTap">LABEL</button>
      <button class="btn btn-main" bindtap="markTap">MARK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="photoTap">PHOTO</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="guideTap">GUIDE</button>
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
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
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
.near {
  color: rgba(64,255,94,0.72);
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
