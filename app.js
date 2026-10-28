import { initLog } from './logq.js';

export default {
  onLaunch() {
    // Diagnostic log return: flush the previous run's leftover queue,
    // then open this run's session (logq.js; a complete no-op while the
    // channel key is still the placeholder). initLog never throws.
    try { initLog(); } catch (e) {}
    console.log('Stop Motion Studio Launch');
  },
  onShow() {},
  onHide() {},
  globalData: {}
};
