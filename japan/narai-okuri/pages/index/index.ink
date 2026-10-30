<script def>
{
  "title": "習い事お迎え"
}
</script>

<script setup>
import wx from 'wx';

// JP39 narai-okuri - index
const KEY = "naraiOkuriV1";
const LESSONS = ["ピアノ ・ 16時30分 ・ 市民センター", "水泳 ・ 17時 ・ 市営プール", "英語 ・ 16時 ・ 英語教室", "サッカー ・ 17時30分 ・ 河川敷グラウンド", "書道 ・ 15時30分 ・ 公民館", "そろばん ・ 16時 ・ そろばん塾"];
const DEF = {"selected": 0, "checks": {}, "records": []};
const STATUS = "今日のお迎えと持ち物を確認します";
const GUIDE = "次へで習い事を変える ・ お迎えチェックで確認 ・ うなずきは主確認";
function DETAILFN(st) { return '習い事は6つ、記録は' + (st.records ? st.records.length : 0) + '件です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < LESSONS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + LESSONS[i]); } d.big = LESSONS[this._idx]; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + LESSONS[this._idx]; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % LESSONS.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + LESSONS.length - 1) % LESSONS.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  sub0Tap() { this._saveSel(); this._nav('/pages/check/index'); },
  sub1Tap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.sub0Tap(); },
  speakTap() { this._speak(LESSONS[this._idx] + 'です。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'narai-okuri', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">習い事お迎え</div>
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
      <button class="btn main" bindtap="sub0Tap">お迎えチェック</button>
      <button class="btn" bindtap="sub1Tap">記録</button>
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
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:13px;line-height:20px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;border-top:1px dashed #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:2px dashed #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;border-style:solid;}
</style>
