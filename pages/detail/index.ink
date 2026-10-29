<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 字义 / 笔法页：读音、字义、结构、重心提示、逐笔类型清单、数据来源。
const TMP = 'trace.brush.tmp';
const ACTS = ['去学字', '去验收', '念要点（全笔）', '返回 BACK'];

export default {
  data: {
    status: '字义与笔法：先懂这个字，再下笔',
    bigChar: '',
    metaLine: '',
    centerLine: '',
    typesLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.3.4'
  },
  onLoad() {
    this._focus = 0;
    const t = loadKey(TMP, { char: CHARS[0].char });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const c = this._char;
    this.setData({
      bigChar: c.char,
      metaLine: c.pinyin + ' · ' + c.meaning + ' · ' + c.structure + ' · ' + c.strokes.length + ' 画',
      centerLine: '重心提示：' + c.center,
      typesLine: '逐笔：' + c.types.join(' → '),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  learnTap() { try { wx.navigateTo({ url: '/pages/learn/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  verifyTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  speakAllTap() { speak(this._char.char + '，' + this._char.strokes.length + '画。' + this._char.tips.join(' ')); this.setData({ evt: 'EVT: speak all tips' }); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.learnTap(); else if (this._focus === 1) this.verifyTap(); else if (this._focus === 2) this.speakAllTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
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
    <text class="title">毛笔字描红 · 字义笔法</text>
    <text class="status">{{status}}</text>
    <view class="stage">
      <text class="big">{{bigChar}}</text>
      <view class="rail">
        <text class="rline strong">{{metaLine}}</text>
        <text class="rline">{{centerLine}}</text>
        <text class="rline">{{typesLine}}</text>
      </view>
    </view>
    <view class="card">
      <text class="rline">笔法口径：要点是本系列自撰的粗练习提示（起笔 / 行笔 / 收笔），帮初学者把一笔写到位，不冒充书法专业评分。</text>
      <text class="rline dim">数据来源：分笔路径与笔顺取自 hanzi-writer-data（Make Me a Hanzi，Arphic Public License），笔画数与逐笔类型逐字人工核定，笔顺口径对《通用规范汉字笔顺规范》GF0023-2020。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">去学字</button>
      <button class="act" bindtap="actTap" data-idx="1">去验收</button>
      <button class="act" bindtap="actTap" data-idx="2">念要点（全笔）</button>
      <button class="act" bindtap="actTap" data-idx="3">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; gap: 10px; margin-top: 4px; align-items: flex-start; }
.big { color: #7dff9e; font-size: 74px; font-weight: 500; line-height: 84px; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 2px 12px; }
.rail { display: flex; flex-direction: column; flex-grow: 1; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.3); background-color: #04140a; padding: 5px 7px; margin-top: 6px; }
.rline { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 16px; margin-top: 2px; }
.strong { color: #7dff9e; font-size: 13px; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 4px 8px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
