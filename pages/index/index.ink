<script def>
{
  "title": "Konbini Basket"
}
</script>

<script setup>
import wx from 'wx';

// JP03 Konbini Basket - 小票账本 Receipt Ledger
// Local anchor: 日本コンビニ的购物是高频小额：一手拿篮子一手拿手机，结账时还要应对一连串定型问句（割り箸は？袋は？温めますか？）。漏买一...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const ITEMS = [['おにぎり', 150], ['お茶 500ml', 130], ['サラダ', 210], ['プリン', 160]];
const PHRASES = ['割り箸をください', '袋に入れてください', '温めてください', 'そのままで大丈夫です'];
const SCAN_MODE = 'wide';
const SCAN_SYSTEM = '写真のバーコードの数字または商品名だけを出力してください。説明は不要です。';
const SCAN_QUESTION = 'この写真の商品のバーコード数字または商品名は何ですか？それだけを出力し、なければ NONE と出力してください。';
const DEMO_S = [{"got": [true, false, false, false], "idx": 1, "phrase": 0, "note": ""}, {"got": [true, true, true, false], "idx": 3, "phrase": 1, "note": ""}, {"got": [true, true, true, true], "idx": 3, "phrase": 2, "note": "complete"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"got": [false, false, false, false], "idx": 0, "phrase": 0, "note": ""};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) {
    const s = this._s;
    s.idx = Math.max(0, Math.min(ITEMS.length - 1, s.idx + dir));
    this.setData({ evt: 'EVT: swipe -> item ' + (s.idx + 1) }); this._recompute();
  },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.got[s.idx]) { this.setData({ evt: 'EVT: already in basket' }); this._recompute(); return; }
    s.got[s.idx] = true; s.note = '';
    let nxt = s.idx + 1; while (nxt < ITEMS.length && s.got[nxt]) nxt++;
    if (nxt < ITEMS.length) s.idx = nxt;
    const left = s.got.filter((g) => !g).length;
    this._speak(left === 0 ? '全部そろいました。レジへどうぞ。' : ('あと ' + left + ' 点です。'));
    this.setData({ evt: 'EVT: GOT ' + ITEMS[this._s.idx][0] + ' checked off' }); this._recompute();
  },
  act2Tap() { if (this._demoIdx >= 0) return; this._swipe(1); },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s.phrase = (this._s.phrase + 1) % PHRASES.length;
    this._speak(PHRASES[this._s.phrase]);
    this.setData({ evt: 'EVT: phrase card ' + (this._s.phrase + 1) + '/4' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const left = s.got.filter((g) => !g).length;
    const ok = this._speak(left === 0 ? '買い物は全部そろっています。' : ('あと ' + left + ' 点。次は ' + ITEMS[s.idx][0] + ' です。'));
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'summary' : 'FAIL') }); this._recompute();
  },
  _scanNote(msg) { this._s.note = msg; this.setData({ evt: 'EVT: ' + msg }); },
  _scanAnswer(ans) {
    const s = this._s;
    const cur = ITEMS[s.idx][0];
    const hit = ans && ans !== 'NONE' && (ans.indexOf('おにぎり') >= 0 || ans.indexOf('お茶') >= 0 || ans.indexOf('サラダ') >= 0 || ans.indexOf('プリン') >= 0 || /\d{8,}/.test(ans));
    s.note = hit ? ('SCAN暫定：' + ans.slice(0, 18) + ' — GOTで確定') : ('SCAN：' + (ans ? ans.slice(0, 18) : '読めず') + '（現在は ' + cur + '）');
    if (hit) this._speak('スキャン読み取り。GOTで確定してください。');
    this.setData({ evt: 'EVT: SCAN answer (tentative)' });
  },
  _recompute() {
    const s = this._s;
    const rows = ITEMS.map((it, i) => (i + 1) + ' ' + (s.got[i] ? '✓' : (i === s.idx ? '►' : '·')) + ' ' + it[0] + '  ¥' + it[1]);
    const sum = ITEMS.reduce((a, it, i) => a + (s.got[i] ? it[1] : 0), 0);
    const n = s.got.filter((g) => g).length;
    this.setData({
      status: s.note ? ('NOTE: ' + s.note) : (n === 4 ? 'DONE: 全部そろった — レジへ' : 'LIST: あと ' + (4 - n) + ' 点 · 現在 ' + ITEMS[s.idx][0]),
      hero: '合計 ¥' + sum, heroSub: n + '/4 点',
      r1: rows[0], r2: rows[1], r3: rows[2], r4: rows[3], marks: '',
      guide: '定型句：' + PHRASES[s.phrase] + ' · GOT 消し込み · SCAN 暫定読み · PHRASE 句を替える'
    });
  },
  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      const buf = await blob.arrayBuffer();
      const bytes = new Uint8Array(buf);
      let bin = '';
      const CH = 0x8000;
      for (let i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: blob read fail');
    }
  },

  async scanTap() {
    if (this._demoIdx >= 0 || this._busy) return;
    this._busy = true;
    this.setData({ evt: 'EVT: SCAN attempt (camera+LLM, guarded)' });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof ImageCapture === 'undefined') {
        this._scanNote('SCAN: SKIP - no camera path on this surface');
        return;
      }
      const stream = await nav.mediaDevices.getUserMedia({ video: true });
      let blob = null;
      try {
        const track = stream.getVideoTracks()[0];
        const cap = new ImageCapture(track);
        blob = await cap.takePhoto({ mode: SCAN_MODE });
      } finally {
        stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
      }
      if (!blob) { this._scanNote('SCAN: SKIP - no photo captured'); return; }
      if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) {
        this._scanNote('SCAN: SKIP - photo taken, no LLM on this surface');
        return;
      }
      const avail = await LanguageModel.availability();
      if (avail !== 'available') { this._scanNote('SCAN: SKIP - LLM unavailable (' + avail + ')'); return; }
      const session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: SCAN_SYSTEM }] });
      const dataUrl = await this._blobToDataUrl(blob);
      const ans = await session.prompt([
        { type: 'text', text: SCAN_QUESTION },
        { type: 'image_url', image_url: { url: dataUrl } }
      ]);
      try { session.destroy(); } catch (e) {}
      this._scanAnswer(String(ans || ''));
    } catch (e) {
      this._scanNote('SCAN: SKIP - ' + (e && e.message ? e.message : String(e)));
    } finally {
      this._busy = false;
      this._recompute();
    }
  },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) { return false; }
  },

  onOrientationStabilityChange(event) {
    const d = (event && event.detail) || {};
    this._steady = d.isStable === true || d.stable === true;
  },

  onHeadGesture(event) {
    const d = (event && event.detail) || {};
    const g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') return;
    if (!this._steady) return;
    if (this._demoIdx >= 0) return;
    this._nodAction();
  },

  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._swipe(1); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._swipe(-1); return; }
  },

  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  demoTap() {
    if (this._busy) return;
    if (this._demoIdx < 0) {
      this._savedS = JSON.parse(JSON.stringify(this._s));
      this._demoIdx = 0;
      this._stopTimers();
    } else {
      this._demoIdx++;
    }
    if (this._demoIdx >= DEMO_S.length) {
      this._s = this._savedS; this._savedS = null; this._demoIdx = -1;
      this._recompute();
      this.setData({ evt: 'EVT: DEMO off - real state restored' });
      return;
    }
    this._s = JSON.parse(JSON.stringify(DEMO_S[this._demoIdx]));
    this._recompute();
    this.setData({ evt: 'EVT: DEMO ' + (this._demoIdx + 1) + '/' + DEMO_S.length + ' (seeded, in-memory)' });
  },

  _stopTimers() {
    if (this._timer) { try { clearInterval(this._timer); } catch (e) {} this._timer = null; }
    if (this._micTimer) { try { clearInterval(this._micTimer); } catch (e) {} this._micTimer = null; }
    if (this._stream) { try { this._stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} }); } catch (e) {} this._stream = null; }
    if (this._ac) { try { this._ac.close(); } catch (e) {} this._ac = null; }
  }
};
</script>

