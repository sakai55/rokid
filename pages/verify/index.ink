<script def>
{"title": "Trace Brush"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { CHARS } from '../../chars.js';

// 验收页：低头对准自己写的字拍照，LLM 对照范字只查三项粗项。
// 判定存进进度键的 lastVerdict，点评页负责呈现与用户覆盖。
const PROG = 'trace.trace-brush.v1';
const TMP = 'trace.brush.tmp';
const ACTS = ['拍照验收（或点头）', '换字（字库）', '返回 BACK'];
const SYS = '你是书法初学练习的粗查员，只查指定的三项粗项，不做专业书法评分，不打分，不用术语堆砌。看不清就如实说看不清，绝不编造。';

export default {
  data: {
    status: '验收：低头对准自己写的字，整字入框再拍',
    targetLine: '',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.3.5'
  },
  onLoad() {
    this._focus = 0; this._busy = false;
    const t = loadKey(TMP, { char: CHARS[0].char, review: false });
    this._char = CHARS.filter(function (c) { return c.char === t.char; })[0] || CHARS[0];
    this._review = !!t.review;
    this._render();
  },
  onShow() { this._render(); },
  _render() {
    const c = this._char;
    this.setData({
      targetLine: this._review
        ? '复习抽查：不给范字。先在纸上写「' + c.char + '」（' + c.pinyin + '），再低头拍照验收'
        : '目标字：' + c.char + '（' + c.pinyin + ' · ' + c.strokes.length + ' 画）。只拍你自己写的这个字，不要拍别人的脸或别的字',
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
    const c = this._char;
    this.setData({ status: '拍照中…对准纸面别晃', evt: 'EVT: verify shoot start ' + c.char });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '已拍（' + shot.note + '），粗查中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '目标字是「' + c.char + '」（' + c.strokes.length + '画，笔顺：' + c.types.join('、') + '）。照片里是练习者在纸上用毛笔写的这个字。若照片里不是这个字、或字看不清，第一行只写 CLEAR: NO 并说明原因，后面不用答。若是这个字且看得清，第一行写 CLEAR: YES，再严格回答三行：第二行 MISSING: 有没有少笔或多笔（没有写 无）；第三行 CENTER: 结构重心偏没偏（没偏写 稳，偏了写往哪边偏）；第四行 DIFF: 与范字差别最明显的1到2处（没有写 无）；第五行 SUMMARY: 一句人话点评，先肯定一句，再指出最值得改的一处。不要打分。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const clear = this._field(raw, 'CLEAR').toUpperCase();
      const p = loadKey(PROG, { chars: {}, days: {}, lastChar: c.char });
      if (clear.indexOf('NO') >= 0) {
        p.lastVerdict = { char: c.char, clear: false, raw: raw.slice(0, 300), at: new Date().toISOString(), review: this._review };
        saveKey(PROG, p);
        this.setData({ status: '没看清：请把整字挪进画面、纸面别反光，再拍一次', evt: 'EVT: verdict CLEAR NO' });
        speak('没看清，请重新拍');
        return;
      }
      p.lastVerdict = {
        char: c.char, clear: true,
        missing: this._field(raw, 'MISSING') || '（未答）',
        center: this._field(raw, 'CENTER') || '（未答）',
        diff: this._field(raw, 'DIFF') || '（未答）',
        summary: this._field(raw, 'SUMMARY') || '（未答）',
        raw: raw.slice(0, 300), at: new Date().toISOString(), review: this._review
      };
      saveKey(PROG, p);
      this.setData({ status: '粗查完成，去点评页看结果（你可以自己改判「算过」）', evt: 'EVT: verdict saved' });
      speak('查完了，去看点评');
      try { wx.navigateTo({ url: '/pages/review/index' }); } catch (e) {}
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this.setData({ status: '验收没成：' + code + '（如实报错，可重拍）', evt: 'EVT: verify FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  libraryTap() { try { wx.navigateTo({ url: '/pages/library/index' }); } catch (e) { this.setData({ evt: 'EVT: nav FAIL E8001' }); } },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() { if (this._focus === 0) this.shootTap(); else if (this._focus === 1) this.libraryTap(); else this.backTap(); },
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
    <text class="title">毛笔字描红 · 验收</text>
    <text class="status">{{status}}</text>
    <view class="framebox">
      <text class="target">{{targetLine}}</text>
      <text class="line dim">查三项粗查：①少笔多笔 ②结构重心 ③最明显的 1–2 处。判定会认错、会看不清——看不清会如实说，点评页里你能自己改判。</text>
    </view>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">拍照验收</button>
      <button class="act" bindtap="actTap" data-idx="1">换字（字库）</button>
      <button class="act" bindtap="actTap" data-idx="2">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}} · TR01</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.framebox { border: 2px dashed rgba(125,255,158,0.65); background-color: #04140a; padding: 8px; margin-top: 6px; }
.target { color: #7dff9e; font-size: 14px; font-weight: 500; line-height: 19px; }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 3px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 8px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); border-radius: 4px 12px 4px 12px; padding: 5px 10px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
