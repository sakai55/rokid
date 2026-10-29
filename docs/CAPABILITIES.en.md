# Rokid Glasses Capability Registry — Atomic Entries

[中文](CAPABILITIES.md) | English | [日本語](CAPABILITIES.ja.md)

Translated from the Chinese version v2.0.0 (2026-10-29). In case of conflict, the Chinese version prevails.

> Compiled on 2026-10-24; current version v2.0.0, 2026-10-29
> Source policy: **Rokid official sources only** (the official product page, the official documentation site, the official GitHub repository `yodaos-project/AIUI` and its bundled `aiui-dev` skill references), plus the registry maintainer's own on-device and build testing, with test-derived conclusions marked separately in each entry. The official repository's `skills/aiui-dev` is the primary source for the API contract; sources below are cited as `skill: references/…`.

## Foreword

This registry is maintained by a Rokid AIUI developer; it is not an official Rokid document. It breaks the capabilities of the Rokid Glasses base platform down into atomic entries: each entry covers exactly one base primitive, with a stable number, a one-sentence conclusion, the official basis, and a verification status. Before designing an agent, check here whether the primitives it needs exist and where their boundaries are.

This registry records primitives only, not application scenarios. Scenarios are combinations of primitives and can be written endlessly; cataloguing them one by one would turn this into a never-ending Q&A set. Any scenario question is answered the same way: break the scenario down into the primitives it requires and look each one up here — if the primitive exists, the combination works; if it does not, the answer is that it cannot be done, and no separate entry is opened for that question. The official API reference is itself a closed list: an API that is not on the list does not exist, and that is the basis for most determinations in this registry.

Maintenance mirrors the error-code table `ERROR-CODES.md`: entries are only appended at the end of a segment and numbers are never reused; an entry whose conclusion is overturned gets its conclusion revised with a trace left in the change log, and its number is not deleted; when conclusions change, the version is bumped and superseded versions are archived under `base/capabilities/` with an index. The Chinese version is authoritative; the English and Japanese versions are translations, and the Chinese version prevails in case of conflict.

## 1. Numbering and Governance

Numbers look like `C2003`: the letter C plus four digits, where the thousands digit is the segment and entries are numbered sequentially within a segment.

| Segment | Domain |
|---|---|
| C1xxx | Hardware and display |
| C2xxx | Camera and imaging |
| C3xxx | Audio, speech and LLM |
| C4xxx | Sensors and positioning |
| C5xxx | Display runtime and pages |
| C6xxx | Storage, files and network |
| C7xxx | Permissions |
| C8xxx | Interaction and host |
| C9xxx | Distribution and review |

The verification status takes only four values: **Docs** — supported by official documentation only, not yet verified on a real device; **Device-verified** — backed by results or behavior returned by a real device; **Build-verified / Studio-verified** — verified in the packaging or Studio flow; **Pending** — a probe exists but its data has not come back yet, see section 4 for the probes. Version rules: adding an entry or changing an entry's conclusion bumps MINOR, a structural or rule change bumps MAJOR, a wording fix bumps PATCH.

## 2. General Rules

The general rules are not entries; they are rules that apply alongside the entries when deriving an answer for a scenario.

- **R1 Closed-loop positioning** (official position, 2026-10-29): an agent essentially completes a closed loop — an agent uses its own declared permissions and callable APIs to take one job from entry to result inside itself; host capabilities outside that loop, including system settings, other agents and host configuration, are not delegated to agents. Source: an official reply, relayed by this registry's maintainer.
- **R2 The list is the boundary**: the official API reference is a closed list. Any API, parameter or enum value that cannot be found there is treated as non-existent; never assume it exists by browser or WeChat Mini Program habit.
- **R3 The interaction gate**: capture and connection calls (taking photos, recording audio, starting ASR, BLE connections and the like) require the owning view to be in an interactive state, and usually must also be triggered by user interaction; calls made in a non-interactive state fail outright. Resources must be released when done: microphone and camera tracks must be stopped, BLE scans and connections disconnected, watchPosition cleared with clearWatch, AudioContext closed.
- **R4 Declaration is not grant**: writing a permission into app.json is only a declaration; the system can still refuse at the call site, and the code must handle the refusal branch.
- **R5 The simulator is not the device**: in the web simulator, sensor values are mostly simulated and performance and heat differ from the real device; for entries whose verification status is "Docs", the conclusion is subject to re-testing on a real device.

