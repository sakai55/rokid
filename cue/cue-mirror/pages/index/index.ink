<script def>
{
  "navigationBarTitleText": "Cue Mirror"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '镜前提示 — 早上出门前最慌乱：天气、第一件事、别忘的东西全挤在镜前十秒：看向镜子停稳才亮三行，逐行确认已读',
    steadyText: 'HEAD: moving - look at the mirror and hold still',
    boxLabel: '◎ 镜前三行 — 看向镜子停稳，TRIG 亮三行',
    bigLabel: '镜前三行 · 待机',
    bigText: '还没触发',
    bigNote: '看向镜子停稳 · TRIG 亮三行 · 逐行确认已读',
    permLine: 'PERM: 无权限 — 只做镜前三行提醒；不拍照、不录音、不定位；三行全是预设，不是实时天气/日程；昨日一句话只存本次会话',
    rows: [],
    countLine: '已读 0/3 · 未读 3 行 · 报未读 0 次 · 只存本次镜前会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look at the mirror, hold steady, TRIG lights up three lines',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | list | summary
    this._labels = ['今日天气要点', '第一件事', '昨日留给今早的一句话'];
    // Preset groups, rotated on each fresh trigger. Group A is
    // the DEMO group; group B is the second preset. Nothing
    // here is live weather or a calendar read: every line is
    // a preset the wearer set in advance.
    this._groups = [
      ['晴，18–24℃，午后有雨带伞', '9 点开会', '别忘带工牌'],
      ['阴，12–16℃，早晚凉加外套', '10 点见客户', '记得带伞']
    ];
    this._groupIdx = -1; // -1 = none yet; fresh trigger advances it
    this._lines = ['', '', ''];
    // per-line state: 'none' | 'read'
    this._state = ['none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 triggered, 2-3 read, 4 warned, 5 all read, 6 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the three lines, their
    // read marks, the warn count and the summary die with
    // the page. Nothing was ever written anywhere persistent,
    // so there is nothing to clean up — that IS the design.
    // The yesterday line is a same-session note, not a
    // cross-day message: yesterday-to-today persistence would
    // need a storage exception decided by GO, and this agent
    // does not take it on its own.
    this._mode = 'idle';
    this._state = ['none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this._groupIdx = -1;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _unread() {
    var m = [], i;
    for (i = 0; i < this._labels.length; i++) {
      if (this._state[i] === 'none') m.push(this._labels[i]);
    }
    return m;
  },

  _readCount() {
    var c = 0, i;
    for (i = 0; i < this._state.length; i++) { if (this._state[i] === 'read') c++; }
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - look at the mirror and hold still'
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
      this.setData({ lastEvent: 'EVT: nod ignored - look at the mirror and hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod triggers the
    // three lines in idle, confirms the focused line read in
    // the list, or confirms the summary. A nod never picks a
    // line and never closes the round on its own: closing
    // early is END.
    if (this._mode === 'idle') { this.trigTap(); return; }
    if (this._mode === 'list') { this.readTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.trigTap();
      else if (this._mode === 'list') this.readTap();
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

  // ---------- trigger ----------

  _trigger(demo) {
    // Fresh trigger only: a kept list (BACK from the list)
    // restores its own group and read marks instead.
    if (!this._triggered) {
      this._groupIdx = (this._groupIdx + 1) % this._groups.length;
      this._lines = this._groups[this._groupIdx].slice();
      this._state = ['none', 'none', 'none'];
      this._warned = false;
    }
    this._mode = 'list';
    this._triggered = true;
    this._focus = 0;
    this.setData({
      status: demo
        ? '镜前三行已亮（DEMO 示例，预设组 A）— 逐行确认已读，三行都读了可以出门'
        : '镜前三行已亮 — 逐行确认已读，三行都读了可以出门',
      lastEvent: demo ? 'EVT: DEMO stage 1 - three lines lit (DEMO sample, preset group A)' : 'EVT: three lines lit - look confirmed at the mirror'
    });
    this._renderAll();
  },

  trigTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TRIG refused - the lines are already lit or a summary is up' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: TRIG refused - look at the mirror and hold steady first' });
      return;
    }
    this._trigger(false);
  },

  // ---------- read / close early ----------

  readTap() {
    if (this._mode !== 'list') {
      this.setData({ lastEvent: 'EVT: READ refused - confirm lines in the list, not in idle or summary' });
      return;
    }
    var st = this._state[this._focus];
    if (st === 'read') {
      this.setData({ lastEvent: 'EVT: READ refused - ' + this._labels[this._focus] + ' already read' });
      return;
    }
    this._state[this._focus] = 'read';
    // A warning names a moment's unread set; a changed list
    // deserves a fresh warning, not a stale one.
    this._warned = false;
    var n = this._readCount();
    this.setData({
      status: '已读：' + this._labels[this._focus] + '（' + n + '/3）— 继续读剩下的，三行都读了可以出门',
      lastEvent: 'EVT: read - ' + this._labels[this._focus] + ' (' + n + '/3)'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to the list without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先看向镜子停稳亮三行（TRIG）' });
      return;
    }
    // list mode: closing early is a reminder, never a gate.
    // The first END with unread lines names them in the
    // banner and in one TTS utterance, counts the warning,
    // and stays in the list; the second END closes for real
    // and the unread lines are recorded honestly in the
    // summary. A mirror glance must not hold the door
    // hostage: this is the deliberate opposite of cue-door
    // (CU01), where an unconfirmed END blocks.
    var unread = this._unread();
    if (unread.length > 0 && !this._warned) {
      this._warned = true;
      this._warns++;
      var line = '还没读 ' + unread.join('、') + '，再点 END 就结束（提醒，不是拦门）';
      this._speakText(line);
      this.setData({
        status: '提前结束提醒 — ' + line,
        lastEvent: 'EVT: END warned - unread: ' + unread.join('、') + ' (warning ' + this._warns + ', reminder not a gate)'
      });
      this._renderAll();
      return;
    }
    this._mode = 'summary';
    var allRead = unread.length === 0;
    this._summary = {
      read: this._readCount(),
      unread: unread,
      warns: this._warns,
      allRead: allRead
    };
    this.setData({
      status: allRead
        ? '结束 — 三行都读了，可以出门了，点 END 确认清空，BACK 返回三行'
        : '结束 — 未读 ' + unread.join('、') + '，点 END 确认清空，BACK 返回三行',
      lastEvent: allRead
        ? 'EVT: closed - all read, can go out (warning ' + this._warns + ')'
        : 'EVT: closed - unread: ' + unread.join('、') + ' (warning ' + this._warns + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._state = ['none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    // _groupIdx is kept on purpose: the next fresh trigger
    // rotates to the next preset group.
    this.setData({
      status: '镜前提示 — 看向镜子停稳，TRIG 再次亮三行（下一预设组）',
      lastEvent: 'EVT: summary confirmed - three lines cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the list without
      // deleting anything; the summary is rebuilt on END.
      // The warned flag is kept: END reopens the summary
      // without re-warning.
      this._mode = 'list';
      this._summary = null;
      this.setData({
        status: '镜前三行 — 继续读，或 END 结束',
        lastEvent: 'EVT: back to list - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'list') {
      // Back to idle keeps the read marks:
      // re-triggering restores the same three lines.
      this._mode = 'idle';
      this.setData({
        status: '镜前提示 — 看向镜子停稳，TRIG 再次亮三行（已读保留）',
        lastEvent: 'EVT: back to idle - read marks kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - TRIG lights up the three lines' });
  },

  _focusLen() {
    if (this._mode === 'idle') return 0;
    return this._labels.length;
  },

  nextTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: NEXT ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    var n = this._focusLen();
    if (n === 0) {
      this.setData({ lastEvent: 'EVT: PREV ignored - nothing to focus' });
      return;
    }
    this._focus = (this._focus - 1 + n) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
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
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没触发：看向镜子停稳，TRIG 亮三行';
    } else if (this._mode === 'list') {
      var unread = this._unread();
      if (this._warned) {
        line = '还没读 ' + unread.join('、') + '，再点 END 就结束';
      } else if (unread.length === 0) {
        line = '三行都读了，可以出门了';
      } else {
        line = '已读 ' + this._readCount() + '/3，还没读 ' + unread.join('、');
      }
    } else if (this._summary) {
      line = this._summary.allRead
        ? '本次镜前小结：三行都读了，可以出门了'
        : '本次镜前小结：已读 ' + this._summary.read + '/3，未读 ' + this._summary.unread.join('、');
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user three-line round is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._readCount() > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user read marks are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._trigger(true);
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._focus = 0;
      this.readTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 今日天气要点 read (DEMO sample, 1/3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._focus = 1;
      this.readTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 第一件事 read (DEMO sample, 2/3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - END warned, unread 昨日留给今早的一句话 (DEMO sample, reminder not a gate)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this._focus = 2;
      this.readTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - 昨日留给今早的一句话 read (DEMO sample, 3/3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - summary: read 3/3, can go out (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i;

    if (this._mode === 'idle') {
      rows.push({
        idx: 0,
        name: '暂未触发',
        detail: '看向镜子停稳，TRIG 亮三行（预设示例，轮换预设组）',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._labels.length; i++) {
        var detail = '';
        var flag = '';
        if (this._state[i] === 'read') { detail = this._lines[i] + ' · 已读（你本人的表态）'; flag = '✓'; }
        else { detail = this._lines[i] + ' · 还没读'; flag = (this._focus === i ? '▶' : '○'); }
        rows.push({
          idx: i,
          name: this._labels[i],
          detail: detail,
          flag: flag,
          cls: 'row'
        });
      }
    }

    var n = this._readCount();
    var unread = this._unread();
    var patch = { rows: rows };
    patch.countLine = '已读 ' + n + '/3 · 未读 ' + unread.length + ' 行 · 报未读 ' + this._warns + ' 次 · 只存本次镜前会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 镜前三行 — 看向镜子停稳，TRIG 亮三行';
      patch.bigLabel = '镜前三行 · 待机';
      patch.bigText = '还没触发';
      patch.bigNote = '看向镜子停稳 · TRIG 亮三行 · 逐行确认已读';
    } else if (this._mode === 'list') {
      patch.boxLabel = '◎ 镜前三行 — READ 确认当前行已读，END 结束';
      patch.bigLabel = '镜前三行 · 第 ' + (this._focus + 1) + '/3 行';
      patch.bigText = this._warned ? '未读 ' + unread.length + ' 行' : '已读 ' + n + '/3';
      patch.bigNote = this._warned
        ? '还没读 ' + unread.join('、') + ' · 再点 END 结束，未读记进小结（提醒，不是拦门）'
        : (unread.length === 0
          ? '三行都读了 · 可以出门了 · END 结束出小结 · BACK 回待机（已读保留）'
          : '还没读 ' + unread.join('、') + ' · END 先报未读');
    } else {
      patch.boxLabel = '◎ 本次镜前小结 — 已读、未读钉在下面';
      patch.bigLabel = '本次镜前小结';
      var s = this._summary || { read: 0, unread: [], warns: 0, allRead: false };
      patch.bigText = s.allRead ? '可以出门了' : '未读 ' + s.unread.length + ' 行';
      patch.bigNote = s.allRead
        ? '已读 3/3 · 报未读 ' + s.warns + ' 次 · 点 END 确认清空 · BACK 返回三行'
        : '未读 ' + s.unread.join('、') + ' · 已读 ' + s.read + '/3 · 报未读 ' + s.warns + ' 次 · 点 END 确认清空 · BACK 返回三行';
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
      <text class="title">CUE MIRROR v1.0.0</text>
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
      <button class="btn btn-main" bindtap="trigTap">TRIG</button>
      <button class="btn btn-main" bindtap="readTap">READ</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
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
    <text class="foot2">三行全部是你预设的（DEMO 轮换预设组）——没有天气接口、没有日历同步，天气要点不是实时天气，第一件事不是日程读取；昨日留给今早的一句话只存本次打开的会话内，关掉即清，想昨天留、今天看需跨日留存（由 GO 另行决定）；看向镜子只是看向你登记的镜子方向停稳触发，不是镜面识别；确认已读只是表态；没有室内定位；零落盘</text>
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
