<script def>
{
  "navigationBarTitleText": "Far Ear"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'Face the sound, tap LISTEN',
    headingLine: 'AIM: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    aimLine: 'Face the sound source - your head aims the array',
    micLine: 'MIC: idle - LISTEN opens the far-field mic',
    levelLine: 'LVL: ---------- 0',
    capLine: 'HEARD (far - may be wrong): ---',
    lastEvent: 'EVT: no live amplification - caption + near-ear repeat',
    busy: false
  },

  onLoad() {
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._sensor = null;
    this._steady = false;
    this._curLevel = 0;
    this._listening = false;
    this._levelTimer = null;
    this._stream = null;
    this._actx = null;
    this._analyser = null;
    this._srcNode = null;
    this._buf = null;
    this._recog = null;
    this._caption = null;      // last caption text (for REPEAT)
    this._captionDemo = false;
    this._demoTimer = null;
    this._demoStep = 0;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
  },

  onHide() {
    this._stopListen(true);
    this._stopDemo();
    this._stopRecog();
    this._stopHeading();
  },

  onUnload() {
    this._stopListen(true);
    this._stopDemo();
    this._stopRecog();
    this._stopHeading();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (this._caption) {
      if (this._steady) this.repeatTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to REPEAT' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._listening || this._demoTimer) this.stopTap(); else this.listenTap();
    } else if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.setData({ lastEvent: 'EVT: turn your head - the array aims where you face' });
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

  // ---------- heading (AbsoluteOrientationSensor, same as sound-compass) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._recompute();
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
        self._recompute();
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
    if (changed) this._recompute();
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  // ---------- LISTEN (far-field mic + live level) ----------

  async listenTap() {
    if (this._listening || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: already on - tap STOP to end' });
      return;
    }
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'LISTEN FAIL: mic n/a on this host',
        lastEvent: 'EVT: LISTEN FAIL - mediaDevices n/a'
      });
      return;
    }
    if (typeof AudioContext === 'undefined') {
      this.setData({
        status: 'LISTEN FAIL: Web Audio n/a on this host',
        lastEvent: 'EVT: LISTEN FAIL - AudioContext n/a'
      });
      return;
    }
    this.setData({ busy: true, status: 'LISTEN: opening mic (far-field)...' });
    var stream = null;
    var actx = null;
    var fellBack = false;
    try {
      try {
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'far-field', echoCancellation: true }
        }), 9000, 'mic');
      } catch (eMode) {
        // media.md: not every device supports every mode - fall back to
        // the default microphone and say so, do not fake the mode.
        if (!eMode || eMode.name !== 'OverconstrainedError') throw eMode;
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 9000, 'mic');
        fellBack = true;
      }
      this._stream = stream;
      actx = new AudioContext();
      this._actx = actx;
      await actx.resume();
      var src = actx.createMediaStreamSource(stream);
      var an = actx.createAnalyser();
      an.fftSize = 2048;
      src.connect(an); // analyser only - never to destination (feedback)
      this._srcNode = src;
      this._analyser = an;
      this._buf = new Float32Array(an.fftSize);
      // Read back what the device actually selected (media.md).
      var mode = '';
      try {
        var tr = stream.getAudioTracks()[0];
        if (tr && tr.getSettings) mode = tr.getSettings().microphoneMode || '';
      } catch (e) {}
      this._listening = true;
      var self = this;
      this._levelTimer = setInterval(function () { self._levelTick(); }, 100);
      this.setData({
        busy: false,
        status: 'LISTENING: face the source - watch the level',
        micLine: fellBack
          ? 'MIC: live (default - far-field n/a on device)'
          : 'MIC: live (' + (mode || 'far-field') + ') - aim with your head',
        lastEvent: fellBack
          ? 'EVT: far-field n/a - default mic used, said so'
          : 'EVT: far-field mic live - level shows your aim'
      });
      this._recompute();
    } catch (e) {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        this._stream = null;
      }
      if (actx) { try { await actx.close(); } catch (e3) {} this._actx = null; }
      this.setData({
        busy: false,
        status: 'LISTEN FAIL: ' + this._err(e),
        lastEvent: 'EVT: LISTEN FAIL - ' + this._err(e)
      });
    }
  },

  _levelTick() {
    if (!this._listening) return;
    var lvl = 0;
    if (this._analyser && this._buf) {
      this._analyser.getFloatTimeDomainData(this._buf);
      var sum = 0;
      for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
      lvl = Math.min(1, Math.sqrt(sum / this._buf.length) * 3);
    }
    this._curLevel = lvl;
    this._recompute();
  },

  stopTap() {
    if (this._demoTimer) {
      this._stopDemo();
      this._curLevel = 0;
      this.setData({
        status: 'DEMO stopped - LISTEN or DEMO again',
        lastEvent: 'EVT: demo level stopped early'
      });
      this._recompute();
      return;
    }
    if (this._recog) {
      this._stopRecog();
      this.setData({
        status: 'CAPTION stopped - LISTEN / CAPTION again',
        lastEvent: 'EVT: caption recognizer aborted'
      });
      return;
    }
    if (!this._listening) {
      this.setData({ lastEvent: 'EVT: nothing on - LISTEN or DEMO first' });
      return;
    }
    this._stopListen(false);
    this.setData({
      status: 'Stopped - CAPTION the speech, or LISTEN again',
      micLine: 'MIC: idle - LISTEN opens the far-field mic',
      lastEvent: 'EVT: mic stopped - tracks released'
    });
    this._recompute();
  },

  // Stops mic/context/timers; silent=true on hide/unload.
  _stopListen(silent) {
    if (this._levelTimer) { clearInterval(this._levelTimer); this._levelTimer = null; }
    this._listening = false;
    if (this._srcNode) { try { this._srcNode.disconnect(); } catch (e) {} this._srcNode = null; }
    this._analyser = null;
    this._buf = null;
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    if (this._actx) {
      var c = this._actx;
      this._actx = null;
      try { c.close(); } catch (e) {}
    }
    if (!silent) this._curLevel = 0;
  },

  // ---------- CAPTION (host SpeechRecognition, benchmark pattern as in cook-along) ----------
  // Honest split: the recognizer listens on the HOST's own microphone path.
  // The far-field microphoneMode applies ONLY to LISTEN's getUserMedia
  // level stream above - it does NOT feed or shape this recognition.

  captionTap() {
    var self = this;
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        capLine: 'HEARD: SKIP - SpeechRecognition n/a here',
        status: 'CAPTION SKIP - ASR n/a on this host',
        lastEvent: 'EVT: CAPTION unavailable (honest SKIP)'
      });
      return;
    }
    try {
      this._stopRecog();
      var rec = new SpeechRecognition();
      this._recog = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          self._caption = txt;
          self._captionDemo = false;
          self.setData({
            capLine: 'HEARD (far - may be wrong): ' + txt.slice(0, 36),
            status: 'CAPTION in - REPEAT hears it at your ear',
            lastEvent: 'EVT: caption heard (host ASR - may be wrong)'
          });
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self._recog = null;
        self.setData({
          capLine: 'HEARD: FAIL - ' + self._err(ev.error || ev),
          status: 'CAPTION FAIL - face the source, try again',
          lastEvent: 'EVT: CAPTION error'
        });
      };
      rec.onend = function () { if (self._recog === rec) self._recog = null; };
      rec.start();
      this.setData({
        capLine: 'HEARD: host ASR listening...',
        status: 'CAPTION: host ASR listening - face the source',
        lastEvent: 'EVT: ASR started (host mic, zh-CN)'
      });
    } catch (e) {
      this.setData({
        capLine: 'HEARD: FAIL - ' + this._err(e),
        status: 'CAPTION FAIL - ASR start failed',
        lastEvent: 'EVT: CAPTION start failed'
      });
    }
  },

  _stopRecog() {
    if (this._recog) {
      try { this._recog.abort(); } catch (e) {}
      this._recog = null;
    }
  },

  // ---------- REPEAT (TTS replay at the ear) ----------

  // The point of Far Ear: a sentence half-heard across the room is
  // spoken again by the glasses' own speaker, right at your ear.
  // This is a TTS replay of the caption - NOT live amplification:
  // the runtime documents no audio passthrough/monitoring API.
  repeatTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: REPEAT FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text;
      if (this._caption) {
        text = '刚才听到的是：' + this._caption;
      } else {
        text = '还没有可重播的句子。先点字幕，或者点演示。';
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({
        lastEvent: 'EVT: TTS repeat sent' + (this._captionDemo ? ' (DEMO caption)' : '') + ': ' + text.slice(0, 30)
      });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: REPEAT FAIL - ' + this._err(e) });
    }
  },

  // ---------- DEMO (synthetic level + sample caption) ----------

  // DEMO fakes a far speaker: a wandering level for ~3s, then a sample
  // caption clearly tagged DEMO. No mic, no sensor, no real speech.
  demoTap() {
    if (this._listening || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: busy - tap STOP first' });
      return;
    }
    this._demo = true;
    this._headingSrc = 'DEMO';
    this._heading = 85;
    this._demoStep = 0;
    this._caption = null;
    this._captionDemo = false;
    this.setData({
      status: 'DEMO: fake far speech - watch the level',
      micLine: 'MIC: DEMO - synthetic level, no mic used',
      capLine: 'HEARD (far - may be wrong): ...',
      lastEvent: 'EVT: DEMO on - sample caption incoming'
    });
    var self = this;
    this._demoTimer = setInterval(function () { self._demoTick(); }, 120);
    this._recompute();
  },

  _demoTick() {
    this._demoStep++;
    var s = this._demoStep;
    var lvl = 0.5 + 0.32 * Math.sin(s * 0.9) + 0.08 * Math.sin(s * 2.3);
    this._curLevel = Math.max(0.05, Math.min(0.95, lvl));
    if (s >= 26) {
      this._stopDemo();
      this._curLevel = 0.78;
      this._caption = '请大家看第三页';
      this._captionDemo = true;
      this.setData({
        status: 'DEMO caption in - tap REPEAT to hear it',
        capLine: 'HEARD (far - may be wrong) [DEMO]: 请大家看第三页',
        lastEvent: 'EVT: DEMO caption ready - REPEAT speaks it'
      });
    }
    this._recompute();
  },

  _stopDemo() {
    if (this._demoTimer) { clearInterval(this._demoTimer); this._demoTimer = null; }
  },

  clearTap() {
    if (this._listening || this._demoTimer || this._recog) {
      this.setData({ lastEvent: 'EVT: STOP first, then CLEAR' });
      return;
    }
    this._caption = null;
    this._captionDemo = false;
    this._curLevel = 0;
    this.setData({
      status: 'Cleared - face the sound, tap LISTEN',
      capLine: 'HEARD (far - may be wrong): ---',
      lastEvent: 'EVT: caption + level cleared'
    });
    this._recompute();
  },

  // ---------- render ----------

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    this.setData({
      headingLine: 'AIM: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      levelLine: 'LVL: ' + this._levelBar(this._curLevel) + ' ' +
        Math.round(this._curLevel * 100)
    });
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">FAR EAR</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="box">
      <text class="aim">{{aimLine}}</text>
      <text class="mic">{{micLine}}</text>
      <text class="level">{{levelLine}}</text>
    </view>
    <view class="box">
      <text class="cap">{{capLine}}</text>
      <text class="note">REPEAT says it again - at your ear, not louder room audio</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="listenTap">LISTEN</button>
      <button class="btn" bindtap="stopTap">STOP</button>
      <button class="btn" bindtap="captionTap">CAPTION</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="repeatTap">REPEAT</button>
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
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.aim {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.mic {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.level {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.cap {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.note {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
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
