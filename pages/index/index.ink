<script def>
{
  "navigationBarTitleText": "Hotel Checkin"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'SWIPE TO PICK A POINT - MARK ITS HEADING',
    headLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    progLine: 'CHECKED: 0/8 · OK 0 · ISSUE 0',
    stayLine: 'STAY: new record - text only; photos NOT saved',
    rows: [
      { text: '○ 门锁与猫眼 · unseen · no heading' },
      { text: '○ 床品 · unseen · no heading' },
      { text: '○ 床头插座 · unseen · no heading' },
      { text: '○ 浴室淋浴 · unseen · no heading' },
      { text: '○ 毛巾浴巾 · unseen · no heading' },
      { text: '○ 空调遥控 · unseen · no heading' },
      { text: '○ 窗帘窗锁 · unseen · no heading' },
      { text: '○ 热水壶 · unseen · no heading' }
    ],
    focusName: '▸ 门锁与猫眼 (1/8)',
    focusCue: '拉一下门把确认反锁，猫眼画面清楚',
    guideLine: 'NO HEADING — look at it, tap MARK to bind',
    guideCls: 'rel',
    photoLine: 'PHOTO: none - kept this session only, never saved',
    micLine: 'MIC CHECK: not run',
    lastEvent: 'EVT: checked = you looked - NOT proof it is fine',
    busy: false
  },

  onLoad() {
    this._defs = this._itemDefs();
    this._items = this._freshItems();
    this._recordDate = '';
    this._recordTime = '';
    this._loadRecord();
    this._photos = {};          // idx -> {bytes, time, demo} - SESSION ONLY, never persisted
    this._sel = 0;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._sensor = null;
    this._timer = null;
    this._dwellIdx = -1;
    this._dwellTicks = 0;        // 250ms ticks accumulated inside the cone
    this._dwellFrozen = false;   // DEMO holds a primed dwell for display
    this._doneSpoken = false;
    this._newArmed = false;
    this._demo = false;
    this._demoHeading = 0;
    this._realItems = null;
    this._realSel = 0;
    this._issueIdx = -1;
    this._asrBroken = false;     // recognition errored: next ISSUE uses chips
    this._dictRec = null;
    this._stream = null;
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
    this._stopDictRec();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopDictRec();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    this._saveRecord();
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
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // Nod discipline: a steady nod only ever OK-confirms the SELECTED
    // checkpoint, and only while you are actually facing it (its
    // registered heading within the +-25 deg cone) with a steady
    // head. A nod never registers a heading and never files an ISSUE.
    if (this.data.busy) return;
    var i = this._sel;
    var it = this._items[i];
    if (!it || it.state !== 'unseen') {
      this.setData({ lastEvent: 'EVT: nod ignored - selected point already checked' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    if (it.headingDeg === null || this._heading === null ||
        Math.abs(this._rel(it.headingDeg, this._heading)) > 25) {
      this.setData({ lastEvent: 'EVT: nod ignored - not facing the selected point' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod = OK-confirm (facing it, steady)' });
    this._setOk(i, 'nod');
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier §3.2.1): single tap arrives as Enter,
  // double-tap as Backspace, swipe as ArrowUp/ArrowDown. The whole
  // check flow runs on these keys + head-steady + nod; the on-screen
  // buttons mirror the same actions for tapping.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (Enter) = primary action' });
      this._primaryTap();
    } else if (code === 'ArrowDown') {
      this._moveSel(1);
    } else if (code === 'ArrowUp') {
      this._moveSel(-1);
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

  // The context primary action behind a single tap (Enter):
  // all checked -> speak the summary; selected unseen and not yet
  // registered -> MARK its heading; selected unseen and registered
  // -> OK-confirm by tap (same as the OK button); selected already
  // checked -> move on to the next unchecked point.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._doneCount() >= 8) { this.speakTap(); return; }
    var it = this._items[this._sel];
    if (it.state !== 'unseen') {
      var nx = this._nextUnseen(this._sel);
      if (nx >= 0) {
        this._sel = nx;
        this.setData({ lastEvent: 'EVT: tap -> next unchecked: ' + this._defs[nx].name });
        this._recompute();
      }
      return;
    }
    if (it.headingDeg === null) { this.markTap(); return; }
    this.okTap();
  },

  _moveSel(dir) {
    this._newArmed = false;
    this._sel = (((this._sel + dir) % 8) + 8) % 8;
    this.setData({ lastEvent: 'EVT: swipe -> select ' + this._defs[this._sel].name });
    this._recompute();
  },

  // ---------- the eight checkpoints ----------

  _itemDefs() {
    return [
      { name: '门锁与猫眼', cue: '拉一下门把确认反锁，猫眼画面清楚' },
      { name: '床品', cue: '掀开被角看床单枕套：干净、无毛发污渍' },
      { name: '床头插座', cue: '面板完好，插口无松动、无烧痕' },
      { name: '浴室淋浴', cue: '开花洒试水：水压够、热水来得快' },
      { name: '毛巾浴巾', cue: '浴巾毛巾各一条以上，干净无异味' },
      { name: '空调遥控', cue: '遥控在床头或桌上，按一下空调有反应' },
      { name: '窗帘窗锁', cue: '窗锁扣好，窗帘拉严不留透光缝' },
      { name: '热水壶', cue: '壶内无剩水、无异味，底座插好' }
    ];
  },

  _chips() {
    // Preset issue notes for hosts with no recogniser (honest SKIP
    // path): cycled by the ISSUE button, labelled as presets.
    return ['无热水', '有异味', '破损', '缺件'];
  },

  _freshItems() {
    var out = [];
    for (var i = 0; i !== 8; i++) {
      out.push({
        name: this._defs[i].name, headingDeg: null, demo: false,
        state: 'unseen', how: '', note: '', noteSrc: '', time: '', chipPos: 0
      });
    }
    return out;
  },

  _doneCount() {
    var n = 0;
    for (var i = 0; i !== 8; i++) if (this._items[i].state !== 'unseen') n++;
    return n;
  },

  _okCount() {
    var n = 0;
    for (var i = 0; i !== 8; i++) if (this._items[i].state === 'ok') n++;
    return n;
  },

  _issueCount() {
    var n = 0;
    for (var i = 0; i !== 8; i++) if (this._items[i].state === 'issue') n++;
    return n;
  },

  _nextUnseen(from) {
    for (var k = 1; k !== 9; k++) {
      var i = (from + k) % 8;
      if (this._items[i].state === 'unseen') return i;
    }
    return -1;
  },

  // ---------- persistence (wx sync storage, key 'hotelCheckin', TEXT ONLY) ----------

  _loadRecord() {
    try {
      var raw = wx.getStorageSync('hotelCheckin');
      if (!raw || typeof raw !== 'object' || !raw.items ||
          Object.prototype.toString.call(raw.items) !== '[object Array]') return;
      this._recordDate = typeof raw.date === 'string' ? raw.date : '';
      this._recordTime = typeof raw.time === 'string' ? raw.time : '';
      for (var i = 0; i !== raw.items.length; i++) {
        var r = raw.items[i];
        if (!r || typeof r.name !== 'string') continue;
        for (var j = 0; j !== 8; j++) {
          if (this._defs[j].name !== r.name) continue;
          var it = this._items[j];
          if (isFinite(r.headingDeg)) {
            it.headingDeg = ((Math.round(r.headingDeg) % 360) + 360) % 360;
            it.demo = !!r.demo;
          }
          if (r.state === 'ok' || r.state === 'issue') {
            it.state = r.state;
            it.how = typeof r.how === 'string' ? r.how : '';
            it.note = typeof r.note === 'string' ? r.note : '';
            it.noteSrc = typeof r.noteSrc === 'string' ? r.noteSrc : '';
            it.time = typeof r.time === 'string' ? r.time : '';
          }
          break;
        }
      }
      if (this._recordDate) {
        this.setData({
          status: 'RESUMED stay record - NEW starts a new stay',
          stayLine: 'STAY: ' + this._recordDate + ' ' + this._recordTime +
            ' · text only; photos NOT saved'
        });
      }
    } catch (e) { /* storage unreadable on this host: start fresh */ }
  },

  _saveRecord() {
    // DEMO state is a simulation: never overwrite the real record.
    if (this._demo) return;
    try {
      if (!this._recordDate) {
        var st = this._stamp();
        this._recordDate = st.date;
        this._recordTime = st.time;
      }
      var items = [];
      for (var i = 0; i !== 8; i++) {
        var it = this._items[i];
        // TEXT ONLY: names, headings, states, methods, notes, times.
        // Photos live in this._photos (memory) and are NEVER written.
        items.push({
          name: it.name, headingDeg: it.headingDeg, demo: !!it.demo,
          state: it.state, how: it.how, note: it.note,
          noteSrc: it.noteSrc, time: it.time
        });
      }
      wx.setStorageSync('hotelCheckin', {
        date: this._recordDate, time: this._recordTime, items: items
      });
    } catch (e) { /* storage unavailable on this host: record stays in memory */ }
  },

  // ---------- helpers ----------

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // ONE clock snapshot -> {date, time} as pure strings (the preview
  // host's Date is virtualised and drifts between calls, so one
  // record's date + time always come from a single read).
  _stamp() {
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      time: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
  },

  _hhmm(d) {
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
  },

  _headText(h) {
    return (h === null || h === undefined || !isFinite(h)) ? '---' : String(Math.round(h));
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
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

  // 250ms tick: poll the sensor (preview hosts may not fire
  // 'reading') and advance the dwell state machine on accumulated
  // tick counts - never on repeated Date samples.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._tick();
    }, 250);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _tick() { this._dwellTick(); },

  // ---------- relative-angle math (same convention as siblings) ----------

  _rel(targetDeg, current) {
    return ((targetDeg - current + 540) % 360) - 180; // -180..180, + = right
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  // The checkpoint your gaze is on right now: unchecked, has a
  // registered heading, within the +-25 deg cone. Nearest wins.
  _coneItem() {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 26;
    for (var i = 0; i !== 8; i++) {
      if (this._items[i].state !== 'unseen') continue;
      var h = this._items[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a <= 25 && a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  // Angularly nearest unchecked checkpoint that has a heading
  // (the missed-guidance target). -1 when none qualifies.
  _nearestMissed() {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 999;
    for (var i = 0; i !== 8; i++) {
      if (this._items[i].state !== 'unseen') continue;
      var h = this._items[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  // ---------- dwell state machine (the LOOK check) ----------

  _resetDwell() {
    this._dwellIdx = -1;
    this._dwellTicks = 0;
  },

  // Coverage rule (same as #30): gaze inside an unchecked point's
  // +-25 deg cone AND head steady, continuously for 2000ms = 8 ticks
  // of 250ms. Leaving the cone, switching points, or moving the head
  // resets the count - a fast sweep across the room earns nothing.
  _dwellTick() {
    if (this._dwellFrozen) return; // DEMO holds a primed dwell for display
    if (this._doneCount() >= 8) {
      if (this._dwellIdx >= 0) this._resetDwell();
      return;
    }
    var cand = this._steady ? this._coneItem() : -1;
    if (cand < 0) {
      if (this._dwellIdx >= 0) this._resetDwell();
      return;
    }
    if (cand !== this._dwellIdx) {
      this._dwellIdx = cand;
      this._dwellTicks = 0;
      this._recompute();
      return;
    }
    this._dwellTicks += 1;
    if (this._dwellTicks * 250 >= 2000) {
      var i = cand;
      this._resetDwell();
      this.setData({
        status: 'LOOKED ✓ ' + this._defs[i].name + ' (gaze 2s)',
        lastEvent: 'EVT: ' + this._defs[i].name + ' checked by 2s gaze dwell'
      });
      this._setOk(i, 'gaze');
      return;
    }
    this._recompute();
  },

  // ---------- state changes (methods recorded honestly) ----------

  _setOk(i, how) {
    var it = this._items[i];
    it.state = 'ok';
    it.how = how;
    it.note = '';
    it.noteSrc = '';
    it.time = this._hhmm(new Date());
    this._saveRecord();
    if (this._doneCount() >= 8) {
      this._finish();
    } else {
      if (this._sel === i) {
        var nx = this._nextUnseen(i);
        if (nx >= 0) this._sel = nx;
      }
      this._recompute();
    }
  },

  _setIssue(i, note, src) {
    var it = this._items[i];
    it.state = 'issue';
    it.how = '';
    it.note = note;
    it.noteSrc = src;
    it.time = this._hhmm(new Date());
    this._saveRecord();
    if (this._doneCount() >= 8) {
      this._finish();
    } else {
      this._recompute();
    }
  },

  // All eight checked: big summary + spoken once (issue notes read
  // out). Reaching "done" again later (flipping OK <-> ISSUE) does
  // not re-speak - the flag only resets on NEW.
  _finish() {
    this._recompute();
    if (this._doneSpoken) return;
    this._doneSpoken = true;
    this.setData({
      status: 'ALL 8 CHECKED — SPEAK 听汇总',
      lastEvent: 'EVT: inspection complete - summary spoken once'
    });
    this._speakText(this._summaryText());
    this._recompute();
  },

  _summaryText() {
    var t = '巡检完成。八项都检查过了。' + this._okCount() + '项没问题，' +
      this._issueCount() + '项有问题。';
    for (var i = 0; i !== 8; i++) {
      var it = this._items[i];
      if (it.state === 'issue') t += this._defs[i].name + '：' + it.note + '。';
    }
    t += '我记录的是你逐项看过；照片只在本次会话里，没有保存。';
    return t;
  },

  // ---------- MARK: bind the selected point to your current heading ----------

  markTap() {
    this._newArmed = false;
    if (this.data.busy) return;
    var i = this._sel;
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'MARK FAIL: no heading - DEMO or wait for sensor',
        lastEvent: 'EVT: MARK refused - never invent a heading'
      });
      return;
    }
    var h = Math.round(this._heading);
    this._items[i].headingDeg = h;
    this._items[i].demo = !!this._demo;
    this._saveRecord();
    this.setData({
      status: 'MARKED: ' + this._defs[i].name + ' @ ' + h + ' deg',
      lastEvent: 'EVT: heading bound ' + this._defs[i].name + ' at ' + h +
        ' deg' + (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._recompute();
  },

  // ---------- OK: tap-confirm the selected point ----------

  okTap() {
    this._newArmed = false;
    if (this.data.busy) return;
    var i = this._sel;
    this.setData({
      status: 'OK ✓ ' + this._defs[i].name + ' (by tap)',
      lastEvent: 'EVT: ' + this._defs[i].name + ' confirmed by tap - recorded as tap'
    });
    this._setOk(i, 'tap');
  },

  // ---------- ISSUE: file a problem note on the selected point ----------

  issueTap() {
    this._newArmed = false;
    if (this.data.busy) return;
    var i = this._sel;
    this._issueIdx = i;
    if (typeof SpeechRecognition === 'undefined' || this._asrBroken) {
      // Honest SKIP: no recogniser on this host - or recognition
      // already errored out once. ISSUE cycles the preset problem
      // chips instead of pretending to listen.
      var chips = this._chips();
      var it = this._items[i];
      var pos = it.chipPos || 0;
      var chip = chips[pos % chips.length];
      it.chipPos = pos + 1;
      this.setData({
        status: 'ISSUE (chip 预置）: ' + chip + ' - tap ISSUE to change',
        lastEvent: 'EVT: ISSUE chip applied (' +
          (this._asrBroken ? 'ASR failed earlier - fallback' : 'ASR n/a, honest SKIP') +
          '): ' + chip
      });
      this._setIssue(i, chip, 'chip');
      return;
    }
    this._issueListen();
  },

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  async _issueListen() {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (documented pattern, same
    // as #21/#36/#41): open the wearer-mode stream, read back its
    // settings, stop every track at once. The check stream is NOT
    // the recognition input and does not shape what recognition
    // hears - the host SpeechRecognition below listens on its own
    // microphone. The result shows on its own MIC CHECK line; the
    // listening line says (host ASR).
    var micNote = 'MIC CHECK: not run';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic check');
        var settings = {};
        try {
          var tr = ms.getAudioTracks()[0];
          if (tr && tr.getSettings) settings = tr.getSettings();
        } catch (e) {}
        micNote = 'MIC CHECK: wearer OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        micNote = 'MIC CHECK: FAIL - ' + this._err(e);
      }
    }
    this.setData({ micLine: micNote });
    try {
      this._stopDictRec();
      var rec = new SpeechRecognition();
      this._dictRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          var idx = self._issueIdx >= 0 ? self._issueIdx : self._sel;
          self.setData({
            status: 'ISSUE noted verbatim (' + micNote + ')',
            lastEvent: 'EVT: ISSUE dictated for ' + self._defs[idx].name + ' - kept verbatim'
          });
          self._setIssue(idx, txt, 'asr');
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        // Recognition produced nothing: the next ISSUE tap falls
        // back to the labelled preset chips instead of retrying a
        // broken recogniser.
        self._asrBroken = true;
        self.setData({
          status: 'ISSUE DICT FAIL - tap ISSUE for preset chips',
          lastEvent: 'EVT: ISSUE ASR error (' +
            self._err(ev && ev.error ? ev.error : ev) + ') - chips offered next'
        });
      };
      rec.onend = function () {
        if (self._dictRec === rec) self._dictRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'ISSUE: listening (host ASR) - say the problem',
        lastEvent: 'EVT: ISSUE listening (host ASR), ' + micNote
      });
    } catch (e) {
      this._asrBroken = true;
      this.setData({
        busy: false,
        status: 'ISSUE FAIL - tap ISSUE for preset chips',
        lastEvent: 'EVT: ISSUE start failed - ' + this._err(e)
      });
    }
  },

  // ---------- PHOTO: session-only record for the selected point ----------

  photoTap() {
    this._newArmed = false;
    if (this.data.busy) return;
    if (this._demo) {
      // DEMO seeds a fake session record (0 bytes, labelled) so the
      // photo state previews without a camera.
      this._photos[this._sel] = { bytes: 0, time: this._hhmm(new Date()), demo: true };
      this.setData({
        status: 'PHOTO (DEMO) - fake session record, 0 bytes',
        lastEvent: 'EVT: DEMO photo seeded - session only, never saved'
      });
      this._recompute();
      return;
    }
    this.capturePhoto();
  },

  async capturePhoto() {
    var i = this._sel;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'PHOTO FAIL - no camera on this host',
        lastEvent: 'EVT: PHOTO FAIL (host has no camera) - checks still work'
      });
      return;
    }
    this.setData({ busy: true, status: 'TAKING PHOTO (default mode)...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'photo');
      var bytes = blob && blob.size ? blob.size : 0;
      // The Blob itself is held on the record below in memory only;
      // it is never written to storage (Blobs cannot persist).
      this._photos[i] = { bytes: bytes, time: this._hhmm(new Date()), demo: false, blob: blob };
      this.setData({
        status: 'PHOTO kept for THIS SESSION only - not saved',
        lastEvent: 'EVT: photo ' + bytes + 'B for ' + this._defs[i].name +
          ' (memory only, never persisted)'
      });
      this._recompute();
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like the sibling agents.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this._photos[i] = { bytes: size, time: this._hhmm(new Date()), demo: false };
        this.setData({
          status: 'PHOTO (wx) kept for THIS SESSION only - not saved',
          lastEvent: 'EVT: wx photo ' + size + 'B for ' + this._defs[i].name + ' (memory only)'
        });
        this._recompute();
      } catch (e3) {
        this.setData({
          status: 'PHOTO FAIL - ' + this._err(firstErr),
          lastEvent: 'EVT: PHOTO FAIL - ' + this._err(firstErr)
        });
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
  },

  // ---------- LIST: jump to the next unchecked point ----------

  listTap() {
    this._newArmed = false;
    var nx = this._nextUnseen(this._sel);
    if (nx < 0) {
      this.setData({
        status: 'ALL 8 CHECKED - SPEAK reads the summary',
        lastEvent: 'EVT: LIST - nothing missed'
      });
      this._recompute();
      return;
    }
    this._sel = nx;
    this.setData({
      lastEvent: 'EVT: LIST -> next unchecked: ' + this._defs[nx].name
    });
    this._recompute();
  },

  // ---------- NEW: start a new stay (two-step confirm) ----------

  newTap() {
    if (this._demo) {
      this.setData({
        status: 'NEW does nothing in DEMO - tap DEMO to exit',
        lastEvent: 'EVT: NEW refused in DEMO'
      });
      return;
    }
    if (!this._newArmed) {
      this._newArmed = true;
      this.setData({
        status: 'NEW STAY? tap NEW again - clears checks + headings',
        lastEvent: 'EVT: NEW armed - second tap resets this stay'
      });
      return;
    }
    this._newArmed = false;
    this._items = this._freshItems();
    this._photos = {};
    this._sel = 0;
    this._doneSpoken = false;
    this._resetDwell();
    var st = this._stamp();
    this._recordDate = st.date;
    this._recordTime = st.time;
    this._saveRecord();
    this.setData({
      status: 'NEW STAY started - MARK the first point',
      stayLine: 'STAY: ' + st.date + ' ' + st.time + ' · text only; photos NOT saved',
      lastEvent: 'EVT: stay reset - checks, headings and notes cleared'
    });
    this._recompute();
  },

  // ---------- DEMO (seeded room, memory only - toggles off) ----------

  // DEMO binds four simulated headings (20/100/130/250 deg) and
  // pre-checks two points (door by gaze, bedding by tap), with all
  // times derived from ONE Date snapshot. The demo head rests at
  // 130 deg, steady, on the bedside socket, its dwell primed at
  // 1.0s and held for display. Further taps step the heading +45
  // deg and re-prime the held dwell. Real items are kept aside and
  // restored untouched when DEMO is tapped again; DEMO never saves.
  // DEMO button cycle: first tap enters + seeds; further taps step
  // the demo heading +45 deg (8 steps = a full circle); the tap
  // after a full circle exits DEMO and restores the real record.
  demoTap() {
    this._newArmed = false;
    if (this.data.busy) return;
    if (!this._demo) {
      this._realItems = this._items;
      this._realSel = this._sel;
      this._realPhotos = this._photos;
      var snap = new Date(); // ONE snapshot: all demo times derive from it
      var t = this._hhmm(snap);
      this._demo = true;
      this._demoSteps = 0;
      this._demoHeading = 130;
      this._heading = 130;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY' });
      var hs = [20, 100, 130, 250, null, null, null, null];
      this._items = this._freshItems();
      for (var i = 0; i !== 8; i++) {
        if (hs[i] !== null) { this._items[i].headingDeg = hs[i]; this._items[i].demo = true; }
      }
      this._items[0].state = 'ok'; this._items[0].how = 'gaze'; this._items[0].time = t;
      this._items[1].state = 'ok'; this._items[1].how = 'tap'; this._items[1].time = t;
      this._photos = {};
      this._doneSpoken = false;
      this._sel = 2;
      this._dwellIdx = 2;
      this._dwellTicks = 4; // 1.0s of the 2s dwell, held for display
      this._dwellFrozen = true;
      this.setData({
        status: 'DEMO ROOM - 2/8 checked, dwelling 床头插座',
        lastEvent: 'EVT: DEMO on - seeded room in memory only, nothing saved'
      });
      this._recompute();
      return;
    }
    if (this._demoSteps >= 8) {
      this._exitDemo();
      return;
    }
    this._demoSteps += 1;
    this._demoHeading = (this._demoHeading + 45) % 360;
    this._heading = this._demoHeading;
    this._headingSrc = 'DEMO';
    var cz = this._coneItem();
    if (cz >= 0) {
      this._dwellIdx = cz;
      this._dwellTicks = 4;
    } else {
      this._resetDwell();
    }
    this._dwellFrozen = true;
    this.setData({
      status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
    });
    this._recompute();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._items = this._realItems || this._freshItems();
    this._sel = this._realSel || 0;
    this._photos = this._realPhotos || {};
    this._realItems = null;
    this._realPhotos = null;
    this._dwellFrozen = false;
    this._resetDwell();
    this._doneSpoken = this._doneCount() >= 8;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this.setData({ steadyText: 'HEAD: moving - hold still' });
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real stay record is back',
      lastEvent: 'EVT: DEMO off - real record restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _recompute() {
    var done = this._doneCount();
    var sel = this._items[this._sel];
    var patch = {
      headLine: 'HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : ''),
      progLine: 'CHECKED: ' + done + '/8 · OK ' + this._okCount() +
        ' · ISSUE ' + this._issueCount(),
      focusName: '▸ ' + this._defs[this._sel].name + ' (' + (this._sel + 1) + '/8)',
      focusCue: this._defs[this._sel].cue
    };
    if (this._recordDate) {
      patch.stayLine = 'STAY: ' + this._recordDate + ' ' + this._recordTime +
        ' · text only; photos NOT saved';
    }
    var self = this;
    patch.rows = this._defs.map(function (d, i) {
      var it = self._items[i];
      var reg = it.headingDeg === null ? 'no heading' : 'reg ' + it.headingDeg + '°';
      var ph = self._photos[i] ? ' · photo' : '';
      var mark;
      if (it.state === 'ok') mark = '✓ ' + it.how + ' ' + it.time;
      else if (it.state === 'issue') {
        mark = '✗ ISSUE ' + it.note + ' (' + (it.noteSrc === 'asr' ? 'ASR' : 'chip') + ')';
      } else if (self._dwellIdx === i) {
        mark = '◎ dwell ' + (self._dwellTicks * 250 / 1000).toFixed(1) + 's';
      } else mark = '○ unseen';
      var cur = i === self._sel ? '▸ ' : '';
      return { text: cur + d.name + ' · ' + mark + ' · ' + reg + ph };
    });

    // Guide box: about the SELECTED point, plus missed guidance.
    if (done >= 8) {
      patch.guideLine = 'ALL DONE — ' + this._okCount() + ' OK · ' +
        this._issueCount() + ' ISSUE · SPEAK 听汇总';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._summaryText() };
    } else if (sel.state === 'ok') {
      patch.guideLine = '✓ OK by ' + sel.how + ' ' + sel.time + ' — swipe for the next point';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else if (sel.state === 'issue') {
      patch.guideLine = '✗ ISSUE: ' + sel.note + ' (' +
        (sel.noteSrc === 'asr' ? 'your words, verbatim' : 'preset chip') + ')';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else if (this._dwellIdx === this._sel && this._dwellTicks > 0) {
      patch.guideLine = 'DWELL ' + (this._dwellTicks * 250 / 1000).toFixed(1) +
        's / 2s — hold still, look as you check';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._progressText() };
    } else if (sel.headingDeg === null) {
      patch.guideLine = 'NO HEADING — look at it, tap MARK to bind';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else if (this._heading === null) {
      patch.guideLine = 'HEADING N/A (SRC NONE) — find it by eye, OK to check';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else {
      var rel = this._rel(sel.headingDeg, this._heading);
      var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
      var rel360 = (sel.headingDeg - this._heading + 360) % 360;
      patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' TURN: ' +
        this._dirName(rel).en + ' ' + Math.round(Math.abs(rel)) + '° — reg ' +
        sel.headingDeg + '°' + (Math.abs(rel) <= 25 ? ' · IN VIEW: hold still 2s' : '');
      patch.guideCls = Math.abs(rel) <= 25 ? 'rel rel-on' : 'rel';
      this._lastSpeak = { text: this._progressText() };
    }

    var ph = this._photos[this._sel];
    patch.photoLine = ph
      ? 'PHOTO: ' + ph.bytes + 'B' + (ph.demo ? ' (DEMO)' : '') + ' ' + ph.time +
        ' - this session only, NOT saved'
      : 'PHOTO: none - kept this session only, never saved';
    this.setData(patch);
  },

  _progressText() {
    var missed = [];
    for (var i = 0; i !== 8; i++) {
      if (this._items[i].state === 'unseen') missed.push(this._defs[i].name);
    }
    var t = '还差' + missed.length + '项没看：' + missed.join('、') + '。' +
      '当前一项：' + this._defs[this._sel].name + '。' + this._defs[this._sel].cue + '。';
    var nm = this._nearestMissed();
    if (nm >= 0 && nm !== this._sel) {
      var rel = this._rel(this._items[nm].headingDeg, this._heading);
      t += '最近的未看项' + this._defs[nm].name + '在你' + this._dirName(rel).zh +
        Math.round(Math.abs(rel)) + '度。';
    }
    return t;
  },

  // ---------- speech (TTS out; lang is never set) ----------

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
    this._newArmed = false;
    if (this.data.busy) return;
    var s = this._lastSpeak;
    var text = s ? s.text : '还没有巡检进度。';
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">HOTEL CHECK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}} · {{steadyText}}</text>
    </view>
    <view class="prog-box">
      <text class="prog">{{progLine}}</text>
      <text class="stay">{{stayLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="guide-box">
      <text class="curname">{{focusName}}</text>
      <text class="cue">{{focusCue}}</text>
      <text class="{{guideCls}}">{{guideLine}}</text>
      <text class="small">{{photoLine}}</text>
      <text class="small">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="okTap">OK</button>
      <button class="btn" bindtap="issueTap">ISSUE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="photoTap">PHOTO</button>
      <button class="btn" bindtap="listTap">LIST</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="newTap">NEW</button>
    </view>
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
  margin-bottom: 2px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 22px;
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
.prog-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 10px;
  margin-bottom: 3px;
}
.prog {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.stay {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
.list {
  height: 62px;
  margin-bottom: 3px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 1px 0;
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
  padding: 3px 10px 4px;
  margin-bottom: 3px;
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
  line-height: 14px;
  margin-top: 1px;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
  margin-top: 1px;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.small {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
