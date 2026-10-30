> 归档快照：能力原子注册表 v2.1.0，已被 v2.2.0 取代。现行版见 docs/CAPABILITIES.md。

# Rokid Glasses 能力原子注册表

中文 | [English](CAPABILITIES-v2.1.0.en.md) | [日本語](CAPABILITIES-v2.1.0.ja.md)

> 编制日期：2026-10-24；当前版本 v2.1.0，2026-10-30
> 资料原则：**只采用 Rokid 官方来源**（官方产品页、官方文档站、官方 GitHub 仓库 `yodaos-project/AIUI` 及其内置的 `aiui-dev` skill 参考），外加本注册表维护者自己的真机与构建实测，实测结论在条目里单独标明。官方仓库 `skills/aiui-dev` 是 API 契约的主来源，下文依据写作 `skill: references/…`。

## 写在前面

本注册表由一名 Rokid AIUI 开发者维护，不是 Rokid 官方文件。它把 Rokid Glasses 底座的能力拆成原子条目：一个条目只说一件底座原语，有稳定编号、一句结论、官方依据与实测状态。设计一个 Agent 之前，先在这里查它要用的原语在不在、边界在哪。

本表只登记原语，不登记应用场景。场景是原语的组合，写法无穷无尽，逐条收录会变成没有尽头的问答集；任何场景问题都用同一条路回答：把场景拆成所需的原语，逐个查本表——原语在，组合就成立；原语不在，答案就是做不了，不需要为这个问题单开一条。官方 API 参考本身是封闭清单，清单里没有的 API 就不存在，这是本表多数字段的判定基础。

维护方式与错误码表 `ERROR-CODES.md` 同构：条目只在段尾追加、编号永不复用，结论被推翻的条目改结论并在变更日志里留痕，不删号；结论有变化时升版本号，旧版归档在 `base/capabilities/` 并附索引。中文版为权威版，英日版为译文，冲突时以中文版为准。

## 1. 编号与治理

编号形如 `C2003`：字母 C 加四位数字，千位是段号，段内顺序编号。

| 段 | 域 |
|---|---|
| C1xxx | 硬件与显示 |
| C2xxx | 摄像头与图像 |
| C3xxx | 音频、语音与大模型 |
| C4xxx | 传感器与定位 |
| C5xxx | 显示运行时与页面 |
| C6xxx | 存储、文件与网络 |
| C7xxx | 权限 |
| C8xxx | 交互与宿主 |
| C9xxx | 分发与提审 |

实测状态只用四种取值：**文档**——只有官方文档依据，未在真机验过；**真机已证**——有真机返回的结果或行为证据；**构建实测 / Studio 实测**——在打包或 Studio 流程里验过；**待验**——已有探针，数据未回，探针见第 4 节。版本号规则：新增条目或条目结论变化升 MINOR，结构或规则变化升 MAJOR，文字修正升 PATCH。

## 2. 总则

总则不是条目，是推导场景答案时与条目同等适用的规则。

- **R1 闭环定位**（官方口径，2026-10-29）：Agent 本质上完成闭环——一个 Agent 靠自身声明的权限与可调用的 API，在自己内部把一件事从进入做到结果；闭环之外的宿主能力，包括系统设置、其他 Agent 与宿主配置，不向 Agent 下放。来源：官方回复，经本注册表维护者转述。
- **R2 清单即边界**：官方 API 参考是封闭清单。查不到的 API、参数与枚举值一律按不存在处理，不按浏览器或微信小程序的习惯假设。
- **R3 交互门**：采集与连接类调用（拍照、录音、ASR 启动、BLE 连接等）要求所属视图处于交互态，通常还要由用户交互触发；非交互态调用直接失败。资源用完必须释放：麦克风与相机 track 要 stop、BLE 扫描与连接要断、watchPosition 要 clearWatch、AudioContext 要 close。
- **R4 声明不等于授权**：权限写进 app.json 只是声明，系统在调用处仍可拒绝，代码必须处理拒绝分支。
- **R5 模拟器不等于真机**：网页模拟器里传感器多为模拟值，性能与发热与真机不同；条目的实测状态标「文档」的，结论以真机复测为准。

## 3. 条目

### 3.1 硬件与显示

