# Deck Mechanics

How the single-file deck is built. Start from `assets/deck-template.html` — it already implements everything below. This is the reference for adapting it.

## The template ships holes, not designs

Four things in the template are **shapes standing in for work you haven't done yet**: the cover figure, the staged-reveal stage, the compare stage, and the architecture figure. Each carries a `PLACEHOLDER-REDRAW` marker in an HTML comment, and **`verify.sh` fails while any marker remains** — so the template itself does not pass its own check, by design. A deck does.

Delete a marker only once its shape is actually real for the source you're presenting — this repo's real mechanism, or this paper's real method. Deleting the marker without redrawing turns a silent default into a deliberate lie — the gate can force a conscious act, it can't force honesty.

## Single-file, self-contained

- One `.html` file, and it means one file: **no external requests AND no sibling assets.** Inline all CSS/JS; embed images as SVG markup or `data:` URIs. A drawio export is a *source*, not a deliverable — paste its markup into the html rather than `<img src="fig.svg">`. The deck must survive being emailed alone; `verify.sh` fails any `src=` that isn't a `data:` URI.
- Full-viewport scroll-snap slides (`scroll-snap-type: y mandatory`, `.slide { min-height:100svh; scroll-snap-align:start }`), auto page numbers via CSS counters.
- Build with the **Write tool** and verify after every change (`scripts/verify.sh`). Do not assemble large HTML by Python string-splicing; if you must script an edit, add an idempotency guard and back up first.

## Slide anatomy

Every slide: `<section class="slide"> <nav>…</nav> <div class="frame"> …content… </div> </section>`.
The template includes one worked example of each type: **cover (type + figure), concept/vocabulary, demo (staged-reveal animation), value, value-compare (toggle animation), status/readiness, appendix-divider, appendix-figure, appendix-cards**. Duplicate and fill; delete what you don't need — except the cover figure, the two interactions and the architecture figure, which are floors (see below).

## data-ref anchors (P1: picker / edit locating)

Every slide and every semantic unit inside it carries a stable `data-ref` id so a browser picker (and Claude, editing the deck later) can locate exactly the element to change without re-deriving structure from scratch. Naming, `N` = 1-based slide order:

- `<section class="…slide…">` → `data-ref="s{N}"`.
- The slide's title element (`h1`/`h2`, or whatever carries the assertion if there's no heading tag) → `data-ref="s{N}-title"`.
- Each interaction root (`[data-anim]` / `[data-cmp]`, or a bespoke `[data-interaction]`) → `data-ref="s{N}-{slug}"`, where `slug` is a short human kebab for that interaction's topic (e.g. `s3-flow`, `s5-compare`) — not a repeat of `N`.
- Each `.apx-fig` figure → `data-ref="s{N}-fig"`.

`data-ref` is additive only — it never replaces or displaces `class`, `data-sec`, `data-anim`, `data-cmp`, `data-edit`, etc.; it sits on the same opening tag as those. When you duplicate a slide or an interaction (see "MULTI-INSTANCE" comments throughout the template), give the copy a new `data-ref` too — duplicating the id is as broken as duplicating an `id` attribute. `verify.sh` fails the build if any slide section or interaction root lacks one.

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

## Static diagrams — required, drawio preferred, SVG fallback

