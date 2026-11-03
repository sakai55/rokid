<script def>
{"title": "Trace Kanji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak, drawGlyph } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 読み方と書き方ページ：読み・意味・構成・重心の目安・画の流れ・データ出典。
const TMP = 'trace.kanji.tmp';
const ACTS = ['学ぶ', '写真チェック', '要点を聞く（全画）', '戻る BACK'];

export default {
  data: {
    status: '読み方と書き方：字を知ってから書く',
    bigChar: '',
    metaLine: '',
    centerLine: '',
    typesLine: '',
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
    const c = this._char;
    this.setData({
      bigChar: c.char,
      metaLine: c.reading + ' · ' + c.meaning + ' · ' + c.structure + ' · ' + c.strokes.length + ' 画',
      centerLine: '重心の目安：' + c.center,
      typesLine: '画の流れ：' + c.types.join(' → '),
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enter で実行）'
    });
    this._drawBig();
  },
  _drawBig() {
    // 大字はホストのフォントで描かず、学ぶ画面と同じ分筆輪郭を塗る
    // （中国語フォントの字形で表示されるのを避ける）。Canvas は
    // レイアウト直後にしか描けないため、学ぶ画面と同じく遅延再描画する。
    const c = this._char; const self = this;
    const once = function () {
      try {
        const ctx = wx.createCanvasContext('bigCanvas');
        if (!ctx) return;
        ctx.fillStyle = '#04140a'; ctx.fillRect(0, 0, 150, 150);
        drawGlyph(ctx, c, 130, 10, 12);
      } catch (e) {}
    };
    once();
    setTimeout(once, 80);
    setTimeout(once, 450);
  },
  learnTap() { try { wx.navigateTo({ url: '/pages/learn/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  verifyTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  speakAllTap() { speak(this._char.char + '、' + this._char.strokes.length + '画。' + this._char.tips.join(' ')); this.setData({ evt: 'EVT: speak all tips' }); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.learnTap(); else if (this._focus === 1) this.verifyTap(); else if (this._focus === 2) this.speakAllTap(); else this.backTap(); },
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
    <text class="title">漢字 なぞり · 読み方と書き方</text>
    <text class="status">{{status}}</text>
    <view class="stage">
      <canvas id="bigCanvas" width="150" height="150" class="bigc"></canvas>
      <view class="rail">
        <text class="rline strong">{{metaLine}}</text>
        <text class="rline">{{centerLine}}</text>
        <text class="rline">{{typesLine}}</text>
      </view>
    </view>
    <view class="card">
      <text class="rline">要点の口径：要点は本シリーズ自作の粗い練習ヒント（入筆／運筆／収筆）で、初学者が一画を書き切るためのもの。書道の専門的な評価基準ではありません。</text>
      <text class="rline dim">データ出典：分筆の輪郭・中心線は hanzi-writer-data（Make Me a Hanzi、Arphic Public License）。画数と画の種類は全字照合済み。筆順は KanjiVG と照合し、「右」「田」「生」は日本式の順に入れ替え済み。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">学ぶ</button>
      <button class="act" bindtap="actTap" data-idx="1">写真チェック</button>
      <button class="act" bindtap="actTap" data-idx="2">要点を聞く</button>
      <button class="act" bindtap="actTap" data-idx="3">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · trace-kanji</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.bigc { width: 150px; height: 150px; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; }
.stage { display: flex; flex-direction: row; gap: 10px; margin-top: 4px; align-items: flex-start; }
.big { color: #7dff9e; font-size: 74px; font-weight: 500; line-height: 84px; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 2px 12px; }
.rail { display: flex; flex-direction: column; flex-grow: 1; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.3); background-color: #04140a; padding: 5px 7px; margin-top: 6px; }
.rline { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 16px; margin-top: 2px; }
.strong { color: #7dff9e; font-size: 13px; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 4px 8px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
