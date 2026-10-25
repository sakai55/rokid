<script def>
{
  "navigationBarTitleText": "Sign Reader"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'AIM AT THE FAR SIGN, SNAP IT BIG',
    steadyText: 'HEAD: moving - hold still',
    headLine: 'HEAD: --- deg · SRC: NONE',
    capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
    typeLine: 'TYPE: 站牌 (tap TYPE) - tells READ what kind of sign',
    readLabel: 'READ: no read yet - the photo itself is never saved',
    keyText: '-',
    transText: '牌子全文会显示在这里（机器读的，可能读错）。',
    youLine: 'YOU READ: - (DICT what YOU read, to cross-check)',
    cmpLine: 'CHECK: not compared - literal text compare, not understanding',
    micLine: 'MIC CHECK: not run',
    boxLabel: '◎ KEY LINE - the one line you need, big; machine read, may misread',
    lastEvent: 'EVT: nod when steady = SPEAK (only when a KEY is showing)',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._cur = null;          // the sign in progress (photo Blob lives here, memory only)
    this._typeIdx = 0;         // sign-type chip, chosen before READ
    this._presetIdx = -1;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._sensor = null;
    this._demo = false;
    this._startHeading();
    this._renderAll();
    this.setData({ lastEvent: 'EVT: session only - nothing is stored on this device' });
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
    // Nothing is saved on unload either: this agent stores NOTHING.
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
    // A nod only SPEAKS a KEY line that is already on screen. It
    // never takes a photo, never starts a read, never dictates.
    if (this._cur && (this._cur.llmKey || this._cur.dictated)) {
      if (this._steady) this.speakTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to SPEAK' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - READ or DICT a KEY line first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (!this.data.busy && this._cur && (this._cur.llmKey || this._cur.dictated)) {
        this.speakTap();
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
  // as #25/#38: the preview host's Date is virtualised and drifts
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

  _types() {
    // Sign-type chips, picked before READ and passed to the model
    // as context so it knows what kind of KEY line to look for.
    return [
      { zh: '站牌', en: 'bus stop sign' },
      { zh: '登机口', en: 'airport departure gate sign' },
      { zh: '菜单', en: 'menu board' },
      { zh: '路牌', en: 'road / direction sign' },
      { zh: '其他', en: 'sign' }
    ];
  },

  _type() { return this._types()[this._typeIdx || 0]; },

  typeTap() {
    if (this.data.busy) return;
    this._typeIdx = ((this._typeIdx || 0) + 1) % this._types().length;
    var t = this._type();
    this.setData({
      typeLine: 'TYPE: ' + t.zh + ' (tap TYPE) - tells READ what kind of sign',
      lastEvent: 'EVT: sign type -> ' + t.zh + ' (' + t.en + '), applies to the next READ'
    });
  },

  _presets() {
    // Demo input for hosts with no recogniser (honest SKIP path):
    // sample "what you read" lines, cycled by DICT, labelled presets.
    return [
      '12 路 · 开往火车站（预置）',
      '今日特价：牛肉拉面 38 元（预置）',
      '前方 200 米 · 出口（预置）'
    ];
  },

  // ---------- heading (AbsoluteOrientationSensor, same as #07/#26/#38) ----------

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

  _newCur(fields) {
    var base = {
      blob: null, bytes: 0, wxPhoto: false, demo: false,
      heading: this._heading, date: '', time: '',
      llmKey: '', transcription: '', readSrc: '', readNote: '',
      dictated: '', dictSrc: ''
    };
    for (var k in fields) base[k] = fields[k];
    return base;
  },

  async capturePhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        capLine: 'CAP: FAIL - mediaDevices n/a on this host',
        status: 'SNAP FAIL - no camera here; DICT what you read instead',
        lastEvent: 'EVT: SNAP FAIL (host has no camera) - DICT still works'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (telephoto) the sign...' });
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
      this._cur = this._newCur({
        blob: blob, bytes: bytes, heading: this._heading, date: st.date, time: st.time
      });
      this.setData({
        capLine: 'CAP: ' + bytes + 'B telephoto · ' + st.time + ' · head ' +
          this._headText(this._heading) + ' · memory only, NOT saved',
        status: 'PHOTO HELD IN MEMORY - READ it, or DICT what YOU read',
        lastEvent: 'EVT: telephoto photo ' + bytes + 'B (memory only, never persisted)'
      });
      this._renderAll();
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
        this._cur = this._newCur({
          bytes: size, wxPhoto: true, heading: this._heading, date: st2.date, time: st2.time
        });
        this.setData({
          capLine: 'CAP: ' + size + 'B wx cam (fallback) · ' + st2.time + ' · memory only',
          status: 'PHOTO HELD (wx) - image read n/a for wx photos; DICT your line',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - READ cannot convert it)'
        });
        this._renderAll();
      } catch (e3) {
        this.setData({
          capLine: 'CAP: FAIL - ' + this._err(firstErr),
          status: 'SNAP FAIL - no photo; DICT what you read instead',
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
    var t = this._type();
    return [
      {
        type: 'text',
        text: 'This photo shows a sign of this kind: ' + t.en + ' (' + t.zh + '), ' +
          'seen from a distance. Transcribe ALL the text on the sign faithfully, line by line, ' +
          'exactly as written - keep numbers, times, gate or platform letters and prices exact; ' +
          'never invent text that is not visible - if a part is unreadable, write [?] there. ' +
          'First pick the single most important line on the sign - the one a traveller needs ' +
          'most: a gate or platform number, a bus route and its direction, a departure time, ' +
          'a dish and its price, or the main direction - copied verbatim from the sign. ' +
          'Reply in exactly this format:\n' +
          'KEY: <the single most important line, verbatim>\n' +
          'TEXT:\n' +
          '<the full transcription, line by line>'
      },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  _parseRead(text) {
    // Expected shape (asked for in the prompt):
    //   KEY: <the key line>
    //   TEXT:
    //   <transcription lines>
    // Salvage line-by-line if the labels drift, never reshape
    // silently: with no labels at all the first plain line becomes
    // the KEY and the rest the transcription.
    var lines = String(text || '').split('\n');
    var key = '';
    var trans = [];
    var plain = [];
    var inText = false;
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      if (!ln) continue;
      if (/^KEY[:：]/i.test(ln)) { key = ln.replace(/^KEY[:：]/i, '').trim(); continue; }
      if (/^TEXT[:：]/i.test(ln)) {
        inText = true;
        var rest = ln.replace(/^TEXT[:：]/i, '').trim();
        if (rest) trans.push(rest);
        continue;
      }
      if (inText) trans.push(ln);
      else plain.push(ln);
    }
    if (!key && plain.length) key = plain.shift();
    if (plain.length) trans = plain.concat(trans);
    var transcription = trans.join('\n').trim();
    if (!key && !transcription) return null;
    if (!key) key = '(no key line returned)';
    return { key: key.slice(0, 80), transcription: transcription.slice(0, 400), source: 'LLM' };
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
        initialPrompts: [{ role: 'system', content: 'You read signs from photos for a traveller wearing smart glasses. Follow the requested two-part format exactly, transcribe only what is visible, and never invent content.' }]
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
    var c = this._cur;
    if (!c) {
      this.setData({
        status: 'READ FAIL: SNAP a sign first (or DICT what you read)',
        lastEvent: 'EVT: READ refused - no sign pending'
      });
      return;
    }
    if (c.wxPhoto || !c.blob) {
      c.readNote = 'READ: image path n/a for a wx photo (no Blob to convert)';
      this.setData({
        status: 'READ N/A here - DICT what YOU read for this sign',
        lastEvent: 'EVT: READ skipped - wx photo cannot become a data: URL'
      });
      this._renderAll();
      return;
    }
    this.setData({ busy: true, status: 'READING the sign photo (host AI, image in)...' });
    try {
      var dataUrl;
      try {
        dataUrl = await this._withTimeout(this._blobToDataUrl(c.blob), 12000, 'convert');
      } catch (ce) {
        c.readNote = 'READ: image conversion unavailable here - ' + this._err(ce);
        this.setData({
          status: 'READ N/A - photo kept as record; DICT what YOU read',
          lastEvent: 'EVT: READ conversion FAIL - ' + this._err(ce)
        });
        this._renderAll();
        return;
      }
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
        c.readNote = 'READ: conversion returned no data: URL';
        this.setData({
          status: 'READ N/A - photo kept as record; DICT what YOU read',
          lastEvent: 'EVT: READ conversion FAIL - result was not a data: URL'
        });
        this._renderAll();
        return;
      }
      var r = await this._llmRead(dataUrl);
      if (!r.ok) {
        var why = r.reason === 'no-lm' ? 'no language model on this host'
          : r.reason === 'unavailable' ? 'language model unavailable now'
          : r.reason === 'empty' ? 'the model returned nothing readable'
          : 'model error - ' + this._err(r.error);
        c.readNote = 'READ: unavailable - ' + why;
        this.setData({
          status: 'READ FAILED - photo kept as record; DICT what YOU read',
          lastEvent: 'EVT: READ FAIL (' + r.reason + ') - dictate path offered'
        });
        this._renderAll();
        return;
      }
      c.readSrc = 'LLM';
      c.readNote = '';
      c.llmKey = r.parsed.key;
      c.transcription = r.parsed.transcription;
      this.setData({
        status: 'LLM READ done - big line below; DICT your reading to cross-check',
        lastEvent: 'EVT: LLM read ok (image input) - machine read, may be wrong'
      });
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  // ---------- DICT (dictate what YOU read - the cross-check, always available) ----------

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  _ensureCur() {
    if (this._cur) return this._cur;
    var st = this._stamp();
    this._cur = this._newCur({ heading: this._heading, date: st.date, time: st.time });
    this.setData({
      capLine: 'CAP: no photo - your dictated line only · ' + st.time,
      lastEvent: 'EVT: sign created by DICT (no photo for this sign)'
    });
    return this._cur;
  },

  _demoDictLine() {
    // In DEMO the "wearer's dictation" is seeded with the gate
    // number changed (12 -> 13), so the DIFF cross-check state
    // previews honestly, labelled DEMO.
    return '13 号登机口 · 东京羽田 · 15:40 开始登机';
  },

  dictTap() {
    if (this.data.busy) return;
    this._ensureCur();
    if (this._demo) {
      this._cur.dictated = this._demoDictLine();
      this._cur.dictSrc = 'DEMO';
      this.setData({
        status: 'YOUR LINE (DEMO dictation) - compare it with the machine KEY',
        lastEvent: 'EVT: DEMO dictation seeded (gate 13, machine read 12) - DIFF expected'
      });
      this._renderAll();
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. DICT cycles sample
      // "what you read" lines as demo input instead of pretending
      // to listen.
      var presets = this._presets();
      this._presetIdx = ((this._presetIdx || 0) + 1) % presets.length;
      this._cur.dictated = presets[this._presetIdx];
      this._cur.dictSrc = 'PRESET';
      this.setData({
        status: 'LINE preset (ASR n/a) - this stands in for your reading',
        lastEvent: 'EVT: DICT preset -> sample line (honest SKIP, no ASR)'
      });
      this._renderAll();
      return;
    }
    this._dictListen();
  },

  async _dictListen() {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (same documented pattern as
    // #21/#36/#38): open the wearer-mode stream, read back its
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
          var cur = self._ensureCur();
          cur.dictated = txt;
          cur.dictSrc = 'ASR';
          self.setData({
            status: 'YOUR LINE heard verbatim - compare it with the machine KEY',
            lastEvent: 'EVT: dictated line heard (' + micNote + ') - verbatim'
          });
          self._renderAll();
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
        status: 'DICT listening (host ASR) - say the key line as YOU read it',
        lastEvent: 'EVT: DICT listening (host ASR), ' + micNote
      });
      this._renderAll();
    } catch (e) {
      this.setData({
        busy: false,
        status: 'DICT FAIL - recogniser would not start',
        lastEvent: 'EVT: DICT start failed - ' + this._err(e)
      });
    }
  },

  // ---------- CHECK (literal comparison of machine KEY vs YOUR line) ----------

  _cmpNorm(s) {
    // Light normalisation ONLY: drop all whitespace and strip
    // trailing punctuation. The compare stays a literal text
    // compare - it does not understand either line.
    return String(s || '')
      .replace(/\s+/g, '')
      .replace(/[。．.，,、；;：:！!？?·•…—-]+$/g, '');
  },

  _compare() {
    var c = this._cur;
    if (!c || !c.llmKey || !c.dictated) return 'none';
    return this._cmpNorm(c.llmKey) === this._cmpNorm(c.dictated) ? 'match' : 'diff';
  },

  // ---------- SPEAK (reads the KEY line aloud, source announced) ----------

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

  _speakKeyText() {
    var c = this._cur;
    if (!c) return null;
    var cmp = this._compare();
    if (c.llmKey && c.dictated) {
      if (cmp === 'match') return '核对一致，牌子上写的是：' + c.llmKey;
      // DIFF: YOUR reading is spoken first and treated as the one
      // to trust; the machine's version is named as the machine's.
      return '按你读的：' + c.dictated + '。机器读的是：' + c.llmKey +
        '，两边不一样，请以你的眼睛为准。';
    }
    if (c.dictated) return '你读的是：' + c.dictated;
    if (c.llmKey) return '机器读数，可能读错：' + c.llmKey;
    return null;
  },

  speakTap() {
    if (this.data.busy) return;
    var c = this._cur;
    var text = this._speakKeyText();
    if (!text) {
      this.setData({
        status: 'SPEAK FAIL: no KEY line yet - READ the sign or DICT your line',
        lastEvent: 'EVT: SPEAK refused - nothing to read aloud'
      });
      return;
    }
    if (this._speakText(text)) {
      var src = (c.llmKey && c.dictated)
        ? (this._compare() === 'match' ? 'agreed line' : 'YOUR line first (DIFF)')
        : (c.dictated ? 'YOUR line' : 'machine KEY');
      this.setData({
        status: 'SPEAK - reading the KEY line (' + src + ')',
        lastEvent: 'EVT: TTS key line sent (' + src + ')'
      });
    }
  },

  // ---------- DEMO (one seeded gate-sign read, memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealCur = this._cur;
      this._demo = true;
    }
    // Seed time derives from ONE Date snapshot as pure arithmetic,
    // so it stays self-consistent on any host clock (#25 lesson).
    var snap = new Date();
    var dateStr = snap.getFullYear() + '-' + this._pad2(snap.getMonth() + 1) + '-' + this._pad2(snap.getDate());
    var timeStr = this._pad2(snap.getHours()) + ':' + this._pad2(snap.getMinutes());
    this._typeIdx = 1; // 登机口
    this._cur = this._newCur({
      demo: true, bytes: 0, heading: 120, date: dateStr, time: timeStr,
      readSrc: 'DEMO',
      llmKey: '12 号登机口 · 东京羽田 · 15:40 开始登机',
      transcription: 'ANA 386 · 东京羽田\n12 号登机口\n15:40 开始登机 · 16:10 起飞\n请提前 30 分钟到达登机口（DEMO 转写 - 不是真照片读数）',
      dictated: '', dictSrc: ''
    });
    this.setData({
      typeLine: 'TYPE: 登机口 (tap TYPE) - tells READ what kind of sign',
      capLine: 'CAP: DEMO - no camera used; photo bytes 0 (DEMO)',
      status: 'DEMO - gate sign read (DEMO); DICT seeds your line (gate 13) for a DIFF',
      lastEvent: 'EVT: DEMO on - seeded read (memory only, nothing saved)'
    });
    this._renderAll();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO restores the real session untouched (demo
      // reads and dictations never wrote anywhere).
      this._demo = false;
      this._cur = this._demoRealCur || null;
      this._demoRealCur = null;
      this.setData({
        capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
        status: 'DEMO OFF - your real session is back',
        lastEvent: 'EVT: DEMO cleared - real session restored, nothing was written'
      });
      this._renderAll();
      return;
    }
    this._cur = null;
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: 'CLEARED - nothing was stored anyway',
      lastEvent: 'EVT: session cleared (on-device only, nothing was uploaded)'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var c = this._cur;
    var patch = {};
    if (!c) {
      patch.readLabel = 'READ: no read yet - the photo itself is never saved';
      patch.keyText = '-';
      patch.transText = '牌子全文会显示在这里（机器读的，可能读错）。';
      patch.youLine = 'YOU READ: - (DICT what YOU read, to cross-check)';
      patch.cmpLine = 'CHECK: not compared - literal text compare, not understanding';
      patch.boxLabel = '◎ KEY LINE - the one line you need, big; machine read, may misread';
    } else {
      if (c.readSrc === 'LLM') {
        patch.readLabel = 'LLM READ - may misread, check it with your own eyes';
      } else if (c.readSrc === 'DEMO') {
        patch.readLabel = 'LLM READ (DEMO) - seeded text, not a real photo read';
      } else if (c.readNote) {
        patch.readLabel = c.readNote;
      } else {
        patch.readLabel = 'READ: no machine read - your own line can still be the KEY';
      }
      patch.keyText = c.llmKey || (c.dictated ? c.dictated : '-');
      patch.transText = c.transcription || (c.llmKey
        ? '(no full transcription returned)'
        : '牌子全文会显示在这里（机器读的，可能读错）。');
      patch.youLine = c.dictated
        ? 'YOU READ (' + (c.dictSrc || 'ASR') + '): ' + c.dictated
        : 'YOU READ: - (DICT what YOU read, to cross-check)';
      var cmp = this._compare();
      if (cmp === 'match') {
        patch.cmpLine = 'CHECK: MATCH ✓ - your line and the machine KEY agree';
      } else if (cmp === 'diff') {
        patch.cmpLine = 'CHECK: DIFF ⚠ - trust YOUR eyes, or SNAP closer and READ again';
      } else {
        patch.cmpLine = 'CHECK: not compared - literal text compare, not understanding';
      }
      patch.boxLabel = c.llmKey
        ? '◎ KEY LINE (machine) - big; DICT your reading to cross-check it'
        : '◎ KEY LINE (yours) - from your dictation; no machine read';
    }
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">SIGN READER</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{headLine}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="photo">{{capLine}}</text>
      <text class="photo">{{typeLine}}</text>
      <text class="photo">{{readLabel}}</text>
      <text class="key">{{keyText}}</text>
      <text class="trans">{{transText}}</text>
      <text class="you">{{youLine}}</text>
      <text class="cmp">{{cmpLine}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="readTap">READ</button>
      <button class="btn" bindtap="typeTap">TYPE</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </view>
    <text class="sub">photos NOT saved · nothing is stored · session only</text>
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
.key {
  color: #40ff5e;
  font-size: 23px;
  font-weight: 500;
  line-height: 29px;
  margin-top: 2px;
}
.trans {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.you {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 2px;
}
.cmp {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
</style>
