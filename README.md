# Gomi Sort（垃圾分流裁判）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-gomi-sort
```

**AIX 直接下载**（最新版）：[gomi-sort.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gomi-sort.aix)

JP06 · 日本本地化系列。交互哲学：**分流裁判 Branching Referee**。本 Agent 的权威从来不是 AI，而是你自家的规则卡：先选你家自治体的模型卡（演示含渋谷区/世田谷区两张模型卡与一张自宅卡），每件物品你先自己判断落点，它再对照规则卡判对错——判错当场说清正确类别与收集日，并记进错题数。拍照+LLM 只给「候補」（候选建议），永远不替你落判。它不做通用识物问答（底座慧眼的事），只做一件事：让你家的垃圾，在你家的规则下，分对。

## 预览截图

![预览-index](<../screenshots/gomi-sort/preview-gomi-sort-index.png>)
![预览-s2](<../screenshots/gomi-sort/preview-gomi-sort-s2.png>)
![预览-s3](<../screenshots/gomi-sort/preview-gomi-sort-s3.png>)
![预览-s4](<../screenshots/gomi-sort/preview-gomi-sort-s4.png>)

## 在地性

日本のごみ分別是全球最细的家庭制度之一：同一件东西在不同市区町村可能属于不同类别，ペットボトル要撕标签、スプレー缶要打孔、粗大ごみ要买券预约。分错了会被贴纸退回，整栋楼都看得见。

## 功能流程（闭环）

- 选卡：WARD 轮换规则卡（演示模型卡 ×2 + 自宅卡），类别与收集日随卡切换
- 落判：滑动选落点（燃やす/燃やさない/資源/粗大）→ JUDGE 对照规则卡，错则讲明正确枝与收集日
- 候选：SCAN 拍物得 LLM「候補」建议（暂定，界面明标），最终落判永远由你 + 规则卡决定

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 JUDGE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 拍照核对路径（见功能流程；失败即 SKIP） |

## 诚实边界

- 演示规则卡为模型化的常见分法，不代表任何自治体官方条文；正式使用请以自家自治体手册为准并据此改卡（方法写在 README）
- LLM 候选可能出错且类别随地区而变，因此它只有建议权没有判定权——这是本 Agent 的核心设计

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/gomi-sort
~/tools/bin/aix pack . -o ../dist/gomi-sort.aix
~/tools/bin/aix list ../dist/gomi-sort.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Gomi Sort（待导入后回填） |
| Version / Build | 1.0.3 / 待导入后回填 |
| App Category | Life |
| Intent Description | At home sorting trash in Japan: drills and checks items against the household ward rule card. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Home trash-sorting referee for Japan: pick your ward rule card first - the card, not the AI, is the law. You call each item, it judges against the card and names the right branch and collection day when you miss. A photo+LLM hint is labelled tentative and never decides. Built for the strictest recycling rules in daily life.

### Opening Message

> ## Gomi Sort
> 
> Your ward's rule card is the law here, not me. Pick your card, call each item yourself, and I will judge it against the card - wrong, and I name the right bin and its collection day. My photo guess is only a hint, always labelled as one.

### Preview Media

- `preview-gomi-sort-index.png` — 初始状态
- `preview-gomi-sort-s2.png` — 演示状态 2
- `preview-gomi-sort-s3.png` — 演示状态 3
- `preview-gomi-sort-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：分流裁判 Branching Referee；分流树：物品在树根，四条枝落入并排分类与收集日

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
