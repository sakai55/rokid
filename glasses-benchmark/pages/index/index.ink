<script def>
{
  "navigationBarTitleText": "Glasses Benchmark"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    summary: 'READY · 0/23 PASS',
    deviceLine: '-',
    lastEvent: 'EVT: temple tap = run focused · swipe = move focus',
    renderTick: 0,
    running: false,
    focusKey: 'runall',
    scrollTarget: '',
    runCls: 'btn btn-main btn-focus',
    speakCls: 'btn',
    listenCls: 'btn',
    tests: [
      { id: 'device', name: '01 Device', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'navigator identity / versions / language', fcls: 'row' },
      { id: 'display', name: '02 Display', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'viewport / rendering / redraw burst', fcls: 'row' },
      { id: 'cpu', name: '03 CPU', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'JS math loop throughput', fcls: 'row' },
      { id: 'crypto', name: '04 Crypto', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'random + SHA-256 digest', fcls: 'row' },
      { id: 'storage', name: '05 Storage', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'localStorage + wx storage sync', fcls: 'row' },
      { id: 'netinfo', name: '06 Net Info', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'online state + connection quality', fcls: 'row' },
      { id: 'fetch', name: '07 Net Fetch', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'HTTPS round-trip to example.com', fcls: 'row' },
      { id: 'canvas', name: '08 Canvas 2D', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'gradient / shapes / text / flush', fcls: 'row' },
      { id: 'audio', name: '09 Audio Out', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'Web Audio oscillator via speaker', fcls: 'row' },
      { id: 'mic', name: '10 Microphone', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'enumerate + 4 mic modes + 0.9s rec', fcls: 'row' },
      { id: 'camera', name: '11 Camera', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'photo: wide / telephoto / default', fcls: 'row' },
      { id: 'accel', name: '12 Accel', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'accelerometer reading', fcls: 'row' },
      { id: 'gyro', name: '13 Gyro/Ori', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'gyroscope + absolute orientation', fcls: 'row' },
      { id: 'geo', name: '14 Geolocation', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'single position fix', fcls: 'row' },
      { id: 'ble', name: '15 Bluetooth', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'BLE availability + known devices', fcls: 'row' },
      { id: 'battery', name: '16 Battery', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'level + charging state', fcls: 'row' },
      { id: 'tts', name: '17 TTS Synth', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'synthesize pipeline (SPEAK = audible)', fcls: 'row' },
      { id: 'asr', name: '18 ASR Caps', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'recognition capabilities (LISTEN = live)', fcls: 'row' },
      { id: 'llm', name: '19 LLM', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'LanguageModel availability + prompt', fcls: 'row' },
      { id: 'barcode', name: '20 Barcode', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'BarcodeDetector formats', fcls: 'row' },
      { id: 'interaction', name: '21 Interaction', status: 'MANUAL', cls: 'st st-manual', msText: '-', detail: 'press a key / nod head / voice wakeup', fcls: 'row' },
      { id: 'eyetrack', name: '22 EyeTrack', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'boundary: platform has NO eye-tracking API', fcls: 'row' },
      { id: 'ocr', name: '23 OCR', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'boundary: platform has NO OCR API', fcls: 'row' }
    ]
  },

  onLoad() {
    var line = '-';
    try {
      var ink = (navigator.versions && navigator.versions.ink) || '?';
      line = 'ink ' + ink + ' · ' + (navigator.language || '-') + ' · ' +
        window.innerWidth + 'x' + window.innerHeight;
    } catch (e) { line = 'navigator n/a'; }
    this.setData({ deviceLine: line });
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._applyFocus();
  },

  onUnload() {
    if (this._recog) { try { this._recog.abort(); } catch (e) {} this._recog = null; }
  },

  onKeyDown(event) {
    var code = event && event.code;
    this._noteEvent('keyDown ' + code);
    // Temple touchpad arrives as key events (tap = Enter / GlobalHook,
    // swipe = ArrowUp/ArrowDown). The host does not turn these into button
    // taps, so the page maps them itself: swipe moves a focus highlight,
    // tap (or a nod) activates whatever is focused. Default focus: RUN ALL.
    if (code === 'ArrowDown') this._moveFocus(1);
    else if (code === 'ArrowUp') this._moveFocus(-1);
    else if (code === 'Enter' || code === 'GlobalHook') this._activateFocused();
    // Backspace is left to the host (back / exit).
  },
  onVoiceWakeup(event) { this._noteEvent('wakeup ' + ((event && event.keyword) || '')); },
  onHeadGesture(event) {
    this._noteEvent('gesture ' + ((event && event.gesture) || ''));
    if (event && event.gesture === 'nod') this._activateFocused();
  },
  onOrientationStabilityChange(event) {
    if (event && event.stable) this._noteEvent('orientation stable');
  },

  _noteEvent(text) {
    this.setData({ lastEvent: 'EVT: ' + text });
    this._setTest('interaction', { status: 'PASS', detail: 'last: ' + text });
  },

  _focusOrder() {
    var order = ['runall', 'speak', 'listen'];
    this.data.tests.forEach(function (t) { order.push(t.id); });
    return order;
  },

  _applyFocus() {
    var key = this.data.focusKey;
    var isBtn = key === 'runall' || key === 'speak' || key === 'listen';
    this.setData({
      runCls: 'btn btn-main' + (key === 'runall' ? ' btn-focus' : ''),
      speakCls: 'btn' + (key === 'speak' ? ' btn-focus' : ''),
      listenCls: 'btn' + (key === 'listen' ? ' btn-focus' : ''),
      scrollTarget: isBtn ? '' : 'row-' + key
    });
    var list = this.data.tests.map(function (t) {
      return {
        id: t.id, name: t.name, status: t.status, cls: t.cls,
        msText: t.msText, detail: t.detail,
        fcls: t.id === key ? 'row row-focus' : 'row'
      };
    });
    this.setData({ tests: list });
  },

  _moveFocus(dir) {
    var order = this._focusOrder();
    var idx = order.indexOf(this.data.focusKey);
    if (idx < 0) idx = 0;
    idx = (idx + dir + order.length) % order.length;
    var key = order[idx];
    this.setData({ focusKey: key });
    this._applyFocus();
    var label = key;
    if (key === 'runall') label = 'RUN ALL';
    else if (key === 'speak') label = 'SPEAK';
    else if (key === 'listen') label = 'LISTEN';
    else {
      for (var i = 0; i !== this.data.tests.length; i++) {
        if (this.data.tests[i].id === key) { label = this.data.tests[i].name; break; }
      }
    }
    this.setData({ lastEvent: 'EVT: focus → ' + label + ' (tap to run)' });
  },

  _activateFocused() {
    var key = this.data.focusKey;
    if (key === 'runall') { this.runAll(); return; }
    if (key === 'speak') { this.speakTest(); return; }
    if (key === 'listen') { this.listenTest(); return; }
    if (this.data.running) return;
    if (key === 'interaction') {
      this._setTest('interaction', { status: 'MANUAL', detail: 'listening: press key / nod / wakeup' });
      return;
    }
    this._runOne(key);
  },

  _setTest(id, patch) {
    var list = this.data.tests.map(function (t) {
      if (t.id !== id) return t;
      var n = { id: t.id, name: t.name, status: t.status, cls: t.cls, msText: t.msText, detail: t.detail, fcls: t.fcls || 'row' };
      if (patch.status) {
        n.status = patch.status;
        n.cls = 'st st-' + patch.status.toLowerCase();
      }
      if (patch.msText !== undefined) n.msText = patch.msText;
      if (patch.detail !== undefined) n.detail = patch.detail;
      return n;
    });
    this.setData({ tests: list });
    var pass = 0, fail = 0, skip = 0, done = 0;
    list.forEach(function (t) {
      if (t.status === 'PASS') { pass++; done++; }
      else if (t.status === 'FAIL') { fail++; done++; }
      else if (t.status === 'SKIP') { skip++; done++; }
    });
    this.setData({
      summary: (this.data.running ? 'RUNNING' : 'DONE ' + done + '/' + list.length) +
        ' · PASS ' + pass + ' · FAIL ' + fail + ' · SKIP ' + skip
    });
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  async runAll() {
    if (this.data.running) return;
    this.setData({ running: true, lastEvent: 'EVT: benchmark running...' });
    var ids = ['device', 'display', 'cpu', 'crypto', 'storage', 'netinfo', 'fetch',
      'canvas', 'audio', 'mic', 'camera', 'accel', 'gyro', 'geo', 'ble', 'battery',
      'tts', 'asr', 'llm', 'barcode', 'eyetrack', 'ocr'];
    for (var i = 0; i !== ids.length; i++) {
      await this._runOne(ids[i]);
    }
    this.setData({ running: false, lastEvent: 'EVT: benchmark finished - see summary' });
    this._setTest('barcode', {});
  },

  runOne(event) {
    var ds = (event && event.currentTarget && event.currentTarget.dataset) ||
      (event && event.target && event.target.dataset) || {};
    var id = ds.id;
    if (!id || this.data.running) return;
    if (id === 'interaction') {
      this._setTest('interaction', { status: 'MANUAL', detail: 'listening: press key / nod / wakeup' });
      return;
    }
    this._runOne(id);
  },

  async _runOne(id) {
    var t0 = performance.now();
    this._setTest(id, { status: 'RUN', msText: '...', detail: 'running...' });
    try {
      var r = await this._dispatch(id);
      var ms = Math.round(performance.now() - t0);
      this._setTest(id, { status: r.status, msText: ms + 'ms', detail: r.detail });
      return r;
    } catch (e) {
      var ms2 = Math.round(performance.now() - t0);
      this._setTest(id, { status: 'FAIL', msText: ms2 + 'ms', detail: this._err(e) });
      return { status: 'FAIL', detail: this._err(e) };
    }
  },

  _dispatch(id) {
    switch (id) {
      case 'device': return this._tDevice();
      case 'display': return this._tDisplay();
      case 'cpu': return this._tCpu();
      case 'crypto': return this._tCrypto();
      case 'storage': return this._tStorage();
      case 'netinfo': return this._tNetInfo();
      case 'fetch': return this._tFetch();
      case 'canvas': return this._tCanvas();
      case 'audio': return this._tAudio();
      case 'mic': return this._tMic();
      case 'camera': return this._tCamera();
      case 'accel': return this._tSensor('Accelerometer', typeof Accelerometer !== 'undefined' ? Accelerometer : null);
      case 'gyro': return this._tGyro();
      case 'geo': return this._tGeo();
      case 'ble': return this._tBle();
      case 'battery': return this._tBattery();
      case 'tts': return this._tTts();
      case 'asr': return this._tAsr();
      case 'llm': return this._tLlm();
      case 'barcode': return this._tBarcode();
      case 'eyetrack': return this._tNoApi('eye');
      case 'ocr': return this._tNoApi('ocr');
      default: return Promise.resolve({ status: 'SKIP', detail: 'no test' });
    }
  },

  async _tDevice() {
    var v = navigator.versions || {};
    var detail = 'ink ' + (v.ink || '?') + ' skia ' + (v.skia || '?') + ' · ' +
      (navigator.language || '-') + ' · ' + (navigator.region || '-') +
      ' · render ' + (navigator.renderingEnabled ? 'on' : 'off');
    if (!navigator.userAgent && !v.ink) throw new Error('navigator empty');
    return { status: 'PASS', detail: detail.slice(0, 72) };
  },

  async _tDisplay() {
    var w = window.innerWidth, h = window.innerHeight;
    for (var i = 0; i !== 12; i++) this.setData({ renderTick: i });
    if (!w || !h) {
      if (navigator.renderingEnabled) {
        return { status: 'PASS', detail: 'viewport n/a in host · render on · 12 redraws' };
      }
      throw new Error('viewport 0 and rendering off');
    }
    return { status: 'PASS', detail: w + 'x' + h + ' · 12 redraws · tick ' + this.data.renderTick };
  },

  async _tCpu() {
    var n = 300000, x = 0, t0 = performance.now();
    for (var i = 1; i !== n + 1; i++) x += Math.sin(i) * Math.cos(i / 3) + Math.sqrt(i % 97);
    var ms = performance.now() - t0;
    var rate = Math.round(n / Math.max(ms, 1) * 1000);
    return { status: 'PASS', detail: n + ' iter · ' + rate + ' ops/s · acc ' + x.toFixed(1) };
  },

  async _tCrypto() {
    var buf = new Uint8Array(32);
    crypto.getRandomValues(buf);
    var digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('rokid-benchmark'));
    var uuid = crypto.randomUUID ? crypto.randomUUID().slice(0, 8) : 'n/a';
    if (digest.byteLength !== 32) throw new Error('digest len ' + digest.byteLength);
    return { status: 'PASS', detail: 'sha256 32B ok · rand[0]=' + buf[0] + ' · uuid ' + uuid };
  },

  async _tStorage() {
    localStorage.setItem('bench', '42');
    var a = localStorage.getItem('bench');
    localStorage.removeItem('bench');
    wx.setStorageSync('bench', { v: 42 });
    var b = wx.getStorageSync('bench');
    wx.removeStorageSync('bench');
    if (a !== '42' || !b || b.v !== 42) throw new Error('storage mismatch');
    return { status: 'PASS', detail: 'local + wx sync rw ok · canIUse(request)=' + wx.canIUse('request') };
  },

  async _tNetInfo() {
    var c = navigator.connection || {};
    return {
      status: 'PASS',
      detail: 'online=' + navigator.onLine + ' · ' + (c.type || '?') + '/' +
        (c.effectiveType || '?') + ' · rtt ' + (c.rtt || 0) + 'ms · dl ' + (c.downlink || 0) + 'Mb/s'
    };
  },

  async _tFetch() {
    var res = await this._withTimeout(fetch('https://example.com/'), 9000, 'fetch');
    var text = await res.text();
    return { status: res.ok ? 'PASS' : 'FAIL', detail: 'HTTP ' + res.status + ' · ' + text.length + 'B body' };
  },

  async _tCanvas() {
    var ctx = wx.createCanvasContext('benchCanvas');
    if (!ctx) throw new Error('canvas ctx null (not ready?)');
    ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, 448, 40);
    var g = ctx.createLinearGradient(0, 0, 448, 0);
    g.addColorStop(0, '#40ff5e'); g.addColorStop(1, '#40ff5e');
    ctx.fillStyle = g; ctx.fillRect(4, 6, 200, 12);
    ctx.fillStyle = '#40ff5e'; ctx.font = '12px monospace';
    ctx.fillText('CANVAS OK', 220, 17);
    ctx.beginPath(); ctx.arc(420, 20, 9, 0, Math.PI * 2); ctx.strokeStyle = '#40ff5e'; ctx.stroke();
    var m = ctx.measureText('CANVAS OK');
    ctx.flush();
    return { status: 'PASS', detail: 'draw + flush ok · text w=' + Math.round(m.width) + 'px' };
  },

  async _tAudio() {
    var ctx = new AudioContext();
    try {
      await ctx.resume();
      var osc = ctx.createOscillator();
      var gain = ctx.createGain();
      osc.type = 'sine'; osc.frequency.value = 880;
      gain.gain.value = 0.05;
      osc.connect(gain); gain.connect(ctx.destination);
      osc.start();
      await new Promise(function (r) { setTimeout(r, 250); });
      osc.stop(); osc.disconnect(); gain.disconnect();
      return { status: 'PASS', detail: '880Hz 250ms · sr ' + ctx.sampleRate + 'Hz · ' + ctx.state };
    } finally {
      try { await ctx.close(); } catch (e) {}
    }
  },

  async _tMic() {
    if (!navigator.mediaDevices) throw new Error('mediaDevices n/a');
    var devices = await navigator.mediaDevices.enumerateDevices();
    // Official mic modes (AIUI media API): wearer / far-field / near-field /
    // omnidirectional. Probe each; an unsupported mode rejects with
    // OverconstrainedError and is reported as not-supported, not a failure.
    var modes = ['wearer', 'far-field', 'near-field', 'omnidirectional'];
    var okModes = [];
    for (var i = 0; i !== modes.length; i++) {
      var probe = null;
      try {
        probe = await this._withTimeout(navigator.mediaDevices.getUserMedia(
          { audio: { captureSource: 'microphone', microphoneMode: modes[i] } }), 4000, 'mode');
        var tr = probe.getAudioTracks()[0];
        var actual = tr && tr.getSettings ? tr.getSettings().microphoneMode : null;
        okModes.push(actual || modes[i]);
      } catch (e) { /* mode not supported on this host */ }
      if (probe) probe.getTracks().forEach(function (t) { t.stop(); });
    }
    var stream = await this._withTimeout(navigator.mediaDevices.getUserMedia(
      { audio: { captureSource: 'microphone', microphoneMode: 'wearer' } }), 8000, 'mic');
    try {
      var mime = (typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported('audio/wav'))
        ? 'audio/wav' : '';
      var rec = new MediaRecorder(stream, mime ? { mimeType: mime } : undefined);
      var bytes = 0;
      rec.addEventListener('dataavailable', function (e) { if (e.data) bytes += e.data.size; });
      var stopped = new Promise(function (r) { rec.addEventListener('stop', r); });
      rec.start(250);
      await new Promise(function (r) { setTimeout(r, 900); });
      rec.stop();
      await this._withTimeout(stopped, 4000, 'rec stop');
      var settings = stream.getAudioTracks()[0] ? stream.getAudioTracks()[0].getSettings() : {};
      return {
        status: bytes > 0 ? 'PASS' : 'FAIL',
        detail: (devices.length + ' dev · modes ' + okModes.length + '/4 ok · rec ' +
          bytes + 'B · ' + (settings.sampleRate || '?') + 'Hz').slice(0, 72)
      };
    } finally {
      stream.getTracks().forEach(function (t) { t.stop(); });
    }
  },

  async _tCamera() {
    if (!navigator.mediaDevices) throw new Error('mediaDevices n/a');
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        // Official photo modes: wide (scanning) / telephoto (distant text) /
        // default. Decode each blob to report its real pixel size.
        var modes = ['wide', 'telephoto', 'default'];
        var labels = { wide: 'wide', telephoto: 'tele', default: 'def' };
        var parts = [];
        var okCount = 0;
        for (var i = 0; i !== modes.length; i++) {
          try {
            var blob = await this._withTimeout(cap.takePhoto({ mode: modes[i] }), 9000, 'photo');
            var dims = '?';
            if (typeof createImageBitmap !== 'undefined') {
              var bmp = await createImageBitmap(blob);
              dims = bmp.width + 'x' + bmp.height;
              try { bmp.close(); } catch (e) {}
            }
            parts.push(labels[modes[i]] + ' ' + Math.round(blob.size / 1024) + 'KB ' + dims);
            okCount++;
          } catch (e) {
            parts.push(labels[modes[i]] + ' err');
          }
        }
        if (!okCount) throw new Error('all photo modes failed');
        return { status: 'PASS', detail: parts.join(' · ').slice(0, 72) };
      }
      throw new Error('ImageCapture n/a');
    } catch (e) {
      if (stream) { stream.getTracks().forEach(function (t) { t.stop(); }); stream = null; }
      var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
      if (!ctx) throw e;
      var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
      var size = res && res.data ? res.data.byteLength : 0;
      return { status: size > 0 ? 'PASS' : 'FAIL', detail: 'wx photo ' + size + 'B · ' + (res.mimeType || '') };
    } finally {
      if (stream) stream.getTracks().forEach(function (t) { t.stop(); });
    }
  },

  _sensorOnce(Ctor, ms) {
    var self = this;
    return new Promise(function (resolve, reject) {
      var sensor = new Ctor({ frequency: 10 });
      var timer = setTimeout(function () {
        try { sensor.stop(); } catch (e) {}
        reject(new Error('no reading in ' + ms + 'ms'));
      }, ms);
      sensor.addEventListener('reading', function () {
        clearTimeout(timer);
        var snap = { x: sensor.x, y: sensor.y, z: sensor.z, q: sensor.quaternion };
        try { sensor.stop(); } catch (e) {}
        resolve(snap);
      });
      sensor.addEventListener('error', function (ev) {
        clearTimeout(timer);
        try { sensor.stop(); } catch (e) {}
        reject(new Error(self._err(ev.error || ev)));
      });
      sensor.start();
    });
  },

  async _tSensor(name, Ctor) {
    if (!Ctor) return { status: 'SKIP', detail: name + ' n/a on this host' };
    var r = await this._sensorOnce(Ctor, 3500);
    return {
      status: 'PASS',
      detail: 'x ' + Number(r.x).toFixed(2) + ' y ' + Number(r.y).toFixed(2) + ' z ' + Number(r.z).toFixed(2)
    };
  },

  async _tGyro() {
    var Gyro = typeof Gyroscope !== 'undefined' ? Gyroscope : null;
    var r = await this._tSensor('Gyroscope', Gyro);
    if (r.status !== 'PASS') return r;
    var Ori = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (Ori) {
      try {
        var o = await this._sensorOnce(Ori, 2500);
        if (o.q) r.detail += ' · q[' + o.q.map(function (v) { return Number(v).toFixed(2); }).join(',') + ']';
      } catch (e) { r.detail += ' · ori: ' + this._err(e); }
    }
    return r;
  },

  async _tGeo() {
    if (!navigator.geolocation) throw new Error('geolocation n/a');
    var pos = await this._withTimeout(new Promise(function (resolve, reject) {
      navigator.geolocation.getCurrentPosition(resolve, reject,
        { enableHighAccuracy: false, timeout: 9000, maximumAge: 60000 });
    }), 11000, 'geo');
    var c = pos.coords;
    return {
      status: 'PASS',
      detail: c.latitude.toFixed(5) + ',' + c.longitude.toFixed(5) + ' · ±' + Math.round(c.accuracy) + 'm'
    };
  },

  async _tBle() {
    if (!navigator.bluetooth) return { status: 'SKIP', detail: 'bluetooth n/a' };
    var avail = await navigator.bluetooth.getAvailability();
    var devices = await navigator.bluetooth.getDevices();
    return {
      status: avail ? 'PASS' : 'FAIL',
      detail: 'available=' + avail + ' · known devices ' + devices.length
    };
  },

  async _tBattery() {
    if (!navigator.getBattery) return { status: 'SKIP', detail: 'getBattery n/a' };
    try {
      var b = await navigator.getBattery();
      return {
        status: 'PASS',
        detail: 'level ' + Math.round(b.level * 100) + '% · charging=' + b.charging
      };
    } catch (e) {
      return { status: 'SKIP', detail: 'host has no battery cap: ' + this._err(e) };
    }
  },

  async _tTts() {
    if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
      return { status: 'SKIP', detail: 'speechSynthesis n/a' };
    }
    var task = await speechSynthesis.synthesize(
      new SpeechSynthesisUtterance('Benchmark OK'), { subtitles: 'sentence' });
    var fin = await this._withTimeout(task.finished, 12000, 'tts');
    return { status: 'PASS', detail: 'synth ok · dur ' + fin.duration + ' · ' + task.state };
  },

  speakTest() {
    try {
      speechSynthesis.speak(
        new SpeechSynthesisUtterance('眼镜基准测试，扬声器播放正常'), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - listen for voice' });
      this._setTest('tts', { status: 'PASS', detail: 'speak() sent (audible check by ear)' });
    } catch (e) {
      this._setTest('tts', { status: 'FAIL', detail: this._err(e) });
    }
  },

  async _tAsr() {
    var parts = [];
    if (typeof SpeechRecognitionSession !== 'undefined' && SpeechRecognitionSession.getCapabilities) {
      var caps = await SpeechRecognitionSession.getCapabilities();
      parts.push('formats ' + (caps.audioFormats ? caps.audioFormats.length : '?'));
      parts.push('interim ' + caps.interimResults);
      parts.push('phrases ' + caps.phrases);
    }
    parts.push('live ctor ' + (typeof SpeechRecognition !== 'undefined'));
    return { status: 'PASS', detail: parts.join(' · ').slice(0, 72) };
  },

  listenTest() {
    var self = this;
    try {
      if (typeof SpeechRecognition === 'undefined') throw new Error('SpeechRecognition n/a');
      if (this._recog) { try { this._recog.abort(); } catch (e) {} }
      var rec = new SpeechRecognition();
      this._recog = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = ev.results[ev.resultIndex][0].transcript;
          self.setData({ lastEvent: 'ASR: ' + txt });
          self._setTest('asr', { status: 'PASS', detail: 'heard: ' + String(txt).slice(0, 44) });
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self._setTest('asr', { status: 'FAIL', detail: 'asr ' + self._err(ev.error || ev) });
      };
      rec.start();
      this.setData({ lastEvent: 'EVT: listening... say something' });
    } catch (e) {
      this._setTest('asr', { status: 'FAIL', detail: this._err(e) });
    }
  },

  async _tLlm() {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return { status: 'SKIP', detail: 'LanguageModel global n/a' };
    var avail = await LM.availability();
    if (avail !== 'available') return { status: 'SKIP', detail: 'availability=' + avail };
    var session = await LM.create({
      initialPrompts: [{ role: 'system', content: 'You reply very concisely.' }]
    });
    try {
      var ans = await this._withTimeout(session.prompt('Reply with exactly: OK'), 25000, 'llm');
      return { status: 'PASS', detail: 'answer: ' + String(ans).slice(0, 40) };
    } finally {
      try { session.destroy(); } catch (e) {}
    }
  },

  async _tBarcode() {
    if (typeof BarcodeDetector === 'undefined') return { status: 'SKIP', detail: 'BarcodeDetector n/a' };
    var formats = await BarcodeDetector.getSupportedFormats();
    return {
      status: 'PASS',
      detail: formats.length + ' formats · ' + formats.slice(0, 3).join(',')
    };
  },

  // Platform boundary items: these capabilities do NOT exist in the official
  // AIUI API surface, so they can never PASS. They are listed so the report
  // states the boundary explicitly instead of implying coverage.
  async _tNoApi(kind) {
    if (kind === 'eye') {
      return {
        status: 'SKIP',
        detail: 'NO eye-tracking API · gaze = head orientation (13/21)'
      };
    }
    return {
      status: 'SKIP',
      detail: 'NO OCR API · read text = telephoto photo + LLM (11/19)'
    };
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">GLASSES BENCHMARK</text>
      <text class="summary">{{summary}}</text>
      <text class="sub">{{deviceLine}}</text>
    </view>
    <view class="actions">
      <button class="{{runCls}}" bindtap="runAll">RUN ALL</button>
      <button class="{{speakCls}}" bindtap="speakTest">SPEAK</button>
      <button class="{{listenCls}}" bindtap="listenTest">LISTEN</button>
    </view>
    <canvas id="benchCanvas" width="448" height="40" class="bench-canvas"></canvas>
    <scroll-view class="list" scroll-y="true" scroll-into-view="{{scrollTarget}}">
      <view ink:for="{{tests}}" class="{{item.fcls}}" id="row-{{item.id}}" bindtap="runOne" data-id="{{item.id}}">
        <view class="row-top">
          <text class="name">{{item.name}}</text>
          <text class="{{item.cls}}">{{item.status}}</text>
          <text class="ms">{{item.msText}}</text>
        </view>
        <text class="detail">{{item.detail}}</text>
      </view>
    </scroll-view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 12px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 8px;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.summary {
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
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 8px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 5px;
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
.btn-focus {
  color: #40ff5e;
  border-color: #40ff5e;
  background-color: rgba(64,255,94,0.30);
}
.bench-canvas {
  width: 448px;
  height: 40px;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 2px;
  margin-bottom: 8px;
}
.list {
  height: 148px;
}
.row {
  display: flex;
  flex-direction: column;
  padding: 6px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.row-focus {
  background-color: rgba(64,255,94,0.14);
}
.row-top {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.name {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  font-size: 13px;
  line-height: 17px;
}
.st {
  font-family: monospace;
  font-size: 11px;
  font-weight: 500;
  line-height: 15px;
  margin-right: 8px;
}
.st-wait { color: rgba(64,255,94,0.48); }
.st-manual { color: rgba(64,255,94,0.48); }
.st-run { color: #40ff5e; }
.st-pass { color: #40ff5e; }
.st-fail { color: rgba(64,255,94,0.72); }
.st-skip { color: rgba(64,255,94,0.48); }
.ms {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  width: 64px;
  text-align: right;
}
.detail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 6px;
}
</style>
