# 官方文档全量审计（2026-10-29）

起因：AV11 误用官方清单外的浏览器 API `FileReader`，真机才暴露。GO 指令把官方 Web API 参考与全部开发文档过一遍，把「什么能用、什么根本不存在」钉死，杜绝同类低级错误。

**范围与方法**：上游 `yodaos-project/AIUI` 的 `documentation/` 全量（392 篇，中英双版按中文版读）+ `aiui-dev` Skill 的 `references/`（53 篇）。五路分片通读（Web 平台 / 设备·媒体·AI / 指南·框架 / 组件·设计 / 教程·云·工具·更新日志），另以候选名单在文档全树 grep 核有无。结论只收实读实查到的；本文件是 SOP「API 纪律」的证据底稿，规范本体在 `SKILL.md`。

## 一、运行环境定性

- 引擎是 **QuickJS（2024-01-13）+ Skia** 的 Ink 自研容器，不是浏览器：完整 ES2023（Promise/async、Map/Set、BigInt），**仅 ESM**，不支持 CommonJS `require()`/`module.exports`，不支持顶级 await，`.ink` 文件不能 export（`0-guide/runtime/env.md`、`0-guide/basic/module.md`）。
- API 是**清单式**的：官方参考列了什么就有什么，没列的就不存在。`3-api/web-apis.md` 明文：已有 Web 代码仍可能依赖 AIUI 尚未实现的浏览器能力。
- APIs 随 **Ink 运行时版本**到达，`app.json.engine` 的版本下限决定可用面（见第四节）。

## 二、确认可用的面（按域，只列关键项）

- **网络**：`fetch`（选项仅 method/headers/body/timeout/signal 五项）、`wx.request`、WebSocket（binaryType 固定 `arraybuffer`）、EventSource、Streams 全套、URL/URLSearchParams、FormData、File、Blob（`arrayBuffer()`/`text()`/`bytes()`/`stream()`/`slice()`）。
- **存储**：`localStorage`（按 Agent 隔离；`getItem` 缺失返回 `null`，`wx.getStorageSync` 缺失返回 `undefined`）、wx.storage、OPFS 子集（`navigator.storage.getDirectory()`，宿主无后端时 NotSupportedError）。
- **编码/加密/性能**：TextEncoder/TextDecoder（+Stream 版）、`atob/btoa`、Web Crypto **仅 SHA 摘要与 HMAC**（raw 导入导出）、performance mark/measure。
- **相机/媒体**：`getUserMedia`（约束含 `captureSource`/`microphoneMode`）、`ImageCapture.takePhoto`（quality 为 high/normal/low 三档；mode 为 default 3024×4032 / wide 2016×2688 / telephoto 2016×1512）、`grabFrame()`、wx 相机（返回 `{data: ArrayBuffer, mimeType}`，须包 Blob 再用）、`MediaRecorder`（**只有四个精确 mime**：`audio/wav`、`audio/ogg;codecs=opus`、`video/webm;codecs=vp8,opus`、`video/mp4`；`isTypeSupported` 只能静态调用）、wx RecorderManager（无音源/模式参数）。
- **Canvas**：页面画布 `wx.createCanvasContext(id)`（ID 不带 `#`，找不到返回 null），绘制后必须 `ctx.flush()`；离屏画布是自有 `new Canvas(w,h)`，导出用其 `convertToBlob()`；全局函数 `createImageBlob(source, {type, quality})` 把 ImageBitmap 编码为 Blob（`3-api/window.md`）。页面画布上下文没有导出方法，导出必须走离屏 Canvas。
- **设备**：BarcodeDetector（detect 只收 ImageData/Blob/ImageBitmap）、三个 Generic Sensor（AbsoluteOrientationSensor / Accelerometer / Gyroscope，首读前读数为 `null`)、`navigator.geolocation`（纯回调式）、GPXDocument、`navigator.getBattery()`、蓝牙 GATT。
- **AI**：`SpeechRecognition`（须用户交互触发 start）、`SpeechRecognitionSession`（不自开麦克风，音频经 `session.audio.getWriter()` 写入，先查 `getCapabilities()`）、`speechSynthesis.speak`（enqueue/immediate）与 `synthesize`（独立路径，不进 speak 队列）两条 TTS 路径、11 个固定音色 ID、`LanguageModel`（`availability()` **只有 `available`/`unavailable` 两态**；`promptStreaming` 是轮询式 `read()`，不是 WHATWG 流；图片只许放在 user 角色的结构化 content 里；toolcall 不自动执行）。
- **框架面**：`export default { ... }` 注册（无 `App()/Page()/Widget()` 调用）、`ink:` 前缀指令、bind/catch 事件、`onKeyDown/onKeyUp`（宿主默认动作在 onKeyUp 后，接管须在 onKeyUp 里 preventDefault）、`enableWorldAwareness()` 后才有 `onHeadGesture`/`onOrientationStabilityChange`、`window.open()` 只能开已声明 Widget、Agent Worker 无 fetch/window/document/渲染/媒体采集。

## 三、查无名单（全树 0 命中或明文不支持——写进代码即错）

