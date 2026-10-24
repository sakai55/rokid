# Buy Filter — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series F03 (FILTER 过滤型， third of the group): in a supermarket, every
shelf and promotion shouts for attention and the thing you actually came
for hides among them. This agent inverts the work: you declare the filter
first — a shopping list, a per-item budget cap, a ban keyword — then shop,
and only a product that satisfies all three conditions is allowed to
surface.

## Design contract

- **Declare first, filter second, and the filter rule never changes
  mid-shop.** The list (DEMO sample pools: 牛奶·面包·鸡蛋 /
  苹果·香蕉·酸奶 / 米·面·食用油）, the budget cap (30 / 50 / 100 元/件）
  and the ban keyword （无 / 花生 / 乳糖 / 麸质） can only change in
  idle. Changing the filter mid-shop would silently rewrite what counts
  as a pass while the wearer is trusting the filter — so every
  LIST/BUDGET/BAN tap while shopping is refused with an explanation,
  never silently applied. This is the same idle-only-settings discipline
  as F01's whitelist and F02's target.
- **The match rule is three conditions, and it is the headline.**
  A product passes only when ALL THREE hold: (1) its normalised name
  contains a list keyword, (2) its price is at most the budget cap,
  (3) its normalised ingredients do not contain the ban keyword (or
  the ban is 无）. There is no product database, no live price check,
  no barcode lookup: name, price and ingredients all come from the
  host LLM reading the photo, so a misread means a wrong judgement,
  and the UI footer, the README and every hint say so. Examples the
  harness pins: 纯牛奶 28 元（牛奶） passes under list 牛奶·面包·鸡蛋 /
  ≤50 元 / 花生； 面包 60 元 fails on budget alone; 花生酱 35 元 fails
  on list and ban together; a price exactly at the cap passes.
- **Non-passing products only ever touch a counter.** A filtered
  product increments the filtered count, is listed as 已过滤 with its
  failing reason, and produces no banner and no TTS. A filter that
  announced every non-pass would be the opposite of a filter. A
  failed photo, a failed LLM read, or a label line without a usable
  name and numeric price is NOT counted at all: the wearer did not
  actually see a product's name and price, so counting it would lie
  about coverage — and judging it against the budget would be
  invented.
- **The label line is the only input, and its format is strict.**
  The LLM is asked for exactly one line, `品名|价格|配料关键词`. The
  parser strips currency symbols and requires a numeric price; a line
  with fewer than three fields, an empty name, or a non-numeric price
  is a parse failure (not counted, retake), never a guessed product.
- **A photo is a deliberate tap, never an accidental nod.** A steady
  nod confirms only where confirmation is safe: START in idle,
  CONFIRM on the summary screen. In live shopping a steady nod is
  ignored on purpose — snapping a photo must be a deliberate tap. An
  unsteady nod never arms the 1.2 s lock (the F01 fix, kept).
- **Correction is cheap, destruction is confirmed.** DEL in live
  shopping only clears the pass banner — it never deletes the seen
  list or ends the shopping. Back from the summary returns to live
  shopping without deleting anything; the summary is rebuilt on END.
  Confirming the summary (Enter / steady nod) is the only wipe.
- **DEMO is staged and never overwrites a user shop.** DEMO walks
  five stages: shopping started (list 牛奶·面包·鸡蛋， budget ≤50 元，
  ban 花生） → filtered product 花生酱 35 元（不在清单内、含忌口，
  counted silently, no banner, no TTS) → pass product 纯牛奶 28 元
  （banner + one TTS) → filtered product 进口巧克力 120 元（不在清单内、
  超预算， counted silently) → summary (seen 3, pass 1, filtered 2).
  A sixth DEMO tap reports the demo complete. DEMO refuses outright
  if a user shopping is running. Every step is labelled DEMO; no
  real photo happens in DEMO (the preview host cannot provide a
  camera stream by design).
- **The shopping trip lives in session memory only — zero
  persistence, by design.** There is no storage API anywhere in the
  page (no wx storage import use, no localStorage; harness-scanned).
  Filter settings, seen list, banner and summary die when the summary
  is confirmed, when the agent closes (onUnload wipes everything),
  and never survive to the next trip. Close the agent and the filter
  is gone, which is the correct use for a trip happening right now.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). The only timers are the 1.2 s
  nod lock and the photo/LLM timeouts (9 s camera, 9 s photo,
  12 s convert, 30 s LLM read).

