<script def>
{
  "title": "Curb Ramp Scout"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Curb Ramp Scout (Curb-Cut CC08, WATCH/GAZE family): the series'
// literal origin story — a wheelchair user arrives at an unfamiliar
// crossing and the curb ramp is usually NOT straight ahead but off
// to one side. Rolling up to the kerb first and discovering steps
// means backing into traffic to look for the ramp. This agent
// moves the discovery BEFORE the roll:
// (1) 定向 calibrates the crossing direction: the wearer faces the
// road and taps 定向； the current AbsoluteOrientationSensor yaw
// becomes the reference. Both hands stay on the wheels —
// calibration, scanning and verdict are all head + tap, never a
// two-hand operation.
// (2) 左扫 / 右扫 record a facing: the wearer turns the head, taps,
// and the agent stores the relative yaw (or, with no sensor, the
// wearer-declared facing — labelled as such, never dressed up as
// a measurement).
// (3) CHECK photographs the currently selected facing (telephoto
// + host LanguageModel, prompted to answer ONLY 坡道 / 台阶 /
// 看不清） and stores the verdict per facing. The LLM answers a
// two-way question about THIS kerb, never a generic description.
// (4) 结论 reads the stored checks: a facing with 坡道 wins and
// the banner says which side; three 台阶 means "换个路口"; an
// incomplete set says plainly which facings are still unexamined.
// Honesty rules: a facing with no photo verdict stays 未核， never
// inferred from the other side; 看不清 is a verdict, not a failure
// to hide — it means "this facing could not be read, check it
// another way"; with no camera/LLM the agent says SKIP plainly and
// the wearer falls back to the facing + manual verdict (手动 buttons
// are deliberately NOT offered: a guessed ramp verdict at a road
// crossing would be dangerous, so no manual override exists).
// Nothing is persisted: no storage calls anywhere.
// -------------------------------------------------------------------

const TICK_MS = 250;
const FACINGS = ['正前方', '左', '右'];

export default {
  data: {
    status: 'IDLE: 面向马路，点定向校准前方',
    sensorLine: '朝向：未校准 — 定向后面向马路为准',
    bannerLine: '还没开始找坡',
    facingLine: '三向：正前方 未核 · 左 未核 · 右 未核',
    photoLine: 'PHOTO: 未试 — CHECK 只答坡道/台阶/看不清',
    stateLine: '没校准 — 定向后左右扫，再 CHECK 核每向',
    progressLine: '已扫 0 / 3 向 · 已核 0 / 3 向',
    guideLine: '定向校准 · 左扫/右扫转头采样 · CHECK 拍照核查 · 结论定坡向',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'idle'; // idle | scanning | verdict
    this._ref = null;
    this._heading = null;
    this._headingSrc = 'NONE';
    this._selected = '正前方';
    this._scanned = { '正前方': false, '左': false, '右': false };
    this._verdict = { '正前方': null, '左': null, '右': null };
    this._yawAt = { '正前方': null, '左': null, '右': null };
    this._tickCount = 0;
    this._steady = false;
    this._nodAt = -100000;
    this._sensor = null;
    this._busy = false;
    this._demo = null;
    this._demoStep = 0;
    this._timer = null;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._startTimer();
    this._startHeading();
    this._recompute();
  },

  onShow() { this._startTimer(); this._startHeading(); },
  onHide() { this._stopTimer(); this._stopHeading(); },
  onUnload() { this._stopTimer(); this._stopHeading(); },

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

  _startTimer() {
    if (this._timer) return;
    this._timer = setInterval(() => { this._tick(); }, TICK_MS);
  },
  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },
  _tick() {
    this._tickCount++;
  },

  // ---- heading (AbsoluteOrientationSensor, same as siblings) --------
  _startHeading() {
    const Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._recompute();
      return;
    }
    if (this._sensor) return;
    const self = this;
    try {
      const s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onHeading(s); });
      s.addEventListener('error', function () {
        self._headingSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - heading NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._headingSrc = 'NONE';
      this._sensor = null;
    }
  },
  _stopHeading() {
    if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; }
  },
  _yawDeg(q) {
    if (!q || q.length < 4) return null;
    const x = q[0], y = q[1], z = q[2], w = q[3];
    const yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    const deg = yaw * 180 / Math.PI;
    return (deg + 360) % 360;
  },
  _rel(deg, ref) {
    return ((deg - ref + 540) % 360) - 180;
  },
  _onHeading(sensor) {
    if (this._demo) return;
    const deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (this._tickCount % 4 === 0) this._recompute();
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
    this.verdictTap();
    this.setData({ lastEvent: 'EVT: nod (steady) -> 结论 only (never scans/checks)' });
    this._recompute();
  },

  // ---- temple keys ---------------------------------------------------
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.calibrateTap(); return; }
    if (key === 'ArrowUp' || key === 'ArrowDown') { event.preventDefault(); this.scanTap(event.key === 'ArrowUp' ? '左' : '右'); return; }
  },
  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') event.preventDefault();
  },

  // ---- buttons -------------------------------------------------------
  calibrateTap() {
    if (this._heading !== null) {
      this._ref = this._heading;
      this._phase = 'scanning';
      this.setData({ status: 'SCANNING: 前方已校准 — 转头左扫/右扫，再 CHECK 核每向', lastEvent: 'EVT: calibrated ref yaw ' + Math.round(this._heading) + '° (sensor)' });
    } else {
      this._ref = 'declared';
      this._phase = 'scanning';
      this.setData({ status: 'SCANNING: 无朝向传感器 — 以佩戴者自报朝向为准（左扫/右扫即你转的方向）', lastEvent: 'EVT: calibrated by declaration (no sensor)' });
    }
    this._recompute();
  },

  scanTap(facing) {
    if (this._phase === 'idle') {
      this.setData({ lastEvent: 'EVT: 扫向 needs 定向 first' });
      this._recompute();
      return;
    }
    if (this._phase === 'verdict') {
      this.setData({ lastEvent: 'EVT: verdict on screen - 清除 before a new crossing' });
      this._recompute();
      return;
    }
    this._selected = facing;
    this._scanned[facing] = true;
    if (this._ref !== null && this._ref !== 'declared' && this._heading !== null) {
      this._yawAt[facing] = this._rel(this._heading, this._ref);
    }
    this.setData({ status: '已扫 ' + facing + ' — 对准该向点 CHECK 拍照核查', lastEvent: 'EVT: SCAN ' + facing + (this._yawAt[facing] !== null ? ' rel yaw ' + Math.round(this._yawAt[facing]) + '°' : ' (declared, no sensor)') });
    this._recompute();
  },
  leftTap() { this.scanTap('左'); },
  rightTap() { this.scanTap('右'); },

  _normVerdict(ans) {
    const s = String(ans);
    if (s.indexOf('坡道') >= 0) return '坡道';
    if (s.indexOf('台阶') >= 0) return '台阶';
    if (s.indexOf('看不清') >= 0) return '看不清';
    return null;
  },

  async checkTap() {
    if (this._busy) return null;
    if (this._phase === 'idle') {
      this.setData({ lastEvent: 'EVT: CHECK needs 定向 first' });
      this._recompute();
      return null;
    }
    if (this._phase === 'verdict') {
      this.setData({ lastEvent: 'EVT: verdict on screen - 清除 before a new crossing' });
      this._recompute();
      return null;
    }
    const facing = this._selected;
    this._busy = true;
    this.setData({ photoLine: 'PHOTO: 正在拍' + facing + '向…（只答坡道/台阶/看不清）', lastEvent: 'EVT: CHECK photo attempt for ' + facing });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof ImageCapture === 'undefined') {
        this.setData({ photoLine: 'PHOTO: SKIP — 本机无相机拍照路径，' + facing + '向保持未核' });
        return null;
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
        this.setData({ photoLine: 'PHOTO: SKIP — 没拍到照片，再对准' + facing + '向一点' });
        return null;
      }
      if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) {
        this.setData({ photoLine: 'PHOTO: SKIP — 拍到了，但本机无 LLM 看图，' + facing + '向保持未核' });
        return null;
      }
      const avail = await LanguageModel.availability();
      if (avail !== 'available') {
        this.setData({ photoLine: 'PHOTO: SKIP — LLM 不可用（' + avail + '），' + facing + '向保持未核' });
        return null;
      }
      const session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: '只回答坡道、台阶或看不清三者之一，不要解释。' }] });
      const dataUrl = await new Promise((resolve, reject) => {
        const r = new FileReader();
        r.onload = () => resolve(r.result);
        r.onerror = () => reject(new Error('blob read fail'));
        r.readAsDataURL(blob);
      });
      const ans = await session.prompt([
        { type: 'text', text: '画面正前方路缘是坡道还是台阶？只回答坡道、台阶或看不清。' },
        { type: 'image_url', image_url: { url: dataUrl } }
      ]);
      try { session.destroy(); } catch (e) {}
      const v = this._normVerdict(ans);
      if (!v) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没认出（LLM 答：' + String(ans).slice(0, 20) + '），' + facing + '向保持未核' });
        return null;
      }
      this._verdict[facing] = v;
      this._scanned[facing] = true;
      this.setData({ photoLine: 'PHOTO: ' + facing + '向 = ' + v, lastEvent: 'EVT: CHECK ' + facing + ' = ' + v });
      this._recompute();
      return null;
    } catch (e) {
      this.setData({ photoLine: 'PHOTO: SKIP — ' + this._err('photo FAIL', e) + '，' + facing + '向保持未核' });
      return null;
    } finally {
      this._busy = false;
      this._recompute();
    }
  },

  verdictTap() {
    if (this._phase === 'idle') {
      this.setData({ lastEvent: 'EVT: 结论 needs 定向 + 扫描 first' });
      this._recompute();
      return;
    }
    const ramps = FACINGS.filter((f) => this._verdict[f] === '坡道');
    const checked = FACINGS.filter((f) => this._verdict[f] !== null);
    const missing = FACINGS.filter((f) => this._verdict[f] === null);
    this._phase = 'verdict';
    if (ramps.length) {
      const text = '坡在' + ramps.join('、') + ' — 朝' + ramps[0] + '走';
      const ok = this._speakText(text);
      this.setData({ status: 'VERDICT ✓ ' + text, lastEvent: 'EVT: VERDICT ramp @ ' + ramps.join(',') + (ok ? ' (spoken)' : '') });
    } else if (checked.length === 3) {
      this.setData({ status: 'VERDICT: 三向都不是坡 — 换个路口再找', lastEvent: 'EVT: VERDICT no ramp on any facing' });
    } else {
      this.setData({ status: 'VERDICT: 还没查完 — 未核：' + missing.join('、') + '，先 CHECK 补核', lastEvent: 'EVT: VERDICT incomplete, missing ' + missing.join(',') });
    }
    this._recompute();
  },

  speakTap() {
    let text;
    if (this._phase === 'verdict') {
      const ramps = FACINGS.filter((f) => this._verdict[f] === '坡道');
      text = ramps.length ? '坡在' + ramps.join('、') + '。' : '还没有定出坡向。';
    } else if (this._phase === 'scanning') {
      text = '正在找坡。已核：' + FACINGS.map((f) => f + (this._verdict[f] || '未核')).join('，') + '。';
    } else {
      text = '还没有开始找坡，面向马路点定向。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read verdict aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  helpTap() {
    const text = '用法：到路口先面向马路点定向，再左右转头扫向，每向点 CHECK 拍照核查是坡道还是台阶，最后点结论，横幅会告诉你坡在哪边。双手不用离开轮子。注意：没拍照核查过的方向永远是未核，不要凭猜测过马路。';
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: HELP ' + (ok ? 'usage spoken' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  clearTap() {
    this._phase = 'idle';
    this._ref = null;
    this._selected = '正前方';
    this._scanned = { '正前方': false, '左': false, '右': false };
    this._verdict = { '正前方': null, '左': null, '右': null };
    this._yawAt = { '正前方': null, '左': null, '右': null };
    this.setData({ status: 'IDLE: 已清除 — 到下一个路口重新定向', lastEvent: 'EVT: CLEARED - back to IDLE' });
    this._recompute();
  },

  resetTap() {
    if (this._phase === 'verdict') {
      this._phase = 'scanning';
      this.setData({ status: 'SCANNING: 回到扫描 — 可补核未核方向', lastEvent: 'EVT: 复位 - verdict reopened for more checks' });
    } else {
      this.setData({ lastEvent: 'EVT: 复位 - not in verdict, nothing to reopen' });
    }
    this._recompute();
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: scanning state with 左=坡道 / 正前方=台阶 /
  // 右=未核， then a verdict （坡在左）, then cleared. A further tap
  // restores the real state. No kerb is ever faked as photographed.
  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, ref: this._ref, selected: this._selected,
        scanned: { '正前方': this._scanned['正前方'], '左': this._scanned['左'], '右': this._scanned['右'] },
        verdict: { '正前方': this._verdict['正前方'], '左': this._verdict['左'], '右': this._verdict['右'] }
      };
      this._demoStep = 0;
      this._phase = 'scanning';
      this._ref = 'declared';
      this._selected = '左';
      this._scanned = { '正前方': true, '左': true, '右': false };
      this._verdict = { '正前方': '台阶', '左': '坡道', '右': null };
      this.setData({ status: 'DEMO: 已扫左（坡道）· 正前方（台阶）· 右未核 — 再点 DEMO = 结论', lastEvent: 'EVT: DEMO on - scanning seeded (demo verdicts, not photographed)' });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'verdict';
      this.setData({ status: 'DEMO: VERDICT ✓ 坡在左 — 朝左走 — 再点 DEMO = 清除', lastEvent: 'EVT: DEMO step 1 - VERDICT ramp @ 左' });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._phase = 'idle';
      this._ref = null;
      this._selected = '正前方';
      this._scanned = { '正前方': false, '左': false, '右': false };
      this._verdict = { '正前方': null, '左': null, '右': null };
      this.setData({ status: 'DEMO: CLEARED ✓ 已清除 — 再点 DEMO 退出', lastEvent: 'EVT: DEMO step 2 - CLEARED' });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._ref = d.ref; this._selected = d.selected;
    this._scanned = d.scanned; this._verdict = d.verdict;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------
  _recompute() {
    const demo = !!this._demo;
    let stateLine, progressLine, guideLine, bannerLine, facingLine;
    const v = (f) => (this._verdict[f] || '未核');
    facingLine = '三向：正前方 ' + v('正前方') + ' · 左 ' + v('左') + ' · 右 ' + v('右');
    const nScan = FACINGS.filter((f) => this._scanned[f]).length;
    const nCheck = FACINGS.filter((f) => this._verdict[f] !== null).length;
    progressLine = '已扫 ' + nScan + ' / 3 向 · 已核 ' + nCheck + ' / 3 向 · 当前选向：' + this._selected;
    guideLine = '定向校准 · 左扫/右扫转头采样 · CHECK 拍照核查 · 结论定坡向';
    if (this._phase === 'idle') {
      stateLine = '没校准 — 定向后左右扫，再 CHECK 核每向';
      bannerLine = '还没开始找坡';
    } else if (this._phase === 'scanning') {
      stateLine = 'SCANNING — 左右扫 + CHECK 核每向，齐了点结论';
      const ramps = FACINGS.filter((f) => this._verdict[f] === '坡道');
      bannerLine = ramps.length ? '已见坡：' + ramps.join('、') + '（结论确认）' : '找坡中…当前选向 ' + this._selected;
    } else {
      const ramps = FACINGS.filter((f) => this._verdict[f] === '坡道');
      const checked = FACINGS.filter((f) => this._verdict[f] !== null);
      stateLine = 'VERDICT ✓ 已定 — 处理完清除，去下一个路口';
      if (ramps.length) bannerLine = '坡在' + ramps.join('、') + ' — 朝' + ramps[0] + '走';
      else if (checked.length === 3) bannerLine = '三向都不是坡 — 换个路口';
      else bannerLine = '还没查完 — 缺 ' + FACINGS.filter((f) => this._verdict[f] === null).join('、');
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    const sensorLine = this._ref === null ? '朝向：未校准 — 定向后面向马路为准'
      : this._ref === 'declared' ? '朝向：佩戴者自报（无传感器读数）'
      : '朝向：传感器已校准，前方为基准 0°';
    this.setData({
      stateLine: stateLine,
      progressLine: progressLine,
      guideLine: guideLine,
      bannerLine: bannerLine,
      facingLine: facingLine,
      sensorLine: sensorLine
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">CURB RAMP SCOUT</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ sensorLine }}</div>
    <div class="sub">{{ photoLine }}</div>

    <div class="banner">
      <div class="big">{{ bannerLine }}</div>
      <div class="bline">{{ facingLine }}</div>
    </div>

    <div class="box">
      <div class="stateline">{{ stateLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="leftTap">左扫</button>
      <button class="btn" bindtap="rightTap">右扫</button>
      <button class="btn btn-main" bindtap="checkTap">CHECK</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="helpTap">HELP</button>
      <button class="btn" bindtap="clearTap">清除</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="calibrateTap">定向</button>
      <button class="btn" bindtap="verdictTap">结论</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">双手不离轮 · 未核的方向永远是未核 · 不猜坡向</div>
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
.banner {
  margin-top: 4px;
  border: 2px dashed rgba(64, 255, 94, 0.9);
  background-color: rgba(64, 255, 94, 0.08);
  padding: 6px 10px;
  text-align: center;
}
.big {
  color: #7dff9e;
  font-size: 28px;
  font-weight: bold;
  line-height: 32px;
  white-space: nowrap;
  overflow: hidden;
}
.bline {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
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
