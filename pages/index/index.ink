<script def>
{
  "title": "Sijang Shopping"
}
</script>

<script setup>
import wx from 'wx';

// KR15 sijang-shopping - market home page (stall grid + progress).
// Merged boutique rebuild of CC09 high-shelf-ask + KR14 sijang-basket:
// wheelchair-first market shopping - help-phrase for high stalls plus a
// per-stall basket checklist that cannot check out while items are missing.
// State persists in wx storage 'sijangShoppingV1'.
const KEY = 'sijangShoppingV1';
const STALLS = [
  { name: '채소가게', items: ['시금치', '대파'] },
  { name: '생선가게', items: ['고등어', '오징어'] },
  { name: '과일가게', items: ['사과', '배'] },
  { name: '반찬가게', items: ['김치', '멸치볶음'] },
  { name: '잡화가게', items: ['고무장갑', '수세미'] },
  { name: '떡집', items: ['인절미', '송편'] }
];

export default {
  data: { status: '', s0: '', s1: '', s2: '', s3: '', s4: '', s5: '', prog: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { checked: [], askDone: [], trips: 0 }; },
  _recompute() {
    const st = this._load();
    const chk = st.checked || [];
    const per = STALLS.map(function (s, i) {
      const a = chk[i * 2] ? '●' : '○'; const b = chk[i * 2 + 1] ? '●' : '○';
      return s.name + ' ' + a + b;
    });
    const done = chk.filter(Boolean).length;
    this.setData({
      status: '시장 장보기: 가게 여섯 곳, 물건 열두 개',
      s0: per[0], s1: per[1], s2: per[2], s3: per[3], s4: per[4], s5: per[5],
      prog: '장바구니 ' + done + ' / 12 · 도움 요청 완료 ' + (st.askDone || []).length + '건 · 장보기 완료 ' + (st.trips || 0) + '회'
    });
  },
  askTap() { try { wx.navigateTo({ url: '/pages/ask/index' }); } catch (e) {} },
  basketTap() { try { wx.navigateTo({ url: '/pages/basket/index' }); } catch (e) {} },
  speakTap() { const st = this._load(); const done = (st.checked || []).filter(Boolean).length; this._speak('시장 장보기입니다. 장바구니에 열두 개 중 ' + done + '개를 담았습니다.'); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp') { event.preventDefault(); this.askTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.basketTap(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.speakTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="awning"></div>
    <div class="ttl">Sijang Shopping</div>
    <div class="status">{{ status }}</div>
    <div class="grid">
      <div class="stall">{{ s0 }}</div>
      <div class="stall">{{ s1 }}</div>
      <div class="stall">{{ s2 }}</div>
    </div>
    <div class="grid">
      <div class="stall">{{ s3 }}</div>
      <div class="stall">{{ s4 }}</div>
      <div class="stall">{{ s5 }}</div>
    </div>
    <div class="prog">{{ prog }}</div>
    <div class="btnrow">
      <button class="sign sign-main" bindtap="askTap">ASK</button>
      <button class="sign" bindtap="basketTap">BASKET</button>
      <button class="sign" bindtap="speakTap">SPEAK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 0 16px 12px 16px; box-sizing: border-box; position: relative; }
.awning { height: 12px; background-color: #14541f; border-bottom: 4px solid rgba(64,255,94,0.8); margin-bottom: 8px; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 12px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.grid { display: flex; flex-direction: row; margin-top: 10px; }
.stall { flex: 1; margin-right: 8px; border: 1px solid rgba(64,255,94,0.7); border-top: 6px solid rgba(64,255,94,0.85); color: #7dff9e; font-size: 13px; padding: 12px 4px; text-align: center; background-color: #061a0b; white-space: nowrap; overflow: hidden; }
.grid .stall:last-child { margin-right: 0; }
.prog { color: #40ff5e; font-size: 12px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 12px; }
.sign { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); border-top-width: 4px; font-size: 14px; padding: 7px 0; text-align: center; border-radius: 0 0 8px 8px; }
.btnrow .sign:last-child { margin-right: 0; }
.sign-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
