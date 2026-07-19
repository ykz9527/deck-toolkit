# Narrative Spine — the mainline the audience can repeat

A project deck fails the moment the listener can't answer "what line is this taking me down?". Decide the mainline before building, and make it visible through the nav.

## Derive the through-line — don't pick one off a shelf

**The mainline is an output, not a menu choice.** Before any HTML, ask SCQA of *this* repo and let the answers set the sections:

- **Situation** — the baseline this audience already accepts, uncontested. ("Extracting the *why* behind a codebase means reading it by hand today.")
- **Complication** — what breaks that baseline: the pain, the pressure, the risk. This is where the tension comes from. ("That knowledge lives in people's heads and evaporates when they leave.")
- **Question** — the crisp problem the complication forces. ("How does a codebase remember its own design rationale?")
- **Answer** — the top-level conclusion, stated **up front**, details after. ("It extracts them into a graph bound to real code.")

That's top-down on purpose: it forces the conclusion out before the internals, which is the whole reason the audience keeps listening. The spine is then the shortest path that walks S→C→Q→A and then earns it — typically `pain → what → see it → why → status → detail`, but **the project decides**, not the template.

Then compress the spine into **4–6 terse nav words that read as a line**. Those words are the deck's only signpost, and they live in ONE place — the `MAINLINE` array at the top of the template's script. Change them there and every slide follows; each slide declares its section with `data-sec` and the active word lights up on its own. There is no reason to keep the template's `是什么 · 为何好 · 现状 · 技术细节` — that is one project's answer, shipped as an example.

**The test:** can a listener repeat the spine back after one pass? If not, simplify it.

Worked examples of what a derivation *produces* (recognise the shape, don't shop from it):

| Spine it produced | The situation that produced it |
|-------|--------------|
| `问题 → 是什么 → 看它用 → 为何好 → 现状 → 细节` | pain is relatable and the complication does the selling; show-then-tell |
| `是什么 → 为何好 → 怎么工作 → 现状` | leadership already feels the pain — the answer is the hook, so lead with it |
| `用它 / 扩它`(two user journeys) | the complication differs by audience: users hit one wall, extenders another |

If none of the three fits, that is expected and fine — write the one your SCQA actually produced.

(Per-slide content logic — assertion-evidence titles, Rule of One, C4 layering — lives in `content-logic.md`.)

**Show, then name.** Put a concrete demo/animation *before* abstract vocabulary — people believe what they see run, then accept the words for it. (In practice: the signature-workflow animation often comes early, right after the hook.)

## Signpost through the NAV — nothing else

The single strongest, lowest-clutter signpost is the **top nav**: make its words read as the mainline, and highlight the current section on every slide.

- Nav words ARE the roadmap: e.g. `是什么 · 为何好 · 现状 · 技术细节` reads as "what → why good → where it's at → how it's done".
- Keep 4–6 sections, terse. Define them once in the template's `MAINLINE` array; each slide names its section via `data-sec` and the highlight is automatic — never hand-maintain `class="active"` across slides.
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
