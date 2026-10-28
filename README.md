# 定期まもり

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-teiki-mamori
```

JP28 · 日本在地 × 路缘坡 × 注意力。通勤者が改札前で定期券の期限と忘れ物を一度に確認する

## 预览截图

![preview-teiki-mamori-index.png](../screenshots/teiki-mamori/preview-teiki-mamori-index.png)
![preview-teiki-mamori-check.png](../screenshots/teiki-mamori/preview-teiki-mamori-check.png)
![preview-teiki-mamori-record.png](../screenshots/teiki-mamori/preview-teiki-mamori-record.png)
![preview-teiki-mamori-check-s2.png](../screenshots/teiki-mamori/preview-teiki-mamori-check-s2.png)
![preview-teiki-mamori-record-s2.png](../screenshots/teiki-mamori/preview-teiki-mamori-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：日本在地 × 路缘坡 × 注意力。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：通勤者が改札前で定期券の期限と忘れ物を一度に確認する。

## 结构与功能

3 页：`pages/index/` 定期一覧（定期3枚・期限表示、選んだ定期を保持）；`pages/check/` 忘れ物チェック（持ち物6点、点头/Enter逐项打勾、齐全时TTS播报并记一条完成记录）；`pages/record/` 記録（最近6条完成记录＋总数）。

内容集计数：定期券3枚；持ち物6点；完成记录按实际条数计。跨会话持久化：存储键 `teikiMamoriV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

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

- 期限は本人の登録した日付だけを表示する。鉄道・バス会社の実績データとは連動しない。
- 持ち物チェックは本人の確認だけを記す。忘れ物がないことの保証ではない。

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

Feature Description: Teiki mamori: a commuter companion before the ticket gate. Three registered passes with expiry dates, a six-item belongings check, and persisted departure records.

Opening Message: 改札の前に、定期券の期限と持ち物を確認しましょう。

Preview Media:
- `preview-teiki-mamori-index.png`
- `preview-teiki-mamori-check.png`
- `preview-teiki-mamori-record.png`
- `preview-teiki-mamori-check-s2.png`
- `preview-teiki-mamori-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；通勤者が改札前で定期券の期限と忘れ物を一度に確認する
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
