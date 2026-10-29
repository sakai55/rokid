# 质地猎手 Texture Hunt

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-texture-hunt
```

**AIX 直接下载**（最新版）：[texture-hunt.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/texture-hunt.aix)

拍照现实交互游戏系列 GA49。每轮出一种质地（固定顺序：木纹 → 金属 → 布料 → 玻璃 → 纸），语音同步播报。找一处该质地的实物表面，凑近让表面占满画面，单击拍照。

与注意力系列 plant-doctor（看叶片判植物状态的养护工具）的区别：plant-doctor 是对着植物做健康判断的生活工具；本作判的是任意实物表面的质地类别，是找质地计分游戏，不做任何诊断。

## 预览截图

![预览-ready](../../screenshots/texture-hunt/preview-texture-hunt-ready.png)
![预览-playing](../../screenshots/texture-hunt/preview-texture-hunt-playing.png)
![预览-done](../../screenshots/texture-hunt/preview-texture-hunt-done.png)

## 玩法

1. 每轮出一种质地（固定顺序：木纹 → 金属 → 布料 → 玻璃 → 纸），语音同步播报。找一处该质地的实物表面，凑近让表面占满画面，单击拍照。
2. 判定看的是表面质地本身（纹理与材质），不是物体名称：一张木桌拍远了只看到「桌子」不一定过，凑近拍出木纹才算。照片送大模型，只回 `VERDICT:` + `REASON:`，本地解析，命中 +1。
3. 滑动可先跳到另一未拍质地轮；判定后点头 = 记录申诉（不改分）；大模型不可用/格式不对，该轮如实记判定失败。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 拍照判定 / 下一轮 / 再来一局 |
| 滑动 | ArrowUp / ArrowDown | 切换到上一个 / 下一个未判定目标（已判定的不重拍） |
| 点头 | onHeadGesture('nod') | 判定显示后 = 记录申诉（只记次数，永不改分）；判定前 = 重读本轮目标 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕上只有一个主按钮（样式随本款形态单独定型）与一个 DEMO 演示键：DEMO 只在网页预览等无相机/无大模型环境里走标注清楚的演示局（预置结果），真机正常游玩走主按钮的真实拍照判定路径。

## 判定链路

takePhoto(default) → FileReader data: URL → LanguageModel 图片输入；提示词写明「判表面质地（纹理与材质），不看物体名称」，只回 `VERDICT:` + `REASON:` 两行，本地解析。

判定期间显示「判定中…」等待态。每轮结果都经 TTS 播报。判定是大模型（或原生检测）给的，可能出错——见下。

## 技术诚实说明

- 质地判定对拍摄距离敏感：太远看不清纹理会被判 NO，判定理由会写明——这属于玩法本身（凑近拍），不是隐藏规则，UI 已明示。仿真材质（如木纹贴纸）按画面质地判，判定可能与真实材质不符，写明娱乐判定、以玩家目测为准。
- 照片只在内存判定，不落盘；不拍他人正脸作判定对象。
- 平台没有连续视频理解：每轮都是一次离散拍照判定，不存在实时 AR 式连续识别（这是 stream-probe 探针的实测结论口径）。
- 计分只存本局内存：不调任何存储 API，不落盘、不造排行榜。

## 权限

`CAMERA` 一项：拍照判定必需。代码不使用定位与麦克风采集（TTS 播报不需 RECORD_AUDIO），故只声明这一项。

## 打包与预览

```bash
cd ~/workspace/rokid/git-rokid-photo/games/texture-hunt
~/tools/bin/aix pack . -o texture-hunt.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

打包大小 13.96 KB（打包在 README/AGENTS 定稿后执行，`aix list` 已核验包内含 README.md 与 AGENTS.md）。

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-texture-hunt`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开质地猎手智能体」。
5. 验收点：凑近木桌表面拍木纹轮确认命中；站远拍整张木桌确认可能没中且理由提到纹理不清（验证距离口径）；对塑料表面拍布料轮确认没中；滑动、点头申诉各验一次；5 轮走完确认结算。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 质地猎手（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Texture-hunt photo game for Rokid glasses: each round names a texture; the player photographs a real surface up close and the host LLM judges the surface texture (VERDICT YES/NO plus reason). Camera only. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限只有 CAMERA 且与实际使用一致；CSS 只用绿色色阶（最亮 `#7dff9e`，无 `#ffffff`、无白色 rgba）。
- 网页预览实跑：用本地 Ink 运行时管线打开预览，点 DEMO 走完一局演示路径（判定为预置结果、全程标注演示局），就绪 / 进行 / 完成各状态截图已逐张目检，状态属实、互不重复。
- `aix pack` 成功，13.96 KB；`aix list` 确认包内含 README.md 与 AGENTS.md。

**未验证（如实说明）**
- 真机相机拍照质量、大模型图片判定的实际延迟与准确率、TTS 实际发声均待 GO 真机自测；判定延迟以 stream-probe 第 03 项真机结果为准（未测前按「判定中」等待态设计）。

## 提审资料 (Review Submission)

### Feature Description

> Texture hunt on Rokid glasses. Five target textures: wood grain, metal, fabric, glass, paper. Find a real surface, get close so the texture fills the frame, and snap. The host LLM judges the surface texture itself - grain and material, not the object's name - and replies VERDICT YES/NO plus a reason. Distance matters and the reason says so. Swipe switches unattempted rounds; nod logs a non-scoring appeal.

### Opening Message

> ## 质地猎手
> 
> 每轮出一种质地（固定顺序：木纹 → 金属 → 布料 → 玻璃 → 纸），语音同步播报。找一处该质地的实物表面，凑近让表面占满画面，单击拍照。
> 
> 判定仅供娱乐，有争议以你的目测为准；申诉只记录、永不改分。分数只存本局内存。

### Preview Media

- `preview-texture-hunt-ready.png`
- `preview-texture-hunt-playing.png`
- `preview-texture-hunt-done.png`

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 质地猎手全流程：每轮出一种质地（固定顺序：木纹 → 金属 → 布料 → 玻璃 → 纸），语音同步播报。找一处该质地的实物表面，凑近让表面占满画面，单击拍照。
- 判定链路：takePhoto(default) → FileReader data: URL → LanguageModel 图片输入；提示词写明「判表面质地（纹理与材质），不看物体名称」，只回 `VERDICT:` + `REASON:` 两行，本地解析。
- 手势优先：单击开始 / 拍照判定 / 下一轮 / 再来一局；滑动切换到上一个 / 下一个未判定目标（已判定的不重拍）；点头判定显示后 = 记录申诉（只记次数，永不改分）；判定前 = 重读本轮目标；每轮结果 TTS 播报，判定中显示等待态
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

- 删除 FileReader（Ink 运行时不存在，真机必死）：照片 Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，失败接全局错误码 E2005 并如实记为拍照失败可重试。
