<script def>
{
  "title": "防災避難"
}
</script>

<script setup>
import wx from 'wx';

// JP40 bosai-hinan - index
const KEY = "bosaiHinanV1";
const DEF = {"selected": 0, "point": null, "records": []};
const STATUS = "地震のあと、避難場所へ向かいます";
const GUIDE = "避難場所に着いたら「ここを登録」を押してください。公式の避難情報が優先です。屋内では GPS が弱いことがあります。";
function DETAILFN(st) { return '到着の記録は' + ((st.records || []).length) + '件です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; d.big = st.point ? '登録済み' : '未登録'; d.r0 = st.point ? ('緯度 ' + st.point.lat.toFixed(4)) : '避難場所はまだ登録されていません'; d.r1 = st.point ? ('経度 ' + st.point.lon.toFixed(4)) : '避難場所に着いたら、ここで登録してください'; d.r2 = st.point ? ('登録時刻 ' + st.point.at) : '登録していない場所へは案内しません'; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: point ' + (st.point ? 'saved' : 'none'); this.setData(d); },
  saveTap() { var self = this; if (typeof navigator === 'undefined' || !navigator.geolocation || !navigator.geolocation.getCurrentPosition) { this._fail('E7002', 'geolocation n/a'); this._recompute(); return; } try { navigator.geolocation.getCurrentPosition(function (p) { var st = self._load(); st.point = { lat: p.coords.latitude, lon: p.coords.longitude, acc: p.coords.accuracy, at: new Date().toISOString().slice(0, 16) }; self._save(st); self._speak('避難場所を登録しました。'); self._recompute(); }, function (err) { if (err && err.code === 1) self._fail('E7003', 'geolocation denied'); else self._fail('E7002', 'geolocation error'); self._recompute(); }, { enableHighAccuracy: false, timeout: 10000 }); } catch (e) { this._fail('E7002', 'geolocation'); this._recompute(); } },
  primaryTap() { this.saveTap(); },
  guideTap() { this._nav('/pages/guide/index'); },
  recordTap() { this._nav('/pages/record/index'); },
  nextTap() { this._recompute(); },
  prevTap() { this._recompute(); },
  speakTap() { var st = this._load(); this._speak(st.point ? '避難場所は登録済みです。' : '避難場所はまだ登録されていません。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'bosai-hinan', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">防災避難</div>
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
      <button class="btn main" bindtap="saveTap">ここを登録</button>
      <button class="btn" bindtap="guideTap">帰路案内</button>
      <button class="btn" bindtap="recordTap">記録を見る</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
      <button class="btn" bindtap="backTap">もどる</button>
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
.band{background-color:#0a2a1a;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-top:2px solid #40ff5e;border-bottom:6px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:6px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
