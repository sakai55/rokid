<script def>
{
  "title": "Sijang Basket"
}
</script>

<script setup>
import wx from 'wx';

// KR15 basket page: per-stall checklist, 6 stalls x 2 items = 12.
// Checkout stays locked while any item is missing; finishing a full basket
// records a completed trip and clears the list for the next visit.
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
  data: { status: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', missing: '', evt: 'EVT: ready' },

  onLoad() { this._stall = 0; try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { checked: [], askDone: [], trips: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const st = this._load();
    const chk = st.checked || [];
    const rows = STALLS.map(function (s, i) {
      const a = chk[i * 2] ? '●' : '○'; const b = chk[i * 2 + 1] ? '●' : '○';
      return (i === this._stall ? '▶ ' : '· ') + s.name + '  ' + s.items[0] + ' ' + a + '  ' + s.items[1] + ' ' + b;
    }.bind(this));
    const done = chk.filter(Boolean).length;
    const miss = [];
    STALLS.forEach(function (s, i) { s.items.forEach(function (it, j) { if (!chk[i * 2 + j]) miss.push(it); }); });
    const cur = STALLS[this._stall];
    this.setData({
      status: '장바구니 확인: 가게별로 하나씩 담았는지 봅니다',
      r0: rows[0], r1: rows[1], r2: rows[2], r3: rows[3], r4: rows[4], r5: rows[5],
      detail: '지금 가게: ' + cur.name + ' · ' + cur.items[0] + ' / ' + cur.items[1],
      missing: done >= 12 ? '빠진 물건이 없습니다. 계산할 수 있습니다.' : ('빠진 물건 ' + (12 - done) + '개: ' + miss.join(', '))
    });
  },
  nextTap() { this._stall = (this._stall + 1) % STALLS.length; this._recompute(); },
  prevTap() { this._stall = (this._stall + STALLS.length - 1) % STALLS.length; this._recompute(); },
  _toggle(j) {
    const st = this._load();
    st.checked = st.checked || [];
    const i = this._stall * 2 + j;
    st.checked[i] = !st.checked[i];
    this._save(st);
    this._recompute();
  },
  item1Tap() { this._toggle(0); },
  item2Tap() { this._toggle(1); },
  checkoutTap() {
    const st = this._load();
    const done = (st.checked || []).filter(Boolean).length;
    if (done < 12) { this._speak('아직 빠진 물건이 있습니다. 빠진 물건을 먼저 확인하세요.'); this.setData({ evt: 'EVT: checkout blocked - missing items' }); return; }
    st.trips = (st.trips || 0) + 1;
    st.checked = [];
    this._save(st);
    this._speak('장보기를 마쳤습니다. 열두 개를 모두 담았습니다.');
    this.setData({ evt: 'EVT: checkout done, trip recorded' });
    this._recompute();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  speakTap() { const st = this._load(); const done = (st.checked || []).filter(Boolean).length; this._speak('장바구니에 열두 개 중 ' + done + '개를 담았습니다.'); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.item1Tap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Basket Check</div>
    <div class="status">{{ status }}</div>
    <div class="list">
      <div class="lrow">{{ r0 }}</div>
      <div class="lrow">{{ r1 }}</div>
      <div class="lrow">{{ r2 }}</div>
      <div class="lrow">{{ r3 }}</div>
      <div class="lrow">{{ r4 }}</div>
      <div class="lrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="missing">{{ missing }}</div>
    <div class="btnrow">
      <button class="tag" bindtap="prevTap">PREV</button>
      <button class="tag" bindtap="item1Tap">ITEM 1</button>
      <button class="tag" bindtap="item2Tap">ITEM 2</button>
      <button class="tag" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="tag tag-main" bindtap="checkoutTap">CHECKOUT</button>
      <button class="tag" bindtap="speakTap">SPEAK</button>
      <button class="tag" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.list { margin-top: 8px; border: 1px solid rgba(64,255,94,0.6); padding: 6px 10px; background-color: #04140a; }
.lrow { color: #7dff9e; font-size: 13px; line-height: 20px; white-space: nowrap; overflow: hidden; }
.detail { color: #40ff5e; font-size: 12px; margin-top: 7px; white-space: nowrap; overflow: hidden; }
.missing { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.tag { flex: 1; margin-right: 6px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); font-size: 12px; padding: 6px 0; text-align: center; border-radius: 3px; }
.btnrow .tag:last-child { margin-right: 0; }
.tag-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
