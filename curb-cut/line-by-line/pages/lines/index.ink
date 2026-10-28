<script def>
{
  "title": "逐行读"
}
</script>

<script setup>
import wx from 'wx';

// CC15 line-by-line - lines
const KEY = "lineByLineV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const PASS = [{"name": "出门清单", "lines": ["出门前，先看一眼燃气阀门。", "确认大门已经锁好。", "窗户关上了吗，再看一次。", "手机、钥匙、钱包都在包里。", "水龙头已经拧紧。", "电源插座没有异常发热。", "今天要带的伞在门口。", "好了，可以出门了。"]}, {"name": "菜市场买菜", "lines": ["今天要买青菜和豆腐。", "先去常去的蔬菜摊。", "青菜要新鲜的，不要蔫的。", "豆腐拿一块，不要压碎。", "鸡蛋数一数，一共十个。", "鱼要活的，眼睛要亮。", "水果买三个苹果。", "算一算钱，再付钱。", "小票收好，回家核对。", "菜都买齐了，回家吧。"]}, {"name": "给家人打电话", "lines": ["先想好要说的第一件事。", "问一问家人的身体怎么样。", "说一说自己今天做了什么。", "提醒家人按时吃药。", "约好下次见面的时间。", "不要着急，慢慢说。", "说完了，确认对方听清楚了。", "说一声再见，再挂电话。", "这通电话打完了。"]}];
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
const LSTATUS = "逐行读：第 {i} / {t} 行";
const GUIDE = "点头进下一行 ・ 上一行可回看 ・ 读完记一条记录";
const REC_KIND = "读完记录";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._lines = PASS[this._sel].lines; this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = LSTATUS.replace('{i}', (this._idx + 1)).replace('{t}', this._lines.length); var i; var marks = ''; for (i = 0; i < this._lines.length; i++) { marks += (i < this._idx ? '●' : (i === this._idx ? '▶' : '○')) + ' '; } d.r0 = marks; d.r1 = PASS[this._sel].name; d.r2 = ''; d.big = this._lines[this._idx]; d.detail = (this._idx >= this._lines.length - 1) ? LINELAST : LINENEXT; d.guide = GUIDE; d.evt = 'EVT: line ' + (this._idx + 1) + '/' + this._lines.length; this.setData(d); },
  primaryTap() { if (this._idx < this._lines.length - 1) { this._idx++; this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: PASS[this._sel].name, at: new Date().toISOString() }); this._save(st); this._speak(LINEDONE); this._recompute(); },
  nextTap() { if (this._idx < this._lines.length - 1) this._idx++; this._recompute(); },
  prevTap() { if (this._idx > 0) this._idx--; this._recompute(); },
  speakTap() { this._speak(this._lines[this._idx]); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'line-by-line', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">逐行读</div>
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
      <button class="btn" bindtap="backTap">返回</button>
      <button class="btn main" bindtap="primaryTap">下一行</button>
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

.band{background-color:#0d2b16;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;letter-spacing:1px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:1px solid rgba(64,255,94,0.7);border-radius:4px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