A deck without an architecture picture is incomplete — `verify.sh` fails one. Every deck needs **at least a story-level architecture diagram and one appendix diagram**. (For a paper deck, the paper's **method/framework figure** plays this role — there is no software architecture to draw, and inventing one is not the fix.) Two ways to make them, in order of preference:

**Check availability FIRST.** The drawio skill needs the drawio CLI, or an extracted AppImage + `xvfb` (headless export needs a virtual display; pure-headless segfaults). Probe it before planning around it — and if it isn't there, don't burn the task installing it, take the fallback. *Silently skipping the diagram because drawio was missing is the single most common way this step fails.*

**Preferred — the drawio skill (when its toolchain works):**
1. Author a `.drawio` and export **SVG**, styled to the deck palette (dark fills, light text, earth-tone accent strokes, transparent background).
2. drawio bakes its colors, so for theme support produce a **warm variant** (dark fills→warm, light text→ink, neutral strokes→dark; keep colored accents) and export a second SVG.
3. **Inline both markups** into `.apx-fig`, tagged `.fig-dark` / `.fig-warm`; CSS swaps them by theme. Inline, not `<img src>` — the deck ships as one file.

**Fallback — hand-authored inline SVG (when drawio tooling is absent):** do NOT skip the diagram. Hand-write a clean `<svg>` in the palette tokens, exactly like the animation stages — `fill="var(--panel)"`, `stroke="var(--c5)"`, text in `var(--tx-hi)`, mono labels, ≤~7 elements, every arrow and color carrying one clear meaning. Put it in the `.apx-fig` slot. **A token-driven SVG themes for free** — one copy covers dark and warm, no pair needed. It won't be as polished as drawio, but a faithful hand-drawn diagram beats an unillustrated architecture every time. The template's appendix figure ships as a worked example: copy its shape, redraw it to the real architecture.

## Animations — interaction that argues the design idea

The most impactful (and hardest) piece. **Design it from your understanding of the source — the repo's real mechanisms, or the paper's real method — then hand-author inline SVG.** One generic "input → process → output" pipeline is a failure. The interaction exists to make the audience *feel* the source's core design idea — so first decide which idea, then which moments deserve interaction.

### Step 0 — decide WHICH slides get interaction (and how many)

The floor is **2 interactive moments, aim for 3**, and the template already ships two scaffolds in different forms — so the count is handled for you. Your job is not "how many" but **which moments, and is each one earned**. A slide earns interaction only when *seeing it move* teaches something a static picture can't. Walk the mainline and ask at each candidate: **which design principle does this project live or die on, and would an interaction let the audience feel it?**

Because two scaffolds ship pre-wired, the failure mode shifts: it is no longer "I only built one", it is **filling both with the template's generic shapes**. A staged reveal of 输入→处理→产出, or a toggle of 手工维护 vs 单一事实源, left roughly as shipped, is not two interactions — it's zero. Both must be redrawn to the source's real mechanisms — this repo's, or this paper's.

**The floor and the quality bar are both hard — and quality wins ties.** Never add an interaction just to reach the count; a hollow "for interaction's sake" demo is worse than a strong static slide. But "I only found one" is usually not a real ceiling — it's a signal you don't yet understand the source deeply enough. Go back and read more: for a code repo, the real workflow code, the specs, the data model, the module that implements the differentiator; for a paper, the method section, the experimental setup, the ablations. The material for a genuine second (and third) interaction almost always surfaces once you see the source clearly. Research harder before you settle for fewer.

Common earners (pick the ones true for THIS source):

- **The signature workflow (repo) / the method pipeline (paper)** — for a code repo, the one loop the product is *for*: mimic the real screen as a staged click-through. For a paper, its method pipeline, or a real worked example walked through the paper's own steps. Almost always worth it.
- **The "why it's better" mechanism** — if a value slide claims something structural (incremental vs full rebuild, graph-derived vs hardcoded, drift-guard catches X), *show the mechanism doing its thing* instead of asserting it. This is where interaction beats prose the most.
- **A before/after or two-journeys toggle** — if the pitch is "old way vs our way" or "use it / extend it", a toggle that flips the same stage between the two states lands harder than two static slides.
- **A concept that only makes sense in motion** — a dependency ripple, a schema edge binding an operator, a queue draining. If the vocabulary slide has a concept people keep misunderstanding, animate *that*.

Skip interaction on slides where a sentence or a static diagram is already the honest, complete story. Interaction on a slide that doesn't need it is clutter, not richness.

### Step 1 — decide WHAT each one animates (from the source)

For each chosen moment, go to the source and pull the *real* thing. For a code repo: the specs, the docs, the code — the real screen/route, its real steps, its real vocabulary, the real artifact a step produces. For a paper: the method section and its figures — the real steps, its real vocabulary, the real intermediate artifact a step produces. The animation must mimic *that*, faithfully. Name the design principle the animation is arguing, in one sentence, before drawing — if you can't, it's decoration, cut it.

### Step 2 — decide HOW (mimic the real UI as a click-through)

- Reproduce the real UI's layout and language: same panels, same step names, same shapes the product actually shows. Read the actual frontend/components if they exist, and match their visual grammar.
- **Staged reveal, click-driven** is the base grammar: a left **story column** narrates the current step; a right **stage** (inline SVG) advances as steps progress. Controls: ▶ play (auto-advance), › next (one discrete step), reset.
- **Discrete stepping is a real requirement:** "next" must advance exactly one step, not behave like play. Keep the play interval **on the instance** (`a.timer`) and clear it (`anStop(a)`) at the top of next/reset/play — otherwise a lingering timer makes "next" auto-run. (The template's `anStop`/`anNext`/`anPlay` show the pattern.)
- **Keep state per instance, never global.** Any new interaction you hand-build must scope its state and its DOM queries to its own root (`a.root.querySelectorAll(...)`, not `document.querySelectorAll(...)`) and must not introduce `id`s. Global state is what makes a second interaction silently drive the first one's nodes — `verify.sh` catches duplicate `id`s, but not a stray `document.` query.
- **Step narration lives in the DOM, not a JS array.** The story column is an editable `<ol class="an-steps" data-editlist="anim-steps">` — one `<li>` (name + desc) per step, the active one lit. `anRender()` reads the steps from this list, so the presenter can edit/add/delete steps in edit mode and the walk-through updates live (and exports). Redraw the SVG to the real flow; node/edge reveal stays keyed on `data-s < current step`.

**Pick the interaction FORM that fits the idea — don't reflex to "reveal boxes left-to-right".**

**`assets/interaction-patterns.html` is a working gallery** — open it in a browser, try them, copy the block you want and redraw it. Everything there is written in the palette tokens and is multi-instance safe (fresh `data-*` root name per copy). It is a **palette, not a checklist**: the range exists so you can find the one that fits, not so you can use them all. The floor is 2. **Each machine's code is split across three sections of that file** — its CSS (top, in `<style>`), its markup (in `<body>`, ending with a `.copy` line listing the exact classes), and its JS (bottom, in `<script>`) — all matched by the same name/id; copy only the markup and you get a dead widget, so pull all three.

**There are only six machines.** The dozen-odd "forms" are those six × different rhetorical uses, plus a few compositions. This matters when you build a bespoke interaction: **the unit you copy is a machine; the unit you choose is a rhetorical move.** Learn six things, not fourteen.

| Machine | How it moves | The moves it supports |
|---|---|---|
| **M1 step through a sequence** | a step index; `data-s <= step` lights up. *Always* `clearInterval` at the top of next/play/reset or "next" auto-runs | **staged reveal** (the workflow has stages) · **challenge→component** (nothing here is arbitrary — start naive, pose the challenge, let it break, reveal the fix, repeat; the AWS re:Invent move) · **agent panel** (the AI loop is real — prompt types itself beside the artifact it builds) |
| **M2 select one of N states** | click → move `.on` to the matching `[data-k]` group. One implementation, `.cmp` — in the template | **compare toggle** at 2 tabs (*ours beats the old way*) and **lens switcher** at N tabs (*several views, all true at once*) are the **same code**. Two craft knobs: tab count, and what you leave *outside* the swapping groups — for a lens, keep the **nodes outside** so only edges change; that fixed skeleton is the entire argument |
| **M3 click an element → its payload** | click `[data-x]` → show the matching payload. Same shape as M2; the trigger is *in the picture* | by payload: **details-on-demand** (a sentence) · **code-anchored inspect** (real code + `file:line` — for a traceability project this *performs* the honesty claim in three seconds) · **StretchText** (an inline gloss — the release valve for "keep the project's own words, gloss don't replace") · **C4 zoom** (a whole other diagram; the only one that adds navigation state — a stack + breadcrumb. "Like Google Maps", and never descend to code level) |
| **M4 continuous parameter** | `range` input → recompute and redraw | **parameter dial** (*it holds up as X grows — and here's where it stops*; let them drag to 10× instead of asserting it). Bind it to **time** and the same widget is a **history scrubber** |
| **M5 traverse a graph** | click a node → BFS along real edges → light downstream in waves | **ripple-on-click** (*change here, it reaches there*). **The only machine that computes** — everything else swaps between states you laid out in advance. That's why it can't merge into M2 |
| **M6 commit, then reveal** | lock every option, then show the truth. One-shot by design | **predict-then-reveal** (*your intuition is wrong, and the gap is the point*). **Once per deck**, real number only |

**Machines compose — reach for that before inventing a seventh.** The gallery's *guard catches bad input* (`it refuses what it can't verify` — run the happy path, then inject the bad input and watch it go red) is not a new machine: it is **M2 picking a branch + M1 playing a timed script**. Most "new forms" turn out to be assemblies.

**One thing there is a rendering, not a machine:** *unit visualization* (`this is how much there is, and how little is covered` — one mark per **real** thing; the gap is the argument and the unmarked dots are the honest roadmap). Its interaction is just M2's toggle; the power is entirely in the drawing. One mark = one thing, never "a dot ≈ 5 files".

Combine sparingly. The richness that matters is *fidelity to the real mechanism*, not the number of widgets — one interaction that faithfully shows the thing beats three generic ones. Distill's own warning holds: *not everything needs to be interactive; misapplied interactivity wastes effort.* Keep every added control wired to the `anStop()` discipline so stepping stays discrete.

### Step 3 — keep it honest and on a dark screen

- Put the animation slide on `.slide.screen` (stays dark in both themes).
- Only animate what's real. If a step is aspirational, either omit it or mark it. Don't imply a capability the product doesn't have.

### The scaffolds — two forms ship, because the floor is two

`assets/deck-template.html` ships **two working interactions, in deliberately different grammars**, so the floor is structural rather than a thing you have to remember:

| In the template | Form | Root attribute |
|---|---|---|
| the signature-workflow demo | **staged reveal** — editable `.an-steps` list drives `.an-node[data-s]` / `.an-edge[data-s]`, with play/next/reset wired | `.anim[data-anim="flow"]` + `.anim-ctl[data-anim-for="flow"]` |
| the "why it's better" slide | **compare toggle** — flips one stage between two states in place (`.cmp-view[data-k]` + `.cmp-cap[data-k]`) | `.cmp[data-cmp="way"]` |

Both are **multi-instance by construction**: every instance keys off its own root attribute and holds its own step/timer state — nothing is global, and there are no `id`s to collide. **To add a third interaction, copy the whole `<section>` and give the copy a new `data-anim` / `data-cmp` name** (plus a matching `data-anim-for` and a fresh `data-editlist` name). It just works; verify it with `verify.sh`.

Redraw both SVGs to the source's real flow and real mechanism — the shipped ones are shapes, not answers. For a rich product UI (or a paper with a rich method diagram), expect a scaffold to grow into a bespoke SVG scene; that's expected, the scaffolds are the starting grammar, not the ceiling. **A bespoke interaction that uses neither root attribute should carry `data-interaction="name"`** so it still counts toward the floor in `verify.sh`.

## Light dynamic touch — reveal-on-view (already in the template)

Beyond the 2–3 hand-built interactions, a *subtle* way to add life is to let a container's parts fade/rise in as its slide scrolls into view. **This ships wired up: add `class="reveal"` to any container and its direct children stagger in.** (The template puts it on the concept grid; move or reuse it freely.)

It does not count toward the interaction floor — it's decoration that happens to be tasteful, not an argument. Best spent where the staggering itself *is* the point: a "define once → derives everywhere" fan-out whose outputs appear one by one *shows* the claim instead of stating it. Everywhere else it's noise; don't sprinkle it.

How it's built, if you need to change it: children start hidden and stagger via `nth-child` `transition-delay`; the hidden state is gated on `body.js` so no-JS, print and `prefers-reduced-motion` render everything visible (never hide content behind an effect); one `IntersectionObserver` toggles a `seen` class on entry and off on exit, so it replays.

## Output location & preview

Build the deck to **your skill's conventional output path** (`showcase_deck/index.html` for showcase-deck, `paper_deck/index.html` for paper-deck) in the project root (create the folder). One project = one output folder; when improving an existing deck, it already lives here. Working files (a `.drawio` source, an exported `.svg` before you inline it) may sit in the folder during authoring, but `index.html` must not depend on them — it ships alone.

## Self-check, then serve (always)

Run `scripts/verify.sh` (no-arg default is `showcase_deck/index.html` — that's a fact about the script, not about your skill; if you're building a `paper_deck/`, pass its path explicitly: `scripts/verify.sh paper_deck/index.html`). It is not just a linter — it enforces the delivery floors, so a deck that under-delivers fails:

- **structure** — balanced tags, balanced CSS braces, ≥3 slides, nav present, **no duplicate `id`s** (the classic copy-paste break).
- **single file** — no external http(s) assets, **no sibling asset files** (any `src=` that isn't `data:`), no external stylesheet.
- **delivery floors** — themes wired, edit mode + `data-editlist` wired, **≥2 interaction roots**, animation controls present, **architecture diagram present**, **cover figure present**, **zero `PLACEHOLDER-REDRAW` markers left**.

A FAIL on the floors is not a formality to route around: it means the deck isn't finished. But fix it by *understanding the source better*, never by padding — see Step 0 above.

Then **always** launch the preview — `scripts/serve.sh` (no-arg default is also `showcase_deck/index.html`; a `paper_deck/` build must pass its path explicitly too — `scripts/serve.sh paper_deck/index.html`; binds `0.0.0.0`; run it in the background) — and give the user the LAN URL. Never finish by handing over a bare file path. Iterate on the rendered page (both themes), not on descriptions.
