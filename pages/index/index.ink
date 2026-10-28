<script def>
{
  "navigationBarTitleText": "视频流探针"
}
</script>

<script setup>
export default {
  data: {
    summary: '就绪 · 共 3 项 · 约 2 分半',
    appVersion: 'v1.0.1',
    deviceLine: '-',
    lastEvent: '单击镜腿开始 · 运行中单击=中止当前项',
    liveLine: 'LIVE: -',
    running: false,
    runLabel: '开始探测',
    hasRun: false,
    tests: [
      { id: 'stream', name: '01 持续取流', speak: '持续取流', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'getUserMedia 视频流 60 秒 · grabFrame 抓帧率 / 最大间隔 / 电量' },
      { id: 'record', name: '02 持续录制', speak: '持续录制', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: 'MediaRecorder 录像 30 秒 · 分片数 / 总字节 / 折算 MB 每分钟' },
      { id: 'vision', name: '03 抓帧问大模型', speak: '抓帧问大模型', status: 'WAIT', cls: 'st st-wait', msText: '-', detail: '3 轮：抓帧→编码→LLM 图片输入 · 抓帧/编码/推理分段耗时' }
    ]
  },

  onLoad() {
    this._runEndAt = 0;
    this._stopFlag = false;
    this._lastKeyAt = 0;
    var line = '-';
    try {
      var ink = (navigator.versions && navigator.versions.ink) || '?';
      line = 'ink ' + ink + ' · ' + (navigator.language || '-') + ' · ' +
        window.innerWidth + 'x' + window.innerHeight;
    } catch (e) { line = 'navigator n/a'; }
    this.setData({ deviceLine: line });
  },

  // Temple model: tap starts when idle; tap while running stops the
  // current item (honest partial). Duplicate Enter+GlobalHook delivery
  // is debounced, and taps within 2s after a run ends are ignored so a
  // finished run can never restart itself (glasses-benchmark v2 lesson).
  onKeyDown(event) {
    var code = event && event.code;
    if (code !== 'Enter' && code !== 'GlobalHook') return;
    var now = Date.now();
    if (now - this._lastKeyAt < 400) return;
    this._lastKeyAt = now;
    this._primary();
  },
  onHeadGesture(event) {
    // Nod never starts or stops anything in this probe.
    if (event && event.gesture === 'nod') {
      this.setData({ lastEvent: 'EVT: 点头已收到（探针中不触发动作）' });
    }
  },

  onPrimary() { this._primary(); },

  _primary() {
    if (this.data.running) { this._stopFlag = true; return; }
    if (this._runEndAt && Date.now() - this._runEndAt < 2000) return;
    this.runAll();
  },

  _refreshRunLabel() {
    var label = '开始探测';
    if (this.data.running) label = '探测中 · 单击中止当前项';
    else if (this.data.hasRun) label = '重新探测';
    this.setData({ runLabel: label });
  },

  _setTest(id, patch) {
    var list = this.data.tests.map(function (t) {
      if (t.id !== id) return t;
      var n = { id: t.id, name: t.name, speak: t.speak, status: t.status, cls: t.cls, msText: t.msText, detail: t.detail };
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

  _sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); },

  _announce(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text));
    } catch (e) { /* announcements must never break the run */ }
  },

  async _batteryLevel() {
    try {
      if (!navigator.getBattery) return null;
      var b = await navigator.getBattery();
      return Math.round(b.level * 100);
    } catch (e) { return null; }
  },

  // One video stream per item, always released in finally. Constraints
  // are ideals: if the host rejects them, fall back to {video:true}
  // and say so in the result line.
  async _openStream() {
    var fallback = false;
    var stream = null;
    try {
      stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 640 }, height: { ideal: 480 }, frameRate: { ideal: 30 } }
      }), 9000, 'camera ideal');
    } catch (e) {
      fallback = true;
      stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
    }
    var track = stream.getVideoTracks()[0];
    if (!track) {
      stream.getTracks().forEach(function (t) { t.stop(); });
      throw new Error('no video track');
    }
    var s = {};
    try { s = track.getSettings() || {}; } catch (e) {}
    return { stream: stream, track: track, settings: s, fallback: fallback };
  },

  _stopStream(o) {
    if (o && o.stream) {
      try { o.stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
    }
  },

  async runAll() {
    if (this.data.running) return;
    this._stopFlag = false;
    this.setData({ running: true, lastEvent: '开始探测…' });
    this._refreshRunLabel();
    this._announce('开始探测，共三项，约两分半钟');
    var ids = ['stream', 'record', 'vision'];
    var words = { stream: '持续取流', record: '持续录制', vision: '抓帧问大模型' };
    for (var i = 0; i !== ids.length; i++) {
      var r = await this._runOne(ids[i]);
      var word = r.status === 'PASS' ? '通过' : (r.status === 'FAIL' ? '失败' : '跳过');
      this._announce(words[ids[i]] + '，' + word);
    }
    this._runEndAt = Date.now();
    this.setData({ running: false, hasRun: true, lastEvent: '全部完成 · 结果即真机实测值，截图留档' });
    this._setTest('vision', {});
    this._refreshRunLabel();
    var pass = 0, fail = 0, skip = 0;
    this.data.tests.forEach(function (t) {
      if (t.status === 'PASS') pass++;
      else if (t.status === 'FAIL') fail++;
      else if (t.status === 'SKIP') skip++;
    });
    this._announce('探测完成。通过' + pass + '项，失败' + fail + '项，跳过' + skip + '项');
  },

  async _runOne(id) {
    var t0 = performance.now();
    this._setTest(id, { status: 'RUN', msText: '...', detail: '探测中…' });
    try {
      var r = await this._dispatch(id);
      var ms = Math.round(performance.now() - t0);
      this._setTest(id, { status: r.status, msText: Math.round(ms / 100) / 10 + 's', detail: r.detail });
      this.setData({ lastEvent: '已完成：' + id + ' · ' + r.status });
      return r;
    } catch (e) {
      var ms2 = Math.round(performance.now() - t0);
      var detail = this._err(e);
      this._setTest(id, { status: 'FAIL', msText: Math.round(ms2 / 100) / 10 + 's', detail: detail });
      this.setData({ lastEvent: '已完成：' + id + ' · FAIL' });
      return { status: 'FAIL', detail: detail };
    }
  },

  _dispatch(id) {
    if (id === 'stream') return this._tStream();
    if (id === 'record') return this._tRecord();
    return this._tVision();
  },

  // Item 1: sustained stream, 60s. Measures the grabFrame rate the
  // agent actually gets (NOT the sensor fps), the longest gap between
  // frames, grab failures, and battery drain over the run.
  async _tStream() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      return { status: 'SKIP', detail: 'mediaDevices n/a on this host' };
    }
    if (typeof ImageCapture === 'undefined') {
      return { status: 'SKIP', detail: 'ImageCapture n/a · 无法 grabFrame 计量' };
    }
    var o = await this._openStream();
    var bat0 = await this._batteryLevel();
    try {
      var cap = new ImageCapture(o.track);
      var DUR = 60000;
      var t0 = Date.now();
      var lastOk = t0;
      var lastUi = 0;
      var frames = 0, fails = 0, maxGap = 0;
      this._stopFlag = false;
      while (Date.now() - t0 < DUR && !this._stopFlag) {
        try {
          var bmp = await cap.grabFrame();
          var now1 = Date.now();
          var gap = now1 - lastOk;
          if (frames > 0 && gap > maxGap) maxGap = gap;
          lastOk = now1;
          frames++;
          if (bmp && bmp.close) { try { bmp.close(); } catch (e) {} }
        } catch (e) {
          fails++;
          await this._sleep(30);
        }
        if (Date.now() - lastUi > 1000) {
          lastUi = Date.now();
          var el = Math.round((lastUi - t0) / 1000);
          this.setData({ liveLine: 'LIVE 取流 ' + el + 's · ' + frames + ' 帧 · ' +
            (el > 0 ? Math.round(frames / el * 10) / 10 : 0) + ' fps(抓帧)' });
        }
      }
      var elapsed = (Date.now() - t0) / 1000;
      var bat1 = await this._batteryLevel();
      var fps = Math.round(frames / Math.max(elapsed, 0.1) * 10) / 10;
      var batText = (bat0 !== null && bat1 !== null) ? ' · 电量 ' + bat0 + '%→' + bat1 + '%' : '';
      var partial = elapsed < 59 ? ' · 中止于 ' + Math.round(elapsed) + 's(部分)' : '';
      if (!frames) throw new Error('grabFrame 0 frames');
      return {
        status: 'PASS',
        detail: ('流 ' + (o.settings.width || '?') + 'x' + (o.settings.height || '?') + '@' +
          (o.settings.frameRate || '?') + (o.fallback ? '(回退约束)' : '') +
          ' · 抓帧 ' + frames + ' · ' + fps + 'fps · 最大间隔 ' + maxGap + 'ms · 失败 ' + fails +
          batText + partial).slice(0, 110)
      };
    } finally {
      this._stopStream(o);
      this.setData({ liveLine: 'LIVE: -' });
    }
  },

  // Item 2: sustained recording, 30s via MediaRecorder with 1s
  // timeslice. Counts chunks and bytes, extrapolates MB/min. Blobs
  // stay in memory and are discarded - nothing is persisted (the
  // platform has no general file API; that is part of the finding).
  async _tRecord() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      return { status: 'SKIP', detail: 'mediaDevices n/a on this host' };
    }
    if (typeof MediaRecorder === 'undefined') {
      return { status: 'SKIP', detail: 'MediaRecorder n/a on this host' };
    }
    var mime = '';
    var candidates = ['video/mp4', 'video/webm;codecs=vp8,opus'];
    for (var i = 0; i !== candidates.length; i++) {
      try {
        if (MediaRecorder.isTypeSupported(candidates[i])) { mime = candidates[i]; break; }
      } catch (e) {}
    }
    if (!mime) return { status: 'SKIP', detail: '无受支持的视频编码（mp4/webm 均不支持）' };
    var o = await this._openStream();
    try {
      var rec = new MediaRecorder(o.stream, { mimeType: mime });
      var chunks = 0, bytes = 0, errors = 0;
      var self = this;
      rec.addEventListener('dataavailable', function (e) {
        if (e.data && e.data.size) { chunks++; bytes += e.data.size; }
      });
      rec.addEventListener('error', function () { errors++; });
      var stopped = new Promise(function (r) { rec.addEventListener('stop', r); });
      var t0 = Date.now();
      rec.start(1000);
      this._stopFlag = false;
      while (Date.now() - t0 < 30000 && !this._stopFlag) {
        await this._sleep(1000);
        var el2 = Math.round((Date.now() - t0) / 1000);
        this.setData({ liveLine: 'LIVE 录制 ' + el2 + 's · ' + chunks + ' 片 · ' +
          Math.round(bytes / 1024) + 'KB' });
      }
      try { rec.stop(); } catch (e) {}
      await this._withTimeout(stopped, 5000, 'rec stop');
      var sec = (Date.now() - t0) / 1000;
      if (!bytes) throw new Error('recorder produced 0 bytes');
      var mbMin = Math.round(bytes / Math.max(sec, 0.1) * 60 / 1048576 * 10) / 10;
      var partial2 = sec < 29 ? ' · 中止于 ' + Math.round(sec) + 's(部分)' : '';
      return {
        status: 'PASS',
        detail: (mime.split(';')[0] + ' · ' + Math.round(sec) + 's · ' + chunks + ' 片 · ' +
          Math.round(bytes / 1024) + 'KB · 折算 ' + mbMin + 'MB/分钟 · 错误 ' + errors + partial2 +
          ' · 数据未落盘(无文件API)').slice(0, 110)
      };
    } finally {
      this._stopStream(o);
      this.setData({ liveLine: 'LIVE: -' });
    }
  },

  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005) -
    // that was this probe's original step and it can never succeed on
    // device. Documented path instead: blob.arrayBuffer() -> chunked
    // base64 via btoa, so the grabFrame path is what actually gets
    // measured; a failure here still falls back to takePhoto, labelled.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      var buf = await blob.arrayBuffer();
      var bytes = new Uint8Array(buf);
      var bin = '';
      var CH = 0x8000;
      for (var i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: ' + String((e && e.message) || e).slice(0, 40));
    }
  },

  // One vision round: try grabFrame -> Canvas(480w) -> JPEG blob
  // first (the true AR-frame path); if any step is unavailable, fall
  // back to takePhoto telephoto (the fleet-proven path) and label
  // the source so the latency numbers are never mixed silently.
  async _frameDataUrl(cap) {
    var t0 = performance.now();
    try {
      if (typeof Canvas === 'undefined') throw new Error('Canvas ctor n/a');
      var bmp = await cap.grabFrame();
      var grabMs = Math.round(performance.now() - t0);
      var w = bmp.width || 640, h = bmp.height || 480;
      var sw = 480, sh = Math.max(2, Math.round(h * 480 / w));
      var cv = new Canvas(sw, sh);
      var ctx = cv.getContext('2d');
      ctx.drawImage(bmp, 0, 0, sw, sh);
      try { bmp.close(); } catch (e) {}
      var blob = await cv.convertToBlob({ type: 'image/jpeg', quality: 0.7 });
      var encMs = Math.round(performance.now() - t0) - grabMs;
      var url = await this._blobToDataUrl(blob);
      if (url.indexOf('data:') !== 0) throw new Error('not a data url');
      return { url: url, source: 'grabFrame', grabMs: grabMs, encMs: Math.round(performance.now() - t0) - grabMs, kb: Math.round(blob.size / 1024) };
    } catch (e) {
      var t1 = performance.now();
      var blob2 = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'photo');
      var grab2 = Math.round(performance.now() - t1);
      var url2 = await this._blobToDataUrl(blob2);
      if (url2.indexOf('data:') !== 0) throw new Error('photo conversion not a data url');
      return { url: url2, source: 'takePhoto', grabMs: grab2, encMs: 0, kb: Math.round(blob2.size / 1024) };
    }
  },

  // Item 3: 3 rounds of frame -> LLM image input. Reports per-stage
  // timing (grab / encode / LLM) so the AR feasibility number is the
  // LLM round-trip, not a blended guess.
  async _tVision() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      return { status: 'SKIP', detail: 'mediaDevices n/a on this host' };
    }
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return { status: 'SKIP', detail: 'LanguageModel n/a on this host' };
    var avail = await LM.availability();
    if (avail !== 'available') return { status: 'SKIP', detail: 'LLM availability=' + avail };
    if (typeof ImageCapture === 'undefined') {
      return { status: 'SKIP', detail: 'ImageCapture n/a · 无法抓帧' };
    }
    var o = await this._openStream();
    var session = null;
    try {
      var cap = new ImageCapture(o.track);
      session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You describe camera frames for a glasses probe. Reply very briefly.' }]
      });
      var okRounds = 0;
      var llmTotal = 0, grabTotal = 0;
      var src = '-', lastAns = '';
      this._stopFlag = false;
      for (var r = 0; r !== 3; r++) {
        if (this._stopFlag) break;
        this.setData({ liveLine: 'LIVE 视觉 第 ' + (r + 1) + '/3 轮…' });
        var fr = await this._frameDataUrl(cap);
        src = fr.source;
        var lt0 = performance.now();
        var ans = await this._withTimeout(session.prompt([
          { type: 'text', text: '用一句不超过十五个字的话说出画面里最主要的东西。' },
          { type: 'image_url', image_url: { url: fr.url } }
        ]), 45000, 'llm vision');
        var llmMs = Math.round(performance.now() - lt0);
        okRounds++;
        llmTotal += llmMs;
        grabTotal += fr.grabMs;
        lastAns = String(ans || '').slice(0, 20);
        this.setData({ liveLine: 'LIVE 视觉 第 ' + (r + 1) + ' 轮 LLM ' + llmMs + 'ms · ' + lastAns });
      }
      if (!okRounds) throw new Error('0 vision rounds completed');
      var llmAvg = llmTotal / okRounds;
      var llmText = llmAvg >= 1000 ? (Math.round(llmAvg / 100) / 10 + 's') : (Math.round(llmAvg) + 'ms');
      return {
        status: 'PASS',
        detail: ('源 ' + src + ' · ' + okRounds + '/3 轮 · 抓帧均 ' + Math.round(grabTotal / okRounds) +
          'ms · LLM 均 ' + llmText + ' · 末答「' + lastAns + '」').slice(0, 110)
      };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
      this._stopStream(o);
      this.setData({ liveLine: 'LIVE: -' });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">视频流探针</text>
      <text class="summary">{{summary}}</text>
      <text class="sub">{{deviceLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="onPrimary">{{runLabel}}</button>
    </view>
    <view class="live-box">
      <text class="live">{{liveLine}}</text>
    </view>
    <view class="list">
      <view ink:for="{{tests}}" class="row">
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
  color: #7dff9e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.summary {
  color: rgba(125,255,158,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.sub {
  color: rgba(125,255,158,0.48);
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
  color: #06230d;
  border: 1px solid #7dff9e;
  border-radius: 12px;
  padding: 8px;
  font-size: 14px;
  font-weight: 500;
  line-height: 18px;
  text-align: center;
  background-color: #7dff9e;
}
.live-box {
  border: 1px dashed rgba(125,255,158,0.48);
  border-radius: 2px;
  padding: 5px 8px;
  margin-bottom: 8px;
}
.live {
  color: #7dff9e;
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.list {
  display: flex;
  flex-direction: column;
}
.row {
  display: flex;
  flex-direction: column;
  padding: 6px 0;
  border-bottom: 1px solid rgba(125,255,158,0.24);
}
.row-top {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.name {
  flex-grow: 1;
  color: rgba(125,255,158,0.85);
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
.st-wait { color: rgba(125,255,158,0.48); }
.st-run { color: #7dff9e; }
.st-pass { color: #7dff9e; }
.st-fail { color: rgba(125,255,158,0.72); }
.st-skip { color: rgba(125,255,158,0.48); }
.ms {
  color: rgba(125,255,158,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  width: 52px;
  text-align: right;
}
.detail {
  color: rgba(125,255,158,0.55);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
.foot-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-top: 8px;
}
.foot {
  flex-grow: 1;
  color: rgba(125,255,158,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.ver {
  color: rgba(125,255,158,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  text-align: right;
}
</style>