`FileReader`、`sessionStorage`、`XMLHttpRequest`、`URL.createObjectURL/revokeObjectURL`、`DOMParser`、`structuredClone`、`queueMicrotask`、`Notification`、`navigator.clipboard`、`IntersectionObserver`、`MutationObserver`、`ServiceWorker`、`new Worker()`、`canvas.toDataURL()`、`canvas.toBlob()`、`canvas.captureStream()`、WebGL、OffscreenCanvas（明文「即将支持」）、`getDisplayMedia`、`track.applyConstraints()`、`ImageCapture.getPhotoCapabilities/getPhotoSettings`、OCR/`TextDetector`/`FaceDetector`、`DeviceOrientationEvent/DeviceMotionEvent`、其他 Generic Sensor（LinearAcceleration/RelativeOrientation/Magnetometer/Gravity/AmbientLight）、`webkitSpeechRecognition`、`speechSynthesis.getVoices()` 与 TTS 的 cancel/pause/resume、Permissions API（`navigator.permissions`）、Crypto 的 encrypt/decrypt 与 RSA/ECDSA/JWK、DOM 式 `onclick=` 属性事件。

另有「名字在、语义不同」的坑：ASR 的 `error` 类别字符串**官方未给枚举表**（只有 error/message/sessionId 三个字段有文档）——不许照 MDN 的 Web Speech 取值表写分支；`swiper` 不是轮播组件（只是 view 分组）、`row`/`column` 与 view 同实现；`calendar` 只展示无选择事件；WXSS 是子集（无 sticky、无 3D 变换/透视、无 animation-play-state、无 font-variant/word-break、无 ::placeholder、无多行截断；calc 只许双操作数加减且单位兼容）。

## 四、Ink 版本到达表（设计时对版本下限）

| 版本 | 关键新增 |
|---|---|
| 0.14 | `requestAnimationFrame`、`takePhoto` 的 `enableSystemPreview`、`navigator.region/language` |
| 0.15 | AbsoluteOrientationSensor、自定义组件、第三方包 |
| 0.16 | `enableWorldAwareness` / 稳定性事件、流式 fetch 读取、TextDecoder 流式解码 |
| 0.17 | 媒体采集与录制（getUserMedia/MediaRecorder）、OPFS、头部手势事件、`<video>` 等组件 |
| 0.18 | Widget、Agent Worker（字段 `agentWorkers`)、WebSocket/FormData/File、geolocation/GPX、Web Audio、SpeechRecognitionSession |
| 0.19 | `Canvas.convertToBlob`/`createImageBlob`、网络状态感知、`wx.canIUse` 按注册函数判定、移除独立 `SPEECH_RECOGNITION` 权限 |

版本敏感 API 必须运行时探测：`typeof` 守卫（官方 TTS 教程即此写法）或 `wx.canIUse()`——但 canIUse 只证明接口存在，不证明设备可用或已授权。

## 五、权限全表（7 个，大小写敏感——纠正旧「只有三个」的说法）

`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`（设备能力三件）+ `READ_MEDIA_IMAGES`、`CREATE_MEDIA_IMAGES`、`READ_MEDIA_AUDIO`、`CREATE_MEDIA_AUDIO`（系统媒体库读写，`1-framework/open-agent-format/app-json.md`）。无法识别的字符串不授予任何能力；声明 ≠ 系统授权，被拒与不可用必须在调用处处理。凭证类红线：`developerSk`、云服务 SK/access_token 只能存服务端，禁止写入 agent 代码、客户端包、仓库与日志（`0-guide/account/authorization.md`、`5-cloud/overview.md`）。

## 六、其他硬规则（散在各域，开发规范已收编）

- 线上请求强制 HTTPS，商店发布前域名须在开发者后台报备白名单；局域网直连与页面级预拉取均为 `unsupported`（`0-guide/basic/network/usage.md` 等）。
- 性能：setData 合并提交、队列必须有上限、二进制优先 ArrayBuffer 而非 Base64、列表用稳定业务 `ink:key`、onHide 只暂停、onUnload 彻底释放（定时器/连接/轨道/会话）（`0-guide/performance/runtime.md`）。
- 提审文案红线：名称 ≤20 字符且不重名、禁用「官方/权威/推荐/精品/TOP1」等暗示词与「测试/test/beta」、禁绝对化承诺；图标不得默认/纯色/带水印二维码；预览视频 ≤60 秒须演示核心流程（`0-guide/bundle/publish.md`)。
- 官方自带完成检查表：`aiui-dev/references/checklist.md`（9 节）——§6「每个运行时 API 须在 references 中有文档」与 §8「搜陈旧字段与不支持注册」是本次纪律的直接依据；§9 要求完成报告分静态/执行/未验证三级，不许把打包成功说成真机验证。
- 文档内部两处不一致（引用时注意）：第三方库导入（guide 说 npm 包不能直接导入、须手动放 ESM 文件；framework/package 说 AIUI Package 可经 npm 加载——区分「任意三方库」与「AIUI Package」）；Canvas 提交（0-guide/basic 写 `ctx.draw()`，API 参考/组件/教程均为 `ctx.flush()`——以 API 参考为准）。另：`7-tools/editor.md` 描述的是中国站 Studio 与 Rokid Ai App，本舰队只走 Global 链路，勿混。

## 七、审计副产物（已报登记处/GO，不在本文件处置）

- 错误码表 E6006 的触发写作 availability 的 `downloadable/downloading` 中间态——与现行文档（仅两态）不符，属当年按 Chrome 习惯的臆测；码义按治理「永不改义」，如何处置（标注废弃或修订触发描述）待 GO 裁定。
- 错误码表 E3006–E3013 依赖的 ASR 错误类别字符串无官方枚举背书（源自全舰队代码实查）；新开发不得再按 MDN 取值表新增此类分支，未经真机验证的分类一律走 E3003 兜底。
