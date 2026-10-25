<script def>
{
  "navigationBarTitleText": "Board Capture"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'AIM AT THE BOARD, SNAP IT BEFORE IT IS WIPED',
    steadyText: 'HEAD: moving - hold still',
    headLine: 'HEAD: --- deg · SRC: NONE',
    capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
    readLabel: 'READ: no read yet - the photo itself is never saved',
    sumText: 'SUMMARY: -',
    transText: '板书转写会显示在这里（机器读的，先核对再 KEEP）。',
    micLine: 'MIC CHECK: not run',
    countLine: 'OUTLINE: 0/8 · text saved on device · photos NOT saved',
    rows: [
      { name: '(no captures)', detail: 'SNAP + READ a board, KEEP files it - or DEMO', flag: '', cls: 'row' }
    ],
    boxLabel: '◎ THIS BOARD - photo in memory only; READ sends it to the AI as an image',
    lastEvent: 'EVT: nod when steady = KEEP (only with a read or dictated line pending)',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._captures = this._loadCaptures(); // filed text entries, capture order
    this._nextSeq = 1;
    for (var i = 0; i !== this._captures.length; i++) {
      if (this._captures[i].seq >= this._nextSeq) this._nextSeq = this._captures[i].seq + 1;
    }
    this._pending = null;      // the board in progress (photo Blob lives here, memory only)
    this._presetIdx = -1;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._sensor = null;
    this._demo = false;
    this._startHeading();
    this._renderAll();
    this.setData({ lastEvent: 'EVT: ' + this._captures.length + ' saved capture(s) on this device' });
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
  },

  onHide() {
    this._stopHeading();
    this._stopDictRec();
  },

  onUnload() {
    this._stopHeading();
    this._stopDictRec();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    this._saveCaptures();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    // A nod only KEEPS a result that is already on screen - a finished
    // LLM read or your own dictated line, checked by your eyes. It
    // never takes a photo and never starts a read by itself.
    if (this._pending && (this._pending.readText || this._pending.dictated)) {
      if (this._steady) this.keepTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to KEEP' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - READ or DICT first, then KEEP' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (!this.data.busy && this._pending && (this._pending.readText || this._pending.dictated)) {
        this.keepTap();
      }
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

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // ONE clock snapshot -> {date, time} as pure strings (same lesson
  // as DI25/DI38: the preview host's Date is virtualised and drifts
  // between calls, so one capture's date + time come from one read).
  _stamp() {
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      time: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
  },

  _headText(h) {
    return (h === null || h === undefined || !isFinite(h)) ? '---' : String(Math.round(h)) + ' deg';
  },

  _presets() {
    // Demo input for hosts with no recogniser (honest SKIP path):
    // sample summary lines, cycled by DICT, labelled as presets.
    return [
      '二次函数图像与性质（预置）',
      '牛顿第二定律推导（预置）',
      '会议结论：下周上线（预置）',
      '季度销售数据复盘（预置）'
    ];
  },

  // ---------- persistence (wx sync storage, key 'boardCaptures', max 8, TEXT ONLY) ----------

  _loadCaptures() {
    try {
      var raw = wx.getStorageSync('boardCaptures');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 8; i++) {
        var it = raw[i];
        if (it && typeof it.summary === 'string' && typeof it.time === 'string') {
          out.push({
            seq: isFinite(it.seq) ? it.seq : out.length + 1,
            date: String(it.date || '').slice(0, 10),
            time: String(it.time).slice(0, 5),
            heading: isFinite(it.heading) ? ((Math.round(it.heading) % 360) + 360) % 360 : null,
            summary: String(it.summary).slice(0, 60),
            transcription: String(it.transcription || '').slice(0, 400),
            src: String(it.src || 'NONE').slice(0, 8)
          });
        }
      }
      out.sort(function (a, b) { return a.seq - b.seq; });
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveCaptures() {
    if (this._demo) return; // demo entries never touch real storage
    try {
      wx.setStorageSync('boardCaptures', this._captures || []);
    } catch (e) { /* storage unavailable on this host: captures stay in memory */ }
  },

  // ---------- heading (AbsoluteOrientationSensor, same as DI07/DI26/DI38) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._renderHead();
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
        self._renderHead();
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
    var deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    var changed = this._heading === null || Math.abs(deg - this._heading) >= 1;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (changed) this._renderHead();
  },

  _renderHead() {
    this.setData({
      headLine: 'HEAD: ' + this._headText(this._heading) + ' · SRC: ' + this._headingSrc
    });
  },

  // ---------- SNAP (telephoto photo, memory only - the photo is NEVER saved) ----------

  snapTap() { this.capturePhoto(); },

  async capturePhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        capLine: 'CAP: FAIL - mediaDevices n/a on this host',
        status: 'SNAP FAIL - no camera here; DICT a line instead',
        lastEvent: 'EVT: SNAP FAIL (host has no camera) - DICT still works'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (telephoto) the board...' });
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
      var st = this._stamp();
      this._pending = {
        blob: blob, bytes: bytes, wxPhoto: false,
        heading: this._heading, date: st.date, time: st.time,
        readText: '', summary: '', transcription: '', dictated: ''
      };
      this.setData({
        capLine: 'CAP: ' + bytes + 'B telephoto · ' + st.time + ' · head ' +
          this._headText(this._heading) + ' · memory only, NOT saved',
        status: 'PHOTO HELD IN MEMORY - READ it, or DICT your own line',
        lastEvent: 'EVT: telephoto photo ' + bytes + 'B (memory only, never persisted)'
      });
      this._renderPending();
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like the sibling agents. A wx
      // photo has no Blob to convert, so READ will honestly report
      // the image path unavailable for it - DICT remains the path.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        var st2 = this._stamp();
        this._pending = {
          blob: null, bytes: size, wxPhoto: true,
          heading: this._heading, date: st2.date, time: st2.time,
          readText: '', summary: '', transcription: '', dictated: ''
        };
        this.setData({
          capLine: 'CAP: ' + size + 'B wx cam (fallback) · ' + st2.time + ' · memory only',
          status: 'PHOTO HELD (wx) - image read n/a for wx photos; DICT a line',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - READ cannot convert it)'
        });
        this._renderPending();
      } catch (e3) {
        this.setData({
          capLine: 'CAP: FAIL - ' + this._err(firstErr),
          status: 'SNAP FAIL - no photo; DICT a summary line instead',
          lastEvent: 'EVT: SNAP FAIL - ' + this._err(firstErr)
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

  // ---------- READ (photo -> data: URL -> host LLM image input, the official read-text path) ----------

  _blobToDataUrl(blob) {
    // The ONLY conversion the runtime story offers: Blob -> data: URL
    // via FileReader. If FileReader is missing this rejects, and READ
    // lands in the honest conversion-unavailable state.
    return new Promise(function (resolve, reject) {
      if (typeof FileReader === 'undefined') {
        reject(new Error('FileReader n/a on this host'));
        return;
      }
      var fr = new FileReader();
      fr.onload = function () { resolve(String(fr.result || '')); };
      fr.onerror = function () { reject(new Error('FileReader read failed')); };
      try { fr.readAsDataURL(blob); } catch (e) { reject(e); }
    });
  },

  _buildReadContent(dataUrl) {
    // Multimodal content goes in the USER message only (dossier
    // section 2.9): one text part with the instructions, one
    // image_url part carrying the data: URL. The system prompt is
    // set separately via initialPrompts at create() time.
    return [
      {
        type: 'text',
        text: 'This photo shows a blackboard or whiteboard in a class or a meeting. ' +
          'Transcribe ALL the writing in the photo faithfully, line by line, keeping formulas, ' +
          'numbers and symbols exactly as written; never invent content that is not visible - ' +
          'if a part is unreadable, write [?] there. Then give a one-line summary in Chinese of ' +
          'what this board is about. Reply in exactly this format:\n' +
          'SUMMARY: <one-line summary in Chinese>\n' +
          'TEXT:\n' +
          '<the faithful transcription, line by line>'
      },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  _parseRead(text) {
    // Expected shape (asked for in the prompt):
    //   SUMMARY: <one-line summary>
    //   TEXT:
    //   <transcription lines>
    // Salvage line-by-line if the labels drift, never reshape
    // silently: unlabeled lines before TEXT join the transcription
    // too, and the first plain line becomes the summary when the
    // SUMMARY label is missing.
    var lines = String(text || '').split('\n');
    var summary = '';
    var trans = [];
    var plain = [];
    var inText = false;
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      if (!ln) continue;
      if (/^SUMMARY[:：]/i.test(ln)) { summary = ln.replace(/^SUMMARY[:：]/i, '').trim(); continue; }
      if (/^TEXT[:：]/i.test(ln)) {
        inText = true;
        var rest = ln.replace(/^TEXT[:：]/i, '').trim();
        if (rest) trans.push(rest);
        continue;
      }
      if (inText) trans.push(ln);
      else plain.push(ln);
    }
    if (!summary && plain.length) summary = plain.shift();
    if (plain.length) trans = plain.concat(trans);
    var transcription = trans.join('\n').trim();
    if (!summary && !transcription) return null;
    if (!summary) summary = '(no summary)';
    return { summary: summary.slice(0, 60), transcription: transcription.slice(0, 400), source: 'LLM' };
  },

  async _llmRead(dataUrl) {
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
        initialPrompts: [{ role: 'system', content: 'You transcribe blackboards and whiteboards from photos. Follow the requested two-part format exactly, transcribe only what is visible, and never invent content.' }]
      });
      var ans = await this._withTimeout(session.prompt(this._buildReadContent(dataUrl)), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var parsed = this._parseRead(ans);
      if (!parsed) return { ok: false, reason: 'empty' };
      return { ok: true, parsed: parsed };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  async readTap() {
    if (this.data.busy) return;
    var p = this._pending;
    if (!p) {
      this.setData({
        status: 'READ FAIL: SNAP a board first (or DICT a line)',
        lastEvent: 'EVT: READ refused - no capture pending'
      });
      return;
    }
    if (p.wxPhoto || !p.blob) {
      this.setData({
        readLabel: 'READ: image path n/a for a wx photo (no Blob to convert)',
        status: 'READ N/A here - DICT your own summary line for this board',
        lastEvent: 'EVT: READ skipped - wx photo cannot become a data: URL'
      });
      this._renderPending();
      return;
    }
    this.setData({ busy: true, status: 'READING the board photo (host AI, image in)...' });
    try {
      var dataUrl;
      try {
        dataUrl = await this._withTimeout(this._blobToDataUrl(p.blob), 12000, 'convert');
      } catch (ce) {
        this.setData({
          readLabel: 'READ: image conversion unavailable here - ' + this._err(ce),
          status: 'READ N/A - photo kept as record; DICT your own line',
          lastEvent: 'EVT: READ conversion FAIL - ' + this._err(ce)
        });
        this._renderPending();
        return;
      }
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
        this.setData({
          readLabel: 'READ: conversion returned no data: URL',
          status: 'READ N/A - photo kept as record; DICT your own line',
          lastEvent: 'EVT: READ conversion FAIL - result was not a data: URL'
        });
        this._renderPending();
        return;
      }
      var r = await this._llmRead(dataUrl);
      if (!r.ok) {
        var why = r.reason === 'no-lm' ? 'no language model on this host'
          : r.reason === 'unavailable' ? 'language model unavailable now'
          : r.reason === 'empty' ? 'the model returned nothing readable'
          : 'model error - ' + this._err(r.error);
        this.setData({
          readLabel: 'READ: unavailable - ' + why,
          status: 'READ FAILED - photo kept as record; DICT your own line, or KEEP bare',
          lastEvent: 'EVT: READ FAIL (' + r.reason + ') - dictate path offered'
        });
        this._renderPending();
        return;
      }
      p.readText = 'LLM';
      p.summary = r.parsed.summary;
      p.transcription = r.parsed.transcription;
      this.setData({
        status: 'LLM READ done - VERIFY it against the board, then KEEP',
        lastEvent: 'EVT: LLM read ok (image input) - machine read, NOT auto-saved'
      });
      this._renderPending();
    } finally {
      this.setData({ busy: false });
    }
  },

  // ---------- DICT (dictate YOUR summary line; the pre-audit design, always available) ----------

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  _ensurePending() {
    if (this._pending) return this._pending;
    var st = this._stamp();
    this._pending = {
      blob: null, bytes: 0, wxPhoto: false,
      heading: this._heading, date: st.date, time: st.time,
      readText: '', summary: '', transcription: '', dictated: ''
    };
    this.setData({
      capLine: 'CAP: no photo - dictated line only · ' + st.time,
      lastEvent: 'EVT: pending created by DICT (no photo for this board)'
    });
    return this._pending;
  },

  dictTap() {
    if (this.data.busy) return;
    this._ensurePending();
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. DICT cycles sample
      // summary lines as demo input instead of pretending to listen.
      var presets = this._presets();
      this._presetIdx = ((this._presetIdx || 0) + 1) % presets.length;
      this._pending.dictated = presets[this._presetIdx];
      this.setData({
        status: 'LINE preset (ASR n/a) - check it, then KEEP',
        lastEvent: 'EVT: DICT preset -> sample summary line (honest SKIP, no ASR)'
      });
      this._renderPending();
      return;
    }
    this._dictListen();
  },

  async _dictListen() {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (same documented pattern as
    // DI21/DI36/DI38): open the wearer-mode stream, read back its
    // settings, stop every track at once. The check stream is NOT
    // the recognition input and does not shape what recognition
    // hears - the host SpeechRecognition below listens on its own
    // microphone (dossier sections 2.4 / 2.8). The result is shown
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
          self._ensurePending().dictated = txt;
          self.setData({
            status: 'YOUR LINE heard - it replaces any LLM summary; KEEP files it',
            lastEvent: 'EVT: dictated line heard (' + micNote + ') - verbatim'
          });
          self._renderPending();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'DICT FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + ', tap DICT again',
          lastEvent: 'EVT: DICT ASR error'
        });
      };
      rec.onend = function () {
        if (self._dictRec === rec) self._dictRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'DICT listening (host ASR)...',
        lastEvent: 'EVT: DICT listening (host ASR), ' + micNote
      });
      this._renderPending();
    } catch (e) {
      this.setData({
        busy: false,
        status: 'DICT FAIL - recogniser would not start',
        lastEvent: 'EVT: DICT start failed - ' + this._err(e)
      });
    }
  },

  // ---------- KEEP (the only way a capture is ever filed) ----------

  keepTap() {
    if (this.data.busy) return;
    var p = this._pending;
    if (!p) {
      this.setData({
        status: 'KEEP FAIL: SNAP or DICT first - nothing pending',
        lastEvent: 'EVT: KEEP refused - nothing to file'
      });
      return;
    }
    // Summary choice is the wearer's, in order: their own dictated
    // line beats the machine's summary; no line at all is filed
    // honestly as (no summary). Nothing is ever filed silently.
    var summary, src;
    if (p.dictated) { summary = p.dictated; src = 'DICT'; }
    else if (p.readText && p.summary) { summary = p.summary; src = 'LLM'; }
    else { summary = '(no summary)'; src = 'NONE'; }
    var entry = {
      seq: this._nextSeq++,
      date: p.date, time: p.time, heading: p.heading,
      summary: String(summary).slice(0, 60),
      transcription: p.transcription || '',
      src: p.demo ? 'DEMO' : src
    };
    this._captures.push(entry);
    var dropped = null;
    while (this._captures.length > 8) dropped = this._captures.shift();
    this._saveCaptures();
    this._pending = null;
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      readLabel: 'READ: no read yet - the photo itself is never saved',
      sumText: 'SUMMARY: -',
      transText: '板书转写会显示在这里（机器读的，先核对再 KEEP）。',
      status: 'KEPT #' + entry.seq + ' (' + entry.src + ')' +
        (dropped ? ' - oldest #' + dropped.seq + ' dropped (cap 8)' : '') +
        ' - outline ' + this._captures.length + '/8',
      lastEvent: 'EVT: filed #' + entry.seq + ' src ' + entry.src +
        (dropped ? '; dropped oldest #' + dropped.seq + ' at cap 8' : '') +
        ' - TEXT saved, photo already gone'
    });
    this._renderAll();
  },

  // ---------- OUTLINE (SPEAK the summaries back in capture order) ----------

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

  _outlineText() {
    var parts = [];
    for (var i = 0; i !== this._captures.length; i++) {
      var c = this._captures[i];
      parts.push('第' + (i + 1) + '张：' + c.summary);
    }
    return parts.join('。');
  },

  outlineTap() {
    if (!this._captures.length) {
      this.setData({
        status: 'OUTLINE: no captures yet - SNAP + READ + KEEP one first',
        lastEvent: 'EVT: OUTLINE refused - outline empty'
      });
      return;
    }
    if (this._speakText(this._outlineText())) {
      this.setData({
        status: 'OUTLINE - reading ' + this._captures.length + ' summaries in capture order',
        lastEvent: 'EVT: TTS outline sent (' + this._captures.length + ' lines, seq order)'
      });
    }
  },

  // ---------- DEMO (seeded captures + one seeded read, memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealCaptures = this._captures;
      this._demoRealSeq = this._nextSeq;
      this._demoRealPending = this._pending;
      this._demo = true;
    }
    // Seed times derive from ONE Date snapshot as pure arithmetic,
    // so they stay self-consistent on any host clock (DI25 lesson).
    var snap = new Date();
    var fmt = function (d) {
      return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
    }.bind(this);
    var t1 = new Date(snap.getTime());
    var t2 = new Date(snap.getTime() + 6 * 60000);
    var t3 = new Date(snap.getTime() + 11 * 60000);
    var dateStr = snap.getFullYear() + '-' + this._pad2(snap.getMonth() + 1) + '-' + this._pad2(snap.getDate());
    this._captures = [
      {
        seq: 1, date: dateStr, time: fmt(t1), heading: 30,
        summary: '二次函数顶点式推导',
        transcription: 'y = a(x-h)² + k\n顶点 (h, k)，对称轴 x = h\n例：y = 2(x-3)² + 1，顶点 (3, 1)',
        src: 'DEMO'
      },
      {
        seq: 2, date: dateStr, time: fmt(t2), heading: 75,
        summary: '例题：抛物线与 x 轴的交点',
        transcription: '令 y = 0：2(x-3)² + 1 = 0\n(x-3)² = -1/2 无实数解\n结论：与 x 轴无交点',
        src: 'DEMO'
      }
    ];
    this._nextSeq = 3;
    // One board is mid-flight: "read" already, waiting on KEEP, so
    // the verify-then-file state previews without any camera or AI.
    this._pending = {
      blob: null, bytes: 0, wxPhoto: false, demo: true,
      heading: 75, date: dateStr, time: fmt(t3),
      readText: 'DEMO',
      summary: '动量守恒定律例题',
      transcription: '例：光滑水平面，m1=2kg 以 3m/s 撞向静止的 m2=1kg，碰后粘连。\nm1·v1 = (m1+m2)·v 共 → v 共 = 2m/s（DEMO 转写 - 不是真照片读数）',
      dictated: ''
    };
    this.setData({
      capLine: 'CAP: DEMO - no camera used; photo bytes 0 (DEMO)',
      status: 'DEMO - 2 boards filed, 1 LLM READ (DEMO) waiting: verify, then KEEP',
      lastEvent: 'EVT: DEMO on - seeded captures + seeded read (memory only, nothing saved)'
    });
    this._renderAll();
    this._renderPending();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO restores the real captures untouched (demo
      // reads and keeps never wrote to real storage).
      this._demo = false;
      this._captures = this._demoRealCaptures || this._loadCaptures();
      this._nextSeq = this._demoRealSeq || 1;
      this._pending = this._demoRealPending || null;
      this._demoRealCaptures = null;
      this._demoRealPending = null;
      this.setData({
        capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
        status: 'DEMO OFF - your real outline is back (' + this._captures.length + ' captures)',
        lastEvent: 'EVT: DEMO cleared - real captures restored, nothing was written'
      });
      this._renderAll();
      this._renderPending();
      return;
    }
    this._captures = [];
    this._nextSeq = 1;
    this._pending = null;
    this._saveCaptures();
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      readLabel: 'READ: no read yet - the photo itself is never saved',
      sumText: 'SUMMARY: -',
      transText: '板书转写会显示在这里（机器读的，先核对再 KEEP）。',
      status: 'OUTLINE CLEARED - 0/8',
      lastEvent: 'EVT: outline emptied (on-device only, nothing was uploaded)'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderPending() {
    var p = this._pending;
    if (!p) {
      this._renderAll();
      return;
    }
    var patch = {};
    if (p.readText === 'LLM') {
      patch.readLabel = 'LLM READ - may misread, verify against the board';
      patch.sumText = 'SUMMARY (AI): ' + (p.summary || '-');
      patch.transText = p.transcription || '(no transcription returned)';
    } else if (p.readText === 'DEMO') {
      patch.readLabel = 'LLM READ (DEMO) - seeded text, not a real photo read';
      patch.sumText = 'SUMMARY (AI, DEMO): ' + (p.summary || '-');
      patch.transText = p.transcription || '-';
    }
    if (p.dictated) {
      patch.sumText = 'SUMMARY (yours): ' + p.dictated;
      if (!p.readText) patch.readLabel = 'READ: none - your dictated line is the summary';
    }
    if (patch.readLabel || patch.sumText) this.setData(patch);
    this._renderAll();
  },

  _renderAll() {
    var rows = [];
    for (var i = 0; i !== this._captures.length; i++) {
      var c = this._captures[i];
      rows.push({
        name: '#' + c.seq + ' ' + c.time + ' · ' + this._headText(c.heading),
        detail: c.summary,
        flag: c.src,
        cls: 'row'
      });
    }
    if (!rows.length) {
      rows.push({
        name: '(no captures)',
        detail: 'SNAP + READ a board, KEEP files it - or DEMO',
        flag: '',
        cls: 'row'
      });
    }
    var p = this._pending;
    this.setData({
      rows: rows,
      countLine: 'OUTLINE: ' + this._captures.length + '/8 · text saved on device · photos NOT saved',
      boxLabel: p
        ? (p.readText
          ? '◎ READ RESULT PENDING - verify it, KEEP files it, DICT replaces the summary'
          : '◎ THIS BOARD - photo in memory only; READ sends it to the AI as an image')
        : '◎ THIS BOARD - photo in memory only; READ sends it to the AI as an image'
    });
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">BOARD CAPTURE</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{headLine}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="photo">{{capLine}}</text>
      <text class="photo">{{readLabel}}</text>
      <text class="sum">{{sumText}}</text>
      <text class="trans">{{transText}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="readTap">READ</button>
      <button class="btn btn-main" bindtap="dictTap">DICT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="keepTap">KEEP</button>
      <button class="btn" bindtap="outlineTap">OUTLINE</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
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
.sum {
  color: #40ff5e;
  font-size: 13px;
  line-height: 16px;
  margin-top: 2px;
}
.trans {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
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
  height: 63px;
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
</style>
