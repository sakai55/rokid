<script def>
{"title": "Trace Sketch"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../judge.js';
import { PICS } from '../../pics.js';

// TR06 复习抽查页：只给图名不给范本，凭记忆在纸上画完整幅，再去
// 验收页对形。抽查对象优先从已画过的图里随机抽；一张没画过时用
// 今日一图并如实标注。「偷看范本」会把 peeked 记进交接键，过关时
// 按协助完成记账（assisted），不冒充凭记忆。
const PROG = 'trace.trace-sketch.v1';
const TMP = 'trace.sketch.tmp';
const ACTS = ['画完了，去验收', '偷看范本一眼', '换一幅抽查', 'BACK'];

export default {
  data: {
    status: '复习抽查：只给名字，凭记忆画',
    quizLine: '',
    metaLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._roll(); this._render(); },
  onShow() { this._render(); },
  _roll() {
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    const learned = PICS.filter(function (x) { const r = (p.pics || {})[x.id]; return r && r.count > 0; });
    this._fresh = learned.length === 0;
    const pool = this._fresh ? PICS : learned;
    const prev = loadKey(TMP, { pic: '' });
    let cand = pool[Math.floor(Math.random() * pool.length)];
    if (pool.length > 1 && prev && prev.pic === cand.id) cand = pool[(pool.indexOf(cand) + 1) % pool.length];
    this._pic = cand;
    saveKey(TMP, { pic: cand.id, review: true, peeked: false });
  },
  _render() {
    const pic = this._pic;
    this.setData({
      quizLine: '抽查：' + pic.name,
      metaLine: this._fresh
        ? '还没画过任何一幅——这幅是今日图，先凭印象画，验完就知道差在哪（不算复习过关的记忆分，照常记次数）'
        : '这幅你画过：不看范本，凭记忆在纸上画完整幅（' + pic.strokes.length + ' 笔），画完去验收',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  checkTap() { try { wx.navigateTo({ url: '/pages/check/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  peekTap() {
    saveKey(TMP, { pic: this._pic.id, review: true, peeked: true });
    this.setData({ evt: 'EVT: peek recorded (assisted)' });
    speak('看范本，记好回去凭记忆画也行，但这次算协助完成');
    try { wx.navigateTo({ url: '/pages/draw/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  rollTap() { this._roll(); this.setData({ evt: 'EVT: reroll ' + this._pic.id }); this._render(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.checkTap();
    else if (this._focus === 1) this.peekTap();
    else if (this._focus === 2) this.rollTap();
    else this.backTap();
  },
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
    <text class="title">简笔画描红 · 复习抽查</text>
    <text class="status">{{status}}</text>
    <view class="quiz">
      <text class="quizname">{{quizLine}}</text>
      <text class="line">{{metaLine}}</text>
    </view>
    <view class="acts">
      <button class="pen hot" bindtap="actTap" data-idx="0">画完了，去验收</button>
      <button class="pen" bindtap="actTap" data-idx="1">偷看范本一眼</button>
      <button class="pen" bindtap="actTap" data-idx="2">换一幅抽查</button>
      <button class="pen" bindtap="actTap" data-idx="3">BACK</button>
    </view>
    <text class="note">抽查规矩：范本不给、只给名字；偷看过范本的这次过关记「协助完成」，不冒充凭记忆。</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR06</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.quiz { margin-top: 8px; border-top: 1px solid rgba(64,255,94,0.4); border-bottom: 1px solid rgba(64,255,94,0.35); padding: 8px 2px; }
.quizname { color: #7dff9e; font-size: 22px; font-weight: 500; line-height: 28px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: column; gap: 5px; margin-top: 9px; }
.pen { color: #7dff9e; background-color: #04140a; border: none; border-bottom: 2px solid rgba(125,255,158,0.6); padding: 5px 8px; font-size: 13px; text-align: left; }
.pen.hot { background-color: #0a2413; border-bottom: 3px solid #7dff9e; font-weight: 500; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 7px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
