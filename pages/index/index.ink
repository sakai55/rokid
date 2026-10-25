<script def>
{
  "navigationBarTitleText": "Market Radar"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'REG: face a stall, set CAT + NOTE, tap REG',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: REG · CAT: 蔬菜',
    noteLine: 'NOTE: none yet - tap NOTE, say the price',
    countLine: 'STALLS: 0/8 · stored on this device only',
    rows: [
      { text: '(no stalls) - REG one here, or DEMO' }
    ],
    arrow: '·',
    faceLine: 'RADAR: REG first, then MODE to RADAR',
    faceCls: 'face',
    faceLineDetail: 'FACING: ---',
    lastEvent: 'EVT: headings fit where you stood - re-check near the spot',
    busy: false
  },

  onLoad() {
    this._mode = 'REG';
    this._catIdx = 0;
    this._records = this._loadRecords();
    this._pendingNote = '';
    this._presetIdx = -1;
    this._noteRec = null;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
    this._sensor = null;
    this._timer = null;
    this._steady = false;
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
    this._stopNoteRec();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopNoteRec();
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
    if (this._mode === 'REG') {
      if (this._steady) this.regTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to REG' });
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
      if (this._mode === 'REG') this.catTap();
      else this.setData({ lastEvent: 'EVT: RADAR follows your heading - turn your head' });
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'REG') this.regTap(); else this.speakTap();
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

  _cnNum(n) {
    var c = ['零', '一', '二', '三', '四', '五', '六', '七', '八'];
    return (n >= 0 && n <= 8) ? c[n] : String(n);
  },

  // ---------- categories ----------

  _cats() { return ['蔬菜', '水果', '肉类', '海鲜', '干货调料']; },
  _cat() { return this._cats()[this._catIdx || 0]; },

  catTap() {
    if (this._mode !== 'REG') {
      this.setData({ lastEvent: 'EVT: CAT only applies in REG mode' });
      return;
    }
    this._catIdx = ((this._catIdx || 0) + 1) % this._cats().length;
    this.setData({ lastEvent: 'EVT: cat -> ' + this._cat() });
    this._recompute();
  },

  // ---------- persistence (wx sync storage, key 'marketStalls', max 8) ----------

  _loadRecords() {
    try {
      var raw = wx.getStorageSync('marketStalls');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 8; i++) {
        var r = raw[i];
        if (r && typeof r.cat === 'string' && isFinite(r.heading) && typeof r.time === 'string') {
          out.push({
            cat: String(r.cat).slice(0, 4),
            note: typeof r.note === 'string' ? String(r.note).slice(0, 30) : '',
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
      wx.setStorageSync('marketStalls', this._records || []);
    } catch (e) { /* storage unavailable on this host: records stay in memory */ }
  },

  // Beyond 8 records the oldest is dropped. The same category may be
  // registered twice on purpose - comparing two stalls is the point.
  _addRecord(rec) {
    var arr = this._records || [];
    arr.push(rec);
    while (arr.length > 8) arr.shift();
    this._records = arr;
    this._saveRecords();
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

  // ---------- modes: REG -> RADAR -> LIST -> REG ----------

  modeTap() {
    this._mode = this._mode === 'REG' ? 'RADAR' : (this._mode === 'RADAR' ? 'LIST' : 'REG');
    this.setData({
      status: this._mode === 'REG'
        ? 'REG: face a stall, set CAT + NOTE, tap REG'
        : (this._mode === 'RADAR'
          ? 'RADAR: turn slowly - a faced stall lights up'
          : 'LIST: all stalls - SPEAK reads every note'),
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  listTap() {
    if (this._mode !== 'LIST') {
      this._mode = 'LIST';
      this.setData({
        status: 'LIST: all stalls - SPEAK reads every note',
        lastEvent: 'EVT: mode -> LIST'
      });
    } else {
      this.setData({ lastEvent: 'EVT: LIST refreshed - compare the notes' });
    }
    this._recompute();
  },

  // ---------- NOTE (one-shot ASR, verbatim; preset fallback) ----------

  _stopNoteRec() {
    if (this._noteRec) {
      try { this._noteRec.abort(); } catch (e) {}
      this._noteRec = null;
    }
  },

  _presets() { return ['便宜', '一般', '贵']; },

  noteTap() {
    if (this._mode !== 'REG') {
      this.setData({ lastEvent: 'EVT: NOTE only applies in REG mode' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. NOTE falls back to
      // cycling three preset tags instead of pretending to listen.
      this._presetIdx = ((this._presetIdx || 0) + 1) % this._presets().length;
      this._pendingNote = this._presets()[this._presetIdx];
      this.setData({
        noteLine: 'NOTE: "' + this._pendingNote + '" (preset - ASR SKIP here)',
        status: 'NOTE preset tag - ASR n/a on this host',
        lastEvent: 'EVT: NOTE preset -> ' + this._pendingNote + ' (honest SKIP, no ASR)'
      });
      this._recompute();
      return;
    }
    this._noteListen();
  },

  async _noteListen() {
    var self = this;
    this.setData({ busy: true, noteLine: 'NOTE: checking wearer mic mode...' });
    // Wearer-mode mic AVAILABILITY check (documented getUserMedia audio
    // constraints, same pattern as cook-along DI11): the stream only
    // verifies the wearer mode opens and reads back its settings, then
    // stops at once. Recognition itself runs on the host
    // SpeechRecognition with its OWN microphone - the checked wearer
    // mode does NOT denoise or otherwise shape the recognition audio.
    var micNote = 'MIC CHECK: wearer not run';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic');
        var settings = {};
        try {
          var tr = ms.getAudioTracks()[0];
          if (tr && tr.getSettings) settings = tr.getSettings();
        } catch (e) {}
        micNote = 'MIC CHECK: wearer OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        micNote = 'MIC CHECK: wearer FAIL - ' + this._err(e);
      }
    }
    try {
      this._stopNoteRec();
      var rec = new SpeechRecognition();
      this._noteRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // The note is stored VERBATIM. Prices and numbers are what
          // ASR gets wrong most, so the heard text stays on screen for
          // the wearer to eyeball BEFORE REG saves it; NOTE redoes it.
          self._pendingNote = txt;
          self.setData({
            noteLine: 'NOTE: "' + txt.slice(0, 22) + '" - check it, then REG',
            status: 'NOTE heard - eyeball the price, then REG',
            lastEvent: 'EVT: note heard (host ASR) - verify before REG; ' + micNote
          });
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          noteLine: 'NOTE: FAIL - ' + self._err(ev.error || ev) + ', tap NOTE again',
          status: 'NOTE FAIL - try again, closer and slower',
          lastEvent: 'EVT: NOTE ASR error'
        });
      };
      rec.onend = function () {
        if (self._noteRec === rec) self._noteRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        noteLine: 'NOTE: listening - say item + price...',
        status: 'NOTE listening (host ASR)',
        lastEvent: 'EVT: NOTE listening (host ASR); ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        noteLine: 'NOTE: FAIL - ' + this._err(e),
        status: 'NOTE FAIL - recogniser would not start',
        lastEvent: 'EVT: NOTE start failed'
      });
    }
  },

  // ---------- REG ----------

  regTap() {
    if (this._mode !== 'REG') {
      this.setData({ lastEvent: 'EVT: REG only applies in REG mode (MODE toggles)' });
      return;
    }
    if (this._heading === null) {
      // Same honesty rule as find-my-thing / exit-radar: never invent
      // a heading. A stall without a direction is a note, not a radar pin.
      this.setData({
        status: 'REG FAIL: no heading - DEMO or wait for sensor',
        lastEvent: 'EVT: REG refused - never invent a heading'
      });
      return;
    }
    var rec = {
      cat: this._cat(),
      note: this._pendingNote || '（未备注）',
      heading: Math.round(this._heading),
      time: this._nowTime(),
      demo: !!this._demo
    };
    this._addRecord(rec);
    this._pendingNote = '';
    this._presetIdx = -1;
    // After any registration the default view is RADAR.
    this._mode = 'RADAR';
    this.setData({
      status: 'REGISTERED: ' + rec.cat + ' · ' + rec.heading + '° - RADAR on',
      noteLine: 'NOTE: none yet - tap NOTE, say the price',
      lastEvent: 'EVT: stall registered ' + rec.cat + ' at heading ' + rec.heading +
        ' deg' + (rec.demo ? ' (DEMO heading)' : '')
    });
    this._recompute();
  },

  clearTap() {
    this._records = [];
    this._saveRecords();
    this._pendingNote = '';
    this._presetIdx = -1;
    this._mode = 'REG';
    this.setData({
      status: 'REG: face a stall, set CAT + NOTE, tap REG',
      noteLine: 'NOTE: none yet - tap NOTE, say the price',
      lastEvent: 'EVT: all stalls cleared'
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO registers 3 labeled stalls at 60 / 180 / 300 deg and switches
  // to RADAR; further taps step the simulated heading +45 deg. At
  // heading 45 the 60 deg stall is 15 deg off and FACING lights up.
  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      // Re-entering DEMO replaces older demo records instead of piling up.
      this._records = (this._records || []).filter(function (r) { return !r.demo; });
      var t = this._nowTime();
      this._addRecord({ cat: '蔬菜', note: '西红柿3块一斤', heading: 60, time: t, demo: true });
      this._addRecord({ cat: '水果', note: '苹果5块一斤', heading: 180, time: t, demo: true });
      this._addRecord({ cat: '海鲜', note: '虾25块一斤', heading: 300, time: t, demo: true });
      this._mode = 'RADAR';
      this.setData({
        status: 'DEMO RADAR: 3 stalls in (DEMO steps +45)',
        lastEvent: 'EVT: DEMO on - stalls at 60/180/300 deg, mode RADAR'
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

  // ---------- guidance math (same as exit-radar / head-nav) ----------

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  // Angularly nearest registered stall vs the current heading.
  // rel is normalised to -180..180, + means the stall is to your right.
  _nearest() {
    var recs = this._records || [];
    if (!recs.length || this._heading === null) return null;
    var best = null;
    for (var i = 0; i !== recs.length; i++) {
      var rel = ((recs[i].heading - this._heading + 540) % 360) - 180;
      if (!best || Math.abs(rel) < Math.abs(best.rel)) best = { rec: recs[i], rel: rel };
    }
    return best;
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · CAT: ' + this._cat()
    };
    var recs = this._records || [];
    if (!recs.length) {
      patch.rows = [{ text: '(no stalls) - REG one here, or DEMO' }];
    } else {
      patch.rows = recs.map(function (r) {
        return {
          text: r.cat + ' · ' + r.note.slice(0, 14) + ' · ' + r.heading + '° · ' +
            r.time + (r.demo ? ' DEMO' : '')
        };
      });
    }
    patch.countLine = 'STALLS: ' + recs.length + '/8 · stored on this device only';

    if (this._mode === 'REG') {
      patch.arrow = '·';
      patch.faceLine = recs.length
        ? 'RADAR: tap MODE to find a saved stall'
        : 'RADAR: no stalls yet - REG first';
      patch.faceCls = 'face';
      patch.faceLineDetail = 'FACING: ---';
      this._lastSpeak = {
        kind: 'reg', cat: this._cat(), note: this._pendingNote
      };
      this.setData(patch);
      return;
    }

    if (this._mode === 'LIST') {
      patch.arrow = '·';
      patch.faceLine = recs.length
        ? 'LIST: ' + recs.length + ' stalls - SPEAK reads all'
        : 'LIST: empty - REG a stall first';
      patch.faceCls = 'face';
      patch.faceLineDetail = 'COMPARE: same CAT twice? both kept';
      this._lastSpeak = recs.length ? { kind: 'list' } : null;
      this.setData(patch);
      return;
    }

    // RADAR mode
    if (!recs.length) {
      patch.arrow = '·';
      patch.faceLine = 'RADAR: no stalls - REG some first';
      patch.faceCls = 'face';
      patch.faceLineDetail = 'FACING: ---';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    if (this._heading === null) {
      patch.arrow = '·';
      patch.faceLine = 'RADAR: heading n/a - SRC NONE, tap DEMO';
      patch.faceCls = 'face';
      patch.faceLineDetail = 'FACING: ---';
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
    var relTxt = (rel > 0 ? '+' : (rel < 0 ? '-' : '')) + deg + '°';
    if (Math.abs(rel) <= 60) {
      // FACING: the stall is in the cone in front of you - show its
      // note big, exactly what you need to re-find the cheap stall.
      patch.faceLine = 'FACING: ' + b.rec.cat + ' · ' + b.rec.note.slice(0, 12) + ' · ' + b.rec.time;
      patch.faceCls = 'face face-on';
      patch.faceLineDetail = 'reg ' + b.rec.heading + '° · rel ' + relTxt + ' · ' + dir.en +
        (b.rec.demo ? ' · DEMO' : '');
      this._lastSpeak = {
        kind: 'stall', cat: b.rec.cat, note: b.rec.note,
        zh: dir.zh, deg: deg, ahead: true
      };
    } else {
      patch.faceLine = 'FACING: --- · turn slowly';
      patch.faceCls = 'face';
      patch.faceLineDetail = 'NEAREST: ' + b.rec.cat + ' · reg ' + b.rec.heading + '° · rel ' +
        relTxt + ' · ' + dir.en;
      this._lastSpeak = {
        kind: 'stall', cat: b.rec.cat, note: b.rec.note,
        zh: dir.zh, deg: deg, ahead: false
      };
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
      var s = this._lastSpeak;
      var recs = this._records || [];
      var text;
      if (!s) {
        text = '还没有登记摊位。先站到摊位前，选好品类，说好价格，点登记。';
      } else if (s.kind === 'reg') {
        text = '当前品类是' + s.cat + '。' + (s.note
          ? '备注是：' + s.note + '。核对无误就点登记。'
          : '还没有备注。点 NOTE，说出商品和价格，再登记。');
      } else if (s.kind === 'list') {
        var parts = ['一共登记了' + this._cnNum(recs.length) + '家摊位。'];
        for (var i = 0; i !== recs.length; i++) {
          parts.push(recs[i].cat + '，' + recs[i].note + '。');
        }
        text = parts.join('');
      } else if (s.ahead) {
        text = '你正对着' + s.cat + '摊。备注：' + s.note + '。';
      } else {
        text = '最近的摊位在你' + s.zh + ' ' + s.deg + '度，是' + s.cat + '。备注：' + s.note + '。';
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text.slice(0, 46) });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">MARKET RADAR</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="reg-box">
      <text class="reg-mode">{{modeLine}}</text>
      <text class="note">{{noteLine}}</text>
      <text class="count">{{countLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="face-box">
      <view class="face-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{faceCls}}">{{faceLine}}</text>
      </view>
      <text class="detail">{{faceLineDetail}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="catTap">CAT</button>
      <button class="btn" bindtap="noteTap">NOTE</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="regTap">REG</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="listTap">LIST</button>
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
.reg-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.reg-mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.note {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.count {
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
.face-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 4px;
  margin-bottom: 4px;
}
.face-top {
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
.face {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
}
.face-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.detail {
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
