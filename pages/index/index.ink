<script def>
{
  "navigationBarTitleText": "Day Lookback"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '白天复盘 — 白天每一次凝视登记一格，晚上按时间+朝向回放成一条注意力时间线',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 登记 — 看向目标停稳，TYPE 选类型、DESC 选一句、DIR 选朝向，MARK 记一格',
    bigLabel: '白天登记 · 待机',
    bigText: '还没记',
    bigNote: '类型 画面 · 描述 路过的店：街角便利店招牌 · 朝向 前方 · MARK 记一格',
    permLine: 'PERM: 无权限 — 凝视登记 + 时间线回放，不拍照、不录音、不定位',
    rows: [],
    countLine: '已记 0 格 · 画面 0 · 数字 0 · 承诺 0 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - register each gaze with MARK, then REPLAY',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'register'; // register | replay | summary
    this._typeList = ['画面', '数字', '承诺'];
    this._typeIdx = 0;
    this._descList = [
      '路过的店：街角便利店招牌',
      '看过的号码：车牌 沪A·12345',
      '答应的事：明天还书给小李',
      '路过的店：花店橱窗',
      '看过的号码：门牌 18 号',
      '答应的事：周五前交报告'
    ];
    this._descIdx = 0;
    this._dirList = ['前方', '左前方', '右前方', '左方', '右方', '后方'];
    this._dirIdx = 0;
    this._filterList = ['全部', '画面', '数字', '承诺'];
    this._filterIdx = 0;
    this._entries = []; // { time, dir, type, desc, demo } — session memory only
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1-3 marked, 4 replay+filter, 5 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the timeline dies with the
    // page. Nothing was ever written anywhere persistent, so
    // there is nothing to clean up — that IS the design. Close
    // the agent and the day is gone, which is the honest price
    // of the zero-persistence rule (see README).
    this._mode = 'register';
    this._typeIdx = 0;
    this._descIdx = 0;
    this._dirIdx = 0;
    this._filterIdx = 0;
    this._entries = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _timeLabel() {
    var d = new Date(this._now());
    var h = String(d.getHours());
    if (h.length < 2) h = '0' + h;
    var m = String(d.getMinutes());
    if (m.length < 2) m = '0' + m;
    return h + ':' + m;
  },

  _type() { return this._typeList[this._typeIdx]; },
  _desc() { return this._descList[this._descIdx]; },
  _dir() { return this._dirList[this._dirIdx]; },
  _filter() { return this._filterList[this._filterIdx]; },

  _visible() {
    var f = this._filter();
    if (f === '全部') return this._entries.slice();
    var out = [];
    var i;
    for (i = 0; i < this._entries.length; i++) {
      if (this._entries[i].type === f) out.push(this._entries[i]);
    }
    return out;
  },

  _counts() {
    var c = { '画面': 0, '数字': 0, '承诺': 0 };
    var i;
    for (i = 0; i < this._entries.length; i++) {
      if (c[this._entries[i].type] !== undefined) c[this._entries[i].type]++;
    }
    return c;
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (only nod is documented)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod marks one
    // entry (register), advances the timeline by one (replay),
    // or confirms the summary. It never changes the type, the
    // description or the direction — those are selections, and
    // a nod must not silently pick one.
    if (this._mode === 'register') { this.markTap(); return; }
    if (this._mode === 'replay') { this.nextTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'register') this.markTap();
      else if (this._mode === 'replay') this.nextTap();
      else if (this._mode === 'summary') this._confirmSummary();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.backTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- selection ----------

  typeTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: TYPE refused - type is chosen while registering, not in replay or summary' });
      return;
    }
    this._typeIdx = (this._typeIdx + 1) % this._typeList.length;
    this.setData({
      status: '类型已选为 ' + this._type() + ' — DESC 选一句、DIR 选朝向、MARK 记一格',
      lastEvent: 'EVT: type set - ' + this._type()
    });
    this._renderAll();
  },

  descTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: DESC refused - description is chosen while registering, not in replay or summary' });
      return;
    }
    this._descIdx = (this._descIdx + 1) % this._descList.length;
    this.setData({
      status: '描述已选为 ' + this._desc() + ' — MARK 记一格',
      lastEvent: 'EVT: description set - ' + this._desc()
    });
    this._renderAll();
  },

  dirTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: DIR refused - direction is chosen while registering, not in replay or summary' });
      return;
    }
    this._dirIdx = (this._dirIdx + 1) % this._dirList.length;
    this.setData({
      status: '朝向已选为 ' + this._dir() + ' — MARK 记一格',
      lastEvent: 'EVT: direction set - ' + this._dir()
    });
    this._renderAll();
  },

  // ---------- register / replay / summary ----------

  markTap() {
    if (this._mode !== 'register') {
      this.setData({ lastEvent: 'EVT: MARK refused - entries are marked while registering, not in replay or summary' });
      return;
    }
    this._entries.push({
      time: this._timeLabel(),
      dir: this._dir(),
      type: this._type(),
      desc: this._desc(),
      demo: this._demo
    });
    this._focus = this._entries.length - 1;
    this.setData({
      status: '已记一格：' + this._type() + ' · ' + this._desc() + '（' + this._dir() + '）— 继续记，或 REPLAY 回放',
      lastEvent: 'EVT: entry marked - ' + this._type() + ' ' + this._desc() + ' (' + this._dir() + ', ' + this._entries[this._entries.length - 1].time + ')'
    });
    this._renderAll();
  },

  replayTap() {
    if (this._mode === 'replay') {
      this.setData({ lastEvent: 'EVT: REPLAY refused - timeline replay is already open' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: REPLAY refused - confirm or go back from the summary first' });
      return;
    }
    if (this._entries.length === 0) {
      this.setData({ lastEvent: 'EVT: REPLAY refused - missing: 至少记一格（MARK）' });
      return;
    }
    this._mode = 'replay';
    this._filterIdx = 0;
    this._focus = 0;
    this.setData({
      status: '时间线回放 — 按时间顺序走，FILTER 按类型过滤，NEXT/PREV 换格',
      lastEvent: 'EVT: replay started (' + this._entries.length + ' entries)'
    });
    this._renderAll();
  },

  filterTap() {
    if (this._mode !== 'replay') {
      this.setData({ lastEvent: 'EVT: FILTER refused - filtering applies to the timeline replay, not while registering or in summary' });
      return;
    }
    this._filterIdx = (this._filterIdx + 1) % this._filterList.length;
    this._focus = 0;
    this.setData({
      status: '过滤已切为 ' + this._filter() + ' — 时间线只列该类型',
      lastEvent: 'EVT: filter set - ' + this._filter()
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the timeline.
      // BACK is the way back to replay without deleting.
      this._confirmSummary();
      return;
    }
    if (this._entries.length === 0) {
      this.setData({ lastEvent: 'EVT: END refused - missing: 至少记一格（MARK）' });
      return;
    }
    this._mode = 'summary';
    var c = this._counts();
    this._summary = {
      total: this._entries.length,
      scene: c['画面'],
      number: c['数字'],
      promise: c['承诺'],
      first: this._entries[0].time,
      last: this._entries[this._entries.length - 1].time
    };
    this.setData({
      status: '本次复盘小结 — 点 END 确认清空，BACK 返回回放',
      lastEvent: 'EVT: day ended - summary ready (total ' + this._entries.length + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'register';
    this._typeIdx = 0;
    this._descIdx = 0;
    this._dirIdx = 0;
    this._filterIdx = 0;
    this._entries = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '白天复盘 — 白天每一次凝视登记一格，晚上按时间+朝向回放成一条注意力时间线',
      lastEvent: 'EVT: summary confirmed - timeline cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to replay without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'replay';
      this._summary = null;
      this.setData({
        status: '时间线回放 — 按时间顺序走，FILTER 按类型过滤，NEXT/PREV 换格',
        lastEvent: 'EVT: back to replay - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'replay') {
      this._mode = 'register';
      this.setData({
        status: '白天登记 — 继续记，或 REPLAY 回放',
        lastEvent: 'EVT: back to registering - entries kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - MARK marks an entry, REPLAY opens the timeline' });
  },

  _focusLen() {
    if (this._mode === 'register') return this._entries.length;
    if (this._mode === 'replay') return this._visible().length;
    return 0;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._focusLen()) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> item ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'register') {
      line = this._entries.length === 0
        ? '还没记：看向目标停稳，MARK 记一格'
        : '已记 ' + this._entries.length + ' 格，继续记或回放';
    } else if (this._mode === 'replay') {
      var vis = this._visible();
      if (vis.length === 0) {
        line = '过滤 ' + this._filter() + ' 下暂无记录';
      } else {
        var cur = vis[this._focus] || vis[0];
        line = cur.time + '，' + cur.dir + '，' + cur.type + '：' + cur.desc;
      }
    } else if (this._summary) {
      line = '本次复盘小结：共 ' + this._summary.total + ' 格，画面 ' + this._summary.scene + ' 格，数字 ' + this._summary.number + ' 格，承诺 ' + this._summary.promise + ' 格';
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'register' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user replay is under way' });
      return;
    }
    if (this._mode === 'register' && !this._demo && this._entries.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user entries are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._typeIdx = 0; // 画面
      this._descIdx = 0; // 路过的店：街角便利店招牌
      this._dirIdx = 0; // 前方
      this.markTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - scene marked (DEMO sample, 1 entry)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._typeIdx = 1; // 数字
      this._descIdx = 1; // 看过的号码：车牌 沪A·12345
      this._dirIdx = 2; // 右前方
      this.markTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - number marked (DEMO sample, 2 entries)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._typeIdx = 2; // 承诺
      this._descIdx = 2; // 答应的事：明天还书给小李
      this._dirIdx = 5; // 后方
      this.markTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - promise marked (DEMO sample, 3 entries)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.replayTap();
      // Filter cycles 全部 -> 画面 -> 数字 -> 承诺: three taps
      // land on 承诺, so the replay shows only the promise.
      this.filterTap();
      this.filterTap();
      this.filterTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - replay filtered to 承诺 (1 of 3 entries visible)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary (3 entries: 画面 1, 数字 1, 承诺 1, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, e;
    var list = this._mode === 'replay' ? this._visible() : this._entries;
    if (list.length === 0) {
      rows.push({
        idx: 0,
        name: this._mode === 'replay' ? '过滤下暂无记录' : '暂无登记',
        detail: this._mode === 'replay'
          ? '过滤 ' + this._filter() + ' 下没有格 — FILTER 换个类型，或 BACK 回去继续记'
          : '看向目标停稳，TYPE 选类型、DESC 选一句、DIR 选朝向，MARK 记一格',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < list.length; i++) {
        e = list[i];
        rows.push({
          idx: i,
          name: '格' + (i + 1) + ' · ' + e.time + ' · ' + e.dir + ' · ' + e.type,
          detail: e.desc + (e.demo ? '（DEMO 示例）' : ''),
          flag: this._focus === i ? '▶' : '✓',
          cls: 'row'
        });
      }
    }

    var c = this._counts();
    var patch = { rows: rows };
    patch.countLine = '已记 ' + this._entries.length + ' 格 · 画面 ' + c['画面'] +
      ' · 数字 ' + c['数字'] + ' · 承诺 ' + c['承诺'] +
      ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'register') {
      patch.boxLabel = '◎ 登记 — 看向目标停稳，TYPE 选类型、DESC 选一句、DIR 选朝向，MARK 记一格';
      patch.bigLabel = '白天登记 · 待机';
      patch.bigText = this._entries.length === 0 ? '还没记' : '已记 ' + this._entries.length + ' 格';
      patch.bigNote = '类型 ' + this._type() + ' · 描述 ' + this._desc() + ' · 朝向 ' + this._dir() + ' · MARK 记一格 · REPLAY 回放';
    } else if (this._mode === 'replay') {
      patch.boxLabel = '◎ 时间线回放 · 过滤：' + this._filter() + ' — NEXT/PREV 换格，FILTER 换类型';
      patch.bigLabel = '时间线回放 · ' + this._filter();
      var vis = this._visible();
      if (vis.length === 0) {
        patch.bigText = '暂无此类型';
        patch.bigNote = '过滤 ' + this._filter() + ' 下没有格 · FILTER 换个类型';
      } else {
        var cur = vis[this._focus] || vis[0];
        patch.bigText = cur.desc;
        patch.bigNote = cur.time + ' · ' + cur.dir + ' · ' + cur.type + ' · 第 ' + (this._focus + 1) + '/' + vis.length + ' 格' + (cur.demo ? '（DEMO 示例）' : '');
      }
    } else {
      patch.boxLabel = '◎ 本次复盘小结';
      patch.bigLabel = '本次复盘小结';
      var s = this._summary || { total: 0, scene: 0, number: 0, promise: 0, first: '', last: '' };
      patch.bigText = '共 ' + s.total + ' 格';
      patch.bigNote = '画面 ' + s.scene + ' · 数字 ' + s.number + ' · 承诺 ' + s.promise + ' · ' + s.first + ' 至 ' + s.last + ' · 点 END 确认清空 · BACK 返回回放';
    }
    patch.bigCls = this._bigClsFor(patch.bigText);
    this.setData(patch);
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">DAY LOOKBACK v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{permLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="demoTap">DEMO</button>
      <button class="btn btn-main" bindtap="typeTap">TYPE</button>
      <button class="btn btn-main" bindtap="descTap">DESC</button>
      <button class="btn btn-main" bindtap="dirTap">DIR</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="replayTap">REPLAY</button>
      <button class="btn btn-main" bindtap="filterTap">FILTER</button>
      <button class="btn" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="prevTap">PREV</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">单会话时间线：登记与回放发生在同一次打开的会话内，关掉即清——白天记、晚上看需要当天一直开着它（或分段打开、当次看当次的），不做跨时段存档；朝向只是你登记时的头部方向，不是定位导航——回放的朝向标记帮你想起当时朝哪边看；描述是你自己记的一句话，不是拍照/录音原文；没有室内定位；零落盘</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 2px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 1px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.biglabel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.bignum {
  color: #40ff5e;
  font-size: 34px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-sm {
  color: #40ff5e;
  font-size: 24px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-xs {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 1px;
}
.bignote {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 2px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 1px;
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
.list {
  flex-shrink: 0;
  height: 80px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-right: 8px;
}
.rdetail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 15px;
  flex-grow: 1;
}
.rflag {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 12px;
}
</style>
