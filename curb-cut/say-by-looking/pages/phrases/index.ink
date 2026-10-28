<script def>
{
  "title": "选句代说"
}
</script>

<script setup>
import wx from 'wx';

// CC16 say-by-looking - phrases
const KEY = "sayByLookingV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const SCENES = [{"name": "买药", "phrases": ["我要买感冒药。", "请问这个药怎么吃？", "我对青霉素过敏。", "请帮我拿一盒。"]}, {"name": "问路", "phrases": ["请问地铁站在哪里？", "请问这条路怎么走？", "请帮我指一下方向。", "谢谢，我知道了。"]}, {"name": "点餐", "phrases": ["我要一碗牛肉面。", "不要辣，谢谢。", "请帮我打包。", "请问多少钱？"]}, {"name": "买票", "phrases": ["我要一张去市中心的票。", "请问下一班车几点？", "我要靠窗的位置。", "谢谢。"]}, {"name": "找厕所", "phrases": ["请问厕所在哪里？", "请问最近的厕所在哪里？", "谢谢。", "我先去一下厕所。"]}, {"name": "求助", "phrases": ["请帮帮我。", "我说话不太方便。", "请帮我叫一下工作人员。", "谢谢你的帮助。"]}];
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
const PSTATUS = "选一句，让眼镜替你说出来";
const GUIDE = "换一句选候选 ・ 主确认就是代说 ・ 说完记一条记录";
const REC_KIND = "代说记录";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; this._phrases = SCENES[this._sel].phrases; this._idx = 0; this._recompute(); },
  _recompute() { var d = {}; d.status = PSTATUS; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + this._phrases[i]); } d.big = SCENES[this._sel].name; d.detail = PHRASEDETAIL; d.guide = GUIDE; d.evt = 'EVT: ' + SCENES[this._sel].name; this.setData(d); },
  primaryTap() { var ph = this._phrases[this._idx]; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: ph, at: new Date().toISOString() }); this._save(st); this._speak(ph); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % 4; this._recompute(); },
  prevTap() { this._idx = (this._idx + 3) % 4; this._recompute(); },
  speakTap() { this._speak(this._phrases[this._idx]); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'say-by-looking', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">选句代说</div>
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
      <button class="btn main" bindtap="primaryTap">替我说这句</button>
      <button class="btn" bindtap="nextTap">下一个</button>
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

.band{background-color:#1a3d1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border:2px dashed rgba(64,255,94,0.8);}
.btn{flex:1;margin-right:8px;background-color:#122812;color:#7dff9e;border:2px solid rgba(64,255,94,0.6);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#2a6b2a;color:#7dff9e;font-weight:bold;}
</style>
