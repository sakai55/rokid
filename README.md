# qr-capacity-probe — Rokid 眼镜二维码容量探针（AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-qr-capacity-probe
```

**AIX 直接下载**（最新版）：[qr-capacity-probe.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/qr-capacity-probe.aix)

为回答「本地数据交换收敛到二维码之后，一码能装多少文本」而建的探针。被测的交换模型：Agent A 把文本编码成二维码图、存成本地文件，BarcodeDetector 把图读回来。本探针在四档纠错（L / M / Q / H）下逐环量这条链的边界——编码上限、存图后的文件读回上限、相机拍图的读回上限。不联网，不碰系统媒体库（其操作 API 官方未给文档，见能力注册表 §5 第 12 条未明）。

## 预览截图

截图统一存放于仓库根目录 `screenshots/qr-capacity-probe/`。

![首页：BarcodeDetector 可用性与码制清单（预览宿主的 Chromium 支持 10 种码制、含 qr_code）+ 五项菜单](../screenshots/qr-capacity-probe/preview-qr-capacity-probe-home.png)

![编码站：Web 预览实跑 M 档梯子——上限 2304 B · v40，2560 B 编码器溢出；中文样本 24 字 = 72 B · v5；页内缩略图为当前码。注记行「转图失败 E2003」是预览宿主拒绝离屏 Canvas 快照的如实记录，见「预览实测」节](../screenshots/qr-capacity-probe/preview-qr-capacity-probe-encode.png)

![文件读回站：预览里编码站没能存下图（E2003），本站如实报「无存图」；真机上存图成功后这里逐个 PASS / 不符 / 未检出](../screenshots/qr-capacity-probe/preview-qr-capacity-probe-decode.png)

![相机读码站：预览宿主无可用相机，停在 E1008 相机不可读——真机上单击即拍照（telephoto）并解码](../screenshots/qr-capacity-probe/preview-qr-capacity-probe-camera.png)

![展示页：M 档编码上限的 v40 码全屏展示（回退标注「未过文件读回」），供手机外部扫码核对](../screenshots/qr-capacity-probe/preview-qr-capacity-probe-display.png)

![结果单：四档上限、中文样本、相机与 lastError 汇总，数据读自本地、重启不丢](../screenshots/qr-capacity-probe/preview-qr-capacity-probe-results.png)

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 待回填（本地 package.json 1.0.0） |
| App Category | 待回填（建议 Work） |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| AIX Package Size | 35.85 KB（本地 pack；Studio 打包值待回填） |
| 状态 | 本地已打包 · 待 GO 在 Studio 导入并真机运行 |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 被测链路（官方口径）

| 环 | 实现 | 边界 |
|---|---|---|
| 编码 | vendored 纯 JS 编码器 `qrcode-generator` 1.4.4（Kazuhiko Arase，MIT）`lib/qrcode.js`，尾部仅追加两行：UTF-8 的 stringToBytes 选定（与上游 qrcode_UTF8.js 相同覆盖）+ ESM 导出 | 平台无编码 API；字节模式、版本自动至 40；`make()` 溢出抛错即上限信号；版本号 =（模块数 − 17）/ 4 |
| 存图 | 离屏 `Canvas` 绘制 → `convertToBlob({type:'image/png'})`（Ink 0.19）→ 本 Agent 私有 OPFS 目录 `qrprobe/`，文件 `qr-<EC>-<字节数>.png` | 绘制倍率为 480×352 内最大整数模块倍率并逐档记录；OPFS 句柄调用永远带 options 参数（Ink 桥拒绝单参数调用，预览首现） |
| 检测 | `BarcodeDetector`：`getSupportedFormats()` 查码制，`{formats:['qr_code']}` 构造，`detect(Blob)` | detect 只吃 ImageData / Blob / ImageBitmap；返回空数组是测量结果（未检出），不是错误 |
| 相机 | `getUserMedia` 开流 → `ImageCapture.takePhoto`，`telephoto` 失败回退 `default` | 需 CAMERA 权限；照片 Blob 直接送 detect |
| 载荷 | 确定性 ASCII 图案（`QRPROBE-…` 循环）按尺寸生成，各站按尺寸重生成逐字比对；中文样本「二维码是眼镜本地数据交换的信箱，存进去，读回来。」24 字 | 中文按 UTF-8 计 72 字节——字节模式数的是字节不是字数 |

## 测试项

| 站 | 测什么 |
|---|---|
| 编码站 | 选档跑梯子：128 / 256 / 512 / 768 / 1024 / 1280 / 1536 / 1792 / 2048 / 2304 / 2560 / 2816 / 2953 字节逐档编码，首个溢出即停，上限 = 上一通过尺寸（记字节数、版本、模块数、每模块像素）；每档通过即画布转图存 OPFS；M 档另跑中文样本验字节计数 |
| 文件读回站 | 按档从 OPFS 读回全部存图逐个 detect：PASS（与载荷逐字一致）/ MISMATCH（解出但不符）/ NONE（未检出）/ NOFILE（无存图）/ ERR（detect 抛错）；上限 = 最大 PASS |
| 相机读码站 | 单击拍一张（手机屏或纸上的码）并解码：记内容字节数、是否与探针载荷一致、头尾预览、拍照模式；会话最佳与历史最佳（落盘）分开记 |
| 展示页 | 全屏展示所选档最大读回 PASS 的码（无读回记录时回退编码上限，标注写明），标注字节数 / 纠错档 / 版本 / 每模块像素，供手机外部扫码核对 |
| 结果单 | 读 `qrprobe.last` 大字汇总：检测器状态、四档编码/读回上限、中文样本、相机最佳、lastError 行；拍照留档、重启不丢 |

纪律：只动自有 OPFS 目录 `qrprobe/` 与 `qrprobe.*` 本地键；梯子每档让出一拍以便刷新进度与响应中止（运行中双击 = 中止并留在本页）；所有持久 JSON 带 `{v:1}` 版本字段。

## 预览实测（Web 预览宿主，2026-10-31）

- **检测器**：预览的 Chromium 提供 BarcodeDetector，`getSupportedFormats()` 返回 10 种码制，含 `qr_code`——读回/相机两站的守卫在预览里是放行的。
- **编码梯子**：M 档在预览内实跑到底——上限 **2304 B · v40**，2560 B 编码器溢出；中文样本 **24 字 = 72 B · v5**，与 UTF-8 字节计数一致。其余三档为同一 vendored 编码器在本机的等价运行结果（编码是纯计算，与宿主无关）：**L 上限 2953 B · v40（梯子全过——即 QR 字节模式的规范上限）、Q 上限 1536 B · v39（1792 溢出）、H 上限 1024 B · v36（1280 溢出）**。真机编码站会逐档实测复核。
- **文件读回**：预览里未能跑通——离屏 Canvas 的 `convertToBlob` 被 Web 预览宿主拒绝（E2003），图存不下来，读回站如实报无存图。此环只认真机（Skia 画布快照路径）。
- **相机**：预览宿主无可用相机，停在 E1008 相机不可读。此环只认真机。

预期判读：编码上限是规范与编码器的天花板；文件读回上限回答「图存下来再读，还认得多少」；相机上限回答「拍下来还认得多少」——三者之差就是这条本地交换链在眼镜上的真实损耗，设计本地交换方案时以最小的那个为准。

## 操作方式（镜腿手势映射）

| 手势 | 键事件 | 作用 |
|---|---|---|
| 滑动 | ArrowUp / ArrowDown | 首页菜单选择；站内切换纠错档 |
| 单击 | Enter / GlobalHook | 进站 / 开始运行 / 拍照（400ms 内重复投递去重） |
| 双击 | Backspace | 站内运行中 = 中止并留在本页；其余时候交给系统：返回 |
| 点头 | onHeadGesture 'nod' | 不触发任何动作（探针只认镜腿键） |

## 权限与边界

- 权限：只声明 `CAMERA` 一个（相机站拍照用）。存储与 BarcodeDetector 不在平台七个权限名内，不需要声明。
- 只测本机链路：不联网、不外发任何数据；不使用系统媒体库（操作 API 未明，不猜接口）。
- Web 预览里检测器 / 相机 / OPFS 是宿主实现，流程能跑通的环已如实跑通（见「预览实测」），数值与失败形态只认真机结果单。

## 错误码

本 Agent 可出现的全局错误码（裸码，定义见仓库根 `ERROR-CODES.md`；本工程 `err.js` 为唯一定义处）：

| 码 | 含义 | 出现处 |
|---|---|---|
| E1001 | 相机打开失败 | getUserMedia 抛错/被拒（非权限类） |
| E1002 | 相机权限未给 | NotAllowedError |
| E1003 | 拍照器不可用 | ImageCapture 不存在 / 构造失败 |
| E1007 | 相机设备不存在 | NotFoundError |
| E1008 | 相机不可读 | NotReadableError |
| E1009 | 拍照失败 | takePhoto 两模式均抛错 |
| E1010 | 拍照模式不可用 | 两模式均失败且原文指向 mode |
| E2002 | 画布创建失败 | 离屏 Canvas 不可得 |
| E2003 | 编码失败（画布） | convertToBlob 抛错 / 不可用 |
| E5001 | 记录保存失败 | OPFS 写入或本地结果落盘抛错（非配额类） |
| E5002 | 记录读取失败 | OPFS 读图抛错（非未找到类） |
| E5003 | 存储空间不足 | 写入被配额拒绝 |
| E5005 | 持久化不可用 | OPFS 接口不存在 / NotSupportedError |
| E7004 | 条码检测失败 | BarcodeDetector.detect 抛错 |
| E7005 | 码制不支持 | getSupportedFormats 不含 qr_code |
| E7009 | 条码检测器不可用 | BarcodeDetector 不存在 / 构造失败 |
| E9001 | 未分类错误 | 以上之外的兜底（原文截断附带） |

报告约定：全部失败经单一漏斗 `fail(code, raw)` 落 `qrprobe.error`（含 slug + 版本 + 原文截断 200 字）；向登记处回报时只报裸码（如「编码站 E2003」），原文在结果单与 `lastError` 里可查。注：detect 正常返回空数组（未检出）与编码器溢出（上限信号）都是测量结果，不经漏斗、不算错误。

## 本地命令

```bash
~/tools/bin/aix pack . -o qr-capacity-probe.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 提审资料 (Review Submission)

