<script def>
{
  "title": "My Bus Watch"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// My Bus Watch (Curb-Cut CC02, FILTER family): target-route bus watch
// for blind / low-vision wearers.
// The problem it outsources is NOT "what bus is that" in general
// (that is Huiyan territory) but "is THAT bus MY bus?" The wearer
// registers exactly one target route; the agent then filters every
// approaching bus to a single verdict: this is your bus, or this is
// route X, not yours, keep waiting. It never describes the street
// or the bus, never listens to announcements, and never speaks for
// a route the wearer did not register.
// How a bus is checked: the wearer hears a bus coming, aims their
// head at it, and taps CHECK (or steady-nods). CHECK takes a
// telephoto photo of the head sign and asks the host LanguageModel
// for ONLY a route number (or NONE); the parsed number is compared
// with the target. A manual fallback exists: the wearer (or a helper
// telling them) steps in / dictates the observed route, and the same
// comparison runs. Unparseable = SKIP, never a guess.
// Reminders run only while this page is open, on a fixed 2-minute
// look-out cadence. Nothing is persisted: no storage calls anywhere.
// -------------------------------------------------------------------

const TICK_MS = 250;
const TICKS_PER_MIN = 240;
const PROMPT_TICKS = 480; // 2 minutes
const MAX_ROUTE = 9999;

export default {
  data: {
    status: 'SETUP: 先填你要等的那一路车',
    photoLine: 'PHOTO: 未试 — 只核车头线路号，从不描述场景',
    micLine: 'MIC CHECK: not run - DICT 前先查佩戴者麦',
    stateLine: '填好目标线路，GO 开始守车 — 只对这路车出声',
    routeLine: 'TARGET ---路 → 上辆 ---',
    progressLine: '查车 0 次 · 提醒：每 2 分钟留意车声',
    guideLine: 'FIELD 切换：目标线路 ↔ 上辆线路 · ↑ +1 · ↓ −1',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'setup'; // setup | watch | hit | done
    this._target = null;
    this._observed = null;
    this._field = 'target'; // target | observed
    this._tickCount = 0;
    this._sincePrompt = 0;
    this._promptPending = false;
    this._checks = 0;
    this._lastSpokenObserved = null;
    this._saidHit = false;
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
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  _fmt(v) { return v === null ? '---' : String(v); },

  // ---- timer: fixed 2-minute look-out cadence -----------------------
  _startTimer() {
    if (this._timer) return;
    this._timer = setInterval(() => { this._tick(); }, TICK_MS);
  },
  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },
  _tick() {
    this._tickCount++;
    if (this._phase === 'watch' && !this._promptPending) {
      this._sincePrompt++;
      if (this._sincePrompt >= PROMPT_TICKS) this._firePrompt();
    }
  },
  _firePrompt() {
    this._promptPending = true;
    this._sincePrompt = 0;
    const ok = this._speakText('留意一下有没有车来，听到车声就对准车头点 CHECK');
    this.setData({
      status: '👀 留意车声 — 听到车来，对准车头点 CHECK',
      lastEvent: 'EVT: look-out prompt fired ' + (ok ? '(spoken)' : '(SPEAK FAIL)')
    });
    this._recompute();
  },

  // ---- route evaluation: exactly once per new observed value -------
  _evalObserved() {
    if (this._phase !== 'watch' || this._target === null || this._observed === null) return;
    this._promptPending = false;
    this._sincePrompt = 0;
    if (this._observed === this._lastSpokenObserved) return;
    this._lastSpokenObserved = this._observed;
    this._checks++;
    if (this._observed === this._target) {
      this._phase = 'hit';
      this._saidHit = true;
      const ok = this._speakText('就是这辆，' + this._target + '路，上车吧');
      this.setData({
        status: '🎉 就是这辆 ' + this._target + '路 — 上车吧，GO = 已上车',
        lastEvent: 'EVT: HIT target ' + this._target + (ok ? ' (spoken)' : '')
      });
    } else {
      const ok = this._speakText('这辆是' + this._observed + '路，不是你的' + this._target + '路，继续等');
      this.setData({
        status: '不是这辆：' + this._observed + '路 ≠ ' + this._target + '路 — 继续等',
        lastEvent: 'EVT: MISS observed ' + this._observed + ' vs target ' + this._target + (ok ? ' (spoken)' : '')
      });
    }
    this._recompute();
  },

  _setObserved(v, source) {
    this._observed = v;
    this.setData({ lastEvent: 'EVT: observed -> ' + v + '路 (' + source + ')' });
    if (this._phase === 'watch') this._evalObserved();
    else this._recompute();
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
    if (this._phase === 'watch') {
      this.checkTap();
      this.setData({ lastEvent: 'EVT: nod (steady) -> CHECK bus' });
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
    if (key === 'ArrowUp') { event.preventDefault(); this._step(1, 'key'); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._step(-1, 'key'); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- buttons -------------------------------------------------------
  plus1Tap() { this._step(1, 'btn'); },
  plus10Tap() { this._step(10, 'btn'); },
  minus1Tap() { this._step(-1, 'btn'); },

  _step(delta, source) {
    if (this._busy) return;
    if (this._phase === 'hit' || this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: this round is over - GO starts fresh' });
      this._recompute();
      return;
    }
    const field = this._field;
    const cur = field === 'target' ? this._target : this._observed;
    let v = (cur === null ? 0 : cur) + delta;
    if (v < 0) v = 0;
    if (v > MAX_ROUTE) v = MAX_ROUTE;
    if (field === 'target') this._target = v; else this._observed = v;
    this.setData({ lastEvent: 'EVT: ' + (field === 'target' ? 'TARGET' : 'OBSERVED') + ' -> ' + v + (source === 'key' ? ' (swipe)' : ' (stepper)') });
    if (this._phase === 'watch' && field === 'observed') this._evalObserved();
    else this._recompute();
  },

  fieldTap() {
    this._field = this._field === 'target' ? 'observed' : 'target';
    const names = { target: '▸ 目标线路 TARGET', observed: '▸ 上辆线路 OBSERVED' };
    this.setData({ lastEvent: 'EVT: edit field -> ' + names[this._field] });
    this._recompute();
  },

  goTap() {
    if (this._busy) return;
    if (this._phase === 'setup') {
      if (this._target === null || this._target <= 0) {
        this.setData({ status: '先填目标线路：你要等的是几路车？', lastEvent: 'EVT: start refused - no target route' });
        this._recompute();
        return;
      }
      this._phase = 'watch';
      this._field = 'observed';
      this._sincePrompt = 0;
      this._promptPending = false;
      this._checks = 0;
      this._lastSpokenObserved = null;
      this._saidHit = false;
      const ok = this._speakText('开始守' + this._target + '路车，听到车声就对准车头点 CHECK');
      this.setData({
        status: 'WATCHING: 守 ' + this._target + '路车 — 听到车声点 CHECK',
        lastEvent: 'EVT: watch started target ' + this._target + (ok ? ' (spoken)' : '')
      });
      this._recompute();
      return;
    }
    if (this._phase === 'watch') {
      if (this._promptPending) {
        this._promptPending = false;
        this._sincePrompt = 0;
        this.setData({ status: '已稍后 — 一个节律后再提醒你留意车声', lastEvent: 'EVT: LATER - prompt snoozed one cadence' });
        this._recompute();
        return;
      }
      this.speakTap();
      return;
    }
    if (this._phase === 'hit') {
      this._phase = 'done';
      this.setData({ status: 'DONE ✓ 已上车，本轮结束', lastEvent: 'EVT: DONE - boarded' });
      this._recompute();
      return;
    }
    this._phase = 'setup';
    this._target = null;
    this._observed = null;
    this._field = 'target';
    this._checks = 0;
    this._lastSpokenObserved = null;
    this._saidHit = false;
    this._promptPending = false;
    this.setData({ status: 'SETUP: 新的一轮 — 先填你要等的那一路车', lastEvent: 'EVT: fresh setup' });
    this._recompute();
  },

  speakTap() {
    let text;
    if (this._phase === 'setup') {
      text = this._target === null ? '还没填目标线路，填好点 GO 开始守车。' : '你要等的是' + this._target + '路，点 GO 开始守车。';
    } else if (this._phase === 'watch') {
      text = '守' + this._target + '路车，已查' + this._checks + '辆车。' + (this._observed === null ? '还没查过车，听到车声点 CHECK。' : '上一辆是' + this._observed + '路。');
    } else if (this._phase === 'hit') {
      text = '就是这辆，' + this._target + '路，上车吧。';
    } else {
      text = '本轮已结束，点 GO 开始新的一轮。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read status aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  // ---- CHECK: telephoto photo + LLM, route number only ---------------
  async checkTap() {
    if (this._phase !== 'watch') {
      this.setData({ lastEvent: 'EVT: CHECK only during watch' });
      this._recompute();
      return;
    }
    if (this._busy) return;
    this._busy = true;
    this.setData({ photoLine: 'PHOTO: 正在拍车头…（只核线路号）', lastEvent: 'EVT: CHECK photo attempt started' });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof ImageCapture === 'undefined') {
        this.setData({ photoLine: 'PHOTO: SKIP — 本机无相机拍照路径，改用步进/口述填上辆线路' });
        return;
      }
      const stream = await nav.mediaDevices.getUserMedia({ video: true });
      let blob = null;
      try {
        const track = stream.getVideoTracks()[0];
        const cap = new ImageCapture(track);
        blob = await cap.takePhoto({ mode: 'telephoto' });
      } finally {
        stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
      }
      if (!blob) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没拍到照片，再对准一点' });
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
      const session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: '只回答线路号数字，例如128；读不清回答NONE，不要解释。' }] });
      const dataUrl = await new Promise((resolve, reject) => {
        const r = new FileReader();
        r.onload = () => resolve(r.result);
        r.onerror = () => reject(new Error('blob read fail'));
        r.readAsDataURL(blob);
      });
      const ans = await session.prompt([
        { type: 'text', text: '这辆公交车头线路号是多少？只回答数字或NONE。' },
        { type: 'image_url', image_url: { url: dataUrl } }
      ]);
      try { session.destroy(); } catch (e) {}
      const m = String(ans).match(/(\d{1,4})/);
      if (!m) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没读清车头号（LLM 答：' + String(ans).slice(0, 20) + '），再对准一点' });
        return;
      }
      const v = parseInt(m[1], 10);
      if (v <= 0 || v > MAX_ROUTE) {
        this.setData({ photoLine: 'PHOTO: SKIP — 读到的号超出范围，改用步进/口述' });
        return;
      }
      this.setData({ photoLine: 'PHOTO: 读到 ' + v + '路 — 正在比对目标' });
      this._setObserved(v, 'photo');
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
    if (str.indexOf('万') >= 0) return null; // route numbers never reach 万
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
  _parseRouteNumber(raw) {
    if (!raw) return null;
    let s = String(raw).replace(/\s+/g, '');
    s = s.replace(/^(现在|当前|是|这辆是|来了|车是)+/g, '');
    s = s.replace(/(路|号|车|啦|了)$/g, '');
    if (!s) return null;
    const m = s.match(/(\d{1,4})/);
    if (m) {
      const v = parseInt(m[1], 10);
      return (v >= 0 && v <= MAX_ROUTE) ? v : null;
    }
    const v = this._cnInt(s);
    if (v === null || v === undefined || isNaN(v)) return null;
    return (v >= 0 && v <= MAX_ROUTE) ? v : null;
  },
  dictTap() {
    if (this._busy) return null;
    if (this._phase === 'hit' || this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: this round is over - GO starts fresh' });
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
    const field = this._field;
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
      const v = this._parseRouteNumber(heard);
      if (v === null) {
        this.setData({ status: '没听清成线路号：「' + (heard || '(empty)') + '」— 没猜，号码没变', lastEvent: 'EVT: DICT parse FAIL - "' + heard + '" rejected, value unchanged' });
      } else {
        if (field === 'target') this._target = v; else this._observed = v;
        this.setData({ status: 'DICT 已填 ' + (field === 'target' ? '目标线路' : '上辆线路') + ' = ' + v + '路 — 请核对一眼', lastEvent: 'EVT: DICT "' + heard + '" -> ' + (field === 'target' ? 'TARGET' : 'OBSERVED') + ' ' + v });
        if (this._phase === 'watch' && field === 'observed') this._evalObserved();
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
      this.setData({ status: 'DICT 聆听中（host ASR）— 说出' + (field === 'target' ? '你要等的线路' : '上辆车的线路'), lastEvent: 'EVT: DICT listening (host ASR) for ' + (field === 'target' ? 'TARGET' : 'OBSERVED') });
    } catch (e) {
      this.setData({ lastEvent: this._err('DICT start FAIL', e) });
    }
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: target 128; watch; 56 miss; 120 miss; 128 HIT.
  // A further tap restores the real state exactly.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, target: this._target, observed: this._observed,
        field: this._field, checks: this._checks, lastSpoken: this._lastSpokenObserved,
        saidHit: this._saidHit, promptPending: this._promptPending, sincePrompt: this._sincePrompt
      };
      this._demoStep = 0;
      this._phase = 'setup';
      this._target = 128;
      this._observed = null;
      this._field = 'target';
      this._checks = 0;
      this._lastSpokenObserved = null;
      this._saidHit = false;
      this._promptPending = false;
      this.setData({ status: 'DEMO: 要等 128路 — 再点 DEMO = 开始守车', lastEvent: 'EVT: DEMO on - target 128 seeded in memory' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'watch';
      this._field = 'observed';
      this.setData({ status: 'DEMO: 守 128路中 — 再点 DEMO = 来了一辆 56路', lastEvent: 'EVT: DEMO step 1 - watch started' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._setObserved(56, 'demo');
      this.setData({ status: 'DEMO: 来了 56路，不是你的 — 再点 DEMO = 来了一辆 120路', lastEvent: 'EVT: DEMO step 2 - MISS 56' });
      this._recompute();
      return;
    }
    if (this._demoStep === 3) {
      this._setObserved(120, 'demo');
      this.setData({ status: 'DEMO: 来了 120路，不是你的 — 再点 DEMO = 来了 128路', lastEvent: 'EVT: DEMO step 3 - MISS 120' });
      this._recompute();
      return;
    }
    if (this._demoStep === 4) {
      this._setObserved(128, 'demo');
      this.setData({ status: 'DEMO: HIT ✓ 就是这辆 128路 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 4 - HIT 128' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._target = d.target; this._observed = d.observed;
    this._field = d.field; this._checks = d.checks; this._lastSpokenObserved = d.lastSpoken;
    this._saidHit = d.saidHit; this._promptPending = d.promptPending; this._sincePrompt = d.sincePrompt;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, routeLine, progressLine, guideLine;
    routeLine = 'TARGET ' + this._fmt(this._target) + '路 → 上辆 ' + this._fmt(this._observed) + (this._observed === null ? '' : '路') + ' · 查车 ' + this._checks + ' 次';
    if (this._phase === 'setup') {
      stateLine = '填好目标线路，GO 开始守车 — 只对这路车出声';
      progressLine = '查车 0 次 · 提醒：每 2 分钟留意车声';
      guideLine = 'FIELD 切换：目标线路 ↔ 上辆线路 · ↑ +1 · ↓ −1 · +10 赶步';
    } else if (this._phase === 'watch') {
      if (this._promptPending) {
        stateLine = '👀 留意车声 — 听到车来，对准车头点 CHECK';
      } else {
        stateLine = 'WATCHING — 守 ' + this._target + '路车，听到车声点 CHECK';
      }
      progressLine = '查车 ' + this._checks + ' 次 · 提醒：每 2 分钟留意车声' + (this._observed === null ? '' : ' · 上辆 ' + this._observed + '路');
      guideLine = 'CHECK=拍车头核线路 · FIELD 换编辑项 · GO=稍后/朗读 · 点头=CHECK';
    } else if (this._phase === 'hit') {
      stateLine = '🎉 就是这辆 ' + this._target + '路 — 上车吧，GO = 已上车';
      progressLine = '查车 ' + this._checks + ' 次 · 命中：' + this._target + '路';
      guideLine = 'GO 开始新的一轮 · SPEAK 再听一遍';
    } else {
      stateLine = 'DONE ✓ 已上车，本轮结束 — GO 开始新的一轮';
      progressLine = '查车 ' + this._checks + ' 次 · 本轮已结束';
      guideLine = 'GO 开始新的一轮';
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    const fieldNames = { target: '▸ 目标线路 TARGET', observed: '▸ 上辆线路 OBSERVED' };
    this.setData({
      stateLine: stateLine,
      routeLine: routeLine,
      progressLine: progressLine,
      guideLine: guideLine + ' · 当前编辑：' + fieldNames[this._field]
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">MY BUS WATCH</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ photoLine }}</div>
    <div class="sub">{{ micLine }}</div>

    <div class="alertbox">
      <div class="stateline">{{ stateLine }}</div>
    </div>

    <div class="box">
      <div class="watchline">{{ routeLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="plus10Tap">+10</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="fieldTap">FIELD</button>
      <button class="btn" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="checkTap">CHECK</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">只对目标线路出声 · 提醒只在本页打开时 · 没读清不猜</div>
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
  color: #ffffff;
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
.alertbox {
  margin-top: 5px;
  border: 1px solid rgba(64, 255, 94, 0.85);
  background-color: rgba(64, 255, 94, 0.10);
  padding: 4px 8px;
}
.stateline {
  color: #ffffff;
  font-size: 12px;
  font-weight: bold;
  line-height: 16px;
  white-space: nowrap;
  overflow: hidden;
}
.box {
  margin-top: 5px;
  border: 1px solid rgba(64, 255, 94, 0.45);
  padding: 4px 8px;
}
.watchline {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
  white-space: nowrap;
  overflow: hidden;
}
.nums {
  color: #ffffff;
  font-size: 15px;
  font-weight: bold;
  line-height: 19px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.rate {
  color: rgba(255, 255, 255, 0.85);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
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
  margin-right: 6px;
  background-color: #0d2812;
  color: #40ff5e;
  border: 1px solid rgba(64, 255, 94, 0.72);
  font-size: 13px;
  padding: 5px 0;
  text-align: center;
}
.btnrow .btn:last-child {
  margin-right: 0;
}
.btn-main {
  background-color: #14541f;
  color: #ffffff;
  font-weight: bold;
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
  white-space: nowrap;
  overflow: hidden;
}
</style>
