<script def>
{
  "title": "Stop Center"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Stop Center （回正定点） — head-movement mini-game GA24, Wave 2,
// Group E (precision control). One page, three states only
// (ready / playing / done). 8 trials, alternating sides.
// Per trial: voice calls a side ("向左转"), turn to that side
// (reach >=20 deg toward it), voice says "回正，停住", then
// return to center and STOP inside +/-5 deg (yaw) without
// overshooting to the other side, holding ~0.8 s = hit (+1).
// Overshooting past 5 deg to the uncalled side during the stop
// phase = miss at once ("过冲了"). 14 s without finishing =
// miss. After a miss the player must return to center (<10 deg
// on BOTH axes) before the next call; after a hit the player is
// already inside +/-5 deg, so the next call follows at once.
//
// DISTINCT FROM GA21 (angle-match) and GA13 (find-target):
// GA21 judges landing IN a called angle band on the way OUT;
// GA13 judges only REACHING a direction. Here the outbound turn
// is just the setup — the scored skill is the RETURN: stopping
// dead inside a narrow center band instead of swinging through
// it to the other side. First-wave games treated return only as
// a gate between trials; here return IS the game.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the
// ready screen, in AGENTS.md and in the README): turning the
// neck in circles is WRONG. Only segmented motion: center ->
// one direction -> return -> stop -> next trial. Never sweep
// from one extreme to another, never fast jerking. Slow, small
// range, stop at mild stretch, never pain. Stop at once on pain
// / dizziness / numbness / nausea. Sit or stand steady first.
// One round set is 8 trials, short. Entertainment / daily
// activity, NOT medical diagnosis, treatment or a rehab
// prescription; people with cervical disease, vertigo, post-op
// or head/neck injury history should ask a doctor first.
//
// Sensor: AbsoluteOrientationSensor quaternion only; yaw =
// atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)) (GA02's formula);
// pitch = asin(2*(w*x - y*z)) clamped (GA01/GA04's formula),
// read ONLY for the center gates. Only RELATIVE pitch/yaw vs
// the calibrated center are used. Yaw sign is LEARNED, not
// assumed: one calibration prompt ("请向左转一下") records the
// sign the head actually moves as LEFT; RIGHT is the opposite
// sign (GA02's pattern). No head-gesture handler: the gesture
// API is documented ONLY for 'nod', and nod is not this game's
// action. Sensor missing (web preview) = SKIP/demo, never a
// fake pass: the screen says so, and the main button becomes a
// labeled DEMO stepper (calibration steps, then one tap per
// whole trial as a hit, return collapsed) so the playing/done
// states can be previewed. On a real device there is no DEMO.
// -------------------------------------------------------------------

const TOTAL = 8;
const GO_DEG = 20;        // outbound turn must reach >=20 deg
const STOP_DEG = 5;       // stop band: yaw within +/-5 deg
const HOLD_MS = 800;      // hold-steady inside the stop band
const CENTER_DEG = 10;    // return gate: <10 deg on BOTH axes
const TRIAL_MS = 14000;   // 14 s without finishing = miss
const RETURN_GRACE_MS = 4000;
const STALL_MS = 8000;
const TICK_MS = 100;
// FIXED trial list (not random): alternating sides.
const TRIALS = ['left', 'right', 'left', 'right', 'left', 'right', 'left', 'right'];

export default {
  data: {
    arrow: '·',
    big: '准备',
    countLine: '停住 0 / 8',
    hint: '单击开始 · 转过去再回正停住，不过冲',
    safety: '回正定点不转圈：每次只向一边转，慢慢回正，停在正中间，不冲到另一边，再下一题。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready';
    // calibTurn | calibReturn | go | stop | returnGate
    this._sub = 'go';
    this._trial = 0;
    this._score = 0;
    this._sensor = null;
    this._pitch = null;
    this._yaw = null;
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._leftSign = null;
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

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) { return false; }
  },

  _startSensor() {
    if (this._sensor || this._sensorSkip) return;
    const Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) { this._sensorSkip = true; this._render(); return; }
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
    } catch (e) { this._sensorSkip = true; this._render(); }
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

  _side() { return TRIALS[this._trial]; },
  _sideWord(side) { return side === 'left' ? '左' : '右'; },
  _sideArrow(side) { return side === 'left' ? '←' : '→'; },
  // Yaw magnitude TOWARD the called side (positive = toward it).
  _toward(leftYaw) {
    return this._side() === 'left' ? leftYaw : -leftYaw;
  },

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    const s = event.stable !== undefined ? event.stable
      : (detail.stable !== undefined ? detail.stable : detail.isStable);
    if (s !== undefined) { this._stable = s === true; this._stableSeen = true; }
  },

  // NOTE: no head-gesture handler, deliberately. The gesture API
  // is documented ONLY for 'nod', and nod is not this game's
  // action — angles come from the sensor, never a gesture event.

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

  _beginRound() {
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._trial = 0;
    this._score = 0;
    this._leftSign = null;
    this._sub = 'calibTurn';
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始回正定点。回正定点不转圈：每次只向一边转，慢慢回正，停在正中间，不冲到另一边。先校准：请向左转一下。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting left-calibration turn' });
    this._render();
  },

  _announceTrial() {
    this._sub = 'go';
    this._trialSince = Date.now();
    this._holdAccum = 0;
    this._speak('向' + this._sideWord(this._side()) + '转');
    this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + '/' + TOTAL + ' go ' + this._side() });
    this._render();
  },

  _finishTrial(hit, overshoot) {
    if (hit) { this._score++; this._speak('停住了'); }
    else if (overshoot) { this._speak('过冲了'); }
    else { this._speak('没停住'); }
    if (this._trial >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE stops ' + this._score + '/' + TOTAL });
    } else if (hit) {
      // Already inside +/-5 deg: next call follows at once.
      this._trial++;
      this._announceTrial();
      this.setData({ foot: 'EVT: trial hit, score ' + this._score + '/' + TOTAL + ', next call at once (already centered)' });
    } else {
      this._sub = 'returnGate';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: trial miss, score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibTurn') {
      this._leftSign = 1;
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration turn (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._announceTrial();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._trial >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done stops ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._trial++;
        this._announceTrial();
        this.setData({ foot: 'EVT: DEMO stop trial, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      }
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    if (this._sensorSkip || !this._hasReading) { this._demoStep(); return; }
    this._speak(this._currentInstruction());
  },

  _currentInstruction() {
    if (this._sub === 'calibTurn') return '请向左转一下，幅度小一点';
    if (this._sub === 'calibReturn') return '回正到中间';
    if (this._sub === 'go') return '向' + this._sideWord(this._side()) + '转';
    if (this._sub === 'stop') return '回正，停住，别冲过去';
    if (this._sub === 'returnGate') return '回正到中间，下一题等你回正';
    return '向' + this._sideWord(this._side()) + '转';
  },

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
    if (relPitch === null || relYaw === null) return;
    const now = Date.now();

    if (this._sub === 'calibTurn') {
      if (Math.abs(relYaw) >= GO_DEG) {
        this._leftSign = relYaw > 0 ? 1 : -1;
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
      if (this._atCenter(relPitch, relYaw)) {
        this._recenter();
        this._announceTrial();
        this.setData({ foot: 'EVT: calibration complete, center re-set, first trial announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._sub === 'returnGate') {
      if (this._atCenter(relPitch, relYaw)) {
        this._trial++;
        this._announceTrial();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        this._speak('请回正，下一题等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next trial still gated on return' });
      }
      this._render();
      return;
    }

    const ly = this._leftYaw();
    if (ly === null) return;
    const toward = this._toward(ly);

    if (now - this._trialSince >= TRIAL_MS) {
      this._finishTrial(false, false);
      return;
    }
    if (this._sub === 'go') {
      if (toward >= GO_DEG) {
        this._sub = 'stop';
        this._holdAccum = 0;
        this._speak('回正，停住');
        this.setData({ foot: 'EVT: trial ' + (this._trial + 1) + ' outbound reached, awaiting return stop' });
      }
    } else if (this._sub === 'stop') {
      if (toward <= -STOP_DEG) {
        // Swung through center to the other side: overshoot miss.
        this._finishTrial(false, true);
        return;
      }
      if (Math.abs(ly) <= STOP_DEG && Math.abs(relPitch) < CENTER_DEG) {
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk) this._holdAccum += TICK_MS;
        if (this._holdAccum >= HOLD_MS) {
          this._finishTrial(true, false);
          return;
        }
      } else {
        this._holdAccum = 0;
      }
    }
    this._render();
  },

  _render() {
    let arrow, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      arrow = '◎';
      big = '准备';
      hint = '单击开始 · 转过去再回正停住，不过冲';
      safety = '回正定点不转圈：每次只向一边转，慢慢回正，停在正中间，不冲到另一边，再下一题。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '◎';
      big = this._demoUsed ? '演示停住 ' + this._score + ' / 8' : '停住 ' + this._score + ' / 8';
      hint = this._demoUsed ? '演示模式：传感器不可用 · 单击再来一局' : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibTurn') {
        arrow = '←'; big = '请向左转一下'; hint = '只校准一次：慢慢向左转，幅度小一点'; mainBtn = demo ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibReturn') {
        arrow = '◎'; big = '回正到中间'; hint = '慢慢转回正前方'; mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'go') {
        arrow = this._sideArrow(this._side()); big = '向' + this._sideWord(this._side()) + '转'; hint = '慢慢转到一边 · 转到位就听回正口令'; mainBtn = demo ? '演示停住一次' : '朗读';
      } else if (this._sub === 'stop') {
        arrow = '◎'; big = '回正，停住…'; hint = '停在正中间 ±5 度 · 别冲到另一边 · 停 0.8 秒'; mainBtn = demo ? '演示停住一次' : '朗读';
      } else {
        arrow = '◎'; big = '回正到中间'; hint = '这一题没停住 · 慢慢转回正前方，下一题等你回正'; mainBtn = demo ? '演示停住一次' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [arrow, big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({ arrow: arrow, big: big, countLine: '停住 ' + this._score + ' / ' + TOTAL, hint: hint, safety: safety, sensorLine: sensorLine, mainBtn: mainBtn });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">回正定点 STOP CENTER</div>
    <div class="arrow">{{ arrow }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-stop" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">转过去 · 回正停住 · 不过冲 · 痛晕立刻停</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 18px; box-sizing: border-box; }
.title { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.arrow { color: #40ff5e; font-size: 52px; font-weight: bold; line-height: 56px; text-align: center; margin-top: 2px; }
.big { color: #7dff9e; font-size: 36px; font-weight: bold; line-height: 42px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.count { color: #40ff5e; font-size: 28px; font-weight: bold; line-height: 32px; margin-top: 2px; }
.hint { color: rgba(125, 255, 158, 0.9); font-size: 14px; line-height: 19px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.safety { color: rgba(125, 255, 158, 0.72); font-size: 11px; line-height: 15px; margin-top: 4px; }
.sensor { color: rgba(64, 255, 94, 0.62); font-size: 10px; line-height: 13px; margin-top: 4px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; justify-content: center; margin-top: 8px; }
.btn-stop { width: 300px; background-color: #062b12; color: #7dff9e; border: 2px solid rgba(64, 255, 94, 0.85); border-radius: 6px; font-size: 16px; font-weight: bold; letter-spacing: 3px; padding: 9px 0; text-align: center; }
.foot { color: rgba(64, 255, 94, 0.72); font-family: monospace; font-size: 10px; line-height: 13px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.foot2 { color: rgba(64, 255, 94, 0.48); font-size: 10px; line-height: 13px; margin-top: 1px; }
</style>