## Relation to the neighbours (kept distinct on purpose)

- Directional-series `allergen-guard` reads one item's ingredients and
  warns only when a banned ingredient hits — it is a **warning**.
  Buy-filter never warns about a single item in isolation: it tests
  every item against three pre-declared conditions and surfaces only
  the ones that pass all three.
- Directional-series `shelf-compare` compares items you have already
  picked up, one by one — it is a **comparison**. Buy-filter decides
  before you pick anything up, and its filtered items never surface
  at all.
- `sign-filter` (F02) is the visual twin of the same gate: a declared
  target interrupts, every other sign is counted. Buy-filter is the
  same gate with three conditions instead of one, applied to products
  instead of signs. The idle-only-settings discipline and the
  zero-persistence discipline are shared on purpose.
- `focus-shield` (F01) is a session gate for sound: whitelist words
  interrupt, everything else is logged. Buy-filter is its shopping
  twin for vision.

## Permissions

CAMERA only — `permissions` is exactly `["CAMERA"]` in app.json, and
the static check asserts exactly that. The telephoto photo
(ImageCapture `telephoto`, guarded try/catch so the preview host
fails soft) plus the host LLM image input is the only read path.
No `RECORD_AUDIO`: nothing is spoken into this agent (list, budget
and ban are picked from pools, confirmation is a gesture).
No `GEOLOCATION`: a supermarket trip needs no position, and this
agent never knows where you are — that ignorance is stated in the
README.

## Validation

- Node harness (see `/tmp/buy-filter-harness.js`, not packed):
  app.json permissions exactly ["CAMERA"]; zero storage/geo/audio
  APIs in the page source; no legacy Page/App/Widget; no utterance
  lang assignment; initial idle state (list 牛奶·面包·鸡蛋， budget
  50, ban 花生， seen list empty, idle big shows list); LIST/BUDGET/
  BAN cycles with wrap and idle-only refusals (mid-shop and on
  summary); START double-start refusal; label parse battery (plain,
  decimal, ¥-stripped, missing price, missing ingredients, empty,
  non-numeric); match rule battery (all-pass, budget-only failure,
  list+ban failure, price-at-cap pass, price-over-cap fail,
  list-miss, space normalisation, ban substring, ban 无 removing only
  the ban failure); _onProductRead paths (pass banner + exactly one
  TTS, filtered silent count, empty read ignored, idle read inert,
  DEL banner-only, END summary counts, back-to-shop rebuild,
  confirm clears); NEXT/PREV wrap and rowTap focus; DEMO five-stage
  arc and refusal on a user shop; nod discipline (unsteady ignored
  without arming the lock, steady nod starts in idle, ignored in
  shopping, confirms on summary, non-nod inert, 1.2 s lock);
  SPEAK lines per mode; photo path soft-fails without a camera (no
  entry counted, busy released); onUnload wipes seen list, banner,
  mode and demo flag; bigCls thresholds.
  Result: **148/148**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (filter 牛奶·面包·鸡蛋 / ≤50 元 / 花生）,
  shopping (DEMO stage 1), filtered silently (DEMO stage 2, 花生酱
  counted, no banner, no TTS), pass banner (DEMO stage 3, 纯牛奶
  28 元）, summary (DEMO stage 5, seen 3, pass 1, filtered 2).
  Hit coordinates probed per state (see `shot-buy-filter.js`,
  `probe-buy.js` in `~/workspace/preview-tools/`): DEMO is the row-1
  first button (x=88), but its y moves with the info-box height —
  the first coordinate set was wrong for stage 2 (y=187 hit LIST
  and produced a fake "pass" frame that was really stage 2 with a
  LIST-refusal event); the corrected sequence is 177 / 173 / 173 /
  187 / 187, and every PNG was re-verified by eye after the fix,
  per the recorded F01/H02 lesson that a single hash probe can hit
  the wrong button.
