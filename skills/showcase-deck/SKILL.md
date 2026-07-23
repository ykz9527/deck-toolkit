---
name: showcase-deck
description: Use when someone wants to introduce, pitch, or explain a code project/repository to an audience (leadership, newcomers, stakeholders) as a polished single-file HTML slide deck or scrollable presentation — not a README, not docs, but a narrated showcase they can present or share.
---

# Project Showcase Deck

## Overview

Turn a code repository into a single-file, self-contained HTML slide deck that introduces the project to a human audience (leadership + newcomers).

**Core principle — where quality actually comes from:** a great project deck is NOT about visuals. It is about (1) extracting the project's *soul* (real positioning, differentiation, honest status), (2) a *logical mainline* the audience can repeat back, and (3) *honesty* (every claim traceable to the repo). The visual form is solved once by the shipped template — do not re-derive it. Almost every bad deck fails on soul / mainline / honesty, never on CSS.

**You are not writing a README as slides.** You are narrating a story.

## When to use

- "介绍这个项目 / 做个项目介绍 / showcase this repo / pitch deck for this codebase"
- Onboarding newcomers to a codebase; explaining a system to leadership; a demo/overview deck.
- Any time the deliverable is *a presentation of a project*, single-file and shareable.

**Not for:** API docs, tutorials, READMEs, or one-off diagrams (use the drawio skill for a lone diagram).

## The non-negotiables (the DNA — read these before touching HTML)

1. **Soul before slides.** First fill out a Project Brief (positioning in one sentence, 2–4 differentiators, audience, graded status). **Read the repo's own documents first — spec/design docs, ADRs, `docs/`, wikis — then README, architecture, git history, tests.** Specs carry the real *why* better than the README or the code surface. Never invent. → `references/extract-the-soul.md`
2. **Use the project's OWN words.** Every term on a slide must be one the repo actually uses (mined from docs, comments, identifiers, config, UI strings), copied verbatim. Gloss an opaque real term; never swap in a prettier synonym or coin a grand umbrella word the team never uses. Build the Brief's VOCABULARY allow-list first; if a word isn't traceable to the repo, cut it. → `references/extract-the-soul.md`
3. **Derive one repeatable mainline — never inherit the template's.** Ask SCQA of *this* repo (Situation → Complication → Question → Answer, conclusion up front) and let the answer set the sections; the spine is an output, not a menu choice. The audience must be able to repeat it back. It lives in ONE place — the `MAINLINE` array in the template — so changing it is a one-line edit, not an excuse. The shipped `是什么 · 为何好 · 现状 · 技术细节` is one project's answer, not a format. → `references/narrative-spine.md`
4. **Signpost the mainline through the NAV, not through clutter.** The top-nav sections ARE the roadmap; highlight the current one per slide. Do NOT insert transition sentences or "agenda" pages — a real, rejected mistake. Plain nav words that read as a line beat any amount of connective prose.
5. **Assertion-Evidence titles + Rule of One.** Every slide title is a complete sentence stating that slide's conclusion (never a topic noun like "架构" / "性能"); the body is the *visual evidence* for it, not a bullet dump. One idea per slide, ≤ ~7 visual elements, ≤ ~50 words. Reading the titles top-to-bottom should reconstruct the argument. Open SCQA-style — hit the point in the first slide, not five in. → `references/content-logic.md`
6. **Radical honesty, graded.** Three states — shipped / partial / planned — as visible tags. Every claim resolves to real repo evidence. Never fabricate metrics. Aspirational ≠ done, and say so.
7. **Story is plain; jargon lives in the appendix.** The mainline uses plain language for a mixed audience. Push architecture depth, schemas and internals into a clearly-separated technical appendix.
8. **Show, then name.** Put a concrete demo/animation of the product *before* abstract vocabulary — people believe what they see run, then accept the words for it.
9. **No "AI slop" aesthetics.** No soft gradients, colorful badges, rounded-everything, emoji-as-icons. The template's editorial design system (near-black/warm-paper themes, earth-tone semantic accents, serif headings + mono labels) is the default — keep it coherent. → `references/visual-system.md`

## The delivery floors (`scripts/verify.sh` fails the deck if you miss them)

These are not aspirations — they are checked, and the template already ships them wired. You do not have to *build* them; you have to make them **true about this project**.

- **The template ships holes, not designs.** The cover figure, both interaction stages and the architecture figure are placeholders carrying a `PLACEHOLDER-REDRAW` marker. Redraw each to this repo's real thing, then delete its marker. **Any marker left = FAIL** (so the template itself fails its own check, by design).
- **A cover figure.** One quiet, static portrait of THIS project — what it makes, its shape, or its real screen — derived from the Brief. Not decoration, not the appendix diagram. The test: swap in another project's name; if the figure still fits, it's filler.
- **≥ 2 interactions** (aim 3), each a *different* form. Two scaffolds ship — a staged reveal and a compare toggle — so the count is free. Redrawing them to the repo's real mechanisms is the work.
- **The architecture is illustrated.** drawio when its toolchain works, a hand-authored inline SVG when it doesn't. Skipping the diagram is the failure; hand-drawing it is the correct fallback.
- **One file.** No external requests *and* no sibling assets — a drawio export gets inlined, never `<img src>`d. The deck must survive being emailed alone.

