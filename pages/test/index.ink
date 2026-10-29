<script def>
{"title": "Trace Probe Kuji"}
</script>

<script setup>
import wx from 'wx';
import { loadKey, saveKey, speak, takePhotoDataUrl, judgePhoto, reportFail } from '../../judge.js';
import { SEALS, SEAL_NAMES } from '../../data.js';

// 輪測ページ：1印ずつ見本（再描画線画・装着者視点・高さ92px表示）と
// 要点を示し、結べたらうなずきで撮影。LLMが9印の候補から判定し、
// 真値は装着者が「正解／不正解」で確定して保存する。
// 見本データ（art）が無い印は「見本準備中」と表示し、代用図は描かない。
const KEY = 'trace.probe.kuji.v1';
const ACTS = ['撮影して判定', '正解', '不正解', '次の印', 'BACK もどる'];
const SYS = 'あなたは九字印の認識テストの判定員です。写真は装着者本人の両手で、装着者視点（手の甲がカメラ側）です。答えは必ず候補一覧の中から選び、見えないときは見えないと正直に答えてください。作り話は禁止です。';

export default {
  data: {
    status: '輪測：見本どおりに結び、うなずいて撮影',
    headLine: '',
    tipLine: '',
    diffLine: '',
    artLine: '',
    judgeLine: '判定：まだ撮影していない',
    truthLine: '真値：未確定',
    focusLine: '',
    evt: 'EVT: ready',
    ver: 'v2.0.0'
  },
  onLoad() {
    this._idx = 0; this._focus = 0; this._busy = false; this._phase = 'pose';
    this._recs = loadKey(KEY, []);
    // 最初の未確定の印から再開する
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
      headLine: '第 ' + (this._idx + 1) + ' / ' + SEALS.length + ' 印：' + it.name + '（' + it.reading + '） ・ ' + it.sub,
      tipLine: '要点：' + it.tip,
      diffLine: '見分け方：' + it.diff,
      artLine: it.art ? '見本：装着者視点の線画（高さ92pxで表示）' : '見本：データ準備中（再描画版を収録予定。要点の文字だけを頼りに結ぶ）',
      judgeLine: this._cur ? ('判定：LLMは「' + (this._cur.guess || '読み取れず') + '」と読んだ ・ ' + this._cur.matchText + (this._cur.finger ? ' ・ 指：' + this._cur.finger : '')) : (rec && rec.guess ? ('判定（前回）：LLMは「' + rec.guess + '」と読んだ') : '判定：まだ撮影していない'),
      truthLine: rec && rec.truth ? ('真値：確定済み ― 判定は' + (rec.truth === 'right' ? '正解' : '不正解')) : '真値：未確定（判定のあと「正解／不正解」を押す）',
      focusLine: 'フォーカス：' + ACTS[this._focus] + '（上下で切替、Enterで実行）'
    });
    const self = this;
    setTimeout(function () { self._drawArt(); }, 60);
  },
  _drawArt() {
    // 見本の行程符号（runs）を 1px 線で描く。art が無い印は隅の印だけの
    // 空枠にし、見本があるように見せない。
    try {
      var ctx = wx.createCanvasContext('sealCanvas');
      if (!ctx) return;
      var W = 252, H = 128;
      ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, W, H);
      var it = this._item();
      if (it.art && it.art.rows) {
        var ox = Math.round((W - it.art.w) / 2);
        var oy = Math.round((H - it.art.h) / 2);
        ctx.fillStyle = '#7dff9e';
        for (var r = 0; r < it.art.rows.length; r++) {
          var row = it.art.rows[r];
          var y = oy + row[0];
          for (var k = 1; k + 1 < row.length; k += 2) ctx.fillRect(ox + row[k], y, row[k + 1], 1);
        }
      } else {
        ctx.strokeStyle = 'rgba(64,255,94,0.45)'; ctx.lineWidth = 1;
        ctx.beginPath(); ctx.strokeRect(76, 18, 100, 92);
        ctx.beginPath();
        ctx.moveTo(76, 30); ctx.lineTo(88, 18);
        ctx.moveTo(176, 30); ctx.lineTo(164, 18);
        ctx.moveTo(76, 98); ctx.lineTo(88, 110);
        ctx.moveTo(176, 98); ctx.lineTo(164, 110);
        ctx.stroke();
      }
      ctx.flush();
    } catch (e) { this.setData({ evt: 'EVT: canvas draw FAIL E2002' }); }
  },
  async shootTap() {
    if (this._busy) return;
    this._busy = true; this._phase = 'judging';
    const it = this._item();
    this.setData({ status: '撮影中…そのまま保つ', evt: 'EVT: shoot start ' + it.id });
    try {
      const shot = await takePhotoDataUrl('default');
      this.setData({ status: '撮影できた（' + shot.note + '）。LLMが判定中…', evt: 'EVT: shot ' + shot.bytes + 'B judge start' });
      const ask = '候補：' + SEAL_NAMES + '。目標の印は「' + it.name + '（' + it.sub + '）」です。写真を見て3行で答えてください。1行目 GUESS: 読み取った印の漢字1字（読み取れなければ NONE）。2行目 MATCH: YES（目標どおり）/ NO（別の印）/ UNSURE（判別できない）。3行目 FINGER: 合っていない指（なければ「なし」、判別できなければ「不明」）。説明は不要です。';
      const raw = await judgePhoto(shot.url, SYS, ask);
      const guess = this._field(raw, 'GUESS');
      const match = this._field(raw, 'MATCH').toUpperCase();
      const finger = this._field(raw, 'FINGER');
      this._cur = {
        target: it.name,
        guess: (guess && guess !== 'NONE') ? guess : '',
        match: match,
        matchText: match === 'YES' ? '目標どおり' : (match === 'NO' ? '別の印らしい' : '判別できない'),
        finger: finger || '',
        raw: raw.slice(0, 300),
        at: new Date().toISOString()
      };
      this._phase = 'judged';
      const rec = this._recs[this._idx] || {};
      rec.target = it.name; rec.guess = this._cur.guess; rec.match = match; rec.finger = this._cur.finger; rec.raw = this._cur.raw; rec.at = this._cur.at;
      this._recs[this._idx] = rec;
      saveKey(KEY, this._recs);
      this.setData({ status: '判定は「' + (this._cur.guess || '読み取れず') + '」。あなたが結んだ形と比べて、正解か不正解か教えてください', evt: 'EVT: judged guess=' + (this._cur.guess || 'NONE') + ' match=' + match });
      speak('判定は' + (this._cur.guess || '読み取れません') + 'でした。正解かどうか教えてください');
    } catch (e) {
      const code = (e && e.code) || 'E9001';
      reportFail(code, e);
      this._phase = 'pose';
      this.setData({ status: 'この印は測れなかった：' + code + '（記録に残る。撮り直せる）', evt: 'EVT: shoot FAIL ' + code });
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
    if (!rec || !rec.at) { this.setData({ status: 'まだ判定していない。先に撮影して判定する', evt: 'EVT: truth refused - no judge' }); return; }
    rec.truth = right ? 'right' : 'wrong';
    this._recs[this._idx] = rec;
    if (!saveKey(KEY, this._recs)) { this.setData({ status: '真値の保存に失敗：E5001（記録はメモリ内のみ、ページを離れると消える）', evt: 'EVT: truth save FAIL E5001' }); return; }
    this._phase = 'recorded';
    this.setData({ status: '真値を記録した：判定は' + (right ? '正解' : '不正解') + '。「次の印」へ進む', evt: 'EVT: truth ' + rec.truth + ' ' + rec.target });
    speak(right ? '正解で記録しました' : '不正解で記録しました');
    this._render();
  },
  nextTap() {
    if (this._idx >= SEALS.length - 1) { this.setData({ status: '最後の印まで来た。結果ページで集計を見る', evt: 'EVT: at last seal' }); try { wx.navigateTo({ url: '/pages/result/index' }); } catch (e) {} return; }
    this._idx++; this._cur = null; this._phase = 'pose';
    this.setData({ status: '次の印：見本どおりに結び、うなずいて撮影', evt: 'EVT: next ' + this._item().id });
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
    <text class="title">印を結ぶ ・ 輪測</text>
    <text class="status">{{status}}</text>
    <text class="head">{{headLine}}</text>
    <view class="stage">
      <canvas id="sealCanvas" width="252" height="128" class="main-canvas"></canvas>
      <view class="rail">
        <text class="rline">{{tipLine}}</text>
        <text class="rline dim">{{diffLine}}</text>
        <text class="rline dim">{{artLine}}</text>
      </view>
    </view>
    <text class="line">{{judgeLine}}</text>
    <text class="line">{{truthLine}}</text>
    <view class="acts">
      <button class="act hot" bindtap="actTap" data-idx="0">撮影・判定</button>
      <button class="act" bindtap="actTap" data-idx="1">正解</button>
      <button class="act" bindtap="actTap" data-idx="2">不正解</button>
      <button class="act" bindtap="actTap" data-idx="3">次の印</button>
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
