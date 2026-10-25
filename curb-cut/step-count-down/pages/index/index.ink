<script def>
{
  "title": "Step Count Down"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Step Count Down (Curb-Cut CC03, HOLD/COVER family): stair countdown
// for blind / low-vision wearers. The fear on an unfamiliar staircase
// is not "where are the stairs" but "how many steps are left" — the
// last step is where people fall. The agent holds the total: at the
// top, COUNT photographs the flight (wide photo + host LanguageModel,
// prompted to answer ONLY a step count or NONE) or the wearer enters
// the total by stepper / dictation. Going down, every step the wearer
// takes is confirmed by them (STEP button or steady nod); the agent
// counts down, speaks every remaining step from 3 down, warns on the
// last step, and says plainly when the bottom is reached.
// Honesty rule: the count is NEVER advanced automatically from head
// pitch. Pitch per step varies with gait, cane use and handrails, so
// an auto-advance would silently drift — exactly the failure that
// causes a fall. Each step is wearer-confirmed; a missed tap is a
// visible, correctable off-by-one, never a silent drift. Pitch is
// therefore not read at all. Nothing is persisted: no storage calls.
// -------------------------------------------------------------------

const TICK_MS = 250;
const MAX_STEPS = 99;

export default {
  data: {
    status: 'SETUP: 先数清这段楼梯一共几级',
    photoLine: 'PHOTO: 未试 — 只数总级数，从不描述场景',
    micLine: 'MIC CHECK: not run - DICT 前先查佩戴者麦',
    bigLine: '—— 级',
    barLine: '还没有总级数',
    stateLine: '填好总级数，GO 开始下楼 — 每下一级确认一次',
    progressLine: '已下 0 级 · 还剩 — 级',
    guideLine: 'COUNT 拍照数级 · ↑ +1 · ↓ −1 · +10 赶步',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'setup'; // setup | counting | done
    this._total = null;
    this._remaining = null;
    this._descended = 0;
    this._tickCount = 0;
    this._steady = false;
    this._nodAt = -100000;
    this._rec = null;
    this._listening = false;
    this._busy = false;
    this._demo = null;
    this._demoStep = 0;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._recompute();
  },

  onShow() {},
  onHide() { this._stopRec(); },
  onUnload() { this._stopRec(); },

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
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  _fmt(v) { return v === null ? '—' : String(v); },

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
    if (this._phase === 'counting') {
      this.stepTap();
      this.setData({ lastEvent: 'EVT: nod (steady) -> STEP down one' });
    } else {
      this.speakTap();
      this.setData({ lastEvent: 'EVT: nod (steady) -> SPEAK only' });
    }
    this._recompute();
  },

  // ---- temple keys ---------------------------------------------------
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._stepTotal(1, 'key'); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._stepTotal(-1, 'key'); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- buttons -------------------------------------------------------
  plus1Tap() { this._stepTotal(1, 'btn'); },
  plus10Tap() { this._stepTotal(10, 'btn'); },
  minus1Tap() { this._stepTotal(-1, 'btn'); },

  _stepTotal(delta, source) {
    if (this._busy) return;
    if (this._phase !== 'setup') {
      this.setData({ lastEvent: 'EVT: total is locked once counting starts - GO starts fresh after DONE' });
      this._recompute();
      return;
    }
    let v = (this._total === null ? 0 : this._total) + delta;
    if (v < 0) v = 0;
    if (v > MAX_STEPS) v = MAX_STEPS;
    this._total = v;
    this.setData({ lastEvent: 'EVT: TOTAL -> ' + v + (source === 'key' ? ' (swipe)' : ' (stepper)') });
    this._recompute();
  },

  goTap() {
    if (this._busy) return;
    if (this._phase === 'setup') {
      if (this._total === null || this._total <= 0) {
        this.setData({ status: '先填总级数：这段楼梯一共几级？', lastEvent: 'EVT: start refused - no total steps' });
        this._recompute();
        return;
      }
      this._phase = 'counting';
      this._remaining = this._total;
      this._descended = 0;
      const ok = this._speakText('开始下楼，共' + this._total + '级，每下一级点一下 STEP 或者点头');
      this.setData({
        status: 'COUNTING: 下楼中 — 每下一级 STEP / 点头确认一次',
        lastEvent: 'EVT: counting started total ' + this._total + (ok ? ' (spoken)' : '')
      });
      this._recompute();
      return;
    }
    if (this._phase === 'counting') {
      this.stepTap();
      return;
    }
    if (this._phase === 'done') {
      this._phase = 'setup';
      this._total = null;
      this._remaining = null;
      this._descended = 0;
      this.setData({ status: 'SETUP: 新的一段 — 先数清这段楼梯一共几级', lastEvent: 'EVT: fresh setup' });
      this._recompute();
      return;
    }
  },

  speakTap() {
    let text;
    if (this._phase === 'setup') {
      text = this._total === null ? '还没填总级数，拍照 COUNT 或者步进填好点 GO 开始下楼。' : '这段楼梯共' + this._total + '级，点 GO 开始下楼。';
    } else if (this._phase === 'counting') {
      text = '共' + this._total + '级，已下' + this._descended + '级，还剩' + this._remaining + '级。';
    } else {
      text = '已到底，本段结束，点 GO 开始新的一段。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read status aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  // ---- STEP: one wearer-confirmed step down --------------------------
  stepTap() {
    if (this._phase !== 'counting') {
      this.setData({ lastEvent: 'EVT: STEP only while counting' });
      this._recompute();
      return;
    }
    if (this._busy) return;
    this._remaining--;
    this._descended++;
    if (this._remaining <= 0) {
      this._remaining = 0;
      this._phase = 'done';
      const ok = this._speakText('已到底，小心站稳，本段结束');
      this.setData({ status: 'DONE ✓ 已到底 — 站稳，GO 开始新的一段', lastEvent: 'EVT: DONE - bottom reached' + (ok ? ' (spoken)' : '') });
      this._recompute();
      return;
    }
    let spoken = '';
    if (this._remaining === 1) {
      const ok = this._speakText('最后一级，踩稳再下');
      spoken = ok ? ' (spoken)' : '';
      this.setData({ status: '最后一级 — 踩稳再下', lastEvent: 'EVT: STEP -> last step warning' + spoken });
    } else if (this._remaining <= 3) {
      const ok = this._speakText('还剩' + this._remaining + '级');
      spoken = ok ? ' (spoken)' : '';
      this.setData({ status: '还剩 ' + this._remaining + '级 — 慢一点', lastEvent: 'EVT: STEP -> remaining ' + this._remaining + spoken });
    } else {
      this.setData({ lastEvent: 'EVT: STEP -> descended ' + this._descended + ', remaining ' + this._remaining + ' (spoken only at <=3)' });
    }
    this._recompute();
  },

  // ---- COUNT: wide photo + LLM, step count only ----------------------
  async countTap() {
    if (this._phase !== 'setup') {
      this.setData({ lastEvent: 'EVT: COUNT only during setup' });
      this._recompute();
      return;
    }
    if (this._busy) return;
    this._busy = true;
    this.setData({ photoLine: 'PHOTO: 正在拍整段楼梯…（只数级数）', lastEvent: 'EVT: COUNT photo attempt started' });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof ImageCapture === 'undefined') {
        this.setData({ photoLine: 'PHOTO: SKIP — 本机无相机拍照路径，改用步进/口述填总级数' });
        return;
      }
      const stream = await nav.mediaDevices.getUserMedia({ video: true });
      let blob = null;
      try {
        const track = stream.getVideoTracks()[0];
        const cap = new ImageCapture(track);
        blob = await cap.takePhoto({ mode: 'wide' });
      } finally {
        stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
      }
      if (!blob) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没拍到照片，再对准楼梯一点' });
        return;
      }
      if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) {
        this.setData({ photoLine: 'PHOTO: SKIP — 拍到了，但本机无 LLM 看图，改用步进/口述' });
        return;
      }
      const avail = await LanguageModel.availability();
      if (avail !== 'available') {
        this.setData({ photoLine: 'PHOTO: SKIP — LLM 不可用（' + avail + '），改用步进/口述' });
        return;
      }
      const session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: '只回答楼梯级数数字，例如12；数不清回答NONE，不要解释。' }] });
      const dataUrl = await new Promise((resolve, reject) => {
        const r = new FileReader();
        r.onload = () => resolve(r.result);
        r.onerror = () => reject(new Error('blob read fail'));
        r.readAsDataURL(blob);
      });
      const ans = await session.prompt([
        { type: 'text', text: '这段楼梯一共有几级台阶？只回答数字或NONE。' },
        { type: 'image_url', image_url: { url: dataUrl } }
      ]);
      try { session.destroy(); } catch (e) {}
      const m = String(ans).match(/(\d{1,2})/);
      if (!m) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没数清级数（LLM 答：' + String(ans).slice(0, 20) + '），改用步进/口述' });
        return;
      }
      const v = parseInt(m[1], 10);
      if (v <= 0 || v > MAX_STEPS) {
        this.setData({ photoLine: 'PHOTO: SKIP — 数到的级数超出范围，改用步进/口述' });
        return;
      }
      this._total = v;
      this.setData({ photoLine: 'PHOTO: 数到共 ' + v + '级 — 请核对一眼再 GO', lastEvent: 'EVT: COUNT -> total ' + v + ' (photo)' });
    } catch (e) {
      this.setData({ photoLine: 'PHOTO: SKIP — ' + this._err('photo FAIL', e) + '，改用步进/口述' });
    } finally {
      this._busy = false;
      this._recompute();
    }
  },

  // ---- DICT: mic check FIRST, then host ASR ---------------------------
  _cnDigits() {
    return { '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9 };
  },
  _cnInt(str) {
    if (str.indexOf('万') >= 0) return null;
    const dig = this._cnDigits();
    const units = { '十': 10, '百': 100, '千': 1000 };
    let section = 0;
    let pending = -1;
    let lastUnit = 1;
    for (let i = 0; i < str.length; i++) {
      const ch = str.charAt(i);
      if (dig[ch] !== undefined) {
        if (pending >= 0) {
          section += pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
          if (lastUnit > 1) lastUnit = lastUnit / 10;
          pending = -1;
        }
        pending = dig[ch];
        continue;
      }
      if (units[ch] !== undefined) {
        if (pending < 0) pending = 1;
        section += pending * units[ch];
        lastUnit = units[ch];
        pending = -1;
        continue;
      }
      return null;
    }
    if (pending >= 0) section += str.length === 1 ? pending : pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
    return section;
  },
  _parseStepCount(raw) {
    if (!raw) return null;
    let s = String(raw).replace(/\s+/g, '');
    s = s.replace(/^(现在|当前|是|一共|总共|有)+/g, '');
    s = s.replace(/(级|阶|步|啦|了)$/g, '');
    if (!s) return null;
    const m = s.match(/(\d{1,2})/);
    if (m) {
      const v = parseInt(m[1], 10);
      return (v >= 0 && v <= MAX_STEPS) ? v : null;
    }
    const v = this._cnInt(s);
    if (v === null || v === undefined || isNaN(v)) return null;
    return (v >= 0 && v <= MAX_STEPS) ? v : null;
  },
  dictTap() {
    if (this._busy) return null;
    if (this._phase !== 'setup') {
      this.setData({ lastEvent: 'EVT: DICT only during setup' });
      this._recompute();
      return null;
    }
    this._busy = true;
    return this._dictListen().then(() => { this._busy = false; });
  },
  async _checkWearerMic() {
    const nav = (typeof navigator !== 'undefined') ? navigator : null;
    if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) {
      this.setData({ micLine: 'MIC CHECK: n/a on this host - dictation uses host ASR only' });
      return;
    }
    let stream = null;
    try {
      try {
        stream = await this._withTimeout(
          nav.mediaDevices.getUserMedia({ audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true } }),
          5000, 'mic check');
      } catch (e1) {
        if (e1 && e1.name === 'OverconstrainedError') {
          stream = await this._withTimeout(nav.mediaDevices.getUserMedia({ audio: true }), 5000, 'mic check fallback');
        } else throw e1;
      }
      const tracks = stream && stream.getAudioTracks ? stream.getAudioTracks() : [];
      const t = tracks[0];
      const st = (t && t.getSettings) ? t.getSettings() : {};
      const mode = st.microphoneMode || 'default (mode not reported)';
      this.setData({ micLine: 'MIC CHECK: wearer-mode stream OK · mode read back: ' + mode });
    } catch (e) {
      this.setData({ micLine: 'MIC CHECK: ' + this._err('mic check FAIL', e) + ' - dictation still tries host ASR' });
    } finally {
      if (stream && stream.getAudioTracks) stream.getAudioTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
    }
  },
  _stopRec() {
    if (this._rec) { try { this._rec.stop(); } catch (e) {} this._rec = null; }
    this._listening = false;
  },
  async _dictListen() {
    await this._checkWearerMic();
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({ lastEvent: 'EVT: DICT SKIP - host SpeechRecognition n/a; use the stepper' });
      this._recompute();
      return;
    }
    this._stopRec();
    const rec = new SpeechRecognition();
    this._rec = rec;
    rec.lang = 'zh-CN';
    rec.interimResults = false;
    rec.maxAlternatives = 1;
    rec.onresult = (ev) => {
      let heard = '';
      try {
        const res = ev.results[ev.resultIndex || 0];
        heard = (res && res[0] && res[0].transcript) || '';
      } catch (e) { heard = ''; }
      const v = this._parseStepCount(heard);
      if (v === null) {
        this.setData({ status: '没听清成级数：「' + (heard || '(empty)') + '」— 没猜，总级数没变', lastEvent: 'EVT: DICT parse FAIL - "' + heard + '" rejected, value unchanged' });
      } else {
        this._total = v;
        this.setData({ status: 'DICT 已填总级数 = ' + v + '级 — 请核对一眼', lastEvent: 'EVT: DICT "' + heard + '" -> TOTAL ' + v });
      }
      this._recompute();
    };
    rec.onerror = () => {
      this._listening = false;
      this.setData({ lastEvent: 'EVT: DICT host ASR error - value unchanged' });
      this._recompute();
    };
    rec.onend = () => { this._listening = false; };
    try {
      rec.start();
      this._listening = true;
      this.setData({ status: 'DICT 聆听中（host ASR）— 说出这段楼梯一共几级', lastEvent: 'EVT: DICT listening (host ASR) for TOTAL' });
    } catch (e) {
      this.setData({ lastEvent: this._err('DICT start FAIL', e) });
    }
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: total 12; counting; 9 left; 3 left (warning zone);
  // 1 left (last step); DONE (bottom). A further tap restores the
  // real state exactly.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, total: this._total, remaining: this._remaining, descended: this._descended
      };
      this._demoStep = 0;
      this._phase = 'setup';
      this._total = 12;
      this._remaining = null;
      this._descended = 0;
      this.setData({ status: 'DEMO: 这段楼梯共 12 级 — 再点 DEMO = 开始下楼', lastEvent: 'EVT: DEMO on - total 12 seeded in memory' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'counting';
      this._remaining = 12;
      this._descended = 0;
      this.setData({ status: 'DEMO: 下楼中 — 再点 DEMO = 下了 3 级', lastEvent: 'EVT: DEMO step 1 - counting started' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._phase = 'counting';
      this._remaining = 9;
      this._descended = 3;
      this.setData({ status: 'DEMO: 下了 3 级 — 再点 DEMO = 只剩 3 级', lastEvent: 'EVT: DEMO step 2 - remaining 9' });
      this._recompute();
      return;
    }
    if (this._demoStep === 3) {
      this._phase = 'counting';
      this._remaining = 3;
      this._descended = 9;
      this.setData({ status: 'DEMO: 还剩 3 级 — 慢一点，再点 DEMO = 最后一级', lastEvent: 'EVT: DEMO step 3 - warning zone 3' });
      this._recompute();
      return;
    }
    if (this._demoStep === 4) {
      this._phase = 'counting';
      this._remaining = 1;
      this._descended = 11;
      this.setData({ status: 'DEMO: 最后一级 — 踩稳再下，再点 DEMO = 已到底', lastEvent: 'EVT: DEMO step 4 - last step' });
      this._recompute();
      return;
    }
    if (this._demoStep === 5) {
      this._phase = 'done';
      this._remaining = 0;
      this._descended = 12;
      this.setData({ status: 'DEMO: DONE ✓ 已到底 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 5 - DONE' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._total = d.total; this._remaining = d.remaining; this._descended = d.descended;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, progressLine, guideLine, bigLine, barLine;
    if (this._phase === 'setup') {
      stateLine = '填好总级数，GO 开始下楼 — 每下一级确认一次';
      progressLine = '已下 0 级 · 还剩 — 级';
      guideLine = 'COUNT 拍照数级 · ↑ +1 · ↓ −1 · +10 赶步 · DICT 口述级数';
      bigLine = this._total === null ? '未数级' : '共 ' + this._total + ' 级';
      barLine = this._total === null ? '还没有总级数 — COUNT / 步进 / DICT 三选一' : '梯口已数清：共 ' + this._total + ' 级，GO 开始下楼';
    } else if (this._phase === 'counting') {
      stateLine = 'COUNTING — 下楼中，每下一级 STEP / 点头确认一次';
      progressLine = '已下 ' + this._descended + ' 级 · 还剩 ' + this._remaining + ' 级';
      guideLine = 'STEP = 下一级 · 点头 = 下一级 · GO = 下一级 · SPEAK 听状态';
      bigLine = '还剩 ' + this._remaining + ' 级';
      let bar = '';
      for (let i = 0; i < this._total; i++) bar += (i < this._descended) ? '█' : '░';
      barLine = '▸ ' + bar + ' （█ 已下 · ░ 未下）';
      if (this._remaining <= 3) stateLine = '⚠ 还剩 ' + this._remaining + '级 — 慢一点' + (this._remaining === 1 ? '，最后一级踩稳' : '');
    } else {
      stateLine = 'DONE ✓ 已到底 — 站稳，GO 开始新的一段';
      progressLine = '已下 ' + this._descended + ' 级 · 还剩 0 级';
      guideLine = 'GO 开始新的一段';
      bigLine = '已到底 ✓';
      barLine = '▸ ' + '█'.repeat(this._descended) + ' 全段走完';
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    this.setData({
      stateLine: stateLine,
      progressLine: progressLine,
      guideLine: guideLine,
      bigLine: bigLine,
      barLine: barLine
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">STEP COUNT DOWN</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ photoLine }}</div>
    <div class="sub">{{ micLine }}</div>

    <div class="dial">
      <div class="big">{{ bigLine }}</div>
      <div class="bar">{{ barLine }}</div>
    </div>

    <div class="box">
      <div class="stateline">{{ stateLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="plus10Tap">+10</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="countTap">COUNT</button>
      <button class="btn" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="stepTap">STEP</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">每级都由你确认 · 剩 3 级起逐级播报 · 从不自动递减</div>
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
.dial {
  margin-top: 4px;
  border: 2px solid rgba(64, 255, 94, 0.85);
  background-color: rgba(64, 255, 94, 0.10);
  padding: 4px 10px;
  text-align: center;
}
.big {
  color: #7dff9e;
  font-size: 36px;
  font-weight: bold;
  line-height: 38px;
  white-space: nowrap;
  overflow: hidden;
}
.bar {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 2px;
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
