<script def>
{
  "title": "Mic Mode Arena"
}
</script>

<script setup>
import wx from 'wx';

var EKEY = 'av04_env';
var ENVS = [
  { name: '街头', hint: '户外噪声 · far-field 候选' },
  { name: '会议室', hint: '多人发言 · omnidirectional 候选' },
  { name: '近耳语', hint: '贴近小声 · near-field 候选' }
];
var MENU = [
  { name: '切换环境', hint: '在 街头/会议室/近耳语 间切换', act: 'env' },
  { name: '开始四轮', hint: '用选中环境跑四模式', act: 'rounds' },
  { name: '评分榜', hint: '看本环境四轮排序', act: 'board' },
  { name: '环境记忆', hint: '三环境各自最佳模式', act: 'memory' }
];

export default {
  data: {
    evt: 'EVT: ready · 滑动选环境/菜单',
    ver: 'v1.0.0',
    status: '先选环境，再跑四轮同句实测',
    note: '说明：麦克风模式只对 getUserMedia 生效；宿主 ASR 不吃模式，转写字数仅作参考分，不参与模式排名。',
    envIdx: 0,
    envRows: [],
    selIdx: 0,
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._syncAll();
  },
  onShow() { this._syncAll(); },
  _syncAll() {
    var ei = this.data.envIdx;
    var envRows = ENVS.map(function (e, i) {
      return { name: e.name, hint: e.hint, cls: i === ei ? 'lane lane-sel' : 'lane', mark: i === ei ? '▸' : '·' };
    });
    var sel = this.data.selIdx;
    var rows = MENU.map(function (m, i) {
      return { name: m.name, hint: m.hint, cls: i === sel ? 'mrow mrow-sel' : 'mrow', mark: i === sel ? '▸' : '·' };
    });
    this.setData({ envRows: envRows, rows: rows });
    try { wx.setStorageSync(EKEY, { env: ENVS[ei].name }); } catch (e) {}
  },
  _moveEnv(dir) {
    var n = (this.data.envIdx + dir + ENVS.length) % ENVS.length;
    this.setData({ envIdx: n, evt: 'EVT: env ' + ENVS[n].name });
    this._syncAll();
    this._speak('环境' + ENVS[n].name);
  },
  _move(dir) {
    var n = (this.data.selIdx + dir + MENU.length) % MENU.length;
    this.setData({ selIdx: n, evt: 'EVT: menu ' + MENU[n].name });
    this._syncAll();
  },
  onEnvTap(e) {
    var i = this.data.envIdx;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this.data.envIdx;
    this.setData({ envIdx: i });
    this._syncAll();
  },
  onRowTap(e) {
    var i = this.data.selIdx;
    try { i = Number(e.currentTarget.dataset.idx); } catch (err) {}
    if (isNaN(i)) i = this.data.selIdx;
    this.setData({ selIdx: i });
    this._activate(i);
  },
  _activate(i) {
    var act = MENU[i] && MENU[i].act;
    if (act === 'env') this._moveEnv(1);
    else if (act === 'rounds') { try { wx.navigateTo({ url: '/pages/rounds/index' }); } catch (e) {} }
    else if (act === 'board') { try { wx.navigateTo({ url: '/pages/board/index' }); } catch (e) {} }
    else if (act === 'memory') { try { wx.navigateTo({ url: '/pages/memory/index' }); } catch (e) {} }
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
    if (k === 'Enter' || k === 'GlobalHook') this._activate(this.data.selIdx);
    else if (k === 'ArrowDown') this._move(1);
    else if (k === 'ArrowUp') this._move(-1);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._activate(this.data.selIdx); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">MIC MODE ARENA · 四麦同台</text>
    <text class="status">{{status}}</text>
    <view class="lanes">
      <view ink:for="{{envRows}}" class="{{item.cls}}" bindtap="onEnvTap" data-idx="{{index}}">
        <text class="lname">{{item.mark}} {{item.name}}</text>
        <text class="lhint">{{item.hint}}</text>
      </view>
    </view>
    <text class="note">{{note}}</text>
    <view class="mlist">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="onRowTap" data-idx="{{index}}">
        <text class="mname">{{item.mark}} {{item.name}}</text>
        <text class="mhint">{{item.hint}}</text>
      </view>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 5px; }
.lanes { display: flex; flex-direction: column; margin-top: 7px; }
.lane { display: flex; flex-direction: row; align-items: center; border-left: 8px solid rgba(64,255,94,0.45); background-color: #04140a; padding: 6px 10px; margin-bottom: 5px; }
.lane-sel { border-left: 8px solid #7dff9e; background-color: #0a1f0e; }
.lname { color: #40ff5e; font-size: 14px; font-weight: 500; }
.lhint { color: rgba(64,255,94,0.62); font-size: 10px; margin-left: 8px; }
.note { color: rgba(64,255,94,0.7); font-size: 9px; margin-top: 4px; }
.mlist { display: flex; flex-direction: column; margin-top: 7px; }
.mrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 5px 10px; margin-bottom: 4px; }
.mrow-sel { border: 2px solid #7dff9e; background-color: #0a1f0e; }
.mname { color: #40ff5e; font-size: 13px; font-weight: 500; }
.mhint { color: rgba(64,255,94,0.62); font-size: 10px; margin-left: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
