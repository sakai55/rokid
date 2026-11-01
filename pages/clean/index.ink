<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../store.js';
import { sceneById } from '../../scenes.js';
import { drawOverlay } from '../../overlay.js';

// 纯净页：全屏只有叠加画，没有按钮、没有标记、没有引导字。
// 进页先倒数 3-2-1（给你扶正头部的时间），随后纯净展示——
// 这时按手机 App 的截图，眼镜画面与现实就合成一张照片。
// 任意按键 / 单击退出回取景页。
const STORE = 'trace.trace-reality.v1';
const SESS = 'trace.reality.session';
const CW = 480, CH = 352;

export default {
  data: { evt: 'EVT: clean', ver: 'v1.0.0' },
  onLoad() {
    this._count = 3;
    this._counted = false;
    this._draw();
    speak('保持不动');
    const self = this;
    this._timer = setInterval(function () {
      self._count--;
      if (self._count <= 0) {
        clearInterval(self._timer);
        self._timer = null;
        self._draw();
        self._markShown();
      } else self._draw();
    }, 900);
  },
  onUnload() { if (this._timer) { clearInterval(this._timer); this._timer = null; } },
  _dateStr() {
    const d = new Date();
    const p = function (n) { return (n < 10 ? '0' : '') + n; };
    return d.getFullYear() + '.' + p(d.getMonth() + 1) + '.' + p(d.getDate());
  },
  _draw() {
    try {
      const sess = loadKey(SESS, { sceneId: 'bubble', textA: '', textB: '', size: 1 });
      const ctx = wx.createCanvasContext('cleanCanvas');
      if (!ctx) return;
      drawOverlay(ctx, CW, CH, sceneById(sess.sceneId), sess, { guides: false, count: this._count > 0 ? this._count : 0, dateStr: this._dateStr() });
    } catch (e) { /* 纯净页不出错字：失败保持黑屏，下次进页重试 */ }
  },
  _markShown() {
    if (this._counted) return;
    this._counted = true;
    const sess = loadKey(SESS, { sceneId: 'bubble' });
    const st = loadKey(STORE, { custom: [], shots: 0, size: 1, uses: {} });
    st.shots = (st.shots || 0) + 1;
    st.uses = st.uses || {};
    st.uses[sess.sceneId] = (st.uses[sess.sceneId] || 0) + 1;
    saveKey(STORE, st);
  },
  exitTap() { try { wx.navigateBack({}); } catch (e) {} },
  onKeyDown(event) { this.exitTap(); },
  onKeyUp(event) { if (event && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page" bindtap="exitTap">
    <canvas id="cleanCanvas" width="480" height="352" class="clean-canvas"></canvas>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 0px; background-color: #000000; }
.clean-canvas { width: 480px; height: 352px; background-color: #000000; }
</style>
