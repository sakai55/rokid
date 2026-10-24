<script def>
{
  "title": "Memory Seq"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Memory Seq （方向记忆） — head-movement mini-game G12, Group B
// (head-as-controller), closing Group B. EXTREME simplicity: one
// page, three states only (ready / playing / done). Direction
// MEMORY, distinct from G05/G10: those follow cues in real time;
// here the player must REMEMBER a sequence after it is announced,
// with NO cue on screen during recall — the screen never shows a
// direction during announce or recall (only "听" / "做", the step
// within the round, and rounds won x/3). TTS does the rest.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> hold -> return to center -> next
// step. The sequence is NEVER performed as a continuous sweep or
// circle: every step is separated by a return to center, and the
// recall phase replays the sequence step by step with returns,
// exactly like the announcement phase. Never fast jerking. Slow,
// small range, stop at mild stretch, never pain; UP only to a
// mild stretch, NEVER hyperextend, NEVER throw the head back.
// Stop at once on pain / dizziness / numbness / nausea. Sit or
// stand steady first. One round set is 3 rounds, short. This is
// entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// HOW A ROUND IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then TWO
// calibration prompts inside the playing state (not extra states),
// G05's dual-axis pattern: (1) "请低一下头" learns DOWN (UP =
// opposite pitch sign); (2) "请向左转一下" learns LEFT (RIGHT =
// opposite yaw sign). Nothing counts before BOTH calibrations
// complete; restart re-runs both. Per round: ANNOUNCE phase —
// TTS speaks the directions one by one, 1 second apart, screen
// shows only "听" + round number (never the directions, otherwise
// it is not memory); then RECALL phase — TTS says "请按顺序做
// 出来", player performs each step (turn to the direction, hold
// ~0.8 s, return to center) in order; a correct step advances
// (voice "对"); a wrong direction past threshold ends the round
// as failed at once (voice "错了，这轮没过", no retry within the
// round); after a failed round, the player returns to center and
// the next round is announced. A round completed in full order =
// won (+1 round). No per-step timeout beyond a stall re-prompt:
// if the player stalls 8 seconds on a recall step, TTS re-prompts
// the phase ("轮到你了，按顺序做") once, then keeps waiting —
// never auto-fails on stall alone. Fixed sequences (NOT random,
// so preview and device behaviour are reproducible):
// Round 1: left, up, right (3 steps);
// Round 2: down, left, down (3 steps — the repeat is allowed
// because each step is separated by a return);
// Round 3: right, down, left, up (4 steps).
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a labeled
// DEMO stepper (calibration steps, announce words, one tap per
// whole recall step as correct, return collapsed) so the playing
// and done states can be previewed. On a real device with a
// sensor there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL_ROUNDS = 3;
const DIR_DEG = 27;       // direction reached: 25-30 deg (pitch or yaw)
const CENTER_DEG = 10;    // return-to-center band: <10 deg on BOTH axes
const HOLD_MS = 800;      // hold-steady ~0.8 s per recalled step
const STALL_MS = 8000;    // stall -> one TTS re-prompt, never auto-fail
const ANNOUNCE_MS = 1000; // announce words 1 second apart
const TICK_MS = 100;
// FIXED round sequences (not random). Round 1: left, up, right.
// Round 2: down, left, down. Round 3: right, down, left, up.
const ROUNDS = [['left', 'up', 'right'], ['down', 'left', 'down'], ['right', 'down', 'left', 'up']];

export default {
  data: {
    big: '准备',
    countLine: '共 3 轮 · 先听后做',
    hint: '单击开始 · 记住方向顺序，不转圈',
    safety: '方向不转圈：先听一轮顺序，再按顺序一步一步做出来，每步只到一个方向，停 0.8 秒，回正到中间，下一步才开始。顺序从不连续扫动、从不画圈。慢、小幅度、到微酸即止；上只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibDownTurn | calibDownReturn | calibLeftTurn | calibLeftReturn
    // | announce | recallWait | recallHold | recallReturn | roundReturn
    this._sub = 'recallWait';
    this._round = 0;
    this._step = 0;
    this._won = 0;
    this._announceIdx = 0;
    this._announceNextAt = 0;
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
    this._recallSince = 0;
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

  // ---- orientation sensor (G05/G10 formulas, fleet-consistent) ------
  // Pitch = asin(2*(w*x - y*z)), clamped (G01/G04). Yaw =
  // atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees (G02).
  // Only the RELATIVE pitch/yaw vs the calibrated center are ever
  // used, so the host's absolute zero never matters.
  //
  // SIGN LEARNING — learned, not assumed (two prompts, both inside
  // the playing state, G05's pattern): "请低一下头" records the
  // sign the head actually moves as DOWN; UP is the opposite pitch
  // sign. "请向左转一下" records the sign the head actually moves
  // as LEFT; RIGHT is the opposite yaw sign. Residual caveats,
  // documented in AGENTS.md and on the device-test checklist:
  // calibration trusts the player to follow each prompt — looking
  // up instead of down, or turning right instead of left, would
  // learn that axis backwards. Fail-safes: nothing counts before
  // BOTH calibrations complete, the first announced direction is
  // left (round 1 step 1) and the second is up, so a backwards
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
  _atCenter(relPitch, relYaw) {
    return Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG;
  },
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _seq() { return ROUNDS[this._round]; },
  _stepDir() { return this._seq()[this._step]; },
  _dirWord(dir) {
    if (dir === 'up') return '上';
    if (dir === 'down') return '下';
    if (dir === 'left') return '左';
    return '右';
  },
  _past(dir, downPitch, leftYaw) {
    if (dir === 'up') return downPitch <= -DIR_DEG;
    if (dir === 'down') return downPitch >= DIR_DEG;
    if (dir === 'left') return leftYaw >= DIR_DEG;
    return leftYaw <= -DIR_DEG;
  },
  _mag(dir, downPitch, leftYaw) {
    if (dir === 'up' || dir === 'down') return Math.abs(downPitch);
    return Math.abs(leftYaw);
  },
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
    // Recalibrate: head straight NOW is the center for this set;
    // both signs are then learned by the two calibration prompts.
    // Same sequences every set, so behaviour is reproducible.
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerSet = true;
    this._round = 0;
    this._step = 0;
    this._won = 0;
    this._downSign = null;
    this._leftSign = null;
    this._sub = 'calibDownTurn';
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始方向记忆。先听顺序，再按顺序做出来，每步都要回正，不转圈。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: set started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  // ANNOUNCE phase: TTS speaks the round's directions one by one,
  // 1 second apart. The screen shows only "听" + round number —
  // never the directions, otherwise it is not memory.
  _startAnnounce() {
    this._sub = 'announce';
    this._announceIdx = 0;
    this._announceNextAt = Date.now() + ANNOUNCE_MS;
    this._speak('第' + (this._round + 1) + '轮，听好顺序');
    this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' announce started, ' + this._seq().length + ' steps' });
    this._render();
  },

  _beginRecall() {
    this._step = 0;
    this._sub = 'recallWait';
    this._recallSince = Date.now();
    this._reprompted = false;
    this._holdAccum = 0;
    this._speak('请按顺序做出来');
    this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' recall started' });
    this._render();
  },

  // A recalled step is correct only as reach -> hold ~0.8 s ->
  // return. Advancing the step speaks NOTHING about the next
  // direction — speaking it would give the memory away.
  _advanceStep() {
    if (this._step >= this._seq().length - 1) {
      this._won++;
      this._speak('这轮全对');
      if (this._round >= TOTAL_ROUNDS - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DONE won ' + this._won + '/' + TOTAL_ROUNDS });
      } else {
        this._round++;
        this._startAnnounce();
        this.setData({ foot: 'EVT: round won ' + this._won + '/' + TOTAL_ROUNDS + ', next round announced' });
      }
    } else {
      this._step++;
      this._sub = 'recallWait';
      this._recallSince = Date.now();
      this._reprompted = false;
      this._holdAccum = 0;
      this.setData({ foot: 'EVT: step correct, now step ' + (this._step + 1) + '/' + this._seq().length });
    }
    this._render();
  },

  // Wrong direction past threshold ends the round as failed at
  // once — no retry within the round. The player must return to
  // center before the next round is announced (except after the
  // last round, which ends the set at once).
  _failRound() {
    this._speak('错了，这轮没过');
    if (this._round >= TOTAL_ROUNDS - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE won ' + this._won + '/' + TOTAL_ROUNDS + ' (last round failed)' });
    } else {
      this._sub = 'roundReturn';
      this._returnSince = Date.now();
      this._reprompted = false;
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' failed, awaiting return to center' });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real win. One
  // tap per calibration step, one tap per announce word, then one
  // tap per whole recall step as correct (turn + hold + return
  // collapsed) so the playing/done states can be previewed.
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
      this._startAnnounce();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else if (this._sub === 'announce') {
      if (this._announceIdx < this._seq().length) {
        const dir = this._seq()[this._announceIdx];
        this._announceIdx++;
        this._speak(dir === 'up' ? '上，只到轻微拉伸，不要用力往后仰' : this._dirWord(dir));
        if (this._announceIdx >= this._seq().length) {
          this._beginRecall();
          this.setData({ foot: 'EVT: DEMO announce complete (sensor SKIP)' });
        } else {
          this.setData({ foot: 'EVT: DEMO announce word ' + this._announceIdx + '/' + this._seq().length + ' (sensor SKIP)' });
        }
      }
    } else if (this._sub === 'roundReturn') {
      this._round++;
      this._startAnnounce();
      this.setData({ foot: 'EVT: DEMO return after failed round (sensor SKIP)' });
    } else {
      // recallWait / recallHold / recallReturn: one tap = one correct step.
      this._speak('对');
      this._advanceStep();
      if (this._phase === 'playing') this.setData({ foot: 'EVT: DEMO correct step (sensor SKIP)' });
      else this.setData({ foot: 'EVT: DEMO done won ' + this._won + '/' + TOTAL_ROUNDS + ' (sensor SKIP)' });
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
    if (this._sub === 'announce') return '听顺序，屏幕不写方向';
    if (this._sub === 'recallHold') return '稳住';
    if (this._sub === 'recallReturn' || this._sub === 'roundReturn') return '回正到中间';
    return '轮到你了，按顺序做';
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
    if (relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives the game
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
        this._startAnnounce();
        this.setData({ foot: 'EVT: calibration complete, round 1 announce started' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: left calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- announce: one spoken word per second, screen shows only ----
    // "听" + round number — never the directions themselves.
    if (this._sub === 'announce') {
      if (now >= this._announceNextAt) {
        if (this._announceIdx < this._seq().length) {
          const dir = this._seq()[this._announceIdx];
          this._announceIdx++;
          this._speak(dir === 'up' ? '上，只到轻微拉伸，不要用力往后仰' : this._dirWord(dir));
          this._announceNextAt = now + ANNOUNCE_MS;
          this.setData({ foot: 'EVT: announce word ' + this._announceIdx + '/' + this._seq().length + ' (round ' + (this._round + 1) + ')' });
        } else {
          this._beginRecall();
        }
      }
      this._render();
      return;
    }

    // --- recall: downPitch positive-down, leftYaw positive-left -----
    const dp = this._downPitch();
    const ly = this._leftYaw();
    if (dp === null || ly === null) return;
    const dir = this._stepDir();

    if (this._sub === 'recallWait') {
      if (this._past(dir, dp, ly)) {
        this._sub = 'recallHold';
        this._holdAccum = 0;
        this._speak(dir === 'up' ? '稳住，只到轻微拉伸，不要用力往后仰' : '稳住');
        this.setData({ foot: 'EVT: recall step ' + (this._step + 1) + '/' + this._seq().length + ' reached, hold started' });
      } else if (this._otherPast(dir, dp, ly)) {
        // Wrong direction past threshold: round fails at once, no retry.
        this._failRound();
        return;
      } else if (!this._reprompted && now - this._recallSince >= STALL_MS) {
        // Stall: re-prompt ONCE, then keep waiting — never auto-fail.
        this._reprompted = true;
        this._speak('轮到你了，按顺序做');
        this.setData({ foot: 'EVT: recall step stalled, re-prompted once (no auto-fail)' });
      }
    } else if (this._sub === 'recallHold') {
      if (!this._past(dir, dp, ly) && this._mag(dir, dp, ly) < DIR_DEG - 5) {
        // Released before the ~0.8 s hold: aborted, no count, back to wait.
        this._sub = 'recallWait';
        this._speak('没稳住，重新来，慢一点');
        this.setData({ foot: 'EVT: recall step released before full hold, no count' });
      } else if (this._past(dir, dp, ly)) {
        // Hold accumulates only while steady where the host reports
        // stability; if the host never reports stability, elapsed
        // time alone gates the hold (documented fallback).
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) this._holdAccum += TICK_MS;
        if (this._holdAccum >= HOLD_MS) {
          this._speak('对');
          this._sub = 'recallReturn';
          this._returnSince = now;
          this._reprompted = false;
          this.setData({ foot: 'EVT: recall step held 0.8 s, awaiting return to center' });
        }
      }
    } else if (this._sub === 'recallReturn') {
      if (this._atCenter(relPitch, relYaw)) {
        this._advanceStep();
        return;
      }
      if (!this._reprompted && now - this._returnSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('回正到中间');
        this.setData({ foot: 'EVT: recall return stalled, re-prompted once (no auto-advance)' });
      }
    } else if (this._sub === 'roundReturn') {
      // After a failed round: next round is announced ONLY after
      // the player actually returns to center.
      if (this._atCenter(relPitch, relYaw)) {
        this._round++;
        this._startAnnounce();
        return;
      }
      if (!this._reprompted && now - this._returnSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('回正到中间，下一轮等你回正');
        this.setData({ foot: 'EVT: failed-round return stalled, re-prompted once (no auto-advance)' });
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  // The screen NEVER shows a direction during announce or recall:
  // only the phase ("听" / "做"), the step within the round, and
  // rounds won x/3. That is what makes it a memory game.
  _render() {
    let big, hint, safety, sensorLine, mainBtn, countLine;
    const demo = (this._sensorSkip || !this._hasReading);
    const roundNo = this._round + 1;
    const seqLen = this._seq().length;
    if (this._phase === 'ready') {
      big = '准备';
      countLine = '共 3 轮 · 先听后做';
      hint = '单击开始 · 记住方向顺序，不转圈';
      safety = '方向不转圈：先听一轮顺序，再按顺序一步一步做出来，每步只到一个方向，停 0.8 秒，回正到中间，下一步才开始。顺序从不连续扫动、从不画圈。慢、小幅度、到微酸即止；上只到轻微拉伸，绝不用力往后仰。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示赢了 ' + this._won + ' / 3' : '赢了 ' + this._won + ' / 3';
      countLine = '已过 ' + this._won + ' / 3 轮';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下左右，同一组顺序）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      countLine = '第' + roundNo + '轮 · 已过 ' + this._won + ' / 3 轮';
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
      } else if (this._sub === 'announce') {
        big = '听';
        hint = '第' + roundNo + '轮 · 记住 ' + seqLen + ' 个方向 · 屏幕不写方向';
        mainBtn = demo ? '演示报方向' : '朗读';
      } else if (this._sub === 'recallHold') {
        big = '做';
        hint = '第' + (this._step + 1) + '步 / ' + seqLen + '步 · 稳住 0.8 秒';
        mainBtn = demo ? '演示做对一步' : '朗读';
      } else if (this._sub === 'recallReturn') {
        big = '回正到中间';
        hint = '第' + (this._step + 1) + '步已对 · 慢慢贴回正前方';
        mainBtn = demo ? '演示做对一步' : '朗读';
      } else if (this._sub === 'roundReturn') {
        big = '回正到中间';
        hint = '这轮没过 · 回正后报下一轮';
        mainBtn = demo ? '演示回正' : '朗读';
      } else {
        big = '做';
        hint = '第' + (this._step + 1) + '步 / ' + seqLen + '步 · 按顺序做，停 0.8 秒，回正';
        mainBtn = demo ? '演示做对一步' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [big, countLine, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: countLine,
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
    <div class="title">方向记忆 MEMORY SEQ</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不转圈 · 每步都要回正 · 不用力往后仰 · 痛晕立刻停</div>
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
  font-size: 44px;
  font-weight: bold;
  line-height: 52px;
  margin-top: 14px;
  white-space: nowrap;
  overflow: hidden;
}
.count {
  color: #40ff5e;
  font-size: 28px;
  font-weight: bold;
  line-height: 32px;
  margin-top: 6px;
}
.hint {
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  line-height: 19px;
  margin-top: 4px;
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
  margin-top: 8px;
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
