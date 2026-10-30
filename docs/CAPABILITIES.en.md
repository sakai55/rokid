# Rokid Glasses Capability Registry

[中文](CAPABILITIES.md) | English | [日本語](CAPABILITIES.ja.md)

English edition of the Chinese version v2.3.0, dated 2026-10-31. The Chinese text is authoritative; where the two differ, the Chinese governs.

> Compiled 2026-10-24. Current version: v2.3.0, 2026-10-31.
> Sources: **official Rokid material only** — the product pages, the documentation site, and the `yodaos-project/AIUI` GitHub repository, including the `aiui-dev` skill references bundled with it — supplemented by the maintainer's own device and build testing. Anything that rests on testing rather than documentation is flagged as such in the entry itself. The API contract comes primarily from `skills/aiui-dev` in the official repository; citations below take the form `skill: references/…`.

## About this registry

This registry is maintained by an individual Rokid AIUI developer. It is not a Rokid publication. Its job is to break the Rokid Glasses platform down into atomic entries: one entry per platform primitive, each with a stable ID, a one-line finding, its official basis, and a note on how far that finding has been verified. Before designing an agent, look up the primitives it depends on here — whether they exist, and where they stop.

The registry covers primitives, never use cases. A use case is a combination of primitives, and combinations are endless; cataloguing them would turn the document into an open-ended FAQ. Every use-case question gets the same treatment: decompose it into the primitives it needs and look each one up. Primitive present, the combination works. Primitive absent, the answer is no — and no entry gets created for the question. The official API reference is a closed list, so anything missing from it does not exist; most findings below rest on that premise.

Upkeep follows the same conventions as the error-code table in `ERROR-CODES.md`. Entries are append-only within their segment and IDs are never reused. If a finding is overturned, the entry is corrected and the change is recorded in the changelog — the ID stays. Content changes bump the version, and superseded versions are archived under `base/capabilities/` with an index. The Chinese edition is authoritative; the English and Japanese editions follow it.

## 1. IDs and governance

An ID is the letter C followed by four digits — `C2003`, say. The thousands digit is the segment; entries are numbered sequentially inside each segment.

| Segment | Area |
|---|---|
| C1xxx | Hardware and display |
| C2xxx | Camera and image |
| C3xxx | Audio, speech, and the language model |
| C4xxx | Sensors and positioning |
| C5xxx | Display runtime and pages |
| C6xxx | Storage, files, and network |
| C7xxx | Permissions |
| C8xxx | Interaction and host |
| C9xxx | Distribution and store review |

The verification column takes exactly four values. **Docs only**: the official documentation says so, but nobody has confirmed it on hardware. **Verified on device**: a real device returned the result or showed the behavior. **Verified in build / Verified in Studio**: confirmed during packaging or in the Studio workflow. **Not yet verified**: a probe exists, but its data has not come back — see section 4. Versioning: a new entry or a changed finding is a MINOR bump; a structural or rule change is MAJOR; a wording fix is PATCH.

## 2. Ground rules

The ground rules are not entries. They carry the same weight as entries when a use-case question is worked out from primitives.

- **R1 — Agents close their own loop.** Per Rokid's official position, relayed 2026-10-29: an agent, by design, completes a closed loop. Working only with the permissions it declares and the APIs it can call, an agent takes a job from start to finish inside itself. Host capabilities outside that loop — system settings, other agents, host configuration — are not handed down to agents.
- **R2 — The list is the boundary.** The official API reference is a closed list. An API, parameter, or enum value that does not appear in it is treated as nonexistent. Browser and WeChat Mini Program conventions are not evidence.
- **R3 — The interaction gate.** Capture and connection calls — taking a photo, recording audio, starting speech recognition, opening a BLE connection — require the owning view to be in the foreground, interactive state, and usually a user gesture to trigger them. Calls from a non-interactive state fail outright. Resources must be released when finished: stop microphone and camera tracks, tear down BLE scans and connections, cancel `watchPosition` with `clearWatch`, close `AudioContext`.
- **R4 — Declared is not granted.** Listing a permission in `app.json` only declares it. The system can still refuse at the call site, and code must handle the refusal path.
- **R5 — The simulator is not the device.** In the web simulator, sensor readings are mostly synthetic, and performance and thermals differ from hardware. Any entry marked Docs only stands until it is re-checked on a real device.

## 3. Entries

### 3.1 Hardware and display

