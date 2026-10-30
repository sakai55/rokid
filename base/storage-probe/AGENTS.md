# storage-probe

Rokid 眼镜本地存储探针（AIUI Agent）。为回答「官方没公布的三套本地存储数字是多少」而建：不做产品功能，只在真机上量往返、容量与配额。

## 身份

一个运行在 Rokid 眼镜上的存储链路探测工具。首页探三套存储的可用性并显示跨会话标记（上次启动时间、第几次启动）；三站各测一套存储，结果写进本地 `sprobe.last`，结果单页读出来大字展示，供拍照留档、重启不丢。

## 三套被测存储（官方口径，能力注册表 C6001–C6003）

- **localStorage**：字符串键值。键与值都走字符串转换；直接存对象得到 `'[object Object]'`，对象须先 `JSON.stringify`。
- **wx 存储**：`wx.setStorage/getStorage/removeStorage`（异步，success/fail 回调）+ Sync 版；数据经 JSON 序列化，不可序列化的数据存不了；`getStorageSync` 读不到键返回 `undefined`；异步口在当前上下文存储不可用时直接抛错。
- **OPFS**：`navigator.storage`。`estimate()` 返回 `{usage, quota}`——配额是运行时值，官方未公布任何数字；`persisted()` 查持久化状态、`persist()` 申请持久化；文件经 `getFileHandle` + `createWritable`（`close()` 才提交）写、`getFile()` 读回；宿主无 OPFS 后端时以 `NotSupportedError` 失败；只有实用子集，不是完整 File System Access API。
- 三套互相独立、按 Agent 隔离、全在眼镜本地，没有云端；官方也没给 Agent 云端存储。
- 三套都没有公布配额数字，也都没有过期/TTL 机制的记载。

## 测法

- **往返**：写已知载荷 → 读回 → 逐字/逐字段比对（LS 字符串比对；wx 同步、异步各一轮）。
- **容量爬坡（LS / wx）**：32 KiB 载荷（`'x'.repeat(32768)`）逐键写入 `sprobe.ls.<i>` / `sprobe.wx.<i>`，首个抛错即停，记已接受字节与错误名/原文；上限 16 MiB（512 键），达上限记「未触顶」。容量按载荷字符数计。爬坡后读回首/末键校验长度。
- **OPFS**：先读 `estimate()` 的 usage/quota（本站头条数字）与持久化状态并调用 `persist()`；再向 `sprobe/ramp.bin` 按 1 MiB 连写至 16 MiB，`close()` 后 `getFile()` 核对大小一致。
- **清理纪律**：测后只删自己的 `sprobe.*` 键与 `sprobe/` 目录；**全工程禁止 `localStorage.clear()` 与 `wx.clearStorage()`**——标记与结果键必须活过爬坡，这也是「接着上次的档做事」成立的实证。
- 爬坡每块之间让出（`await` 一拍），页面要能刷新进度、能响应中止；运行中双击（Backspace）置中止标志，`onKeyUp` 里 `preventDefault` 留在本页；跑完后的双击才交给系统返回。
- 所有持久 JSON 带版本字段 `{v:1, ...}`。

## 错误码（全局表裸码，err.js 唯一定义处）

- E5001 保存失败（写入抛错）· E5002 读取/解析失败（含往返/校验不一致）· E5003 存储空间不足（配额拒绝：错误名/原文含 quota，或 OPFS 的 QuotaExceededError）· E5005 持久化不可用（接口不存在，或 OPFS 的 NotSupportedError）· E9001 兜底（原文截断附带）。
- 全部失败经 `probe.js` 的 `fail(code, raw)` 单漏斗：落 `sprobe.error`（含 slug + 版本 + 原文截断 200 字），页面显示裸码行。

## 页面（6）

home（可用性三卡 + 跨会话标记行 + 五项菜单）/ ls / wx / opfs 三站 / results 结果单 / about 说明与已知边界。手势优先：滑动选、单击进/运行、双击返回；屏幕行保留 bindtap 供预览点击。无权限（存储不在七个权限名内）。

## 行为边界

- 只测本机存储，不联网、不外发任何数据。
- Web 预览里三套存储是宿主实现（浏览器 localStorage / OPFS 等），能跑通流程与失败路径，但数值只认真机：预览配额是浏览器的，不是眼镜的。
- 探针结论回填去向：能力注册表 C6001–C6003 的实测状态与 §4 开口探针行。