## 3. Entries

### 3.1 Hardware and Display

Basis: the official global product page https://global.rokid.com/products/b-h-rokid-glasses-with-display , cross-checked against the same specifications on the official UK site.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C1001 | Main chip | Snapdragon AR1. The product page also carries a "dual-chip" marketing line, but the official specification table does not list a model for the second chip | Docs |
| C1002 | Memory and storage | 2 GB / 32 GB | Docs |
| C1003 | Display technology | Binocular Micro LED with diffractive waveguide | Docs |
| C1004 | Display color | Monochrome green, a single green emission channel, not full color | Docs |
| C1005 | Panel resolution | 480 × 400 by product specification; this coexists with the runtime canvas figure in C5002, see unresolved item 1 | Docs |
| C1006 | Field of view | 30° | Docs |
| C1007 | Brightness | 1500 nits | Docs |
| C1008 | Camera hardware | 12 MP, photos at 3024 × 4032, F2.25; the sensor model and the camera's field of view have not been published officially | Docs |
| C1009 | Microphone hardware | 4-microphone array | Docs |
| C1010 | Speakers | Dual linear directional high-fidelity speakers | Docs |
| C1011 | Battery and charging | 210 mAh; the official battery-life figures come in several versions, see unresolved item 4; magnetic charging, 80% in 20 minutes, the charging case refills the glasses about 10 times | Docs |
| C1012 | Wireless connectivity | Wi-Fi 6, Bluetooth 5.3 | Docs |
| C1013 | Whole-device parameters | 49 g, IPX4; temple length 155.5 mm, hinge spacing 146.3 mm, TR90 frame with titanium-alloy hinges | Docs |
| C1014 | Prescription support | Supports prescriptions from +15 to −15, with an official prescription service and magnetic prescription frames | Docs |
| C1015 | Camera indicator light | Supported; it lights up while shooting | Docs |
| C1016 | Operating system | Name and version not published officially; the known runtime is the Ink container, see C5001 | Docs |
| C1017 | Product-level whole-device features | Real-time translation in 89 languages, the AI assistant, notifications, navigation, teleprompter, notes, meeting transcription and the like are features of the glasses system and the official app, not APIs an agent can call; agents can only use the primitives registered in this table | Docs |

### 3.2 Camera and Imaging

Basis: `skill: references/apis/media.md`, `skill: references/apis/wx.md`; requires permission C7002.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C2001 | Video stream getUserMedia | Can obtain a MediaStream; constraints support facingMode, width, height, frameRate and deviceId, and the final values are read from the track's getSettings | Docs |
| C2002 | Photo capture ImageCapture.takePhoto | Returns an encoded Blob; three modes: wide (wide angle, for barcode scanning), telephoto (for reading distant text), default (ordinary photos); also has quality and enableSystemPreview options | Docs |
| C2003 | Photo output sizes | wide 2016 × 2688, telephoto 2016 × 1512, default 3024 × 4032; the Blob itself carries no width or height, decoding requires createImageBitmap | Docs |
| C2004 | Frame grab ImageCapture.grabFrame | Returns an unencoded ImageBitmap pixel frame; must be closed after use | Docs |
| C2005 | wx photo capture CameraContext.takePhoto | Returns an ArrayBuffer plus mimeType; there is no mode-selection parameter, modes go through C2002; it must be triggered at an interaction-gate call point | Docs |
| C2006 | Video recording MediaRecorder | Records audio/video streams; the video mime is whatever isTypeSupported reports, known values are video/webm;codecs=vp8,opus and video/mp4 | Docs |
| C2007 | Barcode detection BarcodeDetector | Look up supported formats with getSupportedFormats first; detect accepts ImageData, an encoded image Blob or an ImageBitmap, and returns format, rawValue, boundingBox and cornerPoints | Docs |
| C2008 | OCR interface | Does not exist. The path for reading text is a telephoto photo plus image input to the LLM, see C3016 | Docs |
| C2009 | Continuous frame stream | The documentation gives no upper frequency limit or background behavior for continuous frame capture; the sustained availability of the getUserMedia stream and grabFrame awaits probe verification, see section 4 | Pending |
| C2010 | Text and face detection | TextDetector and FaceDetector do not exist; there is no such entry in the official list | Docs |

