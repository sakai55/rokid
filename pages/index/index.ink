<script def>
{
  "title": "광장시장 장보기"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "gwangjangMarketV1";
const SLUG = "gwangjang-market";
const STALLS = ["빈대떡", "마약김밥", "육회", "순대", "어묵", "떡볶이"];
const CONFIRMS = ["샀다", "가격을 확인했다", "포장했다", "가방에 넣었다"];
const DEF = {"selected": 0, "checks": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var _s = this._load(); this._idx = (typeof _s.selected === 'number') ? _s.selected : 0; this._armed = true; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._onYaw(yaw); }); s.addEventListener('error', function () { self._sensorOk = false; self._recompute(); self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _onYaw(yaw) { if (Math.abs(yaw) < 0.15) { this._armed = true; } else if (this._armed && yaw < -0.35) { this._idx = (this._idx + STALLS.length - 1) % STALLS.length; this._armed = false; } else if (this._armed && yaw > 0.35) { this._idx = (this._idx + 1) % STALLS.length; this._armed = false; } this._recompute(); },

  _recompute() { var st = this._load(); var checks = st.checks || {}; var done = 0; var i; for (i = 0; i < 6; i++) { if (checks[String(i)] === 4) done++; } var d = {}; d.status = "두 손에 봉지를 들고, 고개를 돌려 가게를 고르세요" + (this._sensorOk ? " · 센서 연결됨" : " · 센서 없음, 버튼으로 고르세요"); for (i = 0; i < 6; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + STALLS[i] + ' ' + (checks[String(i)] || 0) + '/4'); } d.big = STALLS[this._idx]; d.detail = "확인 완료 " + done + " / 6곳 · 가격은 현장 매대 표시가 정답입니다"; d.guide = "왼쪽을 보면 앞 가게, 오른쪽을 보면 다음 가게, 정면을 보면 멈춥니다"; d.evt = 'EVT: ' + STALLS[this._idx]; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % STALLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + STALLS.length - 1) % STALLS.length; this._recompute(); },
  primaryTap() { this.openTap(); },
  openTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav('/pages/detail/index'); },
  recordTap() { this._nav('/pages/record/index'); },
  speakTap() { this._speak(STALLS[this._idx]); },
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
    <div class="band">광장시장 장보기</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="openTap">확인하러 가기</button><button class="btn" bindtap="nextTap">다음 가게</button><button class="btn" bindtap="recordTap">기록</button><button class="btn" bindtap="speakTap">음성</button>
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
