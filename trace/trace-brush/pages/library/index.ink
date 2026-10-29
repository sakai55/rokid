<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 字库页：20 字总表（字 / 拼音 / 笔画数 / 练过次数），焦点选字。
const PROG = 'trace.trace-brush.v1';
const TMP = 'trace.brush.tmp';
const WIN = 7;

export default {
  data: {
    status: '字库：上下选字，Enter 开始学这个字',
    rows: [],
    selLine: '',
    evt: 'EVT: ready',
    ver: 'v1.3.5'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { chars: {} });
    let start = Math.max(0, Math.min(this._focus - 3, CHARS.length - WIN));
    if (start < 0) start = 0;
    const rows = [];
    for (let i = start; i < Math.min(CHARS.length, start + WIN); i++) {
      const c = CHARS[i];
      const rec = (p.chars || {})[c.char];
      rows.push({ idx: i, cls: i === this._focus ? 'row sel' : 'row', label: (i === this._focus ? '▶ ' : '· ') + c.char + ' ' + c.pinyin + ' · ' + c.strokes.length + ' 画 · 练过 ' + (rec ? rec.count : 0) + ' 次' });
    }
    this.setData({
      rows: rows,
      selLine: '选中 ' + (this._focus + 1) + ' / ' + CHARS.length + '：' + CHARS[this._focus].char + '（Enter 去学字页）'
    });
  },
  pickTap() {
    const c = CHARS[this._focus];
    saveKey(TMP, { char: c.char, review: false });
    const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
    p.lastChar = c.char;
    saveKey(PROG, p);
    try { wx.navigateTo({ url: '/pages/learn/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  rowTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) { this._focus = idx; this._render(); this.pickTap(); } },
  moveTap(d) { this._focus = (this._focus + d + CHARS.length) % CHARS.length; this.setData({ evt: 'EVT: focus ' + CHARS[this._focus].char }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.pickTap(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.pickTap();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">毛笔字描红 · 字库（20 字）</text>
    <text class="status">{{status}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{selLine}}</text>
    <text class="note">字库口径：每字须有完整分笔数据（hanzi-writer-data / Make Me a Hanzi，Arphic Public License）且笔画数、笔顺经人工核定；核不上的字不收，宁缺毋滥。永为 5 画——「永字八法」指八种笔法，不是八画。</text>
    <text class="foot">{{evt}} · {{ver}} · TR01</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; border-top: 1px solid rgba(64,255,94,0.35); }
.row { padding: 4px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.row.sel { background-color: #0a1f0e; border-left: 4px solid #40ff5e; }
.rtxt { color: #7dff9e; font-size: 14px; line-height: 19px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 4px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 5px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
