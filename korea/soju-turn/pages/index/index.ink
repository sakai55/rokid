<script def>
{
  "title": "Soju Turn"
}
</script>

<script setup>
import wx from 'wx';

// KR03 Soju Turn - 尊重编排 Respect Choreography
// Local anchor: 韩国회식（会餐）的烧酒礼仪是身体性的：给长辈倒酒要两手（두 손으로 따르기），自己喝时要侧过头去（고개를 돌려 마시기）...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const STAGES = ['두 손으로 받기', '두 손으로 따르기', '고개 돌려 마시기', '빈 잔 확인'];
const DEMO_S = [{"stage": 1, "elder": true, "glass": "가득", "rounds": 0, "sensor": "ok", "baseYaw": 10, "turned": false}, {"stage": 2, "elder": true, "glass": "가득", "rounds": 0, "sensor": "ok", "baseYaw": 10, "turned": true}, {"stage": 0, "elder": true, "glass": "빈 잔", "rounds": 1, "sensor": "ok", "baseYaw": 10, "turned": false}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"stage": 0, "elder": true, "glass": "빈 잔", "rounds": 0, "sensor": "unknown", "baseYaw": null, "turned": false};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._sensorStart();
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _sensorStart() {
    const self = this;
    try {
      if (typeof AbsoluteOrientationSensor === 'undefined') { this._s.sensor = 'absent'; return; }
      const sen = new AbsoluteOrientationSensor({ frequency: 30 });
      sen.addEventListener('reading', () => {
        const q = sen.quaternion; if (!q) return;
        const x = q[0], y = q[1], z = q[2], w = q[3];
        const yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)) * 180 / Math.PI;
        self._onYaw(yaw);
      });
      sen.addEventListener('error', () => { self._s.sensor = 'absent'; self._recompute(); });
      sen.start(); this._sensor = sen; this._s.sensor = 'ok';
    } catch (e) { this._s.sensor = 'absent'; }
  },
  _onYaw(yaw) {
    const s = this._s;
    if (s.stage !== 2 || !s.elder) return;
    if (s.baseYaw === null || s.baseYaw === undefined) { s.baseYaw = yaw; return; }
    let d = Math.abs(yaw - s.baseYaw);
    if (d > 180) d = 360 - d;
    if (!s.turned && d > 35) { s.turned = true; return; }
    if (s.turned && d < 12) { s.turned = false; s.baseYaw = null; this._advance('head-turn'); }
  },
  _advance(src) {
    const s = this._s;
    if (this._demoIdx >= 0) return;
    s.stage++;
    if (s.stage === 2 && !s.elder) s.stage = 3;
    if (s.stage >= STAGES.length) { s.stage = 0; s.rounds++; s.glass = '빈 잔'; this._speak('한 바퀴 돌았어요。'); }
    else this._speak(STAGES[s.stage]);
    this.setData({ evt: 'EVT: stage advanced by ' + src + ' -> ' + (s.stage + 1) + '/4' });
    this._recompute();
  },
  _nodAction() { this._advance('nod'); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - stages advance in order' }); },
  goTap() { if (this._demoIdx >= 0) return; this._advance('tap'); },
  act1Tap() { if (this._demoIdx >= 0) return; this._advance('tap'); },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const order = ['빈 잔', '가득', '반'];
    const s = this._s;
    s.glass = order[(order.indexOf(s.glass) + 1) % 3];
    this.setData({ evt: 'EVT: glass -> ' + s.glass }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.elder = !s.elder;
    this._speak(s.elder ? '어른이 계십니다。고개를 돌려요。' : '어른이 안 계십니다。편하게 마셔요。');
    this.setData({ evt: 'EVT: elder present -> ' + s.elder }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak('지금은 ' + STAGES[s.stage] + ' 입니다。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'stage' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    this.setData({
      status: 'ROUND ' + (s.rounds + 1) + ' · 어른 ' + (s.elder ? '계심（転頭あり）' : '안 계심') + ' · 센서 ' + (s.sensor === 'ok' ? '有効' : 'なし（点按確認）'),
      hero: STAGES[s.stage], heroSub: s.stage === 2 ? '頭を35°以上 돌렸다 돌아오면自動で次へ' : '両手と体の向きが礼儀です',
      r1: '나 ｜ 두 손', r2: s.elder ? '어른 ｜ 向かい' : '동료 ｜ 向かい',
      r3: '', r4: '', marks: s.stage === 2 ? '――▶ 돌리기' : '―――',
      guide: '잔 상태：' + s.glass + ' · NEXT 次段 · ELDER 长辈在席切换 · 头の向きが入力'
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
    <div class="ttl">SOJU TURN</div>
    <div class="status">{{ status }}</div>
    <div class="stagerow">
      <div class="actor">{{ r1 }}</div>
      <div class="arrow">{{ marks }}</div>
      <div class="actor">{{ r2 }}</div>
    </div>
    <div class="heroline center">{{ hero }}</div>
    <div class="rline center dim">{{ heroSub }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">NEXT</button>
      <button class="btn" bindtap="act2Tap">GLASS</button>
      <button class="btn" bindtap="act3Tap">ELDER</button>
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

.stagerow { display: flex; flex-direction: row; margin-top: 12px; align-items: center; }
.actor { flex: 2; border: 1px solid rgba(64,255,94,0.6); color: #7dff9e; font-size: 13px; line-height: 18px; text-align: center; padding: 12px 4px; }
.arrow { flex: 1; color: #40ff5e; font-family: monospace; font-size: 15px; text-align: center; }
.btn { background-color: #0d2812; border: none; border-top: 3px solid #40ff5e; border-bottom: 3px solid rgba(64,255,94,0.45); letter-spacing: 3px; padding: 8px 0; }
.btn-main { background-color: #14541f; border-top-color: #7dff9e; }
.demobtn { background-color: #0d2812; border: none; border-top: 3px solid #40ff5e; }
</style>