Source: the official global product page, https://global.rokid.com/products/b-h-rokid-glasses-with-display, cross-checked against the same figures on the official UK site.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C1001 | SoC | Snapdragon AR1. Marketing copy on the product page mentions a dual-chip design, but the official spec table names no second chip | Docs only |
| C1002 | Memory and storage | 2 GB RAM, 32 GB storage | Docs only |
| C1003 | Display technology | Binocular Micro LED with diffraction waveguide | Docs only |
| C1004 | Display color | Monochrome green — a single green emitter channel, not full color | Docs only |
| C1005 | Panel resolution | 480 × 400 per the product spec. This sits alongside the runtime canvas figure at C5002; see open question 1 | Docs only |
| C1006 | Field of view | 30° | Docs only |
| C1007 | Brightness | 1500 nits | Docs only |
| C1008 | Camera hardware | 12 MP, stills at 3024 × 4032, f/2.25. Rokid has not published the sensor model or the camera's field of view | Docs only |
| C1009 | Microphone hardware | Four-microphone array | Docs only |
| C1010 | Speakers | Dual linear directional high-fidelity speakers | Docs only |
| C1011 | Battery and charging | 210 mAh. Rokid quotes battery life several different ways — see open question 3. Magnetic charging, 80% in 20 minutes; the charging case holds roughly ten full recharges | Docs only |
| C1012 | Wireless | Wi-Fi 6, Bluetooth 5.3 | Docs only |
| C1013 | Physical specifications | 49 g, IPX4. Temple length 155.5 mm, hinge spacing 146.3 mm, TR90 frame with titanium-alloy hinges | Docs only |
| C1014 | Prescription lenses | Diopters from +15 to −15, via Rokid's prescription service or magnetic insert frames | Docs only |
| C1015 | Camera indicator LED | Present; lights while the camera is capturing | Docs only |
| C1016 | Operating system | Name and version unpublished. The known runtime is the Ink container — see C5001 | Docs only |
| C1017 | Built-in system features | Real-time translation across 89 languages, the AI assistant, notifications, navigation, the teleprompter, notes, meeting transcription, and similar features belong to the glasses system and the official phone app. They are not APIs an agent can call. Agents get only the primitives listed in this registry | Docs only |

### 3.2 Camera and image

Sources: `skill: references/apis/media.md` and `skill: references/apis/wx.md`. Requires the permission at C7002.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C2001 | Video stream — `getUserMedia` | Returns a `MediaStream`. Constraints cover `facingMode`, `width`, `height`, `frameRate`, and `deviceId`; read the values actually granted from the track's `getSettings` | Docs only |
| C2002 | Still capture — `ImageCapture.takePhoto` | Returns an encoded `Blob`. Three modes: `wide`, a wide angle suited to barcode scanning; `telephoto`, for reading distant text; `default`, for ordinary shots. Also accepts `quality` and `enableSystemPreview` | Docs only |
| C2003 | Capture resolutions | `wide` 2016 × 2688, `telephoto` 2016 × 1512, `default` 3024 × 4032. The `Blob` carries no dimensions; decode it with `createImageBitmap` to get them | Docs only |
| C2004 | Frame grab — `ImageCapture.grabFrame` | Returns a raw `ImageBitmap`. Call `close` on it when done | Docs only |
| C2005 | wx capture — `CameraContext.takePhoto` | Returns an `ArrayBuffer` plus a `mimeType`. There is no mode parameter; modes live on the C2002 path. The call must be made from an interaction-gate call site | Docs only |
| C2006 | Recording — `MediaRecorder` | Records audio and video streams. For video MIME types, trust `isTypeSupported`; the known-good values are `video/webm;codecs=vp8,opus` and `video/mp4` | Docs only |
| C2007 | Barcode detection — `BarcodeDetector` | Call `getSupportedFormats` first to learn which symbologies are supported. `detect` accepts `ImageData`, an encoded image `Blob`, or an `ImageBitmap`, and returns `format`, `rawValue`, `boundingBox`, and `cornerPoints` | Docs only |
| C2008 | OCR | No OCR API exists. Reading text means taking a `telephoto` photo and passing the image to the model — see C3016 | Docs only |
| C2009 | Continuous frame access | The documentation states no frame-rate ceiling and says nothing about background behavior. Whether a `getUserMedia` stream and repeated `grabFrame` calls hold up over time is awaiting probe results — see section 4 | Not yet verified |
| C2010 | Text and face detection | `TextDetector` and `FaceDetector` do not exist. Neither appears anywhere in the official API list | Docs only |

### 3.3 Audio, speech, and the language model

