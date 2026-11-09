<script def>
{
  "title": "해운대 만남"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "haeundaeMeetV1";
const SLUG = "haeundae-meet";
const POINTS = ["해운대해수욕장 입구", "동백섬 입구", "달맞이길 입구", "마린시티 더베이101 앞", "해운대역 3번 출구", "해운대구청 앞"];
const CARD = ["북", "북동", "동", "남동", "남", "남서", "서", "북서"];
const DEF = {"selected": 0, "point": null, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._bearing = null; this._dist = null; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = "방위 8방향과 거리로 만남 장소까지 안내합니다"; var sel = (typeof st.selected === 'number') ? st.selected : 0; if (!st.point) { d.big = "아직 등록 안 됨"; d.r0 = "지금 만남 장소: " + POINTS[sel]; d.r1 = "만남 장소 등록을 눌러 지금 위치를 저장하세요"; d.r2 = "등록하기 전에는 방위 안내를 드리지 않습니다"; } else if (this._bearing === null) { d.big = "위치 측정 대기"; d.r0 = "만남 장소: " + st.point.name; d.r1 = "위치 측정을 눌러 방위와 거리를 확인하세요"; d.r2 = "실내나 GPS가 약한 곳에서는 측정이 안 될 수 있습니다"; } else { d.big = CARD[this._bearing] + ' - ' + this._dist + " m"; d.r0 = "만남 장소 방향: " + CARD[this._bearing]; d.r1 = "거리: 약 " + this._dist + " m(추정치)"; d.r2 = "이 방향으로 걸어가세요"; } d.r3 = ''; d.r4 = ''; d.r5 = ''; d.detail = st.point ? ("등록됨: " + st.point.name) : "아직 등록 안 됨"; d.guide = "먼저 등록하고 위치를 측정하세요 · 거리는 추정치이며 10 m 단위입니다 · 등록하지 않았거나 위치를 쓸 수 없을 때는 지어내지 않습니다"; d.evt = 'EVT: guide'; this.setData(d); },
  _calc(lat1, lon1, lat2, lon2) { var toRad = function (x) { return x * Math.PI / 180; }; var dLat = toRad(lat2 - lat1); var dLon = toRad(lon2 - lon1); var a1 = toRad(lat1), a2 = toRad(lat2); var y = Math.sin(dLon) * Math.cos(a2); var x = Math.cos(a1) * Math.sin(a2) - Math.sin(a1) * Math.cos(a2) * Math.cos(dLon); var br = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360; var R = 6371000; var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(a1) * Math.cos(a2) * Math.sin(dLon / 2) * Math.sin(dLon / 2); var dist = 2 * R * Math.asin(Math.sqrt(h)); return { card: Math.round(br / 45) % 8, dist: Math.round(dist / 10) * 10 }; },
  primaryTap() { var self = this; var st = this._load(); if (!st.point) { this._recompute(); return; } if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var r = self._calc(p.coords.latitude, p.coords.longitude, st.point.lat, st.point.lon); self._bearing = r.card; self._dist = r.dist; self._speak("만남 장소는 " + CARD[r.card] + " 방향이며 약 " + r.dist + " m입니다."); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); } },
  saveTap() { var self = this; var st = this._load(); var sel = (typeof st.selected === 'number') ? st.selected : 0; if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var s2 = self._load(); s2.point = { name: POINTS[sel], lat: p.coords.latitude, lon: p.coords.longitude, at: new Date().toISOString() }; s2.selected = sel; self._save(s2); self._speak(POINTS[sel] + " 등록했습니다."); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); } },
  arriveTap() { var st = this._load(); if (!st.point) { this._speak("먼저 만남 장소를 등록하세요."); this._recompute(); return; } if (!st.records) st.records = []; st.records.push({ kind: "만남 장소 도착", item: st.point.name, at: new Date().toISOString() }); this._save(st); this._speak("만남 장소 도착을 기록했습니다."); this._recompute(); },
  nextTap() { this.primaryTap(); },
  prevTap() { this._recompute(); },
  speakTap() { if (this._bearing === null) this._speak("아직 위치를 측정하지 않았습니다."); else this._speak("만남 장소는 " + CARD[this._bearing] + " 방향이며 약 " + this._dist + " m입니다."); },
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
    <div class="band">해운대 만남</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">위치 측정</button><button class="btn" bindtap="saveTap">만남 장소 등록</button><button class="btn" bindtap="arriveTap">도착 기록</button><button class="btn" bindtap="backTap">돌아가기</button>
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

.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;border-bottom:2px solid #40ff5e;text-align:left;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-left:4px solid #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
</style>
