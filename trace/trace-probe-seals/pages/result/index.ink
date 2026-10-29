<script def>
{"title": "Trace Probe Kuji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { SEALS } from '../../data.js';

// 結果ページ：一覧表（目標 / LLMの読み / 正解・不正解）＋ 集計。
// 正しさは装着者の確定が基準。測っていない印は「未テスト」と正直に出す。
const KEY = 'trace.probe.kuji.v1';
const MENU = ['記録を消して最初から', 'BACK もどる'];

export default {
  data: {
    status: '結果：真値はあなたの確定が基準',
    sumLine: '集計：―',
    rows: [],
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v2.0.0'
  },
  onLoad() { this._focus = 1; this._render(); },
  onShow() { this._render(); },
  _render() {
    const recs = loadKey(KEY, []);
    let right = 0, wrong = 0, judged = 0;
    const rows = SEALS.map(function (s, i) {
      const r = Array.isArray(recs) ? recs[i] : null;
      let tail = '未テスト';
      if (r && r.at) {
        judged++;
        if (r.truth === 'right') { right++; tail = '正解'; }
        else if (r.truth === 'wrong') { wrong++; tail = '不正解'; }
        else tail = '判定済み・未確定';
        return { idx: i, label: s.name + '（' + s.sub + '） → 「' + (r.guess || '読み取れず') + '」と判定 ・ ' + tail };
      }
      return { idx: i, label: s.name + '（' + s.sub + '） → ' + tail };
    });
    this.setData({
      rows: rows,
      sumLine: '集計：確定 ' + (right + wrong) + ' / ' + SEALS.length + ' ・ 正解 ' + right + ' ・ 不正解 ' + wrong + ' ・ 判定済み未確定 ' + (judged - right - wrong),
      focusLine: 'フォーカス：' + MENU[this._focus] + '（上下で切替、Enterで実行）'
    });
  },
  clearTap() {
    if (!saveKey(KEY, [])) { this.setData({ status: '記録を消せなかった：E5001', evt: 'EVT: clear FAIL E5001' }); return; }
    this.setData({ status: '記録を消した。説明ページから輪測をやり直せる', evt: 'EVT: cleared' });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.clearTap(); else this.backTap(); },
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
    <text class="title">印を結ぶ ・ 結果</text>
    <text class="status">{{status}}</text>
    <text class="sum">{{sumLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <text class="note">伝え方：このページの集計を口頭でメンテナに伝える。判定の原文は端末内の記録に残る。収録の目安：正解=計分範囲へ、不正解=練習のみ、判別できない印は再測のうえ収録しない。全体の正解が半分未満なら、正式版は自己評価方式に下げる。</text>
    <button class="banner ghost" bindtap="actTap" data-idx="0">記録を消して最初から</button>
    <button class="banner" bindtap="actTap" data-idx="1">BACK もどる</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.sum { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; margin-top: 2px; }
.rows { display: flex; flex-direction: column; margin-top: 3px; border-top: 1px solid rgba(64,255,94,0.35); }
.row { padding: 0px 5px; border-bottom: 1px solid rgba(64,255,94,0.18); }
.rtxt { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 13px; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.banner { color: #04140a; background-color: #40ff5e; padding: 4px; font-size: 12px; font-weight: 500; text-align: center; margin-top: 5px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
