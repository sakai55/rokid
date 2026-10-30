<script def>
{
  "title": "음식 주문"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "jejuTripHubV1";
const DEF = {"selected": 0, "checked": {}, "tools": {}, "records": [], "completed": {}, "spoken": {}, "counts": {}, "quiz": {}};
const GUIDE = "위로 아래로 고르기 · 열기로 쓰기 · 고개 끄덕임은 주 확인";
const RECALL = "이 도구의 확인이 모두 끝났습니다.";

const TOOL = "t18";
const TOOLNAME = "음식 주문";
const PHRASES = ["흑돼지 구이 일 인분 주세요", "해물뚝배기 하나 주세요", "맵지 않게 해 주세요", "계산서 주세요"];

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = '골라서 대신 말하기'; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + PHRASES[i]); } d.big = TOOLNAME; d.detail = '고른 말을 음성으로 읽어줍니다.'; d.guide = GUIDE; d.evt = 'EVT: ' + TOOLNAME; this.setData(d); },
  primaryTap() { var ph = PHRASES[this._idx]; var st = this._load(); if (!st.spoken) st.spoken = {}; var arr = st.spoken[TOOL] || []; if (arr.indexOf(ph) < 0) arr.push(ph); st.spoken[TOOL] = arr; if (!st.tools) st.tools = {}; st.tools[TOOL] = { done: arr.length, total: PHRASES.length }; if (arr.length >= PHRASES.length) { if (!st.completed) st.completed = {}; st.completed[TOOL] = true; } if (!st.records) st.records = []; st.records.push({ kind: '대신 말하기', item: ph, at: new Date().toISOString() }); this._save(st); this._speak(ph); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % 4; this._recompute(); },
  prevTap() { this._idx = (this._idx + 3) % 4; this._recompute(); },
  speakTap() { this._speak(PHRASES[this._idx]); },
  backTap() { this._back(); },

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
    <div class="band">음식 주문</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">돌아가기</button>
      <button class="btn main" bindtap="primaryTap">대신 말하기</button>
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
.band{background-color:#0a3320;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 12px;letter-spacing:1px;border-bottom:2px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#12331f;color:#7dff9e;border:1px solid rgba(64,255,94,0.8);border-radius:10px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