Sources: `skill: references/apis/media.md` and `skill: references/apis/ai.md`. Recording requires the permission at C7003.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C3001 | Capture source — `captureSource` | Either `microphone` or `system-audio`, the latter capturing system sound internally. `system-audio` cannot be combined with `echoCancellation` or `microphoneMode`; doing so raises `OverconstrainedError`. System sound never falls back to the microphone on its own | Docs only |
| C3002 | Microphone mode — `microphoneMode` | Four modes: `wearer`, which favors the wearer; `far-field`; `near-field`; and `omnidirectional`. Modes apply to streams you capture through `getUserMedia` only. Device support is not guaranteed — an unsupported mode raises `OverconstrainedError` — and the mode in effect is read back from `getSettings` | Docs only |
| C3003 | Microphone modes and host recognition | Modes affect only streams you capture yourself. Host speech recognition runs on the host microphone and ignores the setting entirely | Docs only |
| C3004 | Recording formats — `MediaRecorder` | Audio: `audio/wav` and `audio/ogg;codecs=opus` | Docs only |
| C3005 | wx recording — `RecorderManager` | `start`, `pause`, `resume`, `stop`, plus frame callbacks. Uses the default microphone; there are no source or mode parameters. For mode control, use C3001 and C3002 | Docs only |
| C3006 | Speech synthesis — `speechSynthesis.speak` | Synthesizes and plays in one call, queued through the runtime's shared player. Mode is `enqueue`, the default, or `immediate` | Docs only |
| C3007 | Speech synthesis — `speechSynthesis.synthesize` | Synthesizes without playing and returns an abortable task. Options include caption granularity — `none`, `sentence`, or `word` — audio format (`pcm`, `mp3`, `ogg_opus`), sample rate, channel count, and bitrate. Play the result separately with `SpeechAudioPlayer` | Docs only |
| C3008 | Built-in voices | Eleven fixed voice IDs: `female-tianmei`, `English_radiant_girl`, `English_expressive_narrator`, `male-qn-qingse`, `male-qn-jingying`, `female-yujie`, `Chinese (Mandarin)_News_Anchor`, `Chinese (Mandarin)_Radio_Host`, `clever_boy`, `lovely_girl`, `English_Trustworthy_Man`. There is no `getVoices` | Docs only |
| C3009 | Synthesis controls | The utterance `lang` attribute is inert — it does not change the language of the output. There is no cancel, pause, or resume. `pitch`, `rate`, and `volume` all default to 1 | Docs only |
| C3010 | wx speech — `wx.speech.playTTS` | Speaks a single sentence. Returns a request ID string, or an empty string on failure | Docs only |
| C3011 | Speech recognition — `SpeechRecognition` | Runs on the host microphone. Properties: `lang`, `continuous`, `interimResults`, `maxAlternatives`. `start` requires the view to remain interactive, otherwise `InvalidStateError`. With `lang` empty, the host picks a default language | Docs only |
| C3012 | Speech recognition — `SpeechRecognitionSession` | Recognizes an external audio stream; the session itself opens no microphone. Supports hotword `phrases` with `boost`, `auto` segmentation, `vad`, `semantic`, and `updateContext` for dynamic context. Query `getCapabilities` first to learn what the host actually supports | Docs only |
| C3013 | Recognition error values | Rokid publishes no enumeration for the `error` event's category values. Branching error handling on those values is an unverified assumption — do not build on it | Docs only |
| C3014 | Model availability — `LanguageModel.availability` | Returns `available` or `unavailable`, nothing more. Provider, model list, and endpoints are not exposed | Docs only |
| C3015 | Model session — `LanguageModel.create` | Under the hood this is the host's OpenAI-compatible chat-completions channel, streaming. Model resolution order: an explicit `model` first, then the host's `defaultModel`. A `system` prompt may appear only as the first entry of `initialPrompts` | Docs only |
| C3016 | Multimodal model input | A user message's `content` array accepts `text` and `image_url` parts, and an image may be given as a `data:` URL. Structured content is supported for the user role only | Docs only |
| C3017 | Model tool calls | `tools` are forwarded into the provider request body. Invocations come back as `toolcall` events on the session, carrying `callId`, `functionName`, and `arguments`. Nothing executes automatically, and no structured round-trip protocol is guaranteed | Docs only |
| C3018 | Model requests — `prompt` and `promptStreaming` | Streaming is read by polling. It is neither a WHATWG stream nor an async iterator. A session allows one request in flight at a time, and after `destroy` the session is unusable | Docs only |
| C3019 | Audio playback — `AudioPlayer` | General-purpose player for files bundled in the package or remote URLs. Supports streaming append playback in `pcm` and `ogg_opus`, plus caption text tracks | Docs only |
| C3020 | Sound effects — `Sound` | Short playback of bundled sound files. Local files only; `http` and `https` URLs are rejected | Docs only |
| C3021 | Web Audio | `AudioContext` is available, along with `createBuffer`, `Oscillator`, `Gain`, `BiquadFilter`, `Analyser`, `MediaStreamSource`, and `decodeAudioData` — enough for waveform and spectrum work | Docs only |

### 3.4 Sensors and positioning

