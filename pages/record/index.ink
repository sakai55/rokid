<script def>
{
  "title": "記録"
}
</script>

<script setup>
import wx from 'wx';

// JP31 ekiben-erabi - record
const KEY = "ekibenErabiV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const NOWTXT = "いま: ";
const CHOOSETXT = "選んで、決定で答える";
const CORRECTTXT = "正解です。";
const WRONG1 = "ちがいます。答えは";
const WRONG2 = "です。";
const QEND = "。";
const QSEP = "、";
const GOALTXT = " ・ 目標達成";
const CNT1 = "、いま";
const CNT2 = "、目標は";
const CNT3 = "です。";
const REC1 = "記録は";
const REC2 = "件です。";
const RECNONE = "記録はまだありません。";
const PHRASEDETAIL = "選んだ文を、声で代わりに言います。";
const WORDLAST = "最後の語です。言い終えたら完了を押してください。";
const WORDNEXT = "うなずくたびに、次の語へ進みます。";
const WORDDONE = "言い終えました。";
const LINELAST = "最後の行です。読み終えたら完了を押してください。";
const LINENEXT = "うなずくたびに、次の行へ進みます。";
const LINEDONE = "読み終えました。";
const SCORETXT = "点";
const RECDETAIL = "記録は端末に保存されています。";
const RSTATUS = "駅弁の記録";
const GUIDE = "NEXTで弁当を変える ・ クイズで確認 ・ うなずきは主確認";
function SUMMARY(st) { return '記録は' + (st.records ? st.records.length : 0) + '件です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var recs = st.records || []; var d = {}; d.status = RSTATUS; var i; for (i = 0; i < 6; i++) { var r = recs[recs.length - 1 - i]; d['r' + i] = r ? (r.kind + (r.score !== undefined ? ' ' + r.score + SCORETXT : '') + (r.count !== undefined ? ' ' + r.count : '')) : ''; } d.big = SUMMARY(st); d.detail = RECDETAIL; d.guide = GUIDE; d.evt = 'EVT: records ' + recs.length; this.setData(d); },
  primaryTap() { var rr = this._load().records; this._speak(rr ? (REC1 + rr.length + REC2) : RECNONE); },
  nextTap() { this._recompute(); },
  prevTap() { this._recompute(); },
  speakTap() { this.primaryTap(); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'ekiben-erabi', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">記録</div>
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
      <button class="btn main" bindtap="primaryTap">音声案内</button>
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
.hubrows .rrow{font-size:11px;line-height:15px;}

.band{background-color:#1a3d1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border:2px dashed rgba(64,255,94,0.8);}
.btn{flex:1;margin-right:8px;background-color:#122812;color:#7dff9e;border:2px solid rgba(64,255,94,0.6);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#2a6b2a;color:#7dff9e;font-weight:bold;}
</style>
