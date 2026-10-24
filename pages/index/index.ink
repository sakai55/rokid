<script def>
{
  "title": "Turn Count"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Turn Count （转头操） — head-movement mini-game G02, EXTREME simplicity.
// One page, three states only: ready / playing / done. The screen shows
// at most a big instruction, a count x/10 and one short hint while
// playing; voice (TTS) does the rest. No menus, no settings, no levels,
// no camera, no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion: center
// -> one direction -> hold -> return to center -> next direction.
// Never continuous circling, never sweep from one extreme to another,
// never fast jerking. Slow, small range, stop at mild stretch, never
// pain. Stop at once on pain / dizziness / numbness / nausea. Sit or
// stand steady first. One round is 60-180 s. This is entertainment /
// daily activity, NOT medical diagnosis, treatment or a rehab
// prescription; people with cervical disease, vertigo, post-op or
// head/neck injury history should ask a doctor first.
//
// HOW A REP IS COUNTED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt: "请向左转一下". Whichever yaw sign the head
// actually moves is learned as LEFT, so a host yaw-sign inversion
// cannot silently swap left/right counts (see "YAW-SIGN" below).
// Return to center, then reps alternate left / right, 5 + 5 = 10.
// Each rep: turn past threshold -> hold ~0.8 s -> return to center
// = 1 rep, spoken by TTS. A turn without a return never counts, and
// the next direction is only accepted after the return: turning
// straight from one extreme to the other counts nothing and is told
// "请先回正，不要直接扫到另一边".
// If a rep stalls, TTS re-prompts ONCE and never auto-counts.
// Sensor missing (web preview) = SKIP/demo state, never a fake pass:
// the screen says so, and the main button becomes a labeled DEMO
// stepper so the playing/done states can be previewed. On a real
// device with a sensor, there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 10;
const TURN_DEG = 27;      // direction reached: 25-30 deg yaw
const CENTER_DEG = 10;    // return-to-center band: <10 deg
const HOLD_MS = 800;      // hold-steady ~0.8 s
const STALL_MS = 8000;    // rep stall -> one TTS re-prompt, never auto-count
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 10',
    hint: '单击开始 · 左右各 5 次',
    safety: '分段做，不转圈：向左 → 停 → 回正，向右 → 停 → 回正，左右交替。慢、小幅度、到微酸即止，不甩头，不从一边直接扫到另一边。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | wait | turned | held
    this._rep = 'wait';
    this._count = 0;
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
  // Yaw from the orientation quaternion (standard conversion):
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Only the RELATIVE yaw vs the calibrated center is ever used, so
  // the host's absolute zero never matters.
  //
  // YAW-SIGN — learned, not assumed: at round start the game asks
  // once ("请向左转一下") and records the sign the head actually
  // moves as LEFT. A host whose yaw sign is inverted therefore still
  // counts left as left. Residual caveat, documented in AGENTS.md and
  // on the device-test checklist: calibration trusts the player to
  // follow that one prompt — turning right instead of left would
  // learn the signs backwards. The fail-safe is that the first rep
  // is left again, so a backwards calibration feels wrong at once,
  // and restarting (tap on done, or re-entering) re-runs calibration.
  // No fallback sign is ever guessed: before calibration completes,
  // nothing counts.
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

  // Expected direction of the next rep: reps alternate, left first.
  _expected() {
    return (this._count % 2 === 0) ? 'left' : 'right';
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
    this._count = 0;
    this._leftSign = null;
    this._rep = 'calibTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._wrongDir = false;
    this._swept = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。先校准：请向左转一下。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting left-calibration turn' });
    this._render();
  },

  _countRep() {
    this._count++;
    this._rep = 'wait';
    this._reprompted = false;
    this._wrongDir = false;
    this._swept = false;
    if (this._count >= TOTAL) {
      this._phase = 'done';
      this._stopTimer();
      this._speak('完成，左右各五次都做完了。');
      this.setData({ foot: 'EVT: DONE ' + this._count + '/' + TOTAL });
    } else {
      this._speak('第' + this._count + '次，' + this._dirName(this._expected()) + '，慢一点');
      this.setData({ foot: 'EVT: rep counted ' + this._count + '/' + TOTAL });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real rep. One tap
  // per calibration step, then one tap per whole rep (turn + hold +
  // return collapsed) so the playing/done states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._rep === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._rep = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration turn (sensor SKIP)' });
    } else if (this._rep === 'calibReturn') {
      this._rep = 'wait';
      this.setData({ foot: 'EVT: DEMO calibration return (sensor SKIP)' });
    } else {
      this._count++;
      this._rep = 'wait';
      if (this._count >= TOTAL) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done ' + this._count + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this.setData({ foot: 'EVT: DEMO rep ' + this._count + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._rep === 'calibTurn') return '请向左转一下，幅度小一点';
    if (this._rep === 'calibReturn') return '回正到中间';
    if (this._rep === 'turned') return '停住';
    if (this._rep === 'held') return '回正到中间';
    return this._dirName(this._expected()) + '，慢一点';
  },

  // ---- tick: the rep state machine -----------------------------------
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
    if (rel === null) return; // sensor SKIP: demo button drives reps
    const now = Date.now();

    // --- calibration: learn which sign means left, count nothing ---
    if (this._rep === 'calibTurn') {
      if (Math.abs(rel) >= TURN_DEG) {
        this._leftSign = rel > 0 ? 1 : -1;
        this._rep = 'calibReturn';
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
    if (this._rep === 'calibReturn') {
      if (Math.abs(rel) < CENTER_DEG) {
        // Re-center on the returned head position, then first rep.
        this._center = this._yaw;
        this._rep = 'wait';
        this._reprompted = false;
        this._speak('向左，慢一点');
        this.setData({ foot: 'EVT: calibration complete, center re-set, first rep left' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- reps: leftYaw is positive-left once calibrated -------------
    const ly = this._leftYaw();
    if (ly === null) return;
    const dir = this._expected();
    const other = dir === 'left' ? 'right' : 'left';
    this._wrongDir = false;
    this._swept = false;
    if (this._rep === 'wait') {
      if (this._past(dir, ly)) {
        this._rep = 'turned';
        this._turnSince = now;
        this._stallSince = now;
        this._reprompted = false;
        this._speak('停住');
        this.setData({ foot: 'EVT: turned ' + dir + ' past ' + TURN_DEG + ' deg' });
      } else if (this._past(other, ly)) {
        this._wrongDir = true;
      }
    } else if (this._rep === 'turned') {
      if (!this._past(dir, ly) && Math.abs(ly) < TURN_DEG - 5) {
        // Backed off before the hold: aborted, no count.
        this._rep = 'wait';
        this.setData({ foot: 'EVT: turn aborted before hold, no count' });
      } else if (this._past(dir, ly)) {
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk && now - this._turnSince >= HOLD_MS) {
          this._rep = 'held';
          this._stallSince = now;
          this._speak('回正到中间');
          this.setData({ foot: 'EVT: held ' + HOLD_MS + ' ms' });
        } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
          this._reprompted = true;
          this._speak('慢慢回正到中间');
          this.setData({ foot: 'EVT: rep stalled, re-prompted once (no auto-count)' });
        }
      }
    } else if (this._rep === 'held') {
      if (Math.abs(rel) < CENTER_DEG) {
        this._countRep();
        return;
      }
      if (this._past(dir, ly)) {
        // Still turned: keep waiting for center.
        this._stallSince = now;
      } else if (this._past(other, ly)) {
        // Swept straight to the other extreme without returning:
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
      hint = '单击开始 · 左右各 5 次';
      safety = '分段做，不转圈：向左 → 停 → 回正，向右 → 停 → 回正，左右交替。慢、小幅度、到微酸即止，不甩头，不从一边直接扫到另一边。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 10 / 10' : '完成 10 / 10';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._rep === 'calibTurn') {
        big = '请向左转一下';
        hint = '只校准一次：慢慢向左转，幅度小一点';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示向左转' : '朗读';
      } else if (this._rep === 'calibReturn') {
        big = '回正到中间';
        hint = '慢慢转回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._rep === 'turned') {
        big = '停住…';
        hint = '保持这个方向，停一下';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示转头一次' : '朗读';
      } else if (this._rep === 'held') {
        big = '回正到中间';
        hint = this._swept ? '请先回正，不要直接扫到另一边' : '慢慢转回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示转头一次' : '朗读';
      } else {
        big = this._dirName(this._expected()) + '，慢一点';
        hint = this._wrongDir
          ? ('反了？请' + this._dirName(this._expected()) + '转，不是另一边')
          : (this._dirName(this._expected()) + ' → 停 → 回正 = 1 次');
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示转头一次' : '朗读';
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
    <div class="title">转头操 TURN COUNT</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不转圈 · 不甩头 · 不直接扫到另一边 · 痛晕立刻停</div>
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
