# Coin Laundry（コインランドリー見守り Laundry Watch）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-coin-laundry
```

JP18 · 日本在地 × 路缘坡 × 注意力（WATCH）。コインランドリーで終了音が聞こえにくい人が視覚カウントダウンで取り忘れを防ぐ。交互哲学：**コインランドリー見守り Laundry Watch**。

## 预览截图

![预览-index](<../../screenshots/coin-laundry/preview-coin-laundry-index.png>)
![预览-s2](<../../screenshots/coin-laundry/preview-coin-laundry-s2.png>)
![预览-s3](<../../screenshots/coin-laundry/preview-coin-laundry-s3.png>)
![预览-s4](<../../screenshots/coin-laundry/preview-coin-laundry-s4.png>)

## 方向构成

- 本 Agent 的方向构成：日本在地 × 路缘坡 × 注意力（WATCH）。每个方向在场景里承担不可替代的一环，非功能拼盘（日本组概念按精品线组合通则判定；自由组概念按场景核心定主方向编号）。
- 一句话场景：コインランドリーで終了音が聞こえにくい人が視覚カウントダウンで取り忘れを防ぐ。

## 功能流程（闭环）

- 进入：打开即显示当前项与进度，当前项大字在视线中央。
- 过程：NEXT 选下一项、TAKEN 确认当前项、PREV 回上一项；点头（头稳时）等价于主确认；SPEAK 随时播报当前状态。
- 结果：全部项确认后计一轮（周回/完成数 +1），可反复使用；DEMO 演示状态机，退出后真实状态原样恢复。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（确认当前项 / 播报） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 TAKEN 等价） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用 |

## 诚实边界

- 終了時刻は本人の登録と確認だけによる。店舗の機械と連動しない。
- 取り出し済みは本人の確認だけが記す。

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明不生效）。
- 绿色色阶：CSS 只用绿色色阶，禁用纯白与白色 rgba；按钮样式随本 Agent 的 UI 形态定型，不共用默认按钮。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid/japan/coin-laundry
~/tools/bin/aix pack . -o ../../aix/coin-laundry.aix
~/tools/bin/aix list ../../aix/coin-laundry.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Coin Laundry（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | Coin laundry: a visual watch for people who cannot hear the finish buzzer. Register each machine, watch its state in sight, and mark it taken only when the laundry is really out. It never hears anything for you. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Coin laundry: a visual watch for people who cannot hear the finish buzzer. Register each machine, watch its state in sight, and mark it taken only when the laundry is really out. It never hears anything for you.

### Opening Message

> ## Coin Laundry
>
> Coin laundry: a visual watch for people who cannot hear the finish buzzer. Register each machine, watch its state in sight, and mark it taken only when the laundry is really out. It never hears anything for you.

### Preview Media

- `preview-coin-laundry-index.png` — 初始状态
- `preview-coin-laundry-s2.png` — 演示状态 2
- `preview-coin-laundry-s3.png` — 演示状态 3
- `preview-coin-laundry-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：コインランドリー見守り Laundry Watch；コインランドリーで終了音が聞こえにくい人が視覚カウントダウンで取り忘れを防ぐ

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
