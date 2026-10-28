<script def>
{"title": "System Audio Capture"}
</script>

<script setup>
import wx from 'wx';

// AV10 archive: persistent filing av10_archive plus playback.
// Filing stores time, estimated duration, full transcript and byte
// size. Playback restores the Blob from the temp dataURL (atob, no
// fetch), decodes it with decodeAudioData and plays it through a
// buffer source - the Web Audio decode playback path, labelled so.
const TMP = 'av10_tmp';
const KEY = 'av10_archive';
const ACTS = ['归档存档', '回放原录', '停止回放', '清空归档', '返回 BACK'];

export default {
  data: {
    status: '归档：转写完成后把全文与录音信息存档',
    gateLine: '门检：—',
    playLine: '回放：未播（Web Audio 解码播放路径）',
    rows: [],
    countLine: '归档 0 条',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() { this._focus = 0; this._steady = false; this._ctx = null; this._src = null; this._render(); },
  onShow() { this._render(); },
  onUnload() { this.stopPlay(); try { if (this._ctx) { this._ctx.close(); this._ctx = null; } } catch (e) {} },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) { const p = (typeof v === 'string') ? JSON.parse(v) : v; if (Array.isArray(p)) return p; } } catch (e) {} return []; },
  _save(a) { try { wx.setStorageSync(KEY, a); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const t = this._loadTmp();
    let gate = '门检：尚无内录（先完成内录与转写）';
    if (t && t.dataUrl && t.transcript) gate = '门检：录音与转写全文齐备，可归档';
    else if (t && t.dataUrl) gate = '门检：有录音但无转写全文，归档将如实存空稿（先去转写页）';
    const recs = this._load();
    const rows = recs.slice(-5).reverse().map((r) => ({ text: (r.time || '').slice(5, 16) + ' · ' + (r.durationText || '') + ' · ' + (r.size || 0) + 'B · ' + String(r.transcript || '').slice(0, 26) }));
    this.setData({ gateLine: gate, rows: rows, countLine: '归档 ' + recs.length + ' 条（持久化 ' + KEY + '）', focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）' });
  },
  _blobFromDataUrl(dataUrl, mime) {
    const p = String(dataUrl).indexOf(',');
    if (p < 0) throw new Error('dataURL 格式不对');
    const bin = atob(String(dataUrl).slice(p + 1));
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new Blob([bytes], { type: mime || 'audio/ogg' });
  },
  async _durationOf(blob) {
    // Returns display text: decoded duration when the Web Audio
    // decode path works, an honest unknown otherwise.
    try {
      const AC = (typeof AudioContext !== 'undefined') ? AudioContext : null;
      if (!AC) return '时长未知（无 AudioContext）';
      const ctx = new AC();
      try {
        const ab = await blob.arrayBuffer();
        const audioBuf = await ctx.decodeAudioData(ab);
        return '时长约 ' + (Math.round(audioBuf.duration * 10) / 10) + 's（解码实测）';
      } finally { try { ctx.close(); } catch (e) {} }
    } catch (e) { return '时长未知（解码失败：' + this._err(e) + '）'; }
  },
  async saveTap() {
    const t = this._loadTmp();
    if (!t || !t.dataUrl) { this.setData({ status: '不可归档：尚无内录', evt: 'EVT: archive refused - no recording' }); return; }
    const blob = (() => { try { return this._blobFromDataUrl(t.dataUrl, t.mime); } catch (e) { return null; } })();
    const durText = blob ? await this._durationOf(blob) : '时长未知（录音还原失败）';
    const recs = this._load();
    recs.push({ time: new Date().toISOString(), durationText: durText, transcript: t.transcript || '', size: t.size || (blob ? blob.size : 0) });
    this._save(recs);
    this.setData({ status: '已归档：' + durText, evt: 'EVT: archived, total ' + recs.length });
    this._speak('已归档');
    this._render();
  },
  async playTap() {
    const t = this._loadTmp();
    if (!t || !t.dataUrl) { this.setData({ playLine: '回放：无录音可播（先内录）', evt: 'EVT: play refused - no recording' }); return; }
    try {
      this.stopPlay();
      const AC = (typeof AudioContext !== 'undefined') ? AudioContext : null;
      if (!AC) throw new Error('AudioContext 不可用');
      if (!this._ctx) this._ctx = new AC();
      const blob = this._blobFromDataUrl(t.dataUrl, t.mime);
      const ab = await blob.arrayBuffer();
      const audioBuf = await this._ctx.decodeAudioData(ab);
      const src = this._ctx.createBufferSource();
      src.buffer = audioBuf;
      src.connect(this._ctx.destination);
      src.start();
      this._src = src;
      this.setData({ playLine: '回放：播放中（Web Audio 解码播放路径，时长约 ' + (Math.round(audioBuf.duration * 10) / 10) + 's，可停）', evt: 'EVT: playback started' });
    } catch (e) {
      this.setData({ playLine: '回放失败：' + this._err(e) + '（解码播放路径如实）', evt: 'EVT: play FAIL ' + this._err(e) });
    }
  },
  stopPlay() {
    try { if (this._src) { this._src.stop(); this._src = null; this.setData({ playLine: '回放：已停' }); } } catch (e) {}
  },
  clearTap() { this._save([]); this.setData({ status: '归档已清空（本人操作）', evt: 'EVT: archive cleared' }); this._render(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.saveTap(); else if (this._focus === 1) this.playTap(); else if (this._focus === 2) this.stopPlay(); else if (this._focus === 3) this.clearTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.doAct(); },
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
    <text class="title">System Audio Capture · 归档</text>
    <text class="status">{{status}}</text>
    <text class="gate">{{gateLine}}</text>
    <text class="line">{{playLine}}</text>
    <view class="list">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <text class="line dim">{{countLine}}</text>
    <button class="wide" bindtap="actTap" data-idx="0">归档存档</button>
    <button class="wide alt" bindtap="actTap" data-idx="1">回放原录</button>
    <button class="wide alt" bindtap="actTap" data-idx="2">停止回放</button>
    <button class="wide alt" bindtap="actTap" data-idx="3">清空归档</button>
    <button class="wide alt" bindtap="actTap" data-idx="4">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">回放走 Web Audio 解码播放路径：dataURL 还原 Blob → decodeAudioData → buffer source 播放。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.gate { color: #7dff9e; font-size: 11px; line-height: 15px; margin-top: 2px; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 4px 6px; }
.list { display: flex; flex-direction: column; margin-top: 5px; min-height: 56px; }
.row { padding: 3px 4px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.rtxt { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; }
.wide { color: #04140a; background-color: #40ff5e; padding: 7px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.wide.alt { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
