<script def>
{
  "title": "逐词显示"
}
</script>

<script setup>
import wx from 'wx';

// CC17 first-sentence - words
const KEY = "firstSentenceV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const SCENES = [{"name": "点餐", "words": ["您好，", "我要", "一碗", "牛肉面，", "谢谢。"]}, {"name": "自我介绍", "words": ["您好，", "我叫", "小林，", "很高兴", "认识您。"]}, {"name": "打电话", "words": ["您好，", "我是", "小林，", "想问", "一件事。"]}, {"name": "问路", "words": ["请问，", "地铁站", "怎么走？", "谢谢您。"]}, {"name": "面试开场", "words": ["您好，", "我是", "今天的", "应聘者，", "请多指教。"]}, {"name": "道歉", "words": ["对不起，", "是我", "来晚了，", "请原谅。"]}];
const NOWTXT = "当前：";
const CHOOSETXT = "选好后按确定作答";
const CORRECTTXT = "答对了。";
const WRONG1 = "不对。答案是";
const WRONG2 = "。";
const QEND = "。";
const QSEP = "、";
const GOALTXT = " · 已达目标";
const CNT1 = "、当前";
const CNT2 = "、目标是";
const CNT3 = "。";
const REC1 = "记录共";
const REC2 = "条。";
const RECNONE = "还没有记录。";
const PHRASEDETAIL = "选中的句子将由语音替你说出来。";
const WORDLAST = "最后一个词了，说完请按完成。";
const WORDNEXT = "点头一次，进下一个词。";
const WORDDONE = "说完了。";
const LINELAST = "最后一行了，读完请按完成。";
const LINENEXT = "点头一次，进下一行。";
const LINEDONE = "读完了。";
const WSTATUS = "第一句话：第 {i} / {t} 个词";
const GUIDE = "点头进下一个词 ・ 可回上一个词 ・ 说完记一条记录";
const REC_KIND = "说完记录";
const WMAX = 5;

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._words = SCENES[this._sel].words; this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = WSTATUS.replace('{i}', (this._idx + 1)).replace('{t}', this._words.length); var i; for (i = 0; i < this._words.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + this._words[i]); } for (i = this._words.length; i < WMAX; i++) { d['r' + i] = ''; } d.big = this._words[this._idx]; d.detail = SCENES[this._sel].name + ' ・ ' + (this._idx >= this._words.length - 1 ? WORDLAST : WORDNEXT); d.guide = GUIDE; d.evt = 'EVT: word ' + (this._idx + 1) + '/' + this._words.length; this.setData(d); },
  primaryTap() { if (this._idx < this._words.length - 1) { this._idx++; this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: SCENES[this._sel].name, at: new Date().toISOString() }); this._save(st); this._speak(WORDDONE); this._recompute(); },
  nextTap() { if (this._idx < this._words.length - 1) this._idx++; this._recompute(); },
  prevTap() { if (this._idx > 0) this._idx--; this._recompute(); },
  speakTap() { this._speak(this._words[this._idx]); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'first-sentence', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">逐词显示</div>
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
      <button class="btn" bindtap="backTap">返回</button>
      <button class="btn main" bindtap="primaryTap">下一个词</button>
      <button class="btn" bindtap="prevTap">上一个</button>
      <button class="btn" bindtap="speakTap">语音播报</button>
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

.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
