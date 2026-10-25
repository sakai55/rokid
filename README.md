# Kaiten Tally（回转寿司盘数账）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-kaiten-tally
```

JP12 · 日本本地化系列。交互哲学：**传送带盘数 Conveyor Tally**。本 Agent 是传送带边的盘数账：白盘 110 日元、红盘 220 日元、黑盘 330 日元，吃一盘按颜色加一盘，合计实时就是结账目安。它不识寿司、不判断好不好吃，只数盘子；结账时 GO 一次锁定合计，再 GO 一次为下一桌清零。最后点单（ラストオーダー）时间必须问店员，界面明写不替你报。

## 预览截图

![预览-index](<../screenshots/kaiten-tally/preview-kaiten-tally-index.png>)
![预览-s2](<../screenshots/kaiten-tally/preview-kaiten-tally-s2.png>)
![预览-s3](<../screenshots/kaiten-tally/preview-kaiten-tally-s3.png>)
![预览-s4](<../screenshots/kaiten-tally/preview-kaiten-tally-s4.png>)

## 在地性

回转寿司（回転寿司）的价格按盘子颜色定：不同颜色对应不同单价，吃完把盘子摞起来，店员数盘结账。最容易乱的是「到底吃了几盘、每种颜色几盘」，尤其一桌人一起吃、盘子混在一起时。

## 功能流程（闭环）

- 按色计数：白/红/黑三色盘各一键，吃一盘加一盘，合计与总盘数实时更新
- 传送带带：上方一条皿数带，皿数一目了然，空桌时明写「まだ皿はありません」
- 结账锁定：GO 锁定合计并 TTS 报数，再 GO 为下一桌清零，锁定期间加盘无效

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 WHITE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 盘价（白 110/红 220/黑 330）是本账本的目安价目，各店价目不同，以店内标价为准，界面明示
- 盘子由本人按颜色手动加，Agent 不用相机数盘，数错请在结账前复核
- ラストオーダー与店内规则以店员与店内告示为准，Agent 不做实时查询

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/kaiten-tally
~/tools/bin/aix pack . -o ../dist/kaiten-tally.aix
~/tools/bin/aix list ../dist/kaiten-tally.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Kaiten Tally（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a kaiten sushi counter: tallies plates by colour into a bill estimate and locks it at checkout. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Kaiten sushi plate tally: white plates 110 yen, red 220, black 330 - one key per colour, one tap per plate eaten, and the running total is the bill estimate. GO locks the bill and reads it aloud, then GO again clears the table for the next party. It never identifies sushi and never checks last-order times; ask the staff for those.

### Opening Message

> ## Kaiten Tally
> 
> At a kaiten sushi counter the bill is just plates by colour. I count them for you: white 110, red 220, black 330, one tap per plate, and the total on screen is always the bill so far. When you are done, GO locks the bill and reads it out. Last order times belong to the staff, not to me.

### Preview Media

- `preview-kaiten-tally-index.png` — 初始状态
- `preview-kaiten-tally-s2.png` — 演示状态 2
- `preview-kaiten-tally-s3.png` — 演示状态 3
- `preview-kaiten-tally-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：传送带盘数 Conveyor Tally；传送带横条：皿数带 + 大字合计 + 三色盘价行

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
