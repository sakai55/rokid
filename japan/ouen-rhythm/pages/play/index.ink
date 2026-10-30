<script def>
{
  "title": "向きゲーム"
}
</script>

<script setup>
import wx from 'wx';

// JP41 ouen-rhythm - play
const KEY = "ouenRhythmV1";
const DEF = {"selected": 0, "records": []};
const CHANTS = ["応援歌1「それいけ」", "応援歌2「がんばれ」", "チャンステーマ", "勝利のテーマ"];
const DIRS = ["左", "右"];
const STATUS = "頭の向きで応援の向きを決めます";
const GUIDE = "頭を左右に少しだけ振り、真ん中に戻してください。回し続ける動きはしません。センサーがないときはキーで向きを選べます。";

export default {
  data: { status: '', big: '', r0: '', r1: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = st.selected || 0; this._oi = 0; this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null; this._startSensor(); this._recompute(); },
  onShow() { var st = this._load(); this._idx = st.selected || 0; this._recompute(); },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var x = q[0], y = q[1], z = q[2], w = q[3]; self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)); self._zoneTick(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _angDiff(x, y) { var d = x - y; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() { if (this._yaw === null) { return; } if (this._yaw0 === null) { this._yaw0 = this._yaw; return; } var dy = this._angDiff(this._yaw, this._yaw0); var z = 'C'; if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R'; if (z !== 'C' && this._zone === 'C') { this._oi = (z === 'L') ? 0 : 1; this._recompute(); } this._zone = z; },
  _recompute() { var d = {}; d.status = STATUS; d.big = CHANTS[this._idx]; d.r0 = (this._oi === 0 ? '▶ ' : '· ') + '左へ応援'; d.r1 = (this._oi === 1 ? '▶ ' : '· ') + '右へ応援'; d.detail = '今の向き: ' + DIRS[this._oi]; d.guide = 'センサー: ' + (this._sensorOk ? '頭センサー使用中' : 'センサーなし（キーで選べます）') + '。' + GUIDE; d.evt = 'EVT: ' + CHANTS[this._idx] + ' ' + DIRS[this._oi]; this.setData(d); },
  primaryTap() { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '声援', chant: CHANTS[this._idx], dir: DIRS[this._oi], at: new Date().toISOString() }); st.selected = (this._idx + 1) % CHANTS.length; this._save(st); this._speak(CHANTS[this._idx] + '、' + DIRS[this._oi] + 'へ声援を送ります。'); this._idx = st.selected; this._oi = 0; this._yaw0 = this._yaw; this._recompute(); },
  nextTap() { this._oi = (this._oi + 1) % 2; this._recompute(); },
  prevTap() { this._oi = (this._oi + 1) % 2; this._recompute(); },
  speakTap() { this._speak(CHANTS[this._idx] + '。' + DIRS.join('、')); },
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
    <div class="band">向きゲーム</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">決める</button>
      <button class="btn" bindtap="nextTap">向きを変える</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