### 3.3 Audio, Speech and LLM

Basis: `skill: references/apis/media.md`, `skill: references/apis/ai.md`; recording requires permission C7003.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C3001 | Recording source captureSource | microphone, or system-audio for internal capture of system sound; system-audio cannot be combined with echoCancellation or microphoneMode, otherwise OverconstrainedError; system sound does not fall back to the microphone automatically | Docs |
| C3002 | Microphone mode microphoneMode | Four modes: wearer (wearer-first), far-field, near-field, omnidirectional; they apply only to getUserMedia capture streams, device support is not guaranteed, an unsupported mode raises OverconstrainedError, and the value actually in effect is read from getSettings | Docs |
| C3003 | Microphone modes vs. host recognition | The modes act only on self-captured streams, not on host speech recognition; host recognition uses the host microphone and is unrelated to the mode setting | Docs |
| C3004 | Recording encoding MediaRecorder | Audio supports audio/wav and audio/ogg;codecs=opus | Docs |
| C3005 | wx recording RecorderManager | start, pause, resume, stop and frame callbacks; uses the default microphone, with no source or mode selection parameters — to select a mode use C3001 and C3002 | Docs |
| C3006 | Speech synthesis speechSynthesis.speak | Synthesizes and plays directly, queued through the runtime's unified player; mode is enqueue (default) or immediate | Docs |
| C3007 | Speech synthesis speechSynthesis.synthesize | Generates without playing and returns an abortable task; options include caption granularity none, sentence or word, audio formats pcm, mp3 and ogg_opus, sample rate, channels and bitrate; pair with SpeechAudioPlayer for independent playback | Docs |
| C3008 | Synthesis voices | 11 fixed voice IDs in total: female-tianmei, English_radiant_girl, English_expressive_narrator, male-qn-qingse, male-qn-jingying, female-yujie, Chinese (Mandarin)_News_Anchor, Chinese (Mandarin)_Radio_Host, clever_boy, lovely_girl, English_Trustworthy_Man; there is no getVoices | Docs |
| C3009 | Synthesis control surface | The utterance lang attribute has no effect and does not change the generated language; there is no cancel, pause or resume; pitch, rate and volume default to 1 | Docs |
| C3010 | wx announcement wx.speech.playTTS | Announces one sentence, returns a request ID string, and returns an empty string on failure | Docs |
| C3011 | Speech recognition SpeechRecognition | Recognition on the host microphone; properties lang, continuous, interimResults, maxAlternatives; start requires the view to stay interactive, otherwise InvalidStateError; when lang is empty the host picks a default language | Docs |
| C3012 | Speech recognition SpeechRecognitionSession | Recognizes an external audio stream; the session itself does not open a microphone; supports hotword phrases with boost, auto segmentation, vad, semantic, and updateContext for dynamic context; check getCapabilities first for the host's real capabilities | Docs |
| C3013 | Recognition error categories | The official documentation gives no enumeration of the error event's category values; error handling subdivided by category is an unverified assumption and must not be relied on | Docs |
| C3014 | LLM availability LanguageModel.availability | Returns only available or unavailable; does not expose the provider, model list or endpoints | Docs |
| C3015 | LLM session LanguageModel.create | Underneath is the host's OpenAI-compatible chat-completions streaming channel; model resolution order is an explicit model, then the host defaultModel; system may only appear as the first of initialPrompts | Docs |
| C3016 | LLM multimodal input | The content array of a user message supports text and image_url, and an image may be a data: URL; structured content is limited to the user role | Docs |
| C3017 | LLM tool calls | tools are forwarded into the provider request body; calls come back as session toolcall events carrying callId, functionName and arguments; they are not executed automatically and there is no guaranteed structured round-trip protocol | Docs |
| C3018 | LLM requests prompt and promptStreaming | Streaming is poll-based read, not a WHATWG Stream and not an async iterator; only one in-flight request is allowed per session at a time; after destroy the session cannot be used again | Docs |
| C3019 | Audio playback AudioPlayer | General-purpose player for files inside the local package or network URLs; supports pcm and ogg_opus streaming append playback and caption text tracks | Docs |
| C3020 | Sound effects Sound | Short playback of local sound effects, local files only; http and https URLs are rejected | Docs |
| C3021 | Web Audio | AudioContext with createBuffer, Oscillator, Gain, BiquadFilter, Analyser, MediaStreamSource, decodeAudioData and more is available, enough for waveform and spectrum analysis | Docs |

