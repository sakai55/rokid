<script def>
{
  "title": "한국어 인사"
}
</script>

<script setup>
import wx from 'wx';

// KR20 busan-trip-hub - t19
const KEY = "busanTripHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const PHRASES = ["안녕하세요", "감사합니다", "죄송합니다", "괜찮아요", "잘 먹겠습니다", "안녕히 가세요"];
const REC_KIND = "t19";
const STATUS = "문구 듣고 따라 말하기";
const GUIDE = "다음으로 문구 바꾸기 · 음성 안내로 대신 말하기 · 완료로 기록 · 고개 끄덕임은 주 확인";
const ALLDONE = "이 문구를 사용했다고 기록했습니다.";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._spoken = {}; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; var i; for (i = 0; i < PHRASES.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + PHRASES[i] + (this._spoken[i] ? ' · 말했음' : '')); } d.big = PHRASES[this._idx]; d.detail = '고른 문장을 음성으로 대신 말합니다.'; d.guide = GUIDE; d.evt = 'EVT: ' + PHRASES[this._idx]; this.setData(d); },
  speakTap() { this._spoken[this._idx] = true; this._speak(PHRASES[this._idx]); this._recompute(); },
  primaryTap() { this.speakTap(); },
  doneTap() { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, text: PHRASES[this._idx], at: new Date().toISOString() }); this._save(st); this._speak(ALLDONE); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % PHRASES.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + PHRASES.length - 1) % PHRASES.length; this._recompute(); },
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
    <div class="band">한국어 인사</div>
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
      <button class="btn" bindtap="backTap">돌아가기</button>
      <button class="btn" bindtap="prevTap">이전</button>
      <button class="btn main" bindtap="speakTap">음성 안내</button>
      <button class="btn" bindtap="nextTap">다음</button>
      <button class="btn" bindtap="doneTap">완료 기록</button>
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
.band{background-color:#0d2b16;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
