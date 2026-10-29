<script def>
{
  "title": "开口提示卡"
}
</script>

<script setup>
import wx from 'wx';

// CC18 speak-up-cue - index: scene cue cards
const KEY = "speakUpCueV1";
const DEF = {"selected": 0, "ratings": [], "heard": 0, "total": 0, "logs": []};
const SCENES = [
  {"name": "家里", "cue": "慢一点, 让家人听清每个字"},
  {"name": "办公室", "cue": "大声一点, 盖过空调声"},
  {"name": "餐厅", "cue": "面向对方, 别对着桌子说话"},
  {"name": "医院", "cue": "慢一点, 把症状说清楚"},
  {"name": "教室", "cue": "大声一点, 让后排也听见"},
  {"name": "电话", "cue": "对着话筒, 语速放慢"}
];
const STATUS = "开口前先看提示卡, 说话不再被淹没";
const GUIDE = "本机不测量声压、不测分贝——听清率来自对话后本人确认, 不是仪器测量";
function RATEFN(st) { if (!st.total) return "还没有对话确认记录"; return "对话 " + st.total + " 次 · 听清 " + st.heard + " 次 · 听清率 " + Math.round(st.heard * 100 / st.total) + "%"; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < SCENES.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + SCENES[i].name + ' — ' + SCENES[i].cue); } d.big = SCENES[this._idx].cue; d.detail = SCENES[this._idx].name + '场面 · ' + RATEFN(st) + ' · 跟读自评 ' + st.ratings.length + ' 条'; d.guide = GUIDE; d.evt = 'EVT: ' + SCENES[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % SCENES.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + SCENES.length - 1) % SCENES.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  sub0Tap() { this._saveSel(); this._nav('/pages/check/index'); },
  sub1Tap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.sub0Tap(); },
  speakTap() { this._speak(SCENES[this._idx].name + '场面, 提示: ' + SCENES[this._idx].cue); },
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
    <div class="band">开口提示卡</div>
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
      <button class="btn main" bindtap="sub0Tap">跟读练习</button>
      <button class="btn" bindtap="sub1Tap">对话记录</button>
      <button class="btn" bindtap="nextTap">下一场面</button>
      <button class="btn" bindtap="speakTap">语音提示</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:22px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:6px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
