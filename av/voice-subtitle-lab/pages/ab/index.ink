<script def>{"title":"Voice Subtitle Lab - AB"}</script>

<script setup>
import wx from 'wx';

// AV06 ab: A/B side-by-side. Combos are saved from the synth page
// (av06_ab_tmp). Cross-page replay cannot reuse a live task object, so
// PLAY re-synthesizes that combo honestly and plays the fresh task.

export default {
  data: { status: 'A/B 对照：上下选胜出组，Enter 定胜出（各自可重合成播放）', aText: 'A 组：尚未保存（去合成页存A）', bText: 'B 组：尚未保存（去合成页存B）', winnerText: '胜出：未定', evt: 'EVT: ready', ver: 'v1.0.0', steady: 'HEAD: -' },

  onLoad() {
    this._steady = false; this._winner = ''; this._sel = 0; this._ab = null; this._players = {};
    try { this.enableWorldAwareness(); } catch (e) {}
    this._show();
  },
  onShow() { this._show(); },

  _loadTmp(k) { try { const v = wx.getStorageSync(k); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return null; },
  _saveTmp(k, v) { try { wx.setStorageSync(k, v); } catch (e) {} },

  _fmt(side) {
    const s = (this._ab || {})[side];
    if (!s || !s.combo) return side + ' 组：尚未保存（去合成页存' + side + '）';
    const c = s.combo;
    return side + ' 组：' + c.voice + ' · rate ' + c.rate + ' · pitch ' + c.pitch + ' · 耗时 ' + (s.ms != null ? s.ms + 'ms' : '—') + ' · 时长 ' + (s.duration || '—') + ' · 字幕 ' + (s.cueCount || 0) + ' 词';
  },
  _show() {
    this._ab = this._loadTmp('av06_ab_tmp') || {};
    this.setData({ aText: this._fmt('A'), bText: this._fmt('B'), winnerText: '胜出：' + (this._winner ? (this._winner + ' 组（待去收藏页入藏）') : '未定 — 当前指向 ' + (this._sel === 0 ? 'A' : 'B') + ' 组') });
  },

  async playTap(e) {
    const side = (e && e.currentTarget && e.currentTarget.dataset) ? String(e.currentTarget.dataset.side || '') : '';
    const s = (this._ab || {})[side];
    if (!s || !s.combo) { this.setData({ evt: 'EVT: no combo ' + side }); return; }
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined' || typeof speechSynthesis.synthesize !== 'function' || typeof SpeechAudioPlayer === 'undefined') {
        this.setData({ status: '宿主无 synthesize/SpeechAudioPlayer — 无法重放，如实显示', evt: 'EVT: replay unavailable' });
        return;
      }
      const c = s.combo;
      const utt = new SpeechSynthesisUtterance(c.scriptText || '');
      try { utt.voice = c.voice; } catch (err) { this.setData({ status: '宿主拒绝 voice 赋值 — 无法重放', evt: 'EVT: voice rejected' }); return; }
      utt.rate = c.rate; utt.pitch = c.pitch;
      const task = await speechSynthesis.synthesize(utt, { subtitles: 'word', audio: { preferredFormat: c.format, sampleRate: c.sampleRate } });
      const player = new SpeechAudioPlayer(task);
      this._players[side] = player;
      if (typeof player.play === 'function') player.play();
      this.setData({ status: side + ' 组重合成播放中（跨页不能复用旧 task，故重新 synthesize）', evt: 'EVT: replaying ' + side });
    } catch (err) {
      this.setData({ status: '重放失败：' + String((err && err.message) || err).slice(0, 50), evt: 'EVT: replay failed' });
    }
  },

  pickTap() {
    const side = this._sel === 0 ? 'A' : 'B';
    const s = (this._ab || {})[side];
    if (!s || !s.combo) { this.setData({ status: side + ' 组还没有组合 — 先去合成页保存', evt: 'EVT: winner blocked' }); return; }
    this._winner = side;
    this._saveTmp('av06_winner_tmp', s);
    this.setData({ evt: 'EVT: winner ' + side });
    this._show();
    this.setData({ status: side + ' 组胜出 — 去收藏页按 Enter 入藏' });
    this._speak(side + '组胜出');
  },
  moveTap() { this._sel = this._sel === 0 ? 1 : 0; this._show(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  favsTap() { try { wx.navigateTo({ url: '/pages/favs/index' }); } catch (e) {} },

  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onOrientationStabilityChange(event) { const d = (event && event.detail) || event || {}; this._steady = !!(d.isStable === true || d.stable === true); this.setData({ steady: this._steady ? 'HEAD: steady' : 'HEAD: moving' }); },
  onHeadGesture(event) { const d = (event && event.detail) || event || {}; const g = d.gesture || d.type || d.name || ''; if (g === 'nod' && this._steady) this.pickTap(); },
  onKeyDown(event) {
    var k = event.key || event.code; var key = k;
    if (key === 'Enter') {  this.pickTap(); return; }
    if (key === 'ArrowDown' || key === 'ArrowUp') {  this.moveTap(); return; }
  },
  onKeyUp(event) { if (['Enter', 'ArrowUp', 'ArrowDown'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<page>
  <view class="page">
    <view class="topbar"><button class="backbtn" bindtap="backTap">BACK</button><text class="ttl">A/B 对照</text></view>
    <text class="status">{{status}}</text>
    <view class="abbox">
      <text class="abtext">{{aText}}</text>
      <button class="stagebtn play" data-side="A" bindtap="playTap">播放 A（重合成）</button>
    </view>
    <view class="abbox">
      <text class="abtext">{{bText}}</text>
      <button class="stagebtn play" data-side="B" bindtap="playTap">播放 B（重合成）</button>
    </view>
    <text class="line bright">{{winnerText}} · {{steady}}</text>
    <view class="btnrow">
      <button class="stagebtn" bindtap="moveTap">切换指向</button>
      <button class="stagebtn" bindtap="pickTap">定胜出</button>
      <button class="stagebtn" bindtap="favsTap">去收藏</button>
    </view>
    <text class="foot">{{evt}} · {{ver}}</text>
  </view>
</page>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 10px 14px; box-sizing: border-box; position: relative; font-family: monospace; }
.topbar { display: flex; flex-direction: row; align-items: center; }
.backbtn { background-color: #000000; color: #40ff5e; border: 1px solid #40ff5e; border-radius: 10px; font-size: 10px; padding: 3px 8px; margin-right: 10px; }
.ttl { color: #7dff9e; font-size: 17px; font-weight: bold; }
.status { color: #40ff5e; font-size: 11px; display: block; margin-top: 3px; }
.abbox { margin-top: 8px; border: 1px solid rgba(125,255,158,0.65); background-color: #04140a; padding: 9px 10px; }
.abtext { color: #7dff9e; font-size: 12px; display: block; line-height: 17px; }
.line { color: rgba(125,255,158,0.9); font-size: 11px; display: block; margin-top: 7px; }
.bright { color: #7dff9e; }
.btnrow { display: flex; flex-direction: row; margin-top: 8px; }
.stagebtn { flex: 1; margin-right: 6px; background-color: #000000; color: #40ff5e; border: 1px solid rgba(64,255,94,0.85); border-radius: 10px; font-size: 11px; padding: 5px 0; text-align: center; }
.play { margin-top: 7px; width: 170px; flex: none; }
.foot { position: absolute; left: 14px; top: 328px; color: rgba(64,255,94,0.6); font-size: 9px; }
</style>
