<script def>
{
  "title": "투호 기록"
}
</script>

<script setup>
import wx from 'wx';

// KR21 tuho-game - record: recent games and best score
const KEY = "tuhoGameV1";
const DEF = {"best": 0, "games": []};
const STATUS = "최근 게임과 최고 점수를 확인합니다";
const GUIDE = "던지기 판정은 화면 속 시범 점수이고 실제 화살을 인식하지 않습니다";

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var games = (st.games || []).slice(-6); var d = {}; d.status = STATUS; d.big = '최고 점수 ' + (st.best || 0) + '점'; var i; for (i = 0; i < 6; i++) { d['r' + i] = (i < games.length) ? (((i === this._idx) ? '▶ ' : '· ') + games[i].score + '점 · ' + games[i].at.slice(0, 16)) : '· —'; } d.detail = '저장된 게임 ' + (st.games ? st.games.length : 0) + '회'; d.guide = GUIDE; d.evt = 'EVT: ' + (st.games ? st.games.length : 0) + ' games'; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % 6; this._recompute(); },
  prevTap() { this._idx = (this._idx + 5) % 6; this._recompute(); },
  primaryTap() { this.speakTap(); },
  speakTap() { var st = this._load(); var games = (st.games || []).slice(-6); var t = games.length ? ('최근 게임은 ' + games[this._idx % games.length].score + '점입니다') : '저장된 게임이 없습니다'; this._speak(t + ' · 최고 점수는 ' + (st.best || 0) + '점입니다'); },
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
    <div class="band">투호 기록</div>
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
      <button class="btn main" bindtap="speakTap">음성 안내</button>
      <button class="btn" bindtap="nextTap">다음 기록</button>
      <button class="btn" bindtap="prevTap">이전 기록</button>
      <button class="btn" bindtap="backTap">돌아가기</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:26px;font-weight:bold;margin-top:8px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:8px;}
.rrow{color:#7dff9e;font-size:14px;line-height:21px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:12px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:8px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3b22;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0d3b22;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:15px;padding:10px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
