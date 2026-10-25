<script def>
{
  "navigationBarTitleText": "Story Look"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT THE PAGE, SAY WHAT YOU SEE, THEN TELL',
    steadyText: 'HEAD: moving - hold still',
    pageLine: 'PAGE 1/20 - a new story',
    photoLine: 'PHOTO: none - LOOK = page record only, never read',
    descText: '（还没说这一页）',
    descNote: 'DESC: tap SAY - describe this page in one sentence',
    narrText: '讲解词会先出现在这里，你看过再点 READ 读给孩子听。',
    quesText: 'QUESTION: -',
    sourceLine: 'SOURCE: none - no telling yet',
    sessionLine: 'STORY: 0/20 pages saved (on-device, key storyLook)',
    rows: [
      { name: '(story empty)', detail: 'TELL a page, NEXT files it here - or DEMO', flag: '', cls: 'row' }
    ],
    boxLabel: '◎ THIS PAGE - you describe it, the tale is built from YOUR words',
    lastEvent: 'EVT: nod when steady = NEXT (files a told page)',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._pages = this._loadStory(); // saved pages of the last story
    this._cur = this._blankCur();     // the page in progress
    this._presetIdx = -1;
    this._demo = false;
    this._demoForceOffline = false;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: ' + this._pages.length + ' saved page(s) in the last story' });
  },

  onUnload() {
    this._stopSayRec();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    this._saveStory();
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
    if (!this._steady) {
      this.setData({ status: 'NOD IGNORED - hold head steady first' });
      return;
    }
    // A nod only files a page you have already told and previewed.
    // It never generates text and never speaks to the child.
    if (this._cur.narration) this.nextTap();
    else this.setData({ lastEvent: 'EVT: nod ignored - TELL this page first' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (!this.data.busy) this._advance();
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

  _advance() {
    if (this._cur.narration) this.nextTap();
    else if (this._cur.desc) this.tellTap();
    else this.setData({ lastEvent: 'EVT: advance ignored - SAY this page first' });
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

  _blankCur() {
    return { desc: '', narration: '', question: '', source: '', photo: '' };
  },

  _pageNo() { return this._pages.length + 1; },

  _full() { return this._pages.length >= 20; },

  // ---------- built-in question bank (offline fallback, 10 gentle questions) ----------

  _questionBank() {
    return [
      '你猜，接下来会发生什么？',
      '如果你是它，你会怎么做？',
      '它现在的心情是什么样的？',
      '这一页里，你听到了什么声音？',
      '你最喜欢这一页的哪个地方？',
      '它接下来会去哪里呢？',
      '谁会来帮助它呢？',
      '你想对它说什么？',
      '这一页里，你发现了什么小秘密？',
      '猜猜看，这个故事会怎么结束？'
    ];
  },

  _presets() {
    // Demo input for hosts with no recogniser (honest SKIP path):
    // sample page descriptions, cycled by SAY, labelled as presets.
    return [
      '小兔子在森林里迷路了，正在哭',
      '小兔子遇到了一只猫头鹰',
      '猫头鹰带着小兔子飞过小河',
      '大家一起回到了兔子家'
    ];
  },

  // ---------- persistence (wx sync storage, key 'storyLook', last story, max 20) ----------

  _loadStory() {
    try {
      var raw = wx.getStorageSync('storyLook');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 20; i++) {
        var it = raw[i];
        if (it && typeof it.parentDesc === 'string' && it.parentDesc
          && typeof it.narration === 'string' && it.narration
          && typeof it.question === 'string') {
          out.push({
            pageNo: out.length + 1,
            parentDesc: String(it.parentDesc).slice(0, 120),
            narration: String(it.narration).slice(0, 300),
            question: String(it.question).slice(0, 80),
            source: String(it.source || 'OFFLINE ECHO').slice(0, 16)
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveStory() {
    if (this._demo) return; // demo pages never touch real storage
    try {
      wx.setStorageSync('storyLook', this._pages || []);
    } catch (e) { /* storage unavailable on this host: story stays in memory */ }
  },

  // ---------- TELL (host LLM text-in -> OFFLINE ECHO fallback) ----------

  _buildPrompt(pages, desc) {
    // Text-only context: the descriptions of the pages already told,
    // in story order, then this page's description. The photo never
    // enters the prompt - the model has never seen the book.
    var lines = [];
    lines.push('You are helping a parent tell a picture-book story to a 3-6 year old child, in warm, simple Chinese.');
    if (pages && pages.length) {
      lines.push('The story so far - the parent described the earlier pages like this:');
      for (var i = 0; i !== pages.length; i++) {
        lines.push('Page ' + (i + 1) + ': ' + pages[i].parentDesc);
      }
    }
    lines.push('This page, as the parent describes it: ' + desc);
    lines.push('Stay with what the parent described - add only gentle connective tissue, invent no new characters, places or events.');
    lines.push('Reply in exactly two parts:\nNARRATION: <2-3 short warm Chinese sentences retelling ONLY this page, suitable to read aloud to a young child>\nQUESTION: <one short Chinese question to ask the child about this page>');
    return lines.join('\n');
  },

  _parseStory(text) {
    // Expected shape (asked for in the prompt):
    //   NARRATION: <2-3 sentences>
    //   QUESTION: <one question>
    // Salvage line-by-line if the labels drift; never reshape silently:
    // leftover plain lines join the narration before the question line.
    var lines = String(text || '').split('\n');
    var narr = '', ques = '';
    var plain = [];
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      if (!ln) continue;
      if (/^NARRATION[:：]/i.test(ln)) narr = ln.replace(/^NARRATION[:：]/i, '').trim();
      else if (/^QUESTION[:：]/i.test(ln)) ques = ln.replace(/^QUESTION[:：]/i, '').trim();
      else plain.push(ln);
    }
    if (!narr && plain.length) narr = plain.shift();
    if (!ques && plain.length) ques = plain.pop();
    if (!narr) return null;
    if (!ques) ques = this._questionBank()[0];
    return { narration: narr.slice(0, 300), question: ques.slice(0, 80), source: 'LLM' };
  },

  async _llmTell(pages, desc) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    try {
      var avail = await LM.availability();
      if (avail !== 'available') return null;
      var session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You are a warm picture-book storyteller for young children. Follow the requested two-part format exactly.' }]
      });
      try {
        var ans = await this._withTimeout(
          session.prompt(this._buildPrompt(pages, desc)), 25000, 'llm');
        if (ans && String(ans).trim()) return this._parseStory(ans);
        return null;
      } finally {
        try { session.destroy(); } catch (e) {}
      }
    } catch (e) {
      return null; // fall through to the offline echo
    }
  },

  _offlineTell(desc, pageNo) {
    // OFFLINE ECHO: the narration IS the parent's own description,
    // unchanged - not a generated story, and labelled as such. The
    // question comes from the built-in bank, rotating by page.
    var bank = this._questionBank();
    return {
      narration: desc,
      question: bank[((pageNo - 1) % bank.length + bank.length) % bank.length],
      source: 'OFFLINE ECHO'
    };
  },

  async _tell(desc, forceOffline) {
    if (!forceOffline) {
      var viaLlm = await this._llmTell(this._pages, desc);
      if (viaLlm) return viaLlm;
    }
    return this._offlineTell(desc, this._pageNo());
  },

  async tellTap() {
    if (this.data.busy) return;
    if (this._full()) {
      this.setData({
        status: 'STORY FULL - 20 pages saved, CLEAR starts a new one',
        lastEvent: 'EVT: TELL refused - story at cap 20'
      });
      return;
    }
    if (!this._cur.desc) {
      this.setData({
        status: 'TELL FAIL: SAY what this page shows first',
        lastEvent: 'EVT: TELL refused - no description yet'
      });
      return;
    }
    var desc = this._cur.desc;
    this.setData({ busy: true, status: 'TELLING page ' + this._pageNo() + '...' });
    try {
      var r = await this._tell(desc, !!this._demoForceOffline);
      this._cur.narration = r.narration;
      this._cur.question = r.question;
      this._cur.source = r.source;
      this.setData({
        status: 'TOLD (' + r.source + ') - READ it first, then READ aloud / NEXT',
        lastEvent: 'EVT: page ' + this._pageNo() + ' told via ' + r.source +
          ' - NOT spoken yet, preview first'
      });
      this._renderAll();
    } catch (e) {
      this.setData({
        status: 'TELL FAIL - ' + this._err(e),
        lastEvent: 'EVT: tell error ' + this._err(e)
      });
    } finally {
      this.setData({ busy: false });
    }
  },

  // ---------- LOOK (default-mode photo, record only - the agent never sees the page) ----------

  lookTap() { this.capturePhoto(); },

  async capturePhoto() {
    if (this.data.busy) return;
    if (this._full()) {
      this.setData({
        status: 'STORY FULL - 20 pages saved, CLEAR starts a new one',
        lastEvent: 'EVT: LOOK refused - story at cap 20'
      });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host',
        status: 'LOOK FAIL - no camera here; SAY the page anyway',
        lastEvent: 'EVT: LOOK FAIL (host has no camera) - photo is optional'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default mode) at the page...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'page photo');
      var bytes = blob && blob.size ? blob.size : 0;
      this._cur.photo = bytes + 'B';
      this.setData({
        photoLine: 'PHOTO: ' + bytes + 'B default - record only, never read',
        status: 'PAGE RECORDED - now SAY what this page shows',
        lastEvent: 'EVT: page photo ' + bytes + 'B (record only, agent cannot see it)'
      });
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
        this._cur.photo = size + 'B';
        this.setData({
          photoLine: 'PHOTO: ' + size + 'B wx cam (fallback) - record only',
          status: 'PAGE RECORDED - now SAY what this page shows',
          lastEvent: 'EVT: wx page photo ' + size + 'B (record only)'
        });
      } catch (e3) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr),
          status: 'LOOK FAIL - no photo; SAY the page anyway',
          lastEvent: 'EVT: LOOK FAIL - ' + this._err(firstErr)
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

  // ---------- SAY (one-shot ASR: the parent describes this page, verbatim) ----------

  _stopSayRec() {
    if (this._sayRec) {
      try { this._sayRec.abort(); } catch (e) {}
      this._sayRec = null;
    }
  },

  sayTap() {
    if (this.data.busy) return;
    if (this._full()) {
      this.setData({
        status: 'STORY FULL - 20 pages saved, CLEAR starts a new one',
        lastEvent: 'EVT: SAY refused - story at cap 20'
      });
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. SAY cycles sample
      // page descriptions as demo input instead of pretending to listen.
      var presets = this._presets();
      this._presetIdx = ((this._presetIdx || 0) + 1) % presets.length;
      var d = presets[this._presetIdx];
      this._setDesc(d, 'preset - ASR SKIP here');
      this.setData({
        status: 'DESC preset (ASR n/a) - check it, then TELL',
        lastEvent: 'EVT: SAY preset -> sample description (honest SKIP, no ASR)'
      });
      return;
    }
    this._sayListen();
  },

  _setDesc(txt, how) {
    // The parent's description is kept VERBATIM (trimmed only, like
    // DI21/DI36): the whole tale is built from these words, so what the
    // parent sees here is exactly what the model will be given.
    this._cur.desc = txt;
    this._cur.narration = '';
    this._cur.question = '';
    this._cur.source = '';
    this.setData({
      descText: txt,
      descNote: 'DESC heard (' + how + ') - VERBATIM, SAY again if wrong',
      narrText: '讲解词会先出现在这里，你看过再点 READ 读给孩子听。',
      quesText: 'QUESTION: -',
      sourceLine: 'SOURCE: none - not told yet'
    });
    this._renderAll();
  },

  async _sayListen() {
    var self = this;
    this.setData({ busy: true, descNote: 'DESC: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (same documented pattern as
    // DI21/DI36): the stream only verifies the mode opens and reads back
    // its settings, then stops. It does NOT feed recognition - the host
    // SpeechRecognition below listens on its own microphone, and no
    // documented path lets the wearer mode shape what it hears
    // (dossier sections 2.4 / 2.8). No parent-priority claim is made.
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
      this._stopSayRec();
      var rec = new SpeechRecognition();
      this._sayRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          self._setDesc(txt, 'zh-CN');
          self.setData({
            status: 'DESC heard - check it, then TELL this page',
            lastEvent: 'EVT: description heard (' + micNote + ') - verbatim'
          });
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          descNote: 'DESC: FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + ', tap SAY again',
          status: 'SAY FAIL - say one sentence about this page',
          lastEvent: 'EVT: SAY ASR error'
        });
      };
      rec.onend = function () {
        if (self._sayRec === rec) self._sayRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        descNote: 'DESC: listening (zh-CN) - one sentence about this page...',
        status: 'SAY listening (' + micNote + ')',
        lastEvent: 'EVT: SAY listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        descNote: 'DESC: FAIL - ' + this._err(e),
        status: 'SAY FAIL - recogniser would not start',
        lastEvent: 'EVT: SAY start failed'
      });
    }
  },

  // ---------- READ / NEXT / READ ALL ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      var utt = new SpeechSynthesisUtterance(text);
      // Slower than default for a young child; guarded - some hosts
      // ignore the rate, which is fine, it stays synthetic TTS.
      try { utt.rate = 0.85; } catch (e) {}
      speechSynthesis.speak(utt, 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  readTap() {
    // Deliberate product choice: NOTHING is spoken to the child
    // automatically. The parent previews the generated narration on
    // screen and taps READ only when happy with it.
    if (!this._cur.narration) {
      this.setData({
        status: 'READ: TELL this page first - then preview, then READ',
        lastEvent: 'EVT: READ refused - nothing told yet'
      });
      return;
    }
    if (this._speakText(this._cur.narration)) {
      this.setData({
        status: 'READING page ' + this._pageNo() + ' - now ask the QUESTION below',
        lastEvent: 'EVT: TTS narration sent (synthetic voice, parent-approved tap)'
      });
    }
  },

  nextTap() {
    if (!this._cur.narration) {
      this.setData({
        status: 'NEXT FAIL: TELL this page first (nothing to file)',
        lastEvent: 'EVT: NEXT refused - page not told yet'
      });
      return;
    }
    var entry = {
      pageNo: this._pageNo(),
      parentDesc: this._cur.desc,
      narration: this._cur.narration,
      question: this._cur.question,
      source: this._cur.source
    };
    this._pages.push(entry);
    if (this._pages.length > 20) this._pages.length = 20;
    this._saveStory();
    this._cur = this._blankCur();
    this.setData({
      photoLine: 'PHOTO: none - LOOK = page record only, never read',
      descText: '（还没说这一页）',
      descNote: 'DESC: tap SAY - describe this page in one sentence',
      status: this._full()
        ? 'PAGE ' + entry.pageNo + ' FILED - story complete (20/20)'
        : 'PAGE ' + entry.pageNo + ' FILED - turn the page, LOOK + SAY',
      lastEvent: 'EVT: filed page ' + entry.pageNo + ' (' + entry.source + ') - story ' +
        this._pages.length + '/20'
    });
    this._renderAll();
  },

  allTap() {
    if (!this._pages.length) {
      this.setData({
        status: 'READ ALL: no saved pages yet - TELL + NEXT a page first',
        lastEvent: 'EVT: READ ALL refused - story empty'
      });
      return;
    }
    var parts = [];
    for (var i = 0; i !== this._pages.length; i++) {
      parts.push(this._pages[i].narration);
    }
    if (this._speakText(parts.join(' '))) {
      this.setData({
        status: 'READ ALL - replaying ' + this._pages.length + ' page(s) in order',
        lastEvent: 'EVT: TTS replay of the saved story sent'
      });
    }
  },

  // ---------- DEMO (offline echo, seeded in memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealPages = this._pages;
      this._demo = true;
    }
    this._demoForceOffline = true;
    // Page 1 is filed; page 2 is told and waiting on its question -
    // the exact moment co-reading gets interactive. All offline echo,
    // all in memory: real storage is never written in DEMO.
    var p1desc = '小兔子在森林里迷路了，正在哭';
    var p1 = this._offlineTell(p1desc, 1);
    var p2desc = '小兔子遇到了一只猫头鹰，猫头鹰说可以带它回家';
    var p2 = this._offlineTell(p2desc, 2);
    this._pages = [{
      pageNo: 1, parentDesc: p1desc,
      narration: p1.narration, question: p1.question, source: p1.source
    }];
    this._cur = {
      desc: p2desc, narration: p2.narration,
      question: p2.question, source: p2.source, photo: 'DEMO'
    };
    this.setData({
      photoLine: 'PHOTO: DEMO - no camera used here',
      descText: p2desc,
      descNote: 'DESC: DEMO seed - page 2, told via OFFLINE ECHO',
      status: 'DEMO - page 2 QUESTION view: READ it, ask the child',
      lastEvent: 'EVT: DEMO on - 2 pages seeded (offline echo, memory only)'
    });
    this._renderAll();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO restores the real story untouched (demo never saved).
      this._demo = false;
      this._demoForceOffline = false;
      this._pages = this._demoRealPages || this._loadStory();
      this._demoRealPages = null;
      this._cur = this._blankCur();
      this.setData({
        photoLine: 'PHOTO: none - LOOK = page record only, never read',
        descText: '（还没说这一页）',
        descNote: 'DESC: tap SAY - describe this page in one sentence',
        status: 'DEMO OFF - your real story is back (' + this._pages.length + ' pages)',
        lastEvent: 'EVT: DEMO cleared - real story restored, nothing was written'
      });
      this._renderAll();
      return;
    }
    this._pages = [];
    this._cur = this._blankCur();
    this._saveStory();
    this.setData({
      photoLine: 'PHOTO: none - LOOK = page record only, never read',
      descText: '（还没说这一页）',
      descNote: 'DESC: tap SAY - describe this page in one sentence',
      status: 'STORY CLEARED - a new story starts at page 1',
      lastEvent: 'EVT: saved story emptied (on-device only, nothing was uploaded)'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var show = this._pages.slice(0, 8);
    for (var i = 0; i !== show.length; i++) {
      var p = show[i];
      rows.push({
        name: 'P' + p.pageNo + ' ' + p.parentDesc.slice(0, 12),
        detail: p.narration.slice(0, 24),
        flag: p.source === 'LLM' ? 'LLM' : 'ECHO',
        cls: 'row'
      });
    }
    if (!rows.length) {
      rows.push({
        name: '(story empty)',
        detail: 'TELL a page, NEXT files it here - or DEMO',
        flag: '',
        cls: 'row'
      });
    }
    var cur = this._cur;
    this.setData({
      pageLine: this._full()
        ? 'STORY FULL - 20/20 pages'
        : 'PAGE ' + this._pageNo() + '/20 - ' + (cur.narration ? 'told, previewing' : (cur.desc ? 'described, not told' : 'new page')),
      narrText: cur.narration || '讲解词会先出现在这里，你看过再点 READ 读给孩子听。',
      quesText: cur.question ? '问问孩子：' + cur.question : 'QUESTION: -',
      sourceLine: cur.source
        ? 'SOURCE: ' + cur.source + (this._demoForceOffline && cur.source === 'OFFLINE ECHO' ? ' (DEMO forced offline path)' : '')
        : 'SOURCE: none - no telling yet',
      sessionLine: 'STORY: ' + this._pages.length + '/20 pages saved (on-device, key storyLook)',
      rows: rows,
      boxLabel: cur.narration
        ? '◎ PAGE ' + this._pageNo() + ' TOLD · src ' + cur.source + ' - PREVIEW FIRST, READ IS MANUAL'
        : '◎ THIS PAGE - you describe it, the tale is built from YOUR words'
    });
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">STORY LOOK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{pageLine}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">◎ YOUR DESCRIPTION - verbatim; the glasses never see this page</text>
      <text class="desc">{{descText}}</text>
      <text class="photo">{{descNote}}</text>
      <text class="photo">{{photoLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn btn-main" bindtap="sayTap">SAY</button>
      <button class="btn btn-main" bindtap="tellTap">TELL</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="readTap">READ</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="allTap">READ ALL</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="step">{{narrText}}</text>
      <text class="question">{{quesText}}</text>
      <text class="photo">{{sourceLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{sessionLine}}</text>
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
.desc {
  color: #40ff5e;
  font-size: 14px;
  line-height: 17px;
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
.plan-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.step {
  color: #40ff5e;
  font-size: 14px;
  line-height: 17px;
  margin-top: 2px;
}
.question {
  color: #40ff5e;
  font-size: 15px;
  font-weight: 500;
  line-height: 19px;
  margin-top: 3px;
}
.list {
  flex-shrink: 0;
  height: 42px;
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
