<script def>
{
  "title": "Baedal Code"
}
</script>

<script setup>
import wx from 'wx';

// KR10 Baedal Code - 逐字保险箱 Digit Vault
// Local anchor: 韩国배달（外卖）文化与公寓生活咬合出一个高频小麻烦：공동현관（共用玄关）密码、세대玄关码、订单号——骑手到楼下打电话来问...
// Non-conflict: the loop below is a closed register/watch/verify loop the
// glasses do not ship by default; no translation, no generic recognition,
// no navigation, no meeting transcription is claimed anywhere.

const DEMO_S = [{"code": "7394", "reveal": 1, "showOrder": false, "wiped": false, "order": "B-221"}, {"code": "7394", "reveal": 3, "showOrder": false, "wiped": false, "order": "B-221"}, {"code": "7394", "reveal": 0, "showOrder": false, "wiped": true, "order": "B-221"}];

export default {
  data: { status: '', hero: '', heroSub: '', r1: '', r2: '', r3: '', r4: '', marks: '', guide: '', evt: 'EVT: ready' },

  onLoad() {
    this._s = {"code": "7394", "reveal": 0, "showOrder": false, "wiped": false, "order": "B-221"};
    this._demoIdx = -1; this._savedS = null; this._busy = false; this._steady = false;
    this._timer = null; this._micTimer = null; this._stream = null; this._ac = null;
    try { this.enableWorldAwareness(); } catch (e) {}
    this._recompute();
  },

  onHide() { this._stopTimers(); },
  onUnload() { this._stopTimers();  },

  _maskTimer() {
    this._stopTimers();
    const self = this;
    this._timer = setTimeout(() => { self._s.reveal = 0; self.setData({ evt: 'EVT: auto-masked after 8s' }); self._recompute(); }, 8000);
  },
  _nodAction() { this.act1Tap(); },
  _swipe(dir) { this.setData({ evt: 'EVT: swipe - digits open by REVEAL only' }); },
  goTap() {
    if (this._demoIdx >= 0) return;
    const ok = this._speak(this._s.wiped ? '이미 지웠어요。' : '한 자리씩 열게요。숫자는 말하지 않아요。');
    this.setData({ evt: 'EVT: GO guidance spoken (digits never spoken) ' + (ok ? '' : 'FAIL') }); this._recompute();
  },
  act1Tap() {
    if (this._demoIdx >= 0) return;
    const s = this._s;
    if (s.wiped) { this.setData({ evt: 'EVT: vault empty - wiped' }); this._recompute(); return; }
    s.reveal = Math.min(4, s.reveal + 1);
    this._maskTimer();
    this.setData({ evt: 'EVT: REVEAL digit ' + s.reveal + '/4 (auto-mask 8s)' }); this._recompute();
  },
  act2Tap() {
    if (this._demoIdx >= 0) return;
    this._s.showOrder = !this._s.showOrder;
    this.setData({ evt: 'EVT: ORDER display ' + (this._s.showOrder ? 'on' : 'off') }); this._recompute();
  },
  act3Tap() {
    if (this._demoIdx >= 0) return;
    this._stopTimers();
    this._s.wiped = true; this._s.reveal = 0;
    this._speak('지웠어요。');
    this.setData({ evt: 'EVT: WIPE - code destroyed in memory' }); this._recompute();
  },
  speakTap() { this.goTap(); },
  _recompute() {
    const s = this._s;
    const digs = [0, 1, 2, 3].map((i) => s.wiped ? '—' : (i < s.reveal ? s.code[i] : '●'));
    this.setData({
      status: s.wiped ? 'WIPED: 暗号は消えました — 復元できません（設計です）' : ('VAULT: ' + s.reveal + '/4 桁 表示中 · 8秒で自動で隠れます'),
      hero: s.showOrder ? ('注文 ' + s.order) : (s.wiped ? '空の金庫' : '공동현관 코드'),
      heroSub: '数字は音声で読み上げません — 目だけに渡します',
      r1: digs[0], r2: digs[1], r3: digs[2], r4: digs[3], marks: '',
      guide: 'REVEAL 逐位 · ORDER 订单号 · WIPE 销毁 · 存储ゼロ、关页即忘'
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
    <div class="ttl">BAEDAL CODE</div>
    <div class="status">{{ status }}</div>
    <div class="vaultrow">
      <div class="digit">{{ r1 }}</div>
      <div class="digit">{{ r2 }}</div>
      <div class="digit">{{ r3 }}</div>
      <div class="digit">{{ r4 }}</div>
    </div>
    <div class="heroline center">{{ hero }}</div>
    <div class="rline center dim">{{ heroSub }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="act1Tap">REVEAL</button>
      <button class="btn" bindtap="act2Tap">ORDER</button>
      <button class="btn" bindtap="act3Tap">WIPE</button>
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

.vaultrow { display: flex; flex-direction: row; margin-top: 16px; justify-content: center; }
.digit { width: 62px; height: 74px; margin-right: 10px; border: 2px solid rgba(64,255,94,0.7); color: #40ff5e; font-family: monospace; font-size: 34px; font-weight: bold; text-align: center; line-height: 74px; }
.vaultrow .digit:last-child { margin-right: 0; }
.btn { font-family: monospace; background-color: #0d2812; border: 1px solid rgba(64,255,94,0.85); border-radius: 5px; letter-spacing: 3px; padding: 8px 0; }
.btn-main { background-color: #40ff5e; color: #06280f; }
.demobtn { font-family: monospace; border-radius: 5px; letter-spacing: 2px; }
</style>
