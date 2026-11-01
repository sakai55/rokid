<script def>
{
  "title": "Guide to Stop"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "londonBusMeetV1";
const DEF = {"selected": 0, "point": null, "records": []};
const CARD = ["North", "North-East", "East", "South-East", "South", "South-West", "West", "North-West"];
const STATUS = "Guide to your registered bus stop";
const GUIDE = "Direction is an 8-point compass from north; distance is an estimate including GPS error. GPS is weak indoors and may fail.";
const REC_KIND = "Arrival record";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._bearing = null; this._dist = null; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (!st.point) { d.big = 'Not registered'; d.r0 = 'Register a stop on the first page first'; d.r1 = 'No guide is given to a place that is not registered'; d.r2 = ''; } else if (this._bearing === null) { d.big = 'Measure now'; d.r0 = 'The meeting point is registered'; d.r1 = 'Press Measure now to see direction and distance'; d.r2 = 'GPS is weak indoors and may fail'; } else { d.big = CARD[this._bearing] + ' - about ' + this._dist + 'm'; d.r0 = 'Direction to the stop: ' + CARD[this._bearing]; d.r1 = 'Distance: about ' + this._dist + 'm (an estimate including error)'; d.r2 = 'Face that way and walk on'; } d.detail = st.point ? 'Guiding to the registered meeting point' : 'Not registered'; d.guide = GUIDE; d.evt = 'EVT: guide'; this.setData(d); },
  primaryTap() { var self = this; var st = this._load(); if (!st.point) { this._recompute(); return; } this._geo(function (p) { var r = self._calc(p.coords.latitude, p.coords.longitude, st.point.lat, st.point.lon); self._bearing = r.card; self._dist = r.dist; self._speak('The meeting point is ' + CARD[r.card] + ', about ' + r.dist + ' metres.'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }); },
  arriveTap() { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: (st.point ? st.point.name : 'Meeting point'), at: new Date().toISOString() }); this._save(st); this._speak('Arrival recorded.'); this._recompute(); },
  nextTap() { this.primaryTap(); },
  prevTap() { this._recompute(); },
  speakTap() { if (this._bearing === null) this._speak('Not measured yet.'); else this._speak('The meeting point is ' + CARD[this._bearing] + ', about ' + this._dist + ' metres.'); },
  backTap() { this._back(); },

  _geo(ok, fail) { if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); return; } try { navigator.geolocation.getCurrentPosition(ok, fail, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); } },
  _calc(lat1, lon1, lat2, lon2) { var toRad = function (x) { return x * Math.PI / 180; }; var dLat = toRad(lat2 - lat1); var dLon = toRad(lon2 - lon1); var a1 = toRad(lat1), a2 = toRad(lat2); var y = Math.sin(dLon) * Math.cos(a2); var x = Math.cos(a1) * Math.sin(a2) - Math.sin(a1) * Math.cos(a2) * Math.cos(dLon); var br = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360; var R = 6371000; var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(a1) * Math.cos(a2) * Math.sin(dLon / 2) * Math.sin(dLon / 2); var dist = 2 * R * Math.asin(Math.sqrt(h)); return { card: Math.round(br / 45) % 8, dist: Math.round(dist / 10) * 10 }; },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'london-bus-meet', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">Guide to Stop</div>
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
      <button class="btn" bindtap="backTap">Back</button>
      <button class="btn main" bindtap="primaryTap">Measure now</button>
      <button class="btn" bindtap="arriveTap">Arrived</button>
      <button class="btn" bindtap="speakTap">Speak</button>
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
.band{background-color:#0a2a1a;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-top:2px solid #40ff5e;border-bottom:6px solid #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:6px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
