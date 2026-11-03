<script def>
{"title": "Trace Kanji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, ensureQueue, finishChar } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 講評ページ：lastVerdict の三つの粗チェック＋一言講評を出す。
// 本人の「できた」判定が本ページの核——本人の判断を優先し、記録に残す。
const PROG = 'trace.trace-kanji.v1';
const TMP = 'trace.kanji.tmp';
const ACTS = ['この字はできた（本人判定）', 'もう一枚書く（チェックへ）', '次の字へ', '選字へ戻る'];

export default {
  data: {
    status: '講評：LLM は粗い点だけ。最後に「できた」かどうかは本人が決める',
    verdictLine: 'まだ講評がありません：先にチェックページで撮ってください',
    missingLine: '',
    centerLine: '',
    diffLine: '',
    sumLine: '',
    countLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.1.0'
  },
  onLoad() {
    this._focus = 0;
    const t = loadKey(TMP, { char: CHARS[0].char });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
    const v = p.lastVerdict;
    const rec = (p.chars || {})[this._char.char] || { count: 0 };
    const mine = !!(v && v.char === this._char.char);
    let head = 'まだ講評がありません：先にチェックページで撮ってください';
    if (v && !mine) head = '直近の講評は「' + v.char + '」のものです。その字に切り替えるか、先に今の字をチェックしてください';
    if (mine && v.clear) head = '「' + v.char + '」の粗チェック結果' + (v.review ? '（復習テスト）' : '');
    if (mine && !v.clear) head = '「' + v.char + '」は今回は見えませんでした：撮り直してください';
    const ok = mine && v.clear;
    this.setData({
      verdictLine: head,
      missingLine: ok ? ('画の過不足：' + v.missing) : '',
      centerLine: ok ? ('重心：' + v.center) : '',
      diffLine: ok ? ('目立つ違い：' + v.diff) : '',
      sumLine: ok ? ('一言：' + v.summary) : '',
      countLine: '「' + this._char.char + '」練習 ' + (rec.count || 0) + ' 回' + (rec.passed ? ' · できた記録あり' : ''),
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enter で実行）'
    });
  },
  passTap() {
    const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
    const v = p.lastVerdict;
    if (!v || v.char !== this._char.char) { this.setData({ status: 'まずこの字をチェックしてから判定してください（チェックなしに「できた」にはできません）', evt: 'EVT: pass refused - no verdict' }); return; }
    const ch = this._char.char;
    ensureQueue(p, CHARS.map(function (c) { return c.char; }));
    const t = loadKey(TMP, {});
    if (t.counted !== ch) {
      // 練習 1 回分として数え、列の後ろへ（学ぶ画面のうなずき終了と
      // 同じ finishChar。二重に数えないよう TMP.counted で印を付ける）
      finishChar(p, ch);
      t.counted = ch; saveKey(TMP, t);
    }
    const rec = p.chars[ch];
    rec.passed = true;
    rec.overrides = (rec.overrides || 0) + 1;
    p.chars[ch] = rec;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存に失敗：E5001（進捗が記録されませんでした）', evt: 'EVT: pass save FAIL E5001' }); return; }
    this.setData({ status: '記録しました：「' + ch + '」はできた（本人判定が機械判定より優先）', evt: 'EVT: pass recorded ' + ch });
    speak(ch + '、できたと記録しました');
    this._render();
  },
  againTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  nextCharTap() {
    const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
    ensureQueue(p, CHARS.map(function (c) { return c.char; }));
    const q = p.queue;
    const nch = q[0] !== this._char.char ? q[0] : (q[1] || q[0]);
    const n = CHARS.filter(function (c) { return c.char === nch; })[0] || CHARS[0];
    saveKey(TMP, { char: n.char, review: false, counted: '' });
    this._char = n;
    this.setData({ status: '次の字：' + n.char + '。学ぶページで筆順を見てください', evt: 'EVT: next char ' + n.char });
    try { wx.navigateTo({ url: '/pages/learn/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
    this._render();
  },
  homeTap() { try { wx.navigateBack({ delta: 10 }); } catch (e) { try { wx.navigateTo({ url: '/pages/index/index' }); } catch (e2) {} } },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.passTap(); else if (this._focus === 1) this.againTap(); else if (this._focus === 2) this.nextCharTap(); else this.homeTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
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
    <text class="title">漢字 なぞり · 講評</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="vhead">{{verdictLine}}</text>
      <text class="rline">{{missingLine}}</text>
      <text class="rline">{{centerLine}}</text>
      <text class="rline">{{diffLine}}</text>
      <text class="rline strong">{{sumLine}}</text>
      <text class="rline dim">{{countLine}}</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">この字はできた</button>
      <button class="act" bindtap="actTap" data-idx="1">もう一枚</button>
      <button class="act" bindtap="actTap" data-idx="2">次の字</button>
      <button class="act" bindtap="actTap" data-idx="3">選字へ</button>
    </view>
    <text class="note">ルール：機械の判定は参考まで。「できた」は本人の判断を記録します。チェックしていない字を「できた」にはできません。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kanji</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border-left: 5px solid #40ff5e; background-color: #0a1f0e; padding: 6px 8px; margin-top: 5px; }
.vhead { color: #7dff9e; font-size: 14px; font-weight: 500; line-height: 19px; }
.rline { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 17px; margin-top: 2px; }
.strong { color: #7dff9e; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
