<script def>
{
  "title": "Rhythm Nod"
}
</script>

<script setup>
// -------------------------------------------------------------------
// Rhythm Nod （节奏点头） — head-movement mini-game GA11, Group B
// (head-as-controller). EXTREME simplicity: one page, three states
// only (ready / playing / done). Four slow count-in beats teach
// the tempo, then 16 scored beats follow at a FIXED tempo of one
// beat per second; a gentle nod inside ±300 ms of a beat instant
// is a hit. The playing screen shows at most the current beat
// number x/16, a beat indicator (flashing on beat instants), the
// score (hits so far) and one short hint; voice (TTS) does the
// rest. No menus, no settings, no levels, no camera, no mic/ASR,
// no storage, no network.
//
// SERIES CONSTITUTION (neck safety, GO's rule — also on the ready
// screen, in AGENTS.md and in the README):
// Turning the neck in circles is WRONG. This game uses only small
// gentle nods — no circling, no sweeping, no fast jerking. Nods
// stay small and unhurried even on the beat: the beat is slow
// (1 second apart) precisely so nobody has to jerk. Slow, small
// range, stop at mild stretch, never pain. Stop at once on pain /
// dizziness / numbness / nausea. Sit or stand steady first. One
// round is 16 beats, short. This is entertainment / daily
// activity, NOT medical diagnosis, treatment or a rehab
// prescription; people with cervical disease, vertigo, post-op or
// head/neck injury history should ask a doctor first.
//
// HOW A BEAT IS SCORED (exact, as implemented):
// TEMPO: BEAT_MS = 1000, fixed — no acceleration. COUNT-IN:
// 4 preparatory beats, one per second, announced by voice
// ("准备，1、2、3、4"); no nod is counted during count-in.
// After count-in there is a 1-second lead: the beats phase
// starts at roundStart + 4000 ms, beat 1's instant is at
// roundStart + 5000 ms, beat 16's at roundStart + 20000 ms.
// HIT WINDOW: WINDOW_MS = 300, i.e. ±300 ms around each beat
// instant. A nod inside the window = hit (+1, voice "对").
// A nod BEFORE the window of a still-pending beat = early miss
// (voice "早了", that beat is spent). A nod AFTER the window
// but before the next beat's window opens (beat instant + 700
// ms) = late miss (voice "晚了", that beat is spent). No nod
// by the time the next beat's window opens (beat + 700 ms) =
// miss (voice "漏了"). ONE NOD PER BEAT, no second chance:
// after any verdict, further nod signals are ignored until the
// next beat's window opens (the beat advances at beat + 700
// ms). A nod during count-in, during the lead, or after a
// verdict is ignored and can never leak into another beat.
// EARLY IN PRACTICE: because a spent beat only advances at the
// next window opening, the only beat whose window a nod can
// precede while it is still pending is beat 1 (nod in the lead
// interval 4000–4700 ms after round start = early miss for beat
// 1); later beats become pending exactly when their window
// opens. The early rule is still implemented generally, not
// special-cased to beat 1.
// BEAT CALLS: at each beat instant, while the beat is still
// pending, the voice speaks the beat number (Chinese numerals
// 1–16); a spent beat gets no beat call, so a verdict is never
// talked over by its own beat number. The beat indicator also
// flashes for 200 ms at every count-in and scored beat instant.
// Done shows hits x/16 and "再来一局" (tap restarts, count-in
// again).
//
// NOD SIGNALS — PRIMARY vs FALLBACK (technical honesty):
// PRIMARY: onHeadGesture('nod'), officially documented for
// 'nod' — the primary beat signal; it catches gentle nods.
// FALLBACK: pitch from AbsoluteOrientationSensor (GA01 formula,
// relative to the center calibrated at round start): pitch down
// past ~20 deg and back inside 10 deg counts as one fallback
// nod, for hosts that do not deliver the nod event. A gentle
// real nod may not reach 20 deg — the fallback needs a CLEAR
// nod, and that limit is documented, not hidden. DOUBLE-COUNT
// GUARD: nod + fallback share the same _onNod() guard
// (_beatSpent), so a beat delivered by both paths still counts
// once. No other gesture event is claimed or used.
// Sensor missing (web preview) = SKIP/demo state, never a fake
// pass: the screen says so, and the main button becomes a
// labeled DEMO nod stepper ("演示点头") that goes through the
// same one-nod-per-beat verdict at the current beat timing, so
// the playing and done states can be previewed. On a real
// device with a nod event there is no DEMO path at all; tap
// during playing only re-speaks the hint and NEVER hits a beat
// (a beat is nod-only, so a tap cannot cheat a beat).
// -------------------------------------------------------------------

