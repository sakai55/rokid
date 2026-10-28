<script def>
{"title": "Dual Shot Verify"}
</script>

<script setup>
import wx from 'wx';

// AV08 detail: telephoto shot gated by head stability.
// onOrientationStabilityChange drives the steady flag; while unsteady,
// Enter refuses and tells the wearer to hold steady first.
const TMP = 'av08_tmp';
const ACTS = ['拍细节 telephoto', '朗读状态', '返回 BACK'];

export default {
  data: {
    status: '细节拍：先稳住头部，再拍 telephoto 细节',
    steadyLine: '头稳状态：未稳（请保持静止）',
    wideLine: '左幅 WIDE：—',
    detailLine: '右幅 DETAIL：未拍',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() { this._focus = 0; this._busy = false; this._steady = false; this._render(); },
  onShow() { this._render(); },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return {}; },
  _saveTmp(t) { try { wx.setStorageSync(TMP, t); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const t = this._loadTmp();
    this.setData({
      wideLine: '左幅 WIDE：' + (t.wide ? ('已登记 · ' + (t.wideBytes || 0) + ' B') : '未登记（先回全景登记页）'),
      detailLine: '右幅 DETAIL：' + (t.detail ? ('已拍 · ' + (t.detailBytes || 0) + ' B · telephoto') : '未拍'),
      steadyLine: '头稳状态：' + (this._steady ? '已稳 ✓ 可拍' : '未稳（请保持静止）'),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）',
      status: (t.wide && t.detail) ? '两拍齐备：可去交叉核验页' : this.data.status
    });
  },
  async _blobToDataUrl(blob) {
    // This runtime has NO blob-text reader API (fleet error E2005).
    // Documented path:
    // blob.arrayBuffer() -> chunked base64 via btoa.
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
      throw new Error('E2005: ' + this._err(e));
    }
  },
  async _shrink(blob) {
    try {
      if (typeof createImageBitmap === 'undefined' || typeof document === 'undefined') throw new Error('no bitmap/canvas');
      const bmp = await createImageBitmap(blob);
      const scale = bmp.width > 480 ? (480 / bmp.width) : 1;
      const cv = document.createElement('canvas');
      cv.width = Math.max(1, Math.round(bmp.width * scale));
      cv.height = Math.max(1, Math.round(bmp.height * scale));
      const ctx = cv.getContext('2d'); if (!ctx) throw new Error('no 2d ctx');
      ctx.drawImage(bmp, 0, 0, cv.width, cv.height);
      const out = await new Promise((res, rej) => { try { cv.convertToBlob((b) => { if (b) res(b); else rej(new Error('convert fail')); }, 'image/jpeg', 0.7); } catch (e) { rej(e); } });
      return { url: await this._blobToDataUrl(out), note: '已缩图宽480' };
    } catch (e) {
      return { url: await this._blobToDataUrl(blob), note: '缩图失败，回退原图（' + this._err(e) + '）' };
    }
  },
  async captureTap() {
    if (this._busy) return;
    if (!this._steady) {
      this.setData({ status: '未稳不拍：请先稳住头部，稳了才拍', evt: 'EVT: capture refused - head unsteady' });
      this._speak('先稳住头部');
      return;
    }
    this._busy = true;
    this.setData({ status: '正在拍 telephoto 细节…', evt: 'EVT: telephoto capture start' });
    try {
      const nav = (typeof navigator !== 'undefined') ? navigator : null;
      if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw new Error('getUserMedia 不可用');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture 不可用');
      const stream = await nav.mediaDevices.getUserMedia({ video: true });
      let blob = null;
      try {
        const cap = new ImageCapture(stream.getVideoTracks()[0]);
        blob = await cap.takePhoto({ mode: 'telephoto' });
      } finally {
        try { stream.getTracks().forEach((tr) => { try { tr.stop(); } catch (e) {} }); } catch (e) {}
      }
      if (!blob) throw new Error('未取得照片 Blob');
      const shr = await this._shrink(blob);
      const t = this._loadTmp();
      t.detail = shr.url; t.detailBytes = blob.size; t.detailNote = shr.note;
      this._saveTmp(t);
      this.setData({ status: '细节已拍（' + shr.note + '），两拍' + (t.wide ? '齐备' : '还缺全景'), evt: 'EVT: telephoto saved ' + blob.size + 'B' });
      this._speak('细节已拍');
    } catch (e) {
      this.setData({ status: '细节拍失败：' + this._err(e), evt: 'EVT: telephoto FAIL ' + this._err(e) });
    } finally { this._busy = false; this._render(); }
  },
  speakTap() { const t = this._loadTmp(); this._speak('全景' + (t.wide ? '已登记' : '未登记') + '，细节' + (t.detail ? '已拍' : '未拍') + '，头部' + (this._steady ? '已稳' : '未稳')); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) {
    const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN;
    if (!isNaN(idx)) this._focus = idx;
    this.doAct();
  },
  doAct() { if (this._focus === 0) this.captureTap(); else if (this._focus === 1) this.speakTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) {
    const d = (event && event.detail) || event || {};
    this._steady = (d.isStable === true || d.stable === true);
    this.setData({ steadyLine: '头稳状态：' + (this._steady ? '已稳 ✓ 可拍' : '未稳（请保持静止）'), evt: 'EVT: head ' + (this._steady ? 'steady' : 'moving') });
  },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.captureTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (k === 'Enter') {  this.doAct(); }
    else if (k === 'ArrowUp') {  this.moveTap(-1); }
    else if (k === 'ArrowDown') {  this.moveTap(1); }
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">Dual Shot Verify · 细节拍</text>
    <text class="status">{{status}}</text>
    <text class="steady">{{steadyLine}}</text>
    <view class="dual">
      <view class="frame"><text class="flabel">{{wideLine}}</text></view>
      <view class="frame hot"><text class="flabel">{{detailLine}}</text></view>
    </view>
    <button class="banner" bindtap="actTap" data-idx="0">拍细节 telephoto（头稳才拍）</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">朗读状态</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">头稳引导：未稳时 Enter 只提示、不拍；稳了才拍。单拍不给结论。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.steady { color: #7dff9e; font-size: 13px; line-height: 17px; margin-top: 3px; border: 1px dashed rgba(125,255,158,0.6); padding: 3px 6px; }
.dual { display: flex; flex-direction: row; gap: 8px; margin-top: 5px; }
.frame { flex-grow: 1; border: 2px solid rgba(125,255,158,0.5); background-color: #04140a; padding: 6px; min-height: 48px; }
.frame.hot { border-color: #40ff5e; background-color: #0a1f0e; }
.flabel { color: #7dff9e; font-size: 11px; line-height: 15px; }
.banner { color: #04140a; background-color: #40ff5e; border-radius: 0px; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
