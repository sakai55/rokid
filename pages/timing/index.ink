<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults, saveResults, speak, takePhotoTimed, judgeImage, parseJudgeJson, clamp01 } from '../../judge.js';
import { fail, ERR } from '../../err.js';
import { log, flushLog } from '../../logq.js';

// 判定耗时探针：default 模式拍照建房判定全程分段计时，共 3 次。
// 分段：拍照 ms（开流+takePhoto）、编码 ms（缩图+转 data URL）、
// LLM ms（建房判定往返）、总 ms。每次附带把握度与认出物数，并
// 在开头并行发起一次非阻塞定位读取（成功记精度米数；失败记
// E7002/E7003，不挡判定、不计入总耗时）。
const ACTS = ['跑一次判定', 'BACK 返回'];
const SYS = '你是现实 MUD 的建房判定员。看一张佩戴者眼前场景的照片，把它写成一间 MUD 房间的数据。只许输出一个 JSON 对象，不要任何其他文字。看不清就把 confidence 给低、uncertain 写清，不许编造。';
const ASK = '只输出 JSON：{"recognized":["认出的主要东西，最多6个"],"sceneSummary":"一句话场景概括","confidence":0到1的小数,"uncertain":["没看清的东西"],"facesPresent":true或false,"privateOrDanger":true或false,"gesture":null}。facesPresent = 画面里有清晰真人面孔；privateOrDanger = 私人室内、禁入区域或危险场所。';

export default {
  data: {
    status: '判定耗时：对眼前随便拍一张，跑完整建房判定，共 3 次',
    runLine: '还没有记录（0/3）',
    geoLine: '定位：未读',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._busy = false; this._render(); },
  onShow() { if (!this._busy) this._render(); },
  _render() {
    const r = loadResults();
    const runs = (r.timing && r.timing.runs) || [];
    this.setData({
      runLine: runs.length ? runs.map(function (x, i) { return '第' + (i + 1) + '次：总 ' + x.totalMs + ' ms（拍 ' + x.photoMs + ' / 编 ' + x.encodeMs + ' / LLM ' + x.llmMs + '）· 把握 ' + x.confidence + ' · 认出 ' + x.recognizedCount + ' 物'; }).join('\n') : '还没有记录（0/3）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击或点头执行）'
    });
  },
  _geoStart(runIdx) {
    // 非阻塞：只挂回调，判定流程不等它。结果回来后补进对应记录。
    const self = this;
    try {
      if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) {
        this._geoDone(runIdx, null, ERR.GEO_FAIL);
        return;
      }
      navigator.geolocation.getCurrentPosition(
        function (pos) {
          const acc = pos && pos.coords ? pos.coords.accuracy : null;
          self._geoDone(runIdx, (typeof acc === 'number') ? Math.round(acc) : null, null);
        },
        function (err) {
          const code = err && err.code === 1 ? ERR.GEO_DENIED : ERR.GEO_FAIL;
          if (err && err.code === 1) fail(ERR.GEO_DENIED, 'geo permission denied');
          self._geoDone(runIdx, null, code);
        },
        { enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }
      );
    } catch (e) { this._geoDone(runIdx, null, ERR.GEO_FAIL); }
  },
  _geoDone(runIdx, acc, code) {
    const r = loadResults();
    const run = (r.timing.runs || [])[runIdx];
    if (run) {
      run.geoAcc = acc; run.geoCode = code || '';
      saveResults(r);
      log('timing-geo', code || '', 'run=' + (runIdx + 1) + (acc !== null ? ' acc=' + acc + 'm' : ' code=' + code));
    }
    this.setData({ geoLine: acc !== null ? ('定位：成功，精度 ±' + acc + ' 米') : ('定位：失败 ' + (code || '') + '（不挡判定）') });
    if (!this._busy) this._render();
  },
  async runTap() {
    if (this._busy) return;
    const r0 = loadResults();
    if ((r0.timing.runs || []).length >= 3) { this.setData({ status: '3 次已测满。重测请到设置页清除结果', evt: 'EVT: timing full' }); return; }
    this._busy = true;
    const runIdx = (r0.timing.runs || []).length;
    this.setData({ status: '第 ' + (runIdx + 1) + ' 次：拍照中…', evt: 'EVT: timing run start' });
    this._geoStart(runIdx);
    const t0 = Date.now();
    try {
      const shot = await takePhotoTimed('default');
      this.setData({ status: '拍到（' + shot.note + '），判定中…LLM 这段最久', evt: 'EVT: timing judge start' });
      const tL = Date.now();
      const raw = await judgeImage(shot.url, SYS, ASK);
      const llmMs = Date.now() - tL;
      const obj = parseJudgeJson(raw);
      const conf = clamp01(obj.confidence);
      if (conf === null || !Array.isArray(obj.recognized)) { const e2 = new Error('room judge schema invalid'); e2.code = ERR.LLM_OUTPUT; throw e2; }
      const totalMs = Date.now() - t0;
      const r = loadResults();
      r.timing.runs.push({
        photoMs: shot.photoMs, encodeMs: shot.encodeMs, llmMs: llmMs, totalMs: totalMs,
        confidence: conf, recognizedCount: obj.recognized.length,
        scene: String(obj.sceneSummary || '').slice(0, 60),
        geoAcc: null, geoCode: '', at: new Date().toISOString()
      });
      if (!saveResults(r)) fail(ERR.SAVE, 'timing run save failed');
      log('timing', '', 'run=' + (runIdx + 1) + ' photo=' + shot.photoMs + ' enc=' + shot.encodeMs + ' llm=' + llmMs + ' total=' + totalMs + ' conf=' + conf + ' rec=' + obj.recognized.length);
      if (r.timing.runs.length >= 3) { log('timing-done', '', 'runs=3'); flushLog(); }
      this.setData({
        status: '第 ' + (runIdx + 1) + ' 次完成：总 ' + totalMs + ' ms · 把握 ' + conf + ' · 认出 ' + obj.recognized.length + ' 物' + (r.timing.runs.length >= 3 ? '。本站完成' : '，可继续下一次'),
        evt: 'EVT: timing run done total ' + totalMs
      });
      speak('判定完成，总耗时' + Math.round(totalMs / 100) / 10 + '秒');
    } catch (e) {
      const code = (e && e.code) || ERR.UNKNOWN;
      fail(code, e);
      this.setData({ status: '这次失败：' + code + '（已记 lastError，不占次数，可重跑）', evt: 'EVT: timing FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.runTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
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
    <text class="title">判定耗时探针</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">测的是玩家真实体感：一趟「举手拍照 → 眼前变成一间房」要等多久，时间花在哪一段。</text>
      <text class="line">拍什么都行（你日常待的地方），照片不保存，判定完只留数字与一句概括。</text>
      <text class="line">每次同时顺手读一次定位（不阻塞）：成功记精度，失败记码，都不影响判定。</text>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">跑一次判定</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">BACK 返回</button>
    <text class="line">{{runLine}}</text>
    <text class="line">{{geoLine}}</text>
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
.banner { color: #04140a; background-color: #40ff5e; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
