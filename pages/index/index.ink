<script def>
{
  "title": "County Fair Games"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "usFairGamesV1";
const TOOLS = [{"name": "Ring Toss", "url": "/pages/g01/index"}, {"name": "Balloon Pop", "url": "/pages/g02/index"}, {"name": "Duck Pond Pick", "url": "/pages/g03/index"}, {"name": "Pie Eating Rhythm", "url": "/pages/g04/index"}, {"name": "Corn Hole Aim", "url": "/pages/g05/index"}, {"name": "Milk Bottle Knock", "url": "/pages/g06/index"}, {"name": "Horseshoe Toss", "url": "/pages/g07/index"}, {"name": "Face Painting Pick", "url": "/pages/g08/index"}, {"name": "Ferris Wheel Order", "url": "/pages/g09/index"}, {"name": "Livestock Weight Guess", "url": "/pages/g10/index"}, {"name": "Pie Contest Quiz", "url": "/pages/g11/index"}, {"name": "Lemonade Price Calc", "url": "/pages/g12/index"}, {"name": "Sack Race Steps", "url": "/pages/g13/index"}, {"name": "Bean Bag Aim", "url": "/pages/g14/index"}, {"name": "Fishing Pond Count", "url": "/pages/g15/index"}, {"name": "Photo Booth Poses", "url": "/pages/g16/index"}, {"name": "Hay Bale Lift", "url": "/pages/g17/index"}, {"name": "Apple Bobbing Timing", "url": "/pages/g18/index"}, {"name": "Fireworks Sequence", "url": "/pages/g19/index"}, {"name": "Fair Food Quiz", "url": "/pages/g20/index"}];
const DEF = {"selected": 0, "records": []};
const STATUS = "County fair wait time: 20 fair games on one pair of glasses";
const GUIDE = "Move to change game or choice - nod confirms - head back to center between steps";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name); } d.big = TOOLS[this._idx].name; var total = st.records ? st.records.length : 0; var best = null; var j; for (j = 0; j < total; j++) { if (st.records[j].item === TOOLS[this._idx].name && (best === null || st.records[j].score > best)) best = st.records[j].score; } d.detail = 'Played games: ' + total + ' records' + ((best === null) ? ' - this game not played yet' : (' - best score ' + best)); d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + '.'); },
  backTap() { this._speak('County fair games hub.'); },

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
    <div class="band">County Fair Games</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">Open</button>
      <button class="btn" bindtap="nextTap">Next</button>
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
.rrow{color:#7dff9e;font-size:13px;line-height:20px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3319;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 12px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:8px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
