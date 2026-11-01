<script def>
{"title": "Trace Kana"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../kana.js';

// 講評ページ：lastVerdict の三つの粗チェック＋一言講評を出す。
// 本人の「できた」判定が本ページの核——本人の判断を優先し、記録に残す。
const PROG = 'trace.trace-kana.v1';
const TMP = 'trace.kana.tmp';
const ACTS = ['この字はできた（本人判定）', 'もう一枚書く（チェックへ）', '次の字へ', '今日ページへ戻る'];

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
    ver: 'v1.0.1'
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
    const rec = (p.chars[ch] || { count: 0 });
    rec.count = (rec.count || 0) + 1;
    rec.passed = true;
    rec.lastAt = new Date().toISOString();
    rec.overrides = (rec.overrides || 0) + 1;
    p.chars[ch] = rec;
    const today = new Date().toISOString().slice(0, 10);
    p.days = p.days || {}; p.days[today] = true;
    p.lastChar = ch;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存に失敗：E5001（進捗が記録されませんでした）', evt: 'EVT: pass save FAIL E5001' }); return; }
    this.setData({ status: '記録しました：「' + ch + '」はできた（本人判定が機械判定より優先）', evt: 'EVT: pass recorded ' + ch });
    speak(ch + '、できたと記録しました');
    this._render();
  },
  againTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  nextCharTap() {
    const i = CHARS.indexOf(this._char);
    const n = CHARS[(i + 1) % CHARS.length];
    saveKey(TMP, { char: n.char, review: false });
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
    <text class="title">ひらがな なぞり · 講評</text>
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
      <button class="act" bindtap="actTap" data-idx="3">今日へ</button>
    </view>
    <text class="note">ルール：機械の判定は参考まで。「できた」は本人の判断を記録します。チェックしていない字を「できた」にはできません。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kana</text>
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
