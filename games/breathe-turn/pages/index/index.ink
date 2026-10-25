<script def>
{
  "title": "Breathe Turn"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Breathe Turn （呼吸转头） — head-movement mini-game GA17, Group C
// (observation/control), closing Group C. EXTREME simplicity: one
// page, three states only (ready / playing / done). One mechanic:
// voice-paced breathing — inhale turn, exhale return — 8 cycles.
// Voice (TTS) does the pacing. No menus, no settings, no levels,
// no camera, no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only slow, segmented
// motion: one side turn per breath, always returning to center
// on the exhale before the next breath — never a circle, never
// a fast swing side to side, never holding a turned position
// across multiple breaths. Slow, small range, stop at mild
// stretch, never pain. Stop at once on pain / dizziness /
// numbness / nausea or breathlessness. Sit or stand steady
// first; do not hold the breath, do not force deep breathing —
// breathe normally and comfortably, the voice only paces the
// rhythm, it does not prescribe a medical breathing technique.
// One game is 8 breath cycles, short. This is entertainment /
// daily activity, NOT medical diagnosis, treatment, rehab or
// breathing therapy; people with cervical disease, vertigo,
// post-op, head/neck injury, or respiratory/cardiac conditions
// should ask a doctor first.
//
// TECHNICAL HONESTY — READ THIS FIRST:
// Rokid glasses have NO breath sensor, so breathing is NEVER
// measured. This game is VOICE-PACED: TTS announces "吸气" and
// "呼气" on a fixed 4 s + 4 s rhythm, and the sensor checks
// only the HEAD movement in each phase (turn during inhale,
// return during exhale). The ready screen says this plainly:
// "眼镜测不到呼吸，语音只定节奏". Never imply the glasses
// detect breath. Sensor missing (web preview) = SKIP/demo
// state, never a fake pass: the screen says so, and the main
// button becomes a labeled DEMO stepper so the playing/done
// states can be previewed. On a real device with a sensor,
// there is no DEMO path at all.
// -------------------------------------------------------------------

const TURN_DEG = 27;      // cued side: 25-30 deg yaw
const CENTER_DEG = 10;    // return-to-center band: <10 deg, both axes
const INHALE_MS = 4000;   // inhale phase: 4 s
const EXHALE_MS = 4000;   // exhale phase: 4 s
const PAUSE_MS = 1000;    // 1 s pause between cycles
const CYCLES = 8;         // 8 breath cycles per game
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
const SEQ = ['left', 'right', 'left', 'right', 'left', 'right', 'left', 'right'];

export default {
  data: {
    big: '准备',
    phaseLine: '吸气转头 · 呼气回正',
    countLine: '8 次呼吸 · 左右交替',
    hint: '单击开始 · 语音定节奏',
    safety: '吸气慢慢转到一侧，呼气慢慢回正，每次呼吸只转一边，绝不转圈、不左右连甩、不憋气、不刻意深呼吸——按自己舒服的节奏呼吸，语音只定节奏。慢、小幅度、到微酸即止。痛、晕、麻、恶心、喘不上气立刻停。先坐稳 / 站稳。注意：眼镜测不到呼吸，语音只定节奏，测的只是转头和回正。本游戏是日常活动娱乐，不是医疗诊断、治疗、康复或呼吸疗法；颈椎病、眩晕、术后、头颈伤史、呼吸或心脏问题请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | inhale | exhale | pause
    this._sub = 'inhale';
    this._sensor = null;
    this._yaw = null;
    this._pitch = null;
    this._center = 0;
    this._pitchCenter = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._leftSign = null; // +1 / -1: which raw yaw sign means LEFT (learned)
    this._cycle = 0;       // 1..8 while playing
    this._completed = 0;
    this._turnAchieved = false;
    this._returnAchieved = false;
    this._centerPassedInhale = false;
    this._phaseSince = 0;
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
  // Pitch = asin(2*(w*x - y*z)), in degrees, clamped.
  // Only RELATIVE yaw/pitch vs the calibrated center are ever used,
  // so the host's absolute zero never matters.
  //
  // YAW-SIGN — learned, not assumed (GA02's pattern): at round start
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
        let sp = 2 * (w * x - y * z);
        if (sp > 1) sp = 1;
        if (sp < -1) sp = -1;
        self._pitch = Math.asin(sp) * 180 / Math.PI;
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
  // Relative pitch vs calibrated center (asin range needs no wrap).
  _relPitch() {
    if (!this._hasReading || this._pitch === null) return null;
    return this._pitch - this._pitchCenter;
  },
  // Signed yaw in "left-positive" space: positive = left, negative =
  // right, once calibration has learned _leftSign. Null before that.
  _leftYaw() {
    const rel = this._relYaw();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },
  // Centered on BOTH axes: |yaw| < 10 deg AND |pitch| < 10 deg.
  _isCentered() {
    const ry = this._relYaw();
    const rp = this._relPitch();
    if (ry === null || rp === null) return false;
    return Math.abs(ry) < CENTER_DEG && Math.abs(rp) < CENTER_DEG;
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

  // ---- game flow ------------------------------------------------------
  _beginGame() {
    // Recalibrate: head straight NOW is the center for this game;
    // the left sign is then learned by the one calibration prompt.
    this._center = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._centerSet = true;
    this._leftSign = null;
    this._cycle = 0;
    this._completed = 0;
    this._sub = 'calibTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。先校准：请向左转一下。眼镜测不到呼吸，语音只定节奏。');
    this.setData({ foot: 'EVT: game started, center calibrated, awaiting left-calibration turn' });
    this._render();
  },

  _cuedSide() {
    return SEQ[this._cycle - 1] || 'left';
  },
  _sideWord() {
    return this._cuedSide() === 'left' ? '左' : '右';
  },
  _sideArrow() {
    return this._cuedSide() === 'left' ? '←' : '→';
  },

  // Start one cycle's inhale. CENTER-PASS RULE (documented): if the
  // head is still turned (previous return missed) when the inhale
  // starts, the new turn does NOT count until the head first passes
  // through center (|yaw| < 10 deg). A still-turned head is never
  // silently counted as a new turn.
  _startInhale() {
    this._turnAchieved = false;
    this._returnAchieved = false;
    this._centerPassedInhale = this._isCentered();
    this._sub = 'inhale';
    this._phaseSince = Date.now();
    this._speak('吸气，慢慢向' + this._sideWord() + '转');
    this.setData({ foot: 'EVT: cycle ' + this._cycle + ' inhale, cue ' + this._cuedSide() });
    this._render();
  },

  _startExhale() {
    this._sub = 'exhale';
    this._phaseSince = Date.now();
    this._speak('呼气，慢慢回正');
    this.setData({ foot: 'EVT: cycle ' + this._cycle + ' exhale' });
    this._render();
  },

  _endCycle() {
    const ok = this._turnAchieved && this._returnAchieved;
    if (ok) {
      this._completed++;
      this._speak('这一轮跟上了');
    } else {
      this._speak('这一轮没跟上，没关系，下一轮');
    }
    if (this._cycle >= CYCLES) {
      this._phase = 'done';
      this._stopTimer();
      this._speak('呼吸转头完成，跟上 ' + this._completed + ' 轮，共 8 轮。');
      this.setData({ foot: 'EVT: DONE breathe-turn ' + this._completed + '/' + CYCLES });
      this._render();
      return;
    }
    this._cycle++;
    this._sub = 'pause';
    this._phaseSince = Date.now();
    this.setData({ foot: 'EVT: cycle done, 1s pause before cycle ' + this._cycle });
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real cycle. One
  // tap per phase: calibration steps, then inhale (demo turn),
  // exhale (demo return, cycle counts as demo-completed), next
  // cycle — so the playing and done states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration turn (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._cycle = 1;
      this._sub = 'inhale';
      this.setData({ foot: 'EVT: DEMO calibration return (sensor SKIP)' });
    } else if (this._sub === 'inhale') {
      this._turnAchieved = true;
      this._sub = 'exhale';
      this.setData({ foot: 'EVT: DEMO inhale turn (sensor SKIP)' });
    } else if (this._sub === 'exhale') {
      this._returnAchieved = true;
      this._completed++;
      if (this._cycle >= CYCLES) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done breathe-turn ' + this._completed + '/' + CYCLES + ' (sensor SKIP)' });
      } else {
        this._cycle++;
        this._sub = 'inhale';
        this._turnAchieved = false;
        this._returnAchieved = false;
        this.setData({ foot: 'EVT: DEMO cycle done, next cycle ' + this._cycle + ' (sensor SKIP)' });
      }
    } else if (this._sub === 'pause') {
      this._sub = 'inhale';
      this.setData({ foot: 'EVT: DEMO pause skipped (sensor SKIP)' });
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginGame(); return; }
    if (this._phase === 'done') { this._beginGame(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoStep(); return; }
    this._speak(this._currentInstruction());
  },

  _currentInstruction() {
    if (this._sub === 'calibTurn') return '请向左转一下，幅度小一点';
    if (this._sub === 'calibReturn') return '回正到中间';
    if (this._sub === 'inhale') return '吸气，慢慢向' + this._sideWord() + '转';
    if (this._sub === 'exhale') return '呼气，慢慢回正';
    return '跟着呼吸，慢慢转';
  },

  // ---- tick: the breath-cycle state machine ---------------------------
  _startTimer() {
    if (this._timer) return;
    const self = this;
    this._timer = setInterval(function () { self._tick(); }, TICK_MS);
  },
  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  _tick() {
    if (this._phase !== 'playing') return; // done: further turning ignored
    const rel = this._relYaw();
    if (rel === null) return; // sensor SKIP: demo button drives the game
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
      if (this._isCentered()) {
        // Re-center on the returned head position, then cycle 1.
        this._center = this._yaw;
        this._pitchCenter = this._pitch;
        this._cycle = 1;
        this._reprompted = false;
        this._startInhale();
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- breath phases: leftYaw is positive-left once calibrated ------
    const ly = this._leftYaw();
    if (ly === null) return;

    if (this._sub === 'pause') {
      if (now - this._phaseSince >= PAUSE_MS) this._startInhale();
      else this._render();
      return;
    }

    if (this._sub === 'inhale') {
      // Center-pass rule: a still-turned head must pass center first.
      if (Math.abs(rel) < CENTER_DEG) this._centerPassedInhale = true;
      if (this._centerPassedInhale && !this._turnAchieved) {
        const reached = (this._cuedSide() === 'left') ? (ly >= TURN_DEG) : (ly <= -TURN_DEG);
        if (reached) {
          this._turnAchieved = true;
          this.setData({ foot: 'EVT: cycle ' + this._cycle + ' turn achieved' });
        }
      }
      if (now - this._phaseSince >= INHALE_MS) this._startExhale();
      this._render();
      return;
    }

    if (this._sub === 'exhale') {
      // Return counts the moment both axes are inside the center band.
      if (!this._returnAchieved && this._isCentered()) {
        this._returnAchieved = true;
        this.setData({ foot: 'EVT: cycle ' + this._cycle + ' return achieved' });
      }
      if (now - this._phaseSince >= EXHALE_MS) this._endCycle();
      this._render();
      return;
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, phaseLine, countLine, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      phaseLine = '吸气转头 · 呼气回正';
      countLine = '8 次呼吸 · 左右交替';
      hint = '单击开始 · 语音定节奏';
      safety = '吸气慢慢转到一侧，呼气慢慢回正，每次呼吸只转一边，绝不转圈、不左右连甩、不憋气、不刻意深呼吸——按自己舒服的节奏呼吸，语音只定节奏。慢、小幅度、到微酸即止。痛、晕、麻、恶心、喘不上气立刻停。先坐稳 / 站稳。注意：眼镜测不到呼吸，语音只定节奏，测的只是转头和回正。本游戏是日常活动娱乐，不是医疗诊断、治疗、康复或呼吸疗法；颈椎病、眩晕、术后、头颈伤史、呼吸或心脏问题请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成' : '完成';
      phaseLine = '呼吸转头';
      countLine = this._demoUsed
        ? '演示跟上 ' + this._completed + ' / 8 轮（演示）'
        : '跟上 ' + this._completed + ' / 8 轮';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibTurn') {
        big = '请向左转一下';
        phaseLine = '校准：学哪边是左';
        countLine = '校准中 · 不计数';
        hint = '只校准一次：慢慢向左转，幅度小一点';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibReturn') {
        big = '回正到中间';
        phaseLine = '校准：回正到中间';
        countLine = '校准中 · 不计数';
        hint = '慢慢转回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._sub === 'inhale') {
        big = '吸气 · 向' + this._sideWord() + '转 ' + this._sideArrow();
        phaseLine = '吸气 4 秒 · 慢慢转到一侧';
        countLine = '第 ' + this._cycle + ' / 8 次呼吸 · 跟上 ' + this._completed + ' 轮';
        hint = '跟着呼吸，慢慢转';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示吸气转头' : '朗读';
      } else if (this._sub === 'exhale') {
        big = '呼气 · 回正';
        phaseLine = '呼气 4 秒 · 慢慢回正';
        countLine = '第 ' + this._cycle + ' / 8 次呼吸 · 跟上 ' + this._completed + ' 轮';
        hint = '跟着呼吸，慢慢转';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示呼气回正' : '朗读';
      } else {
        big = '下一轮…';
        phaseLine = '停 1 秒 · 下一轮马上开始';
        countLine = '第 ' + this._cycle + ' / 8 次呼吸 · 跟上 ' + this._completed + ' 轮';
        hint = '跟着呼吸，慢慢转';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示下一轮' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [big, phaseLine, countLine, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      phaseLine: phaseLine,
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
    <div class="title">呼吸转头 BREATHE TURN</div>
    <div class="big">{{ big }}</div>
    <div class="phase">{{ phaseLine }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">吸气转头 · 呼气回正 · 一次呼吸只转一边 · 不转圈 · 眼镜测不到呼吸，语音只定节奏</div>
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
.phase {
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