const TOTAL = 16;
const BEAT_MS = 1000;   // fixed tempo: one beat per second, no acceleration
const WINDOW_MS = 300;  // hit window: ±300 ms around each beat instant
const LATE_MS = 700;    // next window opens at beat instant + 700 ms
const COUNTIN = 4;      // 4 preparatory beats, one per second
const COUNTIN_MS = 4000; // count-in duration; beats phase starts here
const LEAD_MS = 1000;   // lead after count-in before beat 1's instant
const TICK_MS = 50;
const FLASH_MS = 200;   // beat indicator flash length at each beat instant
const FALL_DOWN_DEG = 20; // fallback nod: pitch down past 20 deg
const CENTER_DEG = 10;    // fallback nod: return inside 10 deg
const NUM = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二', '十三', '十四', '十五', '十六'];

export default {
  data: {
    big: '准备',
    countLine: '共 16 拍 · 1 秒一拍',
    beatLine: '· 节拍',
    hint: '单击开始 · 先听 4 拍准备',
    safety: '只小幅轻轻点头，不转圈、不甩头、不快点头。先坐稳 / 站稳。先听 4 拍准备（1、2、3、4），再跟 16 拍节拍点头，每拍间隔 1 秒。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。',
    sensorLine: '传感器：未启动',
    mainBtn: '开始',
    foot: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'ready'; // ready | playing | done
    this._sub = 'countin'; // countin | beats (inside playing only)
    this._roundStart = 0;
    this._countinIdx = -1;
    this._beatsStart = 0; // instant of beat 1
    this._beat = 0;       // current pending beat number 1..16 (0 = none)
    this._beatSpent = false; // one nod per beat: true after any verdict
    this._beatAnnounced = false;
    this._hits = 0;
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
  // never fires — it fails safe as "no fallback hit", never as
  // a wrong hit — while the primary nod event still works.
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

  _beatInstant(n) {
    return this._beatsStart + (n - 1) * BEAT_MS;
  },

  // ---- nod signals --------------------------------------------------
  // PRIMARY: the officially documented 'nod' gesture event. It is
  // accepted only while the beats phase is running, the current
  // beat is still pending, and the nod falls in the beat's hit,
  // early or late zone; in every other state (ready / count-in /
  // lead / already spent / done) it is ignored, so one beat can
  // never be hit twice and a nod between beats never leaks into
  // the next beat.
  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || event.gesture || '';
    if (g !== 'nod') return;
    this._onNod(false);
  },

  // One nod, one verdict for the current beat. Inside ±300 ms =
  // hit; before the window (still pending) = early miss; after
  // the window but before beat + 700 ms = late miss; at or after
  // beat + 700 ms the tick has already expired the beat, so the
  // nod is ignored and the tick's "漏了" stands. After any
  // verdict _beatSpent is true and further nods are ignored
  // until the next beat's window opens.
  _onNod(isDemo) {
    if (this._phase !== 'playing') return;
    if (this._sub !== 'beats') return;
    if (this._beatSpent) return;
    if (this._beat < 1 || this._beat > TOTAL) return;
    const now = Date.now();
    const b = this._beatInstant(this._beat);
    const diff = now - b;
    if (diff >= -WINDOW_MS && diff <= WINDOW_MS) {
      this._hits++;
      this._lastResult = '对';
      this._speak('对');
      this.setData({ foot: 'EVT: beat ' + this._beat + ' HIT at ' + diff + ' ms (window ±300 ms)' });
      this._beatSpent = true;
      if (this._beat >= TOTAL) { this._finish(); return; }
    } else if (diff < -WINDOW_MS) {
      this._lastResult = '早了';
      this._speak('早了');
      this.setData({ foot: 'EVT: beat ' + this._beat + ' nod EARLY at ' + diff + ' ms, miss, beat spent' });
      this._beatSpent = true;
      if (this._beat >= TOTAL) { this._finish(); return; }
    } else if (diff < LATE_MS) {
      this._lastResult = '晚了';
      this._speak('晚了');
      this.setData({ foot: 'EVT: beat ' + this._beat + ' nod LATE at ' + diff + ' ms, miss, beat spent' });
      this._beatSpent = true;
      if (this._beat >= TOTAL) { this._finish(); return; }
    } else {
      return;
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
    this._hits = 0;
    this._demoUsed = false;
    this._phase = 'playing';
    this._sub = 'countin';
    this._roundStart = Date.now();
    this._countinIdx = -1;
    this._beatsStart = this._roundStart + COUNTIN_MS + LEAD_MS;
    this._beat = 0;
    this._beatSpent = false;
    this._beatAnnounced = false;
    this._lastResult = '';
    this._fallDown = false;
    this._startTimer();
    this._speak('准备');
    this.setData({ foot: 'EVT: round started, count-in 4 beats, beat 1 at +5000 ms' });
    this._render();
  },

  _finish() {
    this._phase = 'done';
    this._stopTimer();
    this._speak('结束，对了 ' + this._hits + ' 个，满分 16 个');
    this.setData({ foot: 'EVT: DONE hits ' + this._hits + '/' + TOTAL });
    this._render();
  },

  // DEMO path: ONLY when the sensor is unavailable (web preview).
  // A demo tap is a demo nod at the current beat timing — it
  // goes through the same one-nod-per-beat verdict as a real nod.
  // Labeled as demo everywhere it appears; never a real hit.
  _demoNod() {
    this._demoUsed = true;
    this._onNod(true);
  },

  mainTap() {
    if (this._phase === 'ready') { this._beginRound(); return; }
    if (this._phase === 'done') { this._beginRound(); return; }
    // playing:
    if (this._sensorSkip || !this._hasReading) { this._demoNod(); return; }
    // Real device: tap only re-speaks the hint — it NEVER hits.
    // A beat is nod-only, so a tap cannot cheat a beat.
    this._speak('跟着节拍轻轻点头');
  },

  // ---- tick: count-in -> beats -> advance / expire / done -----------
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

    if (this._sub === 'countin') {
      const elapsed = now - this._roundStart;
      const idx = Math.floor(elapsed / 1000);
      if (idx < COUNTIN && idx !== this._countinIdx) {
        this._countinIdx = idx;
        this._speak(NUM[idx]);
      }
      if (elapsed >= COUNTIN_MS) {
        this._sub = 'beats';
        this._beat = 1;
        this._beatSpent = false;
        this._beatAnnounced = false;
        this._fallDown = false;
        this._speak('开始');
        this.setData({ foot: 'EVT: beats phase, beat 1 instant at +5000 ms' });
      }
      this._render();
      return;
    }

    // beats phase:
    if (this._beat < 1 || this._beat > TOTAL) { this._render(); return; }
    const b = this._beatInstant(this._beat);

    if (this._beatSpent) {
      // Wait until the next beat's window opens (beat + 700 ms),
      // then advance. The last beat finishes in _onNod, so a
      // spent last beat never reaches this tick.
      if (now >= b + LATE_MS) {
        this._beat++;
        this._beatSpent = false;
        this._beatAnnounced = false;
        this._fallDown = false;
        this._lastResult = '';
        this.setData({ foot: 'EVT: advance to beat ' + this._beat + ', window opens' });
      }
      this._render();
      return;
    }

    // pending beat:
    if (now >= b && !this._beatAnnounced) {
      this._beatAnnounced = true;
      this._speak(NUM[this._beat - 1]);
    }
    if (now >= b + LATE_MS) {
      // No nod in the window nor the late zone = miss.
      this._lastResult = '漏了';
      this._speak('漏了');
      this.setData({ foot: 'EVT: beat ' + this._beat + ' no nod by +700 ms, miss' });
      if (this._beat >= TOTAL) { this._finish(); return; }
      this._beat++;
      this._beatSpent = false;
      this._beatAnnounced = false;
      this._fallDown = false;
      this._render();
      return;
    }

    // FALLBACK nod: pitch down past 20 deg, then back inside 10
    // deg = one fallback nod. Only while the beat is pending;
    // _onNod() itself enforces the one-nod-per-beat guard, so a
    // fallback nod arriving together with a primary nod event can
    // still only verdict the beat once.
    if (!this._sensorSkip) {
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
    this._render();
  },

  // Beat indicator flash: true for 200 ms starting at a beat
  // instant — count-in beats, the beats-phase start ("开始" tick
  // at +4000 ms), and each scored beat instant.
  _flashNow() {
    if (this._phase !== 'playing') return false;
    const now = Date.now();
    let inst = -1;
    if (this._sub === 'countin') {
      if (this._countinIdx < 0) return false;
      inst = this._roundStart + this._countinIdx * 1000;
    } else if (now < this._beatsStart) {
      inst = this._roundStart + COUNTIN_MS;
    } else if (this._beat >= 1 && this._beat <= TOTAL) {
      inst = this._beatInstant(this._beat);
    } else {
      return false;
    }
    const d = now - inst;
    return d >= 0 && d < FLASH_MS;
  },

  // ---- render: one layout, text driven by state -----------------------
  _render() {
    let big, countLine, beatLine, hint, safety, sensorLine, mainBtn;
    const flash = this._flashNow();
    beatLine = flash ? '● 节拍！' : '○ 节拍';
    if (this._phase === 'ready') {
      big = '准备';
      countLine = '共 16 拍 · 1 秒一拍';
      hint = '单击开始 · 先听 4 拍准备';
      safety = '只小幅轻轻点头，不转圈、不甩头、不快点头。先坐稳 / 站稳。先听 4 拍准备（1、2、3、4），再跟 16 拍节拍点头，每拍间隔 1 秒。痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗诊断、治疗或康复处方；颈椎病、眩晕、术后、头颈伤史请先问医生。';
      mainBtn = '开始';
    } else if (this._phase === 'done') {
      big = this._demoUsed ? '演示对了 ' + this._hits + ' / 16' : '对了 ' + this._hits + ' / 16';
      countLine = '对了 ' + this._hits + ' / 16';
      hint = this._demoUsed
        ? '演示模式：传感器不可用 · 单击再来一局'
        : '单击再来一局';
      safety = '';
      mainBtn = '再来一局';
    } else if (this._sub === 'countin') {
      const n = this._countinIdx < 0 ? 1 : this._countinIdx + 1;
      big = '准备中 ' + n + ' / 4';
      countLine = '对了 0 / 16';
      hint = '听节拍，别点头 · 准备 ' + n + ' / 4';
      safety = '';
      mainBtn = (this._sensorSkip || !this._hasReading) ? '演示点头' : '朗读';
    } else {
      big = '第 ' + this._beat + ' / 16 拍';
      countLine = '对了 ' + this._hits + ' / 16';
      if (this._beatSpent) hint = this._lastResult + ' · 等下一拍';
      else if (this._lastResult) hint = this._lastResult + ' · 跟着节拍轻轻点头';
      else hint = '跟着节拍轻轻点头';
      safety = '';
      mainBtn = (this._sensorSkip || !this._hasReading) ? '演示点头' : '朗读';
    }
    if (this._sensorSkip) sensorLine = '传感器：SKIP（网页预览无方向传感器，演示模式）· 点头事件为主信号';
    else if (!this._hasReading) sensorLine = '传感器：等待读数… · 点头事件为主，俯仰回正为备用';
    else sensorLine = '传感器：方向传感器已连接 · 点头事件为主，俯仰回正为备用';
    const key = [big, countLine, beatLine, hint, safety, sensorLine, mainBtn, this._phase, this._sub, this._beat, this._beatSpent].join('|');
    if (key === this._lastRendered) return;
    this._lastRendered = key;
    this.setData({
      big: big,
      countLine: countLine,
      beatLine: beatLine,
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
    <div class="title">节奏点头 RHYTHM NOD</div>
    <div class="big">{{ big }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="beat">{{ beatLine }}</div>
    <div class="hint">{{ hint }}</div>
    <div class="safety">{{ safety }}</div>
    <div class="sensor">{{ sensorLine }}</div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="mainTap">{{ mainBtn }}</button>
    </div>
    <div class="foot">{{ foot }}</div>
    <div class="foot2">只小幅轻轻点头 · 不转圈 · 不甩头 · 痛晕立刻停</div>
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
.beat {
  color: #ffffff;
  font-size: 22px;
  font-weight: bold;
  line-height: 22px;
  margin-top: 4px;
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
