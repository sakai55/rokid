<script def>
{
  "title": "多锅守候"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaKitchenWatchV1";
const POTS = [{"name": "汤锅 · 老火靓汤", "heat": "大火转小火", "mins": 30}, {"name": "炒锅 · 青椒肉丝", "heat": "大火快炒", "mins": 8}, {"name": "蒸锅 · 清蒸鲈鱼", "heat": "大火蒸", "mins": 12}, {"name": "砂锅 · 煲仔饭", "heat": "中小火", "mins": 25}, {"name": "奶锅 · 热牛奶", "heat": "小火", "mins": 5}, {"name": "电饭煲 · 白米饭", "heat": "自动档", "mins": 40}];
const DEF = {"selected": 0, "timers": [null, null, null], "records": []};
const GUIDE = "看向切换槽位（左/中/右），按键也可切换 · 点头登记或关火 · 计时是关火提醒必经步";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._slot = 1; this._sensorOk = false; this._startSensor(); this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._fail('E7001', 'sensor n/a'); return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._slot = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); self._recompute(); }); s.addEventListener('error', function () { self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._fail('E7001', 'sensor'); } },
  _remain(t) { if (!t) return null; var left = t.mins * 60000 - (Date.now() - t.startedAt); return Math.max(0, Math.ceil(left / 60000)); },
  _slotText(t, i) { if (!t) return '槽' + (i + 1) + ': 空'; var r = this._remain(t); return '槽' + (i + 1) + ': ' + t.name + ' · ' + (r <= 0 ? '到时了' : ('还剩 ' + r + '分钟')); },
  _recompute() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; var d = {}; d.status = '守候 · 当前槽' + (this._slot + 1) + (this._sensorOk ? ' · 头向已接' : ' · 头向未接，按键切换'); var i; for (i = 0; i < 3; i++) { d['r' + i] = ((i === this._slot ? '▶ ' : '· ') + this._slotText(timers[i], i)); } d.big = t ? ((this._remain(t) <= 0) ? (t.name + ' 到时了') : (t.name + ' · 还剩 ' + this._remain(t) + '分钟')) : ('待登记: ' + POTS[this._sel].name); d.detail = '选中锅: ' + POTS[this._sel].name + ' · ' + POTS[this._sel].heat + ' · ' + POTS[this._sel].mins + '分钟'; d.guide = GUIDE; d.evt = 'EVT: slot ' + (this._slot + 1); this.setData(d); },
  startTap() { var st = this._load(); if (!st.timers) st.timers = [null, null, null]; var t = st.timers[this._slot]; if (t && this._remain(t) > 0) { this._speak('这个槽已经在计时了。'); this._recompute(); return; } var p = POTS[this._sel]; st.timers[this._slot] = { name: p.name, heat: p.heat, mins: p.mins, startedAt: Date.now() }; this._save(st); this._speak(p.name + '开始计时，' + p.mins + '分钟。'); this._recompute(); },
  finishTap() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; if (!t) { this._speak('这个槽还没有登记计时。'); this._recompute(); return; } if (this._remain(t) > 0) { this._speak(t.name + '还剩 ' + this._remain(t) + '分钟，还没到时。'); this._recompute(); return; } if (!st.records) st.records = []; st.records.push({ kind: '关火记录', item: t.name, at: new Date().toISOString() }); timers[this._slot] = null; st.timers = timers; this._save(st); this._speak(t.name + '到时了，关火已记录。'); this._recompute(); },
  primaryTap() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; if (t && this._remain(t) <= 0) this.finishTap(); else this.startTap(); },
  nextTap() { this._slot = (this._slot + 1) % 3; this._recompute(); },
  prevTap() { this._slot = (this._slot + 2) % 3; this._recompute(); },
  speakTap() { var st = this._load(); var timers = st.timers || [null, null, null]; var t = timers[this._slot]; if (!t) this._speak('这个槽还没有登记。'); else if (this._remain(t) <= 0) this._speak(t.name + '到时了，请关火。'); else this._speak(t.name + '还剩 ' + this._remain(t) + '分钟。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'china-kitchen-watch', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">多锅守候</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="startTap">登记计时</button>
      <button class="btn" bindtap="finishTap">关火记录</button>
      <button class="btn" bindtap="nextTap">切换槽位</button>
      <button class="btn" bindtap="speakTap">报时</button>
      <button class="btn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border:2px solid #40ff5e;border-radius:18px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:18px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
