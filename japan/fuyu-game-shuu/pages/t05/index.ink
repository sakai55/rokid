<script def>
{
  "title": "凧方向当て"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "fuyuGameShuuV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const KIND = "凧方向当て";
const ZONES = ["左", "中央", "右"];
const TARGETS = [1, 0, 2, 2, 0, 1];
const STATUS = "凧方向当て";
const GUIDE = "中央に戻してから方向を変える ・ 首を回し続けない ・ センサーがなくてもボタンで遊べる";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); if (Math.abs(yaw) < 0.15) { self._armed = true; self._zone = 1; } else if (self._armed && yaw < -0.35) { self._zone = 0; self._armed = false; } else if (self._armed && yaw > 0.35) { self._zone = 2; self._armed = false; } self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._round = 0; this._hits = 0; this._miss = 0; this._zone = 1; this._armed = true; this._done = false; this._startSensor(); this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; d.r0 = this._done ? '集計が終わりました' : ('現在 第' + (this._round + 1) + '回 / 全6回'); d.r1 = '狙う方向: ' + ZONES[TARGETS[Math.min(this._round, 5)]]; d.r2 = '頭の向き: ' + ZONES[this._zone]; d.r3 = '当たり: ' + this._hits; d.r4 = 'はずれ: ' + this._miss; d.r5 = '中央に戻してから方向を変える'; d.big = this._done ? ('結果 ' + this._hits + '回正解') : ('第' + (this._round + 1) + '回'); d.detail = this._done ? KIND + 'を終えました。記録に残しました。' : '狙う方向と頭の向きが合うと当たります'; d.guide = GUIDE; d.evt = 'EVT: ' + this._round + '/6 hits ' + this._hits; this.setData(d); },
  actTap() { if (this._done) { this._nav('/pages/index/index'); return; } var target = TARGETS[this._round]; if (this._zone === target) { this._hits++; this._speak('当たりました。'); } else { this._miss++; this._speak('はずれました。次です。'); } this._round++; if (this._round >= 6) { this._done = true; this._finish(KIND, this._hits + '回正解', this._hits, this._hits + '回正解'); this._speak(KIND + 'が終わりました。当たりは' + this._hits + '回でした。'); } this._recompute(); },
  primaryTap() { this.actTap(); },
  nextTap() { this._zone = (this._zone + 1) % 3; this._recompute(); },
  prevTap() { this._zone = (this._zone + 2) % 3; this._recompute(); },
  speakTap() { this._speak('狙う方向は' + ZONES[TARGETS[Math.min(this._round, 5)]] + 'です。'); },
  backTap() { this._back(); },

  _saveBest(score, text) { var st = this._load(); if (!st.best) st.best = {}; var old = st.best[String(this._sel)]; var oldN = (old === undefined || old === null) ? -1 : parseInt(old, 10); if (isNaN(oldN)) oldN = -1; if (score > oldN) { st.best[String(this._sel)] = text; this._save(st); } },
  _finish(kind, item, score, text) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: kind, item: item, at: new Date().toISOString() }); this._save(st); this._saveBest(score, text); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'fuyu-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">凧方向当て</div>
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
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="actTap">凧を上げる</button>
      <button class="btn" bindtap="nextTap">方向を変える</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
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
.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:9px 12px;border:2px solid #40ff5e;border-radius:24px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:24px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
