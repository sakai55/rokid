<script def>
{"title": "Trace Plating"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { PLATINGS } from '../../platings.js';

// TR07 对位页（自评描红，PLAN §6 降级规则先行）：把摆好的这一步举
// 到眼前拍照，LLM 只给三粗项差异提示（主菜落位 / 色块分区 / 留白
// 边距），不判过与不过；过与不过由用户自定。用户三选：算过 /
// 再摆一张 / 跳过。算过进下一步（记自判）；跳过也进下一步，但记
// 一次跳过与一次改判（本人绕过对位）；再摆一张只重拍。
// 警示：若判定只能复述盘子里有什么，即退化为慧眼问答，本台不以
// 此计数——本页提示词只许答三粗项差异，不许复述盘中菜品。
const PROG = 'trace.trace-plating.v1';
const TMP = 'trace.plating.tmp';
const ACTS = ['拍照对位（或点头）', '算过，进下一步', '再摆一张', '跳过这步', '回看范本', 'BACK'];
const SYS = '你是摆盘练习的差异提示员，只提示指定的三项粗项差异，不判过与不过，不打分，不复述盘子里有什么菜。照片看不清就如实说看不清，绝不编造。';

export default {
  data: {
    status: '对位：把这一步的盘举到眼前，盘面入框再拍',
    targetLine: '',
    placeLine: '',
    zoneLine: '',
    marginLine: '',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    const t = loadKey(TMP, { plating: PLATINGS[0].id });
    this._plating = PLATINGS.filter(function (w) { return w.id === t.plating; })[0] || PLATINGS[0];
    this._render();
  },
  onShow() { this._render(); },
  _step() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const rec = (p.done || {})[this._plating.id] || { step: 0 };
    return Math.min(rec.step || 0, this._plating.steps.length);
  },
  _hint() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    const v = p.lastHint;
    if (v && v.plating === this._plating.id && v.step === this._step()) return v;
    return null;
  },
  _render() {
    const w = this._plating;
    const st = this._step();
    const s = w.steps[Math.min(st, w.steps.length - 1)];
    const v = this._hint();
    const ok = !!(v && v.clear);
    this.setData({
      targetLine: '第 ' + (st + 1) + ' 步 · ' + s.t + '——目标摆位：' + s.target,
      placeLine: ok ? ('主菜落位差异：' + v.place) : '',
      zoneLine: ok ? ('色块分区差异：' + v.zone) : '',
      marginLine: ok ? ('留白边距差异：' + v.margin) : '',
      sumLine: ok ? '自评：看三项差异，你说了算——算过就进下一步，再摆一张就重摆重拍，跳过也进下一步但会记跳过' : (v ? '上次提示没看清，请重拍' : '还没对位：先拍照'),
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
  },
  _field(text, key) {
    if (!text) return '';
    const lines = String(text).split('\n');
    for (let i = 0; i < lines.length; i++) {
      let p = lines[i].indexOf(key + ':');
      if (p >= 0) return lines[i].slice(p + key.length + 1).trim();
      p = lines[i].indexOf(key + '：');
      if (p >= 0) return lines[i].slice(p + key.length + 1).trim();
    }
    return '';
  },
  async shootTap() {
    if (this._busy) return;
    this._busy = true;
    const w = this._plating;
    const st = this._step();
    const s = w.steps[Math.min(st, w.steps.length - 1)];
    this.setData({ status: '拍照中…把盘举稳、别挡光', evt: 'EVT: check shoot start ' + w.id + ' step ' + (st + 1) });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '已拍（' + shot.note + '），对位提示中…', evt: 'EVT: shot ' + shot.bytes + 'B hint start' });
      const ask = '摆盘构图「' + w.name + '」第 ' + (st + 1) + ' 步「' + s.t + '」完成后的目标摆位是：' + s.target + '。照片里是练习者摆的盘。若照片里看不清盘面，第一行只写 CLEAR: NO 并说明原因，后面不用答。若看得清，第一行写 CLEAR: YES，再只答三行差异提示，不判过与不过，不复述盘子里有什么菜：第二行 主菜落位：主菜位置与目标差在哪（无差异写 无差异）；第三行 色块分区：色块分区与目标差在哪（无差异写 无差异）；第四行 留白边距：盘边留白与目标差在哪（无差异写 无差异）。不要打分，不要评美观。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const clear = this._field(raw, 'CLEAR').toUpperCase();
      const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
      if (clear.indexOf('NO') >= 0) {
        p.lastHint = { plating: w.id, step: st, clear: false, raw: raw.slice(0, 300), at: new Date().toISOString() };
        saveKey(PROG, p);
        this.setData({ status: '没看清：把盘挪到画面中央、避开反光，再拍一次', evt: 'EVT: hint CLEAR NO' });
        speak('没看清，请重新拍');
        return;
      }
      p.lastHint = {
        plating: w.id, step: st, clear: true,
        place: this._field(raw, '主菜落位') || '（未答）',
        zone: this._field(raw, '色块分区') || '（未答）',
        margin: this._field(raw, '留白边距') || '（未答）',
        raw: raw.slice(0, 300), at: new Date().toISOString()
      };
      saveKey(PROG, p);
      this.setData({ status: '差异提示已出：看三项，你自定算过、再摆一张还是跳过', evt: 'EVT: hint saved' });
      speak('差异提示出来了，你自己定');
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this.setData({ status: '对位没成：' + code + '（如实报错，可重拍）', evt: 'EVT: check FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  _advance(selfPass) {
    const w = this._plating;
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    p.done = p.done || {};
    const rec = p.done[w.id] || { count: 0, step: 0, overrides: 0 };
    rec.step = (rec.step || 0) + 1;
    if (selfPass) { rec.selfPass = (rec.selfPass || 0) + 1; }
    else { rec.skips = (rec.skips || 0) + 1; rec.overrides = (rec.overrides || 0) + 1; rec.runOverrides = (rec.runOverrides || 0) + 1; }
    rec.lastAt = new Date().toISOString();
    p.done[w.id] = rec;
    p.lastItem = w.id;
    p.today = new Date().toISOString().slice(0, 10);
    delete p.lastHint;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存失败：E5001（进度没落盘）', evt: 'EVT: advance save FAIL E5001' }); return; }
    const last = rec.step >= w.steps.length;
    this.setData({ status: last ? '全部步数对完，去结算' : '已进第 ' + (rec.step + 1) + ' 步' + (selfPass ? '' : '（跳过已记）'), evt: 'EVT: advanced step ' + rec.step });
    speak(last ? '都摆完了，去结算' : '下一步');
    try { wx.navigateTo({ url: last ? '/pages/finish/index' : '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  passTap() {
    const v = this._hint();
    if (!v || !v.clear) { this.setData({ status: '先拍一张看差异提示再算过（没对位不许凭空算过）', evt: 'EVT: pass refused - no hint' }); return; }
    this._advance(true);
  },
  againTap() {
    const p = loadKey(PROG, { done: {}, today: '', lastItem: '' });
    delete p.lastHint;
    saveKey(PROG, p);
    this.setData({ status: '再摆一张：调好摆位再拍', evt: 'EVT: again' });
    this._render();
    this.shootTap();
  },
  skipTap() {
    this._advance(false);
  },
  practiceTap() { try { wx.navigateTo({ url: '/pages/practice/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.shootTap();
    else if (this._focus === 1) this.passTap();
    else if (this._focus === 2) this.againTap();
    else if (this._focus === 3) this.skipTap();
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
    <text class="title">摆盘描红 · 对位</text>
    <text class="status">{{status}}</text>
    <view class="plate-box">
      <text class="target">{{targetLine}}</text>
      <text class="line dim">本台自评描红：LLM 只给三粗项差异提示（主菜落位 / 色块分区 / 留白边距），不判过与不过；过与不过由你自定。若提示只能复述盘子里有什么，即退化为慧眼问答，本台不以此计数。</text>
    </view>
    <view class="verdict">
      <text class="line">{{placeLine}}</text>
      <text class="line">{{zoneLine}}</text>
      <text class="line">{{marginLine}}</text>
      <text class="line strong">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">拍照对位</button>
      <button class="tag" bindtap="actTap" data-idx="1">算过</button>
      <button class="tag" bindtap="actTap" data-idx="2">再摆一张</button>
      <button class="tag" bindtap="actTap" data-idx="3">跳过</button>
      <button class="tag" bindtap="actTap" data-idx="4">回看范本</button>
      <button class="tag" bindtap="actTap" data-idx="5">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR07 · 自评描红</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.plate-box { border: 2px solid rgba(125,255,158,0.65); border-radius: 20px; background-color: #03130a; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 6px 8px; margin-top: 5px; }
.target { color: #7dff9e; font-size: 12px; line-height: 16px; }
.verdict { margin-top: 5px; min-height: 66px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.strong { color: #7dff9e; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.tag { color: #7dff9e; background-color: #03130a; border: 2px solid rgba(125,255,158,0.6); border-radius: 20px; box-shadow: inset 0 0 0 2px #03130a, inset 0 0 0 3px rgba(125,255,158,0.25); padding: 5px 9px; font-size: 11px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border: 2px solid #7dff9e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
