<script def>
{
  "title": "猜灯谜"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "dengmiGameV1";
const RIDDLES = [{"topic": "第1谜·天上圆盘", "riddle": "一个大圆盘，夜夜挂天边，十五最圆满，家家抬头看", "opts": ["月亮", "星星", "太阳", "灯笼"], "ans": 0, "why": "十五的月亮最圆，所以是月亮。"}, {"topic": "第2谜·屋里四腿", "riddle": "四条腿，一张面，吃饭写字都离它，立在屋里不动弹", "opts": ["椅子", "桌子", "床", "柜子"], "ans": 1, "why": "四条腿一张面，是桌子。"}, {"topic": "第3谜·千里说话", "riddle": "没长脚，会走路，没长嘴，会说话，千里话儿一线牵", "opts": ["书信", "电话", "电视", "马匹"], "ans": 1, "why": "拿起就能说话传千里，是电话。"}, {"topic": "第4谜·夏日清凉", "riddle": "身穿绿衣裳，肚里水汪汪，夏天切开吃，又甜又清凉", "opts": ["冬瓜", "黄瓜", "南瓜", "西瓜"], "ans": 3, "why": "绿皮红瓤水多，是西瓜。"}, {"topic": "第5谜·天亮打鸣", "riddle": "头顶红帽子，天不亮就喊，喔喔催人起，从不睡懒觉", "opts": ["鸭子", "公鸡", "喜鹊", "母鸡"], "ans": 1, "why": "天亮打鸣的是公鸡。"}, {"topic": "第6谜·池塘粉衣", "riddle": "出水小姑娘，粉衣随风摇，立在池塘里，香气引人瞧", "opts": ["桃花", "荷花", "菊花", "梅花"], "ans": 1, "why": "出水开粉花，是荷花。"}, {"topic": "第7谜·桌上双棍", "riddle": "两根小棍一头尖，吃饭夹菜不用手，人人桌上都有一双", "opts": ["筷子", "勺子", "叉子", "刀子"], "ans": 0, "why": "两根棍夹菜，是筷子。"}, {"topic": "第8谜·蓝天牵线", "riddle": "圆圆脑袋一根线，飞上蓝天不回家，风越大来它越欢", "opts": ["气球", "风筝", "飞机", "云朵"], "ans": 1, "why": "牵线飞上天，是风筝。"}, {"topic": "第9谜·越洗越小", "riddle": "白白胖胖水里泡，越洗越小不见了，洗衣洗澡少不了", "opts": ["毛巾", "洗衣粉", "肥皂", "水盆"], "ans": 2, "why": "遇水变小去污，是肥皂。"}, {"topic": "第10谜·玻璃亮房", "riddle": "小小玻璃房，肚里一根丝，一通电就亮，满屋亮堂堂", "opts": ["蜡烛", "镜子", "灯泡", "窗户"], "ans": 2, "why": "通电发亮的玻璃房，是灯泡。"}, {"topic": "第11谜·沙漠双峰", "riddle": "远看像座山，近看会走路，背上两座峰，沙漠里赶路", "opts": ["大象", "马", "骆驼", "牛"], "ans": 2, "why": "背双峰走沙漠，是骆驼。"}, {"topic": "第12谜·藤上玛瑙", "riddle": "一根藤儿弯弯绕，架上结串紫玛瑙，酸酸甜甜人人爱", "opts": ["樱桃", "桑葚", "李子", "葡萄"], "ans": 3, "why": "藤上紫玛瑙，是葡萄。"}];
const DEF = {"selected": 0, "records": []};
const STATUS = "头动选答案：左/右一步一换，回正再换，点头确认";
const GUIDE = "头向左/右一步一步换选项，回正后再换，点头确认答案";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._qi = 0; this._score = 0; this._sel = 0; this._optN = 4; this._wasCenter = true; this._done = false; this._lastWhy = ''; this._startSensor(); this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; if (this._done) { d.big = '结算：' + this._score + '/12'; d.detail = '猜对 ' + this._score + ' 条，共 12 条，已记入记录。'; for (var i = 0; i < 4; i++) d['r' + i] = '· ' + RIDDLES[0].opts[i]; } else { var q = RIDDLES[this._qi]; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._sel ? '▶ ' : '· ') + q.opts[i]); } d.big = q.riddle; d.detail = (this._lastWhy ? this._lastWhy : ('第' + (this._qi + 1) + '谜，共 12 谜 · 已对 ' + this._score + ' 条')); } d.guide = GUIDE; d.evt = 'EVT: ' + this._qi + '/12 score ' + this._score; this.setData(d); },
  primaryTap() { if (this._done) { this._nav('/pages/record/index'); return; } var q = RIDDLES[this._qi]; if (this._sel === q.ans) { this._score++; this._speak('猜对了。' + q.why); } else { this._speak('不对。' + q.why); } this._lastWhy = q.why; this._qi++; this._sel = 0; this._wasCenter = true; if (this._qi >= RIDDLES.length) { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '猜谜结算', item: '元宵灯谜12条', score: this._score, total: 12, at: new Date().toISOString() }); this._save(st); this._speak('结算。猜对 ' + this._score + ' 条。'); } this._recompute(); },
  nextTap() { if (this._done) return; this._sel = (this._sel + 1) % 4; this._recompute(); },
  prevTap() { if (this._done) return; this._sel = (this._sel + 3) % 4; this._recompute(); },
  speakTap() { if (this._done) this._speak('结算。'); else this._speak(RIDDLES[this._qi].riddle + ' ' + RIDDLES[this._qi].opts[this._sel] + '。'); },
  backTap() { this._back(); },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); var z = (yaw < -0.35) ? 0 : ((yaw > 0.35) ? 2 : 1); if (z === 1) { self._wasCenter = true; } else if (self._wasCenter) { self._wasCenter = false; self._stepSel(z === 0 ? -1 : 1); } self._recompute(); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _stepSel(d) { this._sel = (this._sel + d + this._optN) % this._optN; },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'dengmi-game', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">猜灯谜</div>
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
      <button class="btn main" bindtap="primaryTap">确认答案</button>
      <button class="btn" bindtap="nextTap">换选项</button>
      <button class="btn" bindtap="speakTap">语音</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:18px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 12px;border:3px double #40ff5e;text-align:center;letter-spacing:4px;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
