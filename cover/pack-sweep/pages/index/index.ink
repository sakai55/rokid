<script def>
{
  "navigationBarTitleText": "Pack Sweep"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '行李清点 — 逐件看向确认已装，出门前小结有未装项绝不报行李齐了',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 未载入清单 — DEMO 载入示例清单',
    bigLabel: '当前项 · —',
    bigText: '未载入清单',
    bigNote: 'DEMO 载入示例清单 · 看向一件点 PACK 确认已装',
    permLine: 'PERM: none — 不用相机/麦克风/定位，只用头部朝向确认',
    rows: [],
    countLine: '已装 0/0 · 未装 0 · 只存本次会话内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - load a list, then pack item by item',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | pack | summary
    this._items = []; // { name, note, state: 'todo'|'packed', src: null|'DEMO'|'USER' }
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1: list loaded, 2: 3 packed, 3: summary blocked, 4: summary complete
    this._summaryComplete = false;
    this._clearArm = false;
    this._clearTimer = null;
    this._nodLock = false;
    this._spare = 0;
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the list, the packed marks and
    // the spare counter die with the page. Nothing was ever written
    // to any storage, so there is nothing to clean up - that IS the
    // design. Close the agent and the packing proof is gone, which
    // is the correct use for a bag you are packing right now.
    this._items = [];
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0;
    this._spare = 0;
    if (this._clearTimer) { try { clearTimeout(this._clearTimer); } catch (e) {} this._clearTimer = null; }
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
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Nod discipline in THIS agent: a steady nod means ONE thing -
    // "this item is packed" - and only in pack mode on the focused
    // item. It never loads a list, never finishes packing, never
    // clears anything, and is inert on the summary screen and
    // before any list is loaded.
    if (this._mode === 'pack') {
      this._packItem('NOD');
      return;
    }
    this.setData({ lastEvent: 'EVT: nod ignored - nod only packs an item in pack mode' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.packTap();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.prevTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  // The sample list used by DEMO only. Eight everyday items, short
  // enough to tick off at a glance on the 480x352 canvas.
  _demoItems() {
    return [
      { name: '证件', note: '护照 / 身份证' },
      { name: '钱包', note: '现金 / 卡' },
      { name: '手机充电器', note: '线 + 插头' },
      { name: '药', note: '常用药 / 处方药' },
      { name: '钥匙', note: '家门 / 车钥匙' },
      { name: '水杯', note: '空杯可过安检' },
      { name: '换洗衣物', note: '按天数' },
      { name: '雨伞', note: '折叠伞' }
    ];
  },

  _spareItems() {
    return [
      { name: '耳机', note: '有线 / 无线' },
      { name: '充电宝', note: '满电' },
      { name: '纸巾', note: '一包' },
      { name: '笔记本', note: '纸质 / 平板' },
      { name: '墨镜', note: '晴天用' }
    ];
  },

  _countPacked() {
    var n = 0;
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'packed') n++;
    return n;
  },

  _countTodo() {
    var n = 0;
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'todo') n++;
    return n;
  },

  _allPacked() {
    return this._items.length > 0 && this._countTodo() === 0;
  },

  _firstTodo() {
    for (var i = 0; i < this._items.length; i++) if (this._items[i].state === 'todo') return i;
    return -1;
  },

  _todoText() {
    var parts = [];
    for (var i = 0; i < this._items.length; i++) {
      if (this._items[i].state === 'todo') parts.push(this._items[i].name);
    }
    return parts.join('、');
  },

  _disarm() {
    this._clearArm = false;
    if (this._clearTimer) { try { clearTimeout(this._clearTimer); } catch (e) {} this._clearTimer = null; }
  },

  _armClear() {
    this._disarm();
    this._clearArm = true;
    var self = this;
    this._clearTimer = setTimeout(function () {
      self._clearTimer = null;
      if (self._clearArm) {
        self._clearArm = false;
        self.setData({ lastEvent: 'EVT: clear disarmed (timeout) - list kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _clearAll() {
    this._items = [];
    this._focus = 0;
    this._demo = false;
    this._demoStage = 0;
    this._spare = 0;
    this._disarm();
    this._mode = 'idle';
    this.setData({
      status: '已清空 — 重新载入清单',
      lastEvent: 'EVT: list cleared by two-step DEL - session memory wiped'
    });
    this._renderAll();
  },

  _setItems(raws, src) {
    this._items = raws.map(function (r) {
      return { name: r.name, note: r.note, state: 'todo', src: src };
    });
    this._focus = 0;
    this._mode = 'pack';
    this._renderAll();
  },

  // ---------- pack / uncheck / delete: the ONLY ways an item changes ----------

  _packItem(how) {
    if (this._mode !== 'pack' || this._items.length === 0) return;
    var it = this._items[this._focus];
    if (!it) return;
    if (it.state === 'packed') {
      this.setData({ lastEvent: 'EVT: ' + how + ' - item already packed, NEXT moves on' });
      return;
    }
    var justPacked = this._focus;
    it.state = 'packed';
    if (!it.src) it.src = this._demo ? 'DEMO' : 'USER';
    this._disarm();
    var next = this._firstTodo();
    if (next >= 0) this._focus = next;
    this.setData({
      status: '已装：' + it.name + ' — ' +
        (this._allPacked() ? '全部装好，点 FIN 看小结' : '已装 ' + this._countPacked() + '/' + this._items.length),
      lastEvent: 'EVT: item ' + (justPacked + 1) + ' packed by ' + how
    });
    this._renderAll();
  },

  _delFocused() {
    if (this._mode !== 'pack' || this._items.length === 0) return;
    var it = this._items[this._focus];
    if (!it) return;
    if (it.state === 'packed') {
      // Correction, not destruction: a packed item goes back to todo.
      it.state = 'todo';
      this._disarm();
      this.setData({
        status: '已取消：' + it.name + ' 回到未装',
        lastEvent: 'EVT: item ' + (this._focus + 1) + ' unchecked by DEL'
      });
    } else {
      // Deleting a todo item removes it from this packing session.
      var name = it.name;
      this._items.splice(this._focus, 1);
      if (this._focus >= this._items.length) this._focus = Math.max(0, this._items.length - 1);
      this._disarm();
      if (this._items.length === 0) {
        this._mode = 'idle';
        this._demo = false;
        this._demoStage = 0;
      }
      this.setData({
        status: '已删除：' + name + ' — 本次行李不再清点它',
        lastEvent: 'EVT: item deleted by DEL - ' + name
      });
    }
    this._renderAll();
  },

  _toSummary() {
    this._disarm();
    this._mode = 'summary';
    this._summaryComplete = this._countTodo() === 0;
    if (this._summaryComplete) {
      this._speakText('行李齐了，可以出门了');
      this.setData({
        status: '行李齐了 ✓ 可以出门了',
        lastEvent: 'EVT: summary complete ' + this._items.length + '/' + this._items.length
      });
    } else {
      this._speakText('还有没装的：' + this._todoText());
      this.setData({
        status: '还有没装的：' + this._todoText() + ' — 点 PACK 回去接着装',
        lastEvent: 'EVT: summary blocked - todo: ' + this._todoText() + ' (never reported ready)'
      });
    }
    this._renderAll();
  },

  // ---------- buttons ----------

  packTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      // Back to packing to keep fixing; never fake a new summary.
      var back = this._firstTodo();
      this._mode = 'pack';
      this._focus = back >= 0 ? back : 0;
      this._disarm();
      this.setData({
        status: back >= 0 ? '回到逐件装 — 先装没装的：' + this._todoText() : '回到逐件装',
        lastEvent: 'EVT: summary -> pack (keep packing)'
      });
      this._renderAll();
      return;
    }
    if (this._mode !== 'pack') {
      this.setData({ lastEvent: 'EVT: PACK before any list - DEMO first' });
      return;
    }
    this._packItem('PACK');
  },

  prevTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode !== 'pack' || this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV outside pack mode - nothing to move' });
      return;
    }
    this._focus = (this._focus + this._items.length - 1) % this._items.length;
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
    this._renderAll();
  },

  nextTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode !== 'pack' || this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT outside pack mode - nothing to move' });
      return;
    }
    this._focus = (this._focus + 1) % this._items.length;
    this.setData({ lastEvent: 'EVT: focus -> item ' + (this._focus + 1) });
    this._renderAll();
  },

  rowTap(event) {
    if (this.data.busy) return;
    var d = (event && event.currentTarget && event.currentTarget.dataset) || (event && event.dataset) || {};
    var idx = parseInt(d.idx, 10);
    if (isNaN(idx)) {
      this.setData({ lastEvent: 'EVT: row tap without index - ignored' });
      return;
    }
    if (this._mode !== 'pack' || this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: row tap outside pack mode - ignored' });
      return;
    }
    if (idx < 0 || idx >= this._items.length) return;
    if (idx === this._focus) {
      this._packItem('TAP');
      return;
    }
    // Tapping another row only moves the focus there. Packing is
    // always an explicit confirmation, never a side effect of
    // browsing the list.
    this._focus = idx;
    this._disarm();
    this.setData({
      status: '当前项：' + this._items[idx].name + ' — 点 PACK 确认已装',
      lastEvent: 'EVT: focus -> item ' + (idx + 1) + ' (row tap, no pack)'
    });
    this._renderAll();
  },

  finTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: FIN in summary - PACK returns to packing, DEL twice clears' });
      return;
    }
    if (this._mode !== 'pack' || this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: FIN before any list - DEMO first' });
      return;
    }
    this._toSummary();
  },

  addTap() {
    if (this.data.busy) return;
    if (this._mode !== 'pack') {
      this.setData({ lastEvent: 'EVT: ADD outside pack mode - DEMO first' });
      return;
    }
    var pool = this._spareItems();
    if (this._spare >= pool.length) {
      this.setData({ lastEvent: 'EVT: ADD - spare pool exhausted, no more items to add' });
      return;
    }
    var it = pool[this._spare];
    this._spare++;
    this._items.push({ name: it.name, note: it.note, state: 'todo', src: 'USER' });
    // Adding your own item exits the DEMO walkthrough: the list is
    // no longer the sample, so staged DEMO steps no longer apply.
    this._demo = false;
    this._demoStage = 0;
    this._disarm();
    this.setData({
      status: '已加一件：' + it.name + ' — 点行名换项，点 PACK 确认已装',
      lastEvent: 'EVT: ADD item ' + it.name + ' (demo exited)'
    });
    this._renderAll();
  },

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      if (this._clearArm) { this._clearAll(); return; }
      this._armClear();
      this.setData({
        status: '⚠ 再点一次 DEL 清空整张清单重新装（其他动作取消）',
        lastEvent: 'EVT: clear 1/2 - ARMED (summary still kept)'
      });
      this._renderAll();
      return;
    }
    this._delFocused();
  },

  // ---------- SPEAK ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    if (this._mode === 'summary') {
      var t = this._summaryComplete
        ? '行李齐了，可以出门了。'
        : '还有没装的：' + this._todoText() + '，请先装完。';
      if (this._speakText(t)) this.setData({ lastEvent: 'EVT: SPEAK summary (TTS, no lang set)' });
      return;
    }
    if (this._mode !== 'pack' || this._items.length === 0) {
      if (this._speakText('还没有载入清单')) this.setData({ lastEvent: 'EVT: SPEAK empty (TTS, no lang set)' });
      return;
    }
    var it = this._items[this._focus];
    var line = '当前项，' + it.name + '，' +
      (it.state === 'packed' ? '已装。' : '还没装。');
    if (this._speakText(line)) this.setData({ lastEvent: 'EVT: SPEAK focus item (TTS, no lang set)' });
  },

  // ---------- DEMO (staged; never overwrites a user-edited list) ----------

  demoTap() {
    if (this.data.busy) return;
    if (this._demoStage === 4) {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
      return;
    }
    // Stage 3 -> 4 runs FROM the summary screen (pack the rest
    // there), so the summary guard must exempt it; any other DEMO
    // tap in summary is refused.
    if (this._mode === 'summary' && this._demoStage !== 3) {
      this.setData({ lastEvent: 'EVT: DEMO in summary - PACK returns to packing first' });
      return;
    }
    if (!this._demo && this._items.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO - a list already exists, DEL twice in summary clears it, then DEMO again' });
      return;
    }
    var self = this;
    function setState(idx, state) {
      self._items[idx].state = state;
      self._items[idx].src = 'DEMO';
    }
    if (this._demoStage === 0) {
      this._setItems(this._demoItems(), 'DEMO');
      this._demo = true;
      this._demoStage = 1;
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated list (not a real packing check)',
        status: 'DEMO - 示例清单已载入，8 件全未装 — 点 PACK 逐件确认已装',
        lastEvent: 'EVT: DEMO stage 1 - sample list, 0 packed'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      setState(0, 'packed'); setState(1, 'packed'); setState(2, 'packed');
      this._focus = 3;
      this._demoStage = 2;
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated list (not a real packing check)',
        status: 'DEMO - 已装 3 件 — 点 DEMO 看出门前小结怎么拦漏装',
        lastEvent: 'EVT: DEMO stage 2 - 3 items packed'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._toSummary();
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated list (not a real packing check)',
        status: 'DEMO - 小结：还有没装的：' + this._todoText() + ' — 点 PACK 回去接着装',
        lastEvent: 'EVT: DEMO stage 3 - summary blocked (simulated)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      for (var i = 0; i < this._items.length; i++) setState(i, 'packed');
      this._demoStage = 4;
      this._toSummary();
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated list (not a real packing check)',
        status: 'DEMO - 小结：行李齐了 ✓ 可以出门了',
        lastEvent: 'EVT: DEMO stage 4 - summary complete (simulated)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._items.length; i++) {
      var it = this._items[i];
      rows.push({
        idx: i,
        name: it.name,
        detail: it.note,
        flag: it.state === 'packed' ? '✓' : '○',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已装 ' + this._countPacked() + '/' + this._items.length +
      ' · 未装 ' + this._countTodo() +
      ' · 只存本次会话内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 未载入清单 — DEMO 载入示例清单';
      patch.bigLabel = '当前项 · —';
      patch.bigText = '未载入清单';
      patch.bigNote = 'DEMO 载入示例清单 · 看向一件点 PACK 确认已装';
    } else if (this._mode === 'pack') {
      var f = this._items[this._focus];
      patch.boxLabel = '◎ 逐件装 — 看向一件确认已装，点行名换项';
      patch.bigLabel = '当前项 · 第' + (this._focus + 1) + '件';
      patch.bigText = f ? f.name : '';
      patch.bigNote = !f ? ''
        : f.state === 'packed' ? '✓ 已装 · NEXT/PREV 换项 · DEL 取消'
        : 'PACK 确认已装 · 点行名换项 · 头稳点头也可确认';
    } else {
      patch.boxLabel = '◎ 出门前小结';
      patch.bigLabel = '出门前小结';
      if (this._summaryComplete) {
        patch.bigText = '行李齐了';
        patch.bigNote = '全部 ' + this._items.length + ' 件装好 · 可以出门了 · DEL 两下清空整张清单';
      } else {
        patch.bigText = '还有没装的';
        patch.bigNote = '没装：' + this._todoText() + ' · PACK 回去接着装';
      }
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
      <text class="title">PACK SWEEP v1.0.0</text>
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
      <button class="btn btn-main" bindtap="packTap">PACK ✓</button>
      <button class="btn" bindtap="prevTap">PREV</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="finTap">FIN</button>
      <button class="btn" bindtap="addTap">ADD</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="delTap">DEL</button>
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
    <text class="foot2">装没装以你的确认为准，Agent 没有物品识别 · 只记本次会话，关掉即清 · 出门前小结有未装项时绝不报行李齐了</text>
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
