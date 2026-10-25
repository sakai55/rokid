<script def>
{
  "navigationBarTitleText": "Receipt Keeper"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'ENTRY: LOOK the receipt, say AMT, check, SAVE',
    steadyText: 'HEAD: moving - hold still',
    catLine: 'CAT: 餐饮 · tap CAT to change',
    amtLine: 'AMT: --- · tap AMT, say the total',
    heardLine: 'HEARD: --- (amounts are never auto-saved)',
    photoLine: 'PHOTO: none - LOOK = record copy only',
    countLine: 'LEDGER: 0 entries · this device only',
    rows: [
      { text: '(no entries) - SAVE one here, or DEMO' }
    ],
    monthLine: 'MONTH: --- · tap MONTH for category totals',
    todayLine: 'TODAY: ¥0',
    lastEvent: 'EVT: the receipt is never read - you say the total',
    busy: false
  },

  onLoad() {
    this._mode = 'ENTRY';
    this._catIdx = 0;
    this._entries = this._loadEntries();
    this._pendingAmt = null;
    this._amtRec = null;
    this._stream = null;
    this._steady = false;
    this._demo = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._recompute();
  },

  onShow() {},

  onHide() {
    this._stopAmtRec();
    this._stopStream();
  },

  onUnload() {
    this._stopAmtRec();
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
    // misheard amount can never slip into the ledger hands-free.
    // A steady nod reads the pending entry back for verification.
    if (this._steady) this.speakTap();
    else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to hear it read back' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      if (this._mode === 'ENTRY') this.catTap();
      else this.setData({ lastEvent: 'EVT: MONTH view - CAT applies in ENTRY' });
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'ENTRY') this.saveTap(); else this.speakTap();
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
  // batch of seeds derived from one snapshot can never drift apart.
  _dateStrParts(y, m0, day) {
    return y + '-' + this._pad2(m0 + 1) + '-' + this._pad2(day);
  },

  _todayStr() { return this._dateStr(new Date()); },

  // A date n days before `base`, clamped to stay inside base's
  // month - DEMO seeds must exercise THIS month's totals, even
  // when today is the 1st.
  _dateDaysAgoInMonth(base, n) {
    var day = Math.max(1, base.getDate() - n);
    return this._dateStr(new Date(base.getFullYear(), base.getMonth(), day));
  },

  _daysAgoInMonth(n) {
    return this._dateDaysAgoInMonth(new Date(), n);
  },

  // Money display: 123.5 stays 123.5, 520 stays 520, 9.9 stays 9.9.
  _fmtAmt(n) {
    var v = Math.round((+n || 0) * 100) / 100;
    return String(v);
  },

  // ---------- categories ----------

  _cats() { return ['餐饮', '交通', '购物', '家居', '娱乐', '其他']; },
  _cat() { return this._cats()[this._catIdx || 0]; },

  catTap() {
    if (this._mode !== 'ENTRY') {
      this.setData({ lastEvent: 'EVT: CAT only applies in ENTRY mode' });
      return;
    }
    this._catIdx = ((this._catIdx || 0) + 1) % this._cats().length;
    this.setData({ lastEvent: 'EVT: cat -> ' + this._cat() });
    this._recompute();
  },

  // ---------- persistence (wx sync storage, key 'receiptLedger', cap 100) ----------

  _loadEntries() {
    try {
      var raw = wx.getStorageSync('receiptLedger');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 100; i++) {
        var r = raw[i];
        if (r && isFinite(r.amount) && typeof r.cat === 'string' &&
            typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            amount: Math.round(+r.amount * 100) / 100,
            cat: String(r.cat).slice(0, 4),
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

  _saveEntries() {
    try {
      wx.setStorageSync('receiptLedger', this._entries || []);
    } catch (e) { /* storage unavailable on this host: entries stay in memory */ }
  },

  // Cap 100 entries: beyond that the OLDEST is dropped. Entries from
  // previous months are kept (until the cap pushes them out) but are
  // excluded from the MONTH totals - see _monthSummary.
  _addEntry(entry) {
    var arr = this._entries || [];
    arr.push(entry);
    while (arr.length > 100) arr.shift();
    this._entries = arr;
    this._saveEntries();
  },

  // ---------- month / today aggregation (real Date math) ----------

  _monthSummary() {
    var now = new Date();
    var mk = now.getFullYear() + '-' + this._pad2(now.getMonth() + 1);
    var today = this._todayStr();
    var byCat = {};
    var total = 0, count = 0, todayTotal = 0;
    var arr = this._entries || [];
    for (var i = 0; i !== arr.length; i++) {
      var e = arr[i];
      if (e.date === today) todayTotal += e.amount;
      if (e.date.slice(0, 7) === mk) {
        byCat[e.cat] = (byCat[e.cat] || 0) + e.amount;
        total += e.amount;
        count++;
      }
    }
    return {
      monthNum: now.getMonth() + 1,
      byCat: byCat,
      total: Math.round(total * 100) / 100,
      count: count,
      todayTotal: Math.round(todayTotal * 100) / 100
    };
  },

  _monthText() {
    var s = this._monthSummary();
    if (!s.count) return '本月还没有记录。看小票，点金额，说出总价，核对后保存。';
    var parts = ['本月共花' + this._fmtAmt(s.total) + '元。'];
    var cats = this._cats();
    var segs = [];
    for (var i = 0; i !== cats.length; i++) {
      if (s.byCat[cats[i]]) segs.push(cats[i] + this._fmtAmt(s.byCat[cats[i]]) + '元');
    }
    if (segs.length) parts.push(segs.join('，') + '。');
    parts.push('今天花了' + this._fmtAmt(s.todayTotal) + '元。');
    return parts.join('');
  },

  // ---------- amount parsing (spoken total -> number) ----------

  _cnDigits() {
    return { '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9 };
  },

  // Chinese integer up to 万: 一百二十三 / 三十五 / 二百 / 两千零五十.
  // A trailing digit right after a unit takes the next place down:
  // 二百五 = 250, 一千二 = 1200 (but 三百零五 = 305 - the 零 holds
  // the tens place, so its scale stays 1). Null on unknown chars.
  _cnInt(str) {
    if (!str) return null;
    var D = this._cnDigits();
    var U = { '十': 10, '百': 100, '千': 1000, '万': 10000 };
    var result = 0, section = 0, pending = null, pendingScale = 1, seen = false;
    for (var i = 0; i < str.length; i++) {
      var ch = str.charAt(i);
      if (Object.prototype.hasOwnProperty.call(D, ch)) {
        pending = D[ch];
        var prev = i > 0 ? str.charAt(i - 1) : '';
        pendingScale = Object.prototype.hasOwnProperty.call(U, prev) ? U[prev] / 10 : 1;
        seen = true;
      } else if (ch === '万') {
        section = (section + (pending === null ? 1 : pending)) * 10000;
        result += section; section = 0; pending = null; seen = true;
      } else if (Object.prototype.hasOwnProperty.call(U, ch)) {
        section += (pending === null ? 1 : pending) * U[ch];
        pending = null; seen = true;
      } else {
        return null;
      }
    }
    if (!seen) return null;
    return result + section + (pending === null ? 0 : pending * pendingScale);
  },

  _validAmt(v) {
    if (v === null || v === undefined || !isFinite(v)) return null;
    if (v <= 0 || v > 999999) return null;
    return Math.round(v * 100) / 100;
  },

  // Parse a dictated total. Handles Arabic ("123.5", "123块5") and
  // Chinese numerals ("一百二十三块五" = 123.5, "九块九" = 9.9).
  // Covers common spoken forms, not every dialect phrasing; anything
  // unparsable returns null and the wearer retries or FINE-adjusts.
  _parseAmount(raw) {
    if (!raw) return null;
    var s = String(raw).replace(/[\s　]/g, '').replace(/[¥￥,，]/g, '');
    s = s.replace(/^(总共|一共|共计|合计|花了|消费了|金额是|是)/, '');
    if (!s) return null;

    // --- Arabic digits present: first number token is authoritative.
    if (/\d/.test(s)) {
      var m = s.match(/(\d+)(?:\.(\d{1,2}))?/);
      if (!m) return null;
      var yuan = parseInt(m[1], 10);
      var val;
      if (m[2] !== undefined) {
        val = yuan + parseInt(m[2], 10) / Math.pow(10, m[2].length);
      } else {
        val = yuan;
        var rest = s.slice(m.index + m[0].length);
        var jm = rest.match(/^[块元](\d)(?:[毛角](\d))?/);
        if (jm) {
          val = yuan + parseInt(jm[1], 10) / 10 +
            (jm[2] ? parseInt(jm[2], 10) / 100 : 0);
        }
      }
      return this._validAmt(val);
    }

    // --- Chinese numerals: split at 块 / 元 / 点.
    var sepIdx = -1, sepCh = '';
    for (var i = 0; i < s.length; i++) {
      var c = s.charAt(i);
      if (c === '块' || c === '元' || c === '点') { sepIdx = i; sepCh = c; break; }
    }
    var head = sepIdx >= 0 ? s.slice(0, sepIdx) : s;
    var tail = sepIdx >= 0 ? s.slice(sepIdx + 1) : '';
    var intVal = this._cnInt(head);
    if (intVal === null) return null;
    var frac = 0;
    if (tail) {
      // Fraction digits are read one by one: 五 -> .5, 五三 -> .53.
      // 毛/角/分 are unit markers, skipped. Anything else: fail.
      var D = this._cnDigits();
      var digits = [];
      for (var j = 0; j < tail.length; j++) {
        var tc = tail.charAt(j);
        if (Object.prototype.hasOwnProperty.call(D, tc)) digits.push(D[tc]);
        else if (tc === '毛' || tc === '角' || tc === '分' || tc === '钱' || tc === '整') { /* marker */ }
        else return null;
      }
      for (var k = 0; k < digits.length; k++) {
        frac += digits[k] / Math.pow(10, k + 1);
      }
    }
    return this._validAmt(intVal + frac);
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
        status: 'LOOK FAIL - no camera here; just say the total',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto) - aim at the receipt total...' });
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
        status: 'PHOTO kept as your copy - now tap AMT and say the total',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / manual-lens.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record copy only',
          status: 'PHOTO kept as your copy - now tap AMT and say the total',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo; the ledger does not need one',
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

  // ---------- AMT: one-shot ASR dictation of the total ----------

  _stopAmtRec() {
    if (this._amtRec) {
      try { this._amtRec.abort(); } catch (e) {}
      this._amtRec = null;
    }
  },

  amtTap() {
    if (this._mode !== 'ENTRY') {
      this.setData({ lastEvent: 'EVT: AMT only applies in ENTRY mode' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host - never pretend to listen.
      this.setData({
        heardLine: 'HEARD: SKIP - ASR n/a on this host, nothing heard',
        status: 'AMT SKIP - no ASR here (DEMO shows the ledger)',
        lastEvent: 'EVT: AMT honest SKIP, no SpeechRecognition'
      });
      return;
    }
    this._amtListen();
  },

  async _amtListen() {
    var self = this;
    this.setData({ busy: true, heardLine: 'HEARD: checking wearer mic...' });
    // Wearer-mode mic check (documented getUserMedia audio constraints,
    // same pattern as cook-along DI11 / market-radar DI21): the 4-mic
    // array in 'wearer' mode prioritises YOUR voice. The stream only
    // verifies the mode opens; recognition uses SpeechRecognition.
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
      this._stopAmtRec();
      var rec = new SpeechRecognition();
      this._amtRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // The heard text is parsed, then shown BIG for the wearer to
          // eyeball. Nothing is saved until SAVE is tapped - a misheard
          // number can always be corrected with FINE or re-dictated.
          var amt = self._parseAmount(txt);
          if (amt === null) {
            self._pendingAmt = null;
            self.setData({
              heardLine: 'HEARD: "' + txt.slice(0, 20) + '" - parse FAIL',
              amtLine: 'AMT: ??? - parse FAIL, say it again',
              status: 'PARSE FAIL - re-say the total, plainly',
              lastEvent: 'EVT: amount parse FAIL on "' + txt.slice(0, 14) + '"'
            });
          } else {
            self._pendingAmt = amt;
            self.setData({
              heardLine: 'HEARD: "' + txt.slice(0, 20) + '" -> ¥' + self._fmtAmt(amt),
              amtLine: 'AMT: ¥' + self._fmtAmt(amt) + ' - eyeball it, then SAVE',
              status: 'AMT heard - check the number, FINE-fix or SAVE',
              lastEvent: 'EVT: amount ¥' + self._fmtAmt(amt) + ' pending (' + micNote + ')'
            });
          }
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          heardLine: 'HEARD: FAIL - ' + self._err(ev.error || ev) + ', tap AMT again',
          status: 'AMT FAIL - try again, closer and slower',
          lastEvent: 'EVT: AMT ASR error'
        });
      };
      rec.onend = function () {
        if (self._amtRec === rec) self._amtRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        heardLine: 'HEARD: listening - say the total...',
        status: 'AMT listening (' + micNote + ')',
        lastEvent: 'EVT: AMT listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        heardLine: 'HEARD: FAIL - ' + this._err(e),
        status: 'AMT FAIL - recogniser would not start',
        lastEvent: 'EVT: AMT start failed'
      });
    }
  },

  // ---------- FINE: correct a near-miss parse (-1 / +1 / +10) ----------

  _fine(delta) {
    if (this._mode !== 'ENTRY') {
      this.setData({ lastEvent: 'EVT: FINE only applies in ENTRY mode' });
      return;
    }
    if (this._pendingAmt === null) {
      this.setData({
        status: 'FINE: no amount yet - tap AMT and say the total first',
        lastEvent: 'EVT: FINE refused - nothing to adjust'
      });
      return;
    }
    var v = this._validAmt(Math.round((this._pendingAmt + delta) * 100) / 100);
    if (v === null) {
      this.setData({ lastEvent: 'EVT: FINE refused - amount out of range' });
      return;
    }
    this._pendingAmt = v;
    this.setData({
      amtLine: 'AMT: ¥' + this._fmtAmt(v) + ' - eyeball it, then SAVE',
      status: 'AMT adjusted by FINE - check it, then SAVE',
      lastEvent: 'EVT: FINE ' + (delta > 0 ? '+' : '') + delta + ' -> ¥' + this._fmtAmt(v)
    });
    this._recompute();
  },

  fineM1Tap() { this._fine(-1); },
  fineP1Tap() { this._fine(1); },
  fineP10Tap() { this._fine(10); },

  // ---------- SAVE (explicit confirm only) ----------

  saveTap() {
    if (this._mode !== 'ENTRY') {
      this.setData({ lastEvent: 'EVT: SAVE only applies in ENTRY mode' });
      return;
    }
    if (this._pendingAmt === null) {
      this.setData({
        status: 'SAVE FAIL: no amount - tap AMT and say the total first',
        lastEvent: 'EVT: SAVE refused - nothing pending, nothing saved'
      });
      return;
    }
    var entry = {
      amount: this._pendingAmt,
      cat: this._cat(),
      date: this._todayStr(),
      time: this._nowTime(),
      demo: !!this._demo
    };
    this._addEntry(entry);
    this._pendingAmt = null;
    this.setData({
      status: 'SAVED ¥' + this._fmtAmt(entry.amount) + ' · ' + entry.cat + ' - next receipt?',
      heardLine: 'HEARD: saved ¥' + this._fmtAmt(entry.amount) + ' · ' + entry.cat +
        (entry.demo ? ' DEMO' : ''),
      amtLine: 'AMT: --- · tap AMT, say the total',
      lastEvent: 'EVT: entry saved ¥' + this._fmtAmt(entry.amount) + ' ' + entry.cat
    });
    this._recompute();
  },

  // ---------- modes: ENTRY <-> MONTH ----------

  modeTap() {
    this._mode = this._mode === 'ENTRY' ? 'MONTH' : 'ENTRY';
    this.setData({
      status: this._mode === 'ENTRY'
        ? 'ENTRY: LOOK the receipt, say AMT, check, SAVE'
        : 'MONTH: this month by category - SPEAK reads it',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  clearTap() {
    this._entries = [];
    this._saveEntries();
    this._pendingAmt = null;
    this._mode = 'ENTRY';
    this.setData({
      status: 'ENTRY: LOOK the receipt, say AMT, check, SAVE',
      heardLine: 'HEARD: --- (amounts are never auto-saved)',
      amtLine: 'AMT: --- · tap AMT, say the total',
      lastEvent: 'EVT: ledger cleared (all entries, incl. old months)'
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO seeds 5 entries across THIS month (dates computed from Date
  // at runtime, clamped to the 1st) so the MONTH math in preview is
  // real, and lands on the MONTH view. Re-tapping replaces old demo
  // entries instead of piling up.
  demoTap() {
    this._demo = true;
    this._entries = (this._entries || []).filter(function (e) { return !e.demo; });
    // One clock snapshot for all five seeds, and the seed dates are
    // derived from it as pure strings: the five dates always belong
    // to the same month, so the MONTH totals are the real sums.
    var now = new Date();
    var t = this._pad2(now.getHours()) + ':' + this._pad2(now.getMinutes());
    var y = now.getFullYear(), m0 = now.getMonth(), dd = now.getDate();
    var today = this._dateStrParts(y, m0, dd);
    this._addEntry({ amount: 35.5, cat: '餐饮', date: today, time: t, demo: true });
    this._addEntry({ amount: 12, cat: '交通', date: today, time: t, demo: true });
    this._addEntry({ amount: 123.5, cat: '购物', date: this._dateStrParts(y, m0, Math.max(1, dd - 2)), time: t, demo: true });
    this._addEntry({ amount: 200, cat: '家居', date: this._dateStrParts(y, m0, Math.max(1, dd - 5)), time: t, demo: true });
    this._addEntry({ amount: 48, cat: '餐饮', date: this._dateStrParts(y, m0, Math.max(1, dd - 10)), time: t, demo: true });
    this._pendingAmt = null;
    this._mode = 'MONTH';
    this.setData({
      status: 'MONTH: DEMO month - 5 seeded entries, real totals',
      lastEvent: 'EVT: DEMO seeded 5 entries this month - MONTH view'
    });
    this._recompute();
  },

  // ---------- recompute view ----------

  _recompute() {
    var s = this._monthSummary();
    var arr = this._entries || [];
    var patch = {
      catLine: 'CAT: ' + this._cat() + ' · tap CAT to change',
      countLine: 'LEDGER: ' + arr.length + '/100 entries · this device only',
      monthLine: 'MONTH ' + s.monthNum + '月: ¥' + this._fmtAmt(s.total) +
        ' · ' + s.count + ' entries this month',
      todayLine: 'TODAY: ¥' + this._fmtAmt(s.todayTotal)
    };
    if (this._mode === 'MONTH') {
      var rows = [];
      var cats = this._cats();
      for (var i = 0; i !== cats.length; i++) {
        if (s.byCat[cats[i]]) {
          rows.push({ text: cats[i] + ' · ¥' + this._fmtAmt(s.byCat[cats[i]]) });
        }
      }
      if (!rows.length) rows.push({ text: '(no entries this month)' });
      rows.push({ text: '合计 · ¥' + this._fmtAmt(s.total) + ' · 今日 ¥' + this._fmtAmt(s.todayTotal) });
      patch.rows = rows;
    } else {
      if (!arr.length) {
        patch.rows = [{ text: '(no entries) - SAVE one here, or DEMO' }];
      } else {
        var self = this;
        var recent = arr.slice(-8).reverse();
        patch.rows = recent.map(function (e) {
          return {
            text: e.cat + ' · ¥' + self._fmtAmt(e.amount) + ' · ' +
              e.date.slice(5) + ' ' + e.time + (e.demo ? ' DEMO' : '')
          };
        });
      }
    }
    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    var text;
    if (this._mode === 'ENTRY' && this._pendingAmt !== null) {
      text = '待确认金额：' + this._fmtAmt(this._pendingAmt) + '元，类别' +
        this._cat() + '。核对无误请点保存。';
    } else {
      text = this._monthText();
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
      <text class="title">RECEIPT KEEPER</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="entry-box">
      <text class="cat">{{catLine}}</text>
      <text class="amt">{{amtLine}}</text>
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
      <text class="month">{{monthLine}}</text>
      <text class="today">{{todayLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="amtTap">AMT</button>
      <button class="btn" bindtap="catTap">CAT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="fineM1Tap">FINE -1</button>
      <button class="btn" bindtap="fineP1Tap">FINE +1</button>
      <button class="btn" bindtap="fineP10Tap">FINE +10</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="saveTap">SAVE</button>
      <button class="btn" bindtap="modeTap">MONTH</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
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
.entry-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 10px;
  margin-bottom: 3px;
}
.cat {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
}
.amt {
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
.month {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
}
.today {
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
