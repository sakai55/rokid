<script def>
{
  "title": "Gye Circle"
}
</script>

<script setup>
import wx from 'wx';

// KR12 Gye Circle - 계 원형 Gye Circle
// Local anchor: 계모임（계）是韩国熟人之间轮流出钱、轮流收款的互助制度：每月每人出一份，到期的一人收走一笔。最容易乱的不是金额，而是「这...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const MEMBERS = ['지영','민준','서연','현우'];
const DEMO_S = [{"idx": 0, "paid": true, "rounds": 0}, {"idx": 1, "paid": false, "rounds": 0}, {"idx": 3, "paid": true, "rounds": 1}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"idx": 0, "paid": false, "rounds": 0};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this._payOrSpeak(); },
  _swipe(dir) {
    this.setData({ evt: 'EVT: swipe - 순서는 버튼으로 넘깁니다' });
  },
  goTap() {
    if (this._demoIdx >= 0) return;
    this._payOrSpeak();
  },
  _payOrSpeak() {
    const s = this._s;
    if (!s.paid) {
      s.paid = true;
      this._speak('이번 달 회비를 모두 냈습니다.');
      this.setData({ evt: 'EVT: paid - this month settled' });
    } else {
      this.speakTap();
    }
    this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    this._payOrSpeak();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (!s.paid) {
      this._speak('아직 회비를 내지 않았습니다. 먼저 납부를 확인해 주세요.');
      this.setData({ evt: 'EVT: NEXT blocked - not paid yet' });
      this._recompute();
      return;
    }
    s.idx = (s.idx + 1) % 4;
    if (s.idx === 0) s.rounds++;
    s.paid = false;
    this.setData({ evt: 'EVT: next receiver -> ' + MEMBERS[s.idx] });
    this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.idx = (s.idx + 3) % 4;
    s.paid = false;
    this.setData({ evt: 'EVT: back -> ' + MEMBERS[s.idx] });
    this._recompute();
  },
  speakTap() {
    const s = this._s;
    const t = '이번 달 받을 사람은 ' + MEMBERS[s.idx] + '입니다. 회비는 ' + (s.paid ? '모두 냈습니다.' : '아직 내지 않았습니다.');
    const ok = this._speak(t);
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'receiver spoken' : 'FAIL') });
    this._recompute();
  },
  _recompute() {
    const s = this._s;
    let ring = '';
    for (let i = 0; i < 4; i++) ring += (i === s.idx ? '● ' : '○ ') + MEMBERS[i] + (i < 3 ? '  ' : '');
    this.setData({
      status: '계모임: 이번 달 받을 사람 ' + MEMBERS[s.idx] + ' · 회비 ' + (s.paid ? '납부 완료' : '미납'),
      hero: MEMBERS[s.idx],
      heroSub: '',
      r1: '이전 순서 ' + MEMBERS[(s.idx + 3) % 4],
      r2: '다음 순서 ' + MEMBERS[(s.idx + 1) % 4],
      r3: '완료한 차례 ' + s.rounds + '바퀴 · 금액은 직접 정합니다',
      r4: '',
      marks: ring,
      guide: 'PAY 회비 납부 · NEXT 다음 순서 · PREV 이전 순서 · GO=납부/읽어주기 · 끄덕임=납부'
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
    <div class="ttl">GYE CIRCLE</div>
    <div class="status">{{ status }}</div>
    <div class="wheelbox">
      <div class="wprev">{{ r1 }}</div>
      <div class="wcur">{{ hero }}</div>
      <div class="wnext">{{ r2 }}</div>
      <div class="wring mono">{{ marks }}</div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">PAY</button>
      <button class="btn" bindtap="act2Tap">NEXT</button>
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

.wheelbox { text-align: center; margin-top: 6px; }
.wprev { color: rgba(125,255,158,0.6); font-size: 12px; }
.wcur { color: #40ff5e; font-size: 23px; font-weight: bold; border: 1px solid rgba(64,255,94,0.72); padding: 8px 0; margin: 6px 60px; }
.wnext { color: rgba(125,255,158,0.6); font-size: 12px; }
.wring { color: rgba(64,255,94,0.85); font-size: 12px; margin-top: 6px; }
.btn { border-radius: 26px; background-color: #0d2812; border: 2px solid rgba(64,255,94,0.8); font-weight: bold; padding: 7px 0; }
.btn-main { background-color: #40ff5e; color: #06280f; border-color: #7dff9e; }
.demobtn { border-radius: 26px; border: 2px solid rgba(64,255,94,0.8); }
.btn { border: 3px double #40ff5e; border-radius: 6px; }
.demobtn { border: 3px double #40ff5e; border-radius: 6px; }
</style>
