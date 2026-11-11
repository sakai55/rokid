<script def>
{
  "title": "熊猫基地拍照核对"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaPandaPhotoV1";
const SLUG = "china-panda-photo";
const SPOTS = ["太阳产房", "月亮产房", "大熊猫1号别墅", "大熊猫2号别墅", "熊猫幼儿园", "成年大熊猫别墅"];
const ITEMS = ["太阳产房 - 产房外活动场", "太阳产房 - 产房内参观窗", "月亮产房 - 产房外活动场", "月亮产房 - 产房内参观窗", "大熊猫1号别墅 - 别墅外竹林", "大熊猫1号别墅 - 别墅内活动场", "大熊猫2号别墅 - 别墅外竹林", "大熊猫2号别墅 - 别墅内活动场", "熊猫幼儿园 - 幼儿园外草坪", "熊猫幼儿园 - 幼儿园内活动室", "成年大熊猫别墅 - 别墅外活动场", "成年大熊猫别墅 - 别墅内参观窗"];
const DEF = {"selected": 0, "checks": {}, "photo": null, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var checks = st.checks || {}; var done = 0; var i; for (i = 0; i < ITEMS.length; i++) if (checks[String(i)]) done++; var d = {}; d.status = "看向一处馆区，点头拍照核对"; for (i = 0; i < SPOTS.length; i++) { var c0 = checks[String(i * 2)] ? '[x]' : '[ ]'; var c1 = checks[String(i * 2 + 1)] ? '[x]' : '[ ]'; d['r' + i] = ((i === this._idx ? '> ' : '- ') + SPOTS[i] + ' ' + c0 + ' ' + c1); } d.big = SPOTS[this._idx] + ' - ' + done + '/12 已打勾'; d.detail = "6 处馆区 - 12 个拍照点 - " + done + '/12 已打勾'; d.guide = "拍照只作本人核对，12 处全打勾才算走完"; d.evt = 'EVT: ' + SPOTS[this._idx]; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % SPOTS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + SPOTS.length - 1) % SPOTS.length; this._recompute(); },
  primaryTap() { this.openTap(); },
  openTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav('/pages/photo/index'); },
  recordTap() { this._nav('/pages/record/index'); },
  speakTap() { this._speak(SPOTS[this._idx]); },
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
    <div class="band">熊猫基地拍照核对</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="openTap">打开拍照</button><button class="btn" bindtap="nextTap">下一个</button><button class="btn" bindtap="recordTap">看记录</button><button class="btn" bindtap="speakTap">播报</button>
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

.band{background-color:#12351f;color:#7dff9e;font-size:18px;font-weight:bold;padding:8px 10px;border:2px dashed #40ff5e;border-radius:8px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#12351f;color:#7dff9e;border:1px dashed #40ff5e;border-radius:8px;font-size:13px;padding:7px 0;text-align:center;}
</style>
