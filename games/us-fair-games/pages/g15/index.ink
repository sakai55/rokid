<script def>
{
  "title": "Fishing Pond Count"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "usFairGamesV1";
const DEF = {"selected": 0, "records": []};
const ITEM = "Toy fish caught";
const TARGET = 7;
const UNIT = "fish";
const STATUS = "County fair game: count to the target";
const GUIDE = "Move to change game or choice - nod confirms - head back to center between steps";
export default {
  data: { status: '', big: '', r0: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._count = 0; this._zone = 1; this._armed = true; this._done = false; this._startSensor(); this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; d.r0 = ITEM + ' - target ' + TARGET + ' ' + UNIT; d.big = this._done ? 'Done!' : (this._count + ' / ' + TARGET + ' ' + UNIT); d.detail = this._done ? 'All 7 fish caught.' : 'Catch a fish - nod or tap to count one, head back to center between counts'; d.guide = GUIDE; d.evt = 'EVT: ' + this._count + '/' + TARGET; this.setData(d); },
  primaryTap() { if (this._done) { this._back(); return; } if (!this._armed) { this._speak('Head back to center first.'); return; } this._count++; this._armed = false; if (this._count >= TARGET) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: 'Game record', item: ITEM, score: this._count, at: new Date().toISOString() }); this._save(st); this._speak('All 7 fish caught.'); } this._recompute(); },
  speakTap() { this._speak(ITEM + ' ' + this._count + ' of ' + TARGET + ' ' + UNIT + '.'); },
  backTap() { this._back(); },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); var z = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); self._zone = z; if (z === 1) self._armed = true; self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },

  nextTap() { this._zone = (this._zone + 1) % 3; if (this._zone === 1) this._armed = true; this._recompute(); },
  prevTap() { this._zone = (this._zone + 2) % 3; if (this._zone === 1) this._armed = true; this._recompute(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'us-fair-games', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">Fishing Pond Count</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">Back</button>
      <button class="btn main" bindtap="primaryTap">Count</button>
      <button class="btn" bindtap="nextTap">Move</button>
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
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3319;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 12px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:8px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
