<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// TR01 今日页：今日一字（按日期轮换）+ 上次进度 + 六个去向。
const PROG = 'trace.trace-brush.v1';
const TMP = 'trace.brush.tmp';
const MENU = ['学今日一字', '去字库选字', '字义与笔法', '拍照验收', '看点评', '我的进度'];

export default {
  data: {
    status: '毛笔字描红：今天练一个字',
    todayLine: '',
    lastLine: '上次：还没练过',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.2.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _todayIdx() {
    const now = new Date();
    const start = new Date(now.getFullYear(), 0, 0);
    const doy = Math.floor((now - start) / 86400000);
    return doy % CHARS.length;
  },
  _prog() { return loadKey(PROG, { chars: {}, days: {}, lastChar: '' }); },
  _render() {
    const ti = this._todayIdx();
    const tc = CHARS[ti];
    const p = this._prog();
    const practiced = Object.keys(p.chars || {}).filter(function (k) { return p.chars[k] && p.chars[k].count > 0; }).length;
    let total = 0;
    Object.keys(p.chars || {}).forEach(function (k) { total += (p.chars[k].count || 0); });
    const last = p.lastChar ? CHARS.filter(function (c) { return c.char === p.lastChar; })[0] : null;
    saveKey(TMP, { char: tc.char, review: false });
    this.setData({
      todayLine: '今日一字：' + tc.char + '（' + tc.pinyin + ' · ' + tc.strokes.length + ' 画）',
      lastLine: last ? ('上次练到：' + last.char + '（' + last.pinyin + '），可从字库继续') : '上次：还没练过，从今日一字开始',
      sumLine: '进度：已练 ' + practiced + ' / ' + CHARS.length + ' 字 · 累计练习 ' + total + ' 次',
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行，点头=执行）'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    if (this._focus === 0) this._go('/pages/learn/index');
    else if (this._focus === 1) this._go('/pages/library/index');
    else if (this._focus === 2) this._go('/pages/detail/index');
    else if (this._focus === 3) this._go('/pages/verify/index');
    else if (this._focus === 4) this._go('/pages/review/index');
    else this._go('/pages/progress/index');
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  moveTap(d) { this._focus = (this._focus + d + MENU.length) % MENU.length; this.setData({ evt: 'EVT: focus ' + MENU[this._focus] }); this._render(); },
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
    <text class="title">毛笔字描红 · 今日</text>
    <text class="status">{{status}}</text>
    <view class="hero">
      <text class="today">{{todayLine}}</text>
      <text class="line">{{lastLine}}</text>
      <text class="line dim">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">学今日一字</button>
      <button class="act" bindtap="actTap" data-idx="1">字库选字</button>
      <button class="act" bindtap="actTap" data-idx="2">字义笔法</button>
      <button class="act" bindtap="actTap" data-idx="3">拍照验收</button>
      <button class="act" bindtap="actTap" data-idx="4">看点评</button>
      <button class="act" bindtap="actTap" data-idx="5">我的进度</button>
    </view>
    <text class="note">练法：中央范字逐笔学（当前笔最亮）→ 在真纸上用真毛笔写 → 低头拍照验字，只查粗项：少笔多笔、重心、最明显的一两处。不装专业评分。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.hero { border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 6px 8px; margin-top: 5px; }
.today { color: #7dff9e; font-size: 16px; font-weight: 500; line-height: 21px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
