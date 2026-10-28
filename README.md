# Barcode Rally（多码清点）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-barcode-rally
```

AV07 · 储藏间/货架盘点双手忙，靠扫码把一架货点清并按目标清单核销，顶边界 B7（BarcodeDetector 码制与输入类型）。

## 预览截图

![预览-index](<../screenshots/barcode-rally/preview-barcode-rally-index.png>)
![预览-scan](<../screenshots/barcode-rally/preview-barcode-rally-scan.png>)
![预览-tally](<../screenshots/barcode-rally/preview-barcode-rally-tally.png>)
![预览-settle](<../screenshots/barcode-rally/preview-barcode-rally-settle.png>)

## 结构与功能（闭环）

四页，清点清单形态（目标行打勾列、大计数数字、清单行式长条按钮）：

- **码制门（pages/index）**：中枢菜单页。Enter 在「检测码制」行调用 `await BarcodeDetector.getSupportedFormats()`，实列宿主码制并计数上屏，不可用如实显示。目标清单内容集 10 件常驻显示：矿泉水 ean_13 / 快递单 code_128 / 会员卡 qr_code / 牛奶盒 ean_13 / 罐头食品 ean_8 / 洗手液 upc_a / 电池 code_39 / 打印纸 pdf417 / 标签贴 data_matrix / 挂面 codabar（名称+期望码制+示例值，码制均为 canonical 名）。
- **连续扫（pages/scan）**：`getUserMedia({video:true})` → `ImageCapture`；Enter 单次扫主路径 `grabFrame()` 得 ImageBitmap 直接喂 `new BarcodeDetector().detect(bitmap)`；grabFrame 失败回退 `takePhoto({mode:'wide'})` 的 Blob 喂 detect 并在界面标注回退。结果上屏 format/rawValue/boundingBox（x/y/w/h 数字）；同一 rawValue 3 秒内重复扫只提示不重复计（去重窗）；每码 TTS 朗读 rawValue 前 20 字；tracks 在 finally 中必停。扫到与目标「码制+值全合」提示命中、仅码制合提示「同码制异值」不自动核销。扫描记录存页间临时键 `av07_scans_tmp`。
- **核销（pages/tally）**：10 件目标行（✓ 已核销/○ 未，区分自动/手动）；最近扫描列表。自动核销口径 = format 与 value 都合；手动核销 = 选中目标行按 Enter，把最近一条扫描人工核销到该目标（人工纠错路径，见诚实边界）。语音纠错：宿主 `SpeechRecognition` 听写，说「删掉第X条」（阿拉伯/中文数字均认）按序号删最近列表对应条，或说条码尾号（≥4 位数字）删匹配的误扫；识别失败显示原文可重说。
- **结算（pages/settle）**：按码制计数表 + 核销进度 x/10 + 本轮扫描数；Enter 写入 `av07_tally`（跨会话累计已核销数与总扫描数、轮次，防重复入账）；可清空重盘（连本轮临时清单一并清）。

闭环：码制门 → 连续扫 → 核销（含语音/手动纠错）→ 结算入账，可反复盘下一架货。

## 语音交互流

- 语音播报节点：码制检测完成（播报支持种数）、每码扫到（TTS 朗读 rawValue 前 20 字）、重复码提示、手动核销确认、结算完成，均经 `_speak`（宿主 TTS、`immediate`）。
- 语音输入/纠错：核销页「语音删误扫」——说「删掉第X条」或条码尾号删误扫；听错/没听懂时界面显示听到的原文与失败原因，可重说，不静默乱删。
- 口令边界：没有「喊一声自动核销」的口令——核销只认扫码全合或本人手动确认，语音只用于删误扫纠错。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 码制门：检测/进入选中行；连续扫：扫一次；核销：手动核销选中目标；结算：入账 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 移动选中（菜单/目标行）或切换页面入口 |
| 点头（头稳时） | `onHeadGesture('nod')` | 与各页主确认等价（扫一次/手动核销/入账） |
| 双击 | Backspace | 系统返回（子页 BACK 钮亦可） |

## 权限

`CAMERA`：连续扫需要相机取帧/拍照喂检测。除此之外无定位；语音纠错走宿主识别。

## 诚实边界

- `detect()` 只喂 ImageBitmap（grabFrame）或 Blob（takePhoto wide 回退）——档案明确 detect 不收 VideoFrame/元素，代码从不那样传（placeholder 点名：扫页在无相机/无 ImageCapture/无 BarcodeDetector 的宿主上只显示不可用说明，不产生假码）。
- 目标清单的示例值是示例（如矿泉水例值 6901234500017），真机以实物条码为准；值不合但码制合只记「同码制异值」，绝不自动核销、不假装全对。
- 手动核销是人工纠错口径：由本人把最近扫描核销到选中目标，界面与记录都标注「手动」，与自动核销分开计数来源。
- 去重窗只有 3 秒且只按 rawValue；同值真有两件时，3 秒后重扫可再次计数，盘点时请留意状态行提示。
- boundingBox 数字为宿主返回值原样呈现，不做位置推断；pdf417 等码制的 rawValue 在实物上可能是二进制内容，示例值为文本示例。
- 页间临时键 `av07_formats_tmp` / `av07_scans_tmp` / `av07_manual_tmp` 只是传参；真正的持久化只有 `av07_tally`。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | 待回填 |
| Version / Build | 1.0.0 |
| App Category | Work（待导入时确认） |
| Intent Description | Stocktake by scanning: check host barcode formats, scan continuously, verify a ten-item target list with voice correction, and settle counts by format |
| Agent ID | 待回填 |
| 状态 | 未导入 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

Hands-busy stocktaking by barcode: list the formats the host really supports, scan continuously from camera frames with a 3-second dedup window and spoken values, verify a ten-item target list (auto only on full format+value match, manual verify labelled), fix bad scans by voice, and settle counts by format across sessions.

### Opening Message (≤500, Markdown)

**欢迎来到多码清点。** 先过码制门看宿主支持哪些码，再对着货架逐个扫——扫到会念给你听，核销进度随时可见，扫错了说一声就能删。

### Preview Media

图片 4 张（本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 四页新作（码制门/连续扫/核销/结算）；getSupportedFormats 实列、grabFrame 主路径扫码与 wide 回退、3 秒去重、10 件清单核销（自动/手动分开）、语音删误扫、按码制结算与跨会话累计。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o barcode-rally.aix`（仓库副本入 `aix/barcode-rally.aix`，由批次统一执行）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（自备 Ink 运行时 + 本地服务端口 8902，逐页截图入 `screenshots/barcode-rally/`）
