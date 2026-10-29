<script def>
{
  "title": "긴급 전화"
}
</script>

<script setup>
import wx from 'wx';

// KR20 busan-trip-hub - t18
const KEY = "busanTripHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const NUMS = ["경찰 · 112", "소방 · 119", "관광 안내 · 1330", "시청 안내 · 120", "해상 구조 · 122"];
const REC_KIND = "t18";
const STATUS = "긴급 전화번호 목록";
const GUIDE = "다음으로 번호 바꾸기 · 음성 안내로 듣기 · 기록 남기기로 저장 · 고개 끄덕임은 주 확인";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._noted = {}; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; var i; for (i = 0; i < NUMS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + NUMS[i] + (this._noted[i] ? ' · 기록됨' : '')); } d.big = NUMS[this._idx]; d.detail = '필요할 때 바로 부를 수 있도록 번호를 확인합니다.'; d.guide = GUIDE; d.evt = 'EVT: ' + NUMS[this._idx]; this.setData(d); },
  speakTap() { this._speak(NUMS[this._idx]); },
  primaryTap() { this.speakTap(); },
  noteTap() { this._noted[this._idx] = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, text: NUMS[this._idx], at: new Date().toISOString() }); this._save(st); this._speak('기록했습니다. ' + NUMS[this._idx]); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % NUMS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + NUMS.length - 1) % NUMS.length; this._recompute(); },
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
    <div class="band">긴급 전화</div>
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
      <button class="btn main" bindtap="speakTap">음성 안내</button>
      <button class="btn" bindtap="nextTap">다음</button>
      <button class="btn" bindtap="noteTap">기록 남기기</button>
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
.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;letter-spacing:2px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
