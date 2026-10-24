<script def>
{
  "navigationBarTitleText": "Guest Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '客人守望 — 在家招待客人，你在厨房忙，客厅谁的水空了、谁想添饭全靠余光：客人入座时逐位看向登记座位朝向，定时提醒回看茶水位，门口有动静 SCAN 报方位',
    steadyText: 'HEAD: moving - REG registers a seat only on steady gaze',
    boxLabel: '◎ 客人座位 — REG 逐位登记，WATCH 开始守望，SEEN 确认回看',
    bigLabel: '客人守望 · 待机',
    bigText: '还没登记',
    bigNote: 'REG 登记座位 · WATCH 开始守望 · SCAN 报门口方位',
    permLine: 'PERM: 无 — 只做座位登记 + 定时提醒 + SCAN 报方位；不拍照、不录音、不定位；水空了是你回看判断的；SCAN 不是动静探测',
    rows: [],
    countLine: '已登记 0 位 · 回看确认 0 次 · SCAN 0 次 · 提醒 0 次 · 只存本次招待会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - REG registers a seat, WATCH starts the look-back timer',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | register | watching | summary
    // Preset seat set (DEMO sample, labelled): each seat is a
    // direction you looked at when the guest sat down, not a
    // measured position. The door direction is likewise a
    // preset you confirm, not a sensor reading.
    this._seatPresets = [
      { name: '沙发左', dir: '左前方' },
      { name: '沙发右', dir: '右前方' },
      { name: '餐桌', dir: '正前方' }
    ];
    this._doorDir = '玄关方向';
    this._seats = [];
    this._focus = 0;
    this._seens = 0;
    this._scans = 0;
    this._reminds = 0;
    this._remLevel = 0; // 0 none, 1 banner, 2 banner + TTS, 3 strong banner + TTS
    this._lastSeen = 0;
    this._ticker = null;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1-3 seats, 4 watching, 5 reminder, 6 scan, 7 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: seats, counts and the
    // summary die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up
    // — that IS the design.
    this._stopTicker();
    this._mode = 'idle';
    this._seats = [];
    this._focus = 0;
    this._seens = 0;
    this._scans = 0;
    this._reminds = 0;
    this._remLevel = 0;
    this._lastSeen = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Level-1 reminders never call this:
    // a first nudge is a banner only, so the kitchen is not
    // interrupted for a glance that can wait.
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - REG registers a seat only on steady gaze'
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
    // Nod discipline in THIS agent: a steady nod registers
    // the next seat in idle/register, confirms a look-back
    // while watching, or confirms the summary. A nod never
    // picks a seat and never SCANs: SCAN is a deliberate tap
    // after you noticed something at the door.
    if (this._mode === 'idle' || this._mode === 'register') { this.regTap(); return; }
    if (this._mode === 'watching') { this.seenTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle' || this._mode === 'register') this.regTap();
      else if (this._mode === 'watching') this.seenTap();
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

  // ---------- look-back timer (5 min ladder, 30 s poll) ----------

  _startTicker() {
    if (this._ticker) return;
    var self = this;
    try {
      this._ticker = setInterval(function () { self._tick(self._now()); }, 30000);
    } catch (e) {}
  },

  _stopTicker() {
    try { if (this._ticker) clearInterval(this._ticker); } catch (e) {}
    this._ticker = null;
  },

  // The single decision point for reminders. Levels are
  // purely elapsed time since the last SEEN: 5 min banner,
  // 10 min banner + one TTS, 15 min strong banner + one TTS,
  // then capped — no further TTS. A reminder never claims
  // a cup is empty: it only says it is time to look.
  _tick(now) {
    if (this._mode !== 'watching') return;
    if (!this._lastSeen) return;
    var elapsed = now - this._lastSeen;
    var level = 0;
    if (elapsed >= 15 * 60 * 1000) level = 3;
    else if (elapsed >= 10 * 60 * 1000) level = 2;
    else if (elapsed >= 5 * 60 * 1000) level = 1;
    if (level <= this._remLevel) return;
    this._remLevel = level;
    this._reminds++;
    var line = '';
    if (level === 1) {
      line = '该回看茶水位了 — 去客厅看一眼谁的水空了';
      this.setData({
        status: '回看提醒 — 该回看茶水位了（横幅，未出声）',
        lastEvent: 'EVT: reminder level 1 - banner only, look back at tea levels'
      });
    } else if (level === 2) {
      line = '该回看茶水位了，去客厅看一眼';
      this._speakText(line);
      this.setData({
        status: '回看提醒升级 — 该回看茶水位了（已出声一次）',
        lastEvent: 'EVT: reminder level 2 - banner + one TTS'
      });
    } else {
      line = '很久没回看了，去客厅看一眼茶水位';
      this._speakText(line);
      this.setData({
        status: '回看强提醒 — 很久没回看了，去客厅看一眼',
        lastEvent: 'EVT: reminder level 3 - strong banner + one TTS, capped'
      });
    }
    this._renderAll();
  },

  // ---------- register / watch / seen / scan / end ----------

  regTap() {
    if (this._mode === 'watching' || this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: REG refused - seats are registered, watching or summarising' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: REG refused - hold steady and look at the seat first' });
      return;
    }
    if (this._mode === 'idle') {
      // First REG after a BACK-to-idle resumes the register
      // list without adding a duplicate: seats are kept.
      this._mode = 'register';
      if (this._seats.length === 0) {
        this._seats.push(this._seatPresets[0]);
        this._focus = 0;
        this.setData({
          status: '登记中 — 已登记沙发左（左前方），REG 继续登记下一位',
          lastEvent: 'EVT: seat registered - 沙发左 (DEMO preset seat set)'
        });
      } else {
        this.setData({
          status: '登记中 — 已登记 ' + this._seats.length + ' 位，REG 继续登记下一位，WATCH 开始守望',
          lastEvent: 'EVT: back to register - seats kept'
        });
      }
      this._renderAll();
      return;
    }
    // mode === 'register': add the next preset seat.
    if (this._seats.length >= this._seatPresets.length) {
      this.setData({ lastEvent: 'EVT: REG refused - all 3 preset seats registered, WATCH starts watching' });
      return;
    }
    var next = this._seatPresets[this._seats.length];
    this._seats.push(next);
    this._focus = this._seats.length - 1;
    this.setData({
      status: '登记中 — 已登记' + next.name + '（' + next.dir + '），REG 继续登记下一位，WATCH 开始守望',
      lastEvent: 'EVT: seat registered - ' + next.name + ' (DEMO preset seat set)'
    });
    this._renderAll();
  },

  watchTap() {
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: WATCH refused - already watching' });
      return;
    }
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: WATCH refused - missing: 先 REG 登记至少一位客人' });
      return;
    }
    if (this._seats.length === 0) {
      this.setData({ lastEvent: 'EVT: WATCH refused - no seats registered yet' });
      return;
    }
    this._mode = 'watching';
    this._lastSeen = this._now();
    this._remLevel = 0;
    this._focus = 0;
    this._startTicker();
    this.setData({
      status: '守望进行中 — 每 5 分钟提醒回看茶水位，SEEN 确认看过了，SCAN 报门口方位',
      lastEvent: 'EVT: watching started - look-back timer running (5 min ladder)'
    });
    this._renderAll();
  },

  seenTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: SEEN refused - SEEN confirms a look-back only while watching' });
      return;
    }
    this._seens++;
    this._lastSeen = this._now();
    this._remLevel = 0;
    this.setData({
      status: '看过了 — 计时重置，下次回看 5 分钟后',
      lastEvent: 'EVT: look-back confirmed - timer reset (seen ' + this._seens + ')'
    });
    this._renderAll();
  },

  scanTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: SCAN refused - SCAN reports the door direction only while watching' });
      return;
    }
    this._scans++;
    var line = '门口方位：' + this._doorDir + '，去看一眼';
    this._speakText(line);
    this.setData({
      status: '门口 SCAN — 方位：' + this._doorDir + '（预设朝向，不是探测），去看一眼',
      lastEvent: 'EVT: SCAN - door direction ' + this._doorDir + ' (preset, not detected), scan ' + this._scans
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to watching without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 REG 登记客人座位' });
      return;
    }
    this._stopTicker();
    this._mode = 'summary';
    this._summary = {
      seats: this._seats.length,
      seens: this._seens,
      scans: this._scans,
      reminds: this._reminds
    };
    this.setData({
      status: '结束 — 登记 ' + this._seats.length + ' 位，回看 ' + this._seens + ' 次，SCAN ' + this._scans + ' 次，点 END 确认清空，BACK 回守望',
      lastEvent: 'EVT: closed - seats ' + this._seats.length + ', seens ' + this._seens + ', scans ' + this._scans + ', reminds ' + this._reminds
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._stopTicker();
    this._mode = 'idle';
    this._seats = [];
    this._focus = 0;
    this._seens = 0;
    this._scans = 0;
    this._reminds = 0;
    this._remLevel = 0;
    this._lastSeen = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '客人守望 — REG 再次登记客人座位',
      lastEvent: 'EVT: summary confirmed - seats and counts cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'watching';
      this._summary = null;
      this._lastSeen = this._now();
      this._remLevel = 0;
      this._startTicker();
      this.setData({
        status: '守望进行中 — 每 5 分钟提醒回看茶水位，SEEN 确认看过了，SCAN 报门口方位',
        lastEvent: 'EVT: back to watching - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'watching') {
      // Back from watching returns to register with seats
      // kept and the timer stopped; WATCH restarts it.
      this._stopTicker();
      this._mode = 'register';
      this._remLevel = 0;
      this.setData({
        status: '登记中 — 已登记 ' + this._seats.length + ' 位，REG 继续登记下一位，WATCH 开始守望',
        lastEvent: 'EVT: back to register - seats kept, timer stopped'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'register') {
      // Back from register returns to idle with seats kept;
      // REG resumes the same list.
      this._mode = 'idle';
      this.setData({
        status: '客人守望 — 已登记 ' + this._seats.length + ' 位未清，REG 恢复登记',
        lastEvent: 'EVT: back to idle - seats kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - REG registers the first seat' });
  },

  _focusLen() {
    if (this._mode === 'register' || this._mode === 'watching') return this._seats.length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus (focus walks seats only)' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus (focus walks seats only)' });
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
      line = '还没登记：REG 登记客人座位';
    } else if (this._mode === 'register') {
      line = '已登记 ' + this._seats.length + ' 位客人';
    } else if (this._mode === 'watching') {
      line = this._remLevel === 0
        ? '守望中，已登记 ' + this._seats.length + ' 位，回看确认 ' + this._seens + ' 次'
        : '提醒 ' + this._remLevel + ' 级：该回看茶水位了';
    } else if (this._summary) {
      line = '本次招待小结：登记 ' + this._summary.seats + ' 位，回看 ' + this._summary.seens + ' 次，SCAN ' + this._summary.scans + ' 次，提醒 ' + this._summary.reminds + ' 次';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user hosting session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._seats.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user seats are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY - ready' });
      this.regTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - seat 沙发左 registered (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this.regTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - seat 沙发右 registered (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this.regTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - seat 餐桌 registered (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.watchTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - watching started (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      // Age the last look-back past the 5 min threshold so
      // the real tick ladder fires: this is a DEMO-forced
      // timer state, labelled as such, not a faked banner.
      this._lastSeen = this._now() - 6 * 60 * 1000;
      this._tick(this._now());
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - reminder level 1 fired by aged timer (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.scanTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - SCAN door direction 玄关方向 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - summary: seats 3, seens 0, scans 1, reminds 1 (DEMO sample)' });
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
      if (this._seats.length === 0) {
        rows.push({
          idx: 0,
          name: '暂未登记',
          detail: 'REG 登记第一位客人（示例座位，DEMO 演示）',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._seats.length; i++) {
          rows.push({
            idx: i,
            name: this._seats[i].name,
            detail: this._seats[i].dir + ' · 已登记（待机保留，REG 恢复）',
            flag: '●',
            cls: 'row'
          });
        }
      }
    } else if (this._mode === 'register' || this._mode === 'watching') {
      for (i = 0; i < this._seats.length; i++) {
        rows.push({
          idx: i,
          name: this._seats[i].name,
          detail: this._seats[i].dir + (this._focus === i ? ' · 当前' : ''),
          flag: (this._focus === i ? '▶' : '●'),
          cls: 'row'
        });
      }
    } else {
      var s = this._summary || { seats: 0, seens: 0, scans: 0, reminds: 0 };
      rows.push({ idx: 0, name: '登记座位', detail: s.seats + ' 位', flag: '○', cls: 'row' });
      rows.push({ idx: 1, name: '回看确认', detail: s.seens + ' 次', flag: '○', cls: 'row' });
      rows.push({ idx: 2, name: 'SCAN', detail: s.scans + ' 次', flag: '○', cls: 'row' });
      rows.push({ idx: 3, name: '提醒', detail: s.reminds + ' 次', flag: '○', cls: 'row' });
    }

    var patch = { rows: rows };
    patch.countLine = '已登记 ' + this._seats.length + ' 位 · 回看确认 ' + this._seens + ' 次 · SCAN ' + this._scans + ' 次 · 提醒 ' + this._reminds + ' 次 · 只存本次招待会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 客人座位 — REG 逐位登记，WATCH 开始守望，SEEN 确认回看';
      patch.bigLabel = '客人守望 · 待机';
      patch.bigText = this._seats.length === 0 ? '还没登记' : '已登记 ' + this._seats.length + ' 位';
      patch.bigNote = 'REG 登记座位 · WATCH 开始守望 · SCAN 报门口方位';
    } else if (this._mode === 'register') {
      patch.boxLabel = '◎ 登记中 — REG 继续登记下一位，WATCH 开始守望';
      patch.bigLabel = '客人守望 · 登记中';
      patch.bigText = '已登记 ' + this._seats.length + ' 位';
      patch.bigNote = this._seats.length >= 3
        ? '3 位都登记了 · WATCH 开始守望 · END 结束出小结'
        : 'REG 继续登记下一位 · WATCH 开始守望 · END 结束出小结';
    } else if (this._mode === 'watching') {
      patch.boxLabel = '◎ 守望进行中 — SEEN 确认看过了，SCAN 报门口方位，END 结束';
      patch.bigLabel = '客人守望 · 守望中';
      if (this._remLevel === 0) {
        patch.bigText = '守望中 · ' + this._seats.length + ' 位';
        patch.bigNote = '下次回看 5 分钟后 · SEEN 确认看过了 · SCAN 报门口方位';
      } else if (this._remLevel === 1) {
        patch.bigText = '该回看了';
        patch.bigNote = '该回看茶水位了（横幅，未出声）· SEEN 确认看过了';
      } else if (this._remLevel === 2) {
        patch.bigText = '该回看了';
        patch.bigNote = '该回看茶水位了（已出声一次）· SEEN 确认看过了';
      } else {
        patch.bigText = '去客厅看一眼';
        patch.bigNote = '很久没回看了（强提醒）· SEEN 确认看过了';
      }
    } else {
      patch.boxLabel = '◎ 本次招待小结 — 登记、回看、SCAN、提醒钉在下面';
      patch.bigLabel = '本次招待小结';
      var sm = this._summary || { seats: 0, seens: 0, scans: 0, reminds: 0 };
      patch.bigText = '登记 ' + sm.seats + ' 位';
      patch.bigNote = '回看 ' + sm.seens + ' 次 · SCAN ' + sm.scans + ' 次 · 提醒 ' + sm.reminds + ' 次 · 点 END 确认清空 · BACK 回守望';
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
      <text class="title">GUEST WATCH v1.0.0</text>
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
      <button class="btn btn-main" bindtap="regTap">REG</button>
      <button class="btn btn-main" bindtap="watchTap">WATCH</button>
      <button class="btn btn-main" bindtap="seenTap">SEEN</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="scanTap">SCAN</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
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
    <text class="foot2">没有水位检测、没有动静探测——「水空了」只能由你回看时自己判断，「门口有动静」是你察觉后按 SCAN 登记的，不是 Agent 检测到的；SCAN 报的方位是你预设的门口朝向（玄关方向），不是传感器探测；它不是监控/安防设备；座位朝向只是你登记时的头部方向，不是定位；只存本次招待会话，关掉即清；没有室内定位；零落盘</text>
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
