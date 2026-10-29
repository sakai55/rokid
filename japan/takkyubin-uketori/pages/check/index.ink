<script def>
{
  "title": "再配達手続き"
}
</script>

<script setup>
import wx from 'wx';

// JP34 takkyubin-uketori - check
const KEY = "takkyubinUketoriV1";
const DEF = {"selected": 0, "slot": 0, "method": 0, "records": []};
const SLOTS = ["9時〜12時", "12時〜14時", "14時〜16時", "16時〜18時", "18時〜20時", "20時〜21時"];
const METHODS = ["対面", "宅配ボックス", "コンビニ", "置き配"];
const GUIDE = "前後で時間帯を変える ・ 受取方法で方法を変える ・ うなずきは保存";
const DONE = "再配達を保存しました。";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._slot = (typeof st.slot === 'number') ? st.slot : 0; this._method = (typeof st.method === 'number') ? st.method : 0; this._recompute(); },
  _recompute() { var d = {}; d.status = '再配達手続き：時間帯と受取方法を選びます'; var i; for (i = 0; i < SLOTS.length; i++) { d['r' + i] = ((i === this._slot ? '▶ ' : '· ') + SLOTS[i]); } d.big = SLOTS[this._slot]; d.detail = '受取方法：' + METHODS[this._method] + ' ・ 受取方法一覧：' + METHODS.join('・'); d.guide = GUIDE; d.evt = 'EVT: ' + SLOTS[this._slot] + ' / ' + METHODS[this._method]; this.setData(d); },
  _persist() { var st = this._load(); st.slot = this._slot; st.method = this._method; this._save(st); },
  confirmTap() { this._persist(); var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '再配達手続き完了', slot: SLOTS[this._slot], method: METHODS[this._method], at: new Date().toISOString() }); this._save(st); this._speak(DONE + SLOTS[this._slot] + '、' + METHODS[this._method] + 'で受け取ります。'); this._recompute(); },
  primaryTap() { this.confirmTap(); },
  nextTap() { this._slot = (this._slot + 1) % SLOTS.length; this._persist(); this._recompute(); },
  prevTap() { this._slot = (this._slot + SLOTS.length - 1) % SLOTS.length; this._persist(); this._recompute(); },
  methodTap() { this._method = (this._method + 1) % METHODS.length; this._persist(); this._recompute(); },
  speakTap() { this._speak(SLOTS[this._slot] + '、' + METHODS[this._method] + 'で受け取ります。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'takkyubin-uketori', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">再配達手続き</div>
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
      <button class="btn main" bindtap="confirmTap">保存する</button>
      <button class="btn" bindtap="prevTap">前へ</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="methodTap">受取方法</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a3d24;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-left:6px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:2px solid #40ff5e;border-radius:4px;font-size:12px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14532d;color:#7dff9e;font-weight:bold;border-style:double;border-width:3px;}
</style>
