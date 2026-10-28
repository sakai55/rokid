<script def>
{
  "navigationBarTitleText": "Seat Catch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '看向票根，头稳住 — SNAP 拍下读座位，不用再一路默念',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 还没有目标座位 — 拍票根读一次，核对后才开始找',
    capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
    bigLabel: '（还没有目标座位）',
    bigText: '----',
    bigCls: 'bignum',
    bigNote: 'SNAP 拍票根 / DEMO 演示（模拟读数）',
    rows: [
      { name: '(no target)', detail: 'SNAP the ticket stub, verify the read, OK keeps it for this session only - or DEMO', flag: '', cls: 'row' }
    ],
    countLine: 'TARGET: 未存 · 只存本次会话内存 · 关掉/坐下即清 · 零落盘',
    lastEvent: 'EVT: ready - a seat becomes the target only after YOU verify and press OK',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'ticket'; // ticket | confirm | grow | gseat | done
    this._pending = null; // unconfirmed read: {zone,row,seat,src,readState,failWhy,corrected,blob,bytes}
    this._target = null; // confirmed target, SESSION MEMORY ONLY - never persisted anywhere
    this._focus = 'row'; // confirm-mode stepper focus: 'row' | 'seat'
    this._curRow = null; // last row read while guiding (number)
    this._curRowSrc = '';
    this._curSeat = null; // last seat token read while guiding (string, e.g. '12' or '12A')
    this._curSeatSrc = '';
    this._log = []; // short guidance history for the rows list (memory only)
    this._sitArm = false; // two-step seated confirm (nod and SIT share the arm)
    this._abandonArm = false; // two-step abandon in guide modes
    this._armTimer = null;
    this._nodLock = false;
    this._demo = false;
    this._demoRowIdx = 0;
    this._demoSeatIdx = 0;
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the target, the pending read and
    // every hint die with the page. Nothing was ever written to any
    // storage, so there is nothing to clean up - that IS the design.
    this._target = null;
    this._pending = null;
    this._log = [];
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (only nod is documented)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Nod discipline in THIS agent: a steady nod means ONE thing -
    // "I am seated" - and only inside the row at the seat stage.
    // It is two-step (first nod arms, second seats), like the
    // number-catch two-nod clear: one nod never wipes the target.
    // A nod never stores a target, never advances a row, never
    // confirms a read.
    if (this._mode === 'gseat') {
      this._seatedStep('nod');
      return;
    }
    if (this._mode === 'confirm') {
      this.setData({ lastEvent: 'EVT: nod ignored in confirm - press OK to keep the seat, nod never stores' });
      return;
    }
    if (this._mode === 'grow') {
      this.setData({ lastEvent: 'EVT: nod ignored while finding the row - nod only means seated, at the seat stage' });
      return;
    }
    if (this._mode === 'done') {
      this.setData({ lastEvent: 'EVT: nod ignored - already seated, target already cleared' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod ignored - nod only means seated, at the seat stage' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.okTap();
    } else if (code === 'ArrowUp') {
      this._stepOrAdjust(1, 'key');
    } else if (code === 'ArrowDown') {
      this._stepOrAdjust(-1, 'key');
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  // ---------- target display helpers ----------

  _seatNum(token) {
    // Numeric part of a seat token ('12A' -> 12); NaN when none.
    var m = String(token == null ? '' : token).match(/^(\d{1,3})/);
    return m ? parseInt(m[1], 10) : NaN;
  },

  _fmtSeat(t) {
    if (!t) return '----';
    var z = t.zone ? t.zone + ' ' : '';
    return z + t.row + '排 ' + t.seat + '座';
  },

  _zones() {
    return ['左区', '中区', '右区', ''];
  },

  // ---------- read-reply parsers (pure; an unclear reply is a failed read, never a guess) ----------

  _parseTicketRead(text) {
    // Expected: "SEAT: 中区|8|12" / "SEAT: |8|12A" / "SEAT: NONE".
    // Salvage: a "N排M座" pattern anywhere in the reply.
    var lines = String(text || '').split('\n');
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      var m = ln.match(/^SEAT[:：]\s*(.+)$/i);
      if (m) {
        var v = m[1].trim();
        if (/^NONE/i.test(v) || v === '无') return null;
        var parts = v.split('|');
        if (parts.length >= 3) {
          var zone = String(parts[0] || '').trim().slice(0, 4);
          var row = parseInt(String(parts[1] || '').trim(), 10);
          var seat = String(parts[2] || '').trim().toUpperCase().replace(/\s+/g, '');
          if (row >= 1 && row <= 99 && /^(\d{1,3})([A-Z]?)$/.test(seat)) {
            return { zone: zone, row: row, seat: seat };
          }
          return null;
        }
        // A SEAT: line without the pipe shape falls through to salvage.
      }
    }
    var s = String(text || '');
    var sm = s.match(/(\d{1,2})\s*排\s*(\d{1,3})\s*([A-Za-z]?)\s*座/);
    if (sm) {
      var zm = s.match(/([左中右]区|[A-Za-z]区)/);
      return {
        zone: zm ? zm[1] : '',
        row: parseInt(sm[1], 10),
        seat: sm[2] + (sm[3] ? sm[3].toUpperCase() : '')
      };
    }
    return null;
  },

  _parseRowRead(text) {
    // Expected: "ROW: 5" / "ROW: NONE". Salvage: "N排" anywhere.
    var lines = String(text || '').split('\n');
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      var m = ln.match(/^ROW[:：]\s*(.+)$/i);
      if (m) {
        var v = m[1].trim();
        if (/^NONE/i.test(v)) return null;
        var n = parseInt(v, 10);
        return (n >= 1 && n <= 99) ? n : null;
      }
    }
    var sm = String(text || '').match(/(\d{1,2})\s*排/);
    if (sm) return parseInt(sm[1], 10);
    return null;
  },

  _parseSeatRead(text) {
    // Expected: "SEATNO: 12" / "SEATNO: 12A" / "SEATNO: NONE".
    // Salvage: "N座" / "N号" anywhere.
    var lines = String(text || '').split('\n');
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      var m = ln.match(/^SEATNO[:：]\s*(.+)$/i);
      if (m) {
        var v = ln.match(/^SEATNO[:：]\s*(.+)$/i)[1].trim().toUpperCase().replace(/\s+/g, '');
        if (/^NONE/i.test(v)) return null;
        return /^(\d{1,3})([A-Z]?)$/.test(v) ? v : null;
      }
    }
    var sm = String(text || '').match(/(\d{1,3})\s*([A-Za-z]?)\s*(座|号)/);
    if (sm) return sm[1] + (sm[2] ? sm[2].toUpperCase() : '');
    return null;
  },

  // ---------- LLM reads (photo -> data: URL -> host LLM image input; dossier 2.9) ----------

  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      var buf = await blob.arrayBuffer();
      var bytes = new Uint8Array(buf);
      var bin = '';
      var CH = 0x8000;
      for (var i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: ' + String((e && e.message) || e).slice(0, 40));
    }
  },

  _buildReadContent(kind, dataUrl) {
    // Multimodal content goes in the USER message only (dossier
    // section 2.9): one text part, one image_url part with the data: URL.
    var instr = '';
    if (kind === 'ticket') {
      instr = 'This photo shows a ticket stub (paper or phone screen) with a seat assignment ' +
        'for a cinema, theatre, hall or train. Find the seat assignment: the seating zone ' +
        'or section if one is printed (for example a Chinese zone word or a lettered ' +
        'section), the ROW number, and the SEAT number (digits, possibly with one trailing ' +
        'letter). Reply in exactly this format:\nSEAT: <zone>|<row>|<seat>\n' +
        'If no zone is printed, leave it empty: SEAT: |<row>|<seat>\n' +
        'If the seat assignment is not clearly readable, reply with exactly: SEAT: NONE';
    } else if (kind === 'row') {
      instr = 'This photo shows a row number sign or the end-of-row number plate in a ' +
        'cinema, theatre, hall or train carriage. Read ONLY the row number. ' +
        'Reply in exactly this format:\nROW: <row number>\n' +
        'If the row number is not clearly readable, reply with exactly: ROW: NONE';
    } else {
      instr = 'This photo shows the number printed on a seat (seat back, armrest or the ' +
        'number plate nearest the camera). Read ONLY that one seat number (digits, ' +
        'possibly with one trailing letter). Reply in exactly this format:\n' +
        'SEATNO: <seat number>\n' +
        'If it is not clearly readable, reply with exactly: SEATNO: NONE';
    }
    return [
      { type: 'text', text: instr },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  async _llmRead(kind, dataUrl) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return { ok: false, reason: 'no-lm' };
    var avail;
    try {
      avail = await LM.availability();
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    }
    if (avail !== 'available') return { ok: false, reason: 'unavailable' };
    var session = null;
    try {
      session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You read seat assignment text and seat/row numbers from photos. Reply with only the requested line. Never invent numbers that are not visible.' }]
      });
      var ans = await this._withTimeout(session.prompt(this._buildReadContent(kind, dataUrl)), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var v = kind === 'ticket' ? this._parseTicketRead(ans)
        : kind === 'row' ? this._parseRowRead(ans)
        : this._parseSeatRead(ans);
      if (v === null || v === undefined) return { ok: false, reason: 'unreadable' };
      return { ok: true, value: v };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  _readFailWhy(r) {
    return r.reason === 'no-lm' ? '这台设备没有大模型'
      : r.reason === 'unavailable' ? '大模型现在不可用'
      : r.reason === 'empty' ? '模型没有返回内容'
      : r.reason === 'unreadable' ? '照片里没读清'
      : '模型出错：' + this._err(r.error);
  },

  // ---------- capture (telephoto) + read dispatch ----------

  snapTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: SNAP in DEMO - no camera used (simulated read already on screen)' });
      return;
    }
    if (this._mode === 'grow') { this.rowTap(); return; }
    if (this._mode === 'gseat') { this.seatPhotoTap(); return; }
    if (this._mode === 'done') {
      this.setData({ lastEvent: 'EVT: SNAP in done - already seated; OK starts a new seat hunt' });
      return;
    }
    if (this._mode === 'confirm' && this._pending && this._pending.blob && this._pending.readState === 'fail') {
      // A photo is held and its read failed: retry the READ on it.
      this._doRead('ticket');
      return;
    }
    this.capturePhoto('ticket');
  },

  rowTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: ROW in DEMO - DEMO taps simulate row reads here' });
      return;
    }
    if (this._mode !== 'grow') {
      this.setData({ lastEvent: 'EVT: ROW - row signs are read at the row-finding stage (confirm a target first)' });
      return;
    }
    this.capturePhoto('row');
  },

  seatPhotoTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: SEAT in DEMO - DEMO taps simulate seat reads here' });
      return;
    }
    if (this._mode !== 'gseat') {
      this.setData({ lastEvent: 'EVT: SEAT - seat numbers are read inside your row (reach the row first)' });
      return;
    }
    this.capturePhoto('seat');
  },

  async capturePhoto(kind) {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this._photoUnavailable(kind, '这台设备没有可用相机', 'mediaDevices n/a on this host');
      return;
    }
    this.setData({
      busy: true,
      status: kind === 'ticket' ? 'SNAPPING (telephoto) the ticket stub...'
        : kind === 'row' ? 'SNAPPING (telephoto) the row sign...'
        : 'SNAPPING (telephoto) the nearest seat number...'
    });
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
      if (kind === 'ticket') {
        this._pending = {
          blob: blob, bytes: bytes, wxPhoto: false,
          zone: '', row: null, seat: null, src: 'LLM',
          readState: 'reading', failWhy: '', corrected: false
        };
        this._focus = 'row';
        this._mode = 'confirm';
      } else {
        this._photoBlob = blob;
        this._photoBytes = bytes;
      }
      this.setData({
        capLine: 'CAP: ' + bytes + 'B telephoto · memory only, NOT saved',
        status: 'PHOTO HELD - reading it...',
        lastEvent: 'EVT: telephoto photo ' + bytes + 'B for ' + kind + ' (memory only, never persisted)'
      });
      this._renderAll();
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context. A wx photo has no Blob to
      // convert, so the image read is honestly n/a for it.
      try {
        var ctx = (typeof wx !== 'undefined' && wx.media && wx.media.createCameraContext)
          ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        if (kind === 'ticket') {
          this._pending = {
            blob: null, bytes: size, wxPhoto: true,
            zone: '', row: null, seat: null, src: 'MANUAL',
            readState: 'fail', failWhy: 'wx 回退照片无法转成图片发给模型', corrected: false
          };
          this._focus = 'row';
          this._mode = 'confirm';
          this.setData({
            capLine: 'CAP: ' + size + 'B wx cam (fallback) · memory only',
            status: '这张照片读不了 — 用步进把排/座填上照样找座',
            lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - image read n/a)'
          });
        } else {
          this.setData({
            capLine: 'CAP: ' + size + 'B wx cam (fallback) · memory only',
            status: '这张照片读不了 — 用 +1/−1 手动报当前' + (kind === 'row' ? '排' : '座'),
            lastEvent: 'EVT: wx photo for ' + kind + ' (fallback, no Blob - read n/a, manual steppers offered)'
          });
        }
        this._renderAll();
      } catch (e3) {
        this._photoUnavailable(kind, '拍照失败：' + this._err(firstErr), this._err(firstErr));
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
    if (kind === 'ticket') {
      if (this._pending && this._pending.blob && this._mode === 'confirm') {
        await this._doRead('ticket');
      }
    } else if (this._photoBlob) {
      await this._doRead(kind);
    }
  },

  _photoUnavailable(kind, why, errText) {
    if (kind === 'ticket') {
      this._pending = {
        blob: null, bytes: 0, wxPhoto: false,
        zone: '', row: null, seat: null, src: 'MANUAL',
        readState: 'fail', failWhy: why, corrected: false
      };
      this._focus = 'row';
      this._mode = 'confirm';
      this.setData({
        capLine: 'CAP: FAIL - ' + errText,
        status: '拍照不可用 — 用步进把排/座填上照样找座',
        lastEvent: 'EVT: SNAP FAIL (' + errText + ') - manual stepper path offered'
      });
    } else {
      this.setData({
        capLine: 'CAP: FAIL - ' + errText,
        status: '拍照失败 — 用 +1/−1 手动报当前' + (kind === 'row' ? '排' : '座'),
        lastEvent: 'EVT: ' + kind.toUpperCase() + ' photo FAIL - manual steppers offered'
      });
    }
    this._renderAll();
  },

  async _doRead(kind) {
    var blob = kind === 'ticket'
      ? (this._pending && this._pending.blob)
      : this._photoBlob;
    if (!blob || this.data.busy) return;
    this.setData({ busy: true, status: 'READING (host AI, image in)...' });
    try {
      var dataUrl;
      try {
        dataUrl = await this._withTimeout(this._blobToDataUrl(blob), 12000, 'convert');
      } catch (ce) {
        this._readFailed(kind, '照片转图片数据失败：' + this._err(ce), 'conversion FAIL - ' + this._err(ce));
        return;
      }
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
        this._readFailed(kind, '照片转换没有得到 data: URL', 'conversion FAIL - not a data: URL');
        return;
      }
      var r = await this._llmRead(kind, dataUrl);
      if (!r.ok) {
        this._readFailed(kind, this._readFailWhy(r), 'READ FAIL (' + r.reason + ')');
        return;
      }
      if (kind === 'ticket') {
        var p = this._pending;
        p.zone = r.value.zone; p.row = r.value.row; p.seat = r.value.seat;
        p.src = 'LLM'; p.readState = 'ok';
        this.setData({
          status: '读到了 — 核对大字：对了 OK 开始找座，错了先改',
          lastEvent: 'EVT: LLM ticket read ok - machine read, NOT the target yet'
        });
      } else if (kind === 'row') {
        this._photoBlob = null;
        this._applyRowRead(r.value, 'LLM');
      } else {
        this._photoBlob = null;
        this._applySeatRead(r.value, 'LLM');
      }
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  _readFailed(kind, why, evt) {
    if (kind === 'ticket') {
      var p = this._pending;
      if (p) { p.readState = 'fail'; p.failWhy = why; }
      this.setData({
        status: '票根没读出来（' + why + '）— 步进填排/座，或 SNAP 重拍',
        lastEvent: 'EVT: ' + evt + ' - stepper fallback offered'
      });
    } else {
      if (kind === 'row') this._photoBlob = null; else this._photoBlob = null;
      this.setData({
        status: '没读出来（' + why + '）— 重拍，或 +1/−1 手动报当前' + (kind === 'row' ? '排' : '座'),
        lastEvent: 'EVT: ' + evt + ' - manual/retry offered'
      });
    }
    this._renderAll();
  },

  // ---------- guidance: relative differences only (NO indoor positioning) ----------

  _logPush(text, flag) {
    this._log.push({ text: text, flag: flag || '' });
    while (this._log.length > 3) this._log.shift();
  },

  _rowHintText(cur) {
    // Pure relative difference between the row you just read and
    // the confirmed target row. Nothing here knows where you are.
    var diff = this._target.row - cur;
    if (diff > 0) return '还差 ' + diff + ' 排，继续向前';
    if (diff < 0) return '走过 ' + (-diff) + ' 排，往回走';
    return '就是这一排';
  },

  _applyRowRead(n, src) {
    if (!this._target) return;
    this._curRow = n;
    this._curRowSrc = src;
    var hint = this._rowHintText(n);
    this._logPush('读到 ' + n + ' 排 → ' + hint, src);
    if (n === this._target.row) {
      this._mode = 'gseat';
      this._curSeat = null;
      this._curSeatSrc = '';
      this._disarm();
      this._speakText('就是这一排。你的座位是' + this._target.seat + '座，看一下最近的座位号，点 SEAT 拍它');
      this.setData({
        status: '就是这一排 ✓ 进排找座：拍最近的座位号',
        lastEvent: 'EVT: row matched (' + src + ') - now finding the seat inside the row'
      });
    } else {
      this._speakText(hint);
      this.setData({
        status: '当前 ' + n + ' 排（' + src + '）→ ' + hint,
        lastEvent: 'EVT: row read ' + n + ' (' + src + ') - diff ' + (this._target.row - n) + ' vs target row ' + this._target.row
      });
    }
    this._renderAll();
  },

  _seatHintText(curToken) {
    // Difference in seat NUMBERS inside the row: move toward bigger
    // or smaller numbers - that direction exists on the seat backs
    // themselves, no positioning is claimed.
    var t = this._seatNum(this._target.seat);
    var c = this._seatNum(curToken);
    if (isNaN(t) || isNaN(c)) return '号码对不上 — 再拍一个座位号核对';
    var diff = t - c;
    if (diff > 0) return '再往里 ' + diff + ' 个（往号码变大的方向）';
    if (diff < 0) return '往回 ' + (-diff) + ' 个（往号码变小的方向）';
    return '就是这个座位';
  },

  _applySeatRead(token, src) {
    if (!this._target) return;
    this._curSeat = token;
    this._curSeatSrc = src;
    var hint = this._seatHintText(token);
    this._logPush('读到 ' + token + ' 座 → ' + hint, src);
    if (this._seatNum(token) === this._seatNum(this._target.seat)) {
      this._speakText('就是这个座位。坐下后点头两次，或者点两次坐下了，目标就清掉');
      this.setData({
        status: '就是这个座位 ✓ 坐下吧 — 点头两下确认就座，目标即清',
        lastEvent: 'EVT: seat matched (' + src + ') - waiting for the seated confirm'
      });
    } else {
      this._speakText(hint);
      this.setData({
        status: '当前 ' + token + ' 座（' + src + '）→ ' + hint,
        lastEvent: 'EVT: seat read ' + token + ' (' + src + ') - target seat ' + this._target.seat
      });
    }
    this._renderAll();
  },

  // ---------- confirm gate: the ONLY way a seat becomes the target ----------

  _confirmTarget() {
    var p = this._pending;
    if (!p) { this._mode = 'ticket'; this._renderAll(); return; }
    if (!(p.row >= 1) || !p.seat || isNaN(this._seatNum(p.seat))) {
      this.setData({
        status: '排和座还没填全 — 用 FIELD 选排/座、+1/−1 填上，再 OK',
        lastEvent: 'EVT: OK refused - target incomplete (row/seat missing), nothing kept'
      });
      this._renderAll();
      return;
    }
    this._target = { zone: p.zone || '', row: p.row, seat: p.seat };
    this._pending = null;
    this._mode = 'grow';
    this._curRow = null;
    this._curRowSrc = '';
    this._curSeat = null;
    this._curSeatSrc = '';
    this._log = [];
    this._logPush('目标存入会话：' + this._fmtSeat(this._target), 'TARGET');
    this._disarm();
    this._speakText('目标座位：' + this._fmtSeat(this._target) + '。先找排：看向排号牌，点 ROW 拍它');
    this.setData({
      status: '开始找排 — 目标 ' + this._fmtSeat(this._target) + '（只在这次会话里）',
      lastEvent: 'EVT: target kept in SESSION memory only (' + p.src + (p.corrected ? ', corrected' : '') + ') - never persisted'
    });
    this._renderAll();
  },

  _discardPending(how) {
    this._pending = null;
    this._mode = 'ticket';
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: '已放弃这次读数（它本来就没成为目标）',
      lastEvent: 'EVT: pending read discarded by ' + how + ' - it was never the target'
    });
    this._renderAll();
  },

  // ---------- steppers / zone / field (confirm correction + manual guide fallback) ----------

  fieldTap() {
    if (this.data.busy) return;
    if (this._mode === 'confirm') {
      this._focus = this._focus === 'row' ? 'seat' : 'row';
      this.setData({
        lastEvent: 'EVT: stepper focus -> ' + (this._focus === 'row' ? '排 (row)' : '座 (seat)')
      });
      this._renderAll();
      return;
    }
    this.setData({
      lastEvent: 'EVT: FIELD - stepper focus only matters on the confirm screen'
    });
  },

  zoneTap() {
    if (this.data.busy) return;
    if (this._mode !== 'confirm' || !this._pending) {
      this.setData({ lastEvent: 'EVT: ZONE - the zone is set on the confirm screen' });
      return;
    }
    var zs = this._zones();
    var cur = zs.indexOf(this._pending.zone || '');
    var next = zs[(cur + 1) % zs.length];
    if (next !== this._pending.zone) this._pending.corrected = true;
    this._pending.zone = next;
    this.setData({
      status: '区：' + (next || '无区'),
      lastEvent: 'EVT: zone -> ' + (next || '(none)')
    });
    this._renderAll();
  },

  _stepOrAdjust(delta, source) {
    if (this.data.busy) return;
    if (this._mode === 'confirm' && this._pending) { this._stepPending(delta); return; }
    if (this._mode === 'grow' && this._target) {
      // Manual current-row report: the no-camera fallback for the
      // row stage, labelled 手动 wherever it is used.
      var base = this._curRow == null ? 0 : this._curRow;
      var n = base + delta;
      if (n < 1) n = 1;
      if (n > 99) n = 99;
      this._applyRowRead(n, '手动');
      return;
    }
    if (this._mode === 'gseat' && this._target) {
      var c = this._curSeat == null ? 0 : this._seatNum(this._curSeat);
      if (isNaN(c)) c = 0;
      var m = c + delta;
      if (m < 1) m = 1;
      if (m > 200) m = 200;
      this._applySeatRead(String(m), '手动');
      return;
    }
    this.setData({ lastEvent: 'EVT: steppers - nothing to adjust in this state' });
  },

  plus1Tap() { this._stepOrAdjust(1, 'btn'); },
  minus1Tap() { this._stepOrAdjust(-1, 'btn'); },

  _stepPending(delta) {
    var p = this._pending;
    this._disarm();
    if (this._focus === 'row') {
      var r = (p.row == null ? 0 : p.row) + delta;
      if (r < 1) r = 1;
      if (r > 99) r = 99;
      if (r !== p.row) p.corrected = true;
      p.row = r;
      this.setData({ lastEvent: 'EVT: row stepped -> ' + r + ' (not the target yet)' });
    } else {
      var cur = p.seat == null ? 0 : this._seatNum(p.seat);
      if (isNaN(cur)) cur = 0;
      var suffix = p.seat ? (String(p.seat).match(/[A-Za-z]$/) || [''])[0] : '';
      var n = cur + delta;
      if (n < 1) n = 1;
      if (n > 200) n = 200;
      var next = String(n) + suffix;
      if (next !== p.seat) p.corrected = true;
      p.seat = next;
      this.setData({ lastEvent: 'EVT: seat stepped -> ' + next + ' (not the target yet)' });
    }
    this._renderAll();
  },

  // ---------- seated confirm (two-step; nod and SIT share the arm) ----------

  _disarm() {
    this._sitArm = false;
    this._abandonArm = false;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  _armSit() {
    this._disarm();
    this._sitArm = true;
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._sitArm) {
        self._sitArm = false;
        self.setData({ lastEvent: 'EVT: seated confirm disarmed (timeout) - target kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _armAbandon() {
    this._disarm();
    this._abandonArm = true;
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._abandonArm) {
        self._abandonArm = false;
        self.setData({ lastEvent: 'EVT: abandon disarmed (timeout) - target kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _seatedStep(how) {
    if (this._mode !== 'gseat') return;
    if (this._sitArm) {
      // Seated: wipe everything. The target's whole life was this
      // one walk from the ticket check to the seat.
      this._target = null;
      this._pending = null;
      this._curRow = null;
      this._curSeat = null;
      this._log = [];
      this._disarm();
      this._mode = 'done';
      this._speakText('好，坐下了。目标座位已经清除');
      this.setData({
        capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
        status: '已就座 ✓ 目标已清除 — 它只记了这一程，清得干干净净',
        lastEvent: 'EVT: SEATED by ' + how + ' (two-step) - target wiped from session memory'
      });
      this._renderAll();
    } else {
      this._armSit();
      this.setData({
        status: '⚠ 再' + (how === 'nod' ? '点头' : '点') + '一次确认就座 — 就座后目标立即清除',
        lastEvent: 'EVT: seated 1/2 - ARMED by ' + how + ' (target still kept)'
      });
      this._renderAll();
    }
  },

  sitTap() {
    if (this.data.busy) return;
    if (this._mode !== 'gseat') {
      this.setData({ lastEvent: 'EVT: SIT - only works inside your row, at the seat stage' });
      return;
    }
    this._seatedStep('SIT');
  },

  _abandon(how) {
    this._target = null;
    this._pending = null;
    this._curRow = null;
    this._curSeat = null;
    this._log = [];
    this._disarm();
    this._mode = 'ticket';
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: '已放弃这次找座 — 目标已清除，重新 SNAP 拍票根开始',
      lastEvent: 'EVT: abandoned by ' + how + ' (two-step) - target wiped'
    });
    this._renderAll();
  },

  // ---------- OK / DEL / SPEAK ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'confirm') { this._confirmTarget(); return; }
    if (this._mode === 'grow') {
      // The wearer judges they are standing at their row even
      // without a matching read: their judgement, stated as such.
      this._mode = 'gseat';
      this._curSeat = null;
      this._disarm();
      this._logPush('你判断已到目标排（未经读数核对）', 'OK');
      this.setData({
        status: '按你的判断进排找座 — 拍最近的座位号核对',
        lastEvent: 'EVT: entered the row on the wearer judgement (OK) - no read claimed it'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'gseat') { this._seatedStep('OK'); return; }
    if (this._mode === 'done') {
      this._mode = 'ticket';
      this.setData({
        status: '新的找座 — 看向票根，头稳住，点 SNAP',
        lastEvent: 'EVT: done -> ticket (new seat hunt)'
      });
      this._renderAll();
      return;
    }
    // ticket
    this.setData({
      status: '先 SNAP 拍票根读座位，或 DEMO 看演示',
      lastEvent: 'EVT: OK in ticket - nothing to confirm yet'
    });
    this._renderAll();
  },

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'confirm') { this._discardPending('DEL'); return; }
    if (this._mode === 'grow' || this._mode === 'gseat') {
      if (this._abandonArm) { this._abandon('DEL x2'); return; }
      this._armAbandon();
      this.setData({
        status: '⚠ 再点一次 DEL 放弃这次找座并清除目标（其他动作取消）',
        lastEvent: 'EVT: abandon 1/2 - ARMED (target still kept)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEL - nothing to discard in this state' });
  },

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    if (this._mode === 'confirm' && this._pending) {
      var p = this._pending;
      var t = (p.row != null && p.seat)
        ? '待核对的座位：' + this._fmtSeat(p) + '。对了按 OK，还没成为目标。'
        : '还没读全：' + (p.failWhy || '排或座缺失') + '。用步进填，或重拍。';
      if (this._speakText(t)) this.setData({ lastEvent: 'EVT: SPEAK pending read (TTS, no lang set)' });
      return;
    }
    if ((this._mode === 'grow' || this._mode === 'gseat') && this._target) {
      var line = '目标座位：' + this._fmtSeat(this._target) + '。';
      if (this._mode === 'grow') {
        line += this._curRow == null ? '还没读到排号，看向排号牌点 ROW 拍它。'
          : '当前第' + this._curRow + '排，' + this._rowHintText(this._curRow) + '。';
      } else {
        line += this._curSeat == null ? '还没读到座位号，点 SEAT 拍最近的座位号。'
          : '当前' + this._curSeat + '座，' + this._seatHintText(this._curSeat) + '。';
      }
      if (this._speakText(line)) this.setData({ lastEvent: 'EVT: SPEAK target + current hint (TTS, no lang set)' });
      return;
    }
    if (this._mode === 'done') {
      if (this._speakText('已经就座，目标座位清除了')) {
        this.setData({ lastEvent: 'EVT: SPEAK done state (TTS, no lang set)' });
      }
      return;
    }
    this.setData({ lastEvent: 'EVT: SPEAK - no target yet, SNAP the stub first' });
  },

  // ---------- DEMO (one full seat hunt, simulated reads, memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      if (this._mode === 'done') {
        this.setData({ lastEvent: 'EVT: DEMO - finish this seat first (already seated); OK starts a new hunt' });
        return;
      }
      this._demoReal = {
        target: this._target, pending: this._pending, mode: this._mode,
        curRow: this._curRow, curSeat: this._curSeat,
        log: (this._log || []).slice(), focus: this._focus
      };
      this._demo = true;
      this._demoRowIdx = 0;
      this._demoSeatIdx = 0;
      this._disarm();
      this._target = null;
      this._curRow = null;
      this._curSeat = null;
      this._log = [];
      this._pending = {
        blob: null, bytes: 0, wxPhoto: false, demo: true,
        zone: '中区', row: 8, seat: '12', src: 'DEMO',
        readState: 'ok', failWhy: '', corrected: false
      };
      this._focus = 'row';
      this._mode = 'confirm';
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated ticket read (not a real photo)',
        status: 'DEMO - 模拟读到座位：中区 8排 12座 — 核对后 OK 开始演示找座',
        lastEvent: 'EVT: DEMO on - simulated read pending (memory only, real state parked)'
      });
      this._renderAll();
      return;
    }
    // Already in DEMO: taps drive the simulated hunt.
    if (this._mode === 'ticket') {
      // Backed out of the demo (e.g. DEL on the simulated read):
      // DEMO here exits and restores the parked real state.
      this._exitDemo();
      return;
    }
    if (this._mode === 'confirm') {
      this.setData({ lastEvent: 'EVT: DEMO - press OK to start the demo hunt with this seat' });
      return;
    }
    if (this._mode === 'grow') {
      var rows = [3, 6, 8];
      if (this._demoRowIdx >= rows.length) {
        this.setData({ lastEvent: 'EVT: DEMO row reads used up - you should be at the seat stage' });
        return;
      }
      var n = rows[this._demoRowIdx++];
      this.setData({ lastEvent: 'EVT: DEMO simulated row sign read: ' + n });
      this._applyRowRead(n, 'DEMO');
      return;
    }
    if (this._mode === 'gseat') {
      var seats = ['5', '12'];
      if (this._demoSeatIdx >= seats.length) {
        this.setData({ lastEvent: 'EVT: DEMO seat reads used up - SIT twice / nod twice to finish' });
        return;
      }
      var tok = seats[this._demoSeatIdx++];
      this.setData({ lastEvent: 'EVT: DEMO simulated seat read: ' + tok });
      this._applySeatRead(tok, 'DEMO');
      return;
    }
    if (this._mode === 'done') {
      this._exitDemo();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - no simulated step in this state' });
  },

  _exitDemo() {
    // The real state comes back exactly as it was parked.
    var r = this._demoReal || {};
    this._demo = false;
    this._demoReal = null;
    this._target = r.target || null;
    this._pending = r.pending || null;
    this._mode = r.mode || 'ticket';
    this._curRow = (typeof r.curRow === 'number') ? r.curRow : null;
    this._curSeat = r.curSeat || null;
    this._log = r.log || [];
    this._focus = r.focus || 'row';
    this._disarm();
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: 'DEMO OFF - your real state is back (' + (this._target ? this._fmtSeat(this._target) : 'no target') + ')',
      lastEvent: 'EVT: DEMO cleared - real state restored exactly, nothing was written'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i;
    if (this._target) {
      rows.push({
        name: '目标 ' + this._fmtSeat(this._target),
        detail: 'session only - wiped when seated',
        flag: 'TARGET',
        cls: 'row'
      });
    }
    for (i = 0; i < this._log.length; i++) {
      rows.push({ name: this._log[i].text, detail: '', flag: this._log[i].flag, cls: 'row' });
    }
    if (!rows.length) {
      rows.push({
        name: '(no target)',
        detail: 'SNAP the ticket stub, verify the read, OK keeps it for this session only - or DEMO',
        flag: '',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = this._target
      ? 'TARGET: ' + this._fmtSeat(this._target) + ' · 会话内存 only · 就座即清 · 零落盘'
      : 'TARGET: 未存 · 只存本次会话内存 · 关掉/坐下即清 · 零落盘';

    if (this._mode === 'ticket') {
      patch.boxLabel = '◎ 还没有目标座位 — 拍票根读一次，核对后才开始找';
      patch.bigLabel = '（还没有目标座位）';
      patch.bigText = '----';
      patch.bigNote = 'SNAP 拍票根 / DEMO 演示（模拟读数）';
    } else if (this._mode === 'confirm' && this._pending) {
      var p = this._pending;
      patch.boxLabel = p.readState === 'ok' && p.src === 'LLM'
        ? '◎ LLM READ - may misread, verify against the stub itself'
        : p.src === 'DEMO'
          ? '◎ DEMO READ (simulated) - not a real photo read'
          : p.readState === 'fail'
            ? '◎ READ FAILED - step the row/seat in yourself below'
            : '◎ YOUR SEAT - stepped in by you';
      patch.bigLabel = '待核对座位' + (p.zone ? ' · ' + p.zone : ' · 无区') +
        (p.corrected ? ' · 已更正' : '') + ' · 步进焦点：' + (this._focus === 'row' ? '排' : '座');
      patch.bigText = (p.row == null ? '?排' : p.row + '排') + ' ' + (p.seat == null ? '?座' : p.seat + '座');
      patch.bigNote = (p.row != null && p.seat)
        ? 'OK 开始找座 · FIELD 换排/座 · +1/−1 改 · ZONE 换区 · DEL 放弃'
        : '没读全：' + (p.failWhy || '排或座缺失') + ' — 步进填上，或 SNAP 重拍';
    } else if (this._mode === 'grow' && this._target) {
      patch.boxLabel = '◎ 找排中 — 逐排读号比对，只有相对差，没有定位';
      patch.bigLabel = '目标 ' + this._fmtSeat(this._target);
      patch.bigText = this._curRow == null ? '找排中' : this._rowHintText(this._curRow);
      patch.bigNote = this._abandonArm
        ? '⚠ 再点一次 DEL 放弃找座并清除目标'
        : this._curRow == null
          ? '看向排号牌点 ROW 拍它 · 读不到用 +1/−1 手动报排'
          : '当前 ' + this._curRow + ' 排（' + this._curRowSrc + '）· ROW 拍下一块排号牌';
    } else if (this._mode === 'gseat' && this._target) {
      patch.boxLabel = '◎ 找座中 — 就在这一排里，按座号差往里走';
      patch.bigLabel = '目标 ' + this._fmtSeat(this._target) + ' · 已在这一排';
      patch.bigText = this._curSeat == null ? '找座中' : this._seatHintText(this._curSeat);
      patch.bigNote = this._sitArm
        ? '⚠ 再点头一次（或再点 SIT）确认就座 — 目标立即清除'
        : this._abandonArm
          ? '⚠ 再点一次 DEL 放弃找座并清除目标'
          : this._curSeat == null
            ? '看向最近的座位号点 SEAT 拍它 · 读不到用 +1/−1 手动报座'
            : '当前 ' + this._curSeat + ' 座（' + this._curSeatSrc + '）· SEAT 拍下一个座位号 · 坐下点 SIT 两下';
    } else if (this._mode === 'done') {
      patch.boxLabel = '◎ 已就座 — 目标座位已从会话内存清除';
      patch.bigLabel = this._demo ? 'DEMO 完成 — 点 DEMO 退出演示' : '这一程记完了，清得干干净净';
      patch.bigText = '已就座';
      patch.bigNote = 'OK 开始新的找座 · 它没有留下任何座位记录';
    }
    patch.bigCls = this._bigClsFor(patch.bigText);
    this.setData(patch);
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">SEAT CATCH v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{capLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="rowTap">ROW</button>
      <button class="btn" bindtap="seatPhotoTap">SEAT</button>
      <button class="btn" bindtap="sitTap">SIT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="fieldTap">FIELD</button>
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="zoneTap">ZONE</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="delTap">DEL</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">无室内定位 · 靠逐排读号比对 · 目标只记这一次，坐下就清</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 2px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 1px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.biglabel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.bignum {
  color: #40ff5e;
  font-size: 34px;
  font-weight: 500;
  line-height: 38px;
  margin-top: 1px;
}
.bignum-sm {
  color: #40ff5e;
  font-size: 24px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-xs {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 1px;
}
.bignote {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 2px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 1px;
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
.list {
  flex-shrink: 0;
  height: 45px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-right: 8px;
}
.rdetail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 15px;
  flex-grow: 1;
}
.rflag {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 12px;
}
</style>
