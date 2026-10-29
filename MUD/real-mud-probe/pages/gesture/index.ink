<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults, saveResults, speak, takePhotoTimed, judgeImage, parseJudgeJson, clamp01 } from '../../judge.js';
import { fail, ERR } from '../../err.js';
import { log, flushLog } from '../../logq.js';

// 手势探针：开掌静态手势拍照判定，共 10 次。管线照架构 §5：
// 拍照 → data URL → LLM 结构化判定 {gesture, confidence,
// recognized[]}。判定对错不由 LLM 定——每次判定后由测试者
// （真值）标 对/错，累计认对 x/10 与每次把握度落盘。
// 这组数决定阶段 1 手势开门是机器判定还是降级自评（探针门）。
const ACTS = ['拍照判定', '判对', '判错', 'BACK 返回'];
const SYS = '你是手势识别探针的判定员。照片是佩戴者本人举在眼前的手，佩戴者视角。只许输出一个 JSON 对象，不要任何其他文字。';
const ASK = '看这张照片里的手势，只输出 JSON：{"gesture":"open_palm 或 other 或 none","confidence":0到1的小数,"recognized":["认出的东西"]}。gesture 取值：五指张开的手掌 = open_palm；是手但不是张开手掌 = other；看不到手或看不清 = none。confidence 是你对 gesture 判断的把握，看不清就给低分，不许硬猜。';

export default {
  data: {
    status: '手势探针：摆开掌，拍照判定，共 10 次',
    progLine: '进度：0/10',
    judgeLine: '判定：还没拍',
    truthLine: '真值：判定后由你标 对 / 错',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._busy = false; this._cur = null; this._render(); },
  onShow() { if (!this._busy) this._render(); },
  _trials() { const r = loadResults(); return r.gesture.trials || []; },
  _render() {
    const trials = this._trials();
    const marked = trials.filter(function (t) { return t && t.truth; });
    const right = marked.filter(function (t) { return t.truth === 'right'; }).length;
    this.setData({
      progLine: '进度：已标真值 ' + marked.length + '/10 · 当前认对 ' + right + ' 次' + (marked.length >= 10 ? ' · 本站完成' : ''),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击执行；摆好后点头也可拍照）'
    });
  },
  async shootTap() {
    if (this._busy) return;
    const trials = this._trials();
    const marked = trials.filter(function (t) { return t && t.truth; }).length;
    if (marked >= 10) { this.setData({ status: '10 次已测满。重测请到设置页清除结果', evt: 'EVT: gesture full' }); return; }
    if (this._cur) { this.setData({ status: '先给上一次判定标 对 / 错，再拍下一次', evt: 'EVT: truth pending' }); return; }
    this._busy = true;
    this.setData({ status: '拍照中…手掌保持不动', evt: 'EVT: shoot start' });
    try {
      const shot = await takePhotoTimed('default');
      this.setData({ status: '拍到（' + shot.note + '），LLM 判定中…', evt: 'EVT: judge start' });
      const raw = await judgeImage(shot.url, SYS, ASK);
      const obj = parseJudgeJson(raw);
      const conf = clamp01(obj.confidence);
      const gesture = (obj.gesture === 'open_palm' || obj.gesture === 'other' || obj.gesture === 'none') ? obj.gesture : null;
      if (gesture === null || conf === null) throw (function () { const e = new Error('judge schema invalid'); e.code = ERR.LLM_OUTPUT; return e; })();
      this._cur = { guess: gesture, confidence: conf, recognized: Array.isArray(obj.recognized) ? obj.recognized.slice(0, 5) : [], at: new Date().toISOString() };
      const gname = gesture === 'open_palm' ? '开掌' : (gesture === 'other' ? '其他手势' : '没看到手');
      this.setData({
        status: '判定是「' + gname + '」。你摆的确实是开掌、且它读对了，就标「判对」；读错了标「判错」',
        judgeLine: '判定：' + gname + ' · 把握 ' + conf.toFixed(2) + ' · 认出：' + (this._cur.recognized.join('、') || '无'),
        evt: 'EVT: judged ' + gesture + ' conf ' + conf
      });
      speak('判定是' + gname + '，请标对错');
    } catch (e) {
      const code = (e && e.code) || ERR.UNKNOWN;
      fail(code, e);
      this.setData({ status: '这次没测成：' + code + '（已记 lastError，不占次数，可重拍）', judgeLine: '判定：失败 ' + code, evt: 'EVT: shoot FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  truthTap(right) {
    if (!this._cur) { this.setData({ status: '还没有判定结果，先拍照判定', evt: 'EVT: truth refused' }); return; }
    const r = loadResults();
    const trial = { guess: this._cur.guess, confidence: this._cur.confidence, truth: right ? 'right' : 'wrong', at: this._cur.at };
    r.gesture.trials.push(trial);
    if (!saveResults(r)) { fail(ERR.SAVE, 'gesture trial save failed'); this.setData({ status: '真值保存失败：E5001（本次不算，请重标）', evt: 'EVT: truth save FAIL E5001' }); return; }
    log('gesture', '', 'n=' + r.gesture.trials.length + ' guess=' + trial.guess + ' conf=' + trial.confidence + ' truth=' + trial.truth);
    this._cur = null;
    const marked = r.gesture.trials.filter(function (t) { return t && t.truth; });
    const rightN = marked.filter(function (t) { return t.truth === 'right'; }).length;
    if (marked.length >= 10) { log('gesture-done', '', 'right=' + rightN + '/10'); flushLog(); }
    this.setData({
      status: '已记录：' + (right ? '判对' : '判错') + '（累计认对 ' + rightN + '/' + marked.length + '）' + (marked.length >= 10 ? '。本站完成，去结果单看汇总' : '，继续下一次'),
      truthLine: '真值：刚标为' + (right ? '对' : '错'),
      evt: 'EVT: truth ' + trial.truth
    });
    speak(right ? '记为判对' : '记为判错');
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.shootTap();
    else if (this._focus === 1) this.truthTap(true);
    else if (this._focus === 2) this.truthTap(false);
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod' && !this._cur) this.shootTap(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">手势探针 · 开掌</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">摆法：单手五指张开，举到眼前约 50 cm，手掌朝向镜头，背景尽量素、光线均匀。</text>
      <text class="line">判定只看一张定格照片，不是实时追踪。读错不怪你——测的就是它能读对几次。</text>
      <text class="line">每次判定后必须标真值才计入次数；失败（没拍到/没网）不占次数。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">拍照判定</button>
      <button class="act" bindtap="actTap" data-idx="1">判对</button>
      <button class="act" bindtap="actTap" data-idx="2">判错</button>
      <button class="act" bindtap="actTap" data-idx="3">BACK</button>
    </view>
    <text class="line">{{progLine}}</text>
    <text class="line">{{judgeLine}}</text>
    <text class="line">{{truthLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.card { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 5px 7px; margin-top: 4px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 6px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); padding: 5px 9px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
