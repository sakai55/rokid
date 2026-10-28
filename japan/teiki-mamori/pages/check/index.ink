<script def>
{
  "title": "忘れ物チェック"
}
</script>

<script setup>
import wx from 'wx';

// JP28 teiki-mamori - check
const KEY = "teikiMamoriV1";
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
const ITEMS2 = ["財布", "定期券", "スマートフォン", "鍵", "ハンカチ", "水筒"];
const CHECKSTATUS = "持ち物チェック: {n} / {t} 点確認済み";
const ALLDONE = "持ち物は全部そろいました。";
const GUIDE = "NEXTで定期を変える ・ 忘れ物チェックで確認 ・ うなずきは主確認";
const REC_KIND = "持ち物チェック完了";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._items = (ITEMS2); var arr = (st.checked && st.checked[String(this._sel)]) || []; var self = this; this._marks = this._items.map(function (_, i) { return !!arr[i]; }); this._idx = 0; this._recompute(); },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = CHECKSTATUS.replace('{n}', done).replace('{t}', this._items.length); for (i = 0; i < this._items.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._marks[i] ? '☑ ' : '☐ ') + this._items[i]); } d.big = this._items[this._idx]; d.detail = (done >= this._items.length) ? ALLDONE : (NOWTXT + this._items[this._idx]); d.guide = GUIDE; d.evt = 'EVT: ' + done + '/' + this._items.length; this.setData(d); },
  _persist() { var st = this._load(); if (!st.checked) st.checked = {}; st.checked[String(this._sel)] = this._marks.slice(); this._save(st); },
  checkTap() { this._marks[this._idx] = !this._marks[this._idx]; this._persist(); var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; if (done >= this._items.length) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, at: new Date().toISOString() }); this._save(st); this._speak(ALLDONE); } else { this._speak(this._items[this._idx]); } this._recompute(); },
  primaryTap() { this.checkTap(); },
  nextTap() { this._idx = (this._idx + 1) % this._items.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + this._items.length - 1) % this._items.length; this._recompute(); },
  speakTap() { this._speak(this._items[this._idx]); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'teiki-mamori', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">忘れ物チェック</div>
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
.big{color:#7dff9e;font-size:24px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.hubrows .rrow{font-size:11px;line-height:15px;}

.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;letter-spacing:2px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
