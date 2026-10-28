<script def>
{"title": "System Audio Capture"}
</script>

<script setup>
import wx from 'wx';

// AV10 transcribe: feed the recording into a recognition session.
// The session never opens a microphone: the recording (restored
// from the av10_tmp dataURL by base64 decoding, no fetch) is sliced
// by maxChunkBytes and written serially through the session writer,
// then the writer is closed. Interim/final results build the draft.
// Every step names itself on failure.
const TMP = 'av10_tmp';
const ACTS = ['开始转写', '返回 BACK'];
const MAXCHUNK = 16384;

export default {
  data: {
    status: '转写：把内录分片喂给识别会话（会话不开麦）',
    stepLine: '环节：待开始',
    draftLine: '文字稿：未转写',
    srcLine: '录音：未读临时键',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._busy = false; this._steady = false; this._session = null; this._render(); },
  onUnload() { try { if (this._session && this._session.close) this._session.close(); } catch (e) {} this._session = null; },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(t) { try { wx.setStorageSync(TMP, t); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const t = this._loadTmp();
    this.setData({
      srcLine: t && t.dataUrl ? ('录音：' + (t.size || 0) + ' B · ' + (t.mime || '') + ' · ' + (t.chunks || 0) + ' 片录制分片') : '录音：未读到（先去内录页录一段）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _blobFromDataUrl(dataUrl, mime) {
    const p = String(dataUrl).indexOf(',');
    if (p < 0) throw new Error('dataURL 格式不对');
    const b64 = String(dataUrl).slice(p + 1);
    const bin = atob(b64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new Blob([bytes], { type: mime || 'audio/ogg' });
  },
  _fail(step, e) {
    this.setData({ status: '转写失败于环节「' + step + '」：' + this._err(e) + '（如实，不编造文字稿）', stepLine: '环节：失败于 ' + step, evt: 'EVT: transcribe FAIL at ' + step });
  },

  async runTap() {
    if (this._busy) return;
    const t = this._loadTmp();
    if (!t || !t.dataUrl) { this.setData({ status: '无录音：先去内录页录一段再回来', evt: 'EVT: transcribe refused - no recording' }); return; }
    this._busy = true;
    let blob = null;
    try { this.setData({ stepLine: '环节：还原 Blob（atob 解 base64）' }); blob = this._blobFromDataUrl(t.dataUrl, t.mime); }
    catch (e) { this._fail('还原录音', e); this._busy = false; return; }
    let session = null;
    try {
      this.setData({ stepLine: '环节：建识别会话（查 getCapabilities 定 interim）' });
      if (typeof SpeechRecognitionSession === 'undefined') throw new Error('SpeechRecognitionSession 不可用');
      let interim = true;
      try {
        if (typeof SpeechRecognitionSession.getCapabilities === 'function') {
          const caps = await SpeechRecognitionSession.getCapabilities();
          if (caps && caps.interimResults === false) interim = false;
        }
      } catch (e) {}
      session = new SpeechRecognitionSession({ lang: 'zh-CN', interimResults: interim });
      this._session = session;
      let finalText = '';
      const self = this;
      const onRes = function (e) {
        try {
          let tr = '';
          let isFinal = false;
          if (e && e.results && e.resultIndex !== undefined) { const r = e.results[e.resultIndex]; tr = (r && r[0] && r[0].transcript) || ''; isFinal = !!(r && r.isFinal); }
          else if (e && typeof e.transcript === 'string') { tr = e.transcript; isFinal = e.isFinal === true || e.type === 'final'; }
          else if (e && e.detail && typeof e.detail.transcript === 'string') { tr = e.detail.transcript; isFinal = e.detail.isFinal === true; }
          if (!tr) return;
          if (isFinal) { finalText += tr; self.setData({ draftLine: '文字稿（定稿累积）：' + finalText }); }
          else self.setData({ draftLine: '文字稿（中间）：' + (finalText + tr) });
        } catch (err) {}
      };
      try { session.onresult = onRes; } catch (e) {}
      try { if (typeof session.addEventListener === 'function') session.addEventListener('result', onRes); } catch (e) {}
      let writer = null;
      if (session.writer) writer = session.writer;
      else if (typeof session.createWriter === 'function') writer = session.createWriter();
      else if (session.writable && typeof session.writable.getWriter === 'function') writer = session.writable.getWriter();
      if (!writer || typeof writer.write !== 'function') throw new Error('会话 writer 不可用');
      this.setData({ stepLine: '环节：分片写入（每片 ≤' + MAXCHUNK + ' B，串行）' });
      const total = blob.size;
      let off = 0; let n = 0;
      while (off < total) {
        const part = blob.slice(off, Math.min(total, off + MAXCHUNK));
        const buf = await part.arrayBuffer();
        await writer.write(buf);
        off += part.size; n++;
        this.setData({ stepLine: '环节：分片写入 ' + n + ' 片（' + off + '/' + total + ' B）' });
      }
      this.setData({ stepLine: '环节：关闭 writer，等待定稿' });
      try { if (typeof writer.close === 'function') await writer.close(); } catch (e) {}
      await new Promise((r) => setTimeout(r, 600));
      const draft = finalText || this.data.draftLine.replace('文字稿（中间）：', '').replace('文字稿：未转写', '');
      const t2 = this._loadTmp() || {};
      t2.transcript = (finalText || (draft === this.data.draftLine ? '' : draft) || '');
      this._saveTmp(t2);
      this.setData({
        status: t2.transcript ? '转写完成：文字稿已存临时键，去归档页' : '转写链走完但无定稿文字（如实：会话未回定稿）',
        stepLine: '环节：完成（写入 ' + n + ' 片）',
         draftLine: '文字稿：' + (t2.transcript || '（无定稿）'),
        evt: 'EVT: transcribe done, ' + n + ' chunks fed'
      });
      if (t2.transcript) this._speak('转写完成');
    } catch (e) {
      this._fail(this.data.stepLine.indexOf('写入') >= 0 ? '分片写入' : '建会话/取 writer', e);
    } finally {
      try { if (session && session.close) session.close(); } catch (e) {}
      this._session = null; this._busy = false; this._render();
    }
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.runTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.runTap(); },
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
    <text class="title">System Audio Capture · 转写</text>
    <text class="status">{{status}}</text>
    <text class="line">{{srcLine}}</text>
    <view class="wavebox">
      <text class="wline">{{stepLine}}</text>
      <text class="draft">{{draftLine}}</text>
    </view>
    <button class="wide" bindtap="actTap" data-idx="0">开始转写</button>
    <button class="wide alt" bindtap="actTap" data-idx="1">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">会话不开麦：喂进去的是内录的设备播放声，不是环境声。录的是设备自身播放声，与会议转写的区别在来源门。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.wavebox { border: 1px solid rgba(125,255,158,0.6); background-color: #04140a; padding: 6px 8px; margin-top: 5px; }
.wline { color: rgba(125,255,158,0.9); font-size: 11px; line-height: 15px; }
.draft { color: #7dff9e; font-size: 12px; line-height: 17px; margin-top: 3px; }
.wide { color: #04140a; background-color: #40ff5e; padding: 7px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 7px; }
.wide.alt { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
