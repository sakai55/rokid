<script def>
{"title": "Trace Knots"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { KNOTS } from '../../knots.js';

// TR05 验形页：把打好的这一步举到眼前拍照，LLM 按固定提示词合同
// 判定——对照范本描述 → 只查清单内粗项（圈数 / 穿向 / 收尾位置）→
// 输出结构化判定 {pass, issues[], confidence} → 看不清就说看不清。
// 判定后用户覆盖口三选：算过 / 不算过 / 重拍，覆盖落盘。
// 步只在「算过」时 +1；机器说不过而用户坚持算过，记一次本人改判。
const PROG = 'trace.trace-knots.v1';
const TMP = 'trace.knots.tmp';
const ACTS = ['拍照验形（或点头）', '算过，进下一步', '不算过，重做这步', '重拍', '回看范本', 'BACK'];
const SYS = '你是绳结练习的粗查员，只查指定的粗项，不评美观、不打分。照片看不清就如实说看不清，绝不编造。';

export default {
  data: {
    status: '验形：把这一步的绳举到眼前，结形入框再拍',
    targetLine: '',
    checksLine: '',
    passLine: '',
    issuesLine: '',
    confLine: '',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    const t = loadKey(TMP, { knot: KNOTS[0].id });
    this._knot = KNOTS.filter(function (w) { return w.id === t.knot; })[0] || KNOTS[0];
    this._render();
  },
  onShow() { this._render(); },
  _step() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const rec = (p.done || {})[this._knot.id] || { step: 0 };
    return Math.min(rec.step || 0, this._knot.steps.length);
  },
  _verdict() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const v = p.lastVerdict;
    if (v && v.knot === this._knot.id && v.step === this._step()) return v;
    return null;
  },
  _render() {
    const w = this._knot;
    const st = this._step();
    const s = w.steps[Math.min(st, w.steps.length - 1)];
    const v = this._verdict();
    const ok = !!(v && v.clear);
    this.setData({
      targetLine: '第 ' + (st + 1) + ' 步 · ' + s.t + '——目标结形：' + s.target,
      checksLine: '本步粗查清单：' + s.checks.join('；'),
      passLine: ok ? ('判定：' + (v.passLLM ? '过' : '不过')) : '',
      issuesLine: ok ? ('差异：' + (v.issues.length ? v.issues.join('；') : '无')) : '',
      confLine: ok ? ('把握度：' + v.confidence) : '',
      sumLine: ok ? '最后你说了算：算过就进下一步，不算过就重做这步' : (v ? '上次判定没看清，请重拍' : '还没验：先拍照'),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _field(text, key) {
    if (!text) return '';
    const lines = String(text).split('\n');
    for (let i = 0; i < lines.length; i++) { const p = lines[i].indexOf(key + ':'); if (p >= 0) return lines[i].slice(p + key.length + 1).trim(); }
    return '';
  },
  async shootTap() {
    if (this._busy) return;
    this._busy = true;
    const w = this._knot;
    const st = this._step();
    const s = w.steps[Math.min(st, w.steps.length - 1)];
    this.setData({ status: '拍照中…把绳举稳、别挡光', evt: 'EVT: check shoot start ' + w.id + ' step ' + (st + 1) });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '已拍（' + shot.note + '），粗查中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '绳结「' + w.name + '」第 ' + (st + 1) + ' 步「' + s.t + '」完成后的目标结形是：' + s.target + '。本步粗查清单只限这三项：' + s.checks.join('；') + '。照片里是练习者手里的绳。若照片里看不清绳的形状，第一行只写 CLEAR: NO 并说明原因，后面不用答。若看得清，第一行写 CLEAR: YES，第二行写 PASS: 是或否（只查清单内粗项，粗项都对写 是，有一项不对写 否），第三行写 ISSUES: 不对的粗项（没有写 无，多项用分号隔开），第四行写 CONFIDENCE: 高或中或低。不要打分，不要评美观。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const clear = this._field(raw, 'CLEAR').toUpperCase();
      const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
      if (clear.indexOf('NO') >= 0) {
        p.lastVerdict = { knot: w.id, step: st, clear: false, raw: raw.slice(0, 300), at: new Date().toISOString() };
        saveKey(PROG, p);
        this.setData({ status: '没看清：把绳挪到画面中央、避开反光，再拍一次', evt: 'EVT: verdict CLEAR NO' });
        speak('没看清，请重新拍');
        return;
      }
      const passText = this._field(raw, 'PASS');
      const issuesText = this._field(raw, 'ISSUES');
      const passLLM = passText ? (passText.indexOf('是') >= 0 && passText.indexOf('否') < 0) : (issuesText === '' || issuesText === '无');
      const issues = (!issuesText || issuesText === '无') ? [] : issuesText.split(/；|;/).map(function (x) { return x.trim(); }).filter(function (x) { return x; });
      p.lastVerdict = {
        knot: w.id, step: st, clear: true, passLLM: passLLM,
        issues: issues, confidence: this._field(raw, 'CONFIDENCE') || '（未答）',
        raw: raw.slice(0, 300), at: new Date().toISOString()
      };
      saveKey(PROG, p);
      this.setData({ status: passLLM ? '粗查通过：点「算过」继续，或「不算过」重做' : '粗查说有问题：看差异，改好重拍，或你确认没问题点「算过」', evt: 'EVT: verdict saved passLLM=' + passLLM });
      speak(passLLM ? '这一步过了' : '粗查说有点问题，看一下再决定');
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this.setData({ status: '验形没成：' + code + '（如实报错，可重拍）', evt: 'EVT: check FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  nextTap() {
    const v = this._verdict();
    if (!v || !v.clear) { this.setData({ status: '先验这一步再进（没验过不许凭空算过）', evt: 'EVT: next refused - no verdict' }); return; }
    const w = this._knot;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    p.done = p.done || {};
    const rec = p.done[w.id] || { count: 0, step: 0, overrides: 0 };
    rec.step = (rec.step || 0) + 1;
    if (!v.passLLM) { rec.overrides = (rec.overrides || 0) + 1; rec.runOverrides = (rec.runOverrides || 0) + 1; }
    rec.lastAt = new Date().toISOString();
    p.done[w.id] = rec;
    p.lastItem = w.id;
    p.today = new Date().toISOString().slice(0, 10);
    delete p.lastVerdict;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存失败：E5001（进度没落盘）', evt: 'EVT: next save FAIL E5001' }); return; }
    const last = rec.step >= w.steps.length;
    this.setData({ status: last ? '全部步数验完，去结算' : '已进第 ' + (rec.step + 1) + ' 步', evt: 'EVT: advanced step ' + rec.step });
    speak(last ? '都打完了，去结算' : '下一步');
    try { wx.navigateTo({ url: last ? '/pages/finish/index' : '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  rejectTap() {
    const v = this._verdict();
    if (!v || !v.clear) { this.setData({ status: '先验这一步再选（没验过不许凭空定）', evt: 'EVT: reject refused - no verdict' }); return; }
    const w = this._knot;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    p.done = p.done || {};
    const rec = p.done[w.id] || { count: 0, step: 0, overrides: 0 };
    if (v.passLLM) { rec.overrides = (rec.overrides || 0) + 1; rec.runOverrides = (rec.runOverrides || 0) + 1; }
    rec.lastAt = new Date().toISOString();
    p.done[w.id] = rec;
    delete p.lastVerdict;
    saveKey(PROG, p);
    this.setData({ status: '已记不算过：回练习页重做这步' + (v.passLLM ? '（你推翻了机器的过，记一次改判）' : ''), evt: 'EVT: rejected step' });
    speak('重做这步');
    try { wx.navigateTo({ url: '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  retakeTap() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    delete p.lastVerdict;
    saveKey(PROG, p);
    this.setData({ status: '重拍：把绳举稳再拍', evt: 'EVT: retake' });
    this._render();
    this.shootTap();
  },
  practiceTap() { try { wx.navigateTo({ url: '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.shootTap();
    else if (this._focus === 1) this.nextTap();
    else if (this._focus === 2) this.rejectTap();
    else if (this._focus === 3) this.retakeTap();
    else if (this._focus === 4) this.practiceTap();
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') this.shootTap(); },
  onKeyDown(event) {
    var k = event.key || event.code;
    if (k === 'Enter') this.doAct();
    else if (k === 'ArrowUp') this.moveTap(-1);
    else if (k === 'ArrowDown') this.moveTap(1);
  },
  onKeyUp(event) { const k = event && event.key; if ((k === 'Enter' || k === 'ArrowUp' || k === 'ArrowDown') && event.preventDefault) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <text class="title">绳结描红 · 验形</text>
    <text class="status">{{status}}</text>
    <view class="knot-box">
      <text class="target">{{targetLine}}</text>
      <text class="line">{{checksLine}}</text>
      <text class="line dim">只查清单内粗项：圈数、穿向、收尾位置。判定会认错、会看不清——看不清会如实说；判定后你三选一：算过 / 不算过 / 重拍，覆盖落盘。</text>
    </view>
    <view class="verdict">
      <text class="line">{{passLine}}</text>
      <text class="line">{{issuesLine}}</text>
      <text class="line">{{confLine}}</text>
      <text class="line strong">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">拍照验形</button>
      <button class="tag" bindtap="actTap" data-idx="1">算过</button>
      <button class="tag" bindtap="actTap" data-idx="2">不算过</button>
      <button class="tag" bindtap="actTap" data-idx="3">重拍</button>
      <button class="tag" bindtap="actTap" data-idx="4">回看范本</button>
      <button class="tag" bindtap="actTap" data-idx="5">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR05</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.knot-box { border: 2px solid rgba(125,255,158,0.65); border-radius: 12px; background-color: #03130a; padding: 6px 8px; margin-top: 5px; }
.target { color: #7dff9e; font-size: 12px; line-height: 16px; }
.verdict { margin-top: 5px; min-height: 66px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.strong { color: #7dff9e; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 12px; padding: 5px 9px; font-size: 11px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
