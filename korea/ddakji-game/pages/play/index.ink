<script def>
{
  "title": "딱지치기 놀이"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "ddakjiGameV1";
const PARTS = ["첫 번째 딱지", "두 번째 딱지", "세 번째 딱지", "네 번째 딱지", "다섯 번째 딱지", "여섯 번째 딱지"];
const TARGETS = [0, 1, 2, 1, 0, 2];
const ZONES = ["왼쪽", "가운데", "오른쪽"];
const DEF = {"selected": 0, "records": []};
const STATUS = "머리 방향으로 칠 방향을 정하고 고개를 끄덕여 친다";
const GUIDE = "머리를 왼쪽 · 가운데 · 오른쪽으로 돌려 방향을 정하기 · 고개 끄덕임으로 치기 · 6번 치면 정산";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._round = 0; this._hits = 0; this._zone = 1; this._done = false; this._startSensor(); this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._zone = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _recompute() { var d = {}; d.status = STATUS; var n = PARTS.length; var i; for (i = 0; i < n; i++) { d['r' + i] = ((i === this._round && !this._done) ? '▶ ' : '· ') + PARTS[i] + ((i < this._round) ? ' 쳤음' : ''); } if (this._done) { d.big = '끝!'; d.detail = '딱지 6번을 다 쳤습니다. 기록에 남겼습니다.'; } else { d.big = PARTS[this._round]; d.detail = '지금 칠 딱지: ' + PARTS[this._round] + ' · 노릴 방향: ' + ZONES[TARGETS[this._round]] + ' · 머리 방향: ' + ZONES[this._zone] + ' 입니다'; } d.guide = GUIDE; d.evt = 'EVT: ' + this._round + '/' + n + ' hits ' + this._hits; this.setData(d); },
  primaryTap() { if (this._done) { this._nav('/pages/record/index'); return; } var target = TARGETS[this._round]; if (this._zone === target) { this._hits++; this._speak('맞혔습니다.'); } else { this._speak('빗나갔습니다. 다음 딱지입니다.'); } this._round++; if (this._round >= PARTS.length) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '딱지치기 결과', item: '6번 치기 완료', at: new Date().toISOString() }); this._save(st); this._speak('딱지치기가 끝났습니다.'); } this._recompute(); },
  nextTap() { this._zone = (this._zone + 1) % 3; this._recompute(); },
  prevTap() { this._zone = (this._zone + 2) % 3; this._recompute(); },
  speakTap() { this._speak(PARTS[this._round] + '입니다.'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'ddakji-game', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">딱지치기 놀이</div>
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
      <button class="btn" bindtap="backTap">돌아가기</button>
      <button class="btn main" bindtap="primaryTap">치기</button>
      <button class="btn" bindtap="nextTap">방향 바꾸기</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:22px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a3d1e;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border:2px solid #40ff5e;border-radius:50px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:50px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
