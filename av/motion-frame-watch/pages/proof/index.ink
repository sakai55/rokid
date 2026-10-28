<script def>
{
  "title": "Motion Proof"
}
</script>

<script setup>
import wx from 'wx';

var AKEY = 'av02_alert';
var LKEY = 'av02_log';
var SYS = 'You look at one photo from smart glasses watching a fixed spot. In one short sentence, say what visibly changed or is present in the scene. If you cannot tell, say so plainly.';

export default {
  data: {
    evt: 'EVT: proof ready',
    ver: 'v1.0.1',
    status: '单击拍存证照并判读变化',
    diffText: '触发差值 -%',
    photoLine: '存证照：未拍（拍后只存内存，不落盘）',
    descLine: '变化描述：待判读',
    busy: false,
    logged: false
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._desc = '';
    var a = null;
    try {
      var v = wx.getStorageSync(AKEY);
      a = (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    if (a && a.diff !== undefined) this.setData({ diffText: '触发差值 ' + a.diff + '%（阈值 ' + (a.thr || 5) + '%）' });
    this._speak('点位有变化');
  },
  _load() {
    try {
      var v = wx.getStorageSync(LKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return [];
  },
  _save(list) { try { wx.setStorageSync(LKEY, list); } catch (e) {} },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onProofTap() { this._proof(); },
  onLogTap() { this._confirmLog(); },
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
  async _proof() {
    if (this.data.busy) return;
    this.setData({ busy: true, status: '存证中…', evt: 'EVT: proof start' });
    var stream = null;
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') {
        this.setData({ status: '宿主无相机，待真机存证（不生成假照片）', evt: 'EVT: camera n/a' });
        return;
      }
      stream = await navigator.mediaDevices.getUserMedia({ video: true });
      var track = stream.getVideoTracks()[0];
      var cap = new ImageCapture(track);
      var blob = await cap.takePhoto({ mode: 'default' });
      this.setData({ photoLine: '存证照：default · ' + blob.size + 'B · 仅内存持有，不落盘' });
      var desc = 'LLM 不可用，未判读（如实标注）';
      try {
        if (typeof LanguageModel !== 'undefined' && (await LanguageModel.availability()) === 'available') {
          var session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: SYS }] });
          try {
            var dataUrl = await this._blobToDataUrl(blob);
            var ans = await session.prompt([{ role: 'user', content: [
              { type: 'text', text: 'Describe in one sentence what is in this watched spot now.' },
              { type: 'image_url', image_url: { url: dataUrl } }
            ] }]);
            desc = String(ans || '').trim().slice(0, 80) || desc;
          } finally { try { session.destroy(); } catch (e) {} }
        }
      } catch (e) { desc = 'LLM 判读失败（如实标注）：' + String((e && e.message) || e).slice(0, 30); }
      this._desc = desc;
      this.setData({ descLine: '变化描述：' + desc, status: '存证完成 · 点头或单击确认入账', evt: 'EVT: proof done' });
      this._speak('存证完成');
    } catch (e) {
      this.setData({ status: '存证失败（如实记录）：' + String((e && e.message) || e).slice(0, 44), evt: 'EVT: proof fail' });
    } finally {
      if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {} }
      this.setData({ busy: false });
    }
  },
  _confirmLog() {
    if (this.data.logged) { try { wx.navigateTo({ url: '/pages/log/index' }); } catch (e) {} return; }
    var a = null;
    try {
      var v = wx.getStorageSync(AKEY);
      a = (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    var list = this._load();
    list.unshift({
      at: new Date().toISOString().slice(0, 16).replace('T', ' '),
      diff: a && a.diff !== undefined ? a.diff : 0,
      desc: this._desc || '未判读（手动入账）'
    });
    this._save(list.slice(0, 30));
    this.setData({ logged: true, status: '已入账，去日志结算', evt: 'EVT: logged' });
    this._speak('已记录');
    try { wx.navigateTo({ url: '/pages/log/index' }); } catch (e) {}
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
    if (k === 'Enter' || k === 'GlobalHook') { if (this._desc) this._confirmLog(); else this._proof(); }
    else if (k === 'ArrowDown' || k === 'ArrowUp') this._speak(this.data.descLine);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._confirmLog(); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="alertbtn alertbtn-back" bindtap="onBackTap">BACK</button>
      <text class="ttl">PROOF · 存证判定</text>
    </view>
    <text class="diff">{{diffText}}</text>
    <text class="pline">{{photoLine}}</text>
    <text class="dline">{{descLine}}</text>
    <text class="status">{{status}}</text>
    <view class="btnrow">
      <button class="alertbtn alertbtn-half" bindtap="onProofTap">PROOF 存证</button>
      <button class="alertbtn alertbtn-half" bindtap="onLogTap">LOG 确认入账</button>
    </view>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 10px 14px; background-color: #000000; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.alertbtn { border-top: 3px solid #40ff5e; border-bottom: 3px solid #40ff5e; border-left: 1px solid rgba(64,255,94,0.7); border-right: 1px solid rgba(64,255,94,0.7); background-color: #04140a; color: #7dff9e; text-align: center; }
.alertbtn-back { font-size: 10px; padding: 3px 8px; }
.alertbtn-half { flex-grow: 1; font-size: 12px; padding: 9px 0; margin-right: 8px; background-color: rgba(64,255,94,0.18); }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.diff { color: #7dff9e; font-size: 20px; font-weight: 500; margin-top: 12px; }
.pline { color: rgba(125,255,158,0.9); font-family: monospace; font-size: 11px; margin-top: 8px; }
.dline { color: #40ff5e; font-size: 12px; margin-top: 6px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.btnrow { display: flex; flex-direction: row; margin-top: 10px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
