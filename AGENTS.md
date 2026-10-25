# Voice List — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series HO03 (HOLD 默念型）: a say-it-once shopping/bring list for the
rapid-fire five things family fires at you on your way out — half of
which are gone from your head by the door.

## Design contract

- **The mic hears YOU, never the family member.** The list is dictated
  by the wearer in their own voice: they said it once, you repeat it
  once, the glasses hold it from there. The agent never claims to
  listen to, record or transcribe another person; the UI line, the
  EVT wording and the README all say the item comes from YOUR
  repetition.
- **Nothing joins the list unconfirmed.** Every heard item lands on a
  CONFIRM chip (labelled as an ASR hearing that may be wrong); only
  OK/Enter adds it. Re-dictating replaces the pending item (it was
  never added), DEL drops it, a steady nod in confirm mode is
  deliberately ignored — a nod never adds. Items are capped at 8; the
  9th add is refused out loud with the pending item kept, never a
  silent drop or overwrite.
- **Parsing stays close to the wearer's words.** Only bare shopping
  lead-ins （买/要买/我要买/带/拿/别忘了…） at the very start and
  trailing punctuation are stripped — "买一瓶洗手液" keeps its
  quantity wording rather than being "cleaned up" into something the
  wearer never said. Over-30-character hearings are truncated to 30
  with the cut stated on the EVT line. Empty-after-stripping is
  rejected as not heard; nothing is ever guessed.
- **Preset chips share the confirm step.** PRESET cycles 牛奶 / 鸡蛋 /
  钥匙 onto the same confirm chip (tap again for the next preset,
  OK adds). Quick-add exists for moments when speaking is awkward —
  it is not a bypass of the confirm discipline.
- **Display truncation is honest.** An item longer than 12 characters
  displays as its first 12 + "…"; the full text stays in storage and
  is what SPEAK reads. The truncation is labelled on the confirm
  chip and on the focused row.
- **The list persists as TEXT — that is its job.** `{text, done}`
  entries in wx key `voiceList`, max 8, saved on every mutation, so
  the list survives closing the agent: dictate at home, shop later.
  Plain text in this app's local storage on the glasses; no audio is
  ever stored. Persistence is stated plainly in the UI and README.
- **Nod = check, the core HOLD gesture.** In the shop, a steady nod
  checks the FOCUSED item — one nod, one check, spoken as it lands
  ("牛奶，勾了 3/5"). An unsteady nod earns nothing. A nod never
  unchecks (unchecking is a deliberate Enter toggle on a done item),
  never adds a pending item, never deletes. Focus moves with
  swipes / +1 / −1 and starts on the first unchecked item.
- **Progress tells you what is still missing.** The count line reads
  "3/5 已勾 · 还差：鸡蛋、钥匙"; SPEAK reads the remaining items
  only — full text, never the checked ones.
- **Last-item spotlight.** When exactly one item remains unchecked it
  is promoted HUGE and spoken once ("就剩最后一项：X") — the
  doorway reminder. The spotlight re-arms whenever the remaining
  count leaves 1, so an item checked then unchecked back to
  last-one is announced again, honestly. All-done is spoken once per
  arrival ("全买齐了") with the same re-arm rule.
- **Delete and clear are two-step.** DEL arms on the focused item,
  second DEL deletes; CLEAR arms, second CLEAR empties the list
  (spoken once). Any other action, or 6 s, disarms both.
- **DICT order is binding** (audit wording): wearer-mode
  `getUserMedia` availability check FIRST (settings read back,
  tracks stopped at once, result on its own "MIC CHECK:" line; an
  OverconstrainedError falls back to a labelled default-mic check),
  THEN host `SpeechRecognition` (zh-CN) on its own microphone,
  listening labelled "(host ASR)". Mic modes apply only to
  getUserMedia streams and never shape host ASR.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data.
- DEMO seeds a 5-item list with 3 checked （牛奶/鸡蛋/钥匙/洗手液/苹果，
  focus on 鸡蛋） in memory only; further DEMO taps walk the scripted
  ending (check 鸡蛋 → last-item spotlight on 苹果 → check 苹果 →
  all done), and the next tap restores the real list exactly. Demo
  saves are suppressed (`_saveItems` is a no-op in demo).

## Permissions

`RECORD_AUDIO` only — the wearer-mode mic availability check plus
the wearer's own dictation of list items. No camera (a spoken list
needs no photo), no geolocation.

## Validation

- Node harness (90 assertions): dictation confirm flow (unconfirmed
  item never in the list, zero storage writes before OK), re-DICT
  replacing the pending item, parse battery (lead-in stripping,
  verbatim phrases, garbage rejection), preset chip cycling through
  the same confirm step, cap-8 refusal with pending kept, entry
  shape exactly {text, done}, persistence roundtrip across a
  simulated reopen including done states and focus placement, nod
  discipline (unsteady earns nothing, steady nod checks exactly the
  focused item once and speaks it, nod never unchecks / never adds),
  Enter toggle both ways, focus wrap, progress math and missing-item
  naming, last-item spotlight spoken once + re-arm, all-done spoken
  once per arrival, two-step delete and two-step clear with disarm
  on other actions, SPEAK reading remaining items only, display
  truncation with full text kept and spoken, a keys + nod only
  shopping walkthrough, DEMO arc with real storage byte-identical
  throughout, mic-check-before-ASR ordering with check tracks
  stopped first, labelled OverconstrainedError fallback, and TTS
  lang never set on any utterance.
- Preview screenshots in `artifacts/` (index / demo list / last-item
  spotlight / all done), generated with the local Ink runtime
  pipeline; button hit coordinates probed per layout state.
