<script def>
{"title": "Trace Reality"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak } from '../../store.js';
import { SCENES } from '../../scenes.js';

// 现实合影首页：六种预置场景 + 我的句子 + 说明。
// 玩法：选景 → 选台词（或现说一句）→ 对准真人 → 纯净页里用
// 手机 App 截图，系统把眼镜画面与现实合成一张照片。
const STORE = 'trace.trace-reality.v1';
const SESS = 'trace.reality.session';
const MENU = SCENES.map(function (s) { return s.name; }).concat(['我的句子', '说明']);

export default {
  data: {
    status: '现实合影：给真人配一句台词，截图合成',
    statLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _store() { return loadKey(STORE, { custom: [], shots: 0, size: 1, uses: {} }); },
  _render() {
    const st = this._store();
    this.setData({
      statLine: '已合成展示 ' + (st.shots || 0) + ' 次 · 我的句子 ' + (st.custom || []).length + ' 条',
      focusLine: '焦点：' + MENU[this._focus] + '（上下切换，Enter 执行，点头=执行）'
    });
  },
  _go(url) { try { wx.navigateTo({ url: url }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  doAct() {
    if (this._focus < SCENES.length) {
      const sc = SCENES[this._focus];
      const st = this._store();
      const sess = { sceneId: sc.id, size: (typeof st.size === 'number' ? st.size : 1), textA: '', textB: '' };
      if (sc.pairs) { sess.textA = sc.pairs[0][0]; sess.textB = sc.pairs[0][1]; }
      else sess.textA = sc.lines[0];
      saveKey(SESS, sess);
      this._go('/pages/edit/index');
    } else if (this._focus === SCENES.length) this._go('/pages/lines/index');
    else this._go('/pages/about/index');
  },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  moveTap(d) { this._focus = (this._focus + d + MENU.length) % MENU.length; this.setData({ evt: 'EVT: focus ' + MENU[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">现实合影 · 选景</text>
    <text class="status">{{status}}</text>
    <view class="hero">
      <text class="line">把气泡 / 名牌 / 横幅叠在真人头上，进纯净页后用手机 App 截图——截图会把眼镜画面和现实合成一张照片。</text>
      <text class="line dim">{{statLine}}</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">对话气泡</button>
      <button class="act" bindtap="actTap" data-idx="1">双人对话</button>
      <button class="act" bindtap="actTap" data-idx="2">心声吐槽</button>
      <button class="act" bindtap="actTap" data-idx="3">头衔名牌</button>
      <button class="act" bindtap="actTap" data-idx="4">庆祝横幅</button>
      <button class="act" bindtap="actTap" data-idx="5">纪念相框</button>
      <button class="act" bindtap="actTap" data-idx="6">我的句子</button>
      <button class="act" bindtap="actTap" data-idx="7">说明</button>
    </view>
    <text class="note">对位靠你的头：气泡尾巴对准头顶，没有人脸识别（平台无此 API），框住谁全靠你站位和转头。</text>
    <text class="line dim">{{focusLine}}</text>
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
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 6px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