<template>
  <div class="page">
    <div class="ttl">KONBINI BASKET</div>
    <div class="status">{{ status }}</div>
    <div class="receipt">
      <div class="rrow mono">{{ r1 }}</div>
      <div class="rrow mono">{{ r2 }}</div>
      <div class="rrow mono">{{ r3 }}</div>
      <div class="rrow mono">{{ r4 }}</div>
      <div class="totalrow">{{ hero }}<span class="tsub">{{ heroSub }}</span></div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">GOT</button>
      <button class="btn" bindtap="act2Tap">NEXT</button>
      <button class="btn" bindtap="act3Tap">PHRASE</button>
      <button class="btn" bindtap="scanTap">SCAN</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </div>
    <div class="guide">{{ guide }}</div>
    <div class="foot">{{ evt }}</div>
    <button class="demobtn" bindtap="demoTap">DEMO</button>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; line-height: 15px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.btn { flex: 1; margin-right: 6px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 13px; padding: 5px 0; text-align: center; }
.btnrow .btn:last-child { margin-right: 0; }
.btn-main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.guide { color: rgba(64,255,94,0.62); font-size: 10px; line-height: 13px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.rline { color: #7dff9e; font-size: 12px; line-height: 16px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.dim { color: rgba(125,255,158,0.75); }
.center { text-align: center; }
.mono { font-family: monospace; }
.heroline { color: #40ff5e; font-size: 16px; font-weight: bold; line-height: 21px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.foot { position: absolute; left: 14px; top: 322px; width: 350px; color: rgba(64,255,94,0.66); font-family: monospace; font-size: 9px; line-height: 12px; white-space: nowrap; overflow: hidden; }
.demobtn { position: absolute; left: 388px; top: 312px; width: 78px; height: 28px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 12px; text-align: center; }

.receipt { border: 1px dashed rgba(64,255,94,0.6); padding: 8px 12px; margin-top: 8px; }
.rrow { color: #7dff9e; font-size: 13px; line-height: 21px; white-space: nowrap; overflow: hidden; }
.totalrow { color: #40ff5e; font-size: 17px; font-weight: bold; border-top: 1px solid rgba(64,255,94,0.48); margin-top: 5px; padding-top: 5px; }
.tsub { color: rgba(125,255,158,0.8); font-size: 11px; font-weight: normal; margin-left: 8px; }
.btn { font-family: monospace; background-color: #000000; border: 1px dashed rgba(64,255,94,0.8); color: #7dff9e; letter-spacing: 1px; }
.btn-main { background-color: #0d2812; }
.demobtn { font-family: monospace; background-color: #000000; border: 1px dashed rgba(64,255,94,0.8); }
</style>
