<script def>
{
  "title": "单手步骤"
}
</script>

<script setup>
import wx from 'wx';

// CC20 one-hand-open - check: five single-hand steps per item, toggle each, all done saves
const KEY = "oneHandOpenV1";
const SLUG = "one-hand-open";
const DEF = {"selected": 0, "logs": []};
const ITEMS = [{"name": "瓶盖", "premise": "一只手拧瓶盖, 另一只手腾不出来"}, {"name": "零食包装", "premise": "一只手撕开零食袋, 不洒出来"}, {"name": "快递箱", "premise": "一只手拆快递箱, 不用牙咬胶带"}, {"name": "罐头", "premise": "一只手开罐头拉环, 不割到手"}, {"name": "药瓶", "premise": "一只手开药瓶, 药片不洒"}, {"name": "饮料拉环", "premise": "一只手拉开易拉罐, 不溅出来"}];
const STEPS = {"瓶盖": ["把瓶身夹在两膝之间", "用桌沿卡住瓶盖", "单手反向拧", "拧不动先松后紧", "盖子放稳防滚"], "零食包装": ["包装袋一角压在桌沿下", "单手捏住另一角", "向身体方向慢撕", "撕口够大停手", "倒出不洒"], "快递箱": ["箱子靠墙角顶住", "胶带一端用膝盖压住", "单手沿中线划开", "先开一面再翻面", "取出物品核对"], "罐头": ["罐身放进抽屉缝卡住", "拉环勾住桌沿", "单手下压起盖", "盖口朝外防割手", "倒出后盖子朝下放"], "药瓶": ["瓶身夹在腋下固定", "下压式盖先压后转", "转不动换手掌根部压", "药片倒在掌心数", "盖紧后放回原处"], "饮料拉环": ["易拉罐夹在两腿间", "拉环勾在钥匙圈上", "单手向后拉", "拉环不断慢慢加力", "开口朝上防溅"]};
const STATUS = "一步一步勾, 做完按全部完成";
const GUIDE = "步骤是单手重构的通用做法, 锋利或烫手物品先停手求助, 不作医疗建议";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected % ITEMS.length : 0; this._step = 0; this._done = [false, false, false, false, false, false]; this._saved = false; this._recompute(); },
  onShow() { this._recompute(); },
  _steps() { return STEPS[ITEMS[this._idx].name]; },
  _count() { var n = 0; var i; for (i = 0; i < 5; i++) { if (this._done[i]) n++; } return n; },
  _recompute() { var steps = this._steps(); var d = {}; d.status = STATUS; d.big = ITEMS[this._idx].name; var i; for (i = 0; i < 5; i++) { d['r' + i] = ((i === this._step ? '▶ ' : '· ') + (this._done[i] ? '✓ ' : '○ ') + steps[i]); } d.detail = '进度 ' + this._count() + ' / 5 步 · ' + ITEMS[this._idx].premise; d.guide = GUIDE; d.evt = 'EVT: ' + ITEMS[this._idx].name + ' ' + this._count() + '/5'; this.setData(d); },
  nextTap() { this._step = (this._step + 1) % 5; this._recompute(); },
  prevTap() { this._step = (this._step + 4) % 5; this._recompute(); },
  toggleTap() { this._done[this._step] = !this._done[this._step]; this._saved = false; this._speak((this._done[this._step] ? '已完成: ' : '取消完成: ') + this._steps()[this._step]); this._recompute(); },
  doneTap() { if (this._count() < 5) { this._speak('还差 ' + (5 - this._count()) + ' 步'); this._recompute(); return; } if (!this._saved) { var st = this._load(); if (!st.logs) st.logs = []; st.logs.push({ item: ITEMS[this._idx].name, at: new Date().toISOString() }); this._save(st); this._saved = true; } this._speak(ITEMS[this._idx].name + '全部完成, 已记下'); this._recompute(); },
  primaryTap() { this.toggleTap(); },
  speakTap() { this._speak(ITEMS[this._idx].name + ', 当前一步: ' + this._steps()[this._step] + ', 进度' + this._count() + '步, 共5步'); },
  recordTap() { this._nav('/pages/record/index'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._fail('E5002', 'storage read'); } return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: SLUG, version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">单手步骤</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="prevTap">上一步</button>
      <button class="btn main" bindtap="toggleTap">勾选本步</button>
      <button class="btn" bindtap="nextTap">下一步</button>
    </div>
    <div class="btnrow">
      <button class="btn main" bindtap="doneTap">全部完成</button>
      <button class="btn" bindtap="speakTap">语音播报</button>
      <button class="btn" bindtap="recordTap">完成记录</button>
      <button class="btn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:22px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a3d33;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0d4d3d;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1a7a5e;color:#7dff9e;font-weight:bold;}
</style>
