<script def>
{
  "title": "日本旅行手帳"
}
</script>

<script setup>
import wx from 'wx';

// JP42 nihon-tabi-hub - index
const KEY = "nihonTabiHubV1";
const TID = "index";
const TOOLS = [{"name": "新幹線乗換", "url": "/pages/t01/index"}, {"name": "在来線乗換", "url": "/pages/t02/index"}, {"name": "バス路線", "url": "/pages/t03/index"}, {"name": "宿泊チェック", "url": "/pages/t04/index"}, {"name": "お土産リスト", "url": "/pages/t05/index"}, {"name": "お城見学", "url": "/pages/t06/index"}, {"name": "庭園散策", "url": "/pages/t07/index"}, {"name": "博物館", "url": "/pages/t08/index"}, {"name": "水族館", "url": "/pages/t09/index"}, {"name": "市場食べ歩き", "url": "/pages/t10/index"}, {"name": "カフェ注文", "url": "/pages/t11/index"}, {"name": "両替計算", "url": "/pages/t12/index"}, {"name": "天気服装", "url": "/pages/t13/index"}, {"name": "写真スポット", "url": "/pages/t14/index"}, {"name": "忘れ物チェック", "url": "/pages/t15/index"}, {"name": "緊急電話", "url": "/pages/t16/index"}, {"name": "駅弁選び", "url": "/pages/t17/index"}, {"name": "乗換時間", "url": "/pages/t18/index"}, {"name": "荷物預かり", "url": "/pages/t19/index"}, {"name": "旅行記録", "url": "/pages/t20/index"}];
const TOTALS = [5, 5, 4, 5, 6, 4, 5, 4, 3, 4, 4, 3, 3, 4, 6, 4, 3, 4, 4, 6];
const STATUS = "日本を旅する人が、旅行道具20種を一冊の手帳で回します";
const GUIDE = "上下で道具を選ぶ · 決定で開く · うなずきは決定と同じ";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected : 0; this._recompute(); },
  onShow() { var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected : 0; this._recompute(); },
  _recompute() { var st = this._load(); var tools = st.tools || {}; var recs = st.records || []; var doneSum = 0; var i; for (i = 0; i < 19; i++) { var tid0 = ('t' + ('0' + (i + 1)).slice(-2)); if (tools[tid0]) doneSum += tools[tid0].done; } var d = {}; d.status = STATUS; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; var tid = ('t' + ('0' + (ti + 1)).slice(-2)); var ent = tools[tid]; var dn = ent ? ent.done : 0; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name + ' ' + dn + '/' + TOTALS[ti]); } d.big = TOOLS[this._idx].name; d.detail = '進み具合 ' + doneSum + '/80 · 記録 ' + recs.length + '件です。'; d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + 'です。'); },

  _fresh() { return {"selected": 0, "tools": {}, "marks": {}, "counts": {}, "quiz": {}, "spoken": {}, "records": []}; },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return this._fresh(); },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = this._fresh(); st.lastError = { code: code, slug: 'nihon-tabi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">日本旅行手帳</div>
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
      <button class="btn main" bindtap="primaryTap">開く</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:22px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows .rrow{font-size:13px;line-height:20px;}
.band{background-color:#0d2b16;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
