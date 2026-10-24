<script def>
{
  "navigationBarTitleText": "Cue Fridge"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '冰箱提示 — 站在冰箱前发呆想不起来要拿什么：看向冰箱停稳才触发清单，拿一样勾一样，关门前报漏拿',
    steadyText: 'HEAD: moving - look at the fridge and hold still',
    boxLabel: '◎ 待拿清单 — 看向冰箱停稳，TRIG 触发清单',
    bigLabel: '待拿清单 · 待机',
    bigText: '还没触发',
    bigNote: '看向冰箱停稳 · TRIG 触发清单 · 关门前报漏拿',
    permLine: 'PERM: 无权限 — 只做待拿清单提醒；不拍照、不录音、不定位；勾掉只是表态，不是检测；缺货是你标的，不是盘点',
    rows: [],
    countLine: '已拿 0/5 · 缺货 0 项 · 漏拿 0 项 · 报漏拿 0 次 · 只存本次开冰箱会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - look at the fridge, hold steady, TRIG opens the checklist',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | list | summary
    this._names = ['牛奶', '鸡蛋', '面包', '水果', '酸奶'];
    // per-item state: 'none' | 'taken' | 'out'
    this._state = ['none', 'none', 'none', 'none', 'none'];
    this._focus = 0;
    this._triggered = false;
    this._warned = false;
    this._warns = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 triggered, 2-3 ticked, 4 out, 5 warned, 6 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the checklist, its ticks,
    // out marks, warnings and the summary die with the page.
    // Nothing was ever written anywhere persistent, so there
    // is nothing to clean up — that IS the design. A tick is
    // the wearer's own statement, never a sensor proof that
    // the item is actually in hand; an out mark is the
    // wearer's own report, never an inventory count.
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

  _takenCount() {
    var c = 0, i;
    for (i = 0; i < this._state.length; i++) { if (this._state[i] === 'taken') c++; }
    return c;
  },

  _outCount() {
    var c = 0, i;
    for (i = 0; i < this._state.length; i++) { if (this._state[i] === 'out') c++; }
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
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - look at the fridge and hold still'
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
      this.setData({ lastEvent: 'EVT: nod ignored - look at the fridge and hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod triggers the
    // checklist in idle, ticks the focused item in the list,
    // or confirms the summary. A nod never picks an item and
    // never closes the fridge on its own: closing is CLOSE.
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
        ? '待拿清单已触发（DEMO 示例）— 拿一样勾一样，关门前报漏拿'
        : '待拿清单已触发 — 拿一样勾一样，关门前报漏拿',
      lastEvent: demo ? 'EVT: DEMO stage 1 - checklist triggered (DEMO sample)' : 'EVT: checklist triggered - look confirmed at the fridge'
    });
    this._renderAll();
  },

  trigTap() {
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TRIG refused - the checklist is already open or a summary is up' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: TRIG refused - look at the fridge and hold steady first' });
      return;
    }
    this._trigger(false);
  },

  // ---------- tick / out / close ----------

  gotTap() {
    if (this._mode !== 'list') {
      this.setData({ lastEvent: 'EVT: GOT refused - tick items in the checklist, not in idle or summary' });
      return;
    }
    var st = this._state[this._focus];
    if (st === 'taken') {
      this.setData({ lastEvent: 'EVT: GOT refused - ' + this._names[this._focus] + ' already taken' });
      return;
    }
    if (st === 'out') {
      this.setData({ lastEvent: 'EVT: GOT refused - ' + this._names[this._focus] + ' marked out of stock, MISS to unmark first' });
      return;
    }
    this._state[this._focus] = 'taken';
    this._warned = false;
    var n = this._takenCount();
    this.setData({
      status: '已拿：' + this._names[this._focus] + '（' + n + '/5）— 继续拿剩下的，关门前报漏拿',
      lastEvent: 'EVT: taken - ' + this._names[this._focus] + ' (' + n + '/5)'
    });
    this._renderAll();
  },

  missTap() {
    if (this._mode !== 'list') {
      this.setData({ lastEvent: 'EVT: MISS refused - mark out of stock in the checklist, not in idle or summary' });
      return;
    }
    var st = this._state[this._focus];
    if (st === 'taken') {
      this.setData({ lastEvent: 'EVT: MISS refused - ' + this._names[this._focus] + ' already taken, out of stock does not apply' });
      return;
    }
    if (st === 'out') {
      this._state[this._focus] = 'none';
      this._warned = false;
      this.setData({
        status: '取消缺货：' + this._names[this._focus] + ' 回到待拿',
        lastEvent: 'EVT: out unmarked - ' + this._names[this._focus] + ' back to pending'
      });
    } else {
      this._state[this._focus] = 'out';
      this._warned = false;
      this.setData({
        status: '已标缺货：' + this._names[this._focus] + '（关门时不算漏拿）',
        lastEvent: 'EVT: marked out - ' + this._names[this._focus] + ' (not counted as missed)'
      });
    }
    this._renderAll();
  },

  closeTap() {
    if (this._mode === 'summary') {
      // In summary, CLOSE is the confirm: it wipes the round.
      // BACK is the way back to the checklist without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: CLOSE refused - missing: 先看向冰箱停稳触发清单（TRIG）' });
      return;
    }
    // list mode: the close warning. This is a REMINDER, not a
    // gate: the first CLOSE with pending items names them in
    // the banner and in one TTS utterance, counts the warning,
    // and stays in the list; the second CLOSE closes for real
    // and the missed items are recorded honestly in the
    // summary. An out-of-stock item never counts as missed.
    var missing = this._missing();
    if (missing.length > 0 && !this._warned) {
      this._warns++;
      this._warned = true;
      var line = '还没拿：' + missing.join('、') + '，关门前别忘了';
      this._speakText(line);
      this.setData({
        status: '关门前提醒 — ' + line,
        lastEvent: 'EVT: CLOSE warned - missed: ' + missing.join('、') + ' (warning ' + this._warns + ', reminder not a gate)'
      });
      this._renderAll();
      return;
    }
    this._mode = 'summary';
    this._summary = {
      taken: this._takenCount(),
      out: this._outCount(),
      missed: missing,
      warns: this._warns,
      allTaken: missing.length === 0
    };
    this.setData({
      status: missing.length === 0
        ? '本次开冰箱小结 — 都拿齐了，点 CLOSE 确认清空，BACK 返回清单'
        : '本次开冰箱小结 — 漏拿 ' + missing.join('、') + '，点 CLOSE 确认清空，BACK 返回清单',
      lastEvent: 'EVT: closed - summary ready (taken ' + this._summary.taken + '/5, out ' + this._summary.out + ', missed ' + missing.length + ')'
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
      status: '冰箱提示 — 站在冰箱前发呆想不起来要拿什么：看向冰箱停稳才触发清单，拿一样勾一样，关门前报漏拿',
      lastEvent: 'EVT: summary confirmed - checklist cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the checklist without
      // deleting anything; the summary is rebuilt on CLOSE.
      this._mode = 'list';
      this._summary = null;
      this.setData({
        status: '待拿清单 — 继续拿，或 CLOSE 关门',
        lastEvent: 'EVT: back to checklist - summary kept for rebuild on CLOSE'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'list') {
      // Back to idle keeps the ticks and out marks:
      // re-triggering restores the same checklist.
      this._mode = 'idle';
      this.setData({
        status: '冰箱提示 — 看向冰箱停稳，TRIG 再次触发清单（已拿/缺货保留）',
        lastEvent: 'EVT: back to idle - ticks and out marks kept'
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
      line = '还没触发：看向冰箱停稳，TRIG 触发清单';
    } else if (this._mode === 'list') {
      var missing = this._missing();
      if (this._warned) {
        line = '关门前提醒：还没拿 ' + missing.join('、');
      } else if (missing.length === 0) {
        line = '都拿齐了，可以关门';
      } else {
        line = '已拿 ' + this._takenCount() + '/5，还没拿 ' + missing.join('、');
      }
    } else if (this._summary) {
      line = '本次开冰箱小结：已拿 ' + this._summary.taken + '/5，缺货 ' + this._summary.out + ' 项，漏拿 ' + this._summary.missed.length + ' 项';
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
    if (this._mode === 'idle' && !this._demo && (this._takenCount() > 0 || this._outCount() > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user ticks are under way' });
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
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - 牛奶 taken (DEMO sample, 1/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._focus = 1;
      this.gotTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - 鸡蛋 taken (DEMO sample, 2/5)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._focus = 2;
      this.missTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - 面包 marked out (DEMO sample, not missed)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this.closeTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - CLOSE warned, missed 水果、酸奶 (DEMO sample, reminder not a gate)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this.closeTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - summary: taken 2, out 1, missed 水果、酸奶 (DEMO sample)' });
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
        detail: '看向冰箱停稳，TRIG 触发清单（预设：牛奶 / 鸡蛋 / 面包 / 水果 / 酸奶）',
        flag: '○',
        cls: 'row'
      });
    } else {
      for (i = 0; i < this._names.length; i++) {
        var detail = '';
        var flag = '';
        if (this._state[i] === 'taken') { detail = '已拿（你本人的表态，不是检测）'; flag = '✓'; }
        else if (this._state[i] === 'out') { detail = '缺货（你标的，不是盘点；关门不算漏拿）'; flag = '✕'; }
        else { detail = '还没拿'; flag = (this._focus === i ? '▶' : '○'); }
        rows.push({
          idx: i,
          name: this._names[i],
          detail: detail,
          flag: flag,
          cls: 'row'
        });
      }
    }

    var n = this._takenCount();
    var o = this._outCount();
    var missing = this._missing();
    var patch = { rows: rows };
    patch.countLine = '已拿 ' + n + '/5 · 缺货 ' + o + ' 项 · 漏拿 ' + missing.length + ' 项 · 报漏拿 ' + this._warns + ' 次 · 只存本次开冰箱会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 待拿清单 — 看向冰箱停稳，TRIG 触发清单';
      patch.bigLabel = '待拿清单 · 待机';
      patch.bigText = '还没触发';
      patch.bigNote = '看向冰箱停稳 · TRIG 触发清单 · 关门前报漏拿';
    } else if (this._mode === 'list') {
      patch.boxLabel = this._warned
        ? '◎ 关门前提醒 — 还没拿的在下面，再点 CLOSE 就关门（提醒，不是拦门）'
        : '◎ 待拿清单 — GOT 勾掉当前项，MISS 标缺货，CLOSE 关门';
      patch.bigLabel = '待拿清单 · 第 ' + (this._focus + 1) + '/5 项';
      patch.bigText = this._warned ? '漏拿 ' + missing.length + ' 项' : '已拿 ' + n + '/5';
      patch.bigNote = this._warned
        ? '还没拿 ' + missing.join('、') + ' · 再点 CLOSE 关门，漏拿记进小结'
        : (missing.length === 0 ? '都拿齐了 · CLOSE 关门出小结 · BACK 回待机（已拿/缺货保留）' : '还没拿 ' + missing.join('、') + ' · CLOSE 先报漏拿');
    } else {
      patch.boxLabel = '◎ 本次开冰箱小结 — 已拿、缺货、漏拿钉在下面';
      patch.bigLabel = '本次开冰箱小结';
      var s = this._summary || { taken: 0, out: 0, missed: [], warns: 0, allTaken: false };
      patch.bigText = s.allTaken ? '都拿齐了' : '漏拿 ' + s.missed.length + ' 项';
      patch.bigNote = '已拿 ' + s.taken + '/5 · 缺货 ' + s.out + ' 项 · 报漏拿 ' + s.warns + ' 次 · 点 CLOSE 确认清空 · BACK 返回清单';
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
      <text class="title">CUE FRIDGE v1.0.0</text>
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
      <button class="btn btn-main" bindtap="missTap">MISS</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
      <button class="btn btn-main" bindtap="closeTap">CLOSE</button>
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
    <text class="foot2">勾掉只是你本人的表态，不是传感器证明——Agent 不检测东西是不是真的拿在手里；它不是库存管理系统，缺货是你标的，不是 Agent 盘点的；只存本次开冰箱会话，关掉即清；没有室内定位；零落盘；看向触发在真机上由头部停稳判定，预览中由 DEMO 演示</text>
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
