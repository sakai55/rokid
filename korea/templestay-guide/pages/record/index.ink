<script def>
{
  "title": "템플스테이 안내"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "templestayGuideV1";
const SLUG = "templestay-guide";
const STAGES = ["산문 맞이", "선방 예절", "다례", "발우공양", "새벽 종소리 순례", "마무리 기록"];
const STEPS = [["산문에 들어서며 인사하기", "사찰 예절 안내 듣기", "숙소 배정 확인하기", "짐 정리하고 옷 갈아입기"], ["선방에 조용히 들어서기", "방석에 바르게 앉기", "합장하고 인사하기", "좌선 호흡 가다듬기"], ["다실에 들어서기", "찻잔 데우기", "차 우리고 따르기", "차를 마시며 고요히 있기"], ["발우 그릇 받기", "공양 게송 함께 읽기", "음식을 조금씩 덜어 먹기", "그릇 닦은 물 마시기"], ["새벽에 일어나기", "범종 소리 듣기", "절 마당 천천히 걷기", "새벽 예불 참여하기"], ["체험 되돌아보기", "느낀 점 한 줄 적기", "다음 방문 다짐하기", "산문을 나서며 인사하기"]];
const DEF = {"selected": 0, "checks": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var recs = st.records || []; var last = recs.slice(-6).reverse(); var d = {}; d.status = "체험 기록"; var i; for (i = 0; i < 6; i++) { d['r' + i] = (i < last.length) ? ('· ' + last[i].item + ' · ' + last[i].kind) : '· 아직 기록이 없습니다'; } d.big = (recs.length > 0) ? ("체험 기록 " + recs.length + ' 건') : "아직 체험 기록이 없습니다"; d.detail = '최근 6건을 보여줍니다'; d.guide = "기록은 4걸음을 마쳤을 때 남습니다"; d.evt = 'EVT: ' + recs.length + ' records'; this.setData(d); },
  primaryTap() { this.indexTap(); },
  indexTap() { this._nav('/pages/index/index'); },
  speakTap() { var st = this._load(); var recs = st.records || []; this._speak((recs.length > 0) ? ("체험 기록이 " + recs.length + "건 있습니다.") : "아직 체험 기록이 없습니다"); },
  nextTap() { this._recompute(); },
  prevTap() { this._recompute(); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: SLUG, version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }

};

</script>

<template>
  <div class="page">
    <div class="band">템플스테이 안내</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="backTap">돌아가기</button><button class="btn" bindtap="indexTap">처음으로</button><button class="btn" bindtap="speakTap">음성</button><button class="btn" bindtap="nextTap">새로고침</button>
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
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;border-bottom:2px solid #40ff5e;text-align:left;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-left:4px solid #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
</style>
