<script def>
{
  "navigationBarTitleText": "Med Look"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'TODAY: MED picks a dose, nod = taken',
    steadyText: 'HEAD: moving',
    clockLine: 'TIME --:--',
    boxLabel: '◎ TODAY - the schedule YOU entered, from the prescription',
    bigLine: 'NO MEDS YET - tap MODE, build the table in SETUP',
    boxLine: 'PHOTO: none - LOOK = label record only, agent cannot read it',
    slotLine: 'SLOTS ~ 空腹7:00 · 早8:00 · 午13:00 · 晚19:00 · 睡前22:00',
    rows: [
      { text: '(empty table) - MODE to SETUP, or DEMO' }
    ],
    countLine: 'TABLE: 0/6 · TAKEN TODAY: 0/0',
    lastEvent: 'EVT: it never checks the bottle - your eyes match it',
    busy: false
  },

  onLoad() {
    this._mode = 'TODAY';
    this._table = this._loadTable();
    this._taken = this._loadTaken();
    this._selIdx = 0;
    this._pendName = '';
    this._doseIdx = 0;
    this._whenIdx = 0;
    this._presetIdx = -1;
    this._nameRec = null;
    this._stream = null;
    this._steady = false;
    this._timer = null;
    this._demo = false;
    this._demoMin = 0;
    this._speakText = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startTimer();
    this._recompute();
  },

  onShow() {
    this._startTimer();
    this._recompute();
  },

  onHide() {
    this._stopTimer();
    this._stopNameRec();
    this._stopStream();
  },

  onUnload() {
    this._stopTimer();
    this._stopNameRec();
    this._stopStream();
    this._saveTable();
    this._saveTaken();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving'
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
    // Steady nod = the primary hands-free action of the current mode:
    // TODAY it logs the picked dose taken; SETUP it adds the new entry.
    if (this._mode === 'TODAY') this.takeTap();
    else this.addTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      if (this._mode === 'TODAY') this.medTap();
      else this.whenTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'TODAY') this.takeTap();
      else this.addTap();
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

  _startTimer() {
    if (this._timer) return;
    var self = this;
    // Keep the due flags honest while the page stays open.
    this._timer = setInterval(function () { self._recompute(); }, 30000);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- vocab ----------

  _doses() { return ['1 片', '2 片', '1 粒', '半片']; },
  _dose() { return this._doses()[this._doseIdx || 0]; },
  _whens() { return ['早上空腹', '早饭后', '午饭后', '晚饭后', '睡前']; },
  _when() { return this._whens()[this._whenIdx || 0]; },
  _presets() { return ['降压药', '降糖药', '钙片', '维生素D']; },

  // Declared approximations: a slot counts as "due" once this hour of
  // the day has passed. Shown on screen (slotLine) - they are rough
  // meal anchors, not medical timing advice.
  _slotHour(when) {
    var map = { '早上空腹': 7, '早饭后': 8, '午饭后': 13, '晚饭后': 19, '睡前': 22 };
    return Object.prototype.hasOwnProperty.call(map, when) ? map[when] : 24;
  },

  // ---------- clock (real clock; DEMO simulates a labeled 09:30) ----------

  _nowDate() { return new Date(); },

  _dateStr(d) {
    var m = d.getMonth() + 1; if (m < 10) m = '0' + m;
    var day = d.getDate(); if (day < 10) day = '0' + day;
    return d.getFullYear() + '-' + m + '-' + day;
  },

  _todayStr() {
    // In DEMO, "today" is the snapshot's date string captured once in
    // demoTap - never a fresh Date sample (preview hosts virtualize
    // Date and successive samples can disagree about the day).
    if (this._demo && this._demoDate) return this._demoDate;
    return this._dateStr(this._nowDate());
  },

  _fmtHM(minOfDay) {
    var h = Math.floor(minOfDay / 60); if (h < 10) h = '0' + h;
    var m = minOfDay % 60; if (m < 10) m = '0' + m;
    return h + ':' + m;
  },

  _nowMin() {
    if (this._demo) return this._demoMin;
    var d = this._nowDate();
    return d.getHours() * 60 + d.getMinutes();
  },

  _nowTimeStr() { return this._fmtHM(this._nowMin()); },

  // ---------- schedule logic (pure; same code sanity-checked in Node) ----------

  // A dose is taken today iff the taken-log holds an entry with the
  // same name AND the same slot on today's date. A med scheduled
  // twice a day is two table entries; each slot matches separately.
  _takenEntry(entry, taken, todayStr) {
    for (var i = taken.length - 1; i >= 0; i--) {
      var t = taken[i];
      if (t.name === entry.name && t.when === entry.when && t.date === todayStr) return t;
    }
    return null;
  },

  // state: 'taken' | 'due' (slot passed, not taken) | 'later'
  _entryState(entry, taken, todayStr, nowMin) {
    var t = this._takenEntry(entry, taken, todayStr);
    if (t) return { state: 'taken', entry: t };
    var due = this._slotHour(entry.when) * 60 <= nowMin;
    return { state: due ? 'due' : 'later', entry: null };
  },

  _sortedTable(table) {
    var self = this;
    return (table || []).slice().sort(function (a, b) {
      var d = self._slotHour(a.when) - self._slotHour(b.when);
      if (d !== 0) return d;
      return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0);
    });
  },

  // ---------- persistence (wx sync storage) ----------

  _loadTable() {
    try {
      var raw = wx.getStorageSync('medTable');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var doses = this._doses(), whens = this._whens();
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 6; i++) {
        var r = raw[i];
        if (r && typeof r.name === 'string' && r.name &&
          doses.indexOf(r.dose) >= 0 && whens.indexOf(r.when) >= 0) {
          out.push({
            name: String(r.name).slice(0, 12),
            dose: r.dose, when: r.when, demo: !!r.demo
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveTable() {
    try {
      wx.setStorageSync('medTable', this._table || []);
    } catch (e) { /* storage unavailable on this host: table stays in memory */ }
  },

  _loadTaken() {
    try {
      var raw = wx.getStorageSync('medTaken');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var whens = this._whens();
      var out = [];
      for (var i = 0; i !== raw.length; i++) {
        var r = raw[i];
        if (r && typeof r.name === 'string' && r.name &&
          whens.indexOf(r.when) >= 0 &&
          typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            name: String(r.name).slice(0, 12),
            when: r.when,
            date: String(r.date).slice(0, 10),
            time: String(r.time).slice(0, 5),
            demo: !!r.demo
          });
        }
      }
      while (out.length > 60) out.shift();
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveTaken() {
    try {
      wx.setStorageSync('medTaken', this._taken || []);
    } catch (e) { /* storage unavailable on this host: log stays in memory */ }
  },

  // ---------- modes ----------

  modeTap() {
    this._mode = this._mode === 'TODAY' ? 'SETUP' : 'TODAY';
    this.setData({
      status: this._mode === 'SETUP'
        ? 'SETUP: NAME + DOSE + WHEN, then ADD (max 6)'
        : 'TODAY: MED picks a dose, nod = taken',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  // ---------- SETUP: name (ASR verbatim / presets), dose, when, add ----------

  _stopNameRec() {
    if (this._nameRec) {
      try { this._nameRec.abort(); } catch (e) {}
      this._nameRec = null;
    }
  },

  nameTap() {
    if (this._mode !== 'SETUP') {
      this.setData({ lastEvent: 'EVT: NAME applies in SETUP (tap MODE)' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. NAME falls back to
      // cycling generic preset categories (never real drug brands).
      this._presetIdx = ((this._presetIdx || 0) + 1) % this._presets().length;
      this._pendName = this._presets()[this._presetIdx];
      this.setData({
        status: 'NAME preset - ASR n/a on this host (SKIP)',
        lastEvent: 'EVT: NAME preset -> ' + this._pendName + ' (honest SKIP, no ASR)'
      });
      this._recompute();
      return;
    }
    this._nameListen();
  },

  async _nameListen() {
    var self = this;
    this.setData({ busy: true, status: 'NAME: checking wearer mic...' });
    // Wearer-mode mic check (documented pattern, same as market-radar):
    // verifies the 4-mic array opens in 'wearer' mode; recognition
    // itself uses the benchmark SpeechRecognition.
    var micNote = 'wearer mic not checked';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic');
        micNote = 'wearer mic OK';
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        micNote = 'wearer mic check FAIL - ' + this._err(e);
      }
    }
    try {
      this._stopNameRec();
      var rec = new SpeechRecognition();
      this._nameRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // The name is stored VERBATIM - what you said is what the
          // checklist will call it. Check it on screen before ADD.
          self._pendName = txt.slice(0, 12);
          self.setData({
            status: 'NAME heard: "' + self._pendName + '" - check it, then ADD',
            lastEvent: 'EVT: name heard (' + micNote + ') - verify before ADD'
          });
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'NAME FAIL - ' + self._err(ev.error || ev) + ', tap NAME again',
          lastEvent: 'EVT: NAME ASR error'
        });
      };
      rec.onend = function () {
        if (self._nameRec === rec) self._nameRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'NAME: listening - say the med name...',
        lastEvent: 'EVT: NAME listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        status: 'NAME FAIL - ' + this._err(e),
        lastEvent: 'EVT: NAME start failed'
      });
    }
  },

  doseTap() {
    if (this._mode !== 'SETUP') {
      this.setData({ lastEvent: 'EVT: DOSE applies in SETUP (tap MODE)' });
      return;
    }
    this._doseIdx = ((this._doseIdx || 0) + 1) % this._doses().length;
    this.setData({ lastEvent: 'EVT: dose -> ' + this._dose() + ' (from the prescription)' });
    this._recompute();
  },

  whenTap() {
    if (this._mode !== 'SETUP') {
      this.setData({ lastEvent: 'EVT: WHEN applies in SETUP (tap MODE)' });
      return;
    }
    this._whenIdx = ((this._whenIdx || 0) + 1) % this._whens().length;
    this.setData({ lastEvent: 'EVT: when -> ' + this._when() });
    this._recompute();
  },

  addTap() {
    if (this._mode !== 'SETUP') {
      this.setData({ lastEvent: 'EVT: ADD applies in SETUP (tap MODE)' });
      return;
    }
    if (!this._pendName) {
      this.setData({
        status: 'ADD FAIL: no name yet - tap NAME first',
        lastEvent: 'EVT: ADD refused - name is empty'
      });
      return;
    }
    var table = this._table || [];
    if (table.length >= 6) {
      this.setData({
        status: 'ADD FAIL: table full (6) - CLEAR in SETUP to rebuild',
        lastEvent: 'EVT: ADD refused - table full'
      });
      return;
    }
    for (var i = 0; i !== table.length; i++) {
      if (table[i].name === this._pendName && table[i].when === this._when()) {
        this.setData({
          status: 'ADD FAIL: ' + this._pendName + ' · ' + this._when() + ' already in table',
          lastEvent: 'EVT: ADD refused - duplicate name+slot'
        });
        return;
      }
    }
    table.push({
      name: this._pendName, dose: this._dose(), when: this._when(),
      demo: !!this._demo
    });
    this._table = table;
    this._saveTable();
    var added = this._pendName;
    this._pendName = '';
    this._presetIdx = -1;
    this.setData({
      status: 'ADDED: ' + added + ' - table ' + table.length + '/6',
      lastEvent: 'EVT: entry added - the table must match the prescription'
    });
    this._recompute();
  },

  // ---------- TODAY: pick, look, take ----------

  medTap() {
    if (this._mode !== 'TODAY') {
      this.setData({ lastEvent: 'EVT: MED applies in TODAY (tap MODE)' });
      return;
    }
    var n = (this._table || []).length;
    if (!n) {
      this.setData({ lastEvent: 'EVT: no meds yet - MODE to SETUP, or DEMO' });
      return;
    }
    this._selIdx = ((this._selIdx || 0) + 1) % n;
    var sorted = this._sortedTable(this._table);
    var e = sorted[this._selIdx];
    this.setData({ lastEvent: 'EVT: picked ' + e.name + ' · ' + e.when + ' - match the bottle in hand' });
    this._recompute();
  },

  _selected() {
    var sorted = this._sortedTable(this._table);
    if (!sorted.length) return null;
    var idx = this._selIdx || 0;
    if (idx >= sorted.length) idx = 0;
    return { entry: sorted[idx], sorted: sorted, idx: idx };
  },

  _stopStream() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  lookTap() { this._lookPhoto(); },

  async _lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'LOOK FAIL - no camera on this host, no photo taken',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOK: capturing label (telephoto)...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var bytes = 0;
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
        bytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this._photoLine = 'PHOTO: ' + bytes + 'B label copy - record only, not read';
      this.setData({
        status: 'LOOK OK: label photo ' + bytes + 'B (record only)',
        lastEvent: 'EVT: photo taken - YOU match the bottle to the entry'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / glasses-benchmark.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this._photoLine = 'PHOTO: ' + size + 'B label copy (wx fallback) - record only';
        this.setData({
          status: 'LOOK OK: wx label photo ' + size + 'B (record only)',
          lastEvent: 'EVT: wx photo taken - YOU match the bottle to the entry'
        });
      } catch (e2) {
        this.setData({
          status: 'LOOK FAIL - ' + this._err(firstErr) + ', no photo taken',
          lastEvent: 'EVT: LOOK FAIL'
        });
      }
    } finally {
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
      this._recompute();
    }
  },

  takeTap() {
    if (this._mode !== 'TODAY') {
      this.setData({ lastEvent: 'EVT: TAKE applies in TODAY (tap MODE)' });
      return;
    }
    var sel = this._selected();
    if (!sel) {
      this.setData({
        status: 'TAKE FAIL: no meds yet - MODE to SETUP, or DEMO',
        lastEvent: 'EVT: TAKE refused - table empty'
      });
      return;
    }
    var e = sel.entry;
    var today = this._todayStr();
    var nowMin = this._nowMin();
    var st = this._entryState(e, this._taken || [], today, nowMin);
    if (st.state === 'taken') {
      // Double-logging a dose is exactly the accident this agent
      // exists to prevent - refuse, and say when it was logged.
      this.setData({
        status: 'TAKE refused: ' + e.name + ' already logged ' + st.entry.time,
        lastEvent: 'EVT: TAKE refused - already taken today at ' + st.entry.time
      });
      return;
    }
    var rec = {
      name: e.name, when: e.when, date: today,
      time: this._nowTimeStr(), demo: !!this._demo
    };
    var taken = this._taken || [];
    taken.push(rec);
    while (taken.length > 60) taken.shift();
    this._taken = taken;
    this._saveTaken();
    var early = this._slotHour(e.when) * 60 > nowMin;
    this.setData({
      status: 'TAKEN ✓ ' + e.name + ' · ' + rec.time + (early ? ' (early - before its slot)' : ''),
      lastEvent: 'EVT: logged taken - ' + e.name + ' ' + e.dose + ' at ' + rec.time
    });
    this._recompute();
  },

  clearTap() {
    if (this._mode === 'SETUP') {
      this._table = [];
      this._selIdx = 0;
      this._pendName = '';
      this._presetIdx = -1;
      this._saveTable();
      this.setData({
        status: 'SETUP: table cleared - rebuild it from the prescription',
        lastEvent: 'EVT: med table cleared'
      });
    } else {
      var today = this._todayStr();
      this._taken = (this._taken || []).filter(function (t) { return t.date !== today; });
      this._saveTaken();
      this.setData({
        status: 'TODAY: today\'s taken log cleared - history kept',
        lastEvent: 'EVT: today taken entries cleared'
      });
    }
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO seeds a 3-med table plus one dose already taken this morning,
  // all derived from ONE Date snapshot: the date is the snapshot's real
  // date as a pure string; taken time '06:58' and the simulated clock
  // 09:30 are fixed strings of the simulation (labeled DEMO on screen).
  // At 09:30 the 早饭后 dose (slot 08:00) is due and untaken -> 待服.
  demoTap() {
    var snap = this._nowDate();
    var today = this._dateStr(snap);
    this._demo = true;
    this._demoMin = 9 * 60 + 30;
    this._demoDate = today;
    // Re-entering DEMO replaces older demo rows instead of piling up.
    this._table = (this._table || []).filter(function (r) { return !r.demo; });
    this._table.push({ name: '维生素D', dose: '1 粒', when: '早上空腹', demo: true });
    this._table.push({ name: '降压药', dose: '1 片', when: '早饭后', demo: true });
    this._table.push({ name: '降糖药', dose: '1 片', when: '晚饭后', demo: true });
    this._saveTable();
    this._taken = (this._taken || []).filter(function (t) { return !t.demo; });
    this._taken.push({
      name: '维生素D', when: '早上空腹', date: today, time: '06:58', demo: true
    });
    this._saveTaken();
    this._mode = 'TODAY';
    // Land on the due entry so the preview shows 待服 right away.
    var sorted = this._sortedTable(this._table);
    this._selIdx = 0;
    for (var i = 0; i !== sorted.length; i++) {
      if (sorted[i].name === '降压药' && sorted[i].when === '早饭后') this._selIdx = i;
    }
    this.setData({
      status: 'DEMO TODAY (clock 09:30 simulated): 1 taken, 1 due',
      lastEvent: 'EVT: DEMO on - sample table from the prescription card'
    });
    this._recompute();
  },

  // ---------- view ----------

  _recompute() {
    var today = this._todayStr();
    var nowMin = this._nowMin();
    var taken = this._taken || [];
    var table = this._table || [];
    var patch = {
      clockLine: 'TIME ' + this._fmtHM(nowMin) + (this._demo ? ' · DEMO clock (simulated)' : '')
    };

    if (this._mode === 'SETUP') {
      patch.boxLabel = '◎ SETUP - enter the table FROM THE PRESCRIPTION';
      patch.bigLine = this._pendName
        ? 'NEW: ' + this._pendName + ' · ' + this._dose() + ' · ' + this._when()
        : 'NEW: (no name) · ' + this._dose() + ' · ' + this._when() + ' - tap NAME';
      patch.boxLine = 'NAME is spoken, kept verbatim - check before ADD';
      if (!table.length) {
        patch.rows = [{ text: '(table empty) - NAME a med, then ADD' }];
      } else {
        patch.rows = this._sortedTable(table).map(function (e) {
          return { text: e.when + ' · ' + e.name + ' · ' + e.dose + (e.demo ? ' DEMO' : '') };
        });
      }
      var takenToday = 0;
      for (var i = 0; i !== taken.length; i++) if (taken[i].date === today) takenToday++;
      patch.countLine = 'TABLE: ' + table.length + '/6 · TAKEN TODAY: ' + takenToday;
      this._speakText = table.length
        ? '服药表里有' + table.length + '条。' + this._sortedTable(table).map(function (e) {
            return e.name + '，' + e.when + '，' + e.dose + '。';
          }).join('')
        : '服药表是空的。先照着处方把药名、剂量和时段建好。';
      this.setData(patch);
      return;
    }

    // TODAY mode
    patch.boxLabel = '◎ TODAY - the schedule YOU entered, from the prescription';
    patch.boxLine = this._photoLine || 'PHOTO: none - LOOK = label record only, agent cannot read it';
    var sel = this._selected();
    if (!sel) {
      patch.bigLine = 'NO MEDS YET - tap MODE, build the table in SETUP';
      patch.rows = [{ text: '(empty table) - MODE to SETUP, or DEMO' }];
      patch.countLine = 'TABLE: 0/6 · TAKEN TODAY: 0/0';
      this._speakText = '服药表是空的。先到设置里照着处方建表，或者点演示看一遍。';
      this.setData(patch);
      return;
    }
    var sorted = sel.sorted;
    var dueCount = 0, takenCount = 0;
    var self = this;
    patch.rows = sorted.map(function (e, i) {
      var st = self._entryState(e, taken, today, nowMin);
      var mark;
      if (st.state === 'taken') {
        takenCount++;
        mark = '✓ 已服 ' + st.entry.time;
      } else if (st.state === 'due') {
        dueCount++;
        mark = '! 待服（未服）';
      } else {
        mark = '未到时间';
      }
      var hh = self._slotHour(e.when); if (hh < 10) hh = '0' + hh;
      return {
        text: (i === sel.idx ? '▶ ' : '  ') + hh + ':00 ' + e.when + ' · ' + e.name +
          ' ' + e.dose + ' · ' + mark + (e.demo ? ' DEMO' : '')
      };
    });
    var cur = sel.entry;
    var cst = this._entryState(cur, taken, today, nowMin);
    patch.bigLine = cur.name + ' — ' + cur.when + ' · ' + cur.dose +
      (cst.state === 'taken' ? ' · ✓ ' + cst.entry.time
        : (cst.state === 'due' ? ' · 待服' : ' · 未到时间'));
    patch.countLine = 'TABLE: ' + table.length + '/6 · TAKEN TODAY: ' + takenCount + '/' + table.length +
      ' · DUE: ' + dueCount;

    // Chinese summary for SPEAK: what is still to take today.
    var rest = [];
    for (var j = 0; j !== sorted.length; j++) {
      var s2 = this._entryState(sorted[j], taken, today, nowMin);
      if (s2.state !== 'taken') {
        rest.push(sorted[j].when + '的' + sorted[j].name + '，' + sorted[j].dose +
          (s2.state === 'due' ? '，现在待服' : '') + '。');
      }
    }
    this._speakText = rest.length
      ? '今天还要服' + rest.length + '个：' + rest.join('')
      : '今天表上的药都已经登记服过了。';

    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text = this._speakText || '还没有内容。先建服药表。';
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
      <text class="title">MED LOOK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{clockLine}} · {{steadyText}}</text>
    </view>
    <view class="rule-box">
      <text class="rule-label">{{boxLabel}}</text>
      <text class="big">{{bigLine}}</text>
      <text class="photo">{{boxLine}}</text>
      <text class="photo">{{slotLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <text class="count">{{countLine}}</text>
    <view class="actions">
      <button class="btn" bindtap="nameTap">NAME</button>
      <button class="btn" bindtap="doseTap">DOSE</button>
      <button class="btn" bindtap="whenTap">WHEN</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="addTap">ADD</button>
      <button class="btn" bindtap="medTap">MED</button>
      <button class="btn btn-main" bindtap="takeTap">TAKE ✓</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
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
.rule-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.rule-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.big {
  color: #40ff5e;
  font-size: 14px;
  line-height: 19px;
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
  margin-bottom: 3px;
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