依据：官方全球产品页 https://global.rokid.com/products/b-h-rokid-glasses-with-display ，英国官方站同参数互证。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C1001 | 主芯片 | Snapdragon AR1。产品页另有「双芯片」宣传语，但官方规格表未列第二颗芯片型号 | 文档 |
| C1002 | 内存与存储 | 2 GB / 32 GB | 文档 |
| C1003 | 显示技术 | 双目 Micro LED 加衍射光波导 | 文档 |
| C1004 | 显示颜色 | 单色绿，单一绿色发光通道，不是全彩 | 文档 |
| C1005 | 面板分辨率 | 480 × 400，产品规格口径；与运行时画布 C5002 口径并存，见未明第 1 条 | 文档 |
| C1006 | 视场角 | 30° | 文档 |
| C1007 | 亮度 | 1500 nits | 文档 |
| C1008 | 摄像头硬件 | 12 MP，照片 3024 × 4032，F2.25；传感器型号与摄像头视场角官方未公布 | 文档 |
| C1009 | 麦克风硬件 | 4 麦克风阵列 | 文档 |
| C1010 | 扬声器 | 双线性定向高保真扬声器 | 文档 |
| C1011 | 电池与充电 | 210 mAh；续航官方口径多套，见未明第 3 条；磁吸充电，20 分钟充至 80%，充电盒可充满约 10 次 | 文档 |
| C1012 | 无线连接 | Wi-Fi 6、蓝牙 5.3 | 文档 |
| C1013 | 整机参数 | 49 g，IPX4；镜腿长 155.5 mm，铰链间距 146.3 mm，镜框 TR90 加钛合金铰链 | 文档 |
| C1014 | 配镜 | 支持屈光度 +15 至 −15，官方配镜服务与磁吸配镜框 | 文档 |
| C1015 | 摄像头指示灯 | 支持，拍摄时有指示 | 文档 |
| C1016 | 操作系统 | 名称与版本官方未公布；已知运行时为 Ink 容器，见 C5001 | 文档 |
| C1017 | 产品级整机功能 | 实时翻译 89 种语言、AI 助手、通知、导航、提词器、笔记、会议转录等是眼镜系统与官方 App 的功能，不是 Agent 可调用的 API；Agent 能用的只有本表登记的原语 | 文档 |

### 3.2 摄像头与图像

依据：`skill: references/apis/media.md`、`skill: references/apis/wx.md`；需权限 C7002。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C2001 | 视频流 getUserMedia | 可取 MediaStream；约束支持 facingMode、width、height、frameRate、deviceId，最终值读 track 的 getSettings | 文档 |
| C2002 | 拍照 ImageCapture.takePhoto | 返回编码后的 Blob；三种模式：wide 条码扫描用广角、telephoto 读远处文字、default 普通拍照；另有 quality、enableSystemPreview 选项 | 文档 |
| C2003 | 拍照输出尺寸 | wide 2016 × 2688、telephoto 2016 × 1512、default 3024 × 4032；Blob 本身不带宽高，需 createImageBitmap 解码 | 文档 |
| C2004 | 取帧 ImageCapture.grabFrame | 返回未编码的 ImageBitmap 像素帧，用后需 close | 文档 |
| C2005 | wx 拍照 CameraContext.takePhoto | 返回 ArrayBuffer 加 mimeType；没有模式选择参数，模式走 C2002；必须在交互门调用点触发 | 文档 |
| C2006 | 录像 MediaRecorder | 录制音视频流；视频 mime 以 isTypeSupported 查询为准，已知 video/webm;codecs=vp8,opus 与 video/mp4 | 文档 |
| C2007 | 条码检测 BarcodeDetector | 支持的码制先用 getSupportedFormats 查；detect 输入限 ImageData、编码图像 Blob 或 ImageBitmap，返回 format、rawValue、boundingBox、cornerPoints | 文档 |
| C2008 | OCR 接口 | 不存在。读文字的路径是 telephoto 拍照加图片输入大模型，见 C3016 | 文档 |
| C2009 | 持续帧流 | 文档未给出持续取帧的频率上限与后台行为；getUserMedia 流与 grabFrame 的持续可用性待探针验证，见第 4 节 | 待验 |
| C2010 | 文字与人脸检测 | TextDetector、FaceDetector 不存在，官方清单无此条目 | 文档 |

