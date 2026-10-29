<script def>
{
  "title": "健康診断準備"
}
</script>

<script setup>
import wx from 'wx';

// JP35 kenkou-shindan - index
const KEY = "kenkouShindanV1";
const FLOW = ["受付で受診券を出す", "問診票を提出する", "身長と体重をはかる", "血圧をはかる", "血液検査をうける", "医師の診察をうける"];
const EXAMS = ["身長と体重", "血圧", "血液検査", "尿検査", "胸部エックス線", "心電図", "視力", "聴力"];
const BELONGINGS = ["健康保険証", "受診券", "問診票", "眼鏡", "お薬手帳"];
const DEF = {"selected": 0, "checked": [], "records": [], "memo": ""};
const STATUS = "健診の流れと検査項目を確認します";
const GUIDE = "検査項目ボタンで切替 ・ 次へで項目を変える ・ うなずきは主確認";
function DETAILFN(st) { return '流れは6つ、検査項目は8つ、持ち物は5つです。記録は' + (st.records ? st.records.length : 0) + '件です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._mode = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _list() { return (this._mode === 0) ? FLOW : EXAMS; },
  _recompute() { var st = this._load(); var list = this._list(); var d = {}; d.status = (this._mode === 0) ? '当日の流れ 6つ' : '検査項目 8つ'; var i; for (i = 0; i < 8; i++) { d['r' + i] = (i < list.length) ? ((i === this._idx ? '▶ ' : '· ') + list[i]) : ''; } d.big = list[this._idx]; d.detail = DETAILFN(st) + ' 持ち物は' + BELONGINGS.join('、') + 'です。'; d.guide = GUIDE; d.evt = 'EVT: ' + list[this._idx]; this.setData(d); },
  nextTap() { var list = this._list(); this._idx = (this._idx + 1) % list.length; this._recompute(); },
  prevTap() { var list = this._list(); this._idx = (this._idx + list.length - 1) % list.length; this._recompute(); },
  modeTap() { this._mode = (this._mode === 0) ? 1 : 0; this._idx = 0; this._recompute(); },
  sub0Tap() { this._nav('/pages/check/index'); },
  sub1Tap() { this._nav('/pages/record/index'); },
  primaryTap() { this.sub0Tap(); },
  speakTap() { this._speak(this._list()[this._idx] + 'です。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'kenkou-shindan', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">健康診断準備</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    <div class="rrow">{{ r6 }}</div>
    <div class="rrow">{{ r7 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="sub0Tap">前日準備チェック</button>
      <button class="btn" bindtap="sub1Tap">受診記録</button>
      <button class="btn" bindtap="modeTap">検査項目</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
      <button class="btn" bindtap="backTap">もどる</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:22px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:13px;line-height:19px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a3d1e;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:4px solid #7dff9e;border-radius:20px 20px 0 0;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:2px solid #40ff5e;border-radius:20px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;border-bottom:4px solid #7dff9e;}
</style>
