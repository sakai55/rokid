<script def>
{
  "title": "Gomi Sort"
}
</script>

<script setup>
import wx from 'wx';

// JP06 Gomi Sort - 分流裁判 Branching Referee
// Local anchor: 日本のごみ分別是全球最细的家庭制度之一：同一件东西在不同市区町村可能属于不同类别，ペットボトル要撕标签、スプレー缶要打孔...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const ITEMS = ['ペットボトル', '乾電池', '割れた皿', '古新聞', 'スプレー缶'];
const KEY = [2, 1, 1, 2, 1];
const BINS = ['燃やすごみ', '燃やさないごみ', '資源', '粗大ごみ'];
const DAYS = [['月・木', '火', '水', '予約制'], ['火・金', '水', '土', '予約制'], ['自宅カード', '自宅カード', '自宅カード', '自宅カード']];
const WARDS = ['渋谷区モデル', '世田谷区モデル', '自宅カード'];
const SCAN_MODE = 'telephoto';
const SCAN_SYSTEM = '只输出物品最可能的垃圾类别与一句理由，不要下结论，用「候補：」开头。';
const SCAN_QUESTION = '这件物品在日本家庭垃圾分类里最可能属于哪一类（燃やす/燃やさない/資源/粗大）？以「候補：」开头输出类别与一句理由。';
const DEMO_S = [{"item": 1, "pick": 1, "ward": 0, "score": 1, "miss": 0, "note": ""}, {"item": 3, "pick": 0, "ward": 0, "score": 2, "miss": 1, "note": "割れた皿は燃やさないごみ"}, {"item": 5, "pick": 2, "ward": 0, "score": 4, "miss": 1, "note": "完了"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"item": 0, "pick": 0, "ward": 0, "score": 0, "miss": 0, "note": ""};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this._s.pick = Math.max(0, Math.min(3, this._s.pick + dir)); this.setData({ evt: 'EVT: pick -> ' + BINS[this._s.pick] }); this._recompute(); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.item >= ITEMS.length) { this.setData({ evt: 'EVT: set complete - WARD/RESET in README flow' }); this._recompute(); return; }
    if (s.pick === KEY[s.item]) { s.score++; s.note = ITEMS[s.item] + ' ✓ ' + BINS[s.pick] + '（' + DAYS[s.ward][s.pick] + '）'; this._speak('正解です。' + BINS[s.pick] + 'です。'); }
    else { s.miss++; s.note = ITEMS[s.item] + ' は ' + BINS[KEY[s.item]] + '（' + DAYS[s.ward][KEY[s.item]] + '）'; this._speak('違います。' + s.note); }
    s.item++; s.pick = 0;
    this.setData({ evt: 'EVT: judged - score ' + s.score + ' miss ' + s.miss }); this._recompute();
  },
  act2Tap() { if (this._demoIdx >= 0) return; this._swipe(1); },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s.ward = (this._s.ward + 1) % WARDS.length;
    this._speak('ルールカードは ' + WARDS[this._s.ward] + ' です。');
    this.setData({ evt: 'EVT: ward card -> ' + WARDS[this._s.ward] }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const t = s.item >= ITEMS.length ? ('完了。正解 ' + s.score + '、ミス ' + s.miss + ' でした。') : ('次は ' + ITEMS[s.item] + '。どこへ分けますか。');
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'prompt' : 'FAIL') }); this._recompute();
  },
  _scanNote(msg) { this._s.note = msg; this.setData({ evt: 'EVT: ' + msg }); this._recompute(); },
  _scanAnswer(ans) {
    this._s.note = '候補（暫定）：' + String(ans || '不明').slice(0, 26) + ' — 落判はカードで';
    this.setData({ evt: 'EVT: SCAN hint only, never decides' }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const rows = BINS.map((b, i) => (i === s.pick ? '► ' : '└ ') + b + ' · ' + DAYS[s.ward][i]);
    const done = s.item >= ITEMS.length;
    this.setData({
      status: done ? ('DONE: 正解 ' + s.score + '/5 · ミス ' + s.miss + ' · カード ' + WARDS[s.ward]) : ('ITEM ' + (s.item + 1) + '/5 · カード ' + WARDS[s.ward] + ' が正典です'),
      hero: done ? '分別完了' : ITEMS[s.item],
      heroSub: '', r1: rows[0], r2: rows[1], r3: rows[2], r4: rows[3], marks: '',
      guide: (s.note ? ('メモ：' + s.note + ' · ') : '') + 'PICK 选落点 · JUDGE 落判 · SCAN 只是候选'
    });
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
      const dataUrl = await new Promise((resolve, reject) => {
        const r = new FileReader();
        r.onload = () => resolve(r.result);
        r.onerror = () => reject(new Error('blob read fail'));
        r.readAsDataURL(blob);
      });
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
    <div class="ttl">GOMI SORT</div>
    <div class="status">{{ status }}</div>
    <div class="treebox">
      <div class="troot">{{ hero }}</div>
      <div class="trow">{{ r1 }}</div>
      <div class="trow">{{ r2 }}</div>
      <div class="trow">{{ r3 }}</div>
      <div class="trow">{{ r4 }}</div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">JUDGE</button>
      <button class="btn" bindtap="act2Tap">PICK</button>
      <button class="btn" bindtap="act3Tap">WARD</button>
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
.status { color: #ffffff; font-size: 11px; line-height: 15px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 6px; }
.btn { flex: 1; margin-right: 6px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 13px; padding: 5px 0; text-align: center; }
.btnrow .btn:last-child { margin-right: 0; }
.btn-main { background-color: #14541f; color: #ffffff; font-weight: bold; }
.guide { color: rgba(64,255,94,0.62); font-size: 10px; line-height: 13px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.rline { color: #ffffff; font-size: 12px; line-height: 16px; margin-top: 3px; white-space: nowrap; overflow: hidden; }
.dim { color: rgba(255,255,255,0.75); }
.center { text-align: center; }
.mono { font-family: monospace; }
.heroline { color: #40ff5e; font-size: 16px; font-weight: bold; line-height: 21px; margin-top: 5px; white-space: nowrap; overflow: hidden; }
.foot { position: absolute; left: 14px; top: 322px; width: 350px; color: rgba(64,255,94,0.66); font-family: monospace; font-size: 9px; line-height: 12px; white-space: nowrap; overflow: hidden; }
.demobtn { position: absolute; left: 388px; top: 312px; width: 78px; height: 28px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.72); font-size: 12px; text-align: center; }

.treebox { margin-top: 8px; border: 1px solid rgba(64,255,94,0.24); padding: 8px 12px; }
.troot { color: #40ff5e; font-size: 16px; font-weight: bold; }
.trow { color: #ffffff; font-size: 13px; line-height: 21px; margin-left: 18px; white-space: nowrap; overflow: hidden; }
</style>
