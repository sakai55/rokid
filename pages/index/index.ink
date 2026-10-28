<script def>
{
  "title": "Drop Search"
}
</script>

<script setup>
import wx from 'wx';

// -------------------------------------------------------------------
// Drop Search (Curb-Cut CC01, COVER family): a floor-sector search for
// blind / low-vision wearers who dropped a small item.
// The problem it outsources is NOT "what is in front of me" (that is
// Huiyan territory) but "which patches of floor around my feet have I
// already swept, and which have I not?" A blind searcher loses the
// coverage map, not the item: they sweep the same patch twice, skip
// another, and give up unsure whether the item is really gone.
// This agent holds that map: 6 sectors around the feet, one spoken
// instruction at a time, a checked box per sector, and an honest end:
// FOUND only on the wearer's own confirmation or on a camera+LLM
// check that actually reports the item; otherwise "all 6 swept,
// nothing found" — never a guessed find.
// Voice is primary (zero screen dependency for the wearer): every
// sector change, check and outcome is spoken once via TTS. The
// screen mirrors the same lines for a sighted helper and for preview.
// Camera+LLM (PHOTO) is OPTIONAL and never replaces the hand sweep:
// it tries ImageCapture wide + LanguageModel; if either is missing
// it reports SKIP honestly and the sector stays hand-sweep only.
// Nothing is persisted: sectors live in page memory, close = forget.
// -------------------------------------------------------------------

const ITEMS = ['钥匙', '耳机', '药片', '硬币', '其他小物'];
const SECTORS = [
  { name: '正前方', cue: '低头，面向正前方，用手慢慢摸正前方地面' },
  { name: '左前方', cue: '头转向左前方，低头，用手慢慢摸左前方地面' },
  { name: '右前方', cue: '头转向右前方，低头，用手慢慢摸右前方地面' },
  { name: '左侧', cue: '头转向左侧，低头，用手慢慢摸左侧地面' },
  { name: '右侧', cue: '头转向右侧，低头，用手慢慢摸右侧地面' },
  { name: '身后', cue: '小心转身，低头，用手慢慢摸身后地面' }
];

