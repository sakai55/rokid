<script def>
{
  "title": "Ear Tilt"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Ear Tilt （贴耳操） — head-movement mini-game G03, EXTREME simplicity.
// One page, three states only: ready / playing / done. The screen shows
// at most a big instruction, a count x/6 and one short hint while
// playing (including the hold countdown); voice (TTS) does the rest.
// No menus, no settings, no levels, no camera, no mic/ASR, no storage,
// no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion: center
// -> one direction -> hold -> return to center -> next direction.
// Never continuous circling, never sweep from one extreme to another,
// never fast jerking. Slow, small range, stop at mild stretch, never
// pain. The ear goes toward the shoulder; NEVER lift the shoulder up
// to meet the ear — the shoulder stays down. Stop at once on pain /
// dizziness / numbness / nausea. Sit or stand steady first. One round
// is 60-180 s. This is entertainment / daily activity, NOT medical
// diagnosis, treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should ask a
// doctor first.
//
// HOW A REP IS COUNTED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt: "请向左贴一下". Whichever roll sign the head
// actually moves is learned as LEFT, so a host roll-sign inversion
// cannot silently swap left/right counts (see "ROLL-SIGN" below).
// Return to center, then reps alternate left / right, 3 + 3 = 6.
// Each rep: tilt past threshold -> hold the full 5 s (spoken
// countdown 5-4-3-2-1) -> return to center = 1 rep, spoken by TTS.
// Releasing early counts nothing. Sweeping to the other side without
// returning counts nothing and is told "请先回正，不要直接扫到另一边".
// If a rep stalls, TTS re-prompts ONCE and never auto-counts.
// Sensor missing (web preview) = SKIP/demo state, never a fake pass:
// the screen says so, and the main button becomes a labeled DEMO
// stepper so the playing/done states can be previewed. On a real
// device with a sensor, there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 6;
const TILT_DEG = 27;      // tilt reached: 25-30 deg roll
const CENTER_DEG = 10;    // return-to-center band: <10 deg
const HOLD_MS = 5000;     // hold the full 5 s, spoken countdown
const STALL_MS = 8000;    // rep stall -> one TTS re-prompt, never auto-count
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 6',
    hint: '单击开始 · 左右各 3 次',
    safety: '分段做，不转圈：向左贴 → 稳住 5 秒 → 回正，向右贴 → 稳住 5 秒 → 回正，左右交替。耳朵向肩膀贴，肩膀别抬起来迎耳朵——肩膀保持下沉。慢、小幅度、到微酸即止，不甩头，不从一边直接扫到另一边。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | wait | tilted | held
    this._rep = 'wait';
    this._count = 0;
    this._sensor = null;
    this._roll = null;     // latest roll deg (formula below)
    this._center = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._leftSign = null; // +1 / -1: which raw roll sign means LEFT (learned)
    this._holdAccum = 0;   // accumulated steady hold time in this tilt
    this._lastCountNum = 0;
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
  // Roll from the orientation quaternion (standard conversion):
  // roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees.
  // Only the RELATIVE roll vs the calibrated center is ever used, so
  // the host's absolute zero never matters.
  //
  // ROLL-SIGN — learned, not assumed: at round start the game asks
  // once ("请向左贴一下") and records the sign the head actually
  // moves as LEFT. A host whose roll sign is inverted therefore still
  // counts left as left. Residual caveat, documented in AGENTS.md and
  // on the device-test checklist: calibration trusts the player to
  // follow that one prompt — tilting right instead of left would
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

  // Relative roll vs calibrated center, wrapped to [-180, 180].
  _relRoll() {
    if (!this._hasReading || this._roll === null) return null;
    let d = this._roll - this._center;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },

  // Signed roll in "left-positive" space: positive = left, negative =
  // right, once calibration has learned _leftSign. Null before that.
  _leftRoll() {
    const rel = this._relRoll();
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
  _past(dir, leftRoll) {
    if (dir === 'left') return leftRoll >= TILT_DEG;
    return leftRoll <= -TILT_DEG;
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
  // side tilts come from the sensor, never from a gesture event.

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
    this._center = (this._hasReading && this._roll !== null) ? this._roll : 0;
    this._centerSet = true;
    this._count = 0;
    this._leftSign = null;
    this._rep = 'calibTurn';
    this._holdAccum = 0;
    this._lastCountNum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._wrongDir = false;
    this._swept = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。先校准：请向左贴一下，耳朵向肩膀贴，肩膀别抬。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting left-calibration tilt' });
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
      this._speak('完成，左右各三次都做完了。');
      this.setData({ foot: 'EVT: DONE ' + this._count + '/' + TOTAL });
    } else {
      this._speak('第' + this._count + '次，' + this._dirName(this._expected()) + '贴，慢一点');
      this.setData({ foot: 'EVT: rep counted ' + this._count + '/' + TOTAL });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real rep. One tap
  // per calibration step, then one tap per whole rep (tilt + hold +
  // return collapsed) so the playing/done states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._rep === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._rep = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration tilt (sensor SKIP)' });
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
    if (this._rep === 'calibTurn') return '请向左贴一下，耳朵向肩膀贴，肩膀别抬';
    if (this._rep === 'calibReturn') return '回正到中间';
    if (this._rep === 'tilted') return '稳住，肩膀别抬';
    if (this._rep === 'held') return '回正到中间';
    return this._dirName(this._expected()) + '贴，慢一点';
  },

  // Countdown number remaining while holding: 5 down to 1.
  _countdownLeft() {
    return Math.max(1, 5 - Math.floor(this._holdAccum / 1000));
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
    const rel = this._relRoll();
    if (rel === null) return; // sensor SKIP: demo button drives reps
    const now = Date.now();

    // --- calibration: learn which sign means left, count nothing ---
    if (this._rep === 'calibTurn') {
      if (Math.abs(rel) >= TILT_DEG) {
        this._leftSign = rel > 0 ? 1 : -1;
        this._rep = 'calibReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: left sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请向左贴一下，耳朵向肩膀贴，肩膀别抬');
        this.setData({ foot: 'EVT: calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._rep === 'calibReturn') {
      if (Math.abs(rel) < CENTER_DEG) {
        // Re-center on the returned head position, then first rep.
        this._center = this._roll;
        this._rep = 'wait';
        this._reprompted = false;
        this._speak('向左贴，肩膀别抬，稳住');
        this.setData({ foot: 'EVT: calibration complete, center re-set, first rep left' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- reps: leftRoll is positive-left once calibrated -------------
    const lr = this._leftRoll();
    if (lr === null) return;
    const dir = this._expected();
    const other = dir === 'left' ? 'right' : 'left';
    this._wrongDir = false;
    this._swept = false;
    if (this._rep === 'wait') {
      if (this._past(dir, lr)) {
        this._rep = 'tilted';
        this._holdAccum = 0;
        this._lastCountNum = 5;
        this._stallSince = now;
        this._reprompted = false;
        this._speak('稳住，五');
        this.setData({ foot: 'EVT: tilted ' + dir + ' past ' + TILT_DEG + ' deg, hold countdown started' });
      } else if (this._past(other, lr)) {
        this._wrongDir = true;
      }
    } else if (this._rep === 'tilted') {
      if (!this._past(dir, lr) && Math.abs(lr) < TILT_DEG - 5) {
        // Released before the full 5 s hold: aborted, no count.
        this._rep = 'wait';
        this._speak('没贴够，重新贴，慢一点');
        this.setData({ foot: 'EVT: tilt released before full hold, no count' });
      } else if (this._past(dir, lr)) {
        // Hold accumulates only while steady where the host reports
        // stability; if the host never reports stability, elapsed
        // time alone gates the hold (documented fallback).
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) {
          this._holdAccum += TICK_MS;
          const left = this._countdownLeft();
          if (left < this._lastCountNum) {
            this._lastCountNum = left;
            const words = { 4: '四', 3: '三', 2: '二', 1: '一' };
            this._speak(words[left] || String(left));
          }
        }
        if (this._holdAccum >= HOLD_MS) {
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
      if (this._past(dir, lr)) {
        // Still tilted: keep waiting for center.
        this._stallSince = now;
      } else if (this._past(other, lr)) {
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
      hint = '单击开始 · 左右各 3 次';
      safety = '分段做，不转圈：向左贴 → 稳住 5 秒 → 回正，向右贴 → 稳住 5 秒 → 回正，左右交替。耳朵向肩膀贴，肩膀别抬起来迎耳朵——肩膀保持下沉。慢、小幅度、到微酸即止，不甩头，不从一边直接扫到另一边。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 6 / 6' : '完成 6 / 6';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._rep === 'calibTurn') {
        big = '请向左贴一下';
        hint = '只校准一次：慢慢向左贴，肩膀别抬';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示向左贴' : '朗读';
      } else if (this._rep === 'calibReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._rep === 'tilted') {
        big = '稳住 ' + this._countdownLeft();
        hint = '保持贴住，肩膀别抬 · 倒数 ' + this._countdownLeft();
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示贴耳一次' : '朗读';
      } else if (this._rep === 'held') {
        big = '回正到中间';
        hint = this._swept ? '请先回正，不要直接扫到另一边' : '慢慢贴回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示贴耳一次' : '朗读';
      } else {
        big = this._dirName(this._expected()) + '贴，慢一点';
        hint = this._wrongDir
          ? ('反了？请' + this._dirName(this._expected()) + '贴，不是另一边')
          : (this._dirName(this._expected()) + '贴 → 稳住 5 秒 → 回正 = 1 次');
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示贴耳一次' : '朗读';
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
    <div class="title">贴耳操 EAR TILT</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不转圈 · 不甩头 · 肩膀别抬 · 不直接扫到另一边 · 痛晕立刻停</div>
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
