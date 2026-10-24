<script def>
{
  "navigationBarTitleText": "Teleprompter Gaze"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'SCRIPT IN YOUR SIGHT - nod / tap NEXT to advance',
    steadyText: 'HEAD: moving - hold still',
    progLine: '段 1/4 · SAMPLE',
    curText: '（稿子加载中）',
    nextText: 'NEXT: -',
    scriptLine: 'SCRIPT: SAMPLE built-in - not saved as yours · no file import',
    autoLine: 'AUTO: OFF - best-effort follow, manual always works',
    micLine: 'MIC CHECK: not run',
    paceLine: 'PACE: - AUTO matches measure it (readout only)',
    timeLine: 'ELAPSED: - starts on first advance / AUTO',
    lastEvent: 'EVT: tap = advance · swipe down = next · nod = advance',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._own = this._loadOwn();      // wearer's dictated paragraphs, or null
    if (this._own && this._own.length) {
      this._paras = this._own.slice(0, 12);
      this._ownScript = true;
    } else {
      this._paras = this._sampleParas();
      this._ownScript = false;
    }
    this._idx = 0;
    this._done = false;
    this._tickCount = 0;               // 500 ms ticks, accumulated - never re-sampled Date math
    this._timer = null;
    this._beginTick = null;            // tick when this talk started
    this._endTick = null;
    this._shownKey = null;
    this._paceChars = 0;               // chars advanced by AUTO matches only
    this._paceFirstTick = null;
    this._paceLastTick = null;
    this._paceMatches = 0;
    this._auto = false;
    this._autoNote = null;             // sticky AUTO line while off (self-off reasons live here)
    this._roundActive = false;
    this._autoRound = 0;
    this._errStreak = 0;
    this._rec = null;
    this._micLabel = 'not run';
    this._demo = false;
    this._demoSaved = null;
    this._startTimer();
    this._render();
    this.setData({
      lastEvent: this._ownScript
        ? 'EVT: your saved script loaded (' + this._paras.length + ' paras, on-device)'
        : 'EVT: SAMPLE script loaded - DICT starts your own script'
    });
  },

  onShow() {
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopRec();
    this._roundActive = false;
    if (this._auto) this._auto = false; // listening never survives the page
  },

  onUnload() {
    this._stopTimer();
    this._stopRec();
    this._saveOwn();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - nod = advance' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    if (g !== 'nod') {
      this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (ignored)' });
      return;
    }
    if (this.data.busy) return;
    // A nod only advances the script, and only with a steady head
    // (same discipline as the sibling agents). It never starts AUTO,
    // never dictates, never speaks.
    if (!this._steady) {
      this.setData({
        status: 'NOD IGNORED - hold head steady first',
        lastEvent: 'EVT: nod ignored - head not steady'
      });
      return;
    }
    this._advance('nod');
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  // Touchpad gestures (dossier §3.2.1): single tap arrives as Enter,
  // double-tap as Backspace, swipe as ArrowUp/ArrowDown. The whole
  // prompting flow runs on these keys + a steady-head nod alone;
  // the six on-screen buttons mirror the same actions for tapping.
  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this._primaryTap();
    } else if (code === 'ArrowDown') {
      this.setData({ lastEvent: 'EVT: swipe down = next paragraph' });
      this._advance('swipe');
    } else if (code === 'ArrowUp') {
      this.setData({ lastEvent: 'EVT: swipe up = previous paragraph' });
      this._back('swipe');
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: double-tap (Backspace) back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // The context primary action behind a single tap (Enter):
  // AUTO on but no round running -> start a listening round;
  // finished -> speak the summary; otherwise advance one paragraph.
  _primaryTap() {
    if (this.data.busy) return;
    if (this._auto && !this._roundActive && !this._done) {
      this.setData({ lastEvent: 'EVT: tap (Enter) = start AUTO round' });
      this._autoRoundStart();
      return;
    }
    if (this._done) {
      this.setData({ lastEvent: 'EVT: tap (Enter) = speak summary' });
      this.speakTap();
      return;
    }
    this.setData({ lastEvent: 'EVT: tap (Enter) = advance' });
    this._advance('tap');
  },

  // ---------- helpers ----------

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

  // The talk clock runs on accumulated 500 ms ticks, not on repeated
  // Date samples (the preview host's clock drifts between samples -
  // same discipline as #38 / #42). Elapsed and pace both read ticks.
  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      self._tickCount++;
      self._paintTime();
    }, 500);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _begin() {
    if (this._beginTick === null) {
      this._beginTick = this._tickCount;
      this._shownKey = null;
      this._paintTime();
    }
  },

  _elapsedTicks() {
    if (this._beginTick === null) return 0;
    var end = this._done && this._endTick !== null ? this._endTick : this._tickCount;
    return Math.max(0, end - this._beginTick);
  },

  _fmtTicks(ticks) {
    var sec = Math.floor(ticks / 2);
    var m = Math.floor(sec / 60);
    var s = sec % 60;
    return m + ':' + (s < 10 ? '0' : '') + s;
  },

  _paintTime() {
    if (this._beginTick === null) return;
    var sec = Math.floor(this._elapsedTicks() / 2);
    // The repaint key includes the done flag: finishing inside the
    // same second must still flip the suffix to (final), and going
    // BACK from done must flip it back to ticking.
    var key = sec + '|' + (this._done ? 'F' : 'T');
    if (key === this._shownKey) return;
    this._shownKey = key;
    this.setData({
      timeLine: 'ELAPSED: ' + this._fmtTicks(this._elapsedTicks()) +
        (this._done ? ' (final)' : ' · ticking while you talk')
    });
  },

  // ---------- the script ----------

  _sampleParas() {
    // Built-in sample speech (labelled SAMPLE everywhere). It is a
    // stand-in so the prompter can be tried at once - it is never
    // persisted as the wearer's own script.
    return [
      '大家好，欢迎来到今天的分享会，我是林晓，先谢谢每一位到场的朋友。',
      '过去一年，我们走访了三百多位用户，大家说的是同一句话：工具应该更懂人，而不是让人去迁就工具。',
      '今天我们带来的这副智能眼镜，能听懂你说的话，能把要紧的信息放在你眼前，让你抬着头把话讲完。',
      '我的分享就到这里，谢谢大家，接下来请我的同事上台做现场演示。'
    ];
  },

  _loadOwn() {
    try {
      var raw = wx.getStorageSync('prompterScript');
      if (!raw || Object.prototype.toString.call(raw.paras) !== '[object Array]') return null;
      var out = [];
      for (var i = 0; i !== raw.paras.length && out.length < 12; i++) {
        if (typeof raw.paras[i] === 'string' && raw.paras[i]) out.push(raw.paras[i]);
      }
      return out.length ? out : null;
    } catch (e) {
      return null;
    }
  },

  _saveOwn() {
    // Only the wearer's own dictated paragraphs are persisted, as
    // TEXT. The built-in SAMPLE is never written as theirs.
    if (!this._ownScript || this._demo) return;
    try {
      wx.setStorageSync('prompterScript', { paras: this._paras.slice(0, 12), own: true });
    } catch (e) { /* storage unavailable on this host: script stays in memory */ }
  },

  // ---------- prompting flow ----------

  _advance(how) {
    if (!this._paras.length) {
      this.setData({ lastEvent: 'EVT: advance ignored - script empty' });
      return;
    }
    if (this._done) {
      this.setData({ lastEvent: 'EVT: already finished - BACK reviews, SPEAK hears the summary' });
      return;
    }
    this._begin();
    if (this._idx < this._paras.length - 1) {
      this._idx++;
      this.setData({
        status: '段 ' + (this._idx + 1) + '/' + this._paras.length + ' - keep your head up',
        lastEvent: 'EVT: advanced (' + how + ') -> 段 ' + (this._idx + 1)
      });
    } else {
      this._done = true;
      this._endTick = this._tickCount;
      if (this._auto) this._autoOff('script finished');
      this.setData({
        status: '讲完了！SPEAK = 听总结 · BACK = 回最后一段',
        lastEvent: 'EVT: finished (' + how + ') - ' + this._paras.length +
          ' paras in ' + this._fmtTicks(this._elapsedTicks())
      });
    }
    this._render();
  },

  _back(how) {
    if (this._done) {
      this._done = false;
      this._endTick = null;
      this.setData({
        status: 'BACK to the last paragraph',
        lastEvent: 'EVT: back (' + how + ') from finished -> 段 ' + this._paras.length
      });
      this._render();
      return;
    }
    if (this._idx > 0) {
      this._idx--;
      this.setData({
        status: '段 ' + (this._idx + 1) + '/' + this._paras.length,
        lastEvent: 'EVT: back (' + how + ') -> 段 ' + (this._idx + 1)
      });
      this._render();
    } else {
      this.setData({ lastEvent: 'EVT: back ignored - already at 段 1' });
    }
  },

  nextTap() { this._advance('tap'); },
  backTap() { this._back('tap'); },

  // ---------- speech out (TTS; lang is never set) ----------

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        return false;
      }
      if (!text) return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  speakTap() {
    var text, label;
    if (this._done) {
      var ticks = this._elapsedTicks();
      var sec = Math.floor(ticks / 2);
      text = '讲完了。一共 ' + this._paras.length + ' 段，用时 ' +
        Math.floor(sec / 60) + ' 分 ' + (sec % 60) + ' 秒。';
      label = 'summary';
    } else if (this._paras.length) {
      text = this._paras[this._idx];
      label = '段 ' + (this._idx + 1) + ' (practice read)';
    } else {
      text = '';
      label = 'nothing to read';
    }
    var ok = text ? this._speak(text) : false;
    this.setData({
      lastEvent: ok
        ? 'EVT: TTS sent: ' + label
        : 'EVT: SPEAK FAIL - speechSynthesis n/a on this host'
    });
  },

  // ---------- wearer mic check (availability only, never the ASR input) ----------

  // Documented pattern (dossier §2.4 / §2.8, same as the siblings):
  // open a wearer-mode stream, read its settings back, stop every
  // track - THEN the host SpeechRecognition listens on its own
  // microphone. The check result lives on its own MIC CHECK line.
  async _wearerCheck() {
    var label = 'check n/a';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      var stream = null;
      try {
        try {
          stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({
            audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
          }), 6000, 'mic');
          label = 'wearer OK';
          try {
            var tr = stream.getAudioTracks()[0];
            if (tr && tr.getSettings && tr.getSettings().microphoneMode) {
              label = 'wearer OK (' + tr.getSettings().microphoneMode + ')';
            }
          } catch (e) {}
        } catch (eMode) {
          if (!eMode || eMode.name !== 'OverconstrainedError') throw eMode;
          stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 6000, 'mic');
          label = 'default mic (wearer mode refused)';
        }
      } catch (e) {
        label = 'check FAIL - ' + this._err(e);
      }
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
    }
    this._micLabel = label;
    this.setData({ micLine: 'MIC CHECK: ' + label + ' (check only - ASR uses the host mic)' });
    return label;
  },

  // ---------- DICT: dictate one paragraph of YOUR script, verbatim ----------

  dictTap() {
    if (this.data.busy) return;
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: DICT refused in DEMO - tap DEMO again to exit first' });
      return;
    }
    if (this._auto) {
      this.setData({ lastEvent: 'EVT: DICT refused - AUTO is listening; turn AUTO off first' });
      return;
    }
    if (this._ownScript && this._paras.length >= 12) {
      this.setData({
        status: 'SCRIPT FULL - your script holds 12 paragraphs max',
        lastEvent: 'EVT: DICT refused - cap 12 reached'
      });
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      // Honest FAIL: no recogniser on this host, nothing is added
      // and nothing pretends to have listened.
      this.setData({
        status: 'DICT FAIL: SpeechRecognition n/a on this host',
        lastEvent: 'EVT: DICT unavailable (honest FAIL, nothing added)'
      });
      return;
    }
    this._dictListen();
  },

  async _dictListen() {
    var self = this;
    this.setData({ busy: true, status: 'DICT: checking wearer mic...' });
    await this._wearerCheck();
    try {
      this._stopRec();
      var rec = new SpeechRecognition();
      this._rec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (txt) self._appendDictated(txt);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'DICT FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + ', tap DICT again',
          lastEvent: 'EVT: DICT ASR error - nothing added'
        });
      };
      rec.onend = function () {
        if (self._rec === rec) self._rec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: 'DICT listening (host ASR) - speak ONE paragraph...',
        lastEvent: 'EVT: DICT listening, ' + this._micLabel
      });
    } catch (e) {
      this.setData({
        busy: false,
        status: 'DICT FAIL - ' + this._err(e),
        lastEvent: 'EVT: DICT start failed'
      });
    }
  },

  _appendDictated(txt) {
    // Your words are stored VERBATIM (trimmed only, like #21/#36/#37):
    // the prompter must show exactly what you said, never a rewrite.
    var startedOwn = false;
    if (!this._ownScript) {
      // You were viewing the built-in SAMPLE: dictating starts YOUR
      // script with this paragraph. The sample is never saved as yours.
      this._paras = [];
      this._ownScript = true;
      this._idx = 0;
      this._done = false;
      startedOwn = true;
    }
    if (this._paras.length >= 12) {
      this.setData({
        status: 'SCRIPT FULL - 12 paragraphs max, nothing added',
        lastEvent: 'EVT: dictated paragraph refused - cap 12'
      });
      return;
    }
    this._paras.push(txt);
    this._saveOwn();
    this.setData({
      status: '段 ' + this._paras.length + ' ADDED verbatim - it is in YOUR script',
      lastEvent: 'EVT: paragraph added VERBATIM (' + txt.length + ' chars)' +
        (startedOwn ? ' - your own script started (SAMPLE left behind)' : '')
    });
    this._render();
  },

