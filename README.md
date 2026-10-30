# storage-probe — Rokid 眼镜本地存储探针（AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-storage-probe
```

**AIX 直接下载**（最新版）：[storage-probe.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/storage-probe.aix)

为回答「官方没公布的三套本地存储数字是多少」而建的探针：不预设结论，在真机上量三套存储的往返正确性、实际容量与 OPFS 配额——为「接着上一次的档继续做东西」这类跨会话场景提供实测依据。

## 预览截图

截图统一存放于仓库根目录 `screenshots/storage-probe/`。

![首页：跨会话标记行 + 三套存储可用性卡 + 五项菜单](../screenshots/storage-probe/preview-storage-probe-home.png)

![localStorage 站：Web 预览里跑完一轮（往返通过、16 MiB 爬坡未触顶——预览宿主的存储比眼镜宽松，数值只认真机）](../screenshots/storage-probe/preview-storage-probe-ls.png)

![wx 存储站：同步+异步往返与爬坡结果（同上：往返通过、爬坡未触顶，预览数值仅供参考）](../screenshots/storage-probe/preview-storage-probe-wx.png)

![OPFS 站：配额/已用/持久化读数与写入验证（预览里 estimate 读到 64.00 MiB、写入 16 MiB 校验通过——那是 Chromium 的配额，不是眼镜的）](../screenshots/storage-probe/preview-storage-probe-opfs.png)

![结果单：三套结果汇总 + lastError 行，数据读自本地、重启不丢](../screenshots/storage-probe/preview-storage-probe-results.png)

![说明与已知边界页](../screenshots/storage-probe/preview-storage-probe-about.png)

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 待回填（本地 package.json 1.0.0） |
| App Category | 待回填（建议 Work） |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| AIX Package Size | 23.79 KB（本地 pack；Studio 打包值待回填） |
| 状态 | 本地已打包 · 待 GO 在 Studio 导入并真机运行 |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 三套被测存储（官方口径）

| 存储 | 形态 | 官方给的边界 |
|---|---|---|
| localStorage | 字符串键值（能力注册表 C6001） | 键值都走字符串转换；直接存对象得到 `'[object Object]'`，须先 `JSON.stringify` |
| wx 存储 | JSON 键值，异步 + Sync 两组口（C6002） | 数据须 JSON 可序列化；`getStorageSync` 缺键返回 `undefined`；异步口在存储不可用的上下文直接抛错 |
| OPFS | `navigator.storage` 文件存储（C6003） | `estimate()` 给运行时配额（无公布数字）；`persist()` 申请持久化；无后端时 `NotSupportedError`；实用子集 |

三套互相独立、按 Agent 隔离、全在眼镜本地、没有云端；三套都没有公布配额数字，也都没有过期/TTL 机制的记载。

## 测试项

| 站 | 测什么 |
|---|---|
| localStorage 站 | 往返（写已知 JSON → 读回逐字比对）+ 容量爬坡：32 KiB 逐键写入 `sprobe.ls.<i>`，首个抛错即停、记已接受字节与错误原文；上限 16 MiB（达上限记「未触顶」）；读回首/末键验长；测后删光自有键 |
| wx 存储站 | 同步往返 + 异步往返 + 同口径爬坡（异步 `setStorage` 逐键，fail 回调记 `errMsg`）；`getStorage` 验末键；逐键 `removeStorage` 清理 |
| OPFS 站 | `estimate()` 的 usage/quota（头条数字）、`persisted()` 与 `persist()` 结果；`sprobe/ramp.bin` 按 1 MiB 连写至 16 MiB，`close()` 提交后 `getFile()` 核对大小；测后整目录删除 |
| 首页标记 | 每次启动先读后写 `sprobe.marker`（`firstTs/lastTs/launches`），首页显示「上次启动 <时间> · 第 N 次启动」——跨会话存活本身就是一项实证 |
| 结果单 | 读 `sprobe.last`（每站跑完写入）大字汇总三套结果 + `lastError` 行，拍照留档、重启不丢 |

纪律：全程只动 `sprobe.*` 自有键与 `sprobe/` 目录，**从不调用任何清空全部存储的接口**；爬坡每块让出一拍以便刷新进度与响应中止（运行中双击 = 中止并留在本页）；所有持久 JSON 带 `{v:1}` 版本字段。容量按载荷字符数计（`'x'` 为单字节字符）。

预期判读：三站的容量数就是「一个 Agent 的档能做多大」的实测上限；OPFS 的 quota 是宿主给的运行时值，各机/各版本可能不同；若某套在预览里能跑而真机报错码（如 OPFS 的 E5005），说明该宿主无此后端——这本身就是要回填能力注册表 C6001–C6003 的结论。

## 操作方式（镜腿手势映射）

| 手势 | 键事件 | 作用 |
|---|---|---|
| 滑动 | ArrowUp / ArrowDown | 首页菜单选择（站内无滚动页） |
| 单击 | Enter / GlobalHook | 进站 / 开始运行（400ms 内重复投递去重） |
| 双击 | Backspace | 站内运行中 = 中止并留在本页；其余时候交给系统：返回 |
| 点头 | onHeadGesture 'nod' | 不触发任何动作（探针只认镜腿键） |

## 权限与边界

- 权限：无。存储不在平台七个权限名内，不需要声明。
- 只测本机存储：不联网、不外发任何数据。
- Web 预览里三套存储是宿主（浏览器）的实现，流程与失败路径能跑通，但配额/容量数值是浏览器的——结论只认真机结果单。

## 错误码

本 Agent 可出现的全局错误码（裸码，定义见仓库根 `ERROR-CODES.md`；本工程 `err.js` 为唯一定义处）：

| 码 | 含义 | 出现处 |
|---|---|---|
| E5001 | 记录保存失败 | 任一写入抛错（非配额类） |
| E5002 | 记录读取失败 | 读取/JSON 解析抛错，或往返/校验内容不一致 |
| E5003 | 存储空间不足 | 写入被配额拒绝（含 OPFS 的 `QuotaExceededError`） |
| E5005 | 持久化不可用 | 存储接口不存在，或 OPFS 的 `NotSupportedError` |
| E9001 | 未分类错误 | 以上之外的兜底（原文截断附带） |

报告约定：全部失败经单一漏斗 `fail(code, raw)` 落 `sprobe.error`（含 slug + 版本 + 原文截断 200 字）；向登记处回报时只报裸码（如「OPFS 站 E5005」），原文在结果单与 `lastError` 里可查。

## 本地命令

```bash
~/tools/bin/aix pack . -o storage-probe.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 提审资料 (Review Submission)

本 Agent 是开发探针，不计划提审上架；以下按 SOP 留档。

### Feature Description

存储探针：真机实测 Rokid 眼镜 Agent 三套本地存储（localStorage / wx 存储 / OPFS）的往返正确性、实际容量与运行时配额，为跨会话存档类场景提供实测依据。

### Opening Message

单击进站开跑：往返校验 + 32 KiB 步进容量爬坡 + OPFS 配额读取，结果汇总在结果单，重启不丢。

### Preview Media

- 图片：`screenshots/storage-probe/` 下 6 张（首页 / 三站 / 结果单 / 说明）
- 视频：真机阶段补录（探针不提审，可略）

### Change Log

#### v1.0.0

- Features added：六页存储探针——首页可用性三卡与跨会话启动标记、localStorage / wx / OPFS 三站（往返校验 + 容量爬坡 + 配额与持久化读取 + 写入读回验证）、结果单（本地持久、重启不丢）、说明与已知边界页；全部失败接全局错误码 E5001/E5002/E5003/E5005/E9001
- Improvements：—
- Fixes：—
