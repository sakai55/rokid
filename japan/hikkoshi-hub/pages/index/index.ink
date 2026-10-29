<script def>
{
  "title": "引越し手帳ハブ"
}
</script>

<script setup>
import wx from 'wx';

// JP37 hikkoshi-hub - 引越し手帳ハブ
const KEY = "hikkoshiHubV1";
const DEF = {"selected": 0, "tools": {}, "records": [], "calc": null, "compare": null};
const TOOLS = [{"name": "転出届チェック", "url": "/pages/t01/index", "total": 5}, {"name": "転入届チェック", "url": "/pages/t02/index", "total": 5}, {"name": "電気手続き", "url": "/pages/t03/index", "total": 4}, {"name": "ガス手続き", "url": "/pages/t04/index", "total": 4}, {"name": "水道手続き", "url": "/pages/t05/index", "total": 4}, {"name": "インターネット移転", "url": "/pages/t06/index", "total": 4}, {"name": "郵便転送", "url": "/pages/t07/index", "total": 4}, {"name": "銀行住所変更", "url": "/pages/t08/index", "total": 5}, {"name": "運転免許住所変更", "url": "/pages/t09/index", "total": 4}, {"name": "健康保険手続き", "url": "/pages/t10/index", "total": 4}, {"name": "学校転校手続き", "url": "/pages/t11/index", "total": 5}, {"name": "粗大ごみ申込", "url": "/pages/t12/index", "total": 6}, {"name": "部屋別荷造り", "url": "/pages/t13/index", "total": 6}, {"name": "業者見積比較", "url": "/pages/t14/index", "total": 1}, {"name": "新居採寸メモ", "url": "/pages/t15/index", "total": 6}, {"name": "ご近所挨拶リスト", "url": "/pages/t16/index", "total": 6}, {"name": "防災確認", "url": "/pages/t17/index", "total": 6}, {"name": "当日タイムライン", "url": "/pages/t18/index", "total": 8}, {"name": "費用計算", "url": "/pages/t19/index", "total": 1}, {"name": "引越し記録", "url": "/pages/t20/index", "total": 1}];
const STATUS = "引越しの20の手続きと道具を、ひとつの手帳で進めます";
const GUIDE = "上下で道具を選ぶ ・ 決定で開く ・ うなずきは主確認";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._idx = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _doneOf(st, i) { var t = st.tools ? st.tools[TOOLS[i].url.split('/')[2]] : null; return t ? t.done : 0; },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; var totalDone = 0; var totalAll = 0; for (i = 0; i < TOOLS.length; i++) { totalDone += this._doneOf(st, i); totalAll += TOOLS[i].total; } for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + TOOLS.length) % TOOLS.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + TOOLS[ti].name + ' ' + this._doneOf(st, ti) + '/' + TOOLS[ti].total); } d.big = TOOLS[this._idx].name; d.detail = '全体の進み具合 ' + totalDone + '/' + totalAll + ' ・ 記録は' + (st.records ? st.records.length : 0) + '件です。'; d.guide = GUIDE; d.evt = 'EVT: ' + TOOLS[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % TOOLS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + TOOLS.length - 1) % TOOLS.length; this._recompute(); },
  primaryTap() { var st = this._load(); st.selected = this._idx; this._save(st); this._nav(TOOLS[this._idx].url); },
  speakTap() { this._speak(TOOLS[this._idx].name + 'です。'); },
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
    <div class="band">引越し手帳ハブ</div>
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
      <button class="btn" bindtap="prevTap">前へ</button>
      <button class="btn" bindtap="nextTap">次へ</button>
      <button class="btn" bindtap="speakTap">音声案内</button>
      <button class="btn" bindtap="backTap">もどる</button>
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
.btn{flex:1;margin-right:8px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-radius:14px;font-size:13px;padding:8px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

</style>
