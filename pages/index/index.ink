<script def>
{
  "title": "서울 생활 수첩"
}
</script>

<script setup>
import wx from 'wx';

// KR19 seoul-life-hub - index
const KEY = "seoulLifeHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const TOOLS = [{"name": "지하철 환승", "url": "/pages/t01/index"}, {"name": "버스 번호", "url": "/pages/t02/index"}, {"name": "시장 장보기", "url": "/pages/t03/index"}, {"name": "약국", "url": "/pages/t04/index"}, {"name": "날씨 옷차림", "url": "/pages/t05/index"}, {"name": "편의점", "url": "/pages/t06/index"}, {"name": "카페 주문", "url": "/pages/t07/index"}, {"name": "환전 계산", "url": "/pages/t08/index"}, {"name": "관광지", "url": "/pages/t09/index"}, {"name": "박물관", "url": "/pages/t10/index"}, {"name": "공원 산책", "url": "/pages/t11/index"}, {"name": "한강 피크닉", "url": "/pages/t12/index"}, {"name": "도서관", "url": "/pages/t13/index"}, {"name": "우체국", "url": "/pages/t14/index"}, {"name": "은행 자동화기기", "url": "/pages/t15/index"}, {"name": "휴대폰 충전", "url": "/pages/t16/index"}, {"name": "우산", "url": "/pages/t17/index"}, {"name": "분실물", "url": "/pages/t18/index"}, {"name": "긴급 전화", "url": "/pages/t19/index"}, {"name": "한국어 인사", "url": "/pages/t20/index"}];
const NOWTXT = "지금: ";
const CHOOSETXT = "골라서 결정으로 답하기";
const CORRECTTXT = "맞았습니다.";
const WRONG1 = "틀렸습니다. 답은 ";
const WRONG2 = "입니다.";
const QEND = ".";
const QSEP = ", ";
const GOALTXT = " · 목표 달성";
const CNT1 = ", 지금 ";
const CNT2 = ", 목표는 ";
const CNT3 = "입니다.";
const REC1 = "기록은 ";
const REC2 = "건입니다.";
const RECNONE = "기록이 아직 없습니다.";
const PHRASEDETAIL = "고른 문장을 음성으로 대신 말합니다.";
const WORDLAST = "마지막 단어입니다. 다 말했으면 완료를 누르세요.";
const WORDNEXT = "고개를 끄덕일 때마다 다음 단어로 넘어갑니다.";
const WORDDONE = "다 말했습니다.";
const LINELAST = "마지막 줄입니다.";
const LINENEXT = "고개를 끄덕일 때마다 다음 줄로 넘어갑니다.";
const LINEDONE = "다 읽었습니다.";
const HUBEND = "입니다.";
const STATUS = "서울에서 일주일을 보내는 동안, 생활 도구 20개를 한 권으로 씁니다";
const GUIDE = "다음으로 도구를 바꾸기 · 열기로 쓰기 · 고개 끄덕임은 주 확인";
function DETAILFN(st) { return '사용한 기록은 ' + (st.records ? st.records.length : 0) + '건입니다.'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name); } d.big = TOOLS[this._idx].name; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + HUBEND); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'seoul-life-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">서울 생활 수첩</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">열기</button>
      <button class="btn" bindtap="nextTap">다음</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.hubrows .rrow{font-size:11px;line-height:15px;}

.band{background-color:#0d2b16;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
