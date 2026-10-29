<script def>
{"title": "Trace Probe Seals"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { SEALS, SEAL_NAMES } from '../../data.js';

// 轮测页：逐印出连续 3 帧范本（佩戴者视角线条示意），GO 摆到定格
// 帧后点头拍照，LLM 从 12 印名单里认；真值由 GO 点选确认后落盘。
const KEY = 'trace.probe.seals.v1';
const ACTS = ['下一帧', '拍照判定（或点头）', '判定对', '判定错', '下一个', '返回 BACK'];
const FRAMES = ['①起手', '②交指中段', '③成印定格'];
const SYS = '你是忍者手印识别试验的判定员。照片里是佩戴者本人双手摆出的手印（佩戴者视角，手背朝向镜头）。你只能从给定名单里选答案，看不清就如实说看不清，绝不编造。';

export default {
  data: {
    status: '轮测：照范本摆到定格帧，点头拍照',
    headLine: '',
    tipLine: '',
    diffLine: '',
    frameLine: '',
    judgeLine: '判定：未拍',
    truthLine: '真值：未确认',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._idx = 0; this._frame = 0; this._focus = 1; this._busy = false; this._phase = 'pose';
    this._recs = loadKey(KEY, []);
    // 从第一个未确认的印续测
    for (var i = 0; i < SEALS.length; i++) { var r = this._recs[i]; if (!r || !r.truth) { this._idx = i; break; } if (i === SEALS.length - 1) this._idx = 0; }
    this._cur = null;
    this._render();
  },
  onShow() { this._render(); },
  _item() { return SEALS[this._idx]; },
  _render() {
    const it = this._item();
    const rec = this._recs[this._idx];
    this.setData({
      headLine: '第 ' + (this._idx + 1) + ' / ' + SEALS.length + ' 印：' + it.name + '（' + it.sub + '）',
      tipLine: '要点：' + it.tip,
      diffLine: '区别：' + it.diff,
      frameLine: '帧：' + FRAMES[this._frame] + '（共 3 帧，下方缩略带左→右）· 示意图，手指以要点为准',
      judgeLine: this._cur ? ('判定：LLM 认成「' + (this._cur.guess || '没认出') + '」· ' + this._cur.matchText + (this._cur.finger ? ' · ' + this._cur.finger : '')) : (rec && rec.guess ? ('判定（上次）：LLM 认成「' + rec.guess + '」') : '判定：未拍'),
      truthLine: rec && rec.truth ? ('真值：已确认——判定' + (rec.truth === 'right' ? '对' : '错')) : '真值：未确认（判定后点「判定对 / 错」）',
      focusLine: '焦点：' + ACTS[this._focus] + '（上下切换，Enter 执行）'
    });
    const self = this;
    setTimeout(function () { self._drawAll(); }, 60);
  },
  _hand(ctx, cx, cy, s, flip, frame, ext, bright) {
    // 一只手的线条示意：掌 + 五指线。flip=+1 左手 / -1 右手（朝中央倾）
    ctx.strokeStyle = bright; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.strokeRect(cx - 15 * s, cy - 6 * s, 30 * s, 34 * s);
    var baseX = [-13, -6.5, 0, 6.5, 13];
    var len = [20, 30, 34, 29, 21];
    for (var i = 0; i < 5; i++) {
      var bx = cx + baseX[i] * s;
      var tilt = flip * frame * 2.2 * s;
      var ex = ext && ext[i] ? 9 * s : 0;
      ctx.beginPath(); ctx.moveTo(bx, cy - 6 * s); ctx.lineTo(bx + tilt, cy - (6 + len[i]) * s - ex); ctx.stroke();
    }
    // 拇指：内侧斜线
    ctx.beginPath(); ctx.moveTo(cx + flip * 15 * s, cy + 12 * s); ctx.lineTo(cx + flip * 24 * s, cy - 4 * s); ctx.stroke();
  },
  _drawFrame(ctx, w, h, frame, main) {
    const it = this._item();
    ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, w, h);
    var s = main ? 1.2 : 0.42;
    var cx = w / 2, cy = h / 2 + (main ? 8 : 4);
    var sep = [46, 25, 8][frame] * (main ? 1 : 0.62);
    var bright = frame === 2 ? '#7dff9e' : '#40ff5e';
    var dim = 'rgba(64,255,94,0.45)';
    this._hand(ctx, cx - sep, cy, s, 1, frame, frame === 2 ? it.ext : null, bright);
    this._hand(ctx, cx + sep, cy, s, -1, frame, frame === 2 ? it.ext.slice().reverse() : null, bright);
    if (frame >= 1) {
      // 交指中段起：双手之间画交叉线，帧 2 更密
      ctx.strokeStyle = dim; ctx.lineWidth = 1.5;
      var n = frame === 1 ? 2 : 4;
      for (var i = 0; i < n; i++) {
        var yy = cy - 26 * s + i * 13 * s;
        ctx.beginPath(); ctx.moveTo(cx - sep - 8 * s, yy); ctx.lineTo(cx + sep + 8 * s, yy + 10 * s); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(cx + sep + 8 * s, yy); ctx.lineTo(cx - sep - 8 * s, yy + 10 * s); ctx.stroke();
      }
    }
    if (!main && frame === this._frame) { ctx.strokeStyle = '#7dff9e'; ctx.lineWidth = 2; ctx.beginPath(); ctx.strokeRect(1, 1, w - 2, h - 2); }
    ctx.flush();
  },
  _drawAll() {
    try {
      var main = wx.createCanvasContext('sealCanvas');
      if (main) this._drawFrame(main, 252, 128, this._frame, true);
      for (var f = 0; f < 3; f++) {
        var tc = wx.createCanvasContext('thumb' + f);
        if (tc) this._drawFrame(tc, 76, 40, f, false);
      }
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  frameTap() { this._frame = (this._frame + 1) % 3; this.setData({ evt: 'EVT: frame ' + FRAMES[this._frame] }); this._render(); },
  async shootTap() {
    if (this._busy) return;
    if (this._frame !== 2) { this.setData({ status: '先推进到 ③成印定格 帧再拍（判定只对定格）', evt: 'EVT: shoot refused - not frame3' }); return; }
    this._busy = true; this._phase = 'judging';
    const it = this._item();
    this.setData({ status: '拍照中…摆稳别动', evt: 'EVT: shoot start ' + it.id });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '已拍（' + shot.note + '），LLM 判定中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '名单：' + SEAL_NAMES + '。目标印是「' + it.name + '」。请看照片回答三行：第一行 GUESS: 你认出的印名（名单里一个，认不出写 NONE）；第二行 MATCH: YES（就是目标）/ NO（是别的印）/ UNSURE（看不清）；第三行 FINGER: 哪根手指对不上（没有写 无，看不清写 看不清）。不要解释。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const guess = this._field(raw, 'GUESS');
      const match = this._field(raw, 'MATCH').toUpperCase();
      const finger = this._field(raw, 'FINGER');
      this._cur = {
        target: it.name,
        guess: (guess && guess !== 'NONE') ? guess : '',
        match: match,
        matchText: match === 'YES' ? '像目标' : (match === 'NO' ? '不像目标' : '看不清/没判明'),
        finger: finger || '',
        raw: raw.slice(0, 300),
        at: new Date().toISOString()
      };
      this._phase = 'judged';
      const rec = this._recs[this._idx] || {};
      rec.target = it.name; rec.guess = this._cur.guess; rec.match = match; rec.finger = this._cur.finger; rec.raw = this._cur.raw; rec.at = this._cur.at;
      this._recs[this._idx] = rec;
      saveKey(KEY, this._recs);
      this.setData({ status: '判定回来：认成「' + (this._cur.guess || '没认出') + '」。请你定真值：你摆的对不对版？点「判定对 / 判定错」', evt: 'EVT: judged guess=' + (this._cur.guess || 'NONE') + ' match=' + match });
      speak('判定认成' + (this._cur.guess || '没认出') + '，请确认对错');
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this._phase = 'pose';
      this.setData({ status: '本印未测成：' + code + '（如实记录，可重拍）', evt: 'EVT: shoot FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  _field(text, key) {
    if (!text) return '';
    const lines = String(text).split('\n');
    for (let i = 0; i < lines.length; i++) { const p = lines[i].indexOf(key + ':'); if (p >= 0) return lines[i].slice(p + key.length + 1).trim(); }
    const p2 = String(text).indexOf(key + '：');
    if (p2 >= 0) return String(text).slice(p2 + key.length + 1).split('\n')[0].trim();
    return '';
  },
  truthTap(right) {
    const rec = this._recs[this._idx];
    if (!rec || !rec.at) { this.setData({ status: '还没判定，先拍照判定再定真值', evt: 'EVT: truth refused - no judge' }); return; }
    rec.truth = right ? 'right' : 'wrong';
    this._recs[this._idx] = rec;
    if (!saveKey(KEY, this._recs)) { this.setData({ status: '真值保存失败：E5001（记录仍在内存，切页会丢）', evt: 'EVT: truth save FAIL E5001' }); return; }
    this._phase = 'recorded';
    this.setData({ status: '真值已记：判定' + (right ? '对' : '错') + '。点「下一个」继续', evt: 'EVT: truth ' + rec.truth + ' ' + rec.target });
    speak(right ? '已记判定对' : '已记判定错');
    this._render();
  },
  nextTap() {
    if (this._idx >= SEALS.length - 1) { this.setData({ status: '已是最后一印，去结果页看汇总', evt: 'EVT: at last seal' }); try { wx.navigateTo({ url: '/pages/result/index' }); } catch (e) {} return; }
    this._idx++; this._frame = 0; this._cur = null; this._phase = 'pose';
    this.setData({ status: '下一印：照范本摆到定格帧，点头拍照', evt: 'EVT: next ' + this._item().id });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.frameTap();
    else if (this._focus === 1) this.shootTap();
    else if (this._focus === 2) this.truthTap(true);
    else if (this._focus === 3) this.truthTap(false);
    else if (this._focus === 4) this.nextTap();
    else this.backTap();
  },
  moveTap(d) { this._focus = (this._focus + d + ACTS.length) % ACTS.length; this.setData({ evt: 'EVT: focus ' + ACTS[this._focus] }); this._render(); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || ''; if (g === 'nod') { if (this._phase === 'pose' || this._phase === 'judged') this.shootTap(); } },
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
    <text class="title">结印探针 · 轮测</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <canvas id="sealCanvas" width="252" height="128" class="main-canvas"></canvas>
      <view class="rail">
        <text class="rline">{{tipLine}}</text>
        <text class="rline dim">{{diffLine}}</text>
      </view>
    </view>
    <view class="thumbs">
      <canvas id="thumb0" width="76" height="40" class="thumb"></canvas>
      <canvas id="thumb1" width="76" height="40" class="thumb"></canvas>
      <canvas id="thumb2" width="76" height="40" class="thumb"></canvas>
    </view>
    <text class="line dim">{{frameLine}}</text>
    <text class="line">{{judgeLine}}</text>
    <text class="line">{{truthLine}}</text>
    <view class="acts">
      <button class="act" bindtap="actTap" data-idx="0">下一帧</button>
      <button class="act hot" bindtap="actTap" data-idx="1">拍照判定</button>
      <button class="act" bindtap="actTap" data-idx="2">判定对</button>
      <button class="act" bindtap="actTap" data-idx="3">判定错</button>
      <button class="act" bindtap="actTap" data-idx="4">下一个</button>
      <button class="act" bindtap="actTap" data-idx="5">BACK</button>
    </view>
    <text class="line dim">{{focusLine}}</text>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { display: flex; flex-direction: column; height: 100vh; padding: 4px 12px; background-color: #000000; }
.title { color: #7dff9e; font-size: 17px; font-weight: 500; line-height: 20px; }
.status { color: #40ff5e; font-size: 12px; line-height: 16px; margin-top: 2px; }
.head { color: #7dff9e; font-size: 13px; font-weight: 500; line-height: 17px; margin-top: 2px; }
.stage { display: flex; flex-direction: row; gap: 8px; margin-top: 3px; }
.main-canvas { width: 252px; height: 128px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.4); }
.rail { display: flex; flex-direction: column; flex-grow: 1; }
.rline { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.thumbs { display: flex; flex-direction: row; gap: 8px; margin-top: 4px; }
.thumb { width: 76px; height: 40px; background-color: #04140a; border: 1px solid rgba(64,255,94,0.3); }
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); padding: 3px 7px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