### 3.4 Sensors and Positioning

Basis: `skill: references/apis/device.md`, `skill: references/apis/geo/geolocation.md`, the official IMU guide; positioning requires permission C7001.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C4001 | Accelerometer | Three-axis acceleration x, y, z plus timestamp; events activate, reading, error; the constructor parameter frequency is only a best-effort hint to the host | Docs |
| C4002 | Gyroscope | Three-axis angular velocity x, y, z plus timestamp; events and frequency semantics as in C4001 | Docs |
| C4003 | Absolute orientation AbsoluteOrientationSensor | Absolute-orientation quaternion [x, y, z, w] plus timestamp; availability depends on device hardware support | Docs |
| C4004 | Sampling-rate guarantee | No officially published maximum frequency or precision figures; the official guide's examples use 60, suggesting a start at 30 to 60 Hz | Docs |
| C4005 | Other sensor interfaces | Geomagnetic, light and proximity sensors have no separate API and do not appear in the official list | Docs |
| C4006 | Head gesture onHeadGesture | Requires enableWorldAwareness turned on inside the Page; the only gesture value in the official examples is nod, and the full enumeration has not been published, see unresolved item 8 | Docs |
| C4007 | Head-stability event onOrientationStabilityChange | Also requires world awareness turned on; event.stable reports changes in head stability | Docs |
| C4008 | Eye tracking | Does not exist. So-called gaze is implemented with head orientation C4003 plus head stability C4007 plus nod C4006 | Docs |
| C4009 | Positioning geolocation | getCurrentPosition and watchPosition, released with clearWatch; coords include latitude, longitude, accuracy (in meters) and the nullable altitude, altitudeAccuracy, heading and speed; options enableHighAccuracy (default false), timeout, maximumAge; error codes 1 denied, 2 unavailable, 3 timeout | Docs |
| C4010 | GPX GPXDocument | GPX route parsing, creation and export: setStartPoint, addWaypoint, appendTrackPoint, toString, toBlob; displayed with the map and map-gpx components | Docs |
| C4011 | Bluetooth BLE | Central-device role: getAvailability, getDevices, requestDevice, scanDevices (Ink-specific), GATT connect, readValue, writeValue, startNotifications; requestDevice, scanDevices, connect and startNotifications require the view to be interactive | Docs |
| C4012 | Bluetooth peripheral and advertising | Does not exist; the official list has no peripheral capability | Docs |

### 3.5 Display Runtime and Pages

