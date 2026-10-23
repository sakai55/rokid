<script def>
{
  "navigationBarTitleText": "Cry Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'Tap WATCH - glasses listen for loud bursts',
    alertLine: 'NO ALERT - no loud burst yet',
    alertCls: 'alert',
    watchLine: 'WATCH: idle · SENS: 中 · THR: 40',
    levelLine: 'LVL: ---------- 0 · QUIET: --:--',
    ruleLine: 'RULE: >=6/10 over THR + spread >18',
    honestLine: 'NOT cry detection - loud + fluctuating only',
    logHead: 'ALERT LOG (times only): 0/20',
    log1: 'No alerts today',
    log2: ' ',
    log3: ' ',
    lastEvent: 'EVT: helper only - never a baby monitor',
    busy: false
  },

  onLoad() {
    this._sensIndex = 1; // 0 low, 1 medium, 2 high
    this._thresholds = [
      { label: '低', value: 0.55 },
      { label: '中', value: 0.40 },
      { label: '高', value: 0.25 }
    ];
    this._spreadFloor = 0.18;
    this._samples = [];
    this._curLevel = 0;
    this._watching = false;
    this._micLabel = 'idle';
    this._sampleTimer = null;
    this._stream = null;
    this._actx = null;
    this._analyser = null;
    this._srcNode = null;
    this._buf = null;
    this._demo = false;
    this._demoTimer = null;
    this._demoStep = 0;
    this._demoAlertStep = -1;
    this._watchStartedAt = 0;
    this._quietSince = 0;
    this._lastAlertAt = 0;
    this._cooldownUntil = 0;
    this._flashOn = false;
    this._logEntries = [];
    this._loadLog();
    this._recompute();
  },

  onShow() {},

  onHide() {
    this._stopWatch(true);
    this._stopDemo(true);
  },

  onUnload() {
    this._stopWatch(true);
    this._stopDemo(true);
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._watching || this._demoTimer) this.stopTap(); else this.watchTap();
    } else if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.sensTap();
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

  _fmtElapsed(ms) {
    if (ms < 0) ms = 0;
    var s = Math.floor(ms / 1000);
    var m = Math.floor(s / 60);
    s = s % 60;
    return this._pad2(m) + ':' + this._pad2(s);
  },

  _sens() {
    return this._thresholds[this._sensIndex];
  },

  // ---------- alert-time log (wx storage: dates, times and DEMO flags only) ----------

  _loadLog() {
    var out = [];
    try {
      var raw = wx.getStorageSync('cryWatchLog');
      if (Array.isArray(raw)) {
        var today = this._todayKey();
        for (var i = 0; i !== raw.length; i++) {
          var item = raw[i];
          var entry = null;
          if (typeof item === 'string') {
            entry = { date: today, time: item, demo: false };
          } else if (item && typeof item.time === 'string') {
            entry = { date: item.date || today, time: item.time, demo: !!item.demo };
          }
          if (entry && entry.date === today && entry.time) out.push(entry);
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
      wx.setStorageSync('cryWatchLog', this._logEntries || []);
    } catch (e) {
      // The in-memory list still works for this page session.
    }
  },

  // ---------- trigger rule ----------

  // The whole rule, in one place: in the last 10 samples, at least 6
  // must be above the sensitivity threshold AND the window must
  // fluctuate (max - min above the spread floor). A steady loud TV
  // or air conditioner fails the spread test; one door slam fails
  // the 6-of-10 count. This is a loudness pattern, NOT cry detection.
  _triggerFromSamples(samples, threshold, spreadFloor) {
    if (!samples || samples.length < 10) return false;
    var win = samples.slice(samples.length - 10);
    var above = 0;
    var min = 1;
    var max = 0;
    for (var i = 0; i !== win.length; i++) {
      var v = win[i];
      if (v > threshold) above++;
      if (v < min) min = v;
      if (v > max) max = v;
    }
    return above >= 6 && (max - min) > spreadFloor;
  },

  _levelBar(lvl) {
    var n = Math.max(0, Math.min(10, Math.round(lvl * 10)));
    var s = '';
    for (var i = 0; i !== 10; i++) s += i < n ? '#' : '-';
    return s;
  },

  _pushSample(level, nowMs) {
    var now = nowMs || Date.now();
    var sens = this._sens();
    if (level > sens.value) this._quietSince = now;
    this._samples.push(level);
    while (this._samples.length > 10) this._samples.shift();

    var alertActive = now < this._cooldownUntil;
    if (alertActive) this._flashOn = !this._flashOn;

    if (now >= this._cooldownUntil &&
        this._triggerFromSamples(this._samples, sens.value, this._spreadFloor)) {
      this._fireAlert(now);
      return;
    }
    this._recompute();
  },

  _fireAlert(nowMs) {
    var now = nowMs || Date.now();
    var entry = { date: this._todayKey(), time: this._timeNow(), demo: !!this._demo };
    this._lastAlertAt = now;
    this._cooldownUntil = now + 60000;
    this._quietSince = now;
    this._flashOn = true;
    this._samples = [];
    this._logEntries.unshift(entry);
    if (this._logEntries.length > 20) this._logEntries.length = 20;
    this._saveLog();
    var sent = this._speakAlert();
    if (this._demo) this._demoAlertStep = this._demoStep;
    this.setData({
      status: this._demo ? 'DEMO ALERT - synthetic burst fired it' : 'ALERT - go and check the baby',
      alertLine: 'LOUD SOUND - check the baby',
      lastEvent: 'EVT: alert ' + entry.time + (entry.demo ? ' DEMO' : '') + (sent ? ' · TTS sent' : ' · TTS n/a')
    });
    this._recompute();
  },

  _speakAlert() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance('有较大的声音，去看看宝宝'), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  // ---------- WATCH (real mic) ----------

  async watchTap() {
    if (this._watching || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: already on - tap STOP to end' });
      return;
    }
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: 'WATCH FAIL: mic n/a on this host',
        lastEvent: 'EVT: WATCH FAIL - mediaDevices n/a'
      });
      return;
    }
    if (typeof AudioContext === 'undefined') {
      this.setData({
        status: 'WATCH FAIL: Web Audio n/a on this host',
        lastEvent: 'EVT: WATCH FAIL - AudioContext n/a'
      });
      return;
    }
    this.setData({ busy: true, status: 'WATCH: opening mic (omnidirectional)...' });
    var stream = null;
    var actx = null;
    var fellBack = false;
    try {
      try {
        stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'omnidirectional' }
        }), 9000, 'mic');
      } catch (eMode) {
        // media.md: not every device supports every mode - fall back
        // to the default microphone and say so, never fake the mode.
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
      var mode = '';
      try {
        var tr = stream.getAudioTracks()[0];
        if (tr && tr.getSettings) mode = tr.getSettings().microphoneMode || '';
      } catch (e) {}
      this._micLabel = fellBack ? 'default - omni n/a' : (mode || 'omnidirectional');
      this._samples = [];
      this._curLevel = 0;
      this._watching = true;
      this._watchStartedAt = Date.now();
      this._quietSince = this._watchStartedAt;
      if (Date.now() >= this._cooldownUntil) {
        this.setData({ alertLine: 'NO ALERT - listening quietly' });
      }
      var self = this;
      this._sampleTimer = setInterval(function () { self._sampleTick(); }, 200);
      this.setData({
        busy: false,
        status: 'WATCHING: loud bursts alert in view + voice',
        lastEvent: fellBack ? 'EVT: omni n/a - default mic used, said so' : 'EVT: watch live - samples every 200ms'
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
        status: 'WATCH FAIL: ' + this._err(e),
        lastEvent: 'EVT: WATCH FAIL - ' + this._err(e)
      });
    }
  },

  _sampleTick() {
    if (!this._watching) return;
    var lvl = 0;
    if (this._analyser && this._buf) {
      this._analyser.getFloatTimeDomainData(this._buf);
      var sum = 0;
      for (var i = 0; i !== this._buf.length; i++) sum += this._buf[i] * this._buf[i];
      lvl = Math.min(1, Math.sqrt(sum / this._buf.length) * 3);
    }
    this._curLevel = lvl;
    this._pushSample(lvl, Date.now());
  },

  stopTap() {
    if (this._demoTimer) {
      this._stopDemo(false);
      this._demo = false;
      this._curLevel = 0;
      this.setData({
        status: 'DEMO stopped - WATCH or DEMO again',
        lastEvent: 'EVT: demo stream stopped early'
      });
      this._recompute();
      return;
    }
    if (!this._watching) {
      this.setData({ lastEvent: 'EVT: nothing on - WATCH or DEMO first' });
      return;
    }
    this._stopWatch(false);
    this.setData({
      status: 'Stopped - tap WATCH to listen again',
      lastEvent: 'EVT: mic stopped - tracks released'
    });
    this._recompute();
  },

  // Stops mic/context/timer; silent=true on hide/unload.
  _stopWatch(silent) {
    if (this._sampleTimer) { clearInterval(this._sampleTimer); this._sampleTimer = null; }
    this._watching = false;
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

  // ---------- SENS ----------

  sensTap() {
    this._sensIndex = (this._sensIndex + 1) % this._thresholds.length;
    this._samples = []; // a new threshold restarts the 10-sample window
    var s = this._sens();
    this.setData({
      status: 'SENS: ' + s.label + ' - threshold ' + Math.round(s.value * 100),
      lastEvent: 'EVT: sensitivity ' + s.label + ' · THR ' + Math.round(s.value * 100) + ' · spread >18'
    });
    this._recompute();
  },

  // ---------- DEMO (synthetic quiet, then a fluctuating loud burst) ----------

  // DEMO feeds fake levels at the real 200ms cadence: 10 quiet
  // samples, then a loud burst that rises and falls. The burst has
  // at least 6 of 10 samples above every sensitivity threshold and
  // a wide spread, so the real trigger rule fires it - no mic used.
  demoTap() {
    if (this._watching || this._demoTimer) {
      this.setData({ lastEvent: 'EVT: busy - tap STOP first' });
      return;
    }
    this._demo = true;
    this._demoStep = 0;
    this._demoAlertStep = -1;
    this._samples = [];
    this._curLevel = 0;
    this._watchStartedAt = Date.now();
    this._quietSince = this._watchStartedAt;
    if (Date.now() >= this._cooldownUntil) {
      this.setData({ alertLine: 'NO ALERT - demo is quiet...' });
    }
    this.setData({
      status: 'DEMO: fake quiet first, then a loud burst',
      lastEvent: 'EVT: DEMO on - synthetic levels, no mic used'
    });
    var self = this;
    this._demoTimer = setInterval(function () { self._demoTick(); }, 200);
    this._recompute();
  },

  _demoLevel(step) {
    var quiet = [0.05, 0.07, 0.06, 0.08, 0.05, 0.07, 0.06, 0.05, 0.08, 0.06];
    var burst = [0.82, 0.44, 0.91, 0.52, 0.86, 0.40, 0.95, 0.78, 0.62, 0.89];
    if (step < 10) return quiet[step];
    if (step < 20) return burst[step - 10];
    return 0.05;
  },

  _demoTick() {
    var step = this._demoStep;
    this._curLevel = this._demoLevel(step);
    this._demoStep++;
    this._pushSample(this._curLevel, Date.now());
    if (this._demoAlertStep >= 0 && this._demoStep >= this._demoAlertStep + 5) {
      this._stopDemo(false);
      this._demo = false;
      this._curLevel = 0;
      this._flashOn = true; // leave the alert lit for the screenshot
      this.setData({
        status: 'DEMO done - alert fired, time logged',
        lastEvent: 'EVT: demo burst triggered the real rule'
      });
      this._recompute();
      return;
    }
    if (this._demoStep > 30 && this._demoAlertStep < 0) {
      this._stopDemo(false);
      this._demo = false;
      this._curLevel = 0;
      this.setData({
        status: 'DEMO done - no alert (unexpected)',
        lastEvent: 'EVT: demo ended without triggering'
      });
      this._recompute();
    }
  },

  _stopDemo(silent) {
    if (this._demoTimer) { clearInterval(this._demoTimer); this._demoTimer = null; }
    if (silent) this._demo = false;
  },

  clearTap() {
    this._logEntries = [];
    this._saveLog();
    if (Date.now() >= this._cooldownUntil) {
      this.setData({ alertLine: this._watching || this._demoTimer ? 'NO ALERT - listening quietly' : 'NO ALERT - no loud burst yet' });
    }
    this.setData({
      status: 'Alert log cleared - times only, no audio kept',
      lastEvent: 'EVT: cryWatchLog cleared'
    });
    this._recompute();
  },

  // ---------- render ----------

  _recompute() {
    var s = this._sens();
    var now = Date.now();
    var active = now < this._cooldownUntil;
    var patch = {};
    if (this._demoTimer) {
      patch.watchLine = 'WATCH: DEMO · SENS: ' + s.label + ' · THR: ' + Math.round(s.value * 100);
    } else if (this._watching) {
      patch.watchLine = 'WATCH: ' + this._micLabel + ' · THR: ' + Math.round(s.value * 100);
    } else {
      patch.watchLine = 'WATCH: idle · SENS: ' + s.label + ' · THR: ' + Math.round(s.value * 100);
    }
    if (active) {
      patch.watchLine += ' · COOL: ' + Math.ceil((this._cooldownUntil - now) / 1000) + 's';
    }
    var quiet = (this._watching || this._demoTimer)
      ? this._fmtElapsed(now - (this._quietSince || now))
      : '--:--';
    patch.levelLine = 'LVL: ' + this._levelBar(this._curLevel) + ' ' +
      Math.round(this._curLevel * 100) + ' · QUIET: ' + quiet;
    patch.ruleLine = 'RULE: >=6/10 over THR + spread >18';
    patch.honestLine = 'NOT cry detection - loud + fluctuating only';
    patch.alertCls = active ? (this._flashOn ? 'alert alert-on' : 'alert alert-off') : 'alert';
    var entries = this._logEntries || [];
    patch.logHead = 'ALERT LOG (times only): ' + entries.length + '/20';
    patch.log1 = entries.length ? entries[0].time + (entries[0].demo ? ' DEMO' : '') : 'No alerts today';
    patch.log2 = entries.length > 1 ? entries[1].time + (entries[1].demo ? ' DEMO' : '') : ' ';
    patch.log3 = entries.length > 2 ? entries[2].time + (entries[2].demo ? ' DEMO' : '') : ' ';
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">CRY WATCH</text>
      <text class="status">{{status}}</text>
    </view>
    <view class="alert-box">
      <text class="{{alertCls}}">{{alertLine}}</text>
    </view>
    <view class="box">
      <text class="watch">{{watchLine}}</text>
      <text class="level">{{levelLine}}</text>
      <text class="rule">{{ruleLine}}</text>
      <text class="note">{{honestLine}}</text>
    </view>
    <view class="box">
      <text class="log-head">{{logHead}}</text>
      <text class="log">{{log1}}</text>
      <text class="log">{{log2}}</text>
      <text class="log">{{log3}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="watchTap">WATCH</button>
      <button class="btn" bindtap="stopTap">STOP</button>
      <button class="btn" bindtap="sensTap">SENS</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
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
.alert-off {
  color: #40ff5e;
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
