<script def>
{
  "navigationBarTitleText": "Word Look"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT THE WORD, SAY IT, CHECK IT, THEN DEFINE',
    steadyText: 'HEAD: moving - hold still',
    modeText: 'MODE: LOOK - find a word',
    photoLine: 'PHOTO: none - LOOK = telephoto record only',
    wordText: '(no word yet)',
    wordNote: 'WORD: tap SAY, say the word - shown VERBATIM',
    defZh: '释义：-',
    defEn: 'EN: -',
    defEx: 'EX: -',
    sourceLine: 'SOURCE: none - no lookup yet',
    sceneText: '旅行',
    bookLine: 'BOOK: 0/60 · 阅读 0 · 旅行 0 · 工作 0 · 日常 0',
    rows: [
      { name: '(book empty)', detail: 'DEFINE a word, SAVE it here - or DEMO', flag: '', cls: 'row' }
    ],
    boxLabel: '◎ THE WORD - you say it, the glasses only take a photo',
    boxBody: '照片读不了字：词靠你说出来，听到的原样显示，先核对再查。',
    boxSub1: '听错一个词，就会查出一个错意思 — 核对这一步就是产品本身。',
    boxSub2: '',
    boxSub3: '',
    lastEvent: 'EVT: nod when steady = next step (DEFINE, then SAVE)',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'lookup'; // lookup | book
    this._word = '';       // heard word, verbatim (trimmed only)
    this._def = null;      // { zh, en, ex, source } for _word
    this._sceneIdx = 1;    // default scene: 旅行
    this._book = this._loadBook();
    this._bookIdx = -1;    // review cursor inside the scene filter
    this._presetIdx = -1;
    this._demo = false;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: ' + this._book.length + ' saved word(s) in the book' });
  },

  onUnload() {
    this._stopSayRec();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    this._saveBook();
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
    // A nod only advances the pipeline YOU are driving: DEFINE the word
    // you checked, or SAVE the definition you heard. It never invents
    // a word and never corrects one (same discipline as DI22/DI23).
    this._advance();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      if (this._mode === 'book') this.reviewTap();
      else this.sceneTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
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
    if (this._mode === 'book') { this.reviewTap(); return; }
    if (this._def && this._word) this.saveTap();
    else if (this._word) this.defineTap();
    else this.setData({ lastEvent: 'EVT: nod ignored - SAY a word first' });
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

  _scenes() { return ['阅读', '旅行', '工作', '日常']; },

  _scene() { return this._scenes()[this._sceneIdx]; },

  _todayStr() {
    var d = new Date();
    var m = d.getMonth() + 1;
    var day = d.getDate();
    return d.getFullYear() + '-' + (m < 10 ? '0' : '') + m + '-' + (day < 10 ? '0' : '') + day;
  },

  // ---------- offline mini-dictionary (24 common words, labelled OFFLINE) ----------

  _dict() {
    return {
      'itinerary':    { zh: '行程；旅行计划', en: 'a detailed plan of a journey', ex: 'Keep your itinerary in your bag.' },
      'boarding':     { zh: '登机；上车', en: 'the act of getting on a plane or train', ex: 'Boarding starts at gate 5.' },
      'receipt':      { zh: '收据；小票', en: 'paper that proves you paid for something', ex: 'Keep the receipt for a refund.' },
      'prescription': { zh: '处方', en: "a doctor's written order for medicine", ex: 'Show the prescription at the pharmacy.' },
      'appointment':  { zh: '预约；约定', en: 'a fixed time to meet someone', ex: 'I have a dentist appointment at nine.' },
      'deadline':     { zh: '截止日期', en: 'the last time something can be done', ex: 'The deadline is Friday.' },
      'warranty':     { zh: '保修；质保', en: 'a written promise to repair or replace', ex: 'The phone has a two-year warranty.' },
      'ingredient':   { zh: '成分；配料', en: 'one of the things a food is made from', ex: 'The first ingredient is sugar.' },
      'fragile':      { zh: '易碎的', en: 'easy to break or damage', ex: 'This box is fragile, carry it gently.' },
      'refund':       { zh: '退款', en: 'money paid back to you', ex: 'Ask for a refund at the counter.' },
      'detour':       { zh: '绕行；便道', en: 'a longer way around something', ex: 'Follow the detour signs.' },
      'luggage':      { zh: '行李', en: 'the bags you carry when travelling', ex: 'Put your luggage on the belt.' },
      'signature':    { zh: '签名', en: 'your name written by hand', ex: 'Your signature goes here.' },
      'discount':     { zh: '折扣', en: 'a lower price than usual', ex: 'Students get a ten percent discount.' },
      'reservation':  { zh: '预订', en: 'a booking for a table, room or seat', ex: 'I have a reservation for two.' },
      'urgent':       { zh: '紧急的', en: 'needing quick action', ex: 'This message is urgent.' },
      'available':    { zh: '可用的；有空的', en: 'free to use, or ready to help', ex: 'Is the doctor available now?' },
      'direction':    { zh: '方向', en: 'the way something is pointing or moving', ex: 'Walk in that direction.' },
      'platform':     { zh: '站台', en: 'the place where you board a train', ex: 'The train leaves from platform 3.' },
      'entrance':     { zh: '入口', en: 'a door or gate to go into a place', ex: 'The entrance is around the corner.' },
      'exit':         { zh: '出口', en: 'a way out of a building or vehicle', ex: 'The exit is on your left.' },
      'caution':      { zh: '小心；警告', en: 'a warning to be careful', ex: 'Caution: wet floor.' },
      'volunteer':    { zh: '志愿者', en: 'a person who helps without being paid', ex: 'A volunteer showed us the way.' },
      'schedule':     { zh: '时间表；日程', en: 'a plan that lists times for events', ex: 'Check the bus schedule.' }
    };
  },

  _dictKeys() {
    var d = this._dict();
    var keys = [];
    for (var k in d) { if (Object.prototype.hasOwnProperty.call(d, k)) keys.push(k); }
    return keys;
  },

  _dictLookup(word) {
    if (!word) return null;
    var hit = this._dict()[String(word).toLowerCase()];
    if (!hit) return null;
    return { zh: hit.zh, en: hit.en, ex: hit.ex, source: 'OFFLINE' };
  },

  // ---------- persistence (wx sync storage, key 'wordBook', max 60) ----------

  _loadBook() {
    try {
      var raw = wx.getStorageSync('wordBook');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      var scenes = this._scenes();
      for (var i = 0; i !== raw.length && out.length < 60; i++) {
        var it = raw[i];
        if (it && typeof it.word === 'string' && it.word && typeof it.gloss === 'string'
          && scenes.indexOf(it.scene) >= 0) {
          out.push({
            word: String(it.word).slice(0, 32),
            gloss: String(it.gloss).slice(0, 60),
            en: String(it.en || '').slice(0, 80),
            example: String(it.example || '').slice(0, 120),
            source: String(it.source || 'OFFLINE').slice(0, 12),
            scene: it.scene,
            date: String(it.date || '').slice(0, 10)
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveBook() {
    if (this._demo) return; // demo entries never touch real storage
    try {
      wx.setStorageSync('wordBook', this._book || []);
    } catch (e) { /* storage unavailable on this host: book stays in memory */ }
  },

  _sceneCounts() {
    var counts = { '阅读': 0, '旅行': 0, '工作': 0, '日常': 0 };
    for (var i = 0; i !== this._book.length; i++) {
      if (counts[this._book[i].scene] !== undefined) counts[this._book[i].scene]++;
    }
    return counts;
  },

  _filtered() {
    var s = this._scene();
    var out = [];
    for (var i = 0; i !== this._book.length; i++) {
      if (this._book[i].scene === s) out.push(this._book[i]);
    }
    return out;
  },

  // ---------- DEFINE (host LLM text-in -> offline dict -> honest none) ----------

  _parseLlm(text) {
    // Expected shape (asked for in the prompt):
    //   ZH: <one-line Chinese meaning>
    //   EN: <simple English gloss>
    //   EX: <one short example sentence>
    // Anything else is salvaged line-by-line, never reshaped silently:
    // first plain line -> zh, second -> en, the rest -> example.
    var lines = String(text || '').split('\n');
    var zh = '', en = '', ex = '';
    var plain = [];
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      if (!ln) continue;
      if (/^ZH[:：]/i.test(ln)) zh = ln.replace(/^ZH[:：]/i, '').trim();
      else if (/^EN[:：]/i.test(ln)) en = ln.replace(/^EN[:：]/i, '').trim();
      else if (/^EX[:：]/i.test(ln)) ex = ln.replace(/^EX[:：]/i, '').trim();
      else plain.push(ln);
    }
    if (!zh && plain.length) zh = plain.shift();
    if (!en && plain.length) en = plain.shift();
    if (!ex && plain.length) ex = plain.join(' ');
    if (!zh) return null;
    return { zh: zh.slice(0, 60), en: en.slice(0, 80), ex: ex.slice(0, 120), source: 'LLM' };
  },

  async _llmDefine(word) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    try {
      var avail = await LM.availability();
      if (avail !== 'available') return null;
      var session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You are a concise English-Chinese dictionary for a learner. Follow the requested three-line format exactly.' }]
      });
      try {
        var ans = await this._withTimeout(
          session.prompt('Define the English word "' + word + '" for a Chinese learner. Reply in exactly three lines:\nZH: <one-line Chinese meaning>\nEN: <one-line simple English gloss>\nEX: <one short example sentence>'),
          25000, 'llm');
        if (ans && String(ans).trim()) return this._parseLlm(ans);
        return null;
      } finally {
        try { session.destroy(); } catch (e) {}
      }
    } catch (e) {
      return null; // fall through to the offline dictionary
    }
  },

  async _define(word, forceOffline) {
    if (!forceOffline) {
      var viaLlm = await this._llmDefine(word);
      if (viaLlm) return viaLlm;
    }
    var hit = this._dictLookup(word);
    if (hit) return hit;
    return null;
  },

  async defineTap() {
    if (this._mode !== 'lookup') {
      this.setData({ lastEvent: 'EVT: DEFINE only applies in LOOK mode (MODE toggles)' });
      return;
    }
    if (this.data.busy) return;
    if (!this._word) {
      this.setData({
        status: 'DEFINE FAIL: no word yet - SAY it first',
        lastEvent: 'EVT: DEFINE refused - nothing heard yet'
      });
      return;
    }
    var word = this._word;
    this.setData({ busy: true, status: 'DEFINING "' + word + '"...' });
    try {
      var r = await this._define(word, !!this._demoForceOffline);
      if (!r) {
        this._def = null;
        this._defineFailed = true;
        this.setData({
          defZh: '释义：(none - LLM unavailable, not in offline dict)',
          defEn: 'EN: -',
          defEx: 'EX: -',
          sourceLine: 'SOURCE: none - try another word, or check spelling by SAY again',
          status: 'DEFINE FAIL - no source could define "' + word + '"',
          lastEvent: 'EVT: define FAIL (honest none) for ' + word
        });
        this._renderAll();
        return;
      }
      this._def = r;
      this._defineFailed = false;
      this.setData({
        defZh: '释义：' + r.zh,
        defEn: 'EN: ' + (r.en || '-'),
        defEx: 'EX: ' + (r.ex || '-'),
        sourceLine: 'SOURCE: ' + r.source + (this._demoForceOffline ? ' (DEMO forced offline path)' : ''),
        status: 'DEFINED - SPEAK hears it, SAVE files it under ' + this._scene(),
        lastEvent: 'EVT: defined "' + word + '" via ' + r.source
      });
      this._renderAll();
      this._speakText(word + '。' + r.zh);
    } catch (e) {
      this.setData({
        status: 'DEFINE FAIL - ' + this._err(e),
        lastEvent: 'EVT: define error ' + this._err(e)
      });
    } finally {
      this.setData({ busy: false });
    }
  },

  // ---------- LOOK (telephoto photo, record only - there is no OCR) ----------

  lookTap() { this.capturePhoto(); },

  async capturePhoto() {
    if (this._mode !== 'lookup') {
      this.setData({ lastEvent: 'EVT: LOOK only applies in LOOK mode (MODE toggles)' });
      return;
    }
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host',
        status: 'LOOK FAIL - no camera here; SAY the word anyway',
        lastEvent: 'EVT: LOOK FAIL (host has no camera) - photo is optional'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto)...' });
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
      this.setData({
        photoLine: 'PHOTO: ' + bytes + 'B telephoto - record only, never read',
        status: 'PHOTO SAVED AS RECORD - now SAY the word itself',
        lastEvent: 'EVT: telephoto photo ' + bytes + 'B (record only, no OCR exists)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like glasses-benchmark / gaze-translate.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: ' + size + 'B wx cam (fallback) - record only',
          status: 'PHOTO SAVED AS RECORD - now SAY the word itself',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only, no OCR exists)'
        });
      } catch (e3) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr),
          status: 'LOOK FAIL - no photo; SAY the word anyway',
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

  // ---------- SAY (one-shot ASR for the word itself, verbatim) ----------

  _stopSayRec() {
    if (this._sayRec) {
      try { this._sayRec.abort(); } catch (e) {}
      this._sayRec = null;
    }
  },

  sayTap() {
    if (this._mode !== 'lookup') {
      this.setData({ lastEvent: 'EVT: SAY only applies in LOOK mode (MODE toggles)' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. SAY falls back to
      // cycling the offline dictionary words as demo input instead
      // of pretending to listen.
      var keys = this._dictKeys();
      this._presetIdx = ((this._presetIdx || 0) + 1) % keys.length;
      var w = keys[this._presetIdx];
      this._setWord(w, 'preset - ASR SKIP here, tap SAY to cycle');
      this.setData({
        status: 'WORD preset (ASR n/a) - CHECK it, then DEFINE',
        lastEvent: 'EVT: SAY preset -> ' + w + ' (honest SKIP, no ASR)'
      });
      return;
    }
    this._sayListen('en-US', false);
  },

  _setWord(txt, how) {
    // The heard word is kept VERBATIM (trimmed only, like DI21). It is
    // shown big precisely so the wearer can catch a mishearing BEFORE
    // DEFINE - a wrong word gets a confidently wrong definition.
    this._word = txt;
    this._def = null;
    this._defineFailed = false;
    this.setData({
      wordText: txt,
      wordNote: 'WORD heard (' + how + ') - CHECK it, SAY again if wrong',
      defZh: '释义：-',
      defEn: 'EN: -',
      defEx: 'EX: -',
      sourceLine: 'SOURCE: none - not defined yet'
    });
    this._renderAll();
  },

  async _sayListen(lang, isFallback) {
    var self = this;
    this.setData({ busy: true, wordNote: 'WORD: checking wearer mic...' });
    // Wearer-mode mic check (same documented pattern as DI21): the
    // 4-mic array in 'wearer' mode prioritises YOUR voice. The stream
    // only verifies the mode opens; recognition does the listening.
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
      // English words are the point of this agent, so en-US goes first.
      // Some hosts reject a language they do not carry; ONLY that error
      // earns one honest retry in zh-CN, with a warning kept on screen,
      // because zh-CN recognition of English words mishears often.
      rec.lang = lang;
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          var how = lang + (isFallback ? ' FALLBACK - English may be misheard, CHECK hard' : '');
          self._setWord(txt, how);
          self.setData({
            status: isFallback
              ? 'WORD heard via zh-CN FALLBACK - check it letter by letter'
              : 'WORD heard - CHECK the spelling, then DEFINE',
            lastEvent: 'EVT: word heard (' + micNote + ', ' + lang + ') - verbatim, unverified'
          });
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        var code = String((ev && ev.error) || '');
        if (!isFallback && code.indexOf('language') !== -1) {
          // Host refused en-US: retry once in zh-CN, honestly labelled.
          self.setData({
            wordNote: 'WORD: en-US rejected by host (' + code + ') - retrying zh-CN...',
            status: 'ASR en-US n/a here - zh-CN fallback, words may mishear',
            lastEvent: 'EVT: ASR language fallback en-US -> zh-CN'
          });
          self._sayListen('zh-CN', true);
          return;
        }
        self.setData({
          wordNote: 'WORD: FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + ', tap SAY again',
          status: 'SAY FAIL - say the word slowly, then DEFINE',
          lastEvent: 'EVT: SAY ASR error (' + lang + ')'
        });
      };
      rec.onend = function () {
        if (self._sayRec === rec) self._sayRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        wordNote: 'WORD: listening (' + lang + ') - say just the word...',
        status: 'SAY listening (' + micNote + ')',
        lastEvent: 'EVT: SAY listening, ' + micNote + ', lang ' + lang
      });
    } catch (e) {
      this.setData({
        busy: false,
        wordNote: 'WORD: FAIL - ' + this._err(e),
        status: 'SAY FAIL - recogniser would not start',
        lastEvent: 'EVT: SAY start failed'
      });
    }
  },

  // ---------- SCENE / SAVE / SPEAK ----------

  sceneTap() {
    this._sceneIdx = (this._sceneIdx + 1) % this._scenes().length;
    this._bookIdx = -1;
    this.setData({
      lastEvent: this._mode === 'book'
        ? 'EVT: BOOK filter -> ' + this._scene()
        : 'EVT: SAVE scene -> ' + this._scene()
    });
    this._renderAll();
  },

  saveTap() {
    if (this._mode !== 'lookup') {
      this.setData({ lastEvent: 'EVT: SAVE only applies in LOOK mode (MODE toggles)' });
      return;
    }
    if (!this._word || !this._def) {
      this.setData({
        status: 'SAVE FAIL: SAY a word and DEFINE it first',
        lastEvent: 'EVT: SAVE refused - nothing defined yet'
      });
      return;
    }
    var entry = {
      word: this._word,
      gloss: this._def.zh,
      en: this._def.en || '',
      example: this._def.ex || '',
      source: this._def.source,
      scene: this._scene(),
      date: this._demo ? this._demoToday : this._todayStr()
    };
    this._book.unshift(entry);
    if (this._book.length > 60) this._book.length = 60;
    this._saveBook();
    this.setData({
      status: 'SAVED "' + entry.word + '" under ' + entry.scene + ' · ' + entry.date,
      lastEvent: 'EVT: saved ' + entry.word + ' (' + entry.source + ') - book ' + this._book.length + '/60'
    });
    this._renderAll();
  },

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      // TTS is synthetic speech: it READS the word aloud, it is not a
      // native-speaker recording and its pronunciation is approximate.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    if (this._mode === 'book') {
      var cur = this._reviewCurrent();
      if (!cur) {
        this.setData({ lastEvent: 'EVT: nothing to speak - this scene is empty' });
        return;
      }
      if (this._speakText(cur.word + '。' + cur.gloss + '。' + (cur.example || ''))) {
        this.setData({ lastEvent: 'EVT: TTS sent (synthetic voice) - ' + cur.word });
      }
      return;
    }
    if (!this._def || !this._word) {
      this.setData({ lastEvent: 'EVT: nothing to speak yet - SAY + DEFINE first' });
      return;
    }
    if (this._speakText(this._word + '。' + this._def.zh)) {
      this.setData({ lastEvent: 'EVT: TTS sent (synthetic voice) - ' + this._word + ' + meaning' });
    }
  },

  // ---------- BOOK mode (browse + review by scene) ----------

  modeTap() {
    this._mode = this._mode === 'lookup' ? 'book' : 'lookup';
    this._bookIdx = -1;
    this.setData({
      status: this._mode === 'book'
        ? 'BOOK: SCENE filters, REVIEW walks the words, SPEAK reads'
        : 'LOOK AT THE WORD, SAY IT, CHECK IT, THEN DEFINE',
      lastEvent: 'EVT: mode -> ' + (this._mode === 'book' ? 'BOOK' : 'LOOK')
    });
    this._renderAll();
  },

  _reviewCurrent() {
    // Read-only clamp: rendering must never move the review cursor,
    // or merely opening BOOK mode would silently skip the first word.
    var list = this._filtered();
    if (!list.length) return null;
    var idx = this._bookIdx;
    if (idx < 0 || idx >= list.length) idx = 0;
    return list[idx];
  },

  reviewTap() {
    if (this._mode !== 'book') {
      this.setData({ lastEvent: 'EVT: REVIEW only applies in BOOK mode (MODE toggles)' });
      return;
    }
    var list = this._filtered();
    if (!list.length) {
      this.setData({
        status: 'BOOK: no words under ' + this._scene() + ' yet',
        lastEvent: 'EVT: REVIEW - empty scene ' + this._scene()
      });
      this._renderAll();
      return;
    }
    this._bookIdx = (this._bookIdx + 1) % list.length;
    var cur = list[this._bookIdx];
    this.setData({
      status: 'REVIEW ' + (this._bookIdx + 1) + '/' + list.length + ' in ' + this._scene(),
      lastEvent: 'EVT: review -> ' + cur.word
    });
    this._renderAll();
  },

  // ---------- DEMO (offline path, one Date snapshot, memory only) ----------

  async demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealBook = this._book;
      this._demo = true;
    }
    // DEMO dates all derive from ONE Date snapshot as pure arithmetic,
    // so the seeds stay self-consistent on any host clock.
    var snap = new Date();
    var fmt = function (d) {
      var m = d.getMonth() + 1;
      var day = d.getDate();
      return d.getFullYear() + '-' + (m < 10 ? '0' : '') + m + '-' + (day < 10 ? '0' : '') + day;
    };
    var today = fmt(snap);
    var yest = new Date(snap.getTime());
    yest.setDate(yest.getDate() - 1);
    this._demoToday = today;
    this._mode = 'lookup';
    this._sceneIdx = 1; // 旅行
    this._demoForceOffline = true;
    var seedDict = this._dict();
    this._book = [
      { word: 'boarding', gloss: seedDict['boarding'].zh, en: seedDict['boarding'].en, example: seedDict['boarding'].ex, source: 'OFFLINE', scene: '旅行', date: today },
      { word: 'luggage', gloss: seedDict['luggage'].zh, en: seedDict['luggage'].en, example: seedDict['luggage'].ex, source: 'OFFLINE', scene: '旅行', date: fmt(yest) }
    ];
    this._bookIdx = -1;
    this._setWord('itinerary', 'DEMO seed');
    this.setData({
      photoLine: 'PHOTO: DEMO - no camera used here',
      status: 'DEMO: defining "itinerary" via OFFLINE dict...',
      lastEvent: 'EVT: DEMO on - offline path, book seeded in memory only'
    });
    this._renderAll();
    await this.defineTap();
    // Land in the result view with the word filed under 旅行.
    if (this._def) {
      this.saveTap();
      this.setData({
        status: 'DEMO RESULT - "itinerary" defined OFFLINE, saved under 旅行',
        lastEvent: 'EVT: DEMO landed - result view, book holds 3 demo words (旅行)'
      });
      this._renderAll();
    }
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO restores the real book untouched (demo never saved).
      this._demo = false;
      this._demoForceOffline = false;
      this._book = this._demoRealBook || this._loadBook();
      this._demoRealBook = null;
      this._word = '';
      this._def = null;
      this._bookIdx = -1;
      this.setData({
        wordText: '(no word yet)',
        wordNote: 'WORD: tap SAY, say the word - shown VERBATIM',
        photoLine: 'PHOTO: none - LOOK = telephoto record only',
        defZh: '释义：-',
        defEn: 'EN: -',
        defEx: 'EX: -',
        sourceLine: 'SOURCE: none - no lookup yet',
        status: 'DEMO OFF - your real book is back (' + this._book.length + ' words)',
        lastEvent: 'EVT: DEMO cleared - real book restored, nothing was written'
      });
      this._renderAll();
      return;
    }
    this._book = [];
    this._saveBook();
    this._bookIdx = -1;
    this.setData({
      status: 'BOOK CLEARED - 0/60',
      lastEvent: 'EVT: word book emptied (on-device only, nothing was uploaded)'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var counts = this._sceneCounts();
    var list = this._filtered();
    var rows = [];
    var show = list.slice(0, 8);
    var curIdx = this._bookIdx;
    if (curIdx < 0 || curIdx >= list.length) curIdx = 0;
    for (var i = 0; i !== show.length; i++) {
      var it = show[i];
      var reviewing = this._mode === 'book' && i === curIdx;
      rows.push({
        name: (reviewing ? '▶ ' : '') + it.word,
        detail: it.gloss + ' · ' + it.date,
        flag: it.source === 'LLM' ? 'LLM' : 'OFF',
        cls: reviewing ? 'row row-urgent' : 'row'
      });
    }
    if (!rows.length) {
      rows.push({
        name: '(no words under ' + this._scene() + ')',
        detail: this._mode === 'book' ? 'SCENE switches the filter' : 'DEFINE a word, SAVE files it here',
        flag: '',
        cls: 'row'
      });
    }
    var box = this._boxContent();
    this.setData({
      modeText: this._mode === 'book'
        ? 'MODE: BOOK - scene ' + this._scene() + ' · ' + list.length + ' word(s)'
        : 'MODE: LOOK - find a word',
      sceneText: this._scene(),
      bookLine: 'BOOK: ' + this._book.length + '/60 · 阅读 ' + counts['阅读'] +
        ' · 旅行 ' + counts['旅行'] + ' · 工作 ' + counts['工作'] + ' · 日常 ' + counts['日常'],
      rows: rows,
      boxLabel: box.label,
      boxBody: box.body,
      boxSub1: box.sub1,
      boxSub2: box.sub2,
      boxSub3: box.sub3
    });
  },

  // One merged box under the buttons: DEFINITION in lookup-result
  // state, the CHECK prompt while a word waits, REVIEW in book mode.
  _boxContent() {
    if (this._mode === 'book') {
      var cur = this._reviewCurrent();
      if (cur) {
        return {
          label: '◎ REVIEW · ' + this._scene() + ' · saved ' + cur.date + ' · src ' + cur.source,
          body: cur.word + ' — ' + cur.gloss,
          sub1: 'EN: ' + (cur.en || '-'),
          sub2: 'EX: ' + (cur.example || '-'),
          sub3: 'REVIEW walks on · SPEAK reads it (synthetic voice)'
        };
      }
      return {
        label: '◎ REVIEW · ' + this._scene(),
        body: '这个场景还没有词 — 回 LOOK 查一个存进来',
        sub1: 'SCENE 换场景过滤；生词本只存本机，不上传。',
        sub2: '',
        sub3: ''
      };
    }
    if (this._word && (this._def || this._defineFailed)) {
      return {
        label: 'DEFINITION',
        body: this.data.defZh,
        sub1: this.data.defEn,
        sub2: this.data.defEx,
        sub3: this.data.sourceLine
      };
    }
    if (this._word) {
      return {
        label: '◎ CHECK THE WORD · the confirm step IS the product',
        body: '你说的是「' + this._word + '」吗？对就 DEFINE，错就再 SAY',
        sub1: '眼镜不会替你纠正听错的词 — 错着查，就会得到一个错意思。',
        sub2: '',
        sub3: this.data.sourceLine
      };
    }
    return {
      label: '◎ THE WORD - you say it, the glasses only take a photo',
      body: '照片读不了字：词靠你说出来，听到的原样显示，先核对再查。',
      sub1: '听错一个词，就会查出一个错意思 — 核对这一步就是产品本身。',
      sub2: '',
      sub3: ''
    };
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">WORD LOOK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{modeText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">◎ WORD - heard by SAY, shown VERBATIM; LOOK photo is a record only</text>
      <text class="word">{{wordText}}</text>
      <text class="photo">{{wordNote}}</text>
      <text class="photo">{{photoLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn btn-main" bindtap="sayTap">SAY</button>
      <button class="btn btn-main" bindtap="defineTap">DEFINE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="sceneTap">SCENE: {{sceneText}}</button>
      <button class="btn" bindtap="saveTap">SAVE</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="step">{{boxBody}}</text>
      <text class="photo">{{boxSub1}}</text>
      <text class="photo">{{boxSub2}}</text>
      <text class="photo">{{boxSub3}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{bookLine}}</text>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="reviewTap">REVIEW</button>
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
.word {
  color: #40ff5e;
  font-size: 16px;
  font-weight: 500;
  line-height: 19px;
  margin-top: 2px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.def-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.defzh {
  color: #40ff5e;
  font-size: 13px;
  line-height: 15px;
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
  height: 21px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.row-urgent .rname, .row-urgent .rdetail {
  color: #40ff5e;
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
  line-height: 16px;
  margin-top: 2px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
</style>
