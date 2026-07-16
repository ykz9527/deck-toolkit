# Visual System — editorial, not "AI slop"

The template ships a coherent design language. Keep it. Recolor semantics per project; do not redesign the system.

## The look

- **Editorial / brutalist-restrained**, not "dashboard". Think forms.supply, a well-set print spread — confident typography, generous whitespace, hairline rules.
- **Two themes, tokenized.** Dark (near-black `#060606`) is default; warm (paper `#f2eee4`) is an additive override via `[data-theme="warm"]`. The neutral scale is CSS variables so both themes work from one markup. Semantic accent colors are the SAME in both themes.
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

- ❌ The stock "floating rotated cards" hero on the cover — it reads as templated and looks the same for every project.

## Do instead

- Hairline borders (`--hairline`), flat dark/warm panels, thin left-accent bars.
- Semantic color used sparingly and meaningfully (a category color, a status color) — never decoratively.
- Strong type hierarchy: big serif h1/h2, small mono uppercase labels, readable body.
- Let whitespace and a single accent do the work.

## Readability (presentation, not a webpage)

This gets projected and read from across a room. The template base is **17px**; keep readable prose at ~14px+ (labels/mono tags may be smaller). If body copy feels cramped, the fix is *less text*, not *smaller text*.

## The cover is a per-project choice, not a fill-in

The cover is the first read — make it express THIS project, don't reflex to a stock hero. Pick one: (a) type-led (big serif headline + official one-liner — the safe default); (b) one framed *real* artifact (a screenshot, a code block, a true output); (c) a strip of the project's real facts (domain / audience / status); (d) one quiet diagram from the drawio skill. The template ships (a) with a fact strip; swap in whatever fits.

## Recoloring per project

Change ONLY the accent tokens in `:root` (`--c1..--c5`, `--live/--partial/--design`) to the project's real category colors — keep them muted and earthy. Do not touch the neutral scale or the two-theme structure. If the project has an established brand palette, adapt the accents toward it but keep saturation low enough to read as editorial, not marketing.

## Status colors (fixed meaning)

- `--live` (green) = shipped, `--partial` (amber) = in-progress, `--design` (grey) = planned. Keep these consistent so the honesty grading reads at a glance.

## Diagrams

Static diagrams (architecture / flow / schema) come from the **drawio skill**, styled to this palette and inlined as SVG (dark + warm pair, swapped by theme — see `deck-mechanics.md`). Interactive animations are the exception: hand-authored inline SVG (see `deck-mechanics.md` → Animations). Never hand-draw a static diagram; never try to animate via drawio.
