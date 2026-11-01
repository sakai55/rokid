<script def>
{
  "title": "逐件核对"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaMarketPhotoV1";
const STALLS = ["蔬菜摊", "水果摊", "肉禽摊", "豆制品摊", "水产摊", "干货调料摊"];
const ITEMS = ["青菜", "番茄", "鸡蛋", "豆腐", "猪肉", "鲫鱼", "苹果", "香蕉", "土豆", "大葱", "生姜", "大蒜"];
const DEF = {"selected": 0, "checks": {}, "records": [], "photo": null};
const GUIDE = "打勾核对菜篮子 · 点头拍照是结账放行必经步 · 照片只给本人当场核对";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', r8: '', r9: '', r10: '', r11: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; var saved = (st.checks && st.checks[String(this._sel)]) || []; this._marks = ITEMS.map(function (_, i) { return !!saved[i]; }); this._photoDone = !!(st.photo && st.photo.stall === this._sel); this._idx = 0; this._recompute(); },
  _doneCount() { var n = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) n++; return n; },
  _recompute() { var done = this._doneCount(); var d = {}; d.status = STALLS[this._sel] + ' · 核对 ' + done + '/' + ITEMS.length; var i; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._marks[i] ? '☑ ' : '☐ ') + ITEMS[i]); } d.big = this._photoDone ? '已拍照 · ' + done + '/' + ITEMS.length : '未拍照 · ' + done + '/' + ITEMS.length; d.detail = this._photoDone ? '照片已拍，只给本人当场核对，不存图、不识别商品' : '请先点头拍照，再结账确认'; d.guide = GUIDE; d.evt = 'EVT: ' + done + '/' + ITEMS.length + ' photo ' + (this._photoDone ? 'yes' : 'no'); this.setData(d); },
  _persist() { var st = this._load(); if (!st.checks) st.checks = {}; st.checks[String(this._sel)] = this._marks.slice(); st.selected = this._sel; this._save(st); },
  checkTap() { this._marks[this._idx] = !this._marks[this._idx]; this._persist(); this._speak(ITEMS[this._idx] + (this._marks[this._idx] ? '已打勾。' : '已取消。')); this._recompute(); },
  nextTap() { this._idx = (this._idx + 1) % ITEMS.length; this._recompute(); },
  prevTap() { this._idx = (this._idx + ITEMS.length - 1) % ITEMS.length; this._recompute(); },
  photoTap() { var self = this; if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) { this._fail('E8004', 'camera n/a'); return; } if (typeof ImageCapture === 'undefined') { this._fail('E8004', 'ImageCapture n/a'); return; } navigator.mediaDevices.getUserMedia({ video: true }).then(function (stream) { try { var track = stream.getVideoTracks()[0]; var cap = new ImageCapture(track); cap.takePhoto({ mode: 'wide' }).then(function (blob) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {} blob.arrayBuffer().then(function (buf) { var bytes = new Uint8Array(buf); var bin = ''; var CH = 0x8000; var i; for (i = 0; i < bytes.length; i += CH) { bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH)); } var dataUrl = 'data:image/jpeg;base64,' + btoa(bin); self._photoOk(dataUrl, blob.size); }, function () { self._fail('E2005', 'photo convert'); }); }, function () { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {} self._fail('E2001', 'takePhoto'); }); } catch (e) { self._fail('E2001', 'camera'); } }, function () { self._fail('E8004', 'camera denied'); }); },
  _photoOk(dataUrl, size) { if (!dataUrl || dataUrl.length < 100) { this._fail('E2005', 'photo convert'); return; } this._photoDone = true; var st = this._load(); st.photo = { stall: this._sel, at: new Date().toISOString(), bytes: size || 0 }; this._save(st); this._speak('已拍下菜篮子，请对照打勾核对。'); this._recompute(); },
  finishTap() { var done = this._doneCount(); if (!this._photoDone) { this._speak('请先点头拍照，拍照是结账放行必经步。'); this.setData({ evt: 'EVT: photo required before checkout' }); return; } if (done < ITEMS.length) { this._speak('还差 ' + (ITEMS.length - done) + ' 件没有打勾，差一件不结账。'); this.setData({ evt: 'EVT: missing ' + (ITEMS.length - done) + ' items' }); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '结账确认', item: STALLS[this._sel], at: new Date().toISOString() }); this._save(st); this._speak(STALLS[this._sel] + '，12 件全部核对无误，可以结账。'); this._recompute(); },
  primaryTap() { this.photoTap(); },
  speakTap() { this._speak(ITEMS[this._idx] + '。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'china-market-photo', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },

};
</script>

<template>
  <div class="page">
    <div class="band">逐件核对</div>
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
    <div class="rrow">{{ r8 }}</div>
    <div class="rrow">{{ r9 }}</div>
    <div class="rrow">{{ r10 }}</div>
    <div class="rrow">{{ r11 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="checkTap">打勾</button>
      <button class="btn" bindtap="photoTap">点头拍照</button>
      <button class="btn" bindtap="nextTap">下一个</button>
      <button class="btn" bindtap="finishTap">结账确认</button>
      <button class="btn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:15px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:11px;line-height:15px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{display:flex;flex-direction:row;margin-top:6px;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:330px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0d3d17;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-left:8px solid #40ff5e;border-radius:10px;text-align:left;}
.btn{flex:1;margin-right:8px;background-color:#0d2812;color:#40ff5e;border:2px solid rgba(64,255,94,0.7);font-size:13px;padding:7px 0;text-align:center;border-radius:12px;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
