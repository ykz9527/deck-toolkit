# Edit Loop — from a pasted reference block to a verified page

The user is looking at the deck live (`scripts/serve.sh`, picker + hot-reload injected in transit — see `shared/references/deck-mechanics.md` → "Output location & preview" for the general serving model). They click an element, the picker copies a reference block, they paste it here with an instruction after `✏️`. Your job is to turn that block into a small, verified, on-disk edit — nothing more.

`scripts/verify.sh` and `scripts/serve.sh` live under the skill's own `scripts/` directory (installed skills get `shared/scripts/` merged in flat, so `deck-editing/scripts/verify.sh` exists once installed — same file as `showcase-deck/scripts/verify.sh`). All commands below assume you're running from the project root, with the deck at its conventional path `showcase_deck/index.html` (the paper-deck flavour's conventional path is `paper_deck/index.html`); substitute the real path if this project's deck lives elsewhere.

## 1. Region-level loop (the normal case — a reference block with a `🔑 data-ref`)

This is the path for almost every paste, because `verify.sh` fails the build if any slide or interaction root lacks a `data-ref` — so a deck that already passes verification has one on everything that matters.

1. **Read the block.** Pull the `data-ref` value out of the 🔑 line (e.g. `s3-source-of-truth`). Note the 📍 slide number/nav word too — you'll want it if the grep needs a fallback.
2. **Locate it uniquely.**
   ```
   grep -n 'data-ref="s3-source-of-truth"' showcase_deck/index.html
   ```
   This must return **exactly one line**. If it does, that's your edit target — no need to re-derive structure, the id already points at it.
3. **If it returns 0 or >1 lines, fall back** (see §2's locating step) — don't guess which occurrence the user meant. A `data-ref` should be unique by construction, so a miss here usually means the deck changed since the picker block was copied (stale paste) or the id collided; re-locate from the 📄 snippet's text and fix the collision while you're there.
4. **Back up before touching the file:**
   ```
   cp showcase_deck/index.html showcase_deck/index.html.bak
   ```
   Every edit gets a fresh backup immediately before it — don't reuse a stale one from an earlier edit in the same session.
5. **Make the edit with the Edit tool, anchored on the matched line.** Use enough surrounding context in `old_string` to make the match unique (the `data-ref` attribute itself is usually enough context on its own). Change only what the `✏️` instruction asked for — resist fixing unrelated things you notice in the same snippet; that's a separate paste, a separate diff, a separate verify.
6. **Verify:**
   ```
   bash <skill>/scripts/verify.sh showcase_deck/index.html
   ```
   where `<skill>` is the installed skill dir that built this deck (`showcase-deck` or `paper-deck` — `scripts/verify.sh` is the same file in either, merged in flat by `install.sh`). Always run it against the real target path, never skip it because "it's a small change". Read the output, not just the exit code — a small edit can still trip a structural check (unbalanced tag, a duplicate id introduced by copy-paste, a `PLACEHOLDER-REDRAW` marker you forgot to delete).
7. **On FAIL, roll back, don't patch forward:**
   ```
   cp showcase_deck/index.html.bak showcase_deck/index.html
   ```
   then re-diagnose and redo the edit from the backup, rather than layering a second Edit on top of a broken file. A half-fixed FAIL left on disk is worse than no edit at all — the user is looking at this page right now.
8. **On PASS, stop — don't restart `serve.sh`.** The server is already polling the file's mtime and reloading the browser on change (see `serve.sh`'s injected hot-reload). Restarting it kills the user's current session for no benefit and can drop them off whatever scroll position they were at. The file write is the whole deliverable; the browser catches up on its own within ~1s.

## 2. No-`data-ref` fallback (the block carries a `⚠️`)

The picker marks this explicitly: `⚠️ 该元素无 data-ref;靠页码+片段定位,Claude 请顺手补一个 data-ref`. This happens for elements inside a slide that aren't a slide section, an interaction root, a title, or a figure — the four things `deck-mechanics.md`'s data-ref convention mandates (see `shared/references/deck-mechanics.md` → "data-ref anchors"). Treat it as a two-part job: locate today, then leave the deck better anchored for next time.

1. **Locate by unique text, not by `data-ref`.** Take the most distinctive fragment from the block's 📄 snippet — a literal string that's unlikely to repeat elsewhere in the file (a heading phrase, a labeled value, a class name combo) — and grep for it:
   ```
   grep -n 'left-and-right comparison' showcase_deck/index.html
   ```
   Cross-check against the 📍 slide number: if the grep hits multiple lines, the slide number narrows it to the one inside that section.
2. **Make the edit** the same way as the region-level loop (backup → Edit → verify → rollback-on-FAIL).
3. **Stamp a `data-ref` on the element while you're there.** Follow the convention in `shared/references/deck-mechanics.md` exactly — don't invent your own shape:
   - a slide section → `data-ref="sN"`
   - the slide's title → `data-ref="sN-title"`
   - an interaction root (`[data-anim]`/`[data-cmp]`/`[data-interaction]`) → `data-ref="sN-{slug}"`
   - an `.apx-fig` figure → `data-ref="sN-fig"`
   - anything else worth being individually addressable but not covered above → `data-ref="sN-slug"`, a short kebab name for what it *is* (not a restatement of its position)

   `N` is that element's current slide's 1-based order — read it off the enclosing `<section class="slide" data-ref="sN">`, don't recount from scratch. `data-ref` is additive: add the attribute alongside whatever the element already carries (`class`, `data-edit`, `data-editlist`, …), never replace an existing attribute with it.
4. **Verify** as usual — `verify.sh` checks that every slide and every interaction root has a `data-ref`, so if you stamped one of those two kinds it will get checked; a stamped mid-slide element (case 4 above) isn't independently checked, but the next picker click on it will now resolve to case §1 instead of a `⚠️` fallback.

## 3. Structural edits (reorder / add / remove slides, change the mainline)

Structural edits touch page identity, so they carry a renumbering obligation the region-level loop doesn't.

- **Changing the mainline (nav words / section grouping)** is a one-place edit: the `MAINLINE` array in the deck's inline `<script>` (see `deck-mechanics.md` → "The mainline" via `narrative-spine.md`). Editing the array itself doesn't touch any `data-ref` — but if you're also reassigning which slide belongs to which section, update that slide's `data-sec` attribute (a *different* attribute from `data-ref`; don't conflate the two). `data-sec` picks the nav section; `data-ref` is the picker's location id — a slide keeps `data-ref="s6"` regardless of which `data-sec` it's filed under.
- **Adding a slide:** duplicate the nearest slide of the right type (`deck-mechanics.md` → "Slide anatomy" lists the worked examples — cover, concept, demo, value, compare, status, appendix-divider/figure/cards), insert it in mainline order, and give it a `data-ref` that continues the sequence at the position it lands — then renumber everything after it (next step).
- **Removing a slide:** delete the `<section>`, then renumber everything after the gap.
- **Reordering slides:** move the `<section>` blocks, then renumber the whole deck top-to-bottom — don't try to patch just the moved ones, because a reorder changes every slide's position, not only the one that moved.
- **Renumbering, mechanically:** walk the file top-to-bottom in document order and rewrite each slide's `sN`, `sN-title`, `sN-{slug}`, `sN-fig` to match its *new* position. This is exactly the kind of bulk edit `deck-mechanics.md` warns about ("do not assemble large HTML by Python string-splicing… back up first") — for a small deck (a handful of slides) do it as individual Edit calls per `data-ref`, which is safer than a single regex pass that might touch an unrelated `s1` substring inside a longer id.
- **Sanity-check the renumber** before verifying the rest:
  ```
  grep -n 'data-ref="s' showcase_deck/index.html
  ```
  Read down the list and confirm the slide-level ids (`s1`, `s2`, `s3`, …) are contiguous, in document order, with no gap and no repeat — and that every child id (`sN-title`, `sN-{slug}`, `sN-fig`) carries the same `N` as the section it's actually inside. A child still tagged with its *old* slide number after a reorder is a silent bug: the picker will show it as belonging to the wrong page next time someone clicks it.
- **Then run the full `verify.sh`** — it independently confirms every slide section and every interaction root still has a `data-ref` at all (it doesn't check numeric contiguity, that's what the grep sanity-check above is for) plus the usual structural/single-file/floor checks a bulk edit is most likely to break (duplicate ids, unbalanced tags).
- **Backup discipline is the same, just earlier:** `cp` before you start moving sections around, not after — a structural edit is exactly the kind of change you want to be able to fully undo in one command if the renumber goes wrong halfway through.

## 4. Multi-select / cross-page reference blocks

The picker lets the user shift-click multiple elements before it copies; a single paste can then contain several blocks back to back, one per selected element, possibly spanning different slides. `serve.sh`'s hot-reload and the verify gate don't know about "batches" — treat each block as its own unit of work:

- **Process blocks in the order pasted**, one full region-level loop (§1, or §2 if it carries `⚠️`) per block: locate → backup → edit → verify → (rollback if FAIL) before moving to the next block.
- **Verify after each block individually**, not once at the end. If block 3 of 5 fails, you want to know that immediately and roll back *just that edit* — batching all edits and verifying once means a failure can't be attributed to a specific change, and rollback would undo good edits along with the bad one.
- **A shared instruction (one `✏️` at the end) can still apply differently per block** — e.g. "make these consistent" might mean the same visual change applied to each block's own markup, not literally the same diff pasted N times. Read each block's own snippet before deciding what the shared instruction means for it.
- **Cross-page selections are fine as-is** — nothing about the loop assumes same-slide. Each block already carries its own slide number and its own `data-ref`, so locating each one is independent of the others; there's no cross-block coordination needed unless the edit is itself structural (see §3), in which case do the structural pass once, for the whole set, after you understand what all the selected elements are.
