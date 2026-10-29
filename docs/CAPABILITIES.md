# Rokid Glasses 能力档案（官方来源版）

中文 | [English](CAPABILITIES.en.md) | [日本語](CAPABILITIES.ja.md)

> 整理日期：2026-10-24，最后更新：2026-10-29
> 资料原则：**只采用 Rokid 官方来源**（官方产品页、官方文档站、官方 GitHub 仓库 `yodaos-project/AIUI` 及其内置的 `aiui-dev` skill 参考）。每条非平凡结论都标注来源。
> 标注约定：**** = 官方页面/文档原文写明；**** = 由官方 API 文档的存在/缺失合理推导，已明确标出；**官方未公布** = 在所查官方来源中找不到，绝不猜测。
> 本地 skill 参考的统一出处：官方仓库 `skills/aiui-dev`（https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev），下文引用写作 `skill: references/…`。

---

## 1. 硬件规格

数据来源以官方全球产品页为准：https://global.rokid.com/products/b-h-rokid-glasses-with-display
（英国官方站 https://gb.rokid.com/collections/rokid-ai-lineup 的参数与之互相印证。）

| 项目 | 规格 | 备注 |
|---|---|---|
| SoC | Snapdragon AR1（高通） | 产品页 Performance 一栏只写 "Snapdragon AR1"，未写世代后缀；产品页另有 "Dual-Chip Performance" 宣传语，但官方规格表未列出第二颗芯片的型号 |
| RAM / 存储 | 2 GB / 32 GB | |
| 显示技术 | 双目 Micro LED + 衍射光波导（Binocular Micro LED waveguide），光学设计为 "1 Micro LED + waveguide" | |
| 显示颜色 | **单色绿**（Single green display） | 不是全彩；AIUI 设计规范同样定义为单一绿色发光通道（`skill: references/design/monochrome-green.md`） |
| 显示分辨率 | **480 × 400** | ⚠️ 与 AIUI 运行时参考画布 480 × 352 不一致，见第 5 节 |
| FOV | 30° | |
| 亮度 | 1500 nits | |
| 摄像头 | 12 MP，照片分辨率 3024 × 4032，光圈 F2.25 | 产品页营销文案称 "Sony sensor"，但规格表未给出传感器型号；摄像头 FOV 官方未公布 |
| 照片格式 | 4K 3:4、4K 9:16、3K 4:3 | |
| 视频格式 | 最高 3K 30fps（9:16）；另有 2.5K 30fps（3:4 / 4:3）、2K 30fps（9:16 / 9:19.5） | |
| 麦克风 | **4 麦克风阵列**（4-microphone array） | |
| 扬声器 | 双线性定向高保真扬声器（Dual linear directional high-fidelity speakers） | |
| 传感器 | IMU：Supported | 官方产品页未公布 IMU 轴数/型号；AIUI 侧可调用的传感器见 2.7 |
| 电池 | 210 mAh | 续航口径不一，见下 |
| 续航 | FAQ 称日常使用约 **8–10 小时**；同页对比表称 **up to 6 h mixed use**、配充电盒 **up to 30 h** | |
| 充电 | 磁吸充电；快充 20 分钟充至 80%；充电盒可为眼镜充满约 10 次；另有可选 Power Capsule 配件 | |
| 无线连接 | Wi-Fi 6、Bluetooth 5.3（BT 5.3） | |
| 重量 | 49 g | |
| 尺寸 | 镜腿长 155.5 mm、铰链间距 146.3 mm、镜片宽 49 mm、镜框高 44.4 mm | 镜框材质 TR90，铰链钛合金 |
| 防护等级 | IPX4 | |
| 唤醒词 | "Hi Rokid" | 中文唤醒词见 3.1（运行时文档） |
| 配镜 | 支持屈光度 +15 至 −15，官方配镜服务 + 磁吸配镜框 | |
| 系统/OS | **官方未公布** | 产品页与文档均未标注眼镜操作系统名称/版本；可知的是智能体运行时为自研 Ink 容器（QuickJS + Skia），见 2.1 与 https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md |
| 摄像头指示灯 | 支持（Camera indicator: supported） | 拍摄时有指示，属隐私设计 |

### 1.1 官方功能清单（产品级，非 Agent API）

官方产品页列出的整机功能：实时翻译（支持 89 种语言）、UI 语言 13 种、AI 助手（Voice AI + Vision AI，模型提及 Qwen + ChatGPT 等）、通知（显示+声音）、导航、提词器、笔记、会议转录、SDK 支持。
注意：这些是**眼镜系统/官方 App 的功能**，不等于 AIUI Agent 可调用的 API（见第 2 节）。

---

## 2. AIUI 运行时能力（Agent 实际可调用的 API）

运行时环境：在 Rokid Glasses 上，智能体的逻辑层与视图层运行在基于 **QuickJS**（JS 引擎）与 **Skia**（渲染）构建的自研容器 **Ink** 中，针对穿戴设备的低功耗/内存/CPU 做了优化。来源：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
API 契约以下文的 skill 参考为准（`skill: references/apis/*.md`），该 skill 即官方仓库随附的开发契约文档。

