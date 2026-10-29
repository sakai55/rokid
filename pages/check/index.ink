<script def>
{
  "title": "返却・延長チェック"
}
</script>

<script setup>
import wx from 'wx';

// JP36 toshokan-kaeshi - check
const KEY = "toshokanKaeshiV1";
const DEF = {"selected": 0, "done": {}, "records": []};
const BOOKS = ["坊っちゃん ・ 返却期限11月2日", "吾輩は猫である ・ 返却期限11月2日", "銀河鉄道の夜 ・ 返却期限11月5日", "人間失格 ・ 返却期限11月5日", "こころ ・ 返却期限11月9日", "雪国 ・ 返却期限11月9日", "羅生門 ・ 返却期限11月12日", "蜘蛛の糸 ・ 返却期限11月12日"];
const METHODS = ["カウンター", "返却ポスト", "延長"];
const GUIDE = "返却方法ボタンで方法を変える ・ 確認するで記録 ・ うなずきは主確認";
const REC_KIND = "返却チェック完了";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._idx = this._sel; var done = st.done || {}; var self = this; this._marks = BOOKS.map(function (_, i) { return !!done[String(i)]; }); this._method = 0; this._recompute(); },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = '返却・延長チェック: ' + done + ' / 8 冊確認済み ・ 方法: ' + METHODS[this._method]; for (i = 0; i < BOOKS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._marks[i] ? '☑ ' : '☐ ') + BOOKS[i]); } d.big = BOOKS[this._idx]; d.detail = 'いま: ' + BOOKS[this._idx] + ' ・ 方法は' + METHODS[this._method] + 'です。返却方法は3つです。'; d.guide = GUIDE; d.evt = 'EVT: ' + done + '/8 ' + METHODS[this._method]; this.setData(d); },
  _persist() { var st = this._load(); var done = {}; var i; for (i = 0; i < this._marks.length; i++) done[String(i)] = !!this._marks[i]; st.done = done; st.selected = this._idx; this._save(st); },
  methodTap() { this._method = (this._method + 1) % METHODS.length; this._recompute(); },
  checkTap() { this._marks[this._idx] = !this._marks[this._idx]; this._persist(); if (this._marks[this._idx]) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, book: BOOKS[this._idx], method: METHODS[this._method], at: new Date().toISOString() }); this._save(st); this._speak(BOOKS[this._idx] + 'を' + METHODS[this._method] + 'で確認しました。'); } else { this._speak(BOOKS[this._idx] + 'のチェックをはずしました。'); } this._recompute(); },
  primaryTap() { this.checkTap(); },
  nextTap() { this._idx = (this._idx + 1) % BOOKS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + BOOKS.length - 1) % BOOKS.length; this._recompute(); },
  speakTap() { this._speak(BOOKS[this._idx] + '、方法は' + METHODS[this._method] + 'です。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'toshokan-kaeshi', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">返却・延長チェック</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    <div class="rrow">{{ r6 }}</div>
    <div class="rrow">{{ r7 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="checkTap">確認する</button>
      <button class="btn" bindtap="methodTap">返却方法</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-left:8px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-left:6px solid #40ff5e;border-radius:0;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
