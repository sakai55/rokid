<script def>
{"title": "Trace Kana"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../kana.js';

// 今日ページ：今日のかな（日付で回す）＋前回の進み具合＋六つの行き先。
const PROG = 'trace.trace-kana.v1';
const TMP = 'trace.kana.tmp';
const MENU = ['今日のかなを学ぶ', 'かな一覧から選ぶ', '読み方と書き方', '写真チェック', '講評を見る', '進捗'];

export default {
  data: {
    status: 'ひらがな なぞり：今日は一字を練習',
    todayLine: '',
    lastLine: '前回：まだ練習していない',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
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
      todayLine: '今日のかな：' + tc.char + '（' + tc.romaji + ' · ' + tc.strokes.length + '画）',
      lastLine: last ? ('前回の続き：' + last.char + '（' + last.romaji + '）。一覧から続けられます') : '前回：まだ練習していない。今日のかなから始めよう',
      sumLine: '進捗：練習済み ' + practiced + ' / ' + CHARS.length + ' 字 · 累計 ' + total + ' 回',
      focusLine: 'フォーカス：' + MENU[this._focus] + '（上下で切替、Enter で実行、うなずき＝実行）'
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
    <text class="title">ひらがな なぞり · 今日</text>
    <text class="status">{{status}}</text>
    <view class="hero">
      <text class="today">{{todayLine}}</text>
      <text class="line">{{lastLine}}</text>
      <text class="line dim">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">今日のかな</button>
      <button class="act" bindtap="actTap" data-idx="1">かな一覧</button>
      <button class="act" bindtap="actTap" data-idx="2">読み方・書き方</button>
      <button class="act" bindtap="actTap" data-idx="3">写真チェック</button>
      <button class="act" bindtap="actTap" data-idx="4">講評</button>
      <button class="act" bindtap="actTap" data-idx="5">進捗</button>
    </view>
    <text class="note">進め方：中央の範字を一画ずつ学ぶ（範字は低輝度、筆順の矢印だけ高輝度）→ 本物の紙に筆で書く → 下を向いて写真チェック。見るのは粗い点だけ：画の過不足、重心、いちばん目立つ 1〜2 か所。専門的な採点はしません。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kana</text>
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
