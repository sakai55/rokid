<script def>
{
  "title": "七巧板拼图"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaTangramGameV1";
const PUZ = [{"name": "天鹅", "slots": ["颈部上方", "翅膀外侧", "身体下方", "尾部后方"], "ans": 1, "why": "翅膀外侧落板，天鹅展翅成形。"}, {"name": "帆船", "slots": ["桅杆顶部", "船帆右侧", "船身下方", "水面左侧"], "ans": 0, "why": "桅杆顶部落板，帆船扬帆成形。"}, {"name": "房子", "slots": ["屋顶左角", "墙面右侧", "门口下方", "窗户旁边"], "ans": 2, "why": "门口下方落板，房子有了出入。"}, {"name": "猫", "slots": ["耳朵上方", "胡须旁边", "尾巴末端", "爪子前方"], "ans": 3, "why": "爪子前方落板，小猫伸爪成形。"}, {"name": "狗", "slots": ["鼻子前方", "耳朵后方", "身体下方", "尾巴上方"], "ans": 0, "why": "鼻子前方落板，小狗嗅闻成形。"}, {"name": "兔子", "slots": ["长耳顶端", "红眼旁边", "短尾后方", "前腿下方"], "ans": 2, "why": "短尾后方落板，兔子蹦跳成形。"}, {"name": "山", "slots": ["山顶上方", "山腰左侧", "山脚下方", "云雾旁边"], "ans": 1, "why": "山腰左侧落板，群山连绵成形。"}, {"name": "桥", "slots": ["桥头左侧", "桥面中央", "桥洞下方", "桥尾右侧"], "ans": 3, "why": "桥尾右侧落板，石桥贯通成形。"}, {"name": "人跑步", "slots": ["抬起的前脚", "摆动的手臂", "弯曲的后腿", "前倾的身体"], "ans": 2, "why": "弯曲的后腿落板，跑步姿态成形。"}, {"name": "蝴蝶", "slots": ["左翅上方", "右翅下方", "触角顶端", "身体中央"], "ans": 1, "why": "右翅下方落板，蝴蝶振翅成形。"}, {"name": "鱼", "slots": ["鱼头前方", "鱼鳍旁边", "鱼尾后方", "鱼身下方"], "ans": 0, "why": "鱼头前方落板，游鱼摆尾成形。"}, {"name": "宝塔", "slots": ["塔尖顶部", "塔檐右侧", "塔基下方", "塔门旁边"], "ans": 0, "why": "塔尖顶部落板，宝塔高耸成形。"}];
const DEF = {"selected": 0, "best": 0, "records": []};
const STATUS = "头动选位置：左/右一步一换，回正再换，点头落板";
const GUIDE = "头向左/右一步一步换位置，回正后再换，点头落板确认";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._qi = 0; this._score = 0; this._sel = 0; this._optN = 4; this._wasCenter = true; this._done = false; this._lastWhy = ''; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; if (this._done) { d.big = '结算：' + this._score + '/12'; d.detail = '拼对 ' + this._score + ' 幅，共 12 幅，已记入记录。'; for (var i = 0; i < 4; i++) d['r' + i] = '· ' + PUZ[0].slots[i]; } else { var q = PUZ[this._qi]; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._sel ? '▶ ' : '· ') + q.slots[i]); } d.big = q.name; d.detail = (this._lastWhy ? this._lastWhy : ('第' + (this._qi + 1) + '幅，共 12 幅 · 已对 ' + this._score + ' 幅')); } d.guide = GUIDE; d.evt = 'EVT: ' + this._qi + '/12 score ' + this._score; this.setData(d); },
  primaryTap() { if (this._done) { this._nav('/pages/record/index'); return; } var q = PUZ[this._qi]; if (this._sel === q.ans) { this._score++; this._speak('落对了。' + q.why); } else { this._speak('位置不对。' + q.why); } this._lastWhy = q.why; this._qi++; this._sel = 0; this._wasCenter = true; if (this._qi >= PUZ.length) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '拼图结算', item: '七巧板12幅', score: this._score, total: 12, at: new Date().toISOString() }); if (!st.best || this._score > st.best) st.best = this._score; this._save(st); this._speak('结算。拼对 ' + this._score + ' 幅。'); } this._recompute(); },
  nextTap() { if (this._done) return; this._sel = (this._sel + 1) % 4; this._recompute(); },
  prevTap() { if (this._done) return; this._sel = (this._sel + 3) % 4; this._recompute(); },
  speakTap() { if (this._done) this._speak('结算。'); else this._speak(PUZ[this._qi].name + ' ' + PUZ[this._qi].slots[this._sel] + '。'); },
  backTap() { this._back(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); var z = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); if (z === 1) { self._wasCenter = true; } else if (self._wasCenter) { self._wasCenter = false; self._stepSel(z === 0 ? -1 : 1); } self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _stepSel(d) { this._sel = (this._sel + d + this._optN) % this._optN; },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'china-tangram-game', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">七巧板拼图</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">返回</button>
      <button class="btn main" bindtap="primaryTap">落板确认</button>
      <button class="btn" bindtap="nextTap">换位置</button>
      <button class="btn" bindtap="speakTap">语音</button>
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
.foot{position:absolute;left:14px;top:292px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 12px;border:3px double #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
