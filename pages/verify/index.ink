<script def>
{"title": "Trace Kana"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { CHARS } from '../../kana.js';

// チェックページ：下を向いて自分が書いた字を撮り、LLM が範字と比べて三つの粗い点だけを見る。
// 判定は進捗キーの lastVerdict に保存し、講評ページで表示と本人の直しを受け付ける。
const PROG = 'trace.trace-kana.v1';
const TMP = 'trace.kana.tmp';
const ACTS = ['写真チェック（または うなずき）', '字を変える（一覧）', '戻る BACK'];
const SYS = 'あなたは書道初学者の粗チェック担当です。指定された三つの粗い点だけを見ます。専門的な書道の採点はせず、点数も付けず、専門用語を並べません。見えなければ正直に見えないと言い、決して作り話をしません。';

export default {
  data: {
    status: 'チェック：自分が書いた字に下向きで合わせ、字全体を入れて撮る',
    targetLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    const t = loadKey(TMP, { char: CHARS[0].char, review: false });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    this._review = !!t.review;
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const c = this._char;
    this.setData({
      targetLine: this._review
        ? '復習テスト：範字は出しません。まず紙に「' + c.char + '」（' + c.romaji + '）を書いてから、下を向いて写真チェック'
        : '目標の字：' + c.char + '（' + c.romaji + ' · ' + c.strokes.length + '画）。自分が書いたこの字だけを撮ってください。他人の顔や別の字は撮らないでください',
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enter で実行）'
    });
  },
  _field(text, key) {
    if (!text) return '';
    const lines = String(text).split('\n');
    for (let i = 0; i < lines.length; i++) { const p = lines[i].indexOf(key + ':'); if (p >= 0) return lines[i].slice(p + key.length + 1).trim(); }
    return '';
  },
  async shootTap() {
    if (this._busy) return;
    this._busy = true;
    const c = this._char;
    this.setData({ status: '撮影中…紙に合わせて動かさないで', evt: 'EVT: verify shoot start ' + c.char });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '撮影済み（' + shot.note + '）、粗チェック中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '目標の字は「' + c.char + '」（' + c.strokes.length + '画、画の流れ：' + c.types.join('、') + '）。写真は練習者が紙に筆で書いたその字です。写真がその字でない、または字が見えない場合、1行目に CLEAR: NO と書いて理由を続け、それ以外は答えないでください。その字で見える場合、1行目は CLEAR: YES、2行目 MISSING: 画の過不足（なければ「なし」）、3行目 CENTER: 重心の偏り（なければ「安定」、偏ればその方向）、4行目 DIFF: 範字と比べて最も目立つ違い 1〜2 か所（なければ「なし」）、5行目 SUMMARY: 一言の講評（まず一言ほめてから、直すと最も良い一か所を）。点数は付けないでください。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const clear = this._field(raw, 'CLEAR').toUpperCase();
      const p = loadKey(PROG, { chars: {}, days: {}, lastChar: c.char });
      if (clear.indexOf('NO') >= 0) {
        p.lastVerdict = { char: c.char, clear: false, raw: raw.slice(0, 300), at: new Date().toISOString(), review: this._review };
        saveKey(PROG, p);
        this.setData({ status: '見えませんでした：字全体を画面に入れ、紙の反射を避けて、もう一度撮ってください', evt: 'EVT: verdict CLEAR NO' });
        speak('見えませんでした。もう一度撮ってください');
        return;
      }
      p.lastVerdict = {
        char: c.char, clear: true,
        missing: this._field(raw, 'MISSING') || '（未答）',
        center: this._field(raw, 'CENTER') || '（未答）',
        diff: this._field(raw, 'DIFF') || '（未答）',
        summary: this._field(raw, 'SUMMARY') || '（未答）',
        raw: raw.slice(0, 300), at: new Date().toISOString(), review: this._review
      };
      saveKey(PROG, p);
      this.setData({ status: '粗チェック完了。講評ページで結果を見てください（自分で「できた」に直せます）', evt: 'EVT: verdict saved' });
      speak('チェック完了。講評を見てください');
      try { wx.navigateTo({ url: '/pages/review/index' }); } catch (e) {}
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this.setData({ status: 'チェックできませんでした：' + code + '（そのまま表示しています。撮り直せます）', evt: 'EVT: verify FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  libraryTap() { try { wx.navigateTo({ url: '/pages/library/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.shootTap(); else if (this._focus === 1) this.libraryTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.shootTap(); },
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
    <text class="title">ひらがな なぞり · 写真チェック</text>
    <text class="status">{{status}}</text>
    <view class="framebox">
      <text class="target">{{targetLine}}</text>
      <text class="line dim">見るのは三つだけ：①画の過不足 ②重心 ③最も目立つ 1〜2 か所。判定は間違えることも、見えないこともあります——見えないときは正直に言い、講評ページで自分で直せます。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">写真チェック</button>
      <button class="act" bindtap="actTap" data-idx="1">字を変える</button>
      <button class="act" bindtap="actTap" data-idx="2">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kana</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.framebox { border: 2px dashed rgba(125,255,158,0.65); background-color: #04140a; padding: 8px; margin-top: 6px; }
.target { color: #7dff9e; font-size: 14px; font-weight: 500; line-height: 19px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 8px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
