# Extract the Soul → Project Brief

The deck is only as good as this step. Do it before any HTML. Output a **Project Brief** and confirm it with the user.

## Read order (highest signal first)

1. **Spec / design docs, ADRs, `docs/`, design notes, RFCs, wikis.** These carry the *why*, the intended narrative, and the roadmap — usually far better than the README. Read them first. Look under `docs/`, `spec/`, `design/`, `rfc/`, `adr/`, `*.md` at repo root, and any linked design tickets.
2. **README + top-level package metadata** — the official positioning line, the elevator pitch.
3. **Architecture** — top-level packages/modules, entry points, how pieces fit. Enough to tell the structure story, not every file.
4. **Git history** — recent commits, branch names, tags. Reveals what's *active* vs *stale*, what shipped recently, what's aspirational.
5. **Tests + CI** — what's actually verified = what's actually real. A capability with green tests is "shipped"; a design doc with no code is "planned".

If the user names specific docs ("看 spec 文档"), read those first and let them anchor the narrative.

## The Project Brief (fill every field, evidenced)

```
POSITIONING (1 sentence): the authoritative one-liner. Prefer the project's own
  words from spec/README. Do NOT invent a new pitch.
PLAIN-LANGUAGE VERSION (1 sentence): the same thing an outsider can understand.
DIFFERENTIATORS (2–4): what makes it not-just-another-X. Each must ladder to an
  outcome the audience cares about (e.g. "usability", "quality", "cost").
AUDIENCE: who is this deck for? (leadership / newcomers / both) — sets the register.
SIGNATURE WORKFLOW: the one flow that best shows what it does — candidate for the
  interactive demo. Name the real product screen/route it maps to.
VOCABULARY (the project's own terms): list the 5–12 real names this repo uses for
  its core nouns/steps/roles — copied verbatim from docs/comments/identifiers, each
  with a plain-language gloss. This list is the ONLY vocabulary the deck may use.
STATUS (graded, evidenced):
  shipped:   [capability] — evidence: [test/file/route]
  partial:   [capability] — evidence + what's missing
  planned:   [direction]  — evidence it's only a design doc / intent
SCOPE ANTI-GOALS: what this project is deliberately NOT (prevents overclaiming).
```

## Speak the project's own language (non-negotiable)

The deck must use the **repo's own words** for its concepts — never invented jargon, never a synonym you found prettier, never a term the codebase doesn't use. Made-up or "smart-sounding" vocabulary is the fastest way to lose an audience that knows the system, and to confuse one that doesn't.

- **Mine the real terms** from where the team actually named things: doc/spec headings, code comments, class/function/module names, config keys, UI strings, commit messages, the glossary if one exists. Prefer the term that appears *most consistently* across these.
- **Copy it verbatim.** If the repo says "operator", don't write "processor". If it says "concern", don't upgrade it to "aspect". Match casing/spelling the project uses (including its Chinese/English mix).
- **Gloss, don't replace.** When a real term is opaque to outsiders, keep the term and add a one-line plain-language explanation next to it (that's what the appendix and the `card em`/`h3` split are for) — don't swap in a word the team never uses.
- **Don't invent umbrella words.** If the project has no single name for a group of things, say so plainly; do not coin a grand term ("the X Engine", "the Y Fabric") to make it sound unified.
- **When unsure which term is canonical, ask** — or show the candidates and let the user pick. Never ship a guessed term as if it were the project's.

The VOCABULARY field in the Brief is the allow-list. If a word you're about to put on a slide isn't traceable to the repo, cut it or replace it with one that is.

## Honesty grading (non-negotiable)

Three states, always visible as tags on the slides:

| Tag | Means | Evidence bar |
|-----|-------|--------------|
| **已上线 / shipped** | works today | code + passing tests / a live route |
| **部分落地 / partial** | partly built | some code, gaps remain — say the gap |
| **方向 / planned** | intended, not built | a design doc / issue / stated intent only |

Rules:
- Never present planned as shipped. "Aspirational ≠ done."
- Never fabricate numbers (latency, %, counts). If you don't have a real figure, don't show one.
- Every claim on a slide should resolve to something you actually saw in the repo. If challenged "where's that from?", you must be able to point.
- A short honesty footnote on status/claim-heavy slides ("越往右越是方向而非已交付") buys credibility, especially with leadership.

## Common failures

- **Feature dump.** Listing modules ≠ a story. If the brief has no positioning/differentiators, you're not ready to build.
- **README-only reading.** The README is marketing; the spec/design docs are the truth of intent. Read the docs.
- **Believing the code is the product.** A prototype path in the repo is not "the product" unless it's wired in and tested. Grade it.
- **Inventing a pitch.** Use the project's own positioning. If it doesn't have one, draft one and get the user to confirm — don't ship your guess as fact.
