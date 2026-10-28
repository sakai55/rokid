<script def>
{
  "navigationBarTitleText": "Number Catch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '看向号码 SNAP 读下来 — 不用再一路默念',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 已存号码 — 滑动选择，OK 放大常驻显示',
    capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
    bigLabel: '（还没有存号码）',
    bigNumber: '----',
    bigNote: 'SNAP 拍号码 / DICT 口述 / 步进手填 / DEMO 演示',
    micLine: 'MIC CHECK: not run',
    rows: [
      { name: '(no numbers)', detail: 'SNAP a number, confirm it, it stays here - or DEMO', flag: '', cls: 'row' }
    ],
    countLine: 'SAVED: 0/6 · text saved on device · photos NOT saved',
    lastEvent: 'EVT: ready - a number is stored only after YOU confirm it',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'list'; // list | catch | confirm | show
    this._entries = this._loadEntries(); // confirmed TEXT entries only
    this._sel = this._entries.length ? 0 : -1;
    this._labelIdx = 0; // label chip for the next catch
    this._pending = null; // unconfirmed catch in progress (photo Blob lives here, memory only)
    this._catchText = '';
    this._catchSrc = '';
    this._clearArmIdx = -1; // two-step clear: entry index currently armed, -1 = none
    this._nodLock = false;
    this._armTimer = null;
    this._demo = false;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: ' + this._entries.length + ' confirmed number(s) on this device' });
  },

  onShow() {},

  onHide() {
    this._stopDictRec();
    this._disarm();
  },

  onUnload() {
    this._stopDictRec();
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
    this._saveEntries();
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
    // Nod discipline (PLAN exception, this agent only): a nod is
    // NEVER destructive outside the recall display, and even there
    // it takes TWO steady nods - the first only arms the clear.
    if (this._mode === 'show') {
      this._nodClearStep();
    } else if (this._mode === 'list') {
      this.speakTap();
      this.setData({ lastEvent: 'EVT: nod in list = SPEAK (nod never deletes here)' });
    } else if (this._mode === 'confirm') {
      this.setData({ lastEvent: 'EVT: nod ignored in confirm - press OK to store, nod never stores' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored while catching - SNAP / DICT / step first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.okTap();
    } else if (code === 'ArrowDown') {
      // Editing a number: down = -1. Navigating: down = next item.
      this._stepOrMove(this._mode === 'confirm' ? -1 : 1, 'key');
    } else if (code === 'ArrowUp') {
      // Editing a number: up = +1. Navigating: up = previous item.
      this._stepOrMove(this._mode === 'confirm' ? 1 : -1, 'key');
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook') {
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

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // ONE clock snapshot -> "HH:MM" (preview host Date drifts between
  // calls, so one entry's time comes from one read - DI25/DI38 lesson).
  _stamp() {
    var d = new Date();
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
  },

  _labels() {
    return ['房号', '快递柜', '取餐号', '车位', '其他'];
  },

  _curLabel() {
    if (this._pending) return this._pending.label;
    return this._labels()[this._labelIdx];
  },

  // ---------- persistence (wx sync storage, key 'numberCatch', max 6, TEXT ONLY) ----------

  _loadEntries() {
    try {
      var raw = wx.getStorageSync('numberCatch');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 6; i++) {
        var it = raw[i];
        if (it && typeof it.number === 'string' && it.number) {
          out.push({
            label: String(it.label || '其他').slice(0, 6),
            number: String(it.number).slice(0, 16),
            time: String(it.time || '').slice(0, 5)
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveEntries() {
    if (this._demo) return; // demo entries never touch real storage
    try {
      wx.setStorageSync('numberCatch', this._entries || []);
    } catch (e) { /* storage unavailable on this host: entries stay in memory */ }
  },

  // ---------- two-step clear arming ----------

  _disarm() {
    this._clearArmIdx = -1;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  _armClear(idx) {
    this._clearArmIdx = idx;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} }
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._clearArmIdx === idx) {
        self._clearArmIdx = -1;
        self.setData({ lastEvent: 'EVT: clear disarmed (timeout) - nothing deleted' });
        self._renderAll();
      }
    }, 6000);
  },

  _clearEntry(idx, how) {
    if (idx < 0 || idx >= this._entries.length) return;
    var gone = this._entries.splice(idx, 1)[0];
    this._disarm();
    this._saveEntries();
    if (this._sel >= this._entries.length) this._sel = this._entries.length - 1;
    if (this._mode === 'show') this._mode = 'list';
    this._speakText('已清除' + gone.label + '号码');
    this.setData({
      status: 'CLEARED ✓ ' + gone.label + ' ' + gone.number + ' — 还剩 ' + this._entries.length + '/6 条',
      lastEvent: 'EVT: cleared ' + gone.label + ' ' + gone.number + ' by ' + how + ' (two-step, spoken once)'
    });
    this._renderAll();
  },

  _nodClearStep() {
    var idx = this._sel;
    if (idx < 0 || idx >= this._entries.length) return;
    if (this._clearArmIdx === idx) {
      this._clearEntry(idx, 'second nod');
    } else {
      this._armClear(idx);
      this.setData({
        status: '⚠ 再点头一次清除 ' + this._entries[idx].label + ' ' + this._entries[idx].number + '（其他动作取消）',
        lastEvent: 'EVT: nod 1/2 - clear ARMED for ' + this._entries[idx].label + ' (nothing deleted yet)'
      });
      this._renderAll();
    }
  },

  // ---------- selection / stepping (dispatch by mode) ----------

  _moveSel(delta) {
    this._disarm();
    if (!this._entries.length) {
      this.setData({ lastEvent: 'EVT: no entries to select yet' });
      return;
    }
    var n = this._entries.length;
    this._sel = (((this._sel < 0 ? 0 : this._sel) + delta) % n + n) % n;
    this.setData({ lastEvent: 'EVT: selected ' + this._entries[this._sel].label + ' ' + this._entries[this._sel].number });
    this._renderAll();
  },

  _stepOrMove(delta, source) {
    if (this.data.busy) return;
    if (this._mode === 'list' || this._mode === 'show') {
      this._moveSel(delta);
      return;
    }
    if (this._mode === 'catch' && source === 'key') {
      // In catch, swipes cycle the label chip (like the LABEL button);
      // the on-screen +1/-1 buttons edit the manual number buffer.
      var labels = this._labels();
      this._labelIdx = ((this._labelIdx + (delta > 0 ? 1 : -1)) % labels.length + labels.length) % labels.length;
      this._pendingLabelSync();
      this.setData({ lastEvent: 'EVT: label -> ' + labels[this._labelIdx] + ' (swipe)' });
      this._renderAll();
      return;
    }
    this._stepNumber(delta);
  },

  plus1Tap() { this._stepOrMove(1, 'btn'); },
  minus1Tap() { this._stepOrMove(-1, 'btn'); },

  _stepNumber(delta) {
    this._disarm();
    var buf = this._mode === 'confirm' && this._pending ? this._pending.text : this._catchText;
    if (buf && !/^\d+$/.test(buf)) {
      this.setData({
        status: '步进只改纯数字号码 — 含字母的用 DICT 更正',
        lastEvent: 'EVT: stepper refused - "' + buf + '" has letters, use DICT'
      });
      this._renderAll();
      return;
    }
    var v = buf ? parseInt(buf, 10) : 0;
    v += delta;
    if (v < 0) v = 0;
    if (v > 999999) v = 999999;
    var next = String(v);
    if (this._mode === 'confirm' && this._pending) {
      if (next !== this._pending.text) this._pending.corrected = true;
      this._pending.text = next;
    } else {
      this._catchText = next;
      if (this._catchSrc !== 'DICT') this._catchSrc = 'MANUAL';
    }
    this.setData({ lastEvent: 'EVT: number stepped -> ' + next + ' (not stored yet)' });
    this._renderAll();
  },

  _pendingLabelSync() {
    // Catch-mode label lives on _labelIdx until a pending exists.
  },

  // ---------- LABEL ----------

  labelTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode === 'show') {
      this._mode = 'list';
      this.setData({ status: '回到列表', lastEvent: 'EVT: show -> list (LABEL)' });
      this._renderAll();
      return;
    }
    var labels = this._labels();
    this._labelIdx = (this._labelIdx + 1) % labels.length;
    if (this._mode === 'confirm' && this._pending) this._pending.label = labels[this._labelIdx];
    this.setData({
      status: '标签：' + labels[this._labelIdx],
      lastEvent: 'EVT: label -> ' + labels[this._labelIdx]
    });
    this._renderAll();
  },

  // ---------- mode entry helpers ----------

  _enterCatch() {
    this._disarm();
    this._mode = 'catch';
    this._catchText = '';
    this._catchSrc = '';
    if (!this._pending || !this._pending.blob) this._pending = null;
    this.setData({
      status: '对准号码 — SNAP 拍照读数，或 DICT / 步进手填',
      lastEvent: 'EVT: catch mode - label ' + this._curLabel()
    });
    this._renderAll();
  },

  _enterConfirmFromCatch() {
    this._pending = {
      blob: null, bytes: 0, wxPhoto: false,
      label: this._curLabel(), text: this._catchText,
      src: this._catchSrc || 'MANUAL', readState: 'none', corrected: false
    };
    this._mode = 'confirm';
    this.setData({
      status: '核对号码 — 对了 OK 存，错了 DICT / 步进改',
      lastEvent: 'EVT: manual entry -> confirm (' + this._pending.src + '), NOT stored yet'
    });
    this._renderAll();
  },

  // ---------- OK (contextual primary, mirrors Enter) ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'list') {
      if (this._sel >= 0 && this._entries.length) {
        this._disarm();
        this._mode = 'show';
        this.setData({
          status: '常驻显示中 — 走路不用再默念它',
          lastEvent: 'EVT: recall display - ' + this._entries[this._sel].label + ' ' + this._entries[this._sel].number
        });
      } else {
        this.setData({ status: '还没有存号码 — 先 SNAP 一个', lastEvent: 'EVT: OK in empty list - nothing to show' });
      }
      this._renderAll();
      return;
    }
    if (this._mode === 'show') {
      this._disarm();
      this._mode = 'list';
      this.setData({ status: '回到列表', lastEvent: 'EVT: show -> list (OK)' });
      this._renderAll();
      return;
    }
    if (this._mode === 'catch') {
      if (this._catchText) {
        this._enterConfirmFromCatch();
      } else {
        this.setData({
          status: '先 SNAP 拍照，或 DICT / 步进填一个号码',
          lastEvent: 'EVT: OK in catch refused - buffer empty'
        });
        this._renderAll();
      }
      return;
    }
    // confirm
    this.saveTap();
  },

  // ---------- SAVE (the ONLY way an entry is ever stored) ----------

  saveTap() {
    if (this.data.busy) return;
    var p = this._pending;
    if (this._mode !== 'confirm' || !p) return;
    var num = String(p.text || '').trim();
    if (!num) {
      this.setData({
        status: '还没读到号码 — DICT 口述或步进填入再存',
        lastEvent: 'EVT: SAVE refused - no number in the confirm buffer'
      });
      this._renderAll();
      return;
    }
    if (this._entries.length >= 6) {
      // Full: honest refusal, pending kept - never a silent overwrite.
      this.setData({
        status: '已存满 6 条 — 先回列表清除一条，这个先留着',
        lastEvent: 'EVT: SAVE refused - store full 6/6, pending kept, nothing overwritten'
      });
      this._renderAll();
      return;
    }
    var entry = { label: p.label, number: num.slice(0, 16), time: this._stamp() };
    this._entries.push(entry);
    this._sel = this._entries.length - 1;
    this._saveEntries();
    this._pending = null;
    this._mode = 'list';
    this.setData({
      capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
      status: 'SAVED ✓ ' + entry.label + ' ' + entry.number + ' — 共 ' + this._entries.length + '/6 条',
      lastEvent: 'EVT: stored ' + entry.label + ' ' + entry.number + ' (' + p.src + ') - TEXT only, photo already gone'
    });
    this._renderAll();
  },

  // ---------- SNAP + READ (telephoto photo -> data: URL -> host LLM image input) ----------

  snapTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: SNAP in DEMO - no camera used (simulated read already on screen)' });
      return;
    }
    if (this._mode === 'confirm' && this._pending && this._pending.blob && !this._pending.text) {
      // A photo is held and the read came back empty: retry the READ
      // on the same photo instead of shooting again.
      this._doRead();
      return;
    }
    if (this._mode !== 'catch') this._enterCatch();
    this.capturePhoto();
  },

  async capturePhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      // No camera on this host: land on the confirm screen empty so
      // the manual path (DICT / stepper) starts right away.
      this._pending = {
        blob: null, bytes: 0, wxPhoto: false,
        label: this._curLabel(), text: '', src: 'MANUAL',
        readState: 'fail', failWhy: '这台设备没有可用相机', corrected: false
      };
      this._mode = 'confirm';
      this.setData({
        capLine: 'CAP: FAIL - mediaDevices n/a on this host',
        status: '拍照不可用 — 直接口述或步进填号码',
        lastEvent: 'EVT: SNAP FAIL (host has no camera) - manual entry offered'
      });
      this._renderAll();
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (telephoto) the number...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
      var bytes = blob && blob.size ? blob.size : 0;
      this._pending = {
        blob: blob, bytes: bytes, wxPhoto: false,
        label: this._curLabel(), text: '', src: 'LLM',
        readState: 'reading', corrected: false
      };
      this._mode = 'confirm';
      this.setData({
        capLine: 'CAP: ' + bytes + 'B telephoto · memory only, NOT saved',
        status: 'PHOTO HELD - reading the number from it...',
        lastEvent: 'EVT: telephoto photo ' + bytes + 'B (memory only, never persisted)'
      });
      this._renderAll();
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context (same as the sibling agents). A
      // wx photo has no Blob to convert, so the image read is honestly
      // n/a for it - the wearer dictates or steps the number instead.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this._pending = {
          blob: null, bytes: size, wxPhoto: true,
          label: this._curLabel(), text: '', src: 'MANUAL',
          readState: 'fail', failWhy: 'wx 回退照片无法转成图片发给模型', corrected: false
        };
        this._mode = 'confirm';
        this.setData({
          capLine: 'CAP: ' + size + 'B wx cam (fallback) · memory only',
          status: '这张照片读不了 — 口述或步进填号码',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - image read n/a)'
        });
        this._renderAll();
      } catch (e3) {
        this._pending = {
          blob: null, bytes: 0, wxPhoto: false,
          label: this._curLabel(), text: '', src: 'MANUAL',
          readState: 'fail', failWhy: '拍照失败：' + this._err(firstErr), corrected: false
        };
        this._mode = 'confirm';
        this.setData({
          capLine: 'CAP: FAIL - ' + this._err(firstErr),
          status: '拍照失败 — 口述或步进填号码照样能存',
          lastEvent: 'EVT: SNAP FAIL - ' + this._err(firstErr)
        });
        this._renderAll();
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
    // Photo held -> read it right away (the CONFIRM screen gates saving).
    if (this._pending && this._pending.blob && this._mode === 'confirm') {
      await this._doRead();
    }
  },

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

  _buildReadContent(dataUrl) {
    // Multimodal content goes in the USER message only (dossier
    // section 2.9): one text part with the instructions, one
    // image_url part carrying the data: URL.
    return [
      {
        type: 'text',
        text: 'This photo shows a short number or code: a hotel room number, a parcel ' +
          'locker number, a food pickup number, or a parking space number. Read ONLY ' +
          'the main number or code itself, exactly as written - digits and capital ' +
          'letters, keeping any hyphen. Do not read any other text in the photo. ' +
          'If the number is not clearly readable, reply with exactly: READ: NONE. ' +
          'Otherwise reply in exactly this format:\n' +
          'READ: <the number or code>'
      },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  _parseNumberRead(text) {
    // Expected: "READ: 1208" / "READ: B2-137" / "READ: NONE".
    // Salvage: a bare clean token on its own line is accepted; any
    // prose around it is not - an unclear reply is a failed read,
    // never a guess.
    var lines = String(text || '').split('\n');
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      var m = ln.match(/^READ[:：]\s*(.+)$/i);
      if (m) {
        var v = m[1].trim().toUpperCase();
        if (!v || v === 'NONE' || v === 'N/A') return null;
        v = v.replace(/\s+/g, '');
        // A number/code always contains a digit; a word does not.
        return /^[A-Z0-9][A-Z0-9-]{0,15}$/.test(v) && /\d/.test(v) ? v : null;
      }
    }
    // Bare-token salvage: starts with a digit, or one letter directly
    // followed by a digit (B2-137) - prose squashed together fails this.
    var whole = String(text || '').trim().toUpperCase().replace(/\s+/g, '');
    if (/^(\d|[A-Z]\d)[A-Z0-9-]{0,14}$/.test(whole) && /\d/.test(whole)) return whole;
    return null;
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
        initialPrompts: [{ role: 'system', content: 'You read short numbers and codes from photos. Reply with only the requested READ line. Never invent digits that are not visible.' }]
      });
      var ans = await this._withTimeout(session.prompt(this._buildReadContent(dataUrl)), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var num = this._parseNumberRead(ans);
      if (!num) return { ok: false, reason: 'unreadable' };
      return { ok: true, number: num };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  async _doRead() {
    var p = this._pending;
    if (!p || !p.blob || this.data.busy) return;
    this.setData({ busy: true, status: 'READING the number (host AI, image in)...' });
    try {
      var dataUrl;
      try {
        dataUrl = await this._withTimeout(this._blobToDataUrl(p.blob), 12000, 'convert');
      } catch (ce) {
        p.readState = 'fail';
        p.failWhy = '照片转图片数据失败：' + this._err(ce);
        this.setData({
          status: '读数不可用 — 口述或步进填号码照样能存',
          lastEvent: 'EVT: READ conversion FAIL - ' + this._err(ce)
        });
        this._renderAll();
        return;
      }
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
        p.readState = 'fail';
        p.failWhy = '照片转换没有得到 data: URL';
        this.setData({
          status: '读数不可用 — 口述或步进填号码照样能存',
          lastEvent: 'EVT: READ conversion FAIL - result was not a data: URL'
        });
        this._renderAll();
        return;
      }
      var r = await this._llmRead(dataUrl);
      if (!r.ok) {
        var why = r.reason === 'no-lm' ? '这台设备没有大模型'
          : r.reason === 'unavailable' ? '大模型现在不可用'
          : r.reason === 'empty' ? '模型没有返回内容'
          : r.reason === 'unreadable' ? '照片里的号码没读清'
          : '模型出错：' + this._err(r.error);
        p.readState = 'fail';
        p.failWhy = why;
        this.setData({
          status: '没读出来（' + why + '）— 口述或步进填',
          lastEvent: 'EVT: READ FAIL (' + r.reason + ') - dictate/stepper path offered'
        });
        this._renderAll();
        return;
      }
      p.text = r.number;
      p.src = 'LLM';
      p.readState = 'ok';
      this.setData({
        status: '读到了 — 核对大字：对了 OK 存，错了先改',
        lastEvent: 'EVT: LLM read ok (image input) - machine read, NOT auto-saved'
      });
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  readTap() {
    // Retry entry point (harness/API symmetry with the siblings):
    // re-runs the read on the held photo when there is one.
    if (this._pending && this._pending.blob && this._mode === 'confirm') this._doRead();
  },

  // ---------- DICT (dictate the number YOU see; check first, then host ASR) ----------

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  _cnDigits() {
    return { '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9 };
  },

  // Chinese integer with 十/百/千 units （一千二 = 1200, 二百五 = 250,
  // 三百零五 = 305); null when not a clean numeral. Same parser family
  // as receipt-keeper / signal-watch.
  _cnInt(str) {
    if (str.indexOf('万') >= 0) return this._cnIntWan(str);
    var dig = this._cnDigits();
    var units = { '十': 10, '百': 100, '千': 1000 };
    var section = 0;
    var pending = -1;
    var lastUnit = 1;
    for (var i = 0; i < str.length; i++) {
      var ch = str.charAt(i);
      if (dig[ch] !== undefined) {
        if (pending >= 0) {
          section += pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
          if (lastUnit > 1) lastUnit = lastUnit / 10;
          pending = -1;
        }
        pending = dig[ch];
        continue;
      }
      if (units[ch] !== undefined) {
        if (pending < 0) pending = 1;
        section += pending * units[ch];
        lastUnit = units[ch];
        pending = -1;
        continue;
      }
      return null;
    }
    if (pending >= 0) {
      section += str.length === 1 ? pending : pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
    }
    return section;
  },

  _cnIntWan(str) {
    var idx = str.indexOf('万');
    var left = str.slice(0, idx);
    var right = str.slice(idx + 1);
    var dig = this._cnDigits();
    var units = { '十': 10, '百': 100, '千': 1000 };
    var parseSide = function (s, allowEmpty) {
      if (s === '') return allowEmpty ? 0 : null;
      var section = 0;
      var pending = -1;
      var lastUnit = 1;
      for (var i = 0; i < s.length; i++) {
        var ch = s.charAt(i);
        if (dig[ch] !== undefined) {
          if (pending >= 0) {
            section += pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
            if (lastUnit > 1) lastUnit = lastUnit / 10;
            pending = -1;
          }
          pending = dig[ch];
          continue;
        }
        if (units[ch] !== undefined) {
          if (pending < 0) pending = 1;
          section += pending * units[ch];
          lastUnit = units[ch];
          pending = -1;
          continue;
        }
        return null;
      }
      if (pending >= 0) {
        section += s.length === 1 ? pending : pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
      }
      return section;
    };
    var l = parseSide(left, false);
    if (l === null) return null;
    var r = parseSide(right, true);
    if (r === null) return null;
    return (l <= 0 ? 1 : l) * 10000 + r;
  },

  // Parse what the wearer dictated into a number/code STRING (leading
  // zeros survive digit-by-digit dictation: 零五零八 -> "0508").
  // Returns null when nothing number-like is heard - never guessed.
  _parseSpokenNumber(raw) {
    if (!raw) return null;
    var s = String(raw).replace(/\s+/g, '');
    s = s.replace(/^(现在|当前|是|号是|号码|编号)+/g, '');
    s = s.replace(/(号|啦|了)$/g, '');
    if (!s) return null;
    // Already a clean code: B2-137, 1208, A05...
    if (/^[A-Za-z0-9][A-Za-z0-9-]*$/.test(s) && /\d/.test(s)) {
      return s.toUpperCase().slice(0, 16);
    }
    // Pure Chinese digit characters, 2+: read digit by digit, the
    // way people actually dictate room/locker numbers （六六三一）.
    if (/^[零一二两三四五六七八九]+$/.test(s) && s.length >= 2) {
      var dig = this._cnDigits();
      var out = '';
      for (var i = 0; i < s.length; i++) out += String(dig[s.charAt(i)]);
      return out.slice(0, 16);
    }
    // A Chinese numeral with units: 一千二百零八 -> "1208".
    var v = this._cnInt(s);
    if (v !== null && v !== undefined && !isNaN(v) && v >= 0 && v <= 999999) {
      return String(v);
    }
    // Mixed speech with an Arabic run inside: keep the run.
    var m = s.match(/[0-9]{2,}/);
    if (m) return m[0].slice(0, 16);
    return null;
  },

  _applyDictatedNumber(txt) {
    var v = this._parseSpokenNumber(txt);
    if (v === null) {
      this.setData({
        status: '没听清成号码：「' + String(txt || '(empty)').slice(0, 12) + '」— 没猜，原值不变',
        lastEvent: 'EVT: DICT parse FAIL - rejected, buffer unchanged'
      });
      this._renderAll();
      return false;
    }
    if (this._mode === 'confirm' && this._pending) {
      if (this._pending.text && v !== this._pending.text) this._pending.corrected = true;
      this._pending.text = v;
      if (this._pending.readState !== 'ok') this._pending.src = 'DICT';
    } else {
      this._catchText = v;
      this._catchSrc = 'DICT';
      if (this._mode === 'list' || this._mode === 'show') this._mode = 'catch';
    }
    this.setData({
      status: '口述填入 ' + v + ' — 核对大字，对了 OK 存',
      lastEvent: 'EVT: DICT "' + String(txt).slice(0, 16) + '" -> ' + v + ' (verbatim from wearer)'
    });
    this._renderAll();
    return true;
  },

  dictTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: DICT in DEMO - no microphone used' });
      return;
    }
    if (this._mode === 'list' || this._mode === 'show') this._enterCatch();
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'DICT SKIP - 这台设备没有识别，改用步进手填',
        lastEvent: 'EVT: DICT SKIP (host ASR n/a) - stepper path offered, nothing faked'
      });
      this._renderAll();
      return;
    }
    this._dictListen();
  },

  async _dictListen() {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (documented pattern from the
    // sibling agents): open the wearer-mode stream, read back its
    // settings, stop every track at once. The check stream is NOT the
    // recognition input and does not shape what recognition hears -
    // the host SpeechRecognition below listens on its own microphone.
    // The result lives on its own MIC CHECK line; the listening line
    // says (host ASR).
    var micNote = 'MIC CHECK: not run';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic check');
        var settings = {};
        try {
          var tr = ms.getAudioTracks()[0];
          if (tr && tr.getSettings) settings = tr.getSettings();
        } catch (e) {}
        micNote = 'MIC CHECK: wearer OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        if (e && e.name === 'OverconstrainedError') {
          try {
            var ms2 = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 6000, 'mic check fallback');
            micNote = 'MIC CHECK: wearer mode rejected - default mic OK (labelled fallback)';
            ms2.getTracks().forEach(function (t) { t.stop(); });
          } catch (e2) {
            micNote = 'MIC CHECK: FAIL - ' + this._err(e2);
          }
        } else {
          micNote = 'MIC CHECK: FAIL - ' + this._err(e);
        }
      }
    }
    this.setData({ micLine: micNote });
    try {
      this._stopDictRec();
      var rec = new SpeechRecognition();
      this._dictRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          self._applyDictatedNumber(txt);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'DICT FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + '，再点 DICT 或步进',
          lastEvent: 'EVT: DICT ASR error'
        });
        self._renderAll();
      };
      rec.onend = function () {
        if (self._dictRec === rec) self._dictRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'DICT listening (host ASR)... 说出你看到的号码',
        lastEvent: 'EVT: DICT listening (host ASR), ' + micNote
      });
      this._renderAll();
    } catch (e) {
      this.setData({
        busy: false,
        status: 'DICT FAIL - recogniser would not start',
        lastEvent: 'EVT: DICT start failed - ' + this._err(e)
      });
      this._renderAll();
    }
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
    var text = null;
    if (this._mode === 'confirm' && this._pending && this._pending.text) {
      text = this._pending.label + '号码，' + this._pending.text + '。还没存，核对后按 OK。';
    } else if (this._sel >= 0 && this._entries.length) {
      var e = this._entries[this._sel];
      text = e.label + '号码，' + e.number + '。';
    }
    if (!text) {
      this.setData({ lastEvent: 'EVT: SPEAK - nothing to read yet' });
      return;
    }
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: SPEAK read a number aloud (TTS, no lang set)' });
    }
  },

  // ---------- DEL (contextual, two-step where anything stored dies) ----------

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'confirm') {
      // Discarding an UNSTORED pending is not destructive to saved
      // data: single tap, said out loud in the EVT line.
      this._pending = null;
      this._mode = 'list';
      this.setData({
        capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
        status: '已放弃这次读数（本来就没存）',
        lastEvent: 'EVT: pending discarded - it was never stored'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'catch') {
      this._catchText = '';
      this._catchSrc = '';
      this.setData({ status: '手填已清空', lastEvent: 'EVT: catch buffer cleared' });
      this._renderAll();
      return;
    }
    // list / show: two-step delete of the selected entry.
    var idx = this._sel;
    if (idx < 0 || idx >= this._entries.length) {
      this.setData({ lastEvent: 'EVT: DEL - nothing selected' });
      return;
    }
    if (this._clearArmIdx === idx) {
      this._clearEntry(idx, 'DEL x2');
    } else {
      this._armClear(idx);
      this.setData({
        status: '⚠ 再点一次 DEL 清除 ' + this._entries[idx].label + ' ' + this._entries[idx].number + '（其他动作取消）',
        lastEvent: 'EVT: DEL 1/2 - clear ARMED for ' + this._entries[idx].label + ' (nothing deleted yet)'
      });
      this._renderAll();
    }
  },

  // ---------- DEMO (seeded entries + one simulated read, memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealEntries = this._entries;
      this._demoRealSel = this._sel;
      this._demoRealPending = this._pending;
      this._demoRealMode = this._mode;
      this._demo = true;
      this._disarm();
    } else {
      this._demo = false;
      this._entries = this._demoRealEntries || [];
      this._sel = this._demoRealSel;
      this._pending = this._demoRealPending || null;
      this._mode = this._demoRealMode || 'list';
      this._demoRealEntries = null;
      this._demoRealPending = null;
      this._disarm();
      this.setData({
        capLine: 'CAP: none - SNAP takes a telephoto photo (memory only)',
        status: 'DEMO OFF - your real numbers are back (' + this._entries.length + ')',
        lastEvent: 'EVT: DEMO cleared - real store restored exactly, nothing was written'
      });
      this._renderAll();
      return;
    }
    // Seed times derive from ONE Date snapshot as pure arithmetic
    // (DI25 lesson: preview host clocks drift between reads).
    var snap = new Date();
    var fmt = function (d) { return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes()); }.bind(this);
    var t1 = new Date(snap.getTime() - 25 * 60000);
    var t2 = new Date(snap.getTime() - 5 * 60000);
    this._entries = [
      { label: '房号', number: '1208', time: fmt(t1) },
      { label: '车位', number: 'B2-137', time: fmt(t2) }
    ];
    this._sel = 0;
    // One catch is mid-flight: a simulated read waiting on the
    // wearer's confirm, exactly like a real READ would land.
    this._pending = {
      blob: null, bytes: 0, wxPhoto: false, demo: true,
      label: '快递柜', text: '6631', src: 'DEMO', readState: 'ok', corrected: false
    };
    this._labelIdx = 1; // 快递柜
    this._mode = 'confirm';
    this.setData({
      capLine: 'CAP: DEMO - no camera used; simulated read (not a real photo)',
      status: 'DEMO - 模拟读到柜号 6631：核对后 OK 存（演示内）',
      lastEvent: 'EVT: DEMO on - 2 seeded entries + 1 simulated read pending (memory only)'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, e;
    if (this._mode === 'show' && this._sel >= 0 && this._entries[this._sel]) {
      e = this._entries[this._sel];
      rows.push({
        name: '展示中',
        detail: e.label + ' ' + e.number + ' · ' + e.time + ' 存入',
        flag: 'RECALL',
        cls: 'row'
      });
    } else {
      for (i = 0; i !== this._entries.length; i++) {
        e = this._entries[i];
        rows.push({
          name: (i === this._sel ? '▸ ' : '') + e.label,
          detail: e.number + ' · ' + e.time,
          flag: i === this._sel ? 'SEL' : '',
          cls: 'row'
        });
      }
      if (!rows.length) {
        rows.push({
          name: '(no numbers)',
          detail: 'SNAP a number, confirm it, it stays here - or DEMO',
          flag: '',
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    patch.countLine = 'SAVED: ' + this._entries.length + '/6 · text saved on device · photos NOT saved';

    if (this._mode === 'list') {
      patch.boxLabel = '◎ 已存号码 — 滑动选择，OK 放大常驻显示';
      if (this._sel >= 0 && this._entries[this._sel]) {
        e = this._entries[this._sel];
        patch.bigLabel = e.label + ' · ' + e.time + ' 存入';
        patch.bigNumber = e.number;
        patch.bigNote = this._clearArmIdx === this._sel
          ? '⚠ 清除已武装 — 再点 DEL 真的清除'
          : 'OK 放大 · SPEAK 朗读 · 点头朗读 · DEL 两下清除';
      } else {
        patch.bigLabel = '（还没有存号码）';
        patch.bigNumber = '----';
        patch.bigNote = 'SNAP 拍号码 / DICT 口述 / 步进手填 / DEMO 演示';
      }
    } else if (this._mode === 'catch') {
      patch.boxLabel = '◎ 正在记 — 标签：' + this._curLabel() + '（LABEL / 滑动切换）';
      patch.bigLabel = this._curLabel();
      patch.bigNumber = this._catchText || '----';
      patch.bigNote = this._catchText
        ? '手填中（' + (this._catchSrc || 'MANUAL') + '）— OK 进入核对，还没存'
        : 'SNAP 拍照读数 · DICT 口述 · +1/−1 步进手填';
    } else if (this._mode === 'confirm') {
      var p = this._pending;
      if (p) {
        patch.boxLabel = p.readState === 'ok' && p.src === 'LLM'
          ? '◎ LLM READ - may misread, verify against the number itself'
          : p.src === 'DEMO'
            ? '◎ DEMO READ (simulated) - not a real photo read'
            : p.readState === 'fail'
              ? '◎ READ FAILED - fill it in yourself below'
              : '◎ YOUR NUMBER - dictated / stepped in by you';
        patch.bigLabel = p.label + (p.corrected ? ' · 已更正' : '');
        patch.bigNumber = p.text || '----';
        patch.bigNote = p.text
          ? 'Enter/OK = 确认存入 · DICT/步进 = 更正 · DEL = 放弃'
          : '没读到：' + (p.failWhy || '读数失败') + ' — DICT 或步进填入';
      }
    } else if (this._mode === 'show') {
      if (this._sel >= 0 && this._entries[this._sel]) {
        e = this._entries[this._sel];
        patch.boxLabel = '◎ RECALL - keep it in view while you walk';
        patch.bigLabel = e.label + ' · ' + e.time + ' 存入';
        patch.bigNumber = e.number;
        patch.bigNote = this._clearArmIdx === this._sel
          ? '⚠ 再点头一次（或再点 DEL）清除这条'
          : '点头两下 / DEL 两下清除 · OK 或 LABEL 回列表';
      }
    }
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">NUMBER CATCH</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="bignum">{{bigNumber}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{capLine}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="labelTap">LABEL</button>
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn" bindtap="dictTap">DICT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">照片不保存 · 存的是你确认过的号码 · 读数先核对再存</text>
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
  height: 63px;
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
