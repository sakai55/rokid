<script def>
{
  "title": "Follow Dot"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Follow Dot （追光点） — head-movement mini-game GA10, Group B
// (head-as-controller). EXTREME simplicity: one page, three states
// only (ready / playing / done). 10 dots, one at a time: a dot
// appears at ONE of four positions (up / down / left / right of
// center), announced by voice ("光点在左"); turn the head to it
// and hold ~0.8 s = hit (+1, "跟到了"), the dot disappears; then
// return to center before the next dot appears. Voice (TTS) does
// the rest. No menus, no settings, no levels, no camera, no mic/
// ASR, no storage, no network.
//
// DISTINCT FROM GA05: GA05 follows VOICE cues for clock positions;
// this game follows a VISUAL dot — the dot's position on screen
// is the cue, and the voice only names it.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one position -> hold -> return to center -> next dot.
// The dot NEVER moves continuously and NEVER traces a circle: it
// jumps discretely between 4 positions, disappears on a hit, and
// the next dot only appears after the player returns to center.
// Never sweep from one extreme to another, never fast jerking.
// Slow, small range, stop at mild stretch, never pain. For UP
// specifically: only to a mild stretch, NEVER hyperextend, NEVER
// throw the head back. Stop at once on pain / dizziness /
// numbness / nausea. Sit or stand steady first. One round is 10
// dots, short. This is entertainment / daily activity, NOT
// medical diagnosis, treatment or a rehab prescription; people
// with cervical disease, vertigo, post-op or head/neck injury
// history should ask a doctor first.
//
// HOW A DOT IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then TWO
// calibration prompts inside the playing state (not extra states),
// GA05's dual-axis pattern: (1) "请低一下头" learns DOWN (UP =
// opposite pitch sign); (2) "请向左转一下" learns LEFT (RIGHT =
// opposite yaw sign). Nothing counts before BOTH calibrations
// complete; restart re-runs both. Per dot: dot appears, player
// turns to it and holds ~0.8 s = hit (+1, "跟到了"); turning to a
// WRONG position past threshold = miss at once ("不是这个方向");
// no correct position within 4 seconds = miss ("没跟到"). After
// every dot (hit or miss) the player MUST return to center (<10
// deg on BOTH axes) before the next dot appears: if not returned
// within 4 seconds, TTS prompts "请回正" and the grace timer
// resets — the grace counts nothing and the next dot NEVER
// appears until the return actually happens (this differs from
// GA09's advance-anyway grace, deliberately: the return rule is
// what keeps this game segmented, not a sweep). The fixed dot
// sequence is NOT random, so preview and device behaviour are
// reproducible: left, up, left, down, right, up, down, right,
// left, up. It contains NO clockwise adjacent step at all (no
// up->right, right->down, down->left or left->up step), so no
// clockwise run can arise. Sensor missing (web preview) =
// SKIP/demo state, never a fake pass: the screen says so, and
// the main button becomes a labeled DEMO stepper (calibration
// steps, then one tap per whole dot as a hit, return collapsed)
// so the playing/done states can be previewed. On a real device
// with a sensor there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 10;
const DIR_DEG = 27;       // position reached: 25-30 deg (pitch or yaw)
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const HOLD_MS = 800;      // hold-steady ~0.8 s
const DOT_MS = 4000;      // no correct position within 4 s = miss
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED dot sequence (not random). Zero clockwise adjacent steps:
// left, up, left, down, right, up, down, right, left, up.
const SEQ = ['left', 'up', 'left', 'down', 'right', 'up', 'down', 'right', 'left', 'up'];

export default {
  data: {
    big: '准备',
    dotTop: '·',
    dotL: '·',
    dotR: '·',
    dotBot: '·',
    countLine: '跟到 0 / 10',
    hint: '单击开始 · 追 10 个光点，不转圈',
    safety: '光点不转圈：每次只出现一个点，慢慢转头跟上，停 0.8 秒，点消失，再回正到中间，下一个点才出现。点从不连续移动、从不画圈。慢、小幅度、到微酸即止；上点只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | wait | atTarget | returning
    this._sub = 'wait';
    this._dot = 0;
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
    this._dotSince = 0;
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
  // that nothing counts before BOTH calibrations complete, the
  // first dot is left and the second is up, so a backwards
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
  // return), so later dots are judged from where "straight" is now.
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _dotPos() { return SEQ[this._dot]; },
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
  // dot positions come from the sensor, never from a gesture event.

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
    this._dot = 0;
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
    this._speak('头摆正，开始追光点。光点不转圈：每次只出现一个点，慢慢转头跟上，停住，点消失，再回正，下一个点才出现。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _announceDot() {
    this._sub = 'wait';
    this._dotSince = Date.now();
    this._holdAccum = 0;
    const pos = this._dotPos();
    let text = '光点在' + this._dirWord(pos);
    if (pos === 'up') text += '，只到轻微拉伸，不要用力往后仰';
    this._speak(text);
    this.setData({ foot: 'EVT: dot ' + (this._dot + 1) + '/' + TOTAL + ' at ' + pos });
    this._render();
  },

  // Finish one dot. Hit adds 1; wrong-direction and timeout misses
  // add 0. After every dot the player must return to center before
  // the next dot appears (see _tick 'returning'). The final dot
  // ends the game at once: there is no next dot for a return to gate.
  _finishDot(result) {
    if (result === 'hit') {
      this._score++;
      this._speak('跟到了');
    } else if (result === 'wrong') {
      this._speak('不是这个方向');
    } else {
      this._speak('没跟到');
    }
    if (this._dot >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE hits ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: dot ' + (this._dot + 1) + ' ' + result + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _nextDot() {
    this._dot++;
    this._announceDot();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real hit. One
  // tap per calibration step, then one tap per whole dot as a hit
  // (turn + hold + return collapsed) so the playing/done states
  // can be previewed.
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
      this._announceDot();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._dot >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done hits ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._dot++;
        this._announceDot();
        this.setData({ foot: 'EVT: DEMO hit dot, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'returning') return '回正到中间，下一个点等你回正';
    const pos = this._dotPos();
    return '光点在' + this._dirWord(pos);
  },

  // ---- tick: the dot state machine -----------------------------------
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
    if (relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives dots
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
        this._announceDot();
        this.setData({ foot: 'EVT: calibration complete, first dot announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: left calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- dots: downPitch positive-down, leftYaw positive-left --------
    const dp = this._downPitch();
    const ly = this._leftYaw();
    if (dp === null || ly === null) return;
    const pos = this._dotPos();

    if (this._sub === 'wait') {
      if (this._past(pos, dp, ly)) {
        this._sub = 'atTarget';
        this._holdAccum = 0;
        this._speak(pos === 'up' ? '稳住，只到轻微拉伸，不要用力往后仰' : '稳住');
        this.setData({ foot: 'EVT: dot ' + (this._dot + 1) + ' reached ' + pos + ' past ' + DIR_DEG + ' deg, hold started' });
      } else if (this._otherPast(pos, dp, ly)) {
        // Wrong position past threshold: miss at once, no hold-or-undo.
        this._finishDot('wrong');
        return;
      } else if (now - this._dotSince >= DOT_MS) {
        this._finishDot('miss');
        return;
      }
    } else if (this._sub === 'atTarget') {
      if (!this._past(pos, dp, ly) && this._mag(pos, dp, ly) < DIR_DEG - 5) {
        // Released before the ~0.8 s hold: aborted, no count; the
        // 4-second dot clock keeps running.
        this._sub = 'wait';
        this._speak('没稳住，重新来，慢一点');
        this.setData({ foot: 'EVT: dot released before full hold, no count' });
      } else if (this._past(pos, dp, ly)) {
        // Hold accumulates only while steady where the host reports
        // stability; if the host never reports stability, elapsed
        // time alone gates the hold (documented fallback).
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) this._holdAccum += TICK_MS;
        if (this._holdAccum >= HOLD_MS) {
          this._finishDot('hit');
          return;
        }
      }
      if (this._sub === 'atTarget' && now - this._dotSince >= DOT_MS) {
        // Clock ran out mid-hold: miss, not a late hit.
        this._finishDot('miss');
        return;
      }
    } else if (this._sub === 'returning') {
      if (this._atCenter(relPitch, relYaw)) {
        this._nextDot();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        // Grace expired: TTS prompts "请回正" and the timer resets.
        // Nothing is counted by the grace, and the next dot is NOT
        // announced until the return actually happens.
        this._speak('请回正，下一个点等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next dot still gated on return' });
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, hint, safety, sensorLine, mainBtn;
    let dotTop = '·', dotL = '·', dotR = '·', dotBot = '·';
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      big = '准备';
      hint = '单击开始 · 追 10 个光点，不转圈';
      safety = '光点不转圈：每次只出现一个点，慢慢转头跟上，停 0.8 秒，点消失，再回正到中间，下一个点才出现。点从不连续移动、从不画圈。慢、小幅度、到微酸即止；上点只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示跟到 ' + this._score + ' / 10' : '跟到 ' + this._score + ' / 10';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下左右）';
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
      } else if (this._sub === 'atTarget') {
        const pos = this._dotPos();
        big = '稳住… 光点在' + this._dirWord(pos);
        hint = '保持这个方向，停 0.8 秒';
        mainBtn = demo ? '演示跟到一次' : '朗读';
        if (pos === 'up') dotTop = '●';
        else if (pos === 'down') dotBot = '●';
        else if (pos === 'left') dotL = '●';
        else dotR = '●';
      } else if (this._sub === 'returning') {
        big = '回正到中间';
        hint = '点已消失 · 慢慢贴回正前方，下一个点等你回正';
        mainBtn = demo ? '演示跟到一次' : '朗读';
      } else {
        const pos = this._dotPos();
        big = '光点在' + this._dirWord(pos);
        hint = '慢慢转头跟上 · 停 0.8 秒 → 点消失 → 回正';
        mainBtn = demo ? '演示跟到一次' : '朗读';
        if (pos === 'up') dotTop = '●';
        else if (pos === 'down') dotBot = '●';
        else if (pos === 'left') dotL = '●';
        else dotR = '●';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn, dotTop, dotL, dotR, dotBot].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      dotTop: dotTop,
      dotL: dotL,
      dotR: dotR,
      dotBot: dotBot,
      countLine: '跟到 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">追光点 FOLLOW DOT</div>
    <div class="dotgrid">
      <div class="dotrow dotcenter">{{ dotTop }}</div>
      <div class="dotrow dotmid"><span>{{ dotL }}</span><span class="dotmidmark">＋</span><span>{{ dotR }}</span></div>
      <div class="dotrow dotcenter">{{ dotBot }}</div>
    </div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">光点不转圈 · 跟上要回正 · 不用力往后仰 · 痛晕立刻停</div>
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
.dotgrid {
  margin-top: 4px;
}
.dotrow {
  color: #40ff5e;
  font-size: 22px;
  font-weight: bold;
  line-height: 24px;
  text-align: center;
}
.dotmid {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  padding: 0 60px;
}
.dotmidmark {
  color: rgba(64, 255, 94, 0.45);
  font-size: 16px;
}
.big {
  color: #ffffff;
  font-size: 36px;
  font-weight: bold;
  line-height: 42px;
  margin-top: 4px;
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
