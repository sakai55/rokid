# Rokid Global Error Codes v1.14.0

[中文](ERROR-CODES.md) | English | [日本語](ERROR-CODES.ja.md)
Translated from the Chinese canonical, v1.14.0 (2026-10-29). In case of conflict, the Chinese version prevails.

Set by GO on 2026-10-28: whenever any Agent hits any error, the glasses show a unified error code. The user only has to report the code, and it can be located in this table.

**This is the only file you need**: the coding rules, governance, integration spec (with copy-ready code examples), and the full code table are all in this one file. See the contents for the sections. Any developer or AI agent can take the whole file and use it as is.

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

These error codes are not an official spec. They are a convention one developer has actually used across their own projects, shared with other developers and AI agents working on Rokid AIUI Agents. To wire error codes into an Agent, just follow the five steps below:

1. **Only codes from this table** (Section 4): use only codes that exist in the table. Do not invent codes, do not change what a code means, do not add any prefix. The only form is the bare code `E####`.
2. **Integration steps are in Section 3**: five things — single-point definition, full mapping of failure points, the same code in three places, a section in the README, and a static self-check. The code examples can be copied as is and then renamed or trimmed to fit your Agent. Do not design a different structure.
3. **How to pick a code**: look up the closest code for the failure point, segment by segment, in Section 4. If nothing fits, use the fallback code `E9001`, keep the original error text in `lastError`, and apply for a new code afterwards following the process in Section 2. Do not ship a self-invented code before the Registry replies.
4. **Three things not to do**: do not show the raw English error text directly to the user — the original text goes only into `lastError`. Do not use retired codes (currently E6006). Do not scatter code strings through business code; always go through the single-point definition module.
5. **Before packaging, run the static self-check in Section 3, step (5)**, and keep the grep results on record.

One more overarching principle: **error handling must not create new errors**. Code that reports, records, or sends back errors must never throw and never disturb the user. Details are at the start of Section 3.

## 1. Coding rules

- **Only form: the bare code `E<4 digits>`**, e.g. E2005. Code definitions, the glasses display, TTS readout, `lastError`, READMEs, and debugging conversations all use only the bare code, with no prefix of any kind.
- **Same code, same meaning**: the same code means the same thing in every Agent. Which Agent it came from is pinned down by the error context and by the slug and version recorded in `lastError`.
- **Segments are split by error domain**, not by Agent:
  - 1xxx Camera and image capture
  - 2xxx Frame data and encoding conversion
  - 3xxx Voice ASR / TTS
  - 4xxx Recording, composition, and playback
  - 5xxx Storage and files
  - 6xxx Network and large models
  - 7xxx Sensors, positioning, and detection
  - 8xxx Pages and runtime
  - 9xxx System fallback: E9001 uncategorized fallback, E9002 host or system-level exception

## 2. Governance

- **Maintainer**: this table is maintained solely by the Registry. New code assignment and segment expansion both go through the Registry. Do not occupy a code on your own.
- Once assigned, a code **never changes meaning and is never reused**. Retired codes keep their original meaning and are marked "Retired".
- **Table expansion convention** — to add a new code to this table, follow these six rules:
  1. **Check for a synonym first**: search the whole table for a code with the same meaning or one that can be reused. If one exists, use it; do not open a new code.
  2. **Append only at the end of the segment**: new codes go in order at the end of their segment. No inserting numbers, and do not take over a slot left empty by a retired code.
  3. **One code, one meaning; the code follows the failure**: one code corresponds to exactly one kind of failure. The same failure uses the same code in whichever Agent it appears; do not create separate codes per Agent or per page.
  4. **Three things in an application**: the failure point, the original trigger text, and your proposed segment. The Registry checks and then assigns and replies with the code. Do not ship a self-proposed code before the reply. In an urgent field situation, use E9001 as a fallback first, keep the original text in `lastError`, and apply for the proper code afterwards.
  5. **When a new segment may be opened**: only when none of the nine segments fits, or a segment's numbers are exhausted, may the Registry open a new segment, and the changelog must state the new segment's domain.
  6. **Write the full entry when it lands**: write the new code's description and typical trigger clearly, with the trigger describing a concrete situation. If you can judge whether the simulator can reproduce the cause, decide at the same time whether to add the "simulator" badge.
