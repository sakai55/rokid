<script def>
{
  "navigationBarTitleText": "Find My Thing"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    status: 'REGISTER: look at the item, pick ITEM + ROOM, SAVE',
    headingLine: 'HEAD: --- deg · SRC: NONE',
    steadyText: 'HEAD: moving - hold still',
    modeLine: 'MODE: REGISTER',
    selLine: 'ITEM: 眼镜盒 · ROOM: 客厅',
    rows: [
      { text: '(no records) - SAVE one here, or DEMO' }
    ],
    countLine: 'SAVED: 0/8 · stored on this device only',
    arrow: '·',
    relLine: 'GUIDE: switch to FIND after saving',
    relCls: 'rel',
    memoryLine: 'MEMORY: ---',
    bleLine: 'BLE: not checked (tap BLE)',
    lastEvent: 'EVT: MODE toggles / nod when steady = SAVE',
    busy: false
  },

  onLoad() {
    this._mode = 'REGISTER';
    this._itemIdx = 0;
    this._roomIdx = 0;
    this._findIdx = 0;
    this._records = this._loadRecords();
    this._heading = null;
    this._headingSrc = 'NONE';
    this._demo = false;
    this._demoHeading = 0;
    this._sensor = null;
    this._timer = null;
    this._steady = false;
    this._lastSpeak = null;
    try { this.enableWorldAwareness(); } catch (e) { /* optional on preview host */ }
    this._startHeading();
    this._startTimer();
    this._recompute();
  },

  onShow() {
    if (!this._sensor && !this._demo) this._startHeading();
    this._startTimer();
  },

  onHide() {
    this._stopTimer();
    this._stopHeading();
  },

  onUnload() {
    this._stopTimer();
    this._stopHeading();
    this._saveRecords();
  },

  onOrientationStabilityChange(event) {
    this._steady = !!(event && event.stable);
    this.setData({
      steadyText: this._steady ? 'HEAD STEADY' : 'HEAD: moving - hold still'
    });
  },

  onHeadGesture(event) {
    var g = (event && event.gesture) || '';
    this.setData({ lastEvent: 'EVT: head gesture ' + g });
    if (g !== 'nod') return;
    if (this._mode === 'REGISTER') {
      if (this._steady) this.saveTap();
      else this.setData({ lastEvent: 'EVT: nod ignored - hold head steady to SAVE' });
    } else {
      this.speakTap();
    }
  },

  onVoiceWakeup(event) {
    this.setData({ lastEvent: 'EVT: wakeup ' + ((event && event.keyword) || '') });
  },

  onKeyDown(event) {
    var code = event && event.code;
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      this.pickTap();
    } else if (code === 'Enter' || code === 'GlobalHook') {
      this.setData({ lastEvent: 'EVT: ' + code + ' confirm' });
      if (this._mode === 'REGISTER') this.saveTap(); else this.speakTap();
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
    return String(e.message || e.name || e).slice(0, 60);
  },

  // ---------- vocab ----------

  _items() { return ['眼镜盒', '钥匙', '遥控器', '钱包', '药瓶', '耳机']; },
  _rooms() { return ['客厅', '卧室', '书房', '厨房', '玄关']; },
  _item() { return this._items()[this._itemIdx || 0]; },
  _room() { return this._rooms()[this._roomIdx || 0]; },

  _nowTime() {
    var d = new Date();
    var hh = d.getHours(); if (hh < 10) hh = '0' + hh;
    var mm = d.getMinutes(); if (mm < 10) mm = '0' + mm;
    return hh + ':' + mm;
  },

  // ---------- persistence (wx sync storage, key 'findMyThing') ----------

  _loadRecords() {
    try {
      var raw = wx.getStorageSync('findMyThing');
      if (!raw || Object.prototype.toString.call(raw) !== '[object Array]') return [];
      var out = [];
      for (var i = 0; i !== raw.length && out.length < 8; i++) {
        var r = raw[i];
        if (r && typeof r.item === 'string' && typeof r.room === 'string' &&
            isFinite(r.heading) && typeof r.time === 'string') {
          out.push({
            item: String(r.item).slice(0, 8),
            room: String(r.room).slice(0, 8),
            heading: ((Math.round(r.heading) % 360) + 360) % 360,
            time: String(r.time).slice(0, 5),
            demo: !!r.demo
          });
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  },

  _saveRecords() {
    try {
      wx.setStorageSync('findMyThing', this._records || []);
    } catch (e) { /* storage unavailable on this host: records stay in memory */ }
  },

  // Newest registration replaces any older record of the same item;
  // beyond 8 records the oldest is dropped.
  _addRecord(rec) {
    var arr = (this._records || []).filter(function (r) { return r.item !== rec.item; });
    arr.push(rec);
    while (arr.length > 8) arr.shift();
    this._records = arr;
    this._saveRecords();
  },

  // ---------- heading (AbsoluteOrientationSensor, same as head-nav) ----------

  _startHeading() {
    var Ctor = typeof AbsoluteOrientationSensor !== 'undefined' ? AbsoluteOrientationSensor : null;
    if (!Ctor) {
      if (!this._demo) this._headingSrc = 'NONE';
      this._recompute();
      return;
    }
    var self = this;
    try {
      var s = new Ctor({ frequency: 5 });
      s.addEventListener('reading', function () { self._onHeading(s); });
      s.addEventListener('error', function (ev) {
        self._headingSrc = 'NONE';
        try { s.stop(); } catch (e) {}
        if (self._sensor === s) self._sensor = null;
        self.setData({ lastEvent: 'EVT: orientation sensor error - heading NONE' });
        self._recompute();
      });
      s.start();
      this._sensor = s;
    } catch (e) {
      this._headingSrc = 'NONE';
      this._sensor = null;
    }
  },

  _stopHeading() {
    if (this._sensor) {
      try { this._sensor.stop(); } catch (e) {}
      this._sensor = null;
    }
  },

  _yawDeg(q) {
    if (!q || q.length < 4) return null;
    var x = q[0], y = q[1], z = q[2], w = q[3];
    var yaw = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    var deg = yaw * 180 / Math.PI;
    return (deg + 360) % 360;
  },

  _onHeading(sensor) {
    if (this._demo) return; // demo heading wins while simulating
    var deg = this._yawDeg(sensor.quaternion);
    if (deg === null) return;
    var changed = this._heading === null || Math.abs(deg - this._heading) >= 1;
    this._heading = deg;
    this._headingSrc = 'SENSOR';
    if (changed) this._recompute();
  },

  _startTimer() {
    if (this._timer) return;
    var self = this;
    this._timer = setInterval(function () {
      if (!self._demo && self._sensor && self._sensor.quaternion) {
        self._onHeading(self._sensor);
      } else {
        self._recompute();
      }
    }, 5000);
  },

  _stopTimer() {
    if (this._timer) { clearInterval(this._timer); this._timer = null; }
  },

  // ---------- mode + selection ----------

  modeTap() {
    this._mode = this._mode === 'REGISTER' ? 'FIND' : 'REGISTER';
    this.setData({
      status: this._mode === 'REGISTER'
        ? 'REGISTER: look at the item, pick ITEM + ROOM, SAVE'
        : 'FIND: PICK an item, turn until you face its heading',
      lastEvent: 'EVT: mode -> ' + this._mode
    });
    this._recompute();
  },

  pickTap() {
    if (this._mode === 'REGISTER') {
      this._itemIdx = ((this._itemIdx || 0) + 1) % this._items().length;
      this.setData({ lastEvent: 'EVT: item -> ' + this._item() });
    } else {
      var n = (this._records || []).length;
      if (!n) {
        this.setData({ lastEvent: 'EVT: no records yet - REGISTER first or DEMO' });
        return;
      }
      this._findIdx = ((this._findIdx || 0) + 1) % n;
      this.setData({ lastEvent: 'EVT: find -> ' + this._records[this._findIdx].item });
    }
    this._recompute();
  },

  roomTap() {
    if (this._mode !== 'REGISTER') {
      this.setData({ lastEvent: 'EVT: ROOM only applies in REGISTER mode' });
      return;
    }
    this._roomIdx = ((this._roomIdx || 0) + 1) % this._rooms().length;
    this.setData({ lastEvent: 'EVT: room -> ' + this._room() });
    this._recompute();
  },

  // ---------- register ----------

  saveTap() {
    if (this._mode !== 'REGISTER') {
      this.setData({ lastEvent: 'EVT: SAVE only applies in REGISTER mode' });
      return;
    }
    if (this._heading === null) {
      this.setData({
        status: 'SAVE FAIL: no heading (SRC NONE) - DEMO or wait for sensor',
        lastEvent: 'EVT: SAVE refused - never invent a heading'
      });
      return;
    }
    var rec = {
      item: this._item(),
      room: this._room(),
      heading: Math.round(this._heading),
      time: this._nowTime(),
      demo: !!this._demo
    };
    this._addRecord(rec);
    this.setData({
      status: 'SAVED: ' + rec.item + ' · ' + rec.room + ' · ' + rec.heading + '° · ' + rec.time,
      lastEvent: 'EVT: registered ' + rec.item + ' at heading ' + rec.heading +
        ' deg' + (rec.demo ? ' (DEMO heading)' : '')
    });
    this._recompute();
  },

  clearTap() {
    this._records = [];
    this._findIdx = 0;
    this._saveRecords();
    this.setData({
      status: this._mode === 'REGISTER'
        ? 'REGISTER: look at the item, pick ITEM + ROOM, SAVE'
        : 'FIND: no records - REGISTER first or DEMO',
      lastEvent: 'EVT: all records cleared'
    });
    this._recompute();
  },

  // ---------- demo ----------

  demoTap() {
    if (!this._demo) {
      this._demo = true;
      this._demoHeading = 0;
      this._heading = 0;
      this._headingSrc = 'DEMO';
      var rec = { item: '遥控器', room: '客厅', heading: 140, time: this._nowTime(), demo: true };
      this._addRecord(rec);
      for (var i = 0; i !== this._records.length; i++) {
        if (this._records[i].item === '遥控器') this._findIdx = i;
      }
      this._mode = 'FIND';
      this.setData({
        status: 'DEMO: sample saved (remote · 客厅 · 140°) - DEMO steps heading +45',
        lastEvent: 'EVT: DEMO on - sample record registered, mode FIND'
      });
    } else {
      this._demoHeading = (this._demoHeading + 45) % 360;
      this._heading = this._demoHeading;
      this._headingSrc = 'DEMO';
      this.setData({
        status: 'DEMO MODE - heading ' + this._demoHeading + ' deg (tap DEMO: +45)',
        lastEvent: 'EVT: DEMO heading -> ' + this._demoHeading + ' deg'
      });
    }
    this._recompute();
  },

  // ---------- BLE proximity capability check (no distance in the API) ----------

  async bleTap() {
    if (typeof navigator === 'undefined' || !navigator.bluetooth ||
        typeof navigator.bluetooth.getAvailability !== 'function') {
      this.setData({
        bleLine: 'BLE: SKIP - bluetooth n/a on this host',
        lastEvent: 'EVT: BLE SKIP - navigator.bluetooth unavailable'
      });
      return;
    }
    try {
      var avail = await navigator.bluetooth.getAvailability();
      this.setData({
        bleLine: avail
          ? 'BLE: available (pair trackers separately)'
          : 'BLE: not available on this device',
        lastEvent: 'EVT: BLE availability = ' + avail + ' (no distance/RSSI in API)'
      });
    } catch (e) {
      this.setData({
        bleLine: 'BLE: SKIP - ' + this._err(e),
        lastEvent: 'EVT: BLE check FAIL - ' + this._err(e)
      });
    }
  },

  // ---------- guidance ----------

  _dirName(rel) {
    var a = Math.abs(rel);
    if (a <= 22.5) return { en: 'FRONT', zh: '正前方' };
    if (a <= 67.5) return rel > 0 ? { en: 'RIGHT-FRONT', zh: '右前方' } : { en: 'LEFT-FRONT', zh: '左前方' };
    if (a <= 112.5) return rel > 0 ? { en: 'RIGHT', zh: '右边' } : { en: 'LEFT', zh: '左边' };
    if (a <= 157.5) return rel > 0 ? { en: 'RIGHT-BACK', zh: '右后方' } : { en: 'LEFT-BACK', zh: '左后方' };
    return { en: 'BACK', zh: '正后方' };
  },

  _findRecord() {
    var recs = this._records || [];
    if (!recs.length) return null;
    var idx = this._findIdx || 0;
    if (idx >= recs.length) idx = 0;
    return recs[idx];
  },

  _recompute() {
    var headTxt = this._heading === null ? '---' : String(Math.round(this._heading));
    var patch = {
      headingLine: 'HEAD: ' + headTxt + ' deg · SRC: ' + this._headingSrc +
        (this._demo ? ' (DEMO)' : ''),
      modeLine: 'MODE: ' + this._mode,
      selLine: 'ITEM: ' + this._item() + ' · ROOM: ' + this._room()
    };
    var recs = this._records || [];
    if (!recs.length) {
      patch.rows = [{ text: '(no records) - SAVE one here, or DEMO' }];
    } else {
      patch.rows = recs.map(function (r) {
        return { text: r.item + ' · ' + r.room + ' · ' + r.heading + '° · ' + r.time + (r.demo ? ' DEMO' : '') };
      });
    }
    patch.countLine = 'SAVED: ' + recs.length + '/8 · stored on this device only';

    var rec = this._findRecord();
    if (!rec) {
      patch.arrow = '·';
      patch.relLine = 'GUIDE: no record selected';
      patch.relCls = 'rel';
      patch.memoryLine = 'MEMORY: ---';
      this._lastSpeak = null;
      this.setData(patch);
      return;
    }
    patch.memoryLine = rec.item + ' · ' + rec.room + ' · 朝向 ' + rec.heading + '° · ' +
      rec.time + ' 登记' + (rec.demo ? ' (DEMO)' : '');
    if (this._heading === null) {
      patch.arrow = '·';
      patch.relLine = 'GUIDE: heading n/a - SRC NONE, tap DEMO';
      patch.relCls = 'rel';
      this._lastSpeak = { rec: rec, facing: false, zh: '', deg: 0 };
      this.setData(patch);
      return;
    }
    var rel = ((rec.heading - this._heading + 540) % 360) - 180; // -180..180, + = right
    var rel360 = (rec.heading - this._heading + 360) % 360;
    var arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    patch.arrow = arrows[Math.round(rel360 / 45) % 8];
    var dir = this._dirName(rel);
    var deg = Math.round(Math.abs(rel));
    var facing = Math.abs(rel) <= 15;
    if (facing) {
      patch.relLine = 'FACING IT — look around there';
      patch.relCls = 'rel rel-on';
    } else {
      patch.relLine = 'TURN: ' + dir.en + ' ' + deg + '° to face it';
      patch.relCls = 'rel';
    }
    this._lastSpeak = { rec: rec, facing: facing, zh: dir.zh, deg: deg };
    this.setData(patch);
  },

  // ---------- speech ----------

  speakTap() {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') {
        this.setData({ lastEvent: 'EVT: SPEAK FAIL - speechSynthesis n/a on this host' });
        return;
      }
      var s = this._lastSpeak;
      var text;
      if (!s || !s.rec) {
        text = '还没有登记记录。先看着物品登记，或者点演示。';
      } else {
        var r = s.rec;
        var parts = r.time.split(':');
        text = r.item + '在' + r.room + '，你当时面朝' + r.heading + '度，' +
          parts[0] + '点' + parts[1] + '分登记。';
        if (s.facing) {
          text += '你现在正对着当时看它的方向，在那附近找找。';
        } else if (s.zh) {
          text += '向你' + s.zh + '转' + s.deg + '度，就对着当时看它的方向。';
        } else {
          text += '现在没有你的朝向读数，先看演示或等传感器。';
        }
      }
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      this.setData({ lastEvent: 'EVT: TTS speak sent: ' + text });
    } catch (e) {
      this.setData({ lastEvent: 'EVT: SPEAK FAIL - ' + this._err(e) });
    }
  }
};
</script>

