<script def>
{
  "title": "Probe WX"
}
</script>

<script setup>
import wx from 'wx';
import { VER, CHUNK, MAXCH, fail, errText, errName, isQuota, readLast, saveSysResult, describeResult, tick, fmtBytes } from '../../probe.js';
import { errLine } from '../../err.js';

var RTKEY = 'sprobe.wx.rt';
var RTAKEY = 'sprobe.wx.rta';
var KEYP = 'sprobe.wx.';

// Async wx storage throws synchronously when storage is unavailable in
// the current context — the executor's try/catch turns that into a
// rejection so every failure flows down one path.
function setP(key, data) {
  return new Promise(function (res, rej) {
    try {
      wx.setStorage({
        key: key, data: data,
        success: function () { res(); },
        fail: function (r) { rej(new Error((r && r.errMsg) || 'setStorage fail')); }
      });
    } catch (e) { rej(e); }
  });
}
function getP(key) {
  return new Promise(function (res, rej) {
    try {
      wx.getStorage({
        key: key,
        success: function (r) { res(r && r.data); },
        fail: function (r) { rej(new Error((r && r.errMsg) || 'getStorage fail')); }
      });
    } catch (e) { rej(e); }
  });
}
function removeP(key) {
  return new Promise(function (res) {
    try {
      wx.removeStorage({ key: key, success: function () { res(); }, fail: function () { res(); } });
    } catch (e) { res(); }
  });
}
function wxIface() {
  return typeof wx !== 'undefined' && typeof wx.setStorageSync === 'function' && typeof wx.setStorage === 'function';
}

