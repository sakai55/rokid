<script def>
{
  "navigationBarTitleText": "Outfit Check"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'DESCRIBE THE PIECE YOU ARE LOOKING AT - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    modeText: 'MODE: DESCRIBE',
    pieceLine: 'PIECE: 上衣 · 藏青 · 纯色 · 合身',
    pairLine: 'PAIR: 裤子 · 米色 · 纯色 - OCCASION: 上班',
    photoLine: 'PHOTO: not taken yet - record only; the agent cannot see the clothes',
    editLine: 'EDIT: 颜色 = 藏青 - FIELD picks what to edit, VALUE cycles it',
    verdictHead: 'DESCRIBE - then CHECK for the rules verdict',
    verdictBody: '选好单品、搭配和场合，点 CHECK 看搭不搭。',
    suggLine: 'SUGGEST: - (CHECK first; advice comes from the built-in rule table)',
    aiLine: 'AI: not asked - ASK AI sends the TEXT description only, never the photo',
    mirrorLine: 'MIRROR: after CHECK, stand at a mirror and tap MIRROR to re-check fit',
    lastEvent: 'EVT: nod when steady = LOOK; Enter = CHECK',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'describe'; // describe | verdict
    // Selector state as indexes into the value tables below.
    // Defaults are the DEMO outfit: 藏青纯色合身上衣 + 米色纯色裤子 + 上班.
    this._sel = {
      type: 0, color: 3, pattern: 0, fit: 1,
      pairType: 1, pairColor: 4, pairPattern: 0, occasion: 0
    };
    this._fieldIdx = 1; // start on 颜色, the field people change most
    this._verdictResult = null;
    this._mirrorIdx = 0; // 0 未看 1 合身 2 显胖 3 显瘦
    this._demo = false;
    this._renderDescribe();
    this.setData({ lastEvent: 'EVT: FIELD/VALUE describe the piece, then CHECK' });
  },

  onUnload() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    if (this._session) {
      try { this._session.destroy(); } catch (e) {}
      this._session = null;
    }
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({
        steadyText: 'HEAD STEADY - ready',
        status: this._mode === 'verdict'
          ? 'HEAD STEADY - nod = hear the verdict again'
          : 'HEAD STEADY - nod or tap LOOK for a record photo'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still',
        status: 'DESCRIBE IT AS YOU SEE IT - HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    if (this._mode === 'verdict') {
      this.speakTap();
    } else if (this._steady) {
      this.lookPhoto();
    } else {
      this.setData({ status: 'NOD IGNORED - hold head steady first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      var dir = code === 'ArrowUp' ? 1 : -1;
      this.cycleValue(dir);
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'verdict') this.backToDescribe();
      else this.runCheck();
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

  // ---------- selector value tables ----------

  _types() { return ['上衣', '裤子', '裙子', '外套', '鞋']; },
  _colors() { return ['黑', '白', '灰', '藏青', '米色', '红', '蓝', '绿', '黄', '粉']; },
  _patterns() { return ['纯色', '条纹', '格纹', '花纹']; },
  _fits() { return ['修身', '合身', '宽松']; },
  _occasions() { return ['上班', '约会', '运动', '正式场合', '日常']; },

  _fields() {
    return [
      { id: 'type', zh: '单品', table: this._types() },
      { id: 'color', zh: '颜色', table: this._colors() },
      { id: 'pattern', zh: '花纹', table: this._patterns() },
      { id: 'fit', zh: '版型', table: this._fits() },
      { id: 'pairType', zh: '搭配', table: this._types() },
      { id: 'pairColor', zh: '搭配色', table: this._colors() },
      { id: 'pairPattern', zh: '搭配花纹', table: this._patterns() },
      { id: 'occasion', zh: '场合', table: this._occasions() }
    ];
  },

  _selText() {
    var s = this._sel;
    return {
      type: this._types()[s.type],
      color: this._colors()[s.color],
      pattern: this._patterns()[s.pattern],
      fit: this._fits()[s.fit],
      pairType: this._types()[s.pairType],
      pairColor: this._colors()[s.pairColor],
      pairPattern: this._patterns()[s.pairPattern],
      occasion: this._occasions()[s.occasion]
    };
  },

  // ---------- rule table (pure; Node-checked on the known cases) ----------
  // Every judgement comes from the wearer's DESCRIPTION run through these
  // tables. The agent never sees the garment: no photo is read, classified
  // or sent anywhere.

  // Colour pairing over the 10-colour palette. Neutrals （黑/白/灰/藏青/米色）
  // pair safely with everything; two brights follow the pair table.
  _colorPair(a, b) {
    var neutral = { '黑': 1, '白': 1, '灰': 1, '藏青': 1, '米色': 1 };
    if (a === b) return { score: 1, note: '同色一身 — 靠版型和材质拉开层次' };
    if (neutral[a] && neutral[b]) return { score: 2, note: '中性互搭 — 稳妥' };
    if (neutral[a] || neutral[b]) return { score: 2, note: '中性色托住亮色 — 稳妥' };
    var key = [a, b].sort().join('+');
    var table = {
      '红+绿': { score: 0, note: '红配绿 — 经典撞色，容易翻车' },
      '粉+红': { score: 0, note: '红与粉同系浓淡打架' },
      '蓝+黄': { score: 2, note: '蓝配黄 — 对比鲜明又协调' },
      '红+黄': { score: 1, note: '红黄都暖 — 热闹，略冲' },
      '红+蓝': { score: 1, note: '红蓝对比 — 能成立，注意比例' },
      '绿+蓝': { score: 1, note: '蓝绿相邻 — 协调偏冷' },
      '粉+蓝': { score: 1, note: '蓝配粉 — 清爽，可以' },
      '绿+黄': { score: 1, note: '绿配黄 — 有春天感，略挑场合' },
      '粉+绿': { score: 1, note: '绿配粉 — 柔和，可以' },
      '粉+黄': { score: 1, note: '黄配粉 — 偏甜，可能显幼' }
    };
    return table[key] || { score: 1, note: '非常规组合 — 靠镜子确认' };
  },

  // Pattern clash: two non-plain patterns fight; one pattern + one plain
  // has a clear lead; two plains are clean.
  _patternPair(p, q) {
    var pLoud = p !== '纯色';
    var qLoud = q !== '纯色';
    if (pLoud && qLoud) return { score: 0, note: '上下都有花纹 — 互相打架' };
    if (pLoud || qLoud) return { score: 2, note: '一个花纹一个纯色 — 有主次' };
    return { score: 2, note: '全纯色 — 干净' };
  },

  // Occasion fit per piece type. 0 = wrong for the occasion (e.g. shoes at
  // a formal event: sneakers are the classic fail), 1 = risky, 2 = fine.
  _occasionFit(type, occ) {
    var table = {
      '上衣': { '上班': 2, '约会': 2, '运动': 1, '正式场合': 1, '日常': 2 },
      '裤子': { '上班': 2, '约会': 2, '运动': 1, '正式场合': 1, '日常': 2 },
      '裙子': { '上班': 2, '约会': 2, '运动': 0, '正式场合': 2, '日常': 2 },
      '外套': { '上班': 2, '约会': 2, '运动': 1, '正式场合': 2, '日常': 2 },
      '鞋': { '上班': 1, '约会': 1, '运动': 2, '正式场合': 0, '日常': 2 }
    };
    var notes = {
      '上衣|运动': '运动要选速干透气款', '上衣|正式场合': '正式场合选衬衫类挺括款',
      '裤子|运动': '运动要选弹性面料', '裤子|正式场合': '正式场合避开破洞和短裤',
      '裙子|运动': '裙子不适合运动，不方便也不安全',
      '外套|运动': '外套运动时碍事，选轻薄款',
      '鞋|上班': '上班鞋选低调款式', '鞋|约会': '约会鞋要干净利落',
      '鞋|正式场合': '正式场合忌运动鞋 — 换皮鞋'
    };
    var row = table[type] || {};
    var score = row[occ] !== undefined ? row[occ] : 1;
    return { score: score, note: notes[type + '|' + occ] || '合适' };
  },

  // Full verdict from a text description {type,color,pattern,fit,
  // pairType,pairColor,pairPattern,occasion}. total = colour 0-2 +
  // pattern 0-2 + occasion 0-2 (max 6). An occasion score of 0 means
  // the occasion is wrong - nothing else can save the outfit.
  _verdictFor(t) {
    var c = this._colorPair(t.color, t.pairColor);
    var p = this._patternPair(t.pattern, t.pairPattern);
    var o = this._occasionFit(t.type, t.occasion);
    var total = c.score + p.score + o.score;
    var level, headline;
    if (o.score === 0) {
      level = 'BAD'; headline = '不搭 — 场合不对，先换场合对的单品';
    } else if (total === 6) {
      // GOOD is strict on purpose: all three components at full marks.
      // Any single discounted component （撞色/风险场合） means 勉强.
      level = 'GOOD'; headline = '搭 — 可以穿出门';
    } else if (total >= 3) {
      level = 'SOFT'; headline = '勉强 — 调一件再出门';
    } else {
      level = 'BAD'; headline = '不搭 — 换一件再说';
    }
    var sugg = [];
    if (c.score === 0) sugg.push('搭配色换成中性色（黑/白/灰/米色），撞色立刻解开');
    else if (c.score === 1 && t.color === t.pairColor) sugg.push('同色一身：用鞋或包拉开层次，别一色到底');
    if (p.score === 0) sugg.push('上下只留一个花纹，另一件换纯色');
    if (o.score === 1) sugg.push(o.note + '，拿不准就换更稳的单品');
    if (t.fit === '宽松' && t.type === '上衣') sugg.push('宽松上衣把下摆塞一半，比例立刻变好');
    if (sugg.length < 2) {
      var boosts = {
        '上班': ['加简洁手表提正式感', '鞋包同色更完整'],
        '约会': ['加一个小配饰当亮点，别堆太多', '袖口卷一折，随性感立刻出来'],
        '正式场合': ['正式场合配饰越少越稳重', '衣服平整无褶，比配饰更重要'],
        '运动': ['运动场合功能优先，配色可以随意', '速干透气面料比颜色重要'],
        '日常': ['舒服干净，就是日常穿搭的最优解', '一双干净的鞋能救整套日常装']
      };
      var fill = boosts[t.occasion] || ['整体已成立，镜子前确认版型即可', '配色和版型都没问题，放心出门'];
      for (var bi = 0; bi !== fill.length && sugg.length < 2; bi++) sugg.push(fill[bi]);
    }
    var tts = level === 'GOOD' ? '这套搭，可以出门。'
      : level === 'SOFT' ? '这套勉强，先调整一件再出门。'
      : '这套不搭，换一件再说。';
    return {
      level: level, total: total,
      headline: headline,
      why: '配色：' + c.note + '（+' + c.score + '）｜花纹：' + p.note + '（+' + p.score + '）｜场合：' + o.note + '（+' + o.score + '）',
      sugg: sugg.slice(0, 2),
      tts: tts
    };
  },

  // ---------- rendering ----------

  _descLines() {
    var t = this._selText();
    return {
      pieceLine: 'PIECE: ' + t.type + ' · ' + t.color + ' · ' + t.pattern + ' · ' + t.fit,
      pairLine: 'PAIR: ' + t.pairType + ' · ' + t.pairColor + ' · ' + t.pairPattern + ' - OCCASION: ' + t.occasion
    };
  },

  _editLine() {
    var f = this._fields()[this._fieldIdx];
    return 'EDIT: ' + f.zh + ' = ' + f.table[this._sel[f.id]] + ' - FIELD picks what to edit, VALUE cycles it';
  },

  _renderDescribe() {
    var d = this._descLines();
    this.setData({
      modeText: 'MODE: DESCRIBE',
      pieceLine: d.pieceLine,
      pairLine: d.pairLine,
      editLine: this._editLine(),
      verdictHead: 'DESCRIBE - then CHECK for the rules verdict',
      verdictBody: '选好单品、搭配和场合，点 CHECK 看搭不搭。',
      suggLine: 'SUGGEST: - (CHECK first; advice comes from the built-in rule table)',
      aiLine: 'AI: not asked - ASK AI sends the TEXT description only, never the photo',
      mirrorLine: 'MIRROR: after CHECK, stand at a mirror and tap MIRROR to re-check fit'
    });
  },

  _renderVerdict() {
    var v = this._verdictResult;
    if (!v) return;
    var d = this._descLines();
    this.setData({
      modeText: 'MODE: VERDICT - ' + v.level + ' · ' + v.total + '/6',
      pieceLine: d.pieceLine,
      pairLine: d.pairLine,
      editLine: this._editLine(),
      verdictHead: 'VERDICT - built-in rules' + (this._demo ? ' (DEMO)' : '') + ' · spoken aloud',
      verdictBody: v.headline,
      suggLine: v.why + '｜' + v.sugg.join('；'),
      mirrorLine: this._mirrorLine()
    });
  },

  _mirrorStates() { return ['未看', '合身', '显胖', '显瘦']; },

  _mirrorLine() {
    var m = this._mirrorStates()[this._mirrorIdx];
    if (this._mirrorIdx === 0) return 'MIRROR: after CHECK, stand at a mirror and tap MIRROR to re-check fit';
    if (m === '合身') return 'MIRROR 复核：合身 — 镜子里整体利落，这套可以定下来';
    if (m === '显胖') return 'MIRROR 复核：显胖 — 上衣下摆塞一点，或把搭配换成深色压一压';
    return 'MIRROR 复核：显瘦 — 镜子里线条利落，保持这套';
  },

  // ---------- selectors ----------

  fieldTap() {
    this._fieldIdx = (this._fieldIdx + 1) % this._fields().length;
    var f = this._fields()[this._fieldIdx];
    this.setData({
      editLine: this._editLine(),
      lastEvent: 'EVT: field -> ' + f.zh + ' = ' + f.table[this._sel[f.id]]
    });
    if (this._mode === 'describe') this._renderDescribeSoft();
  },

  // Refresh only the description + edit lines (keeps verdict box intact
  // while the wearer tweaks a selector before re-checking).
  _renderDescribeSoft() {
    var d = this._descLines();
    this.setData({ pieceLine: d.pieceLine, pairLine: d.pairLine, editLine: this._editLine() });
  },

  valueTap() { this.cycleValue(1); },

  cycleValue(dir) {
    var f = this._fields()[this._fieldIdx];
    var n = f.table.length;
    this._sel[f.id] = ((this._sel[f.id] + dir) % n + n) % n;
    if (this._mode === 'verdict') {
      // Tweaking after a verdict invalidates it - be honest about that.
      this._mode = 'describe';
      this._verdictResult = null;
      this._mirrorIdx = 0;
      this._renderDescribe();
      this.setData({ status: 'CHANGED - old verdict cleared, CHECK again' });
    } else {
      this._renderDescribeSoft();
    }
    this.setData({ lastEvent: 'EVT: ' + f.zh + ' -> ' + f.table[this._sel[f.id]] });
  },

  // ---------- CHECK: rules verdict ----------

  checkTap() { this.runCheck(); },

  runCheck() {
    if (this.data.busy) return;
    var v = this._verdictFor(this._selText());
    this._verdictResult = v;
    this._mode = 'verdict';
    this._mirrorIdx = 0;
    this._renderVerdict();
    this.setData({
      status: 'VERDICT: ' + v.level + ' - ' + v.headline,
      lastEvent: 'EVT: rules verdict ' + v.level + ' ' + v.total + '/6' + (this._demo ? ' (DEMO)' : '')
    });
    this._speakText(v.tts);
  },

  backToDescribe() {
    this._mode = 'describe';
    this._verdictResult = null;
    this._mirrorIdx = 0;
    this._demo = false;
    this._renderDescribe();
    this.setData({ status: 'DESCRIBE AGAIN - tweak any field, then CHECK' });
  },

  // ---------- MIRROR re-check (second stage, after CHECK) ----------

  mirrorTap() {
    if (this._mode !== 'verdict' || !this._verdictResult) {
      this.setData({ status: 'MIRROR COMES AFTER CHECK - CHECK first, then look in the mirror' });
      return;
    }
    this._mirrorIdx = (this._mirrorIdx + 1) % this._mirrorStates().length;
    this.setData({
      mirrorLine: this._mirrorLine(),
      lastEvent: 'EVT: mirror -> ' + this._mirrorStates()[this._mirrorIdx]
    });
  },

  // ---------- ASK AI: LanguageModel over the TEXT description only ----------

  aiTap() { this.askAI(); },

  async _llmTips(t) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    try {
      var avail = await LM.availability();
      if (avail !== 'available') return null;
      var session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You are a concise outfit styling advisor. Reply in Chinese only.' }]
      });
      this._session = session;
      try {
        var desc = t.color + '色' + t.pattern + t.fit + t.type +
          '，搭配' + t.pairColor + '色' + t.pairPattern + t.pairType +
          '，场合是' + t.occasion;
        var ans = await this._withTimeout(
          session.prompt('我正在挑衣服，描述如下：' + desc + '。请给 2 条简短的搭配建议，每条一行，分别以「1. 」「2. 」开头。不要输出其它内容。'),
          25000, 'llm');
        var lines = String(ans || '').split('\n').map(function (s) { return s.trim(); })
          .filter(function (s) { return s.length > 0; });
        var tips = [];
        for (var i = 0; i !== lines.length; i++) {
          var m = lines[i].match(/^[1-2][.、．]\s*(.+)$/);
          if (m) tips.push(m[1]);
        }
        if (tips.length >= 1) return tips.slice(0, 2);
        return null;
      } finally {
        try { session.destroy(); } catch (e) {}
        if (this._session === session) this._session = null;
      }
    } catch (e) {
      return null;
    }
  },

  async askAI() {
    if (this.data.busy) return;
    this.setData({ busy: true, status: 'ASKING AI about the TEXT description (no photo sent)...' });
    var tips = null;
    try { tips = await this._llmTips(this._selText()); } catch (e) { tips = null; }
    this.setData({ busy: false });
    if (tips) {
      this.setData({
        aiLine: 'AI (LLM, from your text): ' + tips.join(' ｜ '),
        status: 'AI TIPS IN - rules verdict above still stands on its own',
        lastEvent: 'EVT: AI tips from text description (' + tips.length + ')'
      });
    } else {
      this.setData({
        aiLine: 'AI: SKIP - LanguageModel n/a here; the rules verdict stands alone',
        status: 'AI SKIP - no LLM on this host; use the rules verdict',
        lastEvent: 'EVT: ASK AI SKIP (LanguageModel unavailable)'
      });
    }
  },

  // ---------- record photo of the garment / mirror (never judged) ----------

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; describe the piece with FIELD/VALUE instead',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default) - aim at the garment or the mirror...' });
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
        photoLine: 'PHOTO: ' + photoBytes + 'B - default - record only; describe it with FIELD/VALUE',
        status: 'PHOTO SAVED as record - it is never judged; describe, then CHECK',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like fresh-pick / plant-doctor.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record only; describe it yourself',
          status: 'PHOTO SAVED as record - it is never judged; describe, then CHECK',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; describe the piece and CHECK anyway',
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
    var t = this._selText();
    var text;
    if (this._mode === 'verdict' && this._verdictResult) {
      text = this._verdictResult.tts + '建议：' + this._verdictResult.sugg.join('。');
    } else {
      text = '这件是' + t.color + '色' + t.pattern + t.fit + '的' + t.type +
        '，搭配' + t.pairColor + '色' + t.pairType + '，场合' + t.occasion + '。点检查看搭不搭。';
    }
    this._speakText(text);
  },

  // ---------- DEMO: 藏青纯色合身上衣 + 米色纯色裤子 + 上班 -> GOOD verdict ----------

  demoTap() {
    this._sel = {
      type: 0, color: 3, pattern: 0, fit: 1,
      pairType: 1, pairColor: 4, pairPattern: 0, occasion: 0
    };
    this._demo = true;
    this.setData({ photoLine: 'PHOTO: DEMO (no camera used) - record only anyway' });
    this.runCheck();
    this.setData({
      status: 'DEMO DONE - navy top + beige trousers for work: GOOD',
      lastEvent: 'EVT: DEMO verdict in (ASK AI here will honestly SKIP - no LLM in preview)'
    });
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">OUTFIT CHECK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{modeText}}</text>
    </view>
    <view class="look-box">
      <text class="box-label">◎ DESCRIBE THE PIECE - AGENT NEVER SEES IT: YOU DESCRIBE, RULES + AI ADVISE</text>
      <text class="photo">{{pieceLine}}</text>
      <text class="photo">{{pairLine}}</text>
      <text class="photo">{{photoLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="fieldTap">FIELD</button>
      <button class="btn" bindtap="valueTap">VALUE</button>
      <button class="btn" bindtap="lookTap">LOOK</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{editLine}}</text>
      <text class="box-label">{{verdictHead}}</text>
      <text class="step">{{verdictBody}}</text>
      <text class="photo">{{suggLine}}</text>
      <text class="photo">{{aiLine}}</text>
      <text class="photo">{{mirrorLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="checkTap">CHECK</button>
      <button class="btn" bindtap="aiTap">ASK AI</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="mirrorTap">MIRROR</button>
      <button class="btn" bindtap="demoTap">DEMO （藏青+米色·上班）</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 5px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 2px;
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
  padding: 4px 8px;
  margin-bottom: 3px;
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
  margin-bottom: 2px;
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
  padding: 4px 8px;
  margin-bottom: 3px;
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
