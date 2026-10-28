<script def>
{"title": "Dual Shot Verify"}
</script>

<script setup>
import wx from 'wx';

// AV08 ledger: filing gate + persistent archive av08_records.
// Only a completed, agreeing verification (verdict ok) may be filed.
// Voice correction: saying the rerun keyword jumps back to verify.
const TMP = 'av08_tmp';
const KEY = 'av08_records';
const ACTS = ['落账存档', '语音「重跑核验」', '清空存档', '返回 BACK'];

export default {
  data: {
    status: '落账：核验一致才可落账',
    gateLine: '门检：—',
    rows: [],
    countLine: '存档 0 条',
    voiceLine: '语音：待命（说「重跑核验」跳回核验页）',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._steady = false; this._rec = null; this._render(); },
  onShow() { this._render(); },
  onUnload() { this._stopAsr(); },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return {}; },
  _saveTmp(t) { try { wx.setStorageSync(TMP, t); } catch (e) {} },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) { const p = (typeof v === 'string') ? JSON.parse(v) : v; if (Array.isArray(p)) return p; } } catch (e) {} return []; },
  _save(a) { try { wx.setStorageSync(KEY, a); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const t = this._loadTmp();
    const v = t.verify || null;
    let gate = '门检：尚无核验结果，不可落账（置灰说明：先完成交叉核验）';
    if (v && v.verdict === 'ok' && !t.saved) gate = '门检：核验完成且一致，可落账';
    else if (v && v.verdict === 'ok' && t.saved) gate = '门检：本轮已落账';
    else if (v && v.verdict === 'mismatch') gate = '门检：两拍不一致，不可落账，请复核后重跑核验';
    else if (v) gate = '门检：核验未完成，不可落账';
    const recs = this._load();
    const rows = recs.slice(-6).reverse().map((r) => ({ text: (r.time || '').slice(5, 16) + ' · ' + (r.name || '未命名') + ' · ' + (r.verdictText || r.verdict || '') }));
    this.setData({ gateLine: gate, rows: rows, countLine: '存档 ' + recs.length + ' 条（持久化 ' + KEY + '）', focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）' });
  },
  saveTap() {
    const t = this._loadTmp();
    const v = t.verify || null;
    if (!v || v.verdict !== 'ok') {
      this.setData({ status: '不可落账：' + (!v ? '尚无核验结果' : (v.verdict === 'mismatch' ? '两拍不一致' : '核验未完成')), evt: 'EVT: file refused' });
      this._speak('还不能落账');
      return;
    }
    if (t.saved) { this.setData({ status: '本轮已落账，不重复写入', evt: 'EVT: file refused - already saved' }); return; }
    const recs = this._load();
    recs.push({ name: t.name || '未命名', r1: v.r1 || '', r2: v.r2 || '', verdict: v.verdict, verdictText: v.verdictText || '', time: new Date().toISOString() });
    this._save(recs);
    t.saved = true; this._saveTmp(t);
    this.setData({ status: '已落账存档', evt: 'EVT: filed, total ' + recs.length });
    this._speak('已落账');
    this._render();
  },
  clearTap() { this._save([]); this.setData({ status: '存档已清空（本人操作）', evt: 'EVT: archive cleared' }); this._render(); },
  _stopAsr() { try { if (this._rec) { this._rec.stop(); this._rec = null; } } catch (e) {} },
  voiceTap() {
    try {
      if (typeof SpeechRecognition === 'undefined') { this.setData({ voiceLine: '语音：本机无 SpeechRecognition（如实）', evt: 'EVT: ASR unavailable' }); return; }
      this._stopAsr();
      const rec = new SpeechRecognition();
      rec.interimResults = true;
      const self = this;
      rec.onresult = function (e) {
        try {
          const tr = e.results[e.resultIndex][0].transcript;
          self.setData({ voiceLine: '语音听写：' + tr });
          if (e.results[e.resultIndex].isFinal && tr && tr.indexOf('重跑核验') >= 0) {
            self.setData({ evt: 'EVT: voice rerun -> verify' });
            try { wx.navigateTo({ url: '/pages/verify/index' }); } catch (err) {}
          }
        } catch (err) {}
      };
      rec.onerror = function (ev) { self.setData({ voiceLine: '语音失败：' + String((ev && ev.error) || 'error'), evt: 'EVT: ASR error' }); };
      rec.onend = function () { self._rec = null; };
      this._rec = rec; rec.start();
      this.setData({ voiceLine: '语音：聆听中，说「重跑核验」…', evt: 'EVT: ASR listening' });
    } catch (e) { this.setData({ voiceLine: '语音启动失败：' + this._err(e), evt: 'EVT: ASR start FAIL' }); }
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.saveTap(); else if (this._focus === 1) this.voiceTap(); else if (this._focus === 2) this.clearTap(); else this.backTap(); },
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
    <text class="title">Dual Shot Verify · 落账</text>
    <text class="status">{{status}}</text>
    <text class="gate">{{gateLine}}</text>
    <view class="list">
      <view ink:for="{{rows}}" class="row"><text class="rtxt">{{item.text}}</text></view>
    </view>
    <text class="line dim">{{countLine}}</text>
    <button class="banner" bindtap="actTap" data-idx="0">落账存档</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">语音「重跑核验」</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">清空存档</button>
    <button class="banner ghost" bindtap="actTap" data-idx="3">BACK 返回</button>
    <text class="line dim">{{voiceLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.gate { color: #7dff9e; font-size: 11px; line-height: 15px; margin-top: 2px; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 4px 6px; }
.list { display: flex; flex-direction: column; margin-top: 5px; min-height: 60px; }
.row { padding: 3px 4px; border-bottom: 1px solid rgba(64,255,94,0.22); }
.rtxt { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; }
.banner { color: #04140a; background-color: #40ff5e; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
