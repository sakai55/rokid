<script def>
{
  "title": "Noraebang Rotation"
}
</script>

<script setup>
import wx from 'wx';

// KR07 Noraebang Rotation - 公平轮值 Fair Rotation
// Local anchor: 노래방（练歌房）是韩国聚会的第二场标配，规矩就一条：轮流唱，谁也不能霸麦，谁也不许被落下。实际包厢里总有人连唱三首、有人...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.
const SINGERS = ['민준', '서연', '지훈', '하은'];
const SONGS = ['8321', '9042', '1177', '6550'];
const DEMO_S = [{"turn": 1, "songs": [0, 1, 2, 3], "sung": 1, "yielded": -1}, {"turn": 2, "songs": [0, 2, 2, 3], "sung": 2, "yielded": 1}, {"turn": 0, "songs": [0, 2, 2, 3], "sung": 4, "yielded": -1}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"turn": 0, "songs": [0, 1, 2, 3], "sung": 0, "yielded": -1};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - the wheel turns by DONE only' }); },
  goTap() { if (this._demoIdx >= 0) return; this.act1Tap(); },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.sung++;
    s.turn = (s.yielded >= 0 && s.yielded !== s.turn) ? s.yielded : (s.turn + 1) % SINGERS.length;
    if (s.yielded === s.turn) s.yielded = -1;
    this._speak('다음은 ' + SINGERS[s.turn] + ' 님이에요。');
    this.setData({ evt: 'EVT: DONE - mic to ' + SINGERS[s.turn] }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.songs[s.turn] = (s.songs[s.turn] + 1) % SONGS.length;
    this._speak('예약 번호는 ' + SONGS[s.songs[s.turn]] + '예요。');
    this.setData({ evt: 'EVT: song# for ' + SINGERS[s.turn] + ' -> ' + SONGS[s.songs[s.turn]] }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    s.yielded = s.turn;
    s.turn = (s.turn + 1) % SINGERS.length;
    this._speak('양보했어요。다음 바퀴에서 먼저예요。');
    this.setData({ evt: 'EVT: PASS - yielded, priority next round' }); this._recompute();
  },
  speakTap() {
    const s = this._s;
    const ok = this._speak('지금은 ' + SINGERS[s.turn] + ' 님, 예약 ' + SONGS[s.songs[s.turn]] + '예요。');
    this.setData({ evt: 'EVT: SPEAK ' + (ok ? 'turn' : 'FAIL') }); this._recompute();
  },
  _recompute() {
    const s = this._s;
    const prev = SINGERS[(s.turn + SINGERS.length - 1) % SINGERS.length];
    const next = SINGERS[(s.turn + 1) % SINGERS.length];
    this.setData({
      status: 'TURN: ' + SINGERS[s.turn] + ' · 歌った曲 ' + s.sung + (s.yielded >= 0 ? ' · 양보待ち：' + SINGERS[s.yielded] : ''),
      hero: SINGERS[s.turn], heroSub: '',
      r1: '前：' + prev, r2: '次：' + next + ' · 予約 ' + SONGS[s.songs[s.turn]],
      r3: '', r4: '', marks: SINGERS.join(' → ') + ' →',
      guide: 'DONE 唱完轮转 · SONG# 预约号 · PASS 让唱（下轮优先） · 点头=DONE'
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
    <div class="ttl">NORAEBANG ROTATION</div>
    <div class="status">{{ status }}</div>
    <div class="wheelbox">
      <div class="wprev">{{ r1 }}</div>
      <div class="wcur">{{ hero }}</div>
      <div class="wnext">{{ r2 }}</div>
      <div class="wring mono">{{ marks }}</div>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">DONE</button>
      <button class="btn" bindtap="act2Tap">SONG#</button>
      <button class="btn" bindtap="act3Tap">PASS</button>
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

.wheelbox { text-align: center; margin-top: 6px; }
.wprev { color: rgba(255,255,255,0.6); font-size: 12px; }
.wcur { color: #40ff5e; font-size: 23px; font-weight: bold; border: 1px solid rgba(64,255,94,0.72); padding: 8px 0; margin: 6px 60px; }
.wnext { color: rgba(255,255,255,0.6); font-size: 12px; }
.wring { color: rgba(64,255,94,0.85); font-size: 12px; margin-top: 6px; }
</style>
