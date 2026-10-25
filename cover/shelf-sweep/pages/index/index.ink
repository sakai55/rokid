<script def>
{
  "navigationBarTitleText": "Shelf Sweep"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '货架找货 — 3 层 × 3 段共 9 格，看向一格点 SCAN 记已扫，漏格小结会点名，找到了只能由你确认',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 未定目标 — TARGET 换示例目标，DEMO 载入货架图',
    bigLabel: '目标 · —',
    bigText: '未定目标',
    bigNote: 'TARGET 换示例目标 · DEMO 载入货架图 · 看向一格点 SCAN 记已扫',
    permLine: 'PERM: none — 不用相机/麦克风/定位，只用头部朝向确认',
    rows: [],
    countLine: '已扫 0/9 · 未扫 9 · 只存本次会话内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - pick a target, then sweep cell by cell',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | sweep | summary
    this._cells = []; // { name, state: 'unseen'|'scanned' }
    this._focus = 0;
    this._target = '';
    this._targetIdx = 0;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1: grid loaded, 2: 4 scanned, 3: summary blocked, 4: all scanned not found, 5: found summary
    this._summaryKind = ''; // '' | 'blocked' | 'found' | 'notfound'
    this._foundCell = -1;
    this._clearArm = false;
    this._clearTimer = null;
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the grid, the scanned marks, the
    // target and the found cell die with the page. Nothing was ever
    // written to any storage, so there is nothing to clean up - that
    // IS the design. Close the agent and this sweep is gone; the
    // next shelf you search starts from a blank map, which is the
    // correct use for a search happening right now.
    this._cells = [];
    this._focus = 0;
    this._target = '';
    this._demo = false;
    this._demoStage = 0;
    this._summaryKind = '';
    this._foundCell = -1;
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
    // "this cell is scanned" - and only in sweep mode on the focused
    // cell. It never loads a grid, never finishes the sweep, never
    // declares the item found, and is inert on the summary screen
    // and before any grid is loaded. Found is always the FOUND
    // button (a tap confirmation), so one gesture can never mean
    // both "scanned" and "found".
    if (this._mode === 'sweep') {
      this._scanCell('NOD');
      return;
    }
    this.setData({ lastEvent: 'EVT: nod ignored - nod only scans a cell in sweep mode' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.scanTap();
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

  // The 9 cells of one shelf: 3 layers (上/中/下) x 3 segments
  // (左/中/右), in row-major order. The grid is a coverage map, not
  // a map of the shop: cell order comes from the wearer's own
  // sweep, and no position of any cell is ever known to the agent.
  _cellNames() {
    return ['上左', '上中', '上右', '中左', '中中', '中右', '下左', '下中', '下右'];
  },

  // DEMO sample targets only. A target is a name you are looking
  // for; the agent never verifies that the item is on the shelf.
  _targetPool() {
    return ['某品牌酱油', '某本书', '折叠雨伞', '洗发水'];
  },

  _countScanned() {
    var n = 0;
    for (var i = 0; i < this._cells.length; i++) if (this._cells[i].state === 'scanned') n++;
    return n;
  },

  _countUnseen() {
    var n = 0;
    for (var i = 0; i < this._cells.length; i++) if (this._cells[i].state === 'unseen') n++;
    return n;
  },

  _allScanned() {
    return this._cells.length > 0 && this._countUnseen() === 0;
  },

  _firstUnseen() {
    for (var i = 0; i < this._cells.length; i++) if (this._cells[i].state === 'unseen') return i;
    return -1;
  },

  _unseenText() {
    var parts = [];
    for (var i = 0; i < this._cells.length; i++) {
      if (this._cells[i].state === 'unseen') parts.push(this._cells[i].name);
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
        self.setData({ lastEvent: 'EVT: clear disarmed (timeout) - sweep kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _clearAll() {
    this._cells = [];
    this._focus = 0;
    this._target = '';
    this._demo = false;
    this._demoStage = 0;
    this._summaryKind = '';
    this._foundCell = -1;
    this._disarm();
    this._mode = 'idle';
    this.setData({
      status: '已清空 — 重新定目标',
      lastEvent: 'EVT: sweep cleared by two-step DEL - session memory wiped'
    });
    this._renderAll();
  },

  _loadGrid(target) {
    var names = this._cellNames();
    this._cells = names.map(function (n) {
      return { name: n, state: 'unseen' };
    });
    this._target = target;
    this._focus = 0;
    this._summaryKind = '';
    this._foundCell = -1;
    this._mode = 'sweep';
    this._renderAll();
  },

  // ---------- scan / unscan: the ONLY ways a cell changes ----------

  _scanCell(how) {
    if (this._mode !== 'sweep' || this._cells.length === 0) return;
    var cell = this._cells[this._focus];
    if (!cell) return;
    if (cell.state === 'scanned') {
      // Repeat-scan warning: the whole point of the map is that a
      // second look at a swept cell must not count twice, and must
      // say so out loud instead of silently re-counting.
      this.setData({
        status: '这段扫过了：' + cell.name + ' 已扫，不重复计 — 换一格接着扫',
        lastEvent: 'EVT: repeat scan on ' + cell.name + ' - already scanned, not counted again'
      });
      this._renderAll();
      return;
    }
    var justScanned = this._focus;
    cell.state = 'scanned';
    // A hand scan ends the DEMO walkthrough: the map is no longer
    // the sample walk, so staged DEMO steps stop applying.
    this._demo = false;
    this._demoStage = 0;
    this._disarm();
    var next = this._firstUnseen();
    if (next >= 0) this._focus = next;
    this.setData({
      status: '已扫：' + cell.name + ' — ' +
        (this._allScanned() ? '9 格全扫完，点 FIN 看小结' : '已扫 ' + this._countScanned() + '/9'),
      lastEvent: 'EVT: cell ' + (justScanned + 1) + ' scanned by ' + how
    });
    this._renderAll();
  },

  _delFocused() {
    if (this._mode !== 'sweep' || this._cells.length === 0) return;
    var cell = this._cells[this._focus];
    if (!cell) return;
    if (cell.state === 'scanned') {
      // Correction, not destruction: a scanned cell goes back to
      // unseen, so a mistaken scan can be undone cheaply.
      cell.state = 'unseen';
      this._disarm();
      this.setData({
        status: '已取消：' + cell.name + ' 回到未扫',
        lastEvent: 'EVT: cell ' + (this._focus + 1) + ' unscanned by DEL'
      });
    } else {
      this.setData({
        status: cell.name + ' 本来就没扫过 — DEL 只取消已扫格',
        lastEvent: 'EVT: DEL on unseen cell ' + cell.name + ' - nothing to unscan'
      });
    }
    this._renderAll();
  },

  _toSummary(kind) {
    this._disarm();
    this._mode = 'summary';
    this._summaryKind = kind;
    if (kind === 'found') {
      var fc = this._cells[this._foundCell];
      var fname = fc ? fc.name : '';
      this._speakText('找到了，在' + fname + '。');
      this.setData({
        status: '找到了 ✓ 在' + fname + ' — 目标：' + this._target,
        lastEvent: 'EVT: summary found at cell ' + (this._foundCell + 1)
      });
    } else if (kind === 'notfound') {
      this._speakText('9 格都扫过了，没找到，建议问店员或换货架。');
      this.setData({
        status: '9 格都扫过了，没找到 — 建议问店员或换货架',
        lastEvent: 'EVT: summary not found - all 9 scanned, never reported found'
      });
    } else {
      this._speakText('还有没扫的：' + this._unseenText());
      this.setData({
        status: '还有没扫的：' + this._unseenText() + ' — 点 SCAN 回去接着扫',
        lastEvent: 'EVT: summary blocked - unseen: ' + this._unseenText() + ' (never reported complete)'
      });
    }
    this._renderAll();
  },

  // ---------- buttons ----------

  scanTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      // Back to sweeping to keep fixing; never fake a new summary.
      var back = this._firstUnseen();
      this._mode = 'sweep';
      this._focus = back >= 0 ? back : 0;
      this._disarm();
      this.setData({
        status: back >= 0 ? '回到逐格扫 — 先扫没扫的：' + this._unseenText() : '回到逐格扫',
        lastEvent: 'EVT: summary -> sweep (keep sweeping)'
      });
      this._renderAll();
      return;
    }
    if (this._mode !== 'sweep') {
      this.setData({ lastEvent: 'EVT: SCAN before any grid - DEMO first' });
      return;
    }
    this._scanCell('SCAN');
  },

  prevTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode !== 'sweep' || this._cells.length === 0) {
      this.setData({ lastEvent: 'EVT: PREV outside sweep mode - nothing to move' });
      return;
    }
    this._focus = (this._focus + this._cells.length - 1) % this._cells.length;
    this.setData({ lastEvent: 'EVT: focus -> cell ' + (this._focus + 1) });
    this._renderAll();
  },

  nextTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode !== 'sweep' || this._cells.length === 0) {
      this.setData({ lastEvent: 'EVT: NEXT outside sweep mode - nothing to move' });
      return;
    }
    this._focus = (this._focus + 1) % this._cells.length;
    this.setData({ lastEvent: 'EVT: focus -> cell ' + (this._focus + 1) });
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
    if (this._mode !== 'sweep' || this._cells.length === 0) {
      this.setData({ lastEvent: 'EVT: row tap outside sweep mode - ignored' });
      return;
    }
    if (idx < 0 || idx >= this._cells.length) return;
    if (idx === this._focus) {
      this._scanCell('TAP');
      return;
    }
    // Tapping another row only moves the focus there. Scanning is
    // always an explicit confirmation, never a side effect of
    // browsing the map.
    this._focus = idx;
    this._disarm();
    this.setData({
      status: '当前格：' + this._cells[idx].name + ' — 点 SCAN 记已扫',
      lastEvent: 'EVT: focus -> cell ' + (idx + 1) + ' (row tap, no scan)'
    });
    this._renderAll();
  },

  finTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: FIN in summary - SCAN returns to sweeping, DEL twice clears' });
      return;
    }
    if (this._mode !== 'sweep' || this._cells.length === 0) {
      this.setData({ lastEvent: 'EVT: FIN before any grid - DEMO first' });
      return;
    }
    // The finish check is a gate, not a decoration: with any cell
    // still unseen, FIN is REFUSED and the refusal NAMES the
    // unscanned cells. Only a fully scanned map may reach a
    // verdict, and the verdict is honest about not finding.
    if (this._allScanned()) {
      this._toSummary('notfound');
    } else {
      this._toSummary('blocked');
    }
  },

  foundTap() {
    if (this.data.busy) return;
    if (this._mode !== 'sweep' || this._cells.length === 0) {
      this.setData({ lastEvent: 'EVT: FOUND outside sweep mode - look at the item, then FOUND' });
      return;
    }
    // Found is the wearer's own confirmation, never object
    // recognition: the agent cannot see the item, it can only
    // record that you said you found it in this cell.
    this._foundCell = this._focus;
    this._demo = false;
    this._demoStage = 0;
    this._disarm();
    this._toSummary('found');
  },

  targetTap() {
    if (this.data.busy) return;
    if (this._mode !== 'idle') {
      this.setData({ lastEvent: 'EVT: TARGET only in idle - finish or clear this sweep first' });
      return;
    }
    var pool = this._targetPool();
    this._targetIdx = (this._targetIdx + 1) % pool.length;
    this._target = pool[this._targetIdx];
    this.setData({
      status: '示例目标已换：' + this._target + ' — DEMO 载入货架图',
      lastEvent: 'EVT: target cycled to ' + this._target
    });
    this._renderAll();
  },

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'summary') {
      if (this._clearArm) { this._clearAll(); return; }
      this._armClear();
      this.setData({
        status: '⚠ 再点一次 DEL 清空本次找货重新找（其他动作取消）',
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
      var t = this._summaryKind === 'found'
        ? '找到了，在' + (this._cells[this._foundCell] ? this._cells[this._foundCell].name : '') + '。'
        : this._summaryKind === 'notfound'
        ? '9 格都扫过了，没找到，建议问店员或换货架。'
        : '还有没扫的：' + this._unseenText() + '，请先扫完。';
      if (this._speakText(t)) this.setData({ lastEvent: 'EVT: SPEAK summary (TTS, no lang set)' });
      return;
    }
    if (this._mode !== 'sweep' || this._cells.length === 0) {
      if (this._speakText('还没有定目标')) this.setData({ lastEvent: 'EVT: SPEAK empty (TTS, no lang set)' });
      return;
    }
    var cell = this._cells[this._focus];
    var line = '当前格，' + cell.name + '，' +
      (cell.state === 'scanned' ? '已扫。' : '还没扫。');
    if (this._speakText(line)) this.setData({ lastEvent: 'EVT: SPEAK focus cell (TTS, no lang set)' });
  },

  // ---------- DEMO (staged; never overwrites a user-edited sweep) ----------

  demoTap() {
    if (this.data.busy) return;
    if (this._demoStage === 5) {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
      return;
    }
    // Stage 3 -> 4 and 4 -> 5 run FROM the summary screen (the arc
    // walks through the verdicts there), so the summary guard must
    // exempt exactly those transitions; any other DEMO tap in
    // summary is refused.
    if (this._mode === 'summary' && this._demoStage !== 3 && this._demoStage !== 4) {
      this.setData({ lastEvent: 'EVT: DEMO in summary - SCAN returns to sweeping first' });
      return;
    }
    if (!this._demo && this._cells.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO - a sweep already exists, DEL twice in summary clears it, then DEMO again' });
      return;
    }
    var self = this;
    function setState(idx, state) {
      self._cells[idx].state = state;
    }
    if (this._demoStage === 0) {
      this._loadGrid(this._targetPool()[this._targetIdx]);
      this._demo = true;
      this._demoStage = 1;
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated grid (not a real shelf search)',
        status: 'DEMO - 货架图已载入，目标：' + this._target + '，9 格全未扫 — 点 SCAN 逐格扫',
        lastEvent: 'EVT: DEMO stage 1 - grid loaded, 0 scanned'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      setState(0, 'scanned'); setState(1, 'scanned'); setState(2, 'scanned'); setState(3, 'scanned');
      this._focus = 4;
      this._demoStage = 2;
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated grid (not a real shelf search)',
        status: 'DEMO - 已扫 4 格 — 点 DEMO 看结束前小结怎么点名漏格',
        lastEvent: 'EVT: DEMO stage 2 - 4 cells scanned'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._toSummary('blocked');
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated grid (not a real shelf search)',
        status: 'DEMO - 小结：还有没扫的：' + this._unseenText() + ' — 点 SCAN 回去接着扫',
        lastEvent: 'EVT: DEMO stage 3 - summary blocked (simulated)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      for (var i = 0; i < this._cells.length; i++) setState(i, 'scanned');
      this._demoStage = 4;
      this._toSummary('notfound');
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated grid (not a real shelf search)',
        status: 'DEMO - 小结：9 格都扫过了，没找到',
        lastEvent: 'EVT: DEMO stage 4 - summary not found (simulated)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._foundCell = 5;
      this._demoStage = 5;
      this._toSummary('found');
      this.setData({
        permLine: 'PERM: DEMO - no camera used; simulated grid (not a real shelf search)',
        status: 'DEMO - 小结：找到了 ✓ 在中右',
        lastEvent: 'EVT: DEMO stage 5 - summary found (simulated)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, DEL twice clears it' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    for (var i = 0; i < this._cells.length; i++) {
      var cell = this._cells[i];
      rows.push({
        idx: i,
        name: cell.name,
        detail: cell.state === 'scanned' ? '已扫' : '未扫',
        flag: cell.state === 'scanned' ? '✓' : '○',
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已扫 ' + this._countScanned() + '/' + this._cells.length +
      ' · 未扫 ' + this._countUnseen() +
      ' · 只存本次会话内存 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 未定目标 — TARGET 换示例目标，DEMO 载入货架图';
      patch.bigLabel = '目标 · 示例';
      patch.bigText = this._target || '未定目标';
      patch.bigNote = 'TARGET 换示例目标 · DEMO 载入货架图 · 看向一格点 SCAN 记已扫';
    } else if (this._mode === 'sweep') {
      var f = this._cells[this._focus];
      patch.boxLabel = '◎ 逐格扫 — 目标：' + this._target + ' · 看向一格确认已扫，点行名换格';
      patch.bigLabel = '当前格 · 第' + (this._focus + 1) + '格';
      patch.bigText = f ? f.name : '';
      patch.bigNote = !f ? ''
        : f.state === 'scanned' ? '✓ 已扫 · NEXT/PREV 换格 · DEL 取消'
        : 'SCAN 记已扫 · 点行名换格 · 头稳点头也可确认 · 找到点 FOUND';
    } else {
      patch.boxLabel = '◎ 找货小结';
      patch.bigLabel = '找货小结';
      if (this._summaryKind === 'found') {
        var fc = this._cells[this._foundCell];
        patch.bigText = '找到了';
        patch.bigNote = '在' + (fc ? fc.name : '') + ' · 目标：' + this._target + ' · DEL 两下清空本次找货';
      } else if (this._summaryKind === 'notfound') {
        patch.bigText = '都扫过了，没找到';
        patch.bigNote = '9 格全扫 · 建议问店员或换货架 · DEL 两下清空本次找货';
      } else {
        patch.bigText = '还有没扫的';
        patch.bigNote = '没扫：' + this._unseenText() + ' · SCAN 回去接着扫';
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
      <text class="title">SHELF SWEEP v1.0.0</text>
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
      <button class="btn btn-main" bindtap="scanTap">SCAN ✓</button>
      <button class="btn" bindtap="prevTap">PREV</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="finTap">FIN</button>
      <button class="btn" bindtap="foundTap">FOUND</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="delTap">DEL</button>
      <button class="btn" bindtap="targetTap">TARGET</button>
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
    <text class="foot2">找到了以你的确认为准，Agent 没有商品识别 · 只记本次会话，关掉即清 · 结束前小结有未扫格时绝不报找完了</text>
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
