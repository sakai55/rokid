<script def>
{
  "title": "Deungsan Pace"
}
</script>

<script setup>
import wx from 'wx';

// KR06 Deungsan Pace - 海拔配速 Elevation Pace
// Local anchor: 등산（登山）是韩国的全民周末仪式：북한산、관악산周末人满为患，山友文化讲究配速与补水，下山伤膝更是常识。山里最容易失守的...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.

const DEMO_S = [{"prog": 3, "rests": 1, "water": 2, "alt": 342, "mins": 55}, {"prog": 5, "rests": 2, "water": 2, "alt": 517, "mins": 95}, {"prog": 8, "rests": 3, "water": 4, "alt": 836, "mins": 150}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"prog": 0, "rests": 0, "water": 0, "alt": null, "mins": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.goTap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - segments advance by GO' }); },
  goTap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.prog < 8) { s.prog++; s.mins += 18; this._speak(s.prog >= 8 ? '정상입니다。하산 페이스도 지켜요。' : (s.prog + '구간째예요。')); }
    this.setData({ evt: 'EVT: segment ' + s.prog + '/8' }); this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    this._s.rests++;
    this._speak('쉬는 것도 페이스예요。');
    this.setData({ evt: 'EVT: rest logged ' + this._s.rests }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.water++;
    this.setData({ evt: 'EVT: water logged ' + this._s.water + ' cups' }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const self = this;
    try {
      if (typeof navigator === 'undefined' || !navigator.geolocation) { this.setData({ evt: 'EVT: GEO SKIP - unavailable' }); return; }
      navigator.geolocation.getCurrentPosition((p) => {
        const c = p && p.coords ? p.coords : {};
        self._s.alt = (c.altitude === null || c.altitude === undefined) ? -1 : Math.round(c.altitude);
        self.setData({ evt: 'EVT: GEO one-shot altitude ' + (self._s.alt < 0 ? 'n/a' : self._s.alt + 'm') }); self._recompute();
      }, () => { self.setData({ evt: 'EVT: GEO SKIP - failed' }); }, { timeout: 8000 });
    } catch (e) { this.setData({ evt: 'EVT: GEO SKIP' }); }
  },
  speakTap() {
    const s = this._s;
    const need = Math.max(1, Math.floor(s.mins / 30));
    const ok = this._speak(s.prog + '구간째, 휴식 ' + s.rests + '번, 물 ' + s.water + '잔。' + (s.water < need ? '물을 마실 시간예요。' : '수분은 괜찮아요。'));
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'pace ledger' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const pos = Math.min(8, s.prog);
    const prof = '    ╱‾‾╲\n  ╱      ╲\n╱' + ' '.repeat(pos) + '●' + ' '.repeat(Math.max(0, 8 - pos)) + '╲___';
    const need = Math.max(1, Math.floor(s.mins / 30));
    this.setData({
      status: s.prog >= 8 ? 'SUMMIT: 정상 — 하산 페이스도 여기서부터' : ('HIKE: ' + s.prog + '/8 구간 · 약 ' + s.mins + '분'),
      hero: '진행 ' + s.prog + '/8 · 고도 ' + (s.alt === null ? '미기록' : (s.alt < 0 ? '가져올 수 없음' : ('약 ' + s.alt + 'm'))),
      heroSub: '', r1: '휴식 ' + s.rests + ' 회 · 수분 ' + s.water + '/' + need + ' 잔 기준' + (s.water < need && s.prog > 0 ? ' — 물을 마시세요' : ''),
      r2: '길은 안내하지 않습니다 — 페이스와 수분 장부뿐입니다', r3: '', r4: '', marks: prof,
      guide: 'GO 다음 구간 · REST 휴식 · WATER 수분 · GEO 고도 한 번만 기록'
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
    <div class="ttl">DEUNGSAN PACE</div>
    <div class="status">{{ status }}</div>
    <div class="profbox"><div class="prof mono">{{ marks }}</div></div>
    <div class="heroline">{{ hero }}</div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">REST</button>
      <button class="btn" bindtap="act2Tap">WATER</button>
      <button class="btn" bindtap="act3Tap">GEO</button>
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

.profbox { border: 1px solid rgba(64,255,94,0.24); padding: 8px 10px; margin-top: 8px; }
.prof { color: #40ff5e; font-size: 14px; line-height: 19px; white-space: pre; }
.btn { border-radius: 20px 4px 20px 4px; background-color: transparent; border: 1px solid rgba(64,255,94,0.72); padding: 6px 0; }
.btn-main { background-color: #0d2812; border-color: #7dff9e; }
.demobtn { border-radius: 20px 4px 20px 4px; background-color: transparent; }
</style>
