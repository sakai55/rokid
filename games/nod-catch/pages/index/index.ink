<script def>
{
  "title": "Nod Catch"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Nod Catch （点头接球） — head-movement mini-game GA08, Group B
// (head-as-controller). EXTREME simplicity: one page, three states
// only (ready / playing / done). Ten balls fall one at a time past
// a visible center catch line; a gentle nod while the ball is in
// the catch window catches it. The playing screen shows at most
// the falling ball + center catch line, the score x/10 and one
// short hint; voice (TTS) does the rest. No menus, no settings,
// no levels, no camera, no mic/ASR, no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. This game uses only small
// nods — no circling, no sweeping, no fast jerking. The catch nod
// is a GENTLE nod, never a throw of the head. Slow, small range,
// stop at mild stretch, never pain. Stop at once on pain /
// dizziness / numbness / nausea. Sit or stand steady first. One
// round is 10 balls, short. This is entertainment / daily
// activity, NOT medical diagnosis, treatment or a rehab
// prescription; people with cervical disease, vertigo, post-op or
// head/neck injury history should ask a doctor first.
//
// HOW A BALL IS CAUGHT (exact, as implemented):
// FALL_MS = 3000: every ball falls from top to bottom over a
// FIXED 3 seconds — no acceleration, so the timing stays
// learnable and fair. The catch line sits at the middle of the
// fall path (50% of the fall). CATCH WINDOW: the ball's center
// within ±15% of screen height around the line, i.e. fall
// progress 35%–65%, i.e. roughly ±0.45 s around the line
// crossing at 1.5 s. A nod inside the window = catch (+1, voice
// "接住了"). A nod outside the window = a MISS for that ball:
// before the window the voice says "早了", after it "晚了"; the
// ball keeps falling and is then gone — ONE NOD PER BALL, no
// second chance on the same ball. No nod at all = miss when the
// ball passes the bottom (voice "没接住"). Between balls there
// is a 1-second pause (PAUSE_MS = 1000) with the next ball
// announced ("下一个"). After ball 10 the done state shows
// catches x/10 and "再来一局" (tap restarts).
//
// NOD SIGNALS — PRIMARY vs FALLBACK (technical honesty):
// PRIMARY: onHeadGesture('nod'), officially documented for
// 'nod' — this is the one game family where the nod event is the
// action, so it is the primary catch signal. FALLBACK: pitch
// from AbsoluteOrientationSensor (GA01 formula, relative to the
// center calibrated at round start): pitch down past ~20 deg
// and back inside 10 deg counts as one fallback nod, for hosts
// that do not deliver the nod event. A gentle real nod may not
// reach 20 deg — the fallback needs a CLEAR nod, and that limit
// is documented, not hidden; the primary event catches gentle
// nods. DOUBLE-COUNT GUARD: nod + fallback can never count the
// same ball twice — _onNod() acts only while the ball is still
// falling AND not yet attempted (_attempted false); after a
// catch or a miss-nod, further nod signals are ignored until
// the next ball starts (_attempted reset at ball start). No
// other gesture event is claimed or used.
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a
// labeled DEMO nod stepper ("演示点头") so the playing and done
// states can be previewed. On a real device with a nod event
// there is no DEMO path at all; tap during playing only
// re-speaks the hint and NEVER catches (catch is nod-only).
// -------------------------------------------------------------------

const TOTAL = 10;
const FALL_MS = 3000;   // fixed fall time per ball, no acceleration
const PAUSE_MS = 1000;  // pause between balls, next ball announced
const WIN_LO = 0.35;    // catch window: progress 35%–65%
const WIN_HI = 0.65;    // = ball center within ±15% height of the line
const TICK_MS = 50;
const FALL_DOWN_DEG = 20; // fallback nod: pitch down past 20 deg
const CENTER_DEG = 10;    // fallback nod: return inside 10 deg

export default {
  data: {
    big: '准备',
    countLine: '0 / 10',
    t0: '', t1: '', t2: '', t3: '', t4: '', t5: '', t6: '', t7: '', t8: '',
    hint: '单击开始 · 共 10 个球',
    safety: '只轻轻点头接球，不转圈、不甩头、不快点头。先坐稳 / 站稳。球从上落下，到中间的线时轻轻点头接住。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    this._ball = 0;        // current ball number 1..10 (0 = none)
    this._ballPhase = 'fall'; // fall | pause (inside playing only)
    this._ballStart = 0;
    this._pauseUntil = 0;
    this._progress = 0;
    this._attempted = false; // one nod per ball: true after any nod
    this._caught = 0;
    this._lastResult = '';
    this._sensor = null;
    this._pitch = null;
    this._center = 0;
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

  // ---- orientation sensor (fallback nod only) -----------------------
  // Pitch from the orientation quaternion, same formula as the
  // GA01 nod-count game (fleet-consistent):
  // pitch = asin(2*(w*x - y*z)), clamped. Only the RELATIVE pitch
  // vs the calibrated center is ever used, so the host's absolute
  // zero never matters. DOWN-SIGN ASSUMPTION (device verification
  // item, same as GA01): head-down is taken as negative relative
  // pitch. If the sign is inverted on device, the fallback simply
  // never fires — it fails safe as "no fallback catch", never as
  // a wrong catch — while the primary nod event still works.
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

  _relPitch() {
    if (!this._hasReading || this._pitch === null) return null;
    let d = this._pitch - this._center;
    while (d > 180) d -= 360;
    while (d < -180) d += 360;
    return d;
  },

  // ---- nod signals --------------------------------------------------
  // PRIMARY: the officially documented 'nod' gesture event. It is
  // accepted only while a ball is falling and not yet attempted;
  // in every other state (ready / pause / done / already
  // attempted) it is ignored, so one ball can never be caught
  // twice and a nod between balls never leaks into the next ball.
  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || event.gesture || '';
    if (g !== 'nod') return;
    this._onNod(false);
  },

  // One nod, one verdict for the current ball. progress < window =
  // early miss, inside = catch, after window = late miss. After
  // any verdict _attempted is true and further nods are ignored
  // until the next ball starts. A catch goes straight to the
  // 1-second pause; an early/late miss lets the ball keep falling
  // to the bottom, then the pause — no second chance either way.
  _onNod(isDemo) {
    if (this._phase !== 'playing') return;
    if (this._ballPhase !== 'fall') return;
    if (this._attempted) return;
    this._attempted = true;
    const p = this._progress;
    if (p >= WIN_LO && p <= WIN_HI) {
      this._caught++;
      this._lastResult = '接住了';
      this._speak('接住了');
      this.setData({ foot: 'EVT: ball ' + this._ball + ' CAUGHT at progress ' + Math.round(p * 100) + '% (window 35-65%)' });
      this._toPause();
    } else if (p < WIN_LO) {
      this._lastResult = '早了';
      this._speak('早了');
      this.setData({ foot: 'EVT: ball ' + this._ball + ' nod EARLY at ' + Math.round(p * 100) + '%, miss, ball keeps falling' });
      // Ball keeps falling; the pause starts at the bottom.
    } else {
      this._lastResult = '晚了';
      this._speak('晚了');
      this.setData({ foot: 'EVT: ball ' + this._ball + ' nod LATE at ' + Math.round(p * 100) + '%, miss, ball keeps falling' });
    }
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
    // (fallback-nod reference only; the primary nod event needs no
    // calibration).
    this._center = (this._hasReading && this._pitch !== null) ? this._pitch : 0;
    this._caught = 0;
    this._demoUsed = false;
    this._phase = 'playing';
    this._startTimer();
    this._speak('开始，球来了，看准中间的线，轻轻点头接');
    this.setData({ foot: 'EVT: round started, center calibrated' });
    this._startBall(1);
  },

  _startBall(n) {
    this._ball = n;
    this._ballPhase = 'fall';
    this._ballStart = Date.now();
    this._progress = 0;
    this._attempted = false;
    this._fallDown = false;
    this._lastResult = '';
    this.setData({ foot: 'EVT: ball ' + n + ' falling, 3 s, window 35-65%' });
    this._render();
  },

  // Enter the 1-second pause; the next ball is announced once here.
  _toPause() {
    this._ballPhase = 'pause';
    this._pauseUntil = Date.now() + PAUSE_MS;
    if (this._ball < TOTAL) {
      this._speak('下一个');
    }
    this._render();
  },

  _finish() {
    this._phase = 'done';
    this._stopTimer();
    this._speak('结束，接住 ' + this._caught + ' 个，满分 10 个');
    this.setData({ foot: 'EVT: DONE caught ' + this._caught + '/' + TOTAL });
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // A demo tap is a demo nod at the current ball position — it
  // goes through the same one-nod-per-ball verdict as a real nod.
  // Labeled as demo everywhere it appears; never a real catch.
  _demoNod() {
    this._demoUsed = true;
    this._onNod(true);
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoNod(); return; }
    // Real device: tap only re-speaks the hint — it NEVER catches.
    // Catch is nod-only, so a tap cannot cheat a ball.
    this._speak(this._currentHint());
  },

  _currentHint() {
    if (this._ballPhase === 'pause') return this._lastResult;
    if (this._attempted) return this._lastResult;
    return '看准中间的线，轻轻点头接';
  },

  // ---- tick: fall -> pause -> next ball / done -----------------------
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

    if (this._ballPhase === 'pause') {
      if (now >= this._pauseUntil) {
        if (this._ball >= TOTAL) { this._finish(); return; }
        this._startBall(this._ball + 1);
      }
      return;
    }

    // falling:
    this._progress = Math.min(1, (now - this._ballStart) / FALL_MS);

    // FALLBACK nod: pitch down past 20 deg, then back inside 10
    // deg = one fallback nod. Only while falling and unattempted;
    // _onNod() itself enforces the one-nod-per-ball guard, so a
    // fallback nod arriving together with a primary nod event can
    // still only verdict the ball once.
    if (!this._attempted && !this._sensorSkip) {
      const rel = this._relPitch();
      if (rel !== null) {
        if (!this._fallDown && rel <= -FALL_DOWN_DEG) {
          this._fallDown = true;
        } else if (this._fallDown && Math.abs(rel) < CENTER_DEG) {
          this._fallDown = false;
          this._onNod(false);
          return;
        }
      }
    }

    if (this._progress >= 1) {
      // Ball reached the bottom.
      if (!this._attempted) {
        // No nod at all = miss.
        this._lastResult = '没接住';
        this._speak('没接住');
        this.setData({ foot: 'EVT: ball ' + this._ball + ' reached bottom, no nod, miss' });
      }
      // An early/late miss was already announced; do not repeat it.
      this._toPause();
      return;
    }
    this._render();
  },

  // ---- render: one layout, text driven by state -----------------------
  // Track: 9 separate row divs (NOT one multi-line string — the
  // Ink canvas renderer collapses newlines inside a single text
  // node, which wrapped the track into 2 lines in preview). The
  // catch line is row 4 (the middle). While a ball falls, its row
  // is floor(progress * 9) clamped to 8, so the ball visibly
  // drops from the top row to the bottom row over 3 s and crosses
  // the line row at mid-fall. The row is DISPLAY only; the catch
  // verdict always uses the exact progress window 35%–65%, never
  // the row.
  _trackRows() {
    // Ready/done show no track (the safety text needs the room);
    // the track appears only while a ball is falling or pausing.
    if (this._phase !== 'playing') return ['', '', '', '', '', '', '', '', ''];
    const rows = [];
    let ballRow = -1;
    if (this._ballPhase === 'fall') {
      ballRow = Math.min(8, Math.floor(this._progress * 9));
    }
    for (let i = 0; i < 9; i++) {
      if (i === ballRow) rows.push('────●────');
      else if (i === 4) rows.push('────┼────');
      else rows.push('────·────');
    }
    return rows;
  },

  _render() {
    let big, hint, safety, sensorLine, mainBtn;
    if (this._phase === 'ready') {
      big = '准备';
      hint = '单击开始 · 共 10 个球';
      safety = '只轻轻点头接球，不转圈、不甩头、不快点头。先坐稳 / 站稳。球从上落下，到中间的线时轻轻点头接住。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示接住 ' + this._caught + ' / 10' : '接住 ' + this._caught + ' / 10';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局';
      safety = '';
      mainBtn = '再来一局';
    } else {
      if (this._ballPhase === 'pause') {
        big = this._ball >= TOTAL ? '最后一个球结束' : '第 ' + this._ball + ' 个球结束';
        hint = this._ball >= TOTAL ? this._lastResult : this._lastResult + ' · 下一个';
      } else {
        big = '第 ' + this._ball + ' 个球';
        hint = this._attempted ? this._lastResult + ' · 球还在落' : '看准中间的线，轻轻点头接';
      }
      safety = '';
      mainBtn = (this._sensorSkip || !this._hasReading) ? '演示点头' : '朗读';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）· 点头事件为主信号';
    else if (!this._hasReading) sensorLine = '传感器：等待读数… · 点头事件为主，俯仰回正为备用';
    else sensorLine = '传感器：方向传感器已连接 · 点头事件为主，俯仰回正为备用';
    const rows = this._trackRows();
    const key = [big, this._caught + '/' + TOTAL, rows.join('/'), hint, safety, sensorLine, mainBtn].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: this._caught + ' / ' + TOTAL,
      t0: rows[0], t1: rows[1], t2: rows[2], t3: rows[3], t4: rows[4],
      t5: rows[5], t6: rows[6], t7: rows[7], t8: rows[8],
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
    <div class="title">点头接球 NOD CATCH</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="trackrow">{{ t0 }}</div>
    <div class="trackrow">{{ t1 }}</div>
    <div class="trackrow">{{ t2 }}</div>
    <div class="trackrow">{{ t3 }}</div>
    <div class="trackrow">{{ t4 }}</div>
    <div class="trackrow">{{ t5 }}</div>
    <div class="trackrow">{{ t6 }}</div>
    <div class="trackrow">{{ t7 }}</div>
    <div class="trackrow">{{ t8 }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">只轻轻点头 · 不转圈 · 不甩头 · 痛晕立刻停</div>
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
.trackrow {
  color: #ffffff;
  font-family: monospace;
  font-size: 13px;
  line-height: 14px;
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
