# Narrative Spine — the mainline the audience can repeat

A project deck fails the moment the listener can't answer "what line is this taking me down?". Decide the mainline before building, and make it visible through the nav.

## Pick one through-line

Choose a spine that fits the project and audience. Proven options:

| Spine | When it fits |
|-------|--------------|
| `问题 → 是什么 → 看它用 → 为何好 → 现状 → 细节` | pain is relatable; show-then-tell; the default for most tools |
| `是什么 → 为何好 → 怎么工作 → 现状` | leadership wants the value case before the demo |
| `用它 / 扩它`(two user journeys) | product has a clear "use it" and "extend it" split |

The test: can a listener repeat the spine back after one pass? If not, simplify it.

**Open with SCQA.** Whatever spine you pick, shape the *opening* as Situation → Complication → Question → Answer: establish the shared baseline, show what breaks it (the pain), frame the question, then give the top-level answer **up front** — don't make the audience wait through architecture to learn what the thing does. Hit the point in the first slide, not five in. (Per-slide content logic — assertion-evidence titles, Rule of One, C4 layering — lives in `content-logic.md`.)

**Show, then name.** Put a concrete demo/animation *before* abstract vocabulary — people believe what they see run, then accept the words for it. (In practice: the signature-workflow animation often comes early, right after the hook.)

## Signpost through the NAV — nothing else

The single strongest, lowest-clutter signpost is the **top nav**: make its words read as the mainline, and highlight the current section on every slide.

- Nav words ARE the roadmap: e.g. `是什么 · 为何好 · 现状 · 技术细节` reads as "what → why good → where it's at → how it's done".
- Keep 4–6 sections, terse. Highlight the active one per slide with `class="active"`.
- Group slides under these sections; keep the order monotonic (never jump backward through the nav).

## The anti-clutter rule (learned the hard way)

**Do NOT insert transition sentences, "agenda" pages, or connective prose to "show the logic."** It reads as cheesy filler, clutters clean layouts, and was explicitly rejected in practice. A plain nav word that reads as a line beats any amount of "先别急着听价值——先看它跑一遍" text.

- No `→ 转场句` lines between sections.
- No standalone "roadmap/agenda" slide.
- If a section genuinely needs a one-line framing, fold it into that slide's existing lede — don't add a new element.

The mainline should be *felt* through order + nav highlight, not *narrated* through inserted text.

## Grouping value props

If there are 3–5 value slides, group them under 2–3 headlines (e.g. 可用性 / 质量) and carry the headline in each slide's small tag (the `benefit-num` label: "可用性 · 多域"). This turns a flat list into a remembered structure — without adding slides or prose.

## Story vs appendix split

- **Mainline slides:** plain language, for a mixed audience. No jargon dumps.
- **Technical appendix:** a clearly separated section (own nav word, e.g. 技术细节) for architecture, schemas, internals — for the people who want to go deep. Everything that would derail the plain-language story goes here.
