<script def>
{
  "title": "祭りゲーム集"
}
</script>

<script setup>
import wx from 'wx';

// JP32 matsuri-game-shuu - index
const KEY = "matsuriGameShuuV1";
const DEF = {"selected": 0, "checked": {}, "records": []};
const TOOLS = [{"name": "太鼓リズム", "url": "/pages/g01/index"}, {"name": "金魚すくい数え", "url": "/pages/g02/index"}, {"name": "輪投げクイズ", "url": "/pages/g03/index"}, {"name": "射的方向", "url": "/pages/g04/index"}, {"name": "ヨーヨー釣り数え", "url": "/pages/g05/index"}, {"name": "かき氷色当て", "url": "/pages/g06/index"}, {"name": "盆踊りステップ", "url": "/pages/g07/index"}, {"name": "すいか割り方向", "url": "/pages/g08/index"}, {"name": "くじ引き", "url": "/pages/g09/index"}, {"name": "お面当て", "url": "/pages/g10/index"}, {"name": "たこ焼き数え", "url": "/pages/g11/index"}, {"name": "りんご飴色当て", "url": "/pages/g12/index"}, {"name": "花火色順", "url": "/pages/g13/index"}, {"name": "うちわ扇ぎ数え", "url": "/pages/g14/index"}, {"name": "提灯数え", "url": "/pages/g15/index"}, {"name": "綿あめ量選び", "url": "/pages/g16/index"}, {"name": "スーパーボールすくい数え", "url": "/pages/g17/index"}, {"name": "盆踊り音当て", "url": "/pages/g18/index"}, {"name": "神輿掛け声数え", "url": "/pages/g19/index"}, {"name": "夜店買い物計算", "url": "/pages/g20/index"}];
const NOWTXT = "いま: ";
const CHOOSETXT = "選んで、決定で答える";
const CORRECTTXT = "正解です。";
const WRONG1 = "ちがいます。答えは";
const WRONG2 = "です。";
const QEND = "。";
const QSEP = "、";
const GOALTXT = " ・ 目標達成";
const CNT1 = "、いま";
const CNT2 = "、目標は";
const CNT3 = "です。";
const REC1 = "記録は";
const REC2 = "件です。";
const RECNONE = "記録はまだありません。";
const PHRASEDETAIL = "選んだ文を、声で代わりに言います。";
const WORDLAST = "最後の語です。言い終えたら完了を押してください。";
const WORDNEXT = "うなずくたびに、次の語へ進みます。";
const WORDDONE = "言い終えました。";
const LINELAST = "最後の行です。読み終えたら完了を押してください。";
const LINENEXT = "うなずくたびに、次の行へ進みます。";
const LINEDONE = "読み終えました。";
const HUBEND = "です。";
const STATUS = "夏祭りの待ち時間、屋台ゲームを20個回します";
const GUIDE = "NEXTでゲームを変える ・ ひらくで遊ぶ ・ うなずきは主確認";
function DETAILFN(st) { return '遊んだ記録は' + (st.records ? st.records.length : 0) + '件です。'; }

export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._idx = 0; this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name); } d.big = TOOLS[this._idx].name; d.detail = DETAILFN(st); d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + HUBEND); },
  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _load() { var v = this._rawLoad(); if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = this._rawLoad() || DEF; st.lastError = { code: code, slug: 'matsuri-game-shuu', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e2) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">祭りゲーム集</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="primaryTap">ひらく</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
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

.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border-bottom:3px solid #40ff5e;}
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:14px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
