# glasses-benchmark — Rokid 眼镜全功能 Benchmark（AIUI Agent）

第一个开发测试智能体：一键跑完 Rokid 眼镜在 AIUI 下的全部功能，共 23 项（21 项实测 + 2 项平台边界声明）。

## 预览截图

截图统一存放于仓库根目录 `screenshots/glasses-benchmark/`。

![首页（READY 状态）](../screenshots/glasses-benchmark/preview-glasses-benchmark-index.png)

![RUN ALL 跑完后的结果页](../screenshots/glasses-benchmark/preview-index-runall.png)

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 12345 |
| Version（Build） | 1.0.19 |
| App Category | Life |
| Intent Description | full |
| Agent ID | ca29aef525bd42db377edba9021656 |
| AIX Package Size | 7.93 KB |
| 状态 | ● Debug version ready — Ready for device debugging |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

> 每次在 Studio 里 Repackage and Save 后，Build 号会递增，上表同步更新。

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

## 打包

```bash
~/tools/bin/aix pack . -o ../dist/glasses-benchmark.aix
~/tools/bin/aix preview .
```

## 真机测试（海外版 · 云端下发）

1. 推到 GitHub → Global AIUI Studio（en-US）从 GitHub 导入（子目录 `glasses-benchmark`）
2. Studio 的 **Device Debug** 页签填 Basic Information（Name / Category / Intent Description），
   在 AIX Packaging 点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版，不是国内版 Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包
4. 对眼镜说「乐奇，打开 glasses-benchmark」，点 RUN ALL

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
