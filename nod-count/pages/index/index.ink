<script def>
{
  "title": "Nod Count"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Nod Count （点头操） — head-movement mini-game G01, EXTREME simplicity.
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
// START calibrates the center (head straight at START). Each rep:
// pitch down past threshold -> hold ~0.8 s -> return to center = 1
// rep, spoken by TTS. A down motion without a return to center never
// counts, and a nod event on its own never double-counts: a nod event
// only completes a rep that the sensor already saw go down, once the
// head is back inside the center band. If a rep stalls, TTS re-prompts
// ONCE ("慢慢回正到中间") and never auto-counts.
// Sensor missing (web preview) = SKIP/demo state, never a fake pass:
// the screen says so, and the main button becomes a labeled DEMO rep
// stepper so the playing/done states can be previewed. On a real
// device with a sensor, there is no DEMO path at all.
// -------------------------------------------------------------------

const TOTAL = 10;
const DOWN_DEG = 27;      // direction reached: 25-30 deg pitch down
const CENTER_DEG = 10;    // return-to-center band: <10 deg
const HOLD_MS = 800;      // hold-steady ~0.8 s
const STALL_MS = 8000;    // rep stall -> one TTS re-prompt, never auto-count
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 10',
    hint: '单击开始 · 共 10 次',
    safety: '分段做，不转圈：低头 → 停 → 回正，再换方向。慢、小幅度、到微酸即止，不甩头。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    this._rep = 'wait';    // wait | down | held
    this._count = 0;
    this._sensor = null;
    this._pitch = null;    // latest pitch deg (benchmark formula, see below)
    this._center = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._stable = false;
    this._stableSeen = false;
    this._downSince = 0;
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
  // Pitch from the orientation quaternion, same formula as the
  // glasses-benchmark guided-interaction test (fleet-consistent):
  // pitch = asin(2*(w*x - y*z)), clamped. Only the RELATIVE pitch vs
  // the calibrated center is ever used, so the host's absolute zero
  // never matters. DOWN-SIGN ASSUMPTION (device verification item):
  // head-down is taken as negative relative pitch; if the first
  // device test shows it inverted, flip DOWN_SIGN — the game already
  // refuses to count an up-tilt as a rep and says so on screen.
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

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    const s = event.stable !== undefined ? event.stable
      : (detail.stable !== undefined ? detail.stable : detail.isStable);
    if (s !== undefined) {
      this._stable = s === true;
      this._stableSeen = true;
    }
  },

  // A nod event never counts on its own: it only completes a rep the
  // sensor already saw go down, once the head is back in the center
  // band. In 'wait' (no down tracked) it is ignored, so it can never
  // double-count a rep the sensor already counted.
  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || event.gesture || '';
    if (g !== 'nod') return;
    if (this._phase !== 'playing') return;
    if (this._rep !== 'down' && this._rep !== 'held') return;
    const rel = this._relPitch();
    if (rel === null || Math.abs(rel) >= CENTER_DEG) return;
    this.setData({ foot: 'EVT: nod event completed a tracked rep' });
    this._countRep();
  },

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
    // Recalibrate: head straight NOW is the center for this round.
    this._center = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._centerSet = true;
    this._count = 0;
    this._rep = 'wait';
    this._reprompted = false;
    this._demoUsed = false;
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。低头，停，回正。');
    this.setData({ foot: 'EVT: round started, center calibrated' });
    this._render();
  },

  _countRep() {
    this._count++;
    this._rep = 'wait';
    this._reprompted = false;
    if (this._count >= TOTAL) {
      this._phase = 'done';
      this._stopTimer();
      this._speak('完成，十次都做完了。');
      this.setData({ foot: 'EVT: DONE ' + this._count + '/' + TOTAL });
    } else {
      this._speak('第' + this._count + '次');
      this.setData({ foot: 'EVT: rep counted ' + this._count + '/' + TOTAL });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real rep.
  _demoRep() {
    this._demoUsed = true;
    this._count++;
    this._rep = 'wait';
    if (this._count >= TOTAL) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DEMO done ' + this._count + '/' + TOTAL + ' (sensor SKIP)' });
    } else {
      this.setData({ foot: 'EVT: DEMO rep ' + this._count + '/' + TOTAL + ' (sensor SKIP)' });
    }
    this._render();
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoRep(); return; }
    this._speak(this._currentInstruction());
  },

  _currentInstruction() {
    if (this._rep === 'down') return '停住';
    if (this._rep === 'held') return '回正到中间';
    return '低头，慢一点';
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
    const down = rel <= -DOWN_DEG;
    const up = rel >= DOWN_DEG;
    if (this._rep === 'wait') {
      if (down) {
        this._rep = 'down';
        this._downSince = now;
        this._stallSince = now;
        this._reprompted = false;
        this._speak('停住');
        this.setData({ foot: 'EVT: down past ' + DOWN_DEG + ' deg' });
      }
    } else if (this._rep === 'down') {
      if (rel > -DOWN_DEG + 5) {
        // Backed off before the hold: aborted, no count.
        this._rep = 'wait';
        this.setData({ foot: 'EVT: down aborted before hold, no count' });
      } else {
        const steadyOk = !this._stableSeen || this._stable;
        if (steadyOk && now - this._downSince >= HOLD_MS) {
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
      if (down) {
        // Dipped down again: still held, keep waiting for center.
        this._stallSince = now;
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: return stalled, re-prompted once (no auto-count)' });
      }
    }
    this._wrongDir = up && this._rep === 'wait';
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      hint = '单击开始 · 共 10 次';
      safety = '分段做，不转圈：低头 → 停 → 回正，再换方向。慢、小幅度、到微酸即止，不甩头。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 10 / 10' : '完成 10 / 10';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._rep === 'down') big = '停住…';
      else if (this._rep === 'held') big = '回正到中间';
      else big = '低头，慢一点';
      if (this._wrongDir) hint = '抬头了？请低头，不是抬头';
      else if (this._rep === 'down') hint = '保持低头，停一下';
      else if (this._rep === 'held') hint = '慢慢抬头，回正到中间';
      else hint = '低头 → 停 → 回正 = 1 次';
      safety = '';
      mainBtn = (this._sensorSkip || !this._hasReading) ? '演示点头一次' : '朗读';
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
    <div class="title">点头操 NOD COUNT</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不转圈 · 不甩头 · 痛晕立刻停</div>
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
