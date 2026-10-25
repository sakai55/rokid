<script def>
{
  "title": "Omiyage Cover"
}
</script>

<script setup>
import wx from 'wx';

// JP09 Omiyage Cover - 人情覆盖 Obligation Grid
// Local anchor: 日本出差与旅行归来，お土産不是随手礼，是义务：上司、同组同事一个不能漏，漏掉谁比买错什么更失礼。买的时候在店里最慌的就是...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const PEOPLE = ['田中部長', '佐藤課長', '鈴木さん', '高橋さん', '伊藤さん', '渡辺さん'];
const SCAN_MODE = 'wide';
const SCAN_SYSTEM = '写真にギフトボックスまたはそのバーコードが見えるかだけ答えてください。あれば BOX、なければ NONE と出力し、説明は不要です。';
const SCAN_QUESTION = 'この写真にギフトボックスまたはそのバーコードはありますか？あれば BOX だけ、なければ NONE だけを出力してください。';
const DEMO_S = [{"st": [1, 1, 0, 0, 0, 0], "idx": 2, "boxes": 1}, {"st": [1, 1, 1, 2, 0, 0], "idx": 4, "boxes": 0}, {"st": [1, 1, 1, 1, 1, 1], "idx": 5, "boxes": 0}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"st": [0, 0, 0, 0, 0, 0], "idx": 0, "boxes": 2};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this._s.idx = Math.max(0, Math.min(5, this._s.idx + dir)); this.setData({ evt: 'EVT: swipe -> ' + PEOPLE[this._s.idx] }); this._recompute(); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.st[s.idx] === 1) { this.setData({ evt: 'EVT: already covered' }); this._recompute(); return; }
    if (s.boxes <= 0) { s.st[s.idx] = 2; this._speak('在庫がありません。後でに記録しました。'); this.setData({ evt: 'EVT: no stock -> marked LATER honestly' }); this._recompute(); return; }
    s.st[s.idx] = 1; s.boxes--;
    let nxt = s.idx + 1; while (nxt < 6 && s.st[nxt] === 1) nxt++;
    if (nxt < 6) s.idx = nxt;
    const n = s.st.filter((v) => v === 1).length;
    this._speak(n === 6 ? '全員分そろいました。' : ('あと ' + (6 - n) + ' 名分です。'));
    this.setData({ evt: 'EVT: BOUGHT for ' + PEOPLE[s.idx] }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.st[s.idx] = (s.st[s.idx] === 2 ? 0 : 2);
    this.setData({ evt: 'EVT: LATER toggled for ' + PEOPLE[s.idx] }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s.boxes++;
    this.setData({ evt: 'EVT: stock +1 -> ' + this._s.boxes }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const n = s.st.filter((v) => v === 1).length;
    const later = PEOPLE.filter((p, i) => s.st[i] === 2);
    const ok = this._speak(n + ' 名分購入済み。在庫 ' + s.boxes + '。' + (later.length ? ('後では ' + later.join('、') + ' です。') : ''));
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'summary' : 'FAIL') }); this._recompute();
  },
  _scanNote(msg) { this.setData({ evt: 'EVT: ' + msg }); },
  _scanAnswer(ans) {
    if (ans && ans.indexOf('BOX') >= 0) { this._s.boxes++; this._speak('箱を一つ数えました。'); this.setData({ evt: 'EVT: SCAN box +1 stock (tentative)' }); }
    else this.setData({ evt: 'EVT: SCAN no box seen - stock unchanged' });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    const marks = s.st.map((v) => v === 1 ? '✓' : (v === 2 ? '△' : '·')).join(' ');
    const n = s.st.filter((v) => v === 1).length;
    this.setData({
      status: n === 6 ? 'DONE: 全員分 6/6 — 人情は果たした' : 'GIFTS: ' + n + '/6 · 現在 ' + PEOPLE[s.idx] + ' 様分',
      hero: '覆盖 ' + n + '/6 名', heroSub: '',
      r1: '現在：' + PEOPLE[s.idx] + ' 様分 — ' + (s.st[s.idx] === 1 ? '購入済 ✓' : (s.st[s.idx] === 2 ? '後で △（未購入）' : '未購入')),
      r2: '礼盒在庫 ' + s.boxes + ' 箱 · BOUGHTは在庫から1箱使う',
      r3: '', r4: '', marks: marks,
      guide: 'BOUGHT 一人分を消し込み · LATER 後回し · STOCK/SCAN 在庫を足す · うなずき=BOUGHT'
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
    <div class="ttl">OMIYAGE COVER</div>
    <div class="status">{{ status }}</div>
    <div class="gridbox"><div class="gridmarks">{{ marks }}</div></div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="heroline">{{ hero }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">BOUGHT</button>
      <button class="btn" bindtap="act2Tap">LATER</button>
      <button class="btn" bindtap="act3Tap">STOCK</button>
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

.gridbox { border: 1px solid rgba(64,255,94,0.48); padding: 10px; margin-top: 8px; text-align: center; }
.gridmarks { color: #40ff5e; font-family: monospace; font-size: 21px; line-height: 28px; letter-spacing: 3px; }
.btn { border: 2px solid rgba(64,255,94,0.85); background-color: #0d2812; border-radius: 0; padding: 9px 0; letter-spacing: 1px; }
.btn-main { background-color: #14541f; border-color: #7dff9e; }
.demobtn { border: 2px solid rgba(64,255,94,0.85); border-radius: 0; }
.btn { border-style: dashed; }
.btn-main { border-style: dashed; }
.demobtn { border-style: dashed; }
.gridbox { border-style: dashed; }
.gridmarks { font-size: 19px; letter-spacing: 5px; }
</style>
