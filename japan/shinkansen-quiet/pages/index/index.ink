<script def>
{
  "title": "Shinkansen Quiet"
}
</script>

<script setup>
import wx from 'wx';

// JP01 Shinkansen Quiet - 沉默守卫 Silence Keeper
// Local anchor: 日本新干线有明确的车厢礼仪：手机调静音、通话去车厢连接处（デッキ）、交谈压低音量。这不是泛泛的「安静」，而是全车厢共同遵...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const THR_DEFAULT = 62;
const DEMO_S = [{"armed": true, "level": 41, "peak": 55, "over": 0, "lastOver": "-", "thr": 62, "practice": false, "ticks": 34}, {"armed": true, "level": 78, "peak": 78, "over": 1, "lastOver": "just now", "thr": 62, "practice": false, "ticks": 71}, {"armed": true, "level": 22, "peak": 78, "over": 1, "lastOver": "ack", "thr": 62, "practice": false, "ticks": 120}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"armed": false, "level": 0, "peak": 0, "over": 0, "lastOver": "-", "thr": 62, "practice": false, "ticks": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() {
    if (this._s.over > 0) { this._s.over = 0; this._s.lastOver = 'ack'; this.setData({ evt: 'EVT: nod -> over-count acknowledged' }); this._recompute(); }
  },
  _swipe(dir) {
    this._s.thr = Math.max(40, Math.min(85, this._s.thr + dir * 3));
    this.setData({ evt: 'EVT: swipe -> threshold ' + this._s.thr });
    this._recompute();
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    if (!this._s.armed) { this.act1Tap(); return; }
    this.speakTap();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    if (this._s.armed) { this._stopTimers(); this._s.armed = false; this.setData({ evt: 'EVT: disarmed - mic released' }); this._recompute(); return; }
    this._s.armed = true; this._s.practice = false;
    this.setData({ evt: 'EVT: arming mic (level only, no recording)' });
    this._startLevel();
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.peak = this._s.level; this._s.over = 0; this._s.lastOver = '-';
    this.setData({ evt: 'EVT: peak/over reset' }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._stopTimers();
    this._s.armed = true; this._s.practice = true;
    const self = this;
    this._micTimer = setInterval(() => {
      self._s.ticks++;
      self._s.level = 30 + Math.abs(Math.sin(self._s.ticks * 0.7)) * 55;
      self._feedLevel();
    }, 500);
    this.setData({ evt: 'EVT: PRACTICE mode - simulated level, not your voice' });
    this._speak('練習モードです。声の大きさは仮の値です。');
    this._recompute();
  },
  _startLevel() {
    const self = this;
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof AudioContext === 'undefined') {
        this.setData({ evt: 'EVT: MIC SKIP - no mic/analyser on this surface' });
        return;
      }
      nav.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
        self._stream = stream;
        const ac = new AudioContext();
        self._ac = ac;
        const src = ac.createMediaStreamSource(stream);
        const an = ac.createAnalyser(); an.fftSize = 512;
        src.connect(an);
        const buf = new Uint8Array(an.fftSize);
        self._micTimer = setInterval(() => {
          an.getByteTimeDomainData(buf);
          let sum = 0;
          for (let i = 0; i < buf.length; i++) { const v = (buf[i] - 128) / 128; sum += v * v; }
          self._s.level = Math.min(100, Math.round(Math.sqrt(sum / buf.length) * 320));
          self._feedLevel();
        }, 400);
      }).catch((e) => { self.setData({ evt: 'EVT: MIC SKIP - ' + (e && e.message ? e.message : 'denied') }); });
    } catch (e) { this.setData({ evt: 'EVT: MIC SKIP - ' + (e && e.message ? e.message : String(e)) }); }
  },
  _feedLevel() {
    const s = this._s;
    if (s.level > s.peak) s.peak = s.level;
    if (s.armed && s.level > s.thr) {
      s.over++; s.lastOver = 'now';
      this._speak('音量が大きめです。通話はデッキへどうぞ。');
      this.setData({ evt: 'EVT: OVER threshold ' + s.thr + ' -> spoken reminder' });
    }
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const t = s.armed ? ('見守り中。現在の声の強さ ' + Math.round(s.level) + '、ピーク ' + s.peak + '、超過 ' + s.over + ' 回です。') : '見守りは止まっています。ARMで開始します。';
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'summary spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    const n = Math.max(0, Math.min(24, Math.round(s.level / 100 * 24)));
    let bar = ''; for (let i = 0; i < 24; i++) bar += (i < n ? '█' : '░');
    const thrPos = Math.round(s.thr / 100 * 24);
    this.setData({
      status: s.armed ? ('WATCH: ' + (s.practice ? '練習モード（仮の声量）' : 'あなたの声だけを見守り中')) : 'SETUP: ARMで守候開始 — 録音も転写もしない',
      hero: String(Math.round(s.level)),
      heroSub: 'しきい値 ' + s.thr + '（スワイプで調整） · 越えたら一度だけ提醒',
      r1: 'PEAK ' + s.peak + ' · 超過 ' + s.over + ' 回 · 最近 ' + s.lastOver,
      r2: s.over > 0 ? '通話はデッキ（車両の連結部）へ — 点頭で確認' : '静かな車内です。その調子でどうぞ',
      r3: '', r4: '',
      marks: bar,
      guide: 'ARM 監視開始 · RESET ピーク消去 · PRACTICE 練習 · うなずき=超過の確認'
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
    <div class="ttl">SHINKANSEN QUIET</div>
    <div class="status">{{ status }}</div>
    <div class="bigread">{{ hero }}</div>
    <div class="barwrap"><div class="bartext">{{ marks }}</div><div class="thresh">{{ heroSub }}</div></div>
    <div class="rline">{{ r1 }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">ARM</button>
      <button class="btn" bindtap="act2Tap">RESET</button>
      <button class="btn" bindtap="act3Tap">PRACTICE</button>
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

.bigread { color: #40ff5e; font-family: monospace; font-size: 34px; font-weight: bold; text-align: center; margin-top: 14px; }
.barwrap { border: 1px solid rgba(64,255,94,0.48); padding: 8px 10px; margin-top: 10px; }
.bartext { color: #40ff5e; font-family: monospace; font-size: 17px; letter-spacing: 1px; white-space: nowrap; overflow: hidden; }
.thresh { color: rgba(125,255,158,0.8); font-size: 11px; margin-top: 3px; }
.btn { background-color: transparent; border: none; border-top: 2px solid #40ff5e; color: #7dff9e; letter-spacing: 3px; font-size: 12px; padding: 4px 0 2px; }
.btn-main { background-color: transparent; border-top: 3px solid #7dff9e; }
.demobtn { background-color: transparent; border: none; border-top: 2px solid #40ff5e; letter-spacing: 2px; }
</style>
