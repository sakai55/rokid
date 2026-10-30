<script def>
{
  "title": "Probe Decode"
}
</script>

<script setup>
import { VER, EC_LEVELS, LADDER, fail, errText, payloadFor, utf8Len, probeDetector, makeDetector, opfsGuard, opfsRead, isNotFound, storageCodeFor, readState, patchState, tick } from '../../qrprobe.js';
import { errLine } from '../../err.js';

var OUTCOME = { PASS: 'PASS 内容一致', MISMATCH: '解出但内容不符', NONE: '未检出码', NOFILE: '无存图', ERR: '检测出错' };

export default {
  data: {
    evt: 'EVT: decode ready',
    ver: 'v' + VER,
    ecLine: '',
    statusLine: '文件读回站 · 未运行',
    progLine: '',
    rows: [],
    failLine: '',
    hintLine: '滑动切档 · 单击开跑（读编码站存的图）· 运行中双击 = 中止 · 双击返回'
  },
  onLoad() {
    this._running = false;
    this._abort = false;
    this._dead = false;
    this._lastAct = 0;
    this._ec = 1; // M
    this._rowsAll = [];
    this._ecRender();
    var st = readState();
    var rec = st.file[EC_LEVELS[this._ec]];
    if (rec && rec.ceiling) this._set({ statusLine: '文件读回站 · 上次 ' + rec.ec + ' 档上限 ' + rec.ceiling + ' B' });
  },
  onHide() { this._abort = true; },
  onUnload() { this._dead = true; this._abort = true; },
  _set(obj) { if (!this._dead) { try { this.setData(obj); } catch (e) {} } },
  _dup() {
    var now = Date.now();
    if (now - this._lastAct < 400) return true;
    this._lastAct = now;
    return false;
  },
  _ecRender() {
    this._set({ ecLine: '纠错档 ' + EC_LEVELS[this._ec] + ' / L M Q H · 滑动或点此行切换' });
  },
  _cycle(d) {
    if (this._running) return;
    this._ec = (this._ec + d + EC_LEVELS.length) % EC_LEVELS.length;
    this._ecRender();
    var st = readState();
    var rec = st.file[EC_LEVELS[this._ec]];
    this._set({ statusLine: '文件读回站 · ' + EC_LEVELS[this._ec] + ' 档' + (rec && rec.ceiling ? ' · 上次上限 ' + rec.ceiling + ' B' : ' · 未运行') });
  },
  ecTap() { if (!this._dup()) this._cycle(1); },
  runTap() { if (!this._dup()) this._run(); },
  _pushRow(text) {
    this._rowsAll.push(text);
    var show = this._rowsAll.slice(-9);
    var rows = [];
    for (var i = 0; i < show.length; i++) rows.push({ text: show[i] });
    this._set({ rows: rows });
  },
  async _run() {
    if (this._running) return;
    var ec = EC_LEVELS[this._ec];
    this._running = true;
    this._abort = false;
    this._rowsAll = [];
    this._set({ statusLine: '文件读回站 · 运行中（' + ec + ' 档）', progLine: '查检测器…', rows: [], failLine: '', evt: 'EVT: decode run ' + ec });

    var det = await probeDetector();
    patchState(function (st) {
      st.detector = { available: det.available, formats: det.formats, qr: det.qr, errCode: det.errCode, raw: det.raw, ts: Date.now() };
    });
    if (!det.available || !det.qr) {
      var gc = det.available ? (det.errCode || 'E7005') : 'E7009';
      fail(gc, det.raw);
      this._running = false;
      this._set({ progLine: '', statusLine: '文件读回站 · 检测器守卫态', failLine: errLine(gc) });
      return;
    }
    var detector = null;
    try { detector = makeDetector(); } catch (e) {
      fail('E7009', errText(e));
      this._running = false;
      this._set({ progLine: '', statusLine: '文件读回站 · 检测器构造失败', failLine: errLine('E7009') });
      return;
    }
    if (!opfsGuard()) {
      fail('E5005', 'navigator.storage.getDirectory missing');
      this._running = false;
      this._set({ progLine: '', statusLine: '文件读回站 · OPFS 不可用', failLine: errLine('E5005') });
      return;
    }

    var rec = { ec: ec, rows: {}, gotLens: {}, ceiling: null, ts: Date.now() };
    for (var i = 0; i < LADDER.length; i++) {
      if (this._abort || this._dead) break;
      var n = LADDER[i];
      this._set({ progLine: '读回 ' + n + ' B…' });
      var blob = null;
      try {
        blob = await opfsRead(ec, n);
      } catch (e) {
        if (isNotFound(e)) {
          rec.rows[String(n)] = 'NOFILE';
          this._pushRow(n + ' B ' + OUTCOME.NOFILE + '（先跑编码站）');
          patchState(function (st) { st.file[ec] = rec; });
          continue;
        }
        var rc = storageCodeFor(e, false);
        fail(rc, errText(e));
        rec.rows[String(n)] = 'ERR';
        this._pushRow(n + ' B 读图失败 ' + rc);
        patchState(function (st) { st.file[ec] = rec; });
        continue;
      }
      var res = null, detErr = null;
      try { res = await detector.detect(blob); } catch (e) { detErr = e; }
      if (detErr) {
        fail('E7004', errText(detErr));
        rec.rows[String(n)] = 'ERR';
        this._pushRow(n + ' B ' + OUTCOME.ERR + ' E7004');
      } else if (!res || !res.length) {
        rec.rows[String(n)] = 'NONE';
        this._pushRow(n + ' B ' + OUTCOME.NONE);
      } else {
        var raw = (res[0] && res[0].rawValue) || '';
        if (raw === payloadFor(n)) {
          rec.rows[String(n)] = 'PASS';
          rec.ceiling = n;
          this._pushRow(n + ' B ' + OUTCOME.PASS);
        } else {
          rec.rows[String(n)] = 'MISMATCH';
          rec.gotLens[String(n)] = utf8Len(raw);
          this._pushRow(n + ' B ' + OUTCOME.MISMATCH + '（解出 ' + utf8Len(raw) + ' B）');
        }
      }
      patchState(function (st) { st.file[ec] = rec; });
      await tick();
    }

    rec.ts = Date.now();
    patchState(function (st) { st.file[ec] = rec; });
    this._running = false;
    this._set({
      progLine: '',
      evt: 'EVT: decode done ' + ec,
      statusLine: '文件读回站 · ' + ec + ' 档' + (this._abort ? '已中止' : '完成') +
        (rec.ceiling ? ' · 读回上限 ' + rec.ceiling + ' B' : ' · 无一 PASS')
    });
  },
  onKeyDown(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook') { if (!this._dup()) this._run(); }
    else if (k === 'ArrowUp') this._cycle(-1);
    else if (k === 'ArrowDown') this._cycle(1);
    else if (k === 'Backspace') { if (this._running) this._abort = true; }
  },
  onKeyUp(event) {
    var k = event && (event.code || event.key);
    if (k === 'Enter' || k === 'GlobalHook' || k === 'ArrowUp' || k === 'ArrowDown') { if (event.preventDefault) event.preventDefault(); }
    else if (k === 'Backspace' && (this._running || this._abort) && event.preventDefault) event.preventDefault();
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">DEC · 文件读回站</text>
    <view class="ecbar" bindtap="ecTap"><text class="ectxt">{{ecLine}}</text></view>
    <text class="status">{{statusLine}}</text>
    <text class="prog">{{progLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <view class="runbtn" bindtap="runTap"><text class="runbtn-txt">▶ 读回当前档全部存图并解码</text></view>
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
.ecbar { margin-top: 5px; border: 1px solid rgba(64,255,94,0.55); padding: 3px 8px; }
.ectxt { color: #40ff5e; font-size: 13px; }
.status { color: #7dff9e; font-size: 13px; margin-top: 5px; }
.prog { color: #7dff9e; font-family: monospace; font-size: 12px; margin-top: 5px; }
.rows { display: flex; flex-direction: column; margin-top: 5px; }
.row { margin-top: 2px; }
.rtxt { color: #7dff9e; font-size: 13px; line-height: 18px; }
.runbtn { margin-top: 8px; border: 1px solid #40ff5e; padding: 6px 10px; }
.runbtn-txt { color: #7dff9e; font-size: 15px; font-weight: 500; }
.fail { color: #000000; background-color: #40ff5e; font-size: 12px; font-weight: 500; margin-top: 6px; padding: 2px 6px; }
.hint { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
