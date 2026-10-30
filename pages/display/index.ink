<script def>
{
  "title": "Probe Display"
}
</script>

<script setup>
import wx from 'wx';
import { VER, EC_LEVELS, payloadFor, encodeQR, fitScale, drawQR, readState } from '../../qrprobe.js';

export default {
  data: {
    evt: 'EVT: display',
    ver: 'v' + VER,
    capLine: '展示页 · 读取记录中…',
    hintLine: '滑动切换纠错档 · 展示该档最大可读回的码，供手机外部扫码核对'
  },
  onLoad() {
    this._lastAct = 0;
    this._ctx = null;
    try { if (wx.createCanvasContext) this._ctx = wx.createCanvasContext('dispCanvas'); } catch (e) { this._ctx = null; }
    // Start from the strongest evidence: an EC level with a file
    // roundtrip ceiling, else any encode ceiling, else M.
    var st = readState();
    this._ec = 1;
    var order = [1, 0, 2, 3];
    var picked = false;
    for (var i = 0; i < order.length && !picked; i++) {
      var f = st.file[EC_LEVELS[order[i]]];
      if (f && f.ceiling) { this._ec = order[i]; picked = true; }
    }
    if (!picked) {
      for (var j = 0; j < order.length && !picked; j++) {
        var e2 = st.encode[EC_LEVELS[order[j]]];
        if (e2 && e2.ceiling) { this._ec = order[j]; picked = true; }
      }
    }
    this._draw();
  },
  onShow() { this._draw(); },
  _set(obj) { try { this.setData(obj); } catch (e) {} },
  _cycle(d) {
    this._ec = (this._ec + d + EC_LEVELS.length) % EC_LEVELS.length;
    this._draw();
  },
  capTap() { this._cycle(1); },
  _draw() {
    if (!this._ctx) {
      try { if (wx.createCanvasContext) this._ctx = wx.createCanvasContext('dispCanvas'); } catch (e) { this._ctx = null; }
    }
    var st = readState();
    var ec = EC_LEVELS[this._ec];
    var f = st.file[ec];
    var e = st.encode[ec];
    var bytes = 0, src = '';
    if (f && f.ceiling) { bytes = f.ceiling; src = '文件读回上限'; }
    else if (e && e.ceiling) { bytes = e.ceiling.bytes; src = '编码上限 · 未过文件读回'; }
    if (this._ctx) {
      try {
        this._ctx.fillStyle = '#000000';
        this._ctx.fillRect(0, 0, 480, 312);
        if (this._ctx.flush) this._ctx.flush();
      } catch (err) {}
    }
    if (!bytes) {
      this._set({ capLine: ec + ' 档暂无上限记录 · 先跑编码站' });
      return;
    }
    var enc = null;
    try { enc = encodeQR(payloadFor(bytes), ec); } catch (err) {}
    if (!enc) {
      this._set({ capLine: ec + ' 档 ' + bytes + ' B 重新编码失败（记录与编码器不一致）' });
      return;
    }
    var scale = fitScale(enc.modules, 480, 312);
    var size = (enc.modules + 8) * scale;
    if (this._ctx) {
      try {
        drawQR(this._ctx, enc.qr, scale, Math.floor((480 - size) / 2), Math.floor((312 - size) / 2));
      } catch (err) {}
    }
    this._set({
      capLine: bytes + ' B · 纠错 ' + ec + ' · v' + enc.version + ' · ' + scale + ' px/模 · ' + src,
      evt: 'EVT: display ' + ec + ' ' + bytes
    });
  },
  onKeyDown(event) {
    var k = event && (event.code || event.key);
    if (k === 'ArrowUp') this._cycle(-1);
    else if (k === 'ArrowDown') this._cycle(1);
    else if (k === 'Enter' || k === 'GlobalHook') this._draw();
  },
  onKeyUp(event) {
    var k = event && (event.code || event.key);
    if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <canvas id="dispCanvas" width="480" height="312" class="cv"></canvas>
    <view class="capbar" bindtap="capTap"><text class="captxt">{{capLine}}</text></view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 0; background-color: #000000; }
.cv { background-color: #000000; width: 480px; height: 312px; }
.capbar { margin-top: 2px; padding: 2px 14px; }
.captxt { color: #7dff9e; font-size: 14px; font-weight: 500; }
.footrow { display: flex; flex-direction: row; margin-top: 2px; padding: 0 14px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
