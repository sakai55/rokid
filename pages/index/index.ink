<script def>
{"title": "Trace Origami"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { WORKS } from '../../works.js';

// TR04 今日页（折纸工坊）：没折完的作品优先续折 + 今日推荐 + 总进度。
const PROG = 'trace.trace-origami.v1';
const TMP = 'trace.origami.tmp';
const MENU = ['继续折', '作品集', '成品结算', '我的进度'];

export default {
  data: {
    status: '折纸描红：一折一验，折错当步就知道',
    contLine: '',
    todayLine: '',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _prog() { return loadKey(PROG, { works: {}, days: {}, lastWork: '' }); },
  _work(id) { return WORKS.filter(function (w) { return w.id === id; })[0] || WORKS[0]; },
  _todayWork() {
    const now = new Date();
    const start = new Date(now.getFullYear(), 0, 0);
    const doy = Math.floor((now - start) / 86400000);
    return WORKS[doy % WORKS.length];
  },
  _current() {
    const p = this._prog();
    if (p.lastWork) {
      const w = this._work(p.lastWork);
      const rec = (p.works || {})[w.id] || { step: 0, done: 0 };
      if ((rec.step || 0) > 0 && (rec.step || 0) < w.steps.length) return w;
    }
    return this._todayWork();
  },
  _render() {
    const p = this._prog();
    const cur = this._current();
    const rec = (p.works || {})[cur.id] || { step: 0, done: 0 };
    const tw = this._todayWork();
    let kinds = 0, total = 0;
    Object.keys(p.works || {}).forEach(function (k) { const r = p.works[k]; if (r && r.done > 0) kinds++; total += (r.done || 0); });
    saveKey(TMP, { work: cur.id });
    this.setData({
      contLine: (rec.step > 0 && rec.step < cur.steps.length)
        ? '续折：' + cur.name + ' 折到第 ' + (rec.step + 1) + ' 步 / 共 ' + cur.steps.length + ' 步'
        : '新开：' + cur.name + '（' + cur.level + ' · ' + cur.steps.length + ' 步 · ' + cur.paper + '）',
      todayLine: '今日推荐：' + tw.name + '（' + tw.steps.length + ' 步）',
      sumLine: '作品集：已完成 ' + kinds + ' / ' + WORKS.length + ' 件 · 累计完成 ' + total + ' 次',
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行，点头=执行）'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    if (this._focus === 0) this._go('/pages/fold/index');
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
    <text class="title">折纸描红 · 工坊</text>
    <text class="status">{{status}}</text>
    <view class="crease-box">
      <text class="cont">{{contLine}}</text>
      <text class="line">{{todayLine}}</text>
      <text class="line dim">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">继续折</button>
      <button class="tag" bindtap="actTap" data-idx="1">作品集</button>
      <button class="tag" bindtap="actTap" data-idx="2">成品结算</button>
      <button class="tag" bindtap="actTap" data-idx="3">我的进度</button>
    </view>
    <text class="note">折法：中央范本是本步折形图（本步折线最亮），照着折完一步，把纸举到眼前拍照验形，只查粗项：轮廓大形、多边少边、折线方向反没反。过了才进下一步。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR04</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.crease-box { border: 1px dashed rgba(125,255,158,0.65); background-color: #03130a; padding: 7px 9px; margin-top: 6px; }
.cont { color: #7dff9e; font-size: 15px; font-weight: 500; line-height: 20px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
.tag { color: #7dff9e; background-color: #03130a; border: 1px solid rgba(125,255,158,0.55); border-left: 7px solid #40ff5e; border-radius: 2px; padding: 5px 10px 5px 7px; font-size: 12px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border-left: 7px solid #7dff9e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 7px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
