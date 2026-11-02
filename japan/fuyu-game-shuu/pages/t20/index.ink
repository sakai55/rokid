<script def>
{
  "title": "雪だるま色当て"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "fuyuGameShuuV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const KIND = "雪だるま色当て";
const QS = [{"q": "雪だるまの帽子によくある色は?", "opts": ["黒", "ピンク", "黄色"], "a": 0}, {"q": "マフラーの定番の色は?", "opts": ["白", "赤", "緑"], "a": 1}, {"q": "雪だるまの目によく使うものは?", "opts": ["花", "石", "紙"], "a": 1}, {"q": "鼻によく使うものは?", "opts": ["きゅうり", "トマト", "にんじん"], "a": 2}];
const STATUS = "雪だるま色当て";
const GUIDE = "上下で選択肢を変える ・ うなずきで答える ・ 4問で集計";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._qi = 0; this._choice = 0; this._correct = 0; this._done = false; this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; if (this._done) { d.r0 = '集計が終わりました'; d.r1 = '正解 ' + this._correct + ' / 全4問'; d.r2 = ''; d.r3 = ''; d.r4 = '第4問まで終えました'; d.r5 = '正解 ' + this._correct + '問'; d.big = '結果 ' + this._correct + '問正解'; d.detail = KIND + 'を終えました。記録に残しました。'; } else { var q = QS[this._qi]; d.r0 = q.q; var i; for (i = 0; i < 3; i++) { d['r' + (i + 1)] = ((i === this._choice ? '▶ ' : '・ ') + q.opts[i]); } d.r4 = '第' + (this._qi + 1) + '問 / 全4問'; d.r5 = '正解 ' + this._correct + '問'; d.big = '第' + (this._qi + 1) + '問'; d.detail = '上下で選択肢を変える ・ うなずきで答える'; } d.guide = GUIDE; d.evt = 'EVT: ' + this._qi + '/4 correct ' + this._correct; this.setData(d); },
  answerTap() { if (this._done) { this._nav('/pages/index/index'); return; } var q = QS[this._qi]; if (this._choice === q.a) { this._correct++; this._speak('正解です。'); } else { this._speak('はずれました。正解は' + q.opts[q.a] + 'です。'); } this._qi++; if (this._qi >= 4) { this._done = true; this._finish(KIND, this._correct + '問正解', this._correct, this._correct + '問正解'); this._speak(KIND + 'が終わりました。正解は' + this._correct + '問でした。'); } else { this._choice = 0; } this._recompute(); },
  primaryTap() { this.answerTap(); },
  nextTap() { if (!this._done) { this._choice = (this._choice + 1) % 3; this._recompute(); } },
  prevTap() { if (!this._done) { this._choice = (this._choice + 2) % 3; this._recompute(); } },
  speakTap() { if (this._done) this._speak('結果は' + this._correct + '問正解でした。'); else this._speak(QS[this._qi].q + 'です。'); },
  backTap() { this._back(); },

  _saveBest(score, text) { var st = this._load(); if (!st.best) st.best = {}; var old = st.best[String(this._sel)]; var oldN = (old === undefined || old === null) ? -1 : parseInt(old, 10); if (isNaN(oldN)) oldN = -1; if (score > oldN) { st.best[String(this._sel)] = text; this._save(st); } },
  _finish(kind, item, score, text) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: kind, item: item, at: new Date().toISOString() }); this._save(st); this._saveBest(score, text); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'fuyu-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },

};
</script>

<template>
  <div class="page">
    <div class="band">雪だるま色当て</div>
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
.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:9px 12px;border:2px solid #40ff5e;border-radius:24px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:24px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
