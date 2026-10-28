<script def>
{
  "navigationBarTitleText": "Shop Replay"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '购物回放 — 看中的商品按店面朝向登记，纠结时列出候选和当时拍的画面',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 登记 — NAME 选商品、PRICE 记价格、DIR 标店面朝向，SNAP 拍一张，MARK 登记一格',
    bigLabel: '购物登记 · 待机',
    bigText: '还没登记',
    bigNote: '商品 外套 · 价格 899元 · 朝向 前方 · SNAP 拍一张 · MARK 登记一格',
    permLine: 'PERM: CAMERA — 只拍当时画面（会话内）；价格是你记的数字，不是读出来的；不录音、不定位',
    rows: [],
    countLine: '已登记 0 件 · 最便宜 — · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - register a candidate per shop, then REPLAY to compare',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'register'; // register | replay | summary
    this._nameList = ['外套', '运动鞋', '背包', '围巾', '水杯'];
    this._nameIdx = 0;
    this._priceList = [899, 649, 459, 299, 129];
    this._priceIdx = 0;
    this._dirList = ['前方', '左前方', '右前方', '左方', '右方', '后方'];
    this._dirIdx = 0;
    this._items = []; // { name, price, dir, time, photo: 'shot'|'demo'|'none', bytes, dataUrl, demo } — session memory only
    this._photoPending = false;
    this._photoBytes = 0;
    this._photoDataUrl = null;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1-3 registered, 4 replay, 5 cheapest, 6 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the candidates and their
    // photos die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up —
    // that IS the design. Close the agent and the shopping
    // round is gone.
    this._mode = 'register';
    this._nameIdx = 0;
    this._priceIdx = 0;
    this._dirIdx = 0;
    this._items = [];
    this._photoPending = false;
    this._photoBytes = 0;
    this._photoDataUrl = null;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
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

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _timeLabel() {
    var d = new Date(this._now());
    var h = String(d.getHours());
    if (h.length < 2) h = '0' + h;
    var m = String(d.getMinutes());
    if (m.length < 2) m = '0' + m;
    return h + ':' + m;
  },

  _name() { return this._nameList[this._nameIdx]; },
  _price() { return this._priceList[this._priceIdx]; },
  _dir() { return this._dirList[this._dirIdx]; },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (_, reject) {
        setTimeout(function () { reject(new Error('timeout: ' + label)); }, ms);
      })
    ]);
  },

  // The cheapest candidate: pure arithmetic over prices YOU
  // wrote down. Ties go to the first registered. This is not
  // a price read from a tag and not a recommendation — it is
  // the minimum of your own numbers.
  _cheapestIdx() {
    if (this._items.length === 0) return -1;
    var best = 0;
    var i;
    for (i = 1; i < this._items.length; i++) {
      if (this._items[i].price < this._items[best].price) best = i;
    }
    return best;
  },

  _cheapest() {
    var i = this._cheapestIdx();
    return i < 0 ? null : this._items[i];
  },

  _photoLabel(photo) {
    if (photo === 'shot') return '已拍（会话内）';
    if (photo === 'demo') return 'DEMO 示例占位';
    return '未拍';
  },

  _addItem(photo, demo) {
    this._items.push({
      name: this._name(),
      price: this._price(),
      dir: this._dir(),
      time: this._timeLabel(),
      photo: photo,
      bytes: photo === 'shot' ? this._photoBytes : 0,
      dataUrl: photo === 'shot' ? this._photoDataUrl : null,
      demo: !!demo
    });
    this._focus = this._items.length - 1;
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect.
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
    // Nod discipline in THIS agent: a steady nod confirms the
    // current selection as a candidate (register), advances
    // the replay by one, or confirms the summary. It never
    // changes NAME, PRICE or DIR: those are selections, and a
    // nod must not silently pick one.
    if (this._mode === 'register') { this.markTap(); return; }
    if (this._mode === 'replay') { this.nextTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'register') this.markTap();
      else if (this._mode === 'replay') this.nextTap();
      else if (this._mode === 'summary') this._confirmSummary();
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

  // ---------- selection ----------

  nameTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: NAME refused - the product is picked while registering, not in replay or summary' });
      return;
    }
    this._nameIdx = (this._nameIdx + 1) % this._nameList.length;
    this.setData({
      status: '商品已选为 ' + this._name() + ' — PRICE 记价格，DIR 标店面朝向，MARK 登记一格',
      lastEvent: 'EVT: product set - ' + this._name()
    });
    this._renderAll();
  },

  priceTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: PRICE refused - the price is written down while registering, not in replay or summary' });
      return;
    }
    this._priceIdx = (this._priceIdx + 1) % this._priceList.length;
    this.setData({
      status: '价格已记为 ' + this._price() + '元 — 这是你记的数字，不是 Agent 从价签上读出来的',
      lastEvent: 'EVT: price set - ' + this._price() + '元'
    });
    this._renderAll();
  },

  dirTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: DIR refused - direction is marked while registering, not in replay or summary' });
      return;
    }
    this._dirIdx = (this._dirIdx + 1) % this._dirList.length;
    this.setData({
      status: '店面朝向已标为 ' + this._dir() + ' — 帮你想起那家店在哪个方向，不是带路',
      lastEvent: 'EVT: direction set - ' + this._dir()
    });
    this._renderAll();
  },

  // ---------- photo (session memory only, never persisted) ----------

  async snapTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: SNAP refused - the photo is taken while registering, not in replay or summary' });
      return;
    }
    if (this.data.busy) return;
    if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: '这台设备没有可用相机 — 先 MARK 登记一格（画面记为未拍），回放照样列出它',
        lastEvent: 'EVT: SNAP FAIL (mediaDevices n/a on this host) - register without a photo'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (wide) ' + this._name() + '...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'wide' }), 9000, 'wide photo');
      var bytes = blob && blob.size ? blob.size : 0;
      // The photo IS kept — as a data URL in session memory
      // only, on the candidate it gets MARKed onto. It is
      // never written to storage, and it dies with the page
      // (onUnload / summary confirm). The fleet UI is text
      // only, so the replay shows the shot as "已拍（会话内）"
      // plus its byte size rather than rendering a gallery;
      // the data itself is retained in-session, not just a
      // flag. A DEMO candidate carries no real photo: its
      // label says DEMO 示例占位, never a fake shot.
      var dataUrl = await this._blobToDataUrl(blob);
      this._photoPending = true;
      this._photoBytes = bytes;
      this._photoDataUrl = dataUrl;
      this.setData({
        status: '画面已拍 ' + bytes + 'B（wide，会话内）— MARK 登记一格就把它钉在这一格上',
        lastEvent: 'EVT: wide photo ' + bytes + 'B pending (memory only, never persisted)'
      });
      this._renderAll();
    } catch (e) {
      var firstErr = e;
      try {
        var ctx = (typeof wx !== 'undefined' && wx.media && wx.media.createCameraContext)
          ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this._photoPending = true;
        this._photoBytes = size;
        this._photoDataUrl = null; // wx fallback photo has no Blob to convert; the shot marker is kept, not the frame
        this.setData({
          status: '画面已拍 ' + size + 'B（wx 回退，会话内）— MARK 登记一格就把它钉在这一格上',
          lastEvent: 'EVT: wx photo ' + size + 'B pending (fallback, memory only)'
        });
        this._renderAll();
      } catch (e2) {
        this.setData({
          status: '拍照失败：' + this._err(firstErr) + ' — 先 MARK 登记一格（画面记为未拍），回放照样列出它',
          lastEvent: 'EVT: SNAP FAIL (' + this._err(firstErr) + ') - register without a photo'
        });
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e3) {}
      }
      this.setData({ busy: false });
    }
  },

  // ---------- register / replay / summary ----------

  markTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: MARK refused - candidates are registered while registering, not in replay or summary' });
      return;
    }
    var photo = this._photoPending ? 'shot' : 'none';
    this._addItem(photo, false);
    this._photoPending = false;
    this._photoBytes = 0;
    this._photoDataUrl = null;
    var it = this._items[this._items.length - 1];
    this.setData({
      status: '已登记：' + it.name + ' ' + it.price + '元 · ' + it.dir + ' · 画面' + this._photoLabel(it.photo) + ' — 继续登记，或 REPLAY 回放比价',
      lastEvent: 'EVT: candidate registered - ' + it.name + ' ' + it.price + '元 (' + it.dir + ', photo ' + it.photo + ')'
    });
    this._renderAll();
  },

  replayTap() {
    if (this._mode === 'replay') {
      this.setData({ lastEvent: 'EVT: REPLAY refused - candidate replay is already open' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: REPLAY refused - confirm or go back from the summary first' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: REPLAY refused - missing: 至少登记一格候选（MARK）' });
      return;
    }
    this._mode = 'replay';
    this._focus = 0;
    this.setData({
      status: '纠结回放 — 按登记顺序列出候选，NEXT/PREV 换格，CHEAP 跳到最便宜的一件',
      lastEvent: 'EVT: replay started (' + this._items.length + ' candidates)'
    });
    this._renderAll();
  },

  cheapTap() {
    if (this._mode !== 'replay') {
      this.setData({ lastEvent: 'EVT: CHEAP refused - the cheapest jump applies to the candidate replay, not while registering or in summary' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: CHEAP refused - missing: 至少登记一格候选（MARK）' });
      return;
    }
    var i = this._cheapestIdx();
    this._focus = i;
    var c = this._items[i];
    this.setData({
      status: '最便宜的一件：' + c.name + ' ' + c.price + '元 · ' + c.dir + ' — 这只是你记的价格里最小的，不是推荐',
      lastEvent: 'EVT: cheapest jump -> item ' + (i + 1) + ' (' + c.name + ' ' + c.price + '元)'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to replay without deleting.
      this._confirmSummary();
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: END refused - missing: 至少登记一格候选（MARK）' });
      return;
    }
    this._mode = 'summary';
    var c = this._cheapest();
    this._summary = {
      total: this._items.length,
      cheapestName: c.name,
      cheapestPrice: c.price,
      cheapestDir: c.dir
    };
    this.setData({
      status: '本次购物小结 — 最便宜的一件钉在下面，点 END 确认清空，BACK 返回回放',
      lastEvent: 'EVT: shopping ended - summary ready (total ' + this._items.length + ', cheapest ' + c.name + ' ' + c.price + '元)'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'register';
    this._nameIdx = 0;
    this._priceIdx = 0;
    this._dirIdx = 0;
    this._items = [];
    this._photoPending = false;
    this._photoBytes = 0;
    this._photoDataUrl = null;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '购物回放 — 看中的商品按店面朝向登记，纠结时列出候选和当时拍的画面',
      lastEvent: 'EVT: summary confirmed - shopping round cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to replay without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'replay';
      this._summary = null;
      this.setData({
        status: '纠结回放 — 按登记顺序列出候选，NEXT/PREV 换格，CHEAP 跳到最便宜的一件',
        lastEvent: 'EVT: back to replay - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'replay') {
      this._mode = 'register';
      this.setData({
        status: '购物登记 — 继续登记，或 REPLAY 回放比价',
        lastEvent: 'EVT: back to registering - candidates kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - MARK registers a candidate, REPLAY opens the replay' });
  },

  _focusLen() {
    if (this._mode === 'register') return this._items.length;
    if (this._mode === 'replay') return this._items.length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._focusLen()) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'register') {
      line = this._items.length === 0
        ? '还没登记：选商品、记价格、标朝向，MARK 登记一格'
        : '已登记 ' + this._items.length + ' 件，继续登记或回放';
    } else if (this._mode === 'replay') {
      if (this._items.length === 0) {
        line = '回放里暂无候选';
      } else {
        var cur = this._items[this._focus] || this._items[0];
        line = cur.name + '，' + cur.price + '元，' + cur.dir + '，画面' + this._photoLabel(cur.photo);
      }
    } else if (this._summary) {
      line = '本次购物小结：共 ' + this._summary.total + ' 件，最便宜是 ' + this._summary.cheapestName + ' ' + this._summary.cheapestPrice + '元，' + this._summary.cheapestDir;
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'register' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user replay is under way' });
      return;
    }
    if (this._mode === 'register' && !this._demo && this._items.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user candidates are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._nameIdx = 0; // 外套
      this._priceIdx = 0; // 899
      this._dirIdx = 1; // 左前方
      this._addItem('demo', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - coat 899元 left-front registered (DEMO sample, 1 candidate)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._nameIdx = 1; // 运动鞋
      this._priceIdx = 1; // 649
      this._dirIdx = 2; // 右前方
      this._addItem('demo', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - shoes 649元 right-front registered (DEMO sample, 2 candidates)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._nameIdx = 2; // 背包
      this._priceIdx = 2; // 459
      this._dirIdx = 0; // 前方
      this._addItem('demo', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - bag 459元 front registered (DEMO sample, 3 candidates)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.replayTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - replay open, focus on item 1 (coat 899元)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.cheapTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - cheapest jump to item 3 (bag 459元)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - summary (3 candidates, cheapest bag 459元, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, e;
    var list = this._items;
    var cheapest = this._cheapestIdx();
    if (list.length === 0) {
      rows.push({
        idx: 0,
        name: this._mode === 'replay' ? '回放里暂无候选' : (this._mode === 'summary' ? '小结里暂无候选' : '暂无候选'),
        detail: this._mode === 'register'
          ? '选商品、记价格、标朝向，SNAP 拍一张，MARK 登记一格'
          : '先回去登记至少一格候选',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < list.length; i++) {
        e = list[i];
        rows.push({
          idx: i,
          name: '件' + (i + 1) + ' · ' + e.time + ' · ' + e.dir + (i === cheapest && this._mode !== 'register' ? ' ★最便宜' : ''),
          detail: e.name + ' ' + e.price + '元 · 画面' + this._photoLabel(e.photo) + (e.demo ? '（DEMO 示例）' : ''),
          flag: this._focus === i ? '▶' : '✓',
          cls: 'row'
        });
      }
    }

    var c = this._cheapest();
    var patch = { rows: rows };
    patch.countLine = '已登记 ' + this._items.length + ' 件' +
      (c ? ' · 最便宜 ' + c.name + ' ' + c.price + '元' : ' · 最便宜 —') +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'register') {
      patch.boxLabel = '◎ 登记 — NAME 选商品、PRICE 记价格、DIR 标店面朝向，SNAP 拍一张，MARK 登记一格';
      patch.bigLabel = '购物登记 · 待机';
      patch.bigText = this._items.length === 0 ? '还没登记' : '已登记 ' + this._items.length + ' 件';
      patch.bigNote = '商品 ' + this._name() + ' · 价格 ' + this._price() + '元 · 朝向 ' + this._dir() +
        ' · 画面' + (this._photoPending ? '已拍待登记' : '未拍') + ' · MARK 登记一格';
    } else if (this._mode === 'replay') {
      patch.boxLabel = '◎ 纠结回放 — NEXT/PREV 换格，CHEAP 跳到最便宜的一件';
      patch.bigLabel = '纠结回放 · 第 ' + (this._focus + 1) + '/' + this._items.length + ' 件';
      var cur = this._items[this._focus] || this._items[0];
      patch.bigText = cur.name + ' ' + cur.price + '元';
      patch.bigNote = cur.time + ' · ' + cur.dir + ' · 画面' + this._photoLabel(cur.photo) +
        (cur.photo === 'shot' && cur.bytes ? ' ' + cur.bytes + 'B' : '') +
        (cur.demo ? '（DEMO 示例）' : '') + (this._focus === cheapest ? ' ★最便宜' : '');
    } else {
      patch.boxLabel = '◎ 本次购物小结 — 最便宜的一件钉在下面';
      patch.bigLabel = '本次购物小结';
      var s = this._summary || { total: 0, cheapestName: '—', cheapestPrice: 0, cheapestDir: '—' };
      patch.bigText = '最便宜 ' + s.cheapestName + ' ' + s.cheapestPrice + '元';
      patch.bigNote = '共 ' + s.total + ' 件 · 最便宜在 ' + s.cheapestDir + ' · 点 END 确认清空 · BACK 返回回放';
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
      <text class="title">SHOP REPLAY v1.0.0</text>
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
      <button class="btn btn-main" bindtap="nameTap">NAME</button>
      <button class="btn btn-main" bindtap="priceTap">PRICE</button>
      <button class="btn btn-main" bindtap="dirTap">DIR</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="replayTap">REPLAY</button>
      <button class="btn btn-main" bindtap="cheapTap">CHEAP</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="prevTap">PREV</button>
      <button class="btn" bindtap="endTap">END</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
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
    <text class="foot2">没有 OCR、没有商品识别——价格是你记的数字，不是 Agent 从价签上读出来的；画面是当时拍的照片原图（会话内），不是识别结果；店面朝向只是你登记时的头部方向，不是定位导航——回放的朝向帮你想起那家店在哪个方向，不是带路；只存本次购物会话，关掉即清；没有室内定位；零落盘</text>
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
  line-height: 28px;
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
  height: 80px;
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