### 2.1 设备信息与系统状态（`navigator`）

来源：`skill: references/apis/navigator.md`

| API | 能力 | 限制/说明 |
|---|---|---|
| `navigator.id` | 与智能体+设备绑定的不透明 ID | 普通重启/升级通常稳定；不得当作凭据 |
| `navigator.userAgent` / `versions.ink` / `versions.skia` | 运行时与渲染引擎版本字符串 | |
| `navigator.language` / `languages` / `region` | 语言偏好（BCP 47）与地区 | 可能为空字符串 |
| `navigator.renderingEnabled` | 当前实例能否渲染可见界面 | |
| `navigator.onLine` / `navigator.connection` | 在线状态与连接信息：`type`（none/wifi/ethernet/cellular/bluetooth/other/unknown）、`effectiveType`、`downlink`、`rtt`、`saveData`，及 `change` 事件 | 仅为估计值，不保证服务可达；经手机蓝牙转发时 `type` 可能报 `bluetooth` |
| `navigator.getBattery()` | 返回 `Promise<BatteryManager>` | 主机无电池能力时 Promise 被拒；⚠️ navigator 参考称电量方法在 device 参考中，但 device 参考实际没有电池章节（见第 5 节） |
| `navigator.getDeviceSerialNumber()` | 设备序列号 | **仅系统级智能体**可拿到，普通智能体返回空字符串 |
| `navigator.requestDeviceToken()` | 设备令牌 | **仅系统级智能体**，普通智能体不得依赖 |

### 2.2 显示与窗口（`window`）

来源：`skill: references/apis/window.md`、`skill: references/framework.md`

- `window.innerWidth` / `innerHeight`：只读视口尺寸（逻辑像素）。
- 全屏 Page 参考画布 **480 × 352 px**（设计规范定义，目标设备 RokidGlasses1 / RokidGlasses2），安全边距左右 16px、上下 12px，有效内容宽 448px。来源：`skill: references/design/monochrome-green.md`
- Widget（桌面小组件）尺寸族：`1x1` = 239 × 140、`1x2` = 480 × 140；眼镜共 **4 个 Widget 网格位**。`family` 只是尺寸类别，禁止把根节点写死为该像素值。
- `window.open(url, '_widget')`：只能打开 `app.json` 已声明的 Widget（唯一 target `_widget`，支持 `placement: 'overlay'` 浮层）；不能打开其他 Page 或外部 URL。
- `window.close()`：请求宿主关闭当前智能体实例。
- `window.atob/btoa`、全局 `createImageBlob(bitmap, …)`（PNG/JPEG 编码）。

### 2.3 摄像头（Camera）

来源：`skill: references/apis/media.md`、`skill: references/apis/wx.md`。需声明 `CAMERA` 权限。

| API | 能力 | 关键参数/限制 |
|---|---|---|
| `navigator.mediaDevices.getUserMedia({video})` | 获取视频流（MediaStream） | 约束支持 `facingMode`、`width`、`height`、`frameRate`、`deviceId`；最终值读 `track.getSettings()` |
| `ImageCapture.takePhoto(options?)` | 拍照，返回编码后的 `Blob` | **三种模式**：`mode: 'wide'`（条码扫描用广角）、`mode: 'telephoto'`（读远处文字的长焦）、`mode: 'default'`（普通拍照）；另有 `quality`、`enableSystemPreview` 选项 |
| 拍照默认输出尺寸 | wide = 2016 × 2688；telephoto = 2016 × 1512；default = 3024 × 4032 | 与视频流尺寸可能不同；Blob 本身不带宽高，需 `createImageBitmap()` 解码 |
| `ImageCapture.grabFrame()` | 返回未编码的 `ImageBitmap` 像素帧 | 用后需 close bitmap |
| `wx.media.createCameraContext().takePhoto()` | wx 风格拍照，返回 `{ data: ArrayBuffer, mimeType}` | 必须在交互门（interactive）调用点触发；无模式选择参数（模式选择走 Web 的 ImageCapture） |
| `MediaRecorder` | 录制音视频流 | 支持 `video/webm;codecs=vp8,opus`、`video/mp4` 等（先用 `isTypeSupported()` 查） |

### 2.4 麦克风与录音

来源：`skill: references/apis/media.md`。需声明 `RECORD_AUDIO` 权限，且必须从有效的用户交互出发起采集。

| API/参数 | 能力 | 关键限制 |
|---|---|---|
| `getUserMedia({audio:{captureSource}})` | 录音来源选择：`'microphone'`（麦克风）或 `'system-audio'`（设备播放混音，即系统声音内录） | system-audio 不能与 `echoCancellation: true` 或 `microphoneMode` 组合，否则 `OverconstrainedError`；系统声音不自动回退到麦克风 |
| `microphoneMode`（麦克风模式） | **四种模式**：`'wearer'`（默认，优先佩戴者人声）、`'far-field'`（远处声音）、`'near-field'`（近处声音）、`'omnidirectional'`（全向不偏重方向） | 仅对麦克风来源有效；设备是否支持每种模式不保证，不支持时报 `OverconstrainedError`；实际生效值读 track 的 `getSettings()` |
| `MediaRecorder` | 录音编码 | 支持 `audio/wav`、`audio/ogg;codecs=opus` |
| `wx.media.getRecorderManager()` | wx 风格录音（start/pause/resume/stop、帧回调等） | **使用默认麦克风，不提供来源/模式选择参数**；要选模式必须用 Web 的 getUserMedia |

