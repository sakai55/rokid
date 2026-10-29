<script def>
{"title": "Trace Sketch"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { PICS } from '../../pics.js';

// TR06 验收点评页（验收与点评同页，与 TR01 的验收/点评分开、TR04 的
// 逐步验形都不同）：整幅画完拍一次，LLM 对照本幅分笔清单只查三粗项
// （漏线 / 比例最偏 / 闭合开口），判定就地呈现；「这幅算过」记数——
// 机器说过直接记，机器说有漏线而本人改判，记 overrides；没验过不许
// 凭空算过。复习模式（review）额外记 reviewPassed 与是否偷看过范本。
const PROG = 'trace.trace-sketch.v1';
const TMP = 'trace.sketch.tmp';
const ACTS = ['拍照验收（或点头）', '这幅算过', '再画一次', '换图（图库）'];
const SYS = '你是简笔画练习的粗查员，只查指定的三项粗项，不评画工、不打分、不说专业术语。看不清就如实说看不清，绝不编造。';

export default {
  data: {
    status: '验收：对准纸上画完整幅，整图入框再拍',
    targetLine: '',
    missLine: '',
    propLine: '',
    closedLine: '',
    sumLine: '',
    countLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    const t = loadKey(TMP, { pic: PICS[0].id, review: false, peeked: false });
    this._pic = PICS.filter(function (x) { return x.id === t.pic; })[0] || PICS[0];
    this._review = !!t.review;
    this._peeked = !!t.peeked;
    this._render();
  },
  onShow() { this._render(); },
  _verdict() {
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    const v = p.lastVerdict;
    if (v && v.pic === this._pic.id && !!v.review === this._review) return v;
    return null;
  },
  _render() {
    const pic = this._pic;
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    const rec = (p.pics || {})[pic.id] || { count: 0 };
    const v = this._verdict();
    const ok = !!(v && v.clear);
    this.setData({
      targetLine: this._review
        ? '复习抽查：凭记忆画的「' + pic.name + '」（' + pic.strokes.length + ' 笔' + (this._peeked ? '，偷看过范本，按协助完成记' : '') + '）'
        : '目标：「' + pic.name + '」（' + pic.strokes.length + ' 笔）。只拍你自己画的这一幅',
      missLine: ok ? ('漏线：' + v.missing) : '',
      propLine: ok ? ('比例最偏：' + v.prop) : '',
      closedLine: ok ? ('闭合开口：' + v.closed) : '',
      sumLine: ok ? ('一句话：' + v.summary) : (v ? '这次没看清：请把整幅挪进画面、纸面别反光，再拍一次' : '还没验：先拍照'),
      countLine: '「' + pic.name + '」已画 ' + (rec.count || 0) + ' 次' + (rec.passed ? ' · 已算过' : '') + (rec.reviewPassed ? ' · 复习过关 ' + rec.reviewPassed + ' 次' : ''),
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
    const pic = this._pic;
    this.setData({ status: '拍照中…对准纸面别晃', evt: 'EVT: check shoot start ' + pic.id });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '已拍（' + shot.note + '），对形中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const names = pic.strokes.map(function (s) { return s.n; }).join('、');
      const closedNames = pic.strokes.filter(function (s) { return s.closed; }).map(function (s) { return s.n; }).join('、') || '无';
      const ask = '目标简笔画是「' + pic.name + '」，应有这些笔：' + names + '。照片里是练习者在纸上画的这幅画。若照片里不是这幅画、或看不清，第一行只写 CLEAR: NO 并说明原因，后面不用答。若是且看得清，第一行写 CLEAR: YES，再严格回答四行：第二行 MISSING: 有没有漏画的笔（没有写 无，有写明漏了哪笔）；第三行 PROPORTION: 比例最偏的一处是哪（没有明显偏差写 无，有写明哪处大/小/歪了）；第四行 CLOSED: 这些本应闭合的图形有没有开口的（' + closedNames + '；都合上了写 无，有写明哪个开口）；第五行 SUMMARY: 一句人话点评，先肯定一句，再指出最值得改的一处。不要打分。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const clear = this._field(raw, 'CLEAR').toUpperCase();
      const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
      if (clear.indexOf('NO') >= 0) {
        p.lastVerdict = { pic: pic.id, clear: false, review: this._review, raw: raw.slice(0, 300), at: new Date().toISOString() };
        saveKey(PROG, p);
        this.setData({ status: '没看清：把整幅挪进画面、纸面别反光，再拍一次', evt: 'EVT: verdict CLEAR NO' });
        speak('没看清，请重新拍');
        return;
      }
      const missing = this._field(raw, 'MISSING') || '（未答）';
      const passLLM = (missing === '无' || missing.indexOf('没有') >= 0);
      p.lastVerdict = {
        pic: pic.id, clear: true, review: this._review, passLLM: passLLM,
        missing: missing, prop: this._field(raw, 'PROPORTION') || '（未答）',
        closed: this._field(raw, 'CLOSED') || '（未答）',
        summary: this._field(raw, 'SUMMARY') || '（未答）',
        raw: raw.slice(0, 300), at: new Date().toISOString()
      };
      saveKey(PROG, p);
      this.setData({ status: passLLM ? '对形通过：没漏线，点「这幅算过」记上' : '对形说有漏线：看下面三项，补画重拍，或你确认没问题再算过', evt: 'EVT: verdict saved passLLM=' + passLLM });
      speak(passLLM ? '对形通过' : '好像有漏线，看一下');
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this.setData({ status: '验收没成：' + code + '（如实报错，可重拍）', evt: 'EVT: check FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  passTap() {
    const v = this._verdict();
    if (!v || !v.clear) { this.setData({ status: '先验收这幅再算过（没验过不凭空算过）', evt: 'EVT: pass refused - no verdict' }); return; }
    const pic = this._pic;
    const p = loadKey(PROG, { pics: {}, days: {}, lastPic: '' });
    p.pics = p.pics || {};
    const rec = p.pics[pic.id] || { count: 0 };
    rec.count = (rec.count || 0) + 1;
    rec.passed = true;
    if (!v.passLLM) rec.overrides = (rec.overrides || 0) + 1;
    if (this._review) {
      rec.reviewPassed = (rec.reviewPassed || 0) + 1;
      if (this._peeked) rec.assisted = (rec.assisted || 0) + 1;
    }
    rec.lastAt = new Date().toISOString();
    p.pics[pic.id] = rec;
    const today = new Date().toISOString().slice(0, 10);
    p.days = p.days || {}; p.days[today] = true;
    p.lastPic = pic.id;
    delete p.lastVerdict;
    if (!saveKey(PROG, p)) { this.setData({ status: '保存失败：E5001（进度没落盘）', evt: 'EVT: pass save FAIL E5001' }); return; }
    this.setData({ status: '已记：「' + pic.name + '」算过' + (v.passLLM ? '' : '（本人改判）') + (this._review ? ' · 复习过关' : ''), evt: 'EVT: pass recorded ' + pic.id });
    speak(pic.name + '，已记算过');
    this._render();
  },
  againTap() { try { wx.navigateTo({ url: '/pages/draw/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  galleryTap() { try { wx.navigateTo({ url: '/pages/gallery/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.shootTap();
    else if (this._focus === 1) this.passTap();
    else if (this._focus === 2) this.againTap();
    else this.galleryTap();
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
    <text class="title">简笔画描红 · 验收点评</text>
    <text class="status">{{status}}</text>
    <view class="ruled">
      <text class="rline strong">{{targetLine}}</text>
      <text class="rline">{{missLine}}</text>
      <text class="rline">{{propLine}}</text>
      <text class="rline">{{closedLine}}</text>
      <text class="rline strong">{{sumLine}}</text>
    </view>
    <text class="line dim">只查三粗项：①漏线 ②比例最偏处 ③闭合图形开没开口。判定会认错——最后算不算过你说了算，但没验过不能算过。</text>
    <view class="acts">
      <button class="pen hot" bindtap="actTap" data-idx="0">拍照验收</button>
      <button class="pen" bindtap="actTap" data-idx="1">这幅算过</button>
      <button class="pen" bindtap="actTap" data-idx="2">再画一次</button>
      <button class="pen" bindtap="actTap" data-idx="3">换图</button>
    </view>
    <text class="line dim">{{countLine}}</text>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR06</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.ruled { margin-top: 5px; border-top: 1px solid rgba(64,255,94,0.4); }
.rline { color: rgba(125,255,158,0.9); font-size: 11px; line-height: 15px; padding: 3px 2px; border-bottom: 1px solid rgba(64,255,94,0.35); min-height: 15px; }
.rline.strong { color: #7dff9e; font-weight: 500; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 12px; margin-top: 6px; }
.pen { color: #7dff9e; background-color: #04140a; border: none; border-bottom: 2px solid rgba(125,255,158,0.6); padding: 4px 6px; font-size: 12px; text-align: left; }
.pen.hot { background-color: #0a2413; border-bottom: 3px solid #7dff9e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
