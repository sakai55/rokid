<script def>
{
  "title": "Turkey Math"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "usThanksgivingGamesV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const QS = [{"q": "3 + 4 = ?", "c": ["6", "7", "8"], "a": 1}, {"q": "5 + 2 = ?", "c": ["6", "7", "9"], "a": 1}, {"q": "2 + 6 = ?", "c": ["7", "8", "9"], "a": 1}, {"q": "4 + 4 = ?", "c": ["7", "8", "9"], "a": 1}];
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._q = 0; this._hits = 0; this._sel = 0; this._done = false; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var best = (st.best && st.best['10']) ? st.best['10'] : 0; var d = {}; d.status = 'Math - nod to answer - 4 questions'; for (var i = 0; i < 6; i++) d['r' + i] = ''; if (this._done) { d.big = 'Settled: ' + this._hits + ' / 4'; d.r0 = 'Game settled'; d.r1 = 'Hits: ' + this._hits + ' / 4'; d.r2 = 'Best: ' + best + ' / 4'; d.r3 = 'Back returns to the hub'; } else { var qq = QS[this._q]; d.big = qq.q; d.r0 = 'Question ' + (this._q + 1) + ' / 4'; var ci; for (ci = 0; ci < 3; ci++) { d['r' + (ci + 1)] = ((ci === this._sel ? '> ' : '- ') + qq.c[ci]); } d.r4 = 'Hits: ' + this._hits + ' - Best: ' + best + ' / 4'; d.r5 = 'Change choice, then nod to answer'; } d.detail = this._done ? 'Game settled - record saved' : 'Pick a choice, then nod to answer'; d.guide = 'Buttons change the choice - Nod answers - Back returns to the hub'; d.evt = 'EVT: question ' + (this._q + 1) + '/4 hits ' + this._hits; this.setData(d); },
  _settle() { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: 'Turkey Math settled', item: this._hits + ' / 4 hits', at: new Date().toISOString() }); if (!st.best) st.best = {}; if (!st.best['10'] || this._hits > st.best['10']) st.best['10'] = this._hits; this._save(st); this._speak('Game settled. ' + this._hits + ' hits out of 4.'); },
  actionTap() { if (this._done) { this._nav('/pages/index/index'); return; } var qq = QS[this._q]; if (this._sel === qq.a) { this._hits++; this._speak('Correct!'); } else { this._speak('Not quite. The answer was ' + qq.c[qq.a] + '.'); } this._q++; if (this._q >= QS.length) { this._settle(); } this._recompute(); },
  secondTap() { if (this._done) { this._nav('/pages/index/index'); return; } this._sel = (this._sel + 1) % 3; this._recompute(); },
  primaryTap() { this.actionTap(); },
  nextTap() { this.secondTap(); },
  prevTap() { this._sel = (this._sel + 2) % 3; this._recompute(); },
  speakTap() { if (this._done) this._speak('Game settled. ' + this._hits + ' hits out of 4.'); else this._speak(QS[this._q].q); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'us-thanksgiving-games', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">Turkey Math</div>
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
      <button class="btn main" bindtap="actionTap">Answer</button>
      <button class="btn" bindtap="secondTap">Change choice</button>
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
.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:16px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
