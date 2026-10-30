<script def>
{
  "title": "駅弁選び"
}
</script>

<script setup>
import wx from 'wx';

// JP42 nihon-tabi-hub - t17
const KEY = "nihonTabiHubV1";
const TID = "t17";
const QS = [{"q": "長い移動に合う駅弁はどれでしょう", "opts": ["冷めてもおいしい弁当", "温かい汁物", "生もの中心の弁当"], "ans": 0, "explain": "冷めてもおいしい弁当は長い移動に向いています。"}, {"q": "乗換時間が短いときの買い方はどれでしょう", "opts": ["ゆっくり選ぶ", "事前に決めて買う", "車内で探す"], "ans": 1, "explain": "乗換時間が短いときは事前に決めて買うと安心です。"}, {"q": "ごみが出にくい選び方はどれでしょう", "opts": ["容器が小さい弁当", "大きな容器の弁当", "汁物が多い弁当"], "ans": 0, "explain": "容器が小さい弁当はごみが少なく済みます。"}];
const QSTATUS = "駅弁選びクイズ：{i} / {t} 問 · {s} 点";
const CHOOSETXT = "選んで決定で答えます";
const CORRECTTXT = "正解です。";
const WRONG1 = "違います。答えは ";
const WRONG2 = "です。";
const ANSSEP = " · ";
const ANSLBL = "答え： ";
const GUIDE = "上下で選択を変える · 決定で答える · うなずきは決定と同じ";
const REC_KIND = "駅弁選びクイズ";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); var q = (st.quiz && st.quiz[TID]) || {}; this._qi = (typeof q.qi === 'number') ? q.qi : 0; this._score = (typeof q.score === 'number') ? q.score : 0; this._answered = (typeof q.answered === 'number') ? q.answered : 0; this._oi = 0; this._done = false; this._recompute(); },
  _recompute() { var qq = QS[this._qi]; var d = {}; d.status = QSTATUS.replace('{i}', (this._qi + 1)).replace('{t}', QS.length).replace('{s}', this._score); d.big = qq.q; var i; for (i = 0; i < 3; i++) { d['r' + i] = ((i === this._oi ? '▶ ' : '· ') + qq.opts[i]); } d.detail = this._done ? (ANSLBL + qq.opts[qq.ans] + ANSSEP + qq.explain) : CHOOSETXT; d.guide = GUIDE; d.evt = 'EVT: Q' + (this._qi + 1) + ' score ' + this._score; this.setData(d); },
  _persist() { var st = this._load(); if (!st.quiz) st.quiz = {}; st.quiz[TID] = { qi: this._qi, score: this._score, answered: this._answered }; if (!st.tools) st.tools = {}; st.tools[TID] = { done: this._answered, total: QS.length }; this._save(st); },
  primaryTap() { var qq = QS[this._qi]; if (this._done) { var last = (this._qi >= QS.length - 1); this._qi = (this._qi + 1) % QS.length; this._oi = 0; this._done = false; if (last) { this._answered = 0; this._score = 0; } this._persist(); this._recompute(); return; } this._done = true; if (this._oi === qq.ans) { this._score++; this._speak(CORRECTTXT + qq.explain); } else { this._speak(WRONG1 + qq.opts[qq.ans] + WRONG2 + qq.explain); } this._answered = this._qi + 1; if (this._qi >= QS.length - 1) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, score: this._score, at: new Date().toISOString() }); this._save(st); } this._persist(); this._recompute(); },
  nextTap() { if (!this._done) this._oi = (this._oi + 1) % 3; this._recompute(); },
  prevTap() { if (!this._done) this._oi = (this._oi + 2) % 3; this._recompute(); },
  speakTap() { var qq = QS[this._qi]; this._speak(qq.q + '。' + qq.opts.join('、')); },
  backTap() { this._back(); },

  _fresh() { return {"selected": 0, "tools": {}, "marks": {}, "counts": {}, "quiz": {}, "spoken": {}, "records": []}; },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return this._fresh(); },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = this._fresh(); st.lastError = { code: code, slug: 'nihon-tabi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">駅弁選び</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">決定する</button>
      <button class="btn" bindtap="nextTap">選択を変える</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:19px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.band{background-color:#000000;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 0;text-align:center;border-top:2px solid #40ff5e;border-bottom:2px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#000000;color:#40ff5e;border:2px solid #40ff5e;border-radius:50px;font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
