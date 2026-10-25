<script def>
{
  "navigationBarTitleText": "Cue Desk"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '书桌提示 — 坐到书桌前先刷十分钟手机才进入状态，站起来又忘刚才做到哪：看向书桌停稳才亮今日三件事，起身时按未完成项给一句「回来从这继续」',
    steadyText: 'HEAD: moving - look at the desk and hold still',
    boxLabel: '◎ 今日三件事 — 看向书桌停稳，TRIG 亮三件事',
    bigLabel: '今日三件事 · 待机',
    bigText: '还没触发',
    bigNote: '看向书桌停稳 · TRIG 亮三件事 · 起身给续接句',
    permLine: 'PERM: 无权限 — 只做书桌三件事提醒；不拍照、不录音、不定位；三件事是你预设的，不是日历同步的；起身是你点的，不是检测到的',
    rows: [],
    countLine: '已做 0/3 · 未完成 3 项 · 起身 0 次 · 只存本次坐桌会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look at the desk, hold steady, TRIG lights up the three tasks',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | list | summary
    this._names = ['写报告', '回邮件', '整理桌面'];
    // per-item state: 'none' | 'done'
    this._state = ['none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._ups = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 triggered, 2-3 done, 4 resume summary, 5 back to list, 6 all done, 7 all-done summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the three tasks, their
    // ticks, the stand-up count and the summary die with the
    // page. Nothing was ever written anywhere persistent, so
    // there is nothing to clean up — that IS the design.
    // Standing up is the wearer's own tap, never a sensor
    // detection; the three tasks are the wearer's preset,
    // never a calendar sync; a tick is the wearer's own
    // statement, never a sensor proof.
    this._mode = 'idle';
    this._state = ['none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._ups = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _pending() {
    var m = [], i;
    for (i = 0; i < this._names.length; i++) {
      if (this._state[i] === 'none') m.push(this._names[i]);
    }
    return m;
  },

  _doneCount() {
    var c = 0, i;
    for (i = 0; i < this._state.length; i++) { if (this._state[i] === 'done') c++; }
    return c;
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - look at the desk and hold still'
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
      this.setData({ lastEvent: 'EVT: nod ignored - look at the desk and hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod triggers the
    // three tasks in idle, ticks the focused task in the list,
    // or confirms the summary. A nod never picks a task and
    // never stands you up on its own: standing up is UP.
    if (this._mode === 'idle') { this.trigTap(); return; }
    if (this._mode === 'list') { this.gotTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.trigTap();
      else if (this._mode === 'list') this.gotTap();
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

  // ---------- trigger ----------

  _trigger(demo) {
    this._mode = 'list';
    this._triggered = true;
    this._focus = 0;
    this.setData({
      status: demo
        ? '今日三件事已亮（DEMO 示例）— 做完一项勾一项，起身给续接句'
        : '今日三件事已亮 — 做完一项勾一项，起身给续接句',
      lastEvent: demo ? 'EVT: DEMO stage 1 - three tasks lit (DEMO sample)' : 'EVT: three tasks lit - look confirmed at the desk'
    });
    this._renderAll();
  },

  trigTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TRIG refused - the tasks are already lit or a summary is up' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: TRIG refused - look at the desk and hold steady first' });
      return;
    }
    this._trigger(false);
  },

  // ---------- tick / stand up ----------

  gotTap() {
    if (this._mode !== 'list') {
      this.setData({ lastEvent: 'EVT: GOT refused - tick tasks in the list, not in idle or summary' });
      return;
    }
    var st = this._state[this._focus];
    if (st === 'done') {
      this.setData({ lastEvent: 'EVT: GOT refused - ' + this._names[this._focus] + ' already done' });
      return;
    }
    this._state[this._focus] = 'done';
    var n = this._doneCount();
    this.setData({
      status: '已做：' + this._names[this._focus] + '（' + n + '/3）— 继续做剩下的，起身给续接句',
      lastEvent: 'EVT: done - ' + this._names[this._focus] + ' (' + n + '/3)'
    });
    this._renderAll();
  },

  upTap() {
    if (this._mode === 'summary') {
      // In summary, UP is the confirm: it wipes the round.
      // BACK is the way back to the list without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: UP refused - missing: 先看向书桌停稳亮三件事（TRIG）' });
      return;
    }
    // list mode: standing up is the wearer's own tap, never a
    // sensor detection. With pending tasks it speaks exactly
    // one resume line naming the FIRST pending task and opens
    // the summary with it recorded; with all three done it
    // says all three are done. UP never blocks: it reports
    // and records, then the summary is the close.
    var pending = this._pending();
    this._ups++;
    if (pending.length > 0) {
      var line = '回来从这继续：' + pending[0];
      this._speakText(line);
      this._mode = 'summary';
      this._summary = {
        done: this._doneCount(),
        pending: pending,
        ups: this._ups,
        resumeLine: line,
        allDone: false
      };
      this.setData({
        status: '起身续接 — ' + line,
        lastEvent: 'EVT: stood up - resume: ' + pending[0] + ' (stand ' + this._ups + ')'
      });
    } else {
      this._speakText('三件事都做完了');
      this._mode = 'summary';
      this._summary = {
        done: 3,
        pending: [],
        ups: this._ups,
        resumeLine: null,
        allDone: true
      };
      this.setData({
        status: '起身 — 三件事都做完了，点 UP 确认清空，BACK 返回三件事',
        lastEvent: 'EVT: stood up - all three done (stand ' + this._ups + ')'
      });
    }
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._state = ['none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._ups = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '书桌提示 — 坐到书桌前先刷十分钟手机才进入状态，站起来又忘刚才做到哪：看向书桌停稳才亮今日三件事，起身时按未完成项给一句「回来从这继续」',
      lastEvent: 'EVT: summary confirmed - tasks cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the list without
      // deleting anything; the summary is rebuilt on UP.
      this._mode = 'list';
      this._summary = null;
      this.setData({
        status: '今日三件事 — 继续做，或 UP 起身',
        lastEvent: 'EVT: back to list - summary kept for rebuild on UP'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'list') {
      // Back to idle keeps the ticks:
      // re-triggering restores the same three tasks.
      this._mode = 'idle';
      this.setData({
        status: '书桌提示 — 看向书桌停稳，TRIG 再次亮三件事（已做保留）',
        lastEvent: 'EVT: back to idle - ticks kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - TRIG lights up the three tasks' });
  },

  _focusLen() {
    if (this._mode === 'idle') return 0;
    return this._names.length;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
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
      line = '还没触发：看向书桌停稳，TRIG 亮三件事';
    } else if (this._mode === 'list') {
      var pending = this._pending();
      if (pending.length === 0) {
        line = '三件事都做完了，可以起身';
      } else {
        line = '已做 ' + this._doneCount() + '/3，还没做 ' + pending.join('、');
      }
    } else if (this._summary) {
      line = this._summary.allDone
        ? '本次坐桌小结：三件事都做完了'
        : '本次坐桌小结：已做 ' + this._summary.done + '/3，' + this._summary.resumeLine;
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary' && this._demoStage !== 4) {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user task list is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._doneCount() > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user ticks are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._trigger(true);
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._focus = 0;
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 写报告 done (DEMO sample, 1/3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._focus = 1;
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 回邮件 done (DEMO sample, 2/3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.upTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - stood up, resume 整理桌面 (DEMO sample, reminder not a gate)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.backTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - back to list, ticks kept (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this._focus = 2;
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - 整理桌面 done (DEMO sample, 3/3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.upTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - summary: all three done (DEMO sample)' });
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
      rows.push({
        idx: 0,
        name: '暂未触发',
        detail: '看向书桌停稳，TRIG 亮三件事（预设：写报告 / 回邮件 / 整理桌面）',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._names.length; i++) {
        var detail = '';
        var flag = '';
        if (this._state[i] === 'done') { detail = '已做（你本人的表态，不是检测）'; flag = '✓'; }
        else { detail = '还没做'; flag = (this._focus === i ? '▶' : '○'); }
        rows.push({
          idx: i,
          name: this._names[i],
          detail: detail,
          flag: flag,
          cls: 'row'
        });
      }
    }

    var n = this._doneCount();
    var pending = this._pending();
    var patch = { rows: rows };
    patch.countLine = '已做 ' + n + '/3 · 未完成 ' + pending.length + ' 项 · 起身 ' + this._ups + ' 次 · 只存本次坐桌会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 今日三件事 — 看向书桌停稳，TRIG 亮三件事';
      patch.bigLabel = '今日三件事 · 待机';
      patch.bigText = '还没触发';
      patch.bigNote = '看向书桌停稳 · TRIG 亮三件事 · 起身给续接句';
    } else if (this._mode === 'list') {
      patch.boxLabel = '◎ 今日三件事 — GOT 勾掉当前项，UP 起身给续接句';
      patch.bigLabel = '今日三件事 · 第 ' + (this._focus + 1) + '/3 项';
      patch.bigText = '已做 ' + n + '/3';
      patch.bigNote = pending.length === 0
        ? '三件事都做完了 · UP 起身出小结 · BACK 回待机（已做保留）'
        : '还没做 ' + pending.join('、') + ' · UP 起身给续接句';
    } else {
      patch.boxLabel = '◎ 本次坐桌小结 — 已做、未完成、续接句钉在下面';
      patch.bigLabel = '本次坐桌小结';
      var s = this._summary || { done: 0, pending: [], ups: 0, resumeLine: null, allDone: false };
      patch.bigText = s.allDone ? '三件事都做完了' : '回来从这继续';
      patch.bigNote = s.allDone
        ? '已做 3/3 · 起身 ' + s.ups + ' 次 · 点 UP 确认清空 · BACK 返回三件事'
        : '首个未完成：' + (s.pending[0] || '') + ' · 已做 ' + s.done + '/3 · 起身 ' + s.ups + ' 次 · 点 UP 确认清空 · BACK 返回三件事';
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
      <text class="title">CUE DESK v1.0.0</text>
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
      <button class="btn btn-main" bindtap="trigTap">TRIG</button>
      <button class="btn btn-main" bindtap="gotTap">GOT</button>
      <button class="btn btn-main" bindtap="upTap">UP</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
    </view>
    <view class="actions">
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
    <text class="foot2">起身是你自己点的，不是 Agent 检测到你站起来了；今日三件事是你预设的，不是日历同步的；勾掉只是你本人的表态，不是传感器证明；只存本次坐桌会话，关掉即清；没有室内定位；零落盘；看向触发在真机上由头部停稳判定，预览中由 DEMO 演示</text>
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
