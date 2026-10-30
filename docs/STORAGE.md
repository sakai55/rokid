# Rokid Glasses 本地存储说明

中文 | [English](STORAGE.en.md) | [日本語](STORAGE.ja.md)

> 编制日期：2026-10-30；当前版本 v1.1.0，2026-10-31
> 资料原则：只采用 Rokid 官方来源（官方文档站、官方 GitHub 仓库 `yodaos-project/AIUI` 及其内置的 `aiui-dev` skill 参考）。官方没有公布的数字，本文一律写明「未公布」，不拿其他平台的数值代用。

## 写在前面

本文由一名 Rokid AIUI 开发者维护，不是 Rokid 官方文件。它把 Agent 能用的本地存储讲清楚：有哪几套、各适合存什么、流程怎么写、边界在哪。

先说总纲：Agent 能用的存放点有四处——三套私有存储（`localStorage`、wx 存储、OPFS 文件存储），加一个系统媒体库，也就是用户在相册里能看到的那一个。三套私有存储都在眼镜本地、按 Agent 隔离、互不相通；媒体库是全系统共享的空间，进出靠权限。平台没有给 Agent 提供任何云端存储：存档不会同步到手机或云端，用户清除应用数据或卸载后，本地存档随之消失；要跨设备或联机保存，只能自建后端。

## 1. 总览

为什么有三套？因为它们来自三条不同的血统，不是同一功能的三个副本：

- **localStorage 是 Web 血统**。运行时 Ink 是 Web 风格的容器（fetch、WebSocket、Streams 都是 Web 接口），localStorage 作为 Web 标准的键值存储随容器自带，官方在 Web API 参考里定义它：字符串键值、同步读写。
- **wx 存储是小程序血统**。平台收了一套微信小程序兼容接口，wx 存储是其中之一；官方的《存储》指南通篇只讲这一套，给它的定位是「本地数据缓存，适合保存用户偏好、页面状态和业务缓存等 JSON 可序列化数据」。就官方文档而言，这一套才是平台正典的存储功能。
- **OPFS 是文件血统**。键值存储装不下大块二进制，OPFS 补上文件这一层；官方 OPFS 专页给它的定位是「保存文件、二进制资源、离线缓存和体积超过简单键值数据的持久化内容」。

官方从未发文比较三套、也没有宣布谁取代谁；重叠只发生在小数据键值这一段（localStorage 与 wx 存储都能存），分工线在数据形态：键值归前两套，文件归 OPFS。

拿图片作例：图片是二进制，localStorage 与 wx 存储都不能直存——只能先转成 base64 字符串绕存（体积膨胀约三分之一，localStorage 还是同步写入、大字符串会卡页面），正道是 OPFS 直接写 Blob。把照片交到用户手里、存进系统媒体库是另一条路，走 `CREATE_MEDIA_IMAGES` 权限，见第 5 节。

| 系统 | 接口 | 适合存什么 | 数据形式 |
|---|---|---|---|
| localStorage | `localStorage.getItem / setItem / removeItem / clear` | 小的设置、标记、跨会话进度指针 | 只有字符串 |
| wx 存储 | `wx.setStorage / getStorage / removeStorage / clearStorage` 及同步版 | 用户偏好、页面状态、业务缓存、存档本体 | JSON 可序列化数据 |
| OPFS | `navigator.storage.getDirectory()` 起的文件 API | 大文件、二进制、超过键值体积的内容 | 文件 |
| 系统媒体库 | 权限门控的媒体操作（具体接口未公布，见第 5 节） | 要交到用户手里的图片与音频；跨 Agent 共享的账面通道 | 系统共享的相册，用户可见 |

前三套都不需要申请权限（不在七个权限名之列）；媒体库要声明媒体权限，见第 5 节。`clear` 类接口只清当前 Agent 自己的存储，清不到别人的。

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
- 官方未公布容量上限（见第 6 节）。写入被配额拒绝时抛错，对应错误码 E5003；接口不存在或被禁用对应 E5005。

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
- 官方未公布单个 key 的大小上限与总量上限（见第 6 节）。

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

## 5. 系统媒体库

前三套是各 Agent 的私有存储；系统媒体库（用户口中的相册）是第四处存放点，性质不同：它是全系统共享的媒体空间，用户能在眼镜与手机 App 里直接翻看。它不按 Agent 隔离，进出靠权限。

### 权限边界

- 读：`READ_MEDIA_IMAGES` 列出并读取媒体库中的图片；`READ_MEDIA_AUDIO` 管音频。
- 写：`CREATE_MEDIA_IMAGES`、`CREATE_MEDIA_AUDIO` 只能新增资源，官方原文写明不包含修改或覆盖已有资源。
- 没有删除与修改：七个权限名里没有删除、改名或编辑元数据的权限——Agent 删不掉、改不了相册里的任何东西，包括它自己存进去的；存错了只能请用户在手机 App 里处理。
- 声明不等于授权：权限写进 app.json 只是声明，调用时仍可能被系统拒绝，代码要处理拒绝分支；提审时每个权限都要写明用途。