Sources: `skill: references/apis/device.md`, `skill: references/apis/geo/geolocation.md`, and the official IMU guide. Positioning requires the permission at C7001.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C4001 | Accelerometer | Three-axis acceleration `x`, `y`, `z` plus a `timestamp`. Events: `activate`, `reading`, `error`. The constructor's `frequency` argument is a best-effort hint to the host, not a guarantee | Docs only |
| C4002 | Gyroscope | Three-axis angular velocity `x`, `y`, `z` plus a `timestamp`. Events and `frequency` semantics as at C4001 | Docs only |
| C4003 | Absolute orientation — `AbsoluteOrientationSensor` | Absolute-orientation quaternion `[x, y, z, w]` plus a `timestamp`. Availability depends on the device's hardware | Docs only |
| C4004 | Sampling rates | No maximum frequency and no accuracy figures are published. Examples in the official guide use 60 Hz and suggest starting between 30 and 60 Hz | Docs only |
| C4005 | Other sensors | Magnetometer, ambient light, and proximity have no dedicated APIs. None of them appears in the official list | Docs only |
| C4006 | Head gestures — `onHeadGesture` | Requires `enableWorldAwareness` to be switched on in the Page. The only gesture value shown anywhere in the official examples is `nod`; the full enumeration is unpublished — see open question 7 | Docs only |
| C4007 | Head stability — `onOrientationStabilityChange` | Also requires world awareness. `event.stable` reports changes in how steady the wearer's head is | Docs only |
| C4008 | Eye tracking | None. What passes for gaze is head orientation (C4003), combined with head stability (C4007) and nod (C4006) | Docs only |
| C4009 | Geolocation | `getCurrentPosition` and `watchPosition`, with `clearWatch` to release a watch. `coords` carries `latitude`, `longitude`, and `accuracy` in meters, plus nullable `altitude`, `altitudeAccuracy`, `heading`, and `speed`. Options: `enableHighAccuracy`, default `false`; `timeout`; `maximumAge`. Error codes: 1 permission denied, 2 position unavailable, 3 timeout | Docs only |
| C4010 | GPX — `GPXDocument` | Parses, builds, and exports GPX routes: `setStartPoint`, `addWaypoint`, `appendTrackPoint`, `toString`, `toBlob`. Routes render through the `map` and `map-gpx` components | Docs only |
| C4011 | Bluetooth — BLE central | Central role only: `getAvailability`, `getDevices`, `requestDevice`, `scanDevices` (Ink-specific), GATT `connect`, `readValue`, `writeValue`, `startNotifications`. `requestDevice`, `scanDevices`, `connect`, and `startNotifications` all require an interactive view | Docs only |
| C4012 | Bluetooth peripheral mode | None. The official list has no peripheral or advertising capability | Docs only |

### 3.5 Display runtime and pages

