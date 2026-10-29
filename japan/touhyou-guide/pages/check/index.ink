<script def>
{
  "title": "持ち物・手順チェック"
}
</script>

<script setup>
import wx from 'wx';

// JP33 touhyou-guide - check
const KEY = "touhyouGuideV1";
const DEF = {"selected": 0, "checked": [], "records": []};
const CHECKITEMS = ["手順：入場整理券を出す", "手順：本人確認をする", "手順：投票用紙を受け取る", "手順：記載台で記入する", "手順：投票箱に入れる", "手順：出口で確認して帰る", "持ち物：入場整理券", "持ち物：本人確認書類", "持ち物：眼鏡", "持ち物：筆記用具", "持ち物：投票所の案内"];
const ALLDONE = "手順と持ち物は全部そろいました。";
const GUIDE = "前後で項目を変える ・ 確認でチェック ・ うなずきは主確認";
const REC_KIND = "投票手順チェック完了";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', r8: '', r9: '', r10: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); var arr = st.checked || []; var self = this; this._marks = CHECKITEMS.map(function (_, i) { return !!arr[i]; }); this._idx = 0; this._savedDone = false; this._recompute(); },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = '持ち物・手順チェック：' + done + ' / ' + CHECKITEMS.length + ' 完了'; for (i = 0; i < CHECKITEMS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._marks[i] ? '☑ ' : '☐ ') + CHECKITEMS[i]); } d.big = CHECKITEMS[this._idx]; d.detail = (done >= CHECKITEMS.length) ? ALLDONE : ('いま：' + CHECKITEMS[this._idx]); d.guide = GUIDE; d.evt = 'EVT: ' + done + '/' + CHECKITEMS.length; this.setData(d); },
  _persist() { var st = this._load(); st.checked = this._marks.slice(); this._save(st); },
  checkTap() { this._marks[this._idx] = !this._marks[this._idx]; this._persist(); var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; if (done >= CHECKITEMS.length) { if (!this._savedDone) { this._savedDone = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, at: new Date().toISOString() }); this._save(st); } this._speak(ALLDONE); } else { this._savedDone = false; this._speak(CHECKITEMS[this._idx]); } this._recompute(); },
  primaryTap() { this.checkTap(); },
  nextTap() { this._idx = (this._idx + 1) % CHECKITEMS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + CHECKITEMS.length - 1) % CHECKITEMS.length; this._recompute(); },
  speakTap() { this._speak(CHECKITEMS[this._idx]); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'touhyou-guide', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">持ち物・手順チェック</div>
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
    <div class="rrow">{{ r8 }}</div>
    <div class="rrow">{{ r9 }}</div>
    <div class="rrow">{{ r10 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="checkTap">確認する</button>
      <button class="btn" bindtap="prevTap">前へ</button>
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
.rrow{color:#7dff9e;font-size:12px;line-height:16px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:2px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:2px solid #7dff9e;border-radius:20px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
