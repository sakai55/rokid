# 第一句话

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-first-sentence
```

**AIX 直接下载**（最新版）：[first-sentence.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/first-sentence.aix)

CC17 · 路缘坡（CC）。口吃者开口前把第一句存好、开口时逐词定速显示在视线内

## 预览截图

![preview-first-sentence-index.png](../screenshots/first-sentence/preview-first-sentence-index.png)
![preview-first-sentence-words.png](../screenshots/first-sentence/preview-first-sentence-words.png)
![preview-first-sentence-record.png](../screenshots/first-sentence/preview-first-sentence-record.png)
![preview-first-sentence-words-s2.png](../screenshots/first-sentence/preview-first-sentence-words-s2.png)
![preview-first-sentence-record-s2.png](../screenshots/first-sentence/preview-first-sentence-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：路缘坡（CC）。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：口吃者开口前把第一句存好、开口时逐词定速显示在视线内。

## 结构与功能

3 页：`pages/index/` 場面一览（6个场景・首句词数5/5/5/4/5/4）；`pages/words/` 逐词显示（首句逐词大字呈现、点头进下一个词、可回上一个词、说完记一条记录）；`pages/record/` 記録（最近6条＋总数）。

内容集计数：場面6个；首句词数共28词（5/5/5/4/5/4）；说完记录按实际条数计。跨会话持久化：存储键 `firstSentenceV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

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

- 只管第一句，不管整篇演讲；节拍点是视觉的，不出声催促。
- 推进全靠本人点头/按键，不声称麦克风自动跟随进度。
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

Feature Description: First sentence: for people who block on the opening line. Store the first sentence per scene, show it word by word in sight, advance by nod, and record each completed opening.

Opening Message: 开口的第一句最难。先把它存好，开口时一个词一个词慢慢来。

Preview Media:
- `preview-first-sentence-index.png`
- `preview-first-sentence-words.png`
- `preview-first-sentence-record.png`
- `preview-first-sentence-words-s2.png`
- `preview-first-sentence-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；口吃者开口前把第一句存好、开口时逐词定速显示在视线内
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
