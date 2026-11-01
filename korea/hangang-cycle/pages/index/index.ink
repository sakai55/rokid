<script def>
{
  "title": "한강 자전거 길"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "hangangCycleV1";
const PLACES = ["뚝섬 갈래길", "잠실대교 갈래길", "반포대교 쉼터", "동작대교 갈래길", "여의도 쉼터", "양화대교 갈래길", "난지 쉼터", "망원 쉼터"];
const DEF = {"selected": 0, "point": null, "records": []};
const STATUS = "한강 자전거 길에서 갈래길을 고르고 GPS로 쉼터를 찾습니다";
const GUIDE = "등록하면 지금 있는 곳을 쉼터 이름으로 저장합니다 · 안내에서 방향과 거리를 봅니다 · 고개 끄덕임은 주 확인입니다";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < PLACES.length; i++) { d['r' + i] = ((i === this._idx ? '\u25b6 ' : '\u00b7 ') + PLACES[i]); } d.big = PLACES[this._idx]; d.detail = st.point ? ('등록됨: ' + st.point.name + ' · 위도 ' + st.point.lat.toFixed(4) + ' 경도 ' + st.point.lon.toFixed(4)) : '미등록입니다'; d.guide = GUIDE; d.evt = 'EVT: ' + PLACES[this._idx]; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % PLACES.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + PLACES.length - 1) % PLACES.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  saveTap() { var self = this; this._geo(function (p) { var st = self._load(); st.point = { name: PLACES[self._idx], lat: p.coords.latitude, lon: p.coords.longitude, at: new Date().toISOString() }; st.selected = self._idx; self._save(st); self._speak(PLACES[self._idx] + ' 등록했습니다.'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }); },
  guideTap() { this._saveSel(); this._nav('/pages/guide/index'); },
  recordTap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.guideTap(); },
  speakTap() { this._speak(PLACES[this._idx]); },
  backTap() { this._back(); },

  _geo(ok, fail) { if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); return; } try { navigator.geolocation.getCurrentPosition(ok, fail, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); } },
  _calc(lat1, lon1, lat2, lon2) { var toRad = function (x) { return x * Math.PI / 180; }; var dLat = toRad(lat2 - lat1); var dLon = toRad(lon2 - lon1); var a1 = toRad(lat1), a2 = toRad(lat2); var y = Math.sin(dLon) * Math.cos(a2); var x = Math.cos(a1) * Math.sin(a2) - Math.sin(a1) * Math.cos(a2) * Math.cos(dLon); var br = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360; var R = 6371000; var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(a1) * Math.cos(a2) * Math.sin(dLon / 2) * Math.sin(dLon / 2); var dist = 2 * R * Math.asin(Math.sqrt(h)); return { card: Math.round(br / 45) % 8, dist: Math.round(dist / 10) * 10 }; },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'hangang-cycle', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">한강 자전거 길</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    <div class="rrow">{{ r6 }}</div>
    <div class="rrow">{{ r7 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="saveTap">지금 위치 등록</button>
      <button class="btn" bindtap="guideTap">갈래길 안내</button>
      <button class="btn" bindtap="recordTap">기록</button>
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
.rrow{color:#7dff9e;font-size:14px;line-height:20px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
