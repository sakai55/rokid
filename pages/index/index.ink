<script def>
{
  "navigationBarTitleText": "Texture Hunt"
}
</script>

<script setup>
import wx from 'wx';

var ROUNDS = [
  {
    "label": "木纹",
    "criteria": "",
    "speak": "找一处木纹表面，凑近拍"
  },
  {
    "label": "金属",
    "criteria": "",
    "speak": "找一处金属表面，凑近拍"
  },
  {
    "label": "布料",
    "criteria": "",
    "speak": "找一处布料表面，凑近拍"
  },
  {
    "label": "玻璃",
    "criteria": "",
    "speak": "找一处玻璃表面，凑近拍"
  },
  {
    "label": "纸",
    "criteria": "",
    "speak": "找一处纸的表面，凑近拍"
  }
];
var DEMO_SEQ = [
  {
    "v": true,
    "r": "木纹纹理清楚"
  },
  {
    "v": true,
    "r": "金属反光与拉丝纹"
  },
  {
    "v": false,
    "r": "主体是塑料，不是布料"
  },
  {
    "v": true,
    "r": "玻璃透光边缘明显"
  },
  {
    "v": false,
    "r": "拍到的是纸上的字，表面太远看不清质地"
  }
];
var PHOTO_MODE = 'default';
var JUDGE_KIND = 'texture';

