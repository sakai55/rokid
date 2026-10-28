<script def>
{"title": "Dual Shot Verify"}
</script>

<script setup>
import wx from 'wx';

// AV08 dual-shot-verify - index: wide registration (B8).
// Wide photo via getUserMedia + ImageCapture takePhoto({mode:'wide'}),
// shrunk to width 480 and kept in wx storage temp key av08_tmp as
// page-to-page hand-off (not the persistent ledger). A spoken name is
// dictated with SpeechRecognition; a mis-hearing is fixed by re-speaking.
const TMP = 'av08_tmp';
const MENU = ['拍全景 wide 登记', '语音命名（说出登记名）', '去细节拍 detail', '去交叉核验 verify', '去落账 ledger'];

export default {
  data: {
    status: '全景登记：先拍 wide 全景，再说出登记名',
    wideLine: '左幅 WIDE：未登记',
    detailLine: '右幅 DETAIL：未拍（在细节拍页）',
    nameLine: '登记名：未命名（说错可重说纠错）',
    voiceLine: '语音：待命（选「语音命名」后开口）',
    selLine: '',
    menu: [],
    noteLine: '与慧眼区别：单拍不给结论，必须双拍配对＋分歧结算后才可落账',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._sel = 0; this._busy = false; this._steady = false; this._rec = null;
    this._render();
  },
  onShow() { this._render(); },
  onUnload() { this._stopAsr(); },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return {}; },
  _saveTmp(t) { try { wx.setStorageSync(TMP, t); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },

  _render() {
    const t = this._loadTmp();
    const rows = MENU.map((label, i) => ({ idx: i, label: (i === this._sel ? '▶ ' : '· ') + label, cls: i === this._sel ? 'mrow sel' : 'mrow' }));
    this.setData({
      menu: rows,
      selLine: '选中 ' + (this._sel + 1) + '/5：' + MENU[this._sel],
      wideLine: '左幅 WIDE：' + (t.wide ? ('已登记 · ' + (t.wideBytes || 0) + ' B · wide') : '未登记'),
      detailLine: '右幅 DETAIL：' + (t.detail ? ('已拍 · ' + (t.detailBytes || 0) + ' B · telephoto') : '未拍（在细节拍页）'),
      nameLine: '登记名：' + (t.name ? t.name : '未命名（说错可重说纠错）')
    });
  },

  _blobToDataUrl(blob) {
    return new Promise((resolve, reject) => {
      try { const r = new FileReader(); r.onload = () => resolve(r.result); r.onerror = () => reject(new Error('read fail')); r.readAsDataURL(blob); } catch (e) { reject(e); }
    });
  },
  async _shrink(blob) {
    // Shrink to width 480 via canvas; any failure falls back to the
    // original photo dataURL and says so in the returned note.
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
  async _takePhoto(mode) {
    const nav = (typeof navigator !== 'undefined') ? navigator : null;
    if (!nav || !nav.mediaDevices || !nav.mediaDevices.getUserMedia) throw new Error('getUserMedia 不可用');
    if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture 不可用');
    const stream = await nav.mediaDevices.getUserMedia({ video: true });
    try {
      const track = stream.getVideoTracks()[0];
      const cap = new ImageCapture(track);
      const blob = await cap.takePhoto({ mode: mode });
      if (!blob) throw new Error('未取得照片 Blob');
      return blob;
    } finally {
      try { stream.getTracks().forEach((tr) => { try { tr.stop(); } catch (e) {} }); } catch (e) {}
    }
  },

  async captureTap() {
    if (this._busy) return;
    this._busy = true;
    this.setData({ status: '正在拍 wide 全景…', evt: 'EVT: wide capture start' });
    try {
      const blob = await this._takePhoto('wide');
      const shr = await this._shrink(blob);
      const t = this._loadTmp();
      t.wide = shr.url; t.wideBytes = blob.size; t.wideNote = shr.note;
      this._saveTmp(t);
      this.setData({ status: '全景已登记（' + shr.note + '）', evt: 'EVT: wide saved ' + blob.size + 'B' });
      this._speak('全景已登记');
    } catch (e) {
      this.setData({ status: '全景拍摄失败：' + this._err(e) + '（Web 预览无相机时如实失败）', evt: 'EVT: wide FAIL ' + this._err(e) });
    } finally { this._busy = false; this._render(); }
  },

  _stopAsr() { try { if (this._rec) { this._rec.stop(); this._rec = null; } } catch (e) {} },
  nameTap() {
    try {
      if (typeof SpeechRecognition === 'undefined') { this.setData({ voiceLine: '语音：本机无 SpeechRecognition，命名不可用（如实）', evt: 'EVT: ASR unavailable' }); return; }
      this._stopAsr();
      const rec = new SpeechRecognition();
      rec.interimResults = true;
      const self = this;
      rec.onresult = function (e) {
        try {
          const tr = e.results[e.resultIndex][0].transcript;
          const isFinal = e.results[e.resultIndex].isFinal;
          self.setData({ voiceLine: '语音听写：' + tr + (isFinal ? '（定稿）' : '（中间）') });
          if (isFinal && tr) {
            const t = self._loadTmp(); t.name = String(tr).slice(0, 24); self._saveTmp(t);
            self.setData({ evt: 'EVT: name set ' + t.name });
            self._speak('登记名 ' + t.name);
            self._render();
          }
        } catch (err) {}
      };
      rec.onerror = function (ev) { self.setData({ voiceLine: '语音失败：' + String((ev && ev.error) || 'error') + '，可重说纠错', evt: 'EVT: ASR error' }); };
      rec.onend = function () { self._rec = null; };
      this._rec = rec;
      rec.start();
      this.setData({ voiceLine: '语音：聆听中，请说出登记名…', evt: 'EVT: ASR listening for name' });
    } catch (e) { this.setData({ voiceLine: '语音启动失败：' + this._err(e), evt: 'EVT: ASR start FAIL' }); }
  },

  detailTap() { try { wx.navigateTo({ url: '/pages/detail/index' }); } catch (e) {} },
  verifyTap() { try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (e) {} },
  ledgerTap() { try { wx.navigateTo({ url: '/pages/ledger/index' }); } catch (e) {} },
  rowTap(e) {
    const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN;
    if (isNaN(idx)) return;
    this._sel = idx; this._render(); this.doSel();
  },
  doSel() {
    if (this._sel === 0) this.captureTap();
    else if (this._sel === 1) this.nameTap();
    else if (this._sel === 2) this.detailTap();
    else if (this._sel === 3) this.verifyTap();
    else this.ledgerTap();
  },
  moveTap(d) { this._sel = (this._sel + d + MENU.length) % MENU.length; this.setData({ evt: 'EVT: select ' + MENU[this._sel] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doSel(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (k === 'Enter') { this.doSel(); }
    else if (k === 'ArrowUp') { this.moveTap(-1); }
    else if (k === 'ArrowDown') { this.moveTap(1); }
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) if (event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">Dual Shot Verify · 全景登记</text>
    <text class="status">{{status}}</text>
    <view class="dual">
      <view class="frame"><text class="flabel">{{wideLine}}</text></view>
      <view class="frame"><text class="flabel">{{detailLine}}</text></view>
    </view>
    <text class="line">{{nameLine}}</text>
    <text class="line dim">{{voiceLine}}</text>
    <view class="menu">
      <view ink:for="{{menu}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}"><text class="mtxt">{{item.label}}</text></view>
    </view>
    <text class="line dim">{{selLine}}</text>
    <text class="note">{{noteLine}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.dual { display: flex; flex-direction: row; gap: 8px; margin-top: 4px; }
.frame { flex-grow: 1; border: 2px solid rgba(125,255,158,0.72); background-color: #04140a; border-radius: 2px; padding: 6px; min-height: 52px; }
.flabel { color: #7dff9e; font-size: 11px; line-height: 15px; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.menu { display: flex; flex-direction: column; margin-top: 5px; border-top: 1px solid rgba(64,255,94,0.35); }
.mrow { padding: 4px 6px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.mrow.sel { background-color: #0a1f0e; border-left: 4px solid #40ff5e; }
.mtxt { color: #7dff9e; font-size: 12px; line-height: 16px; }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
