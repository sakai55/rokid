<script def>
{
  "navigationBarTitleText": "Buy Filter"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '购物过滤 — 先设清单+预算+忌口，扫货时只有三条件全满足的商品才亮，其余只计不打断',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — LIST 换清单，BUDGET 换预算，BAN 换忌口，START 开始扫货',
    bigLabel: '购物过滤 · 待机',
    bigText: '牛奶·面包·鸡蛋',
    bigNote: '预算 ≤50元/件 · 忌口：花生（DEMO 示例） · START 开始 · DEMO 走演示',
    permLine: 'PERM: CAMERA — telephoto 拍标签 + LLM 读品名/价格/配料做三条件比对；无商品数据库、无联网价格核验',
    rows: [],
    countLine: '已看过 0 件 · 符合 0 件 · 已过滤 0 件 · 只存本次购物内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - set the filter with LIST/BUDGET/BAN, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | shopping | summary
    this._listIdx = 0;
    this._lists = [
      ['牛奶', '面包', '鸡蛋'],
      ['苹果', '香蕉', '酸奶'],
      ['米', '面', '食用油']
    ];
    this._budgetIdx = 1;
    this._budgets = [30, 50, 100];
    this._banIdx = 1;
    this._bans = ['无', '花生', '乳糖', '麸质'];
    this._seen = []; // { time, name, price, ingr, pass, reason }
    this._banner = ''; // current pass product name, '' = none
    this._bannerPrice = 0;
    this._bannerReason = '';
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 shopping, 2 filtered, 3 pass, 4 filtered, 5 summary
    this._summary = null; // { seen, pass, filtered, passText } on summary screen
    this._nodLock = false;
    this._startAt = 0;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: filter settings, seen list,
    // banner and summary die with the page. Nothing was ever
    // written to any storage, so there is nothing to clean up -
    // that IS the design. Close the agent and the filter is gone;
    // the next shopping trip starts from a blank filter.
    this._seen = [];
    this._banner = '';
    this._bannerPrice = 0;
    this._bannerReason = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _list() { return this._lists[this._listIdx]; },

  _listText() { return this._list().join('·'); },

  _budget() { return this._budgets[this._budgetIdx]; },

  _ban() { return this._bans[this._banIdx]; },

  _seenCount() {
    return this._seen.length;
  },

  _passCount() {
    var n = 0;
    for (var i = 0; i < this._seen.length; i++) if (this._seen[i].pass) n++;
    return n;
  },

  _filteredCount() {
    return this._seenCount() - this._passCount();
  },

  _norm(s) {
    return String(s || '').toUpperCase().replace(/[\s\-]/g, '');
  },

  // The ONLY match rule, stated everywhere it matters. A product
  // passes only when ALL THREE hold: (1) its name contains a
  // list keyword, (2) its price is at most the per-item budget,
  // (3) its ingredients do not contain the ban keyword (or the
  // ban is 无）. There is no product database and no live price
  // check: name, price and ingredients all come from the LLM
  // reading the photo, so a misread means a wrong judgement,
  // and the UI says so.
  _checkProduct(name, price, ingr) {
    var nName = this._norm(name);
    var nIngr = this._norm(ingr);
    var inList = false;
    for (var i = 0; i < this._list().length; i++) {
      if (nName.indexOf(this._norm(this._list()[i])) !== -1) { inList = true; break; }
    }
    var priceOk = (typeof price === 'number') && !isNaN(price) && price <= this._budget();
    var banOk = this._ban() === '无' || nIngr.indexOf(this._norm(this._ban())) === -1;
    var fails = [];
    if (!inList) fails.push('不在清单内');
    if (!priceOk) fails.push('超预算');
    if (!banOk) fails.push('含忌口');
    var banNote = this._ban() === '无' ? '无忌口' : '无' + this._ban();
    return {
      pass: inList && priceOk && banOk,
      reason: (inList && priceOk && banOk)
        ? ('在清单内 · ' + price + '元 ≤ ' + this._budget() + '元 · ' + banNote)
        : ('不符：' + fails.join('、'))
    };
  },

  _speakText(text) {
    // TTS via the host voice. The utterance lang is never set:
    // the documented behaviour is that it does not take effect.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (only nod is documented)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod confirms only
    // where confirmation is safe - START in idle, CONFIRM on the
    // summary screen. In live shopping a nod is ignored on
    // purpose: a photo must be a deliberate tap, never an
    // accidental nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored - nod never snaps a photo mid-shop' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'shopping') this.photoTap();
      else this._confirmSummary();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.backTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- shopping control ----------

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already shopping or a summary is open' });
      return;
    }
    this._mode = 'shopping';
    this._seen = [];
    this._banner = '';
    this._bannerPrice = 0;
    this._bannerReason = '';
    this._summary = null;
    this._focus = 0;
    this._startAt = this._now();
    this.setData({
      status: '扫货进行中 — 只有三条件全满足的商品才亮，其余只计不打断',
      lastEvent: 'EVT: shopping started (list ' + this._listText() + ', budget ≤' + this._budget() + '元， ban ' + this._ban() + ')'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode !== 'shopping') {
      this.setData({ lastEvent: 'EVT: END refused - no live shopping' });
      return;
    }
    this._mode = 'summary';
    var passes = [];
    for (var i = 0; i < this._seen.length; i++) if (this._seen[i].pass) passes.push(this._seen[i]);
    this._summary = {
      seen: this._seenCount(),
      pass: this._passCount(),
      filtered: this._filteredCount(),
      passText: passes.length ? passes.map(function (p) { return p.name + ' ' + p.price + '元'; }).join('；') : '无符合商品'
    };
    this.setData({
      status: '购物小结 — 确认后清空本次记录',
      lastEvent: 'EVT: shopping ended - summary ready (seen ' + this._summary.seen + ', pass ' + this._summary.pass + ', filtered ' + this._summary.filtered + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._seen = [];
    this._banner = '';
    this._bannerPrice = 0;
    this._bannerReason = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this.setData({
      status: '购物过滤 — 先设清单+预算+忌口，扫货时只有三条件全满足的商品才亮，其余只计不打断',
      lastEvent: 'EVT: summary confirmed - shopping data cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to live shopping without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'shopping';
      this._summary = null;
      this.setData({
        status: '扫货进行中 — 只有三条件全满足的商品才亮，其余只计不打断',
        lastEvent: 'EVT: back to live shopping - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - END finishes shopping, DEL clears a banner' });
  },

  nextTap() {
    if (this._seen.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - seen list is empty' });
      return;
    }
    this._focus = (this._focus + 1) % this._seen.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> entry ' + (this._focus + 1) });
  },

  prevTap() {
    if (this._seen.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - seen list is empty' });
      return;
    }
    this._focus = (this._focus - 1 + this._seen.length) % this._seen.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> entry ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._seen.length) return;
    this._focus = idx;
    var ev = this._seen[idx];
    this.setData({ lastEvent: 'EVT: entry ' + (idx + 1) + ' - ' + ev.name + ' ' + ev.price + '元 · ' + ev.reason });
    this._renderAll();
  },

  // ---------- filter settings (idle-only) ----------

  listTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: LIST refused - filter is set before shopping, never mid-shop' });
      return;
    }
    this._listIdx = (this._listIdx + 1) % this._lists.length;
    this.setData({ lastEvent: 'EVT: list set to ' + this._listText() + ' (DEMO sample list)' });
    this._renderAll();
  },

  budgetTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: BUDGET refused - filter is set before shopping, never mid-shop' });
      return;
    }
    this._budgetIdx = (this._budgetIdx + 1) % this._budgets.length;
    this.setData({ lastEvent: 'EVT: budget set to ≤' + this._budget() + '元/件' });
    this._renderAll();
  },

  banTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: BAN refused - filter is set before shopping, never mid-shop' });
      return;
    }
    this._banIdx = (this._banIdx + 1) % this._bans.length;
    this.setData({ lastEvent: 'EVT: ban set to ' + this._ban() });
    this._renderAll();
  },

  delTap() {
    if (this._mode === 'shopping') {
      // DEL only clears the pass banner - it never deletes the
      // seen list or ends the shopping.
      this._banner = '';
      this._bannerPrice = 0;
      this._bannerReason = '';
      this.setData({ lastEvent: 'EVT: banner cleared - shopping and seen list kept' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEL ignored - nothing to clear here' });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '购物过滤待机，清单 ' + this._listText() + '，预算 ' + this._budget() + '元以内，忌口 ' + this._ban();
    } else if (this._mode === 'shopping') {
      if (this._banner) {
        line = '符合：' + this._banner + '，' + this._bannerPrice + '元，' + this._bannerReason;
      } else {
        line = '扫货进行中，已看过 ' + this._seenCount() + ' 件，符合 ' + this._passCount() + ' 件，已过滤 ' + this._filteredCount() + ' 件';
      }
    } else if (this._summary) {
      line = '购物小结：看过 ' + this._summary.seen + ' 件，符合 ' + this._summary.pass + ' 件，已过滤 ' + this._summary.filtered + ' 件，' + this._summary.passText;
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- photo + read (telephoto photo -> data: URL -> host LLM image input) ----------

  _withTimeout(promise, ms, what) {
    var self = this;
    return new Promise(function (resolve, reject) {
      var done = false;
      var timer = setTimeout(function () {
        if (!done) { done = true; reject(new Error(what + ' timeout')); }
      }, ms);
      promise.then(function (v) {
        if (!done) { done = true; clearTimeout(timer); resolve(v); }
      }, function (e) {
        if (!done) { done = true; clearTimeout(timer); reject(e); }
      });
    });
  },

  _blobToDataUrl(blob) {
    return new Promise(function (resolve, reject) {
      try {
        var r = new FileReader();
        r.onload = function () { resolve(r.result); };
        r.onerror = function () { reject(new Error('FileReader error')); };
        r.readAsDataURL(blob);
      } catch (e) { reject(e); }
    });
  },

  async _llmReadLabel(dataUrl) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return { ok: false, reason: 'no-lm' };
    var avail;
    try {
      avail = await LM.availability();
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    }
    if (avail !== 'available') return { ok: false, reason: 'unavailable' };
    var session = null;
    try {
      session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You read product labels from photos. Reply with exactly one line in the form: name|price|ingredients, e.g. 纯牛奶|28|牛奶. Never invent a name, price or ingredient that is not visible.' }]
      });
      var ans = await this._withTimeout(session.prompt([{ role: 'user', content: [{ type: 'image', image: dataUrl }, { type: 'text', text: 'Read this product label. Reply with exactly one line: name|price|ingredients.' }] }]), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var line = String(ans).trim().split('\n')[0].trim().slice(0, 80);
      if (!line) return { ok: false, reason: 'unreadable' };
      return { ok: true, text: line };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  // Parse one LLM label line. A line that does not carry a
  // usable name AND a numeric price is a failed read, not a
  // product: the wearer did not actually see a price, so
  // judging it against the budget would be invented.
  _parseLabel(line) {
    var parts = String(line || '').split('|').map(function (p) { return p.trim(); });
    if (parts.length < 3) return { ok: false };
    var name = parts[0];
    var price = parseFloat(parts[1].replace(/[^0-9.]/g, ''));
    var ingr = parts[2];
    if (!name || isNaN(price)) return { ok: false };
    return { ok: true, name: name, price: price, ingr: ingr };
  },

  async photoTap() {
    if (this._mode !== 'shopping') {
      this.setData({ lastEvent: 'EVT: PHOTO refused - start shopping first' });
      return;
    }
    if (this.data.busy) return;
    this.setData({ busy: true, status: '拍标签中（telephoto）…' });
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('camera unavailable on this host');
      }
      var stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      var blob;
      try {
        if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
        var cap = new ImageCapture(track);
        blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
      } finally {
        try { stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {}
      }
      var dataUrl = await this._withTimeout(this._blobToDataUrl(blob), 12000, 'convert');
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) throw new Error('photo did not convert to a data: URL');
      var r = await this._llmReadLabel(dataUrl);
      if (!r.ok) {
        var why = r.reason === 'no-lm' ? '这台设备没有大模型'
          : r.reason === 'unavailable' ? '大模型现在不可用'
          : r.reason === 'empty' ? '模型没有返回内容'
          : r.reason === 'unreadable' ? '标签没读清'
          : '模型出错：' + this._err(r.error);
        this.setData({
          status: '没读出来（' + why + '）— 不计入已看过，重拍一次',
          lastEvent: 'EVT: READ FAIL (' + r.reason + ') - not counted, retake'
        });
        this._renderAll();
        return;
      }
      var parsed = this._parseLabel(r.text);
      if (!parsed.ok) {
        this.setData({
          status: '读数格式不全（缺品名或价格）— 不计入已看过，重拍一次',
          lastEvent: 'EVT: PARSE FAIL - not counted, retake'
        });
        this._renderAll();
        return;
      }
      // A failed read is never counted: the wearer did not
      // actually see a product's name and price.
      this._onProductRead(parsed.name, parsed.price, parsed.ingr);
    } catch (e) {
      this.setData({
        status: '拍照/读标签不可用 — 不计入已看过，重拍一次',
        lastEvent: 'EVT: PHOTO FAIL - ' + this._err(e)
      });
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  // The single decision point for every read product, real or
  // DEMO: pass -> banner + one TTS; fail -> silent filtered
  // count only, no banner, no TTS.
  _onProductRead(name, price, ingr) {
    if (this._mode !== 'shopping') return;
    var n = String(name || '').trim();
    if (!n) {
      this.setData({ lastEvent: 'EVT: empty product read ignored - not counted' });
      return;
    }
    var check = this._checkProduct(n, price, ingr);
    this._seen.push({ time: '第' + (this._seen.length + 1) + '件', name: n, price: price, ingr: ingr, pass: check.pass, reason: check.reason });
    this._focus = this._seen.length - 1;
    if (check.pass) {
      this._banner = n;
      this._bannerPrice = price;
      this._bannerReason = check.reason;
      var phrase = '符合：' + n + '，' + price + '元，' + check.reason;
      this._speakText(phrase);
      this.setData({
        status: '符合 — 只有三条件全满足的商品才亮',
        lastEvent: 'EVT: PASS (' + n + ' ' + price + '元） - banner + TTS'
      });
    } else {
      this.setData({
        status: '扫货进行中 — 只有三条件全满足的商品才亮，其余只计不打断',
        lastEvent: 'EVT: filtered (no pass) ' + n + ' ' + price + '元 · ' + check.reason + ' - counted silently'
      });
    }
    this._renderAll();
  },

  // ---------- DEMO (staged, labelled, never overwrites a user shop) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode === 'shopping' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user shopping is running' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._mode = 'shopping';
      this._listIdx = 0;
      this._budgetIdx = 1;
      this._banIdx = 1;
      this._seen = [];
      this._banner = '';
      this._bannerPrice = 0;
      this._bannerReason = '';
      this._summary = null;
      this._focus = 0;
      this._startAt = this._now();
      this.setData({
        status: 'DEMO - 扫货进行中（示例数据，非真实拍照）',
        lastEvent: 'EVT: DEMO stage 1 - shopping started (list 牛奶·面包·鸡蛋， budget ≤50元， ban 花生， DEMO sample filter)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onProductRead('花生酱', 35, '花生');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - filtered silently (花生酱 · 不在清单内、含忌口， no banner, no TTS)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onProductRead('纯牛奶', 28, '牛奶');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - PASS banner + TTS (纯牛奶 28元）' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._onProductRead('进口巧克力', 120, '可可');
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - filtered silently (进口巧克力 · 不在清单内、超预算， no banner, no TTS)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this._mode = 'summary';
      var passes = [];
      for (var i = 0; i < this._seen.length; i++) if (this._seen[i].pass) passes.push(this._seen[i]);
      this._summary = {
        seen: this._seenCount(),
        pass: this._passCount(),
        filtered: this._filteredCount(),
        passText: passes.length ? passes.map(function (p) { return p.name + ' ' + p.price + '元'; }).join('；') : '无符合商品'
      };
      this.setData({
        status: 'DEMO - 购物小结（示例数据）',
        lastEvent: 'EVT: DEMO stage 5 - summary (seen 3, pass 1, filtered 2)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._seen.length; i++) {
      var ev = this._seen[i];
      rows.push({
        idx: i,
        name: ev.time + ' · ' + ev.name + ' ' + ev.price + '元',
        detail: ev.pass ? '符合' : '已过滤（' + ev.reason + '）',
        flag: ev.pass ? '!' : '·',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已看过 ' + this._seenCount() + ' 件 · 符合 ' + this._passCount() + ' 件 · 已过滤 ' + this._filteredCount() + ' 件' +
      ' · 只存本次购物内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — LIST 换清单，BUDGET 换预算，BAN 换忌口，START 开始扫货';
      patch.bigLabel = '购物过滤 · 待机';
      patch.bigText = this._listText();
      patch.bigNote = '预算 ≤' + this._budget() + '元/件 · 忌口：' + this._ban() + '（DEMO 示例） · START 开始 · DEMO 走演示';
    } else if (this._mode === 'shopping') {
      if (this._banner) {
        patch.boxLabel = '◎ 符合 — 只有三条件全满足的商品才亮';
        patch.bigLabel = '符合';
        patch.bigText = this._banner;
        patch.bigNote = this._bannerPrice + '元 · ' + this._bannerReason + ' · DEL 只清横幅，不动已看过';
      } else {
        patch.boxLabel = '◎ 扫货进行中 — 只有三条件全满足的商品才亮，其余只计不打断';
        patch.bigLabel = '扫货进行中';
        patch.bigText = '已看过 ' + this._seenCount() + ' 件';
        patch.bigNote = '清单：' + this._listText() + ' · 预算 ≤' + this._budget() + '元 · 忌口：' + this._ban() + ' · PHOTO 拍标签读价';
      }
    } else {
      patch.boxLabel = '◎ 购物小结';
      patch.bigLabel = '购物小结';
      var s = this._summary || { seen: 0, pass: 0, filtered: 0, passText: '无符合商品' };
      patch.bigText = '符合 ' + s.pass + ' 件 · 已过滤 ' + s.filtered + ' 件';
      patch.bigNote = '符合：' + s.passText + ' · 确认后清空本次记录';
    }
    patch.bigCls = this._bigClsFor(patch.bigText);
    this.setData(patch);
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">BUY FILTER v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{permLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="demoTap">DEMO</button>
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn" bindtap="photoTap">PHOTO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="listTap">LIST</button>
      <button class="btn" bindtap="budgetTap">BUDGET</button>
      <button class="btn" bindtap="banTap">BAN</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="endTap">END</button>
      <button class="btn" bindtap="backTap">BACK</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">三条件全满足才亮：品名含清单词 + 价格 ≤ 预算 + 配料不含忌口词 · 品名/价格/配料只来自 LLM 对照片的读数，读数错则判断错 · 无商品数据库、无联网价格核验 · 只存本次购物，关掉即清</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 2px 12px;
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
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.biglabel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.bignum {
  color: #40ff5e;
  font-size: 34px;
  font-weight: 500;
  line-height: 38px;
  margin-top: 1px;
}
.bignum-sm {
  color: #40ff5e;
  font-size: 24px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-xs {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 1px;
}
.bignote {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
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
  height: 95px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 12px;
}
</style>
