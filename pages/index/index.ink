<script def>
{
  "navigationBarTitleText": "Gaze Translate"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT TEXT - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still to confirm gaze',
    langLabel: 'EN',
    langName: 'English',
    captureLine: 'CAPTURE: not taken yet',
    sourceText: '本日のおすすめ：炭火焼き鳥盛り合わせ 1,280円',
    resultText: 'Tap DEMO to translate the sample, or CAPTURE on the glasses.',
    resultSource: 'RESULT SOURCE: none',
    lastEvent: 'EVT: nod when steady = capture / ArrowUp-Down = language',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this.setData({ lastEvent: 'EVT: look at the text and hold your head still' });
  },

  onUnload() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({
        steadyText: 'HEAD STEADY — ready',
        status: 'HEAD STEADY — ready: nod or tap CAPTURE'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still to confirm gaze',
        status: 'LOOK AT TEXT - HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g === 'nod') {
      if (this._steady) {
        this.captureAndTranslate();
      } else {
        this.setData({ status: 'NOD IGNORED - hold head steady first' });
      }
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.cycleLang(code === 'ArrowUp' ? -1 : 1);
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      this.captureAndTranslate();
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

  _langs() {
    return [
      { label: 'EN', name: 'English' },
      { label: '日本語', name: 'Japanese' },
      { label: '中文', name: 'Chinese' }
    ];
  },

  _langIndex() {
    var langs = this._langs();
    for (var i = 0; i !== langs.length; i++) {
      if (langs[i].label === this.data.langLabel) return i;
    }
    return 0;
  },

  cycleLang(step) {
    var langs = this._langs();
    var next = (this._langIndex() + (step || 1) + langs.length) % langs.length;
    this.setData({
      langLabel: langs[next].label,
      langName: langs[next].name,
      lastEvent: 'EVT: target language -> ' + langs[next].label
    });
  },

  langTap() { this.cycleLang(1); },

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

  _sampleSource() {
    // OCR placeholder: the AIUI runtime exposes no OCR API, so after a real
    // photo is taken this built-in sample text stands in for the recognized
    // text. The UI labels it as a sample / OCR placeholder, never as OCR.
    return '本日のおすすめ：炭火焼き鳥盛り合わせ 1,280円';
  },

  _dict() {
    return [
      {
        src: '本日のおすすめ：炭火焼き鳥盛り合わせ 1,280円',
        EN: "Today's special: charcoal-grilled yakitori platter - 1,280 yen",
        '日本語': '本日のおすすめ：炭火焼き鳥盛り合わせ 1,280円',
        '中文': '今日推荐：炭火烤鸡肉串拼盘，1280 日元'
      },
      {
        src: '出口はこちら',
        EN: 'The exit is this way',
        '日本語': '出口はこちら',
        '中文': '出口在这边'
      },
      {
        src: 'お会計をお願いします',
        EN: 'The check, please',
        '日本語': 'お会計をお願いします',
        '中文': '请结账'
      },
      {
        src: '辛いのでご注意ください',
        EN: 'Caution: this dish is spicy',
        '日本語': '辛いのでご注意ください',
        '中文': '请注意：这道菜很辣'
      },
      {
        src: '営業時間 11:00-22:00',
        EN: 'Opening hours: 11:00-22:00',
        '日本語': '営業時間 11:00-22:00',
        '中文': '营业时间：11:00-22:00'
      },
      {
        src: '禁煙',
        EN: 'No smoking',
        '日本語': '禁煙',
        '中文': '禁止吸烟'
      }
    ];
  },

  _dictLookup(text) {
    var dict = this._dict();
    for (var i = 0; i !== dict.length; i++) {
      if (text === dict[i].src || text.indexOf(dict[i].src) !== -1) {
        return dict[i][this.data.langLabel] || null;
      }
    }
    return null;
  },

  async _translate(text) {
    // 1) On-device LLM, when the host provides LanguageModel.
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (LM) {
      try {
        var avail = await LM.availability();
        if (avail === 'available') {
          var session = await LM.create({
            initialPrompts: [{ role: 'system', content: 'You are a concise translator. Reply with the translation only.' }]
          });
          try {
            var ans = await this._withTimeout(
              session.prompt('Translate the following text into ' + this.data.langName + '. Reply with the translation only.\nText: ' + text),
              25000, 'llm');
            if (ans && String(ans).trim()) {
              return { text: String(ans).trim(), source: 'LLM' };
            }
          } finally {
            try { session.destroy(); } catch (e) {}
          }
        }
      } catch (e) { /* fall through to the offline dictionary */ }
    }
    // 2) Built-in offline dictionary for common menu / sign phrases.
    var hit = this._dictLookup(text);
    if (hit) return { text: hit, source: 'offline dictionary' };
    // 3) Honest failure: no source could translate this text.
    return {
      text: 'No translation available for this text (LLM unavailable, phrase not in offline dictionary).',
      source: 'none'
    };
  },

  async _runPipeline(text, sourceNote) {
    this.setData({ status: 'TRANSLATING...', sourceText: text });
    var r = await this._translate(text);
    this.setData({
      resultText: r.text,
      resultSource: 'RESULT SOURCE: ' + r.source,
      status: 'DONE - tap SPEAK to hear it',
      lastEvent: 'EVT: translated (' + r.source + ') ' + (sourceNote || '')
    });
    return r;
  },

  async demoTap() {
    if (this.data.busy) return;
    this.setData({ busy: true, captureLine: 'CAPTURE: DEMO sample (no camera used)' });
    try {
      await this._runPipeline(this._sampleSource(), '- demo sample phrase');
    } catch (e) {
      this.setData({
        resultText: 'Translation failed: ' + this._err(e),
        resultSource: 'RESULT SOURCE: none',
        status: 'FAIL - see result'
      });
    } finally {
      this.setData({ busy: false });
    }
  },

  captureTap() { this.captureAndTranslate(); },

  async captureAndTranslate() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        captureLine: 'CAPTURE: FAIL - mediaDevices n/a on this host',
        status: 'CAPTURE FAIL - no camera on this host, no photo taken',
        resultText: 'Capture failed: mediaDevices unavailable on this host. No photo was taken and no OCR was performed.',
        resultSource: 'RESULT SOURCE: none',
        lastEvent: 'EVT: capture FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'CAPTURING (telephoto)...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var photoBytes = 0;
      var modeText = 'telephoto';
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        captureLine: 'CAPTURE: photo ' + photoBytes + 'B - mode ' + modeText,
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B, translating placeholder text'
      });
      // No OCR API exists in this runtime: translate the honestly labeled
      // OCR placeholder / sample text, never a claimed OCR result.
      await this._runPipeline(this._sampleSource(), '- OCR placeholder text');
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like glasses-benchmark.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          captureLine: 'CAPTURE: wx photo ' + size + 'B (ImageCapture fallback)',
          lastEvent: 'EVT: wx photo ' + size + 'B, translating placeholder text'
        });
        await this._runPipeline(this._sampleSource(), '- OCR placeholder text');
      } catch (e2) {
        this.setData({
          captureLine: 'CAPTURE: FAIL - ' + this._err(firstErr),
          status: 'CAPTURE FAIL - no photo taken',
          resultText: 'Capture failed: ' + this._err(firstErr) + '. No photo was taken and no OCR was performed.',
          resultSource: 'RESULT SOURCE: none',
          lastEvent: 'EVT: capture FAIL'
        });
      }
    } finally {
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
  },

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text = this.data.resultText || '';
      if (!text || this.data.resultSource === 'RESULT SOURCE: none') {
        this.setData({ lastEvent: 'EVT: nothing to speak yet - run DEMO or CAPTURE first' });
        return;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - listen for the translation' });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">GAZE TRANSLATE</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
      <text class="sub">TARGET: {{langLabel}} ({{langName}}) · MODE: telephoto</text>
    </view>
    <view class="gaze-box">
      <text class="gaze-label">◎ GAZE TARGET · SOURCE (sample / OCR placeholder)</text>
      <text class="source">{{sourceText}}</text>
      <text class="capture">{{captureLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="captureTap">CAPTURE</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="langTap">LANG: {{langLabel}}</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="result-box">
      <text class="result-label">TRANSLATION</text>
      <text class="result">{{resultText}}</text>
      <text class="capture">{{resultSource}}</text>
    </view>
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
.gaze-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 8px 10px;
  margin-bottom: 8px;
}
.gaze-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.source {
  color: #40ff5e;
  font-size: 14px;
  line-height: 19px;
  margin-top: 2px;
}
.capture {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
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
.result-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 8px 10px;
}
.result-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.result {
  color: rgba(64,255,94,0.72);
  font-size: 13px;
  line-height: 18px;
  margin-top: 2px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 6px;
}
</style>
