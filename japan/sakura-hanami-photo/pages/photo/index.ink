<script def>
{
  "title": "桜の花見写真"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "sakuraHanamiPhotoV1";
const SLUG = "sakura-hanami-photo";
const SPOTS = ["上野恩賜公園", "千鳥ヶ淵", "目黒川", "新宿御苑", "隅田公園", "井の頭恩賜公園"];
const ITEMS = ["上野恩賜公園・桜並木の入口", "上野恩賜公園・不忍池のほとり", "千鳥ヶ淵・桜のトンネル", "千鳥ヶ淵・ボート乗り場前", "目黒川・川沿いの桜並木", "目黒川・橋の上から", "新宿御苑・桜園の入口", "新宿御苑・芝生の桜の下", "隅田公園・桜のトンネル", "隅田公園・スカイツリーと桜", "井の頭恩賜公園・井の頭池のほとり", "井の頭恩賜公園・桜の小道"];
const DEF = {"selected": 0, "checks": {}, "photo": null, "records": []};
export default {
  data: { status: '', big: '', 'r0': '', 'r1': '', 'r2': '', 'r3': '', 'r4': '', 'r5': '', 'r6': '', 'r7': '', 'r8': '', 'r9': '', 'r10': '', 'r11': '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._spot = (typeof st.selected === 'number') ? st.selected : 0; var saved = st.checks || {}; this._marks = ITEMS.map(function (_, i) { return !!saved[String(i)]; }); this._sub = 0; this._photo = !!(st.photo); this._photoBytes = st.photo ? st.photo.bytes : 0; this._notice = ''; this._armed = true; this._startSensor(); this._recompute(); },
  onShow() { this._recompute(); },
  _startSensor() { try { if (typeof AbsoluteOrientationSensor === 'undefined') { this._sensorOk = false; return; } var s = new AbsoluteOrientationSensor({ frequency: 30 }); var self = this; s.addEventListener('reading', function () { var q = s.quaternion; if (!q) return; var yaw = Math.atan2(2 * (q[3] * q[2] + q[0] * q[1]), 1 - 2 * (q[1] * q[1] + q[2] * q[2])); self._onYaw(yaw); }); s.addEventListener('error', function () { self._sensorOk = false; self._fail('E7001', 'sensor error'); }); s.start(); this._sensor = s; this._sensorOk = true; } catch (e) { this._sensorOk = false; this._fail('E7001', 'sensor'); } },
  _onYaw(yaw) { if (Math.abs(yaw) < 0.15) { this._armed = true; } else if (this._armed && yaw < -0.35) { this._spot = (this._spot + SPOTS.length - 1) % SPOTS.length; this._sub = 0; this._armed = false; } else if (this._armed && yaw > 0.35) { this._spot = (this._spot + 1) % SPOTS.length; this._sub = 0; this._armed = false; } this._recompute(); },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = "まず撮ってから、一つずつ印を付ける。12か所すべてで完了"; for (i = 0; i < ITEMS.length; i++) { d['r' + i] = (((Math.floor(i / 2) === this._spot && i % 2 === this._sub) ? '> ' : '- ') + (this._marks[i] ? '[x] ' : '[ ] ') + ITEMS[i]); } d.big = this._photo ? ('撮影ずみ - ' + done + '/12') : ('未撮影 - ' + done + '/12'); d.detail = this._notice || ('名所：' + SPOTS[this._spot] + (this._photo ? ('・写真 ' + this._photoBytes + ' バイト') : '')); d.guide = "写真は本人の確認だけに使う。他の人の顔を識別しない。撮影なしでは完了できない"; d.evt = 'EVT: ' + done + '/12 photo ' + (this._photo ? 'yes' : 'no'); this.setData(d); },
  _persist() { var st = this._load(); var c = {}; var i; for (i = 0; i < this._marks.length; i++) c[String(i)] = !!this._marks[i]; st.checks = c; st.selected = this._spot; this._save(st); },
  tickTap() { var i = this._spot * 2 + this._sub; this._marks[i] = !this._marks[i]; this._notice = ''; this._sub = 1 - this._sub; this._persist(); this._speak(ITEMS[i] + (this._marks[i] ? ' に印を付けました。' : ' の印を消しました。')); this._recompute(); },
  _blobToDataUrl(blob) { var self = this; return blob.arrayBuffer().then(function (buf) { var bytes = new Uint8Array(buf); var bin = ''; var CH = 0x8000; var i; for (i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH)); return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin); }); },
  photoTap() { var self = this; var stream = null; if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') { this._fail('E8004', 'camera n/a'); return; } return navigator.mediaDevices.getUserMedia({ video: true }).then(function (s) { stream = s; var track = stream.getVideoTracks()[0]; if (!track) throw new Error('no video track'); var cap = new ImageCapture(track); return cap.takePhoto({ mode: 'wide' }); }).then(function (blob) { return self._blobToDataUrl(blob).then(function (url) { self._photoUrl = url; self._photo = true; self._photoBytes = blob.size; var st = self._load(); st.photo = { at: new Date().toISOString(), bytes: blob.size }; self._save(st); self._notice = ''; self._speak('写真を保存しました。本人の確認だけに使います。'); self._recompute(); }, function (e) { self._fail('E2013', 'encode'); }); }).catch(function (e) { if (String((e && e.message) || e).indexOf('E2013') < 0) self._fail('E2001', 'takePhoto'); }).then(function () { if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {} } }); },
  primaryTap() { this.photoTap(); },
  confirmTap() { if (!this._photo) { this._notice = 'まず撮影してください。完了には撮影が必要です。'; this._speak('まず撮影してください。'); this._recompute(); return; } var missing = 0; var i; for (i = 0; i < this._marks.length; i++) if (!this._marks[i]) missing++; if (missing > 0) { this._notice = missing + 'か所にまだ印が付いていません。先に印を付けてください。'; this._speak(missing + 'か所にまだ印が付いていません。'); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: "花見の写真めぐり", item: SPOTS[this._spot] + '・12/12', at: new Date().toISOString() }); this._save(st); this._notice = ''; this._speak('12か所すべて終わりました。'); this._recompute(); },
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
    <div class="band">桜の花見写真</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow12">{{ r0 }}</div><div class="rrow12">{{ r1 }}</div><div class="rrow12">{{ r2 }}</div><div class="rrow12">{{ r3 }}</div><div class="rrow12">{{ r4 }}</div><div class="rrow12">{{ r5 }}</div><div class="rrow12">{{ r6 }}</div><div class="rrow12">{{ r7 }}</div><div class="rrow12">{{ r8 }}</div><div class="rrow12">{{ r9 }}</div><div class="rrow12">{{ r10 }}</div><div class="rrow12">{{ r11 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="backTap">戻る</button><button class="btn" bindtap="photoTap">撮影する</button><button class="btn" bindtap="tickTap">印を付ける</button><button class="btn" bindtap="confirmTap">完了を確認</button>
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
.rrow12{color:#7dff9e;font-size:11px;line-height:13px;white-space:nowrap;overflow:hidden;}
</style>
