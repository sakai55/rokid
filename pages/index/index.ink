<script def>
{"title": "Trace Probe Sign"}
</script>

<script setup>
import wx from 'wx';
import { loadKey } from '../../judge.js';
import { SIGNS } from '../../data.js';

// 手話プローブ説明ページ（全日本語 UI）。
// 位置づけ：手話「練習」のための認識実験であり、翻訳ツールではない。
const KEY = 'trace.probe.sign.v1';
const MENU = ['測定をはじめる（22項目）', '結果を見る', 'もどる BACK'];

export default {
  data: {
    status: '指文字プローブ：説明を読んでから開始',
    doneLine: '進捗：未開始',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const recs = loadKey(KEY, []);
    const done = Array.isArray(recs) ? recs.filter(function (r) { return r && r.truth; }).length : 0;
    this.setData({
      doneLine: '進捗：測定済み ' + done + ' / ' + SIGNS.length + ' 項目（結果ページで一覧できます）',
      focusLine: 'フォーカス：' + MENU[this._focus] + '（上下で切替、Enter で実行、うなずき=実行）'
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
    <text class="title">指文字プローブ · 認識実験</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line warn">これは手話を学ぶ練習のための認識実験です。翻訳ツールではありません（リアルタイム翻訳に必要な連続追跡はこの眼鏡にはありません）。</text>
      <text class="line">目的：日本手話（JSL）の指文字と数字、静止写真で判定できる22項目を、LLM が写真からどこまで当てるか測ります。当たった項目だけが正式版の練習範囲に入ります。</text>
      <text class="line">進め方：項目ごとに範本（装着者視点の線画模式図）と要点が出ます。手を目の前に出して形を作り、うなずいて撮影、判定のあと自分で「正しい／違う」を確定します。</text>
      <text class="line">姿勢：手は目の前 30〜40cm、背景は無地、明るさは均一に。1項目につき撮影は1回（失敗したら1回だけ撮り直し可）。</text>
      <text class="line">視点：範本は装着者視点（自分の手の甲を見る向き）です。形は要点テキストが正、模式図は目安です。</text>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">測定をはじめる（22項目）</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">結果を見る</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">BACK もどる</button>
    <text class="line dim">{{doneLine}}</text>
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
.warn { color: #7dff9e; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.banner { color: #04140a; background-color: #40ff5e; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
