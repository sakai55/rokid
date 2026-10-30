# qr-capacity-probe

Rokid 眼镜二维码容量探针（AIUI Agent）。为回答「本地数据交换收敛到二维码之后，一码到底能装多少文本」而建：不做产品功能，只在真机上量四档纠错（L/M/Q/H）下的编码上限、存图读回上限与相机读回上限。

## 身份

一个运行在 Rokid 眼镜上的二维码链路探测工具。交换模型：Agent A 把文本编码成二维码图、存成本地文件，BarcodeDetector 把图读回来——本探针把这条链的每一环单独量到顶。结果写进本地 `qrprobe.last`，结果单页大字展示，供拍照留档、重启不丢。

## 被测链路（官方口径）

- **编码**：平台没有二维码编码 API。工程内 vendored 纯 JS 编码器 `qrcode-generator` 1.4.4（Kazuhiko Arase，MIT）于 `lib/qrcode.js`，仅在文件尾追加两行：选定 UTF-8 的 stringToBytes（与上游 qrcode_UTF8.js 相同的覆盖；不覆盖时按单字节计字，中文会算错）与 ESM 默认导出。字节模式、版本自动至 40；`make()` 溢出抛错即编码上限信号。版本号由模块数推导：v =（模块数 − 17）/ 4。
- **存图**：编码结果画到离屏 `Canvas`（流探针 stream-probe 已证路径），`convertToBlob({type:'image/png'})`（Ink 0.19）转 Blob，写入本 Agent 私有 OPFS 目录 `qrprobe/`，文件名 `qr-<EC>-<字节数>.png`。绘制按 480×352 内最大整数模块倍率，记录每模块像素数。
- **检测**：`BarcodeDetector`（`getSupportedFormats()` 查支持码制，`new BarcodeDetector({formats:['qr_code']})`，`detect(imageSource)` 只吃 ImageData / Blob / ImageBitmap）。读回站直接对 OPFS 读回的 Blob 检测，`rawValue` 与载荷逐字比对。
- **相机**：`getUserMedia` 开流 → `ImageCapture.takePhoto`，先 `telephoto` 后 `default` 回退；照片 Blob 直接送 `detect`。
- **载荷**：确定性 ASCII 图案（`QRPROBE-…` 循环）按字节数生成，任何一站都能按尺寸重新生成并逐字比对；另有固定中文样本（24 字 = 72 UTF-8 字节）在 M 档单跑，验证字节计数。
- **OPFS 调用纪律**：`getDirectoryHandle` / `getFileHandle` 永远带第二个 options 参数（哪怕是空对象 `{}`）——Ink 桥对单参数调用直接抛错（原文 `Error calling function with 1 argument(s) while 2 where expected`，预览首现；storage-probe 一直带参所以没踩到）。
- **不碰媒体库**：系统媒体库的操作 API 官方未给文档（能力注册表 §5 第 12 条未明），本探针只用自有 OPFS，不猜接口。不联网。

## 测法

- **编码梯子**：尺寸 128 / 256 / 512 / 768 / 1024 / 1280 / 1536 / 1792 / 2048 / 2304 / 2560 / 2816 / 2953 字节逐档编码，首个溢出即停，该档上限 = 上一通过尺寸（记字节数与版本）。每通过一档即画布存图，并增量落盘结果。
- **文件读回**：按档从 OPFS 读回全部存图逐个 `detect`：PASS（内容一致）/ MISMATCH（解出但不符，记解出字节）/ NONE（未检出）/ NOFILE（无存图）/ ERR（detect 抛错 E7004）；上限 = 最大 PASS。`detect` 正常返回空数组是测量结果，不是错误，不走 fail 漏斗。
- **相机**：每次单击拍一张并解码，记内容字节数、是否与探针载荷一致、拍照模式；会话最佳与历史最佳（落盘）分开记。
- **展示页**：全屏展示所选档的最大读回 PASS 码（无读回记录时回退编码上限并在标注里写明），标注字节数 / 纠错档 / 版本 / 每模块像素，供 GO 用手机外部扫码核对。
- 运行中双击（Backspace）置中止标志，`onKeyUp` 里 `preventDefault` 留在本页；跑完后的双击才交给系统返回。所有持久 JSON 带版本字段 `{v:1, ...}`。

## 错误码（全局表裸码，err.js 唯一定义处）

- 相机：E1001 打开失败 · E1002 权限未给（NotAllowedError）· E1003 拍照器不可用（ImageCapture 不存在/构造失败）· E1007 设备不存在（NotFoundError）· E1008 相机不可读（NotReadableError）· E1009 拍照失败（两模式均抛错）· E1010 拍照模式不可用（两模式均失败且错误原文指向 mode）。
- 编码出图：E2002 画布创建失败（Canvas 不可得）· E2003 编码失败（画布）（convertToBlob 抛错/不可用）。
- 检测：E7004 detect 抛错 · E7005 码制不支持（getSupportedFormats 不含 qr_code）· E7009 检测器不可用（BarcodeDetector 不存在/构造失败）。
- 存储：E5001 保存失败 · E5002 读取失败 · E5003 存储空间不足（配额）· E5005 持久化不可用（OPFS 不存在/NotSupportedError）· E9001 兜底。
- 全部失败经 `qrprobe.js` 的 `fail(code, raw)` 单漏斗：落 `qrprobe.error`（含 slug + 版本 + 原文截断 200 字），页面显示裸码行。

## 页面（6）

home（用途 + 检测器可用性/码制 + 五项菜单）/ encode 编码站（选档跑梯子 + 中文样本 + 画布存图）/ decode 文件读回站 / camera 相机读码站 / display 展示页 / results 结果单。手势优先：滑动选档/选单、单击进站/开跑、双击返回；屏幕行保留 bindtap 供预览点击。权限只声明 CAMERA 一个（存储与检测不在七个权限名内）。

## 行为边界

- 只测本机链路，不联网、不外发任何数据；只动自有 OPFS 目录 `qrprobe/` 与 `qrprobe.*` 本地键。
- Web 预览里 BarcodeDetector / 相机 / OPFS 是宿主实现：Chromium 无 BarcodeDetector 时读回与相机两站停在守卫态（E7009），那是如实截图，不是缺陷；数值只认真机。
- 探针结论回填去向：能力注册表条码检测与相机相关条目、§4 开口探针行，以及 `docs/STORAGE.md` 第 8 节实测占位之外的二维码容量口径（本地交换方案设计依据）。
