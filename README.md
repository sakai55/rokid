# Nomikai Kanji（饮会干事账簿）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-nomikai-kanji
```

JP08 · 日本本地化系列。交互哲学：**干事账簿 Host Ledger**。本 Agent 就是干事的那本账：人数、品目合计、人均（自动按 100 円单位向上凑整，这是割り勘的在地规矩）、终电倒计时，全在一张传票上。它永远不录音、不转写、不总结你们聊了什么——会议转写是底座能力，也不是酒桌需要的东西；它只记钱、人头和时间这三样干事必须持有的数字，点头即结账确认。

## 预览截图

![预览-index](<../screenshots/nomikai-kanji/preview-nomikai-kanji-index.png>)
![预览-s2](<../screenshots/nomikai-kanji/preview-nomikai-kanji-s2.png>)
![预览-s3](<../screenshots/nomikai-kanji/preview-nomikai-kanji-s3.png>)
![预览-s4](<../screenshots/nomikai-kanji/preview-nomikai-kanji-s4.png>)

## 在地性

日本の飲み会里，幹事（组织者）是最操心的角色：数人头、控节奏、算割り勘（还要照顾到100円単位的凑整礼仪）、盯終電。干事自己往往喝不好——注意力全在账本上。

## 功能流程（闭环）

- 记账：+ITEM 逐品累加（演示单价 ¥1,200/品）、+PERSON 调人数，人均自动 100 円凑整
- 守时：TRAIN 轮换终电时刻预设，倒计时以分钟常驻传票底部大字
- 结账：点头 = 结算确认，播报人均金额；全程零录音零转写，关页即忘

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 +ITEM 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 单价与终电时刻为演示预设（单价 ¥1,200、终电三档），实际请按当店与当线修改登记（README 有方法）；合计是登记之和，不是收银小票
- 倒计时按分钟粒度走字，不联网校时；跨零点的终电以预设分钟数计

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/nomikai-kanji
~/tools/bin/aix pack . -o ../dist/nomikai-kanji.aix
~/tools/bin/aix list ../dist/nomikai-kanji.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Nomikai Kanji（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Japanese nomikai: the organizer ledger for headcount, bill split with 100-yen rounding, and last-train countdown. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> The nomikai organizer's ledger: headcount, running total, per-person share auto-rounded up to the nearest 100 yen the warikan way, and a big last-train countdown - all on one izakaya slip. It never records or transcribes the table talk; ledgers hold money, people and time, nothing else.

### Opening Message

> ## Nomikai Kanji
> 
> Being kanji means holding three numbers all night: people, money, last train. I hold them on one slip - total, per-person share rounded the warikan way, and the countdown in big type. You drink; the ledger stays sober.

### Preview Media

- `preview-nomikai-kanji-index.png` — 初始状态
- `preview-nomikai-kanji-s2.png` — 演示状态 2
- `preview-nomikai-kanji-s3.png` — 演示状态 3
- `preview-nomikai-kanji-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：干事账簿 Host Ledger；居酒屋传票：右对齐金额列 + 终电大字倒计时

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
