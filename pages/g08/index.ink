<script def>
{
  "title": "Face Painting Pick"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "usFairGamesV1";
const DEF = {"selected": 0, "records": []};
const ROUNDS = [{"prompt": "Paint a red heart", "opts": ["Blue paint", "Red paint", "Green paint"], "best": 1}, {"prompt": "Paint a golden star", "opts": ["Golden paint", "Silver paint", "Purple paint"], "best": 0}, {"prompt": "Paint a green frog", "opts": ["Pink paint", "Orange paint", "Green paint"], "best": 2}];
const STATUS = "County fair game: pick the right paint";
const GUIDE = "Move to change game or choice - nod confirms - head back to center between steps";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._round = 0; this._score = 0; this._sel = 0; this._optN = 3; this._wasCenter = true; this._done = false; this._lastWhy = ''; this._startSensor(); this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; if (this._done) { d.big = 'Done! ' + this._score + '/' + ROUNDS.length; d.detail = 'Game over. Score ' + this._score + ' of ' + ROUNDS.length + '.'; for (var i = 0; i < 3; i++) d['r' + i] = '· ' + ROUNDS[0].opts[i]; } else { var r = ROUNDS[this._round]; var i; for (i = 0; i < 3; i++) { d['r' + i] = ((i === this._sel ? '▶ ' : '· ') + r.opts[i]); } d.big = 'Round ' + (this._round + 1) + ' of ' + ROUNDS.length; d.detail = r.prompt + ' - turn head one step at a time, recenter between steps, nod to pick.'; } d.guide = GUIDE; d.evt = 'EVT: ' + this._round + '/' + ROUNDS.length + ' score ' + this._score; this.setData(d); },
  primaryTap() { if (this._done) { this._back(); return; } var r = ROUNDS[this._round]; if (this._sel === r.best) { this._score++; this._speak('Correct!'); } else { this._speak('Not that one. The answer was ' + r.opts[r.best] + '.'); } this._round++; this._sel = 0; this._wasCenter = true; if (this._round >= ROUNDS.length) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: 'Game record', item: "Face Painting Pick", score: this._score, at: new Date().toISOString() }); this._save(st); this._speak('Game over. Score ' + this._score + ' of ' + ROUNDS.length + '.'); } this._recompute(); },
  nextTap() { if (this._done) return; this._sel = (this._sel + 1) % 3; this._recompute(); },
  prevTap() { if (this._done) return; this._sel = (this._sel + 2) % 3; this._recompute(); },
  speakTap() { if (this._done) this._speak('Game over.'); else this._speak(ROUNDS[this._round].prompt + ' ' + ROUNDS[this._round].opts[this._sel] + '.'); },
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
    <div class="band">Face Painting Pick</div>
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
      <button class="btn main" bindtap="primaryTap">Pick</button>
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
