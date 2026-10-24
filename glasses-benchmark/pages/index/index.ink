<script def>
{
  "navigationBarTitleText": "眼镜全功能自检"
}
</script>

<script setup>
import wx from 'wx';

var PAGE_SIZE = 4;

export default {
  data: {
    summary: '就绪 · 共 23 项',
    appVersion: 'v2.0.1',
    deviceLine: '-',
    lastEvent: '单击镜腿开始测试 · 滑动翻页看结果',
    renderTick: 0,
    running: false,
    runLabel: '开始测试',
    selId: null,
    hasRun: false,
    page: 0,
    pageText: '第 1/6 页',
    pageItems: [],
    tests: [
      { id: 'device', name: '01 设备信息', speak: '设备信息', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'navigator 身份 / 版本 / 语言 / 地区' },
      { id: 'display', name: '02 显示', speak: '显示', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '视口 / 渲染开关 / 连续重绘' },
      { id: 'cpu', name: '03 算力', speak: '算力', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'JS 数学循环吞吐' },
      { id: 'crypto', name: '04 加密', speak: '加密', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '随机数 + SHA-256 摘要' },
      { id: 'storage', name: '05 存储', speak: '存储', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'localStorage + wx 同步存储读写' },
      { id: 'netinfo', name: '06 网络信息', speak: '网络信息', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '在线状态 / 连接类型与质量' },
      { id: 'fetch', name: '07 网络请求', speak: '网络请求', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'HTTPS 请求往返（example.com）' },
      { id: 'canvas', name: '08 画布', speak: '画布', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'Canvas 2D 绘制 + flush' },
      { id: 'barcode', name: '09 条码', speak: '条码', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'BarcodeDetector 支持格式' },
      { id: 'audio', name: '10 音频播放', speak: '音频播放', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'Web Audio 振荡器（扬声器）' },
      { id: 'mic', name: '11 麦克风', speak: '麦克风', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '四种官方模式探测 + 0.9 秒录音' },
      { id: 'camera', name: '12 相机', speak: '相机', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '三种官方模式拍照 + 实际像素' },
      { id: 'accel', name: '13 加速度', speak: '加速度', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '加速度计读数' },
      { id: 'gyro', name: '14 陀螺与方向', speak: '陀螺与方向', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '陀螺仪 + 绝对方向四元数' },
      { id: 'geo', name: '15 定位', speak: '定位', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '单次定位 + 精度' },
      { id: 'ble', name: '16 蓝牙', speak: '蓝牙', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'BLE 可用性 + 已知设备数' },
      { id: 'battery', name: '17 电池', speak: '电池', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '电量 + 充电状态（不支持时跳过）' },
      { id: 'tts', name: '18 语音合成', speak: '语音合成', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'synthesize 生成（每项结果都会语音播报）' },
      { id: 'asr', name: '19 语音识别', speak: '语音识别', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '识别能力查询' },
      { id: 'llm', name: '20 大模型', speak: '大模型', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'LanguageModel 可用性 + 短推理' },
      { id: 'interaction', name: '21 交互', speak: '交互', status: 'MANUAL', cls: 'st st-manual', msText: '-', detail: '开始后按语音提示做 6 个动作' },
      { id: 'eyetrack', name: '22 眼动追踪', speak: '眼动追踪', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '边界：平台无眼动追踪 API，恒跳过' },
      { id: 'ocr', name: '23 文字识别', speak: '文字识别', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '边界：平台无 OCR API，恒跳过' }
    ]
  },

  onLoad() {
    this._runEndAt = 0;
    var line = '-';
    try {
      var ink = (navigator.versions && navigator.versions.ink) || '?';
      line = 'ink ' + ink + ' · ' + (navigator.language || '-') + ' · ' +
        window.innerWidth + 'x' + window.innerHeight;
    } catch (e) { line = 'navigator n/a'; }
    this.setData({ deviceLine: line });
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._syncPage();
  },

  // Temple input model (v2): one button only. Tap (Enter / GlobalHook) or a
  // nod starts the run; swipes (ArrowUp/Down) flip result pages instead of
  // scrolling. Double-tap (Backspace) stays with the host.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowDown') { this._clearSelection(); this._setPage(1); }
    else if (code === 'ArrowUp') { this._clearSelection(); this._setPage(-1); }
    else if (code === 'Enter' || code === 'GlobalHook') {
      this._guideTap = true;
      this._primary();
    }
  },
  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },
  // Nod NEVER starts a run: a nod after a run ends used to restart the whole
  // run by itself (the v2.0.0 "won't stop" bug). Outside the guided
  // interaction stage, a nod selects the next FAILED item for re-test.
  onHeadGesture(event) {
    if (event && event.gesture === 'nod') {
      this._guideNod = true;
      if (!this.data.running) this._selectNextFailed();
    }
  },
  onOrientationStabilityChange(event) {
    if (event && event.stable) this.setData({ lastEvent: 'EVT: 头部已稳定' });
  },

  onPrimary() { this._primary(); },

  _primary() {
    if (this.data.running) return;
    // Debounce: a temple tap can be delivered twice (Enter + GlobalHook) and
    // a queued event can land just after a run ends; without this the
    // finished run restarts by itself.
    if (this._runEndAt && Date.now() - this._runEndAt < 2000) return;
    if (this.data.selId) this._rerunSelected();
    else this.runAll();
  },

  _refreshRunLabel() {
    var label = '开始测试';
    if (this.data.running) label = '测试中…';
    else if (this.data.selId) {
      var item = null;
      for (var i = 0; i !== this.data.tests.length; i++) {
        if (this.data.tests[i].id === this.data.selId) { item = this.data.tests[i]; break; }
      }
      label = item ? ('重测 ' + item.speak) : '重新测试';
    } else if (this.data.hasRun) label = '重新测试';
    this.setData({ runLabel: label });
  },

  _clearSelection() {
    if (!this.data.selId) return;
    this.setData({ selId: null });
    this._syncPage();
    this._refreshRunLabel();
  },

  // Failed-item re-test selection: nod cycles through FAILED items only
  // (wrapping), the page follows the selection, and a tap re-runs it.
  _selectNextFailed() {
    var failed = [];
    for (var i = 0; i !== this.data.tests.length; i++) {
      if (this.data.tests[i].status === 'FAIL') failed.push(this.data.tests[i]);
    }
    if (!failed.length) {
      this.setData({ lastEvent: '无失败项可重测' });
      this._announce('没有失败项');
      return;
    }
    var idx = -1;
    for (var j = 0; j !== failed.length; j++) {
      if (failed[j].id === this.data.selId) { idx = j; break; }
    }
    var next = failed[(idx + 1) % failed.length];
    this.setData({ selId: next.id });
    for (var k = 0; k !== this.data.tests.length; k++) {
      if (this.data.tests[k].id === next.id) { this.setData({ page: Math.floor(k / PAGE_SIZE) }); break; }
    }
    this._syncPage();
    this._refreshRunLabel();
    this.setData({ lastEvent: '已选中：' + next.name + ' · 单击重测' });
    this._announce('已选中' + next.speak + '，单击镜腿重测');
  },

  _pages() { return Math.ceil(this.data.tests.length / PAGE_SIZE); },

  _syncPage(list) {
    var tests = list || this.data.tests;
    var pages = Math.ceil(tests.length / PAGE_SIZE);
    var page = this.data.page;
    if (page < 0) page = 0;
    if (page > pages - 1) page = pages - 1;
    var self = this;
    var items = tests.slice(page * PAGE_SIZE, page * PAGE_SIZE + PAGE_SIZE).map(function (t) {
      return { id: t.id, name: t.name, speak: t.speak, status: t.status, cls: t.cls,
        msText: t.msText, detail: t.detail, selCls: t.id === self.data.selId ? 'row-sel' : '' };
    });
    this.setData({
      page: page,
      pageItems: items,
      pageText: '第 ' + (page + 1) + '/' + pages + ' 页'
    });
  },

  _setPage(dir) {
    var page = this.data.page + dir;
    if (page < 0) page = 0;
    if (page > this._pages() - 1) page = this._pages() - 1;
    if (page === this.data.page) return;
    this.setData({ page: page });
    this._syncPage();
    this.setData({ lastEvent: '翻页：' + this.data.pageText + ' · 点头选失败项，单击重测' });
  },

  _setTest(id, patch) {
    var list = this.data.tests.map(function (t) {
      if (t.id !== id) return t;
      var n = { id: t.id, name: t.name, speak: t.speak, status: t.status, cls: t.cls, msText: t.msText, detail: t.detail, selCls: t.selCls || '' };
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
      summary: (this.data.running ? '运行中 · 已完成 ' : '已完成 ') + done + '/' + list.length +
        ' · 通过 ' + pass + ' · 失败 ' + fail + ' · 跳过 ' + skip
    });
    this._syncPage(list);
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

  // Voice feedback: every finished item is announced once (queued TTS).
  _announce(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text));
    } catch (e) { /* announcements must never break the run */ }
  },

  _announceResult(id, status) {
    var item = null;
    for (var i = 0; i !== this.data.tests.length; i++) {
      if (this.data.tests[i].id === id) { item = this.data.tests[i]; break; }
    }
    if (!item) return;
    if (id === 'eyetrack') { this._announce('眼动追踪，平台没有这个 API，跳过'); return; }
    if (id === 'ocr') { this._announce('文字识别，平台没有 OCR API，跳过'); return; }
    var word = status === 'PASS' ? '通过' : (status === 'FAIL' ? '失败' : '跳过');
    this._announce(item.speak + '，' + word);
  },

  async runAll() {
    if (this.data.running) return;
    this.setData({ running: true, selId: null, lastEvent: '开始测试…' });
    this._syncPage();
    this._refreshRunLabel();
    this._announce('开始测试，共二十三项');
    var ids = ['device', 'display', 'cpu', 'crypto', 'storage', 'netinfo', 'fetch',
      'canvas', 'barcode', 'audio', 'mic', 'camera', 'accel', 'gyro', 'geo', 'ble',
      'battery', 'tts', 'asr', 'llm', 'interaction', 'eyetrack', 'ocr'];
    for (var i = 0; i !== ids.length; i++) {
      var r = await this._runOne(ids[i]);
      this._announceResult(ids[i], r.status);
    }
    this._runEndAt = Date.now();
    this.setData({ running: false, hasRun: true, lastEvent: '全部完成 · 滑动翻页查看，点头选失败项' });
    this._setTest('ocr', {});
    this._refreshRunLabel();
    var pass = 0, fail = 0, skip = 0;
    this.data.tests.forEach(function (t) {
      if (t.status === 'PASS') pass++;
      else if (t.status === 'FAIL') fail++;
      else if (t.status === 'SKIP') skip++;
    });
    this._announce('全部完成。通过' + pass + '项，失败' + fail + '项，跳过' + skip + '项');
  },

  // Re-run exactly one selected failed item; a pass clears the selection so
  // the next tap goes back to full re-test, a repeated fail keeps it selected.
  async _rerunSelected() {
    var id = this.data.selId;
    if (!id || this.data.running) return;
    this.setData({ running: true });
    this._refreshRunLabel();
    this.setData({ lastEvent: '重测：' + id });
    var r = await this._runOne(id);
    this._announceResult(id, r.status);
    this._runEndAt = Date.now();
    this.setData({ running: false });
    if (r.status !== 'FAIL') this.setData({ selId: null });
    this._setTest(id, {});
    this._refreshRunLabel();
  },

  async _runOne(id) {
    var t0 = performance.now();
    this._setTest(id, { status: 'RUN', msText: '...', detail: '测试中…' });
    try {
      var r = await this._dispatch(id);
      var ms = Math.round(performance.now() - t0);
      this._setTest(id, { status: r.status, msText: ms + 'ms', detail: r.detail });
      this._followItem(id);
      this.setData({ lastEvent: '已完成：' + id + ' · ' + r.status });
      return r;
    } catch (e) {
      var ms2 = Math.round(performance.now() - t0);
      var detail = this._err(e);
      this._setTest(id, { status: 'FAIL', msText: ms2 + 'ms', detail: detail });
      this._followItem(id);
      this.setData({ lastEvent: '已完成：' + id + ' · FAIL' });
      return { status: 'FAIL', detail: detail };
    }
  },

  _followItem(id) {
    // While running, the result pages auto-follow the newest finished item.
    if (!this.data.running) return;
    for (var i = 0; i !== this.data.tests.length; i++) {
      if (this.data.tests[i].id === id) {
        var page = Math.floor(i / PAGE_SIZE);
        if (page !== this.data.page) { this.setData({ page: page }); this._syncPage(); }
        return;
      }
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
      case 'barcode': return this._tBarcode();
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
      case 'interaction': return this._tInteract();
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

  async _tBarcode() {
    if (typeof BarcodeDetector === 'undefined') return { status: 'SKIP', detail: 'BarcodeDetector n/a' };
    var formats = await BarcodeDetector.getSupportedFormats();
    return {
      status: 'PASS',
      detail: formats.length + ' formats · ' + formats.slice(0, 3).join(',')
    };
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

  _sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); },

  _angDiff(a, b) {
    var d = a - b;
    while (d > Math.PI) d -= Math.PI * 2;
    while (d < -Math.PI) d += Math.PI * 2;
    return d;
  },

  _waitStage(checkFn, timeoutMs) {
    var t0 = Date.now();
    var self = this;
    return new Promise(function (resolve) {
      var iv = setInterval(function () {
        var ok = false;
        try { ok = checkFn(); } catch (e) {}
        if (ok) { clearInterval(iv); resolve(true); }
        else if (Date.now() - t0 > timeoutMs) { clearInterval(iv); resolve(false); }
      }, 150);
      self._stageIv = iv;
    });
  },

  // Guided interaction test: items that need the wearer cannot be checked
  // passively, so the agent prompts by voice (and on screen) and verifies
  // each action from the orientation sensor / gesture / key events:
  // turn head left, turn right, look up, look down, nod, tap the temple.
  // Directions are judged relative to each stage's start pose and the two
  // turn stages must be in opposite directions, so no assumption is made
  // about the sensor's yaw sign convention.
  async _tInteract() {
    var Ori = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ori) return { status: 'SKIP', detail: '方向传感器不可用，无法做引导交互测试' };
    var self = this;
    var state = { yaw: null, pitch: null };
    var sensor = new Ori({ frequency: 30 });
    sensor.addEventListener('reading', function () {
      var q = sensor.quaternion;
      if (!q) return;
      var x = q[0], y = q[1], z = q[2], w = q[3];
      state.yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
      var s = 2 * (w * x - y * z);
      state.pitch = s >= 1 ? Math.PI / 2 : (s <= -1 ? -Math.PI / 2 : Math.asin(s));
    });
    sensor.addEventListener('error', function () {});
    sensor.start();
    try {
      var t0 = Date.now();
      while (state.yaw === null && Date.now() - t0 < 3000) await this._sleep(120);
      if (state.yaw === null) return { status: 'SKIP', detail: '方向传感器无读数，无法做引导交互测试' };

      var marks = [];
      var prompt = async function (idx, text) {
        self._setTest('interaction', { detail: '引导 ' + idx + '/6：' + text });
        self.setData({ lastEvent: '请按语音提示操作：' + text });
        self._announce(text);
        await self._sleep(600);
      };

      // 1-2: turn head left, then right (opposite directions required)
      var y0 = state.yaw, d1 = 0;
      await prompt(1, '请向左转头');
      var ok1 = await this._waitStage(function () {
        d1 = self._angDiff(state.yaw, y0);
        return Math.abs(d1) >= 0.35;
      }, 12000);
      marks.push('左转' + (ok1 ? '✓' : '✗'));
      var y1 = state.yaw, dir1 = d1 >= 0 ? 1 : -1, d2 = 0;
      await prompt(2, '请向右转头');
      var ok2 = await this._waitStage(function () {
        d2 = self._angDiff(state.yaw, y1);
        return Math.abs(d2) >= 0.35 && (d2 >= 0 ? 1 : -1) === -dir1;
      }, 12000);
      marks.push('右转' + (ok2 ? '✓' : '✗'));

      // 3-4: look up, then down (opposite pitch directions required)
      var p0 = state.pitch, dp1 = 0;
      await prompt(3, '请抬头');
      var ok3 = await this._waitStage(function () {
        dp1 = self._angDiff(state.pitch, p0);
        return Math.abs(dp1) >= 0.22;
      }, 12000);
      marks.push('抬头' + (ok3 ? '✓' : '✗'));
      var p1 = state.pitch, pdir = dp1 >= 0 ? 1 : -1, dp2 = 0;
      await prompt(4, '请低头');
      var ok4 = await this._waitStage(function () {
        dp2 = self._angDiff(state.pitch, p1);
        return Math.abs(dp2) >= 0.22 && (dp2 >= 0 ? 1 : -1) === -pdir;
      }, 12000);
      marks.push('低头' + (ok4 ? '✓' : '✗'));

      // 5: nod (host head-gesture event)
      this._guideNod = false;
      await prompt(5, '请点头确认');
      var ok5 = await this._waitStage(function () { return self._guideNod === true; }, 12000);
      marks.push('点头' + (ok5 ? '✓' : '✗'));

      // 6: temple tap (Enter / GlobalHook key event)
      this._guideTap = false;
      await prompt(6, '请单击镜腿');
      var ok6 = await this._waitStage(function () { return self._guideTap === true; }, 12000);
      marks.push('单击' + (ok6 ? '✓' : '✗'));

      var done = marks.filter(function (m) { return m.indexOf('✓') >= 0; }).length;
      return {
        status: done === 6 ? 'PASS' : 'FAIL',
        detail: ('完成 ' + done + '/6：' + marks.join(' ')).slice(0, 72)
      };
    } finally {
      try { sensor.stop(); } catch (e) {}
    }
  },

  // Platform boundary items: these capabilities do NOT exist in the official
  // AIUI API surface, so they can never PASS. They are listed so the report
  // states the boundary explicitly instead of implying coverage.
  async _tNoApi(kind) {
    if (kind === 'eye') {
      return {
        status: 'SKIP',
        detail: '平台无眼动追踪 API · 凝视=头部朝向（见 14/21）'
      };
    }
    return {
      status: 'SKIP',
      detail: '平台无 OCR API · 读文字=长焦拍照+大模型（见 12/20）'
    };
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">眼镜全功能自检</text>
      <text class="summary">{{summary}}</text>
      <text class="sub">{{deviceLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="onPrimary">{{runLabel}}</button>
    </view>
    <canvas id="benchCanvas" width="448" height="40" class="bench-canvas"></canvas>
    <view class="list">
      <view ink:for="{{pageItems}}" class="row {{item.selCls}}">
        <view class="row-top">
          <text class="name">{{item.name}}</text>
          <text class="{{item.cls}}">{{item.status}}</text>
          <text class="ms">{{item.msText}}</text>
        </view>
        <text class="detail">{{item.detail}}</text>
      </view>
    </view>
    <view class="foot-row">
      <text class="foot">{{lastEvent}}</text>
      <text class="page-num">{{pageText}}</text>
      <text class="ver">{{appVersion}}</text>
    </view>
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
  margin-bottom: 8px;
}
.btn {
  flex-grow: 1;
  color: #40ff5e;
  border: 1px solid #40ff5e;
  border-radius: 4px;
  padding: 8px;
  font-size: 14px;
  font-weight: 500;
  line-height: 18px;
  text-align: center;
  background-color: rgba(64,255,94,0.18);
}
.bench-canvas {
  width: 448px;
  height: 40px;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 2px;
  margin-bottom: 8px;
}
.list {
  height: 158px;
  display: flex;
  flex-direction: column;
}
.row {
  display: flex;
  flex-direction: column;
  padding: 5px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.row-sel {
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
.foot-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-top: 6px;
}
.foot {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.page-num {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-right: 10px;
}
.ver {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  text-align: right;
}
</style>