### 2.5 音频播放与 Web Audio

来源：`skill: references/apis/media.md`

- `AudioPlayer`：通用播放器（本地包内文件或网络 URL），支持 `pcm` / `ogg_opus` 流式 `append()` 播放、字幕文本轨（`TextTrack`/`VTTCue`）。
- `Sound`：本地音效短播放（仅本地文件，拒绝 http(s) URL）。
- Web Audio：`AudioContext` + `createBuffer/Oscillator/Gain/BiquadFilter/Analyser/MediaStreamSource`、`decodeAudioData` 等，可做麦克风波形/频谱分析。

### 2.6 语音合成 TTS

来源：`skill: references/apis/ai.md`

| API | 能力 | 关键限制 |
|---|---|---|
| `speechSynthesis.speak(utterance, mode?)` | 直接合成并播放（运行时统一播放器排队） | `mode`: `'enqueue'`（默认）/ `'immediate'` |
| `speechSynthesis.synthesize(utterance, options?)` | 只生成不播放，返回 `SpeechSynthesisTask`（含音频块事件、可 abort，配 `SpeechAudioPlayer` 独立播放） | 选项：字幕粒度 `subtitles: 'none'/'sentence'/'word'`、音频格式 `pcm/mp3/ogg_opus`、采样率、声道、码率、`AbortSignal` |
| `SpeechSynthesisUtterance` | text/lang/voice/volume/pitch/rate | **`lang` 属性目前不生效**（文档明示不支持、不会改变生成语言）；pitch/rate/volume 默认 1 |
| 官方音色 ID（共 11 个） | `female-tianmei`、`English_radiant_girl`、`English_expressive_narrator`、`male-qn-qingse`、`male-qn-jingying`、`female-yujie`、`Chinese (Mandarin)_News_Anchor`、`Chinese (Mandarin)_Radio_Host`、`clever_boy`、`lovely_girl`、`English_Trustworthy_Man` | 无 `getVoices()`、无 `cancel()/pause()/resume()`（文档明示未暴露） |
| `wx.speech.playTTS(text)` | wx 风格一句话播报 | 返回字符串（请求 ID），失败返回空字符串 |

### 2.7 传感器（IMU）

来源：`skill: references/apis/device.md`、官方指南 https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md

| API | 数据 | 事件/说明 |
|---|---|---|
| `new Accelerometer({frequency?})` | 三轴加速度 `x/y/z` + `timestamp` | 事件 `activate`/`reading`/`error`；`frequency` 只是给主机的尽力提示（best-effort hint） |
| `new Gyroscope({frequency?})` | 三轴角速度 `x/y/z` + `timestamp` | 同上 |
| `new AbsoluteOrientationSensor({frequency?})` | 绝对朝向四元数 `quaternion`（[x,y,z,w]）+ `timestamp` | 可用性取决于设备硬件支持 |
| 采样率 | 官方指南示例用 60，建议从 30–60 Hz 起步按需调高 | 无官方公布的最高频率/精度数值 |

注：API 层只暴露以上三种传感器；没有单独的地磁/光感/接近传感器 API 出现在官方 API 参考中。

### 2.8 语音识别 ASR

来源：`skill: references/apis/ai.md`。**无独立的 `SPEECH_RECOGNITION` 权限**（文档明示已取消）；开麦克风仍需 `RECORD_AUDIO`。

| API | 能力 | 关键限制 |
|---|---|---|
| `new SpeechRecognition()` | 宿主麦克风识别：`lang`、`continuous`、`interimResults`、`maxAlternatives`；事件含 `result`/`nomatch`/`error` 等完整 Web Speech 风格事件集 | `start()` 要求所属视图保持交互态，非交互态立即 `InvalidStateError`；`lang` 为空时由宿主选默认语言 |
| `new SpeechRecognitionSession(options?)` | 外部音频流识别（自己用 MediaRecorder 喂音频块到 `session.audio` 写入流），会话本身不开麦克风 | 选项含热词 `phrases: [{phrase, boost}]`、分段 `segmentation: 'auto'/'vad'/'semantic'/{mode:'vad', silenceDurationMs}`、`updateContext(messages)` 动态上下文 |
| `SpeechRecognitionSession.getCapabilities()` | 查询宿主真实能力：音频格式/采样率、`maxChunkBytes`、是否支持 interim/热词/上下文/VAD 阈值范围 | 能力因宿主而异，必须先查再用 |

### 2.9 大语言模型 LLM

来源：`skill: references/apis/ai.md`

