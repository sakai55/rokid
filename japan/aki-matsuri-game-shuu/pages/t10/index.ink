<script def>
{
  "title": "ハロウィン仮装当て"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "akiMatsuriGameShuuV1";
const DEF = {"selected": 0, "best": {}, "bestN": {}, "records": []};
const KIND = "ハロウィン仮装当て";
const QS = [{"q": "ハロウィンで子どもが着るのはどれでしょう", "opts": ["仮装", "制服"], "ans": 0}, {"q": "ハロウィンのかぼちゃの飾りはどれでしょう", "opts": ["ジャック・オー・ランタン", "雪だるま"], "ans": 0}, {"q": "ハロウィンで子どもがもらうのはどれでしょう", "opts": ["お菓子", "お年玉"], "ans": 0}];
const STATUS = "ハロウィン仮装当て";
const GUIDE = "上下で選択肢を変える ・ うなずきで答える ・ 全問で集計";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 9; this._q = 0; this._score = 0; this._opt = 0; this._done = false; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (this._done) { d.big = '集計: ' + this._score + '/' + QS.length + '正解'; d.r0 = '全問終わりました'; d.r1 = '正解: ' + this._score + ' / ' + QS.length; d.r2 = 'ベスト: ' + ((st.best && st.best[String(this._sel)]) ? st.best[String(this._sel)] : 'まだなし'); d.r3 = '記録 ' + (st.records ? st.records.length : 0) + '件'; d.r4 = ''; d.r5 = ''; d.detail = KIND + 'の集計です。記録に残しました。'; } else { var q = QS[this._q]; d.big = q.q; var i; for (i = 0; i < 3; i++) { d['r' + i] = (i < q.opts.length) ? ((i === this._opt ? '▶ ' : '・ ') + q.opts[i]) : ''; } d.r3 = '第' + (this._q + 1) + '問 / 全' + QS.length + '問'; d.r4 = '正解: ' + this._score; d.r5 = 'ベスト: ' + ((st.best && st.best[String(this._sel)]) ? st.best[String(this._sel)] : 'まだなし'); d.detail = '上下で選んで、うなずきで答える'; } d.guide = GUIDE; d.evt = 'EVT: Q' + (this._q + 1) + '/' + QS.length + ' score ' + this._score; this.setData(d); },
  answerTap() { if (this._done) { this._speak('もう集計しました。'); this._recompute(); return; } var q = QS[this._q]; if (this._opt === q.ans) { this._score++; this._speak('正解です。'); } else { this._speak('はずれです。正解は' + q.opts[q.ans] + 'です。'); } this._q++; this._opt = 0; if (this._q >= QS.length) { this._done = true; this._finish(KIND, this._score + '/' + QS.length + '正解', this._score, this._score + '/' + QS.length + '正解'); } this._recompute(); },
  primaryTap() { this.answerTap(); },
  nextTap() { if (!this._done) { var q = QS[this._q]; this._opt = (this._opt + 1) % q.opts.length; } this._recompute(); },
  prevTap() { if (!this._done) { var q = QS[this._q]; this._opt = (this._opt + q.opts.length - 1) % q.opts.length; } this._recompute(); },
  speakTap() { if (this._done) this._speak('集計は' + this._score + '問正解です。'); else this._speak(QS[this._q].q); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'aki-matsuri-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  _finish(kind, item, score, text) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: kind, item: item, at: new Date().toISOString() }); if (!st.best) st.best = {}; if (!st.bestN) st.bestN = {}; var oldN = st.bestN[String(this._sel)]; if (oldN === undefined || oldN === null || score > oldN) { st.bestN[String(this._sel)] = score; st.best[String(this._sel)] = text; } this._save(st); },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },

};
</script>

<template>
  <div class="page">
    <div class="band">ハロウィン仮装当て</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="answerTap">答える</button>
      <button class="btn" bindtap="nextTap">選択肢を変える</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:13px;line-height:19px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:3px double #40ff5e;border-radius:12px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d1a;color:#7dff9e;border:2px solid #40ff5e;border-bottom:4px solid #40ff5e;border-radius:12px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
