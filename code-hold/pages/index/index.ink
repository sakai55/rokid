<script def>
{
  "navigationBarTitleText": "Code Hold"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '朋友报的码听一遍记不住 — 你复述一遍，它替你存住',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 已存的码 — 滑动选择，OK 打开逐段看',
    bigLabel: '（还没有存码）',
    bigCode: '----',
    bigCls: 'bignum',
    bigNote: 'DICT 复述一个码 / LABEL 选标签 / DEMO 演示',
    secLine: '存法：明文存本机存储 · 无加密 · 用完即焚',
    micLine: 'MIC CHECK: not run',
    rows: [
      { name: '(no codes)', detail: 'DICT the code in your own voice, confirm it, it stays here - or DEMO', flag: '', cls: 'row' }
    ],
    countLine: 'HELD: 0/4 · 明文存本机 · 无加密',
    lastEvent: 'EVT: ready - a code is stored only after YOU confirm it',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'list'; // list | capture | confirm | show
    this._entries = this._loadEntries(); // confirmed TEXT entries only
    this._sel = this._entries.length ? 0 : -1;
    this._labelIdx = 0; // label chip for the next capture
    this._pending = null; // unconfirmed capture in progress (never stored yet)
    this._capText = '';
    this._capSrc = '';
    this._digitMode = false; // 逐位念： digit-by-digit dictation is the reliable path
    this._curPos = -1; // digit cursor inside the confirm buffer (pure-digit codes)
    this._chunkIdx = 0; // current chunk in show mode
    this._burnSuggest = false; // last chunk viewed -> burn suggested, never automatic
    this._burnArmIdx = -1; // two-step burn: entry index currently armed, -1 = none
    this._nodLock = false;
    this._armTimer = null;
    this._demo = false;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: ' + this._entries.length + ' confirmed code(s) on this device' });
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
    // Nod discipline in THIS agent: a nod is SPEAK and nothing else.
    // It never saves, never burns - deliberately unlike H01
    // number-catch, where the PLAN sanctioned a two-step nod clear.
    // A password you might still need is not deleted by a head move.
    if (this._mode === 'show') {
      this.speakTap();
      this.setData({ lastEvent: 'EVT: nod in show = SPEAK this chunk (nod never burns here)' });
    } else if (this._mode === 'list') {
      this.speakTap();
      this.setData({ lastEvent: 'EVT: nod in list = SPEAK (nod never deletes here)' });
    } else if (this._mode === 'confirm') {
      this.setData({ lastEvent: 'EVT: nod ignored in confirm - press OK to store, nod never stores' });
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored while capturing - DICT / step first' });
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
      this._forward(1, 'key');
    } else if (code === 'ArrowUp') {
      this._forward(-1, 'key');
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
  // calls, so one entry's time comes from one read - sibling lesson).
  _stamp() {
    var d = new Date();
    return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes());
  },

  _labels() {
    return ['WiFi密码', '门锁码', '会议号', '其他'];
  },

  _curLabel() {
    if (this._pending) return this._pending.label;
    return this._labels()[this._labelIdx];
  },

  // Chunks of 4 - the unit you type with on the OTHER device:
  // "4829 · 7713" is two glances, not one long string.
  _chunks(code) {
    var out = [];
    var s = String(code || '');
    for (var i = 0; i < s.length; i += 4) out.push(s.slice(i, i + 4));
    return out;
  },

  _chunked(code) {
    return this._chunks(code).join(' · ');
  },

  // Spell a chunk out for TTS, character by character: "0 5 0 8" is
  // heard as four digits; "0508" would be heard as a number.
  _spell(s) {
    return String(s || '').split('').join(' ');
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  },

  // ---------- persistence (wx sync storage, key 'codeHold', max 4, TEXT ONLY) ----------
  // SECURITY, stated plainly: entries are PLAIN TEXT in this app's
  // local storage on the glasses. No encryption exists here and none
  // is claimed - that is exactly why the burn flow exists.

  _loadEntries() {
    try {
      var raw = wx.getStorageSync('codeHold');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 4; i++) {
        var it = raw[i];
        if (it && typeof it.code === 'string' && it.code) {
          out.push({
            label: String(it.label || '其他').slice(0, 6),
            code: String(it.code).slice(0, 24),
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
      wx.setStorageSync('codeHold', this._entries || []);
    } catch (e) { /* storage unavailable on this host: entries stay in memory */ }
  },

  // ---------- two-step burn arming ----------

  _disarm() {
    this._burnArmIdx = -1;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  _armBurn(idx) {
    this._burnArmIdx = idx;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} }
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._burnArmIdx === idx) {
        self._burnArmIdx = -1;
        self.setData({ lastEvent: 'EVT: burn disarmed (timeout) - nothing deleted' });
        self._renderAll();
      }
    }, 6000);
  },

  _burnEntry(idx, how) {
    if (idx < 0 || idx >= this._entries.length) return;
    var gone = this._entries.splice(idx, 1)[0];
    this._disarm();
    this._burnSuggest = false;
    this._saveEntries();
    if (this._sel >= this._entries.length) this._sel = this._entries.length - 1;
    if (this._mode === 'show') this._mode = 'list';
    this._chunkIdx = 0;
    this._speakText('已焚');
    this.setData({
      status: 'BURNED ✓ ' + gone.label + ' 那一条没了 — 还剩 ' + this._entries.length + '/4 条',
      lastEvent: 'EVT: burned ' + gone.label + ' code by ' + how + ' (two-step, spoken once)'
    });
    this._renderAll();
  },

  // ---------- directional dispatch (swipe keys + the +1/-1 buttons) ----------

  // Arrow keys: "down/forward" = +1, "up/back" = -1 in every mode.
  _forward(delta, source) {
    if (this.data.busy) return;
    if (this._mode === 'list') { this._moveSel(delta); return; }
    if (this._mode === 'show') { this._moveChunk(delta); return; }
    if (this._mode === 'capture') {
      if (source === 'key') {
        var labels = this._labels();
        this._labelIdx = ((this._labelIdx + delta) % labels.length + labels.length) % labels.length;
        this.setData({ lastEvent: 'EVT: label -> ' + labels[this._labelIdx] + ' (swipe)' });
        this._renderAll();
      } else {
        this._stepBuffer(delta);
      }
      return;
    }
    // confirm: keys move the digit cursor; buttons adjust that digit.
    if (source === 'key') this._moveCursor(delta);
    else this._adjustDigit(delta);
  },

  plus1Tap() { this._forward(1, 'btn'); },
  minus1Tap() { this._forward(-1, 'btn'); },

  _moveSel(delta) {
    this._disarm();
    if (!this._entries.length) {
      this.setData({ lastEvent: 'EVT: no entries to select yet' });
      return;
    }
    var n = this._entries.length;
    this._sel = (((this._sel < 0 ? 0 : this._sel) + delta) % n + n) % n;
    this.setData({ lastEvent: 'EVT: selected ' + this._entries[this._sel].label + ' (' + this._chunks(this._entries[this._sel].code).length + ' chunks)' });
    this._renderAll();
  },

  _moveChunk(delta) {
    if (this._sel < 0 || !this._entries[this._sel]) return;
    var chunks = this._chunks(this._entries[this._sel].code);
    var next = this._chunkIdx + delta;
    if (next < 0) next = 0;
    if (next > chunks.length - 1) next = chunks.length - 1;
    this._chunkIdx = next;
    this._afterChunkShown();
    this.setData({ lastEvent: 'EVT: chunk ' + (this._chunkIdx + 1) + '/' + chunks.length + ' in view' });
    this._renderAll();
  },

  // Viewing the last chunk only SUGGESTS the burn (a banner) - the
  // entry is never auto-deleted, however long you look at it.
  _afterChunkShown() {
    if (this._mode !== 'show' || this._sel < 0 || !this._entries[this._sel]) return;
    var chunks = this._chunks(this._entries[this._sel].code);
    if (this._chunkIdx >= chunks.length - 1 && chunks.length > 0) {
      if (!this._burnSuggest) {
        this._burnSuggest = true;
        this.setData({ status: '最后一段了 — 输完了点 BURN 两下焚掉（不会自动焚）' });
      }
    } else {
      this._burnSuggest = false;
    }
  },

  // Capture-mode whole-value stepper: pure-digit buffers only. It is
  // the no-voice last resort for short PINs; letter codes refuse it.
  _stepBuffer(delta) {
    this._disarm();
    var buf = this._capText;
    if (buf && !/^\d+$/.test(buf)) {
      this.setData({
        status: '步进只改纯数字码 — 含字母的靠 DICT 重念',
        lastEvent: 'EVT: stepper refused - buffer has letters, use DICT'
      });
      this._renderAll();
      return;
    }
    var v = buf ? parseInt(buf, 10) : 0;
    v += delta;
    if (v < 0) v = 0;
    if (v > 999999) v = 999999;
    this._capText = String(v);
    if (this._capSrc !== 'DICT') this._capSrc = 'MANUAL';
    this.setData({ lastEvent: 'EVT: code stepped -> ' + this._capText + ' (not stored yet)' });
    this._renderAll();
  },

  // Confirm-mode per-character stepper: the cursor picks ONE digit,
  // +1/-1 change just that digit (wrapping 0<->9). Pure-digit codes
  // only - a letter code is corrected by re-dictating it.
  _moveCursor(delta) {
    var p = this._pending;
    if (!p || !/^\d+$/.test(p.text || '')) {
      this.setData({ lastEvent: 'EVT: digit cursor n/a - this code is not pure digits, re-DICT to correct' });
      return;
    }
    var n = p.text.length;
    if (this._curPos < 0 || this._curPos >= n) this._curPos = n - 1;
    this._curPos = ((this._curPos + delta) % n + n) % n;
    this.setData({ lastEvent: 'EVT: cursor -> digit ' + (this._curPos + 1) + '/' + n + ' = ' + p.text.charAt(this._curPos) });
    this._renderAll();
  },

  _adjustDigit(delta) {
    this._disarm();
    var p = this._pending;
    if (!p) return;
    if (!/^\d+$/.test(p.text || '')) {
      this.setData({
        status: '逐位步进只改纯数字码 — 含字母的点 DICT 重念更正',
        lastEvent: 'EVT: digit stepper refused - code has letters, use DICT'
      });
      this._renderAll();
      return;
    }
    var n = p.text.length;
    if (this._curPos < 0 || this._curPos >= n) this._curPos = n - 1;
    var d = parseInt(p.text.charAt(this._curPos), 10);
    d = ((d + delta) % 10 + 10) % 10;
    var next = p.text.slice(0, this._curPos) + String(d) + p.text.slice(this._curPos + 1);
    if (next !== p.text) p.corrected = true;
    p.text = next;
    this.setData({ lastEvent: 'EVT: digit ' + (this._curPos + 1) + ' -> ' + d + ' (not stored yet)' });
    this._renderAll();
  },

  // ---------- LABEL ----------

  labelTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode === 'show') {
      this._mode = 'list';
      this._burnSuggest = false;
      this.setData({ status: '回到列表', lastEvent: 'EVT: show -> list (LABEL)' });
      this._renderAll();
      return;
    }
    var labels = this._labels();
    this._labelIdx = (this._labelIdx + 1) % labels.length;
    if (this._mode === 'confirm' && this._pending) this._pending.label = labels[this._labelIdx];
    else if (this._mode === 'list') this._enterCapture();
    this.setData({
      status: '标签：' + labels[this._labelIdx],
      lastEvent: 'EVT: label -> ' + labels[this._labelIdx]
    });
    this._renderAll();
  },

  // ---------- DIG (逐位念 toggle) ----------

  digTap() {
    if (this.data.busy) return;
    this._digitMode = !this._digitMode;
    this.setData({
      status: this._digitMode
        ? '逐位念：开 — 像「零五零八」这样一位一位念，最稳'
        : '逐位念：关 — 整段复述（字母码靠它，但要逐字核对）',
      lastEvent: 'EVT: digit-by-digit dictation ' + (this._digitMode ? 'ON' : 'OFF')
    });
    this._renderAll();
  },

  // ---------- mode entry helpers ----------

  _enterCapture() {
    this._disarm();
    this._mode = 'capture';
    this._capText = '';
    this._capSrc = '';
    this._pending = null;
    this.setData({
      status: '复述你刚听到的码 — 麦克风只听你一个人的声音',
      lastEvent: 'EVT: capture mode - label ' + this._curLabel() + ', mic hears YOU repeat it'
    });
    this._renderAll();
  },

  _enterConfirmFromCapture() {
    this._pending = {
      label: this._curLabel(), text: this._capText,
      src: this._capSrc || 'MANUAL', corrected: false
    };
    this._curPos = /^\d+$/.test(this._pending.text) ? this._pending.text.length - 1 : -1;
    this._mode = 'confirm';
    this.setData({
      status: '逐字核对 — 对了 OK 存，错了 DICT 重念 / 逐位改',
      lastEvent: 'EVT: manual entry -> confirm (' + this._pending.src + '), NOT stored yet'
    });
    this._renderAll();
  },

  _enterShow() {
    this._disarm();
    this._mode = 'show';
    this._chunkIdx = 0;
    this._burnSuggest = false;
    // Showing is SILENT by default: opening an entry never speaks
    // the code aloud - a password read out unprompted in a room
    // full of people is a leak, not a feature. SPEAK is on demand.
    this.setData({
      status: '逐段显示中 — 滑动翻段，输完记得焚',
      lastEvent: 'EVT: show mode - chunk 1 in view, nothing spoken (silent by default)'
    });
    this._afterChunkShown();
    this._renderAll();
  },

  // ---------- OK (contextual primary, mirrors Enter) ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'list') {
      if (this._sel >= 0 && this._entries.length) {
        this._enterShow();
      } else {
        this._enterCapture();
      }
      return;
    }
    if (this._mode === 'show') {
      // Enter walks the chunks while you type on the other device.
      this._moveChunk(1);
      return;
    }
    if (this._mode === 'capture') {
      if (this._capText) {
        this._enterConfirmFromCapture();
      } else {
        this.setData({
          status: '先 DICT 复述一个码，或步进填一个纯数字码',
          lastEvent: 'EVT: OK in capture refused - buffer empty'
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
    var code = String(p.text || '').trim();
    if (!code) {
      this.setData({
        status: '还没记下码 — DICT 复述或步进填入再存',
        lastEvent: 'EVT: SAVE refused - no code in the confirm buffer'
      });
      this._renderAll();
      return;
    }
    if (this._entries.length >= 4) {
      // Full: honest refusal, pending kept - never a silent overwrite,
      // and never an auto-burn of an old code to make room.
      this.setData({
        status: '已存满 4 条 — 先焚掉一条旧的，这条先留着',
        lastEvent: 'EVT: SAVE refused - store full 4/4, pending kept, nothing overwritten'
      });
      this._renderAll();
      return;
    }
    var entry = { label: p.label, code: code.slice(0, 24), time: this._stamp() };
    this._entries.push(entry);
    this._sel = this._entries.length - 1;
    this._saveEntries();
    this._pending = null;
    this._mode = 'list';
    this.setData({
      status: 'HELD ✓ ' + entry.label + ' 已存（明文）— 用完记得焚 · 共 ' + this._entries.length + '/4 条',
      lastEvent: 'EVT: stored ' + entry.label + ' code (' + p.src + ') - PLAIN TEXT on device'
    });
    this._renderAll();
  },

  // ---------- BURN (contextual: discard pending / clear buffer / two-step burn) ----------

  burnTap() {
    if (this.data.busy) return;
    if (this._mode === 'confirm') {
      // Discarding an UNSTORED pending burns nothing saved: single tap.
      this._pending = null;
      this._mode = 'list';
      this.setData({
        status: '已放弃这次的码（本来就没存）',
        lastEvent: 'EVT: pending discarded - it was never stored'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'capture') {
      this._capText = '';
      this._capSrc = '';
      this.setData({ status: '复述缓冲已清空', lastEvent: 'EVT: capture buffer cleared' });
      this._renderAll();
      return;
    }
    // list / show: two-step burn of the selected entry.
    var idx = this._sel;
    if (idx < 0 || idx >= this._entries.length) {
      this.setData({ lastEvent: 'EVT: BURN - nothing selected' });
      return;
    }
    if (this._burnArmIdx === idx) {
      this._burnEntry(idx, 'BURN x2');
    } else {
      this._armBurn(idx);
      this.setData({
        status: '⚠ 再点一次 BURN 焚掉 ' + this._entries[idx].label + ' 这条（其他动作取消）',
        lastEvent: 'EVT: BURN 1/2 - burn ARMED for ' + this._entries[idx].label + ' (nothing deleted yet)'
      });
      this._renderAll();
    }
  },

  // ---------- DICT (you repeat the code YOU heard; check first, then host ASR) ----------

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
  // as receipt-keeper / signal-watch / number-catch.
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

  // Parse what the wearer repeated into a code STRING, verbatim where
  // possible. The case of letters is PRESERVED (passwords are
  // case-sensitive - unlike number-catch, nothing is upper-cased
  // here). Returns null when nothing code-like is heard - never
  // guessed. Results shorter than 2 chars are rejected as mishears.
  _parseSpokenCode(raw) {
    if (!raw) return null;
    var s = String(raw).replace(/\s+/g, '');
    s = s.replace(/^(密码是|密码|码是|是|会议号是|会议号|门锁码)+/g, '');
    s = s.replace(/(啦|了)$/g, '');
    if (!s) return null;
    var dig = this._cnDigits();
    // Digit-by-digit: forced by the 逐位念 toggle, or whenever the
    // whole utterance is Chinese digit characters （零五零八 ->
    // "0508", leading zeros survive). The reliable path for codes.
    var allCnDigits = s.length >= 2;
    for (var i = 0; i < s.length; i++) {
      if (dig[s.charAt(i)] === undefined) { allCnDigits = false; break; }
    }
    if (this._digitMode || allCnDigits) {
      var out = '';
      var okDigits = s.length > 0;
      for (var j = 0; j < s.length; j++) {
        var ch = s.charAt(j);
        if (dig[ch] !== undefined) out += String(dig[ch]);
        else if (ch >= '0' && ch <= '9') out += ch;
        else { okDigits = false; break; }
      }
      if (okDigits && out.length >= 2) return out.slice(0, 24);
      if (this._digitMode && !okDigits) return null; // digit mode is strict
    }
    // Already a clean code token: letters / digits / . _ - , case kept.
    if (/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(s) && s.length >= 2) {
      return s.slice(0, 24);
    }
    // A Chinese numeral with units: 二千五 -> "2500" (meeting numbers).
    var v = this._cnInt(s);
    if (v !== null && v !== undefined && !isNaN(v) && v >= 10 && v <= 99999999) {
      return String(v);
    }
    // Mixed speech with a digit run inside: keep the run.
    var m = s.match(/[0-9]{3,}/);
    if (m) return m[0].slice(0, 24);
    return null;
  },

  _applyDictatedCode(txt) {
    var v = this._parseSpokenCode(txt);
    if (v === null) {
      this.setData({
        status: '没听清成码：「' + String(txt || '(empty)').slice(0, 12) + '」— 没猜，原值不变；数字码试试逐位念',
        lastEvent: 'EVT: DICT parse FAIL - rejected, buffer unchanged'
      });
      this._renderAll();
      return false;
    }
    if (this._mode === 'confirm' && this._pending) {
      if (this._pending.text && v !== this._pending.text) this._pending.corrected = true;
      this._pending.text = v;
      this._pending.src = 'DICT';
      this._curPos = /^\d+$/.test(v) ? v.length - 1 : -1;
    } else {
      this._capText = v;
      this._capSrc = 'DICT';
      if (this._mode === 'list' || this._mode === 'show') this._mode = 'capture';
    }
    this.setData({
      status: '听写填入 ' + v + ' — 逐字核对（大小写以识别为准），对了 OK 存',
      lastEvent: 'EVT: DICT "' + String(txt).slice(0, 16) + '" -> ' + v + ' (verbatim from wearer, case kept)'
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
    if (this._mode === 'list' || this._mode === 'show') this._enterCapture();
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'DICT SKIP - 这台设备没有识别；纯数字码可步进手填，字母码只能靠识别',
        lastEvent: 'EVT: DICT SKIP (host ASR n/a) - stepper path for digit codes, nothing faked'
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
    // and it hears the WEARER repeating the code, nobody else. The
    // result lives on its own MIC CHECK line; the listening line says
    // (host ASR).
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
          self._applyDictatedCode(txt);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'DICT FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + '，再点 DICT，或逐位念',
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
        status: 'DICT listening (host ASR)... 复述你听到的码（只听你的声音）' + (this._digitMode ? ' · 逐位念' : ''),
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

  // ---------- SPEAK (on demand only - never automatic) ----------

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
    if (this._mode === 'show' && this._sel >= 0 && this._entries[this._sel]) {
      // The one place the code itself is voiced: chunk by chunk, on
      // demand, spelled out so digits are not merged into a number.
      var e = this._entries[this._sel];
      var chunks = this._chunks(e.code);
      var cur = chunks[this._chunkIdx] || '';
      text = e.label + '，第 ' + (this._chunkIdx + 1) + ' 段，共 ' + chunks.length + ' 段：' + this._spell(cur);
    } else if (this._mode === 'confirm' && this._pending && this._pending.text) {
      text = '待核对，' + this._pending.label + '：' + this._spell(this._pending.text);
    } else if (this._sel >= 0 && this._entries.length) {
      // In the list the code is NOT read aloud - label + shape only.
      var le = this._entries[this._sel];
      text = le.label + '，共 ' + this._chunks(le.code).length + ' 段。OK 打开逐段看，SPEAK 在里面才读段。';
    }
    if (!text) {
      this.setData({ lastEvent: 'EVT: SPEAK - nothing to read yet' });
      return;
    }
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: SPEAK on demand (TTS, no lang set)' });
    }
  },

  // ---------- DEMO (seeded entries + one simulated dictation, memory only) ----------

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
      this._burnSuggest = false;
      this._chunkIdx = 0;
      this._disarm();
      this.setData({
        status: 'DEMO OFF - your real codes are back (' + this._entries.length + ')',
        lastEvent: 'EVT: DEMO cleared - real store restored exactly, nothing was written'
      });
      this._renderAll();
      return;
    }
    // Seed times derive from ONE Date snapshot as pure arithmetic
    // (sibling lesson: preview host clocks drift between reads).
    var snap = new Date();
    var fmt = function (d) { return this._pad2(d.getHours()) + ':' + this._pad2(d.getMinutes()); }.bind(this);
    var t1 = new Date(snap.getTime() - 20 * 60000);
    var t2 = new Date(snap.getTime() - 6 * 60000);
    this._entries = [
      { label: 'WiFi密码', code: 'sunny4829', time: fmt(t1) },
      { label: '门锁码', code: '0508', time: fmt(t2) }
    ];
    this._sel = 0;
    // One capture is mid-flight: a simulated dictation waiting on the
    // wearer's confirm, exactly like a real DICT would land.
    this._pending = {
      label: '会议号', text: '90214478', src: 'DEMO', corrected: false
    };
    this._curPos = 7;
    this._labelIdx = 2; // 会议号
    this._mode = 'confirm';
    this.setData({
      status: 'DEMO - 模拟听写到会议号 90214478：核对后 OK 存（演示内）',
      lastEvent: 'EVT: DEMO on - 2 seeded entries + 1 simulated dictation pending (memory only)'
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
        detail: e.label + ' · 第 ' + (this._chunkIdx + 1) + '/' + this._chunks(e.code).length + ' 段 · ' + e.time + ' 存入',
        flag: 'SHOW',
        cls: 'row'
      });
    } else {
      for (i = 0; i !== this._entries.length; i++) {
        e = this._entries[i];
        rows.push({
          name: (i === this._sel ? '▸ ' : '') + e.label,
          detail: e.code + ' · ' + e.time,
          flag: i === this._sel ? 'SEL' : '',
          cls: 'row'
        });
      }
      if (!rows.length) {
        rows.push({
          name: '(no codes)',
          detail: 'DICT the code in your own voice, confirm it, it stays here - or DEMO',
          flag: '',
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    patch.countLine = 'HELD: ' + this._entries.length + '/4 · 明文存本机 · 无加密';

    if (this._mode === 'list') {
      patch.boxLabel = '◎ 已存的码 — 滑动选择，OK 打开逐段看（打开不出声）';
      if (this._sel >= 0 && this._entries[this._sel]) {
        e = this._entries[this._sel];
        patch.bigLabel = e.label + ' · ' + e.time + ' 存入 · 共 ' + this._chunks(e.code).length + ' 段';
        patch.bigCode = this._chunked(e.code);
        patch.bigNote = this._burnArmIdx === this._sel
          ? '⚠ 焚毁已武装 — 再点 BURN 真的焚'
          : 'OK 逐段看 · SPEAK 只报段数不读码 · BURN 两下焚';
      } else {
        patch.bigLabel = '（还没有存码）';
        patch.bigCode = '----';
        patch.bigNote = 'DICT 复述一个码 / LABEL 选标签 / DEMO 演示';
      }
    } else if (this._mode === 'capture') {
      patch.boxLabel = '◎ 正在记 — 标签：' + this._curLabel() + '（LABEL / 滑动切换）· 麦克风只听你复述';
      patch.bigLabel = this._curLabel() + (this._digitMode ? ' · 逐位念：开' : ' · 逐位念：关');
      patch.bigCode = this._capText ? this._chunked(this._capText) : '----';
      patch.bigNote = this._capText
        ? '复述中（' + (this._capSrc || 'MANUAL') + '）— OK 进入核对，还没存'
        : 'DICT 复述 · DIG 切逐位念 · +1/−1 步进（纯数字）';
    } else if (this._mode === 'confirm') {
      var p = this._pending;
      if (p) {
        patch.boxLabel = p.src === 'DEMO'
          ? '◎ DEMO DICT (simulated) - not a real dictation'
          : '◎ ASR 听写 — 字母/符号最容易听错，这里逐字核对';
        patch.bigLabel = p.label + (p.corrected ? ' · 已更正' : '') + ' · 待核对';
        patch.bigCode = p.text ? this._chunked(p.text) : '----';
        if (p.text && /^\d+$/.test(p.text)) {
          var pos = (this._curPos >= 0 && this._curPos < p.text.length) ? this._curPos : p.text.length - 1;
          patch.bigNote = '第 ' + (pos + 1) + ' 位 = ' + p.text.charAt(pos) + ' · 滑动移位 · +1/−1 改这位 · OK 存';
        } else {
          patch.bigNote = p.text
            ? 'Enter/OK = 确认存入 · DICT = 重念更正 · BURN = 放弃'
            : '没听清 — DICT 重念，或 BURN 放弃';
        }
      }
    } else if (this._mode === 'show') {
      if (this._sel >= 0 && this._entries[this._sel]) {
        e = this._entries[this._sel];
        var chunks = this._chunks(e.code);
        patch.boxLabel = '◎ SHOW - chunk ' + (this._chunkIdx + 1) + '/' + chunks.length + ' · ' + chunks.join(' · ');
        patch.bigLabel = e.label + ' · 第 ' + (this._chunkIdx + 1) + ' 段 / 共 ' + chunks.length + ' 段';
        patch.bigCode = chunks[this._chunkIdx] || '----';
        patch.bigNote = this._burnArmIdx === this._sel
          ? '⚠ 焚毁已武装 — 再点 BURN 真的焚'
          : this._burnSuggest
            ? '⚠ 最后一段了 — 输完 BURN 两下焚掉（不会自动焚）'
            : '滑动/Enter 下一段 · SPEAK 读这一段 · 点头 = SPEAK · LABEL 回列表';
      }
    }
    patch.bigCls = this._bigClsFor(patch.bigCode);
    this.setData(patch);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">CODE HOLD</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigCode}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{secLine}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="labelTap">LABEL</button>
      <button class="btn btn-main" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="digTap">逐位念</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="burnTap">BURN</button>
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
    <text class="foot2">明文存储无加密 · 麦克风只听你复述 · 显示默认不出声</text>
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
