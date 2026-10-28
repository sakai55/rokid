// Shared in-memory session store for the whole agent instance.
// Frames live ONLY here (memory): nothing in this module touches storage.
// Closing the agent drops the frames; only work metadata (av11_works)
// is ever persisted, by the shoot / play pages. There are no settings:
// constants are FPS 12, TARGET 120 frames, 1 s capture interval,
// 180 s safety cap, all fixed in the shoot page.
//
// Frame entry shapes (v1.1.1 graded capture):
//   { kind: 'url', url }        — JPEG data URL (encoded path, real bytes)
//   { kind: 'px', w, h, img }   — raw ImageData pixels (bitmap fallback)
//   { kind: 'bmp', bmp }        — the ImageBitmap itself (last fallback)
// store.mode latches the frame mode for the whole take once decided:
//   '' (undecided) | 'url' (encode path works) | 'memory' (bitmap mode,
//   target drops to 40 frames for memory safety).
export const store = {
  frames: [],      // frame entries, shapes above
  sizes: [],       // per-frame bytes: real encoded bytes for 'url',
                   // estimated w*h*4 for 'px'/'bmp'
  mode: '',        // '' | 'url' | 'memory'
  encodeError: '', // first encode-path error text (real-device diagnostic)
  startVia: '',    // 'nod' | 'tap' — which start channel fired (diagnostic)
  shootSec: 0,     // actual shooting seconds for the current sequence
  stopReason: '',  // 'target' | 'time' | 'voice' | 'back' | ''
  target: 0,       // effective target of the current sequence (120 or 40)
  startedAt: 0,    // session id (Date.now of first frame)
  measuredFps: null
};

export function resetSession() {
  store.frames = [];
  store.sizes = [];
  store.mode = '';
  store.encodeError = '';
  store.startVia = '';
  store.shootSec = 0;
  store.stopReason = '';
  store.target = 0;
  store.startedAt = 0;
  store.measuredFps = null;
}
