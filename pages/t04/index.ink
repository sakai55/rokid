<script def>
{
  "title": "秋刀魚方向当て"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "akiMatsuriGameShuuV1";
const DEF = {"selected": 0, "best": {}, "bestN": {}, "records": []};
const KIND = "秋刀魚方向当て";
const DIRS = ["左", "中央", "右"];
const TARGETS = [0, 1, 2, 0, 2, 1];
const STATUS = "秋刀魚方向当て";
const GUIDE = "頭の向きで左・中央・右を選ぶ ・ 中央に戻してから次を選ぶ ・ うなずきで決める";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 3; this._round = 0; this._hits = 0; this._dir = 1; this._centred = true; this._done = false; this._sensorOk = false; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); if (Math.abs(yaw) < 0.35) { self._centred = true; } else if (self._centred && yaw < -0.35) { self._dir = 0; self._centred = false; } else if (self._centred && yaw > 0.35) { self._dir = 2; self._centred = false; } self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; if (this._done) { d.big = '集計: ' + this._hits + '/6'; d.r0 = '6回終わりました'; d.r1 = '当たった回数: ' + this._hits + ' / 6'; d.r2 = 'ベスト: ' + ((st.best && st.best[String(this._sel)]) ? st.best[String(this._sel)] : 'まだなし'); d.r3 = '記録 ' + (st.records ? st.records.length : 0) + '件'; d.r4 = ''; d.r5 = ''; d.detail = KIND + 'の集計です。記録に残しました。'; } else { d.big = DIRS[TARGETS[this._round]] + 'を当てよう'; d.r0 = '第' + (this._round + 1) + '回 / 全6回'; d.r1 = 'あなたの向き: ' + DIRS[this._dir]; d.r2 = '当たった回数: ' + this._hits; d.r3 = 'ベスト: ' + ((st.best && st.best[String(this._sel)]) ? st.best[String(this._sel)] : 'まだなし'); d.r4 = this._sensorOk ? '頭の向きセンサー接続中' : 'センサーなし ・ ボタンで向きを変える'; d.r5 = '中央に戻してから次を選ぶ'; d.detail = '頭の向きで選んで、うなずきで決める'; } d.guide = GUIDE; d.evt = 'EVT: round ' + (this._round + 1) + '/6 hits ' + this._hits; this.setData(d); },
  decideTap() { if (this._done) { this._nav('/pages/index/index'); return; } var t = TARGETS[this._round]; if (this._dir === t) { this._hits++; this._speak('当たりです。'); } else { this._speak('はずれです。向きは' + DIRS[t] + 'でした。'); } this._round++; if (this._round >= TARGETS.length) { this._done = true; this._finish(KIND, this._hits + '/6方向', this._hits, this._hits + '/6方向'); this._speak('集計は' + this._hits + '回当たりです。'); } this._recompute(); },
  primaryTap() { this.decideTap(); },
  nextTap() { this._dir = (this._dir + 1) % 3; this._centred = false; this._recompute(); },
  prevTap() { this._dir = (this._dir + 2) % 3; this._centred = false; this._recompute(); },
  speakTap() { if (this._done) this._speak('集計は' + this._hits + '回当たりです。'); else this._speak('あなたの向きは' + DIRS[this._dir] + 'です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'aki-matsuri-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  _finish(kind, item, score, text) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: kind, item: item, at: new Date().toISOString() }); if (!st.best) st.best = {}; if (!st.bestN) st.bestN = {}; var oldN = st.bestN[String(this._sel)]; if (oldN === undefined || oldN === null || score > oldN) { st.bestN[String(this._sel)] = score; st.best[String(this._sel)] = text; } this._save(st); },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },

};
</script>

<template>
  <div class="page">
    <div class="band">秋刀魚方向当て</div>
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
      <button class="btn main" bindtap="decideTap">方向を決める</button>
      <button class="btn" bindtap="nextTap">向きを変える</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.band{background-color:#123d1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:3px double #40ff5e;border-radius:12px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d1a;color:#7dff9e;border:2px solid #40ff5e;border-bottom:4px solid #40ff5e;border-radius:12px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
