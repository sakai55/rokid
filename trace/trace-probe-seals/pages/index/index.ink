<script def>
{"title": "Trace Probe Kuji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { SEALS } from '../../data.js';

// 九字印プローブの説明ページ：一巡の進め方、姿勢、視点、真値の決め方。
// 本プローブは描紅シリーズの番号を持たず、一覧にも載らない。
// 結果が TR02 正式版の収録範囲を決める。
const KEY = 'trace.probe.kuji.v1';
const MENU = ['輪測をはじめる（9印）', '結果を見る', 'BACK もどる'];

export default {
  data: {
    status: '九字印の認識テスト：説明を読んでから輪測へ',
    doneLine: '進捗：まだ始まっていない',
    artLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v2.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const recs = loadKey(KEY, []);
    const done = Array.isArray(recs) ? recs.filter(function (r) { return r && r.truth; }).length : 0;
    const withArt = SEALS.filter(function (s) { return !!s.art; }).length;
    this.setData({
      doneLine: '進捗：確定済み ' + done + ' / ' + SEALS.length + ' 印（結果ページで一覧できる）',
      artLine: withArt === SEALS.length ? '見本データ：全印収録済み（再描画線画・装着者視点）' : ('見本データ：準備中（収録済み ' + withArt + ' / ' + SEALS.length + ' 印）。無い印は輪測で「見本準備中」と表示される'),
      focusLine: 'フォーカス：' + MENU[this._focus] + '（上下で切替、Enterで実行、うなずき=実行）'
    });
  },
  startTap() { try { wx.navigateTo({ url: '/pages/test/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  resultTap() { try { wx.navigateTo({ url: '/pages/result/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.startTap(); else if (this._focus === 1) this.resultTap(); else this.backTap(); },
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
    <text class="title">印を結ぶ ・ 認識プローブ</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">目的：LLMが定格写真で九字印（臨・兵・闘・者・皆・陳・烈・在・前）をどれだけ正しく読めるか測る。読めた印だけが正式版の計分範囲に入る。</text>
      <text class="line">進め方：1印ずつ見本と要点を示す。結べたら、うなずいて撮影し、LLMが9印の中から判定する。1巡およそ10分。</text>
      <text class="line">姿勢：両手を目の前およそ50cmに構える（見本は装着者視点＝自分の手の甲を見る向き）。背景は無地に近く、明るさは均一に。撮影は1印1回だけ（ぼけたら撮り直し可）。</text>
      <text class="line">真値：判定の正しさは、あなたが「正解／不正解」で決める。LLMの答えがそのまま真値にはならない。</text>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">輪測をはじめる（9印）</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">結果を見る</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">BACK もどる</button>
    <text class="line dim">{{doneLine}}</text>
    <text class="line dim">{{artLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · プローブ（番号なし）</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 5px 7px; margin-top: 4px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.banner { color: #04140a; background-color: #40ff5e; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
