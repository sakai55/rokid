<script def>
{
  "title": "Pace Turn"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Pace Turn （匀速转头） — head-movement mini-game GA23, Wave 2,
// Group E (precision control). EXTREME simplicity: one page, three
// states only (ready / playing / done). 6 turns, fixed alternating
// sides L,R,L,R,L,R: voice calls one side ("向左，匀速转") and the
// player turns from center to that side's edge (27 deg) — the turn
// counts ONLY if it takes 3.0-5.0 s from leaving the center zone
// (|yaw| > 10 deg toward the called side) to reaching 27 deg.
// Faster than 3.0 s = fail ("太快了"); the clock passing 5.0 s
// before reaching = fail at once ("太慢了"); turning past 15 deg
// to the opposite side = fail at once ("方向反了"); backing into
// the center zone (<10 deg) before reaching = fail ("没转到底").
// After every turn the player returns to center before the next
// call. Voice (TTS) does the rest. No menus, no settings, no
// levels, no camera, no mic/ASR, no storage, no network.
//
// DISTINCT FROM GA15 (slow-scan): GA15 is ONE continuous
// left-to-right pass with an 8 s minimum — only a lower bound, and
// no return between sides. This game is SINGLE turns from center,
// each with a 3-5 s pace WINDOW: too fast fails AND too slow
// fails, and every turn starts from and returns to center.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. Only segmented motion:
// center -> one direction -> return to center -> next turn. Never
// continuous circling, never sweep from one extreme to another,
// never fast jerking. This game is about turning SLOWLY and
// EVENLY: a fast turn is a failed turn by design, speed is never
// rewarded. Slow, small range, stop at mild stretch, never pain.
// Stop at once on pain / dizziness / numbness / nausea. Sit or
// stand steady first. One round set is 6 turns, short. This is
// entertainment / daily activity, NOT medical diagnosis,
// treatment or a rehab prescription; people with cervical
// disease, vertigo, post-op or head/neck injury history should
// ask a doctor first.
//
// HOW A TURN IS SCORED (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt inside the playing state (not an extra
// state), GA02's pattern: "请向左转一下" learns LEFT (RIGHT =
// opposite yaw sign). Nothing counts before calibration
// completes; restart re-runs it. Per turn: TTS calls one side
// ("向左，匀速转"); the pace clock starts the moment the relative
// yaw leaves the center zone (>10 deg toward the called side) and
// stops when the yaw reaches 27 deg toward that side. Elapsed
// 3.0-5.0 s inclusive = on pace (+1, "节奏正好"). Elapsed <3.0 s
// = fail ("太快了"). Clock passing 5.0 s before reaching = fail
// at once ("太慢了") — the deadline is checked before the reach
// on any tick past 5.0 s. Opposite side past 15 deg = fail at
// once ("方向反了"), checked before and during the turn. Backing
// inside 10 deg before reaching, after the clock started = fail
// ("没转到底"). After every turn (counted or failed) the player
// MUST return to center (<10 deg on BOTH axes, pitch and yaw)
// before the next call: if not returned within 4 seconds, TTS
// prompts "请回正" and the grace timer resets — the grace counts
// nothing and the next call is NEVER announced until the return
// actually happens (GA10/GA13's stricter rule). The final turn
// ends the game at once: there is no next turn for a return to
// gate. The fixed side list is NOT random, so preview and device
// behaviour are reproducible: L,R,L,R,L,R. Every turn is
// separated by a return to center, so no circling arises. No
// mid-turn cue is spoken: TTS stays minimal by design. Sensor
// missing (web preview) = SKIP/demo state, never a fake pass: the
// screen says so, and the main button becomes a labeled DEMO
// stepper (calibration steps, then one tap per whole turn as an
// on-pace turn, return collapsed) so the playing/done states can
// be previewed. On a real device with a sensor there is no DEMO
// path at all.
// -------------------------------------------------------------------

const TOTAL = 6;
const TARGET_DEG = 27;    // side edge: reach 27 deg toward the called side
const CENTER_DEG = 10;    // center zone: |yaw| <= 10 deg; clock starts past it
const WRONG_DEG = 15;     // opposite side past 15 deg = fail at once
const PACE_MIN_MS = 3000; // on-pace window: 3.0 s ...
const PACE_MAX_MS = 5000; // ... to 5.0 s inclusive
const CALIB_DEG = 27;     // calibration turn threshold (learn the left sign)
const RETURN_GRACE_MS = 4000; // return grace: TTS "请回正", timer resets, no advance
const STALL_MS = 8000;    // idle call / calibration stall -> one TTS re-prompt
const TICK_MS = 100;
// FIXED side list (not random): left, right, left, right, left, right.
const SIDES = ['left', 'right', 'left', 'right', 'left', 'right'];

export default {
  data: {
    arrow: '·',
    big: '准备',
    countLine: '匀速 0 / 6',
    hint: '单击开始 · 6 次匀速转头，不转圈',
    safety: '匀速转头不转圈：每次只从中间转向一边，用三到五秒慢慢匀速转到边，太快太慢都不算，再回正到中间，下一次才报。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | wait | turning | returning
    this._sub = 'wait';
    this._turn = 0;
    this._score = 0;
    this._sensor = null;
    this._pitch = null;    // latest pitch deg (return gate only)
    this._yaw = null;      // latest yaw deg (formula below)
    this._pitchCenter = 0;
    this._yawCenter = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._leftSign = null; // +1 / -1: which raw yaw sign means LEFT (learned)
    this._clockStart = 0;  // pace clock start (leaving the center zone)
    this._callSince = 0;
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
  // Yaw from the orientation quaternion, same formula as GA02:
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees.
  // Pitch uses the fleet formula (GA01/GA04): pitch =
  // asin(2*(w*x - y*z)), clamped — pitch is read ONLY for the
  // return-to-center gate (both axes <10 deg); the turns
  // themselves are judged on yaw alone, because every called
  // target is a left/right turn. Only the RELATIVE pitch/yaw vs
  // the calibrated center are ever used, so the host's absolute
  // zero never matters.
  //
  // YAW SIGN — learned, not assumed (device verification item):
  // at round start the game asks once ("请向左转一下") and records
  // the sign the head actually moves as LEFT; RIGHT is the
  // opposite sign. A host yaw-sign inversion therefore cannot
  // silently swap left/right. Residual caveat, documented in
  // AGENTS.md and on the device-test checklist: calibration
  // trusts the player to follow that one prompt — turning right
  // instead of left would learn the signs backwards. Fail-safes:
  // nothing counts before calibration completes, the first turn
  // is left again (so a backwards calibration feels wrong at
  // once), and any restart re-runs calibration. No fallback sign
  // is ever guessed.
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

  // Relative pitch / yaw vs calibrated center, wrapped to [-180, 180].
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
  // Signed yaw in "left-positive" space, once calibration has
  // learned the sign. Null before that.
  _leftYaw() {
    const rel = this._relYaw();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },
  // Head back inside the center band on BOTH axes.
  _atCenter(relPitch, relYaw) {
    return Math.abs(relPitch) < CENTER_DEG && Math.abs(relYaw) < CENTER_DEG;
  },
  // Re-center on the head's current position (after the calibration
  // return), so turns are judged from where "straight" is now.
  _recenter() {
    this._pitchCenter = this._pitch;
    this._yawCenter = this._yaw;
  },

  _side() { return SIDES[this._turn]; },
  _sideWord(side) { return side === 'left' ? '左' : '右'; },
  _sideArrow(side) { return side === 'left' ? '←' : '→'; },
  _callText() {
    return '向' + this._sideWord(this._side()) + '，匀速转';
  },
  // Yaw magnitude TOWARD the called side (positive = toward it,
  // negative = toward the wrong side), in degrees.
  _toward(leftYaw) {
    return this._side() === 'left' ? leftYaw : -leftYaw;
  },

  // NOTE: no head-gesture handler, deliberately. The gesture API is officially
  // documented ONLY for 'nod', and nod is not this game's action —
  // left/right turns come from the sensor, never from a gesture event.
  // No onOrientationStabilityChange handler either: this game judges
  // pace timing from sensor yaw, not stillness.

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
    // the left sign is then learned by the one calibration prompt.
    this._pitchCenter = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._yawCenter = (this._hasReading && this._yaw !== null) ? this._yaw : 0;
    this._centerSet = true;
    this._turn = 0;
    this._score = 0;
    this._leftSign = null;
    this._sub = 'calibTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始匀速转头。匀速转头不转圈：每次只从中间转向一边，用三到五秒慢慢转到边，太快太慢都不算，再回正，下一次才报。慢，小幅度。先校准：请向左转一下。');
    this.setData({ foot: 'EVT: round started, center calibrated, awaiting left-calibration turn' });
    this._render();
  },

  _announceTurn() {
    this._sub = 'wait';
    this._callSince = Date.now();
    this._reprompted = false;
    this._speak(this._callText() + '，用三到五秒慢慢转到边');
    this.setData({ foot: 'EVT: turn ' + (this._turn + 1) + '/' + TOTAL + ' call ' + this._side() + ', pace window 3-5 s' });
    this._render();
  },

  // Finish one turn. result: 'pace' (+1, "节奏正好") | 'fast'
  // ("太快了") | 'slow' ("太慢了") | 'wrong' ("方向反了") |
  // 'abort' ("没转到底"). After every turn the player must return
  // to center before the next call (see _tick 'returning'). The
  // final turn ends the game at once: there is no next turn for a
  // return to gate.
  _finishTurn(result) {
    const lines = {
      pace: '节奏正好',
      fast: '太快了',
      slow: '太慢了',
      wrong: '方向反了',
      abort: '没转到底'
    };
    if (result === 'pace') this._score++;
    this._speak(lines[result]);
    if (this._turn >= TOTAL - 1) {
      this._phase = 'done';
      this._stopTimer();
      this.setData({ foot: 'EVT: DONE on-pace ' + this._score + '/' + TOTAL });
    } else {
      this._sub = 'returning';
      this._returnSince = Date.now();
      this.setData({ foot: 'EVT: turn ' + (this._turn + 1) + ' result ' + result + ', score ' + this._score + '/' + TOTAL + ', awaiting return to center' });
    }
    this._render();
  },

  _nextTurn() {
    this._turn++;
    this._announceTurn();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real count. One
  // tap per calibration step, then one tap per whole turn as an
  // on-pace turn (turn + return collapsed) so the playing/done
  // states can be previewed.
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration turn (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._announceTurn();
      this.setData({ foot: 'EVT: DEMO calibration complete (sensor SKIP)' });
    } else {
      this._score++;
      if (this._turn >= TOTAL - 1) {
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done on-pace ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
      } else {
        this._turn++;
        this._announceTurn();
        this.setData({ foot: 'EVT: DEMO on-pace turn, score ' + this._score + '/' + TOTAL + ' (sensor SKIP)' });
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
    if (this._sub === 'calibTurn') return '请向左转一下，幅度小一点';
    if (this._sub === 'calibReturn') return '回正到中间';
    if (this._sub === 'returning') return '回正到中间，下一次等你回正';
    return this._callText() + '，用三到五秒慢慢转到边';
  },

  // ---- tick: the turn state machine ----------------------------------
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
    if (relPitch === null || relYaw === null) return; // sensor SKIP: demo button drives turns
    const now = Date.now();

    // --- calibration: learn which sign means left, count nothing ---
    if (this._sub === 'calibTurn') {
      if (Math.abs(relYaw) >= CALIB_DEG) {
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
        this._announceTurn();
        this.setData({ foot: 'EVT: calibration complete, center re-set, first turn announced' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- return gate: next call waits for a real return -------------
    if (this._sub === 'returning') {
      if (this._atCenter(relPitch, relYaw)) {
        this._nextTurn();
        return;
      }
      if (now - this._returnSince >= RETURN_GRACE_MS) {
        // Grace expired: TTS prompts "请回正" and the timer resets.
        // Nothing is counted by the grace, and the next call is NOT
        // announced until the return actually happens.
        this._speak('请回正，下一次等你回正');
        this._returnSince = now;
        this.setData({ foot: 'EVT: return grace expired, re-prompted 请回正, next turn still gated on return' });
      }
      this._render();
      return;
    }

    // --- turns: leftYaw is positive-left once calibrated ------------
    const ly = this._leftYaw();
    if (ly === null) return;
    const toward = this._toward(ly);

    if (this._sub === 'wait') {
      if (toward <= -WRONG_DEG) {
        // Wrong side past 15 deg before the turn even started:
        // fail at once.
        this._finishTurn('wrong');
        return;
      }
      if (toward > CENTER_DEG) {
        // The pace clock starts the moment the head leaves the
        // center zone toward the called side. Fall through to the
        // turning checks in this same tick, so a flick straight
        // past the edge is judged with ~0 elapsed = too fast.
        this._sub = 'turning';
        this._clockStart = now;
      } else {
        if (!this._reprompted && now - this._callSince >= STALL_MS) {
          this._reprompted = true;
          this._speak(this._callText() + '，用三到五秒慢慢转到边');
          this.setData({ foot: 'EVT: turn idle 8 s, call re-prompted once (no auto-count)' });
        }
        this._render();
        return;
      }
    }

    if (this._sub === 'turning') {
      const elapsed = now - this._clockStart;
      if (toward <= -WRONG_DEG) {
        this._finishTurn('wrong');
        return;
      }
      if (elapsed > PACE_MAX_MS) {
        // The clock passed 5.0 s before the edge was reached: fail
        // at once. The deadline is checked BEFORE the reach, so a
        // head that only crosses 27 deg after 5.0 s is too slow,
        // never on pace.
        this._finishTurn('slow');
        return;
      }
      if (toward >= TARGET_DEG) {
        // Reached the edge inside the deadline: inside the window
        // (3.0-5.0 s inclusive) counts; under 3.0 s is too fast.
        this._finishTurn(elapsed >= PACE_MIN_MS ? 'pace' : 'fast');
        return;
      }
      if (toward < CENTER_DEG) {
        // Backed into the center zone before reaching the edge,
        // after the clock started: the turn is aborted, no count.
        this._finishTurn('abort');
        return;
      }
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let arrow, big, hint, safety, sensorLine, mainBtn;
    const demo = (this._sensorSkip || !this._hasReading);
    if (this._phase === 'ready') {
      arrow = '◎';
      big = '准备';
      hint = '单击开始 · 6 次匀速转头，不转圈';
      safety = '匀速转头不转圈：每次只从中间转向一边，用三到五秒慢慢匀速转到边，太快太慢都不算，再回正到中间，下一次才报。绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      arrow = '◎';
      big = this._demoUsed ? '演示匀速 ' + this._score + ' / 6' : '匀速 ' + this._score + ' / 6';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibTurn') {
        arrow = '←';
        big = '请向左转一下';
        hint = '只校准一次：慢慢向左转，幅度小一点';
        mainBtn = demo ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibReturn') {
        arrow = '◎';
        big = '回正到中间';
        hint = '慢慢转回正前方';
        mainBtn = demo ? '演示回正' : '朗读';
      } else if (this._sub === 'returning') {
        arrow = '◎';
        big = '回正到中间';
        hint = '这一轮完了 · 慢慢转回正前方，下一次等你回正';
        mainBtn = demo ? '演示匀速一次' : '朗读';
      } else if (this._sub === 'turning') {
        arrow = this._sideArrow(this._side());
        big = '向' + this._sideWord(this._side()) + ' · 转…';
        hint = '正在计时 · 匀速，3 到 5 秒转到边';
        mainBtn = demo ? '演示匀速一次' : '朗读';
      } else {
        arrow = this._sideArrow(this._side());
        big = '向' + this._sideWord(this._side()) + ' · 匀速转';
        hint = '匀速，3 到 5 秒 · 太快太慢都不算';
        mainBtn = demo ? '演示匀速一次' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [arrow, big, this._score + '/' + TOTAL, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      arrow: arrow,
      big: big,
      countLine: '匀速 ' + this._score + ' / ' + TOTAL,
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
    <div class="title">匀速转头 PACE TURN</div>
    <div class="arrow">{{ arrow }}</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-pace" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">一边一轮 · 3–5 秒匀速 · 快慢都不算 · 痛晕立刻停</div>
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
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 2px;
}
.arrow {
  color: #40ff5e;
  font-size: 52px;
  font-weight: bold;
  line-height: 56px;
  text-align: center;
  margin-top: 2px;
}
.big {
  color: #7dff9e;
  font-size: 36px;
  font-weight: bold;
  line-height: 42px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.count {
  color: #40ff5e;
  font-size: 28px;
  font-weight: bold;
  line-height: 32px;
  margin-top: 2px;
}
.hint {
  color: rgba(125, 255, 158, 0.9);
  font-size: 14px;
  line-height: 19px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.safety {
  color: rgba(125, 255, 158, 0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 4px;
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
  justify-content: center;
  margin-top: 8px;
}
.btn-pace {
  width: 300px;
  background-color: #0a2a12;
  color: #7dff9e;
  border: 2px dashed rgba(64, 255, 94, 0.85);
  border-radius: 6px;
  font-size: 16px;
  font-weight: bold;
  letter-spacing: 6px;
  padding: 9px 0;
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
