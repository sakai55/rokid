<script def>
{
  "title": "Nomikai Kanji"
}
</script>

<script setup>
import wx from 'wx';

// JP08 Nomikai Kanji - 干事账簿 Host Ledger
// Local anchor: 日本の飲み会里，幹事（组织者）是最操心的角色：数人头、控节奏、算割り勘（还要照顾到100円単位的凑整礼仪）、盯終電。干事...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const TRAIN_PRESETS = [75, 47, 18];
const DEMO_S = [{"people": 6, "items": 5, "total": 18800, "trainMin": 47, "settled": false}, {"people": 6, "items": 8, "total": 22400, "trainMin": 19, "settled": false}, {"people": 6, "items": 8, "total": 22400, "trainMin": 12, "settled": true}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"people": 4, "items": 3, "total": 12800, "trainMin": 47, "settled": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _per() { const s = this._s; return Math.ceil(s.total / Math.max(1, s.people) / 100) * 100; },
  _nodAction() {
    if (this._demoIdx >= 0) return;
    this._s.settled = true;
    this._speak('割り勘は一人 ' + this._per() + ' 円です。');
    this.setData({ evt: 'EVT: nod -> settlement confirmed' }); this._recompute();
  },
  _swipe(dir) {
    const s = this._s;
    if (dir < 0 && s.people > 2) s.people--;
    if (dir > 0 && s.people < 12) s.people++;
    this.setData({ evt: 'EVT: swipe -> people ' + s.people }); this._recompute();
  },
  goTap() { if (this._demoIdx >= 0) return; this.speakTap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s; s.items++; s.total += 1200; s.settled = false;
    this.setData({ evt: 'EVT: +1 item ¥1,200 -> total ¥' + s.total }); this._recompute();
  },
  act2Tap() { if (this._demoIdx >= 0) return; this._swipe(1); },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    const i = TRAIN_PRESETS.indexOf(s.trainMin);
    s.trainMin = TRAIN_PRESETS[(i + 1) % TRAIN_PRESETS.length];
    this._speak('終電まで ' + s.trainMin + ' 分に設定しました。');
    this.setData({ evt: 'EVT: last-train preset -> ' + s.trainMin + ' min' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak('現在 ' + s.people + ' 名、合計 ' + s.total + ' 円。一人 ' + this._per() + ' 円。終電まで ' + s.trainMin + ' 分です。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'ledger summary' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    this.setData({
      status: s.settled ? 'SETTLED: 割り勘確定 — 一人 ¥' + this._per() : 'KANJI: 幹事の帳簿 · 録音・転写は一切しません',
      hero: '終電 ' + s.trainMin + '分', heroSub: 'あと ' + s.trainMin + ' 分で終電（プリセット）',
      r1: '人数 ' + s.people + ' 名 · 注文 ' + s.items + ' 品',
      r2: '合計 ¥' + s.total,
      r3: '割り勘 一人 ¥' + this._per() + '（100円単位で切上）',
      r4: '', marks: '',
      guide: '+ITEM 加品 · +PERSON 加人（下滑减） · TRAIN 换终电档 · 点头=结算'
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
    <div class="ttl">NOMIKAI KANJI</div>
    <div class="status">{{ status }}</div>
    <div class="slipbox">
      <div class="srow2"><span>{{ r1 }}</span></div>
      <div class="srow2"><span>{{ r2 }}</span></div>
      <div class="srow2"><span>{{ r3 }}</span></div>
      <div class="cdline">{{ hero }}</div>
      <div class="rline dim">{{ heroSub }}</div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">+ITEM</button>
      <button class="btn" bindtap="act2Tap">+PERSON</button>
      <button class="btn" bindtap="act3Tap">TRAIN</button>
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

.slipbox { margin-top: 8px; border: 1px solid rgba(64,255,94,0.48); padding: 8px 12px; }
.srow2 { color: #ffffff; font-size: 13px; line-height: 20px; text-align: right; white-space: nowrap; overflow: hidden; }
.cdline { color: #40ff5e; font-family: monospace; font-size: 26px; font-weight: bold; text-align: center; margin-top: 4px; }
</style>
