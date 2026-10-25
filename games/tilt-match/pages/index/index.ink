<script def>
{
  "title": "Tilt Match"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Tilt Match （贴耳对角度） — head-movement mini-game GA22, Wave 2,
// Group E (precision control). EXTREME simplicity: one page, three
// states only (ready / playing / done). 6 trials, one at a time:
// voice calls a SIDE and a small ANGLE ("向左贴，12 度") and the
// screen shows the same call; tilt the ear toward the shoulder so
// the relative ROLL enters the target band (target +/-5 deg) and
// hold steady ~0.8 s = hit (+1, "对上了"); then return to center
// before the next call. Voice (TTS) does the rest. No menus, no
// settings, no levels, no camera, no mic/ASR, no storage, no
// network.
//
// THE ROLL-AXIS COUNTERPART OF GA21 (angle-match): GA21 judged
// angle precision on the YAW axis (turn left/right into a called
// band); this game judges the same precision on the ROLL axis
// (ear-to-shoulder tilt into a called band). DISTINCT FROM GA03
// (ear-tilt): GA03 tilted to the comfortable limit and held 5 s;
// this game matches SMALL called target angles (12 or 20 deg,
// +/-5 deg) and only holds ~0.8 s — precision, not stretch.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> hold -> return to center -> next
// trial. Never continuous circling, never sweep from one extreme
// to another, never fast jerking. Ear tilts are gentle: the ear
// goes toward the shoulder, NEVER force it, and NEVER lift the
// shoulder up to meet the ear — "肩膀别抬" is said in the voice
// guidance, not just on screen. Slow, small range, stop at mild
// stretch, never pain. Stop at once on pain / dizziness /
// numbness / nausea. Sit or stand steady first. One round set is
// 6 trials, short. This is entertainment / daily activity, NOT
// medical diagnosis, treatment or a rehab prescription; people
// with cervical disease, vertigo, post-op or head/neck injury
// history should ask a doctor first.
//
// HOW A TRIAL IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt inside the playing state (not an extra
// state), GA03's pattern: "请向左贴一下" learns LEFT tilt (RIGHT =
// opposite roll sign). Nothing counts before calibration
// completes; restart re-runs it. Per trial: TTS calls side +
// angle ("向左贴，12 度，肩膀别抬"); the relative roll entering
// the band (target +/-5 deg) speaks "停，稳住" once; holding
// steady ~0.8 s inside the band = hit ("对上了"). Leaving the
// band before the hold completes resets the hold to zero — an
// early lean-back counts nothing, an overshoot counts nothing,
// and the 10-second trial clock keeps running. Tilting to the
// WRONG side past 15 deg = miss at once ("没对上"); 10 s without
// a hit = miss ("没对上"). After every trial (hit or miss) the
// player MUST return to center (roll, pitch AND yaw all <10 deg)
// before the next call: if not returned within 4 seconds, TTS
// prompts "请回正" and the grace timer resets — the grace counts
// nothing and the next call is NEVER announced until the return
// actually happens (GA10/GA13's stricter rule). The final trial
// ends the game at once: there is no next trial for a return to
// gate. The fixed trial list is NOT random, so preview and
// device behaviour are reproducible: (left,12) (right,20)
// (left,20) (right,12) (left,12) (right,20). Every trial is
// separated by a return to center, so no circling arises. Sensor
// missing (web preview) = SKIP/demo state, never a fake pass:
// the screen says so, and the main button becomes a labeled DEMO
// stepper (calibration steps, then one tap per whole trial as a
// hit, return collapsed) so the playing/done states can be
// previewed. On a real device with a sensor there is no DEMO
// path at all.
// -------------------------------------------------------------------

const TOTAL = 6;
const BAND_DEG = 5;       // target band: target +/-5 deg
const HOLD_MS = 800;      // hold-steady inside the band ~0.8 s
const WRONG_DEG = 15;     // wrong side past 15 deg = miss at once
const CALIB_DEG = 15;     // calibration: a 15 deg tilt learns the left sign
const TRIAL_MS = 10000;   // 10 s without a hit = miss
const CENTER_DEG = 10;    // return-to-center: roll, pitch AND yaw all <10 deg
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED trial list (not random): side + target angle in degrees.
const TRIALS = [
  { side: 'left', deg: 12 },
  { side: 'right', deg: 20 },
  { side: 'left', deg: 20 },
  { side: 'right', deg: 12 },
  { side: 'left', deg: 12 },
  { side: 'right', deg: 20 }
];

export default {
  data: {
    arrow: '·',
    big: '准备',
    countLine: '对上 0 / 6',
    hint: '单击开始 · 对 6 个贴耳角度，不转圈',
    safety: '贴耳对角度不转圈：每次只报一边一个角度，耳朵慢慢向那侧肩膀贴到所报角度，停稳，再回正到中间，下一个角度才报。贴要轻，绝不硬压，肩膀别抬。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | wait | inBand | returning
    this._sub = 'wait';
    this._trial = 0;
    this._score = 0;
    this._sensor = null;
    this._roll = null;     // latest roll deg (the judged axis)
    this._pitch = null;    // latest pitch deg (return gate only)
    this._yaw = null;      // latest yaw deg (return gate only)
    this._rollCenter = 0;
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._leftSign = null; // +1 / -1: which raw roll sign means LEFT tilt (learned)
    this._holdAccum = 0;
    this._trialSince = 0;
    this._returnSince = 0;
    this._stallSince = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._timer = null;
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
  // Roll from the orientation quaternion, same formula as GA03:
  // roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees —
  // trials are judged on roll alone, because every called target
  // is a left/right ear tilt. Pitch uses the fleet formula
  // (GA01/GA04): pitch = asin(2*(w*x - y*z)), clamped; yaw uses
  // GA02's formula: yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)).
  // Pitch and yaw are read ONLY for the return-to-center gate
  // (all three axes <10 deg). Only the RELATIVE roll/pitch/yaw vs
  // the calibrated center are ever used, so the host's absolute
  // zero never matters.
  //
  // ROLL SIGN — learned, not assumed (device verification item):
  // at round start the game asks once ("请向左贴一下") and records
  // the sign the head actually moves as LEFT tilt; RIGHT is the
  // opposite sign. A host roll-sign inversion therefore cannot
  // silently swap left/right counts. Residual caveat, documented
  // in AGENTS.md and on the device-test checklist: calibration
  // trusts the player to follow that one prompt — tilting right
  // instead of left would learn the signs backwards. Fail-safes:
  // nothing counts before calibration completes, the first trial
  // is left again (so a backwards calibration feels wrong at
  // once), and any restart re-runs calibration. No fallback sign
  // is ever guessed.
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
        self._roll = Math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y)) * 180 / Math.PI;
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

  // Relative angles vs calibrated center, wrapped to [-180, 180].
  _wrap(d) {
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },
  _relRoll() {
    if (!this._hasReading || this._roll === null) return null;
    return this._wrap(this._roll - this._rollCenter);
  },
  _relPitch() {
    if (!this._hasReading || this._pitch === null) return null;
    return this._wrap(this._pitch - this._pitchCenter);
  },
  _relYaw() {
    if (!this._hasReading || this._yaw === null) return null;
    return this._wrap(this._yaw - this._yawCenter);
  },
  // Signed roll in "left-positive" space, once calibration has
  // learned the sign. Null before that.
  _leftRoll() {
    const rel = this._relRoll();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },
  // Head back inside the center band on ALL THREE axes (roll is
  // the judged axis; pitch and yaw must also be back, so a
  // leftover turn or nod cannot fake a return).
  _atCenter(relRoll, relPitch, relYaw) {
    return Math.abs(relRoll) < CENTER_DEG && Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG;
  },
  // Re-center on the head's current position (after the calibration
  // return), so trials are judged from where "straight" is now.
  _recenter() {
    this._rollCenter = this._roll;
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _trialDef() { return TRIALS[this._trial]; },
  _sideWord(side) { return side === 'left' ? '左' : '右'; },
  _sideArrow(side) { return side === 'left' ? '↙' : '↘'; },
  _callText() {
    const t = this._trialDef();
    return '向' + this._sideWord(t.side) + '贴，' + t.deg + ' 度，肩膀别抬';
  },
  // Roll magnitude TOWARD the called side (positive = toward it,
  // negative = toward the wrong side), in degrees.
  _toward(leftRoll) {
    return this._trialDef().side === 'left' ? leftRoll : -leftRoll;
  },
  // True when the toward-magnitude is inside the target band.
  _inBand(toward) {
    const t = this._trialDef();
    return toward >= t.deg - BAND_DEG && toward <= t.deg + BAND_DEG;
  },
  // True when the head is past the wrong-side miss threshold.
  _wrongSide(toward) {
    return toward <= -WRONG_DEG;
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
  // left/right tilts come from the sensor, never from a gesture event.

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
    // the left sign is then learned by the one calibration prompt.
    this._rollCenter = (this._hasReading && this._roll !== null) ? this._roll : 0;
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerSet = true;
    this._trial = 0;
    this._score = 0;
    this._leftSign = null;
    this._sub = 'calibTurn';
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始贴耳对角度。贴耳对角度不转圈：每次只报一边一个角度，贴到那个角度停稳，再回正，下一个才报。贴耳要轻，肩膀别抬，慢，小幅度。先校准：请向左贴一下。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting left-tilt calibration' });
    this._render();
  },

  _announceTrial() {
    this._sub = 'wait';
    this._trialSince = Date.now();
    this._holdAccum = 0;
    this._speak(this._callText());
    this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + '/' + TOTAL + ' call ' + this._trialDef().side + ' ' + this._trialDef().deg + ' deg' });
    this._render();
  },

  // Finish one trial. Hit adds 1 ("对上了"); wrong-side and timeout
  // misses add 0 ("没对上"). After every trial the player must
  // return to center before the next call (see _tick 'returning').
  // The final trial ends the game at once: there is no next trial
  // for a return to gate.
  _finishTrial(hit) {
    if (hit) {
      this._score++;
      this._speak('对上了');
    } else {
      this._speak('没对上');
    }
    if (this._trial >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE hits ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + (hit ? ' hit' : ' miss') + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _nextTrial() {
    this._trial++;
    this._announceTrial();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real hit. One
  // tap per calibration step, then one tap per whole trial as a
  // hit (tilt + band hold + return collapsed) so the playing/done
  // states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration tilt (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._announceTrial();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._trial >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done hits ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._trial++;
        this._announceTrial();
        this.setData({ foot: 'EVT: DEMO hit trial, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'calibTurn') return '请向左贴一下，耳朵向左肩贴，肩膀别抬';
    if (this._sub === 'calibReturn') return '回正到中间';
    if (this._sub === 'inBand') return '停，稳住';
    if (this._sub === 'returning') return '回正到中间，下一个角度等你回正';
    return this._callText();
  },

  // ---- tick: the trial state machine ---------------------------------
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
    const relRoll = this._relRoll();
    const relPitch = this._relPitch();
    const relYaw = this._relYaw();
    if (relRoll === null || relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives trials
    const now = Date.now();

    // --- calibration: learn which sign means left, count nothing ---
    if (this._sub === 'calibTurn') {
      if (Math.abs(relRoll) >= CALIB_DEG) {
        this._leftSign = relRoll > 0 ? 1 : -1;
        this._sub = 'calibReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: left-tilt sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请向左贴一下，耳朵向左肩贴，肩膀别抬');
        this.setData({ foot: 'EVT: calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._sub === 'calibReturn') {
      if (this._atCenter(relRoll, relPitch, relYaw)) {
        this._recenter();
        this._announceTrial();
        this.setData({ foot: 'EVT: calibration complete, center re-set, first trial announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- return gate: next call waits for a real return -------------
    if (this._sub === 'returning') {
      if (this._atCenter(relRoll, relPitch, relYaw)) {
        this._nextTrial();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        // Grace expired: TTS prompts "请回正" and the timer resets.
        // Nothing is counted by the grace, and the next call is NOT
        // announced until the return actually happens.
        this._speak('请回正，下一个角度等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next trial still gated on return' });
      }
      this._render();
      return;
    }

    // --- trials: leftRoll is positive-left once calibrated ----------
    const lr = this._leftRoll();
    if (lr === null) return;
    const toward = this._toward(lr);

    if (this._sub === 'wait') {
      if (this._inBand(toward)) {
        this._sub = 'inBand';
        this._holdAccum = 0;
        this._speak('停，稳住');
        this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + ' entered band ' + this._trialDef().deg + '+/-' + BAND_DEG + ' deg, hold started' });
      } else if (this._wrongSide(toward)) {
        // Wrong side past threshold: miss at once, no hold-or-undo.
        this._finishTrial(false);
        return;
      } else if (now - this._trialSince >= TRIAL_MS) {
        this._finishTrial(false);
        return;
      }
    } else if (this._sub === 'inBand') {
      if (!this._inBand(toward)) {
        // Left the band before the hold completed (leaned back OR
        // overshot): hold resets to zero, nothing counts; the
        // 10-second trial clock keeps running.
        this._sub = 'wait';
        this._holdAccum = 0;
        this._speak('没稳住，再对一次，轻一点');
        this.setData({ foot: 'EVT: trial left band before full hold, hold reset, no count' });
      } else {
        // Hold accumulates only while steady where the host reports
        // stability; if the host never reports stability, elapsed
        // time alone gates the hold (documented fallback).
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) this._holdAccum += TICK_MS;
        if (this._holdAccum >= HOLD_MS) {
          this._finishTrial(true);
          return;
        }
      }
      if (this._sub === 'inBand' && now - this._trialSince >= TRIAL_MS) {
        // Clock ran out before the hold completed: miss.
        this._finishTrial(false);
        return;
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let arrow, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      arrow = '◎';
      big = '准备';
      hint = '单击开始 · 对 6 个贴耳角度，不转圈';
      safety = '贴耳对角度不转圈：每次只报一边一个角度，耳朵慢慢向那侧肩膀贴到所报角度，停稳，再回正到中间，下一个角度才报。贴要轻，绝不硬压，肩膀别抬。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '◎';
      big = this._demoUsed ? '演示对上 ' + this._score + ' / 6' : '对上 ' + this._score + ' / 6';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibTurn') {
        arrow = '↙';
        big = '请向左贴一下';
        hint = '只校准一次：耳朵慢慢向左肩贴，肩膀别抬';
        mainBtn = demo ? '演示向左贴' : '朗读';
      } else if (this._sub === 'calibReturn') {
        arrow = '◎';
        big = '回正到中间';
        hint = '慢慢回到正前方，肩膀放松';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'inBand') {
        const t = this._trialDef();
        arrow = this._sideArrow(t.side);
        big = '停，稳住…';
        hint = '保持贴 ' + t.deg + ' 度这个角度，停 0.8 秒';
        mainBtn = demo ? '演示对上一次' : '朗读';
      } else if (this._sub === 'returning') {
        arrow = '◎';
        big = '回正到中间';
        hint = '这一题完了 · 慢慢回到正前方，下一个角度等你回正';
        mainBtn = demo ? '演示对上一次' : '朗读';
      } else {
        const t = this._trialDef();
        arrow = this._sideArrow(t.side);
        big = '向' + this._sideWord(t.side) + '贴 · ' + t.deg + ' 度';
        hint = '慢慢贴到 ' + t.deg + ' 度 · 肩膀别抬 · 进圈停稳 0.8 秒 → 对上了 → 回正';
        mainBtn = demo ? '演示对上一次' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [arrow, big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      arrow: arrow,
      big: big,
      countLine: '对上 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">贴耳对角度 TILT MATCH</div>
    <div class="arrow">{{ arrow }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-level" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">一题一贴 · 对上要回正 · 肩膀别抬 · 痛晕立刻停</div>
  </div>
</template>

<style>
.page {
  width: 480px;
  height: 352px;
  background-color: #000000;
  padding: 10px 18px;
  box-sizing: border-box;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 2px;
}
.arrow {
  color: #40ff5e;
  font-size: 52px;
  font-weight: bold;
  line-height: 56px;
  text-align: center;
  margin-top: 2px;
}
.big {
  color: #7dff9e;
  font-size: 36px;
  font-weight: bold;
  line-height: 42px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.count {
  color: #40ff5e;
  font-size: 28px;
  font-weight: bold;
  line-height: 32px;
  margin-top: 2px;
}
.hint {
  color: rgba(125, 255, 158, 0.9);
  font-size: 14px;
  line-height: 19px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.safety {
  color: rgba(125, 255, 158, 0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 4px;
}
.sensor {
  color: rgba(64, 255, 94, 0.62);
  font-size: 10px;
  line-height: 13px;
  margin-top: 4px;
  white-space: nowrap;
  overflow: hidden;
}
.btnrow {
  display: flex;
  flex-direction: row;
  justify-content: center;
  margin-top: 8px;
}
.btn-level {
  width: 300px;
  background-color: #06280f;
  color: #7dff9e;
  border: 2px solid rgba(64, 255, 94, 0.85);
  border-bottom: 6px solid rgba(64, 255, 94, 0.85);
  border-radius: 10px;
  font-size: 16px;
  font-weight: bold;
  letter-spacing: 4px;
  padding: 9px 0;
  text-align: center;
}
.foot {
  color: rgba(64, 255, 94, 0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 6px;
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
