# 场景记忆 Scene Memory

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-scene-memory
```

**AIX 直接下载**（最新版）：[scene-memory.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/scene-memory.aix)

拍照现实交互游戏系列 GA45。先对准一个真实场景（桌面、书架、房间一角）拍一张全景照（wide）。大模型看着这张首图当场出 3 道记忆题并定死正确答案（问题只问画面里确实可见的物品、颜色、数量、位置）。

与注意力系列 day-lookback（日终回看当天登记内容的日记工具）的区别：day-lookback 是回放你一天真实记录的生活工具；本作是当场拍、当场出题、当场转头答题的记忆游戏，照片与题目都只活在本局内存，关掉即没。

## 预览截图

![预览-ready](../screenshots/scene-memory/preview-scene-memory-ready.png)
![预览-playing](../screenshots/scene-memory/preview-scene-memory-playing.png)
![预览-done](../screenshots/scene-memory/preview-scene-memory-done.png)

## 玩法

1. 先对准一个真实场景（桌面、书架、房间一角）拍一张全景照（wide）。大模型看着这张首图当场出 3 道记忆题并定死正确答案（问题只问画面里确实可见的物品、颜色、数量、位置）。
2. 出题后转过头去、不再看那个场景，凭记忆答题：每题的 3 个选项就是 3 道题的正确答案（按题号轮转排列），考的是「哪个答案配哪道题」。滑动选、单击或点头确认，即时判对错并播报正解。
3. 3 题答完结算。出题失败（大模型不可用或没按格式出题）会如实显示「出题失败 · 可重拍」，绝不编题；可重拍一张重新出题。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 拍场景照出题 / 确认答案 / 再来一局 |
| 滑动 | ArrowUp / ArrowDown | 移动答案选项 |
| 点头 | onHeadGesture('nod') | 答题阶段 = 确认所选答案 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕上只有一个主按钮（样式随本款形态单独定型）与一个 DEMO 演示键：DEMO 只在网页预览等无相机/无大模型环境里走标注清楚的演示局（预置结果），真机正常游玩走主按钮的真实拍照判定路径。

## 判定链路

takePhoto(wide) → FileReader data: URL → LanguageModel 图片输入，要求只回 3 行 `Qn: 问题 | An: 答案`，本地正则解析并把答案定死；答题阶段全本地比对，不再调大模型。

判定期间显示「判定中…」等待态。每轮结果都经 TTS 播报。判定是大模型（或原生检测）给的，可能出错——见下。

## 技术诚实说明

- 题目质量取决于大模型看首图的准确度：它看错了画面，题目与「正解」就会一起错——这是写明的已知边界，判分口径是「以首图判定为准」，不假装客观真理。
- 照片只在内存里出题，不落盘；答题选项就是三题的正解集合，玩家若记住了答案内容却配错题，照样判错——规则在 UI 与本文件写明。
- 判定（出题）仅供娱乐，有争议以玩家目测为准。
- 平台没有连续视频理解：每轮都是一次离散拍照判定，不存在实时 AR 式连续识别（这是 stream-probe 探针的实测结论口径）。
- 计分只存本局内存：不调任何存储 API，不落盘、不造排行榜。

## 权限

`CAMERA` 一项：拍照判定必需。代码不使用定位与麦克风采集（TTS 播报不需 RECORD_AUDIO），故只声明这一项。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid-photo/games/scene-memory
~/tools/bin/aix pack . -o scene-memory.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

打包大小 13.89 KB（打包在 README/AGENTS 定稿后执行，`aix list` 已核验包内含 README.md 与 AGENTS.md）。

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-scene-memory`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开场景记忆智能体」。
5. 验收点：对着一个内容丰富的桌面拍照，确认出 3 道题且问题问的都是画面里真有的东西、答案属实；转头答题确认选项是三题正解的轮转、选对判对、选错播报正解；遮挡镜头或断网确认出题失败可重拍、不编题；3 题走完确认结算与再来一局。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 场景记忆（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Scene memory game for Rokid glasses: one wide photo, the host LLM fixes three Q&A from it, the player turns away and answers from memory against locally scored answers. Camera only. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限只有 CAMERA 且与实际使用一致；CSS 只用绿色色阶（最亮 `#7dff9e`，无 `#ffffff`、无白色 rgba）。
- 网页预览实跑：用本地 Ink 运行时管线打开预览，点 DEMO 走完一局演示路径（判定为预置结果、全程标注演示局），就绪 / 进行 / 完成各状态截图已逐张目检，状态属实、互不重复。
- `aix pack` 成功，13.89 KB；`aix list` 确认包内含 README.md 与 AGENTS.md。

**未验证（如实说明）**
- 真机相机拍照质量、大模型图片判定的实际延迟与准确率、TTS 实际发声均待 GO 真机自测；判定延迟以 stream-probe 第 03 项真机结果为准（未测前按「判定中」等待态设计）。

## 提审资料 (Review Submission)

### Feature Description

> Scene memory game on Rokid glasses. Photograph one real scene; the host LLM studies that first photo and fixes three memory questions with their correct answers. Then turn away and answer from memory: every question offers the same three correct answers rotated, so you must match each answer to its question. Scoring is local against the answers fixed at photo time. If question generation fails, the game says so and lets you re-shoot - it never invents questions.

### Opening Message

> ## 场景记忆
> 
> 先对准一个真实场景（桌面、书架、房间一角）拍一张全景照（wide）。大模型看着这张首图当场出 3 道记忆题并定死正确答案（问题只问画面里确实可见的物品、颜色、数量、位置）。
> 
> 判定仅供娱乐，有争议以你的目测为准；申诉只记录、永不改分。分数只存本局内存。

### Preview Media

- `preview-scene-memory-ready.png`
- `preview-scene-memory-playing.png`
- `preview-scene-memory-done.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 场景记忆全流程：先对准一个真实场景（桌面、书架、房间一角）拍一张全景照（wide）。大模型看着这张首图当场出 3 道记忆题并定死正确答案（问题只问画面里确实可见的物品、颜色、数量、位置）。
- 判定链路：takePhoto(wide) → FileReader data: URL → LanguageModel 图片输入，要求只回 3 行 `Qn: 问题 | An: 答案`，本地正则解析并把答案定死；答题阶段全本地比对，不再调大模型。
- 手势优先：单击开始 / 拍场景照出题 / 确认答案 / 再来一局；滑动移动答案选项；点头答题阶段 = 确认所选答案；每轮结果 TTS 播报，判定中显示等待态
- 诚实机制：判定失败如实记本轮失败不假判；申诉只记录不改分；照片只在内存判定不落盘；网页预览提供标注清楚的 DEMO 演示局

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

- 删除 FileReader（Ink 运行时不存在，真机必死）：照片 Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，失败接全局错误码 E2005 并如实显示出题失败可重拍。