| API | 能力 | 关键限制 |
|---|---|---|
| `LanguageModel.availability()` | 返回 `'available'/'unavailable'` | **不暴露**供应商、模型列表、端点信息 |
| `LanguageModel.create({model?, initialPrompts?, tools?})` | 创建会话；模型解析顺序：显式 `model` → 宿主 `defaultModel` | 底层是宿主的 **OpenAI 兼容 chat-completions 流式通道**；`system` 只能出现在 initialPrompts 首条 |
| 多模态输入 | user 消息 content 数组支持 `{type:'text'}` 与 `{type:'image_url', image_url:{url}}`（含 data: URL） | 结构化 content 仅限 user 角色 |
| 工具调用 | `tools`（function 型）会被转发进供应商请求体；工具调用以会话 `toolcall` 事件形式回传（callId/functionName/arguments） | **不是**自动执行：JS 侧需自行处理事件，没有结构化 tool-call 往返协议保证 |
| `session.prompt(input)` / `promptStreaming(input)` | 一次性回答 / 流式回答（轮询式 `read()`，非 WHATWG Stream、非 async iterator） | 同一会话同时只允许一个进行中的请求；`destroy()` 后不可再用 |
| `wx.speech.startRecognition()` | wx 风格发起识别（字符串返回） | 与 2.8 是不同入口 |

### 2.10 定位（Geolocation）

来源：`skill: references/apis/geo/geolocation.md`。需声明 `GEOLOCATION` 权限（声明后系统仍可能拒绝）。

- `navigator.geolocation.getCurrentPosition(success, error?, options?)` / `watchPosition(...)`（返回数值型 watch ID，`clearWatch` 释放）。
- 选项：`enableHighAccuracy`（默认 false）、`timeout`、`maximumAge`（省略时由宿主定）。
- 结果：`coords` 含 `latitude`、`longitude`、`accuracy`（米），及可空的 `altitude`、`altitudeAccuracy`、`heading`、`speed`；错误码 1/2/3（拒绝/不可用/超时）。
- 附带 `GPXDocument` API（`'gpx'` 模块）：GPX 路线解析、创建、导出（setStartPoint/addWaypoint/appendTrackPoint/toString/toBlob），配合 `<map>` / `<map-gpx>` 组件做轨迹显示。来源：`skill: references/apis/geo/gpx-document.md`、`skill: references/components.md`

### 2.11 蓝牙 BLE（客户端）

来源：`skill: references/apis/device.md`

- `navigator.bluetooth`：`getAvailability()`、`getDevices()`、`requestDevice({acceptAllDevices?, optionalServices?, filters?:[{name?, services?}]})`、`scanDevices(options?)`（Ink 特有，非标准 Web Bluetooth）。
- GATT：`device.gatt.connect()/disconnect()/getPrimaryService(s)/…`，特征值 `readValue()`（返回 `Promise<number[]>`）、`writeValue(With/WithoutResponse)`、`startNotifications()` + `characteristicvaluechanged` 事件。
- 限制：`requestDevice`、`scanDevices`、`gatt.connect()`、`startNotifications()` 都要求所属视图保持**交互态**；`getAvailability/getDevices` 不受此限。角色是 BLE **中心设备（client）**；官方 API 参考中没有 BLE 外围（peripheral/广播）能力。

### 2.12 存储与文件

来源：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、`skill: references/apis/navigator.md`、`skill: references/framework.md`

- `localStorage`：当前智能体隔离的字符串 KV（getItem/setItem/removeItem/clear）。
- wx 存储：`wx.setStorage/getStorage/removeStorage/clearStorage` 及 `Sync` 同步版，数据经 JSON 序列化。
- `navigator.storage`：StorageManager，文档定义为 "Persistent file storage entry point"（持久文件存储入口）——⚠️ skill 参考未给出其方法细节（见第 5 节）。
- 文件模型：资源一律从**工程内路径**解析（如 `/assets/icon.png` 打包进.aix）；官方框架文档明确提醒**不要假设可任意访问设备文件系统**。官方 API 参考中不存在通用文件系统 API（无任意路径的读/写/列目录接口）。
- ⚠️ **FileReader 不存在（真机实证，2026-10-28，全局错误码 E2005）**：Ink 运行时没有 `FileReader`，aiui-dev 官方参考全文亦无此 API。`Blob → dataURL` 必须走 `blob.arrayBuffer()` + 分块 `btoa` 转码（或位图直存）；任何 `new FileReader()` / `readAsDataURL` 在真机必抛 `FileReader is not defined`，每帧必死。开发时以官方 API 参考清单为准：清单里没有的 API 就不存在，不要按浏览器习惯假设。

### 2.13 网络

来源：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、官方指南 https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md

