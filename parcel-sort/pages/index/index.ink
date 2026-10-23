<script def>
{
  "navigationBarTitleText": "Parcel Sort"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT A PARCEL - SCAN its label barcode',
    steadyText: 'HEAD: moving - hold still',
    modeText: 'MODE: SORT',
    codeLine: 'CODE: --- · SCAN wide barcode (record ID only)',
    whoLine: 'WHO: 我 · tap WHO - you read the label, it cannot',
    kindLine: 'KIND: 日用品 · tap KIND',
    urgLine: 'URG: 常 · tap URG to flip (fresh food auto-急）',
    pilesLine: 'PILES: 急件 0 · 普通 0 · 共 0 件',
    byLine: '我 0 · 配偶 0 · 孩子 0 · 父母 0 · 全家 0',
    countText: 'SORTED: 0/30',
    rows: [
      { text: '(nothing sorted yet - SCAN a parcel, then SORT)' }
    ],
    lastEvent: 'EVT: barcode is an ID only - no carrier lookup exists',
    busy: false
  },

  onLoad() {
    this._mode = 'SORT';
    this._parcels = this._loadParcels();
    this._pending = this._freshPending();
    this._steady = false;
    this._demo = false;
    this._stream = null;
    this._lastSpeak = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._recompute();
    this.setData({ lastEvent: 'EVT: look at one parcel at a time - you read its label' });
  },

  onUnload() {
    this._stopStream();
    this._saveParcels();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - nod = SORT' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (this._mode === 'LIST') { this.speakTap(); return; }
    if (this._steady) {
      this.sortTap();
    } else {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'LIST') this.speakTap(); else this.sortTap();
    } else if (code === 'ArrowDown') {
      this.whoTap();
    } else if (code === 'ArrowUp') {
      this.kindTap();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'ArrowUp' || code === 'ArrowDown') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 60);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _pad2(n) { return (n < 10 ? '0' : '') + n; },

  // Date/time strings from ONE snapshot's parts - never a second
  // sample, so a batch of seeds can never drift apart (preview host's
  // Date is virtualized and drifts between samples; #25/#26 lesson).
  _dateStrParts(y, m0, day) {
    return y + '-' + this._pad2(m0 + 1) + '-' + this._pad2(day);
  },

  _timeStrParts(h, mi) {
    return this._pad2(h) + ':' + this._pad2(mi);
  },

  _nowParts() {
    var d = new Date();
    return {
      date: this._dateStrParts(d.getFullYear(), d.getMonth(), d.getDate()),
      time: this._timeStrParts(d.getHours(), d.getMinutes())
    };
  },

  // ---------- vocabularies ----------

  _whos() { return ['我', '配偶', '孩子', '父母', '全家']; },
  _kinds() { return ['日用品', '食品生鲜', '文件', '衣物', '电子产品', '其他']; },

  _freshPending() {
    return { code: null, noCode: false, who: '我', kind: '日用品', urgent: false };
  },

  // The sequential label a code-less parcel will get if committed now.
  _nextLabel() { return '#' + ((this._parcels || []).length + 1); },

  // ---------- persistence (wx sync storage, key 'parcelSort', cap 30) ----------

  _loadParcels() {
    try {
      var raw = wx.getStorageSync('parcelSort');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 30; i++) {
        var r = raw[i];
        if (r && typeof r.code === 'string' && r.code &&
            this._whos().indexOf(r.who) >= 0 &&
            this._kinds().indexOf(r.kind) >= 0 &&
            typeof r.date === 'string' && typeof r.time === 'string') {
          out.push({
            code: String(r.code).slice(0, 40),
            who: r.who,
            kind: r.kind,
            urgent: !!r.urgent,
            date: String(r.date).slice(0, 10),
            time: String(r.time).slice(0, 5),
            demo: !!r.demo
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveParcels() {
    try {
      wx.setStorageSync('parcelSort', this._parcels || []);
    } catch (e) { /* storage unavailable on this host: batch stays in memory */ }
  },

  // Cap 30 parcels per batch: beyond that the OLDEST falls off.
  _addParcel(entry) {
    var arr = this._parcels || [];
    arr.push(entry);
    while (arr.length > 30) arr.shift();
    this._parcels = arr;
    this._saveParcels();
  },

  // ---------- piles aggregation ----------

  _piles() {
    var p = { total: 0, urgent: 0, normal: 0, byWho: {} };
    var whos = this._whos();
    for (var w = 0; w !== whos.length; w++) p.byWho[whos[w]] = 0;
    var arr = this._parcels || [];
    for (var i = 0; i !== arr.length; i++) {
      p.total++;
      if (arr[i].urgent) p.urgent++; else p.normal++;
      if (typeof p.byWho[arr[i].who] === 'number') p.byWho[arr[i].who]++;
    }
    return p;
  },

  // The spoken batch summary. In speech 我 becomes 你 (the wearer).
  _summaryText() {
    var p = this._piles();
    if (!p.total) {
      return '还没有分拣任何快递。先看一件，扫它的条码，选收件人和类别，再点分拣。';
    }
    var urgParts = [];
    var arr = this._parcels || [];
    for (var i = 0; i !== arr.length; i++) {
      if (arr[i].urgent) {
        urgParts.push((arr[i].who === '我' ? '你' : arr[i].who) + '的' + arr[i].kind);
      }
    }
    var t = '一共' + p.total + '件。急件' + p.urgent + '件';
    if (urgParts.length) t += '：' + urgParts.join('、');
    t += '。普通件' + p.normal + '件。急件放左边先拆，普通件放右边。';
    return t;
  },

  _pileInstruction(entry) {
    var who = entry.who === '我' ? '你' : entry.who;
    if (entry.urgent) {
      return '急件：' + who + '的' + entry.kind + '。放左边急件堆，先拆。';
    }
    return '普通件：' + who + '的' + entry.kind + '。放右边普通堆。';
  },

  // ---------- current-parcel selectors ----------

  whoTap() {
    var whos = this._whos();
    var i = whos.indexOf(this._pending.who);
    this._pending.who = whos[(i + 1) % whos.length];
    this.setData({
      status: 'WHO: ' + this._pending.who + ' (as YOU read on the label)',
      lastEvent: 'EVT: recipient -> ' + this._pending.who + ' (declared by wearer)'
    });
    this._recompute();
  },

  kindTap() {
    var kinds = this._kinds();
    var i = kinds.indexOf(this._pending.kind);
    this._pending.kind = kinds[(i + 1) % kinds.length];
    var auto = false;
    if (this._pending.kind === '食品生鲜' && !this._pending.urgent) {
      // Fresh food spoils: landing on it auto-flags urgency. The wearer
      // can still flip it back with URG - auto only fires on landing.
      this._pending.urgent = true;
      auto = true;
    }
    this.setData({
      status: 'KIND: ' + this._pending.kind + (auto ? ' · auto-flagged 急 (fresh food)' : ''),
      lastEvent: 'EVT: kind -> ' + this._pending.kind + (auto ? ' - urgency auto-on' : '')
    });
    this._recompute();
  },

  urgTap() {
    this._pending.urgent = !this._pending.urgent;
    this.setData({
      status: 'URG: ' + (this._pending.urgent ? '急 - left pile, open first' : '常 - right pile'),
      lastEvent: 'EVT: urgency -> ' + (this._pending.urgent ? '急' : '常')
    });
    this._recompute();
  },

  // ---------- SCAN: wide photo + BarcodeDetector (same as shelf-compare #02) ----------
  // The decoded string is only a record ID for this parcel. There is
  // no carrier database to look it up in, and no OCR: the recipient
  // still comes from the wearer's own eyes on the label.

  scanTap() { this.scanParcel(); },

  async scanParcel() {
    if (this.data.busy) return;
    this._mode = 'SORT';
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this._noCode('SCAN: FAIL - mediaDevices n/a on this host');
      return;
    }
    this.setData({ busy: true, status: 'SCANNING (wide) - aim at the label barcode...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var blob = null;
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        blob = await this._withTimeout(cap.takePhoto({ mode: 'wide' }), 9000, 'wide photo');
      } else {
        throw new Error('ImageCapture n/a');
      }
      await this._decodeAndResolve(blob, 'photo ' + (blob && blob.size ? blob.size : 0) + 'B - mode wide');
    } catch (e) {
      var firstErr = e;
      this._stopStream();
      // Fallback: wx camera context, like gaze-translate / shelf-compare.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        // media.md: wrap the wx encoded data with its mimeType before
        // barcode detection.
        var wxBlob = new Blob([res.data], { type: res.mimeType || 'image/jpeg' });
        await this._decodeAndResolve(wxBlob, 'wx photo ' + size + 'B (ImageCapture fallback)');
      } catch (e2) {
        this._noCode('SCAN: FAIL - ' + this._err(firstErr));
      }
    } finally {
      this._stopStream();
      this.setData({ busy: false });
    }
  },

  _stopStream() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  // No code could be decoded: the parcel is NOT blocked - it will be
  // committed under a sequential batch label and its photo was the
  // record. Never pretend a decode happened.
  _noCode(note) {
    this._pending.code = null;
    this._pending.noCode = true;
    this.setData({
      status: note + ' - parcel gets label ' + this._nextLabel(),
      lastEvent: 'EVT: no code decoded - sequential label ' + this._nextLabel() + ' on SORT'
    });
    this._recompute();
  },

  async _decodeAndResolve(blob, photoNote) {
    if (typeof BarcodeDetector === 'undefined') {
      this._noCode('SCAN: BarcodeDetector n/a on this host (' + photoNote + ')');
      return;
    }
    var detector = new BarcodeDetector();
    var results = await this._withTimeout(detector.detect(blob), 9000, 'barcode detect');
    if (!results || !results.length) {
      this._noCode('SCAN: no barcode found in ' + photoNote);
      return;
    }
    var first = results[0];
    var code = String(first.rawValue || '');
    if (!code) {
      this._noCode('SCAN: barcode decoded empty in ' + photoNote);
      return;
    }
    this._pending.code = code.slice(0, 40);
    this._pending.noCode = false;
    this.setData({
      status: 'CODE: ' + this._pending.code + ' - now pick WHO / KIND, tap SORT',
      lastEvent: 'EVT: code recorded verbatim (' + (first.format || 'barcode') + ') - ID only, not looked up'
    });
    this._recompute();
  },

  // ---------- SORT: commit the current parcel ----------

  sortTap() {
    if (this._mode !== 'SORT') {
      this.setData({ lastEvent: 'EVT: SORT is in SORT mode - tap LIST to toggle back' });
      return;
    }
    var now = this._nowParts();
    var entry = {
      code: this._pending.code ? this._pending.code : this._nextLabel(),
      who: this._pending.who,
      kind: this._pending.kind,
      urgent: !!this._pending.urgent,
      date: now.date,
      time: now.time,
      demo: !!this._demo
    };
    this._addParcel(entry);
    var instr = this._pileInstruction(entry);
    // Next parcel: keep the recipient (a pile often shares one), reset
    // code / kind / urgency so nothing stale carries over.
    var keepWho = this._pending.who;
    this._pending = this._freshPending();
    this._pending.who = keepWho;
    this.setData({
      status: (entry.urgent ? '急件堆（左）: ' : '普通堆（右）: ') + entry.who + ' · ' + entry.kind + ' · ' + entry.code,
      lastEvent: 'EVT: sorted ' + entry.code + ' -> ' + (entry.urgent ? 'LEFT urgent pile' : 'RIGHT normal pile')
    });
    this._recompute();
    this._speakText(instr);
  },

  // ---------- LIST mode ----------

  listTap() {
    this._mode = this._mode === 'LIST' ? 'SORT' : 'LIST';
    this.setData({
      status: this._mode === 'LIST'
        ? 'LIST: urgent first - SPEAK reads the batch summary'
        : 'SORT: look at the next parcel',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  // ---------- CLEAR: the batch is per delivery pile ----------

  clearTap() {
    this._parcels = [];
    this._pending = this._freshPending();
    this._demo = false;
    this._mode = 'SORT';
    this._saveParcels();
    this.setData({
      status: 'BATCH CLEARED - a batch is one delivery pile',
      lastEvent: 'EVT: batch cleared (parcels are sorted per delivery batch)'
    });
    this._recompute();
  },

  // ---------- DEMO ----------

  // DEMO sorts three parcels from ONE clock snapshot, all date/time
  // strings derived as pure strings from that single snapshot, and
  // lands on LIST with the piles summary. Demo entries are tagged
  // and replaced (not piled up) on re-entry.
  demoTap() {
    this._demo = true;
    this._parcels = (this._parcels || []).filter(function (e) { return !e.demo; });
    var snap = this._nowParts();
    var seeds = [
      { code: 'DEMO-1', who: '我', kind: '文件', urgent: true },
      { code: 'DEMO-2', who: '孩子', kind: '食品生鲜', urgent: true },
      { code: 'DEMO-3', who: '配偶', kind: '衣物', urgent: false }
    ];
    for (var i = 0; i !== seeds.length; i++) {
      this._addParcel({
        code: seeds[i].code, who: seeds[i].who, kind: seeds[i].kind,
        urgent: seeds[i].urgent, date: snap.date, time: snap.time, demo: true
      });
    }
    this._pending = this._freshPending();
    this._mode = 'LIST';
    this.setData({
      status: 'DEMO: 3 parcels sorted - piles summary below',
      lastEvent: 'EVT: DEMO seeded 3 parcels (one snapshot) - LIST view'
    });
    this._recompute();
  },

  // ---------- recompute view ----------

  _recompute() {
    var p = this._piles();
    var pn = this._pending;
    var codeTxt;
    if (pn.code) {
      codeTxt = 'CODE: ' + pn.code + ' (verbatim - ID only)';
    } else if (pn.noCode) {
      codeTxt = 'CODE: none decoded - will be ' + this._nextLabel();
    } else {
      codeTxt = 'CODE: --- · SCAN wide barcode (record ID only)';
    }
    var patch = {
      modeText: 'MODE: ' + this._mode,
      codeLine: codeTxt,
      whoLine: 'WHO: ' + pn.who + ' · tap WHO - you read the label, it cannot',
      kindLine: 'KIND: ' + pn.kind + ' · tap KIND',
      urgLine: 'URG: ' + (pn.urgent ? '急 - LEFT pile, open first' : '常 - RIGHT pile') + ' · tap URG to flip',
      pilesLine: 'PILES: 急件 ' + p.urgent + ' · 普通 ' + p.normal + ' · 共 ' + p.total + ' 件',
      countText: 'SORTED: ' + p.total + '/30'
    };
    var byParts = [];
    var whos = this._whos();
    for (var w = 0; w !== whos.length; w++) byParts.push(whos[w] + ' ' + p.byWho[whos[w]]);
    patch.byLine = byParts.join(' · ');

    var rows = [];
    var arr = (this._parcels || []).slice();
    if (this._mode === 'LIST') {
      // Urgent first, stable within each group (insertion order kept).
      arr.sort(function (a, b) {
        return (b.urgent ? 1 : 0) - (a.urgent ? 1 : 0);
      });
    }
    for (var i = 0; i !== arr.length; i++) {
      var e = arr[i];
      var code = e.code.length > 18 ? e.code.slice(0, 18) + '…' : e.code;
      rows.push({
        text: (e.urgent ? '急' : '常') + ' · ' + e.who + ' · ' + e.kind + ' · ' +
          code + ' · ' + e.time + (e.demo ? ' DEMO' : '')
      });
    }
    if (!rows.length) {
      rows.push({ text: '(nothing sorted yet - SCAN a parcel, then SORT)' });
    }
    patch.rows = rows;
    this._lastSpeak = { text: this._summaryText() };
    this.setData(patch);
  },

  // ---------- speech ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    var s = this._lastSpeak;
    var text = s ? s.text : this._summaryText();
    if (this._speakText(text)) {
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">PARCEL SORT</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} · {{modeText}} · {{countText}}</text>
    </view>
    <view class="parcel-box">
      <text class="box-label">◎ CURRENT PARCEL - LOOK AT ITS LABEL</text>
      <text class="line">{{codeLine}}</text>
      <text class="line">{{whoLine}}</text>
      <text class="line">{{kindLine}}</text>
      <text class="line">{{urgLine}}</text>
    </view>
    <view class="piles-box">
      <text class="line">{{pilesLine}}</text>
      <text class="dim">{{byLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <view class="actions">
      <button class="btn btn-main" bindtap="scanTap">SCAN</button>
      <button class="btn" bindtap="whoTap">WHO</button>
      <button class="btn" bindtap="kindTap">KIND</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="urgTap">URG</button>
      <button class="btn btn-main" bindtap="sortTap">SORT</button>
      <button class="btn" bindtap="listTap">LIST</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 8px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.parcel-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.piles-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.line {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
}
.dim {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
}
.list {
  height: 34px;
  margin-bottom: 3px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.rtext {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 3px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 4px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
