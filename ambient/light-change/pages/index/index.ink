<script def>
{
  "navigationBarTitleText": "Light Change"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '光线变化 — 看书/做手工太投入，天黑了还在昏光里用眼，伤眼不自知：相机测光变化 + 定时回看，光线低于阈值在视线内提醒开灯',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 光线变化 — START 开始测光，METER 测一次，LIGHT 确认开灯，END 出小结',
    bigLabel: '光线变化 · 待机',
    bigText: '还没开始',
    bigNote: '相机测光变化 + 定时回看 · 低于阈值提醒开灯',
    permLine: 'PERM: CAMERA — 定时测光拍照；不录音、不定位',
    rows: [],
    countLine: '测光 0 次 · 提醒 0 次 · 开灯确认 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START begins metering, METER takes a reading, LIGHT confirms the lamp, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | summary
    this._checks = 0; // meter readings this session
    this._level = null; // null | bright | dim | dark, latest reading
    this._reminds = 0; // dark-threshold reminders raised
    this._lights = 0; // light-on confirmations
    this._remindOpen = false; // a dark reminder is open, awaiting LIGHT or a bright reading
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 bright, 2 dim, 3 dark reminder, 4 light confirmed, 5 summary
    this._nodLock = false;
    this._timer = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: readings, reminders and
    // confirmations die with the page, and the meter timer
    // stops. Nothing was ever written anywhere persistent.
    this._stopTimer();
    this._mode = 'idle';
    this._checks = 0;
    this._level = null;
    this._reminds = 0;
    this._lights = 0;
    this._remindOpen = false;
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
    // not take effect. A dark reminder speaks exactly once;
    // SPEAK re-reads only on an explicit tap.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  _startTimer() {
    // Timed re-metering: every 10 minutes while watching, an
    // automatic reading is attempted. The timer is stopped by
    // DEMO (staged frames must not drift), by END and by
    // unload. DEMO is a staged sample, not a live watch.
    this._stopTimer();
    var self = this;
    try {
      this._timer = setInterval(function () { self._autoMeter(); }, 600000);
    } catch (e) { this._timer = null; }
  },

  _stopTimer() {
    if (this._timer) {
      try { clearInterval(this._timer); } catch (e) {}
      this._timer = null;
    }
  },

  _autoMeter() {
    if (this._mode !== 'watching' || this._demo) return;
    this.meterTap();
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
    // Nod discipline in THIS agent: a steady nod starts
    // metering in idle and confirms the summary. A nod never
    // meters and never confirms the lamp: a reading comes
    // from the camera, and a lamp confirm comes from LIGHT or
    // a later bright reading — a nod must not invent either.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a meter reading and not a lamp confirm' });
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
      else if (this._mode === 'watching') this.meterTap();
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

  // ---------- start / meter / light / end ----------

  startTap() {
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: START refused - already metering, METER takes a reading' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    this._mode = 'watching';
    this._startTimer();
    this.setData({
      status: '监测中 — 定时测光已开始，METER 测一次，低于阈值提醒开灯',
      lastEvent: 'EVT: metering started - watching, checks ' + this._checks
    });
    this._renderAll();
  },

  async meterTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: METER ignored - START begins metering first' });
      return;
    }
    // Real meter path: one camera photo, graded by average
    // brightness. This is an estimate, not a lux reading:
    // the platform has no ambient light sensor. The photo is
    // used for this reading only and discarded immediately.
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('camera n/a on this host');
      }
      var stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = stream.getVideoTracks()[0];
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await cap.takePhoto({ mode: 'wide' });
      try { track.stop(); } catch (e) {}
      var level = await this._gradePhoto(blob);
      this._applyReading(level);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: meter failed - ' + this._err(e) + ' - DEMO shows a staged sample' });
    }
  },

  async _gradePhoto(blob) {
    // Average-luminance grading of one photo: bright >= 150,
    // dim >= 80, dark below. Thresholds are fixed grades, not
    // calibrated lux values, and the README says so.
    var bmp = await createImageBitmap(blob);
    var canvas = document.createElement('canvas');
    canvas.width = bmp.width;
    canvas.height = bmp.height;
    var ctx = canvas.getContext('2d');
    ctx.drawImage(bmp, 0, 0);
    var data = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    var sum = 0;
    var n = 0;
    for (var i = 0; i < data.length; i += 16) {
      sum += 0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2];
      n++;
    }
    var avg = n ? sum / n : 0;
    if (avg >= 150) return 'bright';
    if (avg >= 80) return 'dim';
    return 'dark';
  },

  _applyReading(level) {
    // The single seam for a reading: real meter path, DEMO
    // stages and the harness all land here, so the reminder
    // and confirm rules are tested once, not per path.
    this._checks++;
    this._level = level;
    if (level === 'dark' && !this._remindOpen) {
      this._remindOpen = true;
      this._reminds++;
      this._speakText('光线暗了，开灯吧');
      this.setData({
        status: '提醒开灯 — 光线低于阈值（暗），开灯后点 LIGHT 确认',
        lastEvent: 'EVT: dark reading - reminder open, reminds ' + this._reminds + ' (one TTS)'
      });
    } else if (level === 'bright' && this._remindOpen) {
      // A later bright reading confirms the lamp by itself:
      // the room is bright again, so the reminder lifts.
      this._remindOpen = false;
      this._lights++;
      this.setData({
        status: '光线回明 — 提醒解除，开灯确认 ' + this._lights + ' 次',
        lastEvent: 'EVT: bright reading - reminder lifted, lights ' + this._lights
      });
    } else if (level === 'dim') {
      this.setData({
        status: '偏暗 — 还没到提醒阈值，继续监测',
        lastEvent: 'EVT: dim reading - below bright, above the dark threshold, no reminder'
      });
    } else {
      this.setData({
        status: '光线明 — 继续监测',
        lastEvent: 'EVT: bright reading - checks ' + this._checks
      });
    }
    this._renderAll();
  },

  lightTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: LIGHT ignored - START begins metering first' });
      return;
    }
    if (!this._remindOpen) {
      this.setData({ lastEvent: 'EVT: LIGHT ignored - no reminder open to confirm' });
      return;
    }
    this._remindOpen = false;
    this._lights++;
    this.setData({
      status: '开灯已确认 — 提醒解除，继续监测',
      lastEvent: 'EVT: lamp confirmed - lights ' + this._lights + ', reminder closed'
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
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始测光' });
      return;
    }
    this._stopTimer();
    this._mode = 'summary';
    this._summary = {
      checks: this._checks,
      reminds: this._reminds,
      lights: this._lights
    };
    this.setData({
      status: '结束 — 测光 ' + this._checks + ' 次，提醒 ' + this._reminds + ' 次，开灯确认 ' + this._lights + ' 次，点 END 确认清空，BACK 回监测',
      lastEvent: 'EVT: closed - checks ' + this._checks + ' reminds ' + this._reminds + ' lights ' + this._lights
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._stopTimer();
    this._mode = 'idle';
    this._checks = 0;
    this._level = null;
    this._reminds = 0;
    this._lights = 0;
    this._remindOpen = false;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '光线变化 — START 再次开始测光',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      // The timer stays stopped in summary; START resumes it.
      this._mode = 'watching';
      this._summary = null;
      this.setData({
        status: '监测中 — BACK 回到监测，小结保留待重建',
        lastEvent: 'EVT: back to watching - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'watching') {
      // Back to idle keeps the session; START resumes the
      // same session instead of resetting it.
      this._stopTimer();
      this._mode = 'idle';
      this.setData({
        status: '光线变化 — 监测已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins metering' });
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
      if (isNaN(idx)) return; // missing dataset: keep focus, never jump to 0
    } catch (e) { return; }
    if (idx < 0 || idx >= 3) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没开始：START 开始测光';
    } else if (this._mode === 'watching') {
      if (this._remindOpen) line = '光线暗了，开灯吧';
      else if (this._level === 'bright') line = '光线明，测光 ' + this._checks + ' 次';
      else if (this._level === 'dim') line = '光线偏暗，测光 ' + this._checks + ' 次';
      else if (this._level === 'dark') line = '光线暗，测光 ' + this._checks + ' 次';
      else line = '监测中，还没测光';
    } else if (this._summary) {
      line = '本次小结：测光 ' + this._summary.checks + ' 次，提醒 ' + this._summary.reminds + ' 次，开灯确认 ' + this._summary.lights + ' 次';
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
    if (this._mode === 'idle' && !this._demo && (this._checks > 0 || this._reminds > 0 || this._lights > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      // DEMO is a staged sample, not a live watch: the timer
      // is stopped so real ticks cannot drift the staged
      // frames, and the readings are staged grades.
      this._stopTimer();
      this._mode = 'watching';
      this._applyReading('bright');
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - watching, reading bright, checks 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._applyReading('dim');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - reading dim, checks 2, no reminder (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._applyReading('dark');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - reading dark, reminder open, reminds 1, one TTS (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.lightTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - lamp confirmed, lights 1, reminder closed (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: checks 3 reminds 1 lights 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _levelText() {
    if (this._level === 'bright') return '光线明';
    if (this._level === 'dim') return '偏暗';
    if (this._level === 'dark') return '光线暗';
    return '还没测光';
  },

  _renderAll() {
    var rows = [];
    rows.push({
      idx: 0,
      name: '最近测光',
      detail: this._levelText() + ' · 测光 ' + this._checks + ' 次',
      flag: (this._focus === 0 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 1,
      name: '提醒开灯',
      detail: this._remindOpen ? '提醒开着 · 提醒 ' + this._reminds + ' 次' : '没有提醒 · 提醒 ' + this._reminds + ' 次',
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '开灯确认',
      detail: this._lights + ' 次（LIGHT 或回明自动确认）',
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '测光 ' + this._checks + ' 次 · 提醒 ' + this._reminds + ' 次 · 开灯确认 ' + this._lights + ' 次 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 光线变化 — START 开始测光，METER 测一次，LIGHT 确认开灯，END 出小结';
      patch.bigLabel = '光线变化 · 待机';
      patch.bigText = (this._checks > 0 || this._reminds > 0 || this._lights > 0) ? '监测已停未清' : '还没开始';
      patch.bigNote = '相机测光变化 + 定时回看 · 低于阈值提醒开灯';
    } else if (this._mode === 'watching') {
      patch.boxLabel = this._remindOpen
        ? '◎ 提醒开灯 — 光线暗了，开灯后点 LIGHT 确认'
        : '◎ ' + this._levelText() + ' — 测光 ' + this._checks + ' 次';
      patch.bigLabel = '光线变化 · 监测中';
      patch.bigText = this._remindOpen ? '提醒开灯' : this._levelText();
      patch.bigNote = this._remindOpen ? '光线低于阈值 · 开灯后点 LIGHT 或等回明' : '相机测光变化 + 定时回看 · 低于阈值提醒开灯';
    } else {
      patch.boxLabel = '◎ 本次小结 — 测光几次、提醒几次、开灯几次钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { checks: 0, reminds: 0, lights: 0 };
      patch.bigText = '测光 ' + sm.checks + ' 次';
      patch.bigNote = '提醒 ' + sm.reminds + ' 次 · 开灯确认 ' + sm.lights + ' 次 · 点 END 确认清空 · BACK 回监测';
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
      <text class="title">LIGHT CHANGE v1.0.0</text>
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
      <button class="btn btn-main" bindtap="meterTap">METER</button>
      <button class="btn btn-main" bindtap="lightTap">LIGHT</button>
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
    <text class="foot2">没有环境光传感器——「测光」不是勒克斯读数，照片亮度只是近似估计，不是精确光照度 · 照片只用于当次测光、会话内即弃，不存档、不上传 · 它不是医疗建议、不诊断视力问题、不承诺护眼效果 · 阈值是固定档位，不是按你眼睛状态调整的 · 只存本次会话，关掉即清 · 没有室内定位 · 零落盘</text>
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
