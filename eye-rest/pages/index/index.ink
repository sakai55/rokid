<script def>
{
  "navigationBarTitleText": "Eye Rest"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '眼睛休息 — 看书/看屏幕一投入就是两小时，眼睛干到疼才想起休息：头部停稳凝视近处持续计时，满 20 分钟视线内提醒远眺，抬头看远自动确认完成',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 近视计时 — START 开始计时，LOOK 抬头看远确认，END 出小结',
    bigLabel: '眼睛休息 · 待机',
    bigText: '还没开始',
    bigNote: 'START 开始计时 · 满 20 分钟提醒远眺 · 抬头看远自动确认',
    permLine: 'PERM: 无权限 — 方向传感器（头稳 + 俯仰角）+ 计时 + 提醒；不拍照、不录音、不定位',
    rows: [],
    countLine: '近视累计 0 分钟 · 提醒 0 次 · 远眺完成 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START starts timing, LOOK confirms a far look, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | timing | remind | summary
    this._threshold = 20; // minutes of steady near gaze before a far-look reminder
    this._near = 0; // minutes in the current near-gaze stretch
    this._totalNear = 0; // minutes across the whole session
    this._reminds = 0;
    this._rests = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 start, 2 timing 12 min, 3 remind at 20 min, 4 look-up confirmed, 5 summary
    this._nodLock = false;
    this._timer = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the near-gaze minutes,
    // reminder/rest counts and the summary die with the page.
    // Nothing was ever written anywhere persistent, so there
    // is nothing to clean up — that IS the design.
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
    this._mode = 'idle';
    this._near = 0;
    this._totalNear = 0;
    this._reminds = 0;
    this._rests = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Speech happens only on the reminder
    // (exactly once per reminder) and via SPEAK.
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

  onOrientationChange(event) {
    // Real-device path: the head-orientation sensor reports a
    // pitch angle; a clear upward pitch while a reminder is
    // open is the far-look confirmation. This is a pitch
    // approximation, never a measured far-look distance:
    // the platform has no eye tracking and no distance
    // measurement. If the host never delivers a pitch event,
    // the LOOK button is the fallback — the README says so.
    var d = (event && event.detail) || event || {};
    var pitch = d.pitch;
    if (pitch === undefined || pitch === null) pitch = d.eulerY;
    if (pitch === undefined || pitch === null) pitch = d.y;
    var up = false;
    if (typeof pitch === 'number' && pitch >= 15) up = true;
    if (d.direction === 'up' || d.lookUp === true) up = true;
    if (!up) {
      if (this._mode === 'remind') {
        this.setData({ lastEvent: 'EVT: pitch ' + pitch + ' - not a look-up yet, keep looking far' });
      }
      return;
    }
    if (this._mode === 'remind') {
      this.lookTap();
      return;
    }
    this.setData({ lastEvent: 'EVT: look-up noted - no reminder open, nothing to confirm' });
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
    // timing in idle and confirms the summary. A nod never
    // confirms a far look: only an upward head pitch (or the
    // LOOK button) confirms one — a nod is not a look far
    // away, and must not be counted as one.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'timing') {
      this.setData({ lastEvent: 'EVT: nod ignored while timing - timing runs on steady gaze and minutes, not on nods' });
      return;
    }
    if (this._mode === 'remind') {
      this.setData({ lastEvent: 'EVT: nod ignored during reminder - look up far to confirm, a nod is not a far look' });
      return;
    }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'timing') {
        this.setData({ lastEvent: 'EVT: Enter ignored while timing - timing runs on steady gaze and minutes, not on keys' });
      }
      else if (this._mode === 'remind') {
        this.setData({ lastEvent: 'EVT: Enter ignored during reminder - look up far to confirm, a key is not a far look' });
      }
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

  // ---------- the timer (the only accumulation point) ----------

  _tick(mins) {
    if (this._mode !== 'timing') {
      this.setData({ lastEvent: 'EVT: tick ignored - not timing' });
      return;
    }
    if (!this._steady) {
      // Head moving is not steady near gaze: the minute does
      // not count. The timer pauses, it does not guess.
      this.setData({ lastEvent: 'EVT: tick paused - head moving, not steady near gaze' });
      this._renderAll();
      return;
    }
    var m = mins || 1;
    this._near += m;
    this._totalNear += m;
    if (this._near >= this._threshold) {
      this._mode = 'remind';
      this._reminds++;
      this.setData({
        status: '该远眺了 — 近视已满 ' + this._threshold + ' 分钟，抬头看远处，抬头自动确认（LOOK 也可确认）',
        lastEvent: 'EVT: far-look reminder ' + this._reminds + ' - near gaze reached ' + this._threshold + ' min'
      });
      // Exactly one spoken reminder per reminder: further
      // ticks in remind mode never speak again.
      this._speakText('该远眺了，抬头看远处');
      this._renderAll();
      return;
    }
    this.setData({
      status: '计时中 — 头部停稳凝视近处 ' + this._near + ' 分钟，满 ' + this._threshold + ' 分钟提醒远眺',
      lastEvent: 'EVT: tick +' + m + ' min - near ' + this._near + ' min'
    });
    this._renderAll();
  },

  _startTimer() {
    // Real-device path: one minute per tick, only while
    // timing. The interval is stopped on unload and on END.
    if (this._timer) return;
    var self = this;
    try {
      this._timer = setInterval(function () { self._tick(1); }, 60000);
    } catch (e) {}
  },

  _stopTimer() {
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
  },

  // ---------- start / look / end ----------

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already timing, reminding or summarising' });
      return;
    }
    // BACK from timing returns to idle with the round kept;
    // START resumes the same round instead of resetting it.
    if (this._near > 0 || this._totalNear > 0 || this._reminds > 0 || this._rests > 0) {
      this._mode = 'timing';
      this._startTimer();
      this.setData({
        status: '计时恢复 — 近视累计 ' + this._totalNear + ' 分钟，头部停稳继续计时',
        lastEvent: 'EVT: timing resumed - round kept'
      });
      this._renderAll();
      return;
    }
    this._mode = 'timing';
    this._startTimer();
    this.setData({
      status: '计时中 — 头部停稳凝视近处开始计时，满 ' + this._threshold + ' 分钟提醒远眺',
      lastEvent: 'EVT: timing started - steady near gaze counts, head moving pauses'
    });
    this._renderAll();
  },

  lookTap() {
    if (this._mode !== 'remind') {
      this.setData({ lastEvent: 'EVT: LOOK ignored - no reminder open, nothing to confirm' });
      return;
    }
    // A far look completes the reminder: the current stretch
    // resets, the session totals keep counting.
    this._rests++;
    this._near = 0;
    this._mode = 'timing';
    this.setData({
      status: '远眺完成 — 抬头看远已确认，计时重新开始，头部停稳继续计时',
      lastEvent: 'EVT: far look confirmed ' + this._rests + ' - stretch reset, timing resumed'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to timing without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始计时' });
      return;
    }
    this._stopTimer();
    this._mode = 'summary';
    this._summary = {
      totalNear: this._totalNear,
      reminds: this._reminds,
      rests: this._rests
    };
    this.setData({
      status: '结束 — 近视累计 ' + this._totalNear + ' 分钟，提醒 ' + this._reminds + ' 次，远眺完成 ' + this._rests + ' 次，点 END 确认清空，BACK 回计时',
      lastEvent: 'EVT: closed - near ' + this._totalNear + ' min, reminds ' + this._reminds + ', rests ' + this._rests
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._near = 0;
    this._totalNear = 0;
    this._reminds = 0;
    this._rests = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '眼睛休息 — START 再次开始计时',
      lastEvent: 'EVT: summary confirmed - minutes and counts cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to timing without
      // deleting anything; the summary is rebuilt on END.
      // If nothing was ever timed, return to idle.
      this._mode = (this._totalNear > 0 || this._reminds > 0 || this._rests > 0) ? 'timing' : 'idle';
      this._summary = null;
      if (this._mode === 'timing') this._startTimer();
      this.setData({
        status: this._mode === 'timing' ? '计时中 — BACK 回到计时，累计保留' : '眼睛休息 — BACK 回到待机',
        lastEvent: 'EVT: back to ' + this._mode + ' - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'remind') {
      // Back from a reminder returns to timing with the
      // reminder still owed: the stretch is NOT reset, so
      // the next steady minute re-raises it. Looking away
      // from the banner is not a far look.
      this._mode = 'timing';
      this.setData({
        status: '计时中 — BACK 回到计时，提醒未完成：近视 ' + this._near + ' 分钟仍满 ' + this._threshold + ' 分钟，下次头稳计时即重提醒',
        lastEvent: 'EVT: back to timing - reminder still owed, stretch kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'timing') {
      // Back from timing returns to idle with the round kept
      // and the timer stopped; START resumes the same round.
      this._stopTimer();
      this._mode = 'idle';
      this.setData({
        status: '眼睛休息 — 已计近视 ' + this._totalNear + ' 分钟未清，START 恢复计时',
        lastEvent: 'EVT: back to idle - round kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START starts timing' });
  },

  _focusLen() {
    return 3; // the three info rows exist in every mode
  },

  nextTap() {
    this._focus = (this._focus + 1) % 3;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    this._focus = (this._focus - 1 + 3) % 3;
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
    if (idx < 0 || idx >= 3) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没开始：START 开始计时';
    } else if (this._mode === 'timing') {
      line = '计时中，近视累计 ' + this._totalNear + ' 分钟，提醒 ' + this._reminds + ' 次';
    } else if (this._mode === 'remind') {
      line = '该远眺了，抬头看远处';
    } else if (this._summary) {
      line = '本次小结：近视累计 ' + this._summary.totalNear + ' 分钟，提醒 ' + this._summary.reminds + ' 次，远眺完成 ' + this._summary.rests + ' 次';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user timing session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._totalNear > 0 || this._reminds > 0 || this._rests > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user minutes are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY - ready' });
      this.startTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - timing started (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._tick(12);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 12 min steady near gaze (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._tick(8);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 20 min reached, far-look reminder (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.onOrientationChange({ detail: { pitch: 20 } });
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - head pitched up, far look confirmed (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: near 20 min, reminds 1, rests 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    rows.push({
      idx: 0,
      name: '近视累计',
      detail: this._totalNear + ' 分钟（本段 ' + this._near + ' 分钟 · 满 ' + this._threshold + ' 分钟提醒）',
      flag: (this._focus === 0 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 1,
      name: '提醒次数',
      detail: this._reminds + ' 次（每次提醒只出声一次）',
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '远眺完成',
      detail: this._rests + ' 次（抬头看远自动确认，点头不算）',
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '近视累计 ' + this._totalNear + ' 分钟 · 提醒 ' + this._reminds + ' 次 · 远眺完成 ' + this._rests + ' 次 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 近视计时 — START 开始计时，LOOK 抬头看远确认，END 出小结';
      patch.bigLabel = '眼睛休息 · 待机';
      patch.bigText = (this._totalNear === 0) ? '还没开始' : '近视 ' + this._totalNear + ' 分钟';
      patch.bigNote = 'START 开始计时 · 满 20 分钟提醒远眺 · 抬头看远自动确认';
    } else if (this._mode === 'timing') {
      patch.boxLabel = '◎ 计时中 — 头部停稳才计时，头部在动计时暂停，满 20 分钟提醒远眺';
      patch.bigLabel = '眼睛休息 · 计时中';
      patch.bigText = '近视 ' + this._totalNear + ' 分钟';
      patch.bigNote = '本段 ' + this._near + ' 分钟 · 提醒 ' + this._reminds + ' 次 · 远眺 ' + this._rests + ' 次';
    } else if (this._mode === 'remind') {
      patch.boxLabel = '◎ 该远眺了 — 抬头看远处，抬头自动确认（LOOK 也可确认），点头不算远眺';
      patch.bigLabel = '眼睛休息 · 该远眺了';
      patch.bigText = '该远眺了';
      patch.bigNote = '近视已满 20 分钟 · 抬头看远自动确认 · 提醒只出声一次';
    } else {
      patch.boxLabel = '◎ 本次小结 — 近视累计、提醒次数、远眺完成次数钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { totalNear: 0, reminds: 0, rests: 0 };
      patch.bigText = '远眺 ' + sm.rests + ' 次';
      patch.bigNote = '近视累计 ' + sm.totalNear + ' 分钟 · 提醒 ' + sm.reminds + ' 次 · 点 END 确认清空 · BACK 回计时';
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
      <text class="title">EYE REST v1.0.0</text>
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
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
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
    <text class="foot2">平台没有眼动追踪——「凝视近处」不是测出来的视线，而是头部停稳（方向稳定性事件）近似的，它不知道你眼睛到底看哪、看多远 · 「抬头看远」也不是测出来的远眺距离，而是头部俯仰角向上变化的近似确认；若宿主不投递俯仰事件，以 LOOK 按键为准 · 它不是医疗建议，不诊断眼疲劳，不承诺护眼效果 · 只存本次会话，关掉即清 · 没有室内定位，没有摄像头 · 零落盘</text>
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
