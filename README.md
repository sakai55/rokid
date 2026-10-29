# Machi Game Set（待ち時間ゲーム集）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-machi-game-set
```

**AIX 直接下载**（最新版）：[machi-game-set.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/machi-game-set.aix)

JP21 · 日本在地 × 指向性 × 游戏。精品线合并重做：由 JP15 `matsuri-taiko`（祭り太鼓リズム）与 JP17 `kotowaza-quiz`（ことわざクイズ）合并为一个等候时间头部游戏集；原两个 Agent 原样封存、不删不改。一句话场景：祭りや駅で順番を待つ家族が、頭の動きだけで遊べる二つのゲームで待ち時間を過ごし、ベスト記録を端末に残す。

## 预览截图

![预览-index](<../screenshots/machi-game-set/preview-machi-game-set-index.png>)
![预览-taiko](<../screenshots/machi-game-set/preview-machi-game-set-taiko.png>)
![预览-quiz](<../screenshots/machi-game-set/preview-machi-game-set-quiz.png>)
![预览-quiz-s2](<../screenshots/machi-game-set/preview-machi-game-set-quiz-s2.png>)

## 结构与功能（闭环）

三页结构（游戏卡带式菜单 / 太鼓圆阵 / 问答双卡）：

- **メニュー（pages/index）**：双模式大磁贴，显示持久化的ベストスコア、ことわざ到達級、プレイ回数（wx storage `machiGameSetV1`）。
- **太鼓（pages/taiko）**：内容集 3 曲（祭り囃子 8 拍 72 BPM／盆踊り 10 拍 60 BPM／山車リズム 12 拍 84 BPM）。开始时以正面校准中心，AbsoluteOrientationSensor 的 yaw/pitch 实读判定「うなずく（ドン）／左を向く／右を向く（カッ）」，逐拍 HIT/MISS、コンボ与スコア结算，结束写回ベスト。动作只允许分段（向く→正面に戻る），绝不转圈；`onHeadGesture('nod')` 亦可触发ドン。
- **ことわざ（pages/quiz）**：内容集 12 问、3 级（每 4 问升一级）。头部左右转（yaw 相对中心 ±0.40 rad）选 A/B，即时正误 + TTS 讲解，正解 100 点，结束结算并持久化ベスト与到達級。

方向分工：游戏承担开始/输赢/计分的完整玩法闭环；指向性承担头部朝向判定（两个模式的唯一主要输入）；日本在地承担祭り与ことわざ的内容本体。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 太鼓开始／ドン（游戏进行中） |
| 左滑/右滑对应键 | ArrowLeft / ArrowRight | 太鼓的左/右动作、问答的 A/B（与转头等价） |
| 点头 | `onHeadGesture('nod')` | 太鼓的ドン |
| 头部左右转 | AbsoluteOrientationSensor | 问答选 A/B、太鼓的左/右 |
| 双击 | Backspace | 系统返回（子页 BACK 键亦可） |

安全：头部动作慢而小幅，动作间必回正；感到疼痛或眩晕立即停止。本 Agent 不主張任何医療効果。

## 权限

无。传感器与 wx storage 不需要权限声明；TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- 传感器不可用时明示「センサーなし（キーでも遊べます）」，以键操作代替，不伪装传感器读数（预览截图中太鼓页显示传感器使用中，是 Web 运行时提供了传感器桩）。
- 分数与进度只存本机 wx storage，不联网、不上排行榜。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | Machi Game Set（待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | Entertainment（待导入时确认） |
| Intent Description | 待ち時間に頭で遊ぶ太鼓とことわざのゲーム集 |
| Agent ID | 待导入后回填 |
| 状态 | 已打包、已推送；未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

A waiting-time head-game set: a taiko rhythm game (3 songs, nod/left/right actions read from the head-orientation sensor, segmented motion with return-to-centre, combo scoring) and a 12-question kotowaza proverb quiz in 3 stages answered by turning your head. Best scores and progress persist on device.

### Opening Message (≤500, Markdown)

**待ち時間ゲーム集へようこそ。** 太鼓とことわざ、遊びたい方を頭の動きで選んでください。記録は端末に残ります。

### Preview Media

图片 4 张（本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 三页新作（メニュー/太鼓/ことわざ）；JP15+JP17 合并重做，曲目 3 首、问答 12 问、分数与进度跨会话持久化。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o machi-game-set.aix`（仓库副本在 `aix/machi-game-set.aix`）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（端口 8902）
