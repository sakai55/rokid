<script def>
{
  "title": "七巧板拼图"
}
</script>

<script setup>
import wx from 'wx';

const KEY = "chinaTangramGameV1";
const PUZ = [{"name": "天鹅", "slots": ["颈部上方", "翅膀外侧", "身体下方", "尾部后方"], "ans": 1, "why": "翅膀外侧落板，天鹅展翅成形。"}, {"name": "帆船", "slots": ["桅杆顶部", "船帆右侧", "船身下方", "水面左侧"], "ans": 0, "why": "桅杆顶部落板，帆船扬帆成形。"}, {"name": "房子", "slots": ["屋顶左角", "墙面右侧", "门口下方", "窗户旁边"], "ans": 2, "why": "门口下方落板，房子有了出入。"}, {"name": "猫", "slots": ["耳朵上方", "胡须旁边", "尾巴末端", "爪子前方"], "ans": 3, "why": "爪子前方落板，小猫伸爪成形。"}, {"name": "狗", "slots": ["鼻子前方", "耳朵后方", "身体下方", "尾巴上方"], "ans": 0, "why": "鼻子前方落板，小狗嗅闻成形。"}, {"name": "兔子", "slots": ["长耳顶端", "红眼旁边", "短尾后方", "前腿下方"], "ans": 2, "why": "短尾后方落板，兔子蹦跳成形。"}, {"name": "山", "slots": ["山顶上方", "山腰左侧", "山脚下方", "云雾旁边"], "ans": 1, "why": "山腰左侧落板，群山连绵成形。"}, {"name": "桥", "slots": ["桥头左侧", "桥面中央", "桥洞下方", "桥尾右侧"], "ans": 3, "why": "桥尾右侧落板，石桥贯通成形。"}, {"name": "人跑步", "slots": ["抬起的前脚", "摆动的手臂", "弯曲的后腿", "前倾的身体"], "ans": 2, "why": "弯曲的后腿落板，跑步姿态成形。"}, {"name": "蝴蝶", "slots": ["左翅上方", "右翅下方", "触角顶端", "身体中央"], "ans": 1, "why": "右翅下方落板，蝴蝶振翅成形。"}, {"name": "鱼", "slots": ["鱼头前方", "鱼鳍旁边", "鱼尾后方", "鱼身下方"], "ans": 0, "why": "鱼头前方落板，游鱼摆尾成形。"}, {"name": "宝塔", "slots": ["塔尖顶部", "塔檐右侧", "塔基下方", "塔门旁边"], "ans": 0, "why": "塔尖顶部落板，宝塔高耸成形。"}];
const DEF = {"selected": 0, "best": 0, "records": []};
const STATUS = "家庭聚会时只用头部方向选位、点头落板，玩七巧板";
const GUIDE = "上下切换拼图 · 点头开始 · 拼完 12 幅结算，最佳纪录跨会话保存";
export default {
  data: { status: '', big: '', r0: '', r1: '', r2: '', r3: '', r4: '', r5: '', detail: '', guide: '', evt: 'EVT: ready' },

  onLoad() { try { this.enableWorldAwareness(); } catch (e) {} var st = this._load(); this._idx = (typeof st.selected === 'number') ? st.selected : 0; this._recompute(); },
  onShow() { this._recompute(); },
  _recompute() { var st = this._load(); var d = {}; d.status = STATUS; var i; for (i = 0; i < 5; i++) { var ti = (this._idx - 2 + i + PUZ.length) % PUZ.length; d['r' + i] = ((ti === this._idx ? '▶ ' : '· ') + PUZ[ti].name); } d.r5 = '共 12 幅 · 最佳 ' + (st.best || 0) + ' 分 · 记录 ' + (st.records ? st.records.length : 0) + ' 局'; d.big = PUZ[this._idx].name; d.detail = '第 ' + (this._idx + 1) + ' 幅，共 12 幅'; d.guide = GUIDE; d.evt = 'EVT: ' + PUZ[this._idx].name; this.setData(d); },
  nextTap() { this._idx = (this._idx + 1) % PUZ.length; this._saveSel(); this._recompute(); },
  prevTap() { this._idx = (this._idx + PUZ.length - 1) % PUZ.length; this._saveSel(); this._recompute(); },
  _saveSel() { var st = this._load(); st.selected = this._idx; this._save(st); },
  playTap() { this._saveSel(); this._nav('/pages/play/index'); },
  recordTap() { this._saveSel(); this._nav('/pages/record/index'); },
  primaryTap() { this.playTap(); },
  speakTap() { this._speak(PUZ[this._idx].name + '。'); },
  backTap() { this._back(); },

  _rawLoad() { try { var v = wx.getStorageSync(KEY); if (v) return (typeof v === 'string') ? JSON.parse(v) : v; } catch (e) { this._readErr = true; } return null; },
  _load() { var v = this._rawLoad(); if (this._readErr) { this._readErr = false; this._fail('E5002', 'storage read'); } if (v) return v; return DEF; },
  _save(st) { try { wx.setStorageSync(KEY, st); } catch (e) { this._fail('E5001', 'storage write'); } },
  _fail(code, orig) { try { var st = null; try { var v = wx.getStorageSync(KEY); if (v) st = (typeof v === 'string') ? JSON.parse(v) : v; } catch (e2) {} if (!st) st = DEF; st.lastError = { code: code, slug: 'china-tangram-game', version: '1.0.0', orig: String(orig).slice(0, 60) }; try { wx.setStorageSync(KEY, st); } catch (e3) {} } catch (e) {} this.setData({ evt: code + ' ' + String(orig).slice(0, 40) }); },
  _speak(text) { try { if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return false; speechSynthesis.speak(new SpeechSynthesisUtterance(text), 'immediate'); return true; } catch (e) { this._fail('E3005', 'speak'); return false; } },
  _nav(url) { try { wx.navigateTo({ url: url }); } catch (e) { this._fail('E8001', 'navigate'); } },
  _back() { try { wx.navigateBack(); } catch (e) { this._fail('E8001', 'back'); } },
  onHeadGesture(event) { var d = (event && event.detail) || {}; var g = d.gesture || d.type || d.name || ''; if (g === 'nod') this.primaryTap(); },
  onKeyDown(event) { var key = event.key; if (key === 'Enter' || key === 'GlobalHook') { event.preventDefault(); this.primaryTap(); return; } if (key === 'ArrowUp') { event.preventDefault(); this.prevTap(); return; } if (key === 'ArrowDown') { event.preventDefault(); this.nextTap(); return; } if (key === 'Backspace') { event.preventDefault(); this.backTap(); return; } },
  onKeyUp(event) { if (['ArrowUp', 'ArrowDown', 'Enter', 'Backspace'].indexOf(event.key) >= 0) event.preventDefault(); },

};
</script>