本 Agent 是开发探针，不计划提审上架；以下按 SOP 留档。

### Feature Description

二维码容量探针：真机实测 Rokid 眼镜上二维码作本地数据交换的容量边界——四档纠错下的文本编码上限、存图文件读回上限与相机读回上限，为 Agent 间本地数据交换方案提供实测依据。

### Opening Message

选档跑梯子：编码到溢出为止、存图逐个读回比对、相机拍码解码，三段上限汇总在结果单，重启不丢。

### Preview Media

- 图片：`screenshots/qr-capacity-probe/` 下 6 张（首页 / 编码 / 读回 / 相机 / 展示 / 结果单）
- 视频：真机阶段补录（探针不提审，可略）

### Change Log

#### v1.0.0

- Features added：六页二维码容量探针——首页检测器可用性与码制清单、编码站（四档纠错编码梯子 + 中文 UTF-8 字节样本 + 画布转图存 OPFS）、文件读回站（逐图 detect 与载荷逐字比对）、相机读码站（telephoto 拍照解码、会话/历史最佳）、展示页（最大可读回码全屏展示供外部扫码核对）、结果单（本地持久、重启不丢）；全部失败接全局错误码（相机 E1001–E1010、出图 E2002/E2003、存储 E5001–E5005、检测 E7004/E7005/E7009、兜底 E9001）
- Improvements：—
- Fixes：—
