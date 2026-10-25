<script def>
{
  "navigationBarTitleText": "Assemble Guide"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'PICK A KIT - COUNT PARTS BY LOOKING, HOLD HEAD STEADY',
    steadyText: 'HEAD: moving - hold still',
    stepText: 'STEP: -/- (no step yet)',
    kitText: '书架',
    partsLine: 'PARTS: 侧板x2 · 层板x3 · 背板x1 · 长螺丝x12 · 木销x8 · 背板钉x10 · 脚垫x4',
    photoLine: 'PHOTO: not taken yet - default mode, record only',
    needLine: 'NEED: - (START a kit first)',
    countLine: 'COUNT: - (tap COUNT for each needed part you can see)',
    planHead: 'ASSEMBLY - no step yet (START or DEMO)',
    stepBody: 'Count this step\'s parts first - ready unlocks the build. NEXT or nod advances; SPEAK reads the step + parts.',
    warnLine: 'WRONG?: tap WRONG mid-step for its common mistake',
    lastEvent: 'EVT: nod when steady = LOOK; during assembly, nod = NEXT',
    busy: false
  },

  onLoad() {
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._steady = false;
    this._kitIdx = 0;
    this._plan = null; // { label, steps, closing, source }
    this._stepIdx = 0;
    this._planDone = false;
    this._counts = [];
    this._focus = 0;
    this._renderKit();
    this.setData({ lastEvent: 'EVT: pick the kit, hold your head still, then START' });
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
          ? 'HEAD STEADY - nod = NEXT step (parts must be ready)'
          : 'HEAD STEADY - nod or tap LOOK'
      });
    } else {
      this.setData({
        steadyText: 'HEAD: moving - hold still',
        status: 'PICK A KIT - COUNT PARTS BY LOOKING, HOLD HEAD STEADY'
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
      this.cycleKit(1);
    } else if (code === 'ArrowDown') {
      this.cycleKit(-1);
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

  // Built-in kit table: 3 flat-pack kits. Every step names the parts it
  // needs (needs: name x qty) and carries ONE common-mistake warning.
  // The parts gate is the point: a step only shows its ready line when
  // the wearer has COUNTed every needed part in front of them.
  _kits() {
    return [
      {
        name: '书架',
        parts: 'PARTS: 侧板x2 · 层板x3 · 背板x1 · 长螺丝x12 · 木销x8 · 背板钉x10 · 脚垫x4',
        steps: [
          {
            text: '清点全部零件摆好；侧板分左右，带预钻孔的一面朝内。',
            needs: [{ part: '侧板', qty: 2 }],
            warn: 'WRONG: 侧板左右装反 -> 预钻孔面对不上，先看孔位方向再动手。'
          },
          {
            text: '把木销敲进侧板下部的销孔，再装上最底层板。',
            needs: [{ part: '木销', qty: 4 }, { part: '层板', qty: 1 }],
            warn: 'WRONG: 木销敲过头会顶裂板面 -> 敲到露出一半即可。'
          },
          {
            text: '装中间两块层板：两端同时对齐木销孔，再平稳压紧。',
            needs: [{ part: '层板', qty: 2 }, { part: '木销', qty: 4 }],
            warn: 'WRONG: 层板斜着硬压会崩边 -> 两端同时对孔再下压。'
          },
          {
            text: '用长螺丝固定层板两端，对角交替，逐颗拧到 snug。',
            needs: [{ part: '长螺丝', qty: 8 }],
            warn: 'WRONG: 先拧死一颗会拉偏框架 -> 对角交替、逐颗渐紧。'
          },
          {
            text: '整体翻面放平，铺上背板，四角先对孔，再钉满背板钉。',
            needs: [{ part: '背板', qty: 1 }, { part: '背板钉', qty: 10 }],
            warn: 'WRONG: 背板方向装反 -> 先对孔再钉，钉偏了整架会歪。'
          },
          {
            text: '沿层板边缘补齐其余长螺丝，扶正框架后整体复紧。',
            needs: [{ part: '长螺丝', qty: 4 }],
            warn: 'WRONG: 扶正前把螺丝全拧死 -> 留一点活动量先调方正。'
          },
          {
            text: '贴上脚垫，立起书架靠墙，轻晃检查稳不稳。',
            needs: [{ part: '脚垫', qty: 4 }],
            warn: 'WRONG: 没贴脚垫就推到位会刮地板 -> 先贴垫再移。'
          }
        ],
        closing: 'DONE - 书架装完：轻晃检查，晃动多半是某颗长螺丝没复紧；靠墙放稳再上书。'
      },
      {
        name: '抽屉柜',
        parts: 'PARTS: 顶板x1 · 侧板x2 · 底板x1 · 抽屉面x2 · 滑轨x2套 · 长螺丝x10 · 把手螺丝x4',
        steps: [
          {
            text: '清点零件；侧板分清左右，带滑轨孔的一面朝内。',
            needs: [{ part: '侧板', qty: 2 }],
            warn: 'WRONG: 侧板左右装反 -> 滑轨孔对不上，先认安装面。'
          },
          {
            text: '把两套滑轨的外轨用长螺丝固定到两侧板内侧。',
            needs: [{ part: '滑轨', qty: 2 }, { part: '长螺丝', qty: 4 }],
            warn: 'WRONG: 滑轨前后装反抽屉拉不出 -> 带滚轮的一端朝前。'
          },
          {
            text: '拼上底板与两侧板：先全部挂住，再逐颗拧紧螺丝。',
            needs: [{ part: '底板', qty: 1 }, { part: '长螺丝', qty: 4 }],
            warn: 'WRONG: 一边先拧死会错位 -> 先全挂住再逐颗紧。'
          },
          {
            text: '装顶板，对角交替拧紧长螺丝，别过紧。',
            needs: [{ part: '顶板', qty: 1 }, { part: '长螺丝', qty: 2 }],
            warn: 'WRONG: 长螺丝拧过紧会顶裂顶板 -> 拧到 snug 就停。'
          },
          {
            text: '组装两个抽屉盒：抽屉面在前，侧后板拼好后固定抽屉底。',
            needs: [{ part: '抽屉面', qty: 2 }],
            warn: 'WRONG: 抽屉面装反 -> 把手孔应该在面板上沿一侧。'
          },
          {
            text: '给抽屉装内轨，再从内侧拧上把手螺丝安把手。',
            needs: [{ part: '把手螺丝', qty: 4 }],
            warn: 'WRONG: 用长螺丝装把手会顶穿面板 -> 只用包内短的把手螺丝。'
          },
          {
            text: '两个抽屉盒推入滑轨，抽拉三次检查顺滑和对齐。',
            needs: [{ part: '抽屉盒', qty: 2 }],
            warn: 'WRONG: 推不进别硬推 -> 多半是内轨没对准外轨槽，抽出重对。'
          }
        ],
        closing: 'DONE - 抽屉柜装完：两个抽屉各抽拉三次，顺滑不蹭边就是到位。'
      },
      {
        name: '电脑桌',
        parts: 'PARTS: 桌面x1 · 桌腿x4 · 横梁x1 · 长螺丝x12 · 线盒x1 · 脚垫x4',
        steps: [
          {
            text: '桌面反扣在纸箱或毯子上清点零件，认清桌面前后边。',
            needs: [{ part: '桌面', qty: 1 }],
            warn: 'WRONG: 桌面直接放地上会划伤 -> 先垫纸箱或毯子再反扣。'
          },
          {
            text: '四条桌腿对准角部孔位，全部先手拧带住，不要拧紧。',
            needs: [{ part: '桌腿', qty: 4 }, { part: '长螺丝', qty: 4 }],
            warn: 'WRONG: 一条腿先拧死再装下一条会翘 -> 先全带住再统一紧。'
          },
          {
            text: '装中间横梁，连接左右两边的腿框。',
            needs: [{ part: '横梁', qty: 1 }, { part: '长螺丝', qty: 4 }],
            warn: 'WRONG: 横梁上下装反，理线孔会朝下 -> 先把孔转到朝后一侧再拧。'
          },
          {
            text: '对角交替复紧全部长螺丝，顺序走一遍再补紧一圈。',
            needs: [{ part: '长螺丝', qty: 4 }],
            warn: 'WRONG: 顺着一圈拧会一边高 -> 对角交替、逐颗渐紧。'
          },
          {
            text: '把理线盒卡到桌后横梁上，电源线从桌后穿入线盒。',
            needs: [{ part: '线盒', qty: 1 }],
            warn: 'WRONG: 线盒卡扣硬压会断 -> 对准卡槽位置轻推到位。'
          },
          {
            text: '贴上脚垫，扶正立桌，轻晃检查四脚是否都着地。',
            needs: [{ part: '脚垫', qty: 4 }],
            warn: 'WRONG: 一脚悬空别垫纸片凑合 -> 拧脚垫调高度找平。'
          }
        ],
        closing: 'DONE - 电脑桌装完：四脚着地不晃、线盒卡牢，就可以摆显示器了。'
      }
    ];
  },

  _kit() { return this._kits()[this._kitIdx]; },
  _step() { return this._plan ? this._plan.steps[this._stepIdx] : null; },

  _renderKit() {
    var k = this._kit();
    this.setData({ kitText: k.name, partsLine: k.parts });
  },

  _endPlan(note) {
    this._plan = null;
    this._planDone = false;
    this._stepIdx = 0;
    this._counts = [];
    this._focus = 0;
    this.setData({
      stepText: 'STEP: -/- (no step yet)',
      needLine: 'NEED: - (START a kit first)',
      countLine: 'COUNT: - (tap COUNT for each needed part you can see)',
      planHead: 'ASSEMBLY - no step yet (START or DEMO)',
      stepBody: 'Count this step\'s parts first - ready unlocks the build. NEXT or nod advances; SPEAK reads the step + parts.',
      warnLine: 'WRONG?: tap WRONG mid-step for its common mistake',
      lastEvent: 'EVT: ' + note
    });
  },

  cycleKit(dir) {
    var n = this._kits().length;
    this._kitIdx = ((this._kitIdx + dir) % n + n) % n;
    this._renderKit();
    this._endPlan('kit -> ' + this._kit().name + ' (plan reset)');
  },

  kitTap() { this.cycleKit(1); },

  _needsText(step) {
    return step.needs.map(function (nd) { return nd.part + ' x' + nd.qty; }).join(' · ');
  },

  _allCounted() {
    var step = this._step();
    if (!step) return false;
    for (var i = 0; i !== step.needs.length; i++) {
      if ((this._counts[i] || 0) < step.needs[i].qty) return false;
    }
    return true;
  },

  _renderCounts() {
    var step = this._step();
    if (!step) return;
    var parts = [];
    for (var i = 0; i !== step.needs.length; i++) {
      parts.push(step.needs[i].part + ' seen ' + (this._counts[i] || 0) + '/' + step.needs[i].qty);
    }
    if (this._allCounted()) {
      this.setData({
        needLine: 'NEED: ' + this._needsText(step),
        countLine: 'COUNT: ' + parts.join(' · '),
        status: 'PARTS READY - parts ready, start building this step'
      });
    } else {
      this.setData({
        needLine: 'NEED: ' + this._needsText(step),
        countLine: 'COUNT: ' + parts.join(' · ') + ' (COUNT as you spot each)'
      });
    }
  },

  countTap() {
    var step = this._step();
    if (!this._plan || this._planDone) {
      this.setData({ status: 'NO STEP RUNNING - tap START or DEMO first' });
      return;
    }
    if (this._allCounted()) {
      this.setData({
        status: 'PARTS READY already - build this step, then NEXT or nod',
        lastEvent: 'EVT: COUNT ignored - all parts ready'
      });
      return;
    }
    // Advance the focus to the first part that is still short.
    while (this._focus < step.needs.length &&
      (this._counts[this._focus] || 0) >= step.needs[this._focus].qty) this._focus++;
    var nd = step.needs[this._focus];
    this._counts[this._focus] = (this._counts[this._focus] || 0) + 1;
    this.setData({
      lastEvent: 'EVT: counted ' + nd.part + ' -> ' + this._counts[this._focus] + '/' + nd.qty
    });
    this._renderCounts();
  },

  _renderStep() {
    var p = this._plan;
    if (!p) return;
    if (this._planDone) {
      this.setData({
        stepText: 'STEP: ' + p.steps.length + '/' + p.steps.length + ' - ALL DONE',
        planHead: 'ASSEMBLY - ' + p.label + ' - source: ' + p.source,
        stepBody: p.closing,
        needLine: 'NEED: - (kit finished)',
        countLine: 'COUNT: - (kit finished)'
      });
      return;
    }
    this.setData({
      stepText: 'STEP: ' + (this._stepIdx + 1) + '/' + p.steps.length,
      planHead: 'ASSEMBLY - ' + p.label + ' - source: ' + p.source,
      stepBody: p.steps[this._stepIdx].text,
      warnLine: 'WRONG?: tap WRONG mid-step for its common mistake'
    });
    this._renderCounts();
  },

  _startPlan(kit) {
    this._plan = {
      label: kit.name, steps: kit.steps,
      closing: kit.closing, source: 'built-in guide'
    };
    this._stepIdx = 0;
    this._planDone = false;
    this._counts = kit.steps[0].needs.map(function () { return 0; });
    this._focus = 0;
    this.setData({ status: 'KIT LOADED - ' + kit.name + ': count step 1 parts first' });
    this._renderStep();
  },

  startTap() {
    if (this.data.busy) return;
    this._startPlan(this._kit());
    this.setData({ lastEvent: 'EVT: started kit ' + this._kit().name + ' at step 1' });
  },

  demoTap() {
    // DEMO always loads the bookshelf kit mid-step (step 3 of 7),
    // with its first needed part only partly counted.
    this._kitIdx = 0;
    this._renderKit();
    this._startPlan(this._kit());
    this._stepIdx = 2;
    this._counts = [2, 0];
    this._focus = 0;
    this._renderStep();
    this.setData({
      photoLine: 'PHOTO: DEMO mid-step (no camera used) - record only anyway',
      status: 'DEMO - 书架 step 3: count the parts you can see',
      lastEvent: 'EVT: DEMO loaded 书架 at step 3, parts partly counted'
    });
  },

  nextStep() {
    if (!this._plan) {
      this.setData({ status: 'NO STEP YET - tap START or DEMO first' });
      return;
    }
    if (this._planDone) {
      this.setData({ status: 'KIT FINISHED - pick another kit with KIT' });
      return;
    }
    if (!this._allCounted()) {
      var step = this._step();
      var short = [];
      for (var i = 0; i !== step.needs.length; i++) {
        if ((this._counts[i] || 0) < step.needs[i].qty) {
          short.push(step.needs[i].part + ' ' + (this._counts[i] || 0) + '/' + step.needs[i].qty);
        }
      }
      this.setData({
        status: 'PARTS NOT READY - still short: ' + short.join(' · '),
        lastEvent: 'EVT: NEXT blocked - parts not counted yet'
      });
      return;
    }
    if (this._stepIdx < this._plan.steps.length - 1) {
      this._stepIdx++;
      var next = this._step();
      this._counts = next.needs.map(function () { return 0; });
      this._focus = 0;
      this.setData({
        status: 'STEP ' + (this._stepIdx + 1) + ' - count its parts first',
        lastEvent: 'EVT: advanced to step ' + (this._stepIdx + 1) + ' (counts reset)'
      });
    } else {
      this._planDone = true;
      this.setData({
        status: 'KIT DONE - all steps built',
        lastEvent: 'EVT: kit finished - closing line shown'
      });
    }
    this._renderStep();
  },

  nextTap() { this.nextStep(); },

  wrongTap() {
    var step = this._step();
    if (!this._plan || this._planDone || !step) {
      this.setData({ status: 'NO STEP RUNNING - WRONG works mid-step' });
      return;
    }
    this.setData({
      warnLine: step.warn,
      lastEvent: 'EVT: common mistake shown for step ' + (this._stepIdx + 1)
    });
  },

  lookTap() { this.lookPhoto(); },

  async lookPhoto() {
    if (this.data.busy) return;
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.setData({
        photoLine: 'PHOTO: FAIL - mediaDevices n/a on this host (record only anyway)',
        status: 'LOOK FAIL - no camera here; pick the kit below and tap START',
        lastEvent: 'EVT: LOOK FAIL (host has no camera)'
      });
      return;
    }
    this.setData({ busy: true, status: 'LOOKING (default) - aim at the diagram page / part...' });
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
        var blob = await this._withTimeout(cap.takePhoto({ mode: 'default' }), 9000, 'default photo');
        photoBytes = blob && blob.size ? blob.size : 0;
      } else {
        throw new Error('ImageCapture n/a');
      }
      this.setData({
        photoLine: 'PHOTO: ' + photoBytes + 'B - default mode, saved as visual record only',
        status: 'PHOTO SAVED as record - nothing is recognised from it; count parts with COUNT',
        lastEvent: 'EVT: photo taken ' + photoBytes + 'B (record only)'
      });
    } catch (e) {
      var firstErr = e;
      if (stream) {
        stream.getTracks().forEach(function (t) { t.stop(); });
        stream = null; this._stream = null;
      }
      // Fallback: wx camera context, like manual-lens / repair-buddy.
      try {
        var ctx = wx.media && wx.media.createCameraContext ? wx.media.createCameraContext() : null;
        if (!ctx) throw firstErr;
        var res = await this._withTimeout(ctx.takePhoto({}), 9000, 'wx photo');
        var size = res && res.data ? res.data.byteLength : 0;
        if (!size) throw firstErr;
        this.setData({
          photoLine: 'PHOTO: wx ' + size + 'B (ImageCapture fallback) - record only',
          status: 'PHOTO SAVED as record - nothing is recognised from it; count parts with COUNT',
          lastEvent: 'EVT: wx photo ' + size + 'B (record only)'
        });
      } catch (e2) {
        this.setData({
          photoLine: 'PHOTO: FAIL - ' + this._err(firstErr) + ' (record only anyway)',
          status: 'LOOK FAIL - no photo taken; pick the kit below and tap START',
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
        var step = this._step();
        var needsText = step.needs.map(function (nd) { return nd.part + nd.qty + '个'; }).join('，');
        text = '第' + (this._stepIdx + 1) + '步：' + step.text + '需要零件：' + needsText + '。';
      } else {
        var k = this._kit();
        text = k.name + '。' + k.parts.replace('PARTS: ', '全部零件：') + '。点开始后，先数齐每一步的零件再动手。';
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
      <text class="title">ASSEMBLE GUIDE</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{steadyText}} - {{stepText}}</text>
    </view>
    <view class="kit-box">
      <text class="box-label">◎ COUNT PARTS BY LOOKING - PHOTO = RECORD ONLY, NOT RECOGNISED</text>
      <text class="kit">{{kitText}}</text>
      <text class="meta">{{partsLine}}</text>
      <text class="meta">{{photoLine}}</text>
      <text class="meta">{{needLine}}</text>
      <text class="meta">{{countLine}}</text>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="lookTap">LOOK</button>
      <button class="btn" bindtap="kitTap">KIT</button>
      <button class="btn" bindtap="countTap">COUNT</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="startTap">START</button>
      <button class="btn" bindtap="nextTap">NEXT</button>
      <button class="btn" bindtap="speakTap">SPEAK</button>
    </view>
    <view class="plan-box">
      <text class="box-label">{{planHead}}</text>
      <text class="step">{{stepBody}}</text>
      <text class="meta">{{warnLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="wrongTap">WRONG?</button>
      <button class="btn" bindtap="demoTap">DEMO （书架）</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 4px 12px;
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
.kit-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 4px 8px;
  margin-bottom: 4px;
}
.box-label {
  color: rgba(64,255,94,0.48);
  font-size: 10px;
  line-height: 14px;
}
.kit {
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
  margin-bottom: 3px;
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
  padding: 4px 8px;
  margin-bottom: 4px;
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
