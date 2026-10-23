<script def>
{
  "navigationBarTitleText": "Plant Doctor"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'LOOK AT THE PLANT - HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    stepText2: 'STEP: -/- (no plan yet)',
    photoLine: 'PHOTO: not taken yet - record only; the check is symptom-based',
    symptomText: '叶子发黄',
    waterLine: 'SOIL: 干透 (tap WATER) - ADVICE: tap WATER for a verdict',
    causeLine: 'CAUSE: pick the symptom you see, then tap CHECK',
    planHead: 'CARE PLAN - no plan yet (CHECK or DEMO)',
    stepBody: 'Plan steps appear here one at a time. NEXT or nod advances, SPEAK reads the step aloud.',
    lastEvent: 'EVT: nod when steady = LOOK; during a plan, nod = NEXT',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._symIdx = 0;
    this._soilIdx = 0;
    this._plan = null; // { name, cause, steps, closing, source }
    this._stepIdx = 0;
    this._planDone = false;
    this._renderSymptom();
    this.setData({ lastEvent: 'EVT: look at the plant, hold your head still, then LOOK' });
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
        status: 'LOOK AT THE PLANT - HOLD HEAD STEADY'
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
      this.cycleSymptom(1);
    } else if (code === 'ArrowDown') {
      this.cycleSymptom(-1);
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

  // Built-in expert table (used when the LLM is unavailable, and by DEMO).
  // Guidance keyed by the VISIBLE symptom the user picks - never claimed
  // to be identified from the photo.
  _symptoms() {
    return [
      {
        name: '叶子发黄',
        cause: '多半是浇水过多闷根、缺肥，或光照不足。先查土和盆底。',
        steps: [
          '手指插入土 2-3 厘米：很湿就停水，把花盆移到通风处。',
          '剪掉完全变黄的叶子，半黄的先保留观察。',
          '检查盆底排水孔是否堵塞，托盘里不要留积水。',
          '等土干透再浇，一次浇透；之后每周一次稀薄液肥。'
        ],
        closing: 'DONE - check again in 3 days：不再新增黄叶就是在好转。'
      },
      {
        name: '叶子蔫垂',
        cause: '多半是缺水，也可能是暴晒或烂根。先摸土再决定。',
        steps: [
          '摸土：干透了就立刻浇透，直到盆底孔出水。',
          '把花盆移到明亮但没有直射光的地方缓半天。',
          '先不要施肥、不要换盆，让它恢复挺立。',
          '若土很湿还蔫：脱盆查根，发黑发软是烂根，剪掉换干土。'
        ],
        closing: 'DONE - check again in 3 days：缺水蔫叶浇透后几小时应挺起；没挺起按烂根处理。'
      },
      {
        name: '叶面斑点',
        cause: '多半是真菌/细菌病害，常因浇水溅叶加不通风。先隔离。',
        steps: [
          '把这盆与其它植物分开至少 30 厘米，避免传染。',
          '剪掉斑点严重的叶子，剪刀每剪一片用酒精擦一次。',
          '以后只浇土面、不喷淋叶面，并开窗通风。',
          '每周喷一次按说明稀释的杀菌剂，连用 3 周看新叶。'
        ],
        closing: 'DONE - check again in 3 days：新叶无斑就是控制住了。'
      },
      {
        name: '有虫',
        cause: '常见蚜虫、红蜘蛛或介壳虫，多藏在叶背和嫩芽处。',
        steps: [
          '先用清水冲洗叶面和叶背，冲掉大部分虫子。',
          '棉签蘸酒精，逐个擦掉残留的虫（对介壳虫尤其有效）。',
          '全株喷肥皂水或印楝油（按说明稀释），重点喷叶背。',
          '一周后重复一次，连续 2-3 次才能断根。'
        ],
        closing: 'DONE - check again in 3 days：翻叶背复查，还有活虫就再喷一轮。'
      },
      {
        name: '只长叶不开花',
        cause: '多半是光照不足，或氮肥太多、磷钾不足。',
        steps: [
          '移到家里光照最强的位置，每天至少 4 小时光照。',
          '停掉高氮肥，改用磷钾为主的促花肥，2 周一次。',
          '适当控水：土干透再浇，轻微干旱有助于促花芽。',
          '剪掉过密的徒长枝，让养分集中到花芽上。'
        ],
        closing: 'DONE - check again in 3 days 看芽点；2-3 周有花芽就恢复正常养护。'
      }
    ];
  },

  _soils() {
    return [
      { name: '干透', advice: '现在可以浇水：一次浇透，盆底出水即停。' },
      { name: '微潮', advice: '先别浇，过 1-2 天再摸土确认。' },
      { name: '很湿', advice: '不要浇水！移到通风处，防闷根烂根。' }
    ];
  },

  _currentSymptom() {
    return this._symptoms()[this._symIdx];
  },

  _renderSymptom() {
    var s = this._currentSymptom();
    this.setData({
      symptomText: s.name,
      causeLine: 'CAUSE: ' + s.cause
    });
  },

  cycleSymptom(dir) {
    var n = this._symptoms().length;
    this._symIdx = ((this._symIdx + dir) % n + n) % n;
    // Changing the symptom ends any running plan for the old symptom.
    this._plan = null;
    this._planDone = false;
    this._stepIdx = 0;
    this._renderSymptom();
    this.setData({
      stepText2: 'STEP: -/- (no plan yet)',
      planHead: 'CARE PLAN - no plan yet (CHECK or DEMO)',
      stepBody: 'Plan steps appear here one at a time. NEXT or nod advances, SPEAK reads the step aloud.',
      lastEvent: 'EVT: symptom -> ' + this._currentSymptom().name
    });
  },

  symptomTap() { this.cycleSymptom(1); },

  _renderStep() {
    var p = this._plan;
    if (!p) return;
    if (this._planDone) {
      this.setData({
        stepText2: 'STEP: ' + p.steps.length + '/' + p.steps.length + ' - DONE',
        planHead: 'CARE PLAN - ' + p.name + ' - source: ' + p.source,
        stepBody: p.closing
      });
      return;
    }
    this.setData({
      stepText2: 'STEP: ' + (this._stepIdx + 1) + '/' + p.steps.length,
      planHead: 'CARE PLAN - ' + p.name + ' - source: ' + p.source,
      stepBody: p.steps[this._stepIdx]
    });
  },

  _startPlan(symptom, source) {
    this._plan = {
      name: symptom.name,
      cause: symptom.cause,
      steps: symptom.steps.slice(),
      closing: symptom.closing,
      source: source
    };
    this._stepIdx = 0;
    this._planDone = false;
    this.setData({
      status: 'PLAN READY - ' + symptom.name + ' (' + source + ')',
      causeLine: 'CAUSE: ' + symptom.cause
    });
    this._renderStep();
  },

  nextStep() {
    if (!this._plan) {
      this.setData({ status: 'NO PLAN YET - tap CHECK or DEMO first' });
      return;
    }
    if (this._planDone) {
      this.setData({ status: 'PLAN FINISHED - pick another symptom, or tap WATER' });
      return;
    }
    if (this._stepIdx < this._plan.steps.length - 1) {
      this._stepIdx++;
      this.setData({ lastEvent: 'EVT: advanced to step ' + (this._stepIdx + 1) });
    } else {
      this._planDone = true;
      this.setData({
        status: 'PLAN DONE - well done, hands free the whole way',
        lastEvent: 'EVT: plan finished - closing advice shown'
      });
    }
    this._renderStep();
  },

  nextTap() { this.nextStep(); },

  waterTap() {
    var soils = this._soils();
    this._soilIdx = (this._soilIdx + 1) % soils.length;
    var s = soils[this._soilIdx];
    this.setData({
      waterLine: 'SOIL: ' + s.name + ' (tap WATER) - ADVICE: ' + s.advice,
      lastEvent: 'EVT: soil state -> ' + s.name
    });
  },

  // Try the on-device LLM for a concise plan; parse "cause line + numbered
  // steps". Returns null when unavailable or unparseable -> built-in table.
  async _llmPlan(symptom) {
    var LM = typeof LanguageModel !== 'undefined' ? LanguageModel : null;
    if (!LM) return null;
    try {
      var avail = await LM.availability();
      if (avail !== 'available') return null;
      var session = await LM.create({
        initialPrompts: [{ role: 'system', content: 'You are a concise houseplant care advisor. Reply in Chinese only.' }]
      });
      try {
        var ans = await this._withTimeout(
          session.prompt('家里的盆栽出现症状：' + symptom.name + '。请给出简短护理计划：第一行写一句最可能的原因（不要编号），随后是 4 个具体步骤，每步一行，分别以「1. 」「2. 」「3. 」「4. 」开头。不要输出其它内容。'),
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
          return {
            name: symptom.name,
            cause: cause.slice(0, 80),
            steps: steps.slice(0, 4),
            closing: symptom.closing
          };
        }
        return null;
      } finally {
        try { session.destroy(); } catch (e) {}
      }
    } catch (e) {
      return null;
    }
  },

  checkTap() { this.buildPlan(false); },
  demoTap() { this.buildPlan(true); },

  async buildPlan(useBuiltinOnly) {
    if (this.data.busy) return;
    var symptom = this._currentSymptom();
    if (useBuiltinOnly) {
      this._startPlan(symptom, 'built-in guide');
      this.setData({
        photoLine: 'PHOTO: DEMO plan (no camera / LLM used)',
        lastEvent: 'EVT: DEMO loaded built-in plan for ' + symptom.name
      });
      return;
    }
    this.setData({ busy: true, status: 'BUILDING PLAN for ' + symptom.name + '...' });
    var llm = null;
    try { llm = await this._llmPlan(symptom); } catch (e) { llm = null; }
    this.setData({ busy: false });
    if (llm) {
      this._startPlan(llm, 'LLM');
      this.setData({ lastEvent: 'EVT: plan built by LLM for ' + symptom.name });
    } else {
      this._startPlan(symptom, 'built-in guide');
      this.setData({ lastEvent: 'EVT: LLM n/a - built-in guide used for ' + symptom.name });
    }
  },

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; pick the symptom you see and CHECK - guidance is symptom-based',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default mode) - aim at the plant...' });
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
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B - mode default - record only; diagnosis is symptom-based, NOT from this photo',
        status: 'PHOTO SAVED as record - now pick the symptom you see and tap CHECK',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like gaze-translate / expiry-check.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record only; diagnosis is symptom-based',
          status: 'PHOTO SAVED as record - now pick the symptom you see and tap CHECK',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; pick the symptom you see and CHECK - guidance is symptom-based',
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
        text = this._currentSymptom().name + '。可能原因：' + this._currentSymptom().cause;
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
      <text class="title">PLANT DOCTOR</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{stepText2}}</text>
    </view>
    <view class="look-box">
      <text class="box-label">◎ LOOKED-AT PLANT - SYMPTOM-BASED GUIDANCE (photo = record only, NOT identification)</text>
      <text class="photo">{{photoLine}}</text>
      <text class="symptom">{{symptomText}}</text>
      <text class="photo">{{waterLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="symptomTap">SYMPTOM</button>
      <button class="btn" bindtap="checkTap">CHECK</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="waterTap">WATER</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{planHead}}</text>
      <text class="cause">{{causeLine}}</text>
      <text class="step">{{stepBody}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="demoTap">DEMO (yellowing leaves plan)</button>
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
.symptom {
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
.cause {
  color: rgba(64,255,94,0.72);
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
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
