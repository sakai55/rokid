<script def>
{
  "title": "Greet Name Hold"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Greet Name Hold (Curb-Cut CC05, HOLD/DUAL family): a name holder
// for people with prosopagnosia (face blindness). The moment is
// familiar: someone greets you warmly, you know they are familiar,
// but the name will not come — and you have seconds to respond.
// The agent does NOT recognise faces: there is no face-recognition
// API on this platform, and pretending otherwise would be a lie.
// It holds the name once it has been SPOKEN. Two capture paths:
// (1) the wearer dictates the name they just heard (DICT, wearer
// mic check first, then host ASR, stored verbatim); (2) LISTEN
// captures the other person's speech with a far-field mic check
// first, shows the transcript, and 采用 stores it — into NAME only
// when it is name-length (<= 6 characters), otherwise it must go
// to NOTE or be dictated. During the conversation the name stays
// in the corner of the wearer's view with one pre-registered note
// ("上次聊过孩子升学" style) and an elapsed timer; CLEAR at the end
// wipes it. Nothing is held past the conversation, and nothing is
// persisted: no storage calls anywhere.
// -------------------------------------------------------------------

const TICK_MS = 250;

export default {
  data: {
    status: 'SETUP: 先把名字和一句备注存好',
    heardLine: '听到的原话：还没有 LISTEN',
    micLine: 'MIC CHECK: not run - DICT/LISTEN 前先查麦模式',
    bigLine: '名字还没存',
    noteLine: '备注：还没有备注',
    elapsedLine: '对话计时：--:--',
    stateLine: '名字存好，GO 开始拿住它 — 对话结束 CLEAR 清除',
    progressLine: '名字：未存 · 备注：未存',
    guideLine: 'FIELD 切换名字/备注 · DICT 口述填入 · LISTEN 听对方说话',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'setup'; // setup | holding | done
    this._name = '';
    this._note = '';
    this._field = 'name'; // name | note
    this._heard = '';
    this._elapsedTicks = 0;
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
    if (this._phase === 'holding') {
      this._elapsedTicks++;
      if (this._elapsedTicks % 4 === 0) this._recompute();
    }
  },
  _fmtElapsed() {
    const sec = Math.floor(this._elapsedTicks / 4);
    const mm = String(Math.floor(sec / 60));
    const ss = sec % 60;
    return (mm.length < 2 ? '0' + mm : mm) + ':' + (ss < 10 ? '0' + ss : String(ss));
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
    this.setData({ lastEvent: 'EVT: nod (steady) -> SPEAK only (never starts/clears)' });
    this._recompute();
  },

  // ---- temple keys ---------------------------------------------------
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp' || key === 'ArrowDown') { event.preventDefault(); this.fieldTap(); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- buttons -------------------------------------------------------
  fieldTap() {
    this._field = this._field === 'name' ? 'note' : 'name';
    const names = { name: '▸ 名字 NAME', note: '▸ 备注 NOTE' };
    this.setData({ lastEvent: 'EVT: edit field -> ' + names[this._field] });
    this._recompute();
  },

  goTap() {
    if (this._busy) return;
    if (this._phase === 'setup') {
      if (!this._name) {
        this.setData({ status: '先存名字：对方叫什么？DICT 口述或 LISTEN 后采用', lastEvent: 'EVT: hold refused - no name stored' });
        this._recompute();
        return;
      }
      this._phase = 'holding';
      this._elapsedTicks = 0;
      const ok = this._speakText('拿住了，' + this._name + '，对话结束点 CLEAR 清除');
      this.setData({
        status: 'HOLDING: 拿住 ' + this._name + ' — 对话结束 CLEAR 清除',
        lastEvent: 'EVT: holding started for ' + this._name + (ok ? ' (spoken)' : '')
      });
      this._recompute();
      return;
    }
    if (this._phase === 'holding') {
      this.speakTap();
      return;
    }
    if (this._phase === 'done') {
      this._phase = 'setup';
      this._name = '';
      this._note = '';
      this._field = 'name';
      this._heard = '';
      this._elapsedTicks = 0;
      this.setData({ status: 'SETUP: 新的一次 — 先把名字和一句备注存好', lastEvent: 'EVT: fresh setup' });
      this._recompute();
      return;
    }
  },

  clearTap() {
    if (this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: already cleared - GO starts fresh' });
      this._recompute();
      return;
    }
    const had = this._name;
    this._phase = 'done';
    this._name = '';
    this._note = '';
    this._elapsedTicks = 0;
    this.setData({ status: 'CLEARED ✓ 已清除 — 名字不再拿着，GO 开始新的一次', lastEvent: 'EVT: CLEARED (was holding: ' + (had || '(none)') + ')' });
    this._recompute();
  },

  speakTap() {
    let text;
    if (this._phase === 'setup') {
      text = this._name ? '已存名字' + this._name + '，' + (this._note ? '备注是' + this._note + '。' : '还没有备注。') + '点 GO 开始拿住。' : '名字还没存，口述名字或者听对方说话后采用。';
    } else if (this._phase === 'holding') {
      text = '拿住的名字是' + this._name + '。' + (this._note ? '备注：' + this._note + '。' : '');
    } else {
      text = '已清除，名字不再拿着，点 GO 开始新的一次。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read state aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  helpTap() {
    const text = '用法：对方自报姓名时点 LISTEN 听原话，名字短就点采用存入名字；或者直接 DICT 口述名字和备注。存好点 GO，名字会一直显示在视线里，对话结束点 CLEAR 清除。本机不认脸，名字只来自说出来的话。';
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: HELP ' + (ok ? 'usage spoken' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  // ---- mic checks: mode FIRST, then host ASR ---------------------------
  async _checkMic(mode, label) {
    const nav = (typeof navigator !== 'undefined') ? navigator : null;
    if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) {
      this.setData({ micLine: 'MIC CHECK (' + label + '): n/a on this host - uses host ASR only' });
      return;
    }
    let stream = null;
    try {
      try {
        stream = await this._withTimeout(
          nav.mediaDevices.getUserMedia({ audio: { captureSource: 'microphone', microphoneMode: mode, echoCancellation: true } }),
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
      this.setData({ micLine: 'MIC CHECK (' + label + '): stream OK · mode read back: ' + m });
    } catch (e) {
      this.setData({ micLine: 'MIC CHECK (' + label + '): ' + this._err('mic check FAIL', e) + ' - still tries host ASR' });
    } finally {
      if (stream && stream.getAudioTracks) stream.getAudioTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
    }
  },
  _stopRec() {
    if (this._rec) { try { this._rec.stop(); } catch (e) {} this._rec = null; }
    this._listening = false;
  },
  _cleanTranscript(raw) {
    if (!raw) return '';
    return String(raw).replace(/[\s，。、！？；：,.!?;:]+/g, '').slice(0, 60);
  },

  // ---- DICT: wearer dictates name/note --------------------------------
  dictTap() {
    if (this._busy) return null;
    if (this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: this round is over - GO starts fresh' });
      this._recompute();
      return null;
    }
    this._busy = true;
    return this._dictListen().then(() => { this._busy = false; });
  },
  async _dictListen() {
    await this._checkMic('wearer', 'wearer');
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({ lastEvent: 'EVT: DICT SKIP - host SpeechRecognition n/a; use LISTEN transcript + 采用' });
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
      const v = this._cleanTranscript(heard);
      if (!v) {
        this.setData({ status: '没听清：「' + (heard || '(empty)') + '」— 没存，内容没变', lastEvent: 'EVT: DICT empty - rejected, value unchanged' });
      } else if (field === 'name' && v.length > 6) {
        this.setData({ status: '这句太长不像名字（' + v.length + '字），请只说名字，或切到备注存整句', lastEvent: 'EVT: DICT name too long - rejected' });
      } else if (field === 'note' && v.length > 40) {
        this.setData({ status: '备注太长（' + v.length + '字），请说短一点', lastEvent: 'EVT: DICT note too long - rejected' });
      } else {
        if (field === 'name') this._name = v; else this._note = v;
        this.setData({ status: 'DICT 已存' + (field === 'name' ? '名字' : '备注') + '：' + v + ' — 请核对一眼', lastEvent: 'EVT: DICT "' + heard + '" -> ' + (field === 'name' ? 'NAME' : 'NOTE') + ' ' + v });
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
      this.setData({ status: 'DICT 聆听中（host ASR）— 说出' + (field === 'name' ? '对方的名字' : '一句备注'), lastEvent: 'EVT: DICT listening (host ASR) for ' + (field === 'name' ? 'NAME' : 'NOTE') });
    } catch (e) {
      this.setData({ lastEvent: this._err('DICT start FAIL', e) });
    }
    this._recompute();
  },

  // ---- LISTEN: far-field capture of the other person's speech ---------
  listenTap() {
    if (this._busy) return null;
    if (this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: this round is over - GO starts fresh' });
      this._recompute();
      return null;
    }
    this._busy = true;
    return this._listenFar().then(() => { this._busy = false; });
  },
  async _listenFar() {
    await this._checkMic('far-field', 'far-field');
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({ lastEvent: 'EVT: LISTEN SKIP - host SpeechRecognition n/a' });
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
      const v = this._cleanTranscript(heard);
      if (!v) {
        this.setData({ status: '没听清对方的话，再听一次或直接 DICT', lastEvent: 'EVT: LISTEN empty - nothing stored' });
      } else {
        this._heard = v;
        this.setData({ status: '听到了：「' + v + '」— 名字短就点采用，长的存备注', lastEvent: 'EVT: LISTEN heard "' + v + '" (not stored yet)' });
      }
      this._recompute();
    };
    rec.onerror = () => {
      this._listening = false;
      this.setData({ lastEvent: 'EVT: LISTEN host ASR error - nothing stored' });
      this._recompute();
    };
    rec.onend = () => { this._listening = false; };
    try {
      rec.start();
      this._listening = true;
      this.setData({ status: 'LISTEN 聆听中（host ASR，far-field 模式检查过）— 听对方说话', lastEvent: 'EVT: LISTEN listening (host ASR) far-field' });
    } catch (e) {
      this.setData({ lastEvent: this._err('LISTEN start FAIL', e) });
    }
    this._recompute();
  },

  // ---- 采用: wearer-confirmed adoption of the heard transcript --------
  adoptTap() {
    if (!this._heard) {
      this.setData({ lastEvent: 'EVT: 采用 - nothing heard yet, LISTEN first' });
      this._recompute();
      return;
    }
    if (this._field === 'name' && this._heard.length > 6) {
      this.setData({ status: '这句太长不像名字（' + this._heard.length + '字），切到备注再采用，或 DICT 只说名字', lastEvent: 'EVT: 采用 name too long - rejected' });
      this._recompute();
      return;
    }
    if (this._field === 'note' && this._heard.length > 40) {
      this.setData({ status: '备注太长（' + this._heard.length + '字），请 DICT 说短一点', lastEvent: 'EVT: 采用 note too long - rejected' });
      this._recompute();
      return;
    }
    if (this._field === 'name') this._name = this._heard; else this._note = this._heard;
    this.setData({ status: '已采用为' + (this._field === 'name' ? '名字' : '备注') + '：' + this._heard, lastEvent: 'EVT: 采用 -> ' + (this._field === 'name' ? 'NAME' : 'NOTE') + ' ' + this._heard });
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: name 李明 + note 上次聊过孩子升学; holding with
  // 02:34 elapsed; cleared. A further tap restores the real state.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, name: this._name, note: this._note, field: this._field,
        heard: this._heard, elapsed: this._elapsedTicks
      };
      this._demoStep = 0;
      this._phase = 'setup';
      this._name = '李明';
      this._note = '上次聊过孩子升学';
      this._field = 'name';
      this._heard = '我是李明';
      this._elapsedTicks = 0;
      this.setData({ status: 'DEMO: 名字 李明，备注已存 — 再点 DEMO = 开始拿住', lastEvent: 'EVT: DEMO on - name 李明 seeded in memory' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'holding';
      this._elapsedTicks = 616;
      this.setData({ status: 'DEMO: 拿住 李明 — 再点 DEMO = 对话结束清除', lastEvent: 'EVT: DEMO step 1 - holding 李明' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._phase = 'done';
      this._name = '';
      this._note = '';
      this._elapsedTicks = 0;
      this.setData({ status: 'DEMO: CLEARED ✓ 已清除 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 2 - CLEARED' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._name = d.name; this._note = d.note; this._field = d.field;
    this._heard = d.heard; this._elapsedTicks = d.elapsed;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, progressLine, guideLine, bigLine, noteLine, elapsedLine;
    if (this._phase === 'setup') {
      stateLine = '名字存好，GO 开始拿住它 — 对话结束 CLEAR 清除';
      progressLine = '名字：' + (this._name || '未存') + ' · 备注：' + (this._note || '未存');
      guideLine = 'FIELD 切换名字/备注 · DICT 口述填入 · LISTEN 听对方说话 · 采用确认存入';
      bigLine = this._name || '名字还没存';
      noteLine = '备注：' + (this._note || '还没有备注');
      elapsedLine = '对话计时：--:--';
    } else if (this._phase === 'holding') {
      stateLine = 'HOLDING — 拿住 ' + this._name + '，名字一直在视线里';
      progressLine = '名字：' + this._name + ' · 备注：' + (this._note || '无');
      guideLine = 'CLEAR = 对话结束清除 · SPEAK 听名字 · 点头 = 只朗读，绝不清除';
      bigLine = this._name;
      noteLine = '备注：' + (this._note || '无');
      elapsedLine = '对话计时：' + this._fmtElapsed() + ' — 结束点 CLEAR';
    } else {
      stateLine = 'CLEARED ✓ 已清除 — 名字不再拿着，GO 开始新的一次';
      progressLine = '名字：已清除 · 备注：已清除';
      guideLine = 'GO 开始新的一次';
      bigLine = '已清除 ✓';
      noteLine = '备注：已清除';
      elapsedLine = '对话计时：--:--';
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    const fieldNames = { name: '▸ 名字 NAME', note: '▸ 备注 NOTE' };
    this.setData({
      stateLine: stateLine,
      progressLine: progressLine,
      guideLine: guideLine + ' · 当前编辑：' + fieldNames[this._field],
      bigLine: bigLine,
      noteLine: noteLine,
      elapsedLine: elapsedLine,
      heardLine: '听到的原话：' + (this._heard || '还没有 LISTEN')
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">GREET NAME HOLD</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ heardLine }}</div>
    <div class="sub">{{ micLine }}</div>

    <div class="card">
      <div class="big">{{ bigLine }}</div>
      <div class="note">{{ noteLine }}</div>
      <div class="elapsed">{{ elapsedLine }}</div>
    </div>

    <div class="box">
      <div class="stateline">{{ stateLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="fieldTap">FIELD</button>
      <button class="btn" bindtap="dictTap">DICT</button>
      <button class="btn" bindtap="listenTap">LISTEN</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="adoptTap">采用</button>
      <button class="btn" bindtap="helpTap">HELP</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">不认脸 · 名字只来自说出来的话 · 对话结束清除</div>
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
.note {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.elapsed {
  color: rgba(64, 255, 94, 0.85);
  font-size: 11px;
  line-height: 15px;
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
