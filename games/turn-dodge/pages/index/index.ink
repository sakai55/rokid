<script def>
{
  "title": "Turn Dodge"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Turn Dodge （左右闪避） — head-movement mini-game G09, Group B
// (head-as-controller). EXTREME simplicity: one page, three states
// only (ready / playing / done). 10 rounds, one obstacle at a time:
// the obstacle comes from ONE side, announced by voice and shown on
// screen; turn AWAY from it (obstacle left -> turn right, obstacle
// right -> turn left), hold ~0.8 s to dodge, then return to center
// before the next round is announced. Voice (TTS) does the rest.
// No menus, no settings, no levels, no camera, no mic/ASR, no
// storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> hold -> return to center -> next
// round. Never continuous circling, never sweep from one extreme
// to the other, never fast jerking — dodges are calm turns, not
// flinches. Slow, small range, stop at mild stretch, never pain.
// Stop at once on pain / dizziness / numbness / nausea. Sit or
// stand steady first. One round is 10 dodges, short. This is
// entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// HOW A ROUND IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt: "请向左转一下". Whichever yaw sign the head
// actually moves is learned as LEFT (G02's proven pattern), so a
// host yaw-sign inversion cannot silently swap left/right.
// Return to center, then the 10 rounds run in a FIXED sequence
// (not random, so preview and device behaviour are reproducible):
// obstacle sides L, R, R, L, R, L, L, R, L, R.
// Per round: obstacle on the LEFT means turn RIGHT (away from
// it), obstacle on the RIGHT means turn LEFT. Reaching the
// opposite direction past threshold and holding ~0.8 s = dodge
// (+1, "躲开了"). Turning TOWARD the obstacle past threshold =
// hit (0, "被撞到了"). No turn within 4 seconds = miss (0,
// "没躲开"). After each round the player MUST return to center
// before the next round is announced: the next round starts only
// after return <10 deg, or after a 4-second return grace, at
// which point the next round is announced anyway with a spoken
// "请回正" reminder (grace expiry, documented — the game never
// waits forever, and never counts a round the player did not
// dodge). The final round ends the game at once: there is no
// next round for a return to gate. A dodge that backs off before
// the hold is aborted with no count; the 4-second round clock
// keeps running, so a stalled dodge still ends as a miss.
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a labeled
// DEMO stepper (calibration steps, then one tap per whole round
// as a dodge) so the playing/done states can be previewed. On a
// real device with a sensor, there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 10;
const TURN_DEG = 27;          // dodge direction reached: 25-30 deg yaw
const CENTER_DEG = 10;        // return-to-center band: <10 deg
const HOLD_MS = 800;          // hold-steady ~0.8 s for a dodge to count
const ROUND_MS = 4000;        // no turn within 4 s = miss
const RETURN_GRACE_MS = 4000; // return grace: next round announced anyway
const STALL_MS = 8000;        // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED obstacle sequence (not random): L, R, R, L, R, L, L, R, L, R.
const SEQ = ['left', 'right', 'right', 'left', 'right', 'left', 'left', 'right', 'left', 'right'];

export default {
  data: {
    big: '准备',
    countLine: '躲开 0 / 10',
    hint: '单击开始 · 10 回合躲障碍',
    safety: '分段躲，不转圈、不甩头：每回合障碍只在一边，慢慢向另一边转，停 0.8 秒，再回正到中间，下一回合才开始。绝不从一边直接扫到另一边，不做连续转圈。慢、小幅度、到微酸即止，躲是沉稳地转，不是猛闪。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | wait | turned | returning
    this._sub = 'wait';
    this._round = 0;
    this._score = 0;
    this._sensor = null;
    this._yaw = null;      // latest yaw deg (formula below)
    this._center = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._leftSign = null; // +1 / -1: which raw yaw sign means LEFT (learned)
    this._turnSince = 0;
    this._roundSince = 0;
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
  // Yaw from the orientation quaternion (standard conversion):
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Only the RELATIVE yaw vs the calibrated center is ever used, so
  // the host's absolute zero never matters.
  //
  // YAW-SIGN — learned, not assumed (G02's pattern): at round start
  // the game asks once ("请向左转一下") and records the sign the
  // head actually moves as LEFT. A host whose yaw sign is inverted
  // therefore still counts left as left. Residual caveat,
  // documented in AGENTS.md and on the device-test checklist:
  // calibration trusts the player to follow that one prompt —
  // turning right instead of left would learn the signs backwards.
  // The fail-safe is that nothing counts before calibration
  // completes, and restarting (tap on done, or re-entering)
  // re-runs calibration. No fallback sign is ever guessed.
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

  // Relative yaw vs calibrated center, wrapped to [-180, 180].
  _relYaw() {
    if (!this._hasReading || this._yaw === null) return null;
    let d = this._yaw - this._center;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },

  // Signed yaw in "left-positive" space: positive = left, negative =
  // right, once calibration has learned _leftSign. Null before that.
  _leftYaw() {
    const rel = this._relYaw();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },

  _obstacle() {
    return SEQ[this._round];
  },
  // Dodge direction is always AWAY from the obstacle.
  _dodgeDir() {
    return this._obstacle() === 'left' ? 'right' : 'left';
  },
  _dirName(dir) {
    return dir === 'left' ? '向左' : '向右';
  },
  // True when the head is past threshold in the given direction.
  _past(dir, leftYaw) {
    if (dir === 'left') return leftYaw >= TURN_DEG;
    return leftYaw <= -TURN_DEG;
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
  // left/right turns come from the sensor, never from a gesture event.

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
    this._center = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerSet = true;
    this._round = 0;
    this._score = 0;
    this._leftSign = null;
    this._sub = 'calibTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。先校准：请向左转一下。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting left-calibration turn' });
    this._render();
  },

  _announceRound() {
    this._sub = 'wait';
    this._roundSince = Date.now();
    const ob = this._obstacle();
    const dg = this._dodgeDir();
    this._speak('第' + (this._round + 1) + '回合，' + (ob === 'left' ? '左边' : '右边') + '有障碍，' + this._dirName(dg) + '躲');
    this.setData({ foot: 'EVT: round ' + (this._round + 1) + '/' + TOTAL + ' obstacle ' + ob + ', dodge ' + dg });
    this._render();
  },

  // Finish one round. Dodge adds 1; hit and miss add 0. After a
  // non-final round the player must return to center before the
  // next round is announced (see _tick 'returning'). The final
  // round ends the game at once — there is no next round for a
  // return to gate.
  _finishRound(result) {
    if (result === 'dodge') {
      this._score++;
      this._speak('躲开了');
    } else if (result === 'hit') {
      this._speak('被撞到了');
    } else {
      this._speak('没躲开');
    }
    if (this._round >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE dodges ' + this._score + '/' + TOTAL });
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
  // Labeled as demo everywhere it appears; never a real dodge. One
  // tap per calibration step, then one tap per whole round as a
  // dodge (turn + hold + return collapsed) so the playing/done
  // states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration turn (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._sub = 'wait';
      this._announceRound();
      this.setData({ foot: 'EVT: DEMO calibration return (sensor SKIP)' });
    } else {
      this._score++;
      if (this._round >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done dodges ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._round++;
        this._announceRound();
        this.setData({ foot: 'EVT: DEMO dodge round, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'calibTurn') return '请向左转一下，幅度小一点';
    if (this._sub === 'calibReturn') return '回正到中间';
    if (this._sub === 'turned') return '停住';
    if (this._sub === 'returning') return '回正到中间，下一回合等你回正';
    const ob = this._obstacle();
    return (ob === 'left' ? '左边有障碍，向右躲' : '右边有障碍，向左躲');
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
    const rel = this._relYaw();
    if (rel === null) return; // sensor SKIP: demo button drives rounds
    const now = Date.now();

    // --- calibration: learn which sign means left, count nothing ---
    if (this._sub === 'calibTurn') {
      if (Math.abs(rel) >= TURN_DEG) {
        this._leftSign = rel > 0 ? 1 : -1;
        this._sub = 'calibReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: left sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请向左转一下，幅度小一点');
        this.setData({ foot: 'EVT: calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._sub === 'calibReturn') {
      if (Math.abs(rel) < CENTER_DEG) {
        // Re-center on the returned head position, then round 1.
        this._center = this._yaw;
        this._announceRound();
        this.setData({ foot: 'EVT: calibration complete, center re-set, round 1 announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- rounds: leftYaw is positive-left once calibrated -----------
    const ly = this._leftYaw();
    if (ly === null) return;
    const dg = this._dodgeDir();
    const ob = this._obstacle();

    if (this._sub === 'wait') {
      if (this._past(dg, ly)) {
        this._sub = 'turned';
        this._turnSince = now;
        this._speak('停住');
        this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' turned away past ' + TURN_DEG + ' deg, holding' });
      } else if (this._past(ob, ly)) {
        // Turned TOWARD the obstacle: hit, no dodge.
        this._finishRound('hit');
        return;
      } else if (now - this._roundSince >= ROUND_MS) {
        this._finishRound('miss');
        return;
      }
    } else if (this._sub === 'turned') {
      if (!this._past(dg, ly) && Math.abs(ly) < TURN_DEG - 5) {
        // Backed off before the hold: aborted, no count; the round
        // clock keeps running, so a stalled dodge still ends as miss.
        this._sub = 'wait';
        this.setData({ foot: 'EVT: dodge aborted before hold, no count' });
      } else if (this._past(dg, ly)) {
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk && now - this._turnSince >= HOLD_MS) {
          this._finishRound('dodge');
          return;
        }
      }
      if (now - this._roundSince >= ROUND_MS && this._sub === 'turned') {
        // Held too long without completing, or clock ran out mid-hold.
        this._finishRound('miss');
        return;
      }
    } else if (this._sub === 'returning') {
      if (Math.abs(rel) < CENTER_DEG) {
        this._nextRound();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        // Grace expired: next round is announced anyway, with a
        // spoken reminder to return to center. Nothing is counted
        // by the grace itself.
        this._speak('请回正，下一回合开始');
        this._nextRound();
        return;
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      hint = '单击开始 · 10 回合躲障碍';
      safety = '分段躲，不转圈、不甩头：每回合障碍只在一边，慢慢向另一边转，停 0.8 秒，再回正到中间，下一回合才开始。绝不从一边直接扫到另一边，不做连续转圈。慢、小幅度、到微酸即止，躲是沉稳地转，不是猛闪。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示躲开 ' + this._score + ' / 10' : '躲开 ' + this._score + ' / 10';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibTurn') {
        big = '请向左转一下';
        hint = '只校准一次：慢慢向左转，幅度小一点';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibReturn') {
        big = '回正到中间';
        hint = '慢慢转回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._sub === 'turned') {
        big = '停住…';
        hint = '保持这个方向，停 0.8 秒';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示躲开一次' : '朗读';
      } else if (this._sub === 'returning') {
        big = '回正到中间';
        hint = '慢慢转回正前方，下一回合等你回正';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示躲开一次' : '朗读';
      } else {
        const ob = this._obstacle();
        if (ob === 'left') {
          big = '◀ 障碍在左';
          hint = '向右躲 → 慢转，停 0.8 秒，再回正';
        } else {
          big = '障碍在右 ▶';
          hint = '向左躲 → 慢转，停 0.8 秒，再回正';
        }
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示躲开一次' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: '躲开 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">左右闪避 TURN DODGE</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不转圈 · 不甩头 · 躲开要回正 · 痛晕立刻停</div>
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
  font-size: 40px;
  font-weight: bold;
  line-height: 48px;
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
