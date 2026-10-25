<script def>
{
  "navigationBarTitleText": "Elder Ear"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '老人叮嘱 — 陪老人聊天，老人反复叮嘱的事（吃药、门锁、子女电话）记不全、回头就忘：wearer/far-field 守听，只把「叮嘱/需求」类句子存成清单，聊完 TTS 复述给你确认',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 叮嘱清单 — START 开始守听，MODE 换收音模式，DONE 聊完复述',
    bigLabel: '老人叮嘱 · 待机',
    bigText: '还没守听',
    bigNote: 'START 开始守听 · MODE 换收音模式 · DONE 聊完复述',
    permLine: 'PERM: RECORD_AUDIO — wearer/far-field 收音流 + 宿主 ASR 转写做叮嘱关键词匹配；模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音；守听中不朗读、不存全文',
    rows: [],
    countLine: '已存 0 条 · 已确认 0 条 · 只听过 0 段 · 只存本次聊天会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START starts listening, MODE switches mic mode, DONE replays the list',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | replay | summary
    // Keyword gate, table order wins on multi-hit: a sentence
    // matching several words is filed under the earliest
    // keyword in this table, never under all of them.
    this._keywords = ['吃药', '门锁', '电话', '记得', '别忘', '明天', '打电话', '锁门'];
    this._micModes = ['wearer', 'far-field'];
    this._micIdx = 0;
    this._items = []; // { text, time, kw, confirmed }
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._allAnnounced = false;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 start, 2 non-hit, 3 hit1, 4 hit2, 5 done, 6 conf1, 7 conf2, 8 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the reminder list, the
    // heard count and the summary die with the page. Nothing
    // was ever written anywhere persistent, so there is
    // nothing to clean up — that IS the design.
    this._mode = 'idle';
    this._items = [];
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._allAnnounced = false;
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

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Listening itself never speaks: a hit
    // is a banner only, so the chat is never interrupted.
    // Speech happens only in replay (DONE/CONF) and SPEAK.
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
    // listening in idle, confirms the replayed item in
    // replay, or confirms the summary. A nod never ingests
    // a sentence while listening: captions can only arrive
    // from the talk itself, never from a nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'listening') {
      this.setData({ lastEvent: 'EVT: nod ignored while listening - captions come from talk, not from a nod' });
      return;
    }
    if (this._mode === 'replay') { this.confTap(); return; }
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
      else if (this._mode === 'replay') this.confTap();
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
    for (var i = 0; i < this._keywords.length; i++) {
      if (text.indexOf(this._keywords[i]) !== -1) return this._keywords[i];
    }
    return null;
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
      // Non-hit sentences are counted and immediately
      // discarded: no full transcript is ever kept.
      this.setData({
        status: '守听中 — 只听过 ' + this._heard + ' 段，未命中不存（已丢弃）',
        lastEvent: 'EVT: heard only - no keyword, discarded (heard ' + this._heard + ')'
      });
      this._renderAll();
      return;
    }
    this._items.push({ text: t, time: this._hhmm(), kw: kw, confirmed: false });
    this._focus = this._items.length - 1;
    // A hit is a banner only: speaking now would interrupt
    // the chat the agent is supposed to stay out of.
    this.setData({
      status: '已存叮嘱 — 「' + kw + '」' + t + '（横幅，未出声）',
      lastEvent: 'EVT: reminder saved - kw ' + kw + ' (banner only, no TTS while listening)'
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

  // ---------- start / mode / done / confirm / end ----------

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - mic mode is set before listening, never mid-chat' });
      return;
    }
    this._micIdx = (this._micIdx + 1) % this._micModes.length;
    this.setData({
      status: '收音模式：' + this._mic() + '（只影响 getUserMedia 流的拾音，不改变宿主识别的拾音）',
      lastEvent: 'EVT: mic mode set to ' + this._mic() + ' (getUserMedia stream pickup only; host ASR pickup is unaffected)'
    });
    this._renderAll();
  },

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already listening, replaying or summarising' });
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
      status: '守听进行中 — 只存「叮嘱/需求」类句子，守听中不朗读、不存全文',
      lastEvent: 'EVT: listening started - mic mode ' + this._mic() + ' (stream pickup only; host ASR unaffected)'
    });
    this._renderAll();
  },

  doneTap() {
    if (this._mode === 'replay') {
      this.setData({ lastEvent: 'EVT: DONE refused - already replaying' });
      return;
    }
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: DONE refused - missing: 先 START 开始守听' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: DONE refused - no reminders saved yet, nothing to replay' });
      return;
    }
    this._mode = 'replay';
    this._focus = 0;
    this._allAnnounced = false;
    var first = this._items[0];
    this._speakText('叮嘱第一条：' + first.text);
    this.setData({
      status: '聊完复述 — 第 1/' + this._items.length + ' 条：' + first.text,
      lastEvent: 'EVT: replay started - reading item 1/' + this._items.length + ' aloud'
    });
    this._renderAll();
  },

  confTap() {
    if (this._mode !== 'replay') {
      this.setData({ lastEvent: 'EVT: CONF refused - CONF confirms a replayed item only in replay' });
      return;
    }
    var item = this._items[this._focus];
    if (!item) {
      this.setData({ lastEvent: 'EVT: CONF refused - no item focused' });
      return;
    }
    if (item.confirmed) {
      this.setData({ lastEvent: 'EVT: CONF refused - this item is already confirmed' });
      return;
    }
    item.confirmed = true;
    var confirmed = 0;
    var i;
    for (i = 0; i < this._items.length; i++) if (this._items[i].confirmed) confirmed++;
    if (confirmed === this._items.length) {
      if (!this._allAnnounced) {
        this._allAnnounced = true;
        this._speakText('叮嘱都确认了');
      }
      this.setData({
        status: '全部确认 — ' + this._items.length + ' 条叮嘱都确认了，END 出小结',
        lastEvent: 'EVT: all items confirmed - ' + confirmed + '/' + this._items.length
      });
      this._renderAll();
      return;
    }
    // Advance to the next unconfirmed item and read it aloud:
    // replay flows by voice, one item per confirmation.
    var next = -1;
    for (i = 0; i < this._items.length; i++) {
      if (!this._items[i].confirmed) { next = i; break; }
    }
    this._focus = next;
    var nxt = this._items[next];
    this._speakText('叮嘱第 ' + (next + 1) + ' 条：' + nxt.text);
    this.setData({
      status: '聊完复述 — 第 ' + (next + 1) + '/' + this._items.length + ' 条：' + nxt.text,
      lastEvent: 'EVT: item confirmed - reading next unconfirmed item ' + (next + 1)
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to replay without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始守听' });
      return;
    }
    this._mode = 'summary';
    var confirmed = 0;
    var i;
    for (i = 0; i < this._items.length; i++) if (this._items[i].confirmed) confirmed++;
    this._summary = {
      saved: this._items.length,
      confirmed: confirmed,
      heard: this._heard
    };
    this.setData({
      status: '结束 — 叮嘱 ' + this._items.length + ' 条，已确认 ' + confirmed + ' 条，点 END 确认清空，BACK 回复述',
      lastEvent: 'EVT: closed - saved ' + this._items.length + ', confirmed ' + confirmed + ', heard ' + this._heard
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._items = [];
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._allAnnounced = false;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '老人叮嘱 — START 再次开始守听',
      lastEvent: 'EVT: summary confirmed - reminders and counts cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to replay without
      // deleting anything; the summary is rebuilt on END.
      // If nothing was ever replayed, return to listening.
      this._mode = this._items.length > 0 ? 'replay' : 'listening';
      this._summary = null;
      this.setData({
        status: this._mode === 'replay' ? '聊完复述 — BACK 回到复述，确认保留' : '守听进行中 — BACK 回到守听，清单保留',
        lastEvent: 'EVT: back to ' + this._mode + ' - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'replay') {
      // Back from replay returns to listening with items
      // and confirmations kept; DONE replays from item 1.
      this._mode = 'listening';
      this.setData({
        status: '守听进行中 — BACK 回到守听，清单与确认保留，DONE 重新复述',
        lastEvent: 'EVT: back to listening - items and confirmations kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'listening') {
      // Back from listening returns to idle with the list
      // kept; START resumes listening on the same list.
      this._mode = 'idle';
      this.setData({
        status: '老人叮嘱 — 已存 ' + this._items.length + ' 条未清，START 恢复守听',
        lastEvent: 'EVT: back to idle - items kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START starts listening' });
  },

  _focusLen() {
    if (this._mode === 'listening' || this._mode === 'replay') return this._items.length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus (focus walks reminders only)' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus (focus walks reminders only)' });
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
      line = '守听中，已存 ' + this._items.length + ' 条叮嘱，只听过 ' + this._heard + ' 段';
    } else if (this._mode === 'replay') {
      var item = this._items[this._focus];
      line = item ? '叮嘱第 ' + (this._focus + 1) + ' 条：' + item.text : '复述中，暂无条目';
    } else if (this._summary) {
      line = '本次聊天小结：叮嘱 ' + this._summary.saved + ' 条，已确认 ' + this._summary.confirmed + ' 条，只听过 ' + this._summary.heard + ' 段';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user chat session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._items.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user reminders are under way' });
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
      this._ingest('今天天气不错，适合出去走走');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - non-hit sentence heard only, discarded (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._ingest('记得吃药，早上那颗别忘了吃');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - reminder saved kw 吃药 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._ingest('出门记得锁门，门锁要转两圈');
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - reminder saved kw 门锁 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.doneTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - replay started, item 1 read aloud (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - item 1 confirmed, item 2 read aloud (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - item 2 confirmed, all confirmed (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 7) {
      this._demoStage = 8;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 8 - summary: saved 2, confirmed 2, heard 3 (DEMO sample)' });
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
      if (this._items.length === 0) {
        rows.push({
          idx: 0,
          name: '暂未守听',
          detail: 'START 开始守听（示例叮嘱，DEMO 演示）',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._items.length; i++) {
          rows.push({
            idx: i,
            name: this._items[i].text,
            detail: this._items[i].time + ' · ' + this._items[i].kw + (this._items[i].confirmed ? ' · 已确认' : '') + '（待机保留，START 恢复）',
            flag: this._items[i].confirmed ? '✓' : '●',
            cls: 'row'
          });
        }
      }
    } else if (this._mode === 'listening' || this._mode === 'replay') {
      for (i = 0; i < this._items.length; i++) {
        rows.push({
          idx: i,
          name: this._items[i].text,
          detail: this._items[i].time + ' · ' + this._items[i].kw + (this._items[i].confirmed ? ' · 已确认' : '') + (this._focus === i ? ' · 当前' : ''),
          flag: (this._focus === i ? '▶' : (this._items[i].confirmed ? '✓' : '●')),
          cls: 'row'
        });
      }
      if (this._items.length === 0) {
        rows.push({
          idx: 0,
          name: '还没存下叮嘱',
          detail: '只存含叮嘱关键词的句子，其他只计数、不存',
          flag: '○',
          cls: 'row'
        });
      }
    } else {
      var s = this._summary || { saved: 0, confirmed: 0, heard: 0 };
      rows.push({ idx: 0, name: '叮嘱条数', detail: s.saved + ' 条', flag: '○', cls: 'row' });
      rows.push({ idx: 1, name: '已确认', detail: s.confirmed + ' 条', flag: '○', cls: 'row' });
      rows.push({ idx: 2, name: '只听过段数', detail: s.heard + ' 段', flag: '○', cls: 'row' });
    }

    var confirmed = 0;
    var j;
    for (j = 0; j < this._items.length; j++) if (this._items[j].confirmed) confirmed++;
    var patch = { rows: rows };
    patch.countLine = '已存 ' + this._items.length + ' 条 · 已确认 ' + confirmed + ' 条 · 只听过 ' + this._heard + ' 段 · 只存本次聊天会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 叮嘱清单 — START 开始守听，MODE 换收音模式，DONE 聊完复述';
      patch.bigLabel = '老人叮嘱 · 待机';
      patch.bigText = this._items.length === 0 ? '还没守听' : '已存 ' + this._items.length + ' 条';
      patch.bigNote = 'START 开始守听 · MODE 换收音模式 · DONE 聊完复述';
    } else if (this._mode === 'listening') {
      patch.boxLabel = '◎ 守听进行中 — 命中才存清单，守听中不朗读，DONE 聊完复述';
      patch.bigLabel = '老人叮嘱 · 守听中';
      patch.bigText = '已存 ' + this._items.length + ' 条';
      patch.bigNote = '只听过 ' + this._heard + ' 段 · 命中才存清单 · 守听中不朗读 · DONE 聊完复述';
    } else if (this._mode === 'replay') {
      patch.boxLabel = '◎ 聊完复述 — CONF 确认当前条，NEXT/PREV 走条目，END 出小结';
      patch.bigLabel = '老人叮嘱 · 复述中';
      if (confirmed === this._items.length && this._items.length > 0) {
        patch.bigText = '全部确认';
        patch.bigNote = '叮嘱都确认了 · END 出小结 · BACK 回守听';
      } else {
        patch.bigText = '复述第 ' + (this._focus + 1) + '/' + this._items.length + ' 条';
        patch.bigNote = 'CONF 确认当前条并读下一条 · NEXT/PREV 走条目 · END 出小结';
      }
    } else {
      patch.boxLabel = '◎ 本次聊天小结 — 叮嘱、已确认、只听过段数钉在下面';
      patch.bigLabel = '本次聊天小结';
      var sm = this._summary || { saved: 0, confirmed: 0, heard: 0 };
      patch.bigText = '叮嘱 ' + sm.saved + ' 条';
      patch.bigNote = '已确认 ' + sm.confirmed + ' 条 · 只听过 ' + sm.heard + ' 段 · 点 END 确认清空 · BACK 回复述';
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
      <text class="title">ELDER EAR v1.0.0</text>
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
      <button class="btn btn-main" bindtap="doneTap">DONE</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="confTap">CONF</button>
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
    <text class="foot2">叮嘱判定是关键词匹配，不是语义理解——含关键词的句子未必真是叮嘱，ASR 听错也可能漏存/错存，清单只是候选 · 没有说话人识别，清单不分说话方 · TTS 复述是你点「聊完」后才读的，守听中不朗读、不打断聊天 · 只存本次聊天会话，关掉即清 · 收音模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音 · 没有室内定位 · 零落盘</text>
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
