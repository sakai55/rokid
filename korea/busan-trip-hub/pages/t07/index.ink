<script def>
{
  "title": "환전 계산"
}
</script>

<script setup>
import wx from 'wx';

// KR20 busan-trip-hub - t07
const KEY = "busanTripHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const REC_KIND = "t07";
const STATUS = "외화 금액에 환율을 곱해 원으로 바꾸기";
const GUIDE = "금액과 환율을 버튼으로 바꾸고 계산하기로 확인 · 고개 끄덕임은 주 확인";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._amt = 50; this._rate = 1300; this._total = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; d.r0 = '외화 금액: ' + this._amt; d.r1 = '환율: ' + this._rate + '원'; d.r2 = '계산 결과: ' + this._total + '원'; d.big = this._total + '원'; d.detail = '외화 ' + this._amt + '에 환율 ' + this._rate + '원을 곱하면 ' + this._total + '원입니다.'; d.guide = GUIDE; d.evt = 'EVT: ' + this._amt + ' x ' + this._rate + ' = ' + this._total; this.setData(d); },
  amtUpTap() { this._amt = this._amt + 10; this._recompute(); },
  amtDownTap() { this._amt = Math.max(0, this._amt - 10); this._recompute(); },
  rateUpTap() { this._rate = this._rate + 10; this._recompute(); },
  rateDownTap() { this._rate = Math.max(0, this._rate - 10); this._recompute(); },
  calcTap() { this._total = this._amt * this._rate; this._speak('계산 결과는 ' + this._total + '원입니다.'); this._recompute(); },
  primaryTap() { this.calcTap(); },
  doneTap() { this._total = this._amt * this._rate; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, text: this._amt + ' x ' + this._rate + ' = ' + this._total, at: new Date().toISOString() }); this._save(st); this._speak('기록했습니다. ' + this._total + '원입니다.'); this._recompute(); },
  nextTap() { this.amtUpTap(); },
  prevTap() { this.amtDownTap(); },
  speakTap() { this._speak('외화 ' + this._amt + ', 환율 ' + this._rate + '원, 결과 ' + this._total + '원입니다.'); },
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
      <button class="btn" bindtap="amtUpTap">금액 더하기</button>
      <button class="btn" bindtap="amtDownTap">금액 빼기</button>
      <button class="btn" bindtap="rateUpTap">환율 올리기</button>
      <button class="btn" bindtap="rateDownTap">환율 내리기</button>
    </div>
    <div class="btnrow">
      <button class="btn main" bindtap="calcTap">계산하기</button>
      <button class="btn" bindtap="doneTap">기록하기</button>
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
.band{background-color:#0d2b16;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
