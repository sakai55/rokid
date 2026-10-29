<script def>
{"title": "Real MUD Probe"}
</script>

<script setup>
import wx from 'wx';
import { loadResults, saveResults, speak } from '../../judge.js';
import { fail } from '../../err.js';
import { log, flushLog } from '../../logq.js';

// 存储探针：localStorage 与 wx 存储各测四件事——
// 1) 单值 1/10/50/100KB 写入+读回校验；2) 累计写入到失败或 500KB；
// 3) 样本房间块 JSON 往返无损；4) 时间戳标记（杀进程重开后比对）。
// 进页先读上一轮留下的标记（在被本轮覆盖之前），结果单靠它判
// 「上次标记在/不在」。每项结果带实测数落盘，不下配额结论。
const ACTS = ['开始测试', 'BACK 返回'];
const SIZES = [1024, 10240, 51200, 102400];
const MARK_KEY = 'mud.probe.marker';
const TEST_PREFIX = 'mud.probe.t';

function checksum(s) { var h = 0; for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return h; }
function makeVal(n) { var head = 'MP' + n + ':'; var body = ''; while (body.length < n - head.length) body += 'x'; return head + body.slice(0, n - head.length); }

export default {
  data: {
    status: '存储探针：两种存储各测一轮，约需十几秒',
    lsLine: 'localStorage：未测',
    wxLine: 'wx 存储：未测',
    roomLine: '样本房间块：未测',
    markLine: '上次标记：进页时读取',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    // 先读旧标记：本轮测试会写新标记，旧标记的存在与时间要在覆盖前留底。
    this._prevMark = this._readMark();
    this._render();
  },
  onShow() { if (!this._busy) this._render(); },
  _readMark() {
    var found = null;
    try { var v = localStorage.getItem(MARK_KEY); if (v) found = JSON.parse(v); } catch (e) {}
    if (!found) { try { var w = wx.getStorageSync(MARK_KEY); if (w) found = (typeof w === 'string') ? JSON.parse(w) : w; } catch (e) {} }
    return found;
  },
  _render() {
    const r = loadResults();
    const s = r.storage;
    this.setData({
      markLine: '上次标记：' + (this._prevMark ? ('在（' + this._prevMark.at + '）') : '不在（首次运行或已被清）'),
      lsLine: s ? this._fmtBackend('localStorage', s.local) : this.data.lsLine,
      wxLine: s ? this._fmtBackend('wx 存储', s.wx) : this.data.wxLine,
      roomLine: s ? ('样本房间块往返（' + s.roomBytes + ' B）：' + (s.roomOk ? '无损 PASS' : 'FAIL')) : this.data.roomLine,
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，单击或点头执行）'
    });
  },
  _fmtBackend(name, b) {
    if (!b) return name + '：无结果';
    const sz = b.sizes.map(function (x) { return (x.kb + 'K' + (x.ok ? '✓' : '✗')); }).join(' ');
    return name + '：' + sz + ' · 累计 ' + b.cumKB + ' KB' + (b.cumCapped ? '（达 500K 上限未失败）' : '');
  },
  _backend(name) {
    // 统一读写口：返回 {set,get,del} 或 null（接口不存在）。
    if (name === 'local') {
      if (typeof localStorage === 'undefined') return null;
      return {
        set: function (k, v) { localStorage.setItem(k, v); },
        get: function (k) { return localStorage.getItem(k); },
        del: function (k) { try { localStorage.removeItem(k); } catch (e) {} }
      };
    }
    return {
      set: function (k, v) { wx.setStorageSync(k, v); },
      get: function (k) { var v = wx.getStorageSync(k); return (v === '' || v == null) ? null : v; },
      del: function (k) { try { wx.removeStorageSync(k); } catch (e) {} }
    };
  },
  _testBackend(name) {
    const be = this._backend(name);
    const out = { sizes: [], cumKB: 0, cumCapped: false, na: !be };
    if (!be) return out;
    for (var i = 0; i < SIZES.length; i++) {
      const n = SIZES[i];
      const val = makeVal(n);
      const key = TEST_PREFIX + '.' + name + '.' + n;
      var ok = false;
      try {
        be.set(key, val);
        const back = be.get(key);
        ok = (typeof back === 'string') && back.length === n && checksum(back) === checksum(val);
      } catch (e) { ok = false; }
      out.sizes.push({ kb: Math.round(n / 1024), ok: ok });
      be.del(key);
    }
    // 累计：10KB 一块往上堆，直到写失败或堆满 500KB。
    var chunk = makeVal(10240);
    var count = 0;
    for (var c = 0; c < 50; c++) {
      try { be.set(TEST_PREFIX + '.' + name + '.cum' + c, chunk); count++; }
      catch (e) { break; }
    }
    out.cumKB = count * 10;
    out.cumCapped = count >= 50;
    for (var d = 0; d < count; d++) be.del(TEST_PREFIX + '.' + name + '.cum' + d);
    return out;
  },
  async runTap() {
    if (this._busy) return;
    this._busy = true;
    this.setData({ status: '测试中…先测 localStorage', evt: 'EVT: storage run start' });
    // 让出一帧再跑重活，避免状态行不刷新。
    await new Promise(function (r) { setTimeout(r, 60); });
    try {
      const local = this._testBackend('local');
      this.setData({ status: 'localStorage 测完，接着测 wx 存储', lsLine: this._fmtBackend('localStorage', local) });
      await new Promise(function (r) { setTimeout(r, 60); });
      const wxb = this._testBackend('wx');
      // 样本房间块往返（走 wx 存储，与结果同一通道）。
      const room = { roomId: 'r1', name: '梧桐树下的长椅', desc: '一条长椅靠在梧桐树下，落叶堆在椅脚。石板路往东去，草坪在西边，北面围墙上爬满藤蔓。', sceneType: 'outdoor_park', exits: { E: 'r2', W: 'r3' }, entities: ['n1', 'i1'], anchor: { lat: 35.6812, lng: 139.7671, accuracyM: 18 }, judge: { confidence: 0.86, recognized: ['长椅', '梧桐树', '石板路'] }, pad: '' };
      while (JSON.stringify(room).length < 2400) room.pad += '记';
      const roomStr = JSON.stringify(room);
      var roomOk = false;
      try {
        wx.setStorageSync(TEST_PREFIX + '.room', roomStr);
        const back = wx.getStorageSync(TEST_PREFIX + '.room');
        roomOk = (typeof back === 'string') && back === roomStr && JSON.parse(back).roomId === 'r1';
        wx.removeStorageSync(TEST_PREFIX + '.room');
      } catch (e) { roomOk = false; }
      // 写本轮标记（供下次杀进程重开比对），两种存储各写一份。
      const mark = { at: new Date().toISOString() };
      try { localStorage.setItem(MARK_KEY, JSON.stringify(mark)); } catch (e) {}
      try { wx.setStorageSync(MARK_KEY, mark); } catch (e) {}
      const results = loadResults();
      results.storage = {
        local: local, wx: wxb, roomOk: roomOk, roomBytes: roomStr.length,
        prevMark: this._prevMark ? { found: true, at: this._prevMark.at } : { found: false, at: '' },
        at: new Date().toISOString()
      };
      if (!saveResults(results)) fail('E5001', 'results save failed');
      log('storage', '', 'ls[' + local.sizes.map(function (x) { return x.kb + (x.ok ? 'P' : 'F'); }).join(',') + '] cum' + local.cumKB + 'KB wx[' + wxb.sizes.map(function (x) { return x.kb + (x.ok ? 'P' : 'F'); }).join(',') + '] cum' + wxb.cumKB + 'KB room' + (roomOk ? 'P' : 'F') + ' mark' + (this._prevMark ? 'Y' : 'N'));
      flushLog();
      this.setData({ status: '存储探针完成，结果已落盘。杀掉进程重开，结果单应显示「上次标记：在」', evt: 'EVT: storage done' });
      speak('存储探针完成');
    } catch (e) {
      fail('E9001', e);
      this.setData({ status: '测试中断：E9001（已记 lastError，可重跑）', evt: 'EVT: storage FAIL E9001' });
    } finally { this._busy = false; this._render(); }
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.runTap(); else this.backTap(); },
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
    <text class="title">存储探针</text>
    <text class="status">{{status}}</text>
    <view class="card">
      <text class="line">测什么：单值能写多大、累计能堆多少、样本房间块（约 2.4 KB 的 JSON）存进去拿出来是否一字不变。</text>
      <text class="line">两种存储分开测：localStorage 与 wx 存储。测完自动清掉测试键，不占地方。</text>
      <text class="line">标记测持久：本轮会留一个时间戳标记；杀掉进程重开本页，若显示「在」，就是跨进程没丢。</text>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">开始测试</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">BACK 返回</button>
    <text class="line">{{lsLine}}</text>
    <text class="line">{{wxLine}}</text>
    <text class="line">{{roomLine}}</text>
    <text class="line">{{markLine}}</text>
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
