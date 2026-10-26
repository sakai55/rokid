<script def>
{
  "title": "Sijang Ask"
}
</script>

<script setup>
import wx from 'wx';

// KR15 ask page: help-phrase card for high stalls.
// Pick a high item, cycle 4 phrase templates, read the big card aloud with
// TTS or show it large; a steady-head nod (or CONFIRM) records the request.
const KEY = 'sijangShoppingV1';
const HIGH = [
  { item: '사과', where: '과일가게 높은 선반' },
  { item: '수세미', where: '잡화가게 높은 선반' },
  { item: '멸치볶음', where: '반찬가게 높은 선반' },
  { item: '송편', where: '떡집 높은 진열대' }
];
const PHRASES = [
  '죄송하지만, 저 위에 있는 {item} 좀 내려 주시겠어요?',
  '휠체어에 앉아 있어서 손이 닿지 않아요. {item} 하나만 꺼내 주세요.',
  '저 선반의 {item}이 필요한데, 도와주실 수 있나요?',
  '{item}을 사고 싶은데 손이 닿지 않아요. 부탁드립니다.'
];

export default {
  data: { status: '', where: '', card: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._hi = 0; this._ph = 0; this._steady = false;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { checked: [], askDone: [], trips: 0 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },
  _phrase() { return PHRASES[this._ph].replace('{item}', HIGH[this._hi].item); },

  _recompute() {
    const st = this._load();
    const done = (st.askDone || []).indexOf(HIGH[this._hi].item) >= 0;
    this.setData({
      status: '도움 요청 카드: ' + (this._hi + 1) + ' / ' + HIGH.length + ' · 문장 ' + (this._ph + 1) + ' / ' + PHRASES.length + (done ? ' · 요청 완료 기록 있음' : ''),
      where: HIGH[this._hi].where + ' · ' + HIGH[this._hi].item,
      card: this._phrase(),
      guide: '고개를 끄덕이면 요청 완료로 기록합니다. SPEAK은 문장을 읽어 줍니다.'
    });
  },
  nextTap() { this._hi = (this._hi + 1) % HIGH.length; this._recompute(); },
  prevTap() { this._hi = (this._hi + HIGH.length - 1) % HIGH.length; this._recompute(); },
  phraseTap() { this._ph = (this._ph + 1) % PHRASES.length; this._recompute(); },
  speakTap() { this._speak(this._phrase()); this.setData({ evt: 'EVT: phrase spoken' }); },
  confirmTap() {
    const st = this._load();
    st.askDone = st.askDone || [];
    if (st.askDone.indexOf(HIGH[this._hi].item) < 0) st.askDone.push(HIGH[this._hi].item);
    this._save(st);
    this._speak('도움 요청을 완료로 기록했습니다.');
    this.setData({ evt: 'EVT: ask confirmed - ' + HIGH[this._hi].item });
    this._recompute();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || {}; this._steady = d.isStable === true || d.stable === true; },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod' && this._steady) this.confirmTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.confirmTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Ask Card</div>
    <div class="status">{{ status }}</div>
    <div class="where">{{ where }}</div>
    <div class="card">{{ card }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="sign" bindtap="prevTap">PREV</button>
      <button class="sign sign-main" bindtap="speakTap">SPEAK</button>
      <button class="sign" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="sign" bindtap="phraseTap">PHRASE</button>
      <button class="sign sign-main" bindtap="confirmTap">CONFIRM</button>
      <button class="sign" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.where { color: #7dff9e; font-size: 14px; margin-top: 10px; }
.card { margin-top: 10px; border: 2px solid rgba(64,255,94,0.85); background-color: #071c0c; color: #7dff9e; font-size: 19px; font-weight: bold; line-height: 27px; padding: 14px 12px; height: 86px; overflow: hidden; }
.guide { color: rgba(125,255,158,0.78); font-size: 11px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 9px; }
.sign { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.8); border-top-width: 4px; font-size: 13px; padding: 6px 0; text-align: center; border-radius: 0 0 8px 8px; }
.btnrow .sign:last-child { margin-right: 0; }
.sign-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
