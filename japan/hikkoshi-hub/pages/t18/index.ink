<script def>
{
  "title": "当日タイムライン"
}
</script>

<script setup>
import wx from 'wx';

// JP37 hikkoshi-hub - 当日タイムライン
const KEY = "hikkoshiHubV1";
const SLUGID = "t18";
const DEF = {"selected": 0, "tools": {}, "records": [], "calc": null, "compare": null};
const ITEMS = ["7:00 起床と最終確認", "8:00 業者の到着", "9:00 荷物の搬出開始", "11:00 旧居の掃除", "12:00 昼食と休憩", "13:00 新居へ移動", "14:00 荷物の搬入", "16:00 搬入完了の確認"];
const STATUS = "当日タイムライン：8つの時間帯を順番に進めます";
const GUIDE = "次へで次の時間帯へ ・ 最後で完了 ・ 保存で手帳に記録 ・ うなずきは次へ";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); var t = st.tools ? st.tools[SLUGID] : null; this._slot = (t && t.step) ? t.step : 0; if (this._slot >= ITEMS.length) this._slot = ITEMS.length - 1; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var d = {}; d.status = STATUS; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._slot ? '▶ ' : (i < this._slot ? '済 ' : '未 ')) + ITEMS[i]); } d.big = ITEMS[this._slot]; d.detail = '時間帯 ' + (this._slot + 1) + '/8番目です。'; d.guide = GUIDE; d.evt = 'EVT: ' + ITEMS[this._slot]; this.setData(d); },
  primaryTap() { if (this._slot < ITEMS.length - 1) { this._slot++; this._saveProgress(); } else { this._saveProgress(); this._speak('当日の流れが完了しました。'); } this._recompute(); },
  _saveProgress() { var st = this._load(); if (!st.tools) st.tools = {}; var done = (this._slot === ITEMS.length - 1) ? ITEMS.length : this._slot + 1; st.tools[SLUGID] = { done: done, total: ITEMS.length, step: this._slot }; this._save(st); },
  saveTap() { this._saveProgress(); var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: "当日タイムライン", done: st.tools[SLUGID].done, total: ITEMS.length, at: new Date().toISOString() }); this._save(st); this._speak('保存しました。'); this._recompute(); },
  nextTap() { this.primaryTap(); },
  prevTap() { if (this._slot > 0) { this._slot--; this._saveProgress(); } this._recompute(); },
  speakTap() { this._speak(ITEMS[this._slot] + 'です。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'hikkoshi-hub', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">当日タイムライン</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    <div class="rrow">{{ r6 }}</div>
    <div class="rrow">{{ r7 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="prevTap">前へ</button>
      <button class="btn main" bindtap="primaryTap">次へ・完了</button>
      <button class="btn" bindtap="saveTap">保存</button>
    </div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">もどる</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:12px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
.rrow{border-left:6px solid #40ff5e;padding-left:8px;line-height:19px;font-size:13px;}
</style>
