<script def>
{
  "title": "Quiet Corner"
}
</script>

<script setup>
import wx from 'wx';

// CC14 quiet-corner - overload overview (home page).
// Sensory-overload design: when voices and lights arrive together, the
// only question is "which way is quietest". This page shows that one
// answer (or that none is marked yet) and today's saved-spot count, and
// nothing else. State lives in wx storage 'quietCornerV1'.
// Home key contract: ArrowUp/ArrowDown cycle the two destination rows
// (marked with ▶), Enter opens the selected sub-page.
const KEY = 'quietCornerV1';
const DIRS = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];

export default {
  data: { status: '', center: '', ring: '', countLine: '', m0: '', m1: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { quiet: null, spots: [] }; },

  _recompute() {
    const st = this._load();
    const q = st.quiet;
    const ring = DIRS.map(function (d) { return (q && q.dir === d) ? '▶' + d : d; }).join(' · ');
    this.setData({
      status: '过载时，只问一件事：往哪边走最安静',
      center: q ? q.dir : '？',
      ring: ring,
      countLine: q ? ('已标记最安静方向：往' + q.dir + '走 · ' + q.at) : '还没有标记：去扫描页慢慢转一圈，感觉到最安静时点头',
      m0: (this._sel === 0 ? '▶ ' : '· ') + '扫描安静方向',
      m1: (this._sel === 1 ? '▶ ' : '· ') + '安静地点记录（今日 ' + (st.spots || []).length + ' 个）'
    });
  },
  scanTap() { try { wx.navigateTo({ url: '/pages/scan/index' }); } catch (e) {} },
  spotsTap() { try { wx.navigateTo({ url: '/pages/spots/index' }); } catch (e) {} },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); if (this._sel === 0) this.scanTap(); else this.spotsTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">安静角</div>
    <div class="status">{{ status }}</div>
    <div class="compass">
      <div class="center">{{ center }}</div>
    </div>
    <div class="ring">{{ ring }}</div>
    <div class="count">{{ countLine }}</div>
    <div class="menu" bindtap="scanTap">{{ m0 }}</div>
    <div class="menu" bindtap="spotsTap">{{ m1 }}</div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; text-align: center; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.compass { width: 150px; height: 150px; margin-left: 149px; margin-top: 14px; border: 4px solid rgba(64,255,94,0.9); border-radius: 50%; background-color: #061a0b; padding-top: 52px; box-sizing: border-box; }
.center { color: #7dff9e; font-size: 34px; font-weight: bold; }
.ring { color: #40ff5e; font-size: 12px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.count { color: rgba(125,255,158,0.9); font-size: 12px; margin-top: 8px; white-space: nowrap; overflow: hidden; }
.menu { color: #40ff5e; font-size: 15px; line-height: 28px; border-top: 1px solid rgba(64,255,94,0.4); margin-top: 6px; text-align: left; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; text-align: left; }
</style>
