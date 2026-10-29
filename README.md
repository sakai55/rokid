# 祭りゲーム集

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-matsuri-game-shuu
```

**AIX 直接下载**（最新版）：[matsuri-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/matsuri-game-shuu.aix)

JP32 · 日本在地 × 游戏 × 注意力 × 指向性。夏祭りの待ち時間、家族が眼鏡一本で20の屋台ゲームを回す

## 预览截图

![preview-matsuri-game-shuu-index.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-index.png)
![preview-matsuri-game-shuu-g01.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g01.png)
![preview-matsuri-game-shuu-g02.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g02.png)
![preview-matsuri-game-shuu-g03.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g03.png)
![preview-matsuri-game-shuu-g04.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g04.png)
![preview-matsuri-game-shuu-g05.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g05.png)
![preview-matsuri-game-shuu-g06.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g06.png)
![preview-matsuri-game-shuu-g07.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g07.png)
![preview-matsuri-game-shuu-g08.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g08.png)
![preview-matsuri-game-shuu-g09.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g09.png)
![preview-matsuri-game-shuu-g10.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g10.png)
![preview-matsuri-game-shuu-g11.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g11.png)
![preview-matsuri-game-shuu-g12.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g12.png)
![preview-matsuri-game-shuu-g13.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g13.png)
![preview-matsuri-game-shuu-g14.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g14.png)
![preview-matsuri-game-shuu-g15.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g15.png)
![preview-matsuri-game-shuu-g16.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g16.png)
![preview-matsuri-game-shuu-g17.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g17.png)
![preview-matsuri-game-shuu-g18.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g18.png)
![preview-matsuri-game-shuu-g19.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g19.png)
![preview-matsuri-game-shuu-g20.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g20.png)
![preview-matsuri-game-shuu-g01-s2.png](../screenshots/matsuri-game-shuu/preview-matsuri-game-shuu-g01-s2.png)

## 方向构成

- 本 Agent 的方向构成：日本在地 × 游戏 × 注意力 × 指向性。每个方向在场景里承担不可替代的一环，非功能拼盘。
- 一句话场景：夏祭りの待ち時間、家族が眼鏡一本で20の屋台ゲームを回す。

## 结构与功能

21 页：`pages/index/` 屋台一覧（20游戏名を5件ずつ窓表示・上下选・Enter开）；游戏页各一机制——计数8页（太鼓8回/金魚5匹/ヨーヨー6個/たこ焼き10個/うちわ20回/提灯12個/ボール7個/掛け声16回）、选择问答10页（各3問・3択・正誤TTS＋解説、完答记分记录）、方向选择2页（左右头向＋按键、AbsoluteOrientationSensor守卫、传感器缺失时按键可用）。每游戏页功能与内容集互异，状态变体不充页数。

内容集计数：屋台ゲーム20个；计数目标8/5/6/10/20/12/7/16；问答10页×3問；方向2页×3的；游戏记录按实际条数计。跨会话持久化：存储键 `matsuriGameShuuV1`（选中项、打勾/答题/计数状态、完成记录数组、`lastError`）。

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

- 各ゲームの採点は本人の操作・選択による。Agent は遊びの上手さを自動判定しない。
- 方向ゲームの頭センサーは、あるときだけ補助します。センサーがないときはキーで選べます。
- 景品・料金は収録済みの定型内容です。実際の屋台の案内が正です。

## 错误码

失败时眼镜屏显裸码、TTS 只读码、最近一次错误写入持久数据的 `lastError`（含码、本台 slug、版本与原文）。本台可能出现的码：

- `E5001` 记录保存失败（存储写入抛错）
- `E5002` 记录读取失败（读取/解析抛错）
- `E3005` 播报失败（TTS speak 抛错）
- `E8001` 页面切换失败（navigateTo/navigateBack 抛错）
- `E7001` 朝向传感器不可用（AbsoluteOrientationSensor 构造/启动失败）

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

Feature Description: Matsuri game shuu: a festival waiting-time collection. Twenty stall games in one agent - counting, quizzes and head-direction choices - each with its own set and persisted play records.

Opening Message: 夏祭りの待ち時間ですね。屋台ゲームを20個、眼鏡一本で回しましょう。

Preview Media:
- `preview-matsuri-game-shuu-index.png`
- `preview-matsuri-game-shuu-g01.png`
- `preview-matsuri-game-shuu-g02.png`
- `preview-matsuri-game-shuu-g03.png`
- `preview-matsuri-game-shuu-g04.png`
- `preview-matsuri-game-shuu-g05.png`
- `preview-matsuri-game-shuu-g06.png`
- `preview-matsuri-game-shuu-g07.png`
- `preview-matsuri-game-shuu-g08.png`
- `preview-matsuri-game-shuu-g09.png`
- `preview-matsuri-game-shuu-g10.png`
- `preview-matsuri-game-shuu-g11.png`
- `preview-matsuri-game-shuu-g12.png`
- `preview-matsuri-game-shuu-g13.png`
- `preview-matsuri-game-shuu-g14.png`
- `preview-matsuri-game-shuu-g15.png`
- `preview-matsuri-game-shuu-g16.png`
- `preview-matsuri-game-shuu-g17.png`
- `preview-matsuri-game-shuu-g18.png`
- `preview-matsuri-game-shuu-g19.png`
- `preview-matsuri-game-shuu-g20.png`
- `preview-matsuri-game-shuu-g01-s2.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机录制后补。

Change Log — Build 1.0.0:

- Features added: 首个版本；夏祭りの待ち時間、家族が眼鏡一本で20の屋台ゲームを回す
- Improvements: 无（首个版本）
- Fixes: 无（首个版本）
