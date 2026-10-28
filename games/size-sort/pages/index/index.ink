<script def>
{
  "navigationBarTitleText": "Size Sort"
}
</script>

<script setup>
import wx from 'wx';

var ROUNDS = [
  {
    "label": "杯子",
    "options": [
      "1,2,3",
      "1,3,2",
      "2,1,3",
      "2,3,1",
      "3,1,2",
      "3,2,1"
    ],
    "speak": "摆三个杯子，从左到右编号一二三。先排从大到小的顺序",
    "snapHint": "把 3 个杯子从左到右摆开，拍照判定"
  },
  {
    "label": "书",
    "options": [
      "1,2,3",
      "1,3,2",
      "2,1,3",
      "2,3,1",
      "3,1,2",
      "3,2,1"
    ],
    "speak": "摆三本书，先排从大到小的顺序",
    "snapHint": "把 3 本书从左到右摆开，拍照判定"
  },
  {
    "label": "瓶子",
    "options": [
      "1,2,3",
      "1,3,2",
      "2,1,3",
      "2,3,1",
      "3,1,2",
      "3,2,1"
    ],
    "speak": "摆三个瓶子，先排从大到小的顺序",
    "snapHint": "把 3 个瓶子从左到右摆开，拍照判定"
  },
  {
    "label": "鞋",
    "options": [
      "1,2,3",
      "1,3,2",
      "2,1,3",
      "2,3,1",
      "3,1,2",
      "3,2,1"
    ],
    "speak": "摆三只鞋，先排从大到小的顺序",
    "snapHint": "把 3 只鞋从左到右摆开，拍照判定"
  }
];
var DEMO_SEQ = [
  {
    "ans": "2,1,3",
    "note": "中间杯最高大"
  },
  {
    "ans": "1,3,2",
    "note": "左书最大，右书最小"
  },
  {
    "ans": "3,2,1",
    "note": "从右往左依次变小"
  },
  {
    "ans": "1,2,3",
    "note": "从左往右依次变小"
  }
];

