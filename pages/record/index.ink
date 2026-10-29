<script def>
{
  "title": "对话确认记录"
}
</script>

<script setup>
import wx from 'wx';

// CC18 speak-up-cue - record: confirm after each conversation whether heard
const KEY = "speakUpCueV1";
const DEF = {"selected": 0, "ratings": [], "heard": 0, "total": 0, "logs": []};
const STATUS = "每次对话后确认一次: 对方听清了吗";
const GUIDE = "本机不测量声压、不测分贝——听清率来自对话后本人确认, 不是仪器测量";
function RATEFN(st) { if (!st.total) return "还没有对话确认记录"; return "对话 " + st.total + " 次 · 听清 " + st.heard + " 次 · 听清率 " + Math.round(st.heard * 100 / st.total) + "%"; }
function LASTFN(st) { if (!st.logs || !st.logs.length) return "最近记录: 无"; var l = st.logs[st.logs.length - 1]; return "最近一次: " + l.result; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var logs = (st.logs || []).slice(-6); var d = {}; d.status = STATUS; d.big = RATEFN(st); var i; for (i = 0; i < 6; i++) { d['r' + i] = (i < logs.length) ? ('· ' + logs[i].result + ' · ' + logs[i].at.slice(0, 16)) : '· —'; } d.detail = LASTFN(st) + ' · 跟读自评 ' + (st.ratings ? st.ratings.length : 0) + ' 条'; d.guide = GUIDE; d.evt = 'EVT: ' + st.total + ' conversations'; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % 6; this._recompute(); },
  prevTap() { this._idx = (this._idx + 5) % 6; this._recompute(); },
  _confirm(result) { var st = this._load(); if (!st.logs) st.logs = []; st.logs.push({ result: result, at: new Date().toISOString() }); st.total = (st.total || 0) + 1; if (result === '听清') st.heard = (st.heard || 0) + 1; this._save(st); this._speak('已记下: ' + result); this._recompute(); },
  heardTap() { this._confirm('听清'); },
  repeatTap() { this._confirm('重说'); },
  primaryTap() { this.heardTap(); },
  speakTap() { var st = this._load(); this._speak(RATEFN(st)); },
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
    <div class="band">对话确认记录</div>
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
      <button class="btn main" bindtap="heardTap">听清了</button>
      <button class="btn" bindtap="repeatTap">让对方重说</button>
      <button class="btn" bindtap="speakTap">语音播报</button>
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