- **Version rules**: adding codes only bumps the minor version; changes to rules or format bump the major version; pure wording or layout fixes bump the patch version. Every version bump gets one entry in the changelog.
- **Version archive**: at every version bump, a full snapshot of the superseded version is stored in `base/error/ERROR-CODES-v<old version>.md`, and the repo root keeps only the latest version. Current rules and code meanings follow the root latest version only.
- Integration for each Agent follows Section 3, "Integration spec".
- This table's version: v1.14.0, 2026-10-29. Location: `ERROR-CODES.md` at the repo root. Copies may be kept inside individual Agent projects; in case of conflict, the root version prevails.

## 3. Integration spec

**Overarching principle: error handling must not create new errors.** Code added for the sake of error reporting — on-screen display, speech readout, writing `lastError`, log queues and log return — must never become a new source of errors itself: the unified failure exit never throws; each action that fails is swallowed silently on its own; whether the main flow succeeds or fails must not change because of an error-reporting action. Log return is an independent optional extra. Not wiring it in does not affect any rule in this spec. If it is wired in but no key is configured, or a send fails, it likewise stays completely silent and does not add confusion for the user.

To wire an agent into this table, do five things:

**(1) Single-point definition.** Create an error-code module in the project (like `err.js` below) and define the codes this Agent uses, as bare-code literals, in exactly one place. Do not scatter code strings through business code, and do not build prefixes at runtime. The module below can be copied as is; just add or remove entries in the `ERR` and `MESSAGES` tables to match the codes your Agent uses:

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

**(2) Map every failure point.** Walk through every call in the code that can fail (camera, encoding, ASR/TTS, LLM, network, storage, sensors, page navigation, …) and map each failure point to one code from the table. When there is no fitting code, use E9001 and keep the original text. Do not just throw the raw text and be done with it — the original text is only an attached diagnostic, shown truncated or kept only in `lastError`. Wire it up following the two examples below:

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

**(3) The same code in three places.** When a failure happens, the same code appears in three places:

- **On-screen display**: the code in large type + one line of description (e.g. `E2005 Encoding to text failed`);
- **TTS**: for errors that stop the machine or stop capture automatically, read only the code itself (e.g. "E2005"), never the original text;
- **`lastError`**: written to this Agent's persistent storage, with fields for the code, this Agent's slug, its version, and the original error text. After the user reports the code, the maintainer uses this to locate the entry in the table.

**(4) A section in the README.** Add an "Error codes" section to the Agent's README, listing the codes this Agent actually uses and one line about how to report (template):

```markdown
## Error codes
This Agent follows the global error code table (bare codes E####). On error, the code is shown on screen and spoken aloud,
and the most recent error is kept in lastError. When reporting a problem, please include the code shown on the glasses.
Used by this Agent: E1001, E1002, E2005, E3001, E9001.
```

**(5) Static self-check.** Before packaging, run the three commands below and keep the results on record:

```bash
grep -rn "FileReader" <project dir>                 # must be 0 hits (this API does not exist in the runtime)
grep -rEoh "E[0-9]{4}" <project dir> | sort -u      # every code this Agent uses; check each against Section 4
grep -rn "'E[0-9]" <business code dir> --include=*.js | grep -v err.js
                                                 # code strings scattered in business code; must be 0 hits
```

**Appendix example: the correct way to convert a Blob to a dataURL (where E2005 came from).** The AIUI API surface is a fixed list: browser APIs that are not in the official reference (such as `FileReader`) do not exist in the runtime. When you need to turn a Blob into text, write it as below; do not use FileReader:

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

