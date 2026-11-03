<script def>
{
  "title": "김장 단계"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "kimjangStepsV1";
const STAGES = ["배추 절이기", "양념 만들기", "버무리기", "통에 담기", "숙성 확인", "나눔 기록"];
const DEF = {"pos": 0, "doneCount": 0, "records": []};
const STATUS = "손이 양념으로 바쁠 때 고개 끄덕임으로 단계를 넘기는 김장 안내";
const GUIDE = "위아래로 단계를 고르고 고개를 끄덕이면 시작합니다 · 손을 쓰지 않아도 됩니다";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 6; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + STAGES[i]); } d.big = STAGES[this._idx]; d.detail = '완성한 통 수: ' + (st.doneCount || 0) + '통 · 진행 중인 단계: ' + (Math.floor((st.pos || 0) / 4) + 1) + '/6'; d.guide = GUIDE; d.evt = 'EVT: ' + STAGES[this._idx]; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % STAGES.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + STAGES.length - 1) % STAGES.length; this._recompute(); },
  startTap() { var st = this._load(); st.pos = this._idx * 4; this._save(st); this._nav('/pages/steps/index'); },
  recordTap() { this._nav('/pages/record/index'); },
  primaryTap() { this.startTap(); },
  speakTap() { this._speak(STAGES[this._idx] + '입니다.'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'kimjang-steps', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">김장 단계</div>
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
      <button class="btn main" bindtap="startTap">단계 시작</button>
      <button class="btn" bindtap="recordTap">기록</button>
      <button class="btn" bindtap="nextTap">다음 단계</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
      <button class="btn" bindtap="backTap">뒤로</button>
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
