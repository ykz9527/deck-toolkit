# Deck Mechanics

How the single-file deck is built. Start from `assets/deck-template.html` — it already implements everything below. This is the reference for adapting it.

## Single-file, self-contained

- One `.html` file. **No external requests** — inline all CSS/JS; embed images as SVG markup or `data:` URIs. (Diagram SVGs may sit next to the file during authoring, but the shippable deliverable inlines them.)
- Full-viewport scroll-snap slides (`scroll-snap-type: y mandatory`, `.slide { min-height:100svh; scroll-snap-align:start }`), auto page numbers via CSS counters.
- Build with the **Write tool** and verify after every change (`scripts/verify.sh`). Do not assemble large HTML by Python string-splicing; if you must script an edit, add an idempotency guard and back up first.

## Slide anatomy

Every slide: `<section class="slide"> <nav>…</nav> <div class="frame"> …content… </div> </section>`.
The template includes one worked example of each type: **cover, concept/vocabulary, demo (animation), value, status/readiness, appendix-divider, appendix-figure, appendix-cards**. Duplicate and fill; delete what you don't need.

## Dark / warm theme (how it works)

- Neutral colors are tokens on `:root` (dark defaults). `:root[data-theme="warm"]` overrides them. Semantic accents are unchanged across themes.
- Toolbar ☀ button toggles `data-theme` on `<html>`, persisted to `localStorage`.
- **Animation slides carry `class="slide screen"`** — a block that re-pins the neutral tokens to dark, so the "product screen" stays dark in *both* themes (intentional; avoids theming complex hand-built SVG).
- To recolor for a project, edit only the accent tokens (see `visual-system.md`).

## Edit mode

Edit mode (✎) lets the presenter reword and restructure the deck in the browser, then ⭳ export a clean standalone HTML. Two lanes, both survive reload **and** export:

