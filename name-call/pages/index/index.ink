<script def>
{
  "navigationBarTitleText": "Name Call"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'Tap WATCH - glasses listen for your name',
    alertLine: 'NO CALL - nobody called you yet',
    alertCls: 'alert',
    nameLine: 'NAME: 五郎 · preset',
    watchLine: 'WATCH: idle · rounds 0',
    heardLine: 'heard: --- (each round shows here)',
    honestLine: 'ASR keyword watch - NOT voiceprint',
    logHead: 'CALL LOG (matched only): 0/20',
    log1: 'No calls logged today',
    log2: ' ',
    log3: ' ',
    lastEvent: 'EVT: may miss / false-fire in noise',
    busy: false
  },

  onLoad() {
    this._presets = ['五郎', '小明', '小红', '老王'];
    this._presetIndex = 0;
    this._target = '五郎';
    this._targetCustom = false;
    this._watching = false;
    this._round = 0;
    this._heardCount = 0;
    this._quietErrs = 0;
    this._errStreak = 0;
    this._fatalError = null;
    this._micLabel = 'far-field';
    this._recog = null;
    this._setRec = null;
    this._setting = false;
    this._roundTimer = null;
    this._demo = false;
    this._demoTimers = [];
    this._lastHeard = '';
    this._logEntries = [];
    this._loadTarget();
    this._loadLog();
    this._recompute();
  },

  onShow() {},

  onHide() {
    this._stopWatchLoop();
    this._stopDemo();
    this._stopSetRec();
  },

  onUnload() {
    this._stopWatchLoop();
    this._stopDemo();
    this._stopSetRec();
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._watching || this._demo) this.stopTap(); else this.watchTap();
    } else if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.nameTap();
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

  _todayKey() {
    var d = new Date();
    return d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate());
  },

  _timeNow() {
    var d = new Date();
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes()) + ':' + this._pad2(d.getSeconds());
  },

  // ---------- target name (wx storage: nameCallTarget) ----------

  _loadTarget() {
    try {
      var raw = wx.getStorageSync('nameCallTarget');
      if (typeof raw === 'string' && raw.trim()) {
        this._target = raw.trim();
        var idx = this._presets.indexOf(this._target);
        if (idx >= 0) {
          this._presetIndex = idx;
          this._targetCustom = false;
        } else {
          this._targetCustom = true;
        }
      }
    } catch (e) {
      // No stored name yet - keep the default preset.
    }
  },

  _saveTarget() {
    try {
      wx.setStorageSync('nameCallTarget', this._target);
    } catch (e) {
      // The in-memory target still works for this page session.
    }
  },

  _setTarget(name, custom) {
    this._target = name;
    this._targetCustom = !!custom;
    if (!custom) {
      var idx = this._presets.indexOf(name);
      if (idx >= 0) this._presetIndex = idx;
    }
    this._saveTarget();
  },

  // ---------- call log (wx storage: matched calls only) ----------

  _loadLog() {
    var out = [];
    try {
      var raw = wx.getStorageSync('nameCallLog');
      if (Array.isArray(raw)) {
        var today = this._todayKey();
        for (var i = 0; i !== raw.length; i++) {
          var item = raw[i];
          if (item && typeof item.time === 'string' && typeof item.text === 'string') {
            var entry = { date: item.date || today, time: item.time, text: item.text, demo: !!item.demo };
            if (entry.date === today) out.push(entry);
          }
          if (out.length >= 20) break;
        }
      }
    } catch (e) {
      this.setData({ lastEvent: 'EVT: storage n/a - log stays in memory' });
    }
    this._logEntries = out;
  },

  _saveLog() {
    try {
      wx.setStorageSync('nameCallLog', this._logEntries || []);
    } catch (e) {
      // The in-memory list still works for this page session.
    }
  },

  // ---------- matching (one path for real ASR and DEMO) ----------

  // Substring match on the recognised text. This is ASR keyword
  // spotting, NOT a voiceprint: any voice can match, a similar
  // sounding word can false-fire, and a misrecognised name misses.
  _matches(text, target) {
    if (!text || !target) return false;
    var t = String(target).trim();
    if (!t) return false;
    return String(text).indexOf(t) !== -1;
  },

  _handleTranscript(txt, isDemo) {
    txt = String(txt || '').trim();
    if (!txt) return false;
    this._lastHeard = txt;
    this._heardCount++;
    if (this._matches(txt, this._target)) {
      this._fireAlert(txt, isDemo);
      return true;
    }
    this.setData({
      alertCls: 'alert',
      heardLine: 'heard: ' + txt.slice(0, 34),
      lastEvent: 'EVT: heard, no "' + this._target + '" in it - not stored'
    });
    this._recompute();
    return false;
  },

  _fireAlert(txt, isDemo) {
    var entry = { date: this._todayKey(), time: this._timeNow(), text: txt, demo: !!isDemo };
    this._logEntries.unshift(entry);
    if (this._logEntries.length > 20) this._logEntries.length = 20;
    this._saveLog();
    var sent = this._speakAlert();
    this.setData({
      status: isDemo ? 'DEMO ALERT - your name was called' : 'YOUR NAME - someone is calling you',
      alertLine: '有人喊你: ' + txt.slice(0, 30),
      alertCls: 'alert alert-on',
      heardLine: 'heard: ' + txt.slice(0, 34),
      lastEvent: 'EVT: call ' + entry.time + (entry.demo ? ' DEMO' : '') + (sent ? ' · TTS sent' : ' · TTS n/a')
    });
    this._recompute();
  },

  _speakAlert() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance('有人喊你'), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  // ---------- NAME / SET ----------

  nameTap() {
    if (this._setting) {
      this.setData({ lastEvent: 'EVT: SET is listening - finish it first' });
      return;
    }
    this._presetIndex = (this._presetIndex + 1) % this._presets.length;
    this._setTarget(this._presets[this._presetIndex], false);
    this.setData({
      status: 'NAME set - WATCH listens for "' + this._target + '"',
      lastEvent: 'EVT: target name = ' + this._target + ' (preset)'
    });
    this._recompute();
  },

  setTap() {
    var self = this;
    if (this._watching || this._demo) {
      this.setData({ lastEvent: 'EVT: busy - tap STOP first' });
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'SET SKIP - SpeechRecognition n/a here',
        heardLine: 'HEARD: SKIP - ASR n/a on this host',
        lastEvent: 'EVT: SET unavailable (honest SKIP)'
      });
      return;
    }
    try {
      this._stopSetRec();
      var rec = new SpeechRecognition();
      this._setRec = rec;
      this._setting = true;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // The heard string becomes the target VERBATIM. If the ASR
          // misheard you, you see it here and can tap SET and redo -
          // the agent never silently "corrects" your name.
          self._setTarget(txt, true);
          self.setData({
            status: 'NAME heard as "' + txt.slice(0, 16) + '" - redo if wrong',
            heardLine: 'heard: ' + txt.slice(0, 34),
            lastEvent: 'EVT: custom name set (verbatim, as heard)'
          });
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'SET FAIL - ' + self._err(ev.error || ev),
          lastEvent: 'EVT: SET error - name unchanged'
        });
      };
      rec.onend = function () {
        if (self._setRec === rec) self._setRec = null;
        self._setting = false;
      };
      rec.start();
      this.setData({
        status: 'SET: say YOUR name once, close and clear',
        heardLine: 'heard: listening for your name...',
        lastEvent: 'EVT: SET listening (one shot, wearer range)'
      });
    } catch (e) {
      this._setting = false;
      this.setData({
        status: 'SET FAIL - ' + this._err(e),
        lastEvent: 'EVT: SET start failed'
      });
    }
  },

  _stopSetRec() {
    if (this._setRec) {
      try { this._setRec.abort(); } catch (e) {}
      this._setRec = null;
    }
    this._setting = false;
  },

  // ---------- WATCH (far-field check + recognition round loop) ----------

  async watchTap() {
    if (this._watching || this._demo) {
      this.setData({ lastEvent: 'EVT: already on - tap STOP to end' });
      return;
    }
    if (this._setting || this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // No recogniser on this host: say so, never fake listening.
      this.setData({
        status: 'WATCH FAIL: SpeechRecognition n/a here',
        heardLine: 'HEARD: SKIP - ASR n/a on this host',
        lastEvent: 'EVT: WATCH unavailable (honest SKIP)'
      });
      return;
    }
    this.setData({ busy: true, status: 'WATCH: checking far-field mic...' });
    // Far-field availability check (documented getUserMedia audio
    // constraints, same pattern as cook-along / far-ear): far-field
    // mode aims the 4-mic array at the room, not at the wearer.
    // The stream only verifies the mode; it is stopped at once and
    // the recognition rounds use the benchmark SpeechRecognition.
    var micLabel = 'check n/a';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      var stream = null;
      try {
        try {
          stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
            audio: { captureSource: 'microphone', microphoneMode: 'far-field', echoCancellation: true }
          }), 6000, 'mic');
          micLabel = 'far-field';
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
    this._watching = true;
    this._round = 0;
    this._heardCount = 0;
    this._quietErrs = 0;
    this._errStreak = 0;
    this._fatalError = null;
    this.setData({
      busy: false,
      status: 'WATCHING for "' + this._target + '" - rounds run back to back',
      lastEvent: 'EVT: watch live · mic ' + micLabel + ' · ASR rounds on'
    });
    this._startRound();
    this._recompute();
  },

  _startRound() {
    if (!this._watching) return;
    var self = this;
    var rec;
    try {
      rec = new SpeechRecognition();
    } catch (e) {
      this._watching = false;
      this.setData({
        status: 'WATCH STOPPED: recogniser ' + this._err(e),
        lastEvent: 'EVT: WATCH stopped - recogniser failed'
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
        self._handleTranscript(txt, false);
      } catch (e) {}
    };
    rec.onerror = function (ev) {
      if (!self._watching) return; // our own abort on STOP
      var err = (ev && ev.error) || 'error';
      // no-speech is the normal sound of a quiet room: count it
      // quietly. Persistent errors stop the loop with the reason
      // on screen instead of spinning forever.
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
      if (!self._watching) return;
      if (self._fatalError) {
        var reason = self._fatalError;
        self._fatalError = null;
        self._watching = false;
        self.setData({
          status: 'WATCH STOPPED: ' + reason,
          lastEvent: 'EVT: WATCH stopped - persistent ASR error: ' + reason
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
      this._watching = false;
      this.setData({
        status: 'WATCH STOPPED: start ' + this._err(e),
        lastEvent: 'EVT: WATCH stopped - ASR start failed'
      });
      this._recompute();
      return;
    }
    this._recompute();
  },

  // Stops the round loop and aborts the current recogniser.
  _stopWatchLoop() {
    this._watching = false;
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
        status: 'DEMO stopped - WATCH or DEMO again',
        lastEvent: 'EVT: demo stopped early'
      });
      this._recompute();
      return;
    }
    if (this._setting) {
      this._stopSetRec();
      this.setData({
        status: 'SET cancelled - name unchanged',
        lastEvent: 'EVT: SET aborted'
      });
      this._recompute();
      return;
    }
    if (!this._watching) {
      this.setData({ lastEvent: 'EVT: nothing on - WATCH or DEMO first' });
      return;
    }
    this._stopWatchLoop();
    this.setData({
      status: 'Stopped - tap WATCH to listen again',
      lastEvent: 'EVT: watch stopped - recogniser aborted'
    });
    this._recompute();
  },

  // ---------- DEMO (two synthetic rounds through the real match path) ----------

  // DEMO feeds two fake transcripts through the SAME
  // _handleTranscript the recogniser uses: round 1 has no name in
  // it, round 2 is "<your name>，你的快递到了" and fires the alert.
  demoTap() {
    if (this._watching || this._demo || this._setting) {
      this.setData({ lastEvent: 'EVT: busy - tap STOP first' });
      return;
    }
    var self = this;
    this._demo = true;
    this.setData({
      status: 'DEMO round 1: small talk, no name in it',
      lastEvent: 'EVT: DEMO on - synthetic rounds, no mic used'
    });
    this._recompute();
    this._demoTimers.push(setTimeout(function () {
      self._round++;
      self._handleTranscript('今天中午吃什么', true);
      if (!self._demo) return;
      self.setData({ status: 'DEMO round 2: someone calls your name...' });
      self._recompute();
    }, 1300));
    this._demoTimers.push(setTimeout(function () {
      self._round++;
      self._handleTranscript(self._target + '，你的快递到了', true);
      self._demo = false;
      self._demoTimers = [];
      self.setData({ status: 'DEMO done - alert fired, call logged' });
      self._recompute();
    }, 2800));
  },

  _stopDemo() {
    for (var i = 0; i !== this._demoTimers.length; i++) clearTimeout(this._demoTimers[i]);
    this._demoTimers = [];
    this._demo = false;
  },

  clearTap() {
    this._logEntries = [];
    this._saveLog();
    this.setData({
      status: 'Call log cleared - matched calls only, ever',
      alertLine: 'NO CALL - nobody called you yet',
      alertCls: 'alert',
      lastEvent: 'EVT: nameCallLog cleared'
    });
    this._recompute();
  },

  // ---------- render ----------

  _recompute() {
    var patch = {};
    patch.nameLine = 'NAME: ' + this._target + (this._targetCustom ? ' · as you said it' : ' · preset');
    if (this._demo) {
      patch.watchLine = 'WATCH: DEMO · round ' + this._round + ' · synthetic';
    } else if (this._watching) {
      patch.watchLine = 'WATCH: listening · round ' + this._round + ' · ' + this._micLabel;
    } else if (this._setting) {
      patch.watchLine = 'WATCH: SET listening · say your name';
    } else {
      patch.watchLine = 'WATCH: idle · rounds ' + this._round;
    }
    patch.honestLine = 'ASR keyword watch - NOT voiceprint';
    var entries = this._logEntries || [];
    patch.logHead = 'CALL LOG (matched only): ' + entries.length + '/20';
    patch.log1 = entries.length ? entries[0].time + ' ' + entries[0].text.slice(0, 22) + (entries[0].demo ? ' DEMO' : '') : 'No calls logged today';
    patch.log2 = entries.length > 1 ? entries[1].time + ' ' + entries[1].text.slice(0, 22) + (entries[1].demo ? ' DEMO' : '') : ' ';
    patch.log3 = entries.length > 2 ? entries[2].time + ' ' + entries[2].text.slice(0, 22) + (entries[2].demo ? ' DEMO' : '') : ' ';
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">NAME CALL</text>
      <text class="status">{{status}}</text>
    </view>
    <view class="alert-box">
      <text class="{{alertCls}}">{{alertLine}}</text>
    </view>
    <view class="box">
      <text class="watch">{{nameLine}}</text>
      <text class="level">{{watchLine}}</text>
      <text class="rule">{{heardLine}}</text>
      <text class="note">{{honestLine}}</text>
    </view>
    <view class="box">
      <text class="log-head">{{logHead}}</text>
      <text class="log">{{log1}}</text>
      <text class="log">{{log2}}</text>
      <text class="log">{{log3}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nameTap">NAME</button>
      <button class="btn" bindtap="setTap">SET</button>
      <button class="btn" bindtap="watchTap">WATCH</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="stopTap">STOP</button>
      <button class="btn" bindtap="clearTap">CLEAR LOG</button>
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
.alert-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 10px;
  margin-bottom: 4px;
}
.alert {
  color: rgba(64,255,94,0.72);
  font-size: 14px;
  font-weight: 500;
  line-height: 18px;
}
.alert-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.16);
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
.rule {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.note {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.log-head {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.log {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
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