export default {
  data: {
    state: 'ready',
    stage: 'guess',
    status: '摆 3 个同类物，先排大小顺序，再拍照判定',
    heroLabel: '本局物品',
    heroText: '4 局 · 先排后判',
    verdictLine: '判定仅供娱乐 · 有争议以玩家目测为准',
    detailLine: '顺序指从左数的位置 · 按从大到小排 · 先定死再拍',
    progressText: '0 / 4',
    options: [],
    optCls: 'opts-on',
    lastEvent: 'EVT: 滑动=选猜测 · 单击/点头=确认 · 拍照后判定揭晓',
    appVersion: 'v1.0.1',
    runLabel: '开始',
    busy: false,
    demoTag: ''
  },

  onLoad() {
    this._idx = 0;
    this._sel = 0;
    this._guess = -1;
    this._guessText = '';
    this._results = ROUNDS.map(function () { return 'wait'; });
    this._score = 0;
    this._appeals = 0;
    this._demo = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._syncOptions();
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowDown') this._moveSel(1);
    else if (code === 'ArrowUp') this._moveSel(-1);
    else if (code === 'Enter' || code === 'GlobalHook') this._primary();
  },

  _onNod() {
    if (this.data.busy) return;
    if (this.data.state === 'playing' && this.data.stage === 'guess') this._primary();
    else if (this.data.state === 'playing' && this.data.stage === 'verdict') {
      this._appeals++;
      this.setData({ lastEvent: 'EVT: 已记录申诉（第 ' + this._appeals + ' 次）· 分数不变' });
      this._announce('已记录申诉，分数不变');
    }
  },

  _moveSel(dir) {
    if (this.data.state !== 'playing' || this.data.stage !== 'guess' || this.data.busy) return;
    var n = ROUNDS[this._idx].options.length;
    this._sel = (((this._sel + dir) % n) + n) % n;
    this._syncOptions();
  },

  _syncOptions() {
    var r = ROUNDS[this._idx];
    var self = this;
    this.setData({
      optCls: (this.data.state === 'playing' && this.data.stage === 'guess') ? 'opts-on' : 'opts-off',
      options: r.options.map(function (o, i) {
        return { label: o, cls: i === self._sel ? 'opt opt-on' : 'opt' };
      })
    });
  },

  onPrimary() { this._primary(); },
  onDemo() { this._startDemo(); },
  onOpt0() { this._pick(0); },
  onOpt1() { this._pick(1); },
  onOpt2() { this._pick(2); },
  onOpt3() { this._pick(3); },
  onOpt4() { this._pick(4); },
  onOpt5() { this._pick(5); },

  _pick(i) {
    if (this.data.state !== 'playing' || this.data.stage !== 'guess' || this.data.busy) return;
    if (i >= ROUNDS[this._idx].options.length) return;
    this._sel = i;
    this._syncOptions();
  },

  _primary() {
    if (this.data.busy) return;
    if (this.data.state === 'ready' || this.data.state === 'done') { this._start(false); return; }
    if (this.data.stage === 'guess') this._confirmGuess();
    else if (this.data.stage === 'snap') this._shoot();
    else if (this.data.stage === 'verdict') this._advance();
  },

  _startDemo() {
    if (this.data.busy || this.data.state === 'playing') return;
    this._start(true);
  },

  _start(demo) {
    this._demo = demo;
    this._idx = 0;
    this._sel = 0;
    this._results = ROUNDS.map(function () { return 'wait'; });
    this._score = 0;
    this._appeals = 0;
    this.setData({
      state: 'playing', stage: 'guess',
      demoTag: demo ? '演示局 · ' : '',
      runLabel: '确认猜测',
      verdictLine: '先选你的猜测，再确认',
      detailLine: demo ? '演示判定（预置结果）· 真机走真实拍照+大模型判定' : '猜测先定死，拍照判定后不许改口'
    });
    this._syncRound();
    this._announce((demo ? '演示局开始。' : '') + ROUNDS[0].speak);
  },

  _syncRound() {
    var r = ROUNDS[this._idx];
    this.setData({
      heroText: r.label,
      status: this.data.demoTag + '第 ' + (this._idx + 1) + ' / ' + ROUNDS.length + ' 局 · ' +
        (this.data.stage === 'guess' ? '先猜' : (this.data.stage === 'snap' ? '拍照' : '揭晓')),
      progressText: this._score + ' / ' + ROUNDS.length
    });
    this._syncOptions();
  },

  _confirmGuess() {
    var r = ROUNDS[this._idx];
    this._guess = this._sel;
    this._guessText = r.options[this._sel];
    this.setData({
      stage: 'snap', runLabel: '拍照判定',
      verdictLine: '你的猜测：' + this._guessText,
      detailLine: r.snapHint
    });
    this._syncRound();
    this._announce('猜测记下了，去拍照判定');
  },

  async _shoot() {
    var idx = this._idx;
    var round = ROUNDS[idx];
    this.setData({ busy: true, verdictLine: '判定中…', detailLine: '正在拍照并请大模型判定，请稍候' });
    if (this._demo) {
      await this._sleep(500);
      var d = DEMO_SEQ[idx];
      this._applyJudge(idx, d.ans, d.note);
      this.setData({ busy: false });
      return;
    }
    var snap = await this._snap('default');
    if (!snap.ok) {
      this.setData({
        busy: false,
        verdictLine: snap.absent ? '本机无相机接口' : '拍照失败 · 本局未消耗',
        detailLine: snap.absent ? '网页预览无相机：点 DEMO 看演示局，或在真机上玩' : snap.error + ' · 再单击重试'
      });
      return;
    }
    var ans = await this._judge(this._buildContent(round, snap.url),
      'You are a strict but fair judge for a photo game played on smart glasses. Reply ONLY in the requested format, in Chinese.');
    if (!ans) {
      this._results[idx] = 'fail';
      this._finishRound(idx, '判定失败 · 本局不计分', '大模型不可用或无回答 · 如实记为失败');
      this.setData({ busy: false });
      return;
    }
    var raw = this._fieldOf(ans, 'ORDER').replace(/\s/g, '');
    var parts = raw.split(',');
    var ord = [];
    var valid = parts.length === 3;
    for (var pi = 0; pi !== parts.length; pi++) {
      var v = parseInt(parts[pi], 10);
      if (!v || v < 1 || v > 3 || ord.indexOf(v) >= 0) valid = false;
      ord.push(v);
    }
    if (!valid) {
      this._results[idx] = 'fail';
      this._finishRound(idx, '判定失败 · 本局不计分', '大模型没给出有效顺序 · 如实记为失败');
      this.setData({ busy: false });
      return;
    }
    this._applyJudge(idx, ord.join(','), this._fieldOf(ans, 'REASON'));
    this.setData({ busy: false });
  },

  _buildContent(round, url) {
    return [
      { type: 'text', text: '照片中有3个' + round.label + '大致从左到右排开。按它们在画面里的视觉大小（占画面大小/高度）从大到小，排出位置序号（位置从左数1到3）。回复两行：第一行 ORDER: 三个序号用英文逗号分隔（如 2,1,3）；第二行 REASON: 一句不超过20字的理由。' },
      { type: 'image_url', image_url: { url: url } }
    ];
  },

  _finishRound(idx, line, detail) {
    this.setData({ stage: 'verdict', runLabel: '下一局', verdictLine: line, detailLine: detail.slice(0, 78),
      lastEvent: 'EVT: 第 ' + (idx + 1) + ' 局 ' + line + ' · 单击下一局，点头申诉' });
    this._syncRound();
    this.setData({ stage: 'verdict' });
  },

  // answerText is canonical for both judge kinds: odd-one-out uses
  // the option label itself ('第 2 个'), size-sort uses the option
  // string ('2,1,3') - so one comparison serves both games.
  _applyJudge(idx, answerText, note) {
    var hit = answerText === this._guessText;
    this._results[idx] = hit ? 'hit' : 'miss';
    if (hit) this._score++;
    this._finishRound(idx,
      hit ? '猜中 ✓' : '没猜中 ✗',
      ('判定答案：' + answerText + ' · 你的猜测：' + this._guessText +
        (note ? ' · ' + note : '')).slice(0, 78));
    this._announce(hit ? '猜中了' : '没猜中，判定答案是' + answerText);
  },

  _advance() {
    if (this._idx + 1 >= ROUNDS.length) {
      this.setData({
        state: 'done', stage: 'verdict', runLabel: '再来一局',
        status: this.data.demoTag + '完成',
        heroText: '猜中 ' + this._score + ' / ' + ROUNDS.length,
        verdictLine: (this._demo ? '演示局结束 · ' : '本局结束 · ') + '猜中 ' + this._score + ' / ' + ROUNDS.length,
        detailLine: '申诉记录 ' + this._appeals + ' 次（只记录不改分）· 分数只存本局内存'
      });
      this._syncOptions();
      this._announce('本局结束，猜中' + this._score + '局，共' + ROUNDS.length + '局');
      return;
    }
    this._idx++;
    this._sel = 0;
    this.setData({ stage: 'guess', runLabel: '确认猜测', verdictLine: '先选你的猜测，再确认', detailLine: '猜测先定死，拍照判定后不许改口' });
    this._syncRound();
    this._announce(ROUNDS[this._idx].speak);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  _sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); },

  _announce(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text));
    } catch (e) { /* announcements must never break the game */ }
  },

  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      var buf = await blob.arrayBuffer();
      var bytes = new Uint8Array(buf);
      var bin = '';
      var CH = 0x8000;
      for (var i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: ' + String((e && e.message) || e).slice(0, 40));
    }
  },

  // Take one photo and convert it to a data: URL. Returns
  // { ok, url, bytes } or { ok:false, absent:true } when the host has
  // no camera surface at all (web preview), or { ok:false, error }
  // for a real capture failure. The wx fallback photo cannot become
  // a data: URL, so it can never feed the judge - reported honestly.
  async _snap(mode) {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia ||
        typeof ImageCapture === 'undefined') {
      return { ok: false, absent: true, error: 'mediaDevices/ImageCapture n/a on this host' };
    }
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: mode || 'default' }), 9000, 'photo');
      var url = await this._blobToDataUrl(blob);
      if (url.indexOf('data:') !== 0) throw new Error('photo conversion not a data url');
      return { ok: true, url: url, bytes: blob && blob.size ? blob.size : 0 };
    } catch (e) {
      return { ok: false, error: this._err(e) };
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
    }
  },

  // One LLM judge call. content is a LanguageModel content array
  // (text + image_url parts). Returns the raw answer text, or null
  // when the model is unavailable / errors / answers empty - the
  // caller must score that as a failed round, never invent a verdict.
  async _judge(content, systemText) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    var avail = null;
    try { avail = await LM.availability(); } catch (e) { return null; }
    if (avail !== 'available') return null;
    var session = null;
    try {
      session = await LM.create({
        initialPrompts: [{ role: 'system', content: systemText }]
      });
      var ans = await this._withTimeout(session.prompt(content), 45000, 'llm judge');
      if (!ans || !String(ans).trim()) return null;
      return String(ans);
    } catch (e) {
      return null;
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  _verdictOf(ans) {
    var m = /VERDICT[:：]\s*(YES|NO)/i.exec(ans || '');
    return m ? m[1].toUpperCase() : null;
  },

  _fieldOf(ans, name) {
    var re = new RegExp(name + '[:：]\\s*([^\\n]+)', 'i');
    var m = re.exec(ans || '');
    return m ? m[1].trim() : '';
  },

  onHeadGesture(event) {
    if (event && event.gesture === 'nod') this._onNod();
  }

};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">大小排序</text>
      <text class="progress">{{progressText}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="hero hero-steps">
      <text class="hero-label">{{heroLabel}}</text>
      <text class="hero-text">{{heroText}}</text>
    </view>
    <view class="opts {{optCls}}">
      <text ink:for="{{options}}" class="{{item.cls}}" bindtap="onOpt{{index}}">{{item.label}}</text>
    </view>
    <view class="verdict-box">
      <text class="verdict">{{verdictLine}}</text>
      <text class="detail">{{detailLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-steps" bindtap="onPrimary">{{runLabel}}</button>
      <button class="btn-demo" bindtap="onDemo">DEMO</button>
    </view>
    <view class="foot-row">
      <text class="foot">{{lastEvent}}</text>
      <text class="ver">{{appVersion}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 12px 16px; background-color: #000000; }
.head { display: flex; flex-direction: row; align-items: center; margin-bottom: 4px; }
.title { flex-grow: 1; color: #7dff9e; font-size: 22px; font-weight: 500; line-height: 26px; }
.progress { color: rgba(125,255,158,0.72); font-family: monospace; font-size: 13px; line-height: 17px; }
.status { color: rgba(125,255,158,0.72); font-size: 12px; line-height: 16px; margin-bottom: 6px; }
.hero { display: flex; flex-direction: column; align-items: center; padding: 10px 12px; margin-bottom: 8px; border: 1px solid rgba(125,255,158,0.6); border-bottom: 6px solid rgba(125,255,158,0.85); border-radius: 2px; }
.hero-label { color: rgba(125,255,158,0.62); font-size: 11px; line-height: 15px; }
.hero-text { color: #7dff9e; font-size: 19px; font-weight: 500; line-height: 25px; margin-top: 2px; text-align: center; }
.opts-off { display: none; }
.opts-on { display: flex; flex-direction: row; flex-wrap: wrap; margin-bottom: 8px; }
.opt { color: rgba(125,255,158,0.72); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-size: 13px; line-height: 17px; padding: 5px 9px; margin-right: 8px; margin-bottom: 6px; }
.opt-on { color: #000000; background-color: #7dff9e; font-weight: 500; }
.verdict-box { display: flex; flex-direction: column; min-height: 52px; margin-bottom: 4px; }
.verdict { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 22px; }
.detail { color: rgba(125,255,158,0.62); font-family: monospace; font-size: 10px; line-height: 14px; margin-top: 2px; }
.actions { display: flex; flex-direction: row; align-items: center; margin-top: auto; }
.btn { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 19px; text-align: center; padding: 9px; border: 1px solid rgba(125,255,158,0.9); border-bottom: 6px solid rgba(125,255,158,0.9); border-radius: 2px; background-color: rgba(125,255,158,0.15); }
.btn-demo { color: rgba(125,255,158,0.62); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-family: monospace; font-size: 10px; line-height: 14px; padding: 6px 8px; margin-left: 10px; background-color: rgba(0,0,0,0); }
.foot-row { display: flex; flex-direction: row; align-items: center; margin-top: 6px; }
.foot { flex-grow: 1; color: rgba(125,255,158,0.55); font-family: monospace; font-size: 10px; line-height: 14px; }
.ver { color: rgba(125,255,158,0.42); font-family: monospace; font-size: 10px; line-height: 14px; }
</style>
