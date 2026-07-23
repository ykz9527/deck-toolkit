# Content & Logic — how each slide earns its place

The mainline (your skill's own structure/spine reference — e.g. `narrative-spine.md` for a code repo, `paper-narrative.md` for a paper) is the *order*. This file is the *content logic*: how to open, how to title a slide, how much to put on it, and how to present architecture / schema / trade-offs so a mixed audience actually follows. Distilled from proven technical-talk frameworks (SCQA, Assertion-Evidence, C4, system-design reasoning, RFC/ADR structure).

The one enemy behind every failure here: **the curse of knowledge** — you know the internals so well you overestimate what the audience can absorb. Every rule below is a defense against it.

**Apply these frameworks INVISIBLY.** SCQA, assertion-evidence, C4 are tools for shaping the *order and the titles* — not content to put on screen. Never build a slide that displays the scaffold: no page labeled "Situation / Complication / Question / Answer", no visible "assertion-evidence" structure, no C4-level captions as decoration. The audience should feel the logic flow and never be able to name the framework you used. A conspicuous framework reads as academic and was rejected in practice. Write titles as assertions — but leave the machinery off the page. Whether you *reorder* slides to reach an SCQA-style opening depends on the source: see the next section.

## Lead with the conclusion — don't make the audience wait for the point

The principle is source-neutral: **open with the conclusion and the pain, before the detail.** How you get there differs by source — slide ORDER itself comes from your skill's own spine/structure reference, not from this file.

**When the order still needs to be created** — a code repo is a set of parallel modules with no inherent sequence of its own — derive the opening as **Situation → Complication → Question → Answer**, top-down:

- **Situation** — the shared, uncontested baseline the audience already accepts. ("Today, extracting the *why* behind a codebase means reading it by hand.")
- **Complication** — what breaks that baseline; the pain/pressure/risk. This creates the tension. ("That knowledge lives in people's heads and evaporates when they leave.")
- **Question** — the crisp problem it forces. ("How do you make a codebase remember its own design rationale?")
- **Answer** — the top-level conclusion **first**, then details later. Don't make them wait through architecture to learn what the thing does.

**When the source already carries its own order** — a research paper argues in a fixed sequence — that order governs: do not re-shuffle it to force an SCQA shape. You still open with the conclusion, but by *summarizing* it up front, not by re-sequencing the source.

Either way, this is the antidote to "bio → history → background → … → finally the point". Hit the pain or the payoff in the first slide, not five slides in. (Delivery echo: cut self/company/history intro; the first 30 seconds decide whether they keep listening.)

## Assertion-Evidence — the single highest-leverage slide rule

**Every slide title is a complete declarative sentence stating that slide's conclusion — not a topic noun.** The body is *visual evidence* for that assertion, not a bullet list.

- ❌ Title "系统架构" / "性能" / "Schema 设计" (topic labels — say nothing)
- ✅ Title "抽取全程绑定真实代码,结论可回溯到函数级" (a claim the slide then proves)
- Body = the diagram / animation / chart / code that *demonstrates* the title. Kill bullet-point walls. If a slide is a title + 6 bullets, it has no argument — rebuild it as assertion + one visual.
- Test: read only the titles top to bottom — they should form the argument of the whole deck by themselves.

(The cautionary tale: NASA's Columbia review slide buried the fatal risk under vague phrase-titles and bullet lists; nobody saw it. A sentence-title with one comparison chart would have screamed it.)

## Rule of One + Miller's 7±2 — ruthless per-slide budget

- **One idea per slide.** If you're saying "and also…", that's the next slide.
- **≤ ~7 visual elements** on any diagram/slide (boxes + lines + labels all count). Over that, the audience stops parsing.
- **Body prose ≤ ~50 words.** Anything more is speaker narration, not a slide. When it feels cramped, the fix is *less text*, never smaller text.
- **Every on-slide number needs provenance or a referent.** A figure that appears with no setup ("六种改动", "18 checks") gives the audience nothing to anchor it to. It's allowed only if it either (a) traces to real repo evidence — you counted it in the code/data before writing it, not estimated — or (b) has a same-slide referent it points back to ("the same checks as the previous page"). Neither? Cut it, or restate without the number. A wrong or unbacked count is caught instantly and it's the fastest way to lose the room.
- This is *why* the deck splits story (plain, sparse) from appendix (depth) — it keeps each story slide inside the budget.

## Complex structure: layer it, don't dump it

The general principle is source-neutral: **disclose a complex structure in audience-appropriate zoom levels, never all at once.** For a code repo, the model is Simon Brown's **C4** ("architecture diagrams should work like Google Maps"). For a paper, the analogue is its own method/framework figure: start at the overview, then reveal sub-mechanisms only where a point needs them, rather than showing the whole thing at once.

For a code repo: never paste the full topology. Disclose in these C4 zoom levels:

| Level | Shows | For | In the deck |
|---|---|---|---|
| **Context** | the system as ONE box + its users + external systems; **no tech-stack names** | execs / newcomers | the story-line architecture slide |
| **Containers** | deployable units (app, API, DB, queue) + protocols + tech choices | architects / devs | main appendix architecture figure |
| **Components** | modules inside one container | implementers | appendix, only if a point needs it |
| **Code** | class/field-level | the one engineer touching it | **avoid** — IDEs autogenerate it; it just overloads |

Pick the lowest level the *point* actually needs. Most story slides live at Context; most appendix figures at Containers.

**Diagram anti-patterns (reject these):**
- Arrows with undefined meaning → every arrow needs one clear semantic (data flow / call / event); if you can't name it, delete it. Keep direction consistent (e.g. requests always flow one way).
- Color as decoration → color must carry meaning (a zone, a status, a category) and nothing else.
- Component sprawl → if a box can't justify its presence in 30 seconds, merge it into a "…core services" group or cut it.

## Schema / data model: progressive, domain-split, conceptual-first

- **Never show the whole database.** Split by business domain (orders / users / inventory) into separate small diagrams; a shared entity repeating across them is fine.
- **Show conceptual/logical, hide physical** for a mixed audience — entities + relationships, not `VARCHAR`, indexes, FK constraints.
- Make relationships *readable as sentences*: crow's-foot cardinality + a verb on the edge ("a customer **places** many orders").

## Argue a design choice like a system-design review

When a slide has to justify *why this design* (a schema, a datastore, an architecture), use this reasoning order — it's far more convincing than asserting the winner:

1. **Scope & requirements** — put the non-functional constraints on the table first (scale, latency, consistency, security).
2. **Rough numbers** — a back-of-envelope estimate (QPS, data volume, growth) is the most persuasive and most-skipped move; real numbers become undeniable evidence.
3. **High-level design** — the macro data flow, agreed before detail.
4. **Deep dive + trade-offs** — and explicitly say **what you gave up and why**.

## Progressive reveal — teach a complex picture as a chain of micro-problems

Don't drop a finished mega-diagram at once. Start minimal, then **"introduce a challenge → add the component that solves it"**, step by step: show the naive design → "what happens at 10× load?" → reveal the scaling piece → "and if the primary dies?" → reveal failover. The audience re-lives the design's evolution instead of decoding a static result. This is exactly what the interactive animation (`deck-mechanics.md`) is for — challenge-driven staging, not a passive left-to-right pipeline.

## The cover copy — the hardest sentence, budget for iterations

The cover figure has an archetype menu (`visual-system.md` → The cover); the cover *copy* has none and is where the most rewrites happen. Anchor it with four questions, in this order:

- **Subject first, means second.** Lead with *what this project is / does*, not the clever mechanism behind it. "New AI-native way to…" buries the subject; "Build a new X — here's what changed" states it. If the first noun the reader meets is a technique, reorder.
- **Macro, not operational.** The cover states the *idea / positioning*; how it actually works unfolds on later slides. A cover that reads like step-1-of-a-tutorial is too low. ("具体怎么操作后面再展开.")
- **Tight, not colloquial.** Plain language is the goal, but the cover is still the most composed sentence in the deck — don't over-correct plainness into chattiness. Rigor and plainness are not opposites.
- **Say the one thing plainly.** If the human's actual job is "define a schema", the cover says *define a schema* — not a grand umbrella phrase for it.

Expect several passes here and don't treat that as failure; the cover earns disproportionate rewrites because it's the first read.

## Prose is part of the design — avoid "AI slop" in words, not just visuals

`visual-system.md`'s "no AI slop" is about the *look* (gradients, badges, emoji). Words have the same failure mode. → `references/copy.md`. In short: specific verbs over vague ones; cut em-dash pile-ups and rhetorical questions; no empty attitude words ("powerful", "seamless", "简单地"); turn stiff spec-speak ("经过分析判断后形成的认知知识") into plain human phrasing without sliding into chatty. Plain ≠ colloquial. (For a deep pass, the external `hallmark` skill is a good pairing.)

## The checklist (run against every story slide)

- [ ] Title is a full sentence stating this slide's conclusion (not a topic word).
- [ ] The body is visual evidence for that title, not a bullet dump.
- [ ] One idea; ≤ ~7 elements; ≤ ~50 words of prose.
- [ ] Every number on the slide traces to repo evidence or a same-slide referent — no bare, unbacked counts.
- [ ] Any factual claim (field name, ownership, behavior) is checked against the source, not plausibly invented.
- [ ] Any complex structure (a code repo's architecture, a paper's method figure) is disclosed at the right zoom level for this audience; every arrow/color means something.
- [ ] Any "why this design" slide shows the trade-off, not just the winner.
- [ ] Reading titles alone reconstructs the argument.