### 3.3 音频、语音与大模型

依据：`skill: references/apis/media.md`、`skill: references/apis/ai.md`；录音需权限 C7003。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C3001 | 录音来源 captureSource | microphone 麦克风或 system-audio 系统声音内录；system-audio 不能与 echoCancellation 或 microphoneMode 组合，否则 OverconstrainedError；系统声音不自动回退到麦克风 | 文档 |
| C3002 | 麦克风模式 microphoneMode | 四种：wearer 佩戴者优先、far-field 远场、near-field 近场、omnidirectional 全向；仅对 getUserMedia 采集流有效，设备支持不保证，不支持报 OverconstrainedError，实际生效值读 getSettings | 文档 |
| C3003 | 麦克风模式与宿主识别的关系 | 模式只作用于自采流，不作用于宿主语音识别；宿主识别用宿主麦克风，与模式设置无关 | 文档 |
| C3004 | 录音编码 MediaRecorder | 音频支持 audio/wav、audio/ogg;codecs=opus | 文档 |
| C3005 | wx 录音 RecorderManager | start、pause、resume、stop 与帧回调；用默认麦克风，没有来源与模式选择参数，要选模式用 C3001、C3002 | 文档 |
| C3006 | 语音合成 speechSynthesis.speak | 直接合成并播放，走运行时统一播放器排队；mode 为 enqueue 默认或 immediate | 文档 |
| C3007 | 语音合成 speechSynthesis.synthesize | 只生成不播放，返回可 abort 的任务；选项含字幕粒度 none、sentence、word，音频格式 pcm、mp3、ogg_opus，采样率、声道、码率；配 SpeechAudioPlayer 独立播放 | 文档 |
| C3008 | 合成音色 | 共 11 个固定音色 ID：female-tianmei、English_radiant_girl、English_expressive_narrator、male-qn-qingse、male-qn-jingying、female-yujie、Chinese (Mandarin)_News_Anchor、Chinese (Mandarin)_Radio_Host、clever_boy、lovely_girl、English_Trustworthy_Man；没有 getVoices | 文档 |
| C3009 | 合成控制面 | utterance 的 lang 属性不生效，不改变生成语言；没有 cancel、pause、resume；pitch、rate、volume 默认 1 | 文档 |
| C3010 | wx 播报 wx.speech.playTTS | 一句话播报，返回请求 ID 字符串，失败返回空字符串 | 文档 |
| C3011 | 语音识别 SpeechRecognition | 宿主麦克风识别；属性 lang、continuous、interimResults、maxAlternatives；start 要求视图保持交互态，否则 InvalidStateError；lang 为空时宿主选默认语言 | 文档 |
| C3012 | 语音识别 SpeechRecognitionSession | 外部音频流识别，会话本身不开麦克风；支持热词 phrases 加 boost、分段 auto、vad、semantic、updateContext 动态上下文；用前先 getCapabilities 查宿主真实能力 | 文档 |
| C3013 | 识别错误类别 | error 事件的错误类别取值，官方没有给出枚举表；按类别细分错误处理属于未证假设，不可依赖 | 文档 |
| C3014 | 大模型可用性 LanguageModel.availability | 只返回 available 或 unavailable，不暴露供应商、模型列表与端点 | 文档 |
| C3015 | 大模型会话 LanguageModel.create | 底层是宿主的 OpenAI 兼容 chat-completions 流式通道；模型解析顺序为显式 model、宿主 defaultModel；system 只能出现在 initialPrompts 首条 | 文档 |
| C3016 | 大模型多模态输入 | user 消息 content 数组支持 text 与 image_url，图片可为 data: URL；结构化 content 仅限 user 角色 | 文档 |
| C3017 | 大模型工具调用 | tools 会转发进供应商请求体；调用以会话 toolcall 事件回传，含 callId、functionName、arguments；不自动执行，没有结构化往返协议保证 | 文档 |
| C3018 | 大模型请求 prompt 与 promptStreaming | 流式为轮询式 read，不是 WHATWG Stream 也不是 async iterator；同一会话同时只允许一个进行中的请求；destroy 后不可再用 | 文档 |
| C3019 | 音频播放 AudioPlayer | 通用播放器，本地包内文件或网络 URL；支持 pcm、ogg_opus 流式 append 播放与字幕文本轨 | 文档 |
| C3020 | 音效 Sound | 本地音效短播放，仅本地文件，拒绝 http 与 https 的 URL | 文档 |
| C3021 | Web Audio | AudioContext 与 createBuffer、Oscillator、Gain、BiquadFilter、Analyser、MediaStreamSource、decodeAudioData 等可用，可做波形与频谱分析 | 文档 |

