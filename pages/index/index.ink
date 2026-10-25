<script def>
{
  "navigationBarTitleText": "Food Safe"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'REGISTER WHAT YOU STORED, THEN CHECK IT BEFORE YOU EAT',
    steadyText: 'HEAD: moving - hold still',
    countText: 'ITEMS: 0/12',
    itemLine: 'ITEM: (none) - NAME a draft, ADD it, or DEMO',
    draftLine: 'DRAFT: name? · stored today · 冰箱冷藏 - NAME/DAY/STORE edit, ADD saves',
    guideLine: '眼镜测不出细菌：闻不到、看不出 ≠ 没细菌。拿不准就扔，别赌肠胃。',
    rows: [
      { name: '(empty)', detail: 'NAME, DAY, STORE, ADD - or DEMO', flag: '', cls: 'row' }
    ],
    promptHead: 'HOW IT WORKS - dates x YOUR senses; the agent detects NOTHING itself',
    promptBody: '先登记（哪天放的、放哪儿），吃之前逐项报：异味、黏滑、霉点、鼓胀。',
    promptSub: 'ITEM 选条目，四项逐个点按钮切换 有/无，再 VERDICT 给结论。',
    flag1: '异味：无', flag2: '黏滑：无', flag3: '霉点：无', flag4: '鼓胀：无',
    lastEvent: 'EVT: nod when steady in CHECK = VERDICT',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'list'; // list | check | verdict
    this._items = this._loadItems();
    this._sel = 0;
    this._flags = { smell: false, slimy: false, mold: false, bloat: false };
    this._verdict = null;
    this._draft = { name: '', daysAgo: 0, storage: 0 };
    this._presetIdx = -1;
    this._demo = false;
    this._demoTodayNum = null;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: ' + this._items.length + ' stored item(s) loaded' });
  },

  onUnload() {
    this._stopNameRec();
    this._saveItems();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    // A nod CONFIRMS the action of the current mode; it never answers a
    // sensory check for you - the four flags only move when YOU tap them.
    if (this._mode === 'check') this.verdictTap();
    else if (this._mode === 'verdict') this.backToList();
    else if (this._steady) this.enterCheck();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      var dir = code === 'ArrowUp' ? 1 : -1;
      this.cycleItem(dir);
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'check') this.verdictTap();
      else if (this._mode === 'verdict') this.backToList();
      else this.enterCheck();
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

  // ---------- dates: all arithmetic on UTC day numbers (no DST drift) ----------

  _pad(n) { return (n < 10 ? '0' : '') + n; },

  _dayNum(y, m, d) {
    return Math.floor(Date.UTC(y, m - 1, d) / 86400000);
  },

  _dayNumFromStr(s) {
    var p = String(s || '').split('-');
    if (p.length !== 3) return null;
    var y = parseInt(p[0], 10), m = parseInt(p[1], 10), d = parseInt(p[2], 10);
    if (!isFinite(y) || !isFinite(m) || !isFinite(d)) return null;
    return this._dayNum(y, m, d);
  },

  _strFromDayNum(n) {
    var dt = new Date(n * 86400000);
    return dt.getUTCFullYear() + '-' + this._pad(dt.getUTCMonth() + 1) + '-' + this._pad(dt.getUTCDate());
  },

  _todayNum() {
    if (this._demo && this._demoTodayNum !== null) return this._demoTodayNum;
    var now = new Date();
    return this._dayNum(now.getFullYear(), now.getMonth() + 1, now.getDate());
  },

  _todayStr() { return this._strFromDayNum(this._todayNum()); },

  _daysStored(item) {
    var sn = this._dayNumFromStr(item.storedDate);
    if (sn === null) return 0;
    var diff = this._todayNum() - sn;
    return diff < 0 ? 0 : diff; // a future stored-date is a data error; clamp, never negative
  },

  // ---------- general storage-life guide (COMMON ADVICE, not a rule) ----------
  // Labelled everywhere as 常见建议: typical fridge/freezer keeping times
  // from everyday food-safety guidance. It is a yardstick for the date
  // factor only - sensory red flags always beat it, and passing it never
  // proves food is fine (bacteria can be invisible and odourless).

  _storages() { return ['冰箱冷藏', '冰箱冷冻', '室温']; },

  _guideDays(item) {
    if (item.storage === '室温') return 0;
    if (item.storage === '冰箱冷冻') return 30;
    // 冰箱冷藏: raw sashimi-style items keep about a day; cooked
    // leftovers, opened milk etc. about 3 days.
    if (/生鱼片|刺身|生蚝|生肉/.test(item.name)) return 1;
    return 3;
  },

  _guideLabel(item) {
    var g = this._guideDays(item);
    if (item.storage === '室温') return '室温剩菜只建议当天（常见建议）';
    return '常见建议约 ' + g + ' 天（' + item.storage + '）';
  },

  // ---------- verdict: deterministic two-factor rules (Node-tested) ----------
  // flags: { smell, slimy, mold, bloat } - ALL reported by the wearer.
  //   1. mold or bloat            -> THROW (hard red flags, beat everything)
  //   2. smell or slimy           -> THROW (spoilage beats dates: food can
  //      go off BEFORE its guide days)
  //   3. days > guide             -> THROW (dates beat "looks fine":
  //      bacteria can be invisible and odourless)
  //   4. past half the guide days -> CAUTION (eat today, reheat thoroughly)
  //      room-temperature storage is at least CAUTION even on day 0
  //   5. else                     -> RELATIVELY OK - the word 相对 is
  //      mandatory; this agent never says 安全 / 没问题.

  _verdictFor(item, flags) {
    var days = this._daysStored(item);
    var guide = this._guideDays(item);
    var whens = item.name + '，' + item.storage + '已存 ' + days + ' 天。';
    if (flags.mold || flags.bloat) {
      var which = flags.mold && flags.bloat ? '霉点、鼓胀都有' : (flags.mold ? '有变色或霉点' : '包装鼓胀胀气');
      return {
        level: 'THROW', days: days, guide: guide,
        headline: '别吃 — 扔掉（红旗）',
        reason: '你报了「' + which + '」— 这是硬红旗，和放了几天无关，直接扔，不要尝、不要切掉再吃。',
        tts: whens + '你报了红旗，别吃，扔掉。'
      };
    }
    if (flags.smell || flags.slimy) {
      var which2 = flags.smell && flags.slimy ? '异味、黏滑都有' : (flags.smell ? '有异味' : '表面黏滑');
      return {
        level: 'THROW', days: days, guide: guide,
        headline: '别吃 — 扔掉（感官已坏）',
        reason: '你报了「' + which2 + '」— 感官变质优先于日期：没到建议天数也会坏，别吃。',
        tts: whens + '你报了变质迹象，别吃，扔掉。'
      };
    }
    if (days > guide) {
      return {
        level: 'THROW', days: days, guide: guide,
        headline: '别吃 — 已超建议天数',
        reason: '已存 ' + days + ' 天，超过' + this._guideLabel(item) + '。看着闻着正常也不行：有些细菌无色无味。',
        tts: whens + '已超过建议存放天数。看着正常也别吃，扔掉。'
      };
    }
    if (days * 2 > guide || item.storage === '室温') {
      return {
        level: 'CAUTION', days: days, guide: guide,
        headline: '谨慎 — 今天吃完，彻底加热',
        reason: '感官没报异常，但已存 ' + days + ' 天（' + this._guideLabel(item) + '）。要吃就今天吃完，剩菜彻底加热烧透；老人小孩孕妇拿不准就扔。',
        tts: whens + '谨慎。今天吃完，彻底加热。拿不准就扔。'
      };
    }
    return {
      level: 'OK', days: days, guide: guide,
      headline: '相对安心 — 尽快吃，剩菜彻底加热',
      reason: '感官四项都没报异常，已存 ' + days + ' 天，在' + this._guideLabel(item) + '之内。只是「相对」：眼镜测不出细菌，尽快吃完。',
      tts: whens + '相对安心。尽快吃，剩菜彻底加热。'
    };
  },

  // ---------- persistence (wx sync storage, key 'foodSafeItems', max 12) ----------

  _loadItems() {
    try {
      var raw = wx.getStorageSync('foodSafeItems');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      var storages = this._storages();
      for (var i = 0; i !== raw.length && out.length < 12; i++) {
        var it = raw[i];
        if (it && typeof it.name === 'string' && this._dayNumFromStr(it.storedDate) !== null
          && storages.indexOf(it.storage) >= 0) {
          out.push({
            name: String(it.name).slice(0, 12),
            storedDate: it.storedDate,
            storage: it.storage
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveItems() {
    if (this._demo) return; // demo items never touch real storage
    try {
      wx.setStorageSync('foodSafeItems', this._items || []);
    } catch (e) { /* storage unavailable on this host: list stays in memory */ }
  },

  // ---------- rendering ----------

  _selected() {
    if (!this._items.length) return null;
    if (this._sel < 0 || this._sel >= this._items.length) this._sel = 0;
    return this._items[this._sel];
  },

  _flagText() {
    var f = this._flags;
    return {
      flag1: '异味：' + (f.smell ? '有 !' : '无'),
      flag2: '黏滑：' + (f.slimy ? '有 !' : '无'),
      flag3: '霉点：' + (f.mold ? '有 !' : '无'),
      flag4: '鼓胀：' + (f.bloat ? '有 !' : '无')
    };
  },

  _renderAll() {
    var self = this;
    var rows = [];
    for (var i = 0; i !== this._items.length; i++) {
      var it = this._items[i];
      var days = this._daysStored(it);
      var guide = this._guideDays(it);
      var over = days > guide;
      rows.push({
        name: (i === this._sel ? '▶ ' : '') + it.name,
        detail: it.storedDate + ' 存入 · ' + it.storage + ' · 已存 ' + days + ' 天 / 建议约 ' + guide + ' 天',
        flag: over ? '!' : '',
        cls: over ? 'row row-urgent' : 'row'
      });
    }
    if (!rows.length) {
      rows.push({ name: '(empty)', detail: 'NAME, DAY, STORE, ADD - or DEMO', flag: '', cls: 'row' });
    }
    var sel = this._selected();
    var draft = this._draft;
    var draftDate = this._strFromDayNum(this._todayNum() - draft.daysAgo);
    var modeLabel = this._mode === 'check' ? 'CHECK' : this._mode === 'verdict' ? 'VERDICT' : 'LIST';
    var patch = {
      rows: rows,
      countText: 'ITEMS: ' + this._items.length + '/12 · MODE: ' + modeLabel + (this._demo ? ' · DEMO' : ''),
      itemLine: sel
        ? 'ITEM: ' + sel.name + ' · ' + sel.storage + ' · 已存 ' + this._daysStored(sel) + ' 天 · ' + this._guideLabel(sel)
        : 'ITEM: (none) - NAME a draft, ADD it, or DEMO',
      draftLine: 'DRAFT: ' + (draft.name ? draft.name : 'name?')
        + ' · ' + draftDate + ' 存（' + draft.daysAgo + ' 天前）· ' + this._storages()[draft.storage]
    };
    var ft = this._flagText();
    patch.flag1 = ft.flag1; patch.flag2 = ft.flag2; patch.flag3 = ft.flag3; patch.flag4 = ft.flag4;
    if (this._mode === 'check' && sel) {
      patch.promptHead = 'CHECK - ' + sel.name + ': report with YOUR nose, eyes, fingers';
      patch.promptBody = '逐项点按钮切换 有/无：异味、黏滑、霉点、鼓胀。报完点 VERDICT。';
      patch.promptSub = '当前：' + ft.flag1 + ' · ' + ft.flag2 + ' · ' + ft.flag3 + ' · ' + ft.flag4
        + ' — 点头只给结论，不替你报任何一项。';
    } else if (this._mode === 'verdict' && this._verdict && sel) {
      patch.promptHead = 'VERDICT - ' + sel.name + ' · 已存 ' + this._verdict.days + ' 天 · ' + this._verdict.level
        + (this._demo ? ' (DEMO)' : '');
      patch.promptBody = this._verdict.headline;
      patch.promptSub = this._verdict.reason;
    } else {
      patch.promptHead = 'HOW IT WORKS - dates x YOUR senses; the agent detects NOTHING itself';
      patch.promptBody = '先登记（哪天放的、放哪儿），吃之前逐项报：异味、黏滑、霉点、鼓胀。';
      patch.promptSub = 'ITEM 选条目，四项逐个点按钮切换 有/无，再 VERDICT 给结论。';
    }
    this.setData(patch);
  },

  backToList() {
    this._mode = 'list';
    this._renderAll();
  },

  // ---------- item selection / check flow ----------

  cycleItem(dir) {
    if (!this._items.length) {
      this.setData({ status: 'NO ITEMS YET - register one first (NAME, ADD) or DEMO' });
      return;
    }
    var n = this._items.length;
    this._sel = ((this._sel + dir) % n + n) % n;
    this._mode = 'list';
    this._flags = { smell: false, slimy: false, mold: false, bloat: false };
    this._verdict = null;
    this.setData({
      status: 'ITEM ' + (this._sel + 1) + '/' + n + ': ' + this._items[this._sel].name,
      lastEvent: 'EVT: item -> ' + this._items[this._sel].name
    });
    this._renderAll();
  },

  itemTap() { this.cycleItem(1); },

  enterCheck() {
    var sel = this._selected();
    if (!sel) {
      this.setData({ status: 'NOTHING TO CHECK - register an item first, or DEMO' });
      return;
    }
    this._mode = 'check';
    this._flags = { smell: false, slimy: false, mold: false, bloat: false };
    this._verdict = null;
    this.setData({
      status: 'CHECKING ' + sel.name + ' - smell it, look at it, touch it, then toggle honestly',
      lastEvent: 'EVT: check started for ' + sel.name
    });
    this._renderAll();
  },

  _toggleFlag(key, label) {
    var sel = this._selected();
    if (!sel) {
      this.setData({ status: 'NOTHING TO CHECK - register an item first, or DEMO' });
      return;
    }
    if (this._mode === 'list') this.enterCheckSilent();
    if (this._mode === 'verdict') {
      // Changing a report after a verdict invalidates it - back to CHECK.
      this._mode = 'check';
      this._verdict = null;
    }
    this._flags[key] = !this._flags[key];
    this.setData({
      status: 'CHECK ' + sel.name + ': ' + label + ' = ' + (this._flags[key] ? '有' : '无'),
      lastEvent: 'EVT: flag ' + label + ' -> ' + (this._flags[key] ? '有' : '无') + ' (wearer-reported)'
    });
    this._renderAll();
  },

  enterCheckSilent() {
    this._mode = 'check';
    this._flags = { smell: false, slimy: false, mold: false, bloat: false };
    this._verdict = null;
  },

  flag1Tap() { this._toggleFlag('smell', '异味'); },
  flag2Tap() { this._toggleFlag('slimy', '黏滑'); },
  flag3Tap() { this._toggleFlag('mold', '霉点'); },
  flag4Tap() { this._toggleFlag('bloat', '鼓胀'); },

  verdictTap() {
    var sel = this._selected();
    if (!sel) {
      this.setData({ status: 'NOTHING TO JUDGE - register an item first, or DEMO' });
      return;
    }
    if (this._mode === 'list') this.enterCheckSilent();
    this._verdict = this._verdictFor(sel, this._flags);
    this._mode = 'verdict';
    this.setData({
      status: 'VERDICT ' + this._verdict.level + ' - ' + this._verdict.headline,
      lastEvent: 'EVT: verdict ' + this._verdict.level + ' for ' + sel.name
        + ' (days ' + this._verdict.days + ' vs guide ' + this._verdict.guide + ')'
    });
    this._renderAll();
    this._speakText(this._verdict.tts);
  },

  delTap() {
    if (!this._items.length) {
      this.setData({ status: 'NOTHING TO DELETE' });
      return;
    }
    var gone = this._items.splice(this._sel, 1)[0];
    if (this._sel >= this._items.length) this._sel = Math.max(0, this._items.length - 1);
    this._mode = 'list';
    this._verdict = null;
    this._saveItems();
    this.setData({
      status: 'DELETED: ' + gone.name + ' (eaten, thrown or finished)',
      lastEvent: 'EVT: deleted ' + gone.name
    });
    this._renderAll();
  },

  // ---------- registration draft ----------

  _presets() { return ['剩米饭', '炖肉', '凉拌菜', '牛奶', '生鱼片']; },

  nameTap() {
    if (this.data.busy) return;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host - cycle the presets
      // instead of pretending to listen (same pattern as DI03/DI21).
      this._presetIdx = ((this._presetIdx || 0) + 1) % this._presets().length;
      this._draft.name = this._presets()[this._presetIdx];
      this.setData({
        status: 'NAME preset (ASR SKIP here): ' + this._draft.name,
        lastEvent: 'EVT: NAME preset -> ' + this._draft.name + ' (honest SKIP, no ASR)'
      });
      this._renderAll();
      return;
    }
    this._nameListen();
  },

  _stopNameRec() {
    if (this._nameRec) {
      try { this._nameRec.abort(); } catch (e) {}
      this._nameRec = null;
    }
  },

  async _nameListen() {
    var self = this;
    this.setData({ busy: true, status: 'NAME: checking wearer mic...' });
    // Wearer-mode mic check (documented getUserMedia audio constraints,
    // same pattern as DI11/DI21): the stream only verifies the mode opens;
    // recognition uses the benchmark SpeechRecognition.
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
      this._stopNameRec();
      var rec = new SpeechRecognition();
      this._nameRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // The name is kept VERBATIM and shown in the draft for the
          // wearer to eyeball before ADD stores it.
          self._draft.name = txt.slice(0, 12);
          self.setData({
            status: 'NAME heard: "' + self._draft.name + '" - eyeball it, DAY/STORE, then ADD',
            lastEvent: 'EVT: name heard verbatim (' + micNote + ')'
          });
          self._renderAll();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'NAME FAIL - ' + self._err(ev.error || ev) + ', tap NAME again (cycles presets if ASR n/a)',
          lastEvent: 'EVT: NAME ASR error'
        });
      };
      rec.onend = function () {
        if (self._nameRec === rec) self._nameRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'NAME listening (' + micNote + ') - say the food name...',
        lastEvent: 'EVT: NAME listening, ' + micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        status: 'NAME FAIL - ' + this._err(e),
        lastEvent: 'EVT: NAME start failed'
      });
    }
  },

  dayMinusTap() { this._stepDays(-1); },
  dayPlusTap() { this._stepDays(1); },

  _stepDays(dir) {
    var d = this._draft.daysAgo + dir;
    if (d < 0) d = 0;
    if (d > 14) d = 14;
    this._draft.daysAgo = d;
    this.setData({
      status: 'DRAFT stored date: ' + d + ' day(s) ago (' + this._strFromDayNum(this._todayNum() - d) + ')',
      lastEvent: 'EVT: draft daysAgo -> ' + d + ' (0-14)'
    });
    this._renderAll();
  },

  storeTap() {
    this._draft.storage = (this._draft.storage + 1) % this._storages().length;
    this.setData({
      status: 'DRAFT storage: ' + this._storages()[this._draft.storage],
      lastEvent: 'EVT: draft storage -> ' + this._storages()[this._draft.storage]
    });
    this._renderAll();
  },

  addTap() {
    if (!this._draft.name) {
      this.setData({ status: 'ADD NEEDS A NAME FIRST - tap NAME and say it (or cycle a preset)' });
      return;
    }
    if (this._items.length >= 12) {
      this.setData({ status: 'LIST FULL (12) - DEL an item that is eaten or thrown first' });
      return;
    }
    var item = {
      name: this._draft.name,
      storedDate: this._strFromDayNum(this._todayNum() - this._draft.daysAgo),
      storage: this._storages()[this._draft.storage]
    };
    this._items.push(item);
    this._sel = this._items.length - 1;
    this._mode = 'list';
    this._saveItems();
    this.setData({
      status: 'REGISTERED: ' + item.name + ' · ' + item.storage + ' · 存入 ' + item.storedDate,
      lastEvent: 'EVT: registered ' + item.name + ' (' + item.storedDate + ', ' + item.storage + ')'
    });
    this._draft = { name: '', daysAgo: 0, storage: 0 };
    this._renderAll();
  },

  // ---------- TTS ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - ' + text.slice(0, 24) });
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    var sel = this._selected();
    if (this._mode === 'verdict' && this._verdict) {
      this._speakText(this._verdict.tts);
      return;
    }
    if (!sel) {
      this._speakText('还没有登记的食物。先说出名字登记，或者点演示。');
      return;
    }
    var days = this._daysStored(sel);
    this._speakText(sel.name + '，' + sel.storage + '，已存' + days + '天。'
      + this._guideLabel(sel) + '。吃之前逐项检查异味、黏滑、霉点、鼓胀，再点结论。');
  },

  // ---------- DEMO: one Date snapshot; dates are pure day-number math ----------
  // Seeds: 炖肉 stored 4 days ago, 冰箱冷藏 (guide 3) with NO sensory
  // flags -> lands on the over-date THROW verdict, showing that dates
  // beat "looks fine". Plus 牛奶 1 day 冷藏 and 剩米饭 today 冷藏 so the
  // list shows the range. Demo items live in memory only.

  demoTap() {
    var snap = new Date(); // ONE snapshot - every demo date derives from it
    this._demoTodayNum = this._dayNum(snap.getFullYear(), snap.getMonth() + 1, snap.getDate());
    this._demo = true;
    var t = this._demoTodayNum;
    this._items = [
      { name: '剩米饭', storedDate: this._strFromDayNum(t), storage: '冰箱冷藏' },
      { name: '炖肉', storedDate: this._strFromDayNum(t - 4), storage: '冰箱冷藏' },
      { name: '牛奶', storedDate: this._strFromDayNum(t - 1), storage: '冰箱冷藏' }
    ];
    this._sel = 1; // 炖肉
    this._flags = { smell: false, slimy: false, mold: false, bloat: false };
    this._verdict = this._verdictFor(this._items[1], this._flags);
    this._mode = 'verdict';
    this.setData({
      status: 'DEMO VERDICT - dates beat "looks fine": 4d stored vs ~3d guide',
      lastEvent: 'EVT: DEMO seeded from one snapshot (today ' + this._strFromDayNum(t) + '), 炖肉 verdict shown'
    });
    this._renderAll();
    this._speakText(this._verdict.tts);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">FOOD SAFE</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{countText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">◎ SELECTED ITEM + DRAFT - guide days are COMMON ADVICE, not the app's rule</text>
      <text class="photo">{{itemLine}}</text>
      <text class="photo">{{draftLine}}</text>
      <text class="photo warn">{{guideLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nameTap">NAME</button>
      <button class="btn" bindtap="itemTap">ITEM</button>
      <button class="btn" bindtap="storeTap">STORE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="dayMinusTap">DAY-</button>
      <button class="btn" bindtap="dayPlusTap">DAY+</button>
      <button class="btn" bindtap="addTap">ADD</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <view class="plan-box">
      <text class="box-label">{{promptHead}}</text>
      <text class="step">{{promptBody}}</text>
      <text class="photo">{{promptSub}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="flag1Tap">{{flag1}}</button>
      <button class="btn" bindtap="flag2Tap">{{flag2}}</button>
      <button class="btn" bindtap="flag3Tap">{{flag3}}</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="flag4Tap">{{flag4}}</button>
      <button class="btn btn-main" bindtap="verdictTap">VERDICT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="delTap">DEL</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 4px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 1px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 22px;
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
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 8px;
  margin-bottom: 4px;
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
  line-height: 13px;
  margin-top: 2px;
}
.warn {
  color: rgba(64,255,94,0.72);
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
  padding: 1px;
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
.list {
  flex-shrink: 0;
  height: 30px;
  margin-bottom: 4px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.row-urgent .rname, .row-urgent .rdetail {
  color: #40ff5e;
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-right: 8px;
}
.rdetail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 15px;
  flex-grow: 1;
}
.rflag {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.plan-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 8px;
  margin-bottom: 4px;
}
.step {
  color: #40ff5e;
  font-size: 15px;
  line-height: 17px;
  margin-top: 2px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
