<script def>
{
  "navigationBarTitleText": "Last Glance"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '离开前环视一周 — 每区头稳住点 SNAP 拍照存档，6 区全亮才可以离开',
    steadyText: 'HEAD: moving - hold still',
    boxLabel: '◎ 环视进行中 — 没拍的区一眼就能看见',
    bigLabel: '当前区 · 前',
    bigText: '○ 未拍',
    bigNote: 'SNAP 拍当前区 / DEMO 演示（模拟描述）',
    capLine: 'CAP: none - SNAP takes a wide photo (memory only)',
    rows: [],
    countLine: '已存档 0/6 · 只存本次会话内存 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - turn around once, photo each zone, confirm it',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'sweep'; // sweep | done | replay
    this._zones = [null, null, null, null, null, null]; // {desc, src, photo} or null
    this._focus = 0;
    this._replayIdx = 0;
    this._replayFrom = 'sweep';
    this._pending = null; // {zoneIdx, desc, src, readState, failWhy, blob, bytes}
    this._newArm = false;
    this._armTimer = null;
    this._nodLock = false;
    this._demoStage = 0; // 0 none, 1 partial (2 zones), 2 full (done)
    this._renderAll();
  },

  onShow() {},

  onHide() {
    this._disarm();
  },

  onUnload() {
    // Session-only by construction: the archive, the pending read and
    // every description die with the page. Nothing was ever written
    // to any storage, so there is nothing to clean up - that IS the
    // design. The useful window is "just left, worrying on the road",
    // not a permanent archive.
    this._zones = [null, null, null, null, null, null];
    this._pending = null;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (only nod is documented)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: nod ignored - hold head steady first' });
      return;
    }
    // Nod discipline in THIS agent: a steady nod means ONE thing -
    // "confirm this zone's photo" - and only while a pending photo
    // waits in sweep mode. It never photographs, never moves focus,
    // never replays, never clears the archive.
    if (this._mode === 'sweep' && this._pending) {
      this._confirmZone();
      return;
    }
    this.setData({ lastEvent: 'EVT: nod ignored - nod only confirms a pending zone photo' });
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      this.okTap();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _withTimeout(promise, ms, label) {
    return Promise.race([
      promise,
      new Promise(function (resolve, reject) {
        setTimeout(function () { reject(new Error(label + ' timeout ' + ms + 'ms')); }, ms);
      })
    ]);
  },

  _zoneNames() {
    return ['前', '右前', '右后', '后', '左后', '左前'];
  },

  _demoDescs() {
    return ['玄关门已关', '窗户关着，桌上无遗留', '床铺整齐，充电器已拔',
      '阳台门关着', '衣柜门关着', '水杯药盒已带'];
  },

  _countDone() {
    var n = 0;
    for (var i = 0; i < this._zones.length; i++) if (this._zones[i]) n++;
    return n;
  },

  _allDone() {
    return this._countDone() === 6;
  },

  _firstMissing() {
    for (var i = 0; i < this._zones.length; i++) if (!this._zones[i]) return i;
    return -1;
  },

  _firstDone() {
    for (var i = 0; i < this._zones.length; i++) if (this._zones[i]) return i;
    return -1;
  },

  _hasReal() {
    for (var i = 0; i < this._zones.length; i++) {
      if (this._zones[i] && this._zones[i].src !== 'DEMO') return true;
    }
    return false;
  },

  // ---------- description parser (pure; an unclear reply is a failed read, never a guess) ----------

  _parseZoneDesc(text) {
    // Expected: "ZONE: <one short line>" / "ZONE: NONE".
    // Salvage: one short non-empty line (<=30 chars), never prose.
    var lines = String(text || '').split('\n');
    for (var i = 0; i !== lines.length; i++) {
      var ln = lines[i].trim();
      var m = ln.match(/^ZONE[:：]\s*(.+)$/i);
      if (m) {
        var v = m[1].trim();
        if (/^NONE/i.test(v) || v === '无') return null;
        return v.slice(0, 30);
      }
    }
    for (var j = 0; j !== lines.length; j++) {
      var s2 = lines[j].trim();
      if (s2 && s2.length <= 30 && !/^ZONE/i.test(s2)) return s2;
    }
    return null;
  },

  // ---------- LLM description (photo -> data: URL -> host LLM image input; dossier 2.9) ----------

  _blobToDataUrl(blob) {
    return new Promise(function (resolve, reject) {
      if (typeof FileReader === 'undefined') {
        reject(new Error('FileReader n/a on this host'));
        return;
      }
      var fr = new FileReader();
      fr.onload = function () { resolve(String(fr.result || '')); };
      fr.onerror = function () { reject(new Error('FileReader read failed')); };
      try { fr.readAsDataURL(blob); } catch (e) { reject(e); }
    });
  },

  _buildDescContent(dataUrl) {
    var instr = 'This photo shows one area of a room, seat or campsite ' +
      'that the wearer is leaving. Describe what is visible in ONE short ' +
      'line of at most 15 Chinese characters, mentioning whether doors, ' +
      'windows or appliances look closed and whether anything looks left ' +
      'behind. Reply in exactly this format:\nZONE: <one short line>\n' +
      'If nothing is clearly visible, reply with exactly: ZONE: NONE';
    return [
      { type: 'text', text: instr },
      { type: 'image_url', image_url: { url: dataUrl } }
    ];
  },

  async _llmDescribe(dataUrl) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return { ok: false, reason: 'no-lm' };
    var avail;
    try {
      avail = await LM.availability();
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    }
    if (avail !== 'available') return { ok: false, reason: 'unavailable' };
    var session = null;
    try {
      session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You describe one photo of a room area in one short line. Reply with only the requested line. Never invent details that are not visible.' }]
      });
      var ans = await this._withTimeout(session.prompt(this._buildDescContent(dataUrl)), 30000, 'llm describe');
      if (!ans || !String(ans).trim()) return { ok: false, reason: 'empty' };
      var v = this._parseZoneDesc(ans);
      if (v === null) return { ok: false, reason: 'unreadable' };
      return { ok: true, value: v };
    } catch (e) {
      return { ok: false, reason: 'error', error: e };
    } finally {
      if (session) { try { session.destroy(); } catch (e) {} }
    }
  },

  _readFailWhy(r) {
    return r.reason === 'no-lm' ? '这台设备没有大模型'
      : r.reason === 'unavailable' ? '大模型现在不可用'
      : r.reason === 'empty' ? '模型没有返回内容'
      : r.reason === 'unreadable' ? '照片里没看清'
      : '模型出错：' + this._err(r.error);
  },

  // ---------- capture (wide) + describe dispatch ----------

  snapTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode === 'done') {
      this.setData({ lastEvent: 'EVT: SNAP in done - REPLAY picks a zone first, then SNAP retakes it' });
      return;
    }
    var zoneIdx = this._mode === 'replay' ? this._replayIdx : this._focus;
    this.capturePhoto(zoneIdx);
  },

  async capturePhoto(zoneIdx) {
    if (this.data.busy) return;
    if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this._photoUnavailable(zoneIdx, '这台设备没有可用相机', 'mediaDevices n/a on this host');
      return;
    }
    this.setData({
      busy: true,
      status: 'SNAPPING (wide) ' + this._zoneNames()[zoneIdx] + '区...'
    });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      if (typeof ImageCapture === 'undefined') throw new Error('ImageCapture n/a');
      var cap = new ImageCapture(track);
      var blob = await this._withTimeout(cap.takePhoto({ mode: 'wide' }), 9000, 'wide photo');
      var bytes = blob && blob.size ? blob.size : 0;
      this._pending = {
        zoneIdx: zoneIdx, blob: blob, bytes: bytes, wxPhoto: false,
        desc: '', src: 'LLM', readState: 'reading', failWhy: ''
      };
      this.setData({
        capLine: 'CAP: ' + bytes + 'B wide · memory only, NOT saved',
        status: '照片已拍 — 正在读它写一句描述...',
        lastEvent: 'EVT: wide photo ' + bytes + 'B for zone ' + this._zoneNames()[zoneIdx] + ' (memory only, never persisted)'
      });
      this._renderAll();
    } catch (e) {
      var firstErr = e;
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e2) {}
        stream = null; this._stream = null;
      }
      try {
        var ctx = (typeof wx !== 'undefined' && wx.media && wx.media.createCameraContext)
          ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this._pending = {
          zoneIdx: zoneIdx, blob: null, bytes: size, wxPhoto: true,
          desc: '', src: 'MANUAL', readState: 'fail',
          failWhy: 'wx 回退照片无法转成图片发给模型'
        };
        this.setData({
          capLine: 'CAP: ' + size + 'B wx cam (fallback) · memory only',
          status: '这张照片读不了描述 — OK 照样存档为「已拍·未读出描述」',
          lastEvent: 'EVT: wx photo ' + size + 'B (fallback, no Blob - image read n/a)'
        });
        this._renderAll();
      } catch (e3) {
        this._photoUnavailable(zoneIdx, '拍照失败：' + this._err(firstErr), this._err(firstErr));
      }
    } finally {
      if (stream) {
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
    if (this._pending && this._pending.blob) {
      await this._doDescribe();
    }
  },

  _photoUnavailable(zoneIdx, why, errText) {
    this._pending = {
      zoneIdx: zoneIdx, blob: null, bytes: 0, wxPhoto: false,
      desc: '', src: 'MANUAL', readState: 'fail', failWhy: why
    };
    this.setData({
      capLine: 'CAP: FAIL - ' + errText,
      status: '拍照不可用 — OK 照样存档为「已拍·未读出描述」',
      lastEvent: 'EVT: SNAP FAIL (' + errText + ') - keep-as-photographed path offered'
    });
    this._renderAll();
  },

  async _doDescribe() {
    var p = this._pending;
    if (!p || !p.blob || this.data.busy) return;
    this.setData({ busy: true, status: 'READING (host AI, image in)...' });
    try {
      var dataUrl;
      try {
        dataUrl = await this._withTimeout(this._blobToDataUrl(p.blob), 12000, 'convert');
      } catch (ce) {
        this._describeFailed('照片转图片数据失败：' + this._err(ce), 'conversion FAIL - ' + this._err(ce));
        return;
      }
      if (!dataUrl || dataUrl.indexOf('data:') !== 0) {
        this._describeFailed('照片转换没有得到 data: URL', 'conversion FAIL - not a data: URL');
        return;
      }
      var r = await this._llmDescribe(dataUrl);
      if (!r.ok) {
        this._describeFailed(this._readFailWhy(r), 'DESCRIBE FAIL (' + r.reason + ')');
        return;
      }
      p.desc = r.value;
      p.src = 'LLM';
      p.readState = 'ok';
      this.setData({
        status: '读到了 — 核对这句描述：对了 OK 存档，错了 DEL 重拍',
        lastEvent: 'EVT: LLM zone description ok - machine read, NOT archived yet'
      });
      this._renderAll();
    } finally {
      this.setData({ busy: false });
    }
  },

  _describeFailed(why, evt) {
    var p = this._pending;
    if (p) { p.readState = 'fail'; p.failWhy = why; }
    this.setData({
      status: '描述没读出来（' + why + '）— OK 照样存档为「已拍·未读出描述」，或 SNAP 重拍',
      lastEvent: 'EVT: ' + evt + ' - keep-as-photographed offered'
    });
    this._renderAll();
  },
  // ---------- confirm gate: the ONLY way a photo becomes an archive entry ----------

  _confirmZone() {
    var p = this._pending;
    if (!p) return;
    var desc = p.readState === 'ok' && p.desc ? p.desc : '已拍·未读出描述';
    var src = p.readState === 'ok' ? p.src : 'MANUAL-KEPT';
    var idx = p.zoneIdx;
    this._zones[idx] = { desc: desc, src: src, photo: true };
    this._pending = null;
    this._disarm();
    if (this._allDone()) {
      this._mode = 'done';
      this._speakText('六个区都存档了，可以离开了');
      this.setData({
        status: '6/6 全亮 ✓ 可以离开 — 路上焦虑时 REPLAY 回放任何一区',
        lastEvent: 'EVT: archive complete 6/6 - all zones confirmed, summary shown'
      });
    } else {
      var next = this._firstMissing();
      this._focus = next;
      if (this._mode === 'replay') {
        // Retaking inside replay: the zone is fixed, stay in replay
        // on that same zone so the wearer sees the new description.
        this._replayIdx = idx;
        this.setData({
          status: '已重拍存档：' + this._zoneNames()[idx] + '区 — ' + desc,
          lastEvent: 'EVT: zone ' + this._zoneNames()[idx] + ' retaken in replay (' + src + ')'
        });
      } else {
        this.setData({
          status: '已存档：' + this._zoneNames()[idx] + '区 — ' + desc + '（还差 ' + (6 - this._countDone()) + ' 区）',
          lastEvent: 'EVT: zone ' + this._zoneNames()[idx] + ' archived (' + src + ') - focus moves to next missing zone'
        });
      }
    }
    this._renderAll();
  },

  _discardPending(how) {
    this._pending = null;
    this.setData({
      capLine: 'CAP: none - SNAP takes a wide photo (memory only)',
      status: '已放弃这次拍照（它本来就没存档）',
      lastEvent: 'EVT: pending photo discarded by ' + how + ' - it was never archived'
    });
    this._renderAll();
  },

  _disarm() {
    this._newArm = false;
    if (this._armTimer) { try { clearTimeout(this._armTimer); } catch (e) {} this._armTimer = null; }
  },

  _armNew() {
    this._disarm();
    this._newArm = true;
    var self = this;
    this._armTimer = setTimeout(function () {
      self._armTimer = null;
      if (self._newArm) {
        self._newArm = false;
        self.setData({ lastEvent: 'EVT: new sweep disarmed (timeout) - archive kept' });
        self._renderAll();
      }
    }, 6000);
  },

  _clearArchive() {
    this._zones = [null, null, null, null, null, null];
    this._pending = null;
    this._focus = 0;
    this._replayIdx = 0;
    this._demoStage = 0;
    this._disarm();
    this._mode = 'sweep';
    this.setData({
      capLine: 'CAP: none - SNAP takes a wide photo (memory only)',
      status: '存档已清空 — 重新环视一周',
      lastEvent: 'EVT: archive cleared by two-step DEL - session memory wiped'
    });
    this._renderAll();
  },

  // ---------- OK / DEL / navigation / replay ----------

  okTap() {
    if (this.data.busy) return;
    if (this._mode === 'sweep' && this._pending) { this._confirmZone(); return; }
    if (this._mode === 'done') { this.replayTap(); return; }
    if (this._mode === 'replay') {
      // Replay can be entered from a partial sweep too: go back to
      // wherever it came from, never fake a 6/6 summary.
      if (this._replayFrom === 'done') {
        this._mode = 'done';
        this.setData({
          status: '6/6 全亮 ✓ 可以离开 — 路上焦虑时 REPLAY 回放任何一区',
          lastEvent: 'EVT: replay -> done summary'
        });
      } else {
        this._mode = 'sweep';
        this._focus = this._replayIdx;
        this.setData({
          status: '回放结束 — 回到环视，继续补拍未拍的区',
          lastEvent: 'EVT: replay -> sweep (archive was partial)'
        });
      }
      this._renderAll();
      return;
    }
    this.setData({
      status: '先 SNAP 拍当前区，或 DEMO 看演示',
      lastEvent: 'EVT: OK in sweep - nothing pending to confirm yet'
    });
    this._renderAll();
  },

  delTap() {
    if (this.data.busy) return;
    if (this._mode === 'sweep' && this._pending) { this._discardPending('DEL'); return; }
    if (this._mode === 'replay') {
      if (this._replayFrom === 'done') {
        this._mode = 'done';
        this.setData({
          status: '6/6 全亮 ✓ 可以离开 — 路上焦虑时 REPLAY 回放任何一区',
          lastEvent: 'EVT: replay -> done summary (DEL)'
        });
      } else {
        this._mode = 'sweep';
        this._focus = this._replayIdx;
        this.setData({
          status: '回放结束 — 回到环视，继续补拍未拍的区',
          lastEvent: 'EVT: replay -> sweep (DEL, archive was partial)'
        });
      }
      this._renderAll();
      return;
    }
    if (this._mode === 'done') {
      if (this._newArm) { this._clearArchive(); return; }
      this._armNew();
      this.setData({
        status: '⚠ 再点一次 DEL 清空存档重新环视（其他动作取消）',
        lastEvent: 'EVT: new sweep 1/2 - ARMED (archive still kept)'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEL - nothing to discard in this state' });
  },

  nextTap() {
    if (this.data.busy) return;
    if (this._mode === 'sweep') {
      this._disarm();
      this._focus = (this._focus + 1) % 6;
      this.setData({ lastEvent: 'EVT: focus -> ' + this._zoneNames()[this._focus] + '区' });
      this._renderAll();
      return;
    }
    if (this._mode === 'replay') {
      this._replayIdx = (this._replayIdx + 1) % 6;
      this.setData({ lastEvent: 'EVT: replay -> ' + this._zoneNames()[this._replayIdx] + '区' });
      this._renderAll();
      return;
    }
    this._disarm();
    this.setData({ lastEvent: 'EVT: NEXT - use REPLAY to browse zones from the summary' });
  },

  prevTap() {
    if (this.data.busy) return;
    if (this._mode === 'sweep') {
      this._disarm();
      this._focus = (this._focus + 5) % 6;
      this.setData({ lastEvent: 'EVT: focus -> ' + this._zoneNames()[this._focus] + '区' });
      this._renderAll();
      return;
    }
    if (this._mode === 'replay') {
      this._replayIdx = (this._replayIdx + 5) % 6;
      this.setData({ lastEvent: 'EVT: replay -> ' + this._zoneNames()[this._replayIdx] + '区' });
      this._renderAll();
      return;
    }
    this._disarm();
    this.setData({ lastEvent: 'EVT: PREV - use REPLAY to browse zones from the summary' });
  },

  replayTap() {
    if (this.data.busy) return;
    this._disarm();
    if (this._mode === 'replay') {
      this.setData({ lastEvent: 'EVT: REPLAY - already replaying, NEXT/PREV browse zones' });
      return;
    }
    var first = this._firstDone();
    if (first < 0) {
      this.setData({ lastEvent: 'EVT: REPLAY - no zone archived yet, SNAP one first' });
      return;
    }
    this._replayFrom = this._mode;
    this._mode = 'replay';
    this._replayIdx = first;
    this.setData({
      status: '回放中 — NEXT/PREV 换区，SNAP 重拍当前区，DEL 回小结',
      lastEvent: 'EVT: replay entered at zone ' + this._zoneNames()[first]
    });
    this._renderAll();
  },

  // ---------- SPEAK ----------

  _speakText(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return false;
      }
      if (!text) return false;
      // No utterance.lang is ever set: the host does not honour it
      // (dossier section 2.6). This is synthetic speech, a readback.
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
      return false;
    }
  },

  speakTap() {
    if (this._mode === 'sweep' && this._pending) {
      var p = this._pending;
      var t = p.readState === 'ok'
        ? '待核对：' + this._zoneNames()[p.zoneIdx] + '区，' + p.desc + '。对了按 OK 存档，还没存。'
        : '还没读出描述：' + (p.failWhy || '原因不明') + '。按 OK 照样存档为已拍。';
      if (this._speakText(t)) this.setData({ lastEvent: 'EVT: SPEAK pending zone (TTS, no lang set)' });
      return;
    }
    if (this._mode === 'sweep') {
      var z = this._zones[this._focus];
      var line = z
        ? '当前区' + this._zoneNames()[this._focus] + '已存档：' + z.desc + '。'
        : '当前区' + this._zoneNames()[this._focus] + '还没拍。已存档 ' + this._countDone() + ' 区，还差 ' + (6 - this._countDone()) + ' 区。';
      if (this._speakText(line)) this.setData({ lastEvent: 'EVT: SPEAK focus zone (TTS, no lang set)' });
      return;
    }
    if (this._mode === 'replay') {
      var rz = this._zones[this._replayIdx];
      var rline = rz
        ? '回放' + this._zoneNames()[this._replayIdx] + '区：' + rz.desc + '。照片已存。'
        : '回放' + this._zoneNames()[this._replayIdx] + '区：这一区没拍。';
      if (this._speakText(rline)) this.setData({ lastEvent: 'EVT: SPEAK replay zone (TTS, no lang set)' });
      return;
    }
    if (this._mode === 'done') {
      if (this._speakText('六个区都存档了，可以离开了。路上焦虑时按 REPLAY 回放任何一区。')) {
        this.setData({ lastEvent: 'EVT: SPEAK done summary (TTS, no lang set)' });
      }
      return;
    }
  },

  // ---------- DEMO (two stages; never overwrites real archives) ----------

  demoTap() {
    if (this.data.busy) return;
    if (this._hasReal()) {
      this.setData({ lastEvent: 'EVT: DEMO - a real archive exists, DEMO never overwrites it' });
      return;
    }
    if (this._mode !== 'sweep') {
      this.setData({ lastEvent: 'EVT: DEMO - demo runs from the sweep screen only' });
      return;
    }
    if (this._pending) {
      this.setData({ lastEvent: 'EVT: DEMO - confirm or discard the pending photo first' });
      return;
    }
    var descs = this._demoDescs();
    if (this._demoStage === 0) {
      this._zones[0] = { desc: descs[0], src: 'DEMO', photo: true };
      this._zones[1] = { desc: descs[1], src: 'DEMO', photo: true };
      this._focus = 2;
      this._demoStage = 1;
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated zone descriptions (not real photos)',
        status: 'DEMO - 已模拟存档 2 区：前、右前 — 再点 DEMO 存满 6 区',
        lastEvent: 'EVT: DEMO stage 1 - 2 zones simulated (memory only)'
      });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      for (var i = 2; i < 6; i++) {
        this._zones[i] = { desc: descs[i], src: 'DEMO', photo: true };
      }
      this._mode = 'done';
      this._demoStage = 2;
      this._speakText('六个区都存档了，可以离开了');
      this.setData({
        capLine: 'CAP: DEMO - no camera used; simulated zone descriptions (not real photos)',
        status: 'DEMO - 6/6 全亮 ✓ 可以离开 — REPLAY 回放任何一区',
        lastEvent: 'EVT: DEMO stage 2 - all 6 zones simulated, summary shown'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo archive already complete, DEL twice clears it' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var names = this._zoneNames();
    var rows = [];
    for (var i = 0; i < 6; i++) {
      var z = this._zones[i];
      var pendingHere = this._pending && this._pending.zoneIdx === i;
      rows.push({
        name: names[i] + '区',
        detail: pendingHere
          ? (this._pending.readState === 'ok' ? '待核对：' + this._pending.desc : '待核对：照片已拍（' + (this._pending.failWhy || '未读出') + '）')
          : z ? z.desc : '○ 未拍',
        flag: pendingHere ? '待核对' : (z ? '✓' : ''),
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '已存档 ' + this._countDone() + '/6 · 只存本次会话内存 · 关掉即清 · 零落盘';

    if (this._mode === 'sweep') {
      var f = this._focus;
      var fz = this._zones[f];
      if (this._pending) {
        var p = this._pending;
        patch.boxLabel = p.readState === 'ok'
          ? '◎ 机器描述 — 可能看错，核对后再存档'
          : '◎ 描述没读出来 — OK 照样存档为已拍';
        patch.bigLabel = '待核对 · ' + names[p.zoneIdx] + '区';
        patch.bigText = p.readState === 'ok' ? p.desc : '已拍·未读出描述';
        patch.bigNote = p.readState === 'ok'
          ? 'OK 存档 · DEL 放弃重拍 · 点头（头稳）也可确认'
          : 'OK 存档为已拍 · DEL 放弃 · SNAP 重拍 · 原因：' + (p.failWhy || '');
      } else {
        patch.boxLabel = '◎ 环视进行中 — 没拍的区一眼就能看见';
        patch.bigLabel = '当前区 · ' + names[f] + '区';
        patch.bigText = fz ? fz.desc : '○ 未拍';
        patch.bigNote = fz
          ? '已存档 · NEXT/PREV 换区 · SNAP 重拍本区'
          : 'SNAP 拍当前区 / DEMO 演示（模拟描述）';
      }
    } else if (this._mode === 'done') {
      patch.boxLabel = '◎ 6/6 全亮 — 可以离开';
      patch.bigLabel = '离开小结';
      patch.bigText = '可以离开';
      patch.bigNote = this._newArm
        ? '⚠ 再点一次 DEL 清空存档重新环视'
        : 'REPLAY 回放任何一区 · DEL 两下清空重拍';
    } else if (this._mode === 'replay') {
      var ri = this._replayIdx;
      var rz = this._zones[ri];
      patch.boxLabel = '◎ 回放中 — 描述是回放本体，照片只是存档凭证';
      patch.bigLabel = '回放 · ' + names[ri] + '区';
      patch.bigText = rz ? rz.desc : '○ 这一区没拍';
      patch.bigNote = rz
        ? '照片已存（会话内存）· NEXT/PREV 换区 · SNAP 重拍本区 · DEL 回小结'
        : '这一区没拍 — NEXT/PREV 换区，或回环视补拍';
    }
    patch.bigCls = this._bigClsFor(patch.bigText);
    this.setData(patch);
  },

  _bigClsFor(displayStr) {
    var n = String(displayStr || '').length;
    if (n <= 6) return 'bignum';
    if (n <= 13) return 'bignum-sm';
    return 'bignum-xs';
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">LAST GLANCE v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{capLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="snapTap">SNAP</button>
      <button class="btn btn-main" bindtap="okTap">OK ✓</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="prevTap">PREV</button>
      <button class="btn" bindtap="replayTap">REPLAY</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="delTap">DEL</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">回放是文字描述，不是照片回放 · 区来自环视顺序，无房间地图 · 只记这次离开，关掉即清</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 2px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 1px;
}
.title {
  color: #40ff5e;
  font-size: 19px;
  font-weight: 500;
  line-height: 20px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 14px;
}
.info-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 3px 8px;
  margin-bottom: 3px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.biglabel {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 15px;
  margin-top: 1px;
}
.bignum {
  color: #40ff5e;
  font-size: 34px;
  font-weight: 500;
  line-height: 38px;
  margin-top: 1px;
}
.bignum-sm {
  color: #40ff5e;
  font-size: 24px;
  font-weight: 500;
  line-height: 28px;
  margin-top: 1px;
}
.bignum-xs {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 21px;
  margin-top: 1px;
}
.bignote {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 14px;
  margin-top: 1px;
}
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 2px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 1px;
  font-size: 11px;
  font-weight: 500;
  line-height: 16px;
  text-align: center;
}
.btn-main {
  color: #40ff5e;
  border-color: rgba(64,255,94,0.72);
  background-color: rgba(64,255,94,0.12);
}
.list {
  flex-shrink: 0;
  height: 45px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.18);
}
.rname {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-right: 8px;
}
.rdetail {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 15px;
  flex-grow: 1;
}
.rflag {
  color: #40ff5e;
  font-size: 11px;
  line-height: 15px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 12px;
  margin-top: 1px;
}
.foot2 {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 12px;
}
</style>
