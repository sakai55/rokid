<script def>
{
  "title": "Signal Watch"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Signal Watch (W04, WATCH family): queue-number look-back watcher.
// The wearer reads the hall screen ONCE with their own eyes and enters
// two numbers: MY (your queue number) and NOW (the number currently
// called) - by stepper or by dictating the number THEY saw. After
// that the agent owns the staring: a look-back cadence prompts the
// wearer to glance at the screen and update NOW; every update
// recomputes the gap, a pace estimate from the wearer's OWN updates,
// and a rough ETA. At gap <= 3 it speaks once to get ready; at gap 0
// it calls out; if an update shows NOW > MY it says plainly the
// number has passed. The agent NEVER reads the screen itself and
// NEVER listens to the PA system - there is no broadcast recognition
// here; the microphone is only for the wearer dictating numbers they
// saw, after a wearer-mode availability check on getUserMedia (mic
// modes apply to getUserMedia streams only and never shape the host
// SpeechRecognition that follows). Reminders fire only while this
// page is open. Nothing is persisted: zero storage by construction.
// -------------------------------------------------------------------

const TICK_MS = 250;
const TICKS_PER_MIN = 240; // 60s * 4 ticks/s
const MAX_NUM = 99999;
const READY_GAP = 3;
const SAMPLE_GAP_TICKS = 40; // 10s: separates one look-back from the next
const CADENCES_MIN = [1, 2, 5];
const VENUES = ['医院', '银行', '取餐', '其他'];
const DEMO_INCS = [3, 3, 3, 2, 1]; // 117 -> 120 -> 123 -> 126 -> 128 -> 129

export default {
  data: {
    status: 'SETUP: 用你眼睛读大屏 - 填你的号 + 当前号',
    micLine: 'MIC CHECK: not run - DICT 前先查佩戴者麦',
    stateLine: '填好两个号，GO 开始守望 - 号码只来自你的眼睛',
    watchLine: 'SETUP: 场馆/号码都在下面这块里改',
    numsLine: 'MY --- → NOW ---',
    rateLine: 'RATE: --- （开始后按你的回看更新估算）',
    focusName: '▸ 你的号 MY',
    focusCue: '↑ +1 · ↓ −1 · +10 赶步 · DICT 口述你看到的号',
    guideLine: 'FIELD 切换：你的号 → 当前号 → 场馆',
    lastEvent: 'EVT: ready'
  },

  // ---- lifecycle ---------------------------------------------------

  onLoad() {
    this._phase = 'setup'; // setup | watch | done
    this._my = null;
    this._now = null;
    this._venueIdx = 0;
    this._cadIdx = 1; // default cadence: every 2 minutes
    this._field = 'my'; // my | now | venue
    this._tickCount = 0;
    this._sinceLook = 0;
    this._lookPending = false;
    this._samples = []; // {tick, now} look-back stamps for the pace math
    this._latest = null; // newest {tick, now} (bursts count once)
    this._gap = null;
    this._saidReady = false;
    this._saidCalled = false;
    this._saidPassed = false;
    this._steady = false;
    this._nodAt = -100000;
    this._rec = null;
    this._listening = false;
    this._busy = false;
    this._demo = null; // snapshot while demo runs
    this._demoStep = 0;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._startTimer();
    this._recompute('ready');
  },

  onShow() {
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopRec();
  },

  onUnload() {
    this._stopTimer();
    this._stopRec();
  },

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

  // ---- dictation number parsing (queue numbers) ---------------------
  // Arabic digits first; otherwise a Chinese-numeral integer in the
  // style of receipt-keeper's parser: digit map + 十百千万 units, a
  // digit right after a unit takes the next place down （二百五 = 250),
  // 零 holds a place （三百零五 = 305). Anything unparsable returns null
  // and is rejected honestly - a dictated number is never guessed.

  _cnDigits() {
    return { '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9 };
  },

  // Parse a Chinese integer using 十/百/千/万 units; null when the
  // string is not a clean Chinese numeral. Strings containing 万 are
  // handled by _cnIntWan; the rest parse in one pass below.
  _cnInt(str) {
    if (str.indexOf('万') >= 0) return this._cnIntWan(str);
    const dig = this._cnDigits();
    const units = { '十': 10, '百': 100, '千': 1000 };
    let section = 0;
    let pending = -1; // last digit seen, waiting for its unit or the end
    let lastUnit = 1;
    for (let i = 0; i < str.length; i++) {
      const ch = str.charAt(i);
      if (dig[ch] !== undefined) {
        if (pending >= 0) {
          // two digits in a row: previous one takes the next place down
          section += pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
          if (lastUnit > 1) lastUnit = lastUnit / 10;
          pending = -1;
        }
        pending = dig[ch];
        continue;
      }
      if (units[ch] !== undefined) {
        if (pending < 0) pending = 1; // 十 at start = 10
        section += pending * units[ch];
        lastUnit = units[ch];
        pending = -1;
        continue;
      }
      return null; // unknown character: not a numeral
    }
    if (pending >= 0) {
      section += str.length === 1 ? pending : pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
    }
    return section;
  },

  // 万-aware variant: split at 万， parse both sides with the base rules.
  _cnIntWan(str) {
    const idx = str.indexOf('万');
    const left = str.slice(0, idx);
    const right = str.slice(idx + 1);
    const dig = this._cnDigits();
    const units = { '十': 10, '百': 100, '千': 1000 };
    const parseSide = (s, allowEmpty) => {
      if (s === '') return allowEmpty ? 0 : null;
      let section = 0;
      let pending = -1;
      let lastUnit = 1;
      for (let i = 0; i < s.length; i++) {
        const ch = s.charAt(i);
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
      if (pending >= 0) {
        section += s.length === 1 ? pending : pending * (lastUnit / 10 >= 1 ? lastUnit / 10 : 1);
      }
      return section;
    };
    const l = parseSide(left, false);
    if (l === null) return null;
    const r = parseSide(right, true);
    if (r === null) return null;
    return (l <= 0 ? 1 : l) * 10000 + r;
  },

  _parseQueueNumber(raw) {
    if (!raw) return null;
    let s = String(raw).replace(/\s+/g, '');
    // strip spoken framing, keep the number itself
    s = s.replace(/^(现在|当前|叫到|已经到|到了|是|号是)+/g, '');
    s = s.replace(/(号|啦|了)$/g, '');
    if (!s) return null;
    const m = s.match(/(\d{1,6})/);
    if (m) {
      const v = parseInt(m[1], 10);
      return (v >= 0 && v <= MAX_NUM) ? v : null;
    }
    const v = this._cnInt(s);
    if (v === null || v === undefined || isNaN(v)) return null;
    return (v >= 0 && v <= MAX_NUM) ? v : null;
  },

  // ---- timer engine ---------------------------------------------------
  // All timing accumulates 250ms tick COUNTS; the wall clock is never
  // re-sampled, so pace/ETA math and the cadence stay consistent.

  _startTimer() {
    if (this._timer) return;
    this._timer = setInterval(() => { this._tick(); }, TICK_MS);
  },

  _stopTimer() {
    if (this._timer) {
      clearInterval(this._timer);
      this._timer = null;
    }
  },

  _tick() {
    this._tickCount++;
    if (this._phase === 'watch' && !this._lookPending) {
      const sub = this._subState();
      if (sub === 'far' || sub === 'ready') {
        this._sinceLook++;
        if (this._sinceLook >= CADENCES_MIN[this._cadIdx] * TICKS_PER_MIN) {
          this._fireLookback();
        }
      }
    }
    if (this._tickCount % 4 === 0) this._recompute();
  },

  _subState() {
    if (this._phase !== 'watch') return this._phase;
    if (this._gap === null) return 'far';
    if (this._gap < 0) return 'passed';
    if (this._gap === 0) return 'called';
    if (this._gap <= READY_GAP) return 'ready';
    return 'far';
  },

  _fireLookback() {
    this._lookPending = true;
    this._sinceLook = 0;
    const ok = this._speakText('回看一下大屏，更新当前号');
    this.setData({
      status: '👀 回看时间到 — 看一眼大屏，更新当前号',
      lastEvent: 'EVT: look-back fired ' + (ok ? '(spoken)' : '(SPEAK FAIL - visual only)')
    });
    this._recompute();
  },

  // ---- numbers: entry, updates, gap evaluation ------------------------

  _onNowChanged() {
    // Any NOW update is a look-back completed: clear the reminder,
    // restart the cadence, stamp the update for the pace math.
    this._lookPending = false;
    this._sinceLook = 0;
    this._recordSample();
    this._evalGap();
  },

  _recordSample() {
    const cur = { tick: this._tickCount, now: this._now };
    const last = this._samples.length ? this._samples[this._samples.length - 1] : null;
    if (!last || this._tickCount - last.tick >= SAMPLE_GAP_TICKS) {
      this._samples.push(cur);
    }
    this._latest = cur;
  },

  // Pace from the wearer's own updates only: numbers advanced between
  // the first stamped update and the latest one, over tick time.
  _rateInfo() {
    if (this._samples.length < 1 || !this._latest) return null;
    const first = this._samples[0];
    const advanced = this._latest.now - first.now;
    const mins = (this._latest.tick - first.tick) / TICKS_PER_MIN;
    if (advanced <= 0 || mins <= 0) return null;
    return { perMin: advanced / mins, updates: this._samples.length - 1 };
  },

  _evalGap() {
    if (this._phase !== 'watch' || this._my === null || this._now === null) return;
    const prev = this._gap;
    const gap = this._my - this._now;
    this._gap = gap;
    if (gap > READY_GAP) this._saidReady = false;
    if (gap !== 0) this._saidCalled = false;
    if (gap >= 0) this._saidPassed = false;
    if (gap >= 1 && gap <= READY_GAP && !this._saidReady) {
      this._saidReady = true;
      this._speakText('只差' + gap + '个号了，准备过去');
    } else if (gap === 0 && !this._saidCalled) {
      this._saidCalled = true;
      this._speakText('到你的号了');
    } else if (gap < 0 && prev !== null && prev >= 0 && !this._saidPassed) {
      this._saidPassed = true;
      this._speakText('已经过号了，去服务台问问');
    }
  },

  // ---- speech ---------------------------------------------------------

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

  _statusSpeech() {
    if (this._phase === 'setup') {
      const myT = this._my === null ? '还没填' : String(this._my);
      const nowT = this._now === null ? '还没填' : String(this._now);
      return '你的号' + myT + '，当前号' + nowT + '。两个号都填好，点 GO 开始守望。';
    }
    if (this._phase === 'done') {
      return '本轮守望已结束。';
    }
    const sub = this._subState();
    if (sub === 'passed') return '已经过号了：现在叫到' + this._now + '，你的号是' + this._my + '。去服务台问问。';
    if (sub === 'called') return '到你的号了，你的号是' + this._my + '。';
    let s = '现在叫到' + this._now + '号，你是' + this._my + '号，还差' + this._gap + '个。';
    const r = this._rateInfo();
    if (r) {
      const eta = Math.max(1, Math.round(this._gap / r.perMin));
      s += '按你更新的速度，大约还要' + eta + '分钟。';
    } else {
      s += '速度还不知道，再更新一次当前号就能估时间。';
    }
    if (sub === 'ready') s += '只差' + this._gap + '个，准备过去。';
    return s;
  },

  speakTap() {
    const ok = this._speakText(this._statusSpeech());
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read gap/ETA aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  // ---- head gesture: nod speaks, nothing else --------------------------
  // 'nod' is the only documented head gesture on this platform, and
  // head orientation is NOT eye gaze. Here a steady nod only reads the
  // status aloud - it never starts, updates, snoozes or finishes.

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    this._steady = detail.isStable === true || detail.stable === true;
  },

  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || '';
    if (g !== 'nod') return;
    if (!this._steady) return; // shaky nod while moving: ignored
    if (this._tickCount - this._nodAt < 8) return; // 2s debounce
    this._nodAt = this._tickCount;
    this.speakTap();
    this.setData({ lastEvent: 'EVT: nod (steady) -> SPEAK only' });
    this._recompute();
  },

  onVoiceWakeup() {
    this.setData({ lastEvent: 'EVT: voice wake (info only - voice never edits numbers)' });
    this._recompute();
  },

  // ---- temple keys ------------------------------------------------------
  // Single tap = Enter = contextual primary (GO). Swipes arrive as
  // ArrowUp / ArrowDown and adjust the active value by +-1 (the same
  // as the +1 / -1 buttons). Double-tap = Backspace = host back,
  // never intercepted.

  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') {
      event.preventDefault();
      this.goTap();
      return;
    }
    if (key === 'ArrowUp') {
      event.preventDefault();
      this._step(1, 'key');
      return;
    }
    if (key === 'ArrowDown') {
      event.preventDefault();
      this._step(-1, 'key');
      return;
    }
  },

  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') {
      event.preventDefault();
    }
  },

  // ---- buttons ----------------------------------------------------------

  plus1Tap() { this._step(1, 'btn'); },
  plus10Tap() { this._step(10, 'btn'); },
  minus1Tap() { this._step(-1, 'btn'); },

  _step(delta, source) {
    if (this._busy) return;
    if (this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: watch is done - GO starts a fresh setup' });
      this._recompute();
      return;
    }
    if (this._field === 'venue') {
      if (this._phase !== 'setup') { this._field = 'now'; }
      else {
        const n = VENUES.length;
        this._venueIdx = ((this._venueIdx + (delta > 0 ? 1 : -1)) % n + n) % n;
        this.setData({ lastEvent: 'EVT: venue -> ' + VENUES[this._venueIdx] + ' (label only)' });
        this._recompute();
        return;
      }
    }
    const field = this._field;
    const cur = field === 'my' ? this._my : this._now;
    let v = (cur === null ? 0 : cur) + delta;
    if (v < 0) v = 0;
    if (v > MAX_NUM) v = MAX_NUM;
    if (field === 'my') this._my = v; else this._now = v;
    this.setData({
      lastEvent: 'EVT: ' + (field === 'my' ? 'MY' : 'NOW') + ' -> ' + v + (source === 'key' ? ' (swipe)' : ' (stepper)')
    });
    if (this._phase === 'watch') {
      if (field === 'now') this._onNowChanged();
      else this._evalGap();
    }
    this._recompute();
  },

  fieldTap() {
    if (this._phase === 'setup') {
      this._field = this._field === 'my' ? 'now' : (this._field === 'now' ? 'venue' : 'my');
    } else if (this._phase === 'watch') {
      this._field = this._field === 'now' ? 'my' : 'now';
    }
    const names = { my: '你的号 MY', now: '当前号 NOW', venue: '场馆 VENUE' };
    this.setData({ lastEvent: 'EVT: edit field -> ' + names[this._field] });
    this._recompute();
  },

  cadTap() {
    this._cadIdx = (this._cadIdx + 1) % CADENCES_MIN.length;
    this._sinceLook = 0;
    this.setData({ lastEvent: 'EVT: look-back cadence -> every ' + CADENCES_MIN[this._cadIdx] + ' min' });
    this._recompute();
  },

  // GO: the contextual primary, mirrored by the Enter key and nothing
  // else. Setup: advance the field, then start (with validation).
  // Watch: CALLED/PASSED -> DONE; look-back pending -> snooze one
  // cadence (LATER); otherwise read the status aloud.
  goTap() {
    if (this._busy) return;
    if (this._phase === 'setup') {
      if (this._field === 'my') {
        this._field = 'now';
        this.setData({ lastEvent: 'EVT: field MY ok -> now fill NOW' });
        this._recompute();
        return;
      }
      this._startWatch();
      return;
    }
    if (this._phase === 'watch') {
      const sub = this._subState();
      if (sub === 'called' || sub === 'passed') {
        this._phase = 'done';
        this._lookPending = false;
        this.setData({
          status: sub === 'called' ? 'DONE ✓ 已到号，本轮守望结束' : 'DONE ✓ 已确认过号，去服务台处理',
          lastEvent: 'EVT: DONE tapped - watch closed'
        });
        this._recompute();
        return;
      }
      if (this._lookPending) {
        this._lookPending = false;
        this._sinceLook = 0;
        this.setData({
          status: '已稍后 — 一个节律后再提醒你回看',
          lastEvent: 'EVT: LATER - look-back snoozed one cadence'
        });
        this._recompute();
        return;
      }
      this.speakTap();
      return;
    }
    // done -> fresh setup
    this._phase = 'setup';
    this._my = null;
    this._now = null;
    this._field = 'my';
    this._samples = [];
    this._latest = null;
    this._gap = null;
    this._saidReady = false;
    this._saidCalled = false;
    this._saidPassed = false;
    this._lookPending = false;
    this.setData({ status: 'SETUP: 新的一轮 - 填你的号 + 当前号', lastEvent: 'EVT: fresh setup' });
    this._recompute();
  },

  _startWatch() {
    if (this._my === null || this._now === null) {
      this.setData({
        status: '先把两个号都填上：你的号 + 当前号',
        lastEvent: 'EVT: start refused - a number is missing'
      });
      this._recompute();
      return;
    }
    if (this._my <= this._now) {
      const ok = this._speakText('你的号已经过了？先核对一下两个号');
      this.setData({
        status: '你的号已经过了？MY 必须大于当前号 — 先核对',
        lastEvent: 'EVT: start refused - MY <= NOW ' + (ok ? '(asked aloud)' : '')
      });
      this._recompute();
      return;
    }
    this._phase = 'watch';
    this._field = 'now';
    this._gap = this._my - this._now;
    this._samples = [];
    this._latest = null;
    this._recordSample(); // the setup NOW is the first stamped update
    this._sinceLook = 0;
    this._lookPending = false;
    this._saidReady = false;
    this._saidCalled = false;
    this._saidPassed = false;
    this._evalGap(); // a first gap of 1..3 speaks READY right away
    this.setData({
      status: 'WATCHING: ' + VENUES[this._venueIdx] + ' — 放心歇眼，我按节律叫你回看',
      lastEvent: 'EVT: watch started MY ' + this._my + ' / NOW ' + this._now
    });
    this._recompute();
  },

  // ---- DICT: dictate the number you SAW --------------------------------
  // Order is binding: FIRST a wearer-mode availability check on
  // getUserMedia (result on its own MIC CHECK line, stream stopped at
  // once), THEN the host SpeechRecognition for what the WEARER says.
  // Mic modes never shape host ASR. The recognized number fills the
  // active field for the wearer's own eyeball check - it is applied
  // exactly like a stepper entry, never treated as screen truth.

  dictTap() {
    if (this._busy) return null;
    if (this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: watch is done - GO starts a fresh setup' });
      this._recompute();
      return null;
    }
    if (this._field === 'venue') {
      this.setData({ lastEvent: 'EVT: venue has no number - FIELD to a number field first' });
      this._recompute();
      return null;
    }
    this._busy = true;
    return this._dictListen().then(() => { this._busy = false; });
  },

  async _checkWearerMic() {
    // Wearer-mode availability check ONLY: request the stream, read
    // the mode back from the track settings, stop immediately.
    const nav = (typeof navigator !== 'undefined') ? navigator : null;
    if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) {
      this.setData({ micLine: 'MIC CHECK: n/a on this host - dictation uses host ASR only' });
      return;
    }
    let stream = null;
    try {
      try {
        stream = await this._withTimeout(
          nav.mediaDevices.getUserMedia({
            audio: { captureSource: 'microphone', microphoneMode: 'wearer', echoCancellation: true }
          }), 5000, 'mic check');
      } catch (e1) {
        if (e1 && e1.name === 'OverconstrainedError') {
          stream = await this._withTimeout(nav.mediaDevices.getUserMedia({ audio: true }), 5000, 'mic check fallback');
        } else {
          throw e1;
        }
      }
      const tracks = stream && stream.getAudioTracks ? stream.getAudioTracks() : [];
      const t = tracks[0];
      const st = (t && t.getSettings) ? t.getSettings() : {};
      const mode = st.microphoneMode || 'default (mode not reported)';
      this.setData({ micLine: 'MIC CHECK: wearer-mode stream OK · mode read back: ' + mode });
    } catch (e) {
      this.setData({ micLine: 'MIC CHECK: ' + this._err('mic check FAIL', e) + ' - dictation still tries host ASR' });
    } finally {
      if (stream && stream.getAudioTracks) {
        stream.getAudioTracks().forEach((t) => { try { t.stop(); } catch (e) { /* already stopped */ } });
      }
    }
  },

  _stopRec() {
    if (this._rec) {
      try { this._rec.stop(); } catch (e) { /* not running */ }
      this._rec = null;
    }
    this._listening = false;
  },

  async _dictListen() {
    await this._checkWearerMic();
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({
        lastEvent: 'EVT: DICT SKIP - host SpeechRecognition n/a; use the stepper'
      });
      this._recompute();
      return;
    }
    this._stopRec();
    const field = this._field;
    const rec = new SpeechRecognition();
    this._rec = rec;
    rec.lang = 'zh-CN'; // ASR language is real; only TTS lang is inert
    rec.interimResults = false;
    rec.maxAlternatives = 1;
    rec.onresult = (ev) => {
      let heard = '';
      try {
        const res = ev.results[ev.resultIndex || 0];
        heard = (res && res[0] && res[0].transcript) || '';
      } catch (e) { heard = ''; }
      const v = this._parseQueueNumber(heard);
      if (v === null) {
        this.setData({
          status: '没听清成号码：「' + (heard || '(empty)') + '」— 没猜，号码没变',
          lastEvent: 'EVT: DICT parse FAIL - "' + heard + '" rejected, value unchanged'
        });
      } else {
        if (field === 'my') this._my = v; else this._now = v;
        this.setData({
          status: 'DICT 已填 ' + (field === 'my' ? '你的号' : '当前号') + ' = ' + v + ' — 请核对一眼',
          lastEvent: 'EVT: DICT "' + heard + '" -> ' + (field === 'my' ? 'MY' : 'NOW') + ' ' + v
        });
        if (this._phase === 'watch') {
          if (field === 'now') this._onNowChanged();
          else this._evalGap();
        }
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
      this.setData({
        status: 'DICT 聆听中（host ASR）— 说出你看到的' + (field === 'my' ? '你的号' : '当前号'),
        lastEvent: 'EVT: DICT listening (host ASR) for ' + (field === 'my' ? 'MY' : 'NOW')
      });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: ' + this._err('DICT start FAIL', e) });
    }
    this._recompute();
  },

  // ---- DEMO ---------------------------------------------------------------
  // Seeds an in-memory queue (MY 128 / NOW 117 at a hospital) and
  // replays the whole arc: look-back reminder -> updates -> READY ->
  // CALLED -> PASSED. Each DEMO tap after the first plays one look-back
  // update: the tick clock fast-forwards one cadence so the pace math
  // reads like real waiting. Exiting restores the real state exactly.

  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, my: this._my, now: this._now,
        venueIdx: this._venueIdx, field: this._field, cadIdx: this._cadIdx,
        samples: this._samples, latest: this._latest, gap: this._gap,
        saidReady: this._saidReady, saidCalled: this._saidCalled, saidPassed: this._saidPassed,
        lookPending: this._lookPending, sinceLook: this._sinceLook
      };
      this._demoStep = 0;
      this._phase = 'watch';
      this._my = 128;
      this._now = 117;
      this._venueIdx = 0; // 医院
      this._field = 'now';
      this._gap = 11;
      this._samples = [];
      this._latest = null;
      this._recordSample();
      this._saidReady = false;
      this._saidCalled = false;
      this._saidPassed = false;
      this._sinceLook = 0;
      this._lookPending = true; // the demo opens on the look-back reminder
      this.setData({
        status: 'DEMO: 回看提醒来了 — 再点 DEMO = 你回看后更新当前号',
        lastEvent: 'EVT: DEMO on - MY 128 / NOW 117 seeded in memory, look-back pending'
      });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep > DEMO_INCS.length) {
      const d = this._demo;
      this._phase = d.phase; this._my = d.my; this._now = d.now;
      this._venueIdx = d.venueIdx; this._field = d.field; this._cadIdx = d.cadIdx;
      this._samples = d.samples; this._latest = d.latest; this._gap = d.gap;
      this._saidReady = d.saidReady; this._saidCalled = d.saidCalled; this._saidPassed = d.saidPassed;
      this._lookPending = d.lookPending; this._sinceLook = d.sinceLook;
      this._demo = null;
      this._demoStep = 0;
      this.setData({
        status: 'DEMO off — 真实号码已恢复',
        lastEvent: 'EVT: DEMO off - real state restored'
      });
      this._recompute();
      return;
    }
    // one simulated look-back: a cadence passes, the wearer updates NOW
    this._tickCount += CADENCES_MIN[this._cadIdx] * TICKS_PER_MIN;
    this._now += DEMO_INCS[this._demoStep - 1];
    this._onNowChanged();
    const sub = this._subState();
    this.setData({
      status: sub === 'passed' ? 'DEMO: 号已过 — 再点 DEMO 退出' :
        (sub === 'called' ? 'DEMO: 到号了 — 再点 DEMO 继续（故意过号）' :
          (sub === 'ready' ? 'DEMO: 只差几个了 — 再点 DEMO 继续更新' :
            'DEMO: 已更新 — 再点 DEMO 继续')),
      lastEvent: 'EVT: DEMO update ' + this._demoStep + '/' + DEMO_INCS.length + ' - NOW -> ' + this._now + ' (simulated look-back)'
    });
    this._recompute();
  },

  // ---- render -------------------------------------------------------------

  _fmtNum(v) {
    return v === null ? '---' : String(v);
  },

  _recompute(evtTag) {
    const demo = !!this._demo;
    const venue = VENUES[this._venueIdx];
    const cad = CADENCES_MIN[this._cadIdx];
    const sub = this._subState();
    let stateLine;
    let watchLine;
    let numsLine;
    let rateLine;
    if (this._phase === 'setup') {
      stateLine = '填好两个号，GO 开始守望 - 号码只来自你的眼睛';
      watchLine = (demo ? 'DEMO · ' : '') + 'SETUP: ' + venue + ' · 场馆只是标签，不参与计算';
      numsLine = 'MY ' + this._fmtNum(this._my) + ' → NOW ' + this._fmtNum(this._now);
      rateLine = 'RATE: --- （开始后按你的回看更新估算）';
    } else if (this._phase === 'done') {
      stateLine = 'DONE ✓ 本轮守望结束 — GO 开始新的一轮';
      watchLine = (demo ? 'DEMO · ' : '') + venue + ' · MY ' + this._fmtNum(this._my) + ' / NOW ' + this._fmtNum(this._now);
      numsLine = 'MY ' + this._fmtNum(this._my) + ' → NOW ' + this._fmtNum(this._now);
      rateLine = 'RATE: 本轮已结束';
    } else {
      watchLine = (demo ? 'DEMO · ' : '') + 'WATCH: ' + venue + ' · 每 ' + cad + ' 分钟提醒回看 · 更新 ' +
        Math.max(0, this._samples.length - 1) + ' 次';
      numsLine = 'NOW ' + this._fmtNum(this._now) + ' → MY ' + this._fmtNum(this._my) +
        (this._gap === null ? '' : (this._gap >= 0 ? ' · 还差 ' + this._gap + ' 个' : ' · 已过 ' + (-this._gap) + ' 个'));
      if (sub === 'passed') {
        stateLine = '✗ 已过号 — 去服务台问问（号是你更新的）';
        rateLine = 'RATE: 已过号，不再估时';
      } else if (sub === 'called') {
        stateLine = '🎉 到你的号了 — 过去吧，GO = 完成';
        rateLine = 'RATE: 已到号';
      } else if (this._lookPending) {
        stateLine = '👀 回看一下大屏 — 更新当前号，或 GO 稍后';
        rateLine = this._rateLineText();
      } else if (sub === 'ready') {
        stateLine = '⚠ 只差 ' + this._gap + ' 个 — 准备过去';
        rateLine = this._rateLineText();
      } else {
        stateLine = 'WATCHING — 闭眼歇会儿，我按节律叫你回看';
        rateLine = this._rateLineText();
      }
    }
    const fieldNames = { my: '▸ 你的号 MY', now: '▸ 当前号 NOW', venue: '▸ 场馆 VENUE' };
    const fieldVals = {
      my: 'MY = ' + this._fmtNum(this._my),
      now: 'NOW = ' + this._fmtNum(this._now),
      venue: '场馆 = ' + venue + '（标签）'
    };
    const cue = this._field === 'venue'
      ? '↑/↓ 或 +1/−1 切换场馆 · 只是标签'
      : '↑ +1 · ↓ −1 · +10 赶步 · DICT 口述你看到的号';
    this.setData({
      stateLine: stateLine,
      watchLine: watchLine,
      numsLine: numsLine,
      rateLine: rateLine,
      focusName: fieldNames[this._field] + (this._phase === 'watch' ? '（守望中）' : ''),
      focusCue: cue,
      guideLine: fieldVals[this._field] + ' · CAD 节律 ' + cad + ' 分钟' +
        (evtTag ? ' · ' + evtTag : '')
    });
  },

  _rateLineText() {
    const r = this._rateInfo();
    if (!r) return 'RATE: unknown yet — 再回看更新一次就能估时';
    const eta = this._gap > 0 ? Math.max(1, Math.round(this._gap / r.perMin)) : 0;
    return 'RATE: ~' + r.perMin.toFixed(1) + ' 个/分 · 据你的 ' + r.updates + ' 次更新 · ETA ~' + eta + ' 分钟';
  }
};
</script>

<template>
  <div class="page">
    <div class="title">SIGNAL WATCH</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ micLine }}</div>

    <div class="alertbox">
      <div class="stateline">{{ stateLine }}</div>
    </div>

    <div class="box">
      <div class="watchline">{{ watchLine }}</div>
      <div class="nums">{{ numsLine }}</div>
      <div class="rate">{{ rateLine }}</div>
    </div>

    <div class="box guide">
      <div class="focus">{{ focusName }}</div>
      <div class="cue">{{ focusCue }}</div>
      <div class="guide">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="plus1Tap">+1</button>
      <button class="btn" bindtap="plus10Tap">+10</button>
      <button class="btn" bindtap="minus1Tap">−1</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="fieldTap">FIELD</button>
      <button class="btn" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="cadTap">CAD</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">只在本页打开时提醒 · 号码来自你的眼睛 · 不读屏、不听广播</div>
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
.guide {
  border-color: rgba(64, 255, 94, 0.30);
}
.focus {
  color: #40ff5e;
  font-size: 12px;
  font-weight: bold;
  line-height: 15px;
  white-space: nowrap;
  overflow: hidden;
}
.cue {
  color: #ffffff;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.guide {
  color: rgba(64, 255, 94, 0.62);
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
