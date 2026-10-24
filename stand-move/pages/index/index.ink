<script def>
{
  "navigationBarTitleText": "Stand Move"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '起身活动 — 久坐一上午，腰背僵了才惊觉没起过身：头部活动量+静止时长监测，久坐超阈值提醒起身，并用环视一圈当作活动确认',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 起身活动 — START 开始监测，MODE 换阈值，SWEEP 环视确认，END 出小结',
    bigLabel: '起身活动 · 待机',
    bigText: '还没开始',
    bigNote: '静止满 45 分钟提醒起身 · 环视一圈确认活动',
    permLine: 'PERM: 无权限 — 方向传感器 + 计时 + 提醒；不拍照、不录音、不定位',
    rows: [],
    countLine: '静止 0 分钟 · 起身 0 次 · 提醒 0 次 · 阈值 45 分钟 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START watches still time, MODE switches the threshold, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | remind | summary
    this._thresholds = [
      { name: '45', min: 45 },
      { name: '60', min: 60 }
    ];
    this._thIdx = 0;
    this._stillMin = 0; // minutes since the last head movement
    this._longestStill = 0; // longest still stretch this session
    this._stands = 0; // sweep-confirmed stand-ups
    this._reminds = 0; // reminders fired
    this._moveCount = 0; // head movements counted
    this._sweepLeft = false; // yaw swung past -20 in remind
    this._sweepRight = false; // yaw swung past +20 in remind
    this._prevMode = 'watching'; // mode to return to from summary
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 watching, 2 remind, 3 confirmed, 4 summary
    this._nodLock = false;
    this._timer = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the still minutes, the
    // stand-ups, the reminders and the summary die with the
    // page. Nothing was ever written anywhere persistent, so
    // there is nothing to clean up — that IS the design.
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
    this._mode = 'idle';
    this._stillMin = 0;
    this._longestStill = 0;
    this._stands = 0;
    this._reminds = 0;
    this._moveCount = 0;
    this._sweepLeft = false;
    this._sweepRight = false;
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
    // not take effect. The stand-up reminder is spoken
    // exactly once per reminder, and never again while the
    // reminder stands unconfirmed.
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
    // Head activity: any delivered orientation change is a
    // head movement. While watching it resets the still
    // timer; while a reminder stands it feeds the sweep
    // (yaw past -20 and past +20 is one look-around).
    var d = (event && event.detail) || event || {};
    var yaw = d.yaw;
    if (yaw === undefined || yaw === null) yaw = d.eulerZ;
    if (yaw === undefined || yaw === null) yaw = d.z;
    if (this._mode === 'watching') {
      this._moveCount++;
      if (this._stillMin > this._longestStill) this._longestStill = this._stillMin;
      this._stillMin = 0;
      this.setData({
        status: '监测中 — 刚才动了一下，静止计时已清零，静止 0 分钟',
        lastEvent: 'EVT: head moved - still timer reset, moves ' + this._moveCount
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'remind') {
      this._moveCount++;
      if (typeof yaw === 'number') {
        if (yaw <= -20) this._sweepLeft = true;
        if (yaw >= 20) this._sweepRight = true;
      }
      if (this._sweepLeft && this._sweepRight) {
        this._confirmMove();
        return;
      }
      this.setData({
        status: '提醒中 — 环视进度：左' + (this._sweepLeft ? '✓' : '·') + ' 右' + (this._sweepRight ? '✓' : '·') + '，左右都扫过才算确认',
        lastEvent: 'EVT: sweep progress left ' + this._sweepLeft + ' right ' + this._sweepRight
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: orientation ignored - not watching' });
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
    // watching in idle and confirms the summary. A nod never
    // confirms a stand-up: standing up is a look-around
    // sweep, and counting a nod as a stand-up would be a
    // lie about what you did.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'watching' || this._mode === 'remind') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not standing up, a look-around sweep confirms' });
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
      else if (this._mode === 'remind') this.sweepTap();
      else if (this._mode === 'summary') this._confirmSummary();
      else this.setData({ lastEvent: 'EVT: Enter ignored while watching - head movement resets the timer, no tap needed' });
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

  // ---------- the stillness clock (the only accumulation point) ----------

  _threshold() {
    return this._thresholds[this._thIdx];
  },

  _tick(mins) {
    if (this._mode !== 'watching' && this._mode !== 'remind') {
      this.setData({ lastEvent: 'EVT: tick ignored - not watching' });
      return;
    }
    var m = mins || 1;
    this._stillMin += m;
    if (this._stillMin > this._longestStill) this._longestStill = this._stillMin;
    if (this._mode === 'watching' && this._stillMin >= this._threshold().min) {
      // Cross the threshold: the reminder fires exactly once
      // (banner + one spoken line). Further ticks while the
      // reminder stands unconfirmed never speak again.
      this._mode = 'remind';
      this._reminds++;
      this._speakText('该起身活动了');
      this.setData({
        status: '提醒 — 静止 ' + this._stillMin + ' 分钟，满 ' + this._threshold().min + ' 分钟了，起身环视一圈确认',
        lastEvent: 'EVT: threshold crossed - reminder ' + this._reminds + ' (spoken once)'
      });
      this._renderAll();
      return;
    }
    this.setData({
      status: this._mode === 'remind'
        ? '提醒中 — 静止 ' + this._stillMin + ' 分钟，起身环视一圈确认（不再重复出声）'
        : '监测中 — 静止 ' + this._stillMin + ' 分钟，满 ' + this._threshold().min + ' 分钟提醒起身'
    });
    this._renderAll();
  },

  _startTimer() {
    // Real-device path: one minute per tick, only while
    // watching or a reminder stands. The timer is stopped
    // on unload, on BACK to idle, and on END.
    if (this._timer) return;
    var self = this;
    try {
      this._timer = setInterval(function () { self._tick(1); }, 60000);
    } catch (e) {}
  },

  _stopTimer() {
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
  },

  // ---------- start / mode / sweep / end ----------

  startTap() {
    if (this._mode === 'watching' || this._mode === 'remind') {
      this.setData({ lastEvent: 'EVT: START refused - already watching, head movement resets the timer' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    // BACK from watching returns to idle with the session
    // kept; START resumes the same session instead of
    // resetting it.
    this._mode = 'watching';
    this._startTimer();
    this.setData({
      status: (this._stillMin > 0 || this._stands > 0)
        ? '监测恢复 — 静止 ' + this._stillMin + ' 分钟，满 ' + this._threshold().min + ' 分钟提醒起身'
        : '监测中 — 静止 0 分钟，满 ' + this._threshold().min + ' 分钟提醒起身',
      lastEvent: 'EVT: watching started - threshold ' + this._threshold().min + ' min'
    });
    this._renderAll();
  },

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - switch the threshold before starting, not mid-watch' });
      return;
    }
    this._thIdx = (this._thIdx + 1) % this._thresholds.length;
    this.setData({
      status: '阈值已换 — 静止满 ' + this._threshold().min + ' 分钟提醒起身，点 START 开始',
      lastEvent: 'EVT: threshold switched to ' + this._threshold().min + ' min'
    });
    this._renderAll();
  },

  sweepTap() {
    if (this._mode !== 'remind') {
      this.setData({ lastEvent: 'EVT: SWEEP ignored - no reminder stands, nothing to confirm' });
      return;
    }
    // SWEEP is the fallback for the yaw sweep: if the host
    // never delivers yaw events, the button is the confirm.
    this._confirmMove();
  },

  _confirmMove() {
    if (this._mode !== 'remind') return;
    this._stands++;
    if (this._stillMin > this._longestStill) this._longestStill = this._stillMin;
    this._stillMin = 0;
    this._sweepLeft = false;
    this._sweepRight = false;
    this._mode = 'watching';
    this.setData({
      status: '已确认 — 环视一圈，起身 ' + this._stands + ' 次，静止计时重新开始',
      lastEvent: 'EVT: sweep confirmed - stand-ups ' + this._stands + ', still timer reset'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the session.
      // BACK is the way back without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始监测' });
      return;
    }
    this._stopTimer();
    this._prevMode = this._mode;
    this._mode = 'summary';
    this._summary = {
      reminds: this._reminds,
      stands: this._stands,
      longestStill: this._longestStill,
      threshold: this._threshold().min
    };
    this.setData({
      status: '结束 — 提醒 ' + this._reminds + ' 次，起身 ' + this._stands + ' 次，最长静止 ' + this._longestStill + ' 分钟，点 END 确认清空，BACK 回监测',
      lastEvent: 'EVT: closed - reminds ' + this._reminds + ', stands ' + this._stands + ', longest ' + this._longestStill + ' min'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._stillMin = 0;
    this._longestStill = 0;
    this._stands = 0;
    this._reminds = 0;
    this._moveCount = 0;
    this._sweepLeft = false;
    this._sweepRight = false;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '起身活动 — START 再次开始监测',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the mode it came
      // from (watching, or remind with the reminder still
      // standing) without deleting anything; the summary is
      // rebuilt on END.
      this._mode = this._prevMode;
      this._summary = null;
      this._startTimer();
      this.setData({
        status: this._mode === 'remind' ? '提醒中 — BACK 回到提醒，提醒还在，环视一圈确认' : '监测中 — BACK 回到监测，计数保留',
        lastEvent: 'EVT: back to ' + this._mode + ' - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'watching' || this._mode === 'remind') {
      // Back to idle keeps the session and stops the timer;
      // START resumes the same session.
      this._stopTimer();
      this._mode = 'idle';
      this.setData({
        status: '起身活动 — 监测已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START watches still time' });
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
      line = '还没开始：START 开始监测';
    } else if (this._mode === 'watching') {
      line = '静止 ' + this._stillMin + ' 分钟，满 ' + this._threshold().min + ' 分钟提醒起身';
    } else if (this._mode === 'remind') {
      line = '该起身活动了，环视一圈确认';
    } else if (this._summary) {
      line = '本次小结：提醒 ' + this._summary.reminds + ' 次，起身 ' + this._summary.stands + ' 次，最长静止 ' + this._summary.longestStill + ' 分钟';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._stillMin > 0 || this._stands > 0 || this._reminds > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this.startTap();
      // DEMO is a staged sample, not a live watch: stop the
      // one-minute timer so the preview frames are
      // deterministic (otherwise live ticks would drift the
      // still minutes between the DEMO tap and the screenshot).
      this._stopTimer();
      this._tick(30);
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - watching, still 30 min (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._tick(15);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - threshold crossed, reminder fired (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      // Yaw sweep, left then right, is the real confirm path.
      this.onOrientationChange({ detail: { yaw: -30 } });
      this.onOrientationChange({ detail: { yaw: 30 } });
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - look-around sweep confirmed, stand-ups 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - summary: reminds 1, stands 1, longest 45 min (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var th = this._threshold();
    var rows = [];
    rows.push({
      idx: 0,
      name: '当前静止',
      detail: this._stillMin + ' 分钟（满 ' + th.min + ' 分钟提醒起身）',
      flag: (this._focus === 0 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 1,
      name: '起身确认',
      detail: this._stands + ' 次（环视一圈算一次）',
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '最长静止',
      detail: this._longestStill + ' 分钟 · 提醒 ' + this._reminds + ' 次 · 头动 ' + this._moveCount + ' 次',
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '静止 ' + this._stillMin + ' 分钟 · 起身 ' + this._stands + ' 次 · 提醒 ' + this._reminds + ' 次 · 阈值 ' + th.min + ' 分钟 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 起身活动 — START 开始监测，MODE 换阈值，SWEEP 环视确认，END 出小结';
      patch.bigLabel = '起身活动 · 待机';
      patch.bigText = (this._stillMin > 0 || this._stands > 0 || this._reminds > 0) ? '监测已停未清' : '还没开始';
      patch.bigNote = '静止满 ' + th.min + ' 分钟提醒起身 · 环视一圈确认活动';
    } else if (this._mode === 'watching') {
      patch.boxLabel = '◎ 监测中 — 头动清零静止计时，点头不是起身，环视才算确认';
      patch.bigLabel = '起身活动 · 监测中';
      patch.bigText = '静止 ' + this._stillMin + ' 分钟';
      patch.bigNote = '满 ' + th.min + ' 分钟提醒起身 · 起身 ' + this._stands + ' 次 · 提醒 ' + this._reminds + ' 次';
    } else if (this._mode === 'remind') {
      patch.boxLabel = '◎ 该起身活动了 — 环视一圈确认，左右都扫过才算';
      patch.bigLabel = '起身活动 · 该起身了';
      patch.bigText = '该起身活动了';
      patch.bigNote = '静止 ' + this._stillMin + ' 分钟 · 环视进度：左' + (this._sweepLeft ? '✓' : '·') + ' 右' + (this._sweepRight ? '✓' : '·') + ' · SWEEP 按键也可确认';
    } else {
      patch.boxLabel = '◎ 本次小结 — 提醒几次、起身几次、最长静止多久钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { reminds: 0, stands: 0, longestStill: 0, threshold: th.min };
      patch.bigText = '起身 ' + sm.stands + ' 次';
      patch.bigNote = '提醒 ' + sm.reminds + ' 次 · 最长静止 ' + sm.longestStill + ' 分钟 · 阈值 ' + sm.threshold + ' 分钟 · 点 END 确认清空 · BACK 回监测';
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
      <text class="title">STAND MOVE v1.0.0</text>
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
      <button class="btn btn-main" bindtap="sweepTap">SWEEP</button>
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
    <text class="foot2">它测不出你是不是真的站起来了——没有身体传感器，环视一圈只是头部转动代理，不是站立证明 · 久坐阈值是固定档位（45 / 60 分钟），不是按你身体状态调整的 · 它不是医疗建议：不诊断腰背问题、不承诺活动效果，严重不适请寻求专业帮助，头晕立即停下 · 只存本次会话，关掉即清 · 没有室内定位，没有摄像头 · 零落盘</text>
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
