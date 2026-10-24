# glasses-benchmark — Rokid 眼镜全功能 Benchmark（AIUI Agent）

第一个开发测试智能体：一键跑完 Rokid 眼镜在 AIUI 下的全部功能，共 23 项（21 项实测 + 2 项平台边界声明）。

## 预览截图

截图统一存放于仓库根目录 `screenshots/glasses-benchmark/`。

![首页（READY 状态）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/glasses-benchmark/preview-glasses-benchmark-index.png)

![RUN ALL 跑完后的结果页](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/glasses-benchmark/preview-index-runall.png)

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | sakai55/rokid（分支导入的默认名，待在 Studio 内改名） |
| Version（Build） | 1.0.1（Device Debug 首次 Package and Save：1.0.0 → 1.0.1） |
| App Category | Work（导入端到端验证时所填） |
| Intent Description | —（未填） |
| Agent ID | 87963d2dfa304a9f8ff9595eb7879820 |
| AIX Package Size | 12.74 KB（Studio 打包生成） |
| 状态 | ● Packaged — Uploaded to the cloud and completed AIX packaging；Simulator 运行通过（完整 UI、无报错） |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

> 更正（2026-10-24）：本表此前误填了另一个 agent「12345」（Agent ID ca29aef525bd42db377edba9021656，GO 通过对话会话创建，Build 1.0.19 / Life / "full"）的数据——那不是本仓库的 glasses-benchmark。上表为分支 `agent-glasses-benchmark` 导入的草稿的实测值。
> 注意：Studio 里的代码仍是首次导入时的版本，仓库的改动不会自动同步过去；本地代码现为 v1.1.2，需在 Studio 重新同步分支后，再 Package and Save 生成新 Build，上表随之更新。

## 测试项

| # | 项目 | 测什么 |
|---|------|--------|
| 01 | Device | navigator 身份 / Ink·Skia 版本 / 语言 / 地区 |
| 02 | Display | 视口尺寸 / 渲染开关 / 12 次连续重绘 |
| 03 | CPU | 30 万次数学循环吞吐 (ops/s) |
| 04 | Crypto | getRandomValues + SHA-256 + randomUUID |
| 05 | Storage | localStorage + wx 同步存储读写 |
| 06 | Net Info | 在线状态 / 连接类型 / RTT / 下行估算 |
| 07 | Net Fetch | HTTPS 请求 example.com 往返 |
| 08 | Canvas 2D | 渐变 / 图形 / 文字 / flush（画布直接可见） |
| 09 | Audio Out | Web Audio 880Hz 振荡器（扬声器） |
| 10 | Microphone | 设备枚举 + 四种官方麦克风模式逐个探测（wearer / far-field / near-field / omnidirectional）+ wearer 模式 0.9 秒录音 |
| 11 | Camera | 取流 + 三种官方模式各拍一张并解码实际像素（wide 2016×2688 / telephoto 2016×1512 / default 3024×4032，回退 wx CameraContext 无模式参数） |
| 12 | Accel | 加速度计读数 |
| 13 | Gyro/Ori | 陀螺仪 + 绝对方向四元数 |
| 14 | Geolocation | 单次定位 + 精度 |
| 15 | Bluetooth | BLE 可用性 + 已知设备数 |
| 16 | Battery | 电量 + 充电状态（不支持时 SKIP） |
| 17 | TTS Synth | speechSynthesis.synthesize；SPEAK 按钮做真人耳确认 |
| 18 | ASR Caps | 识别能力查询；LISTEN 按钮做实时识别 |
| 19 | LLM | LanguageModel 可用性 + 一次短推理 |
| 20 | Barcode | BarcodeDetector 支持格式 |
| 21 | Interaction | 按键 / 点头手势 / 头稳 / 语音唤醒（被动监听，触发即 PASS） |
| 22 | EyeTrack（边界） | 平台无眼动追踪 API——恒为 SKIP 并注明：「凝视」=头部朝向+头稳+点头（见 13/21），永不报 PASS |
| 23 | OCR（边界） | 平台无 OCR API——恒为 SKIP 并注明：读文字走 telephoto 拍照 + LLM 图片输入（见 11/19），永不报 PASS |

状态：PASS / FAIL / SKIP（硬件或主机不支持、或平台无此 API）/ MANUAL（需人触发）。
点任意一行可单独重跑该项；RUN ALL 顺序跑完 01–20 与 22–23。

## 操作方式（镜腿手势映射）

真机上没有触屏，全部操作走镜腿触控板（页面自己接管按键事件，不依赖宿主把按键转成按钮点击）：

| 手势 | 键事件 | 作用 |
|---|---|---|
| 单击 | Enter / GlobalHook | 触发当前焦点；打开页面时焦点默认在 **RUN ALL**，单击即开跑全部 |
| 滑动 | ArrowUp / ArrowDown | 在 RUN ALL / SPEAK / LISTEN / 23 个测试行之间移动焦点（高亮 + 列表自动滚到焦点行） |
| 点头 | onHeadGesture 'nod' | 与单击相同，触发当前焦点 |
| 双击 | Backspace | 交给系统：返回 / 退出（页面不拦截） |

