# Onsen Gate（温泉入浴门禁）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-onsen-gate
```

> **退役保留（2026-10-25，GO 裁定）**：温泉里没人戴眼镜入浴，浴场也不允许携入电子设备，高温蒸汽本身就会毁掉眼镜——本 Agent 的场景在生活常识中不成立。即日起退出日韩系列现役阵容，JP05 由 `coin-locker`（车站储物柜寄存账）接替。工程与导入地址保留备查，不删除。

JP05 · 日本本地化系列。交互哲学：**门禁阈限 Threshold Gates**。本 Agent 是入浴前的三道门：洗净身体、束发与毛巾出池、安静入池——上一道门没过，下一道门不开，界面就是三道门框本身。三道门全过，它才切换成入池计时（10 分钟目安，超时轻声收）。浴室场景它硬性不用相机：权限表里根本没有 CAMERA，代码里零相机调用，写进 README 作为设计承诺。它不辨识浴场、不翻译告示（底座的事），只守这三道门。

## 预览截图

![预览-index](<../../screenshots/onsen-gate/preview-onsen-gate-index.png>)
![预览-s2](<../../screenshots/onsen-gate/preview-onsen-gate-s2.png>)
![预览-s3](<../../screenshots/onsen-gate/preview-onsen-gate-s3.png>)
![预览-s4](<../../screenshots/onsen-gate/preview-onsen-gate-s4.png>)

## 在地性

日本の温泉・銭湯有一套不写在墙上也人人懂的规矩：湯船の前に体を洗う、タオルは湯船に入れない、髪は束ねる。对初次去的人（和带外国朋友去的人），最紧张的不是泡，是「进门到下水之间别出洋相」。

## 功能流程（闭环）

- 门禁：三道门自左向右，当前门满框，通过后门框点亮并「开启」
- 通过方式：PASS 键/单击/点头，本人确认即过（无传感器可证洗净与否，如实标注自己确认）
- 入池：三门全过自动进入 10:00 计时段，结束播报「上がりましょう」，BACK 可回上一门修正

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 PASS 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 所有门均为本人确认，Agent 无法也声称能验证你是否真的洗净——它守的是顺序与提醒，不是监督
- 计时为节奏目安，不是医疗建议；身体不适请立即出浴，本 Agent 不做健康判断

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/onsen-gate
~/tools/bin/aix pack . -o ../dist/onsen-gate.aix
~/tools/bin/aix list ../dist/onsen-gate.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Onsen Gate（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Japanese onsen or sento changing room: sequences the pre-bath etiquette gates, then times the soak. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Onsen entry gates: three thresholds before the bath - wash first, hair tied and towel out of the water, enter quietly. A gate opens only when you confirm the previous one; pass all three and it becomes a gentle 10-minute soak timer. No camera anywhere in this agent, by design - the permissions list is empty.

### Opening Message

> ## Onsen Gate
> 
> Three gates before the water: wash, tie your hair and keep the towel out, step in quietly. Pass them in order and I turn into your soak timer. I never use a camera here - this is a bathroom, and the gate is a promise, not a sensor.

### Preview Media

- `preview-onsen-gate-index.png` — 初始状态
- `preview-onsen-gate-s2.png` — 演示状态 2
- `preview-onsen-gate-s3.png` — 演示状态 3
- `preview-onsen-gate-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：门禁阈限 Threshold Gates；门形横列：三道无底边门框逐道开启，入池后变计时

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
