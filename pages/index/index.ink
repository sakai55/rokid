<script def>
{
  "title": "Taxfree Ledger"
}
</script>

<script setup>
import wx from 'wx';

// JP11 Taxfree Ledger - 免税账本 Taxfree Ledger
// Local anchor: 日本免税购物（Tax Free）是外国游客在店内当场适用的制度：同一店铺同一天购物满线才能免税，消耗品必须装进密封袋且在...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const STORES = ['ドラッグストア','百貨店','家電量販店'];
const DEMO_S = [{"store": 0, "gen": 3200, "con": 1800, "sealed": false, "done": 0}, {"store": 1, "gen": 0, "con": 7200, "sealed": true, "done": 1}, {"store": 2, "gen": 6800, "con": 5400, "sealed": true, "done": 2}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"store": 0, "gen": 0, "con": 0, "sealed": false, "done": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _total() { return this._s.gen + this._s.con; },
  _nodAction() { this._sealOrSpeak(); },
  _swipe(dir) {
    this.setData({ evt: 'EVT: swipe - 集計は店舗ごと、スワイプでは変わりません' });
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    this._sealOrSpeak();
  },
  _sealOrSpeak() {
    const s = this._s;
    if (this._total() >= 5000 && !s.sealed) {
      s.sealed = true;
      this._speak('密封袋を閉じました。日本国内では開けないでください。');
      this.setData({ evt: 'EVT: sealed - do not open in Japan' });
    } else {
      this.speakTap();
    }
    this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (this._total() >= 5000) s.done++;
    s.store = (s.store + 1) % 3; s.gen = 0; s.con = 0; s.sealed = false;
    this.setData({ evt: 'EVT: next store -> ' + STORES[s.store] });
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.con += 1000;
    this.setData({ evt: 'EVT: consumables +1000' });
    this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s.gen += 1000;
    this.setData({ evt: 'EVT: general goods +1000' });
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const total = this._total();
    const rem = Math.max(0, 5000 - total);
    const t = total >= 5000
      ? (STORES[s.store] + '、合計' + total + '円、ライン達成です。密封袋は' + (s.sealed ? '閉じています。' : 'まだ閉じていません。'))
      : (STORES[s.store] + '、合計' + total + '円、あと' + rem + '円でライン達成です。');
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'ledger spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    const total = this._total();
    const rem = Math.max(0, 5000 - total);
    const filled = Math.min(20, Math.round(total / 5000 * 20));
    let bar = '';
    for (let i = 0; i < 20; i++) bar += (i < filled ? '█' : '░');
    this.setData({
      status: total >= 5000 ? ('TAXFREE: ' + STORES[s.store] + ' · 5,000円ライン達成 — 密封してから店を出てください') : ('TAXFREE: ' + STORES[s.store] + ' · あと' + rem + '円でライン達成'),
      hero: '¥' + total,
      heroSub: STORES[s.store] + ' · パスポートは店頭で提示（自己申告）',
      r1: '一般物品 ¥' + s.gen + ' · 消耗品 ¥' + s.con,
      r2: '密封袋：' + (s.sealed ? '閉じた — 国内で開封禁止' : '未密封 — ライン達成後に閉じる'),
      r3: '達成店舗 ' + s.done + '店 · 1店舗1日ごとに集計',
      r4: '消耗品は密封袋のまま日本国外へ持ち出すこと · 最終判断は店舗のレジです',
      marks: bar,
      guide: 'STORE 次の店 · CON+1000 消耗品追加 · GEN+1000 一般物品追加 · GO=密封/読み上げ · うなずき=密封'
    });
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
    <div class="ttl">TAXFREE LEDGER</div>
    <div class="status">{{ status }}</div>
    <div class="passbook">
      <div class="passrow">{{ marks }}</div>
      <div class="passline">{{ r1 }}</div>
      <div class="passline">{{ r2 }}</div>
      <div class="passline">{{ r3 }}</div>
    </div>
    <div class="heroline">{{ hero }}<span class="tsub">{{ heroSub }}</span></div>
    <div class="rline dim">{{ r4 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">STORE</button>
      <button class="btn" bindtap="act2Tap">CON+1000</button>
      <button class="btn" bindtap="act3Tap">GEN+1000</button>
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

.passbook { border: 2px double rgba(64,255,94,0.7); padding: 10px 12px; margin-top: 8px; }
.passrow { color: #40ff5e; font-family: monospace; font-size: 17px; letter-spacing: 1px; white-space: nowrap; overflow: hidden; }
.passline { color: #7dff9e; font-size: 13px; line-height: 20px; white-space: nowrap; overflow: hidden; }
.btn { border: 2px double rgba(64,255,94,0.85); background-color: #0d2812; border-radius: 3px; padding: 7px 0; letter-spacing: 1px; }
.btn-main { background-color: #14541f; border-color: #7dff9e; }
.demobtn { border: 2px double rgba(64,255,94,0.85); border-radius: 3px; }
</style>
