<script def>
{
  "navigationBarTitleText": "Proof Sweep"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '校对覆盖 — 逐行读完才算读完，跳过的行当场标漏读',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 未载入页面 — LOAD 拍照读页，或 DEMO 看示例页',
    bigLabel: '当前行 · —',
    bigText: '未载入页面',
    bigNote: 'LOAD 拍照读页 · DEMO 载入示例页 · 点行名直接跳读',
    capLine: 'CAP: none - LOAD 为整页拍照（default），模型读出行文本',
    rows: [],
    countLine: '已读 0/0 · 漏读 0 · 本页 — · 累计 — · 只存本次会话内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - photograph a page, then read it line by line',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'empty'; // empty | read | summary
    this._lines = []; // { text, state: 'todo'|'read'|'missed', src: null|'LLM'|'DEMO' }
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1: 3 read, 2: jump -> 3 missed, 3: summary missed, 4: missed fixed -> summary all-read
    this._summaryAllRead = false;
    this._clearArm = false;
    this._clearTimer = null;
    this._nodLock = false;
    this._archLines = 0;
    this._archRead = 0;
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the lines, the missed marks and
    // the page totals die with the page. Nothing was ever written to
    // any storage, so there is nothing to clean up - that IS the
    // design. Close the agent and the proof is gone, correctly.
    this._lines = [];
    this._archLines = 0;
    this._archRead = 0;
    if (this._clearTimer) { try { clearTimeout(this._clearTimer); } catch (e) {} this._clearTimer = null; }
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
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Nod discipline in THIS agent: a steady nod means ONE thing -
    // "this line is read" - and only in read mode on the focused
    // line. It never loads a page, never jumps, never finishes the
    // page, never clears anything, and is inert on the summary
    // screen and before any page is loaded.
    if (this._mode === 'read') {
      this._readLine('NOD');
      return;
    }
    this.setData({ lastEvent: 'EVT: nod ignored - nod only marks a line read in read mode' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.readTap();
    } else if (code === 'ArrowUp') {
      this.pageTap();
    } else if (code === 'ArrowDown') {
      this.prevPageTap();
    } else if (code === 'Backspace') {
      this.prevTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
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

  // The sample page used by DEMO only. Eight short contract lines:
  // long enough to demonstrate a skip, short enough to read at a
  // glance on the 480x352 canvas.
  _demoLines() {
    return [
      '第一条 本合同自双方签字之日起生效。',
      '第二条 服务期为十二个月，到期自动续约。',
      '第三条 费用按月结算，每月五日前支付。',
      '第四条 逾期未付的，按日加收千分之一。',
      '第五条 一方提前解约需提前三十日通知。',
      '第六条 争议提交签约地仲裁委员会仲裁。',
      '第七条 未尽事宜，双方另行书面补充约定。',
      '第八条 本合同一式两份，双方各执一份。'
    ];
  },

  _countRead() {
    var n = 0;
    for (var i = 0; i < this._lines.length; i++) if (this._lines[i].state === 'read') n++;
    return n;
  },

  _countMissed() {
    var n = 0;
    for (var i = 0; i < this._lines.length; i++) if (this._lines[i].state === 'missed') n++;
    return n;
  },

  _countTodo() {
    var n = 0;
    for (var i = 0; i < this._lines.length; i++) if (this._lines[i].state === 'todo') n++;
    return n;
  },

  _allDecided() {
    return this._lines.length > 0 && this._countTodo() === 0;
  },

  _firstTodo() {
    for (var i = 0; i < this._lines.length; i++) if (this._lines[i].state === 'todo') return i;
    return -1;
  },

  _firstMissed() {
    for (var i = 0; i < this._lines.length; i++) if (this._lines[i].state === 'missed') return i;
    return -1;
  },

  _hasReal() {
    for (var i = 0; i < this._lines.length; i++) {
      if (this._lines[i].src === 'LLM') return true;
    }
    return false;
  },

  _todoText() {
    var parts = [];
    for (var i = 0; i < this._lines.length; i++) {
      if (this._lines[i].state === 'todo') parts.push('第' + (i + 1) + '行');
    }
    return parts.join('、');
  },

  _missedText() {
    var parts = [];
    for (var i = 0; i < this._lines.length; i++) {
      if (this._lines[i].state === 'missed') parts.push('第' + (i + 1) + '行');
    }
    return parts.join('、');
  },

  _pagePct() {
    if (this._lines.length === 0) return 0;
    return Math.round(this._countRead() * 100 / this._lines.length);
  },

  _cumPct() {
    var total = this._archLines + this._lines.length;
    if (total === 0) return 0;
    return Math.round((this._archRead + this._countRead()) * 100 / total);
  },

  _disarm() {
    this._clearArm = false;
    if (this._clearTimer) { try { clearTimeout(this._clearTimer); } catch (e) {} this._clearTimer = null; }
  },

  _armClear() {
    this._disarm();
    this._clearArm = true;
    var self = this;
    this._clearTimer = setTimeout(function () {
      self._clearTimer = null;
      if (self._clearArm) {
        self._clearArm = false;
        self.setData({ lastEvent: 'EVT: clear disarmed (timeout) - page kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _clearAll() {
    this._lines = [];
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0;
    this._archLines = 0;
    this._archRead = 0;
    this._disarm();
    this._mode = 'empty';
    this.setData({
      capLine: 'CAP: none - LOAD 为整页拍照（default），模型读出行文本',
      status: '已清空 — 重新载入页面',
      lastEvent: 'EVT: page cleared by two-step DEL - session memory wiped'
    });
    this._renderAll();
  },
  // ---------- read / jump / reset: the ONLY ways a line changes state ----------

  _readLine(how) {
    if (this._mode !== 'read' || this._lines.length === 0) return;
    var it = this._lines[this._focus];
    if (!it) return;
    if (it.state === 'read') {
      this.setData({ lastEvent: 'EVT: ' + how + ' - line already read, NEXT moves on' });
      return;
    }
    var wasMissed = it.state === 'missed';
    var justRead = this._focus;
    it.state = 'read';
    if (!it.src) it.src = this._demo ? 'DEMO' : 'LLM';
    this._disarm();
    var next = this._firstTodo();
    if (next < 0) next = this._firstMissed();
    if (next >= 0) this._focus = next;
    this.setData({
      status: (wasMissed ? '已补读：' : '已读：') + '第' + (justRead + 1) + '行 — ' +
        (this._allDecided() ? '全部已决，点 FIN 看小结' : '已读 ' + this._countRead() + '/' + this._lines.length),
      lastEvent: 'EVT: line ' + (justRead + 1) + ' marked read by ' + how + (wasMissed ? ' (was missed, now fixed)' : '')
    });
    this._renderAll();
  },

  _jumpTo(idx) {
    if (this._mode !== 'read' || this._lines.length === 0) return;
    if (idx < 0 || idx >= this._lines.length) return;
    if (idx === this._focus) {
      this._readLine('TAP');
      return;
    }
    if (idx < this._focus) {
      // Moving back is re-reading, never a skip: no state changes.
      this._focus = idx;
      this._disarm();
      this.setData({
        status: '回到第' + (idx + 1) + '行重读 — 往回走不算跳行',
        lastEvent: 'EVT: focus back to line ' + (idx + 1) + ' (re-read, no skip)'
      });
      this._renderAll();
      return;
    }
    // Jumping forward: every unread line between the focus and the
    // tapped line is marked MISSED on the spot. Lines already read
    // stay read; only todo lines become missed. This is the skip
    // detector, and it fires at the moment of the jump, not later.
    var missed = [];
    for (var i = this._focus; i < idx; i++) {
      if (this._lines[i].state === 'todo') {
        this._lines[i].state = 'missed';
        missed.push('第' + (i + 1) + '行');
      }
    }
    this._focus = idx;
    this._disarm();
    if (missed.length > 0) {
      this.setData({
        status: '⚠ 跳行提醒：' + missed.join('、') + ' 被跳过，已标漏读 — 读完回来看这几行',
        lastEvent: 'EVT: jump ' + (idx + 1) + ' - lines missed: ' + missed.join(',')
      });
    } else {
      this.setData({
        status: '跳到第' + (idx + 1) + '行 — 中间行都已读过，无漏读',
        lastEvent: 'EVT: jump to line ' + (idx + 1) + ' - nothing missed'
      });
    }
    this._renderAll();
  },

  _resetLine() {
    if (this._mode !== 'read' || this._lines.length === 0) return;
    var it = this._lines[this._focus];
    if (!it) return;
    it.state = 'todo';
    it.src = null;
    this._disarm();
    this.setData({
      status: '已取消：第' + (this._focus + 1) + '行回到未读',
      lastEvent: 'EVT: line ' + (this._focus + 1) + ' reset to todo by DEL'
    });
    this._renderAll();
  },

  // ---------- page text parsing (LLM reply -> lines) ----------

  _parsePageRead(text) {
    if (!text) return null;
    var raw = String(text).split('\n');
    var lines = [];
    var lform = 0;
    for (var i = 0; i < raw.length; i++) {
      var t = raw[i].trim();
      if (!t) continue;
      var m = t.match(/^L(\d+)\s*[:：]\s*(.+)$/);
      if (m) { lines.push(m[2].trim()); lform++; }
    }
    if (lform > 0) {
      lines = lines.filter(function (s) { return s.length > 0; });
    } else {
      // Salvage: plain lines, one per row. A single prose sentence
      // is NOT a page: fewer than 3 lines is an unreadable reply,
      // never a guess.
      lines = [];
      for (var j = 0; j < raw.length; j++) {
        var s2 = raw[j].trim();
        if (s2) lines.push(s2);
      }
    }
    if (lines.length < 3) return null;
    if (lines.length > 12) lines = lines.slice(0, 12);
    return lines;
  },

  _buildReadContent(dataUrl) {
    var instr = 'This photo shows one page of a contract or manual. ' +
      'Transcribe ONLY the visible body lines, one per line, in exactly this format:\n' +
      'L1: <first line>\nL2: <second line>\n' +
      'Keep each line short and faithful to the photo. Do not summarise, ' +
      'do not add lines that are not visible, do not explain anything. ' +
      'If fewer than 3 lines are clearly readable, reply with exactly: NONE';
    return [
      { type: 'text', text: instr },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  async _llmRead(dataUrl) {
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
        initialPrompts: [{ role: 'system', content: 'You transcribe page lines from photos. Reply with only the requested L-lines. Never invent lines that are not visible.' }]
      });
      var ans = await this._withTimeout(session.prompt(this._buildReadContent(dataUrl)), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      if (/^NONE/i.test(String(ans).trim())) return { ok: false, reason: 'unreadable' };
      var v = this._parsePageRead(ans);
      if (v === null) return { ok: false, reason: 'unreadable' };
      return { ok: true, value: v };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  _readFailWhy(r) {
    return r.reason === 'no-lm' ? '这台设备没有大模型'
      : r.reason === 'unavailable' ? '大模型现在不可用'
      : r.reason === 'empty' ? '模型没有返回内容'
      : r.reason === 'unreadable' ? '照片里没读清至少 3 行'
      : '模型出错：' + this._err(r.error);
  },

  _setLines(texts, src) {
    this._lines = texts.map(function (t) {
      return { text: t, state: 'todo', src: src };
    });
    this._focus = 0;
    this._mode = 'read';
    this._renderAll();
  },

  // ---------- LOAD (default photo + LLM read) ----------

  loadTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: LOAD in DEMO - DEMO page is a sample; DEL twice clears it, then LOAD a real page' });
      return;
    }
    this.capturePhoto();
  },

  async capturePhoto() {
    if (this.data.busy) return;
    if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this._photoUnavailable('这台设备没有可用相机');
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (default) the page...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'default photo');
      var bytes = blob && blob.size ? blob.size : 0;
      this.setData({
        capLine: 'CAP: ' + bytes + 'B default · memory only, NOT saved',
        status: 'PHOTO HELD - reading its lines...',
        lastEvent: 'EVT: default photo ' + bytes + 'B for page (memory only, never persisted)'
      });
      this._renderAll();
      await this._doRead(blob);
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null;
      }
      try {
        var ctx = (typeof wx !== 'undefined' && wx.media && wx.media.createCameraContext)
          ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? (res.data.byteLength || 0) : 0;
        if (!size) throw firstErr;
        this.setData({
          capLine: 'CAP: ' + size + 'B wx cam (fallback) · memory only',
          status: '这张照片读不了（wx 回退照片无法转成图片发给模型）— 点 DEMO 看示例页',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - image read n/a)'
        });
        this._renderAll();
      } catch (e3) {
        this._photoUnavailable('拍照失败：' + this._err(firstErr));
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
      this.setData({ busy: false });
    }
  },

  async _doRead(blob) {
    if (typeof FileReader === 'undefined') {
      this.setData({
        status: '读不了这张照片（这台设备没有 FileReader）— 点 DEMO 看示例页',
        lastEvent: 'EVT: read n/a - FileReader missing'
      });
      this._renderAll();
      return;
    }
    var self = this;
    var dataUrl = await new Promise(function (resolve, reject) {
      var fr = new FileReader();
      fr.onload = function () { resolve(fr.result); };
      fr.onerror = function () { reject(new Error('FileReader error')); };
      fr.readAsDataURL(blob);
    }).catch(function (e) { return null; });
    if (!dataUrl) {
      this.setData({
        status: '读不了这张照片（转码失败）— 点 DEMO 看示例页',
        lastEvent: 'EVT: read n/a - FileReader conversion failed'
      });
      this._renderAll();
      return;
    }
    var r = await this._llmRead(dataUrl);
    if (!r.ok) {
      this.setData({
        status: '没读清（' + this._readFailWhy(r) + '）— 重拍一次，或点 DEMO 看示例页',
        lastEvent: 'EVT: page read FAILED (' + r.reason + ') - page kept empty'
      });
      this._renderAll();
      return;
    }
    this._demo = false;
    this._demoStage = 0;
    this._setLines(r.value, 'LLM');
    this.setData({
      status: '已载入 ' + r.value.length + ' 行 — 从第 1 行开始逐行读',
      lastEvent: 'EVT: page loaded by LLM - ' + r.value.length + ' lines'
    });
    this._renderAll();
  },

  _photoUnavailable(why) {
    this.setData({
      capLine: 'CAP: FAIL - ' + why,
      status: '拍照载入不可用（' + why + '）— 点 DEMO 看示例页，不影响逐行逻辑',
      lastEvent: 'EVT: LOAD FAIL (' + why + ') - page kept empty'
    });
    this._renderAll();
  },
  // ---------- buttons ----------

  readTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      // Back to reading to keep fixing; never fake a new summary.
      var back = this._firstMissed();
      if (back < 0) back = this._firstTodo();
      this._mode = 'read';
      this._focus = back >= 0 ? back : 0;
      this._disarm();
      this.setData({
        status: back >= 0 ? '回到逐行读 — 先补读漏读行：' + this._missedText() : '回到逐行读',
        lastEvent: 'EVT: summary -> read (keep fixing)'
      });
      this._renderAll();
      return;
    }
    if (this._mode !== 'read') {
      this.setData({ lastEvent: 'EVT: READ before any page - LOAD or DEMO first' });
      return;
    }
    this._readLine('READ');
  },

  prevTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode !== 'read' || this._lines.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV outside read mode - nothing to move' });
      return;
    }
    this._focus = (this._focus + this._lines.length - 1) % this._lines.length;
    this.setData({ lastEvent: 'EVT: focus -> line ' + (this._focus + 1) });
    this._renderAll();
  },

  nextTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode !== 'read' || this._lines.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT outside read mode - nothing to move' });
      return;
    }
    this._focus = (this._focus + 1) % this._lines.length;
    this.setData({ lastEvent: 'EVT: focus -> line ' + (this._focus + 1) });
    this._renderAll();
  },

  rowTap(event) {
    if (this.data.busy) return;
    var d = (event && event.currentTarget && event.currentTarget.dataset) || (event && event.dataset) || {};
    var idx = parseInt(d.idx, 10);
    if (isNaN(idx)) {
      this.setData({ lastEvent: 'EVT: row tap without index - ignored' });
      return;
    }
    this._jumpTo(idx);
  },

  finTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: FIN in summary - READ returns to reading, DEL twice clears' });
      return;
    }
    if (this._mode !== 'read' || this._lines.length === 0) {
      this.setData({ lastEvent: 'EVT: FIN before any page - LOAD or DEMO first' });
      return;
    }
    this._disarm();
    var todo = this._firstTodo();
    if (todo >= 0) {
      // Unread lines are NAMED before any summary is allowed. A
      // summary with a hole in it would be exactly the false
      // reassurance this agent exists to prevent.
      var n = this._countTodo();
      this.setData({
        status: '还差 ' + n + ' 行没读：' + this._todoText() + ' — 点行名直接跳读，跳过的行会标漏读',
        lastEvent: 'EVT: FIN refused - ' + n + ' lines still todo: ' + this._todoText()
      });
      this._renderAll();
      return;
    }
    this._mode = 'summary';
    this._summaryAllRead = this._countMissed() === 0;
    if (this._summaryAllRead) {
      this._speakText('本页全部读完，覆盖率百分之百');
      this.setData({
        status: '本页全部读完 ✓ 覆盖率 100%',
        lastEvent: 'EVT: summary all-read ' + this._lines.length + '/' + this._lines.length
      });
    } else {
      this._speakText('还有漏读行：' + this._missedText() + '，请先补读');
      this.setData({
        status: '有漏读行：' + this._missedText() + ' — 点 READ 回去补读',
        lastEvent: 'EVT: summary missed - lines: ' + this._missedText() + ' (never reported all-read)'
      });
    }
    this._renderAll();
  },

  pageTap() {
    if (this.data.busy) return;
    if (this._lines.length === 0) {
      this.setData({ lastEvent: 'EVT: PAGE before any page - LOAD or DEMO first' });
      return;
    }
    // Archive this page's totals, then start the next page empty.
    // The next page is a fresh LOAD/DEMO, never a copy of this one.
    this._archLines += this._lines.length;
    this._archRead += this._countRead();
    var arch = '已归档本页（' + this._countRead() + '/' + this._lines.length + '）— 下一页请 LOAD 或 DEMO';
    this._lines = [];
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0;
    this._disarm();
    this._mode = 'empty';
    this.setData({
      capLine: 'CAP: none - LOAD 为整页拍照（default），模型读出行文本',
      status: arch,
      lastEvent: 'EVT: page archived, totals now ' + this._archRead + '/' + this._archLines
    });
    this._renderAll();
  },

  prevPageTap() {
    if (this.data.busy) return;
    this.setData({ lastEvent: 'EVT: PREVPG - pages only move forward; use DEL twice to restart the document' });
  },

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      if (this._clearArm) { this._clearAll(); return; }
      this._armClear();
      this.setData({
        status: '⚠ 再点一次 DEL 清空整份文档重新读（其他动作取消）',
        lastEvent: 'EVT: clear 1/2 - ARMED (summary still kept)'
      });
      this._renderAll();
      return;
    }
    this._resetLine();
  },

  // ---------- SPEAK ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    if (this._mode === 'summary') {
      var t = this._summaryAllRead
        ? '本页全部读完，覆盖率百分之百。'
        : '还有漏读行：' + this._missedText() + '，请先补读。';
      if (this._speakText(t)) this.setData({ lastEvent: 'EVT: SPEAK summary (TTS, no lang set)' });
      return;
    }
    if (this._mode !== 'read' || this._lines.length === 0) {
      if (this._speakText('还没有载入页面')) this.setData({ lastEvent: 'EVT: SPEAK empty (TTS, no lang set)' });
      return;
    }
    var it = this._lines[this._focus];
    var line = '第' + (this._focus + 1) + '行，' + it.text +
      (it.state === 'read' ? '，已读。'
        : it.state === 'missed' ? '，漏读，请补读。'
        : '，还没读。');
    if (this._speakText(line)) this.setData({ lastEvent: 'EVT: SPEAK focus line (TTS, no lang set)' });
  },

  // ---------- DEMO (staged; never overwrites real decisions) ----------

  demoTap() {
    if (this.data.busy) return;
    if (this._hasReal()) {
      this.setData({ lastEvent: 'EVT: DEMO - real page lines exist, DEMO never overwrites them' });
      return;
    }
    if (this._demoStage === 4) {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
      return;
    }
    // Stage 3 -> 4 runs FROM the summary screen (fix the missed lines
    // there), so the summary guard must exempt it; any other DEMO tap
    // in summary is refused.
    if (this._mode === 'summary' && this._demoStage !== 3) {
      this.setData({ lastEvent: 'EVT: DEMO in summary - READ returns to reading first' });
      return;
    }
    var self = this;
    function setState(idx, state) {
      self._lines[idx].state = state;
      self._lines[idx].src = 'DEMO';
    }
    if (this._demoStage === 0) {
      this._setLines(this._demoLines(), 'DEMO');
      this._demo = true;
      setState(0, 'read'); setState(1, 'read'); setState(2, 'read');
      this._focus = 3;
      this._demoStage = 1;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated page (not a real photo read)',
        status: 'DEMO - 示例页已载入，前 3 行已读 — 点行名跳读看漏读提醒',
        lastEvent: 'EVT: DEMO stage 1 - sample page, 3 lines read'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      // Simulate the skip: the wearer jumps from line 4 to line 7,
      // so lines 4-6 become missed on the spot.
      setState(3, 'missed'); setState(4, 'missed'); setState(5, 'missed');
      this._focus = 6;
      this._demoStage = 2;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated page (not a real photo read)',
        status: 'DEMO - 已模拟跳行：第 4、5、6 行标漏读 — 再点 DEMO 读完并看小结',
        lastEvent: 'EVT: DEMO stage 2 - jump simulated, lines 4-6 missed'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      setState(6, 'read'); setState(7, 'read');
      this._mode = 'summary';
      this._summaryAllRead = false;
      this._demoStage = 3;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated page (not a real photo read)',
        status: 'DEMO - 小结：有漏读行：第 4、5、6 行 — 点 READ 回去补读',
        lastEvent: 'EVT: DEMO stage 3 - summary missed (simulated)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      setState(3, 'read'); setState(4, 'read'); setState(5, 'read');
      this._mode = 'summary';
      this._summaryAllRead = true;
      this._demoStage = 4;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated page (not a real photo read)',
        status: 'DEMO - 小结：本页全部读完 ✓ 覆盖率 100%',
        lastEvent: 'EVT: DEMO stage 4 - summary all-read (simulated)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._lines.length; i++) {
      var it = this._lines[i];
      rows.push({
        idx: i,
        name: '第' + (i + 1) + '行',
        detail: it.text,
        flag: it.state === 'read' ? '✓' : (it.state === 'missed' ? '⚠漏读' : '○'),
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已读 ' + this._countRead() + '/' + this._lines.length +
      ' · 漏读 ' + this._countMissed() +
      ' · 本页 ' + (this._lines.length ? this._pagePct() + '%' : '—') +
      ' · 累计 ' + ((this._archLines + this._lines.length) ? this._cumPct() + '%' : '—') +
      ' · 只存本次会话内存 · 关掉即清 · 零落盘';

    if (this._mode === 'empty') {
      patch.boxLabel = '◎ 未载入页面 — LOAD 拍照读页，或 DEMO 看示例页';
      patch.bigLabel = '当前行 · —';
      patch.bigText = '未载入页面';
      patch.bigNote = 'LOAD 拍照读页 · DEMO 载入示例页 · 点行名直接跳读';
    } else if (this._mode === 'read') {
      var f = this._lines[this._focus];
      patch.boxLabel = '◎ 逐行读 — 读完一行点 READ，点行名跳读会标漏读';
      patch.bigLabel = '当前行 · 第' + (this._focus + 1) + '行';
      patch.bigText = f ? f.text : '';
      patch.bigNote = !f ? ''
        : f.state === 'read' ? '✓ 已读 · NEXT/PREV 换行 · DEL 取消'
        : f.state === 'missed' ? '⚠ 漏读 — 点 READ 补读 · 跳过的行不会自己消失'
        : 'READ 读完进下一行 · 点行名跳读 · 头稳点头也可确认';
    } else {
      patch.boxLabel = '◎ 本页小结';
      patch.bigLabel = '本页小结';
      if (this._summaryAllRead) {
        patch.bigText = '本页全部读完';
        patch.bigNote = '覆盖率 100% · 累计 ' + this._cumPct() + '% · PAGE 下一页 · DEL 两下清空整份文档';
      } else {
        patch.bigText = '有漏读行';
        patch.bigNote = '漏读：' + this._missedText() + ' · 覆盖率 ' + this._pagePct() + '% · READ 回去补读';
      }
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
      <text class="title">PROOF SWEEP v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{capLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="loadTap">LOAD</button>
      <button class="btn btn-main" bindtap="readTap">READ ✓</button>
      <button class="btn" bindtap="prevTap">PREV</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="finTap">FIN</button>
      <button class="btn" bindtap="pageTap">PAGE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="delTap">DEL</button>
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
    <text class="foot2">读到哪行以你的逐行动作为准，Agent 没有眼球注视检测 · 行文本来自拍照模型读数，可能读错，DEMO 页为示例 · 只记本次会话，关掉即清</text>
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
