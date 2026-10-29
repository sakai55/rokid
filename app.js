import { initLog } from './logq.js';

export default {
  onLaunch() {
    // 诊断日志回传：先 flush 上一轮残留队列、再开本轮 session
    // （logq.js；配置两件不齐时完全 no-op）。initLog 永不抛错。
    try { initLog(); } catch (e) {}
    console.log('Real MUD Probe Launch');
  },
  onShow() {},
  onHide() {},
  globalData: {}
};
