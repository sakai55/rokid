<script def>
{
  "navigationBarTitleText": "Home Find"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'STORE: look at the spot, say ITEM + CLUE, SAVE',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: STORE · ROOM: 客厅',
    itemLine: 'ITEM: 护照 · tap ITEM, say what it is',
    clueLine: 'CLUE: 柜子抽屉 · tap CLUE, say where exactly',
    photoLine: 'PHOTO: none - LOOK = record copy only',
    countLine: 'STORED: 0/12 · stored on this device only',
    rows: [
      { text: '(nothing stored) - SAVE one here, or DEMO' }
    ],
    memoryLine: '护照 → ---',
    arrow: '·',
    relLine: 'GUIDE: switch to FIND after saving',
    relCls: 'rel',
    lastEvent: 'EVT: headings fit where you stood - re-check near the spot',
    busy: false
  },

  onLoad() {
    this._mode = 'STORE';
    this._itemIdx = 0;
    this._roomIdx = 0;
    this._clueIdx = 0;
    this._findIdx = 0;
    this._pendingItem = this._presetItems()[0];
    this._pendingClue = this._presetClues()[0];
    this._itemTag = '';
    this._clueTag = '';
    this._records = this._loadRecords();
    this._rec = null;
    this._stream = null;
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
    this._stopRec();
    this._stopStream();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopRec();
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
    if (this._mode === 'STORE') {
      if (this._steady) this.saveTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to SAVE' });
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
      // Keys cannot speak: arrows cycle the same selections the
      // ITEM button reaches (presets in STORE, stored items in FIND).
      if (this._mode === 'STORE') this._cycleItemPreset();
      else this._cycleFind();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'STORE') this.saveTap(); else this.speakTap();
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

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // ONE clock snapshot -> {date, time} as pure strings. Related
  // values (a batch of DEMO seeds, a record's date + time) always
  // come from a single snapshot: the preview host's Date is
  // virtualised and drifts between calls (lesson from DI25), so
  // sampling Date repeatedly for related values can split them.
  _stamp() {
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      time: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
  },

  // ---------- vocab ----------

  _presetItems() { return ['护照', '备用钥匙', '工具箱', '药盒', '充电器']; },
  _rooms() { return ['客厅', '卧室', '书房', '厨房', '玄关', '阳台']; },
  _presetClues() { return ['柜子抽屉', '架子第二层', '盒子里', '门后挂钩']; },
  _room() { return this._rooms()[this._roomIdx || 0]; },

  // ---------- persistence (wx sync storage, key 'homeFind', max 12) ----------

  _loadRecords() {
    try {
      var raw = wx.getStorageSync('homeFind');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 12; i++) {
        var r = raw[i];
        if (r && typeof r.item === 'string' && typeof r.room === 'string' &&
            typeof r.clue === 'string' && isFinite(r.heading) &&
            typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            item: String(r.item).slice(0, 12),
            room: String(r.room).slice(0, 8),
            clue: String(r.clue).slice(0, 16),
            heading: ((Math.round(r.heading) % 360) + 360) % 360,
            date: String(r.date).slice(0, 10),
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
      wx.setStorageSync('homeFind', this._records || []);
    } catch (e) { /* storage unavailable on this host: records stay in memory */ }
  },

  // Re-storing the same item REPLACES its old record: you moved it,
  // the newest spot wins. Beyond 12 records the oldest is dropped.
  _addRecord(rec) {
    var arr = (this._records || []).filter(function (r) { return r.item !== rec.item; });
    arr.push(rec);
    while (arr.length > 12) arr.shift();
    this._records = arr;
    this._saveRecords();
  },

  // ---------- heading (AbsoluteOrientationSensor, same as find-my-thing) ----------

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

  // ---------- modes: STORE <-> FIND ----------

  modeTap() {
    this._mode = this._mode === 'STORE' ? 'FIND' : 'STORE';
    this.setData({
      status: this._mode === 'STORE'
        ? 'STORE: look at the spot, say ITEM + CLUE, SAVE'
        : 'FIND: ITEM picks a thing, turn to its heading',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  // ---------- ITEM / CLUE: one-shot ASR verbatim, preset fallback ----------

  _stopRec() {
    if (this._rec) {
      try { this._rec.abort(); } catch (e) {}
      this._rec = null;
    }
  },

  _cycleItemPreset() {
    this._itemIdx = ((this._itemIdx || 0) + 1) % this._presetItems().length;
    this._pendingItem = this._presetItems()[this._itemIdx];
    this._itemTag = 'preset';
    this.setData({ lastEvent: 'EVT: item preset -> ' + this._pendingItem });
    this._recompute();
  },

  _cycleCluePreset() {
    this._clueIdx = ((this._clueIdx || 0) + 1) % this._presetClues().length;
    this._pendingClue = this._presetClues()[this._clueIdx];
    this._clueTag = 'preset';
    this.setData({ lastEvent: 'EVT: clue preset -> ' + this._pendingClue });
    this._recompute();
  },

  _cycleFind() {
    var n = (this._records || []).length;
    if (!n) {
      this.setData({ lastEvent: 'EVT: nothing stored yet - STORE first or DEMO' });
      return;
    }
    this._findIdx = ((this._findIdx || 0) + 1) % n;
    this.setData({ lastEvent: 'EVT: find -> ' + this._records[this._findIdx].item });
    this._recompute();
  },

  itemTap() {
    if (this._mode === 'FIND') { this._cycleFind(); return; }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. ITEM falls back to
      // cycling the preset items instead of pretending to listen.
      this._cycleItemPreset();
      this.setData({
        status: 'ITEM preset - ASR SKIP on this host',
        lastEvent: 'EVT: ITEM preset (honest SKIP, no ASR)'
      });
      return;
    }
    this._listen('item');
  },

  clueTap() {
    if (this._mode !== 'STORE') {
      this.setData({ lastEvent: 'EVT: CLUE only applies in STORE mode' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      this._cycleCluePreset();
      this.setData({
        status: 'CLUE preset - ASR SKIP on this host',
        lastEvent: 'EVT: CLUE preset (honest SKIP, no ASR)'
      });
      return;
    }
    this._listen('clue');
  },

  async _listen(target) {
    var self = this;
    var label = target === 'item' ? 'ITEM' : 'CLUE';
    this.setData({ busy: true, status: label + ': checking wearer mic...' });
    // Wearer-mode mic check (documented getUserMedia audio constraints,
    // same pattern as market-radar DI21): the 4-mic array in 'wearer'
    // mode prioritises YOUR voice. The stream only verifies the mode
    // opens; recognition uses the benchmark SpeechRecognition.
    var micNote = 'wearer mic not checked';
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
        micNote = 'wearer mic OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        micNote = 'wearer mic check FAIL - ' + this._err(e);
      }
    }
    try {
      this._stopRec();
      var rec = new SpeechRecognition();
      this._rec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // Stored VERBATIM, exactly as heard, and shown on screen so
          // the wearer eyeballs it BEFORE SAVE. The glasses never
          // quietly "correct" a misheard item or clue.
          if (target === 'item') {
            self._pendingItem = txt.slice(0, 12);
            self._itemTag = 'heard';
          } else {
            self._pendingClue = txt.slice(0, 16);
            self._clueTag = 'heard';
          }
          self.setData({
            status: label + ' heard - eyeball it, then SAVE',
            lastEvent: 'EVT: ' + label.toLowerCase() + ' heard (' + micNote + ') - verify before SAVE'
          });
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: label + ' FAIL - tap ' + label + ' again',
          lastEvent: 'EVT: ' + label + ' ASR error - ' + self._err(ev.error || ev)
        });
      };
      rec.onend = function () {
        if (self._rec === rec) self._rec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: label + ' listening (' + micNote + ')',
        lastEvent: 'EVT: ' + label + ' listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        status: label + ' FAIL - recogniser would not start',
        lastEvent: 'EVT: ' + label + ' start failed - ' + this._err(e)
      });
    }
  },

  roomTap() {
    if (this._mode !== 'STORE') {
      this.setData({ lastEvent: 'EVT: ROOM only applies in STORE mode' });
      return;
    }
    this._roomIdx = ((this._roomIdx || 0) + 1) % this._rooms().length;
    this.setData({ lastEvent: 'EVT: room -> ' + this._room() });
    this._recompute();
  },

  // ---------- SAVE (STORE only; refuses without a heading) ----------

  saveTap() {
    if (this._mode !== 'STORE') {
      this.setData({ lastEvent: 'EVT: SAVE only applies in STORE mode' });
      return;
    }
    if (this._heading === null) {
      // Same honesty rule as find-my-thing DI07: never invent a
      // heading. A spot without a direction is a note, not a memory.
      this.setData({
        status: 'SAVE FAIL: no heading (SRC NONE) - DEMO or wait for sensor',
        lastEvent: 'EVT: SAVE refused - never invent a heading'
      });
      return;
    }
    var st = this._stamp();
    var rec = {
      item: this._pendingItem,
      room: this._room(),
      clue: this._pendingClue,
      heading: Math.round(this._heading),
      date: st.date,
      time: st.time,
      demo: !!this._demo
    };
    var replaced = (this._records || []).some(function (r) { return r.item === rec.item; });
    this._addRecord(rec);
    for (var i = 0; i !== this._records.length; i++) {
      if (this._records[i].item === rec.item) this._findIdx = i;
    }
    this.setData({
      status: 'SAVED: ' + rec.item + ' · ' + rec.room + ' · ' + rec.heading + '°' +
        (replaced ? ' (old spot replaced)' : ''),
      lastEvent: 'EVT: stored ' + rec.item + ' at heading ' + rec.heading +
        ' deg' + (rec.demo ? ' (DEMO heading)' : '') + (replaced ? ' - replaced old record' : '')
    });
    this._recompute();
  },

  clearTap() {
    this._records = [];
    this._findIdx = 0;
    this._saveRecords();
    this.setData({
      status: this._mode === 'STORE'
        ? 'STORE: look at the spot, say ITEM + CLUE, SAVE'
        : 'FIND: nothing stored - STORE first or DEMO',
      lastEvent: 'EVT: all stored spots cleared'
    });
    this._recompute();
  },

  // ---------- LOOK: default-mode photo of the spot (record only) ----------

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
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; the words still save',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default) - aim at the storage spot...' });
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
        photoLine: 'PHOTO: ' + photoBytes + 'B - default - record copy only, never read',
        status: 'PHOTO kept as your copy - now say ITEM + CLUE, SAVE',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like receipt-keeper DI25.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record copy only',
          status: 'PHOTO kept as your copy - now say ITEM + CLUE, SAVE',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo; the words still save',
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

  // ---------- DEMO ----------

  // DEMO stores 3 labeled items (passport 210 / spare key 40 /
  // medicine box 300 deg) and enters FIND on the passport. All three
  // dates/times derive from ONE clock snapshot as pure strings, so
  // they can never drift apart on the virtualised preview clock.
  // Further taps step the simulated heading +45 deg: at 225 deg the
  // passport spot (210 deg) is -15 deg off and FACING THE SPOT lights.
  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      // Re-entering DEMO replaces older demo records instead of piling up.
      this._records = (this._records || []).filter(function (r) { return !r.demo; });
      var st = this._stamp();
      this._addRecord({ item: '护照', room: '书房', clue: '书柜第二层', heading: 210, date: st.date, time: st.time, demo: true });
      this._addRecord({ item: '备用钥匙', room: '玄关', clue: '门后挂钩', heading: 40, date: st.date, time: st.time, demo: true });
      this._addRecord({ item: '药盒', room: '卧室', clue: '床头柜抽屉', heading: 300, date: st.date, time: st.time, demo: true });
      for (var i = 0; i !== this._records.length; i++) {
        if (this._records[i].item === '护照') this._findIdx = i;
      }
      this._mode = 'FIND';
      this.setData({
        status: 'DEMO FIND: 3 stored - DEMO steps heading +45',
        lastEvent: 'EVT: DEMO on - 3 items stored, mode FIND on 护照'
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

  // ---------- guidance (same geometry as find-my-thing DI07) ----------

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _findRecord() {
    var recs = this._records || [];
    if (!recs.length) return null;
    var idx = this._findIdx || 0;
    if (idx >= recs.length) idx = 0;
    return recs[idx];
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · ROOM: ' + this._room(),
      itemLine: 'ITEM: ' + this._pendingItem +
        (this._itemTag === 'heard' ? ' (heard - check it)' :
          (this._itemTag === 'preset' ? ' (preset)' : ' · tap ITEM, say what it is')),
      clueLine: 'CLUE: ' + this._pendingClue +
        (this._clueTag === 'heard' ? ' (heard - check it)' :
          (this._clueTag === 'preset' ? ' (preset)' : ' · tap CLUE, say where exactly'))
    };
    var recs = this._records || [];
    if (!recs.length) {
      patch.rows = [{ text: '(nothing stored) - SAVE one here, or DEMO' }];
    } else {
      patch.rows = recs.map(function (r) {
        return {
          text: r.item + ' · ' + r.room + ' · ' + r.clue + ' · ' + r.heading + '° · ' +
            r.date.slice(5) + ' ' + r.time + (r.demo ? ' DEMO' : '')
        };
      });
    }
    patch.countLine = 'STORED: ' + recs.length + '/12 · stored on this device only';

    var rec = this._findRecord();
    if (!rec) {
      patch.arrow = '·';
      patch.memoryLine = '--- → ---';
      patch.relLine = 'GUIDE: no stored item selected';
      patch.relCls = 'rel';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    // The memory clue, big: item -> room, spoken clue, stored heading.
    patch.memoryLine = rec.item + ' → ' + rec.room + ' · ' + rec.clue +
      ' · 朝向 ' + rec.heading + '° 登记';
    if (this._heading === null) {
      patch.arrow = '·';
      patch.relLine = 'GUIDE: heading n/a - SRC NONE, tap DEMO';
      patch.relCls = 'rel';
      this._lastSpeak = { rec: rec, facing: false, zh: '', deg: 0 };
      this.setData(patch);
      return;
    }
    var rel = ((rec.heading - this._heading + 540) % 360) - 180; // -180..180, + = right
    var rel360 = (rec.heading - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    var facing = Math.abs(rel) <= 15;
    if (facing) {
      patch.relLine = 'FACING THE SPOT — look there';
      patch.relCls = 'rel rel-on';
    } else {
      patch.relLine = 'TURN: ' + dir.en + ' ' + deg + '° to face the spot';
      patch.relCls = 'rel';
    }
    this._lastSpeak = { rec: rec, facing: facing, zh: dir.zh, deg: deg };
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
      if (!s || !s.rec) {
        text = '还没有收纳记录。先看着收纳处，说出物品和位置，点保存。';
      } else {
        var r = s.rec;
        text = r.item + '在' + r.room + '，' + r.clue + '。你当时站在' + r.room +
          '朝向 ' + r.heading + ' 度登记的。';
        if (s.facing) {
          text += '你现在正对着当时登记的方向，在那附近找找。';
        } else if (s.zh) {
          text += '回到' + r.room + '当时站的位置附近，向你' + s.zh + '转' + s.deg +
            '度，就对着当时登记的方向。';
        } else {
          text += '现在没有你的朝向读数，先看演示或等传感器。';
        }
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
      <text class="title">HOME FIND</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="store-box">
      <text class="mode">{{modeLine}}</text>
      <text class="item">{{itemLine}}</text>
      <text class="clue">{{clueLine}}</text>
      <text class="photo">{{photoLine}}</text>
      <text class="count">{{countLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="find-box">
      <text class="memory">{{memoryLine}}</text>
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{relCls}}">{{relLine}}</text>
      </view>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="itemTap">ITEM</button>
      <button class="btn" bindtap="roomTap">ROOM</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="clueTap">CLUE</button>
      <button class="btn btn-main" bindtap="saveTap">SAVE</button>
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
  padding: 6px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 3px;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: 500;
  line-height: 24px;
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
  font-size: 11px;
  line-height: 14px;
}
.store-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 10px;
  margin-bottom: 3px;
}
.mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
}
.item {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.clue {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.count {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
.list {
  height: 32px;
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
.find-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 3px;
  margin-bottom: 3px;
}
.memory {
  color: #40ff5e;
  font-size: 13px;
  font-weight: 500;
  line-height: 16px;
}
.guide-top {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.arrow {
  color: #40ff5e;
  font-size: 24px;
  line-height: 27px;
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
