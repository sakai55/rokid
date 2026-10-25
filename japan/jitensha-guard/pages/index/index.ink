<script def>
{
  "title": "Jitensha Guard"
}
</script>

<script setup>
import wx from 'wx';

// JP10 Jitensha Guard - 运动锁闭 Motion Lockout
// Local anchor: 日本是自行车大国，也是规矩大国：ながらスマホ（骑车看手机）已入罚则，傘さし、イヤホン、並進都被交规点名。骑行中任何「看一...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const CHECKS = ['ブレーキ', 'タイヤ空気', 'ライト点灯', '鍵・防犯登録'];
const DEMO_S = [{"riding": false, "checks": [true, true, false, false], "idx": 2, "speed": 0, "sense": "GEO可", "sim": false}, {"riding": true, "checks": [true, true, true, true], "idx": 3, "speed": 4.2, "sense": "GEO可", "sim": true}, {"riding": false, "checks": [true, true, true, true], "idx": 3, "speed": 0, "sense": "GEO可", "sim": false}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"riding": false, "checks": [false, false, false, false], "idx": 0, "speed": 0, "sense": "未試行", "sim": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._geoWatch();
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers(); try { if (this._watchId !== undefined && typeof navigator !== 'undefined' && navigator.geolocation) navigator.geolocation.clearWatch(this._watchId); } catch (e) {} },

  _nodAction() { if (!this._s.riding) this.act1Tap(); },
  _swipe(dir) {
    if (this._s.riding) { this.setData({ evt: 'EVT: LOCKED - swipes ignored while riding' }); return; }
    this._s.idx = Math.max(0, Math.min(3, this._s.idx + dir));
    this.setData({ evt: 'EVT: check item -> ' + CHECKS[this._s.idx] }); this._recompute();
  },
  goTap() { if (this._demoIdx >= 0) return; if (!this._s.riding) this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.riding) { this.setData({ evt: 'EVT: LOCKED while riding' }); return; }
    s.checks[s.idx] = true;
    let nxt = s.idx + 1; while (nxt < 4 && s.checks[nxt]) nxt++;
    if (nxt < 4) s.idx = nxt;
    const n = s.checks.filter(Boolean).length;
    this._speak(n === 4 ? '点検完了。出発できます。' : ('次は ' + CHECKS[s.idx] + ' です。'));
    this.setData({ evt: 'EVT: CHECK ' + CHECKS[s.idx] + ' ok (' + n + '/4)' }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.riding = !s.riding; s.sim = false;
    if (s.riding) this._speak('走行中モードです。画面は見ないでください。');
    else this._speak('停止しました。点検モードです。');
    this.setData({ evt: 'EVT: manual MODE -> ' + (s.riding ? 'riding' : 'stopped') }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.sim = !s.sim; s.riding = s.sim; s.speed = s.sim ? 4.2 : 0;
    this._speak(s.sim ? '練習用の走行中です。' : '練習を終えました。');
    this.setData({ evt: 'EVT: SIM ride ' + (s.sim ? 'on (practice)' : 'off') }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak(s.riding ? '走行中です。画面は見ないでください。' : ('点検 ' + s.checks.filter(Boolean).length + ' /4 です。'));
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'state' : 'FAIL') }); this._recompute();
  },
  _geoWatch() {
    const self = this;
    try {
      if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.watchPosition) { this._s.sense = '判定不可（GEOなし）'; return; }
      this._watchId = navigator.geolocation.watchPosition((p) => {
        const c = p && p.coords ? p.coords : {};
        const sp = (c.speed === null || c.speed === undefined) ? 0 : c.speed;
        self._s.speed = sp; self._s.sense = 'GEO可';
        const riding = sp > 2.2;
        if (riding !== self._s.riding && !self._s.sim) {
          self._s.riding = riding;
          if (riding) self._speak('走行中です。画面は見ないでください。');
        }
        self._recompute();
      }, () => { self._s.sense = '判定不可（GEO失敗）'; self._recompute(); }, { enableHighAccuracy: false, timeout: 10000 });
    } catch (e) { this._s.sense = '判定不可'; }
  },
  _recompute() {
    const s = this._s;
    const n = s.checks.filter(Boolean).length;
    if (s.riding) {
      this.setData({
        status: 'LOCKED: 走行中は操作できません（SIM練習含む）',
        hero: '走行中 — 見ないで', heroSub: 'イヤホン・スマホ操作は違反です',
        r1: '停止すると自動で点検に戻ります · 判定：' + s.sense, r2: '', r3: '', r4: '', marks: '',
        guide: '騎行中：ボタン全失效 · 耳だけが通道です'
      });
      return;
    }
    this.setData({
      status: n === 4 ? 'READY: 点検 4/4 — 出発できます' : 'CHECK: 出発前点検 ' + n + '/4 · 判定：' + s.sense,
      hero: n === 4 ? '出発できます' : ('次：' + CHECKS[s.idx]),
      heroSub: 'ブレーキ · タイヤ · ライト · 鍵 を一つずつ',
      r1: CHECKS.map((c, i) => (s.checks[i] ? '✓' : (i === s.idx ? '►' : '·')) + c).join('  '),
      r2: '', r3: '', r4: '', marks: '',
      guide: 'CHECK 逐项 · MODE 手动骑行相 · SIM 练习锁闭 · 骑行判定は速度/陀螺'
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
    <div class="ttl">JITENSHA GUARD</div>
    <div class="status">{{ status }}</div>
    <div class="lockbox">
      <div class="lockhero">{{ hero }}</div>
      <div class="locksub">{{ heroSub }}</div>
      <div class="rline center dim">{{ r1 }}</div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">CHECK</button>
      <button class="btn" bindtap="act2Tap">MODE</button>
      <button class="btn" bindtap="act3Tap">SIM</button>
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

.lockbox { margin-top: 58px; text-align: center; }
.lockhero { color: #40ff5e; font-size: 27px; font-weight: bold; letter-spacing: 1px; }
.locksub { color: #7dff9e; font-size: 13px; margin-top: 8px; }
.btn { background-color: transparent; border: 1px solid rgba(64,255,94,0.4); color: rgba(64,255,94,0.75); font-size: 11px; letter-spacing: 5px; padding: 3px 0; }
.btn-main { background-color: transparent; color: #7dff9e; border-color: rgba(125,255,158,0.7); font-weight: normal; }
.demobtn { background-color: transparent; border-color: rgba(64,255,94,0.4); font-size: 11px; letter-spacing: 3px; }
</style>
