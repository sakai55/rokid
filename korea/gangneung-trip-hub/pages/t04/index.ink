<script def>
{
  "title": "강릉중앙시장"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "gangneungTripHubV1";
const SLUG = "gangneung-trip-hub";
const GI = 3;
const GNAME = "강릉중앙시장";
const DEF = {"selected": 0, "best": {}, "records": []};

const ITEMS = ["닭강정 가게", "어묵고로케 가게", "시장 입구", "중앙시장 간판"];
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = 0; this._marks = [false, false, false, false]; this._photo = !!(st.photo && st.photo[GI]); this._photoBytes = (st.photo && st.photo[GI]) ? st.photo[GI].bytes : 0; this._trying = false; this._notice = ''; this._done = false; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var done = 0; var i; for (i = 0; i < 4; i++) if (this._marks[i]) done++; var d = {}; d.status = "먼저 찍고, 네 곳에 표시를 하면 끝납니다"; for (i = 0; i < 4; i++) { d['r' + i] = ((i === this._idx ? '> ' : '- ') + (this._marks[i] ? '[x] ' : '[ ] ') + ITEMS[i]); } d.r4 = this._notice || ''; d.r5 = "최고： " + ((this._load().best && this._load().best[String(GI)]) ? this._load().best[String(GI)] : 0); d.big = this._done ? "끝" : (this._photo ? ('촬영 완료 - ' + done + '/4') : (this._trying ? '촬영 중' : ('미촬영 - ' + done + '/4'))); d.detail = this._photo ? ('사진 ' + this._photoBytes + ' 바이트 저장됨') : '사진은 본인 확인에만 쓴다'; d.guide = "촬영으로 사진을 남기고 표시로 네 곳을 확인한 뒤 확인으로 끝낸다"; d.evt = 'EVT: photo ' + done + '/4'; this.setData(d); },
  _blobToDataUrl(blob) { var self = this; return blob.arrayBuffer().then(function (buf) { var bytes = new Uint8Array(buf); var bin = ''; var CH = 0x8000; var i; for (i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH)); return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin); }); },
  photoTap() { var self = this; var stream = null; var stage = 'open'; this._trying = true; this._recompute(); if (typeof navigator === 'undefined' || !navigator.mediaDevices || typeof ImageCapture === 'undefined') { this._trying = false; this._fail('E8004', 'camera n/a'); return; } return navigator.mediaDevices.getUserMedia({ video: true }).then(function (s) { stream = s; stage = 'photo'; var track = stream.getVideoTracks()[0]; if (!track) throw new Error('no video track'); var cap = new ImageCapture(track); return cap.takePhoto({ mode: 'wide' }); }).then(function (blob) { return self._blobToDataUrl(blob).then(function (url) { self._photoUrl = url; self._photo = true; self._trying = false; self._photoBytes = blob.size; var st = self._load(); if (!st.photo) st.photo = {}; st.photo[GI] = { at: new Date().toISOString(), bytes: blob.size }; self._save(st); self._notice = ''; self._speak('사진을 저장했습니다. 본인 확인에만 씁니다.'); self._recompute(); }, function (e) { self._trying = false; self._fail('E2013', 'encode'); var _d = 0, _i; for (_i = 0; _i < 4; _i++) if (self._marks[_i]) _d++; self.setData({ big: self._photo ? ('촬영 완료 - ' + _d + '/4') : '미촬영 - ' + _d + '/4' }); }); }).catch(function (e) { self._trying = false; if (stage === 'open') self._fail('E1001', 'takePhoto'); else self._fail('E1009', 'takePhoto'); var _d2 = 0, _j; for (_j = 0; _j < 4; _j++) if (self._marks[_j]) _d2++; self.setData({ big: self._photo ? ('촬영 완료 - ' + _d2 + '/4') : '미촬영 - ' + _d2 + '/4' }); }).then(function () { if (stream) { try { stream.getTracks().forEach(function (tr) { tr.stop(); }); } catch (e2) {} } }); },
  tickTap() { this._marks[this._idx] = !this._marks[this._idx]; this._notice = ''; this._speak(ITEMS[this._idx] + (this._marks[this._idx] ? '에 표시했습니다.' : ' 표시를 지웠습니다.')); this._recompute(); },
  confirmTap() { if (!this._photo) { this._notice = '먼저 촬영해 주세요. 끝내려면 촬영이 필요합니다.'; this._speak('먼저 촬영해 주세요.'); this._recompute(); return; } var missing = 0; var i; for (i = 0; i < 4; i++) if (!this._marks[i]) missing++; if (missing > 0) { this._notice = missing + '곳에 아직 표시가 없습니다. 먼저 표시해 주세요.'; this._speak(missing + '곳에 아직 표시가 없습니다.'); this._recompute(); return; } this._done = true; var st = this._load(); if (!st.records) st.records = []; st.records.push({ kind: GNAME, item: '사진 4 / 4', at: new Date().toISOString() }); if (!st.best) st.best = {}; if (!st.best[String(GI)] || 4 > st.best[String(GI)]) st.best[String(GI)] = 4; this._save(st); this._speak('끝. 네 곳을 모두 확인했습니다.'); this._recompute(); },
  primaryTap() { this.photoTap(); },
  nextTap() { this._idx = (this._idx + 1) % 4; this._recompute(); },
  prevTap() { this._idx = (this._idx + 3) % 4; this._recompute(); },
  speakTap() { this._speak(ITEMS[this._idx]); },
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
    <div class="band">강릉중앙시장</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div><div class="rrow">{{ r1 }}</div><div class="rrow">{{ r2 }}</div><div class="rrow">{{ r3 }}</div><div class="rrow">{{ r4 }}</div><div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="photoTap">촬영</button><button class="btn" bindtap="tickTap">표시</button><button class="btn" bindtap="confirmTap">확인</button><button class="btn" bindtap="backTap">돌아가기</button>
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

.band{background-color:#0a2a12;color:#7dff9e;font-size:19px;font-weight:bold;padding:8px 10px;border:2px solid #40ff5e;border-radius:8px;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a12;color:#7dff9e;border:1px solid #40ff5e;border-radius:8px;font-size:13px;padding:7px 0;text-align:center;}
</style>
