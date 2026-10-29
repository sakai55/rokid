# Rokid Glasses Capability Dossier (Official Sources Edition)

[中文](CAPABILITIES.md) | English | [日本語](CAPABILITIES.ja.md)

Translated from the Chinese version (last updated 2026-10-29). In case of conflict, the Chinese version prevails.

> Compiled: 2026-10-24; last updated: 2026-10-29
> Source policy: **official Rokid sources only** (official product pages, the official documentation site, the official GitHub repository `yodaos-project/AIUI` and the `aiui-dev` skill reference bundled with it). Every non-trivial claim is annotated with its source.
> Annotation convention: **** = stated explicitly in the text of an official page/document; **** = reasonably inferred from the presence/absence of official API documentation, and flagged as such; **Not officially published** = not found in any of the official sources consulted, and never guessed.
> Unified citation for the local skill reference: the official repository's `skills/aiui-dev` (https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev); citations below are written as `skill: references/…`.

---

## 1. Hardware Specifications

Primary source of record: the official global product page: https://global.rokid.com/products/b-h-rokid-glasses-with-display
(The specifications on the official UK site, https://gb.rokid.com/collections/rokid-ai-lineup, corroborate it.)

| Item | Specification | Notes |
|---|---|---|
| SoC | Snapdragon AR1 (Qualcomm) | The product page's Performance section says only "Snapdragon AR1", with no generation suffix; the page also carries a "Dual-Chip Performance" tagline, but the official spec table does not list a model for the second chip |
| RAM / storage | 2 GB / 32 GB | |
| Display technology | Binocular Micro LED + diffractive waveguide (Binocular Micro LED waveguide); the optical design is "1 Micro LED + waveguide" | |
| Display color | **Monochrome green** (Single green display) | Not full color; the AIUI design specification likewise defines a single green emissive channel (`skill: references/design/monochrome-green.md`) |
| Display resolution | **480 × 400** | ⚠️ Inconsistent with the AIUI runtime reference canvas of 480 × 352; see Section 5 |
| FOV | 30° | |
| Brightness | 1500 nits | |
| Camera | 12 MP, photo resolution 3024 × 4032, aperture F2.25 | Marketing copy on the product page calls it a "Sony sensor", but the spec table gives no sensor model; camera FOV not officially published |
| Photo formats | 4K 3:4, 4K 9:16, 3K 4:3 | |
| Video formats | Up to 3K 30fps (9:16); also 2.5K 30fps (3:4 / 4:3), 2K 30fps (9:16 / 9:19.5) | |
| Microphones | **4-microphone array** | |
| Speakers | Dual linear directional high-fidelity speakers | |
| Sensors | IMU: Supported | The official product page does not publish the IMU's axis count or model; the sensors callable from AIUI are listed in 2.7 |
| Battery | 210 mAh | Battery-life figures vary; see below |
| Battery life | The FAQ claims about **8–10 hours** of daily use; the comparison table on the same page claims **up to 6 h mixed use**, and **up to 30 h** with the charging case | |
| Charging | Magnetic charging; fast charge to 80% in 20 minutes; the charging case can fully charge the glasses about 10 times; an optional Power Capsule accessory is also available | |
| Wireless connectivity | Wi-Fi 6, Bluetooth 5.3 (BT 5.3) | |
| Weight | 49 g | |
| Dimensions | Temple length 155.5 mm, hinge spacing 146.3 mm, lens width 49 mm, frame height 44.4 mm | Frame material TR90, hinges titanium alloy |
| Ingress protection | IPX4 | |
| Wake word | "Hi Rokid" | For the Chinese wake word, see 3.1 (runtime documentation) |
| Prescription support | Supports prescriptions from +15 to −15 diopters; official prescription service + magnetic prescription frame | |
| System / OS | **Not officially published** | Neither the product page nor the documentation names the glasses' operating system or version; what is known is that the agent runtime is the in-house Ink container (QuickJS + Skia); see 2.1 and https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md |
| Camera indicator light | Supported (Camera indicator: supported) | Lights up while capturing; a privacy design feature |

### 1.1 Official Feature List (product level, not Agent APIs)

Features listed on the official product page for the device as a whole: real-time translation (89 languages supported), 13 UI languages, an AI assistant (Voice AI + Vision AI, with models such as Qwen and ChatGPT mentioned), notifications (visual + audio), navigation, a teleprompter, notes, meeting transcription, SDK support.
Note: these are **features of the glasses system / official app**, not APIs callable by AIUI Agents (see Section 2).

---

## 2. AIUI Runtime Capabilities (APIs an Agent Can Actually Call)

Runtime environment: on Rokid Glasses, an agent's logic layer and view layer run inside **Ink**, an in-house container built on **QuickJS** (JS engine) and **Skia** (rendering), optimized for the low power / memory / CPU budgets of wearable devices. Source: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
The API contract follows the skill reference cited below (`skill: references/apis/*.md`); that skill is the development contract document shipped with the official repository.

### 2.1 Device Information and System State (`navigator`)

Source: `skill: references/apis/navigator.md`

| API | Capability | Limits / notes |
|---|---|---|
| `navigator.id` | An opaque ID bound to the agent + device | Generally stable across ordinary restarts/upgrades; must not be used as a credential |
| `navigator.userAgent` / `versions.ink` / `versions.skia` | Runtime and rendering-engine version strings | |
| `navigator.language` / `languages` / `region` | Language preferences (BCP 47) and region | May be empty strings |
| `navigator.renderingEnabled` | Whether the current instance can render a visible UI | |
| `navigator.onLine` / `navigator.connection` | Online state and connection info: `type` (none/wifi/ethernet/cellular/bluetooth/other/unknown), `effectiveType`, `downlink`, `rtt`, `saveData`, plus the `change` event | Estimates only; does not guarantee service reachability; when relayed over the phone's Bluetooth link, `type` may report `bluetooth` |
| `navigator.getBattery()` | Returns `Promise<BatteryManager>` | The promise is rejected when the host has no battery capability; ⚠️ the navigator reference says the battery methods are in the device reference, but the device reference actually has no battery section (see Section 5) |
| `navigator.getDeviceSerialNumber()` | Device serial number | Available to **system-level agents only**; ordinary agents get an empty string |
| `navigator.requestDeviceToken()` | Device token | **System-level agents only**; ordinary agents must not rely on it |

### 2.2 Display and Windows (`window`)

Sources: `skill: references/apis/window.md`, `skill: references/framework.md`

- `window.innerWidth` / `innerHeight`: read-only viewport size (logical pixels).
- Full-screen Page reference canvas: **480 × 352 px** (defined by the design specification; target devices RokidGlasses1 / RokidGlasses2), with safe margins of 16 px left/right and 12 px top/bottom, for an effective content width of 448 px. Source: `skill: references/design/monochrome-green.md`
- Widget (home-screen widget) size family: `1x1` = 239 × 140, `1x2` = 480 × 140; the glasses have **4 Widget grid slots** in total. `family` is only a size category; the root node must not be hard-coded to those pixel values.
- `window.open(url, '_widget')`: can only open Widgets declared in `app.json` (the only target is `_widget`; `placement: 'overlay'` is supported); it cannot open other Pages or external URLs.
- `window.close()`: asks the host to close the current agent instance.
- `window.atob/btoa`, and the global `createImageBlob(bitmap, …)` (PNG/JPEG encoding).

### 2.3 Camera

Sources: `skill: references/apis/media.md`, `skill: references/apis/wx.md`. The `CAMERA` permission must be declared.

| API | Capability | Key parameters / limits |
|---|---|---|
| `navigator.mediaDevices.getUserMedia({video})` | Acquire a video stream (MediaStream) | Constraints support `facingMode`, `width`, `height`, `frameRate`, `deviceId`; read the final values from `track.getSettings()` |
| `ImageCapture.takePhoto(options?)` | Take a photo; returns the encoded `Blob` | **Three modes**: `mode: 'wide'` (wide angle for barcode scanning), `mode: 'telephoto'` (telephoto for reading distant text), `mode: 'default'` (ordinary photo); also `quality` and `enableSystemPreview` options |
| Default photo output sizes | wide = 2016 × 2688; telephoto = 2016 × 1512; default = 3024 × 4032 | May differ from the video stream size; the Blob itself carries no width/height, so decode it with `createImageBitmap()` |
| `ImageCapture.grabFrame()` | Returns an unencoded `ImageBitmap` pixel frame | The bitmap must be closed after use |
| `wx.media.createCameraContext().takePhoto()` | wx-style photo capture; returns `{ data: ArrayBuffer, mimeType}` | Must be triggered from an interactive call site (the interactive gate); no mode-selection parameter (mode selection goes through the Web `ImageCapture`) |
| `MediaRecorder` | Record audio/video streams | Supports `video/webm;codecs=vp8,opus`, `video/mp4`, etc. (check with `isTypeSupported()` first) |

### 2.4 Microphone and Recording

Source: `skill: references/apis/media.md`. The `RECORD_AUDIO` permission must be declared, and capture must originate from a valid user interaction.

| API / parameter | Capability | Key limits |
|---|---|---|
| `getUserMedia({audio:{captureSource}})` | Recording source selection: `'microphone'` (the microphone) or `'system-audio'` (the device's playback mix, i.e. internal system-audio capture) | system-audio cannot be combined with `echoCancellation: true` or `microphoneMode`, otherwise `OverconstrainedError`; system audio does not automatically fall back to the microphone |
| `microphoneMode` (microphone mode) | **Four modes**: `'wearer'` (default; prioritizes the wearer's voice), `'far-field'` (distant sounds), `'near-field'` (nearby sounds), `'omnidirectional'` (no directional preference) | Applies to the microphone source only; device support for each mode is not guaranteed — unsupported modes raise `OverconstrainedError`; read the effective value from the track's `getSettings()` |
| `MediaRecorder` | Audio encoding | Supports `audio/wav`, `audio/ogg;codecs=opus` |
| `wx.media.getRecorderManager()` | wx-style recording (start/pause/resume/stop, frame callbacks, etc.) | **Uses the default microphone and offers no source/mode selection parameters**; mode selection requires the Web `getUserMedia` |

### 2.5 Audio Playback and Web Audio

Source: `skill: references/apis/media.md`

- `AudioPlayer`: a general player (files inside the local package or network URLs), supporting streamed `append()` playback of `pcm` / `ogg_opus`, and subtitle text tracks (`TextTrack`/`VTTCue`).
- `Sound`: short playback of local sound effects (local files only; http(s) URLs are rejected).
- Web Audio: `AudioContext` plus `createBuffer/Oscillator/Gain/BiquadFilter/Analyser/MediaStreamSource`, `decodeAudioData`, etc.; can be used for microphone waveform/spectrum analysis.

### 2.6 Speech Synthesis (TTS)

Source: `skill: references/apis/ai.md`

| API | Capability | Key limits |
|---|---|---|
| `speechSynthesis.speak(utterance, mode?)` | Synthesize and play directly (queued by the runtime's unified player) | `mode`: `'enqueue'` (default) / `'immediate'` |
| `speechSynthesis.synthesize(utterance, options?)` | Generate without playing; returns a `SpeechSynthesisTask` (audio chunk events, abortable; pair with `SpeechAudioPlayer` for independent playback) | Options: subtitle granularity `subtitles: 'none'/'sentence'/'word'`, audio format `pcm/mp3/ogg_opus`, sample rate, channels, bit rate, `AbortSignal` |
| `SpeechSynthesisUtterance` | text/lang/voice/volume/pitch/rate | **The `lang` attribute currently has no effect** (the documentation states explicitly that it is unsupported and does not change the generation language); pitch/rate/volume default to 1 |
| Official voice IDs (11 in total) | `female-tianmei`, `English_radiant_girl`, `English_expressive_narrator`, `male-qn-qingse`, `male-qn-jingying`, `female-yujie`, `Chinese (Mandarin)_News_Anchor`, `Chinese (Mandarin)_Radio_Host`, `clever_boy`, `lovely_girl`, `English_Trustworthy_Man` | No `getVoices()`, no `cancel()/pause()/resume()` (the documentation states explicitly that they are not exposed) |
| `wx.speech.playTTS(text)` | wx-style one-shot speech playback | Returns a string (the request ID); returns an empty string on failure |

### 2.7 Sensors (IMU)

Sources: `skill: references/apis/device.md`, and the official guide https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md

| API | Data | Events / notes |
|---|---|---|
| `new Accelerometer({frequency?})` | Three-axis acceleration `x/y/z` + `timestamp` | Events `activate`/`reading`/`error`; `frequency` is only a best-effort hint to the host |
| `new Gyroscope({frequency?})` | Three-axis angular velocity `x/y/z` + `timestamp` | Same as above |
| `new AbsoluteOrientationSensor({frequency?})` | Absolute orientation quaternion `quaternion` ([x,y,z,w]) + `timestamp` | Availability depends on device hardware support |
| Sampling rate | The official guide's examples use 60; starting at 30–60 Hz and raising as needed is recommended | No officially published maximum frequency / accuracy figures |

Note: the API layer exposes only the three sensors above; no separate geomagnetic / ambient-light / proximity sensor API appears in the official API reference.

### 2.8 Speech Recognition (ASR)

Source: `skill: references/apis/ai.md`. **There is no separate `SPEECH_RECOGNITION` permission** (the documentation states explicitly that it was removed); opening the microphone still requires `RECORD_AUDIO`.

| API | Capability | Key limits |
|---|---|---|
| `new SpeechRecognition()` | Host-microphone recognition: `lang`, `continuous`, `interimResults`, `maxAlternatives`; a full Web Speech-style event set including `result`/`nomatch`/`error` | `start()` requires the owning view to remain in the interactive state; in a non-interactive state it immediately raises `InvalidStateError`; when `lang` is empty the host picks the default language |
| `new SpeechRecognitionSession(options?)` | Recognition of an external audio stream (you feed audio chunks with a MediaRecorder into the writable stream `session.audio`); the session itself does not open the microphone | Options include hot words `phrases: [{phrase, boost}]`, segmentation `segmentation: 'auto'/'vad'/'semantic'/{mode:'vad', silenceDurationMs}`, and dynamic context via `updateContext(messages)` |
| `SpeechRecognitionSession.getCapabilities()` | Query the host's real capabilities: audio formats/sample rates, `maxChunkBytes`, whether interim results / hot words / context / VAD threshold ranges are supported | Capabilities vary by host; always query before use |

### 2.9 Large Language Model (LLM)

Source: `skill: references/apis/ai.md`

| API | Capability | Key limits |
|---|---|---|
| `LanguageModel.availability()` | Returns `'available'/'unavailable'` | Does **not** expose the provider, model list, or endpoint information |
| `LanguageModel.create({model?, initialPrompts?, tools?})` | Create a session; model resolution order: explicit `model` → host `defaultModel` | Underneath is the host's **OpenAI-compatible chat-completions streaming channel**; `system` may only appear as the first entry of initialPrompts |
| Multimodal input | The content array of user messages supports `{type:'text'}` and `{type:'image_url', image_url:{url}}` (including data: URLs) | Structured content is limited to the user role |
| Tool calls | `tools` (function type) are forwarded into the provider request body; tool calls come back as `toolcall` events on the session (callId/functionName/arguments) | **Not** executed automatically: the JS side must handle the events itself, and there is no guarantee of a structured tool-call round-trip protocol |
| `session.prompt(input)` / `promptStreaming(input)` | One-shot answer / streaming answer (polling-style `read()`; not a WHATWG Stream, not an async iterator) | Only one in-flight request per session at a time; after `destroy()` the session cannot be used again |
| `wx.speech.startRecognition()` | wx-style recognition entry point (returns a string) | A different entry point from 2.8 |

### 2.10 Geolocation

Source: `skill: references/apis/geo/geolocation.md`. The `GEOLOCATION` permission must be declared (the system may still deny it after declaration).

- `navigator.geolocation.getCurrentPosition(success, error?, options?)` / `watchPosition(...)` (returns a numeric watch ID; release it with `clearWatch`).
- Options: `enableHighAccuracy` (default false), `timeout`, `maximumAge` (host-determined when omitted).
- Result: `coords` contains `latitude`, `longitude`, `accuracy` (meters), and the nullable `altitude`, `altitudeAccuracy`, `heading`, `speed`; error codes 1/2/3 (denied / unavailable / timeout).
- A companion `GPXDocument` API (the `'gpx'` module): GPX route parsing, creation, and export (setStartPoint/addWaypoint/appendTrackPoint/toString/toBlob), used with the `<map>` / `<map-gpx>` components for track display. Sources: `skill: references/apis/geo/gpx-document.md`, `skill: references/components.md`

### 2.11 Bluetooth BLE (Client)

Source: `skill: references/apis/device.md`

- `navigator.bluetooth`: `getAvailability()`, `getDevices()`, `requestDevice({acceptAllDevices?, optionalServices?, filters?:[{name?, services?}]})`, `scanDevices(options?)` (Ink-specific, not standard Web Bluetooth).
- GATT: `device.gatt.connect()/disconnect()/getPrimaryService(s)/…`, characteristic `readValue()` (returns `Promise<number[]>`), `writeValue(With/WithoutResponse)`, `startNotifications()` plus the `characteristicvaluechanged` event.
- Limits: `requestDevice`, `scanDevices`, `gatt.connect()`, and `startNotifications()` all require the owning view to remain in the **interactive state**; `getAvailability/getDevices` are exempt. The role is BLE **central (client)**; the official API reference contains no BLE peripheral (advertising) capability.

### 2.12 Storage and Files

Sources: `skill: references/apis/web.md`, `skill: references/apis/wx.md`, `skill: references/apis/navigator.md`, `skill: references/framework.md`

- `localStorage`: a string key-value store isolated per agent (getItem/setItem/removeItem/clear).
- wx storage: `wx.setStorage/getStorage/removeStorage/clearStorage` plus `Sync` synchronous variants; data is JSON-serialized.
- `navigator.storage`: a StorageManager, defined in the documentation as the "Persistent file storage entry point" — ⚠️ the skill reference gives no method details for it (see Section 5).
- File model: resources are always resolved from **paths inside the project** (e.g. `/assets/icon.png` packaged into the .aix); the official framework documentation explicitly warns **not to assume arbitrary access to the device file system**. The official API reference contains no general-purpose file system API (no read/write/list-directory interfaces for arbitrary paths).
- ⚠️ **`FileReader` does not exist (verified on real hardware, 2026-10-28; global error code E2005)**: the Ink runtime has no `FileReader`, and the full official aiui-dev reference contains no such API either. `Blob → dataURL` conversion must go through `blob.arrayBuffer()` + chunked `btoa` encoding (or bitmap-direct storage); any `new FileReader()` / `readAsDataURL` will throw `FileReader is not defined` on real hardware and kill every frame. When developing, treat the official API reference list as authoritative: an API that is not in the list does not exist — do not assume it from browser habits.

### 2.13 Networking

Sources: `skill: references/apis/web.md`, `skill: references/apis/wx.md`, and the official guide https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md

- `fetch` / `Headers` / `Response` (including streamed reading of `body` as a ReadableStream, and BYOB), `WebSocket`, `File`/`FormData`, `URL`/`URLSearchParams`, and the full Streams family (Readable/Writable/Transform).
- `wx.request` (timeout resolution order: options.timeout → the app.json setting → the 60000 ms default), `wx.createSocket/connectSocket`, `wx.createEventSource` (SSE).
- `crypto`: `randomUUID`, `getRandomValues` (capped at 65,536 bytes); `crypto.subtle` supports **only** SHA-1/256/384/512 digests and HMAC (generateKey/importKey/exportKey/sign/verify) — encryption/decryption, RSA, ECDSA, and JWK are **not supported**.
- **Mobile Proxy networking**: when the glasses are not on Wi-Fi, as long as Bluetooth is connected to the phone app (Rokid AI App / Hi Rokid), `fetch`/`wx.request` traffic is automatically forwarded over the phone link — transparent to the developer, and more power-efficient.
- **HTTPS mandatory**: network requests in production must use HTTPS; before publishing to the store, request domains must be **filed on the allowlist** in the developer console.
- **Direct LAN connections: not supported** (the official guide says "under development"; the LAN section of the documentation catalog is marked `status: unsupported`).

### 2.14 Canvas 2D and Barcode Detection

Source: `skill: references/apis/canvas.md`

- `CanvasRenderingContext2D`: paths/rectangles/text (including `measureText`)/transforms/gradients/patterns/image data/`drawImage` (only the 3/5/9-argument forms); entry points are a page `<canvas>` (`wx.createCanvasContext(id)`) or a script-created `new Canvas(w,h)`.
- Restricted color parsing: only `#rrggbb`, `#rgb`, `rgb()`, `rgba()`, and a few named colors such as black/white/red/green/blue/yellow/transparent.
- Output: `canvas.convertToBlob({type, quality})` (PNG by default; JPEG quality 0–1; transparent pixels are composited onto black in JPEG), and the global `createImageBlob()`.
- `BarcodeDetector` (the `'barcode'` module or a global): `getSupportedFormats()` lists the supported symbologies (canonical names such as `qr_code`, `code_128`, `ean_13`); `detect(image)` accepts ImageData, an encoded image Blob, or an ImageBitmap, and returns `format`, `rawValue`, `boundingBox`, `cornerPoints`. OffscreenCanvas/VideoFrame/HTML-element inputs are not supported.

### 2.15 Interaction Events (Runtime Layer)

Source: `skill: references/events.md`. See Section 3 for the interaction model.

- Template events: `bind<event>` bindings such as `bindtap`/`catchtap`; animation events `bindanimationstart/iteration/end/cancel`.
- Key events: a Page's `onKeyDown/onKeyUp(event)`, dispatched by `event.code` (for the Rokid Glasses mapping, see 3.2).
- Voice wakeup callback: `onVoiceWakeup(event)`.
- World awareness (must be enabled inside a Page with `enableWorldAwareness()`): `onHeadGesture(event)` (an example gesture value is `'nod'`), `onOrientationStabilityChange(event)` (`event.stable`, head stability).
- Network state: App/Page `onNetworkStatus(event)`.

### 2.16 Framework and Component Surface

Sources: `skill: references/framework.md`, `skill: references/components.md`, `skill: references/apis/agent-worker.md`

- Project structure: `app.json` + `app.js` + `AGENTS.md` + `pages/` (a single `.ink` file, or the four-piece `.json/.wxml/.wxss/.js` set) + optional `widgets/`, `workers/`, `components/`, `assets/`.
- **37 authorable built-in component tags** in total: containers/text/forms (button/input/textarea/switch)/media (image/video/lottie-view)/maps (map, map-gpx)/canvas and charts (canvas/chart)/AI-generated UI (a2ui), and more.
- Agent Worker: a UI-less script (triggered by open; `lifetime: 'instant'|'foreground'`; `background` is reserved and ineffective); it has timers, Promise, Crypto, Wasm, and encoding streams, but **no** `window/document/fetch`, routing, rendering, or media capture.
- TypeScript entry points and WebAssembly modules are supported (through the project packaging pipeline).

### 2.17 Permission List (app.json.permissions, Exact Names)

Source (corrected by the full audit of 2026-10-29): the permission table in `documentation/1-framework/open-agent-format/app-json.md` — **7 in total**. The names are **case-sensitive**; unrecognized names grant no capability; declaring a permission in the manifest ≠ system authorization, so call sites must still handle denial. Note: the aiui-dev skill's `references/framework.md` still lists only the first three — an internal inconsistency in the upstream documentation; the framework document governs.

| Permission name | Purpose |
|---|---|
| `GEOLOCATION` | Get the current position / watch position changes |
| `CAMERA` | Access the camera; capture images or video |
| `RECORD_AUDIO` | Access the microphone and capture audio (ASR microphone use and recording both rely on it; there is no separate ASR permission — the old `SPEECH_RECOGNITION` permission was removed in Ink 0.19) |
| `READ_MEDIA_IMAGES` | List and read images in the system media library |
| `CREATE_MEDIA_IMAGES` | Add images to the system media library (does not include modifying/overwriting existing assets) |
| `READ_MEDIA_AUDIO` | List and read audio in the system media library |
| `CREATE_MEDIA_AUDIO` | Add audio to the system media library (does not include modifying/overwriting existing assets) |

In addition: the review stage (Studio/store) has a separate set of **declaration checkboxes** — networking, camera, microphone, speaker, Rokid account information, etc. — each requiring a stated purpose; these are a separate mechanism from the manifest permissions. Source: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md

---

## 3. Interaction Model

### 3.1 Wakeup

- Product-level wake word: **"Hi Rokid"**.
- Runtime `onVoiceWakeup(event)`: can be triggered by voice or touch; known `event.keyword` values include `乐奇` (the Chinese wake word), `Hi Rokid`, and `clickAiAssist` (touch wakeup). Do not filter by keyword by default; `event.preventDefault()` can take over the host's default action.

### 3.2 Temple Touch and Key Mapping

The runtime delivers these as **key events** (`onKeyDown/onKeyUp` + `event.code`); the Rokid Glasses mapping is:

| `event.code` | Meaning | Default behavior (after onKeyUp) |
|---|---|---|
| `Enter` | Confirm / activate | Enter navigation mode or activate the current target |
| `Backspace` | Back | Go back one level; when there is no page to go back to, request closing the agent |
| `ArrowUp` / `ArrowDown` | Up / down | Move within the current navigation path or scroll the root view |
| `GlobalHook` | Device-specific signal for a **temple key touch** (not a standard Web key value) | No default action; the documentation recommends using it only for fast response in onKeyDown — use Backspace/Enter to distinguish back/confirm |

Product-side supplement: the product page mentions "Quick Action Shortcuts — Tap to launch the features you use most" (tap the temple to quick-launch frequently used features) and a dedicated capture action ("One word or one press" to take a photo).

### 3.2.1 Complete Temple Touchpad Gesture Table (verified on real hardware; Hi Rokid app "User Guide")

Source: the user guide built into the Hi Rokid app (real-device behavior; this governs; the touch area is the middle section of the temple). This is the complete product-level mapping behind the §3.2 key events — the runtime's `Enter`/`Backspace`/`ArrowUp/Down` originate from these gestures.

**Single-finger interaction (general)**

| Gesture | System behavior | Runtime equivalent |
|---|---|---|
| Single tap | Confirm | `Enter` |
| Double tap | Back | `Backspace` |
| Long-press the touchpad | Wake the assistant (in the app you can choose "Glasses AI assistant (default)" or "Phone assistant") | `onVoiceWakeup` (keyword `clickAiAssist`) |
| Swipe | Scroll forward (direction can be changed in the app) | `ArrowUp` / `ArrowDown` |

**Single-finger, scenario-specific**: Music — a single tap on the home screen does nothing; in the music app a single tap = play/pause; swipe forward/back = next/previous track. Calls — double tap during an incoming call = reject; single tap during a call = mute/unmute; double tap during a call = hang up.

**Two-finger interaction (two fingers spread, touching the middle section of the temple)**

| Gesture | System behavior |
|---|---|
| Double tap | Screen off |
| Long press | **AI Quick Command**: send a fixed command to a selected "trigger target" (see below) |
| Swipe forward/back | Volume up/down (default; changeable) |

**AI Quick Command (two-finger long press)**: can be toggled in the app; the command can be a preset ("Look at what's in front of me", "Take a photo and translate it into Chinese", "What's the weather today") or custom text (≤500 characters). Key point: **the trigger target can be a specific custom/debug Agent** — that is, a two-finger long press deterministically delivers a fixed text to a designated Agent with zero ASR, a hardware-level entry point that bypasses voice-wakeup misrecognition (verified working on real hardware).


### 3.3 What "Gaze" Actually Is: Head Orientation, Not Eye Tracking

**Conclusion: AIUI has no eye-tracking API; so-called "gaze" is implemented through head pose.**

Evidence:
1. No eye-tracking / gaze-coordinate API exists anywhere in the official API reference (all of the skill's apis files); a full-text search finds no eye-tracking entries.
2. Pointing capability is provided by the IMU: `AbsoluteOrientationSensor` yields the head orientation quaternion (2.7).
3. There are only two world-awareness callbacks: `onHeadGesture(event)` (the documented example gesture value is `'nod'`) and `onOrientationStabilityChange(event)` (head stability changes) — i.e. the "look at something and hold your head steady → trigger" interaction paradigm relies on **head-stability detection**, and the official example confirms exactly on `event.gesture === 'nod'`. Source: `skill: references/events.md`
4. Neither the product page nor the documentation ever claims eye-tracking hardware; the spec table's sensor entry says only "IMU: Supported".

Therefore: developing "gaze"-style interaction = head orientation (quaternion/direction) + head-stability events + nod confirmation. **Other gesture values such as shake are not listed in the official documentation** — the complete gesture enumeration for `onHeadGesture` has not been officially published (see Section 5).

### 3.4 Voice Interaction Flow


Wake word / touch wakeup → `onVoiceWakeup` → inside the Agent, use `SpeechRecognition` (host recognition) or `SpeechRecognitionSession` (your own audio stream) for ASR → `LanguageModel` session inference (image input supported) → speak via `speechSynthesis.speak/synthesize` or `AudioPlayer`. The conversation-flow card is **display-only** by default; interactive UIs require a full-screen Page or a Widget (`skill: SKILL.md` Core Rules).

### 3.5 The Role of the Phone Companion App


- Network proxy: when the glasses have no Wi-Fi, they get online via Bluetooth through the phone app (the overseas **Hi Rokid**, package name `com.rokid.sprite.global.aiapp`) (2.13).
- Device management and resource distribution: connect/manage the glasses, adjust settings, manage media, AI feature entry points (translation/subtitles/teleprompter/device control) — product page FAQ.
- Agent distribution chain: Studio packaging and cloud upload → the app updates the glasses resource package → the agent runs on the glasses (this project's established flow; the official guide's publishing flow is "build → web simulation → AIX packaging and cloud upload → real-device debugging", source: publish.md).

---

## 4. Platform Limits and Constraints (Developer View)

### 4.1 Display / UI Constraints

- Single green channel: every visible pixel is just a brightness level of the same green (base color `#40ff5e`, 6 brightness steps); **black = transparent background**, so you cannot count on an opaque black panel to occlude the real environment.
- Semantics must not rely on color alone: states/severity must be redundantly encoded with icons, text labels, line styles, or motion.
- Reference canvas 480 × 352; key information must fall within the central comfortable field of view; body text brightness of ≥72% is recommended, decorative lines ≤24%.

### 4.2 .aix Package Constraints

- AIX = "AI eXecutable", AIUI's proprietary distribution format; internally it follows the OAF (Open Agent Format) specification and is self-contained: code (WXML/WXSS/JS), configuration (JSON), and static assets.
- Packaging automatically generates a `VERSION` file with a unique UUID for version verification / hot update; packaging supports PNG/JPEG compression and JSON obfuscation/minification.
- **Package size limit: not officially published** (no figure in the documentation consulted).
- Project-side red line: `.aixignore` must exclude `.agents/`, `.aix/`, `artifacts/`, `*.aix`, `skills-lock.json`, and `node_modules/`, or development files will end up in the package (measured: 2.3 KB → 107 KB). Source: this project's root README (repository sakai55/rokid).

### 4.3 Capabilities AIUI Explicitly Does Not Expose / Support

| Capability | Status | Basis |
|---|---|---|
| **OCR (text recognition) API** | **Does not exist** | No OCR entry anywhere in the complete official API reference list (the skill's apis directory) or the official documentation catalog; the official path for "reading text" is a telephoto photo + LLM image input (2.3 / 2.9) |
| Eye tracking | Does not exist | See 3.3 |
| Direct LAN communication | Not supported (under development) | Official networking guide + documentation catalog `lan: status unsupported` |
| Data prefetch | Not supported | Documentation catalog `prefetch: status unsupported` |
| Source map debugging | Not supported | Documentation catalog `sourcemap: status unsupported` |
| WXML `<template>` | Not supported | Marked unsupported in the documentation catalog |
| Agent Worker background residency | Not supported | `lifetime: 'background'` is reserved and ineffective; Workers also have no fetch |
| Web Crypto encryption algorithms | SHA digests + HMAC only | `skill: references/apis/web.md` states explicitly that RSA/ECDSA/encryption-decryption/JWK are unsupported |
| TTS language switching | The `lang` attribute has no effect | Stated explicitly in `skill: references/apis/ai.md` |
| TTS queue control | No cancel/pause/resume/getVoices | Same as above |
| General file system | No arbitrary-path file API | 2.12 |
| Device serial number / token | System-level agents only | 2.1 |
| LLM provider information | availability() does not provide it | 2.9 |

### 4.4 Review / Publishing Constraints

> Note: the official document in question describes publishing to the **Rokid Ai agent store (mainland China)**; the Global edition goes through the Submit tab of Global AIUI Studio, with broadly matching requirements (verified by this project in practice).

- Name: required, ≤20 characters, must not duplicate another's name, must not contain "test/beta"-type words, prices or promotions, or superlatives; copy must not use implication words such as "official/authoritative/recommended/TOP1" or absolute claims like "100% accurate".
- Icon: required and **the default icon must not be used**; it must not be blurry/stretched, carry a watermark or QR code, or be a plain color with text.
- Feature description ≤500 characters; the opening message is required and ≤300 characters is recommended; the version number and Agent ID are both system-generated and cannot be edited by the developer.
- Permissions: truthfully check all permissions actually used and state each one's purpose, following "minimum necessary + truthful purpose"; calling undeclared permissions, vague descriptions, or inconsistency with the code's behavior can all lead to rejection.
- Preview assets: **3–5 files** are required, at least 1 image + 1 video; images in JPG/PNG (1:1 recommended), videos in MP4 (1:1 recommended), duration ≤60 seconds (15–45 seconds recommended), a single file ≤50 MB recommended; the video must fully demonstrate 1–2 core flows.
- Content safety: UGC requires safety filtering; AI-generated synthetic content must be labeled as required by law; the agent must start, interact, and return normally, and must not crash frequently.
- Flow: build → web simulation → AIX packaging and cloud upload → real-device debugging → complete the review materials → submit for review → result (if rejected, fix, repackage, and resubmit; if approved, it is listed in the store).

### 4.5 Runtime and Interactive-Gate Constraints

- **Interactive gate**: BLE requestDevice/scanDevices/connect/startNotifications, SpeechRecognition.start, RecorderManager.start, CameraContext.takePhoto, getUserMedia capture, and the like all require the owning view to be in the interactive state, and usually also need to be triggered by a user interaction; calling them in a non-interactive state throws/fails directly.
- Resource lifecycle: microphone/camera tracks must be stopped when done; BLE scanning must be stopped and GATT disconnected; watchPosition must be clearWatch'ed; AudioContext must be closed. The official checklist lists these as delivery red lines (`skill: references/checklist.md`).
- Simulator ≠ real device: in DevTools, sensors are mostly simulated values, and performance/heat/throttling differ from real hardware; the official documentation requires real hardware to govern (env.md).

---

## 5. Contradictions and Unresolved Items

1. **Inconsistent display-resolution figures**: the official product spec table says **480 × 400**; the AIUI design specification and the Widget size family use the **480 × 352** reference canvas (the 1x2 Widget width of 480 is consistent with this too). Both are official sources — presumably 480×400 is the panel's physical resolution and 480×352 the runtime safe canvas, but officials have not stated this.
2. **Third-party FOV claims**: unofficial reviews (Notebookcheck, etc.) claim 23°, while the official product page says **30°**. The official figure governs; 23° is marked **not officially confirmed**.
3. **Third-party display-resolution claims**: some unofficial reviews claim 640×480, which does not match the official 480×400 — **not officially confirmed**.
4. **Multiple battery-life figures**: within the same official product page, the FAQ says 8–10 hours of daily use while the comparison table says 6 hours mixed use / 30 hours with the case; no nominal figure under a unified test protocol is given.
5. **The second chip**: the product page carries a "Dual-Chip Performance" tagline, but the official spec table lists only Snapdragon AR1 as the SoC; the second chip's model (e.g. the NXP RT600 claimed by third parties) is **not confirmed on the official spec page**.
6. **Missing camera details**: the sensor model (marketing copy says Sony; the spec table gives no model) and camera FOV (third parties claim 109°) are both **not officially published**.
7. **Missing IMU details**: the product page says only "IMU: Supported"; the axis count, model, sampling-rate ceiling, and accuracy are all unpublished; on the API side, frequency is only a best-effort hint with no guaranteed value.
8. **Head-gesture enumeration unpublished**: official examples for `onHeadGesture` give only `'nod'`; whether other gesture values (head shake, look up, etc.) exist and what they are called is not fully listed in the official documentation.
9. **Dangling `navigator.getBattery()` documentation reference**: the navigator reference says the battery methods are in the device reference, but the device reference has no BatteryManager section — the API's existence follows the navigator reference, while the details (properties/events) are not given in the skill.
10. **Missing `navigator.storage` (StorageManager) details**: the navigator reference gives only the single sentence "Persistent file storage entry point", with no method signatures; its boundary with localStorage/wx storage is not explained in the skill.
11. **Device-generation differences unverified**: the events reference states explicitly that the key mappings for **Rokid Glasses 2** and the **first-generation full-color glasses** "remain unverified" and must not borrow the mapping of Rokid Glasses (first-generation monochrome green); the design specification names RokidGlasses1 / RokidGlasses2 as target devices.
12. **Dual-track documentation versions**: the official documentation currently has two sites — open.rokid.com/aiui (current) and js.rokid.com (an earlier version; its AI development guide is at /AIUI/guide/quickstart/ai-dev); this dossier's API contract follows the official repository's current `documentation/` and `skills/aiui-dev`, and the two sites' contents have not been compared page by page.
13. **OS unpublished**: the glasses' operating system name/version appears in neither the official product page nor the documentation (only the Ink / QuickJS + Skia container runtime is known).
14. **.aix package size limit unpublished**; the filing entry point and review turnaround for the domain allowlist are likewise not detailed in the public documentation.

---

## 6. Official Source List

**Product and platform**
- Rokid Glasses official global product page (primary specification source): https://global.rokid.com/products/b-h-rokid-glasses-with-display
- Rokid official UK site, AI product line (specification corroboration): https://gb.rokid.com/collections/rokid-ai-lineup
- Official Academy tutorial "3.6 Glasses AIUI" (Craft/Studio workflow): https://global.rokid.com/de/blogs/academy-glasses/glasses-3-6-aiui

**Official documentation sites**
- AIUI documentation (current): https://open.rokid.com/aiui
- AIUI documentation (earlier version): https://js.rokid.com/AIUI/guide/quickstart/ai-dev

**Official GitHub repository yodaos-project/AIUI (jsar-project/AIUI redirects here)**
- Repository home/README (positioning, Samples index): https://github.com/yodaos-project/AIUI
- Samples directory (bluetooth / capabilities / cut-card / games / gyroscope-test / meal-card / navigator-info / realtime-voice-intelligence / scanner / tts): https://github.com/yodaos-project/AIUI/tree/main/samples
- aiui-dev skill (the primary source for this dossier's API contract): https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev
- Review and publishing: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/publish.md
- What is AIX: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/bundle/aix.md
- Runtime environment: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/runtime/env.md
- IMU guide: https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/device/imu.md
- Network usage notes (mobile proxy / HTTPS / domain allowlist / LAN): https://github.com/yodaos-project/AIUI/blob/main/documentation/0-guide/basic/network/usage.md
- Documentation catalog (including the unsupported markings for lan/prefetch/sourcemap, etc.): https://github.com/yodaos-project/AIUI/blob/main/documentation/toc.json
