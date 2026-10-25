<script def>
{
  "title": "Traffic Light"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Traffic Light （红绿灯） — head-movement mini-game G19, Group D
// (fun finale). EXTREME simplicity: one page, three states only
// (ready / playing / done). One mechanic: obey the light. 10
// rounds, fixed sequence: green = turn to the cued direction,
// red = freeze still. Voice (TTS) does the rest. No menus, no
// settings, no levels, no camera, no mic/ASR, no storage, no
// network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only slow, segmented
// motion: green rounds turn to ONE cued direction and return to
// center before the next round; red rounds do not move at all.
// Never a sweep, never fast jerking, never a rapid
// green-red-green flinch. Slow, small range, stop at mild
// stretch, never pain. For UP specifically: only to a mild
// stretch, NEVER hyperextend, NEVER throw the head back. Stop at
// once on pain / dizziness / numbness / nausea. Sit or stand
// steady first. One game is 10 rounds, short. This is
// entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// HOW A ROUND IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then TWO
// calibration prompts inside the playing state (not extra
// states), G05's dual-axis pattern: (1) "请低一下头" learns DOWN
// (UP = opposite pitch sign); (2) "请向左转一下" learns LEFT
// (RIGHT = opposite yaw sign). Nothing counts before BOTH
// calibrations complete; restart re-runs both. GREEN round: TTS
// "绿灯，向左转" (or the cued direction); reaching the cued
// direction past ~27 deg within 4 seconds = pass (+1, "通过");
// not reaching within 4 s = fail ("没赶上"). Turning the wrong
// way does NOT fail a green round at once — it simply does not
// count as reaching, and the 4-second clock still ends the round
// as a fail (documented choice: the spec's fail condition is the
// clock, not the wrong turn). RED round: TTS "红灯，别动";
// surviving 3 seconds with total angular change under 5 deg from
// the round-start reference (G07's metric, quaternion angle)
// = pass (+1, "稳住了"); moving to 5 deg or beyond at ANY point
// during the 3 s = fail at once ("动了") — unlike G07 there is
// NO 0.3 s grace on red, because the whole point of red is
// freezing instantly. After every GREEN round the player MUST
// return to center (<10 deg on BOTH axes) before the next round:
// if not returned within 4 seconds, TTS prompts "请回正" and the
// grace timer resets — the next round is NEVER announced until
// the return actually happens (G10/G13's stricter rule, NOT
// G09's advance-anyway grace). Red rounds end already at center
// (a passed red means the head never left it; a failed red ends
// the moment the head moved, and the return gate after a failed
// red is handled the same way as after green — see _finishRound:
// after ANY round except the last, the player returns to center
// before the next round, so a failed red's movement is always
// walked back first). The final round ends the game at once:
// there is no next round for a return to gate. The fixed light
// sequence is NOT random, so preview and device behaviour are
// reproducible: green-left, red, green-up, red, green-right,
// green-down, red, green-left, red, green-up (6 green, 4 red).
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a
// labeled DEMO stepper (calibration steps, then one tap per
// whole round as a pass, return collapsed) so the playing/done
// states can be previewed. On a real device with a sensor there
// is no DEMO path at all. DISPLAY NOTE: the glasses display is
// monochrome green, so the light is NOT distinguished by color:
// green = filled circle + the word 绿灯, red = hollow circle +
// the word 红灯. The words carry the meaning; the circles are
// decoration.
// -------------------------------------------------------------------

const TOTAL = 10;
const DIR_DEG = 27;       // direction reached: 25-30 deg (pitch or yaw)
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const GREEN_MS = 4000;    // green: reach within 4 s or fail
const RED_MS = 3000;      // red: survive 3 s still or fail
const STILL_DEG = 5;      // red stillness: total angular change < 5 deg
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED light sequence (not random). 6 green, 4 red.
const SEQ = [
  { light: 'green', dir: 'left' },
  { light: 'red', dir: null },
  { light: 'green', dir: 'up' },
  { light: 'red', dir: null },
  { light: 'green', dir: 'right' },
  { light: 'green', dir: 'down' },
  { light: 'red', dir: null },
  { light: 'green', dir: 'left' },
  { light: 'red', dir: null },
  { light: 'green', dir: 'up' }
];

export default {
  data: {
    light: '● ○',
    big: '准备',
    countLine: '通过 0 / 10',
    hint: '单击开始 · 绿灯转，红灯停',
    safety: '红绿灯不转圈：绿灯只报一个方向，慢慢转过去，4 秒内转到算通过；红灯就别动，稳住 3 秒算通过，动了立刻算没通过。绿灯过后要回正到中间，下一轮才报。绝不从一边直接扫到另一边，绝不快速甩动，绝不绿红之间来回闪。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | greenWait | redHold | returning
    this._sub = 'greenWait';
    this._round = 0;
    this._score = 0;
    this._sensor = null;
    this._quat = null;     // latest [x, y, z, w]
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
    this._refQuat = null;  // red round-start reference quaternion
    this._greenSince = 0;
    this._redSince = 0;
    this._redAccum = 0;
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
  // Pitch from the orientation quaternion, fleet-consistent:
  // pitch = asin(2*(w*x - y*z)), clamped.
  // Yaw from the same quaternion:
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Only the RELATIVE pitch/yaw vs the calibrated center are ever
  // used, so the host's absolute zero never matters. The red-round
  // stillness metric additionally uses the raw quaternion angle
  // (G07's metric): angle = 2*acos(|dot(q, qRef)|), in degrees.
  //
  // SIGN LEARNING — learned, not assumed (two prompts, both inside
  // the playing state, G05's pattern): at round start the game
  // asks "请低一下头" and records the sign the head actually
  // moves as DOWN; UP is the opposite pitch sign. It then asks
  // "请向左转一下" and records the sign the head actually moves
  // as LEFT; RIGHT is the opposite yaw sign. A host whose pitch
  // or yaw sign is inverted therefore still counts down as down,
  // up as up, left as left, right as right. Residual caveats,
  // documented in AGENTS.md and on the device-test checklist:
  // calibration trusts the player to follow each prompt —
  // looking up instead of down, or turning right instead of
  // left, would learn that axis backwards. The fail-safes are
  // that nothing counts before BOTH calibrations complete, and
  // any restart re-runs both prompts. No fallback sign is ever
  // guessed.
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
  // return), so later rounds are judged from where "straight" is now.
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },
  // Total angular deviation in degrees vs the red round-start
  // reference quaternion (G07's metric). Null before a reference
  // is captured or before any reading.
  _deviationDeg() {
    if (!this._hasReading || !this._quat || !this._refQuat) return null;
    let dot = 0;
    for (let i = 0; i < 4; i++) dot += this._quat[i] * this._refQuat[i];
    if (dot < 0) dot = -dot;
    if (dot > 1) dot = 1;
    return 2 * Math.acos(dot) * 180 / Math.PI;
  },

  _roundDef() { return SEQ[this._round]; },
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
  // True when the head is past threshold in the given direction.
  _past(dir, downPitch, leftYaw) {
    if (dir === 'up') return downPitch <= -DIR_DEG;
    if (dir === 'down') return downPitch >= DIR_DEG;
    if (dir === 'left') return leftYaw >= DIR_DEG;
    return leftYaw <= -DIR_DEG;
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

  // NOTE: no head-gesture handler, deliberately. The gesture API is
  // officially documented ONLY for 'nod', and nod is not this
  // game's action — directions and stillness come from the sensor.

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
    // Recalibrate: head straight NOW is the center for this game;
    // both signs are then learned by the two calibration prompts.
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerSet = true;
    this._round = 0;
    this._score = 0;
    this._downSign = null;
    this._leftSign = null;
    this._sub = 'calibDownTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始玩红绿灯。绿灯报一个方向，慢慢转过去，4 秒内转到算通过；红灯就别动，稳住 3 秒算通过，动了立刻算没通过。绿灯过后要回正，下一轮才报。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: game started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _announceRound() {
    const def = this._roundDef();
    if (def.light === 'green') {
      this._sub = 'greenWait';
      this._greenSince = Date.now();
      let text = '绿灯，向' + this._dirWord(def.dir) + '转';
      if (def.dir === 'up') text += '，只到轻微拉伸，不要用力往后仰';
      this._speak(text);
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + '/' + TOTAL + ' GREEN ' + def.dir });
    } else {
      this._sub = 'redHold';
      this._redSince = Date.now();
      this._redAccum = 0;
      // Capture the stillness reference NOW: the head is at center
      // (return gate after the previous round), so this quaternion
      // is what "did not move" is judged against.
      this._refQuat = this._quat ? [this._quat[0], this._quat[1], this._quat[2], this._quat[3]] : null;
      this._speak('红灯，别动');
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + '/' + TOTAL + ' RED hold 3 s' });
    }
    this._render();
  },

  // Finish one round. Pass adds 1. After every round except the
  // last, the player must return to center before the next round
  // is announced (green rounds end turned; red rounds end at
  // center or just-moved, so the gate walks any movement back).
  // The final round ends the game at once: there is no next round
  // for a return to gate.
  _finishRound(pass) {
    if (pass) {
      this._score++;
      this._speak(this._sub === 'redHold' ? '稳住了' : '通过');
    } else {
      this._speak(this._sub === 'redHold' ? '动了' : '没赶上');
    }
    if (this._round >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE passed ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' ' + (pass ? 'pass' : 'fail') + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _nextRound() {
    this._round++;
    this._announceRound();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real pass. One
  // tap per calibration step, then one tap per whole round as a
  // pass (turn + return collapsed) so the playing/done states can
  // be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibDownTurn') {
      this._downSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibDownReturn';
      this.setData({ foot: 'EVT: DEMO down-calibration tilt (sensor SKIP)' });
    } else if (this._sub === 'calibDownReturn') {
      this._sub = 'calibLeftTurn';
      this.setData({ foot: 'EVT: DEMO down-calibration return (sensor SKIP)' });
    } else if (this._sub === 'calibLeftTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibLeftReturn';
      this.setData({ foot: 'EVT: DEMO left-calibration tilt (sensor SKIP)' });
    } else if (this._sub === 'calibLeftReturn') {
      this._announceRound();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._round >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done passed ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._round++;
        this._announceRound();
        this.setData({ foot: 'EVT: DEMO passed round, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'calibDownTurn') return '请低一下头，慢慢低头，到微酸就停';
    if (this._sub === 'calibDownReturn') return '回正到中间';
    if (this._sub === 'calibLeftTurn') return '请向左转一下，慢慢向左转';
    if (this._sub === 'calibLeftReturn') return '回正到中间';
    if (this._sub === 'redHold') return '红灯，别动';
    if (this._sub === 'returning') return '回正到中间，下一轮等你回正';
    const def = this._roundDef();
    return '绿灯，向' + this._dirWord(def.dir) + '转';
  },

  // ---- tick: the round state machine ---------------------------------
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
    if (relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives rounds
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
        this._announceRound();
        this.setData({ foot: 'EVT: calibration complete, first round announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: left calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- rounds: downPitch positive-down, leftYaw positive-left ------
    const dp = this._downPitch();
    const ly = this._leftYaw();
    if (dp === null || ly === null) return;
    const def = this._roundDef();

    if (this._sub === 'greenWait') {
      if (this._past(def.dir, dp, ly)) {
        this._finishRound(true);
        return;
      }
      if (now - this._greenSince >= GREEN_MS) {
        this._finishRound(false);
        return;
      }
    } else if (this._sub === 'redHold') {
      const dev = this._deviationDeg();
      if (dev !== null && dev >= STILL_DEG) {
        // Moved: fail at once, no grace — freezing instantly is the
        // whole point of red.
        this._finishRound(false);
        return;
      }
      // Still: accumulate only while steady where the host reports
      // stability; if the host never reports stability, elapsed
      // time alone gates the hold (documented fallback).
      const steadyOk = !this._stableSeen || this._stable;
      if (steadyOk) this._redAccum += TICK_MS;
      if (this._redAccum >= RED_MS) {
        this._finishRound(true);
        return;
      }
    } else if (this._sub === 'returning') {
      if (this._atCenter(relPitch, relYaw)) {
        this._nextRound();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        // Grace expired: TTS prompts "请回正" and the timer resets.
        // Nothing is counted by the grace, and the next round is NOT
        // announced until the return actually happens.
        this._speak('请回正，下一轮等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next round still gated on return' });
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let light, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      light = '● ○';
      big = '准备';
      hint = '单击开始 · 绿灯转，红灯停';
      safety = '红绿灯不转圈：绿灯只报一个方向，慢慢转过去，4 秒内转到算通过；红灯就别动，稳住 3 秒算通过，动了立刻算没通过。绿灯过后要回正到中间，下一轮才报。绝不从一边直接扫到另一边，绝不快速甩动，绝不绿红之间来回闪。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      light = '·';
      big = this._demoUsed ? '演示通过 ' + this._score + ' / 10' : '通过 ' + this._score + ' / 10';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibDownTurn') {
        light = '·';
        big = '请低一下头';
        hint = '只校准第一步：慢慢低头，到微酸就停';
        mainBtn = demo ? '演示低一下头' : '朗读';
      } else if (this._sub === 'calibDownReturn') {
        light = '·';
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'calibLeftTurn') {
        light = '·';
        big = '请向左转一下';
        hint = '只校准第二步：慢慢向左转';
        mainBtn = demo ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibLeftReturn') {
        light = '·';
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'redHold') {
        light = '○ 红灯';
        big = '红灯 · 别动';
        hint = '稳住 3 秒 · 动了立刻算没通过';
        mainBtn = demo ? '演示稳住通过' : '朗读';
      } else if (this._sub === 'returning') {
        light = '·';
        big = '回正到中间';
        hint = '本轮已报完 · 慢慢贴回正前方，下一轮等你回正';
        mainBtn = demo ? '演示通过一轮' : '朗读';
      } else {
        const def = this._roundDef();
        light = '● 绿灯';
        big = '绿灯 · 向' + this._dirWord(def.dir) + '转';
        hint = '慢慢转过去 · 4 秒内转到算通过 → 回正';
        mainBtn = demo ? '演示通过一轮' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [light, big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      light: light,
      big: big,
      countLine: '通过 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">红绿灯 TRAFFIC LIGHT</div>
    <div class="light">{{ light }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">绿灯转一个方向 · 红灯别动 · 绿灯过后要回正 · 痛晕立刻停</div>
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
.light {
  color: #40ff5e;
  font-size: 44px;
  font-weight: bold;
  line-height: 50px;
  text-align: center;
  margin-top: 2px;
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
