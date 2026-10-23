<script def>
{
  "navigationBarTitleText": "Cook Along"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PICK A RECIPE - tap RECIPE, then START',
    steadyText: 'HEAD: moving - hold still',
    recipeStep: 'RECIPE 番茄炒蛋 · STEP 0/6 （备料）',
    stepBody: '备料：番茄 2 个切块，鸡蛋 3 个打散，盐、糖、葱花备齐。',
    timerLine: 'TIMER: -- (untimed step)',
    panLine: 'PAN: not checked - LOOK at the pan, then tap PAN',
    asrLine: 'ASR: tap LISTEN - say 下一步 (wearer mic)',
    lastEvent: 'EVT: nod / Enter = START or NEXT while cooking',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._recipeIdx = 0;
    this._stepIdx = 0; // 0 = ingredients, 1..n = steps
    this._started = false;
    this._done = false;
    this._panIdx = -1;
    this._recog = null;
    this._stream = null;
    this._timerId = null;
    this._remainSec = 0;
    this._renderStep();
  },

  onHide() {
    this._stopTimer();
    if (this._recog) { try { this._recog.abort(); } catch (e) {} this._recog = null; }
  },

  onUnload() {
    this._stopTimer();
    if (this._recog) { try { this._recog.abort(); } catch (e) {} this._recog = null; }
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    if (this._steady) {
      this.setData({
        steadyText: 'HEAD STEADY - ready',
        status: this._started && !this._done
          ? 'HEAD STEADY - nod = NEXT step'
          : 'HEAD STEADY - nod = START / NEXT'
      });
    } else {
      this.setData({ steadyText: 'HEAD: moving - hold still' });
    }
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    if (!this._steady) {
      this.setData({ status: 'NOD IGNORED - hold head steady first' });
      return;
    }
    if (!this._started) this.startCooking();
    else if (!this._done) this.nextStep();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (!this._started) this.startCooking();
      else if (!this._done) this.nextStep();
    } else if (code === 'ArrowUp') {
      if (!this._started) this.cycleRecipe(1);
    } else if (code === 'ArrowDown') {
      if (!this._started) this.cycleRecipe(-1);
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

  // Built-in recipes. Step 0 is the ingredients line; steps 1..n are the
  // cooking steps. `min` marks a timed step (countdown + TTS alert).
  _recipes() {
    return [
      {
        name: '番茄炒蛋',
        ing: '备料：番茄 2 个切块，鸡蛋 3 个打散，盐、糖、葱花备齐。',
        steps: [
          { t: '鸡蛋加半勺盐打散；番茄去蒂切块。' },
          { t: '热锅凉油，蛋液下锅，凝固成块立刻盛出。' },
          { t: '底油下番茄，中火炒出红汁，加半勺糖。', min: 2 },
          { t: '倒回鸡蛋，加盐，翻匀裹上番茄汁。', min: 1 },
          { t: '沿锅边淋一勺清水，大火收汁。', min: 1 },
          { t: '撒葱花，关火出锅。' }
        ]
      },
      {
        name: '青椒肉丝',
        ing: '备料：里脊 200g，青椒 2 个，姜蒜、生抽、淀粉备齐。',
        steps: [
          { t: '肉切丝，加生抽、料酒、淀粉抓匀腌制。', min: 10 },
          { t: '青椒去籽切丝，姜蒜切末备用。' },
          { t: '热锅凉油，肉丝大火滑散，变色盛出。' },
          { t: '底油爆香姜蒜，下青椒丝大火快炒。', min: 1 },
          { t: '青椒断生，倒回肉丝，加盐、生抽调味。' },
          { t: '沿锅边淋少量水，翻炒均匀。', min: 1 },
          { t: '关火出锅，趁热吃。' }
        ]
      },
      {
        name: '清水煮面',
        ing: '备料：面条 1 把，盐、生抽、香油、葱花备齐。',
        steps: [
          { t: '锅里加足量水，大火烧开。', min: 5 },
          { t: '水开下面条，用筷子拨散防粘。' },
          { t: '再次沸腾，加一碗凉水（点水）。', min: 2 },
          { t: '再点一次水，面条浮起、无白芯。', min: 2 },
          { t: '碗里放盐、生抽、香油，舀面汤冲开。' },
          { t: '捞面入碗拌匀，加葱花。' }
        ]
      }
    ];
  },

  _recipe() { return this._recipes()[this._recipeIdx]; },

  _currentStep() {
    if (this._stepIdx <= 0) return null;
    return this._recipe().steps[this._stepIdx - 1];
  },

  _fmt(sec) {
    var m = Math.floor(sec / 60);
    var s = sec % 60;
    return m + ':' + (s < 10 ? '0' : '') + s;
  },

  _stopTimer() {
    if (this._timerId !== null) {
      try { clearInterval(this._timerId); } catch (e) {}
      this._timerId = null;
    }
    this._remainSec = 0;
  },

  _timerLineForStep() {
    var st = this._currentStep();
    if (!st) return 'TIMER: -- (prep, untimed)';
    if (!st.min) return 'TIMER: -- (untimed step)';
    return 'TIMER: ' + this._fmt(st.min * 60) + ' ready - tap TIMER';
  },

  _renderStep() {
    var r = this._recipe();
    var head;
    if (this._done) head = 'RECIPE ' + r.name + ' · DONE';
    else if (!this._started) head = 'RECIPE ' + r.name + ' · STEP 0/' + r.steps.length + ' （备料）';
    else head = 'RECIPE ' + r.name + ' · STEP ' + this._stepIdx + '/' + r.steps.length;
    var body;
    if (this._done) body = '全部完成 — 趁热上菜。';
    else if (!this._started || this._stepIdx <= 0) body = r.ing;
    else body = this._currentStep().t;
    this.setData({
      recipeStep: head,
      stepBody: body,
      timerLine: this._done ? 'TIMER: -- (done)' : this._timerLineForStep()
    });
  },

  cycleRecipe(dir) {
    var n = this._recipes().length;
    this._recipeIdx = ((this._recipeIdx + dir) % n + n) % n;
    this._stepIdx = 0;
    this._started = false;
    this._done = false;
    this._stopTimer();
    this._renderStep();
    this.setData({
      status: 'RECIPE -> ' + this._recipe().name + ' - tap START',
      lastEvent: 'EVT: recipe -> ' + this._recipe().name
    });
  },

  recipeTap() {
    if (this._started && !this._done) {
      this.setData({ status: 'COOKING - RECIPE switch is locked mid-cook' });
      return;
    }
    this.cycleRecipe(1);
  },

  startCooking() {
    this._stopTimer();
    this._started = true;
    this._done = false;
    this._stepIdx = 1;
    this._renderStep();
    this.setData({
      status: 'COOKING - nod / NEXT / say 下一步',
      lastEvent: 'EVT: started ' + this._recipe().name + ' step 1'
    });
  },

  startTap() {
    if (this._started && !this._done) {
      this.setData({ status: 'ALREADY COOKING - tap NEXT' });
      return;
    }
    this.startCooking();
  },

  nextStep() {
    if (!this._started) {
      this.setData({ status: 'NOT STARTED - tap START first' });
      return;
    }
    if (this._done) {
      this.setData({ status: 'DONE - tap RECIPE for another dish' });
      return;
    }
    this._stopTimer();
    var r = this._recipe();
    if (this._stepIdx < r.steps.length) {
      this._stepIdx++;
      this.setData({ lastEvent: 'EVT: advanced to step ' + this._stepIdx });
    } else {
      this._done = true;
      this.setData({
        status: 'DONE - 上菜！well done',
        lastEvent: 'EVT: recipe finished'
      });
    }
    this._renderStep();
  },

  nextTap() { this.nextStep(); },

  timerTap() {
    if (!this._started || this._done) {
      this.setData({ status: 'TIMER: start cooking first' });
      return;
    }
    var st = this._currentStep();
    if (!st || !st.min) {
      this.setData({ status: 'TIMER: this step has no minutes' });
      return;
    }
    if (this._timerId !== null) {
      this._stopTimer();
      this.setData({
        timerLine: this._timerLineForStep(),
        status: 'TIMER stopped - tap TIMER to restart',
        lastEvent: 'EVT: timer stopped'
      });
      return;
    }
    this._startTimer(st.min * 60);
  },

  _startTimer(totalSec) {
    this._stopTimer();
    this._remainSec = totalSec;
    var self = this;
    this.setData({
      timerLine: 'TIMER: ' + this._fmt(this._remainSec) + ' left',
      status: 'TIMER running - eyes on the pan',
      lastEvent: 'EVT: timer started ' + this._fmt(totalSec)
    });
    this._timerId = setInterval(function () {
      self._remainSec--;
      if (self._remainSec <= 0) {
        self._stopTimer();
        self.setData({
          timerLine: 'TIMER: TIME UP',
          status: 'TIME UP - check the pan',
          lastEvent: 'EVT: timer done - TTS alert sent'
        });
        self._speakText('时间到。' + (self._currentStep() ? self._currentStep().t : ''));
        return;
      }
      self.setData({ timerLine: 'TIMER: ' + self._fmt(self._remainSec) + ' left' });
    }, 1000);
  },

  listenTap() { this.listenVoice(); },

  async listenVoice() {
    var self = this;
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        asrLine: 'ASR: SKIP - SpeechRecognition n/a here',
        status: 'ASR SKIP - use nod / NEXT instead',
        lastEvent: 'EVT: ASR unavailable (honest SKIP)'
      });
      return;
    }
    // Wearer-mode mic check (documented getUserMedia audio constraints):
    // the 4-mic array in 'wearer' mode prioritizes YOUR voice over the
    // range-hood noise. The stream only verifies the mode opens; the
    // recognition itself uses the benchmark SpeechRecognition pattern.
    var micNote = 'wearer mic not checked';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic');
        var settings = {};
        try {
          var tr = ms.getAudioTracks()[0];
          if (tr && tr.getSettings) settings = tr.getSettings();
        } catch (e) {}
        micNote = 'wearer mic OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        micNote = 'wearer mic check FAIL - ' + this._err(e);
      }
    }
    try {
      if (this._recog) { try { this._recog.abort(); } catch (e) {} }
      var rec = new SpeechRecognition();
      this._recog = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          self.setData({ asrLine: 'ASR heard: ' + txt.slice(0, 24) });
          if (txt.indexOf('下一步') !== -1 || txt.indexOf('好了') !== -1) {
            self.setData({
              status: 'VOICE: 下一步 - advancing',
              lastEvent: 'EVT: voice command -> next step'
            });
            if (!self._started) self.startCooking();
            else if (!self._done) self.nextStep();
          } else {
            self.setData({
              status: 'VOICE heard, not a command (say 下一步）',
              lastEvent: 'ASR: ' + txt.slice(0, 24)
            });
          }
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          asrLine: 'ASR: FAIL - ' + self._err(ev.error || ev),
          status: 'ASR FAIL - use nod / NEXT instead',
          lastEvent: 'EVT: ASR error'
        });
      };
      rec.start();
      this.setData({
        asrLine: 'ASR: listening (' + micNote + ')',
        status: 'LISTENING - say 下一步 / 好了',
        lastEvent: 'EVT: ASR listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        asrLine: 'ASR: FAIL - ' + this._err(e),
        status: 'ASR FAIL - use nod / NEXT instead',
        lastEvent: 'EVT: ASR start failed'
      });
    }
  },

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        panLine: 'PAN: PHOTO FAIL - mediaDevices n/a here',
        status: 'LOOK FAIL - no camera on this host',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default mode) - aim at the pan...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var photoBytes = 0;
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        panLine: 'PAN: photo ' + photoBytes + 'B - record only; YOU judge doneness',
        status: 'PHOTO SAVED - tap PAN to log what you see',
        lastEvent: 'EVT: pan photo ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like the sibling agents.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          panLine: 'PAN: photo wx ' + size + 'B - record only; YOU judge',
          status: 'PHOTO SAVED - tap PAN to log what you see',
          lastEvent: 'EVT: wx pan photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          panLine: 'PAN: PHOTO FAIL - ' + this._err(firstErr),
          status: 'LOOK FAIL - no photo; still tap PAN to log',
          lastEvent: 'EVT: LOOK FAIL'
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

  _panStates() {
    return [
      { name: '还生', tip: '再加热 1-2 分钟，少翻动' },
      { name: '刚好', tip: '火候正好，推进下一步' },
      { name: '有点糊', tip: '关小火，加两勺水快翻匀' }
    ];
  },

  panTap() {
    var states = this._panStates();
    this._panIdx = (this._panIdx + 1) % states.length;
    var s = states[this._panIdx];
    this.setData({
      panLine: 'PAN: ' + s.name + ' - ' + s.tip,
      lastEvent: 'EVT: pan state -> ' + s.name
    });
  },

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  speakTap() {
    var text;
    if (this._done) text = '全部完成，趁热上菜。';
    else if (!this._started || this._stepIdx <= 0) text = this._recipe().ing;
    else text = '第' + this._stepIdx + '步：' + this._currentStep().t;
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent - ' + text.slice(0, 30) });
    } else {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a here' });
    }
  },

  demoTap() {
    // DEMO: 番茄炒蛋， jump to step 3 (timed, 2 min) with the timer running,
    // so the preview shows the step view + a live countdown line.
    this._recipeIdx = 0;
    this._started = true;
    this._done = false;
    this._stepIdx = 3;
    this._renderStep();
    this.setData({
      status: 'DEMO - 番茄炒蛋 step 3, timer running',
      lastEvent: 'EVT: DEMO mid-recipe step + live timer'
    });
    var st = this._currentStep();
    if (st && st.min) this._startTimer(st.min * 60);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">COOK ALONG</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{recipeStep}}</text>
    </view>
    <view class="step-box">
      <text class="box-label">◎ CURRENT STEP - recipe stays in your line of sight</text>
      <text class="step">{{stepBody}}</text>
      <text class="mono">{{timerLine}}</text>
      <text class="mono">{{panLine}}</text>
      <text class="mono">{{asrLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="recipeTap">RECIPE</button>
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="timerTap">TIMER</button>
      <button class="btn" bindtap="listenTap">LISTEN</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="panTap">PAN</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 6px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: 500;
  line-height: 24px;
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
.step-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 8px;
  margin-bottom: 5px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.step {
  color: #40ff5e;
  font-size: 15px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 2px;
}
.mono {
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
  margin-bottom: 4px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 2px;
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
  margin-top: 2px;
}
</style>
