<script def>{"title":"Voice Subtitle Lab"}</script>

<script setup>
import wx from 'wx';

// AV06 voice-subtitle-lab - index: script library (B6 entry).
// 8 built-in broadcast scripts; host SpeechRecognition dictation can append
// one spoken script (final transcript is appended and announced; a mishear
// is corrected by dictating again or by picking a built-in script instead).
const SCRIPTS = [
  { title: '开店迎客', text: '欢迎光临，本店今日九点开门，新鲜面包已经出炉。' },
  { title: '取餐提醒', text: '您的餐已备好，请到取餐口凭号码牌领取。' },
  { title: '关门提示', text: '本店今晚十点打烊，请您提前安排购物时间。' },
  { title: '活动播报', text: '周末活动开始了，满一百减二十，欢迎到服务台咨询。' },
  { title: '寻物启事', text: '有顾客遗落一把蓝色雨伞，请到前台认领。' },
  { title: '天气提醒', text: '今天下午有阵雨，出门请记得带伞，注意路面湿滑。' },
  { title: '会议开始', text: '会议马上开始，请大家把手机调到静音，谢谢配合。' },
  { title: '生日祝福', text: '祝你生日快乐，愿新的一岁平安健康，天天开心。' }
];
const MENU_EXTRA = [{ label: '口述自加一条（语音听写）', url: '__listen' }];

export default {
  data: { status: '脚本库：上下选稿，Enter 选稿去合成；末行可口述自加', rows: [], heardText: '听写：—', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._sel = 0; this._steady = false; this._scripts = SCRIPTS.slice(); this._rec = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },

  _allRows() {
    const list = this._scripts.map(function (s) { return { label: s.title + ' — ' + s.text }; });
    MENU_EXTRA.forEach(function (m) { list.push({ label: m.label }); });
    return list;
  },
  _recompute() {
    const self = this;
    const rows = this._allRows().map(function (r, i) { return { label: (i === self._sel ? '▶ ' : '· ') + r.label, idx: i }; });
    this.setData({ rows: rows, status: '脚本库共 ' + this._scripts.length + ' 条（内置 8 条起）· 当前第 ' + (this._sel + 1) + ' 行' });
  },

  _listen() {
    try {
      const Ctor = (typeof SpeechRecognition !== 'undefined') ? SpeechRecognition : ((typeof webkitSpeechRecognition !== 'undefined') ? webkitSpeechRecognition : null);
      if (!Ctor) { this.setData({ heardText: '听写：宿主无 SpeechRecognition — 如实显示，无法口述', evt: 'EVT: no asr host' }); return; }
      const r = new Ctor();
      this._rec = r;
      r.interimResults = true;
      const self = this;
      r.onresult = function (e) {
        try {
          const res = e.results[e.resultIndex];
          const t = (res && res[0]) ? (res[0].transcript || '') : '';
          if (!t) return;
          self.setData({ heardText: '听写：' + t });
          if (res.isFinal) {
            self._scripts.push({ title: '口述稿' + self._scripts.length, text: t });
            self._sel = self._scripts.length - 1;
            self.setData({ evt: 'EVT: dictated script appended' });
            self._speak('已加入脚本库');
            self._recompute();
          }
        } catch (err) {}
      };
      r.onerror = function (e) { self.setData({ heardText: '听写失败：' + String((e && (e.error || e.message)) || 'unknown').slice(0, 40) + ' — 可重说', evt: 'EVT: asr error' }); };
      r.start();
      this.setData({ heardText: '听写：聆听中…请口述一条播报稿', evt: 'EVT: listening' });
    } catch (e) {
      this.setData({ heardText: '听写启动失败：' + String((e && e.message) || e).slice(0, 40), evt: 'EVT: asr start failed' });
    }
  },

  goTap() {
    if (this._sel >= this._scripts.length) { this._listen(); return; }
    const s = this._scripts[this._sel];
    this._saveTmp('av06_script_tmp', { idx: this._sel, title: s.title, text: s.text });
    this.setData({ evt: 'EVT: script picked - ' + s.title });
    this._speak('已选' + s.title);
    try { wx.navigateTo({ url: '/pages/synth/index' }); } catch (e) {}
  },
  rowTap(e) {
    const i = (e && e.currentTarget && e.currentTarget.dataset) ? Number(e.currentTarget.dataset.idx) : -1;
    const total = this._scripts.length + MENU_EXTRA.length;
    if (isNaN(i)) return;
    if (i < 0 || i >= total) return;
    this._sel = i; this._recompute(); this.goTap();
  },
  synthTap() { try { wx.navigateTo({ url: '/pages/synth/index' }); } catch (e) {} },
  abTap() { try { wx.navigateTo({ url: '/pages/ab/index' }); } catch (e) {} },
  favsTap() { try { wx.navigateTo({ url: '/pages/favs/index' }); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.goTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    const total = this._scripts.length + MENU_EXTRA.length;
    if (key === 'Enter') {  this.goTap(); return; }
    if (key === 'ArrowDown') {  this._sel = (this._sel + 1) % total; this._recompute(); return; }
    if (key === 'ArrowUp') {  this._sel = (this._sel + total - 1) % total; this._recompute(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="ttl">Voice Subtitle Lab · 脚本库</text>
    <text class="status">{{status}}</text>
    <view class="stagelist">
      <view ink:for="{{rows}}" class="scriptrow" data-idx="{{item.idx}}" bindtap="rowTap"><text class="scripttext">{{item.label}}</text></view>
    </view>
    <text class="line">{{heardText}}</text>
    <text class="line dim">{{steady}} · 听错可重说：再选末行口述一次</text>
    <view class="btnrow">
      <button class="stagebtn" bindtap="goTap">选稿 / 口述</button>
      <button class="stagebtn" bindtap="synthTap">合成</button>
      <button class="stagebtn" bindtap="abTap">A/B</button>
      <button class="stagebtn" bindtap="favsTap">收藏</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.ttl { color: #7dff9e; font-size: 17px; font-weight: bold; letter-spacing: 1px; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.stagelist { margin-top: 7px; border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 6px 8px; height: 168px; overflow: hidden; }
.scriptrow { border-bottom: 1px solid rgba(64,255,94,0.35); padding: 2px 2px; }
.scripttext { color: #7dff9e; font-size: 11px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 4px; }
.dim { color: rgba(64,255,94,0.7); }
.btnrow { display: flex; flex-direction: row; margin-top: 7px; }
.stagebtn { flex: 1; margin-right: 6px; background-color: #000000; color: #40ff5e; border: 1px solid #40ff5e; font-size: 11px; padding: 5px 0; text-align: center; border-radius: 10px; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