### 3.4 传感器与定位

依据：`skill: references/apis/device.md`、`skill: references/apis/geo/geolocation.md`、官方 IMU 指南；定位需权限 C7001。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C4001 | 加速度计 Accelerometer | 三轴加速度 x、y、z 加 timestamp；事件 activate、reading、error；构造参数 frequency 只是给主机的尽力提示 | 文档 |
| C4002 | 陀螺仪 Gyroscope | 三轴角速度 x、y、z 加 timestamp；事件与 frequency 语义同 C4001 | 文档 |
| C4003 | 绝对朝向 AbsoluteOrientationSensor | 绝对朝向四元数 quaternion [x, y, z, w] 加 timestamp；可用性取决于设备硬件支持 | 文档 |
| C4004 | 采样率保证 | 无官方公布的最高频率与精度数值；官方指南示例用 60，建议 30 至 60 Hz 起步 | 文档 |
| C4005 | 其他传感器接口 | 地磁、光感、接近传感器没有单独 API，未出现在官方清单 | 文档 |
| C4006 | 头部手势 onHeadGesture | 需在 Page 内 enableWorldAwareness 开启；官方示例手势值只有 nod 点头，完整枚举未公布，见未明第 7 条 | 文档 |
| C4007 | 头稳事件 onOrientationStabilityChange | 同需开启世界感知；event.stable 表示头部稳定性变化 | 文档 |
| C4008 | 眼动追踪 | 不存在。所谓凝视由头部朝向 C4003 加头稳 C4007 加点头 C4006 实现 | 文档 |
| C4009 | 定位 geolocation | getCurrentPosition 与 watchPosition，clearWatch 释放；coords 含 latitude、longitude、accuracy（米）及可空的 altitude、altitudeAccuracy、heading、speed；选项 enableHighAccuracy 默认 false、timeout、maximumAge；错误码 1 拒绝、2 不可用、3 超时 | 文档 |
| C4010 | GPX GPXDocument | GPX 路线解析、创建与导出：setStartPoint、addWaypoint、appendTrackPoint、toString、toBlob；配合 map 与 map-gpx 组件显示轨迹 | 文档 |
| C4011 | 蓝牙 BLE | 中心设备角色：getAvailability、getDevices、requestDevice、scanDevices（Ink 特有）、GATT connect、readValue、writeValue、startNotifications；requestDevice、scanDevices、connect、startNotifications 要求视图交互态 | 文档 |
| C4012 | 蓝牙外围与广播 | 不存在，官方清单无 peripheral 能力 | 文档 |

### 3.5 显示运行时与页面

