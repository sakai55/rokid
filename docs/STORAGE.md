# Rokid Glasses 本地存储说明

中文 | [English](STORAGE.en.md) | [日本語](STORAGE.ja.md)

> 编制日期：2026-10-30；当前版本 v1.0.0，2026-10-30
> 资料原则：只采用 Rokid 官方来源（官方文档站、官方 GitHub 仓库 `yodaos-project/AIUI` 及其内置的 `aiui-dev` skill 参考）。官方没有公布的数字，本文一律写明「未公布」，不拿其他平台的数值代用。

## 写在前面

本文由一名 Rokid AIUI 开发者维护，不是 Rokid 官方文件。它把 Agent 能用的本地存储讲清楚：有哪几套、各适合存什么、流程怎么写、边界在哪。

先说总纲：Agent 的本地存储共有三套——`localStorage`、wx 存储、OPFS 文件存储。三套都在眼镜本地、按 Agent 隔离、互不相通。平台没有给 Agent 提供任何云端存储：存档不会同步到手机或云端，用户清除应用数据或卸载后，本地存档随之消失；要跨设备或联机保存，只能自建后端。

## 1. 三套存储总览

为什么有三套？因为它们来自三条不同的血统，不是同一功能的三个副本：

- **localStorage 是 Web 血统**。运行时 Ink 是 Web 风格的容器（fetch、WebSocket、Streams 都是 Web 接口），localStorage 作为 Web 标准的键值存储随容器自带，官方在 Web API 参考里定义它：字符串键值、同步读写。
- **wx 存储是小程序血统**。平台收了一套微信小程序兼容接口，wx 存储是其中之一；官方的《存储》指南通篇只讲这一套，给它的定位是「本地数据缓存，适合保存用户偏好、页面状态和业务缓存等 JSON 可序列化数据」。就官方文档而言，这一套才是平台正典的存储功能。
- **OPFS 是文件血统**。键值存储装不下大块二进制，OPFS 补上文件这一层；官方 OPFS 专页给它的定位是「保存文件、二进制资源、离线缓存和体积超过简单键值数据的持久化内容」。

官方从未发文比较三套、也没有宣布谁取代谁；重叠只发生在小数据键值这一段（localStorage 与 wx 存储都能存），分工线在数据形态：键值归前两套，文件归 OPFS。

拿图片作例：图片是二进制，localStorage 与 wx 存储都不能直存——只能先转成 base64 字符串绕存（体积膨胀约三分之一，localStorage 还是同步写入、大字符串会卡页面），正道是 OPFS 直接写 Blob。另注意，把照片存进系统媒体库（用户在相册里能看到）走的是 `CREATE_MEDIA_IMAGES` 权限，不属于这三套私有存储。

| 系统 | 接口 | 适合存什么 | 数据形式 |
|---|---|---|---|
| localStorage | `localStorage.getItem / setItem / removeItem / clear` | 小的设置、标记、跨会话进度指针 | 只有字符串 |
| wx 存储 | `wx.setStorage / getStorage / removeStorage / clearStorage` 及同步版 | 用户偏好、页面状态、业务缓存、存档本体 | JSON 可序列化数据 |
| OPFS | `navigator.storage.getDirectory()` 起的文件 API | 大文件、二进制、超过键值体积的内容 | 文件 |

三套都不需要申请权限（不在七个权限名之列）。`clear` 类接口只清当前 Agent 自己的存储，清不到别人的。

## 2. localStorage

### 流程示例：保存与读回一份进度

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

### 边界

- 键和值都强制转成字符串。直接存对象得到的是 `'[object Object]'`，必须自己 `JSON.stringify`。
- 同步接口：调用即执行，大数据量写入会阻塞页面，别拿它存大块数据。
- 官方未公布容量上限（见第 5 节）。写入被配额拒绝时抛错，对应错误码 E5003；接口不存在或被禁用对应 E5005。

## 3. wx 存储

官方存储指南的主推口，异步与同步两组接口都有。

### 流程示例：异步存取一份存档

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

### 边界

- 只接受 JSON 可序列化的数据：函数、`undefined`、循环引用存不进去。
- 异步接口要求当前上下文支持存储，不支持时调用直接抛错；同步版读不存在的 key 返回 `undefined`，不是抛错。
- 官方未公布单个 key 的大小上限与总量上限（见第 5 节）。

## 4. OPFS 文件存储

`navigator.storage` 提供当前 Agent 私有的文件系统（OPFS），与另两套相互独立。宿主未提供 OPFS 后端时，调用以 `NotSupportedError` 失败，使用前必须做存在性守卫。

### 流程示例：先查配额，再写一个大文件并读回

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

### 边界

- `estimate()` 返回当前用量与配额，但配额的具体数值官方没有公布，是宿主运行时给出的值，不同设备与版本可能不同。
- 当前是实用子集，不是完整的浏览器 File System Access API；`StorageManager` 与句柄都不能用构造函数直接创建。
- 写入先进缓冲区，`close()` 才提交；中途异常要自己处理残局（删掉半成品文件）。

## 5. 已知边界汇总

- **容量数字全部未公布**：三套存储都没有官方公布的单项上限或总量上限。微信小程序的「单 key 1 MB、总量 10 MB」与浏览器的 localStorage 常见数值都不适用于本平台，不得代用。
- **没有过期机制**：官方没有记载任何 TTL、过期时间或自动清理规则。存下去就一直在，直到自己删除或用户清除应用数据。反过来，官方也没有承诺存储永不回收——OPFS 专门有 `persisted()` 查询与 `persist()` 申请两个方法，说明持久化是一个需要申请的状态。
- **全部本地、无同步**：三套存储都不联网、不与手机 App 同步；换设备等于新存档。
- **隔离是双向的**：Agent 读不到其他 Agent 的存储，也读不到宿主应用的数据。
- **实测补数在路上**：真实容量与 OPFS 配额由存储探针（`base/storage-probe`）在真机上量取，结果回填能力原子注册表（`docs/CAPABILITIES.md`）的 C6001 至 C6003 条目；本文数字口径以注册表为准。

## 6. 选型速记

- 设置、开关、上次读到哪：wx 存储或 localStorage，怎么顺手怎么来。
- 结构化存档（进度、收集、历史）：wx 存储，存档对象从第一天就带 `v` 版本号。
- 图片、音频、自生成的大块二进制：OPFS，写前先 `estimate()`。
- 要跨会话接着上次的档做事：以上都行，机制上没有有效期这一关；要防的是存档结构升级——留版本号、写迁移，别让旧档把新版读崩（错误码 E5004）。

## 7. 变更日志

### v1.0.0 2026-10-30

初版。三套存储的总览、流程示例与已知边界，依据官方存储指南与 OPFS 专页写成；容量与配额的实测回填口径见第 5 节。
