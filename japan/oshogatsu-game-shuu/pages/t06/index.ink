<script def>
{
  "title": "餅つきリズム"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "oshogatsuGameShuuV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const ITEMS = ["ドン", "ペッタン", "ドン", "ペッタン", "ドン", "ペッタン"];
const GUIDE = "ドンとペッタンの拍を順に打つ ・ 6拍で完成";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._step = 0; this._miss = 0; this._done = false; this._recompute(); },
  _recompute() { var d = {}; d.status = '餅つきリズムのリズム'; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._step && !this._done) ? '▶ ' : '・ ') + ITEMS[i] + ((i < this._step) ? ' 済み' : ''); } d.big = this._done ? '完成！' : ITEMS[this._step]; d.detail = this._done ? ('リズムを打ち終えました。ミス' + this._miss + '回でした。記録に残しました。') : ('いま打つ拍: ' + ITEMS[this._step] + ' ・ ミス: ' + this._miss + '回です'); d.guide = GUIDE; d.evt = 'EVT: ' + this._step + '/' + ITEMS.length + ' miss ' + this._miss; this.setData(d); },
  _tap(label) { if (this._done) { this._speak('もう打ち終えました。'); this._recompute(); return; } if (label === ITEMS[this._step]) { this._step++; this._speak(label + '、いい拍です。'); if (this._step >= ITEMS.length) { this._done = true; this._finish('餅つきリズム', '完成（ミス' + this._miss + '回）', 100, '達成'); this._speak('リズムが完成しました。'); } } else { this._miss++; this._speak('拍が違います。いまの拍は' + ITEMS[this._step] + 'です。'); } this._recompute(); },
  donTap() { this._tap('ドン'); },
  pettanTap() { this._tap('ペッタン'); },
  primaryTap() { this.donTap(); },
  nextTap() { this._recompute(); },
  prevTap() { this._recompute(); },
  speakTap() { this._speak(ITEMS[Math.min(this._step, ITEMS.length - 1)] + 'です。'); },
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
    <div class="band">餅つきリズム</div>
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
      <button class="btn main" bindtap="donTap">ドン</button>
      <button class="btn" bindtap="pettanTap">ペッタン</button>
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
