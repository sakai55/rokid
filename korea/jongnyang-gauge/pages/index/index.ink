<script def>
{
  "title": "Jongnyang Gauge"
}
</script>

<script setup>
import wx from 'wx';

// KR04 Jongnyang Gauge - 计量表 Volume Gauge
// Local anchor: 韩国的종량제（垃圾计量收费制）是把垃圾变成钱的制度：一般垃圾必须装进付费的标准化计量袋（종량제 봉투），食物垃圾（음식물...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.

const SCAN_MODE = 'wide';
const SCAN_SYSTEM = '只回答照片里计量垃圾袋包装上印的容量数字（如 20L），读不到输出 NONE，不要解释。';
const SCAN_QUESTION = '这张照片里的종량제 봉투（计量垃圾袋）包装上印的容量是几升？只输出数字加L，读不到输出 NONE。';
const DEMO_S = [{"cap": 20, "filled": 9, "food": 1, "bags": 0, "note": ""}, {"cap": 20, "filled": 17, "food": 3, "bags": 0, "note": "80% 경고"}, {"cap": 20, "filled": 0, "food": 3, "bags": 1, "note": "새 봉투"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"cap": 20, "filled": 0, "food": 0, "bags": 0, "note": ""};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - log with +1L / FOOD' }); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.filled >= s.cap) { this._speak('이미 가득 찼어요。THROW로 배출해요。'); this.setData({ evt: 'EVT: bag full - add refused honestly' }); this._recompute(); return; }
    s.filled++;
    if (s.filled === Math.floor(s.cap * 0.8)) { s.note = '80% 경고'; this._speak('곧 가득 차요。'); }
    this.setData({ evt: 'EVT: +1L -> ' + s.filled + '/' + s.cap + 'L' }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.food++;
    this._speak('음식물 0.5킬로目安으로 기록했어요。');
    this.setData({ evt: 'EVT: food drop logged (0.5kg est.)' }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.filled === 0) { this.setData({ evt: 'EVT: empty bag - nothing to throw' }); this._recompute(); return; }
    s.bags++; s.filled = 0; s.note = '새 봉투';
    this._speak('배출했어요。새 봉투예요。');
    this.setData({ evt: 'EVT: THROW - bag #' + s.bags + ' sealed' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak('봉투는 ' + s.filled + '리터 찼고, 음식물은 ' + s.food + '번 버렸어요。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'ledger' : 'FAIL') }); this._recompute();
  },
  _scanNote(msg) { this._s.note = msg; this.setData({ evt: 'EVT: ' + msg }); },
  _scanAnswer(ans) {
    const m = String(ans || '').match(/(10|20|30|50)\s*L/i);
    if (m) { this._s.cap = parseInt(m[1], 10); this._s.note = '袋型 ' + m[1] + 'L（暫定読取）'; this._speak('봉투 크기를 바꿨어요。'); }
    else this._s.note = '容量 読めず — 手動のまま';
    this.setData({ evt: 'EVT: SCAN bag size tentative' }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const rows = 8;
    const filledRows = Math.round(s.filled / s.cap * rows);
    let g = '';
    for (let i = rows - 1; i >= 0; i--) { g += (i < filledRows ? '█████' : '░░░░░') + (i > 0 ? '\n' : ''); }
    const fee = s.food * 60;
    this.setData({
      status: 'BAG: ' + s.cap + 'L 종량제 · 배출済み ' + s.bags + ' 袋' + (s.note ? ' · ' + s.note : ''),
      hero: 'あと ' + (s.cap - s.filled) + 'L 入ります', heroSub: '',
      r1: '現在 ' + s.filled + '/' + s.cap + 'L（' + Math.round(s.filled / s.cap * 100) + '%）',
      r2: '음식물 ' + s.food + ' 回 · 料金目安 約 ' + fee + '원（推定）',
      r3: '満杯では +1L 不可 — 正直な量表', r4: '', marks: g,
      guide: '+1L 逐升 · FOOD 食物投放 · THROW 封袋排出 · SCAN 袋型（暂定）'
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
    <div class="ttl">JONGNYANG GAUGE</div>
    <div class="status">{{ status }}</div>
    <div class="gaugewrap">
      <div class="gaugecol">{{ marks }}</div>
      <div class="gaugeside"><div class="heroline">{{ hero }}</div><div class="rline">{{ r1 }}</div><div class="rline">{{ r2 }}</div><div class="rline dim">{{ r3 }}</div></div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">+1L</button>
      <button class="btn" bindtap="act2Tap">FOOD</button>
      <button class="btn" bindtap="act3Tap">THROW</button>
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

.gaugewrap { display: flex; flex-direction: row; margin-top: 8px; }
.gaugecol { width: 96px; box-sizing: border-box; color: #40ff5e; font-family: monospace; font-size: 15px; line-height: 19px; border: 1px solid rgba(64,255,94,0.48); padding: 6px 10px; white-space: pre; }
.gaugeside { flex: 1; margin-left: 14px; min-width: 0; }
.btn { font-family: monospace; background-color: #0d2812; border: none; border-left: 5px solid #40ff5e; text-align: left; padding: 6px 0 6px 10px; }
.btn-main { border-left-color: #7dff9e; background-color: #14541f; }
.demobtn { font-family: monospace; background-color: #0d2812; border: none; border-left: 5px solid #40ff5e; }
</style>