export default {
  data: {
    state: 'ready',
    status: '每轮出一种质地，找实物表面凑近拍照',
    heroLabel: '目标质地',
    heroText: '5 种质地 · 凑近拍表面',
    verdictLine: '判定仅供娱乐 · 有争议以玩家目测为准',
    detailLine: '判的是表面质地，不是物体名字 · 凑近占满画面',
    progressText: '0 / 5',
    dots: [],
    cells: [],
    gridCls: 'grid-off',
    lastEvent: 'EVT: 单击=拍照判定 · 滑动=换目标 · 点头=申诉(不改分)',
    appVersion: 'v1.0.0',
    runLabel: '开始',
    busy: false,
    demoTag: ''
  },

  onLoad() {
    this._idx = 0;
    this._results = ROUNDS.map(function () { return 'wait'; });
    this._score = 0;
    this._appeals = 0;
    this._demo = false;
    this._verdictShown = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._syncDots();
    this._syncCells();
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowDown') this._cycle(1);
    else if (code === 'ArrowUp') this._cycle(-1);
    else if (code === 'Enter' || code === 'GlobalHook') this._primary();
  },

  _onNod() {
    if (this.data.busy) return;
    if (this.data.state === 'playing' && this._verdictShown) {
      this._appeals++;
      this.setData({ lastEvent: 'EVT: 已记录申诉（第 ' + this._appeals + ' 次）· 分数不变' });
      this._announce('已记录申诉，分数不变');
    } else if (this.data.state === 'playing') {
      this._announce(ROUNDS[this._idx].speak);
      this.setData({ lastEvent: 'EVT: 点头重读目标（判定后点头=申诉）' });
    }
  },

  // Swipe cycles the current target among unfinished rounds only.
  _cycle(dir) {
    if (this.data.state !== 'playing' || this.data.busy || this._verdictShown) return;
    var n = ROUNDS.length;
    for (var step = 1; step !== n + 1; step++) {
      var i = (((this._idx + dir * step) % n) + n) % n;
      if (this._results[i] === 'wait') {
        this._idx = i;
        this._syncHero();
        this._announce(ROUNDS[i].speak);
        return;
      }
    }
  },

  onPrimary() { this._primary(); },
  onDemo() { this._startDemo(); },

  _primary() {
    if (this.data.busy) return;
    if (this.data.state === 'ready' || this.data.state === 'done') { this._start(false); return; }
    if (this._verdictShown) this._advance();
    else this._shoot();
  },

  _startDemo() {
    if (this.data.busy || this.data.state === 'playing') return;
    this._start(true);
  },

  _start(demo) {
    this._demo = demo;
    this._idx = 0;
    this._results = ROUNDS.map(function () { return 'wait'; });
    this._score = 0;
    this._appeals = 0;
    this._verdictShown = false;
    this.setData({
      state: 'playing',
      demoTag: demo ? '演示局 · ' : '',
      runLabel: '拍照判定',
      verdictLine: '对准目标，单击拍照',
      detailLine: demo ? '演示判定（预置结果）· 真机走真实拍照+大模型判定' : '照片只在内存里判定，不保存'
    });
    this._syncDots();
    this._syncHero();
    this._announce(demo ? '演示局开始。' + ROUNDS[0].speak : ROUNDS[0].speak);
  },

  _syncHero() {
    var r = ROUNDS[this._idx];
    this.setData({
      heroText: r.label,
      status: this.data.demoTag + '第 ' + (this._idx + 1) + ' / ' + ROUNDS.length + ' 轮',
      progressText: this._score + ' / ' + ROUNDS.length
    });
    this._syncCells();
  },

  _syncCells() {
    var zone = this.data.state === 'playing' ? (ROUNDS[this._idx] && ROUNDS[this._idx].zone) : null;
    var codes = ['TL', 'TC', 'TR', 'ML', 'C', 'MR', 'BL', 'BC', 'BR'];
    var self = this;
    this.setData({
      gridCls: zone ? 'grid-on' : 'grid-off',
      cells: codes.map(function (c) {
        return { code: c, cls: c === zone ? 'cell cell-on' : 'cell' };
      })
    });
  },

  _syncDots() {
    var marks = { wait: '·', hit: '✓', miss: '✗', fail: '!' };
    var self = this;
    this.setData({
      dots: this._results.map(function (r, i) {
        return { mark: marks[r], cls: 'dot dot-' + r + (i === self._idx && self.data.state === 'playing' ? ' dot-cur' : '') };
      }),
      progressText: this._score + ' / ' + ROUNDS.length
    });
  },

  _buildContent(round, url) {
    return [
      { type: 'text', text: '目标质地：' + round.label + '。判断照片主体表面的质地是否就是这种质地（看纹理与材质，不看物体名称）。只回复两行：第一行 VERDICT: YES 或 VERDICT: NO；第二行 REASON: 一句不超过20字的理由。看不清回 NO 并说明。' },
      { type: 'image_url', image_url: { url: url } }
    ];
  },

  async _shoot() {
    var idx = this._idx;
    var round = ROUNDS[idx];
    this.setData({ busy: true, verdictLine: '判定中…', detailLine: '正在拍照并请大模型判定，请稍候' });
    if (this._demo) {
      await this._sleep(500);
      var d = DEMO_SEQ[idx];
      this._applyVerdict(idx, d.v, d.r, d.x || '');
      this.setData({ busy: false });
      return;
    }
    var snap = await this._snap(PHOTO_MODE);
    if (!snap.ok) {
      this.setData({
        busy: false,
        verdictLine: snap.absent ? '本机无相机接口' : '拍照失败 · 本轮未消耗',
        detailLine: snap.absent ? '网页预览无相机：点 DEMO 看演示局，或在真机上玩' : snap.error + ' · 再单击重试'
      });
      return;
    }
    var ans = await this._judge(this._buildContent(round, snap.url),
      'You are a strict but fair judge for a photo game played on smart glasses. Reply ONLY in the requested format, in Chinese.');
    if (!ans) {
      this._results[idx] = 'fail';
      this._finishRound(idx, '判定失败 · 本轮不计分', '大模型不可用或无回答 · 如实记为失败', '判定失败，本轮不计分');
      this.setData({ busy: false });
      return;
    }
    var v = this._verdictOf(ans);
    if (!v) {
      this._results[idx] = 'fail';
      this._finishRound(idx, '判定失败 · 本轮不计分', '大模型回答格式不对 · 如实记为失败', '判定失败，本轮不计分');
      this.setData({ busy: false });
      return;
    }
    this._applyVerdict(idx, v === 'YES', this._fieldOf(ans, 'REASON'), '');
    this.setData({ busy: false });
  },

  _applyVerdict(idx, hit, reason, extra) {
    this._results[idx] = hit ? 'hit' : 'miss';
    if (hit) this._score++;
    var line = hit ? '命中 ✓' : '没中 ✗';
    var detail = (extra ? extra + ' · ' : '') + (reason || '');
    this._finishRound(idx, line, detail.slice(0, 78),
      hit ? '命中' : '没中');
  },

  _finishRound(idx, line, detail, speakWord) {
    this._verdictShown = true;
    this._syncDots();
    this.setData({
      verdictLine: line,
      detailLine: detail,
      lastEvent: 'EVT: 第 ' + (idx + 1) + ' 轮 ' + line + ' · 单击下一轮，点头申诉'
    });
    this._announce(speakWord + '。已命中' + this._score + '个');
  },

  _advance() {
    this._verdictShown = false;
    var n = ROUNDS.length;
    for (var step = 1; step !== n + 1; step++) {
      var i = (this._idx + step) % n;
      if (this._results[i] === 'wait') {
        this._idx = i;
        this._syncHero();
        this.setData({ verdictLine: '对准目标，单击拍照', detailLine: '照片只在内存里判定，不保存' });
        this._announce(ROUNDS[i].speak);
        return;
      }
    }
    this.setData({
      state: 'done',
      runLabel: '再来一局',
      status: this.data.demoTag + '完成',
      heroText: '命中 ' + this._score + ' / ' + ROUNDS.length,
      verdictLine: (this._demo ? '演示局结束 · ' : '本局结束 · ') + '命中 ' + this._score + ' / ' + ROUNDS.length,
      detailLine: '申诉记录 ' + this._appeals + ' 次（只记录不改分）· 分数只存本局内存'
    });
    this._syncDots();
    this._syncCells();
    this._announce('本局结束，命中' + this._score + '个，共' + ROUNDS.length + '个');
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
      <text class="title">质地猎手</text>
      <text class="progress">{{progressText}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="hero hero-weave">
      <text class="hero-label">{{heroLabel}}</text>
      <text class="hero-text">{{heroText}}</text>
      <view class="grid {{gridCls}}">
        <view ink:for="{{cells}}" class="{{item.cls}}"></view>
      </view>
    </view>
    <view class="verdict-box">
      <text class="verdict">{{verdictLine}}</text>
      <text class="detail">{{detailLine}}</text>
    </view>
    <view class="dots">
      <text ink:for="{{dots}}" class="{{item.cls}}">{{item.mark}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-weave" bindtap="onPrimary">{{runLabel}}</button>
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
.hero { display: flex; flex-direction: column; align-items: center; padding: 10px 12px; margin-bottom: 8px; border: 1px solid rgba(125,255,158,0.6); border-radius: 12px; }
.hero-label { color: rgba(125,255,158,0.62); font-size: 11px; line-height: 15px; }
.hero-text { color: #7dff9e; font-size: 30px; font-weight: 500; line-height: 36px; margin-top: 2px; }
.grid-off { display: none; }
.grid-on { display: flex; flex-direction: row; flex-wrap: wrap; width: 62px; margin-top: 6px; }
.cell { width: 16px; height: 10px; border: 1px solid rgba(125,255,158,0.38); margin: 1px; }
.cell-on { background-color: rgba(125,255,158,0.55); }
.verdict-box { display: flex; flex-direction: column; min-height: 52px; margin-bottom: 4px; }
.verdict { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 22px; }
.detail { color: rgba(125,255,158,0.62); font-family: monospace; font-size: 10px; line-height: 14px; margin-top: 2px; }
.dots { display: flex; flex-direction: row; margin-bottom: 8px; }
.dot { font-family: monospace; font-size: 15px; line-height: 19px; margin-right: 10px; color: rgba(125,255,158,0.38); }
.dot-hit { color: #7dff9e; }
.dot-miss { color: rgba(125,255,158,0.55); }
.dot-fail { color: rgba(125,255,158,0.85); }
.dot-cur { text-decoration: underline; }
.actions { display: flex; flex-direction: row; align-items: center; margin-top: auto; }
.btn { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 19px; text-align: center; padding: 9px; border: 1px solid rgba(125,255,158,0.9); border-radius: 12px; background-color: rgba(125,255,158,0.18); }
.btn-demo { color: rgba(125,255,158,0.62); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-family: monospace; font-size: 10px; line-height: 14px; padding: 6px 8px; margin-left: 10px; background-color: rgba(0,0,0,0); }
.foot-row { display: flex; flex-direction: row; align-items: center; margin-top: 6px; }
.foot { flex-grow: 1; color: rgba(125,255,158,0.55); font-family: monospace; font-size: 10px; line-height: 14px; }
.ver { color: rgba(125,255,158,0.42); font-family: monospace; font-size: 10px; line-height: 14px; }
</style>
