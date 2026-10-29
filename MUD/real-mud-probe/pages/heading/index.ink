<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults, saveResults, speak } from '../../judge.js';
import { fail, ERR } from '../../err.js';
import { log, flushLog } from '../../logq.js';

// 朝向探针：AbsoluteOrientationSensor 四元数 → yaw（舰队既有公式），
// 先校准（面朝一个已知方向定中心），再依次朝 4 个目标方位转头，
// 记录到达误差（度）与头稳耗时（ms）。传感器首读为 null 是正常
// 态，不当错误；启动后 5 秒无读数才按 E7008 报。
// 点头事件单独计数，测 onHeadGesture 通道是否通。
const ACTS = ['校准中心', '开始测向', 'BACK 返回'];
const TARGETS = [
  { name: '东', deg: 90 },
  { name: '南', deg: 180 },
  { name: '西', deg: 270 },
  { name: '北', deg: 0 }
];
const WIN_DEG = 10;      // 进入 ±10° 算朝向到达
const HOLD_MS = 800;     // 在窗口内连续停留 800ms 算头稳达成

function yawFromQuat(q) {
  if (!q || q.length < 4) return null;
  var x = q[0], y = q[1], z = q[2], w = q[3];
  var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
  return (yaw * 180 / Math.PI + 360) % 360;
}
function angDiff(a, b) { var d = Math.abs(a - b) % 360; return d > 180 ? 360 - d : d; }
function cardinal(deg) {
  const names = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
  return names[Math.round(deg / 45) % 8];
}

