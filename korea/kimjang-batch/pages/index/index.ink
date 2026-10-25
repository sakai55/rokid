<script def>
{
  "title": "Kimjang Batch"
}
</script>

<script setup>
import wx from 'wx';

// KR08 Kimjang Batch - 批次大数 Batch Counter
// Local anchor: 김장（泡菜季腌制）是韩国冬初的家族级工程：几十上百棵白菜，절이기（盐渍）→헹구기（冲洗）→양념 바르기（抹料）三段流水线...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const STAGES = ['절이기', '헹구기', '양념 바르기'];
const DEMO_S = [{"count": 23, "target": 60, "stage": 0, "asr": "有効"}, {"count": 60, "target": 60, "stage": 0, "asr": "有効"}, {"count": 41, "target": 60, "stage": 2, "asr": "有効"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"count": 0, "target": 60, "stage": 0, "asr": "未試行"};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) {
    if (this._demoIdx >= 0) return;
    if (dir < 0 && this._s.count > 0) { this._s.count--; this.setData({ evt: 'EVT: correction -1 -> ' + this._s.count }); this._recompute(); }
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    const self = this;
    try {
      if (typeof SpeechRecognition === 'undefined') { this._s.asr = '不可（降级：点头/+1）'; this.setData({ evt: 'EVT: ASR SKIP - nod path remains' }); this._recompute(); return; }
      const sr = new SpeechRecognition();
      sr.lang = 'ko-KR'; sr.continuous = false; sr.interimResults = false;
      sr.onresult = (ev) => {
        try {
          const t = ev.results[ev.resultIndex][0].transcript || '';
          self._s.asr = '有効';
          if (t.indexOf('다음') >= 0 || t.indexOf('하나') >= 0) { self._s.count++; self.setData({ evt: 'EVT: voice count +1 (' + t + ')' }); }
          else self.setData({ evt: 'EVT: heard "' + t + '" - not a count word' });
          self._recompute();
        } catch (e) {}
      };
      sr.onerror = () => { self._s.asr = '失敗（降级：点头/+1）'; self.setData({ evt: 'EVT: ASR error - fallback' }); self._recompute(); };
      sr.start();
      this._s.asr = '聞き取り中';
      this.setData({ evt: 'EVT: ASR listening - say 다음' }); this._recompute();
    } catch (e) { this._s.asr = '不可（降级）'; this.setData({ evt: 'EVT: ASR SKIP' }); this._recompute(); }
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    this._s.count++;
    this.setData({ evt: 'EVT: +1 -> ' + this._s.count }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.count += 10;
    this._speak(this._s.count + '포기예요。');
    this.setData({ evt: 'EVT: +10 -> ' + this._s.count }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.count < s.target) { this._speak('아직 ' + (s.target - s.count) + '포기 남았어요。'); this.setData({ evt: 'EVT: stage gate holds - ' + (s.target - s.count) + ' to go' }); this._recompute(); return; }
    if (s.stage < 2) { s.stage++; const done = s.count; s.count = 0; this._speak(STAGES[s.stage] + ' 단계예요。'); this.setData({ evt: 'EVT: stage -> ' + STAGES[s.stage] + ' (prev ' + done + ')' }); }
    else { this._speak('김장 끝났어요。수고했어요。'); this.setData({ evt: 'EVT: all stages done' }); }
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak(STAGES[s.stage] + ' ' + s.count + '포기, 목표 ' + s.target + '예요。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'count' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const filled = Math.round(Math.min(1, s.count / s.target) * 20);
    let band = ''; for (let i = 0; i < 20; i++) band += (i < filled ? '█' : '░');
    this.setData({
      status: 'STAGE: ' + STAGES[s.stage] + ' · 音声 ' + s.asr,
      hero: String(s.count), heroSub: '포기 / 目標 ' + s.target + ' · ' + STAGES[s.stage],
      r1: '点头=+1 · 语音 다음=+1 · 下滑=-1 纠错 · 段目标未满 STAGE 不放行',
      r2: '', r3: '', r4: '', marks: band + ' ' + s.count + '/' + s.target,
      guide: 'GO 语音计数 · +1/+10 · STAGE 下一段 · 数字は大きく、手は汚れたままで'
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
    <div class="ttl">KIMJANG BATCH</div>
    <div class="status">{{ status }}</div>
    <div class="bigwrap"><div class="bignum">{{ hero }}</div><div class="bigunit">{{ heroSub }}</div></div>
    <div class="band mono">{{ marks }}</div>
    <div class="rline">{{ r1 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">+1</button>
      <button class="btn" bindtap="act2Tap">+10</button>
      <button class="btn" bindtap="act3Tap">STAGE</button>
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

.bigwrap { text-align: center; margin-top: 2px; }
.bignum { color: #40ff5e; font-family: monospace; font-size: 62px; font-weight: bold; line-height: 68px; }
.bigunit { color: #7dff9e; font-size: 12px; }
.band { color: rgba(64,255,94,0.9); font-size: 13px; text-align: center; border-top: 1px solid rgba(64,255,94,0.4); border-bottom: 1px solid rgba(64,255,94,0.4); padding: 4px 0; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.btn { font-size: 16px; font-weight: bold; background-color: #14541f; border: 2px solid #40ff5e; padding: 10px 0; letter-spacing: 2px; }
.btn-main { background-color: #40ff5e; color: #06280f; border-color: #7dff9e; }
.demobtn { font-weight: bold; background-color: #14541f; border: 2px solid #40ff5e; }
</style>
