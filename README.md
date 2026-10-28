# 看向代说

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-say-by-looking
```

CC16 · 路缘坡（CC）。失语者看向场景、从4句固定候选里点头选一句、由TTS替他说出来

## 预览截图

![preview-say-by-looking-index.png](../screenshots/say-by-looking/preview-say-by-looking-index.png)
![preview-say-by-looking-phrases.png](../screenshots/say-by-looking/preview-say-by-looking-phrases.png)
![preview-say-by-looking-record.png](../screenshots/say-by-looking/preview-say-by-looking-record.png)
![preview-say-by-looking-phrases-s2.png](../screenshots/say-by-looking/preview-say-by-looking-phrases-s2.png)
![preview-say-by-looking-record-s2.png](../screenshots/say-by-looking/preview-say-by-looking-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：路缘坡（CC）。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：失语者看向场景、从4句固定候选里点头选一句、由TTS替他说出来。

## 结构与功能

3 页：`pages/index/` 場面一览（6个场景）；`pages/phrases/` 选句代说（选中场景的4句固定候选、点头/主确认即TTS代说整句并记一条记录）；`pages/record/` 記録（最近6条＋总数）。

内容集计数：場面6个；候选句24句（6×4）；代说记录按实际条数计。跨会话持久化：存储键 `sayByLookingV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

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

- 候选句是内置定型句，不是现场生成的语言；不声称理解场景或识别眼前的物品。
- 代说只在本人点头/主确认后才出声；对方是否听清以实际为准。
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

Feature Description: Say by looking: for people who cannot speak in the moment. Pick a scene, choose one of four fixed phrases by nod, and the glasses speak it aloud for you, with persisted records.

Opening Message: 说不出来的时候，看向场景、选一句，眼镜替你说出来。

Preview Media:
- `preview-say-by-looking-index.png`
- `preview-say-by-looking-phrases.png`
- `preview-say-by-looking-record.png`
- `preview-say-by-looking-phrases-s2.png`
- `preview-say-by-looking-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；失语者看向场景、从4句固定候选里点头选一句、由TTS替他说出来
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
