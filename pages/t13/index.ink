<script def>
{
  "title": "환전 계산"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "jejuTripHubV1";
const DEF = {"selected": 0, "checked": {}, "tools": {}, "records": [], "completed": {}, "spoken": {}, "counts": {}, "quiz": {}};
const GUIDE = "위로 아래로 고르기 · 열기로 쓰기 · 고개 끄덕임은 주 확인";
const RECALL = "이 도구의 확인이 모두 끝났습니다.";

const TOOL = "t13";
const TOOLNAME = "환전 계산";
const QS = [{"q": "물건 값이 만 오천 원이고 오만 원을 냈을 때 거스름돈은 얼마입니까", "opts": ["삼만 오천 원", "삼만 원", "사만 원"], "ans": 0, "explain": "오만 원에서 만 오천 원을 빼면 삼만 오천 원입니다."}, {"q": "물건 값이 이만 팔천 원이고 오만 원을 냈을 때 거스름돈은 얼마입니까", "opts": ["이만 이천 원", "이만 원", "삼만 원"], "ans": 0, "explain": "오만 원에서 이만 팔천 원을 빼면 이만 이천 원입니다."}, {"q": "물건 값이 칠천 원이고 만 원을 냈을 때 거스름돈은 얼마입니까", "opts": ["삼천 원", "이천 원", "사천 원"], "ans": 0, "explain": "만 원에서 칠천 원을 빼면 삼천 원입니다."}];

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); var qz = (st.quiz && st.quiz[TOOL]) || {}; this._qi = (typeof qz.qi === 'number') ? qz.qi : 0; this._score = (typeof qz.score === 'number') ? qz.score : 0; this._answered = (typeof qz.answered === 'number') ? qz.answered : 0; this._oi = 0; this._done = false; this._recompute(); },
  _recompute() { var q = QS[this._qi]; var d = {}; d.status = '여행 퀴즈: ' + (this._qi + 1) + ' / ' + QS.length + ' 문제 · ' + this._score + ' 점'; d.big = q.q; var i; for (i = 0; i < 3; i++) { d['r' + i] = ((i === this._oi ? '▶ ' : '· ') + q.opts[i]); } d.detail = this._done ? ('답: ' + q.opts[q.ans] + ' · ' + q.explain) : '골라서 결정으로 답하기'; d.guide = GUIDE; d.evt = 'EVT: Q' + (this._qi + 1) + ' score ' + this._score; this.setData(d); },
  _persist() { var st = this._load(); if (!st.quiz) st.quiz = {}; st.quiz[TOOL] = { qi: this._qi, score: this._score, answered: this._answered }; if (!st.tools) st.tools = {}; st.tools[TOOL] = { done: this._answered, total: QS.length }; this._save(st); },
  primaryTap() { var q = QS[this._qi]; if (this._done) { if (this._qi >= QS.length - 1) { this._qi = 0; this._score = 0; this._answered = 0; var st0 = this._load(); if (st0.completed) st0.completed[TOOL] = false; this._save(st0); } else { this._qi++; } this._oi = 0; this._done = false; this._persist(); this._recompute(); return; } this._done = true; if (this._oi === q.ans) { this._score++; this._speak('맞았습니다. ' + q.explain); } else { this._speak('틀렸습니다. 답은 ' + q.opts[q.ans] + '입니다. ' + q.explain); } this._answered = this._qi + 1; if (this._answered >= QS.length) { var st = this._load(); if (!st.completed) st.completed = {}; if (!st.completed[TOOL]) { st.completed[TOOL] = true; if (!st.records) st.records = []; st.records.push({ kind: TOOLNAME + ' 퀴즈 완료', score: this._score, at: new Date().toISOString() }); } this._save(st); } this._persist(); this._recompute(); },
  nextTap() { if (!this._done) this._oi = (this._oi + 1) % 3; this._recompute(); },
  prevTap() { if (!this._done) this._oi = (this._oi + 2) % 3; this._recompute(); },
  speakTap() { var q = QS[this._qi]; this._speak(q.q + '. ' + q.opts.join(', ')); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._fail('E5002', 'storage read'); } return JSON.parse(JSON.stringify(DEF)); },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || JSON.parse(JSON.stringify(DEF)); st.lastError = { code: code, slug: 'jeju-trip-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace' && this.backTap) { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};

</script>

<template>
  <div class="page">
    <div class="band">환전 계산</div>
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
      <button class="btn" bindtap="backTap">돌아가기</button>
      <button class="btn main" bindtap="primaryTap">결정하기</button>
      <button class="btn" bindtap="nextTap">선택 바꾸기</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
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
.big{color:#7dff9e;font-size:18px;font-weight:bold;margin-top:8px;text-align:center;line-height:26px;}
.rows{margin-top:8px;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
