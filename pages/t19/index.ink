<script def>
{
  "title": "費用計算"
}
</script>

<script setup>
import wx from 'wx';

// JP37 hikkoshi-hub - 費用計算
const KEY = "hikkoshiHubV1";
const SLUGID = "t19";
const DEF = {"selected": 0, "tools": {}, "records": [], "calc": null, "compare": null};
const FIELDS = ["業者費", "その他費用"];
const STATUS = "費用計算：業者費とその他費用を5000円ずつ調整します";
const GUIDE = "増やす・減らすで5000円ずつ調整 ・ 項目切替で費用を変える ・ 確定で保存 ・ うなずきは確定";
export default {
  data: { status: '', big: '', r0: '', r1: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._field = 0; this._amounts = (st.calc && st.calc.amounts) ? st.calc.amounts.slice() : [80000, 10000]; this._recompute(); },
  onShow() { this._recompute(); },
  _total() { return this._amounts[0] + this._amounts[1]; },
  _recompute() { var d = {}; d.status = STATUS; d.r0 = ((this._field === 0 ? '▶ ' : '· ') + FIELDS[0] + ' ' + this._amounts[0] + '円'); d.r1 = ((this._field === 1 ? '▶ ' : '· ') + FIELDS[1] + ' ' + this._amounts[1] + '円'); d.big = '合計 ' + this._total() + '円'; d.detail = FIELDS[this._field] + 'を調整中です。'; d.guide = GUIDE; d.evt = 'EVT: 合計 ' + this._total() + '円'; this.setData(d); },
  upTap() { this._amounts[this._field] += 5000; this._recompute(); },
  downTap() { if (this._amounts[this._field] >= 5000) this._amounts[this._field] -= 5000; this._recompute(); },
  fieldTap() { this._field = (this._field + 1) % FIELDS.length; this._recompute(); },
  primaryTap() { var st = this._load(); if (!st.tools) st.tools = {}; st.tools[SLUGID] = { done: 1, total: 1 }; st.calc = { amounts: this._amounts.slice(), total: this._total() }; if (!st.records) st.records = []; st.records.push({ kind: "費用計算", done: 1, total: 1, at: new Date().toISOString() }); this._save(st); this._speak('合計' + this._total() + '円で保存しました。'); this._recompute(); },
  speakTap() { this._speak('合計' + this._total() + '円です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'hikkoshi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.upTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.downTap(); return; } if (key === 'Backspace' && this.backTap) { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};
</script>

<template>
  <div class="page">
    <div class="band">費用計算</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="upTap">増やす 5000円</button>
      <button class="btn" bindtap="downTap">減らす 5000円</button>
      <button class="btn" bindtap="fieldTap">項目切替</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">確定して保存</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.band{background-color:#0d3d17;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#1d6b33;color:#7dff9e;border:1px solid #40ff5e;border-radius:16px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
.big{font-size:26px;} .rrow{font-size:16px;background-color:#0a2a1a;padding:6px 10px;margin-top:4px;}
</style>
