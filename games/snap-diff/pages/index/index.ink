<script def>
{
  "navigationBarTitleText": "Snap Diff"
}
</script>

<script setup>
import wx from 'wx';

var TYPES = [
  { code: 'REMOVED', label: '少了一件' },
  { code: 'ADDED', label: '多了一件' },
  { code: 'MOVED', label: '一件移位' }
];
var DEMO_SEQ = [
  {
    "type": "REMOVED",
    "diff": "桌上的杯子不见了"
  },
  {
    "type": "ADDED",
    "diff": "书架上多了一本书"
  },
  {
    "type": "REMOVED",
    "diff": "椅子上的外套不见了"
  }
];
var TOTAL = 3;

export default {
  data: {
    state: 'ready',
    stage: 'first',
    status: '同一场景拍两张，中间改一处',
    heroLabel: '两拍找不同',
    heroText: '拍 · 改 · 拍',
    verdictLine: '判定仅供娱乐 · 有争议以玩家目测为准',
    detailLine: '先说你改了哪类，再由双图判定揭晓',
    progressText: '0 / 3',
    options: [],
    optCls: 'opts-off',
    lastEvent: 'EVT: 单击=拍照/确认 · 滑动=选改动类 · 点头=确认所选',
    appVersion: 'v1.0.0',
    runLabel: '开始',
    busy: false,
    demoTag: ''
  },

  onLoad() {
    this._round = 0;
    this._sel = 0;
    this._guess = 'REMOVED';
    this._photo1 = '';
    this._results = ['wait', 'wait', 'wait'];
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
    if (this.data.state === 'playing' && this.data.stage === 'declare') this._confirmType();
    else if (this.data.state === 'playing' && this.data.stage === 'verdict') {
      this._appeals++;
      this.setData({ lastEvent: 'EVT: 已记录申诉（第 ' + this._appeals + ' 次）· 分数不变' });
      this._announce('已记录申诉，分数不变');
    }
  },

  _moveSel(dir) {
    if (this.data.state !== 'playing' || this.data.stage !== 'declare' || this.data.busy) return;
    this._sel = (((this._sel + dir) % 3) + 3) % 3;
    this._syncOptions();
  },

  _syncOptions() {
    var self = this;
    this.setData({
      optCls: (this.data.state === 'playing' && this.data.stage === 'declare') ? 'opts-on' : 'opts-off',
      options: TYPES.map(function (t, i) {
        return { label: t.label, cls: i === self._sel ? 'opt opt-on' : 'opt' };
      })
    });
  },

  onPrimary() { this._primary(); },
  onDemo() { this._startDemo(); },
  onOpt0() { this._pick(0); },
  onOpt1() { this._pick(1); },
  onOpt2() { this._pick(2); },

  _pick(i) {
    if (this.data.state !== 'playing' || this.data.stage !== 'declare' || this.data.busy) return;
    this._sel = i;
    this._syncOptions();
  },

  _primary() {
    if (this.data.busy) return;
    if (this.data.state === 'ready' || this.data.state === 'done') { this._start(false); return; }
    if (this.data.stage === 'first') this._snapFirst();
    else if (this.data.stage === 'declare') this._confirmType();
    else if (this.data.stage === 'second') this._snapSecond();
    else if (this.data.stage === 'verdict') this._advance();
  },

  _startDemo() {
    if (this.data.busy || this.data.state === 'playing') return;
    this._start(true);
  },

  _start(demo) {
    this._demo = demo;
    this._round = 0;
    this._sel = 0;
    this._photo1 = '';
    this._results = ['wait', 'wait', 'wait'];
    this._score = 0;
    this._appeals = 0;
    this.setData({
      state: 'playing', stage: 'first', runLabel: '拍第一张',
      demoTag: demo ? '演示局 · ' : '',
      status: demo ? '演示局 · 第 1/3 局' : '第 1/3 局 · 对准场景拍第一张',
      heroText: '拍 · 改 · 拍',
      verdictLine: '对准场景，单击拍第一张',
      detailLine: demo ? '演示判定（预置结果）· 真机两张照片同送一次判定' : '第一张只存内存，拍完动手改一处'
    });
    this._syncOptions();
    this._announce((demo ? '演示局开始。' : '') + '拍第一张照片');
  },

  async _snapFirst() {
    this.setData({ busy: true, verdictLine: '拍照中…', detailLine: '正在拍第一张' });
    if (this._demo) {
      await this._sleep(400);
      this._photo1 = 'demo';
      this.setData({ busy: false });
      this._toDeclare();
      return;
    }
    var snap = await this._snap('default');
    if (!snap.ok) {
      this.setData({
        busy: false,
        verdictLine: snap.absent ? '本机无相机接口' : '拍照失败 · 可重拍',
        detailLine: snap.absent ? '网页预览无相机：点 DEMO 看演示局，或在真机上玩' : snap.error + ' · 再单击重拍'
      });
      return;
    }
    this._photo1 = snap.url;
    this.setData({ busy: false });
    this._toDeclare();
  },

  _toDeclare() {
    this._sel = 0;
    this.setData({
      stage: 'declare', runLabel: '确认改动',
      status: this.data.demoTag + '第 ' + (this._round + 1) + '/3 局 · 已拍第一张，去改一处',
      verdictLine: '动手改一处，再选你改了哪类',
      detailLine: '拿走一件 / 放进一件 / 挪动一件，只能改一处'
    });
    this._syncOptions();
    this._announce('去改一处，然后选你改了哪一类');
  },

  _confirmType() {
    if (this.data.busy) return;
    this._guess = TYPES[this._sel].code;
    this.setData({
      stage: 'second', runLabel: '拍第二张判定',
      verdictLine: '你说：' + TYPES[this._sel].label,
      detailLine: '回到原机位，对准同一场景拍第二张'
    });
    this._syncOptions();
    this._announce('记下了，拍第二张判定');
  },

  async _snapSecond() {
    var round = this._round;
    this.setData({ busy: true, verdictLine: '判定中…', detailLine: '两张照片同送大模型对比，请稍候' });
    if (this._demo) {
      await this._sleep(500);
      var d = DEMO_SEQ[round];
      this._applyDiff(round, d.type, d.diff);
      this.setData({ busy: false });
      return;
    }
    var snap = await this._snap('default');
    if (!snap.ok) {
      this.setData({
        busy: false,
        verdictLine: snap.absent ? '本机无相机接口' : '拍照失败 · 可重拍',
        detailLine: snap.error + ' · 再单击重拍第二张'
      });
      return;
    }
    var ans = await this._judge([
      { type: 'text', text: '这两张照片是同一场景，中间只有一处被改动。对比后只回复两行：第一行 TYPE: REMOVED（少了一件）或 ADDED（多了一件）或 MOVED（一件移位）或 NONE（看不出差异）；第二行 DIFF: 一句话说清差异，不超过25字。' },
      { type: 'image_url', image_url: { url: this._photo1 } },
      { type: 'image_url', image_url: { url: snap.url } }
    ], 'You compare two photos of the same scene and report the single change. Reply ONLY in the requested format, in Chinese.');
    if (!ans) {
      this._results[round] = 'fail';
      this._finishRound(round, '判定失败 · 本局不计分', '大模型不可用或无回答 · 如实记为失败');
      this.setData({ busy: false });
      return;
    }
    var type = this._fieldOf(ans, 'TYPE').toUpperCase();
    if (!type) {
      this._results[round] = 'fail';
      this._finishRound(round, '判定失败 · 本局不计分', '大模型回答格式不对 · 如实记为失败');
      this.setData({ busy: false });
      return;
    }
    this._applyDiff(round, type, this._fieldOf(ans, 'DIFF'));
    this.setData({ busy: false });
  },

  _applyDiff(round, type, diffText) {
    var names = { REMOVED: '少了一件', ADDED: '多了一件', MOVED: '一件移位', NONE: '看不出差异' };
    var hit = type === this._guess;
    this._results[round] = hit ? 'hit' : 'miss';
    if (hit) this._score++;
    this._finishRound(round,
      hit ? '说中 ✓' : '没说中 ✗ · 判定：' + (names[type] || type),
      ('判定差异：' + (diffText || '（无说明）') + ' · 你说：' + (names[this._guess] || this._guess)).slice(0, 78));
    this._announce(hit ? '说中了' : '没说中，判定是' + (names[type] || type));
  },

  _finishRound(round, line, detail) {
    this.setData({
      stage: 'verdict', runLabel: round + 1 >= TOTAL ? '看结果' : '下一局',
      progressText: this._score + ' / 3',
      verdictLine: line, detailLine: detail,
      lastEvent: 'EVT: 第 ' + (round + 1) + ' 局 ' + line + ' · 单击继续，点头申诉'
    });
    this._syncOptions();
  },

  _advance() {
    if (this._round + 1 >= TOTAL) {
      this.setData({
        state: 'done', stage: 'done', runLabel: '再来一局',
        status: this.data.demoTag + '完成 · 拍照游戏系列收官作',
        heroText: '说中 ' + this._score + ' / 3',
        verdictLine: (this._demo ? '演示局结束 · ' : '本局结束 · ') + '说中 ' + this._score + ' / 3',
        detailLine: '申诉记录 ' + this._appeals + ' 次（只记录不改分）· 两张照片都只存本局内存'
      });
      this._syncOptions();
      this._announce('本局结束，说中' + this._score + '局，共3局');
      return;
    }
    this._round++;
    this._photo1 = '';
    this.setData({
      stage: 'first', runLabel: '拍第一张',
      status: this.data.demoTag + '第 ' + (this._round + 1) + '/3 局 · 对准场景拍第一张',
      verdictLine: '对准场景，单击拍第一张',
      detailLine: '第一张只存内存，拍完动手改一处'
    });
    this._syncOptions();
    this._announce('第' + (this._round + 1) + '局，拍第一张');
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

  _blobToDataUrl(blob) {
    return new Promise(function (resolve, reject) {
      if (typeof FileReader === 'undefined') {
        reject(new Error('FileReader n/a on this host'));
        return;
      }
      var fr = new FileReader();
      fr.onload = function () { resolve(String(fr.result || '')); } ;
      fr.onerror = function () { reject(new Error('FileReader read failed')); };
      try { fr.readAsDataURL(blob); } catch (e) { reject(e); }
    });
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
      <text class="title">两拍找不同</text>
      <text class="progress">{{progressText}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="hero hero-diff">
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
      <button class="btn btn-diff" bindtap="onPrimary">{{runLabel}}</button>
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
.hero { display: flex; flex-direction: column; align-items: center; padding: 10px 12px; margin-bottom: 8px; border: 1px dashed rgba(125,255,158,0.8); border-radius: 10px; }
.hero-label { color: rgba(125,255,158,0.62); font-size: 11px; line-height: 15px; }
.hero-text { color: #7dff9e; font-size: 26px; font-weight: 500; line-height: 32px; margin-top: 2px; }
.opts-off { display: none; }
.opts-on { display: flex; flex-direction: row; flex-wrap: wrap; margin-bottom: 8px; }
.opt { color: rgba(125,255,158,0.72); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-size: 13px; line-height: 17px; padding: 5px 9px; margin-right: 8px; margin-bottom: 6px; }
.opt-on { color: #000000; background-color: #7dff9e; font-weight: 500; }
.verdict-box { display: flex; flex-direction: column; min-height: 52px; margin-bottom: 4px; }
.verdict { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 22px; }
.detail { color: rgba(125,255,158,0.62); font-family: monospace; font-size: 10px; line-height: 14px; margin-top: 2px; }
.actions { display: flex; flex-direction: row; align-items: center; margin-top: auto; }
.btn { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 19px; text-align: center; padding: 9px; border: 2px dashed rgba(125,255,158,0.85); border-radius: 22px; background-color: rgba(125,255,158,0.14); }
.btn-demo { color: rgba(125,255,158,0.62); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-family: monospace; font-size: 10px; line-height: 14px; padding: 6px 8px; margin-left: 10px; background-color: rgba(0,0,0,0); }
.foot-row { display: flex; flex-direction: row; align-items: center; margin-top: 6px; }
.foot { flex-grow: 1; color: rgba(125,255,158,0.55); font-family: monospace; font-size: 10px; line-height: 14px; }
.ver { color: rgba(125,255,158,0.42); font-family: monospace; font-size: 10px; line-height: 14px; }
</style>