<page>
  <view class="page">
    <view class="head">
      <text class="title">FIND MY THING</text>
      <text class="status">{{status}}</text>
      <text class="sub">{{headingLine}} · {{steadyText}}</text>
    </view>
    <view class="sel-box">
      <text class="sel-mode">{{modeLine}} · {{selLine}}</text>
      <text class="memory">{{memoryLine}}</text>
    </view>
    <scroll-view class="list" scroll-y="true">
      <view ink:for="{{rows}}" class="row">
        <text class="rtext">{{item.text}}</text>
      </view>
    </scroll-view>
    <text class="count">{{countLine}}</text>
    <view class="guide-box">
      <view class="guide-top">
        <text class="arrow">{{arrow}}</text>
        <text class="{{relCls}}">{{relLine}}</text>
      </view>
      <text class="ble">{{bleLine}}</text>
    </view>
    <view class="actions">
      <button class="btn" bindtap="modeTap">MODE</button>
      <button class="btn" bindtap="pickTap">PICK</button>
      <button class="btn" bindtap="roomTap">ROOM</button>
    </view>
    <view class="actions">
      <button class="btn btn-main" bindtap="saveTap">SAVE</button>
      <button class="btn" bindtap="demoTap">DEMO</button>
      <button class="btn" bindtap="bleTap">BLE</button>
    </view>
    <view class="actions">
      <button class="btn" bindtap="speakTap">SPEAK</button>
      <button class="btn" bindtap="clearTap">CLEAR</button>
    </view>
    <text class="foot">{{lastEvent}}</text>
  </view>
