<script def>
{
  "title": "广场舞步"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaSquareDanceV1";
const SLUG = "china-square-dance";
const STEPS = ["十字步", "三步踩", "转圈步", "摆手步", "踢腿步", "小跑步", "扭腰步", "拍手步"];
const SEQ = [0, 3, 1, 6, 2, 7, 4, 5, 1, 3];
const ZONES = ["左", "中", "右"];
const DEF = {"best": null, "records": []};
const STATUS = "头部方向选舞步，点头踩拍，10 轮结算";
const GUIDE = "左转切上一步、右转切下一步，须回中再切 · 分段动作，绝不转圈 · 无传感器时按钮也可玩";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; d.r0 = '玩法：每轮给一个目标舞步，选对再点头踩拍'; d.r1 = '共 10 轮，8 种舞步：十字步／三步踩／转圈步／摆手步'; d.r2 = '踢腿步／小跑步／扭腰步／拍手步'; d.r3 = '选步：左转上一步，右转下一步，回中再切'; d.r4 = '点头即踩拍，命中计分'; d.r5 = (st.best === null || st.best === undefined) ? '最佳：暂无' : ('最佳：' + st.best + '/10'); d.big = '广场舞步 · 10 轮'; d.detail = '家人只用头部方向选步，不用低头看手机'; d.guide = GUIDE; d.evt = 'EVT: index'; this.setData(d); },
  primaryTap() { this.playTap(); },
  playTap() { this._nav('/pages/play/index'); },
  recordTap() { this._nav('/pages/record/index'); },
  nextTap() { this._recompute(); },
  prevTap() { this._recompute(); },
  speakTap() { this._speak('广场舞步，头部方向选步，点头踩拍，十轮结算。'); },
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
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};
</script>

<template>
  <div class="page">
    <div class="band">广场舞步</div>
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
      <button class="btn main" bindtap="playTap">开始游戏</button>
      <button class="btn" bindtap="recordTap">看记录</button>
      <button class="btn" bindtap="speakTap">语音说明</button>
      <button class="btn" bindtap="backTap">返回</button>
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
.rrow12{color:#7dff9e;font-size:11px;line-height:13px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-top:2px solid #40ff5e;border-bottom:6px solid #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:6px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

</style>
