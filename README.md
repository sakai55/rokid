# gaze-translate — 凝视翻译（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-gaze-translate
```

**AIX 直接下载**（最新版）：[gaze-translate.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/gaze-translate.aix)


50 个「指向性生活问题」Agent 的第 DI01 个。在国外看不懂菜单、路牌、说明书时，
不用掏手机（慢、还遮挡视线）：看着文字，把头稳住，眼镜用长焦拍下、翻译，
并直接朗读出来。

## 预览截图

截图统一存放于仓库根目录 `screenshots/gaze-translate/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/gaze-translate/preview-gaze-translate-index.png)

![点 DEMO 后的翻译结果状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/gaze-translate/preview-gaze-translate-demo.png)

## 解决的问题

出国时菜单/路牌/说明书看不懂；手机翻译要掏手机、对焦、举着挡视线。
本 Agent 把「头部朝向」本身当成取词工具：头对着哪里，就翻哪里。

## 指向性设计（为什么必须用眼镜）

- **凝视即指针（GAZE）**：头部对准文字（以头部朝向作指针）即完成选定，没有光标、不用手。
- **头部稳定 = 凝视确认**：`enableWorldAwareness()` 开启世界感知后，
  `onOrientationStabilityChange` 报告头部稳定时才进入可拍状态，界面显示
  「HEAD STEADY — ready」；点头（`onHeadGesture` 的 `nod`）在稳定时触发
  拍摄，晃动时点头会被忽略并提示先稳住头——用方位感代替按键确认。
- **长焦拍摄远处小字**：`getUserMedia({video:true})` 取流后用
  `ImageCapture.takePhoto({mode:'telephoto'})` 拍远处的菜单/路牌小字；
  ImageCapture 不可用时回退 `wx.media` CameraContext。
- **耳朵收结果**：译文用 `speechSynthesis.speak` 朗读（SPEAK 按钮），
  视线不用离开眼前的文字。

## 功能流程

1. 看着文字，稳住头 → 状态变 `HEAD STEADY — ready`
2. 点头，或点 CAPTURE，或按 Enter / GlobalHook → 长焦拍照，显示照片字节数
3. 翻译：优先 LanguageModel 大模型；不可用时回退内置离线词典
   （常见菜单/路牌短语），界面如实标注来源 `LLM / offline dictionary / none`
4. 点 SPEAK 朗读译文
5. 目标语言 EN / 日本語 / 中文：点 LANG 按钮或 ArrowUp / ArrowDown 切换，
   Enter / GlobalHook 确认；Backspace 返回（宿主处理）
6. DEMO 按钮：对内置日文菜单样例跑完整翻译管线，预览即可看到结果态

> 诚实说明：当前 AIUI 运行时没有 OCR 接口。拍摄成功后进入翻译的是代码中
> 明确标注的 OCR 占位/样例文本，界面与代码注释都如实标注，绝不声称已完成
> 文字识别。主机没有相机时 CAPTURE 显示 FAIL 并写明原因。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | 取流并用长焦模式拍摄所凝视的文字 |

仅此一项。相机只在用户触发时启动，拍完立即停掉全部媒体轨道。

## 打包与预览

```bash
cd ~/workspace/rokid/gaze-translate
~/tools/bin/aix pack . -o ../dist/gaze-translate.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-gaze.js`，DEMO 点击坐标为 canvas 内 (358, 187)）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-gaze-translate`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 gaze-translate」，看着外文稳住头、点头拍摄

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 11.9 KB（本地打包 `dist/gaze-translate.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 打包：`aix pack` 成功，`dist/gaze-translate.aix` 约 11.9 KB，包内含
  AGENTS.md、app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：首页初始态完整渲染；点击 DEMO 后显示真实翻译结果
  「Today's special: charcoal-grilled yakitori platter - 1,280 yen」，
  来源如实标注 `offline dictionary`（预览主机上 LLM 未走通时自动回退）。

**未验证**

- 真机相机取流与 telephoto 长焦拍照（预览主机无相机，CAPTURE 的 FAIL
  路径逻辑已写明原因，真机待测）。
- 真机头部稳定检测、点头手势触发、LanguageModel 翻译、TTS 朗读效果。
- OCR：运行时无此接口，未实现、未声称。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Gaze Translate is a hands-free translation flow for menus, signs and manuals abroad. Point your head at the text, hold steady or nod, and the glasses take a telephoto photo of it as a record. It then translates the sample line on screen via the host language model or a built-in offline dictionary (source always labeled) and reads it aloud in English, Japanese or Chinese. Status: the runtime has no OCR, so the photographed text itself is not read yet — live text input is the pending link.

### Opening Message

Hi, I'm **Gaze Translate** — point, hold steady, understand.

Aim at a menu or sign, head held still. At **HEAD STEADY**, nod or tap **CAPTURE**: I take a telephoto photo of the text as a record, then translate the on-screen sample line (host LLM or built-in offline dictionary, source labeled) and read it aloud via **SPEAK**. Honest note: no OCR in this runtime — the photo's words aren't read yet; live text input is the pending link. **LANG** switches EN / 日本語 / 中文; **DEMO** runs the flow.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-gaze-translate-index.png`（aix preview 首页：GAZE TRANSLATE 初始态，含凝视框、日文菜单样例与 CAPTURE/DEMO/LANG/SPEAK 按钮，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-gaze-translate-demo.png`（点 DEMO 后的结果态：译文 + 来源标注 offline dictionary，本地文件）
- Video：待真机补 — 真机录制「稳头 → 点头拍摄 → 朗读」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None (documentation and submission-copy correction only; no behavior change).

**Improvements**

- Directional-design wording aligned to the platform reality: pointing is head orientation, not eye tracking (README「指向性设计」与「解决的问题」）。

**Fixes**

- Submission copy corrected (capability-boundary audit, 2026-10-24): the Feature Description and Opening Message now state plainly that the telephoto photo is kept as a record and that translation runs on the labeled on-screen sample text — the AIUI runtime has no OCR, so photographed text is not read yet. The previous copy described a photo-to-translate pipeline the current build does not perform.

#### Build 1.0.0

**Features added**

- Gaze-confirmed telephoto translation: head-stability gaze confirmation (HEAD STEADY), nod-to-capture, ImageCapture telephoto photo with wx camera fallback.
- Translation via LanguageModel with an offline dictionary fallback for common menu/sign phrases; the result source (LLM / offline dictionary / none) is always shown.
- Target language EN / 日本語 / 中文， switched by the LANG button or ArrowUp/ArrowDown keys; SPEAK reads the translation aloud; DEMO runs the full pipeline on a sample Japanese menu line.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