依据：`skill: references/framework.md`、`skill: references/apis/window.md`、`skill: references/apis/canvas.md`、`skill: references/events.md`、官方运行环境文档。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C5001 | 运行时 Ink | 逻辑层与视图层运行在 QuickJS 加 Skia 的自研容器 Ink 中；ES2023、ESM | 文档 |
| C5002 | 参考画布 | 全屏 Page 参考画布 480 × 352；安全边距左右 16 px、上下 12 px，有效内容宽 448 px | 文档 |
| C5003 | 单色绿设计约束 | 基色 #40ff5e，6 级亮度阶梯；黑色等于透明底，不能指望不透明黑面板遮挡现实；语义不能只靠颜色，须叠加图标、文字或线型；正文亮度建议不低于 72%，装饰线不高于 24%，关键信息落在中央舒适视野 | 文档 |
| C5004 | 视口尺寸 | window.innerWidth、innerHeight 只读逻辑像素 | 文档 |
| C5005 | Widget 尺寸 | 尺寸族 1x1 为 239 × 140、1x2 为 480 × 140；眼镜共 4 个 Widget 网格位；family 只是尺寸类别，禁止把根节点写死为该像素值 | 文档 |
| C5006 | 打开界面 window.open | 只能打开 app.json 已声明的 Widget，唯一 target 为 _widget，支持 overlay 浮层；不能打开其他 Page 或外部 URL | 文档 |
| C5007 | 关闭实例 window.close | 请求宿主关闭当前智能体实例 | 文档 |
| C5008 | 跨 Agent 跳转 | 不存在：官方清单无 openAgent 类条目，wx.navigateTo 仅限本 Agent 内页面，见总则 R1 | 文档 |
| C5009 | 打开宿主设置页 | 不可达：没有此 API，「打开某某设置」类意图由宿主执行到打开应用本身为止，见总则 R1 | 文档 |
| C5010 | 工程结构 | app.json 加 app.js 加 AGENTS.md 加 pages；页面为 .ink 单文件或 .json、.wxml、.wxss、.js 四件套；可选 widgets、workers、components、assets | 文档 |
| C5011 | 内置组件 | 共 37 个可编写标签，含容器、文本、表单、媒体、地图、画布、图表与 AI 生成 UI 的 a2ui | 文档 |
| C5012 | Agent Worker | 无界面脚本，open 触发；lifetime 为 instant 或 foreground，background 保留且无效；有定时器、Promise、Crypto、Wasm、编码流；没有 window、document、fetch、路由、渲染与媒体采集 | 文档 |
| C5013 | 语言与模块 | TypeScript 入口与 WebAssembly 模块受支持，走工程打包流程 | 文档 |
| C5014 | Canvas 2D | 路径、矩形、文本含 measureText、变换、渐变、图案、drawImage 仅 3、5、9 参数三种形式；颜色解析仅 #rrggbb、#rgb、rgb、rgba 与少数命名色；输出走 convertToBlob 与 createImageBlob，canvas.toDataURL 不存在 | 文档 |
| C5015 | WXML 模板 | template 不支持 | 文档 |
| C5016 | 对话流卡片 | 默认仅展示；交互式界面需全屏 Page 或 Widget | 文档 |
| C5017 | 设备信息 navigator | id 为与智能体加设备绑定的不透明 ID，不得当作凭据；userAgent 与 versions.ink、versions.skia 给版本字符串；language、languages、region 可能为空；onLine 与 connection 给在线状态与连接估计值；renderingEnabled 表示当前实例能否渲染 | 文档 |
| C5018 | 电池 getBattery | 返回 Promise 的 BatteryManager；主机无电池能力时 Promise 被拒；细节文档不全，见未明第 8 条 | 文档 |
| C5019 | 序列号与令牌 | getDeviceSerialNumber 与 requestDeviceToken 仅系统级智能体可用，普通智能体返回空字符串或不得依赖 | 文档 |
| C5020 | 全局编码工具 | window.atob、btoa 与全局 createImageBlob 可用，createImageBlob 做 PNG、JPEG 编码 | 文档 |

### 3.6 存储、文件与网络

