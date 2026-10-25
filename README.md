# 两拍找不同 Snap Diff

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-snap-diff
```

拍照现实交互游戏系列 GA50。一局两拍：先对准一个场景拍第一张；然后动手只改一处（拿走一件 / 放进一件 / 挪动一件）。

与注意力系列 proof-sweep（文字校对找错工具）的区别：proof-sweep 是对着文稿找文字差错的工作工具；本作找的是真实场景两拍之间的实物变化，是先声明后判定的找不同游戏，照片不用于任何校对留档。

## 预览截图

![预览-ready](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/snap-diff/preview-snap-diff-ready.png)
![预览-playing](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/snap-diff/preview-snap-diff-playing.png)
![预览-done](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/snap-diff/preview-snap-diff-done.png)

## 玩法

1. 一局两拍：先对准一个场景拍第一张；然后动手只改一处（拿走一件 / 放进一件 / 挪动一件）。
2. 先声明：滑动选你改了哪类（少了一件 / 多了一件 / 一件移位），单击或点头确认——声明先定死，再回到原机位拍第二张。
3. 两张照片同送一次大模型判定，大模型回 `TYPE:`（它判的改动类）+ `DIFF:`（一句话说清差异），本地拿 TYPE 与你的声明比对：说中 +1，判定看出的差异原话会显示出来。3 局结算。本作是拍照游戏系列（GA41–GA50）的收官作。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 拍第一张 / 确认改动 / 拍第二张判定 / 下一局 / 再来一局 |
| 滑动 | ArrowUp / ArrowDown | 声明阶段移动改动类选项 |
| 点头 | onHeadGesture('nod') | 声明阶段 = 确认所选；判定显示后 = 记录申诉（不改分） |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕上只有一个主按钮（样式随本款形态单独定型）与一个 DEMO 演示键：DEMO 只在网页预览等无相机/无大模型环境里走标注清楚的演示局（预置结果），真机正常游玩走主按钮的真实拍照判定路径。

## 判定链路

两张 takePhoto(default) 照片各转 FileReader data: URL，在同一次 LanguageModel prompt 里以两个 image_url part 一起送出（多模态 user 消息支持多图 part）；只回 `TYPE:` + `DIFF:` 两行，本地比对 TYPE 与玩家声明。判定回 NONE（看不出差异）记没说中并写明。

判定期间显示「判定中…」等待态。每轮结果都经 TTS 播报。判定是大模型（或原生检测）给的，可能出错——见下。

## 技术诚实说明

- 双图对比对机位一致性敏感：第二张拍偏了，大模型可能把视角差当成变化，或看不出真变化而回 NONE——判定行会原样展示它的 DIFF 说明，玩家可核对；规则要求「回到原机位」写在 UI 里。
- 两张照片都只存本局内存，不落盘；娱乐判定、以玩家目测为准，申诉（判定后点头）只记录不改分。
- 平台没有连续视频理解：每轮都是一次离散拍照判定，不存在实时 AR 式连续识别（这是 stream-probe 探针的实测结论口径）。
- 计分只存本局内存：不调任何存储 API，不落盘、不造排行榜。

## 权限

`CAMERA` 一项：拍照判定必需。代码不使用定位与麦克风采集（TTS 播报不需 RECORD_AUDIO），故只声明这一项。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid-photo/games/snap-diff
~/tools/bin/aix pack . -o snap-diff.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

打包大小 14.04 KB（打包在 README/AGENTS 定稿后执行，`aix list` 已核验包内含 README.md 与 AGENTS.md）。

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-snap-diff`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开两拍找不同智能体」。
5. 验收点：摆一个桌面场景拍第一张，拿走杯子，声明「少了一件」拍第二张，确认判定 TYPE=REMOVED、DIFF 提到杯子且判说中；第二局故意声明与实际改动不符，确认判没说中；第二张故意大幅偏机位，观察判定是否被视角差干扰并如实记录；判定后点头只记申诉；3 局走完确认结算。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 两拍找不同（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Two-photo difference game for Rokid glasses: photo, one change, declare the change type, second photo; both images judged in one host LLM prompt (TYPE plus DIFF) and compared locally with the declaration. Camera only. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限只有 CAMERA 且与实际使用一致；CSS 只用绿色色阶（最亮 `#7dff9e`，无 `#ffffff`、无白色 rgba）。
- 网页预览实跑：用本地 Ink 运行时管线打开预览，点 DEMO 走完一局演示路径（判定为预置结果、全程标注演示局），就绪 / 进行 / 完成各状态截图已逐张目检，状态属实、互不重复。
- `aix pack` 成功，14.04 KB；`aix list` 确认包内含 README.md 与 AGENTS.md。

**未验证（如实说明）**
- 真机相机拍照质量、大模型图片判定的实际延迟与准确率、TTS 实际发声均待 GO 真机自测；判定延迟以 stream-probe 第 03 项真机结果为准（未测前按「判定中」等待态设计）。

## 提审资料 (Review Submission)

### Feature Description

> Spot-the-difference on Rokid glasses, closing the photo-game wave. Photograph a scene, change exactly one thing, declare the change type first (something removed, added, or moved - locked before the second shot), then photograph the scene again from the same spot. Both photos go to the host LLM in one prompt; it returns the change TYPE and a one-line DIFF, scored locally against your declaration. Three rounds. Both photos live in memory only.

### Opening Message

> ## 两拍找不同
> 
> 一局两拍：先对准一个场景拍第一张；然后动手只改一处（拿走一件 / 放进一件 / 挪动一件）。
> 
> 判定仅供娱乐，有争议以你的目测为准；申诉只记录、永不改分。分数只存本局内存。

### Preview Media

- `preview-snap-diff-ready.png`
- `preview-snap-diff-playing.png`
- `preview-snap-diff-done.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 两拍找不同全流程：一局两拍：先对准一个场景拍第一张；然后动手只改一处（拿走一件 / 放进一件 / 挪动一件）。
- 判定链路：两张 takePhoto(default) 照片各转 FileReader data: URL，在同一次 LanguageModel prompt 里以两个 image_url part 一起送出（多模态 user 消息支持多图 part）；只回 `TYPE:` + `DIFF:` 两行，本地比对 TYPE 与玩家声明。判定回 NONE（看不出差异）记没说中并写明。
- 手势优先：单击开始 / 拍第一张 / 确认改动 / 拍第二张判定 / 下一局 / 再来一局；滑动声明阶段移动改动类选项；点头声明阶段 = 确认所选；判定显示后 = 记录申诉（不改分）；每轮结果 TTS 播报，判定中显示等待态
- 诚实机制：判定失败如实记本轮失败不假判；申诉只记录不改分；照片只在内存判定不落盘；网页预览提供标注清楚的 DEMO 演示局

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
