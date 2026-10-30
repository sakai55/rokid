# Rokid Glasses Local Storage Guide

[中文](STORAGE.md) | English | [日本語](STORAGE.ja.md)

English edition of the Chinese version v1.0.0, dated 2026-10-30. The Chinese text is authoritative; where the two differ, the Chinese governs.

> Compiled 2026-10-30. Current version: v1.0.0, 2026-10-30.
> Sources: official Rokid material only — the documentation site and the `yodaos-project/AIUI` GitHub repository, including the `aiui-dev` skill references bundled with it. Where Rokid has published no figure, this guide says so outright; it never borrows numbers from other platforms.

## About this guide

This guide is maintained by an individual Rokid AIUI developer. It is not a Rokid publication. Its job is to set out the local storage an agent can actually use: what the options are, what each one is suited to, how the code flows, and where the walls are.

The headline: an agent gets three local storage systems — `localStorage`, the wx store, and OPFS file storage. All three live on the glasses, are isolated per agent, and do not talk to each other. The platform offers agents no cloud storage at all: saves never sync to the phone or to a server, and clearing the app's data or uninstalling takes the local saves with it. If a save has to follow the user across devices or live online, you build your own backend.

## 1. The three storage systems

Why three? Because they descend from three different lineages — they are not three copies of one feature:

- **localStorage is the Web lineage.** The Ink runtime is a Web-style container — `fetch`, WebSocket and Streams are all Web APIs — and localStorage comes with the container as the standard Web key-value store. Rokid defines it in the Web API reference: string keys and values, synchronous reads and writes.
- **The wx store is the mini-program lineage.** The platform adopted a set of WeChat Mini Program-compatible APIs, and wx storage is one of them. Rokid's *Storage* guide covers this system and no other, and positions it as a local data cache for JSON-serializable data — user preferences, page state, business caches. As far as the official documentation goes, this is the platform's canonical storage facility.
- **OPFS is the file lineage.** Key-value stores cannot hold large binary blobs, so OPFS adds a file layer on top. Rokid's OPFS page positions it as the place for files, binary resources and offline caches — content whose volume exceeds simple key-value data.

Rokid has never published a comparison of the three, nor declared any of them superseded. They overlap only at the small key-value end, where both localStorage and the wx store work; the dividing line is the shape of the data — key-value goes to the first two, files go to OPFS.

