<script def>
{
  "title": "Nichijo Set"
}
</script>

<script setup>
import wx from 'wx';

// JP22 nichijo-set - daily-life hub (menu page).
// Merged boutique rebuild of CC11 left-home-proof + JP18 coin-laundry +
// JP19 origami-steps: leave-home proof with camera, laundry countdown
// watch, hands-busy origami steps. Shared state in wx storage 'nichijoSetV1'.
const KEY = 'nichijoSetV1';

export default {
  data: { status: '', proofLine: '', laundryLine: '', origamiLine: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { proof: null, laundry: [], origami: { done: [], work: 0, step: 0 } }; },
  _today() { return new Date().toISOString().slice(0, 10); },

  _recompute() {
    const st = this._load();
    const proofTxt = (st.proof && st.proof.date === this._today()) ? ('今日の存証: 完了 ' + st.proof.at) : '今日の存証: まだです';
    let running = 0;
    (st.laundry || []).forEach(function (m) { if (m.endAt && m.endAt > Date.now()) running++; });
    const laundryTxt = 'ランドリー: 稼働中 ' + running + ' 台';
    const og = st.origami || { done: [] };
    const origamiTxt = 'おりがみ: 完成 ' + (og.done || []).length + ' / 3 作品';
    this.setData({
      status: '日常生活セット: 今日の用事を三つ守ります',
      proofLine: proofTxt, laundryLine: laundryTxt, origamiLine: origamiTxt
    });
  },
  proofTap() { try { wx.navigateTo({ url: '/pages/proof/index' }); } catch (e) {} },
  laundryTap() { try { wx.navigateTo({ url: '/pages/laundry/index' }); } catch (e) {} },
  origamiTap() { try { wx.navigateTo({ url: '/pages/origami/index' }); } catch (e) {} },
  speakTap() {
    const st = this._load();
    const p = (st.proof && st.proof.date === this._today()) ? '今日の存証は完了しています。' : '今日の存証はまだです。';
    this._speak('日常生活セットです。' + p);
  },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.proofTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.laundryTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Nichijo Set</div>
    <div class="status">{{ status }}</div>
    <div class="tile" bindtap="proofTap">
      <div class="tic">鍵</div>
      <div class="tbody">
        <div class="tname">でかける前チェック</div>
        <div class="tsub">{{ proofLine }}</div>
      </div>
    </div>
    <div class="tile" bindtap="laundryTap">
      <div class="tic">洗</div>
      <div class="tbody">
        <div class="tname">ランドリー守候</div>
        <div class="tsub">{{ laundryLine }}</div>
      </div>
    </div>
    <div class="tile" bindtap="origamiTap">
      <div class="tic">折</div>
      <div class="tbody">
        <div class="tname">おりがみ手順</div>
        <div class="tsub">{{ origamiLine }}</div>
      </div>
    </div>
    <div class="btnrow">
      <button class="home" bindtap="proofTap">PROOF</button>
      <button class="home" bindtap="laundryTap">LAUNDRY</button>
      <button class="home" bindtap="origamiTap">ORIGAMI</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.tile { display: flex; flex-direction: row; margin-top: 10px; border: 1px solid rgba(64,255,94,0.7); background-color: #061a0b; padding: 9px 12px; border-radius: 10px; }
.tic { color: #7dff9e; font-size: 24px; font-weight: bold; width: 44px; text-align: center; border-right: 1px solid rgba(64,255,94,0.5); padding-right: 8px; }
.tbody { margin-left: 12px; }
.tname { color: #40ff5e; font-size: 16px; font-weight: bold; }
.tsub { color: rgba(125,255,158,0.85); font-size: 12px; margin-top: 2px; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.home { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 12px; padding: 6px 0; text-align: center; border-radius: 20px; }
.btnrow .home:last-child { margin-right: 0; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
