# Coin Locker（车站储物柜寄存账）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-coin-locker
```

JP05 · 日本本地化系列。交互哲学：**寄存格账本 Locker Ledger**。本 Agent 只做一张寄存账：存入时登记柜号（滑动选号）、中身一件（ITEM 切换）、场所固定写明在状态里；保管中它只显示这三件事；取回时先亮出中身名让你核对，TAKE 才记取回完成。它不帮你找空柜（那要看车站的实时空位屏）、不导航回柜子（底座的事）、不替你保管密码——它只保证你寄存的那一格，被完整地记住并核对着取回。

## 预览截图

![预览-index](<../screenshots/coin-locker/preview-coin-locker-index.png>)
![预览-s2](<../screenshots/coin-locker/preview-coin-locker-s2.png>)
![预览-s3](<../screenshots/coin-locker/preview-coin-locker-s3.png>)
![预览-s4](<../screenshots/coin-locker/preview-coin-locker-s4.png>)

## 在地性

日本车站的コインロッカー是旅行与通勤的基础设施：大站按大中小分柜、Suica 或现金开锁、超时按日加算、三日无人取走移交遗失物。寄存时真正的风险从来不是柜子安不安全，而是人记不住——几号柜、在哪个口、哪一层、里面放了什么，回程时站在几百个柜门前发呆。

## 功能流程（闭环）

- 选格：滑动在演示柜号间切换，STORE 登记存入（柜号+中身锁定）
- 持有：保管中只显示柜号/中身/场所与加算目安，不催不扰
- 取回：TAKE 前先亮中身名核对，确认后记取回完了，格子清空

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 STORE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 柜号与场所是本人登记的备忘，不是与车站系统的实时联动；空位、费率、保管期限以车站告示为准
- 演示柜号与场所为新宿站西口的示例值，真机使用时按实际柜号登记

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/coin-locker
~/tools/bin/aix pack . -o ../dist/coin-locker.aix
~/tools/bin/aix list ../dist/coin-locker.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Coin Locker（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Japanese station: remembers coin-locker number and stored item until verified pickup. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Coin Locker: a station coin-locker ledger for Japan. Register the locker number and the one item you stored, and the agent holds exactly that - number, item, place - until pickup, when it shows the item name for you to verify before marking the locker emptied. No live locker availability, no navigation back, no PIN custody.

### Opening Message

> ## Coin Locker
> 
> Hundreds of identical doors, and yours is the one you forgot. Store with me: the locker number, what you put in, and where the bank of lockers is. At pickup I show you the item name first - check it, then take it.

### Preview Media

- `preview-coin-locker-index.png` — 初始状态
- `preview-coin-locker-s2.png` — 演示状态 2
- `preview-coin-locker-s3.png` — 演示状态 3
- `preview-coin-locker-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：寄存格账本 Locker Ledger；储物柜段格：柜门号阵列 + 大字柜号 + 中身/场所行

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）

### Change Log（Build 1.0.1）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- 语言纯化：界面与语音文案统一为本地语言（日本=日语 / 韩国=韩语），逐个排查清除了混入的日文、中文文案（含 SCAN 提示词）
