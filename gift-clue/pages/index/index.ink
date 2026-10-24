<script def>
{
  "navigationBarTitleText": "Gift Clue"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '送礼线索 — 朋友随口提的喜好/想要的东西，当时没在意，生日送礼时全想不起来：日常聊天中命中「想要/喜欢/缺一个」类句子默记成线索卡，按人归档，送礼时回放',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 线索卡 — START 开始守听，MODE 换收音模式，PERSON 给当前卡指定归属人，GIFT 送礼时按人回放',
    bigLabel: '送礼线索 · 待机',
    bigText: '还没守听',
    bigNote: 'START 开始守听 · MODE 换收音模式 · PERSON 指定归属人 · GIFT 送礼时按人回放',
    permLine: 'PERM: RECORD_AUDIO — wearer/far-field 收音流 + 宿主 ASR 转写做喜好关键词匹配；模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音；守听中不朗读、不亮屏打断聊天',
    rows: [],
    countLine: '线索 0 张 · 已归档 0 人 · 只听过 0 段 · 只存本次聊天会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START starts listening, MODE switches mic mode, PERSON assigns the focused card, GIFT replays one person',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | listening | gift | summary
    // Want/like keyword table, in table order: the earliest
    // table keyword in the sentence files the card, never all
    // of them. Note 想要 is a substring of 想要一个 and
    // 一直想要， so table order files those under 想要.
    this._keywords = ['想要', '喜欢', '缺一个', '想要一个', '好想要', '一直想要'];
    // People are a preset demo group only: the owner of a
    // card is always assigned by hand with PERSON, never
    // recognised from a voice.
    this._persons = ['阿明', '小林', '老陈'];
    this._micModes = ['wearer', 'far-field'];
    this._micIdx = 0;
    this._cards = []; // { text, time, kw, person: null | name }
    this._heard = 0;
    this._focus = 0;
    this._giftPerson = '阿明';
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 start, 2 non-hit, 3 card1, 4 card2, 5 assigned, 6 gift, 7 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the clue cards, the
    // heard count and the summary die with the page. Nothing
    // was ever written anywhere persistent, so there is
    // nothing to clean up — that IS the design. The gift-time
    // replay is a replay inside this same opening, never a
    // cross-day memory.
    this._mode = 'idle';
    this._cards = [];
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

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Listening itself never speaks: a hit
    // is a silent card, so the chat is never interrupted.
    // Speech happens only via SPEAK and in gift/summary.
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
    // gift focus. A nod never ingests a sentence while
    // listening: captions can only arrive from the chat
    // itself, never from a nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'listening') {
      this.setData({ lastEvent: 'EVT: nod ignored while listening - captions come from chat, not from a nod' });
      return;
    }
    if (this._mode === 'gift') { this.nextTap(); return; }
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
        this.setData({ lastEvent: 'EVT: Enter ignored while listening - captions come from chat, not from a key' });
      }
      else if (this._mode === 'gift') this.nextTap();
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
      // Non-hit sentences are counted and dropped on the
      // spot: gift-clue keeps cards only, never a transcript.
      this.setData({
        status: '守听中 — 只听过 ' + this._heard + ' 段，未命中句只计数、判定即丢弃',
        lastEvent: 'EVT: non-hit counted and dropped - no keyword (heard ' + this._heard + ')'
      });
      this._renderAll();
      return;
    }
    this._cards.push({ text: t, time: this._hhmm(), kw: kw, person: null });
    this._focus = this._cards.length - 1;
    // A hit is a silent card: no banner, no speech, so the
    // chat is never interrupted by the agent noticing a clue.
    this.setData({
      status: '已存线索 — 「' + kw + '」' + t + '（默记，未出声，待归档）',
      lastEvent: 'EVT: clue card saved - kw ' + kw + ' (silent, unassigned)'
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

  // ---------- start / mode / person / gift / end ----------

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - mic mode is set before listening, never mid-chat' });
      return;
    }
    if (!this._micModes) this._micModes = ['wearer', 'far-field'];
    if (this._micIdx === undefined) this._micIdx = 0;
    this._micIdx = (this._micIdx + 1) % this._micModes.length;
    this.setData({
      status: '收音模式：' + this._mic() + '（只影响 getUserMedia 流的拾音，不改变宿主识别的拾音）',
      lastEvent: 'EVT: mic mode set to ' + this._mic() + ' (getUserMedia stream pickup only; host ASR pickup is unaffected)'
    });
    this._renderAll();
  },

  personTap() {
    if (this._mode === 'listening') {
      if (this._cards.length === 0) {
        this.setData({ lastEvent: 'EVT: PERSON ignored - no clue card yet to assign' });
        return;
      }
      var card = this._cards[this._focus];
      // Cycle: unassigned -> 阿明 -> 小林 -> 老陈 -> unassigned.
      // The owner is always assigned by hand here, never
      // recognised from a voice: there is no speaker
      // identification on this device.
      var order = [null].concat(this._persons);
      var cur = order.indexOf(card.person);
      var nxt = order[(cur + 1) % order.length];
      card.person = nxt;
      this.setData({
        status: nxt ? '已归档 — 第 ' + (this._focus + 1) + ' 张线索归给' + nxt + '（你手动指定的，不是识别的）' : '已取消归档 — 第 ' + (this._focus + 1) + ' 张线索回待归档',
        lastEvent: 'EVT: card ' + (this._focus + 1) + ' assigned to ' + (nxt || 'unassigned') + ' (hand-assigned, not recognised)'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'gift') {
      var gi = this._persons.indexOf(this._giftPerson);
      this._giftPerson = this._persons[(gi + 1) % this._persons.length];
      this._focus = 0;
      this.setData({
        status: '送礼回放 — 看' + this._giftPerson + '的线索卡（同一次打开内的回放，不是跨天存档）',
        lastEvent: 'EVT: gift filter set to ' + this._giftPerson
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: PERSON refused - assign cards while listening, switch people while replaying' });
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
      status: '守听进行中 — 命中喜好句默记成线索卡，不亮屏、不出声，PERSON 给当前卡指定归属人',
      lastEvent: 'EVT: listening started - mic mode ' + this._mic() + ' (stream pickup only; host ASR unaffected)'
    });
    this._renderAll();
  },

  giftTap() {
    if (this._mode === 'gift') {
      this.setData({ lastEvent: 'EVT: GIFT refused - already replaying' });
      return;
    }
    if (this._mode !== 'listening') {
      this.setData({ lastEvent: 'EVT: GIFT refused - missing: 先 START 开始守听' });
      return;
    }
    if (this._cards.length === 0) {
      this.setData({ lastEvent: 'EVT: GIFT refused - no clue cards yet, nothing to replay' });
      return;
    }
    // Default filter: the focused card's owner if assigned,
    // else the first person who already has cards, else 阿明.
    var focused = this._cards[this._focus];
    if (focused && focused.person) {
      this._giftPerson = focused.person;
    } else {
      var found = null;
      for (var i = 0; i < this._cards.length; i++) {
        if (this._cards[i].person) { found = this._cards[i].person; break; }
      }
      this._giftPerson = found || '阿明';
    }
    this._mode = 'gift';
    this._focus = 0;
    this.setData({
      status: '送礼回放 — 看' + this._giftPerson + '的线索卡，NEXT/PREV 走卡，SPEAK 读当前卡，PERSON 换人',
      lastEvent: 'EVT: gift replay opened - person ' + this._giftPerson
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to gift without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始守听' });
      return;
    }
    var persons = {};
    for (var i = 0; i < this._cards.length; i++) {
      if (this._cards[i].person) persons[this._cards[i].person] = true;
    }
    this._mode = 'summary';
    this._summary = {
      cards: this._cards.length,
      persons: Object.keys(persons).length,
      heard: this._heard
    };
    this.setData({
      status: '结束 — 线索 ' + this._cards.length + ' 张，已归档 ' + this._summary.persons + ' 人，只听过 ' + this._heard + ' 段，点 END 确认清空，BACK 回送礼回放',
      lastEvent: 'EVT: closed - cards ' + this._cards.length + ', persons ' + this._summary.persons + ', heard ' + this._heard
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._cards = [];
    this._heard = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '送礼线索 — START 再次开始守听',
      lastEvent: 'EVT: summary confirmed - clue cards and counts cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to gift without
      // deleting anything; the summary is rebuilt on END.
      // If nothing was ever collected, return to listening.
      this._mode = this._cards.length > 0 ? 'gift' : 'listening';
      this._summary = null;
      this.setData({
        status: this._mode === 'gift' ? '送礼回放 — BACK 回到送礼回放，线索卡保留' : '守听进行中 — BACK 回到守听，线索卡保留',
        lastEvent: 'EVT: back to ' + this._mode + ' - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'gift') {
      // Back from gift returns to listening with cards kept;
      // GIFT reopens from the focused card's owner.
      this._mode = 'listening';
      this.setData({
        status: '守听进行中 — BACK 回到守听，线索卡保留，GIFT 重新按人回放',
        lastEvent: 'EVT: back to listening - cards kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'listening') {
      // Back from listening returns to idle with the round
      // kept; START resumes listening on the same round.
      this._mode = 'idle';
      this.setData({
        status: '送礼线索 — 已存线索 ' + this._cards.length + ' 张未清，START 恢复守听',
        lastEvent: 'EVT: back to idle - cards kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START starts listening' });
  },

  _giftRows() {
    var rows = [];
    for (var i = 0; i < this._cards.length; i++) {
      if (this._cards[i].person === this._giftPerson) rows.push(this._cards[i]);
    }
    return rows;
  },

  _focusLen() {
    if (this._mode === 'listening') return this._cards.length;
    if (this._mode === 'gift') return this._giftRows().length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus (focus walks cards in listening, one person\'s cards in gift)' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus (focus walks cards in listening, one person\'s cards in gift)' });
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
      line = '守听中，线索 ' + this._cards.length + ' 张，只听过 ' + this._heard + ' 段';
    } else if (this._mode === 'gift') {
      var rows = this._giftRows();
      var row = rows[this._focus];
      line = row ? this._giftPerson + '的第 ' + (this._focus + 1) + ' 张线索：' + row.text : this._giftPerson + '还没有线索卡';
    } else if (this._summary) {
      line = '本次聊天小结：线索 ' + this._summary.cards + ' 张，已归档 ' + this._summary.persons + ' 人，只听过 ' + this._summary.heard + ' 段';
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
    if (this._mode === 'idle' && !this._demo && this._cards.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user cards are under way' });
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
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - non-hit sentence counted and dropped (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._ingest('我一直想要一个降噪耳机，出差路上用');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - clue card 1 saved kw 想要 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._ingest('最近喜欢上喝手冲咖啡，家里缺一个磨豆机');
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - clue card 2 saved kw 喜欢 (table order over 缺一个) (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.personTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - card 2 assigned to 阿明 by hand (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.giftTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - gift replay opened for 阿明, 1 card (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - summary: cards 2, persons 1, heard 3 (DEMO sample)' });
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
      if (this._cards.length === 0) {
        rows.push({
          idx: 0,
          name: '暂未守听',
          detail: 'START 开始守听（日常聊天示例，DEMO 演示）',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._cards.length; i++) {
          rows.push({
            idx: i,
            name: this._cards[i].text,
            detail: this._cards[i].time + ' · ' + this._cards[i].kw + ' · ' + (this._cards[i].person || '待归档') + '（待机保留，START 恢复）',
            flag: '●',
            cls: 'row'
          });
        }
      }
    } else if (this._mode === 'listening') {
      for (i = 0; i < this._cards.length; i++) {
        rows.push({
          idx: i,
          name: this._cards[i].text,
          detail: this._cards[i].time + ' · ' + this._cards[i].kw + ' · ' + (this._cards[i].person || '待归档') + (this._focus === i ? ' · 当前' : ''),
          flag: (this._focus === i ? '▶' : '●'),
          cls: 'row'
        });
      }
      if (this._cards.length === 0) {
        rows.push({
          idx: 0,
          name: '还没存下线索',
          detail: '只存含想要/喜欢/缺一个类关键词的句子，其他只计数、判定即丢弃',
          flag: '○',
          cls: 'row'
        });
      }
    } else if (this._mode === 'gift') {
      var gr = this._giftRows();
      for (i = 0; i < gr.length; i++) {
        rows.push({
          idx: i,
          name: gr[i].text,
          detail: gr[i].time + ' · ' + gr[i].kw + ' · ' + this._giftPerson + (this._focus === i ? ' · 当前' : ''),
          flag: (this._focus === i ? '▶' : '●'),
          cls: 'row'
        });
      }
      if (gr.length === 0) {
        rows.push({
          idx: 0,
          name: this._giftPerson + '还没有线索卡',
          detail: 'PERSON 换人，BACK 回守听',
          flag: '○',
          cls: 'row'
        });
      }
    } else {
      var s = this._summary || { cards: 0, persons: 0, heard: 0 };
      rows.push({ idx: 0, name: '线索张数', detail: s.cards + ' 张', flag: '○', cls: 'row' });
      rows.push({ idx: 1, name: '已归档人数', detail: s.persons + ' 人', flag: '○', cls: 'row' });
      rows.push({ idx: 2, name: '只听过段数', detail: s.heard + ' 段', flag: '○', cls: 'row' });
    }

    var patch = { rows: rows };
    var persons = {};
    for (var j = 0; j < this._cards.length; j++) {
      if (this._cards[j].person) persons[this._cards[j].person] = true;
    }
    var archived = Object.keys(persons).length;
    patch.countLine = '线索 ' + this._cards.length + ' 张 · 已归档 ' + archived + ' 人 · 只听过 ' + this._heard + ' 段 · 只存本次聊天会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 线索卡 — START 开始守听，MODE 换收音模式，PERSON 指定归属人，GIFT 送礼时按人回放';
      patch.bigLabel = '送礼线索 · 待机';
      patch.bigText = (this._cards.length === 0) ? '还没守听' : '线索 ' + this._cards.length + ' 张';
      patch.bigNote = 'START 开始守听 · MODE 换收音模式 · PERSON 指定归属人 · GIFT 送礼时按人回放';
    } else if (this._mode === 'listening') {
      patch.boxLabel = '◎ 守听进行中 — 命中喜好句默记成线索卡，不亮屏、不出声，PERSON 给当前卡指定归属人';
      patch.bigLabel = '送礼线索 · 守听中';
      patch.bigText = '线索 ' + this._cards.length + ' 张';
      patch.bigNote = '只听过 ' + this._heard + ' 段 · 已归档 ' + archived + ' 人 · 守听中不朗读 · GIFT 送礼时按人回放';
    } else if (this._mode === 'gift') {
      patch.boxLabel = '◎ 送礼回放 — 只看' + this._giftPerson + '的线索卡，NEXT/PREV 走卡，PERSON 换人，END 出小结';
      patch.bigLabel = '送礼回放 · ' + this._giftPerson;
      patch.bigText = this._giftPerson + ' · ' + this._giftRows().length + ' 张';
      patch.bigNote = 'NEXT/PREV 走卡 · SPEAK 读当前卡 · PERSON 换人 · END 出小结';
    } else {
      patch.boxLabel = '◎ 本次聊天小结 — 线索、已归档人数、只听过段数钉在下面';
      patch.bigLabel = '本次聊天小结';
      var sm = this._summary || { cards: 0, persons: 0, heard: 0 };
      patch.bigText = '线索 ' + sm.cards + ' 张';
      patch.bigNote = '已归档 ' + sm.persons + ' 人 · 只听过 ' + sm.heard + ' 段 · 点 END 确认清空 · BACK 回送礼回放';
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
      <text class="title">GIFT CLUE v1.0.0</text>
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
      <button class="btn btn-main" bindtap="personTap">PERSON</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="giftTap">GIFT</button>
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
    <text class="foot2">喜好判定是关键词匹配，不是喜好理解——含关键词的句子未必真是想要，ASR 听错也可能漏存/错存，线索卡只是候选 · 归属人是你手动指定的，没有说话人识别，线索卡从不自动认人 · 送礼时回放是指同一次打开内的回放，不是跨天存档 · 只存本次聊天会话，关掉即清 · 收音模式只影响 getUserMedia 流的拾音，不改变宿主识别的拾音 · 没有室内定位 · 零落盘</text>
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
