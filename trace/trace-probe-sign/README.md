# Trace Probe Sign · 手语探针（JSL 识别试验）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-trace-probe-sign
```

**AIX 直接下载**（最新版）：[trace-probe-sign.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/trace-probe-sign.aix)

描红系列的识别可行性探针，**不占 TR 编号、不上根清单**，UI 全日语。测 LLM 靠一张定格照片认日本手语（JSL）指文字与数字到底准不准，结果决定 TR03 手语描红正式版的收录范围（门槛事先定死：认对进练习范围、认错只进不计分练习、看不清复测后不收、全集认对不足一半则正式版降级自评描红）。

**定位明示：这是学 / 练手语的练习用识别试验，不是手语翻译工具。** 实时翻译需要连续手部追踪，眼镜没有这个能力，本 Agent 不做、也不暗示能做。

## 内容集（22 项，可数）

指文字：あ・い・う・え・お（元音 5）、か・さ・た・な・は・ま・や・ら・わ（各行あ段 9）、に・て・ほ（混淆组补项 3：に 与 な・は 同手形异方向、て・ほ 同手形异掌心）；数字：1・2・3・4・5。靠动作才能区分的浊音・半浊音・促音・拗音・长音一律不收（静止写真无法判定，逐类理由见工程 `data.js` 头部）。

## 试验流程

1. **说明页**（日语）：定位声明、摆位要求（手举到眼前 30–40cm、素背景、匀光）、已测进度。
2. **测定页**：逐项显示佩戴者视角单手线条范本（模式图）+ 要点文字；对着摆好，**点头拍照**，LLM 从 22 项名单中认（固定输出：认成什么 / 像不像 / 哪根手指差在哪）；随后本人点「判定は正しい / 判定は違う」定真值，落盘 `trace.probe.sign.v1`。
3. **结果页**：逐项表（分页 11 项 / 页）+ 汇总（认对 / 认错 / 未确定数）；回传 = 口述汇总数。

## 范本诚实标注

范本是 Canvas 自绘的**佩戴者视角线条模式图**（看自己手背 / 手心的方向），手指配置以要点文字为准，模式图不冒充标准手形图谱。数字与部分指文字（あ/1、た/2、か/3、て/5）在静态手形上天然近似，本探针正是来量这批混淆的。判定只对单张定格照片，不是连续追踪。

## 方向性 / 交互

核心 = SCAN（拍照）+ HEAD（点头触发）。手势：点头 = 拍照判定 / 执行焦点；点按 = 确认（Enter）；上下滑 = 切焦点；双击 = 返回（Backspace）。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 定格拍照，照片转 data URL 后给 LLM 图片输入判定 |

## 错误码

本台遵循全局错误码表（仓库根 `ERROR-CODES.md`，裸码 `E####`）。出错时屏显裸码 + 一行说明，最近一次错误保存在 `lastError`（含码、slug、版本、原文截断）。回报问题时请带上眼镜上显示的码。
本台用到：E1001 相机打开失败、E1002 相机权限未给、E1003 拍照器不可用、E1007 相机设备不存在、E1009 拍照失败、E2002 画布创建失败、E2013 文本编码失败、E5001 记录保存失败、E5002 记录读取失败、E6001 大模型不可用、E6002 大模型请求失败、E6011 大模型输出不可用、E8001 页面切换失败、E9001 未分类错误。

## 真机信息

| 项 | 值 |
|---|---|
| Studio name | （待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | （待导入后回填） |
| Intent Description | JSL 指文字 22 项识别探针：摆好点头拍照判定，真值确认落盘 |
| Agent ID | （待导入后回填） |
| 状态 | 已打包，待 GO 导入真机摆一轮回数据 |

## 打包 / 预览命令

```bash
~/tools/bin/aix pack . -o trace-probe-sign.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 预览截图

（Web 预览渲染：无相机 / LLM 的页面会如实显示未撮影状态，真机行为以真机为准。）

![说明页](../../screenshots/trace-probe-sign/preview-trace-probe-sign-index.png)
![测定页](../../screenshots/trace-probe-sign/preview-trace-probe-sign-test.png)
![结果页](../../screenshots/trace-probe-sign/preview-trace-probe-sign-result.png)

## 提审资料 (Review Submission)

本探针为内部识别试验工具，**不提审**（不进商店）。以下资料仅备查：

- **Feature Description**：手話指文字の認識プローブ：日本手話の指文字と数字22項目を装着者視点の線画範本で提示し、うなずき撮影で LLM が判定、本人が真値を確定して記録する。翻訳ツールではない。
- **Opening Message**：範本どおりに形を作り、うなずいて撮影。判定の真値は自分で確定します。
- **Preview Media**：见「预览截图」（探针不提交商店，视频免）。
- **Change Log**（Build 1.0.0）：Features added — JSL 22 项轮测、定格拍照判定、真值确认与结果汇总；Improvements — 无；Fixes — 无。
