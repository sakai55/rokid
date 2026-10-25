<script def>
{
  "navigationBarTitleText": "Meter Reader"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'READ: LOOK the dial, say the number, check, SAVE',
    steadyText: 'HEAD: moving - hold still',
    meterLine: 'METER: 电表 · unit 度 · tap METER to change',
    readLine: 'READ: --- · tap READ, say the dial number',
    heardLine: 'HEARD: --- (readings are never auto-saved)',
    photoLine: 'PHOTO: none - LOOK = record copy only',
    countLine: 'HISTORY: 0/36 readings · this device only',
    rows: [
      { text: '(no readings) - READ one here, or DEMO' }
    ],
    usageLine: 'USAGE: --- · two readings make a period',
    anomalyLine: 'COMPARE: ---',
    lastEvent: 'EVT: the dial is never read - you say the number',
    busy: false
  },

  onLoad() {
    this._mode = 'READ';
    this._meterIdx = 1; // 电表
    this._entries = this._loadEntries();
    this._pendingRead = null;
    this._overrideNew = false;
    this._readRec = null;
    this._stream = null;
    this._steady = false;
    this._demo = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._recompute();
  },

  onShow() {},

  onHide() {
    this._stopReadRec();
    this._stopStream();
  },

  onUnload() {
    this._stopReadRec();
    this._stopStream();
    this._saveEntries();
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
    // A nod NEVER saves. Saving is SAVE button / Enter only, so a
    // misheard dial number can never slip into the history hands-free.
    // A steady nod reads the pending value / usage back instead.
    if (this._steady) this.speakTap();
    else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to hear it read back' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.meterTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'READ') this.saveTap(); else this.speakTap();
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

  _nowTime() {
    var d = new Date();
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
  },

  _dateStr(d) {
    return d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate());
  },

  // Date string straight from parts - no Date construction, so a
  // batch of seeds derived from one snapshot can never drift apart
  // (preview host's Date is virtualized and drifts between samples).
  _dateStrParts(y, m0, day) {
    return y + '-' + this._pad2(m0 + 1) + '-' + this._pad2(day);
  },

  // A date n months before the snapshot (y, m0), day clamped to 28 -
  // pure part arithmetic from ONE snapshot, never a second sample.
  _dateMonthsAgoParts(y, m0, day, n) {
    var total = y * 12 + m0 - n;
    var yy = Math.floor(total / 12);
    var mm = total - yy * 12;
    return this._dateStrParts(yy, mm, Math.min(day, 28));
  },

  _todayStr() { return this._dateStr(new Date()); },

  // Dial value display: 8620 stays 8620, 1234.5 stays 1234.5.
  _fmtVal(n) {
    var v = Math.round((+n || 0) * 100) / 100;
    return String(v);
  },

  // ---------- meters ----------

  _meters() { return ['水表', '电表', '燃气表']; },
  _units() { return ['吨', '度', '立方米']; },
  _meter() { return this._meters()[this._meterIdx || 0]; },
  _unit() { return this._units()[this._meterIdx || 0]; },
  _leakHint() {
    return { '水表': '查漏水', '电表': '查漏电/待机耗电', '燃气表': '查漏气' }[this._meter()] || '去检查一下';
  },

  meterTap() {
    this._meterIdx = ((this._meterIdx || 0) + 1) % this._meters().length;
    this._pendingRead = null;
    this._overrideNew = false;
    this.setData({
      readLine: 'READ: --- · tap READ, say the dial number',
      heardLine: 'HEARD: --- (readings are never auto-saved)',
      status: (this._mode === 'READ' ? 'READ' : 'USAGE') + ': ' + this._meter() + ' selected',
      lastEvent: 'EVT: meter -> ' + this._meter()
    });
    this._recompute();
  },

  // ---------- persistence (wx sync storage, key 'meterReadings', cap 36) ----------

  _loadEntries() {
    try {
      var raw = wx.getStorageSync('meterReadings');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 36; i++) {
        var r = raw[i];
        if (r && this._meters().indexOf(r.meter) >= 0 && isFinite(r.value) &&
            typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            meter: String(r.meter),
            value: Math.round(+r.value * 100) / 100,
            date: String(r.date).slice(0, 10),
            time: String(r.time).slice(0, 5),
            demo: !!r.demo,
            baseline: !!r.baseline
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveEntries() {
    try {
      wx.setStorageSync('meterReadings', this._entries || []);
    } catch (e) { /* storage unavailable on this host: readings stay in memory */ }
  },

  // Cap 36 readings across all meters: beyond that the OLDEST is
  // dropped. The history is the memory of the house - keep it local.
  _addEntry(entry) {
    var arr = this._entries || [];
    arr.push(entry);
    while (arr.length > 36) arr.shift();
    this._entries = arr;
    this._saveEntries();
  },

  _forMeter(meter) {
    return (this._entries || []).filter(function (e) { return e.meter === meter; });
  },

  _latestFor(meter) {
    var arr = this._forMeter(meter);
    return arr.length ? arr[arr.length - 1] : null;
  },

  // ---------- usage / anomaly math (values only, never the clock) ----------

  // Periods for one meter, aligned by reading index: per[i] is the
  // period ENDING at reading i, or null when reading i starts a
  // segment (the first reading, or a baseline = meter replacement -
  // the new meter starts from its own zero-ish world, and nothing
  // is ever compared across the swap). A negative usage (should be
  // impossible: SAVE blocks lower readings) is kept but invalid.
  _periods(meter) {
    var arr = this._forMeter(meter);
    var per = [];
    for (var i = 0; i < arr.length; i++) {
      if (i === 0 || arr[i].baseline) { per.push(null); continue; }
      var usage = Math.round((arr[i].value - arr[i - 1].value) * 100) / 100;
      per.push({ from: arr[i - 1], to: arr[i], usage: usage, valid: usage >= 0 });
    }
    return per;
  },

  // Anomaly rule: latest valid period vs the valid period right
  // before it IN THE SAME SEGMENT (same physical meter, unbroken
  // chain). Flag only when the swing is MORE than +/-50% (exactly
  // 50% is not flagged) and the previous usage is positive (a 0
  // base has no meaningful percentage). This is a "go check"
  // prompt - it never claims to know WHY usage changed.
  _usageInfo(meter) {
    var arr = this._forMeter(meter);
    var per = this._periods(meter);
    var latestIdx = -1;
    for (var i = per.length - 1; i >= 0; i--) {
      if (per[i] && per[i].valid) { latestIdx = i; break; }
    }
    var latest = latestIdx >= 0 ? per[latestIdx] : null;
    var prev = null;
    if (latest) {
      var segStart = 0;
      for (var j = latestIdx; j >= 0; j--) {
        if (j === 0 || arr[j].baseline) { segStart = j; break; }
      }
      var pIdx = latestIdx - 1;
      if (pIdx > segStart && per[pIdx] && per[pIdx].valid) prev = per[pIdx];
    }
    var info = {
      count: arr.length,
      latestReading: arr.length ? arr[arr.length - 1] : null,
      latestUsage: latest ? latest.usage : null,
      prevUsage: prev ? prev.usage : null,
      pct: null,
      anomaly: false
    };
    if (latest && prev && prev.usage > 0) {
      info.pct = Math.round((latest.usage - prev.usage) / prev.usage * 100);
      info.anomaly = info.pct > 50 || info.pct < -50;
    }
    return info;
  },

  _usageText() {
    var info = this._usageInfo(this._meter());
    var u = this._unit();
    if (info.count < 2 || info.latestUsage === null) {
      return this._meter() + '的读数还不够，先后记两次读数才能算用量。';
    }
    var text = this._meter() + '本期用量' + this._fmtVal(info.latestUsage) + u + '。';
    if (info.prevUsage !== null) {
      text += '上期' + this._fmtVal(info.prevUsage) + u + '。';
    }
    if (info.anomaly) {
      text += '用量异常，比上期' + (info.pct > 0 ? '多' : '少') +
        Math.abs(info.pct) + '%，' + this._leakHint() + '。';
    } else if (info.pct !== null) {
      text += '用量平稳。';
    }
    return text;
  },

  // ---------- reading parser (spoken dial number -> value) ----------

  _cnDigits() {
    return { '零': 0, '一': 1, '幺': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9 };
  },

  _digitOf(ch) {
    if (ch >= '0' && ch <= '9') return ch.charCodeAt(0) - 48;
    var D = this._cnDigits();
    return Object.prototype.hasOwnProperty.call(D, ch) ? D[ch] : null;
  },

  // Chinese/Arabic integer up to 万 (八千三百二十一 / 8千3百21 /
  // 一万二千三百四十五). A single Chinese digit right after a unit
  // takes the next place down (二百五 = 250); an Arabic digit run is
  // already the full tail value (三百21 = 321). Null on unknown.
  _cnInt(str) {
    if (!str) return null;
    var D = this._cnDigits();
    var U = { '十': 10, '百': 100, '千': 1000, '万': 10000 };
    var result = 0, section = 0, pending = null, pendingScale = 1, seen = false;
    var prevUnit = 0;
    var i = 0;
    while (i < str.length) {
      var ch = str.charAt(i);
      if (ch >= '0' && ch <= '9') {
        var run = '';
        while (i < str.length && str.charAt(i) >= '0' && str.charAt(i) <= '9') {
          run += str.charAt(i); i++;
        }
        pending = parseInt(run, 10);
        pendingScale = 1;
        prevUnit = 0;
        seen = true;
      } else if (Object.prototype.hasOwnProperty.call(D, ch)) {
        pending = D[ch];
        pendingScale = prevUnit ? prevUnit / 10 : 1;
        prevUnit = 0;
        seen = true;
        i++;
      } else if (ch === '万') {
        section = (section + (pending === null ? 1 : pending)) * 10000;
        result += section; section = 0; pending = null; prevUnit = 0; seen = true;
        i++;
      } else if (Object.prototype.hasOwnProperty.call(U, ch)) {
        section += (pending === null ? 1 : pending) * U[ch];
        pending = null; prevUnit = U[ch]; seen = true;
        i++;
      } else {
        return null;
      }
    }
    if (!seen) return null;
    return result + section + (pending === null ? 0 : pending * pendingScale);
  },

  _validReading(v) {
    if (v === null || v === undefined || !isFinite(v)) return null;
    if (v < 0 || v > 99999999) return null;
    return Math.round(v * 100) / 100;
  },

  // Parse a dictated dial reading. Two spoken shapes:
  //  - digit by digit: "一二三四五" / "12345" / "幺二三四五" - every
  //    char is a digit, so concatenate (this also covers 一零二三).
  //  - as a number: "八千三百二十一" / "九万九千九百九十九".
  // An optional decimal tail follows 点 or '.' ("...点五" = .5).
  // Anything unparsable returns null - never guess a dial number.
  _parseReading(raw) {
    if (!raw) return null;
    var s = String(raw).replace(/[\s　]/g, '').replace(/[,，]/g, '');
    s = s.replace(/^(读数是|读数|表数是|表数|现在是|现在|显示)/, '');
    s = s.replace(/(吨|立方米|度|方|个字)$/, '');
    if (!s) return null;

    var dotIdx = -1;
    for (var i = 0; i < s.length; i++) {
      var c = s.charAt(i);
      if (c === '点' || c === '.') { dotIdx = i; break; }
    }
    var intStr = dotIdx >= 0 ? s.slice(0, dotIdx) : s;
    var fracStr = dotIdx >= 0 ? s.slice(dotIdx + 1) : '';
    if (!intStr) return null;

    var intVal = null;
    var allDigits = intStr.length > 0;
    for (var j = 0; j < intStr.length; j++) {
      if (this._digitOf(intStr.charAt(j)) === null) { allDigits = false; break; }
    }
    if (allDigits) {
      var digs = '';
      for (var k = 0; k < intStr.length; k++) digs += String(this._digitOf(intStr.charAt(k)));
      intVal = parseInt(digs, 10);
    } else {
      intVal = this._cnInt(intStr);
      if (intVal === null) return null;
    }

    var frac = 0;
    if (fracStr) {
      var fd = [];
      for (var m = 0; m < fracStr.length; m++) {
        var d = this._digitOf(fracStr.charAt(m));
        if (d === null) return null;
        fd.push(d);
      }
      for (var n = 0; n < fd.length; n++) frac += fd[n] / Math.pow(10, n + 1);
    }
    return this._validReading(intVal + frac);
  },

  // ---------- LOOK: telephoto record photo (never read, no OCR) ----------

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
        status: 'LOOK FAIL - no camera here; just say the number',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto) - aim at the dial...' });
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
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B - telephoto - record copy only, never read',
        status: 'PHOTO kept as your copy - now tap READ and say the number',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / receipt-keeper.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record copy only',
          status: 'PHOTO kept as your copy - now tap READ and say the number',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo; the history does not need one',
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

  // ---------- READ: one-shot ASR dictation of the dial number ----------

  _stopReadRec() {
    if (this._readRec) {
      try { this._readRec.abort(); } catch (e) {}
      this._readRec = null;
    }
  },

  readTap() {
    if (this._mode !== 'READ') {
      this.setData({ lastEvent: 'EVT: READ only applies in READ mode' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host - never pretend to listen.
      this.setData({
        heardLine: 'HEARD: SKIP - ASR n/a on this host, nothing heard',
        status: 'READ SKIP - no ASR here (DEMO shows the history)',
        lastEvent: 'EVT: READ honest SKIP, no SpeechRecognition'
      });
      return;
    }
    this._readListen();
  },

  async _readListen() {
    var self = this;
    this.setData({ busy: true, heardLine: 'HEARD: checking wearer mic...' });
    // Wearer-mode mic check (documented getUserMedia audio constraints,
    // same pattern as receipt-keeper #25): the 4-mic array in 'wearer'
    // mode prioritises YOUR voice over the meter-room echo. The stream
    // only verifies the mode opens; recognition uses SpeechRecognition.
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
      this._stopReadRec();
      var rec = new SpeechRecognition();
      this._readRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // The heard text is parsed, then shown BIG for the wearer to
          // eyeball. Nothing is saved until SAVE is tapped.
          var val = self._parseReading(txt);
          if (val === null) {
            self._pendingRead = null;
            self.setData({
              heardLine: 'HEARD: "' + txt.slice(0, 20) + '" - parse FAIL',
              readLine: 'READ: ??? - parse FAIL, say it again',
              status: 'PARSE FAIL - re-say the number, digit by digit',
              lastEvent: 'EVT: reading parse FAIL on "' + txt.slice(0, 14) + '"'
            });
          } else {
            self._pendingRead = val;
            self.setData({
              heardLine: 'HEARD: "' + txt.slice(0, 20) + '" -> ' + self._fmtVal(val),
              readLine: 'READ: ' + self._fmtVal(val) + ' ' + self._unit() + ' - eyeball it, then SAVE',
              status: 'READ heard - check the number, FINE-fix or SAVE',
              lastEvent: 'EVT: reading ' + self._fmtVal(val) + ' pending (' + micNote + ')'
            });
          }
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          heardLine: 'HEARD: FAIL - ' + self._err(ev.error || ev) + ', tap READ again',
          status: 'READ FAIL - try again, slower, digit by digit',
          lastEvent: 'EVT: READ ASR error'
        });
      };
      rec.onend = function () {
        if (self._readRec === rec) self._readRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        heardLine: 'HEARD: listening - say the dial number...',
        status: 'READ listening (' + micNote + ')',
        lastEvent: 'EVT: READ listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        heardLine: 'HEARD: FAIL - ' + this._err(e),
        status: 'READ FAIL - recogniser would not start',
        lastEvent: 'EVT: READ start failed'
      });
    }
  },

  // ---------- FINE: correct a near-miss parse (-1 / +1 / +10) ----------

  _fine(delta) {
    if (this._mode !== 'READ') {
      this.setData({ lastEvent: 'EVT: FINE only applies in READ mode' });
      return;
    }
    if (this._pendingRead === null) {
      this.setData({
        status: 'FINE: no reading yet - tap READ and say the number first',
        lastEvent: 'EVT: FINE refused - nothing to adjust'
      });
      return;
    }
    var v = this._validReading(Math.round((this._pendingRead + delta) * 100) / 100);
    if (v === null) {
      this.setData({ lastEvent: 'EVT: FINE refused - value out of range' });
      return;
    }
    this._pendingRead = v;
    this.setData({
      readLine: 'READ: ' + this._fmtVal(v) + ' ' + this._unit() + ' - eyeball it, then SAVE',
      status: 'READ adjusted by FINE - check it, then SAVE',
      lastEvent: 'EVT: FINE ' + (delta > 0 ? '+' : '') + delta + ' -> ' + this._fmtVal(v)
    });
    this._recompute();
  },

  fineM1Tap() { this._fine(-1); },
  fineP1Tap() { this._fine(1); },
  fineP10Tap() { this._fine(10); },

  // ---------- NEW METER: arm the replacement-baseline override ----------

  newMeterTap() {
    this._overrideNew = !this._overrideNew;
    this.setData({
      status: this._overrideNew
        ? 'NEW METER ON: next SAVE = fresh baseline (no usage vs old meter)'
        : 'NEW METER OFF: normal save rules apply',
      lastEvent: 'EVT: meter-changed override ' + (this._overrideNew ? 'ARMED' : 'off')
    });
    this._recompute();
  },

  // ---------- SAVE (explicit confirm only; lower readings blocked) ----------

  saveTap() {
    if (this._mode !== 'READ') {
      this.setData({ lastEvent: 'EVT: SAVE only applies in READ mode' });
      return;
    }
    if (this._pendingRead === null) {
      this.setData({
        status: 'SAVE FAIL: no reading - tap READ and say the number first',
        lastEvent: 'EVT: SAVE refused - nothing pending, nothing saved'
      });
      return;
    }
    var meter = this._meter();
    var latest = this._latestFor(meter);
    // A dial never runs backwards. A lower number means the ASR
    // misheard (most likely) or the meter was replaced - block it
    // and say so plainly, unless the wearer armed NEW METER, which
    // stores the value as a fresh baseline instead of a "usage".
    if (latest && this._pendingRead < latest.value && !this._overrideNew) {
      this.setData({
        status: 'SAVE BLOCKED: ' + this._fmtVal(this._pendingRead) + ' < 上次 ' +
          this._fmtVal(latest.value) + ' — 听错了？换表点 NEW METER',
        lastEvent: 'EVT: SAVE blocked - lower than last ' + this._fmtVal(latest.value)
      });
      return;
    }
    var entry = {
      meter: meter,
      value: this._pendingRead,
      date: this._todayStr(),
      time: this._nowTime(),
      demo: !!this._demo,
      baseline: !!this._overrideNew
    };
    this._addEntry(entry);
    this._pendingRead = null;
    var wasBaseline = this._overrideNew;
    this._overrideNew = false;
    this.setData({
      status: 'SAVED ' + meter + ' ' + this._fmtVal(entry.value) + ' ' + this._unit() +
        (wasBaseline ? ' (new meter baseline)' : ' - next meter?'),
      heardLine: 'HEARD: saved ' + this._fmtVal(entry.value) + ' ' + this._unit() +
        (entry.demo ? ' DEMO' : ''),
      readLine: 'READ: --- · tap READ, say the dial number',
      lastEvent: 'EVT: reading saved ' + meter + ' ' + this._fmtVal(entry.value)
    });
    this._recompute();
  },

  // ---------- modes: READ <-> USAGE ----------

  modeTap() {
    this._mode = this._mode === 'READ' ? 'USAGE' : 'READ';
    this.setData({
      status: this._mode === 'READ'
        ? 'READ: LOOK the dial, say the number, check, SAVE'
        : 'USAGE: this period vs last - SPEAK reads it',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  clearTap() {
    this._entries = [];
    this._saveEntries();
    this._pendingRead = null;
    this._overrideNew = false;
    this._mode = 'READ';
    this.setData({
      status: 'READ: LOOK the dial, say the number, check, SAVE',
      heardLine: 'HEARD: --- (readings are never auto-saved)',
      readLine: 'READ: --- · tap READ, say the dial number',
      lastEvent: 'EVT: history cleared (all readings, all meters)'
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO seeds two meters from ONE clock snapshot, all dates derived
  // as pure strings (the preview host's Date drifts between samples;
  // a single snapshot keeps the seed months internally consistent).
  // 电表: 8120 -> 8350 -> 8620 (usage 230 then 270, +17%, normal).
  // 水表: 320 -> 340 -> 384 (usage 20 then 44, +120%, ANOMALY).
  // Lands on USAGE with 水表 selected so the anomaly renders.
  demoTap() {
    this._demo = true;
    this._entries = (this._entries || []).filter(function (e) { return !e.demo; });
    var now = new Date();
    var t = this._pad2(now.getHours()) + ':' + this._pad2(now.getMinutes());
    var y = now.getFullYear(), m0 = now.getMonth(), dd = now.getDate();
    var d2 = this._dateMonthsAgoParts(y, m0, dd, 2);
    var d1 = this._dateMonthsAgoParts(y, m0, dd, 1);
    var d0 = this._dateStrParts(y, m0, dd);
    this._addEntry({ meter: '电表', value: 8120, date: d2, time: t, demo: true, baseline: false });
    this._addEntry({ meter: '水表', value: 320, date: d2, time: t, demo: true, baseline: false });
    this._addEntry({ meter: '电表', value: 8350, date: d1, time: t, demo: true, baseline: false });
    this._addEntry({ meter: '水表', value: 340, date: d1, time: t, demo: true, baseline: false });
    this._addEntry({ meter: '电表', value: 8620, date: d0, time: t, demo: true, baseline: false });
    this._addEntry({ meter: '水表', value: 384, date: d0, time: t, demo: true, baseline: false });
    this._pendingRead = null;
    this._overrideNew = false;
    this._meterIdx = 0; // 水表 - the anomaly
    this._mode = 'USAGE';
    this.setData({
      status: 'USAGE: DEMO history - 水表 anomaly flagged below',
      lastEvent: 'EVT: DEMO seeded 电表 x3 + 水表 x3 - USAGE view'
    });
    this._recompute();
  },

  // ---------- recompute view ----------

  _recompute() {
    var meter = this._meter();
    var unit = this._unit();
    var info = this._usageInfo(meter);
    var arr = this._forMeter(meter);
    var patch = {
      meterLine: 'METER: ' + meter + ' · unit ' + unit + ' · tap METER to change' +
        (this._overrideNew ? ' · NEW METER ARMED' : ''),
      countLine: 'HISTORY: ' + (this._entries || []).length + '/36 readings · this device only'
    };
    if (info.latestUsage === null) {
      patch.usageLine = 'USAGE ' + meter + ': 本期 --- · 记两次读数才有用量';
    } else {
      patch.usageLine = 'USAGE ' + meter + ': 本期 ' + this._fmtVal(info.latestUsage) + ' ' + unit +
        (info.prevUsage !== null ? ' · 上期 ' + this._fmtVal(info.prevUsage) + ' ' + unit : ' · 上期 ---');
    }
    if (info.anomaly) {
      patch.anomalyLine = '! 用量异常: 比上期' + (info.pct > 0 ? '多' : '少') + ' ' +
        Math.abs(info.pct) + '% — ' + this._leakHint();
    } else if (info.pct !== null) {
      patch.anomalyLine = 'COMPARE: 用量平稳 (within +/-50%)';
    } else {
      patch.anomalyLine = 'COMPARE: 还没有上期可比';
    }

    var rows = [];
    if (this._mode === 'USAGE') {
      var periods = this._periods(meter);
      // Newest first: each reading with what it means.
      for (var i = arr.length - 1; i >= 0; i--) {
        var e = arr[i];
        var note;
        if (e.baseline) note = '换表基线';
        else if (i === 0) note = '起始读数';
        else {
          var p = periods[i];
          note = p && p.valid ? '本期 +' + this._fmtVal(p.usage) : '本期 ---';
        }
        rows.push({
          text: this._fmtVal(e.value) + ' ' + unit + ' · ' + e.date.slice(5) +
            ' · ' + note + (e.demo ? ' DEMO' : '')
        });
      }
      if (!rows.length) rows.push({ text: '(no readings for ' + meter + ')' });
    } else {
      if (!arr.length) {
        rows.push({ text: '(no readings for ' + meter + ') - READ one, or DEMO' });
      } else {
        var self = this;
        var recent = arr.slice(-8).reverse();
        rows = recent.map(function (e) {
          return {
            text: meter + ' · ' + self._fmtVal(e.value) + ' ' + unit + ' · ' +
              e.date.slice(5) + ' ' + e.time + (e.baseline ? ' 换表' : '') + (e.demo ? ' DEMO' : '')
          };
        });
      }
    }
    patch.rows = rows;
    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    var text;
    if (this._mode === 'READ' && this._pendingRead !== null) {
      text = '待确认读数：' + this._meter() + '，' + this._fmtVal(this._pendingRead) +
        this._unit() + '。核对无误请点保存。';
    } else {
      text = this._usageText();
    }
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text.slice(0, 40) });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">METER READER</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="entry-box">
      <text class="meter">{{meterLine}}</text>
      <text class="read">{{readLine}}</text>
      <text class="heard">{{heardLine}}</text>
      <text class="photo">{{photoLine}}</text>
      <text class="count">{{countLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="sum-box">
      <text class="usage">{{usageLine}}</text>
      <text class="anomaly">{{anomalyLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="meterTap">METER</button>
      <button class="btn" bindtap="readTap">READ</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="fineM1Tap">FINE -1</button>
      <button class="btn" bindtap="fineP1Tap">FINE +1</button>
      <button class="btn" bindtap="fineP10Tap">FINE +10</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="saveTap">SAVE</button>
      <button class="btn" bindtap="newMeterTap">NEW METER</button>
      <button class="btn" bindtap="modeTap">USAGE</button>
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
  line-height: 24px;
  font-weight: 500;
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
.entry-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
    padding: 3px 10px;
  margin-bottom: 3px;
}
.meter {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
}
.read {
  color: #40ff5e;
  font-size: 15px;
  font-weight: 500;
  line-height: 19px;
  margin-top: 1px;
}
.heard {
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
  height: 40px;
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
.sum-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 3px;
  margin-bottom: 3px;
}
.usage {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
}
.anomaly {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
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
