<script def>
{
  "title": "Tsugaku Record"
}
</script>

<script setup>
import wx from 'wx';

// JP26 tsugaku-mimamori - 記録.
// Reads per-day records from wx storage 'tsugakuMimamoriV1' and shows
// today's going-to-school / coming-home arrivals plus the unreached
// points as a reminder. ArrowUp/ArrowDown cycles the ▶ selection between
// the 登校 / 下校 rows; Enter (the main action) speaks the reminder for
// the selected direction. Nothing is invented: a day with no check-ins
// reads 0 / 8 with all points unreached.
const KEY = 'tsugakuMimamoriV1';
const POINTS = ['集合場所', '横断歩道', '公園前', '踏切', 'コンビニ前', '神社前', '学校門', '下校集合場所'];

export default {
  data: { status: '', r0: '', r1: '', missTo: '', missFrom: '', days: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { days: {} }; },

  _recompute() {
    const st = this._load();
    const date = new Date().toISOString().slice(0, 10);
    const day = st.days[date] || { to: [null, null, null, null, null, null, null, null], from: [null, null, null, null, null, null, null, null] };
    const toDone = day.to.filter(Boolean).length;
    const fromDone = day.from.filter(Boolean).length;
    const missToList = [];
    const missFromList = [];
    for (let i = 0; i < 8; i++) {
      if (!day.to[i]) missToList.push(POINTS[i]);
      if (!day.from[i]) missFromList.push(POINTS[i]);
    }
    this.setData({
      status: '通学記録：今日 ' + date,
      r0: (this._sel === 0 ? '▶ ' : '· ') + '登校 ' + toDone + ' / 8 地点',
      r1: (this._sel === 1 ? '▶ ' : '· ') + '下校 ' + fromDone + ' / 8 地点',
      missTo: '登校の未到達：' + (missToList.length ? missToList.join('・') : 'なし（全部そろいました）'),
      missFrom: '下校の未到達：' + (missFromList.length ? missFromList.join('・') : 'なし（全部そろいました）'),
      days: '記録のある日数：' + Object.keys(st.days || {}).length + '日（記録は端末に保存されます）'
    });
  },
  speakTap() {
    const st = this._load();
    const date = new Date().toISOString().slice(0, 10);
    const day = st.days[date] || { to: [null, null, null, null, null, null, null, null], from: [null, null, null, null, null, null, null, null] };
    const list = this._sel === 0 ? day.to : day.from;
    const miss = [];
    for (let i = 0; i < 8; i++) if (!list[i]) miss.push(POINTS[i]);
    const dir = this._sel === 0 ? '登校' : '下校';
    if (!miss.length) this._speak(dir + 'は全部そろっています。');
    else this._speak(dir + 'でまだの地点は、' + miss.join('、') + 'です。');
    this.setData({ evt: 'EVT: speaking unreached ' + dir });
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">通学記録</div>
    <div class="status">{{ status }}</div>
    <div class="cols">
      <div class="col">
        <div class="chead">登校</div>
        <div class="crow">{{ r0 }}</div>
      </div>
      <div class="col">
        <div class="chead">下校</div>
        <div class="crow">{{ r1 }}</div>
      </div>
    </div>
    <div class="miss">{{ missTo }}</div>
    <div class="miss">{{ missFrom }}</div>
    <div class="days">{{ days }}</div>
    <div class="note">到着は本人のチェック申告です。位置を測った証明ではありません。</div>
    <div class="btnrow">
      <button class="recbtn main" bindtap="speakTap">未到達を読み上げる</button>
      <button class="recbtn" bindtap="backTap">戻る</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.cols { display: flex; flex-direction: row; margin-top: 14px; }
.col { flex: 1; margin-right: 10px; border: 2px solid rgba(64,255,94,0.7); padding: 10px; background-color: #04140a; }
.cols .col:last-child { margin-right: 0; }
.chead { color: #40ff5e; font-size: 16px; font-weight: bold; text-align: center; }
.crow { color: #7dff9e; font-size: 14px; margin-top: 6px; white-space: nowrap; overflow: hidden; font-family: monospace; }
.miss { color: #40ff5e; font-size: 12px; margin-top: 10px; white-space: nowrap; overflow: hidden; }
.days { color: #7dff9e; font-size: 12px; margin-top: 10px; font-family: monospace; }
.note { color: rgba(125,255,158,0.75); font-size: 11px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.recbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 2px solid rgba(64,255,94,0.7); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 20px 20px 6px 6px; }
.btnrow .recbtn:last-child { margin-right: 0; }
.recbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
