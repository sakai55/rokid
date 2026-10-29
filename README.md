# Bosai Kit（防灾包覆盖点检）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-bosai-kit
```

**AIX 直接下载**（最新版）：[bosai-kit.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/bosai-kit.aix)

JP04 · 日本本地化系列。交互哲学：**榻榻米覆盖格 Coverage Grid**。本 Agent 把防灾包变成一张覆盖格：8 个品类一人一格，查过打 ●，过期或需更换打 △，没查是 ○。只有 8 格全部离开 ○，它才说「点检完了」。期限靠 telephoto 拍包装日期 + LLM 读年月（暂定，显示原文等你确认），或由你直接 FLAG。它不辨识灾害、不播报情报、不导航去避难所——那些是底座与自治体的事；它只证明一件事：这个包，今天真的被完整查过一遍。

## 预览截图

![预览-index](<../screenshots/bosai-kit/preview-bosai-kit-index.png>)
![预览-s2](<../screenshots/bosai-kit/preview-bosai-kit-s2.png>)
![预览-s3](<../screenshots/bosai-kit/preview-bosai-kit-s3.png>)
![预览-s4](<../screenshots/bosai-kit/preview-bosai-kit-s4.png>)

## 在地性

日本家庭的防灾（防災）不是可选项：各自治体都发防災手册，超市有专门的防灾货架，防灾包讲究「备齐 + 没过期」。水、非常食、药品都有有效期，点检的难点从来不是认不认识这些东西，而是八个品类到底哪格查过、哪格过期。

## 功能流程（闭环）

- 覆盖：8 品类格阵（水/非常食/電灯/ラジオ/電源/常備薬/軍手/笛），滑动选格
- 点检：OK 落 ●、FLAG 落 △（过期/待换），点头 = OK；SCAN 拍期限作暂定メモ
- 收口：8/8 非 ○ 才报完了，并单独列出 △ 清单提醒更换

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 OK 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | 拍照核对路径（见功能流程；失败即 SKIP） |

## 诚实边界

- 期限读数来自拍照+LLM，属暂定信息：必须与包装原文对照，读错以包装为准；SCAN 失败即 SKIP，不影响手工点检
- 品目为东京常见防灾包构成，依各自治体手册增减是后续课题；本 Agent 不提供任何避难判断

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/bosai-kit
~/tools/bin/aix pack . -o ../dist/bosai-kit.aix
~/tools/bin/aix list ../dist/bosai-kit.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Bosai Kit（待导入后回填） |
| Version / Build | 1.0.3 / 待导入后回填 |
| App Category | Life |
| Intent Description | At home before disaster season: sweeps a Japanese emergency kit grid, flagging expired items. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Bosai disaster-kit coverage check: 8 kit categories as a grid that must be fully swept - checked, or flagged expired/to-replace - before it will say done. Photograph a date with the telephoto camera for a tentative expiry note, or flag it yourself. It proves the kit was checked today; it gives no disaster advice and no evacuation directions.

### Opening Message

> ## Bosai Kit
> 
> A disaster kit is only ready when every category was actually checked - including expiry dates. Sweep the 8 cells: water, food, light, radio, power, medicine, gloves, whistle. All cells filled, and only then do I say ready.

### Preview Media

- `preview-bosai-kit-index.png` — 初始状态
- `preview-bosai-kit-s2.png` — 演示状态 2
- `preview-bosai-kit-s3.png` — 演示状态 3
- `preview-bosai-kit-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：榻榻米覆盖格 Coverage Grid；格阵：8 格大标记阵 + 当前格说明行

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
