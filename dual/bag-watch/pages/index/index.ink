<script def>
{
  "navigationBarTitleText": "Bag Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '行李副线 — 主线等车/买东西，副线替你记着行李：看向行李方向停稳后 REG 登记，离开时过离开门才放行',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — 看向行李方向停稳，REG 登记副线',
    bigLabel: '行李副线 · 待机',
    bigText: '行李未登记',
    bigNote: '登记后每 5 分钟提醒回看 · DEMO 走演示 · TICK 走一格演示计时',
    permLine: 'PERM: 无权限 — 定时提醒 + 头部朝向确认，不拍照、不录音、不定位',
    rows: [],
    countLine: '回看确认 0 次 · 未确认提醒 0 次 · 喊停 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look toward the bag, hold steady, then REG',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | leaving | summary
    this._level = 0; // 0 none | 1 reminder banner | 2 escalated (TTS + brighter) | 3 strong (go look in person)
    this._bag = null; // { label, dir } — a heading the wearer registered, never a detected bag
    this._interval = 5 * 60 * 1000; // DEMO interval: 5 minutes between look-backs
    this._elapsedOffset = 0; // DEMO/advance clock: TICK adds one interval; real time flows on top
    this._startAt = 0;
    this._nextDue = 0;
    this._confirmed = 0;
    this._missed = 0;
    this._blocked = 0; // leave attempts stopped on the spot (END without the gate)
    this._gatePassed = false; // the wearer attested "I have it" at the leave gate
    this._gateFlash = false; // a blocked END just happened — banner stays until GOT/LEAVE/BACK
    this._log = []; // { label, text } — look-back confirmations + gate attestation, session memory
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 watching, 2 reminder, 3 gate, 4 blocked, 5 summary
    this._summary = null;
    this._nodLock = false;
    this._ticker = null;
    var self = this;
    try {
      this._ticker = setInterval(function () { self._checkDue(); }, 30000);
    } catch (e) {}
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: bag, counts, log, level,
    // gate and summary die with the page. Nothing was ever
    // written anywhere persistent, so there is nothing to
    // clean up - that IS the design. Close the agent and the
    // wait is gone; the next wait starts from a blank page.
    try { if (this._ticker) clearInterval(this._ticker); } catch (e) {}
    this._ticker = null;
    this._bag = null;
    this._confirmed = 0;
    this._missed = 0;
    this._blocked = 0;
    this._gatePassed = false;
    this._gateFlash = false;
    this._log = [];
    this._level = 0;
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this._nextDue = 0;
    this._elapsedOffset = 0;
  },

  _now() { return Date.now() + this._elapsedOffset; },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _elapsedText() {
    if (!this._startAt) return '第0分钟';
    var m = Math.floor((this._now() - this._startAt) / 60000);
    return '第' + (m + 1) + '分钟';
  },

  _remainingText() {
    if (!this._nextDue) return '未开始';
    var ms = this._nextDue - this._now();
    if (ms <= 0) return '已到回看时间';
    return '下次回看 ' + Math.ceil(ms / 60000) + ' 分钟后';
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
    // where confirmation is safe - REG in idle, GOT while
    // watching (look-back) or at the leave gate (attest "I
    // have it"), CONFIRM on the summary screen. A nod is the
    // wearer attesting; it is never sensor proof the bag is
    // in hand, because the page has no sensor that could
    // prove that.
    if (this._mode === 'idle') { this.regTap(); return; }
    if (this._mode === 'watching') { this.gotTap(); return; }
    if (this._mode === 'leaving') { this.gotTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.regTap();
      else if (this._mode === 'watching') this.gotTap();
      else if (this._mode === 'leaving') this.gotTap();
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

  // ---------- registration & watching ----------

  regTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: REG refused - a side line is already registered' });
      return;
    }
    this._bag = { label: '行李', dir: '登记时朝向' };
    this._mode = 'watching';
    this._level = 0;
    this._confirmed = 0;
    this._missed = 0;
    this._blocked = 0;
    this._gatePassed = false;
    this._gateFlash = false;
    this._log = [];
    this._focus = 0;
    this._summary = null;
    this._startAt = this._now();
    this._nextDue = this._now() + this._interval;
    this.setData({
      status: '守望进行中 — 副线已登记，每 5 分钟提醒回看一次；确认即重置计时',
      lastEvent: 'EVT: side line registered (bag heading) - next look-back in 5 minutes'
    });
    this._renderAll();
  },

  // One interval step, shared by the DEMO clock and the real
  // ticker: advancing the clock is the only thing that can
  // raise a reminder level, and every step is decided here.
  _checkDue() {
    if (this._mode !== 'watching') return;
    var steps = 0;
    while (this._now() >= this._nextDue && steps < 10) {
      steps++;
      this._nextDue += this._interval;
      if (this._level === 0) {
        this._level = 1;
        this.setData({
          status: '回看提醒 — 抬头看一眼行李那一格，确认后计时重置',
          lastEvent: 'EVT: look-back reminder (level 1 banner only, no TTS)'
        });
      } else if (this._level < 3) {
        this._level++;
        this._missed++;
        if (this._level === 2) {
          this._speakText('还没确认，请再看一眼行李');
          this.setData({
            status: '升级提醒 — 还没确认，TTS 已报一次，请再看一眼行李',
            lastEvent: 'EVT: escalated (level 2, one TTS) - missed ' + this._missed
          });
        } else {
          this._speakText('请起身去行李那一格看一眼');
          this.setData({
            status: '强提醒 — 请起身去行李那一格看一眼',
            lastEvent: 'EVT: strong reminder (level 3, one TTS) - missed ' + this._missed
          });
        }
      } else {
        this._missed++;
        this.setData({
          status: '强提醒 — 请起身去行李那一格看一眼',
          lastEvent: 'EVT: strong reminder still open (level 3) - missed ' + this._missed
        });
      }
    }
    if (steps > 0) this._renderAll();
  },

  tickTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: TICK refused - register a side line first' });
      return;
    }
    this._elapsedOffset += this._interval;
    this._checkDue();
    if (this._level === 0) {
      this.setData({ lastEvent: 'EVT: TICK - clock advanced one interval, no reminder due yet' });
      this._renderAll();
    }
  },

  gotTap() {
    if (this._mode === 'watching') {
      var early = this._level === 0;
      this._confirmed++;
      this._log.push({
        label: this._elapsedText(),
        text: early ? '提前回看确认（未到提醒时间）' : '回看确认（提醒等级' + this._level + '）'
      });
      this._focus = this._log.length - 1;
      this._level = 0;
      this._gateFlash = false;
      this._nextDue = this._now() + this._interval;
      this.setData({
        status: '守望进行中 — 回看已确认，计时重置，下次回看 5 分钟后',
        lastEvent: 'EVT: look-back confirmed (confirmed ' + this._confirmed + ') - timer reset'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'leaving') {
      // Leave-gate attestation: the wearer turned to the
      // registered heading, held steady and confirmed "I have
      // it". This is an attestation, not detection — the page
      // cannot know whether the bag is really in hand, and
      // nothing here claims it does.
      this._gatePassed = true;
      this._gateFlash = false;
      this._log.push({
        label: this._elapsedText(),
        text: '离开门确认：拿上了（你的表态，非检测）'
      });
      this._focus = this._log.length - 1;
      this._mode = 'watching';
      this.setData({
        status: '离开门已通过 — 随时可以点 END 结束，行李已由你确认拿上',
        lastEvent: 'EVT: leave gate passed (attestation) - END now allowed'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: GOT refused - no side line is being watched' });
  },

  leaveTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: LEAVE refused - register a side line first' });
      return;
    }
    this._mode = 'leaving';
    this._gateFlash = false;
    this.setData({
      status: '离开门 — 转头对准行李朝向停稳，点头/点按 GOT 确认拿上了',
      lastEvent: 'EVT: leave gate opened - turn to the registered heading and confirm with GOT'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: END refused - a summary is already open' });
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - no side line is being watched' });
      return;
    }
    if (this._gatePassed) {
      this._mode = 'summary';
      this._summary = {
        confirmed: this._confirmed,
        missed: this._missed,
        blocked: this._blocked,
        gatePassed: true,
        entries: this._log.length
      };
      this.setData({
        status: '本次等候小结 — 确认后清空本次记录',
        lastEvent: 'EVT: wait ended - summary ready (confirmed ' + this._summary.confirmed + ', missed ' + this._summary.missed + ', blocked ' + this._summary.blocked + ', gate passed)'
      });
      this._renderAll();
      return;
    }
    // The gate is the whole point: ending without it only
    // stops the wearer on the spot and names the bag as
    // unconfirmed. It never says "you may go", and it never
    // advances the session.
    this._blocked++;
    this._gateFlash = true;
    this._speakText('行李还没确认，先过离开门');
    this.setData({
      status: '喊停 — 行李还没确认，不能结束：先过离开门，GOT 确认拿上了再点 END',
      lastEvent: 'EVT: END blocked on the spot (blocked ' + this._blocked + ') - bag unconfirmed, gate not passed'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._bag = null;
    this._confirmed = 0;
    this._missed = 0;
    this._blocked = 0;
    this._gatePassed = false;
    this._gateFlash = false;
    this._log = [];
    this._level = 0;
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this._nextDue = 0;
    this._elapsedOffset = 0;
    this.setData({
      status: '行李副线 — 主线等车/买东西，副线替你记着行李：看向行李方向停稳后 REG 登记，离开时过离开门才放行',
      lastEvent: 'EVT: summary confirmed - wait cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      // The gate stays passed, so END still works.
      this._mode = 'watching';
      this._summary = null;
      this.setData({
        status: '守望进行中 — 副线已登记，每 5 分钟提醒回看一次；确认即重置计时',
        lastEvent: 'EVT: back to watching - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'leaving') {
      // Back cancels the leave attempt (not a block): the
      // wearer decided not to go yet, so the gate simply
      // closes and watching resumes.
      this._mode = 'watching';
      this._gateFlash = false;
      this.setData({
        status: '守望进行中 — 离开门已取消，继续守望行李',
        lastEvent: 'EVT: back to watching - leave gate cancelled, not counted as blocked'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - LEAVE opens the gate, END finishes only after it' });
  },

  nextTap() {
    if (this._log.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - log list is empty' });
      return;
    }
    this._focus = (this._focus + 1) % this._log.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> log ' + (this._focus + 1) });
  },

  prevTap() {
    if (this._log.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - log list is empty' });
      return;
    }
    this._focus = (this._focus - 1 + this._log.length) % this._log.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> log ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._log.length) return;
    this._focus = idx;
    var n = this._log[idx];
    this.setData({ lastEvent: 'EVT: 记录' + (idx + 1) + ' - ' + n.label + ' · ' + n.text });
    this._renderAll();
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '行李副线待机，看向行李方向停稳后按 REG 登记';
    } else if (this._mode === 'leaving') {
      line = this._gateFlash ? '行李还没确认，先过离开门' : '离开门：转头对准行李朝向，确认拿上了再走';
    } else if (this._mode === 'watching') {
      if (this._gateFlash) {
        line = '行李还没确认，先过离开门';
      } else if (this._level === 1) {
        line = '回看提醒：抬头看一眼行李';
      } else if (this._level === 2) {
        line = '还没确认，请再看一眼行李';
      } else if (this._level === 3) {
        line = '请起身去行李那一格看一眼';
      } else if (this._gatePassed) {
        line = '离开门已通过，行李已由你确认拿上，随时可以结束';
      } else {
        line = '守望进行中，行李 ' + (this._bag ? this._bag.label : '') + '，' + this._remainingText() + '，回看确认 ' + this._confirmed + ' 次';
      }
    } else if (this._summary) {
      line = '本次等候小结：回看确认 ' + this._summary.confirmed + ' 次，未确认提醒 ' + this._summary.missed + ' 次，喊停 ' + this._summary.blocked + ' 次，离开门已通过';
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
    if (this._mode === 'watching' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user side line is being watched' });
      return;
    }
    if (this._mode === 'leaving' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user side line is being watched' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._bag = { label: '黑色背包（DEMO 示例）', dir: '登记时朝向' };
      this._mode = 'watching';
      this._level = 0;
      this._confirmed = 0;
      this._missed = 0;
      this._blocked = 0;
      this._gatePassed = false;
      this._gateFlash = false;
      this._log = [];
      this._focus = 0;
      this._summary = null;
      this._startAt = this._now();
      this._nextDue = this._now() + this._interval;
      this.setData({
        status: 'DEMO - 守望进行中（示例行李，非真实登记）',
        lastEvent: 'EVT: DEMO stage 1 - side line registered (black backpack DEMO sample)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this.tickTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - look-back reminder (level 1 banner only, no TTS)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      // Confirm the look-back, then open the leave gate.
      this._demoStage = 3;
      this.gotTap();
      this.leaveTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - look-back confirmed, leave gate opened' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      // Try to end without the gate: stopped on the spot.
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - END blocked on the spot (blocked 1), bag unconfirmed' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.gotTap();
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary (confirmed 1, missed 0, blocked 1, gate passed, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._log.length; i++) {
      var n = this._log[i];
      rows.push({
        idx: i,
        name: '记录' + (i + 1) + ' · ' + n.label,
        detail: n.text,
        flag: '✓',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '回看确认 ' + this._confirmed + ' 次 · 未确认提醒 ' + this._missed + ' 次 · 喊停 ' + this._blocked + ' 次' +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — 看向行李方向停稳，REG 登记副线';
      patch.bigLabel = '行李副线 · 待机';
      patch.bigText = '行李未登记';
      patch.bigNote = '登记后每 5 分钟提醒回看 · DEMO 走演示 · TICK 走一格演示计时';
    } else if (this._mode === 'watching') {
      var bagText = this._bag ? this._bag.label + '（' + this._bag.dir + '）' : '行李';
      if (this._gateFlash) {
        patch.boxLabel = '◎ 喊停 — 行李还没确认，不能结束：先过离开门，GOT 确认拿上了再点 END';
        patch.bigLabel = '喊停';
        patch.bigText = '还没确认！';
        patch.bigNote = '行李：' + bagText + ' · 先点 LEAVE 过离开门，GOT 确认拿上了再结束';
      } else if (this._level === 1) {
        patch.boxLabel = '◎ 回看提醒 — 抬头看一眼行李那一格，确认后计时重置';
        patch.bigLabel = '回看提醒';
        patch.bigText = '看一眼行李';
        patch.bigNote = '行李：' + bagText + ' · GOT 确认还在 · 未确认会升级';
      } else if (this._level === 2) {
        patch.boxLabel = '◎ 升级提醒 — 还没确认，TTS 已报一次，请再看一眼行李';
        patch.bigLabel = '升级提醒';
        patch.bigText = '还没确认';
        patch.bigNote = '行李：' + bagText + ' · GOT 确认还在 · 再不确认会请你起身去看';
      } else if (this._level === 3) {
        patch.boxLabel = '◎ 强提醒 — 请起身去行李那一格看一眼';
        patch.bigLabel = '请起身去看一眼';
        patch.bigText = '起身去看一眼';
        patch.bigNote = '行李：' + bagText + ' · GOT 确认还在';
      } else if (this._gatePassed) {
        patch.boxLabel = '◎ 离开门已通过 — 随时可以点 END 结束，行李已由你确认拿上';
        patch.bigLabel = '离开门已通过';
        patch.bigText = '拿上了 ✓';
        patch.bigNote = '行李：' + bagText + ' · END 结束本次等候 · 这是你本人的表态，非检测';
      } else {
        patch.boxLabel = '◎ 守望进行中 — 副线已登记，每 5 分钟提醒回看一次；确认即重置计时';
        patch.bigLabel = '守望进行中';
        patch.bigText = this._remainingText();
        patch.bigNote = '行李：' + bagText + ' · 回看确认 ' + this._confirmed + ' 次 · GOT 确认还在';
      }
    } else if (this._mode === 'leaving') {
      var bagText2 = this._bag ? this._bag.label + '（' + this._bag.dir + '）' : '行李';
      if (this._gateFlash) {
        patch.boxLabel = '◎ 喊停 — 行李还没确认，不能结束：GOT 确认拿上了再点 END';
        patch.bigLabel = '喊停';
        patch.bigText = '还没确认！';
        patch.bigNote = '行李：' + bagText2 + ' · 转头对准行李朝向停稳，GOT 确认拿上了再结束';
      } else {
        patch.boxLabel = '◎ 离开门 — 转头对准行李朝向停稳，点头/点按 GOT 确认拿上了';
        patch.bigLabel = '离开门';
        patch.bigText = '拿上了吗？';
        patch.bigNote = '行李：' + bagText2 + ' · GOT = 我拿上了（你的表态） · 未确认点 END 会喊停';
      }
    } else {
      patch.boxLabel = '◎ 本次等候小结';
      patch.bigLabel = '本次等候小结';
      var s = this._summary || { confirmed: 0, missed: 0, blocked: 0, gatePassed: false, entries: 0 };
      patch.bigText = '确认 ' + s.confirmed + ' 次 · 未确认 ' + s.missed + ' 次';
      patch.bigNote = '回看记录 ' + s.entries + ' 条 · 喊停 ' + s.blocked + ' 次 · 离开门' + (s.gatePassed ? '已通过' : '未通过') + ' · 确认后清空本次记录';
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
      <text class="title">BAG WATCH v1.0.0</text>
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
      <button class="btn" bindtap="tickTap">TICK</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="gotTap">GOT</button>
      <button class="btn btn-main" bindtap="leaveTap">LEAVE</button>
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
    <text class="foot2">不是防盗/防丢设备：没有行李检测、没有定位、没有步数/移动感知——「要走了」只能由你自己点，「拿上了」只是你转头对准登记朝向 + 确认的表态，不是传感器证明行李在手；它不知道行李是否真的在手，也不能保证行李不丢 · 本次等候数据只存会话内存，关掉即清 · 无权限：不拍照、不录音、不定位 · 计时是演示 5 分钟一格，到时提醒、未确认才升级 · 离开门未通过时点结束只会喊停，绝不报「可以走了」</text>
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
