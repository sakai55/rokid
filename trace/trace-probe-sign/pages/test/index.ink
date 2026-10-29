<script def>
{"title": "Trace Probe Sign"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { SIGNS, SIGN_NAMES } from '../../data.js';

// 測定ページ：項目ごとに装着者視点の線画模式図＋要点を出し、
// 形を作ってうなずき撮影→LLM 判定→本人が真値を確定して保存する。
const KEY = 'trace.probe.sign.v1';
const ACTS = ['撮影して判定（うなずきでも可）', '判定は正しい', '判定は違う', '次の項目', 'もどる BACK'];
const SYS = 'あなたは日本手話（JSL）指文字の認識実験の判定員です。写真は装着者本人の片手です（装着者視点）。答えは必ず候補リストの中から選び、見えなければ正直に「見えない」と答えてください。創作は禁止です。';

export default {
  data: {
    status: '測定：範本どおりに形を作り、うなずいて撮影',
    headLine: '',
    tipLine: '',
    judgeLine: '判定：未撮影',
    truthLine: '真値：未確定',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v1.0.0'
  },
  onLoad() {
    this._idx = 0; this._focus = 0; this._busy = false; this._phase = 'pose';
    this._recs = loadKey(KEY, []);
    for (var i = 0; i < SIGNS.length; i++) { var r = this._recs[i]; if (!r || !r.truth) { this._idx = i; break; } if (i === SIGNS.length - 1) this._idx = 0; }
    this._cur = null;
    this._render();
  },
  onShow() { this._render(); },
  _item() { return SIGNS[this._idx]; },
  _render() {
    const it = this._item();
    const rec = this._recs[this._idx];
    this.setData({
      headLine: (this._idx + 1) + ' / ' + SIGNS.length + ' 項目：' + it.name + '（' + it.kind + '）',
      tipLine: '要点：' + it.tip,
      judgeLine: this._cur ? ('判定：LLM は「' + (this._cur.guess || '読み取れず') + '」と回答 · ' + this._cur.matchText + (this._cur.finger ? ' · ' + this._cur.finger : '')) : (rec && rec.guess ? ('判定（前回）：LLM は「' + rec.guess + '」') : '判定：未撮影'),
      truthLine: rec && rec.truth ? ('真値：確定済み——判定は' + (rec.truth === 'right' ? '正しい' : '違う')) : '真値：未確定（判定のあと確定してください）',
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enter で実行）'
    });
    const self = this;
    setTimeout(function () { self._draw(); }, 60);
  },
  _draw() {
    try {
      const ctx = wx.createCanvasContext('signCanvas');
      if (!ctx) return;
      const it = this._item();
      const W = 252, H = 128;
      ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, W, H);
      const cx = 84, cy = 78; // 手掌中心（左寄せ、右に凡例）
      const bright = '#7dff9e', mid = '#40ff5e', dim = 'rgba(64,255,94,0.45)';
      // 手掌
      ctx.strokeStyle = mid; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.strokeRect(cx - 30, cy - 22, 60, 46);
      if (it.palm === 'ura') {
        // 手の甲側：斜線ハッチで区別
        ctx.strokeStyle = dim; ctx.lineWidth = 1;
        for (var hx = -22; hx <= 22; hx += 11) { ctx.beginPath(); ctx.moveTo(cx + hx, cy + 22); ctx.lineTo(cx + hx + 14, cy - 22); ctx.stroke(); }
      } else {
        // 手のひら側：掌線 2 本
        ctx.strokeStyle = dim; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(cx - 22, cy + 2); ctx.lineTo(cx + 20, cy - 4); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(cx - 22, cy + 12); ctx.lineTo(cx + 16, cy + 8); ctx.stroke();
      }
      // 指：[親指, 人差し, 中, 薬, 小]。親指は左側面から、他は掌の上辺から。
      const f = it.fingers;
      const baseX = [null, -21, -7, 7, 21];
      const len = [30, 34, 38, 34, 26];
      const dv = it.dir === 'down' ? [0.25, 1] : (it.dir === 'side' ? [-0.85, -0.5] : (it.dir === 'fwd' ? [0, -0.35] : [0, -1]));
      ctx.strokeStyle = bright; ctx.lineWidth = 2.4;
      for (var i = 1; i < 5; i++) {
        const bx = cx + baseX[i];
        const by = it.dir === 'down' ? cy + 24 : cy - 22;
        const st = f[i];
        if (st === 0) { ctx.beginPath(); ctx.moveTo(bx, by); ctx.lineTo(bx + dv[0] * 6, by + dv[1] * 6); ctx.stroke(); continue; }
        const L = st === 1 ? len[i] : len[i] * 0.5;
        let tx = bx + dv[0] * L, ty = by + dv[1] * L;
        if (it.cross && i === 1) { tx += 10; }
        if (it.cross && i === 2) { tx -= 10; }
        ctx.beginPath(); ctx.moveTo(bx, by); ctx.lineTo(tx, ty); ctx.stroke();
        if (st === 2) { ctx.beginPath(); ctx.moveTo(tx, ty); ctx.lineTo(tx + 6, ty + (it.dir === 'down' ? -5 : 5)); ctx.stroke(); }
      }
      // 親指：左側面から（位置は thumbPos で微変）
      const tst = f[0];
      ctx.beginPath();
      if (tst === 0) { ctx.moveTo(cx - 30, cy + 8); ctx.lineTo(cx - 38, cy + 2); }
      else if (it.thumbPos === 'front') { ctx.moveTo(cx - 30, cy + 16); ctx.lineTo(cx + 6, cy + 14); }
      else if (it.thumbPos === 'under') { ctx.moveTo(cx - 30, cy + 20); ctx.lineTo(cx + 2, cy + 22); }
      else { ctx.moveTo(cx - 30, cy + 10); ctx.lineTo(cx - 44, cy - 16); }
      ctx.stroke();
      if (it.ring) { ctx.strokeStyle = bright; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(cx, cy - 34, 13, 0, Math.PI * 2); ctx.stroke(); }
      // 右側の凡例テキスト相当（向き・手の側）
      ctx.fillStyle = mid; ctx.font = '11px sans-serif';
      ctx.fillText('視点：装着者側', 150, 34);
      ctx.fillText(it.palm === 'ura' ? '見えているのは手の甲' : '見えているのは手のひら', 150, 52);
      ctx.fillText('向き：' + (it.dir === 'down' ? '下' : (it.dir === 'side' ? '横' : (it.dir === 'fwd' ? '相手方向' : '上'))), 150, 70);
      ctx.fillText('模式図（目安）', 150, 88);
      ctx.flush();
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  async shootTap() {
    if (this._busy) return;
    this._busy = true; this._phase = 'judging';
    const it = this._item();
    this.setData({ status: '撮影中…手を止めてください', evt: 'EVT: shoot start ' + it.id });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '撮影完了（' + shot.note + '）、LLM 判定中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '候補：' + SIGN_NAMES + '。目標は「' + it.name + '」（' + it.kind + '）です。写真を見て三行で答えてください。一行目 GUESS: 読み取った項目（候補の一つ、読み取れなければ NONE）。二行目 MATCH: YES（目標どおり）/ NO（別の項目）/ UNSURE（見えない）。三行目 FINGER: どの指がどう違うか（なければ「なし」、見えなければ「見えない」）。説明は不要です。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const guess = this._field(raw, 'GUESS');
      const match = this._field(raw, 'MATCH').toUpperCase();
      const finger = this._field(raw, 'FINGER');
      this._cur = {
        guess: (guess && guess !== 'NONE') ? guess : '',
        matchText: match === 'YES' ? '目標どおり' : (match === 'NO' ? '目標とは違う' : '見えない・未判定'),
        finger: finger || ''
      };
      this._phase = 'judged';
      const rec = this._recs[this._idx] || {};
      rec.target = it.name; rec.guess = this._cur.guess; rec.match = match; rec.finger = this._cur.finger; rec.raw = raw.slice(0, 300); rec.at = new Date().toISOString();
      this._recs[this._idx] = rec;
      saveKey(KEY, this._recs);
      this.setData({ status: '判定が返りました：「' + (this._cur.guess || '読み取れず') + '」。自分の形と比べて真値を確定してください', evt: 'EVT: judged guess=' + (this._cur.guess || 'NONE') + ' match=' + match });
      speak('判定は' + (this._cur.guess || '読み取れず') + 'です。真値を確定してください');
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this._phase = 'pose';
      this.setData({ status: 'この項目は測定できませんでした：' + code + '（正直に記録、撮り直し可）', evt: 'EVT: shoot FAIL ' + code });
    } finally { this._busy = false; this._render(); }
  },
  _field(text, key) {
    if (!text) return '';
    const lines = String(text).split('\n');
    for (let i = 0; i < lines.length; i++) { const p = lines[i].indexOf(key + ':'); if (p >= 0) return lines[i].slice(p + key.length + 1).trim(); }
    return '';
  },
  truthTap(right) {
    const rec = this._recs[this._idx];
    if (!rec || !rec.at) { this.setData({ status: 'まだ判定がありません。先に撮影してください', evt: 'EVT: truth refused - no judge' }); return; }
    rec.truth = right ? 'right' : 'wrong';
    this._recs[this._idx] = rec;
    if (!saveKey(KEY, this._recs)) { this.setData({ status: '保存に失敗しました：E5001', evt: 'EVT: truth save FAIL E5001' }); return; }
    this._phase = 'recorded';
    this.setData({ status: '真値を記録しました：判定は' + (right ? '正しい' : '違う') + '。「次の項目」へ進んでください', evt: 'EVT: truth ' + rec.truth + ' ' + rec.target });
    speak(right ? '正しいと記録しました' : '違うと記録しました');
    this._render();
  },
  nextTap() {
    if (this._idx >= SIGNS.length - 1) { this.setData({ status: '最後の項目です。結果ページへ移動します', evt: 'EVT: at last sign' }); try { wx.navigateTo({ url: '/pages/result/index' }); } catch (e) {} return; }
    this._idx++; this._cur = null; this._phase = 'pose';
    this.setData({ status: '次の項目：範本どおりに形を作り、うなずいて撮影', evt: 'EVT: next ' + this._item().id });
    this._render();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  actTap(e) { const idx = e && e.currentTarget && e.currentTarget.dataset ? Number(e.currentTarget.dataset.idx) : NaN; if (!isNaN(idx)) this._focus = idx; this.doAct(); },
  doAct() {
    if (this._focus === 0) this.shootTap();
    else if (this._focus === 1) this.truthTap(true);
    else if (this._focus === 2) this.truthTap(false);
    else if (this._focus === 3) this.nextTap();
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
    <text class="title">指文字プローブ · 測定</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <canvas id="signCanvas" width="252" height="128" class="main-canvas"></canvas>
      <view class="rail">
        <text class="rline">{{tipLine}}</text>
      </view>
    </view>
    <text class="line">{{judgeLine}}</text>
    <text class="line">{{truthLine}}</text>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">撮影して判定</button>
      <button class="act" bindtap="actTap" data-idx="1">判定は正しい</button>
      <button class="act" bindtap="actTap" data-idx="2">判定は違う</button>
      <button class="act" bindtap="actTap" data-idx="3">次の項目</button>
      <button class="act" bindtap="actTap" data-idx="4">BACK</button>
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
.line { color: rgba(125,255,158,0.88); font-size: 11px; line-height: 15px; margin-top: 2px; }
.dim { color: rgba(64,255,94,0.55); }
.acts { display: flex; flex-direction: row; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
.act { color: #7dff9e; background-color: #04140a; border: 1px solid rgba(125,255,158,0.6); padding: 3px 7px; font-size: 12px; text-align: center; }
.act.hot { color: #04140a; background-color: #40ff5e; font-weight: 500; }
.foot { color: rgba(64,255,94,0.55); font-family: monospace; font-size: 10px; line-height: 12px; margin-top: 3px; }
</style>
