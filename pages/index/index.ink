<script def>
{
  "title": "包饺子守候"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaDumplingWatchV1";
const POTS = [{"name": "大蒸锅·猪肉白菜饺", "heat": "大火蒸", "mins": 20}, {"name": "中蒸锅·韭菜鸡蛋饺", "heat": "大火蒸", "mins": 15}, {"name": "小蒸锅·虾仁饺", "heat": "中火蒸", "mins": 12}, {"name": "电蒸箱·玉米饺", "heat": "自动档", "mins": 18}, {"name": "竹蒸笼·素三鲜饺", "heat": "大火蒸", "mins": 15}, {"name": "平底锅·煎饺", "heat": "中小火煎", "mins": 10}];
const DEF = {"selected": 0, "timers": [null, null, null], "records": []};
const STATUS = "包饺子时双手沾面，看向蒸锅点头登记计时";
const GUIDE = "首页选锅 · 守候页看向切槽位，点头登记或出锅 · 计时到时语音提醒";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected : 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < POTS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + POTS[i].name + ' · ' + POTS[i].mins + '分钟'); } d.big = POTS[this._idx].name; d.detail = '选中: ' + POTS[this._idx].heat + ' · ' + POTS[this._idx].mins + '分钟'; d.guide = GUIDE; d.evt = 'EVT: ' + POTS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % POTS.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + POTS.length - 1) % POTS.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  watchTap() { this._saveSel(); this._nav('/pages/watch/index'); },
  recordTap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.watchTap(); },
  speakTap() { this._speak(POTS[this._idx].name + '，' + POTS[this._idx].mins + '分钟。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'china-dumpling-watch', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">包饺子守候</div>
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
      <button class="btn main" bindtap="watchTap">开始守候</button>
      <button class="btn" bindtap="recordTap">记录</button>
      <button class="btn" bindtap="nextTap">下一个</button>
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
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border:2px solid #40ff5e;border-radius:18px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:18px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
