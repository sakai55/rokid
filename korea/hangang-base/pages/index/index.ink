<script def>
{
  "title": "Hangang Base"
}
</script>

<script setup>
import wx from 'wx';

// KR05 Hangang Base - 营地持有 Basecamp Holder
// Local anchor: 周末的한강공원（汉江公园）有一套成熟玩法：铺돗자리（垫子）占位、点外卖到指定交付点自取、吃完把垫子与垃圾按规矩收走。营地...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const CODES = ['여의나루 3번', '뚝섬 1번', '반포 달빛광장'];
const CLEAN = ['돗자리 털기', '쓰레기 분리', '음식물 모으기', '페트 압축'];
const DEMO_S = [{"code": 1, "food": 7, "clean": 0, "focus": 1}, {"code": 1, "food": 7, "clean": 2, "focus": 3}, {"code": 1, "food": 7, "clean": 4, "focus": 3}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"code": 0, "food": 0, "clean": 0, "focus": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _cells() {
    const s = this._s;
    return [
      '交付点\n' + CODES[s.code],
      '取餐号\n' + (s.food === 0 ? '未登记' : ('A-' + s.food)),
      '垫子归还\n21:30 まで',
      '片付け\n' + s.clean + '/4 ' + (s.clean < 4 ? CLEAN[s.clean] : '完了')
    ];
  },
  _nodAction() { this.goTap(); },
  _swipe(dir) { this._s.focus = Math.max(0, Math.min(3, this._s.focus + dir)); this.setData({ evt: 'EVT: focus cell ' + (this._s.focus + 1) }); this._recompute(); },
  goTap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    const cells = this._cells();
    const ok = this._speak(cells[s.focus].replace('\n', ' '));
    s.focus = (s.focus + 1) % 4;
    this.setData({ evt: 'EVT: GO read cell aloud ' + (ok ? '' : '(FAIL)') }); this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    this._s.code = (this._s.code + 1) % CODES.length;
    this._speak('交付点는 ' + CODES[this._s.code] + '예요。');
    this.setData({ evt: 'EVT: delivery point -> ' + CODES[this._s.code] }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.food++;
    this.setData({ evt: 'EVT: pickup number A-' + this._s.food }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.clean < 4) { this._speak(CLEAN[s.clean] + ' 완료。'); s.clean++; }
    this.setData({ evt: 'EVT: cleanup ' + s.clean + '/4' }); this._recompute();
  },
  speakTap() {
    const cells = this._cells();
    const ok = this._speak(cells.join('。'));
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'all four cells' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const c = this._cells();
    this.setData({
      status: 'BASE: 한강 베이스캠프 · 焦点は格 ' + (s.focus + 1) + '/4',
      hero: s.clean >= 4 ? '片付け完了 — 좋은 하루였어요' : '营地は私が見ています',
      heroSub: '', r1: c[0], r2: c[1], r3: c[2], r4: c[3], marks: '',
      guide: 'CODE 交付点 · FOOD# 取餐号 · CLEAN 片付け · GO 逐格播报'
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
    <div class="ttl">HANGANG BASE</div>
    <div class="status">{{ status }}</div>
    <div class="matrow">
      <div class="matcell">{{ r1 }}</div>
      <div class="matcell">{{ r2 }}</div>
    </div>
    <div class="matrow">
      <div class="matcell">{{ r3 }}</div>
      <div class="matcell">{{ r4 }}</div>
    </div>
    <div class="heroline">{{ hero }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">CODE</button>
      <button class="btn" bindtap="act2Tap">FOOD#</button>
      <button class="btn" bindtap="act3Tap">CLEAN</button>
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

.matrow { display: flex; flex-direction: row; margin-top: 6px; }
.matcell { flex: 1; margin-right: 6px; border: 1px solid rgba(64,255,94,0.55); color: #ffffff; font-size: 12px; line-height: 16px; padding: 7px 8px; height: 52px; box-sizing: border-box; overflow: hidden; }
.matrow .matcell:last-child { margin-right: 0; }
</style>
