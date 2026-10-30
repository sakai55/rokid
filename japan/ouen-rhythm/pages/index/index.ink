<script def>
{
  "title": "応援リズム"
}
</script>

<script setup>
import wx from 'wx';

// JP41 ouen-rhythm - index
const KEY = "ouenRhythmV1";
const DEF = {"selected": 0, "records": []};
const CHANTS = [{ "name": "応援歌1「それいけ」", "note": "試合の始まりに歌う" }, { "name": "応援歌2「がんばれ」", "note": "選手を励ますときに歌う" }, { "name": "チャンステーマ", "note": "好機に盛り上げる" }, { "name": "勝利のテーマ", "note": "勝ったときに歌う" }];
const STATUS = "球場で家族と応援します";
const GUIDE = "応援歌を選んで、向きゲームで頭の向きを決めます。";
function DETAILFN(st) { return '応援歌は4曲、声援の記録は' + ((st.records || []).length) + '件です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = st.selected || 0; this._recompute(); },
  onShow() { var st = this._load(); this._idx = st.selected || 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < CHANTS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + CHANTS[i].name + ' ・ ' + CHANTS[i].note); } d.big = CHANTS[this._idx].name; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + CHANTS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % CHANTS.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + CHANTS.length - 1) % CHANTS.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  playTap() { this._saveSel(); this._nav('/pages/play/index'); },
  recordTap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.playTap(); },
  speakTap() { this._speak(CHANTS[this._idx].name + 'です。' + CHANTS[this._idx].note); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'ouen-rhythm', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">応援リズム</div>
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
      <button class="btn main" bindtap="playTap">向きゲーム</button>
      <button class="btn" bindtap="recordTap">記録を見る</button>
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
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#14541f;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 0;text-align:center;border-radius:24px;}
.btn{flex:1;margin-right:6px;background-color:#122812;color:#7dff9e;border:1px solid #40ff5e;border-right:4px solid #40ff5e;border-radius:0;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#2a6b2a;color:#7dff9e;font-weight:bold;}
</style>