Basis: `skill: references/framework.md`, `skill: references/apis/window.md`, `skill: references/apis/canvas.md`, `skill: references/events.md`, the official runtime-environment documentation.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C5001 | Runtime Ink | The logic and view layers run in Ink, an in-house container built on QuickJS plus Skia; ES2023, ESM | Docs |
| C5002 | Reference canvas | The full-screen Page reference canvas is 480 × 352; safe margins are 16 px left and right, 12 px top and bottom, giving an effective content width of 448 px | Docs |
| C5003 | Monochrome-green design constraints | Base color #40ff5e with a 6-step brightness ladder; black equals a transparent background, so an opaque black panel cannot be counted on to occlude reality; meaning must not be carried by color alone and needs icons, text or line styles on top; body-text brightness is recommended at no less than 72%, decorative lines at no more than 24%, and key information belongs in the central comfortable field of view | Docs |
| C5004 | Viewport size | window.innerWidth and innerHeight are read-only logical pixels | Docs |
| C5005 | Widget sizes | The size family 1x1 is 239 × 140 and 1x2 is 480 × 140; the glasses have 4 Widget grid slots in total; family is only a size category, and the root node must not be hard-coded to those pixel values | Docs |
| C5006 | Opening UI window.open | Can only open a Widget declared in app.json, the sole target is _widget, with overlay support; it cannot open another Page or an external URL | Docs |
| C5007 | Closing an instance window.close | Requests the host to close the current agent instance | Docs |
| C5008 | Cross-agent navigation | Does not exist: the official list has no openAgent-type entry, and wx.navigateTo is limited to pages inside the same agent, see general rule R1 | Docs |
| C5009 | Opening a host settings page | Unreachable: there is no such API, and "open such-and-such settings" intents are carried out by the host only as far as opening the app itself, see general rule R1 | Docs |
| C5010 | Project structure | app.json plus app.js plus AGENTS.md plus pages; a page is either a single .ink file or the four-piece set .json, .wxml, .wxss, .js; optional widgets, workers, components, assets | Docs |
| C5011 | Built-in components | 37 authorable tags in total, covering containers, text, forms, media, maps, canvas, charts and a2ui for AI-generated UI | Docs |
| C5012 | Agent Worker | A UI-less script, triggered by open; lifetime is instant or foreground, background is reserved and ineffective; it has timers, Promise, Crypto, Wasm and encoding streams; it has no window, document, fetch, routing, rendering or media capture | Docs |
| C5013 | Languages and modules | TypeScript entry points and WebAssembly modules are supported through the project packaging flow | Docs |
| C5014 | Canvas 2D | Paths, rectangles, text including measureText, transforms, gradients, patterns, and drawImage in only the 3-, 5- and 9-argument forms; color parsing covers only #rrggbb, #rgb, rgb, rgba and a few named colors; output goes through convertToBlob and createImageBlob, and canvas.toDataURL does not exist | Docs |
| C5015 | WXML templates | template is not supported | Docs |
| C5016 | Conversation-flow cards | Display-only by default; interactive UI needs a full-screen Page or a Widget | Docs |
| C5017 | Device information navigator | id is an opaque ID bound to the agent plus device and must not be treated as a credential; userAgent and versions.ink, versions.skia give version strings; language, languages and region may be empty; onLine and connection give online status and a connection estimate; renderingEnabled reports whether the current instance can render | Docs |
| C5018 | Battery getBattery | Returns a Promise of a BatteryManager; on a host with no battery capability the Promise is rejected; the documentation is incomplete, see unresolved item 9 | Docs |
| C5019 | Serial number and token | getDeviceSerialNumber and requestDeviceToken are available only to system-level agents; ordinary agents get an empty string back or must not rely on them | Docs |
| C5020 | Global encoding tools | window.atob, btoa and the global createImageBlob are available; createImageBlob performs PNG and JPEG encoding | Docs |

### 3.6 Storage, Files and Network

