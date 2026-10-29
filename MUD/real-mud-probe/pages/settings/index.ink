<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, RESULTS_KEY } from '../../judge.js';
import { selfCheck } from '../../err.js';
import { BASE_URL, CHANNEL_KEY } from '../../config.js';

// 设置 / 自检：显示 lastError（裸码 + slug + 版本 + 原文截断）、
// 日志回传配置状态（只报齐/不齐，永不显示钥匙本身）、运行时
// 自检（错误码形状、关键接口存在性），并提供清除结果。
// 清除只删探针结果与标记，不动 lastError（单独一项清）。
const ACTS = ['清除全部结果', '清除 lastError', 'BACK 返回'];

export default {
  data: {
    status: '设置 / 自检',
    errLine: 'lastError：无',
    cfgLine: '日志回传：未配置（静默）',
    chkLine: '自检：—',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._render(); },
  onShow() { this._render(); },
  _render() {
    const le = loadKey('lastError', null);
    const cfgOn = !!CHANNEL_KEY && CHANNEL_KEY !== 'PASTE_CHANNEL_KEY_HERE' && !!BASE_URL;
    const checks = [];
    checks.push('错误码形状 ' + (selfCheck() ? '✓' : '✗'));
    checks.push('相机接口 ' + ((typeof ImageCapture !== 'undefined') ? '有' : '无'));
    checks.push('LLM ' + ((typeof LanguageModel !== 'undefined') ? '有' : '无'));
    checks.push('朝向传感器 ' + ((typeof AbsoluteOrientationSensor !== 'undefined') ? '有' : '无'));
    checks.push('定位 ' + ((typeof navigator !== 'undefined' && navigator.geolocation) ? '有' : '无'));
    this.setData({
      errLine: le ? ('lastError：' + le.code + ' · ' + le.slug + ' v' + le.version + ' · ' + String(le.at || '').slice(0, 16) + '\n原文：' + String(le.raw || '').slice(0, 80)) : 'lastError：无（还没出过错）',
      cfgLine: '日志回传：' + (cfgOn ? ('已启用 → ' + BASE_URL + '/log（钥匙不显示）') : '未配置两件齐（config.js 的 BASE_URL / CHANNEL_KEY）→ 完全静默，不影响探针'),
      chkLine: '自检：' + checks.join(' · ') + '（「无」在 Web 预览里常见，真机为准）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击或点头执行）'
    });
  },
  clearResultsTap() {
    try { wx.removeStorageSync(RESULTS_KEY); } catch (e) {}
    try { wx.removeStorageSync('mud.probe.marker'); } catch (e) {}
    try { if (typeof localStorage !== 'undefined') localStorage.removeItem('mud.probe.marker'); } catch (e) {}
    this.setData({ status: '全部结果已清除，四站可重测', evt: 'EVT: results cleared' });
    this._render();
  },
  clearErrTap() {
    try { wx.removeStorageSync('lastError'); } catch (e) {}
    this.setData({ status: 'lastError 已清除', evt: 'EVT: lastError cleared' });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.clearResultsTap(); else if (this._focus === 1) this.clearErrTap(); else this.backTap(); },
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
    <text class="title">设置 / 自检</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">{{errLine}}</text>
      <text class="line">{{cfgLine}}</text>
      <text class="line">{{chkLine}}</text>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">清除全部结果</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">清除 lastError</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">BACK 返回</button>
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
