<script def>
{
  "navigationBarTitleText": "Meeting Filter"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '会议过滤 — 先定名字+议题关键词，守听时只有命中才亮，未命中只计不打断',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — KW 换关键词组，MODE 换收音模式，START 开始守听',
    bigLabel: '会议过滤 · 待机',
    bigText: '王磊·预算·上线',
    bigNote: '收音 far-field · START 开始 · DEMO 走演示',
    permLine: 'PERM: RECORD_AUDIO — far-field/omnidirectional 收音流 + 宿主 ASR 转写做关键词匹配；模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音',
    rows: [],
    countLine: '已听 0 段 · 命中 0 次 · 缓冲仅约10秒、未命中即丢弃 · 只存本次会议内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - set keywords with KW and mode with MODE, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | summary
    this._kwIdx = 0;
    this._kwSets = [
      ['王磊', '预算', '上线'],
      ['李娜', '招聘', '排期'],
      ['张伟', '发布', '复盘']
    ];
    this._micIdx = 0;
    this._mics = ['far-field', 'omnidirectional'];
    this._buffer = []; // { text, at } — rolling ~10 s transcript window, non-hits discarded on expiry
    this._heard = 0; // segments heard (hit or not)
    this._hits = []; // { keyword, context, label }
    this._banner = ''; // current hit keyword, '' = none
    this._bannerContext = '';
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
    // Session-only by construction: keywords stay as settings,
    // but the buffer, heard count, hits, banner and summary die
    // with the page. Nothing was ever written to any storage, so
    // there is nothing to clean up - that IS the design. Close
    // the agent and the meeting is gone; the next meeting starts
    // from a blank buffer.
    try { if (this._stream) this._stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {}
    try { if (this._recog) this._recog.stop(); } catch (e) {}
    this._stream = null;
    this._recog = null;
    this._buffer = [];
    this._heard = 0;
    this._hits = [];
    this._banner = '';
    this._bannerContext = '';
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

  _keywords() { return this._kwSets[this._kwIdx]; },

  _kwText() { return this._keywords().join('·'); },

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
    // TTS via the host voice. The utterance lang is never set:
    // the documented behaviour is that it does not take effect.
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
    // summary screen. In live listening a nod is ignored on
    // purpose: starting or stopping the gate must be a
    // deliberate tap, never an accidental nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored - nod never starts or stops listening mid-meeting' });
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
    this._buffer = [];
    this._heard = 0;
    this._hits = [];
    this._banner = '';
    this._bannerContext = '';
    this._summary = null;
    this._focus = 0;
    this._startAt = this._now();
    this._startListening();
    this.setData({
      status: '守听进行中 — 只有命中名字/关键词才亮，未命中只计不打断',
      lastEvent: 'EVT: listening started (keywords ' + this._kwText() + ', mic ' + this._mic() + ')'
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
      hits: this._hits.length,
      hitText: this._hits.length ? this._hits.map(function (h) { return h.keyword + '（' + h.label + '）'; }).join('；') : '无命中'
    };
    this.setData({
      status: '会议小结 — 确认后清空本次记录',
      lastEvent: 'EVT: listening ended - summary ready (heard ' + this._summary.heard + ', hits ' + this._summary.hits + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._buffer = [];
    this._heard = 0;
    this._hits = [];
    this._banner = '';
    this._bannerContext = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this.setData({
      status: '会议过滤 — 先定名字+议题关键词，守听时只有命中才亮，未命中只计不打断',
      lastEvent: 'EVT: summary confirmed - meeting data cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to live listening without
      // deleting anything; the summary is rebuilt on END. The
      // listening stream stays stopped while the summary is
      // open, and restarts on the next START.
      this._mode = 'listening';
      this._summary = null;
      this.setData({
        status: '守听进行中 — 只有命中名字/关键词才亮，未命中只计不打断',
        lastEvent: 'EVT: back to live listening - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - END finishes listening, DEL clears a banner' });
  },

  nextTap() {
    if (this._hits.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - hit list is empty' });
      return;
    }
    this._focus = (this._focus + 1) % this._hits.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> hit ' + (this._focus + 1) });
  },

  prevTap() {
    if (this._hits.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - hit list is empty' });
      return;
    }
    this._focus = (this._focus - 1 + this._hits.length) % this._hits.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> hit ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._hits.length) return;
    this._focus = idx;
    var h = this._hits[idx];
    this.setData({ lastEvent: 'EVT: 命中' + (idx + 1) + ' - ' + h.keyword + ' · 前10秒：' + h.context });
    this._renderAll();
  },

  // ---------- keywords & mic mode (idle-only) ----------

  kwTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: KW refused - keywords are set before listening, never mid-meeting' });
      return;
    }
    this._kwIdx = (this._kwIdx + 1) % this._kwSets.length;
    this.setData({ lastEvent: 'EVT: keywords set to ' + this._kwText() + ' (DEMO sample set)' });
    this._renderAll();
  },

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - mic mode is set before listening, never mid-meeting' });
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
      // hit list or ends the listening.
      this._banner = '';
      this._bannerContext = '';
      this.setData({ lastEvent: 'EVT: banner cleared - listening and hit list kept' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEL ignored - nothing to clear here' });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '会议过滤待机，关键词 ' + this._kwText() + '，收音模式 ' + this._mic();
    } else if (this._mode === 'listening') {
      if (this._banner) {
        line = '命中：' + this._banner + '，请看前十秒回放';
      } else {
        line = '守听进行中，已听 ' + this._heard + ' 段，命中 ' + this._hits.length + ' 次';
      }
    } else if (this._summary) {
      line = '会议小结：已听 ' + this._summary.heard + ' 段，命中 ' + this._summary.hits + ' 次，' + this._summary.hitText;
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- real listening path (guarded, soft-fails on the preview host) ----------

  _startListening() {
    // Real-device path: a mode-selected getUserMedia audio
    // stream (far-field for a meeting room, omnidirectional for
    // a round table) plus host SpeechRecognition ASR whose final
    // results feed _onTranscript. On the preview host both fail
    // by design and the session still works through DEMO.
    // Honesty note, stated in the UI and README: the mic mode
    // governs the getUserMedia stream's pickup only; host ASR
    // uses the host mic and is NOT steered by the mode.
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
  // real or DEMO: hit -> banner + exactly one TTS + context
  // kept; non-hit -> counters only, no banner, no TTS. The
  // rolling buffer keeps only segments from the last ~10 s:
  // anything older is dropped before the match is tested, so
  // the context shown on a hit is genuinely the pre-hit 10 s.
  _onTranscript(text, atMs) {
    if (this._mode !== 'listening') return;
    var t = String(text || '').trim();
    if (!t) {
      this.setData({ lastEvent: 'EVT: empty transcript ignored - not counted' });
      return;
    }
    var now = (typeof atMs === 'number') ? atMs : this._now();
    this._buffer.push({ text: t, at: now });
    this._buffer = this._buffer.filter(function (s) { return now - s.at <= 10000; });
    this._heard++;
    var nText = this._norm(t);
    var hitKw = '';
    var kws = this._keywords();
    for (var i = 0; i < kws.length; i++) {
      if (nText.indexOf(this._norm(kws[i])) !== -1) { hitKw = kws[i]; break; }
    }
    if (!hitKw) {
      this.setData({
        status: '守听进行中 — 只有命中名字/关键词才亮，未命中只计不打断',
        lastEvent: 'EVT: heard (no hit) - counted silently, buffer pruned to ~10 s'
      });
      this._renderAll();
      return;
    }
    var context = this._buffer.map(function (s) { return s.text; }).join(' / ');
    this._hits.push({ keyword: hitKw, context: context, label: this._elapsedText() });
    this._focus = this._hits.length - 1;
    this._banner = hitKw;
    this._bannerContext = context;
    var phrase = '命中：' + hitKw + '，请看前十秒回放';
    this._speakText(phrase);
    this.setData({
      status: '命中 — 只有命中名字/关键词才亮',
      lastEvent: 'EVT: HIT (' + hitKw + ') - banner + one TTS + pre-10 s context'
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
      this._kwIdx = 0;
      this._micIdx = 0;
      this._buffer = [];
      this._heard = 0;
      this._hits = [];
      this._banner = '';
      this._bannerContext = '';
      this._summary = null;
      this._focus = 0;
      this._startAt = this._now();
      this._demoBase = this._now();
      this.setData({
        status: 'DEMO - 守听进行中（示例字幕，非真实转写）',
        lastEvent: 'EVT: DEMO stage 1 - listening started (keywords 王磊·预算·上线， mic far-field, DEMO sample set)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onTranscript('茶水间新换了咖啡机，大家下班可以去试试', this._demoBase + 0);
      this._onTranscript('下午三点行政会发新的门禁卡', this._demoBase + 3000);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 2 non-hit segments counted silently, no banner, no TTS' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onTranscript('预算这块王磊说下周要重新核一遍', this._demoBase + 6000);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - HIT (王磊） banner + one TTS + pre-10 s context' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._stopListening();
      this._mode = 'summary';
      this._summary = {
        heard: this._heard,
        hits: this._hits.length,
        hitText: this._hits.length ? this._hits.map(function (h) { return h.keyword + '（' + h.label + '）'; }).join('；') : '无命中'
      };
      this.setData({
        status: 'DEMO - 会议小结（示例数据）',
        lastEvent: 'EVT: DEMO stage 4 - summary (heard 3, hits 1, keyword 王磊）'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._hits.length; i++) {
      var h = this._hits[i];
      rows.push({
        idx: i,
        name: '命中' + (i + 1) + ' · ' + h.keyword + '（' + h.label + '）',
        detail: '前10秒：' + h.context,
        flag: '!',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已听 ' + this._heard + ' 段 · 命中 ' + this._hits.length + ' 次' +
      ' · 缓冲仅约10秒、未命中即丢弃 · 只存本次会议内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — KW 换关键词组，MODE 换收音模式，START 开始守听';
      patch.bigLabel = '会议过滤 · 待机';
      patch.bigText = this._kwText();
      patch.bigNote = '收音 ' + this._mic() + ' · START 开始 · DEMO 走演示';
    } else if (this._mode === 'listening') {
      if (this._banner) {
        patch.boxLabel = '◎ 命中 — 只有命中名字/关键词才亮';
        patch.bigLabel = '命中！';
        patch.bigText = this._banner;
        patch.bigNote = '前10秒回放：' + this._bannerContext + ' · DEL 只清横幅，不动命中列表';
      } else {
        patch.boxLabel = '◎ 守听进行中 — 只有命中名字/关键词才亮，未命中只计不打断';
        patch.bigLabel = '守听进行中';
        patch.bigText = '已听 ' + this._heard + ' 段';
        patch.bigNote = '关键词：' + this._kwText() + ' · 收音 ' + this._mic() + ' · 未命中只计不亮';
      }
    } else {
      patch.boxLabel = '◎ 会议小结';
      patch.bigLabel = '会议小结';
      var s = this._summary || { heard: 0, hits: 0, hitText: '无命中' };
      patch.bigText = '命中 ' + s.hits + ' 次 · 已听 ' + s.heard + ' 段';
      patch.bigNote = '命中：' + s.hitText + ' · 确认后清空本次记录';
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
      <text class="title">MEETING FILTER v1.0.0</text>
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
      <button class="btn" bindtap="kwTap">KW</button>
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
    <text class="foot2">没有说话人识别：命中只对 ASR 转写文本做关键词匹配，听错就可能漏报/误报 · 滚动缓冲只保留约 10 秒，未命中即丢弃，不做全程录音存档 · 本次会议数据只存会话内存，关掉即清 · 模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音 · 没有室内定位、无全程纪要</text>
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
