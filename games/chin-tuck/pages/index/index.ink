<script def>
{
  "title": "Chin Tuck"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Chin Tuck （收下巴） — head-movement mini-game GA06, closing Group A
// (neck exercises). EXTREME simplicity: one page, three states only
// (ready / playing / done). The screen shows at most a big
// instruction, a count x/8 and one short hint while playing
// (including the hold countdown); voice (TTS) does the rest. No
// menus, no settings, no levels, no camera, no mic/ASR, no storage,
// no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> hold -> return to center -> next.
// Never continuous circling, never sweep from one extreme to
// another, never fast jerking. Slow, small range, stop at mild
// stretch, never pain. For chin-tuck specifically: a SMALL
// horizontal glide only — the chin slides straight back, like
// making a slight double chin; the head does NOT tilt down and
// does NOT nod. The voice guidance says this distinction
// explicitly: 「不是低头，是下巴水平往后收」. Stop at once on
// pain / dizziness / numbness / nausea. Sit or stand steady
// first. One round is 60-180 s. This is entertainment / daily
// activity, NOT medical diagnosis, treatment or a rehab
// prescription; people with cervical disease, vertigo, post-op or
// head/neck injury history should ask a doctor first.
//
// HOW A REP IS COUNTED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt: "请低一下头". Whichever pitch sign the head
// actually moves is learned as DOWN (GA01/GA04 pattern); the tuck
// itself uses that same pitch direction at SMALL amplitude. Each
// rep: glide into the small tuck band -> hold the full 5 s
// (spoken countdown 5-4-3-2-1) -> return to center = 1 rep,
// spoken by TTS ("下巴轻轻往后收，像点头的一半还不到，稳住，
// 5、4、3、2、1，放松"). Releasing early counts nothing. A FULL
// NOD counts nothing: pitch beyond the tuck band's upper bound is
// "too far" and is told "幅度小一点，这是收下巴不是低头". A move
// without a return never counts. If a rep stalls, TTS re-prompts
// ONCE and never auto-counts. Sensor missing (web preview) =
// SKIP/demo state, never a fake pass: the screen says so, and the
// main button becomes a labeled DEMO stepper so the playing/done
// states can be previewed. On a real device with a sensor, there
// is no DEMO path at all.
//
// TUCK VS NOD — the whole point of this game, and its honest
// limit: a chin tuck is mostly a horizontal translation, which an
// orientation sensor barely sees. This game therefore detects the
// tuck as a SMALL pitch motion in the learned down direction,
// cued as "像点头的一半还不到": the player glides the chin back
// with only the smallest nod-like component. The device-test
// checklist must confirm a natural tuck lands in the 14-20 deg
// band; if real tucks systematically under-register, the
// threshold — not the motion — gets adjusted. A full nod is
// rejected by the upper bound, never counted as a tuck.
// -------------------------------------------------------------------

const TOTAL = 8;
const CALIB_DEG = 27;     // calibration look-down: 25-30 deg pitch (GA01/GA04)
const TUCK_DEG = 14;      // tuck reached: small pitch-down-equivalent, 12-15 deg
const TOO_FAR_DEG = 20;   // beyond this = a full nod, counts nothing
const CENTER_DEG = 8;     // return-to-center band: <8 deg pitch
const HOLD_MS = 5000;     // hold the full 5 s, spoken countdown
const STALL_MS = 8000;    // rep stall -> one TTS re-prompt, never auto-count
const TICK_MS = 100;

export default {
  data: {
    big: '准备',
    countLine: '0 / 8',
    hint: '单击开始 · 收下巴 8 次，每次稳住 5 秒',
    safety: '不是低头，是下巴水平往后收：下巴轻轻往后平移，像轻轻做一个双下巴，头不往下点、不点头。收 → 稳住 5 秒 → 放松回正，做 8 次。慢、小幅度、到微酸即止。幅度小一点：点头的一半还不到，低头太多不算。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | wait | tucked | held
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
    this._holdAccum = 0;   // accumulated steady hold time in the tuck band
    this._lastCountNum = 0;
    this._stallSince = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._timer = null;
    this._tooFar = false;
    this._wrongDir = false;
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
  // Pitch from the orientation quaternion, same formula as GA01/GA04
  // (fleet-consistent):
  // pitch = asin(2*(w*x - y*z)), clamped. Only the RELATIVE pitch vs
  // the calibrated center is ever used, so the host's absolute zero
  // never matters.
  //
  // PITCH-SIGN — learned, not assumed: at round start the game asks
  // once ("请低一下头") and records the sign the head actually moves
  // as DOWN. The tuck uses that same pitch direction at SMALL
  // amplitude (14-20 deg, not the 27 deg exercise range), because a
  // tuck is a small motion: a full nod would overshoot the band and
  // be rejected as too far. Residual caveat, documented in
  // AGENTS.md and on the device-test checklist: calibration trusts
  // the player to follow that one prompt — looking up instead of
  // down would learn the sign backwards. The fail-safe is that
  // nothing counts before calibration completes, and restarting
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

  // True when the head is inside the small tuck band (not too far).
  _inTuck(dp) {
    return dp >= TUCK_DEG && dp < TOO_FAR_DEG;
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
  // documented ONLY for 'nod', and a nod must NEVER count as a tuck —
  // so no nod handler exists at all, and the sensor's upper bound
  // (20 deg) rejects a full nod even at the sensor level.

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
    this._tooFar = false;
    this._wrongDir = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。先校准：请低一下头，慢慢低头，到微酸就停。记住，这只是校准，正式动作不是低头，是下巴水平往后收。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting down-calibration tilt' });
    this._render();
  },

  _countRep() {
    this._count++;
    this._rep = 'wait';
    this._reprompted = false;
    this._tooFar = false;
    this._wrongDir = false;
    if (this._count >= TOTAL) {
      this._phase = 'done';
      this._stopTimer();
      this._speak('完成，收下巴 8 次都做完了。');
      this.setData({ foot: 'EVT: DONE ' + this._count + '/' + TOTAL });
    } else {
      this._speak('第' + this._count + '次，下巴轻轻往后收，像点头的一半还不到');
      this.setData({ foot: 'EVT: rep counted ' + this._count + '/' + TOTAL });
    }
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real rep. One tap
  // per calibration step, then one tap per whole rep (tuck + hold +
  // return collapsed) so the playing/done states can be previewed.
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
    if (this._rep === 'tucked') return '稳住';
    if (this._rep === 'held') return '放松，回正到中间';
    return '下巴轻轻往后收，像点头的一半还不到，不是低头';
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
      if (Math.abs(rel) >= CALIB_DEG) {
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
        this._speak('下巴轻轻往后收，像点头的一半还不到，稳住');
        this.setData({ foot: 'EVT: calibration complete, center re-set, first rep tuck' });
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
    this._tooFar = false;
    this._wrongDir = false;
    if (this._rep === 'wait') {
      if (this._inTuck(dp)) {
        this._rep = 'tucked';
        this._holdAccum = 0;
        this._lastCountNum = 5;
        this._stallSince = now;
        this._reprompted = false;
        this._speak('稳住，五');
        this.setData({ foot: 'EVT: tuck band ' + TUCK_DEG + '-' + TOO_FAR_DEG + ' deg reached, hold countdown started' });
      } else if (dp >= TOO_FAR_DEG) {
        // A full nod: too far, counts nothing, corrected — never a tuck.
        this._tooFar = true;
      } else if (dp <= -TUCK_DEG) {
        this._wrongDir = true;
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('下巴轻轻往后收，像点头的一半还不到，不是低头');
        this.setData({ foot: 'EVT: rep stalled, re-prompted once (no auto-count)' });
      }
    } else if (this._rep === 'tucked') {
      if (dp >= TOO_FAR_DEG) {
        // Pushed into a full nod mid-hold: the hold is void, no count.
        this._rep = 'wait';
        this._stallSince = now;
        this._speak('幅度小一点，这是收下巴不是低头，慢慢回正重新来');
        this.setData({ foot: 'EVT: pushed past tuck band into full nod mid-hold, no count' });
      } else if (!this._inTuck(dp) && dp < TUCK_DEG - 3) {
        // Released before the full 5 s hold: aborted, no count.
        this._rep = 'wait';
        this._stallSince = now;
        this._speak('没稳住，重新来，慢一点');
        this.setData({ foot: 'EVT: tuck released before full hold, no count' });
      } else if (this._inTuck(dp)) {
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
          this._speak('放松，回正到中间');
          this.setData({ foot: 'EVT: held ' + HOLD_MS + ' ms' });
        }
      }
    } else if (this._rep === 'held') {
      if (Math.abs(rel) < CENTER_DEG) {
        this._countRep();
        return;
      }
      if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('放松，回正到中间');
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
      hint = '单击开始 · 收下巴 8 次，每次稳住 5 秒';
      safety = '不是低头，是下巴水平往后收：下巴轻轻往后平移，像轻轻做一个双下巴，头不往下点、不点头。收 → 稳住 5 秒 → 放松回正，做 8 次。慢、小幅度、到微酸即止。幅度小一点：点头的一半还不到，低头太多不算。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示完成 8 / 8' : '完成 8 / 8';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与上下）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._rep === 'calibTurn') {
        big = '请低一下头';
        hint = '只校准一次：慢慢低头，到微酸就停（正式动作不是低头）';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示低一下头' : '朗读';
      } else if (this._rep === 'calibReturn') {
        big = '回正到中间';
        hint = '慢慢贴回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._rep === 'tucked') {
        big = '稳住 ' + this._countdownLeft();
        hint = '保持住 · 倒数 ' + this._countdownLeft() + ' · 幅度小一点，不是低头';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示收下巴一次' : '朗读';
      } else if (this._rep === 'held') {
        big = '放松回正';
        hint = '慢慢贴回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示收下巴一次' : '朗读';
      } else {
        big = '收下巴，慢一点';
        hint = this._tooFar
          ? '幅度小一点，这是收下巴不是低头'
          : (this._wrongDir
            ? '仰头了？请收下巴，不是仰头'
            : '下巴水平往后收 → 稳住 5 秒 → 回正 = 1 次 · 不是低头');
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示收下巴一次' : '朗读';
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
    <div class="title">收下巴 CHIN TUCK</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">不是低头，是下巴水平往后收 · 幅度小一点 · 痛晕立刻停</div>
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