- **Text — `data-edit`.** Any element with a bare `data-edit` becomes click-to-edit. Stored in `localStorage` keyed by index (order is fixed). Put it on every text element the user might reword.
- **Repeatable content — `data-editlist="name"`.** Wrap a container of like items (the concept cards, each readiness column's `<ul>`, the appendix points, the animation step list) in `data-editlist`. In edit mode each such container grows a **"+ 添加"** button and each item a **"×"** delete. The whole region is persisted by name (its cleaned `innerHTML`), so adding / removing / editing items all stick. Give each list a unique name.

The +/× controls carry class `edit-ctl`, are injected only while editing, and are stripped before both save and export — never hand-author them. A `data-edit` element **inside** a `data-editlist` is persisted by the region, not by index (don't double-count it). Keep non-text/interactive containers out of editing (`contenteditable="false"` on the animation wrapper; the editable step rows inside re-enable themselves).

## Static diagrams (drawio skill)

For architecture / schema / flow diagrams:
1. Use the **drawio skill** to author a `.drawio` and export **SVG**, styled to the deck palette (dark fills, light text, earth-tone accent strokes, transparent background).
2. For theme support, produce a **warm variant** (swap dark fills→warm, light text→ink, neutral strokes→dark; keep colored accents) and export a second SVG.
3. Inline/reference both as a `.fig-dark` / `.fig-warm` pair inside `.apx-fig`; CSS swaps them by theme.
- If the environment lacks the drawio CLI, note the AppImage-extract + `xvfb` path (headless export needs a virtual display; pure-headless segfaults).

## Animations — interaction that argues the design idea

The most impactful (and hardest) piece. **Design it from your repo understanding, then hand-author inline SVG.** One generic "input → process → output" pipeline is a failure. The interaction exists to make the audience *feel* the project's core design idea — so first decide which idea, then which moments deserve interaction.

### Step 0 — decide WHICH slides get interaction (and how many)

Don't ship exactly one token demo. Budget **2–3 interactive moments** for a real deck, chosen deliberately. A slide earns interaction only when *seeing it move* teaches something a static picture can't. Walk the mainline and ask at each candidate: **which design principle does this project live or die on, and would an interaction let the audience feel it?**

Common earners (pick the ones true for THIS repo):

- **The signature workflow** — the one loop the product is *for*. Almost always worth it. Mimic the real screen as a staged click-through.
- **The "why it's better" mechanism** — if a value slide claims something structural (incremental vs full rebuild, graph-derived vs hardcoded, drift-guard catches X), *show the mechanism doing its thing* instead of asserting it. This is where interaction beats prose the most.
- **A before/after or two-journeys toggle** — if the pitch is "old way vs our way" or "use it / extend it", a toggle that flips the same stage between the two states lands harder than two static slides.
- **A concept that only makes sense in motion** — a dependency ripple, a schema edge binding an operator, a queue draining. If the vocabulary slide has a concept people keep misunderstanding, animate *that*.

Skip interaction on slides where a sentence or a static diagram is already the honest, complete story. Interaction on a slide that doesn't need it is clutter, not richness.

### Step 1 — decide WHAT each one animates (from the repo)

For each chosen moment, go to the specs/docs/code and pull the *real* thing: the real screen/route, its real steps, its real vocabulary, the real artifact a step produces. The animation must mimic *that*, faithfully. Name the design principle the animation is arguing, in one sentence, before drawing — if you can't, it's decoration, cut it.

### Step 2 — decide HOW (mimic the real UI as a click-through)

- Reproduce the real UI's layout and language: same panels, same step names, same shapes the product actually shows. Read the actual frontend/components if they exist, and match their visual grammar.
- **Staged reveal, click-driven** is the base grammar: a left **story column** narrates the current step; a right **stage** (inline SVG) advances as steps progress. Controls: ▶ play (auto-advance), › next (one discrete step), reset.
- **Discrete stepping is a real requirement:** "next" must advance exactly one step, not behave like play. Keep the play interval in a module-level variable and clear it (`anStop()`) at the top of next/reset/play — otherwise a lingering timer makes "next" auto-run. (The template's `anStop`/`anNext`/`anPlay` show the pattern.)
- **Step narration lives in the DOM, not a JS array.** The story column is an editable `<ol class="an-steps" data-editlist="anim-steps">` — one `<li>` (name + desc) per step, the active one lit. `anRender()` reads the steps from this list, so the presenter can edit/add/delete steps in edit mode and the walk-through updates live (and exports). Redraw the SVG to the real flow; node/edge reveal stays keyed on `data-s < current step`.

**Pick the interaction FORM that fits the idea — don't reflex to "reveal boxes left-to-right".** A menu, roughly by what the design idea is:

| The idea you're arguing | Interaction form that lands it |
|---|---|
| a pipeline/workflow has stages | staged reveal of nodes+edges (base grammar) — but redraw to the *real* steps |
| "our way vs the old way" | a **toggle/slider** that flips the same stage between two states in place |
| change here ripples to there | click a node → **highlight its downstream** lighting up along real edges |
| structure is derived, not hardcoded | show the **source artifact** (schema/spec/config) on the left, watch the derived thing **build itself** on the right |
| a guard/check catches something | run the happy path, then inject the bad input and watch the guard **flag it** (red state) |
| an AI/agent loop | a **chat/side panel** that "types" the real prompt→response steps next to the artifact it produces |
| a big graph/knowledge base | a small **pan/zoom/hover-tooltip** map with click-to-focus |
| a complex architecture that evolved for reasons | **challenge→component progressive reveal**: start naive, pose a problem ("what at 10× load?"), reveal the piece that solves it, repeat — the audience re-lives the design (see `content-logic.md`) |

Combine sparingly. The richness that matters is *fidelity to the real mechanism*, not the number of widgets — one interaction that faithfully shows the thing beats three generic ones. Keep every added control wired to `anStop()` discipline so stepping stays discrete.

### Step 3 — keep it honest and on a dark screen

- Put the animation slide on `.slide.screen` (stays dark in both themes).
- Only animate what's real. If a step is aspirational, either omit it or mark it. Don't imply a capability the product doesn't have.

### The scaffold

`assets/deck-template.html` ships a minimal working scaffold: the editable `.an-steps` list (name + desc per step) driving `.an-node[data-s]` / `.an-edge[data-s]` reveal, with play/next/reset wired correctly. Add/edit steps in the list and redraw the SVG to match the project's real flow. For a rich product UI, expect this to grow into a bespoke SVG scene — that's expected; the scaffold is the starting grammar, not the ceiling.

## Light dynamic touch — reveal-on-view (cheap, tasteful)

Beyond the 2–3 hand-built interactions, a *subtle* way to add life is to let a diagram's parts fade/rise in as its slide scrolls into view. Best spent on a diagram that **argues a value prop** — e.g. a "define once → derives everywhere" fan-out whose outputs appear one by one *shows* the claim instead of stating it.

- Add a `reveal` class to the container; its direct children start hidden and stagger in via `nth-child` `transition-delay`.
- **Gate the hidden state on `body.js`** (JS adds the class) so no-JS, print, and `prefers-reduced-motion` render everything visible — never hide content behind an effect.
- Drive it with one `IntersectionObserver` that toggles a `seen` class on entry (and off on exit, so it replays). Keep it restrained: no buttons, no bounce — just a quiet build-in that reinforces the slide's point.

## Output location & preview

Build the deck to **`showcase_deck/index.html` in the project root** (create the folder). Keep any drawio SVG figures beside it in the same folder — the deck references them by relative path (`fig-architecture.svg`, `fig-architecture-warm.svg`), and serving the folder resolves them. One project = one `showcase_deck/`; when improving an existing deck, it already lives here.

## Self-check, then serve (always)

Run `scripts/verify.sh showcase_deck/index.html`: balanced tags, no external URLs, both themes wired, `data-edit` present, animation controls present. Then **always** launch the preview — `scripts/serve.sh` (no-arg defaults to `showcase_deck/index.html`, binds `0.0.0.0`; run it in the background) — and give the user the LAN URL. Never finish by handing over a bare file path. Iterate on the rendered page (both themes), not on descriptions.
