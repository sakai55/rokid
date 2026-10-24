<script def>
{
  "navigationBarTitleText": "Badge Reader"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'AIM AT THE BADGE IN FRONT OF YOU, THEN SNAP',
    steadyText: 'HEAD: moving - hold still',
    headLine: 'HEAD: --- deg · SRC: NONE',
    capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
    readLabel: 'READ: no read yet - the photo itself is never saved',
    nameText: '-',
    orgLine: 'ORG: - · TITLE: -',
    youLine: 'YOU SAID: - (DICT the name as YOU read it, to cross-check)',
    cmpLine: 'CHECK: not compared - literal text compare, not understanding',
    micLine: 'MIC CHECK: not run',
    meetLine: 'CARD: face a saved direction 2 s - the name pops here',
    meetCls: 'meet',
    countLine: 'PEOPLE: 0/12 · text only, saved on this device',
    rows: [
      { text: '(nobody saved) - SNAP a badge, or DEMO' }
    ],
    lastEvent: 'EVT: people bind to a DIRECTION, never to a face',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._cur = null;          // the badge in progress (photo Blob lives here, memory only)
    this._people = this._loadPeople();
    this._idSeq = 0;
    for (var i = 0; i !== this._people.length; i++) {
      if (this._people[i].id > this._idSeq) this._idSeq = this._people[i].id;
    }
    this._face = {};           // per-person re-meet state, keyed by person id
    this._selIdx = 0;
    this._presetIdx = -1;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._sensor = null;
    this._timer = null;
    this._demo = false;
    this._demoSteps = 0;
    this._demoHeading = 0;
    this._demoRealPeople = null;
    this._demoRealCur = null;
    this._startHeading();
    this._startTimer();
    this._renderAll();
    this.setData({ lastEvent: 'EVT: saved people live on this device only (text)' });
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
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    // A nod only SPEAKS a name that is already on screen (a pending
    // read, or a re-meet card). It never takes a photo and never
    // saves a person - saving takes an explicit tap / Enter.
    if (this._facingPerson() || (this._cur && (this._cur.llmName || this._cur.dictated))) {
      if (this._steady) this.speakTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to SPEAK' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - READ or DICT a name first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowDown') {
      this._cycleSel(1);
    } else if (code === 'ArrowUp') {
      this._cycleSel(-1);
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      this._primaryTap();
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

  // Contextual primary action (temple-pad single tap / Enter):
  // a dictated line is waiting -> SAVE the person; a machine read
  // is waiting -> SPEAK it; a re-meet card is up -> SPEAK it;
  // otherwise SNAP a badge.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._cur && this._cur.dictated) { this.saveTap(); return; }
    if (this._cur && this._cur.llmName) { this.speakTap(); return; }
    if (this._facingPerson()) { this.speakTap(); return; }
    this.capturePhoto();
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
  // between calls, so one record's date + time come from one read).
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

  // ---------- persistence (wx sync storage, key 'badgePeople', max 12, TEXT only) ----------

  _loadPeople() {
    try {
      var raw = wx.getStorageSync('badgePeople');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 12; i++) {
        var r = raw[i];
        if (r && typeof r.name === 'string' && r.name &&
            isFinite(r.heading) && typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            id: isFinite(r.id) ? r.id : out.length + 1,
            name: String(r.name).slice(0, 24),
            org: typeof r.org === 'string' ? String(r.org).slice(0, 32) : '',
            title: typeof r.title === 'string' ? String(r.title).slice(0, 24) : '',
            src: (r.src === 'llm' || r.src === 'dict' || r.src === 'both') ? r.src : 'llm',
            heading: ((Math.round(r.heading) % 360) + 360) % 360,
            date: String(r.date).slice(0, 10),
            time: String(r.time).slice(0, 5),
            demo: false
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _persist() {
    // Only real people are written, and only their TEXT fields -
    // never a photo, never a Blob, never a data: URL. DEMO people
    // and DEMO sessions write nothing at all.
    if (this._demo) return;
    try {
      var out = [];
      var list = this._people || [];
      for (var i = 0; i !== list.length; i++) {
        var p = list[i];
        if (p.demo) continue;
        out.push({
          id: p.id, name: p.name, org: p.org, title: p.title, src: p.src,
          heading: p.heading, date: p.date, time: p.time
        });
      }
      wx.setStorageSync('badgePeople', out);
    } catch (e) { /* storage unavailable on this host: people stay in memory */ }
  },

  // Beyond 12 people the OLDEST is dropped; the caller hears about
  // it (EVT note) - a person is never dropped silently.
  _addPerson(rec) {
    var arr = this._people || [];
    arr.push(rec);
    var dropped = null;
    while (arr.length > 12) dropped = arr.shift();
    this._people = arr;
    if (dropped) delete this._face[dropped.id];
    this._persist();
    return dropped;
  },

  // ---------- heading (AbsoluteOrientationSensor, same as #07/#38/#41) ----------

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
    if (this._demo) return; // demo heading wins while simulating
    var deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    var changed = this._heading === null || Math.abs(deg - this._heading) >= 1;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (changed) this._renderAll();
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
      llmName: '', org: '', title: '', readSrc: '', readNote: '',
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
        status: 'SNAP FAIL - no camera here; DICT the name instead',
        lastEvent: 'EVT: SNAP FAIL (host has no camera) - DICT still works'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (telephoto) the badge...' });
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
      // The heading at THIS instant is the whole point: it is the
      // direction of the person standing in front of you.
      this._cur = this._newCur({
        blob: blob, bytes: bytes, heading: this._heading, date: st.date, time: st.time
      });
      this.setData({
        capLine: 'CAP: ' + bytes + 'B telephoto · ' + st.time + ' · head ' +
          this._headText(this._heading) + ' · memory only, NOT saved',
        status: 'BADGE HELD IN MEMORY - READ it, or DICT the name yourself',
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
          status: 'BADGE HELD (wx) - image read n/a for wx photos; DICT the name',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - READ cannot convert it)'
        });
        this._renderAll();
      } catch (e3) {
        this.setData({
          capLine: 'CAP: FAIL - ' + this._err(firstErr),
          status: 'SNAP FAIL - no photo; DICT the name instead',
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
        text: 'This photo shows a name badge worn by a person at a social or work event. ' +
          'Read the badge faithfully, exactly as printed - keep the name, the company or ' +
          'organisation, and the job title or role exact; never invent text that is not ' +
          'visible - if a part is unreadable, write [?] there. If a field is not on the ' +
          'badge at all, leave it empty after its label. Reply in exactly this format:\n' +
          'NAME: <the person\'s name, verbatim>\n' +
          'ORG: <the company or organisation, verbatim>\n' +
          'TITLE: <the job title or role, verbatim>'
      },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  _parseBadge(text) {
    // Expected shape (asked for in the prompt):
    //   NAME: <name>
    //   ORG: <organisation>
    //   TITLE: <title>
    // Salvage line-by-line if the labels drift, never reshape
    // silently: unlabeled lines fill NAME, then ORG, then TITLE
    // in order. Returns null when nothing usable came back.
    var lines = String(text || '').split('\n');
    var name = '', org = '', title = '';
    var plain = [];
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      if (!ln) continue;
      if (/^NAME[:：]/i.test(ln)) { name = ln.replace(/^NAME[:：]/i, '').trim(); continue; }
      if (/^ORG[:：]/i.test(ln)) { org = ln.replace(/^ORG[:：]/i, '').trim(); continue; }
      if (/^TITLE[:：]/i.test(ln)) { title = ln.replace(/^TITLE[:：]/i, '').trim(); continue; }
      plain.push(ln);
    }
    if (!name && plain.length) name = plain.shift();
    if (!org && plain.length) org = plain.shift();
    if (!title && plain.length) title = plain.shift();
    name = name.slice(0, 24); org = org.slice(0, 32); title = title.slice(0, 24);
    if (!name && !org && !title) return null;
    return { name: name, org: org, title: title, source: 'LLM' };
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
        initialPrompts: [{ role: 'system', content: 'You read name badges from photos for a wearer of smart glasses who cannot read the badge themselves. Follow the requested three-line format exactly, transcribe only what is visible, and never invent content.' }]
      });
      var ans = await this._withTimeout(session.prompt(this._buildReadContent(dataUrl)), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var parsed = this._parseBadge(ans);
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
        status: 'READ FAIL: SNAP a badge first (or DICT the name)',
        lastEvent: 'EVT: READ refused - no badge pending'
      });
      return;
    }
    if (c.wxPhoto || !c.blob) {
      c.readNote = 'READ: image path n/a for a wx photo (no Blob to convert)';
      this.setData({
        status: 'READ N/A here - DICT the name for this badge',
        lastEvent: 'EVT: READ skipped - wx photo cannot become a data: URL'
      });
      this._renderAll();
      return;
    }
    this.setData({ busy: true, status: 'READING the badge photo (host AI, image in)...' });
    try {
      var dataUrl;
      try {
        dataUrl = await this._withTimeout(this._blobToDataUrl(c.blob), 12000, 'convert');
      } catch (ce) {
        c.readNote = 'READ: image conversion unavailable here - ' + this._err(ce);
        this.setData({
          status: 'READ N/A - photo kept as record; DICT the name',
          lastEvent: 'EVT: READ conversion FAIL - ' + this._err(ce)
        });
        this._renderAll();
        return;
      }
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
        c.readNote = 'READ: conversion returned no data: URL';
        this.setData({
          status: 'READ N/A - photo kept as record; DICT the name',
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
          status: 'READ FAILED - photo kept as record; DICT the name',
          lastEvent: 'EVT: READ FAIL (' + r.reason + ') - dictate path offered'
        });
        this._renderAll();
        return;
      }
      c.readSrc = 'LLM';
      c.readNote = '';
      c.llmName = r.parsed.name;
      c.org = r.parsed.org;
      c.title = r.parsed.title;
      this.setData({
        status: 'LLM READ done - spoken to you; DICT the name to cross-check',
        lastEvent: 'EVT: LLM read ok (image input) - machine read, may be wrong'
      });
      this._renderAll();
      // Quietly tell the wearer at once - that is the point of the
      // agent: the name reaches YOUR ear, nobody else's screen.
      if (c.llmName || c.org) {
        this._speakText('机器读到：' + (c.llmName || '（没读出姓名）') +
          (c.org ? '，' + c.org : '') + '。可能读错，请核对。');
      }
    } finally {
      this.setData({ busy: false });
    }
  },

  // ---------- DICT (dictate the name as YOU read it - the cross-check, always available) ----------

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
      capLine: 'CAP: no photo - your dictated name only · ' + st.time,
      lastEvent: 'EVT: badge created by DICT (no photo for this badge)'
    });
    return this._cur;
  },

  _presets() {
    // Demo input for hosts with no recogniser (honest SKIP path):
    // sample "names you read" lines, cycled by DICT, labelled presets.
    return [
      '陈小雨（预置）',
      'Alex Chen（预置）',
      '佐藤健（预置）'
    ];
  },

  _demoDictLine() {
    // In DEMO the "wearer's dictation" is seeded with the surname
    // changed （王小明 -> 王大明）, so the DIFF cross-check state
    // previews honestly, labelled DEMO.
    return '王大明';
  },

  // A dictated line is "name, org" said as ONE line: the first
  // segment (up to ，、·, or a space) is the name, the rest is the
  // organisation the wearer supplied. Both are kept verbatim.
  _dictParts() {
    var c = this._cur;
    if (!c || !c.dictated) return { name: '', org: '' };
    var s = String(c.dictated).trim();
    var m = s.split(/[，、·,]/);
    var name, rest;
    if (m.length > 1) {
      name = m[0].trim();
      rest = m.slice(1).join(' ').trim();
    } else {
      var sp = s.indexOf(' ');
      if (sp > 0) { name = s.slice(0, sp).trim(); rest = s.slice(sp + 1).trim(); }
      else { name = s; rest = ''; }
    }
    return { name: name.slice(0, 24), org: rest.slice(0, 32) };
  },

  dictTap() {
    if (this.data.busy) return;
    this._ensureCur();
    if (this._demo) {
      this._cur.dictated = this._demoDictLine();
      this._cur.dictSrc = 'DEMO';
      this.setData({
        status: 'YOUR NAME (DEMO dictation) - compare it with the machine NAME',
        lastEvent: 'EVT: DEMO dictation seeded （王大明 vs machine 王小明） - DIFF expected'
      });
      this._renderAll();
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. DICT cycles sample
      // "name you read" lines as demo input instead of pretending
      // to listen.
      var presets = this._presets();
      this._presetIdx = ((this._presetIdx || 0) + 1) % presets.length;
      this._cur.dictated = presets[this._presetIdx];
      this._cur.dictSrc = 'PRESET';
      this.setData({
        status: 'NAME preset (ASR n/a) - this stands in for your reading',
        lastEvent: 'EVT: DICT preset -> sample name (honest SKIP, no ASR)'
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
    // #21/#36/#38/#41): open the wearer-mode stream, read back its
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
            status: 'YOUR NAME heard verbatim - compare it with the machine NAME',
            lastEvent: 'EVT: dictated name heard (' + micNote + ') - verbatim'
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
        status: 'DICT listening (host ASR) - say the name as YOU read it',
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

  // ---------- CHECK (literal comparison of machine NAME vs YOUR name) ----------

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
    if (!c || !c.llmName || !c.dictated) return 'none';
    return this._cmpNorm(c.llmName) === this._cmpNorm(this._dictParts().name) ? 'match' : 'diff';
  },

  // The name that counts: when you dictated one, YOUR reading is
  // the confirmed version (it wins on a DIFF); otherwise the
  // machine read stands, labelled as such.
  _confirmedName() {
    var c = this._cur;
    if (!c) return '';
    if (c.dictated) return this._dictParts().name;
    return c.llmName || '';
  },

  _confirmedOrg() {
    var c = this._cur;
    if (!c) return '';
    if (c.org) return c.org;
    if (c.dictated) return this._dictParts().org;
    return '';
  },

  // ---------- SPEAK (says a name aloud - to the wearer's ear only) ----------

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

  _speakPendingText() {
    var c = this._cur;
    if (!c) return null;
    var cmp = this._compare();
    var org = this._confirmedOrg();
    if (c.llmName && c.dictated) {
      if (cmp === 'match') {
        return '核对一致，名牌上是：' + c.llmName + (org ? '，' + org : '');
      }
      // DIFF: YOUR reading is spoken first and treated as the one
      // to trust; the machine's version is named as the machine's.
      return '按你读的：' + this._dictParts().name + '。机器读的是：' + c.llmName +
        '，两边不一样，请以你读到的为准。';
    }
    if (c.dictated) return '你记下的是：' + c.dictated;
    if (c.llmName) return '机器读数，可能读错：' + c.llmName + (org ? '，' + org : '');
    return null;
  },

  speakTap() {
    if (this.data.busy) return;
    var facing = this._facingPerson();
    if (facing) {
      var ft = '你正前方这个方向登记过：' + facing.name +
        (facing.org ? '，' + facing.org : '') +
        (facing.title ? '，' + facing.title : '');
      if (this._speakText(ft)) {
        this.setData({
          status: 'SPEAK - the saved person in front of you',
          lastEvent: 'EVT: TTS saved person sent: ' + facing.name
        });
      }
      return;
    }
    var text = this._speakPendingText();
    if (text) {
      if (this._speakText(text)) {
        this.setData({
          status: 'SPEAK - reading the badge name aloud (to you only)',
          lastEvent: 'EVT: TTS badge name sent'
        });
      }
      return;
    }
    var sel = this._selPerson();
    if (sel) {
      var st = '登记过的人：' + sel.name + (sel.org ? '，' + sel.org : '') +
        (sel.title ? '，' + sel.title : '') + '。这是你在 ' + sel.time +
        ' 朝着 ' + sel.heading + ' 度时记下的。';
      var rel = this._relOf(sel);
      if (rel === null) st += '现在没有你的朝向读数。';
      else if (Math.abs(rel) <= 15) st += '你现在正对着当时登记的方向。';
      if (this._speakText(st)) {
        this.setData({ lastEvent: 'EVT: TTS saved person sent: ' + sel.name });
      }
      return;
    }
    this.setData({
      status: 'SPEAK FAIL: no name yet - READ a badge or DICT a name',
      lastEvent: 'EVT: SPEAK refused - nothing to say'
    });
  },

  // ---------- SAVE (registers the person against the SNAP/DICT heading) ----------

  saveTap() {
    if (this.data.busy) return;
    var c = this._cur;
    var name = this._confirmedName();
    if (!c || !name) {
      // Nothing read and nothing dictated = nobody to register. A
      // SAVE (or a nod) with no name NEVER invents one.
      this.setData({
        status: 'SAVE FAIL: no name - READ a badge or DICT the name first',
        lastEvent: 'EVT: SAVE refused - no name pending'
      });
      return;
    }
    if (c.heading === null || c.heading === undefined || !isFinite(c.heading)) {
      // The person IS their direction here. A name without the
      // heading of that moment cannot be registered - never invent
      // a heading.
      this.setData({
        status: 'SAVE FAIL: no heading was captured - face the person and SNAP/DICT again',
        lastEvent: 'EVT: SAVE refused - never invent a heading'
      });
      return;
    }
    var src = (c.llmName && c.dictated) ? 'both' : (c.llmName ? 'llm' : 'dict');
    var rec = {
      id: ++this._idSeq,
      name: name,
      org: this._confirmedOrg(),
      title: c.title || '',
      src: src,
      heading: ((Math.round(c.heading) % 360) + 360) % 360,
      date: c.date || this._stamp().date,
      time: c.time || this._stamp().time,
      demo: !!this._demo
    };
    var dropped = this._addPerson(rec);
    for (var i = 0; i !== this._people.length; i++) {
      if (this._people[i].id === rec.id) this._selIdx = i;
    }
    this._cur = null;
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: 'SAVED: ' + rec.name + ' @ ' + rec.heading + '° - face that way again, I whisper it back',
      lastEvent: dropped
        ? 'EVT: cap 12 - oldest person dropped: ' + dropped.name
        : 'EVT: saved ' + rec.name + ' (src ' + src + ') at heading ' + rec.heading + ' deg' +
          (rec.demo ? ' (DEMO - not persisted)' : '')
    });
    this._renderAll();
  },

  // ---------- people list / selection ----------

  _selPerson() {
    var list = this._people || [];
    if (!list.length) return null;
    var idx = this._selIdx || 0;
    if (idx >= list.length) idx = 0;
    return list[idx];
  },

  _cycleSel(dir) {
    var n = (this._people || []).length;
    if (!n) {
      this.setData({ lastEvent: 'EVT: nobody saved yet - SNAP a badge or DEMO' });
      return;
    }
    this._selIdx = (((this._selIdx || 0) + dir) % n + n) % n;
    this.setData({ lastEvent: 'EVT: selected -> ' + this._people[this._selIdx].name });
    this._renderAll();
  },

  listTap() { this._cycleSel(1); },

  // ---------- RE-MEET engine (same tick discipline as #38) ----------

  // The engine ticks on accumulated tick time (500 ms per tick),
  // NOT on repeated Date samples, so dwell / re-arm timing cannot
  // be distorted by the preview host's drifting clock.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._remindTick();
    }, 500);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _faceState(p) {
    var st = this._face[p.id];
    if (!st) {
      st = { inCone: false, dwellMs: 0, fired: false, outMs: 0, armed: true };
      this._face[p.id] = st;
    }
    return st;
  },

  _relOf(p) {
    if (this._heading === null || this._heading === undefined) return null;
    return ((p.heading - this._heading + 540) % 360) - 180; // -180..180, + = to your right
  },

  // Runs every 500 ms tick. A person FIRES when the heading stays
  // within ±15 deg of theirs for 2 continuous seconds: their card
  // surfaces big and their name is whispered ONCE for that facing
  // episode. It re-arms only after the heading has been outside
  // the cone for >= 5 s, so glancing back and forth never spams.
  _remindTick() {
    if (this._heading === null || this._heading === undefined) return;
    var best = null;
    var bestAbs = 999;
    var list = this._people || [];
    for (var i = 0; i !== list.length; i++) {
      var p = list[i];
      var rel = this._relOf(p);
      var st = this._faceState(p);
      if (Math.abs(rel) <= 15) {
        st.outMs = 0;
        if (!st.inCone) { st.inCone = true; st.dwellMs = 0; }
        else st.dwellMs += 500;
        if (Math.abs(rel) < bestAbs) { bestAbs = Math.abs(rel); best = p; }
      } else {
        st.inCone = false;
        st.dwellMs = 0;
        if (st.fired) {
          st.outMs += 500;
          if (st.outMs >= 5000) { st.fired = false; st.armed = true; st.outMs = 0; }
        }
      }
    }
    if (best) {
      var bst = this._faceState(best);
      if (bst.dwellMs >= 2000 && !bst.fired && bst.armed) {
        bst.fired = true;
        bst.armed = false;
        this._firePerson(best);
        return;
      }
    }
    this._renderAll();
  },

  _firePerson(p) {
    var spoken = this._speakText(p.name + (p.org ? '，' + p.org : ''));
    this.setData({
      lastEvent: 'EVT: RE-MEET ' + p.name + ' - facing their saved direction' +
        (spoken ? ' (whispered once)' : ' (TTS n/a here)')
    });
    this._renderAll();
  },

  _facingPerson() {
    var list = this._people || [];
    for (var i = 0; i !== list.length; i++) {
      var st = this._face[list[i].id];
      if (st && st.fired && st.inCone) return list[i];
    }
    return null;
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return 'FRONT';
    if (a <= 67.5) return rel > 0 ? 'RIGHT-FRONT' : 'LEFT-FRONT';
    if (a <= 112.5) return rel > 0 ? 'RIGHT' : 'LEFT';
    if (a <= 157.5) return rel > 0 ? 'RIGHT-BACK' : 'LEFT-BACK';
    return 'BACK';
  },

  // ---------- DEMO (seeded badge read + one saved person, memory only) ----------

  // DEMO seeds a labelled badge read （王小明 · 星野科技 · 产品经理）
  // dead ahead (heading 0) plus one already-saved person （李华）
  // at 90 deg, so the re-meet card can be previewed by stepping
  // the simulated heading +45 deg per DEMO tap. After a full
  // circle of steps, the next DEMO tap exits and restores the
  // real session untouched. DEMO writes NO storage, ever.
  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealPeople = this._people;
      this._demoRealCur = this._cur;
      this._demo = true;
      this._demoSteps = 0;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._face = {};
      var st = this._stamp();
      this._people = (this._people || []).slice();
      this._people.push({
        id: ++this._idSeq, name: '李华', org: '蓝桥资本', title: '投资经理',
        src: 'llm', heading: 90, date: st.date, time: st.time, demo: true
      });
      this._cur = this._newCur({
        demo: true, bytes: 0, heading: 0, date: st.date, time: st.time,
        readSrc: 'DEMO',
        llmName: '王小明', org: '星野科技', title: '产品经理'
      });
      this.setData({
        capLine: 'CAP: DEMO - no camera used; photo bytes 0 (DEMO)',
        status: 'DEMO - badge read ahead of you; DICT seeds your line （王大明） for a DIFF',
        lastEvent: 'EVT: DEMO on - seeded read + saved person 李华 @90 (memory only)'
      });
      this._renderAll();
      return;
    }
    this._demoSteps++;
    if (this._demoSteps >= 8) { this._exitDemo(); return; }
    this._demoHeading = (this._demoSteps * 45) % 360;
    this._heading = this._demoHeading;
    this._headingSrc = 'DEMO';
    this.setData({
      status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
      lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
    });
    this._renderAll();
  },

  _exitDemo() {
    this._demo = false;
    this._demoSteps = 0;
    this._people = this._demoRealPeople || [];
    this._cur = this._demoRealCur || null;
    this._demoRealPeople = null;
    this._demoRealCur = null;
    this._face = {};
    this._heading = null;
    this._headingSrc = 'NONE';
    this._startHeading();
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: 'DEMO OFF - your real session is back',
      lastEvent: 'EVT: DEMO cleared - real session restored, nothing was written'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var c = this._cur;
    var patch = {};
    patch.headLine = 'HEAD: ' + this._headText(this._heading) + ' · SRC: ' + this._headingSrc +
      (this._demo ? ' (DEMO)' : '');
    if (!c) {
      patch.readLabel = 'READ: no read yet - the photo itself is never saved';
      patch.nameText = '-';
      patch.orgLine = 'ORG: - · TITLE: -';
      patch.youLine = 'YOU SAID: - (DICT the name as YOU read it, to cross-check)';
      patch.cmpLine = 'CHECK: not compared - literal text compare, not understanding';
    } else {
      if (c.readSrc === 'LLM') {
        patch.readLabel = 'LLM READ - may misread, check it against the badge yourself';
      } else if (c.readSrc === 'DEMO') {
        patch.readLabel = 'LLM READ (DEMO) - seeded text, not a real photo read';
      } else if (c.readNote) {
        patch.readLabel = c.readNote;
      } else {
        patch.readLabel = 'READ: no machine read - your dictated name can still be saved';
      }
      patch.nameText = c.llmName || (c.dictated ? this._dictParts().name : '-');
      patch.orgLine = 'ORG: ' + (this._confirmedOrg() || '-') + ' · TITLE: ' + (c.title || '-');
      patch.youLine = c.dictated
        ? 'YOU SAID (' + (c.dictSrc || 'ASR') + '): ' + c.dictated
        : 'YOU SAID: - (DICT the name as YOU read it, to cross-check)';
      var cmp = this._compare();
      if (cmp === 'match') {
        patch.cmpLine = 'CHECK: MATCH ✓ - your name and the machine NAME agree';
      } else if (cmp === 'diff') {
        patch.cmpLine = 'CHECK: DIFF ⚠ - YOUR version is the one that gets saved';
      } else {
        patch.cmpLine = 'CHECK: not compared - literal text compare, not understanding';
      }
    }
    var list = this._people || [];
    patch.countLine = 'PEOPLE: ' + list.length + '/12 · text only, saved on this device';
    if (!list.length) {
      patch.rows = [{ text: '(nobody saved) - SNAP a badge, or DEMO' }];
    } else {
      var sel = this._selIdx || 0;
      if (sel >= list.length) sel = 0;
      patch.rows = list.map(function (p, i) {
        return {
          text: (i === sel ? '▶ ' : '  ') + p.name + ' · ' + (p.org || '-') + ' · ' +
            p.heading + '° · ' + p.date.slice(5) + ' ' + p.time + (p.demo ? ' DEMO' : '')
        };
      });
    }
    // The RE-MEET card: while you face a fired person's direction
    // their name is surfaced big. The match is by DIRECTION only -
    // whoever stands there now gets the saved name shown.
    var facing = this._facingPerson();
    if (facing) {
      patch.meetLine = 'CARD: ' + facing.name + ' · ' + (facing.org || '') +
        (facing.title ? ' · ' + facing.title : '') + ' · saved ' + facing.time;
      patch.meetCls = 'meet meet-on';
    } else {
      patch.meetLine = 'CARD: face a saved direction 2 s - the name pops here';
      patch.meetCls = 'meet';
    }
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">BADGE READER</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{headLine}}</text>
    </view>
    <view class="info-box">
      <text class="photo">{{capLine}}</text>
      <text class="photo">{{readLabel}}</text>
      <text class="key">{{nameText}}</text>
      <text class="org">{{orgLine}}</text>
      <text class="you">{{youLine}}</text>
      <text class="cmp">{{cmpLine}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="meet-box">
      <text class="{{meetCls}}">{{meetLine}}</text>
      <text class="photo">reminders only while open · matched by DIRECTION, not by face</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <text class="photo">{{countLine}}</text>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="readTap">READ</button>
      <button class="btn" bindtap="dictTap">DICT</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="saveTap">SAVE</button>
      <button class="btn" bindtap="listTap">LIST</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="sub">photos NOT saved · no face recognition - direction only</text>
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
.key {
  color: #40ff5e;
  font-size: 23px;
  font-weight: 500;
  line-height: 29px;
  margin-top: 2px;
}
.org {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 16px;
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
.meet-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 8px 3px;
  margin-bottom: 3px;
}
.meet {
  color: rgba(64,255,94,0.72);
  font-size: 13px;
  font-weight: 500;
  line-height: 17px;
}
.meet-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.list {
  height: 28px;
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
