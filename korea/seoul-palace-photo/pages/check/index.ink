<script def>
{
  "title": "사진 확인"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "seoulPalacePhotoV1";
const ZONES = ["광화문", "근정전", "경회루", "자경전", "향원정", "고궁박물관"];
const ITEMS = ["광화문 정문", "광화문 해치상", "근정전 정전", "근정전 월대", "경회루 누각", "경회루 연못", "자경전 침전", "자경전 정원", "향원정 정자", "향원정 연못", "고궁박물관 전시실", "고궁박물관 정원"];
const DEF = {"selected": 0, "checks": {}, "photo": null, "records": []};
const STATUS = "사진을 먼저 찍고 12곳을 모두 체크하세요";
const GUIDE = "사진은 본인 확인용입니다 · 명소를 자동으로 판별하지 않으며 다른 사람 얼굴을 찍지 않습니다";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._sel = (typeof st.selected === 'number') ? st.selected : 0; var saved = st.checks || {}; this._marks = ITEMS.map(function (_, i) { return !!saved[String(i)]; }); this._idx = 0; this._half = 0; this._photo = !!(st.photo); this._photoBytes = st.photo ? st.photo.bytes : 0; this._notice = ''; this._recompute(); },
  onShow() { this._recompute(); },
  _global(i) { return this._half * 6 + i; },
  _recompute() { var done = 0; var i; for (i = 0; i < this._marks.length; i++) if (this._marks[i]) done++; var d = {}; d.status = STATUS; for (i = 0; i < 6; i++) { var g = this._global(i); d['r' + i] = ((i === this._idx ? '▶ ' : '· ') + (this._marks[g] ? '☑ ' : '☐ ') + ITEMS[g]); } d.big = this._photo ? ('사진 보관 중 - ' + done + '/12 체크') : ('사진 없음 - ' + done + '/12 체크'); d.detail = this._notice || ('구역: ' + ZONES[this._sel] + ' · 사진 ' + (this._half + 1) + '/2쪽' + (this._photo ? (' · ' + this._photoBytes + '바이트') : '')); d.guide = GUIDE; d.evt = 'EVT: ' + done + '/12 photo ' + (this._photo ? 'yes' : 'no'); this.setData(d); },
  _persist() { var st = this._load(); var c = {}; var i; for (i = 0; i < this._marks.length; i++) c[String(i)] = !!this._marks[i]; st.checks = c; st.selected = this._sel; this._save(st); },
  tickTap() { var g = this._global(this._idx); this._marks[g] = !this._marks[g]; this._notice = ''; this._persist(); this._speak(ITEMS[g] + (this._marks[g] ? ' 체크했습니다.' : ' 체크를 해제했습니다.')); this._recompute(); },
  pageTap() { this._half = (this._half + 1) % 2; this._idx = 0; this._recompute(); },
  _blobToDataUrl(blob) { var self = this; return blob.arrayBuffer().then(function (buf) { var bytes = new Uint8Array(buf); var bin = ''; var CH = 0x8000; var i; for (i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH)); return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin); }); },
  photoTap() { var self = this; var stream = null; if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') { this._fail('E8004', 'camera n/a'); return; } return navigator.mediaDevices.getUserMedia({ video: true }).then(function (s) { stream = s; var track = stream.getVideoTracks()[0]; if (!track) throw new Error('no video track'); var cap = new ImageCapture(track); return cap.takePhoto({ mode: 'wide' }); }).then(function (blob) { return self._blobToDataUrl(blob).then(function (url) { self._photoUrl = url; self._photo = true; self._photoBytes = blob.size; var st = self._load(); st.photo = { at: new Date().toISOString(), bytes: blob.size }; self._save(st); self._notice = ''; self._speak('본인 확인용 사진을 보관했습니다.'); self._recompute(); }, function (e) { self._fail('E2013', 'encode'); }); }).catch(function (e) { if (String((e && e.message) || e).indexOf('E2013') < 0) self._fail('E2001', 'takePhoto'); }).then(function () { if (stream) { try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {} } }); },
  checkoutTap() { if (!this._photo) { this._notice = '사진을 먼저 찍으세요. 정산에는 사진이 필요합니다.'; this._speak('사진을 먼저 찍으세요. 정산에는 사진이 필요합니다.'); this._recompute(); return; } var missing = 0; var i; for (i = 0; i < this._marks.length; i++) if (!this._marks[i]) missing++; if (missing > 0) { this._notice = '아직 체크하지 않은 곳이 ' + missing + '곳 있습니다.'; this._speak('아직 체크하지 않은 곳이 ' + missing + '곳 있습니다.'); this._recompute(); return; } var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: '사진 확인 완료', item: ZONES[this._sel] + ' - 12곳 모두', at: new Date().toISOString() }); this._save(st); this._notice = ''; this._speak('모두 확인했습니다. 정산할 수 있습니다.'); this._recompute(); },
  primaryTap() { this.photoTap(); },
  nextTap() { this._idx = (this._idx + 1) % 6; this._recompute(); },
  prevTap() { this._idx = (this._idx + 5) % 6; this._recompute(); },
  speakTap() { this._speak(ITEMS[this._global(this._idx)]); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'seoul-palace-photo', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
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
    <div class="band">사진 확인</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="photoTap">사진 찍기</button>
      <button class="btn" bindtap="tickTap">항목 체크</button>
      <button class="btn" bindtap="nextTap">다음 항목</button>
      <button class="btn" bindtap="pageTap">다음 페이지</button>
      <button class="btn" bindtap="checkoutTap">정산</button>
      <button class="btn" bindtap="backTap">뒤로</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:16px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:12px;line-height:18px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:340px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#123d2a;color:#7dff9e;font-size:19px;font-weight:bold;padding:7px 10px;border:2px solid #40ff5e;border-radius:16px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#1d6b33;color:#7dff9e;border:1px solid #40ff5e;border-radius:20px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
