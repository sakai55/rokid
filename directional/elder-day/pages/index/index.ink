<script def>
{
  "navigationBarTitleText": "Elder Day"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'SWIPE TO PICK AN ITEM - LOOK AT ITS OBJECT TO CONFIRM',
    clockLine: 'TIME --:-- · HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    remindLine: '提醒只在本页打开时播报 · REMINDERS ONLY WHILE THIS PAGE IS OPEN',
    progLine: 'TODAY: 0/6 DONE · DUE 0',
    dayLine: 'DAY: - · text record on this device only',
    rows: [
      { text: '○ 早晨吃药 · 08:00 · 药瓶 · 待确认' },
      { text: '○ 上午喝水 · 10:00 · 水杯 · 待确认' },
      { text: '○ 午饭 · 12:00 · 餐桌 · 待确认' },
      { text: '○ 下午吃药 · 15:00 · 药瓶 · 待确认' },
      { text: '○ 傍晚散步 · 17:00 · 大门 · 待确认' },
      { text: '○ 睡前门窗 · 21:00 · 大门 · 待确认' }
    ],
    focusName: '▸ 早晨吃药 (1/6)',
    focusCue: '看着药瓶：这一顿吃过了，就确认',
    guideLine: 'NO HEADING — family setup: look at it, tap MARK once',
    guideCls: 'rel',
    lastEvent: 'EVT: confirm = you looked and say done - I cannot check for you',
    busy: false
  },

  onLoad() {
    this._items = this._defaultPlan();
    this._loadPlan();
    this._log = { days: [] };
    this._loadLog();
    this._today = this._ensureToday();
    this._applyToday();
    this._sel = 0;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this._sensor = null;
    this._timer = null;
    this._tickCount = 0;
    this._dwellIdx = -1;
    this._dwellTicks = 0;        // 250ms ticks accumulated inside the cone
    this._dwellFrozen = false;   // DEMO holds the seeded display state
    this._dayDoneSpoken = false;
    this._demo = false;
    this._demoDate = '';
    this._demoBaseMin = 16 * 60 + 10;
    this._realItems = null;
    this._realSel = 0;
    this._realToday = null;
    this._lastSpeak = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
    this._recompute();
    this._checkDue();
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
    this._savePlan();
    this._saveLog();
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
    // Nod discipline: a steady nod only ever confirms the SELECTED
    // item, and only while you are actually facing its registered
    // heading (the object's direction) with a steady head. A nod
    // never edits the plan (no MARK, no TIME) and never confirms
    // an item you are not looking at.
    if (this.data.busy) return;
    var i = this._sel;
    var it = this._items[i];
    if (!it || it.done) {
      this.setData({ lastEvent: 'EVT: nod ignored - selected item already confirmed' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    if (it.headingDeg === null || this._heading === null ||
        Math.abs(this._rel(it.headingDeg, this._heading)) > 25) {
      this.setData({ lastEvent: 'EVT: nod ignored - not facing the selected item object' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod = confirm (facing its object, steady)' });
    this._confirm(i, 'nod');
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier §3.2.1): single tap arrives as Enter,
  // double-tap as Backspace, swipe as ArrowUp/ArrowDown. The daily
  // flow (pick an item, confirm it, hear the day) runs on these
  // keys + head-steady + nod; MARK / TIME are one-time family
  // setup actions and stay on their buttons on purpose.
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
  // all confirmed -> speak the day summary; selected item not yet
  // confirmed -> confirm it by tap (same as the DONE button);
  // selected item already confirmed -> move to the next unconfirmed.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._doneCount() >= 6) { this.speakTap(); return; }
    var it = this._items[this._sel];
    if (it.done) {
      var nx = this._nextUndone(this._sel);
      if (nx >= 0) {
        this._sel = nx;
        this.setData({ lastEvent: 'EVT: tap -> next unconfirmed: ' + this._items[nx].label });
        this._recompute();
      }
      return;
    }
    this.doneTap();
  },

  _moveSel(dir) {
    this._sel = (((this._sel + dir) % 6) + 6) % 6;
    this.setData({ lastEvent: 'EVT: swipe -> select ' + this._items[this._sel].label });
    this._recompute();
  },

  // ---------- the day plan (family presets, fixed labels this build) ----------

  _defaultPlan() {
    // Labels and the family's spoken lines are FIXED presets in
    // this build; only the times step (+-30min via TIME) and the
    // headings are adjustable. The spoken lines carry no dosage
    // and no advice - they are the family's own reminder words.
    return [
      { id: 'med-am', label: '早晨吃药', time: '08:00', object: '药瓶',
        say: '八点了，早晨的药。吃过了，看着药瓶确认一下。',
        cue: '看着药瓶：这一顿吃过了，就确认',
        headingDeg: null, headingDemo: false, done: false, doneTime: '', doneHow: '' },
      { id: 'water', label: '上午喝水', time: '10:00', object: '水杯',
        say: '十点了，喝杯水。喝完看着水杯确认一下。',
        cue: '看着水杯：这一杯水喝过了，就确认',
        headingDeg: null, headingDemo: false, done: false, doneTime: '', doneHow: '' },
      { id: 'lunch', label: '午饭', time: '12:00', object: '餐桌',
        say: '十二点了，吃午饭。吃完看着餐桌确认一下。',
        cue: '看着餐桌：午饭吃过了，就确认',
        headingDeg: null, headingDemo: false, done: false, doneTime: '', doneHow: '' },
      { id: 'med-pm', label: '下午吃药', time: '15:00', object: '药瓶',
        say: '三点了，下午的药。吃过了，看着药瓶确认一下。',
        cue: '看着药瓶：这一顿吃过了，就确认',
        headingDeg: null, headingDemo: false, done: false, doneTime: '', doneHow: '' },
      { id: 'walk', label: '傍晚散步', time: '17:00', object: '大门',
        say: '五点了，出去散散步。回来确认一下。',
        cue: '看着大门：出去散过步了，就确认',
        headingDeg: null, headingDemo: false, done: false, doneTime: '', doneHow: '' },
      { id: 'doors', label: '睡前门窗', time: '21:00', object: '大门',
        say: '九点了，看一看门窗关好没有。看完确认一下。',
        cue: '看着大门和窗：都关好了，就确认',
        headingDeg: null, headingDemo: false, done: false, doneTime: '', doneHow: '' }
    ];
  },

  _doneCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._items[i].done) n++;
    return n;
  },

  _nextUndone(from) {
    for (var k = 1; k !== 7; k++) {
      var i = (from + k) % 6;
      if (!this._items[i].done) return i;
    }
    return -1;
  },

  _timeMin(item) {
    var p = String(item.time || '00:00').split(':');
    var h = parseInt(p[0], 10), m = parseInt(p[1], 10);
    if (!isFinite(h) || !isFinite(m)) return 0;
    return h * 60 + m;
  },

  // An item is DUE when its preset time has arrived (or passed)
  // and it is not confirmed yet. Confirmed items are never due,
  // however early they were confirmed.
  _isDue(i, nowMin) {
    var it = this._items[i];
    if (it.done) return false;
    return nowMin >= this._timeMin(it);
  },

  _dueList(nowMin) {
    var out = [];
    for (var i = 0; i !== 6; i++) if (this._isDue(i, nowMin)) out.push(i);
    return out;
  },

  // ---------- persistence (wx sync storage, TEXT ONLY) ----------
  // elderDayPlan: the family's preset schedule + headings.
  // elderDayLog:  per-date confirmations, newest first, <= 7 days.

  _loadPlan() {
    try {
      var raw = wx.getStorageSync('elderDayPlan');
      if (!raw || typeof raw !== 'object' ||
          Object.prototype.toString.call(raw.items) !== '[object Array]') return;
      for (var i = 0; i !== raw.items.length; i++) {
        var r = raw.items[i];
        if (!r || typeof r.id !== 'string') continue;
        for (var j = 0; j !== 6; j++) {
          if (this._items[j].id !== r.id) continue;
          var it = this._items[j];
          if (typeof r.time === 'string' && /^\d{2}:\d{2}$/.test(r.time)) {
            var mm = this._timeMin({ time: r.time });
            if (mm % 30 === 0) it.time = r.time;
          }
          if (isFinite(r.headingDeg)) {
            it.headingDeg = ((Math.round(r.headingDeg) % 360) + 360) % 360;
            it.headingDemo = !!r.headingDemo;
          }
          break;
        }
      }
      // Same-object share default: an item with no heading of its
      // own inherits the heading of a same-object sibling (the two
      // medicine items share the pill bottle's direction).
      for (var a = 0; a !== 6; a++) {
        if (this._items[a].headingDeg !== null) continue;
        for (var b = 0; b !== 6; b++) {
          if (b !== a && this._items[b].object === this._items[a].object &&
              this._items[b].headingDeg !== null) {
            this._items[a].headingDeg = this._items[b].headingDeg;
            this._items[a].headingDemo = this._items[b].headingDemo;
            break;
          }
        }
      }
    } catch (e) { /* storage unreadable on this host: defaults stand */ }
  },

  _savePlan() {
    if (this._demo) return; // DEMO is a simulation: never persist it
    try {
      var items = [];
      for (var i = 0; i !== 6; i++) {
        var it = this._items[i];
        items.push({
          id: it.id, label: it.label, time: it.time, object: it.object,
          say: it.say, headingDeg: it.headingDeg, headingDemo: !!it.headingDemo
        });
      }
      wx.setStorageSync('elderDayPlan', { items: items });
    } catch (e) { /* storage unavailable on this host: plan stays in memory */ }
  },

  _loadLog() {
    try {
      var raw = wx.getStorageSync('elderDayLog');
      if (!raw || typeof raw !== 'object' ||
          Object.prototype.toString.call(raw.days) !== '[object Array]') return;
      var days = [];
      for (var i = 0; i !== raw.days.length && days.length !== 7; i++) {
        var d = raw.days[i];
        if (!d || typeof d.date !== 'string') continue;
        var entries = [];
        if (Object.prototype.toString.call(d.entries) === '[object Array]') {
          for (var k = 0; k !== d.entries.length; k++) {
            var e = d.entries[k];
            if (e && typeof e.id === 'string') {
              entries.push({
                id: e.id,
                time: typeof e.time === 'string' ? e.time : '',
                how: typeof e.how === 'string' ? e.how : ''
              });
            }
          }
        }
        var announced = [];
        if (Object.prototype.toString.call(d.announced) === '[object Array]') {
          for (var q = 0; q !== d.announced.length; q++) {
            if (typeof d.announced[q] === 'string') announced.push(d.announced[q]);
          }
        }
        days.push({ date: d.date, entries: entries, announced: announced });
      }
      this._log = { days: days };
    } catch (e) { /* storage unreadable on this host: start with an empty log */ }
  },

  _saveLog() {
    if (this._demo) return; // DEMO never writes the real day record
    try {
      wx.setStorageSync('elderDayLog', this._log);
    } catch (e) { /* storage unavailable on this host: log stays in memory */ }
  },

  // Find (or start) today's record. A new date gets a FRESH record;
  // older dates are kept, at most 7 days in total.
  _ensureToday() {
    var today = this._nowInfo().date;
    for (var i = 0; i !== this._log.days.length; i++) {
      if (this._log.days[i].date === today) return this._log.days[i];
    }
    var rec = { date: today, entries: [], announced: [] };
    this._log.days.unshift(rec);
    while (this._log.days.length > 7) this._log.days.pop();
    this._saveLog();
    return rec;
  },

  _applyToday() {
    for (var i = 0; i !== this._today.entries.length; i++) {
      var e = this._today.entries[i];
      for (var j = 0; j !== 6; j++) {
        if (this._items[j].id === e.id) {
          this._items[j].done = true;
          this._items[j].doneTime = e.time;
          this._items[j].doneHow = e.how;
        }
      }
    }
    this._dayDoneSpoken = this._doneCount() >= 6;
  },

  // ---------- clock ----------

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // ONE clock read -> {date, minutes, hhmm} as pure values. In
  // DEMO the clock is the seeded snapshot (16:10 on the snapshot's
  // date, advanced only by accumulated ticks), so seeded dates and
  // times never drift apart the way repeated Date reads do on the
  // preview host.
  _nowInfo() {
    if (this._demo) {
      var mins = this._demoBaseMin + Math.floor((this._tickCount || 0) / 240);
      return { date: this._demoDate, minutes: mins, hhmm: this._minToHhmm(mins) };
    }
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      minutes: d.getHours() * 60 + d.getMinutes(),
      hhmm: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
  },

  _minToHhmm(mins) {
    var m = ((mins % 1440) + 1440) % 1440;
    return this._pad2(Math.floor(m / 60)) + ':' + this._pad2(m % 60);
  },

  _headText(h) {
    return (h === null || h === undefined || !isFinite(h)) ? '---' : String(Math.round(h));
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
  // 'reading'), advance the dwell state machine on accumulated
  // tick counts, and run the due check every 120 ticks (30s).
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

  _tick() {
    this._tickCount = (this._tickCount || 0) + 1;
    // Date rollover while the page stays open: a fresh day starts,
    // yesterday's record stays in the log.
    if (!this._demo) {
      var today = this._nowInfo().date;
      if (this._today && this._today.date !== today) {
        for (var i = 0; i !== 6; i++) {
          this._items[i].done = false;
          this._items[i].doneTime = '';
          this._items[i].doneHow = '';
        }
        this._today = this._ensureToday();
        this._dayDoneSpoken = false;
        this.setData({ lastEvent: 'EVT: new day ' + today + ' - fresh list, old record kept' });
      }
    }
    this._dwellTick();
    if (this._tickCount % 120 === 0) this._checkDue();
    if (this._tickCount % 4 === 0) this._recompute();
  },

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

  // The unconfirmed item your gaze is on right now: registered
  // heading within the +-25 deg cone. Nearest wins.
  _coneItem() {
    if (this._heading === null) return -1;
    var best = -1, bestAbs = 26;
    for (var i = 0; i !== 6; i++) {
      if (this._items[i].done) continue;
      var h = this._items[i].headingDeg;
      if (h === null) continue;
      var a = Math.abs(this._rel(h, this._heading));
      if (a <= 25 && a < bestAbs) { best = i; bestAbs = a; }
    }
    return best;
  },

  // ---------- dwell state machine (the LOOK confirm) ----------

  _resetDwell() {
    this._dwellIdx = -1;
    this._dwellTicks = 0;
  },

  // Coverage rule (same as DI30/DI43): gaze inside an unconfirmed
  // item's +-25 deg cone AND head steady, continuously for 2000ms
  // = 8 ticks of 250ms. Leaving the cone, switching items, or
  // moving the head resets the count - a fast sweep earns nothing.
  _dwellTick() {
    if (this._dwellFrozen) return; // DEMO holds the seeded display state
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
        status: 'LOOKED ✓ ' + this._items[i].label + ' (gaze 2s)',
        lastEvent: 'EVT: ' + this._items[i].label + ' confirmed by 2s gaze dwell'
      });
      this._confirm(i, 'gaze');
      return;
    }
    this._recompute();
  },

  // ---------- confirm (methods recorded honestly) ----------

  // Confirming means: you looked at the object and say it is done.
  // The agent cannot verify the medicine was swallowed or the door
  // is really locked - and it never gives medical advice, dosage
  // logic, or missed-dose guidance (same restraint as DI31).
  _confirm(i, how) {
    var it = this._items[i];
    if (it.done) return;
    it.done = true;
    it.doneHow = how;
    it.doneTime = this._nowInfo().hhmm;
    if (!this._demo) {
      this._today.entries.push({ id: it.id, time: it.doneTime, how: how });
      this._saveLog();
    }
    if (this._doneCount() >= 6) {
      this._finishDay();
    } else {
      if (this._sel === i) {
        var nx = this._nextUndone(i);
        if (nx >= 0) this._sel = nx;
      }
      this._recompute();
    }
  },

  _finishDay() {
    this._recompute();
    if (this._dayDoneSpoken) return;
    this._dayDoneSpoken = true;
    this.setData({
      status: 'DAY DONE — 今天六件事都确认完了',
      lastEvent: 'EVT: all six confirmed - day summary spoken once'
    });
    this._speakText(this._statusText());
    this._recompute();
  },

  // ---------- due check (runs on load + every 30s tick) ----------

  // An item whose time has arrived and is still unconfirmed is
  // announced ONCE per day: the family's preset line for that
  // item, read verbatim. It then stays DUE on screen until it is
  // confirmed; it is never re-shouted (SPEAK re-reads on demand).
  // The announcement is recorded in today's log, so closing and
  // reopening the page does not announce it again.
  _checkDue() {
    var now = this._nowInfo();
    var fresh = [];
    for (var i = 0; i !== 6; i++) {
      var it = this._items[i];
      if (!this._isDue(i, now.minutes)) continue;
      if (this._today.announced.indexOf(it.id) >= 0) continue;
      this._today.announced.push(it.id);
      fresh.push(i);
    }
    if (!fresh.length) return;
    this._saveLog();
    for (var k = 0; k !== fresh.length; k++) {
      var idx = fresh[k];
      this._speakText(this._items[idx].say);
      this.setData({
        status: 'DUE: ' + this._items[idx].label + ' ' + this._items[idx].time + ' 还没确认',
        lastEvent: 'EVT: DUE announced once: ' + this._items[idx].label +
          ' (family preset line, verbatim)' + (this._demo ? ' (DEMO)' : '')
      });
    }
    this._recompute();
  },

  // ---------- MARK: bind the selected item to your current heading ----------

  markTap() {
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
    this._items[i].headingDemo = !!this._demo;
    // Same-object siblings with no heading of their own inherit
    // this direction (both medicine items look at the same bottle).
    var shared = [];
    for (var j = 0; j !== 6; j++) {
      if (j !== i && this._items[j].object === this._items[i].object &&
          this._items[j].headingDeg === null) {
        this._items[j].headingDeg = h;
        this._items[j].headingDemo = !!this._demo;
        shared.push(this._items[j].label);
      }
    }
    this._savePlan();
    this.setData({
      status: 'MARKED: ' + this._items[i].label + ' (' + this._items[i].object + ') @ ' + h + ' deg',
      lastEvent: 'EVT: heading bound ' + this._items[i].label + ' at ' + h + ' deg' +
        (shared.length ? ' · shared with ' + shared.join('、') + ' (same ' +
          this._items[i].object + ')' : '') +
        (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._recompute();
  },

  // ---------- TIME: step the selected item's preset time (+30min) ----------

  // Family setup: times move in 30-minute steps only - there is
  // no free-text time entry in this build, so a time can never be
  // mistyped. Labels and spoken lines stay the fixed presets.
  timeTap() {
    if (this.data.busy) return;
    var i = this._sel;
    var it = this._items[i];
    var next = (this._timeMin(it) + 30) % 1440;
    it.time = this._minToHhmm(next);
    this._savePlan();
    this.setData({
      status: 'TIME: ' + it.label + ' -> ' + it.time + ' (tap TIME for +30min)',
      lastEvent: 'EVT: preset time stepped ' + it.label + ' to ' + it.time +
        (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._checkDue();
    this._recompute();
  },

  // ---------- DONE: tap-confirm the selected item ----------

  doneTap() {
    if (this.data.busy) return;
    var i = this._sel;
    if (this._items[i].done) {
      this.setData({
        status: this._items[i].label + ' already confirmed ' + this._items[i].doneTime,
        lastEvent: 'EVT: DONE ignored - already confirmed (no double record)'
      });
      return;
    }
    this.setData({
      status: 'DONE ✓ ' + this._items[i].label + ' (by tap)',
      lastEvent: 'EVT: ' + this._items[i].label + ' confirmed by tap - recorded as tap'
    });
    this._confirm(i, 'tap');
  },

  // ---------- LIST: jump to the next unconfirmed item ----------

  listTap() {
    var nx = this._nextUndone(this._sel);
    if (nx < 0) {
      this.setData({
        status: 'ALL 6 CONFIRMED - SPEAK reads the day',
        lastEvent: 'EVT: LIST - nothing left unconfirmed'
      });
      this._recompute();
      return;
    }
    this._sel = nx;
    this.setData({
      lastEvent: 'EVT: LIST -> next unconfirmed: ' + this._items[nx].label
    });
    this._recompute();
  },

  // ---------- speech (TTS out; lang is never set) ----------

  _statusText() {
    var done = this._doneCount();
    if (done >= 6) return '今天六件事都确认完了。';
    var now = this._nowInfo();
    var t = '今天六件事，确认了' + done + '件。';
    for (var i = 0; i !== 6; i++) {
      var it = this._items[i];
      if (it.done) continue;
      t += it.label + '，' + it.time + (this._isDue(i, now.minutes) ? '，到时间了' : '') +
        '，还没确认。';
    }
    return t;
  },

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
    if (this.data.busy) return;
    var s = this._lastSpeak;
    var text = s ? s.text : this._statusText();
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  },

  // ---------- DEMO (seeded mid-day, memory only - toggles off) ----------

  // DEMO seeds "today" at 16:10 from ONE Date snapshot: morning
  // medicine / water / lunch are confirmed (gaze, tap, gaze), the
  // 15:00 medicine is DUE and announced once, and the demo head
  // rests at 60 deg facing the water cup. Headings: bottle 350,
  // cup 60, table 120, door 200. Further taps step the heading
  // +45 deg; the tap after a full circle exits DEMO and restores
  // the real plan, day record and selection untouched - DEMO
  // never writes storage.
  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._realItems = this._items;
      this._realSel = this._sel;
      this._realToday = this._today;
      var snap = new Date(); // ONE snapshot: all demo seeds derive from it
      this._demoDate = snap.getFullYear() + '-' + this._pad2(snap.getMonth() + 1) +
        '-' + this._pad2(snap.getDate());
      this._demoBaseMin = 16 * 60 + 10;
      this._demoSteps = 0;
      this._demo = true;
      this._demoHeading = 60;
      this._heading = 60;
      this._headingSrc = 'DEMO';
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY' });
      this._items = this._defaultPlan();
      var hs = [350, 60, 120, 350, 200, 200];
      for (var i = 0; i !== 6; i++) {
        this._items[i].headingDeg = hs[i];
        this._items[i].headingDemo = true;
      }
      var doneSeeds = [
        { i: 0, how: 'gaze', time: '08:04' },
        { i: 1, how: 'tap', time: '10:12' },
        { i: 2, how: 'gaze', time: '12:20' }
      ];
      // Seed today's demo record directly (DEMO writes nothing to
      // storage; confirmations live in memory for the demo only).
      this._today = { date: this._demoDate, entries: [], announced: [] };
      for (var k = 0; k !== doneSeeds.length; k++) {
        var ds = doneSeeds[k];
        this._items[ds.i].done = true;
        this._items[ds.i].doneHow = ds.how;
        this._items[ds.i].doneTime = ds.time;
        this._today.entries.push({ id: this._items[ds.i].id, time: ds.time, how: ds.how });
      }
      this._dayDoneSpoken = false;
      this._sel = 3; // the DUE medicine item, so its banner shows
      this._dwellFrozen = true;
      this._resetDwell();
      this.setData({
        status: 'DEMO TODAY 16:10 - 3/6 done · 下午吃药 DUE',
        lastEvent: 'EVT: DEMO on - seeded day in memory only, nothing saved'
      });
      this._recompute();
      // 15:00 medicine is due at 16:10: announces once, and its
      // DUE event line is the one left standing.
      this._checkDue();
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
    this.setData({
      status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
    });
    this._recompute();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._items = this._realItems || this._defaultPlan();
    this._sel = this._realSel || 0;
    this._today = this._realToday || this._ensureToday();
    this._realItems = null;
    this._realToday = null;
    this._dwellFrozen = false;
    this._resetDwell();
    this._dayDoneSpoken = this._doneCount() >= 6;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._steady = false;
    this.setData({ steadyText: 'HEAD: moving - hold still' });
    this._startHeading();
    this.setData({
      status: 'DEMO OFF - your real day is back',
      lastEvent: 'EVT: DEMO off - real plan and record restored, nothing was written'
    });
    this._recompute();
  },

  // ---------- rendering ----------

  _recompute() {
    var now = this._nowInfo();
    var done = this._doneCount();
    var due = this._dueList(now.minutes);
    var sel = this._items[this._sel];
    var patch = {
      clockLine: 'TIME ' + now.hhmm + (this._demo ? ' (DEMO)' : '') +
        ' · HEAD: ' + this._headText(this._heading) + ' deg · SRC: ' +
        this._headingSrc + (this._demo ? ' (DEMO)' : ''),
      progLine: 'TODAY: ' + done + '/6 DONE · DUE ' + due.length,
      dayLine: 'DAY: ' + (this._today ? this._today.date : '-') +
        ' · text record on this device only',
      focusName: '▸ ' + sel.label + ' (' + (this._sel + 1) + '/6)',
      focusCue: sel.cue
    };
    var self = this;
    patch.rows = this._items.map(function (it, i) {
      var reg = it.headingDeg === null ? 'no heading' : 'reg ' + it.headingDeg + '°';
      var mark;
      if (it.done) mark = '✓ ' + it.doneHow + ' ' + it.doneTime;
      else if (self._isDue(i, now.minutes)) mark = '! DUE 还没确认';
      else if (self._dwellIdx === i) {
        mark = '◎ dwell ' + (self._dwellTicks * 250 / 1000).toFixed(1) + 's';
      } else mark = '○ 待确认';
      var cur = i === self._sel ? '▸ ' : '';
      return { text: cur + it.label + ' · ' + it.time + ' · ' + it.object +
        ' · ' + mark + ' · ' + reg };
    });

    // Guide box: about the SELECTED item.
    if (done >= 6) {
      patch.guideLine = 'DAY DONE — 六件事都确认完了 · SPEAK 听汇总';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._statusText() };
    } else if (sel.done) {
      patch.guideLine = '✓ 已确认 by ' + sel.doneHow + ' ' + sel.doneTime +
        ' — swipe for the next item';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._statusText() };
    } else if (this._isDue(this._sel, now.minutes)) {
      patch.guideLine = '! DUE ' + sel.time + ' 还没确认 — 看着' + sel.object +
        '停满 2 秒，或点 DONE';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._statusText() };
    } else if (this._dwellIdx === this._sel && this._dwellTicks > 0) {
      patch.guideLine = 'DWELL ' + (this._dwellTicks * 250 / 1000).toFixed(1) +
        's / 2s — hold still, look at the ' + sel.object;
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: this._statusText() };
    } else if (sel.headingDeg === null) {
      patch.guideLine = 'NO HEADING — family setup: look at the ' + sel.object +
        ', tap MARK once';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._statusText() };
    } else if (this._heading === null) {
      patch.guideLine = 'HEADING N/A (SRC NONE) — find the ' + sel.object +
        ' by eye, DONE to confirm';
      patch.guideCls = 'rel';
      this._lastSpeak = { text: this._statusText() };
    } else {
      var rel = this._rel(sel.headingDeg, this._heading);
      var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
      var rel360 = (sel.headingDeg - this._heading + 360) % 360;
      patch.guideLine = arrows[Math.round(rel360 / 45) % 8] + ' TURN: ' +
        this._dirName(rel).en + ' ' + Math.round(Math.abs(rel)) + '° — ' +
        sel.object + ' reg ' + sel.headingDeg + '°' +
        (Math.abs(rel) <= 25 ? ' · IN VIEW: hold still 2s' : '');
      patch.guideCls = Math.abs(rel) <= 25 ? 'rel rel-on' : 'rel';
      this._lastSpeak = { text: this._statusText() };
    }
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">ELDER DAY</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{clockLine}} · {{steadyText}}</text>
      <text class="remind">{{remindLine}}</text>
    </view>
    <view class="prog-box">
      <text class="prog">{{progLine}}</text>
      <text class="stay">{{dayLine}}</text>
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
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="doneTap">DONE</button>
      <button class="btn" bindtap="markTap">MARK</button>
      <button class="btn" bindtap="timeTap">TIME</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="listTap">LIST</button>
      <button class="btn btn-main" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">确认 = 你看过并说做完；我没法核对 · no medical advice 不是医疗建议</text>
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
.remind {
  color: #40ff5e;
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
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
  height: 101px;
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
.foot2 {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
