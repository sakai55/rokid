<script def>
{
  "title": "Ferris Wheel Order"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "usFairGamesV1";
const DEF = {"selected": 0, "records": []};
const ITEMS = [{"name": "Green car", "note": "48 feet high"}, {"name": "Red car", "note": "40 feet high"}, {"name": "Yellow car", "note": "36 feet high"}, {"name": "Blue car", "note": "32 feet high"}];
const CORRECT = [0, 1, 2, 3];
const STATUS = "County fair game: order cars tallest first";
const GUIDE = "Move to change game or choice - nod confirms - head back to center between steps";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._slots = []; this._sel = 0; this._optN = ITEMS.length; this._wasCenter = true; this._done = false; this._score = 0; this._startSensor(); this._recompute(); },
  _picked(i) { var j; for (j = 0; j < this._slots.length; j++) if (this._slots[j] === i) return true; return false; },
  _recompute() { var d = {}; d.status = STATUS; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._sel && !this._done) ? '▶ ' : '· ') + ITEMS[i].name + ' - ' + ITEMS[i].note + (this._picked(i) ? ' picked' : ''); } if (this._done) { d.big = 'Done! ' + this._score + '/' + ITEMS.length; d.detail = 'Order complete. Score ' + this._score + ' of ' + ITEMS.length + ' positions right.'; } else { d.big = 'Pick number ' + (this._slots.length + 1); d.detail = 'Turn head one step at a time, recenter, nod to lock this pick.'; } d.guide = GUIDE; d.evt = 'EVT: ' + this._slots.length + '/' + ITEMS.length; this.setData(d); },
  primaryTap() { if (this._done) { this._back(); return; } if (this._picked(this._sel)) { this._speak('Already picked. Move to another.'); return; } this._slots.push(this._sel); if (this._slots.length >= ITEMS.length) { this._done = true; var s = 0; var i; for (i = 0; i < ITEMS.length; i++) if (this._slots[i] === CORRECT[i]) s++; this._score = s; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: 'Game record', item: "Ferris Wheel Order", score: this._score, at: new Date().toISOString() }); this._save(st); this._speak('Order complete. Score ' + s + ' of ' + ITEMS.length + '.'); } this._recompute(); },
  nextTap() { if (this._done) return; var n = 0; do { this._sel = (this._sel + 1) % ITEMS.length; n++; } while (this._picked(this._sel) && n <= ITEMS.length); this._recompute(); },
  prevTap() { if (this._done) return; var n = 0; do { this._sel = (this._sel + ITEMS.length - 1) % ITEMS.length; n++; } while (this._picked(this._sel) && n <= ITEMS.length); this._recompute(); },
  speakTap() { if (this._done) this._speak('Order complete.'); else this._speak(ITEMS[this._sel].name + '.'); },
  backTap() { this._back(); },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); var z = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); if (z === 1) { self._wasCenter = true; } else if (self._wasCenter) { self._wasCenter = false; self._stepSel(z === 0 ? -1 : 1); } self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _stepSel(d) { this._sel = (this._sel + d + this._optN) % this._optN; },

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
    <div class="band">Ferris Wheel Order</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">Back</button>
      <button class="btn main" bindtap="primaryTap">Lock pick</button>
      <button class="btn" bindtap="nextTap">Move</button>
      <button class="btn" bindtap="speakTap">Speak</button>
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
.band{background-color:#0d3319;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 12px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:8px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
