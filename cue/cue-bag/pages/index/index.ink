<script def>
{
  "navigationBarTitleText": "Cue Bag"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '换包提示 — 换包/换外套出门，东西总落在上一个包里：看向今天要背的包停稳才触发按目的地清单，逐项看向包内格层确认装入',
    steadyText: 'HEAD: moving - look at today\'s bag and hold still',
    boxLabel: '◎ 今日装包清单 · 通勤 — 看向今天要背的包停稳，TRIG 触发清单',
    bigLabel: '今日装包 · 待机',
    bigText: '还没触发',
    bigNote: '看向今天要背的包停稳 · TRIG 触发清单 · 提前结束报漏装',
    permLine: 'PERM: 无权限 — 只做换包装包提醒；不拍照、不录音、不定位；确认装入只是表态，不是检测；格层只是分组标注，不是包内实测位置',
    rows: [],
    countLine: '已装 0/5 · 未装 5 项 · 报漏 0 次 · 只存本次换包会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look at today\'s bag, hold steady, TRIG lights up the packing list',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | list | summary
    this._names = ['钥匙', '手机', '钱包', '工牌', '耳机'];
    this._comps = ['主袋', '侧袋', '内袋', '侧袋', '内袋'];
    // per-item state: 'none' | 'packed'
    this._state = ['none', 'none', 'none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 triggered, 2-3 packed, 4 warned, 5 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the packing list, its
    // confirmations, the warning count and the summary die
    // with the page. Nothing was ever written anywhere
    // persistent, so there is nothing to clean up — that IS
    // the design. Confirming packed is the wearer's own
    // statement, never a sensor proof; compartments are list
    // group labels, never measured positions in the bag.
    this._mode = 'idle';
    this._state = ['none', 'none', 'none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _now() { return Date.now(); },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _missing() {
    var m = [], i;
    for (i = 0; i < this._names.length; i++) {
      if (this._state[i] === 'none') m.push(this._names[i]);
    }
    return m;
  },

  _packedCount() {
    var c = 0, i;
    for (i = 0; i < this._state.length; i++) { if (this._state[i] === 'packed') c++; }
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - look at today\'s bag and hold still'
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
      this.setData({ lastEvent: 'EVT: nod ignored - look at the bag and hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod triggers the
    // packing list in idle, confirms the focused item in the
    // list, or confirms the summary. A nod never picks an
    // item and never closes the round on its own: closing
    // early is END.
    if (this._mode === 'idle') { this.trigTap(); return; }
    if (this._mode === 'list') { this.gotTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.trigTap();
      else if (this._mode === 'list') this.gotTap();
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
    this._mode = 'list';
    this._triggered = true;
    this._focus = 0;
    this.setData({
      status: demo
        ? '今日装包清单已触发（DEMO 示例，目的地：通勤）— 逐项看向格层确认装入，提前结束报漏装'
        : '今日装包清单已触发 — 逐项看向格层确认装入，提前结束报漏装',
      lastEvent: demo ? 'EVT: DEMO stage 1 - packing list lit (DEMO sample)' : 'EVT: packing list lit - look confirmed at today\'s bag'
    });
    this._renderAll();
  },

  trigTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TRIG refused - the list is already lit or a summary is up' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: TRIG refused - look at the bag and hold steady first' });
      return;
    }
    this._trigger(false);
  },

  // ---------- pack / close early ----------

  gotTap() {
    if (this._mode !== 'list') {
      this.setData({ lastEvent: 'EVT: GOT refused - confirm items in the list, not in idle or summary' });
      return;
    }
    var st = this._state[this._focus];
    if (st === 'packed') {
      this.setData({ lastEvent: 'EVT: GOT refused - ' + this._names[this._focus] + ' already packed' });
      return;
    }
    this._state[this._focus] = 'packed';
    // A warning names a moment's missing set; a changed list
    // deserves a fresh warning, not a stale one.
    this._warned = false;
    var n = this._packedCount();
    this.setData({
      status: '已装：' + this._names[this._focus] + '（' + this._comps[this._focus] + '，' + n + '/5）— 继续装剩下的，提前结束报漏装',
      lastEvent: 'EVT: packed - ' + this._names[this._focus] + ' (' + this._comps[this._focus] + ', ' + n + '/5)'
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
      this.setData({ lastEvent: 'EVT: END refused - missing: 先看向今天要背的包停稳触发清单（TRIG）' });
      return;
    }
    // list mode: closing early is a reminder, never a gate.
    // The first END with missing items names them in the
    // banner and in one TTS utterance, counts the warning,
    // and stays in the list; the second END closes for real
    // and the missing items are recorded honestly in the
    // summary. Packing happens at home where you can still
    // turn back and fetch — a warning that pretended to
    // block would be a lie about what happens next. This is
    // the deliberate opposite of cue-door (CU01), where an
    // unconfirmed END blocks.
    var missing = this._missing();
    if (missing.length > 0 && !this._warned) {
      this._warned = true;
      this._warns++;
      var line = '还没装 ' + missing.join('、') + '，再点 END 就结束（提醒，不是拦门）';
      this._speakText(line);
      this.setData({
        status: '提前结束提醒 — ' + line,
        lastEvent: 'EVT: END warned - missing: ' + missing.join('、') + ' (warning ' + this._warns + ', reminder not a gate)'
      });
      this._renderAll();
      return;
    }
    this._mode = 'summary';
    var allPacked = missing.length === 0;
    this._summary = {
      packed: this._packedCount(),
      missing: missing,
      warns: this._warns,
      allPacked: allPacked
    };
    this.setData({
      status: allPacked
        ? '结束 — 都装好了，点 END 确认清空，BACK 返回清单'
        : '结束 — 未装 ' + missing.join('、') + '，点 END 确认清空，BACK 返回清单',
      lastEvent: allPacked
        ? 'EVT: closed - all packed (warning ' + this._warns + ')'
        : 'EVT: closed - missing: ' + missing.join('、') + ' (warning ' + this._warns + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._state = ['none', 'none', 'none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '换包提示 — 换包/换外套出门，东西总落在上一个包里：看向今天要背的包停稳才触发按目的地清单，逐项看向包内格层确认装入',
      lastEvent: 'EVT: summary confirmed - packing list cleared'
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
        status: '今日装包清单 — 继续装，或 END 结束',
        lastEvent: 'EVT: back to list - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'list') {
      // Back to idle keeps the confirmations:
      // re-triggering restores the same packing list.
      this._mode = 'idle';
      this.setData({
        status: '换包提示 — 看向今天要背的包停稳，TRIG 再次触发清单（已装保留）',
        lastEvent: 'EVT: back to idle - confirmations kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - TRIG lights up the packing list' });
  },

  _focusLen() {
    if (this._mode === 'idle') return 0;
    return this._names.length;
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
      line = '还没触发：看向今天要背的包停稳，TRIG 触发清单';
    } else if (this._mode === 'list') {
      var missing = this._missing();
      if (this._warned) {
        line = '还没装 ' + missing.join('、') + '，再点 END 就结束';
      } else if (missing.length === 0) {
        line = '都装好了，可以结束';
      } else {
        line = '已装 ' + this._packedCount() + '/5，还没装 ' + missing.join('、');
      }
    } else if (this._summary) {
      line = this._summary.allPacked
        ? '本次换包小结：都装好了'
        : '本次换包小结：已装 ' + this._summary.packed + '/5，未装 ' + this._summary.missing.join('、');
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary' && this._demoStage !== 4) {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user packing list is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._packedCount() > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user confirmations are under way' });
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
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 钥匙 packed (DEMO sample, 1/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._focus = 1;
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 手机 packed (DEMO sample, 2/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - END warned, missing 钱包、工牌、耳机 (DEMO sample, reminder not a gate)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: packed 2 / missing 3 (DEMO sample)' });
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
        detail: '看向今天要背的包停稳，TRIG 触发清单（目的地：通勤，预设示例）',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._names.length; i++) {
        var detail = '';
        var flag = '';
        if (this._state[i] === 'packed') { detail = this._comps[i] + ' · 已装（你本人的表态，不是检测）'; flag = '✓'; }
        else { detail = this._comps[i] + ' · 还没装'; flag = (this._focus === i ? '▶' : '○'); }
        rows.push({
          idx: i,
          name: this._names[i],
          detail: detail,
          flag: flag,
          cls: 'row'
        });
      }
    }

    var n = this._packedCount();
    var missing = this._missing();
    var patch = { rows: rows };
    patch.countLine = '已装 ' + n + '/5 · 未装 ' + missing.length + ' 项 · 报漏 ' + this._warns + ' 次 · 只存本次换包会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 今日装包清单 · 通勤 — 看向今天要背的包停稳，TRIG 触发清单';
      patch.bigLabel = '今日装包 · 待机';
      patch.bigText = '还没触发';
      patch.bigNote = '看向今天要背的包停稳 · TRIG 触发清单 · 提前结束报漏装';
    } else if (this._mode === 'list') {
      patch.boxLabel = '◎ 今日装包清单 · 通勤 — GOT 确认装入当前项，END 结束';
      patch.bigLabel = '今日装包 · 第 ' + (this._focus + 1) + '/5 项';
      patch.bigText = this._warned ? '未装 ' + missing.length + ' 项' : '已装 ' + n + '/5';
      patch.bigNote = this._warned
        ? '还没装 ' + missing.join('、') + ' · 再点 END 结束，报漏记进小结（提醒，不是拦门）'
        : (missing.length === 0
          ? '都装好了 · END 结束出小结 · BACK 回待机（已装保留）'
          : '还没装 ' + missing.join('、') + ' · END 先报漏装');
    } else {
      patch.boxLabel = '◎ 本次换包小结 — 已装、未装钉在下面';
      patch.bigLabel = '本次换包小结';
      var s = this._summary || { packed: 0, missing: [], warns: 0, allPacked: false };
      patch.bigText = s.allPacked ? '都装好了' : '未装 ' + s.missing.length + ' 项';
      patch.bigNote = s.allPacked
        ? '已装 5/5 · 报漏 ' + s.warns + ' 次 · 点 END 确认清空 · BACK 返回清单'
        : '未装 ' + s.missing.join('、') + ' · 已装 ' + s.packed + '/5 · 报漏 ' + s.warns + ' 次 · 点 END 确认清空 · BACK 返回清单';
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
      <text class="title">CUE BAG v1.0.0</text>
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
      <button class="btn btn-main" bindtap="gotTap">GOT</button>
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
    <text class="foot2">确认装入只是你本人的表态，不是传感器证明——Agent 不检测东西是不是真的在包里；格层只是清单分组标注，不是包内实测位置；只存本次换包会话，关掉即清；没有室内定位；零落盘；看向触发在真机上由头部停稳判定，预览中由 DEMO 演示</text>
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
