<script def>
{
  "title": "帰路"
}
</script>

<script setup>
import wx from 'wx';

// JP30 hanabi-kaeri - guide
const KEY = "hanabiKaeriV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const CARD = ['北', '北東', '東', '南東', '南', '南西', '西', '北西'];
const STATUS = "集合場所への帰路";
const GUIDE = "現地で「ここを登録」を押すと、集合場所を保存します。屋内では GPS が弱いことがあります。位置は測れたときだけ表示し、測れないときは測れないと出します。";
const REC_KIND = "到着記録";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._bearing = null; this._dist = null; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (!st.point) { d.big = '未登録'; d.r0 = '先にトップで集合場所を登録してください'; d.r1 = ''; d.r2 = ''; } else if (this._bearing === null) { d.big = '測位してください'; d.r0 = '集合場所は登録済みです'; d.r1 = '「現在地を測る」を押すと、方角と距離が出ます'; d.r2 = '屋内では GPS が弱く、測れないことがあります'; } else { d.big = CARD[this._bearing] + ' ・ 約' + this._dist + 'm'; d.r0 = '集合場所の方角: ' + CARD[this._bearing]; d.r1 = '距離: 約' + this._dist + 'm（誤差を含む概算です）'; d.r2 = 'そちらを向いて進んでください'; } d.detail = st.point ? '登録済みの集合場所へ案内します' : '未登録です'; d.guide = GUIDE; d.evt = 'EVT: guide'; this.setData(d); },
  _calc(lat1, lon1, lat2, lon2) { var toRad = function (x) { return x * Math.PI / 180; }; var dLat = toRad(lat2 - lat1); var dLon = toRad(lon2 - lon1); var a1 = toRad(lat1), a2 = toRad(lat2); var y = Math.sin(dLon) * Math.cos(a2); var x = Math.cos(a1) * Math.sin(a2) - Math.sin(a1) * Math.cos(a2) * Math.cos(dLon); var br = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360; var R = 6371000; var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(a1) * Math.cos(a2) * Math.sin(dLon / 2) * Math.sin(dLon / 2); var dist = 2 * R * Math.asin(Math.sqrt(h)); return { card: Math.round(br / 45) % 8, dist: Math.round(dist / 10) * 10 }; },
  primaryTap() { var self = this; var st = this._load(); if (!st.point) { this._recompute(); return; } if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var r = self._calc(p.coords.latitude, p.coords.longitude, st.point.lat, st.point.lon); self._bearing = r.card; self._dist = r.dist; self._speak('集合場所は' + CARD[r.card] + '、約' + r.dist + 'メートルです。'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); } },
  arriveTap() { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, at: new Date().toISOString() }); this._save(st); this._speak('到着を記録しました。'); this._recompute(); },
  nextTap() { this.primaryTap(); },
  prevTap() { this._recompute(); },
  speakTap() { if (this._bearing === null) this._speak('まだ測位していません。'); else this._speak('集合場所は' + CARD[this._bearing] + '、約' + this._dist + 'メートルです。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'hanabi-kaeri', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">帰路</div>
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
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">現在地を測る</button>
      <button class="btn" bindtap="arriveTap">到着した</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.hubrows .rrow{font-size:11px;line-height:15px;}

.band{background-color:#000000;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 0;text-align:center;border-top:2px solid #40ff5e;border-bottom:2px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#000000;color:#40ff5e;border:2px solid #40ff5e;border-radius:50px;font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
