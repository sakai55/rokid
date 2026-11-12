<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults } from '../../judge.js';
import { fail } from '../../err.js';
import { log, flushLog } from '../../logq.js';

// 首页：四站入口 + 结果单 + 设置自检，并显示上次结果摘要。
// 本探针为真境漫游阶段 1 采集真机事实，不占正式游戏本体、不提审。
const MENU = ['存储探针', '手势探针', '朝向探针', '判定耗时', '结果单', '设置 / 自检'];
const URLS = ['/pages/storage/index', '/pages/gesture/index', '/pages/heading/index', '/pages/timing/index', '/pages/result/index', '/pages/settings/index'];

export default {
  data: {
    status: '真境探针：四站测完，结果汇成一张结果单',
    sumLine: '上次结果：还没有任何记录',
    focusLine: '',
    cls0: 'banner', cls1: 'banner ghost', cls2: 'banner ghost', cls3: 'banner ghost', cls4: 'banner ghost', cls5: 'banner ghost',
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() { this._focus = 0; },
  onShow() { this._render(); },
  _render() {
    const r = loadResults();
    const parts = [];
    parts.push(r.storage ? '存储 已测' : '存储 未测');
    const gt = (r.gesture && r.gesture.trials) || [];
    parts.push('手势 ' + gt.filter(function (t) { return t && t.truth; }).length + '/10 已标真值');
    const ht = (r.heading && r.heading.trials) || [];
    parts.push('朝向 ' + ht.length + '/4 向');
    const tr = (r.timing && r.timing.runs) || [];
    parts.push('判定 ' + tr.length + '/3 次');
    const upd = {
      sumLine: '进度：' + parts.join(' · '),
      focusLine: '焦点：' + MENU[this._focus] + '（上下滑动切换，单击或点头执行）'
    };
    for (var i = 0; i < MENU.length; i++) upd['cls' + i] = (i === this._focus) ? 'banner' : 'banner ghost';
    this.setData(upd);
  },
  goTap(i) {
    if (i >= URLS.length) { try { wx.navigateBack({}); } catch (e) {} return; }
    try { wx.navigateTo({ url: URLS[i] }); }
    catch (e) { fail('E8001', e); this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { this.goTap(this._focus); },
  moveTap(d) { this._focus = (this._focus + d + MENU.length) % MENU.length; this.setData({ evt: 'EVT: focus ' + MENU[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    // 按键一律以 event.code 为准：真机 event.key 不可靠且会遮蔽 code
    // （v1.0.0 因此滑动/单击全灭，见 README Change Log 1.0.1）。
    var code = (event && event.code) || '';
    if (!code && event && event.key) code = event.key;
    if (code === 'Enter' || code === 'GlobalHook') this.doAct();
    else if (code === 'ArrowUp') this.moveTap(-1);
    else if (code === 'ArrowDown') this.moveTap(1);
    else if (code === 'Backspace') { try { wx.navigateBack({}); } catch (e) {} }
  },
  onKeyUp(event) {
    var code = (event && event.code) || '';
    if (!code && event && event.key) code = event.key;
    if ((code === 'Enter' || code === 'GlobalHook' || code === 'ArrowUp' || code === 'ArrowDown') && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="title">真境探针 · RealMUD</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">用途：给真境漫游（第一人称现实 MUD）阶段 1 测四组数——存储能存多少、手势判定认得准不准、转头朝向误差多大、拍照判定一趟要多久。</text>
      <text class="line">顺序任意，建议从存储开始；每站做完自动落盘，关掉重开不丢。回传：结果单页大字汇总，配了日志钥匙时也会上报（见设置页）。</text>
    </view>
    <button class="{{cls0}}" bindtap="actTap" data-idx="0">存储探针</button>
    <button class="{{cls1}}" bindtap="actTap" data-idx="1">手势探针（10 次）</button>
    <button class="{{cls2}}" bindtap="actTap" data-idx="2">朝向探针（4 向）</button>
    <button class="{{cls3}}" bindtap="actTap" data-idx="3">判定耗时（3 次）</button>
    <button class="{{cls4}}" bindtap="actTap" data-idx="4">结果单</button>
    <button class="{{cls5}}" bindtap="actTap" data-idx="5">设置 / 自检</button>
    <text class="line dim">{{sumLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <view class="foot-row">
      <text class="foot">{{evt}} · 探针（不提审）</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 5px 7px; margin-top: 4px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.banner { color: #04140a; background-color: #40ff5e; padding: 4px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 4px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.foot-row { display: flex; flex-direction: row; align-items: center; justify-content: flex-end; margin-top: auto; padding-top: 3px; }
.foot { flex-grow: 1; color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; }
.ver { color: rgba(125,255,158,0.75); font-family: monospace; font-size: 10px; line-height: 12px; text-align: right; }
</style>
