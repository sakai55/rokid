<script def>
{
  "navigationBarTitleText": "Fresh Pick"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PICK A FRUIT, HOLD ONE IN YOUR HAND - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    modeText: 'MODE: HOME',
    fruitLine: 'FRUIT: 西瓜 - 看纹、听声、看蒂、掂重',
    photoLine: 'PHOTO: not taken yet - record only; the agent cannot see the fruit',
    scoreLine: 'SCORE: candidate 1 -/8 · candidate 2 -/8 (max 2 to compare)',
    promptHead: 'PICK A FRUIT - FRUIT cycles, LOOK photos the one in your hand, NEXT starts the 4 checks',
    promptBody: '西瓜怎么挑 — 四个检查，逐项报你看到的。',
    promptSub: 'The agent cannot see, smell or feel the fruit - every score comes from YOUR observations.',
    opt1: '优 +2',
    opt2: '中 +1',
    opt3: '差 0',
    lastEvent: 'EVT: nod when steady = LOOK; during checks, nod = confirm picked option',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'home'; // home | check | verdict
    this._fruitIdx = 0;
    this._cand = 0; // current candidate being scored: 1 | 2 (0 = none yet)
    this._checkIdx = 0;
    this._answers = []; // per check: { score, label }
    this._picked = -1; // option index picked but not yet confirmed (-1 = none)
    this._scores = {}; // candidate number -> total score
    this._verdictResult = null;
    this._compareResult = null;
    this._demo = false;
    this._renderHome();
    this.setData({ lastEvent: 'EVT: pick a fruit, hold one in your hand, then LOOK' });
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
        steadyText: 'HEAD STEADY - ready',
        status: this._mode === 'check'
          ? 'HEAD STEADY - nod = confirm picked option'
          : 'HEAD STEADY - nod or tap LOOK'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still',
        status: 'JUDGE WITH YOUR OWN EYES, HANDS AND NOSE - HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    if (this._mode === 'check') {
      // Same discipline as allergen-guard: a nod only CONFIRMS an option
      // you already picked. It never picks the good option for you.
      this.confirmPick();
    } else if (this._mode === 'verdict') {
      if (this._cand === 1) this.startSecond();
      else this.resetRound();
    } else if (this._mode === 'home') {
      if (this._steady) this.lookPhoto();
      else this.setData({ status: 'NOD IGNORED - hold head steady first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      var dir = code === 'ArrowUp' ? 1 : -1;
      if (this._mode === 'home') this.cycleFruit(dir);
      else if (this._mode === 'check') this.cyclePicked(dir);
      else this.setData({ lastEvent: 'EVT: ' + code + ' (nothing to cycle here)' });
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'check') this.confirmPick();
      else if (this._mode === 'verdict') { if (this._cand === 1) this.startSecond(); else this.resetRound(); }
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

  // ---------- fruit table: the real checks an experienced shopper does ----------
  // Every check is something the WEARER observes with eyes / ears / hands /
  // nose and reports. Scores: 2 = looks ripe & good, 1 = middling, 0 = bad
  // sign. The agent adds up the wearer's observations - it senses nothing.

  _fruits() {
    return [
      {
        key: 'watermelon', zh: '西瓜', intro: '看纹、听声、看蒂、掂重',
        okHead: 'OK — 能买，熟度中等', okAdvice: '口感中上；想吃更甜的，同堆再挑一颗对比。', okTts: '熟度中等。',
        checks: [
          { name: '纹路', prompt: '看瓜皮纹路 — 深浅分明吗？', opts: [['清晰深刻', 2], ['一般', 1], ['模糊发淡', 0]] },
          { name: '敲声', prompt: '轻敲瓜身 — 听是什么声', opts: [['清脆嘭嘭', 2], ['闷声', 1], ['沙哑发空', 0]] },
          { name: '瓜蒂', prompt: '看瓜蒂 — 干还是绿？', opts: [['干枯卷曲', 2], ['半干', 1], ['新鲜发绿', 0]] },
          { name: '重量', prompt: '掂重量 — 同大小比一比', opts: [['偏沉', 2], ['一般', 1], ['发轻', 0]] }
        ]
      },
      {
        key: 'avocado', zh: '牛油果', intro: '看色、捏弹、看蒂、听核',
        okHead: 'OK — 能买，再放 1–2 天', okAdvice: '还没全熟，室温放 1–2 天到微软再吃。', okTts: '再放一两天再吃。',
        checks: [
          { name: '表皮色', prompt: '看表皮颜色 — 越深越熟', opts: [['深绿近黑', 2], ['墨绿', 1], ['鲜亮绿', 0]] },
          { name: '轻捏', prompt: '轻捏果身 — 有回弹吗？', opts: [['微软回弹', 2], ['偏硬', 1], ['很软发塌', 0]] },
          { name: '蒂头', prompt: '抠蒂头 — 看下面颜色', opts: [['黄绿色', 2], ['鲜绿', 1], ['发褐', 0]] },
          { name: '晃动', prompt: '贴耳轻晃 — 有核声吗？', opts: [['无声', 2], ['轻微核声', 1], ['核声明显', 0]] }
        ]
      },
      {
        key: 'mango', zh: '芒果', intro: '闻香、按弹、看斑、看形',
        okHead: 'OK — 能买，再放 1 天', okAdvice: '偏生，室温放 1 天，闻到果香再吃。', okTts: '再放一天再吃。',
        checks: [
          { name: '香味', prompt: '闻果蒂处 — 有果香吗？', opts: [['果香浓郁', 2], ['淡淡清香', 1], ['无味或酒味', 0]] },
          { name: '软硬', prompt: '轻按果身 — 软硬如何？', opts: [['微软有弹', 2], ['偏硬', 1], ['很软出水', 0]] },
          { name: '斑点', prompt: '看果皮 — 斑点多吗？', opts: [['干净少点', 2], ['一些小斑', 1], ['大片黑斑', 0]] },
          { name: '果形', prompt: '看果形 — 饱满吗？', opts: [['圆润饱满', 2], ['一般', 1], ['干瘪发皱', 0]] }
        ]
      },
      {
        key: 'banana', zh: '香蕉', intro: '看色、看斑、看柄、捏硬',
        okHead: 'OK — 能买，再放半天到一天', okAdvice: '再放半天到一天，芝麻点出来更甜。', okTts: '再放半天到一天更甜。',
        checks: [
          { name: '颜色', prompt: '看表皮颜色', opts: [['金黄', 2], ['黄绿相间', 1], ['全绿或发黑', 0]] },
          { name: '斑点', prompt: '看表皮斑点', opts: [['少量芝麻点', 2], ['没有斑点', 1], ['大片黑斑', 0]] },
          { name: '果柄', prompt: '看果柄 — 结实吗？', opts: [['黄绿结实', 2], ['发干', 1], ['发黑松动', 0]] },
          { name: '硬度', prompt: '轻捏果身 — 硬度如何？', opts: [['结实微弹', 2], ['偏硬', 1], ['发软发黏', 0]] }
        ]
      },
      {
        key: 'peach', zh: '桃子', intro: '闻香、看底、摸绒、捏弹',
        okHead: 'OK — 能买，再放 1 天', okAdvice: '偏生，室温放 1 天变软再吃。', okTts: '再放一天再吃。',
        checks: [
          { name: '香味', prompt: '闻一闻 — 有桃香吗？', opts: [['桃香明显', 2], ['淡淡香', 1], ['没有香味', 0]] },
          { name: '底色', prompt: '看底色 — 不是红晕那面', opts: [['奶黄底色', 2], ['黄绿相间', 1], ['发青', 0]] },
          { name: '绒毛', prompt: '摸果皮 — 绒毛如何？', opts: [['绒毛完整', 2], ['绒毛稀疏', 1], ['脱毛发黏', 0]] },
          { name: '轻捏', prompt: '轻捏果身 — 软硬如何？', opts: [['微软有弹', 2], ['偏硬', 1], ['硬如石或烂软', 0]] }
        ]
      }
    ];
  },

  _fruit() { return this._fruits()[this._fruitIdx]; },

  // ---------- verdict + compare (pure; Node-checked at the boundaries) ----------

  // answers: array of { score, label } in check order. Total is out of 8:
  //   >= 7 PICK IT · 4..6 OK (per-fruit wording) · <= 3 SKIP IT.
  // The "why" line names the lowest-scoring check - that is the one thing
  // an experienced shopper would look at first on the next candidate.
  _verdictFor(fruit, answers) {
    var total = 0;
    var worstIdx = 0;
    for (var i = 0; i !== answers.length; i++) {
      total += answers[i].score;
      if (answers[i].score < answers[worstIdx].score) worstIdx = i;
    }
    var worst = fruit.checks[worstIdx];
    var worstLine = answers[worstIdx].score === 2
      ? '四项都不差，最弱是' + worst.name + '「' + answers[worstIdx].label + '」。'
      : '最弱一项：' + worst.name + '「' + answers[worstIdx].label + '」（+' + answers[worstIdx].score + '）。';
    if (total >= 7) {
      return {
        level: 'PICK', total: total,
        headline: 'PICK IT — 熟度正好，买它',
        guide: worstLine + '四项合计 ' + total + '/8 — 可以买。',
        tts: fruit.zh + '，这颗可以买，熟度正好。'
      };
    }
    if (total >= 4) {
      return {
        level: 'OK', total: total,
        headline: fruit.okHead,
        guide: worstLine + '四项合计 ' + total + '/8。' + fruit.okAdvice,
        tts: fruit.zh + '，这颗能买，' + fruit.okTts
      };
    }
    return {
      level: 'SKIP', total: total,
      headline: 'SKIP IT — 放下，换一个',
      guide: worstLine + '四项合计 ' + total + '/8 — 别将就，同堆换一颗重新走四项。',
      tts: '这颗不行，换一个。'
    };
  },

  _compare(s1, s2) {
    if (s2 > s1) {
      return {
        line: 'COMPARE: 第 2 个 ' + s2 + ' 分 > 第 1 个 ' + s1 + ' 分 — 买第 2 个',
        tts: '第二个分更高，买第二个。'
      };
    }
    if (s1 > s2) {
      return {
        line: 'COMPARE: 第 1 个 ' + s1 + ' 分 > 第 2 个 ' + s2 + ' 分 — 买第 1 个',
        tts: '第一个分更高，买第一个。'
      };
    }
    return {
      line: 'COMPARE: 两个都是 ' + s1 + ' 分 — 一样好，拿顺手的那个',
      tts: '两个一样分，拿哪个都行。'
    };
  },

  // ---------- rendering per mode ----------

  _scoreLine() {
    var s1 = this._scores[1] !== undefined ? this._scores[1] + '/8' : '-/8';
    var s2 = this._scores[2] !== undefined ? this._scores[2] + '/8' : '-/8';
    return 'SCORE: candidate 1 ' + s1 + ' · candidate 2 ' + s2 + ' (max 2 to compare)';
  },

  _renderHome() {
    var f = this._fruit();
    this.setData({
      modeText: 'MODE: HOME',
      fruitLine: 'FRUIT: ' + f.zh + ' - ' + f.intro,
      scoreLine: this._scoreLine(),
      promptHead: 'PICK A FRUIT - FRUIT cycles, LOOK photos the one in your hand, NEXT starts the 4 checks',
      promptBody: f.zh + '怎么挑 — 四个检查，逐项报你看到的。',
      promptSub: 'The agent cannot see, smell or feel the fruit - every score comes from YOUR observations.',
      opt1: '优 +2', opt2: '中 +1', opt3: '差 0'
    });
  },

  _renderCheck() {
    var f = this._fruit();
    var c = f.checks[this._checkIdx];
    this.setData({
      modeText: 'MODE: CHECK ' + (this._checkIdx + 1) + '/4 · CAND ' + this._cand,
      fruitLine: 'FRUIT: ' + f.zh + ' - ' + f.intro,
      scoreLine: this._scoreLine(),
      promptHead: 'CHECK ' + (this._checkIdx + 1) + '/4 - ' + c.name + ' · candidate ' + this._cand + ' in your hand',
      promptBody: c.prompt,
      promptSub: this._picked >= 0
        ? '已选：' + c.opts[this._picked][0] + '（+' + c.opts[this._picked][1] + '）— NEXT 或点头确认，记入本项'
        : '点你真正看到/听到/摸到的那一项 — 先选，再 NEXT 确认（点头不会替你选）',
      opt1: c.opts[0][0], opt2: c.opts[1][0], opt3: c.opts[2][0]
    });
  },

  _renderVerdict() {
    var v = this._verdictResult;
    if (!v) return;
    var sub = v.guide;
    if (this._compareResult) sub += '｜' + this._compareResult.line;
    else if (this._cand === 1) sub += '｜想比一颗：点 SECOND 拿另一颗再走四项';
    this.setData({
      modeText: 'MODE: VERDICT - ' + v.level + ' · CAND ' + this._cand,
      fruitLine: 'FRUIT: ' + this._fruit().zh + ' - ' + this._fruit().intro,
      scoreLine: this._scoreLine(),
      promptHead: 'VERDICT - candidate ' + this._cand + ' · ' + v.total + '/8 · spoken aloud' + (this._demo ? ' (DEMO)' : ''),
      promptBody: v.headline,
      promptSub: sub,
      opt1: '优 +2', opt2: '中 +1', opt3: '差 0'
    });
  },

  // ---------- check flow ----------

  startCheck() {
    if (this._mode === 'check') return;
    this._mode = 'check';
    this._cand = 1;
    this._checkIdx = 0;
    this._answers = [];
    this._picked = -1;
    this._scores = {};
    this._verdictResult = null;
    this._compareResult = null;
    this._demo = false;
    this.setData({
      status: 'CHECKS STARTED - report what YOU actually observe, one by one',
      lastEvent: 'EVT: checks started for candidate 1 (' + this._fruit().zh + ')'
    });
    this._renderCheck();
  },

  startSecond() {
    if (this._mode !== 'verdict' || this._cand !== 1) {
      this.setData({ status: 'SECOND COUNTS ONLY AFTER CANDIDATE 1 HAS A VERDICT' });
      return;
    }
    this._mode = 'check';
    this._cand = 2;
    this._checkIdx = 0;
    this._answers = [];
    this._picked = -1;
    this._verdictResult = null;
    this.setData({
      status: 'CANDIDATE 2 - put the other one in your hand, same 4 checks',
      photoLine: 'PHOTO: not taken yet - record only; the agent cannot see the fruit',
      lastEvent: 'EVT: candidate 2 started (' + this._fruit().zh + ')'
    });
    this._renderCheck();
  },

  secondTap() { this.startSecond(); },

  pickOpt(i) {
    if (this._mode !== 'check') {
      this.setData({ status: 'OPTIONS COUNT ONLY DURING THE CHECKS - NEXT starts them' });
      return;
    }
    this._picked = i;
    var c = this._fruit().checks[this._checkIdx];
    this.setData({ lastEvent: 'EVT: picked ' + c.opts[i][0] + ' (+' + c.opts[i][1] + ', not confirmed yet)' });
    this._renderCheck();
  },

  opt1Tap() { this.pickOpt(0); },
  opt2Tap() { this.pickOpt(1); },
  opt3Tap() { this.pickOpt(2); },

  cyclePicked(dir) {
    var idx = this._picked < 0 ? (dir > 0 ? -1 : 0) : this._picked;
    idx = ((idx + dir) % 3 + 3) % 3;
    this.pickOpt(idx);
  },

  confirmPick() {
    if (this._mode !== 'check') return;
    if (this._picked < 0) {
      this.setData({ status: 'PICK WHAT YOU OBSERVE FIRST (nod never picks for you)' });
      return;
    }
    var c = this._fruit().checks[this._checkIdx];
    var opt = c.opts[this._picked];
    this._answers.push({ score: opt[1], label: opt[0] });
    this.setData({ lastEvent: 'EVT: ' + c.name + ' = ' + opt[0] + ' (+' + opt[1] + ')' });
    this._picked = -1;
    if (this._checkIdx < 3) {
      this._checkIdx++;
      this._renderCheck();
    } else {
      this._finishCandidate();
    }
  },

  _finishCandidate() {
    var v = this._verdictFor(this._fruit(), this._answers);
    this._verdictResult = v;
    this._scores[this._cand] = v.total;
    this._mode = 'verdict';
    var speak = v.tts;
    if (this._cand === 2 && this._scores[1] !== undefined) {
      this._compareResult = this._compare(this._scores[1], this._scores[2]);
      speak = this._compareResult.tts;
    }
    this._renderVerdict();
    this.setData({
      status: 'VERDICT: ' + v.level + ' - ' + v.headline,
      lastEvent: 'EVT: candidate ' + this._cand + ' scored ' + v.total + '/8 - ' + v.level + (this._demo ? ' (DEMO)' : '')
    });
    this._speakText(speak);
  },

  resetRound() {
    this._mode = 'home';
    this._cand = 0;
    this._checkIdx = 0;
    this._answers = [];
    this._picked = -1;
    this._scores = {};
    this._verdictResult = null;
    this._compareResult = null;
    this._demo = false;
    this.setData({
      status: 'NEW ROUND - FRUIT to change fruit, NEXT to check the next one',
      photoLine: 'PHOTO: not taken yet - record only; the agent cannot see the fruit',
      lastEvent: 'EVT: reset (fruit kept: ' + this._fruit().zh + ')'
    });
    this._renderHome();
  },

  nextTap() {
    if (this._mode === 'home') this.startCheck();
    else if (this._mode === 'check') this.confirmPick();
    else if (this._mode === 'verdict') this.resetRound();
  },

  // ---------- fruit switching (home only) ----------

  cycleFruit(dir) {
    if (this._mode !== 'home') {
      this.setData({ status: 'FINISH THIS ROUND FIRST - FRUIT switches on the home screen' });
      return;
    }
    var n = this._fruits().length;
    this._fruitIdx = ((this._fruitIdx + dir) % n + n) % n;
    this._scores = {};
    this._cand = 0;
    this.setData({
      status: 'FRUIT: ' + this._fruit().zh + ' - ' + this._fruit().intro,
      lastEvent: 'EVT: fruit -> ' + this._fruit().key
    });
    this._renderHome();
  },

  fruitTap() { this.cycleFruit(1); },

  // ---------- record photo of the candidate in your hand (default mode) ----------

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (this._mode === 'check') {
      this.setData({ status: 'FINISH THESE 4 CHECKS FIRST - then LOOK for the next candidate' });
      return;
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; judge the fruit yourself and tap NEXT',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default) - aim at the fruit in your hand...' });
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
        photoLine: 'PHOTO: ' + photoBytes + 'B - default - record only; YOU judge the fruit, then NEXT',
        status: 'PHOTO SAVED as record - now walk the 4 checks with NEXT',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like plant-doctor / gaze-translate.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record only; YOU judge the fruit',
          status: 'PHOTO SAVED as record - now walk the 4 checks with NEXT',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; judge the fruit yourself and tap NEXT',
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
    var f = this._fruit();
    var text;
    if (this._mode === 'verdict' && this._verdictResult) {
      text = this._compareResult ? this._compareResult.tts : this._verdictResult.tts;
    } else if (this._mode === 'check') {
      var c = f.checks[this._checkIdx];
      text = '第' + (this._checkIdx + 1) + '项，' + c.name + '。' + c.prompt;
    } else {
      text = '挑' + f.zh + '，四步：' + f.intro + '。逐项报你观察到的，我来打分。';
    }
    this._speakText(text);
  },

  // ---------- DEMO: 西瓜 cand1 strong (7 PICK) -> cand2 weak (3 SKIP) -> compare ----------

  demoTap() {
    this._fruitIdx = 0; // watermelon
    this._demo = true;
    this._compareResult = null;
    var f = this._fruit();
    // Candidate 1: observations [2,2,2,1] = 7 -> PICK IT.
    this._cand = 1;
    this._answers = [
      { score: 2, label: '清晰深刻' }, { score: 2, label: '清脆嘭嘭' },
      { score: 2, label: '干枯卷曲' }, { score: 1, label: '一般' }
    ];
    this._scores = { 1: this._verdictFor(f, this._answers).total };
    // Candidate 2: observations [1,1,0,1] = 3 -> SKIP IT, then compare.
    this._cand = 2;
    this._answers = [
      { score: 1, label: '一般' }, { score: 1, label: '闷声' },
      { score: 0, label: '新鲜发绿' }, { score: 1, label: '一般' }
    ];
    this.setData({ photoLine: 'PHOTO: DEMO (no camera used) - record only anyway' });
    this._finishCandidate();
    this.setData({
      status: 'DEMO DONE - candidate 1 wins 7 vs 3',
      lastEvent: 'EVT: DEMO - cand1 PICK 7/8, cand2 SKIP 3/8, compare spoken'
    });
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">FRESH PICK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{modeText}}</text>
    </view>
    <view class="look-box">
      <text class="box-label">◎ FRUIT + RECORD PHOTO - AGENT SENSES NOTHING: YOU LOOK, TAP, SMELL, SQUEEZE</text>
      <text class="photo">{{fruitLine}}</text>
      <text class="photo">{{photoLine}}</text>
      <text class="photo">{{scoreLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="fruitTap">FRUIT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="opt1Tap">{{opt1}}</button>
      <button class="btn" bindtap="opt2Tap">{{opt2}}</button>
      <button class="btn" bindtap="opt3Tap">{{opt3}}</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{promptHead}}</text>
      <text class="step">{{promptBody}}</text>
      <text class="photo">{{promptSub}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="secondTap">SECOND 第二个</button>
      <button class="btn" bindtap="demoTap">DEMO （西瓜 7 vs 3）</button>
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
