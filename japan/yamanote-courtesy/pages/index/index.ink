<script def>
{
  "title": "Yamanote Courtesy"
}
</script>

<script setup>
import wx from 'wx';

// JP07 Yamanote Courtesy - 站名线图 Station Line Cue
// Local anchor: 東京的通勤礼仪是写在身体里的：リュックは前に抱える、スマホはマナーモード、降りる駅の一つ前から出口側へ寄る。做不到不是没...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const STATIONS = ['品川', '田町', '浜松町', '新橋', '有楽町', '東京'];
const CUES = ['バックパックを前に抱える', 'スマホをマナーモードに', '出口側へ寄って降りる準備'];
const DEMO_S = [{"at": 3, "cue": -1, "cuesDone": [false, false, false], "geo": "未試行"}, {"at": 4, "cue": 0, "cuesDone": [false, false, false], "geo": "粗定位あり（旁証）"}, {"at": 4, "cue": 3, "cuesDone": [true, true, true], "geo": "粗定位あり（旁証）"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"at": 0, "cue": -1, "cuesDone": [false, false, false], "geo": "未試行"};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() {
    const s = this._s;
    if (s.cue >= 0 && s.cue < 3) { this.act2Tap(); return; }
    this.act1Tap();
  },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - stations advance by ARRIVE only' }); },
  goTap() { if (this._demoIdx >= 0) return; this._nodAction(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.at >= STATIONS.length - 1) { this.setData({ evt: 'EVT: at destination - reopen to restart' }); this._recompute(); return; }
    s.at++;
    if (s.at === STATIONS.length - 2) { s.cue = 0; this._speak('次が終点です。礼儀の準備を。' + CUES[0]); }
    else this._speak(STATIONS[s.at] + 'です。');
    this.setData({ evt: 'EVT: arrived ' + STATIONS[s.at] + ' (' + (s.at + 1) + '/6)' }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.cue < 0 || s.cue >= 3) { this.setData({ evt: 'EVT: cues arm one stop before destination' }); this._recompute(); return; }
    s.cuesDone[s.cue] = true; s.cue++;
    if (s.cue < 3) this._speak(CUES[s.cue]);
    else this._speak('準備完了。あとは降りるだけです。');
    this.setData({ evt: 'EVT: cue done ' + Math.min(s.cue, 3) + '/3' }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const self = this;
    try {
      if (typeof navigator === 'undefined' || !navigator.geolocation) { this._s.geo = 'SKIP：定位なし'; this._recompute(); return; }
      navigator.geolocation.getCurrentPosition((p) => {
        const c = p && p.coords ? p.coords : {};
        self._s.geo = '粗定位 ' + (c.latitude ? c.latitude.toFixed(3) : '?') + ',' + (c.longitude ? c.longitude.toFixed(3) : '?') + '（旁証）';
        self.setData({ evt: 'EVT: GEO rough fix (evidence only)' }); self._recompute();
      }, () => { self._s.geo = 'SKIP：定位失敗'; self.setData({ evt: 'EVT: GEO SKIP' }); self._recompute(); }, { timeout: 8000 });
    } catch (e) { this._s.geo = 'SKIP：' + (e && e.message ? e.message : 'error'); this._recompute(); }
  },
  speakTap() {
    const s = this._s;
    const t = s.cue >= 0 && s.cue < 3 ? CUES[s.cue] : ('今は ' + STATIONS[s.at] + '。次は ' + (STATIONS[s.at + 1] || '終点') + ' です。');
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'status' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const marks = STATIONS.map((st, i) => i < s.at ? '●' : (i === s.at ? '◐' : (i === STATIONS.length - 1 ? '◎' : '○'))).join('─');
    const cueMode = s.cue >= 0;
    this.setData({
      status: cueMode ? ('CUE: 終点まであと1駅 · 礼儀 ' + Math.min(s.cue, 3) + '/3') : ('RIDE: ' + STATIONS[s.at] + ' · 次 ' + (STATIONS[s.at + 1] || '—') + ' · GEO ' + s.geo),
      hero: cueMode ? (s.cue < 3 ? CUES[s.cue] : '準備完了 — あとは降りるだけ') : ('現在：' + STATIONS[s.at]),
      heroSub: '', r1: STATIONS.join(' · '), r2: cueMode ? 'CUE/点頭で一件ずつ完了に' : '到着は ARRIVE で確認（列車APIはありません）',
      r3: '', r4: '', marks: marks,
      guide: 'ARRIVE 到站 · CUE 礼仪逐件 · GEO 粗旁证 · 不导航，只管时机'
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
    <div class="ttl">YAMANOTE COURTESY</div>
    <div class="status">{{ status }}</div>
    <div class="linebox">
      <div class="dots">{{ marks }}</div>
      <div class="stations">{{ r1 }}</div>
    </div>
    <div class="heroline">{{ hero }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">ARRIVE</button>
      <button class="btn" bindtap="act2Tap">CUE</button>
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

.linebox { margin-top: 12px; border-top: 2px solid rgba(64,255,94,0.6); padding-top: 8px; }
.dots { color: #40ff5e; font-family: monospace; font-size: 19px; letter-spacing: 2px; text-align: center; }
.stations { color: #ffffff; font-size: 11px; text-align: center; margin-top: 4px; white-space: nowrap; overflow: hidden; }
</style>
