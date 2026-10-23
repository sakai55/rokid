<script def>
{
  "navigationBarTitleText": "Manual Lens"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT THE NAMEPLATE / ERROR DISPLAY - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    stepText: 'STEP: -/- (no plan yet)',
    photoLine: 'PHOTO: not taken yet - record only; you confirm the code below',
    deviceText: '洗衣机',
    codeText: 'E1 · 进水异常',
    meaningLine: 'MEANING: pick the appliance and the code you see, then tap FIX',
    planHead: 'FIX PLAN - no plan yet (FIX or DEMO)',
    stepBody: 'Plan steps appear here one at a time. NEXT or nod advances, SPEAK reads the step aloud.',
    lastEvent: 'EVT: nod when steady = LOOK; during a plan, nod = NEXT',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._devIdx = 0;
    this._codeIdx = 0;
    this._focus = 'device'; // ArrowUp/Down cycle the focused selector
    this._plan = null; // { label, meaning, steps, closing, source }
    this._stepIdx = 0;
    this._planDone = false;
    this._renderSelectors();
    this.setData({ lastEvent: 'EVT: look at the appliance, hold your head still, then LOOK' });
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
        status: 'LOOK AT THE NAMEPLATE / ERROR DISPLAY - HOLD HEAD STEADY'
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
      this.cycleFocused(1);
    } else if (code === 'ArrowDown') {
      this.cycleFocused(-1);
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

  // Built-in common-cause table: 5 appliance types x common error codes.
  // The user CONFIRMS appliance + code with the selectors - the photo is
  // a record only and the code is never claimed to be read by OCR.
  // For water/electric appliances, step 1 of every entry is the safety
  // action (unplug / shut the water valve).
  _devices() {
    return [
      {
        name: '洗衣机',
        codes: [
          {
            code: 'E1', meaning: '进水异常：进水超时，水龙头、水压或进水滤网的问题。',
            steps: [
              '先拔掉电源插头，并关闭进水水龙头（安全第一）。',
              '再打开水龙头确认家里有水、水压正常。',
              '拧下进水管接头，清洗里面的小滤网后装回。',
              '接通电源重新启动一次脱水+进水流程试试。'
            ]
          },
          {
            code: 'E2', meaning: '排水问题：排水超时，排水管、泵滤网堵塞或管路弯折。',
            steps: [
              '先拔掉电源插头，并关闭进水水龙头（安全第一）。',
              '检查排水管：放直不压扁，出水口别插进下水太深。',
              '打开机身下方小门，拧开排水泵滤网清硬币头发（备毛巾接水）。',
              '装回滤网，选单脱水程序试运行一次。'
            ]
          },
          {
            code: 'E3', meaning: '门盖未关好：门没关紧、衣物夹门，或门锁检测异常。',
            steps: [
              '先拔掉电源插头（安全第一）。',
              '开门再用力关紧，听到咔哒声；检查门边有没有衣物夹住。',
              '擦干门锁与锁孔附近的水渍。',
              '接通电源重启；仍报 E3 多半门锁损坏，报修时说代码 E3。'
            ]
          },
          {
            code: 'E4', meaning: '脱水不平衡：衣物偏在一边，晃动过大触发保护。',
            steps: [
              '先拔掉电源插头（安全第一）。',
              '开门把衣物抖散铺平；单件大件加一两件小件配平。',
              '确认机身四脚平稳、地面不软不晃。',
              '关门，重新选脱水程序启动。'
            ]
          }
        ]
      },
      {
        name: '空调',
        codes: [
          {
            code: 'E1', meaning: '系统保护：多与散热差、滤网脏堵或通信异常有关。',
            steps: [
              '先关机并拔掉空调电源，等 5 分钟（安全第一）。',
              '打开内机面板抽出滤网，清水冲洗晾干装回。',
              '确认室外机出风口没有杂物遮挡。',
              '重新上电开机试运行；仍报 E1 报修并说代码 E1。'
            ]
          },
          {
            code: 'E2', meaning: '防冻结保护：蒸发器结霜，滤网太脏、风量小或缺氟。',
            steps: [
              '先关机并拔掉电源（安全第一）。',
              '抽出滤网清洗晾干后装回。',
              '上电改送风模式运行 30 分钟化霜。',
              '再开制冷；反复报 E2 多半缺氟，找专业人员处理。'
            ]
          },
          {
            code: 'E3', meaning: '低压保护：多为缺冷媒或管路泄漏，不要自行加氟。',
            steps: [
              '先关机并拔掉电源（安全第一）。',
              '看室外机铜管接口有没有油迹（漏氟痕迹）。',
              '清洗内机滤网，先排除风量因素。',
              '不要自己加氟：报修时说代码 E3，要求先查漏再加氟。'
            ]
          },
          {
            code: 'F1', meaning: '室温传感器故障：探头开路/短路，温度读数不准。',
            steps: [
              '先关机并拔掉电源，等 5 分钟（安全第一）。',
              '重新上电，看显示温度是否恢复正常。',
              '内机右下角的探头小头若脱落或糊满灰，轻轻擦净归位。',
              '仍报 F1 需更换传感器，报修并说代码 F1。'
            ]
          }
        ]
      },
      {
        name: '热水器',
        codes: [
          {
            code: 'E1', meaning: '加热失败（电热水器）：干烧保护触发或加热管异常。',
            steps: [
              '先断电，并关闭进水阀（安全第一）。',
              '打开任意热水龙头放一点水，确认内胆里有水、防干烧。',
              '找机身侧面小孔里的复位按钮，轻轻按一下复位。',
              '重新上电加热；仍报 E1 报修，加热管或温控需更换。'
            ]
          },
          {
            code: 'E2', meaning: '过热保护：出水温度过高，常因水垢多或水流太小。',
            steps: [
              '先断电，并关闭进水阀（安全第一）。',
              '等 30 分钟充分降温后再重新上电试。',
              '把设定温度调到 55°C 左右，不要长期开到最高。',
              '反复跳 E2 多半水垢严重，找专业人员清洗内胆。'
            ]
          },
          {
            code: 'E3', meaning: '温度传感器故障：测温探头异常，温度显示不准。',
            steps: [
              '先断电，并关闭进水阀（安全第一）。',
              '等 10 分钟重新上电，看显示是否恢复。',
              '观察显示温度是否乱跳、与实际明显不符。',
              '仍报 E3 需更换探头，报修并说代码 E3。'
            ]
          },
          {
            code: 'E4', meaning: '漏电保护触发：立即停用，不要反复通电尝试。',
            steps: [
              '保持断电状态，绝不再通电，并关闭进水阀（安全第一）。',
              '擦干机身和周围地面的水渍，人不要站在积水里操作。',
              '不要自行拆机、不要强行复位漏电开关。',
              '直接报修并说明代码 E4（漏电），检修合格前不要使用。'
            ]
          }
        ]
      },
      {
        name: '洗碗机',
        codes: [
          {
            code: 'E1', meaning: '进水超时：水龙头未开、进水滤网堵或水压太低。',
            steps: [
              '先断电，并关闭进水阀（安全第一）。',
              '打开水龙头确认供水与水压正常。',
              '拆下进水管清洗滤网，管路理直不要弯折。',
              '恢复供水、上电，重新启动洗涤程序。'
            ]
          },
          {
            code: 'E2', meaning: '排水故障：底部滤网、排水管或排水泵堵塞。',
            steps: [
              '先断电，并关闭进水阀（安全第一）。',
              '取出机内底部滤网组件，冲洗干净再装回。',
              '检查排水管高度与走向：别抬太高、别压扁。',
              '舀出机内积水后重启；仍报 E2 报修查排水泵。'
            ]
          },
          {
            code: 'E3', meaning: '加热故障：水温升不上去，加热器或温控异常。',
            steps: [
              '先断电（安全第一）。',
              '确认没选到冷水洗/快速节能这类低温程序。',
              '重新上电，选高温程序空跑一次试试。',
              '仍报 E3 需检修加热组件，报修并说代码 E3。'
            ]
          },
          {
            code: 'E4', meaning: '溢水/漏水：底盘检出漏水，机器已自动保护停机。',
            steps: [
              '立即断电，并关闭进水阀（安全第一）。',
              '擦干机器底部和周围地面的水。',
              '检查门封条：有没有夹到餐具、密封条是否老化变形。',
              '不要强行重启；找不到漏点就报修，说代码 E4。'
            ]
          }
        ]
      },
      {
        name: '烤箱',
        codes: [
          {
            code: 'F1', meaning: '温控传感器故障：测温探头开路/短路，有失控风险。',
            steps: [
              '先断电，等炉腔完全冷却再操作（安全第一）。',
              '看腔内后壁的细长探头：松脱就推回，油污重就擦净。',
              '重新上电，空烧 5 分钟看是否还报 F1。',
              '仍报 F1 就停用，报修更换探头并说代码 F1。'
            ]
          },
          {
            code: 'F2', meaning: '过热保护：腔温超限，常因散热口被遮挡。',
            steps: [
              '先断电，等炉腔完全冷却（安全第一）。',
              '移开烤箱顶部和背后的遮挡物，保证散热空间。',
              '冷却 30 分钟后重新上电试一次。',
              '空载也报 F2 是温控故障，报修并说代码 F2。'
            ]
          },
          {
            code: 'F3', meaning: '加热异常：加热管不工作或局部损坏。',
            steps: [
              '先断电，等炉腔完全冷却（安全第一）。',
              '目视上下加热管：有没有起泡、断裂、局部发黑。',
              '确认模式没选错（单上火/单下火会影响判断）。',
              '加热管损坏只能更换，报修并说代码 F3。'
            ]
          },
          {
            code: 'E0', meaning: '通信/显示异常：控制板与显示板通信偶发故障。',
            steps: [
              '先断电，等 5 分钟（安全第一）。',
              '重新上电，看显示是否恢复正常。',
              '逐个按键试一遍，确认都有响应。',
              '反复出现 E0 需检修控制板，报修并说代码 E0。'
            ]
          }
        ]
      }
    ];
  },

  _device() { return this._devices()[this._devIdx]; },
  _entry() { return this._device().codes[this._codeIdx]; },

  _closing(device, entry) {
    return 'DONE - still showing ' + entry.code + '? Book a technician - quote code ' +
      entry.code + ' (' + device.name + ').';
  },

  _renderSelectors() {
    var d = this._device();
    var e = this._entry();
    this.setData({
      deviceText: d.name,
      codeText: e.code + ' · ' + e.meaning.split('：')[0].split(':')[0],
      meaningLine: 'MEANING (' + d.name + ' ' + e.code + '): ' + e.meaning
    });
  },

  _endPlan(note) {
    this._plan = null;
    this._planDone = false;
    this._stepIdx = 0;
    this.setData({
      stepText: 'STEP: -/- (no plan yet)',
      planHead: 'FIX PLAN - no plan yet (FIX or DEMO)',
      stepBody: 'Plan steps appear here one at a time. NEXT or nod advances, SPEAK reads the step aloud.',
      lastEvent: 'EVT: ' + note
    });
  },

  cycleDevice(dir) {
    var n = this._devices().length;
    this._devIdx = ((this._devIdx + dir) % n + n) % n;
    this._codeIdx = 0;
    this._focus = 'device';
    this._renderSelectors();
    this._endPlan('appliance -> ' + this._device().name + ' (code reset to first)');
  },

  cycleCode(dir) {
    var n = this._device().codes.length;
    this._codeIdx = ((this._codeIdx + dir) % n + n) % n;
    this._focus = 'code';
    this._renderSelectors();
    this._endPlan('code -> ' + this._device().name + ' ' + this._entry().code);
  },

  cycleFocused(dir) {
    if (this._focus === 'code') this.cycleCode(dir);
    else this.cycleDevice(dir);
  },

  deviceTap() { this.cycleDevice(1); },
  codeTap() { this.cycleCode(1); },

  _renderStep() {
    var p = this._plan;
    if (!p) return;
    if (this._planDone) {
      this.setData({
        stepText: 'STEP: ' + p.steps.length + '/' + p.steps.length + ' - DONE',
        planHead: 'FIX PLAN - ' + p.label + ' - source: ' + p.source,
        stepBody: p.closing
      });
      return;
    }
    this.setData({
      stepText: 'STEP: ' + (this._stepIdx + 1) + '/' + p.steps.length,
      planHead: 'FIX PLAN - ' + p.label + ' - source: ' + p.source,
      stepBody: p.steps[this._stepIdx]
    });
  },

  _startPlan(label, meaning, steps, closing, source) {
    this._plan = {
      label: label, meaning: meaning,
      steps: steps.slice(), closing: closing, source: source
    };
    this._stepIdx = 0;
    this._planDone = false;
    this.setData({
      status: 'PLAN READY - ' + label + ' (' + source + ')',
      meaningLine: 'MEANING (' + label + '): ' + meaning
    });
    this._renderStep();
  },

  nextStep() {
    if (!this._plan) {
      this.setData({ status: 'NO PLAN YET - tap FIX or DEMO first' });
      return;
    }
    if (this._planDone) {
      this.setData({ status: 'PLAN FINISHED - pick another appliance/code, or LOOK again' });
      return;
    }
    if (this._stepIdx < this._plan.steps.length - 1) {
      this._stepIdx++;
      this.setData({ lastEvent: 'EVT: advanced to step ' + (this._stepIdx + 1) });
    } else {
      this._planDone = true;
      this.setData({
        status: 'PLAN DONE - both hands stayed on the machine',
        lastEvent: 'EVT: plan finished - closing advice shown'
      });
    }
    this._renderStep();
  },

  nextTap() { this.nextStep(); },

  // Try the on-device LLM first for a concise fix plan; parse "cause line +
  // numbered steps". Returns null when unavailable or unparseable ->
  // built-in table. The prompt forces step 1 to be the safety action.
  async _llmPlan(device, entry) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    try {
      var avail = await LM.availability();
      if (avail !== 'available') return null;
      var session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You are a concise home-appliance troubleshooting advisor. Reply in Chinese only. Never suggest opening the appliance casing or repairing internal parts.' }]
      });
      try {
        var ans = await this._withTimeout(
          session.prompt('家用电器故障排查。电器：' + device.name + '；故障代码：' + entry.code +
            '（常见含义：' + entry.meaning + '）。请给出简短排查计划：第一行写一句最可能的原因（不要编号），随后是 4 个具体步骤，每步一行，分别以「1. 」「2. 」「3. 」「4. 」开头。第 1 步必须是安全动作：先断电，涉及水的电器还要关进水阀。不要输出其它内容。'),
          25000, 'llm');
        var lines = String(ans || '').split('\n').map(function (s) { return s.trim(); })
          .filter(function (s) { return s.length > 0; });
        var steps = [];
        var cause = '';
        for (var i = 0; i !== lines.length; i++) {
          var m = lines[i].match(/^[1-4][.、．]\s*(.+)$/);
          if (m) steps.push(m[1]);
          else if (!cause && steps.length === 0) cause = lines[i];
        }
        if (steps.length >= 3 && cause) {
          return { meaning: cause.slice(0, 80), steps: steps.slice(0, 4) };
        }
        return null;
      } finally {
        try { session.destroy(); } catch (e) {}
      }
    } catch (e) {
      return null;
    }
  },

  fixTap() { this.buildPlan(false); },

  demoTap() {
    // DEMO always shows the washer E2 (drainage) built-in plan.
    this._devIdx = 0;
    this._codeIdx = 1;
    this._focus = 'code';
    this._renderSelectors();
    this.buildPlan(true);
  },

  async buildPlan(useBuiltinOnly) {
    if (this.data.busy) return;
    var device = this._device();
    var entry = this._entry();
    var label = device.name + ' ' + entry.code;
    var closing = this._closing(device, entry);
    if (useBuiltinOnly) {
      this._startPlan(label, entry.meaning, entry.steps, closing, 'built-in guide');
      this.setData({
        photoLine: 'PHOTO: DEMO plan (no camera / LLM used) - record only anyway',
        lastEvent: 'EVT: DEMO loaded built-in plan for ' + label
      });
      return;
    }
    this.setData({ busy: true, status: 'BUILDING FIX PLAN for ' + label + '...' });
    var llm = null;
    try { llm = await this._llmPlan(device, entry); } catch (e) { llm = null; }
    this.setData({ busy: false });
    if (llm) {
      this._startPlan(label, llm.meaning, llm.steps, closing, 'LLM');
      this.setData({ lastEvent: 'EVT: fix plan built by LLM for ' + label });
    } else {
      this._startPlan(label, entry.meaning, entry.steps, closing, 'built-in guide');
      this.setData({ lastEvent: 'EVT: LLM n/a - built-in guide used for ' + label });
    }
  },

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; confirm the appliance + code below and tap FIX',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (telephoto) - aim at the nameplate / display...' });
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
        photoLine: 'PHOTO: ' + photoBytes + 'B - mode telephoto - record only; the code is NOT read from it - confirm the code below',
        status: 'PHOTO SAVED as record - now confirm appliance + code, then tap FIX',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / plant-doctor.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record only; confirm the code below',
          status: 'PHOTO SAVED as record - now confirm appliance + code, then tap FIX',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; confirm the appliance + code below and tap FIX',
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
      if (this._plan && this._planDone) {
        text = this._plan.closing;
      } else if (this._plan) {
        text = '第' + (this._stepIdx + 1) + '步：' + this._plan.steps[this._stepIdx];
      } else {
        var e = this._entry();
        text = this._device().name + '，代码' + e.code + '。含义：' + e.meaning;
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
      <text class="title">MANUAL LENS</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{stepText}}</text>
    </view>
    <view class="look-box">
      <text class="box-label">◎ LOOKED-AT APPLIANCE - PHOTO = RECORD ONLY, CODE IS CONFIRMED BY YOU BELOW (no OCR)</text>
      <text class="photo">{{photoLine}}</text>
      <text class="device">{{deviceText}} · {{codeText}}</text>
      <text class="photo">{{meaningLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="deviceTap">DEVICE</button>
      <button class="btn" bindtap="codeTap">CODE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="fixTap">FIX</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{planHead}}</text>
      <text class="step">{{stepBody}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO （洗衣机 E2 排水计划）</button>
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
.look-box {
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
.photo {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 2px;
}
.device {
  color: #40ff5e;
  font-size: 17px;
  font-weight: 500;
  line-height: 22px;
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
