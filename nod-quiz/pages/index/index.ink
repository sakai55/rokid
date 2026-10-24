<script def>
{
  "title": "Nod Quiz"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Nod Quiz （点头问答） — head-movement mini-game G16, Group C
// (observation/control). EXTREME simplicity: one page, three
// states only (ready / playing / done). Ten fixed yes/no
// questions, one at a time. A gentle nod = YES; a single side
// turn past ~27 deg held ~0.8 s = NO. The playing screen shows
// at most the current question, the question number x/10, the
// score so far, one short hint ("点头=是，转头=否") and the
// verdict line; voice (TTS) does the rest. No menus, no
// settings, no levels, no camera, no mic/ASR, no storage, no
// network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. This game uses only
// small, segmented motions: a gentle nod for YES, a single side
// turn for NO, each followed by a return to center before the
// next question. Never fast jerking, never shaking the head
// back and forth — shaking is explicitly NOT the NO signal
// (see below). Slow, small range, stop at mild stretch, never
// pain. Stop at once on pain / dizziness / numbness / nausea.
// Sit or stand steady first. One game is 10 questions, short.
// This is entertainment / daily activity, NOT medical
// diagnosis, treatment or a rehab prescription; people with
// cervical disease, vertigo, post-op or head/neck injury
// history should ask a doctor first.
//
// THE 10 FIXED QUESTIONS (same order every round, never random;
// every item is unambiguously true or false):
//  1. 水是液体吗 — 是
//  2. 猫会飞吗 — 否
//  3. 一天有24小时吗 — 是
//  4. 太阳从西边升起吗 — 否
//  5. 鱼能在水里呼吸吗 — 是
//  6. 冰是热的吗 — 否
//  7. 一年有12个月吗 — 是
//  8. 人有三只眼睛吗 — 否
//  9. 月亮会自己发光吗 — 否（月光是反射的太阳光，月亮本身不发光）
// 10. 鸟有翅膀吗 — 是
// 5 yes / 5 no, so neither answer can win by guessing one side.
//
// HOW A QUESTION IS ANSWERED (exact, as implemented):
// TTS reads the question and the screen shows it. The player
// has 10 seconds (TIMEOUT_MS = 10000). Correct = +1, voice
// "答对了". Wrong = 0, voice "答错了，正确答案是是 / 否".
// No answer within 10 s = miss, voice "超时了", 0. After the
// verdict the player must RETURN TO CENTER before the next
// question: the next question is NEVER announced until the
// return actually happens (|relative yaw| < 10 deg AND
// |relative pitch| < 10 deg). If the head is not back within
// 4 s, TTS prompts "请回正", then repeats every 4 s until the
// return happens. Done shows correct x/10 and "再来一局"
// (tap restarts, same questions in the same order).
//
// YES / NO SIGNALS — PRIMARY vs FALLBACK, AND WHAT NO IS NOT
// (technical honesty, the core of this game):
// YES, PRIMARY: onHeadGesture('nod'), officially documented
// for 'nod' — the primary YES signal; it catches gentle nods.
// YES, FALLBACK: pitch from AbsoluteOrientationSensor (G01
// formula, relative to the center calibrated at round start):
// pitch down past ~20 deg and back inside 10 deg counts as one
// fallback nod, for hosts that do not deliver the nod event.
// A gentle real nod may not reach 20 deg — the fallback needs
// a CLEAR nod, and that limit is documented, not hidden.
// NO: there is NO documented shake gesture — onHeadGesture is
// officially documented ONLY for 'nod', so NO is NEVER claimed
// as a shake event and shaking the head back and forth is
// explicitly NOT the NO signal. NO is detected from the sensor
// only: turn the head to EITHER side past ~27 deg yaw
// (absolute value vs the calibrated center, so the left/right
// sign does not matter for NO) and hold ~0.8 s. A turn that
// drops back below 22 deg before 0.8 s resets the hold.
// MUTUAL EXCLUSION: YES and NO are mutually exclusive per
// question — the first valid signal wins (_answered guard +
// the question/returnwait sub-state). A nod and a side turn in
// the same question window cannot both count, and after an
// answer, further signals are ignored until the next question.
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a
// labeled DEMO answer stepper ("演示回答") that submits the
// correct answer for the current question, so the playing and
// done states can be previewed. On a real device with a nod
// event there is no DEMO path at all; tap during playing only
// re-speaks the question (or "请回正" while waiting for the
// return) and NEVER answers — an answer is nod/turn-only, so a
// tap cannot cheat a question. If a real device had no sensor
// readings at all, NO could not be detected (it needs the
// sensor) while YES via the nod event still would work, and
// the return gate would auto-pass after a short feedback delay
// (same as demo) instead of blocking forever — documented,
// not hidden.
// -------------------------------------------------------------------

const TOTAL = 10;
const TIMEOUT_MS = 10000; // per-question answer window
const NO_DEG = 27;        // NO: |relative yaw| past 27 deg
const NO_HOLD_MS = 800;   // NO: hold ~0.8 s at/above 27 deg
const NO_RESET_DEG = 22;  // NO hold resets below 22 deg (hysteresis)
const RETURN_DEG = 10;    // return to center: |yaw| and |pitch| < 10 deg
const RETURN_PROMPT_MS = 4000; // "请回正" first prompt, then every 4 s
const DEMO_ADVANCE_MS = 1200;  // demo/sensorless return auto-pass delay
const TICK_MS = 50;
const FALL_DOWN_DEG = 20; // fallback nod: pitch down past 20 deg
const CENTER_DEG = 10;    // fallback nod: return inside 10 deg
const QUESTIONS = [
  { q: '水是液体吗', a: true },
  { q: '猫会飞吗', a: false },
  { q: '一天有24小时吗', a: true },
  { q: '太阳从西边升起吗', a: false },
  { q: '鱼能在水里呼吸吗', a: true },
  { q: '冰是热的吗', a: false },
  { q: '一年有12个月吗', a: true },
  { q: '人有三只眼睛吗', a: false },
  { q: '月亮会自己发光吗', a: false },
  { q: '鸟有翅膀吗', a: true }
];

export default {
  data: {
    big: '准备',
    countLine: '共 10 题 · 答对 0',
    resultLine: '',
    hint: '单击开始 · 共 10 道是非题',
    safety: '只轻轻点头答“是”，只向一侧转头答“否”，答完回正再答下一题。不转圈、不甩头、不左右摇头、不快动。先坐稳 / 站稳。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    this._sub = 'question'; // question | returnwait (inside playing only)
    this._q = 0;            // current question number 1..10 (0 = none)
    this._score = 0;
    this._answered = false; // mutual exclusion: one verdict per question
    this._qStart = 0;
    this._noHoldStart = 0;  // 0 = no NO hold in progress
    this._returnAt = 0;
    this._lastPromptAt = 0;
    this._lastResult = '';
    this._sensor = null;
    this._yaw = null;
    this._pitch = null;
    this._centerYaw = 0;
    this._centerPitch = 0;
    this._hasReading = false;
    this._sensorSkip = false;
    this._fallDown = false; // fallback nod: currently past 20 deg down
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

  // ---- orientation sensor (NO detection + return gate + fallback ---
  // ---- nod). Yaw from the G15 formula, pitch from the G01 formula,
  // both relative to the center calibrated at round start, so the
  // host's absolute zero never matters. NO uses |yaw| only, so a
  // host yaw-sign inversion cannot swap the NO direction — either
  // side counts as NO by design. DOWN-SIGN ASSUMPTION (device
  // verification item, same as G01): head-down is taken as
  // negative relative pitch. If the sign is inverted on device,
  // the fallback nod simply never fires — it fails safe as "no
  // fallback YES", never as a wrong YES — while the primary nod
  // event still works.
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
    } catch (e) {
      this._sensorSkip = true;
      this._render();
    }
  },
  _stopSensor() {
    if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; }
  },

  _relYaw() {
    if (!this._hasReading || this._yaw === null) return null;
    let d = this._yaw - this._centerYaw;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },
  _relPitch() {
    if (!this._hasReading || this._pitch === null) return null;
    let d = this._pitch - this._centerPitch;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },
  _isCentered() {
    const y = this._relYaw();
    const p = this._relPitch();
    if (y === null || p === null) return false;
    return Math.abs(y) < RETURN_DEG && Math.abs(p) < RETURN_DEG;
  },

  // ---- YES signal ---------------------------------------------------
  // PRIMARY: the officially documented 'nod' gesture event. It is
  // accepted only while a question is open and unanswered; in
  // every other state (ready / returnwait / done / already
  // answered) it is ignored, so a nod can never leak into the
  // next question and can never double-count with a NO turn.
  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || event.gesture || '';
    if (g !== 'nod') return;
    this._answer(true, false);
  },

  // One question, one verdict. The first valid signal wins: after
  // any verdict _answered is true and the sub-state leaves
  // 'question', so a second signal (nod or turn) in the same
  // window is ignored until the next question starts.
  _answer(yes, isDemo) {
    if (this._phase !== 'playing') return;
    if (this._sub !== 'question') return;
    if (this._answered) return;
    this._answered = true;
    const cur = QUESTIONS[this._q - 1];
    const correct = (yes === cur.a);
    const word = cur.a ? '是' : '否';
    if (correct) {
      this._score++;
      this._lastResult = '答对了';
      this._speak('答对了');
    } else {
      this._lastResult = '答错了，正确答案是' + word;
      this._speak('答错了，正确答案是' + word);
    }
    this.setData({ foot: 'EVT: Q' + this._q + ' answer ' + (yes ? 'YES' : 'NO') + (isDemo ? ' (demo)' : '') + ' -> ' + (correct ? 'CORRECT' : 'WRONG') + ', score ' + this._score });
    this._toReturnWait();
  },

  _timeout() {
    if (this._phase !== 'playing') return;
    if (this._sub !== 'question') return;
    if (this._answered) return;
    this._answered = true;
    this._lastResult = '超时了';
    this._speak('超时了');
    this.setData({ foot: 'EVT: Q' + this._q + ' TIMEOUT at 10 s, miss, score ' + this._score });
    this._toReturnWait();
  },

  // After every verdict (right, wrong or timeout) the player must
  // return to center before the next question. Nothing advances
  // from here except an actual return (or the demo/sensorless
  // auto-pass in the tick).
  _toReturnWait() {
    this._sub = 'returnwait';
    this._returnAt = Date.now();
    this._lastPromptAt = this._returnAt;
    this._noHoldStart = 0;
    this._fallDown = false;
    this._render();
  },

  _nextOrFinish() {
    if (this._q >= TOTAL) { this._finish(); return; }
    this._startQuestion(this._q + 1);
  },

  _startQuestion(n) {
    this._q = n;
    this._sub = 'question';
    this._answered = false;
    this._qStart = Date.now();
    this._noHoldStart = 0;
    this._fallDown = false;
    this._lastResult = '';
    this._speak(QUESTIONS[n - 1].q);
    this.setData({ foot: 'EVT: Q' + n + ' asked, 10 s window' });
    this._render();
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
    // Recalibrate: head straight NOW is the center for this round
    // (NO-turn and return-gate reference; the primary nod event
    // needs no calibration).
    this._centerYaw = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerPitch = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._score = 0;
    this._demoUsed = false;
    this._phase = 'playing';
    this._startTimer();
    this._speak('开始');
    this.setData({ foot: 'EVT: round started, center calibrated' });
    this._startQuestion(1);
  },

  _finish() {
    this._phase = 'done';
    this._stopTimer();
    this._speak('结束，答对 ' + this._score + ' 道，满分 10 道');
    this.setData({ foot: 'EVT: DONE score ' + this._score + '/' + TOTAL });
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // A demo tap submits the CORRECT answer for the current
  // question — labeled as demo everywhere it appears, never a
  // real answer — so the playing and done states can be
  // previewed. The return gate auto-passes in demo (tick).
  _demoAnswer() {
    this._demoUsed = true;
    this._answer(QUESTIONS[this._q - 1].a, true);
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) {
      if (this._sub === 'question') { this._demoAnswer(); return; }
      this._nextOrFinish(); // demo: advance early from return-wait
      return;
    }
    // Real device: tap only re-speaks — it NEVER answers.
    // An answer is nod/turn-only, so a tap cannot cheat.
    if (this._sub === 'question') this._speak(QUESTIONS[this._q - 1].q);
    else this._speak('请回正');
  },

  // ---- tick: question window / NO hold / fallback nod / return -----
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
    const now = Date.now();

    if (this._sub === 'returnwait') {
      // Demo / sensorless: auto-pass after a short feedback delay
      // instead of blocking forever on a return that cannot be
      // measured. Real device with readings: only a real return
      // advances — the next question is NEVER announced early.
      if (this._sensorSkip || !this._hasReading) {
        if (now >= this._returnAt + DEMO_ADVANCE_MS) this._nextOrFinish();
        return;
      }
      if (this._isCentered()) { this._nextOrFinish(); return; }
      if (now - this._lastPromptAt >= RETURN_PROMPT_MS) {
        this._lastPromptAt = now;
        this._speak('请回正');
        this.setData({ foot: 'EVT: Q' + this._q + ' waiting for return, prompted 请回正' });
        this._render();
      }
      return;
    }

    // question open:
    if (now >= this._qStart + TIMEOUT_MS) {
      this._timeout();
      return;
    }

    if (!this._sensorSkip) {
      // NO detection: |relative yaw| past 27 deg, held 0.8 s.
      // Dropping below 22 deg resets the hold. Sign-free: either
      // side counts, so yaw-sign inversion cannot break NO.
      const relYaw = this._relYaw();
      if (relYaw !== null && !this._answered) {
        const ay = Math.abs(relYaw);
        if (ay >= NO_DEG) {
          if (!this._noHoldStart) this._noHoldStart = now;
          else if (now - this._noHoldStart >= NO_HOLD_MS) {
            this._answer(false, false);
            return;
          }
        } else if (ay < NO_RESET_DEG) {
          this._noHoldStart = 0;
        }
      }
      // FALLBACK nod: pitch down past 20 deg, then back inside
      // 10 deg = one fallback nod. Only while the question is
      // open and unanswered; _answer() itself enforces the
      // one-verdict guard, so a fallback nod arriving together
      // with a primary nod event can still only verdict once.
      if (!this._answered) {
        const relPitch = this._relPitch();
        if (relPitch !== null) {
          if (!this._fallDown && relPitch <= -FALL_DOWN_DEG) {
            this._fallDown = true;
          } else if (this._fallDown && Math.abs(relPitch) < CENTER_DEG) {
            this._fallDown = false;
            this._answer(true, false);
            return;
          }
        }
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, countLine, resultLine, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      countLine = '共 10 题 · 答对 0';
      resultLine = '';
      hint = '单击开始 · 共 10 道是非题';
      safety = '只轻轻点头答“是”，只向一侧转头答“否”，答完回正再答下一题。不转圈、不甩头、不左右摇头、不快动。先坐稳 / 站稳。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示答对 ' + this._score + ' / 10' : '答对 ' + this._score + ' / 10';
      countLine = '答对 ' + this._score + ' / 10';
      resultLine = '';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局';
      safety = '';
      mainBtn = '再来一局';
    } else {
      big = QUESTIONS[this._q - 1].q;
      countLine = '第 ' + this._q + ' / 10 题 · 答对 ' + this._score;
      if (this._sub === 'question') {
        resultLine = '';
        hint = '点头=是，转头=否';
      } else {
        resultLine = this._lastResult;
        hint = '答完请回正到中间，再出下一题';
      }
      safety = '';
      mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回答' : '朗读';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）· 点头事件为主信号，转头否演示代替';
    else if (!this._hasReading) sensorLine = '传感器：等待读数… · 点头事件为主，转头超27°停0.8秒为否';
    else sensorLine = '传感器：方向传感器已连接 · 点头事件为主，转头超27°停0.8秒为否';
    const key = [big, countLine, resultLine, hint, safety, sensorLine, mainBtn, this._phase, this._sub, this._q, this._score].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: countLine,
      resultLine: resultLine,
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
    <div class="title">点头问答 NOD QUIZ</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="result">{{ resultLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">点头=是 · 转头=否 · 不摇头 · 不转圈 · 痛晕立刻停</div>
  </div>
</template>

<style>
.page {
  width: 480px;
  height: 352px;
  background-color: #000000;
  padding: 10px 18px;
  box-sizing: border-box;
}
.title {
  color: #40ff5e;
  font-size: 18px;
  font-weight: bold;
  letter-spacing: 2px;
  line-height: 20px;
}
.big {
  color: #ffffff;
  font-size: 30px;
  font-weight: bold;
  line-height: 30px;
  margin-top: 4px;
  white-space: nowrap;
  overflow: hidden;
}
.count {
  color: #40ff5e;
  font-size: 24px;
  font-weight: bold;
  line-height: 24px;
  margin-top: 2px;
}
.result {
  color: #ffffff;
  font-size: 20px;
  font-weight: bold;
  line-height: 22px;
  margin-top: 4px;
  min-height: 22px;
}
.hint {
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  line-height: 19px;
  margin-top: 4px;
  white-space: nowrap;
  overflow: hidden;
}
.safety {
  color: rgba(255, 255, 255, 0.75);
  font-size: 11px;
  line-height: 15px;
  margin-top: 4px;
  min-height: 60px;
}
.sensor {
  color: rgba(64, 255, 94, 0.62);
  font-size: 10px;
  line-height: 13px;
  margin-top: 4px;
  white-space: nowrap;
  overflow: hidden;
}
.btnrow {
  display: flex;
  flex-direction: row;
  margin-top: 6px;
}
.btn {
  flex: 1;
  background-color: #14541f;
  color: #ffffff;
  border: 1px solid rgba(64, 255, 94, 0.72);
  font-size: 16px;
  font-weight: bold;
  padding: 7px 0;
  text-align: center;
}
.foot {
  color: rgba(64, 255, 94, 0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 6px;
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
