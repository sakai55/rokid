<script def>
{
  "navigationBarTitleText": "Expiry Check"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT A PACKAGE - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    countText: 'LIST: 0/6 - URGENT<=3d: 0',
    photoLine: 'PHOTO: not taken yet - MODE: telephoto (date area)',
    dateText: 'EXPIRY: ----/--/--',
    nameText: 'NAME: 牛奶 (tap NAME - ASR zh-CN)',
    rows: [
      { name: '(empty)', detail: 'LOOK, confirm date, ADD - or DEMO', flag: '', cls: 'row' }
    ],
    summaryText: 'URGENT: none',
    lastEvent: 'EVT: nod when steady = LOOK, nod again = ADD',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._items = this._loadItems();
    this._steady = false;
    this._armed = false; // a LOOK was attempted for the current item
    this._nameIdx = 0;
    this._demoIdx = 0;
    this._fieldIdx = 1; // stepper focus: 0=year 1=month 2=day
    var now = new Date();
    this._date = { y: now.getFullYear(), m: now.getMonth() + 1, d: now.getDate() };
    this._renderAll();
    this.setData({ lastEvent: 'EVT: look at the package date area and hold your head still' });
  },

  onUnload() {
    if (this._recog) { try { this._recog.abort(); } catch (e) {} this._recog = null; }
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
    this._saveItems();
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({
        steadyText: 'HEAD STEADY - ready',
        status: this._armed ? 'HEAD STEADY - nod to ADD this item' : 'HEAD STEADY - nod or tap LOOK'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still',
        status: 'LOOK AT A PACKAGE - HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g === 'nod') {
      if (this._armed) {
        this.addItem();
      } else if (this._steady) {
        this.lookItem();
      } else {
        this.setData({ status: 'NOD IGNORED - hold head steady first' });
      }
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp') {
      this.adjustDate(1);
    } else if (code === 'ArrowDown') {
      this.adjustDate(-1);
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      this.lookItem();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
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

  _pad(n) { return (n < 10 ? '0' : '') + n; },

  _dayNum(y, m, d) {
    return Math.floor(Date.UTC(y, m - 1, d) / 86400000);
  },

  _todayNum() {
    var now = new Date();
    return this._dayNum(now.getFullYear(), now.getMonth() + 1, now.getDate());
  },

  _daysLeft(item) {
    return this._dayNum(item.y, item.m, item.d) - this._todayNum();
  },

  _daysInMonth(y, m) {
    return new Date(Date.UTC(y, m, 0)).getUTCDate();
  },

  _demoNames() {
    return ['牛奶', '鸡蛋', '酸奶', '面包', '剩菜'];
  },

  // Rotating DEMO samples: name + expiry offset in days from today.
  // The first three land at +1 (urgent), +2 (urgent), +5 so the preview
  // shows a sorted list with urgency flags; later ones include an
  // already-expired item to show the EXPIRED flag.
  _demoSamples() {
    return [
      { name: '牛奶', off: 1 },
      { name: '鸡蛋', off: 2 },
      { name: '酸奶', off: 5 },
      { name: '面包', off: 0 },
      { name: '剩菜', off: -1 },
      { name: '果汁', off: 9 }
    ];
  },

  _currentName() {
    return this._demoNames()[this._nameIdx % this._demoNames().length];
  },

  _loadItems() {
    try {
      var raw = wx.getStorageSync('expiryWatchlist');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 6; i++) {
        var it = raw[i];
        if (it && typeof it.name === 'string' && isFinite(it.y) && isFinite(it.m) && isFinite(it.d)) {
          out.push({ name: String(it.name).slice(0, 12), y: it.y | 0, m: it.m | 0, d: it.d | 0 });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveItems() {
    try {
      wx.setStorageSync('expiryWatchlist', this._items || []);
    } catch (e) { /* storage unavailable on this host: list stays in memory */ }
  },

  _sortedItems() {
    var self = this;
    var arr = (this._items || []).slice();
    arr.sort(function (a, b) {
      return self._dayNum(a.y, a.m, a.d) - self._dayNum(b.y, b.m, b.d);
    });
    return arr;
  },

  _renderAll() {
    var sorted = this._sortedItems();
    var rows = [];
    var urgent = 0;
    for (var i = 0; i !== sorted.length; i++) {
      var it = sorted[i];
      var left = this._daysLeft(it);
      var flag = '';
      var cls = 'row';
      if (left < 0) { flag = 'EXPIRED'; cls = 'row row-urgent'; urgent++; }
      else if (left <= 3) { flag = '!'; cls = 'row row-urgent'; urgent++; }
      var when = left < 0 ? ('expired ' + (-left) + 'd ago')
        : left === 0 ? 'expires TODAY'
        : left === 1 ? '1d left'
        : left + 'd left';
      rows.push({
        name: it.name,
        detail: it.y + '-' + this._pad(it.m) + '-' + this._pad(it.d) + ' - ' + when,
        flag: flag,
        cls: cls
      });
    }
    if (!rows.length) {
      rows.push({ name: '(empty)', detail: 'LOOK, confirm date, ADD - or DEMO', flag: '', cls: 'row' });
    }
    // Date stepper display: the focused field is wrapped in [ ].
    var dt = this._date;
    var ys = String(dt.y), ms = this._pad(dt.m), ds = this._pad(dt.d);
    if (this._fieldIdx === 0) ys = '[' + ys + ']';
    else if (this._fieldIdx === 1) ms = '[' + ms + ']';
    else ds = '[' + ds + ']';
    var fields = ['YEAR', 'MONTH', 'DAY'];
    this.setData({
      rows: rows,
      countText: 'LIST: ' + sorted.length + '/6 - URGENT<=3d: ' + urgent,
      summaryText: urgent
        ? 'URGENT: ' + urgent + ' item(s) within 3 days - tap SPEAK to hear them'
        : 'URGENT: none within 3 days',
      dateText: 'EXPIRY: ' + ys + '-' + ms + '-' + ds + ' - FOCUS: ' + fields[this._fieldIdx],
      nameText: this._customName
        ? 'NAME: ' + this._customName + ' (heard via ASR)'
        : 'NAME: ' + this._currentName() + ' (tap NAME - ASR zh-CN)'
    });
    this._urgent = urgent;
    this._sorted = sorted;
  },

  fieldTap() {
    this._fieldIdx = (this._fieldIdx + 1) % 3;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: stepper focus -> ' + ['YEAR', 'MONTH', 'DAY'][this._fieldIdx] });
  },

  adjustDate(step) {
    var dt = this._date;
    var now = new Date();
    if (this._fieldIdx === 0) {
      dt.y += step;
      if (dt.y < now.getFullYear() - 1) dt.y = now.getFullYear() + 5;
      if (dt.y > now.getFullYear() + 5) dt.y = now.getFullYear() - 1;
    } else if (this._fieldIdx === 1) {
      dt.m += step;
      if (dt.m < 1) dt.m = 12;
      if (dt.m > 12) dt.m = 1;
    } else {
      dt.d += step;
      var dim = this._daysInMonth(dt.y, dt.m);
      if (dt.d < 1) dt.d = dim;
      if (dt.d > dim) dt.d = 1;
    }
    var dim2 = this._daysInMonth(dt.y, dt.m);
    if (dt.d > dim2) dt.d = dim2;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: date adjusted with stepper' });
  },

  nameTap() {
    var self = this;
    if (typeof SpeechRecognition === 'undefined') {
      // Honest fallback on hosts without ASR: cycle the built-in names.
      this._nameIdx = (this._nameIdx + 1) % this._demoNames().length;
      this._renderAll();
      this.setData({
        status: 'ASR n/a on this host - DEMO name cycled',
        lastEvent: 'EVT: ASR unavailable, name -> ' + this._currentName()
      });
      return;
    }
    try {
      if (this._recog) { try { this._recog.abort(); } catch (e) {} }
      var rec = new SpeechRecognition();
      this._recog = rec;
      rec.lang = 'zh-CN';
      rec.interimResults = false;
      rec.onresult = function (ev) {
        try {
          var txt = String(ev.results[ev.resultIndex][0].transcript || '').trim().slice(0, 12);
          if (txt) {
            // Store the spoken name as a one-off custom name.
            self._customName = txt;
            self.setData({
              nameText: 'NAME: ' + txt + ' (heard via ASR - tap NAME to redo)',
              status: 'NAME HEARD: ' + txt,
              lastEvent: 'ASR: ' + txt
            });
          }
        } catch (e) {}
      };
      rec.onerror = function (ev) {
        self.setData({
          status: 'ASR FAIL - ' + self._err(ev.error || ev) + ' (name unchanged)',
          lastEvent: 'EVT: ASR error'
        });
      };
      rec.start();
      this.setData({
        status: 'LISTENING - say the item name (zh-CN)...',
        lastEvent: 'EVT: ASR listening for item name'
      });
    } catch (e) {
      this.setData({
        status: 'ASR FAIL - ' + this._err(e) + ' (name unchanged)',
        lastEvent: 'EVT: ASR start failed'
      });
    }
  },

  _nameForAdd() {
    if (this._customName) return this._customName;
    return this._currentName();
  },

  addItem() {
    if (this._items.length >= 6) {
      this.setData({ status: 'WATCHLIST FULL (6) - REMOVE or CLEAR first' });
      return;
    }
    var item = { name: this._nameForAdd(), y: this._date.y, m: this._date.m, d: this._date.d };
    this._items.push(item);
    this._saveItems();
    this._armed = false;
    this._customName = null;
    var left = this._daysLeft(item);
    this._renderAll();
    this.setData({
      status: 'ADDED: ' + item.name + ' - ' + (left < 0 ? 'already EXPIRED' : left + 'd left'),
      lastEvent: 'EVT: added ' + item.name + ' exp ' + item.y + '-' + this._pad(item.m) + '-' + this._pad(item.d)
    });
  },

  addTap() { this.addItem(); },

  removeTap() {
    if (!this._items.length) {
      this.setData({ status: 'WATCHLIST ALREADY EMPTY' });
      return;
    }
    // REMOVE drops the most urgent item (first in the sorted list).
    var sorted = this._sortedItems();
    var target = sorted[0];
    var idx = this._items.indexOf(target);
    if (idx !== -1) this._items.splice(idx, 1);
    this._saveItems();
    this._renderAll();
    this.setData({
      status: 'REMOVED (most urgent): ' + target.name,
      lastEvent: 'EVT: removed most urgent item ' + target.name
    });
  },

  clearTap() {
    this._items = [];
    this._armed = false;
    this._customName = null;
    this._saveItems();
    this._renderAll();
    this.setData({
      status: 'WATCHLIST CLEARED',
      lastEvent: 'EVT: watchlist cleared'
    });
  },

  demoTap() {
    if (this._items.length >= 6) {
      this.setData({ status: 'WATCHLIST FULL (6) - REMOVE or CLEAR first' });
      return;
    }
    var samples = this._demoSamples();
    var s = samples[this._demoIdx % samples.length];
    this._demoIdx++;
    var base = new Date();
    base.setDate(base.getDate() + s.off);
    var item = { name: s.name + '(样例)', y: base.getFullYear(), m: base.getMonth() + 1, d: base.getDate() };
    this._items.push(item);
    this._saveItems();
    this._renderAll();
    this.setData({
      photoLine: 'PHOTO: DEMO sample item (no camera used)',
      status: 'DEMO ADDED: ' + item.name + ' - ' + this._daysLeft(item) + 'd left',
      lastEvent: 'EVT: DEMO sample added (built-in, no camera/ASR used)'
    });
  },

  lookTap() { this.lookItem(); },

  async lookItem() {
    if (this.data.busy) return;
    this._armed = true;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host',
        status: 'LOOK FAIL - no camera here; the date below is user-confirmed (no OCR) - set it and ADD',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto) - aim at the date area...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var photoBytes = 0;
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B - mode telephoto (date area) - date is NOT read from the photo',
        status: 'PHOTO OK - confirm the expiry date with the stepper (user-confirmed, no OCR), then ADD or nod',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B, awaiting date confirmation'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / shelf-compare.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - date is NOT read from the photo',
          status: 'PHOTO OK - confirm the expiry date with the stepper (user-confirmed, no OCR), then ADD or nod',
          lastEvent: 'EVT: wx photo ' + size + 'B, awaiting date confirmation'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr),
          status: 'LOOK FAIL - no photo taken; the date below is user-confirmed (no OCR) - set it and ADD',
          lastEvent: 'EVT: LOOK FAIL'
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

  _speakSummary() {
    var sorted = this._sortedItems();
    var urgentList = [];
    for (var i = 0; i !== sorted.length; i++) {
      if (this._daysLeft(sorted[i]) <= 3) urgentList.push(sorted[i]);
    }
    if (!sorted.length) return '临期清单是空的。';
    if (!urgentList.length) return '临期清单共 ' + sorted.length + ' 项，3 天内没有要到期的。';
    var parts = [];
    for (var j = 0; j !== urgentList.length; j++) {
      var it = urgentList[j];
      var left = this._daysLeft(it);
      var when = left < 0 ? '已过期 ' + (-left) + ' 天'
        : left === 0 ? '今天到期'
        : left === 1 ? '明天到期'
        : '还有 ' + left + ' 天到期';
      parts.push(it.name + when);
    }
    return '临期提醒：' + urgentList.length + ' 项在 3 天内到期。' + parts.join('；') + '。';
  },

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text = this._speakSummary();
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - ' + text.slice(0, 40) });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">EXPIRY CHECK</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{countText}}</text>
    </view>
    <view class="confirm-box">
      <text class="box-label">◎ LOOKED-AT PACKAGE - CONFIRM DATE (user-confirmed, no OCR)</text>
      <text class="photo">{{photoLine}}</text>
      <text class="date">{{dateText}}</text>
      <text class="photo">{{nameText}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="fieldTap">FIELD</button>
      <button class="btn" bindtap="nameTap">NAME</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="addTap">ADD</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="list-head">
      <text class="list-title">WATCHLIST - SOONEST FIRST (URGENT = !)</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <view class="actions">
      <button class="btn" bindtap="removeTap">REMOVE (most urgent)</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </view>
    <text class="summary">{{summaryText}}</text>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 6px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: 500;
  line-height: 24px;
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
.confirm-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 8px;
  margin-bottom: 5px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
.date {
  color: #40ff5e;
  font-size: 14px;
  line-height: 19px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 4px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 2px;
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
.list-head {
  display: flex;
  flex-direction: column;
  margin-bottom: 2px;
}
.list-title {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.list {
  height: 60px;
  margin-top: 9px;
  margin-bottom: 5px;
}
.row {
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.row-urgent {
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
.rflag {
  color: #40ff5e;
  font-size: 11px;
  font-weight: 500;
  line-height: 15px;
}
.summary {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
</style>
