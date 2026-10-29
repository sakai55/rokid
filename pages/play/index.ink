<script def>
{
  "title": "투호 던지기"
}
</script>

<script setup>
import wx from 'wx';

// KR21 tuho-game - play: aim with Up/Down, nod or Enter to throw.
// Head yaw from AbsoluteOrientationSensor only nudges the on-screen
// aim hint; selection always works with the buttons too. Aim resets to
// the center after every throw. Scoring is a demo score, not physical
// arrow recognition: a throw scores when the chosen aim matches the
// hidden target zone for that throw.
const KEY = "tuhoGameV1";
const DEF = {"best": 0, "games": []};
const AIMS = ["왼쪽", "가운데", "오른쪽"];
const AIMKEYS = ["L", "C", "R"];
const DISTS = [{"label": "1m", "score": 10}, {"label": "2m", "score": 30}, {"label": "3m", "score": 50}];
const TARGETS = ["C", "L", "R", "C", "R", "L", "R", "C", "L", "C"];
const STATUS = "위아래로 겨냥하고 고개를 끄덕여 던집니다";
const GUIDE = "던지기 판정은 화면 속 시범 점수이고 실제 화살을 인식하지 않습니다";

export default {
  data: { status: '', big: '', aim: '', dist: '', score: '', throws: '', result: '', sensor: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._aim = 1; this._dist = 0; this._n = 0; this._score = 0; this._done = false; this._result = '아직 던지지 않았습니다'; this._yaw = null; this._yaw0 = null; this._zone = 'C'; this._sensorOk = false; this._sensor = null; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  onHide() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  onUnload() { if (this._sensor) { try { this._sensor.stop(); } catch (e) {} this._sensor = null; } },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var x = q[0], y = q[1], z = q[2], w = q[3]; self._yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z)); if (self._yaw0 === null) self._yaw0 = self._yaw; self._zoneTick(); }); s.addEventListener('error', function () {}); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; } },
  _angDiff(a, b) { var d = a - b; while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; },
  _zoneTick() { if (this._yaw === null || this._yaw0 === null) return; var dy = this._angDiff(this._yaw, this._yaw0); var z = 'C'; if (dy <= -0.35) z = 'L'; else if (dy >= 0.35) z = 'R'; if (z !== this._zone) { this._zone = z; this._recompute(); } },
  _zoneText() { if (!this._sensorOk) return '감지기 없음 · 버튼으로 겨냥합니다'; return '머리 방향 힌트: ' + (this._zone === 'L' ? '왼쪽' : (this._zone === 'R' ? '오른쪽' : '정면')); },
  _recompute() { var d = {}; d.status = STATUS; d.big = '현재 점수 ' + this._score + '점'; d.aim = '겨냥: ' + AIMS[this._aim] + (this._aim === 1 ? ' · 정면으로 맞췄습니다' : ''); d.dist = '거리: ' + DISTS[this._dist].label + ' · 맞히면 ' + DISTS[this._dist].score + '점'; d.score = '던진 횟수: ' + this._n + ' / 10'; d.throws = this._done ? '게임 종료' : ('다음 던지기: ' + (this._n + 1) + '번째'); d.result = this._result; d.sensor = this._zoneText(); d.guide = GUIDE; d.evt = 'EVT: throw ' + this._n + ' score ' + this._score; this.setData(d); },
  nextTap() { this._aim = (this._aim + 1) % 3; this._recompute(); },
  prevTap() { this._aim = (this._aim + 2) % 3; this._recompute(); },
  distTap() { this._dist = (this._dist + 1) % 3; this._recompute(); },
  throwTap() { if (this._done) { this._aim = 1; this._dist = 0; this._n = 0; this._score = 0; this._done = false; this._result = '새 게임을 시작합니다'; this._recompute(); return; } var target = TARGETS[this._n]; var hit = (AIMKEYS[this._aim] === target); var gained = hit ? DISTS[this._dist].score : 0; this._score += gained; var targetText = (target === 'L' ? '왼쪽' : (target === 'R' ? '오른쪽' : '가운데')); this._result = (this._n + 1) + '번째: ' + (hit ? ('맞았습니다! +' + gained + '점') : ('빗나갔습니다 · 목표는 ' + targetText + '였습니다')); this._n += 1; this._aim = 1; if (this._n >= 10) { this._done = true; var st = this._load(); if (!st.games) st.games = []; st.games.push({ score: this._score, at: new Date().toISOString() }); if (this._score > (st.best || 0)) st.best = this._score; this._save(st); this._result += ' · 게임 종료! 최종 ' + this._score + '점'; this._speak('게임 종료! 최종 점수는 ' + this._score + '점입니다'); } else { this._speak(this._result); } this._recompute(); },
  primaryTap() { this.throwTap(); },
  speakTap() { this._speak('겨냥은 ' + AIMS[this._aim] + ', 거리는 ' + DISTS[this._dist].label + ', 현재 점수는 ' + this._score + '점입니다'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._fail('E5002', 'storage read'); } return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'tuho-game', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">투호 던지기</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ aim }}</div>
    <div class="rrow">{{ dist }}</div>
    <div class="rrow">{{ score }}</div>
    <div class="rrow">{{ throws }}</div>
    </div>
    <div class="detail">{{ result }}</div>
    <div class="detail">{{ sensor }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="throwTap">던지기</button>
      <button class="btn" bindtap="distTap">거리 바꾸기</button>
      <button class="btn" bindtap="nextTap">겨냥 바꾸기</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
      <button class="btn" bindtap="backTap">돌아가기</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:26px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:8px;}
.rrow{color:#7dff9e;font-size:15px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:5px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3b22;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0d3b22;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:14px;padding:10px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