依据：`skill: references/apis/web.md`、`skill: references/apis/wx.md`、官方网络指南。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C6001 | 本地存储 localStorage | 当前智能体隔离的字符串 KV：getItem、setItem、removeItem、clear | 文档 |
| C6002 | wx 存储 | setStorage、getStorage、removeStorage、clearStorage 及 Sync 同步版，数据经 JSON 序列化 | 文档 |
| C6003 | OPFS navigator.storage | 每个 Agent 私有的文件存储，与 localStorage、wx 存储相互独立：estimate 查当前用量与配额，配额是运行时值、官方未公布数字；persisted 查持久化状态，persist 申请持久化，getDirectory 取根目录；文件经 createWritable 写入、close 后提交；宿主未提供 OPFS 后端时以 NotSupportedError 失败；当前是实用子集，不是完整 File System Access API。依据为官方 documentation 的 OPFS 专页 | 文档 |
| C6004 | 通用文件系统 | 不存在：资源一律从工程内路径解析，没有任意路径的读、写、列目录接口 | 文档 |
| C6005 | FileReader | 不存在，真机必抛 FileReader is not defined；Blob 转 dataURL 走 blob.arrayBuffer 加分块 btoa；关联错误码 E2005 | 真机已证 |
| C6006 | 查无的浏览器 API | 以下在 Ink 运行时均不存在，写进代码即错：sessionStorage、XMLHttpRequest、URL.createObjectURL、DOMParser、structuredClone、queueMicrotask、Notification、剪贴板 API、IntersectionObserver、MutationObserver、ServiceWorker、new Worker、OffscreenCanvas、getDisplayMedia、applyConstraints、getVoices、navigator.permissions | 文档 |
| C6007 | fetch 与 Web 设施 | fetch、Headers、Response 含 body 流式读取、WebSocket、File、FormData、URL 与 URLSearchParams、Streams 全家桶可用 | 文档 |
| C6008 | wx 网络 | wx.request 超时解析顺序为 options.timeout、app.json 配置、默认 60000 ms；wx.createSocket、connectSocket；wx.createEventSource 做 SSE | 文档 |
| C6009 | Web Crypto | randomUUID、getRandomValues 上限 65536 字节可用；subtle 仅 SHA-1、256、384、512 摘要与 HMAC；加密、解密、RSA、ECDSA、JWK 不支持 | 文档 |
| C6010 | 手机代理上网 | 眼镜未连 Wi-Fi 时，只要蓝牙连着手机 App，fetch 与 wx.request 自动经手机链路转发上网，对开发者透明 | 文档 |
| C6011 | HTTPS 与域名白名单 | 线上环境网络请求必须 HTTPS；发布商店前，请求域名需在开发者后台报备白名单 | 文档 |
| C6012 | 局域网直连 | 不支持，官方指南称开发中，文档目录标注 unsupported | 文档 |
| C6013 | 数据预拉取 | prefetch 不支持 | 文档 |
| C6014 | Source map 调试 | 不支持 | 文档 |

### 3.7 权限

依据：官方 framework 文档 app-json.md 权限表，2026-10-29 全量审计订正。共 7 个，名称大小写敏感，未识别的名称不授予任何能力；另注意 C7008 的上游不一致。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C7001 | 权限 GEOLOCATION | 获取当前位置与监听位置变化，见 C4009 | 文档 |
| C7002 | 权限 CAMERA | 访问摄像头、拍摄图像或视频，见 3.2 节 | 文档 |
| C7003 | 权限 RECORD_AUDIO | 访问麦克风与采集音频；ASR 开麦也靠它，没有独立的 ASR 权限，旧 SPEECH_RECOGNITION 已于 Ink 0.19 移除 | 文档 |
| C7004 | 权限 READ_MEDIA_IMAGES | 列出和读取系统媒体库中的图片 | 文档 |
| C7005 | 权限 CREATE_MEDIA_IMAGES | 向系统媒体库新增图片，不含修改与覆盖已有资源 | 文档 |
| C7006 | 权限 READ_MEDIA_AUDIO | 列出和读取系统媒体库中的音频 | 文档 |
| C7007 | 权限 CREATE_MEDIA_AUDIO | 向系统媒体库新增音频，不含修改与覆盖已有资源 | 文档 |
| C7008 | 权限清单的文档口径 | aiui-dev skill 的 framework 参考仍只列前三个权限，属上游文档内部不一致；以 framework 正式文档的七名为准 | 文档 |

### 3.8 交互与宿主

