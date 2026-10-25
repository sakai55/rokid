<script def>
{
  "title": "Find Target"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Find Target （找方向） — head-movement mini-game G13, opening
// Group C (observation/control: head-steady = confirm). EXTREME
// simplicity: one page, three states only (ready / playing /
// done). 8 trials, one at a time: a SINGLE voice cue per trial
// ("请看向左") and the screen shows the same direction arrow;
// turn to it and hold ~0.8 s = found (+1, "找到了"); then return
// to center before the next cue. Voice (TTS) does the rest. No
// menus, no settings, no levels, no camera, no mic/ASR, no
// storage, no network.
//
// DISTINCT FROM G05/G10/G12: G05 follows clock-position cues in
// sequence, G10 follows a VISUAL dot, G12 replays a sequence from
// memory. This game is a single voice cue per trial, confirmed by
// head-steady: the cue names ONE direction, the player finds it,
// holds steady, returns — nothing to follow, nothing to remember.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> hold -> return to center -> next
// trial. Never continuous circling, never sweep from one extreme
// to another, never fast jerking. Slow, small range, stop at mild
// stretch, never pain. For UP specifically: only to a mild
// stretch, NEVER hyperextend, NEVER throw the head back. Stop at
// once on pain / dizziness / numbness / nausea. Sit or stand
// steady first. One round set is 8 trials, short. This is
// entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// HOW A TRIAL IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then TWO
// calibration prompts inside the playing state (not extra states),
// G05's dual-axis pattern: (1) "请低一下头" learns DOWN (UP =
// opposite pitch sign); (2) "请向左转一下" learns LEFT (RIGHT =
// opposite yaw sign). Nothing counts before BOTH calibrations
// complete; restart re-runs both. Per trial: TTS cues one
// direction ("请看向左") and the screen shows the same arrow;
// player turns to it and holds ~0.8 s = found (+1, "找到了");
// turning to a WRONG direction past threshold = miss for that
// trial at once ("不是这个方向"); no correct direction within 4
// seconds = miss ("没找到"). After every trial (found or miss)
// the player MUST return to center (<10 deg on BOTH axes)
// before the next cue: if not returned within 4 seconds, TTS
// prompts "请回正" and the grace timer resets — the grace counts
// nothing and the next cue is NEVER announced until the return
// actually happens (G10's stricter rule, NOT G09's
// advance-anyway grace). The final trial ends the game at once:
// there is no next trial for a return to gate. The fixed cue
// sequence is NOT random, so preview and device behaviour are
// reproducible: left, down, right, up, right, left, up, down. It
// contains NO clockwise run of adjacent steps (no up->right->
// down, right->down->left, down->left->up or left->up->right
// triple), and every trial is separated by a return to center,
// so no circling arises in either direction. Sensor missing (web
// preview) = SKIP/demo state, never a fake pass: the screen says
// so, and the main button becomes a labeled DEMO stepper
// (calibration steps, then one tap per whole trial as a find,
// return collapsed) so the playing/done states can be previewed.
// On a real device with a sensor there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 8;
const DIR_DEG = 27;       // direction reached: 25-30 deg (pitch or yaw)
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const HOLD_MS = 800;      // hold-steady ~0.8 s
const TRIAL_MS = 4000;    // no correct direction within 4 s = miss
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED cue sequence (not random). No clockwise run of adjacent
// steps: left, down, right, up, right, left, up, down.
const SEQ = ['left', 'down', 'right', 'up', 'right', 'left', 'up', 'down'];

export default {
  data: {
    arrow: '·',
    big: '准备',
    countLine: '找到 0 / 8',
    hint: '单击开始 · 找 8 个方向，不转圈',
    safety: '找方向不转圈：每次只报一个方向，慢慢转头找到，停 0.8 秒，报「找到了」，再回正到中间，下一个方向才报。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | wait | atTarget | returning
    this._sub = 'wait';
    this._trial = 0;
    this._score = 0;
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
  // Pitch from the orientation quaternion, same formula as G01/G04
  // (fleet-consistent): pitch = asin(2*(w*x - y*z)), clamped.
  // Yaw from the same quaternion, same formula as G02:
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Only the RELATIVE pitch/yaw vs the calibrated center are ever
  // used, so the host's absolute zero never matters.
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
  // that nothing counts before BOTH calibrations complete, the
  // first cue is left and the second is down, so a backwards
  // calibration feels wrong at once, and any restart re-runs
  // both prompts. No fallback sign is ever guessed.
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
  // return), so later trials are judged from where "straight" is now.
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _cueDir() { return SEQ[this._trial]; },
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
  // directions come from the sensor, never from a gesture event.

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
    this._trial = 0;
    this._score = 0;
    this._downSign = null;
    this._leftSign = null;
    this._sub = 'calibDownTurn';
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始找方向。找方向不转圈：每次只报一个方向，慢慢转头找到，停住，报找到了，再回正，下一个方向才报。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _announceTrial() {
    this._sub = 'wait';
    this._trialSince = Date.now();
    this._holdAccum = 0;
    const dir = this._cueDir();
    let text = '请看向' + this._dirWord(dir);
    if (dir === 'up') text += '，只到轻微拉伸，不要用力往后仰';
    this._speak(text);
    this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + '/' + TOTAL + ' cue ' + dir });
    this._render();
  },

  // Finish one trial. Found adds 1; wrong-direction and timeout
  // misses add 0. After every trial the player must return to
  // center before the next cue appears (see _tick 'returning').
  // The final trial ends the game at once: there is no next trial
  // for a return to gate.
  _finishTrial(result) {
    if (result === 'found') {
      this._score++;
      this._speak('找到了');
    } else if (result === 'wrong') {
      this._speak('不是这个方向');
    } else {
      this._speak('没找到');
    }
    if (this._trial >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE found ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + ' ' + result + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _nextTrial() {
    this._trial++;
    this._announceTrial();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real find. One
  // tap per calibration step, then one tap per whole trial as a
  // find (turn + hold + return collapsed) so the playing/done
  // states can be previewed.
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
      this._announceTrial();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._trial >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done found ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._trial++;
        this._announceTrial();
        this.setData({ foot: 'EVT: DEMO found trial, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'atTarget') return '稳住';
    if (this._sub === 'returning') return '回正到中间，下一个方向等你回正';
    const dir = this._cueDir();
    return '请看向' + this._dirWord(dir);
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
    const relPitch = this._relPitch();
    const relYaw = this._relYaw();
    if (relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives trials
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
        this._announceTrial();
        this.setData({ foot: 'EVT: calibration complete, first trial announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: left calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- trials: downPitch positive-down, leftYaw positive-left ------
    const dp = this._downPitch();
    const ly = this._leftYaw();
    if (dp === null || ly === null) return;
    const dir = this._cueDir();

    if (this._sub === 'wait') {
      if (this._past(dir, dp, ly)) {
        this._sub = 'atTarget';
        this._holdAccum = 0;
        this._speak(dir === 'up' ? '稳住，只到轻微拉伸，不要用力往后仰' : '稳住');
        this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + ' reached ' + dir + ' past ' + DIR_DEG + ' deg, hold started' });
      } else if (this._otherPast(dir, dp, ly)) {
        // Wrong direction past threshold: miss at once, no hold-or-undo.
        this._finishTrial('wrong');
        return;
      } else if (now - this._trialSince >= TRIAL_MS) {
        this._finishTrial('miss');
        return;
      }
    } else if (this._sub === 'atTarget') {
      if (!this._past(dir, dp, ly) && this._mag(dir, dp, ly) < DIR_DEG - 5) {
        // Released before the ~0.8 s hold: aborted, no count; the
        // 4-second trial clock keeps running.
        this._sub = 'wait';
        this._speak('没稳住，重新来，慢一点');
        this.setData({ foot: 'EVT: trial released before full hold, no count' });
      } else if (this._past(dir, dp, ly)) {
        // Hold accumulates only while steady where the host reports
        // stability; if the host never reports stability, elapsed
        // time alone gates the hold (documented fallback).
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) this._holdAccum += TICK_MS;
        if (this._holdAccum >= HOLD_MS) {
          this._finishTrial('found');
          return;
        }
      }
      if (this._sub === 'atTarget' && now - this._trialSince >= TRIAL_MS) {
        // Clock ran out mid-hold: miss, not a late find.
        this._finishTrial('miss');
        return;
      }
    } else if (this._sub === 'returning') {
      if (this._atCenter(relPitch, relYaw)) {
        this._nextTrial();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        // Grace expired: TTS prompts "请回正" and the timer resets.
        // Nothing is counted by the grace, and the next cue is NOT
        // announced until the return actually happens.
        this._speak('请回正，下一个方向等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next trial still gated on return' });
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let arrow, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      arrow = '·';
      big = '准备';
      hint = '单击开始 · 找 8 个方向，不转圈';
      safety = '找方向不转圈：每次只报一个方向，慢慢转头找到，停 0.8 秒，报「找到了」，再回正到中间，下一个方向才报。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '·';
      big = this._demoUsed ? '演示找到 ' + this._score + ' / 8' : '找到 ' + this._score + ' / 8';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibDownTurn') {
        arrow = '↓';
        big = '请低一下头';
        hint = '只校准第一步：慢慢低头，到微酸就停';
        mainBtn = demo ? '演示低一下头' : '朗读';
      } else if (this._sub === 'calibDownReturn') {
        arrow = '·';
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'calibLeftTurn') {
        arrow = '←';
        big = '请向左转一下';
        hint = '只校准第二步：慢慢向左转';
        mainBtn = demo ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibLeftReturn') {
        arrow = '·';
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'atTarget') {
        const dir = this._cueDir();
        arrow = this._dirArrow(dir);
        big = '稳住… 请看向' + this._dirWord(dir);
        hint = '保持这个方向，停 0.8 秒';
        mainBtn = demo ? '演示找到一次' : '朗读';
      } else if (this._sub === 'returning') {
        arrow = '·';
        big = '回正到中间';
        hint = '方向已报完 · 慢慢贴回正前方，下一个方向等你回正';
        mainBtn = demo ? '演示找到一次' : '朗读';
      } else {
        const dir = this._cueDir();
        arrow = this._dirArrow(dir);
        big = '请看向' + this._dirWord(dir);
        hint = '慢慢转头找到 · 停 0.8 秒 → 找到了 → 回正';
        mainBtn = demo ? '演示找到一次' : '朗读';
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
      countLine: '找到 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">找方向 FIND TARGET</div>
    <div class="arrow">{{ arrow }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">一次只报一个方向 · 找到要回正 · 不用力往后仰 · 痛晕立刻停</div>
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
