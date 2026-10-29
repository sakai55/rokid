<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 点评页：呈现 lastVerdict 的三项粗查 + 一句人话点评；
// 用户覆盖口是本页的核心——「这字算过」以本人判断为准，覆盖落盘。
const PROG = 'trace.trace-brush.v1';
const TMP = 'trace.brush.tmp';
const ACTS = ['这字算过（本人改判）', '再写一张（去验收）', '换下一字', '返回今日页'];

export default {
  data: {
    status: '点评：LLM 只查粗项，最后算不算过你说了算',
    verdictLine: '尚无点评：先去验收页拍一张',
    missingLine: '',
    centerLine: '',
    diffLine: '',
    sumLine: '',
    countLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0;
    const t = loadKey(TMP, { char: CHARS[0].char });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
    const v = p.lastVerdict;
    const rec = (p.chars || {})[this._char.char] || { count: 0 };
    const mine = !!(v && v.char === this._char.char);
    let head = '尚无点评：先去验收页拍一张';
    if (v && !mine) head = '最近点评是「' + v.char + '」的，切到那个字看，或先验当前字';
    if (mine && v.clear) head = '「' + v.char + '」的粗查结果' + (v.review ? '（复习抽查）' : '');
    if (mine && !v.clear) head = '「' + v.char + '」这次没看清：请重拍';
    const ok = mine && v.clear;
    this.setData({
      verdictLine: head,
      missingLine: ok ? ('少笔多笔：' + v.missing) : '',
      centerLine: ok ? ('结构重心：' + v.center) : '',
      diffLine: ok ? ('最明显处：' + v.diff) : '',
      sumLine: ok ? ('一句话：' + v.summary) : '',
      countLine: '「' + this._char.char + '」已练 ' + (rec.count || 0) + ' 次' + (rec.passed ? ' · 已算过' : ''),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  passTap() {
    const p = loadKey(PROG, { chars: {}, days: {}, lastChar: '' });
    const v = p.lastVerdict;
    if (!v || v.char !== this._char.char) { this.setData({ status: '先验收这个字，再来改判（没判过不凭空算过）', evt: 'EVT: pass refused - no verdict' }); return; }
    const ch = this._char.char;
    const rec = (p.chars[ch] || { count: 0 });
    rec.count = (rec.count || 0) + 1;
    rec.passed = true;
    rec.lastAt = new Date().toISOString();
    rec.overrides = (rec.overrides || 0) + 1;
    p.chars[ch] = rec;
    const today = new Date().toISOString().slice(0, 10);
    p.days = p.days || {}; p.days[today] = true;
    p.lastChar = ch;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存失败：E5001（进度没落盘）', evt: 'EVT: pass save FAIL E5001' }); return; }
    this.setData({ status: '已记：「' + ch + '」算过（本人改判优先于机器判定）', evt: 'EVT: pass recorded ' + ch });
    speak(ch + '，已记算过');
    this._render();
  },
  againTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  nextCharTap() {
    const i = CHARS.indexOf(this._char);
    const n = CHARS[(i + 1) % CHARS.length];
    saveKey(TMP, { char: n.char, review: false });
    this._char = n;
    this.setData({ status: '下一字：' + n.char + '，去学字页看笔顺', evt: 'EVT: next char ' + n.char });
    try { wx.navigateTo({ url: '/pages/learn/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
    this._render();
  },
  homeTap() { try { wx.navigateBack({ delta: 10 }); } catch (e) { try { wx.navigateTo({ url: '/pages/index/index' }); } catch (e2) {} } },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.passTap(); else if (this._focus === 1) this.againTap(); else if (this._focus === 2) this.nextCharTap(); else this.homeTap(); },
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
    <text class="title">毛笔字描红 · 点评</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="vhead">{{verdictLine}}</text>
      <text class="rline">{{missingLine}}</text>
      <text class="rline">{{centerLine}}</text>
      <text class="rline">{{diffLine}}</text>
      <text class="rline strong">{{sumLine}}</text>
      <text class="rline dim">{{countLine}}</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">这字算过</button>
      <button class="act" bindtap="actTap" data-idx="1">再写一张</button>
      <button class="act" bindtap="actTap" data-idx="2">换下一字</button>
      <button class="act" bindtap="actTap" data-idx="3">回今日页</button>
    </view>
    <text class="note">改判规矩：机器判定只作参考，「算过」以你本人的判断为准并落盘计数；没验收过的字不能凭空算过。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border-left: 5px solid #40ff5e; background-color: #0a1f0e; padding: 6px 8px; margin-top: 5px; }
.vhead { color: #7dff9e; font-size: 14px; font-weight: 500; line-height: 19px; }
.rline { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 17px; margin-top: 2px; }
.strong { color: #7dff9e; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
