<script def>
{
  "title": "Probe Results"
}
</script>

<script setup>
import { VER, readLast, readLastError, describeResult, fmtDT } from '../../probe.js';
import { errLine } from '../../err.js';

var SYS = [
  { key: 'ls', name: 'localStorage' },
  { key: 'wx', name: 'wx 存储' },
  { key: 'opfs', name: 'OPFS' }
];

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
    var last = readLast();
    var rows = [];
    if (!last || !last.systems) {
      this.setData({
        headLine: '结果单 · 尚无实测记录',
        rows: [
          { text: '还没有跑过任何一站。', head: false },
          { text: '回首页进任意一站运行一次，', head: false },
          { text: '结果会写进本地并在这里汇总。', head: false }
        ]
      });
      return;
    }
    for (var i = 0; i < SYS.length; i++) {
      var s = SYS[i];
      rows.push({ text: s.name, head: true });
      var lines = describeResult(s.key, last.systems[s.key]);
      for (var j = 0; j < lines.length; j++) rows.push({ text: lines[j], head: false });
    }
    var le = readLastError();
    if (le && le.code) {
      rows.push({ text: 'lastError ' + errLine(le.code), head: true });
      rows.push({ text: le.slug + ' v' + le.ver + ' · ' + fmtDT(le.ts), head: false });
    }
    this.setData({ headLine: '结果单 · ' + fmtDT(last.ts), rows: rows });
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
    <text class="note">本页数据读自本地 sprobe.last，重启不丢，可直接拍照留档。</text>
    <view class="footrow">
      <text class="evt">{{evt}}</text>
      <text class="ver">{{ver}}</text>
    </view>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 6px 14px; background-color: #000000; }
.ttl { color: #7dff9e; font-size: 15px; font-weight: 500; }
.rows { display: flex; flex-direction: column; margin-top: 4px; }
.row { margin-top: 1px; }
.sbar { background-color: #40ff5e; padding: 0 6px; margin-top: 2px; }
.stxt { color: #000000; font-size: 14px; font-weight: 500; line-height: 18px; }
.dtxt { color: #7dff9e; font-size: 15px; line-height: 18px; }
.note { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 5px; }
.footrow { display: flex; flex-direction: row; margin-top: 3px; }
.evt { flex-grow: 1; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
.ver { color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; }
</style>
