# 逐行读

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-line-by-line
```

**AIX 直接下载**（最新版）：[line-by-line.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/line-by-line.aix)

CC15 · 路缘坡（CC）。阅读障碍者读纸质文件时一次只看一行、点头进下一行、不串行

## 预览截图

![preview-line-by-line-index.png](../screenshots/line-by-line/preview-line-by-line-index.png)
![preview-line-by-line-lines.png](../screenshots/line-by-line/preview-line-by-line-lines.png)
![preview-line-by-line-record.png](../screenshots/line-by-line/preview-line-by-line-record.png)
![preview-line-by-line-lines-s2.png](../screenshots/line-by-line/preview-line-by-line-lines-s2.png)
![preview-line-by-line-record-s2.png](../screenshots/line-by-line/preview-line-by-line-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：路缘坡（CC）。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：阅读障碍者读纸质文件时一次只看一行、点头进下一行、不串行。

## 结构与功能

3 页：`pages/index/` 文章一览（3篇・行数8/10/9）；`pages/lines/` 逐行读（大字只呈现当前一行、进度点标记、点头/下一行推进、可回上一行、读完记一条记录）；`pages/record/` 記録（最近6条＋总数）。

内容集计数：内置样例文章3篇・共27行（8/10/9）；读完记录按实际条数计。跨会话持久化：存储键 `lineByLineV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 主确认（各页主按钮） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 切换选项 / 上下一项 |
| 点头（头稳时） | `onHeadGesture('nod')` | 等价于主确认 |
| 双击 | Backspace | 返回上一页（子页） |

## 权限

无。TTS 与传感器不需要清单权限，相机零调用。

## 诚实边界

- 本版只提供内置样例文章的逐行扶行。拍照后自动切分整页文字的功能不在本版声称内，不声称读过相机内容。
- 一行制：同一时刻视线内只呈现一行，整页文字不上屏。
- 生活辅助用途，不替代医疗诊断与治疗建议。

## 错误码

失败时眼镜屏显裸码、TTS 只读码、最近一次错误写入持久数据的 `lastError`（含码、本台 slug、版本与原文）。本台可能出现的码：

- `E5001` 记录保存失败（存储写入抛错）
- `E5002` 记录读取失败（读取/解析抛错）
- `E3005` 播报失败（TTS speak 抛错）
- `E8001` 页面切换失败（navigateTo/navigateBack 抛错）

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名 | 待回填 |
| Version | 1.0.0 |
| App Category | 待回填 |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未真机验证 |

## 提审资料 (Review Submission)

Feature Description: Line by line: reading support that shows exactly one large line at a time. Three built-in sample passages (8, 10 and 9 lines), nod to advance, back to re-read, persisted finish records.

Opening Message: 慢慢读，一次只读一行。点头就进下一行，读错了可以回上一行。

Preview Media:
- `preview-line-by-line-index.png`
- `preview-line-by-line-lines.png`
- `preview-line-by-line-record.png`
- `preview-line-by-line-lines-s2.png`
- `preview-line-by-line-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；阅读障碍者读纸质文件时一次只看一行、点头进下一行、不串行
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
