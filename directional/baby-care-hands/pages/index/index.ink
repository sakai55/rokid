<script def>
{
  "navigationBarTitleText": "Baby Care Hands"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOG: pick EVT, nod or LOG - hands stay on baby',
    steadyText: 'HEAD: moving - hold still',
    feedLine: 'LAST FEED: no feed logged yet',
    sleepLine: 'LAST SLEEP: ---',
    todayLine: 'TODAY: feeds 0 · diapers 0',
    nextLine: 'NEXT FEED: --- (ESTIMATE ONLY)',
    selLine: 'EVT: 喂奶 · EVERY: 每 3 小时',
    rows: [
      { text: '(no entries) - LOG one, or DEMO' }
    ],
    countLine: 'LOG: 0/30 · stored on this device only',
    lastEvent: 'EVT: nod when steady = LOG the picked event',
    busy: false
  },

  onLoad() {
    this._evtIdx = 0;
    this._everyIdx = 1; // intervals [2,3,4] hours, default 3
    this._entries = this._loadLog();
    this._steady = false;
    this._timer = null;
    this._speakText = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startTimer();
    this._recompute();
  },

  onShow() {
    this._startTimer();
    this._recompute();
  },

  onHide() {
    this._stopTimer();
  },

  onUnload() {
    this._stopTimer();
    this._saveLog();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Both arms are holding the baby: a steady nod stamps the event.
    this.logTap();
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.evtTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      this.logTap();
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
    return String(e.message || e.name || e).slice(0, 60);
  },

  _startTimer() {
    if (this._timer) return;
    var self = this;
    // Refresh the "x ago" lines while the page stays open.
    this._timer = setInterval(function () { self._recompute(); }, 5000);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- vocab ----------

  _events() { return ['喂奶', '换尿布', '开始睡', '醒了']; },
  _evt() { return this._events()[this._evtIdx || 0]; },
  _everyHours() { return [2, 3, 4][this._everyIdx || 0]; },

  // ---------- time math (pure; same code sanity-checked in Node) ----------

  _fmtHM(ts) {
    var d = new Date(ts);
    var h = d.getHours(); if (h < 10) h = '0' + h;
    var m = d.getMinutes(); if (m < 10) m = '0' + m;
    return h + ':' + m;
  },

  _isToday(ts, now) {
    var a = new Date(ts), b = new Date(now);
    return a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  },

  // '2h 10m' / '45m' / '3h 0m'
  _fmtElapsed(ms) {
    if (ms < 0) ms = 0;
    var mins = Math.floor(ms / 60000);
    var h = Math.floor(mins / 60);
    var m = mins % 60;
    return h > 0 ? h + 'h ' + m + 'm' : m + 'm';
  },

  // '2小时10分钟' / '45分钟' / '3小时'
  _fmtElapsedCn(ms) {
    if (ms < 0) ms = 0;
    var mins = Math.floor(ms / 60000);
    var h = Math.floor(mins / 60);
    var m = mins % 60;
    if (h > 0) return m > 0 ? h + '小时' + m + '分钟' : h + '小时';
    return m + '分钟';
  },

  _lastOf(entries, evt) {
    for (var i = entries.length - 1; i >= 0; i--) {
      if (entries[i].evt === evt) return entries[i];
    }
    return null;
  },

  // Last completed sleep (开始睡 -> 醒了 pair), or "sleeping now".
  _sleepInfo(entries) {
    var lastSleep = -1, lastWake = -1;
    for (var i = 0; i !== entries.length; i++) {
      if (entries[i].evt === '开始睡') lastSleep = i;
      if (entries[i].evt === '醒了') lastWake = i;
    }
    if (lastSleep < 0 && lastWake < 0) return null;
    if (lastSleep > lastWake) {
      return { type: 'sleeping', sinceTs: entries[lastSleep].ts };
    }
    // Find the 开始睡 that pairs with the last 醒了 (latest one before it).
    var start = -1;
    for (var j = 0; j !== lastWake; j++) {
      if (entries[j].evt === '开始睡') start = j;
    }
    if (start < 0) return null;
    return { type: 'done', ms: entries[lastWake].ts - entries[start].ts, wakeTs: entries[lastWake].ts };
  },

  _todayCounts(entries, now) {
    var feeds = 0, diapers = 0;
    for (var i = 0; i !== entries.length; i++) {
      if (!this._isToday(entries[i].ts, now)) continue;
      if (entries[i].evt === '喂奶') feeds++;
      else if (entries[i].evt === '换尿布') diapers++;
    }
    return { feeds: feeds, diapers: diapers };
  },

  _nextFeedTs(entries, hours) {
    var f = this._lastOf(entries, '喂奶');
    return f ? f.ts + hours * 3600000 : null;
  },

  // ---------- persistence (wx sync storage, key 'babyLog') ----------

  _loadLog() {
    try {
      var raw = wx.getStorageSync('babyLog');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var evts = this._events();
      var out = [];
      for (var i = 0; i !== raw.length; i++) {
        var r = raw[i];
        if (r && evts.indexOf(r.evt) >= 0 && isFinite(r.ts)) {
          out.push({ evt: r.evt, ts: +r.ts, demo: !!r.demo });
        }
      }
      out.sort(function (a, b) { return a.ts - b.ts; });
      while (out.length > 30) out.shift();
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveLog() {
    try {
      wx.setStorageSync('babyLog', this._entries || []);
    } catch (e) { /* storage unavailable on this host: log stays in memory */ }
  },

  _addEntry(evt, demo) {
    var now = Date.now();
    this._entries.push({ evt: evt, ts: now, demo: !!demo });
    while (this._entries.length > 30) this._entries.shift();
    this._saveLog();
    return now;
  },

  // ---------- actions ----------

  evtTap() {
    this._evtIdx = ((this._evtIdx || 0) + 1) % this._events().length;
    this.setData({ lastEvent: 'EVT: event -> ' + this._evt() });
    this._recompute();
  },

  everyTap() {
    this._everyIdx = ((this._everyIdx || 0) + 1) % 3;
    this.setData({ lastEvent: 'EVT: feed interval -> 每 ' + this._everyHours() + ' 小时（仅估算）' });
    this._recompute();
  },

  logTap() {
    var evt = this._evt();
    var ts = this._addEntry(evt, false);
    this.setData({
      status: 'LOGGED: ' + evt + ' · ' + this._fmtHM(ts),
      lastEvent: 'EVT: logged ' + evt + ' at ' + this._fmtHM(ts)
    });
    this._recompute();
  },

  clearTap() {
    this._entries = [];
    this._saveLog();
    this.setData({
      status: 'LOG: pick EVT, nod or LOG - hands stay on baby',
      lastEvent: 'EVT: log cleared'
    });
    this._recompute();
  },

  // ---------- demo ----------

  demoTap() {
    // Seed a plausible log for today, computed from Date.now() so the
    // summary math is real: last feed 2h10m ago, one completed sleep
    // of 1h20m (开始睡 4h50m ago -> 醒了 3h30m ago), plus earlier
    // feeds and diaper changes. Old demo entries are replaced.
    var now = Date.now();
    var keep = (this._entries || []).filter(function (e) { return !e.demo; });
    var seeds = [
      { evt: '喂奶', agoMin: 390 },
      { evt: '换尿布', agoMin: 380 },
      { evt: '开始睡', agoMin: 290 },
      { evt: '醒了', agoMin: 210 },
      { evt: '喂奶', agoMin: 200 },
      { evt: '换尿布', agoMin: 185 },
      { evt: '喂奶', agoMin: 130 },
      { evt: '换尿布', agoMin: 75 }
    ];
    for (var i = 0; i !== seeds.length; i++) {
      keep.push({ evt: seeds[i].evt, ts: now - seeds[i].agoMin * 60000, demo: true });
    }
    keep.sort(function (a, b) { return a.ts - b.ts; });
    while (keep.length > 30) keep.shift();
    this._entries = keep;
    this._saveLog();
    this.setData({
      status: 'DEMO: seeded log - last feed 2h10m ago',
      lastEvent: 'EVT: DEMO on - 8 sample entries from Date.now()'
    });
    this._recompute();
  },

  // ---------- summary ----------

  _recompute() {
    var now = Date.now();
    var entries = this._entries || [];
    var patch = {
      selLine: 'EVT: ' + this._evt() + ' · EVERY: 每 ' + this._everyHours() + ' 小时'
    };

    var lastFeed = this._lastOf(entries, '喂奶');
    patch.feedLine = lastFeed
      ? 'LAST FEED: ' + this._fmtHM(lastFeed.ts) + ' · ' + this._fmtElapsed(now - lastFeed.ts) + ' ago'
      : 'LAST FEED: no feed logged yet';

    var si = this._sleepInfo(entries);
    if (!si) patch.sleepLine = 'LAST SLEEP: ---';
    else if (si.type === 'sleeping') {
      patch.sleepLine = 'SLEEPING NOW: since ' + this._fmtHM(si.sinceTs) +
        ' · ' + this._fmtElapsed(now - si.sinceTs);
    } else {
      patch.sleepLine = 'LAST SLEEP: ' + this._fmtElapsed(si.ms) + ' · woke ' + this._fmtHM(si.wakeTs);
    }

    var c = this._todayCounts(entries, now);
    patch.todayLine = 'TODAY: feeds ' + c.feeds + ' · diapers ' + c.diapers;

    var next = this._nextFeedTs(entries, this._everyHours());
    patch.nextLine = next
      ? 'NEXT FEED ~ ' + this._fmtHM(next) + ' - ESTIMATE ONLY'
      : 'NEXT FEED: --- (ESTIMATE ONLY)';

    if (!entries.length) {
      patch.rows = [{ text: '(no entries) - LOG one, or DEMO' }];
    } else {
      patch.rows = entries.slice().reverse().map(function (e) {
        return { text: this._fmtHM(e.ts) + ' ' + e.evt + (e.demo ? ' DEMO' : '') };
      }, this);
    }
    patch.countLine = 'LOG: ' + entries.length + '/30 · stored on this device only';

    // Chinese summary for SPEAK
    var parts = [];
    parts.push(lastFeed
      ? '上次喂奶是' + this._fmtElapsedCn(now - lastFeed.ts) + '前。'
      : '还没有喂奶记录。');
    if (si) {
      parts.push(si.type === 'sleeping'
        ? '宝宝正在睡，从' + this._fmtHM(si.sinceTs) + '睡到现在。'
        : '上次睡了' + this._fmtElapsedCn(si.ms) + '。');
    }
    parts.push('今天喂了' + c.feeds + '次，换了' + c.diapers + '次尿布。');
    this._speakText = parts.join('');

    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text = this._speakText || '还没有记录。先选事件，点记录，或者点一下头。';
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">BABY CARE HANDS</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="sum-box">
      <text class="sum">{{feedLine}}</text>
      <text class="sum">{{sleepLine}}</text>
      <text class="sum">{{todayLine}}</text>
      <text class="sum dim">{{nextLine}}</text>
    </view>
    <text class="sel">{{selLine}}</text>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <text class="count">{{countLine}}</text>
    <view class="actions">
      <button class="btn" bindtap="evtTap">EVT</button>
      <button class="btn" bindtap="everyTap">EVERY</button>
      <button class="btn btn-main" bindtap="logTap">LOG</button>
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
  margin-bottom: 5px;
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
.sum-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 10px;
  margin-bottom: 5px;
}
.sum {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.dim {
  color: rgba(64,255,94,0.72);
}
.sel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 16px;
  margin-bottom: 4px;
}
.list {
  height: 45px;
  margin-bottom: 2px;
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
.count {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-bottom: 4px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
