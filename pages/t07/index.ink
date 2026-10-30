<script def>
{
  "title": "庭園散策"
}
</script>

<script setup>
import wx from 'wx';

// JP42 nihon-tabi-hub - t07
const KEY = "nihonTabiHubV1";
const TID = "t07";
const ITEMNAME = "散策ポイント";
const TARGET = 5;
const UNIT = "か所";
const CSTATUS = "庭園散策：数えて目標まで";
const NOWTXT = "いま： ";
const GOALTXT = " · 目標達成";
const CNT1 = "、いま ";
const CNT2 = "、目標は ";
const CNT3 = "です。";
const GUIDE = "下で数える · 上でリセット · うなずきは数えると同じ";
const REC_KIND = "庭園散策";

export default {
  data: { status: '', big: '', r0: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._count = (st.counts && typeof st.counts[TID] === 'number') ? st.counts[TID] : 0; this._recompute(); },
  _recompute() { var d = {}; d.status = CSTATUS; d.r0 = ITEMNAME + ' 目標 ' + TARGET + UNIT; d.big = this._count + ' / ' + TARGET + ' ' + UNIT; d.detail = NOWTXT + ITEMNAME + (this._count >= TARGET ? GOALTXT : ''); d.guide = GUIDE; d.evt = 'EVT: ' + ITEMNAME + ' ' + this._count + '/' + TARGET; this.setData(d); },
  _persist() { var st = this._load(); if (!st.counts) st.counts = {}; st.counts[TID] = this._count; if (!st.tools) st.tools = {}; st.tools[TID] = { done: this._count, total: TARGET }; this._save(st); },
  primaryTap() { if (this._count >= TARGET) { this._recompute(); return; } this._count++; this._persist(); if (this._count >= TARGET) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: ITEMNAME, count: this._count, at: new Date().toISOString() }); this._save(st); this._speak(ITEMNAME + GOALTXT); } this._recompute(); },
  resetTap() { this._count = 0; this._persist(); this._recompute(); },
  nextTap() { this.primaryTap(); },
  prevTap() { this.resetTap(); },
  speakTap() { this._speak(ITEMNAME + CNT1 + this._count + CNT2 + TARGET + CNT3); },
  backTap() { this._back(); },

  _fresh() { return {"selected": 0, "tools": {}, "marks": {}, "counts": {}, "quiz": {}, "spoken": {}, "records": []}; },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return this._fresh(); },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = this._fresh(); st.lastError = { code: code, slug: 'nihon-tabi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.resetTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.primaryTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};

</script>

<template>
  <div class="page">
    <div class="band">庭園散策</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">数える</button>
      <button class="btn" bindtap="resetTap">リセット</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:32px;font-weight:bold;margin-top:10px;text-align:center;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border:2px dashed rgba(64,255,94,0.8);}
.btn{flex:1;margin-right:8px;background-color:#122812;color:#7dff9e;border:2px solid rgba(64,255,94,0.6);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#2a6b2a;color:#7dff9e;font-weight:bold;}
</style>
