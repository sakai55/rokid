<script def>
{"title": "Trace Origami"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { WORKS } from '../../works.js';

// TR04 验形页：把折好的这一步举到眼前拍照，LLM 对照本步目标折形只
// 查三粗项（轮廓大形 / 多边少边 / 折线方向）。判定落盘 lastVerdict；
// 「算过，进下一步」才推进度——机器说过直接进，机器说不过而用户点
// 进，记一次本人改判（overrides）。看不清如实报 CLEAR: NO、重拍。
const PROG = 'trace.trace-origami.v1';
const TMP = 'trace.origami.tmp';
const ACTS = ['拍照验形（或点头）', '算过，进下一步', '回看范本', 'BACK'];
const SYS = '你是折纸练习的粗查员，只查指定的三项粗项，不评美观、不打分。照片看不清就如实说看不清，绝不编造。';

export default {
  data: {
    status: '验形：把这一步的纸举到眼前，整形入框再拍',
    targetLine: '',
    shapeLine: '',
    edgeLine: '',
    dirLine: '',
    sumLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    const t = loadKey(TMP, { work: WORKS[0].id });
    this._work = WORKS.filter(function (w) { return w.id === t.work; })[0] || WORKS[0];
    this._render();
  },
  onShow() { this._render(); },
  _step() {
    const p = loadKey(PROG, { works: {}, days: {}, lastWork: '' });
    const rec = (p.works || {})[this._work.id] || { step: 0 };
    return Math.min(rec.step || 0, this._work.steps.length);
  },
  _verdict() {
    const p = loadKey(PROG, { works: {}, days: {}, lastWork: '' });
    const v = p.lastVerdict;
    if (v && v.work === this._work.id && v.step === this._step()) return v;
    return null;
  },
  _render() {
    const w = this._work;
    const st = this._step();
    const s = w.steps[Math.min(st, w.steps.length - 1)];
    const v = this._verdict();
    const ok = !!(v && v.clear);
    this.setData({
      targetLine: '第 ' + (st + 1) + ' 步 · ' + s.t + '——目标折形：' + s.target,
      shapeLine: ok ? ('轮廓大形：' + v.shape) : '',
      edgeLine: ok ? ('多边少边：' + v.edge) : '',
      dirLine: ok ? ('折线方向：' + v.direction) : '',
      sumLine: ok ? ('一句话：' + v.summary) : (v ? '上次判定没看清，请重拍' : '还没验：先拍照'),
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
    const w = this._work;
    const st = this._step();
    const s = w.steps[Math.min(st, w.steps.length - 1)];
    this.setData({ status: '拍照中…把纸举稳、别挡光', evt: 'EVT: check shoot start ' + w.id + ' step ' + (st + 1) });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '已拍（' + shot.note + '），粗查中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '折纸作品「' + w.name + '」第 ' + (st + 1) + ' 步「' + s.t + '」完成后的目标折形是：' + s.target + '。照片里是练习者手里的纸。若照片里看不清纸的形状，第一行只写 CLEAR: NO 并说明原因，后面不用答。若看得清，第一行写 CLEAR: YES，再严格回答三行：第二行 SHAPE: 轮廓大形对不对（对就写 对，不对写不对并说差在哪）；第三行 EDGE: 有没有多边或少边（没有写 无，有写明哪处）；第四行 DIRECTION: 本步折线方向明显反了没有（没反写 没反，反了写 反了并说明）；第五行 SUMMARY: 一句人话，先肯定一句再指出最值得改的一处。不要打分，不要评美观。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const clear = this._field(raw, 'CLEAR').toUpperCase();
      const p = loadKey(PROG, { works: {}, days: {}, lastWork: '' });
      if (clear.indexOf('NO') >= 0) {
        p.lastVerdict = { work: w.id, step: st, clear: false, raw: raw.slice(0, 300), at: new Date().toISOString() };
        saveKey(PROG, p);
        this.setData({ status: '没看清：把纸挪到画面中央、避开反光，再拍一次', evt: 'EVT: verdict CLEAR NO' });
        speak('没看清，请重新拍');
        return;
      }
      const shape = this._field(raw, 'SHAPE') || '（未答）';
      const direction = this._field(raw, 'DIRECTION') || '（未答）';
      const passLLM = (shape.indexOf('不对') < 0 && direction.indexOf('反了') < 0 && direction.indexOf('反') !== 0);
      p.lastVerdict = {
        work: w.id, step: st, clear: true, passLLM: passLLM,
        shape: shape, edge: this._field(raw, 'EDGE') || '（未答）',
        direction: direction, summary: this._field(raw, 'SUMMARY') || '（未答）',
        raw: raw.slice(0, 300), at: new Date().toISOString()
      };
      saveKey(PROG, p);
      this.setData({ status: passLLM ? '粗查通过：点「算过，进下一步」继续' : '粗查说有问题：看下面三项，改好重拍，或你确认没问题再进下一步', evt: 'EVT: verdict saved passLLM=' + passLLM });
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
    const w = this._work;
    const p = loadKey(PROG, { works: {}, days: {}, lastWork: '' });
    p.works = p.works || {};
    const rec = p.works[w.id] || { done: 0, step: 0, overrides: 0 };
    rec.step = (rec.step || 0) + 1;
    if (!v.passLLM) { rec.overrides = (rec.overrides || 0) + 1; rec.runOverrides = (rec.runOverrides || 0) + 1; }
    rec.lastAt = new Date().toISOString();
    p.works[w.id] = rec;
    p.lastWork = w.id;
    delete p.lastVerdict;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存失败：E5001（进度没落盘）', evt: 'EVT: next save FAIL E5001' }); return; }
    const last = rec.step >= w.steps.length;
    this.setData({ status: last ? '全部步数验完，去成品结算' : '已进第 ' + (rec.step + 1) + ' 步', evt: 'EVT: advanced step ' + rec.step });
    speak(last ? '都折完了，去结算' : '下一步');
    try { wx.navigateTo({ url: last ? '/pages/finish/index' : '/pages/fold/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); }
  },
  foldTap() { try { wx.navigateTo({ url: '/pages/fold/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.shootTap();
    else if (this._focus === 1) this.nextTap();
    else if (this._focus === 2) this.foldTap();
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
    <text class="title">折纸描红 · 验形</text>
    <text class="status">{{status}}</text>
    <view class="crease-box">
      <text class="target">{{targetLine}}</text>
      <text class="line dim">只查三粗项：①轮廓大形 ②多边少边 ③折线方向反没反。判定会认错、会看不清——看不清会如实说，进不进下一步最后你说了算，但没验过不能凭空算过。</text>
    </view>
    <view class="verdict">
      <text class="line">{{shapeLine}}</text>
      <text class="line">{{edgeLine}}</text>
      <text class="line">{{dirLine}}</text>
      <text class="line strong">{{sumLine}}</text>
    </view>
    <view class="acts">
      <button class="tag hot" bindtap="actTap" data-idx="0">拍照验形</button>
      <button class="tag" bindtap="actTap" data-idx="1">算过，进下一步</button>
      <button class="tag" bindtap="actTap" data-idx="2">回看范本</button>
      <button class="tag" bindtap="actTap" data-idx="3">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR04</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.crease-box { border: 1px dashed rgba(125,255,158,0.65); background-color: #03130a; padding: 6px 8px; margin-top: 5px; }
.target { color: #7dff9e; font-size: 12px; line-height: 16px; }
.verdict { margin-top: 5px; min-height: 66px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.strong { color: #7dff9e; font-weight: 500; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.tag { color: #7dff9e; background-color: #03130a; border: 1px solid rgba(125,255,158,0.55); border-left: 7px solid #40ff5e; border-radius: 2px; padding: 5px 9px 5px 6px; font-size: 11px; text-align: center; }
.tag.hot { color: #03130a; background-color: #40ff5e; border-left: 7px solid #7dff9e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
