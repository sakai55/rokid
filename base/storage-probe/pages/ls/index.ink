<script def>
{
  "title": "Probe LS"
}
</script>

<script setup>
import { VER, CHUNK, CAP, MAXCH, fail, errText, errName, isQuota, lsAvailable, readLast, saveSysResult, describeResult, tick, fmtBytes } from '../../probe.js';
import { errLine } from '../../err.js';

var RTKEY = 'sprobe.ls.rt';
var KEYP = 'sprobe.ls.';

export default {
  data: {
    evt: 'EVT: ls ready',
    ver: 'v' + VER,
    statusLine: 'localStorage 站 · 未运行',
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
    if (last && last.systems && last.systems.ls) {
      this._showResult(last.systems.ls, '上次结果');
    }
  },
  onHide() { this._abort = true; },
  onUnload() { this._dead = true; this._abort = true; },
  _set(obj) { if (!this._dead) { try { this.setData(obj); } catch (e) {} } },
  _showResult(r, tag) {
    var lines = describeResult('ls', r);
    var rows = [];
    for (var i = 0; i < lines.length; i++) rows.push({ text: lines[i] });
    this._set({
      statusLine: 'localStorage 站 · ' + tag,
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
    var avail = lsAvailable();
    if (!avail.ok) {
      var r0 = { v: 1, sys: 'ls', available: false, roundtrip: false, capacityBytes: null, capped: false, aborted: false, errorCode: avail.code, errName: '', errMsg: String(avail.raw || '').slice(0, 120), ts: Date.now() };
      fail(avail.code, avail.raw);
      saveSysResult('ls', r0);
      this._showResult(r0, '不可用');
      return;
    }
    this._running = true;
    this._abort = false;
    this._set({ statusLine: 'localStorage 站 · 运行中', progLine: '往返校验…', rows: [], failLine: '', evt: 'EVT: ls run' });

    var result = { v: 1, sys: 'ls', available: true, roundtrip: false, capacityBytes: null, capped: false, aborted: false, errorCode: '', errName: '', errMsg: '', ts: Date.now() };
    var code = '', lastErr = null;
    function note(c, e) {
      if (!code) code = c;
      lastErr = e;
      result.errName = errName(e);
      result.errMsg = errText(e).slice(0, 120);
    }

    // ---- roundtrip: write a known JSON payload, read it back, compare
    var payload = JSON.stringify({ v: 1, probe: 'storage-probe', n: 12345, tail: 'x'.repeat(64) });
    try {
      localStorage.setItem(RTKEY, payload);
      var back = localStorage.getItem(RTKEY);
      if (back !== payload) {
        var me = new Error('roundtrip mismatch');
        note('E5002', me); fail('E5002', errText(me));
      } else {
        result.roundtrip = true;
      }
    } catch (e) {
      note(isQuota(e) ? 'E5003' : 'E5001', e);
      fail(result.errorCode || (isQuota(e) ? 'E5003' : 'E5001'), errText(e));
    }
    try { localStorage.removeItem(RTKEY); } catch (e) {}

    // ---- capacity ramp: 32 KiB chunks until first throw or 16 MiB
    if (result.roundtrip) {
      var chunk = 'x'.repeat(CHUNK);
      var accepted = 0;
      var i = 0;
      for (i = 0; i < MAXCH; i++) {
        if (this._abort) break;
        try {
          localStorage.setItem(KEYP + i, chunk);
          accepted += CHUNK;
        } catch (e) {
          var c = isQuota(e) ? 'E5003' : 'E5001';
          note(c, e); fail(c, errText(e));
          break;
        }
        if (i % 4 === 3) this._set({ progLine: '爬坡中 已写入 ' + fmtBytes(accepted) + ' / 16 MiB' });
        await tick();
        if (this._dead) break;
      }
      if (i >= MAXCH && !this._abort) result.capped = true;
      result.capacityBytes = accepted;
      result.aborted = !!this._abort;

      // ---- verify first and last accepted chunk lengths
      if (accepted > 0 && !this._abort) {
        try {
          var f = localStorage.getItem(KEYP + '0');
          var l = localStorage.getItem(KEYP + (accepted / CHUNK - 1));
          if (!f || f.length !== CHUNK || !l || l.length !== CHUNK) {
            var ve = new Error('verify length mismatch');
            if (!code) { note('E5002', ve); }
            fail('E5002', errText(ve));
          }
        } catch (e) {
          if (!code) note('E5002', e);
          fail('E5002', errText(e));
        }
      }

      // ---- cleanup: remove ONLY our own sprobe.ls.* keys, never clear-all
      this._set({ progLine: '清理测试键…' });
      for (var j = 0; j < MAXCH; j++) {
        try { localStorage.removeItem(KEYP + j); } catch (e) {}
        if (j % 64 === 63) await tick();
      }
    }

    result.errorCode = code;
    result.ts = Date.now();
    saveSysResult('ls', result);
    this._running = false;
    this._set({ progLine: '', evt: 'EVT: ls done' });
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
    <text class="ttl">LS · localStorage 站</text>
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
