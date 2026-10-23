<script def>
{
  "navigationBarTitleText": "Shelf Compare"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT A PRODUCT - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still to confirm gaze',
    countText: 'IN TABLE: 0/4',
    pendingText: 'PENDING: none - SCAN a shelf item or tap DEMO',
    scanLine: 'SCAN: not scanned yet - MODE: wide (barcode)',
    rows: [
      { name: '(table empty)', detail: 'SCAN a barcode or tap DEMO to add items', bestText: '', cls: 'row' }
    ],
    verdictText: 'VERDICT: -',
    lastEvent: 'EVT: nod when steady = scan / confirm add',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._products = [];
    this._pending = null;
    this._demoIdx = 0;
    this._steady = false;
    this.setData({ lastEvent: 'EVT: look at a shelf product and hold your head still' });
  },

  onUnload() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({
        steadyText: 'HEAD STEADY - ready',
        status: this._pending ? 'HEAD STEADY - nod to ADD pending item' : 'HEAD STEADY - nod or tap SCAN'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still to confirm gaze',
        status: 'LOOK AT A PRODUCT - HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g === 'nod') {
      if (this._pending) {
        this.addPending();
      } else if (this._steady) {
        this.scanItem();
      } else {
        this.setData({ status: 'NOD IGNORED - hold head steady first' });
      }
    } else if (g.indexOf('shake') !== -1) {
      this.clearTable();
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._pending) this.addPending(); else this.scanItem();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'Enter') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  // Built-in DEMO catalog (sample data for the prototype, labeled as such
  // in the UI and README). Keyed by EAN-13 barcode. amt is grams or ml,
  // unit price is computed per 100g / 100ml.
  _catalog() {
    return {
      '6901028075831': { name: '全脂牛奶', price: 15.90, amt: 1000, unit: 'ml' },
      '6901028075848': { name: '低脂牛奶', price: 13.90, amt: 1000, unit: 'ml' },
      '6901028075855': { name: '有机牛奶', price: 24.80, amt: 946, unit: 'ml' },
      '6901028075862': { name: '脱脂牛奶', price: 12.50, amt: 1000, unit: 'ml' },
      '6917878000949': { name: '矿泉水', price: 2.00, amt: 550, unit: 'ml' },
      '6925303718238': { name: '橙汁', price: 11.90, amt: 900, unit: 'ml' },
      '6907992512288': { name: '可乐', price: 3.50, amt: 500, unit: 'ml' },
      '6923450657219': { name: '洗洁精', price: 12.80, amt: 500, unit: 'ml' },
      '6902083881405': { name: '洗衣液', price: 39.90, amt: 2000, unit: 'g' },
      '4902430731010': { name: '洗发水', price: 45.00, amt: 450, unit: 'ml' }
    };
  },

  _demoCodes() {
    // DEMO cycles through the four milks so the unit-price comparison
    // in the preview is apples-to-apples.
    return ['6901028075831', '6901028075848', '6901028075855', '6901028075862'];
  },

  _unitPrice(p) {
    if (!p || p.price === null || p.price === undefined || !p.amt) return null;
    return p.price / (p.amt / 100);
  },

  _findInTable(code) {
    for (var i = 0; i !== this._products.length; i++) {
      if (this._products[i].code === code) return true;
    }
    return false;
  },

  _setPending(p, note) {
    this._pending = p;
    var unit = this._unitPrice(p);
    var desc;
    if (unit !== null) {
      desc = p.name + ' - ¥' + p.price.toFixed(2) + ' / ' + p.amt + p.unit +
        ' - ¥' + unit.toFixed(2) + '/100' + p.unit;
    } else {
      desc = p.name + ' - code ' + p.code + ' - price/size unknown';
    }
    this.setData({
      pendingText: 'PENDING: ' + desc,
      status: 'PENDING - nod or tap ADD to confirm',
      lastEvent: 'EVT: ' + (note || 'item pending')
    });
  },

  _renderTable() {
    var products = this._products;
    var best = null;
    var knownCount = 0;
    for (var i = 0; i !== products.length; i++) {
      var u = this._unitPrice(products[i]);
      if (u !== null) {
        knownCount++;
        if (!best || best.unit > u) best = { idx: i, unit: u, p: products[i] };
      }
    }
    var rows = [];
    for (var j = 0; j !== products.length; j++) {
      var p = products[j];
      var up = this._unitPrice(p);
      var isBest = best !== null && knownCount >= 2 && best.idx === j;
      rows.push({
        name: p.name,
        detail: up !== null
          ? '¥' + p.price.toFixed(2) + ' - ' + p.amt + p.unit + ' - ¥' + up.toFixed(2) + '/100' + p.unit
          : 'code ' + p.code + ' - price unknown',
        bestText: isBest ? 'BEST' : '',
        cls: isBest ? 'row row-best' : 'row'
      });
    }
    if (!rows.length) {
      rows.push({ name: '(table empty)', detail: 'SCAN a barcode or tap DEMO to add items', bestText: '', cls: 'row' });
    }
    var verdict;
    if (best && knownCount >= 2) {
      verdict = 'VERDICT: BEST VALUE - ' + best.p.name + ' ¥' + best.unit.toFixed(2) + '/100' + best.p.unit;
    } else if (knownCount === 1) {
      verdict = 'VERDICT: add one more priced item to compare';
    } else if (products.length) {
      verdict = 'VERDICT: no priced items - unit price n/a';
    } else {
      verdict = 'VERDICT: -';
    }
    this._best = best;
    this.setData({
      rows: rows,
      verdictText: verdict,
      countText: 'IN TABLE: ' + products.length + '/4'
    });
  },

  addPending() {
    if (!this._pending) {
      this.setData({ status: 'NOTHING PENDING - SCAN or DEMO first' });
      return;
    }
    if (this._products.length >= 4) {
      this.setData({ status: 'TABLE FULL (4) - REMOVE or CLEAR first' });
      return;
    }
    if (this._findInTable(this._pending.code)) {
      this.setData({
        status: 'ALREADY IN TABLE - ' + this._pending.name,
        pendingText: 'PENDING: none - SCAN a shelf item or tap DEMO'
      });
      this._pending = null;
      return;
    }
    var added = this._pending;
    this._products.push(added);
    this._pending = null;
    this._renderTable();
    this.setData({
      pendingText: 'PENDING: none - SCAN a shelf item or tap DEMO',
      status: 'ADDED: ' + added.name,
      lastEvent: 'EVT: added ' + added.name + ' to the table'
    });
  },

  addTap() { this.addPending(); },

  removeTap() {
    if (!this._products.length) {
      this.setData({ status: 'TABLE ALREADY EMPTY' });
      return;
    }
    var removed = this._products.pop();
    this._renderTable();
    this.setData({
      status: 'REMOVED: ' + removed.name,
      lastEvent: 'EVT: removed last row ' + removed.name
    });
  },

  clearTable() {
    this._products = [];
    this._pending = null;
    this._renderTable();
    this.setData({
      pendingText: 'PENDING: none - SCAN a shelf item or tap DEMO',
      scanLine: 'SCAN: not scanned yet - MODE: wide (barcode)',
      status: 'TABLE CLEARED',
      lastEvent: 'EVT: table cleared'
    });
  },

  clearTap() { this.clearTable(); },

  demoTap() {
    if (this.data.busy) return;
    if (this._products.length >= 4) {
      this.setData({ status: 'TABLE FULL (4) - REMOVE or CLEAR first' });
      return;
    }
    var codes = this._demoCodes();
    var catalog = this._catalog();
    var picked = null;
    for (var k = 0; k !== codes.length; k++) {
      var code = codes[(this._demoIdx + k) % codes.length];
      if (!this._findInTable(code) && !(this._pending && this._pending.code === code)) {
        picked = code;
        this._demoIdx = (this._demoIdx + k + 1) % codes.length;
        break;
      }
    }
    if (!picked) {
      this.setData({ status: 'DEMO: all demo items already in table' });
      return;
    }
    var item = catalog[picked];
    this._setPending(
      { code: picked, name: item.name, price: item.price, amt: item.amt, unit: item.unit },
      'DEMO item (built-in catalog sample, no camera used)');
    this.setData({ scanLine: 'SCAN: DEMO sample - code ' + picked + ' (no camera used)' });
  },

  scanTap() { this.scanItem(); },

  async scanItem() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        scanLine: 'SCAN: FAIL - mediaDevices n/a on this host',
        status: 'SCAN FAIL - no camera on this host, nothing scanned',
        lastEvent: 'EVT: scan FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'SCANNING (wide) - aim at the barcode...' });
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
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate.
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
        this.setData({
          scanLine: 'SCAN: FAIL - ' + this._err(firstErr),
          status: 'SCAN FAIL - no barcode decoded',
          lastEvent: 'EVT: scan FAIL'
        });
      }
    } finally {
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
  },

  async _decodeAndResolve(blob, photoNote) {
    if (typeof BarcodeDetector === 'undefined') {
      this.setData({
        scanLine: 'SCAN: FAIL - BarcodeDetector n/a on this host (' + photoNote + ')',
        status: 'SCAN FAIL - barcode detector unavailable, nothing decoded',
        lastEvent: 'EVT: scan FAIL (no BarcodeDetector)'
      });
      return;
    }
    var detector = new BarcodeDetector();
    var results = await this._withTimeout(detector.detect(blob), 9000, 'barcode detect');
    if (!results || !results.length) {
      this.setData({
        scanLine: 'SCAN: no barcode found in ' + photoNote,
        status: 'SCAN: NO BARCODE - aim at the barcode and retry',
        lastEvent: 'EVT: scan found no barcode'
      });
      return;
    }
    var first = results[0];
    var code = String(first.rawValue || '');
    var format = first.format || 'barcode';
    this.setData({ scanLine: 'SCAN: ' + format + ' ' + code + ' - ' + photoNote });
    var hit = this._catalog()[code];
    if (hit) {
      this._setPending(
        { code: code, name: hit.name, price: hit.price, amt: hit.amt, unit: hit.unit },
        'catalog match (built-in demo catalog) for ' + code);
    } else {
      // Unknown code: joins as an honestly labeled unknown item; it has no
      // price/size, so it is excluded from unit-price comparison.
      this._setPending(
        { code: code, name: 'Unknown item', price: null, amt: 0, unit: 'ml' },
        'unknown code ' + code + ' (not in built-in catalog)');
    }
  },

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var best = this._best;
      if (!best || !best.p) {
        this.setData({ lastEvent: 'EVT: nothing to speak yet - add 2+ priced items first' });
        return;
      }
      var unitWord = best.p.unit === 'g' ? 'grams' : 'millilitres';
      var text = 'Best value: ' + best.p.name + ', at ' + best.unit.toFixed(2) +
        ' yuan per 100 ' + unitWord + '.';
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - listen for the verdict' });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">SHELF COMPARE</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{countText}}</text>
    </view>
    <view class="pending-box">
      <text class="pending-label">◎ LOOKED-AT ITEM - WIDE SCAN</text>
      <text class="pending">{{pendingText}}</text>
      <text class="scan">{{scanLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="scanTap">SCAN</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="addTap">ADD</button>
    </view>
    <view class="table-head">
      <text class="table-title">COMPARISON - UNIT PRICE PER 100g / 100ml</text>
    </view>
    <view ink:for="{{rows}}" class="{{item.cls}}">
      <text class="rname">{{item.name}}</text>
      <text class="rdetail">{{item.detail}}</text>
      <text class="rbest">{{item.bestText}}</text>
    </view>
    <text class="verdict">{{verdictText}}</text>
    <view class="actions">
      <button class="btn" bindtap="removeTap">REMOVE</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 12px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 8px;
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
.pending-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 6px 10px;
  margin-bottom: 8px;
}
.pending-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.pending {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 2px;
}
.scan {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 8px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 5px;
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
.table-head {
  display: flex;
  flex-direction: column;
  margin-bottom: 2px;
}
.table-title {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.row {
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.row-best {
  background-color: rgba(64,255,94,0.12);
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 16px;
  margin-right: 8px;
}
.rdetail {
  flex-grow: 1;
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.rbest {
  color: #40ff5e;
  font-size: 11px;
  font-weight: 500;
  line-height: 15px;
}
.verdict {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
  margin-top: 4px;
  margin-bottom: 6px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 4px;
}
</style>
