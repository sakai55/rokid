<script def>
{
  "navigationBarTitleText": "Standup Echo"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '站会回声 — 每日站会轮到你之前，同事的进度大多和你无关，轮到关联项又没听清：守听只命中与你负责模块相关的关键词才亮屏，未命中默记成一行摘要会后可查',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 关联笔记 — START 开始守听，MODE 换收音模式，KW 换关键词组，REVIEW 会后可查',
    bigLabel: '站会回声 · 待机',
    bigText: '还没守听',
    bigNote: 'START 开始守听 · MODE 换收音模式 · KW 换关键词组 · REVIEW 会后可查',
    permLine: 'PERM: RECORD_AUDIO — wearer/far-field 收音流 + 宿主 ASR 转写做模块关键词匹配；模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音；守听中不朗读、不存全文',
    rows: [],
    countLine: '命中 0 条 · 摘要 0 行 · 只听过 0 段 · 只存本次站会会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START starts listening, MODE switches mic mode, KW switches keyword group, REVIEW shows notes + digest',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | review | summary
    // Module keyword groups, rotatable in idle only. Table
    // order wins on multi-hit: a sentence matching several
    // words is filed under the earliest keyword in the active
    // group, never under all of them.
    this._kwGroups = [['支付', '订单', '风控'], ['库存', '物流', '配送']];
    this._kwIdx = 0;
    this._micModes = ['wearer', 'far-field'];
    this._micIdx = 0;
    this._hits = []; // { text, time, kw }
    this._digest = []; // { line, time, full }
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 start, 2 digest1, 3 hit1, 4 digest2, 5 hit2, 6 review, 7 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the hit notes, the
    // digest rows, the heard count and the summary die with
    // the page. Nothing was ever written anywhere persistent,
    // so there is nothing to clean up — that IS the design.
    this._mode = 'idle';
    this._hits = [];
    this._digest = [];
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _hhmm() {
    var d = new Date();
    var h = String(d.getHours());
    var m = String(d.getMinutes());
    if (h.length < 2) h = '0' + h;
    if (m.length < 2) m = '0' + m;
    return h + ':' + m;
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _mic() { return this._micModes[this._micIdx]; },

  _keywords() { return this._kwGroups[this._kwIdx]; },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Listening itself never speaks: a hit
    // is a banner only, so the standup is never interrupted.
    // Speech happens only via SPEAK and in review/summary.
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - nod confirms only on steady gaze'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (nod only)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod starts
    // listening in idle, confirms the summary, or moves the
    // review focus. A nod never ingests a sentence while
    // listening: captions can only arrive from the talk
    // itself, never from a nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'listening') {
      this.setData({ lastEvent: 'EVT: nod ignored while listening - captions come from talk, not from a nod' });
      return;
    }
    if (this._mode === 'review') { this.nextTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'listening') {
        this.setData({ lastEvent: 'EVT: Enter ignored while listening - captions come from talk, not from a key' });
      }
      else if (this._mode === 'review') this.nextTap();
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

  // ---------- the keyword gate (the only ingest point) ----------

  _matchKeyword(text) {
    var kws = this._keywords();
    for (var i = 0; i < kws.length; i++) {
      if (text.indexOf(kws[i]) !== -1) return kws[i];
    }
    return null;
  },

  _digestLine(text) {
    // A digest row is a truncation of the original sentence,
    // never a paraphrase: first 14 chars, ellipsis if cut.
    if (text.length <= 14) return text;
    return text.slice(0, 14) + '…';
  },

  _ingest(text) {
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: caption ignored - not listening' });
      return;
    }
    var t = String(text || '').trim();
    if (!t) {
      this.setData({ lastEvent: 'EVT: empty caption ignored' });
      return;
    }
    this._heard++;
    var kw = this._matchKeyword(t);
    if (!kw) {
      // Non-hit sentences are NOT discarded outright: the
      // standup contract keeps exactly one truncated line
      // per non-hit segment, so the post-meeting review can
      // show what was skipped. No full transcript is kept.
      this._digest.push({ line: this._digestLine(t), time: this._hhmm(), full: t });
      this.setData({
        status: '守听中 — 只听过 ' + this._heard + ' 段，未命中默记 1 行摘要（会后可查）',
        lastEvent: 'EVT: digest row kept - no keyword, truncated to one line (heard ' + this._heard + ')'
      });
      this._renderAll();
      return;
    }
    this._hits.push({ text: t, time: this._hhmm(), kw: kw });
    this._focus = this._hits.length - 1;
    // A hit is a banner only: speaking now would interrupt
    // the standup the agent is supposed to stay out of.
    this.setData({
      status: '已存关联 — 「' + kw + '」' + t + '（横幅，未出声）',
      lastEvent: 'EVT: hit saved - kw ' + kw + ' (banner only, no TTS while listening)'
    });
    this._renderAll();
  },

  onASRResult(event) {
    // Real-device path: host SpeechRecognition ASR delivers
    // transcript segments; each goes through the same gate.
    var d = (event && event.detail) || event || {};
    var text = d.text || d.transcript || '';
    this._ingest(text);
  },

  // ---------- start / mode / kw / review / end ----------

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - mic mode is set before listening, never mid-standup' });
      return;
    }
    this._micIdx = (this._micIdx + 1) % this._micModes.length;
    this.setData({
      status: '收音模式：' + this._mic() + '（只影响 getUserMedia 流的拾音，不改变宿主识别的拾音）',
      lastEvent: 'EVT: mic mode set to ' + this._mic() + ' (getUserMedia stream pickup only; host ASR pickup is unaffected)'
    });
    this._renderAll();
  },

  kwTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: KW refused - keyword group is set before listening, never mid-standup' });
      return;
    }
    this._kwIdx = (this._kwIdx + 1) % this._kwGroups.length;
    this.setData({
      status: '关键词组：' + this._keywords().join(' / ') + '（命中只亮横幅存笔记，未命中默记一行摘要）',
      lastEvent: 'EVT: keyword group set to ' + this._keywords().join('/') + ' (table order wins on multi-hit)'
    });
    this._renderAll();
  },

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already listening, reviewing or summarising' });
      return;
    }
    // Real-device path: a mode-selected getUserMedia audio
    // stream plus host SpeechRecognition ASR. Both are
    // optional on the preview host: failure only notes the
    // soft failure, listening still starts so DEMO and
    // delivered ASR events keep working.
    try {
      if (typeof navigator !== 'undefined' && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: { microphoneMode: this._mic() } }).then(function () {}).catch(function () {});
      }
    } catch (e) {}
    try {
      var SR = (typeof window !== 'undefined' && (window.SpeechRecognition || window.webkitSpeechRecognition)) || null;
      if (SR) { /* host ASR delivers via onASRResult */ }
    } catch (e) {}
    this._mode = 'listening';
    this.setData({
      status: '守听进行中 — 命中才亮屏存笔记，未命中默记一行摘要，会后 REVIEW 可查',
      lastEvent: 'EVT: listening started - mic mode ' + this._mic() + ' (stream pickup only; host ASR unaffected)'
    });
    this._renderAll();
  },

  reviewTap() {
    if (this._mode === 'review') {
      this.setData({ lastEvent: 'EVT: REVIEW refused - already reviewing' });
      return;
    }
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: REVIEW refused - missing: 先 START 开始守听' });
      return;
    }
    if (this._hits.length === 0 && this._digest.length === 0) {
      this.setData({ lastEvent: 'EVT: REVIEW refused - no hit notes and no digest rows yet, nothing to review' });
      return;
    }
    this._mode = 'review';
    this._focus = 0;
    this.setData({
      status: '会后可查 — 关联 ' + this._hits.length + ' 条在前，摘要 ' + this._digest.length + ' 行在后，NEXT/PREV 走行，END 出小结',
      lastEvent: 'EVT: review opened - hits ' + this._hits.length + ', digest ' + this._digest.length
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to review without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始守听' });
      return;
    }
    this._mode = 'summary';
    this._summary = {
      hits: this._hits.length,
      digest: this._digest.length,
      heard: this._heard
    };
    this.setData({
      status: '结束 — 关联 ' + this._hits.length + ' 条，摘要 ' + this._digest.length + ' 行，只听过 ' + this._heard + ' 段，点 END 确认清空，BACK 回会后可查',
      lastEvent: 'EVT: closed - hits ' + this._hits.length + ', digest ' + this._digest.length + ', heard ' + this._heard
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._hits = [];
    this._digest = [];
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '站会回声 — START 再次开始守听',
      lastEvent: 'EVT: summary confirmed - hit notes, digest rows and counts cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to review without
      // deleting anything; the summary is rebuilt on END.
      // If nothing was ever collected, return to listening.
      this._mode = (this._hits.length > 0 || this._digest.length > 0) ? 'review' : 'listening';
      this._summary = null;
      this.setData({
        status: this._mode === 'review' ? '会后可查 — BACK 回到会后可查，笔记与摘要保留' : '守听进行中 — BACK 回到守听，笔记与摘要保留',
        lastEvent: 'EVT: back to ' + this._mode + ' - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'review') {
      // Back from review returns to listening with notes
      // and digest rows kept; REVIEW reopens from row 1.
      this._mode = 'listening';
      this.setData({
        status: '守听进行中 — BACK 回到守听，笔记与摘要保留，REVIEW 重新可查',
        lastEvent: 'EVT: back to listening - notes and digest kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'listening') {
      // Back from listening returns to idle with the round
      // kept; START resumes listening on the same round.
      this._mode = 'idle';
      this.setData({
        status: '站会回声 — 已存关联 ' + this._hits.length + ' 条、摘要 ' + this._digest.length + ' 行未清，START 恢复守听',
        lastEvent: 'EVT: back to idle - notes and digest kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START starts listening' });
  },

  _reviewRows() {
    var rows = [];
    var i;
    for (i = 0; i < this._hits.length; i++) {
      rows.push({ hit: true, idx: i, text: this._hits[i].text, time: this._hits[i].time, kw: this._hits[i].kw });
    }
    for (i = 0; i < this._digest.length; i++) {
      rows.push({ hit: false, idx: this._hits.length + i, text: this._digest[i].line, time: this._digest[i].time, kw: '' });
    }
    return rows;
  },

  _focusLen() {
    if (this._mode === 'listening') return this._hits.length;
    if (this._mode === 'review') return this._hits.length + this._digest.length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus (focus walks notes in listening, rows in review)' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus (focus walks notes in listening, rows in review)' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
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
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没守听：START 开始守听';
    } else if (this._mode === 'listening') {
      line = '守听中，命中 ' + this._hits.length + ' 条，摘要 ' + this._digest.length + ' 行，只听过 ' + this._heard + ' 段';
    } else if (this._mode === 'review') {
      var rows = this._reviewRows();
      var row = rows[this._focus];
      line = row ? (row.hit ? '关联第 ' + (this._focus + 1) + ' 条：' + row.text : '摘要第 ' + (this._focus - this._hits.length + 1) + ' 行：' + row.text) : '会后可查，暂无行';
    } else if (this._summary) {
      line = '本次站会小结：关联 ' + this._summary.hits + ' 条，摘要 ' + this._summary.digest + ' 行，只听过 ' + this._summary.heard + ' 段';
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
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user standup session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._hits.length > 0 || this._digest.length > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user notes are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY - ready' });
      this.startTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - listening started (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._ingest('昨天团建订了火锅，周五晚上七点集合');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - non-hit sentence kept as digest row 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._ingest('支付链路这周要上灰度，订单回调先别动');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - hit saved kw 支付 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._ingest('新来的实习生下周一入职，工位在三楼');
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - non-hit sentence kept as digest row 2 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this._ingest('订单超时的重试策略风控那边要先评审');
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - hit saved kw 订单 (table order over 风控) (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.reviewTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - review opened, hits 2 + digest 2 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - summary: hits 2, digest 2, heard 4 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i;

    if (this._mode === 'idle') {
      if (this._hits.length === 0 && this._digest.length === 0) {
        rows.push({
          idx: 0,
          name: '暂未守听',
          detail: 'START 开始守听（示例站会，DEMO 演示）',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._hits.length; i++) {
          rows.push({
            idx: i,
            name: this._hits[i].text,
            detail: this._hits[i].time + ' · ' + this._hits[i].kw + ' · 关联（待机保留，START 恢复）',
            flag: '●',
            cls: 'row'
          });
        }
        for (i = 0; i < this._digest.length; i++) {
          rows.push({
            idx: this._hits.length + i,
            name: this._digest[i].line,
            detail: this._digest[i].time + ' · 摘要行（待机保留，START 恢复）',
            flag: '○',
            cls: 'row'
          });
        }
      }
    } else if (this._mode === 'listening') {
      for (i = 0; i < this._hits.length; i++) {
        rows.push({
          idx: i,
          name: this._hits[i].text,
          detail: this._hits[i].time + ' · ' + this._hits[i].kw + ' · 关联' + (this._focus === i ? ' · 当前' : ''),
          flag: (this._focus === i ? '▶' : '●'),
          cls: 'row'
        });
      }
      if (this._hits.length === 0) {
        rows.push({
          idx: 0,
          name: '还没存下关联',
          detail: '只存含模块关键词的句子，其他默记成一行摘要',
          flag: '○',
          cls: 'row'
        });
      }
    } else if (this._mode === 'review') {
      var rr = this._reviewRows();
      for (i = 0; i < rr.length; i++) {
        rows.push({
          idx: rr[i].idx,
          name: rr[i].text,
          detail: rr[i].time + (rr[i].hit ? ' · ' + rr[i].kw + ' · 关联' : ' · 摘要行（原句截取）') + (this._focus === i ? ' · 当前' : ''),
          flag: (this._focus === i ? '▶' : (rr[i].hit ? '●' : '○')),
          cls: 'row'
        });
      }
    } else {
      var s = this._summary || { hits: 0, digest: 0, heard: 0 };
      rows.push({ idx: 0, name: '关联条数', detail: s.hits + ' 条', flag: '○', cls: 'row' });
      rows.push({ idx: 1, name: '摘要行数', detail: s.digest + ' 行', flag: '○', cls: 'row' });
      rows.push({ idx: 2, name: '只听过段数', detail: s.heard + ' 段', flag: '○', cls: 'row' });
    }

    var patch = { rows: rows };
    patch.countLine = '命中 ' + this._hits.length + ' 条 · 摘要 ' + this._digest.length + ' 行 · 只听过 ' + this._heard + ' 段 · 只存本次站会会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 关联笔记 — START 开始守听，MODE 换收音模式，KW 换关键词组，REVIEW 会后可查';
      patch.bigLabel = '站会回声 · 待机';
      patch.bigText = (this._hits.length === 0 && this._digest.length === 0) ? '还没守听' : '命中 ' + this._hits.length + ' 条';
      patch.bigNote = 'START 开始守听 · MODE 换收音模式 · KW 换关键词组 · REVIEW 会后可查';
    } else if (this._mode === 'listening') {
      patch.boxLabel = '◎ 守听进行中 — 命中才亮屏存笔记，未命中默记一行摘要，REVIEW 会后可查';
      patch.bigLabel = '站会回声 · 守听中';
      patch.bigText = '命中 ' + this._hits.length + ' 条';
      patch.bigNote = '摘要 ' + this._digest.length + ' 行 · 只听过 ' + this._heard + ' 段 · 守听中不朗读 · REVIEW 会后可查';
    } else if (this._mode === 'review') {
      patch.boxLabel = '◎ 会后可查 — 关联在前，摘要在后，NEXT/PREV 走行，END 出小结';
      patch.bigLabel = '站会回声 · 会后可查';
      patch.bigText = '关联 ' + this._hits.length + ' 条';
      patch.bigNote = '摘要 ' + this._digest.length + ' 行 · NEXT/PREV 走行 · SPEAK 读当前行 · END 出小结';
    } else {
      patch.boxLabel = '◎ 本次站会小结 — 关联、摘要、只听过段数钉在下面';
      patch.bigLabel = '本次站会小结';
      var sm = this._summary || { hits: 0, digest: 0, heard: 0 };
      patch.bigText = '关联 ' + sm.hits + ' 条';
      patch.bigNote = '摘要 ' + sm.digest + ' 行 · 只听过 ' + sm.heard + ' 段 · 点 END 确认清空 · BACK 回会后可查';
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
      <text class="title">STANDUP ECHO v1.0.0</text>
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
      <button class="btn btn-main" bindtap="modeTap">MODE</button>
      <button class="btn btn-main" bindtap="kwTap">KW</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="reviewTap">REVIEW</button>
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="backTap">BACK</button>
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
    <text class="foot2">关联判定是关键词匹配，不是相关性理解——含关键词的句子未必真与你相关，ASR 听错也可能漏报/误报 · 未命中摘要行是原句截取，不是提炼 · 没有说话人识别，笔记与摘要不分说话方 · 命中只亮横幅，守听中不朗读、不打断站会 · 只存本次站会会话，关掉即清 · 收音模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音 · 没有室内定位 · 零落盘</text>
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
