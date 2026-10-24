<script def>
{
  "title": "Neck Clock"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Neck Clock （时钟点位） — head-movement mini-game G05, the flagship
// anti-circling teaching game. EXTREME simplicity: one page, three
// states only (ready / playing / done). The screen shows at most a
// big clock position, a count x/8 and one short hint while playing;
// voice (TTS) guides every step and counts. No menus, no settings,
// no levels, no camera, no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> hold -> return to center -> next
// direction. Never continuous circling, never sweep from one extreme
// to another, never fast jerking. Slow, small range, stop at mild
// stretch, never pain. For UP (12 o'clock) specifically: only to a
// MILD stretch, NEVER force the head far back, NEVER hyperextend,
// NEVER throw the head back. Stop at once on pain / dizziness /
// numbness / nausea. Sit or stand steady first. One round is
// 60-180 s. This is entertainment / daily activity, NOT medical
// diagnosis, treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should ask
// a doctor first.
//
// WHAT THIS GAME TEACHES: its opening voice line and ready screen
// say, verbatim: 「这是点位，不是转圈：每次只到一个点位，停住，
// 回正，再报下一个」. Each cue is ONE clock position, reached,
// held ~0.8 s, and returned from — never a sweep around the dial.
// The fixed 8-cue sequence is DELIBERATELY NON-CIRCULAR (no
// 12-3-6-9 clockwise run): 12, 9, 6, 3, 9, 12, 3, 6.
//
// HOW A CUE IS COUNTED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then TWO
// calibration prompts inside the playing state (not extra states):
// (1) "请低一下头" learns DOWN (UP = opposite pitch sign, G01/G04
// pattern); (2) "请向左转一下" learns LEFT (RIGHT = opposite yaw
// sign, G02 pattern). Nothing counts before BOTH calibrations
// complete; restart re-runs both. Each cue: move past threshold ->
// hold ~0.8 s -> return to center = 1 point, and only then is the
// next cue announced. A wrong position, an early release, or
// sweeping to the next position without returning counts nothing,
// with the correction hint "请先回正，不要直接转到下一个点".
// If a cue stalls, TTS re-prompts ONCE and never auto-counts.
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a labeled
// DEMO stepper so the playing/done states can be previewed. On a
// real device with a sensor, there is no DEMO path at all.
// -------------------------------------------------------------------

// Fixed cue sequence — deliberately NON-circular: never a clockwise
// 12-3-6-9 run, and every jump between cues passes through center.
const SEQ = [
  { n: 12, dir: 'up' },
  { n: 9, dir: 'left' },
  { n: 6, dir: 'down' },
  { n: 3, dir: 'right' },
  { n: 9, dir: 'left' },
  { n: 12, dir: 'up' },
  { n: 3, dir: 'right' },
  { n: 6, dir: 'down' }
];
const TOTAL = 8;
const DIR_DEG = 27;       // direction reached: 25-30 deg (pitch or yaw)
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const HOLD_MS = 800;      // hold-steady ~0.8 s
const STALL_MS = 8000;    // cue stall -> one TTS re-prompt, never auto-count
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 8',
    hint: '单击开始 · 8 个点位，不转圈',
    safety: '这是点位，不是转圈：每次只到一个点位，停住，回正，再报下一个。顺序 12、9、6、3、9、12、3、6，不按顺时针转圈。慢、小幅度、到微酸即止。12 点只到轻微拉伸，绝不用力往后仰、绝不向后甩头。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | wait | atTarget | held
    this._rep = 'wait';
    this._count = 0;
    this._sensor = null;
    this._pitch = null;    // latest pitch deg (formula below)
    this._yaw = null;      // latest yaw deg (formula below)
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._downSign = null; // +1 / -1: which raw pitch sign means DOWN (learned)
    this._leftSign = null; // +1 / -1: which raw yaw sign means LEFT (learned)
    this._holdAccum = 0;
    this._stallSince = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._timer = null;
    this._wrongDir = false;
    this._swept = false;
    this._lastRendered = '';
    this._startSensor();
    this._render();
  },

  onShow() { this._startTimer(); },
  onHide() { this._stopTimer(); },
  onUnload() { this._stopTimer(); this._stopSensor(); },

  // ---- TTS: fixed host voice; utterance lang is never set ----------
  // (documented: the TTS lang attribute does not take effect).
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  // ---- orientation sensor -------------------------------------------
  // Pitch from the orientation quaternion, same formula as G01/G04
  // (fleet-consistent): pitch = asin(2*(w*x - y*z)), clamped.
  // Yaw from the same quaternion, same formula as G02:
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Only the RELATIVE pitch/yaw vs the calibrated center are ever
  // used, so the host's absolute zero never matters.
  //
  // SIGN LEARNING — learned, not assumed (two prompts, both inside
  // the playing state): at round start the game asks "请低一下头"
  // and records the sign the head actually moves as DOWN; UP is the
  // opposite pitch sign. It then asks "请向左转一下" and records
  // the sign the head actually moves as LEFT; RIGHT is the opposite
  // yaw sign. A host whose pitch or yaw sign is inverted therefore
  // still counts down as down, up as up, left as left, right as
  // right. Residual caveats, documented in AGENTS.md and on the
  // device-test checklist: calibration trusts the player to follow
  // each prompt — looking up instead of down, or turning right
  // instead of left, would learn that axis backwards. The fail-safes
  // are that nothing counts before BOTH calibrations complete, the
  // first cue is 12 (up) and the second is 9 (left), so a backwards
  // calibration feels wrong at once, and any restart re-runs both
  // prompts. No fallback sign is ever guessed.
  _startSensor() {
    if (this._sensor || this._sensorSkip) return;
    const Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      this._sensorSkip = true;
      this._render();
      return;
    }
    const self = this;
    try {
      const s = new Ctor({ frequency: 10 });
      s.addEventListener('reading', function () {
        const q = s.quaternion;
        if (!q || q.length < 4) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        let v = 2 * (w * x - y * z);
        if (v > 1) v = 1;
        if (v < -1) v = -1;
        self._pitch = Math.asin(v) * 180 / Math.PI;
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)) * 180 / Math.PI;
        self._hasReading = true;
      });
      s.addEventListener('error', function () {
        self._sensorSkip = true;
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self._render();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._sensorSkip = true;
      this._render();
    }
  },
  _stopSensor() {
    if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; }
  },

  // Relative pitch / yaw vs calibrated center, wrapped to [-180, 180].
  _wrap(d) {
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },
  _relPitch() {
    if (!this._hasReading || this._pitch === null) return null;
    return this._wrap(this._pitch - this._pitchCenter);
  },
  _relYaw() {
    if (!this._hasReading || this._yaw === null) return null;
    return this._wrap(this._yaw - this._yawCenter);
  },
  // Signed pitch in "down-positive" space, signed yaw in
  // "left-positive" space, once calibration has learned the signs.
  _downPitch() {
    const rel = this._relPitch();
    if (rel === null || this._downSign === null) return null;
    return rel * this._downSign;
  },
  _leftYaw() {
    const rel = this._relYaw();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },
  // Head back inside the center band on BOTH axes.
  _atCenter(relPitch, relYaw) {
    return Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG;
  },
  // Re-center on the head's current position (after a calibration
  // return), so later cues are judged from where "straight" is now.
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _cue() { return SEQ[this._count]; },
  _dirWord(dir) {
    if (dir === 'up') return '上';
    if (dir === 'down') return '下';
    if (dir === 'left') return '左';
    return '右';
  },
  // True when the head is past threshold in the given direction.
  _past(dir, downPitch, leftYaw) {
    if (dir === 'up') return downPitch <= -DIR_DEG;
    if (dir === 'down') return downPitch >= DIR_DEG;
    if (dir === 'left') return leftYaw >= DIR_DEG;
    return leftYaw <= -DIR_DEG;
  },
  // Magnitude along the given direction's axis (for early-release).
  _mag(dir, downPitch, leftYaw) {
    if (dir === 'up' || dir === 'down') return Math.abs(downPitch);
    return Math.abs(leftYaw);
  },
  // True when the head is past threshold in ANY direction except dir.
  _otherPast(dir, downPitch, leftYaw) {
    const dirs = ['up', 'down', 'left', 'right'];
    for (let i = 0; i < dirs.length; i++) {
      if (dirs[i] !== dir && this._past(dirs[i], downPitch, leftYaw)) return true;
    }
    return false;
  },

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    const s = event.stable !== undefined ? event.stable
      : (detail.stable !== undefined ? detail.stable : detail.isStable);
    if (s !== undefined) {
      this._stable = s === true;
      this._stableSeen = true;
    }
  },

  // NOTE: no head-gesture handler, deliberately. The gesture API is officially
  // documented ONLY for 'nod', and nod is not this game's action —
  // clock positions come from the sensor, never from a gesture event.

  // ---- temple keys: tap = main button; double-tap (Backspace) is ---
  // never intercepted — the host handles back.
  onKeyDown(event) {
    const k = event.key || event.code || '';
    if (k === 'Enter' || k === 'GlobalHook') {
      if (event.preventDefault) event.preventDefault();
      this.mainTap();
    }
  },
  onKeyUp(event) {
    const k = event.key || event.code || '';
    if (k === 'Enter' || k === 'GlobalHook') {
      if (event.preventDefault) event.preventDefault();
    }
  },

  // ---- round flow ----------------------------------------------------
  _beginRound() {
    // Recalibrate: head straight NOW is the center for this round;
    // both signs are then learned by the two calibration prompts.
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerSet = true;
    this._count = 0;
    this._downSign = null;
    this._leftSign = null;
    this._rep = 'calibDownTurn';
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._wrongDir = false;
    this._swept = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('这是点位，不是转圈：每次只到一个点位，停住，回正，再报下一个。头摆正，开始。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _announceCue() {
    const cue = this._cue();
    let text = '下一个点位：' + cue.n + ' 点钟方向，' + this._dirWord(cue.dir);
    if (cue.dir === 'up') text += '，只到轻微拉伸，不要用力往后仰';
    this._speak(text);
    this.setData({ foot: 'EVT: cue announced ' + cue.n + ' ' + cue.dir + ' (' + (this._count + 1) + '/' + TOTAL + ')' });
  },

  _countCue() {
    this._count++;
    this._rep = 'wait';
    this._reprompted = false;
    this._wrongDir = false;
    this._swept = false;
    this._stallSince = Date.now();
    if (this._count >= TOTAL) {
      this._phase = 'done';
      this._stopTimer();
      this._speak('完成，8 个点位都到过了，没有转圈。');
      this.setData({ foot: 'EVT: DONE ' + this._count + '/' + TOTAL });
    } else {
      this._announceCue();
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real point. One
  // tap per calibration step, then one tap per whole cue (reach +
  // hold + return collapsed) so the playing/done states can be
  // previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._rep === 'calibDownTurn') {
      this._downSign = 1; // demo assumption, labeled as demo only
      this._rep = 'calibDownReturn';
      this.setData({ foot: 'EVT: DEMO down-calibration tilt (sensor SKIP)' });
    } else if (this._rep === 'calibDownReturn') {
      this._rep = 'calibLeftTurn';
      this.setData({ foot: 'EVT: DEMO down-calibration return (sensor SKIP)' });
    } else if (this._rep === 'calibLeftTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._rep = 'calibLeftReturn';
      this.setData({ foot: 'EVT: DEMO left-calibration tilt (sensor SKIP)' });
    } else if (this._rep === 'calibLeftReturn') {
      this._rep = 'wait';
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._count++;
      this._rep = 'wait';
      if (this._count >= TOTAL) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done ' + this._count + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this.setData({ foot: 'EVT: DEMO cue ' + this._count + '/' + TOTAL + ' (sensor SKIP)' });
      }
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoStep(); return; }
    this._speak(this._currentInstruction());
  },

  _currentInstruction() {
    if (this._rep === 'calibDownTurn') return '请低一下头，慢慢低头，到微酸就停';
    if (this._rep === 'calibDownReturn') return '回正到中间';
    if (this._rep === 'calibLeftTurn') return '请向左转一下，慢慢向左转';
    if (this._rep === 'calibLeftReturn') return '回正到中间';
    if (this._rep === 'atTarget') return '稳住';
    if (this._rep === 'held') return '回正到中间';
    const cue = this._cue();
    return '下一个点位：' + cue.n + ' 点钟方向，' + this._dirWord(cue.dir);
  },

  // ---- tick: the cue state machine -----------------------------------
  _startTimer() {
    if (this._timer) return;
    const self = this;
    this._timer = setInterval(function () { self._tick(); }, TICK_MS);
  },
  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _tick() {
    if (this._phase !== 'playing') return;
    const relPitch = this._relPitch();
    const relYaw = this._relYaw();
    if (relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives cues
    const now = Date.now();

    // --- calibration 1: learn which pitch sign means down -----------
    if (this._rep === 'calibDownTurn') {
      if (Math.abs(relPitch) >= DIR_DEG) {
        this._downSign = relPitch > 0 ? 1 : -1;
        this._rep = 'calibDownReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: down sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请低一下头，慢慢低头，到微酸就停');
        this.setData({ foot: 'EVT: down calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._rep === 'calibDownReturn') {
      if (this._atCenter(relPitch, relYaw)) {
        this._recenter();
        this._rep = 'calibLeftTurn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('再校准一下左右：请向左转一下，慢慢向左转');
        this.setData({ foot: 'EVT: down calibration complete, awaiting left-calibration turn' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: down calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- calibration 2: learn which yaw sign means left -------------
    if (this._rep === 'calibLeftTurn') {
      if (Math.abs(relYaw) >= DIR_DEG) {
        this._leftSign = relYaw > 0 ? 1 : -1;
        this._rep = 'calibLeftReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: left sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请向左转一下，慢慢向左转');
        this.setData({ foot: 'EVT: left calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._rep === 'calibLeftReturn') {
      if (this._atCenter(relPitch, relYaw)) {
        this._recenter();
        this._rep = 'wait';
        this._reprompted = false;
        this._stallSince = now;
        this._announceCue();
        this.setData({ foot: 'EVT: calibration complete, first cue announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: left calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- cues: downPitch positive-down, leftYaw positive-left --------
    const dp = this._downPitch();
    const ly = this._leftYaw();
    if (dp === null || ly === null) return;
    const cue = this._cue();
    const dir = cue.dir;
    this._wrongDir = false;
    this._swept = false;
    if (this._rep === 'wait') {
      if (this._past(dir, dp, ly)) {
        this._rep = 'atTarget';
        this._holdAccum = 0;
        this._stallSince = now;
        this._reprompted = false;
        this._speak(dir === 'up' ? '稳住，只到轻微拉伸，不要用力往后仰' : '稳住');
        this.setData({ foot: 'EVT: reached ' + cue.n + ' ' + dir + ' past ' + DIR_DEG + ' deg, hold started' });
      } else if (this._otherPast(dir, dp, ly)) {
        this._wrongDir = true;
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._announceCue();
        this.setData({ foot: 'EVT: cue stalled, re-prompted once (no auto-count)' });
      }
    } else if (this._rep === 'atTarget') {
      if (!this._past(dir, dp, ly) && this._mag(dir, dp, ly) < DIR_DEG - 5) {
        // Released before the ~0.8 s hold: aborted, no count.
        this._rep = 'wait';
        this._stallSince = now;
        this._speak('没稳住，重新来，慢一点');
        this.setData({ foot: 'EVT: position released before full hold, no count' });
      } else if (this._past(dir, dp, ly)) {
        // Hold accumulates only while steady where the host reports
        // stability; if the host never reports stability, elapsed
        // time alone gates the hold (documented fallback).
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) this._holdAccum += TICK_MS;
        if (this._holdAccum >= HOLD_MS) {
          this._rep = 'held';
          this._stallSince = now;
          this._speak('回正到中间');
          this.setData({ foot: 'EVT: held ' + HOLD_MS + ' ms' });
        }
      }
    } else if (this._rep === 'held') {
      if (this._atCenter(relPitch, relYaw)) {
        this._countCue();
        return;
      }
      if (this._past(dir, dp, ly)) {
        // Still at the position: keep waiting for center.
        this._stallSince = now;
      } else if (this._otherPast(dir, dp, ly)) {
        // Swept straight to another position without returning:
        // counts nothing, and the hint says so.
        this._swept = true;
        this._stallSince = now;
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: return stalled, re-prompted once (no auto-count)' });
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      hint = '单击开始 · 8 个点位，不转圈';
      safety = '这是点位，不是转圈：每次只到一个点位，停住，回正，再报下一个。顺序 12、9、6、3、9、12、3、6，不按顺时针转圈。慢、小幅度、到微酸即止。12 点只到轻微拉伸，绝不用力往后仰、绝不向后甩头。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 8 / 8' : '完成 8 / 8';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      const demo = (this._sensorSkip || !this._hasReading);
      if (this._rep === 'calibDownTurn') {
        big = '请低一下头';
        hint = '只校准第一步：慢慢低头，到微酸就停';
        mainBtn = demo ? '演示低一下头' : '朗读';
      } else if (this._rep === 'calibDownReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._rep === 'calibLeftTurn') {
        big = '请向左转一下';
        hint = '只校准第二步：慢慢向左转';
        mainBtn = demo ? '演示向左转' : '朗读';
      } else if (this._rep === 'calibLeftReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._rep === 'atTarget') {
        const cue = this._cue();
        big = cue.n + ' · ' + this._dirWord(cue.dir);
        hint = '稳住… 0.8 秒';
        mainBtn = demo ? '演示到点位' : '朗读';
      } else if (this._rep === 'held') {
        big = '回正到中间';
        hint = this._swept ? '请先回正，不要直接转到下一个点' : '慢慢贴回正前方';
        mainBtn = demo ? '演示到点位' : '朗读';
      } else {
        const cue = this._cue();
        big = cue.n + ' · ' + this._dirWord(cue.dir);
        hint = this._wrongDir
          ? ('反了？请先回正，再到 ' + cue.n + ' 点钟方向')
          : (cue.n + ' 点钟方向，' + this._dirWord(cue.dir) + ' · 稳住 0.8 秒 → 回正 = 1 个点位');
        mainBtn = demo ? '演示到点位' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [big, this._count + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: this._count + ' / ' + TOTAL,
      hint: hint,
      safety: safety,
      sensorLine: sensorLine,
      mainBtn: mainBtn
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">时钟点位 NECK CLOCK</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">点位不是转圈 · 不直接转到下一个点 · 不用力往后仰 · 痛晕立刻停</div>
  </div>
</template>

<style>
.page {
  width: 480px;
  height: 352px;
  background-color: #000000;
  padding: 14px 18px;
  box-sizing: border-box;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 2px;
}
.big {
  color: #ffffff;
  font-size: 56px;
  font-weight: bold;
  line-height: 64px;
  margin-top: 10px;
  white-space: nowrap;
  overflow: hidden;
}
.count {
  color: #40ff5e;
  font-size: 30px;
  font-weight: bold;
  line-height: 36px;
  margin-top: 6px;
}
.hint {
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  line-height: 19px;
  margin-top: 6px;
  white-space: nowrap;
  overflow: hidden;
}
.safety {
  color: rgba(255, 255, 255, 0.75);
  font-size: 11px;
  line-height: 15px;
  margin-top: 6px;
}
.sensor {
  color: rgba(64, 255, 94, 0.62);
  font-size: 10px;
  line-height: 13px;
  margin-top: 6px;
  white-space: nowrap;
  overflow: hidden;
}
.btnrow {
  display: flex;
  flex-direction: row;
  margin-top: 10px;
}
.btn {
  flex: 1;
  background-color: #14541f;
  color: #ffffff;
  border: 1px solid rgba(64, 255, 94, 0.72);
  font-size: 16px;
  font-weight: bold;
  padding: 8px 0;
  text-align: center;
}
.foot {
  color: rgba(64, 255, 94, 0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 8px;
  white-space: nowrap;
  overflow: hidden;
}
.foot2 {
  color: rgba(64, 255, 94, 0.48);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
}
</style>