export default {
  data: {
    status: '朝向探针：先校准，再按提示转头朝向四方',
    yawLine: '当前朝向：等待传感器…',
    calLine: '校准：还没定中心',
    testLine: '测向：未开始（0/4）',
    nodLine: '点头计数：0（随时点头都计数）',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0;
    this._yaw = null; this._center = null; this._lastReadAt = 0; this._noDataFired = false;
    this._testing = false; this._targetIdx = 0; this._testStartAt = 0; this._holdAccum = 0; this._lastTick = 0;
    this._stable = false;
    const r = loadResults();
    this._nods = (r.heading && r.heading.nods) || 0;
    if (r.heading && r.heading.calibrated) this._center = 0; // 中心不跨会话存角度，只记「曾校准」；本页仍需重新校准
    this._center = null;
    try { this.enableWorldAwareness(); }
    catch (e) { fail(ERR.WORLD_AWARE, e); this.setData({ evt: 'EVT: world awareness FAIL E7006' }); }
    this._startSensor();
    const self = this;
    this._timer = setInterval(function () { self._tick(); }, 200);
    this._render();
  },
  onUnload() { this._stopAll(); },
  onHide() { this._stopAll(); },
  _stopAll() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
    if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; }
  },
  _startSensor() {
    const Ctor = (typeof AbsoluteOrientationSensor !== 'undefined') ? AbsoluteOrientationSensor : null;
    if (!Ctor) { fail(ERR.SENSOR_NA, 'AbsoluteOrientationSensor undefined'); this.setData({ yawLine: '当前朝向：传感器不可用 E7001', evt: 'EVT: sensor NA E7001' }); return; }
    const self = this;
    try {
      const s = new Ctor({ frequency: 10 });
      s.addEventListener('reading', function () {
        const deg = yawFromQuat(s.quaternion);
        if (deg === null) return; // 首读 null 是正常态
        self._yaw = deg; self._lastReadAt = Date.now();
      });
      s.addEventListener('error', function () {
        fail(ERR.SENSOR_NA, 'orientation sensor error event');
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ yawLine: '当前朝向：传感器出错 E7001', evt: 'EVT: sensor error E7001' });
      });
      s.start();
      this._sensor = s;
      this._sensorStartAt = Date.now();
    } catch (e) {
      fail(ERR.SENSOR_NA, e);
      this._sensor = null;
      this.setData({ yawLine: '当前朝向：传感器构造失败 E7001', evt: 'EVT: sensor ctor FAIL E7001' });
    }
  },
  _relYaw() { // 相对校准中心的朝向（未校准时用原始 yaw）
    if (this._yaw === null) return null;
    if (this._center === null) return this._yaw;
    return (this._yaw - this._center + 360) % 360;
  },
  _tick() {
    const now = Date.now();
    if (this._sensor && !this._lastReadAt && this._sensorStartAt && now - this._sensorStartAt > 5000 && !this._noDataFired) {
      this._noDataFired = true;
      fail(ERR.SENSOR_NODATA, 'no orientation reading in 5s');
      this.setData({ evt: 'EVT: sensor no data E7008' });
    }
    // 测向进行中：检查窗口与头稳累计
    if (this._testing && this._center !== null) {
      const rel = this._relYaw();
      const t = TARGETS[this._targetIdx];
      if (rel !== null && t) {
        const err = angDiff(rel, t.deg);
        const dt = this._lastTick ? (now - this._lastTick) : 200;
        if (err <= WIN_DEG) { this._holdAccum += dt; } else { this._holdAccum = 0; }
        if (this._holdAccum >= HOLD_MS) this._finishTarget(err, now - this._testStartAt);
      }
    }
    this._lastTick = now;
    // 朝向行节流刷新（每 tick 都刷会闪，靠 setData 同值无害处理）
    const rel2 = this._relYaw();
    this.setData({
      yawLine: rel2 === null ? '当前朝向：等待传感器…' : ('当前朝向：' + cardinal(rel2) + '（' + Math.round(rel2) + '°' + (this._center === null ? '，未校准为原始角' : '，相对中心') + '）')
    });
  },
  _finishTarget(errDeg, elapsedMs) {
    const t = TARGETS[this._targetIdx];
    const r = loadResults();
    r.heading.trials = (r.heading.trials || []).filter(function (x) { return x && x.target !== t.name; });
    r.heading.trials.push({ target: t.name, targetDeg: t.deg, errDeg: Math.round(errDeg * 10) / 10, steadyMs: elapsedMs, at: new Date().toISOString() });
    if (!saveResults(r)) fail(ERR.SAVE, 'heading trial save failed');
    log('heading', '', 'target=' + t.name + ' err=' + (Math.round(errDeg * 10) / 10) + 'deg steady=' + elapsedMs + 'ms');
    this._targetIdx++;
    this._holdAccum = 0;
    if (this._targetIdx >= TARGETS.length) {
      this._testing = false;
      log('heading-done', '', 'trials=' + r.heading.trials.length);
      flushLog();
      this.setData({ status: '四向测完，去结果单看平均误差', testLine: '测向：完成 4/4', evt: 'EVT: heading done' });
      speak('朝向四向测完');
    } else {
      this._testStartAt = Date.now();
      this.setData({ status: '记下了。下一个：转头朝向' + TARGETS[this._targetIdx].name + '，停稳别动', evt: 'EVT: next target ' + TARGETS[this._targetIdx].name });
      speak('下一个，朝向' + TARGETS[this._targetIdx].name);
    }
    this._render();
  },
  calTap() {
    if (this._yaw === null) { this.setData({ status: '传感器还没出数，等朝向行有数字再校准', evt: 'EVT: cal refused no yaw' }); return; }
    this._center = this._yaw;
    const r = loadResults(); r.heading.calibrated = true; saveResults(r);
    this.setData({ status: '中心已定：你现在面朝的方向就是「北（0°）」。测向时按相对这个中心转', calLine: '校准：已定中心（当前朝向 = 北 0°）', evt: 'EVT: calibrated' });
    speak('校准完成');
    this._render();
  },
  startTap() {
    if (this._center === null) { this.setData({ status: '先校准：面朝一个你认得的方向（比如正对窗户），点「校准中心」', evt: 'EVT: start refused no cal' }); return; }
    const r = loadResults();
    if ((r.heading.trials || []).length >= 4) { this.setData({ status: '四向已有记录。重测请到设置页清除结果', evt: 'EVT: heading full' }); return; }
    this._testing = true; this._targetIdx = (r.heading.trials || []).length; this._holdAccum = 0; this._testStartAt = Date.now();
    this.setData({ status: '开始：转头朝向' + TARGETS[this._targetIdx].name + '，在 ±10° 内停稳 0.8 秒自动记下', evt: 'EVT: heading start' });
    speak('开始测向，朝向' + TARGETS[this._targetIdx].name);
    this._render();
  },
  _render() {
    const r = loadResults();
    const trials = (r.heading && r.heading.trials) || [];
    this.setData({
      calLine: this._center === null ? '校准：还没定中心（先面朝已知方向再点校准）' : '校准：已定中心（当前朝向 = 北 0°）',
      testLine: '测向：已记 ' + trials.length + '/4' + (trials.length ? '（' + trials.map(function (t) { return t.target + ' 误差' + t.errDeg + '°'; }).join(' · ') + '）' : ''),
      nodLine: '点头计数：' + this._nods + '（随时点头都计数，测点头通道）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击执行；点头只计数不执行）'
    });
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.calTap(); else if (this._focus === 1) this.startTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onOrientationStabilityChange(event) {
    const d = (event && event.detail) || event || {};
    this._stable = !!(d.isStable === true || d.stable === true);
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || event || {};
    const g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') return;
    this._nods++;
    const r = loadResults(); r.heading.nods = this._nods; saveResults(r);
    log('nod', '', 'count=' + this._nods);
    this.setData({ evt: 'EVT: nod #' + this._nods });
    this._render();
  },
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
    <text class="title">朝向探针</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">校准：面朝一个你认得的方向站好，点「校准中心」——那个方向就记作北（0°）。</text>
      <text class="line">测向：依次朝东、南、西、北转头，在 ±10° 内停稳 0.8 秒，自动记下到达误差与用时。</text>
      <text class="line">点头：这一页点头只计数不执行任何操作，用来单测点头通道。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">校准中心</button>
      <button class="act" bindtap="actTap" data-idx="1">开始测向</button>
      <button class="act" bindtap="actTap" data-idx="2">BACK</button>
    </view>
    <text class="line big">{{yawLine}}</text>
    <text class="line">{{calLine}}</text>
    <text class="line">{{testLine}}</text>
    <text class="line">{{nodLine}}</text>
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
.line.big { font-size: 14px; color: #7dff9e; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 6px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); padding: 5px 9px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
