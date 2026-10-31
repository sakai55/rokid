<script def>
{
  "title": "高齢者暮らし手帳"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "seniorKurashiHubV1";
const TOOLS = [{"name": "朝の薬", "url": "/pages/t01/index"}, {"name": "血圧メモ", "url": "/pages/t02/index"}, {"name": "買い物リスト", "url": "/pages/t03/index"}, {"name": "ゴミ出し確認", "url": "/pages/t04/index"}, {"name": "散歩コース", "url": "/pages/t05/index"}, {"name": "友人電話", "url": "/pages/t06/index"}, {"name": "趣味の時間", "url": "/pages/t07/index"}, {"name": "昼食メニュー", "url": "/pages/t08/index"}, {"name": "午後の体操", "url": "/pages/t09/index"}, {"name": "孫への手紙", "url": "/pages/t10/index"}, {"name": "銀行・年金メモ", "url": "/pages/t11/index"}, {"name": "予定確認", "url": "/pages/t12/index"}, {"name": "天気と服装", "url": "/pages/t13/index"}, {"name": "夕食メニュー", "url": "/pages/t14/index"}, {"name": "入浴準備", "url": "/pages/t15/index"}, {"name": "明日の持ち物", "url": "/pages/t16/index"}, {"name": "連絡先", "url": "/pages/t17/index"}, {"name": "緊急連絡", "url": "/pages/t18/index"}, {"name": "日記", "url": "/pages/t19/index"}, {"name": "暮らし記録", "url": "/pages/t20/index"}];
const DEF = {"selected": 0, "checked": {}, "counts": {}, "records": []};
const STATUS = "高齢者の一日の暮らし道具20本を一冊の手帳で回します";
const GUIDE = "次へで道具を変える ・ 開くで使う ・ うなずきは主確認";
function DETAILFN(st) { return '使った記録は' + (st.records ? st.records.length : 0) + '件です。'; }
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name); } d.big = TOOLS[this._idx].name; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + 'です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'senior-kurashi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">高齢者暮らし手帳</div>
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
      <button class="btn" bindtap="backTap">もどる</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:13px;line-height:20px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a3d1e;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border:2px solid #40ff5e;border-radius:10px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#123d2a;color:#7dff9e;border:1px solid #40ff5e;border-radius:10px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
