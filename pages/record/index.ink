<script def>
{
  "title": "Eki Dekake Record"
}
</script>

<script setup>
import wx from 'wx';

// JP20 eki-dekake - 記録: trip history + frequent station, from wx storage.
const KEY = 'ekiDekakeV1';

export default {
  data: { status: '', freq: '', t0: '', t1: '', t2: '', t3: '', t4: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { lastStation: 0, kasa: null, trips: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const st = this._load();
    const trips = (st.trips || []).slice(-5).reverse();
    const counts = {};
    (st.trips || []).forEach(function (t) { counts[t.station] = (counts[t.station] || 0) + 1; });
    let best = 'まだ記録がありません', bestN = 0;
    Object.keys(counts).forEach(function (k) { if (counts[k] > bestN) { bestN = counts[k]; best = k + '（' + bestN + ' 回）'; } });
    const row = function (t) { return t ? (t.date + ' ' + t.at + ' ・ ' + t.station + ' ・ ' + t.phase) : '—'; };
    this.setData({
      status: '記録：出行 ' + (st.trips || []).length + ' 件を保存しています',
      freq: 'よく使う駅: ' + best,
      t0: row(trips[0]), t1: row(trips[1]), t2: row(trips[2]), t3: row(trips[3]), t4: row(trips[4])
    });
  },
  clearTap() {
    const st = this._load(); st.trips = []; this._save(st);
    this.setData({ evt: 'EVT: trips cleared' });
    this._recompute();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  speakTap() {
    const st = this._load();
    this._speak('これまでの出行記録は' + (st.trips || []).length + '件です。');
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) { if (event.key === 'Enter' || event.key === 'GlobalHook') { event.preventDefault(); this.speakTap(); } },
  onKeyUp(event) { if (event.key === 'Enter') event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Trip Record</div>
    <div class="status">{{ status }}</div>
    <div class="freq">{{ freq }}</div>
    <div class="log">
      <div class="lrow">{{ t0 }}</div>
      <div class="lrow">{{ t1 }}</div>
      <div class="lrow">{{ t2 }}</div>
      <div class="lrow">{{ t3 }}</div>
      <div class="lrow">{{ t4 }}</div>
    </div>
    <div class="btnrow">
      <button class="stamp" bindtap="speakTap">SPEAK</button>
      <button class="stamp" bindtap="clearTap">CLEAR</button>
      <button class="stamp" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #02100a; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.freq { color: #7dff9e; font-size: 16px; font-weight: bold; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.log { margin-top: 10px; border-left: 3px solid rgba(64,255,94,0.6); padding-left: 10px; }
.lrow { color: #40ff5e; font-size: 12px; line-height: 21px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.stamp { flex: 1; margin-right: 8px; background-color: transparent; color: #40ff5e; border: 2px solid rgba(64,255,94,0.75); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 50%; }
.btnrow .stamp:last-child { margin-right: 0; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
