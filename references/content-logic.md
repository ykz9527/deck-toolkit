# Content & Logic — how each slide earns its place

The mainline (`narrative-spine.md`) is the *order*. This file is the *content logic*: how to open, how to title a slide, how much to put on it, and how to present architecture / schema / trade-offs so a mixed audience actually follows. Distilled from proven technical-talk frameworks (SCQA, Assertion-Evidence, C4, system-design reasoning, RFC/ADR structure).

The one enemy behind every failure here: **the curse of knowledge** — you know the internals so well you overestimate what the audience can absorb. Every rule below is a defense against it.

**Apply these frameworks INVISIBLY.** SCQA, assertion-evidence, C4 are tools for shaping the *order and the titles* — not content to put on screen. Never build a slide that displays the scaffold: no page labeled "Situation / Complication / Question / Answer", no visible "assertion-evidence" structure, no C4-level captions as decoration. The audience should feel the logic flow and never be able to name the framework you used. A conspicuous framework reads as academic and was rejected in practice. Reorder slides to open SCQA-style; write titles as assertions — but leave the machinery off the page.

## Open with SCQA — conclusion and pain BEFORE detail

Structure the opening (and often each section) as **Situation → Complication → Question → Answer**, top-down:

- **Situation** — the shared, uncontested baseline the audience already accepts. ("Today, extracting the *why* behind a codebase means reading it by hand.")
- **Complication** — what breaks that baseline; the pain/pressure/risk. This creates the tension. ("That knowledge lives in people's heads and evaporates when they leave.")
- **Question** — the crisp problem it forces. ("How do you make a codebase remember its own design rationale?")
- **Answer** — the top-level conclusion **first**, then details later. Don't make them wait through architecture to learn what the thing does.

This is the antidote to "bio → history → background → … → finally the point". Hit the pain or the payoff in the first slide, not five slides in. (Delivery echo: cut self/company/history intro; the first 30 seconds decide whether they keep listening.)

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
- This is *why* the deck splits story (plain, sparse) from appendix (depth) — it keeps each story slide inside the budget.

## Architecture: layer it (C4), don't dump it

Never paste the full topology. Disclose in **audience-appropriate zoom levels** (Simon Brown's C4 — "architecture diagrams should work like Google Maps"):

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

## The checklist (run against every story slide)

- [ ] Title is a full sentence stating this slide's conclusion (not a topic word).
- [ ] The body is visual evidence for that title, not a bullet dump.
- [ ] One idea; ≤ ~7 elements; ≤ ~50 words of prose.
- [ ] Any architecture is at the right C4 zoom for this audience; every arrow/color means something.
- [ ] Any "why this design" slide shows the trade-off, not just the winner.
- [ ] Reading titles alone reconstructs the argument.
