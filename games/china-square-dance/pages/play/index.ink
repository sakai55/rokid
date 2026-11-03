<script def>
{
  "title": "广场舞步"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaSquareDanceV1";
const SLUG = "china-square-dance";
const STEPS = ["十字步", "三步踩", "转圈步", "摆手步", "踢腿步", "小跑步", "扭腰步", "拍手步"];
const SEQ = [0, 3, 1, 6, 2, 7, 4, 5, 1, 3];
const ZONES = ["左", "中", "右"];
const DEF = {"best": null, "records": []};
const STATUS = "看目标舞步，转头选步，点头踩拍";
const GUIDE = "左区切上一步，右区切下一步，中区为回正待命 · 回中后才能再切步 · 转头一次只动一步";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._round = 0; this._hits = 0; this._miss = 0; this._zone = 1; this._sel = 0; this._armed = true; this._done = false; this._startSensor(); this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._onYaw(yaw); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _onYaw(yaw) { if (Math.abs(yaw) < 0.15) { this._armed = true; this._zone = 1; } else if (this._armed && yaw < -0.35) { this._zone = 0; this._sel = (this._sel + 7) % 8; this._armed = false; } else if (this._armed && yaw > 0.35) { this._zone = 2; this._sel = (this._sel + 1) % 8; this._armed = false; } this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; d.r0 = this._done ? '10 轮已打完' : ('第 ' + (this._round + 1) + ' 轮 / 共 10 轮'); d.r1 = '目标舞步：' + STEPS[SEQ[Math.min(this._round, 9)]]; d.r2 = '你选的舞步：' + STEPS[this._sel]; d.r3 = '头向区域：' + ZONES[this._zone] + '（左上一步／右下一步／中回正）'; d.r4 = '命中：' + this._hits + ' · 踩空：' + this._miss; d.r5 = '回中后才能再切步'; d.big = this._done ? ('结算 ' + this._hits + '/10') : STEPS[this._sel]; d.detail = this._done ? '10 轮打完，已写入记录。' : '选对目标舞步再点头踩拍'; d.guide = GUIDE; d.evt = 'EVT: ' + this._round + '/10 hits ' + this._hits; this.setData(d); },
  primaryTap() { if (this._done) { this._nav('/pages/record/index'); return; } var target = SEQ[this._round]; if (this._sel === target) { this._hits++; this._speak('踩中了。'); } else { this._miss++; this._speak('踩空了，下一轮。'); } this._round++; if (this._round >= 10) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '广场舞步 10 轮', item: '命中 ' + this._hits + '/10', at: new Date().toISOString() }); if (st.best === null || st.best === undefined || this._hits > st.best) st.best = this._hits; this._save(st); this._speak('10 轮打完，命中' + this._hits + '轮。'); } this._recompute(); },
  nextTap() { this._sel = (this._sel + 1) % 8; this._recompute(); },
  prevTap() { this._sel = (this._sel + 7) % 8; this._recompute(); },
  speakTap() { this._speak('目标舞步是' + STEPS[SEQ[Math.min(this._round, 9)]] + '。'); },
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
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};
</script>

<template>
  <div class="page">
    <div class="band">广场舞步</div>
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
      <button class="btn" bindtap="backTap">返回</button>
      <button class="btn main" bindtap="primaryTap">踩拍</button>
      <button class="btn" bindtap="nextTap">换舞步</button>
      <button class="btn" bindtap="speakTap">语音播报</button>
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
.rrow12{color:#7dff9e;font-size:11px;line-height:13px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-top:2px solid #40ff5e;border-bottom:6px solid #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:6px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

</style>
