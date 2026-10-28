<script def>
{"title": "AV Sync Check"}
</script>

<script setup>
import wx from 'wx';

// AV09 judge: fixed thresholds, shown on screen, applied to the
// measurements handed over from the sync page via av09_tmp.
// Passing report is appended to persistent av09_reports.
const TMP = 'av09_tmp';
const KEY = 'av09_reports';
const ACTS = ['判定并保存', '返回 BACK'];

export default {
  data: {
    status: '判定：按写死标准逐项过线',
    fpsLine: '帧率估算：—（标准 ≥10 fps）',
    gapLine: '最大帧间隔：—（标准 ≤500 ms）',
    rmsLine: '音频 RMS 均值：—（标准 ≥0.01）',
    deltaLine: 'delta 中位：—（标准 |中位| ≤300 ms）',
    verdictLine: '总判定：未判定',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() { this._focus = 0; this._steady = false; this._render(); },
  onShow() { this._render(); },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) { const p = (typeof v === 'string') ? JSON.parse(v) : v; if (Array.isArray(p)) return p; } } catch (e) {} return []; },
  _save(a) { try { wx.setStorageSync(KEY, a); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _stats() {
    const t = this._loadTmp();
    if (!t || !Array.isArray(t.gaps) || !t.gaps.length) return null;
    const gaps = t.gaps.slice().sort((a, b) => a - b);
    const med = gaps[Math.floor(gaps.length / 2)];
    const max = gaps[gaps.length - 1];
    const fps = med > 0 ? Math.round((1000 / med) * 10) / 10 : 0;
    const rmsMean = t.rmsN ? (t.rmsSum / t.rmsN) : 0;
    return { fps: fps, medGap: med, maxGap: max, rmsMean: Math.round(rmsMean * 1000) / 1000, deltaMedian: (t.deltaMedian === undefined ? null : t.deltaMedian), events: (t.events || []).length };
  },
  _render() {
    const s = this._stats();
    if (!s) { this.setData({ status: '判定：尚无采样数据（先去同步事件页做满采样）', focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）' }); return; }
    const okF = s.fps >= 10; const okG = s.maxGap <= 500; const okR = s.rmsMean >= 0.01; const okD = s.deltaMedian !== null && Math.abs(s.deltaMedian) <= 300;
    this.setData({
      fpsLine: '帧率估算：' + s.fps + ' fps（标准 ≥10）' + (okF ? ' ✓' : ' ✗'),
      gapLine: '最大帧间隔：' + s.maxGap + ' ms（标准 ≤500，丢帧指标）' + (okG ? ' ✓' : ' ✗'),
      rmsLine: '音频 RMS 均值：' + s.rmsMean + '（标准 ≥0.01）' + (okR ? ' ✓' : ' ✗'),
      deltaLine: 'delta 中位：' + (s.deltaMedian === null ? '无（未检出尖峰）' : (s.deltaMedian + ' ms')) + '（标准 |中位| ≤300）' + (okD ? ' ✓' : ' ✗'),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  judgeTap() {
    const s = this._stats();
    if (!s) { this.setData({ status: '无数据不可判定（如实，不编造）', evt: 'EVT: judge refused - no data' }); this._speak('还没有采样数据'); return; }
    const okF = s.fps >= 10; const okG = s.maxGap <= 500; const okR = s.rmsMean >= 0.01; const okD = s.deltaMedian !== null && Math.abs(s.deltaMedian) <= 300;
    const pass = okF && okG && okR && okD;
    const verdict = pass ? '通过' : '未通过';
    const recs = this._load();
    recs.push({ time: new Date().toISOString(), verdict: verdict, fps: s.fps, maxGap: s.maxGap, rmsMean: s.rmsMean, deltaMedian: s.deltaMedian });
    this._save(recs);
    this.setData({ status: '已判定并写入历史（' + KEY + '）', verdictLine: '总判定：' + verdict + '（帧率' + (okF ? '✓' : '✗') + ' 间隔' + (okG ? '✓' : '✗') + ' RMS' + (okR ? '✓' : '✗') + ' delta' + (okD ? '✓' : '✗') + '）', evt: 'EVT: judged ' + verdict });
    this._speak('声画同步判定' + verdict);
    this._render();
    this.setData({ verdictLine: '总判定：' + verdict + '（帧率' + (okF ? '✓' : '✗') + ' 间隔' + (okG ? '✓' : '✗') + ' RMS' + (okR ? '✓' : '✗') + ' delta' + (okD ? '✓' : '✗') + '）' });
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.judgeTap(); else this.backTap(); },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },

  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = (d.isStable === true || d.stable === true); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.judgeTap(); },
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
    <text class="title">AV Sync Check · 判定</text>
    <text class="status">{{status}}</text>
    <view class="panel">
      <text class="pline">{{fpsLine}}</text>
      <text class="pline">{{gapLine}}</text>
      <text class="pline">{{rmsLine}}</text>
      <text class="pline">{{deltaLine}}</text>
    </view>
    <view class="verdict"><text class="vtxt">{{verdictLine}}</text></view>
    <button class="dash main" bindtap="actTap" data-idx="0">判定并保存</button>
    <button class="dash" bindtap="actTap" data-idx="1">BACK 返回</button>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">标准写死并上屏：帧率估算≥10fps、最大帧间隔≤500ms、RMS均值≥0.01、|delta中位|≤300ms，四项全过才算通过。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.panel { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 5px 8px; margin-top: 5px; }
.pline { color: rgba(125,255,158,0.9); font-size: 12px; line-height: 17px; }
.verdict { background-color: #0a1f0e; border-left: 5px solid #40ff5e; padding: 5px 7px; margin-top: 5px; }
.vtxt { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 17px; }
.dash { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.65); border-radius: 8px; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.dash.main { color: #04140a; background-color: #40ff5e; }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