- `fetch` / `Headers` / `Response`（含 `body` ReadableStream 流式读取、BYOB）、`WebSocket`、`File`/`FormData`、`URL`/`URLSearchParams`、Streams 全家桶（Readable/Writable/Transform）。
- `wx.request`（超时解析顺序：options.timeout → app.json 配置 → 默认 60000 ms）、`wx.createSocket/connectSocket`、`wx.createEventSource`（SSE）。
- `crypto`：`randomUUID`、`getRandomValues`（上限 65,536 字节）；`crypto.subtle` **仅** SHA-1/256/384/512 摘要与 HMAC（generateKey/importKey/exportKey/sign/verify）——加密/解密、RSA、ECDSA、JWK **不支持**。
- **手机代理上网（Mobile Proxy）**：眼镜未连 Wi-Fi 时，只要蓝牙连着手机 App（Rokid AI App / Hi Rokid），`fetch`/`wx.request` 会自动经手机链路转发上网，对开发者透明，且更省电。
- **HTTPS 强制**：线上环境网络请求必须 HTTPS；发布商店前请求域名需在开发者后台**报备白名单**。
- **局域网直连：不支持**（官方指南称"正在开发中"；文档目录中 LAN 一节标注 `status: unsupported`）。

### 2.14 Canvas 2D 与条码检测

来源：`skill: references/apis/canvas.md`

- `CanvasRenderingContext2D`：路径/矩形/文本（含 `measureText`）/变换/渐变/图案/图像数据/`drawImage`（仅 3/5/9 参数三种形式）等；入口为页面 `<canvas>`（`wx.createCanvasContext(id)`）或脚本自建 `new Canvas(w,h)`。
- 颜色解析受限：仅 `#rrggbb`、`#rgb`、`rgb()`、`rgba()` 与 black/white/red/green/blue/yellow/transparent 等少数命名色。
- 输出：`canvas.convertToBlob({type, quality})`（PNG 默认，JPEG 质量 0–1；透明像素在 JPEG 下合成到黑底）、全局 `createImageBlob()`。
- `BarcodeDetector`（`'barcode'` 模块或全局）：`getSupportedFormats()` 查支持的码制（规范名如 `qr_code`、`code_128`、`ean_13`）；`detect(image)` 接受 ImageData、编码图像 Blob 或 ImageBitmap，返回 `format`、`rawValue`、`boundingBox`、`cornerPoints`。不支持 OffscreenCanvas/VideoFrame/HTML 元素类输入。

### 2.15 交互事件（运行时层）

来源：`skill: references/events.md`。详见第 3 节交互模型。

- 模板事件：`bindtap`/`catchtap` 等 `bind<event>` 绑定；动画事件 `bindanimationstart/iteration/end/cancel`。
- 按键事件：Page 的 `onKeyDown/onKeyUp(event)`，按 `event.code` 分发（Rokid Glasses 映射见 3.2）。
- 语音唤醒回调：`onVoiceWakeup(event)`。
- 环境感知（需在 Page 内 `enableWorldAwareness()` 开启）：`onHeadGesture(event)`（示例手势值 `'nod'`）、`onOrientationStabilityChange(event)`（`event.stable` 头部稳定性）。
- 网络状态：App/Page `onNetworkStatus(event)`。

### 2.16 框架与组件面

来源：`skill: references/framework.md`、`skill: references/components.md`、`skill: references/apis/agent-worker.md`

- 工程结构：`app.json` + `app.js` + `AGENTS.md` + `pages/`（`.ink` 单文件或 `.json/.wxml/.wxss/.js` 四件套）+ 可选 `widgets/`、`workers/`、`components/`、`assets/`。
- 内置组件共 **37 个可编写标签**：容器/文本/表单（button/input/textarea/switch）/媒体（image/video/lottie-view）/地图（map、map-gpx）/画布与图表（canvas/chart）/AI 生成 UI（a2ui）等。
- Agent Worker：无界面脚本（open 触发，`lifetime: 'instant'|'foreground'`，`background` 保留且无效）；有定时器、Promise、Crypto、Wasm、编码流，但**没有** `window/document/fetch`、路由、渲染与媒体采集。
- TypeScript 入口与 WebAssembly 模块受支持（走工程打包流程）。

### 2.17 权限清单（app.json.permissions，精确名称）

来源（2026-10-29 全量审计订正）：`documentation/1-framework/open-agent-format/app-json.md` 权限表，共 **7 个**。名称**大小写敏感**，未识别的名称不授予任何能力；清单声明 ≠ 系统授权，调用处仍需处理拒绝。注：aiui-dev Skill 的 `references/framework.md` 仍只列前三个，属上游文档内部不一致，以 framework 文档为准。

| 权限名 | 用途 |
|---|---|
| `GEOLOCATION` | 获取当前位置 / 监听位置变化 |
| `CAMERA` | 访问摄像头、拍摄图像或视频 |
| `RECORD_AUDIO` | 访问麦克风、采集音频（ASR 开麦、录音均靠它；无独立 ASR 权限，旧 `SPEECH_RECOGNITION` 权限已于 Ink 0.19 移除） |
| `READ_MEDIA_IMAGES` | 列出和读取系统媒体库中的图片 |
| `CREATE_MEDIA_IMAGES` | 向系统媒体库新增图片（不含修改/覆盖已有资源） |
| `READ_MEDIA_AUDIO` | 列出和读取系统媒体库中的音频 |
| `CREATE_MEDIA_AUDIO` | 向系统媒体库新增音频（不含修改/覆盖已有资源） |

补充：提审环节（Studio/商店）另有**声明类勾选**——网络、摄像头、麦克风、扬声器、Rokid 账号信息等，需逐项填写用途，与清单权限是两套东西。来源：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md

