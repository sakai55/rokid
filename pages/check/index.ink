<script def>
{
  "title": "自提核对"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaPickupPhotoV1";
const SLUG = "china-pickup-photo";
const SHELVES = ["一号架", "二号架", "三号架", "四号架", "五号架", "六号架"];
const ITEMS = ["一号架·牛奶", "一号架·鸡蛋", "二号架·馒头", "二号架·饺子", "三号架·苹果", "三号架·香蕉", "四号架·青菜", "四号架·土豆", "五号架·纸巾", "五号架·洗衣液", "六号架·汤圆", "六号架·水饺"];
const DEF = {"selected": 0, "checks": {}, "photo": null, "records": []};
const STATUS = "先拍照，再逐件打勾，齐了才能取货确认";
const GUIDE = "看向货架即锁定，转头切架 · 照片只作本人核对 · 差一件也提醒，不写取货记录";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', r8: '', r9: '', r10: '', r11: '', detail: '', guide: '', evt: 'EVT: ready' },
  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._shelf = (typeof st.selected === 'number') ? st.selected : 0; var saved = st.checks || {}; this._marks = ITEMS.map(function (_, i) { return !!saved[String(i)]; }); this._sub = 0; this._photo = !!(st.photo); this._photoBytes = st.photo ? st.photo.bytes : 0; this._notice = ''; this._armed = true; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._onYaw(yaw); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _onYaw(yaw) { if (Math.abs(yaw) < 0.15) { this._armed = true; } else if (this._armed && yaw < -0.35) { this._shelf = (this._shelf + 5) % 6; this._sub = 0; this._armed = false; } else if (this._armed && yaw > 0.35) { this._shelf = (this._shelf + 1) % 6; this._sub = 0; this._armed = false; } this._recompute(); },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = STATUS; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = (((Math.floor(i / 2) === this._shelf && i % 2 === this._sub) ? '▶ ' : '· ') + (this._marks[i] ? '☑ ' : '☐ ') + ITEMS[i]); } d.big = this._photo ? ('已拍照 · ' + done + '/12 已勾') : ('未拍照 · ' + done + '/12 已勾'); d.detail = this._notice || ('当前货架：' + SHELVES[this._shelf] + (this._photo ? (' · 照片 ' + this._photoBytes + ' 字节') : '')); d.guide = GUIDE; d.evt = 'EVT: ' + done + '/12 photo ' + (this._photo ? 'yes' : 'no'); this.setData(d); },
  _persist() { var st = this._load(); var c = {}; var i; for (i = 0; i < this._marks.length; i++) c[String(i)] = !!this._marks[i]; st.checks = c; st.selected = this._shelf; this._save(st); },
  tickTap() { var i = this._shelf * 2 + this._sub; this._marks[i] = !this._marks[i]; this._notice = ''; this._sub = 1 - this._sub; this._persist(); this._speak(ITEMS[i] + (this._marks[i] ? '已打勾。' : '已取消。')); this._recompute(); },
  _blobToDataUrl(blob) { var self = this; return blob.arrayBuffer().then(function (buf) { var bytes = new Uint8Array(buf); var bin = ''; var CH = 0x8000; var i; for (i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH)); return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin); }); },
  photoTap() { var self = this; var stream = null; if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') { this._fail('E8004', 'camera n/a'); return; } return navigator.mediaDevices.getUserMedia({ video: true }).then(function (s) { stream = s; var track = stream.getVideoTracks()[0]; if (!track) throw new Error('no video track'); var cap = new ImageCapture(track); return cap.takePhoto({ mode: 'wide' }); }).then(function (blob) { return self._blobToDataUrl(blob).then(function (url) { self._photoUrl = url; self._photo = true; self._photoBytes = blob.size; var st = self._load(); st.photo = { at: new Date().toISOString(), bytes: blob.size }; self._save(st); self._notice = ''; self._speak('照片已留作本人核对。'); self._recompute(); }, function (e) { self._fail('E2013', 'encode'); }); }).catch(function (e) { if (String((e && e.message) || e).indexOf('E2013') < 0) self._fail('E2001', 'takePhoto'); }).then(function () { if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {} } }); },
  primaryTap() { this.photoTap(); },
  checkoutTap() { if (!this._photo) { this._notice = '请先拍照，取货确认需要照片。'; this._speak('请先拍照，取货确认需要照片。'); this._recompute(); return; } var missing = 0; var i; for (i = 0; i < this._marks.length; i++) if (!this._marks[i]) missing++; if (missing > 0) { this._notice = '还差 ' + missing + ' 件未打勾，先核对再确认。'; this._speak('还差' + missing + '件未打勾。'); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '自提核对完成', item: SHELVES[this._shelf] + ' · 12 件齐', at: new Date().toISOString() }); this._save(st); this._notice = ''; this._speak('12 件齐，可以取货了。'); this._recompute(); },
  nextTap() { this._shelf = (this._shelf + 1) % 6; this._sub = 0; this._recompute(); },
  prevTap() { this._shelf = (this._shelf + 5) % 6; this._sub = 0; this._recompute(); },
  speakTap() { this._speak(ITEMS[this._shelf * 2 + this._sub]); },
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
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },
};
</script>

<template>
  <div class="page">
    <div class="band">自提核对</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow12">{{ r0 }}</div>
    <div class="rrow12">{{ r1 }}</div>
    <div class="rrow12">{{ r2 }}</div>
    <div class="rrow12">{{ r3 }}</div>
    <div class="rrow12">{{ r4 }}</div>
    <div class="rrow12">{{ r5 }}</div>
    <div class="rrow12">{{ r6 }}</div>
    <div class="rrow12">{{ r7 }}</div>
    <div class="rrow12">{{ r8 }}</div>
    <div class="rrow12">{{ r9 }}</div>
    <div class="rrow12">{{ r10 }}</div>
    <div class="rrow12">{{ r11 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn" bindtap="backTap">返回</button>
      <button class="btn main" bindtap="photoTap">拍照</button>
      <button class="btn" bindtap="tickTap">打勾</button>
      <button class="btn" bindtap="checkoutTap">取货确认</button>
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
.rrow12{color:#7dff9e;font-size:11px;line-height:13px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:19px;font-weight:bold;padding:6px 12px;border-top:2px solid #40ff5e;border-bottom:6px solid #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:6px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}

</style>
