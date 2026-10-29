<script def>
{
  "title": "부산 여행 수첩"
}
</script>

<script setup>
import wx from 'wx';

// KR20 busan-trip-hub - index
const KEY = "busanTripHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const TOOLS = [{"name": "지하철 노선", "url": "/pages/t01/index"}, {"name": "버스 노선", "url": "/pages/t02/index"}, {"name": "해운대 해수욕장", "url": "/pages/t03/index"}, {"name": "감천문화마을", "url": "/pages/t04/index"}, {"name": "자갈치시장", "url": "/pages/t05/index"}, {"name": "음식 주문 문구", "url": "/pages/t06/index"}, {"name": "환전 계산", "url": "/pages/t07/index"}, {"name": "날씨 복장", "url": "/pages/t08/index"}, {"name": "숙박 체크", "url": "/pages/t09/index"}, {"name": "사진 명소", "url": "/pages/t10/index"}, {"name": "박물관", "url": "/pages/t11/index"}, {"name": "부산타워", "url": "/pages/t12/index"}, {"name": "용두산공원", "url": "/pages/t13/index"}, {"name": "범어사", "url": "/pages/t14/index"}, {"name": "영도 드라이브", "url": "/pages/t15/index"}, {"name": "기념품 목록", "url": "/pages/t16/index"}, {"name": "분실물 체크", "url": "/pages/t17/index"}, {"name": "긴급 전화", "url": "/pages/t18/index"}, {"name": "한국어 인사", "url": "/pages/t19/index"}, {"name": "집합 장소 안내", "url": "/pages/t20/index"}];
const KINDS = ["t01", "t02", "t03", "t04", "t05", "t06", "t07", "t08", "t09", "t10", "t11", "t12", "t13", "t14", "t15", "t16", "t17", "t18", "t19", "t20"];
const STATUS = "부산 여행 수첩 한 권으로 여행 도구 20개를 끝까지 씁니다";
const GUIDE = "다음으로 도구 바꾸기 · 열기로 쓰기 · 고개 끄덕임은 주 확인";
function DETAILFN(st, idx) { var total = (st.records ? st.records.length : 0); var c = 0; var i; if (st.records) { for (i = 0; i < st.records.length; i++) if (st.records[i].kind === KINDS[idx]) c++; } return '이 도구 사용: ' + c + '건 · 전체 사용: ' + total + '건입니다.'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _count(st, kind) { var c = 0; var i; if (st.records) { for (i = 0; i < st.records.length; i++) if (st.records[i].kind === kind) c++; } return c; },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name + ' (' + this._count(st, KINDS[ti]) + '건)'); } d.big = TOOLS[this._idx].name; d.detail = DETAILFN(st, this._idx); d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + '입니다.'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'busan-trip-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">부산 여행 수첩</div>
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
      <button class="btn" bindtap="backTap">돌아가기</button>
      <button class="btn" bindtap="prevTap">이전</button>
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
.band{background-color:#0d2b16;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
