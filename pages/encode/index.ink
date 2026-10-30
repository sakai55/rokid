<script def>
{
  "title": "Probe Encode"
}
</script>

<script setup>
import wx from 'wx';
import { VER, EC_LEVELS, LADDER, CJK_TEXT, fail, errText, payloadFor, encodeQR, fitScale, drawQR, qrToBlob, opfsGuard, opfsSave, storageCodeFor, readState, patchState, tick, fmtBytes, utf8Len } from '../../qrprobe.js';

export default {
  data: {
    evt: 'EVT: encode ready',
    ver: 'v' + VER,
    ecLine: '',
    statusLine: '编码站 · 未运行',
    progLine: '',
    rows: [],
    failLine: '',
    hintLine: '滑动切档 · 单击开跑 · 运行中双击 = 中止（留在本页）· 双击返回'
  },
  onLoad() {
    this._running = false;
    this._abort = false;
    this._dead = false;
    this._lastAct = 0;
    this._ec = 1; // M
    this._rowsAll = [];
    this._ctx = null;
    try { if (wx.createCanvasContext) this._ctx = wx.createCanvasContext('encCanvas'); } catch (e) { this._ctx = null; }
    this._ecRender();
    var st = readState();
    var rec = st.encode[EC_LEVELS[this._ec]];
    if (rec && rec.ceiling) {
      this._set({ statusLine: '编码站 · 上次 ' + rec.ec + ' 档上限 ' + rec.ceiling.bytes + ' B · v' + rec.ceiling.ver });
    }
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
    var rec = st.encode[EC_LEVELS[this._ec]];
    this._set({ statusLine: '编码站 · ' + EC_LEVELS[this._ec] + ' 档' + (rec && rec.ceiling ? ' · 上次上限 ' + rec.ceiling.bytes + ' B · v' + rec.ceiling.ver : ' · 未运行') });
  },
  ecTap() { if (!this._dup()) this._cycle(1); },
  runTap() { if (!this._dup()) this._run(); },
  _pushRow(text) {
    this._rowsAll.push(text);
    var show = this._rowsAll.slice(-6);
    var rows = [];
    for (var i = 0; i < show.length; i++) rows.push({ text: show[i] });
    this._set({ rows: rows });
  },
  _draw(enc) {
    if (!this._ctx) {
      try { if (wx.createCanvasContext) this._ctx = wx.createCanvasContext('encCanvas'); } catch (e) { this._ctx = null; }
    }
    if (!this._ctx) return;
    try {
      var ctx = this._ctx;
      ctx.fillStyle = '#000000';
      ctx.fillRect(0, 0, 176, 176);
      var scale = fitScale(enc.modules, 176, 176);
      var size = (enc.modules + 8) * scale;
      drawQR(ctx, enc.qr, scale, Math.floor((176 - size) / 2), Math.floor((176 - size) / 2));
    } catch (e) {}
  },
  async _run() {
    if (this._running) return;
    var ec = EC_LEVELS[this._ec];
    this._running = true;
    this._abort = false;
    this._rowsAll = [];
    this._set({ statusLine: '编码站 · 运行中（' + ec + ' 档）', progLine: '', rows: [], failLine: '', evt: 'EVT: encode run ' + ec });

    var rec = { ec: ec, rows: {}, ceiling: null, capped: false, blobNote: '', cjk: null, ts: Date.now() };
    var canStore = opfsGuard();
    if (!canStore) {
      fail('E5005', 'navigator.storage.getDirectory missing');
      rec.blobNote = 'OPFS 不可用 E5005，图未存';
    }
    var overflowed = false;

    for (var i = 0; i < LADDER.length; i++) {
      if (this._abort || this._dead) break;
      var n = LADDER[i];
      this._set({ progLine: '编码 ' + n + ' B…' });
      await tick();
      var enc = null, encErr = null;
      try { enc = encodeQR(payloadFor(n), ec); } catch (e) { encErr = e; }
      if (!enc) {
        // make() threw: length overflow — this IS the ceiling signal.
        overflowed = true;
        rec.rows[String(n)] = { ok: 0, err: errText(encErr).slice(0, 80) };
        this._pushRow(n + ' B 超限（编码器溢出）');
        patchState(function (st) { st.encode[ec] = rec; });
        break;
      }
      var scale = fitScale(enc.modules, 480, 352);
      this._draw(enc);
      var blobBytes = null;
      if (canStore) {
        // Two distinct failure points, two distinct code families:
        // canvas -> blob is the encode segment (E2002/E2003); writing
        // the blob to OPFS is the storage segment (E5001/E5003/E5005).
        var blob = null, blobCode = '';
        try {
          blob = await qrToBlob(enc.qr, scale);
          if (!blob) {
            blobCode = (typeof Canvas === 'undefined') ? 'E2002' : 'E2003';
            fail(blobCode, 'canvas / convertToBlob unavailable');
          }
        } catch (e) {
          blobCode = (typeof Canvas === 'undefined') ? 'E2002' : 'E2003';
          fail(blobCode, errText(e));
        }
        if (blobCode) {
          if (!rec.blobNote) rec.blobNote = '转图失败 ' + blobCode;
        } else {
          try {
            blobBytes = await opfsSave(ec, n, blob);
          } catch (e) {
            var c = storageCodeFor(e, true);
            fail(c, errText(e));
            if (!rec.blobNote) rec.blobNote = '存图失败 ' + c;
          }
        }
      }
      rec.rows[String(n)] = { ok: 1, ver: enc.version, modules: enc.modules, px: scale, blob: blobBytes };
      rec.ceiling = { bytes: n, ver: enc.version };
      this._pushRow(n + ' B OK · v' + enc.version + ' · ' + enc.modules + ' 模 · ' + scale + 'px/模' + (blobBytes ? ' · 图 ' + fmtBytes(blobBytes) : ''));
      patchState(function (st) { st.encode[ec] = rec; });
      await tick();
    }
    if (!overflowed && !this._abort && rec.ceiling && rec.ceiling.bytes === LADDER[LADDER.length - 1]) rec.capped = true;

    // CJK sanity sample, EC M only: 24 chars must count as 72 UTF-8
    // bytes — the byte-mode byte counting made visible.
    if (ec === 'M' && !this._abort && !this._dead) {
      this._set({ progLine: '中文样本…' });
      await tick();
      try {
        var ce = encodeQR(CJK_TEXT, 'M');
        rec.cjk = { ok: 1, chars: CJK_TEXT.length, bytes: utf8Len(CJK_TEXT), ver: ce.version, err: '' };
        this._pushRow('中文样本 ' + CJK_TEXT.length + ' 字 = ' + utf8Len(CJK_TEXT) + ' B · v' + ce.version);
      } catch (e) {
        rec.cjk = { ok: 0, chars: CJK_TEXT.length, bytes: utf8Len(CJK_TEXT), ver: 0, err: errText(e).slice(0, 80) };
      }
      patchState(function (st) { st.encode[ec] = rec; });
    }

    rec.ts = Date.now();
    patchState(function (st) { st.encode[ec] = rec; });
    this._running = false;
    this._set({
      progLine: '',
      evt: 'EVT: encode done ' + ec,
      statusLine: '编码站 · ' + ec + ' 档' + (this._abort ? '已中止' : '完成') +
        (rec.ceiling ? ' · 上限 ' + rec.ceiling.bytes + ' B · v' + rec.ceiling.ver + (rec.capped ? '（梯子全过）' : '') : ' · 无一通过'),
      failLine: rec.blobNote ? rec.blobNote : ''
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
    <text class="ttl">ENC · 编码站</text>
    <view class="ecbar" bindtap="ecTap"><text class="ectxt">{{ecLine}}</text></view>
    <text class="status">{{statusLine}}</text>
    <view class="mid">
      <canvas id="encCanvas" width="176" height="176" class="cv"></canvas>
      <view class="side">
        <text class="prog">{{progLine}}</text>
        <view class="rows">
          <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
        </view>
      </view>
    </view>
    <view class="runbtn" bindtap="runTap"><text class="runbtn-txt">▶ 跑编码梯子（当前档）</text></view>
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
.mid { display: flex; flex-direction: row; margin-top: 6px; }
.cv { background-color: #000000; width: 176px; height: 176px; }
.side { display: flex; flex-direction: column; margin-left: 10px; flex-grow: 1; }
.prog { color: #7dff9e; font-family: monospace; font-size: 12px; }
.rows { display: flex; flex-direction: column; margin-top: 4px; }
.row { margin-top: 2px; }
.rtxt { color: #7dff9e; font-size: 12px; line-height: 16px; }
.runbtn { margin-top: 8px; border: 1px solid #40ff5e; padding: 6px 10px; }
.runbtn-txt { color: #7dff9e; font-size: 15px; font-weight: 500; }
.fail { color: #000000; background-color: #40ff5e; font-size: 12px; font-weight: 500; margin-top: 6px; padding: 2px 6px; }
.hint { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 7px; }
.footrow { display: flex; flex-direction: row; margin-top: 5px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
