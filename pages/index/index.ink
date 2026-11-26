<script def>
{
  "title": "강릉 여행 수첩"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "gangneungTripHubV1";
const SLUG = "gangneung-trip-hub";
const TOOLS = [{"name": "경포해변", "url": "/pages/t01/index"}, {"name": "안목해변 커피거리", "url": "/pages/t02/index"}, {"name": "오죽헌", "url": "/pages/t03/index"}, {"name": "강릉중앙시장", "url": "/pages/t04/index"}, {"name": "초당순두부", "url": "/pages/t05/index"}, {"name": "정동진", "url": "/pages/t06/index"}, {"name": "선교장", "url": "/pages/t07/index"}, {"name": "경포호", "url": "/pages/t08/index"}, {"name": "강릉역 환승", "url": "/pages/t09/index"}, {"name": "대관령", "url": "/pages/t10/index"}, {"name": "강릉단오제", "url": "/pages/t11/index"}, {"name": "아르떼뮤지엄 강릉", "url": "/pages/t12/index"}, {"name": "하슬라아트월드", "url": "/pages/t13/index"}, {"name": "주문진항", "url": "/pages/t14/index"}, {"name": "강릉 올림픽파크", "url": "/pages/t15/index"}, {"name": "커피박물관", "url": "/pages/t16/index"}, {"name": "강릉 사진 명소", "url": "/pages/t17/index"}, {"name": "강릉 기념품 목록", "url": "/pages/t18/index"}, {"name": "강릉 날씨 옷차림", "url": "/pages/t19/index"}, {"name": "강릉 여행 기록", "url": "/pages/t20/index"}];
const DEF = {"selected": 0, "best": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = "강릉 여행 수첩, 20가지 여행 도구"; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '> ' : '- ') + TOOLS[ti].name); } d.r5 = ''; d.big = TOOLS[this._idx].name; d.detail = "최고： " + ((st.best && st.best[String(this._idx)]) ? st.best[String(this._idx)] : "아직 없음") + " 끝낸 기록： " + (st.records ? st.records.length : 0) + "건"; d.guide = "밀기로 도구를 고르고 끄덕이거나 열기로 시작한다"; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  openTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  primaryTap() { this.openTap(); },
  speakTap() { this._speak(TOOLS[this._idx].name); },
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
    <div class="band">강릉 여행 수첩</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="openTap">열기</button><button class="btn" bindtap="nextTap">다음</button><button class="btn" bindtap="speakTap">음성</button><button class="btn" bindtap="backTap">돌아가기</button>
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

.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:2px solid #40ff5e;border-radius:8px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:8px;font-size:13px;padding:7px 0;text-align:center;}
</style>
