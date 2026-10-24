<script def>
{
  "navigationBarTitleText": "Voice List"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '家人连珠炮说的五样东西 — 你复述一遍，它替你记成清单',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 购物清单 — 滑动选一项，点头勾掉它',
    bigLabel: '（清单是空的）',
    bigText: '----',
    bigCls: 'bignum',
    bigNote: 'DICT 说一项 / PRESET 快加 / DEMO 演示',
    micLine: 'MIC CHECK: not run',
    rows: [
      { name: '(no items)', detail: 'DICT an item in your own voice, confirm it, it joins the list - or DEMO', flag: '', cls: 'row' }
    ],
    countLine: 'LIST: 0/0 已勾 · 还差 0 项 · 文字存本机',
    lastEvent: 'EVT: ready - an item joins the list only after YOU confirm it',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'list'; // list | pending (a heard item waiting on the confirm chip)
    this._items = this._loadItems(); // confirmed TEXT items only: {text, done}
    this._focus = this._firstOpen(); // focus starts on the first unchecked item
    this._pending = null; // unconfirmed heard item (never in the list yet)
    this._presetIdx = -1; // which preset the PRESET button last produced
    this._spotKey = null; // identity of the item the last-item spotlight fired for
    this._allDoneSaid = false;
    this._delArmIdx = -1; // two-step item delete
    this._clearArm = false; // two-step whole-list clear
    this._armTimer = null;
    this._nodLock = false;
    this._demo = false;
    this._demoStep = 0;
    this._renderAll();
    this.setData({
      lastEvent: 'EVT: ' + this._items.length + ' confirmed item(s) restored from this device'
    });
  },

  onShow() {},

  onHide() {
    this._stopDictRec();
    this._disarm();
  },

  onUnload() {
    this._stopDictRec();
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
    this._saveItems();
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
    // Nod discipline in THIS agent: a steady nod CHECKS the focused
    // item - that is the HOLD gesture this agent is built around,
    // one nod = one check, spoken as it lands. A nod never unchecks
    // (unchecking is a deliberate Enter toggle), never confirms a
    // pending dictation, never deletes, never clears.
    if (this._mode === 'pending') {
      this.setData({ lastEvent: 'EVT: nod ignored in confirm - press OK to add, nod never adds' });
      return;
    }
    if (!this._items.length) {
      this.setData({ lastEvent: 'EVT: nod - list is empty, nothing to check' });
      return;
    }
    var it = this._items[this._focus];
    if (!it) { this.setData({ lastEvent: 'EVT: nod - no focused item' }); return; }
    if (it.done) {
      this.setData({ lastEvent: 'EVT: nod - ' + this._disp(it.text) + ' already checked (nod never unchecks; Enter toggles)' });
      return;
    }
    this._checkItem(this._focus, 'nod');
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.okTap();
    } else if (code === 'ArrowDown') {
      this._forward(1);
    } else if (code === 'ArrowUp') {
      this._forward(-1);
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

  // Display truncation is honest: a long item shows its first 12
  // characters + a marker, the FULL text stays in storage and is
  // what SPEAK reads out.
  _disp(text) {
    var s = String(text || '');
    return s.length > 12 ? s.slice(0, 12) + '…' : s;
  },

  _truncated(text) {
    return String(text || '').length > 12;
  },

  _firstOpen() {
    for (var i = 0; i < this._items.length; i++) {
      if (!this._items[i].done) return i;
    }
    return this._items.length ? 0 : -1;
  },

  _remaining() {
    var out = [];
    for (var i = 0; i < this._items.length; i++) {
      if (!this._items[i].done) out.push(i);
    }
    return out;
  },

  // ---------- persistence (wx sync storage, key 'voiceList', TEXT ONLY) ----------
  // The whole point of this agent: dictate at home, shop later.
  // The list is {text, done} plain text in this app's local storage
  // on the glasses, so it survives closing the agent. That is stated
  // plainly in the UI - nothing else is stored, no audio, ever.

  _loadItems() {
    try {
      var raw = wx.getStorageSync('voiceList');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 8; i++) {
        var it = raw[i];
        if (it && typeof it.text === 'string' && it.text) {
          out.push({ text: String(it.text).slice(0, 30), done: it.done === true });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveItems() {
    if (this._demo) return; // demo list never touches real storage
    try {
      wx.setStorageSync('voiceList', this._items || []);
    } catch (e) { /* storage unavailable on this host: list stays in memory */ }
  },

  // ---------- two-step arming (item delete / whole-list clear) ----------

  _disarm() {
    this._delArmIdx = -1;
    this._clearArm = false;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  _arm(kind, idx) {
    this._disarm();
    if (kind === 'del') this._delArmIdx = idx;
    if (kind === 'clear') this._clearArm = true;
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._delArmIdx === idx || self._clearArm) {
        self._disarm();
        self.setData({ lastEvent: 'EVT: disarmed (timeout) - nothing deleted' });
        self._renderAll();
      }
    }, 6000);
  },

  // ---------- focus movement (swipes + +1/-1 buttons) ----------

  _forward(delta) {
    if (this.data.busy) return;
    if (this._mode === 'pending') {
      this.setData({ lastEvent: 'EVT: focus locked on the pending item - OK adds it, DEL drops it' });
      return;
    }
    this._disarm();
    if (!this._items.length) {
      this.setData({ lastEvent: 'EVT: no items to move through yet' });
      return;
    }
    var n = this._items.length;
    var cur = this._focus < 0 ? 0 : this._focus;
    this._focus = (((cur + delta) % n) + n) % n;
    var it = this._items[this._focus];
    this.setData({
      lastEvent: 'EVT: focus ' + (this._focus + 1) + '/' + n + ' - ' + this._disp(it.text) + (it.done ? ' (checked)' : '')
    });
    this._renderAll();
  },

  plus1Tap() { this._forward(1); },
  minus1Tap() { this._forward(-1); },

  // ---------- check / uncheck ----------

  // The ONLY place an item becomes done via a deliberate check.
  // Spoken as it lands: "牛奶，勾了 3/5".
  _checkItem(idx, how) {
    var it = this._items[idx];
    if (!it || it.done) return;
    it.done = true;
    this._disarm();
    this._saveItems();
    var doneCount = this._items.length - this._remaining().length;
    this._speakText(it.text + '，勾了 ' + doneCount + '/' + this._items.length);
    this.setData({
      status: '✓ ' + this._disp(it.text) + ' 勾了（' + how + '）· ' + doneCount + '/' + this._items.length,
      lastEvent: 'EVT: checked ' + this._disp(it.text) + ' by ' + how + ' - ' + doneCount + '/' + this._items.length + ' done'
    });
    this._afterChange();
  },

  _uncheckItem(idx, how) {
    var it = this._items[idx];
    if (!it || !it.done) return;
    it.done = false;
    this._disarm();
    this._saveItems();
    this._speakText(it.text + '，取消勾选');
    this.setData({
      status: this._disp(it.text) + ' 取消勾选（' + how + '）— 又回到待买里',
      lastEvent: 'EVT: unchecked ' + this._disp(it.text) + ' by ' + how + ' (deliberate toggle)'
    });
    this._afterChange();
  },

  // Spotlight + all-done announcements, fired off every change.
  // Both speak ONCE per arrival: the spotlight re-arms whenever the
  // remaining count leaves 1 (so an item checked, then unchecked
  // back to last-one, is announced again - honestly, not silently).
  _afterChange() {
    var rem = this._remaining();
    if (rem.length === 1) {
      var key = 'i' + rem[0];
      if (this._spotKey !== key) {
        this._spotKey = key;
        var it = this._items[rem[0]];
        this._speakText('就剩最后一项：' + it.text);
        this.setData({
          status: '⚠ 就剩最后一项：' + this._disp(it.text) + ' — 出门前最容易漏的就是它'
        });
      }
    } else {
      this._spotKey = null;
    }
    if (this._items.length > 0 && rem.length === 0) {
      if (!this._allDoneSaid) {
        this._allDoneSaid = true;
        this._speakText('全买齐了');
        this.setData({ status: '🎉 全买齐了 — 清单 ' + this._items.length + ' 项全勾完' });
      }
    } else {
      this._allDoneSaid = false;
    }
    this._renderAll();
  },

  // ---------- OK (contextual primary, mirrors Enter) ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'pending') { this._confirmPending(); return; }
    if (!this._items.length || this._focus < 0) {
      this.setData({
        status: '清单是空的 — 先 DICT 说一项，或 PRESET 快加',
        lastEvent: 'EVT: OK refused - nothing to toggle yet'
      });
      this._renderAll();
      return;
    }
    var it = this._items[this._focus];
    if (it.done) this._uncheckItem(this._focus, 'Enter');
    else this._checkItem(this._focus, 'Enter');
  },

  // ---------- pending item: confirm / drop ----------

  _setPending(text, src) {
    this._pending = { text: text, src: src };
    this._mode = 'pending';
    this.setData({
      status: '听到这一项：「' + this._disp(text) + '」— 对了 OK 入单' +
        (this._truncated(text) ? '（显示截断，全文朗读为准）' : ''),
      lastEvent: 'EVT: pending "' + this._disp(text) + '" from ' + src + ' - NOT in the list yet'
    });
    this._renderAll();
  },

  _confirmPending() {
    var p = this._pending;
    if (!p) { this._mode = 'list'; this._renderAll(); return; }
    if (this._items.length >= 8) {
      // Full: honest refusal, pending kept - never a silent drop.
      this.setData({
        status: '清单满了 8/8 — 先删一项，这项先留着不丢',
        lastEvent: 'EVT: ADD refused - list full 8/8, pending kept, nothing dropped'
      });
      this._renderAll();
      return;
    }
    this._items.push({ text: p.text, done: false });
    this._focus = this._items.length - 1;
    this._pending = null;
    this._mode = 'list';
    this._presetIdx = -1;
    this._saveItems();
    this.setData({
      status: '✓ 已入单：' + this._disp(p.text) + ' · 共 ' + this._items.length + '/8 项',
      lastEvent: 'EVT: added "' + this._disp(p.text) + '" (' + p.src + ') - list saved as text'
    });
    this._afterChange();
  },

  _dropPending(how) {
    var p = this._pending;
    this._pending = null;
    this._mode = 'list';
    this._presetIdx = -1;
    this.setData({
      status: '已丢弃待确认的这一项（它本来就没入单）',
      lastEvent: 'EVT: pending "' + (p ? this._disp(p.text) : '') + '" dropped by ' + how + ' - it was never in the list'
    });
    this._renderAll();
  },

  // ---------- PRESET quick-add chips ----------

  _presets() {
    return ['牛奶', '鸡蛋', '钥匙'];
  },

  presetTap() {
    if (this.data.busy) return;
    this._disarm();
    var presets = this._presets();
    this._presetIdx = (this._presetIdx + 1) % presets.length;
    // A preset lands on the same confirm chip as a dictation: one
    // more tap cycles to the next preset, OK adds it. Quick-add is
    // for silent moments, not a bypass of the confirm step.
    this._setPending(presets[this._presetIdx], 'PRESET');
  },

  // ---------- DEL (drop pending / two-step delete focused item) ----------

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'pending') { this._dropPending('DEL'); return; }
    var idx = this._focus;
    if (idx < 0 || idx >= this._items.length) {
      this.setData({ lastEvent: 'EVT: DEL - nothing focused' });
      return;
    }
    if (this._delArmIdx === idx) {
      var gone = this._items.splice(idx, 1)[0];
      this._disarm();
      if (this._focus >= this._items.length) this._focus = this._items.length - 1;
      if (this._focus < 0 && this._items.length) this._focus = 0;
      this._saveItems();
      this.setData({
        status: '已删：' + this._disp(gone.text) + ' · 还剩 ' + this._items.length + ' 项',
        lastEvent: 'EVT: deleted "' + this._disp(gone.text) + '" (two-step DEL)'
      });
      this._afterChange();
    } else {
      this._arm('del', idx);
      this.setData({
        status: '⚠ 再点一次 DEL 删掉「' + this._disp(this._items[idx].text) + '」（其他动作取消）',
        lastEvent: 'EVT: DEL 1/2 - delete ARMED for "' + this._disp(this._items[idx].text) + '" (nothing deleted yet)'
      });
      this._renderAll();
    }
  },

  // ---------- CLEAR (two-step, whole list) ----------

  clearTap() {
    if (this.data.busy) return;
    if (this._mode === 'pending') {
      this.setData({
        status: '先处理待确认的这一项：OK 入单或 DEL 丢弃',
        lastEvent: 'EVT: CLEAR refused while an item is pending'
      });
      this._renderAll();
      return;
    }
    if (!this._items.length) {
      this.setData({ lastEvent: 'EVT: CLEAR - list already empty' });
      return;
    }
    if (this._clearArm) {
      this._disarm();
      this._items = [];
      this._focus = -1;
      this._spotKey = null;
      this._allDoneSaid = false;
      this._saveItems();
      this._speakText('清单已清空');
      this.setData({
        status: '清单已清空 — 下一趟重新说',
        lastEvent: 'EVT: list cleared (two-step CLEAR, spoken once)'
      });
      this._renderAll();
    } else {
      this._arm('clear', -1);
      this.setData({
        status: '⚠ 再点一次 CLEAR 清空整张清单 ' + this._items.length + ' 项（其他动作取消）',
        lastEvent: 'EVT: CLEAR 1/2 - clear ARMED (nothing cleared yet)'
      });
      this._renderAll();
    }
  },

  // ---------- DICT (you say the item yourself; check first, then host ASR) ----------

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  // What the wearer said becomes ONE list item, close to verbatim:
  // shopping-list filler around it is stripped ("买一瓶洗手液" ->
  // "洗手液" would lose the quantity - so ONLY bare lead-ins go:
  // 买/要买/带/拿 at the very start and trailing punctuation).
  // Anything longer than 30 chars is truncated with the cut stated,
  // never silently. Empty after stripping = not heard, rejected.
  _parseItem(raw) {
    if (!raw) return null;
    var s = String(raw).replace(/\s+/g, '');
    s = s.replace(/^(我要买|要买|我想买|买|带|拿|记得买|别忘了买|别忘了)/, '');
    s = s.replace(/[。．.!！?？]+$/g, '');
    if (!s) return null;
    if (s.length < 1) return null;
    return s.slice(0, 30);
  },

  _applyDictatedItem(txt) {
    var v = this._parseItem(txt);
    if (v === null) {
      this.setData({
        status: '没听清成一项：「' + String(txt || '(empty)').slice(0, 12) + '」— 没猜，再点 DICT 说一遍',
        lastEvent: 'EVT: DICT parse FAIL - rejected, list unchanged'
      });
      this._renderAll();
      return false;
    }
    if (String(txt).replace(/\s+/g, '').length > 30) {
      this.setData({ lastEvent: 'EVT: dictated item over 30 chars - truncated to 30, full text NOT kept beyond that' });
    }
    this._presetIdx = -1;
    this._setPending(v, 'DICT');
    return true;
  },

  dictTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: DICT in DEMO - no microphone used' });
      return;
    }
    if (this._mode === 'pending') {
      // Re-dictating replaces the pending item (it was never added).
      this.setData({ lastEvent: 'EVT: re-DICT - the new hearing replaces the pending item' });
    }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'DICT SKIP - 这台设备没有识别；用 PRESET 快加，或真机再试',
        lastEvent: 'EVT: DICT SKIP (host ASR n/a) - nothing faked, preset path still works'
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
    // the host SpeechRecognition below listens on its own microphone,
    // and it hears the WEARER saying the item in their own voice:
    // the family member said it once, you repeat it once, the list
    // is built from YOUR repetition, and the confirm chip is where a
    // mishearing gets caught. Result on its own MIC CHECK line; the
    // listening line says (host ASR).
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
          self._applyDictatedItem(txt);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'DICT FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + '，再点 DICT，或用 PRESET',
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
        status: 'DICT listening (host ASR)... 说一项你要买/带的东西（只听你的声音）',
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

  // ---------- SPEAK (remaining items only) ----------

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
    if (this._mode === 'pending' && this._pending) {
      // In confirm, SPEAK reads the pending item (full text) so the
      // wearer can verify by ear what the chip shows by eye.
      if (this._speakText('待确认：' + this._pending.text)) {
        this.setData({ lastEvent: 'EVT: SPEAK pending item (full text, TTS, no lang set)' });
      }
      return;
    }
    var rem = this._remaining();
    if (!this._items.length) {
      this.setData({ lastEvent: 'EVT: SPEAK - list is empty' });
      return;
    }
    if (!rem.length) {
      if (this._speakText('全买齐了，没有还差的')) {
        this.setData({ lastEvent: 'EVT: SPEAK - nothing remaining' });
      }
      return;
    }
    var names = [];
    for (var i = 0; i < rem.length; i++) names.push(this._items[rem[i]].text);
    if (this._speakText('还差 ' + rem.length + ' 项：' + names.join('、'))) {
      this.setData({ lastEvent: 'EVT: SPEAK remaining ' + rem.length + ' item(s) only (TTS, no lang set)' });
    }
  },

  // ---------- DEMO (seeded 5-item list, 3 checked; steps walk the ending) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealItems = this._items;
      this._demoRealFocus = this._focus;
      this._demoRealPending = this._pending;
      this._demoRealMode = this._mode;
      this._demo = true;
      this._demoStep = 0;
      this._disarm();
      this._pending = null;
      this._mode = 'list';
      this._items = [
        { text: '牛奶', done: true },
        { text: '鸡蛋', done: false },
        { text: '钥匙', done: true },
        { text: '洗手液', done: true },
        { text: '苹果', done: false }
      ];
      this._focus = 1; // 鸡蛋 - first unchecked
      this._spotKey = null;
      this._allDoneSaid = false;
      this.setData({
        status: 'DEMO - 5 项已勾 3 项：焦点在鸡蛋，点 DEMO 继续走完',
        lastEvent: 'EVT: DEMO on - seeded 5 items, 3 checked (memory only, real list untouched)'
      });
      this._renderAll();
      return;
    }
    // Further DEMO taps walk the scripted ending: check the focused
    // demo item, so the last-item spotlight and the all-done line
    // both fire exactly as they would from a nod at the shelf.
    this._demoStep++;
    if (this._demoStep === 1) {
      this._checkItem(1, 'DEMO'); // 鸡蛋 -> remaining 1 -> spotlight 苹果
      this.setData({ lastEvent: 'EVT: DEMO step 1 - checked 鸡蛋 (simulated), spotlight on the last item' });
      return;
    }
    if (this._demoStep === 2) {
      this._focus = 4;
      this._checkItem(4, 'DEMO'); // 苹果 -> all done
      this.setData({ lastEvent: 'EVT: DEMO step 2 - checked 苹果 (simulated), list complete' });
      return;
    }
    // Third tap exits: the real list comes back exactly as it was.
    this._demo = false;
    this._demoStep = 0;
    this._items = this._demoRealItems || [];
    this._focus = (typeof this._demoRealFocus === 'number') ? this._demoRealFocus : -1;
    this._pending = this._demoRealPending || null;
    this._mode = this._demoRealMode || 'list';
    this._demoRealItems = null;
    this._demoRealPending = null;
    this._spotKey = null;
    this._allDoneSaid = false;
    this._disarm();
    this.setData({
      status: 'DEMO OFF - your real list is back (' + this._items.length + ' items)',
      lastEvent: 'EVT: DEMO cleared - real list restored exactly, nothing was written'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, it;
    for (i = 0; i !== this._items.length; i++) {
      it = this._items[i];
      rows.push({
        name: (i === this._focus && this._mode === 'list' ? '▸ ' : '') + (it.done ? '✓ ' : '☐ ') + this._disp(it.text),
        detail: it.done ? '已勾' : '待买/待带',
        flag: i === this._focus && this._mode === 'list' ? 'FOCUS' : '',
        cls: 'row'
      });
    }
    if (!rows.length) {
      rows.push({
        name: '(no items)',
        detail: 'DICT an item in your own voice, confirm it, it joins the list - or DEMO',
        flag: '',
        cls: 'row'
      });
    }

    var rem = this._remaining();
    var doneCount = this._items.length - rem.length;
    var patch = { rows: rows };
    if (rem.length) {
      var names = [];
      for (i = 0; i < rem.length && i < 3; i++) names.push(this._disp(this._items[rem[i]].text));
      patch.countLine = 'LIST: ' + doneCount + '/' + this._items.length + ' 已勾 · 还差 ' +
        names.join('、') + (rem.length > 3 ? ' 等 ' + rem.length + ' 项' : ' · 共 ' + rem.length + ' 项') + ' · 文字存本机';
    } else {
      patch.countLine = 'LIST: ' + doneCount + '/' + this._items.length + ' 已勾 · 还差 0 项 · 文字存本机';
    }

    if (this._mode === 'pending' && this._pending) {
      var p = this._pending;
      patch.boxLabel = p.src === 'PRESET'
        ? '◎ 快加待确认 — 核对后 OK 才入单（PRESET 再点换下一个）'
        : '◎ ASR 听写待确认 — 识别可能听错，这里核对（只听你复述的）';
      patch.bigLabel = '待确认 · 来源 ' + p.src + (this._truncated(p.text) ? ' · 显示截断，全文已留' : '');
      patch.bigText = this._disp(p.text);
      patch.bigNote = 'OK 入单 · DICT 重念替换 · DEL 丢弃这项 · 点头不入单';
    } else if (this._items.length && rem.length === 0) {
      patch.boxLabel = '◎ 清单完成 — 全勾完了';
      patch.bigLabel = this._items.length + ' 项全部勾完';
      patch.bigText = '全买齐了 ✓';
      patch.bigNote = 'CLEAR 两下清空备下一趟 · OK 点已勾项可取消勾选';
    } else if (rem.length === 1 && this._spotKey !== null) {
      var last = this._items[rem[0]];
      patch.boxLabel = '◎ 就剩最后一项 — 出门前/结账前最容易漏的一项';
      patch.bigLabel = '最后一项 · 还差这一件';
      patch.bigText = this._disp(last.text);
      patch.bigNote = '看向它，头稳点头（或 OK）勾掉它 · SPEAK 只读还差的';
    } else if (this._focus >= 0 && this._items[this._focus]) {
      it = this._items[this._focus];
      patch.boxLabel = '◎ 购物清单 — 滑动选一项，头稳点头勾掉它';
      patch.bigLabel = '第 ' + (this._focus + 1) + '/' + this._items.length + ' 项 · ' + (it.done ? '已勾' : '待买/待带') +
        (this._truncated(it.text) ? ' · 显示截断' : '');
      patch.bigText = this._disp(it.text);
      patch.bigNote = this._delArmIdx === this._focus
        ? '⚠ 删除已武装 — 再点 DEL 真的删'
        : this._clearArm
          ? '⚠ 清空已武装 — 再点 CLEAR 清空整单'
          : '点头/OK 勾它 · 已勾的 OK 取消勾 · SPEAK 只读还差的';
    } else {
      patch.boxLabel = '◎ 购物清单 — 滑动选一项，点头勾掉它';
      patch.bigLabel = '（清单是空的）';
      patch.bigText = '----';
      patch.bigNote = 'DICT 说一项 / PRESET 快加 / DEMO 演示';
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
      <text class="title">VOICE LIST</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="presetTap">PRESET</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
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
    <text class="foot2">清单靠你自己的声音记 · 识别成什么样先核对再入单 · 只存文字</text>
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