### 现状：操作接口未明

本节不给流程示例——给不出。官方文档只在 app.json 权限表里定义了这四个权限，并注明媒体库的图片读取、保存操作会检查该权限，但列出、读取、保存分别调用什么 API，全套官方文档里没有写。这一条已经登记进能力原子注册表（`docs/CAPABILITIES.md`）第 5 节未明清单，挂在 C7004 至 C7007 名下。开发相册功能之前，先把操作接口探明，不要按其他平台的同类接口猜用。

### 边界

- 只有图片与音频两类资源，别的格式进不去。
- 写进去就等于交给用户：内容对用户与系统可见，不要把工作数据、缓存或隐私材料放进媒体库。
- 容量与回收规则官方未公布。

## 6. 已知边界汇总

- **容量数字全部未公布**：三套存储都没有官方公布的单项上限或总量上限。微信小程序的「单 key 1 MB、总量 10 MB」与浏览器的 localStorage 常见数值都不适用于本平台，不得代用。
- **没有过期机制**：官方没有记载任何 TTL、过期时间或自动清理规则。存下去就一直在，直到自己删除或用户清除应用数据。反过来，官方也没有承诺存储永不回收——OPFS 专门有 `persisted()` 查询与 `persist()` 申请两个方法，说明持久化是一个需要申请的状态。
- **全部本地、无同步**：三套存储都不联网、不与手机 App 同步；换设备等于新存档。
- **隔离是双向的**：Agent 读不到其他 Agent 的存储，也读不到宿主应用的数据。
- **媒体库的口径同样未明**：容量上限、回收规则、可见范围的细化口径，官方均未公布（见第 5 节）。
- **实测补数在路上**：真实容量与 OPFS 配额由存储探针（`base/storage-probe`）在真机上量取，结果先填本文第 8 节，再回填能力原子注册表（`docs/CAPABILITIES.md`）的 C6001 至 C6003 条目；本文数字口径以注册表为准。

## 7. 选型速记

- 设置、开关、上次读到哪：wx 存储或 localStorage，怎么顺手怎么来。
- 结构化存档（进度、收集、历史）：wx 存储，存档对象从第一天就带 `v` 版本号。
- 图片、音频、自生成的大块二进制：OPFS，写前先 `estimate()`。
- 要把图片、音频交到用户手里，或者借相册在 Agent 之间传数据：系统媒体库——但先探明操作接口（第 5 节），且写进去的东西用户看得见，别放工作数据。
- 要跨会话接着上次的档做事：以上都行，机制上没有有效期这一关；要防的是存档结构升级——留版本号、写迁移，别让旧档把新版读崩（错误码 E5004）。

## 8. 真机实测

本节留给真机数据，由测试者回填。测量工具是存储探针（`base/storage-probe`）：三套存储逐套做往返自检与容量爬坡，爬坡以 32 KiB 为一级逐级写入、第一处失败即停，接受量是失败前的累计字节；OPFS 站另读 `estimate()` 的配额与已用量、`persisted()` 与 `persist()` 的结果；跨会话留存靠探针首页的启动标记验证（第二次打开时显示的上次启动时间与累计启动次数）。填好后同步回填能力原子注册表 C6001 至 C6003。

- 测试日期：（待填）
- 眼镜型号与固件：（待填）
- Ink 运行时版本：（待填）

| 测量项 | 真机结果 | 备注 |
|---|---|---|
| localStorage 往返自检 | （待填） | |
| localStorage 容量爬坡接受量 | （待填） | 触顶错误名与原文：（待填） |
| wx 存储同步往返 | （待填） | |
| wx 存储异步爬坡接受量 | （待填） | fail 的 errMsg 原文：（待填） |
| OPFS estimate() 配额 quota | （待填） | 字节与 MiB 两个口径都记 |
| OPFS estimate() 已用 usage，测前 | （待填） | |
| OPFS persisted() 与 persist() 结果 | （待填） | |
| OPFS 写入读回校验，文件大小 | （待填） | |
| OPFS 爬坡接受量 | （待填） | |
| 跨会话留存，第二次启动显示 | （待填） | 上次启动时间与启动次数 |
| 媒体库操作 API 是否探明 | （待填） | 探明后回填第 5 节与注册表 |

## 9. 变更日志

### v1.1.0 2026-10-31

系统媒体库入册：新增第 5 节，把相册正式列为第四个存放点，写清权限边界（只读、只新增、不可改、不可删）与操作 API 未明的现状；新增第 8 节真机实测占位，测量项与存储探针一一对应，待真机回填；原第 5、6、7 节顺延为第 6、7、9 节，第 1 节总览表补媒体库一行。

### v1.0.0 2026-10-30

初版。三套存储的总览、流程示例与已知边界，依据官方存储指南与 OPFS 专页写成；容量与配额的实测回填口径见第 5 节。
