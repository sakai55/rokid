# Jongnyang Gauge（计量垃圾袋量表）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-jongnyang-gauge
```

KR04 · 韩国本地化系列。交互哲学：**计量表 Volume Gauge**。本 Agent 是一把量表：左边是当前袋子的填充刻度（逐升登记），右边是账本——食物垃圾投放次数与估算费用、已排出几袋。刻度到 80% 它提醒「곧 가득 차요」，满格只能 THROW（封袋排出）再开新袋，不许在界面里假装还能塞。它不识别垃圾种类（分类是各自治体手册与 JP06 式规则卡的事），只守体积与重量这两本经济账。袋子容量可扫包装上的印刷数字来设定（暂定识别）。

## 预览截图

![预览-index](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-index.png>)
![预览-s2](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-s2.png>)
![预览-s3](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-s3.png>)
![预览-s4](<../../screenshots/jongnyang-gauge/preview-jongnyang-gauge-s4.png>)

## 在地性

韩国的종량제（垃圾计量收费制）是把垃圾变成钱的制度：一般垃圾必须装进付费的标准化计量袋（종량제 봉투），食物垃圾（음식물쓰레기）按重量芯片计量另行收费。袋子买大了浪费、买小了装不下，食物垃圾的水分控不控直接决定重量与费用。

## 功能流程（闭环）

- 量袋：+1L 逐升登记填充，量表刻度同步上升；80% 播报预警
- 食物：FOOD 逐次登记食物垃圾投放（0.5kg/次目安），费用估算并行累计（估算明示）
- 排出：THROW 封袋计数 +1 并清零刻度；SCAN 扫袋包装容量数字可改袋型（10/20/50L）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 +1L 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 拍照核对路径（见功能流程；失败即 SKIP） |

## 诚实边界

- 填充量与食物重量均为人工登记的目安，不是称重；费用为单价目安估算，实际以各自治体单价为准
- 袋型单价各地不同，本 Agent 只记体积与次数，金额仅作量级参考

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/jongnyang-gauge
~/tools/bin/aix pack . -o ../dist/jongnyang-gauge.aix
~/tools/bin/aix list ../dist/jongnyang-gauge.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Jongnyang Gauge（待导入后回填） |
| Version / Build | 1.0.3 / 待导入后回填 |
| App Category | Life |
| Intent Description | At home in Korea: tracks standard trash-bag fill level and food-waste drop ledger. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Jongnyang pay-as-you-throw gauge: your standard bag as a rising volume scale, litre by litre, with an 80% warning and a throw-out that seals and counts the bag. A parallel ledger logs food-waste drops and a clearly-labelled fee estimate. It measures volume and habit - it never claims to weigh or to classify your trash.

### Opening Message

> ## Jongnyang Gauge
> 
> In Korea your trash is metered, so I am a meter. Log litres as the bag fills, watch the scale climb, seal it at full and start the next. Food waste drops get their own ledger line - estimate labelled as estimate.

### Preview Media

- `preview-jongnyang-gauge-index.png` — 初始状态
- `preview-jongnyang-gauge-s2.png` — 演示状态 2
- `preview-jongnyang-gauge-s3.png` — 演示状态 3
- `preview-jongnyang-gauge-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：计量表 Volume Gauge；竖直量表：左侧填充刻度逐格上升，右侧账本

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
- 量表刻度改用通用块字符（原字形在预览字体中缺字显示为方框）

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

- FileReader 제거(Ink 런타임에 존재하지 않아 실기기에서 반드시 실패함): 사진 Blob→dataURL 변환을 공식 문서 경로인 `blob.arrayBuffer()` + 분할 `btoa`로 바꾸고, 실패 시 전 함대 오류 코드 E2005를 표시한다.
