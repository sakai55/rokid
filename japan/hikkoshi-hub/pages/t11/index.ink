<script def>
{
  "title": "学校転校手続き"
}
</script>

<script setup>
import wx from 'wx';

// JP37 hikkoshi-hub - 学校転校手続き
const KEY = "hikkoshiHubV1";
const SLUGID = "t11";
const DEF = {"selected": 0, "tools": {}, "records": [], "calc": null, "compare": null};
const ITEMS = ["転校先の学校を確認する", "在学証明書をもらう", "教科書の手続きを確認する", "転校届を提出する", "給食費の手続きを確認する"];
const STATUS = "学校転校手続き：項目をひとつずつ確認します";
const GUIDE = "上下で項目を選ぶ ・ 切替で確認 ・ 保存で手帳に記録 ・ うなずきは切替";
function countDone(a) { var c = 0; var i; for (i = 0; i < a.length; i++) { if (a[i]) c++; } return c; }
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; var st = this._load(); var t = st.tools ? st.tools[SLUGID] : null; this._checked = (t && t.checked) ? t.checked.slice() : []; while (this._checked.length < ITEMS.length) { this._checked.push(false); } this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._checked[i] ? '済 ' : '未 ') + ITEMS[i]); } d.big = ITEMS[this._idx]; d.detail = '確認済み ' + countDone(this._checked) + '/' + ITEMS.length + '件です。'; d.guide = GUIDE; d.evt = 'EVT: ' + ITEMS[this._idx]; this.setData(d); },
  primaryTap() { this._checked[this._idx] = !this._checked[this._idx]; this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % ITEMS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._recompute(); },
  confirmTap() { var st = this._load(); if (!st.tools) st.tools = {}; st.tools[SLUGID] = { done: countDone(this._checked), total: ITEMS.length, checked: this._checked.slice() }; if (!st.records) st.records = []; st.records.push({ kind: "学校転校手続き", done: countDone(this._checked), total: ITEMS.length, at: new Date().toISOString() }); this._save(st); this._speak('保存しました。'); this._recompute(); },
  speakTap() { this._speak(ITEMS[this._idx] + 'です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'hikkoshi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">学校転校手続き</div>
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
      <button class="btn" bindtap="prevTap">前へ</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn main" bindtap="primaryTap">切替</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="confirmTap">保存</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.band{background-color:#0d3d17;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#7dff9e;border:1px solid #40ff5e;border-radius:8px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
.rrow{line-height:22px;}
</style>
