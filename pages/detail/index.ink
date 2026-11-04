<script def>
{
  "title": "자갈치 안내"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "jagalchiGuideV1";
const SLUG = "jagalchi-guide";
const STALLS = [["활어회 코너", ["오늘 회 확인하기", "손님 수 확인하기", "포장 여부 확인하기", "계산 확인하기"]], ["건어물 코너", ["멸치 상태 확인하기", "김 상태 확인하기", "포장 단위 확인하기", "계산 확인하기"]], ["젓갈 코너", ["젓갈 종류 확인하기", "맛보기 확인하기", "용기 확인하기", "계산 확인하기"]], ["조개구이 코너", ["조개 종류 확인하기", "숯불 상태 확인하기", "자리 확인하기", "계산 확인하기"]], ["포장마차 코너", ["메뉴 확인하기", "매운 정도 확인하기", "포장 여부 확인하기", "계산 확인하기"]], ["기념품 코너", ["선물 목록 확인하기", "포장 여부 확인하기", "배송 여부 확인하기", "계산 확인하기"]]];
const DEF = {"selected": 0, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._n = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _stall() { var st = this._load(); var s = (typeof st.selected === 'number') ? st.selected : 0; return STALLS[s]; },
  _recompute() { var stl = this._stall(); var d = {}; d.status = "끄덕임으로 다음 확인 항목을 마친다"; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i < this._n ? 'done ' : (i === this._n ? '> ' : '- ')) + stl[1][i]); } d.r4 = ''; d.r5 = ''; d.big = stl[0] + ' ' + this._n + ' / 4'; d.detail = "코너 확인 4개"; d.guide = "끄덕임으로 확인·모두 마치면 마침을 누른다"; d.evt = 'EVT: check ' + this._n; this.setData(d); },
  primaryTap() { var stl = this._stall(); if (this._n < 4) { this._speak(stl[1][this._n]); this._n++; } else { this._speak("모두 확인했다."); } this._recompute(); },
  finishTap() { if (this._n < 4) { this._speak("아직 확인 항목이 남았다."); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: "시장 확인", item: this._stall()[0], at: new Date().toISOString() }); this._save(st); this._speak("코너 확인 기록을 남겼다."); this._nav('/pages/record/index'); },
  nextTap() { this.primaryTap(); },
  prevTap() { if (this._n > 0) this._n--; this._recompute(); },
  speakTap() { var stl = this._stall(); this._speak(stl[0]); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: SLUG, version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); }

};

</script>

<template>
  <div class="page">
    <div class="band">자갈치 안내</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">다음 확인</button><button class="btn" bindtap="finishTap">마침</button><button class="btn" bindtap="backTap">돌아가기</button><button class="btn" bindtap="speakTap">읽어주기</button>
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
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:16px;font-size:13px;padding:7px 0;text-align:center;}
</style>
