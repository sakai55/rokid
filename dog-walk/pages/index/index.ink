<script def>
{
  "navigationBarTitleText": "Dog Walk"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '遛狗副线 — 主线是走路和看狗，副线替你记着清单和狗的事：出门清单逐项确认，狗停下时点 STOP 处理，回家前过回家门才放行',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — 出门清单：便袋 · 水 · 牵绳，CHECK 逐项确认',
    bigLabel: '遛狗副线 · 待机',
    bigText: '出门清单 0/3',
    bigNote: '清单齐了点 WALK 出发 · 狗停下点 STOP · DEMO 走演示',
    permLine: 'PERM: 无权限 — 清单确认 + 狗停点按，不拍照、不录音、不定位',
    rows: [],
    countLine: '狗停 0 次 · 已清理 0 次 · 喝水 0 次 · 待清理点位 0 处 · 喊停 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - confirm the going-out checklist item by item',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | walking | stopped | home | summary
    this._checklist = [
      { name: '便袋', done: false },
      { name: '水', done: false },
      { name: '牵绳', done: false }
    ];
    this._gate = null; // [{ name, done, point }] — home-gate items, built on HOME
    this._pending = []; // [{ label, dir }] — poop spots marked for later cleanup, by gaze direction
    this._log = []; // { label, text } — stops resolved + gate attestation, session memory
    this._focus = 0; // into checklist (idle), gate items (home), or log rows (else)
    this._stops = 0;
    this._cleaned = 0;
    this._drinks = 0;
    this._blocked = 0; // end attempts stopped on the spot (END without the gate)
    this._gatePassed = false;
    this._gateFlash = false; // a blocked END just happened — banner stays until CHECK/BACK
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 walking, 2 stopped, 3 home gate, 4 blocked, 5 summary
    this._nodLock = false;
    this._startAt = 0;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: checklist, stops, pending
    // points, gate and summary die with the page. Nothing was
    // ever written anywhere persistent, so there is nothing to
    // clean up - that IS the design. Close the agent and the
    // walk is gone; the next walk starts from a blank page.
    this._checklist = [
      { name: '便袋', done: false },
      { name: '水', done: false },
      { name: '牵绳', done: false }
    ];
    this._gate = null;
    this._pending = [];
    this._log = [];
    this._focus = 0;
    this._stops = 0;
    this._cleaned = 0;
    this._drinks = 0;
    this._blocked = 0;
    this._gatePassed = false;
    this._gateFlash = false;
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
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

  _checklistDone() {
    for (var i = 0; i < this._checklist.length; i++) {
      if (!this._checklist[i].done) return false;
    }
    return true;
  },

  _missingChecklist() {
    var names = [];
    for (var i = 0; i < this._checklist.length; i++) {
      if (!this._checklist[i].done) names.push(this._checklist[i].name);
    }
    return names;
  },

  _missingGate() {
    var names = [];
    if (!this._gate) return names;
    for (var i = 0; i < this._gate.length; i++) {
      if (!this._gate[i].done) names.push(this._gate[i].name);
    }
    return names;
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
    // where confirmation is safe - CHECK on the going-out
    // checklist (idle) or the home gate (home), CONFIRM on the
    // summary screen. A nod never reports a dog stop and never
    // resolves one: a stop is only ever reported by your own
    // STOP tap, and poop/water/mark are choices, not a default
    // a nod could accidentally pick.
    if (this._mode === 'idle') { this.checkTap(); return; }
    if (this._mode === 'home') { this.checkTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored here - STOP reports a stop, POOP/DRINK/MARK resolve it' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.checkTap();
      else if (this._mode === 'home') this.checkTap();
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

  // ---------- checklist & walking ----------

  checkTap() {
    if (this._mode === 'idle') {
      var item = this._checklist[this._focus];
      if (!item) {
        this.setData({ lastEvent: 'EVT: CHECK refused - no checklist item focused' });
        return;
      }
      if (item.done) {
        this.setData({ lastEvent: 'EVT: CHECK - ' + item.name + ' already confirmed' });
        return;
      }
      item.done = true;
      this.setData({
        status: this._checklistDone()
          ? '出门清单齐了 — 点 WALK 出发遛狗'
          : '出门清单 — ' + item.name + '已确认，继续确认下一项',
        lastEvent: 'EVT: checklist confirmed - ' + item.name
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'home') {
      if (!this._gate || !this._gate[this._focus]) {
        this.setData({ lastEvent: 'EVT: CHECK refused - no gate item focused' });
        return;
      }
      var g = this._gate[this._focus];
      if (g.done) {
        this.setData({ lastEvent: 'EVT: CHECK - ' + g.name + ' already confirmed' });
        return;
      }
      g.done = true;
      if (g.point) {
        // Clearing a pending point here is what "回程按朝向逐个
        // 提醒清理" means in practice: each marked spot is its
        // own gate item, confirmed one by one, and only then is
        // the point gone.
        for (var i = 0; i < this._pending.length; i++) {
          if (this._pending[i].label === g.point.label) {
            this._pending.splice(i, 1);
            break;
          }
        }
      }
      if (this._missingGate().length === 0) {
        this._gatePassed = true;
        this._gateFlash = false;
        this._log.push({
          label: this._elapsedText(),
          text: '回家门确认：全部核对项已确认（你的表态，非检测）'
        });
        this._focus = this._log.length - 1;
        this._mode = 'walking';
        this.setData({
          status: '回家门已通过 — 随时可以点 END 结束，本次遛狗已由你核对',
          lastEvent: 'EVT: home gate passed (attestation) - END now allowed'
        });
      } else {
        this.setData({
          status: '回家门 — 还缺：' + this._missingGate().join('、'),
          lastEvent: 'EVT: gate item confirmed - ' + g.name
        });
      }
      this._renderAll();
      return;
    }
    if (this._mode === 'summary') {
      this._confirmSummary();
      return;
    }
    this.setData({ lastEvent: 'EVT: CHECK refused here - STOP reports a stop, POOP/DRINK/MARK resolve it' });
  },

  walkTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: WALK refused - a walk is already under way or finished' });
      return;
    }
    var missing = this._missingChecklist();
    if (missing.length > 0) {
      this.setData({ lastEvent: 'EVT: WALK refused - checklist missing: ' + missing.join('、') });
      return;
    }
    this._mode = 'walking';
    this._startAt = this._now();
    this._log.push({ label: this._elapsedText(), text: '出发遛狗（出门清单 3/3）' });
    this._focus = this._log.length - 1;
    this.setData({
      status: '遛狗进行中 — 狗停下时点 STOP 处理，回家前点 HOME 过回家门',
      lastEvent: 'EVT: walk started (checklist 3/3)'
    });
    this._renderAll();
  },

  // ---------- dog stops ----------

  stopTap() {
    if (this._mode !== 'walking') {
      this.setData({ lastEvent: 'EVT: STOP refused - start a walk first, or resolve the current stop' });
      return;
    }
    this._stops++;
    this._mode = 'stopped';
    this.setData({
      status: '狗停下了 — 看一眼在做什么：便便点 POOP，喝水点 DRINK，先记下点位点 MARK，只是闻闻点 BACK',
      lastEvent: 'EVT: dog stopped (stop ' + this._stops + ', reported by your tap, not detected)'
    });
    this._renderAll();
  },

  poopTap() {
    if (this._mode !== 'stopped') {
      this.setData({ lastEvent: 'EVT: POOP refused - no stop is open; STOP reports one first' });
      return;
    }
    this._cleaned++;
    this._log.push({
      label: this._elapsedText(),
      text: '狗停下：便便已清理（你的表态，非检测）'
    });
    this._focus = this._log.length - 1;
    this._mode = 'walking';
    this.setData({
      status: '遛狗进行中 — 便便已清理，继续走；回家前点 HOME 过回家门',
      lastEvent: 'EVT: stop resolved - poop cleaned (cleaned ' + this._cleaned + ')'
    });
    this._renderAll();
  },

  drinkTap() {
    if (this._mode !== 'stopped') {
      this.setData({ lastEvent: 'EVT: DRINK refused - no stop is open; STOP reports one first' });
      return;
    }
    this._drinks++;
    this._log.push({
      label: this._elapsedText(),
      text: '狗停下：喝水已给'
    });
    this._focus = this._log.length - 1;
    this._mode = 'walking';
    this.setData({
      status: '遛狗进行中 — 水已给，继续走；回家前点 HOME 过回家门',
      lastEvent: 'EVT: stop resolved - water given (drinks ' + this._drinks + ')'
    });
    this._renderAll();
  },

  markTap() {
    if (this._mode !== 'stopped') {
      this.setData({ lastEvent: 'EVT: MARK refused - no stop is open; STOP reports one first' });
      return;
    }
    var point = { label: '待清理点位' + (this._pending.length + 1), dir: '停留时朝向' };
    this._pending.push(point);
    this._log.push({
      label: this._elapsedText(),
      text: '狗停下：便便点位已记下（' + point.label + '，回程逐个提醒清理）'
    });
    this._focus = this._log.length - 1;
    this._mode = 'walking';
    this.setData({
      status: '遛狗进行中 — 点位已记下（待清理 ' + this._pending.length + ' 处），回家门会逐个提醒清理',
      lastEvent: 'EVT: stop resolved - cleanup point marked (pending ' + this._pending.length + ')'
    });
    this._renderAll();
  },

  // ---------- home gate & ending ----------

  homeTap() {
    if (this._mode !== 'walking') {
      this.setData({ lastEvent: 'EVT: HOME refused - start a walk first, or resolve the current stop' });
      return;
    }
    var gate = [
      { name: '便袋已用/未用已确认', done: false, point: null },
      { name: '水已给已确认', done: false, point: null }
    ];
    for (var i = 0; i < this._pending.length; i++) {
      gate.push({ name: this._pending[i].label + '已清理', done: false, point: this._pending[i] });
    }
    this._gate = gate;
    this._focus = 0;
    this._gateFlash = false;
    this._mode = 'home';
    this.setData({
      status: '回家门 — CHECK 逐项确认：便袋、水' + (this._pending.length > 0 ? '、待清理点位逐个清理' : '') + '；未确认点 END 会喊停',
      lastEvent: 'EVT: home gate opened - ' + gate.length + ' items to confirm'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: END refused - a summary is already open' });
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - no walk is under way' });
      return;
    }
    if (this._mode === 'stopped') {
      this.setData({ lastEvent: 'EVT: END refused - resolve the stop first: POOP/DRINK/MARK, or BACK to keep walking' });
      return;
    }
    if (this._gatePassed) {
      this._mode = 'summary';
      this._summary = {
        stops: this._stops,
        cleaned: this._cleaned,
        drinks: this._drinks,
        pendingLeft: this._pending.length,
        blocked: this._blocked,
        gatePassed: true,
        entries: this._log.length
      };
      this.setData({
        status: '本次遛狗小结 — 确认后清空本次记录',
        lastEvent: 'EVT: walk ended - summary ready (stops ' + this._summary.stops + ', cleaned ' + this._summary.cleaned + ', blocked ' + this._summary.blocked + ', gate passed)'
      });
      this._renderAll();
      return;
    }
    // The gate is the whole point: ending without it only stops
    // the wearer on the spot and names the missing items. It
    // never says "you may go home", and it never advances the
    // session.
    this._blocked++;
    this._gateFlash = true;
    var missing = this._mode === 'home' ? this._missingGate() : ['回家门（点 HOME 核对）'];
    this._speakText('还没过回家门，缺：' + missing.join('、'));
    this.setData({
      status: '喊停 — 还没过回家门，不能结束：缺 ' + missing.join('、'),
      lastEvent: 'EVT: END blocked on the spot (blocked ' + this._blocked + ') - missing: ' + missing.join('、')
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._checklist = [
      { name: '便袋', done: false },
      { name: '水', done: false },
      { name: '牵绳', done: false }
    ];
    this._gate = null;
    this._pending = [];
    this._log = [];
    this._focus = 0;
    this._stops = 0;
    this._cleaned = 0;
    this._drinks = 0;
    this._blocked = 0;
    this._gatePassed = false;
    this._gateFlash = false;
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this.setData({
      status: '遛狗副线 — 主线是走路和看狗，副线替你记着清单和狗的事：出门清单逐项确认，狗停下时点 STOP 处理，回家前过回家门才放行',
      lastEvent: 'EVT: summary confirmed - walk cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'stopped') {
      // Sniff-and-go: the stop happened, but nothing needed
      // doing. Logged as such, so the stop count stays honest.
      this._log.push({
        label: this._elapsedText(),
        text: '狗停下：闻了闻，继续走'
      });
      this._focus = this._log.length - 1;
      this._mode = 'walking';
      this.setData({
        status: '遛狗进行中 — 只是闻了闻，继续走；回家前点 HOME 过回家门',
        lastEvent: 'EVT: stop resolved - sniffed and kept walking'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'home') {
      // Back cancels the home-gate attempt (not a block): the
      // wearer decided not to go home yet. Gate progress is
      // discarded, but pending points stay — they still need
      // clearing, and the next HOME rebuilds the gate from them.
      this._gate = null;
      this._gateFlash = false;
      this._mode = 'walking';
      this.setData({
        status: '遛狗进行中 — 回家门已取消，继续走；点位仍在，下次 HOME 重新核对',
        lastEvent: 'EVT: back to walking - home gate cancelled, not counted as blocked'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'summary') {
      // Back from the summary returns to walking without
      // deleting anything; the summary is rebuilt on END.
      // The gate stays passed, so END still works.
      this._mode = 'walking';
      this._summary = null;
      this.setData({
        status: '遛狗进行中 — 回家门已通过，随时可以点 END 结束',
        lastEvent: 'EVT: back to walking - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - WALK starts a walk, HOME opens the gate' });
  },

  _focusLen() {
    if (this._mode === 'idle') return this._checklist.length;
    if (this._mode === 'home') return this._gate ? this._gate.length : 0;
    return this._log.length;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
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
    this.setData({ lastEvent: 'EVT: focus -> item ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      var missing = this._missingChecklist();
      line = missing.length > 0
        ? '出门清单还缺：' + missing.join('、') + '，逐项确认后点开始遛狗'
        : '出门清单齐了，点开始遛狗';
    } else if (this._mode === 'walking') {
      if (this._gateFlash) {
        line = '还没过回家门，先点回家门核对';
      } else if (this._gatePassed) {
        line = '回家门已通过，随时可以结束';
      } else {
        line = '遛狗进行中，狗停 ' + this._stops + ' 次，已清理 ' + this._cleaned + ' 次，待清理点位 ' + this._pending.length + ' 处';
      }
    } else if (this._mode === 'stopped') {
      line = '狗停下了，看一眼在做什么：便便、喝水，还是先记下点位';
    } else if (this._mode === 'home') {
      line = this._gateFlash
        ? '回家门还没通过，缺：' + this._missingGate().join('、')
        : '回家门：逐项确认便袋、水和待清理点位';
    } else if (this._summary) {
      line = '本次遛狗小结：狗停 ' + this._summary.stops + ' 次，已清理 ' + this._summary.cleaned + ' 次，喊停 ' + this._summary.blocked + ' 次，回家门已通过';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user walk is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._checklist.some(function (c) { return c.done; })) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user checklist is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      for (var i = 0; i < this._checklist.length; i++) this._checklist[i].done = true;
      this._mode = 'walking';
      this._startAt = this._now();
      this._log.push({ label: this._elapsedText(), text: '出发遛狗（DEMO 示例清单 3/3）' });
      this._focus = this._log.length - 1;
      this.setData({
        status: 'DEMO - 遛狗进行中（示例清单，非真实确认）',
        lastEvent: 'EVT: DEMO stage 1 - checklist done (DEMO sample), walk started'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this.stopTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - dog stopped (stop 1)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      // Resolve the stop, then open the home gate.
      this._demoStage = 3;
      this.poopTap();
      this.homeTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - poop cleaned, home gate opened' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      // Try to end without the gate: stopped on the spot.
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - END blocked on the spot (blocked 1), gate items unconfirmed' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      while (this._gate && this._missingGate().length > 0) {
        this.checkTap();
        if (this._mode !== 'home') break;
        // After each CHECK the focus stays; move to the next
        // unconfirmed item explicitly.
        var next = -1;
        for (var j = 0; j < this._gate.length; j++) {
          if (!this._gate[j].done) { next = j; break; }
        }
        if (next < 0) break;
        this._focus = next;
      }
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary (stops 1, cleaned 1, blocked 1, gate passed, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, n;
    if (this._mode === 'idle') {
      for (i = 0; i < this._checklist.length; i++) {
        n = this._checklist[i];
        rows.push({
          idx: i,
          name: '清单' + (i + 1) + ' · ' + n.name,
          detail: n.done ? '已确认' : '未确认（CHECK 确认）',
          flag: n.done ? '✓' : '○',
          cls: 'row'
        });
      }
    } else if (this._mode === 'home' && this._gate) {
      for (i = 0; i < this._gate.length; i++) {
        n = this._gate[i];
        rows.push({
          idx: i,
          name: '核对' + (i + 1) + ' · ' + n.name,
          detail: n.done ? '已确认' : '未确认（CHECK 确认）',
          flag: n.done ? '✓' : '○',
          cls: 'row'
        });
      }
    } else {
      for (i = 0; i < this._log.length; i++) {
        n = this._log[i];
        rows.push({
          idx: i,
          name: '记录' + (i + 1) + ' · ' + n.label,
          detail: n.text,
          flag: '✓',
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    var doneCount = 0;
    for (i = 0; i < this._checklist.length; i++) if (this._checklist[i].done) doneCount++;
    patch.countLine = '狗停 ' + this._stops + ' 次 · 已清理 ' + this._cleaned + ' 次 · 喝水 ' + this._drinks + ' 次' +
      ' · 待清理点位 ' + this._pending.length + ' 处 · 喊停 ' + this._blocked + ' 次' +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — 出门清单：便袋 · 水 · 牵绳，CHECK 逐项确认';
      patch.bigLabel = '遛狗副线 · 待机';
      patch.bigText = '出门清单 ' + doneCount + '/3';
      patch.bigNote = doneCount === 3 ? '清单齐了，点 WALK 出发 · DEMO 走演示' : 'NEXT/PREV 换项，CHECK 确认 · 清单齐了点 WALK 出发';
    } else if (this._mode === 'walking') {
      if (this._gateFlash) {
        patch.boxLabel = '◎ 喊停 — 还没过回家门，不能结束：先点 HOME 核对，全部确认再点 END';
        patch.bigLabel = '喊停';
        patch.bigText = '还没通过！';
        patch.bigNote = '待清理点位 ' + this._pending.length + ' 处 · 先点 HOME 过回家门';
      } else if (this._gatePassed) {
        patch.boxLabel = '◎ 回家门已通过 — 随时可以点 END 结束，本次遛狗已由你核对';
        patch.bigLabel = '回家门已通过';
        patch.bigText = '可以回家了 ✓';
        patch.bigNote = '狗停 ' + this._stops + ' 次 · 已清理 ' + this._cleaned + ' 次 · END 结束本次遛狗 · 这是你本人的表态，非检测';
      } else {
        patch.boxLabel = '◎ 遛狗进行中 — 狗停下时点 STOP 处理，回家前点 HOME 过回家门';
        patch.bigLabel = '遛狗进行中';
        patch.bigText = '狗停 ' + this._stops + ' 次';
        patch.bigNote = '已清理 ' + this._cleaned + ' 次 · 待清理点位 ' + this._pending.length + ' 处 · STOP 报狗停';
      }
    } else if (this._mode === 'stopped') {
      patch.boxLabel = '◎ 狗停下了 — 看一眼在做什么：便便点 POOP，喝水点 DRINK，先记下点位点 MARK，只是闻闻点 BACK';
      patch.bigLabel = '狗停下了';
      patch.bigText = '看一眼在做什么';
      patch.bigNote = '第 ' + this._stops + ' 次停下 · POOP 已清理 / DRINK 已给 / MARK 记点位 / BACK 只是闻闻';
    } else if (this._mode === 'home') {
      var missing = this._missingGate();
      if (this._gateFlash) {
        patch.boxLabel = '◎ 喊停 — 回家门还没通过，不能结束：缺 ' + missing.join('、');
        patch.bigLabel = '喊停';
        patch.bigText = '还没通过！';
        patch.bigNote = '缺：' + missing.join('、') + ' · CHECK 逐项确认后再点 END';
      } else {
        patch.boxLabel = '◎ 回家门 — CHECK 逐项确认：便袋、水' + (this._pending.length > 0 ? '、待清理点位逐个清理' : '') + '；未确认点 END 会喊停';
        patch.bigLabel = '回家门';
        patch.bigText = '待确认 ' + missing.length + ' 项';
        patch.bigNote = 'NEXT/PREV 换项，CHECK 确认 · 全部确认后自动通过，END 结束';
      }
    } else {
      patch.boxLabel = '◎ 本次遛狗小结';
      patch.bigLabel = '本次遛狗小结';
      var s = this._summary || { stops: 0, cleaned: 0, drinks: 0, pendingLeft: 0, blocked: 0, gatePassed: false, entries: 0 };
      patch.bigText = '狗停 ' + s.stops + ' 次 · 清理 ' + s.cleaned + ' 次';
      patch.bigNote = '喝水 ' + s.drinks + ' 次 · 待清理点位剩余 ' + s.pendingLeft + ' 处 · 喊停 ' + s.blocked + ' 次 · 回家门' + (s.gatePassed ? '已通过' : '未通过') + ' · 确认后清空本次记录';
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
      <text class="title">DOG WALK v1.0.0</text>
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
      <button class="btn btn-main" bindtap="checkTap">CHECK</button>
      <button class="btn btn-main" bindtap="walkTap">WALK</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="stopTap">STOP</button>
      <button class="btn btn-main" bindtap="poopTap">POOP</button>
      <button class="btn" bindtap="drinkTap">DRINK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="homeTap">HOME</button>
      <button class="btn" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="prevTap">PREV</button>
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
    <text class="foot2">不是宠物健康/行为监测设备：没有狗行为识别、没有定位、没有步数/移动感知——「狗停下了」只能由你自己点 STOP（或 DEMO 演示），Agent 不检测狗是否真的停下；「便便已清理」只是你本人的表态，不是传感器证明；待清理点位只是你停留时朝向的提醒锚，不是狗便的位置记录 · 本次遛狗数据只存会话内存，关掉即清 · 无权限：不拍照、不录音、不定位 · 回家门未通过时点结束只会喊停并点名缺项，绝不报「可以回家了」</text>
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
