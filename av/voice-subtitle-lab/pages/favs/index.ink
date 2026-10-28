<script def>{"title":"Voice Subtitle Lab - Favs"}</script>

<script setup>
import wx from 'wx';

// AV06 favs: winning combos persist in 'av06_favs' across sessions.
// A favourite is script index + voice + rate + pitch (+ format/sampleRate).

const KEY = 'av06_favs';

export default {
  data: { status: '收藏：胜出组合跨会话留用，Enter 入藏待入藏组合', rows: [], pendingText: '待入藏：无（先在 A/B 页定胜出）', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._sel = 0; this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._show();
  },
  onShow() { this._show(); },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) { const p = (typeof v === 'string') ? JSON.parse(v) : v; return Array.isArray(p) ? p : []; } } catch (e) {} return []; },
  _save(v) { try { wx.setStorageSync(KEY, v); } catch (e) {} },
  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },

  _label(f, i) {
    const c = (f && f.combo) ? f.combo : f;
    return '脚本#' + (c.scriptIdx != null ? c.scriptIdx : '?') + ' · ' + (c.voice || '?') + ' · rate ' + (c.rate != null ? c.rate : '?') + ' · pitch ' + (c.pitch != null ? c.pitch : '?');
  },
  _show() {
    const favs = this._load();
    const self = this;
    const rows = favs.map(function (f, i) { return { label: (i === self._sel ? '▶ ' : '· ') + self._label(f, i), idx: i }; });
    if (!rows.length) rows.push({ label: '暂无收藏 — 定胜出后按 Enter 入藏' });
    const w = this._loadTmp('av06_winner_tmp');
    this.setData({
      rows: rows,
      pendingText: w ? ('待入藏：' + this._label(w, 0) + ' — 按 Enter 入藏') : '待入藏：无（先在 A/B 页定胜出）',
      status: '收藏共 ' + favs.length + ' 条（av06_favs 跨会话）'
    });
  },

  addTap() {
    const w = this._loadTmp('av06_winner_tmp');
    if (!w || !w.combo) { this.setData({ status: '没有待入藏组合 — 先在 A/B 页定胜出', evt: 'EVT: add blocked' }); return; }
    const favs = this._load();
    const c = w.combo;
    favs.push({ scriptIdx: c.scriptIdx, voice: c.voice, rate: c.rate, pitch: c.pitch, format: c.format, sampleRate: c.sampleRate, combo: c });
    this._save(favs);
    try { wx.removeStorageSync('av06_winner_tmp'); } catch (e) {}
    this.setData({ evt: 'EVT: favourite saved', status: '已入藏 — 共 ' + favs.length + ' 条' });
    this._speak('已收藏');
    this._show();
  },
  delTap() {
    const favs = this._load();
    if (!favs.length || this._sel >= favs.length) return;
    favs.splice(this._sel, 1);
    if (this._sel >= favs.length) this._sel = Math.max(0, favs.length - 1);
    this._save(favs);
    this.setData({ evt: 'EVT: favourite deleted' });
    this._show();
  },
  rowTap(e) {
    const i = (e && e.currentTarget && e.currentTarget.dataset) ? Number(e.currentTarget.dataset.idx) : -1;
    const favs = this._load();
    if (isNaN(i)) return;
    if (i < 0 || i >= favs.length) return;
    this._sel = i; this._show();
  },
  clearTap() { this._save([]); this._sel = 0; this.setData({ evt: 'EVT: favs cleared' }); this._show(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.addTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    const favs = this._load();
    if (key === 'Enter') {  this.addTap(); return; }
    if (key === 'ArrowDown') {  if (favs.length) this._sel = (this._sel + 1) % favs.length; this._show(); return; }
    if (key === 'ArrowUp') {  if (favs.length) this._sel = (this._sel + favs.length - 1) % favs.length; this._show(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">收藏 · 胜出组合</text></view>
    <text class="status">{{status}}</text>
    <text class="line bright">{{pendingText}}</text>
    <view class="stagelist">
      <view ink:for="{{rows}}" class="favrow" data-idx="{{item.idx}}" bindtap="rowTap"><text class="favtext">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{steady}}</text>
    <view class="btnrow">
      <button class="stagebtn" bindtap="addTap">入藏</button>
      <button class="stagebtn" bindtap="delTap">删选中</button>
      <button class="stagebtn" bindtap="clearTap">清空</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { background-color: #000000; color: #40ff5e; border: 1px solid #40ff5e; border-radius: 10px; font-size: 10px; padding: 3px 8px; margin-right: 10px; }
.ttl { color: #7dff9e; font-size: 17px; font-weight: bold; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 5px; }
.bright { color: #7dff9e; }
.dim { color: rgba(64,255,94,0.7); }
.stagelist { margin-top: 6px; border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 6px 8px; height: 150px; overflow: hidden; }
.favrow { border-bottom: 1px solid rgba(64,255,94,0.35); padding: 3px 2px; }
.favtext { color: #7dff9e; font-size: 11px; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.stagebtn { flex: 1; margin-right: 6px; background-color: #000000; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); border-radius: 10px; font-size: 11px; padding: 5px 0; text-align: center; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
