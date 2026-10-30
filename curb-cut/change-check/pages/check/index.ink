<script def>
{
  "title": "找零核对"
}
</script>

<script setup>
import wx from 'wx';

// CC19 change-check - check: adjust paid and change received, show ONLY the conclusion
const KEY = "changeCheckV1";
const SLUG = "change-check";
const DEF = {"selected": 0, "logs": []};
const ITEMS = [{"name": "矿泉水", "due": 3}, {"name": "面包", "due": 8}, {"name": "牛奶", "due": 12}, {"name": "鸡蛋", "due": 15}, {"name": "青菜", "due": 6}, {"name": "纸巾", "due": 10}];
const STATUS = "调好实付额和找回额, 按结论只看一句话";
const GUIDE = "结论只核对数字, 不代表商家账目; 算式过程不在屏上显示";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected % ITEMS.length : 0; this._paid = ITEMS[this._idx].due; this._back_amt = 0; this._result = ''; this._savedSig = ''; this._recompute(); },
  onShow() { this._recompute(); },
  _due() { return ITEMS[this._idx].due; },
  _recompute() { var d = {}; d.status = STATUS; d.big = this._result ? this._result : '调好数字, 按结论'; d.r0 = '买的东西: ' + ITEMS[this._idx].name; d.r1 = '应付额: ' + this._due() + '元'; d.r2 = '实付额: ' + this._paid + '元'; d.r3 = '找回额: ' + this._back_amt + '元'; d.r4 = '实付每次加减 100 元, 找回每次加减 1 元'; d.r5 = '结论只显示一句话, 不显示算式'; d.detail = '应付 ' + this._due() + '元 · 实付 ' + this._paid + '元 · 找回 ' + this._back_amt + '元'; d.guide = GUIDE; d.evt = 'EVT: ' + ITEMS[this._idx].name; this.setData(d); },
  paidUpTap() { this._paid = this._paid + 100; this._result = ''; this._recompute(); },
  paidDownTap() { this._paid = Math.max(0, this._paid - 100); this._result = ''; this._recompute(); },
  backUpTap() { this._back_amt = this._back_amt + 1; this._result = ''; this._recompute(); },
  backDownTap() { this._back_amt = Math.max(0, this._back_amt - 1); this._result = ''; this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % ITEMS.length; this._paid = ITEMS[this._idx].due; this._back_amt = 0; this._result = ''; this._recompute(); },
  prevTap() { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._paid = ITEMS[this._idx].due; this._back_amt = 0; this._result = ''; this._recompute(); },
  conclusionTap() { var diff = this._paid - this._due() - this._back_amt; if (diff === 0) { this._result = '对的'; } else if (diff > 0) { this._result = '少了 ' + diff + '元'; } else { this._result = '多了 ' + (-diff) + '元'; } var sig = this._due() + '|' + this._paid + '|' + this._back_amt + '|' + this._result; if (sig !== this._savedSig) { var st = this._load(); if (!st.logs) st.logs = []; st.logs.push({ item: ITEMS[this._idx].name, due: this._due(), paid: this._paid, back: this._back_amt, result: this._result, at: new Date().toISOString() }); this._save(st); this._savedSig = sig; } this._speak(this._result); this._recompute(); },
  primaryTap() { this.conclusionTap(); },
  speakTap() { this._speak(this._result ? this._result : '先调好实付额和找回额, 再按结论'); },
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
    <div class="band">找零核对</div>
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
      <button class="btn" bindtap="paidUpTap">实付+100</button>
      <button class="btn" bindtap="paidDownTap">实付-100</button>
      <button class="btn" bindtap="backUpTap">找回+1</button>
      <button class="btn" bindtap="backDownTap">找回-1</button>
    </div>
    <div class="btnrow">
      <button class="btn main" bindtap="conclusionTap">结论</button>
      <button class="btn" bindtap="speakTap">语音播报</button>
      <button class="btn" bindtap="recordTap">核对记录</button>
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
.band{background-color:#1e4d00;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#1a3d00;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#3d8b1f;color:#7dff9e;font-weight:bold;}
</style>
