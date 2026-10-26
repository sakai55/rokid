<script def>
{
  "title": "Memory Six"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Memory Six （六向记忆） — head-movement mini-game GA26, Wave 2,
// Group F (memory / rhythm advanced). One page, three states only
// (ready / playing / done). 3 rounds, sequences over SIX
// directions (left, right, up, down, left tilt, right tilt):
// round 1 = 3 steps, round 2 = 4 steps, round 3 = 5 steps.
// The round is ANNOUNCED by voice only — the screen shows no
// direction during the announce (GA12's pattern) — then the
// player reproduces it step by step. Each step: turn / dip /
// tilt to the called direction and reach its threshold, then
// return to center before the next step. Reaching a DIFFERENT
// direction's threshold first = round failed at once ("顺序
// 错了"). 10 s without the right step = round failed. Score =
// rounds reproduced correctly, x/3.
//
// DISTINCT FROM GA12 (memory-seq): GA12 only used FOUR
// directions (left / right / up / down). Here the element set
// grows to SIX by adding left tilt and right tilt (side bends),
// so the memory load is genuinely larger and the replay must
// tell a tilt apart from a turn — a step is judged on its own
// axis only. Also distinct from GA22 (tilt-match): that judges
// tilt ANGLE precision against small targets; here tilt is one
// element of a remembered sequence, judged only by direction.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the
// ready screen, in AGENTS.md and in the README): turning the
// neck in circles is WRONG. Only segmented motion: center ->
// one direction -> return to center -> next step. The announce
// NEVER asks for a sweep or a circle: one step at a time, each
// returned from before the next step is attempted. Never fast
// jerking. Slow, small range, stop at mild stretch, never pain.
// Stop at once on pain / dizziness / numbness / nausea. Sit or
// stand steady first. One round set is 3 rounds, short.
// Entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// Sensor: AbsoluteOrientationSensor quaternion only.
// yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)) (GA02);
// pitch = asin(2*(w*x - y*z)) clamped (GA01/GA04);
// roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)) (side bend).
// Only RELATIVE angles vs the calibrated center are used.
// THREE signs are LEARNED, not assumed, by three calibration
// prompts (each followed by a return to center): "请向左转
// 一下" learns LEFT, "请低一下头" learns DOWN, "请向左贴一下
// 耳" learns LEFT TILT; RIGHT / UP / RIGHT TILT are the
// opposite signs. No head-gesture handler: the gesture API is
// documented ONLY for 'nod', and nod is not this game's action.
// Sensor missing (web preview) = SKIP/demo, never a fake pass:
// the screen says so, and the main button becomes a labeled
// DEMO stepper (calibration steps, announce skipped, then one
// tap per whole step as correct, returns collapsed) so the
// playing/done states can be previewed. On a real device there
// is no DEMO.
// -------------------------------------------------------------------

const TOTAL = 3;
const TURN_DEG = 25;      // left/right/up/down reach threshold
const TILT_DEG = 15;      // left/right tilt reach threshold
const CENTER_DEG = 10;    // return gate: <10 deg on ALL axes
const STEP_MS = 10000;    // 10 s without the right step = round failed
const ANN_MS = 1200;      // announce pacing: one item per 1.2 s
const RETURN_GRACE_MS = 4000;
const STALL_MS = 8000;
const TICK_MS = 100;
// Calibration prompts in order: axis + prompt word.
const CALIBS = [
  { axis: 'yaw', word: '向左转一下', reach: TURN_DEG },
  { axis: 'pitch', word: '低一下头', reach: TURN_DEG },
  { axis: 'roll', word: '向左贴一下耳', reach: TILT_DEG }
];
// FIXED sequences (not random). Dir names: left/right/up/down/
// leftTilt/rightTilt.
const ROUNDS = [
  ['left', 'up', 'rightTilt'],
  ['down', 'leftTilt', 'right', 'up'],
  ['rightTilt', 'left', 'down', 'leftTilt', 'right']
];

export default {
  data: {
    arrow: '·',
    big: '准备',
    countLine: '记住 0 / 3',
    hint: '单击开始 · 听六个方向，照顺序做出来',
    safety: '六向记忆不转圈：每次只做一个方向，做完回正到中间，再做下一个。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready';
    // calib | announce | replay | stepReturn | roundReturn
    this._sub = 'announce';
    this._round = 0;
    this._score = 0;
    this._sensor = null;
    this._pitch = null;
    this._yaw = null;
    this._roll = null;
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._rollCenter = 0;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._leftSign = null;
    this._downSign = null;
    this._leftTiltSign = null;
    this._calibIdx = 0;
    this._calibPhase = 'prompt'; // prompt | return
    this._annIdx = 0;
    this._annSince = 0;
    this._stepIdx = 0;
    this._stepSince = 0;
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
  _relRoll() {
    if (!this._hasReading || this._roll === null) return null;
    return this._wrap(this._roll - this._rollCenter);
  },
  _leftYaw() {
    const rel = this._relYaw();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },
  _downPitch() {
    const rel = this._relPitch();
    if (rel === null || this._downSign === null) return null;
    return rel * this._downSign;
  },
  _leftTiltRoll() {
    const rel = this._relRoll();
    if (rel === null || this._leftTiltSign === null) return null;
    return rel * this._leftTiltSign;
  },
  _atCenter(relPitch, relYaw, relRoll) {
    return Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG && Math.abs(relRoll) < CENTER_DEG;
  },
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
    this._rollCenter = this._roll;
  },

  _seq() { return ROUNDS[this._round]; },
  _dirWord(d) {
    return { left: '左', right: '右', up: '上', down: '下', leftTilt: '左贴耳', rightTilt: '右贴耳' }[d] || d;
  },
  _dirArrow(d) {
    return { left: '←', right: '→', up: '↑', down: '↓', leftTilt: '↙', rightTilt: '↘' }[d] || '·';
  },
  _dirThresh(d) { return (d === 'leftTilt' || d === 'rightTilt') ? TILT_DEG : TURN_DEG; },
  // Magnitude TOWARD direction d (positive = toward it).
  _toward(d, ly, dp, lt) {
    if (d === 'left') return ly;
    if (d === 'right') return -ly;
    if (d === 'down') return dp;
    if (d === 'up') return -dp;
    if (d === 'leftTilt') return lt;
    return -lt; // rightTilt
  },
  // True when direction d is currently reached on its own axis.
  _reached(d, ly, dp, lt) {
    return this._toward(d, ly, dp, lt) >= this._dirThresh(d);
  },

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    const s = event.stable !== undefined ? event.stable
      : (detail.stable !== undefined ? detail.stable : detail.isStable);
    if (s !== undefined) { this._stable = s === true; this._stableSeen = true; }
  },

  // NOTE: no head-gesture handler, deliberately. The gesture API
  // is documented ONLY for 'nod', and nod is not this game's
  // action — directions come from the sensor, never an event.

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
    this._rollCenter = (this._hasReading && this._roll !== null) ? this._roll : 0;
    this._round = 0;
    this._score = 0;
    this._leftSign = null;
    this._downSign = null;
    this._leftTiltSign = null;
    this._calibIdx = 0;
    this._calibPhase = 'prompt';
    this._sub = 'calib';
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始六向记忆。六向记忆不转圈：每次只做一个方向，做完回正，再做下一个。先校准三个方向：请向左转一下。');
    this.setData({ foot: 'EVT: round started, center calibrated, calib 1/3 left turn' });
    this._render();
  },

  _announceRound() {
    this._sub = 'announce';
    this._annIdx = 0;
    this._annSince = Date.now();
    this._speak('第 ' + (this._round + 1) + ' 轮，听好，一共 ' + this._seq().length + ' 个方向');
    this.setData({ foot: 'EVT: round ' + (this._round + 1) + '/' + TOTAL + ' announce ' + this._seq().length + ' steps' });
    this._render();
  },

  _startReplay() {
    this._sub = 'replay';
    this._stepIdx = 0;
    this._stepSince = Date.now();
    this._speak('轮到你了，照顺序做');
    this.setData({ foot: 'EVT: round ' + (this._round + 1) + ' replay started' });
    this._render();
  },

  _finishRound(passed) {
    if (passed) { this._score++; this._speak('这一轮全对'); }
    else { this._speak('顺序错了'); }
    if (this._round >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE rounds ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'roundReturn';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: round ' + (this._round + 1) + (passed ? ' passed' : ' failed') + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calib') {
      if (this._calibPhase === 'prompt') {
        if (this._calibIdx === 0) this._leftSign = 1;
        if (this._calibIdx === 1) this._downSign = 1;
        if (this._calibIdx === 2) this._leftTiltSign = 1;
        this._calibPhase = 'return';
        this.setData({ foot: 'EVT: DEMO calib ' + (this._calibIdx + 1) + '/3 prompt (sensor SKIP)' });
      } else if (this._calibIdx < 2) {
        this._calibIdx++;
        this._calibPhase = 'prompt';
        this.setData({ foot: 'EVT: DEMO calib return, next prompt (sensor SKIP)' });
      } else {
        this._announceRound();
        this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
      }
    } else if (this._sub === 'announce') {
      this._startReplay();
      this.setData({ foot: 'EVT: DEMO announce skipped (sensor SKIP)' });
    } else if (this._sub === 'replay') {
      if (this._stepIdx >= this._seq().length - 1) {
        this._finishRound(true);
        this.setData({ foot: 'EVT: DEMO round passed (sensor SKIP)' });
      } else {
        this._stepIdx++;
        this._stepSince = Date.now();
        this.setData({ foot: 'EVT: DEMO step correct (sensor SKIP)' });
      }
    } else if (this._sub === 'roundReturn') {
      this._round++;
      this._announceRound();
      this.setData({ foot: 'EVT: DEMO round return, next round (sensor SKIP)' });
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
    if (this._sub === 'calib') {
      const c = CALIBS[this._calibIdx];
      return this._calibPhase === 'prompt' ? '请' + c.word : '回正到中间';
    }
    if (this._sub === 'announce') return '听好，记住顺序';
    if (this._sub === 'replay') return '第 ' + (this._stepIdx + 1) + ' 个：照顺序做';
    if (this._sub === 'roundReturn') return '回正到中间，下一轮等你回正';
    return '照顺序做';
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
    const relRoll = this._relRoll();
    if (relPitch === null || relYaw === null || relRoll === null) return;
    const now = Date.now();

    // --- calibration: three prompts, each followed by a return ---
    if (this._sub === 'calib') {
      const c = CALIBS[this._calibIdx];
      if (this._calibPhase === 'prompt') {
        const axisVal = c.axis === 'yaw' ? relYaw : (c.axis === 'pitch' ? relPitch : relRoll);
        if (Math.abs(axisVal) >= c.reach) {
          const sign = axisVal > 0 ? 1 : -1;
          if (c.axis === 'yaw') this._leftSign = sign;
          else if (c.axis === 'pitch') this._downSign = sign;
          else this._leftTiltSign = sign;
          this._calibPhase = 'return';
          this._reprompted = false;
          this._stallSince = now;
          this._speak('好，记住了，回正到中间');
          this.setData({ foot: 'EVT: calib ' + (c.axis) + ' sign learned, awaiting return' });
        } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
          this._reprompted = true;
          this._speak('请' + c.word + '，幅度小一点');
          this.setData({ foot: 'EVT: calibration stalled, re-prompted once (no auto-count)' });
        }
      } else {
        if (this._atCenter(relPitch, relYaw, relRoll)) {
          if (this._calibIdx < 2) {
            this._calibIdx++;
            this._calibPhase = 'prompt';
            this._reprompted = false;
            this._stallSince = now;
            this._speak('下一个校准：请' + CALIBS[this._calibIdx].word);
            this.setData({ foot: 'EVT: calib return done, next prompt ' + (this._calibIdx + 1) + '/3' });
          } else {
            this._recenter();
            this._announceRound();
            this.setData({ foot: 'EVT: calibration complete, center re-set, round 1 announced' });
          }
        } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
          this._reprompted = true;
          this._speak('慢慢回正到中间');
          this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
        }
      }
      this._render();
      return;
    }

    // --- announce: one item per 1.2 s, voice only ---
    if (this._sub === 'announce') {
      if (this._annIdx < this._seq().length) {
        if (now - this._annSince >= ANN_MS) {
          this._speak(this._dirWord(this._seq()[this._annIdx]));
          this._annIdx++;
          this._annSince = now;
          this.setData({ foot: 'EVT: announced item ' + this._annIdx + '/' + this._seq().length });
        }
      } else {
        this._startReplay();
      }
      this._render();
      return;
    }

    // --- round return gate ---
    if (this._sub === 'roundReturn') {
      if (this._atCenter(relPitch, relYaw, relRoll)) {
        this._round++;
        this._announceRound();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        this._speak('请回正，下一轮等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next round still gated on return' });
      }
      this._render();
      return;
    }

    // --- step return gate ---
    if (this._sub === 'stepReturn') {
      if (this._atCenter(relPitch, relYaw, relRoll)) {
        if (this._stepIdx >= this._seq().length - 1) {
          this._finishRound(true);
        } else {
          this._stepIdx++;
          this._stepSince = Date.now();
          this._sub = 'replay';
          this._speak('下一个');
          this.setData({ foot: 'EVT: step return done, next step ' + (this._stepIdx + 1) });
        }
      } else if (now - this._returnSince >= RETURN_GRACE_MS) {
        this._speak('请回正，下一步等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: step return grace expired, re-prompted 请回正' });
      }
      this._render();
      return;
    }

    // --- replay ---
    if (this._sub !== 'replay') { this._render(); return; }
    const ly = this._leftYaw();
    const dp = this._downPitch();
    const lt = this._leftTiltRoll();
    if (ly === null || dp === null || lt === null) return;
    const want = this._seq()[this._stepIdx];
    if (this._reached(want, ly, dp, lt)) {
      this._sub = 'stepReturn';
      this._returnSince = now;
      this._speak('对');
      this.setData({ foot: 'EVT: step ' + (this._stepIdx + 1) + ' correct (' + want + '), awaiting return' });
      this._render();
      return;
    }
    const ALL = ['left', 'right', 'up', 'down', 'leftTilt', 'rightTilt'];
    for (let i = 0; i < ALL.length; i++) {
      if (ALL[i] !== want && this._reached(ALL[i], ly, dp, lt)) {
        this._finishRound(false);
        return;
      }
    }
    if (now - this._stepSince >= STEP_MS) {
      this._finishRound(false);
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
      hint = '单击开始 · 听六个方向，照顺序做出来';
      safety = '六向记忆不转圈：每次只做一个方向，做完回正到中间，再做下一个。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '◎';
      big = this._demoUsed ? '演示记住 ' + this._score + ' / 3' : '记住 ' + this._score + ' / 3';
      hint = this._demoUsed ? '演示模式：传感器不可用 · 单击再来一局' : '单击再来一局（重新校准三个方向）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calib') {
        const c = CALIBS[this._calibIdx];
        if (this._calibPhase === 'prompt') {
          arrow = this._calibIdx === 0 ? '←' : (this._calibIdx === 1 ? '↓' : '↙');
          big = '请' + c.word;
          hint = '校准 ' + (this._calibIdx + 1) + ' / 3：慢慢做，幅度小一点';
          mainBtn = demo ? '演示校准一步' : '朗读';
        } else {
          arrow = '◎'; big = '回正到中间'; hint = '慢慢回正前方'; mainBtn = demo ? '演示回正' : '朗读';
        }
      } else if (this._sub === 'announce') {
        arrow = '？'; big = '听…'; hint = '第 ' + (this._round + 1) + ' 轮 · 记住顺序，屏幕不显示方向'; mainBtn = demo ? '演示跳过报序' : '朗读';
      } else if (this._sub === 'replay') {
        arrow = '？'; big = '第 ' + (this._stepIdx + 1) + ' 个'; hint = '照顺序做 · 做完回正，下一步等你回正'; mainBtn = demo ? '演示做对一步' : '朗读';
      } else {
        arrow = '◎'; big = '回正到中间'; hint = '这一步对了 · 慢慢回正前方'; mainBtn = demo ? '演示做对一步' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [arrow, big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({ arrow: arrow, big: big, countLine: '记住 ' + this._score + ' / ' + TOTAL, hint: hint, safety: safety, sensorLine: sensorLine, mainBtn: mainBtn });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">六向记忆 MEMORY SIX</div>
    <div class="arrow">{{ arrow }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-six" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">听顺序 · 一步一回正 · 做错即停 · 痛晕立刻停</div>
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
.btn-six { width: 300px; background-color: #0d3316; color: #7dff9e; border: 2px dashed rgba(64, 255, 94, 0.85); border-radius: 12px; font-size: 16px; font-weight: bold; letter-spacing: 3px; padding: 9px 0; text-align: center; }
.foot { color: rgba(64, 255, 94, 0.72); font-family: monospace; font-size: 10px; line-height: 13px; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.foot2 { color: rgba(64, 255, 94, 0.48); font-size: 10px; line-height: 13px; margin-top: 1px; }
</style>
