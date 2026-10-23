<script def>
{
  "navigationBarTitleText": "Home Patrol"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PATROL: look at each point, tap CHECK',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: PATROL · ITEM: 大门锁',
    progLine: 'PROGRESS: 0/6 · reg headings: 0/6',
    rows: [
      { text: '○ 大门锁 · no heading' }
    ],
    curName: 'NOW: 大门锁',
    cueLine: '拉一下门把，确认已经反锁',
    arrow: '·',
    guideLine: 'NO HEADING — check by eye, tap CHECK',
    guideCls: 'rel',
    lastEvent: 'EVT: patrol logs that you LOOKED - it cannot verify a valve',
    busy: false
  },

  onLoad() {
    this._mode = 'PATROL';
    this._defs = this._pointDefs();
    this._regs = this._loadRegs();
    this._checks = this._freshChecks();
    this._sel = 0;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 45;
    this._sensor = null;
    this._timer = null;
    this._steady = false;
    this._lastSpeak = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopHeading();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._saveRegs();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    if (this._mode === 'SETUP') { this.regTap(); return; }
    // PATROL: nod checks only when facing the point or it has no heading.
    if (this._sel < 0) { this.speakTap(); return; }
    var st = this._facingState(this._sel);
    if (st === 'facing' || st === 'none') {
      this.checkTap();
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - face the point first, or tap CHECK' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.itemTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'SETUP') this.regTap(); else this.checkTap();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  // ---------- the six fixed checkpoints ----------

  _pointDefs() {
    return [
      { name: '大门锁', cue: '拉一下门把，确认已经反锁' },
      { name: '客厅窗', cue: '看锁扣扣上、窗扇关严再打勾' },
      { name: '卧室窗', cue: '看锁扣扣上、窗扇关严再打勾' },
      { name: '燃气阀', cue: '看阀门手柄，确认已关到位再打勾' },
      { name: '水龙头', cue: '看龙头口无滴水再打勾' },
      { name: '空调电源', cue: '看指示灯已灭、遥控已关再打勾' }
    ];
  },

  _freshChecks() {
    var out = [];
    for (var i = 0; i !== 6; i++) out.push({ done: false, how: '' });
    return out;
  },

  _doneCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._checks[i].done) n++;
    return n;
  },

  // ---------- persistence (wx sync storage, key 'homePatrolPoints') ----------

  _loadRegs() {
    var out = [];
    var i;
    for (i = 0; i !== 6; i++) out.push({ name: this._defs[i].name, headingDeg: null, demo: false });
    try {
      var raw = wx.getStorageSync('homePatrolPoints');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return out;
      for (i = 0; i !== raw.length; i++) {
        var r = raw[i];
        if (!r || typeof r.name !== 'string') continue;
        for (var j = 0; j !== 6; j++) {
          if (this._defs[j].name === r.name) {
            if (isFinite(r.headingDeg)) {
              out[j].headingDeg = ((Math.round(r.headingDeg) % 360) + 360) % 360;
              out[j].demo = !!r.demo;
            }
            break;
          }
        }
      }
      return out;
    } catch (e) {
      return out;
    }
  },

  _saveRegs() {
    // DEMO headings are a simulation: never overwrite real registrations.
    if (this._demo) return;
    try {
      var out = [];
      for (var i = 0; i !== 6; i++) {
        out.push({
          name: this._regs[i].name,
          headingDeg: this._regs[i].headingDeg,
          demo: !!this._regs[i].demo
        });
      }
      wx.setStorageSync('homePatrolPoints', out);
    } catch (e) { /* storage unavailable on this host: regs stay in memory */ }
  },

  _regCount() {
    var n = 0;
    for (var i = 0; i !== 6; i++) if (this._regs[i].headingDeg !== null) n++;
    return n;
  },

  // ---------- heading (AbsoluteOrientationSensor, same as exit-radar) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._recompute();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onHeading(s); });
      s.addEventListener('error', function (ev) {
        self._headingSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - heading NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._headingSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopHeading() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  _yawDeg(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    var deg = yaw * 180 / Math.PI;
    return (deg + 360) % 360;
  },

  _onHeading(sensor) {
    if (this._demo) return; // demo heading wins while simulating
    var deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    var changed = this._heading === null || Math.abs(deg - this._heading) >= 1;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (changed) this._recompute();
  },

  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      } else {
        self._recompute();
      }
    }, 5000);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- relative-angle math (same convention as siblings) ----------

  _rel(headingDeg, current) {
    return ((headingDeg - current + 540) % 360) - 180; // -180..180, + = right
  },

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  // 'none' = no heading registered; 'na' = registered but no live heading;
  // 'facing' = |rel| <= 20; 'away' = registered + live heading, not facing.
  _facingState(i) {
    var reg = this._regs[i].headingDeg;
    if (reg === null) return 'none';
    if (this._heading === null) return 'na';
    return Math.abs(this._rel(reg, this._heading)) <= 20 ? 'facing' : 'away';
  },

  _nextPending(from) {
    for (var k = 0; k !== 6; k++) {
      var i = (from + k) % 6;
      if (!this._checks[i].done) return i;
    }
    return -1;
  },

  // ---------- modes / selection ----------

  modeTap() {
    this._mode = this._mode === 'PATROL' ? 'SETUP' : 'PATROL';
    if (this._mode === 'PATROL' && this._sel >= 0 && this._checks[this._sel].done) {
      this._sel = this._nextPending(this._sel);
    }
    if (this._mode === 'PATROL' && this._sel < 0) this._sel = this._nextPending(0);
    this.setData({
      status: this._mode === 'PATROL'
        ? 'PATROL: look at each point, tap CHECK'
        : 'SETUP: look at the point, tap REG to bind its heading',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  itemTap() {
    if (this._mode === 'SETUP') {
      this._sel = ((this._sel < 0 ? 0 : this._sel) + 1) % 6;
    } else {
      // PATROL: cycle among the points still to check.
      var nxt = this._nextPending((this._sel < 0 ? 0 : this._sel) + 1);
      if (nxt >= 0) this._sel = nxt;
    }
    this.setData({ lastEvent: 'EVT: item -> ' + this._defs[this._sel < 0 ? 0 : this._sel].name });
    this._recompute();
  },

  // ---------- SETUP: register a heading ----------

  regTap() {
    if (this._mode !== 'SETUP') {
      this.setData({ lastEvent: 'EVT: REG is SETUP only - tap MODE first' });
      return;
    }
    if (this._sel < 0) this._sel = 0;
    if (this._heading === null) {
      // Same honesty rule as the siblings: never invent a heading.
      this.setData({
        status: 'REG FAIL: no heading - DEMO or wait for sensor',
        lastEvent: 'EVT: REG refused - never invent a heading'
      });
      return;
    }
    var h = Math.round(this._heading);
    this._regs[this._sel].headingDeg = h;
    this._regs[this._sel].demo = !!this._demo;
    this._saveRegs();
    this.setData({
      status: 'REGISTERED: ' + this._defs[this._sel].name + ' · ' + h + '°',
      lastEvent: 'EVT: heading bound ' + this._defs[this._sel].name + ' at ' + h +
        ' deg' + (this._demo ? ' (DEMO, not saved)' : '')
    });
    this._recompute();
  },

  // ---------- PATROL: check the current point ----------

  checkTap() {
    if (this._mode !== 'PATROL') {
      this.setData({ lastEvent: 'EVT: CHECK is PATROL only - tap MODE first' });
      return;
    }
    if (this._sel < 0 || this._doneCount() >= 6) {
      this.setData({ lastEvent: 'EVT: patrol already complete - RESET for a new one' });
      return;
    }
    var i = this._sel;
    if (this._checks[i].done) {
      this._sel = this._nextPending(i);
      this._recompute();
      return;
    }
    // How was it checked? 'facing' only when the heading guide says the
    // user is actually looking at the registered point right now.
    var how = this._facingState(i) === 'facing' ? 'facing' : 'tap';
    this._checks[i] = { done: true, how: how };
    var n = this._doneCount();
    var name = this._defs[i].name;
    this._sel = this._nextPending(i + 1);
    if (n >= 6) {
      this.setData({
        status: 'ALL CLEAR — 可以出门',
        lastEvent: 'EVT: patrol complete 6/6 - spoken send-off sent'
      });
      this._recompute();
      this._speakText('全部检查完，可以出门了。六个检查点都逐项看过了。');
      return;
    }
    this.setData({
      status: 'CHECKED ' + n + '/6: ' + name + ' ✓ (' + how + ')',
      lastEvent: 'EVT: ' + name + ' checked via ' + how + ' - next: ' +
        this._defs[this._sel].name
    });
    this._recompute();
  },

  resetTap() {
    this._checks = this._freshChecks();
    this._sel = this._nextPending(0);
    this.setData({
      status: this._mode === 'PATROL'
        ? 'PATROL: look at each point, tap CHECK'
        : 'SETUP: look at the point, tap REG to bind its heading',
      lastEvent: 'EVT: new patrol - checks cleared, registrations kept'
    });
    this._recompute();
  },

  clearTap() {
    if (this._demo) {
      // Leaving DEMO: drop the simulated headings, restore real ones.
      this._demo = false;
      this._regs = this._loadRegs();
      this._checks = this._freshChecks();
      this._sel = this._nextPending(0);
      this._heading = null;
      this._headingSrc = 'NONE';
      this._startHeading();
      this.setData({
        status: 'PATROL: look at each point, tap CHECK',
        lastEvent: 'EVT: DEMO off - your saved registrations restored'
      });
      this._recompute();
      return;
    }
    for (var i = 0; i !== 6; i++) {
      this._regs[i].headingDeg = null;
      this._regs[i].demo = false;
    }
    this._saveRegs();
    this._checks = this._freshChecks();
    this._sel = this._nextPending(0);
    this.setData({
      status: 'PATROL: look at each point, tap CHECK',
      lastEvent: 'EVT: all registered headings cleared'
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO binds simulated headings 40/90/160/230/300/340 (in memory only,
  // real registrations are never overwritten), starts the patrol facing
  // 45 deg - 5 deg off the first point (40 deg), so point 1 is FACING and
  // gets pre-checked; the patrol lands at 1/6 on the living-room window
  // (90 deg, TURN: RIGHT-FRONT 45). Further taps step heading +45.
  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 45;
      this._heading = 45;
      this._headingSrc = 'DEMO';
      var hs = [40, 90, 160, 230, 300, 340];
      for (var i = 0; i !== 6; i++) {
        this._regs[i] = { name: this._defs[i].name, headingDeg: hs[i], demo: true };
      }
      this._checks = this._freshChecks();
      this._checks[0] = { done: true, how: 'facing' };
      this._mode = 'PATROL';
      this._sel = 1;
      this.setData({
        status: 'DEMO PATROL 1/6 - heading 45 deg (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO on - 6 headings in (memory only), 大门锁 pre-checked facing'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      this.setData({
        status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
      });
    }
    this._recompute();
  },

  // ---------- recompute view ----------

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var done = this._doneCount();
    var selName = this._sel >= 0 ? this._defs[this._sel].name : '(none)';
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode + ' · ITEM: ' + selName,
      progLine: 'PROGRESS: ' + done + '/6 · reg headings: ' + this._regCount() + '/6'
    };
    var self = this;
    patch.rows = this._defs.map(function (d, i) {
      var c = self._checks[i];
      var r = self._regs[i];
      var regTxt = r.headingDeg === null ? 'no heading' : 'reg ' + r.headingDeg + '°';
      var mark = c.done ? ('✓ ' + c.how) : '○';
      var cur = (!c.done && i === self._sel && self._mode === 'PATROL') ? '▸ ' : '';
      return { text: cur + d.name + ' · ' + mark + ' · ' + regTxt };
    });

    if (this._mode === 'SETUP') {
      var si = this._sel < 0 ? 0 : this._sel;
      var sr = this._regs[si];
      patch.curName = 'SETUP: ' + this._defs[si].name;
      patch.cueLine = this._defs[si].cue;
      patch.arrow = '◎';
      patch.guideLine = sr.headingDeg === null
        ? 'UNREGISTERED — look at it, tap REG'
        : 'REGISTERED ' + sr.headingDeg + '° — REG again to re-bind';
      patch.guideCls = 'rel';
      this._lastSpeak = {
        text: '设置模式。当前检查点是' + this._defs[si].name + '。' +
          (sr.headingDeg === null ? '还没有登记朝向。' : '已登记在' + sr.headingDeg + '度。')
      };
      this.setData(patch);
      return;
    }

    // PATROL
    if (done >= 6) {
      patch.curName = 'ALL CLEAR — 可以出门';
      patch.cueLine = '6/6 都逐项看过了 — 出门吧';
      patch.arrow = '✓';
      patch.guideLine = 'ALL CLEAR — 可以出门';
      patch.guideCls = 'rel rel-on';
      this._lastSpeak = { text: '全部检查完，可以出门了。六个检查点都逐项看过了。' };
      this.setData(patch);
      return;
    }
    if (this._sel < 0) this._sel = this._nextPending(0);
    var i2 = this._sel;
    var def = this._defs[i2];
    var reg = this._regs[i2].headingDeg;
    patch.curName = 'NOW: ' + def.name;
    patch.cueLine = def.cue;
    var st = this._facingState(i2);
    if (st === 'none') {
      patch.arrow = '·';
      patch.guideLine = 'NO HEADING — check by eye, tap CHECK';
      patch.guideCls = 'rel';
    } else if (st === 'na') {
      patch.arrow = '·';
      patch.guideLine = 'HEADING N/A (SRC NONE) — check by eye, tap CHECK';
      patch.guideCls = 'rel';
    } else {
      var rel = this._rel(reg, this._heading);
      var rel360 = (reg - this._heading + 360) % 360;
      var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
      patch.arrow = arrows[Math.round(rel360 / 45) % 8];
      var deg = Math.round(Math.abs(rel));
      if (st === 'facing') {
        patch.guideLine = 'FACING IT — look carefully, then CHECK';
        patch.guideCls = 'rel rel-on';
      } else {
        patch.guideLine = 'TURN: ' + this._dirName(rel).en + ' ' + deg + '° — reg ' + reg + '°';
        patch.guideCls = 'rel';
      }
    }
    var left = 6 - done;
    this._lastSpeak = {
      text: '还剩' + left + '项。当前一项：' + def.name + '。' + def.cue + '。'
    };
    this.setData(patch);
  },

  // ---------- speech ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    var s = this._lastSpeak;
    var text = s ? s.text : '还没有巡检进度。';
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">HOME PATROL</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="mark-box">
      <text class="mark-mode">{{modeLine}}</text>
      <text class="count">{{progLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="guide-box">
      <text class="curname">{{curName}}</text>
      <text class="cue">{{cueLine}}</text>
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{guideCls}}">{{guideLine}}</text>
      </view>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="itemTap">ITEM</button>
      <button class="btn btn-main" bindtap="checkTap">CHECK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="regTap">REG</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="resetTap">RESET</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 8px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.mark-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.mark-mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.count {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.list {
  height: 45px;
  margin-bottom: 3px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.rtext {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.guide-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 2px 10px 4px;
  margin-bottom: 4px;
}
.curname {
  color: #40ff5e;
  font-size: 15px;
  font-weight: 500;
  line-height: 19px;
}
.cue {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.guide-top {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-top: 1px;
}
.arrow {
  color: #40ff5e;
  font-size: 24px;
  line-height: 27px;
  margin-right: 10px;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 3px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 4px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
