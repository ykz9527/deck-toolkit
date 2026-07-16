---
name: project-showcase-deck
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

1. **Soul before slides.** First fill out a Project Brief (positioning in one sentence, 2–4 differentiators, audience, and an honest status of what is *shipped* vs *in-progress* vs *planned*). **Read the repo's own documents first — spec/design docs, ADRs, `docs/`, design notes, wikis — then README, architecture, git history, and tests.** Spec and design docs usually carry the real *why* and the intended narrative better than the README or the code surface. Never invent. See `references/extract-the-soul.md`.
2. **One repeatable mainline.** Decide the through-line before building (e.g. `问题 → 是什么 → 看它用 → 为何好 → 现状 → 细节`). The audience must be able to repeat it. See `references/narrative-spine.md`.
3. **Signpost the mainline through the NAV, not through clutter.** The top-nav sections ARE the roadmap; highlight the current one per slide. Do NOT insert cheesy transition sentences or extra "agenda" pages — that was a real, rejected mistake. Plain nav words that read as a line beat any amount of connective prose.
4. **Radical honesty, graded.** Use three states — shipped / partial / planned — as visible tags. Every claim resolves to real repo evidence. Never fabricate metrics. Aspirational ≠ done, and say so.
5. **Story is plain; jargon lives in the appendix.** The mainline uses plain language for a mixed audience. Push architecture depth, schemas, internals into a clearly-separated technical appendix.
5b. **Use the project's OWN words — never invent vocabulary.** Every term on a slide must be one the repo actually uses (mined from its docs, comments, identifiers, config, UI strings). Copy real terms verbatim; when one is opaque to outsiders, keep it and add a plain-language gloss beside it — don't swap in a prettier synonym or coin a grand umbrella word the team never uses. Build the Brief's VOCABULARY allow-list first; if a word isn't traceable to the repo, cut it. See `references/extract-the-soul.md`.
6. **Show, then name.** Put a concrete demo/animation of the product *before* abstract vocabulary — people believe what they see run.
6b. **Assertion-Evidence titles + Rule of One.** Every slide title is a complete sentence stating that slide's conclusion (never a topic noun like "架构" / "性能"); the body is the *visual evidence* for it, not a bullet dump. One idea per slide, ≤ ~7 visual elements, ≤ ~50 words of prose. Reading the titles top-to-bottom should reconstruct the whole argument. Open with SCQA (pain/context → question → top-level answer) — hit the point in the first slide, not five slides in. See `references/content-logic.md`.
7. **No "AI slop" aesthetics.** No soft gradients, colorful badges, rounded-everything, emoji-as-icons. The template's editorial design system (near-black/warm-paper themes, earth-tone semantic accents, serif headings + mono labels) is the default — keep it coherent. See `references/visual-system.md`.

## Workflow

1. **Extract the soul → write the Project Brief.** `references/extract-the-soul.md`. Start with the repo's own docs (spec/design docs, ADRs, `docs/`) — they are the highest-signal source for narrative and intent — then code, architecture, git history, tests. Do not proceed until positioning, differentiators, audience, and graded status are concrete and evidenced.
2. **Design the mainline.** Pick the through-line and the nav sections (these become the signpost), and shape the opening as SCQA (pain/context → question → top-level answer up front). `references/narrative-spine.md` + `references/content-logic.md`.
3. **Copy the template, fill it — one assertion per slide.** Start from `assets/deck-template.html` (CSS design system, scroll-snap slides, dark/warm toggle, edit mode, nav, one worked example of every slide type + the animation scaffold). Replace content; set nav words to the mainline. Write each slide title as a full-sentence conclusion with one visual as its evidence (not topic-noun + bullets); keep one idea, ≤~7 elements, ≤~50 words per slide. `references/deck-mechanics.md` + `references/content-logic.md`.
4. **Build 2–3 interactive moments — each arguing one design principle.** Don't ship a single token demo. Walk the mainline and pick 2–3 slides where *seeing it move* teaches something static can't (the signature workflow; the mechanism behind a "why it's better" claim; a before/after toggle; a concept that only makes sense in motion). For each, name the design principle it argues, then mimic the *real* screen/flow/mechanism as a click-through (hand-authored inline SVG) — and pick the interaction FORM that fits the idea (staged reveal / toggle / ripple-on-click / source→derived build / guard-catches-bad-input / chat panel), not a reflex left-to-right pipeline. Fidelity to the real mechanism is the richness that matters. The template ships the scaffold + a worked example; `references/deck-mechanics.md` → Animations has the which/what/how + the form menu.
5. **Static diagrams via the drawio skill.** For architecture / schema / flow diagrams, generate with the **drawio skill**, style to the deck palette, inline the SVG. Do not hand-draw static diagrams. (Interactive animations are the exception — those are hand-SVG.)
6. **Self-check, then serve.** Run `scripts/verify.sh` (single-file integrity: balanced tags, no external URLs, both themes wired). Serve with `scripts/serve.sh` on `0.0.0.0` and give the user the URL. Iterate on the rendered result, not on descriptions.

## Quick reference

| Need | Go to |
|------|-------|
| What to mine from the repo + honesty rules + vocabulary fidelity | `references/extract-the-soul.md` |
| Choosing the mainline + nav signposting | `references/narrative-spine.md` |
| Per-slide content logic (SCQA, assertion-evidence, Rule of One, C4, trade-offs) | `references/content-logic.md` |
| Design language, anti-AI-slop, palette/fonts | `references/visual-system.md` |
| Single-file structure, slide components, themes, edit mode, animations | `references/deck-mechanics.md` |
| Proven skeleton to copy | `assets/deck-template.html` |
| Static diagrams | **drawio skill** (cross-reference) |
| Integrity check / local server | `scripts/verify.sh`, `scripts/serve.sh` |

## Reliability rules (hard-won)

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
- Hand-drawing a static architecture diagram → use the drawio skill.
- **A generic, decorative hero on the cover** → the anti-pattern is a *templated* hero that looks identical for every project (random floating rotated cards as decoration). It is NOT an anti-pattern to mirror the project's OWN real product UI — if the actual product home shows floating knowledge cards, a cover echoing that is authentic and distinctive, keep it. The test: does the hero say something true and specific about THIS project, or is it filler? Filler → replace (type-led, one real artifact, a true metric strip, a quiet diagram).
- **A single token demo, or a generic input→process→output animation** → budget 2–3 interactions, each mimicking a real mechanism and arguing a design principle. See `deck-mechanics.md` → Animations.
- **Body text too small to read from the back of a room** → the template's base is 17px; don't shrink body copy below ~14px. Labels/mono tags may stay small; readable prose must not.
- **Invented / prettier-synonym / grand-umbrella vocabulary** → use the repo's own words, mined from docs/comments/identifiers; if a word isn't traceable to the repo, cut it. Gloss opaque real terms, don't replace them.
