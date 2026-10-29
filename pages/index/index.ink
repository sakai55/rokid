<script def>
{"title": "Trace Sketch"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey } from '../../judge.js';
import { PICS } from '../../pics.js';

// TR06 今日页（手账首页）：今日一图（按日期轮换）+ 上次画到哪 + 进度摘要。
const PROG = 'trace.trace-sketch.v1';
const TMP = 'trace.sketch.tmp';
const MENU = ['学今日一图', '去图库选图', '复习抽查', '我的进度'];

export default {
  data: {
    status: '简笔画描红：今天在本子上画一幅',
    todayLine: '',
    lastLine: '上次：还没画过',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _todayIdx() {
    const now = new Date();
    const start = new Date(now.getFullYear(), 0, 0);
    return Math.floor((now - start) / 86400000) % PICS.length;
  },
  _render() {
    const tp = PICS[this._todayIdx()];
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    let drawn = 0, total = 0;
    Object.keys(p.pics || {}).forEach(function (k) { const r = p.pics[k]; if (r && r.count > 0) drawn++; total += (r.count || 0); });
    const last = p.lastPic ? PICS.filter(function (x) { return x.id === p.lastPic; })[0] : null;
    saveKey(TMP, { pic: tp.id, review: false, peeked: false });
    this.setData({
      todayLine: '今日一图：' + tp.name + '（' + tp.strokes.length + ' 笔）',
      lastLine: last ? ('上次画到：' + last.name + '，可从图库接着画') : '上次：还没画过，从今日一图开始',
      sumLine: '进度：已画 ' + drawn + ' / ' + PICS.length + ' 幅 · 累计画过 ' + total + ' 次',
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行，点头=执行）'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    if (this._focus === 0) this._go('/pages/draw/index');
    else if (this._focus === 1) this._go('/pages/gallery/index');
    else if (this._focus === 2) this._go('/pages/review/index');
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
    <text class="title">简笔画描红 · 手账</text>
    <text class="status">{{status}}</text>
    <view class="ruled">
      <text class="rline strong">{{todayLine}}</text>
      <text class="rline">{{lastLine}}</text>
      <text class="rline dim">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="pen hot" bindtap="actTap" data-idx="0">学今日一图</button>
      <button class="pen" bindtap="actTap" data-idx="1">去图库选图</button>
      <button class="pen" bindtap="actTap" data-idx="2">复习抽查</button>
      <button class="pen" bindtap="actTap" data-idx="3">我的进度</button>
    </view>
    <text class="note">画法：中央范本逐笔亮起（当前笔最亮），在自己的手账纸上一笔一笔画完整幅，再拍照对形，只查粗项：漏线、比例最偏处、闭合图形开没开口。点评完你可自己改判。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR06</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.ruled { margin-top: 6px; border-top: 1px solid rgba(64,255,94,0.4); }
.rline { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 18px; padding: 3px 2px; border-bottom: 1px solid rgba(64,255,94,0.35); }
.rline.strong { color: #7dff9e; font-size: 15px; font-weight: 500; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: column; gap: 4px; margin-top: 8px; }
.pen { color: #7dff9e; background-color: #04140a; border: none; border-bottom: 2px solid rgba(125,255,158,0.6); padding: 5px 8px; font-size: 13px; text-align: left; }
.pen.hot { background-color: #0a2413; border-bottom: 3px solid #7dff9e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 7px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
