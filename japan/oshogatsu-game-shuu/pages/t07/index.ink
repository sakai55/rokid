<script def>
{
  "title": "お年玉計算"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "oshogatsuGameShuuV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const QS = [{"q": "1000円と500円はいくら？", "ans": 1500}, {"q": "2000円と300円はいくら？", "ans": 2300}, {"q": "500円と500円と100円はいくら？", "ans": 1100}, {"q": "3000円と700円はいくら？", "ans": 3700}];
const GUIDE = "100円単位で値を合わせて確定する ・ 4問で結果が出る";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._round = 0; this._score = 0; this._val = 0; this._done = false; this._recompute(); },
  _recompute() { var d = {}; d.status = 'お年玉計算の計算'; var q = QS[Math.min(this._round, QS.length - 1)]; d.r0 = '問題: ' + q.q; d.r1 = '現在の値: ' + this._val + '円'; d.r2 = '第' + (this._round + 1) + '問 / 全' + QS.length + '問 ・ 現在 ' + this._score + '点'; d.big = this._done ? ('結果 ' + this._score + '点') : (this._val + '円'); d.detail = this._done ? ('全' + QS.length + '問で' + this._score + '点でした。記録に残しました。') : '100円単位で値を合わせて確定する'; d.guide = GUIDE; d.evt = 'EVT: ' + this._round + '/' + QS.length + ' score ' + this._score; this.setData(d); },
  upTap() { if (this._done) return; this._val += 100; this._recompute(); },
  downTap() { if (this._done) return; if (this._val >= 100) this._val -= 100; this._recompute(); },
  confirmTap() { if (this._done) { this._speak('もう終わっています。'); this._recompute(); return; } var q = QS[this._round]; if (this._val === q.ans) { this._score++; this._speak('正解です。'); } else { this._speak('はずれです。正解は' + q.ans + '円です。'); } this._round++; this._val = 0; if (this._round >= QS.length) { this._done = true; this._finish('お年玉計算', this._score + '点', this._score, this._score + '点'); this._speak('結果は' + this._score + '点です。'); } this._recompute(); },
  primaryTap() { this.confirmTap(); },
  nextTap() { this.upTap(); },
  prevTap() { this.downTap(); },
  speakTap() { var q = QS[Math.min(this._round, QS.length - 1)]; this._speak(q.q + 'です。'); },
  backTap() { this._back(); },

  _saveBest(score, text) { var st = this._load(); if (!st.best) st.best = {}; var old = st.best[String(this._sel)]; var oldN = (old === undefined || old === null) ? -1 : parseInt(old, 10); if (isNaN(oldN)) oldN = -1; if (score > oldN) { st.best[String(this._sel)] = text; this._save(st); } },
  _finish(kind, item, score, text) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: kind, item: item, at: new Date().toISOString() }); this._save(st); this._saveBest(score, text); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'oshogatsu-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">お年玉計算</div>
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
      <button class="btn main" bindtap="upTap">100円増やす</button>
      <button class="btn" bindtap="downTap">100円減らす</button>
      <button class="btn" bindtap="confirmTap">確定</button>
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
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:9px 12px;border:2px solid #40ff5e;border-radius:24px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:24px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
