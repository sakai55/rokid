# Jjimjil Rest（汗蒸冷热循环）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-jjimjil-rest
```

> **退役保留（2026-10-25，GO 裁定）**：汗蒸房的高温房里没人戴着智能眼镜，高温与蒸汽也会毁掉眼镜——本 Agent 的使用环境在生活常识中不成立。即日起退出日韩系列现役阵容，KR09 由 `pcbang-session`（网吧座席会话账）接替。工程与导入地址保留备查，不删除。

KR09 · 韩国本地化系列。交互哲学：**冷热循环 Thermal Cycle**。本 Agent 只管循环节奏：热段 12 分钟、休段 8 分钟，双环交替，当前环满亮，段终轻声播报一次并自动换段。它把「还要待多久」从意志力问题变成看一眼双环的问题。声明在先：它不做任何疗效承诺（排毒、治病一概不提），不测体温心率（平台没有这能力），只是一个懂汗蒸房规矩的计时环——热段超时未出，它会多提醒一次，仅此而已。

## 预览截图

![预览-index](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-index.png>)
![预览-s2](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-s2.png>)
![预览-s3](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-s3.png>)
![预览-s4](<../../screenshots/jjimjil-rest/preview-jjimjil-rest-s4.png>)

## 在地性

찜질방（汗蒸房）的玩法是循环：高温房里出一身汗，出来在休息厅吃식이（米露）与烤鸡蛋，缓过来再进去。节奏对了是享受，节奏乱了——在热房里待过头——就成了遭罪。

## 功能流程（闭环）

- 双环：热环（12:00）/休环（08:00）交替，当前环大字倒数，非当前环显示全长
- 切换：段终自动换段 + TTS 一句；SWITCH 可手动跳段，+2MIN 给当前段加时（加时会被如实标注）
- 收口：一轮（热+休）计 1 循环，循环数常驻；全程零健康断言，界面明写「节奏だけ」

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 START 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 时长为汗蒸房常见节奏目安，个人耐受不同请随时出房；本 Agent 不提供任何医疗或疗效判断
- 计时在页面隐藏时暂停（Ink 生命周期），回页续计，README 明示

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/jjimjil-rest
~/tools/bin/aix pack . -o ../dist/jjimjil-rest.aix
~/tools/bin/aix list ../dist/jjimjil-rest.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Jjimjil Rest（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | Life |
| Intent Description | In a Korean jjimjilbang: alternates hot-room and rest timers in a two-ring cycle display. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Jjimjilbang thermal cycle rings: 12 minutes hot, 8 minutes rest, two rings alternating with one spoken word at each switch. It keeps the rhythm of the bathhouse and makes zero health claims - no temperatures, no detox talk, just time, held in circles.

### Opening Message

> ## Jjimjil Rest
> 
> Hot room, rest hall, repeat - the jjimjilbang runs on cycles, and willpower is a bad timer. Two rings hold the rhythm for you: twelve in the heat, eight in the cool, one quiet word when it is time to move.

### Preview Media

- `preview-jjimjil-rest-index.png` — 初始状态
- `preview-jjimjil-rest-s2.png` — 演示状态 2
- `preview-jjimjil-rest-s3.png` — 演示状态 3
- `preview-jjimjil-rest-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：冷热循环 Thermal Cycle；双环：热环与休环交替点亮，环心是剩余时间

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
