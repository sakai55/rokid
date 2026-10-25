<script def>
{
  "title": "Guess Direction"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Guess Direction （猜方向） — head-movement mini-game GA18, opening
// Group D (fun finale). EXTREME simplicity: one page, three states
// only (ready / playing / done). 5 rounds, one at a time: the
// secret direction is NEVER shown on screen — TTS only reports
// how far away it is ("还远 / 近了 / 很近了 / 到了附近，停稳"),
// the player slowly moves the head toward it, and holding steady
// ~0.8 s within 12 deg of it = found (+1, the secret is then
// revealed by voice). Then return to center before the next
// round. Voice (TTS) does the rest. No menus, no settings, no
// levels, no camera, no mic/ASR, no storage, no network.
//
// DISTINCT FROM GA13: GA13 NAMES the direction ("请看向左") and the
// screen shows the same arrow. This game names NOTHING: the only
// feedback is distance, so the player must search. Distinct from
// GA05: GA05 follows clock-position cues in sequence; here the
// sequence is secret, and distance — not a cue — is the guide.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only slow, segmented
// searching: move slowly toward the hidden direction, stop,
// return to center between rounds — never a sweep, never a
// circle, never fast jerking. Slow, small range, stop at mild
// stretch, never pain. For UP specifically: only to a mild
// stretch, NEVER hyperextend, NEVER throw the head back. Stop at
// once on pain / dizziness / numbness / nausea. Sit or stand
// steady first. One game is 5 rounds, short. This is
// entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// HOW A ROUND IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then TWO
// calibration prompts inside the playing state (not extra states),
// GA05's dual-axis pattern: (1) "请低一下头" learns DOWN (UP =
// opposite pitch sign); (2) "请向左转一下" learns LEFT (RIGHT =
// opposite yaw sign). Nothing counts before BOTH calibrations
// complete; restart re-runs both. Per round: TTS says only "第 x
// 轮，猜猜看是哪个方向" — the secret is never named or shown
// until the round ends. Distance from the current head direction
// to the secret direction is sqrt(dYaw^2 + dPitch^2) in degrees,
// where the secret direction is 27 deg along its axis. Bands:
// <=12 deg = "到了附近，停稳" (also shown on screen); <=25 deg =
// "很近了"; <=45 deg = "近了"; >45 deg = "还远". A new hint is
// spoken ONLY when the band changes — the same hint is never
// repeated. Head within <=12 deg AND held steady ~0.8 s = found
// (+1, voice reveals the secret: "猜对了，是向左"). No find
// within 20 seconds = miss (voice reveals the secret: "时间到，
// 是向左"). After every round (found or miss) the player MUST
// return to center (<10 deg on BOTH axes) before the next round:
// if not returned within 4 seconds, TTS prompts "请回正" and the
// grace timer resets — the grace counts nothing and the next
// round is NEVER announced until the return actually happens
// (GA10/GA13's stricter rule, NOT GA09's advance-anyway grace).
// The final round ends the game at once: there is no next round
// for a return to gate. The fixed secret sequence is NOT random,
// so preview and device behaviour are reproducible: left, down,
// right, up, right. Rounds are separated by a return to center,
// so no circling arises from the sequence regardless of its
// order. Sensor missing (web preview) = SKIP/demo state, never a
// fake pass: the screen says so, and the main button becomes a
// labeled DEMO stepper (calibration steps, then one tap per
// whole round as a find, return collapsed) so the playing/done
// states can be previewed. On a real device with a sensor there
// is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 5;
const SECRET_DEG = 27;    // secret direction: 27 deg along its axis
const NEAR_DEG = 12;      // <=12 deg = "到了附近，停稳" + hold zone
const VERY_NEAR_DEG = 25; // <=25 deg = "很近了"
const CLOSE_DEG = 45;     // <=45 deg = "近了"; above = "还远"
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const HOLD_MS = 800;      // hold-steady ~0.8 s inside the near band
const ROUND_MS = 20000;   // no find within 20 s = miss
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED secret sequence (not random). Never shown on screen;
// revealed by voice only when the round ends. Left, down, right,
// up, right — rounds are separated by a return to center, so no
// circling arises from the sequence.
const SEQ = ['left', 'down', 'right', 'up', 'right'];

export default {
  data: {
    arrow: '?',
    big: '准备',
    countLine: '猜对 0 / 5',
    hint: '单击开始 · 猜 5 个方向，不转圈',
    safety: '猜方向不转圈：秘密方向不显示、不报名字，只报远近——慢慢转头找，听到「到了附近，停稳」就停住 0.8 秒，报「猜对了」，再回正到中间，下一轮才报。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | guessing | returning
    this._sub = 'guessing';
    this._round = 0;
    this._score = 0;
    this._sensor = null;
    this._pitch = null;
    this._yaw = null;
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._downSign = null;
    this._leftSign = null;
    this._holdAccum = 0;
    this._roundSince = 0;
    this._returnSince = 0;
    this._stallSince = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._band = null; // 'far' | 'close' | 'veryNear' | 'near'
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
  // Pitch from the orientation quaternion, same formula as GA01/GA04
  // (fleet-consistent): pitch = asin(2*(w*x - y*z)), clamped.
  // Yaw from the same quaternion, same formula as GA02:
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Only the RELATIVE pitch/yaw vs the calibrated center are ever
  // used, so the host's absolute zero never matters.
  //
  // SIGN LEARNING — learned, not assumed (two prompts, both inside
  // the playing state, GA05's pattern): at round start the game
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

  _secretDir() { return SEQ[this._round]; },
  _dirWord(dir) {
    if (dir === 'up') return '上';
    if (dir === 'down') return '下';
    if (dir === 'left') return '左';
    return '右';
  },
  // Secret direction as a (downPitch, leftYaw) point: 27 deg along
  // its own axis, 0 on the other axis.
  _secretPoint(dir) {
    if (dir === 'up') return [-SECRET_DEG, 0];
    if (dir === 'down') return [SECRET_DEG, 0];
    if (dir === 'left') return [0, SECRET_DEG];
    return [0, -SECRET_DEG];
  },
  // Angular distance (deg) from the current head direction to the
  // secret direction: sqrt(dYaw^2 + dPitch^2) in the
  // down-positive / left-positive plane.
  _distance(dir, downPitch, leftYaw) {
    const p = this._secretPoint(dir);
    const dP = downPitch - p[0];
    const dY = leftYaw - p[1];
    return Math.sqrt(dP * dP + dY * dY);
  },
  _bandFor(dist) {
    if (dist <= NEAR_DEG) return 'near';
    if (dist <= VERY_NEAR_DEG) return 'veryNear';
    if (dist <= CLOSE_DEG) return 'close';
    return 'far';
  },
  _bandWord(band) {
    if (band === 'near') return '到了附近，停稳';
    if (band === 'veryNear') return '很近了';
    if (band === 'close') return '近了';
    return '还远';
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
  _beginGame() {
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
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._band = null;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始猜方向。猜方向不转圈：秘密方向不显示、不报名字，只报远近——慢慢转头找，听到到了附近就停稳，再回正，下一轮才报。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: game started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _announceRound() {
    this._sub = 'guessing';
    this._roundSince = Date.now();
    this._holdAccum = 0;
    // At center the head is SECRET_DEG (27 deg) from any secret, so
    // the opening band is 'close' （近了） — never 'far' at start.
    this._band = 'close';
    this._speak('第 ' + (this._round + 1) + ' 轮，猜猜看是哪个方向');
    this.setData({ foot: 'EVT: round ' + (this._round + 1) + '/' + TOTAL + ' announced, secret hidden' });
    this._render();
  },

  // Finish one round. Found adds 1; timeout miss adds 0. The secret
  // is revealed by voice ONLY here, at the end of the round. After
  // every round the player must return to center before the next
  // round appears (see _tick 'returning'). The final round ends
  // the game at once: there is no next round for a return to gate.
  _finishRound(result) {
    const word = this._dirWord(this._secretDir());
    if (result === 'found') {
      this._score++;
      this._speak('猜对了，是向' + word);
    } else {
      this._speak('时间到，是向' + word);
    }
    if (this._round >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE found ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' ' + result + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _nextRound() {
    this._round++;
    this._announceRound();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real find. One
  // tap per calibration step, then one tap per whole round as a
  // find (search + hold + return collapsed) so the playing/done
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
      this._announceRound();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._round >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done found ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._round++;
        this._announceRound();
        this.setData({ foot: 'EVT: DEMO found round, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      }
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginGame(); return; }
    if (this._phase === 'done') { this._beginGame(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoStep(); return; }
    this._speak(this._currentInstruction());
  },

  _currentInstruction() {
    if (this._sub === 'calibDownTurn') return '请低一下头，慢慢低头，到微酸就停';
    if (this._sub === 'calibDownReturn') return '回正到中间';
    if (this._sub === 'calibLeftTurn') return '请向左转一下，慢慢向左转';
    if (this._sub === 'calibLeftReturn') return '回正到中间';
    if (this._sub === 'returning') return '回正到中间，下一轮等你回正';
    return '第 ' + (this._round + 1) + ' 轮，猜猜看是哪个方向，慢慢找，停稳';
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
      if (Math.abs(relPitch) >= SECRET_DEG) {
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
      if (Math.abs(relYaw) >= SECRET_DEG) {
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

    // --- returning: next round is gated on a real return ------------
    if (this._sub === 'returning') {
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
      this._render();
      return;
    }

    // --- guessing: distance bands + hold ------------------------------
    const dp = this._downPitch();
    const ly = this._leftYaw();
    if (dp === null || ly === null) return;
    const dir = this._secretDir();
    const dist = this._distance(dir, dp, ly);
    const band = this._bandFor(dist);
    // A new hint is spoken ONLY when the band changes.
    if (band !== this._band) {
      this._band = band;
      this._speak(this._bandWord(band));
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' band ' + band + ' dist ' + dist.toFixed(1) + ' deg' });
    }
    if (band === 'near') {
      // Hold accumulates only while steady where the host reports
      // stability; if the host never reports stability, elapsed
      // time alone gates the hold (documented fallback).
      const steadyOk = !this._stableSeen || this._stable;
      if (steadyOk) this._holdAccum += TICK_MS;
      if (this._holdAccum >= HOLD_MS) {
        this._finishRound('found');
        return;
      }
    } else {
      // Left the near band before the hold finished: no count, and
      // the hold restarts from zero if the player comes back.
      this._holdAccum = 0;
    }
    if (now - this._roundSince >= ROUND_MS) {
      // Clock ran out (even mid-hold): miss, not a late find.
      this._finishRound('miss');
      return;
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let arrow, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      arrow = '?';
      big = '准备';
      hint = '单击开始 · 猜 5 个方向，不转圈';
      safety = '猜方向不转圈：秘密方向不显示、不报名字，只报远近——慢慢转头找，听到「到了附近，停稳」就停住 0.8 秒，报「猜对了」，再回正到中间，下一轮才报。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '?';
      big = this._demoUsed ? '演示猜对 ' + this._score + ' / 5' : '猜对 ' + this._score + ' / 5';
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
      } else if (this._sub === 'returning') {
        arrow = '·';
        big = '回正到中间';
        hint = '本轮已报完 · 慢慢贴回正前方，下一轮等你回正';
        mainBtn = demo ? '演示猜对一次' : '朗读';
      } else {
        // guessing: the secret is NEVER shown — no arrow, no word.
        arrow = '?';
        big = this._band ? this._bandWord(this._band) : '猜猜看';
        hint = '慢慢找，停稳';
        mainBtn = demo ? '演示猜对一次' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [arrow, big, this._score + '/' + TOTAL, this._round, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      arrow: arrow,
      big: big,
      countLine: '第 ' + (this._round + 1) + ' / ' + TOTAL + ' 轮 · 猜对 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">猜方向 GUESS DIRECTION</div>
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
    <div class="foot2">秘密方向不显示 · 只报远近 · 猜对要回正 · 不用力往后仰 · 痛晕立刻停</div>
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
