<script def>
{
  "navigationBarTitleText": "Route Replay"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '路线预告 — 通勤路上看向登记危险点（方位+画面），次日出门前按顺序预告',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 登记 — DESC 选描述、DIR 标方位，SNAP 拍一张，MARK 登记一处',
    bigLabel: '路线登记 · 待机',
    bigText: '还没登记',
    bigNote: '描述 施工围挡 · 方位 前方 · SNAP 拍一张 · MARK 登记一处',
    permLine: 'PERM: CAMERA — 只拍当时画面（会话内）；危险点是你登记的，不是检测出来的；不录音、不定位',
    rows: [],
    countLine: '已登记 0 处 · 预告确认 0/0 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - register a hazard spot per look, then PREVIEW before the next outing',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'register'; // register | preview | summary
    this._descList = ['施工围挡', '路面大坑', '积水路段', '脚手架', '井盖缺失'];
    this._descIdx = 0;
    this._dirList = ['前方', '左前方', '右前方', '左方', '右方', '后方'];
    this._dirIdx = 0;
    this._items = []; // { desc, dir, time, photo: 'shot'|'demo'|'none', bytes, dataUrl, demo, known } — session memory only
    this._photoPending = false;
    this._photoBytes = 0;
    this._photoDataUrl = null;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1-3 registered, 4 preview, 5 one confirmed, 6 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the spots and their
    // photos die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up —
    // that IS the design. Close the agent and the route
    // round is gone. A "next day" preview therefore happens
    // in the same session it was registered in; cross-day
    // keeping is a decision for GO, not something this agent
    // smuggles in through storage.
    this._mode = 'register';
    this._descIdx = 0;
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

  _blobToDataUrl(blob) {
    var self = this;
    return new Promise(function (resolve, reject) {
      if (typeof FileReader === 'undefined') {
        reject(new Error('FileReader n/a on this host'));
        return;
      }
      var fr = new FileReader();
      fr.onload = function () { resolve(fr.result); };
      fr.onerror = function () { reject(new Error('FileReader read failed')); };
      try { fr.readAsDataURL(blob); } catch (e) { reject(e); }
    });
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

  _desc() { return this._descList[this._descIdx]; },
  _dir() { return this._dirList[this._dirIdx]; },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (_, reject) {
        setTimeout(function () { reject(new Error('timeout: ' + label)); }, ms);
      })
    ]);
  },

  _knownCount() {
    var n = 0, i;
    for (i = 0; i < this._items.length; i++) {
      if (this._items[i].known) n++;
    }
    return n;
  },

  _photoLabel(photo) {
    if (photo === 'shot') return '已拍（会话内）';
    if (photo === 'demo') return 'DEMO 示例占位';
    return '未拍';
  },

  _addItem(photo, demo) {
    this._items.push({
      desc: this._desc(),
      dir: this._dir(),
      time: this._timeLabel(),
      photo: photo,
      bytes: photo === 'shot' ? this._photoBytes : 0,
      dataUrl: photo === 'shot' ? this._photoDataUrl : null,
      demo: !!demo,
      known: false
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
    // current selection as a spot (register), confirms the
    // previewed spot as known (preview), or confirms the
    // summary. It never changes DESC or DIR: those are
    // selections, and a nod must not silently pick one.
    if (this._mode === 'register') { this.markTap(); return; }
    if (this._mode === 'preview') { this.gotTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'register') this.markTap();
      else if (this._mode === 'preview') this.gotTap();
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

  descTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: DESC refused - the description is picked while registering, not in preview or summary' });
      return;
    }
    this._descIdx = (this._descIdx + 1) % this._descList.length;
    this.setData({
      status: '描述已选为 ' + this._desc() + ' — DIR 标方位，MARK 登记一处',
      lastEvent: 'EVT: description set - ' + this._desc()
    });
    this._renderAll();
  },

  dirTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: DIR refused - direction is marked while registering, not in preview or summary' });
      return;
    }
    this._dirIdx = (this._dirIdx + 1) % this._dirList.length;
    this.setData({
      status: '方位已标为 ' + this._dir() + ' — 帮你想起那处在哪个方向，不是带路',
      lastEvent: 'EVT: direction set - ' + this._dir()
    });
    this._renderAll();
  },

  // ---------- photo (session memory only, never persisted) ----------

  async snapTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: SNAP refused - the photo is taken while registering, not in preview or summary' });
      return;
    }
    if (this.data.busy) return;
    if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        status: '这台设备没有可用相机 — 先 MARK 登记一处（画面记为未拍），预告照样列出它',
        lastEvent: 'EVT: SNAP FAIL (mediaDevices n/a on this host) - register without a photo'
      });
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (wide) ' + this._desc() + '...' });
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
      // only, on the spot it gets MARKed onto. It is never
      // written to storage, and it dies with the page
      // (onUnload / summary confirm). The fleet UI is text
      // only, so the preview shows a shot as "已拍（会话内）"
      // plus its byte size rather than rendering a gallery;
      // the data itself is retained in-session, not just a
      // flag. A DEMO spot carries no real photo: its label
      // says DEMO 示例占位, never a fake shot.
      var dataUrl = await this._blobToDataUrl(blob);
      this._photoPending = true;
      this._photoBytes = bytes;
      this._photoDataUrl = dataUrl;
      this.setData({
        status: '画面已拍 ' + bytes + 'B（wide，会话内）— MARK 登记一处就把它钉在这一处上',
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
          status: '画面已拍 ' + size + 'B（wx 回退，会话内）— MARK 登记一处就把它钉在这一处上',
          lastEvent: 'EVT: wx photo ' + size + 'B pending (fallback, memory only)'
        });
        this._renderAll();
      } catch (e2) {
        this.setData({
          status: '拍照失败：' + this._err(firstErr) + ' — 先 MARK 登记一处（画面记为未拍），预告照样列出它',
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

  // ---------- register / preview / summary ----------

  markTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: MARK refused - spots are registered while registering, not in preview or summary' });
      return;
    }
    var photo = this._photoPending ? 'shot' : 'none';
    this._addItem(photo, false);
    this._photoPending = false;
    this._photoBytes = 0;
    this._photoDataUrl = null;
    var it = this._items[this._items.length - 1];
    this.setData({
      status: '已登记：' + it.desc + ' · ' + it.dir + ' · 画面' + this._photoLabel(it.photo) + ' — 继续登记，或 PREVIEW 次日预告',
      lastEvent: 'EVT: spot registered - ' + it.desc + ' (' + it.dir + ', photo ' + it.photo + ')'
    });
    this._renderAll();
  },

  previewTap() {
    if (this._mode === 'preview') {
      this.setData({ lastEvent: 'EVT: PREVIEW refused - the next-outing preview is already open' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: PREVIEW refused - confirm or go back from the summary first' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: PREVIEW refused - missing: 至少登记一处危险点（MARK）' });
      return;
    }
    this._mode = 'preview';
    this._focus = 0;
    this.setData({
      status: '次日预告 — 按登记顺序逐个预告，GOT 确认知道了才走下一处',
      lastEvent: 'EVT: preview started (' + this._items.length + ' spots)'
    });
    this._renderAll();
  },

  gotTap() {
    if (this._mode !== 'preview') {
      this.setData({ lastEvent: 'EVT: GOT refused - spots are confirmed as known in the preview, not while registering or in summary' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: GOT refused - missing: 至少登记一处危险点（MARK）' });
      return;
    }
    var cur = this._items[this._focus];
    if (cur.known) {
      this.setData({ lastEvent: 'EVT: GOT refused - this spot is already confirmed known' });
      return;
    }
    cur.known = true;
    var known = this._knownCount();
    // Advance to the next still-unknown spot, wrapping; if
    // every spot is known, stay put and say so.
    var i, nxt = -1;
    for (i = 1; i <= this._items.length; i++) {
      var j = (this._focus + i) % this._items.length;
      if (!this._items[j].known) { nxt = j; break; }
    }
    if (nxt >= 0) this._focus = nxt;
    this.setData({
      status: known === this._items.length
        ? '全部已确认 — ' + known + '/' + this._items.length + ' 处都知道了，END 出小结'
        : '知道了：' + cur.desc + ' · ' + cur.dir + ' — 已确认 ' + known + '/' + this._items.length + ' 处，继续预告下一处',
      lastEvent: 'EVT: spot confirmed known - ' + cur.desc + ' (' + known + '/' + this._items.length + ')'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to preview without deleting.
      this._confirmSummary();
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: END refused - missing: 至少登记一处危险点（MARK）' });
      return;
    }
    this._mode = 'summary';
    this._summary = {
      total: this._items.length,
      known: this._knownCount()
    };
    this.setData({
      status: '本次路线小结 — 登记与预告确认钉在下面，点 END 确认清空，BACK 返回预告',
      lastEvent: 'EVT: route ended - summary ready (total ' + this._items.length + ', known ' + this._summary.known + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'register';
    this._descIdx = 0;
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
      status: '路线预告 — 通勤路上看向登记危险点（方位+画面），次日出门前按顺序预告',
      lastEvent: 'EVT: summary confirmed - route round cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to preview without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'preview';
      this._summary = null;
      this.setData({
        status: '次日预告 — 按登记顺序逐个预告，GOT 确认知道了才走下一处',
        lastEvent: 'EVT: back to preview - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'preview') {
      this._mode = 'register';
      this.setData({
        status: '路线登记 — 继续登记，或 PREVIEW 次日预告',
        lastEvent: 'EVT: back to registering - spots kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - MARK registers a spot, PREVIEW opens the preview' });
  },

  _focusLen() {
    if (this._mode === 'register') return this._items.length;
    if (this._mode === 'preview') return this._items.length;
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
    this.setData({ lastEvent: 'EVT: focus -> spot ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> spot ' + (this._focus + 1) });
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
    this.setData({ lastEvent: 'EVT: focus -> spot ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'register') {
      line = this._items.length === 0
        ? '还没登记：选描述、标方位，MARK 登记一处'
        : '已登记 ' + this._items.length + ' 处，继续登记或预告';
    } else if (this._mode === 'preview') {
      if (this._items.length === 0) {
        line = '预告里暂无危险点';
      } else {
        var cur = this._items[this._focus] || this._items[0];
        line = cur.desc + '，' + cur.dir + '，画面' + this._photoLabel(cur.photo) + (cur.known ? '，已确认' : '，还没确认');
      }
    } else if (this._summary) {
      line = '本次路线小结：共 ' + this._summary.total + ' 处，预告确认 ' + this._summary.known + ' 处';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user preview is under way' });
      return;
    }
    if (this._mode === 'register' && !this._demo && this._items.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user spots are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._descIdx = 0; // 施工围挡
      this._dirIdx = 0; // 前方
      this._addItem('demo', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - roadworks front registered (DEMO sample, 1 spot)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._descIdx = 1; // 路面大坑
      this._dirIdx = 1; // 左前方
      this._addItem('demo', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - pothole left-front registered (DEMO sample, 2 spots)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._descIdx = 2; // 积水路段
      this._dirIdx = 2; // 右前方
      this._addItem('demo', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - flooding right-front registered (DEMO sample, 3 spots)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.previewTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - preview open, focus on spot 1 (roadworks front)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - spot 1 confirmed known, focus on spot 2 (pothole left-front)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - summary (3 spots, 1 confirmed, DEMO sample)' });
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
    if (list.length === 0) {
      rows.push({
        idx: 0,
        name: this._mode === 'preview' ? '预告里暂无危险点' : (this._mode === 'summary' ? '小结里暂无危险点' : '暂无危险点'),
        detail: this._mode === 'register'
          ? '选描述、标方位，SNAP 拍一张，MARK 登记一处'
          : '先回去登记至少一处危险点',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < list.length; i++) {
        e = list[i];
        rows.push({
          idx: i,
          name: '处' + (i + 1) + ' · ' + e.time + ' · ' + e.dir + (e.known ? ' ✓已确认' : ''),
          detail: e.desc + ' · 画面' + this._photoLabel(e.photo) + (e.demo ? '（DEMO 示例）' : ''),
          flag: this._focus === i ? '▶' : (e.known ? '✓' : '○'),
          cls: 'row'
        });
      }
    }

    var known = this._knownCount();
    var patch = { rows: rows };
    patch.countLine = '已登记 ' + this._items.length + ' 处' +
      ' · 预告确认 ' + known + '/' + this._items.length +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'register') {
      patch.boxLabel = '◎ 登记 — DESC 选描述、DIR 标方位，SNAP 拍一张，MARK 登记一处';
      patch.bigLabel = '路线登记 · 待机';
      patch.bigText = this._items.length === 0 ? '还没登记' : '已登记 ' + this._items.length + ' 处';
      patch.bigNote = '描述 ' + this._desc() + ' · 方位 ' + this._dir() +
        ' · 画面' + (this._photoPending ? '已拍待登记' : '未拍') + ' · MARK 登记一处';
    } else if (this._mode === 'preview') {
      patch.boxLabel = '◎ 次日预告 — GOT 确认知道了才走下一处';
      patch.bigLabel = '次日预告 · 第 ' + (this._focus + 1) + '/' + this._items.length + ' 处';
      var cur = this._items[this._focus] || this._items[0];
      patch.bigText = cur.desc + ' · ' + cur.dir;
      patch.bigNote = cur.time + ' · 画面' + this._photoLabel(cur.photo) +
        (cur.photo === 'shot' && cur.bytes ? ' ' + cur.bytes + 'B' : '') +
        (cur.demo ? '（DEMO 示例）' : '') + (cur.known ? ' · 已确认' : ' · 还没确认，GOT 确认知道了');
    } else {
      patch.boxLabel = '◎ 本次路线小结 — 登记与预告确认钉在下面';
      patch.bigLabel = '本次路线小结';
      var s = this._summary || { total: 0, known: 0 };
      patch.bigText = '已确认 ' + s.known + '/' + s.total + ' 处';
      patch.bigNote = '共 ' + s.total + ' 处 · 预告确认 ' + s.known + ' 处 · 点 END 确认清空 · BACK 返回预告';
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
      <text class="title">ROUTE REPLAY v1.0.0</text>
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
      <button class="btn btn-main" bindtap="descTap">DESC</button>
      <button class="btn btn-main" bindtap="dirTap">DIR</button>
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="previewTap">PREVIEW</button>
      <button class="btn btn-main" bindtap="gotTap">GOT</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
    </view>
    <view class="actions">
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
    <text class="foot2">没有危险识别、没有定位——危险点是你自己看向登记的，不是 Agent 检测出来的；画面是当时拍的照片原图（会话内），不是识别结果；方位只是你登记时的头部方向，不是定位导航——预告的方位帮你想起那处在哪个方向，不是带路；点位只存本次会话，关掉即清；想今天记、明天看需要跨日留存，由 GO 另行决定是否破例；没有室内定位；零落盘</text>
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
