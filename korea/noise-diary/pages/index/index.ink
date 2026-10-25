<script def>
{
  "title": "Noise Diary"
}
</script>

<script setup>
import wx from 'wx';

// KR02 Noise Diary - 夜间日记 Night Diary
// Local anchor: 층간소음（层间噪音）是韩国公寓生活的头号邻里矛盾，严重到有专门的调解机构与「이웃사이센터」。矛盾的另一面是：很多人并不知...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.

const DEMO_S = [{"armed": true, "level": 34, "events": 2, "peaks": ["23:10 · 72", "23:44 · 68"], "maxLv": 72, "maxAt": "23:10"}, {"armed": true, "level": 18, "events": 5, "peaks": ["23:10 · 72", "01:25 · 81", "02:03 · 66"], "maxLv": 81, "maxAt": "01:25"}, {"armed": false, "level": 0, "events": 5, "peaks": ["23:10 · 72", "01:25 · 81", "02:03 · 66"], "maxLv": 81, "maxAt": "01:25"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"armed": false, "level": 0, "events": 0, "peaks": [], "maxLv": 0, "maxAt": "-"};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _clock() { try { const d = new Date(); return (d.getHours() < 10 ? '0' : '') + d.getHours() + ':' + (d.getMinutes() < 10 ? '0' : '') + d.getMinutes(); } catch (e) { return 'night'; } },
  _nodAction() { if (!this._s.armed) this.act2Tap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - diary is by night, not pages' }); },
  goTap() { if (this._demoIdx >= 0) return; if (!this._s.armed) this.act1Tap(); else this.act2Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    if (this._s.armed) { this._stopTimers(); this._s.armed = false; this.setData({ evt: 'EVT: diary closed for tonight' }); this._recompute(); return; }
    this._s.armed = true; this._startLevel();
    this.setData({ evt: 'EVT: night watch armed (level only)' }); this._recompute();
  },
  _startLevel() {
    const self = this;
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof AudioContext === 'undefined') { this.setData({ evt: 'EVT: MIC SKIP - no mic on this surface' }); return; }
      nav.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
        self._stream = stream;
        const ac = new AudioContext(); self._ac = ac;
        const src = ac.createMediaStreamSource(stream);
        const an = ac.createAnalyser(); an.fftSize = 512; src.connect(an);
        const buf = new Uint8Array(an.fftSize);
        let cool = 0;
        self._micTimer = setInterval(() => {
          an.getByteTimeDomainData(buf);
          let sum = 0; for (let i = 0; i < buf.length; i++) { const v = (buf[i] - 128) / 128; sum += v * v; }
          const lv = Math.min(100, Math.round(Math.sqrt(sum / buf.length) * 320));
          self._s.level = lv;
          if (cool > 0) cool--;
          if (lv > 65 && cool === 0) {
            cool = 15; self._s.events++;
            if (lv > self._s.maxLv) { self._s.maxLv = lv; self._s.maxAt = self._clock(); }
            if (self._s.peaks.length < 3) self._s.peaks.push(self._clock() + ' · ' + lv);
            self.setData({ evt: 'EVT: peak pinned (silent, no alert by design)' });
          }
          self._recompute();
        }, 400);
      }).catch((e) => { self.setData({ evt: 'EVT: MIC SKIP - denied' }); });
    } catch (e) { this.setData({ evt: 'EVT: MIC SKIP' }); }
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    const ok = this._speak('어젯밤 큰 소리는 ' + s.events + '번, 가장 큰 소리는 ' + s.maxAt + ' 였어요。');
    this.setData({ evt: 'EVT: REVIEW ' + (ok ? 'diary read aloud' : 'FAIL') }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._s = { armed: false, level: 0, events: 0, peaks: [], maxLv: 0, maxAt: '-' };
    this._stopTimers();
    this.setData({ evt: 'EVT: diary wiped (it lives only in this page)' }); this._recompute();
  },
  speakTap() { this.act2Tap(); },
  _recompute() {
    const s = this._s;
    const arc = '22 ──────── 02 ──────── 06';
    this.setData({
      status: s.armed ? 'DIARY: 夜の守候中 — 記録だけで、夜間は一切知らせません' : ('MORNING: 昨夜 ' + s.events + ' 件 · 最も大きい音 ' + (s.maxAt === '-' ? 'なし' : (s.maxAt + ' · ' + s.maxLv))),
      hero: s.armed ? '守候中 · 事件 ' + s.events + ' 件' : '朝の復盤です',
      heroSub: '', r1: '峰值1：' + (s.peaks[0] || '—'), r2: '峰值2：' + (s.peaks[1] || '—'), r3: '峰值3：' + (s.peaks[2] || '—'),
      r4: '', marks: arc,
      guide: 'ARM 夜守候 · REVIEW 晨复盘 · RESET 清空 · 声は録らない、時刻だけ'
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
    <div class="ttl">NOISE DIARY</div>
    <div class="status">{{ status }}</div>
    <div class="arc">{{ marks }}</div>
    <div class="heroline">{{ hero }}</div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="rline dim">{{ r3 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">ARM</button>
      <button class="btn" bindtap="act2Tap">REVIEW</button>
      <button class="btn" bindtap="act3Tap">RESET</button>
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

.arc { color: #40ff5e; font-family: monospace; font-size: 16px; text-align: center; margin-top: 8px; letter-spacing: 1px; white-space: nowrap; overflow: hidden; }
.btn { border-radius: 20px; background-color: transparent; border: 1px dashed rgba(64,255,94,0.65); font-size: 11px; letter-spacing: 2px; padding: 4px 0; }
.btn-main { border: 1px solid #7dff9e; background-color: #0d2812; }
.demobtn { border-radius: 20px; background-color: transparent; border: 1px dashed rgba(64,255,94,0.65); }
</style>
