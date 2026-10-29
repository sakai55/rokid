<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 进度页：跨会话进度总览（已练字集 / 每字次数 / 练习天数）+
// 复习抽查入口（随机抽字、只给拼音不给范字、去验收页写完再验）。
const PROG = 'trace.trace-brush.v1';
const TMP = 'trace.brush.tmp';
const ACTS = ['复习抽查（随机一字）', '清空进度（连点两次确认）', '返回 BACK'];
const WIN = 6;

export default {
  data: {
    status: '我的进度：下次打开接着练',
    sumLine: '',
    rows: [],
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.3.0'
  },
  onLoad() { this._focus = 0; this._armClear = false; this._off = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { chars: {}, days: {} });
    const practiced = CHARS.filter(function (c) { const r = (p.chars || {})[c.char]; return r && r.count > 0; });
    let total = 0;
    practiced.forEach(function (c) { total += p.chars[c.char].count; });
    const dayCount = Object.keys(p.days || {}).length;
    const rows = practiced.slice(this._off, this._off + WIN).map(function (c) {
      const r = p.chars[c.char];
      return { idx: c.char, label: c.char + ' ' + c.pinyin + ' · 练过 ' + r.count + ' 次' + (r.passed ? ' · 已算过' : '') };
    });
    this.setData({
      sumLine: '已练 ' + practiced.length + ' / ' + CHARS.length + ' 字 · 累计 ' + total + ' 次 · 练习天数 ' + dayCount + ' 天',
      rows: rows.length ? rows : [{ idx: 'none', label: '还没练过任何字——先从今日一字开始' }],
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行；进度列表自动跟随）'
    });
  },
  reviewTap() {
    const c = CHARS[Math.floor(Math.random() * CHARS.length)];
    saveKey(TMP, { char: c.char, review: true });
    this.setData({ status: '抽查字已抽好（验收页只给拼音）：' + c.pinyin, evt: 'EVT: review pick ' + c.char });
    speak('抽查，请写' + c.char);
    try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  clearTap() {
    if (!this._armClear) {
      this._armClear = true;
      this.setData({ status: '再点一次「清空进度」才会真的清空（防误删）', evt: 'EVT: clear armed' });
      return;
    }
    if (!saveKey(PROG, { chars: {}, days: {}, lastChar: '' })) { this.setData({ status: '清空失败：E5001', evt: 'EVT: clear FAIL E5001' }); return; }
    this._armClear = false;
    this.setData({ status: '进度已清空', evt: 'EVT: progress cleared' });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.reviewTap(); else if (this._focus === 1) this.clearTap(); else this.backTap(); },
  moveTap(d) {
    // 焦点在按钮间走；进度行多于一屏时，方向键先滚列表
    this._focus = (this._focus + d + ACTS.length) % ACTS.length;
    this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] });
    this._render();
  },
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
    <text class="title">毛笔字描红 · 进度</text>
    <text class="status">{{status}}</text>
    <text class="sum">{{sumLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.label}}</text></view>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">复习抽查</button>
      <button class="act" bindtap="actTap" data-idx="1">清空进度（两次确认）</button>
      <button class="act" bindtap="actTap" data-idx="2">BACK</button>
    </view>
    <text class="note">复习抽查：随机抽一字，验收页只给拼音、不给范字——先在纸上凭记忆写，再拍照验。进度保存在本机，跨会话接着练。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01 · 存储键 trace.trace-brush.v1</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.sum { color: #7dff9e; font-size: 12px; font-weight: 500; line-height: 16px; margin-top: 2px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; border-top: 1px solid rgba(64,255,94,0.35); }
.row { padding: 3px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.rtxt { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 16px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
