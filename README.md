# 駅弁えらび

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-ekiben-erabi
```

JP31 · 日本在地 × 注意力 × 游戏。駅で旅行者がアレルギーを確かめながら駅弁をクイズで選ぶ

## 预览截图

![preview-ekiben-erabi-index.png](../screenshots/ekiben-erabi/preview-ekiben-erabi-index.png)
![preview-ekiben-erabi-quiz.png](../screenshots/ekiben-erabi/preview-ekiben-erabi-quiz.png)
![preview-ekiben-erabi-record.png](../screenshots/ekiben-erabi/preview-ekiben-erabi-record.png)
![preview-ekiben-erabi-quiz-s2.png](../screenshots/ekiben-erabi/preview-ekiben-erabi-quiz-s2.png)
![preview-ekiben-erabi-record-s2.png](../screenshots/ekiben-erabi/preview-ekiben-erabi-record-s2.png)

## 方向构成

- 本 Agent 的方向构成：日本在地 × 注意力 × 游戏。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：駅で旅行者がアレルギーを確かめながら駅弁をクイズで選ぶ。

## 结构与功能

3 页：`pages/index/` 駅弁一覧（8種・各アレルギー表示）；`pages/quiz/` アレルギークイズ（8問・3択・正誤TTS＋解説、8問完答记一条得分记录）；`pages/record/` 記録（最近6条＋总数）。

内容集计数：駅弁8種；クイズ8問・各3択；得分记录按实际条数计。跨会话持久化：存储键 `ekibenErabiV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

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

- アレルギー表示は収録済みの定型表示です。実物の表示ラベルが正であり、表示と違う場合は現場の表示を優先してください。
- クイズの正誤は本人の選択で決まります。Agent はアレルギーの有無を判定しません。

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

Feature Description: Ekiben erabi: pick a station bento while checking allergens. Eight bentos with allergen labels, an eight-question allergen quiz, and persisted quiz records.

Opening Message: 駅弁を選びましょう。アレルギーを確かめてから、安心して選べます。

Preview Media:
- `preview-ekiben-erabi-index.png`
- `preview-ekiben-erabi-quiz.png`
- `preview-ekiben-erabi-record.png`
- `preview-ekiben-erabi-quiz-s2.png`
- `preview-ekiben-erabi-record-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；駅で旅行者がアレルギーを確かめながら駅弁をクイズで選ぶ
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
