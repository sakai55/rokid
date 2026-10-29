<script def>
{"title": "Trace Probe Sign"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { SIGNS } from '../../data.js';

// 結果ページ：項目ごとの表（目標 / LLM の回答 / 正誤）＋集計。
// 正誤は装着者本人が確定した真値が基準。未測定は正直に「未測定」。
const KEY = 'trace.probe.sign.v1';
const MENU = ['次の11件 / 前の11件', '消去して最初から', 'もどる BACK'];
const PER = 11;

export default {
  data: {
    status: '結果：真値は本人の確定が基準です',
    sumLine: '集計：—',
    rows: [],
    pageLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 2; this._page = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const recs = loadKey(KEY, []);
    let right = 0, wrong = 0, judged = 0;
    const all = SIGNS.map(function (s, i) {
      const r = Array.isArray(recs) ? recs[i] : null;
      let tail = '未測定';
      if (r && r.at) {
        judged++;
        if (r.truth === 'right') { right++; tail = '判定は正しい'; }
        else if (r.truth === 'wrong') { wrong++; tail = '判定は違う'; }
        else tail = '判定済み・未確定';
        return { idx: i, label: s.name + ' →「' + (r.guess || '読み取れず') + '」 · ' + tail };
      }
      return { idx: i, label: s.name + ' → ' + tail };
    });
    const rows = all.slice(this._page * PER, this._page * PER + PER);
    this.setData({
      rows: rows,
      sumLine: '集計：確定 ' + (right + wrong) + ' / ' + SIGNS.length + ' · 正解 ' + right + ' · 不正解 ' + wrong + ' · 未確定 ' + (judged - right - wrong),
      pageLine: '表示：' + (this._page * PER + 1) + '〜' + Math.min(SIGNS.length, this._page * PER + PER) + ' 件目（全 ' + SIGNS.length + ' 件）',
      focusLine: 'フォーカス：' + MENU[this._focus] + '（上下で切替、Enter で実行）'
    });
  },
  pageTap() { this._page = (this._page + 1) % Math.ceil(SIGNS.length / PER); this.setData({ evt: 'EVT: page ' + this._page }); this._render(); },
  clearTap() {
    if (!saveKey(KEY, [])) { this.setData({ status: '消去に失敗しました：E5001', evt: 'EVT: clear FAIL E5001' }); return; }
    this.setData({ status: '消去しました。説明ページから再開できます', evt: 'EVT: cleared' });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.pageTap(); else if (this._focus === 1) this.clearTap(); else this.backTap(); },
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
    <text class="title">指文字プローブ · 結果</text>
    <text class="status">{{status}}</text>
    <text class="sum">{{sumLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{pageLine}}</text>
    <text class="note">報告方法：このページの集計を口頭でメンテナへ伝えてください。収録基準：当たった項目だけ正式版の範囲に入り、外れた項目は採点なしの練習のみ、見えない項目は再測定のうえ収録しません。</text>
    <button class="banner ghost" bindtap="actTap" data-idx="0">次の11件 / 前の11件</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">消去して最初から</button>
    <button class="banner" bindtap="actTap" data-idx="2">BACK もどる</button>
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
