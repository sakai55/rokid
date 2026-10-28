# Konbini Basket（便利店篮子核对）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-konbini-basket
```

JP03 · 日本本地化系列。交互哲学：**小票账本 Receipt Ledger**。本 Agent 是一本会自己落账的小票：出门前登记要买的四样东西，进店后每拿到一样就核销一行，合计行永远告诉你还差几件。结账环节它不做翻译（那是底座翻译的事），只把四句最高频的柜台定型句做成大字句卡——你指着给店员看，或照着念。条码扫描是可选的核销加速：扫到与当前物品对得上才落账，对不上如实报，对不上账的账本不开绿灯。

## 预览截图

![预览-index](<../screenshots/konbini-basket/preview-konbini-basket-index.png>)
![预览-s2](<../screenshots/konbini-basket/preview-konbini-basket-s2.png>)
![预览-s3](<../screenshots/konbini-basket/preview-konbini-basket-s3.png>)
![预览-s4](<../screenshots/konbini-basket/preview-konbini-basket-s4.png>)

## 在地性

日本コンビニ的购物是高频小额：一手拿篮子一手拿手机，结账时还要应对一连串定型问句（割り箸は？袋は？温めますか？）。漏买一样东西要再跑一趟，听不懂问句要在柜台前卡住。

## 功能流程（闭环）

- 登记：固定四件清单（おにぎり/お茶/サラダ/プリン为演示集，README 写明可换成自家清单）逐件排列
- 核销：GOT 或 SCAN（wide 拍照→条码/LLM 读名，暂定匹配）落一行账，✓ 与金额同步累计
- 结账：四句定型句卡（割り箸/袋/温め/そのまま）大字轮换，柜台前点 PHRASE 即可

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 GOT 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 拍照核对路径（见功能流程；失败即 SKIP） |

## 诚实边界

- 清单为内置演示四件套，未做自由编辑（编辑走语音登记是后续课题）；合计是清单标价之和，不是收银台实付
- SCAN 读名来自拍照+LLM，属暂定：显示原文并等你确认才核销，失败即 SKIP，不假装扫到

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/konbini-basket
~/tools/bin/aix pack . -o ../dist/konbini-basket.aix
~/tools/bin/aix list ../dist/konbini-basket.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Konbini Basket（待导入后回填） |
| Version / Build | 1.0.3 / 待导入后回填 |
| App Category | Life |
| Intent Description | In a Japanese convenience store: checks off a 4-item basket list and shows counter phrase cards. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Konbini basket ledger: your 4-item list as a receipt that fills itself in. Each item you grab gets checked off with its price; the total line always shows what is still missing. At the counter, four big phrase cards (chopsticks / bag / warm it up / as-is) replace live translation. Optional barcode scan is tentative until you confirm.

### Opening Message

> ## Konbini Basket
> 
> Four items, one receipt. Grab an item, tap GOT, and watch the line fill in - the total always tells you what is left. At the register, tap PHRASE for the big cards: chopsticks, a bag, warm it up, or just as it is.

### Preview Media

- `preview-konbini-basket-index.png` — 初始状态
- `preview-konbini-basket-s2.png` — 演示状态 2
- `preview-konbini-basket-s3.png` — 演示状态 3
- `preview-konbini-basket-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：小票账本 Receipt Ledger；小票竖账：虚线框内等宽流水，合计行收口

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

### Change Log（Build 1.0.3）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- FileReader 削除（Ink ランタイムに存在せず、実機で必ず失敗する）：写真 Blob→dataURL を公式ドキュメントの経路 `blob.arrayBuffer()` + 分割 `btoa` に変更し、失敗時は全艦隊エラーコード E2005 を表示する。
