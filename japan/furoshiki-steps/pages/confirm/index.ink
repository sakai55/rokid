<script def>
{
  "title": "風呂敷の包み方"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "furoshikiStepsV1";
const SLUG = "furoshiki-steps";
const STAGES = [["本包み", ["布を広げる", "荷物を中央に置く", "向かい合う角を結ぶ", "残りの角を結んで仕上げる"]], ["花包み", ["布を広げる", "荷物を中央に置く", "四隅を中央に集める", "集めた角を花のように結ぶ"]], ["瓶包み", ["布を広げる", "瓶を中央に立てる", "両端を持ち上げる", "上で結んで持ち手にする"]], ["箱包み", ["布を広げる", "箱を斜めに置く", "角を箱に沿って折り込む", "上で結んで仕上げる"]], ["二つ包み", ["布を広げる", "荷物を二つ並べる", "中央で布を分ける", "それぞれを結んで仕上げる"]], ["結び目包み", ["布を広げる", "荷物を中央に置く", "角を一つ結びにする", "余った角を結び目に通す"]]];
const DEF = {"selected": 0, "checks": {}, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._n = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _dish() { var st = this._load(); var s = (typeof st.selected === 'number') ? st.selected : 0; return STAGES[s]; },
  _recompute() { var dg = this._dish(); var d = {}; d.status = "うなずきで手順を一つずつ進める"; var i; for (i = 0; i < 4; i++) { d['r' + i] = ((i < this._n ? '済 ' : (i === this._n ? '▶ ' : '· ')) + dg[1][i]); } d.r4 = '包み方：' + dg[0]; d.r5 = (this._n >= 4) ? "4つともできあがり" : ("次：" + dg[1][this._n]); d.big = dg[0] + ' ' + this._n + ' / 4'; d.detail = "風呂敷はうなずきで進めます。"; d.guide = "うなずく＝次の手順へ進む · 4つ終えたら「記録する」"; d.evt = 'EVT: step ' + this._n; this.setData(d); },
  primaryTap() { var dg = this._dish(); if (this._n < 4) { this._speak(dg[1][this._n] + "、できました。"); this._n++; } else { this._speak("4つともできあがりです。"); } this._recompute(); },
  finishTap() { if (this._n < 4) { this._speak("まだ終わっていない手順があります。"); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: "風呂敷包み", item: this._dish()[0], at: new Date().toISOString() }); if (!st.checks) st.checks = {}; st.checks[String((typeof st.selected === 'number') ? st.selected : 0)] = 4; this._save(st); this._speak(this._dish()[0] + "、4つの手順で包めました。"); this._nav('/pages/record/index'); },
  nextTap() { this.primaryTap(); },
  prevTap() { if (this._n > 0) this._n--; this._recompute(); },
  speakTap() { this._speak(this._dish()[0] + '、' + this._n + ' / 4'); },
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
    <div class="band">風呂敷の包み方</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">進む</button><button class="btn" bindtap="finishTap">記録する</button><button class="btn" bindtap="backTap">戻る</button><button class="btn" bindtap="speakTap">音声</button>
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

.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-top:2px solid #40ff5e;border-bottom:6px solid #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:6px;font-size:13px;padding:7px 0;text-align:center;}
</style>
