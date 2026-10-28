<script def>
{
  "title": "공원 산책"
}
</script>

<script setup>
import wx from 'wx';

// KR19 seoul-life-hub - t11
const KEY = "seoulLifeHubV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const ITEMS = [{"name": "산책 코스 걷기", "target": 5, "unit": "곳"}];
const NOWTXT = "지금: ";
const CHOOSETXT = "골라서 결정으로 답하기";
const CORRECTTXT = "맞았습니다.";
const WRONG1 = "틀렸습니다. 답은 ";
const WRONG2 = "입니다.";
const QEND = ".";
const QSEP = ", ";
const GOALTXT = " · 목표 달성";
const CNT1 = ", 지금 ";
const CNT2 = ", 목표는 ";
const CNT3 = "입니다.";
const REC1 = "기록은 ";
const REC2 = "건입니다.";
const RECNONE = "기록이 아직 없습니다.";
const PHRASEDETAIL = "고른 문장을 음성으로 대신 말합니다.";
const WORDLAST = "마지막 단어입니다. 다 말했으면 완료를 누르세요.";
const WORDNEXT = "고개를 끄덕일 때마다 다음 단어로 넘어갑니다.";
const WORDDONE = "다 말했습니다.";
const LINELAST = "마지막 줄입니다.";
const LINENEXT = "고개를 끄덕일 때마다 다음 줄로 넘어갑니다.";
const LINEDONE = "다 읽었습니다.";
const TARGETTXT = " 목표 ";
const CSTATUS = "생활 도구: 세어 목표까지";
const GUIDE = "다음으로 도구를 바꾸기 · 열기로 쓰기 · 고개 끄덕임은 주 확인";
const REC_KIND = "생활 기록";

export default {
  data: { status: '', big: '', r0: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = 0; this._count = 0; this._recompute(); },
  _recompute() { var it = ITEMS[this._idx]; var d = {}; d.status = CSTATUS; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + ITEMS[i].name + TARGETTXT + ITEMS[i].target + ITEMS[i].unit); } d.big = this._count + ' / ' + it.target + ' ' + it.unit; d.detail = NOWTXT + it.name + (this._count >= it.target ? GOALTXT : ''); d.guide = GUIDE; d.evt = 'EVT: ' + it.name + ' ' + this._count + '/' + it.target; this.setData(d); },
  primaryTap() { var it = ITEMS[this._idx]; this._count++; if (this._count >= it.target) { var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: REC_KIND, item: it.name, count: this._count, at: new Date().toISOString() }); this._save(st); this._speak(it.name + GOALTXT + QEND); } this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % ITEMS.length; this._count = 0; this._recompute(); },
  prevTap() { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._count = 0; this._recompute(); },
  speakTap() { var it = ITEMS[this._idx]; this._speak(it.name + CNT1 + this._count + CNT2 + it.target + CNT3); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'seoul-life-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">공원 산책</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">돌아가기</button>
      <button class="btn main" bindtap="primaryTap">세기</button>
      <button class="btn" bindtap="nextTap">다음</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
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

.band{background-color:#0d3d17;color:#7dff9e;font-size:20px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;letter-spacing:2px;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);font-size:14px;padding:7px 0;text-align:center;}
.btn.main{background-color:#14541f;color:#7dff9e;font-weight:bold;}
</style>
