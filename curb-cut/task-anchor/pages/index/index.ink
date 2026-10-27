<script def>
{
  "title": "Task Anchor"
}
</script>

<script setup>
import wx from 'wx';

// CC13 task-anchor - task overview (home page).
// ADHD / time-blindness design: declare ONE task before starting, so the
// task name can stay resident while working. Eight task templates are a
// countable constant; today's task state and logs live in wx storage
// 'taskAnchorV1'. Home key contract: ArrowUp/ArrowDown cycle the two
// destination rows (marked with ▶), Enter opens the selected sub-page.
const KEY = 'taskAnchorV1';
const TEMPLATES = ['写作业', '写报告', '做家务', '做饭', '复习', '整理房间', '回邮件', '运动'];

export default {
  data: { status: '', dialTask: '', dialTime: '', todayLine: '', m0: '', m1: '', t0: '', t1: '', t2: '', t3: '', t4: '', t5: '', t6: '', t7: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._sel = 0; this._recompute(); },
  onShow() { this._sel = 0; this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { current: null, logs: [], totalMinutes: 0, drifts: 0 }; },

  _recompute() {
    const st = this._load();
    const cur = st.current;
    const rows = ['开始专注', '查看记录'];
    this.setData({
      status: '任务锚：一次只做一件事，名字一直在视线里',
      dialTask: cur ? cur.task : '还没有今日任务',
      dialTime: cur ? ('已专注 ' + Math.floor((cur.elapsed || 0) / 60) + ' 分钟' + (cur.done ? ' · 已完成' : '')) : '先选一个任务，再开始',
      todayLine: '今日累计专注 ' + (st.totalMinutes || 0) + ' 分钟 · 完成 ' + (st.logs || []).length + ' 个任务 · 走神自报 ' + (st.drifts || 0) + ' 次',
      m0: (this._sel === 0 ? '▶ ' : '· ') + rows[0],
      m1: (this._sel === 1 ? '▶ ' : '· ') + rows[1],
      t0: TEMPLATES[0], t1: TEMPLATES[1], t2: TEMPLATES[2], t3: TEMPLATES[3],
      t4: TEMPLATES[4], t5: TEMPLATES[5], t6: TEMPLATES[6], t7: TEMPLATES[7]
    });
  },
  focusTap() { try { wx.navigateTo({ url: '/pages/focus/index' }); } catch (e) {} },
  logTap() { try { wx.navigateTo({ url: '/pages/log/index' }); } catch (e) {} },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) {
    const key = event.key;
    if (key === 'ArrowUp' || key === 'ArrowDown') { event.preventDefault(); this._sel = (this._sel + 1) % 2; this._recompute(); return; }
    if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); if (this._sel === 0) this.focusTap(); else this.logTap(); return; }
  },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter'].indexOf(event.key) >= 0) event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">任务锚</div>
    <div class="status">{{ status }}</div>
    <div class="mainrow">
      <div class="dial">
        <div class="diallabel">今日任务</div>
        <div class="dialtask">{{ dialTask }}</div>
        <div class="dialtime">{{ dialTime }}</div>
      </div>
      <div class="side">
        <div class="menu" bindtap="focusTap">{{ m0 }}</div>
        <div class="menu" bindtap="logTap">{{ m1 }}</div>
        <div class="today">{{ todayLine }}</div>
      </div>
    </div>
    <div class="tplhead">任务模板（8 个，去专注页选）：</div>
    <div class="tplrow"><div class="tpl">{{ t0 }}</div><div class="tpl">{{ t1 }}</div><div class="tpl">{{ t2 }}</div><div class="tpl">{{ t3 }}</div></div>
    <div class="tplrow"><div class="tpl">{{ t4 }}</div><div class="tpl">{{ t5 }}</div><div class="tpl">{{ t6 }}</div><div class="tpl">{{ t7 }}</div></div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #000000; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 20px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.mainrow { display: flex; flex-direction: row; margin-top: 12px; }
.dial { width: 190px; height: 150px; border: 3px solid rgba(64,255,94,0.8); border-radius: 50%; background-color: #071c0c; text-align: center; padding-top: 34px; box-sizing: border-box; }
.diallabel { color: rgba(125,255,158,0.8); font-size: 11px; }
.dialtask { color: #7dff9e; font-size: 22px; font-weight: bold; margin-top: 6px; white-space: nowrap; overflow: hidden; }
.dialtime { color: #40ff5e; font-size: 12px; margin-top: 6px; }
.side { flex: 1; margin-left: 16px; }
.menu { color: #40ff5e; font-size: 16px; line-height: 30px; border-bottom: 1px solid rgba(64,255,94,0.4); }
.today { color: rgba(125,255,158,0.85); font-size: 12px; margin-top: 10px; line-height: 18px; }
.tplhead { color: #40ff5e; font-size: 12px; margin-top: 14px; }
.tplrow { display: flex; flex-direction: row; margin-top: 6px; }
.tpl { flex: 1; margin-right: 6px; background-color: #0d2812; color: #7dff9e; border: 1px solid rgba(64,255,94,0.6); font-size: 13px; padding: 5px 0; text-align: center; border-radius: 8px; }
.tplrow .tpl:last-child { margin-right: 0; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
