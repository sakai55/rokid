<script def>
{
  "title": "初詣の参拝手順"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "hatsumodeStepsV1";
const SLUG = "hatsumode-steps";
const STAGES = ["参道に入る", "手水舎", "参拝", "賽銭と鈴", "お守りと絵馬", "帰りの確認"];
const STEPS = [["鳥居の前で一礼する", "参道の端を歩く", "境内の案内板を確認する", "本殿の方角を確認する"], ["ひしゃくを右手で取る", "左手を清める", "右手を清める", "口をすすいでひしゃくを立てる"], ["本殿の前に立つ", "深く二礼する", "二回拍手する", "最後に一礼する"], ["お賽銭を用意する", "賽銭をそっと入れる", "鈴の緒を静かに引く", "鈴の音を聞いて手を合わせる"], ["授与所でお守りを選ぶ", "お守りを受け取る", "絵馬に願いを書く", "絵馬を掛ける"], ["お守りと絵馬を確認する", "帰りの参道を確かめる", "鳥居の前で一礼する", "参拝を終えたことを確かめる"]];
const DEF = {"selected": 0, "checks": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._n = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _stage() { var st = this._load(); var s = (typeof st.selected === 'number') ? st.selected : 0; return STAGES[s]; },
  _recompute() { var rm = this._stage(); var st = this._load(); var s = (typeof st.selected === 'number') ? st.selected : 0; var d = {}; d.status = "うなずきで一歩ずつ進む"; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i < this._n ? '済 ' : (i === this._n ? '▶ ' : '· ')) + STEPS[s][i]); } d.r4 = '段階：' + rm; d.r5 = (this._n >= 4) ? "4歩とも終えた" : ("次：" + STEPS[s][this._n]); d.big = rm + ' ' + this._n + ' / 4'; d.detail = "参拝はうなずきで進みます。"; d.guide = "うなずく＝次の一歩へ進む · 4歩終えたら「参拝記録」"; d.evt = 'EVT: step ' + this._n; this.setData(d); },
  primaryTap() { var st = this._load(); var s = (typeof st.selected === 'number') ? st.selected : 0; if (this._n < 4) { this._speak(STEPS[s][this._n]); this._n++; } else { this._speak("4歩とも終えました。"); } this._recompute(); },
  finishTap() { if (this._n < 4) { this._speak("まだ終えていない歩があります。"); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: "初詣参拝", item: this._stage(), at: new Date().toISOString() }); if (!st.checks) st.checks = {}; st.checks[String((typeof st.selected === 'number') ? st.selected : 0)] = 4; this._save(st); this._speak(this._stage() + "参拝を記録しました。"); this._nav('/pages/record/index'); },
  nextTap() { this.primaryTap(); },
  prevTap() { if (this._n > 0) this._n--; this._recompute(); },
  speakTap() { var st = this._load(); var s = (typeof st.selected === 'number') ? st.selected : 0; this._speak(this._stage() + '、' + this._n + ' / 4'); },
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
    <div class="band">初詣の参拝手順</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">進む</button><button class="btn" bindtap="finishTap">参拝記録</button><button class="btn" bindtap="backTap">戻る</button><button class="btn" bindtap="speakTap">音声</button>
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

.band{background-color:#12351f;color:#7dff9e;font-size:18px;font-weight:bold;padding:8px 10px;border:2px dashed #40ff5e;border-radius:8px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#12351f;color:#7dff9e;border:1px dashed #40ff5e;border-radius:8px;font-size:13px;padding:7px 0;text-align:center;}
</style>
