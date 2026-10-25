<script def>
{
  "title": "Steady Hold"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Steady Hold （稳头挑战） — head-movement mini-game GA07, opening
// Group B (head-as-controller). EXTREME simplicity: one page, three
// states only (ready / playing / done). The whole game is staying
// still: there is NO turning at all, which is itself a safety
// point. Tap start -> 1-second settle ("摆好，开始稳住") -> hold
// the head still for 10 continuous seconds. The screen shows at
// most a big progress (seconds held x/10) and one short hint
// ("别动，稳住"); voice (TTS) does the rest. No menus, no
// settings, no levels, no camera, no mic/ASR, no storage, no
// network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. This game involves NO
// turning at all — the whole game is staying still. Never fast
// jerking. Sit or stand steady first, feet steady, no walking
// while playing. Stop at once on pain / dizziness / numbness /
// nausea. One round is short: a single 10-second hold,
// replayable. This is entertainment / daily activity, NOT medical
// diagnosis, treatment or a rehab prescription; people with
// cervical disease, vertigo, post-op or head/neck injury history
// should ask a doctor first.
//
// HOW A WIN IS COUNTED (sensor state machine, no fake counts):
// START begins a 1-second settle; at the end of the settle the
// current orientation is captured as the attempt's center, and the
// 10-second hold begins. Stillness = total angular change from
// that captured orientation, computed from the
// AbsoluteOrientationSensor quaternion (angle between the
// current quaternion and the center quaternion: 2*acos(|dot|),
// in degrees, combining pitch + yaw + roll into one number).
// The hold accumulates only while that total deviation stays
// under 5 degrees. FAIRNESS GRACE: a deviation beyond 5 degrees
// lasting under ~0.3 s (a tremor / blink-scale wobble) does NOT
// reset — the grace window freezes accumulation but does not
// clear it, and if the head returns inside 5 degrees within
// 300 ms the hold resumes from the same value. Sustained
// movement beyond 5 degrees for 300 ms or more resets the timer
// to 0 immediately ("动了，从头来") and the attempt restarts
// automatically (1-second settle, center re-captured, no tap
// needed). After 5 resets in one round, TTS suggests resting
// ("休息一下再来") and the game returns to ready. Tap during
// playing abandons the round to ready (on a real device; in the
// sensor-SKIP demo the tap is the labeled demo stepper instead).
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
// events of any kind — stillness comes from the sensor alone.
// -------------------------------------------------------------------

const HOLD_MS = 10000;    // one continuous 10-second hold = win
const SETTLE_MS = 1000;   // 1-second settle before each attempt
const THRESH_DEG = 5;     // total angular deviation must stay under 5 deg
const GRACE_MS = 300;     // wobble under ~0.3 s does NOT reset
const MAX_RESETS = 5;     // 5 resets in one round -> rest, back to ready
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 10 秒',
    hint: '单击开始 · 头不动，稳住 10 秒',
    safety: '这个游戏不用转头：全程就是稳住不动。先坐稳 / 站稳，脚站稳，玩的时候不要走路。点开始，摆好，头一点也别动，稳满 10 秒。动了就从头来。慢、不甩头。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    this._sub = 'settle';  // settle | holding (inside playing only)
    this._sensor = null;
    this._quat = null;     // latest [x, y, z, w]
    this._centerQuat = null;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._heldMs = 0;
    this._resets = 0;
    this._graceSince = null;
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
  // Total angular change from the captured center quaternion:
  // angle = 2*acos(|dot(q, qCenter)|), in degrees. One number that
  // combines pitch + yaw + roll, so a drift in ANY direction
  // breaks stillness — there is no axis to hide a movement in.
  // Only the RELATIVE angle vs the captured center is ever used,
  // so the host's absolute zero never matters.
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

  // Total angular deviation in degrees vs the captured center.
  // Null before a center is captured or before any reading.
  _deviationDeg() {
    if (!this._hasReading || !this._quat || !this._centerQuat) return null;
    let dot = 0;
    for (let i = 0; i < 4; i++) dot += this._quat[i] * this._centerQuat[i];
    if (dot < 0) dot = -dot;
    if (dot > 1) dot = 1;
    return 2 * Math.acos(dot) * 180 / Math.PI;
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
  // gesture events at all — stillness comes from the sensor alone.

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
    this._centerQuat = null;
    this._demoUsed = false;
    this._rested = false;
    this._sub = 'settle';
    this._settleUntil = Date.now() + SETTLE_MS;
    this._phase = 'playing';
    this._startTimer();
    this._speak('坐稳，头摆正，摆好，开始稳住，头一点也别动，稳满 10 秒');
    this.setData({ foot: 'EVT: round started, 1 s settle, center not yet captured' });
    this._render();
  },

  _win() {
    this._phase = 'done';
    this._stopTimer();
    this._speak('稳满 10 秒，好稳');
    this.setData({ foot: 'EVT: DONE held 10 s continuous, deviation under 5 deg' });
    this._render();
  },

  // Reset: timer to 0, attempt restarts automatically (settle +
  // center re-captured). The 5th reset in one round ends the round
  // with a rest suggestion instead of another restart.
  _doReset() {
    this._resets++;
    this._heldMs = 0;
    this._graceSince = null;
    this._centerQuat = null;
    if (this._resets >= MAX_RESETS) {
      this._phase = 'ready';
      this._rested = true;
      this._speak('动了，休息一下再来，坐稳了再开始');
      this.setData({ foot: 'EVT: 5 resets in one round, rest suggested, back to ready' });
    } else {
      this._sub = 'settle';
      this._settleUntil = Date.now() + SETTLE_MS;
      this._speak('动了，从头来');
      this.setData({ foot: 'EVT: reset ' + this._resets + '/' + MAX_RESETS + ', auto-restart settle' });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real hold. One
  // tap leaves the settle, then each tap adds 1 second, so the
  // playing (e.g. 6/10) and done (10/10) states can be previewed.
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
          // Capture the center NOW: this orientation is the stillness
          // reference for the whole attempt.
          this._centerQuat = [this._quat[0], this._quat[1], this._quat[2], this._quat[3]];
          this._sub = 'holding';
          this._heldMs = 0;
          this._graceSince = null;
          this._speak('开始，稳住，别动');
          this.setData({ foot: 'EVT: settle done, center captured, hold started' });
        }
      } else {
        this._settleUntil = now + 200; // no reading yet: wait, do not capture null
      }
      this._render();
      return;
    }

    // holding:
    const dev = this._deviationDeg();
    if (dev === null) return;
    if (dev < THRESH_DEG) {
      // Inside the still band: grace clears, and the hold accumulates
      // only while steady where the host reports stability; if the
      // host never reports stability, elapsed time alone gates the
      // hold (documented fallback, not a fake stable).
      this._graceSince = null;
      const steadyOk = !this._stableSeen || this._stable;
      if (steadyOk) this._heldMs += TICK_MS;
      if (this._heldMs >= HOLD_MS) { this._win(); return; }
    } else {
      // Beyond 5 deg: start / continue the grace window. Under 300 ms
      // the wobble does NOT reset (accumulation frozen, not cleared);
      // at or beyond 300 ms of sustained movement, reset.
      if (this._graceSince === null) {
        this._graceSince = now;
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

  _render() {
    let big, countLine, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      countLine = '0 / 10 秒';
      hint = this._rested
        ? '休息一下再来 · 单击重新开始'
        : '单击开始 · 头不动，稳住 10 秒';
      safety = '这个游戏不用转头：全程就是稳住不动。先坐稳 / 站稳，脚站稳，玩的时候不要走路。点开始，摆好，头一点也别动，稳满 10 秒。动了就从头来。慢、不甩头。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示稳满 10 秒' : '稳满 10 秒';
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
        big = '摆好，开始稳住';
        hint = this._resets > 0
          ? '动了，从头来（第' + this._resets + '次重来）· 摆好别动'
          : '摆好，头不动，1 秒后开始计时';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示开始稳住' : '放弃';
      } else {
        big = '稳住 ' + sec + ' 秒';
        hint = this._graceSince !== null
          ? '动了？快稳住别动，0.3 秒内回正不算动'
          : '别动，稳住';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示+1秒' : '放弃';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 稳住以 5 度为限';
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
    <div class="title">稳头挑战 STEADY HOLD</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不用转头，全程稳住不动 · 动了从头来 · 痛晕立刻停</div>
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
