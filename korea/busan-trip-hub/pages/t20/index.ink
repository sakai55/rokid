<script def>
{
  "title": "집합 장소 안내"
}
</script>

<script setup>
import wx from 'wx';

// KR20 busan-trip-hub - t20
const KEY = "busanTripHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const REC_KIND = "t20";
const CARDS = ["북", "북동", "동", "남동", "남", "남서", "서", "북서"];
const STATUS = "집합 장소를 등록하고 방향과 거리로 안내";
const GUIDE = "장소 등록으로 지금 위치 저장 · 길 안내로 방향과 거리 확인 · 고개 끄덕임은 주 확인";
const NOTE = "값은 대략적인 값입니다. 지피에스 신호가 약한 곳에서는 정확도가 떨어집니다.";
const NOTREG = "미등록";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._card = ''; this._dist = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (st.spot) { d.r0 = '등록된 장소: 위도 ' + st.spot.lat + ' · 경도 ' + st.spot.lon; } else { d.r0 = '등록된 장소: ' + NOTREG; } d.r1 = (this._card === '') ? '방향: 아직 안내하지 않았습니다.' : ('방향: ' + this._card); d.r2 = (this._dist === 0) ? '거리: 아직 안내하지 않았습니다.' : ('거리: 약 ' + this._dist + '미터'); d.big = (this._card === '') ? NOTREG : (this._card + ' · 약 ' + this._dist + '미터'); d.detail = NOTE; d.guide = GUIDE; d.evt = 'EVT: ' + ((st.spot) ? 'registered' : 'unregistered'); this.setData(d); },
  _calc(lat1, lon1, lat2, lon2) { var R = 6371000; var dLat = (lat2 - lat1) * Math.PI / 180; var dLon = (lon2 - lon1) * Math.PI / 180; var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2); var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); var dist = R * c; var y = Math.sin(dLon) * Math.cos(lat2 * Math.PI / 180); var x = Math.cos(lat1 * Math.PI / 180) * Math.sin(lat2 * Math.PI / 180) - Math.sin(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.cos(dLon); var brg = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360; var card = CARDS[Math.round(brg / 45) % 8]; return { card: card, dist: Math.round(dist / 10) * 10 }; },
  _geoOk() { return (typeof navigator !== 'undefined' && navigator.geolocation && navigator.geolocation.getCurrentPosition); },
  saveTap() { var self = this; if (!this._geoOk()) { this._fail('E7002', 'geolocation n/a'); this._recompute(); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var st = self._load(); st.spot = { lat: p.coords.latitude, lon: p.coords.longitude, at: new Date().toISOString() }; self._save(st); self._speak('집합 장소를 등록했습니다.'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); self._recompute(); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); this._recompute(); } },
  guideTap() { var self = this; var st = this._load(); if (!st.spot) { this._card = ''; this._dist = 0; this._recompute(); return; } if (!this._geoOk()) { this._fail('E7002', 'geolocation n/a'); this._recompute(); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var r = self._calc(p.coords.latitude, p.coords.longitude, st.spot.lat, st.spot.lon); self._card = r.card; self._dist = r.dist; var st2 = self._load(); if (!st2.records) st2.records = []; st2.records.push({ kind: REC_KIND, text: r.card + ' ' + r.dist, at: new Date().toISOString() }); self._save(st2); self._speak('집합 장소는 ' + r.card + ' 방향, 약 ' + r.dist + '미터입니다.'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); self._recompute(); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); this._recompute(); } },
  primaryTap() { this.guideTap(); },
  nextTap() { this.guideTap(); },
  prevTap() { this._recompute(); },
  speakTap() { var st = this._load(); if (!st.spot) { this._speak('등록된 집합 장소가 없습니다.'); return; } if (this._card === '') { this._speak('길 안내를 먼저 눌러 주세요.'); return; } this._speak('집합 장소는 ' + this._card + ' 방향, 약 ' + this._dist + '미터입니다.'); },
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
    <div class="band">집합 장소 안내</div>
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
      <button class="btn main" bindtap="saveTap">장소 등록</button>
      <button class="btn main" bindtap="guideTap">길 안내</button>
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
.band{background-color:#123d2a;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