Basis: `skill: references/apis/web.md`, `skill: references/apis/wx.md`, the official network guide.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C6001 | Local storage localStorage | A string KV isolated per agent: getItem, setItem, removeItem, clear | Docs |
| C6002 | wx storage | setStorage, getStorage, removeStorage, clearStorage and their Sync synchronous versions; data is JSON-serialized | Docs |
| C6003 | StorageManager navigator.storage | The documentation gives only one line, "persistent file storage entry point", with no method details, see unresolved item 10 | Docs |
| C6004 | General file system | Does not exist: resources are always resolved from paths inside the project, and there is no interface for reading, writing or listing arbitrary paths | Docs |
| C6005 | FileReader | Does not exist; on a real device it invariably throws FileReader is not defined; converting a Blob to a data URL goes through blob.arrayBuffer plus chunked btoa; related error code E2005 | Device-verified |
| C6006 | Browser APIs verified absent | None of the following exist in the Ink runtime, and writing them into code is an error: sessionStorage, XMLHttpRequest, URL.createObjectURL, DOMParser, structuredClone, queueMicrotask, Notification, the clipboard API, IntersectionObserver, MutationObserver, ServiceWorker, new Worker, OffscreenCanvas, getDisplayMedia, applyConstraints, getVoices, navigator.permissions | Docs |
| C6007 | fetch and web facilities | fetch, Headers, Response including streaming body reads, WebSocket, File, FormData, URL and URLSearchParams, and the full Streams family are available | Docs |
| C6008 | wx network | The wx.request timeout resolves in the order options.timeout, app.json configuration, default 60000 ms; wx.createSocket and connectSocket; wx.createEventSource provides SSE | Docs |
| C6009 | Web Crypto | randomUUID and getRandomValues up to 65536 bytes are available; subtle provides only SHA-1, 256, 384, 512 digests and HMAC; encryption, decryption, RSA, ECDSA and JWK are not supported | Docs |
| C6010 | Phone-proxied networking | When the glasses are not on Wi-Fi, as long as Bluetooth is connected to the phone app, fetch and wx.request are automatically forwarded over the phone link, transparently to the developer | Docs |
| C6011 | HTTPS and domain allowlist | In the production environment, network requests must use HTTPS; before publishing to the store, request domains must be filed on an allowlist in the developer backend | Docs |
| C6012 | LAN direct connection | Not supported; the official guide calls it in development, and the documentation index marks it unsupported | Docs |
| C6013 | Data prefetch | prefetch is not supported | Docs |
| C6014 | Source-map debugging | Not supported | Docs |

### 3.7 Permissions

Basis: the permissions table in the official framework document app-json.md, corrected by the full audit of 2026-10-29. There are 7 in total; names are case-sensitive, and an unrecognized name grants no capability; also note the upstream inconsistency in C7008.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C7001 | Permission GEOLOCATION | Obtains the current position and watches position changes, see C4009 | Docs |
| C7002 | Permission CAMERA | Accesses the camera and captures images or video, see section 3.2 | Docs |
| C7003 | Permission RECORD_AUDIO | Accesses the microphone and captures audio; ASR also relies on it to open the microphone, and there is no separate ASR permission — the old SPEECH_RECOGNITION was removed in Ink 0.19 | Docs |
| C7004 | Permission READ_MEDIA_IMAGES | Lists and reads images in the system media library | Docs |
| C7005 | Permission CREATE_MEDIA_IMAGES | Adds images to the system media library, excluding modification or overwriting of existing assets | Docs |
| C7006 | Permission READ_MEDIA_AUDIO | Lists and reads audio in the system media library | Docs |
| C7007 | Permission CREATE_MEDIA_AUDIO | Adds audio to the system media library, excluding modification or overwriting of existing assets | Docs |
| C7008 | Documentation stance of the permission list | The framework reference inside the aiui-dev skill still lists only the first three permissions, an internal inconsistency in the upstream documentation; the seven names in the formal framework document govern | Docs |

### 3.8 Interaction and Host

