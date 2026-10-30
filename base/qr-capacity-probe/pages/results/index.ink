<script def>
{
  "title": "Probe Results"
}
</script>

<script setup>
import { VER, EC_LEVELS, readState, readLastError, fmtDT } from '../../qrprobe.js';
import { errLine } from '../../err.js';

export default {
  data: {
    evt: 'EVT: results',
    ver: 'v' + VER,
    headLine: '结果单',
    rows: []
  },
  onLoad() { this._build(); },
  onShow() { this._build(); },
  _build() {
    var st = readState();
    var rows = [];
    function bar(text) { rows.push({ text: text, head: true }); }
    function line(text) { rows.push({ text: text, head: false }); }

    var d = st.detector;
    bar('检测器 BarcodeDetector');
    if (!d) line('未探（回首页自动探一次）');
    else if (!d.available) line('不可用 · ' + (d.errCode || 'E7009'));
    else if (!d.qr) line('可用 · qr_code 不支持 · ' + (d.errCode || 'E7005'));
    else line('可用 · 支持 qr_code · 码制 ' + (d.formats ? d.formats.length : 0) + ' 种');

    for (var i = 0; i < EC_LEVELS.length; i++) {
      var ec = EC_LEVELS[i];
      bar('纠错 ' + ec);
      var e = st.encode[ec];
      var f = st.file[ec];
      var encTxt = (e && e.ceiling) ? ('编码 ' + e.ceiling.bytes + ' B·v' + e.ceiling.ver + (e.capped ? '·全过' : '')) : '编码 未测';
      var filTxt = (f && f.ceiling) ? ('读回 ' + f.ceiling + ' B') : (f ? '读回 无PASS' : '读回 未测');
      line(encTxt + ' ｜ ' + filTxt + (e && e.blobNote ? ' ｜ ' + e.blobNote : ''));
    }

    var cjk = st.encode.M && st.encode.M.cjk;
    bar('中文样本（纠错 M）');
    if (cjk && cjk.ok) line(cjk.chars + ' 字 = ' + cjk.bytes + ' B（UTF-8）· v' + cjk.ver);
    else if (cjk) line('编码失败：' + cjk.err);
    else line('未测（跑一次 M 档编码梯子）');

    bar('相机读码');
    var cam = st.camera || {};
    if (cam.best) line('最佳 ' + cam.best.bytes + ' B · ' + (cam.best.match ? '探针载荷' : '外部码') + ' · ' + cam.best.mode + (cam.last ? ' ｜ 最近 ' + cam.last.bytes + ' B' : ''));
    else line('未测');

    var le = readLastError();
    if (le && le.code) {
      bar('lastError ' + errLine(le.code));
      line(le.slug + ' v' + le.ver + ' · ' + fmtDT(le.ts));
      if (le.raw) line('原文：' + le.raw);
    }
    this.setData({
      headLine: '结果单' + (st.ts ? ' · ' + fmtDT(st.ts) : ' · 尚无记录'),
      rows: rows
    });
  }
};
</script>

<page>
  <view class="page">
    <text class="ttl">{{headLine}}</text>
    <view class="rows">
      <view ink:for="{{rows}}" class="row">
        <view ink:if="{{item.head}}" class="sbar"><text class="stxt">{{item.text}}</text></view>
        <text ink:if="{{!item.head}}" class="dtxt">{{item.text}}</text>
      </view>
    </view>
    <text class="note">本页数据读自本地 qrprobe.last，重启不丢，可直接拍照留档。预览数值是预览宿主的，只认真机。</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 6px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 14px; font-weight: 500; }
.rows { display: flex; flex-direction: column; margin-top: 4px; }
.row { margin-top: 1px; }
.sbar { background-color: #40ff5e; padding: 0 6px; margin-top: 1px; }
.stxt { color: #000000; font-size: 12px; font-weight: 500; line-height: 15px; }
.dtxt { color: #7dff9e; font-size: 13px; line-height: 16px; }
.note { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 5px; }
.footrow { display: flex; flex-direction: row; margin-top: 3px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
