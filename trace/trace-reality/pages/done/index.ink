<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, speak } from '../../store.js';
import { sceneById } from '../../scenes.js';

// 完成页：如实说明——本台不知道你有没有真的按下截图，
// 它只知道纯净画面展示过几次。合成图在手机相册里看。
const STORE = 'trace.trace-reality.v1';
const SESS = 'trace.reality.session';

export default {
  data: {
    status: '纯净画面展示完成',
    sumLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._render(); speak('拍好了，去手机相册看合成图'); },
  onShow() { this._render(); },
  _render() {
    const st = loadKey(STORE, { custom: [], shots: 0, size: 1, uses: {} });
    const sess = loadKey(SESS, { sceneId: 'bubble' });
    const sc = sceneById(sess.sceneId);
    this.setData({
      sumLine: '本次场景：' + sc.name + ' · 累计纯净展示 ' + (st.shots || 0) + ' 次'
    });
  },
  againTap() { try { wx.navigateTo({ url: '/pages/frame/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  homeTap() { try { wx.navigateBack({ delta: 3 }); } catch (e) { try { wx.navigateBack({}); } catch (e2) {} } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.againTap();
    else if (k === 'Backspace') this.backTap();
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">现实合影 · 完成</text>
    <text class="status">{{status}}</text>
    <view class="hero">
      <text class="line">合成图不在眼镜里——去手机相册 / Hi Rokid App 的截图里看：眼镜画面应该已经和当时的现实合成在同一张图上。</text>
      <text class="line dim">{{sumLine}}</text>
      <text class="line dim">说明：本台数的是「纯净画面展示次数」；你有没有在那几秒里按下截图，只有相册知道。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="againTap">再拍一张</button>
      <button class="act" bindtap="homeTap">回首页</button>
      <button class="act" bindtap="backTap">BACK</button>
    </view>
    <text class="foot">{{evt}} · {{ver}} · 现实合影</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.hero { border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 6px 8px; margin-top: 5px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
