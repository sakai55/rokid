<script def>
{
  "title": "胡同拍照核对"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaHutongPhotoV1";
const SLUG = "china-hutong-photo";
const SPOTS = ["南锣鼓巷", "烟袋斜街", "五道营胡同", "国子监街", "琉璃厂", "东交民巷"];
const ITEMS = ["南锣鼓巷 - 南锣鼓巷牌楼", "南锣鼓巷 - 雨儿胡同口", "烟袋斜街 - 烟袋斜街牌楼", "烟袋斜街 - 银锭桥", "五道营胡同 - 五道营胡同牌楼", "五道营胡同 - 胡同老门楼", "国子监街 - 国子监牌楼", "国子监街 - 孔庙大成门", "琉璃厂 - 琉璃厂牌楼", "琉璃厂 - 荣宝斋门脸", "东交民巷 - 东交民巷老使馆门", "东交民巷 - 圣弥厄尔教堂"];
const DEF = {"selected": 0, "checks": {}, "photo": null, "records": []};
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', r6: '', r7: '', r8: '', r9: '', r10: '', r11: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._spot = (typeof st.selected === 'number') ? st.selected : 0; var saved = st.checks || {}; this._marks = ITEMS.map(function (_, i) { return !!saved[String(i)]; }); this._sub = 0; this._photo = !!(st.photo); this._photoBytes = st.photo ? st.photo.bytes : 0; this._notice = ''; this._armed = true; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },

  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._onYaw(yaw); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _onYaw(yaw) { if (Math.abs(yaw) < 0.15) { this._armed = true; } else if (this._armed && yaw < -0.35) { this._spot = (this._spot + SPOTS.length - 1) % SPOTS.length; this._sub = 0; this._armed = false; } else if (this._armed && yaw > 0.35) { this._spot = (this._spot + 1) % SPOTS.length; this._sub = 0; this._armed = false; } this._recompute(); },

  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = "先拍照，再逐个打勾，12 处全打勾才算走完"; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = (((Math.floor(i / 2) === this._spot && i % 2 === this._sub) ? '> ' : '- ') + (this._marks[i] ? '[x] ' : '[ ] ') + ITEMS[i]); } d.big = this._photo ? ('已拍照 - ' + done + '/12 已打勾') : ('尚未拍照 - ' + done + '/12 已打勾'); d.detail = this._notice || ('胡同：' + SPOTS[this._spot] + (this._photo ? (' - 照片 ' + this._photoBytes + ' 字节') : '')); d.guide = "拍照只作本人核对，不识别他人正脸；没拍照不能确认完成"; d.evt = 'EVT: ' + done + '/12 photo ' + (this._photo ? 'yes' : 'no'); this.setData(d); },
  _persist() { var st = this._load(); var c = {}; var i; for (i = 0; i < this._marks.length; i++) c[String(i)] = !!this._marks[i]; st.checks = c; st.selected = this._spot; this._save(st); },
  tickTap() { var i = this._spot * 2 + this._sub; this._marks[i] = !this._marks[i]; this._notice = ''; this._sub = 1 - this._sub; this._persist(); this._speak(ITEMS[i] + (this._marks[i] ? ' 已打勾。' : ' 已取消打勾。')); this._recompute(); },
  _blobToDataUrl(blob) { var self = this; return blob.arrayBuffer().then(function (buf) { var bytes = new Uint8Array(buf); var bin = ''; var CH = 0x8000; var i; for (i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH)); return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin); }); },
  photoTap() { var self = this; var stream = null; if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') { this._fail('E8004', 'camera n/a'); return; } return navigator.mediaDevices.getUserMedia({ video: true }).then(function (s) { stream = s; var track = stream.getVideoTracks()[0]; if (!track) throw new Error('no video track'); var cap = new ImageCapture(track); return cap.takePhoto({ mode: 'wide' }); }).then(function (blob) { return self._blobToDataUrl(blob).then(function (url) { self._photoUrl = url; self._photo = true; self._photoBytes = blob.size; var st = self._load(); st.photo = { at: new Date().toISOString(), bytes: blob.size }; self._save(st); self._notice = ''; self._speak('照片已保存，仅供本人核对。'); self._recompute(); }, function (e) { self._fail('E2013', 'encode'); }); }).catch(function (e) { if (String((e && e.message) || e).indexOf('E2013') < 0) self._fail('E2001', 'takePhoto'); }).then(function () { if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {} } }); },
  primaryTap() { this.photoTap(); },
  confirmTap() { if (!this._photo) { this._notice = '请先拍照，完成需要先拍照。'; this._speak('请先拍照。'); this._recompute(); return; } var missing = 0; var i; for (i = 0; i < this._marks.length; i++) if (!this._marks[i]) missing++; if (missing > 0) { this._notice = missing + ' 处未打勾，请先打勾。'; this._speak(missing + ' 处未打勾。'); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: "胡同拍照走完", item: SPOTS[this._spot] + ' - 12/12', at: new Date().toISOString() }); this._save(st); this._notice = ''; this._speak('12 处都完成了。'); this._recompute(); },
  nextTap() { this._spot = (this._spot + 1) % SPOTS.length; this._sub = 0; this._recompute(); },
  prevTap() { this._spot = (this._spot + SPOTS.length - 1) % SPOTS.length; this._sub = 0; this._recompute(); },
  speakTap() { this._speak(ITEMS[this._spot * 2 + this._sub]); },
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
    <div class="band">胡同拍照核对</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow12">{{ r0 }}</div><div class="rrow12">{{ r1 }}</div><div class="rrow12">{{ r2 }}</div><div class="rrow12">{{ r3 }}</div><div class="rrow12">{{ r4 }}</div><div class="rrow12">{{ r5 }}</div><div class="rrow12">{{ r6 }}</div><div class="rrow12">{{ r7 }}</div><div class="rrow12">{{ r8 }}</div><div class="rrow12">{{ r9 }}</div><div class="rrow12">{{ r10 }}</div><div class="rrow12">{{ r11 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="backTap">返回</button><button class="btn" bindtap="photoTap">拍照</button><button class="btn" bindtap="tickTap">打勾</button><button class="btn" bindtap="confirmTap">确认走完</button>
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
.rrow12{color:#7dff9e;font-size:11px;line-height:13px;white-space:nowrap;overflow:hidden;}
</style>
