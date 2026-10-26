<script def>
{
  "navigationBarTitleText": "大表哥"
}
</script>

<script setup>
import { CHANNEL_KEY } from '../../channel.js';

var BASE = 'https://rokidp.datumoj.com';
var POLL_MS = 4000;
var TIMEOUT_MS = 300000;
var END_WORD = '大表哥';
// v1.0.3 tolerance: ASR may drop the first syllable ("大表哥" heard as
// "表哥"); a trailing short form also ends the utterance.
var END_WORD_SHORT = '表哥';
var MAX_CHARS = 500;

export default {
  data: {
    phase: 'idle',
    stateText: '待命 · 点头或单击镜腿开始说话',
    heardText: '',
    heardCls: 'heard heard-dim',
    resTitle: '',
    resBody: '',
    resItems: [],
    choiceLine: '',
    hint: '说完以「大表哥」结尾发送（「表哥」也认） · 停顿没关系，文字都攒着',
    sayLabel: '开始说话',
    appVersion: 'v1.0.3'
  },

  onLoad() {
    this._lastKeyAt = 0;
    this._pollStop = false;
    this._pollStart = 0;
    this._rec = null;
    this._submitted = false;
    this._buffer = '';
    this._wantListen = false;
    this._tapFinish = false;
    this._restarts = 0;
    this._gotFinal = false;
    try { this.enableWorldAwareness(); } catch (e) { /* optional */ }
    this._ensureSession();
    this._resume();
  },

  onUnload() {
    this._pollStop = true;
    this._wantListen = false;
    if (this._rec) { try { this._rec.abort(); } catch (e) {} this._rec = null; }
  },

  // ---------- session / storage ----------

  _ensureSession() {
    var sid = '';
    try { sid = localStorage.getItem('dabiaoge_session') || ''; } catch (e) {}
    if (!sid) {
      sid = 's-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
      try { localStorage.setItem('dabiaoge_session', sid); } catch (e) {}
    }
    this._session = sid;
  },

  _storeTicket(tid) {
    try {
      if (tid) localStorage.setItem('dabiaoge_ticket', tid);
      else localStorage.removeItem('dabiaoge_ticket');
    } catch (e) {}
  },

  // Cold start: an unfinished ticket from last time is checked once
  // before idling - the channel never loses a ticket when the
  // glasses close mid-wait.
  _resume() {
    var tid = '';
    try { tid = localStorage.getItem('dabiaoge_ticket') || ''; } catch (e) {}
    if (!tid) return;
    this._pollStart = Date.now();
    this._poll(tid, true);
  },

  // ---------- demo states (preview / screenshot only) ----------
  // The footer demo button cycles sample states so previews and the
  // device checklist can show every screen without real ASR/network.
  // Samples are labelled as demo data on screen; the default entry
  // is always the real idle state and no demo path ever submits.
  onDemo() { this._cycleDemo(); },

  _cycleDemo() {
    var order = ['working', 'list', 'text', 'idle'];
    var idx = this._demoIdx || 0;
    this._demoIdx = idx + 1;
    this._applyDemo(order[idx % order.length]);
  },

  _applyDemo(mode) {
    if (mode === 'working') {
      this.setData({
        phase: 'working',
        stateText: 'Muse 正在处理 · 已等 24s',
        heardText: '今天有什么值得看的新闻',
        heardCls: 'heard',
        resTitle: '', resBody: '', resItems: [], choiceLine: '',
        sayLabel: '处理中…',
        hint: '演示状态（示例数据） · 再点演示看下一态'
      });
      return;
    }
    if (mode === 'list') {
      this.setData({ heardText: '列出今天的开发清单', heardCls: 'heard' });
      this._showEnvelope({
        type: 'list', title: '今日开发清单', body: '今天完成的三批：',
        items: ['路缘坡 CC06–CC08', '头动游戏 GA24–GA26', '日韩新批 3 个'],
        choices: [], speak: '三批都完成了。'
      }, false);
      this.setData({ hint: '演示状态（示例数据） · 再点演示看下一态' });
      return;
    }
    if (mode === 'text') {
      this.setData({ heardText: '用一句话说说今天的天气', heardCls: 'heard' });
      this._showEnvelope({
        type: 'text', title: '今日天气',
        body: '东京今天晴，最高 21 度，傍晚起风，出门加件外套。',
        items: [], choices: [], speak: '今天晴，最高二十一度。'
      }, false);
      this.setData({ hint: '演示状态（示例数据） · 再点演示回待命' });
      return;
    }
    this.setData({
      phase: 'idle',
      stateText: '待命 · 点头或单击镜腿开始说话',
      heardText: '',
      heardCls: 'heard heard-dim',
      resTitle: '', resBody: '', resItems: [], choiceLine: '',
      sayLabel: '开始说话',
      hint: '说完以「大表哥」结尾发送（「表哥」也认） · 停顿没关系，文字都攒着'
    });
  },

  // ---------- gestures ----------

  onKeyDown(event) {
    var code = event && event.code;
    if (code !== 'Enter' && code !== 'GlobalHook') return;
    var now = Date.now();
    if (now - this._lastKeyAt < 400) return;
    this._lastKeyAt = now;
    this._primary();
  },

  onHeadGesture(event) {
    if (!event || event.gesture !== 'nod') return;
    var now = Date.now();
    if (now - this._lastKeyAt < 400) return;
    this._lastKeyAt = now;
    this._primary();
  },

  onPrimary() { this._primary(); },

  _primary() {
    var ph = this.data.phase;
    if (ph === 'idle' || ph === 'result') this._startListening();
    else if (ph === 'listening') this._stopListening();
    // working: ignore - the poll owns the screen until done/timeout
  },

  // ---------- ASR (accumulate + end word) ----------
  // The host ASR endpoints on ITS OWN silence rule, which the app
  // cannot tune: a mid-sentence pause would cut the user off. So a
  // final segment no longer submits. Segments accumulate on screen
  // and are sent only when the accumulated text ends with the end
  // word (END_WORD, stripped before submit), or when the user
  // taps/nods to send now. After each host endpoint the recognizer
  // restarts itself while listening is still wanted.

  _startListening() {
    var SR = typeof SpeechRecognition !== 'undefined' ? SpeechRecognition : null;
    if (!SR) {
      this._showPlain('无法开始识别', '这台设备没有可用的语音识别（SpeechRecognition 不可用）。', '');
      return;
    }
    this._submitted = false;
    this._buffer = '';
    this._wantListen = true;
    this._tapFinish = false;
    this._restarts = 0;
    this.setData({
      phase: 'listening',
      stateText: '正在听 · 说吧，停顿没关系',
      heardText: '',
      heardCls: 'heard',
      resTitle: '', resBody: '', resItems: [], choiceLine: '',
      sayLabel: '发送',
      hint: '说完最后说「大表哥」自动发送 · 或单击镜腿发送'
    });
    this._launchRec();
  },

  _launchRec() {
    var SR = typeof SpeechRecognition !== 'undefined' ? SpeechRecognition : null;
    if (!SR) return;
    var self = this;
    var rec = null;
    try {
      rec = new SR();
      rec.continuous = false;
      rec.interimResults = true;
      rec.maxAlternatives = 1;
    } catch (e) {
      this._wantListen = false;
      this._showPlain('无法开始识别', '语音识别启动失败：' + this._err(e), '');
      return;
    }
    this._rec = rec;
    this._gotFinal = false;
    rec.onresult = function (ev) { self._onResult(ev); };
    rec.onerror = function (ev) {
      if (self._submitted) return;
      self._rec = null;
      if (self._tapFinish) {
        self._tapFinish = false;
        self._finishBuffer();
        return;
      }
      self._wantListen = false;
      self._showPlain('识别失败', '没能听清（' + String((ev && ev.error) || 'error') + '）。已攒到的文字还留在屏上，单击再试。', '');
    };
    rec.onend = function () { self._onRecEnd(); };
    try {
      rec.start();
    } catch (e) {
      this._rec = null;
      if (this._wantListen && !this._submitted) {
        this._wantListen = false;
        this._showPlain('无法开始识别', '语音识别启动失败：' + this._err(e), '');
      }
    }
  },

  _onResult(ev) {
    if (this._submitted) return;
    var finalText = '', interim = '';
    try {
      for (var i = ev.resultIndex; i < ev.results.length; i++) {
        var r = ev.results[i];
        var t = (r && r[0]) ? String(r[0].transcript || '') : '';
        if (r && r.isFinal) finalText += t; else interim += t;
      }
    } catch (e) {}
    if (interim) {
      this.setData({ heardText: (this._buffer || '') + interim });
    }
    if (finalText) {
      this._gotFinal = true;
      this._restarts = 0;
      this._buffer = (this._buffer || '') + finalText;
      this.setData({ heardText: this._buffer });
      this._checkEnd();
    }
  },

  _onRecEnd() {
    this._rec = null;
    if (this._submitted) return;
    if (this._tapFinish) {
      this._tapFinish = false;
      this._finishBuffer();
      return;
    }
    if (!this._wantListen) return;
    if (this.data.phase !== 'listening') return;
    if (!this._gotFinal) {
      this._restarts = (this._restarts || 0) + 1;
      if (this._restarts >= 6) {
        this._wantListen = false;
        this.setData({
          phase: 'idle',
          stateText: '待命 · 点头或单击镜腿开始说话',
          sayLabel: '开始说话',
          hint: '一直没听到声音 · 单击再试'
        });
        return;
      }
    }
    this._launchRec();
  },

  _stopListening() {
    // Tap/nod while listening = send now. stop() lets the host
    // flush its pending final segment first; _onRecEnd then
    // finishes with whatever has accumulated on screen.
    this._tapFinish = true;
    if (this._rec) {
      try { this._rec.stop(); } catch (e) { this._tapFinish = false; this._finishBuffer(); }
    } else {
      this._tapFinish = false;
      this._finishBuffer();
    }
  },

  // Strip trailing punctuation/whitespace for end-word tests.
  _trimTail(s) {
    return String(s || '').replace(/[\s，。！？、；：,.!?;:]+$/, '');
  },

  // Length of the end word at the tail (0 = none). Accepts the full
  // end word and its short form (see END_WORD_SHORT).
  _endHit(tail) {
    if (tail.slice(-END_WORD.length) === END_WORD) return END_WORD.length;
    if (tail.slice(-END_WORD_SHORT.length) === END_WORD_SHORT) return END_WORD_SHORT.length;
    return 0;
  },

  _checkEnd() {
    var tail = this._trimTail(this._buffer);
    var hit = this._endHit(tail);
    if (hit > 0) {
      var body = this._trimTail(tail.slice(0, tail.length - hit));
      if (!body) {
        // Only the end word so far: keep listening, ask for content.
        this._buffer = '';
        this.setData({
          heardText: '',
          stateText: '正在听 · 先说事，最后再说「大表哥」',
          hint: '刚才只有结束词，还没攒到内容'
        });
        return;
      }
      this._finish(body);
      return;
    }
    if (this._buffer.length >= MAX_CHARS) {
      this._finish(this._trimTail(this._buffer));
    }
  },

  _finishBuffer() {
    var text = this._trimTail(this._buffer);
    var hit = this._endHit(text);
    if (hit > 0) {
      text = this._trimTail(text.slice(0, text.length - hit));
    }
    this._finish(text);
  },

  // The text that is sent STAYS on screen (the user sees exactly
  // what was heard and sent). No audio ever leaves the glasses.
  _finish(text) {
    if (this._submitted) return;
    this._submitted = true;
    this._wantListen = false;
    this._tapFinish = false;
    var clean = String(text || '').trim();
    this.setData({ heardText: clean, heardCls: 'heard' });
    if (this._rec) { try { this._rec.abort(); } catch (e) {} this._rec = null; }
    if (!clean) {
      this._showPlain('没听清', '还没有攒到内容。回待命后单击再说一遍。', '');
      return;
    }
    this._submit(clean);
  },

  // ---------- channel ----------

  _submit(text) {
    if (!CHANNEL_KEY || CHANNEL_KEY === 'PASTE_CHANNEL_KEY_HERE') {
      this._showPlain('钥匙未填', 'channel.js 里还是占位符：打包前要在 Studio 里把占位符换成真钥匙（见 README）。', '');
      return;
    }
    this.setData({
      phase: 'working',
      stateText: '已发送 · 等 Muse 接单',
      sayLabel: '处理中…',
      hint: '单子已进队列 · 可以放下眼镜，回来自动补收结果'
    });
    var self = this;
    fetch(BASE + '/submit', {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-channel-key': CHANNEL_KEY },
      body: JSON.stringify({ session: this._session, kind: 'ask', text: text })
    }).then(function (resp) {
      return resp.json().then(function (j) { return { status: resp.status, body: j }; });
    }).then(function (r) {
      if (r.status === 401) {
        self._showPlain('钥匙不对', '前门拒绝了这把钥匙（401）。检查 channel.js 里填的钥匙是否正确。', '');
        return;
      }
      if (!r.body || !r.body.ticket) {
        self._showPlain('投单失败', '前门没有返回单号。稍后单击再问一句重试。', '');
        return;
      }
      self._storeTicket(r.body.ticket);
      self._pollStart = Date.now();
      self._poll(r.body.ticket, false);
    }).catch(function (e) {
      self._showPlain('网络没通', '投单没发出去（' + self._err(e) + '）。检查眼镜与手机的连接后重试。', '');
    });
  },

  _poll(tid, isResume) {
    if (this._pollStop) return;
    var self = this;
    fetch(BASE + '/ticket/' + encodeURIComponent(tid), {
      headers: { 'x-channel-key': CHANNEL_KEY }
    }).then(function (resp) {
      return resp.json().then(function (j) { return { status: resp.status, body: j }; });
    }).then(function (r) {
      var b = r.body || {};
      var st = b.status || '';
      if (st === 'done') {
        self._storeTicket('');
        self._showEnvelope(b.result || {}, true);
        return;
      }
      if (st === 'needs-approval') {
        self._storeTicket('');
        self._showPlain('需要你批准', '这件事要你在手机上批准，已挂起。', '');
        return;
      }
      if (st === 'error') {
        self._storeTicket('');
        self._showPlain('处理失败', 'Muse 那边没能办成（' + String(b.error || 'error').slice(0, 40) + '）。单击再问一句。', '');
        return;
      }
      // queued | working | unknown -> keep waiting
      var waited = Math.round((Date.now() - self._pollStart) / 1000);
      if (waited * 1000 >= TIMEOUT_MS) {
        self._showPlain('还在处理中', '等了 300 秒还没回。单子不会丢：退出后下次打开大表哥会自动补收。', '');
        return;
      }
      self.setData({
        phase: 'working',
        stateText: (st === 'working' ? 'Muse 正在处理' : '已排队') + ' · 已等 ' + waited + 's',
        sayLabel: '处理中…',
        hint: isResume ? '正在补收上次的单子…' : '单子已进队列 · 可以放下眼镜，回来自动补收结果'
      });
      setTimeout(function () { self._poll(tid, isResume); }, POLL_MS);
    }).catch(function (e) {
      var waited2 = Math.round((Date.now() - self._pollStart) / 1000);
      if (waited2 * 1000 >= TIMEOUT_MS) {
        self._showPlain('还在处理中', '网络多次不通，先等到这里。单子不会丢，下次打开会自动补收。', '');
        return;
      }
      setTimeout(function () { self._poll(tid, isResume); }, POLL_MS);
    });
  },

  // ---------- rendering ----------

  _showEnvelope(env, speakIt) {
    var title = String(env.title || '');
    var body = String(env.body || '');
    var items = [];
    if (env.type === 'list' && env.items) {
      items = env.items.map(function (s) { return '· ' + String(s); });
    }
    var choices = '';
    if (env.type === 'choices' && env.choices && env.choices.length) {
      choices = env.choices.map(function (s) { return String(s); }).join('  ·  ');
    }
    this.setData({
      phase: 'result',
      stateText: '已完成',
      resTitle: title,
      resBody: body,
      resItems: items,
      choiceLine: choices,
      sayLabel: '再问一句',
      hint: '单击或点头再问一句'
    });
    // v1.0.3: a non-empty speak is ALWAYS read once. The front door
    // fills an empty speak with the body, so "speak === body" is the
    // normal short-answer case (read the body once), not a duplicate.
    if (speakIt && env.speak) {
      this._announce(String(env.speak));
    }
  },

  _showPlain(title, body, speak) {
    this.setData({
      phase: 'result',
      stateText: title,
      resTitle: title,
      resBody: body,
      resItems: [],
      choiceLine: '',
      sayLabel: '再问一句',
      hint: '单击或点头再问一句'
    });
    if (speak) this._announce(speak);
  },

  _announce(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text));
    } catch (e) { /* TTS must never break the flow */ }
  },

  _err(e) {
    if (!e) return 'unknown error';
    return String(e.message || e.name || e).slice(0, 48);
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">大表哥</text>
      <text class="state">{{stateText}}</text>
    </view>
    <view class="heard-box">
      <text class="heard-label">你说的是</text>
      <text class="{{heardCls}}">{{heardText}}</text>
    </view>
    <view class="reply">
      <text class="res-title">{{resTitle}}</text>
      <text class="res-body">{{resBody}}</text>
      <view class="items">
        <text ink:for="{{resItems}}" class="res-item">{{item}}</text>
      </view>
      <text class="choices">{{choiceLine}}</text>
    </view>
    <view class="actions">
      <button class="btn-say" bindtap="onPrimary">{{sayLabel}}</button>
    </view>
    <view class="foot-row">
      <text class="foot">{{hint}}</text>
      <button class="btn-demo" bindtap="onDemo">演示</button>
      <text class="ver">{{appVersion}}</text>
    </view>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 12px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 8px;
}
.title {
  color: #7dff9e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
}
.state {
  color: rgba(125,255,158,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
  margin-top: 2px;
}
.heard-box {
  border: 1px dashed rgba(125,255,158,0.55);
  border-radius: 2px;
  padding: 6px 8px;
  margin-bottom: 8px;
}
.heard-label {
  color: rgba(125,255,158,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.heard {
  color: #7dff9e;
  font-size: 15px;
  line-height: 20px;
  margin-top: 2px;
}
.heard-dim {
  color: rgba(125,255,158,0.4);
  font-size: 15px;
  line-height: 20px;
  margin-top: 2px;
}
.reply {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}
.res-title {
  color: #7dff9e;
  font-size: 17px;
  font-weight: 500;
  line-height: 22px;
}
.res-body {
  color: rgba(125,255,158,0.88);
  font-size: 14px;
  line-height: 19px;
  margin-top: 3px;
}
.items {
  display: flex;
  flex-direction: column;
  margin-top: 4px;
}
.res-item {
  color: rgba(125,255,158,0.88);
  font-size: 13px;
  line-height: 18px;
}
.choices {
  color: #7dff9e;
  font-family: monospace;
  font-size: 12px;
  line-height: 16px;
  margin-top: 6px;
}
.btn-say {
  width: 100%;
  color: #7dff9e;
  background-color: rgba(125,255,158,0.10);
  border: 2px solid #7dff9e;
  border-radius: 999px;
  padding: 9px 8px;
  font-size: 15px;
  font-weight: 500;
  line-height: 19px;
  text-align: center;
}
.foot-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-top: 8px;
}
.btn-demo {
  color: rgba(125,255,158,0.6);
  background-color: rgba(125,255,158,0.06);
  border: 1px dashed rgba(125,255,158,0.48);
  border-radius: 999px;
  padding: 2px 9px;
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  text-align: center;
  margin-right: 8px;
}
.foot {
  flex-grow: 1;
  color: rgba(125,255,158,0.6);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
}
.ver {
  color: rgba(125,255,158,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  text-align: right;
}
</style>
