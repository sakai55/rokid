<script def>
{
  "title": "Hold Ramp"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Hold Ramp （渐进保持） — head-movement mini-game GA25, Wave 2,
// Group E (precision control). One page, three states only
// (ready / playing / done). 5 levels, one at a time: hold the
// head-down position (>=20 deg down) for 2, then 3, 4, 5, then
// 6 seconds, returning to center between levels. Holding the
// full level duration = level passed (+1, "爬上去了"); leaving
// the down zone resets the hold to zero (not a fail by itself);
// the level clock running out = level failed ("没爬上去").
// After every level (pass or fail) the player MUST return to
// center (<10 deg on BOTH axes) before the next level; if not
// returned within 4 seconds, TTS prompts "请回正" and the grace
// timer resets — the next level is NEVER announced until the
// return actually happens.
//
// DISTINCT FROM GA04 (stretch-hold): GA04 holds a FIXED 5 s,
// alternating up and down, 3 times each. Here the hold DURATION
// itself climbs a ladder (2/3/4/5/6 s) and only the DOWN
// direction is used — the skill is sustaining a hold longer and
// longer, not switching directions. Also distinct from GA03
// (ear-tilt): that holds a side tilt; this holds a down pitch.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the
// ready screen, in AGENTS.md and in the README): turning the
// neck in circles is WRONG. Only segmented motion: center ->
// down -> hold -> return to center -> next level. Never sweep,
// never fast jerking. Slow, small range, stop at mild stretch,
// never pain — down only to a light stretch, never forced.
// Stop at once on pain / dizziness / numbness / nausea. Sit or
// stand steady first. One round set is 5 levels, short.
// Entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// Sensor: AbsoluteOrientationSensor quaternion only; pitch =
// asin(2*(w*x - y*z)) clamped (GA01/GA04's formula); yaw =
// atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)) (GA02's formula),
// read ONLY for the center gates. Only RELATIVE pitch/yaw vs
// the calibrated center are used. The DOWN sign is LEARNED,
// not assumed: one calibration prompt ("请低一下头") records
// the pitch sign the head actually moves as DOWN (GA04's
// pattern). No head-gesture handler: the gesture API is
// documented ONLY for 'nod', and nod is not this game's action
// (a nod is a quick dip, not a sustained down hold). Sensor
// missing (web preview) = SKIP/demo, never a fake pass: the
// screen says so, and the main button becomes a labeled DEMO
// stepper (calibration steps, then one tap per whole level as
// a pass, return collapsed) so the playing/done states can be
// previewed. On a real device there is no DEMO.
// -------------------------------------------------------------------

const TOTAL = 5;
const DOWN_DEG = 20;      // down zone: >=20 deg toward down
const CENTER_DEG = 10;    // return gate: <10 deg on BOTH axes
const RETURN_GRACE_MS = 4000;
const STALL_MS = 8000;
const TICK_MS = 100;
// FIXED level ladder in seconds (not random).
const LEVELS = [2, 3, 4, 5, 6];
// Level clock = level duration + 8 s of slack for re-settling.
const SLACK_MS = 8000;

export default {
  data: {
    arrow: '·',
    big: '准备',
    countLine: '爬上 0 / 5',
    hint: '单击开始 · 低头保持，一级比一级久',
    safety: '渐进保持不转圈：每次只低头一次，保持够秒数，再回正到中间，下一级才报。低头只到微酸，不勉强、不后仰、不甩动。慢、小幅度。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready';
    // calibDown | calibReturn | hold | returning
    this._sub = 'hold';
    this._level = 0;
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
    this._downSign = null;
    this._holdAccum = 0;
    this._levelSince = 0;
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
  // Pitch magnitude TOWARD down, once calibrated. Null before.
  _downPitch() {
    const rel = this._relPitch();
    if (rel === null || this._downSign === null) return null;
    return rel * this._downSign;
  },
  _atCenter(relPitch, relYaw) {
    return Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG;
  },
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _levelSec() { return LEVELS[this._level]; },

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    const s = event.stable !== undefined ? event.stable
      : (detail.stable !== undefined ? detail.stable : detail.isStable);
    if (s !== undefined) { this._stable = s === true; this._stableSeen = true; }
  },

  // NOTE: no head-gesture handler, deliberately. The gesture API
  // is documented ONLY for 'nod', and nod is not this game's
  // action — a nod is a quick dip, not a sustained down hold.

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
    this._level = 0;
    this._score = 0;
    this._downSign = null;
    this._sub = 'calibDown';
    this._holdAccum = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始渐进保持。渐进保持不转圈：每次只低头一次，保持够秒数，再回正，下一级才报。低头只到微酸，不勉强。先校准：请低一下头。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting down-calibration dip' });
    this._render();
  },

  _announceLevel() {
    this._sub = 'hold';
    this._levelSince = Date.now();
    this._holdAccum = 0;
    this._speak('第 ' + (this._level + 1) + ' 级，低头保持 ' + this._levelSec() + ' 秒');
    this.setData({ foot: 'EVT: level ' + (this._level + 1) + '/' + TOTAL + ' hold ' + this._levelSec() + 's' });
    this._render();
  },

  _finishLevel(passed) {
    if (passed) { this._score++; this._speak('爬上去了'); }
    else { this._speak('没爬上去'); }
    if (this._level >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE levels ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: level ' + (this._level + 1) + (passed ? ' passed' : ' failed') + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibDown') {
      this._downSign = 1;
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration dip (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._announceLevel();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._level >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done levels ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._level++;
        this._announceLevel();
        this.setData({ foot: 'EVT: DEMO level pass, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'calibDown') return '请低一下头，幅度小一点';
    if (this._sub === 'calibReturn') return '回正到中间';
    if (this._sub === 'returning') return '回正到中间，下一级等你回正';
    return '低头保持 ' + this._levelSec() + ' 秒';
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

    if (this._sub === 'calibDown') {
      if (Math.abs(relPitch) >= DOWN_DEG) {
        this._downSign = relPitch > 0 ? 1 : -1;
        this._sub = 'calibReturn';
        this._reprompted = false;
        this._stallSince = now;
        this._speak('好，记住了，回正到中间');
        this.setData({ foot: 'EVT: down sign learned, awaiting return to center' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('请低一下头，幅度小一点');
        this.setData({ foot: 'EVT: calibration stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._sub === 'calibReturn') {
      if (this._atCenter(relPitch, relYaw)) {
        this._recenter();
        this._announceLevel();
        this.setData({ foot: 'EVT: calibration complete, center re-set, first level announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }
    if (this._sub === 'returning') {
      if (this._atCenter(relPitch, relYaw)) {
        this._level++;
        this._announceLevel();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        this._speak('请回正，下一级等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next level still gated on return' });
      }
      this._render();
      return;
    }

    // hold phase
    const down = this._downPitch();
    if (down === null) return;
    if (down >= DOWN_DEG) {
      const steadyOk = !this._stableSeen || this._stable;
      if (steadyOk) this._holdAccum += TICK_MS;
      if (this._holdAccum >= this._levelSec() * 1000) {
        this._finishLevel(true);
        return;
      }
    } else {
      // Left the down zone before the hold completed: hold resets
      // to zero, nothing counts; the level clock keeps running.
      if (this._holdAccum > 0) {
        this._holdAccum = 0;
        this._speak('没稳住，再低一次，慢一点');
        this.setData({ foot: 'EVT: level left down zone before full hold, hold reset, no count' });
      }
    }
    if (now - this._levelSince >= this._levelSec() * 1000 + SLACK_MS) {
      this._finishLevel(false);
      return;
    }
    this._render();
  },

  _render() {
    let arrow, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      arrow = '◎';
      big = '准备';
      hint = '单击开始 · 低头保持，一级比一级久';
      safety = '渐进保持不转圈：每次只低头一次，保持够秒数，再回正到中间，下一级才报。低头只到微酸，不勉强、不后仰、不甩动。慢、小幅度。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '◎';
      big = this._demoUsed ? '演示爬上 ' + this._score + ' / 5' : '爬上 ' + this._score + ' / 5';
      hint = this._demoUsed ? '演示模式：传感器不可用 · 单击再来一局' : '单击再来一局（重新校准中心与低头方向）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibDown') {
        arrow = '↓'; big = '请低一下头'; hint = '只校准一次：慢慢低头，幅度小一点'; mainBtn = demo ? '演示低一下头' : '朗读';
      } else if (this._sub === 'calibReturn') {
        arrow = '◎'; big = '回正到中间'; hint = '慢慢抬回正前方'; mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'returning') {
        arrow = '◎'; big = '回正到中间'; hint = '这一级完了 · 慢慢抬回正前方，下一级等你回正'; mainBtn = demo ? '演示爬上一级' : '朗读';
      } else {
        arrow = '↓'; big = '低头 · ' + this._levelSec() + ' 秒'; hint = '低头到 20 度以上 · 保持 ' + this._levelSec() + ' 秒 → 爬上去 → 回正'; mainBtn = demo ? '演示爬上一级' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [arrow, big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({ arrow: arrow, big: big, countLine: '爬上 ' + this._score + ' / ' + TOTAL, hint: hint, safety: safety, sensorLine: sensorLine, mainBtn: mainBtn });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">渐进保持 HOLD RAMP</div>
    <div class="arrow">{{ arrow }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-ramp" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">低头保持 · 一级比一级久 · 回正再下一级 · 痛晕立刻停</div>
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
.btn-ramp { width: 300px; background-color: #0d3316; color: #7dff9e; border: 2px solid rgba(64, 255, 94, 0.85); border-radius: 26px 26px 6px 6px; font-size: 16px; font-weight: bold; letter-spacing: 3px; padding: 9px 0; text-align: center; }
.foot { color: rgba(64, 255, 94, 0.72); font-family: monospace; font-size: 10px; line-height: 13px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.foot2 { color: rgba(64, 255, 94, 0.48); font-size: 10px; line-height: 13px; margin-top: 1px; }
</style>
