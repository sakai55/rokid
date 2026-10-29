# Trace Probe Seals · 结印探针（识别试验）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-trace-probe-seals
```

描红系列的识别可行性探针，**不占 TR 编号、不上根清单**：测 LLM 靠一张定格照片认十二基本印（子、丑、寅、卯、辰、巳、午、未、申、酉、戌、亥）到底准不准。结果决定 TR02 结印描红正式版的收录范围（事先定死的门槛：认对进计分档、认错只进不计分练习档、看不清复测后不收、全集认对不足一半则正式版降级为自评描红）。

## 玩法（试验流程）

1. **说明页**：摆位要求（双手举到眼前约 30–40cm、背景尽量素、光线均匀）、佩戴者视角声明、已测进度（可续测）。
2. **轮测页**：逐印显示连续 3 帧范本（①起手 ②交指中段 ③成印定格）——中央大图逐帧推进，下方缩略帧带。照每印要点文字摆到定格帧，**点头拍照**，LLM 从 12 印名单中认（固定输出：认成什么 / 像不像目标 / 哪根手指对不上；认不出、看不清如实说）。随后由佩戴者点「判定对 / 判定错」定真值，落盘。
3. **结果页**：逐项表（目标 / LLM 认成什么 / 对错）+ 汇总认对数；回传方式 = 把汇总数口述给维护者。

## 范本诚实标注

范本图是 Canvas 自绘的**佩戴者视角线条示意图**（你看自己手背的方向，与旁观者教材图左右相反），只表达成印过程与大致手形；**每印的手指配置以要点文字为准**，示意图不冒充精确手形图谱。判定只发生在定格帧的单张照片上——这是定格判定，不是连续追踪，本探针不暗示能实时纠正手势。

## 方向性 / 交互

核心 = SCAN（拍照）+ HEAD（点头触发拍照）。手势：点头 = 拍照判定 / 执行焦点；单指点按 = 确认（Enter）；上下滑 = 切焦点；双击 = 返回（Backspace）。屏幕按钮与手势一一对应，手势可独立跑完一轮。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 定格拍照，照片转 data URL 后给 LLM 图片输入判定 |

## 错误码

本台遵循全局错误码表（仓库根 `ERROR-CODES.md`，裸码 `E####`）。出错时屏显裸码 + 一行说明，最近一次错误保存在 `lastError`（含码、本台 slug、版本、原文截断）。回报问题时请带上眼镜上显示的码。
本台用到：E1001 相机打开失败、E1002 相机权限未给、E1003 拍照器不可用、E1007 相机设备不存在、E1009 拍照失败、E2002 画布创建失败、E2013 文本编码失败、E5001 记录保存失败、E5002 记录读取失败、E6001 大模型不可用、E6002 大模型请求失败、E6011 大模型输出不可用、E8001 页面切换失败、E9001 未分类错误。

## 真机信息

| 项 | 值 |
|---|---|
| Studio name | （待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | （待导入后回填） |
| Intent Description | 十二基本印识别探针：三帧范本摆印，点头拍照判定，真值确认落盘 |
| Agent ID | （待导入后回填） |
| 状态 | 已打包，待 GO 导入真机摆一轮回数据 |

## 打包 / 预览命令

```bash
~/tools/bin/aix pack . -o trace-probe-seals.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 预览截图

（截图为 Web 预览渲染：无相机 / LLM 的页面会如实显示失败或未拍状态，真机行为以真机为准。）

![说明页](../../screenshots/trace-probe-seals/preview-trace-probe-seals-index.png)
![轮测页](../../screenshots/trace-probe-seals/preview-trace-probe-seals-test.png)
![结果页](../../screenshots/trace-probe-seals/preview-trace-probe-seals-result.png)

## 提审资料 (Review Submission)

本探针为内部识别试验工具，**不提审**（不进商店）。以下资料仅备查：

- **Feature Description**：结印识别探针：十二基本印各以三帧佩戴者视角线条范本呈现，摆到定格后点头拍照，LLM 从名单中认印，佩戴者确认真值并落盘汇总。
- **Opening Message**：照范本摆印，点头拍照，看 LLM 认得准不准。
- **Preview Media**：见「预览截图」（探针不提交商店，视频免）。
- **Change Log**（Build 1.0.0）：Features added — 12 印三帧范本轮测、定格拍照判定、真值确认与结果汇总；Improvements — 无；Fixes — 无。
