<script def>
{"title": "Trace Probe Seals"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { SEALS } from '../../data.js';

// 结果页：逐项表（目标 / LLM 认成什么 / 对错）+ 汇总认对数。
// 对错以 GO 的真值确认为准；未测的印如实标「未测」。
const KEY = 'trace.probe.seals.v1';
const MENU = ['清空重测', '返回 BACK'];

export default {
  data: {
    status: '结果：真值以你的确认为准',
    sumLine: '汇总：—',
    rows: [],
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 1; this._render(); },
  onShow() { this._render(); },
  _render() {
    const recs = loadKey(KEY, []);
    let right = 0, wrong = 0, judged = 0;
    const rows = SEALS.map(function (s, i) {
      const r = Array.isArray(recs) ? recs[i] : null;
      let tail = '未测';
      if (r && r.at) {
        judged++;
        if (r.truth === 'right') { right++; tail = '判定对'; }
        else if (r.truth === 'wrong') { wrong++; tail = '判定错'; }
        else tail = '已判未确认';
        return { idx: i, label: s.name + ' → 认成「' + (r.guess || '没认出') + '」 · ' + tail };
      }
      return { idx: i, label: s.name + ' → ' + tail };
    });
    this.setData({
      rows: rows,
      sumLine: '汇总：已确认 ' + (right + wrong) + ' / ' + SEALS.length + ' · 认对 ' + right + ' · 认错 ' + wrong + ' · 已判未确认 ' + (judged - right - wrong),
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  clearTap() {
    if (!saveKey(KEY, [])) { this.setData({ status: '清空失败：E5001', evt: 'EVT: clear FAIL E5001' }); return; }
    this.setData({ status: '已清空，可从说明页重新开始轮测', evt: 'EVT: cleared' });
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
    <text class="title">结印探针 · 结果</text>
    <text class="status">{{status}}</text>
    <text class="sum">{{sumLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <text class="note">回传方式：把本页汇总数口述给维护者即可；逐项原判定保存在本机记录里。收录门槛：认对进计分、认错只进练习、看不清复测后不收、全集认对不足一半，正式版降级自评。</text>
    <button class="banner ghost" bindtap="actTap" data-idx="0">清空重测</button>
    <button class="banner" bindtap="actTap" data-idx="1">BACK 返回</button>
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
