# Omiyage Cover（土产义务覆盖）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-omiyage-cover
```

JP09 · 日本本地化系列。交互哲学：**人情覆盖 Obligation Grid**。本 Agent 把送礼名单变成覆盖格：格子不是物，是人。出发前登记六位受赠人（演示名单），在店里每买一份就核销一人，在库不够时先记「後で」（待补）也不许假装买过；只有 6 格全部落 ✓，它才说「全員分そろいました」。SCAN 扫到礼盒条码只加一份在库（暂定识别），核销永远由你确认。它不辨识礼品好不好（慧眼的事），只守「人人有份」这条人情底线。

## 预览截图

![预览-index](<../../screenshots/omiyage-cover/preview-omiyage-cover-index.png>)
![预览-s2](<../../screenshots/omiyage-cover/preview-omiyage-cover-s2.png>)
![预览-s3](<../../screenshots/omiyage-cover/preview-omiyage-cover-s3.png>)
![预览-s4](<../../screenshots/omiyage-cover/preview-omiyage-cover-s4.png>)

## 在地性

日本出差与旅行归来，お土産不是随手礼，是义务：上司、同组同事一个不能漏，漏掉谁比买错什么更失礼。买的时候在店里最慌的就是「我到底买了几份、还差谁」。

## 功能流程（闭环）

- 名单：6 位受赠人一人一格（演示名单），滑动选人
- 核销：BOUGHT 落 ✓ 并扣一份在库；在库为零时只能记 LATER（△ 待补），不许透支
- 在库：STOCK 手工 +1，或 SCAN 扫礼盒条码暂定 +1；6/6 ✓ 才报全覆盖

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 BOUGHT 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 拍照核对路径（见功能流程；失败即 SKIP） |

## 诚实边界

- 名单与礼品均为演示集；单价与预算未做（那是购物账，不是人情账）
- SCAN 对礼盒的识别是暂定的（wide 拍照+LLM 二值判断），误报时以 STOCK 手工修正为准

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/omiyage-cover
~/tools/bin/aix pack . -o ../dist/omiyage-cover.aix
~/tools/bin/aix list ../dist/omiyage-cover.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Omiyage Cover（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | Buying omiyage souvenirs in Japan: covers a 6-person recipient grid against gift-box stock. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Omiyage obligation cover: the gift list as a grid of people, not products. Six recipients, one cell each - bought, or honestly marked later when stock runs out; it will not let you pretend. Scan a gift box to add stock (tentative), confirm each person yourself. Done only when every cell is covered.

### Opening Message

> ## Omiyage Cover
> 
> Forgetting a person is worse than choosing the wrong gift. Six names, six cells. Buy a box, cover a name; out of stock, the cell says 'later' in the open - never a quiet fake check. All six covered, and only then: everyone is remembered.

### Preview Media

- `preview-omiyage-cover-index.png` — 初始状态
- `preview-omiyage-cover-s2.png` — 演示状态 2
- `preview-omiyage-cover-s3.png` — 演示状态 3
- `preview-omiyage-cover-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：人情覆盖 Obligation Grid；礼盒格阵（虚线框变体）：格子是人，全覆盖才收口

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）

### Change Log（Build 1.0.1）

**Features added**

- 无

**Improvements**

- 按钮按本 Agent 的 UI 形态单独定型（形态见设计契约），不再与全系列共用同一套按钮

**Fixes**

- 颜色对齐真机单色绿面板：原纯白 #ffffff 改为绿色色阶（最亮绿 #7dff9e），深浅只用绿色表现

### Change Log（Build 1.0.2）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- 语言纯化：界面与语音文案统一为本地语言（日本=日语 / 韩国=韩语），逐个排查清除了混入的日文、中文文案（含 SCAN 提示词）
