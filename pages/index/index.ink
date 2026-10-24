<script def>
{
  "navigationBarTitleText": "Sky Watch"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '天空守望 — 晒着衣服/被子出门，天什么时候阴的完全没察觉，回来全淋透：出门前看向晾晒区登记，定时提醒回看天空，云层变化大时 TTS 预警',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 天空守望 — REG 登记晾晒区，START 开始守望，METER 测一次，SKY 回看确认，END 出小结',
    bigLabel: '天空守望 · 待机',
    bigText: '还没登记',
    bigNote: '出门前看向晾晒区登记 · 定时提醒回看天空 · 云层变化大时 TTS 预警',
    permLine: 'PERM: CAMERA — 定时测光拍照；不录音、不定位',
    rows: [],
    countLine: '测光 0 次 · 提醒 0 次 · 预警 0 次 · 回看 0 次 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - REG registers the drying area, START begins watching, METER takes a reading, SKY confirms a look-back, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | summary
    this._registered = false; // drying area registered (looked + steady)
    this._checks = 0; // meter readings this session
    this._level = null; // null | bright | dim | dark, latest reading
    this._reminds = 0; // timed sky-check reminders raised
    this._alerts = 0; // cloud-change TTS warnings raised
    this._looks = 0; // SKY look-back confirmations
    this._remindOpen = false; // a timed reminder banner is open
    this._alertOpen = false; // a cloud warning is open
    this._mark = '已看'; // current mark choice: 已看 | 要收 | 不收
    this._lastMark = null; // mark of the last SKY confirmation
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 registered+bright, 2 reminder, 3 cloud alert, 4 sky confirmed, 5 summary
    this._nodLock = false;
    this._meterTimer = null;
    this._remindTimer = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: registration, readings,
    // reminders, warnings and look-backs die with the page,
    // and both timers stop. Nothing was ever written anywhere
    // persistent.
    this._stopTimers();
    this._mode = 'idle';
    this._registered = false;
    this._checks = 0;
    this._level = null;
    this._reminds = 0;
    this._alerts = 0;
    this._looks = 0;
    this._remindOpen = false;
    this._alertOpen = false;
    this._mark = '已看';
    this._lastMark = null;
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
    // not take effect. A cloud warning speaks exactly once;
    // SPEAK re-reads only on an explicit tap.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  _startTimers() {
    // Timed metering every 10 minutes and a timed sky-check
    // reminder every 30 minutes while watching. Both are
    // stopped by DEMO (staged frames must not drift), by END
    // and by unload. DEMO is a staged sample, not a live watch.
    this._stopTimers();
    var self = this;
    try {
      this._meterTimer = setInterval(function () { self._autoMeter(); }, 600000);
    } catch (e) { this._meterTimer = null; }
    try {
      this._remindTimer = setInterval(function () { self._reminderTick(); }, 1800000);
    } catch (e) { this._remindTimer = null; }
  },

  _stopTimers() {
    if (this._meterTimer) {
      try { clearInterval(this._meterTimer); } catch (e) {}
      this._meterTimer = null;
    }
    if (this._remindTimer) {
      try { clearInterval(this._remindTimer); } catch (e) {}
      this._remindTimer = null;
    }
  },

  _autoMeter() {
    if (this._mode !== 'watching' || this._demo) return;
    this.meterTap();
  },

  _reminderTick() {
    if (this._mode !== 'watching' || this._demo) return;
    if (this._remindOpen || this._alertOpen) return; // one open banner at a time, no double count
    this._remindOpen = true;
    this._reminds++;
    this.setData({
      status: '提醒回看天空 — 定时提醒，抬头看看天，SKY 标记回看',
      lastEvent: 'EVT: timed reminder - look back at the sky, reminds ' + this._reminds + ' (no TTS)'
    });
    this._renderAll();
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
    // the drying area in idle (or starts watching once
    // registered) and confirms the summary. A nod never
    // meters and never confirms a look-back: a reading comes
    // from the camera, and a look-back comes from SKY — a nod
    // must not invent either.
    if (this._mode === 'idle') {
      if (!this._registered) { this.regTap(); return; }
      this.startTap(); return;
    }
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a meter reading and not a sky look-back' });
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
      if (this._mode === 'idle') {
        if (!this._registered) this.regTap();
        else this.startTap();
      }
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

  // ---------- register / start / meter / sky / mark / end ----------

  regTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: REG refused - registration happens before watching starts' });
      return;
    }
    if (this._registered) {
      this.setData({ lastEvent: 'EVT: REG refused - drying area already registered, START begins watching' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: REG refused - look at the drying area and hold steady first' });
      return;
    }
    this._registered = true;
    this.setData({
      status: '晾晒区已登记 — 出门前看向晾晒区停稳已记下，START 开始守望',
      lastEvent: 'EVT: drying area registered - look steady, START begins watching'
    });
    this._renderAll();
  },

  startTap() {
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: START refused - already watching, METER takes a reading' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    if (!this._registered) {
      this.setData({ lastEvent: 'EVT: START refused - missing: 先 REG 登记晾晒区' });
      return;
    }
    this._mode = 'watching';
    this._startTimers();
    this.setData({
      status: '守望中 — 定时提醒回看天空，相机定时测光，云层变化大时 TTS 预警',
      lastEvent: 'EVT: watching started - registered, checks ' + this._checks
    });
    this._renderAll();
  },

  async meterTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: METER ignored - START begins watching first' });
      return;
    }
    // Real meter path: one camera photo, graded by average
    // brightness. This is an estimate, not a weather reading:
    // the platform has no weather forecast and no rain sensor.
    // The photo is used for this reading only and discarded
    // immediately.
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

  _gradeSteps(level) {
    if (level === 'bright') return 2;
    if (level === 'dim') return 1;
    return 0;
  },

  _applyReading(level) {
    // The single seam for a reading: real meter path, DEMO
    // stages and the harness all land here, so the warning
    // rule is tested once, not per path. A cloud warning fires
    // only on a BIG drop: two grade steps down from the last
    // reading (bright -> dark). A one-step slide (bright ->
    // dim, dim -> dark) is shown but warns nothing.
    var prev = this._level;
    this._checks++;
    this._level = level;
    if (level === 'dark' && prev !== null && !this._alertOpen &&
        this._gradeSteps(prev) - this._gradeSteps(level) >= 2) {
      this._alertOpen = true;
      this._alerts++;
      this._speakText('天空变暗了，可能是云层变厚，回去看看晾晒');
      this.setData({
        status: '云层预警 — 亮度显著下降，可能是云层变厚，SKY 标记回看',
        lastEvent: 'EVT: big drop to dark - cloud warning open, alerts ' + this._alerts + ' (one TTS)'
      });
    } else if (level === 'bright' && this._alertOpen) {
      // A later bright reading lifts the warning by itself:
      // the sky is bright again, so the warning has no reason
      // to stay. It counts no look-back: only SKY does.
      this._alertOpen = false;
      this.setData({
        status: '天空回明 — 预警解除，继续守望',
        lastEvent: 'EVT: bright reading - warning lifted, no look-back counted'
      });
    } else if (level === 'dim') {
      this.setData({
        status: '偏暗 — 还没到预警线，继续守望',
        lastEvent: 'EVT: dim reading - below bright, above the warning line, no warning'
      });
    } else if (level === 'dark') {
      this.setData({
        status: '光线暗 — 小幅变暗，未达预警线，继续守望',
        lastEvent: 'EVT: dark reading - small drop, below the big-change line, no warning'
      });
    } else {
      this.setData({
        status: '天空明 — 继续守望',
        lastEvent: 'EVT: bright reading - checks ' + this._checks
      });
    }
    this._renderAll();
  },

  skyTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: SKY ignored - START begins watching first' });
      return;
    }
    if (!this._remindOpen && !this._alertOpen) {
      this.setData({ lastEvent: 'EVT: SKY ignored - no reminder or warning open to confirm' });
      return;
    }
    // One look-back covers both open banners: you looked at
    // the sky once, and the mark you chose (MARK cycles it)
    // is what the look-back records.
    this._remindOpen = false;
    this._alertOpen = false;
    this._looks++;
    this._lastMark = this._mark;
    this.setData({
      status: '回看已标记 — ' + this._mark + '，回看 ' + this._looks + ' 次，继续守望',
      lastEvent: 'EVT: look-back confirmed - mark ' + this._mark + ', looks ' + this._looks
    });
    this._renderAll();
  },

  markTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: MARK ignored - START begins watching first' });
      return;
    }
    // The mark is your decision after a look-back, never the
    // agent's: it cycles 已看 -> 要收 -> 不收 -> 已看, and SKY
    // records whichever one is showing. The agent never
    // decides whether the laundry comes in.
    if (this._mark === '已看') this._mark = '要收';
    else if (this._mark === '要收') this._mark = '不收';
    else this._mark = '已看';
    this.setData({
      lastEvent: 'EVT: mark -> ' + this._mark + ' (SKY records it)'
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
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 REG 登记晾晒区，再 START 开始守望' });
      return;
    }
    this._stopTimers();
    this._mode = 'summary';
    this._summary = {
      checks: this._checks,
      reminds: this._reminds,
      alerts: this._alerts,
      looks: this._looks,
      lastMark: this._lastMark
    };
    this.setData({
      status: '结束 — 测光 ' + this._checks + ' 次，提醒 ' + this._reminds + ' 次，预警 ' + this._alerts + ' 次，回看 ' + this._looks + ' 次，点 END 确认清空，BACK 回守望',
      lastEvent: 'EVT: closed - checks ' + this._checks + ' reminds ' + this._reminds + ' alerts ' + this._alerts + ' looks ' + this._looks
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._stopTimers();
    this._mode = 'idle';
    this._registered = false;
    this._checks = 0;
    this._level = null;
    this._reminds = 0;
    this._alerts = 0;
    this._looks = 0;
    this._remindOpen = false;
    this._alertOpen = false;
    this._mark = '已看';
    this._lastMark = null;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '天空守望 — 下次出门前再 REG 登记晾晒区',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      // Timers stay stopped in summary; START resumes them
      // only after BACK to idle, same as the fleet pattern.
      this._mode = 'watching';
      this._summary = null;
      this.setData({
        status: '守望中 — BACK 回到守望，小结保留待重建',
        lastEvent: 'EVT: back to watching - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'watching') {
      // Back to idle keeps the session and the registration;
      // START resumes the same round instead of resetting it.
      this._stopTimers();
      this._mode = 'idle';
      this.setData({
        status: '天空守望 — 守望已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - REG registers the drying area first' });
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
      line = this._registered ? '已登记晾晒区：START 开始守望' : '还没登记：REG 登记晾晒区';
    } else if (this._mode === 'watching') {
      if (this._alertOpen) line = '天空变暗了，可能是云层变厚，回去看看晾晒';
      else if (this._remindOpen) line = '提醒回看天空，抬头看看天';
      else if (this._level === 'bright') line = '天空明，测光 ' + this._checks + ' 次';
      else if (this._level === 'dim') line = '天空偏暗，测光 ' + this._checks + ' 次';
      else if (this._level === 'dark') line = '天空暗，测光 ' + this._checks + ' 次';
      else line = '守望中，还没测光';
    } else if (this._summary) {
      line = '本次小结：测光 ' + this._summary.checks + ' 次，提醒 ' + this._summary.reminds + ' 次，预警 ' + this._summary.alerts + ' 次，回看 ' + this._summary.looks + ' 次';
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
    if (this._mode === 'idle' && !this._demo && (this._checks > 0 || this._reminds > 0 || this._alerts > 0 || this._looks > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      // DEMO is a staged sample, not a live watch: both
      // timers are stopped so real ticks cannot drift the
      // staged frames, and the readings are staged grades.
      this._stopTimers();
      this._registered = true;
      this._mode = 'watching';
      this._applyReading('bright');
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - drying area registered, watching, reading bright, checks 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._remindOpen = true;
      this._reminds++;
      this.setData({
        status: '提醒回看天空 — 定时提醒，抬头看看天，SKY 标记回看',
        lastEvent: 'EVT: DEMO stage 2 - timed reminder, reminds 1, no TTS (DEMO sample)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._applyReading('dark');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - big drop bright->dark, cloud warning open, alerts 1, one TTS (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.skyTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - look-back confirmed, mark 已看, looks 1, banners cleared (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: checks 2 reminds 1 alerts 1 looks 1 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _levelText() {
    if (this._level === 'bright') return '天空明';
    if (this._level === 'dim') return '偏暗';
    if (this._level === 'dark') return '天空暗';
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
      name: '天空提醒',
      detail: this._alertOpen ? '云层预警开着 · 预警 ' + this._alerts + ' 次' : (this._remindOpen ? '提醒回看开着 · 提醒 ' + this._reminds + ' 次' : '没有提醒 · 提醒 ' + this._reminds + ' 次 · 预警 ' + this._alerts + ' 次'),
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '回看标记',
      detail: (this._lastMark ? '上次：' + this._lastMark + ' · ' : '还没回看 · ') + '回看 ' + this._looks + ' 次（当前选：' + this._mark + '）',
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '测光 ' + this._checks + ' 次 · 提醒 ' + this._reminds + ' 次 · 预警 ' + this._alerts + ' 次 · 回看 ' + this._looks + ' 次 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 天空守望 — REG 登记晾晒区，START 开始守望，METER 测一次，SKY 回看确认，END 出小结';
      patch.bigLabel = '天空守望 · 待机';
      patch.bigText = this._registered ? '已登记未开始' : '还没登记';
      patch.bigNote = this._registered ? '晾晒区已登记 · START 开始守望' : '出门前看向晾晒区登记 · 定时提醒回看天空 · 云层变化大时 TTS 预警';
    } else if (this._mode === 'watching') {
      if (this._alertOpen) {
        patch.boxLabel = '◎ 云层预警 — 亮度显著下降，可能是云层变厚，SKY 标记回看';
        patch.bigLabel = '天空守望 · 预警';
        patch.bigText = '云层预警';
        patch.bigNote = '天空变暗了 · SKY 标记回看（MARK 选：' + this._mark + '）';
      } else if (this._remindOpen) {
        patch.boxLabel = '◎ 提醒回看天空 — 定时提醒，抬头看看天，SKY 标记回看';
        patch.bigLabel = '天空守望 · 提醒';
        patch.bigText = '提醒回看';
        patch.bigNote = '定时提醒 · SKY 标记回看（MARK 选：' + this._mark + '）';
      } else {
        patch.boxLabel = '◎ ' + this._levelText() + ' — 测光 ' + this._checks + ' 次';
        patch.bigLabel = '天空守望 · 守望中';
        patch.bigText = this._levelText();
        patch.bigNote = '相机定时测光 · 定时提醒回看天空 · 云层变化大时 TTS 预警';
      }
    } else {
      patch.boxLabel = '◎ 本次小结 — 测光几次、提醒几次、预警几次、回看几次钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { checks: 0, reminds: 0, alerts: 0, looks: 0 };
      patch.bigText = '测光 ' + sm.checks + ' 次';
      patch.bigNote = '提醒 ' + sm.reminds + ' 次 · 预警 ' + sm.alerts + ' 次 · 回看 ' + sm.looks + ' 次 · 点 END 确认清空 · BACK 回守望';
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
      <text class="title">SKY WATCH v1.0.0</text>
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
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn btn-main" bindtap="meterTap">METER</button>
      <button class="btn btn-main" bindtap="skyTap">SKY</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
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
    <text class="foot2">没有天气预报、没有雨滴传感器——亮度下降只是云层变厚的代理信号，不是下雨预报 · 照片只用于当次测光、会话内即弃，不存档、不上传 · 它不是气象工具，收不收衣服最终由你回看判断 · 阈值是固定档位，不是按天气状态调整的 · 只存本次会话，关掉即清 · 没有室内定位 · 零落盘</text>
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
