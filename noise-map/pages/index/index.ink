<script def>
{
  "navigationBarTitleText": "Noise Map"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '噪音方位图 — 在家/办公室找最安静的角落办公，凭感觉选总是选错：转头扫描一周，电平 × 头部朝向生成噪音方位图，指出最安静的朝向',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 噪音方位图 — SCAN 扫一个扇区，RESCAN 重扫，END 出小结',
    bigLabel: '噪音方位图 · 待机',
    bigText: '还没开始',
    bigNote: '顺时针转头，每转到一个方向点 SCAN · 扫满 8 个扇区成图并报最安静的朝向',
    permLine: 'PERM: RECORD_AUDIO — 扫描电平；不拍照、不定位',
    rows: [],
    countLine: '扫描 0/8 · 已成图 0 轮 · 最安静：还没成图 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - START begins a scan, SCAN records one sector level, RESCAN repeats, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | scanning | map | summary
    this._sectors = [null, null, null, null, null, null, null, null]; // low | mid | high per sector
    this._scanned = 0; // sectors recorded this round
    this._rounds = 0; // completed maps this session
    this._quietest = null; // sector name of the quietest direction, or null
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 scanning 4/8, 2 map complete, 3 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: sectors, maps, rounds and
    // the quietest direction die with the page. Nothing was
    // ever written anywhere persistent.
    this._mode = 'idle';
    this._sectors = [null, null, null, null, null, null, null, null];
    this._scanned = 0;
    this._rounds = 0;
    this._quietest = null;
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0;
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 70);
  },

  _speakText(text) {
    // TTS via the host voice. The utterance language attribute
    // is never set: the documented behaviour is that it does
    // not take effect. The quietest direction is announced
    // exactly once per completed map; SPEAK re-reads only on
    // an explicit tap.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  _sectorNames() {
    return ['前', '右前', '右', '右后', '后', '左后', '左', '左前'];
  },

  _levelText(level) {
    if (level === 'low') return '低';
    if (level === 'mid') return '中';
    if (level === 'high') return '高';
    return '未扫';
  },

  _levelRank(level) {
    if (level === 'low') return 0;
    if (level === 'mid') return 1;
    return 2;
  },

  _gradeRms(rms) {
    // Relative grades, NOT decibels: the platform has no
    // calibrated sound-pressure meter, and the README says
    // so. Thresholds are fixed grades.
    if (rms < 0.15) return 'low';
    if (rms < 0.4) return 'mid';
    return 'high';
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - nod confirms only on steady gaze'
    });
  },

  onHeadGesture(event) {
    var d = (event && event.detail) || event || {};
    var g = d.gesture || d.type || d.name || '';
    if (g !== 'nod') {
      if (g) this.setData({ lastEvent: 'EVT: head gesture ' + g + ' (nod only)' });
      return;
    }
    if (this.data.busy || this._nodLock) return;
    if (!this._steady) {
      // An unsteady nod never arms the lock: a shaky head must
      // not eat the next, steady nod.
      this.setData({ lastEvent: 'EVT: nod ignored - hold steady first' });
      return;
    }
    this._nodLock = true;
    var self = this;
    setTimeout(function () { self._nodLock = false; }, 1200);
    // Nod discipline in THIS agent: a steady nod starts a
    // scan in idle and confirms the summary. A nod never
    // records a sector level and never completes a map: a
    // level comes from the microphone, a map from 8 recorded
    // sectors — a nod must not invent either.
    if (this._mode === 'idle') { this.startTap(); return; }
    if (this._mode === 'scanning') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a sector level, SCAN records it' });
      return;
    }
    if (this._mode === 'map') {
      this.setData({ lastEvent: 'EVT: nod ignored - a map is open, RESCAN repeats or END closes' });
      return;
    }
    if (this._mode === 'summary') { this._confirmSummary(); return; }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && (event.code || event.key);
    if (code === 'Enter' || code === 'GlobalHook') {
      if (this._mode === 'idle') this.startTap();
      else if (this._mode === 'scanning') this.scanTap();
      else if (this._mode === 'map') this.rescanTap();
      else if (this._mode === 'summary') this._confirmSummary();
    } else if (code === 'ArrowUp') {
      this.nextTap();
    } else if (code === 'ArrowDown') {
      this.prevTap();
    } else if (code === 'Backspace') {
      this.backTap();
    }
  },

  onKeyUp(event) {
    var code = event && (event.code || event.key);
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter' || code === 'GlobalHook' || code === 'Backspace') {
      if (event && typeof event.preventDefault === 'function') event.preventDefault();
    }
  },

  // ---------- start / scan / rescan / end ----------

  startTap() {
    if (this._mode === 'scanning') {
      this.setData({ lastEvent: 'EVT: START refused - already scanning, SCAN records the next sector' });
      return;
    }
    if (this._mode === 'map') {
      this.setData({ lastEvent: 'EVT: START refused - a map is open, RESCAN repeats or END closes' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: START refused - a summary is open, END confirms it first' });
      return;
    }
    this._mode = 'scanning';
    this.setData({
      status: '扫描中 — 顺时针转头，每转到一个方向点 SCAN，扫满 8 个扇区成图',
      lastEvent: 'EVT: scan started - turn clockwise, SCAN records one sector at a time'
    });
    this._renderAll();
  },

  async scanTap() {
    if (this._mode !== 'scanning') {
      this.setData({ lastEvent: 'EVT: SCAN ignored - START begins a scan first' });
      return;
    }
    // Real sample path: one mic level at the current head
    // direction. The sector order is clockwise (front, front
    // right, right, ...): you turn right one sector per tap,
    // and the agent records in that order — it does not
    // verify your yaw angle, and the README says so.
    try {
      if (typeof navigator === 'undefined' || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('mic n/a on this host');
      }
      var stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      var Ctx = window.AudioContext || window.webkitAudioContext;
      var ctx = new Ctx();
      var src = ctx.createMediaStreamSource(stream);
      var analyser = ctx.createAnalyser();
      src.connect(analyser);
      var buf = new Uint8Array(analyser.fftSize);
      var self = this;
      setTimeout(function () {
        try {
          analyser.getByteTimeDomainData(buf);
          var sum = 0;
          for (var i = 0; i < buf.length; i++) {
            var v = (buf[i] - 128) / 128;
            sum += v * v;
          }
          var rms = Math.sqrt(sum / buf.length);
          self._recordLevel(self._gradeRms(rms));
        } catch (e) {
          self.setData({ lastEvent: 'EVT: level sample failed - ' + self._err(e) + ' - DEMO shows a staged sample' });
        }
        try { stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        try { ctx.close(); } catch (e) {}
      }, 300);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: level sample failed - ' + this._err(e) + ' - DEMO shows a staged sample' });
    }
  },

  _recordLevel(level) {
    // The single seam for a sector level: the real mic path,
    // DEMO stages and the harness all land here, so the map
    // rule is tested once, not per path.
    if (this._mode !== 'scanning') return;
    if (this._scanned >= 8) return;
    this._sectors[this._scanned] = level;
    this._scanned++;
    if (this._scanned < 8) {
      this.setData({
        status: '扫描中 — 已扫 ' + this._scanned + '/8，继续顺时针转头点 SCAN',
        lastEvent: 'EVT: sector ' + this._sectorNames()[this._scanned - 1] + ' level ' + level + ' - ' + this._scanned + '/8'
      });
      this._renderAll();
      return;
    }
    // 8 sectors recorded: the map is complete. The quietest
    // direction is the lowest grade, first on ties, and it is
    // announced exactly once by voice.
    var best = 0;
    for (var i = 1; i < 8; i++) {
      if (this._levelRank(this._sectors[i]) < this._levelRank(this._sectors[best])) best = i;
    }
    this._quietest = this._sectorNames()[best];
    this._rounds++;
    this._mode = 'map';
    this._speakText('最安静的朝向是' + this._quietest);
    this.setData({
      status: '方位图已生成 — 最安静的朝向是' + this._quietest + '，RESCAN 重扫，END 出小结',
      lastEvent: 'EVT: map complete - quietest ' + this._quietest + ', rounds ' + this._rounds + ' (one TTS)'
    });
    this._renderAll();
  },

  rescanTap() {
    if (this._mode === 'scanning') {
      this.setData({ lastEvent: 'EVT: RESCAN refused - a scan is running, finish it first' });
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: RESCAN refused - START begins a scan first' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: RESCAN refused - a summary is open, END confirms it first' });
      return;
    }
    this._sectors = [null, null, null, null, null, null, null, null];
    this._scanned = 0;
    this._quietest = null;
    this._focus = 0;
    this._mode = 'scanning';
    this.setData({
      status: '重扫中 — 顺时针转头，每转到一个方向点 SCAN，扫满 8 个扇区成图',
      lastEvent: 'EVT: rescan started - previous map kept in rounds count ' + this._rounds
    });
    this._renderAll();
  },

  endTap() {
    if (this._mode === 'summary') {
      // In summary, END is the confirm: it wipes the session.
      // BACK is the way back without deleting.
      this._confirmSummary();
      return;
    }
    if (this._mode === 'idle') {
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 START 开始扫描' });
      return;
    }
    this._backMode = this._mode;
    this._mode = 'summary';
    this._summary = {
      rounds: this._rounds,
      quietest: this._quietest,
      scanned: this._scanned
    };
    this.setData({
      status: '结束 — 扫描成图 ' + this._rounds + ' 轮，最安静：' + (this._quietest || '还没成图') + '，点 END 确认清空，BACK 回去',
      lastEvent: 'EVT: closed - rounds ' + this._rounds + ' quietest ' + (this._quietest || 'none')
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._sectors = [null, null, null, null, null, null, null, null];
    this._scanned = 0;
    this._rounds = 0;
    this._quietest = null;
    this._focus = 0;
    this._summary = null;
    this._backMode = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '噪音方位图 — 下次找安静角落再 START 扫描一周',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to the mode it came
      // from without deleting anything; the summary is
      // rebuilt on END.
      this._mode = this._backMode || 'scanning';
      this._summary = null;
      this.setData({
        status: '回到扫描 — BACK 回来不删东西，小结待重建',
        lastEvent: 'EVT: back from summary - session kept'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'scanning' || this._mode === 'map') {
      // Back to idle keeps the session; START resumes the
      // same round instead of resetting it.
      this._mode = 'idle';
      this.setData({
        status: '噪音方位图 — 已停未清，START 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - START begins a scan first' });
  },

  _focusLen() {
    return 8; // the eight sector rows exist in every mode
  },

  nextTap() {
    this._focus = (this._focus + 1) % 8;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    this._focus = (this._focus - 1 + 8) % 8;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  rowTap(event) {
    var idx = 0;
    try {
      var ds = (event && event.currentTarget && event.currentTarget.dataset) || {};
      idx = parseInt(ds.idx, 10);
      if (isNaN(idx)) return; // missing dataset: keep focus, never jump to 0
    } catch (e) { return; }
    if (idx < 0 || idx >= 8) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没开始：START 扫描一周';
    } else if (this._mode === 'scanning') {
      line = '扫描中，已扫 ' + this._scanned + '/8 个扇区';
    } else if (this._mode === 'map') {
      line = '最安静的朝向是' + this._quietest;
    } else if (this._summary) {
      line = '本次小结：扫描成图 ' + this._summary.rounds + ' 轮，最安静：' + (this._summary.quietest || '还没成图');
    }
    this._speakText(line);
    this.setData({ lastEvent: 'EVT: speak - ' + line });
  },

  // ---------- DEMO (staged, labelled, never overwrites a user session) ----------

  demoTap() {
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
      return;
    }
    if (this._mode !== 'idle' && !this._demo) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is running' });
      return;
    }
    if (this._mode === 'idle' && !this._demo && (this._scanned > 0 || this._rounds > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    // Staged levels: only 左后 is low, so the quietest
    // direction is unambiguous: 左后.
    var staged = ['mid', 'high', 'mid', 'high', 'mid', 'low', 'mid', 'high'];
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      // DEMO is a staged sample, not a live scan: levels are
      // staged grades, not mic readings.
      this._mode = 'scanning';
      for (var i = 0; i < 4; i++) this._recordLevel(staged[i]);
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - scanning 4/8 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      for (var j = 4; j < 8; j++) this._recordLevel(staged[j]);
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - map complete, quietest 左后, one TTS (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - summary: rounds 1, quietest 左后 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    var names = this._sectorNames();
    for (var i = 0; i < 8; i++) {
      rows.push({
        idx: i,
        name: names[i],
        detail: this._levelText(this._sectors[i]) + (this._quietest === names[i] && this._mode === 'map' ? ' · 最安静' : ''),
        flag: (this._focus === i ? '▶' : '●'),
        cls: 'row'
      });
    }

    var patch = { rows: rows };
    patch.countLine = '扫描 ' + this._scanned + '/8 · 已成图 ' + this._rounds + ' 轮 · 最安静：' + (this._quietest || '还没成图') + ' · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 噪音方位图 — SCAN 扫一个扇区，RESCAN 重扫，END 出小结';
      patch.bigLabel = '噪音方位图 · 待机';
      patch.bigText = (this._scanned > 0 || this._rounds > 0) ? '已停未清' : '还没开始';
      patch.bigNote = '顺时针转头，每转到一个方向点 SCAN · 扫满 8 个扇区成图并报最安静的朝向';
    } else if (this._mode === 'scanning') {
      patch.boxLabel = '◎ 扫描中 — 已扫 ' + this._scanned + '/8';
      patch.bigLabel = '噪音方位图 · 扫描中';
      patch.bigText = '扫描 ' + this._scanned + '/8';
      patch.bigNote = '继续顺时针转头点 SCAN · 扫满 8 个扇区成图';
    } else if (this._mode === 'map') {
      patch.boxLabel = '◎ 方位图已生成 — 最安静的朝向是' + this._quietest;
      patch.bigLabel = '噪音方位图 · 成图';
      patch.bigText = '最安静：' + this._quietest;
      patch.bigNote = 'RESCAN 重扫 · END 出小结';
    } else {
      patch.boxLabel = '◎ 本次小结 — 扫描几轮、最安静朝向是哪钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { rounds: 0, quietest: null };
      patch.bigText = '成图 ' + sm.rounds + ' 轮';
      patch.bigNote = '最安静：' + (sm.quietest || '还没成图') + ' · 点 END 确认清空 · BACK 回去';
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
      <text class="title">NOISE MAP v1.0.0</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}}</text>
    </view>
    <view class="info-box">
      <text class="box-label">{{boxLabel}}</text>
      <text class="biglabel">{{bigLabel}}</text>
      <text class="{{bigCls}}">{{bigText}}</text>
      <text class="bignote">{{bigNote}}</text>
      <text class="photo">{{permLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="demoTap">DEMO</button>
      <button class="btn btn-main" bindtap="scanTap">SCAN</button>
      <button class="btn btn-main" bindtap="rescanTap">RESCAN</button>
      <button class="btn btn-main" bindtap="endTap">END</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="nextTap">NEXT</button>
      <button class="btn btn-main" bindtap="prevTap">PREV</button>
      <button class="btn" bindtap="backTap">BACK</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="{{item.cls}}" bindtap="rowTap" data-idx="{{item.idx}}">
        <text class="rname">{{item.name}}</text>
        <text class="rdetail">{{item.detail}}</text>
        <text class="rflag">{{item.flag}}</text>
      </view>
    </scroll-view>
    <text class="sub">{{countLine}}</text>
    <text class="foot">{{lastEvent}}</text>
    <text class="foot2">电平不等于识别——平台没有声音分类 API，电平高低只说明响不响，不知道是什么声音（说话声/空调声/施工声分不出来） · 电平是相对分级，不是分贝读数 · 最安静的朝向是本次扫描内的相对最低，不是绝对安静保证 · 收音模式只影响 getUserMedia 流的拾音，不改变宿主 ASR 的拾音 · 扇区按顺时针顺序记录，不单独验证每个方向角 · 只存本次会话，关掉即清 · 没有室内定位 · 零落盘</text>
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
  line-height: 28px;
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
  height: 80px;
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
