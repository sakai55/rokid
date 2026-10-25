# Kimjang Batch（泡菜季大批次计数）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-kimjang-batch
```

KR08 · 韩国本地化系列。交互哲学：**批次大数 Batch Counter**。本 Agent 为沾满料的手而设计：屏幕上只有一个 62px 的大数字——当前阶段的棵数。计数靠点头（+1）与语音口令（宿主识别听到「다음」即 +1，识别不可用自动降级并明示），手几乎不用碰任何东西；+10 应对整筐过数，下滑纠错 -1。三段流水线各自计数，段目标达成才放行下一段。它不辨识白菜品质、不提供配方（那是菜谱与慧眼的事），只在你双手最忙的时候，把「数到几了」这件事稳稳接住。

## 预览截图

![预览-index](<../screenshots/kimjang-batch/preview-kimjang-batch-index.png>)
![预览-s2](<../screenshots/kimjang-batch/preview-kimjang-batch-s2.png>)
![预览-s3](<../screenshots/kimjang-batch/preview-kimjang-batch-s3.png>)
![预览-s4](<../screenshots/kimjang-batch/preview-kimjang-batch-s4.png>)

## 在地性

김장（泡菜季腌制）是韩国冬初的家族级工程：几十上百棵白菜，절이기（盐渍）→헹구기（冲洗）→양념 바르기（抹料）三段流水线，手上沾满辣椒面，一数错，盐和料的配比全乱。

## 功能流程（闭环）

- 大数：一屏一个巨号计数，阶段带显示 절이기/헹구기/양념 当前段与段目标
- 免手：点头 +1、语音「다음」+1（ASR 守护式，失败即明示降级）、+10 整筐、下滑 -1 纠错
- 段进：STAGE 在段目标达成后放行下一段（未达成时拒绝并播报还差几棵）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 +1 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 麦克风/语音路径（强度分析或 ASR；不录存） |

## 诚实边界

- 语音计数依赖宿主 ASR（韩语口令 다음），环境嘈杂时可能漏计；计数以屏幕大数为准，漏计用 +10/下滑当场修正
- 棵数目标为演示 60 棵；盐料配比不在本 Agent 范围，请按自家配方

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/kimjang-batch
~/tools/bin/aix pack . -o ../dist/kimjang-batch.aix
~/tools/bin/aix list ../dist/kimjang-batch.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Kimjang Batch（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | During kimjang in Korea: counts cabbage batches per stage by nod and voice, hands-free. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Kimjang batch counter built for hands covered in chili flakes: one 62-pixel number per stage - salting, rinsing, seasoning. Nod to add one, say 'daeum' to add one (guarded speech recognition, honest fallback), +10 per basket, swipe down to correct. Stage goals gate the pipeline. It counts; recipes stay yours.

### Opening Message

> ## Kimjang Batch
> 
> Sixty cabbages, three stages, and hands you cannot touch anything with. So: one huge number, counted by nods and by voice. I keep the count steady through salting, rinsing and seasoning - you keep the family recipe.

### Preview Media

- `preview-kimjang-batch-index.png` — 初始状态
- `preview-kimjang-batch-s2.png` — 演示状态 2
- `preview-kimjang-batch-s3.png` — 演示状态 3
- `preview-kimjang-batch-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：批次大数 Batch Counter；巨号计数面：一屏一个大数字 + 阶段带

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
