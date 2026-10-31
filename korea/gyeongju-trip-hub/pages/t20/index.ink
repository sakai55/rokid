<script def>
{
  "title": "여행 기록"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "gyeongjuTripHubV1";
const DEF = {"selected": 0, "checked": {}, "counts": {}, "records": []};
const ITEMS = ["아침 기록", "점심 기록", "저녁 기록", "밤 기록", "하루 정리"];
const GUIDE = "다음으로 항목 바꾸기 · 주 확인으로 진행 · 고개 끄덕임은 주 확인";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._cnt = 0; this._done = false; this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = '세기: ' + this._cnt + ' / ' + ITEMS.length + ' 곳'; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + ITEMS[i]); } d.big = '' + this._cnt + ' / ' + ITEMS.length + ' 곳'; d.detail = this._done ? '세기가 끝났습니다.' : ('지금 셀 항목: ' + ITEMS[this._idx] + ' 입니다'); d.guide = GUIDE; d.evt = 'EVT: ' + this._cnt + '/' + ITEMS.length; this.setData(d); },
  countTap() { if (this._done) { this._speak('세기가 끝났습니다.'); this._recompute(); return; } this._cnt++; if (this._cnt >= ITEMS.length) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '여행 기록 완료', item: '여행 기록', at: new Date().toISOString() }); this._save(st); this._speak('세기가 끝났습니다.'); } else { this._speak(ITEMS[this._idx]); } this._idx = (this._idx + 1) % ITEMS.length; this._recompute(); },
  primaryTap() { this.countTap(); },
  nextTap() { this._idx = (this._idx + 1) % ITEMS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._recompute(); },
  speakTap() { this._speak(ITEMS[this._idx]); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'gyeongju-trip-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">여행 기록</div>
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
      <button class="btn main" bindtap="countTap">세기</button>
      <button class="btn" bindtap="nextTap">다음</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;letter-spacing:2px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