</page>

<style>
.page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  padding: 8px 16px;
  background-color: #000000;
}
.head {
  display: flex;
  flex-direction: column;
  margin-bottom: 5px;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  font-weight: 500;
  line-height: 26px;
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
.sel-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
  padding: 5px 10px;
  margin-bottom: 5px;
}
.sel-mode {
  color: #40ff5e;
  font-size: 12px;
  line-height: 16px;
}
.memory {
  color: rgba(64,255,94,0.72);
  font-size: 12px;
  line-height: 16px;
  margin-top: 1px;
}
.list {
  height: 30px;
  margin-bottom: 2px;
}
.row {
  display: flex;
  flex-direction: row;
  padding: 2px 0;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.rtext {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 11px;
  line-height: 15px;
}
.count {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-bottom: 4px;
}
.guide-box {
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(64,255,94,0.24);
  border-radius: 6px;
  padding: 3px 10px 5px;
  margin-bottom: 5px;
}
.guide-top {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.arrow {
  color: #40ff5e;
  font-size: 28px;
  line-height: 31px;
  margin-right: 10px;
}
.rel {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
}
.rel-on {
  color: #40ff5e;
  background-color: rgba(64,255,94,0.12);
}
.ble {
  color: rgba(64,255,94,0.48);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
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
  padding: 5px;
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
.foot {
  color: rgba(64,255,94,0.72);
  font-family: monospace;
  font-size: 10px;
  line-height: 14px;
  margin-top: 1px;
}
</style>