Basis: `skill: references/events.md`, the operation guide built into the Hi Rokid App (the gesture part; on-device behavior there governs).

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C8001 | Wakeup onVoiceWakeup | Can be triggered by voice or touch; known event.keyword values: 乐奇, Hi Rokid, and clickAiAssist for touch wakeup; by default do not filter on keyword; event.preventDefault can take over the host's default action | Docs |
| C8002 | Key events | A Page's onKeyDown and onKeyUp dispatch on event.code: Enter confirm, Backspace back, ArrowUp and ArrowDown scroll, GlobalHook is a device-specific signal for temple touch; the host's default action fires after onKeyUp | Docs |
| C8003 | Single-finger tap | Confirm, corresponds to Enter | Docs |
| C8004 | Single-finger double tap | Back, corresponds to Backspace; when there is no page to go back to, it requests closing the agent | Docs |
| C8005 | Single-finger swipe | Scroll, corresponds to ArrowUp and ArrowDown; the scroll direction can be changed in the app | Docs |
| C8006 | Single-finger long press | Wakes the assistant; the app offers a choice between the glasses AI assistant and the phone assistant | Docs |
| C8007 | Two-finger double tap | Screen off | Docs |
| C8008 | Two-finger front/back swipe | Volume up and down, by default; can be changed in the app | Docs |
| C8009 | Two-finger long press, AI Shortcut Command | Sends one fixed command to a chosen trigger target, with a text limit of 500 characters; the trigger target can be a specific custom or debug agent, i.e. a fixed text delivered deterministically to a designated agent with zero ASR | Device-verified |
| C8010 | Contextual gestures | Music context: tap to play or pause, front/back swipe to change track; call context: double tap to reject an incoming call, tap during a call to mute or unmute, double tap to hang up | Docs |
| C8011 | Buttons bound only to click | A button bound only with bindtap cannot be triggered by gestures on the glasses; a page must map keys to actions itself and cannot rely on button clicks alone | Device-verified |
| C8012 | The failing layer of voice wakeup | Failures of fixed-phrase wakeup occur at the transcription layer of speech recognition, not at the matching layer after correct transcription; shortening or regularizing an agent's name can only ease transcription, not bypass it — for a deterministic entry point see C8009 | Device-verified |
| C8013 | Role of the phone companion app | For the network proxy see C6010; it also handles device management and settings, media management, AI feature entry points and delivery of glasses resource packages | Docs |

### 3.9 Distribution and Review

Basis: the official publishing document publish.md and the AIX documentation; the import behavior is the maintainer's own testing in Global AIUI Studio on 2026-10-24.

| No. | Primitive | Conclusion | Verified |
|---|---|---|---|
| C9001 | Distribution format AIX | AI eXecutable, following the Open Agent Format, self-contained code, configuration and static resources; packaging automatically generates a VERSION file with a unique UUID for version checking | Docs |
| C9002 | Package size limit | No figure published officially | Docs |
| C9003 | Packaging exclusions .aixignore | Must exclude .agents, .aix, artifacts, *.aix, skills-lock.json and node_modules, otherwise development files enter the package — measured to bloat a package from 2.3 KB to 107 KB | Build-verified |
| C9004 | Studio import behavior | The import dialog has a single URL field; everything after /tree/ is treated as one ref, so subdirectory addresses fail to import; a repository-root address imports with an empty code tree; with a single-segment branch name and one agent's complete files at the branch root, the import succeeds as a complete project | Studio-verified |
| C9005 | Review red lines | The name is required, at most 20 characters, must not duplicate someone else's, and must not contain words like test or beta or superlative claims; an icon is required and must not be the default icon; the feature description is at most 500 characters; an opening message is required, recommended at no more than 300 characters; preview media is 3 to 5 files with at least 1 image plus 1 video, and video at most 60 seconds; every permission's purpose must be stated item by item | Docs |
| C9006 | Review declaration checkboxes | Studio review has a separate set of declaration checkboxes — network, camera, microphone, speaker, Rokid account information and the like — which are a different thing from the list permissions in section 3.7 | Docs |
| C9007 | Publishing flow | Build, web simulation, AIX packaging and upload to the cloud, on-device debugging, completing the review materials, submitting for review | Docs |
| C9008 | Generation of version and ID | The version number and the Agent ID are both generated by the system; the developer cannot edit them | Docs |

## 4. Open Probes

A probe is a test rig built to verify entries. This section registers only the probes and the entry numbers they are meant to answer; once a probe's data is complete, the conclusion is written back into the corresponding entry, its verification status is updated, and the row here is deleted.

