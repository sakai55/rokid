<script def>{"title":"Hotword Forge - Settle"}</script>

<script setup>
import wx from 'wx';

// AV05 settle: per-word hits from the last test, weak words (0 hits),
// config recap, and the cross-session cumulative board in 'av05_hits'.
const KEY = 'av05_hits';
const ALL = ['纸箱', '托盘', '货架', '叉车', '标签', '封口', '称重', '扫码枪', '周转箱', '防潮垫', '捆扎带', '出库单'];

export default {
  data: { status: '结算：本次命中入累计榜（av05_hits）', rows: [], weakText: '弱词：—', summaryText: '配置摘要：—', totalText: '累计：—', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._steady = false; this._saved = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._show(false);
  },
  onShow() { if (!this._saved) this._show(false); },

  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return {}; },
  _save(v) { try { wx.setStorageSync(KEY, v); } catch (e) {} },
  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },

  _show(saveNow) {
    const last = this._loadTmp('av05_last_tmp');
    const hits = (last && last.hits) || {};
    const cfg = (last && last.cfg) || this._loadTmp('av05_cfg_tmp') || {};
    const picked = (cfg.picked && cfg.picked.length) ? cfg.picked : Object.keys(hits);
    let board = this._load();
    if (saveNow && !this._saved && last) {
      picked.forEach(function (w) { board[w] = (board[w] || 0) + (hits[w] || 0); });
      this._save(board); this._saved = true;
    }
    const rows = picked.map(function (w) { return { label: w + ' · 本次 ' + (hits[w] || 0) + ' · 累计 ' + (board[w] || 0) }; });
    if (!rows.length) rows.push({ label: '暂无实测数据 — 先在实测页完成一次识别' });
    const weak = picked.filter(function (w) { return !(hits[w] > 0); });
    this.setData({
      rows: rows,
      weakText: '弱词（本次命中 0）：' + (weak.length ? weak.join('、') : '无 — 全部命中'),
      summaryText: '配置摘要：热词 ' + picked.length + ' 个 · VAD ' + (cfg.vadMs != null ? cfg.vadMs + 'ms' : '关') + ' · 分段 ' + (cfg.segMode || 'auto') + ' · 上下文 ' + (cfg.useCtx ? '开' : '关'),
      totalText: '累计榜覆盖 ' + ALL.filter(function (w) { return board[w] != null; }).length + '/12 词 · 状态：' + (this._saved ? '本次已入账' : '未入账（按 Enter 入账）'),
      status: last ? '结算：本次命中如下，Enter 入累计榜' : '结算：暂无本次实测 — 先去实测页'
    });
  },

  saveTap() { this._show(true); this.setData({ evt: 'EVT: hits merged into av05_hits' }); this._speak('命中已入累计榜'); },
  clearTap() {
    try { wx.removeStorageSync(KEY); } catch (e) {}
    this._saved = false;
    this.setData({ evt: 'EVT: av05_hits cleared' });
    this._show(false);
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.saveTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.saveTap(); return; }
    if (key === 'ArrowDown' || key === 'ArrowUp') {  this._show(this._saved); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">结算 · 命中榜</text></view>
    <text class="status">{{status}}</text>
    <view class="board">
      <view ink:for="{{rows}}" class="hitrow"><text class="hittext">{{item.label}}</text></view>
    </view>
    <text class="line warn">{{weakText}}</text>
    <text class="line">{{summaryText}}</text>
    <text class="line bright">{{totalText}} · {{steady}}</text>
    <view class="btnrow">
      <button class="forgebtn main" bindtap="saveTap">入账</button>
      <button class="forgebtn" bindtap="clearTap">清空累计</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { background-color: #04140a; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 10px; padding: 3px 8px; margin-right: 10px; }
.ttl { color: #7dff9e; font-size: 17px; font-weight: bold; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.board { margin-top: 7px; border: 3px solid #40ff5e; background-color: #04140a; padding: 6px 8px; height: 142px; overflow: hidden; }
.hitrow { border-bottom: 1px solid rgba(64,255,94,0.45); padding: 2px 2px; }
.hittext { color: #7dff9e; font-size: 12px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 4px; }
.warn { color: #7dff9e; }
.bright { color: #7dff9e; }
.btnrow { display: flex; flex-direction: row; margin-top: 7px; }
.forgebtn { flex: 1; margin-right: 8px; background-color: #0a1f0e; color: #40ff5e; border: 3px solid rgba(64,255,94,0.85); font-size: 12px; padding: 6px 0; text-align: center; }
.main { color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
