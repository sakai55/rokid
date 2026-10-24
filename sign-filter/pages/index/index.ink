<script def>
{
  "navigationBarTitleText": "Sign Filter"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '找牌过滤 — 先声明目标，扫街时只有读到的牌面含目标才亮，其余牌只计不打断',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 待机 — TGT 换目标，DIR 设拍照时的面向，START 开始扫街',
    bigLabel: '找牌过滤 · 待机',
    bigText: '全家',
    bigNote: '目标：全家（DEMO 示例） · START 开始扫街 · DEMO 走演示',
    permLine: 'PERM: CAMERA — telephoto 拍牌面 + LLM 读字做包含比对；无定位、无录音',
    rows: [],
    countLine: '已看过 0 块 · 命中 0 块 · 只存本次扫街内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - pick a target with TGT, then START',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | scanning | summary
    this._targetIdx = 0;
    this._targets = ['全家', '星巴克', '中山路128号', '7-ELEVEN'];
    this._dirIdx = 1;
    this._dirs = ['左', '正前', '右'];
    this._seen = []; // { time, text, dir, hit }
    this._banner = ''; // current hit sign text, '' = none
    this._bannerDir = ''; // facing direction of the hit photo (NOT the current DIR setting)
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 scanning, 2 non-match, 3 hit, 4 summary
    this._summary = null; // { seen, hit, hitText } on summary screen
    this._nodLock = false;
    this._startAt = 0;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: target, seen list, banner and
    // summary die with the page. Nothing was ever written to any
    // storage, so there is nothing to clean up - that IS the
    // design. Close the agent and the filter is gone; the next
    // walk starts from a blank filter.
    this._seen = [];
    this._banner = '';
    this._bannerDir = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _target() { return this._targets[this._targetIdx]; },

  _dir() { return this._dirs[this._dirIdx]; },


  // Seen = every sign actually read (hits included); the hit
  // count is listed separately. A non-match increments only this
  // counter and nothing else - no banner, no TTS.
  _seenCount() {
    return this._seen.length;
  },

  _hitCount() {
    var n = 0;
    for (var i = 0; i < this._seen.length; i++) if (this._seen[i].hit) n++;
    return n;
  },

  _norm(s) {
    return String(s || '').toUpperCase().replace(/[\s\-]/g, '');
  },

  // The ONLY match rule, stated everywhere it matters: the
  // normalised sign text read by the LLM must CONTAIN the
  // normalised target string. There is no sign database, no
  // fuzzy match, no brand recognition - a misread character can
  // cause a miss or a false hit, and the UI says so.
  _isMatch(signText) {
    var t = this._norm(this._target());
    var s = this._norm(signText);
    if (!t || !s) return false;
    return s.indexOf(t) !== -1;
  },

  _speakText(text) {
    // TTS via the host voice. The utterance lang is never set:
    // the documented behaviour is that it does not take effect.
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
    // Nod discipline in THIS agent: a steady nod confirms only
    // where confirmation is safe - START in idle, CONFIRM on the
    // summary screen. In a live walk a nod is ignored on purpose:
    // a photo must be a deliberate tap, never an accidental nod.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
    this.setData({ lastEvent: 'EVT: nod ignored - nod never snaps a photo mid-walk' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'scanning') this.photoTap();
      else this._confirmSummary();
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

  // ---------- walk control ----------

  startTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: START refused - already scanning or a summary is open' });
      return;
    }
    this._mode = 'scanning';
    this._seen = [];
    this._banner = '';
    this._bannerDir = '';
    this._summary = null;
    this._focus = 0;
    this._startAt = this._now();
    this.setData({
      status: '扫街进行中 — 只有含目标的牌才亮，其余牌只计不打断',
      lastEvent: 'EVT: walk started (target ' + this._target() + ')'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode !== 'scanning') {
      this.setData({ lastEvent: 'EVT: END refused - no live walk' });
      return;
    }
    this._mode = 'summary';
    var hits = [];
    for (var i = 0; i < this._seen.length; i++) if (this._seen[i].hit) hits.push(this._seen[i]);
    this._summary = {
      seen: this._seenCount(),
      hit: this._hitCount(),
      hitText: hits.length ? hits.map(function (h) { return h.text + ' · ' + h.dir; }).join('；') : '未命中'
    };
    this.setData({
      status: '扫街小结 — 确认后清空本次记录',
      lastEvent: 'EVT: walk ended - summary ready (seen ' + this._summary.seen + ', hit ' + this._summary.hit + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._seen = [];
    this._banner = '';
    this._bannerDir = '';
    this._summary = null;
    this._mode = 'idle';
    this._demo = false;
    this._demoStage = 0;
    this._startAt = 0;
    this.setData({
      status: '找牌过滤 — 先声明目标，扫街时只有读到的牌面含目标才亮，其余牌只计不打断',
      lastEvent: 'EVT: summary confirmed - walk data cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the live walk without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'scanning';
      this._summary = null;
      this.setData({
        status: '扫街进行中 — 只有含目标的牌才亮，其余牌只计不打断',
        lastEvent: 'EVT: back to live walk - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - END finishes a walk, DEL clears a banner' });
  },

  nextTap() {
    if (this._seen.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - seen list is empty' });
      return;
    }
    this._focus = (this._focus + 1) % this._seen.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> entry ' + (this._focus + 1) });
  },

  prevTap() {
    if (this._seen.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - seen list is empty' });
      return;
    }
    this._focus = (this._focus - 1 + this._seen.length) % this._seen.length;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> entry ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) idx = 0;
    } catch (e) { idx = 0; }
    if (idx < 0 || idx >= this._seen.length) return;
    this._focus = idx;
    var ev = this._seen[idx];
    this.setData({ lastEvent: 'EVT: entry ' + (idx + 1) + ' - ' + ev.text + ' · ' + ev.dir });
    this._renderAll();
  },

  // ---------- target & direction (target is idle-only) ----------

  tgtTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TGT refused - target is set before the walk, never mid-walk' });
      return;
    }
    this._targetIdx = (this._targetIdx + 1) % this._targets.length;
    this.setData({ lastEvent: 'EVT: target set to ' + this._target() + ' (DEMO sample target)' });
    this._renderAll();
  },

  dirTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DIR refused - no photo is taken from a summary' });
      return;
    }
    // Direction is the direction the wearer faces when the photo
    // is taken, declared here before PHOTO. It is NOT a
    // positioning fix: there is no indoor/outdoor positioning in
    // this agent, and the UI says so.
    this._dirIdx = (this._dirIdx + 1) % this._dirs.length;
    this.setData({ lastEvent: 'EVT: photo direction set to ' + this._dir() });
    this._renderAll();
  },

  delTap() {
    if (this._mode === 'scanning') {
      // DEL only clears the hit banner - it never deletes the
      // seen list or ends the walk.
      this._banner = '';
      this._bannerDir = '';
      this.setData({ lastEvent: 'EVT: banner cleared - walk and seen list kept' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEL ignored - nothing to clear here' });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '找牌过滤待机，目标 ' + this._target();
    } else if (this._mode === 'scanning') {
      if (this._banner) {
        line = '找到了，' + this._target() + '，在你' + (this._bannerDir === '左' ? '左手边' : this._bannerDir === '右' ? '右手边' : '正前方') + '边';
      } else {
        line = '扫街进行中，目标 ' + this._target() + '，已看过 ' + this._seenCount() + ' 块，命中 ' + this._hitCount() + ' 块';
      }
    } else if (this._summary) {
      line = '扫街小结：看过 ' + this._summary.seen + ' 块，命中 ' + this._summary.hit + ' 块，' + this._summary.hitText;
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- photo + read (telephoto photo -> data: URL -> host LLM image input) ----------

  _withTimeout(promise, ms, what) {
    var self = this;
    return new Promise(function (resolve, reject) {
      var done = false;
      var timer = setTimeout(function () {
        if (!done) { done = true; reject(new Error(what + ' timeout')); }
      }, ms);
      promise.then(function (v) {
        if (!done) { done = true; clearTimeout(timer); resolve(v); }
      }, function (e) {
        if (!done) { done = true; clearTimeout(timer); reject(e); }
      });
    });
  },

  _blobToDataUrl(blob) {
    return new Promise(function (resolve, reject) {
      try {
        var r = new FileReader();
        r.onload = function () { resolve(r.result); };
        r.onerror = function () { reject(new Error('FileReader error')); };
        r.readAsDataURL(blob);
      } catch (e) { reject(e); }
    });
  },

  async _llmReadSign(dataUrl) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return { ok: false, reason: 'no-lm' };
    var avail;
    try {
      avail = await LM.availability();
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    }
    if (avail !== 'available') return { ok: false, reason: 'unavailable' };
    var session = null;
    try {
      session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You read shop signs and door plates from photos. Reply with only the visible sign text, one line. Never invent characters that are not visible.' }]
      });
      var ans = await this._withTimeout(session.prompt([{ role: 'user', content: [{ type: 'image', image: dataUrl }, { type: 'text', text: 'Read the sign text in this photo. Reply with only the text.' }] }]), 30000, 'llm read');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var line = String(ans).trim().split('\n')[0].trim().slice(0, 40);
      if (!line) return { ok: false, reason: 'unreadable' };
      return { ok: true, text: line };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  async photoTap() {
    if (this._mode !== 'scanning') {
      this.setData({ lastEvent: 'EVT: PHOTO refused - start a walk first' });
      return;
    }
    if (this.data.busy) return;
    this.setData({ busy: true, status: '拍牌中（telephoto）…' });
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('camera unavailable on this host');
      }
      var stream = await this._withTimeout(navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      var track = stream.getVideoTracks()[0];
      var blob;
      try {
        if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
        var cap = new ImageCapture(track);
        blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
      } finally {
        try { stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e) {}
      }
      var dataUrl = await this._withTimeout(this._blobToDataUrl(blob), 12000, 'convert');
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) throw new Error('photo did not convert to a data: URL');
      var r = await this._llmReadSign(dataUrl);
      if (!r.ok) {
        var why = r.reason === 'no-lm' ? '这台设备没有大模型'
          : r.reason === 'unavailable' ? '大模型现在不可用'
          : r.reason === 'empty' ? '模型没有返回内容'
          : r.reason === 'unreadable' ? '牌面没读清'
          : '模型出错：' + this._err(r.error);
        this.setData({
          status: '没读出来（' + why + '）— 不计入已看过，重拍一次',
          lastEvent: 'EVT: READ FAIL (' + r.reason + ') - not counted, retake'
        });
        this._renderAll();
        return;
      }
      // A failed read is never counted as a seen sign: the
      // wearer did not actually see a sign's text.
      this._onSignRead(r.text, this._dir());
    } catch (e) {
      this.setData({
        status: '拍照/读牌不可用 — 不计入已看过，重拍一次',
        lastEvent: 'EVT: PHOTO FAIL - ' + this._err(e)
      });
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  // The single decision point for every read sign, real or DEMO:
  // match -> banner + one TTS; non-match -> silent count only.
  _onSignRead(signText, dir) {
    if (this._mode !== 'scanning') return;
    var text = String(signText || '').trim();
    if (!text) {
      this.setData({ lastEvent: 'EVT: empty sign read ignored - not counted' });
      return;
    }
    var hit = this._isMatch(text);
    this._seen.push({ time: '第' + (this._seen.length + 1) + '块', text: text, dir: dir, hit: hit });
    this._focus = this._seen.length - 1;
    if (hit) {
      this._banner = text;
      this._bannerDir = dir;
      var phrase = '找到了，' + this._target() + '，在你' + (dir === '左' ? '左手边' : dir === '右' ? '右手边' : '正前方');
      this._speakText(phrase);
      this.setData({
        status: '找到了 — 只有匹配的牌才亮',
        lastEvent: 'EVT: HIT (' + text + ' · ' + dir + ') - banner + TTS'
      });
    } else {
      this.setData({
        status: '扫街进行中 — 只有含目标的牌才亮，其余牌只计不打断',
        lastEvent: 'EVT: seen (no match) ' + text + ' · ' + dir + ' - counted silently'
      });
    }
    this._renderAll();
  },

  // ---------- DEMO (staged, labelled, never overwrites a user walk) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode === 'scanning' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user walk is running' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._mode = 'scanning';
      this._targetIdx = 0;
      this._dirIdx = 1;
      this._seen = [];
      this._banner = '';
      this._bannerDir = '';
      this._summary = null;
      this._focus = 0;
      this._startAt = this._now();
      this.setData({
        status: 'DEMO - 扫街进行中（示例数据，非真实拍照）',
        lastEvent: 'EVT: DEMO stage 1 - walk started (target 全家， DEMO sample target)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._onSignRead('肯德基', '左');
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - non-match sign counted silently (no banner, no TTS)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._onSignRead('全家便利店', '右');
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - HIT banner + TTS (全家便利店 · 右）' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._mode = 'summary';
      var hits = [];
      for (var i = 0; i < this._seen.length; i++) if (this._seen[i].hit) hits.push(this._seen[i]);
      this._summary = {
        seen: this._seenCount(),
        hit: this._hitCount(),
        hitText: hits.length ? hits.map(function (h) { return h.text + ' · ' + h.dir; }).join('；') : '未命中'
      };
      this.setData({
        status: 'DEMO - 扫街小结（示例数据）',
        lastEvent: 'EVT: DEMO stage 4 - summary (seen 2, hit 1)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._seen.length; i++) {
      var ev = this._seen[i];
      rows.push({
        idx: i,
        name: ev.time + ' · ' + ev.text + ' · ' + ev.dir,
        detail: ev.hit ? '命中' : '已看过',
        flag: ev.hit ? '!' : '·',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已看过 ' + this._seenCount() + ' 块 · 命中 ' + this._hitCount() + ' 块' +
      ' · 只存本次扫街内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待机 — TGT 换目标，DIR 设拍照时的面向，START 开始扫街';
      patch.bigLabel = '找牌过滤 · 待机';
      patch.bigText = this._target();
      patch.bigNote = '目标：' + this._target() + '（DEMO 示例） · START 开始 · DEMO 走演示';
    } else if (this._mode === 'scanning') {
      if (this._banner) {
        patch.boxLabel = '◎ 找到了 — 只有匹配的牌才亮';
        patch.bigLabel = '找到了';
        patch.bigText = this._banner;
        patch.bigNote = '目标 ' + this._target() + ' · 在你' + (this._bannerDir === '左' ? '左手边' : this._bannerDir === '右' ? '右手边' : '正前方') + ' · DEL 只清横幅，不动已看过';
      } else {
        patch.boxLabel = '◎ 扫街进行中 — 只有含目标的牌才亮，其余牌只计不打断';
        patch.bigLabel = '扫街进行中';
        patch.bigText = '已看过 ' + this._seenCount() + ' 块';
        patch.bigNote = '目标：' + this._target() + ' · 面向：' + this._dir() + ' · PHOTO 拍牌读字';
      }
    } else {
      patch.boxLabel = '◎ 扫街小结';
      patch.bigLabel = '扫街小结';
      var s = this._summary || { seen: 0, hit: 0, hitText: '未命中' };
      patch.bigText = '看过 ' + s.seen + ' 块 · 命中 ' + s.hit + ' 块';
      patch.bigNote = '命中：' + s.hitText + ' · 确认后清空本次记录';
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
      <text class="title">SIGN FILTER v1.0.0</text>
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
      <button class="btn btn-main" bindtap="startTap">START</button>
      <button class="btn" bindtap="photoTap">PHOTO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="tgtTap">TGT</button>
      <button class="btn" bindtap="dirTap">DIR</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="endTap">END</button>
      <button class="btn" bindtap="backTap">BACK</button>
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
    <text class="foot2">匹配只对 LLM 读出的牌面文字做包含比对，读错字可能漏报/误报 · 方位为拍照时面向方向，非定位 · 只存本次扫街，关掉即清</text>
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
  line-height: 38px;
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
  height: 95px;
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
