# Rokid Global Error Codes v1.14.0

[中文](ERROR-CODES.md) | English | [日本語](ERROR-CODES.ja.md)
Translated from the Chinese canonical, v1.14.0 (2026-10-29). In case of conflict, the Chinese version prevails.

Adopted by GO on 2026-10-28: whatever goes wrong in any agent, the glasses display one standard error code. The user reads the code off the screen, and that alone is enough to pinpoint the failure in this table.

**This file is the whole thing.** The format rules, the governance, the integration guide (with code you can copy as-is), and the complete table all live here — see the contents below. Any developer or AI agent can lift the file wholesale and put it to work.

## Contents

- [Before you start](#before-you-start)
- [1. Coding rules](#1-coding-rules)
- [2. Governance](#2-governance)
- [3. Integration spec](#3-integration-spec)
- [4. Code table](#4-code-table)
- [5. Field cases](#5-field-cases)
- [6. Changelog](#6-changelog)
- [7. Why error codes](#7-why-error-codes)

## Before you start

First, what this is — and what it isn't. These codes are not an official Rokid spec. They are a working convention from one developer's own projects, written up for anyone else building AIUI agents for Rokid glasses. Wiring the codes into an agent takes five steps:

1. **This table is the only source of codes** (Section 4). Use codes that exist here. Don't invent your own, don't bend a code's meaning, and don't add prefixes — the bare code, `E####`, is the only form there is.
2. **Section 3 is the how-to.** Five jobs: define the codes in one place, map every failure point, surface the same code in three places, give the README a section of its own, and run a static self-check. The sample code is meant to be copied and then trimmed or extended for your agent — don't invent a different structure.
3. **Picking a code.** Work through Section 4 range by range and take the closest match for the failure at hand. Nothing fits? Fall back to `E9001`, stash the original error text in `lastError`, and request a new code afterwards through the process in Section 2. Never ship a code you made up while you wait for the registry to answer.
4. **Three things to avoid.** Never put raw error text in front of the user — the original wording belongs in `lastError` only. Never use a retired code (right now, that's E6006). And never sprinkle code literals through business code; everything goes through the single definition module.
5. **Run the static self-check in Section 3, step (5) before you package**, and keep the grep output on file.

One principle sits above all of it: **error handling must never create errors of its own.** The code that displays, records, and ships back errors must never throw and never hassle the user. Section 3 spells out what that means in practice.

## 1. Coding rules

- **One form only: the bare code, `E` plus four digits** — E2005, say. Definitions in code, the on-screen display, the TTS readout, `lastError`, READMEs, and debugging threads all use the bare code. No prefixes, ever.
- **A code means the same thing everywhere.** E2005 in one agent is E2005 in every agent. Which agent produced a given report comes from context, plus the slug and version recorded in `lastError`.
- **Ranges are organized by what failed**, not by which agent failed:
  - 1xxx Camera and image capture
  - 2xxx Frame data and encoding
  - 3xxx Speech: ASR and TTS
  - 4xxx Recording, compositing, and playback
  - 5xxx Storage and files
  - 6xxx Networking and the LLM
  - 7xxx Sensors, location, and detection
  - 8xxx Pages and runtime
  - 9xxx System catch-alls: E9001 for anything unclassified, E9002 for host- or system-level failures

## 2. Governance

- **One maintainer.** This table is kept by a single registry — the maintainer who owns it. New code assignments and new ranges alike go through the registry; nobody reserves a code unilaterally.
- **Codes are forever.** Once assigned, a code never changes meaning and is never recycled. A retired code keeps its original meaning and is marked "Retired".
- **Adding a code to the table** follows six rules:
  1. **Look for a synonym first.** Search the whole table for a code that already means this, or one that can be reused. If there is one, use it — don't mint a new code.
  2. **Append at the end of the range.** New codes take the next number at the tail of their range, in order. No inserting numbers mid-range, and no backfilling the slot a retired code left behind.
  3. **One code, one failure — the code follows the failure.** A code names exactly one kind of failure, and that failure takes the same code in every agent where it occurs. No per-agent or per-page variants.
  4. **A request has three parts:** the failure point, the original text that triggered it, and the range you propose. The registry checks it, assigns the code, and replies. Don't ship a code you assigned yourself ahead of that reply. In a live incident, park it under E9001 with the original text in `lastError` and file the request afterwards.
  5. **Opening a new range** takes a real reason: none of the nine ranges fits, or a range has run out of numbers. Only the registry opens a range, and the changelog records the new range's domain.
  6. **Write the entry in full.** A new code lands with a clear description and a typical trigger stated as a concrete situation. If you can tell whether the simulator reproduces the cause, settle the "simulator" badge question at the same time.
- **Versioning.** Adding codes only: bump the minor version. Rule or format changes: bump the major. Wording or layout only: bump the patch. Every bump gets a changelog entry.
- **Archiving.** Each release snapshots the version it replaces into `base/error/ERROR-CODES-v<old version>.md`; the repo root holds only the current version. For current rules and code meanings, the root copy is the only one that counts.
- Wiring codes into an agent follows the integration spec in Section 3.
- This table is v1.14.0, dated 2026-10-29, and lives at the repo root as `ERROR-CODES.md`. An agent may carry a copy inside its own project; if a copy and the root version ever disagree, the root version wins.

## 3. Integration spec

**The standing rule: error handling must never create new errors.** Everything added for reporting's sake — the on-screen display, the spoken readout, the `lastError` write, a log queue and its upload — must never turn into a fresh source of failures. The single failure exit never throws; if a reporting action fails, it fails silently, on its own; and the main flow's outcome never hinges on whether reporting worked. Log upload is a strictly optional extra: leaving it out changes nothing in this spec, and if you do wire it in, a missing key or a failed send stays just as silent — nothing about it reaches the user.

Five jobs wire an agent into this table:

**(1) Define the codes in exactly one place.** Give the project an error-code module (`err.js`, below) that declares every code the agent uses, once, as bare-code literals. No code strings scattered through business code, and no prefixes assembled at runtime. Copy the module as-is, and adjust the `ERR` and `MESSAGES` tables to the codes your agent actually uses:

```js
// err.js — single-point error code definitions + unified failure exit
// Code meanings follow the global error code table; business code may only reference ERR.*, never scatter 'E####' strings.

export const ERR = {
  CAM_OPEN: 'E1001',        // camera failed to open
  PHOTO: 'E1009',           // photo capture failed
  ENCODE_TEXT: 'E2005',     // encoding to text failed
  ASR_ERROR: 'E3003',       // other ASR error (fallback)
  ASR_DENIED: 'E3008',      // microphone not authorized
  UNKNOWN: 'E9001'          // uncategorized fallback
};

const MESSAGES = {
  E1001: 'Camera failed to open',
  E1009: 'Photo capture failed',
  E2005: 'Encoding to text failed',
  E3003: 'Speech recognition error',
  E3008: 'Microphone not authorized',
  E9001: 'Uncategorized error'
};

// The page registers its own display function (large code + one-line description); err.js never touches page structure directly.
let showOnScreen = null;
export function onShowError(fn) { showOnScreen = fn; }

// Unified failure exit: display + (for stop-class errors) TTS reads only the code + write lastError — the same code in three places.
// raw takes the original error object or string; it goes only into lastError, truncated to 300 chars, and is never shown on screen directly.
export function fail(code, raw, opts = {}) {
  const entry = {
    code,
    slug: opts.slug || '',
    version: opts.version || '',
    raw: String((raw && raw.message) || raw || '').slice(0, 300),
    at: new Date().toISOString()
  };
  try { wx.setStorageSync('lastError', entry); } catch (e) { /* even if storage fails again, never throw */ }
  if (showOnScreen) showOnScreen(code, MESSAGES[code] || 'Uncategorized error');
  if (opts.speak) {
    try {
      speechSynthesis.speak(new SpeechSynthesisUtterance(code)); // read only the code itself, never the original text
    } catch (e) { /* if speech fails, do not throw again */ }
  }
  return entry;
}
```

**(2) Map every failure point.** Audit every call that can fail — camera, encoding, ASR/TTS, the LLM, networking, storage, sensors, page navigation, and so on — and map each failure point to one code from the table. Where nothing fits, use E9001 and keep the original text. Never throw raw error text at the user and call it handled: the original wording is diagnostic material only, shown truncated if it is shown at all, and otherwise confined to `lastError`. The two wirings below are the pattern to follow:

```js
// Example 1: photo failure point — call fail() in the catch, then degrade and return; never throw the raw error
async function takeShot(capture) {
  try {
    return await capture.takePhoto({ mode: 'telephoto' });
  } catch (e) {
    fail(ERR.PHOTO, e);   // display E1009 + write lastError
    return null;          // the caller takes null and follows the degraded path
  }
}

// Example 2: ASR error event — map only the categories you genuinely handle; everything else falls back to E3003
// Note: the official docs have no enumeration of ASR error category strings. Do not create finer codes for categories that have not been verified on a real device.
rec.onerror = (event) => {
  if (event.error === 'not-allowed') fail(ERR.ASR_DENIED, event, { speak: true });
  else fail(ERR.ASR_ERROR, event);
};
```

**(3) The same code in three places.** When something fails, one and the same code shows up in all three:

- **On screen:** the code in large type plus one line of plain description — `E2005 Encoding to text failed`, for instance.
- **In speech:** for errors that halt the agent or stop capture outright, TTS reads the code itself ("E2005") and nothing more — never the original text.
- **In `lastError`:** persisted in the agent's own storage, carrying the code, the agent's slug, its version, and the original error text. When a user reports a code, that record is what lets the maintainer find the failure in this table.

**(4) Give the README a section.** The agent's README gets an "Error codes" section listing the codes it actually uses, plus one line on how to report problems. Template:

```markdown
## Error codes
This Agent follows the global error code table (bare codes E####). On error, the code is shown on screen and spoken aloud,
and the most recent error is kept in lastError. When reporting a problem, please include the code shown on the glasses.
Used by this Agent: E1001, E1002, E2005, E3001, E9001.
```

**(5) Run the static self-check.** Before packaging, run the three greps below and keep the output on file:

```bash
grep -rn "FileReader" <project dir>                 # must be 0 hits (this API does not exist in the runtime)
grep -rEoh "E[0-9]{4}" <project dir> | sort -u      # every code this Agent uses; check each against Section 4
grep -rn "'E[0-9]" <business code dir> --include=*.js | grep -v err.js
                                                 # code strings scattered in business code; must be 0 hits
```

**Worked example: turning a Blob into a dataURL, done right (this is where E2005 came from).** The AIUI API surface is a closed list: a browser API that isn't in the official reference — FileReader is the famous case — does not exist in the runtime. When you need a Blob as text, write it like this, not with FileReader:

```js
// blobToDataUrl — arrayBuffer + chunked btoa (converting a large image in one block overflows the stack; chunking is required)
export async function blobToDataUrl(blob) {
  const bytes = new Uint8Array(await blob.arrayBuffer());
  let bin = '';
  const CHUNK = 0x8000;
  for (let i = 0; i < bytes.length; i += CHUNK) {
    bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CHUNK));
  }
  return 'data:' + (blob.type || 'image/jpeg') + ';base64,' + btoa(bin);
}
```

## 4. Code table

(The `E####` codes in this table are the only form in use — identical across every agent, with no prefix of any kind.)

Some trigger cells end with a struck-through "simulator" badge, <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator">. The badge marks a failure the simulator cannot reproduce — an API missing from the real-device runtime, say, or the real behavior of the glasses' hardware and host services — so the only way to run into it is on actual hardware. A trigger without the badge is environment-independent and happens in the simulator just as well. There are 29 badges in the table in total, and when you register a new code you decide about its badge at the same time.

### 1xxx Camera and framing
| Code | Description | Typical trigger |
|---|---|---|
| E1001 | Camera failed to open | getUserMedia throws / is rejected (non-permission class) |
| E1002 | Camera permission not granted | NotAllowedError / permission denied |
| E1003 | Image capture device unavailable | ImageCapture construction fails / does not exist <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E1004 | Frame grab failed | grabFrame throws on a single call |
| E1005 | Repeated frame grab failures | preview rendering fails repeatedly |
| E1006 | Camera stream interrupted | track ended / stream withdrawn <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E1007 | No camera device | NotFoundError: no usable camera / no device matches the constraints |
| E1008 | Camera not readable | NotReadableError: camera busy or hardware read failure, track cannot start |
| E1009 | Photo capture failed | takePhoto throws or returns empty |
| E1010 | Photo mode unavailable | the requested wide / telephoto / default mode is not supported <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E1011 | Framing constraints not satisfied | video constraint OverconstrainedError and the fallback to defaults also fails |

### 2xxx Frame capture and encoding
| Code | Description | Typical trigger |
|---|---|---|
| E2001 | Frame capture failed during shooting | grabFrame throws while shooting |
| E2002 | Canvas creation failed | Canvas unavailable <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2003 | Encoding failed (canvas) | convertToBlob throws / returns empty |
| E2004 | Encoding failed (direct) | createImageBlob throws / returns empty |
| E2005 | Encoding to text failed | Blob→dataURL failed (including missing FileReader; the first field code, E2005, from AV11) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2006 | Encoding timed out, switched mode | encoding timeout circuit-breaker tripped; switched to the backup mode <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2007 | No usable frame output path | both the primary and backup frame output paths are unavailable <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2008 | In-memory frame read failed | getImageData throws and bitmap-direct storage also fails |
| E2009 | Single-frame processing timeout | watchdog forced reset |
| E2010 | Stopped after repeated failures | repeated failures reached the cap and shooting stopped automatically (main code in lastError) |
| E2011 | Image decoding failed | createImageBitmap throws while decoding a photo / frame data |
| E2012 | Image source empty | drawImage source is empty or has been invalidated (InvalidStateError) |
| E2013 | Text encoding failed | arrayBuffer / chunked btoa conversion throws (a failure of the no-FileReader replacement path itself) |

### 3xxx Voice ASR / TTS
| Code | Description | Typical trigger |
|---|---|---|
| E3001 | Speech recognition unavailable | SpeechRecognition does not exist <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3002 | Speech recognition did not start | rec.start() throws |
| E3003 | Speech recognition error | rec.onerror (fallback for unrefined events) |
| E3004 | Speech recognition keeps dropping | onend restarts fail repeatedly |
| E3005 | Speech output failed | speechSynthesis.speak throws |
| E3006 | No speech input | ASR event no-speech: silence timeout, no voice |
| E3007 | Microphone capture failed | ASR event audio-capture: host-side audio capture failed <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3008 | Recognition permission not granted | ASR event not-allowed: RECORD_AUDIO not authorized <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3009 | Recognition network error | ASR event network: recognition service network failure |
| E3010 | Microphone mode fell back | OverconstrainedError: the exact microphone mode cannot be satisfied; fell back to the default mode (AV04 field case; referenced in 23 places across the fleet) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3011 | Microphone stream acquisition failed | getUserMedia audio stream throws (non-permission, non-constraint class) |
| E3012 | Recognition service unavailable | ASR event service-not-allowed <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3013 | Recognition language not supported | ASR event language-not-supported |
| E3014 | Recognition session configuration failed | SpeechRecognitionSession hot words / VAD / updateContext update rejected (AV05) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3015 | Speech synthesis failed | speechSynthesis.synthesize throws on the generation side (distinct from E3005's speak playback failure, AV06) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 4xxx Recording, composition, and playback
| Code | Description | Typical trigger |
|---|---|---|
| E4001 | No frames to compose | finished with 0 frames |
| E4002 | Frame decoding failed | frame data → ImageBitmap decoding throws |
| E4003 | Playback rendering failed | playback drawImage throws |
| E4004 | Playback frame rate too low | measured rate below half the setting |
| E4005 | Frame data lost | frames no longer match the record after crossing pages / sessions |
| E4006 | Recorder unavailable | MediaRecorder does not exist / construction fails <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E4007 | Recording format not supported | isTypeSupported rejects every candidate format (AV03 probe) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E4008 | Recording start failed | MediaRecorder.start throws |
| E4009 | Recording has no data | ondataavailable has no data / all chunks empty |
| E4010 | Audio decoding failed | decodeAudioData throws (AV04 analysis path) |
| E4011 | Audio playback failed | SpeechAudioPlayer / media element playback throws <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 5xxx Storage
| Code | Description | Typical trigger |
|---|---|---|
| E5001 | Record save failed | localStorage / wx storage write throws |
| E5002 | Record read failed | read / JSON parse throws |
| E5003 | Storage space insufficient | write rejected by quota |
| E5004 | Saved data version incompatible | persisted data structure version mismatch; parse or migration fails |
| E5005 | Persistence unavailable | localStorage / storage interface does not exist or is disabled <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 6xxx Network and LLM
| Code | Description | Typical trigger |
|---|---|---|
| E6001 | Large model unavailable | LanguageModel.availability is not available |
| E6002 | Large model request failed | prompt / promptStreaming throws or the stream fails |
| E6003 | Large model timed out | request timed out with no return |
| E6004 | Network unreachable | fetch / wx.request fails |
| E6005 | Image input failed | image dataURL construction / passing failed (non-FileReader class; FileReader class goes to E2005) |
| E6006 | Large model not ready (Retired) | Retired, never use again: the official docs state plainly that `availability` has only the two states available / unavailable, with no intermediate state; use E6001 when the large model is unavailable. This code is never reused |
| E6007 | Server error | HTTP 5xx or API business error |
| E6008 | Request rejected | HTTP 4xx / authentication failure (401/403; a dabiaoge channel 401 belongs here) |
| E6009 | Response parsing failed | network response JSON / structure parsing throws |
| E6010 | Domain not on the allowlist | the request domain was not filed on the allowlist and is blocked by the host <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E6011 | Large model output unusable | empty response or structure not as expected; cannot be parsed into business data |

### 7xxx Sensors, positioning, and detection
| Code | Description | Typical trigger |
|---|---|---|
| E7001 | Orientation sensor unavailable | AbsoluteOrientationSensor construction / start fails <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7002 | Positioning failed | getCurrentPosition error 2/3 |
| E7003 | Positioning permission not granted | getCurrentPosition error 1 |
| E7004 | Barcode detection failed | BarcodeDetector.detect throws |
| E7005 | Barcode format not supported | getSupportedFormats does not include the target format <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7006 | Gesture channel abnormal | enabling world awareness fails; enableWorldAwareness throws <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7007 | Inertial sensor unavailable | Accelerometer / Gyroscope construction or start fails <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7008 | Sensor has no data | sensor started but no reading within the timeout (benchmark orientation / motion item timeout class) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7009 | Barcode detector unavailable | BarcodeDetector does not exist / construction fails (distinct from E7004's detect throw) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7010 | Head calibration failed | calibration cannot complete, or the calibration center drifts too far (head games / directional class) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 8xxx Pages and runtime
| Code | Description | Typical trigger |
|---|---|---|
| E8001 | Page navigation failed | wx.navigateTo / navigateBack throws |
| E8002 | Page reclaimed by the system | abnormal onUnload with the task unfinished <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E8003 | Permission not declared | the called capability does not match the permissions in app.json (development-time self-check code) |
| E8004 | Runtime interface missing | a required global interface does not exist (generic code for "X is not defined"; FileReader in an encoding context goes to E2005) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E8005 | Input event did not reach the page | key / gesture events not delivered to the page (development-time self-check code: onKeyDown not wired, or the bindtap-only class that cannot be triggered on a real device) <img src="assets/badges/badge-nosim.en.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E8006 | Session state lost | session state missing after crossing pages / re-entering (media frame loss goes to E4005) |

### 9xxx System
| Code | Description | Typical trigger |
|---|---|---|
| E9001 | Uncategorized error | fallback (original text attached, truncated) |
| E9002 | Configuration missing | a required configuration / constant is empty |

## 5. Field cases

Real failures, on real hardware, that an error code tracked down. Each case records four things: the symptom, the code reported, the root cause, and the handling.

### Case 1, E2005: stop-motion, not a single frame came out

- **Symptom:** On its first real-device test, the stop-motion agent ran a capture for the full 180 seconds, exited on its own, and had produced zero frames.
- **Reported code:** The glasses showed E2005. The user reported the code, and the table pointed straight at the encode-to-text step.
- **Root cause:** Each frame was being encoded with FileReader, which is not on the Ink runtime's API list. The simulator is a full web environment, so the problem never surfaced there.
- **Handling:** Encode from the blob's `arrayBuffer()` with chunked `btoa` instead — the recipe is the worked example at the end of Section 3. FileReader also went onto the static-check list.

## 6. Changelog

### v1.14.0 2026-10-29

Rules for growing the table (GO's direction). Section 2 gains the six rules for adding codes: check for a synonym first; append only at the tail of a range; one code, one meaning, with the code following the failure; the three-part request; when a new range may be opened; and write the entry in full. The old request process and append rule fold into these six, and the versioning rule stands as its own item. All 84 code meanings untouched, word for word. (MINOR: spec addition.)

### v1.13.0 2026-10-29

Field notes change shape (GO's direction). The "Field-reported codes" section deleted in the previous release returns as Section 5, "Field cases" — each case records four things (symptom, reported code, root cause, handling), the first of them E2005, the stop-motion shoot that produced not a single frame. The sections after it renumber to 6 Changelog and 7 Why error codes. All 84 code meanings untouched, word for word. (MINOR: structural adjustment.)

### v1.12.0 2026-10-29

A section comes out (GO's direction). "Field-reported codes" is deleted, and the sections after it renumber to 5 Changelog and 6 Why error codes. Where E2005 came from is still told in Section 3's worked example and in Section 6. All 84 code meanings untouched, word for word. (MINOR: structural slimming.)

### v1.11.1 2026-10-29

No parentheses in headings or the contents (GO's direction). The instruction section is renamed "Before you start"; the H1 loses its bracketed English note; Section 3's title loses its bracketed suffix; dates in the changelog subheadings lose their brackets; the contents list follows suit. Content and all 84 code meanings unchanged. (PATCH: layout.)

### v1.11.0 2026-10-29

The standing rule joins the spec (GO's direction). Section 3 opens by establishing "error handling must never create new errors": the failure exit never throws, each reporting action fails silently on its own, and the main flow's outcome does not hinge on reporting actions. The section also states plainly that log upload is an independent, optional extra, completely silent when no key is configured or a send fails. A matching note is added at the end of the opening section. Section 4's table and all 84 code meanings untouched, word for word. (MINOR: spec addition.)

### v1.10.1 2026-10-29

Tone. The opening section drops its commanding voice and is rewritten as one developer plainly sharing a convention with peers, stating up front that these codes are not an official specification and that the maintainer, too, is just one of the developers. "Three prohibitions" becomes "Three things not to do". Content and all 84 code meanings unchanged. (PATCH: wording.)

### v1.10.0 2026-10-29

A full slimming pass (GO's direction). The "Why" section moves to the end of the document and is tightened; the "Prefixes (abolished)" section is deleted, its history staying in this log's v1.2.0 through v1.4.0 entries; the coding rules, governance, opening instructions, and field notes shed their internal phrasing and bracketed asides and are recast in a general developer register; the title drops "fleet"; the sections renumber to 1 Coding rules / 2 Governance / 3 Integration spec / 4 Code table / 5 Field-reported codes / 6 Changelog / 7 Why. The content of Sections 3 and 4 and all 84 code meanings are unchanged, word for word. (MINOR: structure and phrasing slimming.)

### v1.9.2 2026-10-29

Archiving (GO's direction). Snapshots of superseded versions now live uniformly in `base/error/` — file name `ERROR-CODES-v<version>.md`, an archive banner as the first line — while the repo root keeps only the latest version, and the governance section gains a "Version archive" item. This release backfills 17 historical snapshots, v1.1.0 through v1.9.1, into the archive. Two gaps are noted in the archive index: v1.0.0 has no surviving standalone snapshot (the canonical only reached the repo root at v1.1.0), and v1.5.3 shipped in the same commit as v1.5.4, so it has no standalone snapshot either. All 84 code meanings untouched, word for word. (PATCH: governance addition.)

### v1.9.1 2026-10-29

Layout. The changelog changes from a two-column table to entry form — one entry per version, the first line "version (date)" as a subheading and the content as a paragraph (GO's direction). The content of every earlier version and all 84 code meanings are unchanged, word for word. (PATCH: layout.)

### v1.9.0 2026-10-29

One file, settled (GO's direction). Only one file is needed: the distribution edition `ROKID-ERROR-CODES.md` is retired and deleted, its content merged into this file. This file gains a contents list and numbered sections (1 Rationale / 2 Rules / 3 Governance / 4 Integration spec / 5 Code table / 6 Prefixes / 7 Field codes / 8 Changelog), and an instructions section for AI agents is added at the front. Section 4's code examples are filled out into complete, copy-as-is form: the full err.js module, the photo and ASR wiring examples, the three static self-check greps, and the appendix with the correct way to turn a Blob into a dataURL. All 84 code meanings untouched, word for word. (MINOR: structure and spec completion.)

### v1.8.0 2026-10-29

Spec merged in (GO's direction). The distribution edition's integration instructions are folded into this table as a new "Integration spec (for developers and AI agents)" section — single-point definition (with a reference err.js form), mapping every failure point, the same code in three places, the README template, and the static self-check: five jobs in all. The governance section's integration requirement now points to that section. All 84 code meanings untouched, word for word. (MINOR: spec addition.)

### v1.7.0 2026-10-29

E6006 retired (GO's ruling). The code's trigger had been written as `availability` passing through a downloadable / downloading intermediate state — but a full audit of the official documentation that same day established that `LanguageModel.availability()` has exactly two states, available and unavailable, with nothing in between. The premise was a guess carried over from Chrome habits back then; the state does not exist. The code's meaning stays as written and will never be reused, and new development must not reference it again; an unavailable LLM is E6001 in all cases. Every other code unchanged, word for word. (MINOR: code status change.)

### v1.6.3 2026-10-29

Owning the first fault. GO pointed out that the original wording read as if it shifted the blame to the simulator: the official API reference is a closed list and FileReader is not on it, so the first fault was on the development side, for not checking against the list. The passage is rewritten in that order — an off-list API used first; the full web environment of the simulator and local preview hiding the fault second; the real device exposing it through E2005. The case for the table and the calls themselves are unchanged. (PATCH.)

### v1.6.2 2026-10-29

Changelog reformatted. At GO's direction it becomes a two-column table (version and date | content), and new entries are added in that format from here on. Every version's content unchanged, word for word. (PATCH.)

### v1.6.1 2026-10-29

A louder badge. At GO's direction, the struck-through "simulator" badge changes from dark gray to bright red (#e53935), and its inline display height goes from 18 to 20, so it reads at a glance. The calls and code meanings are unchanged. (PATCH.)

### v1.6.0 2026-10-29

Marks become badges. At GO's direction, the "Cannot be triggered in the simulator" column is deleted; in its place, each of the 29 codes carries a struck-through "simulator" badge at the end of its typical-trigger cell (new asset `assets/badges/badge-nosim.en.svg` — a marker private to this table, not a series badge). The marked set and all 84 code meanings are unchanged, word for word.

### v1.5.5 2026-10-29

No double-telling. At GO's direction, history already recorded in this changelog is no longer restated in the body: the coding rules drop the prefix trial history, the governance version rule drops its exception narrative, this table's version line keeps only the version number and date, and the prefix section and field notes are tightened in step. The rules themselves and the 84 codes are unchanged, word for word. From here on, the body states current rules only, and history lives in this log alone.

### v1.5.4 2026-10-29

Column definition tightened. GO pointed out that the original explanation of the "Cannot be triggered in the simulator" column was ambiguous; the definition now fits in one sentence — **yes = the failure cause behind the code is one the simulator cannot reproduce** (an interface missing from the real-device runtime, or the real behavior of the glasses' hardware and host services), so it never genuinely occurs there; **no = the cause is environment-independent and occurs in the simulator too**. The per-code calls are unchanged, word for word (29 yes / 55 no), and so are all 84 code meanings.

### v1.5.3 2026-10-29

Made generic. At GO's direction, this document becomes a general-purpose piece that other AI agents can use directly, and the whole text drops its pointers to any one specific AI assistant and to an internal working environment: the party who looks a failure up in the table is renamed "the maintainer", the registry no longer points at a specific working environment and serves only as a general maintainer, and explanations of an environment-specific local mirror path are deleted. All 84 code meanings and every column's calls are unchanged, word for word.

### v1.5.2 2026-10-29

"Why this table" reorganized. At GO's direction, the argument GO endorsed is arranged into the section: AV11 and FileReader serve as the ready counterexample (all green in the simulator, all dead on the real device, located through E2005 in this table); the line is drawn between what the simulator can cover and what it cannot, citing the official position that the final experience is judged on the real device; it is stated plainly that the official real-device pipeline ends at delivery and that runtime is a black box; and one further layer is added — error codes are not just a debugging tool but also the only failure language a user can remember and report under a small monochrome screen with no other information channel. The conclusion: the two are a division of labor, not a duplication. A wording reorganization only; all 84 code meanings and every column's calls unchanged, word for word.

### v1.5.1 2026-10-29

"Why this table" added. At GO's direction, the case for the table goes in ahead of the coding rules: the official real-device pipeline only ever confirms delivery (packaging and upload results, a resource-pack download success), while runtime errors have no return path, no record, and no entry point for viewing them; the simulator is a different runtime, in which the triggers of 29 codes do not exist; and on the glasses the screen is small, information is fleeting, screenshots are impossible while the camera is occupied, and relayed error text always comes out garbled — hence short codes meaning the same across the whole fleet, shown on screen, read by TTS, and reconciled in debugging through `lastError`. An explanatory addition only; all 84 code meanings and every column's calls unchanged, word for word.

### v1.5.0 2026-10-28

The "Cannot be triggered in the simulator" column. At GO's direction, the codes were checked for which triggers the Studio web simulator cannot reproduce, and the code table gained a column marking each one. The standard: a typical trigger that depends on the real-device Ink runtime, the glasses' hardware, host services, or device resource state is marked "yes" (the simulator has no such condition); a trigger independent of the environment, or one the browser has a like mechanism for, is marked "no". The result: 29 codes marked "yes" — 1xxx 3 (E1003/E1006/E1010), 2xxx 4 (E2002/E2005/E2006/E2007), 3xxx 7 (E3001/E3007/E3008/E3010/E3012/E3014/E3015), 4xxx 3 (E4006/E4007/E4011), 5xxx 1 (E5005), 6xxx 1 (E6010), 7xxx 7 (E7001/E7005/E7006/E7007/E7008/E7009/E7010), 8xxx 3 (E8002/E8004/E8005), 9xxx 0 — and the remaining 55 codes marked "no". All 84 code meanings unchanged, word for word. This column is, in effect, the "only real-device testing covers these" list: a clean run through the simulator proves none of these 29 codes will stay quiet (and the first field code, E2005, is one of them).

### v1.4.0 2026-10-28

Bare codes, settled. GO reversed the earlier call: the numeric range itself carries one meaning across the whole fleet, so a series prefix adds no locating information — it is redundant. The only form returns to the bare `E####` (code definitions, display, TTS, `lastError`, README, and debug all use it); series prefixes and the BA and short-code prefixes are all abolished. Which agent failed is pinned down by context and by the slug in `lastError`. The format changed three times on the night it was settled (numbered form → series form → bare codes), and none of the forms took hold anywhere — the one build that used the full concatenated form, AV11 v1.1.2 awaiting re-verification, was notified to correct it in its next version — so the change is still recorded as a minor version. This is the final format; absent a fresh order from GO, it will not change again. All 84 code meanings unchanged, word for word.

### v1.3.0 2026-10-28

One form, settled. At GO's direction, the whole fleet uses a single coding convention: the full code `<series code>E<4 digits>` becomes the only form (code definitions, display, TTS, `lastError`, README, and debug all align on it), and the bare `E####` is demoted to the registration form used inside this table only, forbidden at runtime and in communication. Within agent code, full codes are defined as literals and are no longer assembled at runtime. All 84 code meanings unchanged, word for word.

### v1.2.0 2026-10-28

Format fix, merged edition. GO's 23:22 correction of the reporting format: the prefix becomes the **series code**, written fully concatenated with no separator (AVE2005 / CCE1234 / BOE0002); the agent number occupies no code digits, and which specific agent it was is pinned down by the error context. The registry confirms that the unnumbered base series uniformly takes the **BA** prefix, and v1.0.0's short codes BENCH / PROBE / DABIAO / MYAGT, never enabled, are abolished unused. This release merges that format fix with the registry's v1.1.0 expansion (+39 codes) into the settled version: all 84 code meanings unchanged, word for word; only the format and the prefix register changed.

### v1.1.0 2026-10-28

The registry expands the table. The registry takes over this table and codes up every error currently knowable, working from the capability dossier's red lines, a full sweep of fleet code (OverconstrainedError in 23 places, six kinds of ASR error events, `LanguageModel` availability calls in 41 places, and the usage surface of isTypeSupported / decodeAudioData / createImageBitmap / getCurrentPosition, among others), and lessons already learned on real devices. 39 codes are added: 1xxx +5 (E1007–E1011), 2xxx +3 (E2011–E2013), 3xxx +10 (E3006–E3015), 4xxx +6 (E4006–E4011, the section title widening to "Recording, composition, and playback"), 5xxx +2 (E5004–E5005), 6xxx +6 (E6006–E6011), 7xxx +4 (E7007–E7010), 8xxx +3 (E8004–E8006), 9xxx +0. The existing 45 codes' meanings are unchanged, word for word. Governance gains the new-code request process and the version rules; the canonical takes its place at the repo root.

### v1.0.0 2026-10-28

The table is founded, expanded from AV11's field table: the reporting format, the numbered-prefix rules, some 45 codes across nine ranges, a register of unnumbered prefixes (BENCH/PROBE/DABIAO/MYAGT), and the governance skeleton.

## 7. Why error codes

At runtime on the real device there is no channel for logs to come back. Studio's packaging result and the phone app's resource-pack download notice prove only that the package reached the glasses; errors an agent hits once it is running have no return path, no record, and no place to view them. They can only come back as a user's report.

Nor can the simulator stand in for the real device. The simulator is a complete web environment, and its API list does not line up with the real-device runtime's: a whole class of problems shows no symptom at all in the simulator and surfaces only on the hardware. FileReader is the standing example — it runs in the simulator and simply does not exist in the device runtime. For the 29 codes marked in Section 4's table, the failure causes behind them cannot be produced by the simulator at all.

And the glasses themselves leave little room: a small, monochrome screen where information is gone in a moment. When something fails, the user cannot memorize the English error text, and retelling it garbles it beyond use; the one thing that can be reported exactly is a short code. Hence the standing convention — the error goes on screen in large type, TTS reads the code aloud, and the failure is written to `lastError` and kept. The user reports a single code, and the maintainer looks it up in this table and reconstructs the failure point.
