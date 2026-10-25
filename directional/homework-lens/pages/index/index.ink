<script def>
{
  "navigationBarTitleText": "Homework Lens"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'AIM AT THE PROBLEM, SNAP IT - HINT MODE BY DEFAULT',
    steadyText: 'HEAD: moving - hold still',
    headLine: 'HEAD: --- deg · SRC: NONE',
    boxLabel: '◎ THIS PROBLEM - photo in memory only; ASK sends it to the AI as an image',
    probLine: 'PROB: none - SNAP the problem, or DICT it in your own words',
    subjLine: 'SUBJ: 数学 · MODE: HINT （只给提示，不给答案）',
    stepHead: 'STEP -/-',
    stepText: '解题步骤会一步一步显示在这里（机器给的，先看再讲）。',
    ansLine: 'ANSWER: hidden - only a parent REVEAL tap shows it',
    followLine: 'MORE: on a step, dictate a question about THIS step (host ASR)',
    micLine: 'MIC CHECK: not run',
    footLine: 'photos NOT saved · nothing is stored · AI steps can be wrong - parent checks',
    lastEvent: 'EVT: nod when steady = NEXT step only (never snaps, asks or reveals)',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._pending = null;      // the problem in progress (photo Blob lives here, memory only)
    this._subjectIdx = 0;
    this._mode = 'HINT';       // decided before ASK; stored into pending at ASK time
    this._builtin = false;     // built-in coaching prompts active (LLM unavailable)
    this._coachIdx = 0;
    this._presetIdx = -1;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._sensor = null;
    this._demo = false;
    this._startHeading();
    this._renderAll();
    this.setData({ lastEvent: 'EVT: session only - nothing you do here is stored' });
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
  },

  onHide() {
    this._stopHeading();
    this._stopRec();
  },

  onUnload() {
    this._stopHeading();
    this._stopRec();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    // Nothing is persisted - deliberately. Homework is ephemeral:
    // no wx storage is written anywhere in this agent.
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
    // A nod only ADVANCES the step already on screen (or cycles the
    // built-in coaching prompts). It never takes a photo, never
    // starts an ASK and never reveals the answer - those are always
    // deliberate parent taps.
    if (this._hasSteps() || this._builtin) {
      if (this._steady) this.nextTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to advance' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - SNAP/DICT and ASK first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm = NEXT' });
      if (!this.data.busy && (this._hasSteps() || this._builtin)) this.nextTap();
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
  // as DI25/DI38/DI39: the preview host's Date is virtualised and
  // drifts between calls, so one capture's date + time come from
  // one read).
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

  _subjects() {
    return ['数学', '语文', '英语', '科学', '其他'];
  },

  _modeText(m) {
    return m === 'FULL' ? 'FULL （讲清步骤，答案另藏）' : 'HINT （只给提示，不给答案）';
  },

  _builtinPrompts() {
    // Built-in generic coaching prompts (NOT AI) for when the host
    // language model is unavailable: the parent can still coach.
    return [
      '先圈出题目里的已知条件，再写下题目到底要求什么。',
      '把问题拆小：先只做第一步，做完再看下一步要什么。',
      '找一道做过的例题对照：它和这道题哪里像、哪里不一样？'
    ];
  },

  _presetProblems() {
    // Demo input for hosts with no recogniser (honest SKIP path):
    // sample dictated problems, cycled by DICT, labelled presets.
    return [
      '一个长方形长 8 厘米、宽 5 厘米，周长是多少？（预置）',
      '小明有 24 颗糖，平均分给 4 个朋友，每人几颗？（预置）'
    ];
  },

  _hasSteps() {
    return !!(this._pending && this._pending.asked && this._pending.steps && this._pending.steps.length);
  },

  // ---------- heading (AbsoluteOrientationSensor, same as DI07/DI26/DI38/DI39) ----------

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

  snapTap() {
    if (this._demo) { this._demo = false; this._pending = null; }
    this._builtin = false;
    return this.capturePhoto();
  },

  async capturePhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        probLine: 'PROB: FAIL - mediaDevices n/a on this host',
        status: 'SNAP FAIL - no camera here; DICT the problem instead',
        lastEvent: 'EVT: SNAP FAIL (host has no camera) - DICT still works'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (telephoto) the problem...' });
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
      this._pending = this._newPending({
        blob: blob, bytes: bytes, wxPhoto: false,
        heading: this._heading, date: st.date, time: st.time
      });
      this.setData({
        status: 'PHOTO HELD IN MEMORY - ASK sends it to the AI as an image',
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
      // photo has no Blob to convert, so ASK will honestly report
      // the image path unavailable for it - DICT remains the path.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        var st2 = this._stamp();
        this._pending = this._newPending({
          blob: null, bytes: size, wxPhoto: true,
          heading: this._heading, date: st2.date, time: st2.time
        });
        this.setData({
          status: 'PHOTO HELD (wx) - image read n/a for wx photos; DICT the problem',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - ASK cannot convert it)'
        });
        this._renderAll();
      } catch (e3) {
        this.setData({
          status: 'SNAP FAIL - no photo; DICT the problem instead',
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

  _newPending(base) {
    base.problemText = '';      // dictated problem (verbatim) for the text-only path
    base.problemSummary = '';   // the model's one-line restatement (context for MORE)
    base.subject = '';
    base.mode = '';
    base.steps = [];
    base.stepIdx = 0;
    base.answer = '';           // quarantined final answer, behind REVEAL only
    base.asked = false;
    base.revealed = false;
    base.demo = !!base.demo;
    return base;
  },

  // ---------- ASK (photo -> data: URL -> host LLM image input, or dictated text) ----------

  _blobToDataUrl(blob) {
    // The ONLY conversion the runtime story offers: Blob -> data:
    // URL via FileReader. If FileReader is missing this rejects,
    // and ASK lands in the honest conversion-unavailable state.
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

  _modeRule(mode) {
    if (mode === 'FULL') {
      return 'Mode: FULL EXPLANATION. Give numbered steps WITH the worked reasoning a parent can follow, ' +
        'and put the final answer ONLY on the ANSWER line at the very end - never inside a step.';
    }
    return 'Mode: HINTS ONLY. Give numbered steps where each step is a hint or a guiding question that ' +
      'helps the child think - do NOT work the problem out and do NOT state the final answer anywhere.';
  },

  _askFormat(mode) {
    var s = 'Reply in Chinese in exactly this format:\n' +
      'PROBLEM: <one line restating the problem>\n' +
      'STEPS:\n' +
      '1. <step>\n' +
      '2. <step>\n' +
      '(3 to 6 steps)';
    if (mode === 'FULL') s += '\nANSWER: <the final answer>';
    return s;
  },

  _buildAskContent(dataUrl, subject, mode) {
    // Multimodal content goes in the USER message only (dossier
    // section 2.9): one text part with the instructions, one
    // image_url part carrying the data: URL. The system prompt is
    // set separately via initialPrompts at create() time.
    var text = 'This photo shows a homework problem (subject: ' + subject + ') a child is stuck on. ' +
      'Read the problem in the photo carefully; if part of it is unreadable, say so in the PROBLEM line instead of inventing it. ' +
      this._modeRule(mode) + '\n' + this._askFormat(mode);
    return [
      { type: 'text', text: text },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  _buildAskText(problemText, subject, mode) {
    // Text-only path: the parent dictated the problem; the words
    // are theirs verbatim, shown on screen before ASK ran.
    return 'A parent dictated this homework problem (subject: ' + subject + '), verbatim: "' + problemText + '". ' +
      this._modeRule(mode) + '\n' + this._askFormat(mode);
  },

  // Pull any ANSWER / 答案 line out of a model reply: in HINT mode
  // the model was told not to give one, and in FULL mode it belongs
  // at the end anyway. Either way it is quarantined behind the
  // parent's REVEAL tap - never part of the step flow, never spoken
  // before REVEAL.
  _extractAnswer(text) {
    var lines = String(text || '').split('\n');
    var kept = [];
    var answer = '';
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i];
      var m = ln.match(/^\s*(ANSWER|答案|最终答案)\s*[:：]\s*(.+)$/i);
      if (m) { if (!answer) answer = m[2].trim(); continue; }
      kept.push(ln);
    }
    return { clean: kept.join('\n'), answer: answer.slice(0, 80) };
  },

  _parseReply(text) {
    // Expected shape (asked for in the prompt):
    //   PROBLEM: <one-line restatement>
    //   STEPS:
    //   1. <step>
    //   2. <step>
    //   ANSWER: <final answer>     (FULL mode; quarantined first)
    // Salvage line-by-line if the labels drift; never reshape
    // silently: unnumbered lines inside STEPS become steps too,
    // and a first plain line becomes the problem summary.
    var ex = this._extractAnswer(text);
    var lines = ex.clean.split('\n');
    var problem = '';
    var steps = [];
    var inSteps = false;
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      if (!ln) continue;
      if (/^PROBLEM[:：]/i.test(ln)) { problem = ln.replace(/^PROBLEM[:：]/i, '').trim(); continue; }
      if (/^STEPS?[:：]/i.test(ln)) {
        inSteps = true;
        var rest = ln.replace(/^STEPS?[:：]/i, '').trim();
        if (rest) steps.push(rest);
        continue;
      }
      var num = ln.match(/^\d+\s*[.、．):)]\s*(.+)$/);
      if (num) { steps.push(num[1].trim()); inSteps = true; continue; }
      if (inSteps) steps.push(ln);
      else if (!problem) problem = ln;
    }
    steps = steps.filter(function (s) { return !!s; }).slice(0, 8);
    for (var j = 0; j !== steps.length; j++) steps[j] = steps[j].slice(0, 140);
    if (!steps.length) return null;
    return {
      problem: problem.slice(0, 80) || '(problem not restated)',
      steps: steps,
      answer: ex.answer
    };
  },

  async _llmPrompt(content) {
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
        initialPrompts: [{ role: 'system', content: 'You are a patient homework tutor helping a parent coach a child. Follow the requested format and the mode rule exactly; teach, do not just hand over results.' }]
      });
      var ans = await this._withTimeout(session.prompt(content), 30000, 'llm ask');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      return { ok: true, text: String(ans) };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  _enterBuiltin(why) {
    // The language model cannot help on this host right now. The
    // parent still gets something honest: built-in generic coaching
    // prompts, labelled as built-in - never dressed up as AI.
    this._builtin = true;
    this._coachIdx = 0;
    this.setData({
      status: 'AI UNAVAILABLE (' + why + ') - built-in coaching prompts instead (not AI)',
      lastEvent: 'EVT: ASK fell back to BUILT-IN coach prompts - no model output claimed'
    });
    this._renderAll();
  },

  async askTap() {
    if (this.data.busy) return;
    var p = this._pending;
    if (!p) {
      this.setData({
        status: 'ASK FAIL: SNAP a problem first (or DICT it)',
        lastEvent: 'EVT: ASK refused - nothing pending'
      });
      return;
    }
    var subject = this._subjects()[this._subjectIdx];
    var mode = this._mode;
    if (p.wxPhoto) {
      this.setData({
        status: 'ASK N/A for a wx photo (no Blob to convert) - DICT the problem, ASK runs on your words',
        lastEvent: 'EVT: ASK skipped - wx photo cannot become a data: URL'
      });
      this._renderAll();
      return;
    }
    this.setData({ busy: true, status: 'ASKING the host AI (' + mode + ' mode, ' + subject + ')...' });
    try {
      var content;
      if (p.blob) {
        var dataUrl;
        try {
          dataUrl = await this._withTimeout(this._blobToDataUrl(p.blob), 12000, 'convert');
        } catch (ce) {
          this.setData({
            status: 'ASK N/A - image conversion unavailable here (' + this._err(ce) + '); DICT the problem instead',
            lastEvent: 'EVT: ASK conversion FAIL - ' + this._err(ce)
          });
          this._renderAll();
          return;
        }
        if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
          this.setData({
            status: 'ASK N/A - conversion returned no data: URL; DICT the problem instead',
            lastEvent: 'EVT: ASK conversion FAIL - result was not a data: URL'
          });
          this._renderAll();
          return;
        }
        content = this._buildAskContent(dataUrl, subject, mode);
      } else if (p.problemText) {
        content = this._buildAskText(p.problemText, subject, mode);
      } else {
        this.setData({
          status: 'ASK FAIL: this capture has no photo and no dictated problem',
          lastEvent: 'EVT: ASK refused - empty pending'
        });
        return;
      }
      var r = await this._llmPrompt(content);
      if (!r.ok) {
        var why = r.reason === 'no-lm' ? 'no language model on this host'
          : r.reason === 'unavailable' ? 'language model unavailable now'
          : r.reason === 'empty' ? 'the model returned nothing usable'
          : 'model error - ' + this._err(r.error);
        this._enterBuiltin(why);
        return;
      }
      var parsed = this._parseReply(r.text);
      if (!parsed) {
        this._enterBuiltin('the reply had no steps to show');
        return;
      }
      p.subject = subject;
      p.mode = mode;
      p.problemSummary = parsed.problem;
      p.steps = parsed.steps;
      p.stepIdx = 0;
      p.answer = parsed.answer;
      p.asked = true;
      p.revealed = false;
      this._builtin = false;
      this.setData({
        status: 'AI STEPS READY (' + mode + ') - step 1 of ' + parsed.steps.length +
          '; check them before you coach' +
          (parsed.answer ? '; the answer is quarantined behind REVEAL' : ''),
        lastEvent: 'EVT: ASK ok - ' + parsed.steps.length + ' steps (' + mode + ')' +
          (parsed.answer && mode === 'HINT' ? '; model leaked an ANSWER line in HINT mode - quarantined, NOT shown' : '')
      });
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  // ---------- mic availability check + one-shot listening (shared by DICT and MORE) ----------

  _stopRec() {
    if (this._rec) {
      try { this._rec.abort(); } catch (e) {}
      this._rec = null;
    }
  },

  async _micCheck() {
    // Wearer-mode mic AVAILABILITY check (same documented pattern
    // as DI21/DI36/DI38/DI39): open the wearer-mode stream, read back
    // its settings, stop every track at once. The check stream is
    // NOT the recognition input and does not shape what recognition
    // hears - the host SpeechRecognition listens on its own
    // microphone (dossier sections 2.4 / 2.8). The result is shown
    // on its own MIC CHECK line; listening lines say (host ASR).
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
    return micNote;
  },

  // One-shot host recognition after the mic check. onText receives
  // the verbatim transcript. The check tracks are already stopped
  // before the recogniser starts - asserted in the Node harness.
  async _listenOnce(label, onText) {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    var micNote = await this._micCheck();
    try {
      this._stopRec();
      var rec = new SpeechRecognition();
      this._rec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (txt) onText(txt, micNote);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: label + ' FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + ', tap again',
          lastEvent: 'EVT: ' + label + ' ASR error'
        });
      };
      rec.onend = function () {
        if (self._rec === rec) self._rec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: label + ' listening (host ASR)...',
        lastEvent: 'EVT: ' + label + ' listening (host ASR), ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        status: label + ' FAIL - recogniser would not start',
        lastEvent: 'EVT: ' + label + ' start failed - ' + this._err(e)
      });
    }
  },

  // ---------- DICT (dictate the problem; the always-available fallback input) ----------

  _ensurePending() {
    if (this._pending) return this._pending;
    var st = this._stamp();
    this._pending = this._newPending({
      blob: null, bytes: 0, wxPhoto: false,
      heading: this._heading, date: st.date, time: st.time
    });
    this.setData({ lastEvent: 'EVT: pending created by DICT (no photo for this problem)' });
    return this._pending;
  },

  dictTap() {
    if (this.data.busy) return;
    if (this._demo) { this._demo = false; this._pending = null; }
    this._ensurePending();
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. DICT cycles sample
      // problems as demo input instead of pretending to listen.
      var presets = this._presetProblems();
      this._presetIdx = ((this._presetIdx || 0) + 1) % presets.length;
      this._pending.problemText = presets[this._presetIdx];
      this.setData({
        status: 'PROBLEM preset (ASR n/a) - check it, then ASK (text-only)',
        lastEvent: 'EVT: DICT preset -> sample problem (honest SKIP, no ASR)'
      });
      this._renderAll();
      return;
    }
    var self = this;
    this._listenOnce('DICT', function (txt, micNote) {
      self._ensurePending().problemText = txt;
      self.setData({
        status: 'PROBLEM heard verbatim - check it, then ASK (text-only)',
        lastEvent: 'EVT: dictated problem heard (' + micNote + ') - verbatim'
      });
      self._renderAll();
    });
  },

  // ---------- step navigation / SPEAK / REVEAL ----------

  nextTap() {
    if (this.data.busy) return;
    if (this._builtin) {
      var prompts = this._builtinPrompts();
      this._coachIdx = (this._coachIdx + 1) % prompts.length;
      this.setData({ lastEvent: 'EVT: built-in coach prompt ' + (this._coachIdx + 1) + '/' + prompts.length });
      this._renderAll();
      return;
    }
    if (!this._hasSteps()) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - no steps on screen' });
      return;
    }
    var p = this._pending;
    if (p.stepIdx < p.steps.length - 1) {
      p.stepIdx++;
      this.setData({ lastEvent: 'EVT: step ' + (p.stepIdx + 1) + '/' + p.steps.length });
    } else {
      this.setData({
        status: 'LAST STEP - MORE asks about this step; REVEAL shows the answer (parent tap)',
        lastEvent: 'EVT: already at the last step'
      });
    }
    this._renderAll();
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

  _currentSpeakText() {
    if (this._builtin) return this._builtinPrompts()[this._coachIdx];
    var p = this._pending;
    if (p && p.asked && p.steps && p.steps.length) {
      var t = '第' + (p.stepIdx + 1) + '步：' + p.steps[p.stepIdx];
      // The quarantined answer joins speech ONLY after the parent
      // tapped REVEAL, and only from the last step. Before REVEAL
      // the answer is never in any spoken text - harness-asserted.
      if (p.revealed && p.answer && p.stepIdx === p.steps.length - 1) {
        t += '。答案：' + p.answer;
      }
      return t;
    }
    return '';
  },

  speakTap() {
    var t = this._currentSpeakText();
    if (!t) {
      this.setData({
        status: 'SPEAK: nothing to read yet - ASK first',
        lastEvent: 'EVT: SPEAK refused - no steps'
      });
      return;
    }
    if (this._speakText(t)) {
      this.setData({ lastEvent: 'EVT: TTS step sent (synthetic voice, readback only)' });
    }
  },

  revealTap() {
    var p = this._pending;
    if (!p || !p.asked) {
      this.setData({
        status: 'REVEAL: nothing asked yet',
        lastEvent: 'EVT: REVEAL refused - ASK first'
      });
      return;
    }
    if (!p.answer) {
      // Honest empty case: in HINT mode the model was told not to
      // give an answer, and it did not leak one - there is nothing
      // stored to reveal. Say so instead of inventing one.
      this.setData({
        status: 'REVEAL: no answer stored - ' + p.mode + ' mode asked for none (switch MODE to FULL and ASK again for one)',
        lastEvent: 'EVT: REVEAL - no quarantined answer exists'
      });
      this._renderAll();
      return;
    }
    p.revealed = true;
    this.setData({
      status: 'ANSWER REVEALED (parent) - check it yourself before the child relies on it',
      lastEvent: 'EVT: REVEAL tapped by parent - answer now on screen'
    });
    this._renderAll();
  },

  // ---------- MORE (ask about THIS step; follow-up with context, text-only) ----------

  moreTap() {
    if (this.data.busy) return;
    if (!this._hasSteps()) {
      this.setData({
        status: 'MORE: get steps on screen first (SNAP/DICT + ASK)',
        lastEvent: 'EVT: MORE refused - no current step'
      });
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'MORE needs the host recogniser - n/a on this host',
        lastEvent: 'EVT: MORE SKIP - SpeechRecognition n/a (honest, no fake listening)'
      });
      return;
    }
    var self = this;
    this._listenOnce('MORE', function (txt, micNote) {
      self._followUp(txt, micNote);
    });
  },

  async _followUp(question, micNote) {
    var p = this._pending;
    if (!p || !this._hasSteps()) return;
    var stepText = p.steps[p.stepIdx];
    this.setData({
      busy: true,
      followLine: 'MORE Q (' + micNote + '): ' + question,
      status: 'ASKING about step ' + (p.stepIdx + 1) + '...'
    });
    this._renderAll();
    // Follow-ups are TEXT-only, in a fresh session (sessions are
    // create -> prompt -> destroy, like ASK): the context - the
    // problem summary, the current step and the mode rule - is
    // restated inside the prompt itself.
    var content = 'Homework follow-up. Problem: ' + (p.problemSummary || p.problemText || '(from photo)') +
      ' (subject: ' + (p.subject || '') + '). The child is on step ' + (p.stepIdx + 1) + ' of ' +
      p.steps.length + ': "' + stepText + '". ' + this._modeRule(p.mode || 'HINT') +
      ' Answer this follow-up question about THIS step, in Chinese, in at most 3 short sentences: ' + question;
    var r = await this._llmPrompt(content);
    this.setData({ busy: false });
    if (!r.ok) {
      var why = r.reason === 'no-lm' ? 'no language model on this host'
        : r.reason === 'unavailable' ? 'language model unavailable now'
        : r.reason === 'empty' ? 'the model returned nothing usable'
        : 'model error - ' + this._err(r.error);
      this.setData({
        followLine: 'MORE: follow-up failed - ' + why,
        status: 'MORE FAILED - the step above still stands; coach it yourself or retry',
        lastEvent: 'EVT: MORE FAIL (' + r.reason + ')'
      });
      this._renderAll();
      return;
    }
    var ex = this._extractAnswer(r.text);
    var shown = ex.clean.replace(/\s*\n\s*/g, ' ').trim().slice(0, 200);
    var note = '';
    if (ex.answer) {
      // Same quarantine discipline as ASK: a follow-up in HINT
      // mode does not get to smuggle the answer onto the screen.
      if (!p.answer) p.answer = ex.answer;
      p.answerFromFollow = true;
      note = ' (an ANSWER line was quarantined behind REVEAL)';
    }
    this.setData({
      followLine: 'MORE A (LLM, may be wrong - parent checks): ' + shown,
      status: 'FOLLOW-UP ANSWERED - it is machine text; verify before coaching',
      lastEvent: 'EVT: MORE ok - answer shown for step ' + (p.stepIdx + 1) + note
    });
    this._renderAll();
  },

  // ---------- subject / mode / demo ----------

  subjTap() {
    this._subjectIdx = (this._subjectIdx + 1) % this._subjects().length;
    this.setData({
      lastEvent: 'EVT: subject -> ' + this._subjects()[this._subjectIdx] + ' (applies at ASK)'
    });
    this._renderAll();
  },

  modeTap() {
    this._mode = this._mode === 'HINT' ? 'FULL' : 'HINT';
    var p = this._pending;
    this.setData({
      lastEvent: 'EVT: mode -> ' + this._mode +
        (p && p.asked ? ' (applies to the NEXT problem - SNAP/DICT + ASK again)' : ' (applies at ASK)')
    });
    this._renderAll();
  },

  demoTap() {
    if (this.data.busy) return;
    if (this._demo) {
      this._demo = false;
      this._pending = null;
      this._builtin = false;
      this.setData({
        status: 'DEMO OFF - session cleared (nothing was stored)',
        lastEvent: 'EVT: DEMO cleared'
      });
      this._renderAll();
      return;
    }
    this._demo = true;
    this._builtin = false;
    var st = this._stamp();
    var p = this._newPending({
      blob: null, bytes: 0, wxPhoto: false, demo: true,
      heading: null, date: st.date, time: st.time
    });
    p.subject = '数学';
    p.mode = 'HINT';
    p.problemSummary = '解方程 3x + 5 = 20（DEMO 题目）';
    p.steps = [
      '先想一想：等号两边要保持平衡，左边的 +5 应该怎么去掉？',
      '两边同时减去 5：左边还剩什么？右边是多少？',
      '现在变成 3x 等于一个数，x 前面的 3 又该怎么去掉？',
      '两边同时除以 3，算出 x，再代回原方程验算一遍。'
    ];
    p.stepIdx = 0;
    // The DEMO models the worst case on purpose: in HINT mode the
    // (seeded) model reply leaked an ANSWER line. It was stripped
    // from the steps and quarantined behind REVEAL, exactly like a
    // real leak - the preview shows the discipline, not just steps.
    p.answer = 'x = 5';
    p.asked = true;
    p.revealed = false;
    this._pending = p;
    this.setData({
      status: 'DEMO - 4 HINT steps for a seeded problem; the model leaked an answer, quarantined behind REVEAL',
      lastEvent: 'EVT: DEMO on - seeded steps + quarantined answer (memory only, nothing stored)'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var p = this._pending;
    var patch = {};
    var subj = p && p.asked ? p.subject : this._subjects()[this._subjectIdx];
    var mode = p && p.asked ? p.mode : this._mode;
    patch.subjLine = 'SUBJ: ' + subj + ' · MODE: ' + mode + ' ' +
      (mode === 'FULL' ? '（讲清步骤，答案另藏）' : '（只给提示，不给答案）') +
      (p && p.asked ? '' : ' - set before ASK');
    if (this._builtin) {
      var prompts = this._builtinPrompts();
      patch.boxLabel = '◎ BUILT-IN COACH - the AI is unavailable; these prompts are built in, not AI';
      patch.stepHead = 'COACH ' + (this._coachIdx + 1) + '/' + prompts.length + ' · BUILT-IN';
      patch.stepText = prompts[this._coachIdx];
      patch.ansLine = 'ANSWER: none - no model, no answer stored';
      this.setData(patch);
      return;
    }
    if (!p) {
      patch.probLine = 'PROB: none - SNAP the problem, or DICT it in your own words';
      patch.stepHead = 'STEP -/-';
      patch.stepText = '解题步骤会一步一步显示在这里（机器给的，先看再讲）。';
      patch.ansLine = 'ANSWER: hidden - only a parent REVEAL tap shows it';
      this.setData(patch);
      return;
    }
    if (p.demo) {
      patch.probLine = 'PROB (DEMO): ' + p.problemSummary + ' · no camera used';
    } else if (p.blob) {
      patch.probLine = 'PROB: photo ' + p.bytes + 'B · ' + p.time + ' · head ' + this._headText(p.heading) + ' · memory only, NOT saved';
    } else if (p.wxPhoto) {
      patch.probLine = 'PROB: wx photo ' + p.bytes + 'B · ' + p.time + ' · image read n/a - DICT the problem';
    } else if (p.problemText) {
      patch.probLine = 'PROB (your words): ' + p.problemText.slice(0, 46);
    } else {
      patch.probLine = 'PROB: photo pending · ' + p.time;
    }
    if (p.asked && p.steps.length) {
      patch.boxLabel = '◎ AI STEPS (' + (p.demo ? 'DEMO' : 'LLM') + ') - machine output, may be wrong; parent verifies';
      patch.stepHead = 'STEP ' + (p.stepIdx + 1) + '/' + p.steps.length + ' · ' + p.mode +
        (p.demo ? ' (DEMO)' : '') + ' · ' + (p.problemSummary || '');
      patch.stepText = p.steps[p.stepIdx];
      patch.ansLine = p.revealed
        ? 'ANSWER (parent revealed): ' + p.answer + ' - check it yourself first'
        : (p.answer
          ? 'ANSWER: quarantined - REVEAL (parent tap) shows it'
          : 'ANSWER: none stored - ' + p.mode + ' mode asked for none');
    } else {
      patch.boxLabel = '◎ THIS PROBLEM - photo in memory only; ASK sends it to the AI as an image';
      patch.stepHead = 'STEP -/-';
      patch.stepText = p.problemText
        ? '题目已口述，点 ASK（纯文字）开始分步。'
        : '照片已就绪，点 ASK 让大模型分步（先选好 SUBJ 与 MODE）。';
      patch.ansLine = 'ANSWER: hidden - only a parent REVEAL tap shows it';
    }
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">HOMEWORK LENS</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{headLine}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="photo">{{probLine}}</text>
      <text class="photo">{{subjLine}}</text>
      <text class="step-head">{{stepHead}}</text>
      <text class="step">{{stepText}}</text>
      <text class="photo">{{ansLine}}</text>
      <text class="photo">{{followLine}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="askTap">ASK</button>
      <button class="btn" bindtap="dictTap">DICT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="subjTap">SUBJ</button>
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="moreTap">MORE</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="revealTap">REVEAL</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="sub">{{footLine}}</text>
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
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.step-head {
  color: #40ff5e;
  font-size: 13px;
  line-height: 16px;
  margin-top: 2px;
}
.step {
  color: #40ff5e;
  font-size: 15px;
  line-height: 19px;
  margin-top: 2px;
}
.ans {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
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
