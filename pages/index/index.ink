<script def>
{
  "navigationBarTitleText": "Breath Pace"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '呼吸节拍 — 紧张/焦虑时呼吸乱成一团，自己数拍子反而更慌：视线内呼吸节拍光点（吸-停-呼），跟着看就行，拍子由它数，结束给时长小结',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 呼吸节拍 — START 跟着光点走，PAUSE 暂停，MODE 换拍档，MUTE 关语音，END 出小结',
    bigLabel: '呼吸节拍 · 待机',
    bigText: '还没开始',
    bigNote: '吸 4 秒 · 停 2 秒 · 呼 6 秒 · 跟着看就行，不用自己数',
    permLine: 'PERM: 无权限 — 节拍光点 + 计时 + TTS 相位报；不拍照、不录音、不定位',
    rows: [],
    countLine: '已跟 0 轮 · 本次 0 秒 · 拍档 4-2-6 · 语音开 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START follows the beat, MODE switches the beat, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | pacing | summary
    this._presets = [
      { name: '4-2-6', inhale: 4, hold: 2, exhale: 6 },
      { name: '4-4-6', inhale: 4, hold: 4, exhale: 6 }
    ];
    this._presetIdx = 0;
    this._phase = 'inhale'; // inhale | hold | exhale
    this._phaseElapsed = 0; // seconds into the current phase
    this._rounds = 0; // completed inhale-hold-exhale cycles
    this._totalSec = 0; // seconds paced this session
    this._paused = false;
    this._muted = false;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 inhale, 2 hold, 3 exhale, 4 inhale round 2, 5 summary
    this._nodLock = false;
    this._timer = null;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the phase, the rounds,
    // the total seconds and the summary die with the page.
    // Nothing was ever written anywhere persistent, so there
    // is nothing to clean up — that IS the design.
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
    this._mode = 'idle';
    this._phase = 'inhale';
    this._phaseElapsed = 0;
    this._rounds = 0;
    this._totalSec = 0;
    this._paused = false;
    this._muted = false;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Phase names are spoken only on a phase
    // change, and never when muted — MUTE means look only.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - nod confirms only on steady gaze'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (nod only)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod starts
    // pacing in idle and confirms the summary. A nod never
    // pauses, never switches phase, and never counts a
    // breath: the beat is counted by the timer, not by
    // nodding, and a nod is not a breath.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'pacing') {
      this.setData({ lastEvent: 'EVT: nod ignored while pacing - the beat is counted by the timer, a nod is not a breath' });
      return;
    }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'pacing') this.pauseTap();
      else if (this._mode === 'summary') this._confirmSummary();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.backTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- the beat (the only accumulation point) ----------

  _preset() {
    return this._presets[this._presetIdx];
  },

  _phaseDur(phase) {
    var p = this._preset();
    if (phase === 'inhale') return p.inhale;
    if (phase === 'hold') return p.hold;
    return p.exhale;
  },

  _phaseName(phase) {
    if (phase === 'inhale') return '吸';
    if (phase === 'hold') return '停';
    return '呼';
  },

  _nextPhase(phase) {
    if (phase === 'inhale') return 'hold';
    if (phase === 'hold') return 'exhale';
    return 'inhale';
  },

  _tick(secs) {
    if (this._mode !== 'pacing') {
      this.setData({ lastEvent: 'EVT: tick ignored - not pacing' });
      return;
    }
    if (this._paused) {
      this.setData({ lastEvent: 'EVT: tick ignored - paused' });
      return;
    }
    var s = secs || 1;
    this._totalSec += s;
    var remain = s;
    while (remain > 0) {
      var dur = this._phaseDur(this._phase);
      var left = dur - this._phaseElapsed;
      if (remain < left) {
        this._phaseElapsed += remain;
        remain = 0;
        break;
      }
      // Cross a phase boundary: the beat counts it, and the
      // new phase name is spoken once — unless muted.
      remain -= left;
      this._phaseElapsed = 0;
      var prev = this._phase;
      this._phase = this._nextPhase(this._phase);
      if (prev === 'exhale' && this._phase === 'inhale') this._rounds++;
      if (!this._muted) {
        this._speakText(this._phaseName(this._phase));
      }
      this.setData({
        lastEvent: 'EVT: phase ' + prev + ' -> ' + this._phase + (this._muted ? ' (muted, look only)' : ' (spoken once)')
      });
    }
    this.setData({
      status: '节拍中 — ' + this._phaseName(this._phase) + '相，剩 ' + (this._phaseDur(this._phase) - this._phaseElapsed) + ' 秒，已跟 ' + this._rounds + ' 轮'
    });
    this._renderAll();
  },

  _startTimer() {
    // Real-device path: one second per tick, only while
    // pacing and not paused. The timer is stopped on unload
    // and on END.
    if (this._timer) return;
    var self = this;
    try {
      this._timer = setInterval(function () { self._tick(1); }, 1000);
    } catch (e) {}
  },

  _stopTimer() {
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
  },

  // ---------- start / pause / mode / mute / end ----------

  startTap() {
    if (this._mode === 'pacing') {
      this.setData({ lastEvent: 'EVT: START refused - already pacing, PAUSE pauses' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    // BACK from pacing returns to idle with the round kept;
    // START resumes the same round instead of resetting it.
    this._mode = 'pacing';
    this._paused = false;
    this._startTimer();
    this.setData({
      status: (this._rounds > 0 || this._totalSec > 0)
        ? '节拍恢复 — ' + this._phaseName(this._phase) + '相，剩 ' + (this._phaseDur(this._phase) - this._phaseElapsed) + ' 秒，已跟 ' + this._rounds + ' 轮'
        : '节拍中 — 吸相，剩 ' + this._phaseDur('inhale') + ' 秒，跟着光点看就行，不用自己数',
      lastEvent: 'EVT: pacing started - beat ' + this._preset().name + ', phase ' + this._phase
    });
    this._renderAll();
  },

  pauseTap() {
    if (this._mode !== 'pacing') {
      this.setData({ lastEvent: 'EVT: PAUSE ignored - not pacing' });
      return;
    }
    this._paused = !this._paused;
    this.setData({
      status: this._paused ? '已暂停 — 光点停住，点 PAUSE 继续' : '节拍中 — ' + this._phaseName(this._phase) + '相，剩 ' + (this._phaseDur(this._phase) - this._phaseElapsed) + ' 秒',
      lastEvent: 'EVT: ' + (this._paused ? 'paused' : 'resumed')
    });
    this._renderAll();
  },

  modeTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: MODE refused - switch the beat before starting, not mid-beat' });
      return;
    }
    this._presetIdx = (this._presetIdx + 1) % this._presets.length;
    this.setData({
      status: '拍档已换 — ' + this._preset().name + '（吸 ' + this._preset().inhale + ' 秒 · 停 ' + this._preset().hold + ' 秒 · 呼 ' + this._preset().exhale + ' 秒），点 START 开始',
      lastEvent: 'EVT: beat switched to ' + this._preset().name
    });
    this._renderAll();
  },

  muteTap() {
    this._muted = !this._muted;
    this.setData({
      status: this._muted ? '语音已关 — 只看光点，相位切换不出声' : '语音已开 — 相位切换报一次相位名',
      lastEvent: 'EVT: ' + (this._muted ? 'muted - look only' : 'unmuted - phase names spoken once')
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to pacing without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 跟节拍' });
      return;
    }
    this._stopTimer();
    this._mode = 'summary';
    this._summary = {
      rounds: this._rounds,
      totalSec: this._totalSec,
      preset: this._preset().name
    };
    this.setData({
      status: '结束 — 跟了 ' + this._rounds + ' 轮，本次 ' + this._totalSec + ' 秒，点 END 确认清空，BACK 回节拍',
      lastEvent: 'EVT: closed - rounds ' + this._rounds + ', total ' + this._totalSec + ' sec, beat ' + this._preset().name
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._phase = 'inhale';
    this._phaseElapsed = 0;
    this._rounds = 0;
    this._totalSec = 0;
    this._paused = false;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '呼吸节拍 — START 再次跟节拍',
      lastEvent: 'EVT: summary confirmed - rounds and seconds cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to pacing without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'pacing';
      this._summary = null;
      this._startTimer();
      this.setData({
        status: '节拍中 — BACK 回到节拍，计数保留',
        lastEvent: 'EVT: back to pacing - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'pacing') {
      // Back from pacing returns to idle with the round kept
      // and the timer stopped; START resumes the same round.
      this._stopTimer();
      this._mode = 'idle';
      this.setData({
        status: '呼吸节拍 — 节拍已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - round kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START follows the beat' });
  },

  _focusLen() {
    return 3; // the three info rows exist in every mode
  },

  nextTap() {
    this._focus = (this._focus + 1) % 3;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    this._focus = (this._focus - 1 + 3) % 3;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= 3) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没开始：START 跟着光点走';
    } else if (this._mode === 'pacing') {
      line = this._phaseName(this._phase) + '相，剩 ' + (this._phaseDur(this._phase) - this._phaseElapsed) + ' 秒，已跟 ' + this._rounds + ' 轮';
    } else if (this._summary) {
      line = '本次小结：跟了 ' + this._summary.rounds + ' 轮，本次 ' + this._summary.totalSec + ' 秒';
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user pacing session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._rounds > 0 || this._totalSec > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user round is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this.startTap();
      // DEMO is a staged sample, not a live beat: stop the
      // one-second timer so the preview frames are
      // deterministic (otherwise live ticks would drift the
      // phase between the DEMO tap and the screenshot).
      this._stopTimer();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - pacing, inhale phase (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._tick(this._phaseDur('inhale'));
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - hold phase (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._tick(this._phaseDur('hold'));
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - exhale phase (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._tick(this._phaseDur('exhale'));
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - inhale again, round 1 complete, 12 sec paced (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: rounds 1, total 12 sec (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var p = this._preset();
    var rows = [];
    rows.push({
      idx: 0,
      name: '当前相位',
      detail: this._mode === 'pacing'
        ? this._phaseName(this._phase) + '相，剩 ' + (this._phaseDur(this._phase) - this._phaseElapsed) + ' 秒' + (this._paused ? '（已暂停）' : '')
        : (this._mode === 'summary' ? '已结束' : '待机（点 START 开始）'),
      flag: (this._focus === 0 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 1,
      name: '已跟轮数',
      detail: this._rounds + ' 轮（吸-停-呼一圈算一轮）',
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '本次时长',
      detail: this._totalSec + ' 秒 · 拍档 ' + p.name + ' · 语音' + (this._muted ? '关' : '开'),
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '已跟 ' + this._rounds + ' 轮 · 本次 ' + this._totalSec + ' 秒 · 拍档 ' + p.name + ' · 语音' + (this._muted ? '关' : '开') + ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 呼吸节拍 — START 跟着光点走，PAUSE 暂停，MODE 换拍档，MUTE 关语音，END 出小结';
      patch.bigLabel = '呼吸节拍 · 待机';
      patch.bigText = (this._rounds > 0 || this._totalSec > 0) ? '节拍已停未清' : '还没开始';
      patch.bigNote = '吸 ' + p.inhale + ' 秒 · 停 ' + p.hold + ' 秒 · 呼 ' + p.exhale + ' 秒 · 跟着看就行，不用自己数';
    } else if (this._mode === 'pacing') {
      patch.boxLabel = '◎ 节拍中 — 跟着光点看就行，拍子由它数；点头不是呼吸，不暂停也不计数';
      patch.bigLabel = '呼吸节拍 · ' + this._phaseName(this._phase) + '相' + (this._paused ? '（已暂停）' : '');
      patch.bigText = this._phaseName(this._phase) + ' · 剩 ' + (this._phaseDur(this._phase) - this._phaseElapsed) + ' 秒';
      patch.bigNote = '已跟 ' + this._rounds + ' 轮 · 本次 ' + this._totalSec + ' 秒 · 拍档 ' + p.name + (this._muted ? ' · 语音关，只看光点' : '');
    } else {
      patch.boxLabel = '◎ 本次小结 — 跟了几轮、本次多长钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { rounds: 0, totalSec: 0, preset: p.name };
      patch.bigText = '跟了 ' + sm.rounds + ' 轮';
      patch.bigNote = '本次 ' + sm.totalSec + ' 秒 · 拍档 ' + sm.preset + ' · 点 END 确认清空 · BACK 回节拍';
    }
    patch.bigCls = this._bigClsFor(patch.bigText);
    this.setData(patch);
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">BREATH PACE v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{permLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="demoTap">DEMO</button>
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn btn-main" bindtap="pauseTap">PAUSE</button>
      <button class="btn btn-main" bindtap="modeTap">MODE</button>
      <button class="btn btn-main" bindtap="muteTap">MUTE</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="endTap">END</button>
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">它测不出你的呼吸——没有呼吸传感器，它不知道你是不是真的跟着吸呼，只是一个节拍器 · 它不是医疗建议：不治疗焦虑、不承诺平复效果，严重不适请寻求专业帮助，头晕立即停下 · 拍长是固定档位（4-2-6 / 4-4-6），不是按你实时状态调整的 · 只存本次会话，关掉即清 · 没有室内定位，没有摄像头 · 零落盘</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 2px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 1px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.biglabel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.bignum {
  color: #40ff5e;
  font-size: 34px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-sm {
  color: #40ff5e;
  font-size: 24px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-xs {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 1px;
}
.bignote {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 2px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 1px;
  font-size: 11px;
  font-weight: 500;
  line-height: 16px;
  text-align: center;
}
.btn-main {
  color: #40ff5e;
  border-color: rgba(64,255,94,0.72);
  background-color: rgba(64,255,94,0.12);
}
.list {
  flex-shrink: 0;
  height: 80px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-right: 8px;
}
.rdetail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 15px;
  flex-grow: 1;
}
.rflag {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 12px;
}
</style>
