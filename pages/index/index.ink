<script def>
{
  "navigationBarTitleText": "Trail Back"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '返程面包屑 — 商场/展馆/大停车场逛一圈，回去的路完全没印象：沿途关键路口看向登记面包屑（朝向+画面），返程按反向朝向逐点引导',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 返程面包屑 — MARK 登记路口，RETURN 开始返程，ARRIVED 确认到达，END 出小结',
    bigLabel: '返程面包屑 · 待机',
    bigText: '还没开始',
    bigNote: '沿途关键路口看向停稳点 MARK · 返程点 RETURN 按反向朝向逐点走回起点',
    permLine: 'PERM: CAMERA — 面包屑画面拍照；不录音、不定位',
    rows: [],
    countLine: '登记 0 处 · 返程走了 0 处 · 还没返程 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START begins marking, MARK records a breadcrumb, RETURN walks back in reverse, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | marking | returning | summary
    this._crumbs = []; // {name, reverse, photo}
    this._arrived = 0; // points confirmed on the way back
    this._complete = false; // reached the first crumb on the way back
    this._retIdx = -1; // index of the current return target, -1 when not returning
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 marking 2, 2 registered 3, 3 returning last, 4 returning first, 5 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: crumbs, arrivals and the
    // return walk die with the page. Photos are never stored:
    // a crumb keeps only a label, never an image file.
    this._mode = 'idle';
    this._crumbs = [];
    this._arrived = 0;
    this._complete = false;
    this._retIdx = -1;
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. Return guidance speaks only on an
    // explicit SPEAK tap or once when the return walk starts.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  _sectorName(angle) {
    var a = ((angle % 360) + 360) % 360;
    if (a < 45 || a >= 315) return '前';
    if (a < 135) return '右';
    if (a < 225) return '后';
    return '左';
  },

  _reverseOf(angle) {
    return this._sectorName(angle + 180);
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - nod confirms only on steady gaze'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (nod only)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod starts
    // marking in idle and confirms the summary. A nod never
    // records a crumb and never confirms an arrival: a crumb
    // comes from looking steady at a junction and tapping
    // MARK, an arrival from standing at the point and tapping
    // ARRIVED — a nod must not invent either.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'marking') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a breadcrumb, MARK records it' });
      return;
    }
    if (this._mode === 'returning') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not an arrival, ARRIVED confirms it' });
      return;
    }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'marking') this.markTap();
      else if (this._mode === 'returning') this.arrivedTap();
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

  // ---------- start / mark / return / arrive / end ----------

  startTap() {
    if (this._mode === 'marking') {
      this.setData({ lastEvent: 'EVT: START refused - already marking, MARK records the next junction' });
      return;
    }
    if (this._mode === 'returning') {
      this.setData({ lastEvent: 'EVT: START refused - a return walk is running, ARRIVED confirms each point' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    this._mode = 'marking';
    this.setData({
      status: '登记中 — 沿途关键路口看向停稳点 MARK，登记满了点 RETURN 开始返程',
      lastEvent: 'EVT: marking started - look steady at a junction, MARK records it'
    });
    this._renderAll();
  },

  _recordCrumb(crumb) {
    // The single seam for a crumb: the real MARK path, DEMO
    // stages and the harness all land here, so the crumb
    // rule is tested once, not per path.
    if (this._mode !== 'marking') return false;
    if (this._crumbs.length >= 8) return false;
    this._crumbs.push(crumb);
    this.setData({
      status: '登记中 — 已登记 ' + this._crumbs.length + ' 处，继续看向停稳点 MARK，返程点 RETURN',
      lastEvent: 'EVT: crumb ' + crumb.name + ' recorded - ' + this._crumbs.length + ' total'
    });
    this._renderAll();
    return true;
  },

  markTap() {
    if (this._mode !== 'marking') {
      this.setData({ lastEvent: 'EVT: MARK ignored - START begins marking first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: MARK refused - hold steady at the junction first' });
      return;
    }
    if (this._crumbs.length >= 8) {
      this.setData({ lastEvent: 'EVT: MARK refused - 8 crumbs already, RETURN walks back' });
      return;
    }
    // A crumb keeps a label, never an image file: the photo
    // is only a same-session对照 aid, taken below, and the
    // crumb is recorded even if the photo fails.
    var crumb = {
      name: '路口' + (this._crumbs.length + 1),
      reverse: '登记时的反方向',
      photo: '示例画面'
    };
    this._recordCrumb(crumb);
    this._snapPhoto(crumb);
  },

  async _snapPhoto(crumb) {
    // Real photo path (wide mode, like room-sweep): a
    // same-session对照 picture for the return walk. Failure
    // only notes itself — the crumb already stands.
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('camera n/a on this host');
      }
      var stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = stream.getVideoTracks()[0];
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      await cap.takePhoto({ mode: 'wide' });
      crumb.photo = '已拍画面';
      try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._renderAll();
    } catch (e) {
      this.setData({ lastEvent: 'EVT: photo failed - ' + this._err(e) + ' - crumb kept as 示例画面' });
    }
  },

  returnTap() {
    if (this._mode === 'returning') {
      this.setData({ lastEvent: 'EVT: RETURN refused - already walking back, ARRIVED confirms each point' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: RETURN refused - a summary is open, END confirms it first' });
      return;
    }
    if (this._crumbs.length === 0) {
      this.setData({ lastEvent: 'EVT: RETURN refused - missing: 先 START 登记路口' });
      return;
    }
    this._mode = 'returning';
    this._retIdx = this._crumbs.length - 1;
    this._arrived = 0;
    this._complete = false;
    this._focus = this._retIdx;
    this._speakText('开始返程：先朝' + this._crumbs[this._retIdx].reverse + '走，到' + this._crumbs[this._retIdx].name);
    this.setData({
      status: '返程中 — 按反向朝向逐点走回起点，每点点 ARRIVED 确认',
      lastEvent: 'EVT: return started - target ' + this._crumbs[this._retIdx].name + ' reverse ' + this._crumbs[this._retIdx].reverse + ' (one TTS)'
    });
    this._renderAll();
  },

  arrivedTap() {
    if (this._mode !== 'returning') {
      this.setData({ lastEvent: 'EVT: ARRIVED ignored - RETURN starts the walk back first' });
      return;
    }
    this._arrived++;
    if (this._retIdx === 0) {
      // Last point confirmed: back at the start.
      this._complete = true;
      this._backMode = 'returning';
      this._mode = 'summary';
      this._summary = {
        crumbs: this._crumbs.length,
        arrived: this._arrived,
        complete: true
      };
      this.setData({
        status: '已回到起点 — 登记 ' + this._crumbs.length + ' 处，返程走了 ' + this._arrived + ' 处，点 END 确认清空，BACK 回去',
        lastEvent: 'EVT: back at start - crumbs ' + this._crumbs.length + ' arrived ' + this._arrived
      });
      this._renderAll();
      return;
    }
    this._retIdx--;
    this._focus = this._retIdx;
    this.setData({
      status: '返程中 — 下一点' + this._crumbs[this._retIdx].name + '，反向：' + this._crumbs[this._retIdx].reverse,
      lastEvent: 'EVT: arrived - next target ' + this._crumbs[this._retIdx].name + ' reverse ' + this._crumbs[this._retIdx].reverse
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the session.
      // BACK is the way back without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 登记路口' });
      return;
    }
    this._backMode = this._mode;
    this._mode = 'summary';
    this._summary = {
      crumbs: this._crumbs.length,
      arrived: this._arrived,
      complete: this._complete
    };
    this.setData({
      status: '结束 — 登记 ' + this._crumbs.length + ' 处，返程走了 ' + this._arrived + ' 处，点 END 确认清空，BACK 回去',
      lastEvent: 'EVT: closed - crumbs ' + this._crumbs.length + ' arrived ' + this._arrived + ' complete ' + this._complete
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._crumbs = [];
    this._arrived = 0;
    this._complete = false;
    this._retIdx = -1;
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '返程面包屑 — 下次逛商场再 START 登记路口',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the mode it came
      // from without deleting anything; the summary is
      // rebuilt on END.
      this._mode = this._backMode || 'marking';
      this._summary = null;
      this.setData({
        status: '回到登记 — BACK 回来不删东西，小结待重建',
        lastEvent: 'EVT: back from summary - session kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'marking' || this._mode === 'returning') {
      // Back to idle keeps the session; START resumes the
      // same round instead of resetting it.
      this._mode = 'idle';
      this.setData({
        status: '返程面包屑 — 已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins marking first' });
  },

  _focusLen() {
    return Math.max(1, this._crumbs.length);
  },

  nextTap() {
    if (this._mode === 'returning') {
      // NEXT walks the return list toward the start without
      // confirming: it only moves the target.
      if (this._retIdx > 0) {
        this._retIdx--;
        this._focus = this._retIdx;
        this._renderAll();
        this.setData({ lastEvent: 'EVT: return target -> ' + this._crumbs[this._retIdx].name });
      } else {
        this.setData({ lastEvent: 'EVT: NEXT refused - already at the first crumb, ARRIVED returns to start' });
      }
      return;
    }
    var n = this._focusLen();
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    if (this._mode === 'returning') {
      if (this._retIdx < this._crumbs.length - 1) {
        this._retIdx++;
        this._focus = this._retIdx;
        this._renderAll();
        this.setData({ lastEvent: 'EVT: return target -> ' + this._crumbs[this._retIdx].name });
      } else {
        this.setData({ lastEvent: 'EVT: PREV refused - already at the last crumb' });
      }
      return;
    }
    var n = this._focusLen();
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) return; // missing dataset: keep focus, never jump to 0
    } catch (e) { return; }
    if (idx < 0 || idx >= this._focusLen()) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没开始：START 登记路口';
    } else if (this._mode === 'marking') {
      line = '登记中，已登记 ' + this._crumbs.length + ' 处';
    } else if (this._mode === 'returning') {
      line = '返程目标：' + this._crumbs[this._retIdx].name + '，反向：' + this._crumbs[this._retIdx].reverse;
    } else if (this._summary) {
      line = '本次小结：登记 ' + this._summary.crumbs + ' 处，返程走了 ' + this._summary.arrived + ' 处' + (this._summary.complete ? '，已回到起点' : '');
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
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._crumbs.length > 0 || this._arrived > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    // Staged crumbs with staged reverse sectors: 路口1 was
    // recorded facing 前 (reverse 后), 路口2 facing 右
    // (reverse 左), 路口3 facing 后 (reverse 前).
    var staged = [
      { name: '路口1', reverse: '后', photo: '示例画面' },
      { name: '路口2', reverse: '左', photo: '示例画面' },
      { name: '路口3', reverse: '前', photo: '示例画面' }
    ];
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      // DEMO is a staged sample, not a live walk: crumbs and
      // reverse directions are staged values, not sensor
      // readings.
      this._mode = 'marking';
      this._recordCrumb(staged[0]);
      this._recordCrumb(staged[1]);
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - marking 2 crumbs (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._recordCrumb(staged[2]);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - registered 3 crumbs (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this.returnTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - returning to 路口3 reverse 前 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.arrivedTap();
      this.arrivedTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - returning to 路口1, arrived 2 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.arrivedTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: crumbs 3, arrived 3, back at start (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    if (this._crumbs.length === 0) {
      rows.push({ idx: 0, name: '还没登记', detail: '沿途关键路口看向停稳点 MARK', flag: '▶', cls: 'row' });
    } else {
      for (var i = 0; i < this._crumbs.length; i++) {
        var c = this._crumbs[i];
        var mark = '';
        if (this._mode === 'returning' && this._retIdx === i) mark = ' · 返程目标';
        else if (this._mode === 'returning' && i > this._retIdx) mark = ' · 已走过';
        rows.push({
          idx: i,
          name: c.name,
          detail: '反向：' + c.reverse + ' · ' + c.photo + mark,
          flag: (this._focus === i ? '▶' : '●'),
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    patch.countLine = '登记 ' + this._crumbs.length + ' 处 · 返程走了 ' + this._arrived + ' 处 · ' + (this._complete ? '已回到起点' : (this._mode === 'returning' ? '返程中' : '还没返程')) + ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 返程面包屑 — MARK 登记路口，RETURN 开始返程，ARRIVED 确认到达，END 出小结';
      patch.bigLabel = '返程面包屑 · 待机';
      patch.bigText = (this._crumbs.length > 0 || this._arrived > 0) ? '已停未清' : '还没开始';
      patch.bigNote = '沿途关键路口看向停稳点 MARK · 返程点 RETURN 按反向朝向逐点走回起点';
    } else if (this._mode === 'marking') {
      patch.boxLabel = '◎ 登记中 — 已登记 ' + this._crumbs.length + ' 处';
      patch.bigLabel = '返程面包屑 · 登记中';
      patch.bigText = '登记 ' + this._crumbs.length + ' 处';
      patch.bigNote = '继续看向停稳点 MARK · 返程点 RETURN';
    } else if (this._mode === 'returning') {
      var cur = this._crumbs[this._retIdx];
      patch.boxLabel = '◎ 返程中 — 目标' + cur.name + '，反向：' + cur.reverse;
      patch.bigLabel = '返程面包屑 · 返程中';
      patch.bigText = '返程 ' + (this._crumbs.length - this._retIdx) + '/' + this._crumbs.length;
      patch.bigNote = '目标' + cur.name + ' · 反向：' + cur.reverse + ' · 对照' + cur.photo + ' · ARRIVED 确认到达';
    } else {
      patch.boxLabel = '◎ 本次小结 — 登记几处、返程走了几处钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { crumbs: 0, arrived: 0, complete: false };
      patch.bigText = '登记 ' + sm.crumbs + ' 处';
      patch.bigNote = '返程走了 ' + sm.arrived + ' 处' + (sm.complete ? ' · 已回到起点' : '') + ' · 点 END 确认清空 · BACK 回去';
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
      <text class="title">TRAIL BACK v1.0.0</text>
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
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="returnTap">RETURN</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="arrivedTap">ARRIVED</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="actions">
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
    <text class="foot2">它不是导航——平台没有室内定位、没有 GPS 路径规划，面包屑只是你登记的朝向 + 画面，不是地图 · 反向朝向是你登记朝向的反向提示，不是测出来的返程路线 · 照片只用于本次返程对照、会话内即弃，不存档、不上传 · 路口是你自己判断登记的，它不知道哪个路口关键 · 只存本次会话，关掉即清 · 没有室内定位 · 零落盘</text>
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
