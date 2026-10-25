<script def>
{
  "title": "Coin Locker"
}
</script>

<script setup>
import wx from 'wx';

// JP05 Coin Locker - 寄存格账本 Locker Ledger
// Local anchor: 日本车站的コインロッカー是旅行与通勤的基础设施：大站按大中小分柜、Suica 或现金开锁、超时按日加算、三日无人取走移交...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const NOS = ['A-03', 'B-12', 'C-27'];
const ITEMS = ['スーツケース', '土産袋', 'コート'];
const DEMO_S = [{"noIdx": 1, "itemIdx": 0, "stored": false, "taken": false}, {"noIdx": 1, "itemIdx": 0, "stored": true, "taken": false}, {"noIdx": 1, "itemIdx": 0, "stored": true, "taken": true}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"noIdx": 1, "itemIdx": 0, "stored": false, "taken": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { if (this._s.stored && !this._s.taken) this.act3Tap(); else this.act1Tap(); },
  _swipe(dir) { const s = this._s; if (s.stored) { this.setData({ evt: 'EVT: swipe ignored (stored)' }); return; } s.noIdx = Math.max(0, Math.min(2, s.noIdx + dir)); this.setData({ evt: 'EVT: swipe -> locker ' + NOS[s.noIdx] }); this._recompute(); },
  goTap() { if (this._demoIdx >= 0) return; this._nodAction(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.taken) { s.taken = false; this.setData({ evt: 'EVT: new session' }); this._recompute(); return; }
    if (s.stored) { this.setData({ evt: 'EVT: already stored' }); this._recompute(); return; }
    s.stored = true;
    this._speak('預けました。ロッカーは ' + NOS[s.noIdx] + '、中身は ' + ITEMS[s.itemIdx] + ' です。');
    this.setData({ evt: 'EVT: STORE ' + NOS[s.noIdx] }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.stored) { this.setData({ evt: 'EVT: item locked while stored' }); this._recompute(); return; }
    s.itemIdx = (s.itemIdx + 1) % ITEMS.length;
    this.setData({ evt: 'EVT: item -> ' + ITEMS[s.itemIdx] }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (!s.stored || s.taken) { this.setData({ evt: 'EVT: nothing to take' }); this._recompute(); return; }
    s.taken = true;
    this._speak('中身は ' + ITEMS[s.itemIdx] + ' です。確認して取り出してください。');
    this.setData({ evt: 'EVT: TAKE verify ' + NOS[s.noIdx] }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const msg = s.taken ? '取り出し完了しています。' : (s.stored ? ('ロッカー ' + NOS[s.noIdx] + ' に ' + ITEMS[s.itemIdx] + ' を預けています。') : 'まだ預けていません。');
    const ok = this._speak(msg);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'summary' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const marks = NOS.map((n, i) => i === s.noIdx ? '【' + n + '】' : ' ' + n + ' ').join(' ');
    this.setData({
      status: s.taken ? 'DONE: 受け取り完了 · ' + NOS[s.noIdx] : (s.stored ? 'STORED: ' + NOS[s.noIdx] + ' · ' + ITEMS[s.itemIdx] : 'EMPTY: ロッカーを選んで STORE'),
      hero: s.taken ? '受け取り完了' : (s.stored ? NOS[s.noIdx] + ' 預け中' : NOS[s.noIdx]),
      heroSub: '',
      r1: '中身：' + ITEMS[s.itemIdx] + (s.stored ? '（固定）' : '（ITEM で切替）'),
      r2: '場所：新宿駅 西口ロッカー街 · 24時を過ぎると 1 日分加算（目安）',
      r3: '', r4: '', marks: marks,
      guide: 'STORE 預ける · ITEM 中身を替える · TAKE 受け取り確認 · うなずき=文脈アクション（預ける/受け取る）'
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
    <div class="ttl">COIN LOCKER</div>
    <div class="status">{{ status }}</div>
    <div class="lockbank"><div class="lockmarks">{{ marks }}</div></div>
    <div class="heroline center">{{ hero }}</div>
    <div class="rline center">{{ r1 }}</div>
    <div class="rline center dim">{{ r2 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">STORE</button>
      <button class="btn" bindtap="act2Tap">ITEM</button>
      <button class="btn" bindtap="act3Tap">TAKE</button>
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

.lockbank { border: 2px solid rgba(64,255,94,0.55); padding: 12px 8px; margin-top: 10px; }
.lockmarks { color: #40ff5e; font-family: monospace; font-size: 17px; letter-spacing: 2px; text-align: center; white-space: nowrap; overflow: hidden; }
.btn { border: 2px solid rgba(64,255,94,0.8); border-radius: 3px; background-color: #0d2812; letter-spacing: 2px; padding: 7px 0; }
.btn-main { background-color: #14541f; border-color: #7dff9e; }
.demobtn { border: 2px solid rgba(64,255,94,0.8); border-radius: 3px; }
</style>
