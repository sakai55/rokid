# 한옥 머무르기

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-hanok-stay
```

KR18 · 韩国在地 × 路缘坡 × 注意力。第一次住韩屋的游客按房间逐项确认设施与礼仪、不失礼

## 预览截图

![preview-hanok-stay-index.png](../screenshots/hanok-stay/preview-hanok-stay-index.png)
![preview-hanok-stay-check.png](../screenshots/hanok-stay/preview-hanok-stay-check.png)
![preview-hanok-stay-record.png](../screenshots/hanok-stay/preview-hanok-stay-record.png)
![preview-hanok-stay-check-s2.png](../screenshots/hanok-stay/preview-hanok-stay-check-s2.png)
![preview-hanok-stay-record-s2.png](../screenshots/hanok-stay/preview-hanok-stay-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：韩国在地 × 路缘坡 × 注意力。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：第一次住韩屋的游客按房间逐项确认设施与礼仪、不失礼。

## 结构与功能

3 页：`pages/index/` 방 일람（6处・各4点）；`pages/check/` 확인 체크（选中房间的4点逐项打勾、齐全时TTS播报并记完成记录）；`pages/record/` 기록（最近6条＋总数）。韩语文案机检：假名=0、CJK汉字=0。

内容集计数：방 6处；检查点24点（6×4）；完成记录按实际条数计。跨会话持久化：存储键 `hanokStayV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

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

- 시설과 예절은 수록된 정형 안내입니다. 실제 숙소의 안내가 기준이며, 다르면 현장 안내를 따릅니다.
- 체크는 본인의 확인만을 기록합니다.

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

Feature Description: Hanok stay: a first stay in a Korean traditional house, room by room. Six rooms, four facility and etiquette checks each, checked by nod and persisted.

Opening Message: 한옥에 처음 머무르시나요. 방마다 시설과 예절을 하나씩 확인해 보세요.

Preview Media:
- `preview-hanok-stay-index.png`
- `preview-hanok-stay-check.png`
- `preview-hanok-stay-record.png`
- `preview-hanok-stay-check-s2.png`
- `preview-hanok-stay-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；第一次住韩屋的游客按房间逐项确认设施与礼仪、不失礼
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
