<script def>
{
  "title": "Bosai Kit"
}
</script>

<script setup>
import wx from 'wx';

// JP04 Bosai Kit - 榻榻米覆盖格 Coverage Grid
// Local anchor: 日本家庭的防灾（防災）不是可选项：各自治体都发防災手册，超市有专门的防灾货架，防灾包讲究「备齐 + 没过期」。水、非常食...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const CATS = ['水 2L', '非常食', '懐中電灯', 'ラジオ', 'モバイル電源', '常備薬', '軍手', 'ホイッスル'];
const SCAN_MODE = 'telephoto';
const SCAN_SYSTEM = '只输出照片中食品或药品的有效期年月（如 2027年3月），读不到输出 NONE，不要解释。';
const SCAN_QUESTION = '这张包装照片上的有效期是哪一年哪一月？只输出年月，读不到输出 NONE。';
const DEMO_S = [{"st": [1, 1, 0, 0, 0, 0, 0, 0], "idx": 2, "note": "-"}, {"st": [1, 1, 1, 1, 2, 0, 0, 0], "idx": 5, "note": "常備薬 2026年9月（暫定）"}, {"st": [1, 1, 1, 1, 2, 1, 1, 1], "idx": 7, "note": "常備薬 2026年9月（暫定）"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"st": [0, 0, 0, 0, 0, 0, 0, 0], "idx": 0, "note": "-"};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this._s.idx = Math.max(0, Math.min(7, this._s.idx + dir)); this.setData({ evt: 'EVT: swipe -> cell ' + (this._s.idx + 1) }); this._recompute(); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.st[s.idx] = 1;
    let nxt = s.idx + 1; while (nxt < 8 && s.st[nxt] !== 0) nxt++;
    if (nxt < 8) s.idx = nxt;
    const left = s.st.filter((v) => v === 0).length;
    this._speak(left === 0 ? '点検完了です。' : ('あと ' + left + ' 品目です。'));
    this.setData({ evt: 'EVT: OK cell -> ' + CATS[s.idx] }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.st[s.idx] = (s.st[s.idx] === 2 ? 0 : 2);
    this._speak('要確認として記録しました。');
    this.setData({ evt: 'EVT: FLAG toggled on ' + CATS[s.idx] }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s = { st: [0, 0, 0, 0, 0, 0, 0, 0], idx: 0, note: '-' };
    this.setData({ evt: 'EVT: grid reset' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const left = s.st.filter((v) => v === 0).length;
    const flags = s.st.filter((v) => v === 2).length;
    const ok = this._speak('未点検 ' + left + '、要確認 ' + flags + ' です。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'summary' : 'FAIL') }); this._recompute();
  },
  _scanNote(msg) { this.setData({ evt: 'EVT: ' + msg }); },
  _scanAnswer(ans) {
    const s = this._s;
    if (ans && ans !== 'NONE' && /\d{4}/.test(ans)) { s.note = CATS[s.idx] + ' ' + ans.slice(0, 12) + '（暫定）'; this._speak('期限を読みました。包装の原文と比べてください。'); }
    else s.note = '期限 読めず（手動確認を）';
    this.setData({ evt: 'EVT: SCAN date tentative for ' + CATS[s.idx] }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const marks = s.st.map((v) => v === 1 ? '●' : (v === 2 ? '△' : '○')).join(' ');
    const done = s.st.filter((v) => v !== 0).length;
    const flags = CATS.filter((c, i) => s.st[i] === 2);
    this.setData({
      status: done === 8 ? 'DONE: 8/8 点検完了' + (flags.length ? '（要確認：' + flags.join('・') + '）' : '') : 'CHECK: ' + done + '/8 · 現在 ' + CATS[s.idx],
      hero: '点検 ' + done + '/8', heroSub: '',
      r1: '現在：' + CATS[s.idx] + ' — 在庫と期限を見て OK / FLAG',
      r2: '期限メモ：' + s.note,
      r3: '', r4: '', marks: marks,
      guide: 'OK 查过 · FLAG 过期/待换 · SCAN 拍期限（暂定） · 点头=OK'
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
    <div class="ttl">BOSAI KIT</div>
    <div class="status">{{ status }}</div>
    <div class="gridbox"><div class="gridmarks">{{ marks }}</div></div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="heroline">{{ hero }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">OK</button>
      <button class="btn" bindtap="act2Tap">FLAG</button>
      <button class="btn" bindtap="act3Tap">RESET</button>
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

.gridbox { border: 1px solid rgba(64,255,94,0.48); padding: 10px; margin-top: 8px; text-align: center; }
.gridmarks { color: #40ff5e; font-family: monospace; font-size: 21px; line-height: 28px; letter-spacing: 3px; }
</style>
