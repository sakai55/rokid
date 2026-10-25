<script def>
{
  "title": "Last Sentence"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Last Sentence (Curb-Cut CC07, REVIEW/HOLD family): a replayable
// last sentence for deaf and auditory-processing listeners. In a
// fast group conversation, missing one sentence derails the whole
// thread that follows — and a live caption stream scrolls past and
// never comes back. This agent keeps the recent sentences instead
// of letting them vanish:
// (1) LISTEN runs a far-field mic check FIRST, then host ASR
// (continuous where the host supports it); each completed
// transcript is split into sentences and appended to a rolling
// list (last 6 kept, older ones dropped, honestly — this is a
// short rolling window, not a meeting transcript).
// (2) 上一句 freezes the PREVIOUS sentence — the one before the
// latest — in huge type and stops the display from advancing,
// even while new speech keeps arriving underneath. Nothing is
// lost while you read: the roll keeps growing behind the freeze.
// (3) 继续 unfreezes and returns to the live latest sentence.
// 点头 (steady) = 继续 only: it never freezes, because an
// accidental freeze mid-conversation would be the failure mode.
// Honesty rules: ASR text is shown as heard, never cleaned into
// a different meaning (only surrounding whitespace trimmed);
// with no host SpeechRecognition the agent says SKIP plainly and
// the DEMO still shows the flow; a freeze with fewer than 2
// sentences is refused honestly ("还没攒够两句").
// Nothing is persisted: no storage calls anywhere.
// -------------------------------------------------------------------

const TICK_MS = 250;
const KEEP = 6;

export default {
  data: {
    status: 'IDLE: 点 LISTEN 开始听群聊',
    micLine: 'MIC CHECK: not run - LISTEN 前先查远场模式',
    bigLine: '还没有句子',
    rollLine: '最近句子：还没有',
    frozenLine: '定格：没有定格 — 上一句会把上一句钉在这里',
    stateLine: '没在听 — LISTEN 后句子开始滚动',
    progressLine: '已攒 0 句 · 定格：无',
    guideLine: 'LISTEN 听 · 上一句定格 · 继续回直播 · 回放听一句',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'idle'; // idle | live | frozen
    this._sentences = [];
    this._frozenIdx = -1;
    this._tickCount = 0;
    this._steady = false;
    this._nodAt = -100000;
    this._rec = null;
    this._listening = false;
    this._busy = false;
    this._demo = null;
    this._demoStep = 0;
    this._timer = null;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._startTimer();
    this._recompute();
  },

  onShow() { this._startTimer(); },
  onHide() { this._stopTimer(); this._stopRec(); },
  onUnload() { this._stopTimer(); this._stopRec(); },

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
    // TTS here reads the frozen sentence aloud for a listener who
    // wants to hear it again, or for a helper nearby; the primary
    // channel for the deaf wearer is always the frozen text.
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
  },

  _splitSentences(text) {
    if (!text) return [];
    const parts = String(text).split(/([。！？!?；;])/);
    const out = [];
    let cur = '';
    for (let i = 0; i < parts.length; i++) {
      cur += parts[i];
      if (/[。！？!?；;]/.test(parts[i]) || i === parts.length - 1) {
        const s = cur.trim();
        if (s) out.push(s);
        cur = '';
      }
    }
    return out;
  },
  _pushSentence(s) {
    this._sentences.push(s);
    while (this._sentences.length > KEEP) this._sentences.shift();
    if (this._frozenIdx >= 0) {
      // Keep the frozen sentence pinned even as the roll shifts:
      // the frozen text is stored separately at freeze time.
    }
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
    if (this._phase === 'frozen') {
      this.resumeTap();
      this.setData({ lastEvent: 'EVT: nod (steady) -> 继续 (unfreeze only, never freezes)' });
    } else {
      this.setData({ lastEvent: 'EVT: nod (steady) -> nothing to resume, not frozen' });
    }
    this._recompute();
  },

  // ---- temple keys ---------------------------------------------------
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.listenTap(); return; }
    if (key === 'ArrowUp' || key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- mic: mode FIRST, then host ASR --------------------------------
  _stopRec() {
    if (this._rec) { try { this._rec.stop(); } catch (e) {} this._rec = null; }
    this._listening = false;
  },
  async _checkMic() {
    const nav = (typeof navigator !== 'undefined') ? navigator : null;
    if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) {
      this.setData({ micLine: 'MIC CHECK (far-field): n/a on this host - uses host ASR only' });
      return;
    }
    let stream = null;
    try {
      try {
        stream = await this._withTimeout(
          nav.mediaDevices.getUserMedia({ audio: { captureSource: 'microphone', microphoneMode: 'far-field', echoCancellation: true } }),
          5000, 'mic check');
      } catch (e1) {
        if (e1 && e1.name === 'OverconstrainedError') {
          stream = await this._withTimeout(nav.mediaDevices.getUserMedia({ audio: true }), 5000, 'mic check fallback');
        } else throw e1;
      }
      const tracks = stream && stream.getAudioTracks ? stream.getAudioTracks() : [];
      const t = tracks[0];
      const st = (t && t.getSettings) ? t.getSettings() : {};
      const m = st.microphoneMode || 'default (mode not reported)';
      this.setData({ micLine: 'MIC CHECK (far-field): stream OK · mode read back: ' + m });
    } catch (e) {
      this.setData({ micLine: 'MIC CHECK (far-field): ' + this._err('mic check FAIL', e) + ' - still tries host ASR' });
    } finally {
      if (stream && stream.getAudioTracks) stream.getAudioTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
    }
  },

  // ---- buttons -------------------------------------------------------
  async listenTap() {
    if (this._busy) return null;
    if (this._phase === 'frozen') {
      this.setData({ lastEvent: 'EVT: frozen - 继续 first, LISTEN is already running underneath' });
      this._recompute();
      return null;
    }
    this._busy = true;
    await this._checkMic();
    this._busy = false;
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({ status: 'LISTEN SKIP — 宿主 SpeechRecognition 不可用，句子攒不了；DEMO 可看流程', lastEvent: 'EVT: LISTEN SKIP - host SpeechRecognition n/a' });
      this._recompute();
      return null;
    }
    this._stopRec();
    const rec = new SpeechRecognition();
    this._rec = rec;
    rec.lang = 'zh-CN';
    try { rec.continuous = true; } catch (e) {}
    rec.interimResults = false;
    rec.maxAlternatives = 1;
    rec.onresult = (ev) => {
      try {
        for (let i = ev.resultIndex || 0; i < ev.results.length; i++) {
          const res = ev.results[i];
          if (!res.isFinal) continue;
          const heard = (res[0] && res[0].transcript) || '';
          const ss = this._splitSentences(heard);
          ss.forEach((s) => this._pushSentence(s));
        }
      } catch (e) { /* keep existing roll */ }
      this._recompute();
    };
    rec.onerror = () => {
      this._listening = false;
      this.setData({ lastEvent: 'EVT: LISTEN host ASR error - roll kept' });
      this._recompute();
    };
    rec.onend = () => { this._listening = false; };
    try {
      rec.start();
      this._listening = true;
      this._phase = 'live';
      this.setData({ status: 'LIVE: 听群聊中 — 句子滚动保留最近 6 句', lastEvent: 'EVT: LISTEN live (host ASR, far-field checked)' });
    } catch (e) {
      this.setData({ lastEvent: this._err('LISTEN start FAIL', e) });
    }
    this._recompute();
    return null;
  },

  prevTap() {
    if (this._phase === 'frozen') {
      this.setData({ lastEvent: 'EVT: already frozen - 继续 to return to live first' });
      this._recompute();
      return;
    }
    if (this._sentences.length < 2) {
      this.setData({ status: '还没攒够两句：只有 ' + this._sentences.length + ' 句 — 先 LISTEN 多听几句', lastEvent: 'EVT: 上一句 refused - fewer than 2 sentences' });
      this._recompute();
      return;
    }
    this._frozenIdx = this._sentences.length - 2;
    this._frozenText = this._sentences[this._frozenIdx];
    this._phase = 'frozen';
    this.setData({ status: 'FROZEN ✓ 上一句已定格 — 看完点头或点继续回直播', lastEvent: 'EVT: FROZEN sentence ' + (this._frozenIdx + 1) + '/' + this._sentences.length });
    this._recompute();
  },

  resumeTap() {
    if (this._phase !== 'frozen') {
      this.setData({ lastEvent: 'EVT: not frozen - nothing to resume' });
      this._recompute();
      return;
    }
    this._phase = 'live';
    this._frozenIdx = -1;
    this._frozenText = '';
    this.setData({ status: 'LIVE: 回直播 — 最新一句在上', lastEvent: 'EVT: resumed to live' });
    this._recompute();
  },

  replayTap() {
    let text;
    if (this._phase === 'frozen') text = this._frozenText;
    else if (this._sentences.length) text = this._sentences[this._sentences.length - 1];
    else text = '还没有句子可以回放，先 LISTEN 听几句。';
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: 回放 ' + (ok ? 'read sentence aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  speakTap() {
    this.replayTap();
  },

  helpTap() {
    const text = '用法：点 LISTEN 开始听群聊，句子会滚动保留最近六句。哪句没跟上，点上一句，那一句会定格在视线里不动，新话继续在后面攒着。看完点头或者点继续，就回到直播。注意：这只是最近六句的滚动窗口，不是会议记录。';
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: HELP ' + (ok ? 'usage spoken' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  clearTap() {
    this._stopRec();
    this._phase = 'idle';
    this._sentences = [];
    this._frozenIdx = -1;
    this._frozenText = '';
    this.setData({ status: 'IDLE: 已清除 — 点 LISTEN 开始新一段群聊', lastEvent: 'EVT: CLEARED - roll wiped' });
    this._recompute();
  },

  resetTap() {
    if (this._phase === 'frozen') this.resumeTap();
    else this.setData({ lastEvent: 'EVT: 复位 - not frozen, already live/idle' });
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: three seeded sentences, then a frozen 上一句
  // (the second sentence), then cleared. A further tap restores the
  // real state. Seeded text is labelled DEMO, never presented as
  // heard speech.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, sentences: this._sentences.slice(),
        frozenIdx: this._frozenIdx, frozenText: this._frozenText || ''
      };
      this._demoStep = 0;
      this._phase = 'live';
      this._sentences = ['我们先去三楼开会。', '预算下周三之前要定下来。', '对了，午饭后别忘了给王老师打电话。'];
      this._frozenIdx = -1;
      this._frozenText = '';
      this.setData({ status: 'DEMO: LIVE 已攒 3 句 — 再点 DEMO = 定格上一句', lastEvent: 'EVT: DEMO on - 3 sentences seeded (demo text, not heard)' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'frozen';
      this._frozenIdx = 1;
      this._frozenText = this._sentences[1];
      this.setData({ status: 'DEMO: FROZEN ✓ 上一句已定格 — 再点 DEMO = 清除', lastEvent: 'EVT: DEMO step 1 - FROZEN sentence 2/3' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._phase = 'idle';
      this._sentences = [];
      this._frozenIdx = -1;
      this._frozenText = '';
      this.setData({ status: 'DEMO: CLEARED ✓ 已清除 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 2 - CLEARED' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._sentences = d.sentences; this._frozenIdx = d.frozenIdx; this._frozenText = d.frozenText;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, progressLine, guideLine, bigLine, rollLine, frozenLine;
    const n = this._sentences.length;
    if (this._phase === 'idle') {
      stateLine = '没在听 — LISTEN 后句子开始滚动';
      bigLine = n ? this._sentences[n - 1] : '还没有句子';
      frozenLine = '定格：没有定格 — 上一句会把上一句钉在这里';
    } else if (this._phase === 'live') {
      stateLine = 'LIVE — 听群聊中，最新一句在上';
      bigLine = n ? this._sentences[n - 1] : '听着，还没有完整句子';
      frozenLine = '定格：没有定格 — 没跟上就点上一句';
    } else {
      stateLine = 'FROZEN ✓ 上一句定格中 — 看完点头或点继续';
      bigLine = this._frozenText || '（定格为空）';
      frozenLine = '定格：第 ' + (this._frozenIdx + 1) + ' / ' + n + ' 句 — 新话仍在后面攒着';
    }
    const roll = [];
    for (let i = Math.max(0, n - 4); i < n; i++) {
      roll.push((i + 1) + '. ' + this._sentences[i]);
    }
    rollLine = '最近句子：' + (roll.length ? roll.join(' ｜ ') : '还没有');
    progressLine = '已攒 ' + n + ' 句（只留最近 6 句） · 定格：' + (this._phase === 'frozen' ? '第 ' + (this._frozenIdx + 1) + ' 句' : '无');
    guideLine = 'LISTEN 听 · 上一句定格 · 继续/点头回直播 · 回放听一句';
    if (demo) stateLine = 'DEMO · ' + stateLine;
    this.setData({
      stateLine: stateLine,
      progressLine: progressLine,
      guideLine: guideLine,
      bigLine: bigLine,
      rollLine: rollLine,
      frozenLine: frozenLine
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">LAST SENTENCE</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ micLine }}</div>

    <div class="card">
      <div class="big">{{ bigLine }}</div>
      <div class="frozen">{{ frozenLine }}</div>
    </div>
    <div class="roll">{{ rollLine }}</div>

    <div class="box">
      <div class="stateline">{{ stateLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="listenTap">LISTEN</button>
      <button class="btn btn-main" bindtap="prevTap">上一句</button>
      <button class="btn" bindtap="resumeTap">继续</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="helpTap">HELP</button>
      <button class="btn" bindtap="clearTap">清除</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="replayTap">回放</button>
      <button class="btn" bindtap="resetTap">复位</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">只留最近 6 句 · 定格时新话仍在后面攒 · 不是会议记录</div>
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
.card {
  margin-top: 4px;
  border: 2px solid rgba(64, 255, 94, 0.85);
  background-color: rgba(64, 255, 94, 0.08);
  padding: 4px 10px;
}
.big {
  color: #7dff9e;
  font-size: 22px;
  font-weight: bold;
  line-height: 26px;
  white-space: nowrap;
  overflow: hidden;
}
.frozen {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.roll {
  color: rgba(64, 255, 94, 0.85);
  font-size: 11px;
  line-height: 15px;
  margin-top: 3px;
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
