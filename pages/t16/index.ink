<script def>
{
  "title": "緊急電話"
}
</script>

<script setup>
import wx from 'wx';

// JP42 nihon-tabi-hub - t16
const KEY = "nihonTabiHubV1";
const TID = "t16";
const PHRASES = ["助けてください", "救急車を呼んでください", "警察を呼んでください", "ここはどこですか"];
const PSTATUS = "緊急電話：選んで声で伝える";
const PDETAIL = "選んだ言葉を音声で伝えます。";
const GUIDE = "上下で言葉を変える · 決定で声に出す · うなずきは決定と同じ";
const REC_KIND = "緊急電話";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var spoken = (st.spoken && st.spoken[TID]) || []; var d = {}; d.status = PSTATUS; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + PHRASES[i]); } d.big = PHRASES[this._idx]; d.detail = PDETAIL + ' 伝えた言葉は ' + spoken.length + ' / ' + PHRASES.length + ' です。'; d.guide = GUIDE; d.evt = 'EVT: ' + PHRASES[this._idx]; this.setData(d); },
  primaryTap() { var ph = PHRASES[this._idx]; var st = this._load(); if (!st.spoken) st.spoken = {}; var arr = st.spoken[TID] || []; if (arr.indexOf(ph) < 0) arr.push(ph); st.spoken[TID] = arr; if (!st.tools) st.tools = {}; st.tools[TID] = { done: arr.length, total: PHRASES.length }; if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: ph, at: new Date().toISOString() }); this._save(st); this._speak(ph); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % 4; this._recompute(); },
  prevTap() { this._idx = (this._idx + 3) % 4; this._recompute(); },
  speakTap() { this._speak(PHRASES[this._idx]); },
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
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};

</script>

<template>
  <div class="page">
    <div class="band">緊急電話</div>
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
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">声で伝える</button>
      <button class="btn" bindtap="nextTap">次へ</button>
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
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
