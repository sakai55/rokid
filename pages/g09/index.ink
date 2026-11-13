<script def>
{
  "title": "桜茶の段取り"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "sakuraGameShuuV1";
const SLUG = "sakura-game-shuu";
const GI = 8;
const GNAME = "桜茶の段取り";
const DEF = {"selected": 0, "best": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._step = 0; this._done = false; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var best = (st.best && st.best[String(GI)]) ? st.best[String(GI)] : 0; var d = {}; d.status = "うなずいて遊ぶ・決めると記録が残る"; var i; for (i = 0; i < 5; i++) { d['r' + i] = ((i < this._step ? '済み ' : (i === this._step ? '> ' : '- ')) + ["湯を沸かす", "急須を温める", "茶葉を入れる", "湯を注ぐ", "桜を見ながら飲む"][i]); } d.r5 = "ベスト：" + best; d.big = this._done ? "おわり" : ["湯を沸かす", "急須を温める", "茶葉を入れる", "湯を注ぐ", "桜を見ながら飲む"][this._step]; d.detail = "ベストは次も残る"; d.guide = "うなずくか進めるで数える・次へで決める・戻るで一覧へ"; d.evt = 'EVT: step ' + (this._step + 1); this.setData(d); },
  _settle() { this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: GNAME, item: '5 / 5', at: new Date().toISOString() }); if (!st.best) st.best = {}; if (!st.best[String(GI)] || 5 > st.best[String(GI)]) st.best[String(GI)] = 5; this._save(st); this._speak("おわり。5つの手順がそろいました。"); this._recompute(); },
  actionTap() { if (this._done) { this._nav('/pages/index/index'); return; } if (this._step < 4) { this._step++; this._speak(["湯を沸かす", "急須を温める", "茶葉を入れる", "湯を注ぐ", "桜を見ながら飲む"][this._step]); } else { this._settle(); return; } this._recompute(); },
  secondTap() { if (this._done) { this._nav('/pages/index/index'); return; } if (this._step === 0) { this._speak("まず一つ数えてください。"); this._recompute(); return; } this._settle(); },
  primaryTap() { this.actionTap(); },
  nextTap() { this.actionTap(); },
  prevTap() { if (this._step > 0) this._step--; this._recompute(); },
  speakTap() { this._speak(["湯を沸かす", "急須を温める", "茶葉を入れる", "湯を注ぐ", "桜を見ながら飲む"][this._step]); },
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
    <div class="band">桜茶の段取り</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="actionTap">進める</button><button class="btn" bindtap="secondTap">次へ</button><button class="btn" bindtap="backTap">戻る</button><button class="btn" bindtap="speakTap">読み上げ</button>
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
