<script def>
{
  "title": "Score Math"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "canadaHockeyGamesV1";
const SLUG = "canada-hockey-games";
const GI = 9;
const GNAME = "Score Math";
const DEF = {"selected": 0, "best": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._opt = 0; this._done = false; this._score = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var best = (st.best && st.best[String(GI)]) ? st.best[String(GI)] : 0; var d = {}; d.status = "Nod to play - settling writes a record"; d.r0 = "7 + 5 = ?"; var i; for (i = 0; i < 3; i++) { d['r' + (i + 1)] = ((i === this._opt ? '> ' : '- ') + ["12", "11", "13"][i]); } d.r4 = this._done ? ("Score: " + this._score) : ''; d.r5 = "Best: " + best; d.big = this._done ? ("Settled " + this._score) : ["12", "11", "13"][this._opt]; d.detail = "Best kept across sessions"; d.guide = "Nod or tap Count - Finish settles early - Back returns to the hub"; d.evt = 'EVT: math opt ' + this._opt; this.setData(d); },
  _settle() { this._done = true; this._score = (this._opt === 0) ? 10 : 0; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: GNAME, item: this._score + ' / 10', at: new Date().toISOString() }); if (!st.best) st.best = {}; if (!st.best[String(GI)] || this._score > st.best[String(GI)]) st.best[String(GI)] = this._score; this._save(st); this._speak("Score: " + this._score); this._recompute(); },
  actionTap() { if (this._done) { this._nav('/pages/index/index'); return; } this._settle(); },
  secondTap() { if (this._done) { this._nav('/pages/index/index'); return; } this._opt = (this._opt + 1) % 3; this._recompute(); },
  primaryTap() { this.actionTap(); },
  nextTap() { this.secondTap(); },
  prevTap() { this._recompute(); },
  speakTap() { this._speak("7 + 5 = ?"); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: SLUG, version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }

};

</script>

<template>
  <div class="page">
    <div class="band">Score Math</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="actionTap">Count</button><button class="btn" bindtap="secondTap">Next</button><button class="btn" bindtap="backTap">Back</button><button class="btn" bindtap="speakTap">Speak</button>
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
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:16px;font-size:13px;padding:7px 0;text-align:center;}
</style>
