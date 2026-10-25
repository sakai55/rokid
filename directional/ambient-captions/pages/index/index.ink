<script def>
{
  "navigationBarTitleText": "Ambient Captions"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'Tap START - captions for the person facing you',
    steadyText: 'HEAD: moving - hold still',
    micLine: 'MIC: idle · near-field check on START',
    guideLine: 'Face the speaker - captions sit under their face',
    capOld2: ' ',
    capOld1: ' ',
    capLatest: 'No captions yet - START, then face the speaker',
    capMeta: 'CAPTIONS: 0 · memory only, never saved',
    honestLine: 'ASR aid, not a transcript - errors happen',
    lastEvent: 'EVT: captions may err, esp. names / numbers',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._captions = []; // {time:'HH:MM', text} - memory only, max 30
    this._listening = false;
    this._round = 0;
    this._quietErrs = 0;
    this._errStreak = 0;
    this._fatalError = null;
    this._micLabel = 'not run';
    this._recog = null;
    this._roundTimer = null;
    this._demo = false;
    this._demoTimers = [];
    this._recompute();
  },

  onShow() {},

  onHide() {
    this._stopLoop();
    this._stopDemo();
  },

  onUnload() {
    this._stopLoop();
    this._stopDemo();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - nod = REPEAT' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') return;
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this.repeatTap();
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._listening || this._demo) this.stopTap(); else this.startTap();
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

  _pad2(n) {
    return (n < 10 ? '0' : '') + n;
  },

  _timeNow() {
    var d = new Date();
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
  },

  // ---------- caption stack (one path for real ASR and DEMO) ----------

  // Captions live in memory only (max 30, oldest dropped). A
  // conversation is not a recording: nothing is persisted, nothing
  // is uploaded, and CLEAR wipes the stack for good.
  _addCaption(txt, isDemo) {
    txt = String(txt || '').trim();
    if (!txt) return false;
    this._captions.push({ time: this._timeNow(), text: txt, demo: !!isDemo });
    if (this._captions.length > 30) this._captions.shift();
    this._recompute();
    return true;
  },

  _latestCaption() {
    return this._captions.length ? this._captions[this._captions.length - 1] : null;
  },

  // ---------- START (near-field check + recognition round loop) ----------

  async startTap() {
    if (this._listening || this._demo) {
      this.setData({ lastEvent: 'EVT: already on - tap STOP to end' });
      return;
    }
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // No recogniser on this host: say so, never fake captions.
      this.setData({
        status: 'START FAIL: SpeechRecognition n/a here',
        lastEvent: 'EVT: captions unavailable (honest SKIP)'
      });
      return;
    }
    this.setData({ busy: true, status: 'START: checking near-field mic...' });
    // Near-field availability check (documented getUserMedia audio
    // constraints, same pattern as far-ear / name-call): the person
    // you are talking with sits 1-2 m away - per the media docs
    // that is a NEARBY sound source, so 'near-field' is the mode
    // whose documented purpose matches this conversation distance.
    // The check only verifies that mode exists on this device: the
    // stream is stopped at once and is NOT the recognition input.
    // The caption rounds use the host SpeechRecognition, which
    // listens on its own microphone - no mic mode chosen here
    // shapes what the recogniser hears.
    var micLabel = 'check n/a';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      var stream = null;
      try {
        try {
          stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
            audio: { captureSource: 'microphone', microphoneMode: 'near-field', echoCancellation: true }
          }), 6000, 'mic');
          micLabel = 'near-field';
          try {
            var tr = stream.getAudioTracks()[0];
            if (tr && tr.getSettings && tr.getSettings().microphoneMode) {
              micLabel = tr.getSettings().microphoneMode;
            }
          } catch (e) {}
        } catch (eMode) {
          if (!eMode || eMode.name !== 'OverconstrainedError') throw eMode;
          stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 6000, 'mic');
          micLabel = 'default mic';
        }
      } catch (e) {
        micLabel = 'check FAIL';
      }
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
    }
    this._micLabel = micLabel;
    this._listening = true;
    this._round = 0;
    this._quietErrs = 0;
    this._errStreak = 0;
    this._fatalError = null;
    this.setData({
      busy: false,
      status: 'CAPTIONING - face the speaker, one at a time',
      lastEvent: 'EVT: captions live · mic check ' + micLabel + ' · host ASR rounds on'
    });
    this._startRound();
    this._recompute();
  },

  _startRound() {
    if (!this._listening) return;
    var self = this;
    var rec;
    try {
      rec = new SpeechRecognition();
    } catch (e) {
      this._listening = false;
      this.setData({
        status: 'STOPPED: recogniser ' + this._err(e),
        lastEvent: 'EVT: captions stopped - recogniser failed'
      });
      this._recompute();
      return;
    }
    this._recog = rec;
    this._round++;
    rec.lang = 'zh-CN';
    rec.interimResults = false;
    rec.onresult = function (ev) {
      try {
        var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
        if (!txt) return;
        self._errStreak = 0;
        self._addCaption(txt, false);
        self.setData({ lastEvent: 'EVT: caption ' + self._captions.length + ' in - kept in memory only' });
      } catch (e) {}
    };
    rec.onerror = function (ev) {
      if (!self._listening) return; // our own abort on STOP
      var err = (ev && ev.error) || 'error';
      // no-speech is the normal sound of a pause in conversation:
      // count it quietly. Persistent errors stop the loop with the
      // reason on screen instead of spinning forever.
      if (err === 'not-allowed' || err === 'service-not-allowed' ||
          err === 'audio-capture' || err === 'language-not-supported') {
        self._fatalError = err;
      } else {
        self._quietErrs++;
        self._errStreak++;
        if (self._errStreak >= 5) self._fatalError = err + ' x5';
      }
    };
    rec.onend = function () {
      if (self._recog === rec) self._recog = null;
      if (!self._listening) return;
      if (self._fatalError) {
        var reason = self._fatalError;
        self._fatalError = null;
        self._listening = false;
        self.setData({
          status: 'STOPPED: ' + reason,
          lastEvent: 'EVT: captions stopped - persistent ASR error: ' + reason
        });
        self._recompute();
        return;
      }
      self._recompute();
      self._roundTimer = setTimeout(function () {
        self._roundTimer = null;
        self._startRound();
      }, 250);
    };
    try {
      rec.start();
    } catch (e) {
      this._recog = null;
      this._listening = false;
      this.setData({
        status: 'STOPPED: start ' + this._err(e),
        lastEvent: 'EVT: captions stopped - ASR start failed'
      });
      this._recompute();
      return;
    }
    this._recompute();
  },

  // Stops the round loop and aborts the current recogniser.
  _stopLoop() {
    this._listening = false;
    this._fatalError = null;
    if (this._roundTimer) { clearTimeout(this._roundTimer); this._roundTimer = null; }
    if (this._recog) {
      try { this._recog.abort(); } catch (e) {}
      this._recog = null;
    }
  },

  stopTap() {
    if (this._demo) {
      this._stopDemo();
      this.setData({
        status: 'DEMO stopped - START or DEMO again',
        lastEvent: 'EVT: demo stopped early'
      });
      this._recompute();
      return;
    }
    if (!this._listening) {
      this.setData({ lastEvent: 'EVT: nothing on - START or DEMO first' });
      return;
    }
    this._stopLoop();
    this.setData({
      status: 'Stopped - captions stay on screen, in memory',
      lastEvent: 'EVT: captions stopped - recogniser aborted'
    });
    this._recompute();
  },

  // ---------- REPEAT (TTS re-speaks the latest caption) ----------

  repeatTap() {
    var latest = this._latestCaption();
    var text = latest ? latest.text : '还没有字幕。请先点开始，面对说话的人。';
    var sent = false;
    try {
      if (typeof speechSynthesis !== 'undefined' && typeof SpeechSynthesisUtterance !== 'undefined') {
        speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
        sent = true;
      }
    } catch (e) {}
    this.setData({
      lastEvent: latest
        ? 'EVT: REPEAT ' + (sent ? 'spoke latest caption' : 'FAIL - TTS n/a here')
        : 'EVT: REPEAT - no caption yet, spoke the hint'
    });
  },

  // ---------- DEMO (three synthetic lines through the real stack path) ----------

  // DEMO feeds three fake sentences through the SAME _addCaption
  // the recogniser uses, so the rolling stack, the times and the
  // REPEAT behaviour in preview are the real code path.
  demoTap() {
    if (this._listening || this._demo) {
      this.setData({ lastEvent: 'EVT: busy - tap STOP first' });
      return;
    }
    var self = this;
    var lines = ['你好，今天过得怎么样', '我刚从超市回来', '晚上我们吃火锅吧'];
    this._demo = true;
    this.setData({
      status: 'DEMO - 3 sample lines, no mic used',
      lastEvent: 'EVT: DEMO on - synthetic captions via the real stack'
    });
    this._recompute();
    lines.forEach(function (line, i) {
      self._demoTimers.push(setTimeout(function () {
        self._addCaption(line, true);
        self.setData({ lastEvent: 'EVT: DEMO caption ' + (i + 1) + '/3 in' });
        if (i === lines.length - 1) {
          self._demo = false;
          self._demoTimers = [];
          self.setData({ status: 'DEMO done - latest line big, REPEAT it' });
          self._recompute();
        }
      }, 1100 * (i + 1)));
    });
  },

  _stopDemo() {
    for (var i = 0; i !== this._demoTimers.length; i++) clearTimeout(this._demoTimers[i]);
    this._demoTimers = [];
    this._demo = false;
  },

  clearTap() {
    this._captions = [];
    this.setData({
      status: 'Captions cleared - they were never saved',
      lastEvent: 'EVT: caption stack wiped (memory only, as designed)'
    });
    this._recompute();
  },

  // ---------- render ----------

  _recompute() {
    var patch = {};
    var caps = this._captions || [];
    var n = caps.length;
    if (this._demo) {
      patch.micLine = 'MIC: DEMO · synthetic lines, no mic used';
    } else if (this._listening) {
      patch.micLine = 'MIC CHECK: ' + this._micLabel + ' · round ' + this._round + ' · listening (host ASR)';
    } else {
      patch.micLine = 'MIC: idle · rounds ' + this._round + ' · near-field check on START';
    }
    patch.guideLine = 'Face the speaker - captions sit under their face';
    var latest = n ? caps[n - 1] : null;
    var prev1 = n > 1 ? caps[n - 2] : null;
    var prev2 = n > 2 ? caps[n - 3] : null;
    patch.capOld2 = prev2 ? prev2.time + ' ' + prev2.text.slice(0, 26) : ' ';
    patch.capOld1 = prev1 ? prev1.time + ' ' + prev1.text.slice(0, 26) : ' ';
    patch.capLatest = latest ? latest.text.slice(0, 34) : 'No captions yet - START, then face the speaker';
    patch.capMeta = latest
      ? 'LATEST ' + latest.time + (latest.demo ? ' · DEMO' : '') + ' · CAPTIONS: ' + n + '/30 · memory only'
      : 'CAPTIONS: 0 · memory only, never saved';
    patch.honestLine = 'ASR aid, not a transcript - errors happen';
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">AMBIENT CAPTIONS</text>
      <text class="status">{{status}}</text>
      <text class="status">{{steadyText}}</text>
    </view>
    <view class="box">
      <text class="watch">{{guideLine}}</text>
      <text class="level">{{micLine}}</text>
      <text class="note">{{honestLine}}</text>
    </view>
    <view class="cap-box">
      <text class="cap-old">{{capOld2}}</text>
      <text class="cap-old">{{capOld1}}</text>
      <text class="cap-latest">{{capLatest}}</text>
      <text class="cap-meta">{{capMeta}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn" bindtap="stopTap">STOP</button>
      <button class="btn" bindtap="repeatTap">REPEAT</button>
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
  padding: 8px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.watch {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.level {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.note {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.cap-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 10px;
  margin-bottom: 4px;
}
.cap-old {
  color: rgba(64,255,94,0.48);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.cap-latest {
  color: #40ff5e;
  font-size: 16px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 2px;
}
.cap-meta {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
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
  padding: 4px;
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
  line-height: 14px;
  margin-top: 1px;
}
</style>
