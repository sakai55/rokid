<script def>
{
  "navigationBarTitleText": "Play Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '游乐场副线 — 主线休息，副线替你记着抬头看活动区：看向活动区停稳后 REG 登记，每 5 分钟提醒回看一次',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — 看向活动区停稳，REG 登记副线',
    bigLabel: '游乐场副线 · 待机',
    bigText: '活动区未登记',
    bigNote: '登记后每 5 分钟提醒回看 · DEMO 走演示 · TICK 走一格演示计时',
    permLine: 'PERM: 无权限 — 定时提醒 + 头部朝向确认，不拍照、不录音、不定位',
    rows: [],
    countLine: '回看确认 0 次 · 未确认提醒 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look at the play area, hold steady, then REG',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | summary
    this._level = 0; // 0 none | 1 reminder banner | 2 escalated (TTS + brighter) | 3 strong (go look in person)
    this._zone = null; // { label, dir } — a heading the wearer registered, never a tracked position
    this._interval = 5 * 60 * 1000; // DEMO interval: 5 minutes between look-backs
    this._elapsedOffset = 0; // DEMO/advance clock: TICK adds one interval; real time flows on top
    this._startAt = 0;
    this._nextDue = 0;
    this._confirmed = 0;
    this._missed = 0;
    this._log = []; // { label, text } — look-back confirmations only, session memory
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 watching, 2 reminder, 3 escalated, 4 summary
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
    // Session-only by construction: zone, counts, log, level
    // and summary die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up -
    // that IS the design. Close the agent and the outing is
    // gone; the next outing starts from a blank page.
    try { if (this._ticker) clearInterval(this._ticker); } catch (e) {}
    this._ticker = null;
    this._zone = null;
    this._confirmed = 0;
    this._missed = 0;
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
    // where confirmation is safe - REG in idle, SEEN while
    // watching, CONFIRM on the summary screen. A nod is the
    // wearer attesting "I looked at the area"; it is never
    // proof from a sensor that the child was seen.
    if (this._mode === 'idle') { this.regTap(); return; }
    if (this._mode === 'watching') { this.seenTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.regTap();
      else if (this._mode === 'watching') this.seenTap();
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
    this._zone = { label: '活动区', dir: '登记时朝向' };
    this._mode = 'watching';
    this._level = 0;
    this._confirmed = 0;
    this._missed = 0;
    this._log = [];
    this._focus = 0;
    this._summary = null;
    this._startAt = this._now();
    this._nextDue = this._now() + this._interval;
    this.setData({
      status: '守望进行中 — 副线已登记，每 5 分钟提醒回看一次；确认即重置计时',
      lastEvent: 'EVT: side line registered (area heading) - next look-back in 5 minutes'
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
          status: '回看提醒 — 抬头看一眼活动区，确认后计时重置',
          lastEvent: 'EVT: look-back reminder (level 1 banner only, no TTS)'
        });
      } else if (this._level < 3) {
        this._level++;
        this._missed++;
        if (this._level === 2) {
          this._speakText('还没确认，请再看一眼活动区');
          this.setData({
            status: '升级提醒 — 还没确认，TTS 已报一次，请再看一眼活动区',
            lastEvent: 'EVT: escalated (level 2, one TTS) - missed ' + this._missed
          });
        } else {
          this._speakText('请起身去活动区看一眼');
          this.setData({
            status: '强提醒 — 请起身去活动区看一眼',
            lastEvent: 'EVT: strong reminder (level 3, one TTS) - missed ' + this._missed
          });
        }
      } else {
        this._missed++;
        this.setData({
          status: '强提醒 — 请起身去活动区看一眼',
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

  seenTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: SEEN refused - no side line is being watched' });
      return;
    }
    var early = this._level === 0;
    this._confirmed++;
    this._log.push({
      label: this._elapsedText(),
      text: early ? '提前回看确认（未到提醒时间）' : '回看确认（提醒等级' + this._level + '）'
    });
    this._focus = this._log.length - 1;
    this._level = 0;
    this._nextDue = this._now() + this._interval;
    this.setData({
      status: '守望进行中 — 回看已确认，计时重置，下次回看 5 分钟后',
      lastEvent: 'EVT: look-back confirmed (confirmed ' + this._confirmed + ') - timer reset'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: END refused - no side line is being watched' });
      return;
    }
    this._mode = 'summary';
    this._summary = {
      confirmed: this._confirmed,
      missed: this._missed,
      entries: this._log.length
    };
    this.setData({
      status: '本次游玩小结 — 确认后清空本次记录',
      lastEvent: 'EVT: outing ended - summary ready (confirmed ' + this._summary.confirmed + ', missed ' + this._summary.missed + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._zone = null;
    this._confirmed = 0;
    this._missed = 0;
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
      status: '游乐场副线 — 主线休息，副线替你记着抬头看活动区：看向活动区停稳后 REG 登记，每 5 分钟提醒回看一次',
      lastEvent: 'EVT: summary confirmed - outing cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'watching';
      this._summary = null;
      this.setData({
        status: '守望进行中 — 副线已登记，每 5 分钟提醒回看一次；确认即重置计时',
        lastEvent: 'EVT: back to watching - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - END finishes watching, SEEN confirms a look-back' });
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
      line = '游乐场副线待机，看向活动区停稳后按 REG 登记';
    } else if (this._mode === 'watching') {
      if (this._level === 1) {
        line = '回看提醒：抬头看一眼活动区';
      } else if (this._level === 2) {
        line = '还没确认，请再看一眼活动区';
      } else if (this._level === 3) {
        line = '请起身去活动区看一眼';
      } else {
        line = '守望进行中，活动区 ' + (this._zone ? this._zone.label : '') + '，' + this._remainingText() + '，回看确认 ' + this._confirmed + ' 次';
      }
    } else if (this._summary) {
      line = '本次游玩小结：回看确认 ' + this._summary.confirmed + ' 次，未确认提醒 ' + this._summary.missed + ' 次';
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
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._zone = { label: '滑梯区 · 红外套（DEMO 示例）', dir: '登记时朝向' };
      this._mode = 'watching';
      this._level = 0;
      this._confirmed = 0;
      this._missed = 0;
      this._log = [];
      this._focus = 0;
      this._summary = null;
      this._startAt = this._now();
      this._nextDue = this._now() + this._interval;
      this.setData({
        status: 'DEMO - 守望进行中（示例区域，非真实登记）',
        lastEvent: 'EVT: DEMO stage 1 - side line registered (slide area, red jacket DEMO sample)'
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
      this._demoStage = 3;
      this.seenTap();
      this.tickTap();
      this.tickTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - escalated (level 2, one TTS) after one confirmed look-back and one missed reminder' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - summary (confirmed 1, missed 1, DEMO sample)' });
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
    patch.countLine = '回看确认 ' + this._confirmed + ' 次 · 未确认提醒 ' + this._missed + ' 次' +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — 看向活动区停稳，REG 登记副线';
      patch.bigLabel = '游乐场副线 · 待机';
      patch.bigText = '活动区未登记';
      patch.bigNote = '登记后每 5 分钟提醒回看 · DEMO 走演示 · TICK 走一格演示计时';
    } else if (this._mode === 'watching') {
      var zoneText = this._zone ? this._zone.label + '（' + this._zone.dir + '）' : '活动区';
      if (this._level === 1) {
        patch.boxLabel = '◎ 回看提醒 — 抬头看一眼活动区，确认后计时重置';
        patch.bigLabel = '回看提醒';
        patch.bigText = '看一眼活动区';
        patch.bigNote = '区域：' + zoneText + ' · SEEN 确认看到了 · 未确认会升级';
      } else if (this._level === 2) {
        patch.boxLabel = '◎ 升级提醒 — 还没确认，TTS 已报一次，请再看一眼活动区';
        patch.bigLabel = '升级提醒';
        patch.bigText = '还没确认';
        patch.bigNote = '区域：' + zoneText + ' · SEEN 确认看到了 · 再不确认会请你起身去看';
      } else if (this._level === 3) {
        patch.boxLabel = '◎ 强提醒 — 请起身去活动区看一眼';
        patch.bigLabel = '请起身去看一眼';
        patch.bigText = '起身去看一眼';
        patch.bigNote = '区域：' + zoneText + ' · SEEN 确认看到了';
      } else {
        patch.boxLabel = '◎ 守望进行中 — 副线已登记，每 5 分钟提醒回看一次；确认即重置计时';
        patch.bigLabel = '守望进行中';
        patch.bigText = this._remainingText();
        patch.bigNote = '区域：' + zoneText + ' · 回看确认 ' + this._confirmed + ' 次 · SEEN 确认看到了';
      }
    } else {
      patch.boxLabel = '◎ 本次游玩小结';
      patch.bigLabel = '本次游玩小结';
      var s = this._summary || { confirmed: 0, missed: 0, entries: 0 };
      patch.bigText = '确认 ' + s.confirmed + ' 次 · 未确认 ' + s.missed + ' 次';
      patch.bigNote = '回看记录 ' + s.entries + ' 条 · 确认后清空本次记录';
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
      <text class="title">PLAY WATCH v1.0.0</text>
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
      <button class="btn btn-main" bindtap="seenTap">SEEN</button>
      <button class="btn" bindtap="endTap">END</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
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
    <text class="foot2">不是监护或安防设备：没有持续追踪、没有人脸/人体识别、它不知道孩子在哪，只能按你登记的区域朝向定时提醒你抬头确认；孩子仍需家长视线监护 · 确认是你本人的表态（点头需头稳、点按即确认），不是传感器证明孩子被看见 · 本次游玩数据只存会话内存，关掉即清 · 无权限：不拍照、不录音、不定位 · 计时是演示 5 分钟一格，到时提醒、未确认才升级</text>
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