---

## 3. 交互模型

### 3.1 唤醒

- 产品级唤醒词：**"Hi Rokid"**。
- 运行时 `onVoiceWakeup(event)`：语音或触控均可触发；已知 `event.keyword` 值包括 `乐奇`（中文唤醒词）、`Hi Rokid`、`clickAiAssist`（触控唤醒）。默认不要按 keyword 过滤；`event.preventDefault()` 可接管宿主默认动作。

### 3.2 镜腿触控与按键映射

运行时以**键事件**形式下发（`onKeyDown/onKeyUp` + `event.code`），Rokid Glasses 映射如下：

| `event.code` | 含义 | 默认行为（onKeyUp 后） |
|---|---|---|
| `Enter` | 确认/激活 | 进入导航模式或激活当前目标 |
| `Backspace` | 返回 | 回上一级；无页面可回时请求关闭智能体 |
| `ArrowUp` / `ArrowDown` | 上/下方向 | 在当前导航路径内移动或滚动根视图 |
| `GlobalHook` | **镜腿按键触摸**的设备专用信号（非标准 Web 键值） | 无默认动作；文档建议仅在 onKeyDown 做快速响应，要区分返回/确认应使用 Backspace/Enter |

产品侧补充：产品页称有 "Quick Action Shortcuts — Tap to launch the features you use most"（点按镜腿快速启动常用功能）与独立拍摄操作（"One word or one press" 拍照）。

### 3.2.1 镜腿触控板完整手势表（真机实证，Hi Rokid App「操作指南」）

来源：Hi Rokid App 内置操作指南（真机行为，以此为准；触控位置为镜腿中段）。这是 §3.2 键事件在产品层的完整映射——运行时里 `Enter`/`Backspace`/`ArrowUp/Down` 的来源就是这些手势。

**单指交互（通用）**

| 手势 | 系统行为 | 运行时对应 |
|---|---|---|
| 单击 | 确认 | `Enter` |
| 双击 | 返回 | `Backspace` |
| 长按触控板 | 唤醒助手（可在 App 里选「眼镜 AI 助手（默认）」或「手机助手」） | `onVoiceWakeup`（keyword `clickAiAssist`） |
| 滑动 | 正向滚动（方向可在 App 里改） | `ArrowUp` / `ArrowDown` |

**单指·场景化**：音乐——首页单击 = 无；音乐应用中单击 = 播放/暂停；向前/后滑 = 下一首/上一首。通话——来电中双击 = 拒接；通话中单击 = 禁麦/开麦；通话中双击 = 挂断。

**双指交互（双指张开触控镜腿中段）**

| 手势 | 系统行为 |
|---|---|
| 双击 | 息屏 |
| 长按 | **AI 快捷指令**：向选定的「触发对象」发送一条固定指令（见下） |
| 前后滑动 | 音量加减（默认，可改） |

**AI 快捷指令（双指长按）**：App 里可开关；指令可选预置（「看一下面前这是什么」「拍照翻译成中文」「今天天气」）或自定义文本（≤500 字）。关键点：**触发对象可以选某个具体的自定义/调试 Agent**——即双指长按 = 零 ASR、确定性地把一段固定文本投递给指定 Agent，是绕过语音唤醒误识别的硬件级入口（真机实测可用）。


### 3.3 "凝视"到底是什么：头部朝向，不是眼动追踪

**结论：AIUI 没有眼动追踪（eye tracking）API；所谓"凝视"由头部姿态实现。**

依据：
1. 官方 API 参考（skill 全部 apis 文件）中不存在任何眼动/视线坐标 API；全文检索无 eye-tracking 相关条目。
2. 指向能力由 IMU 提供：`AbsoluteOrientationSensor` 给出头部朝向四元数（2.7）。
3. 世界感知回调只有两个：`onHeadGesture(event)`（已文档化的手势值示例为 `'nod'` 点头）与 `onOrientationStabilityChange(event)`（头部稳定性变化）——即"看向某物并稳住头 → 触发"的交互范式靠的是**头稳检测**，官方示例正是 `event.gesture === 'nod'` 时确认。来源：`skill: references/events.md`
4. 产品页与文档从未宣称眼动追踪硬件；规格表传感器仅写 "IMU: Supported"。

因此：开发"凝视"类交互 = 头部朝向（四元数/方向）+ 头稳事件 + 点头确认。**摇头（shake）等其他手势值未在官方文档中列出**——`onHeadGesture` 的完整手势枚举官方未公布（见第 5 节）。

### 3.4 语音交互流


唤醒词/触控唤醒 → `onVoiceWakeup` → Agent 内可用 `SpeechRecognition`（宿主识别）或 `SpeechRecognitionSession`（自备音频流）做 ASR → `LanguageModel` 会话推理（可带图片输入）→ `speechSynthesis.speak/synthesize` 或 `AudioPlayer` 播报。对话流卡片（conversation-flow card）默认**仅展示**，交互式界面需全屏 Page 或 Widget（`skill: SKILL.md` Core Rules）。

### 3.5 手机伴侣 App 的角色


