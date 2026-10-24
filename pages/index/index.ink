<script def>
{
  "navigationBarTitleText": "Queue Sense"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK ALONG THE QUEUE - COUNT+ PER PERSON AHEAD',
    steadyText: 'HEAD: moving - hold still',
    queueLine: 'ACTIVE: A · swipe / QUEUE cycles A-B-C',
    peopleLine: 'A · PEOPLE AHEAD: 0',
    rateLine: 'RATE (A): not measured yet - counting only',
    estLine: 'EST (A): - (no measured rate yet)',
    allLine: 'A: 0 ppl · B: 0 ppl · C: 0 ppl',
    noteLine: 'YOUR NOTE (A): - (DICT a posted headway; your words)',
    photoLine: 'PHOTO (A): none - session record only, never saved',
    micLine: 'MIC CHECK: not run',
    cmpLine: 'BEST: - (SPEAK compares the three queues)',
    lastEvent: 'EVT: tap(Enter)=COUNT+ · swipe=queue · nod(steady)=SERVED',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._letters = ['A', 'B', 'C'];
    this._queues = [this._newQueue(), this._newQueue(), this._newQueue()];
    this._active = 0;
    this._elapsed = 0;         // seconds, accumulated by 1 s ticks (never re-sampled from Date)
    this._timer = null;
    this._steady = false;
    this._demo = false;
    this._demoSaved = null;
    this._dictRec = null;
    this._startTimer();
    this._renderAll();
  },

  onShow() {
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopDictRec();
  },

  onUnload() {
    this._stopTimer();
    this._stopDictRec();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    // Session only: nothing is written to storage, ever.
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    // A nod marks one SERVED event for the active queue - you are
    // watching the front of the queue. It needs a steady head, and
    // it NEVER counts a person (counting is COUNT+ / Enter only).
    if (this.data.busy) {
      this.setData({ lastEvent: 'EVT: nod ignored - busy' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady (nod = SERVED)' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod (steady) = SERVED on ' + this._letter() });
    this._markServed();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier section 3.2.1): single tap arrives
  // as Enter, double-tap as Backspace, swipe as ArrowUp/ArrowDown.
  // The main flow - count the queue, mark served, switch queue,
  // hear the comparison - runs on these keys + head-steady + nod;
  // the on-screen buttons mirror the same actions for tapping.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: tap (Enter) = COUNT+ on ' + this._letter() });
      this.countTap();
    } else if (code === 'ArrowUp') {
      this._cycleQueue(1, 'swipe');
    } else if (code === 'ArrowDown') {
      this._cycleQueue(-1, 'swipe');
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: double-tap (Backspace) back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- state ----------

  _newQueue() {
    // served: tick-elapsed seconds of each SERVED mark (rate input).
    // note: the wearer's own dictated words - display only, it is
    // NEVER an input to the estimate math.
    return { people: 0, served: [], base: 0, note: '', noteSrc: '', photoBytes: 0, photoTime: '' };
  },

  _q() { return this._queues[this._active || 0]; },

  _letter(i) { return this._letters[i === undefined ? (this._active || 0) : i]; },

  // Elapsed seconds tick up once per second from a timer. Every
  // duration in this agent is a difference of tick counts, so the
  // preview host's drifting virtual clock cannot distort a rate
  // (same discipline as #38/#42). Wall-clock strings come from ONE
  // Date snapshot per event (see _stamp).
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () { self._elapsed += 1; }, 1000);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  _stamp() {
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      time: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
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

  // ---------- rate + estimate math (the measured side) ----------

  // Seconds per person, from the SERVED marks of one queue. Needs
  // at least 2 marks (1 interval) spanning more than one tick;
  // otherwise there is honestly no measured rate yet.
  _rate(q) {
    var s = q.served;
    if (!s || s.length < 2) return null;
    var span = s[s.length - 1] - s[0];
    if (span <= 0) return null;
    return span / (s.length - 1);
  },

  _estSec(q) {
    var r = this._rate(q);
    if (r === null || q.people <= 0) return null;
    return q.people * r;
  },

  _minText(sec) {
    if (sec < 45) return '<1';
    return String(Math.round(sec / 60));
  },

  _estText(sec) {
    return '~' + this._minText(sec) + ' min (rough)';
  },

  // ---------- counting (the wearer's eyes, tapped in) ----------

  countTap() {
    if (this.data.busy) return;
    var q = this._q();
    q.people += 1;
    this.setData({
      status: 'COUNTED ' + q.people + ' AHEAD IN ' + this._letter() + ' - keep looking, keep tapping',
      lastEvent: 'EVT: COUNT+ ' + this._letter() + ' -> ' + q.people + ' people ahead (your count)'
    });
    this._renderAll();
  },

  undoTap() {
    if (this.data.busy) return;
    var q = this._q();
    if (q.people > 0) q.people -= 1;
    this.setData({
      status: 'COUNT FIXED - ' + q.people + ' AHEAD IN ' + this._letter(),
      lastEvent: 'EVT: UNDO ' + this._letter() + ' -> ' + q.people + ' (floor 0)'
    });
    this._renderAll();
  },

  // ---------- SERVED (rate samples) ----------

  servedTap() {
    if (this.data.busy) return;
    this._markServed();
  },

  _markServed() {
    var q = this._q();
    q.served.push(this._elapsed);
    var r = this._rate(q);
    this.setData({
      status: r === null
        ? 'SERVED marked on ' + this._letter() + ' - one more mark gives a rate'
        : 'SERVED marked on ' + this._letter() + ' - rate updated',
      lastEvent: 'EVT: SERVED ' + this._letter() + ' at T+' + this._elapsed + 's (sample ' +
        q.served.length + ')'
    });
    this._renderAll();
  },

  // ---------- JOINED (you moved up: position only, not a rate sample) ----------

  joinedTap() {
    if (this.data.busy) return;
    var q = this._q();
    if (q.people > 0) q.people -= 1;
    // Re-base: your position changed at this tick. A JOINED mark is
    // NOT a served sample - the served array (the rate input) is
    // deliberately left untouched; only the base mark moves.
    q.base = this._elapsed;
    this.setData({
      status: 'MOVED UP IN ' + this._letter() + ' - ' + q.people + ' AHEAD NOW',
      lastEvent: 'EVT: JOINED ' + this._letter() + ' -> ' + q.people + ' ahead, re-based at T+' +
        this._elapsed + 's (not a rate sample)'
    });
    this._renderAll();
  },

  // ---------- queue switching ----------

  queueTap() { this._cycleQueue(1, 'button'); },

  _cycleQueue(dir, src) {
    this._active = (((this._active || 0) + dir) % 3 + 3) % 3;
    this.setData({
      status: 'ACTIVE QUEUE: ' + this._letter() + ' - count / served / note apply here',
      lastEvent: 'EVT: ' + src + ' -> active queue ' + this._letter()
    });
    this._renderAll();
  },

  // ---------- PHOTO (wide, session record only - NEVER used for counting) ----------

  async photoTap() {
    if (this.data.busy) return;
    var q = this._q();
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'PHOTO FAIL - no camera on this host (counting unaffected)',
        lastEvent: 'EVT: PHOTO FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'PHOTO (wide) of queue ' + this._letter() + '...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'wide' }), 9000, 'wide photo');
      var bytes = blob && blob.size ? blob.size : 0;
      var st = this._stamp();
      // Only the byte count + time are kept; the Blob itself is
      // dropped here and never written anywhere (same posture as
      // #44). The photo is a memory of the queue, never an input.
      q.photoBytes = bytes;
      q.photoTime = st.time;
      this.setData({
        status: 'PHOTO kept as session record for ' + this._letter() + ' - NOT counted from',
        lastEvent: 'EVT: wide photo ' + bytes + 'B for ' + this._letter() +
          ' (record only - people are counted by YOUR taps)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        var st2 = this._stamp();
        q.photoBytes = size;
        q.photoTime = st2.time;
        this.setData({
          status: 'PHOTO (wx) kept as session record for ' + this._letter() + ' - NOT counted from',
          lastEvent: 'EVT: wx photo ' + size + 'B for ' + this._letter() + ' (record only)'
        });
      } catch (e3) {
        this.setData({
          status: 'PHOTO FAIL - ' + this._err(firstErr) + ' (counting unaffected)',
          lastEvent: 'EVT: PHOTO FAIL - ' + this._err(firstErr)
        });
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
      this._renderAll();
    }
  },

  // ---------- DICT (your note, verbatim - never feeds the estimate) ----------

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  dictTap() {
    if (this.data.busy) return;
    if (this._demo) {
      var q = this._q();
      q.note = '班车每 12 分钟一班';
      q.noteSrc = 'DEMO';
      this.setData({
        status: 'NOTE (DEMO) set for ' + this._letter() + ' - your words only, math untouched',
        lastEvent: 'EVT: DEMO note seeded for ' + this._letter()
      });
      this._renderAll();
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host - the note is left
      // exactly as it was, never filled with invented text.
      this.setData({
        status: 'DICT SKIP - no recogniser on this host; note unchanged',
        lastEvent: 'EVT: DICT skipped honestly (ASR n/a)'
      });
      return;
    }
    this._dictListen();
  },

  async _dictListen() {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (same documented pattern
    // as #21/#41): open the wearer-mode stream, read back settings,
    // stop every track at once. The check stream is NOT the
    // recognition input and does not shape what recognition hears -
    // the host SpeechRecognition below listens on its own mic
    // (dossier sections 2.4 / 2.8). Result lives on its own
    // MIC CHECK line; the listening line says (host ASR).
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
          var q = self._q();
          // Stored VERBATIM as your note. It is displayed under
          // YOUR NOTE and is never parsed, never fed to the rate
          // or the estimate (harness-asserted).
          q.note = txt;
          q.noteSrc = 'ASR';
          self.setData({
            status: 'NOTE saved verbatim for ' + self._letter() + ' - estimate math untouched',
            lastEvent: 'EVT: note dictated (' + micNote + ') - verbatim, words only'
          });
          self._renderAll();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'DICT FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + ', tap DICT again',
          lastEvent: 'EVT: DICT ASR error - note unchanged'
        });
      };
      rec.onend = function () {
        if (self._dictRec === rec) self._dictRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'DICT listening (host ASR) - say the posted headway / note',
        lastEvent: 'EVT: DICT listening (host ASR), ' + micNote
      });
      this._renderAll();
    } catch (e) {
      this.setData({
        busy: false,
        status: 'DICT FAIL - recogniser would not start; note unchanged',
        lastEvent: 'EVT: DICT start failed - ' + this._err(e)
      });
    }
  },

  // ---------- COMPARE + SPEAK ----------

  // The verdict: among queues with people ahead AND a measured
  // rate, the smallest rounded-minute estimate wins; a tie on
  // rounded minutes goes to fewer people, then to the earlier
  // letter. Queues with people but no rate are named as missing
  // data - never silently ranked, never guessed.
  _compare() {
    var rows = [];
    var missing = [];
    var any = false;
    for (var i = 0; i !== 3; i++) {
      var q = this._queues[i];
      if (q.people <= 0) continue;
      any = true;
      var est = this._estSec(q);
      if (est === null) { missing.push(i); continue; }
      rows.push({ i: i, people: q.people, est: est, mins: Math.round(est / 60) });
    }
    var best = null;
    for (var j = 0; j !== rows.length; j++) {
      var r = rows[j];
      if (!best || r.mins < best.mins ||
        (r.mins === best.mins && (r.people < best.people ||
          (r.people === best.people && r.i < best.i)))) {
        best = r;
      }
    }
    return { rows: rows, missing: missing, best: best, any: any };
  },

  _compareSpeech(c) {
    if (!c.any) {
      return '还没有开始数任何一队。先看着队伍，前面一个人点一次计数。';
    }
    var parts = [];
    for (var k = 0; k !== c.rows.length; k++) {
      var r = c.rows[k];
      parts.push(this._letter(r.i) + ' 队前面 ' + r.people + ' 人，约 ' + this._minText(r.est) + ' 分钟');
    }
    var text = parts.length ? parts.join('；') + '。' : '';
    if (c.best) {
      text += this._letter(c.best.i) + ' 队最快，约 ' + this._minText(c.best.est) + ' 分钟。';
    } else if (c.missing.length) {
      text += '还没有哪一队测到服务速度 - 前面的人被服务完时，点一次已服务。';
    }
    for (var m = 0; m !== c.missing.length; m++) {
      text += this._letter(c.missing[m]) + ' 队数据不足，还没有测到速度。';
    }
    return text;
  },

  _cmpLine(c) {
    if (!c.any) return 'BEST: - (no queue counted yet)';
    var seg = [];
    if (c.best) seg.push('BEST: ' + this._letter(c.best.i) + ' ~' + this._minText(c.best.est) + ' min');
    for (var k = 0; k !== c.rows.length; k++) {
      var r = c.rows[k];
      if (c.best && r.i === c.best.i) continue;
      seg.push(this._letter(r.i) + ' ~' + this._minText(r.est) + ' min');
    }
    for (var m = 0; m !== c.missing.length; m++) {
      seg.push(this._letter(c.missing[m]) + ': no rate yet');
    }
    return seg.join(' · ');
  },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  speakTap() {
    if (this.data.busy) return;
    var c = this._compare();
    var text = this._compareSpeech(c);
    var ok = this._speak(text);
    this.setData({
      cmpLine: this._cmpLine(c),
      status: ok ? 'COMPARE spoken - verdict above' : 'COMPARE above (TTS n/a on this host)',
      lastEvent: ok ? 'EVT: TTS compare sent: ' + text : 'EVT: SPEAK FAIL - speechSynthesis n/a here'
    });
  },

  // ---------- DEMO (seeded queues, memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoSaved = {
        queues: this._queues, active: this._active, elapsed: this._elapsed
      };
      this._demo = true;
      this._queues = [this._newQueue(), this._newQueue(), this._newQueue()];
      // A: 12 ahead, served marks at T+0/40/85 -> intervals 40+45,
      // rate 42.5 s/person, est 510 s (~9 min).
      this._queues[0].people = 12;
      this._queues[0].served = [0, 40, 85];
      this._queues[0].note = '每 10 分钟一班';
      this._queues[0].noteSrc = 'DEMO';
      // B: 8 ahead, marks at T+10/40 -> rate 30 s/person, est ~4 min.
      this._queues[1].people = 8;
      this._queues[1].served = [10, 40];
      this._active = 0;
      // Continue the tick clock past the last seeded mark, so any
      // further SERVED mark appends a sane (positive) interval.
      this._elapsed = 90;
      this.setData({
        status: 'DEMO - A 12 ppl measured, B 8 ppl measured; SPEAK compares',
        lastEvent: 'EVT: DEMO on - seeded A/B with real rate math (memory only)'
      });
    } else {
      var saved = this._demoSaved;
      this._demo = false;
      this._demoSaved = null;
      if (saved) {
        this._queues = saved.queues;
        this._active = saved.active;
        this._elapsed = saved.elapsed;
      }
      this.setData({
        status: 'DEMO OFF - your real queues are back',
        lastEvent: 'EVT: DEMO cleared - real session restored, nothing was written'
      });
    }
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var q = this._q();
    var L = this._letter();
    var r = this._rate(q);
    var est = this._estSec(q);
    var patch = {
      queueLine: 'ACTIVE: ' + L + ' · swipe / QUEUE cycles A-B-C',
      peopleLine: L + ' · PEOPLE AHEAD: ' + q.people
    };
    if (r !== null) {
      patch.rateLine = 'RATE (' + L + '): ~' + Math.round(r) + ' s/person · from ' +
        q.served.length + ' served (' + (q.served.length - 1) + ' intervals)';
    } else if (q.served.length >= 2) {
      patch.rateLine = 'RATE (' + L + '): marks landed in one tick - keep watching';
    } else if (q.served.length === 1) {
      patch.rateLine = 'RATE (' + L + '): 1 served marked - one more gives a rate';
    } else {
      patch.rateLine = 'RATE (' + L + '): not measured yet - counting only';
    }
    if (est !== null) {
      patch.estLine = 'EST (' + L + '): ' + this._estText(est) + ' · MEASURED';
    } else if (q.people <= 0) {
      patch.estLine = 'EST (' + L + '): nobody ahead - you are at the front';
    } else {
      patch.estLine = 'EST (' + L + '): - (no measured rate yet)';
    }
    var all = [];
    for (var i = 0; i !== 3; i++) {
      var qi = this._queues[i];
      var ei = this._estSec(qi);
      var seg = this._letter(i) + ': ' + qi.people + ' ppl';
      if (ei !== null) seg += ' ~' + this._minText(ei) + ' min';
      else if (qi.people > 0) seg += ', no rate';
      all.push(seg);
    }
    patch.allLine = all.join(' · ');
    // The BEST line is recomputed from live state on every render,
    // so it can never show a verdict for queues that no longer
    // exist (e.g. DEMO seeds after DEMO is switched off).
    var cmp = this._compare();
    patch.cmpLine = cmp.any ? this._cmpLine(cmp) : 'BEST: - (SPEAK compares the three queues)';
    patch.noteLine = 'YOUR NOTE (' + L + '): ' + (q.note
      ? q.note.slice(0, 42) + (q.noteSrc ? ' (' + q.noteSrc + ')' : '')
      : '- (DICT a posted headway; your words)');
    patch.photoLine = q.photoBytes
      ? 'PHOTO (' + L + '): ' + q.photoBytes + 'B wide · ' + q.photoTime + ' · record only'
      : 'PHOTO (' + L + '): none - session record only, never saved';
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">QUEUE SENSE</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">◎ MEASURED - your counts + the real service rate</text>
      <text class="photo">{{queueLine}}</text>
      <text class="people">{{peopleLine}}</text>
      <text class="photo">{{rateLine}}</text>
      <text class="est">{{estLine}}</text>
      <text class="photo">{{allLine}}</text>
      <text class="photo">{{cmpLine}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">◎ YOURS - note + photo record (never counted from)</text>
      <text class="photo">{{noteLine}}</text>
      <text class="photo">{{photoLine}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="countTap">COUNT+</button>
      <button class="btn" bindtap="undoTap">UNDO</button>
      <button class="btn btn-main" bindtap="servedTap">SERVED</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="queueTap">QUEUE</button>
      <button class="btn" bindtap="joinedTap">JOINED</button>
      <button class="btn" bindtap="photoTap">PHOTO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="sub">photos NOT saved · photos NEVER used for counting · session only</text>
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
.people {
  color: #40ff5e;
  font-size: 16px;
  font-weight: 500;
  line-height: 20px;
  margin-top: 2px;
}
.est {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
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
