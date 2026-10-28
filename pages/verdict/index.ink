<script def>
{
  "title": "Tri Shot Verdict"
}
</script>

<script setup>
import wx from 'wx';

var CKEY = 'av01_current';
var HKEY = 'av01_history';
var SYS = 'You read one cropped photo from smart glasses. Reply with exactly two lines: READ: <the text you can actually read, or NONE> and LEGIBLE: YES or NO. Never guess text you cannot see.';

export default {
  data: {
    evt: 'EVT: verdict ready',
    ver: 'v1.0.0',
    status: '单击逐张判读（三张串行，同一 session 一次只发一个请求）',
    targetName: '-',
    busy: false,
    saved: false,
    conclusion: '结论：待判读',
    rows: []
  },
  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) {}
    this._cur = null;
    try {
      var v = wx.getStorageSync(CKEY);
      this._cur = (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    if (this._cur && this._cur.shots) {
      this.setData({ targetName: this._cur.target || '-' });
      this._syncRows(null);
    } else {
      this.setData({ status: '尚无连拍结果：先回连拍页拍一组（不编造结论）' });
    }
  },
  _load() {
    try {
      var v = wx.getStorageSync(HKEY);
      if (v) return (typeof v === 'string') ? JSON.parse(v) : v;
    } catch (e) {}
    return [];
  },
  _save(list) { try { wx.setStorageSync(HKEY, list); } catch (e) {} },
  _syncRows(judged) {
    var shots = (this._cur && this._cur.shots) || [];
    var rows = shots.map(function (s, i) {
      var j = judged && judged[i];
      return {
        label: s.mode,
        pix: s.pix + ' · ' + s.bytes + 'B',
        line: j ? ('READ: ' + j.read + ' · LEGIBLE: ' + j.legible) : '待判读',
        cls: j ? 'vrow vrow-done' : 'vrow'
      };
    });
    this.setData({ rows: rows });
  },
  onBackTap() { try { wx.navigateBack({}); } catch (e) {} },
  onJudgeTap() { this._judge(); },
  onSpeakTap() { this._speak(this.data.conclusion); },
  // Fallback strategy (by design): sending all three images in one prompt
  // is NOT assumed to work on the host LLM, so each crop is judged in its
  // own serial session.prompt call, awaited one at a time. If the LLM is
  // unavailable the verdict degrades to a pixel/byte comparison only and
  // says so - no read result is ever invented.
  async _judge() {
    if (this.data.busy) return;
    var cur = this._cur;
    if (!cur || !cur.shots || !cur.shots.length) { this.setData({ evt: 'EVT: no shots' }); return; }
    this.setData({ busy: true, status: '判读中（逐张串行）…', evt: 'EVT: judge start' });
    var judged = [];
    var llmOk = false;
    var session = null;
    try {
      if (typeof LanguageModel !== 'undefined') {
        var avail = await LanguageModel.availability();
        if (avail === 'available') {
          session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: SYS }] });
          llmOk = true;
        }
      }
      for (var i = 0; i < cur.shots.length; i++) {
        var s = cur.shots[i];
        var one = { read: 'NONE', legible: 'NO' };
        if (llmOk && session) {
          var ans = await session.prompt([{ role: 'user', content: [
            { type: 'text', text: 'Read this ' + s.mode + ' centre crop. Target type: ' + (cur.target || '') },
            { type: 'image_url', image_url: { url: s.dataUrl } }
          ] }]);
          var txt = String(ans || '');
          var rm = txt.match(/READ:\s*(.+)/);
          var lm = txt.match(/LEGIBLE:\s*(YES|NO)/i);
          if (rm) one.read = rm[1].trim().slice(0, 40);
          if (lm) one.legible = lm[1].toUpperCase();
        }
        judged.push(one);
        this._syncRows(judged);
      }
    } catch (e) {
      llmOk = false;
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
    var best = null;
    for (var j = 0; j < cur.shots.length; j++) {
      if (judged[j] && judged[j].legible === 'YES') {
        var px = parseInt(String(cur.shots[j].pix).split('x')[0], 10) || 0;
        if (!best || px > best.px) best = { mode: cur.shots[j].mode, px: px };
      }
    }
    var concl = '';
    if (!llmOk) {
      concl = '判读未完成（LLM 不可用），仅像素对照：' + cur.shots.map(function (s) { return s.mode + ' ' + s.pix; }).join(' / ');
    } else if (best) {
      concl = '结论：' + (cur.target || '该对象') + ' 用 ' + best.mode + ' 镜可读';
    } else {
      concl = '结论：三镜均未读清（LEGIBLE 全 NO），请靠近或换光线重拍';
    }
    this.setData({ conclusion: concl, busy: false, status: llmOk ? '判读完成' : 'LLM 不可用，已降级为像素对照', evt: 'EVT: judge done llm=' + llmOk });
    this._speak(concl);
    if (!this.data.saved) {
      var list = this._load();
      list.unshift({ at: new Date().toISOString().slice(0, 16).replace('T', ' '), target: cur.target || '-', conclusion: concl, llm: llmOk });
      this._save(list.slice(0, 20));
      this.setData({ saved: true });
    }
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
    if (k === 'Enter' || k === 'GlobalHook') this._judge();
    else if (k === 'ArrowDown' || k === 'ArrowUp') this._speak(this.data.conclusion);
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key || event.code) >= 0) event.preventDefault(); },
  onHeadGesture(event) { if (event && event.gesture === 'nod') this._speak(this.data.conclusion); },
  onOrientationStabilityChange(event) {
    var s = !!(event && event.detail && event.detail.isStable);
    this.setData({ evt: 'EVT: steady=' + s });
  }
};
</script>

