<script def>
{
  "title": "宅配便受け取り"
}
</script>

<script setup>
import wx from 'wx';

// JP34 takkyubin-uketori - index
const KEY = "takkyubinUketoriV1";
const PARCELS = [{"name": "衣類", "status": "不在票あり"}, {"name": "食品", "status": "再配達待ち"}, {"name": "日用品", "status": "配達中"}, {"name": "書籍", "status": "保管中"}, {"name": "家電小物", "status": "不在票あり"}, {"name": "贈り物", "status": "受取済み"}];
const DEF = {"selected": 0, "slot": 0, "method": 0, "records": []};
const STATUS = "荷物を確認して、再配達へ進みます";
const GUIDE = "再配達手続きで時間帯と受取方法を選びます";
function DETAILFN(st) { return '不在票の荷物は' + PARCELS.filter(function (p) { return p.status === '不在票あり'; }).length + '件 ・ 記録は' + (st.records ? st.records.length : 0) + '件です。'; }
function SPEAKFN(i) { return '荷物です。' + PARCELS[i].name + '、' + PARCELS[i].status + 'です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < PARCELS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + PARCELS[i].name + ' ・ ' + PARCELS[i].status); } d.big = PARCELS[this._idx].name + ' ・ ' + PARCELS[this._idx].status; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + PARCELS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % PARCELS.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + PARCELS.length - 1) % PARCELS.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  sub0Tap() { this._saveSel(); this._nav('/pages/check/index'); },
  sub1Tap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.sub0Tap(); },
  speakTap() { this._speak(SPEAKFN(this._idx)); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'takkyubin-uketori', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">宅配便受け取り</div>
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
      <button class="btn main" bindtap="sub0Tap">再配達へ</button>
      <button class="btn" bindtap="sub1Tap">記録を見る</button>
      <button class="btn" bindtap="prevTap">前へ</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a3d24;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-left:6px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:2px solid #40ff5e;border-radius:4px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14532d;color:#7dff9e;font-weight:bold;border-style:double;border-width:3px;}
</style>