- 网络代理：眼镜无 Wi-Fi 时经蓝牙借手机 App（海外版 **Hi Rokid**，包名 `com.rokid.sprite.global.aiapp`）上网（2.13）。
- 设备管理与资源下发：连接/管理眼镜、调整设置、管理媒体、AI 功能入口（翻译/字幕/提词器/设备控制）——产品页 FAQ。
- Agent 分发链路：Studio 打包上传云端 → App 更新眼镜资源包 → 眼镜端运行（本项目既定流程；官方指南的发布流程为"构建 → 网页模拟 → AIX 打包上传云端 → 真机调试"，来源：publish.md）。

---

## 4. 平台限制与约束（开发者视角）

### 4.1 显示/UI 约束

- 单一绿色通道：所有可见像素只是同一绿色的不同亮度（基色 `#40ff5e`，6 级亮度阶梯）；**黑色 = 透明底**，不能指望不透明黑面板遮挡现实环境。
- 语义不能只靠颜色：状态/严重程度必须叠加图标、文字标签、线型或动效等冗余编码。
- 参考画布 480 × 352，关键信息须落在中央舒适视野内；正文文本亮度建议 ≥72%，装饰线 ≤24%。

### 4.2.aix 包约束

- AIX = "AI eXecutable"，AIUI 定义的专有分发格式，内部遵循 OAF（Open Agent Format）规范，自包含代码（WXML/WXSS/JS）、配置（JSON）与静态资源。
- 打包时自动生成唯一 UUID 的 `VERSION` 文件用于版本校验/热更新；打包支持 PNG/JPEG 压缩与 JSON 混淆压缩。
- **包大小上限：官方未公布**（所查文档无数值）。
- 工程侧红线：`.aixignore` 必须排除 `.agents/`、`.aix/`、`artifacts/`、`*.aix`、`skills-lock.json`、`node_modules/`，否则开发文件会进包（实测 2.3 KB → 107 KB）。来源：本项目根 README（仓库 sakai55/rokid）。

### 4.3 AIUI 明确不暴露 / 不支持的能力

| 能力 | 状态 | 依据 |
|---|---|---|
| **OCR（文字识别）API** | **不存在** | 官方 API 参考全量清单（skill apis 目录）与官方文档目录中均无 OCR 条目；"读文字"的官方路径是 telephoto 拍照 + LLM 图片输入（2.3 / 2.9） |
| 眼动追踪 | 不存在 | 见 3.3 |
| 局域网直连通信 | 不支持（开发中） | 官方网络指南 + 文档目录 `lan: status unsupported` |
| 数据预拉取 prefetch | 不支持 | 文档目录 `prefetch: status unsupported` |
| Source map 调试 | 不支持 | 文档目录 `sourcemap: status unsupported` |
| WXML `<template>` | 不支持 | 文档目录标注 unsupported |
| Agent Worker 后台常驻 | 不支持 | `lifetime: 'background'` 保留且无效；Worker 也无 fetch |
| Web Crypto 加密算法 | 仅 SHA 摘要 + HMAC | `skill: references/apis/web.md` 明示 RSA/ECDSA/加密解密/JWK 不支持 |
| TTS 语言切换 | `lang` 属性不生效 | `skill: references/apis/ai.md` 明示 |
| TTS 队列控制 | 无 cancel/pause/resume/getVoices | 同上 |
| 通用文件系统 | 无任意路径文件 API | 2.12 |
| 设备序列号/令牌 | 仅系统级智能体 | 2.1 |
| LLM 供应商信息 | availability() 不给 | 2.9 |

### 4.4 提审/发布约束

> 注意：该官方文档描述的是发布到 **Rokid Ai 智能体商店（中国大陆）** 的流程；Global 版走 Global AIUI Studio 的 Submit 页签，要求大体一致（本项目实测）。

- 名称：必填，≤20 字符，不得与他人重名，不得含"测试/test/beta"、价格促销、极限词；文案禁用"官方/权威/推荐/TOP1"等暗示词与"100% 准确"类绝对化承诺。
- 图标：必填且**不得使用默认图标**，不得模糊/拉伸/带水印二维码/纯色+文字。
- 功能介绍 ≤500 字符；开场白必填、建议 ≤300 字；版本号与 Agent ID 均由系统生成、开发者不可编辑。
- 权限：如实勾选实际使用的全部权限并逐项写明用途，遵循"最小必要 + 用途真实"；未声明却调用、描述模糊、与代码行为不一致都可能被拒。
- 预览素材：必填 **3–5 个文件**，至少 1 张图片 + 1 个视频；图片 JPG/PNG（建议 1:1），视频 MP4（建议 1:1）、时长 ≤60 秒（建议 15–45 秒）、单文件建议 ≤50 MB；视频须完整演示 1–2 个核心流程。
- 内容安全：UGC 需安全过滤；AI 生成合成内容需依法添加标识；智能体必须能正常启动、交互、返回，不得频繁崩溃。
- 流程：构建 → 网页模拟 → AIX 打包上传云端 → 真机调试 → 完善提审资料 → 提交审核 → 结果（拒绝则改后重新打包再交；通过后上架商店）。

