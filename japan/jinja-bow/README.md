# Jinja Bow（神社参拜序列）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-jinja-bow
```

JP02 · 日本本地化系列。交互哲学：**身体即输入 Ritual Sequence**。参拜的难处是双手要空出来、眼睛要看着神前，没法盯屏幕点按钮。本 Agent 把整套序列装进眼镜：你只管低头——鞠躬的深度就是确认键。每一步只显示一行，做完一步才亮下一步；二拝需要真的鞠两次躬，拍手步需要你拍完手再点头确认（拍手声感应不了，如实说明）。它不辨识神社、不讲解神话（那是慧眼问答的事），只守着「顺序」这一件事。

## 预览截图

![预览-index](<../../screenshots/jinja-bow/preview-jinja-bow-index.png>)
![预览-s2](<../../screenshots/jinja-bow/preview-jinja-bow-s2.png>)
![预览-s3](<../../screenshots/jinja-bow/preview-jinja-bow-s3.png>)
![预览-s4](<../../screenshots/jinja-bow/preview-jinja-bow-s4.png>)

## 在地性

日本神社参拜有一套身体记住的顺序：一の鳥居前一揖、手水舎净手漱口、拝殿前摇铃、二拝二拍手一拝。顺序错了不失礼，但心里没底；拿着手机查顺序又破坏了参拜本身。

## 功能流程（闭环）

- 序列守候：6 步固定序列（鳥居一揖→手水→摇铃→二拝→二拍手→一拝），当前步满亮，其余半亮
- 身体确认：头部俯仰传感器测鞠躬（相对基线 >16° 再回正 = 一揖），或点头/单击确认，传感器缺失自动降级
- 诚实分工：拍手无法被传感器证实，该步只接受本人确认，界面明写「拍手は自己確認」

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 CONFIRM 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 鞠躬角是相对头部基线的俯仰变化，不是礼仪评分；阈值 16° 为待真机标定值，README 已注明
- AbsoluteOrientationSensor 不可用时全程降级为点头/单击确认，序列逻辑不变

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/jinja-bow
~/tools/bin/aix pack . -o ../dist/jinja-bow.aix
~/tools/bin/aix list ../dist/jinja-bow.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Jinja Bow（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Shinto shrine: walks the wearer through the visit sequence, confirming bows by head pitch. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Shrine visit sequence coach for Rokid glasses: torii bow, temizuya, bell, two bows, two claps, one bow. Your bow is the button - head-pitch sensing confirms each bow, nod or tap confirms the rest. One step on screen at a time, hands free, eyes on the shrine. Claps are self-confirmed and labelled as such.

### Opening Message

> ## Jinja Bow
> 
> Six steps, one at a time: bow at the torii, purify your hands, ring the bell, two bows, two claps, one bow. Bow to confirm - I count the dip of your head, not a button. Your hands stay free for the ritual itself.

### Preview Media

- `preview-jinja-bow-index.png` — 初始状态
- `preview-jinja-bow-s2.png` — 演示状态 2
- `preview-jinja-bow-s3.png` — 演示状态 3
- `preview-jinja-bow-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：身体即输入 Ritual Sequence；竖版绘卷：左侧竖线串起参拜步骤，逐格点亮

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
