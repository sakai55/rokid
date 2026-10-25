<script def>
{
  "navigationBarTitleText": "Barcode Bingo"
}
</script>

<script setup>
import wx from 'wx';

var CELLS = [
  {
    "label": "二维码",
    "fmt": "qr_code"
  },
  {
    "label": "商品码13",
    "fmt": "ean_13"
  },
  {
    "label": "条码128",
    "fmt": "code_128"
  },
  {
    "label": "商品码8",
    "fmt": "ean_8"
  },
  {
    "label": "条码39",
    "fmt": "code_39"
  },
  {
    "label": "UPC-A",
    "fmt": "upc_a"
  },
  {
    "label": "数据矩阵",
    "fmt": "data_matrix"
  },
  {
    "label": "库德巴",
    "fmt": "codabar"
  },
  {
    "label": "PDF417",
    "fmt": "pdf417"
  }
];
var LINES = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
var DEMO_SEQ = [
  "qr_code",
  "ean_13",
  "code_128",
  "qr_code",
  "ean_8",
  "code_39",
  "upc_a",
  "data_matrix",
  "codabar",
  "pdf417"
];
var MAX_SCANS = 12;

export default {
  data: {
    state: 'ready',
    status: '在身边实物上找条码，对准格子扫',
    heroLabel: '宾果盘 · 凑线计分',
    verdictLine: '判定用原生条码检测，不是大模型',
    detailLine: '扫到对应码制就填格 · 连成一线 +3 分',
    progressText: '0 格 · 0 线',
    cells: [],
    lastEvent: 'EVT: 单击=扫码 · 点头=播报盘面 · 扫满12次或填满结束',
    appVersion: 'v1.0.0',
    runLabel: '开始',
    busy: false,
    demoTag: ''
  },

  onLoad() {
    this._filled = CELLS.map(function () { return false; });
    this._scans = 0;
    this._demo = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._syncBoard();
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') this._primary();
  },

  _onNod() {
    if (this.data.busy || this.data.state !== 'playing') return;
    var filled = this._filled.filter(Boolean).length;
    var lines = this._lines();
    this._announce('已填' + filled + '格，连成' + lines + '线，已扫' + this._scans + '次');
    this.setData({ lastEvent: 'EVT: 盘面播报 ' + filled + '/9 格 · ' + lines + ' 线' });
  },

  _lines() {
    var self = this;
    var n = 0;
    LINES.forEach(function (L) {
      if (self._filled[L[0]] && self._filled[L[1]] && self._filled[L[2]]) n++;
    });
    return n;
  },

  _score() {
    return this._filled.filter(Boolean).length + this._lines() * 3;
  },

  _syncBoard() {
    var self = this;
    this.setData({
      cells: CELLS.map(function (c, i) {
        return { label: c.label, fmt: c.fmt, mark: self._filled[i] ? '✓' : '·',
          cls: self._filled[i] ? 'cell cell-on' : 'cell' };
      }),
      progressText: this._filled.filter(Boolean).length + ' 格 · ' + this._lines() + ' 线 · ' + this._score() + ' 分'
    });
  },

  onPrimary() { this._primary(); },
  onDemo() { this._startDemo(); },

  _primary() {
    if (this.data.busy) return;
    if (this.data.state === 'ready' || this.data.state === 'done') { this._start(false); return; }
    this._scan();
  },

  _startDemo() {
    if (this.data.busy || this.data.state === 'playing') return;
    this._start(true);
  },

  _start(demo) {
    this._demo = demo;
    this._filled = CELLS.map(function () { return false; });
    this._scans = 0;
    this.setData({
      state: 'playing', runLabel: '扫码',
      demoTag: demo ? '演示局 · ' : '',
      status: demo ? '演示局 · 单击扫码（演示）' : '找实物条码，对准后单击扫码',
      verdictLine: '对准一个条码，单击扫码',
      detailLine: demo ? '演示扫码（预置码制）· 真机走原生 BarcodeDetector' : '拍照后用原生检测认码制 · 照片不保存'
    });
    this._syncBoard();
    this._announce((demo ? '演示局开始。' : '') + '条码宾果开始，找条码扫吧');
  },

  async _snapBlob() {
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
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'wide' }), 9000, 'photo');
      return { ok: true, blob: blob };
    } catch (e) {
      return { ok: false, error: this._err(e) };
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
      }
    }
  },

  async _scan() {
    if (this.data.busy) return;
    this.setData({ busy: true, verdictLine: '扫码中…', detailLine: '正在拍照并用原生检测认码制' });
    var fmt = null;
    var rawVal = '';
    if (this._demo) {
      await this._sleep(400);
      fmt = DEMO_SEQ[Math.min(this._scans, DEMO_SEQ.length - 1)];
    } else {
      if (typeof BarcodeDetector === 'undefined') {
        this.setData({ busy: false, verdictLine: '本机无条码检测接口',
          detailLine: 'BarcodeDetector 不可用 · 点 DEMO 看演示局，或在真机上玩' });
        return;
      }
      var snap = await this._snapBlob();
      if (!snap.ok) {
        this.setData({
          busy: false,
          verdictLine: snap.absent ? '本机无相机接口' : '拍照失败 · 本次未消耗',
          detailLine: snap.absent ? '网页预览无相机：点 DEMO 看演示局，或在真机上玩' : snap.error + ' · 再单击重试'
        });
        return;
      }
      try {
        var bmp = await createImageBitmap(snap.blob);
        var det = new BarcodeDetector();
        var codes = await this._withTimeout(det.detect(bmp), 9000, 'detect');
        try { bmp.close(); } catch (e) {}
        if (!codes || !codes.length) {
          this.setData({ busy: false, verdictLine: '没扫到码 · 本次未消耗', detailLine: '对准条码、拿稳一点，再单击重试' });
          return;
        }
        fmt = codes[0].format || '';
        rawVal = codes[0].rawValue || '';
      } catch (e) {
        this.setData({ busy: false, verdictLine: '检测失败 · 本次未消耗', detailLine: this._err(e) + ' · 再单击重试' });
        return;
      }
    }
    this._scans++;
    var hitIdx = -1;
    for (var i = 0; i !== CELLS.length; i++) {
      if (CELLS[i].fmt === fmt && !this._filled[i]) { hitIdx = i; break; }
    }
    var dup = false;
    if (hitIdx < 0) {
      for (var j = 0; j !== CELLS.length; j++) {
        if (CELLS[j].fmt === fmt && this._filled[j]) dup = true;
      }
    }
    if (hitIdx >= 0) {
      this._filled[hitIdx] = true;
      this.setData({
        verdictLine: '填格 ✓ ' + CELLS[hitIdx].label,
        detailLine: '码制 ' + fmt + (rawVal ? ' · 内容 ' + String(rawVal).slice(0, 18) : '') + ' · 已扫 ' + this._scans + '/' + MAX_SCANS + ' 次'
      });
      this._announce('填上了，' + CELLS[hitIdx].label);
    } else {
      this.setData({
        verdictLine: dup ? '这个码制已经填过了' : '盘上没有这个码制',
        detailLine: '扫到码制 ' + (fmt || '?') + ' · 已扫 ' + this._scans + '/' + MAX_SCANS + ' 次 · 本次计次但不填格'
      });
      this._announce(dup ? '这个码制填过了' : '盘上没有这个码制');
    }
    this._syncBoard();
    this.setData({ busy: false });
    if (this._filled.every(Boolean) || this._scans >= MAX_SCANS) this._done();
  },

  _done() {
    var filled = this._filled.filter(Boolean).length;
    this.setData({
      state: 'done', runLabel: '再来一局',
      status: this.data.demoTag + '完成',
      verdictLine: (this._demo ? '演示局结束 · ' : '本局结束 · ') + filled + '/9 格 · ' + this._lines() + ' 线 · ' + this._score() + ' 分',
      detailLine: '分数只存本局内存 · 扫码次数 ' + this._scans + '/' + MAX_SCANS
    });
    this._announce('本局结束，填了' + filled + '格，连成' + this._lines() + '线，共' + this._score() + '分');
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
      <text class="title">条码宾果</text>
      <text class="progress">{{progressText}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="board">
      <view ink:for="{{cells}}" class="{{item.cls}}">
        <text class="cell-mark">{{item.mark}}</text>
        <text class="cell-label">{{item.label}}</text>
        <text class="cell-fmt">{{item.fmt}}</text>
      </view>
    </view>
    <view class="verdict-box">
      <text class="verdict">{{verdictLine}}</text>
      <text class="detail">{{detailLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-bingo" bindtap="onPrimary">{{runLabel}}</button>
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
.board { display: flex; flex-direction: row; flex-wrap: wrap; width: 296px; margin: 0 auto 6px auto; }
.cell { display: flex; flex-direction: column; align-items: center; width: 88px; height: 42px; border: 1px solid rgba(125,255,158,0.45); margin: 2px; padding: 2px; }
.cell-on { background-color: rgba(125,255,158,0.30); border: 1px solid #7dff9e; }
.cell-mark { color: #7dff9e; font-size: 12px; line-height: 15px; }
.cell-label { color: rgba(125,255,158,0.85); font-size: 10px; line-height: 13px; }
.cell-fmt { color: rgba(125,255,158,0.45); font-family: monospace; font-size: 8px; line-height: 10px; }
.verdict-box { display: flex; flex-direction: column; min-height: 40px; margin-bottom: 4px; }
.verdict { color: #7dff9e; font-size: 16px; font-weight: 500; line-height: 21px; }
.detail { color: rgba(125,255,158,0.62); font-family: monospace; font-size: 10px; line-height: 14px; margin-top: 2px; }
.actions { display: flex; flex-direction: row; align-items: center; margin-top: auto; }
.btn { flex-grow: 1; color: #000000; font-size: 15px; font-weight: 500; line-height: 19px; text-align: center; padding: 9px; border: 1px solid #7dff9e; border-radius: 6px; background-color: rgba(125,255,158,0.75); }
.btn-demo { color: rgba(125,255,158,0.62); border: 1px solid rgba(125,255,158,0.38); border-radius: 4px; font-family: monospace; font-size: 10px; line-height: 14px; padding: 6px 8px; margin-left: 10px; background-color: rgba(0,0,0,0); }
.foot-row { display: flex; flex-direction: row; align-items: center; margin-top: 6px; }
.foot { flex-grow: 1; color: rgba(125,255,158,0.55); font-family: monospace; font-size: 10px; line-height: 14px; }
.ver { color: rgba(125,255,158,0.42); font-family: monospace; font-size: 10px; line-height: 14px; }
</style>
