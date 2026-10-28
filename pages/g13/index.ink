<script def>
{
  "title": "花火色順"
}
</script>

<script setup>
import wx from 'wx';

// JP32 matsuri-game-shuu - g13
const KEY = "matsuriGameShuuV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const QS = [{"q": "花火の最初の色はどれですか", "opts": ["赤", "青", "緑"], "ans": 0, "explain": "この花火は赤から始まります。"}, {"q": "花火の次の色はどれですか", "opts": ["青", "赤", "黄"], "ans": 0, "explain": "次は青い花火です。"}, {"q": "花火の最後の色はどれですか", "opts": ["金", "赤", "青"], "ans": 0, "explain": "最後は金の花火です。"}];
const __USESTORE__ = false;
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
const ANSSEP = " ・ ";
const ANSLBL = "答え: ";
const QSTATUS = "屋台クイズ: {i} / {t} 問 ・ {s} 点";
const GUIDE = "NEXTでゲームを変える ・ ひらくで遊ぶ ・ うなずきは主確認";
const REC_KIND = "ゲーム記録";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._qi = __USESTORE__ && (typeof st.qi === 'number') ? st.qi : 0; this._oi = 0; this._score = __USESTORE__ && (typeof st.score === 'number') ? st.score : 0; this._done = false; this._recompute(); },
  _recompute() { var q = QS[this._qi]; var d = {}; d.status = QSTATUS.replace('{i}', (this._qi + 1)).replace('{t}', QS.length).replace('{s}', this._score); d.big = q.q; var i; for (i = 0; i < 3; i++) { d['r' + i] = ((i === this._oi ? '▶ ' : '· ') + q.opts[i]); } d.detail = this._done ? (ANSLBL + q.opts[q.ans] + ANSSEP + q.explain) : CHOOSETXT; d.guide = GUIDE; d.evt = 'EVT: Q' + (this._qi + 1) + ' score ' + this._score; this.setData(d); },
  _persist() { var st = this._load(); st.qi = this._qi; st.score = this._score; this._save(st); },
  primaryTap() { var q = QS[this._qi]; if (this._done) { this._qi = (this._qi + 1) % QS.length; this._oi = 0; this._done = false; this._persist(); this._recompute(); return; } this._done = true; if (this._oi === q.ans) { this._score++; this._speak(CORRECTTXT + q.explain); } else { this._speak(WRONG1 + q.opts[q.ans] + WRONG2 + q.explain); } if (this._qi >= QS.length - 1) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, score: this._score, at: new Date().toISOString() }); this._save(st); } this._persist(); this._recompute(); },
  nextTap() { if (!this._done) this._oi = (this._oi + 1) % 3; this._recompute(); },
  prevTap() { if (!this._done) this._oi = (this._oi + 2) % 3; this._recompute(); },
  speakTap() { var q = QS[this._qi]; this._speak(q.q + QEND + q.opts.join(QSEP)); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'matsuri-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">花火色順</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn main" bindtap="primaryTap">決定する</button>
      <button class="btn" bindtap="nextTap">選択肢を変える</button>
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

.band{background-color:#000000;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 0;text-align:center;border-top:2px solid #40ff5e;border-bottom:2px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#000000;color:#40ff5e;border:2px solid #40ff5e;border-radius:50px;font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