<template>
  <div class="page">
    <div class="band">七巧板拼图</div>
    <div class="status">{{ status }}</div>
    <div class="big">{{ big }}</div>
    <div class="rows">
    <div class="rrow">{{ r0 }}</div>
    <div class="rrow">{{ r1 }}</div>
    <div class="rrow">{{ r2 }}</div>
    <div class="rrow">{{ r3 }}</div>
    <div class="rrow">{{ r4 }}</div>
    <div class="rrow">{{ r5 }}</div>
    </div>
    <div class="detail">{{ detail }}</div>
    <div class="guide">{{ guide }}</div>
    <div class="btnrow">
      <button class="btn main" bindtap="playTap">开始拼图</button>
      <button class="btn" bindtap="recordTap">记录</button>
      <button class="btn" bindtap="nextTap">下一个</button>
      <button class="btn" bindtap="speakTap">语音</button>
    </div>
    <div class="foot">{{ evt }}</div>
  </div>
</template>

<style>
.page{width:480px;height:352px;background-color:#000000;padding:10px 14px;box-sizing:border-box;position:relative;}
.status{color:#7dff9e;font-size:11px;margin-top:6px;white-space:nowrap;overflow:hidden;}
.big{color:#7dff9e;font-size:20px;font-weight:bold;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;}
.rows{margin-top:4px;}
.rrow{color:#7dff9e;font-size:13px;line-height:19px;white-space:nowrap;overflow:hidden;}
.detail{color:#40ff5e;font-size:11px;margin-top:4px;white-space:nowrap;overflow:hidden;}
.guide{color:rgba(64,255,94,0.7);font-size:11px;margin-top:3px;white-space:nowrap;overflow:hidden;}
.btnrow{position:absolute;left:14px;top:296px;width:452px;display:flex;flex-direction:row;}
.btnrow .btn:last-child{margin-right:0;}
.foot{position:absolute;left:14px;top:292px;width:452px;color:rgba(64,255,94,0.6);font-family:monospace;font-size:9px;white-space:nowrap;overflow:hidden;}
.band{background-color:#0a2a1a;color:#7dff9e;font-size:20px;font-weight:bold;padding:7px 12px;border:3px double #40ff5e;text-align:center;}
.btn{flex:1;margin-right:6px;background-color:#0a2a1a;color:#7dff9e;border:1px solid #40ff5e;border-top:4px solid #40ff5e;border-radius:4px;font-size:13px;padding:7px 0;text-align:center;}
.btn.main{background-color:#1d6b33;color:#7dff9e;font-weight:bold;}
</style>