Sources: `skill: references/framework.md`, `skill: references/apis/window.md`, `skill: references/apis/canvas.md`, `skill: references/events.md`, and the official documentation on the runtime environment.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C5001 | The Ink runtime | Logic and view layers run in Ink, Rokid's own container built on QuickJS and Skia. Language level ES2023; modules are ESM | Docs only |
| C5002 | Reference canvas | A full-screen Page uses a 480 × 352 reference canvas. Safe margins are 16 px on the left and right and 12 px top and bottom, leaving an effective content width of 448 px | Docs only |
| C5003 | Designing for monochrome green | Base color `#40ff5e`, with a six-step brightness scale. Black renders as transparency, so an opaque black panel cannot be relied on to block out the real world. Never carry meaning by color alone — pair it with icons, text, or line style. Keep body text at 72% brightness or above, decorative lines at 24% or below, and key information inside the comfortable central field of view | Docs only |
| C5004 | Viewport size | `window.innerWidth` and `window.innerHeight`, read-only, in logical pixels | Docs only |
| C5005 | Widget sizes | The size families are 1x1 at 239 × 140 and 1x2 at 480 × 140, and the glasses hold four widget slots. A family is only a size class — never hard-code the root node to those pixel values | Docs only |
| C5006 | Opening UI — `window.open` | Opens only widgets declared in `app.json`. The sole target is `_widget`; overlays are supported. It cannot open another Page or an external URL | Docs only |
| C5007 | Closing the instance — `window.close` | Asks the host to close the current agent instance | Docs only |
| C5008 | Jumping to another agent | No such capability exists. The official list contains no `openAgent`-style entry, and `wx.navigateTo` reaches only pages inside the same agent. See ground rule R1 | Docs only |
| C5009 | Opening a host settings page | Unreachable — no API does this. Intents of the "open the such-and-such settings" kind are carried out by the host itself, and only as far as opening the app. See ground rule R1 | Docs only |
| C5010 | Project layout | `app.json`, `app.js`, `AGENTS.md`, and `pages`. A page is either a single `.ink` file or the four-file set of `.json`, `.wxml`, `.wxss`, and `.js`. Optional: `widgets`, `workers`, `components`, `assets` | Docs only |
| C5011 | Built-in components | 37 authorable tags in all, spanning containers, text, forms, media, maps, canvas, charts, and `a2ui` for generated UI | Docs only |
| C5012 | Agent Worker | A script with no UI, launched through `open`. Lifetime is `instant` or `foreground`; `background` is reserved and has no effect. Timers, Promises, Crypto, Wasm, and encoding streams are available. There is no `window`, `document`, `fetch`, routing, rendering, or media capture | Docs only |
| C5013 | Languages and modules | TypeScript entry points and WebAssembly modules are supported, through the project's packaging pipeline | Docs only |
| C5014 | Canvas 2D | Paths, rectangles, text including `measureText`, transforms, gradients, patterns, and `drawImage` in its 3-, 5-, and 9-argument forms only. Color parsing accepts `#rrggbb`, `#rgb`, `rgb`, `rgba`, and a handful of named colors. Output goes through `convertToBlob` and `createImageBlob`; `canvas.toDataURL` does not exist | Docs only |
| C5015 | WXML templates | `template` is not supported | Docs only |
| C5016 | Conversation-stream cards | Display-only by default. Interactive UI needs a full-screen Page or a widget | Docs only |
| C5017 | Device identity — `navigator` | `id` is an opaque identifier bound to the agent and the device; do not treat it as a credential. `userAgent`, `versions.ink`, and `versions.skia` give version strings. `language`, `languages`, and `region` may be empty. `onLine` and `connection` report connectivity and a connection estimate. `renderingEnabled` says whether the current instance can render | Docs only |
| C5018 | Battery — `getBattery` | Returns a Promise for a `BatteryManager`. On a host without battery capability the Promise rejects. The documentation is thin — see open question 8 | Docs only |
| C5019 | Serial number and device token | `getDeviceSerialNumber` and `requestDeviceToken` serve system-level agents only. Ordinary agents get an empty string back, or must not rely on them at all | Docs only |
| C5020 | Global encoding helpers | `window.atob`, `btoa`, and a global `createImageBlob` are available. `createImageBlob` encodes PNG and JPEG | Docs only |

### 3.6 Storage, files, and network

Sources: `skill: references/apis/web.md`, `skill: references/apis/wx.md`, and the official networking guide.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C6001 | Local storage — `localStorage` | String key–value storage, isolated per agent: `getItem`, `setItem`, `removeItem`, `clear` | Docs only |
| C6002 | wx storage | `setStorage`, `getStorage`, `removeStorage`, `clearStorage`, plus synchronous `Sync` variants. Values pass through JSON serialization | Docs only |
| C6003 | OPFS — `navigator.storage` | Per-agent private file storage, independent of `localStorage` and the wx store. `estimate()` reports current usage and quota; the quota is a runtime value and Rokid publishes no figure for it. `persisted()` reports the persistence state, `persist()` requests persistence, and `getDirectory()` returns the root directory. Directory and file handle methods must be called with an options argument — the QR capacity probe measured the Ink bridge rejecting one-argument calls with an error stating that 2 arguments are expected. Files are written through `createWritable()` and committed on `close()`. On a host with no OPFS backend, calls fail with `NotSupportedError`. What ships is a practical subset, not the full File System Access API. Source: the OPFS page in the official documentation | Docs only |
| C6004 | General-purpose file system | None. Resources resolve from paths inside the project only; there is no API to read, write, or list arbitrary paths | Docs only |
| C6005 | `FileReader` | Does not exist. On hardware it always throws `FileReader is not defined`. To turn a `Blob` into a data URL, use `blob.arrayBuffer` and base64-encode it in chunks with `btoa`. Related error code: E2005 | Verified on device |
| C6006 | Browser APIs confirmed absent | None of the following exist in the Ink runtime, and using any of them in code is a defect: `sessionStorage`, `XMLHttpRequest`, `URL.createObjectURL`, `DOMParser`, `structuredClone`, `queueMicrotask`, `Notification`, the clipboard API, `IntersectionObserver`, `MutationObserver`, `ServiceWorker`, `new Worker`, `OffscreenCanvas`, `getDisplayMedia`, `applyConstraints`, `getVoices`, `navigator.permissions` | Docs only |
| C6007 | `fetch` and the web platform surface | Available: `fetch`, `Headers`, `Response` including streaming body reads, `WebSocket`, `File`, `FormData`, `URL` and `URLSearchParams`, and the Streams family in full | Docs only |
| C6008 | wx networking | `wx.request` resolves its timeout in this order: `options.timeout`, then the `app.json` setting, then a default of 60000 ms. Also available: `wx.createSocket` and `connectSocket`, and `wx.createEventSource` for server-sent events | Docs only |
| C6009 | Web Crypto | `randomUUID` and `getRandomValues`, the latter capped at 65536 bytes, are available. `subtle` offers digests only — SHA-1, SHA-256, SHA-384, SHA-512 — plus HMAC. Encryption, decryption, RSA, ECDSA, and JWK are not supported | Docs only |
| C6010 | Networking through the phone | When the glasses have no Wi-Fi but Bluetooth is linked to the phone app, `fetch` and `wx.request` are forwarded over the phone connection automatically. The developer does nothing to enable this | Docs only |
| C6011 | HTTPS and the domain allowlist | In production, network requests must go over HTTPS. Before an agent can be listed in the store, every domain it calls must be registered on the allowlist in the developer console | Docs only |
| C6012 | Direct LAN access | Not supported. The official guide describes it as in development, and the documentation index marks the topic unsupported | Docs only |
| C6013 | Data prefetch | `prefetch` is not supported | Docs only |
| C6014 | Source-map debugging | Not supported | Docs only |

