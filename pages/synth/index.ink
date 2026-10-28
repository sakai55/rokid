<script def>{"title":"Voice Subtitle Lab - Synth"}</script>

<script setup>
import wx from 'wx';

// AV06 synth (B6): speechSynthesis.synthesize with word subtitles.
// speak() queue has no pause/cancel, so playback control goes through
// synthesize + SpeechAudioPlayer. utterance.lang is never set (documented
// as not taking effect). utterance.voice is assigned the voice id string;
// if the host rejects it, the error is shown as-is.
const VOICES = ['female-tianmei', 'English_radiant_girl', 'English_expressive_narrator', 'male-qn-qingse', 'male-qn-jingying', 'female-yujie', 'Chinese (Mandarin)_News_Anchor', 'Chinese (Mandarin)_Radio_Host', 'clever_boy', 'lovely_girl', 'English_Trustworthy_Man'];
const RATES = [0.8, 1.0, 1.2];
const PITCHES = [0.9, 1.0, 1.1];
const FORMATS = ['mp3', 'ogg_opus', 'pcm'];
const SRS = [16000, 22050, 24000, 44100];

export default {
  data: { status: '选声合成：上下选音色，Enter 合成；合成后 Enter 播放/暂停', scriptText: '脚本：未选（先去脚本库选稿）', curWord: '—', cueRows: [], paramText: 'rate 1.0 · pitch 1.0 · mp3 · 22050Hz', timingText: '合成耗时：— · 时长：—', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._steady = false; this._voiceIdx = 0; this._rateIdx = 1; this._pitchIdx = 1; this._fmtIdx = 0; this._srIdx = 1;
    this._task = null; this._player = null; this._playing = false; this._cues = []; this._script = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    const s = this._loadTmp('av06_script_tmp');
    if (s && s.text) { this._script = s; this.setData({ scriptText: '脚本：' + s.title + ' — ' + s.text }); }
    this._recompute();
  },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },

  _combo() { return { scriptIdx: this._script ? this._script.idx : -1, scriptText: this._script ? this._script.text : '', voice: VOICES[this._voiceIdx], rate: RATES[this._rateIdx], pitch: PITCHES[this._pitchIdx], format: FORMATS[this._fmtIdx], sampleRate: SRS[this._srIdx] }; },
  _recompute() {
    const c = this._combo();
    this.setData({ paramText: '音色 ' + c.voice + ' · rate ' + c.rate + ' · pitch ' + c.pitch + ' · ' + c.format + ' · ' + c.sampleRate + 'Hz' });
  },

  voiceNext() { this._voiceIdx = (this._voiceIdx + 1) % VOICES.length; this.setData({ evt: 'EVT: voice ' + VOICES[this._voiceIdx] }); this._recompute(); },
  voicePrev() { this._voiceIdx = (this._voiceIdx + VOICES.length - 1) % VOICES.length; this.setData({ evt: 'EVT: voice ' + VOICES[this._voiceIdx] }); this._recompute(); },
  rateTap() { this._rateIdx = (this._rateIdx + 1) % RATES.length; this._recompute(); },
  pitchTap() { this._pitchIdx = (this._pitchIdx + 1) % PITCHES.length; this._recompute(); },
  fmtTap() { this._fmtIdx = (this._fmtIdx + 1) % FORMATS.length; this._recompute(); },
  srTap() { this._srIdx = (this._srIdx + 1) % SRS.length; this._recompute(); },

  async mainTap() {
    if (this._player && this._task) { this._togglePlay(); return; }
    await this._synthesize();
  },

  async _synthesize() {
    const combo = this._combo();
    if (!combo.scriptText) { this.setData({ status: '还没有脚本 — 先回脚本库选一条', evt: 'EVT: no script' }); return; }
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined' || typeof speechSynthesis.synthesize !== 'function') {
        this.setData({ status: '宿主无 speechSynthesis.synthesize — 如实显示，无法合成（speak 队列无字幕/暂停，不代用）', evt: 'EVT: no synthesize api' });
        return;
      }
      if (typeof SpeechAudioPlayer === 'undefined') { this.setData({ status: '宿主无 SpeechAudioPlayer — 如实显示，无法播放合成结果', evt: 'EVT: no player api' }); return; }
      const utt = new SpeechSynthesisUtterance(combo.scriptText);
      try { utt.voice = combo.voice; } catch (e) { this.setData({ status: '宿主拒绝 voice 赋值：' + String((e && e.message) || e).slice(0, 40), evt: 'EVT: voice rejected' }); return; }
      utt.rate = combo.rate; utt.pitch = combo.pitch;
      this._cues = [];
      this.setData({ status: '合成中…（synthesize · 字幕 word）', cueRows: [], curWord: '—', timingText: '合成耗时：计时中…' });
      const t0 = Date.now();
      const task = await speechSynthesis.synthesize(utt, { subtitles: 'word', audio: { preferredFormat: combo.format, sampleRate: combo.sampleRate } });
      this._task = task;
      const self = this;
      const onChunk = function (ev) {
        const cues = (ev && (ev.cues || (ev.detail && ev.detail.cues) || (ev.chunk && ev.chunk.cues))) || [];
        cues.forEach(function (cue) { self._cues.push({ text: (cue && (cue.text || cue.word)) || '', start: cue ? cue.start : null }); });
        self._renderCues(0);
      };
      try { task.onchunk = onChunk; } catch (e) {}
      try { if (typeof task.addEventListener === 'function') task.addEventListener('chunk', onChunk); } catch (e) {}
      this._player = new SpeechAudioPlayer(task);
      let durText = '—';
      try {
        const fin = (task.finished && typeof task.finished.then === 'function') ? await task.finished : null;
        if (fin && fin.duration != null) durText = String(fin.duration);
        else if (task.duration != null) durText = String(task.duration);
      } catch (e) {}
      const ms = Date.now() - t0;
      this._lastMs = ms; this._lastDur = durText;
      this._saveTmp('av06_combo_tmp', { combo: combo, ms: ms, duration: durText, cueCount: this._cues.length });
      this.setData({ status: '合成完成 — Enter 播放/暂停，ABORT 可中止', timingText: '合成耗时：' + ms + ' ms · 时长：' + durText + ' · 字幕词数：' + this._cues.length, evt: 'EVT: synthesized - ' + this._cues.length + ' cues' });
      this._renderCues(0);
    } catch (e) {
      this.setData({ status: '合成失败：' + String((e && e.message) || e).slice(0, 60), evt: 'EVT: synthesize failed' });
    }
  },

  _renderCues(active) {
    const rows = this._cues.map(function (c, i) { return { label: (i === active ? '▶ ' : '· ') + c.text }; });
    this.setData({ cueRows: rows, curWord: this._cues.length ? (this._cues[Math.min(active, this._cues.length - 1)].text || '—') : '—' });
  },
  _togglePlay() {
    try {
      if (!this._player) return;
      if (this._playing) { if (typeof this._player.pause === 'function') this._player.pause(); this._playing = false; this.setData({ status: '已暂停（SpeechAudioPlayer.pause）', evt: 'EVT: paused' }); }
      else { if (typeof this._player.play === 'function') this._player.play(); this._playing = true; this.setData({ status: '播放中 — 词级字幕随 cues 顺序点亮（大字区为当前词）', evt: 'EVT: playing' }); if (this._cues.length) this._renderCues(Math.min(1, this._cues.length - 1)); }
    } catch (e) { this.setData({ status: '播放切换失败：' + String((e && e.message) || e).slice(0, 40), evt: 'EVT: play toggle failed' }); }
  },
  abortTap() {
    try { if (this._task && typeof this._task.abort === 'function') this._task.abort(); this._playing = false; this.setData({ status: '已中止合成任务（task.abort）', evt: 'EVT: aborted' }); } catch (e) {}
  },
  saveATap() { this._saveSide('A'); },
  saveBTap() { this._saveSide('B'); },
  _saveSide(side) {
    const ab = this._loadTmp('av06_ab_tmp') || {};
    ab[side] = { combo: this._combo(), ms: this._lastMs || null, duration: this._lastDur || '—', cueCount: this._cues.length };
    this._saveTmp('av06_ab_tmp', ab);
    this.setData({ evt: 'EVT: saved as ' + side, status: '已存为 ' + side + ' 组 — 去 A/B 对照页选胜出' });
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.mainTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.mainTap(); return; }
    if (key === 'ArrowDown') {  this.voiceNext(); return; }
    if (key === 'ArrowUp') {  this.voicePrev(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">选声合成 · 字幕舞台</text><button class="backbtn abort" bindtap="abortTap">ABORT</button></view>
    <text class="status">{{status}}</text>
    <text class="line">{{scriptText}}</text>
    <view class="bigstage"><text class="bigword">{{curWord}}</text></view>
    <view class="cuelist">
      <view ink:for="{{cueRows}}" class="cuerow"><text class="cuetext">{{item.label}}</text></view>
    </view>
    <text class="line">{{paramText}}</text>
    <text class="line dim">{{timingText}} · {{steady}}</text>
    <view class="btnrow">
      <button class="stagebtn" bindtap="rateTap">语速</button>
      <button class="stagebtn" bindtap="pitchTap">音高</button>
      <button class="stagebtn" bindtap="fmtTap">格式</button>
      <button class="stagebtn" bindtap="srTap">采样率</button>
      <button class="stagebtn" bindtap="saveATap">存A</button>
      <button class="stagebtn" bindtap="saveBTap">存B</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { background-color: #000000; color: #40ff5e; border: 1px solid #40ff5e; border-radius: 10px; font-size: 10px; padding: 3px 8px; margin-right: 8px; }
.abort { margin-right: 0; margin-left: 8px; color: #7dff9e; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: bold; flex: 1; text-align: center; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.7); }
.bigstage { margin-top: 6px; border: 1px solid rgba(125,255,158,0.7); background-color: #04140a; padding: 10px; text-align: center; }
.bigword { color: #7dff9e; font-size: 30px; font-weight: bold; }
.cuelist { margin-top: 5px; height: 62px; overflow: hidden; padding: 2px 6px; }
.cuerow { display: inline-block; margin-right: 6px; }
.cuetext { color: #40ff5e; font-size: 12px; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.stagebtn { flex: 1; margin-right: 5px; background-color: #000000; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); border-radius: 10px; font-size: 11px; padding: 5px 0; text-align: center; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
