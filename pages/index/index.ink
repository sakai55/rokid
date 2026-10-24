<script def>
{
  "navigationBarTitleText": "Site Patrol"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'SWIPE TO PICK A POINT - MARK ITS HEADING',
    headLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    progLine: 'DONE: 0/6 · OK 0 · ISSUE 0',
    roundLine: 'ROUND: new round - text archived; photos NOT saved',
    rows: [
      { text: '○ 消防器材 · 待：状态/照片/确认 · no heading' },
      { text: '○ 安全出口 · 待：状态/照片/确认 · no heading' },
      { text: '○ 配电箱 · 待：状态/照片/确认 · no heading' },
      { text: '○ 防护栏 · 待：状态/照片/确认 · no heading' },
      { text: '○ 物料堆放 · 待：状态/照片/确认 · no heading' },
      { text: '○ 警示标识 · 待：状态/照片/确认 · no heading' }
    ],
    focusName: '▸ 消防器材 (1/6)',
    focusCue: '灭火器在位、压力表在绿区、有效期未过，前面无遮挡',
    partsLine: 'PARTS: 状态 ✗ · 照片 ✗ · 确认 ✗ — 还差：状态、照片、确认',
    guideLine: 'NO HEADING — look at it, tap MARK to bind',
    guideCls: 'rel',
    photoLine: 'PHOTO: none - kept this session only, never saved',
    micLine: 'MIC CHECK: not run',
    lastEvent: 'EVT: DONE needs 状态 + 照片 + 确认 - all three',
    busy: false
  },

  onLoad() {
    this._defs = this._itemDefs();
    this._items = this._freshItems();
    this._rounds = [];
    this._roundDate = '';
    this._roundTime = '';
    this._roundArchived = false;
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
    this._doneSpoken = this._doneCount() >= 6;
    this._newArmed = false;
    this._demo = false;
    this._demoHeading = 0;
    this._demoSteps = 0;
    this._realItems = null;
    this._realPhotos = null;
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
    this._persist();
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
    // Nod discipline: a steady nod only ever CONFIRMS the SELECTED
    // checkpoint, and only while you are actually facing it (its
    // registered heading within the +-25 deg cone) with a steady
    // head. A nod never sets a status, never files an ISSUE, never
    // takes the photo and never registers a heading.
    if (this.data.busy) return;
    var i = this._sel;
    var it = this._items[i];
    if (!it || it.confirmHow) {
      this.setData({ lastEvent: 'EVT: nod ignored - selected point already confirmed' });
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
    this.setData({ lastEvent: 'EVT: nod = confirm (facing it, steady)' });
    this._setConfirm(i, 'nod');
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier §3.2.1): single tap arrives as Enter,
  // double-tap as Backspace, swipe as ArrowUp/ArrowDown. The whole
  // patrol flow runs on these keys + head-steady + nod; the
  // on-screen buttons mirror the same actions for tapping.
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
  // round complete -> speak the summary; selected DONE -> jump to
  // the next unfinished point; selected unregistered -> MARK its
  // heading; otherwise tap-confirm it (the OK path) and, if parts
  // are still missing afterwards, SPEAK what is missing.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._doneCount() >= 6) { this.speakTap(); return; }
    var it = this._items[this._sel];
    if (this._isDone(this._sel)) {
      var nx = this._nextUndone(this._sel);
      if (nx >= 0) {
        this._sel = nx;
        this.setData({ lastEvent: 'EVT: tap -> next unfinished: ' + this._defs[nx].name });
        this._recompute();
      }
      return;
    }
    if (it.headingDeg === null) { this.markTap(); return; }
    this.okTap(true);
  },

  _moveSel(dir) {
    this._newArmed = false;
    this._sel = (((this._sel + dir) % 6) + 6) % 6;
    this.setData({ lastEvent: 'EVT: swipe -> select ' + this._defs[this._sel].name });
    this._recompute();
  },

  // ---------- the six checkpoints ----------

  _itemDefs() {
    return [
      { name: '消防器材', cue: '灭火器在位、压力表在绿区、有效期未过，前面无遮挡' },
      { name: '安全出口', cue: '出口灯亮、疏散门推得开、通道里没有杂物堆放' },
      { name: '配电箱', cue: '箱门关好、无异响异味，周边半米内无易燃物' },
      { name: '防护栏', cue: '栏杆无缺口无松动，踢脚板在位，临边不缺口' },
      { name: '物料堆放', cue: '堆放不超高、不堵通道，码在黄线以内' },
      { name: '警示标识', cue: '标识齐全无脱落，字迹清晰，反光完好' }
    ];
  },

  _chips() {
    // Preset issue notes for hosts with no recogniser (honest SKIP
    // path): cycled by the ISSUE button, labelled as presets.
    return ['灭火器过期', '通道堵塞', '围栏破损', '标识缺失'];
  },

  _freshItems() {
    var out = [];
    for (var i = 0; i !== 6; i++) {
      out.push({
        name: this._defs[i].name, headingDeg: null, demo: false,
        status: '', note: '', noteSrc: '', confirmHow: '', time: '', chipPos: 0
      });
    }
    return out;
  },

  // ---------- the three-part completion rule ----------

  // A checkpoint counts as DONE only when ALL THREE parts are on
  // record: a STATUS (OK via OK-tap, or ISSUE with a note), a PHOTO
  // (session record - proves you stood there, never archived) and
  // a CONFIRMATION (2s gaze dwell, nod while facing it, or tap OK).
  _missingParts(i) {
    var it = this._items[i];
    var miss = [];
    if (!it.status) miss.push('状态');
    if (!this._photos[i]) miss.push('照片');
    if (!it.confirmHow) miss.push('确认');
    return miss;
  },

  _isDone(i) { return this._missingParts(i).length === 0; },

  _doneCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._isDone(i)) n++;
    return n;
  },

  _okCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._items[i].status === 'ok') n++;
    return n;
  },

  _issueCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._items[i].status === 'issue') n++;
    return n;
  },

  _nextUndone(from) {
    for (var k = 1; k !== 7; k++) {
      var i = (from + k) % 6;
      if (!this._isDone(i)) return i;
    }
    return -1;
  },

  // ---------- persistence (wx sync storage, key 'sitePatrolRounds', TEXT ONLY) ----------

  _loadRecord() {
    try {
      var raw = wx.getStorageSync('sitePatrolRounds');
      if (!raw || typeof raw !== 'object') return;
      this._roundDate = typeof raw.roundDate === 'string' ? raw.roundDate : '';
      this._roundTime = typeof raw.roundTime === 'string' ? raw.roundTime : '';
      if (Object.prototype.toString.call(raw.rounds) === '[object Array]') {
        for (var r = 0; r !== raw.rounds.length; r++) {
          var rd = raw.rounds[r];
          if (rd && typeof rd.date === 'string' &&
              Object.prototype.toString.call(rd.items) === '[object Array]') {
            this._rounds.push(rd);
          }
        }
        if (this._rounds.length > 5) this._rounds = this._rounds.slice(-5);
      }
      if (Object.prototype.toString.call(raw.items) !== '[object Array]') return;
      for (var i = 0; i !== raw.items.length; i++) {
        var rec = raw.items[i];
        if (!rec || typeof rec.name !== 'string') continue;
        for (var j = 0; j !== 6; j++) {
          if (this._defs[j].name !== rec.name) continue;
          var it = this._items[j];
          if (isFinite(rec.headingDeg)) {
            it.headingDeg = ((Math.round(rec.headingDeg) % 360) + 360) % 360;
            it.demo = !!rec.demo;
          }
          if (rec.status === 'ok' || rec.status === 'issue') {
            it.status = rec.status;
            it.note = typeof rec.note === 'string' ? rec.note : '';
            it.noteSrc = typeof rec.noteSrc === 'string' ? rec.noteSrc : '';
            it.time = typeof rec.time === 'string' ? rec.time : '';
          }
          if (rec.confirmHow === 'gaze' || rec.confirmHow === 'nod' || rec.confirmHow === 'tap') {
            it.confirmHow = rec.confirmHow;
          }
          break;
        }
      }
      this._roundArchived = this._doneCount() >= 6;
      if (this._roundDate) {
        this.setData({
          status: 'RESUMED patrol record - NEW starts a new round',
          roundLine: 'ROUND: ' + this._roundDate + ' ' + this._roundTime +
            ' · 已归档 ' + this._rounds.length + '/5 轮 · text only; photos NOT saved'
        });
      }
    } catch (e) { /* storage unreadable on this host: start fresh */ }
  },

  _persist() {
    // DEMO state is a simulation: never overwrite the real record.
    if (this._demo) return;
    try {
      if (!this._roundDate) {
        var st = this._stamp();
        this._roundDate = st.date;
        this._roundTime = st.time;
      }
      var items = [];
      for (var i = 0; i !== 6; i++) {
        var it = this._items[i];
        // TEXT ONLY: names, headings, statuses, notes, confirm
        // methods, times. Photos live in this._photos (memory) and
        // are NEVER written - they cannot persist in wx storage.
        items.push({
          name: it.name, headingDeg: it.headingDeg, demo: !!it.demo,
          status: it.status, note: it.note, noteSrc: it.noteSrc,
          confirmHow: it.confirmHow, time: it.time
        });
      }
      var rounds = [];
      for (var k = 0; k !== this._rounds.length; k++) rounds.push(this._rounds[k]);
      wx.setStorageSync('sitePatrolRounds', {
        roundDate: this._roundDate, roundTime: this._roundTime,
        items: items, rounds: rounds
      });
    } catch (e) { /* storage unavailable on this host: record stays in memory */ }
  },

  // Archive the finished round as TEXT (<=5 rounds kept, oldest
  // dropped). Re-completing after a status flip updates the same
  // archived snapshot instead of adding a duplicate.
  _archiveRound() {
    if (this._demo) return; // a simulated round is never archived
    var snapItems = [];
    for (var i = 0; i !== 6; i++) {
      var it = this._items[i];
      snapItems.push({
        name: it.name, status: it.status, note: it.note,
        noteSrc: it.noteSrc, confirmHow: it.confirmHow, time: it.time
      });
    }
    var snap = { date: this._roundDate, time: this._roundTime, items: snapItems };
    if (this._roundArchived && this._rounds.length > 0) {
      this._rounds[this._rounds.length - 1] = snap;
    } else {
      this._rounds.push(snap);
      this._roundArchived = true;
      if (this._rounds.length > 5) {
        this._rounds.shift();
        this.setData({ lastEvent: 'EVT: round archive full - oldest round dropped (keeps 5)' });
      }
    }
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

  // The checkpoint your gaze could confirm right now: its CONFIRM
  // part still missing, has a registered heading, within the
  // +-25 deg cone. Nearest wins.
  _coneItem() {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 26;
    for (var i = 0; i !== 6; i++) {
      if (this._items[i].confirmHow) continue;
      var h = this._items[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a <= 25 && a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  // Angularly nearest unfinished checkpoint that has a heading
  // (the missed-guidance target). -1 when none qualifies.
  _nearestMissed() {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 999;
    for (var i = 0; i !== 6; i++) {
      if (this._isDone(i)) continue;
      var h = this._items[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  // ---------- dwell state machine (the gaze CONFIRM) ----------

  _resetDwell() {
    this._dwellIdx = -1;
    this._dwellTicks = 0;
  },

  // Coverage rule (same as #30/#43): gaze inside an unconfirmed
  // point's +-25 deg cone AND head steady, continuously for
  // 2000ms = 8 ticks of 250ms, fills that point's CONFIRM part as
  // 'gaze'. Leaving the cone, switching points, or moving the head
  // resets the count - a fast sweep across the site earns nothing.
  _dwellTick() {
    if (this._dwellFrozen) return; // DEMO holds a primed dwell for display
    if (this._doneCount() >= 6) {
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
        status: 'GAZE CONFIRM ✓ ' + this._defs[i].name + ' (looked 2s)',
        lastEvent: 'EVT: ' + this._defs[i].name + ' confirmed by 2s gaze dwell'
      });
      this._setConfirm(i, 'gaze');
      return;
    }
    this._recompute();
  },

  // ---------- state changes (each part recorded honestly) ----------

  // Central after-change hook: persist the text record, move the
  // selection on if the selected point just became DONE, and finish
  // the round when the last point lands its third part.
  _afterChange(i) {
    this._persist();
    if (this._doneCount() >= 6) { this._finish(); return; }
    if (i === this._sel && this._isDone(i)) {
      var nx = this._nextUndone(i);
      if (nx >= 0) this._sel = nx;
    }
    this._recompute();
  },

  _setConfirm(i, how) {
    var it = this._items[i];
    if (it.confirmHow) { this._recompute(); return; }
    it.confirmHow = how;
    if (!it.time) it.time = this._hhmm(new Date());
    this._afterChange(i);
  },

  _setStatusOk(i) {
    var it = this._items[i];
    it.status = 'ok';
    it.note = '';
    it.noteSrc = '';
    it.time = this._hhmm(new Date());
    this._afterChange(i);
  },

  _setIssue(i, note, src) {
    var it = this._items[i];
    it.status = 'issue';
    it.note = note;
    it.noteSrc = src;
    it.time = this._hhmm(new Date());
    this._afterChange(i);
  },

  // All six DONE: archive the round as text + big summary spoken
  // once. Flipping a status afterwards updates the archived
  // snapshot and does not re-speak or re-archive a duplicate.
  _finish() {
    this._archiveRound();
    this._persist();
    this._recompute();
    if (this._doneSpoken) return;
    this._doneSpoken = true;
    this.setData({
      status: 'ALL 6 DONE — round archived (text)',
      lastEvent: 'EVT: patrol round complete - summary spoken once'
    });
    this._speakText(this._summaryText());
    this._recompute();
  },

  _summaryText() {
    var t = '巡检完成。六个检查点全部完成。' + this._okCount() + '项没问题，' +
      this._issueCount() + '项有问题。';
    for (var i = 0; i !== 6; i++) {
      var it = this._items[i];
      if (it.status === 'issue') t += this._defs[i].name + '：' + it.note + '。';
    }
    t += '本轮记录已存档为文字；照片只在本次会话里，没有归档。';
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
    this._persist();
    this.setData({
      status: 'MARKED: ' + this._defs[i].name + ' @ ' + h + ' deg',
      lastEvent: 'EVT: heading bound ' + this._defs[i].name + ' at ' + h +
        ' deg' + (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._recompute();
  },

  // ---------- OK: tap-confirm the selected point ----------

  // Tap OK fills the STATUS part as 'ok' (unless an ISSUE already
  // stands - the issue is never overwritten by a confirm) and the
  // CONFIRM part as 'tap'. Via Enter (fromPrimary), whatever parts
  // are still missing afterwards are spoken aloud.
  okTap(fromPrimary) {
    this._newArmed = false;
    if (this.data.busy) return;
    var i = this._sel;
    var it = this._items[i];
    if (this._isDone(i)) {
      this.setData({
        status: this._defs[i].name + ' already DONE',
        lastEvent: 'EVT: OK on a DONE point - nothing changed'
      });
      return;
    }
    var filledStatus = false;
    if (!it.status) { it.status = 'ok'; it.time = this._hhmm(new Date()); filledStatus = true; }
    if (!it.confirmHow) it.confirmHow = 'tap';
    this._persist();
    var miss = this._missingParts(i);
    this.setData({
      status: (filledStatus ? 'OK ✓ ' : 'CONFIRM ✓ (ISSUE stands) ') + this._defs[i].name +
        (miss.length ? ' — 还差：' + miss.join('、') : ' — DONE'),
      lastEvent: 'EVT: ' + this._defs[i].name + ' tap-confirmed' +
        (filledStatus ? ' + status ok' : '') +
        (miss.length ? '; still missing: ' + miss.join('/') : '; point DONE')
    });
    if (this._doneCount() >= 6) { this._finish(); return; }
    if (i === this._sel && this._isDone(i)) {
      var nx = this._nextUndone(i);
      if (nx >= 0) this._sel = nx;
    }
    this._recompute();
    if (fromPrimary && miss.length) {
      this._speakText(this._defs[i].name + '还差：' + miss.join('、') + '。');
    }
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
    // as #21/#36/#41/#43): open the wearer-mode stream, read back
    // its settings, stop every track at once. This is a CHECK
    // only: the wearer mode does not denoise anything and does not
    // shape what recognition hears - the host SpeechRecognition
    // below listens on its own microphone. The check result shows
    // on its own MIC CHECK line; the listening line says (host ASR).
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
      // photo part previews without a camera.
      var i = this._sel;
      this._photos[i] = { bytes: 0, time: this._hhmm(new Date()), demo: true };
      this.setData({
        status: 'PHOTO (DEMO) - fake session record, 0 bytes',
        lastEvent: 'EVT: DEMO photo seeded - session only, never saved'
      });
      this._afterChange(i);
      return;
    }
    this.capturePhoto();
  },

  async capturePhoto() {
    var i = this._sel;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'PHOTO FAIL - no camera on this host',
        lastEvent: 'EVT: PHOTO FAIL (host has no camera) - other parts still work'
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
      // The Blob is held in memory only, as this session's record
      // that you stood at the point. It is never written to
      // storage (Blobs cannot persist) and never archived.
      this._photos[i] = { bytes: bytes, time: this._hhmm(new Date()), demo: false, blob: blob };
      this.setData({
        status: 'PHOTO kept for THIS SESSION only - not saved',
        lastEvent: 'EVT: photo ' + bytes + 'B for ' + this._defs[i].name +
          ' (memory only, never persisted)'
      });
      this._afterChange(i);
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
        this._afterChange(i);
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

  // ---------- LIST: jump to the next unfinished point ----------

  listTap() {
    this._newArmed = false;
    var nx = this._nextUndone(this._sel);
    if (nx < 0) {
      this.setData({
        status: 'ALL 6 DONE - SPEAK reads the summary',
        lastEvent: 'EVT: LIST - nothing unfinished'
      });
      this._recompute();
      return;
    }
    this._sel = nx;
    this.setData({
      lastEvent: 'EVT: LIST -> next unfinished: ' + this._defs[nx].name +
        ' (missing: ' + this._missingParts(nx).join('/') + ')'
    });
    this._recompute();
  },

  // ---------- NEW: start a new round (two-step confirm) ----------

  // NEW clears the current round's statuses, notes, confirmations
  // and session photos, and archives NOTHING extra - only finished
  // rounds are archived. Registered headings PERSIST across rounds
  // (same site), so the next round starts with guidance ready.
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
        status: 'NEW ROUND? tap NEW again - clears progress, KEEPS headings',
        lastEvent: 'EVT: NEW armed - second tap starts a new round'
      });
      return;
    }
    this._newArmed = false;
    var keep = [];
    for (var i = 0; i !== 6; i++) {
      keep.push({ headingDeg: this._items[i].headingDeg, demo: this._items[i].demo });
    }
    this._items = this._freshItems();
    for (var j = 0; j !== 6; j++) {
      this._items[j].headingDeg = keep[j].headingDeg;
      this._items[j].demo = keep[j].demo;
    }
    this._photos = {};
    this._sel = 0;
    this._doneSpoken = false;
    this._roundArchived = false;
    this._resetDwell();
    var st = this._stamp();
    this._roundDate = st.date;
    this._roundTime = st.time;
    this._persist();
    this.setData({
      status: 'NEW ROUND started - headings kept, progress cleared',
      lastEvent: 'EVT: new round - statuses/notes/confirms/photos cleared, headings kept'
    });
    this._recompute();
  },

  // ---------- DEMO (seeded site, memory only - toggles off) ----------

  // DEMO binds three simulated headings (30/110/200 deg), completes
  // 消防器材 in full (status ok + photo + gaze confirm) and files
  // an ISSUE with a preset chip note on 安全出口 (status only -
  // photo and confirm still missing, so it is NOT done). The demo
  // head rests at 200 deg, steady, on 配电箱， its confirm dwell
  // primed at 1.0s and held for display. All seed times derive from
  // ONE Date snapshot. Further taps step the heading +45 deg; the
  // tap after a full circle exits DEMO and restores the real
  // record untouched. DEMO never persists and never archives.
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
      this._demoHeading = 200;
      this._heading = 200;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY' });
      var hs = [30, 110, 200, null, null, null];
      this._items = this._freshItems();
      for (var i = 0; i !== 6; i++) {
        if (hs[i] !== null) { this._items[i].headingDeg = hs[i]; this._items[i].demo = true; }
      }
      this._items[0].status = 'ok'; this._items[0].confirmHow = 'gaze'; this._items[0].time = t;
      this._items[1].status = 'issue'; this._items[1].note = '通道堵塞';
      this._items[1].noteSrc = 'chip'; this._items[1].time = t;
      this._photos = {};
      this._photos[0] = { bytes: 0, time: t, demo: true };
      this._doneSpoken = false;
      this._sel = 2;
      this._dwellIdx = 2;
      this._dwellTicks = 4; // 1.0s of the 2s confirm dwell, held for display
      this._dwellFrozen = true;
      this.setData({
        status: 'DEMO SITE - 1/6 done, 安全出口 has an ISSUE',
        lastEvent: 'EVT: DEMO on - seeded site in memory only, nothing saved'
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
    this._doneSpoken = this._doneCount() >= 6;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this.setData({ steadyText: 'HEAD: moving - hold still' });
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real patrol record is back',
      lastEvent: 'EVT: DEMO off - real record restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _partsText(i) {
    var it = this._items[i];
    var s = it.status ? '✓ ' + (it.status === 'ok' ? 'ok' : 'ISSUE') : '✗';
    var p = this._photos[i] ? '✓' : '✗';
    var c = it.confirmHow ? '✓ ' + it.confirmHow : '✗';
    return 'PARTS: 状态 ' + s + ' · 照片 ' + p + ' · 确认 ' + c;
  },

  _recompute() {
    var done = this._doneCount();
    var sel = this._items[this._sel];
    var patch = {
      headLine: 'HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : ''),
      progLine: 'DONE: ' + done + '/6 · OK ' + this._okCount() +
        ' · ISSUE ' + this._issueCount(),
      focusName: '▸ ' + this._defs[this._sel].name + ' (' + (this._sel + 1) + '/6)',
      focusCue: this._defs[this._sel].cue,
      partsLine: this._partsText(this._sel) +
        (this._isDone(this._sel) ? ' — DONE ✓' : ' — 还差：' + this._missingParts(this._sel).join('、'))
    };
    if (this._roundDate) {
      patch.roundLine = 'ROUND: ' + this._roundDate + ' ' + this._roundTime +
        ' · 已归档 ' + this._rounds.length + '/5 轮 · text only; photos NOT saved';
    }
    var self = this;
    patch.rows = this._defs.map(function (d, i) {
      var it = self._items[i];
      var reg = it.headingDeg === null ? 'no heading' : 'reg ' + it.headingDeg + '°';
      var mark;
      if (self._isDone(i)) {
        mark = '✓ DONE ' + (it.status === 'ok' ? 'ok' : 'ISSUE ' + it.note) +
          ' · ' + it.confirmHow + ' ' + it.time;
      } else if (it.status === 'issue') {
        mark = '✗ ISSUE ' + it.note + ' (' + (it.noteSrc === 'asr' ? 'ASR' : 'chip') +
          ') · 待：' + self._missingParts(i).join('/');
      } else if (self._dwellIdx === i) {
        mark = '◎ dwell ' + (self._dwellTicks * 250 / 1000).toFixed(1) + 's · 待：' +
          self._missingParts(i).join('/');
      } else {
        mark = '○ 待：' + self._missingParts(i).join('/');
      }
      var cur = i === self._sel ? '▸ ' : '';
      return { text: cur + d.name + ' · ' + mark + ' · ' + reg };
    });

    // Guide box: missed guidance for the SELECTED point.
    if (done >= 6) {
      patch.guideLine = 'ALL DONE — ' + this._okCount() + ' OK · ' +
        this._issueCount() + ' ISSUE · round archived · SPEAK 听汇总';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._summaryText() };
    } else if (this._isDone(this._sel)) {
      patch.guideLine = '✓ DONE — swipe for the next unfinished point';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else if (this._dwellIdx === this._sel && this._dwellTicks > 0) {
      patch.guideLine = 'DWELL ' + (this._dwellTicks * 250 / 1000).toFixed(1) +
        's / 2s — hold still to CONFIRM this point';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._progressText() };
    } else if (sel.headingDeg === null) {
      patch.guideLine = 'NO HEADING — look at it, tap MARK to bind';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else if (this._heading === null) {
      patch.guideLine = 'HEADING N/A (SRC NONE) — find it by eye, OK/PHOTO by tap';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._progressText() };
    } else {
      var rel = this._rel(sel.headingDeg, this._heading);
      var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
      var rel360 = (sel.headingDeg - this._heading + 360) % 360;
      patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' TURN: ' +
        this._dirName(rel).en + ' ' + Math.round(Math.abs(rel)) + '° — reg ' +
        sel.headingDeg + '°' + (Math.abs(rel) <= 25 ? ' · IN VIEW: hold still 2s to confirm' : '');
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
    var parts = [];
    for (var i = 0; i !== 6; i++) {
      if (!this._isDone(i)) {
        parts.push(this._defs[i].name + '（差：' + this._missingParts(i).join('、') + '）');
      }
    }
    var t = '还差' + parts.length + '项未完成：' + parts.join('、') + '。';
    var nm = this._nearestMissed();
    if (nm >= 0 && nm !== this._sel) {
      var rel = this._rel(this._items[nm].headingDeg, this._heading);
      t += '最近的未完成项' + this._defs[nm].name + '在你' + this._dirName(rel).zh +
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
      <text class="title">SITE PATROL</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headLine}} · {{steadyText}}</text>
    </view>
    <view class="prog-box">
      <text class="prog">{{progLine}}</text>
      <text class="stay">{{roundLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="guide-box">
      <text class="curname">{{focusName}}</text>
      <text class="cue">{{focusCue}}</text>
      <text class="small">{{partsLine}}</text>
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
  height: 52px;
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
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
