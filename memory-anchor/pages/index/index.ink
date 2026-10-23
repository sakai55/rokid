<script def>
{
  "navigationBarTitleText": "Memory Anchor"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'NOTE: face a thing, tap NOTE, say the memo',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    catLine: 'CAT: 钥匙 · tap CAT to switch',
    memoLine: 'MEMO: (none yet) - tap NOTE and say it',
    micLine: 'MIC CHECK: not run',
    countLine: 'ANCHORS: 0/10 · saved on this device only',
    rows: [
      { text: '(no anchors) - NOTE one here, or DEMO' }
    ],
    anchorLine: 'ANCHOR: face a noted direction 2 s - memo pops here',
    anchorCls: 'anchor',
    arrow: '·',
    guideLine: 'GUIDE: SEL picks an anchor below',
    guideCls: 'rel',
    lastEvent: 'EVT: anchors bind a direction, not the thing itself',
    busy: false
  },

  onLoad() {
    this._catIdx = 0;
    this._selIdx = 0;
    this._presetIdx = 0;
    this._pendingMemo = null;
    this._pendingTag = '';
    this._anchors = this._loadAnchors();
    this._idSeq = 0;
    for (var i = 0; i !== this._anchors.length; i++) {
      if (this._anchors[i].id > this._idSeq) this._idSeq = this._anchors[i].id;
    }
    this._face = {};       // per-anchor remind state, keyed by anchor id
    this._doneArm = false;
    this._rec = null;
    this._micNote = 'MIC CHECK: not run';
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
    this._sensor = null;
    this._timer = null;
    this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopHeading();
    this._stopRec();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._stopRec();
    this._saveAnchors();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (this._pendingMemo) {
      // A nod only ever CONFIRMS a memo that is already dictated and
      // on screen verbatim. With nothing pending it can never create
      // or save a memo out of thin air.
      if (this._steady) this.saveTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to SAVE' });
    } else {
      this.speakTap();
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this._cycleSel();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._pendingMemo) this.saveTap(); else this.speakTap();
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
    return String(e.message || e.name || e).slice(0, 60);
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

  // ONE clock snapshot -> {date, time} as pure strings. A batch of
  // related values (DEMO seeds, a record's date + time) always comes
  // from a single snapshot: the preview host's Date is virtualised
  // and drifts between calls (lesson from #25), so sampling Date
  // repeatedly for related values can split them.
  _stamp() {
    var d = new Date();
    return {
      date: d.getFullYear() + '-' + this._pad2(d.getMonth() + 1) + '-' + this._pad2(d.getDate()),
      time: this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes())
    };
  },

  // ---------- vocab ----------

  _cats() { return ['钥匙', '文件', '药', '工具', '食材', '其他']; },
  _cat() { return this._cats()[this._catIdx || 0]; },
  _presetMemos() {
    return ['记得把发票拍照存档', '出门前给花浇水', '周五前交水电费', '把伞放回玄关', '睡前吃一片药'];
  },

  // ---------- persistence (wx sync storage, key 'memoryAnchors', max 10) ----------

  _loadAnchors() {
    try {
      var raw = wx.getStorageSync('memoryAnchors');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 10; i++) {
        var r = raw[i];
        if (r && typeof r.cat === 'string' && typeof r.memo === 'string' &&
            isFinite(r.heading) && typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            id: isFinite(r.id) ? r.id : out.length + 1,
            cat: String(r.cat).slice(0, 4),
            memo: String(r.memo).slice(0, 40),
            heading: ((Math.round(r.heading) % 360) + 360) % 360,
            date: String(r.date).slice(0, 10),
            time: String(r.time).slice(0, 5),
            demo: !!r.demo
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveAnchors() {
    try {
      wx.setStorageSync('memoryAnchors', this._anchors || []);
    } catch (e) { /* storage unavailable on this host: anchors stay in memory */ }
  },

  // Beyond 10 anchors the OLDEST is dropped; the caller hears about
  // it (EVT note) - an anchor is never dropped silently.
  _addAnchor(rec) {
    var arr = this._anchors || [];
    arr.push(rec);
    var dropped = null;
    while (arr.length > 10) dropped = arr.shift();
    this._anchors = arr;
    this._saveAnchors();
    return dropped;
  },

  // ---------- heading (AbsoluteOrientationSensor, same as home-find) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._recompute();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onHeading(s); });
      s.addEventListener('error', function (ev) {
        self._headingSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - heading NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._headingSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopHeading() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  _yawDeg(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    var deg = yaw * 180 / Math.PI;
    return (deg + 360) % 360;
  },

  _onHeading(sensor) {
    if (this._demo) return; // demo heading wins while simulating
    var deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    var changed = this._heading === null || Math.abs(deg - this._heading) >= 1;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (changed) this._recompute();
  },

  // The remind engine ticks on accumulated tick time (500 ms per
  // tick), NOT on repeated Date samples, so dwell / re-arm timing
  // cannot be distorted by the preview host's drifting clock.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      }
      self._remindTick();
    }, 500);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- selection / category ----------

  _cycleSel() {
    var n = (this._anchors || []).length;
    if (!n) {
      this.setData({ lastEvent: 'EVT: no anchors yet - NOTE first or DEMO' });
      return;
    }
    this._doneArm = false;
    this._selIdx = ((this._selIdx || 0) + 1) % n;
    this.setData({ lastEvent: 'EVT: selected -> ' + this._anchors[this._selIdx].cat });
    this._recompute();
  },

  selTap() { this._cycleSel(); },

  catTap() {
    this._doneArm = false;
    this._catIdx = ((this._catIdx || 0) + 1) % this._cats().length;
    this.setData({ lastEvent: 'EVT: category -> ' + this._cat() });
    this._recompute();
  },

  // ---------- NOTE: mic-mode CHECK, then host ASR dictation ----------

  _stopRec() {
    if (this._rec) {
      try { this._rec.abort(); } catch (e) {}
      this._rec = null;
    }
  },

  // Wearer-mode microphone AVAILABILITY CHECK ONLY (post-audit
  // wording rule): this getUserMedia stream verifies the documented
  // 'wearer' mode opens and reads its settings back, then stops at
  // once. It is NOT the recognition input and shapes nothing the
  // recogniser hears - dictation below runs on the host
  // SpeechRecognition, which listens on its own microphone.
  async _micCheck() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      return 'MIC CHECK: n/a on this host';
    }
    try {
      var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
        audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
      }), 6000, 'mic');
      var mode = '';
      try {
        var tr = ms.getAudioTracks()[0];
        if (tr && tr.getSettings) mode = tr.getSettings().microphoneMode || '';
      } catch (e) {}
      ms.getTracks().forEach(function (t) { t.stop(); });
      return 'MIC CHECK: wearer OK' + (mode ? ' (' + mode + ')' : '');
    } catch (e) {
      return 'MIC CHECK: wearer FAIL - ' + this._err(e);
    }
  },

  noteTap() {
    if (this.data.busy) return;
    this._doneArm = false;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest SKIP: no recogniser on this host. NOTE falls back to
      // cycling built-in preset memos instead of pretending to listen.
      var memos = this._presetMemos();
      this._pendingMemo = memos[this._presetIdx % memos.length];
      this._presetIdx++;
      this._pendingTag = 'preset';
      this._micNote = 'MIC CHECK: not run (ASR SKIP)';
      this.setData({
        status: 'NOTE preset - ASR SKIP on this host, then SAVE',
        lastEvent: 'EVT: NOTE preset memo (honest SKIP, no ASR on this host)'
      });
      this._recompute();
      return;
    }
    this._listenMemo();
  },

  async _listenMemo() {
    var self = this;
    this.setData({ busy: true, status: 'NOTE: wearer mic check first...' });
    this._micNote = await this._micCheck();
    this.setData({ micLine: this._micNote });
    try {
      this._stopRec();
      var rec = new SpeechRecognition();
      this._rec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          // Kept VERBATIM, exactly as the host recogniser heard it,
          // and shown on screen so the wearer eyeballs it BEFORE
          // SAVE. The glasses never quietly "correct" a mishearing.
          self._pendingMemo = txt.slice(0, 40);
          self._pendingTag = 'heard';
          self.setData({
            status: 'MEMO heard - eyeball it, then SAVE',
            lastEvent: 'EVT: memo heard (host ASR) - verify before SAVE'
          });
          self._recompute();
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'NOTE FAIL - tap NOTE again',
          lastEvent: 'EVT: ASR error - ' + self._err(ev.error || ev)
        });
      };
      rec.onend = function () {
        if (self._rec === rec) self._rec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'NOTE listening (host ASR) - say the memo',
        lastEvent: 'EVT: NOTE listening on host ASR; ' + this._micNote
      });
    } catch (e) {
      this.setData({
        busy: false,
        status: 'NOTE FAIL - recogniser would not start',
        lastEvent: 'EVT: NOTE start failed - ' + this._err(e)
      });
    }
  },

  // ---------- SAVE: only a dictated, on-screen memo can be anchored ----------

  saveTap() {
    this._doneArm = false;
    if (!this._pendingMemo) {
      // Nothing dictated = nothing to anchor. A nod or SAVE with no
      // pending memo NEVER invents or saves one.
      this.setData({
        status: 'SAVE FAIL: no memo - tap NOTE and say it first',
        lastEvent: 'EVT: SAVE refused - no dictated memo pending'
      });
      return;
    }
    if (this._heading === null) {
      // Same honesty rule as find-my-thing #07: never invent a
      // heading. A memo without a direction is a note, not an anchor.
      this.setData({
        status: 'SAVE FAIL: no heading (SRC NONE) - DEMO or wait for sensor',
        lastEvent: 'EVT: SAVE refused - never invent a heading'
      });
      return;
    }
    var st = this._stamp();
    var rec = {
      id: ++this._idSeq,
      cat: this._cat(),
      memo: this._pendingMemo,
      heading: Math.round(this._heading),
      date: st.date,
      time: st.time,
      demo: !!this._demo
    };
    var dropped = this._addAnchor(rec);
    this._pendingMemo = null;
    this._pendingTag = '';
    for (var i = 0; i !== this._anchors.length; i++) {
      if (this._anchors[i].id === rec.id) this._selIdx = i;
    }
    this.setData({
      status: 'ANCHORED: ' + rec.cat + ' · ' + rec.heading + '° - face it later, I remind you',
      lastEvent: dropped
        ? 'EVT: cap 10 - oldest anchor dropped: ' + dropped.cat + ' · ' + dropped.memo.slice(0, 12)
        : 'EVT: anchored ' + rec.cat + ' at heading ' + rec.heading + ' deg' + (rec.demo ? ' (DEMO heading)' : '')
    });
    this._recompute();
  },

  // ---------- DONE: two-step delete of the selected anchor ----------

  doneTap() {
    var recs = this._anchors || [];
    if (!recs.length) {
      this.setData({ lastEvent: 'EVT: nothing to delete - no anchors' });
      return;
    }
    var idx = this._selIdx || 0;
    if (idx >= recs.length) idx = 0;
    var target = recs[idx];
    if (!this._doneArm) {
      this._doneArm = true;
      this.setData({
        status: 'DONE? tap DONE again to delete: ' + target.cat + ' · ' + target.memo.slice(0, 16),
        lastEvent: 'EVT: delete armed for ' + target.cat + ' (tap DONE again)'
      });
      return;
    }
    this._doneArm = false;
    recs.splice(idx, 1);
    delete this._face[target.id];
    if (this._selIdx >= recs.length) this._selIdx = Math.max(0, recs.length - 1);
    this._saveAnchors();
    this.setData({
      status: 'DELETED: ' + target.cat + ' · ' + target.memo.slice(0, 16),
      lastEvent: 'EVT: anchor deleted - ' + target.cat
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO seeds 2 labeled anchors (medicine 45 deg / spare key 200
  // deg) from ONE clock snapshot, simulated heading starts at 0.
  // Further taps step the heading +45 deg: at 45 deg the medicine
  // anchor is dead ahead - hold 2 s and its REMIND card + speech
  // fire. Re-entering DEMO replaces older demo anchors.
  demoTap() {
    this._doneArm = false;
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      this._anchors = (this._anchors || []).filter(function (r) { return !r.demo; });
      var st = this._stamp();
      this._addAnchor({ id: ++this._idSeq, cat: '药', memo: '睡前吃一片降压药', heading: 45, date: st.date, time: st.time, demo: true });
      this._addAnchor({ id: ++this._idSeq, cat: '钥匙', memo: '备用钥匙放在鞋柜里', heading: 200, date: st.date, time: st.time, demo: true });
      for (var i = 0; i !== this._anchors.length; i++) {
        if (this._anchors[i].heading === 45 && this._anchors[i].demo) this._selIdx = i;
      }
      this.setData({
        status: 'DEMO: 2 anchors - DEMO steps heading +45, hold 2 s at 45',
        lastEvent: 'EVT: DEMO on - anchors @45 (药） and @200 （钥匙）'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      this.setData({
        status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
      });
    }
    this._recompute();
  },

  // ---------- REMIND engine ----------

  _faceState(a) {
    var st = this._face[a.id];
    if (!st) {
      st = { inCone: false, dwellMs: 0, fired: false, outMs: 0, armed: true };
      this._face[a.id] = st;
    }
    return st;
  },

  _relOf(a) {
    if (this._heading === null) return null;
    return ((a.heading - this._heading + 540) % 360) - 180; // -180..180, + = to your right
  },

  // Runs every 500 ms tick. An anchor FIRES when the heading stays
  // within ±15 deg of it for 2 continuous seconds: its card surfaces
  // and its memo is spoken ONCE for that facing episode. It re-arms
  // only after the heading has been outside the cone for >= 5 s, so
  // glancing back and forth never spams the reminder.
  _remindTick() {
    if (this._heading === null) return;
    var best = null;
    var bestAbs = 999;
    var list = this._anchors || [];
    for (var i = 0; i !== list.length; i++) {
      var a = list[i];
      var rel = this._relOf(a);
      var st = this._faceState(a);
      if (Math.abs(rel) <= 15) {
        st.outMs = 0;
        if (!st.inCone) { st.inCone = true; st.dwellMs = 0; }
        else st.dwellMs += 500;
        if (Math.abs(rel) < bestAbs) { bestAbs = Math.abs(rel); best = a; }
      } else {
        st.inCone = false;
        st.dwellMs = 0;
        if (st.fired) {
          st.outMs += 500;
          if (st.outMs >= 5000) { st.fired = false; st.armed = true; st.outMs = 0; }
        }
      }
    }
    if (best) {
      var bst = this._faceState(best);
      if (bst.dwellMs >= 2000 && !bst.fired && bst.armed) {
        bst.fired = true;
        bst.armed = false;
        this._fireAnchor(best);
        return;
      }
    }
    this._recompute();
  },

  _fireAnchor(a) {
    var spoken = this._speak('备忘提醒：' + a.memo);
    this.setData({
      lastEvent: 'EVT: REMIND ' + a.cat + ' - facing its direction' +
        (spoken ? ' (spoken once)' : ' (TTS n/a here)')
    });
    this._recompute();
  },

  _facingAnchor() {
    var list = this._anchors || [];
    for (var i = 0; i !== list.length; i++) {
      var st = this._face[list[i].id];
      if (st && st.fired && st.inCone) return list[i];
    }
    return null;
  },

  // ---------- guidance (same geometry as home-find / find-my-thing) ----------

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _selAnchor() {
    var list = this._anchors || [];
    if (!list.length) return null;
    var idx = this._selIdx || 0;
    if (idx >= list.length) idx = 0;
    return list[idx];
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      catLine: 'CAT: ' + this._cat() + ' · tap CAT to switch',
      memoLine: this._pendingMemo
        ? 'MEMO: ' + this._pendingMemo + (this._pendingTag === 'heard' ? ' (heard - check it)' : ' (preset)')
        : 'MEMO: (none yet) - tap NOTE and say it',
      micLine: this._micNote
    };
    var list = this._anchors || [];
    if (!list.length) {
      patch.rows = [{ text: '(no anchors) - NOTE one here, or DEMO' }];
    } else {
      patch.rows = list.map(function (r) {
        return {
          text: r.cat + ' · ' + r.memo + ' · ' + r.heading + '° · ' +
            r.date.slice(5) + ' ' + r.time + (r.demo ? ' DEMO' : '')
        };
      });
    }
    patch.countLine = 'ANCHORS: ' + list.length + '/10 · saved on this device only';

    // The REMIND card: while you face a fired anchor's direction its
    // memo is surfaced big. The anchor binds the DIRECTION you faced
    // when noting - not the object itself; if the thing was moved,
    // the direction still points at the old spot.
    var facing = this._facingAnchor();
    if (facing) {
      patch.anchorLine = 'ANCHOR: ' + facing.cat + ' · ' + facing.memo + ' · noted ' + facing.time;
      patch.anchorCls = 'anchor anchor-on';
    } else {
      patch.anchorLine = 'ANCHOR: face a noted direction 2 s - memo pops here';
      patch.anchorCls = 'anchor';
    }

    var sel = this._selAnchor();
    if (!sel) {
      patch.arrow = '·';
      patch.guideLine = 'GUIDE: no anchor selected';
      patch.guideCls = 'rel';
      this.setData(patch);
      return;
    }
    var rel = this._relOf(sel);
    if (rel === null) {
      patch.arrow = '·';
      patch.guideLine = 'GUIDE: ' + sel.cat + ' · heading n/a - SRC NONE, tap DEMO';
      patch.guideCls = 'rel';
      this.setData(patch);
      return;
    }
    var rel360 = (sel.heading - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    if (Math.abs(rel) <= 15) {
      patch.guideLine = 'FACING IT: ' + sel.cat + ' · ' + sel.memo;
      patch.guideCls = 'rel rel-on';
    } else {
      patch.guideLine = 'TURN: ' + dir.en + ' ' + deg + '° -> ' + sel.cat + ' anchor';
      patch.guideCls = 'rel';
    }
    this.setData(patch);
  },

  // ---------- speech ----------

  // NOTE: no utterance.lang is ever set (post-audit rule - the host
  // ignores it); the memo text is spoken exactly as dictated/saved.
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  speakTap() {
    var sel = this._selAnchor();
    var text;
    if (!sel) {
      text = '还没有备忘锚点。先看着要记的东西，点 NOTE 说出备忘，再点保存。';
    } else {
      text = sel.cat + '，' + sel.memo + '。这是你在 ' + sel.time +
        ' 记下的，锚在朝向 ' + sel.heading + ' 度。';
      var rel = this._relOf(sel);
      if (rel === null) {
        text += '现在没有你的朝向读数。';
      } else if (Math.abs(rel) <= 15) {
        text += '你现在正对着当时记备忘的方向。';
      } else {
        var dir = this._dirName(rel);
        text += '向你' + dir.zh + '转' + Math.round(Math.abs(rel)) + '度，就对着那个方向。';
      }
    }
    if (this._speak(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text.slice(0, 46) });
    } else {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">MEMORY ANCHOR</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="note-box">
      <text class="cat">{{catLine}}</text>
      <text class="memo">{{memoLine}}</text>
      <text class="mic">{{micLine}}</text>
      <text class="count">{{countLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="anchor-box">
      <text class="{{anchorCls}}">{{anchorLine}}</text>
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{guideCls}}">{{guideLine}}</text>
      </view>
      <text class="honest">REMIND: only while open · binds direction, not the thing</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="noteTap">NOTE</button>
      <button class="btn" bindtap="catTap">CAT</button>
      <button class="btn btn-main" bindtap="saveTap">SAVE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="selTap">SEL</button>
      <button class="btn" bindtap="doneTap">DONE</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 6px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 3px;
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
  line-height: 14px;
  margin-top: 1px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.note-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 10px;
  margin-bottom: 3px;
}
.cat {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
}
.memo {
  color: #40ff5e;
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.mic {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.count {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
.list {
  height: 32px;
  margin-bottom: 3px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.rtext {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.anchor-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 3px;
  margin-bottom: 3px;
}
.anchor {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  font-weight: 500;
  line-height: 15px;
}
.anchor-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.guide-top {
  display: flex;
  flex-direction: row;
    align-items: center;
}
.arrow {
  color: #40ff5e;
  font-size: 24px;
  line-height: 27px;
  margin-right: 10px;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.honest {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 3px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 3px;
  font-size: 11px;
  font-weight: 500;
  line-height: 15px;
  text-align: center;
}
.btn-main {
  color: #40ff5e;
  border-color: rgba(64,255,94,0.72);
  background-color: rgba(64,255,94,0.12);
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
