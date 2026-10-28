<script def>
{
  "title": "Tri Shot Shoot"
}
</script>

<script setup>
import wx from 'wx';

var TKEY = 'av01_target';
var CKEY = 'av01_current';
var MODES = [
  { mode: 'wide', label: 'WIDE 广角', note: 'quality 默认 · 扫大面' },
  { mode: 'telephoto', label: 'TELE 长焦', note: 'quality 默认 · 远读小字' },
  { mode: 'default', label: 'DEFAULT 全幅', note: 'quality 默认 · 最高像素' }
];

export default {
  data: {
    evt: 'EVT: shoot ready',
    ver: 'v1.0.1',
    status: '对准对象，单击开始三镜连拍',
    targetName: '-',
    busy: false,
    steady: false,
    cropLine: '中心裁片：未生成',
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    var name = '-';
    try {
      var v = wx.getStorageSync(TKEY);
      var o = (typeof v === 'string') ? JSON.parse(v) : v;
      if (o && o.name) name = o.name;
    } catch (e) {}
    this.setData({ targetName: name });
    this._syncRows(null);
  },
  _syncRows(results) {
    var rows = MODES.map(function (m, i) {
      var r = results && results[i];
      return {
        label: m.label,
        note: m.note,
        line: r ? (r.pix + ' · ' + r.bytes + 'B') : '待拍',
        cls: r ? 'shot shot-done' : 'shot'
      };
    });
    this.setData({ rows: rows });
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onShootTap() { this._shootAll(); },
  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      var buf = await blob.arrayBuffer();
      var bytes = new Uint8Array(buf);
      var bin = '';
      var CH = 0x8000;
      for (var i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: ' + String((e && e.message) || e).slice(0, 40));
    }
  },
  // Centre crop: drawImage with the 9-argument (source-rect -> dest-rect)
  // form on a document canvas, then canvas.convertToBlob(jpeg, 0.7) and
  // blob-to-dataURL for the LLM. Falls back to the raw photo
  // data URL when the host has no document canvas / convertToBlob.
  async _cropDataUrl(blob) {
    try {
      if (typeof document === 'undefined' || typeof createImageBitmap === 'undefined') return await this._blobToDataUrl(blob);
      var bmp = await createImageBitmap(blob);
      try {
        var sw = Math.floor(bmp.width / 2), sh = Math.floor(bmp.height / 2);
        var sx = Math.floor((bmp.width - sw) / 2), sy = Math.floor((bmp.height - sh) / 2);
        var cv = document.createElement('canvas');
        cv.width = 240; cv.height = 180;
        var ctx = cv.getContext('2d');
        ctx.drawImage(bmp, sx, sy, sw, sh, 0, 0, 240, 180);
        if (typeof cv.convertToBlob === 'function') {
          var cb = await cv.convertToBlob({ type: 'image/jpeg', quality: 0.7 });
          return await this._blobToDataUrl(cb);
        }
        if (typeof cv.toDataURL === 'function') return cv.toDataURL('image/jpeg', 0.7);
        return await this._blobToDataUrl(blob);
      } finally { try { bmp.close(); } catch (e) {} }
    } catch (e) { return await this._blobToDataUrl(blob); }
  },
  async _shootAll() {
    if (this.data.busy) return;
    var self = this;
    this.setData({ busy: true, status: '连拍中…', evt: 'EVT: shoot start' });
    var stream = null;
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') {
        this.setData({ status: '宿主无相机/ImageCapture，待真机连拍（不生成假照片）', evt: 'EVT: camera n/a' });
        return;
      }
      stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var cap = new ImageCapture(track);
      var results = [];
      for (var i = 0; i < MODES.length; i++) {
        var blob = await cap.takePhoto({ mode: MODES[i].mode });
        var pix = '?x?';
        if (typeof createImageBitmap !== 'undefined') {
          var bmp = await createImageBitmap(blob);
          pix = bmp.width + 'x' + bmp.height;
          try { bmp.close(); } catch (e) {}
        }
        var dataUrl = await this._cropDataUrl(blob);
        results.push({ mode: MODES[i].mode, pix: pix, bytes: blob.size, dataUrl: dataUrl });
        this._syncRows(results);
        this.setData({ evt: 'EVT: shot ' + MODES[i].mode + ' ' + pix });
      }
      this.setData({ cropLine: '中心裁片：3 张已生成（240x180 · jpeg q0.7）', status: '连拍完成，去对照结论' });
      try { wx.setStorageSync(CKEY, { target: this.data.targetName, at: Date.now(), shots: results }); } catch (e) {}
      this._speak('连拍完成');
      setTimeout(function () { try { wx.navigateTo({ url: '/pages/verdict/index' }); } catch (e) {} }, 700);
    } catch (e) {
      this.setData({ status: '连拍失败（如实记录）：' + String((e && e.message) || e).slice(0, 48), evt: 'EVT: shoot fail' });
    } finally {
      if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} }
      this.setData({ busy: false });
    }
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter' || k === 'GlobalHook') this._shootAll();
    else if (k === 'ArrowDown' || k === 'ArrowUp') this.setData({ evt: 'EVT: steady=' + this.data.steady + ' · 单击连拍' });
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._shootAll(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ steady: s, evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="backbtn" bindtap="onBackTap">BACK</button>
      <text class="ttl">SHOOT · 连拍</text>
      <text class="tgt">对象 {{targetName}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="film">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="slabel">{{item.label}}</text>
        <text class="sline">{{item.line}}</text>
        <text class="snote">{{item.note}}</text>
      </view>
    </view>
    <text class="crop">{{cropLine}}</text>
    <button class="sqbtn sqbtn-main" bindtap="onShootTap">SHOOT 三镜连拍</button>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { border-radius: 0; border: 1px solid rgba(64,255,94,0.8); background-color: #04140a; color: rgba(125,255,158,0.9); font-size: 10px; padding: 3px 8px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 16px; font-weight: 500; text-align: center; }
.tgt { color: #40ff5e; font-size: 12px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.film { display: flex; flex-direction: row; margin-top: 8px; }
.shot { flex-grow: 1; border: 1px dashed rgba(64,255,94,0.6); background-color: #04140a; padding: 8px 6px; margin-right: 6px; border-radius: 0; }
.shot-done { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.slabel { color: #40ff5e; font-size: 12px; font-weight: 500; }
.sline { color: #7dff9e; font-family: monospace; font-size: 10px; margin-top: 3px; }
.snote { color: rgba(64,255,94,0.6); font-size: 9px; margin-top: 2px; }
.crop { color: rgba(64,255,94,0.75); font-size: 10px; margin-top: 8px; }
.sqbtn { border-radius: 0; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.16); color: #7dff9e; font-size: 13px; padding: 8px 0; text-align: center; margin-top: 8px; }
.sqbtn-main { background-color: rgba(125,255,158,0.22); }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