想单独重跑某一项：滑动把焦点移到该行，单击即可。屏幕按钮同时保留点击绑定，供 Studio 模拟器用鼠标操作。

## 打包

```bash
~/tools/bin/aix pack . -o ../dist/glasses-benchmark.aix
~/tools/bin/aix preview .
```

## 真机测试（海外版 · 云端下发）

1. 推到 GitHub → Global AIUI Studio（en-US）用分支地址导入：`https://github.com/sakai55/rokid/tree/agent-glasses-benchmark`（已导入过的草稿需重新同步到最新代码）
2. Studio 的 **Device Debug** 页签填 Basic Information（Name / Category / Intent Description），
   在 AIX Packaging 点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版，不是国内版 Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包
4. 对眼镜说「乐奇，打开 glasses-benchmark」，然后**单击镜腿**（焦点默认在 RUN ALL）即开跑；滑动可移焦点到某一行，单击单独重跑该项

注意：07 Fetch 需要眼镜联网（经手机蓝牙/Wi-Fi）；14 定位、10/11 麦克风/相机
第一次会弹系统授权，拒绝会记 FAIL 并写明原因——这正是要测的。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Glasses Benchmark is a full self-check for Rokid Glasses under AIUI. Tap RUN ALL to run 23 checks: device, display, CPU, crypto, storage, network, Canvas 2D, audio, microphone (all 4 official modes), camera (wide / telephoto / default), sensors, geolocation, Bluetooth, battery, TTS, ASR, LLM, barcode and interaction. Two boundary items state what the platform has no API for — eye tracking and OCR — and always report SKIP, never PASS. Every item shows PASS, FAIL, SKIP or MANUAL with a reason.

### Opening Message

Hi, I'm **Glasses Benchmark** — your on-glasses self-check.

Tap **RUN ALL** and I'll test 23 items one by one, from display and CPU to camera, sensors, TTS and the built-in LLM. Two items are platform boundaries (no eye-tracking or OCR API exists) and will always show **SKIP** — that's the honest answer, not a failure. Items marked **MANUAL** need a quick tap or your ears to confirm. You can also tap any single row to re-run just that test.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-glasses-benchmark-index.png`（aix preview 首页预览图：READY 状态，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-index-runall.png`（RUN ALL 跑完后的结果页预览图，本地文件）
- Video：待补 — 真机录制 RUN ALL 运行过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### v1.1.2（本地包版本；Studio Build 号待重新打包后生成）

**Features added**

- None.

**Improvements**

- The app version (mirrors package.json `version`) is now shown at the bottom-right corner of the page, so the build actually running on the glasses can be identified at a glance — Studio's own Build number is generated on its side and does not follow the repo version.

**Fixes**

- None.

#### v1.1.1（本地包版本；Studio Build 号待重新打包后生成）

**Features added**

- None.

**Improvements**

- None.

**Fixes**

- Real-device operation: the page previously only logged temple key events, so the RUN ALL / SPEAK / LISTEN buttons could not be operated from the temple touchpad at all. The page now maps temple input itself — swipe (ArrowUp/Down) moves a visible focus across the buttons and all 23 test rows, tap (Enter/GlobalHook) or a nod activates the focused item, and the default focus is RUN ALL, so a single tap starts the full run.

#### v1.1.0（本地包版本；Studio Build 号待重新打包后生成）

**Features added**

- Two platform-boundary items (22 EyeTrack, 23 OCR): the official AIUI API has no eye-tracking and no OCR API, so these always report SKIP with the reason and the official alternative path — they can never report PASS.
- Microphone test now probes all four official microphone modes (wearer / far-field / near-field / omnidirectional) and reports how many the host accepts.

**Improvements**

- Camera test now takes one photo in each official mode (wide / telephoto / default) and decodes each photo to report its real pixel size, instead of a single modeless photo.
- Capability-boundary audit against the official Rokid capability dossier (2026-10-24): permissions, sensor set, canvas size (480×352) and monochrome-green styling re-verified.

**Fixes**

- None.

#### Build 1.0.19

**Features added**

- Initial release: 21-item full-function benchmark — device, display, CPU, crypto, storage, network info/fetch, Canvas 2D, audio out, microphone, camera, accelerometer, gyroscope/orientation, geolocation, Bluetooth, battery, TTS, ASR, LLM, barcode detection and interaction events.
- Result states PASS / FAIL / SKIP / MANUAL with a reason per item; tap any row to re-run a single test.

**Improvements**

- First build packaged and saved in Global AIUI Studio for device debugging (Debug version ready).

**Fixes**

- None (initial release).
