<script def>
{
  "title": "Probe OPFS"
}
</script>

<script setup>
import { VER, fail, errText, errName, opfsGuard, readLast, saveSysResult, describeResult, tick, fmtBytes } from '../../probe.js';
import { errLine } from '../../err.js';

var MIB = 1024 * 1024;
var MAXW = 16; // 16 x 1 MiB = the same 16 MiB ceiling as the KV ramps

function codeFor(e, fallback) {
  var nm = errName(e);
  if (nm === 'NotSupportedError') return 'E5005';
  if (nm === 'QuotaExceededError') return 'E5003';
  return fallback || 'E9001';
}

export default {
  data: {
    evt: 'EVT: opfs ready',
    ver: 'v' + VER,
    statusLine: 'OPFS 站 · 未运行',
    quotaLine: '',
    usedLine: '',
    persistLine: '',
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
    if (last && last.systems && last.systems.opfs) {
      this._showResult(last.systems.opfs, '上次结果');
    }
  },
  onHide() { this._abort = true; },
  onUnload() { this._dead = true; this._abort = true; },
  _set(obj) { if (!this._dead) { try { this.setData(obj); } catch (e) {} } },
  _showResult(r, tag) {
    var lines = describeResult('opfs', r);
    var rows = [];
    for (var i = 0; i < lines.length; i++) rows.push({ text: lines[i] });
    this._set({
      statusLine: 'OPFS 站 · ' + tag,
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
    if (!opfsGuard()) {
      var r0 = { v: 1, sys: 'opfs', available: false, usage: null, quota: null, persisted: null, persistResult: null, writtenBytes: 0, verified: false, capped: false, aborted: false, errorCode: 'E5005', errName: 'NotSupportedError', errMsg: 'navigator.storage.getDirectory missing', ts: Date.now() };
      fail('E5005', r0.errMsg);
      saveSysResult('opfs', r0);
      this._showResult(r0, '不可用');
      return;
    }
    this._running = true;
    this._abort = false;
    this._set({ statusLine: 'OPFS 站 · 运行中', progLine: '读取配额…', rows: [], failLine: '', quotaLine: '', usedLine: '', persistLine: '', evt: 'EVT: opfs run' });

    var result = { v: 1, sys: 'opfs', available: true, usage: null, quota: null, persisted: null, persistResult: null, writtenBytes: 0, verified: false, capped: false, aborted: false, errorCode: '', errName: '', errMsg: '', ts: Date.now() };
    var code = '';
    function note(c, e) {
      if (!code) code = c;
      result.errName = errName(e);
      result.errMsg = errText(e).slice(0, 120);
    }
    var st = navigator.storage;

    // ---- headline numbers: estimate() usage / quota (runtime values;
    // the official docs publish no quota number anywhere)
    try {
      var est = await st.estimate();
      if (est) {
        if (typeof est.usage === 'number') result.usage = est.usage;
        if (typeof est.quota === 'number') result.quota = est.quota;
      }
    } catch (e) {
      var ec = codeFor(e);
      note(ec, e); fail(ec, errText(e));
    }
    this._set({
      quotaLine: '配额 quota ' + fmtBytes(result.quota),
      usedLine: '已用 usage ' + fmtBytes(result.usage)
    });

    // ---- persistence state, then request persistence
    try { result.persisted = await st.persisted(); } catch (e) { result.persisted = null; }
    try { result.persistResult = await st.persist(); } catch (e) { result.persistResult = null; }
    this._set({
      persistLine: '持久化 ' + (result.persisted === true ? '已持久' : (result.persisted === false ? '未持久' : '未知')) +
        ' · 申请 ' + (result.persistResult === true ? '通过' : (result.persistResult === false ? '未通过' : '未知'))
    });

    // ---- write test: sprobe/ramp.bin, 1 MiB writes up to 16 MiB,
    // close() commits, then getFile() must report the same size
    var root = null, w = null, written = 0;
    try {
      root = await st.getDirectory();
      var dir = await root.getDirectoryHandle('sprobe', { create: true });
      var fh = await dir.getFileHandle('ramp.bin', { create: true });
      w = await fh.createWritable();
      var buf = new Uint8Array(MIB);
      for (var b = 0; b < MIB; b++) buf[b] = 0x78;
      var i = 0;
      for (i = 0; i < MAXW; i++) {
        if (this._abort) break;
        await w.write(buf);
        written += MIB;
        this._set({ progLine: '写入中 ' + fmtBytes(written) + ' / 16 MiB' });
        await tick();
        if (this._dead) break;
      }
      await w.close();
      w = null;
      if (i >= MAXW && !this._abort) result.capped = true;
      result.writtenBytes = written;
      result.aborted = !!this._abort;
      var f = await fh.getFile();
      if (f && f.size === written) {
        result.verified = true;
      } else {
        var ve = new Error('size mismatch: wrote ' + written + ', file ' + (f ? f.size : 'null'));
        if (!code) note('E5002', ve);
        fail('E5002', errText(ve));
      }
    } catch (e) {
      if (w) { try { await w.close(); } catch (e2) {} w = null; }
      result.writtenBytes = written;
      result.aborted = !!this._abort;
      var wc = codeFor(e);
      note(wc, e); fail(wc, errText(e));
    }

    // ---- cleanup: remove only our own sprobe directory tree
    try {
      if (!root) root = await st.getDirectory();
      await root.removeEntry('sprobe', { recursive: true });
    } catch (e) { /* already gone or host refuses — the next run recreates it */ }

    result.errorCode = code;
    result.ts = Date.now();
    saveSysResult('opfs', result);
    this._running = false;
    this._set({ progLine: '', evt: 'EVT: opfs done' });
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
    <text class="ttl">OPFS · 文件存储站</text>
    <text class="status">{{statusLine}}</text>
    <view class="runbtn" bindtap="runTap"><text class="runbtn-txt">▶ 查配额 + 写入验证</text></view>
    <text class="big">{{quotaLine}}</text>
    <text class="big">{{usedLine}}</text>
    <text class="mid">{{persistLine}}</text>
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
.big { color: #7dff9e; font-family: monospace; font-size: 18px; font-weight: 500; margin-top: 5px; }
.mid { color: #40ff5e; font-size: 13px; margin-top: 3px; }
.prog { color: #7dff9e; font-family: monospace; font-size: 13px; margin-top: 4px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; }
.row { margin-top: 2px; }
.rtxt { color: #7dff9e; font-size: 17px; line-height: 23px; }
.fail { color: #000000; background-color: #40ff5e; font-size: 13px; font-weight: 500; margin-top: 6px; padding: 2px 6px; }
.hint { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