**The floors never justify padding.** A hollow demo added to hit a count is worse than a strong static slide. If a second genuine interaction won't come, the fix is to *understand the repo better* — read the workflow code, the specs, the data model — not to fake one. Quality wins ties; the floor just refuses silence.

## Workflow

1. **Extract the soul → write the Project Brief.** `references/extract-the-soul.md`. Start with the repo's own docs (spec/design docs, ADRs, `docs/`) — they are the highest-signal source for narrative and intent — then code, architecture, git history, tests. Do not proceed until positioning, differentiators, audience, and graded status are concrete and evidenced.
2. **Derive the mainline.** Run SCQA on the Brief (Situation → Complication → Question → Answer) and let it produce the through-line; compress it into 4–6 nav words that read as a line. Set them in the template's `MAINLINE` array — one edit, whole deck follows. Keeping the shipped words is a decision you must be able to justify, not a default. `references/narrative-spine.md` + `references/content-logic.md`.
3. **Copy the template, fill it — one assertion per slide.** Copy `assets/deck-template.html` to **`showcase_deck/index.html` in the project root** (create the folder). The template has the CSS design system, scroll-snap slides, dark/warm toggle, edit mode, nav, one worked example of every slide type, the cover figure slot, the two interaction scaffolds and the appendix figure. Replace content; set nav words to the mainline. **Draw the cover figure** — one quiet static portrait of this project, derived from the Brief (`references/visual-system.md` → The cover has the archetype menu); the cover is the first read and the placeholder is a hole, not a design. Write each slide title as a full-sentence conclusion with one visual as its evidence (not topic-noun + bullets); keep one idea, ≤~7 elements, ≤~50 words per slide. **Keep every semantic unit `data-ref`-stamped** — the template ships them, and any slide/title/interaction/figure you add or duplicate needs one too (convention `sN` / `sN-title` / `sN-{slug}` / `sN-fig`, see `references/deck-mechanics.md` → data-ref anchors); this is what lets the user later point-and-edit. `verify.sh` fails if a slide or interaction root lacks one. `references/deck-mechanics.md` + `references/content-logic.md`.
4. **Make the interactions true (floor: 2, aim 3).** Two scaffolds ship wired; the work is choosing *which* moments and redrawing them to the real thing. Walk the mainline and pick the slides where *seeing it move* teaches something static can't. For each: name the design principle it argues in one sentence — if you can't, it's decoration, cut it — then mimic the *real* screen/flow/mechanism as a click-through in hand-authored inline SVG. **Vary the form** — two identical staged-reveals count as one idea. **`assets/interaction-patterns.html` is a working gallery**, organised by the **six machines** everything is built from, each keyed to the claims it can argue — **M1 step a sequence** (staged reveal · challenge→component · agent panel) · **M2 select one of N states** (compare toggle = lens switcher, same code) · **M3 click an element → its payload** (details-on-demand · code-anchored inspect · StretchText · C4 zoom) · **M4 continuous parameter** (dial · history scrubber) · **M5 traverse a graph** (ripple — the only one that computes) · **M6 commit then reveal** (predict-then-reveal, once per deck). Machines **compose** (the guard demo is M2+M1) — reach for that before inventing a seventh. Open it in a browser, copy the machine that fits, redraw it. It is a **palette, not a checklist** — the range exists so you can find the right one, not so you can use them all. Leaving a scaffold's generic placeholder shapes in place is not an interaction. `references/deck-mechanics.md` → Animations has the which/what/how + the full form table.
5. **Illustrate the architecture.** Probe the **drawio skill**'s toolchain first (CLI, or extracted AppImage + `xvfb`); if it works, author `.drawio` → export SVG in the deck palette → **inline the markup**. If it doesn't, hand-author the inline SVG instead — same discipline as the animations (palette tokens, ≤~7 elements, every arrow/color meaningful); the template's appendix figure is a worked example. Never skip it. `references/deck-mechanics.md` → Static diagrams.
6. **Self-check, then serve (always — don't just hand over a file).** Run `scripts/verify.sh` (no-arg defaults to `showcase_deck/index.html`): structure, single-file integrity, and the delivery floors above. Then **always launch the preview**: `scripts/serve.sh` (same default, binds `0.0.0.0`, run it in the background) and give the user the LAN URL. The deliverable is the verified rendered page — iterate on it (both themes), not on descriptions.
7. **Iterate with the user via the `deck-editing` skill.** Once served, the injected picker lets the user click any element and paste a reference block back into the chat; use the **`deck-editing`** skill to turn each into a surgical, verified edit. Don't rebuild from scratch for tweaks — point-and-edit the live deck.

## Quick reference

| Need | Go to |
|------|-------|
| What to mine from the repo + honesty rules + vocabulary fidelity | `references/extract-the-soul.md` |
| Choosing the mainline + nav signposting | `references/narrative-spine.md` |
| Per-slide content logic (SCQA, assertion-evidence, Rule of One, numeric provenance, cover copy, C4, trade-offs) | `references/content-logic.md` |
| Prose that isn't "AI slop" (word-level anti-slop checklist) | `references/copy.md` |
| Design language, anti-AI-slop visuals, one-shape-one-meaning, palette/fonts | `references/visual-system.md` |
| Single-file structure, slide components, themes, edit mode, animations | `references/deck-mechanics.md` |
| Proven skeleton to copy (2 interaction scaffolds + figure, all wired) | `assets/deck-template.html` |
| **Gallery of working interactions — 6 machines, many moves** — open in a browser, copy one in | `assets/interaction-patterns.html` |
| Static diagrams — preferred route | **drawio skill** (cross-reference); fallback = hand-authored inline SVG |
| Where to save + how to preview | build to `showcase_deck/index.html`; verify + serve via `scripts/verify.sh`, `scripts/serve.sh` |

## Reliability rules (hard-won)

- **Output location is fixed: `showcase_deck/index.html` in the project root.** Create the `showcase_deck/` folder. A `.drawio` source or a not-yet-inlined `.svg` may live there while you work, but `index.html` must not depend on them. If a deck already exists for this project, it lives here — find it before building anything new. After building, **always start the preview server and give the user a URL** — never end by just naming a file path.
- **If a deck already exists for this project, IMPROVE IT IN PLACE — do not rewrite from scratch.** A mature deck holds hard-won craft (a real cover, hand-built animations, tuned type) that a from-scratch rewrite silently throws away and regresses. First read the existing deck, treat it as the base, and make surgical edits (reorder, retitle, add one interaction) with a backup + verify each time. Rebuilding "cleaner" from the template is the single most damaging mistake — it looks like progress and is regression. Only start from the template when there is no existing deck.
- **Build the HTML with the Write tool and verify after every change** (`wc -c`, grep structure, serve → 200). Large-file Python splicing is unreliable and can be silently *replayed* — if you must script an edit, add an idempotency guard (grep a sentinel; no-op if present) and delete the script after.
- **Back up before any bulk/script edit** (`cp`), and diff the untouched regions afterward.
- **Verify on the real rendered page**, both themes — never trust that a color/theme change looks right without viewing it.

## Common mistakes (red flags — stop)

- Listing features instead of telling a story → you skipped the soul/mainline. Go back to step 1–2.
- **Rewriting a mature existing deck from the template** → regression disguised as progress. Improve the existing deck in place (see Reliability rules). Rewrite only when none exists.
- **Displaying the content-logic framework instead of applying it** → e.g. a slide literally labeled Situation/Complication/Question/Answer, or "assertion-evidence" scaffolding on show. The frameworks (SCQA, C4, etc.) shape the *order and titles* invisibly; the audience should feel the logic, never see the framework's name. If a viewer can tell which framework you used, you over-applied it.
- **Topic-noun slide titles + bullet walls** ("架构" / "性能" over 6 bullets) → rewrite as an assertion (full-sentence conclusion) + one visual. See `content-logic.md`.
- **Dumping a full architecture/DB diagram at once** → layer it (C4 zoom for the audience) or reveal it as challenge→component steps; split schemas by domain, conceptual not physical.
- Inserting transition sentences / agenda pages to "show the logic" → clutter. Signpost via nav only.
- Claiming things are done that are only planned → grade honestly (shipped/partial/planned).
- Front-loading vocabulary before any demo → show first, name second.
- Gradients, badges, emoji icons creeping in → return to the template's design system.
- **Shipping the template's placeholder shapes** (输入→处理→产出; 手工维护 vs 单一事实源; the empty cover figure) → that's zero of everything wearing the costume of a finished deck. Redraw each to the real thing. See `deck-mechanics.md` → Animations.
- **A cover with no figure, arrived at by default** → the first read is what makes it look like THIS project. Draw the portrait; type-led-only is a deliberate choice, not a skip.
- **Skipping the diagram because drawio wasn't installed** → hand-author the inline SVG; that's the fallback, not a mistake.
- **`<img src="fig.svg">` beside the deck** → inline the markup. One file, or it isn't the deliverable.
- **A generic, decorative hero on the cover** → the anti-pattern is a *templated* hero identical for every project, not a shape. Mirroring the project's OWN real product UI is authentic — keep it. The test: does the hero say something true and specific about THIS project, or is it filler?
- **Body text too small to read from the back of a room** → the template's base is 17px; don't shrink body copy below ~14px. Labels/mono tags may stay small; readable prose must not.
- **Invented / prettier-synonym / grand-umbrella vocabulary** → use the repo's own words, mined from docs/comments/identifiers; if a word isn't traceable to the repo, cut it. Gloss opaque real terms, don't replace them.
