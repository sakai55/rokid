<script def>
{
  "navigationBarTitleText": "Attention Diary"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '注意力账单 — 一天结束，想知道注意力被谁偷走了，就按分类记一格，晚上出一张账单',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 记账 — CAT 选分类，MARK 记一格，BILL 出账单',
    bigLabel: '记账 · 待机',
    bigText: '还没记',
    bigNote: '分类 守望提醒 · MARK 记一格 · BILL 出账单',
    permLine: 'PERM: 无权限 — 只记账 + 汇总算术；不拍照、不录音、不定位；账单是你记的，不是自动采集的',
    rows: [],
    countLine: '已记 0 格 · 还没记 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - log one trigger per category, then BILL for the attention bill',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'log'; // log | bill | summary
    this._cats = ['守望提醒', '默念存档', '护盾拦截', '过滤命中', '回放确认', '副线提醒'];
    this._catIdx = 0;
    this._items = []; // { cat, note, time, demo } — session memory only
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1-6 logged, 7 bill, 8 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the entries and their
    // counts die with the page. Nothing was ever written
    // anywhere persistent, so there is nothing to clean up —
    // that IS the design. A "whole day" bill therefore covers
    // the entries logged in this open session; cross-agent
    // automatic collection does not exist on this platform,
    // and this agent never pretends otherwise.
    this._mode = 'log';
    this._catIdx = 0;
    this._items = [];
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

  _cat() { return this._cats[this._catIdx]; },

  _counts() {
    var c = [0, 0, 0, 0, 0, 0];
    var i, j;
    for (i = 0; i < this._items.length; i++) {
      for (j = 0; j < this._cats.length; j++) {
        if (this._items[i].cat === this._cats[j]) { c[j]++; break; }
      }
    }
    return c;
  },

  _top() {
    // Most-logged category; ties go to the earliest category
    // in the list, and the tie is shown, not hidden.
    var c = this._counts();
    var best = 0, i;
    for (i = 1; i < c.length; i++) {
      if (c[i] > c[best]) best = i;
    }
    return { idx: best, cat: this._cats[best], count: c[best] };
  },

  _lastNoteOf(cat) {
    var i;
    for (i = this._items.length - 1; i >= 0; i--) {
      if (this._items[i].cat === cat) return this._items[i].note;
    }
    return '';
  },

  _addItem(cat, note, demo) {
    this._items.push({
      cat: cat,
      note: note,
      time: this._timeLabel(),
      demo: !!demo
    });
    this._focus = this._items.length - 1;
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
    // Nod discipline in THIS agent: a steady nod logs the
    // current category as one entry (log), walks to the next
    // category in the bill (bill: walking only, it never logs
    // and never changes a count), or confirms the summary.
    // A nod never changes CAT: that is a selection, and a nod
    // must not silently pick one.
    if (this._mode === 'log') { this.markTap(); return; }
    if (this._mode === 'bill') { this.nextTap(); return; }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'log') this.markTap();
      else if (this._mode === 'bill') this.nextTap();
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

  catTap() {
    if (this._mode !== 'log') {
      this.setData({ lastEvent: 'EVT: CAT refused - the category is picked while logging, not in the bill or summary' });
      return;
    }
    this._catIdx = (this._catIdx + 1) % this._cats.length;
    this.setData({
      status: '分类已选为 ' + this._cat() + ' — MARK 记一格',
      lastEvent: 'EVT: category set - ' + this._cat()
    });
    this._renderAll();
  },

  // ---------- log / bill / summary ----------

  markTap() {
    if (this._mode !== 'log') {
      this.setData({ lastEvent: 'EVT: MARK refused - triggers are logged while logging, not in the bill or summary' });
      return;
    }
    this._addItem(this._cat(), '手动记一格', false);
    var it = this._items[this._items.length - 1];
    this.setData({
      status: '已记：' + it.cat + ' · ' + it.time + ' — 继续记，或 BILL 出账单',
      lastEvent: 'EVT: trigger logged - ' + it.cat + ' (' + this._items.length + ' total)'
    });
    this._renderAll();
  },

  billTap() {
    if (this._mode === 'bill') {
      this.setData({ lastEvent: 'EVT: BILL refused - the attention bill is already open' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: BILL refused - confirm or go back from the summary first' });
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: BILL refused - missing: 至少记一格触发（MARK）' });
      return;
    }
    this._mode = 'bill';
    this._focus = 0;
    this.setData({
      status: '注意力账单 — 按分类汇总计数，NEXT/PREV 走分类，最多那类标 ★',
      lastEvent: 'EVT: bill opened (' + this._items.length + ' entries)'
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the day.
      // BACK is the way back to the bill without deleting.
      this._confirmSummary();
      return;
    }
    if (this._items.length === 0) {
      this.setData({ lastEvent: 'EVT: END refused - missing: 至少记一格触发（MARK）' });
      return;
    }
    this._mode = 'summary';
    var top = this._top();
    this._summary = {
      total: this._items.length,
      counts: this._counts(),
      topCat: top.cat,
      topCount: top.count
    };
    this.setData({
      status: '本次账单小结 — 各分类计数与偷走最多那类钉在下面，点 END 确认清空，BACK 返回账单',
      lastEvent: 'EVT: day ended - summary ready (total ' + this._items.length + ', top ' + top.cat + ' ' + top.count + ')'
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'log';
    this._catIdx = 0;
    this._items = [];
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '注意力账单 — 一天结束，想知道注意力被谁偷走了，就按分类记一格，晚上出一张账单',
      lastEvent: 'EVT: summary confirmed - day cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the bill without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'bill';
      this._summary = null;
      this.setData({
        status: '注意力账单 — 按分类汇总计数，NEXT/PREV 走分类，最多那类标 ★',
        lastEvent: 'EVT: back to bill - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'bill') {
      this._mode = 'log';
      this.setData({
        status: '记账 — 继续记，或 BILL 出账单',
        lastEvent: 'EVT: back to logging - entries kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - MARK logs a trigger, BILL opens the bill' });
  },

  _focusLen() {
    if (this._mode === 'log') return this._items.length;
    return this._cats.length;
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
    if (this._mode === 'log') {
      line = this._items.length === 0
        ? '还没记：选分类，MARK 记一格'
        : '已记 ' + this._items.length + ' 格，继续记或出账单';
    } else if (this._mode === 'bill') {
      var c = this._counts();
      var top = this._top();
      line = this._cats[this._focus] + ' ' + c[this._focus] + ' 次，最多是' + top.cat + ' ' + top.count + ' 次';
    } else if (this._summary) {
      line = '本次账单小结：共 ' + this._summary.total + ' 格，最多是' + this._summary.topCat + ' ' + this._summary.topCount + ' 次';
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
    if (this._mode !== 'log' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user bill is under way' });
      return;
    }
    if (this._mode === 'log' && !this._demo && this._items.length > 0) {
      this.setData({ lastEvent: 'EVT: DEMO refused - user entries are under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      this._catIdx = 0; // 守望提醒
      this._addItem('守望提醒', '灶台守望叫回看', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - watch reminder logged (DEMO sample, 1 entry)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this._catIdx = 2; // 护盾拦截
      this._addItem('护盾拦截', '护盾挡了闲聊打扰', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - shield block logged (DEMO sample, 2 entries)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this._catIdx = 1; // 默念存档
      this._addItem('默念存档', '默念存了取号', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - silent save logged (DEMO sample, 3 entries)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this._catIdx = 2; // 护盾拦截
      this._addItem('护盾拦截', '护盾挡了推销电话', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - shield block logged (DEMO sample, 4 entries)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 4) {
      this._demoStage = 5;
      this._catIdx = 0; // 守望提醒
      this._addItem('守望提醒', '洗衣守望叫收衣', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 5 - watch reminder logged (DEMO sample, 5 entries)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 5) {
      this._demoStage = 6;
      this._catIdx = 2; // 护盾拦截
      this._addItem('护盾拦截', '护盾挡了群消息轰炸', true);
      this.setData({ lastEvent: 'EVT: DEMO stage 6 - shield block logged (DEMO sample, 6 entries, top shield 3)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 6) {
      this._demoStage = 7;
      this.billTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 7 - bill open, focus on category 1 (watch 2)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 7) {
      this._demoStage = 8;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 8 - summary (6 entries, top shield 3, DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var i, e;
    var top = this._top();
    var counts = this._counts();

    if (this._mode === 'log') {
      if (this._items.length === 0) {
        rows.push({
          idx: 0,
          name: '暂无记录',
          detail: '选分类，MARK 记一格，BILL 出账单',
          flag: '○',
          cls: 'row'
        });
      } else {
        for (i = 0; i < this._items.length; i++) {
          e = this._items[i];
          rows.push({
            idx: i,
            name: '格' + (i + 1) + ' · ' + e.time + ' · ' + e.cat,
            detail: e.note + (e.demo ? '（DEMO 示例）' : ''),
            flag: this._focus === i ? '▶' : '○',
            cls: 'row'
          });
        }
      }
    } else {
      // bill and summary share the per-category bill rows
      for (i = 0; i < this._cats.length; i++) {
        var note = counts[i] > 0 ? '最近：' + this._lastNoteOf(this._cats[i]) : '暂无记录';
        rows.push({
          idx: i,
          name: this._cats[i] + ' ' + counts[i] + ' 次',
          detail: note,
          flag: this._focus === i ? '▶' : (i === top.idx && counts[i] > 0 ? '★' : '○'),
          cls: 'row'
        });
      }
    }

    var patch = { rows: rows };
    if (this._items.length === 0) {
      patch.countLine = '已记 0 格 · 还没记 · 只存本次会话 · 关掉即清 · 零落盘';
    } else {
      patch.countLine = '已记 ' + this._items.length + ' 格' +
        ' · 最多 ' + top.cat + ' ' + top.count + ' 次' +
        ' · 只存本次会话 · 关掉即清 · 零落盘';
    }

    if (this._mode === 'log') {
      patch.boxLabel = '◎ 记账 — CAT 选分类，MARK 记一格，BILL 出账单';
      patch.bigLabel = '记账 · 待机';
      patch.bigText = this._items.length === 0 ? '还没记' : '已记 ' + this._items.length + ' 格';
      patch.bigNote = '分类 ' + this._cat() + ' · MARK 记一格 · BILL 出账单';
    } else if (this._mode === 'bill') {
      patch.boxLabel = '◎ 注意力账单 — NEXT/PREV 走分类，最多那类标 ★';
      patch.bigLabel = '注意力账单 · 第 ' + (this._focus + 1) + '/6 类';
      patch.bigText = this._cats[this._focus] + ' ' + counts[this._focus] + ' 次';
      patch.bigNote = '共 ' + this._items.length + ' 格 · 最多 ' + top.cat + ' ' + top.count + ' 次 · BACK 回记账';
    } else {
      patch.boxLabel = '◎ 本次账单小结 — 各分类计数与偷走最多那类钉在下面';
      patch.bigLabel = '本次账单小结';
      var s = this._summary || { total: 0, topCat: '—', topCount: 0 };
      patch.bigText = '最多 ' + s.topCat + ' ' + s.topCount + ' 次';
      patch.bigNote = '共 ' + s.total + ' 格 · 点 END 确认清空 · BACK 返回账单';
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
      <text class="title">ATTENTION DIARY v1.0.0</text>
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
      <button class="btn btn-main" bindtap="catTap">CAT</button>
      <button class="btn btn-main" bindtap="markTap">MARK</button>
      <button class="btn btn-main" bindtap="billTap">BILL</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn btn-main" bindtap="backTap">BACK</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
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
    <text class="foot2">账单是你自己记的分类计数，不是自动采集的全天统计；各 Agent 之间不共享数据、没有后台常驻汇总；跨 Agent 自动汇总需要平台级数据通道，目前没有；次数只是你记的分类计数，不是传感器统计；只存本次会话，关掉即清；没有室内定位；零落盘</text>
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
