<script def>
{
  "title": "お迎えチェック"
}
</script>

<script setup>
import wx from 'wx';

// JP39 narai-okuri - check
const KEY = "naraiOkuriV1";
const DEF = {"selected": 0, "checks": {}, "records": []};
const LESSONS = ["ピアノ ・ 16時30分 ・ 市民センター", "水泳 ・ 17時 ・ 市営プール", "英語 ・ 16時 ・ 英語教室", "サッカー ・ 17時30分 ・ 河川敷グラウンド", "書道 ・ 15時30分 ・ 公民館", "そろばん ・ 16時 ・ そろばん塾"];
const CHECKS = ["迎えの時間", "迎えの場所", "持ち物", "連絡先", "帰りの交通手段"];
const GUIDE = "確認するで項目を切替える ・ 5つそろうと記録 ・ うなずきは主確認";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; var saved = st.checks || {}; var self = this; this._marks = CHECKS.map(function (_, i) { return !!saved[String(i)]; }); this._idx = 0; this._recompute(); },
  _allDone() { var i; for (i = 0; i < this._marks.length; i++) if (!this._marks[i]) return false; return true; },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = 'お迎えチェック: ' + done + ' / 5 項目 ・ 習い事: ' + LESSONS[this._sel]; for (i = 0; i < CHECKS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._marks[i] ? '☑ ' : '☐ ') + CHECKS[i]); } d.big = CHECKS[this._idx]; d.detail = 'いま: ' + CHECKS[this._idx] + ' ・ 5つそろうとお迎えの記録が残ります。'; d.guide = GUIDE; d.evt = 'EVT: ' + done + '/5'; this.setData(d); },
  _persist() { var st = this._load(); var c = {}; var i; for (i = 0; i < this._marks.length; i++) c[String(i)] = !!this._marks[i]; st.checks = c; st.selected = this._sel; this._save(st); },
  checkTap() { var wasAll = this._allDone(); this._marks[this._idx] = !this._marks[this._idx]; this._persist(); if (this._allDone() && !wasAll) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: 'お迎えチェック完了', item: LESSONS[this._sel], at: new Date().toISOString() }); this._save(st); this._speak(LESSONS[this._sel] + 'のお迎えチェックが5つそろいました。お迎えの記録を残しました。'); } else if (this._marks[this._idx]) { this._speak(CHECKS[this._idx] + 'を確認しました。'); } else { this._speak(CHECKS[this._idx] + 'のチェックをはずしました。'); } this._recompute(); },
  primaryTap() { this.checkTap(); },
  nextTap() { this._idx = (this._idx + 1) % CHECKS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + CHECKS.length - 1) % CHECKS.length; this._recompute(); },
  speakTap() { this._speak(CHECKS[this._idx] + 'です。'); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'narai-okuri', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">お迎えチェック</div>
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
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="checkTap">確認する</button>
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
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;border-top:1px dashed #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:2px dashed #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;border-style:solid;}
</style>
