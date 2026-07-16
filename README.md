# project-showcase-deck

A [Claude Code](https://claude.com/claude-code) skill that turns any code repository into a polished, single-file HTML slide deck introducing the project to a human audience (leadership + newcomers) — not a README, not docs, but a narrated showcase you can present or share.

> 一个 Claude Code skill:把任意代码仓库变成一份单文件 HTML 讲演稿(暗/暖主题、可编辑、内置交互动画),用来给领导和新人介绍项目。

## What it produces

- **One self-contained `.html` file** — no external requests; scroll-snap slides, auto page numbers.
- **Dark / warm editorial theme** with a toggle (no "AI slop": no gradients, colorful badges, or emoji icons).
- **An honest, repeatable narrative** — a mainline the audience can repeat back, with graded honesty (shipped / in-progress / planned).
- **2–3 hand-built interactive demos** that mimic the project's real signature workflow, each arguing one design principle.
- **Click-to-edit mode** with localStorage persistence and export to a clean standalone HTML.

The quality lives in the *soul* (real positioning, honest status), the *mainline*, and *fidelity to the project's own words* — not in the CSS. The visual system is solved once by the shipped template.

## How it works

The skill guides Claude Code through six steps:

1. **Extract the soul** — read the repo's own docs (spec/design docs, ADRs, `docs/`), then code/architecture/git/tests; write a Project Brief with a vocabulary allow-list mined verbatim from the repo.
2. **Design the mainline** — pick the through-line and nav sections; open SCQA-style (pain → question → answer up front).
3. **Fill the template** — one assertion per slide title, one visual as its evidence.
4. **Build 2–3 interactive moments** — faithful to the real product UI, each dramatizing a design principle.
5. **Static diagrams via the drawio skill** — architecture / schema / flow, styled to the palette.
6. **Self-check and serve** — `scripts/verify.sh` for single-file integrity, `scripts/serve.sh` to view.

## Install

Copy this directory into your Claude Code **personal skills** folder so it's available across all sessions:

```bash
git clone <this-repo-url> project-showcase-deck
mkdir -p ~/.claude/skills
cp -r project-showcase-deck ~/.claude/skills/project-showcase-deck
```

(Or place it under a project's `.claude/skills/` to scope it to one repo.)

Then, from inside any project you want to showcase, just ask Claude Code:

> "给这个项目做一份介绍 deck" · "make a showcase deck for this repo"

## Layout

```
SKILL.md                     # entry point: DNA, non-negotiables, workflow, red flags
references/
  extract-the-soul.md        # what to mine from the repo + honesty grading + vocabulary fidelity
  narrative-spine.md         # choosing the mainline + nav signposting (SCQA opening)
  content-logic.md           # per-slide logic: SCQA, assertion-evidence, Rule of One, C4, trade-offs
  visual-system.md           # editorial design language, anti-"AI slop", palette/fonts
  deck-mechanics.md          # single-file structure, themes, edit mode, animations
assets/
  deck-template.html         # the proven skeleton to copy (dark/warm, edit mode, animation scaffold)
scripts/
  verify.sh                  # single-file integrity check (balanced tags, no external URLs, themes wired)
  serve.sh                   # serve a deck on 0.0.0.0 for browser viewing
```

## Requirements

- Claude Code.
- Static diagrams use the **drawio** skill (optional; needs the drawio CLI or an extracted AppImage + `xvfb` for headless SVG export).

## License

MIT — see [LICENSE](LICENSE).