<page>
  <view class="page">
    <view class="topbar">
      <button class="backbtn" bindtap="onBackTap">BACK</button>
      <text class="ttl">VERDICT · 对照结论</text>
      <text class="tgt">{{targetName}}</text>
    </view>
    <text class="status">{{status}}</text>
    <view class="vlist">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="vlabel">{{item.label}}</text>
        <text class="vpix">{{item.pix}}</text>
        <text class="vline">{{item.line}}</text>
      </view>
    </view>
    <text class="concl">{{conclusion}}</text>
    <view class="btnrow">
      <button class="sqbtn" bindtap="onJudgeTap">JUDGE 判读</button>
      <button class="sqbtn" bindtap="onSpeakTap">SPEAK 播报</button>
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
.backbtn { border-radius: 0; border: 1px solid rgba(64,255,94,0.8); background-color: #04140a; color: rgba(125,255,158,0.9); font-size: 10px; padding: 3px 8px; }
.ttl { flex-grow: 1; color: #7dff9e; font-size: 15px; font-weight: 500; text-align: center; }
.tgt { color: #40ff5e; font-size: 12px; }
.status { color: rgba(125,255,158,0.9); font-size: 11px; margin-top: 6px; }
.vlist { display: flex; flex-direction: column; margin-top: 6px; }
.vrow { border: 1px solid rgba(64,255,94,0.5); background-color: #04140a; padding: 5px 10px; margin-bottom: 5px; border-radius: 0; }
.vrow-done { border: 2px solid #40ff5e; background-color: #0a1f0e; }
.vlabel { color: #40ff5e; font-size: 12px; font-weight: 500; }
.vpix { color: rgba(64,255,94,0.65); font-family: monospace; font-size: 10px; margin-left: 8px; }
.vline { color: #7dff9e; font-size: 11px; margin-left: 8px; }
.concl { color: #7dff9e; font-size: 13px; font-weight: 500; margin-top: 4px; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.sqbtn { flex-grow: 1; border-radius: 0; border: 2px solid #40ff5e; background-color: rgba(64,255,94,0.16); color: #7dff9e; font-size: 12px; padding: 7px 0; text-align: center; margin-right: 8px; }
.footrow { display: flex; flex-direction: row; margin-top: 8px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
