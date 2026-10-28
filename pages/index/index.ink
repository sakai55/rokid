<script def>
{
  "navigationBarTitleText": "Scene Memory"
}
</script>

<script setup>
import wx from 'wx';

var DEMO_QA = [
  {
    "q": "画面左边放着什么颜色的杯子？",
    "a": "红色杯子"
  },
  {
    "q": "画面里一共有几本书？",
    "a": "三本书"
  },
  {
    "q": "桌子右上角是什么？",
    "a": "一盆绿植"
  }
];

export default {
  data: {
    state: 'ready',
    stage: 'photo',
    status: '先拍一张场景照，再凭记忆答题',
    heroLabel: '场景记忆',
    heroText: '拍一张 · 答三题',
    verdictLine: '判定仅供娱乐 · 答案以首图判定为准',
    detailLine: '首图的问答由大模型当场定死，答题阶段不再看图',
    progressText: '0 / 3',
    options: [],
    optCls: 'opts-off',
    lastEvent: 'EVT: 单击=拍照/确认答案 · 滑动=换选项 · 点头=确认答案',
    appVersion: 'v1.0.1',
    runLabel: '开始',
    busy: false,
    demoTag: ''
  },

  onLoad() {
    this._qa = [];
    this._q = 0;
    this._sel = 0;
    this._score = 0;
    this._demo = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowDown') this._moveSel(1);
    else if (code === 'ArrowUp') this._moveSel(-1);
    else if (code === 'Enter' || code === 'GlobalHook') this._primary();
  },

  _onNod() {
    if (this.data.busy) return;
    if (this.data.state === 'playing' && this.data.stage === 'quiz') this._confirmAnswer();
  },

  _moveSel(dir) {
    if (this.data.state !== 'playing' || this.data.stage !== 'quiz' || this.data.busy) return;
    var n = this.data.options.length;
    if (!n) return;
    this._sel = (((this._sel + dir) % n) + n) % n;
    this._syncOptions();
  },

  _syncOptions() {
    var self = this;
    var qa = this._qa[this._q];
    if (!qa) { this.setData({ optCls: 'opts-off', options: [] }); return; }
    // The three options are the three correct answers, rotated per
    // question: the player must remember WHICH answer belongs to
    // WHICH question. Deterministic, no Math.random.
    var opts = [];
    for (var k = 0; k !== 3; k++) opts.push(this._qa[(this._q + k) % 3].a);
    this.setData({
      optCls: 'opts-on',
      options: opts.map(function (o, i) {
        return { label: o, cls: i === self._sel ? 'opt opt-on' : 'opt' };
      })
    });
  },

  onPrimary() { this._primary(); },
  onDemo() { this._startDemo(); },
  onOpt0() { this._pick(0); },
  onOpt1() { this._pick(1); },
  onOpt2() { this._pick(2); },

  _pick(i) {
    if (this.data.state !== 'playing' || this.data.stage !== 'quiz' || this.data.busy) return;
    this._sel = i;
    this._syncOptions();
  },

  _primary() {
    if (this.data.busy) return;
    if (this.data.state === 'ready' || this.data.state === 'done') { this._start(false); return; }
    if (this.data.stage === 'photo') this._snapAnalyze();
    else if (this.data.stage === 'quiz') this._confirmAnswer();
  },

  _startDemo() {
    if (this.data.busy || this.data.state === 'playing') return;
    this._start(true);
  },

  _start(demo) {
    this._demo = demo;
    this._qa = [];
    this._q = 0;
    this._sel = 0;
    this._score = 0;
    this.setData({
      state: 'playing', stage: 'photo',
      demoTag: demo ? '演示局 · ' : '',
      runLabel: '拍场景照',
      status: demo ? '演示局 · 拍一张场景照（演示）' : '对准一个场景，拍一张全景照',
      heroText: '拍一张 · 答三题',
      verdictLine: '拍完请转过头去，凭记忆答题',
      detailLine: '照片只在内存里出题，不保存'
    });
    this._syncOptions();
    this._announce((demo ? '演示局开始。' : '') + '先拍一张场景照');
  },

  async _snapAnalyze() {
    this.setData({ busy: true, verdictLine: '出题中…', detailLine: '大模型正看着首图出 3 道题，请稍候' });
    if (this._demo) {
      await this._sleep(500);
      this._qa = DEMO_QA;
      this.setData({ busy: false });
      this._beginQuiz('演示题已定死（预置）· 真机由首图判定生成');
      return;
    }
    var snap = await this._snap('wide');
    if (!snap.ok) {
      this.setData({
        busy: false,
        verdictLine: snap.absent ? '本机无相机接口' : '拍照失败 · 可重拍',
        detailLine: snap.absent ? '网页预览无相机：点 DEMO 看演示局，或在真机上玩' : snap.error + ' · 再单击重拍'
      });
      return;
    }
    var ans = await this._judge([
      { type: 'text', text: '仔细看这张场景照片，为戴眼镜的玩家出3道记忆题。每题占一行，格式严格为：Q1: <问题> | A1: <简短正确答案>（题号依次1、2、3）。问题只能问照片中确实可见的东西：物品、颜色、数量、左右位置。答案要短，不超过6个字。只回复这3行，不要任何其他文字。' },
      { type: 'image_url', image_url: { url: snap.url } }
    ], 'You create memory-quiz questions from one photo. Reply ONLY in the requested format, in Chinese.');
    var qa = this._parseQa(ans);
    if (!qa) {
      this.setData({
        busy: false,
        verdictLine: '出题失败 · 可重拍',
        detailLine: '大模型不可用或没按格式出题 · 如实记为失败，不编题'
      });
      return;
    }
    this._qa = qa;
    this.setData({ busy: false });
    this._beginQuiz('题目已按首图定死 · 转过头，凭记忆答');
  },

  _parseQa(ans) {
    if (!ans) return null;
    var found = {};
    var re = /Q([123])[:：]\s*([^|\n]+)\|\s*A[123][:：]\s*([^\n]+)/g;
    var m;
    while ((m = re.exec(ans)) !== null) {
      found[m[1]] = { q: m[2].trim().slice(0, 30), a: m[3].trim().slice(0, 12) };
    }
    if (!found['1'] || !found['2'] || !found['3']) return null;
    return [found['1'], found['2'], found['3']];
  },

  _beginQuiz(note) {
    this._q = 0;
    this._sel = 0;
    this.setData({
      stage: 'quiz', runLabel: '确认答案',
      status: this.data.demoTag + '答题 1 / 3 · 已转头，凭记忆',
      heroText: this._qa[0].q,
      verdictLine: '选一个答案，单击或点头确认',
      detailLine: note
    });
    this._syncOptions();
    this._announce('转过头，凭记忆答题。第一题：' + this._qa[0].q);
  },

  _confirmAnswer() {
    if (this.data.busy || this.data.stage !== 'quiz') return;
    var qa = this._qa[this._q];
    var opts = [];
    for (var k = 0; k !== 3; k++) opts.push(this._qa[(this._q + k) % 3].a);
    var picked = opts[this._sel];
    var hit = picked === qa.a;
    if (hit) this._score++;
    var last = this._q + 1 >= 3;
    this.setData({
      progressText: this._score + ' / 3',
      verdictLine: hit ? '答对 ✓' : '答错 ✗ · 正解：' + qa.a,
      detailLine: last ? '最后一题已答完' : '单击继续下一题',
      lastEvent: 'EVT: 第 ' + (this._q + 1) + ' 题 ' + (hit ? '答对' : '答错')
    });
    this._announce(hit ? '答对' : '答错，正解是' + qa.a);
    if (last) {
      this.setData({
        state: 'done', stage: 'done', runLabel: '再来一局',
        status: this.data.demoTag + '完成',
        heroText: '答对 ' + this._score + ' / 3',
        verdictLine: (this._demo ? '演示局结束 · ' : '本局结束 · ') + '答对 ' + this._score + ' / 3',
        detailLine: '答案以首图判定为准 · 分数只存本局内存'
      });
      this._syncOptions();
      this.setData({ optCls: 'opts-off', options: [] });
      this._announce('本局结束，答对' + this._score + '题，共3题');
    } else {
      this._q++;
      this._sel = 0;
      this.setData({
        stage: 'quiz',
        status: this.data.demoTag + '答题 ' + (this._q + 1) + ' / 3 · 已转头，凭记忆',
        heroText: this._qa[this._q].q,
        detailLine: '选一个答案，单击或点头确认'
      });
      this._syncOptions();
      this._announce('第' + (this._q + 1) + '题：' + this._qa[this._q].q);
    }
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
      <text class="title">场景记忆</text>
      <text class="progress">{{progressText}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="hero hero-frame">
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
      <button class="btn btn-frame" bindtap="onPrimary">{{runLabel}}</button>
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
.hero { display: flex; flex-direction: column; align-items: center; padding: 10px 12px; margin-bottom: 8px; border: 3px double rgba(125,255,158,0.8); border-radius: 2px; }
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
.btn { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 19px; text-align: center; padding: 9px; border: 3px double rgba(125,255,158,0.85); border-radius: 2px; background-color: rgba(125,255,158,0.10); }
.btn-demo { color: rgba(125,255,158,0.62); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-family: monospace; font-size: 10px; line-height: 14px; padding: 6px 8px; margin-left: 10px; background-color: rgba(0,0,0,0); }
.foot-row { display: flex; flex-direction: row; align-items: center; margin-top: 6px; }
.foot { flex-grow: 1; color: rgba(125,255,158,0.55); font-family: monospace; font-size: 10px; line-height: 14px; }
.ver { color: rgba(125,255,158,0.42); font-family: monospace; font-size: 10px; line-height: 14px; }
</style>
