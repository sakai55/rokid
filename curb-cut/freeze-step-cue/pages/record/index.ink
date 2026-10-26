<script def>
{
  "title": "Freeze Record"
}
</script>

<script setup>
import wx from 'wx';

// CC10 v2 record page: session history from wx storage 'freezeStepCueV2'.
const KEY = 'freezeStepCueV2';

export default {
  data: { status: '', s0: '', s1: '', s2: '', s3: '', s4: '', best: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} this._recompute(); },
  _load() { try { const v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) {} return { sessions: [], totalSteps: 0, rhythm: 1 }; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) {} },

  _recompute() {
    const st = this._load();
    const ss = (st.sessions || []).slice(-5).reverse();
    const row = function (s) { return s ? (s.date + ' · ' + s.rhythm + ' · ' + s.steps + ' 步 · ' + s.result) : '—'; };
    let best = 0;
    (st.sessions || []).forEach(function (s) { if (s.steps > best) best = s.steps; });
    this.setData({
      status: '会话记录：共 ' + (st.sessions || []).length + ' 次 · 累计 ' + (st.totalSteps || 0) + ' 步',
      s0: row(ss[0]), s1: row(ss[1]), s2: row(ss[2]), s3: row(ss[3]), s4: row(ss[4]),
      best: '单次最多 ' + best + ' 步（只记本人走出的步数，不做医疗评估）'
    });
  },
  clearTap() { const st = this._load(); st.sessions = []; st.totalSteps = 0; this._save(st); this.setData({ evt: 'EVT: records cleared' }); this._recompute(); },
  backTap() { try { wx.navigateBack({}); } catch (e) {} },
  speakTap() { const st = this._load(); this._speak('共记录' + (st.sessions || []).length + '次，累计' + (st.totalSteps || 0) + '步。'); },
  _speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false;
      speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate');
      return true;
    } catch (e) { return false; }
  },
  onKeyDown(event) { if (event.key === 'Enter' || event.key === 'GlobalHook') { event.preventDefault(); this.speakTap(); } },
  onKeyUp(event) { if (event.key === 'Enter') event.preventDefault(); }
};
</script>

<template>
  <div class="page">
    <div class="ttl">Cue Record</div>
    <div class="status">{{ status }}</div>
    <div class="log">
      <div class="lrow">{{ s0 }}</div>
      <div class="lrow">{{ s1 }}</div>
      <div class="lrow">{{ s2 }}</div>
      <div class="lrow">{{ s3 }}</div>
      <div class="lrow">{{ s4 }}</div>
    </div>
    <div class="best">{{ best }}</div>
    <div class="btnrow">
      <button class="logbtn" bindtap="speakTap">SPEAK</button>
      <button class="logbtn" bindtap="clearTap">CLEAR</button>
      <button class="logbtn" bindtap="backTap">BACK</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page { width: 480px; height: 352px; background-color: #02100a; padding: 12px 16px; box-sizing: border-box; position: relative; }
.ttl { color: #40ff5e; font-size: 19px; font-weight: bold; letter-spacing: 2px; }
.status { color: #7dff9e; font-size: 11px; margin-top: 2px; white-space: nowrap; overflow: hidden; }
.log { margin-top: 12px; border-left: 3px solid rgba(64,255,94,0.6); padding-left: 10px; }
.lrow { color: #40ff5e; font-size: 13px; line-height: 23px; white-space: nowrap; overflow: hidden; }
.best { color: #7dff9e; font-size: 12px; margin-top: 12px; white-space: nowrap; overflow: hidden; }
.btnrow { display: flex; flex-direction: row; margin-top: 14px; }
.logbtn { flex: 1; margin-right: 8px; background-color: transparent; color: #40ff5e; border: 2px solid rgba(64,255,94,0.75); font-size: 13px; padding: 6px 0; text-align: center; border-radius: 50%; }
.btnrow .logbtn:last-child { margin-right: 0; }
.foot { position: absolute; left: 16px; top: 326px; width: 440px; color: rgba(64,255,94,0.6); font-family: monospace; font-size: 9px; white-space: nowrap; overflow: hidden; }
</style>
