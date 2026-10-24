<script def>
{
  "navigationBarTitleText": "Snack Aware"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: '零食觉察 — 无意识吃零食：一边忙一边伸手，回过神一包没了：看向零食停稳时先亮「这是今天第几次」，计数外包给它，吃不吃你决定，它只负责让你看见',
    steadyText: 'HEAD: moving - nod confirms only on steady gaze',
    boxLabel: '◎ 零食觉察 — REG 登记零食，LOOK 看向计数，END 出小结',
    bigLabel: '零食觉察 · 待机',
    bigText: '还没登记',
    bigNote: '看向零食停稳时亮「这是今天第几次」· 只计数不干预',
    permLine: 'PERM: 无权限 — 方向传感器 + 计数 + 提醒；不拍照、不录音、不定位',
    rows: [],
    countLine: '看向零食 0 次 · 只计数不干预 · 吃不吃你决定 · 只存本次会话 · 关掉即清 · 零落盘',
    lastEvent: 'EVT: ready - REG registers the snack, LOOK counts a steady look, END closes with a summary',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._mode = 'idle'; // idle | watching | summary
    this._registered = false;
    this._snackYaw = null; // direction faced at registration, if the host delivered one
    this._lastYaw = null;
    this._looks = 0; // steady looks at the snack this session
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0; // 0 none, 1 registered, 2 look 1, 3 looks 3, 4 summary
    this._nodLock = false;
    this._renderAll();
  },

  onShow() {},

  onHide() {},

  onUnload() {
    // Session-only by construction: the registration, the
    // look count and the summary die with the page. Nothing
    // was ever written anywhere persistent, so there is
    // nothing to clean up — that IS the design.
    this._mode = 'idle';
    this._registered = false;
    this._snackYaw = null;
    this._lastYaw = null;
    this._looks = 0;
    this._focus = 0;
    this._summary = null;
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
    // not take effect. A look never speaks: the banner is
    // silent by design, and only an explicit SPEAK tap reads
    // a count aloud.
    try {
      var u = new SpeechSynthesisUtterance(text);
      speechSynthesis.speak(u);
    } catch (e) {
      this.setData({ lastEvent: 'EVT: speak unavailable here - ' + this._err(e) });
    }
  },

  onOrientationStabilityChange(event) {
    var d = (event && event.detail) || event || {};
    this._steady = !!(d.isStable === true || d.stable === true);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY - ready' : 'HEAD: moving - nod confirms only on steady gaze'
    });
  },

  onOrientationChange(event) {
    // Direction memory only: the latest delivered yaw is kept
    // so REG can record the direction faced at registration.
    // A look is confirmed by a steady gaze (LOOK), not by a
    // yaw comparison — the page never pretends it can verify
    // you are really looking at the snack.
    var d = (event && event.detail) || event || {};
    var yaw = d.yaw;
    if (yaw === undefined || yaw === null) yaw = d.eulerZ;
    if (yaw === undefined || yaw === null) yaw = d.z;
    if (typeof yaw === 'number') this._lastYaw = yaw;
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
    // Nod discipline in THIS agent: a steady nod registers
    // the snack in idle and confirms the summary. A nod never
    // counts a look: a look is a steady gaze at the snack,
    // and counting a nod as a look would be a lie about what
    // you did.
    if (this._mode === 'idle') { this.regTap(); return; }
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: nod ignored - a nod is not a look at the snack, a steady gaze counts' });
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
      if (this._mode === 'idle') this.regTap();
      else if (this._mode === 'watching') this.lookTap();
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

  // ---------- register / look / end ----------

  regTap() {
    if (this._mode === 'watching') {
      this.setData({ lastEvent: 'EVT: REG refused - snack already registered, LOOK counts a steady look' });
      return;
    }
    if (this._mode === 'summary') {
      this.setData({ lastEvent: 'EVT: REG refused - a summary is open, END confirms it first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: REG refused - look toward the snack and hold steady first' });
      return;
    }
    this._registered = true;
    this._snackYaw = this._lastYaw;
    this._mode = 'watching';
    this.setData({
      status: '守望中 — 零食已登记' + (this._snackYaw !== null ? '（方向 ' + this._snackYaw + '°）' : '') + '，看向零食停稳时亮次数',
      lastEvent: 'EVT: snack registered - watching, looks 0'
    });
    this._renderAll();
  },

  lookTap() {
    if (this._mode !== 'watching') {
      this.setData({ lastEvent: 'EVT: LOOK ignored - REG registers the snack first' });
      return;
    }
    if (!this._steady) {
      this.setData({ lastEvent: 'EVT: LOOK refused - look toward the snack and hold steady to count' });
      return;
    }
    // The count, and nothing else: no judgement, no advice,
    // no spoken interruption. The banner shows the count;
    // whether you eat is your decision.
    this._looks++;
    this.setData({
      status: '这是今天第 ' + this._looks + ' 次 — 看向零食停稳，吃不吃你决定，它只负责让你看见',
      lastEvent: 'EVT: look counted - looks ' + this._looks + ' (silent banner, zero TTS)'
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
      this.setData({ lastEvent: 'EVT: END refused - missing: 先 REG 登记零食' });
      return;
    }
    this._mode = 'summary';
    this._summary = {
      looks: this._looks,
      registered: this._registered
    };
    this.setData({
      status: '结束 — 今天看向零食 ' + this._looks + ' 次，点 END 确认清空，BACK 回守望',
      lastEvent: 'EVT: closed - looks ' + this._looks
    });
    this._renderAll();
  },

  _confirmSummary() {
    if (this._mode !== 'summary') {
      this.setData({ lastEvent: 'EVT: confirm refused - no summary open' });
      return;
    }
    this._mode = 'idle';
    this._registered = false;
    this._snackYaw = null;
    this._lastYaw = null;
    this._looks = 0;
    this._focus = 0;
    this._summary = null;
    this._demo = false;
    this._demoStage = 0;
    this.setData({
      status: '零食觉察 — REG 再次登记零食',
      lastEvent: 'EVT: summary confirmed - session cleared'
    });
    this._renderAll();
  },

  backTap() {
    if (this._mode === 'summary') {
      // Back from the summary returns to watching without
      // deleting anything; the summary is rebuilt on END.
      this._mode = 'watching';
      this._summary = null;
      this.setData({
        status: '守望中 — BACK 回到守望，计数保留',
        lastEvent: 'EVT: back to watching - summary kept for rebuild on END'
      });
      this._renderAll();
      return;
    }
    if (this._mode === 'watching') {
      // Back to idle keeps the session; REG resumes the same
      // session instead of resetting it.
      this._mode = 'idle';
      this.setData({
        status: '零食觉察 — 守望已停未清，REG 恢复同一轮',
        lastEvent: 'EVT: back to idle - session kept'
      });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: back ignored - REG registers the snack' });
  },

  _focusLen() {
    return 3; // the three info rows exist in every mode
  },

  nextTap() {
    this._focus = (this._focus + 1) % 3;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (this._focus + 1) });
  },

  prevTap() {
    this._focus = (this._focus - 1 + 3) % 3;
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
    if (idx < 0 || idx >= 3) return;
    this._focus = idx;
    this._renderAll();
    this.setData({ lastEvent: 'EVT: focus -> ' + (idx + 1) });
  },

  speakTap() {
    var line = '';
    if (this._mode === 'idle') {
      line = '还没登记：REG 登记零食';
    } else if (this._mode === 'watching') {
      line = '这是今天第 ' + this._looks + ' 次';
    } else if (this._summary) {
      line = '本次小结：今天看向零食 ' + this._summary.looks + ' 次';
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
    if (this._mode === 'idle' && !this._demo && (this._registered || this._looks > 0)) {
      this.setData({ lastEvent: 'EVT: DEMO refused - a user session is under way' });
      return;
    }
    if (this._demoStage === 0) {
      this._demo = true;
      this._demoStage = 1;
      // DEMO is a staged sample, not a live watch: the
      // steady flag and the direction are staged too, so the
      // preview frames are deterministic.
      this._steady = true;
      this.setData({ steadyText: 'HEAD STEADY - ready' });
      this._lastYaw = 30;
      this.regTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 1 - snack registered, watching, looks 0 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 1) {
      this._demoStage = 2;
      this.lookTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 2 - steady look, this is look 1 today (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 2) {
      this._demoStage = 3;
      this.lookTap();
      this.lookTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 3 - two more steady looks, looks 3 (DEMO sample)' });
      this._renderAll();
      return;
    }
    if (this._demoStage === 3) {
      this._demoStage = 4;
      this.endTap();
      this.setData({ lastEvent: 'EVT: DEMO stage 4 - summary: looks 3 (DEMO sample)' });
      this._renderAll();
      return;
    }
    this.setData({ lastEvent: 'EVT: DEMO - demo already complete, confirm the summary to clear' });
  },

  // ---------- rendering ----------

  _renderAll() {
    var rows = [];
    rows.push({
      idx: 0,
      name: '零食位置',
      detail: this._registered ? ('已登记' + (this._snackYaw !== null ? ' · 方向 ' + this._snackYaw + '°' : '')) : '还没登记',
      flag: (this._focus === 0 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 1,
      name: '今天第几次',
      detail: this._looks + ' 次（看向零食停稳算一次）',
      flag: (this._focus === 1 ? '▶' : '●'),
      cls: 'row'
    });
    rows.push({
      idx: 2,
      name: '本次会话',
      detail: '只计数不干预 · 吃不吃你决定 · 关掉即清',
      flag: (this._focus === 2 ? '▶' : '●'),
      cls: 'row'
    });

    var patch = { rows: rows };
    patch.countLine = '看向零食 ' + this._looks + ' 次 · 只计数不干预 · 吃不吃你决定 · 只存本次会话 · 关掉即清 · 零落盘';

    if (this._mode === 'idle') {
      patch.boxLabel = '◎ 零食觉察 — REG 登记零食，LOOK 看向计数，END 出小结';
      patch.bigLabel = '零食觉察 · 待机';
      patch.bigText = (this._registered || this._looks > 0) ? '守望已停未清' : '还没登记';
      patch.bigNote = '看向零食停稳时亮「这是今天第几次」· 只计数不干预';
    } else if (this._mode === 'watching') {
      patch.boxLabel = '◎ 这是今天第 ' + this._looks + ' 次 — 吃不吃你决定，它只负责让你看见';
      patch.bigLabel = '零食觉察 · 守望中';
      patch.bigText = this._looks === 0 ? '还没看向' : '第 ' + this._looks + ' 次';
      patch.bigNote = '看向零食停稳算一次 · 只计数不干预 · 不出声打断';
    } else {
      patch.boxLabel = '◎ 本次小结 — 今天看向零食几次钉在下面';
      patch.bigLabel = '本次小结';
      var sm = this._summary || { looks: 0 };
      patch.bigText = '看向 ' + sm.looks + ' 次';
      patch.bigNote = '只计数不干预 · 点 END 确认清空 · BACK 回守望';
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
      <text class="title">SNACK AWARE v1.0.0</text>
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
      <button class="btn btn-main" bindtap="regTap">REG</button>
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
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
    <text class="foot2">看向零食不等于吃了——计的是你看向零食并停稳的次数，不是真的吃了几口、几包 · 只计数不干预：不阻止、不评判、不给饮食建议，不是健康管理工具 · 零食位置是你登记时面向的方向，不是定位追踪，零食挪了位置要重新登记 · 「今天第几次」是指本次会话内的次数，不是跨天累计 · 只存本次会话，关掉即清 · 没有室内定位，没有摄像头 · 零落盘</text>
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
