<script def>
{"title": "Trace Probe Seals"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { SEALS } from '../../data.js';

// 结印探针说明页：讲清一轮怎么跑、摆位、视角与真值口径。
// 本探针不占描红系列编号、不上清单；结果决定 TR02 正式版收录范围。
const KEY = 'trace.probe.seals.v1';
const MENU = ['开始轮测（12 印）', '查看结果', '返回 BACK'];

export default {
  data: {
    status: '结印识别探针：先看说明，再开始轮测',
    doneLine: '进度：未开始',
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
      doneLine: '进度：已测 ' + done + ' / ' + SEALS.length + ' 印（结果页可看逐项表）',
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行，点头=执行）'
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
    <text class="title">结印探针 · 识别试验</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">目的：测 LLM 拍照认十二基本印（子丑寅卯辰巳午未申酉戌亥）到底准不准，认对的才进正式版计分范围。</text>
      <text class="line">一轮约 10 分钟：逐印看连续 3 帧范本（起手→交指中段→成印定格），照要点摆到定格，点头拍照判定。</text>
      <text class="line">摆位：双手举到眼前约 30–40cm，背景尽量素、光线均匀；每个印只拍一张（拍糊可重拍一次）。</text>
      <text class="line">视角：范本是佩戴者视角线条示意图（你看自己手背的方向），手指配置以要点文字为准。</text>
      <text class="line">真值：判定后由你点「判定对 / 判定错」定对错，LLM 说了不算；结果落盘，结果页可逐项回看。</text>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">开始轮测（12 印）</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">查看结果</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{doneLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · 探针不占编号</text>
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
