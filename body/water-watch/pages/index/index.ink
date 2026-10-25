<script def>
{
  "navigationBarTitleText": "Water Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '喝水提醒 — 忙起来一天喝不上两杯水，渴了才想起水杯就在手边：看向水杯登记位置，久未看向水杯（=久未喝水）时轻轻亮屏提醒，喝完凝视确认',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 喝水守望 — REG 看向水杯登记，DRINK 喝完凝视确认，END 出小结',
    bigLabel: '喝水提醒 · 待机',
    bigText: '还没登记',
    bigNote: 'REG 看向水杯登记 · 久未看向轻轻亮屏提醒 · 喝完凝视确认',
    permLine: 'PERM: 无权限 — 方向传感器（头稳）+ 计时 + 提醒；不拍照、不录音、不定位',
    rows: [],
    countLine: '距上次喝水 0 分钟 · 喝水 0 次 · 提醒 0 次 · 最长间隔 0 分钟 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - REG registers the cup direction, DRINK confirms a drink, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | remind | summary
    this._threshold = 60; // minutes since last drink before a gentle reminder
    this._since = 0; // minutes since the last confirmed drink
    this._drinks = 0;
    this._reminds = 0;
    this._longest = 0; // longest completed interval, minutes
    this._cupPos = null; // registered cup direction, session only
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 registered, 2 watching 45 min, 3 remind at 65 min, 4 drink confirmed, 5 summary
    this._nodLock = false;
    this._timer = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the cup position, the
    // interval, drink/reminder counts and the summary die
    // with the page. Nothing was ever written anywhere
    // persistent, so there is nothing to clean up — that IS
    // the design.
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
    this._mode = 'idle';
    this._since = 0;
    this._drinks = 0;
    this._reminds = 0;
    this._longest = 0;
    this._cupPos = null;
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
    // not take effect. Speech happens only via SPEAK: the
    // gentle reminder is a silent banner by design, never a
    // spoken interruption.
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
    // Nod discipline in THIS agent: a steady nod registers
    // the cup in idle and confirms the summary. A nod never
    // confirms a drink: only a steady gaze at the cup (or
    // the DRINK button) confirms one — a nod is not a drink,
    // and must not be counted as one.
    if (this._mode === 'idle') { this.regTap(); return; }
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: nod ignored while watching - a drink is confirmed by gazing at the cup, not by nodding' });
      return;
    }
    if (this._mode === 'remind') {
      this.setData({ lastEvent: 'EVT: nod ignored during reminder - gaze at the cup to confirm a drink, a nod is not a drink' });
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
      if (this._mode === 'idle') this.regTap();
      else if (this._mode === 'watching') {
        this.setData({ lastEvent: 'EVT: Enter ignored while watching - a drink is confirmed by gazing at the cup, not by a key' });
      }
      else if (this._mode === 'remind') {
        this.setData({ lastEvent: 'EVT: Enter ignored during reminder - gaze at the cup to confirm a drink, a key is not a drink' });
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
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: tick ignored - not watching' });
      return;
    }
    // Unlike eye-rest, this interval is wall-clock time since
    // the last drink: it passes whether or not the head is
    // moving. Only the registration and the drink confirm
    // need a steady gaze.
    var m = mins || 1;
    this._since += m;
    if (this._since >= this._threshold) {
      this._mode = 'remind';
      this._reminds++;
      this.setData({
        status: '该喝水了 — 距上次喝水已 ' + this._since + ' 分钟，水杯就在手边，喝完看向水杯凝视确认（DRINK 也可确认）',
        lastEvent: 'EVT: gentle reminder ' + this._reminds + ' - ' + this._since + ' min since last drink, banner only, zero TTS'
      });
      // Gentle means silent: the reminder is a banner in
      // view, never a spoken interruption. SPEAK reads it
      // only when you tap SPEAK.
      this._renderAll();
      return;
    }
    this.setData({
      status: '守望中 — 距上次喝水 ' + this._since + ' 分钟，满 ' + this._threshold + ' 分钟轻轻亮屏提醒',
      lastEvent: 'EVT: tick +' + m + ' min - since last drink ' + this._since + ' min'
    });
    this._renderAll();
  },

  _startTimer() {
    // Real-device path: one minute per tick, only while
    // watching. The interval is stopped on unload and on END.
    if (this._timer) return;
    var self = this;
    try {
      this._timer = setInterval(function () { self._tick(1); }, 60000);
    } catch (e) {}
  },

  _stopTimer() {
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
  },

  // ---------- register / drink / end ----------

  regTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: REG refused - cup already registered, watching or summarising' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: REG refused - look toward the cup and hold steady first' });
      return;
    }
    // BACK from watching returns to idle with the round kept;
    // REG resumes the same round instead of resetting it.
    this._cupPos = '已登记（你看向的方向）';
    this._mode = 'watching';
    this._startTimer();
    this.setData({
      status: (this._drinks > 0 || this._reminds > 0)
        ? '守望恢复 — 水杯已登记，距上次喝水 ' + this._since + ' 分钟'
        : '守望中 — 水杯已登记，距上次喝水开始计时，满 ' + this._threshold + ' 分钟轻轻亮屏提醒',
      lastEvent: 'EVT: cup registered - watching since last drink'
    });
    this._renderAll();
  },

  drinkTap() {
    if (this._mode !== 'watching' && this._mode !== 'remind') {
      this.setData({ lastEvent: 'EVT: DRINK ignored - register the cup first, then confirm a drink' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: DRINK refused - look toward the cup and hold steady to confirm' });
      return;
    }
    // A drink completes the interval: the interval is
    // recorded (longest kept), the timer resets, and the
    // reminder — if one was open — clears with it.
    if (this._since > this._longest) this._longest = this._since;
    this._drinks++;
    this._since = 0;
    this._mode = 'watching';
    this.setData({
      status: '喝水已确认 — 第 ' + this._drinks + ' 次，计时重新开始，满 ' + this._threshold + ' 分钟再提醒',
      lastEvent: 'EVT: drink confirmed ' + this._drinks + ' - interval recorded, timer reset'
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
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 REG 登记水杯' });
      return;
    }
    this._stopTimer();
    this._mode = 'summary';
    this._summary = {
      drinks: this._drinks,
      longest: this._longest,
      reminds: this._reminds,
      since: this._since
    };
    this.setData({
      status: '结束 — 喝水 ' + this._drinks + ' 次，最长间隔 ' + this._longest + ' 分钟，提醒 ' + this._reminds + ' 次，点 END 确认清空，BACK 回守望',
      lastEvent: 'EVT: closed - drinks ' + this._drinks + ', longest ' + this._longest + ' min, reminds ' + this._reminds
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._since = 0;
    this._drinks = 0;
    this._reminds = 0;
    this._longest = 0;
    this._cupPos = null;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '喝水提醒 — REG 再次登记水杯',
      lastEvent: 'EVT: summary confirmed - drinks and intervals cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      // If nothing was ever registered, return to idle.
      this._mode = (this._cupPos) ? 'watching' : 'idle';
      this._summary = null;
      if (this._mode === 'watching') this._startTimer();
      this.setData({
        status: this._mode === 'watching' ? '守望中 — BACK 回到守望，计数保留' : '喝水提醒 — BACK 回到待机',
        lastEvent: 'EVT: back to ' + this._mode + ' - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'remind') {
      // Back from a reminder returns to watching with the
      // interval still owed: the minutes are NOT reset, so
      // the next tick re-raises it. Looking away from the
      // banner is not a drink.
      this._mode = 'watching';
      this.setData({
        status: '守望中 — BACK 回到守望，提醒未完成：距上次喝水 ' + this._since + ' 分钟仍满 ' + this._threshold + ' 分钟，下次计时即重提醒',
        lastEvent: 'EVT: back to watching - reminder still owed, interval kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'watching') {
      // Back from watching returns to idle with the round kept
      // and the timer stopped; REG resumes the same round.
      this._stopTimer();
      this._mode = 'idle';
      this.setData({
        status: '喝水提醒 — 水杯已登记未清，REG 恢复守望',
        lastEvent: 'EVT: back to idle - round kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - REG registers the cup' });
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
      line = '还没登记：REG 看向水杯登记';
    } else if (this._mode === 'watching') {
      line = '守望中，距上次喝水 ' + this._since + ' 分钟，喝水 ' + this._drinks + ' 次';
    } else if (this._mode === 'remind') {
      line = '该喝水了，水杯就在手边';
    } else if (this._summary) {
      line = '本次小结：喝水 ' + this._summary.drinks + ' 次，最长间隔 ' + this._summary.longest + ' 分钟，提醒 ' + this._summary.reminds + ' 次';
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user watching session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._drinks > 0 || this._reminds > 0 || this._cupPos)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user round is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY - ready' });
      this.regTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - cup registered (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._tick(45);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 45 min since last drink, no reminder yet (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._tick(20);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 65 min reached, gentle banner reminder, zero TTS (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.drinkTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - steady gaze at the cup, drink 1 confirmed (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: drinks 1, longest 65 min, reminds 1 (DEMO sample)' });
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
      name: '水杯位置',
      detail: this._cupPos ? this._cupPos : '未登记（看向水杯停稳后点 REG）',
      flag: (this._focus === 0 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 1,
      name: '距上次喝水',
      detail: this._since + ' 分钟（满 ' + this._threshold + ' 分钟轻轻亮屏提醒）',
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '喝水次数',
      detail: this._drinks + ' 次（最长间隔 ' + this._longest + ' 分钟 · 提醒 ' + this._reminds + ' 次）',
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '距上次喝水 ' + this._since + ' 分钟 · 喝水 ' + this._drinks + ' 次 · 提醒 ' + this._reminds + ' 次 · 最长间隔 ' + this._longest + ' 分钟 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 喝水守望 — REG 看向水杯登记，DRINK 喝完凝视确认，END 出小结';
      patch.bigLabel = '喝水提醒 · 待机';
      patch.bigText = (this._cupPos) ? '水杯已登记' : '还没登记';
      patch.bigNote = 'REG 看向水杯登记 · 久未看向轻轻亮屏提醒 · 喝完凝视确认';
    } else if (this._mode === 'watching') {
      patch.boxLabel = '◎ 守望中 — 距上次喝水计时中，满 60 分钟轻轻亮屏提醒（不出声）';
      patch.bigLabel = '喝水提醒 · 守望中';
      patch.bigText = '距上次喝水 ' + this._since + ' 分钟';
      patch.bigNote = '喝水 ' + this._drinks + ' 次 · 提醒 ' + this._reminds + ' 次 · 最长间隔 ' + this._longest + ' 分钟';
    } else if (this._mode === 'remind') {
      patch.boxLabel = '◎ 该喝水了 — 水杯就在手边，喝完看向水杯凝视确认（DRINK 也可确认），点头不算喝水';
      patch.bigLabel = '喝水提醒 · 该喝水了';
      patch.bigText = '该喝水了';
      patch.bigNote = '距上次喝水 ' + this._since + ' 分钟 · 轻轻亮屏提醒，不出声 · SPEAK 才读';
    } else {
      patch.boxLabel = '◎ 本次小结 — 喝水次数、最长间隔、提醒次数钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { drinks: 0, longest: 0, reminds: 0 };
      patch.bigText = '喝水 ' + sm.drinks + ' 次';
      patch.bigNote = '最长间隔 ' + sm.longest + ' 分钟 · 提醒 ' + sm.reminds + ' 次 · 点 END 确认清空 · BACK 回守望';
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
      <text class="title">WATER WATCH v1.0.0</text>
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
      <button class="btn btn-main" bindtap="drinkTap">DRINK</button>
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
    <text class="foot2">喝水本身测不出来——「看向水杯」只是喝水代理：它记录的是你看向水杯方向并停稳，不是你真的喝了水 · 水杯位置是你登记的方向朝向，不是定位追踪——水杯挪了位置要重新登记 · 它不是健康建议，不承诺补水效果 · 只存本次会话，关掉即清 · 没有室内定位，没有摄像头 · 零落盘</text>
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