Images make the line concrete: a photo is binary, and neither localStorage nor the wx store can hold it directly — the only route is to base64-encode it into a string first (roughly a third larger, and in localStorage's case a synchronous write that stalls the page on large strings). The proper home is OPFS, writing the Blob as-is. Note that saving a photo into the system media library — the one the wearer browses in the gallery — is a separate path under the `CREATE_MEDIA_IMAGES` permission, not part of these three private stores.

| System | API | Good for | Data shape |
|---|---|---|---|
| localStorage | `localStorage.getItem / setItem / removeItem / clear` | Small settings, flags, cross-session progress pointers | Strings only |
| wx storage | `wx.setStorage / getStorage / removeStorage / clearStorage`, plus Sync variants | User preferences, page state, business caches, the save file itself | JSON-serializable data |
| OPFS | File API starting from `navigator.storage.getDirectory()` | Large files, binaries, anything bigger than key-value volume | Files |

None of the three needs a permission — storage is not among the seven permission names. The `clear`-style calls only ever clear the calling agent's own storage; they cannot touch another agent's.

## 2. localStorage

### Walkthrough: saving and reading back a progress record

```javascript
const KEY = 'myagent.progress';

// 保存：对象先序列化，存档带版本号
function saveProgress(progress) {
  try {
    localStorage.setItem(KEY, JSON.stringify({ v: 1, progress }));
  } catch (e) {
    fail('E5001', e); // 记录保存失败
  }
}

// 读回：取不到是 null；解析失败按存档损坏处理
function loadProgress() {
  let raw;
  try {
    raw = localStorage.getItem(KEY);
  } catch (e) {
    fail('E5002', e);
    return null;
  }
  if (raw === null) return null; // 从未存过
  try {
    const data = JSON.parse(raw);
    if (data.v !== 1) { fail('E5004'); return null; } // 存档版本不兼容
    return data.progress;
  } catch (e) {
    fail('E5002', e);
    return null;
  }
}
```

### Limits

- Keys and values are both coerced to strings. Store an object directly and you get `'[object Object]'` — serializing with `JSON.stringify` is on you.
- The calls are synchronous and execute on the spot. A large write blocks the page, so don't keep bulky data here.
- Rokid publishes no capacity limit (see section 5). A write the quota rejects throws — error code E5003; a missing or disabled API is E5005.

## 3. wx storage

This is the store the official *Storage* guide leads with, and it comes in both an asynchronous and a synchronous API family.

### Walkthrough: saving and loading a save file, async

```javascript
// 写入：结果走 success / fail 回调
wx.setStorage({
  key: 'myagent.save',
  data: { v: 1, level: 3, items: ['a', 'b'] },
  fail(res) { fail('E5001', res.errMsg); },
});

// 读回：成功时 res.data 就是写入的对象
wx.getStorage({
  key: 'myagent.save',
  success(res) {
    const save = res.data;
    // 使用 save 前先查 save.v 做版本迁移
  },
  fail(res) { fail('E5002', res.errMsg); },
});

// 同步版：key 不存在时 getStorageSync 返回 undefined
wx.setStorageSync('myagent.theme', { mode: 'dark' });
const theme = wx.getStorageSync('myagent.theme');
```

### Limits

- Only JSON-serializable data goes in: functions, `undefined` and circular references cannot be stored.
- The async calls require storage support in the current context; without it, the call throws outright. The sync getter, by contrast, returns `undefined` for a key that was never written — it does not throw.
- Rokid publishes neither a per-key size limit nor a total limit (see section 5).

## 4. OPFS file storage

`navigator.storage` exposes a filesystem private to the current agent — OPFS — independent of the other two systems. If the host provides no OPFS backend, calls fail with `NotSupportedError`, so guard for its existence before you use it.

### Walkthrough: check the quota, write a large file, read it back

```javascript
async function writeBigFile(bytes) {
  if (!navigator.storage || !navigator.storage.getDirectory) {
    fail('E5005'); // 持久化不可用
    return;
  }
  // 配额是运行时值：写大文件前先查
  const { usage, quota } = await navigator.storage.estimate();
  if (quota && bytes.length > quota - usage) {
    fail('E5003'); // 存储空间不足
    return;
  }
  await navigator.storage.persist(); // 申请持久化（结果是 boolean，不保证批准）

  const root = await navigator.storage.getDirectory();
  const dir = await root.getDirectoryHandle('save', { create: true });
  const file = await dir.getFileHandle('blob.bin', { create: true });
  const writable = await file.createWritable();
  await writable.write(bytes);
  await writable.close(); // close 之后才真正落盘

  const snapshot = await file.getFile(); // 读回校验
  return snapshot.size;
}
```

### Limits

- `estimate()` reports current usage and a quota, but the quota figure itself is not published anywhere — it is a value the host runtime hands out, and it can differ between devices and versions.
- What ships today is a practical subset, not the full browser File System Access API; neither `StorageManager` nor the handles can be created directly with a constructor.
- Writes land in a buffer first and only commit on `close()`. If something fails halfway, cleaning up the partial file is your job.

## 5. The known limits, in one place

- **No capacity figures are published — for any of the three.** There is no official per-item limit and no official total. The numbers from elsewhere do not transfer: WeChat Mini Programs' 1 MB per key and 10 MB total, and the localStorage allowances common in browsers, do not apply to this platform and must not be substituted for real ones.
- **There is no expiry mechanism.** Nothing in the official material describes a TTL, an expiry time or an automatic cleanup rule. What you store stays stored until you delete it yourself or the user clears the app's data. The converse is also true: Rokid never promises storage will never be reclaimed — OPFS carries dedicated `persisted()` and `persist()` methods precisely because persistence is a state you apply for, not a given.
- **Everything is local; nothing syncs.** None of the three goes over the network or syncs with the phone app. A different device means a brand-new save.
- **Isolation runs in both directions.** An agent cannot read another agent's storage, and it cannot read the host app's data either.
- **Measured numbers are on the way.** Real capacity and the OPFS quota are being measured on actual hardware by the storage probe (`base/storage-probe`), and the results feed back into entries C6001 through C6003 of the capability registry (`docs/CAPABILITIES.md`). Where figures are concerned, the registry is the authority.

## 6. Which one to pick

- Settings, toggles, where you left off: the wx store or localStorage — whichever is closer at hand.
- A structured save — progress, collections, history: the wx store, and give the save object a `v` version field from day one.
- Images, audio, large binaries you generate yourself: OPFS, and call `estimate()` before you write.
- Picking up last session's save and carrying on: any of the three will do — mechanically, there is no expiry gate to clear. What you have to defend against is the save format evolving: keep the version field, write the migrations, and never let an old save crash a new build (error code E5004).

## 7. Changelog

### v1.0.0 — 2026-10-30

First edition. The three storage systems — overview, walkthroughs and known limits — drawn from the official *Storage* guide and the OPFS page. For how measured capacity and quota figures will be fed back, see section 5.
