<script def>
{
  "title": "射的方向"
}
</script>

<script setup>
import wx from 'wx';

// JP32 matsuri-game-shuu - g04
const KEY = "matsuriGameShuuV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const ITEMS = [{"name": "的1", "opts": ["左", "右"]}, {"name": "的2", "opts": ["左", "右"]}, {"name": "的3", "opts": ["左", "右"]}];
const DSTATUS = "屋台の方向ゲーム";
const REC_KIND = "ゲーム記録";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._oi = 0; this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null; this._startSensor(); this._recompute(); },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var x = q[0], y = q[1], z = q[2], w = q[3]; self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)); self._zoneTick(); }); s.addEventListener('error', function () { self._sensorOk = false; }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _angDiff(x, y) { var d = x - y; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() { if (this._yaw === null) { return; } if (this._yaw0 === null) { this._yaw0 = this._yaw; return; } var dy = this._angDiff(this._yaw, this._yaw0); var z = 'C'; if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R'; if (z !== 'C' && this._zone === 'C') { this._oi = (z === 'L') ? 0 : 1; this._recompute(); } this._zone = z; },
  _recompute() { var it = ITEMS[this._idx]; var d = {}; d.status = DSTATUS; d.big = it.name; d.r0 = (this._oi === 0 ? '▶ ' : '· ') + it.opts[0]; d.r1 = (this._oi === 1 ? '▶ ' : '· ') + it.opts[1]; d.r2 = ''; d.detail = '頭を左右に振ると、選ぶ方向が動きます。'; d.guide = 'センサー: ' + (this._sensorOk ? '頭センサー使用中' : 'センサーなし（キーで選べます）'); d.evt = 'EVT: ' + it.name; this.setData(d); },
  primaryTap() { var it = ITEMS[this._idx]; this._speak(it.name + '、' + it.opts[this._oi] + 'です。'); var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: it.name, pick: it.opts[this._oi], at: new Date().toISOString() }); this._save(st); this._idx = (this._idx + 1) % ITEMS.length; this._oi = 0; this._yaw0 = this._yaw; this._recompute(); },
  nextTap() { this._oi = (this._oi + 1) % 2; this._recompute(); },
  prevTap() { this._oi = (this._oi + 1) % 2; this._recompute(); },
  speakTap() { var it = ITEMS[this._idx]; this._speak(it.name + '。' + it.opts.join('、')); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'matsuri-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">射的方向</div>
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
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">決める</button>
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
.hubrows .rrow{font-size:11px;line-height:15px;}

.band{background-color:#1a3d1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border:2px dashed rgba(64,255,94,0.8);}
.btn{flex:1;margin-right:8px;background-color:#122812;color:#7dff9e;border:2px solid rgba(64,255,94,0.6);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#2a6b2a;color:#7dff9e;font-weight:bold;}
</style>
