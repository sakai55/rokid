<script def>
{
  "title": "Stretch Hold"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Stretch Hold （仰低拉伸） — head-movement mini-game G04, EXTREME
// simplicity. One page, three states only: ready / playing / done.
// The screen shows at most a big instruction, a count x/6 and one
// short hint while playing (including the hold countdown); voice
// (TTS) does the rest. No menus, no settings, no levels, no camera,
// no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion: center
// -> one direction -> hold -> return to center -> next direction.
// Never continuous circling, never sweep from one extreme to another,
// never fast jerking. Slow, small range, stop at mild stretch, never
// pain. For UP specifically: only to a MILD stretch, NEVER force the
// head far back, NEVER hyperextend, NEVER throw the head back. Stop
// at once on pain / dizziness / numbness / nausea. Sit or stand
// steady first. One round is 60-180 s. This is entertainment / daily
// activity, NOT medical diagnosis, treatment or a rehab prescription;
// people with cervical disease, vertigo, post-op or head/neck injury
// history should ask a doctor first.
//
// HOW A REP IS COUNTED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt: "请低一下头". Whichever pitch sign the head
// actually moves is learned as DOWN; UP is the opposite pitch sign
// (see "PITCH-SIGN" below). Return to center, then reps alternate
// up / down, 3 + 3 = 6. Each rep: move past threshold -> hold the
// full 5 s (spoken countdown 5-4-3-2-1) -> return to center = 1 rep,
// spoken by TTS ("慢慢仰头，到轻微拉伸就停，稳住，5、4、3、2、1，
// 回正"). Releasing early counts nothing. Sweeping to the other side
// without returning counts nothing and is told "请先回正，不要直接
// 扫到另一边". If a rep stalls, TTS re-prompts ONCE and never
// auto-counts. Sensor missing (web preview) = SKIP/demo state,
// never a fake pass: the screen says so, and the main button becomes
// a labeled DEMO stepper so the playing/done states can be previewed.
// On a real device with a sensor, there is no DEMO path at all.
//
// DISTINCT FROM G01 nod-count: G01 counts QUICK nods (down ~0.8 s
// hold). This game HOLDS: every rep requires the full 5 s hold plus
// a return to center.
// -------------------------------------------------------------------

const TOTAL = 6;
const DIR_DEG = 27;       // direction reached: 25-30 deg pitch
const CENTER_DEG = 10;    // return-to-center band: <10 deg
const HOLD_MS = 5000;     // hold the full 5 s, spoken countdown
const STALL_MS = 8000;    // rep stall -> one TTS re-prompt, never auto-count
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 6',
    hint: '单击开始 · 仰头低头各 3 次',
    safety: '分段做，不转圈：仰头 → 稳住 5 秒 → 回正，低头 → 稳住 5 秒 → 回正，上下交替。慢、小幅度、到微酸即止。仰头只到轻微拉伸，绝不用力往后仰、绝不把头向后甩。低头也只到微酸，不压下巴贴胸。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
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
    this._pitch = null;    // latest pitch deg (formula below)
    this._center = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._downSign = null; // +1 / -1: which raw pitch sign means DOWN (learned)
    this._holdAccum = 0;   // accumulated steady hold time in this direction
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
  // Pitch from the orientation quaternion, same formula as G01
  // nod-count (fleet-consistent):
  // pitch = asin(2*(w*x - y*z)), clamped. Only the RELATIVE pitch vs
  // the calibrated center is ever used, so the host's absolute zero
  // never matters.
  //
  // PITCH-SIGN — learned, not assumed: at round start the game asks
  // once ("请低一下头") and records the sign the head actually moves
  // as DOWN; UP is the opposite sign. A host whose pitch sign is
  // inverted therefore still counts down as down and up as up.
  // Residual caveat, documented in AGENTS.md and on the device-test
  // checklist: calibration trusts the player to follow that one
  // prompt — looking up instead of down would learn the signs
  // backwards (if the down sign is learned backwards, up/down swap).
  // The fail-safe is that the first rep is up again, so a backwards
  // calibration feels wrong at once, and restarting (tap on done, or
  // re-entering) re-runs calibration. No fallback sign is ever
  // guessed: before calibration completes, nothing counts.
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

  // Relative pitch vs calibrated center, wrapped to [-180, 180].
  _relPitch() {
    if (!this._hasReading || this._pitch === null) return null;
    let d = this._pitch - this._center;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },

  // Signed pitch in "down-positive" space: positive = down, negative =
  // up, once calibration has learned _downSign. Null before that.
  _downPitch() {
    const rel = this._relPitch();
    if (rel === null || this._downSign === null) return null;
    return rel * this._downSign;
  },

  // Expected direction of the next rep: reps alternate, up first.
  _expected() {
    return (this._count % 2 === 0) ? 'up' : 'down';
  },
  _dirName(dir) {
    return dir === 'up' ? '仰头' : '低头';
  },
  // True when the head is past threshold in the given direction.
  _past(dir, downPitch) {
    if (dir === 'down') return downPitch >= DIR_DEG;
    return downPitch <= -DIR_DEG;
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
  // up/down stretches come from the sensor, never from a gesture event.

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
    // the down sign is then learned by the one calibration prompt.
    this._center = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._centerSet = true;
    this._count = 0;
    this._downSign = null;
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
    this._speak('头摆正，开始。先校准：请低一下头，慢慢低头，到微酸就停。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting down-calibration tilt' });
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
      this._speak('完成，仰头低头各三次都做完了。');
      this.setData({ foot: 'EVT: DONE ' + this._count + '/' + TOTAL });
    } else {
      this._speak('第' + this._count + '次，' + this._dirName(this._expected()) + '，慢一点');
      this.setData({ foot: 'EVT: rep counted ' + this._count + '/' + TOTAL });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real rep. One tap
  // per calibration step, then one tap per whole rep (direction + hold
  // + return collapsed) so the playing/done states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._rep === 'calibTurn') {
      this._downSign = 1; // demo assumption, labeled as demo only
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
    if (this._rep === 'calibTurn') return '请低一下头，慢慢低头，到微酸就停';
    if (this._rep === 'calibReturn') return '回正到中间';
    if (this._rep === 'tilted') return this._expected() === 'up'
      ? '稳住，仰头只到轻微拉伸，不要用力往后仰'
      : '稳住，低头只到微酸';
    if (this._rep === 'held') return '回正到中间';
    return this._expected() === 'up'
      ? '慢慢仰头，到轻微拉伸就停，不要用力往后仰'
      : '慢慢低头，到微酸就停';
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
    const rel = this._relPitch();
    if (rel === null) return; // sensor SKIP: demo button drives reps
    const now = Date.now();

    // --- calibration: learn which sign means down, count nothing ---
    if (this._rep === 'calibTurn') {
      if (Math.abs(rel) >= DIR_DEG) {
        this._downSign = rel > 0 ? 1 : -1;
        this._rep = 'calibReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: down sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请低一下头，慢慢低头，到微酸就停');
        this.setData({ foot: 'EVT: calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._rep === 'calibReturn') {
      if (Math.abs(rel) < CENTER_DEG) {
        // Re-center on the returned head position, then first rep.
        this._center = this._pitch;
        this._rep = 'wait';
        this._reprompted = false;
        this._speak('慢慢仰头，到轻微拉伸就停，不要用力往后仰，稳住');
        this.setData({ foot: 'EVT: calibration complete, center re-set, first rep up' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- reps: downPitch is positive-down once calibrated ------------
    const dp = this._downPitch();
    if (dp === null) return;
    const dir = this._expected();
    const other = dir === 'up' ? 'down' : 'up';
    this._wrongDir = false;
    this._swept = false;
    if (this._rep === 'wait') {
      if (this._past(dir, dp)) {
        this._rep = 'tilted';
        this._holdAccum = 0;
        this._lastCountNum = 5;
        this._stallSince = now;
        this._reprompted = false;
        this._speak(dir === 'up' ? '稳住，五，不要用力往后仰' : '稳住，五');
        this.setData({ foot: 'EVT: moved ' + dir + ' past ' + DIR_DEG + ' deg, hold countdown started' });
      } else if (this._past(other, dp)) {
        this._wrongDir = true;
      }
    } else if (this._rep === 'tilted') {
      if (!this._past(dir, dp) && Math.abs(dp) < DIR_DEG - 5) {
        // Released before the full 5 s hold: aborted, no count.
        this._rep = 'wait';
        this._speak('没稳住，重新来，慢一点');
        this.setData({ foot: 'EVT: direction released before full hold, no count' });
      } else if (this._past(dir, dp)) {
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
      if (this._past(dir, dp)) {
        // Still in the direction: keep waiting for center.
        this._stallSince = now;
      } else if (this._past(other, dp)) {
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
      hint = '单击开始 · 仰头低头各 3 次';
      safety = '分段做，不转圈：仰头 → 稳住 5 秒 → 回正，低头 → 稳住 5 秒 → 回正，上下交替。慢、小幅度、到微酸即止。仰头只到轻微拉伸，绝不用力往后仰、绝不把头向后甩。低头也只到微酸，不压下巴贴胸。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 6 / 6' : '完成 6 / 6';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._rep === 'calibTurn') {
        big = '请低一下头';
        hint = '只校准一次：慢慢低头，到微酸就停';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示低一下头' : '朗读';
      } else if (this._rep === 'calibReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._rep === 'tilted') {
        big = '稳住 ' + this._countdownLeft();
        hint = '保持住 · 倒数 ' + this._countdownLeft()
          + (this._expected() === 'up' ? ' · 仰头只到轻微拉伸，绝不用力往后仰' : '');
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示拉伸一次' : '朗读';
      } else if (this._rep === 'held') {
        big = '回正到中间';
        hint = this._swept ? '请先回正，不要直接扫到另一边' : '慢慢贴回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示拉伸一次' : '朗读';
      } else {
        const up = this._expected() === 'up';
        big = (up ? '仰头' : '低头') + '，慢一点';
        hint = this._wrongDir
          ? ('反了？请' + this._dirName(this._expected()) + '，不是另一边')
          : (this._dirName(this._expected()) + ' → 稳住 5 秒 → 回正 = 1 次'
            + (up ? ' · 只到轻微拉伸，绝不用力往后仰' : ''));
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示拉伸一次' : '朗读';
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
    <div class="title">仰低拉伸 STRETCH HOLD</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不转圈 · 不甩头 · 不用力往后仰 · 不直接扫到另一边 · 痛晕立刻停</div>
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
