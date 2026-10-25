<script def>
{
  "title": "Kairanban Relay"
}
</script>

<script setup>
import wx from 'wx';

// JP13 Kairanban Relay - 町内リレー Neighborhood Relay
// Local anchor: 回覧板（かいらんばん）は日本の町内会・自治会の連絡制度：区役所や町内会のお知らせを一枚の板・冊子に挟み、家から家へ順番に...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const HOUSES = ['佐藤家','鈴木家','高橋家','田中家'];
const DEMO_S = [{"idx": 0, "stamped": true, "cycles": 0}, {"idx": 1, "stamped": false, "cycles": 0}, {"idx": 3, "stamped": true, "cycles": 1}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"idx": 0, "stamped": false, "cycles": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this._stampOrSpeak(); },
  _swipe(dir) {
    this.setData({ evt: 'EVT: swipe - 回覧板の順番はボタンで進めます' });
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    this._stampOrSpeak();
  },
  _stampOrSpeak() {
    const s = this._s;
    if (!s.stamped) {
      s.stamped = true;
      this._speak('回覧板を受け取りました。次の家へ回してください。');
      this.setData({ evt: 'EVT: stamped - board received' });
    } else {
      this.speakTap();
    }
    this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (!s.stamped) {
      this._speak('まだ押印していません。先に押印してください。');
      this.setData({ evt: 'EVT: PASS blocked - not stamped yet' });
      this._recompute();
      return;
    }
    s.idx = (s.idx + 1) % 4;
    if (s.idx === 0) s.cycles++;
    s.stamped = false;
    this.setData({ evt: 'EVT: passed -> ' + HOUSES[s.idx] });
    this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._stampOrSpeak();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.idx = (s.idx + 3) % 4;
    s.stamped = false;
    this.setData({ evt: 'EVT: back -> ' + HOUSES[s.idx] });
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const t = '回覧板は今、' + HOUSES[s.idx] + 'の手にあります。押印は' + (s.stamped ? '済んでいます。' : 'まだ済んでいません。');
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'holder spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    let dots = '';
    for (let i = 0; i < 4; i++) dots += (i === s.idx ? '●' : '○') + (i < 3 ? ' ' : '');
    const route = HOUSES[0] + ' → ' + HOUSES[1] + ' → ' + HOUSES[2] + ' → ' + HOUSES[3];
    this.setData({
      status: '回覧板：' + HOUSES[s.idx] + 'が持っています · ' + (s.stamped ? '押印済み' : '押印まだです'),
      hero: HOUSES[s.idx],
      heroSub: '',
      r1: route,
      r2: '押印：' + (s.stamped ? '済み' : 'まだ') + ' · 周回 ' + s.cycles + '回 · 次は' + HOUSES[(s.idx + 1) % 4],
      r3: '',
      r4: '',
      marks: dots,
      guide: 'PASS 次の家へ · STAMP 押印 · PREV 前の家へ · GO=押印/読み上げ · うなずき=押印'
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
    <div class="ttl">KAIRANBAN RELAY</div>
    <div class="status">{{ status }}</div>
    <div class="linebox">
      <div class="dots">{{ marks }}</div>
      <div class="stations">{{ r1 }}</div>
    </div>
    <div class="heroline">{{ hero }}</div>
    <div class="rline dim">{{ r2 }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">PASS</button>
      <button class="btn" bindtap="act2Tap">STAMP</button>
      <button class="btn" bindtap="act3Tap">PREV</button>
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

.linebox { margin-top: 12px; border-top: 2px solid rgba(64,255,94,0.6); padding-top: 8px; }
.dots { color: #40ff5e; font-family: monospace; font-size: 19px; letter-spacing: 2px; text-align: center; }
.stations { color: #7dff9e; font-size: 11px; text-align: center; margin-top: 4px; white-space: nowrap; overflow: hidden; }
.btn { border-radius: 20px; background-color: #000000; border: 1px solid rgba(64,255,94,0.72); border-top: 3px solid #40ff5e; letter-spacing: 1px; }
.btn-main { background-color: #0d2812; border-top: 3px solid #7dff9e; }
.demobtn { border-radius: 20px; background-color: #000000; border-top: 3px solid #40ff5e; }
.btn { border-top: 3px solid #40ff5e; background-color: #0d2812; }
.demobtn { border-top: 3px solid #40ff5e; }
</style>
