<script def>
{"title": "Dual Shot Verify"}
</script>

<script setup>
import wx from 'wx';

// AV08 verify: one LLM session, three serial rounds (B8).
// Round 1 sees only the wide photo, round 2 only the detail photo,
// round 3 (promptStreaming, polled via read()) sees both photos plus
// the first two answers and settles agreement. A local field compare
// runs on top: any mismatch blocks filing and is announced by TTS.
const TMP = 'av08_tmp';
const ACTS = ['开始三轮核验', '语音：说「重跑核验」', '返回 BACK'];
const SYS = 'You judge photos for a two-shot verification. Reply only in the requested fixed format, transcribe only what is visible, never invent.';

export default {
  data: {
    status: '交叉核验：两图齐备后 Enter 开始三轮',
    gateLine: '门检：—',
    r1Line: '轮1（只看全景）：未跑',
    r2Line: '轮2（只看细节）：未跑',
    liveLine: '轮3流式：未跑',
    r3Line: '轮3（双图交叉）：未跑',
    verdictLine: '结论：未核验',
    voiceLine: '语音：待命',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.1'
  },
  onLoad() { this._focus = 0; this._busy = false; this._steady = false; this._rec = null; this._render(); },
  onShow() { this._render(); },
  onUnload() { this._stopAsr(); },

  _loadTmp() { try { const v = wx.getStorageSync(TMP); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return {}; },
  _saveTmp(t) { try { wx.setStorageSync(TMP, t); } catch (e) {} },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); } catch (e) {} },
  _err(e) { return String((e && (e.message || e.name)) || e || 'unknown').slice(0, 60); },
  _render() {
    const t = this._loadTmp();
    const miss = [];
    if (!t.wide) miss.push('全景');
    if (!t.detail) miss.push('细节');
    const v = t.verify || null;
    this.setData({
      gateLine: miss.length ? ('门检：缺' + miss.join('、') + '，禁止开始，请回前页补拍') : '门检：两图齐备，可开始',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）',
      verdictLine: v ? ('结论：' + v.verdictText) : '结论：未核验',
      r1Line: v && v.r1 ? ('轮1（只看全景）：' + v.r1) : '轮1（只看全景）：未跑',
      r2Line: v && v.r2 ? ('轮2（只看细节）：' + v.r2) : '轮2（只看细节）：未跑',
      r3Line: v && v.r3 ? ('轮3（双图交叉）：' + v.r3) : '轮3（双图交叉）：未跑'
    });
  },
  _field(text, key) {
    if (!text) return '';
    const lines = String(text).split('\n');
    for (let i = 0; i < lines.length; i++) {
      const p = lines[i].indexOf(key + ':');
      if (p >= 0) return lines[i].slice(p + key.length + 1).trim().toUpperCase();
    }
    return '';
  },

  async runTap() {
    if (this._busy) return;
    const t0 = this._loadTmp();
    if (!t0.wide || !t0.detail) {
      this.setData({ status: '缺图禁止开始：请回前页补拍', evt: 'EVT: verify refused - missing photo' });
      this._speak('还缺照片，请先补拍');
      return;
    }
    if (typeof LanguageModel === 'undefined' || !LanguageModel.availability) {
      const t = this._loadTmp(); t.verify = { done: false, verdict: 'incomplete', verdictText: '核验未完成（本机无 LanguageModel）', r1: '', r2: '', r3: '', time: new Date().toISOString() }; this._saveTmp(t);
      this.setData({ status: '核验未完成：本机无 LanguageModel（如实，不编造）', evt: 'EVT: LLM unavailable' });
      this._render(); return;
    }
    this._busy = true;
    let session = null;
    const res = { done: false, verdict: 'incomplete', verdictText: '核验未完成', r1: '', r2: '', r3: '', time: new Date().toISOString() };
    try {
      const avail = await LanguageModel.availability();
      if (avail !== 'available') throw new Error('LLM availability=' + avail);
      session = await LanguageModel.create({ initialPrompts: [{ role: 'system', content: SYS }] });
      const ask = '只看这一张照片，严格回答两行：第一行 ITEM: 品名；第二行 VALUE: 单号或关键数值。看不清写 NONE，不要解释。';
      this.setData({ status: '轮1 进行中（只发全景图）…', evt: 'EVT: round1 start' });
      res.r1 = String(await session.prompt([{ type: 'text', text: ask }, { type: 'image_url', image_url: { url: t0.wide } }])).slice(0, 220);
      this.setData({ r1Line: '轮1（只看全景）：' + res.r1, status: '轮2 进行中（只发细节图）…', evt: 'EVT: round1 done' });
      res.r2 = String(await session.prompt([{ type: 'text', text: ask }, { type: 'image_url', image_url: { url: t0.detail } }])).slice(0, 220);
      this.setData({ r2Line: '轮2（只看细节）：' + res.r2, status: '轮3 进行中（双图交叉，流式）…', evt: 'EVT: round2 done' });
      const crossText = '下面给两张照片（全景与细节）与前两轮判读。轮1：' + res.r1 + ' 轮2：' + res.r2 + ' 请交叉核对是否同一物品，严格回答两行：第一行 AGREE: YES 或 NO；第二行 DIFF: 分歧说明，无分歧写 NONE。';
      const stream = session.promptStreaming([{ type: 'text', text: crossText }, { type: 'image_url', image_url: { url: t0.wide } }, { type: 'image_url', image_url: { url: t0.detail } }]);
      let acc = '';
      while (true) {
        const r = await stream.read();
        if (r.done) break;
        if (r.value !== undefined && r.value !== null) { acc += String(r.value); this.setData({ liveLine: '轮3流式：' + acc.slice(0, 160) }); }
      }
      res.r3 = acc.slice(0, 220);
      this.setData({ r3Line: '轮3（双图交叉）：' + res.r3, evt: 'EVT: round3 done' });
      const i1 = this._field(res.r1, 'ITEM'); const v1 = this._field(res.r1, 'VALUE');
      const i2 = this._field(res.r2, 'ITEM'); const v2 = this._field(res.r2, 'VALUE');
      const agree = this._field(res.r3, 'AGREE');
      const fieldDiff = (i1 && i2 && i1 !== i2) || (v1 && v2 && v1 !== v2);
      if (fieldDiff || agree === 'NO') {
        res.done = true; res.verdict = 'mismatch'; res.verdictText = '两拍不一致（本地字段比对' + (fieldDiff ? '有差' : '一致') + '，轮3 AGREE=' + (agree || '未答') + '）';
        this.setData({ status: '两拍不一致：请复核，不要落账', evt: 'EVT: verdict MISMATCH' });
        this._speak('两拍不一致，请复核');
      } else if (agree === 'YES' && !fieldDiff) {
        res.done = true; res.verdict = 'ok'; res.verdictText = '可落账（双拍一致，轮3 AGREE=YES）';
        this.setData({ status: '核验完成：双拍一致，可落账', evt: 'EVT: verdict OK' });
        this._speak('核验一致，可落账');
      } else {
        res.done = false; res.verdict = 'incomplete'; res.verdictText = '核验未完成（轮3 未给出明确 AGREE）';
        this.setData({ status: '核验未完成：轮3 答复不明确，不落账', evt: 'EVT: verdict incomplete' });
      }
    } catch (e) {
      res.done = false; res.verdict = 'incomplete'; res.verdictText = '核验未完成（失败：' + this._err(e) + '）';
      this.setData({ status: '某一轮失败（如实标注）：' + this._err(e) + '，结论为核验未完成', evt: 'EVT: verify FAIL ' + this._err(e) });
    } finally {
      try { if (session && session.destroy) session.destroy(); } catch (e) {}
      const t = this._loadTmp(); t.verify = res; t.saved = false; this._saveTmp(t);
      this._busy = false; this._render();
    }
  },

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
          if (e.results[e.resultIndex].isFinal && tr && tr.indexOf('重跑核验') >= 0) { self.setData({ evt: 'EVT: voice command rerun' }); self.runTap(); }
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
  doAct() { if (this._focus === 0) this.runTap(); else if (this._focus === 1) this.voiceTap(); else this.backTap(); },
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
    <text class="title">Dual Shot Verify · 交叉核验</text>
    <text class="status">{{status}}</text>
    <text class="gate">{{gateLine}}</text>
    <view class="rounds">
      <text class="rline">{{r1Line}}</text>
      <text class="rline">{{r2Line}}</text>
      <text class="rline live">{{liveLine}}</text>
      <text class="rline">{{r3Line}}</text>
    </view>
    <view class="verdict"><text class="vtxt">{{verdictLine}}</text></view>
    <button class="banner" bindtap="actTap" data-idx="0">开始三轮核验</button>
    <button class="banner ghost" bindtap="actTap" data-idx="1">语音「重跑核验」</button>
    <button class="banner ghost" bindtap="actTap" data-idx="2">BACK 返回</button>
    <text class="line dim">{{voiceLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="note">单拍不给结论：必须双拍配对＋三轮交叉＋分歧结算。任一轮失败＝核验未完成，不落账。</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.gate { color: #7dff9e; font-size: 11px; line-height: 15px; margin-top: 2px; }
.rounds { display: flex; flex-direction: column; border: 1px solid rgba(64,255,94,0.4); background-color: #04140a; padding: 4px 7px; margin-top: 4px; }
.rline { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; }
.rline.live { color: #40ff5e; }
.verdict { background-color: #0a1f0e; border-left: 5px solid #40ff5e; padding: 5px 7px; margin-top: 5px; }
.vtxt { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 17px; }
.banner { color: #04140a; background-color: #40ff5e; padding: 6px; font-size: 13px; font-weight: 500; text-align: center; margin-top: 6px; }
.banner.ghost { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); }
.line { color: rgba(125,255,158,0.85); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.note { color: rgba(64,255,94,0.55); font-size: 10px; line-height: 13px; margin-top: 4px; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
