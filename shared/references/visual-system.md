# Visual System — editorial, not "AI slop"

The template ships a coherent design language. Keep it. Recolor semantics per project; do not redesign the system.

## The look

- **Editorial / brutalist-restrained**, not "dashboard". Think forms.supply, a well-set print spread — confident typography, generous whitespace, hairline rules.
- **Two themes, tokenized.** Dark (near-black `#060606`) is default; warm (paper `#efe9dd`) is an additive override via `[data-theme="warm"]`. The neutral scale is CSS variables so both themes work from one markup. Semantic accent colors are the SAME in both themes. (Read the real values off `:root` in the template — don't retype them from memory.)
- **Type:** serif headings (Georgia) for authority; mono labels/tags for a technical, precise feel; sans for body.
- **Color:** one restrained, earthy palette. Semantic accents map to the project's real categories (in the template: `--c1..--c5`). Muted, low-saturation — earth tones, not neon.

## Hard "no" list (this is what "AI slop" means)

- ❌ Soft multi-color gradients / glows as decoration
- ❌ Colorful pill "badges" everywhere
- ❌ Rounded-everything, big border-radius on every box
- ❌ Emoji used as UI icons
- ❌ Drop shadows on everything; glassmorphism
- ❌ Rainbow category colors / high-saturation primaries
- ❌ Center-everything, no hierarchy

- ❌ A *templated* decorative hero on the cover — e.g. stock floating rotated cards used as ornament. It reads as filler and looks the same for every project. (Not a ban on the shape itself: if the real product UI *is* floating cards, a cover echoing it is authentic and specific — keep it. The test is whether the hero says something true about THIS project.)

## Do instead

- Hairline borders (`--hairline`), flat dark/warm panels, thin left-accent bars.
- Semantic color used sparingly and meaningfully (a category color, a status color) — never decoratively.
- Strong type hierarchy: big serif h1/h2, small mono uppercase labels, readable body.
- Let whitespace and a single accent do the work.

## Readability (presentation, not a webpage)

This gets projected and read from across a room. The template base is **17px**; keep readable prose at ~14px+ (labels/mono tags may be smaller). If body copy feels cramped, the fix is *less text*, not *smaller text*.

## The cover

The cover is the first read, and it is where a deck either looks like THIS project or looks like every other deck. The template ships type on the left (headline + official one-liner + fact strip) and **a figure slot on the right** — a hole with a placeholder in it, because the one thing that cannot be templated is the thing that makes a cover specific.

**The figure is a portrait, not decoration and not a diagram.** The appendix already carries the diagram; this is the single image you'd put on the cover of a book about this project. Derive it from the Brief:

| What the project is / does | The portrait that says it |
|---|---|
| produces a distinctive artifact | draw that artifact, framed, at rest (a schema card, a graph node, a generated file) |
| is a structure / graph / index | a small quiet map of the REAL topology — a portrait of its shape, not a flowchart |
| is a loop / workflow | the loop as one closed static shape |
| has a distinctive product UI | a reduced, stylized echo of the real screen (not a screenshot) |
| converts A into B | the two real artifacts side by side, one mark between them |

Rules: **static** (never animate the cover), **quiet** (the headline still leads), ≤~7 elements, palette tokens only, and everything on the hard-no list above still applies.

**The test — swap in another project's name. Does the figure still fit? Then it's filler; throw it away.** That is also the honest definition of the templated-hero anti-pattern: not a banned shape, but a shape that would fit anyone.

A type-led cover with no figure can be excellent — but it is a *deliberate* choice, made when the headline genuinely carries the whole page, not a default you arrive at by skipping the work. `verify.sh` fails a cover with no figure, so if you mean it, mean it on purpose.

## Recoloring per project

Change ONLY the accent tokens in `:root` (`--c1..--c5`, `--live/--partial/--design`) to the project's real category colors — keep them muted and earthy. Do not touch the neutral scale or the two-theme structure. If the project has an established brand palette, adapt the accents toward it but keep saturation low enough to read as editorial, not marketing.

## Status colors (fixed roles, skill-defined labels)

- Three grades, always the same visual roles: `--live` (green) = the confident/verified grade, `--partial` (amber) = the partial/intermediate grade, `--design` (grey) = the unproven/aspirational grade. Keep the colors and their ordering consistent so the honesty grading reads at a glance.
- The WORDING is defined per skill, not fixed here — in the same confident → partial → unproven order: `showcase-deck` labels them 已上线 / 部分落地 / 方向; `paper-deck` labels them 已复现 / 论文声称 / 存疑. Use the labels the active skill specifies — do not import the other skill's wording.

## Diagrams

Every deck illustrates its architecture — that part is not optional. *How* you draw it has an order of preference:

1. **Static diagrams → the drawio skill** when its toolchain is actually installed: styled to this palette, exported as SVG, then **inlined into the html**. drawio bakes its colors, so export a dark + warm pair and let CSS swap them by theme.
2. **No drawio toolchain → hand-author the inline SVG.** This is the correct fallback, not a mistake. Write it in the palette tokens (`fill="var(--panel)"`, `stroke="var(--c5)"`, `fill="var(--tx-hi)"` for text) — token-driven SVG themes for free, so one copy covers both themes. The template's appendix figure is a worked example. **Skipping the diagram is the failure; hand-drawing it is not.**
3. **Interactive animations are always hand-authored inline SVG** — never try to animate via drawio.

Whichever route, the SVG markup ends up **inside the .html**. Never `<img src="fig.svg">` a sibling file: the deck's whole promise is that one file survives being emailed. See `deck-mechanics.md` → Static diagrams.
