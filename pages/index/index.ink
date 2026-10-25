<script def>
{
  "title": "Alarm Triage Visual"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Alarm Triage Visual (Curb-Cut CC06, FILTER/WATCH family): visual
// alarm triage for people with severe hearing loss. Smoke alarms,
// doorbells, kettles, washer-end tones, a crying baby — all of them
// are sounds, so for this wearer they are invisible unless something
// turns them into light. This agent does exactly that, and nothing
// it cannot honestly do:
// (1) LISTEN opens an omnidirectional getUserMedia stream and
// watches its level with an Analyser; a loud event flips the whole
// screen into a big visual banner. The banner is the alarm — no
// speech, no beep, no hearing required.
// (2) SCAN: the wearer turns the head toward a facing (DIR cycles
// 左 / 正前方 / 右 — the wearer turns, then taps) and SCAN samples
// the live level at that facing. The facing with the highest sampled
// level is the direction verdict.
// (3) TYPE + 确认: the agent NEVER claims to recognise which
// appliance is sounding — a level meter cannot identify a source.
// The wearer (who can see the kitchen, the door, the baby) picks
// the type from a fixed list and confirms it; the triage banner
// then reads TYPE + DIRECTION in huge type.
// Honesty rules: a level with no stream is shown as 未测, never
// invented; a triage with no confirmed type stays 未确认; SPEAK
// only reads the banner aloud for a hearing person nearby — the
// deaf wearer's own channel is always the screen. Nothing is
// persisted: no storage calls anywhere.
// -------------------------------------------------------------------

const TICK_MS = 250;
const TYPES = ['烟感', '门铃', '水壶', '洗衣机', '宝宝哭声', '其他声响'];
const DIRS = ['左', '正前方', '右'];

export default {
  data: {
    status: 'IDLE: 点 LISTEN 开始全向守听',
    micLine: 'MIC CHECK: not run - LISTEN 前先查全向模式',
    bannerLine: '没有响声',
    dirLine: '方位：未测 — 转头向声源，SCAN 逐向采样',
    levelLine: '声级：░░░░░░░░░░ 未测',
    typeLine: '类型：未确认 — TYPE 选一项，确认后定格',
    stateLine: '守听没开 — LISTEN 后有响声即亮横幅',
    progressLine: '采样：左 未测 · 正前方 未测 · 右 未测',
    guideLine: 'LISTEN 守听 · DIR 转向 · SCAN 采样 · TYPE 选类型',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'idle'; // idle | listening | alert | triaged
    this._typeIdx = 0;
    this._dirIdx = 1;
    this._samples = { '左': null, '正前方': null, '右': null };
    this._level = 0;
    this._alertAt = 0;
    this._tickCount = 0;
    this._steady = false;
    this._nodAt = -100000;
    this._stream = null;
    this._analyser = null;
    this._audioCtx = null;
    this._busy = false;
    this._demo = null;
    this._demoStep = 0;
    this._timer = null;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._startTimer();
    this._recompute();
  },

  onShow() { this._startTimer(); },
  onHide() { this._stopTimer(); this._stopStream(); },
  onUnload() { this._stopTimer(); this._stopStream(); },

  _err(tag, e) {
    return tag + ': ' + (e && e.message ? e.message : String(e));
  },

  _withTimeout(promise, ms, tag) {
    return Promise.race([
      promise,
      new Promise((resolve, reject) => {
        setTimeout(() => reject(new Error(tag + ' timeout')), ms);
      })
    ]);
  },

  _speakText(text) {
    // Fixed host voice; utterance lang is never set (documented: the
    // TTS lang attribute does not take effect on this platform).
    // SPEAK exists for a hearing person nearby; the wearer's own
    // channel is always the screen, never this voice.
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  _startTimer() {
    if (this._timer) return;
    this._timer = setInterval(() => { this._tick(); }, TICK_MS);
  },
  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },
  _tick() {
    this._tickCount++;
    if (this._analyser && (this._phase === 'listening' || this._phase === 'alert')) {
      try {
        const buf = new Uint8Array(this._analyser.fftSize || 2048);
        this._analyser.getByteTimeDomainData(buf);
        let sum = 0;
        for (let i = 0; i < buf.length; i++) { const v = (buf[i] - 128) / 128; sum += v * v; }
        const rms = Math.sqrt(sum / buf.length);
        this._level = Math.max(0, Math.min(10, Math.round(rms * 40)));
      } catch (e) { /* keep last level */ }
      if (this._phase === 'listening' && this._level >= 6) {
        this._phase = 'alert';
        this._alertAt = this._tickCount;
        this.setData({ lastEvent: 'EVT: loud event level ' + this._level + ' -> ALERT banner' });
      }
      if (this._tickCount % 4 === 0) this._recompute();
    }
  },
  _bar() {
    let s = '';
    for (let i = 0; i < 10; i++) s += (i < this._level) ? '█' : '░';
    return s;
  },
  _bestDir() {
    let best = null;
    let bestVal = -1;
    for (const d of DIRS) {
      const v = this._samples[d];
      if (v !== null && v > bestVal) { bestVal = v; best = d; }
    }
    return best;
  },

  // ---- head gestures -------------------------------------------------
  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    this._steady = detail.isStable === true || detail.stable === true;
  },
  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || '';
    if (g !== 'nod') return;
    if (!this._steady) return;
    if (this._tickCount - this._nodAt < 8) return;
    this._nodAt = this._tickCount;
    this.speakTap();
    this.setData({ lastEvent: 'EVT: nod (steady) -> SPEAK only (never confirms/clears)' });
    this._recompute();
  },

  // ---- temple keys ---------------------------------------------------
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.listenTap(); return; }
    if (key === 'ArrowUp' || key === 'ArrowDown') { event.preventDefault(); this.dirTap(); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- mic: mode FIRST, then level monitor ---------------------------
  _stopStream() {
    if (this._stream && this._stream.getAudioTracks) this._stream.getAudioTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
    this._stream = null;
    this._analyser = null;
    if (this._audioCtx) { try { this._audioCtx.close(); } catch (e) {} this._audioCtx = null; }
  },
  async _checkMic() {
    const nav = (typeof navigator !== 'undefined') ? navigator : null;
    if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) {
      this.setData({ micLine: 'MIC CHECK (omnidirectional): n/a on this host - level stays 未测' });
      return;
    }
    this._stopStream();
    let stream = null;
    try {
      try {
        stream = await this._withTimeout(
          nav.mediaDevices.getUserMedia({ audio: { captureSource: 'microphone', microphoneMode: 'omnidirectional', echoCancellation: false } }),
          5000, 'mic check');
      } catch (e1) {
        if (e1 && e1.name === 'OverconstrainedError') {
          stream = await this._withTimeout(nav.mediaDevices.getUserMedia({ audio: true }), 5000, 'mic check fallback');
        } else throw e1;
      }
      this._stream = stream;
      const tracks = stream.getAudioTracks ? stream.getAudioTracks() : [];
      const t = tracks[0];
      const st = (t && t.getSettings) ? t.getSettings() : {};
      const m = st.microphoneMode || 'default (mode not reported)';
      try {
        const AC = window.AudioContext || window.webkitAudioContext;
        if (AC) {
          this._audioCtx = new AC();
          const src = this._audioCtx.createMediaStreamSource(stream);
          this._analyser = this._audioCtx.createAnalyser();
          this._analyser.fftSize = 2048;
          src.connect(this._analyser);
        }
      } catch (e) { /* level monitor unavailable, banner still manual */ }
      this.setData({ micLine: 'MIC CHECK (omnidirectional): stream OK · mode read back: ' + m });
    } catch (e) {
      this.setData({ micLine: 'MIC CHECK (omnidirectional): ' + this._err('mic check FAIL', e) + ' - level stays 未测' });
    }
  },

  // ---- buttons -------------------------------------------------------
  async listenTap() {
    if (this._busy) return null;
    if (this._phase === 'triaged') {
      this.setData({ lastEvent: 'EVT: triage on screen - 清除 before new listening' });
      this._recompute();
      return null;
    }
    this._busy = true;
    await this._checkMic();
    this._busy = false;
    if (this._phase === 'idle' || this._phase === 'alert') {
      if (this._phase === 'idle') {
        this._phase = 'listening';
        this._samples = { '左': null, '正前方': null, '右': null };
        this._level = 0;
      }
      this.setData({ status: 'LISTENING: 全向守听中 — 有响声即亮横幅', lastEvent: 'EVT: listening (omnidirectional)' });
    }
    this._recompute();
    return null;
  },

  dirTap() {
    this._dirIdx = (this._dirIdx + 1) % DIRS.length;
    this.setData({ lastEvent: 'EVT: facing -> ' + DIRS[this._dirIdx] + ' (turn head there, then SCAN)' });
    this._recompute();
  },

  scanTap() {
    if (this._phase !== 'alert' && this._phase !== 'listening') {
      this.setData({ lastEvent: 'EVT: SCAN needs LISTENING/ALERT - LISTEN first' });
      this._recompute();
      return;
    }
    const d = DIRS[this._dirIdx];
    if (!this._analyser) {
      this.setData({ status: '该向没测到声级（无可用音频流）— 请确认 LISTEN 已开，或用 DEMO 看流程', lastEvent: 'EVT: SCAN ' + d + ' SKIP - no analyser stream' });
      this._recompute();
      return;
    }
    this._samples[d] = this._level;
    if (this._phase === 'listening') this._phase = 'alert';
    this.setData({ status: 'SCAN 已采 ' + d + '：声级 ' + this._level + ' — 再转头采另一向', lastEvent: 'EVT: SCAN ' + d + ' = level ' + this._level });
    this._recompute();
  },

  typeTap() {
    this._typeIdx = (this._typeIdx + 1) % TYPES.length;
    this.setData({ lastEvent: 'EVT: type -> ' + TYPES[this._typeIdx] + ' (wearers eyes confirm, not auto-recognition)' });
    this._recompute();
  },

  confirmTap() {
    if (this._phase !== 'alert') {
      this.setData({ lastEvent: 'EVT: 确认 needs an ALERT banner - LISTEN/SCAN first' });
      this._recompute();
      return;
    }
    const best = this._bestDir();
    this._phase = 'triaged';
    this.setData({
      status: 'TRIAGED ✓ ' + TYPES[this._typeIdx] + ' · ' + (best ? best + '方向最响' : '方位未采样'),
      lastEvent: 'EVT: TRIAGED ' + TYPES[this._typeIdx] + ' @ ' + (best || 'no facing sampled')
    });
    this._recompute();
  },

  speakTap() {
    let text;
    if (this._phase === 'triaged') {
      const best = this._bestDir();
      text = '分诊结果：' + TYPES[this._typeIdx] + '，' + (best ? best + '方向最响。' : '方位没有采样。');
    } else if (this._phase === 'alert') {
      text = '有响声，声级' + this._level + '。请转头采样方位，再选类型确认。';
    } else if (this._phase === 'listening') {
      text = '正在全向守听，有响声会亮起横幅。';
    } else {
      text = '还没有开始守听，点 LISTEN 开始全向守听。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK (for a hearing person nearby) ' + (ok ? 'read banner aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  helpTap() {
    const text = '用法：点 LISTEN 全向守听，有响声屏幕会亮起大横幅。转头向声源，DIR 选方向、SCAN 采样，采两个方向以上最准。再用 TYPE 选你看到的声源类型，点确认，分诊横幅会定格显示类型和方向。声级计认不出是哪种电器，类型永远由你亲眼确认。';
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: HELP ' + (ok ? 'usage spoken (for nearby hearing help)' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  clearTap() {
    this._stopStream();
    this._phase = 'idle';
    this._samples = { '左': null, '正前方': null, '右': null };
    this._level = 0;
    this.setData({ status: 'IDLE: 已清除 — 点 LISTEN 开始新一轮守听', lastEvent: 'EVT: CLEARED - back to IDLE' });
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: alert with a loud level, then a triaged banner
  // (烟感 · 左方向最响）, then cleared. A further tap restores the
  // real state. No sound is ever faked as a real detection.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, typeIdx: this._typeIdx, dirIdx: this._dirIdx,
        samples: { '左': this._samples['左'], '正前方': this._samples['正前方'], '右': this._samples['右'] },
        level: this._level
      };
      this._demoStep = 0;
      this._phase = 'alert';
      this._level = 9;
      this._typeIdx = 0;
      this._dirIdx = 0;
      this._samples = { '左': null, '正前方': null, '右': null };
      this.setData({ status: 'DEMO: 有响声！声级 9 — 再点 DEMO = 采样+确认分诊', lastEvent: 'EVT: DEMO on - ALERT banner (demo level, not a detection)' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'triaged';
      this._samples = { '左': 9, '正前方': 4, '右': 2 };
      this.setData({ status: 'DEMO: TRIAGED ✓ 烟感 · 左方向最响 — 再点 DEMO = 清除', lastEvent: 'EVT: DEMO step 1 - TRIAGED 烟感 @ 左' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._phase = 'idle';
      this._samples = { '左': null, '正前方': null, '右': null };
      this._level = 0;
      this.setData({ status: 'DEMO: CLEARED ✓ 已清除 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 2 - CLEARED' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._typeIdx = d.typeIdx; this._dirIdx = d.dirIdx;
    this._samples = d.samples; this._level = d.level;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, progressLine, guideLine, bannerLine, dirLine, levelLine, typeLine;
    const sm = (d) => (this._samples[d] === null ? '未测' : String(this._samples[d]));
    progressLine = '采样：左 ' + sm('左') + ' · 正前方 ' + sm('正前方') + ' · 右 ' + sm('右');
    guideLine = 'LISTEN 守听 · DIR 转向（当前 ' + DIRS[this._dirIdx] + ') · SCAN 采样 · TYPE 选类型 · 确认定格';
    if (this._phase === 'idle') {
      stateLine = '守听没开 — LISTEN 后有响声即亮横幅';
      bannerLine = '没有响声';
      dirLine = '方位：未测 — 转头向声源，SCAN 逐向采样';
      levelLine = '声级：░░░░░░░░░░ 未测';
      typeLine = '类型：未确认 — TYPE 选一项，确认后定格';
    } else if (this._phase === 'listening') {
      stateLine = 'LISTENING — 全向守听中，有响声即亮横幅';
      bannerLine = '守听中…';
      dirLine = '方位：当前朝向 ' + DIRS[this._dirIdx] + ' — 转头后 SCAN 采样';
      levelLine = '声级：' + this._bar() + ' ' + this._level;
      typeLine = '类型：' + TYPES[this._typeIdx] + '（待确认，声级计不认电器）';
    } else if (this._phase === 'alert') {
      stateLine = 'ALERT — 有响声！转头采样方位，再 TYPE + 确认';
      bannerLine = '⚠ 有响声！';
      const best = this._bestDir();
      dirLine = '方位：' + (best ? best + '方向目前最响' : '还没采样 — 转头向声源 SCAN');
      levelLine = '声级：' + this._bar() + ' ' + this._level;
      typeLine = '类型：' + TYPES[this._typeIdx] + '（你亲眼确认，点确认定格）';
    } else {
      const best = this._bestDir();
      stateLine = 'TRIAGED ✓ 分诊已定格 — 处理完点清除';
      bannerLine = TYPES[this._typeIdx] + ' · ' + (best || '方位未采样');
      dirLine = '方位：' + (best ? best + '方向最响' : '方位未采样（只定了类型）');
      levelLine = '声级：' + this._bar() + ' ' + this._level;
      typeLine = '类型：' + TYPES[this._typeIdx] + '（佩戴者确认，非自动识别）';
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    this.setData({
      stateLine: stateLine,
      progressLine: progressLine,
      guideLine: guideLine,
      bannerLine: bannerLine,
      dirLine: dirLine,
      levelLine: levelLine,
      typeLine: typeLine
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">ALARM TRIAGE VISUAL</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ micLine }}</div>

    <div class="banner">
      <div class="big">{{ bannerLine }}</div>
      <div class="bline">{{ dirLine }}</div>
      <div class="bline">{{ levelLine }}</div>
      <div class="bline">{{ typeLine }}</div>
    </div>

    <div class="box">
      <div class="stateline">{{ stateLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="listenTap">LISTEN</button>
      <button class="btn" bindtap="scanTap">SCAN</button>
      <button class="btn" bindtap="dirTap">DIR</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="confirmTap">确认 ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="typeTap">TYPE</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="helpTap">HELP</button>
      <button class="btn" bindtap="clearTap">清除</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">零语音依赖 · 声级计不认电器，类型永远由佩戴者亲眼确认</div>
  </div>
</template>

<style>
.page {
  width: 480px;
  height: 352px;
  background-color: #000000;
  padding: 10px 14px;
  box-sizing: border-box;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 2px;
}
.status {
  color: #7dff9e;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.sub {
  color: rgba(64, 255, 94, 0.62);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.banner {
  margin-top: 4px;
  border: 3px solid rgba(64, 255, 94, 0.95);
  background-color: #0d3d16;
  padding: 4px 10px;
  text-align: center;
}
.big {
  color: #7dff9e;
  font-size: 32px;
  font-weight: bold;
  line-height: 36px;
  white-space: nowrap;
  overflow: hidden;
}
.bline {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.box {
  margin-top: 4px;
  border: 1px solid rgba(64, 255, 94, 0.45);
  padding: 4px 8px;
}
.stateline {
  color: #7dff9e;
  font-size: 12px;
  font-weight: bold;
  line-height: 16px;
  white-space: nowrap;
  overflow: hidden;
}
.nums {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.rate {
  color: rgba(64, 255, 94, 0.85);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.btnrow {
  display: flex;
  flex-direction: row;
  margin-top: 4px;
}
.btn {
  flex: 1;
  margin-right: 6px;
  background-color: #0d2812;
  color: #40ff5e;
  border: 1px solid rgba(64, 255, 94, 0.72);
  font-size: 13px;
  padding: 3px 0;
  text-align: center;
}
.btnrow .btn:last-child {
  margin-right: 0;
}
.btn-main {
  background-color: #14541f;
  color: #7dff9e;
  font-weight: bold;
}
.foot {
  color: rgba(64, 255, 94, 0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 4px;
  white-space: nowrap;
  overflow: hidden;
}
.foot2 {
  color: rgba(64, 255, 94, 0.48);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
</style>