### 3.7 Permissions

Source: the permissions table in the official framework documentation, `app-json.md`, as corrected by a full audit on 2026-10-29. There are seven permissions. Names are case-sensitive, and an unrecognized name grants nothing. Note also the upstream inconsistency recorded at C7008.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C7001 | `GEOLOCATION` | Current position and position updates — see C4009 | Docs only |
| C7002 | `CAMERA` | Camera access; stills and video capture — see section 3.2 | Docs only |
| C7003 | `RECORD_AUDIO` | Microphone access and audio capture. Speech recognition depends on this permission to open the microphone; there is no separate ASR permission. The legacy `SPEECH_RECOGNITION` was removed in Ink 0.19 | Docs only |
| C7004 | `READ_MEDIA_IMAGES` | List and read images in the system media library | Docs only |
| C7005 | `CREATE_MEDIA_IMAGES` | Add images to the system media library. Modifying or overwriting existing assets is not included | Docs only |
| C7006 | `READ_MEDIA_AUDIO` | List and read audio in the system media library | Docs only |
| C7007 | `CREATE_MEDIA_AUDIO` | Add audio to the system media library. Modifying or overwriting existing assets is not included | Docs only |
| C7008 | The permission list in the upstream docs | The framework reference bundled with the `aiui-dev` skill still lists only the first three permissions — an inconsistency inside the upstream documentation itself. The seven names in the formal framework document govern | Docs only |

### 3.8 Interaction and host

Sources: `skill: references/events.md` and the operating guide built into the Hi Rokid app, whose account of the gestures reflects actual device behavior.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C8001 | Wake-up — `onVoiceWakeup` | Triggered by voice or by touch. Known `event.keyword` values: `乐奇`, `Hi Rokid`, and `clickAiAssist` for touch wake-up. Do not filter on `keyword` unless you have a reason to. `event.preventDefault` takes over the host's default action | Docs only |
| C8002 | Key events | `onKeyDown` and `onKeyUp` on a Page dispatch by `event.code`: `Enter` confirms, `Backspace` goes back, `ArrowUp` and `ArrowDown` scroll, and `GlobalHook` is a device-specific signal for temple touch. The host's default action fires after `onKeyUp` | Docs only |
| C8003 | Single-finger tap | Confirm — equivalent to `Enter` | Docs only |
| C8004 | Single-finger double tap | Back — equivalent to `Backspace`. With no page to go back to, it asks the host to close the agent | Docs only |
| C8005 | Single-finger swipe | Scroll — equivalent to `ArrowUp` and `ArrowDown`. Direction can be reversed in the app | Docs only |
| C8006 | Single-finger long press | Wakes the assistant. The app chooses between the glasses' AI assistant and the phone assistant | Docs only |
| C8007 | Two-finger double tap | Turns the display off | Docs only |
| C8008 | Two-finger swipe, front to back | Volume up and down, by default; remappable in the app | Docs only |
| C8009 | Two-finger long press — AI shortcut | Sends a single preset instruction to a chosen trigger target; the text is capped at 500 characters. The target can be one specific custom or debug agent, which makes this a deterministic delivery path to a named agent — fixed text, no speech recognition involved | Verified on device |
| C8010 | Context gestures | While music plays: tap pauses or resumes, a front-to-back swipe changes track. On a call: a double tap rejects an incoming call, a tap mutes or unmutes mid-call, a double tap hangs up | Docs only |
| C8011 | Buttons wired to tap only | A button that binds only `bindtap` cannot be triggered by gesture on the glasses. Pages must map keys to their own actions; button clicks alone are not enough | Verified on device |
| C8012 | Where voice wake-up fails | Fixed-phrase wake-up fails at the speech-recognition stage — the phrase is misheard — not at the matching stage after a correct transcription. Shorter or more regular agent names ease the transcription problem but cannot sidestep it. For a deterministic entry point, see C8009 | Verified on device |
| C8013 | The companion phone app | Beyond the network relay covered at C6010, the app handles device management and settings, media management, entry points to the AI features, and delivery of resource packages to the glasses | Docs only |

