<script def>
{
  "navigationBarTitleText": "Room Sweep"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '睡前巡房 — 逐项看向确认，问题项绝不刷绿，全绿才报安',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 巡房进行中 — 没查的项一眼就能看见',
    bigLabel: '当前项 · 窗户·左',
    bigText: '○ 未查',
    bigNote: 'OK 通过 · FLAG 标记问题 · SNAP 拍照留档 · NEXT 换项',
    capLine: 'CAP: none - SNAP 为当前项拍照留档（仅会话内存，不分析）',
    rows: [],
    countLine: '已查 0/6 · 待处理 0 · 只存本次会话内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - walk the room in entry order, confirm each item',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'sweep'; // sweep | summary
    this._items = this._itemDefs().map(function (d) {
      return { name: d.name, sector: d.sector, state: 'todo', src: null, photo: false, bytes: 0 };
    });
    this._focus = 0;
    this._summaryAllOk = false;
    this._clearArm = false;
    this._clearTimer = null;
    this._nodLock = false;
    this._demoStage = 0; // 0 none, 1: 2 ok, 2: +2 ok +1 flag, 3: last ok -> summary-pending, 4: flag fixed -> summary-all-ok
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the checklist, the flags and the
    // photo markers die with the page. Nothing was ever written to
    // any storage, so there is nothing to clean up - that IS the
    // design. Tomorrow night you sweep again, which is the point.
    this._items = [];
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
    // "this item is fine" - and only in sweep mode on the focused
    // item. It never flags a problem, never finishes the sweep,
    // never clears anything, and is inert on the summary screen.
    if (this._mode === 'sweep') {
      this._confirmItem('NOD');
      return;
    }
    this.setData({ lastEvent: 'EVT: nod ignored - nod only confirms an item in sweep mode' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.okTap();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
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

  // Fixed checklist, in the order you walk the room from the door.
  // The sector labels are that walk order, NOT measured positions:
  // the agent never knows where anything really is in the room.
  _itemDefs() {
    return [
      { name: '窗户', sector: '左' },
      { name: '插座', sector: '右前' },
      { name: '地面小物件', sector: '中央' },
      { name: '床护栏', sector: '右' },
      { name: '门', sector: '后' },
      { name: '夜灯', sector: '左前' }
    ];
  },

  _countOk() {
    var n = 0;
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'ok') n++;
    return n;
  },

  _countFlag() {
    var n = 0;
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'flag') n++;
    return n;
  },

  _countDone() {
    return this._countOk() + this._countFlag();
  },

  _allDecided() {
    return this._countDone() === this._items.length;
  },

  _firstTodo() {
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'todo') return i;
    return -1;
  },

  _firstFlag() {
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'flag') return i;
    return -1;
  },

  _hasReal() {
    for (var i = 0; i < this._items.length; i++) {
      if (this._items[i].src === 'REAL') return true;
    }
    return false;
  },

  _missingText() {
    var parts = [];
    for (var i = 0; i < this._items.length; i++) {
      if (this._items[i].state === 'todo') parts.push(this._items[i].name + '（' + this._items[i].sector + '）');
    }
    return parts.join('、');
  },

  _flagText() {
    var parts = [];
    for (var i = 0; i < this._items.length; i++) {
      if (this._items[i].state === 'flag') parts.push(this._items[i].name + '（' + this._items[i].sector + '）');
    }
    return parts.join('、');
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
        self.setData({ lastEvent: 'EVT: clear disarmed (timeout) - summary kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _clearAll() {
    this._items = this._itemDefs().map(function (d) {
      return { name: d.name, sector: d.sector, state: 'todo', src: null, photo: false, bytes: 0 };
    });
    this._focus = 0;
    this._demoStage = 0;
    this._disarm();
    this._mode = 'sweep';
    this.setData({
      capLine: 'CAP: none - SNAP 为当前项拍照留档（仅会话内存，不分析）',
      status: '已清空 — 重新巡房',
      lastEvent: 'EVT: checklist cleared by two-step DEL - session memory wiped'
    });
    this._renderAll();
  },

  // ---------- confirm / flag / reset: the ONLY ways an item changes state ----------

  _confirmItem(how) {
    var it = this._items[this._focus];
    if (!it) return;
    if (it.state === 'ok') {
      this.setData({ lastEvent: 'EVT: ' + how + ' - item already passed, NEXT moves on' });
      return;
    }
    var wasFlag = it.state === 'flag';
    it.state = 'ok';
    it.src = 'REAL';
    this._disarm();
    var next = this._firstTodo();
    if (next >= 0) this._focus = next;
    this.setData({
      status: (wasFlag ? '已处理并通过：' : '已通过：') + it.name + '（' + it.sector + '）' +
        (next >= 0 ? ' — 下一项：' + this._items[next].name : ' — 全部已查，点 FIN 看小结'),
      lastEvent: 'EVT: item ' + it.name + ' passed by ' + how + (wasFlag ? ' (was flagged, now fixed)' : '')
    });
    this._renderAll();
  },

  _flagItem() {
    var it = this._items[this._focus];
    if (!it) return;
    if (it.state === 'flag') {
      this.setData({ lastEvent: 'EVT: FLAG - item already flagged, fix it then OK' });
      return;
    }
    // A flagged item is NEVER counted as passed: _countOk counts
    // only state 'ok'. Flagging is a refusal to brush it green.
    it.state = 'flag';
    it.src = 'REAL';
    this._disarm();
    var next = this._firstTodo();
    if (next >= 0) this._focus = next;
    this.setData({
      status: '已标记待处理：' + it.name + '（' + it.sector + '）— 处理完回来点 OK 才能通过' +
        (next >= 0 ? ' — 下一项：' + this._items[next].name : ' — 全部已查，点 FIN 看小结'),
      lastEvent: 'EVT: item ' + it.name + ' flagged as pending (never counted as passed)'
    });
    this._renderAll();
  },

  _resetItem() {
    var it = this._items[this._focus];
    if (!it) return;
    it.state = 'todo';
    it.src = null;
    it.photo = false;
    it.bytes = 0;
    this._disarm();
    this.setData({
      status: '已取消：' + it.name + '（' + it.sector + '）回到未查',
      lastEvent: 'EVT: item ' + it.name + ' reset to todo by DEL'
    });
    this._renderAll();
  },

  // ---------- photo archive marker (wide photo, memory only, NEVER analysed) ----------

  snapTap() {
    if (this.data.busy) return;
    this._disarm();
    this.capturePhoto(this._focus);
  },

  async capturePhoto(itemIdx) {
    if (this.data.busy) return;
    if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this._photoFallback(itemIdx, '这台设备没有可用相机');
      return;
    }
    this.setData({ busy: true, status: 'SNAPPING (wide) ' + this._items[itemIdx].name + '...' });
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
      // The blob is deliberately NOT kept: only a marker (bytes) is
      // recorded. The photo is an archive marker for this item in
      // this session, never analysed, never judged by the agent.
      this._items[itemIdx].photo = true;
      this._items[itemIdx].bytes = bytes;
      this.setData({
        capLine: 'CAP: ' + bytes + 'B wide · memory only, NOT saved, NOT analysed',
        status: '已拍照留档：' + this._items[itemIdx].name + ' — 照片不分析、不判断状态，只作本次留档',
        lastEvent: 'EVT: wide photo ' + bytes + 'B for item ' + this._items[itemIdx].name + ' (marker only, blob discarded)'
      });
      this._renderAll();
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
        this._items[itemIdx].photo = true;
        this._items[itemIdx].bytes = size;
        this.setData({
          capLine: 'CAP: ' + size + 'B wx cam (fallback) · memory only, NOT analysed',
          status: '已拍照留档（wx 回退）：' + this._items[itemIdx].name + ' — 照片不分析、不判断状态',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, marker only)'
        });
        this._renderAll();
      } catch (e3) {
        this._photoFallback(itemIdx, '拍照失败：' + this._err(firstErr));
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
      this.setData({ busy: false });
    }
  },

  _photoFallback(itemIdx, why) {
    this.setData({
      capLine: 'CAP: FAIL - ' + why,
      status: '拍照留档不可用（' + why + '）— 不影响查项，OK/FLAG 照常确认',
      lastEvent: 'EVT: SNAP FAIL (' + why + ') - photo marker unavailable, checklist unaffected'
    });
    this._renderAll();
  },

  // ---------- OK / FLAG / DEL / navigation / summary ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      // Back to the sweep to keep fixing; never fake a new summary.
      var back = this._firstFlag();
      this._mode = 'sweep';
      this._focus = back >= 0 ? back : 0;
      this._disarm();
      this.setData({
        status: back >= 0 ? '回到巡房 — 先处理待处理项：' + this._flagText() : '回到巡房',
        lastEvent: 'EVT: summary -> sweep (keep fixing)'
      });
      this._renderAll();
      return;
    }
    this._confirmItem('OK');
  },

  flagTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: FLAG in summary - go back to sweep (OK) to change items' });
      return;
    }
    this._flagItem();
  },

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      if (this._clearArm) { this._clearAll(); return; }
      this._armClear();
      this.setData({
        status: '⚠ 再点一次 DEL 清空清单重新巡房（其他动作取消）',
        lastEvent: 'EVT: clear 1/2 - ARMED (summary still kept)'
      });
      this._renderAll();
      return;
    }
    this._resetItem();
  },

  nextTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode === 'sweep') {
      this._focus = (this._focus + 1) % this._items.length;
      this.setData({ lastEvent: 'EVT: focus -> ' + this._items[this._focus].name });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: NEXT in summary - OK returns to sweep' });
  },

  prevTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode === 'sweep') {
      this._focus = (this._focus + this._items.length - 1) % this._items.length;
      this.setData({ lastEvent: 'EVT: focus -> ' + this._items[this._focus].name });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: PREV in summary - OK returns to sweep' });
  },

  finTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: FIN in summary - OK returns to sweep, DEL twice clears' });
      return;
    }
    this._disarm();
    var todo = this._firstTodo();
    if (todo >= 0) {
      // Missed items are NAMED, with their walk-order sector, before
      // any summary is allowed. A summary with a hole in it would be
      // the exact false reassurance this agent exists to prevent.
      var n = this._items.length - this._countDone();
      this.setData({
        status: '还差 ' + n + ' 项没查：' + this._missingText() + ' — 按顺序补看，补完再点 FIN',
        lastEvent: 'EVT: FIN refused - ' + n + ' items still todo: ' + this._missingText()
      });
      this._renderAll();
      return;
    }
    this._mode = 'summary';
    this._summaryAllOk = this._countFlag() === 0;
    if (this._summaryAllOk) {
      this._speakText('全部通过，可以安心睡了');
      this.setData({
        status: '全部通过 ✓ 可以安心睡了',
        lastEvent: 'EVT: summary all-green 6/6 passed'
      });
    } else {
      this._speakText('还有待处理项：' + this._flagText() + '，请先处理');
      this.setData({
        status: '有待处理项：' + this._flagText() + ' — 处理完回来点 OK 回巡房改成通过',
        lastEvent: 'EVT: summary pending - flags: ' + this._flagText() + ' (never reported all-green)'
      });
    }
    this._renderAll();
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
      var t = this._summaryAllOk
        ? '全部通过，可以安心睡了。'
        : '还有待处理项：' + this._flagText() + '，请先处理。';
      if (this._speakText(t)) this.setData({ lastEvent: 'EVT: SPEAK summary (TTS, no lang set)' });
      return;
    }
    var it = this._items[this._focus];
    var line = it.state === 'ok' ? '当前项' + it.name + '已通过。'
      : it.state === 'flag' ? '当前项' + it.name + '待处理，发现问题。'
      : '当前项' + it.name + '还没查。已查 ' + this._countDone() + ' 项，还差 ' + (this._items.length - this._countDone()) + ' 项。';
    if (this._speakText(line)) this.setData({ lastEvent: 'EVT: SPEAK focus item (TTS, no lang set)' });
  },

  // ---------- DEMO (staged; never overwrites real decisions) ----------

  demoTap() {
    if (this.data.busy) return;
    if (this._hasReal()) {
      this.setData({ lastEvent: 'EVT: DEMO - real decisions exist, DEMO never overwrites them' });
      return;
    }
    var self = this;
    function setState(idx, state) {
      self._items[idx].state = state;
      self._items[idx].src = 'DEMO';
    }
    if (this._demoStage === 0) {
      setState(0, 'ok'); setState(1, 'ok');
      this._focus = 2;
      this._demoStage = 1;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated checks (not real judgements)',
        status: 'DEMO - 已模拟通过 2 项：窗户、插座 — 再点 DEMO 继续',
        lastEvent: 'EVT: DEMO stage 1 - 2 items simulated ok'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      setState(2, 'ok'); setState(3, 'ok'); setState(4, 'flag');
      this._focus = 5;
      this._demoStage = 2;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated checks (not real judgements)',
        status: 'DEMO - 已模拟：4 项通过、门标记待处理 — 再点 DEMO 查完夜灯',
        lastEvent: 'EVT: DEMO stage 2 - 4 ok + 1 flagged (simulated)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      setState(5, 'ok');
      this._mode = 'summary';
      this._summaryAllOk = false;
      this._demoStage = 3;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated checks (not real judgements)',
        status: 'DEMO - 小结：有待处理项：门 — 处理完回来点 OK 回巡房改成通过',
        lastEvent: 'EVT: DEMO stage 3 - summary pending (simulated flag)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      setState(4, 'ok');
      this._mode = 'summary';
      this._summaryAllOk = true;
      this._demoStage = 4;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated checks (not real judgements)',
        status: 'DEMO - 小结：全部通过 ✓ 可以安心睡了',
        lastEvent: 'EVT: DEMO stage 4 - summary all-green (simulated)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._items.length; i++) {
      var it = this._items[i];
      rows.push({
        name: it.name + '·' + it.sector,
        detail: it.state === 'ok'
          ? '✓ 通过' + (it.photo ? ' · 已拍照留档' : '')
          : it.state === 'flag' ? '⚠ 待处理：发现问题' : '○ 未查',
        flag: it.state === 'ok' ? '✓' : (it.state === 'flag' ? '⚠' : ''),
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已查 ' + this._countDone() + '/6 · 待处理 ' + this._countFlag() +
      ' · 只存本次会话内存 · 关掉即清 · 零落盘';

    if (this._mode === 'sweep') {
      var f = this._items[this._focus];
      patch.boxLabel = '◎ 巡房进行中 — 没查的项一眼就能看见';
      patch.bigLabel = '当前项 · ' + f.name + '·' + f.sector;
      patch.bigText = f.state === 'ok' ? '✓ 通过' : (f.state === 'flag' ? '⚠ 待处理' : '○ 未查');
      patch.bigNote = f.state === 'ok'
        ? '已通过' + (f.photo ? ' · 已拍照留档' : '') + ' · NEXT 换项 · DEL 取消 · SNAP 补拍留档'
        : f.state === 'flag'
          ? '发现问题，绝不刷绿 · 处理完点 OK 改成通过 · NEXT 换项'
          : 'OK 通过 · FLAG 标记问题 · SNAP 拍照留档 · NEXT 换项 · 头稳点头也可确认';
    } else {
      patch.boxLabel = '◎ 巡查小结';
      patch.bigLabel = '今晚巡查小结';
      if (this._summaryAllOk) {
        patch.bigText = '可以安心睡了';
        patch.bigNote = '全部 6 项通过 · OK 回巡房 · DEL 两下清空重查';
      } else {
        patch.bigText = '有待处理项';
        patch.bigNote = '待处理：' + this._flagText() + ' · OK 回巡房处理 · DEL 两下清空重查';
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
      <text class="title">ROOM SWEEP v1.0.0</text>
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
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
      <button class="btn" bindtap="flagTap">FLAG ⚠</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="prevTap">PREV</button>
      <button class="btn" bindtap="finTap">FIN</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="delTap">DEL</button>
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
    <text class="foot2">窗关没关、插座盖没盖由你看向确认，Agent 不检测物理状态、不联网家居 · 方位是进门起的巡查顺序，不是实测位置 · 只记今晚，关掉即清</text>
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
  height: 45px;
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
