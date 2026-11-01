# 元宵灯谜

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-dengmi-game
```

**AIX 直接下载**（最新版）：[dengmi-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/dengmi-game.aix)

GA52 · 中国在地 × 游戏 × 指向性。元宵节家庭聚会，家人只用头部方向选灯谜答案。

## 预览截图

![preview-dengmi-game-index.png](../screenshots/dengmi-game/preview-dengmi-game-index.png)
![preview-dengmi-game-play.png](../screenshots/dengmi-game/preview-dengmi-game-play.png)
![preview-dengmi-game-record.png](../screenshots/dengmi-game/preview-dengmi-game-record.png)
![preview-dengmi-game-play-s2.png](../screenshots/dengmi-game/preview-dengmi-game-play-s2.png)

## 方向构成

- 本台的方向构成：中国在地 × 游戏 × 指向性。各方向在场景里承担不可替代的一环，不是功能拼盘。
- 一句话场景：元宵节家庭聚会，家人围坐猜灯谜，只用头动选答案。
- 眼镜独占能力：视线与头部方向协调。4 个选项靠分段头动选择：从正中向左/右转一次只换一个选项，转回正中后才能再换一步；点头确认答案。抽掉头动，选答案的闭环就断。手机做不到同样自然：聚会时手里端着汤圆、抱着孩子，掏手机选答案会打断围坐猜谜的气氛。

## 结构与功能

3 页：`pages/index/` 12 条灯谜题目一览（只写题目线索，不泄露答案）、`pages/play/` 猜谜页（谜面＋4 选项，头动选、点头确认，正误即时播报并给解析一句）、`pages/record/` 记录页（最近 6 局结算）。

闭环：开始→出谜→头向选答案→正误计分→12 谜结算→记录，可反复玩。

内容集：自撰原创灯谜 12 条，每条含谜面＋4 选项＋答案解析一句（谜面均为本台新写，未抄现成谜语集原文；答案位置分散在 4 个选项位）。跨会话持久化：存储键 `dengmiGameV1`（每局结算记录数组 `records`、lastError）。

## 手势对应表

| 手势（镜腿触控板） | 按键事件 | 本台作用 |
|---|---|---|
| 单击 | Enter | 主确认（开始 / 确认答案 / 回首页） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 换选项（头部方向的按键兜底） |
| 点头（头部静止时） | `onHeadGesture('nod')` | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## 权限

无。头部方向传感与 TTS 不需要清单权限，本台不调用相机、麦克风与定位。

## 诚实边界

- 计分只来自玩家自己的头动选择，本台不做任何自动判定。
- 头部传感器只起辅助作用：缺失时用按键换选项，游戏仍可玩。
- 灯谜为本台自撰的游戏内容，不是传统谜语集的收录。

## 错误码

失败时眼镜屏显裸码、TTS 只读码、最新错误写入存储数据的 `lastError`（含码、本台 slug、版本、原文）。本台可能出现的码：

- `E5001` 记录保存失败（存储写入异常）
- `E5002` 记录读取失败（存储读取/解析异常）
- `E3005` 语音播报失败（TTS speak 异常）
- `E8001` 页面切换失败（navigateTo / navigateBack 异常）
- `E7001` 头部传感器不可用（AbsoluteOrientationSensor 生成/启动失败，经 `typeof` 守卫）

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名 | 未填 |
| Version | 1.0.0 |
| App Category | 未填 |
| Intent Description | 未填 |
| Agent ID | 未填 |
| 状态 | 未经真机验证 |

## 提审资料 (Review Submission)

Feature Description: 元宵灯谜：元宵节家庭聚会用的猜谜游戏。12 条自撰灯谜，每条 4 个选项；家人只用头部方向选答案、点头确认，12 谜后结算计分并跨会话保存记录。手里端着汤圆也不用掏手机，围坐猜谜不中断。

Opening Message: 元宵节到啦，汤圆端好、眼镜戴好，咱们只用点头摇头猜 12 条灯谜，看谁猜对得多。

Preview Media:
- `preview-dengmi-game-index.png`
- `preview-dengmi-game-play.png`
- `preview-dengmi-game-record.png`

> 正式提审需 3–5 个媒体文件且至少含 1 个视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 初版。元宵节家庭聚会，家人只用头部方向猜 12 条自撰灯谜。
- Improvements: 无（初版）
- Fixes: 无（初版）
