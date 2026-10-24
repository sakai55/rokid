<script def>
{
  "title": "Level Keep"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Level Keep （端水平） — head-movement mini-game G14, Group C
// (observation/control). EXTREME simplicity: one page, three
// states only (ready / playing / done). The whole game is holding
// the head LEVEL: there is NO turning at all. Tap start ->
// 1-second settle ("摆好，端平，开始") capturing the level
// reference -> hold the head level for 10 continuous seconds.
// The playing screen shows at most a level ball/track (ball
// centered = level, ball offset left/right with roll), seconds
// held x/10, and one short hint ("端平，别歪"). Voice (TTS)
// does the rest. No menus, no settings, no levels, no camera,
// no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. This game involves NO
// turning at all — the whole game is holding the head level.
// Never fast jerking. Sit or stand steady first, feet steady, no
// walking while playing. Stop at once on pain / dizziness /
// numbness / nausea. One round is a single 10-second level hold,
// replayable. This is entertainment / daily activity, NOT medical
// diagnosis, treatment or a rehab prescription; people with
// cervical disease, vertigo, post-op or head/neck injury history
// should ask a doctor first.
//
// HOW A WIN IS COUNTED (sensor state machine, no fake counts):
// START begins a 1-second settle; at the end of the settle the
// current roll is captured as the attempt's level reference, and
// the 10-second hold begins. Level = RELATIVE ROLL vs that
// reference, from the AbsoluteOrientationSensor quaternion:
// roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees
// (the G03 ear-tilt formula), and the relative roll is the
// wrapped difference of the current roll and the reference roll,
// in [-180, 180]. Only roll counts: pitch/yaw drift does NOT
// break level by itself — that is what distinguishes this game
// from G07 steady-hold (G07: total angular change in ANY
// direction breaks stillness; this game: roll only, with a
// visual ball). The hold accumulates only while the relative
// roll stays within +/-8 degrees of the reference. FAIRNESS
// GRACE (same as G07): a tilt beyond 8 degrees lasting under
// ~0.3 s does NOT reset — the grace window freezes accumulation
// but does not clear it, and if the head returns inside 8
// degrees within 300 ms the hold resumes from the same value.
// A tilt beyond 8 degrees sustained for 300 ms or more resets
// the timer to 0 immediately ("歪了，从头来") and the attempt
// restarts automatically (1-second settle, level reference
// re-captured, no tap needed). After 5 resets in one round, TTS
// suggests resting ("休息一下再来") and the game returns to
// ready. Tap during playing abandons the round to ready (on a
// real device; in the sensor-SKIP demo the tap is the labeled
// demo stepper instead).
// ROLL DIRECTION NAMING — DISPLAY CONVENTION, NOT A CLAIM:
// relative roll > 0 is displayed and spoken as a RIGHT tilt
// ("往右歪了", ball to the right) and relative roll < 0 as a
// LEFT tilt ("往左歪了", ball to the left). This naming is a
// convention to verify on device, not a verified host sign:
// the device checklist must confirm a real right tilt shows
// "往右歪了" (and vice versa); if the host roll axis is
// inverted, the naming must be swapped — the band, grace and
// win logic are unaffected, since they use |relative roll|.
// Stability events from onOrientationStabilityChange are a
// SUPPORTING signal only: where the host reports them, an
// unstable report pauses accumulation but never resets it and
// never passes a hold on its own; if the host never reports
// them, elapsed time alone gates the hold (documented fallback,
// not a fake stable). Sensor missing (web preview) = SKIP/demo
// state, never a fake pass: the screen says so, and the main
// button becomes a labeled DEMO stepper (settle, then +1 s per
// tap) so the playing/done states can be previewed. On a real
// device with a sensor there is no DEMO path at all. There is no
// head-gesture handler at all: onHeadGesture is officially
// documented ONLY for 'nod', and this game uses no gesture
// events of any kind — level comes from the sensor alone.
// DIFFERENCE FROM photo-level: that agent levels a CAMERA
// photo; this game levels the HEAD (roll), with no camera.
// -------------------------------------------------------------------

const HOLD_MS = 10000;    // one continuous 10-second level hold = win
const SETTLE_MS = 1000;   // 1-second settle before each attempt
const BAND_DEG = 8;       // relative roll must stay within +/-8 deg
const GRACE_MS = 300;     // tilt under ~0.3 s does NOT reset
const MAX_RESETS = 5;     // 5 resets in one round -> rest, back to ready
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    ballLine: '[----------●----------]',
    countLine: '0 / 10 秒',
    hint: '单击开始 · 头端平，稳住 10 秒',
    safety: '这个游戏不用转头：全程就是头端平。先坐稳 / 站稳，脚站稳，玩的时候不要走路。点开始，摆好，头端平，别歪，稳满 10 秒。歪了就从头来。慢、不甩头。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    this._sub = 'settle';  // settle | holding (inside playing only)
    this._sensor = null;
    this._quat = null;     // latest [x, y, z, w]
    this._refRoll = null;  // level reference roll, captured at settle end
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._heldMs = 0;
    this._resets = 0;
    this._graceSince = null;
    this._graceWarned = false;
    this._settleUntil = 0;
    this._demoUsed = false;
    this._rested = false;
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
  // Roll from the sensor quaternion (G03 formula), in degrees.
  // Only the RELATIVE roll vs the captured level reference is
  // ever used, so the host's absolute zero never matters.
  _rollDeg(q) {
    const x = q[0], y = q[1], z = q[2], w = q[3];
    return Math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y)) * 180 / Math.PI;
  },
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

  // Relative roll in degrees vs the captured level reference,
  // wrapped to [-180, 180]. Null before a reference is captured
  // or before any reading. Positive = displayed as RIGHT tilt,
  // negative = displayed as LEFT tilt (display convention only,
  // to verify on device — see header comment).
  _relRollDeg() {
    if (!this._hasReading || !this._quat || this._refRoll === null) return null;
    let d = this._rollDeg(this._quat) - this._refRoll;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
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
  // officially documented ONLY for 'nod', and this game uses no
  // gesture events at all — level comes from the sensor alone.

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
    this._heldMs = 0;
    this._resets = 0;
    this._graceSince = null;
    this._graceWarned = false;
    this._refRoll = null;
    this._demoUsed = false;
    this._rested = false;
    this._sub = 'settle';
    this._settleUntil = Date.now() + SETTLE_MS;
    this._phase = 'playing';
    this._startTimer();
    this._speak('坐稳，头摆正，摆好，端平，开始');
    this.setData({ foot: 'EVT: round started, 1 s settle, level ref not yet captured' });
    this._render();
  },

  _win() {
    this._phase = 'done';
    this._stopTimer();
    this._speak('端平 10 秒，好平');
    this.setData({ foot: 'EVT: DONE level 10 s continuous, relative roll within 8 deg' });
    this._render();
  },

  // Reset: timer to 0, attempt restarts automatically (settle +
  // level reference re-captured). The 5th reset in one round ends
  // the round with a rest suggestion instead of another restart.
  _doReset() {
    this._resets++;
    this._heldMs = 0;
    this._graceSince = null;
    this._graceWarned = false;
    this._refRoll = null;
    if (this._resets >= MAX_RESETS) {
      this._phase = 'ready';
      this._rested = true;
      this._speak('歪了，休息一下再来，坐稳了再开始');
      this.setData({ foot: 'EVT: 5 resets in one round, rest suggested, back to ready' });
    } else {
      this._sub = 'settle';
      this._settleUntil = Date.now() + SETTLE_MS;
      this._speak('歪了，从头来');
      this.setData({ foot: 'EVT: reset ' + this._resets + '/' + MAX_RESETS + ', auto-restart settle' });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real hold. One
  // tap leaves the settle, then each tap adds 1 second, so the
  // playing (e.g. 6/10) and done (10/10) states can be previewed.
  // The demo ball stays centered (level) throughout.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'settle') {
      this._sub = 'holding';
      this.setData({ foot: 'EVT: DEMO settle done (sensor SKIP)' });
    } else {
      this._heldMs += 1000;
      if (this._heldMs >= HOLD_MS) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done 10/10 s (sensor SKIP)' });
      } else {
        this.setData({ foot: 'EVT: DEMO hold ' + Math.floor(this._heldMs / 1000) + '/10 s (sensor SKIP)' });
      }
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoStep(); return; }
    // Real device: tap abandons the round to ready.
    this._phase = 'ready';
    this._rested = false;
    this._speak('停了');
    this.setData({ foot: 'EVT: round abandoned by tap, back to ready' });
    this._render();
  },

  // ---- tick: settle -> hold -> win / reset ---------------------------
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
    if (this._sensorSkip || !this._hasReading) return; // demo button drives
    const now = Date.now();

    if (this._sub === 'settle') {
      if (this._quat) {
        if (now >= this._settleUntil) {
          // Capture the level reference NOW: this roll is the
          // level reference for the whole attempt.
          this._refRoll = this._rollDeg(this._quat);
          this._sub = 'holding';
          this._heldMs = 0;
          this._graceSince = null;
          this._graceWarned = false;
          this._speak('开始，端平，别歪');
          this.setData({ foot: 'EVT: settle done, level ref captured, hold started' });
        }
      } else {
        this._settleUntil = now + 200; // no reading yet: wait, do not capture null
      }
      this._render();
      return;
    }

    // holding: roll only — pitch/yaw drift alone cannot break level.
    const rel = this._relRollDeg();
    if (rel === null) return;
    if (Math.abs(rel) <= BAND_DEG) {
      // Inside the level band: grace clears, and the hold
      // accumulates only while steady where the host reports
      // stability; if the host never reports stability, elapsed
      // time alone gates the hold (documented fallback, not a
      // fake stable).
      this._graceSince = null;
      this._graceWarned = false;
      const steadyOk = !this._stableSeen || this._stable;
      if (steadyOk) this._heldMs += TICK_MS;
      if (this._heldMs >= HOLD_MS) { this._win(); return; }
    } else {
      // Beyond 8 deg: start / continue the grace window. Under
      // 300 ms the tilt does NOT reset (accumulation frozen, not
      // cleared); at or beyond 300 ms of sustained tilt, reset.
      // The tilt warning is spoken once per excursion.
      if (this._graceSince === null) {
        this._graceSince = now;
        if (!this._graceWarned) {
          this._graceWarned = true;
          this._speak(rel > 0 ? '往右歪了' : '往左歪了');
        }
      } else if (now - this._graceSince >= GRACE_MS) {
        this._doReset();
        return;
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _heldSec() {
    return Math.min(10, Math.floor(this._heldMs / 1000));
  },

  // Level ball/track: 21 cells, ball centered when level, one cell
  // per ~2 deg of relative roll, clamped to the track ends. In
  // demo mode (no sensor) the ball stays centered.
  _ballLine() {
    let rel = 0;
    if (this._phase === 'playing' && this._sub === 'holding' && !this._sensorSkip && this._hasReading) {
      const r = this._relRollDeg();
      if (r !== null) rel = r;
    }
    let off = Math.round(rel / 2);
    if (off > 10) off = 10;
    if (off < -10) off = -10;
    const pos = 10 + off;
    let s = '[';
    for (let i = 0; i < 21; i++) s += (i === pos ? '●' : '-');
    return s + ']';
  },

  _render() {
    let big, countLine, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      countLine = '0 / 10 秒';
      hint = this._rested
        ? '休息一下再来 · 单击重新开始'
        : '单击开始 · 头端平，稳住 10 秒';
      safety = '这个游戏不用转头：全程就是头端平。先坐稳 / 站稳，脚站稳，玩的时候不要走路。点开始，摆好，头端平，别歪，稳满 10 秒。歪了就从头来。慢、不甩头。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示端平 10 秒' : '端平 10 秒';
      countLine = '10 / 10 秒';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局';
      safety = '';
      mainBtn = '再来一局';
    } else {
      const sec = this._heldSec();
      countLine = sec + ' / 10 秒';
      if (this._sub === 'settle') {
        big = '摆好，端平，开始';
        hint = this._resets > 0
          ? '歪了，从头来（第' + this._resets + '次重来）· 摆好端平'
          : '摆好，头端平，1 秒后开始计时';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示开始端平' : '放弃';
      } else {
        big = '端平 ' + sec + ' 秒';
        if (this._graceSince !== null) {
          const rel = this._relRollDeg();
          hint = (rel !== null && rel > 0)
            ? '往右歪了？快端平，0.3 秒内回正不算歪'
            : '往左歪了？快端平，0.3 秒内回正不算歪';
        } else {
          hint = '端平，别歪';
        }
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示+1秒' : '放弃';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 端平以滚角 ±8 度为限';
    const ballLine = this._ballLine();
    const key = [big, ballLine, countLine, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      ballLine: ballLine,
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
    <div class="title">端水平 LEVEL KEEP</div>
    <div class="big">{{ big }}</div>
    <div class="ball">{{ ballLine }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不用转头，全程头端平 · 歪了从头来 · 痛晕立刻停</div>
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
.ball {
  color: #40ff5e;
  font-size: 22px;
  font-weight: bold;
  line-height: 28px;
  margin-top: 6px;
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