export default {
  data: {
    evt: 'EVT: wx ready',
    ver: 'v' + VER,
    statusLine: 'wx 存储站 · 未运行',
    progLine: '',
    rows: [],
    failLine: '',
    hintLine: '单击开始 · 运行中双击 = 中止（留在本页）· 双击返回'
  },
  onLoad() {
    this._running = false;
    this._abort = false;
    this._dead = false;
    this._lastAct = 0;
    var last = readLast();
    if (last && last.systems && last.systems.wx) {
      this._showResult(last.systems.wx, '上次结果');
    }
  },
  onHide() { this._abort = true; },
  onUnload() { this._dead = true; this._abort = true; },
  _set(obj) { if (!this._dead) { try { this.setData(obj); } catch (e) {} } },
  _showResult(r, tag) {
    var lines = describeResult('wx', r);
    var rows = [];
    for (var i = 0; i < lines.length; i++) rows.push({ text: lines[i] });
    this._set({
      statusLine: 'wx 存储站 · ' + tag,
      rows: rows,
      failLine: r && r.errorCode ? errLine(r.errorCode) : ''
    });
  },
  _dup() {
    var now = Date.now();
    if (now - this._lastAct < 400) return true;
    this._lastAct = now;
    return false;
  },
  runTap() { if (!this._dup()) this._run(); },
  async _run() {
    if (this._running) return;
    if (!wxIface()) {
      var r0 = { v: 1, sys: 'wx', available: false, roundtrip: false, capacityBytes: null, capped: false, aborted: false, errorCode: 'E5005', errName: '', errMsg: 'wx storage interface missing', ts: Date.now() };
      fail('E5005', r0.errMsg);
      saveSysResult('wx', r0);
      this._showResult(r0, '不可用');
      return;
    }
    this._running = true;
    this._abort = false;
    this._set({ statusLine: 'wx 存储站 · 运行中', progLine: '同步往返校验…', rows: [], failLine: '', evt: 'EVT: wx run' });

    var result = { v: 1, sys: 'wx', available: true, roundtrip: false, syncRt: false, asyncRt: false, capacityBytes: null, capped: false, aborted: false, errorCode: '', errName: '', errMsg: '', ts: Date.now() };
    var code = '';
    function note(c, e) {
      if (!code) code = c;
      result.errName = errName(e);
      result.errMsg = errText(e).slice(0, 120);
    }

    // ---- sync roundtrip
    try {
      wx.setStorageSync(RTKEY, { v: 1, n: 42, s: 'storage-probe' });
      var sv = wx.getStorageSync(RTKEY);
      if (sv && sv.v === 1 && sv.n === 42 && sv.s === 'storage-probe') result.syncRt = true;
      else { var se = new Error('sync roundtrip mismatch'); note('E5002', se); fail('E5002', errText(se)); }
    } catch (e) {
      var sc = isQuota(e) ? 'E5003' : 'E5001';
      note(sc, e); fail(sc, errText(e));
    }
    try { wx.removeStorageSync(RTKEY); } catch (e) {}

    // ---- async roundtrip
    if (result.syncRt) {
      this._set({ progLine: '异步往返校验…' });
      try {
        await setP(RTAKEY, { v: 1, n: 7, s: 'async' });
        var av = await getP(RTAKEY);
        if (av && av.v === 1 && av.n === 7 && av.s === 'async') result.asyncRt = true;
        else { var ae = new Error('async roundtrip mismatch'); note('E5002', ae); fail('E5002', errText(ae)); }
      } catch (e) {
        var ac = isQuota(e) ? 'E5003' : 'E5001';
        note(ac, e); fail(ac, errText(e));
      }
      await removeP(RTAKEY);
    }
    result.roundtrip = result.syncRt && result.asyncRt;

    // ---- capacity ramp via async setStorage, 32 KiB per key
    if (result.roundtrip) {
      var chunk = 'x'.repeat(CHUNK);
      var accepted = 0;
      var i = 0;
      for (i = 0; i < MAXCH; i++) {
        if (this._abort) break;
        try {
          await setP(KEYP + i, chunk);
          accepted += CHUNK;
        } catch (e) {
          var c2 = isQuota(e) ? 'E5003' : 'E5001';
          note(c2, e); fail(c2, errText(e));
          break;
        }
        if (i % 4 === 3) this._set({ progLine: '爬坡中 已写入 ' + fmtBytes(accepted) + ' / 16 MiB' });
        await tick();
        if (this._dead) break;
      }
      if (i >= MAXCH && !this._abort) result.capped = true;
      result.capacityBytes = accepted;
      result.aborted = !!this._abort;

      // ---- verify the last accepted key through async getStorage
      if (accepted > 0 && !this._abort) {
        try {
          var lv = await getP(KEYP + (accepted / CHUNK - 1));
          if (typeof lv !== 'string' || lv.length !== CHUNK) {
            var ve2 = new Error('verify length mismatch');
            if (!code) note('E5002', ve2);
            fail('E5002', errText(ve2));
          }
        } catch (e) {
          if (!code) note('E5002', e);
          fail('E5002', errText(e));
        }
      }

      // ---- cleanup: removeStorage for every test key, never clear-all
      this._set({ progLine: '清理测试键…' });
      for (var j = 0; j < MAXCH; j++) {
        await removeP(KEYP + j);
        if (j % 32 === 31) await tick();
        if (this._dead) break;
      }
    }

    result.errorCode = code;
    result.ts = Date.now();
    saveSysResult('wx', result);
    this._running = false;
    this._set({ progLine: '', evt: 'EVT: wx done' });
    this._showResult(result, result.aborted ? '已中止' : '本次结果');
  },
  onKeyDown(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (!this._dup()) this._run(); }
    else if (k === 'Backspace') { if (this._running) this._abort = true; }
  },
  onKeyUp(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (event.preventDefault) event.preventDefault(); }
    else if (k === 'Backspace' && (this._running || this._abort) && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">WX · wx 存储站</text>
    <text class="status">{{statusLine}}</text>
    <view class="runbtn" bindtap="runTap"><text class="runbtn-txt">▶ 运行往返 + 容量爬坡</text></view>
    <text class="prog">{{progLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <text class="fail" ink:if="{{failLine}}">{{failLine}}</text>
    <text class="hint">{{hintLine}}</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 8px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 16px; font-weight: 500; }
.status { color: #40ff5e; font-size: 13px; margin-top: 5px; }
.runbtn { margin-top: 8px; border: 1px solid #40ff5e; padding: 6px 10px; }
.runbtn-txt { color: #7dff9e; font-size: 15px; font-weight: 500; }
.prog { color: #7dff9e; font-family: monospace; font-size: 13px; margin-top: 6px; }
.rows { display: flex; flex-direction: column; margin-top: 6px; }
.row { margin-top: 2px; }
.rtxt { color: #7dff9e; font-size: 17px; line-height: 23px; }
.fail { color: #000000; background-color: #40ff5e; font-size: 13px; font-weight: 500; margin-top: 6px; padding: 2px 6px; }
.hint { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