(The `E####` form in the table below is the only form in use — the same across the whole fleet, with no prefix.)

A typical-trigger cell ending with the struck-through "simulator" badge <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> means the failure cause behind that trigger cannot be reproduced by the simulator (for example, an interface missing from the real-device runtime, or the real behavior of the glasses hardware and host services); it can only be met in real-device testing. Triggers without the badge are environment-independent and happen in the simulator too. There are 29 badge occurrences in the whole table. When registering a new code, judge at the same time whether to add the badge.

### 1xxx Camera and framing
| Code | Description | Typical trigger |
|---|---|---|
| E1001 | Camera failed to open | getUserMedia throws / is rejected (non-permission class) |
| E1002 | Camera permission not granted | NotAllowedError / permission denied |
| E1003 | Image capture device unavailable | ImageCapture construction fails / does not exist <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E1004 | Frame grab failed | grabFrame throws on a single call |
| E1005 | Repeated frame grab failures | preview rendering fails repeatedly |
| E1006 | Camera stream interrupted | track ended / stream withdrawn <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E1007 | No camera device | NotFoundError: no usable camera / no device matches the constraints |
| E1008 | Camera not readable | NotReadableError: camera busy or hardware read failure, track cannot start |
| E1009 | Photo capture failed | takePhoto throws or returns empty |
| E1010 | Photo mode unavailable | the requested wide / telephoto / default mode is not supported <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E1011 | Framing constraints not satisfied | video constraint OverconstrainedError and the fallback to defaults also fails |

### 2xxx Frame capture and encoding
| Code | Description | Typical trigger |
|---|---|---|
| E2001 | Frame capture failed during shooting | grabFrame throws while shooting |
| E2002 | Canvas creation failed | Canvas unavailable <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2003 | Encoding failed (canvas) | convertToBlob throws / returns empty |
| E2004 | Encoding failed (direct) | createImageBlob throws / returns empty |
| E2005 | Encoding to text failed | Blob→dataURL failed (including missing FileReader; the first field code, E2005, from AV11) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2006 | Encoding timed out, switched mode | encoding timeout circuit-breaker tripped; switched to the backup mode <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2007 | No usable frame output path | both the primary and backup frame output paths are unavailable <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E2008 | In-memory frame read failed | getImageData throws and bitmap-direct storage also fails |
| E2009 | Single-frame processing timeout | watchdog forced reset |
| E2010 | Stopped after repeated failures | repeated failures reached the cap and shooting stopped automatically (main code in lastError) |
| E2011 | Image decoding failed | createImageBitmap throws while decoding a photo / frame data |
| E2012 | Image source empty | drawImage source is empty or has been invalidated (InvalidStateError) |
| E2013 | Text encoding failed | arrayBuffer / chunked btoa conversion throws (a failure of the no-FileReader replacement path itself) |