依据：`skill: references/events.md`、Hi Rokid App 内置操作指南（手势部分，真机行为以此为准）。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C8001 | 唤醒 onVoiceWakeup | 语音或触控均可触发；event.keyword 已知值：乐奇、Hi Rokid、clickAiAssist 触控唤醒；默认不要按 keyword 过滤；event.preventDefault 可接管宿主默认动作 | 文档 |
| C8002 | 按键事件 | Page 的 onKeyDown、onKeyUp 按 event.code 分发：Enter 确认、Backspace 返回、ArrowUp 与 ArrowDown 滚动、GlobalHook 为镜腿触摸的设备专用信号；宿主默认动作在 onKeyUp 后触发 | 文档 |
| C8003 | 单指单击 | 确认，对应 Enter | 文档 |
| C8004 | 单指双击 | 返回，对应 Backspace；无页面可回时请求关闭智能体 | 文档 |
| C8005 | 单指滑动 | 滚动，对应 ArrowUp、ArrowDown；滚动方向可在 App 里改 | 文档 |
| C8006 | 单指长按 | 唤醒助手；App 里可选眼镜 AI 助手或手机助手 | 文档 |
| C8007 | 双指双击 | 息屏 | 文档 |
| C8008 | 双指前后滑动 | 音量加减，默认如此，可在 App 里改 | 文档 |
| C8009 | 双指长按 AI 快捷指令 | 向选定的触发对象发送一条固定指令，文本上限 500 字；触发对象可以选某个具体的自定义或调试 Agent，即零 ASR、确定性地把固定文本投递给指定 Agent | 真机已证 |
| C8010 | 场景化手势 | 音乐场景：单击播放或暂停、前后滑切歌；通话场景：来电双击拒接、通话中单击禁麦或开麦、双击挂断 | 文档 |
| C8011 | 仅绑定点击的按钮 | 只绑 bindtap 的按钮在眼镜上无法被手势触发；页面必须自己把按键映射到动作，不能只依赖按钮点击 | 真机已证 |
| C8012 | 语音唤醒的失败层 | 固定句式唤醒的失败发生在语音识别的转写层，不是文本正确转写后的匹配层；缩短或规整 Agent 名只能缓解转写，不能绕过，确定性入口见 C8009 | 真机已证 |
| C8013 | 手机伴侣 App 的角色 | 网络代理见 C6010；另承担设备管理与设置、媒体管理、AI 功能入口与眼镜资源包下发 | 文档 |

### 3.9 分发与提审

依据：官方发布文档 publish.md、AIX 文档；导入行为为维护者 2026-10-24 在 Global AIUI Studio 的实测。

| 编号 | 原语 | 结论 | 实测 |
|---|---|---|---|
| C9001 | 分发格式 AIX | AI eXecutable，遵循 Open Agent Format，自包含代码、配置与静态资源；打包自动生成唯一 UUID 的 VERSION 文件做版本校验 | 文档 |
| C9002 | 包大小上限 | 官方未公布数值 | 文档 |
| C9003 | 打包排除 .aixignore | 必须排除 .agents、.aix、artifacts、*.aix、skills-lock.json、node_modules，否则开发文件进包，实测可由 2.3 KB 膨胀到 107 KB | 构建实测 |
| C9004 | Studio 导入行为 | 导入对话框只有一个 URL 输入框；/tree/ 之后的内容整体被当作一个 ref，子目录地址导入失败；仓库根地址导入得到空代码树；单段分支名、分支根放一个 Agent 的全部文件时，导入成功为一个完整项目 | Studio 实测 |
| C9005 | 提审红线 | 名称必填且不超过 20 字符、不得与他人重名、不得含测试与 test、beta 等词与极限词；图标必填且不得用默认图标；功能介绍不超过 500 字符；开场白必填，建议不超过 300 字；预览素材 3 至 5 个文件，至少 1 张图片加 1 个视频，视频不超过 60 秒；每个权限逐项写明用途 | 文档 |
| C9006 | 提审声明勾选 | Studio 提审另有声明类勾选：网络、摄像头、麦克风、扬声器、Rokid 账号信息等，与 3.7 节的清单权限是两套东西 | 文档 |
| C9007 | 发布流程 | 构建、网页模拟、AIX 打包上传云端、真机调试、完善提审资料、提交审核 | 文档 |
| C9008 | 版本与 ID 的生成 | 版本号与 Agent ID 均由系统生成，开发者不可编辑 | 文档 |

## 4. 开口探针

探针是为验证条目而建的实测装置。本节只登记探针与它要回答的条目号；探针数据回齐后，结论写回对应条目并更新其实测状态，本节相应行删除。

| 探针 | 验证条目 | 状态 |
|---|---|---|
| 能力基准测试 Agent，23 项逐项测底座 | C2002、C2004、C3002、C3011、C4001 至 C4007、C5002 等 | 已建，真机复测未完成 |
| 影音捕捉系列 10 个 Agent，各顶一条影音边界 | C2002、C2004、C2006、C2007、C3001、C3002、C3021 | 已建，硬件链待真机回填 |
| 定格动画 Agent 加日志回传客户端 | C6005 复证；错误日志经外部通道回传的可行性 | 已建，待真机跑一轮 |
| 描红探针，结印与手语两个 | C3016 图片输入做定格判定的可用性与命中率 | 已建，待真机数据定正式版收录 |
| 连续视频流探针 | C2009 | 已立项，未跑 |
| 识别错误类别采集 | C3013 | 待真机触发各类错误后比对原文 |

