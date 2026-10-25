<script def>
{
  "navigationBarTitleText": "Lecture Filter"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '课堂过滤 — 先定信号词，守听时只有命中信号词的句子才亮并记入笔记，未命中只计不存',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — SIG 换信号词组，MODE 换收音模式，START 开始守听',
    bigLabel: '课堂过滤 · 待机',
    bigText: '重点·考试·作业',
    bigNote: '收音 far-field · START 开始 · DEMO 走演示',
    permLine: 'PERM: RECORD_AUDIO — far-field/omnidirectional 收音流 + 宿主 ASR 转写做信号词匹配；模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音',
    rows: [],
    countLine: '已听 0 段 · 记笔记 0 条 · 未命中即丢弃、不存全文 · 只存本课内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - set signal words with SIG and mode with MODE, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | summary
    this._sigIdx = 0;
    this._sigSets = [
      ['重点', '考试', '作业'],
      ['截止日', '必考', '复习'],
      ['重点', '考试', '作业', '截止日', '必考', '复习']
    ];
    this._micIdx = 0;
    this._mics = ['far-field', 'omnidirectional'];
    this._heard = 0; // segments heard (hit or not)
    this._notes = []; // { keyword, sentence, label } — ONLY hit sentences are ever stored
    this._banner = ''; // current hit keyword, '' = none
    this._bannerSentence = '';
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 listening, 2 non-hit counted, 3 hit, 4 summary
    this._demoBase = 0;
    this._summary = null;
    this._nodLock = false;
    this._startAt = 0;
    this._stream = null;
    this._recog = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the signal-word settings
    // stay, but the heard count, notes, banner and summary die
    // with the page. Nothing was ever written to any storage,
    // so there is nothing to clean up - that IS the design.
    // Close the agent and the lesson is gone; the next lesson
    // starts from a blank notebook.
    try { if (this._stream) this._stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {}
    try { if (this._recog) this._recog.stop(); } catch (e) {}
    this._stream = null;
    this._recog = null;
    this._heard = 0;
    this._notes = [];
    this._banner = '';
    this._bannerSentence = '';
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

  _signals() { return this._sigSets[this._sigIdx]; },

  _sigText() { return this._signals().join('·'); },

  _mic() { return this._mics[this._micIdx]; },

  _norm(s) {
    return String(s || '').toLowerCase().replace(/[\s\-]/g, '');
  },

  _elapsedText() {
    if (!this._startAt) return '第0分钟';
    var m = Math.floor((this._now() - this._startAt) / 60000);
    return '第' + (m + 1) + '分钟';
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
    // Nod discipline in THIS agent: a steady nod confirms only
    // where confirmation is safe - START in idle, CONFIRM on the
    // summary screen. In live listening a steady nod is ignored
    // on purpose: starting or stopping the gate must be a
    // deliberate tap, never an accidental nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored - nod never starts or stops listening mid-lesson' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'listening') this.endTap();
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

  // ---------- listening control ----------

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already listening or a summary is open' });
      return;
    }
    this._mode = 'listening';
    this._heard = 0;
    this._notes = [];
    this._banner = '';
    this._bannerSentence = '';
    this._summary = null;
    this._focus = 0;
    this._startAt = this._now();
    this._startListening();
    this.setData({
      status: '守听进行中 — 只有命中信号词的句子才亮并记入笔记，未命中只计不存',
      lastEvent: 'EVT: listening started (signals ' + this._sigText() + ', mic ' + this._mic() + ')'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: END refused - no live listening' });
      return;
    }
    this._stopListening();
    this._mode = 'summary';
    this._summary = {
      heard: this._heard,
      hits: this._notes.length,
      noteText: this._notes.length ? this._notes.map(function (n) { return n.keyword + '（' + n.label + '）'; }).join('；') : '无笔记'
    };
    this.setData({
      status: '本课小结 — 确认后清空本次笔记',
      lastEvent: 'EVT: listening ended - summary ready (heard ' + this._summary.heard + ', notes ' + this._summary.hits + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._heard = 0;
    this._notes = [];
    this._banner = '';
    this._bannerSentence = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this.setData({
      status: '课堂过滤 — 先定信号词，守听时只有命中信号词的句子才亮并记入笔记，未命中只计不存',
      lastEvent: 'EVT: summary confirmed - lesson notes cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to live listening without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'listening';
      this._summary = null;
      this.setData({
        status: '守听进行中 — 只有命中信号词的句子才亮并记入笔记，未命中只计不存',
        lastEvent: 'EVT: back to live listening - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - END finishes listening, DEL clears a banner' });
  },

  nextTap() {
    if (this._notes.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - note list is empty' });
      return;
    }
    this._focus = (this._focus + 1) % this._notes.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> note ' + (this._focus + 1) });
  },

  prevTap() {
    if (this._notes.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - note list is empty' });
      return;
    }
    this._focus = (this._focus - 1 + this._notes.length) % this._notes.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> note ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._notes.length) return;
    this._focus = idx;
    var n = this._notes[idx];
    this.setData({ lastEvent: 'EVT: 笔记' + (idx + 1) + ' - ' + n.keyword + ' · ' + n.sentence });
    this._renderAll();
  },

  // ---------- signal words & mic mode (idle-only) ----------

  sigTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: SIG refused - signal words are set before listening, never mid-lesson' });
      return;
    }
    this._sigIdx = (this._sigIdx + 1) % this._sigSets.length;
    this.setData({ lastEvent: 'EVT: signal words set to ' + this._sigText() + ' (DEMO sample set)' });
    this._renderAll();
  },

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - mic mode is set before listening, never mid-lesson' });
      return;
    }
    this._micIdx = (this._micIdx + 1) % this._mics.length;
    this.setData({ lastEvent: 'EVT: mic mode set to ' + this._mic() + ' (getUserMedia stream pickup only; host ASR pickup is unaffected)' });
    this._renderAll();
  },

  delTap() {
    if (this._mode === 'listening') {
      if (!this._banner) {
        this.setData({ lastEvent: 'EVT: DEL ignored - nothing to clear here' });
        return;
      }
      // DEL only clears the hit banner - it never deletes the
      // note list or ends the listening.
      this._banner = '';
      this._bannerSentence = '';
      this.setData({ lastEvent: 'EVT: banner cleared - listening and note list kept' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEL ignored - nothing to clear here' });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '课堂过滤待机，信号词 ' + this._sigText() + '，收音模式 ' + this._mic();
    } else if (this._mode === 'listening') {
      if (this._banner) {
        line = '命中：' + this._banner + '，已记入本课笔记';
      } else {
        line = '守听进行中，已听 ' + this._heard + ' 段，记了 ' + this._notes.length + ' 条笔记';
      }
    } else if (this._summary) {
      line = '本课小结：已听 ' + this._summary.heard + ' 段，记了 ' + this._summary.hits + ' 条笔记，' + this._summary.noteText;
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- real listening path (guarded, soft-fails on the preview host) ----------

  _startListening() {
    // Real-device path: a mode-selected getUserMedia audio
    // stream (far-field for a lecture hall, omnidirectional
    // for a round table) plus host SpeechRecognition ASR whose
    // final results feed _onTranscript. On the preview host
    // both fail by design and the session still works through
    // DEMO. Honesty note, stated in the UI and README: the mic
    // mode governs the getUserMedia stream's pickup only; host
    // ASR uses the host mic and is NOT steered by the mode.
    var self = this;
    try {
      if (typeof navigator !== 'undefined' && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: { microphoneMode: this._mic() } }).then(function (stream) {
          self._stream = stream;
        }).catch(function (e) {
          self.setData({ lastEvent: 'EVT: mic stream unavailable here - ' + self._err(e) });
        });
      }
    } catch (e) {}
    try {
      var SR = (typeof window !== 'undefined' && (window.SpeechRecognition || window.webkitSpeechRecognition)) || null;
      if (SR) {
        var recog = new SR();
        recog.continuous = true;
        recog.interimResults = false;
        recog.onresult = function (event) {
          try {
            var res = event.results[event.results.length - 1];
            if (res && res.isFinal) self._onTranscript(res[0].transcript || '');
          } catch (e) {}
        };
        recog.onerror = function () {};
        recog.start();
        this._recog = recog;
      }
    } catch (e) {}
  },

  _stopListening() {
    try { if (this._stream) this._stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {}
    try { if (this._recog) this._recog.stop(); } catch (e) {}
    this._stream = null;
    this._recog = null;
  },

  // The single decision point for every transcript segment,
  // real or DEMO: hit -> banner + exactly one TTS + the
  // sentence stored as a lesson note; non-hit -> counter only,
  // the sentence is discarded immediately and never stored.
  // There is deliberately NO rolling transcript buffer here:
  // FI04 keeps ~10 seconds of context for replay, but a lesson
  // note needs only the signal sentence itself, and keeping a
  // buffer would mean keeping non-hit speech around.
  _onTranscript(text) {
    if (this._mode !== 'listening') return;
    var t = String(text || '').trim();
    if (!t) {
      this.setData({ lastEvent: 'EVT: empty transcript ignored - not counted' });
      return;
    }
    this._heard++;
    var nText = this._norm(t);
    var hitKw = '';
    var sigs = this._signals();
    for (var i = 0; i < sigs.length; i++) {
      if (nText.indexOf(this._norm(sigs[i])) !== -1) { hitKw = sigs[i]; break; }
    }
    if (!hitKw) {
      this.setData({
        status: '守听进行中 — 只有命中信号词的句子才亮并记入笔记，未命中只计不存',
        lastEvent: 'EVT: heard (no hit) - counted silently, sentence discarded, nothing stored'
      });
      this._renderAll();
      return;
    }
    this._notes.push({ keyword: hitKw, sentence: t, label: this._elapsedText() });
    this._focus = this._notes.length - 1;
    this._banner = hitKw;
    this._bannerSentence = t;
    var phrase = '命中：' + hitKw + '，已记入本课笔记';
    this._speakText(phrase);
    this.setData({
      status: '命中 — 只有命中信号词的句子才亮并记入笔记',
      lastEvent: 'EVT: HIT (' + hitKw + ') - banner + one TTS + sentence stored as note'
    });
    this._renderAll();
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode === 'listening' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user listening session is running' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._mode = 'listening';
      this._sigIdx = 0;
      this._micIdx = 0;
      this._heard = 0;
      this._notes = [];
      this._banner = '';
      this._bannerSentence = '';
      this._summary = null;
      this._focus = 0;
      this._startAt = this._now();
      this._demoBase = this._now();
      this.setData({
        status: 'DEMO - 守听进行中（示例字幕，非真实转写）',
        lastEvent: 'EVT: DEMO stage 1 - listening started (signals 重点·考试·作业， mic far-field, DEMO sample set)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onTranscript('今天天气不错，大家注意防晒');
      this._onTranscript('下课后图书馆二楼有社团招新');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 2 non-hit segments counted silently, sentences discarded, no banner, no TTS' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onTranscript('这道题是考试重点，下周复习要看');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - HIT (重点） banner + one TTS + sentence stored as note' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._stopListening();
      this._mode = 'summary';
      this._summary = {
        heard: this._heard,
        hits: this._notes.length,
        noteText: this._notes.length ? this._notes.map(function (n) { return n.keyword + '（' + n.label + '）'; }).join('；') : '无笔记'
      };
      this.setData({
        status: 'DEMO - 本课小结（示例数据）',
        lastEvent: 'EVT: DEMO stage 4 - summary (heard 3, notes 1, keyword 重点）'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._notes.length; i++) {
      var n = this._notes[i];
      rows.push({
        idx: i,
        name: '笔记' + (i + 1) + ' · ' + n.keyword + '（' + n.label + '）',
        detail: n.sentence,
        flag: '!',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已听 ' + this._heard + ' 段 · 记笔记 ' + this._notes.length + ' 条' +
      ' · 未命中即丢弃、不存全文 · 只存本课内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — SIG 换信号词组，MODE 换收音模式，START 开始守听';
      patch.bigLabel = '课堂过滤 · 待机';
      patch.bigText = this._sigText();
      patch.bigNote = '收音 ' + this._mic() + ' · START 开始 · DEMO 走演示';
    } else if (this._mode === 'listening') {
      if (this._banner) {
        patch.boxLabel = '◎ 命中 — 只有命中信号词的句子才亮并记入笔记';
        patch.bigLabel = '命中！已记入笔记';
        patch.bigText = this._banner;
        patch.bigNote = '信号句：' + this._bannerSentence + ' · DEL 只清横幅，不动笔记列表';
      } else {
        patch.boxLabel = '◎ 守听进行中 — 只有命中信号词的句子才亮并记入笔记，未命中只计不存';
        patch.bigLabel = '守听进行中';
        patch.bigText = '已听 ' + this._heard + ' 段';
        patch.bigNote = '信号词：' + this._sigText() + ' · 收音 ' + this._mic() + ' · 未命中只计不存';
      }
    } else {
      patch.boxLabel = '◎ 本课小结';
      patch.bigLabel = '本课小结';
      var s = this._summary || { heard: 0, hits: 0, noteText: '无笔记' };
      patch.bigText = '笔记 ' + s.hits + ' 条 · 已听 ' + s.heard + ' 段';
      patch.bigNote = '笔记：' + s.noteText + ' · 确认后清空本次记录';
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
      <text class="title">LECTURE FILTER v1.0.0</text>
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
      <button class="btn" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="sigTap">SIG</button>
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
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
    <text class="foot2">没有说话人识别：命中只对 ASR 转写文本做信号词匹配，听错就可能漏报/误报 · 只存命中信号句，未命中句子立即丢弃，不存全文、不做全程录音 · 本课数据只存会话内存，关掉即清 · 模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音 · 没有室内定位、无板书拍照</text>
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
