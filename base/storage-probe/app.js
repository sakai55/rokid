import { initMarker } from './probe.js';

export default {
  onLaunch: function () {
    // Cross-session marker: read the previous value first, then write
    // the updated one. The home page displays the previous launch time
    // and the launch count from this record. Never throws.
    try { initMarker(); } catch (e) {}
    console.log('Storage Probe Launch');
  },
  onShow: function () {},
  onHide: function () {},
  globalData: {}
};
