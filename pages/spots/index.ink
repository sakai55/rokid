<script def>
{
  "title": "Quiet Corner Spots"
}
</script>

<script setup>
import wx from 'wx';

// CC14 quiet-corner - spots page.
// Saved quiet spots, persisted in wx storage 'quietCornerV1'. Glasses have
// no keyboard, so a new spot name is chosen from six common place names
// (countable constant) and saved together with the last marked quiet
// direction (or "未定" when none is marked yet). ArrowUp/ArrowDown cycle
// the place name, Enter (main action) saves it, nod does the same.
const KEY = 'quietCornerV1';
const SPOT_NAMES = ['超市出口', '车站西口', '公园长椅', '图书馆角落', '商场楼梯间', '医院走廊尽头'];

export default {
  data: { pick: '', s0: '', s1: '', s2: '', s3: '', s4: '', countLine: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { quiet: null, spots: [] }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const st = this._load();
    const spots = (st.spots || []).slice(-5);
    const rows = [];
    for (let i = 0; i < 5; i++) {
      if (i < spots.length) rows.push((spots[i].name) + ' · 往' + spots[i].dir + '走 · ' + spots[i].at);
      else rows.push('');
    }
    this.setData({
      pick: '新增地点：' + SPOT_NAMES[this._sel] + '（上下键换地点，Enter 保存）',
      s0: rows[0], s1: rows[1], s2: rows[2], s3: rows[3], s4: rows[4],
      countLine: '已存安静地点 ' + (st.spots || []).length + ' 个' + (st.quiet ? ' · 最近标记方向：' + st.quiet.dir : ' · 还没有标记方向，保存时方向记为未定')
    });
  },
  addTap() {
    const st = this._load();
    st.spots = st.spots || [];
    const dir = st.quiet ? st.quiet.dir : '未定';
    st.spots.push({ name: SPOT_NAMES[this._sel], dir: dir, at: new Date().toISOString().slice(0, 16) });
    this._save(st);
    this._speak('记下了，' + SPOT_NAMES[this._sel] + '，往' + dir + '走。');
    this.setData({ evt: 'EVT: spot saved - ' + SPOT_NAMES[this._sel] + ' ' + dir });
    this._recompute();
  },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onHeadGesture(event) {
    const d = (event && event.detail) || {}; const g = d.gesture || d.type || d.name || '';
    if (g === 'nod') this.addTap();
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.addTap(); return; }
    if (key === 'ArrowUp') { event.preventDefault(); this._sel = (this._sel + SPOT_NAMES.length - 1) % SPOT_NAMES.length; this._recompute(); return; }
    if (key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % SPOT_NAMES.length; this._recompute(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">安静地点记录</div>
    <div class="pick">{{ pick }}</div>
    <div class="list">
      <div class="srow">{{ s0 }}</div>
      <div class="srow">{{ s1 }}</div>
      <div class="srow">{{ s2 }}</div>
      <div class="srow">{{ s3 }}</div>
      <div class="srow">{{ s4 }}</div>
    </div>
    <div class="count">{{ countLine }}</div>
    <div class="note">过载时少看字：列表只显示地点名、方向与时间，不加评价与说明。</div>
    <div class="btnrow">
      <button class="spotbtn main" bindtap="addTap">保存这个地点</button>
      <button class="spotbtn" bindtap="backTap">返回</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.pick { color: #7dff9e; font-size: 14px; margin-top: 8px; border: 2px solid rgba(64,255,94,0.8); background-color: #061a0b; padding: 8px 10px; border-radius: 12px; white-space: nowrap; overflow: hidden; }
.list { margin-top: 12px; border-top: 2px solid rgba(64,255,94,0.7); border-bottom: 2px solid rgba(64,255,94,0.7); padding: 8px 0; }
.srow { color: #7dff9e; font-size: 13px; line-height: 24px; white-space: nowrap; overflow: hidden; min-height: 24px; }
.count { color: #40ff5e; font-size: 12px; margin-top: 10px; }
.note { color: rgba(125,255,158,0.85); font-size: 11px; margin-top: 6px; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.spotbtn { flex: 1; margin-right: 8px; background-color: #0d2812; color: #40ff5e; border: 1px solid rgba(64,255,94,0.7); font-size: 14px; padding: 7px 0; text-align: center; border-radius: 20px; }
.btnrow .spotbtn:last-child { margin-right: 0; }
.spotbtn.main { background-color: #14541f; color: #7dff9e; font-weight: bold; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
