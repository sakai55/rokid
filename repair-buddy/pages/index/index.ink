<script def>
{
  "navigationBarTitleText": "Repair Buddy"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PICK A JOB - LOOK AT THE FAULT, HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    stepText: 'STEP: -/- (no plan yet)',
    jobText: '水龙头滴水',
    toolsLine: 'TOOLS: 活动扳手 · 十字螺丝刀 · 生料带 · 备用垫圈/阀芯',
    photoLine: 'PHOTO: not taken yet - telephoto, record only',
    partLine: 'PART: 零件完好 - clean it and refit, no new part needed',
    planHead: 'FIX PLAN - no plan yet (START or DEMO)',
    stepBody: 'Steps appear here one at a time. NEXT or nod advances, SPEAK reads the step aloud.',
    lastEvent: 'EVT: nod when steady = LOOK; during a plan, nod = NEXT',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._jobIdx = 0;
    this._partIdx = 0;
    this._plan = null; // { label, steps, check, closing, source }
    this._stepIdx = 0;
    this._planDone = false;
    this._checked = false;
    this._renderJob();
    this.setData({ lastEvent: 'EVT: pick the job, hold your head still, then START' });
  },

  onUnload() {
    if (this._stream) {
      try { this._stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
      this._stream = null;
    }
  },

  onOrientationStabilityChange(event) {
    if (event && event.stable) {
      this.setData({
        steadyText: 'HEAD STEADY - ready',
        status: this._plan && !this._planDone
          ? 'HEAD STEADY - nod = NEXT step'
          : 'HEAD STEADY - nod or tap LOOK'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still',
        status: 'PICK A JOB - LOOK AT THE FAULT, HOLD HEAD STEADY'
      });
    }
    this._steady = !!(event && event.stable);
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod' || this.data.busy) return;
    if (this._plan && !this._planDone) {
      this.nextStep();
    } else if (this._steady) {
      this.lookPhoto();
    } else {
      this.setData({ status: 'NOD IGNORED - hold head steady first' });
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp') {
      this.cycleJob(1);
    } else if (code === 'ArrowDown') {
      this.cycleJob(-1);
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._plan && !this._planDone) this.nextStep();
      else this.lookPhoto();
    } else if (code === 'Backspace') {
      this.setData({ lastEvent: 'EVT: Backspace back (host handles close)' });
    }
  },

  onKeyUp(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown' || code === 'Enter') {
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

  // Built-in job table: 4 common DIY jobs. The user PICKS the job -
  // nothing is diagnosed. Step 1 of every job is its safety action
  // (shut the water / steady the bike / check the screws first).
  // Gas work and mains electrical work are NOT in this table at all.
  _jobs() {
    return [
      {
        name: '水龙头滴水',
        tools: 'TOOLS: 活动扳手 · 十字螺丝刀 · 生料带 · 备用垫圈/阀芯',
        steps: [
          '先关总水阀（或台下角阀），再打开龙头放掉余水（安全第一）。',
          '撬开手柄上的装饰盖，拧下螺丝，取下手柄。',
          '用扳手逆时针拧下阀芯，记住拆下的方向和顺序。',
          '换上同规格新垫圈/阀芯（旧件磨损或开裂就别再装回）。',
          '按原顺序装回阀芯与手柄，螺丝拧到 snug 即可，别过紧。'
        ],
        check: 'CHECK: 慢慢开总水阀 → 看 1 分钟不滴 = 成功；还滴多半是阀座磨损。',
        closing: 'DONE - still dripping? Book a plumber - say: faucet valve seat worn.'
      },
      {
        name: '自行车掉链',
        tools: 'TOOLS: 一次性手套 · 纸巾 · （可选）撬胎棒',
        steps: [
          '先把车支稳（或倒置放平），让后轮离地能空转（安全第一）。',
          '右手把后拨变速调到最小飞轮档，给链条留松量。',
          '把脱落的链条先套回前牙盘的上半圈。',
          '一手扶链条贴住牙盘，一手慢慢向前转脚踏，链条自动归位。',
          '擦净链条上的油污，检查链条有没有扭曲或死节。'
        ],
        check: 'CHECK: 逐档变速、空转 10 圈不再掉 = 成功；总掉是链条拉长了。',
        closing: 'DONE - keeps dropping? Book a bike shop - say: chain worn / limit screws.'
      },
      {
        name: '马桶一直流水',
        tools: 'TOOLS: 活动扳手 · 毛巾 · 备用拍盖/进水阀（可选）',
        steps: [
          '先关马桶后面的进水角阀，再冲一次排空水箱（安全第一）。',
          '打开水箱盖，看水位是否高过溢水管口：高了先调低浮球。',
          '取下排水阀拍盖，检查密封胶圈：老化变形就换新。',
          '理顺拍盖链条：留 1-2 环余量，太长会卡住拍盖漏水。',
          '装回拍盖与箱盖，开进水阀，等水箱重新注满。'
        ],
        check: 'CHECK: 注满后等 2 分钟，无流水声、水位不降 = 成功。',
        closing: 'DONE - still running? Book a plumber - say: fill valve / flush seal.'
      },
      {
        name: '门把手松动',
        tools: 'TOOLS: 十字螺丝刀 · 内六角扳手（常见 3mm）',
        steps: [
          '先分清松动来源：把手晃、面板晃还是锁舌晃（无水电危险，先确认）。',
          '找把手下方或侧面的小顶丝，用内六角扳手拧紧。',
          '掀开装饰面板，对角交替拧紧面板的两颗固定螺丝。',
          '装回面板与把手，螺丝别过紧，以免滑丝。',
          '检查锁舌伸缩是否顺畅，卡涩就滴一滴润滑油。'
        ],
        check: 'CHECK: 开合门 5 次 + 轻拉把手，不晃不掉 = 成功。',
        closing: 'DONE - still loose? Book a locksmith - say: handle spindle stripped.'
      }
    ];
  },

  // What YOU see on the part in front of you - cycled by PART.
  // The photo never judges this; the wearer does.
  _parts() {
    return [
      { name: '零件完好', line: 'PART: 零件完好 - clean it and refit, no new part needed' },
      { name: '磨损', line: 'PART: 磨损 - refit to test, but get a new one ready' },
      { name: '裂了', line: 'PART: 裂了 - replace it, do NOT force it back in' }
    ];
  },

  _job() { return this._jobs()[this._jobIdx]; },

  _renderJob() {
    var j = this._job();
    this.setData({ jobText: j.name, toolsLine: j.tools });
  },

  _endPlan(note) {
    this._plan = null;
    this._planDone = false;
    this._checked = false;
    this._stepIdx = 0;
    this.setData({
      stepText: 'STEP: -/- (no plan yet)',
      planHead: 'FIX PLAN - no plan yet (START or DEMO)',
      stepBody: 'Steps appear here one at a time. NEXT or nod advances, SPEAK reads the step aloud.',
      lastEvent: 'EVT: ' + note
    });
  },

  cycleJob(dir) {
    var n = this._jobs().length;
    this._jobIdx = ((this._jobIdx + dir) % n + n) % n;
    this._partIdx = 0;
    this.setData({ partLine: this._parts()[0].line });
    this._renderJob();
    this._endPlan('job -> ' + this._job().name + ' (plan reset)');
  },

  jobTap() { this.cycleJob(1); },

  partTap() {
    var parts = this._parts();
    this._partIdx = (this._partIdx + 1) % parts.length;
    var p = parts[this._partIdx];
    this.setData({
      partLine: p.line,
      lastEvent: 'EVT: part seen -> ' + p.name
    });
  },

  _renderStep() {
    var p = this._plan;
    if (!p) return;
    if (this._checked) {
      this.setData({
        stepText: 'STEP: ' + p.steps.length + '/' + p.steps.length + ' - DONE',
        planHead: 'WRAP-UP CHECK - ' + p.label + ' - source: ' + p.source,
        stepBody: p.check
      });
      return;
    }
    if (this._planDone) {
      this.setData({
        stepText: 'STEP: ' + p.steps.length + '/' + p.steps.length + ' - ALL DONE',
        planHead: 'FIX PLAN - ' + p.label + ' - source: ' + p.source,
        stepBody: p.closing + ' Tap CHECK for the wrap-up test.'
      });
      return;
    }
    this.setData({
      stepText: 'STEP: ' + (this._stepIdx + 1) + '/' + p.steps.length,
      planHead: 'FIX PLAN - ' + p.label + ' - source: ' + p.source,
      stepBody: p.steps[this._stepIdx]
    });
  },

  _startPlan(job, steps, source) {
    this._plan = {
      label: job.name, steps: steps.slice(),
      check: job.check, closing: job.closing, source: source
    };
    this._stepIdx = 0;
    this._planDone = false;
    this._checked = false;
    this.setData({ status: 'PLAN READY - ' + job.name + ' (' + source + ')' });
    this._renderStep();
  },

  nextStep() {
    if (!this._plan) {
      this.setData({ status: 'NO PLAN YET - tap START or DEMO first' });
      return;
    }
    if (this._planDone) {
      this.setData({ status: 'ALL STEPS DONE - tap CHECK for the wrap-up test' });
      return;
    }
    if (this._stepIdx < this._plan.steps.length - 1) {
      this._stepIdx++;
      this.setData({ lastEvent: 'EVT: advanced to step ' + (this._stepIdx + 1) });
    } else {
      this._planDone = true;
      this.setData({
        status: 'ALL STEPS DONE - tap CHECK to verify the repair',
        lastEvent: 'EVT: plan finished - closing advice shown'
      });
    }
    this._renderStep();
  },

  nextTap() { this.nextStep(); },

  checkTap() {
    if (!this._plan) {
      this.setData({ status: 'NO PLAN YET - CHECK runs at the end of a plan' });
      return;
    }
    if (!this._planDone) {
      this.setData({
        status: 'CHECK TOO EARLY - finish step ' + (this._stepIdx + 1) + '/' + this._plan.steps.length + ' first',
        lastEvent: 'EVT: CHECK ignored - plan not finished'
      });
      return;
    }
    this._checked = true;
    this.setData({
      status: 'DONE - wrap-up check shown; still bad? book a pro',
      lastEvent: 'EVT: wrap-up check shown for ' + this._plan.label
    });
    this._renderStep();
  },

  // Try the on-device LLM first for a concise step plan for the picked
  // job; parse numbered steps. Returns null when unavailable or
  // unparseable -> built-in job table. The prompt forces step 1 to be
  // the job's own safety action and bans gas / mains-electric work.
  async _llmPlan(job) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    try {
      var avail = await LM.availability();
      if (avail !== 'available') return null;
      var session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You are a concise home DIY repair coach. Reply in Chinese only. Never suggest gas work, mains (220V) electrical work, or opening sealed units.' }]
      });
      try {
        var ans = await this._withTimeout(
          session.prompt('家庭小维修分步指南。维修项目：' + job.name + '。请给出 5 个具体步骤，每步一行，分别以「1. 」「2. 」「3. 」「4. 」「5. 」开头。第 1 步必须原样使用这个安全动作：' + job.steps[0] + ' 不要输出其它内容。'),
          25000, 'llm');
        var lines = String(ans || '').split('\n').map(function (s) { return s.trim(); })
          .filter(function (s) { return s.length > 0; });
        var steps = [];
        for (var i = 0; i !== lines.length; i++) {
          var m = lines[i].match(/^[1-6][.、．]\s*(.+)$/);
          if (m) steps.push(m[1]);
        }
        if (steps.length >= 4) return steps.slice(0, 6);
        return null;
      } finally {
        try { session.destroy(); } catch (e) {}
      }
    } catch (e) {
      return null;
    }
  },

  startTap() { this.buildPlan(false); },

  demoTap() {
    // DEMO always loads the faucet job's built-in plan at step 2.
    this._jobIdx = 0;
    this._partIdx = 0;
    this.setData({ partLine: this._parts()[0].line });
    this._renderJob();
    this.buildPlan(true);
  },

  async buildPlan(useBuiltinOnly) {
    if (this.data.busy) return;
    var job = this._job();
    if (useBuiltinOnly) {
      this._startPlan(job, job.steps, 'built-in guide');
      this._stepIdx = 1; // DEMO lands mid-job, on step 2
      this._renderStep();
      this.setData({
        photoLine: 'PHOTO: DEMO plan (no camera / LLM used) - record only anyway',
        lastEvent: 'EVT: DEMO loaded built-in plan for ' + job.name + ' at step 2'
      });
      return;
    }
    this.setData({ busy: true, status: 'BUILDING PLAN for ' + job.name + '...' });
    var llm = null;
    try { llm = await this._llmPlan(job); } catch (e) { llm = null; }
    this.setData({ busy: false });
    if (llm) {
      this._startPlan(job, llm, 'LLM');
      this.setData({ lastEvent: 'EVT: plan built by LLM for ' + job.name });
    } else {
      this._startPlan(job, job.steps, 'built-in guide');
      this.setData({ lastEvent: 'EVT: LLM n/a - built-in guide used for ' + job.name });
    }
  },

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; pick the job below and tap START',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto) - aim at the part in your hands...' });
    var stream = null;
    try {
      stream = await this._withTimeout(
        navigator.mediaDevices.getUserMedia({ video: true }), 9000, 'camera');
      this._stream = stream;
      var track = stream.getVideoTracks()[0];
      if (!track) throw new Error('no video track');
      var photoBytes = 0;
      if (typeof ImageCapture !== 'undefined') {
        var cap = new ImageCapture(track);
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'telephoto' }), 9000, 'telephoto photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B - telephoto close-up saved as visual record only',
        status: 'PHOTO SAVED as record - note the part with PART, then START',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / manual-lens.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record only',
          status: 'PHOTO SAVED as record - note the part with PART, then START',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; pick the job below and tap START',
          lastEvent: 'EVT: LOOK FAIL'
        });
      }
    } finally {
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        if (this._stream === stream) this._stream = null;
      }
      this.setData({ busy: false });
    }
  },

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var text;
      if (this._plan && this._checked) {
        text = this._plan.check;
      } else if (this._plan && this._planDone) {
        text = this._plan.closing;
      } else if (this._plan) {
        text = '第' + (this._stepIdx + 1) + '步：' + this._plan.steps[this._stepIdx];
      } else {
        var j = this._job();
        text = j.name + '。' + j.tools.replace('TOOLS: ', '工具：') + '。第一步：' + j.steps[0];
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent - ' + text.slice(0, 40) });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">REPAIR BUDDY</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{stepText}}</text>
    </view>
    <view class="job-box">
      <text class="box-label">◎ JOB YOU PICKED - PHOTO = RECORD ONLY, NO DIAGNOSIS FROM IT</text>
      <text class="job">{{jobText}}</text>
      <text class="meta">{{toolsLine}}</text>
      <text class="meta">{{photoLine}}</text>
      <text class="meta">{{partLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="jobTap">JOB</button>
      <button class="btn" bindtap="partTap">PART</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="startTap">START</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{planHead}}</text>
      <text class="step">{{stepBody}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="checkTap">CHECK</button>
      <button class="btn" bindtap="demoTap">DEMO （水龙头滴水）</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 6px 12px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 4px;
}
.title {
  color: #40ff5e;
  font-size: 20px;
  font-weight: 500;
  line-height: 24px;
}
.status {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.sub {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.job-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 8px;
  margin-bottom: 5px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.job {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 22px;
  margin-top: 2px;
}
.meta {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
.actions {
  display: flex;
  flex-direction: row;
  gap: 8px;
  margin-bottom: 4px;
}
.btn {
  flex-grow: 1;
  color: rgba(64,255,94,0.72);
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 4px;
  padding: 2px;
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
.plan-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 8px;
  margin-bottom: 5px;
}
.step {
  color: #40ff5e;
  font-size: 13px;
  line-height: 18px;
  margin-top: 2px;
}
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
</style>
