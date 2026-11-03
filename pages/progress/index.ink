<script def>
{"title": "Trace Kanji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, ensureQueue } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 進捗ページ：セッションをまたぐ進捗の総覧（練習済みの字／字ごとの回数／練習日数）＋
// 復習テストの入口（字をランダムに引き、ローマ字だけ見せて範字は出さない）。
const PROG = 'trace.trace-kanji.v1';
const TMP = 'trace.kanji.tmp';
const ACTS = ['復習テスト（ランダム一字）', '進捗を消す（二回押して確定）', '戻る BACK'];
const WIN = 6;

export default {
  data: {
    status: '進捗：次に開いたとき続きから',
    sumLine: '',
    queueLine: '',
    rows: [],
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.1.0'
  },
  onLoad() { this._focus = 0; this._armClear = false; this._off = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { chars: {}, days: {} });
    ensureQueue(p, CHARS.map(function (c) { return c.char; }));
    const practiced = CHARS.filter(function (c) { const r = (p.chars || {})[c.char]; return r && r.count > 0; });
    let total = 0;
    practiced.forEach(function (c) { total += p.chars[c.char].count; });
    const dayCount = Object.keys(p.days || {}).length;
    const rows = practiced.slice(this._off, this._off + WIN).map(function (c) {
      const r = p.chars[c.char];
      return { idx: c.char, label: c.char + ' ' + c.reading + ' · 練習 ' + r.count + ' 回' + (r.passed ? ' · できた' : '') };
    });
    this.setData({
      queueLine: '列の順番：' + (p.queue || []).join(' '),
      sumLine: '練習済み ' + practiced.length + ' / ' + CHARS.length + ' 字 · 累計 ' + total + ' 回 · 練習日数 ' + dayCount + ' 日',
      rows: rows.length ? rows : [{ idx: 'none', label: 'まだ何も練習していません——列の先頭から始めよう' }],
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enter で実行）'
    });
  },
  reviewTap() {
    const c = CHARS[Math.floor(Math.random() * CHARS.length)];
    saveKey(TMP, { char: c.char, review: true });
    this.setData({ status: 'テストの字を引きました（チェックページでは読みだけ表示）：' + c.reading, evt: 'EVT: review pick ' + c.char });
    speak('テストです。書いてください：' + c.char);
    try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  clearTap() {
    if (!this._armClear) {
      this._armClear = true;
      this.setData({ status: 'もう一度「進捗を消す」を押すと本当に消えます（誤操作防止）', evt: 'EVT: clear armed' });
      return;
    }
    if (!saveKey(PROG, { chars: {}, days: {}, lastChar: '' })) { this.setData({ status: '消去に失敗：E5001', evt: 'EVT: clear FAIL E5001' }); return; }
    this._armClear = false;
    this.setData({ status: '進捗を消しました', evt: 'EVT: progress cleared' });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.reviewTap(); else if (this._focus === 1) this.clearTap(); else this.backTap(); },
  moveTap(d) {
    // フォーカスはボタンの間を移動する
    this._focus = (this._focus + d + ACTS.length) % ACTS.length;
    this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] });
    this._render();
  },
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
    <text class="title">漢字 なぞり · 進捗</text>
    <text class="status">{{status}}</text>
    <text class="sum">{{sumLine}}</text>
    <text class="sum">{{queueLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">復習テスト</button>
      <button class="act" bindtap="actTap" data-idx="1">進捗を消す（二回で確定）</button>
      <button class="act" bindtap="actTap" data-idx="2">BACK</button>
    </view>
    <text class="note">復習テスト：字をランダムに引き、チェックページでは読みだけ・範字は出しません——まず紙に記憶で書いてから写真チェック。進捗はこの端末に保存され、次回も続きから。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kanji · 保存キー trace.trace-kanji.v1</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.sum { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; margin-top: 2px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; border-top: 1px solid rgba(64,255,94,0.35); }
.row { padding: 3px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.rtxt { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 16px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
