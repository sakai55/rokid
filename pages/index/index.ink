<script def>
{
  "title": "제주 여행 수첩"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "jejuTripHubV1";
const DEF = {"selected": 0, "checked": {}, "tools": {}, "records": [], "completed": {}, "spoken": {}, "counts": {}, "quiz": {}};
const GUIDE = "위로 아래로 고르기 · 열기로 쓰기 · 고개 끄덕임은 주 확인";
const RECALL = "이 도구의 확인이 모두 끝났습니다.";

const TOOLS = [{"name": "공항 도착", "url": "/pages/t01/index"}, {"name": "렌터카", "url": "/pages/t02/index"}, {"name": "버스 노선", "url": "/pages/t03/index"}, {"name": "한라산 등산", "url": "/pages/t04/index"}, {"name": "해변 산책", "url": "/pages/t05/index"}, {"name": "시장", "url": "/pages/t06/index"}, {"name": "카페 주문", "url": "/pages/t07/index"}, {"name": "박물관", "url": "/pages/t08/index"}, {"name": "감귤 따기", "url": "/pages/t09/index"}, {"name": "숙박 체크", "url": "/pages/t10/index"}, {"name": "사진 명소", "url": "/pages/t11/index"}, {"name": "기념품 목록", "url": "/pages/t12/index"}, {"name": "환전 계산", "url": "/pages/t13/index"}, {"name": "날씨 옷차림", "url": "/pages/t14/index"}, {"name": "분실물 체크", "url": "/pages/t15/index"}, {"name": "긴급 전화", "url": "/pages/t16/index"}, {"name": "한국어 인사", "url": "/pages/t17/index"}, {"name": "음식 주문", "url": "/pages/t18/index"}, {"name": "환승 시간", "url": "/pages/t19/index"}, {"name": "여행 기록", "url": "/pages/t20/index"}];
const TOTALS = [4, 5, 4, 5, 5, 4, 4, 4, 10, 5, 4, 6, 3, 3, 5, 4, 4, 4, 4, 6];

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected : 0; this._recompute(); },
  onShow() { var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected : 0; this._recompute(); },
  _doneOf(i, st) { if (i === 19) return Math.min(st.records ? st.records.length : 0, 6); var k = 't' + ((i + 1 < 10) ? '0' + (i + 1) : '' + (i + 1)); if (st.tools && st.tools[k]) return st.tools[k].done || 0; return 0; },
  _recompute() { var st = this._load(); var d = {}; d.status = '제주 여행 수첩 · 도구 스무 가지'; var i; var doneAll = 0; for (i = 0; i < TOOLS.length; i++) doneAll += this._doneOf(i, st); for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name + ' ' + this._doneOf(ti, st) + '/' + TOTALS[ti]); } d.big = TOOLS[this._idx].name; d.detail = '전체 진행 ' + doneAll + ' / 93 · 기록 ' + (st.records ? st.records.length : 0) + '건'; d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name); },

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
    <div class="band">제주 여행 수첩</div>
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
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d2b16;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