export default {
  data: {
    status: 'SETUP: 先选丢了什么，再开始分区找',
    photoLine: 'PHOTO: 未试 — 拍照+LLM 只是可选辅助，从不代替手摸',
    stateLine: '选好物品，GO 开始搜索 — 每次只说一个区',
    sectorLine: 'SECTOR 1/6 · 正前方 · 未查',
    progressLine: '已查 0/6 · 未查 6 · 找到：无',
    guideLine: 'ITEM 切换物品 · GO 开始 · 上滑下一区 · 下滑上一区',
    lastEvent: 'EVT: ready'
  },

  onLoad() {
    this._phase = 'setup'; // setup | sweep | found | notfound
    this._itemIdx = 0;
    this._sectorIdx = 0;
    this._checked = [false, false, false, false, false, false];
    this._foundSector = -1;
    this._steady = false;
    this._nodAt = -100000;
    this._busy = false;
    this._demo = null;
    this._demoStep = 0;
    try { this.enableWorldAwareness(); } catch (e) { /* runtime without awareness */ }
    this._recompute();
  },

  onHide() { this._busy = false; },
  onUnload() { this._busy = false; },

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

  _item() { return ITEMS[this._itemIdx]; },
  _sector() { return SECTORS[this._sectorIdx]; },
  _checkedCount() {
    let n = 0;
    for (let i = 0; i < this._checked.length; i++) if (this._checked[i]) n++;
    return n;
  },

  _sectorInstruction() {
    const s = this._sector();
    return '第' + (this._sectorIdx + 1) + '区，' + s.name + '。' + s.cue + '。摸完点一下，没有就下一区，找到了点 FOUND。';
  },

  // ---- head gestures: steady nod = CHECK current sector ------------
  // 'nod' is the only documented head gesture; head orientation is NOT
  // eye gaze. A steady nod here means "this sector is swept" — the
  // same action as the CHECK button — never a find by itself.

  onOrientationStabilityChange(event) {
    const detail = (event && event.detail) || {};
    this._steady = detail.isStable === true || detail.stable === true;
  },

  onHeadGesture(event) {
    const detail = (event && event.detail) || {};
    const g = detail.gesture || detail.type || detail.name || '';
    if (g !== 'nod') return;
    if (!this._steady) return;
    if (this._phase !== 'sweep') return;
    this.checkTap();
    this.setData({ lastEvent: 'EVT: nod (steady) -> CHECK sector ' + (this._sectorIdx + 1) });
    this._recompute();
  },

  // ---- temple keys --------------------------------------------------
  // Single tap = Enter = contextual GO. Swipes = ArrowUp/Down move
  // between sectors. Double-tap = Backspace = host back, never used.

  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') {
      event.preventDefault();
      this.goTap();
      return;
    }
    if (key === 'ArrowUp') { event.preventDefault(); this.nextTap(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this.prevTap(); return; }
  },

  onKeyUp(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown' || key === 'Enter') {
      event.preventDefault();
    }
  },

  // ---- buttons ------------------------------------------------------

  itemTap() {
    if (this._phase !== 'setup') {
      this.setData({ lastEvent: 'EVT: item fixed once search starts — GO ends, then change' });
      this._recompute();
      return;
    }
    this._itemIdx = (this._itemIdx + 1) % ITEMS.length;
    this.setData({ lastEvent: 'EVT: item -> ' + this._item() });
    this._recompute();
  },

  goTap() {
    if (this._phase === 'setup') {
      this._phase = 'sweep';
      this._sectorIdx = 0;
      this._checked = [false, false, false, false, false, false];
      this._foundSector = -1;
      const ok = this._speakText('开始找' + this._item() + '。' + this._sectorInstruction());
      this.setData({
        status: 'SWEEP: ' + this._sectorInstruction(),
        lastEvent: 'EVT: search started for ' + this._item() + (ok ? ' (spoken)' : ' (SPEAK FAIL)')
      });
      this._recompute();
      return;
    }
    if (this._phase === 'sweep') {
      this.speakTap();
      return;
    }
    // found / notfound -> fresh setup
    this._phase = 'setup';
    this._sectorIdx = 0;
    this._checked = [false, false, false, false, false, false];
    this._foundSector = -1;
    this.setData({ status: 'SETUP: 新的一轮 — 先选丢了什么', lastEvent: 'EVT: fresh setup' });
    this._recompute();
  },

  nextTap() {
    if (this._phase !== 'sweep') return;
    if (this._sectorIdx >= SECTORS.length - 1) {
      this._finishNotFound();
      return;
    }
    this._sectorIdx++;
    const ok = this._speakText(this._sectorInstruction());
    this.setData({
      status: 'SWEEP: ' + this._sectorInstruction(),
      lastEvent: 'EVT: sector -> ' + (this._sectorIdx + 1) + ' ' + this._sector().name + (ok ? ' (spoken)' : '')
    });
    this._recompute();
  },

  prevTap() {
    if (this._phase !== 'sweep') return;
    if (this._sectorIdx <= 0) {
      this.setData({ lastEvent: 'EVT: already sector 1 — cannot go back' });
      this._recompute();
      return;
    }
    this._sectorIdx--;
    const ok = this._speakText(this._sectorInstruction());
    this.setData({
      status: 'SWEEP: ' + this._sectorInstruction(),
      lastEvent: 'EVT: sector back -> ' + (this._sectorIdx + 1) + ' ' + this._sector().name + (ok ? ' (spoken)' : '')
    });
    this._recompute();
  },

  checkTap() {
    if (this._phase !== 'sweep') {
      this.setData({ lastEvent: 'EVT: CHECK only during sweep' });
      this._recompute();
      return;
    }
    if (this._checked[this._sectorIdx]) {
      this.setData({ lastEvent: 'EVT: sector ' + (this._sectorIdx + 1) + ' already checked — NEXT moves on' });
      this._recompute();
      return;
    }
    this._checked[this._sectorIdx] = true;
    const n = this._checkedCount();
    if (n >= SECTORS.length) {
      this._finishNotFound();
      return;
    }
    // Advance to the next unchecked sector (skipping checked ones).
    let nxt = this._sectorIdx + 1;
    while (nxt < SECTORS.length && this._checked[nxt]) nxt++;
    if (nxt >= SECTORS.length) { this._finishNotFound(); return; }
    this._sectorIdx = nxt;
    const ok = this._speakText('第' + (this._sectorIdx + 1) + '区还没查。' + this._sectorInstruction());
    this.setData({
      status: 'SWEEP: 已查 ' + n + '/6。' + this._sectorInstruction(),
      lastEvent: 'EVT: sector checked ' + n + '/6 -> next unchecked ' + (this._sectorIdx + 1) + (ok ? ' (spoken)' : '')
    });
    this._recompute();
  },

  foundTap() {
    if (this._phase !== 'sweep') {
      this.setData({ lastEvent: 'EVT: FOUND only during sweep' });
      this._recompute();
      return;
    }
    this._foundSector = this._sectorIdx;
    this._phase = 'found';
    const ok = this._speakText('找到了，' + this._item() + '在第' + (this._sectorIdx + 1) + '区，' + this._sector().name + '。慢慢拿，别急。');
    this.setData({
      status: 'FOUND ✓ ' + this._item() + ' 在第' + (this._sectorIdx + 1) + '区（' + this._sector().name + '）',
      lastEvent: 'EVT: FOUND sector ' + (this._sectorIdx + 1) + ' by wearer confirmation' + (ok ? ' (spoken)' : '')
    });
    this._recompute();
  },

  speakTap() {
    let text;
    if (this._phase === 'setup') {
      text = '丢了' + this._item() + '，点 GO 开始分区找，一共 6 个区。';
    } else if (this._phase === 'sweep') {
      text = '已查' + this._checkedCount() + '区，还剩' + (SECTORS.length - this._checkedCount()) + '区没查。现在是' + this._sectorInstruction();
    } else if (this._phase === 'found') {
      text = this._item() + '在第' + (this._foundSector + 1) + '区，' + SECTORS[this._foundSector].name + '。';
    } else {
      text = '6 个区都查过了，没找到' + this._item() + '。可能掉在别处，或者滚出去了。';
    }
    const ok = this._speakText(text);
    this.setData({ lastEvent: 'EVT: SPEAK ' + (ok ? 'read status aloud' : 'FAIL (host TTS n/a)') });
    this._recompute();
  },

  _finishNotFound() {
    this._phase = 'notfound';
    const ok = this._speakText('6 个区都查过了，没找到' + this._item() + '。可能掉在别处，或者滚出去了。');
    this.setData({
      status: 'NOT FOUND ✗ 6 区全查完，没找到' + this._item() + ' — GO 开始新的一轮',
      lastEvent: 'EVT: NOT FOUND after 6/6 sectors' + (ok ? ' (spoken)' : '')
    });
    this._recompute();
  },

  // ---- PHOTO: optional camera+LLM check, never a substitute ---------
  // Order is honest by construction: photo first (ImageCapture wide),
  // then LanguageModel availability, then one question about THIS
  // item in THIS photo. Any step missing -> SKIP on its own line and
  // the sector stays hand-sweep only. A "no" from the model is also
  // not a find. This never claims generic scene description.

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

  async photoTap() {
    if (this._phase !== 'sweep') {
      this.setData({ lastEvent: 'EVT: PHOTO only during sweep' });
      this._recompute();
      return;
    }
    if (this._busy) return;
    this._busy = true;
    this.setData({ photoLine: 'PHOTO: 正在试拍照…（可选辅助）', lastEvent: 'EVT: PHOTO attempt started' });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia || typeof ImageCapture === 'undefined') {
        this.setData({ photoLine: 'PHOTO: SKIP — 本机无相机拍照路径，手摸为准' });
        return;
      }
      const stream = await nav.mediaDevices.getUserMedia({ video: true });
      let blob = null;
      try {
        const track = stream.getVideoTracks()[0];
        const cap = new ImageCapture(track);
        blob = await cap.takePhoto({ mode: 'wide' });
      } finally {
        stream.getTracks().forEach((t) => { try { t.stop(); } catch (e) {} });
      }
      if (!blob) {
        this.setData({ photoLine: 'PHOTO: SKIP — 没拍到照片，手摸为准' });
        return;
      }
      if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) {
        this.setData({ photoLine: 'PHOTO: SKIP — 拍到了，但本机无 LLM 看图，手摸为准' });
        return;
      }
      const avail = await LanguageModel.availability();
      if (avail !== 'available') {
        this.setData({ photoLine: 'PHOTO: SKIP — LLM 不可用（' + avail + '），手摸为准' });
        return;
      }
      const session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: '只回答“有”或“没有”，不要解释。' }] });
      const dataUrl = await this._blobToDataUrl(blob);
      const ans = await session.prompt([
        { type: 'text', text: '这张地面照片里有没有' + this._item() + '？只回答有或没有。' },
        { type: 'image_url', image_url: { url: dataUrl } }
      ]);
      try { session.destroy(); } catch (e) {}
      const yes = /有/.test(String(ans)) && !/没有/.test(String(ans));
      if (yes) {
        this._foundSector = this._sectorIdx;
        this._phase = 'found';
        this._speakText('照片里可能有' + this._item() + '，在第' + (this._sectorIdx + 1) + '区，' + this._sector().name + '。请用手确认一下。');
        this.setData({
          status: 'FOUND? 照片提示第' + (this._sectorIdx + 1) + '区可能有' + this._item() + ' — 请用手确认',
          photoLine: 'PHOTO: LLM 说“有” — 只是提示，最终以手摸为准',
          lastEvent: 'EVT: PHOTO LLM yes -> tentative FOUND sector ' + (this._sectorIdx + 1)
        });
      } else {
        this.setData({
          photoLine: 'PHOTO: LLM 说本区照片里没有' + this._item() + ' — 仍以手摸为准',
          lastEvent: 'EVT: PHOTO LLM no — sector stays hand-sweep'
        });
      }
    } catch (e) {
      this.setData({ photoLine: 'PHOTO: SKIP — ' + this._err('photo FAIL', e) + '，手摸为准' });
    } finally {
      this._busy = false;
      this._recompute();
    }
  },

  // ---- DEMO -----------------------------------------------------------
  // In-memory only: seeds 钥匙， walks sector 1 checked (empty),
  // sector 2 checked (empty), sector 3 FOUND by wearer confirmation.
  // A further tap restores the real state exactly.

  demoTap() {
    if (this._busy) return;
    if (!this._demo) {
      this._demo = {
        phase: this._phase, itemIdx: this._itemIdx, sectorIdx: this._sectorIdx,
        checked: this._checked.slice(), foundSector: this._foundSector
      };
      this._demoStep = 0;
      this._phase = 'setup';
      this._itemIdx = 0; // 钥匙
      this._sectorIdx = 0;
      this._checked = [false, false, false, false, false, false];
      this._foundSector = -1;
      this.setData({
        status: 'DEMO: 丢了钥匙 — 再点 DEMO = 开始搜索',
        lastEvent: 'EVT: DEMO on - item 钥匙 seeded in memory'
      });
      this._recompute();
      return;
    }
    this._demoStep++;
    if (this._demoStep === 1) {
      this._phase = 'sweep';
      this.setData({
        status: 'DEMO: 搜索中 — 第 1 区正前方，低头摸地面',
        lastEvent: 'EVT: DEMO step 1 - sweep started'
      });
      this._recompute();
      return;
    }
    if (this._demoStep === 2) {
      this._checked[0] = true;
      this._sectorIdx = 1;
      this.setData({
        status: 'DEMO: 第 1 区查完没有 — 第 2 区左前方',
        lastEvent: 'EVT: DEMO step 2 - sector 1 checked empty'
      });
      this._recompute();
      return;
    }
    if (this._demoStep === 3) {
      this._checked[1] = true;
      this._sectorIdx = 2;
      this._foundSector = 2;
      this._phase = 'found';
      this.setData({
        status: 'DEMO: FOUND ✓ 钥匙在第 3 区（右前方）',
        lastEvent: 'EVT: DEMO step 3 - FOUND sector 3 by confirmation'
      });
      this._recompute();
      return;
    }
    if (this._demoStep === 4) {
      // Not-found arc: all 6 checked, nothing found.
      this._phase = 'sweep';
      this._sectorIdx = 0;
      this._checked = [false, false, false, false, false, false];
      this._foundSector = -1;
      this.setData({
        status: 'DEMO: 换一轮演示 — 6 区全查完也没找到',
        lastEvent: 'EVT: DEMO step 4 - not-found arc start'
      });
      this._recompute();
      return;
    }
    if (this._demoStep === 5) {
      this._checked = [true, true, true, true, true, true];
      this._phase = 'notfound';
      this.setData({
        status: 'DEMO: NOT FOUND ✗ 6 区全查完，没找到钥匙',
        lastEvent: 'EVT: DEMO step 5 - NOT FOUND 6/6'
      });
      this._recompute();
      return;
    }
    const d = this._demo;
    this._phase = d.phase; this._itemIdx = d.itemIdx; this._sectorIdx = d.sectorIdx;
    this._checked = d.checked; this._foundSector = d.foundSector;
    this._demo = null;
    this._demoStep = 0;
    this.setData({ status: 'DEMO off — 真实状态已恢复', lastEvent: 'EVT: DEMO off - real state restored' });
    this._recompute();
  },

  // ---- render ---------------------------------------------------------

  _recompute() {
    const demo = !!this._demo;
    const item = this._item();
    const n = this._checkedCount();
    const marks = this._checked.map((c, i) => (i + 1) + (c ? '✓' : '·')).join(' ');
    let stateLine, sectorLine, progressLine, guideLine;
    if (this._phase === 'setup') {
      stateLine = '选好物品，GO 开始搜索 — 每次只说一个区';
      sectorLine = 'SECTOR 待查 · 6 区 · 物品：' + item;
      progressLine = '已查 0/6 · 未查 6 · 找到：无';
      guideLine = 'ITEM 切换物品 · GO 开始 · 语音是主通道，屏幕只是镜像';
    } else if (this._phase === 'sweep') {
      stateLine = 'SWEEP — 第' + (this._sectorIdx + 1) + '区 ' + this._sector().name + '：' + this._sector().cue;
      sectorLine = 'SECTOR ' + (this._sectorIdx + 1) + '/6 · ' + this._sector().name + ' · ' + (this._checked[this._sectorIdx] ? '已查' : '未查');
      progressLine = '已查 ' + n + '/6 · 未查 ' + (6 - n) + ' · 找到：无 · ' + marks;
      guideLine = 'CHECK=本区摸完 · NEXT=下一区 · FOUND=找到了 · 点头=CHECK';
    } else if (this._phase === 'found') {
      stateLine = 'FOUND ✓ ' + item + ' 在第' + (this._foundSector + 1) + '区（' + SECTORS[this._foundSector].name + '）— 慢慢拿';
      sectorLine = 'SECTOR ' + (this._foundSector + 1) + '/6 · ' + SECTORS[this._foundSector].name + ' · 已找到';
      progressLine = '已查 ' + n + '/6 · 找到：' + item + ' · ' + marks;
      guideLine = 'GO 开始新的一轮 · SPEAK 再听一遍位置';
    } else {
      stateLine = 'NOT FOUND ✗ 6 区全查完，没找到' + item + ' — 可能在别处';
      sectorLine = 'SECTOR 6/6 · 全查完 · 找到：无';
      progressLine = '已查 6/6 · 未查 0 · 找到：无 · ' + marks;
      guideLine = 'GO 开始新的一轮 · 换个地方重新开始';
    }
    if (demo) stateLine = 'DEMO · ' + stateLine;
    // Preserve the status line set by the action itself when it is a
    // DEMO narrative line; otherwise render from state.
    this.setData({
      stateLine: stateLine,
      sectorLine: sectorLine,
      progressLine: progressLine,
      guideLine: guideLine
    });
  }
};
</script>

