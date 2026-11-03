<script def>
{"title": "Trace Kanji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, ensureQueue } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 選字ページ（入口）：漢字は全部平鋪（列の順にタイル状に並ぶ）。
// 説明文は置かない。スワイプで選択が移り、選ばれた字だけが大きく
// なる。タップで学ぶページへ。列の末尾に読み方／講評／一覧／進捗
// の小さなタイルが続く。練習の列（キュー）の仕組みは judge.js。
const PROG = 'trace.trace-kanji.v1';
const TMP = 'trace.kanji.tmp';
const TAIL = ['読み方', '講評', '一覧', '進捗'];

export default {
  data: {
    status: '',
    cells: [],
    evt: 'EVT: ready',
    ver: 'v1.2.0'
  },
  onLoad() { this._focus = 0; this._sel = 0; this._render(); },
  onShow() { this._render(); },
  _prog() { const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' }); ensureQueue(p, CHARS.map(function (c) { return c.char; })); return p; },
  _stops() { return this._prog().queue.length + TAIL.length; },
  _render() {
    const p = this._prog();
    const q = p.queue;
    if (this._focus < q.length) this._sel = this._focus;
    const selChar = q[Math.min(this._sel, q.length - 1)];
    const c = CHARS.filter(function (x) { return x.char === selChar; })[0] || CHARS[0];
    const rec = (p.chars || {})[c.char] || { count: 0 };
    const focus = this._focus;
    const cells = q.map(function (ch, i) {
      return { key: 'c' + i, label: ch, cls: 'cell' + (i === focus ? ' sel' : '') };
    });
    TAIL.forEach(function (t, i) {
      cells.push({ key: 't' + i, label: t, cls: 'cell act' + (q.length + i === focus ? ' sel' : '') });
    });
    saveKey(TMP, { char: c.char, review: false, counted: '' });
    this.setData({
      cells: cells,
      status: focus < q.length
        ? c.char + '（' + c.reading + '）· ' + c.strokes.length + ' 画 · 練習 ' + (rec.count || 0) + ' 回 · 列の ' + (Math.min(this._sel, q.length - 1) + 1) + ' / ' + q.length
        : TAIL[focus - q.length] + 'を開く'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    const q = this._prog().queue;
    if (this._focus < q.length) { this._go('/pages/learn/index'); return; }
    const t = this._focus - q.length;
    if (t === 0) this._go('/pages/detail/index');
    else if (t === 1) this._go('/pages/review/index');
    else if (t === 2) this._go('/pages/library/index');
    else this._go('/pages/progress/index');
  },
  cellTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  moveTap(d) { const n = this._stops(); this._focus = (this._focus + d + n) % n; this.setData({ evt: 'EVT: focus ' + this._focus }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">漢字 なぞり · 字を選ぶ</text>
    <text class="status">{{status}}</text>
    <view class="grid">
      <view ink:for="{{cells}}" class="{{item.cls}}" bindtap="cellTap" data-idx="{{index}}"><text class="glyph">{{item.label}}</text></view>
    </view>
    <text class="foot">{{evt}} · {{ver}} · trace-kanji</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 18px; }
.status { color: #40ff5e; font-size: 12px; line-height: 15px; margin-top: 1px; }
.grid { display: flex; flex-direction: row; flex-wrap: wrap; gap: 2px; margin-top: 4px; }
.cell { width: 71px; height: 44px; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(64,255,94,0.25); background-color: #02140a; }
.cell .glyph { color: rgba(125,255,158,0.75); font-size: 24px; line-height: 42px; }
.cell.sel { border: 1px solid #7dff9e; background-color: #0a2e16; }
.cell.sel .glyph { color: #7dff9e; font-size: 38px; font-weight: 500; }
.cell.act .glyph { font-size: 14px; color: rgba(64,255,94,0.6); }
.cell.act.sel .glyph { color: #7dff9e; font-size: 17px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 4px; }
</style>
