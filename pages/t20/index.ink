<script def>
{
  "title": "引越し記録"
}
</script>

<script setup>
import wx from 'wx';

// JP37 hikkoshi-hub - 引越し記録
const KEY = "hikkoshiHubV1";
const SLUGID = "t20";
const DEF = {"selected": 0, "tools": {}, "records": [], "calc": null, "compare": null};
const STATUS = "引越し記録：手帳の記録と合計を確認します";
const GUIDE = "集計を保存で記録を追加 ・ 音声案内で合計を読み上げ ・ うなずきは集計を保存";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._off = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var tools = st.tools || {}; var doneTools = 0; var k; for (k in tools) { if (tools[k] && tools[k].done >= tools[k].total) doneTools++; } var recs = st.records || []; var i; for (i = 0; i < 5; i++) { var r = recs[recs.length - 1 - i - (this._off || 0)]; d['r' + i] = r ? (r.kind + ' ' + r.done + '/' + r.total) : '記録がありません。'; } d.big = '完了した道具 ' + doneTools + '/20'; d.detail = '記録は' + recs.length + '件です。' + (st.calc ? ' 費用合計は' + st.calc.total + '円です。' : ' 費用計算はまだ保存されていません。'); d.guide = GUIDE; d.evt = 'EVT: 記録 ' + recs.length + '件'; this.setData(d); },
  primaryTap() { var st = this._load(); var tools = st.tools || {}; var doneTools = 0; var k; for (k in tools) { if (tools[k] && tools[k].done >= tools[k].total) doneTools++; } if (!st.tools) st.tools = {}; st.tools[SLUGID] = { done: 1, total: 1 }; if (!st.records) st.records = []; st.records.push({ kind: "引越し記録・集計", done: doneTools, total: 20, at: new Date().toISOString() }); this._save(st); this._speak('集計を保存しました。'); this._recompute(); },
  nextTap() { var st = this._load(); var recs = st.records || []; if ((this._off || 0) + 5 < recs.length) this._off = (this._off || 0) + 1; this._recompute(); },
  prevTap() { if ((this._off || 0) > 0) this._off = (this._off || 0) - 1; this._recompute(); },
  speakTap() { var st = this._load(); var recs = st.records || []; this._speak('記録は' + recs.length + '件です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'hikkoshi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace' && this.backTap) { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};
</script>

<template>
  <div class="page">
    <div class="band">引越し記録</div>
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
      <button class="btn" bindtap="prevTap">前の記録</button>
      <button class="btn" bindtap="nextTap">次の記録</button>
      <button class="btn main" bindtap="primaryTap">集計を保存</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
      <button class="btn" bindtap="backTap">もどる</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:22px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:10px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
.rrow{border-bottom:1px solid rgba(64,255,94,0.4);}
</style>