## 5. 未明与矛盾

以下不是条目：它们是官方来源自身对不上、或官方没有给出的点，挂在相关条目之下，等官方口径或实测澄清后并入条目或删除。

1. 显示分辨率双口径：产品规格 480 × 400（C1005）与运行时画布 480 × 352（C5002）并存，官方未说明两者关系。
2. FOV 第三方说法 23° 与显示分辨率第三方说法 640 × 480 均未经官方证实，以 C1006、C1005 为准。
3. 续航口径多套：同一产品页 FAQ 称日常 8 至 10 小时、对比表称混合使用 6 小时、配充电盒 30 小时，无统一测试条件（C1011）。
4. 第二颗芯片型号官方未证实（C1001）。
5. 摄像头传感器型号与视场角官方未公布（C1008）。
6. IMU 轴数、型号、采样率上限与精度官方未公布（C4001 至 C4004）。
7. 头部手势完整枚举官方未公布（C4006）。
8. getBattery 的细节文档不全：navigator 参考称电量方法见 device 参考，但 device 参考无此章节（C5018）。
9. 设备代际差异：Rokid Glasses 2 与第一代全彩眼镜的按键映射在官方 events 参考中标注未验证，不得套用本表 3.8 节的映射。
10. 官方文档双轨：open.rokid.com/aiui 为当前版，js.rokid.com 为较早版本，两站差异未逐页比对；本表以官方仓库 documentation 与 aiui-dev skill 为准。
11. 包大小上限与域名白名单报备入口、审核时效，官方未细化（C9002、C6011）。

## 6. 官方来源清单

**产品与平台**

- Rokid Glasses 官方全球产品页（规格主来源）：https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid 英国官方站 AI 产品线（规格互证）：https://gb.rokid.com/collections/rokid-ai-lineup
- 官方 Academy 教程《3.6 Glasses AIUI》：https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**官方文档站**

- AIUI 文档（当前版）：https://open.rokid.com/aiui
- AIUI 文档（较早版本）：https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**官方 GitHub 仓库 yodaos-project/AIUI**

- 仓库首页：https://github.com/yodaos-project/AIUI
- aiui-dev skill（API 契约主来源）：https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- 提审与发布：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- 什么是 AIX：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- 运行环境：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU 指南：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- 网络使用说明：https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- 文档目录（含 lan、prefetch、sourcemap 等 unsupported 标注）：https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json

## 7. 变更日志

### v2.1.0 2026-10-30

C6003 结论订正：官方 documentation 的 OPFS 专页（3-api/storage/opfs.md）给出了 navigator.storage 的完整方法面，此前按 aiui-dev references 的一句口径记为「方法细节未给出」并不准确，现按专页改写，并注明配额只有运行时查询口、官方未公布数字。第 5 节原第 9 条（StorageManager 方法细节未给出）已经澄清，撤下，后续条目顺延一号；条目内引用未明条号的历史错位一并对齐（C1011、C4006、C5018）。

### v2.0.0 2026-10-29

结构重构为原子注册表：全文按九段拆成 123 个编号条目，每条含原语、结论与实测状态；新增编号与治理、总则与开口探针三节；原第 5 节矛盾与未明事项改挂条目号保留。场景类问题不再逐条收录，统一由条目与总则推导。

### v1.1.0 2026-10-29

第 4 节补入平台定位的官方口径「Agent 本质上完成闭环」，并在 4.3 表新增跨 Agent 跳转与打开宿主设置页两条；全文标题去除括注，括注内容移入正文；新增写在前面与本变更日志。

### v1.0.0 2026-10-29

入仓公开版。本档案编制于 2026-10-24，汇编官方产品页、官方文档站与官方仓库 aiui-dev 参考；入仓时做通用化处理，删去开发者内部的工作政策与个人使用痕迹，能力事实未动。
