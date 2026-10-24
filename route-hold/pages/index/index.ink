<script def>
{
  "navigationBarTitleText": "Route Hold"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '问路听来的路线 — 你复述一遍，它拆成步骤替你记着走',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 路线编辑 — 一步步说，或一口气说整条让它拆',
    bigLabel: '（还没有路线）',
    bigText: '----',
    bigCls: 'bignum',
    bigNote: 'DICT 说一步 / SPLIT 说整条 / DEMO 演示',
    micLine: 'MIC CHECK: not run',
    rows: [
      { name: '(no steps)', detail: 'DICT one step in your own voice, or SPLIT a whole route - or DEMO', flag: '', cls: 'row' }
    ],
    countLine: 'ROUTE: 0/8 步 · 文字存本机 · 关掉再开还在',
    lastEvent: 'EVT: ready - a step joins the route only after YOU confirm it',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'build'; // build | pending (one heard step) | review (split proposals) | walk
    this._steps = this._loadSteps(); // confirmed TEXT steps only: {text}
    this._focus = this._steps.length ? 0 : -1; // build-mode focus (DEL target)
    this._pending = null; // unconfirmed heard step (never in the route yet)
    this._review = null; // split proposals, NOT saved yet
    this._reviewFocus = 0;
    this._cur = 0; // walk position: step index; == steps.length means steps finished
    this._arrivedSaid = false;
    this._peek = false; // next-step peek, OFF by default, walk mode only
    this._delArmIdx = -1; // two-step step delete (build)
    this._resetArm = false; // two-step walk reset
    this._armTimer = null;
    this._nodLock = false;
    this._demo = false;
    this._demoStep = 0;
    this._renderAll();
    this.setData({
      lastEvent: 'EVT: ' + this._steps.length + ' saved step(s) restored from this device'
    });
  },

  onShow() {},

  onHide() {
    this._stopDictRec();
    this._disarm();
  },

  onUnload() {
    this._stopDictRec();
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
    this._saveSteps();
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
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Nod discipline in THIS agent: a steady nod means ONE thing -
    // "this step is done" - and only while walking. It is the
    // wearer's judgement that advances the route: the agent has no
    // position and never advances on its own. A nod never confirms
    // a dictation, never accepts a review, never goes back, never
    // deletes.
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: nod in DEMO - the DEMO button walks the demo route' });
      return;
    }
    if (this._mode === 'walk') {
      this._advance('nod');
      return;
    }
    if (this._mode === 'pending') {
      this.setData({ lastEvent: 'EVT: nod ignored in confirm - press OK to save the step, nod never saves' });
      return;
    }
    if (this._mode === 'review') {
      this.setData({ lastEvent: 'EVT: nod ignored in review - OK accepts the steps, nod never accepts' });
      return;
    }
    this.setData({ lastEvent: 'EVT: nod - nod advances only while walking (WALK starts)' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.okTap();
    } else if (code === 'ArrowDown') {
      this._forward(1);
    } else if (code === 'ArrowUp') {
      this._forward(-1);
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  // Display truncation is honest: a long step shows its first 12
  // characters + a marker, the FULL text stays in storage and is
  // what SPEAK / the walk advance reads out.
  _disp(text) {
    var s = String(text || '');
    return s.length > 12 ? s.slice(0, 12) + '…' : s;
  },

  _truncated(text) {
    return String(text || '').length > 12;
  },

  // ---------- persistence (wx sync storage, key 'routeHold', TEXT ONLY) ----------
  // Dictate at the street corner, walk later: the steps are {text}
  // plain text in this app's local storage on the glasses, so the
  // route survives closing the agent. The WALK POSITION is not
  // stored - reopening starts editing, and a walk restarts at
  // step 1. Nothing else is stored, no audio, ever.

  _loadSteps() {
    try {
      var raw = wx.getStorageSync('routeHold');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 8; i++) {
        var it = raw[i];
        if (it && typeof it.text === 'string' && it.text) {
          out.push({ text: String(it.text).slice(0, 30) });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveSteps() {
    if (this._demo) return; // demo route never touches real storage
    try {
      wx.setStorageSync('routeHold', this._steps || []);
    } catch (e) { /* storage unavailable on this host: steps stay in memory */ }
  },

  // ---------- two-step arming (step delete / walk reset) ----------

  _disarm() {
    this._delArmIdx = -1;
    this._resetArm = false;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  _arm(kind, idx) {
    this._disarm();
    if (kind === 'del') this._delArmIdx = idx;
    if (kind === 'reset') this._resetArm = true;
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._delArmIdx === idx || self._resetArm) {
        self._disarm();
        self.setData({ lastEvent: 'EVT: disarmed (timeout) - nothing deleted, no reset' });
        self._renderAll();
      }
    }, 6000);
  },

  // ---------- focus / step movement (swipes + +1/-1 buttons) ----------
  // Build: move the edit focus. Review: move the proposal focus.
  // Walk: +1 advances a step, -1 goes back a step - the same
  // judgement keys as nod/Enter, for when the head should stay up.

  _forward(delta) {
    if (this.data.busy) return;
    if (this._mode === 'pending') {
      this.setData({ lastEvent: 'EVT: focus locked on the pending step - OK saves it, DEL drops it' });
      return;
    }
    if (this._mode === 'walk') {
      if (delta > 0) this._advance('swipe');
      else this._back('swipe');
      return;
    }
    this._disarm();
    if (this._mode === 'review') {
      var rn = (this._review || []).length;
      if (!rn) return;
      this._reviewFocus = (((this._reviewFocus + delta) % rn) + rn) % rn;
      this.setData({
        lastEvent: 'EVT: review focus ' + (this._reviewFocus + 1) + '/' + rn + ' - ' + this._disp(this._review[this._reviewFocus].text)
      });
      this._renderAll();
      return;
    }
    // build
    if (!this._steps.length) {
      this.setData({ lastEvent: 'EVT: no steps to move through yet' });
      return;
    }
    var n = this._steps.length;
    var cur = this._focus < 0 ? 0 : this._focus;
    this._focus = (((cur + delta) % n) + n) % n;
    this.setData({
      lastEvent: 'EVT: focus step ' + (this._focus + 1) + '/' + n + ' - ' + this._disp(this._steps[this._focus].text)
    });
    this._renderAll();
  },

  plus1Tap() { this._forward(1); },
  minus1Tap() { this._forward(-1); },

  // ---------- WALK: start / exit / advance / back / reset ----------

  _startWalk(how) {
    if (!this._steps.length) {
      this.setData({
        status: '还没有路线 — 先 DICT 说一步，或 SPLIT 一口气说整条',
        lastEvent: 'EVT: WALK refused - no steps saved yet'
      });
      this._renderAll();
      return;
    }
    this._disarm();
    this._mode = 'walk';
    this._cur = 0;
    this._peek = false;
    this._arrivedSaid = false;
    this._speakText('开始走。第1步：' + this._steps[0].text);
    this.setData({
      status: '走路中 — 眼前只有当前一步，你判断走完才推进',
      lastEvent: 'EVT: WALK started by ' + how + ' at step 1/' + this._steps.length
    });
    this._renderAll();
  },

  _exitWalk(how) {
    this._mode = 'build';
    this._focus = this._steps.length ? Math.min(this._cur, this._steps.length - 1) : -1;
    this._peek = false;
    this._disarm();
    this.setData({
      status: '回到编辑 — 路线没变，要改就 DICT / DEL',
      lastEvent: 'EVT: back to BUILD by ' + how + ' - steps unchanged'
    });
    this._renderAll();
  },

  // The ONLY way the route ever moves forward: the wearer says so
  // (nod / Enter / swipe). One input, one step.
  _advance(how) {
    if (this._mode !== 'walk') return;
    var n = this._steps.length;
    if (this._cur >= n) {
      this.setData({ lastEvent: 'EVT: advance ignored - steps already finished (DEL x2 resets, WALK exits)' });
      return;
    }
    this._peek = false;
    this._disarm();
    this._cur++;
    if (this._cur >= n) {
      // Steps finished. The wording is the honesty boundary of this
      // agent: the STEPS are done - whether you have actually
      // arrived is your judgement, it never claims arrival.
      if (!this._arrivedSaid) {
        this._arrivedSaid = true;
        this._speakText('路线走完了，应该到了');
      }
      this.setData({
        status: '步骤全部走完 — 到没到由你判断',
        lastEvent: 'EVT: steps finished by ' + how + ' - route done, arrival is YOUR judgement'
      });
    } else {
      this._speakText('第' + (this._cur + 1) + '步：' + this._steps[this._cur].text);
      this.setData({
        lastEvent: 'EVT: advanced by ' + how + ' to step ' + (this._cur + 1) + '/' + n
      });
    }
    this._renderAll();
  },

  _back(how) {
    if (this._mode !== 'walk') return;
    if (this._cur <= 0) {
      this.setData({ lastEvent: 'EVT: back ignored - already at step 1' });
      return;
    }
    this._peek = false;
    this._disarm();
    this._cur--;
    this._arrivedSaid = false; // going back re-arms the finish line
    this._speakText('退回第' + (this._cur + 1) + '步：' + this._steps[this._cur].text);
    this.setData({
      lastEvent: 'EVT: back by ' + how + ' to step ' + (this._cur + 1) + '/' + this._steps.length
    });
    this._renderAll();
  },

  _resetWalk() {
    this._cur = 0;
    this._peek = false;
    this._arrivedSaid = false;
    this._disarm();
    this._speakText('回到第一步：' + this._steps[0].text);
    this.setData({
      status: '已回到第一步 — 走错了就从头按步骤再走一遍',
      lastEvent: 'EVT: walk RESET to step 1 (two-step DEL)'
    });
    this._renderAll();
  },

  // PEEK: off by default, the walk shows ONLY the current step.
  // PEEK toggles a small look at the next step; any advance, back
  // or reset turns it off again - it is a glance, not a mode.
  peekTap() {
    if (this.data.busy) return;
    if (this._mode !== 'walk') {
      this.setData({ lastEvent: 'EVT: PEEK - only works while walking (the walk shows one step at a time)' });
      return;
    }
    if (this._cur >= this._steps.length) {
      this.setData({ lastEvent: 'EVT: PEEK - no next step, the steps are finished' });
      return;
    }
    this._peek = !this._peek;
    this.setData({
      lastEvent: this._peek
        ? 'EVT: PEEK on - next step shown small; advancing turns it off'
        : 'EVT: PEEK off - current step only'
    });
    this._renderAll();
  },

  walkTap() {
    if (this.data.busy) return;
    if (this._mode === 'walk') { this._exitWalk('WALK'); return; }
    if (this._mode === 'pending' || this._mode === 'review') {
      this.setData({
        status: '先处理待确认的内容：OK 存下，或 DEL 丢弃',
        lastEvent: 'EVT: WALK refused while a step/review is pending'
      });
      this._renderAll();
      return;
    }
    this._startWalk('WALK');
  },

  // ---------- OK (contextual primary, mirrors Enter) ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'pending') { this._confirmPending(); return; }
    if (this._mode === 'review') { this._acceptReview(); return; }
    if (this._mode === 'walk') { this._advance('Enter'); return; }
    // build: the primary action after storing a route is to walk it
    this._startWalk('OK');
  },

  // ---------- pending step: confirm / drop ----------

  _setPending(text, src) {
    this._pending = { text: text, src: src };
    this._mode = 'pending';
    this.setData({
      status: '听到这一步：「' + this._disp(text) + '」— 对了 OK 存下' +
        (this._truncated(text) ? '（显示截断，全文朗读为准）' : ''),
      lastEvent: 'EVT: pending "' + this._disp(text) + '" from ' + src + ' - NOT in the route yet'
    });
    this._renderAll();
  },

  _confirmPending() {
    var p = this._pending;
    if (!p) { this._mode = 'build'; this._renderAll(); return; }
    if (this._steps.length >= 8) {
      // Full: honest refusal, pending kept - never a silent drop.
      this.setData({
        status: '路线满了 8/8 步 — 先删一步，这步先留着不丢',
        lastEvent: 'EVT: SAVE refused - route full 8/8, pending kept, nothing dropped'
      });
      this._renderAll();
      return;
    }
    this._steps.push({ text: p.text });
    this._focus = this._steps.length - 1;
    this._pending = null;
    this._mode = 'build';
    this._saveSteps();
    this.setData({
      status: '✓ 已存第 ' + this._steps.length + ' 步：' + this._disp(p.text) + ' · 共 ' + this._steps.length + '/8 步',
      lastEvent: 'EVT: saved step "' + this._disp(p.text) + '" (' + p.src + ') - route saved as text'
    });
    this._renderAll();
  },

  _dropPending(how) {
    var p = this._pending;
    this._pending = null;
    this._mode = 'build';
    this.setData({
      status: '已丢弃待确认的这一步（它本来就没存下）',
      lastEvent: 'EVT: pending "' + (p ? this._disp(p.text) : '') + '" dropped by ' + how + ' - it was never saved'
    });
    this._renderAll();
  },

  // ---------- review (SPLIT proposals): accept all / prune ----------

  _setReview(steps) {
    this._review = steps;
    this._reviewFocus = 0;
    this._mode = 'review';
    this.setData({
      status: '整条路线拆出 ' + steps.length + ' 步 — 核对：DEL 删错步，OK 全部存下',
      lastEvent: 'EVT: SPLIT proposed ' + steps.length + ' step(s) - NOT saved yet, review first'
    });
    this._renderAll();
  },

  _acceptReview() {
    var props = this._review || [];
    if (!props.length) { this._review = null; this._mode = 'build'; this._renderAll(); return; }
    var slots = 8 - this._steps.length;
    if (slots <= 0) {
      this.setData({
        status: '路线已满 8/8 步 — 先回编辑删几步，再存这批',
        lastEvent: 'EVT: accept refused - route full 8/8, proposals kept in review'
      });
      this._renderAll();
      return;
    }
    var take = props.slice(0, slots);
    var left = props.length - take.length;
    for (var i = 0; i < take.length; i++) this._steps.push({ text: take[i].text });
    this._focus = this._steps.length - 1;
    this._review = null;
    this._mode = 'build';
    this._saveSteps();
    if (left > 0) {
      // Honest overflow: what did not fit is said out loud, never
      // dropped silently.
      this._speakText('存下了 ' + take.length + ' 步，还有 ' + left + ' 步没存下，路线满了');
      this.setData({
        status: '存下 ' + take.length + ' 步；另 ' + left + ' 步没存下（上限 8 步）：' +
          props.slice(slots).map(function (s) { return this._disp(s.text); }, this).join('、'),
        lastEvent: 'EVT: accept saved ' + take.length + ', ' + left + ' NOT saved (cap 8) - stated, not silent'
      });
    } else {
      this._speakText('路线存好了，共 ' + this._steps.length + ' 步');
      this.setData({
        status: '✓ 整条路线已存下 · 共 ' + this._steps.length + '/8 步 — 点 WALK 开始走',
        lastEvent: 'EVT: accept saved all ' + take.length + ' step(s) - route now ' + this._steps.length + ' steps'
      });
    }
    this._renderAll();
  },

  _dropReviewStep(idx) {
    var gone = this._review.splice(idx, 1)[0];
    if (this._reviewFocus >= this._review.length) this._reviewFocus = this._review.length - 1;
    if (this._reviewFocus < 0) this._reviewFocus = 0;
    this.setData({
      status: '已删待存步：「' + this._disp(gone.text) + '」· 还剩 ' + this._review.length + ' 步待存',
      lastEvent: 'EVT: review step "' + this._disp(gone.text) + '" pruned - it was never saved'
    });
    if (!this._review.length) {
      this._review = null;
      this._mode = 'build';
      this.setData({
        status: '待存步全删完了 — 回到编辑，路线没变',
        lastEvent: 'EVT: review emptied by pruning - back to build, route unchanged'
      });
    }
    this._renderAll();
  },

  // ---------- DEL (drop pending / prune review / two-step delete / two-step walk reset) ----------

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'pending') { this._dropPending('DEL'); return; }
    if (this._mode === 'review') {
      if (this._review && this._review.length) this._dropReviewStep(this._reviewFocus);
      return;
    }
    if (this._mode === 'walk') {
      if (!this._steps.length) return;
      if (this._resetArm) { this._resetWalk(); return; }
      this._arm('reset', -1);
      this.setData({
        status: '⚠ 再点一次 DEL 回到第一步（其他动作取消）',
        lastEvent: 'EVT: RESET 1/2 - armed (still on step ' + Math.min(this._cur + 1, this._steps.length) + ')'
      });
      this._renderAll();
      return;
    }
    // build: two-step delete of the focused step
    var idx = this._focus;
    if (idx < 0 || idx >= this._steps.length) {
      this.setData({ lastEvent: 'EVT: DEL - no step focused' });
      return;
    }
    if (this._delArmIdx === idx) {
      var gone = this._steps.splice(idx, 1)[0];
      this._disarm();
      if (this._focus >= this._steps.length) this._focus = this._steps.length - 1;
      if (this._focus < 0 && this._steps.length) this._focus = 0;
      this._saveSteps();
      this.setData({
        status: '已删第 ' + (idx + 1) + ' 步：' + this._disp(gone.text) + ' · 还剩 ' + this._steps.length + ' 步',
        lastEvent: 'EVT: deleted step "' + this._disp(gone.text) + '" (two-step DEL)'
      });
      this._renderAll();
    } else {
      this._arm('del', idx);
      this.setData({
        status: '⚠ 再点一次 DEL 删掉第 ' + (idx + 1) + ' 步「' + this._disp(this._steps[idx].text) + '」（其他动作取消）',
        lastEvent: 'EVT: DEL 1/2 - delete ARMED for step "' + this._disp(this._steps[idx].text) + '" (nothing deleted yet)'
      });
      this._renderAll();
    }
  },

  // ---------- parsing: one step / a whole route ----------

  // One dictated step, close to verbatim: bare sequence markers at
  // the very start （先/然后/接着/最后） and trailing punctuation are
  // stripped - they are connectors, not the step itself. Anything
  // longer than 30 chars is truncated with the cut stated, never
  // silently. Empty after stripping = not heard, rejected.
  _cleanStep(raw) {
    if (!raw) return '';
    var s = String(raw).replace(/\s+/g, '');
    s = s.replace(/^(先|然后|接着|其次|最后)+/, '');
    s = s.replace(/[。．.!！?？]+$/g, '');
    s = s.replace(/^[，、,]+/, '').replace(/[，、,]+$/g, '');
    return s;
  },

  _parseStep(raw) {
    var s = this._cleanStep(raw);
    if (!s) return null;
    return s.slice(0, 30);
  },

  // A whole route in one utterance, split into steps. Split points:
  // sentence breaks; the sequence markers 然后/接着/其次/最后； a
  // comma right before a turn verb or an ordinal landmark （第二
  // 个灯）; and 再 only when a turn verb follows （再走一百米 keeps
  // its 再 - it is one step, not a marker). Leading markers are
  // consumed as separators, not kept in the step text. Each step is
  // capped at 30 chars like a dictated step.
  _splitRoute(raw) {
    if (!raw) return [];
    var s = String(raw).replace(/\s+/g, '');
    s = s.replace(/[。．.!！?？]+$/g, '');
    if (!s) return [];
    s = s.replace(/[。；;]+/g, '\u0001');
    s = s.replace(/(然后|接着|其次|最后)/g, '\u0001$1');
    s = s.replace(/再(?=左转|右转|直行|掉头|左拐|右拐|往左|往右|直走)/g, '\u0001再');
    s = s.replace(/[，、,](?=(左转|右转|直行|掉头|左拐|右拐|往左转|往右转|往左|往右|直走|向前|走到|看见|看到|第[一二三四五六七八九十0-9]+个))/g, '\u0001');
    var parts = s.split('\u0001');
    var out = [];
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i]
        .replace(/^(先|然后|接着|其次|最后)+/, '')
        .replace(/^再(?=左转|右转|直行|掉头|左拐|右拐|往左|往右|直走)/, '')
        .replace(/^[，、,。；;]+/, '')
        .replace(/[，、,。；;]+$/g, '');
      if (p) out.push(p.slice(0, 30));
    }
    return out;
  },

  _applyDictatedStep(txt) {
    var v = this._parseStep(txt);
    if (v === null) {
      this.setData({
        status: '没听清成一步：「' + String(txt || '(empty)').slice(0, 12) + '」— 没猜，再点 DICT 说一遍',
        lastEvent: 'EVT: DICT parse FAIL - rejected, route unchanged'
      });
      this._renderAll();
      return false;
    }
    if (this._cleanStep(txt).length > 30) {
      this.setData({ lastEvent: 'EVT: dictated step over 30 chars - truncated to 30, the cut is stated' });
    }
    this._setPending(v, 'DICT');
    return true;
  },

  _applyDictatedRoute(txt) {
    var steps = this._splitRoute(txt);
    if (!steps.length) {
      this.setData({
        status: '没听清成路线：「' + String(txt || '(empty)').slice(0, 12) + '」— 没猜，再点 SPLIT 说一遍',
        lastEvent: 'EVT: SPLIT parse FAIL - rejected, route unchanged'
      });
      this._renderAll();
      return false;
    }
    if (steps.length < 2) {
      // Honest single-step outcome: the split found no step
      // markers, so the whole utterance is kept as ONE step and
      // goes through the normal confirm gate - it is never
      // chopped up by guessing.
      this.setData({
        lastEvent: 'EVT: SPLIT found no step markers - kept whole as ONE step on the confirm chip'
      });
      this._setPending(steps[0], 'SPLIT');
      return true;
    }
    this._setReview(steps.map(function (t) { return { text: t }; }));
    return true;
  },

  // ---------- DICT / SPLIT (you repeat it yourself; check first, then host ASR) ----------

  _stopDictRec() {
    if (this._dictRec) {
      try { this._dictRec.abort(); } catch (e) {}
      this._dictRec = null;
    }
  },

  dictTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: DICT in DEMO - no microphone used' });
      return;
    }
    if (this._mode === 'walk') {
      this.setData({
        status: '走路中改不了路线 — 点 WALK 回编辑再重录',
        lastEvent: 'EVT: DICT refused in walk - steps are re-dictated in BUILD only'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'review') {
      this.setData({
        status: '先处理这批待存步：OK 全部存下，或 DEL 逐个删',
        lastEvent: 'EVT: DICT refused while a review is open'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'pending') {
      // Re-dictating replaces the pending step (it was never saved).
      this.setData({ lastEvent: 'EVT: re-DICT - the new hearing replaces the pending step' });
    }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'DICT SKIP - 这台设备没有识别；真机再试',
        lastEvent: 'EVT: DICT SKIP (host ASR n/a) - nothing faked'
      });
      this._renderAll();
      return;
    }
    this._dictListen('step');
  },

  splitTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._demo) {
      this.setData({ lastEvent: 'EVT: SPLIT in DEMO - no microphone used' });
      return;
    }
    if (this._mode === 'walk') {
      this.setData({
        status: '走路中改不了路线 — 点 WALK 回编辑再重录',
        lastEvent: 'EVT: SPLIT refused in walk - steps are re-dictated in BUILD only'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'review') {
      this.setData({
        status: '先处理这批待存步：OK 全部存下，或 DEL 逐个删',
        lastEvent: 'EVT: SPLIT refused while a review is open'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'pending') {
      this.setData({
        status: '先处理待确认的这一步：OK 存下或 DEL 丢弃',
        lastEvent: 'EVT: SPLIT refused while a step is pending'
      });
      this._renderAll();
      return;
    }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        status: 'SPLIT SKIP - 这台设备没有识别；真机再试',
        lastEvent: 'EVT: SPLIT SKIP (host ASR n/a) - nothing faked'
      });
      this._renderAll();
      return;
    }
    this._dictListen('route');
  },

  async _dictListen(kind) {
    var self = this;
    this.setData({ busy: true, micLine: 'MIC CHECK: checking wearer mic...' });
    // Wearer-mode mic AVAILABILITY check (documented pattern from
    // the sibling agents): open the wearer-mode stream, read back
    // its settings, stop every track at once. The check stream is
    // NOT the recognition input and does not shape what recognition
    // hears - the host SpeechRecognition below listens on its own
    // microphone, and it hears the WEARER repeating the directions
    // in their own voice: the stranger said it once, you repeat it
    // once, the glasses hold it from there. Result on its own MIC
    // CHECK line; the listening line says (host ASR).
    var micNote = 'MIC CHECK: not run';
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        var ms = await this._withTimeout(navigator.mediaDevices.getUserMedia({
          audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
        }), 6000, 'mic check');
        var settings = {};
        try {
          var tr = ms.getAudioTracks()[0];
          if (tr && tr.getSettings) settings = tr.getSettings();
        } catch (e) {}
        micNote = 'MIC CHECK: wearer OK' + (settings.microphoneMode ? ' (' + settings.microphoneMode + ')' : '');
        ms.getTracks().forEach(function (t) { t.stop(); });
      } catch (e) {
        if (e && e.name === 'OverconstrainedError') {
          try {
            var ms2 = await this._withTimeout(navigator.mediaDevices.getUserMedia({ audio: true }), 6000, 'mic check fallback');
            micNote = 'MIC CHECK: wearer mode rejected - default mic OK (labelled fallback)';
            ms2.getTracks().forEach(function (t) { t.stop(); });
          } catch (e2) {
            micNote = 'MIC CHECK: FAIL - ' + this._err(e2);
          }
        } else {
          micNote = 'MIC CHECK: FAIL - ' + this._err(e);
        }
      }
    }
    this.setData({ micLine: micNote });
    try {
      this._stopDictRec();
      var rec = new SpeechRecognition();
      this._dictRec = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim();
          if (!txt) return;
          if (kind === 'route') self._applyDictatedRoute(txt);
          else self._applyDictatedStep(txt);
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: (kind === 'route' ? 'SPLIT' : 'DICT') + ' FAIL - ' + self._err(ev && ev.error ? ev.error : ev) + '，再试一次',
          lastEvent: 'EVT: ' + (kind === 'route' ? 'SPLIT' : 'DICT') + ' ASR error'
        });
        self._renderAll();
      };
      rec.onend = function () {
        if (self._dictRec === rec) self._dictRec = null;
        self.setData({ busy: false });
      };
      rec.start();
      this.setData({
        status: kind === 'route'
          ? 'SPLIT listening (host ASR)... 一口气复述整条路线（只听你的声音）'
          : 'DICT listening (host ASR)... 复述一步路线（只听你的声音）',
        lastEvent: 'EVT: ' + (kind === 'route' ? 'SPLIT' : 'DICT') + ' listening (host ASR), ' + micNote
      });
      this._renderAll();
    } catch (e) {
      this.setData({
        busy: false,
        status: (kind === 'route' ? 'SPLIT' : 'DICT') + ' FAIL - recogniser would not start',
        lastEvent: 'EVT: dictation start failed - ' + this._err(e)
      });
      this._renderAll();
    }
  },

  // ---------- SPEAK (mode-aware readback, current context only) ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    if (this._mode === 'pending' && this._pending) {
      if (this._speakText('待确认：' + this._pending.text)) {
        this.setData({ lastEvent: 'EVT: SPEAK pending step (full text, TTS, no lang set)' });
      }
      return;
    }
    if (this._mode === 'review' && this._review) {
      var parts = [];
      for (var i = 0; i < this._review.length; i++) parts.push('第' + (i + 1) + '步 ' + this._review[i].text);
      if (this._speakText('待存 ' + this._review.length + ' 步：' + parts.join('；'))) {
        this.setData({ lastEvent: 'EVT: SPEAK review proposals in order (TTS, no lang set)' });
      }
      return;
    }
    if (this._mode === 'walk') {
      if (this._cur >= this._steps.length) {
        if (this._speakText('路线走完了，应该到了')) {
          this.setData({ lastEvent: 'EVT: SPEAK - steps finished (arrival is your judgement)' });
        }
        return;
      }
      if (this._speakText('第' + (this._cur + 1) + '步：' + this._steps[this._cur].text)) {
        this.setData({ lastEvent: 'EVT: SPEAK current step only, full text (TTS, no lang set)' });
      }
      return;
    }
    // build: read the whole saved route in order
    if (!this._steps.length) {
      this.setData({ lastEvent: 'EVT: SPEAK - no route saved yet' });
      return;
    }
    var all = [];
    for (var j = 0; j < this._steps.length; j++) all.push('第' + (j + 1) + '步 ' + this._steps[j].text);
    if (this._speakText('路线共 ' + this._steps.length + ' 步：' + all.join('；'))) {
      this.setData({ lastEvent: 'EVT: SPEAK whole route in order (TTS, no lang set)' });
    }
  },

  // ---------- DEMO (the PLAN's own route, walked in memory only) ----------

  demoTap() {
    if (this.data.busy) return;
    if (!this._demo) {
      this._demoRealSteps = this._steps;
      this._demoRealFocus = this._focus;
      this._demoRealPending = this._pending;
      this._demoRealMode = this._mode;
      this._demoRealReview = this._review;
      this._demo = true;
      this._demoStep = 0;
      this._disarm();
      this._pending = null;
      this._review = null;
      this._steps = [
        { text: '左转' },
        { text: '直行' },
        { text: '第二个灯右转' }
      ];
      this._mode = 'walk';
      this._cur = 0;
      this._peek = false;
      this._arrivedSaid = false;
      this.setData({
        status: 'DEMO - 就是问路那句原话拆成的 3 步：点 DEMO 一步步走完',
        lastEvent: 'EVT: DEMO on - seeded 3 steps in WALK (memory only, real route untouched)'
      });
      this._renderAll();
      return;
    }
    // Further DEMO taps walk the demo route with the same advance
    // the wearer's nod would make.
    this._demoStep++;
    if (this._demoStep <= 3) {
      this._advance('DEMO');
      this.setData({ lastEvent: 'EVT: DEMO step ' + this._demoStep + ' - advanced the demo route (simulated judgement)' });
      return;
    }
    // Fourth tap exits: the real route comes back exactly as it was.
    this._demo = false;
    this._demoStep = 0;
    this._steps = this._demoRealSteps || [];
    this._focus = (typeof this._demoRealFocus === 'number') ? this._demoRealFocus : -1;
    this._pending = this._demoRealPending || null;
    this._mode = this._demoRealMode || 'build';
    this._review = this._demoRealReview || null;
    this._demoRealSteps = null;
    this._demoRealPending = null;
    this._demoRealReview = null;
    this._cur = 0;
    this._peek = false;
    this._arrivedSaid = false;
    this._disarm();
    this.setData({
      status: 'DEMO OFF - your real route is back (' + this._steps.length + ' steps)',
      lastEvent: 'EVT: DEMO cleared - real route restored exactly, nothing was written'
    });
    this._renderAll();
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i;
    var patch = { rows: rows };

    if (this._mode === 'review' && this._review) {
      for (i = 0; i < this._review.length; i++) {
        rows.push({
          name: (i === this._reviewFocus ? '▸ ' : '') + '待存 ' + (i + 1) + '. ' + this._disp(this._review[i].text),
          detail: 'proposed step',
          flag: i === this._reviewFocus ? 'FOCUS' : '',
          cls: 'row'
        });
      }
      patch.countLine = 'REVIEW: 待存 ' + this._review.length + ' 步 · 还没存下 · 核对后 OK 才存';
    } else if (this._mode === 'walk') {
      var n = this._steps.length;
      var dots = '';
      for (i = 0; i < n; i++) dots += (i < this._cur ? '●' : '○');
      var finished = this._cur >= n;
      rows.push({
        name: dots + '  第 ' + Math.min(this._cur + 1, n) + '/' + n + ' 步',
        detail: finished ? 'steps finished' : 'done ' + this._cur + ' · left ' + (n - this._cur),
        flag: 'WALK',
        cls: 'row'
      });
      patch.countLine = finished
        ? 'WALK: 步骤全走完 · 到没到你判断 · 它不知道你在哪'
        : 'WALK: 第 ' + (this._cur + 1) + '/' + n + ' 步 · 靠你的点头推进 · 它不知道你在哪';
    } else {
      for (i = 0; i < this._steps.length; i++) {
        rows.push({
          name: (i === this._focus && this._mode === 'build' ? '▸ ' : '') + (i + 1) + '. ' + this._disp(this._steps[i].text),
          detail: 'step ' + (i + 1),
          flag: i === this._focus && this._mode === 'build' ? 'FOCUS' : '',
          cls: 'row'
        });
      }
      if (!rows.length) {
        rows.push({
          name: '(no steps)',
          detail: 'DICT one step in your own voice, or SPLIT a whole route - or DEMO',
          flag: '',
          cls: 'row'
        });
      }
      patch.countLine = 'ROUTE: ' + this._steps.length + '/8 步 · 文字存本机 · 步数位置不存（重开从编辑起）';
    }

    if (this._mode === 'pending' && this._pending) {
      var p = this._pending;
      patch.boxLabel = '◎ ASR 听写待确认 — 识别可能听错，这里核对（只听你复述的）';
      patch.bigLabel = '待确认的一步 · 来源 ' + p.src + (this._truncated(p.text) ? ' · 显示截断，全文已留' : '');
      patch.bigText = this._disp(p.text);
      patch.bigNote = 'OK 存下这一步 · DICT 重念替换 · DEL 丢弃 · 点头不存步';
    } else if (this._mode === 'review' && this._review && this._review.length) {
      var rp = this._review[this._reviewFocus] || this._review[0];
      patch.boxLabel = '◎ 整条路线已拆开 — 还没存下，先核对（拆错了删掉那一步）';
      patch.bigLabel = '待存 第 ' + (this._reviewFocus + 1) + '/' + this._review.length + ' 步' +
        (this._truncated(rp.text) ? ' · 显示截断' : '');
      patch.bigText = this._disp(rp.text);
      patch.bigNote = 'OK 全部存下 · +1/−1 选步 · DEL 删这一步 · 点头不接受';
    } else if (this._mode === 'walk') {
      var wn = this._steps.length;
      if (this._cur >= wn) {
        patch.boxLabel = '◎ 步骤全部走完 — 它只知道步骤走完了';
        patch.bigLabel = '路线走完了 — 应该到了（到没到你判断）';
        patch.bigText = '走完了';
        patch.bigNote = 'DEL 两下回第一步 · WALK 回编辑 · 要重录回编辑 DICT';
      } else {
        var cur = this._steps[this._cur];
        patch.boxLabel = '◎ 正在走 — 眼前只有当前一步，它不知道你在哪';
        patch.bigLabel = '第 ' + (this._cur + 1) + '/' + wn + ' 步' +
          (this._truncated(cur.text) ? ' · 显示截断，朗读是全文' : '');
        patch.bigText = this._disp(cur.text);
        if (this._peek) {
          patch.bigNote = this._cur + 1 < wn
            ? '偷看下一步：' + this._disp(this._steps[this._cur + 1].text) + '（推进后自动关）'
            : '偷看：没有下一步了，这是最后一步';
        } else {
          patch.bigNote = '点头/OK = 这步走完 · 上滑退一步 · PEEK 偷看下一步（默认关）';
        }
      }
    } else if (this._steps.length && this._focus >= 0 && this._steps[this._focus]) {
      var f = this._steps[this._focus];
      patch.boxLabel = '◎ 已存路线 — 点 OK 或 WALK 开始走，走时只显示当前一步';
      patch.bigLabel = '第 ' + (this._focus + 1) + '/' + this._steps.length + ' 步（编辑焦点）' +
        (this._truncated(f.text) ? ' · 显示截断' : '');
      patch.bigText = this._disp(f.text);
      patch.bigNote = this._delArmIdx === this._focus
        ? '⚠ 删除已武装 — 再点 DEL 真的删'
        : 'DICT 再加一步 · SPLIT 整条重拆 · DEL 两下删这一步';
    } else {
      patch.boxLabel = '◎ 路线编辑 — 一步步说，或一口气说整条让它拆';
      patch.bigLabel = '（还没有路线）';
      patch.bigText = '----';
      patch.bigNote = 'DICT 说一步 / SPLIT 说整条 / DEMO 演示';
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
      <text class="title">ROUTE HOLD</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{micLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="splitTap">SPLIT</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="peekTap">PEEK</button>
      <button class="btn" bindtap="walkTap">WALK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">路线靠你自己的声音记 · 它不带路、不认路 · 走完一步你点头才进下一步</text>
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
  height: 63px;
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