### 3.9 Distribution and store review

Sources: the official publishing guide, `publish.md`, and the AIX documentation. The import behavior below is the maintainer's own finding from Global AIUI Studio on 2026-10-24.

| ID | Primitive | Finding | Verification |
|---|---|---|---|
| C9001 | Distribution format — AIX | AI eXecutable, following the Open Agent Format: code, configuration, and static assets in one self-contained package. Packaging generates a `VERSION` file with a unique UUID for version verification | Docs only |
| C9002 | Package size limit | Rokid publishes no figure | Docs only |
| C9003 | Packaging exclusions — `.aixignore` | `.agents`, `.aix`, `artifacts`, `*.aix`, `skills-lock.json`, and `node_modules` must be excluded, or development files ship in the package. Measured effect: a package ballooning from 2.3 KB to 107 KB | Verified in build |
| C9004 | Studio import behavior | The import dialog takes a single URL. Everything after `/tree/` is read as one ref, so a URL pointing into a subdirectory fails to import, and a repository-root URL imports to an empty code tree. A single-segment branch name with one agent's files complete at the branch root imports cleanly as a full project | Verified in Studio |
| C9005 | Review red lines | Name: required, at most 20 characters, unique, and free of testing vocabulary such as test or beta and of superlative claims. Icon: required, and the default icon is not acceptable. Feature description: at most 500 characters. Opening message: required, 300 characters or fewer recommended. Preview media: 3 to 5 files, at least one image and one video, video no longer than 60 seconds. Every permission must come with a stated purpose | Docs only |
| C9006 | Review declarations | The Studio review form carries its own set of declaration checkboxes — network, camera, microphone, speaker, Rokid account information, and the like. These are a separate mechanism from the declared permissions in section 3.7 | Docs only |
| C9007 | Release process | Build, try in the web simulator, package as AIX and upload to the cloud, debug on a device, complete the review materials, submit for review | Docs only |
| C9008 | Versions and IDs | The version number and the Agent ID are both system-generated. Developers cannot edit either | Docs only |

## 4. Open probes

A probe is a test build put together to settle one or more entries. This section lists only the probes and the entry IDs each one speaks to. Once a probe's data is in, its findings are written back into the entries, the verification column is updated, and the probe's row here is removed.

| Probe | Entries it verifies | Status |
|---|---|---|
| Capability benchmark agent — 23 checks, one per platform primitive | C2002, C2004, C3002, C3011, C4001 through C4007, C5002, and others | Built; the device re-test has not been completed |
| Audiovisual capture series — ten agents, each probing one audiovisual boundary | C2002, C2004, C2006, C2007, C3001, C3002, C3021 | Built; the hardware chain is waiting on device results |
| Stop-motion agent with a log-return client | Re-checks C6005, and tests whether error logs can be returned over an external channel | Built; waiting on one device run |
| Tracing probes — one for hand seals, one for sign language | Whether C3016 image input is usable for still-frame judging, and how often it is right | Built; device data will decide what the full versions include |
| Continuous video stream probe | C2009 | Approved, not yet run |
| Recognition error-value collection | C3013 | Compare the raw error output once each error type has been triggered on a device |
| Storage probe: roundtrip self-checks and capacity ramps for all three stores; the OPFS station reads the estimate() quota and persistence state; a cross-session marker verifies that saves survive restarts | C6001 through C6003 | Built; device run pending |
| QR capacity probe: text-capacity boundaries per error-correction level across encoding, file-roundtrip decoding and camera decoding | C2007; also C6003, C2002 | Built; encoding verified (level L reaches the 2,953-byte spec ceiling), roundtrip and camera legs await a device run |

## 5. Open questions and contradictions

None of the following are entries. Each is a place where Rokid's own sources disagree with each other or say nothing at all. They hang under the entries they touch until an official answer or a test settles them, at which point they fold into an entry or are deleted.

