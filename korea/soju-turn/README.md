# Soju Turn（烧酒礼仪转头编排）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-soju-turn
```

KR03 · 韩国本地化系列。交互哲学：**尊重编排 Respect Choreography**。本 Agent 编排的正是身体：四段固定舞台（两手接杯→两手斟酒→侧头饮→空杯确认），其中「侧头」一段由头部偏航传感器判定——相对基线转过 35° 再回正才算完成，转头的方向与幅度就是交互本身。长辈不在席时（ELDER 切换）该段自动改为正对饮用，规矩随席面而变。它不录酒桌、不转写祝酒词（底座的事），只守年轻人身体的朝向。

## 预览截图

![预览-index](<../../screenshots/soju-turn/preview-soju-turn-index.png>)
![预览-s2](<../../screenshots/soju-turn/preview-soju-turn-s2.png>)
![预览-s3](<../../screenshots/soju-turn/preview-soju-turn-s3.png>)
![预览-s4](<../../screenshots/soju-turn/preview-soju-turn-s4.png>)

## 在地性

韩国회식（会餐）的烧酒礼仪是身体性的：给长辈倒酒要两手（두 손으로 따르기），自己喝时要侧过头去（고개를 돌려 마시기），空杯才会被续。规矩不在嘴上，在手和头的朝向上——新人最怕的就是身体跟不上规矩。

## 功能流程（闭环）

- 站位：舞台图常驻「你 ↔ 长辈」相对方位，长辈在席状态可切换
- 编排：四段顺序推进（接杯/斟酒/侧头/空杯），侧头一段以头部偏航 >35° 自动判定（传感器缺失降级为点按）
- 轮回：一段走完回到接杯，轮数计数；空杯状态由 GLASS 手动登记（满/空/待续）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 NEXT 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 偏航角为相对基线的头部转动，不是礼仪评分；阈值 35° 为待真机标定值
- 传感器不可用时侧头段降级为本人确认，界面明示；本 Agent 不做饮酒量健康建议，过量请自控

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/soju-turn
~/tools/bin/aix pack . -o ../dist/soju-turn.aix
~/tools/bin/aix list ../dist/soju-turn.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Soju Turn（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Korean hoesik dinner: choreographs soju etiquette stages, judging the head-turn by head yaw. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Hoesik soju choreography: receive with two hands, pour with two hands, turn your head away to drink when an elder is present, show the empty glass. The head-turn step is judged by your actual head yaw - your body's direction IS the input. Toggle the elder away and the turn step politely disappears.

### Opening Message

> ## Soju Turn
> 
> At a hoesik, respect is choreography: two hands to receive, two hands to pour, head turned to drink. I stage the four steps and judge the turn by your head itself. Toggle 'elder present' off, and the turn step steps aside.

### Preview Media

- `preview-soju-turn-index.png` — 初始状态
- `preview-soju-turn-s2.png` — 演示状态 2
- `preview-soju-turn-s3.png` — 演示状态 3
- `preview-soju-turn-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：尊重编排 Respect Choreography；舞台站位图：你与长辈的相对方位 + 中央转头弧线

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
