<script def>
{
  "navigationBarTitleText": "Tomorrow Stage"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '明日备齐 — 明早要用的东西，今晚想不起来备，明早出门抓瞎：睡前逐件看向登记成位，明早出门按 CUE 逐项确认带齐',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 明日备齐 — REG 登记成位，CUE 早上确认，CONFIRM 确认带齐，END 出小结',
    bigLabel: '明日备齐 · 待机',
    bigText: '还没开始',
    bigNote: '睡前逐件看向停稳点 REG · 明早出门点 CUE 逐项确认带齐',
    permLine: 'PERM: 无权限 — 看向登记 + CUE 确认；不拍照、不录音、不定位',
    rows: [],
    countLine: '成位 0 件 · 已确认 0 件 · 缺失 0 件 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START begins staging, REG stages an item, CUE confirms in the morning, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | staging | cue | summary
    this._items = []; // {name, confirmed}
    this._presets = ['钥匙', '工牌', '雨伞', '水杯', '文件袋'];
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 staged 2, 2 staged 3, 3 cue 1 confirmed, 4 missing warning, 5 all confirmed
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the night staging and the
    // morning CUE are two phases of ONE open session. Close
    // the agent and the staged list is gone — this is not
    // overnight storage, and no storage API is ever called.
    this._mode = 'idle';
    this._items = [];
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
    // not take effect. The gate speaks only on an explicit
    // SPEAK tap or once when the morning CUE opens.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  _confirmedCount() {
    var n = 0;
    for (var i = 0; i < this._items.length; i++) if (this._items[i].confirmed) n++;
    return n;
  },

  _missingItems() {
    var out = [];
    for (var i = 0; i < this._items.length; i++) if (!this._items[i].confirmed) out.push(this._items[i].name);
    return out;
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
    // staging in idle and confirms the summary. A nod never
    // stages an item and never confirms one: staging comes
    // from looking steady and tapping REG, confirming from
    // standing with the item and tapping CONFIRM — a nod
    // must not invent either.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'staging') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a staged item, REG stages it' });
      return;
    }
    if (this._mode === 'cue') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a packed item, CONFIRM confirms it' });
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
      else if (this._mode === 'staging') this.regTap();
      else if (this._mode === 'cue') this.confirmTap();
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

  // ---------- start / reg / cue / confirm / end ----------

  startTap() {
    if (this._mode === 'staging') {
      this.setData({ lastEvent: 'EVT: START refused - already staging, REG stages the next item' });
      return;
    }
    if (this._mode === 'cue') {
      this.setData({ lastEvent: 'EVT: START refused - a morning CUE is running, CONFIRM confirms each item' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    this._mode = 'staging';
    this.setData({
      status: '成位中 — 睡前逐件看向停稳点 REG，成位满了明早点 CUE 逐项确认',
      lastEvent: 'EVT: staging started - look steady at an item, REG stages it'
    });
    this._renderAll();
  },

  _stageItem(item) {
    // The single seam for staging: the real REG path, DEMO
    // stages and the harness all land here, so the staging
    // rule is tested once, not per path.
    if (this._mode !== 'staging') return false;
    if (this._items.length >= 8) return false;
    this._items.push(item);
    this.setData({
      status: '成位中 — 已成位 ' + this._items.length + ' 件，继续看向停稳点 REG，明早点 CUE',
      lastEvent: 'EVT: item ' + item.name + ' staged - ' + this._items.length + ' total'
    });
    this._renderAll();
    return true;
  },

  _nextPresetName() {
    var n = this._items.length;
    if (n < this._presets.length) return this._presets[n];
    return '物品' + (n + 1);
  },

  regTap() {
    if (this._mode !== 'staging') {
      this.setData({ lastEvent: 'EVT: REG ignored - START begins staging first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: REG refused - hold steady at the item first' });
      return;
    }
    if (this._items.length >= 8) {
      this.setData({ lastEvent: 'EVT: REG refused - 8 items already, CUE confirms them in the morning' });
      return;
    }
    // Staging records that you looked steady at the item — it
    // does not verify the item itself: the agent cannot see
    // whether the keys are really there, only that you looked
    // steady and tapped REG.
    this._stageItem({ name: this._nextPresetName(), confirmed: false });
  },

  cueTap() {
    if (this._mode === 'cue') {
      this.setData({ lastEvent: 'EVT: CUE refused - already confirming, CONFIRM confirms each item' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: CUE refused - a summary is open, END confirms it first' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: CUE refused - missing: 先 START 成位物品' });
      return;
    }
    this._mode = 'cue';
    this._focus = 0;
    this._speakText('早上确认：' + this._items.length + ' 件待确认，第一件' + this._items[0].name);
    this.setData({
      status: '早上确认中 — 逐项确认带齐，每项点 CONFIRM，全部确认才可以出门',
      lastEvent: 'EVT: cue started - ' + this._items.length + ' items to confirm (one TTS)'
    });
    this._renderAll();
  },

  confirmTap() {
    if (this._mode !== 'cue') {
      this.setData({ lastEvent: 'EVT: CONFIRM ignored - CUE starts the morning check first' });
      return;
    }
    var item = this._items[this._focus];
    if (!item) {
      this.setData({ lastEvent: 'EVT: CONFIRM ignored - no item focused' });
      return;
    }
    if (item.confirmed) {
      this.setData({ lastEvent: 'EVT: CONFIRM refused - ' + item.name + ' already confirmed' });
      return;
    }
    item.confirmed = true;
    this.setData({
      lastEvent: 'EVT: confirmed ' + item.name + ' - ' + this._confirmedCount() + '/' + this._items.length + ' packed'
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
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 成位物品' });
      return;
    }
    // The gate: with anything missing, END never says you may
    // leave — it warns and names the missing items. Only when
    // every staged item is confirmed does the summary say
    // 可以出门. The gate does not stop you leaving: the final
    // decision is always yours.
    var missing = this._missingItems();
    this._backMode = this._mode;
    this._mode = 'summary';
    this._summary = {
      staged: this._items.length,
      confirmed: this._confirmedCount(),
      missing: missing,
      mayLeave: missing.length === 0 && this._items.length > 0
    };
    this.setData({
      status: this._summary.mayLeave ? '可以出门 — 全部 ' + this._items.length + ' 件已确认，点 END 确认清空，BACK 回去' : '还没带齐 — 缺：' + missing.join('、') + '，点 END 确认清空，BACK 回去确认',
      lastEvent: 'EVT: closed - staged ' + this._items.length + ' confirmed ' + this._confirmedCount() + ' missing ' + missing.length + ' mayLeave ' + this._summary.mayLeave
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._items = [];
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '明日备齐 — 下次睡前再 START 成位物品',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the mode it came
      // from without deleting anything; the summary is
      // rebuilt on END.
      this._mode = this._backMode || 'staging';
      this._summary = null;
      this.setData({
        status: '回到确认 — BACK 回来不删东西，小结待重建',
        lastEvent: 'EVT: back from summary - session kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'staging' || this._mode === 'cue') {
      // Back to idle keeps the session; START resumes the
      // same round instead of resetting it.
      this._mode = 'idle';
      this.setData({
        status: '明日备齐 — 已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins staging first' });
  },

  _focusLen() {
    return Math.max(1, this._items.length);
  },

  nextTap() {
    var n = this._focusLen();
    this._focus = (this._focus + 1) % n;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
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
      line = '还没开始：START 成位物品';
    } else if (this._mode === 'staging') {
      line = '成位中，已成位 ' + this._items.length + ' 件';
    } else if (this._mode === 'cue') {
      var cur = this._items[this._focus];
      line = '早上确认：' + (cur ? cur.name : '') + (cur && cur.confirmed ? '已确认' : '未确认') + '，已确认 ' + this._confirmedCount() + '/' + this._items.length + ' 件';
    } else if (this._summary) {
      line = this._summary.mayLeave ? '可以出门：全部 ' + this._summary.staged + ' 件已确认' : '还没带齐：缺 ' + this._summary.missing.join('、');
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    // DEMO stage 4 leaves a summary open; DEMO must continue
    // from it to stage 5, so the summary check comes after
    // the stage-4 continuation, not before it.
    if (this._demo && this._demoStage === 4 && this._mode === 'summary') {
      this._demoStage = 5;
      this.backTap();
      // Confirm the two remaining items, then END: the gate
      // now says 可以出门.
      this._focus = 1;
      this.confirmTap();
      this._focus = 2;
      this.confirmTap();
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - summary: staged 3, confirmed 3, may leave (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && this._items.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      // DEMO is a staged sample, not a live night: items and
      // confirmations are staged values, not sensor readings.
      this._mode = 'staging';
      this._stageItem({ name: '钥匙', confirmed: false });
      this._stageItem({ name: '工牌', confirmed: false });
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - staged 2 items (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._stageItem({ name: '雨伞', confirmed: false });
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - staged 3 items (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this.cueTap();
      this._focus = 0;
      this.confirmTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - cue: 1 confirmed of 3 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - summary: missing 工牌、雨伞, mayLeave false (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    if (this._items.length === 0) {
      rows.push({ idx: 0, name: '还没成位', detail: '睡前逐件看向停稳点 REG', flag: '▶', cls: 'row' });
    } else {
      for (var i = 0; i < this._items.length; i++) {
        var it = this._items[i];
        var mark = '';
        if (this._mode === 'cue' && this._focus === i) mark = ' · 当前';
        rows.push({
          idx: i,
          name: it.name,
          detail: (it.confirmed ? '已确认' : '未确认') + mark,
          flag: (this._focus === i ? '▶' : '●'),
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    var conf = this._confirmedCount();
    var miss = this._items.length - conf;
    patch.countLine = '成位 ' + this._items.length + ' 件 · 已确认 ' + conf + ' 件 · 缺失 ' + miss + ' 件 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 明日备齐 — REG 登记成位，CUE 早上确认，CONFIRM 确认带齐，END 出小结';
      patch.bigLabel = '明日备齐 · 待机';
      patch.bigText = (this._items.length > 0) ? '已停未清' : '还没开始';
      patch.bigNote = '睡前逐件看向停稳点 REG · 明早出门点 CUE 逐项确认带齐';
    } else if (this._mode === 'staging') {
      patch.boxLabel = '◎ 成位中 — 已成位 ' + this._items.length + ' 件';
      patch.bigLabel = '明日备齐 · 成位中';
      patch.bigText = '成位 ' + this._items.length + ' 件';
      patch.bigNote = '继续看向停稳点 REG · 明早点 CUE';
    } else if (this._mode === 'cue') {
      var cur = this._items[this._focus];
      patch.boxLabel = '◎ 早上确认中 — 已确认 ' + conf + '/' + this._items.length + ' 件';
      patch.bigLabel = '明日备齐 · 早上确认';
      patch.bigText = cur ? cur.name : '待确认';
      patch.bigNote = (cur && cur.confirmed ? '已确认' : '未确认') + ' · CONFIRM 确认带齐 · 全部确认才可以出门';
    } else {
      patch.boxLabel = '◎ 本次小结 — 成位几件、确认几件、缺失几件钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { staged: 0, confirmed: 0, missing: [], mayLeave: false };
      patch.bigText = sm.mayLeave ? '可以出门' : '还没带齐';
      patch.bigNote = '成位 ' + sm.staged + ' 件 · 已确认 ' + sm.confirmed + ' 件' + (sm.mayLeave ? '' : ' · 缺：' + sm.missing.join('、')) + ' · 点 END 确认清空 · BACK 回去';
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
      <text class="title">TOMORROW STAGE v1.0.0</text>
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
      <button class="btn btn-main" bindtap="regTap">REG</button>
      <button class="btn btn-main" bindtap="cueTap">CUE</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="confirmTap">CONFIRM</button>
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
    <text class="foot2">夜里成位与早上 CUE 是同一打开会话内的两段流程，关掉即清，不是跨夜存档——跨夜存档需要 GO 决定是否破例，绝不悄悄加存储 · 看向停稳只是登记，不是验证物品本身，它看不出钥匙是不是真在那 · 门不阻止出门，门只是不说可以出门并点名缺失项，最终决定在你 · 没有室内定位 · 没有摄像头 · 只存本次会话 · 零落盘</text>
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
