<script def>
{
  "title": "Probe Camera"
}
</script>

<script setup>
import { VER, fail, errText, errName, utf8Len, matchPayload, probeDetector, makeDetector, patchState, readState, withTimeout } from '../../qrprobe.js';
import { errLine } from '../../err.js';

function camCodeFor(e) {
  var nm = errName(e);
  if (nm === 'NotAllowedError') return 'E1002';
  if (nm === 'NotFoundError') return 'E1007';
  if (nm === 'NotReadableError') return 'E1008';
  return 'E1001';
}

export default {
  data: {
    evt: 'EVT: camera ready',
    ver: 'v' + VER,
    statusLine: '相机读码站 · 未运行',
    progLine: '',
    rows: [],
    failLine: '',
    hintLine: '单击拍照读码（对准手机或纸上的二维码）· 双击返回'
  },
  onLoad() {
    this._running = false;
    this._dead = false;
    this._lastAct = 0;
    this._sessionBest = 0;
    var st = readState();
    if (st.camera && st.camera.best) {
      this._set({ statusLine: '相机读码站 · 历史最佳 ' + st.camera.best.bytes + ' B（' + (st.camera.best.match ? '探针载荷' : '外部码') + '）' });
    }
  },
  onUnload() { this._dead = true; },
  _set(obj) { if (!this._dead) { try { this.setData(obj); } catch (e) {} } },
  _dup() {
    var now = Date.now();
    if (now - this._lastAct < 400) return true;
    this._lastAct = now;
    return false;
  },
  runTap() { if (!this._dup()) this._run(); },
  _show(lines, failCode) {
    var rows = [];
    for (var i = 0; i < lines.length; i++) rows.push({ text: lines[i] });
    this._set({ rows: rows, failLine: failCode ? errLine(failCode) : '' });
  },
  async _openStream() {
    try {
      return await withTimeout(navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 640 }, height: { ideal: 480 } }
      }), 9000, 'camera ideal');
    } catch (e) {
      return await withTimeout(navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
    }
  },
  async _run() {
    if (this._running) return;
    this._running = true;
    this._set({ statusLine: '相机读码站 · 运行中', progLine: '打开相机…', rows: [], failLine: '', evt: 'EVT: camera run' });
    var stream = null;
    try {
      // ---- detector first: no point opening the camera without it
      var det = await probeDetector();
      patchState(function (st) {
        st.detector = { available: det.available, formats: det.formats, qr: det.qr, errCode: det.errCode, raw: det.raw, ts: Date.now() };
      });
      if (!det.available || !det.qr) {
        var gc = det.available ? (det.errCode || 'E7005') : 'E7009';
        fail(gc, det.raw);
        this._show(['检测器守卫态，未开相机'], gc);
        this._set({ progLine: '', statusLine: '相机读码站 · 检测器不可用' });
        return;
      }
      var detector = null;
      try { detector = makeDetector(); } catch (e) {
        fail('E7009', errText(e));
        this._show(['检测器构造失败'], 'E7009');
        this._set({ progLine: '', statusLine: '相机读码站 · 检测器不可用' });
        return;
      }
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        fail('E1001', 'mediaDevices.getUserMedia missing');
        this._show(['相机接口不存在'], 'E1001');
        this._set({ progLine: '', statusLine: '相机读码站 · 相机不可用' });
        return;
      }
      if (typeof ImageCapture === 'undefined') {
        fail('E1003', 'ImageCapture undefined');
        this._show(['ImageCapture 不可用'], 'E1003');
        this._set({ progLine: '', statusLine: '相机读码站 · 拍照器不可用' });
        return;
      }
      try {
        stream = await this._openStream();
      } catch (e) {
        var cc = camCodeFor(e);
        fail(cc, errText(e));
        this._show(['相机打开失败'], cc);
        this._set({ progLine: '', statusLine: '相机读码站 · 打开失败' });
        return;
      }
      var track = stream.getVideoTracks()[0];
      if (!track) {
        fail('E1001', 'no video track');
        this._show(['无视频轨道'], 'E1001');
        this._set({ progLine: '', statusLine: '相机读码站 · 打开失败' });
        return;
      }
      var cap = null;
      try { cap = new ImageCapture(track); } catch (e) {
        fail('E1003', errText(e));
        this._show(['ImageCapture 构造失败'], 'E1003');
        this._set({ progLine: '', statusLine: '相机读码站 · 拍照器不可用' });
        return;
      }

      // ---- photo: telephoto first, default as the fallback mode
      this._set({ progLine: '拍照（telephoto）…' });
      var blob = null, mode = 'telephoto', photoErr = null, firstPhotoErr = null;
      try {
        blob = await withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'photo telephoto');
      } catch (e) {
        photoErr = e;
        firstPhotoErr = e;
        this._set({ progLine: 'telephoto 失败，回退 default…' });
        try {
          blob = await withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'photo default');
          mode = 'default';
          photoErr = null;
        } catch (e2) { photoErr = e2; }
      }
      if (!blob) {
        // Both modes failed: a mode-flavoured failure maps to E1010,
        // anything else to the generic photo failure E1009.
        var bothErr = errText(firstPhotoErr) + ' ' + errText(photoErr);
        var pc = /mode|Overconstrained/i.test(bothErr) ? 'E1010' : 'E1009';
        fail(pc, errText(photoErr));
        this._show(['拍照失败（两模式均失败）'], pc);
        this._set({ progLine: '', statusLine: '相机读码站 · 拍照失败' });
        return;
      }

      // ---- decode the photo
      this._set({ progLine: '检测中…' });
      var res = null, detErr = null;
      try { res = await detector.detect(blob); } catch (e) { detErr = e; }
      if (detErr) {
        fail('E7004', errText(detErr));
        this._show(['照片已拍（' + mode + '），检测抛错'], 'E7004');
        this._set({ progLine: '', statusLine: '相机读码站 · 检测失败' });
        return;
      }
      if (!res || !res.length) {
        // detect() resolving with [] is a measurement outcome, not an
        // error: the photo simply held no readable code.
        this._show(['照片已拍（' + mode + '）', '未识别到二维码（换角度/距离再试）'], '');
        this._set({ progLine: '', statusLine: '相机读码站 · 未识别' });
        return;
      }
      var raw = (res[0] && res[0].rawValue) || '';
      var bytes = utf8Len(raw);
      var matched = matchPayload(raw);
      var head = raw.slice(0, 24);
      var tail = raw.length > 40 ? raw.slice(-12) : '';
      var lines = [
        '解码成功 · ' + bytes + ' B · 模式 ' + mode,
        matched ? '与探针载荷一致（' + matched + ' B）' : '外部码（非探针载荷）',
        '头：' + head + (tail ? ' … 尾：' + tail : '')
      ];
      if (bytes > this._sessionBest) this._sessionBest = bytes;
      lines.push('本次会话最佳 ' + this._sessionBest + ' B');
      var rec = { bytes: bytes, match: matched > 0, mode: mode, preview: head, ts: Date.now() };
      patchState(function (st) {
        st.camera.last = rec;
        if (!st.camera.best || bytes > st.camera.best.bytes) st.camera.best = rec;
      });
      var stNow = readState();
      if (stNow.camera.best) lines.push('历史最佳 ' + stNow.camera.best.bytes + ' B');
      this._show(lines, '');
      this._set({ progLine: '', statusLine: '相机读码站 · 解码成功', evt: 'EVT: camera decoded ' + bytes });
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      }
      this._running = false;
    }
  },
  onKeyDown(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (!this._dup()) this._run(); }
  },
  onKeyUp(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (event.preventDefault) event.preventDefault(); }
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">CAM · 相机读码站</text>
    <text class="status">{{statusLine}}</text>
    <text class="prog">{{progLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <view class="runbtn" bindtap="runTap"><text class="runbtn-txt">▶ 拍照并读码</text></view>
    <text class="fail" ink:if="{{failLine}}">{{failLine}}</text>
    <text class="hint">{{hintLine}}</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.status { color: #40ff5e; font-size: 13px; margin-top: 5px; }
.prog { color: #7dff9e; font-family: monospace; font-size: 12px; margin-top: 5px; }
.rows { display: flex; flex-direction: column; margin-top: 6px; }
.row { margin-top: 2px; }
.rtxt { color: #7dff9e; font-size: 15px; line-height: 21px; }
.runbtn { margin-top: 8px; border: 1px solid #40ff5e; padding: 6px 10px; }
.runbtn-txt { color: #7dff9e; font-size: 15px; font-weight: 500; }
.fail { color: #000000; background-color: #40ff5e; font-size: 13px; font-weight: 500; margin-top: 6px; padding: 2px 6px; }
.hint { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
