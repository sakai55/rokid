<script def>
{
  "title": "갈래길 안내"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "hangangCycleV1";
const DEF = {"selected": 0, "point": null, "records": []};
const ZONES = ["왼쪽 갈래길", "직진", "오른쪽 갈래길"];
const CARD = ["북", "북동", "동", "남동", "남", "남서", "서", "북서"];
const STATUS = "등록한 쉼터로 가는 갈래길 안내";
const GUIDE = "방향은 북쪽 기준 8방위이고 거리는 오차를 포함한 어림값입니다. 실내에서는 GPS가 약해 잴 수 없는 경우가 있습니다.";
const REC_KIND = "도착 기록";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._bearing = null; this._dist = null; this._zone = 1; this._sensorOk = false; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._zone = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (!st.point) { d.big = '미등록'; d.r0 = '먼저 첫 페이지에서 쉼터를 등록하세요'; d.r1 = '등록하지 않은 곳으로는 안내하지 않습니다'; d.r2 = ''; } else if (this._bearing === null) { d.big = ZONES[this._zone]; d.r0 = '갈래길: ' + ZONES[this._zone]; d.r1 = '아직 잴지 않았습니다 · 현재 위치 측정을 누르세요'; d.r2 = this._sensorOk ? '머리 방향이 갈래길을 고릅니다' : '센서가 없어 버튼으로 갈래길을 바꿉니다'; } else { d.big = CARD[this._bearing] + ' · 약 ' + this._dist + 'm'; d.r0 = '갈래길: ' + ZONES[this._zone]; d.r1 = '쉼터 방향: ' + CARD[this._bearing]; d.r2 = '거리: 약 ' + this._dist + 'm(오차를 포함한 어림값입니다)'; } d.detail = st.point ? '등록된 쉼터로 안내합니다' : '미등록입니다'; d.guide = GUIDE; d.evt = 'EVT: guide'; this.setData(d); },
  primaryTap() { var self = this; var st = this._load(); if (!st.point) { this._recompute(); return; } this._geo(function (p) { var r = self._calc(p.coords.latitude, p.coords.longitude, st.point.lat, st.point.lon); self._bearing = r.card; self._dist = r.dist; self._speak('쉼터는 ' + CARD[r.card] + ', 약 ' + r.dist + '미터입니다.'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }); },
  arriveTap() { var st = this._load(); if (!st.point) { this._speak('미등록입니다'); this._recompute(); return; } if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: st.point.name + ' · ' + ZONES[this._zone], at: new Date().toISOString() }); this._save(st); this._speak('도착을 기록했습니다.'); this._recompute(); },
  zoneTap() { this._zone = (this._zone + 1) % 3; this._recompute(); },
  nextTap() { this.zoneTap(); },
  prevTap() { this._zone = (this._zone + 2) % 3; this._recompute(); },
  speakTap() { if (this._bearing === null) this._speak('아직 잴지 않았습니다.'); else this._speak('쉼터는 ' + CARD[this._bearing] + ', 약 ' + this._dist + '미터입니다.'); },
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
    <div class="band">갈래길 안내</div>
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
      <button class="btn" bindtap="backTap">뒤로</button>
      <button class="btn main" bindtap="primaryTap">현재 위치 측정</button>
      <button class="btn" bindtap="arriveTap">도착 기록</button>
      <button class="btn" bindtap="zoneTap">갈래길 바꾸기</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
