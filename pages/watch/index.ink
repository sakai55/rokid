<script def>
{
  "title": "인사동 차 지킴이"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "insadongTeaWatchV1";
const SLUG = "insadong-tea-watch";
const ITEMS = [["보리차", 180], ["녹차", 120], ["유자차", 240], ["오미자차", 300], ["국화차", 150], ["생강차", 210]];
const DEF = {"timers": {}, "records": [], "total": 0};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; var _sel = this._load(); if (typeof _sel.selected === 'number') this._idx = _sel.selected; this._armed = true; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._onYaw(yaw); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _onYaw(yaw) { if (Math.abs(yaw) < 0.15) { this._armed = true; } else if (this._armed && yaw < -0.35) { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._armed = false; } else if (this._armed && yaw > 0.35) { this._idx = (this._idx + 1) % ITEMS.length; this._armed = false; } this._recompute(); },

  _timerState(i) { var st = this._load(); var t = (st.timers || {})[String(i)]; if (!t) return "아직 안 잼"; var el = Math.floor((Date.now() - t.startAt) / 1000); if (el >= t.secs) return "다 됐다"; return "남은 시간 " + (t.secs - el) + "초"; },
  _recompute() { var st = this._load(); var timers = st.timers || {}; var now = Date.now(); var k; for (k in timers) { var t = timers[k]; if (!t.reminded && now - t.startAt >= t.secs * 1000) { t.reminded = true; this._speak(ITEMS[Number(k)][0] + "차를 따라야 할 시간이다."); } } this._save(st); var d = {}; d.status = "차를 바라보고 끄덕임으로 시간을 재면 때가 되면 알려준다"; var i; for (i = 0; i < 6; i++) { d['r' + i] = ((i === this._idx ? '> ' : '- ') + ITEMS[i][0] + ' - ' + this._timerState(i)); } d.big = ITEMS[this._idx][0] + ' - ' + this._timerState(this._idx); d.detail = "우리는 시간은 각 차마다 다르다"; d.guide = "왼쪽으로 돌리면 앞차, 오른쪽으로 돌리면 다음 차, 가운데로 돌아와야 다시 바뀐다 · 시간이 되기 전에 누르면 남은 시간만 알려준다"; d.evt = 'EVT: watch ' + this._idx; this.setData(d); },
  primaryTap() { var st = this._load(); if (!st.timers) st.timers = {}; var t = st.timers[String(this._idx)]; if (!t) { st.timers[String(this._idx)] = { item: ITEMS[this._idx][0], secs: ITEMS[this._idx][1], startAt: Date.now(), reminded: false }; this._save(st); this._speak(ITEMS[this._idx][0] + "시간을 재기 시작한다, " + ITEMS[this._idx][1] + "초."); } else if (Date.now() - t.startAt >= t.secs * 1000) { if (!st.records) st.records = []; st.records.push({ kind: "차 우리기", item: ITEMS[this._idx][0], at: new Date().toISOString() }); delete st.timers[String(this._idx)]; this._save(st); this._speak(ITEMS[this._idx][0] + "차를 따랐다. 기록했다."); } else { var left = t.secs - Math.floor((Date.now() - t.startAt) / 1000); this._speak(ITEMS[this._idx][0] + "아직 " + left + "초 남았으니 기록하지 않는다."); } this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % ITEMS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._recompute(); },
  speakTap() { this._speak(ITEMS[this._idx][0] + ' ' + this._timerState(this._idx)); },
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
    <div class="band">인사동 차 지킴이</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">시간 재기</button><button class="btn" bindtap="nextTap">다음 차</button><button class="btn" bindtap="backTap">돌아가기</button><button class="btn" bindtap="speakTap">읽어주기</button>
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

.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:16px;font-size:13px;padding:7px 0;text-align:center;}
</style>