### 3xxx Voice ASR / TTS
| Code | Description | Typical trigger |
|---|---|---|
| E3001 | Speech recognition unavailable | SpeechRecognition does not exist <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3002 | Speech recognition did not start | rec.start() throws |
| E3003 | Speech recognition error | rec.onerror (fallback for unrefined events) |
| E3004 | Speech recognition keeps dropping | onend restarts fail repeatedly |
| E3005 | Speech output failed | speechSynthesis.speak throws |
| E3006 | No speech input | ASR event no-speech: silence timeout, no voice |
| E3007 | Microphone capture failed | ASR event audio-capture: host-side audio capture failed <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3008 | Recognition permission not granted | ASR event not-allowed: RECORD_AUDIO not authorized <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3009 | Recognition network error | ASR event network: recognition service network failure |
| E3010 | Microphone mode fell back | OverconstrainedError: the exact microphone mode cannot be satisfied; fell back to the default mode (AV04 field case; referenced in 23 places across the fleet) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3011 | Microphone stream acquisition failed | getUserMedia audio stream throws (non-permission, non-constraint class) |
| E3012 | Recognition service unavailable | ASR event service-not-allowed <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3013 | Recognition language not supported | ASR event language-not-supported |
| E3014 | Recognition session configuration failed | SpeechRecognitionSession hot words / VAD / updateContext update rejected (AV05) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E3015 | Speech synthesis failed | speechSynthesis.synthesize throws on the generation side (distinct from E3005's speak playback failure, AV06) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 4xxx Recording, composition, and playback
| Code | Description | Typical trigger |
|---|---|---|
| E4001 | No frames to compose | finished with 0 frames |
| E4002 | Frame decoding failed | frame data → ImageBitmap decoding throws |
| E4003 | Playback rendering failed | playback drawImage throws |
| E4004 | Playback frame rate too low | measured rate below half the setting |
| E4005 | Frame data lost | frames no longer match the record after crossing pages / sessions |
| E4006 | Recorder unavailable | MediaRecorder does not exist / construction fails <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E4007 | Recording format not supported | isTypeSupported rejects every candidate format (AV03 probe) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E4008 | Recording start failed | MediaRecorder.start throws |
| E4009 | Recording has no data | ondataavailable has no data / all chunks empty |
| E4010 | Audio decoding failed | decodeAudioData throws (AV04 analysis path) |
| E4011 | Audio playback failed | SpeechAudioPlayer / media element playback throws <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 5xxx Storage
| Code | Description | Typical trigger |
|---|---|---|
| E5001 | Record save failed | localStorage / wx storage write throws |
| E5002 | Record read failed | read / JSON parse throws |
| E5003 | Storage space insufficient | write rejected by quota |
| E5004 | Saved data version incompatible | persisted data structure version mismatch; parse or migration fails |
| E5005 | Persistence unavailable | localStorage / storage interface does not exist or is disabled <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |

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
| E6010 | Domain not on the allowlist | the request domain was not filed on the allowlist and is blocked by the host <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E6011 | Large model output unusable | empty response or structure not as expected; cannot be parsed into business data |

### 7xxx Sensors, positioning, and detection
| Code | Description | Typical trigger |
|---|---|---|
| E7001 | Orientation sensor unavailable | AbsoluteOrientationSensor construction / start fails <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7002 | Positioning failed | getCurrentPosition error 2/3 |
| E7003 | Positioning permission not granted | getCurrentPosition error 1 |
| E7004 | Barcode detection failed | BarcodeDetector.detect throws |
| E7005 | Barcode format not supported | getSupportedFormats does not include the target format <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7006 | Gesture channel abnormal | enabling world awareness fails; enableWorldAwareness throws <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7007 | Inertial sensor unavailable | Accelerometer / Gyroscope construction or start fails <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7008 | Sensor has no data | sensor started but no reading within the timeout (benchmark orientation / motion item timeout class) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7009 | Barcode detector unavailable | BarcodeDetector does not exist / construction fails (distinct from E7004's detect throw) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E7010 | Head calibration failed | calibration cannot complete, or the calibration center drifts too far (head games / directional class) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |

### 8xxx Pages and runtime
| Code | Description | Typical trigger |
|---|---|---|
| E8001 | Page navigation failed | wx.navigateTo / navigateBack throws |
| E8002 | Page reclaimed by the system | abnormal onUnload with the task unfinished <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E8003 | Permission not declared | the called capability does not match the permissions in app.json (development-time self-check code) |
| E8004 | Runtime interface missing | a required global interface does not exist (generic code for "X is not defined"; FileReader in an encoding context goes to E2005) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E8005 | Input event did not reach the page | key / gesture events not delivered to the page (development-time self-check code: onKeyDown not wired, or the bindtap-only class that cannot be triggered on a real device) <img src="assets/badges/badge-nosim.svg" height="20" alt="Cannot be triggered in the simulator"> |
| E8006 | Session state lost | session state missing after crossing pages / re-entering (media frame loss goes to E4005) |

### 9xxx System
| Code | Description | Typical trigger |
|---|---|---|
| E9001 | Uncategorized error | fallback (original text attached, truncated) |
| E9002 | Configuration missing | a required configuration / constant is empty |

## 5. Field cases

Cases that really happened on a real device and were located via an error code. Each entry records four things: symptom, reported code, root cause, handling.

### Case 1, E2005: stop-motion, not a single frame came out

- Symptom: a stop-motion Agent's first real-device test — shooting ran the full 180 seconds and exited automatically, with 0 frames.
- Reported code: the glasses showed E2005; after the user reported the code, it was located in the table at the encoding-to-text step.
- Root cause: per-frame encoding used FileReader, which is not in the Ink runtime's API list; the simulator is a complete Web environment, so it was never exposed there.
- Handling: switched to the blob's arrayBuffer plus chunked btoa — see the appendix example in Section 3. FileReader was also added to the static check list.

## 6. Changelog

### v1.14.0 2026-10-29

Table expansion convention (GO directive): Section 2 gains the six-rule "Table expansion convention" — check for a synonym first, append only at the end of the segment, one code one meaning and the code follows the failure, three things in an application, the conditions for opening a new segment, and write the full entry when it lands. The previous application process and append rule are folded into this convention, and the version rule becomes its own item. The meanings of the 84 codes are unchanged, not a word (MINOR: spec addition).

### v1.13.0 2026-10-29

Field records change form (GO directive): the "Field-reported codes" section deleted in the previous version returns as "Field cases" in Section 5 — each case records four things (symptom, reported code, root cause, handling), the first being E2005, stop-motion with not a single frame out. The following sections shift to 6 Changelog and 7 Why error codes. The meanings of the 84 codes are unchanged, not a word (MINOR: structural adjustment).


### v1.12.0 2026-10-29

Section removed (GO directive): the "Field-reported codes" section is removed, and the following sections shift to 5 Changelog and 6 Why error codes. Where E2005 came from is still written in the appendix example in Section 3 and in Section 6. The meanings of the 84 codes are unchanged, not a word (MINOR: structural slimming).


### v1.11.1 2026-10-29

No brackets in titles or the contents (GO directive): the instruction section is renamed "Before you start"; the top-level title drops the English bracketed note; Section 3's title drops its bracketed suffix; the dates in the changelog entry subheadings drop their brackets; the contents are synced. Content and the meanings of the 84 codes unchanged (PATCH: layout).


### v1.11.0 2026-10-29

Overarching principle enters the spec (GO directive): the start of Section 3 establishes "error handling must not create new errors" — the failure exit never throws, each action's failure is silent on its own, and whether the main flow succeeds does not change because of error-reporting actions. It also states plainly that log return is an independent optional extra, completely silent when no key is configured or a send fails. A matching overarching-principle note is added at the end of the instruction section. Section 4's table and the meanings of the 84 codes are unchanged, not a word (MINOR: spec addition).

### v1.10.1 2026-10-29

Tone: the opening of the instruction section loses its commanding tone and is reworded as a plain statement of a convention shared between developers, stating plainly that these error codes are not an official spec and that the maintainer is also just one of the developers. "Three prohibitions" is renamed "Three things not to do". Content and the meanings of the 84 codes unchanged (PATCH: wording).

### v1.10.0 2026-10-29

Full-text slimming (GO directive): the "Why" section moves to the end of the document and is compressed; the "Prefixes (abolished)" section is deleted, its history staying in the v1.2.0 to v1.4.0 entries of this log; the coding rules, governance, instructions, and field records lose their internal phrasing and bracketed asides and are rewritten in a general developer register; the title drops "fleet"; sections are renumbered as 1 Coding rules / 2 Governance / 3 Integration spec / 4 Code table / 5 Field-reported codes / 6 Changelog / 7 Why. The content of Sections 3 and 4 and the meanings of the 84 codes are unchanged, not a word (MINOR: structure and phrasing slimming).


### v1.9.2 2026-10-29

Archive system (GO directive): snapshots of old versions are uniformly stored in `base/error/` (file name `ERROR-CODES-v<version>.md`, with an archive banner as the first line), the repo root keeps only the latest version, and the governance section gains a "Version archive" item. This round backfills 17 historical snapshots, v1.1.0–v1.9.1, into the archive. v1.0.0 has no surviving standalone snapshot (the canonical landed at the repo root starting from v1.1.0), and v1.5.3 landed in the same commit as v1.5.4 with no standalone snapshot; both gaps are noted in the archive index. The meanings of the 84 codes are unchanged, not a word (PATCH: governance addition).

### v1.9.1 2026-10-29

Layout: the changelog changes from a two-column table to entry form — one entry per version, with the first line "version (date)" as a subheading and the content as a paragraph (GO directive). The content of all previous versions and the meanings of the 84 codes are unchanged, not a word (PATCH: layout).

### v1.9.0 2026-10-29

Single-file final form (GO directive): only one file is needed — the distribution edition `ROKID-ERROR-CODES.md` is retired and deleted, its content merged into this file. This file gains a contents list and numbered sections (1 Rationale / 2 Rules / 3 Governance / 4 Integration spec / 5 Code table / 6 Prefixes / 7 Field codes / 8 Changelog), and an "Instructions for AI agents" section is added at the start. Section 4's code examples are completed into copy-ready full form (the complete err.js module, photo/ASR wiring examples, three static self-check greps, and the appendix with the correct Blob-to-dataURL writing). The meanings of the 84 codes are unchanged, not a word (MINOR: structure and spec completion).

### v1.8.0 2026-10-29

Spec merged in (GO directive): the distribution edition's "Integration instructions" are merged into this table, adding the "Integration spec (for developers and AI agents)" section — single-point definition (with an err.js reference form), full mapping of failure points, the same code in three places, the README template, and the static self-check: five things. The governance section's integration requirement now points to that section. The meanings of the 84 codes are unchanged, not a word (MINOR: spec addition).

### v1.7.0 2026-10-29

E6006 retired (GO ruling): the code's original trigger was written as availability being in a downloadable / downloading intermediate state — a full audit of the official docs the same day established that `LanguageModel.availability()` has only the two states available / unavailable; that premise was a guess made back then following Chrome habits and does not exist. The code's meaning is kept as is and never reused, and new development must not reference it again; when the large model is unavailable, use E6001 in all cases. All other codes unchanged, not a word (MINOR: code status change).

### v1.6.3 2026-10-29

Honest attribution in the first paragraph: GO pointed out that the original wording looked like shifting the blame to the simulator — the official API reference is a fixed list and FileReader is not on it, so the first fault lies on the development side for not checking against the list. Rewritten as: development-side use of an off-list API came first, the complete Web environment of the simulator and local preview hid the fault after that, and the real device exposed it via E2005. The rationale for the table and the judgments are unchanged (PATCH).

### v1.6.2 2026-10-29

Changelog relayout: per GO directive it changes to a two-column table (version date | content), and future entries are appended in this format. The content of every version is unchanged, not a word (PATCH).

### v1.6.1 2026-10-29

Badge made conspicuous: per GO directive — the struck-through "simulator" badge changes from dark gray to bright red (#e53935), and its inline display height goes from 18 to 20, visible at a glance. Judgments and code meanings unchanged (PATCH).

### v1.6.0 2026-10-29

Marks become badges: per GO directive the "Cannot be triggered in the simulator" column is deleted — the marks for the 29 codes change to a struck-through "simulator" badge at the end of the typical-trigger sentence (new file `assets/badges/badge-nosim.svg`; a mark dedicated to this table, not a series badge). The judged set and the meanings of the 84 codes are unchanged, not a word.

### v1.5.5 2026-10-29

Deduplication of explanation: GO directive — history already recorded in the changelog is not restated in the body text: the coding rules drop the prefix trial history, the governance version rule drops the exception narrative, the version line of this table keeps only the version number and date, and the prefix section and field records are tightened in sync. The rules themselves and the 84 codes are unchanged, not a word. From now on the body text states only current rules, and history goes only into this log.

### v1.5.4 2026-10-29

Column definition tightened: GO pointed out that the original explanation of the "Cannot be triggered in the simulator" column was ambiguous. The definition becomes one sentence — **Yes = the failure cause behind this code cannot be produced by the simulator** (for example, an interface missing from the real-device runtime, or the real behavior of the glasses hardware and host services); it does not really happen in the simulator. No = the cause is environment-independent and happens in the simulator too. The per-code judgments are unchanged, not a word (29 yes / 55 no), and the meanings of the 84 codes are unchanged.

### v1.5.3 2026-10-29

Generalization: GO directive — this document is made into a general-purpose piece for other AI agents to use directly, and the whole text drops pointers to a specific AI assistant and internal working environment: the party who locates entries in the table is renamed "maintainer", the Registry no longer points to a specific working environment and serves only as a general maintainer, and environment-specific local mirror path explanations are deleted. The meanings of the 84 codes and the judgments in every column are unchanged, not a word.

### v1.5.2 2026-10-29

The "Why this table" section reorganized: per GO directive, the argument GO endorsed is arranged into this section — using AV11 / FileReader as a ready counterexample (all green in the simulator, all dead on the real device, located via E2005 in the table), drawing the line between what the simulator can and cannot cover (and citing the official line that "the final experience should be based on the real device"), making plain that the official real-device chain ends at delivery and the runtime period is a black box, and adding one more layer: error codes are not only a debugging tool, but also the only failure language a user can remember and report under small monochrome screen conditions with no other information channel. Conclusion: the two are a division of labor, not a duplication. Pure text reorganization; the meanings of the 84 codes and the judgments in every column are unchanged, not a word.

### v1.5.1 2026-10-29

The "Why this table" section: per GO directive, a rationale for the table is added before the coding rules: the official real-device chain only signals delivery (packaging upload results, resource pack download success); runtime errors have no return path, no record, and no viewing entry. The simulator is a different runtime, and the triggers of 29 codes do not exist in it. On the glasses the screen is small, information is fleeting, screenshots are impossible while the camera is busy, and relaying the original text inevitably distorts it — hence short codes with the same meaning across the whole fleet, shown on screen + read by TTS + aligned in debugging via `lastError`. Pure explanatory addition; the meanings of the 84 codes and the judgments in every column are unchanged, not a word.

### v1.5.0 2026-10-28

The "Cannot be triggered in the simulator" column: per GO directive, which codes' triggers the Studio web simulator cannot reproduce was checked, and the code table gains a column marking each code. Judgment standard: a typical trigger that depends on the real-device Ink runtime / glasses hardware / host services / device resource state is marked "yes" (the simulator does not have that condition); environment-independent triggers, or ones where the browser has a similar mechanism, are marked "no". Result: 29 codes marked "yes" — 1xxx: 3 (E1003/E1006/E1010), 2xxx: 4 (E2002/E2005/E2006/E2007), 3xxx: 7 (E3001/E3007/E3008/E3010/E3012/E3014/E3015), 4xxx: 3 (E4006/E4007/E4011), 5xxx: 1 (E5005), 6xxx: 1 (E6010), 7xxx: 7 (E7001/E7005/E7006/E7007/E7008/E7009/E7010), 8xxx: 3 (E8002/E8004/E8005), 9xxx: 0; the remaining 55 codes marked "no". The meanings of the 84 codes are unchanged, not a word. This column is exactly the "real-device coverage only" list: an all-green simulator proves nothing about these 29 codes not triggering (the first field code, E2005, is one of them).

### v1.4.0 2026-10-28

Bare codes finalized: GO reversed the ruling — the numeric segment itself has one unique meaning across the whole fleet, and series prefixes add no extra locating information; they are superfluous. The only form returns to the bare code `E####` (code definitions / display / TTS / lastError / README / debug all use it), and series prefixes and the BA / short-code prefixes are all abolished. Agent identity is pinned by context and the slug in `lastError`. The format changed three times on the night it was finalized (numbered form → series form → bare codes), and none of them formed existing stock (the only build that used the full concatenated form, AV11 v1.1.2 awaiting re-verification, has been notified to fix it in its next version), so it is still recorded with a minor version; this is the final format and will not change again unless GO orders otherwise. The meanings of the 84 codes are unchanged, not a word.

### v1.3.0 2026-10-28

Only form finalized: per GO directive, the whole fleet uses one set of coding rules — the full code `<series code>E<4 digits>` is set as the only form (code definitions / display / TTS / lastError / README / debug all align on it), the bare `E####` is demoted to the registration form used only inside this table, forbidden at runtime and in communication. Inside agent code, full codes are defined as literals and no longer concatenated at runtime. The meanings of the 84 codes are unchanged, not a word.

### v1.2.0 2026-10-28

Merged format-fix edition: GO's 23:22 correction of the reporting format — the prefix changes to a **series code**, fully concatenated with no separator (AVE2005 / CCE1234 / BOE0002). The unit number does not occupy code digits; which specific unit it is gets pinned by the error context. The Registry confirms that the unnumbered base series uniformly uses the **BA** prefix, and v1.0.0's BENCH / PROBE / DABIAO / MYAGT short codes are abolished before ever being used. This version merges that format fix with the Registry's v1.1.0 expansion (+39 codes) into the final form: the meanings of the 84 codes are unchanged, not a word; only the format and the prefix register changed.

### v1.1.0 2026-10-28

Registry expansion: the Registry takes over this table. It enumerates all error information currently knowable and encodes it. Basis: red lines from the capability dossier, a full inspection of fleet code (OverconstrainedError in 23 places, six kinds of ASR error events, LanguageModel availability calls in 41 places, and the reference surface of isTypeSupported / decodeAudioData / createImageBitmap / getCurrentPosition, among others), plus existing real-device lessons. 39 codes are added: 1xxx +5 (E1007–E1011), 2xxx +3 (E2011–E2013), 3xxx +10 (E3006–E3015), 4xxx +6 (E4006–E4011, with the segment title expanded to "Recording, composition, and playback"), 5xxx +2 (E5004–E5005), 6xxx +6 (E6006–E6011), 7xxx +4 (E7007–E7010), 8xxx +3 (E8004–E8006), 9xxx +0. The meanings of the existing 45 codes are unchanged, not a word. Governance gains the "Applying for a new code" process and the version rules; the canonical lands at the repo root.

### v1.0.0 2026-10-28

Table established: grown out of AV11's field table — the reporting format, numbered prefix rules, roughly 45 codes in nine segments, a register of unnumbered prefixes (BENCH/PROBE/DABIAO/MYAGT), and the governance skeleton.

## 7. Why error codes

During the real-device runtime period there is no log return: Studio's packaging result and the phone App's resource-pack download prompt only prove that the package reached the glasses. Errors that occur after the Agent starts running have no return path, no record, and no viewing entry; they can only be reported by the user.

The simulator cannot stand in for the real device: the simulator is a complete Web environment, and its API list does not match the real-device runtime's. A whole class of problems shows no sign at all in the simulator and is exposed only on the real device. For example, FileReader runs fine in the simulator and simply does not exist in the real-device runtime. For the 29 codes marked in the code table in Section 4 of this document, the failure causes cannot be produced by the simulator.

On the glasses the screen is small and monochrome, and information is fleeting. When an error occurs, the user cannot remember the English original text, and relaying it inevitably distorts it; the only thing that can be reported accurately is a short code. Hence the unified convention: errors are shown in large type on screen, read aloud by TTS as codes, and written to `lastError` for keeping. The user reports one code, and the maintainer can restore the failure point by looking it up in the table.
