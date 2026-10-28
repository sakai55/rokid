<script def>
{
  "title": "Color Order Check"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Color Order Check (Curb-Cut CC04, COVER/HOLD family): wire / cable
// colour-sequence checking for red-green colour-weak wearers. The
// problem is not "I cannot see" but "colour codes read unreliably":
// a wrong order means rework at best, a fault at worst. The agent
// builds an ORDER TABLE: look at each wire in turn, CHECK photographs
// it (telephoto + host LanguageModel, prompted to answer ONLY a
// colour name) and appends the colour NAME to the list. In VERIFY the
// same wires are re-photographed in the same order and each is
// compared with the table: match advances, mismatch stops and says
// exactly which position is wrong, what was registered, and what is
// there now. Colours are NEVER communicated by colour alone: every
// result is a spoken and written colour NAME, because correcting a
// broken channel with the broken channel itself is not a fix.
// A manual fallback exists (COLOR cycles a fixed palette, ADD
// appends, DEL removes the last entry) for when the photo path is
// unavailable. Nothing is persisted: no storage calls.
// -------------------------------------------------------------------

const PALETTE = ['红', '橙', '黄', '绿', '蓝', '紫', '棕', '黑', '白', '灰', '粉'];

export default {
  data: {
    status: 'REGISTER: 逐根看向线材，CHECK 登记颜色名',
    photoLine: 'PHOTO: 未试 — 只报颜色名，从不只用颜色提示',
    manualLine: '手动色：红 — COLOR 换色 · ADD 登记 · DEL 删末位',
    seqLine: '顺序表：还没有登记',
    stateLine: '登记至少 2 根，GO 开始逐根复查',
    progressLine: '已登记 0 根 · 复查 0 / 0 根',
    guideLine: 'CHECK=拍照识色 · COLOR 换手动色 · ADD 手动登记',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'register'; // register | verify | done
    this._seq = [];
    this._ptr = 0;
    this._manualIdx = 0;
    this._mismatch = null;
    this._verified = 0;
    this._skipped = 0;
    this._tickCount = 0;
    this._steady = false;
    this._nodAt = -100000;
    this._busy = false;
    this._demo = null;
    this._demoStep = 0;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._recompute();
  },

  onShow() {},
  onHide() {},
  onUnload() {},

  _err(tag, e) {
    return tag + ': ' + (e && e.message ? e.message : String(e));
  },

  _speakText(text) {
    // Fixed host voice; utterance lang is never set (documented: the
    // TTS lang attribute does not take effect on this platform).
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      const u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u, 'immediate');
      return true;
    } catch (e) {
      return false;
    }
  },

  // ---- head gestures -------------------------------------------------
  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    this._steady = detail.isStable === true || detail.stable === true;
  },
  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || '';
    if (g !== 'nod') return;
    if (!this._steady) return;
    if (this._tickCount - this._nodAt < 8) return;
    this._nodAt = this._tickCount;
    if (this._phase === 'register' || this._phase === 'verify') {
      this.checkTap();
      this.setData({ lastEvent: 'EVT: nod (steady) -> CHECK colour' });
    } else {
      this.speakTap();
      this.setData({ lastEvent: 'EVT: nod (steady) -> SPEAK only' });
    }
    this._recompute();
  },

  // ---- temple keys ---------------------------------------------------
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.goTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this.colorTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._manualIdx = (this._manualIdx + PALETTE.length - 1) % PALETTE.length; this.setData({ lastEvent: 'EVT: manual colour -> ' + PALETTE[this._manualIdx] + ' (swipe down)' }); this._recompute(); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- buttons -------------------------------------------------------
  colorTap() {
    this._manualIdx = (this._manualIdx + 1) % PALETTE.length;
    this.setData({ lastEvent: 'EVT: manual colour -> ' + PALETTE[this._manualIdx] });
    this._recompute();
  },
  addTap() {
    if (this._phase !== 'register') {
      this.setData({ lastEvent: 'EVT: ADD only during register' });
      this._recompute();
      return;
    }
    const c = PALETTE[this._manualIdx];
    this._seq.push(c);
    this.setData({ lastEvent: 'EVT: ADD manual -> position ' + this._seq.length + ' = ' + c + '色' });
    this._recompute();
  },
  delTap() {
    if (this._phase !== 'register') {
      this.setData({ lastEvent: 'EVT: DEL only during register' });
      this._recompute();
      return;
    }
    if (this._seq.length === 0) {
      this.setData({ lastEvent: 'EVT: DEL - list already empty' });
      this._recompute();
      return;
    }
    const c = this._seq.pop();
    this.setData({ lastEvent: 'EVT: DEL removed last = ' + c + '色, now ' + this._seq.length + ' entries' });
    this._recompute();
  },

  goTap() {
    if (this._busy) return;
    if (this._phase === 'register') {
      if (this._seq.length < 2) {
        this.setData({ status: '先登记至少 2 根：顺序核对需要两个以上位置', lastEvent: 'EVT: verify refused - fewer than 2 entries' });
        this._recompute();
        return;
      }
      this._phase = 'verify';
      this._ptr = 0;
      this._mismatch = null;
      this._verified = 0;
      this._skipped = 0;
      const ok = this._speakText('开始复查，共' + this._seq.length + '根，从第 1 根开始逐根拍照核对');
      this.setData({
        status: 'VERIFY: 复查第 1 根 — 看向第 1 根点 CHECK',
        lastEvent: 'EVT: verify started, ' + this._seq.length + ' entries' + (ok ? ' (spoken)' : '')
      });
      this._recompute();
      return;
    }
    if (this._phase === 'verify') {
      this.checkTap();
      return;
    }
    if (this._phase === 'done') {
      this._phase = 'register';
      this._seq = [];
      this._ptr = 0;
      this._mismatch = null;
      this._verified = 0;
      this._skipped = 0;
      this.setData({ status: 'REGISTER: 新的一组 — 逐根看向线材，CHECK 登记颜色名', lastEvent: 'EVT: fresh register' });
      this._recompute();
      return;
    }
  },

  speakTap() {
    let text;
    if (this._phase === 'register') {
      text = this._seq.length === 0 ? '顺序表还是空的，逐根拍照或者手动登记颜色。' : '顺序表共' + this._seq.length + '根：' + this._seq.map((c, i) => '第' + (i + 1) + '根' + c + '色').join('，') + '。';
    } else if (this._phase === 'verify') {
      if (this._mismatch) {
        text = '第' + (this._mismatch.pos + 1) + '根不对，登记是' + this._mismatch.expected + '色，现在是' + this._mismatch.got + '色。';
      } else {
        text = '复查第' + (this._ptr + 1) + '根，登记是' + this._seq[this._ptr] + '色，已对上' + this._verified + '根。';
      }
    } else {
      text = '全部对上了，共' + this._seq.length + '根，点 GO 开始新的一组。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read state aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  skipTap() {
    if (this._phase !== 'verify') {
      this.setData({ lastEvent: 'EVT: SKIP only during verify' });
      this._recompute();
      return;
    }
    const pos = this._ptr;
    this._skipped++;
    this._ptr++;
    this._mismatch = null;
    this.setData({ lastEvent: 'EVT: SKIP position ' + (pos + 1) + ' (not passed, recorded as skipped)' });
    if (this._ptr >= this._seq.length) this._finishVerify();
    else this._recompute();
  },

  _finishVerify() {
    this._phase = 'done';
    const ok = this._speakText('复查结束，对上' + this._verified + '根，跳过' + this._skipped + '根');
    this.setData({ status: 'DONE ✓ 复查结束 — 对上 ' + this._verified + ' 根，跳过 ' + this._skipped + ' 根', lastEvent: 'EVT: DONE - verified ' + this._verified + ', skipped ' + this._skipped + (ok ? ' (spoken)' : '') });
    this._recompute();
  },

  // ---- CHECK: telephoto photo + LLM, colour name only ----------------
  _normColour(ans) {
    const s = String(ans);
    for (let i = 0; i < PALETTE.length; i++) {
      if (s.indexOf(PALETTE[i]) >= 0) return PALETTE[i];
    }
    return null;
  },
  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path: blob.arrayBuffer() -> chunked base64 via btoa.
    try {
      if (!blob || typeof blob.arrayBuffer !== 'function') throw new Error('E2005: blob.arrayBuffer unavailable');
      const buf = await blob.arrayBuffer();
      const bytes = new Uint8Array(buf);
      let bin = '';
      const CH = 0x8000;
      for (let i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
      return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
    } catch (e) {
      if (e && /^E2005/.test(e.message || '')) throw e;
      throw new Error('E2005: blob read fail');
    }
  },

  async checkTap() {
    if (this._phase === 'done') {
      this.setData({ lastEvent: 'EVT: this round is over - GO starts fresh' });
      this._recompute();
      return;
    }
    if (this._busy) return;
    this._busy = true;
    this.setData({ photoLine: 'PHOTO: 正在拍这根线…（只报颜色名）', lastEvent: 'EVT: CHECK photo attempt started' });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof ImageCapture === 'undefined') {
        this.setData({ photoLine: 'PHOTO: SKIP — 本机无相机拍照路径，改用 COLOR + ADD 手动登记/核对' });
        return;
      }
      const stream = await nav.mediaDevices.getUserMedia({ video: true });
      let blob = null;
      try {
        const track = stream.getVideoTracks()[0];
        const cap = new ImageCapture(track);
        blob = await cap.takePhoto({ mode: 'telephoto' });
      } finally {
        stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
      }
      if (!blob) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没拍到照片，再对准这根线一点' });
        return;
      }
      if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) {
        this.setData({ photoLine: 'PHOTO: SKIP — 拍到了，但本机无 LLM 看图，改用 COLOR + ADD' });
        return;
      }
      const avail = await LanguageModel.availability();
      if (avail !== 'available') {
        this.setData({ photoLine: 'PHOTO: SKIP — LLM 不可用（' + avail + '），改用 COLOR + ADD' });
        return;
      }
      const session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: '只回答颜色名，例如红色、绿色、黄色；看不清回答NONE，不要解释。' }] });
      const dataUrl = await this._blobToDataUrl(blob);
      const ans = await session.prompt([
        { type: 'text', text: '这根线是什么颜色？只回答颜色名或NONE。' },
        { type: 'image_url', image_url: { url: dataUrl } }
      ]);
      try { session.destroy(); } catch (e) {}
      const c = this._normColour(ans);
      if (!c) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没认出颜色（LLM 答：' + String(ans).slice(0, 20) + '），再对准一点或手动登记' });
        return;
      }
      this.setData({ photoLine: 'PHOTO: 认出 ' + c + '色 — 正在处理' });
      this._applyColour(c, 'photo');
    } catch (e) {
      this.setData({ photoLine: 'PHOTO: SKIP — ' + this._err('photo FAIL', e) + '，改用 COLOR + ADD' });
    } finally {
      this._busy = false;
      this._recompute();
    }
  },

  _applyColour(c, source) {
    if (this._phase === 'register') {
      this._seq.push(c);
      this.setData({ lastEvent: 'EVT: REGISTER position ' + this._seq.length + ' = ' + c + '色 (' + source + ')' });
    } else if (this._phase === 'verify') {
      const pos = this._ptr;
      const expected = this._seq[pos];
      if (c === expected) {
        this._verified++;
        this._ptr++;
        this._mismatch = null;
        const ok = this._speakText('第' + (pos + 1) + '根对了，' + c + '色');
        this.setData({ status: '第 ' + (pos + 1) + ' 根 ✓ 对了（' + c + '色）', lastEvent: 'EVT: MATCH position ' + (pos + 1) + ' = ' + c + '色' + (ok ? ' (spoken)' : '') });
        if (this._ptr >= this._seq.length) { this._finishVerify(); return; }
      } else {
        this._mismatch = { pos: pos, expected: expected, got: c };
        const ok = this._speakText('第' + (pos + 1) + '根不对，登记是' + expected + '色，现在是' + c + '色');
        this.setData({ status: '第 ' + (pos + 1) + ' 根 ✗ 不对：登记 ' + expected + '色，现在 ' + c + '色', lastEvent: 'EVT: MISMATCH position ' + (pos + 1) + ' expected ' + expected + ' got ' + c + (ok ? ' (spoken)' : '') });
      }
    }
    this._recompute();
  },

  clearTap() {
    if (this._busy) return;
    this._phase = 'register';
    this._seq = [];
    this._ptr = 0;
    this._mismatch = null;
    this._verified = 0;
    this._skipped = 0;
    this.setData({ status: 'REGISTER: 已清空 — 逐根看向线材，CHECK 登记颜色名', lastEvent: 'EVT: CLEAR - all reset' });
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: register 红 黄 绿; verify pos1 match; pos2
  // mismatch (registered 黄, now 蓝); fix; pos3 match; DONE.
  // A further tap restores the real state exactly.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, seq: this._seq.slice(), ptr: this._ptr,
        mismatch: this._mismatch, verified: this._verified, skipped: this._skipped
      };
      this._demoStep = 0;
      this._phase = 'register';
      this._seq = ['红', '黄', '绿'];
      this._ptr = 0;
      this._mismatch = null;
      this._verified = 0;
      this._skipped = 0;
      this.setData({ status: 'DEMO: 顺序表 红 黄 绿 — 再点 DEMO = 开始复查', lastEvent: 'EVT: DEMO on - sequence seeded in memory' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'verify';
      this._ptr = 0;
      this.setData({ status: 'DEMO: 复查第 1 根 — 再点 DEMO = 第 1 根对了', lastEvent: 'EVT: DEMO step 1 - verify started' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._ptr = 1;
      this._verified = 1;
      this.setData({ status: 'DEMO: 第 1 根 ✓ 红色对了 — 再点 DEMO = 第 2 根不对', lastEvent: 'EVT: DEMO step 2 - MATCH pos1' });
      this._recompute();
      return;
    }
    if (this._demoStep === 3) {
      this._mismatch = { pos: 1, expected: '黄', got: '蓝' };
      this.setData({ status: 'DEMO: 第 2 根 ✗ 不对：登记 黄色，现在 蓝色 — 再点 DEMO = 已纠正', lastEvent: 'EVT: DEMO step 3 - MISMATCH pos2' });
      this._recompute();
      return;
    }
    if (this._demoStep === 4) {
      this._ptr = 2;
      this._verified = 2;
      this._mismatch = null;
      this.setData({ status: 'DEMO: 第 2 根已纠正 ✓ — 再点 DEMO = 第 3 根对了，复查结束', lastEvent: 'EVT: DEMO step 4 - pos2 fixed' });
      this._recompute();
      return;
    }
    if (this._demoStep === 5) {
      this._phase = 'done';
      this._ptr = 3;
      this._verified = 3;
      this.setData({ status: 'DEMO: DONE ✓ 全部对上了 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 5 - DONE' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._seq = d.seq; this._ptr = d.ptr;
    this._mismatch = d.mismatch; this._verified = d.verified; this._skipped = d.skipped;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, progressLine, guideLine, seqLine;
    if (this._seq.length === 0) {
      seqLine = '顺序表：还没有登记';
    } else {
      seqLine = '顺序表：' + this._seq.map((c, i) => {
        const mark = (this._phase === 'verify' && i === this._ptr) ? '▸' : '';
        const bad = (this._mismatch && this._mismatch.pos === i) ? '✗' : '';
        const ok = (this._phase !== 'register' && i < this._ptr && !(this._mismatch && this._mismatch.pos === i)) ? '✓' : '';
        return mark + (i + 1) + '.' + c + '色' + bad + ok;
      }).join('  ');
    }
    if (this._phase === 'register') {
      stateLine = '登记至少 2 根，GO 开始逐根复查';
      progressLine = '已登记 ' + this._seq.length + ' 根 · 复查 0 / 0 根';
      guideLine = 'CHECK=拍照识色 · COLOR 换手动色 · ADD 手动登记 · DEL 删末位';
    } else if (this._phase === 'verify') {
      if (this._mismatch) {
        stateLine = '✗ 第 ' + (this._mismatch.pos + 1) + ' 根不对：登记 ' + this._mismatch.expected + '色，现在 ' + this._mismatch.got + '色 — 纠正后重拍 CHECK';
      } else {
        stateLine = 'VERIFY — 复查第 ' + (this._ptr + 1) + ' 根（登记 ' + this._seq[this._ptr] + '色），看向它点 CHECK';
      }
      progressLine = '已登记 ' + this._seq.length + ' 根 · 对上 ' + this._verified + ' 根 · 跳过 ' + this._skipped + ' 根';
      guideLine = 'CHECK=重拍核对 · SKIP 跳过此根（记为跳过，不算对）· GO=CHECK';
    } else {
      stateLine = 'DONE ✓ 复查结束 — 对上 ' + this._verified + ' 根，跳过 ' + this._skipped + ' 根';
      progressLine = '已登记 ' + this._seq.length + ' 根 · 对上 ' + this._verified + ' 根 · 跳过 ' + this._skipped + ' 根';
      guideLine = 'GO 开始新的一组 · CLEAR 清空重来';
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    this.setData({
      stateLine: stateLine,
      progressLine: progressLine,
      guideLine: guideLine,
      seqLine: seqLine,
      manualLine: '手动色：' + PALETTE[this._manualIdx] + '色 — COLOR 换色 · ADD 登记 · DEL 删末位'
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">COLOR ORDER CHECK</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ photoLine }}</div>
    <div class="sub">{{ manualLine }}</div>

    <div class="ledger">
      <div class="seq">{{ seqLine }}</div>
    </div>

    <div class="box">
      <div class="stateline">{{ stateLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="colorTap">COLOR</button>
      <button class="btn" bindtap="addTap">ADD</button>
      <button class="btn" bindtap="delTap">DEL</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="checkTap">CHECK</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="skipTap">SKIP</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">颜色只用名字报 · 错位停住明说 · 跳过不算对上</div>
  </div>
</template>

<style>
.page {
  width: 480px;
  height: 352px;
  background-color: #000000;
  padding: 10px 14px;
  box-sizing: border-box;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 2px;
}
.status {
  color: #7dff9e;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
}
.sub {
  color: rgba(64, 255, 94, 0.62);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.ledger {
  margin-top: 4px;
  border: 1px dashed rgba(64, 255, 94, 0.85);
  background-color: rgba(64, 255, 94, 0.06);
  padding: 8px 10px;
}
.seq {
  color: #7dff9e;
  font-size: 17px;
  font-weight: bold;
  line-height: 22px;
  white-space: nowrap;
  overflow: hidden;
}
.box {
  margin-top: 4px;
  border: 1px solid rgba(64, 255, 94, 0.45);
  padding: 4px 8px;
}
.stateline {
  color: #7dff9e;
  font-size: 12px;
  font-weight: bold;
  line-height: 16px;
  white-space: nowrap;
  overflow: hidden;
}
.nums {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.rate {
  color: rgba(64, 255, 94, 0.85);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.btnrow {
  display: flex;
  flex-direction: row;
  margin-top: 4px;
}
.btn {
  flex: 1;
  margin-right: 6px;
  background-color: #0d2812;
  color: #40ff5e;
  border: 1px solid rgba(64, 255, 94, 0.72);
  font-size: 13px;
  padding: 3px 0;
  text-align: center;
}
.btnrow .btn:last-child {
  margin-right: 0;
}
.btn-main {
  background-color: #14541f;
  color: #7dff9e;
  font-weight: bold;
}
.foot {
  color: rgba(64, 255, 94, 0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 4px;
  white-space: nowrap;
  overflow: hidden;
}
.foot2 {
  color: rgba(64, 255, 94, 0.48);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
</style>
