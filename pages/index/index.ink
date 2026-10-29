<script def>
{"title": "Trace Plating"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { PLATINGS } from '../../platings.js';

// TR07 今日页：没摆完的构图优先续练 + 今日推荐 + 总进度。
const PROG = 'trace.trace-plating.v1';
const TMP = 'trace.plating.tmp';
const MENU = ['继续练', '构图集', '结算', '我的进度'];

export default {
  data: {
    status: '摆盘描红：一步一摆，一摆一对，过与不过你自定',
    contLine: '',
    todayLine: '',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _prog() { return loadKey(PROG, { done: {}, today: '', lastItem: '' }); },
  _plating(id) { return PLATINGS.filter(function (w) { return w.id === id; })[0] || PLATINGS[0]; },
  _todayPlating() {
    const now = new Date();
    const start = new Date(now.getFullYear(), 0, 0);
    const doy = Math.floor((now - start) / 86400000);
    return PLATINGS[doy % PLATINGS.length];
  },
  _current() {
    const p = this._prog();
    if (p.lastItem) {
      const w = this._plating(p.lastItem);
      const rec = (p.done || {})[w.id] || { step: 0, count: 0 };
      if ((rec.step || 0) > 0 && (rec.step || 0) < w.steps.length) return w;
    }
    return this._todayPlating();
  },
  _render() {
    const p = this._prog();
    const cur = this._current();
    const rec = (p.done || {})[cur.id] || { step: 0, count: 0 };
    const tw = this._todayPlating();
    let kinds = 0, total = 0;
    Object.keys(p.done || {}).forEach(function (k) { const r = p.done[k]; if (r && r.count > 0) kinds++; total += (r.count || 0); });
    saveKey(TMP, { plating: cur.id });
    this.setData({
      contLine: (rec.step > 0 && rec.step < cur.steps.length)
        ? '续练：' + cur.name + ' 摆到第 ' + (rec.step + 1) + ' 步 / 共 ' + cur.steps.length + ' 步'
        : '新开：' + cur.name + '（' + cur.level + ' · ' + cur.steps.length + ' 步 · ' + cur.dish + '）',
      todayLine: '今日推荐：' + tw.name + '（' + tw.steps.length + ' 步）',
      sumLine: '构图集：已完成 ' + kinds + ' / ' + PLATINGS.length + ' 套 · 累计完成 ' + total + ' 次',
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行，点头=执行）'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    if (this._focus === 0) this._go('/pages/practice/index');
    else if (this._focus === 1) this._go('/pages/gallery/index');
    else if (this._focus === 2) this._go('/pages/finish/index');
    else this._go('/pages/progress/index');
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
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
    <text class="title">摆盘描红 · 今日</text>
    <text class="status">{{status}}</text>
    <view class="plate-box">
      <text class="cont">{{contLine}}</text>
      <text class="line">{{todayLine}}</text>
      <text class="line dim">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">继续练</button>
      <button class="tag" bindtap="actTap" data-idx="1">构图集</button>
      <button class="tag" bindtap="actTap" data-idx="2">结算</button>
      <button class="tag" bindtap="actTap" data-idx="3">我的进度</button>
    </view>
    <text class="note">练法：中央范本是本步摆盘构图线条示意图的文字描述（盘内分区与落位），照着摆完一步，把盘举到眼前拍照对位；本台是自评描红——LLM 只给三粗项差异提示（主菜落位 / 色块分区 / 留白边距），过与不过由你自定，不硬判。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR07 · 自评描红：LLM 只提示差异，过与不过你自定</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.plate-box { border: 2px solid rgba(125,255,158,0.65); border-radius: 20px; background-color: #03130a; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 7px 9px; margin-top: 6px; }
.cont { color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 20px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 20px; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 5px 10px; font-size: 12px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 7px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
