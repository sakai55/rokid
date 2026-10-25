<script def>
{
  "navigationBarTitleText": "Garden Hands"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'REGISTER: look at a bed, BED picks name, REG saves',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: REGISTER',
    selLine: 'BED: 番茄畦 · 每 2 天浇 · ACT: 浇水',
    rows: [
      { text: '(no beds) - REG one here, or DEMO' }
    ],
    countLine: 'BEDS: 0/5 · stored on this device only',
    arrow: '·',
    faceLine: 'FACING: register beds first',
    faceCls: 'rel',
    dueLine: 'DUE: ---',
    photoLine: 'PHOTO: record only - app does NOT store it',
    lastEvent: 'EVT: nod when steady = REG (REGISTER) / LOG',
    busy: false
  },

  onLoad() {
    this._mode = 'REGISTER'; // REGISTER | DUE | FIND
    this._bedIdx = 0;        // index into built-in bed table (REGISTER)
    this._selIdx = 0;        // index into registered beds (LOG target)
    this._actIdx = 0;
    this._beds = this._loadBeds();
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
    this._sensor = null;
    this._timer = null;
    this._steady = false;
    this._stream = null;
    this._dueSpeak = null;
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
    this._saveBeds();
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
    if (g !== 'nod' || this.data.busy) return;
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Gloved hands: a steady nod does the mode's main action.
    if (this._mode === 'REGISTER') this.regTap();
    else this.logTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.bedTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'REGISTER') this.regTap(); else this.logTap();
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

  // ---------- vocab ----------

  // Built-in beds and their watering interval in days.
  _bedTable() {
    return [
      { name: '番茄畦', interval: 2 },
      { name: '黄瓜架', interval: 2 },
      { name: '香草盆', interval: 1 },
      { name: '月季丛', interval: 3 },
      { name: '草莓畦', interval: 2 }
    ];
  },
  _acts() { return ['浇水', '施肥', '修剪', '除虫']; },
  _bedDef() { return this._bedTable()[this._bedIdx || 0]; },
  _act() { return this._acts()[this._actIdx || 0]; },

  _today() {
    var d = new Date();
    var m = d.getMonth() + 1; if (m < 10) m = '0' + m;
    var day = d.getDate(); if (day < 10) day = '0' + day;
    return d.getFullYear() + '-' + m + '-' + day;
  },

  _daysAgoStr(n) {
    var d = new Date();
    d.setDate(d.getDate() - n);
    var m = d.getMonth() + 1; if (m < 10) m = '0' + m;
    var day = d.getDate(); if (day < 10) day = '0' + day;
    return d.getFullYear() + '-' + m + '-' + day;
  },

  // Whole days from a 'YYYY-MM-DD' string to today (local dates).
  _daysSince(ds) {
    if (!ds) return null;
    var p = String(ds).split('-');
    if (p.length !== 3) return null;
    var then = new Date(+p[0], +p[1] - 1, +p[2]);
    var n = new Date();
    var today = new Date(n.getFullYear(), n.getMonth(), n.getDate());
    return Math.round((today - then) / 86400000);
  },

  // ---------- persistence (wx sync storage, key 'gardenBeds') ----------

  _loadBeds() {
    try {
      var raw = wx.getStorageSync('gardenBeds');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 5; i++) {
        var r = raw[i];
        if (r && typeof r.bed === 'string' && isFinite(r.heading) && isFinite(r.interval)) {
          out.push({
            bed: String(r.bed).slice(0, 8),
            heading: ((Math.round(r.heading) % 360) + 360) % 360,
            interval: Math.max(1, Math.round(r.interval)),
            lastWatered: typeof r.lastWatered === 'string' ? r.lastWatered : null,
            lastAct: typeof r.lastAct === 'string' ? r.lastAct.slice(0, 4) : null,
            lastActDate: typeof r.lastActDate === 'string' ? r.lastActDate : null,
            demo: !!r.demo
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveBeds() {
    try {
      wx.setStorageSync('gardenBeds', this._beds || []);
    } catch (e) { /* storage unavailable on this host: beds stay in memory */ }
  },

  // Re-registering a bed replaces its heading/interval but keeps its
  // watering history; beyond 5 beds the oldest registration is dropped.
  _addBed(rec) {
    var old = null;
    var arr = (this._beds || []).filter(function (b) {
      if (b.bed === rec.bed) { old = b; return false; }
      return true;
    });
    if (old) {
      rec.lastWatered = old.lastWatered;
      rec.lastAct = old.lastAct;
      rec.lastActDate = old.lastActDate;
    }
    arr.push(rec);
    while (arr.length > 5) arr.shift();
    this._beds = arr;
    this._saveBeds();
  },

  _selBed() {
    var beds = this._beds || [];
    if (!beds.length) return null;
    var idx = this._selIdx || 0;
    if (idx >= beds.length) idx = 0;
    return beds[idx];
  },

  // ---------- heading (AbsoluteOrientationSensor, same as DI07/DI10) ----------

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

  _stopStream() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  // ---------- mode + selection ----------

  modeTap() {
    var modes = ['REGISTER', 'DUE', 'FIND'];
    var i = modes.indexOf(this._mode);
    this._mode = modes[(i + 1) % modes.length];
    this.setData({
      status: this._mode === 'REGISTER'
        ? 'REGISTER: look at a bed, BED picks name, REG saves'
        : this._mode === 'DUE'
          ? 'DUE: most overdue bed first - LOG when done'
          : 'FIND: turn your head - nearest bed lights up',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  bedTap() {
    if (this._mode === 'REGISTER') {
      this._bedIdx = ((this._bedIdx || 0) + 1) % this._bedTable().length;
      this.setData({ lastEvent: 'EVT: bed -> ' + this._bedDef().name });
    } else {
      var n = (this._beds || []).length;
      if (!n) {
        this.setData({ lastEvent: 'EVT: no beds yet - REGISTER first or DEMO' });
        return;
      }
      this._selIdx = ((this._selIdx || 0) + 1) % n;
      this.setData({ lastEvent: 'EVT: selected -> ' + this._beds[this._selIdx].bed });
    }
    this._recompute();
  },

  actTap() {
    this._actIdx = ((this._actIdx || 0) + 1) % this._acts().length;
    this.setData({ lastEvent: 'EVT: action -> ' + this._act() });
    this._recompute();
  },

  // ---------- register ----------

  regTap() {
    if (this._mode !== 'REGISTER') {
      this.setData({ lastEvent: 'EVT: REG only applies in REGISTER mode' });
      return;
    }
    if (this._heading === null) {
      this.setData({
        status: 'REG FAIL: no heading (SRC NONE) - DEMO or wait for sensor',
        lastEvent: 'EVT: REG refused - never invent a heading'
      });
      return;
    }
    var def = this._bedDef();
    var rec = {
      bed: def.name,
      heading: Math.round(this._heading),
      interval: def.interval,
      lastWatered: null,
      lastAct: null,
      lastActDate: null,
      demo: !!this._demo
    };
    this._addBed(rec);
    // Select the just-registered bed so LOG can target it right away.
    for (var i = 0; i !== this._beds.length; i++) {
      if (this._beds[i].bed === rec.bed) this._selIdx = i;
    }
    this.setData({
      status: 'REGISTERED: ' + rec.bed + ' · ' + rec.heading + '° · 每 ' + rec.interval + ' 天浇',
      lastEvent: 'EVT: registered ' + rec.bed + ' at heading ' + rec.heading +
        ' deg' + (rec.demo ? ' (DEMO heading)' : '')
    });
    this._recompute();
  },

  // ---------- log an action ----------

  logTap() {
    var bed = this._selBed();
    if (!bed) {
      this.setData({
        status: 'LOG FAIL: no bed registered yet',
        lastEvent: 'EVT: LOG refused - register a bed first'
      });
      return;
    }
    var act = this._act();
    var today = this._today();
    bed.lastAct = act;
    bed.lastActDate = today;
    if (act === '浇水') bed.lastWatered = today;
    this._saveBeds();
    this.setData({
      status: 'LOGGED: ' + bed.bed + ' · ' + act + ' · ' + today,
      lastEvent: 'EVT: logged ' + act + ' for ' + bed.bed + ' (' + today + ')' +
        (act === '浇水' ? ' - watering clock reset' : '')
    });
    this._recompute();
  },

  clearTap() {
    this._beds = [];
    this._selIdx = 0;
    this._saveBeds();
    this.setData({
      status: 'REGISTER: look at a bed, BED picks name, REG saves',
      lastEvent: 'EVT: all beds cleared'
    });
    this._recompute();
  },

  // ---------- demo ----------

  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      // lastWatered computed from Date at runtime, so DUE math is real:
      // tomato 3d ago (interval 2 -> due), cucumber 1d ago (ok),
      // strawberry 5d ago (interval 2 -> most overdue).
      var demo = [
        { bed: '番茄畦', heading: 30, interval: 2, lastWatered: this._daysAgoStr(3), lastAct: '浇水', lastActDate: this._daysAgoStr(3), demo: true },
        { bed: '黄瓜架', heading: 150, interval: 2, lastWatered: this._daysAgoStr(1), lastAct: '浇水', lastActDate: this._daysAgoStr(1), demo: true },
        { bed: '草莓畦', heading: 270, interval: 2, lastWatered: this._daysAgoStr(5), lastAct: '浇水', lastActDate: this._daysAgoStr(5), demo: true }
      ];
      for (var i = 0; i !== demo.length; i++) this._addBed(demo[i]);
      this._selIdx = 0;
      this._mode = 'DUE';
      this.setData({
        status: 'DEMO: 3 beds (30/150/270°) - DUE view, DEMO steps +45',
        lastEvent: 'EVT: DEMO on - 3 beds registered, mode DUE'
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

  // ---------- photo (growth record, moment only) ----------

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a here',
        status: 'LOOK FAIL - no camera on this host',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default mode) - aim at the bed...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var photoBytes = 0;
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B moment record - app does NOT store it',
        status: 'PHOTO TAKEN - a moment record only, not saved',
        lastEvent: 'EVT: bed photo ' + photoBytes + 'B (record only, not stored)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like the sibling agents.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B moment record - not stored',
          status: 'PHOTO TAKEN - a moment record only, not saved',
          lastEvent: 'EVT: wx bed photo ' + size + 'B (record only, not stored)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr),
          status: 'LOOK FAIL - no photo taken',
          lastEvent: 'EVT: LOOK FAIL'
        });
      }
    } finally {
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
  },

  // ---------- due computation ----------

  // Returns beds annotated with days-since + overdue amount, sorted:
  // never-watered first, then most overdue first.
  _dueList() {
    var self = this;
    var list = (this._beds || []).map(function (b) {
      var days = self._daysSince(b.lastWatered);
      var overdue = days === null ? 999 : days - b.interval;
      return { bed: b, days: days, overdue: overdue, due: days === null || days >= b.interval };
    });
    list.sort(function (a, b2) { return b2.overdue - a.overdue; });
    return list;
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var sel = this._selBed();
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode
    };
    if (this._mode === 'REGISTER') {
      var def = this._bedDef();
      patch.selLine = 'BED: ' + def.name + ' · 每 ' + def.interval + ' 天浇 · ACT: ' + this._act();
    } else if (sel) {
      patch.selLine = 'BED: ' + sel.bed + ' · 每 ' + sel.interval + ' 天浇 · ACT: ' + this._act();
    } else {
      patch.selLine = 'BED: (none) · ACT: ' + this._act();
    }

    var beds = this._beds || [];
    var due = this._dueList();
    if (!beds.length) {
      patch.rows = [{ text: '(no beds) - REG one here, or DEMO' }];
    } else if (this._mode === 'DUE') {
      patch.rows = due.map(function (d) {
        var when = d.days === null ? '从没浇过' : d.days + ' 天没浇';
        return { text: (d.due ? '! DUE ' : '  ok  ') + d.bed.bed + ' · ' + when + ' · 每 ' + d.bed.interval + ' 天' + (d.bed.demo ? ' DEMO' : '') };
      });
    } else {
      patch.rows = beds.map(function (b) {
        var when = b.lastWatered ? b.lastWatered.slice(5) : '从没浇过';
        var act = b.lastAct ? ' · ' + b.lastAct + ' ' + (b.lastActDate || '').slice(5) : '';
        return { text: b.bed + ' · ' + b.heading + '° · 浇 ' + when + act + (b.demo ? ' DEMO' : '') };
      });
    }
    patch.countLine = 'BEDS: ' + beds.length + '/5 · stored on this device only';

    // DUE summary line + speak text
    var dueOnes = due.filter(function (d) { return d.due; });
    if (!beds.length) {
      patch.dueLine = 'DUE: ---';
      this._dueSpeak = null;
    } else if (!dueOnes.length) {
      patch.dueLine = 'DUE: all beds watered - nothing due';
      this._dueSpeak = '所有苗床都不缺水，今天不用浇。';
    } else {
      var first = dueOnes[0];
      patch.dueLine = first.days === null
        ? 'DUE: ' + first.bed.bed + ' 还没浇过水，今天该浇'
        : 'DUE: ' + first.bed.bed + ' ' + first.days + ' 天没浇，今天该浇' +
          (dueOnes.length > 1 ? '（共 ' + dueOnes.length + ' 块到期）' : '');
      this._dueSpeak = dueOnes.map(function (d) {
        return d.days === null
          ? d.bed.bed + '还没浇过水，今天该浇。'
          : d.bed.bed + d.days + '天没浇了，今天该浇。';
      }).join('');
    }

    // FIND: angularly nearest registered bed to the current heading
    if (!beds.length || this._heading === null) {
      patch.arrow = '·';
      patch.faceLine = beds.length ? 'FACING: heading n/a - SRC NONE, tap DEMO' : 'FACING: register beds first';
      patch.faceCls = 'rel';
      this.setData(patch);
      return;
    }
    var best = null;
    for (var i = 0; i !== beds.length; i++) {
      var rel = ((beds[i].heading - this._heading + 540) % 360) - 180;
      if (best === null || Math.abs(rel) < Math.abs(best.rel)) best = { bed: beds[i], rel: rel };
    }
    var rel360 = (best.bed.heading - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var deg = Math.round(Math.abs(best.rel));
    if (Math.abs(best.rel) <= 15) {
      var dInfo = null;
      for (var j = 0; j !== due.length; j++) if (due[j].bed === best.bed) dInfo = due[j];
      patch.faceLine = 'FACING ' + best.bed.bed +
        (dInfo && dInfo.due ? ' - DUE, water it' : ' - check it over');
      patch.faceCls = 'rel rel-on';
    } else {
      patch.faceLine = 'NEAREST: ' + best.bed.bed + ' · ' + this._dirName(best.rel).en + ' ' + deg + '°';
      patch.faceCls = 'rel';
    }
    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text = this._dueSpeak || '还没有登记苗床。先看着一块畦登记，或者点演示。';
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
      <text class="title">GARDEN HANDS</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="sel-box">
      <text class="sel-mode">{{modeLine}} · {{selLine}}</text>
      <text class="due">{{dueLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <text class="count">{{countLine}}</text>
    <view class="guide-box">
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{faceCls}}">{{faceLine}}</text>
      </view>
      <text class="photo">{{photoLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="bedTap">BED</button>
      <button class="btn" bindtap="actTap">ACT</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="regTap">REG</button>
      <button class="btn" bindtap="logTap">LOG</button>
      <button class="btn" bindtap="lookTap">LOOK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
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
.sel-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 10px;
  margin-bottom: 5px;
}
.sel-mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.due {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
}
.list {
  height: 30px;
  margin-bottom: 2px;
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
.count {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-bottom: 4px;
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
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
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
