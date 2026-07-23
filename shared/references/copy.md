# Copy — prose that isn't "AI slop"

`visual-system.md` bans the *visual* tells of machine-generated design (gradients, badges, emoji-as-icons). Words have a parallel failure mode — "AI slop prose" — and a deck fails on it just as visibly. The audience can't name it, but they feel the text is generic, padded, or trying too hard. This file is the prose counterpart to the visual "no" list.

The goal is **plain but composed**: every word carries weight, nothing is decorative. Plain is not the same as colloquial — don't fix stiffness by sliding into chatty.

## The "no" list (prose slop)

- **Empty attitude words** that assert a feeling instead of showing a fact: *powerful, seamless, robust, elegant, simply, easily,轻松地, 强大的, 完美*. Delete them; if the thing is powerful, the fact demonstrates it.
- **Em-dash / 破折号 pile-ups.** One interruption dash per paragraph, tops. Chains of them ("X——Y——Z——") read as a model thinking out loud. Prefer a full stop.
- **Rhetorical questions** as a rhetorical device ("那么,这意味着什么呢?"). State the thing.
- **Vague verbs** where a specific one exists: *handle, process, manage, leverage, utilize, 进行* → the actual verb (*validate, cache, reject, merge*).
- **Grand umbrella coinages** the project doesn't use — a made-up capital-letter phrase to sound weighty. Use the repo's own word (see `extract-the-soul.md` vocabulary rule).
- **Stiff spec-speak read straight off a data field.** "经过分析、判断、聚类后形成的认知知识" is a schema description, not a sentence a person says. Translate to plain: "从材料里得出的结论." Don't paste field text onto a slide unchanged.
- **Restating the obvious** ("如下图所示,下面这张图展示了…"). If the figure is below, the words don't need to announce it.

## Do instead

- **Specific verb, concrete noun.** "沿定义把每条边的实现建出来" beats "高效地完成开发工作".
- **A refusal is stronger than a promise.** "不读 diff,靠一张图" lands harder than "让审查更轻松". Naming what you *don't* do is credible; naming a feeling is not.
- **Short declaratives.** When a sentence sprawls, cut it in two. The deck is read at a glance, not studied.
- **Say the one true specific thing.** One named mechanism ("18 preflight checks", "guard 包住 llm 框") beats a paragraph of adjectives.

## Plain ≠ colloquial (the over-correction trap)

Fixing slop, it's easy to over-shoot into casual: "这事儿两秒就搞定啦". That's a different failure. The register is *editorial* — a good magazine caption: plain words, but composed, no filler particles, no winking. Tight, not chatty.

## When to reach for more

For a thorough line-by-line prose pass, the external **`hallmark`** skill (anti-AI-slop copy + a slop-test gate) pairs well with this file. This file is the fast in-deck checklist; hallmark is the deep clean.