| Probe | Entries verified | Status |
|---|---|---|
| Capability benchmark agent, 23 items testing the base platform one by one | C2002, C2004, C3002, C3011, C4001 to C4007, C5002 and more | Built; the on-device re-test is not complete |
| Audiovisual capture series, 10 agents, each pushing one audiovisual boundary | C2002, C2004, C2006, C2007, C3001, C3002, C3021 | Built; the hardware chain awaits on-device backfill |
| Stop-motion agent plus a log-return client | Re-verification of C6005; the feasibility of returning error logs over an external channel | Built; awaiting one on-device run |
| Tracing probes, one for seals and one for sign language | The usability and hit rate of C3016 image input for still-frame judgment | Built; on-device data will decide inclusion in the full versions |
| Continuous video stream probe | C2009 | Project approved, not yet run |
| Recognition error-category collection | C3013 | After triggering each error type on a real device, compare against the original text |

## 5. Unresolved and Conflicting Points

The following are not entries: they are points where the official sources disagree with each other or give nothing, hung under the related entries until an official position or a test clarifies them, at which point they are merged into an entry or deleted.

1. Two figures for display resolution: the product specification's 480 × 400 (C1005) coexists with the runtime canvas's 480 × 352 (C5002), and the official sources do not explain the relationship between the two.
2. Third-party claims of a 23° FOV and of a 640 × 480 display resolution are both unconfirmed officially; C1006 and C1005 govern.
3. Several battery-life figures: the same product page's FAQ says 8 to 10 hours of daily use, its comparison table says 6 hours of mixed use and 30 hours with the charging case, with no unified test conditions (C1011).
4. The second chip's model is unconfirmed officially (C1001).
5. The camera sensor model and field of view have not been published officially (C1008).
6. The IMU's axis count, model, sampling-rate ceiling and precision have not been published officially (C4001 to C4004).
7. The full enumeration of head gestures has not been published officially (C4006).
8. The getBattery documentation is incomplete: the navigator reference says the battery methods are in the device reference, but the device reference has no such section (C5018).
9. StorageManager method details have not been given officially (C6003).
10. Device-generation differences: the key mappings for Rokid Glasses 2 and the first-generation full-color glasses are marked unverified in the official events reference and must not be assumed to follow the mappings in section 3.8 of this registry.
11. Two tracks of official documentation: open.rokid.com/aiui is the current version and js.rokid.com an earlier one; the differences between the two sites have not been compared page by page; this registry follows the official repository's documentation and the aiui-dev skill.
12. The package size limit, the entry point for filing the domain allowlist, and review turnaround times have not been detailed officially (C9002, C6011).

## 6. Official Sources

**Product and platform**

- Rokid Glasses official global product page (primary specification source): https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid UK official site, AI product line (specification cross-check): https://gb.rokid.com/collections/rokid-ai-lineup
- Official Academy tutorial "3.6 Glasses AIUI": https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**Official documentation site**

- AIUI documentation (current version): https://open.rokid.com/aiui
- AIUI documentation (earlier version): https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**Official GitHub repository yodaos-project/AIUI**

- Repository home: https://github.com/yodaos-project/AIUI
- aiui-dev skill (primary API-contract source): https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- Review and publishing: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- What AIX is: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- Runtime environment: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU guide: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- Network usage notes: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- Documentation index (with unsupported markings for lan, prefetch, sourcemap and more): https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json

## 7. Change Log

### v2.0.0 2026-10-29

Restructured into an atomic registry: the whole text was split by the nine segments into 123 numbered entries, each carrying a primitive, a conclusion and a verification status; three new sections — numbering and governance, general rules, and open probes; the former section 5's conflicting and unresolved points were kept, re-hung under entry numbers. Scenario-type questions are no longer catalogued one by one; they are uniformly derived from the entries and the general rules.

### v1.1.0 2026-10-29

Section 4 gained the official positioning statement "an agent essentially completes a closed loop", and its 4.3 table gained two rows, cross-agent navigation and opening a host settings page; parenthetical notes were removed from headings throughout, with their content moved into the body text; the foreword and this change log were added.

### v1.0.0 2026-10-29

First version published in this repository. This dossier was compiled on 2026-10-24 from the official product page, the official documentation site and the aiui-dev references in the official repository; on entering the repository it was generalized, removing developer-internal working policies and traces of personal use, with the capability facts untouched.
