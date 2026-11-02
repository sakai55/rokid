<script def>
{
  "title": "年夜饭菜名问答"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaFestivalGameShuuV1";
const DEF = {"selected": 0, "best": {}, "records": []};
const QS = [{"q": "哪道菜寓意年年有余", "opts": ["红烧肉", "清蒸鱼", "白灼虾", "炖鸡"], "ans": 1, "why": "鱼谐音余，清蒸鱼寓意年年有余。"}, {"q": "哪道菜寓意步步高升", "opts": ["饺子", "年糕", "汤圆", "春卷"], "ans": 1, "why": "年糕谐音年高，步步高升。"}, {"q": "除夕必吃、形如元宝的是", "opts": ["馒头", "饺子", "包子", "花卷"], "ans": 1, "why": "饺子形如元宝，除夕必吃。"}, {"q": "哪道菜象征红红火火", "opts": ["凉拌黄瓜", "红烧肉", "清炒时蔬", "紫菜蛋汤"], "ans": 1, "why": "红烧肉色泽红亮，红红火火。"}];
const KIND = "年夜饭菜名问答";
const STATUS = "点头确认答案 · 上下换选项";
const GUIDE = "点头确认答案，答完记分并保存最佳纪录";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._qi = 0; this._score = 0; this._opt = 0; this._done = false; this._lastWhy = ''; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; if (this._done) { d.big = '完成：' + this._score + '/' + QS.length; d.detail = '答对 ' + this._score + ' 题，共 ' + QS.length + ' 题，已记入记录。'; for (var i = 0; i < 4; i++) d['r' + i] = '· ' + QS[0].opts[i]; } else { var q = QS[this._qi]; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._opt ? '▶ ' : '· ') + q.opts[i]); } d.big = q.q; d.detail = (this._lastWhy ? this._lastWhy : ('第' + (this._qi + 1) + '题，共 ' + QS.length + ' 题 · 已对 ' + this._score + ' 题')); } d.guide = GUIDE; d.evt = 'EVT: ' + this._qi + '/' + QS.length + ' score ' + this._score; this.setData(d); },
  primaryTap() { if (this._done) { this._back(); return; } var q = QS[this._qi]; if (this._opt === q.ans) { this._score++; this._speak('答对了。' + q.why); } else { this._speak('不对。' + q.why); } this._lastWhy = q.why; this._qi++; this._opt = 0; if (this._qi >= QS.length) { this._done = true; this._finish(KIND, KIND + this._score + '/' + QS.length, this._score, this._score + '/' + QS.length); this._speak('完成。答对 ' + this._score + ' 题。'); } this._recompute(); },
  nextTap() { if (this._done) return; this._opt = (this._opt + 1) % 4; this._recompute(); },
  prevTap() { if (this._done) return; this._opt = (this._opt + 3) % 4; this._recompute(); },
  speakTap() { if (this._done) this._speak('完成。'); else this._speak(QS[this._qi].q + ' ' + QS[this._qi].opts[this._opt] + '。'); },
  backTap() { this._back(); },

  _saveBest(score, text) { var st = this._load(); if (!st.best) st.best = {}; var old = st.best[String(this._sel)]; var oldN = (old === undefined || old === null) ? -1 : parseInt(old, 10); if (isNaN(oldN)) oldN = -1; if (score > oldN) { st.best[String(this._sel)] = text; this._save(st); } },
  _finish(kind, item, score, text) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: kind, item: item, at: new Date().toISOString() }); this._save(st); this._saveBest(score, text); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'china-festival-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">年夜饭菜名问答</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">返回</button>
      <button class="btn main" bindtap="primaryTap">确认答案</button>
      <button class="btn" bindtap="nextTap">换选项</button>
      <button class="btn" bindtap="speakTap">语音</button>
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
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:292px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:9px 12px;border:2px solid #40ff5e;border-radius:24px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:24px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
