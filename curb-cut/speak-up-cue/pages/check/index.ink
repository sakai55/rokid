<script def>
{
  "title": "跟读练习"
}
</script>

<script setup>
import wx from 'wx';

// CC18 speak-up-cue - check: model sentence practice with self-rating
const KEY = "speakUpCueV1";
const DEF = {"selected": 0, "ratings": [], "heard": 0, "total": 0, "logs": []};
const SENTENCES = ["请帮我倒一杯水, 谢谢。", "我想预约明天下午三点。", "请问去火车站怎么走?", "这件衣服有没有大一号的?", "麻烦您说慢一点, 我没听清。", "今天天气真好, 适合出去走走。"];
const STATUS = "听示范句, 跟读一遍, 给自己评一声量";
const GUIDE = "本机不测量声压、不测分贝——自评来自本人感受, 不是仪器测量";
function LASTFN(st) { if (!st.ratings.length) return "还没有自评"; var r = st.ratings[st.ratings.length - 1]; return "上次自评: " + r.rate + " · 已评 " + st.ratings.length + " 条"; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected % SENTENCES.length : 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < SENTENCES.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + SENTENCES[i]); } d.big = SENTENCES[this._idx]; d.detail = LASTFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + (this._idx + 1) + ' / ' + SENTENCES.length; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % SENTENCES.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + SENTENCES.length - 1) % SENTENCES.length; this._recompute(); },
  _rate(rate) { var st = this._load(); if (!st.ratings) st.ratings = []; st.ratings.push({ sentence: SENTENCES[this._idx], rate: rate, at: new Date().toISOString() }); this._save(st); this._speak('已记下: ' + rate); this._recompute(); },
  rateBigTap() { this._rate('大'); },
  rateOkTap() { this._rate('正好'); },
  rateSmallTap() { this._rate('小'); },
  primaryTap() { this.speakTap(); },
  speakTap() { this._speak(SENTENCES[this._idx]); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._fail('E5002', 'storage read'); } return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'speak-up-cue', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">跟读练习</div>
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
      <button class="btn main" bindtap="speakTap">听示范</button>
      <button class="btn" bindtap="rateBigTap">大</button>
      <button class="btn" bindtap="rateOkTap">正好</button>
      <button class="btn" bindtap="rateSmallTap">小</button>
      <button class="btn" bindtap="nextTap">下一句</button>
      <button class="btn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:13px;line-height:19px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