1. Two resolution figures coexist: 480 × 400 in the product spec (C1005) and a 480 × 352 runtime canvas (C5002). Rokid has not explained how the two relate.
2. Third-party claims of a 23° field of view and a 640 × 480 resolution are both unconfirmed by Rokid. C1006 and C1005 govern.
3. Battery life is quoted several ways on a single product page: the FAQ says 8 to 10 hours of daily use, the comparison table says 6 hours of mixed use and 30 hours with the charging case, and no common test conditions are stated (C1011).
4. The second chip in the dual-chip marketing line is never named in the official spec (C1001).
5. The camera's sensor model and field of view are unpublished (C1008).
6. The IMU's axis count, chip model, sampling-rate ceiling, and accuracy are unpublished (C4001 through C4004).
7. The full enumeration of head gestures is unpublished (C4006).
8. The `getBattery` documentation is incomplete: the `navigator` reference defers to a device reference for the battery methods, and that reference has no such section (C5018).
9. Hardware generations differ: for Rokid Glasses 2 and the first-generation full-color glasses, the official events reference marks the key mappings unverified. Do not assume the mappings in section 3.8 carry over.
10. The official documentation runs on two tracks: open.rokid.com/aiui is current and js.rokid.com is older, and the two have never been diffed page by page. This registry follows the official repository's documentation and the `aiui-dev` skill.
11. The package size limit, the exact place to file domains for the allowlist, and review turnaround times are all unspecified in official material (C9002, C6011).
12. The media-library operation surface is undocumented: the four media permissions are defined in the app.json permission table (C7004 through C7007), but no official document names the API for listing, reading or saving media-library assets — the table says only that the relevant operations check the permission. Establish the operation surface before building album features, and never assume a same-named API from another platform.

## 6. Official sources

**Product and platform**

- Rokid Glasses, official global product page — the primary source for specifications: https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid UK, AI product line — specification cross-check: https://gb.rokid.com/collections/rokid-ai-lineup
- Official Academy tutorial, 3.6 Glasses AIUI: https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**Documentation site**

- AIUI documentation, current: https://open.rokid.com/aiui
- AIUI documentation, earlier version: https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**The yodaos-project/AIUI GitHub repository**

- Repository home: https://github.com/yodaos-project/AIUI
- The `aiui-dev` skill — primary source for the API contract: https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- Review and publishing: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- What AIX is: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- Runtime environment: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU guide: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- Networking notes: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- Documentation index, including the unsupported markings for topics such as LAN access, prefetch, and source maps: https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json

## 7. Changelog

### v2.3.0 — 2026-10-31

Section 4 gains the QR capacity probe: qr-capacity-probe is built (base/qr-capacity-probe in the repository) and measures the three boundaries of QR-carried text — encoding, file-roundtrip decoding and camera decoding — across all four error-correction levels, verifying C2007 and touching C6003 and C2002. The encoding leg is already measured (level L reaches the byte-mode spec ceiling of 2,953 bytes); the roundtrip and camera legs await device numbers. Entry C6003 gains one measured constraint: directory and file handle methods must be called with an options argument, and the Ink bridge rejects one-argument calls (measured by the QR capacity probe).

### v2.2.0 — 2026-10-30

Section 4 gains the storage probe: storage-probe is built (base/storage-probe in the repository) and verifies C6001 through C6003 — roundtrip correctness and practical capacity for all three stores, the OPFS runtime quota, and save survival across restarts via a cross-session marker. Once device numbers return, the entry conclusions and verification states will be updated and this row retired. Section 5 gains item 12: the four media permissions are defined in the app.json permission table (C7004 through C7007), but no official document names the API for listing, reading or saving media-library assets.

### v2.1.0 — 2026-10-30

C6003 corrected. The OPFS page in the official documentation documents the full `navigator.storage` surface; the entry previously followed the one-line summary in the aiui-dev references and said no method details were published, which is not accurate. The entry now follows the OPFS page, and records that the quota exists only as a runtime value, with no published figure. Open question 9 (StorageManager method details) is resolved and removed, the remaining questions are renumbered, and the in-entry question references — which had drifted one position off — are realigned (C1011, C4006, C5018).

### v2.0.0 — 2026-10-29

Restructured as an atomic registry. The document was recast across the nine segments as 123 numbered entries, each with a primitive, a finding, and a verification status. Three sections are new: IDs and governance, the ground rules, and open probes. The contradictions and gaps formerly collected in section 5 were kept and re-hung under their entry IDs. Use-case questions are no longer given entries of their own; they are answered by deriving them from entries and ground rules.

### v1.1.0 — 2026-10-29

Section 4 took in Rokid's official positioning — an agent essentially completes a closed loop — and its table at 4.3 gained two rows: jumping to another agent, and opening a host settings page. Parenthetical qualifications were removed from headings throughout and their content moved into the body. The foreword and this changelog were added.

### v1.0.0 — 2026-10-29

First edition published in this repository. The underlying dossier was compiled on 2026-10-24 from the official product pages, the documentation site, and the `aiui-dev` references in the official repository. On publication it was generalized: developer-internal working rules and traces of personal use were removed. The capability findings themselves were not touched.
