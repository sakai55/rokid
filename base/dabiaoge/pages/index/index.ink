<script def>
{
  "navigationBarTitleText": "大表哥"
}
</script>

<script setup>
import { CHANNEL_KEY, BASE_URL } from '../../channel.js';

var POLL_MS = 4000;
var TIMEOUT_MS = 300000;
var MAX_INFLIGHT = 5;
var END_WORD = '大表哥';
// ASR may drop the first syllable ("大表哥" heard as "表哥"); a
// trailing short form also ends the utterance (v1.0.3).
var END_WORD_SHORT = '表哥';
var MAX_CHARS = 500;
var QUEUE_KEY = 'dabiaoge_queue_v2';
// Snake loop on the 5x5 dot grid (irregular turns, wraps around):
// the working slot shows 4 connected cells of this loop, head first.
var SNAKE_LOOP = [[0,2],[1,2],[2,2],[2,1],[2,0],[3,0],[4,0],[4,1],[4,2],[3,2],[3,3],[3,4],[2,4],[1,4],[0,4],[0,3]];

export default {
  data: {
    phase: 'idle',
    stateText: '待命 · 点头开始说话',
    heardText: '',
    heardCls: 'heard heard-dim',
    boxLabel: '待命，点头开始录入',
    slots: [],
    resTitle: '',
    resBody: '',
    resItems: [],
    choiceLine: '',
    hint: '说完以「大表哥」结尾发送（「表哥」也认） · 停顿没关系，文字都攒着',
    appVersion: 'v2.1.3'
  },

  onLoad() {
    this._lastKeyAt = 0;
    this._rec = null;
    this._notice = null;
    this._submitted = false;
    this._buffer = '';
    this._wantListen = false;
    this._restarts = 0;
    this._gotFinal = false;
    this._queue = [];
    this._viewIdx = -1;
    this._pollTimer = null;
    this._polling = false;
    this._tick = 0;
    this._demo = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._ensureSession();
    this._restoreQueue();
    var self = this;
    this._snakeTimer = setInterval(function () { self._snakeStep(); }, 300);
    this._initHeadTurn();
    this._syncUI();
    this._ensurePolling();
  },

  onUnload() {
    this._polling = false;
    this._wantListen = false;
    if (this._rec) { try { this._rec.abort(); } catch (e) {} this._rec = null; }
    if (this._pollTimer) { clearTimeout(this._pollTimer); this._pollTimer = null; }
    if (this._snakeTimer) { clearInterval(this._snakeTimer); this._snakeTimer = null; }
    if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; }
  },

  // ---------- session / queue storage ----------
  // v2: the whole queue (sent / in-flight / finished-unread) is
  // persisted, so closing the agent never loses a ticket and a
  // cold start resumes polling every unfinished one.

  _ensureSession() {
    var sid = '';
    try { sid = localStorage.getItem('dabiaoge_session') || ''; } catch (e) {}
    if (!sid) {
      sid = 's-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
      try { localStorage.setItem('dabiaoge_session', sid); } catch (e) {}
    }
    this._session = sid;
  },

  _saveQueue() {
    try { localStorage.setItem(QUEUE_KEY, JSON.stringify(this._queue)); } catch (e) {}
  },

  _restoreQueue() {
    var q = [];
    try { q = JSON.parse(localStorage.getItem(QUEUE_KEY) || '[]'); } catch (e) { q = []; }
    if (!Array.isArray(q)) q = [];
    this._queue = q.filter(function (it) { return it && it.id; });
    // Upgrade path: a v1 single in-flight ticket becomes a queue item.
    if (!this._queue.length) {
      var old = '';
      try { old = localStorage.getItem('dabiaoge_ticket') || ''; } catch (e) {}
      if (old) {
        this._queue.push({ id: old, text: '上次的问题', st: 'queued', at: Date.now(), env: null });
        this._saveQueue();
      }
    }
    try { localStorage.removeItem('dabiaoge_ticket'); } catch (e) {}
    this._trimQueue();
  },

  // Retention: only the newest MAX_INFLIGHT tickets exist at all.
  // Older finished ones fall off (history cannot be paged back);
  // unfinished ones are never evicted.
  _trimQueue() {
    while (this._queue.length > MAX_INFLIGHT) {
      var idx = -1;
      for (var i = 0; i < this._queue.length; i++) {
        if (this._queue[i].st !== 'queued' && this._queue[i].st !== 'working') { idx = i; break; }
      }
      if (idx < 0) break;
      this._queue.splice(idx, 1);
    }
  },

  _unfinished() {
    return this._queue.filter(function (it) { return it.st === 'queued' || it.st === 'working'; });
  },

  // Presentation is strictly in SEND order: walk the queue from
  // the front and stop at the first unfinished ticket - finals
  // behind it have arrived but are HELD (not shown, not spoken)
  // until every earlier ticket is final too.
  _finals() {
    var out = [];
    for (var i = 0; i < this._queue.length; i++) {
      var it = this._queue[i];
      if (it.st === 'queued' || it.st === 'working') break;
      out.push(it);
    }
    return out;
  },

  _heldCount() {
    var seenGap = false, n = 0;
    for (var i = 0; i < this._queue.length; i++) {
      var it = this._queue[i];
      if (it.st === 'queued' || it.st === 'working') seenGap = true;
      else if (seenGap) n++;
    }
    return n;
  },

  // ---------- life slots (dot matrix in the title row) ----------
  // One 5x5 dot slot per queue item, in send order, height matched
  // to the title text (x0.618). queued = border dots, working = a
  // little snake with a tail running the loop, finished-unread =
  // all dots lit. Nothing at all when the queue is empty.

  _dotsFor(kind, slotIdx) {
    var dots = [];
    var x, y, i;
    if (kind === 'd') {
      for (i = 0; i < 25; i++) dots.push(2);
      return dots;
    }
    if (kind === 'q') {
      for (y = 0; y < 5; y++) for (x = 0; x < 5; x++) {
        dots.push((x === 0 || x === 4 || y === 0 || y === 4) ? 1 : 0);
      }
      return dots;
    }
    // working: snake = 4 consecutive loop cells, head brightest
    for (i = 0; i < 25; i++) dots.push(0);
    var head = ((this._tick + slotIdx * 5) % SNAKE_LOOP.length + SNAKE_LOOP.length) % SNAKE_LOOP.length;
    for (var k = 0; k < 4; k++) {
      var cell = SNAKE_LOOP[((head - k) % SNAKE_LOOP.length + SNAKE_LOOP.length) % SNAKE_LOOP.length];
      dots[cell[1] * 5 + cell[0]] = (k === 0) ? 2 : 1;
    }
    return dots;
  },

  _slotsData() {
    var self = this;
    return this._queue.map(function (it, i) {
      var kind = it.st === 'queued' ? 'q' : (it.st === 'working' ? 'w' : 'd');
      return { kind: kind, dots: self._dotsFor(kind, i) };
    });
  },

  _snakeStep() {
    this._tick = (this._tick || 0) + 1;
    if (this._demo) return;
    var hasWorking = this._queue.some(function (it) { return it.st === 'working'; });
    if (hasWorking) this.setData({ slots: this._slotsData() });
  },

  // ---------- central UI sync ----------

  _syncUI() {
    if (this._demo) return;
    var patch = { slots: this._slotsData() };
    patch.boxLabel = this.data.phase === 'idle' ? '待命，点头开始录入' : '你说的是';
    var ph = this.data.phase;
    var finals = this._finals();
    if (ph === 'idle') {
      if (this._notice) {
        patch.stateText = this._notice.title;
        patch.resTitle = this._notice.title;
        patch.resBody = this._notice.body;
        patch.resItems = []; patch.choiceLine = '';
        this.setData(patch);
        return;
      }
      var un = this._unfinished().length;
      if (finals.length) {
        patch.stateText = '有 ' + finals.length + ' 条结果可看' + (un ? ' · 另有 ' + un + ' 条在处理' : '');
        patch.hint = '左右转头或滑动镜腿看结果 · 点头继续提问';
      } else if (un) {
        patch.stateText = '已发送 ' + un + ' 条 · 下面可以继续说下一条';
        patch.hint = '左右转头或滑动翻看已完成 · 还能再发 ' + (MAX_INFLIGHT - this._queue.length) + ' 条';
      } else {
        patch.stateText = '待命 · 点头开始说话';
        patch.hint = '说完以「大表哥」结尾发送（「表哥」也认） · 停顿没关系，文字都攒着';
      }
      if (this._lastEnv) {
        var le = this._lastEnv;
        patch.resTitle = String(le.title || '');
        patch.resBody = String(le.body || '');
        patch.resItems = (le.type === 'list' && le.items) ? le.items.map(function (x) { return '· ' + String(x); }) : [];
        patch.choiceLine = (le.type === 'choices' && le.choices && le.choices.length)
          ? le.choices.map(function (x) { return String(x); }).join('  ·  ') : '';
      } else {
        patch.resTitle = ''; patch.resBody = ''; patch.resItems = []; patch.choiceLine = '';
      }
    } else if (ph === 'inbox') {
      var item = finals[this._viewIdx];
      if (item) {
        var env = item.env || {};
        var held = this._heldCount();
        patch.stateText = '第 ' + (this._viewIdx + 1) + ' / ' + finals.length + ' 条（发送顺序）' + (held ? ' · ' + held + ' 条已回在排队' : '') + ' · 转头或滑动翻条';
        patch.resTitle = String(env.title || '');
        patch.resBody = String(env.body || '');
        patch.resItems = (env.type === 'list' && env.items) ? env.items.map(function (s) { return '· ' + String(s); }) : [];
        patch.choiceLine = (env.type === 'choices' && env.choices && env.choices.length)
          ? env.choices.map(function (s) { return String(s); }).join('  ·  ') : '';
        patch.hint = '转头 / 滑动翻条（翻到即朗读） · 点头问下一条';
      }
    }
    this.setData(patch);
  },

  // ---------- inbox ----------

  _openInbox(idx, speakIt) {
    this._notice = null;
    var finals = this._finals();
    if (!finals.length) return;
    this._viewIdx = Math.max(0, Math.min(idx || 0, finals.length - 1));
    this.setData({ phase: 'inbox' });
    this._syncUI();
    this._lastEnv = finals[this._viewIdx].env || {};
    finals[this._viewIdx].shown = true;
    this._saveQueue();
    if (speakIt) {
      var env = finals[this._viewIdx].env || {};
      if (env.speak) this._announce(String(env.speak));
    }
  },

  _flip(delta) {
    if (this.data.phase === 'listening') return;
    var finals = this._finals();
    if (!finals.length) return;
    if (this.data.phase !== 'inbox') { this._openInbox(delta > 0 ? 0 : finals.length - 1, true); return; }
    var n = this._viewIdx + delta;
    if (n < 0) n = 0;
    if (n > finals.length - 1) n = finals.length - 1;
    if (n !== this._viewIdx) {
      this._viewIdx = n;
      this._lastEnv = finals[n].env || {};
      finals[n].shown = true;
      this._saveQueue();
      this._syncUI();
      var env = finals[n].env || {};
      if (env.speak) this._announce(String(env.speak));
    }
  },

  // A ticket reached a final state. While the user is speaking it
  // is banked silently (a footer note only); while composing, the
  // earliest unread result surfaces and is read aloud.
  _onFinal(item) {
    item.doneAt = Date.now();
    this._saveQueue();
    var ph = this.data.phase;
    var finals = this._finals();
    var candidate = null;
    for (var i = 0; i < finals.length; i++) {
      if (!finals[i].shown) { candidate = finals[i]; break; }
    }
    if (!candidate) {
      // Arrived out of order and is held behind an earlier ticket,
      // or everything presentable was already shown: update slots only.
      this.setData({ slots: this._slotsData() });
      if (ph === 'inbox') this._syncUI();
      return;
    }
    this._lastEnv = candidate.env || {};
    if (ph === 'listening') {
      // Never interrupt dictation: the result appears quietly in
      // the reply area below - no screen switch, no TTS.
      candidate.shown = true;
      this._saveQueue();
      this.setData({ slots: this._slotsData() });
      this._renderEnv(this._lastEnv);
      return;
    }
    if (ph === 'idle') { this._openInbox(finals.indexOf(candidate), true); return; }
    this._syncUI();
  },

  _renderEnv(env) {
    env = env || {};
    this.setData({
      resTitle: String(env.title || ''),
      resBody: String(env.body || ''),
      resItems: (env.type === 'list' && env.items) ? env.items.map(function (x) { return '· ' + String(x); }) : [],
      choiceLine: (env.type === 'choices' && env.choices && env.choices.length)
        ? env.choices.map(function (x) { return String(x); }).join('  ·  ') : ''
    });
  },

  // ---------- demo states (preview / screenshot only) ----------
  // The footer demo button cycles sample screens (queue + slots,
  // inbox list, inbox text, idle). Samples never touch the real
  // queue and never submit; any primary action exits demo mode.

  onDemo() {
    var order = ['queue', 'listening', 'list', 'text', 'idle'];
    var idx = this._demoIdx || 0;
    this._demoIdx = idx + 1;
    this._demo = true;
    var mode = order[idx % order.length];
    if (mode === 'queue') {
      this._tick = 6;
      var mk = function (kind, i) { return { kind: kind, dots: this._dotsFor(kind, i) }; }.bind(this);
      this.setData({
        phase: 'idle',
        boxLabel: '待命，点头开始录入',
        stateText: '已发送 3 条 · 下面可以继续说下一条',
        heardText: '', heardCls: 'heard heard-dim',
        slots: [mk('d', 0), mk('w', 1), mk('q', 2)],
        resTitle: '', resBody: '', resItems: [], choiceLine: '',
        hint: '演示（示例） · 全点满=已完成 · 小蛇=处理中 · 边框点=待处理'
      });
      return;
    }
    if (mode === 'listening') {
      var mk2 = function (kind, i) { return { kind: kind, dots: this._dotsFor(kind, i) }; }.bind(this);
      this.setData({
        phase: 'listening',
        boxLabel: '你说的是',
        stateText: '正在听 · 说吧，停顿没关系',
        heardText: '帮我查一下明天去大阪的电车，嗯……还有最早一班是几点',
        heardCls: 'heard',
        slots: [mk2('d', 0)],
        resTitle: '今日天气',
        resBody: '东京今天晴，最高 21 度，傍晚起风，出门加件外套。',
        resItems: [], choiceLine: '',
        hint: '说完以「大表哥」结尾发送（「表哥」也认） · 点头取消'
      });
      return;
    }
    if (mode === 'list') {
      this.setData({
        phase: 'inbox',
        boxLabel: '你说的是',
        stateText: '第 1 / 2 条（发送顺序） · 转头或滑动翻条',
        heardText: '列出今天的开发清单', heardCls: 'heard',
        resTitle: '今日开发清单', resBody: '今天完成的三批：',
        resItems: ['· 路缘坡 CC06–CC08', '· 头动游戏 GA24–GA26', '· 日韩新批 3 个'],
        choiceLine: '',
        hint: '演示状态（示例数据） · 再点演示看下一态'
      });
      return;
    }
    if (mode === 'text') {
      this.setData({
        phase: 'inbox',
        boxLabel: '你说的是',
        stateText: '第 2 / 2 条（发送顺序） · 转头或滑动翻条',
        heardText: '用一句话说说今天的天气', heardCls: 'heard',
        resTitle: '今日天气',
        resBody: '东京今天晴，最高 21 度，傍晚起风，出门加件外套。',
        resItems: [], choiceLine: '',
        hint: '演示状态（示例数据） · 再点演示回待命'
      });
      return;
    }
    this._demo = false;
    this.setData({
      phase: 'idle',
      boxLabel: '待命，点头开始录入',
      stateText: '待命 · 点头开始说话',
      heardText: '', heardCls: 'heard heard-dim',
      resTitle: '', resBody: '', resItems: [], choiceLine: '',
      hint: '说完以「大表哥」结尾发送（「表哥」也认） · 停顿没关系，文字都攒着'
    });
    this._syncUI();
  },

  // ---------- gestures ----------
  // Temple touch has exactly ONE job: previous / next (the swipe
  // keys). There is deliberately NO tap action anywhere - taps on
  // the temple misfire too easily (interrupting dictation or
  // sending half a sentence). Input is head-driven: a nod starts
  // listening (and cancels it), the end word sends. Turning the
  // head left / right mirrors the temple swipe.

  onKeyDown(event) {
    var code = event && event.code;
    if (code !== 'ArrowDown' && code !== 'ArrowUp') return;
    var now = Date.now();
    if (now - this._lastKeyAt < 400) return;
    this._lastKeyAt = now;
    if (!this._demo) this._flip(code === 'ArrowDown' ? 1 : -1);
  },

  onHeadGesture(event) {
    if (!event || event.gesture !== 'nod') return;
    var now = Date.now();
    if (now - this._lastKeyAt < 400) return;
    this._lastKeyAt = now;
    this._nod();
  },

  _nod() {
    if (this._demo) { this._exitDemo(); return; }
    if (this.data.phase === 'listening') { this._cancelListening(); return; }
    this._startListening();
  },

  _cancelListening() {
    this._wantListen = false;
    this._buffer = '';
    if (this._rec) { try { this._rec.abort(); } catch (e) {} this._rec = null; }
    this.setData({ phase: 'idle', heardText: '', heardCls: 'heard heard-dim' });
    this._syncUI();
  },

  _exitDemo() {
    this._demo = false;
    this._demoIdx = 0;
    this.setData({ phase: 'idle', heardText: '', heardCls: 'heard heard-dim' });
    this._syncUI();
  },

  // Head turns (yaw from the orientation sensor) = temple swipes.
  // Baseline recentres whenever the head settles back inside the
  // dead zone; a turn past 22 degrees flips once per excursion.
  _initHeadTurn() {
    this._yawBase = null;
    this._turnArmed = true;
    var S = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!S) return;
    var self = this;
    var sensor = null;
    try {
      sensor = new S({ frequency: 30 });
    } catch (e) { return; }
    this._sensor = sensor;
    sensor.onreading = function () { self._onYaw(sensor); };
    sensor.onerror = function () { /* sensor optional - swipes still work */ };
    try { sensor.start(); } catch (e) {}
  },

  _onYaw(sensor) {
    var q = sensor.quaternion;
    if (!q || q.length < 4) return;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)) * 180 / Math.PI;
    if (this._yawBase === null) { this._yawBase = yaw; return; }
    var rel = yaw - this._yawBase;
    while (rel > 180) rel -= 360;
    while (rel < -180) rel += 360;
    if (this.data.phase === 'listening' || this._demo) { this._yawBase = yaw; return; }
    if (this._turnArmed && rel >= 22) { this._turnArmed = false; if (!this._demo) this._flip(1); }
    else if (this._turnArmed && rel <= -22) { this._turnArmed = false; if (!this._demo) this._flip(-1); }
    else if (!this._turnArmed && Math.abs(rel) <= 9) { this._turnArmed = true; this._yawBase = yaw; }
  },

  // ---------- ASR (accumulate + end word) ----------
  // The host ASR endpoints on ITS OWN silence rule, which the app
  // cannot tune: a mid-sentence pause would cut the user off. So a
  // final segment no longer submits. Segments accumulate on screen
  // and are sent only when the accumulated text ends with the end
  // word (stripped before submit), or when the user taps/nods to
  // send now. After each host endpoint the recognizer restarts
  // itself while listening is still wanted.

  _startListening() {
    var SR = typeof SpeechRecognition !== 'undefined' ? SpeechRecognition : null;
    if (!SR) {
      this._noteAsResult('无法开始识别', '这台设备没有可用的语音识别（SpeechRecognition 不可用）。');
      return;
    }
    this._notice = null;
    this._submitted = false;
    this._buffer = '';
    this._wantListen = true;
    this._restarts = 0;
    this.setData({
      phase: 'listening',
      boxLabel: '你说的是',
      stateText: '正在听 · 说吧，停顿没关系',
      heardText: '',
      heardCls: 'heard',
      hint: '说完以「大表哥」结尾发送（「表哥」也认） · 点头取消'
    });
    this._launchRec();
  },

  _launchRec() {
    var SR = typeof SpeechRecognition !== 'undefined' ? SpeechRecognition : null;
    if (!SR) return;
    var self = this;
    var rec = null;
    try {
      rec = new SR();
      rec.continuous = false;
      rec.interimResults = true;
      rec.maxAlternatives = 1;
    } catch (e) {
      this._wantListen = false;
      this._noteAsResult('无法开始识别', '语音识别启动失败：' + this._err(e));
      return;
    }
    this._rec = rec;
    this._gotFinal = false;
    rec.onresult = function (ev) { self._onResult(ev); };
    rec.onerror = function (ev) {
      if (self._submitted) return;
      self._rec = null;
      self._wantListen = false;
      self._noteAsResult('识别失败', '没能听清（' + String((ev && ev.error) || 'error') + '）。已攒到的文字还留在屏上，点头再试。');
    };
    rec.onend = function () { self._onRecEnd(); };
    try {
      rec.start();
    } catch (e) {
      this._rec = null;
      if (this._wantListen && !this._submitted) {
        this._wantListen = false;
        this._noteAsResult('无法开始识别', '语音识别启动失败：' + this._err(e));
      }
    }
  },

  _onResult(ev) {
    if (this._submitted) return;
    var finalText = '', interim = '';
    try {
      for (var i = ev.resultIndex; i < ev.results.length; i++) {
        var r = ev.results[i];
        var t = (r && r[0]) ? String(r[0].transcript || '') : '';
        if (r && r.isFinal) finalText += t; else interim += t;
      }
    } catch (e) {}
    if (interim) {
      this.setData({ heardText: (this._buffer || '') + interim });
    }
    if (finalText) {
      this._gotFinal = true;
      this._restarts = 0;
      this._buffer = (this._buffer || '') + finalText;
      this.setData({ heardText: this._buffer });
      this._checkEnd();
    }
  },

  _onRecEnd() {
    this._rec = null;
    if (this._submitted) return;
    if (!this._wantListen) return;
    if (this.data.phase !== 'listening') return;
    if (!this._gotFinal) {
      this._restarts = (this._restarts || 0) + 1;
      if (this._restarts >= 6) {
        this._wantListen = false;
        this.setData({ phase: 'idle' });
        this._syncUI();
        return;
      }
    }
    this._launchRec();
  },

  // Strip trailing punctuation/whitespace for end-word tests.
  _trimTail(s) {
    return String(s || '').replace(/[\s，。！？、；：,.!?;:]+$/, '');
  },

  // Length of the end word at the tail (0 = none). Accepts the full
  // end word and its short form (see END_WORD_SHORT).
  _endHit(tail) {
    if (tail.slice(-END_WORD.length) === END_WORD) return END_WORD.length;
    if (tail.slice(-END_WORD_SHORT.length) === END_WORD_SHORT) return END_WORD_SHORT.length;
    return 0;
  },

  _checkEnd() {
    var tail = this._trimTail(this._buffer);
    var hit = this._endHit(tail);
    if (hit > 0) {
      var body = this._trimTail(tail.slice(0, tail.length - hit));
      if (!body) {
        // Only the end word so far: keep listening, ask for content.
        this._buffer = '';
        this.setData({
          heardText: '',
          stateText: '正在听 · 先说事，最后再说「大表哥」',
          hint: '刚才只有结束词，还没攒到内容'
        });
        return;
      }
      this._finish(body);
      return;
    }
    if (this._buffer.length >= MAX_CHARS) {
      this._finish(this._trimTail(this._buffer));
    }
  },

  // The finished utterance joins the queue and the screen returns
  // to compose at once - sending never waits for processing. Any
  // results banked during listening surface right after the send.
  _finish(text) {
    if (this._submitted) return;
    this._submitted = true;
    this._wantListen = false;
    var clean = String(text || '').trim();
    if (this._rec) { try { this._rec.abort(); } catch (e) {} this._rec = null; }
    this.setData({ phase: 'idle', heardText: '', heardCls: 'heard heard-dim' });
    if (!clean) {
      this._noteAsResult('没听清', '还没有攒到内容。点头再说一遍。');
      return;
    }
    if (this._unfinished().length >= MAX_INFLIGHT) {
      this._noteAsResult('都在处理中', '最新 5 条都还在处理，先等一条回来再问。刚才这句是：' + clean.slice(0, 60));
      return;
    }
    this._submit(clean);
    // After sending, the screen returns to the initial compose
    // state: a nod starts the next voice input. Results that
    // arrived quietly stay visible in the reply area below; the
    // inbox is never auto-opened from here.
    this._syncUI();
  },

  // ---------- channel ----------

  _submit(text) {
    if (!CHANNEL_KEY || CHANNEL_KEY === 'PASTE_CHANNEL_KEY_HERE') {
      this._noteAsResult('钥匙未填', 'channel.js 里还是占位符：打包前要在 Studio 里把占位符换成真钥匙（见 README）。');
      return;
    }
    var self = this;
    fetch(BASE_URL + '/submit', {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-channel-key': CHANNEL_KEY },
      body: JSON.stringify({ session: this._session, kind: 'ask', text: text })
    }).then(function (resp) {
      return resp.json().then(function (j) { return { status: resp.status, body: j }; });
    }).then(function (r) {
      if (r.status === 401) {
        self._noteAsResult('钥匙不对', '前门拒绝了这把钥匙（401）。检查 channel.js 里填的钥匙是否正确。');
        return;
      }
      if (!r.body || !r.body.ticket) {
        self._noteAsResult('投单失败', '前门没有返回单号。稍后点头再问一句重试。');
        return;
      }
      self._queue.push({ id: r.body.ticket, text: text, st: 'queued', at: Date.now(), env: null });
      self._trimQueue();
      self._saveQueue();
      self._syncUI();
      self._ensurePolling();
    }).catch(function (e) {
      self._noteAsResult('网络没通', '投单没发出去（' + self._err(e) + '）。检查眼镜与手机的连接后重试。');
    });
  },

  // One polling loop serves the whole queue: every cycle checks
  // each unfinished ticket once. A ticket that reaches a final
  // state (done / needs-approval / error) or its own 300s limit
  // lands in the inbox; the others keep waiting independently.
  _ensurePolling() {
    if (this._polling) return;
    if (!this._unfinished().length) return;
    this._polling = true;
    this._pollCycle();
  },

  _pollCycle() {
    if (!this._polling) return;
    var self = this;
    var pending = this._unfinished().slice();
    if (!pending.length) { this._polling = false; return; }
    var i = 0;
    var step = function () {
      if (!self._polling) return;
      if (i >= pending.length) {
        self._pollTimer = setTimeout(function () { self._pollCycle(); }, POLL_MS);
        return;
      }
      var item = pending[i++];
      if (Date.now() - item.at >= TIMEOUT_MS) {
        item.st = 'timeout';
        item.env = { type: 'text', title: '还在处理中', body: '这一条等了 300 秒还没回（单子不会丢，Muse 办完后下次打开还能补收——若一直没回，多半是队列堵住了）。点头看完后可重新问。', speak: '' };
        self._onFinal(item);
        step();
        return;
      }
      fetch(BASE_URL + '/ticket/' + encodeURIComponent(item.id), {
        headers: { 'x-channel-key': CHANNEL_KEY }
      }).then(function (resp) {
        return resp.json().then(function (j) { return { status: resp.status, body: j }; });
      }).then(function (r) {
        var b = r.body || {};
        var st = b.status || '';
        if (st === 'done') {
          item.st = 'done';
          item.env = b.result || {};
          self._onFinal(item);
        } else if (st === 'needs-approval') {
          item.st = 'approval';
          item.env = { type: 'text', title: '需要你批准', body: '这件事要你在手机上批准，已挂起：到 RokidRelay 聊里看工单卡处理。', speak: '' };
          self._onFinal(item);
        } else if (st === 'error') {
          item.st = 'error';
          item.env = { type: 'text', title: '处理失败', body: 'Muse 那边没能办成（' + String(b.error || 'error').slice(0, 40) + '）。', speak: '' };
          self._onFinal(item);
        } else if (st === 'working' && item.st !== 'working') {
          item.st = 'working';
          self._saveQueue();
          self._syncUI();
        }
        step();
      }).catch(function () { step(); });
    };
    step();
  },

  // ---------- rendering helpers ----------

  // Local notices (no network, no ticket) reuse the compose area.
  _noteAsResult(title, body) {
    this._lastEnv = null;
    this._notice = { title: title, body: body };
    this.setData({
      phase: 'idle',
      boxLabel: '待命，点头开始录入',
      stateText: title,
      resTitle: title,
      resBody: body,
      resItems: [], choiceLine: '',
    });
  },

  _announce(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text));
    } catch (e) { /* TTS must never break the flow */ }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 48);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <view class="title-row">
        <text class="title">大表哥</text>
        <view class="slots">
          <view ink:for="{{slots}}" class="slot">
            <view ink:for="{{item.dots}}" class="dot dot-{{item}}"></view>
          </view>
        </view>
      </view>
      <text class="state">{{stateText}}</text>
    </view>
    <view class="heard-box">
      <text class="heard-label">{{boxLabel}}</text>
      <text class="{{heardCls}}">{{heardText}}</text>
      <text class="box-hint">{{hint}}</text>
    </view>
    <view class="reply">
      <text class="res-title">{{resTitle}}</text>
      <text class="res-body">{{resBody}}</text>
      <view class="items">
        <text ink:for="{{resItems}}" class="res-item">{{item}}</text>
      </view>
      <text class="choices">{{choiceLine}}</text>
    </view>
    <view class="foot-row">
      <button class="btn-demo" bindtap="onDemo">演示</button>
      <text class="ver">{{appVersion}}</text>
    </view>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 12px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 8px;
}
.title-row {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.title {
  color: #7dff9e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.slots {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-left: 8px;
}
.slot {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  width: 14px;
  height: 14px;
  margin-right: 5px;
}
.dot {
  width: 2px;
  height: 2px;
  border-radius: 1px;
  margin: 0.4px;
}
.dot-0 {
  background-color: rgba(125,255,158,0.07);
}
.dot-1 {
  background-color: rgba(125,255,158,0.55);
}
.dot-2 {
  background-color: #7dff9e;
}
.box-hint {
  color: rgba(125,255,158,0.6);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 3px;
}
.state {
  color: rgba(125,255,158,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.heard-box {
  border: 1px dashed rgba(125,255,158,0.55);
  border-radius: 2px;
  padding: 6px 8px;
  margin-bottom: 8px;
}
.heard-label {
  color: rgba(125,255,158,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.heard {
  color: #7dff9e;
  font-size: 15px;
  line-height: 20px;
  margin-top: 2px;
}
.heard-dim {
  color: rgba(125,255,158,0.4);
  font-size: 15px;
  line-height: 20px;
  margin-top: 2px;
}
.reply {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}
.res-title {
  color: #7dff9e;
  font-size: 17px;
  font-weight: 500;
  line-height: 22px;
}
.res-body {
  color: rgba(125,255,158,0.88);
  font-size: 14px;
  line-height: 19px;
  margin-top: 3px;
}
.items {
  display: flex;
  flex-direction: column;
  margin-top: 4px;
}
.res-item {
  color: rgba(125,255,158,0.88);
  font-size: 13px;
  line-height: 18px;
}
.choices {
  color: #7dff9e;
  font-family: monospace;
  font-size: 12px;
  line-height: 16px;
  margin-top: 6px;
}
.foot-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-end;
  margin-top: 8px;
}
.btn-demo {
  color: rgba(125,255,158,0.6);
  background-color: rgba(125,255,158,0.06);
  border: 1px dashed rgba(125,255,158,0.48);
  border-radius: 999px;
  padding: 2px 9px;
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  text-align: center;
  margin-right: 8px;
}
.foot {
  flex-grow: 1;
  color: rgba(125,255,158,0.6);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.ver {
  color: rgba(125,255,158,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  text-align: right;
}
</style>
