# deck-toolkit

**A multi-skill toolkit that generates and polishes narrated, single-file HTML slide decks — turning a code repository or a paper PDF into a showcase you can present to a human audience, not a README, not docs.**

> 一个 Claude Code / Codex skill 工具集:从**代码仓**或**论文 PDF** 生成单文件 HTML 讲解 deck(暗/暖主题、可点击编辑、内置交互动画),并支持在生成后与 AI 持续迭代打磨。

`Works in Claude Code and Codex` · `single self-contained .html` · `dark + warm theme` · `MIT`

<p align="center">
  <img src="shared/assets/img/sample-deck.svg" alt="Three slides a generated deck produces: a type-led cover, a live interactive demo on a dark screen, and a warm-theme value slide" width="100%">
</p>

The output is **one `.html` file** — no build step, no external requests, no sibling assets, no server. Open it, present it, email it. Every deck carries a dark/warm theme toggle, click-to-edit mode, and 2–3 hand-built interactive demos that mimic the project's own signature workflow.

---

## Source layout

This repo holds the *source* for a growing family of deck skills, not a single flat skill folder:

- `shared/` — the base every skill draws on: template, visual system, interaction library, and the `verify.sh` / `serve.sh` scripts. Single source of truth, shared by all skills.
- `skills/showcase-deck/` — code repo → deck (extract the project's soul + build the SCQA mainline).
- `skills/paper-deck/` — research paper / PDF → deck (extract the paper's soul, redraw the method figure as a live interaction, lift result figures faithfully via `extract-pdf-figures.sh`).
- `skills/deck-editing/` — iterate on an already-built deck: the served page injects a picker, the user clicks an element and pastes the reference block back, this skill turns it into a small verified edit.

`install.sh` fans `shared/` + each `skills/<name>/` out into a flat, self-contained directory per skill — see [Install](#install) and [Layout](#layout) below.

---

## Why it's not just "slides"

Almost every bad project deck fails on the same things — and none of them are CSS. This skill front-loads the parts that actually matter:

| The hard part | What the skill enforces |
|---|---|
| **Soul** | Read the repo's *own* docs (specs, ADRs, `docs/`) first — extract real positioning and differentiation, never invent. |
| **A mainline** | One through-line the audience can repeat back (`problem → what → see it → why → status`), signposted through the nav. |
| **Honesty** | Every claim is graded `shipped / partial / planned` and traceable to the repo. No fabricated metrics. |
| **The project's own words** | Vocabulary is mined verbatim from the repo's docs and identifiers — no invented umbrella terms. |
| **Assertion-evidence** | Every slide title is a full-sentence conclusion; the body is one visual that proves it — not a bullet wall. |
| **Delivery floors** | ≥2 interactions in different forms, an illustrated architecture, and true single-file integrity — mechanically checked by `verify.sh`, not left to good intentions. |

The visual system is solved once by the shipped template, so you spend your effort on the story, not the stylesheet.

---

## How it works

The skill walks the agent through six steps — from reading the repo to serving the finished page:

<p align="center">
  <img src="shared/assets/img/workflow.svg" alt="Six steps: extract soul, design mainline, fill template, build interactions, static diagrams, verify and serve" width="100%">
</p>

1. **Extract the soul** — read the repo's own docs, then code / architecture / git / tests; write a Project Brief with a vocabulary allow-list mined verbatim.
2. **Design the mainline** — pick the through-line and nav sections; open with the pain and the answer up front, not five slides in.
3. **Fill the template** — one assertion per slide title, one visual as its evidence. Includes drawing the **cover figure**: one quiet static portrait of this project (what it makes / its shape / its real screen), derived from the Brief — the template ships a hole there, not a stock hero.
4. **Build 2–3 interactive moments** — the template ships two wired scaffolds in different forms (staged reveal + compare toggle); the agent redraws them to the real product UI, each dramatizing one design principle.
5. **Static diagrams (required)** — architecture / schema / flow via the drawio skill, styled to the palette; if the drawio toolchain isn't installed, it falls back to a hand-authored inline SVG rather than skipping the diagram. Either way the markup is inlined.
6. **Self-check and serve** — the deck is written to `showcase_deck/index.html` in the project; `scripts/verify.sh` checks single-file integrity **and the delivery floors** (≥2 interactions, diagram present, no sibling assets), then `scripts/serve.sh` auto-starts a local preview so you can view it in a browser right away.

---

## Install

Clone this repo anywhere (it is *not* itself a skill folder), then run the installer. `install.sh` reads the local `shared/` + `skills/` source and fans each skill out into your agent's personal-skills folder(s) — auto-detecting Claude Code and/or Codex, installing to both if both are present:

```bash
git clone https://github.com/ykz9527/project-showcase-deck.git deck-toolkit
cd deck-toolkit && bash install.sh
```

This installs `showcase-deck`, `paper-deck`, and `deck-editing` (and any future skills under `skills/`) as self-contained, flat directories:

- Claude Code → `~/.claude/skills/showcase-deck`, `~/.claude/skills/paper-deck`, `~/.claude/skills/deck-editing`
- Codex → `~/.agents/skills/showcase-deck`, `~/.agents/skills/paper-deck`, `~/.agents/skills/deck-editing`

Force a specific target with `FORCE_CLAUDE=1 bash install.sh` or `FORCE_CODEX=1 bash install.sh`.

**Update later:** the installed copies are plain copies, not checkouts — `git pull` updates *this* source repo, then re-run the installer to refresh what's installed:

```bash
cd deck-toolkit && git pull && bash install.sh
```

**Upgrading from the old single-skill install?** The pre-P0 version installed to `~/.claude/skills/project-showcase-deck` (and `~/.agents/skills/project-showcase-deck`). The new layout installs as `showcase-deck`, so delete the old directory once to avoid a duplicate skill — the installer prints a reminder if it finds one:

```bash
rm -rf ~/.claude/skills/project-showcase-deck ~/.agents/skills/project-showcase-deck
```

Then start a fresh agent session and, from inside any project you want to showcase, just ask:

> "给这个项目做一份介绍 deck"  ·  "make a showcase deck for this repo"

---

## Works in both Claude Code and Codex

The installed skill format is the same across both agents — a `SKILL.md` (with `name` + `description` frontmatter) plus `references/`, `assets/`, and `scripts/`, merged flat by `install.sh` from `shared/` and each `skills/<name>/`. **No content changes are needed to run it in Codex** — only the install location differs:

| Agent | Personal-skills folder |
|---|---|
| **Claude Code** | `~/.claude/skills/` |
| **Codex** | `~/.agents/skills/` |

Both agents load `SKILL.md` on demand when your request matches its description, then follow the same workflow. The one soft dependency is step 5's cross-reference to a **drawio** skill for static diagrams; where that isn't available, the deck falls back to hand-authored inline SVG and the rest of the flow is unaffected.

---

## What you get

- **One self-contained `.html` file** — no external requests, no sibling assets; scroll-snap slides, auto page numbers.
- **Dark / warm editorial theme** with a toggle — no "AI slop" (no gradients, colorful badges, or emoji icons).
- **An honest, repeatable narrative** — a mainline the audience can repeat back, with graded honesty (shipped / partial / planned).
- **2–3 hand-built interactive demos** that mimic the project's real signature workflow, each arguing one design principle. Copy an interaction slide to add another — every instance is independently wired.
- **A gallery of working interactions — six machines, a dozen moves.** Organised by the machine you copy (step a sequence · select one of N states · click an element for its payload · drag a continuous parameter · traverse a graph · commit-then-reveal) and indexed by the claim each move argues, so you pick by what you need to prove. Machines compose — the guard demo is two of them stacked. Grounded in the interactive-article literature ([Distill](https://distill.pub/2020/communicating-with-interactive-articles/), [Nicky Case](https://blog.ncase.me/explorable-explanations-4-more-design-patterns/)), Bret Victor's direct manipulation, and Simon Brown's C4. A palette, not a checklist — the floor stays 2.
- **Click-to-edit mode** — reword any text, and add / remove list items, cards, and animation steps in the browser; persists to localStorage and exports to a clean standalone HTML.
- **A cover that looks like your project** — a hand-drawn portrait derived from the repo, not a stock hero. The test: swap in another project's name; if the figure still fits, it's filler.
- **A verifier that actually bites** — `verify.sh` fails a deck that ships fewer than 2 interactions, no cover figure, no architecture diagram, a duplicate `id`, a stray sibling asset, or any of the template's placeholder shapes left un-redrawn.

---

## Layout

**Source (this repo)** — `shared/` is the single source of truth every skill draws on; each skill under `skills/` owns only what's specific to it:

```
install.sh                       # local fan-out installer (Claude Code + Codex)
shared/
  references/
    content-logic.md             # per-slide logic: SCQA, assertion-evidence, Rule of One, C4, trade-offs
    visual-system.md             # editorial design language, anti-"AI slop", palette/fonts
    deck-mechanics.md            # single-file structure, themes, edit mode, animations
  assets/
    deck-template.html           # the proven skeleton to copy (dark/warm, edit mode,
                                 #   2 interaction scaffolds, inline architecture figure)
    interaction-patterns.html    # browsable gallery of 8 working interaction forms —
                                 #   a palette to copy from, not a checklist to fill
    picker.js                    # injected by serve.sh: click-to-copy element picker for deck-editing
    img/                         # README figures
  scripts/
    verify.sh                    # structure + single-file integrity + delivery floors
    serve.sh                     # serve a deck on 0.0.0.0 for browser viewing
    extract-pdf-figures.sh       # lift a PDF figure as a self-contained inline apx-fig snippet
skills/
  showcase-deck/
    SKILL.md                     # entry point: DNA, non-negotiables, workflow, red flags
    references/
      extract-the-soul.md        # what to mine from the repo + honesty grading + vocabulary fidelity
      narrative-spine.md         # choosing the mainline + nav signposting (SCQA opening)
  paper-deck/
    SKILL.md                     # entry point: paper's soul, method-as-interaction, result figures lifted from the PDF
    references/
      extract-the-paper-soul.md  # Paper Brief + paper-context honesty grading + vocabulary fidelity
      paper-narrative.md         # motivation → gap → idea → method → results → limits spine
  deck-editing/
    SKILL.md                     # entry point: turn a pasted picker reference block into a verified edit
    references/
      edit-loop.md                # region-level / no-data-ref / structural / multi-select edit loops
```

**Installed (what `install.sh` produces)** — under `~/.claude/skills/<name>/` on Claude Code (`~/.agents/skills/<name>/` on Codex), `shared/` is merged flat into each of `showcase-deck`, `paper-deck`, and `deck-editing` so every installed folder is self-contained (no `shared/` subdirectory):

```
SKILL.md
references/
  <skill-specific references>                            # e.g. extract-the-soul.md, narrative-spine.md for showcase-deck
  content-logic.md, visual-system.md, deck-mechanics.md   # merged from shared/
assets/
  deck-template.html, interaction-patterns.html, picker.js, img/   # merged from shared/
scripts/
  verify.sh, serve.sh, extract-pdf-figures.sh              # merged from shared/
```

## Requirements

- **Claude Code** or **Codex**.
- Static diagrams use the **drawio** skill (optional; needs the drawio CLI or an extracted AppImage + `xvfb` for headless SVG export). Without it, the deck hand-authors inline SVG.

## License

MIT — see [LICENSE](LICENSE).
