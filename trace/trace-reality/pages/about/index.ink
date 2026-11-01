<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';

export default {
  data: { evt: 'EVT: ready', ver: 'v1.0.0' },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  onKeyDown(event) { var k = event.key || event.code; if (k === 'Backspace' || k === 'Enter') this.backTap(); },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'Backspace') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">现实合影 · 说明</text>
    <text class="para">原理：眼镜是透视显示，你看到的世界和屏幕画是叠在一起的。手机 App 的截图会把当时的眼镜画面与现实景象合成一张照片——本台就是为这一瞬间画画的：先把气泡、名牌、横幅摆好，对准真人，进纯净页截图。</text>
    <text class="para">边界（如实说）：一、本台自己不拍照、也不合成，合成是系统截图做的；如果你的截图设置只截屏幕不带现实，出来的就是黑底叠加图。二、平台没有人脸识别，对位全靠你转头把准星对准头顶。三、纯净页倒数结束才算一次展示，本台不知道你有没有真的按下截图，结果去手机相册验。</text>
    <text class="para">操作：上下选、Enter / 点头确认、双击返回。选词页按「说一句」可以现说台词，存进我的句子，下次直接点用。</text>
    <view class="acts">
      <button class="act" bindtap="backTap">BACK</button>
    </view>
    <text class="foot">{{evt}} · {{ver}} · 现实合影</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.para { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 16px; margin-top: 6px; }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 7px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 10px; padding: 5px 10px; font-size: 12px; text-align: center; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