### 4.5 运行时与交互门约束

- **交互门（interactive gate）**：BLE 的 requestDevice/scanDevices/connect/startNotifications、SpeechRecognition.start、RecorderManager.start、CameraContext.takePhoto、getUserMedia 采集等都要求所属视图处于交互态，通常还需由用户交互触发；非交互态调用直接抛错/失败。
- 资源生命周期：麦克风/相机 track 用完必须 stop；BLE 扫描要停、GATT 要断；watchPosition 要 clearWatch；AudioContext 要 close。官方 checklist 把这些列为交付红线（`skill: references/checklist.md`）。
- 模拟器 ≠ 真机：DevTools 中传感器多为模拟值、性能/发热/降频与真机不同，官方要求以真机为准（env.md）。

---

## 5. 矛盾与未明事项

1. **显示分辨率口径不一致**：官方产品规格表写 **480 × 400**；AIUI 设计规范与 Widget 尺寸族按 **480 × 352** 参考画布（1x2 Widget 宽 480 也与此一致）。两者都是官方来源——推测 480×400 为面板物理分辨率、480×352 为运行时安全画布，但官方未作此说明。
2. **FOV 的第三方说法**：非官方评测（Notebookcheck 等）称 23°，官方产品页为 **30°**。以官方为准，23° 标记为**未经官方证实**。
3. **显示分辨率的第三方说法**：个别非官方评测称 640×480，与官方 480×400 不符，**未经官方证实**。
4. **续航口径多套**：官方同一产品页内 FAQ 写 8–10 小时日常使用、对比表写 6 小时混合使用 / 配盒 30 小时；未给出统一测试条件下的标称值。
5. **第二颗芯片**：产品页有 "Dual-Chip Performance" 宣传语，但官方规格表 SoC 只列 Snapdragon AR1；第二芯片型号（如第三方所称 NXP RT600）**官方规格页未证实**。
6. **摄像头细节缺失**：传感器型号（营销文案称 Sony、规格表未写型号）、摄像头 FOV（第三方称 109°）均**官方未公布**。
7. **IMU 细节缺失**：产品页仅 "IMU: Supported"；轴数、型号、采样率上限、精度均未公布；API 侧 frequency 只是 best-effort 提示，无保证值。
8. **头部手势枚举未公布**：`onHeadGesture` 官方示例只给出 `'nod'`；摇头、抬头等其他手势值是否存在、叫什么，官方文档未列全。
9. **`navigator.getBattery()` 文档悬空引用**：navigator 参考称电量方法见 device 参考，但 device 参考中并无 BatteryManager 章节——API 存在性以 navigator 参考为准，细节（属性/事件）未在 skill 中给出。
10. **`navigator.storage`（StorageManager）细节缺失**：navigator 参考只给了一句 "Persistent file storage entry point"，无方法签名；其与 localStorage/wx 存储的边界未在 skill 中说明。
11. **设备代际差异未验证**：events 参考明示 **Rokid Glasses 2** 与**第一代全彩眼镜**的按键映射"remain unverified"，不得套用 Rokid Glasses（一代单色绿）的映射；设计规范目标设备写作 RokidGlasses1 / RokidGlasses2。
12. **文档版本双轨**：官方文档现有两个站点——open.rokid.com/aiui（当前版）与 js.rokid.com（较早版本，AI 开发指南位于 /AIUI/guide/quickstart/ai-dev）；本档案的 API 契约以官方仓库当前 `documentation/` 与 `skills/aiui-dev` 为准，两站内容差异未逐页比对。
13. **OS 未公布**：眼镜操作系统名称/版本在官方产品页与文档中均未标注（仅知运行时为 Ink/QuickJS+Skia 容器）。
14. **.aix 包大小上限未公布**；域名白名单的报备入口/审核时效亦未在公开文档中细化。

---

## 6. 官方来源清单

**产品与平台**
- Rokid Glasses 官方全球产品页（规格主来源）：https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid 英国官方站 AI 产品线（规格互证）：https://gb.rokid.com/collections/rokid-ai-lineup
- 官方 Academy 教程《3.6 Glasses AIUI》（Craft/Studio 工作流）：https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**官方文档站**
- AIUI 文档（当前版）：https://open.rokid.com/aiui
- AIUI 文档（较早版本）：https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**官方 GitHub 仓库 yodaos-project/AIUI（jsar-project/AIUI 会重定向至此）**
- 仓库首页/README（定位、Samples 索引）：https://github.com/yodaos-project/AIUI
- Samples 目录（bluetooth / capabilities / cut-card / games / gyroscope-test / meal-card / navigator-info / realtime-voice-intelligence / scanner / tts）：https://github.com/yodaos-project/AIUI/tree/main/samples
- aiui-dev skill（本档案 API 契约的主来源）：https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- 提审与发布：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- 什么是 AIX：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- 运行环境：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU 指南：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- 网络使用说明（手机代理 / HTTPS / 域名白名单 / 局域网）：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- 文档目录（含 lan/prefetch/sourcemap 等 unsupported 标注）：https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json
