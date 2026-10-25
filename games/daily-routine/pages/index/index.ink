<script def>
{
  "title": "Daily Routine"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Daily Routine （每日一套） — head-movement mini-game GA20, Group D
// (fun finale) and the SERIES FINALE (20/20). EXTREME simplicity:
// one page, three states only (ready / playing / done). One
// mechanic: follow the guided routine to the end. The finale
// strings the A-group moves together in 5 FIXED segments, each
// return-gated, each with a 30-second skip rule. Voice (TTS)
// guides every segment and counts everything. No menus, no
// settings, no levels, no camera, no mic/ASR, no storage, no
// network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Every move here stays
// segmented: center -> one direction -> hold/return -> center ->
// next move. Never a circle, never a sweep from one extreme to
// another, never fast jerking. Slow, small range, stop at mild
// stretch, never pain. For UP specifically: only to a mild
// stretch, NEVER hyperextend, NEVER throw the head back. Stop at
// once on pain / dizziness / numbness / nausea. Sit or stand
// steady first. The whole routine takes about 2 minutes (honest
// estimate from the segment timings: roughly 90-120 seconds of
// moves plus returns and calibration — not a promised exact
// duration). This is entertainment / daily activity, NOT medical
// diagnosis, treatment or a rehab prescription; people with
// cervical disease, vertigo, post-op or head/neck injury history
// should ask a doctor first.
//
// THE 5 SEGMENTS (fixed order, documented here and in AGENTS.md):
//  1. 点头 3 次 — gentle nods, GA01 pattern: down past ~27 deg,
//     hold ~0.8 s, return <10 deg. Nod event is the primary YES
//     for a nod (see onHeadGesture below); pitch fallback covers
//     hosts that do not deliver it.
//  2. 转头左右各 2 次 — alternating left, right, left, right,
//     GA02 pattern: past ~27 deg, hold ~0.8 s, return <10 deg.
//  3. 贴耳左右各 1 次 — ear-to-shoulder hold 3 s each side, GA03
//     pattern BUT 3 s, not GA03's 5 s (deliberate routine
//     shortening, documented). Voice: 「肩膀别抬」.
//  4. 仰低拉伸各 1 次 — up hold 3 s, then down hold 3 s, GA04
//     pattern BUT 3 s, not GA04's 5 s (deliberate routine
//     shortening, documented). Up only to a mild stretch.
//  5. 收下巴 2 次 — chin tucks, GA06 pattern BUT 3 s, not GA06's
//     5 s (deliberate routine shortening, documented): small
//     pitch in the 14-20 deg band, hold 3 s, return <8 deg
//     pitch. Pitch >= 20 deg is a full nod, NOT a tuck, and
//     counts nothing (voice correction).
// SEGMENT TIMEOUT: 30 s per segment. If a segment is not
// completed within 30 s, voice says 「这一节先跳过」 and the
// routine moves to the next segment. A skipped segment is
// counted as skipped, NOT as failed and NOT as completed; the
// routine always finishes. RETURN GATE: after every segment
// except the last, the player MUST return to center (<10 deg on
// BOTH axes; after the tuck segment the pitch return is already
// <8 deg, the gate still checks both axes) before the next
// segment is announced: if not returned within 4 seconds, TTS
// prompts 「请回正」 and the timer resets — the next segment is
// NEVER announced until the return actually happens (GA10/GA13's
// stricter rule).
// CALIBRATION (three prompts, inside the playing state, not extra
// states): START calibrates the center (head straight at START),
// then (1) 「请低一下头」 learns DOWN (UP = opposite pitch
// sign); (2) 「请向左转一下」 learns LEFT (RIGHT = opposite yaw
// sign); (3) 「请向左贴一下」 learns left roll (right roll =
// opposite roll sign). Nothing counts before ALL THREE
// calibrations complete; restart re-runs all three.
// TUCK RISK FLAG (GA06's, carried honestly): a true chin tuck is
// mostly a horizontal TRANSLATION, which an orientation sensor
// barely sees; there is no translation sensor API on this
// platform. The routine therefore detects the tuck as a SMALL
// pitch motion in the 14-20 deg band, cued as 「像点头的一半还
// 不到」. The device checklist must confirm natural tucks land
// in that band, or the threshold needs adjustment — never ship
// silently as a working tuck detector.
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a
// labeled DEMO stepper (calibration steps, then one tap per
// whole segment) so the playing/done states can be previewed.
// On a real device with a sensor there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL_SEG = 5;
const DIR_DEG = 27;       // direction reached: 25-30 deg
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const HOLD_NOD_MS = 800;  // nod / turn hold: ~0.8 s
const HOLD_SEG_MS = 3000; // ear / stretch / tuck hold: 3 s (routine variant)
const TUCK_LO = 14;       // tuck band lower bound (pitch deg)
const TUCK_HI = 20;       // tuck band upper bound; >= 20 deg = full nod, not a tuck
const TUCK_RETURN = 8;    // tuck return: pitch < 8 deg (GA06, tighter than 10)
const SEG_MS = 30000;     // per-segment timeout: 30 s, then skip
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED segment order (not random). Segment targets:
//  seg 0 nod: 3 reps, target down
//  seg 1 turn: 4 reps, targets left, right, left, right
//  seg 2 ear: 2 reps, targets left roll, right roll
//  seg 3 stretch: 2 reps, targets up, down
//  seg 4 tuck: 2 reps, target tuck band
const SEG_NAMES = ['点头', '转头', '贴耳', '仰低拉伸', '收下巴'];
const SEG_REPS = [3, 4, 2, 2, 2];
const TURN_SEQ = ['left', 'right', 'left', 'right'];
const EAR_SEQ = ['left', 'right'];
const STRETCH_SEQ = ['up', 'down'];

export default {
  data: {
    big: '准备',
    countLine: '完成 0 / 5 节',
    hint: '单击开始 · 每日一套，跟着语音慢慢做',
    safety: '每日一套不转圈：每节只做一个方向，做完回正，下一节才报。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。一套约 2 分钟，每节 30 秒没做完就先跳过，不硬撑。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。收下巴一节如实说明：真收下巴主要是下巴水平往后收，方向传感器只能看到一点点小俯仰，游戏按 14–20° 小俯仰带判定，提示语是“像点头的一半还不到”。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | calibRollTurn | calibRollReturn | segWait | segHold | segReturn | returning
    this._sub = 'segWait';
    this._seg = 0;
    this._rep = 0;
    this._doneSegs = 0;
    this._skippedSegs = 0;
    this._sensor = null;
    this._quat = null;
    this._pitch = null;
    this._yaw = null;
    this._roll = null;
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._rollCenter = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._downSign = null;
    this._leftSign = null;
    this._rollLeftSign = null;
    this._holdAccum = 0;
    this._nodDownSeen = false;
    this._segSince = 0;
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
  // pitch = asin(2*(w*x - y*z)), clamped.
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees.
  // Only the RELATIVE values vs the calibrated center are ever
  // used, so the host's absolute zero never matters.
  //
  // SIGN LEARNING — learned, not assumed (three prompts, all inside
  // the playing state): "请低一下头" records the pitch sign the
  // head actually moves as DOWN (UP = opposite); "请向左转一下"
  // records the yaw sign the head actually moves as LEFT (RIGHT =
  // opposite); "请向左贴一下" records the roll sign the head
  // actually moves as LEFT (right roll = opposite). A host whose
  // sign is inverted on any axis therefore still counts correctly.
  // Residual caveat, documented in AGENTS.md and on the device
  // checklist: calibration trusts the player to follow each
  // prompt — doing the opposite motion would learn that axis
  // backwards. Fail-safes: nothing counts before ALL THREE
  // calibrations complete, and any restart re-runs all three.
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
        self._quat = [q[0], q[1], q[2], q[3]];
        const x = q[0], y = q[1], z = q[2], w = q[3];
        let v = 2 * (w * x - y * z);
        if (v > 1) v = 1;
        if (v < -1) v = -1;
        self._pitch = Math.asin(v) * 180 / Math.PI;
        self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)) * 180 / Math.PI;
        self._roll = Math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y)) * 180 / Math.PI;
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
  _relRoll() {
    if (!this._hasReading || this._roll === null) return null;
    return this._wrap(this._roll - this._rollCenter);
  },
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
  _leftRoll() {
    const rel = this._relRoll();
    if (rel === null || this._rollLeftSign === null) return null;
    return rel * this._rollLeftSign;
  },
  _atCenter(relPitch, relYaw) {
    return Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG;
  },
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
    this._rollCenter = this._roll;
  },
  _dirWord(dir) {
    if (dir === 'up') return '上';
    if (dir === 'down') return '下';
    if (dir === 'left') return '左';
    return '右';
  },
  _dirArrow(dir) {
    if (dir === 'up') return '↑';
    if (dir === 'down') return '↓';
    if (dir === 'left') return '←';
    return '→';
  },
  // Current segment's target direction for this rep (null for nod/tuck).
  _segTarget() {
    if (this._seg === 1) return TURN_SEQ[this._rep];
    if (this._seg === 2) return EAR_SEQ[this._rep];
    if (this._seg === 3) return STRETCH_SEQ[this._rep];
    return null;
  },
  _holdMs() {
    return (this._seg === 0 || this._seg === 1) ? HOLD_NOD_MS : HOLD_SEG_MS;
  },
  // True when the head is past threshold in the segment target.
  _targetReached(dp, ly, lr) {
    if (this._seg === 0) return dp >= DIR_DEG;
    if (this._seg === 1) {
      const dir = this._segTarget();
      if (dir === 'left') return ly >= DIR_DEG;
      return ly <= -DIR_DEG;
    }
    if (this._seg === 2) {
      const dir = this._segTarget();
      if (dir === 'left') return lr >= DIR_DEG;
      return lr <= -DIR_DEG;
    }
    if (this._seg === 3) {
      const dir = this._segTarget();
      if (dir === 'up') return dp <= -DIR_DEG;
      return dp >= DIR_DEG;
    }
    // seg 4 tuck: inside the small band only.
    return dp >= TUCK_LO && dp < TUCK_HI;
  },
  // True while the hold is still alive (hysteresis: 5 deg inside).
  _stillInTarget(dp, ly, lr) {
    if (this._seg === 0) return dp >= DIR_DEG - 5;
    if (this._seg === 1) {
      const dir = this._segTarget();
      if (dir === 'left') return ly >= DIR_DEG - 5;
      return ly <= -(DIR_DEG - 5);
    }
    if (this._seg === 2) {
      const dir = this._segTarget();
      if (dir === 'left') return lr >= DIR_DEG - 5;
      return lr <= -(DIR_DEG - 5);
    }
    if (this._seg === 3) {
      const dir = this._segTarget();
      if (dir === 'up') return dp <= -(DIR_DEG - 5);
      return dp >= DIR_DEG - 5;
    }
    return dp >= TUCK_LO - 3 && dp < TUCK_HI;
  },
  // Voice instruction for the current segment rep.
  _segInstruction() {
    if (this._seg === 0) return '点头，慢慢低头，停一下，回正';
    if (this._seg === 1) return '转头，向' + this._dirWord(this._segTarget()) + '转，停一下，回正';
    if (this._seg === 2) return '贴耳，向' + this._dirWord(this._segTarget()) + '贴，肩膀别抬，稳住 3 秒，回正';
    if (this._seg === 3) {
      const dir = this._segTarget();
      let t = dir === 'up' ? '仰头，只到轻微拉伸，不要用力往后仰，稳住 3 秒，回正' : '低头，稳住 3 秒，回正';
      return t;
    }
    return '收下巴，下巴水平往后收，像点头的一半还不到，稳住 3 秒，放松';
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

  // Nod event: officially documented ONLY for 'nod'. It NEVER counts
  // on its own. It only completes a nod rep the sensor already saw
  // go down, once the head is back inside the center band (GA01's
  // pattern); in segWait it moves a down-past-15-deg head into the
  // hold, so a gentle nod the pitch fallback would miss still
  // counts when the sensor confirms the head is down.
  onHeadGesture(event) {
    const g = (event && (event.gesture || event.detail)) || event;
    const name = typeof g === 'string' ? g : (g && g.name);
    if (name !== 'nod') return;
    if (this._phase !== 'playing' || this._seg !== 0) return;
    if (this._sub === 'segWait') {
      const dp = this._downPitch();
      if (dp !== null && dp >= 15) {
        this._nodDownSeen = true;
        this._sub = 'segHold';
        this._holdAccum = 0;
        this._render();
      }
    } else if (this._sub === 'segReturn' && this._nodDownSeen) {
      this._completeRep();
    }
  },

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

  _beginRoutine() {
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._rollCenter = (this._hasReading && this._roll !== null) ? this._roll : 0;
    this._centerSet = true;
    this._seg = 0;
    this._rep = 0;
    this._doneSegs = 0;
    this._skippedSegs = 0;
    this._downSign = null;
    this._leftSign = null;
    this._rollLeftSign = null;
    this._sub = 'calibDownTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始每日一套。一共 5 节，跟着语音慢慢做，每节做完回正，下一节才报。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: routine started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _announceSegment() {
    this._rep = 0;
    this._holdAccum = 0;
    this._nodDownSeen = false;
    this._sub = 'segWait';
    this._segSince = Date.now();
    this._speak('第 ' + (this._seg + 1) + ' 节，' + SEG_NAMES[this._seg] + '。' + this._segInstruction());
    this.setData({ foot: 'EVT: segment ' + (this._seg + 1) + '/' + TOTAL_SEG + ' ' + SEG_NAMES[this._seg] + ' announced' });
    this._render();
  },

  // One rep finished (hold complete + return to center).
  _completeRep() {
    this._rep++;
    if (this._rep >= SEG_REPS[this._seg]) {
      this._finishSegment(true);
    } else {
      this._sub = 'segWait';
      this._holdAccum = 0;
      this._nodDownSeen = false;
      this._speak(this._segInstruction());
      this.setData({ foot: 'EVT: segment ' + (this._seg + 1) + ' rep ' + this._rep + '/' + SEG_REPS[this._seg] + ' done' });
    }
    this._render();
  },

  // Finish one segment. Completed adds 1 to done; skipped does not.
  // After every segment except the last, the player must return to
  // center before the next segment is announced. The final segment
  // ends the routine at once.
  _finishSegment(completed) {
    if (completed) {
      this._doneSegs++;
      this._speak('第 ' + (this._seg + 1) + ' 节做完了');
    } else {
      this._skippedSegs++;
      this._speak('这一节先跳过');
    }
    if (this._seg >= TOTAL_SEG - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE segments ' + this._doneSegs + '/' + TOTAL_SEG + ' skipped ' + this._skippedSegs });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: segment ' + (this._seg + 1) + ' ' + (completed ? 'done' : 'skipped') + ', awaiting return to center' });
    }
    this._render();
  },

  _nextSegment() {
    this._seg++;
    this._announceSegment();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real pass. One
  // tap per calibration step, then one tap per whole segment.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibDownTurn') {
      this._downSign = 1;
      this._sub = 'calibDownReturn';
      this.setData({ foot: 'EVT: DEMO down-calibration tilt (sensor SKIP)' });
    } else if (this._sub === 'calibDownReturn') {
      this._sub = 'calibLeftTurn';
      this.setData({ foot: 'EVT: DEMO down-calibration return (sensor SKIP)' });
    } else if (this._sub === 'calibLeftTurn') {
      this._leftSign = 1;
      this._sub = 'calibLeftReturn';
      this.setData({ foot: 'EVT: DEMO left-calibration turn (sensor SKIP)' });
    } else if (this._sub === 'calibLeftReturn') {
      this._sub = 'calibRollTurn';
      this.setData({ foot: 'EVT: DEMO left-calibration return (sensor SKIP)' });
    } else if (this._sub === 'calibRollTurn') {
      this._rollLeftSign = 1;
      this._sub = 'calibRollReturn';
      this.setData({ foot: 'EVT: DEMO roll-calibration tilt (sensor SKIP)' });
    } else if (this._sub === 'calibRollReturn') {
      this._announceSegment();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._doneSegs++;
      if (this._seg >= TOTAL_SEG - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done segments ' + this._doneSegs + '/' + TOTAL_SEG + ' (sensor SKIP)' });
      } else {
        this._seg++;
        this._announceSegment();
        this.setData({ foot: 'EVT: DEMO segment passed, done ' + this._doneSegs + '/' + TOTAL_SEG + ' (sensor SKIP)' });
      }
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRoutine(); return; }
    if (this._phase === 'done') { this._beginRoutine(); return; }
    if (this._sensorSkip || !this._hasReading) { this._demoStep(); return; }
    this._speak(this._currentInstruction());
  },

  _currentInstruction() {
    if (this._sub === 'calibDownTurn') return '请低一下头，慢慢低头，到微酸就停';
    if (this._sub === 'calibDownReturn') return '回正到中间';
    if (this._sub === 'calibLeftTurn') return '请向左转一下，慢慢向左转';
    if (this._sub === 'calibLeftReturn') return '回正到中间';
    if (this._sub === 'calibRollTurn') return '请向左贴一下，耳朵慢慢贴向左肩，肩膀别抬';
    if (this._sub === 'calibRollReturn') return '回正到中间';
    if (this._sub === 'returning') return '回正到中间，下一节等你回正';
    return this._segInstruction();
  },

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
    const relRoll = this._relRoll();
    if (relPitch === null || relYaw === null || relRoll === null) return;
    const now = Date.now();

    // --- calibration 1: learn which pitch sign means down -----------
    if (this._sub === 'calibDownTurn') {
      if (Math.abs(relPitch) >= DIR_DEG) {
        this._downSign = relPitch > 0 ? 1 : -1;
        this._sub = 'calibDownReturn';
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
    if (this._sub === 'calibDownReturn') {
      if (this._atCenter(relPitch, relYaw)) {
        this._recenter();
        this._sub = 'calibLeftTurn';
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
    if (this._sub === 'calibLeftTurn') {
      if (Math.abs(relYaw) >= DIR_DEG) {
        this._leftSign = relYaw > 0 ? 1 : -1;
        this._sub = 'calibLeftReturn';
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
    if (this._sub === 'calibLeftReturn') {
      if (this._atCenter(relPitch, relYaw)) {
        this._recenter();
        this._sub = 'calibRollTurn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('最后校准一下贴耳：请向左贴一下，耳朵慢慢贴向左肩，肩膀别抬');
        this.setData({ foot: 'EVT: left calibration complete, awaiting roll-calibration tilt' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: left calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- calibration 3: learn which roll sign means left ------------
    if (this._sub === 'calibRollTurn') {
      if (Math.abs(relRoll) >= DIR_DEG) {
        this._rollLeftSign = relRoll > 0 ? 1 : -1;
        this._sub = 'calibRollReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: roll sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请向左贴一下，耳朵慢慢贴向左肩，肩膀别抬');
        this.setData({ foot: 'EVT: roll calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._sub === 'calibRollReturn') {
      if (this._atCenter(relPitch, relYaw) && Math.abs(relRoll) < CENTER_DEG) {
        this._recenter();
        this._announceSegment();
        this.setData({ foot: 'EVT: calibration complete, first segment announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: roll calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- return gate between segments -------------------------------
    if (this._sub === 'returning') {
      if (this._atCenter(relPitch, relYaw)) {
        this._nextSegment();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        this._speak('请回正，下一节等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next segment still gated on return' });
      }
      this._render();
      return;
    }

    // --- segments -----------------------------------------------------
    const dp = this._downPitch();
    const ly = this._leftYaw();
    const lr = this._leftRoll();
    if (dp === null || ly === null || lr === null) return;

    // Segment timeout: skip, never fail, routine always finishes.
    if (now - this._segSince >= SEG_MS) {
      this._finishSegment(false);
      return;
    }

    if (this._sub === 'segWait') {
      if (this._targetReached(dp, ly, lr)) {
        // Tuck overshoot (>= 20 deg) is handled in segHold via the
        // band check; segWait only enters the hold inside the band.
        this._nodDownSeen = (this._seg === 0);
        this._sub = 'segHold';
        this._holdAccum = 0;
        this.setData({ foot: 'EVT: segment ' + (this._seg + 1) + ' rep ' + (this._rep + 1) + ' target reached, hold started' });
      }
      this._render();
      return;
    }
    if (this._sub === 'segHold') {
      if (this._seg === 4 && dp >= TUCK_HI) {
        // Full nod, not a tuck: void the hold, count nothing.
        this._sub = 'segWait';
        this._holdAccum = 0;
        this._speak('幅度小一点，这是收下巴不是低头，慢慢回正重新来');
        this.setData({ foot: 'EVT: tuck overshoot >= 20 deg, hold voided, no count' });
        this._render();
        return;
      }
      if (!this._stillInTarget(dp, ly, lr)) {
        // Released early: aborted, no count.
        this._sub = 'segWait';
        this._holdAccum = 0;
        this._nodDownSeen = false;
        this.setData({ foot: 'EVT: hold released early, no count' });
        this._render();
        return;
      }
      // Accumulate only while steady where the host reports
      // stability; if the host never reports stability, elapsed
      // time alone gates the hold (documented fallback).
      const steadyOk = !this._stableSeen || this._stable;
      if (steadyOk) this._holdAccum += TICK_MS;
      if (this._holdAccum >= this._holdMs()) {
        this._sub = 'segReturn';
        this.setData({ foot: 'EVT: hold complete, awaiting return to center' });
      }
      this._render();
      return;
    }
    if (this._sub === 'segReturn') {
      const returned = (this._seg === 4)
        ? (dp < TUCK_RETURN)
        : this._atCenter(relPitch, relYaw);
      if (returned) {
        this._completeRep();
        return;
      }
      this._render();
      return;
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      big = '准备';
      hint = '单击开始 · 每日一套，跟着语音慢慢做';
      safety = '每日一套不转圈：每节只做一个方向，做完回正，下一节才报。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。一套约 2 分钟，每节 30 秒没做完就先跳过，不硬撑。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。收下巴一节如实说明：真收下巴主要是下巴水平往后收，方向传感器只能看到一点点小俯仰，游戏按 14–20° 小俯仰带判定，提示语是“像点头的一半还不到”。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 ' + this._doneSegs + ' / 5 节' : '完成 ' + this._doneSegs + ' / 5 节';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下左右贴耳）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibDownTurn') {
        big = '请低一下头';
        hint = '只校准第一步：慢慢低头，到微酸就停';
        mainBtn = demo ? '演示低一下头' : '朗读';
      } else if (this._sub === 'calibDownReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'calibLeftTurn') {
        big = '请向左转一下';
        hint = '只校准第二步：慢慢向左转';
        mainBtn = demo ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibLeftReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'calibRollTurn') {
        big = '请向左贴一下';
        hint = '只校准第三步：耳朵贴向左肩，肩膀别抬';
        mainBtn = demo ? '演示向左贴' : '朗读';
      } else if (this._sub === 'calibRollReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'returning') {
        big = '回正到中间';
        hint = '本节已报完 · 慢慢贴回正前方，下一节等你回正';
        mainBtn = demo ? '演示完成一节' : '朗读';
      } else if (this._sub === 'segHold') {
        const total = Math.ceil(this._holdMs() / 1000);
        const left = Math.max(1, total - Math.floor(this._holdAccum / 1000));
        big = '第 ' + (this._seg + 1) + ' 节 · ' + SEG_NAMES[this._seg] + ' · 稳住 ' + left + ' 秒';
        hint = this._segInstruction();
        mainBtn = demo ? '演示完成一节' : '朗读';
      } else {
        big = '第 ' + (this._seg + 1) + ' 节 · ' + SEG_NAMES[this._seg];
        hint = this._segInstruction();
        mainBtn = demo ? '演示完成一节' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const segLine = '完成 ' + this._doneSegs + ' / 5 节';
    const repLine = (this._phase === 'playing' && this._sub !== 'returning' && !this._sub.startsWith('calib'))
      ? ' · 本节 ' + (this._rep + 1) + ' / ' + SEG_REPS[this._seg]
      : '';
    const key = [big, segLine, repLine, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: segLine + repLine,
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
    <div class="title">每日一套 DAILY ROUTINE</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">每节只做一个方向 · 做完回正 · 30 秒没做完先跳过 · 痛晕立刻停</div>
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
.big {
  color: #ffffff;
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
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  line-height: 19px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.safety {
  color: rgba(255, 255, 255, 0.75);
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
  margin-top: 6px;
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
