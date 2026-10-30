<script def>
{
  "title": "Storage Probe"
}
</script>

<script setup>
import wx from 'wx';
import { VER, markerInfo, lsAvailable, opfsGuard, readLast, fmtDT, errText } from '../../probe.js';

var MENU = [
  { label: 'localStorage 站', url: '/pages/ls/index' },
  { label: 'wx 存储站', url: '/pages/wx/index' },
  { label: 'OPFS 站', url: '/pages/opfs/index' },
  { label: '结果单', url: '/pages/results/index' },
  { label: '说明与已知边界', url: '/pages/about/index' }
];

function wxAvailable() {
  if (typeof wx === 'undefined' || typeof wx.setStorageSync !== 'function') {
    return { ok: false, code: 'E5005', raw: 'wx storage interface missing' };
  }
  try {
    wx.setStorageSync('sprobe.ping', { v: 1 });
    var v = wx.getStorageSync('sprobe.ping');
    wx.removeStorageSync('sprobe.ping');
    return (v && v.v === 1) ? { ok: true } : { ok: false, code: 'E5002', raw: 'ping readback mismatch' };
  } catch (e) {
    try { wx.removeStorageSync('sprobe.ping'); } catch (e2) {}
    return { ok: false, code: 'E5005', raw: errText(e) };
  }
}

export default {
  data: {
    evt: 'EVT: home',
    ver: 'v' + VER,
    markerLine: '跨会话标记读取中…',
    cardLs: 'localStorage …',
    cardWx: 'wx 存储 …',
    cardOpfs: 'OPFS …',
    lastLine: '',
    menu: []
  },
  onLoad() {
    this._sel = 0;
    this._lastAct = 0;
    var mk = markerInfo();
    if (mk.prev) {
      this.setData({ markerLine: '上次启动 ' + fmtDT(mk.prev.lastTs) + ' · 这是第 ' + mk.cur.launches + ' 次启动' });
    } else {
      this.setData({ markerLine: '首次启动 · 无上次记录（跨会话标记已写入）' });
    }
    var a = lsAvailable();
    this.setData({ cardLs: 'localStorage ' + (a.ok ? '可用' : '不可用 · ' + a.code) });
    var w = wxAvailable();
    this.setData({ cardWx: 'wx 存储 ' + (w.ok ? '可用' : '不可用 · ' + w.code) });
    this.setData({ cardOpfs: 'OPFS ' + (opfsGuard() ? '可用（配额站内实测）' : '不可用 · E5005') });
    var last = readLast();
    if (last && last.ts) this.setData({ lastLine: '已有实测记录 · ' + fmtDT(last.ts) + '（结果单查看）' });
    this._render();
  },
  onShow() {
    var last = readLast();
    if (last && last.ts) this.setData({ lastLine: '已有实测记录 · ' + fmtDT(last.ts) + '（结果单查看）' });
  },
  _render() {
    var rows = [];
    for (var i = 0; i < MENU.length; i++) {
      rows.push({ idx: i, label: (i === this._sel ? '▶ ' : '　') + MENU[i].label, cls: i === this._sel ? 'row sel' : 'row' });
    }
    this.setData({ menu: rows });
  },
  _dup() {
    var now = Date.now();
    if (now - this._lastAct < 400) return true;
    this._lastAct = now;
    return false;
  },
  _open() {
    var m = MENU[this._sel];
    if (!m) return;
    this.setData({ evt: 'EVT: open ' + m.label });
    try { wx.navigateTo({ url: m.url }); } catch (e) {}
  },
  moveTap(d) {
    this._sel = (this._sel + d + MENU.length) % MENU.length;
    this.setData({ evt: 'EVT: select ' + MENU[this._sel].label });
    this._render();
  },
  rowTap(e) {
    var idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN;
    if (isNaN(idx)) return;
    this._sel = idx;
    this._render();
    if (!this._dup()) this._open();
  },
  onKeyDown(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (!this._dup()) this._open(); }
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
  },
  onKeyUp(event) {
    var k = event && (event.code || event.key);
    if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">STORAGE PROBE · 存储探针</text>
    <text class="marker">{{markerLine}}</text>
    <view class="cards">
      <text class="card">{{cardLs}}</text>
      <text class="card">{{cardWx}}</text>
      <text class="card">{{cardOpfs}}</text>
    </view>
    <view class="menu">
      <view ink:for="{{menu}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="mtxt">{{item.label}}</text></view>
    </view>
    <text class="last">{{lastLine}}</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.marker { color: #40ff5e; font-size: 13px; margin-top: 5px; }
.cards { display: flex; flex-direction: column; margin-top: 6px; border: 1px solid rgba(64,255,94,0.55); padding: 5px 8px; }
.card { color: #7dff9e; font-size: 13px; line-height: 19px; }
.menu { display: flex; flex-direction: column; margin-top: 8px; }
.row { padding: 4px 8px; margin-top: 3px; border: 1px solid rgba(64,255,94,0.35); }
.row.sel { background-color: #40ff5e; }
.mtxt { color: #7dff9e; font-size: 15px; }
.row.sel .mtxt { color: #000000; font-weight: 500; }
.last { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