// ---------- AUTO follow: best-effort LITERAL match of host ASR ----------

_norm(s) {
// Literal-match normalisation: drop whitespace and punctuation
// (ASCII + CJK). What remains is compared character for character
// - no synonyms, no semantics, no guessing.
return String(s || '').replace(/[\s，。、；：？！·…—\-「」『』“”‘’（）()\[\]《》<>,.;:?!'"~～_]/g, '');
},

// Find where the tail of what was heard lands in the current and
// next two paragraphs. The longest suffix of the heard text (at
// least 4 normalised chars, capped at 40) that appears verbatim in
// a candidate paragraph decides; the strongest match wins and ties
// go to the LATER paragraph (you have moved on). Returns
// {matched, target, charsAdvanced, matchLen} or {matched:false}.
_matchAdvance(heard) {
var H = this._norm(heard);
if (H.length < 4) return { matched: false, why: 'too short (<4 chars)'};
if (this._done ||!this._paras.length) return { matched: false, why: 'no live paragraph'};
var best = null;
var maxL = Math.min(H.length, 40);
for (var k = 0; k < 3; k++) {
var ci = this._idx + k;
if (ci >= this._paras.length) break;
var P = this._norm(this._paras[ci]);
var L = 0, pos = -1;
for (var l = maxL; l >= 4; l--) {
var p = P.indexOf(H.slice(H.length - l));
if (p >= 0) { L = l; pos = p; break;}
}
if (L >= 4 && (!best || L > best.L || (L === best.L && ci > best.i))) {
best = { i: ci, L: L, end: pos + L};
}
}
if (!best) return { matched: false, why: 'no literal match'};
var chars = 0;
if (best.i > this._idx) {
for (var j = this._idx; j < best.i; j++) chars += this._norm(this._paras[j]).length;
chars += best.end;
}
return { matched: true, target: best.i, charsAdvanced: chars, matchLen: best.L};
},

_handleHeard(txt, via) {
var r = this._matchAdvance(txt);
var tag = via === 'demo'? 'DEMO AUTO': 'AUTO';
if (!r.matched) {
this.setData({
lastEvent: 'EVT: ' + tag + ' heard "' + String(txt).slice(0, 14) +
'" - no literal match (' + r.why + ') - nod to advance'
});
return r;
}
if (r.target > this._idx) {
this._paceChars += r.charsAdvanced;
if (this._paceFirstTick === null) this._paceFirstTick = this._tickCount;
this._paceLastTick = this._tickCount;
this._paceMatches++;
this._idx = r.target;
this.setData({
status: tag + ' FOLLOWED you -> 段 ' + (this._idx + 1),
lastEvent: 'EVT: ' + tag + ' matched → 段 ' + (this._idx + 1) + ' (literal match)'
});
} else {
this.setData({
lastEvent: 'EVT: ' + tag + ' matched here - still 段 ' + (this._idx + 1) + ' (literal match)'
});
}
this._render();
return r;
},

async autoTap() {
if (this._auto) {
this._autoOff('you turned it off');
this._autoNote = 'AUTO: OFF - best-effort follow, manual always works';
this.setData({
status: 'AUTO OFF - manual advance (nod / tap / swipe) always works',
lastEvent: 'EVT: AUTO off (manual)'
});
this._render();
return;
}
if (this._done) {
this.setData({ lastEvent: 'EVT: AUTO refused - already finished; BACK to review'});
return;
}
if (!this._paras.length) {
this.setData({ lastEvent: 'EVT: AUTO refused - script empty'});
return;
}
if (typeof SpeechRecognition === 'undefined') {
// AUTO cannot exist without a recogniser: it turns itself off
// before it starts and says why. Manual flow is untouched.
this._autoNote = 'AUTO: OFF - no recogniser on this host';
this.setData({
status: 'AUTO FAIL: SpeechRecognition n/a on this host - AUTO stays OFF',
autoLine: this._autoNote,
lastEvent: 'EVT: AUTO unavailable (honest FAIL) - manual advance still works'
});
return;
}
this._auto = true;
this._autoNote = null;
this._errStreak = 0;
this._autoRound = 0;
this._begin();
this.setData({
status: 'AUTO ON - speak; I follow LITERAL matches only',
lastEvent: 'EVT: AUTO on - best-effort literal follow, not guaranteed'
});
this._render();
this._autoRoundStart();
},

_autoOff(why) {
this._auto = false;
this._roundActive = false;
this._autoNote = 'AUTO: OFF - ' + why;
this._stopRec();
this.setData({
autoLine: this._autoNote,
lastEvent: 'EVT: AUTO self-off - ' + why + ' (manual advance unaffected)'
});
},

_stopRec() {
if (this._rec) {
try { this._rec.abort();} catch (e) {}
this._rec = null;
}
},

async _autoRoundStart() {
if (!this._auto || this._roundActive || this._done) return;
this._roundActive = true;
this._autoRound++;
// Every round re-runs the wearer availability check first; its
// tracks are stopped before the recogniser starts (ordering is
// asserted in the Node harness).
await this._wearerCheck();
if (!this._auto) { this._roundActive = false; return;}
var self = this;
var rec;
try {
rec = new SpeechRecognition();
} catch (e) {
this._roundActive = false;
this._autoOff('recogniser ' + this._err(e));
this._render();
return;
}
this._rec = rec;
rec.lang = 'zh-CN';
rec.interimResults = false;
rec.onresult = function (ev) {
try {
var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
if (txt) { self._errStreak = 0; self._handleHeard(txt, 'auto');}
} catch (e) {}
};
rec.onerror = function (ev) {
var name = ev && ev.error? String(ev.error): 'error';
if (name === 'not-allowed' || name === 'service-not-allowed' || name === 'audio-capture') {
self._autoOff('ASR error: ' + name);
self._render();
return;
}
if (name!== 'no-speech' && name!== 'aborted') {
self._errStreak++;
if (self._errStreak >= 3) {
self._autoOff('ASR keeps failing: ' + name);
self._render();
}
}
};
rec.onend = function () {
if (self._rec === rec) self._rec = null;
self._roundActive = false;
if (self._auto &&!self._done) self._autoRoundStart(); // next round
};
try {
rec.start();
// The round state lives on the AUTO line; lastEvent is kept for
// the round's OUTCOME (matched / no literal match), which is
// the information the wearer actually needs.
this.setData({
autoLine: 'AUTO: ON · round ' + this._autoRound + ' · listening (host ASR)'
});
} catch (e) {
this._roundActive = false;
this._autoOff('recogniser start ' + this._err(e));
this._render();
}
},

// ---------- DEMO: sample script + one seeded AUTO match ----------

demoTap() {
if (this.data.busy) return;
if (!this._demo) {
this._demoSaved = {
paras: this._paras, ownScript: this._ownScript,
idx: this._idx, done: this._done,
beginTick: this._beginTick, endTick: this._endTick,
paceChars: this._paceChars, paceFirstTick: this._paceFirstTick,
paceLastTick: this._paceLastTick, paceMatches: this._paceMatches
};
if (this._auto) this._autoOff('DEMO took over');
this._demo = true;
this._paras = this._sampleParas();
this._ownScript = false;
this._idx = 0;
this._done = false;
this._beginTick = null;
this._endTick = null;
this._paceChars = 0;
this._paceFirstTick = null;
this._paceLastTick = null;
this._paceMatches = 0;
this._begin();
this.setData({
status: 'DEMO - SAMPLE script; a seeded line will AUTO-follow to 段 3',
lastEvent: 'EVT: DEMO on - sample loaded (memory only, nothing saved)'
});
this._render();
// One seeded recognition line: a verbatim chunk of paragraph 3,
// fed through the REAL matching path, labelled DEMO.
this._handleHeard('能把要紧的信息放在你眼前', 'demo');
return;
}
// Leaving DEMO restores the wearer's real script untouched.
var s = this._demoSaved || {};
this._demo = false;
this._demoSaved = null;
this._paras = s.paras || this._sampleParas();
this._ownScript =!!s.ownScript;
this._idx = s.idx || 0;
this._done =!!s.done;
this._beginTick = (s.beginTick === undefined? null: s.beginTick);
this._endTick = (s.endTick === undefined? null: s.endTick);
this._paceChars = s.paceChars || 0;
this._paceFirstTick = (s.paceFirstTick === undefined? null: s.paceFirstTick);
this._paceLastTick = (s.paceLastTick === undefined? null: s.paceLastTick);
this._paceMatches = s.paceMatches || 0;
this.setData({
status: 'DEMO OFF - your real script is back',
lastEvent: 'EVT: DEMO off - real script restored, nothing was written'
});
this._render();
},

// ---------- rendering ----------

_paceText() {
if (!this._paceMatches || this._paceFirstTick === null) {
return 'PACE: - AUTO matches measure it (readout only)';
}
var elapsed = (this._paceLastTick - this._paceFirstTick) * 0.5; // seconds
if (elapsed <= 0 ||!this._paceChars) {
return 'PACE: measuring... (' + this._paceMatches + ' match(es) so far, readout only)';
}
var perMin = Math.round(this._paceChars / (elapsed / 60));
return 'PACE: ≈ ' + perMin + ' 字/分 (from ' + this._paceMatches +
' matches · readout only)';
},

_render() {
var n = this._paras.length;
var patch = {};
if (this._done) {
patch.progLine = '讲完了 · ' + n + ' 段 · ' + (this._ownScript? 'YOUR SCRIPT': 'SAMPLE');
patch.curText = '讲完了 — THE END';
patch.nextText = 'SPEAK = 听总结 · BACK = 回最后一段';
} else if (n) {
patch.progLine = '段 ' + (this._idx + 1) + '/' + n + ' · ' +
(this._ownScript? 'YOUR SCRIPT': 'SAMPLE') + (this._demo? ' · DEMO': '');
patch.curText = this._paras[this._idx];
patch.nextText = this._idx + 1 < n
? 'NEXT ▸ ' + this._paras[this._idx + 1]
: '（这是最后一段 - NEXT 后讲完）';
} else {
patch.progLine = '段 0/0';
patch.curText = '（稿子是空的 - DICT 口述第一段）';
patch.nextText = 'NEXT: -';
}
patch.scriptLine = this._ownScript
? 'SCRIPT: ' + n + ' paras · YOURS, saved on device (key prompterScript)'
: 'SCRIPT: ' + n + ' paras · SAMPLE built-in - not saved as yours · no file import';
patch.autoLine = this._auto
? 'AUTO: ON · round ' + this._autoRound + ' · literal follow (best-effort)'
: (this._autoNote || 'AUTO: OFF - best-effort follow, manual always works');
patch.paceLine = this._paceText();
patch.micLine = 'MIC CHECK: ' + this._micLabel +
(this._micLabel === 'not run'? '': ' (check only - ASR uses the host mic)');
this.setData(patch);
this._paintTime();
}
};
</script>

<page>
<view class="page">
<view class="head">
<text class="title">TELEPROMPTER</text>
<text class="status">{{status}}</text>
<text class="sub">{{steadyText}} · {{progLine}}</text>
</view>
<view class="cur-box">
<text class="box-label">◎ NOW - read THIS paragraph</text>
<text class="cur">{{curText}}</text>
<text class="next">{{nextText}}</text>
</view>
<view class="info-box">
<text class="info">{{scriptLine}}</text>
<text class="info">{{autoLine}}</text>
<text class="info">{{micLine}}</text>
<text class="info">{{paceLine}}</text>
<text class="info">{{timeLine}}</text>
</view>
<view class="actions">
<button class="btn btn-main" bindtap="nextTap">NEXT</button>
<button class="btn" bindtap="backTap">BACK</button>
<button class="btn" bindtap="autoTap">AUTO</button>
</view>
<view class="actions">
<button class="btn" bindtap="dictTap">DICT</button>
<button class="btn" bindtap="speakTap">SPEAK</button>
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
padding: 6px 14px;
background-color: #000000;
}
.head {
display: flex;
flex-direction: column;
margin-bottom: 4px;
}
.title {
color: #40ff5e;
font-size: 21px;
font-weight: 500;
line-height: 24px;
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
.cur-box {
display: flex;
flex-direction: column;
border: 1px solid rgba(64,255,94,0.72);
border-radius: 6px;
padding: 6px 10px;
margin-bottom: 5px;
}
.box-label {
color: rgba(64,255,94,0.48);
font-size: 10px;
line-height: 13px;
}
.cur {
color: #40ff5e;
font-size: 17px;
line-height: 22px;
margin-top: 3px;
}
.next {
color: rgba(64,255,94,0.48);
font-size: 11px;
line-height: 15px;
margin-top: 4px;
}
.info-box {
display: flex;
flex-direction: column;
border: 1px solid rgba(64,255,94,0.24);
border-radius: 6px;
padding: 5px 10px;
margin-bottom: 5px;
}
.info {
color: rgba(64,255,94,0.48);
font-family: monospace;
font-size: 10px;
line-height: 14px;
}
.actions {
display: flex;
flex-direction: row;
gap: 8px;
margin-bottom: 4px;
}
.btn {
flex-grow: 1;
color: rgba(64,255,94,0.72);
border: 1px solid rgba(64,255,94,0.48);
border-radius: 4px;
padding: 4px;
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
.foot {
color: rgba(64,255,94,0.72);
font-family: monospace;
font-size: 10px;
line-height: 13px;
margin-top: 2px;
}
</style>
