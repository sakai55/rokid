<script def>
{
  "title": "獅子舞ステップ"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "oshogatsuGameShuuV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const SEQ = ["前進", "横歩き", "回る", "前進", "止まる"];
const OPTS = ["前進", "横歩き", "回る", "止まる"];
const GUIDE = "手順を覚えてから同じ順に再現する ・ 間違えたら最初から";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._phase = 0; this._pos = 0; this._opt = 0; this._done = false; this._recompute(); },
  _recompute() { var d = {}; d.status = '獅子舞ステップの手順'; var i; for (i = 0; i < SEQ.length; i++) { d['r' + i] = ((this._phase === 1 && i === this._pos && !this._done) ? '▶ ' : '・ ') + SEQ[i] + ((this._phase === 1 && i < this._pos) ? ' 済み' : ''); } if (this._done) { d.big = '完成！'; d.detail = '手順をすべて再現しました。記録に残しました。'; } else if (this._phase === 0) { d.big = '覚えてください'; d.detail = '上の手順を覚えたら、うなずきで再現を始める'; } else { d.big = OPTS[this._opt]; d.detail = '再現中: ' + (this._pos + 1) + '手目 ・ 選んでいる動作: ' + OPTS[this._opt] + ' です'; } d.guide = GUIDE; d.evt = 'EVT: phase ' + this._phase + ' pos ' + this._pos; this.setData(d); },
  primaryTap() { if (this._done) { this._speak('もう完成しています。'); this._recompute(); return; } if (this._phase === 0) { this._phase = 1; this._pos = 0; this._opt = 0; this._speak('再現を始めます。'); this._recompute(); return; } if (OPTS[this._opt] === SEQ[this._pos]) { this._pos++; this._speak('正しい動作です。'); if (this._pos >= SEQ.length) { this._done = true; this._finish('獅子舞ステップ', '手順再現完成', 100, '達成'); this._speak('手順をすべて再現しました。'); } } else { this._pos = 0; this._speak('違います。最初からやり直します。'); } this._recompute(); },
  nextTap() { if (this._phase === 1) this._opt = (this._opt + 1) % OPTS.length; this._recompute(); },
  prevTap() { if (this._phase === 1) this._opt = (this._opt + OPTS.length - 1) % OPTS.length; this._recompute(); },
  speakTap() { if (this._phase === 0) this._speak(SEQ.join('、') + 'です。'); else this._speak(OPTS[this._opt] + 'です。'); },
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
    <div class="band">獅子舞ステップ</div>
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
      <button class="btn main" bindtap="primaryTap">決める</button>
      <button class="btn" bindtap="nextTap">選択を変える</button>
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
