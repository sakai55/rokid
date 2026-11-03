<script def>
{"title": "Trace Kanji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, ensureQueue } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 選字ページ（入口）：入ったらそのまま鏡腿スワイプで列を送って字を
// 選び、タップで学ぶページへ。列は練習の列（キュー）そのもので、
// 練習を終えた字は記憶曲線の間隔で後ろに並び直る（judge.js の
// finishChar / QUEUE_LADDER）。フォーカスは「列の字」が主で、末尾に
// 読み方・講評・一覧・進捗の 4 つが続く。
const PROG = 'trace.trace-kanji.v1';
const TMP = 'trace.kanji.tmp';
const TAIL = ['読み方・書き方', '講評', '漢字一覧', '進捗'];

export default {
  data: {
    status: '字を選ぶ：スワイプで送る、タップで練る',
    bigChar: '',
    metaLine: '',
    queueLine: '',
    nextLine: '',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.1.0'
  },
  onLoad() { this._focus = 0; this._sel = 0; this._render(); },
  onShow() { this._render(); },
  _prog() { const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' }); ensureQueue(p, CHARS.map(function (c) { return c.char; })); return p; },
  _stops() { return this._queue().length + TAIL.length; },
  _queue() { return this._prog().queue; },
  _render() {
    const p = this._prog();
    const q = p.queue;
    if (this._focus < q.length) this._sel = this._focus;
    const selChar = q[Math.min(this._sel, q.length - 1)];
    const c = CHARS.filter(function (x) { return x.char === selChar; })[0] || CHARS[0];
    const rec = (p.chars || {})[c.char] || { count: 0 };
    const practiced = Object.keys(p.chars || {}).filter(function (k) { return p.chars[k] && p.chars[k].count > 0; }).length;
    const pos = Math.min(this._sel, q.length - 1);
    const next = [];
    for (let i = 1; i <= 3; i++) { const nq = q[(pos + i) % q.length]; if (nq && nq !== c.char) next.push(nq); }
    const onChar = this._focus < q.length;
    saveKey(TMP, { char: c.char, review: false, counted: '' });
    this.setData({
      bigChar: onChar ? c.char : '≡',
      metaLine: onChar
        ? c.char + '（' + c.reading + ' · ' + c.strokes.length + ' 画）'
        : TAIL[this._focus - q.length] + 'を開く',
      queueLine: '列の ' + (pos + 1) + ' / ' + q.length + ' 字目 · この字は練習 ' + (rec.count || 0) + ' 回',
      nextLine: 'この先：' + next.join(' → '),
      sumLine: '進捗：練習済み ' + practiced + ' / ' + CHARS.length + ' 字',
      focusLine: onChar
        ? 'フォーカス：' + c.char + ' を練る（上下＝字を送る、Enter＝練る）'
        : 'フォーカス：' + TAIL[this._focus - q.length] + '（上下で切替、Enter で開く）'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    const q = this._queue();
    if (this._focus < q.length) { this._go('/pages/learn/index'); return; }
    const t = this._focus - q.length;
    if (t === 0) this._go('/pages/detail/index');
    else if (t === 1) this._go('/pages/review/index');
    else if (t === 2) this._go('/pages/library/index');
    else this._go('/pages/progress/index');
  },
  learnTap() { this._focus = this._sel; this.doAct(); },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
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
    <view class="stage">
      <text class="big">{{bigChar}}</text>
      <view class="rail">
        <text class="rline strong">{{metaLine}}</text>
        <text class="rline">{{queueLine}}</text>
        <text class="rline dim">{{nextLine}}</text>
        <text class="rline dim">{{sumLine}}</text>
      </view>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="learnTap">この字を練る</button>
    </view>
    <text class="note">進め方：スワイプで列を送って字を選ぶ → 範字を一画ずつ見て紙に書く → 学ぶ画面でうなずくと練習 1 回分として記録され、その字は列の後ろに並び直ります（練習回数が多い字ほど遠くへ。記憶曲線の間隔）。写真チェックは学ぶ画面の最後から。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kanji</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; gap: 10px; margin-top: 6px; align-items: flex-start; }
.big { color: #7dff9e; font-size: 84px; font-weight: 500; line-height: 96px; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 2px 16px; }
.rail { display: flex; flex-direction: column; flex-grow: 1; }
.rline { color: rgba(125,255,158,0.88); font-size: 12px; line-height: 17px; margin-top: 3px; }
.strong { color: #7dff9e; font-size: 14px; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 8px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 14px; margin-top: 7px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
