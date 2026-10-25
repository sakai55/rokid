<script def>
{
  "navigationBarTitleText": "Allergen Guard"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PICK UP A PRODUCT AND READ ITS LABEL - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    modeText: 'MODE: HOME',
    profileLine: 'YOUR ALLERGENS: 花生、牛奶 (default - tap PROFILE to edit)',
    photoLine: 'PHOTO: not taken yet - record only; the agent does NOT read the label',
    promptHead: 'CHECK A PRODUCT - LOOK takes a record photo, NEXT starts the allergen walk',
    promptBody: '拿起一件商品，翻到配料表 — 逐项核对，不漏一个。',
    promptSub: 'The agent never reads the label - YOU do. It walks your allergen list so nothing is skipped.',
    lastEvent: 'EVT: nod when steady = LOOK; during a check, nod = confirm picked answer',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'home'; // home | profile | check | trace | verdict
    this._profile = this._loadProfile(); // array of allergen keys that are ON
    this._focusIdx = 0; // profile editing focus into _allergens()
    this._checkList = []; // allergen objects being walked in this check
    this._ansIdx = 0;
    this._answers = {}; // key -> 'found' | 'clear' | 'unsure'
    this._picked = null; // answer picked but not yet confirmed
    this._traceYes = null;
    this._verdictResult = null;
    this._demo = false;
    this._renderHome();
    this.setData({ lastEvent: 'EVT: profile loaded (' + this._profile.length + ' allergens ON)' });
  },

  onUnload() {
    this._saveProfile();
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({
        steadyText: 'HEAD STEADY - ready',
        status: this._mode === 'check'
          ? 'HEAD STEADY - nod = confirm picked answer'
          : 'HEAD STEADY - nod or tap LOOK'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still',
        status: 'READ THE LABEL WITH YOUR OWN EYES - HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    if (this._mode === 'check') {
      // Safer rule: a nod only CONFIRMS an answer you already picked.
      // It never answers for you, and never means CLEAR.
      this.confirmAnswer();
    } else if (this._mode === 'verdict') {
      this.nextProduct();
    } else if (this._mode === 'home') {
      if (this._steady) this.lookPhoto();
      else this.setData({ status: 'NOD IGNORED - hold head steady first' });
    } else {
      this.setData({ status: 'NOD IGNORED in ' + this._mode.toUpperCase() + ' - use the buttons' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      var dir = code === 'ArrowUp' ? 1 : -1;
      if (this._mode === 'profile') this.cycleFocus(dir);
      else if (this._mode === 'check') this.cyclePicked(dir);
      else this.setData({ lastEvent: 'EVT: ' + code + ' (nothing to cycle here)' });
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'profile') this.toggleFocused();
      else if (this._mode === 'check') this.confirmAnswer();
      else if (this._mode === 'verdict') this.nextProduct();
      else if (this._mode === 'home') this.startCheck();
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

  // ---------- allergen table + profile persistence ----------

  // The 8 common allergens. The profile is chosen ONCE by the wearer and
  // persisted; the check walk only visits the allergens switched ON.
  _allergens() {
    return [
      { key: 'peanut', zh: '花生', en: 'peanut' },
      { key: 'milk', zh: '牛奶', en: 'milk' },
      { key: 'egg', zh: '鸡蛋', en: 'egg' },
      { key: 'gluten', zh: '麸质小麦', en: 'gluten / wheat' },
      { key: 'soy', zh: '大豆', en: 'soy' },
      { key: 'nuts', zh: '坚果', en: 'tree nuts' },
      { key: 'shellfish', zh: '海鲜甲壳类', en: 'shellfish' },
      { key: 'sesame', zh: '芝麻', en: 'sesame' }
    ];
  },

  _allergen(key) {
    var list = this._allergens();
    for (var i = 0; i !== list.length; i++) if (list[i].key === key) return list[i];
    return null;
  },

  _isOn(key) { return (this._profile || []).indexOf(key) !== -1; },

  _onList() {
    var self = this;
    return this._allergens().filter(function (a) { return self._isOn(a.key); });
  },

  _loadProfile() {
    try {
      var raw = wx.getStorageSync('allergenProfile');
      if (raw && Object.prototype.toString.call(raw) === '[object Array]') {
        var valid = this._allergens().map(function (a) { return a.key; });
        var out = [];
        for (var i = 0; i !== raw.length; i++) {
          if (valid.indexOf(raw[i]) !== -1 && out.indexOf(raw[i]) === -1) out.push(raw[i]);
        }
        return out;
      }
    } catch (e) { /* storage unavailable: fall through to default */ }
    // Default starting profile, clearly labeled as default in the UI:
    // peanut + milk ON until the wearer edits it.
    return ['peanut', 'milk'];
  },

  _saveProfile() {
    try {
      wx.setStorageSync('allergenProfile', this._profile || []);
    } catch (e) { /* storage unavailable on this host: profile stays in memory */ }
  },

  _profileLine() {
    var on = this._onList();
    if (!on.length) return 'YOUR ALLERGENS: none ON - tap PROFILE and toggle at least one ON';
    var names = on.map(function (a) { return a.zh; }).join('、');
    return 'YOUR ALLERGENS: ' + names + ' (' + on.length + ' ON) - tap PROFILE to edit';
  },

  // ---------- rendering per mode ----------

  _renderHome() {
    var on = this._onList();
    this.setData({
      modeText: 'MODE: HOME',
      profileLine: this._profileLine(),
      promptHead: 'CHECK A PRODUCT - LOOK takes a record photo, NEXT starts the allergen walk',
      promptBody: on.length
        ? '拿起商品看配料表 — 逐项核对 ' + on.length + ' 个忌口。'
        : '还没有忌口被打开 — 先点 PROFILE 打开至少一个。',
      promptSub: 'The agent never reads the label - YOU do. It walks your allergen list so nothing is skipped.'
    });
  },

  _renderProfile() {
    var a = this._allergens()[this._focusIdx];
    var marks = this._allergens().map(function (x) {
      return x.zh + (this._isOn(x.key) ? '●' : '○');
    }, this).join(' ');
    this.setData({
      modeText: 'MODE: PROFILE ' + (this._focusIdx + 1) + '/8',
      profileLine: this._profileLine(),
      promptHead: 'PROFILE - PROFILE cycles allergen, TOGGLE flips ON/OFF, NEXT saves & exits',
      promptBody: a.zh + '（' + a.en + '）— ' + (this._isOn(a.key) ? 'ON · 会逐项核对' : 'OFF · 不查'),
      promptSub: marks
    });
  },

  _ansLabel(ans) {
    if (ans === 'found') return '含 (FOUND)';
    if (ans === 'clear') return '未见 (CLEAR)';
    if (ans === 'unsure') return '看不清 (UNSURE)';
    return '';
  },

  _renderCheck() {
    var item = this._checkList[this._ansIdx];
    this.setData({
      modeText: 'MODE: CHECK ' + (this._ansIdx + 1) + '/' + this._checkList.length,
      profileLine: this._profileLine(),
      promptHead: 'ALLERGEN ' + (this._ansIdx + 1) + '/' + this._checkList.length + ' - answer from the label YOU are reading',
      promptBody: '含「' + item.zh + '」吗？看配料表再答',
      promptSub: this._picked
        ? '已选：' + this._ansLabel(this._picked) + ' — NEXT 或点头确认，记入本项'
        : '未选 — 先点 FOUND / CLEAR / UNSURE（点头不会替你作答）'
    });
  },

  _renderTrace() {
    this.setData({
      modeText: 'MODE: TRACE',
      profileLine: this._profileLine(),
      promptHead: 'LAST QUESTION - the "may contain" line on the package',
      promptBody: '有「可能含微量 / 同生产线」提示吗？',
      promptSub: 'YES = 包装上有这行小字 · NO = 没有 — 点 YES / NO 直接出结论'
    });
  },

  _renderVerdict() {
    var v = this._verdictResult;
    if (!v) return;
    var summary = this._checkList.map(function (item) {
      return item.zh + '=' + this._ansLabel(this._answers[item.key]).split(' ')[0];
    }, this).join(' · ');
    this.setData({
      modeText: 'MODE: VERDICT - ' + v.level,
      profileLine: this._profileLine(),
      promptHead: 'VERDICT - spoken aloud automatically' + (this._demo ? ' (DEMO)' : ''),
      promptBody: v.headline,
      promptSub: v.guide + '｜' + summary + ' · 微量行=' + (this._traceYes ? '有' : '无')
    });
  },

  // ---------- verdict aggregation (pure; Node-checked for all combinations) ----------

  // Rules, in priority order:
  //   any FOUND          -> STOP (DO NOT BUY), spoken warning
  //   else any UNSURE    -> CAUTION (severe allergy: treat unsure as contains)
  //   else trace line YES-> CAUTION (may-contain downgrades an all-clear)
  //   else               -> OK (reachable only by walking every ON allergen)
  _computeVerdict(answers, traceYes) {
    var found = [];
    var unsure = [];
    for (var i = 0; i !== answers.length; i++) {
      if (answers[i].ans === 'found') found.push(answers[i].zh);
      else if (answers[i].ans === 'unsure') unsure.push(answers[i].zh);
    }
    if (found.length) {
      return {
        level: 'STOP',
        headline: 'DO NOT BUY — 含' + found.join('、'),
        guide: '放回货架，别买。本次查到含：' + found.join('、') + '。',
        tts: '注意，这个含' + found.join('和') + '，不要买。'
      };
    }
    if (unsure.length && traceYes) {
      return {
        level: 'CAUTION',
        headline: 'CAUTION — 看不清 + 有微量提示',
        guide: '别冒险：' + unsure.join('、') + '看不清，包装上还有微量提示。重度过敏：看不清就按含有处理，不要买。',
        tts: '小心，有成分看不清，包装上还有微量提示，别冒险，不要买。'
      };
    }
    if (unsure.length) {
      return {
        level: 'CAUTION',
        headline: 'CAUTION — 有看不清的成分',
        guide: '别冒险：' + unsure.join('、') + '看不清。重度过敏：看不清就按含有处理，不要买。',
        tts: '小心，有成分看不清，别冒险。'
      };
    }
    if (traceYes) {
      return {
        level: 'CAUTION',
        headline: 'CAUTION — 有微量/同生产线提示',
        guide: '配料表里没查到你的忌口，但包装上有「可能含微量」提示 — 别冒险，慎买。',
        tts: '小心，包装上有可能含微量的提示，别冒险。'
      };
    }
    return {
      level: 'OK',
      headline: 'OK — 你的忌口都不在配料表里',
      guide: '逐项核对完毕，可以买。结论来自你亲眼读的配料表，不是眼镜识别。',
      tts: '检查完了，你忌口的成分都不在配料表里。'
    };
  },

  _answersArray() {
    var self = this;
    return this._checkList.map(function (item) {
      return { key: item.key, zh: item.zh, ans: self._answers[item.key] || 'unsure' };
    });
  },

  _finishCheck() {
    this._verdictResult = this._computeVerdict(this._answersArray(), !!this._traceYes);
    this._mode = 'verdict';
    this._renderVerdict();
    this.setData({
      status: 'VERDICT: ' + this._verdictResult.level + ' - ' + this._verdictResult.headline,
      lastEvent: 'EVT: check finished - verdict ' + this._verdictResult.level + (this._demo ? ' (DEMO)' : '')
    });
    this._speakText(this._verdictResult.tts);
  },

  // ---------- check flow ----------

  startCheck() {
    var on = this._onList();
    if (!on.length) {
      this.setData({ status: 'NO ALLERGENS ON - tap PROFILE and toggle at least one ON first' });
      return;
    }
    this._mode = 'check';
    this._checkList = on;
    this._ansIdx = 0;
    this._answers = {};
    this._picked = null;
    this._traceYes = null;
    this._verdictResult = null;
    this._demo = false;
    this.setData({
      status: 'CHECK STARTED - answer each allergen from the label',
      lastEvent: 'EVT: check started for ' + on.length + ' allergens'
    });
    this._renderCheck();
  },

  pickAnswer(ans) {
    if (this._mode !== 'check') {
      this.setData({ status: 'ANSWERS COUNT ONLY DURING A CHECK - NEXT starts one' });
      return;
    }
    this._picked = ans;
    this.setData({ lastEvent: 'EVT: picked ' + this._ansLabel(ans) + ' (not confirmed yet)' });
    this._renderCheck();
  },

  foundTap() { this.pickAnswer('found'); },
  clearTap() { this.pickAnswer('clear'); },
  unsureTap() { this.pickAnswer('unsure'); },

  cyclePicked(dir) {
    var order = ['found', 'clear', 'unsure'];
    var idx = this._picked ? order.indexOf(this._picked) : (dir > 0 ? -1 : 0);
    idx = ((idx + dir) % order.length + order.length) % order.length;
    this.pickAnswer(order[idx]);
  },

  confirmAnswer() {
    if (this._mode !== 'check') return;
    if (!this._picked) {
      this.setData({ status: 'PICK AN ANSWER FIRST - FOUND / CLEAR / UNSURE (nod never answers for you)' });
      return;
    }
    var item = this._checkList[this._ansIdx];
    this._answers[item.key] = this._picked;
    this._picked = null;
    this.setData({ lastEvent: 'EVT: ' + item.zh + ' = ' + this._ansLabel(this._answers[item.key]) });
    if (this._ansIdx < this._checkList.length - 1) {
      this._ansIdx++;
      this._renderCheck();
    } else {
      this._mode = 'trace';
      this.setData({ status: 'ALL ALLERGENS ANSWERED - one last question: the trace line' });
      this._renderTrace();
    }
  },

  traceAnswer(yes) {
    if (this._mode !== 'trace') {
      this.setData({ status: 'TRACE QUESTION COMES AFTER THE ALLERGEN WALK - finish it first' });
      return;
    }
    this._traceYes = !!yes;
    this.setData({ lastEvent: 'EVT: trace line = ' + (yes ? 'YES' : 'NO') });
    this._finishCheck();
  },

  traceYesTap() { this.traceAnswer(true); },
  traceNoTap() { this.traceAnswer(false); },

  nextProduct() {
    this._mode = 'home';
    this._checkList = [];
    this._answers = {};
    this._picked = null;
    this._traceYes = null;
    this._verdictResult = null;
    this._demo = false;
    this.setData({
      status: 'NEW PRODUCT - LOOK again, then NEXT to start the walk',
      photoLine: 'PHOTO: not taken yet - record only; the agent does NOT read the label',
      lastEvent: 'EVT: reset for the next product (profile kept)'
    });
    this._renderHome();
  },

  nextTap() {
    if (this._mode === 'home') this.startCheck();
    else if (this._mode === 'profile') {
      this._saveProfile();
      this._mode = 'home';
      this.setData({ status: 'PROFILE SAVED - ' + this._profile.length + ' allergens ON' });
      this._renderHome();
    } else if (this._mode === 'check') this.confirmAnswer();
    else if (this._mode === 'trace') this.setData({ status: 'TAP YES / NO FOR THE TRACE LINE' });
    else if (this._mode === 'verdict') this.nextProduct();
  },

  // ---------- profile editing ----------

  profileTap() {
    if (this._mode !== 'profile') {
      this._mode = 'profile';
      this._focusIdx = 0;
      this.setData({ status: 'PROFILE EDIT - your allergen set, saved on this device only' });
    } else {
      this._focusIdx = (this._focusIdx + 1) % this._allergens().length;
    }
    this._renderProfile();
  },

  cycleFocus(dir) {
    var n = this._allergens().length;
    this._focusIdx = ((this._focusIdx + dir) % n + n) % n;
    this._renderProfile();
  },

  toggleFocused() {
    var a = this._allergens()[this._focusIdx];
    if (this._isOn(a.key)) {
      this._profile = this._profile.filter(function (k) { return k !== a.key; });
    } else {
      this._profile.push(a.key);
    }
    this._saveProfile();
    this.setData({
      status: a.zh + ' -> ' + (this._isOn(a.key) ? 'ON' : 'OFF') + ' (saved)',
      lastEvent: 'EVT: profile ' + a.key + ' = ' + (this._isOn(a.key) ? 'ON' : 'OFF')
    });
    this._renderProfile();
  },

  toggleTap() {
    if (this._mode !== 'profile') {
      this.setData({ status: 'TOGGLE WORKS IN PROFILE - tap PROFILE first' });
      return;
    }
    this.toggleFocused();
  },

  // ---------- telephoto record photo (never read, never OCR) ----------

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (this._mode === 'check' || this._mode === 'trace') {
      this.setData({ status: 'FINISH THIS CHECK FIRST - then LOOK for the next product' });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; read the label yourself and tap NEXT to check',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto) - aim at the ingredient panel...' });
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
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B - telephoto - record cue only, image not saved; YOU read the label, then NEXT',
        status: 'PHOTO TAKEN (image not saved) - now read the label and tap NEXT',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / manual-lens.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record cue only, image not saved; YOU read the label',
          status: 'PHOTO TAKEN (image not saved) - now read the label and tap NEXT',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; read the label yourself and tap NEXT to check',
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

  // ---------- TTS ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - ' + text.slice(0, 40) });
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    var text;
    if (this._mode === 'verdict' && this._verdictResult) {
      text = this._verdictResult.tts;
    } else if (this._mode === 'check') {
      var item = this._checkList[this._ansIdx];
      text = '含' + item.zh + '吗？请看配料表再回答。';
    } else if (this._mode === 'trace') {
      text = '包装上有可能含微量，或者同生产线生产的提示吗？';
    } else {
      var on = this._onList();
      text = on.length
        ? '你的忌口是：' + on.map(function (a) { return a.zh; }).join('、') + '。拿起商品，看配料表逐项核对。'
        : '你还没有打开任何忌口。先点 PROFILE 打开至少一个。';
    }
    this._speakText(text);
  },

  // ---------- DEMO: demo profile (peanut + milk), peanut FOUND -> STOP ----------

  demoTap() {
    // In-memory DEMO profile only - the wearer's saved profile is NOT overwritten.
    this._profile = ['peanut', 'milk'];
    this._demo = true;
    this._checkList = this._onList();
    this._answers = { peanut: 'found', milk: 'clear' };
    this._picked = null;
    this._traceYes = false;
    this.setData({
      photoLine: 'PHOTO: DEMO (no camera used) - record only anyway',
      status: 'DEMO - a label where peanut is FOUND'
    });
    this._finishCheck();
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">ALLERGEN GUARD</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{modeText}}</text>
    </view>
    <view class="look-box">
      <text class="box-label">◎ PROFILE + RECORD PHOTO - AGENT NEVER READS THE LABEL, YOU DO (no OCR)</text>
      <text class="photo">{{profileLine}}</text>
      <text class="photo">{{photoLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="profileTap">PROFILE</button>
      <button class="btn" bindtap="toggleTap">TOGGLE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="foundTap">FOUND 含</button>
      <button class="btn" bindtap="clearTap">CLEAR 未见</button>
      <button class="btn" bindtap="unsureTap">UNSURE 看不清</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{promptHead}}</text>
      <text class="step">{{promptBody}}</text>
      <text class="photo">{{promptSub}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="traceYesTap">YES 微量</button>
      <button class="btn" bindtap="traceNoTap">NO 无微量</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="demoTap">DEMO （花生=含 → 不要买）</button>
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
.look-box {
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
.photo {
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
.plan-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 8px;
  margin-bottom: 5px;
}
.step {
  color: #40ff5e;
  font-size: 15px;
  line-height: 20px;
  margin-top: 2px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
</style>
