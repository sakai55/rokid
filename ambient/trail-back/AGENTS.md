# Trail Back — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series E04 (AMBIENT 环境型， fourth of the group, series #49): you wander
a mall, a gallery or a big car park for a while and then have no idea
how to get back. This agent takes the way back off your hands: you mark
key junctions as breadcrumbs (direction + photo) as you go, and the
return walk guides you point by point in reverse order.

## Design contract

- **It is not navigation, and the UI never pretends it
  is.** The platform has no indoor positioning and no GPS
  route planning. A breadcrumb is only a direction you
  recorded plus a photo label — not a map — and the UI and
  README say exactly that.
- **The reverse direction is a reversed hint, not a
  measured route.** Returning shows the opposite of the
  direction recorded at each crumb (DEMO stages use staged
  sector angles: 前→后, 右→左, 后→前). A user MARK records
  the generic hint "登记时的反方向" — the agent does not
  measure your return route, and the README says so.
- **Photos are a same-session对照 aid, never stored.**
  A crumb keeps a label (示例画面 / 已拍画面), never an
  image file. The photo is taken on MARK (wide mode, like
  room-sweep) and only helps you recognise the junction on
  the way back; a failed photo only notes itself and the
  crumb still stands.
- **Junctions are yours to judge.** The agent does not
  know which junction matters: you decide where to MARK,
  and the README says so.
- **A nod never records a crumb and never confirms an
  arrival.** A crumb comes from looking steady at a
  junction and tapping MARK, an arrival from standing at
  the point and tapping ARRIVED — a nod must not invent
  either. A steady nod in idle starts marking and in
  summary confirms it.
- **Correction is cheap, destruction is confirmed.** BACK
  from marking or returning returns to idle with the
  session kept, and START resumes the same round; BACK
  from the summary returns to the mode it came from
  without deleting anything, and the summary is rebuilt
  on END. Confirming the summary (END while a summary is
  open, or a steady nod) is the only wipe. There is no
  DEL key.
- **The session lives in session memory only — zero persistence,
  by design.** Crumbs, arrivals and the return walk die
  when the summary is confirmed and when the agent closes
  (onUnload wipes everything). Close the agent and the
  trail is gone.
- **Not a navigator, not a health tool.** The agent does
  not plan routes, does not track your position, and does
  not adapt thresholds to anything: the crumb cap (8) is
  fixed, and the UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). Return
  guidance speaks once when the walk starts; SPEAK re-reads
  only on an explicit tap.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `room-sweep` (C02) is a pre-departure
  room-by-room check. Trail-back photographs nothing to
  check: its photos are return-walk对照 labels attached
  to junction crumbs.
- Attention-series `cue-bag` (P04) is an exit luggage
  gate: items confirmed before leaving. Trail-back gates
  nothing before leaving: it records the way out so the
  way back exists.
- Attention-series `light-change` (E01) meters light on
  a timer. Trail-back meters nothing on a timer: its only
  input is your MARK at a junction.

## Permissions

CAMERA only (app.json `permissions` is exactly
`["CAMERA"]`, and the static check asserts exactly
that): crumb photos need the camera. No `RECORD_AUDIO`:
nothing is listened to. No `GEOLOCATION`: this agent
never knows where anyone is.

## Validation

- Node harness (see `/tmp/trail-back-harness.js`, not packed):
  app.json pages and permissions exactly `["CAMERA"]`;
  zero storage/location/audio APIs, no utterance language
  assignment, no legacy Page/App; foot2 honesty lines
  asserted （它不是导航、没有室内定位、没有 GPS 路径规划、
  不是地图、反向提示、会话内即弃、不存档、不上传、路口是
  你自己判断登记的、只存本次会话、关掉即清、零落盘）;
  initial idle state （bigText 还没开始， placeholder row,
  countLine); idle refusals (MARK ignored, RETURN/END
  refused missing, BACK ignored); start + steady discipline
  (START refused while marking, unsteady MARK refused,
  steady MARK records crumb with reverse 登记时的反方向
  and 示例画面， photo failure noted with crumb kept, 8
  crumb cap, 9th refused); focus walks rows with wrap,
  rowTap out-of-range and missing-dataset guards (missing
  dataset keeps focus, never jumps to 0 — the B05 page bug,
  fixed here by construction); return walk (RETURN refused
  with zero crumbs, target last, exactly one TTS naming
  it, NEXT/PREV at the ends refused, ARRIVED advances,
  final ARRIVED completes the summary); summary flow (END
  from marking kept, BACK rebuilds, END confirms and
  clears, BACK marking to idle keeps session with START
  resume); nod discipline (unsteady ignored without
  arming, steady nod in idle starts, lock blocks a second
  nod, lock expiry works, nod in marking/returning ignored
  as not-a-crumb/not-an-arrival, non-nod gesture noted);
  key discipline (Enter per-mode, ArrowUp/Down walk,
  Backspace returns); SPEAK lines per mode; sector and
  reverse helpers (0→前, 90→右, 180→后, 270→左, reverse
  0→后, 90→左, 180→前）; DEMO six-stage arc (marking 2,
  registered 3, returning to 路口3 reverse 前 with one
  TTS, returning to 路口1 arrived 2, summary crumbs 3
  arrived 3 complete) and refusal on user sessions;
  onUnload wipes everything; bigCls thresholds.
  Result: **105/105** (first run, no harness fixes, no
  page fixes).
- Preview screenshots 6, each visually verified (not just
  hash-compared): idle (not started), marking (DEMO stage
  1, 2 crumbs), registered (DEMO stage 2, 3 crumbs),
  returning (DEMO stage 3, target 路口3 reverse 前),
  returning first point (DEMO stage 4, target 路口1,
  arrived 2), summary (DEMO stage 5, crumbs 3, arrived 3,
  back at start). Button coordinates were probed per state
  and every PNG re-verified by eye (see
  `shot-trail-back.js` in `~/workspace/preview-tools/`).
  Probe findings worth keeping: DEMO (66,170) hits in ALL
  states here (the extra BACK row keeps the band stable);
  the first probe run came back blank because the sed
  importmap rewrite had produced `//ink/index.js`
  (protocol-relative, resolved to `http://ink/`) — the www
  copy must contain exactly `/ink/index.js`. DEMO is a
  staged sample, not a live walk: crumbs and reverse
  directions are staged values, not sensor readings.
