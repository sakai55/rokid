<script def>
{
  "title": "김장 단계 안내"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "kimjangStepsV1";
const STAGES = ["배추 절이기", "양념 만들기", "버무리기", "통에 담기", "숙성 확인", "나눔 기록"];
const STEPS = [["배추를 반으로 가른다", "소금물에 배추를 담근다", "배추를 뒤집어 골고루 절인다", "절인 배추를 물에 헹군다"], ["고춧가루를 준비한다", "마늘과 생강을 다진다", "젓갈과 설탕을 섞는다", "양념 맛을 본다"], ["절인 배추에 양념을 바른다", "배추 잎 사이사이 양념을 넣는다", "버무린 배추를 한 번 더 확인한다", "남은 양념을 위에 얹는다"], ["통을 깨끗이 씻는다", "버무린 배추를 통에 차곡차곡 담는다", "통 윗면을 평평하게 누른다", "뚜껑을 닫고 날짜를 적는다"], ["하루 뒤 거품이 이는지 본다", "이틀 뒤 냄새를 맡아본다", "맛을 보아 익었는지 확인한다", "먹기 좋은 상태인지 적어둔다"], ["나눌 이웃을 정한다", "나눌 양을 따로 담는다", "나눔 날짜를 기록한다", "다음 김장 날짜를 정한다"]];
const DEF = {"pos": 0, "doneCount": 0, "records": []};
const STATUS = "김장 단계 안내";
const GUIDE = "고개를 끄덕이면 다음 단계로 넘어갑니다 · 음성 안내가 다음 단계를 읽어줍니다";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _cur() { var st = this._load(); var pos = st.pos || 0; if (pos >= 24) pos = 0; return { stage: Math.floor(pos / 4), step: pos % 4, pos: pos }; },
  _recompute() { var st = this._load(); var c = this._cur(); var steps = STEPS[c.stage]; var d = {}; d.status = STATUS; d.r0 = '단계 ' + (c.stage + 1) + '/6: ' + STAGES[c.stage]; var i; for (i = 0; i < 4; i++) { d['r' + (i + 1)] = ((i === c.step ? '▶ ' : (i < c.step ? '완료 ' : '· ')) + steps[i]); } d.r5 = (c.pos + 1 < 24) ? ('다음: ' + STEPS[Math.floor((c.pos + 1) / 4)][(c.pos + 1) % 4]) : '마지막 단계입니다'; d.big = steps[c.step]; d.detail = '전체 ' + (c.pos + 1) + '/24단계 · 완성한 통 수: ' + (st.doneCount || 0) + '통'; d.guide = GUIDE; d.evt = 'EVT: step ' + (c.pos + 1) + '/24'; this.setData(d); },
  nextTap() { var c = this._cur(); var st = this._load(); var pos = c.pos + 1; if (pos >= 24) { if (!st.records) st.records = []; st.records.push({ kind: '김장 한 통 완성', item: '24단계 완료', at: new Date().toISOString() }); st.doneCount = (st.doneCount || 0) + 1; st.pos = 0; this._save(st); this._speak('한 통을 다 담갔습니다. 완성한 통이 ' + st.doneCount + '통이 되었습니다.'); } else { st.pos = pos; this._save(st); var nc = { stage: Math.floor(pos / 4), step: pos % 4 }; this._speak(STEPS[nc.stage][nc.step] + '입니다.'); } this._recompute(); },
  primaryTap() { this.nextTap(); },
  prevTap() { this._recompute(); },
  speakTap() { var c = this._cur(); this._speak(STEPS[c.stage][c.step] + '입니다.'); },
  recordTap() { this._nav('/pages/record/index'); },
  indexTap() { this._nav('/pages/index/index'); },
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
    <div class="band">김장 단계 안내</div>
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
      <button class="btn main" bindtap="nextTap">다음 단계</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
      <button class="btn" bindtap="recordTap">기록</button>
      <button class="btn" bindtap="indexTap">처음으로</button>
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
