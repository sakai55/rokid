// Shared in-memory session store for the whole agent instance.
// Frames live ONLY here (memory): nothing in this module touches storage.
// Closing the agent drops the frames; only work metadata (av11_works)
// is ever persisted, by the shoot / play pages. There are no settings:
// v1.1 constants are FPS 12, TARGET 120 frames, 1 s capture interval,
// 180 s safety cap, all fixed in the shoot page.
export const store = {
  frames: [],      // data URLs (JPEG, scaled to 480x352 where the host allows)
  sizes: [],       // per-frame encoded bytes (blob size, or data-URL estimate)
  shootSec: 0,     // actual shooting seconds for the current sequence
  stopReason: '',  // 'target' | 'time' | 'user' | ''
  target: 0,       // target frame count of the current sequence
  startedAt: 0,    // session id (Date.now of first frame)
  measuredFps: null
};

export function resetSession() {
  store.frames = [];
  store.sizes = [];
  store.shootSec = 0;
  store.stopReason = '';
  store.target = 0;
  store.startedAt = 0;
  store.measuredFps = null;
}
