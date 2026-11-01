<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../store.js';
import { sceneById } from '../../scenes.js';
import { drawOverlay } from '../../overlay.js';

// 取景页：叠加画 + 对位标记（准星对准头顶）。眼镜是透视显示，
// 画布黑底在真机上就是透明的——你看到的是真人 + 叠加。
// 对好位进纯净页，标记和按钮全部消失，再按 App 截图合成。
const SESS = 'trace.reality.session';
const CW = 480, CH = 296;

export default {
  data: {
    guideLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._draw(); const sc = sceneById(loadKey(SESS, { sceneId: 'bubble' }).sceneId); this.setData({ guideLine: sc.guide }); speak(sc.guide + '，对好后进纯净页截图'); },
  onShow() { this._draw(); },
  _dateStr() {
    const d = new Date();
    const p = function (n) { return (n < 10 ? '0' : '') + n; };
    return d.getFullYear() + '.' + p(d.getMonth() + 1) + '.' + p(d.getDate());
  },
  _draw() {
    try {
      const sess = loadKey(SESS, { sceneId: 'bubble', textA: '', textB: '', size: 1 });
      const ctx = wx.createCanvasContext('ovCanvas');
      if (!ctx) return;
      drawOverlay(ctx, CW, CH, sceneById(sess.sceneId), sess, { guides: true, count: 0, dateStr: this._dateStr() });
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E9001' }); }
  },
  cleanTap() { try { wx.navigateTo({ url: '/pages/clean/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doneTap() { try { wx.navigateTo({ url: '/pages/done/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.cleanTap(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.cleanTap();
    else if (k === 'ArrowDown') this.doneTap();
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <canvas id="ovCanvas" width="480" height="296" class="ov-canvas"></canvas>
    <text class="bar">{{guideLine}} · 准星对准头顶，点头或 Enter 进纯净页，下键去完成页</text>
    <view class="acts">
      <button class="act hot" bindtap="cleanTap">纯净截图</button>
      <button class="act" bindtap="doneTap">完成</button>
      <button class="act" bindtap="backTap">BACK</button>
    </view>
    <text class="foot">{{evt}} · {{ver}} · 现实合影 · 取景</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 0px; background-color: #000000; }
.ov-canvas { width: 480px; height: 296px; background-color: #000000; }
.bar { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; padding: 0px 10px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 4px; padding: 0px 10px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; padding: 0px 10px; }
</style>
