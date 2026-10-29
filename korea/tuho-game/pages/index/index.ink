<script def>
{
  "title": "투호 게임"
}
</script>

<script setup>
import wx from 'wx';

// KR21 tuho-game - index: game description and best score
const KEY = "tuhoGameV1";
const DEF = {"best": 0, "games": []};
const STATUS = "모임에서 머리로만 던지는 투호 게임";
const LINES = ["머리 방향으로 왼쪽, 가운데, 오른쪽을 겨냥합니다", "거리는 1m, 2m, 3m이고 점수는 10점, 30점, 50점입니다", "한 게임은 10번 던지기이고 최고 점수가 저장됩니다"];
const GUIDE = "던지기 판정은 화면 속 시범 점수이고 실제 화살을 인식하지 않습니다";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < LINES.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + LINES[i]); } d.big = '최고 점수 ' + (st.best || 0) + '점'; d.detail = '저장된 게임 ' + (st.games ? st.games.length : 0) + '회 · 최고 점수 ' + (st.best || 0) + '점'; d.guide = GUIDE; d.evt = 'EVT: best ' + (st.best || 0); this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % LINES.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + LINES.length - 1) % LINES.length; this._recompute(); },
  sub0Tap() { this._nav('/pages/play/index'); },
  sub1Tap() { this._nav('/pages/record/index'); },
  primaryTap() { this.sub0Tap(); },
  speakTap() { this._speak('투호 게임입니다. ' + LINES.join(' ')); },
  backTap() { this._back(); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._fail('E5002', 'storage read'); } return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'tuho-game', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">투호 게임</div>
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
      <button class="btn main" bindtap="sub0Tap">게임 시작</button>
      <button class="btn" bindtap="sub1Tap">기록 보기</button>
      <button class="btn" bindtap="nextTap">다음 설명</button>
      <button class="btn" bindtap="speakTap">음성 안내</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:26px;font-weight:bold;margin-top:10px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:10px;}
.rrow{color:#7dff9e;font-size:14px;line-height:22px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:8px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:10px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3b22;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0d3b22;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:15px;padding:10px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
