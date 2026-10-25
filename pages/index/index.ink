<script def>
{
  "title": "Kaiten Tally"
}
</script>

<script setup>
import wx from 'wx';

// JP12 Kaiten Tally - 传送带盘数 Conveyor Tally
// Local anchor: 回转寿司（回転寿司）的价格按盘子颜色定：不同颜色对应不同单价，吃完把盘子摞起来，店员数盘结账。最容易乱的是「到底吃了几盘...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const PRICE = [110, 220, 330];
const DEMO_S = [{"w": 2, "r": 1, "b": 0, "checked": false}, {"w": 3, "r": 2, "b": 1, "checked": false}, {"w": 4, "r": 3, "b": 2, "checked": true}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"w": 0, "r": 0, "b": 0, "checked": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _totals() {
    const s = this._s;
    const plates = s.w + s.r + s.b;
    const total = s.w * 110 + s.r * 220 + s.b * 330;
    return { plates: plates, total: total };
  },
  _nodAction() { this.act1Tap(); },
  _swipe(dir) {
    this.setData({ evt: 'EVT: swipe - 皿の色はボタンで追加します' });
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    const t = this._totals();
    if (!s.checked) {
      s.checked = true;
      this._speak('お会計は' + t.total + '円、' + t.plates + '皿です。');
      this.setData({ evt: 'EVT: bill locked' });
    } else {
      s.w = 0; s.r = 0; s.b = 0; s.checked = false;
      this.setData({ evt: 'EVT: new table - tally cleared' });
    }
    this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0 || this._s.checked) return;
    this._s.w++;
    this.setData({ evt: 'EVT: white +1' });
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0 || this._s.checked) return;
    this._s.r++;
    this.setData({ evt: 'EVT: red +1' });
    this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0 || this._s.checked) return;
    this._s.b++;
    this.setData({ evt: 'EVT: black +1' });
    this._recompute();
  },
  speakTap() {
    const t = this._totals();
    const ok = this._speak('合計' + t.total + '円、' + t.plates + '皿です。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'tally spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    const t = this._totals();
    let belt = '';
    for (let i = 0; i < t.plates; i++) belt += '○';
    if (t.plates === 0) belt = 'まだ皿はありません';
    this.setData({
      status: s.checked ? ('CHECK: お会計 ¥' + t.total + ' · ' + t.plates + '皿 — GOで新しいテーブルへ') : ('EAT: ' + t.plates + '皿 · 合計 ¥' + t.total),
      hero: '¥' + t.total,
      heroSub: t.plates + '皿 · 白110/赤220/黒330',
      r1: '白110 ×' + s.w + ' · 赤220 ×' + s.r,
      r2: '黒330 ×' + s.b + ' · 合計 ' + t.plates + '皿',
      r3: s.checked ? 'お会計済み — GOでリセット' : 'ラストオーダーは店員に直接確認してください',
      r4: '',
      marks: belt,
      guide: 'WHITE 白110追加 · RED 赤220追加 · BLACK 黒330追加 · GO=お会計 · うなずき=白110追加'
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
    <div class="ttl">KAITEN TALLY</div>
    <div class="status">{{ status }}</div>
    <div class="belt">{{ marks }}</div>
    <div class="heroline">{{ hero }}<span class="tsub">{{ heroSub }}</span></div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="rline dim">{{ r3 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">WHITE</button>
      <button class="btn" bindtap="act2Tap">RED</button>
      <button class="btn" bindtap="act3Tap">BLACK</button>
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

.belt { border-top: 3px double rgba(64,255,94,0.7); border-bottom: 3px double rgba(64,255,94,0.7); padding: 6px 0; margin-top: 10px; color: #40ff5e; font-family: monospace; font-size: 16px; letter-spacing: 2px; text-align: center; white-space: nowrap; overflow: hidden; }
.btn { border: 4px double #40ff5e; border-radius: 6px; background-color: transparent; padding: 7px 0; font-weight: bold; }
.btn-main { background-color: #0d2812; border-color: #7dff9e; }
.demobtn { border: 4px double #40ff5e; border-radius: 6px; }
</style>
