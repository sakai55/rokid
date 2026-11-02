<script def>
{
  "title": "Ceilidh Dance"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "irelandDanceStepV1";
const STEPS = ["Sidestep Left", "Sidestep Right", "Forward Step", "Turn Step"];
const TARGETS = [0, 1, 2, 3, 0, 2, 1, 3, 2, 0];
const DEF = {"selected": 0, "best": 0, "records": []};
const STATUS = "Turn your head to pick a step, nod to dance it - 10 rounds";
const GUIDE = "Turn left or right past the centre to change the step · Return to centre before changing again · Buttons also change the step";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._round = 0; this._hits = 0; this._sel = 0; this._centred = true; this._done = false; this._sensorOk = false; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); if (Math.abs(yaw) < 0.35) { self._centred = true; } else if (self._centred && yaw < -0.35) { self._sel = (self._sel + STEPS.length - 1) % STEPS.length; self._centred = false; } else if (self._centred && yaw > 0.35) { self._sel = (self._sel + 1) % STEPS.length; self._centred = false; } self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (this._done) { d.big = 'Settled: ' + this._hits + '/10'; d.r0 = 'Game settled after 10 rounds'; d.r1 = 'Hits: ' + this._hits + ' / 10'; d.r2 = 'Best: ' + (st.best || 0) + '/10'; d.r3 = 'See the record page for past games'; d.r4 = ''; d.r5 = ''; } else { d.big = STEPS[TARGETS[this._round]]; d.r0 = 'Round ' + (this._round + 1) + ' / 10'; d.r1 = 'Target step: ' + STEPS[TARGETS[this._round]]; d.r2 = 'Your step: ' + STEPS[this._sel]; d.r3 = 'Hits: ' + this._hits; d.r4 = 'Best: ' + (st.best || 0) + '/10'; d.r5 = this._sensorOk ? 'Head direction connected' : 'Head sensor off - buttons change the step'; } d.detail = this._done ? 'Game settled - record saved' : 'Dance the target step with a nod'; d.guide = GUIDE; d.evt = 'EVT: round ' + (this._round + 1) + '/10 hits ' + this._hits; this.setData(d); },
  primaryTap() { this.danceTap(); },
  danceTap() { if (this._done) { this._nav('/pages/record/index'); return; } var target = TARGETS[this._round]; if (this._sel === target) { this._hits++; this._speak('Hit! ' + STEPS[target] + '.'); } else { this._speak('Missed. The step was ' + STEPS[target] + '.'); } this._round++; if (this._round >= TARGETS.length) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: 'Ceilidh game settled', item: this._hits + '/10 hits', at: new Date().toISOString() }); if (!st.best || this._hits > st.best) st.best = this._hits; this._save(st); this._speak('Game settled. ' + this._hits + ' hits out of 10.'); } this._recompute(); },
  nextTap() { this._sel = (this._sel + 1) % STEPS.length; this._centred = false; this._recompute(); },
  prevTap() { this._sel = (this._sel + STEPS.length - 1) % STEPS.length; this._centred = false; this._recompute(); },
  speakTap() { if (this._done) this._speak('Game settled. ' + this._hits + ' hits out of 10.'); else this._speak('Round ' + (this._round + 1) + '. Target step: ' + STEPS[TARGETS[this._round]] + '.'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'ireland-dance-step', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">Ceilidh Dance</div>
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
      <button class="btn" bindtap="backTap">Back</button>
      <button class="btn main" bindtap="danceTap">Dance</button>
      <button class="btn" bindtap="nextTap">Change step</button>
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
.rrow{color:#7dff9e;font-size:13px;line-height:19px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d1a;color:#7dff9e;font-size:20px;font-weight:bold;padding:8px 10px;border:3px double #40ff5e;border-radius:4px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d1a;color:#7dff9e;border:2px solid #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
