<script def>
{
  "navigationBarTitleText": "Cue Door"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '出门提示 — 出门忘带是日常：看向大门停稳才触发清单，逐项确认，全过才放行',
    steadyText: 'HEAD: moving - look at the door and hold still',
    boxLabel: '◎ 出门清单 — 看向大门停稳，TRIG 触发清单',
    bigLabel: '出门清单 · 待机',
    bigText: '还没触发',
    bigNote: '看向大门停稳 · TRIG 触发清单 · 全过才放行',
    permLine: 'PERM: 无权限 — 只做清单确认门；不拍照、不录音、不定位；确认只是表态，不是检测',
    rows: [],
    countLine: '已确认 0/5 · 缺 5 项 · 喊停 0 次 · 只存本次出门会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look at the door, hold steady, TRIG opens the checklist',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | list | summary
    this._names = ['钥匙', '手机', '钱包', '工牌', '雨伞'];
    this._done = [false, false, false, false, false];
    this._focus = 0;
    this._triggered = false;
    this._blocks = 0;
    this._released = false;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 triggered, 2-3 partial, 4 blocked, 5-7 confirmed, 8 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the checklist, its
    // confirmations and the block count die with the page.
    // Nothing was ever written anywhere persistent, so there
    // is nothing to clean up — that IS the design. A
    // confirmation is the wearer's own statement, never a
    // sensor proof that the item is actually packed.
    this._mode = 'idle';
    this._done = [false, false, false, false, false];
    this._focus = 0;
    this._triggered = false;
    this._blocks = 0;
    this._released = false;
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
      if (!this._done[i]) m.push(this._names[i]);
    }
    return m;
  },

  _confirmedCount() {
    var c = 0, i;
    for (i = 0; i < this._done.length; i++) { if (this._done[i]) c++; }
    return c;
  },

  _allDone() { return this._confirmedCount() === this._names.length; },

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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - look at the door and hold still'
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
      this.setData({ lastEvent: 'EVT: nod ignored - look at the door and hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod triggers the
    // checklist in idle, confirms the focused item in the
    // list, or confirms the summary. A nod never picks an
    // item and never releases the door on its own: release
    // needs every item confirmed first.
    if (this._mode === 'idle') { this.trigTap(); return; }
    if (this._mode === 'list') { this.confTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.trigTap();
      else if (this._mode === 'list') this.confTap();
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
        ? '出门清单已触发（DEMO 示例）— 逐项确认，全过才放行'
        : '出门清单已触发 — 逐项确认，全过才放行',
      lastEvent: demo ? 'EVT: DEMO stage 1 - checklist triggered (DEMO sample)' : 'EVT: checklist triggered - look confirmed at the door'
    });
    this._renderAll();
  },

  trigTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TRIG refused - the checklist is already open or a summary is up' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: TRIG refused - look at the door and hold steady first' });
      return;
    }
    this._trigger(false);
  },

  // ---------- confirm / gate ----------

  confTap() {
    if (this._mode !== 'list') {
      this.setData({ lastEvent: 'EVT: CONF refused - confirm items in the checklist, not in idle or summary' });
      return;
    }
    if (this._done[this._focus]) {
      this.setData({ lastEvent: 'EVT: CONF refused - ' + this._names[this._focus] + ' already confirmed' });
      return;
    }
    this._done[this._focus] = true;
    var n = this._confirmedCount();
    this.setData({
      status: this._allDone()
        ? '全过 — 可以出门，END 出小结'
        : '已确认：' + this._names[this._focus] + '（' + n + '/5）— 继续确认剩下的',
      lastEvent: 'EVT: confirmed - ' + this._names[this._focus] + ' (' + n + '/5)'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the round.
      // BACK is the way back to the checklist without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先看向大门停稳触发清单（TRIG）' });
      return;
    }
    // list mode: the gate. Unconfirmed items block, and the
    // block names them out loud — it never says "可以出门"
    // while anything is missing.
    var missing = this._missing();
    if (missing.length > 0) {
      this._blocks++;
      var line = '还缺：' + missing.join('、') + '，别出门';
      this._speakText(line);
      this.setData({
        status: '喊停 — ' + line,
        lastEvent: 'EVT: END blocked - missing: ' + missing.join('、') + ' (block ' + this._blocks + ')'
      });
      this._renderAll();
      return;
    }
    this._mode = 'summary';
    this._released = true;
    this._summary = {
      confirmed: this._confirmedCount(),
      missing: [],
      blocks: this._blocks,
      released: true
    };
    this.setData({
      status: '本次出门小结 — 全过放行，点 END 确认清空，BACK 返回清单',
      lastEvent: 'EVT: released - summary ready (5/5 confirmed, blocks ' + this._blocks + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._done = [false, false, false, false, false];
    this._focus = 0;
    this._triggered = false;
    this._blocks = 0;
    this._released = false;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '出门提示 — 出门忘带是日常：看向大门停稳才触发清单，逐项确认，全过才放行',
      lastEvent: 'EVT: summary confirmed - checklist cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the checklist without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'list';
      this._summary = null;
      this._released = false;
      this.setData({
        status: '出门清单 — 继续确认，或 END 出小结',
        lastEvent: 'EVT: back to checklist - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'list') {
      // Back to idle keeps the confirmations: re-triggering
      // restores the same checklist, nothing is lost.
      this._mode = 'idle';
      this.setData({
        status: '出门提示 — 看向大门停稳，TRIG 再次触发清单（确认保留）',
        lastEvent: 'EVT: back to idle - confirmations kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - TRIG triggers the checklist' });
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
      line = '还没触发：看向大门停稳，TRIG 触发清单';
    } else if (this._mode === 'list') {
      var missing = this._missing();
      line = this._allDone()
        ? '全过，可以出门'
        : '已确认 ' + this._confirmedCount() + '/5，还缺 ' + missing.join('、');
    } else if (this._summary) {
      line = '本次出门小结：确认 ' + this._summary.confirmed + '/5，喊停 ' + this._summary.blocks + ' 次，' +
        (this._summary.released ? '已放行' : '未放行');
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
      this.setData({ lastEvent: 'EVT: DEMO refused - a user checklist is under way' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._confirmedCount() > 0) {
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
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 钥匙 confirmed (DEMO sample, 1/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._focus = 1;
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 手机 confirmed (DEMO sample, 2/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - END blocked, missing 钱包、工牌、雨伞 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this._focus = 2;
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - 钱包 confirmed (DEMO sample, 3/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this._focus = 3;
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - 工牌 confirmed (DEMO sample, 4/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this._focus = 4;
      this.confTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - 雨伞 confirmed (DEMO sample, 5/5, 可以出门)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 7) {
      this._demoStage = 8;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 8 - summary released 5/5 (DEMO sample)' });
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
        detail: '看向大门停稳，TRIG 触发清单（预设：钥匙 / 手机 / 钱包 / 工牌 / 雨伞）',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._names.length; i++) {
        rows.push({
          idx: i,
          name: this._names[i],
          detail: this._done[i] ? '已确认（你本人的表态，不是检测）' : '未确认',
          flag: this._done[i] ? '✓' : (this._focus === i ? '▶' : '○'),
          cls: 'row'
        });
      }
    }

    var n = this._confirmedCount();
    var missing = this._missing();
    var patch = { rows: rows };
    patch.countLine = '已确认 ' + n + '/5 · 缺 ' + missing.length + ' 项 · 喊停 ' + this._blocks + ' 次 · 只存本次出门会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 出门清单 — 看向大门停稳，TRIG 触发清单';
      patch.bigLabel = '出门清单 · 待机';
      patch.bigText = '还没触发';
      patch.bigNote = '看向大门停稳 · TRIG 触发清单 · 全过才放行';
    } else if (this._mode === 'list') {
      patch.boxLabel = '◎ 出门清单 — CONF 确认当前项，全过才放行';
      patch.bigLabel = '出门清单 · 第 ' + (this._focus + 1) + '/5 项';
      patch.bigText = this._allDone() ? '可以出门' : '已确认 ' + n + '/5';
      patch.bigNote = this._allDone()
        ? '全过 · END 出小结 · BACK 回待机（确认保留）'
        : '还缺 ' + missing.join('、') + ' · END 未全过会喊停';
    } else {
      patch.boxLabel = '◎ 本次出门小结 — 确认数、缺项数、是否放行钉在下面';
      patch.bigLabel = '本次出门小结';
      var s = this._summary || { confirmed: 0, blocks: 0, released: false };
      patch.bigText = s.released ? '可以出门' : '未放行 · 缺 ' + (5 - s.confirmed) + ' 项';
      patch.bigNote = '确认 ' + s.confirmed + '/5 · 喊停 ' + s.blocks + ' 次 · 点 END 确认清空 · BACK 返回清单';
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
      <text class="title">CUE DOOR v1.0.0</text>
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
      <button class="btn btn-main" bindtap="confTap">CONF</button>
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
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
    <text class="foot2">确认只是你本人的表态，不是传感器证明——Agent 不检测东西是不是真的在包里；它不是防丢设备，不能保证出门不忘带；只存本次出门会话，关掉即清；没有室内定位；零落盘；看向触发在真机上由头部停稳判定，预览中由 DEMO 演示</text>
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
