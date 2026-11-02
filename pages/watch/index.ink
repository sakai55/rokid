<script def>
{
  "title": "Hut Cook Watch"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "nzHutCookWatchV1";
const COOKERS = [{"name": "Hut Stove - Soup Pot", "mins": 30}, {"name": "Hut Stove - Rice Pot", "mins": 25}, {"name": "Camp Burner - Kettle", "mins": 5}, {"name": "Camp Burner - Pasta Pot", "mins": 12}, {"name": "Fireplace Pot - Stew", "mins": 40}, {"name": "Solar Cooker - Porridge", "mins": 20}];
const DEF = {"selected": 0, "timers": [null, null, null], "records": []};
const GUIDE = "Look left, centre or right to switch slots · Nod starts the selected cooker timer · A finished timer speaks and records on Finish";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._slot = 1; this._sensorOk = false; this._announced = ''; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._slot = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _remain(t) { if (!t) return null; var left = t.mins * 60000 - (Date.now() - t.startedAt); return Math.max(0, Math.ceil(left / 60000)); },
  _slotText(t, i) { if (!t) return 'Slot ' + (i + 1) + ': empty'; var r = this._remain(t); return 'Slot ' + (i + 1) + ': ' + t.name + ' · ' + (r <= 0 ? 'Done!' : (r + ' min left')); },
  _recompute() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; var d = {}; d.status = 'Watch · Slot ' + (this._slot + 1) + (this._sensorOk ? ' · head direction connected' : ' · head sensor off, buttons switch slots'); var i; for (i = 0; i < 3; i++) { d['r' + i] = ((i === this._slot ? '▶ ' : '· ') + this._slotText(timers[i], i)); } if (t && this._remain(t) <= 0) { d.big = t.name + ' is done!'; if (this._announced !== ('slot' + this._slot + ':' + t.startedAt)) { this._announced = 'slot' + this._slot + ':' + t.startedAt; this._speak(t.name + ' is done. Turn it off.'); } } else if (t) { d.big = t.name + ' · ' + this._remain(t) + ' min left'; } else { d.big = 'To time: ' + COOKERS[this._sel].name; } d.detail = 'Selected cooker: ' + COOKERS[this._sel].name + ' · ' + COOKERS[this._sel].mins + ' min'; d.guide = GUIDE; d.evt = 'EVT: slot ' + (this._slot + 1); this.setData(d); },
  startTap() { var st = this._load(); if (!st.timers) st.timers = [null, null, null]; var t = st.timers[this._slot]; if (t && this._remain(t) > 0) { this._speak('This slot is already timing.'); this._recompute(); return; } var p = COOKERS[this._sel]; st.timers[this._slot] = { name: p.name, mins: p.mins, startedAt: Date.now() }; this._save(st); this._speak(p.name + ' timer started, ' + p.mins + ' minutes.'); this._recompute(); },
  finishTap() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; if (!t) { this._speak('This slot has no timer yet.'); this._recompute(); return; } if (this._remain(t) > 0) { this._speak(t.name + ' has ' + this._remain(t) + ' minutes left. Not done yet.'); this._recompute(); return; } if (!st.records) st.records = []; st.records.push({ kind: 'Cooking done', item: t.name, at: new Date().toISOString() }); timers[this._slot] = null; st.timers = timers; this._save(st); this._speak(t.name + ' is done. Finish recorded.'); this._recompute(); },
  primaryTap() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; if (t && this._remain(t) <= 0) this.finishTap(); else this.startTap(); },
  nextTap() { this._slot = (this._slot + 1) % 3; this._recompute(); },
  prevTap() { this._slot = (this._slot + 2) % 3; this._recompute(); },
  speakTap() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; if (!t) this._speak('This slot has no timer yet.'); else if (this._remain(t) <= 0) this._speak(t.name + ' is done. Turn it off.'); else this._speak(t.name + ' has ' + this._remain(t) + ' minutes left.'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'nz-hut-cook-watch', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">Hut Cook Watch</div>
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
      <button class="btn main" bindtap="startTap">Start timer</button>
      <button class="btn" bindtap="finishTap">Finish</button>
      <button class="btn" bindtap="nextTap">Next slot</button>
      <button class="btn" bindtap="speakTap">Speak</button>
      <button class="btn" bindtap="backTap">Back</button>
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
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0f3d24;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 12px;border-left:6px solid #40ff5e;border-radius:10px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0f3d24;color:#7dff9e;border:1px solid #40ff5e;border-left:4px solid #40ff5e;border-radius:12px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