<template>
  <div class="page">
    <div class="title">DROP SEARCH</div>
    <div class="status">{{ status }}</div>
    <div class="sub">{{ photoLine }}</div>

    <div class="alertbox">
      <div class="stateline">{{ stateLine }}</div>
    </div>

    <div class="box">
      <div class="watchline">{{ sectorLine }}</div>
      <div class="nums">{{ progressLine }}</div>
      <div class="rate">{{ guideLine }}</div>
    </div>

    <div class="btnrow">
      <button class="btn" bindtap="itemTap">ITEM</button>
      <button class="btn" bindtap="prevTap">PREV</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="checkTap">CHECK</button>
      <button class="btn" bindtap="foundTap">FOUND</button>
      <button class="btn" bindtap="photoTap">PHOTO</button>
    </div>
    <div class="btnrow">
      <button class="btn btn-main" bindtap="goTap">GO ✓</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </div>

    <div class="foot">{{ lastEvent }}</div>
    <div class="foot2">语音主通道 · 6 区查完才说没找到 · 拍照仅辅助</div>
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
  color: #ffffff;
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
.alertbox {
  margin-top: 5px;
  border: 1px solid rgba(64, 255, 94, 0.85);
  background-color: rgba(64, 255, 94, 0.10);
  padding: 4px 8px;
}
.stateline {
  color: #ffffff;
  font-size: 12px;
  font-weight: bold;
  line-height: 16px;
  white-space: nowrap;
  overflow: hidden;
}
.box {
  margin-top: 5px;
  border: 1px solid rgba(64, 255, 94, 0.45);
  padding: 4px 8px;
}
.watchline {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
  white-space: nowrap;
  overflow: hidden;
}
.nums {
  color: #ffffff;
  font-size: 15px;
  font-weight: bold;
  line-height: 19px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.rate {
  color: rgba(255, 255, 255, 0.85);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.focus {
  color: #40ff5e;
  font-size: 12px;
  font-weight: bold;
  line-height: 15px;
  white-space: nowrap;
  overflow: hidden;
}
.cue {
  color: #ffffff;
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.guide {
  color: rgba(64, 255, 94, 0.62);
  font-size: 10px;
  line-height: 13px;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
}
.btnrow {
  display: flex;
  flex-direction: row;
  margin-top: 6px;
}
.btn {
  flex: 1;
  margin-right: 6px;
  background-color: #0d2812;
  color: #40ff5e;
  border: 1px solid rgba(64, 255, 94, 0.72);
  font-size: 13px;
  padding: 5px 0;
  text-align: center;
}
.btnrow .btn:last-child {
  margin-right: 0;
}
.btn-main {
  background-color: #14541f;
  color: #ffffff;
  font-weight: bold;
}
.foot {
  color: rgba(64, 255, 94, 0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 13px;
  margin-top: 6px;
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
