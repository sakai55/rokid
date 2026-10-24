<script def>
{
  "title": "Slow Scan"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Slow Scan （慢速扫描） — head-movement mini-game G15, Group C
// (observation/control). EXTREME simplicity: one page, three
// states only (ready / playing / done). One mechanic: a SINGLE
// slow pass from the left limit to the right limit. Voice (TTS)
// does the rest. No menus, no settings, no levels, no camera,
// no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. This game is ONE slow
// pass from left to right, never a circle, never a sweep back
// and forth, never fast jerking. The whole point is slowness:
// a fast pass does not count. Slow, small range, stop at mild
// stretch, never pain. Stop at once on pain / dizziness /
// numbness / nausea. Sit or stand steady first. One game is a
// single slow pass, replayable, short. This is entertainment /
// daily activity, NOT medical diagnosis, treatment or a rehab
// prescription; people with cervical disease, vertigo, post-op
// or head/neck injury history should ask a doctor first.
//
// HOW A SCAN COUNTS (sensor state machine, no fake counts):
// START calibrates the center (head straight at START), then ONE
// calibration prompt: "请向左转一下". Whichever yaw sign the head
// actually moves is learned as LEFT (G02's proven pattern), so a
// host yaw-sign inversion cannot silently swap left/right.
// Return to center, then: turn to the LEFT limit (past ~27 deg
// left) and hold briefly ("先转到最左，停一下"), then turn slowly
// and continuously to the RIGHT limit (past ~27 deg right).
// The scan counts ONLY if BOTH hold:
//   (a) at least 8 seconds from LEAVING the left limit to
//       reaching the right limit, AND
//   (b) the head passes through center (yaw within +/-10 deg)
//       on the way — a jump straight from left to right that
//       never registers center is a sensor discontinuity, not
//       a scan, and restarts the scan phase.
// Reaching the right limit in under 8 seconds = too fast:
// voice "太快了，回到最左，重新慢扫" and the scan restarts
// (not counted). Reversing mid-scan — returning to the left
// limit (past 27 deg left again) after the scan has started —
// restarts the scan phase with voice "回到最左，重新慢扫".
// While scanning, if the instantaneous yaw speed exceeds
// ~45 deg/s, TTS warns ONCE per scan attempt ("慢一点"). A
// single fast moment does NOT fail the scan: the 8-second rule
// is the fail condition (documented choice — a momentary
// wobble should not punish an otherwise slow pass).
// Reaching the right limit ends the scan AT ONCE (voice
// "到了，停"): the player must NOT continue past it into a
// circle, and any further turning after completion is ignored
// (the tick machine runs only while phase is playing).
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a
// labeled DEMO stepper so the playing/done states can be
// previewed. On a real device with a sensor, there is no DEMO
// path at all.
// -------------------------------------------------------------------

const TURN_DEG = 27;      // left/right limit: 25-30 deg yaw
const CENTER_DEG = 10;    // center band: <10 deg
const HOLD_MS = 800;      // hold briefly at the left limit ~0.8 s
const MIN_SCAN_MS = 8000; // a scan must take at least 8 seconds
const SPEED_WARN_DEG_S = 45; // instantaneous yaw speed warning threshold
const STALL_MS = 8000;    // calibration stall -> one TTS re-prompt
const TICK_MS = 100;
const BAR_CELLS = 20;     // progress bar cells, left (0) to right (full)

export default {
  data: {
    big: '准备',
    bar: '◀ 最左 ············ 最右 ▶',
    countLine: '一次慢扫 · 左 → 右',
    hint: '单击开始 · 一次慢扫就够',
    safety: '只做一次慢扫，不转圈、不来回扫、不甩头：先转到最左停一下，再慢慢转到最右，整个慢扫至少 8 秒，越慢越好。到了最右就停，不要继续转成圈。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    // calibTurn | calibReturn | toLeft | toLeftHold | atLeft | scanning
    this._sub = 'toLeft';
    this._sensor = null;
    this._yaw = null;      // latest yaw deg (formula below)
    this._center = 0;
    this._centerSet = false;
    this._hasReading = false;
    this._sensorSkip = false;
    this._leftSign = null; // +1 / -1: which raw yaw sign means LEFT (learned)
    this._holdSince = 0;
    this._stallSince = 0;
    this._reprompted = false;
    this._demoUsed = false;
    this._demoProgress = 0; // demo scan steps completed (0..3)
    this._scanSince = 0;
    this._scanSeconds = 0;
    this._centerPassed = false;
    this._warned = false;
    this._prevLy = null;
    this._prevT = 0;
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
  // Only the RELATIVE yaw vs the calibrated center is ever used, so
  // the host's absolute zero never matters.
  //
  // YAW-SIGN — learned, not assumed (G02's pattern): at round start
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

  // Signed yaw in "left-positive" space: positive = left, negative =
  // right, once calibration has learned _leftSign. Null before that.
  _leftYaw() {
    const rel = this._relYaw();
    if (rel === null || this._leftSign === null) return null;
    return rel * this._leftSign;
  },

  // Scan progress 0..1: left limit (+27 left-yaw) = 0, right limit
  // (-27) = 1, center = 0.5. Clamped, so overshoot past either limit
  // pins at the bar ends instead of overflowing.
  _progress(leftYaw) {
    const p = (TURN_DEG - leftYaw) / (2 * TURN_DEG);
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
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
    this._centerSet = true;
    this._leftSign = null;
    this._sub = 'calibTurn';
    this._reprompted = false;
    this._demoUsed = false;
    this._demoProgress = 0;
    this._scanSeconds = 0;
    this._centerPassed = false;
    this._warned = false;
    this._prevLy = null;
    this._stallSince = Date.now();
    this._phase = 'playing';
    this._startTimer();
    this._speak('头摆正，开始。先校准：请向左转一下。');
    this.setData({ foot: 'EVT: game started, center calibrated, awaiting left-calibration turn' });
    this._render();
  },

  // Restart the scan phase only (calibration is NOT re-run): the
  // player must go back to the left limit and hold again.
  _restartScan(reason) {
    this._sub = 'toLeft';
    this._scanSeconds = 0;
    this._centerPassed = false;
    this._warned = false;
    this._prevLy = null;
    this._reprompted = false;
    this._speak(reason);
    this.setData({ foot: 'EVT: scan restarted, back to left limit' });
    this._render();
  },

  _finishScan() {
    this._phase = 'done';
    this._stopTimer();
    this._speak('到了，停。慢扫完成，用了' + this._scanSeconds.toFixed(1) + '秒。');
    this.setData({ foot: 'EVT: DONE slow scan ' + this._scanSeconds.toFixed(1) + 's' });
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // Labeled as demo everywhere it appears; never a real scan. One
  // tap per calibration step, one tap to reach the left limit,
  // then one tap per third of the scan so the playing state can
  // be previewed mid-scan; the demo scan completes at a fixed
  // labeled 9.6 seconds (a qualifying slow pass, by construction).
  _demoStep() {
    this._demoUsed = true;
    if (this._sub === 'calibTurn') {
      this._leftSign = 1; // demo assumption, labeled as demo only
      this._sub = 'calibReturn';
      this.setData({ foot: 'EVT: DEMO calibration turn (sensor SKIP)' });
    } else if (this._sub === 'calibReturn') {
      this._sub = 'toLeft';
      this.setData({ foot: 'EVT: DEMO calibration return (sensor SKIP)' });
    } else if (this._sub === 'toLeft' || this._sub === 'toLeftHold') {
      this._sub = 'atLeft';
      this.setData({ foot: 'EVT: DEMO at left limit (sensor SKIP)' });
    } else if (this._sub === 'atLeft') {
      this._sub = 'scanning';
      this._demoProgress = 0;
      this.setData({ foot: 'EVT: DEMO scan started (sensor SKIP)' });
    } else if (this._sub === 'scanning') {
      this._demoProgress++;
      if (this._demoProgress >= 3) {
        this._scanSeconds = 9.6;
        this._phase = 'done';
        this._stopTimer();
        this.setData({ foot: 'EVT: DEMO done slow scan 9.6s (sensor SKIP)' });
      } else {
        this.setData({ foot: 'EVT: DEMO scan progress ' + this._demoProgress + '/3 (sensor SKIP)' });
      }
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
    if (this._sub === 'toLeft' || this._sub === 'toLeftHold') return '先转到最左，停一下';
    if (this._sub === 'atLeft') return '从最左开始，慢慢向右扫';
    return '慢，再慢一点';
  },

  // ---- tick: the scan state machine -----------------------------------
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
      if (Math.abs(rel) < CENTER_DEG) {
        // Re-center on the returned head position, then left limit.
        this._center = this._yaw;
        this._sub = 'toLeft';
        this._reprompted = false;
        this._speak('先转到最左，停一下');
        this.setData({ foot: 'EVT: calibration complete, center re-set, awaiting left limit' });
      } else if (!this._reprompted && now - this._stallSince >= STALL_MS) {
        this._reprompted = true;
        this._speak('慢慢回正到中间');
        this.setData({ foot: 'EVT: calibration return stalled, re-prompted once (no auto-count)' });
      }
      this._render();
      return;
    }

    // --- scan phases: leftYaw is positive-left once calibrated ------
    const ly = this._leftYaw();
    if (ly === null) return;

    if (this._sub === 'toLeft') {
      if (ly >= TURN_DEG) {
        this._sub = 'toLeftHold';
        this._holdSince = now;
        this._speak('停一下');
        this.setData({ foot: 'EVT: left limit reached, holding' });
      }
      this._render();
      return;
    }
    if (this._sub === 'toLeftHold') {
      if (ly < TURN_DEG - 5) {
        // Backed off before the hold: aborted, no scan starts.
        this._sub = 'toLeft';
        this.setData({ foot: 'EVT: left-limit hold aborted before 0.8s, no scan' });
      } else if (now - this._holdSince >= HOLD_MS) {
        this._sub = 'atLeft';
        this._speak('从最左开始，慢慢向右扫');
        this.setData({ foot: 'EVT: left-limit hold done, awaiting departure from left limit' });
      }
      this._render();
      return;
    }
    if (this._sub === 'atLeft') {
      // The scan clock starts when the head LEAVES the left limit
      // (drops below the limit with hysteresis), not at the hold:
      // the hold itself is not scan time.
      if (ly < TURN_DEG - 5) {
        this._sub = 'scanning';
        this._scanSince = now;
        this._scanSeconds = 0;
        this._centerPassed = false;
        this._warned = false;
        this._prevLy = ly;
        this._prevT = now;
        this.setData({ foot: 'EVT: scan started, leaving left limit' });
      }
      this._render();
      return;
    }

    // --- scanning: left limit -> center -> right limit, >= 8 s ------
    if (Math.abs(ly) < CENTER_DEG) this._centerPassed = true;
    // Instantaneous yaw speed: warn once per scan attempt, never fail.
    if (this._prevLy !== null) {
      const dt = Math.max(1, now - this._prevT);
      const speed = Math.abs(ly - this._prevLy) * 1000 / dt;
      if (!this._warned && speed > SPEED_WARN_DEG_S) {
        this._warned = true;
        this._speak('慢一点');
        this.setData({ foot: 'EVT: speed warning once, ' + speed.toFixed(0) + ' deg/s' });
      }
    }
    this._prevLy = ly;
    this._prevT = now;
    this._scanSeconds = (now - this._scanSince) / 1000;
    if (ly >= TURN_DEG) {
      // Reversed back to the left limit mid-scan: restart the scan.
      this._restartScan('回到最左，重新慢扫');
      return;
    }
    if (ly <= -TURN_DEG) {
      // Right limit reached: the scan ends AT ONCE — do not continue
      // past it into a circle. Judge the pass now.
      if (!this._centerPassed) {
        this._restartScan('回到最左，重新慢扫');
        return;
      }
      if (now - this._scanSince < MIN_SCAN_MS) {
        this._restartScan('太快了，回到最左，重新慢扫');
        return;
      }
      this._finishScan();
      return;
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  _barText(progress) {
    const filled = Math.round(progress * BAR_CELLS);
    let s = '◀';
    for (let i = 0; i < BAR_CELLS; i++) s += (i < filled) ? '█' : '·';
    return s + '▶';
  },

  _render() {
    let big, bar, countLine, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      bar = '◀ 最左 ············ 最右 ▶';
      countLine = '一次慢扫 · 左 → 右';
      hint = '单击开始 · 一次慢扫就够';
      safety = '只做一次慢扫，不转圈、不来回扫、不甩头：先转到最左停一下，再慢慢转到最右，整个慢扫至少 8 秒，越慢越好。到了最右就停，不要继续转成圈。慢、小幅度、到微酸即止。痛、晕、麻、恶心立刻停。先坐稳 / 站稳。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示慢扫完成' : '慢扫完成';
      bar = this._barText(1);
      countLine = this._demoUsed
        ? '演示用时 9.6 秒 · 慢扫通过（演示）'
        : '用时 ' + this._scanSeconds.toFixed(1) + ' 秒 · 慢扫通过';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局（重新校准中心与左右）';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._sub === 'calibTurn') {
        big = '请向左转一下';
        bar = '◀ 最左 ············ 最右 ▶';
        countLine = '校准：学哪边是左';
        hint = '只校准一次：慢慢向左转，幅度小一点';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示向左转' : '朗读';
      } else if (this._sub === 'calibReturn') {
        big = '回正到中间';
        bar = '◀ 最左 ············ 最右 ▶';
        countLine = '校准：回正到中间';
        hint = '慢慢转回正前方';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示回正' : '朗读';
      } else if (this._sub === 'toLeft' || this._sub === 'toLeftHold') {
        big = '先转到最左，停一下';
        bar = this._barText(0);
        countLine = '第 1 步：到最左 · 停一下';
        hint = '慢慢向左转，到最左停 0.8 秒';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示到最左' : '朗读';
      } else if (this._sub === 'atLeft') {
        big = '在最左，准备慢扫';
        bar = this._barText(0);
        countLine = '第 2 步：从最左出发';
        hint = '慢慢开始向右转，越慢越好';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示开始慢扫' : '朗读';
      } else {
        // scanning
        let progress;
        if (this._sensorSkip || !this._hasReading) {
          progress = this._demoProgress / 3;
        } else {
          progress = this._progress(this._leftYaw() !== null ? this._leftYaw() : 0);
        }
        big = '慢扫中…';
        bar = this._barText(progress);
        countLine = (this._sensorSkip || !this._hasReading)
          ? '演示慢扫中 · 第 ' + this._demoProgress + ' / 3 段'
          : '已扫 ' + this._scanSeconds.toFixed(1) + ' 秒 · 至少 8 秒';
        hint = '慢，再慢一点';
        mainBtn = (this._sensorSkip || !this._hasReading) ? '演示慢扫一段' : '朗读';
      }
      safety = '';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）';
    else if (!this._hasReading) sensorLine = '传感器：等待读数…';
    else sensorLine = '传感器：方向传感器已连接 · 中心已校准';
    const key = [big, bar, countLine, hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      bar: bar,
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
    <div class="title">慢速扫描 SLOW SCAN</div>
    <div class="big">{{ big }}</div>
    <div class="bar">{{ bar }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">一次慢扫 · 不转圈 · 不来回扫 · 到了最右就停 · 痛晕立刻停</div>
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
.bar {
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
