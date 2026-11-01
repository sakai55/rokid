<script def>
{
  "title": "公園集合"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "koenShuugouV1";
const PLACES = ["公園東のベンチ", "中央の噴水前", "桜の木の下", "西のあずまや", "池のほとり", "南の入口広場"];
const DEF = {"selected": 0, "point": null, "records": []};
const STATUS = "公園で集まる場所を登録し、方角と距離で案内します";
const GUIDE = "登録で今いる場所を集合場所にする ・ 案内で方角と距離を見る ・ うなずきは主確認";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < PLACES.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '・ ') + PLACES[i]); } d.big = PLACES[this._idx]; d.detail = st.point ? ('登録済み: ' + st.point.name + ' ・ 緯度 ' + st.point.lat.toFixed(4) + ' 経度 ' + st.point.lon.toFixed(4)) : '未登録です'; d.guide = GUIDE; d.evt = 'EVT: ' + PLACES[this._idx]; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % PLACES.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + PLACES.length - 1) % PLACES.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  saveTap() { var self = this; if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var st = self._load(); st.point = { name: PLACES[self._idx], lat: p.coords.latitude, lon: p.coords.longitude, at: new Date().toISOString() }; st.selected = self._idx; self._save(st); self._speak(PLACES[self._idx] + 'を集合場所に登録しました。'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); } },
  guideTap() { this._saveSel(); this._nav('/pages/guide/index'); },
  recordTap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.guideTap(); },
  speakTap() { this._speak(PLACES[this._idx] + 'です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'koen-shuugou', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">公園集合</div>
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
      <button class="btn main" bindtap="saveTap">場所に登録</button>
      <button class="btn" bindtap="guideTap">帰路案内</button>
      <button class="btn" bindtap="recordTap">記録</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.band{background-color:#0e2f16;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 12px;border-left:10px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0e2f16;color:#7dff9e;border:2px solid rgba(64,255,94,0.7);border-radius:16px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
