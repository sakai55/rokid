# my-agent — AIUI 脚手架示例智能体

官方脚手架（`npm create @yodaos-pkg/aiui-agent`）生成的示例 Agent：单页 `pages/index/index.ink`，点击后问候语在 “Hello AIUI!” 与 “你好，世界！” 之间切换。用于验证开发 → 打包 → GitHub → Studio 导入 → 真机测试全流程。

在 AIUI Studio 中导入本仓库时，子目录选 `my-agent`。

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | （尚未导入） |
| Version（Build） | — |
| App Category | — |
| Intent Description | — |
| Agent ID | — |
| 状态 | 尚未导入 Studio，未进行真机测试 |

> 导入并在 Device Debug 里 Repackage and Save 后，把名称、Build 版本、分类、
> 描述、Agent ID 和状态完整补到这里。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

My Agent is a minimal starter agent created from the official AIUI scaffold. It renders a single page on Rokid Glasses showing a greeting, and switches the greeting between English and Chinese when the button is tapped, demonstrating .ink page structure, data binding and tap interaction in the smallest possible AIUI agent. It serves as a hello-world reference for new AIUI developers and a smoke test for the develop, package, import and device-debug pipeline.

### Opening Message

Hello! I'm **my-agent**, a tiny starter agent.

Open my page and tap the button — the greeting switches between English and Chinese. That's the simplest AIUI page interaction there is.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-my-agent-index.png`（aix preview 生成的首页预览图，本地文件，提交时从本地上传）
- Video：待补 — 真机或预览录制点击切换问候语的过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（目前只有 1 张图；补齐到 3–5 个且含视频后才可提交）

### Change Log

#### Build —（尚未进入 Studio，无 Build 号）

**Features added**

- Initial scaffold agent: single .ink page, tap the button to switch the greeting between English and Chinese.

**Improvements**

- None (initial version).

**Fixes**

- None (initial version).
